`timescale 1ns / 1ps

module add(
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] sum
);
    // Bit-level propagate and generate signals
    wire [31:0] p = a ^ b;
    wire [31:0] g = a & b;

    // Kogge–Stone parallel-prefix network
    localparam integer STAGES = 5; // ceil(log2(32))

    wire [31:0] P [0:STAGES - 1];
    wire [31:0] G [0:STAGES];

    assign P[0] = p;
    assign G[0] = g;

    genvar s, j;
    generate
        for (s = 0; s < STAGES; s = s + 1) begin : LEVEL
            localparam integer SHIFT = 1 << s;
            for (j = 0; j < 32; j = j + 1) begin : NODE
                if (s < STAGES - 1) begin
                    if (j < SHIFT) begin
                        assign G[s + 1][j] = G[s][j];
                        assign P[s + 1][j] = P[s][j];
                    end else begin
                        black_cell bc(
                            .Gout(G[s + 1][j]),
                            .Pout(P[s + 1][j]),
                            .Gin_hi(G[s][j]),
                            .Pin_hi(P[s][j]),
                            .Gin_lo(G[s][j - SHIFT]),
                            .Pin_lo(P[s][j - SHIFT])
                        );
                    end
                end else begin
                    if (j < SHIFT) begin
                        assign G[s + 1][j] = G[s][j];
                    end else begin
                        gray_cell gc(
                            .Gout(G[s + 1][j]),
                            .Gin_hi(G[s][j]),
                            .Pin_hi(P[s][j]),
                            .Gin_lo(G[s][j - SHIFT])
                        );
                    end
                end
            end
        end
    endgenerate

    // Derive carries: carry into bit 0 is 0, into bit (i+1) is the corresponding prefix generate
    wire [32:0] carry;
    assign carry[0] = 1'b0;

    generate
        for (j = 0; j < 32; j = j + 1) begin : CARRY_ASSIGN
            assign carry[j + 1] = G[STAGES][j];
        end
    endgenerate

    // Sum bits combine the original propagate with their incoming carry
    assign sum = p ^ carry[31:0];
endmodule


module black_cell(
    output Gout,
    output Pout,
    input  Gin_hi,
    input  Pin_hi,
    input  Gin_lo,
    input  Pin_lo
);
    assign Gout = Gin_hi | (Pin_hi & Gin_lo);
    assign Pout = Pin_hi & Pin_lo;
endmodule


module gray_cell(
    output Gout,
    input  Gin_hi,
    input  Pin_hi,
    input  Gin_lo
);
    assign Gout = Gin_hi | (Pin_hi & Gin_lo);
endmodule
