#ifndef PROGRAM_IMAGE_H
#define PROGRAM_IMAGE_H

#include <string>
#include <vector>
#include <cstdint>

struct Operand {
    enum Kind {
        NONE,
        INDEX,
        ICONST,
        LABEL,
        CONST_IDX,
    };

    Kind kind;
    int64_t intValue;
    std::string strValue;

    Operand() : kind(NONE), intValue(0) {}

    static Operand none() { Operand o; return o; }
    static Operand index(int idx) { Operand o; o.kind = INDEX; o.intValue = idx; return o; }
    static Operand iconst(int64_t v) { Operand o; o.kind = ICONST; o.intValue = v; return o; }
    static Operand label(const std::string& l) { Operand o; o.kind = LABEL; o.strValue = l; return o; }
    static Operand constIdx(int idx) { Operand o; o.kind = CONST_IDX; o.intValue = idx; return o; }

    std::string toString() const;
};

struct Instruction {
    std::string mnemonic;
    Operand operand;
    std::string comment;

    Instruction() = default;
    explicit Instruction(const std::string& mn)
        : mnemonic(mn) {}
    Instruction(const std::string& mn, Operand op)
        : mnemonic(mn), operand(op) {}
    Instruction(const std::string& mn, Operand op, const std::string& cmt)
        : mnemonic(mn), operand(op), comment(cmt) {}
};

struct ConstantEntry {
    enum Kind { CONST_STRING, CONST_INT };
    Kind kind;
    std::string strValue;
    int64_t intValue;
    std::string label;

    ConstantEntry() : kind(CONST_INT), intValue(0) {}
};

struct DataElement {
    std::string label;
    int sizeBytes;

    DataElement() : sizeBytes(0) {}
    DataElement(const std::string& l, int sz) : label(l), sizeBytes(sz) {}
};

struct CodeFragment {
    std::string label;
    std::vector<Instruction> instructions;
};

struct FunctionCode {
    std::string name;
    int numLocals;
    int numArgs;
    std::vector<CodeFragment> fragments;

    FunctionCode() : numLocals(0), numArgs(0) {}
};

struct ProgramImage {
    std::vector<ConstantEntry> constants;
    std::vector<DataElement> data;
    std::vector<FunctionCode> code;
    std::vector<std::string> externFunctions;
    std::vector<std::string> includeFiles;

    std::string toListing() const;
};

#endif