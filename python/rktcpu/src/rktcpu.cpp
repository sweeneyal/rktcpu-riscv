#include <array>
#include <stdint.h>

struct instruction_t
{
    uint32_t pc;
    uint8_t opcode;
    uint8_t rs1;
    uint8_t rs2;
    uint8_t rd;

    uint32_t itype;
    uint32_t stype;
    uint32_t utype;
    uint32_t btype;
    uint32_t jtype;
};

const std::size_t EXECUTE_IDX   = 0;
const std::size_t MEMACCESS_IDX = 1;
const std::size_t WRITEBACK_IDX = 2;

const uint8_t ALU_OPCODE       = 0b0110011;
const uint8_t ALU_IMMED_OPCODE = 0b0010011;
const uint8_t LSU_LOAD_OPCODE  = 0b0000011;
const uint8_t LSU_STORE_OPCODE = 0b0100011;
const uint8_t BRANCH_OPCODE    = 0b1100011;
const uint8_t JUMP_OPCODE      = 0b1101111;
const uint8_t JALR_OPCODE      = 0b1100111;
const uint8_t LUI_OPCODE       = 0b0110111;
const uint8_t AUIPC_OPCODE     = 0b0010111;
const uint8_t FENCE_OPCODE     = 0b0001111;
const uint8_t ECALL_OPCODE     = 0b1110011;

class RktCpu
{
private:
    /* data */
    instruction_t instruction;

    std::array<uint32_t, 32> m_registers;

public:
    RktCpu(/* args */);
    ~RktCpu();

    void fetch(uint32_t pc);
    void decode(uint32_t instr);
    void execute();
    void step();
};

RktCpu::RktCpu(/* args */)
{
}

RktCpu::~RktCpu()
{
}

void RktCpu::fetch(uint32_t pc) {}
void RktCpu::decode(uint32_t instr) {}
void RktCpu::execute() {}

void RktCpu::step() {
    // fetch instruction
    // decode instruction
    // run instruction
    // log result of instruction
}

// void RktCpu::assign_signals() {
//     auto & execute_stage = m_pipeline[EXECUTE_IDX];
//     auto & memaccess_stage = m_pipeline[MEMACCESS_IDX];
//     auto & writeback_stage = m_pipeline[WRITEBACK_IDX];



//     m_ma_operanda = m_ex_operanda;
//     m_ma_operandb = m_ex_operandb;

//     m_ex_operanda = m_registers[execute_stage.rs1];
//     m_ex_operandb = m_registers[execute_stage.rs2];

//     if (m_hazard_rs1.first) {
//         if (m_hazard_rs1.second == MEMACCESS_IDX)
//             m_ex_operanda = m_aluresult;
//         else
//             m_ex_operanda = m_wbresult;
//     }

//     if (m_hazard_rs2.first) {
//         if (m_hazard_rs2.second == MEMACCESS_IDX)
//             m_ex_operandb = m_aluresult;
//         else
//             m_ex_operandb = m_wbresult;
//     }

//     switch (execute_stage.opcode)
//     {
//     case LSU_LOAD_OPCODE:
//     case JALR_OPCODE:
//     case ALU_IMMED_OPCODE:
//         m_ex_operandb = execute_stage.itype;
//         break;

//     case LUI_OPCODE:
//     case AUIPC_OPCODE:
//         m_ex_operandb = execute_stage.utype;
//         break;

//     case JUMP_OPCODE:
//         m_ex_operandb = execute_stage.jtype;
//         break;

//     case LSU_STORE_OPCODE:
//         m_ex_operandb = execute_stage.stype;
//         break;

//     case BRANCH_OPCODE:
//         m_ex_operandb = execute_stage.btype;
//         break;

//     default:
//         break;
//     }
    
// }