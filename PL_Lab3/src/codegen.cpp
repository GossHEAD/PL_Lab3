// codegen.cpp — ИСПРАВЛЕНО
//
// ИСПРАВЛЕНИЯ:
//   1. Поддержка неявного возврата (implicit return):
//      OP_RETURN в emitOperation вычисляет выражение и прыгает в exit-блок.
//      Exit-блок делает просто ret N (без push_none, значение уже на стеке).
//      Если в функции нет OP_RETURN (пустое тело или только присваивания) —
//      exit-блок добавляет push_none перед ret N.
//
//   2. ret теперь ret N (N = число аргументов) — VM очищает стек вызывающего.
//
//   3. Аргументы callee НЕ нужно очищать в caller — это делает ret N в callee.

#include "../include/codegen.h"
#include <queue>
#include <sstream>

void CodeGenerator::emit(const Instruction& instr) {
    if (currentFrag_) currentFrag_->instructions.push_back(instr);
}
void CodeGenerator::emit(const std::string& mnemonic) { emit(Instruction(mnemonic)); }
void CodeGenerator::emit(const std::string& mnemonic, Operand op) { emit(Instruction(mnemonic, op)); }
void CodeGenerator::emit(const std::string& mnemonic, Operand op, const std::string& comment) {
    emit(Instruction(mnemonic, op, comment));
}
void CodeGenerator::addError(const std::string& msg, SourceLocation loc) {
    errors_.push_back({ msg, currentFile_, loc });
}

