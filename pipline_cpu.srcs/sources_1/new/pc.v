`timescale 1ns / 1ps

module pc(
    input           reset,
    input           clock,
    input           pcwrite,
    input  [31:0]   nextpc,
    output [31:0]   pcValue
);
    reg [31:0] pc_reg;
    localparam RESET_PC = 32'h0000_3000;
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            pc_reg <= RESET_PC;
        end else if (pcwrite) begin
            pc_reg <= nextpc;
        end
    end
    assign pcValue = pc_reg;
endmodule
