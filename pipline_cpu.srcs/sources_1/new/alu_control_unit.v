`timescale 1ns / 1ps

module alu_control_unit(
    input wire [3:0] alu_op_type, 
    input wire [5:0] funct,       
    output reg [5:0] alu_control 
);
    // ALU Control Codes (Must match alu.v)
    localparam ALU_SLL  = 6'b000000;
    localparam ALU_SRL  = 6'b000010;
    localparam ALU_SRA  = 6'b000011;
    localparam ALU_ADD  = 6'b100000;
    localparam ALU_ADDU = 6'b100001;
    localparam ALU_SUB  = 6'b100010;
    localparam ALU_SUBU = 6'b100011;
    localparam ALU_AND  = 6'b100100;
    localparam ALU_OR   = 6'b100101;
    localparam ALU_XOR  = 6'b100110;
    localparam ALU_NOR  = 6'b100111;
    localparam ALU_LUI  = 6'b101000;
    localparam ALU_SLT  = 6'b101010;
    localparam ALU_SLTU = 6'b101011;
    localparam ALU_SLLV = 6'b000100;
    localparam ALU_SRLV = 6'b000110;
    localparam ALU_SRAV = 6'b000111;
    localparam ALU_MFHI = 6'b010000;
    localparam ALU_MFLO = 6'b010001;
    localparam ALU_MTHI = 6'b010010;
    localparam ALU_MTLO = 6'b010011;
    localparam ALU_MULT = 6'b011000;
    localparam ALU_MULTU= 6'b011001;
    localparam ALU_DIV  = 6'b011010;
    localparam ALU_DIVU = 6'b011011;

    // ALU Op Types (Protocol with Main Control)
    localparam TYPE_ADD    = 4'b0000; // LW, SW, JAL, ADDIU
    localparam TYPE_SUB    = 4'b0001; // BEQ
    localparam TYPE_R_TYPE = 4'b0010; // R-Type (Look at funct)
    localparam TYPE_OR     = 4'b0011; // ORI
    localparam TYPE_LUI    = 4'b0100; // LUI
    localparam TYPE_AND    = 4'b0101; // ANDI
    localparam TYPE_XOR    = 4'b0110; // XORI
    localparam TYPE_SLT    = 4'b0111; // SLTI
    localparam TYPE_SLTU   = 4'b1000; // SLTIU

    // Funct Codes (Standard MIPS)
    localparam FUNCT_SLL  = 6'b000000;
    localparam FUNCT_SRL  = 6'b000010;
    localparam FUNCT_SRA  = 6'b000011;
    localparam FUNCT_ADD  = 6'b100000;
    localparam FUNCT_ADDU = 6'b100001;
    localparam FUNCT_SUB  = 6'b100010;
    localparam FUNCT_SUBU = 6'b100011;
    localparam FUNCT_AND  = 6'b100100;
    localparam FUNCT_OR   = 6'b100101;
    localparam FUNCT_XOR  = 6'b100110;
    localparam FUNCT_NOR  = 6'b100111;
    localparam FUNCT_SLT  = 6'b101010;
    localparam FUNCT_SLTU = 6'b101011;
    localparam FUNCT_SLLV = 6'b000100;
    localparam FUNCT_SRLV = 6'b000110;
    localparam FUNCT_SRAV = 6'b000111;
    localparam FUNCT_MFHI = 6'b010000;
    localparam FUNCT_MFLO = 6'b010010;
    localparam FUNCT_MTHI = 6'b010001;
    localparam FUNCT_MTLO = 6'b010011;
    localparam FUNCT_MULT = 6'b011000;
    localparam FUNCT_MULTU= 6'b011001;
    localparam FUNCT_DIV  = 6'b011010;
    localparam FUNCT_DIVU = 6'b011011;

    always @(*) begin
        case (alu_op_type)
            TYPE_ADD:    alu_control = ALU_ADD;
            TYPE_SUB:    alu_control = ALU_SUB;
            TYPE_OR:     alu_control = ALU_OR;
            TYPE_LUI:    alu_control = ALU_LUI;
            TYPE_AND:    alu_control = ALU_AND;
            TYPE_XOR:    alu_control = ALU_XOR;
            TYPE_SLT:    alu_control = ALU_SLT;
            TYPE_SLTU:   alu_control = ALU_SLTU;
            
            TYPE_R_TYPE: begin
                case (funct)
                    FUNCT_ADD:  alu_control = ALU_ADD;
                    FUNCT_ADDU: alu_control = ALU_ADDU;
                    FUNCT_SUB:  alu_control = ALU_SUB;
                    FUNCT_SUBU: alu_control = ALU_SUBU;
                    FUNCT_AND:  alu_control = ALU_AND;
                    FUNCT_OR:   alu_control = ALU_OR;
                    FUNCT_XOR:  alu_control = ALU_XOR;
                    FUNCT_NOR:  alu_control = ALU_NOR;
                    FUNCT_SLL:  alu_control = ALU_SLL;
                    FUNCT_SRL:  alu_control = ALU_SRL;
                    FUNCT_SRA:  alu_control = ALU_SRA;
                    FUNCT_SLT:  alu_control = ALU_SLT;
                    FUNCT_SLTU: alu_control = ALU_SLTU;
                    FUNCT_SLLV: alu_control = ALU_SLLV;
                    FUNCT_SRLV: alu_control = ALU_SRLV;
                    FUNCT_SRAV: alu_control = ALU_SRAV;
                    FUNCT_MFHI: alu_control = ALU_MFHI;
                    FUNCT_MFLO: alu_control = ALU_MFLO;
                    FUNCT_MTHI: alu_control = ALU_MTHI;
                    FUNCT_MTLO: alu_control = ALU_MTLO;
                    FUNCT_MULT: alu_control = ALU_MULT;
                    FUNCT_MULTU:alu_control = ALU_MULTU;
                    FUNCT_DIV:  alu_control = ALU_DIV;
                    FUNCT_DIVU: alu_control = ALU_DIVU;
                    default:    alu_control = ALU_ADD; // Default
                endcase
            end
            default: alu_control = ALU_ADD;
        endcase
    end

endmodule
