`timescale 1ns / 1ps

module instruction_memory(
    input  [31:0] address,
    output [31:0] instruction
);
    // Instruction Memory: 4KB (1024 words)
    reg [31:0] memory [0:1023];

    initial begin
        // Load instructions from external file (hex format)
        $readmemh("code.txt", memory);
    end

    // Address is word-aligned; use bits [11:2] to index 1024 words
    assign instruction = memory[address[11:2]];
endmodule