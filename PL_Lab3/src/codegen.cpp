#include "../include/codegen.h"
#include <queue>
#include <sstream>

void CodeGenerator::emit(const Instruction& instr) {
    if (currentFrag_) {
        currentFrag_->instructions.push_back(instr);
    }
}

void CodeGenerator::emit(const std::string& mnemonic) {
    emit(Instruction(mnemonic));
}

void CodeGenerator::emit(const std::string& mnemonic, Operand op) {
    emit(Instruction(mnemonic, op));
}

void CodeGenerator::emit(const std::string& mnemonic, Operand op, const std::string& comment) {
    emit(Instruction(mnemonic, op, comment));
}

void CodeGenerator::addError(const std::string& msg, SourceLocation loc) {
    errors_.push_back({ msg, currentFile_, loc });
}

std::string CodeGenerator::blockLabel(const std::string& funcName, int blockId,
    const std::string& hint) const {
    std::string safeHint = hint;
    for (char& c : safeHint) {
        if (c == '.') c = '_';
    }
    return funcName + "__" + safeHint + "_" + std::to_string(blockId);
}

int CodeGenerator::getLocalSlot(const std::string& varName) {
    auto it = localSlots_.find(varName);
    if (it != localSlots_.end()) return it->second;
    int slot = nextLocalSlot_++;
    localSlots_[varName] = slot;
    return slot;
}

int CodeGenerator::getArgSlot(const std::string& argName) {
    auto it = argSlots_.find(argName);
    if (it != argSlots_.end()) return it->second;
    return -1;
}

int CodeGenerator::addStringConstant(const std::string& str) {
    std::string s = str;
    if (s.size() >= 2 && s.front() == '"' && s.back() == '"') {
        s = s.substr(1, s.size() - 2);
    }

    for (size_t i = 0; i < image_.constants.size(); ++i) {
        if (image_.constants[i].kind == ConstantEntry::CONST_STRING &&
            image_.constants[i].strValue == s) {
            return static_cast<int>(i);
        }
    }

    int idx = static_cast<int>(image_.constants.size());
    ConstantEntry entry;
    entry.kind = ConstantEntry::CONST_STRING;
    entry.strValue = s;
    entry.label = "_str_" + std::to_string(idx);
    image_.constants.push_back(std::move(entry));
    return idx;
}

std::vector<int> CodeGenerator::topoOrder(const ControlFlowGraph& cfg) {
    int n = static_cast<int>(cfg.blocks.size());
    std::vector<bool> visited(n, false);
    std::vector<int> order;
    order.reserve(n);

    std::queue<int> q;
    if (cfg.entryBlockId >= 0) {
        q.push(cfg.entryBlockId);
        visited[cfg.entryBlockId] = true;
    }

    while (!q.empty()) {
        int id = q.front();
        q.pop();
        order.push_back(id);

        const BasicBlock* block = cfg.blocks[id].get();
        auto tryVisit = [&](int next) {
            if (next >= 0 && next < n && !visited[next]) {
                visited[next] = true;
                q.push(next);
            }
            };
        tryVisit(block->unconditionalNext);
        tryVisit(block->conditionalTrue);
        tryVisit(block->conditionalFalse);
    }

    for (int i = 0; i < n; ++i) {
        if (!visited[i]) order.push_back(i);
    }
    return order;
}

CodegenResult CodeGenerator::generate(const ProgramInfo& program) {
    image_ = ProgramImage();
    errors_.clear();

    for (const auto& func : program.functions) {
        currentFile_ = func->sourceFile;
        generateFunction(*func);
    }

    return { std::move(image_), std::move(errors_) };
}

