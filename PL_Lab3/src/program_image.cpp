#include "../include/program_image.h"
#include <sstream>
#include <iomanip>

std::string Operand::toString() const {
    switch (kind) {
    case NONE:      return "";
    case INDEX:     return std::to_string(intValue);
    case ICONST:    return std::to_string(intValue);
    case LABEL:     return strValue;
    case CONST_IDX: return "#" + std::to_string(intValue);
    }
    return "?";
}

static std::string instrToString(const Instruction& instr) {
    std::string s = "    " + instr.mnemonic;
    if (instr.operand.kind != Operand::NONE) {
        s += " " + instr.operand.toString();
    }
    if (!instr.comment.empty()) {
        s += " ; " + instr.comment;
    }
    return s;
}

std::string ProgramImage::toListing() const {
    std::ostringstream out;

    if (!constants.empty()) {
        out << "[section _constants]\n";
        for (size_t i = 0; i < constants.size(); ++i) {
            const auto& c = constants[i];
            if (!c.label.empty()) {
                out << c.label << ":\n";
            }
            switch (c.kind) {
            case ConstantEntry::CONST_STRING:
                out << "    .string \"" << c.strValue << "\"";
                out << " ; const #" << i << "\n";
                break;
            case ConstantEntry::CONST_INT:
                out << "    .int " << c.intValue;
                out << " ; const #" << i << "\n";
                break;
            }
        }
        out << "\n";
    }

    if (!data.empty()) {
        out << "[section _data]\n";
        for (const auto& d : data) {
            out << d.label << ": resb " << d.sizeBytes << "\n";
        }
        out << "\n";
    }

    out << "[section _code]\n";

    out << "; === entry point ===\n";
    out << "_start:\n";
    out << "    init_sp 0x30000\n";
    out << "    call main\n";
    out << "    hlt\n";
    out << "\n";

    if (!externFunctions.empty()) {
        out << "; --- external functions (implemented elsewhere) ---\n";
        for (const auto& name : externFunctions) {
            out << "; extern " << name << "\n";
        }
        out << "\n";
    }

    for (const auto& func : code) {
        out << "; === function " << func.name
            << " (args=" << func.numArgs
            << ", locals=" << func.numLocals << ") ===\n";

        for (const auto& frag : func.fragments) {
            if (!frag.label.empty()) {
                out << frag.label << ":\n";
            }
            for (const auto& instr : frag.instructions) {
                out << instrToString(instr) << "\n";
            }
        }
        out << "\n";
    }

    out << "; [section stack] — managed by VM at runtime\n";

    for (const auto& content : includeFiles) {
        out << "\n; --- included external code ---\n";
        out << content;
        if (!content.empty() && content.back() != '\n') {
            out << "\n";
        }
    }

    return out.str();
}