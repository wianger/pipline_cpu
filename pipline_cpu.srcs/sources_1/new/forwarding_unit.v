`timescale 1ns / 1ps

module forwarding_unit(
    input wire [4:0] id_ex_rs,      // 当前EX阶段指令的源寄存器Rs
    input wire [4:0] id_ex_rt,      // 当前EX阶段指令的源寄存器Rt
    input wire [4:0] ex_mem_rd,     // 前一条指令(MEM阶段)的目的寄存器Rd
    input wire       ex_mem_reg_write, // MEM阶段指令的写使能
    input wire [4:0] mem_wb_rd,     // 前前一条指令(WB阶段)的目的寄存器Rd
    input wire       mem_wb_reg_write, // WB阶段指令的写使能
    output reg [1:0] forward_a,     // ALU输入A的选择信号
    output reg [1:0] forward_b      // ALU输入B的选择信号
);
    // forward_a/b 编码:
    // 00: 来自寄存器堆 (ID/EX)
    // 10: 来自EX/MEM阶段 (上条指令结果) - 优先
    // 01: 来自MEM/WB阶段 (上上条指令结果)
    always @(*) begin
        // 默认不转发
        forward_a = 2'b00;
        forward_b = 2'b00;
        // --- EX Hazard (MEM阶段转发) ---
        // 如果上一条指令要写寄存器，且不是$0，且写的寄存器等于当前指令的Rs
        if (ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs)) begin
            forward_a = 2'b10;
        end

        // 如果上一条指令要写寄存器，且不是$0，且写的寄存器等于当前指令的Rt
        if (ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rt)) begin
            forward_b = 2'b10;
        end

        // --- MEM Hazard (WB阶段转发) ---
        // 如果上上条指令要写寄存器，且不是$0，且写的寄存器等于当前指令的Rs
        // 并且！上一条指令没有覆盖这个寄存器 (Double Data Hazard处理)
        if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs) &&
            !(ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs))) begin
            forward_a = 2'b01;
        end

        if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rt) &&
            !(ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rt))) begin
            forward_b = 2'b01;
        end
    end

endmodule
