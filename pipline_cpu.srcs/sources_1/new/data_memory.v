`timescale 1ns / 1ps

module data_memory(
    input           reset,
    input           clock,
    input  [31:0]   address,
    input           memread,
    input           memwrite,
    input  [31:0]   writedata,
    input  [31:0]   pc,
    input  [1:0]    size, // 00: Word, 01: Byte, 10: Half
    output [31:0]   readdata
);
    // Increase memory to 16KB (4096 words) to avoid aliasing with the large loop
    reg [31:0] memory [0:4095];
    reg [31:0] temp_word;

    integer i;
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < 4096; i = i + 1) begin
                memory[i] <= 32'b0;
            end
        end else if (memwrite) begin
            // Use bits [13:2] for 4096 words
            temp_word = memory[address[13:2]];
            case (size)
                2'b00: begin // Word
                    memory[address[13:2]] <= writedata;
                    $display("@%h: *%h <= %h", pc, address, writedata); 
                end
                2'b01: begin // Byte
                    case (address[1:0])
                        2'b00: temp_word[7:0]   = writedata[7:0];
                        2'b01: temp_word[15:8]  = writedata[7:0];
                        2'b10: temp_word[23:16] = writedata[7:0];
                        2'b11: temp_word[31:24] = writedata[7:0];
                    endcase
                    memory[address[13:2]] <= temp_word;
                    $display("@%h: *%h <= %h", pc, {address[31:2], 2'b00}, temp_word);
                end
                2'b10: begin // Half
                    case (address[1])
                        1'b0: temp_word[15:0]  = writedata[15:0];
                        1'b1: temp_word[31:16] = writedata[15:0];
                    endcase
                    memory[address[13:2]] <= temp_word;
                    $display("@%h: *%h <= %h", pc, {address[31:2], 2'b00}, temp_word);
                end
            endcase
        end
    end

    assign readdata = (memread) ? memory[address[13:2]] : 32'b0;
endmodule
