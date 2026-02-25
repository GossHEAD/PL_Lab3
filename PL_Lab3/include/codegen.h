#ifndef CODEGEN_H
#define CODEGEN_H

#include "cfg.h"
#include "program_image.h"
#include <string>
#include <vector>
#include <map>

struct CodegenError {
    std::string message;
    std::string sourceFile;
    SourceLocation loc;
};

struct CodegenResult {
    ProgramImage image;
    std::vector<CodegenError> errors;
};

class CodeGenerator {
public:
    CodegenResult generate(const ProgramInfo& program);

private:
    void generateFunction(const FunctionInfo& func);

    void generateBlock(const BasicBlock& block, const FunctionInfo& func,
                       const std::string& exitLabel);
    void generateBlock(const BasicBlock& block, const FunctionInfo& func);

    void emitOperation(const Operation* op);

    void emitConditionAndJump(const Operation* cond,
                              const std::string& trueLabel,
                              const std::string& falseLabel);

    std::string blockLabel(const std::string& funcName, int blockId,
                           const std::string& hint) const;

    int getLocalSlot(const std::string& varName);
    int getArgSlot(const std::string& argName);
    int addStringConstant(const std::string& str);

    void emit(const Instruction& instr);
    void emit(const std::string& mnemonic);
    void emit(const std::string& mnemonic, Operand op);
    void emit(const std::string& mnemonic, Operand op, const std::string& comment);
    void addError(const std::string& msg, SourceLocation loc);

    std::vector<int> topoOrder(const ControlFlowGraph& cfg);

    ProgramImage image_;
    std::vector<CodegenError> errors_;
    std::string currentFile_;

    FunctionCode* currentFunc_;
    CodeFragment* currentFrag_;
    std::map<std::string, int> localSlots_;
    std::map<std::string, int> argSlots_;
    int nextLocalSlot_;
    int numArgs_;

    std::string exitLabel_;
};

#endif // CODEGEN_H