std::string CodeGenerator::blockLabel(const std::string& funcName, int blockId,
    const std::string& hint) const {
    std::string safeHint = hint;
    for (char& c : safeHint) { if (c == '.') c = '_'; }
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
    if (s.size() >= 2 && s.front() == '"' && s.back() == '"')
        s = s.substr(1, s.size() - 2);
    for (size_t i = 0; i < image_.constants.size(); ++i) {
        if (image_.constants[i].kind == ConstantEntry::CONST_STRING &&
            image_.constants[i].strValue == s)
            return static_cast<int>(i);
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
    if (cfg.entryBlockId >= 0) { q.push(cfg.entryBlockId); visited[cfg.entryBlockId] = true; }
    while (!q.empty()) {
        int id = q.front(); q.pop();
        order.push_back(id);
        const BasicBlock* block = cfg.blocks[id].get();
        auto tryVisit = [&](int next) {
            if (next >= 0 && next < n && !visited[next]) { visited[next] = true; q.push(next); }
        };
        tryVisit(block->unconditionalNext);
        tryVisit(block->conditionalTrue);
        tryVisit(block->conditionalFalse);
    }
    for (int i = 0; i < n; ++i) if (!visited[i]) order.push_back(i);
    return order;
}

static bool cfgHasExplicitReturn(const ControlFlowGraph& cfg) {
    for (const auto& block : cfg.blocks)
        for (const auto& op : block->operations)
            if (op->kind == Operation::OP_RETURN) return true;
    return false;
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
        if (block->label != "entry" && block->label != "exit") { hasBody = true; break; }
        if (!block->operations.empty()) { hasBody = true; break; }
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

    for (int i = 0; i < numArgs_; ++i)
        argSlots_[func.signature.args[i].name] = i;
    nextLocalSlot_ = 0;

    // Предварительный проход: локальные переменные
    for (const auto& block : cfg.blocks)
        for (const auto& op : block->operations)
            if (op->kind == Operation::OP_ASSIGN && !op->operands.empty())
                if (op->operands[0]->kind == Operation::OP_PLACE) {
                    const std::string& name = op->operands[0]->value;
                    if (argSlots_.find(name) == argSlots_.end())
                        getLocalSlot(name);
                }

    currentFunc_->numArgs   = numArgs_;
    currentFunc_->numLocals = nextLocalSlot_;

    bool hasExplicitReturn = cfgHasExplicitReturn(cfg);

    // Находим exit блок
    int exitId = -1;
    for (const auto& block : cfg.blocks)
        if (block->label == "exit") { exitId = block->id; break; }
    exitLabel_ = blockLabel(func.signature.name, exitId, "exit");

    // Пролог
    {
        CodeFragment prologue;
        prologue.label = func.signature.name;
        currentFrag_ = &prologue;
        emit("enter", Operand::iconst(nextLocalSlot_),
             "allocate " + std::to_string(nextLocalSlot_) + " local slots");
        currentFunc_->fragments.push_back(std::move(prologue));
    }

    // Основные блоки
    std::vector<int> order = topoOrder(cfg);
    for (int blockId : order) {
        const BasicBlock& block = *cfg.blocks[blockId].get();
        if (block.label == "exit") continue;

        std::string label = blockLabel(func.signature.name, blockId, block.label);
        CodeFragment frag;
        frag.label = (blockId == cfg.entryBlockId) ? "" : label;
        currentFrag_ = &frag;

        generateBlock(block, func, exitLabel_);
        currentFunc_->fragments.push_back(std::move(frag));
    }

    // Эпилог (exit блок)
    {
        CodeFragment epilogue;
        epilogue.label = exitLabel_;
        currentFrag_ = &epilogue;

        if (!hasExplicitReturn) {
            // Нет неявного возврата — возвращаем none по умолчанию
            emit("push_none", Operand::none(), "default return value");
        }
        // Если hasExplicitReturn: значение уже на стеке (положено перед jmp exitLabel_)
        emit("ret", Operand::iconst(numArgs_),
             "return, clean " + std::to_string(numArgs_) + " args");

        currentFunc_->fragments.push_back(std::move(epilogue));
    }

    currentFunc_ = nullptr;
    currentFrag_ = nullptr;
}

void CodeGenerator::generateBlock(const BasicBlock& block, const FunctionInfo& func,
                                   const std::string& exitLabel) {
    for (const auto& op : block.operations) {
        if (op->kind == Operation::OP_RETURN) {
            // Вычисляем возвращаемое значение, прыгаем в exit
            emitOperation(op.get());
            return; // остальные операции блока после return не нужны
        }
        emitOperation(op.get());
        if (op->kind != Operation::OP_ASSIGN) {
            emit("pop", Operand::none(), "discard expression result");
        }
    }

    // Переходы блока
    if (block.condition) {
        std::string trueLabel, falseLabel;
        if (block.conditionalTrue >= 0) {
            const BasicBlock* tb = func.cfg.blocks[block.conditionalTrue].get();
            trueLabel = (tb->label == "exit") ? exitLabel
                : blockLabel(func.signature.name, block.conditionalTrue, tb->label);
        }
        if (block.conditionalFalse >= 0) {
            const BasicBlock* fb = func.cfg.blocks[block.conditionalFalse].get();
            falseLabel = (fb->label == "exit") ? exitLabel
                : blockLabel(func.signature.name, block.conditionalFalse, fb->label);
        }
        emitConditionAndJump(block.condition.get(), trueLabel, falseLabel);
    } else if (block.unconditionalNext >= 0) {
        const BasicBlock* nb = func.cfg.blocks[block.unconditionalNext].get();
        std::string nextLabel = (nb->label == "exit") ? exitLabel
            : blockLabel(func.signature.name, block.unconditionalNext, nb->label);
        emit("jmp", Operand::label(nextLabel));
    }
}

void CodeGenerator::generateBlock(const BasicBlock& block, const FunctionInfo& func) {
    generateBlock(block, func, exitLabel_);
}

void CodeGenerator::emitOperation(const Operation* op) {
    if (op == nullptr) return;

    switch (op->kind) {
    case Operation::OP_LITERAL: {
        const std::string& s = op->value;
        if (s == "true")  { emit("push_bool", Operand::iconst(1)); break; }
        if (s == "false") { emit("push_bool", Operand::iconst(0)); break; }
        if (s.size() >= 3 && s[0] == '\'' && s.back() == '\'') {
            emit("push_char", Operand::iconst(static_cast<int64_t>(s[1]))); break;
        }
        if (s.size() >= 2 && s[0] == '"') {
            int idx = addStringConstant(s);
            emit("push_const", Operand::constIdx(idx), "string"); break;
        }
        if (s.size() > 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) {
            emit("push_int", Operand::iconst(std::stoll(s, nullptr, 16))); break;
        }
        if (s.size() > 2 && s[0] == '0' && (s[1] == 'b' || s[1] == 'B')) {
            emit("push_int", Operand::iconst(std::stoll(s.substr(2), nullptr, 2))); break;
        }
        int64_t val = 0;
        try { val = std::stoll(s); } catch (...) {}
        emit("push_int", Operand::iconst(val));
        break;
    }

    case Operation::OP_PLACE: {
        auto ait = argSlots_.find(op->value);
        if (ait != argSlots_.end())
            emit("load_arg", Operand::index(ait->second), op->value);
        else
            emit("load_local", Operand::index(getLocalSlot(op->value)), op->value);
        break;
    }

    case Operation::OP_ASSIGN: {
        if (op->operands.size() < 2) break;
        const Operation* lhs = op->operands[0].get();
        const Operation* rhs = op->operands[1].get();
        if (lhs->kind == Operation::OP_PLACE) {
            emitOperation(rhs);
            auto ait = argSlots_.find(lhs->value);
            if (ait != argSlots_.end())
                emit("store_arg", Operand::index(ait->second), lhs->value);
            else
                emit("store_local", Operand::index(getLocalSlot(lhs->value)), lhs->value);
        } else if (lhs->kind == Operation::OP_INDEX) {
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
        const std::string& b = op->value;
        if      (b == "+")  emit("add");
        else if (b == "-")  emit("sub");
        else if (b == "*")  emit("mul");
        else if (b == "/")  emit("div");
        else if (b == "%")  emit("mod");
        else if (b == "&")  emit("bit_and");
        else if (b == "|")  emit("bit_or");
        else if (b == "^")  emit("bit_xor");
        else if (b == "<<") emit("bit_shl");
        else if (b == ">>") emit("bit_shr");
        else if (b == "&&") emit("log_and");
        else if (b == "||") emit("log_or");
        else if (b == "==") emit("cmp_eq");
        else if (b == "!=") emit("cmp_ne");
        else if (b == "<")  emit("cmp_lt");
        else if (b == ">")  emit("cmp_gt");
        else if (b == "<=") emit("cmp_le");
        else if (b == ">=") emit("cmp_ge");
        else if (b == "..") emit("make_range");
        else addError("unknown binary operator: " + b, op->loc);
        break;
    }

    case Operation::OP_UNARY: {
        if (op->operands.empty()) break;
        emitOperation(op->operands[0].get());
        const std::string& u = op->value;
        if      (u == "-")              emit("neg");
        else if (u == "~")              emit("bit_not");
        else if (u == "!")              emit("log_not");
        else if (u == "++" || u == "post++") emit("inc");
        else if (u == "--" || u == "post--") emit("dec_op");
        else addError("unknown unary operator: " + u, op->loc);
        if ((u == "post++" || u == "post--") &&
            !op->operands.empty() && op->operands[0]->kind == Operation::OP_PLACE) {
            emit("dup");
            auto ait = argSlots_.find(op->operands[0]->value);
            if (ait != argSlots_.end())
                emit("store_arg", Operand::index(ait->second));
            else
                emit("store_local", Operand::index(getLocalSlot(op->operands[0]->value)));
        }
        break;
    }

    case Operation::OP_CALL: {
        if (op->operands.empty()) break;
        int argCount = static_cast<int>(op->operands.size()) - 1;

        // Аргументы пушатся в ОБРАТНОМ порядке (справа налево).
        // Тогда arg[0] — последний push — лежит ближе всего к fp,
        // и load_arg 0 = stack[fp - 12 - 0*9] читает arg[0] корректно.
        for (int a = argCount; a >= 1; --a) {
            emitOperation(op->operands[a].get());
        }

        if (op->operands[0]->kind == Operation::OP_PLACE)
            emit("call", Operand::label(op->operands[0]->value),
                 "args=" + std::to_string(argCount));
        else {
            emitOperation(op->operands[0].get());
            emit("call_indirect", Operand::iconst(argCount));
        }
        // После ret_op callee: TOS = возвращаемое значение
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
            for (size_t i = 1; i < op->operands.size(); ++i)
                emitOperation(op->operands[i].get());
            emit("arr_slice");
        }
        break;
    }

    case Operation::OP_RETURN: {
        // Вычисляем возвращаемое значение и кладём на стек
        if (!op->operands.empty())
            emitOperation(op->operands[0].get());
        else
            emit("push_none", Operand::none(), "void return");
        // Прыгаем в exit — там стоит ret N
        emit("jmp", Operand::label(exitLabel_), "implicit return");
        break;
    }
    }
}

void CodeGenerator::emitConditionAndJump(const Operation* cond,
    const std::string& trueLabel, const std::string& falseLabel) {
    emitOperation(cond);
    emit("jnz", Operand::label(trueLabel));
    emit("jmp", Operand::label(falseLabel));
}
