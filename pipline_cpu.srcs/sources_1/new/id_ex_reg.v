`timescale 1ns / 1ps

module id_ex_reg(
    input wire clock,
    input wire reset,
    input wire stall,       // 暂停信号
    input wire flush,       // 清除信号 (用于Load-Use冒险插入气泡)
    // --- 来自ID阶段的信息 ---
    // 1. 控制信号 - WB段 (Write Back)
    input wire id_reg_write,    // 寄存器堆写使能
    input wire id_mem_to_reg,   // 写回数据来源选择 (0:ALU结果, 1:内存数据)
    // 2. 控制信号 - MEM段 (Memory)
    input wire id_mem_read,     // 内存读使能
    input wire id_mem_write,    // 内存写使能
    input wire id_branch,       // 分支指令标志
    input wire id_branch_taken, // 分支/跳转实际发生标志 (Added for Delay Slot handling)
    input wire [1:0] id_mem_size, // 内存访问大小
    input wire id_mem_unsigned,   // 内存无符号加载
    // 3. 控制信号 - EX段 (Execute)
    input wire [5:0] id_alu_op, // ALU操作码
    input wire id_alu_src,      // ALU源操作数B选择 (0:寄存器数据, 1:立即数)
    input wire id_reg_dst,      // 目的寄存器地址选择 (0:rt, 1:rd)
    // 4. 数据信号
    input wire [31:0] id_pc,        // PC+4
    input wire [31:0] id_read_data1,// 寄存器堆读出数据1 (Rs)
    input wire [31:0] id_read_data2,// 寄存器堆读出数据2 (Rt)
    input wire [31:0] id_imm,       // 符号扩展后的立即数
    input wire [4:0]  id_shamt,     // 移位量
    input wire [4:0]  id_rs,        // Rs寄存器地址 (用于转发)
    input wire [4:0]  id_rt,        // Rt寄存器地址 (用于转发和作为目的寄存器)
    input wire [4:0]  id_rd,        // Rd寄存器地址 (作为目的寄存器)
    // --- 输出到EX阶段的信息 ---
    // 1. 控制信号 - WB段
    output reg ex_reg_write,
    output reg ex_mem_to_reg,
    // 2. 控制信号 - MEM段
    output reg ex_mem_read,
    output reg ex_mem_write,
    output reg ex_branch,
    output reg ex_branch_taken, // Added
    output reg [1:0] ex_mem_size,
    output reg ex_mem_unsigned,
    // 3. 控制信号 - EX段
    output reg [5:0] ex_alu_op,
    output reg ex_alu_src,
    output reg ex_reg_dst,
    // 4. 数据信号
    output reg [31:0] ex_pc,
    output reg [31:0] ex_read_data1,
    output reg [31:0] ex_read_data2,
    output reg [31:0] ex_imm,
    output reg [4:0]  ex_shamt,
    output reg [4:0]  ex_rs,
    output reg [4:0]  ex_rt,
    output reg [4:0]  ex_rd
);
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // 复位所有输出
            ex_reg_write  <= 1'b0;
            ex_mem_to_reg <= 1'b0;
            ex_mem_read   <= 1'b0;
            ex_mem_write  <= 1'b0;
            ex_branch     <= 1'b0;
            ex_branch_taken <= 1'b0;
            ex_mem_size   <= 2'b00;
            ex_mem_unsigned <= 1'b0;
            ex_alu_op     <= 6'b0;
            ex_alu_src    <= 1'b0;
            ex_reg_dst    <= 1'b0;
            ex_pc         <= 32'h0000_3000;
            ex_read_data1 <= 32'b0;
            ex_read_data2 <= 32'b0;
            ex_imm        <= 32'b0;
            ex_shamt      <= 5'b0;
            ex_rs         <= 5'b0;
            ex_rt         <= 5'b0;
            ex_rd         <= 5'b0;
        end else if (flush) begin
            // 冲刷流水线，控制信号清零 (插入气泡)
            ex_reg_write  <= 1'b0;
            ex_mem_to_reg <= 1'b0;
            ex_mem_read   <= 1'b0;
            ex_mem_write  <= 1'b0;
            ex_branch     <= 1'b0;
            ex_branch_taken <= 1'b0;
            ex_mem_size   <= 2'b00;
            ex_mem_unsigned <= 1'b0;
            // 数据信号清零 (可选，但为了调试方便通常清零)
            ex_alu_op     <= 6'b0;
            ex_alu_src    <= 1'b0;
            ex_reg_dst    <= 1'b0;
            ex_pc         <= 32'h0000_3000;
            ex_read_data1 <= 32'b0;
            ex_read_data2 <= 32'b0;
            ex_imm        <= 32'b0;
            ex_shamt      <= 5'b0;
            ex_rs         <= 5'b0;
            ex_rt         <= 5'b0;
            ex_rd         <= 5'b0;
        end else if (!stall) begin
            ex_reg_write  <= id_reg_write;
            ex_mem_to_reg <= id_mem_to_reg;
            ex_mem_read   <= id_mem_read;
            ex_mem_write  <= id_mem_write;
            ex_branch     <= id_branch;
            ex_branch_taken <= id_branch_taken;
            ex_mem_size   <= id_mem_size;
            ex_mem_unsigned <= id_mem_unsigned;
            ex_alu_op     <= id_alu_op;
            ex_alu_src    <= id_alu_src;
            ex_reg_dst    <= id_reg_dst;
            ex_pc         <= id_pc;
            ex_read_data1 <= id_read_data1;
            ex_read_data2 <= id_read_data2;
            ex_imm        <= id_imm;
            ex_shamt      <= id_shamt;
            ex_rs         <= id_rs;
            ex_rt         <= id_rt;
            ex_rd         <= id_rd;
        end
    end
endmodule
