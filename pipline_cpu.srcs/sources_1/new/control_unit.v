`timescale 1ns / 1ps

module control_unit(
    input  wire [5:0] opcode,
    input  wire [5:0] funct,
    output reg       reg_dst,     // 0: rt, 1: rd
    output reg       alu_src,     // 0: reg, 1: imm
    output reg       mem_to_reg,  // 0: ALU, 1: Mem
    output reg       reg_write,
    output reg       mem_read,
    output reg       mem_write,
    output reg       branch,      // beq
    output reg       jump,        // j
    output reg       jump_reg,    // jr
    output reg       jal,         // jal
    output reg       jalr,        // jalr
    output reg       sign_ext,    // 0: Zero Ext, 1: Sign Ext
    output reg [3:0] alu_op_type, // Output to ALU Control Unit
    output reg [1:0] mem_size,    // 00: Word, 01: Byte, 10: Half
    output reg       mem_unsigned // 0: Signed, 1: Unsigned (for loads)
);
    // Opcode definitions
    localparam OP_R_TYPE = 6'b000000;
    localparam OP_ADDI   = 6'b001000;
    localparam OP_ADDIU  = 6'b001001; 
    localparam OP_LW     = 6'b100011;
    localparam OP_SW     = 6'b101011;
    localparam OP_BEQ    = 6'b000100;
    localparam OP_BNE    = 6'b000101;
    localparam OP_BLEZ   = 6'b000110;
    localparam OP_BGTZ   = 6'b000111;
    localparam OP_REGIMM = 6'b000001;
    localparam OP_LUI    = 6'b001111; 
    localparam OP_ORI    = 6'b001101; 
    localparam OP_J      = 6'b000010;
    localparam OP_JAL    = 6'b000011;
    localparam OP_SLTI   = 6'b001010;
    localparam OP_SLTIU  = 6'b001011;
    localparam OP_ANDI   = 6'b001100;
    localparam OP_XORI   = 6'b001110;
    
    // Memory Access Opcodes
    localparam OP_LB     = 6'b100000;
    localparam OP_LH     = 6'b100001;
    localparam OP_LBU    = 6'b100100;
    localparam OP_LHU    = 6'b100101;
    localparam OP_SB     = 6'b101000;
    localparam OP_SH     = 6'b101001;

    // Funct definitions (Only needed for Control Flow signals like JR)
    localparam FUNCT_JR      = 6'b001000;
    localparam FUNCT_JALR    = 6'b001001;
    localparam FUNCT_SYSCALL = 6'b001100;
    localparam FUNCT_MULT    = 6'b011000;
    localparam FUNCT_MULTU   = 6'b011001;
    localparam FUNCT_DIV     = 6'b011010;
    localparam FUNCT_DIVU    = 6'b011011;
    localparam FUNCT_MTHI    = 6'b010001;
    localparam FUNCT_MTLO    = 6'b010011;
    
    // ALU Op Types (Protocol with ALU Control)
    localparam TYPE_ADD    = 4'b0000;
    localparam TYPE_SUB    = 4'b0001;
    localparam TYPE_R_TYPE = 4'b0010;
    localparam TYPE_OR     = 4'b0011;
    localparam TYPE_LUI    = 4'b0100;
    localparam TYPE_AND    = 4'b0101;
    localparam TYPE_XOR    = 4'b0110;
    localparam TYPE_SLT    = 4'b0111;
    localparam TYPE_SLTU   = 4'b1000;
    
    // Memory Sizes
    localparam SIZE_WORD = 2'b00;
    localparam SIZE_BYTE = 2'b01;
    localparam SIZE_HALF = 2'b10;

    always @(*) begin
        // Defaults
        reg_dst    = 1'b0;
        alu_src    = 1'b0;
        mem_to_reg = 1'b0;
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        jump_reg   = 1'b0;
        jal        = 1'b0;
        jalr       = 1'b0;
        sign_ext   = 1'b0; 
        alu_op_type = TYPE_ADD; // Default to ADD
        mem_size    = SIZE_WORD;
        mem_unsigned = 1'b0;

        case (opcode)
            OP_R_TYPE: begin
                alu_op_type = TYPE_R_TYPE; // Delegate to ALU Control
                
                // Handle R-type Control Flow signals
                if (funct == FUNCT_JR) begin
                    jump_reg = 1'b1;
                    reg_write = 1'b0; // JR doesn't write
                end else if (funct == FUNCT_JALR) begin
                    jump_reg = 1'b1;
                    reg_write = 1'b1;
                    reg_dst = 1'b1;
                    jalr = 1'b1;
                end else if (funct == FUNCT_SYSCALL || 
                             funct == FUNCT_MULT || funct == FUNCT_MULTU || 
                             funct == FUNCT_DIV || funct == FUNCT_DIVU ||
                             funct == FUNCT_MTHI || funct == FUNCT_MTLO) begin
                    reg_write = 1'b0; // These instructions do not write to GPR
                end else begin
                    reg_dst = 1'b1; 
                    reg_write = 1'b1;
                end
            end
            
            OP_ADDI: begin
                alu_src = 1'b1; reg_write = 1'b1;
                alu_op_type = TYPE_ADD;
                sign_ext = 1'b1;
            end

            OP_ADDIU: begin
                alu_src = 1'b1; reg_write = 1'b1;
                alu_op_type = TYPE_ADD;
                sign_ext = 1'b1;
            end

            OP_LW: begin
                alu_src = 1'b1; mem_to_reg = 1'b1; reg_write = 1'b1; mem_read = 1'b1; 
                alu_op_type = TYPE_ADD;
                sign_ext = 1'b1;
            end
            
            OP_LB: begin
                alu_src = 1'b1; mem_to_reg = 1'b1; reg_write = 1'b1; mem_read = 1'b1; 
                alu_op_type = TYPE_ADD;
                sign_ext = 1'b1;
                mem_size = SIZE_BYTE;
            end

            OP_LBU: begin
                alu_src = 1'b1; mem_to_reg = 1'b1; reg_write = 1'b1; mem_read = 1'b1; 
                alu_op_type = TYPE_ADD;
                sign_ext = 1'b1;
                mem_size = SIZE_BYTE;
                mem_unsigned = 1'b1;
            end

            OP_LH: begin
                alu_src = 1'b1; mem_to_reg = 1'b1; reg_write = 1'b1; mem_read = 1'b1; 
                alu_op_type = TYPE_ADD;
                sign_ext = 1'b1;
                mem_size = SIZE_HALF;
            end

            OP_LHU: begin
                alu_src = 1'b1; mem_to_reg = 1'b1; reg_write = 1'b1; mem_read = 1'b1; 
                alu_op_type = TYPE_ADD;
                sign_ext = 1'b1;
                mem_size = SIZE_HALF;
                mem_unsigned = 1'b1;
            end

            OP_SW: begin
                alu_src = 1'b1; mem_write = 1'b1; 
                alu_op_type = TYPE_ADD;
                sign_ext = 1'b1;
            end

            OP_SB: begin
                alu_src = 1'b1; mem_write = 1'b1; 
                alu_op_type = TYPE_ADD;
                sign_ext = 1'b1;
                mem_size = SIZE_BYTE;
            end

            OP_SH: begin
                alu_src = 1'b1; mem_write = 1'b1; 
                alu_op_type = TYPE_ADD;
                sign_ext = 1'b1;
                mem_size = SIZE_HALF;
            end
            
            OP_BEQ: begin
                branch = 1'b1; 
                alu_op_type = TYPE_SUB;
                sign_ext = 1'b1; 
            end

            OP_BNE: begin
                branch = 1'b1; 
                alu_op_type = TYPE_SUB;
                sign_ext = 1'b1; 
            end

            OP_BLEZ: begin
                branch = 1'b1; 
                alu_op_type = TYPE_SUB;
                sign_ext = 1'b1; 
            end

            OP_BGTZ: begin
                branch = 1'b1; 
                alu_op_type = TYPE_SUB;
                sign_ext = 1'b1; 
            end

            OP_REGIMM: begin
                branch = 1'b1; 
                alu_op_type = TYPE_SUB;
                sign_ext = 1'b1; 
            end
            
            OP_ORI: begin
                alu_src = 1'b1; reg_write = 1'b1; 
                alu_op_type = TYPE_OR;
                sign_ext = 1'b0; 
            end
            
            OP_ANDI: begin
                alu_src = 1'b1; reg_write = 1'b1; 
                alu_op_type = TYPE_AND;
                sign_ext = 1'b0; 
            end

            OP_XORI: begin
                alu_src = 1'b1; reg_write = 1'b1; 
                alu_op_type = TYPE_XOR;
                sign_ext = 1'b0; 
            end

            OP_SLTI: begin
                alu_src = 1'b1; reg_write = 1'b1; 
                alu_op_type = TYPE_SLT;
                sign_ext = 1'b1; 
            end

            OP_SLTIU: begin
                alu_src = 1'b1; reg_write = 1'b1; 
                alu_op_type = TYPE_SLTU;
                sign_ext = 1'b1; 
            end
            
            OP_LUI: begin
                alu_src = 1'b1; reg_write = 1'b1; 
                alu_op_type = TYPE_LUI;
            end
            
            OP_J: begin
                jump = 1'b1;
            end
            
            OP_JAL: begin
                jump = 1'b1; jal = 1'b1; reg_write = 1'b1;
                alu_op_type = TYPE_ADD; // JAL uses ADD for PC+8 calculation (if using ALU)
            end
        endcase
    end

endmodule