void CodeGenerator::generateFunction(const FunctionInfo& func) {
    const ControlFlowGraph& cfg = func.cfg;
    bool hasBody = false;
    for (const auto& block : cfg.blocks) {
        if (block->label != "entry" && block->label != "exit") {
            hasBody = true;
            break;
        }
        if (!block->operations.empty()) {
            hasBody = true;
            break;
        }
    }
    if (!hasBody) {
        image_.externFunctions.push_back(func.signature.name);
        return;
    }

    FunctionCode funcCode;
    funcCode.name = func.signature.name;
    image_.code.push_back(std::move(funcCode));
    currentFunc_ = &image_.code.back();

    localSlots_.clear();
    argSlots_.clear();
    nextLocalSlot_ = 0;
    numArgs_ = static_cast<int>(func.signature.args.size());

    for (int i = 0; i < numArgs_; ++i) {
        argSlots_[func.signature.args[i].name] = i;
    }
    nextLocalSlot_ = 0;

    for (const auto& block : cfg.blocks) {
        for (const auto& op : block->operations) {
            if (op->kind == Operation::OP_ASSIGN && !op->operands.empty()) {
                if (op->operands[0]->kind == Operation::OP_PLACE) {
                    const std::string& name = op->operands[0]->value;
                    if (argSlots_.find(name) == argSlots_.end()) {
                        getLocalSlot(name);
                    }
                }
            }
        }
    }

    currentFunc_->numArgs = numArgs_;
    currentFunc_->numLocals = nextLocalSlot_;

    {
        CodeFragment prologue;
        prologue.label = func.signature.name;
        currentFrag_ = &prologue;

        emit("enter", Operand::iconst(nextLocalSlot_),
            "allocate " + std::to_string(nextLocalSlot_) + " local slots");

        currentFunc_->fragments.push_back(std::move(prologue));
    }

    std::vector<int> order = topoOrder(cfg);

    for (int blockId : order) {
        const BasicBlock& block = *cfg.blocks[blockId].get();

        if (block.label == "exit") continue;

        std::string label = blockLabel(func.signature.name, blockId, block.label);

        CodeFragment frag;
        frag.label = (blockId == cfg.entryBlockId) ? "" : label;
        currentFrag_ = &frag;

        generateBlock(block, func);
        currentFunc_->fragments.push_back(std::move(frag));
    }

    {
        int exitId = -1;
        for (const auto& block : cfg.blocks) {
            if (block->label == "exit") { exitId = block->id; break; }
        }

        CodeFragment epilogue;
        epilogue.label = blockLabel(func.signature.name, exitId, "exit");
        currentFrag_ = &epilogue;

        emit("push_none", Operand::none(), "default return value");
        emit("ret");

        currentFunc_->fragments.push_back(std::move(epilogue));
    }

    currentFunc_ = nullptr;
    currentFrag_ = nullptr;
}

void CodeGenerator::generateBlock(const BasicBlock& block, const FunctionInfo& func) {
    for (const auto& op : block.operations) {
        emitOperation(op.get());
        if (op->kind != Operation::OP_ASSIGN) {
            emit("pop", Operand::none(), "discard expression result");
        }
    }

    if (block.condition) {
        std::string trueLabel, falseLabel;

        if (block.conditionalTrue >= 0) {
            const BasicBlock* tb = func.cfg.blocks[block.conditionalTrue].get();
            trueLabel = (tb->label == "exit")
                ? blockLabel(func.signature.name, block.conditionalTrue, "exit")
                : blockLabel(func.signature.name, block.conditionalTrue, tb->label);
        }
        if (block.conditionalFalse >= 0) {
            const BasicBlock* fb = func.cfg.blocks[block.conditionalFalse].get();
            falseLabel = (fb->label == "exit")
                ? blockLabel(func.signature.name, block.conditionalFalse, "exit")
                : blockLabel(func.signature.name, block.conditionalFalse, fb->label);
        }

        emitConditionAndJump(block.condition.get(), trueLabel, falseLabel);

    }
    else if (block.unconditionalNext >= 0) {
        const BasicBlock* nb = func.cfg.blocks[block.unconditionalNext].get();
        std::string nextLabel = (nb->label == "exit")
            ? blockLabel(func.signature.name, block.unconditionalNext, "exit")
            : blockLabel(func.signature.name, block.unconditionalNext, nb->label);
        emit("jmp", Operand::label(nextLabel));
    }
}

