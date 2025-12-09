`timescale 1ns / 1ps

module branch_unit(
    input wire [5:0]  opcode,
    input wire [5:0]  funct,
    input wire [4:0]  rt_index,     // Added: rt index for REGIMM
    input wire [31:0] rs_data,
    input wire [31:0] rt_data,
    input wire [31:0] pc_plus_4,    // ID阶段的PC+4
    input wire [25:0] instr_index,  // J-type指令的索引
    output reg        branch_taken, // 分支/跳转是否发生
    output reg [31:0] branch_target // 跳转目标地址
);
    // Opcode definitions
    localparam OP_BEQ = 6'b000100;
    localparam OP_BNE = 6'b000101; 
    localparam OP_BLEZ = 6'b000110;
    localparam OP_BGTZ = 6'b000111;
    localparam OP_REGIMM = 6'b000001; // Added
    localparam OP_J   = 6'b000010;
    localparam OP_JAL = 6'b000011;
    localparam OP_R_TYPE = 6'b000000;
    
    // Funct definitions for R-type
    localparam FUNCT_JR = 6'b001000;
    localparam FUNCT_JALR = 6'b001001;
    
    // Rt definitions for REGIMM
    localparam RT_BLTZ = 5'b00000;
    localparam RT_BGEZ = 5'b00001;
    localparam RT_BLTZAL = 5'b10000;
    localparam RT_BGEZAL = 5'b10001;

    always @(*) begin
        branch_taken = 1'b0;
        branch_target = 32'b0;

        case (opcode)
            OP_BEQ: begin
                if (rs_data == rt_data) begin
                    branch_taken = 1'b1;
                    // BEQ target: (offset << 2) + (PC+4)
                    // instr_index[15:0] is the offset (imm16)
                    branch_target = pc_plus_4 + {{14{instr_index[15]}}, instr_index[15:0], 2'b00};
                end
            end

            OP_BNE: begin
                if (rs_data != rt_data) begin
                    branch_taken = 1'b1;
                    branch_target = pc_plus_4 + {{14{instr_index[15]}}, instr_index[15:0], 2'b00};
                end
            end

            OP_BLEZ: begin
                if ($signed(rs_data) <= 0) begin
                    branch_taken = 1'b1;
                    branch_target = pc_plus_4 + {{14{instr_index[15]}}, instr_index[15:0], 2'b00};
                end
            end

            OP_BGTZ: begin
                if ($signed(rs_data) > 0) begin
                    branch_taken = 1'b1;
                    branch_target = pc_plus_4 + {{14{instr_index[15]}}, instr_index[15:0], 2'b00};
                end
            end
            
            OP_REGIMM: begin
                if (rt_index == RT_BLTZ || rt_index == RT_BLTZAL) begin
                    if ($signed(rs_data) < 0) begin
                        branch_taken = 1'b1;
                        branch_target = pc_plus_4 + {{14{instr_index[15]}}, instr_index[15:0], 2'b00};
                    end
                end else if (rt_index == RT_BGEZ || rt_index == RT_BGEZAL) begin
                    if ($signed(rs_data) >= 0) begin
                        branch_taken = 1'b1;
                        branch_target = pc_plus_4 + {{14{instr_index[15]}}, instr_index[15:0], 2'b00};
                    end
                end
            end
            
            OP_J, OP_JAL: begin
                branch_taken = 1'b1;
                // J target: { (PC+4)[31:28], address, 00 }
                branch_target = {pc_plus_4[31:28], instr_index, 2'b00};
            end

            OP_R_TYPE: begin
                if (funct == FUNCT_JR || funct == FUNCT_JALR) begin
                    branch_taken = 1'b1;
                    branch_target = rs_data;
                end
            end
            
            default: begin
                branch_taken = 1'b0;
            end
        endcase
    end

endmodule
