`timescale 1ns / 1ps

module registers(
    input           reset,
    input           clock,
    input  [4:0]    readregister1,
    input  [4:0]    readregister2,
    input           regwrite,
    input  [4:0]    writeregister,
    input  [31:0]   writedata,
    input  [31:0]   pc,
    output [31:0]   readdata1,
    output [31:0]   readdata2
);
    reg [31:0] registers [0:31];
    integer i;
    always @(negedge clock or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (regwrite) begin
            if (writeregister != 0) begin
                registers[writeregister] <= writedata;
                // Always display for debugging
                $display("@%h: $%d <= %h", pc, writeregister, writedata);
            end else begin
                // Even if writing to $0, we might need to display it if Mars does.
                // Mars usually displays writes to $0 if it's an explicit instruction.
                $display("@%h: $%d <= %h", pc, writeregister, writedata);
            end
        end
    end

    assign readdata1 = (readregister1 == 0) ? 32'b0 : registers[readregister1];
    assign readdata2 = (readregister2 == 0) ? 32'b0 : registers[readregister2];
endmodule