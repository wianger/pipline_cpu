`timescale 1ns / 1ps

module mem_wb_reg(
    input wire clock,
    input wire reset,
    input wire stall,
    input wire flush,
    // --- 来自MEM阶段的信息 ---
    // 1. 控制信号 - WB段
    input wire mem_reg_write,
    input wire mem_mem_to_reg,
    // 2. 数据信号
    input wire [31:0] mem_read_data, // 来自数据存储器
    input wire [31:0] mem_alu_result,// 来自ALU计算结果
    input wire [4:0]  mem_write_reg, // 写回寄存器地址
    input wire [31:0] mem_pc,        // PC value
    // --- 输出到WB阶段的信息 ---
    // 1. 控制信号 - WB段
    output reg wb_reg_write,
    output reg wb_mem_to_reg,
    // 2. 数据信号
    output reg [31:0] wb_read_data,
    output reg [31:0] wb_alu_result,
    output reg [4:0]  wb_write_reg,
    output reg [31:0] wb_pc
);

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            wb_reg_write   <= 1'b0;
            wb_mem_to_reg  <= 1'b0;
            wb_read_data   <= 32'b0;
            wb_alu_result  <= 32'b0;
            wb_write_reg   <= 5'b0;
            wb_pc          <= 32'h0000_3000; // Initialize to start PC
        end else if (flush) begin
            wb_reg_write   <= 1'b0;
            wb_mem_to_reg  <= 1'b0;
            wb_read_data   <= 32'b0;
            wb_alu_result  <= 32'b0;
            wb_write_reg   <= 5'b0;
            wb_pc          <= 32'h0000_3000;
        end else if (!stall) begin
            wb_reg_write   <= mem_reg_write;
            wb_mem_to_reg  <= mem_mem_to_reg;
            wb_read_data   <= mem_read_data;
            wb_alu_result  <= mem_alu_result;
            wb_write_reg   <= mem_write_reg;
            wb_pc          <= mem_pc;
        end
    end

endmodule