void CodeGenerator::emitOperation(const Operation* op) {
    if (op == nullptr) return;

    switch (op->kind) {
    case Operation::OP_LITERAL: {
        const std::string& s = op->value;
        if (s == "true") {
            emit("push_bool", Operand::iconst(1));
        }
        else if (s == "false") {
            emit("push_bool", Operand::iconst(0));
        }
        else if (s.size() >= 3 && s[0] == '\'' && s.back() == '\'') {
            emit("push_char", Operand::iconst(static_cast<int64_t>(s[1])));
        }
        else if (s.size() >= 2 && s[0] == '"') {
            int idx = addStringConstant(s);
            emit("push_const", Operand::constIdx(idx), "string");
        }
        else if (s.size() > 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) {
            emit("push_int", Operand::iconst(std::stoll(s, nullptr, 16)));
        }
        else if (s.size() > 2 && s[0] == '0' && (s[1] == 'b' || s[1] == 'B')) {
            emit("push_int", Operand::iconst(std::stoll(s.substr(2), nullptr, 2)));
        }
        else {
            int64_t val = 0;
            try { val = std::stoll(s); }
            catch (...) {}
            emit("push_int", Operand::iconst(val));
        }
        break;
    }

    case Operation::OP_PLACE: {
        auto ait = argSlots_.find(op->value);
        if (ait != argSlots_.end()) {
            emit("load_arg", Operand::index(ait->second), op->value);
        }
        else {
            int slot = getLocalSlot(op->value);
            emit("load_local", Operand::index(slot), op->value);
        }
        break;
    }

    case Operation::OP_ASSIGN: {
        if (op->operands.size() < 2) break;
        const Operation* lhs = op->operands[0].get();
        const Operation* rhs = op->operands[1].get();

        if (lhs->kind == Operation::OP_PLACE) {
            emitOperation(rhs);

            auto ait = argSlots_.find(lhs->value);
            if (ait != argSlots_.end()) {
                emit("store_arg", Operand::index(ait->second), lhs->value);
            }
            else {
                int slot = getLocalSlot(lhs->value);
                emit("store_local", Operand::index(slot), lhs->value);
            }
        }
        else if (lhs->kind == Operation::OP_INDEX) {
            if (lhs->operands.size() >= 2) {
                emitOperation(lhs->operands[0].get());
                emitOperation(lhs->operands[1].get());
            }
            emitOperation(rhs);
            emit("arr_store");
        }
        break;
    }

    case Operation::OP_BINARY: {
        if (op->operands.size() < 2) break;

        emitOperation(op->operands[0].get());
        emitOperation(op->operands[1].get());

        const std::string& binOp = op->value;
        if (binOp == "+")  emit("add");
        else if (binOp == "-")  emit("sub");
        else if (binOp == "*")  emit("mul");
        else if (binOp == "/")  emit("div");
        else if (binOp == "%")  emit("mod");
        else if (binOp == "&")  emit("bit_and");
        else if (binOp == "|")  emit("bit_or");
        else if (binOp == "^")  emit("bit_xor");
        else if (binOp == "<<") emit("bit_shl");
        else if (binOp == ">>") emit("bit_shr");
        else if (binOp == "&&") emit("log_and");
        else if (binOp == "||") emit("log_or");
        else if (binOp == "==") emit("cmp_eq");
        else if (binOp == "!=") emit("cmp_ne");
        else if (binOp == "<")  emit("cmp_lt");
        else if (binOp == ">")  emit("cmp_gt");
        else if (binOp == "<=") emit("cmp_le");
        else if (binOp == ">=") emit("cmp_ge");
        else if (binOp == "..") {
            emit("make_range");
        }
        else {
            addError("unknown binary operator: " + binOp, op->loc);
        }
        break;
    }

    case Operation::OP_UNARY: {
        if (op->operands.empty()) break;
        emitOperation(op->operands[0].get());

        const std::string& uop = op->value;
        if (uop == "-")        emit("neg");
        else if (uop == "~")        emit("bit_not");
        else if (uop == "!")        emit("log_not");
        else if (uop == "++" || uop == "post++") emit("inc");
        else if (uop == "--" || uop == "post--") emit("dec_op");
        else {
            addError("unknown unary operator: " + uop, op->loc);
        }

        if ((uop == "post++" || uop == "post--") &&
            !op->operands.empty() && op->operands[0]->kind == Operation::OP_PLACE) {
            emit("dup");
            auto ait = argSlots_.find(op->operands[0]->value);
            if (ait != argSlots_.end()) {
                emit("store_arg", Operand::index(ait->second));
            }
            else {
                int slot = getLocalSlot(op->operands[0]->value);
                emit("store_local", Operand::index(slot));
            }
        }
        break;
    }

    case Operation::OP_CALL: {
        if (op->operands.empty()) break;

        int argCount = static_cast<int>(op->operands.size()) - 1;
        for (int a = 1; a <= argCount; ++a) {
            emitOperation(op->operands[a].get());
        }

        if (op->operands[0]->kind == Operation::OP_PLACE) {
            emit("call", Operand::label(op->operands[0]->value),
                "args=" + std::to_string(argCount));
        }
        else {
            emitOperation(op->operands[0].get());
            emit("call_indirect", Operand::iconst(argCount));
        }

        break;
    }

    case Operation::OP_INDEX: {
        if (op->operands.size() < 2) break;
        emitOperation(op->operands[0].get());
        emitOperation(op->operands[1].get());
        emit("arr_load");
        break;
    }

    case Operation::OP_SLICE: {
        if (op->operands.size() >= 2) {
            emitOperation(op->operands[0].get());
            for (size_t i = 1; i < op->operands.size(); ++i) {
                emitOperation(op->operands[i].get());
            }
            emit("arr_slice");
        }
        break;
    }

    case Operation::OP_RETURN: {
        if (!op->operands.empty()) {
            emitOperation(op->operands[0].get());
        }
        else {
            emit("push_none");
        }
        emit("ret");
        break;
    }
    }
}

void CodeGenerator::emitConditionAndJump(const Operation* cond,
    const std::string& trueLabel,
    const std::string& falseLabel) {
    emitOperation(cond);
    emit("jnz", Operand::label(trueLabel));
    emit("jmp", Operand::label(falseLabel));
}