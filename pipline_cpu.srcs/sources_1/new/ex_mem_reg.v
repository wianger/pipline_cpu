`timescale 1ns / 1ps

module ex_mem_reg(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire flush,
    // --- 来自EX阶段的信息 ---
    // 1. 控制信号 - WB段
    input wire ex_reg_write,
    input wire ex_mem_to_reg,
    // 2. 控制信号 - MEM段
    input wire ex_mem_read,
    input wire ex_mem_write,
    input wire ex_branch,
    input wire [1:0] ex_mem_size,
    input wire ex_mem_unsigned,
    // 3. 数据信号
    input wire [31:0] ex_alu_result,    // ALU计算结果
    input wire [31:0] ex_mem_write_data,// 写入内存的数据 (通常是rt寄存器的值，可能经过转发)
    input wire [4:0]  ex_write_reg,     // 写回寄存器地址 (rd 或 rt)
    input wire        ex_zero,          // ALU零标志 (用于分支判断)
    input wire [31:0] ex_branch_target, // 分支跳转目标地址
    input wire [31:0] ex_pc,            // EX阶段PC
    // --- 输出到MEM阶段的信息 ---
    // 1. 控制信号 - WB段
    output reg mem_reg_write,
    output reg mem_mem_to_reg,
    // 2. 控制信号 - MEM段
    output reg mem_mem_read,
    output reg mem_mem_write,
    output reg mem_branch,
    output reg [1:0] mem_mem_size,
    output reg mem_mem_unsigned,
    // 3. 数据信号
    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_write_data,
    output reg [4:0]  mem_write_reg,
    output reg        mem_zero,
    output reg [31:0] mem_branch_target,
    output reg [31:0] mem_pc
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_mem_read      <= 1'b0;
            mem_mem_write     <= 1'b0;
            mem_branch        <= 1'b0;
            mem_mem_size      <= 2'b00;
            mem_mem_unsigned  <= 1'b0;
            mem_alu_result    <= 32'b0;
            mem_write_data    <= 32'b0;
            mem_write_reg     <= 5'b0;
            mem_zero          <= 1'b0;
            mem_branch_target <= 32'b0;
            mem_pc            <= 32'h0000_3000;
        end else if (flush) begin
            mem_reg_write     <= 1'b0;
            mem_mem_to_reg    <= 1'b0;
            mem_mem_read      <= 1'b0;
            mem_mem_write     <= 1'b0;
            mem_branch        <= 1'b0;
            mem_mem_size      <= 2'b00;
            mem_mem_unsigned  <= 1'b0;
            mem_alu_result    <= 32'b0;
            mem_write_data    <= 32'b0;
            mem_write_reg     <= 5'b0;
            mem_zero          <= 1'b0;
            mem_branch_target <= 32'b0;
            mem_pc            <= 32'h0000_3000;
        end else if (!stall) begin
            mem_reg_write     <= ex_reg_write;
            mem_mem_to_reg    <= ex_mem_to_reg;
            mem_mem_read      <= ex_mem_read;
            mem_mem_write     <= ex_mem_write;
            mem_branch        <= ex_branch;
            mem_mem_size      <= ex_mem_size;
            mem_mem_unsigned  <= ex_mem_unsigned;
            mem_alu_result    <= ex_alu_result;
            mem_write_data    <= ex_mem_write_data;
            mem_write_reg     <= ex_write_reg;
            mem_zero          <= ex_zero;
            mem_branch_target <= ex_branch_target;
            mem_pc            <= ex_pc;
        end
    end
endmodule
