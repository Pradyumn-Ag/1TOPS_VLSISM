`timescale 1ns / 1ps

// Carry-Save Adder - reduces 3 N-bit numbers to 2 N-bit numbers.
// Does NOT propagate carry - every bit is independent (just a column of FAs).
// PS[i] = A[i] ^ B[i] ^ D[i]       (partial sum)
// PC[i] = majority(A[i], B[i], D[i]) (partial carry - NOT shifted here)
// Caller is responsible for shifting PC left by 1 before the next stage.
module CSA #(
    parameter N = 128                    // bit-width (= 2*W)
)(
    input  wire [N-1:0] A, B_in, D,
    output wire [N-1:0] PS, PC           // Partial Sum, Partial Carry
);
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : csa_bits
            FA fa (
                .a   (A[i]),
                .b   (B_in[i]),
                .cin (D[i]),
                .sum (PS[i]),
                .cout(PC[i])
            );
        end
    endgenerate
endmodule