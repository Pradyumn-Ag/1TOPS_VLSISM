`timescale 1ns / 1ps

// 1-bit Full Adder - atomic building block for CSA and KSA.
// sum  = a XOR b XOR cin  (odd-parity)
// cout = majority(a, b, cin)
module FA (
    input  wire a, b, cin,
    output wire sum, cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule