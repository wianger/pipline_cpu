`timescale 1ns / 1ps

module if_id_reg(
    input wire clock,
    input wire reset,
    input wire stall,       // 暂停信号，高电平有效。有效时保持输出不变
    input wire flush,       // 清除信号，高电平有效。有效时输出清零(插入NOP)
    input wire [31:0] if_pc,    // 来自IF阶段的PC (通常是PC+4)
    input wire [31:0] if_inst,  // 来自指令存储器的指令
    output reg [31:0] id_pc,    // 传递给ID阶段的PC
    output reg [31:0] id_inst   // 传递给ID阶段的指令
);
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            id_pc <= 32'h0000_3000;
            id_inst <= 32'b0;
        end else if (flush) begin
            id_pc <= 32'h0000_3000;
            id_inst <= 32'b0; // 通常清零代表NOP指令 (SLL r0, r0, 0)
        end else if (!stall) begin
            id_pc <= if_pc;
            id_inst <= if_inst;
        end
    end
endmodule
