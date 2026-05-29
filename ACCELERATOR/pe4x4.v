`ifndef GLOBAL_SVH
`include "global.svh"
`endif

module pe4x4 #(
    // parameter W = 16,
    // parameter N = 4,
    // parameter ACC_WIDTH = 40,
    // parameter OUT_WIDTH = 2*W
)(
    input clk,
    input rst_n,

    input flush_acc,   
    input [FIF_LINES-1:0] in_valid_a ,
    input [FIF_LINES-1:0] in_valid_b  ,

    // inputs from fifo controller
    input [W-1:0] fifo_A0,
    input [W-1:0] fifo_A1,
    input [W-1:0] fifo_A2,
    input [W-1:0] fifo_A3,

    input [W-1:0] fifo_B0,
    input [W-1:0] fifo_B1,
    input [W-1:0] fifo_B2,
    input [W-1:0] fifo_B3,

    // four output buses
    output reg [OUT_WIDTH-1:0] outputbus1,
    output reg [OUT_WIDTH-1:0] outputbus2,
    output reg [OUT_WIDTH-1:0] outputbus3,
    output reg [OUT_WIDTH-1:0] outputbus4,

    output reg valid1,
    output reg valid2,
    output reg valid3,
    output reg valid4
);

wire [W-1:0] A [0:3][0:4];
wire [W-1:0] B_mat [0:4][0:3];
wire [OUT_WIDTH-1:0] S [0:3][0:3];
wire valid [0:3][0:3];
wire pass_a [0:3][0:4];
wire pass_b [0:4][0:3];

// inputs
assign A[0][0] = fifo_A0;
assign A[1][0] = fifo_A1;
assign A[2][0] = fifo_A2;
assign A[3][0] = fifo_A3;

assign B_mat[0][0] = fifo_B0;
assign B_mat[0][1] = fifo_B1;
assign B_mat[0][2] = fifo_B2;
assign B_mat[0][3] = fifo_B3;

// Left boundary (A direction)
assign pass_a[0][0] = in_valid_a[0];
assign pass_a[1][0] = in_valid_a[1];
assign pass_a[2][0] = in_valid_a[2];
assign pass_a[3][0] = in_valid_a[3];

// Top boundary (B direction)
assign pass_b[0][0] = in_valid_b[0];
assign pass_b[0][1] = in_valid_b[1];
assign pass_b[0][2] = in_valid_b[2];
assign pass_b[0][3] = in_valid_b[3];

// PE grid
genvar i,j;

generate
for(i=0;i<4;i=i+1) begin
    for(j=0;j<4;j=j+1) begin

        pe_v2 #(
            // .N(N),
            // .W(W),
            // .ACC_WIDTH(ACC_WIDTH),
            // .OUT_WIDTH(OUT_WIDTH)
        ) PE (

            .clk(clk),
            .rst_n(rst_n),

            .inA(A[i][j]),
            .inB(B_mat[i][j]),

            .outA(A[i][j+1]),
            .outB(B_mat[i+1][j]),

            .outS(S[i][j]),
            .out_valid(valid[i][j]),

            .in_valid_a(pass_a[i][j]),
            .in_valid_b(pass_b[i][j]),

            .pass_valid_a(pass_a[i][j+1]),
            .pass_valid_b(pass_b[i+1][j]),

            .flush_acc(flush_acc)
        );

    end
end
endgenerate

// ================= OUTPUT MUX =================
// pick first valid in each row

always @(posedge clk) begin
    if(!rst_n) begin
        outputbus1 <= 0;
        outputbus2 <= 0;
        outputbus3 <= 0;
        outputbus4 <= 0;

        valid1 <= 0;
        valid2 <= 0;
        valid3 <= 0;
        valid4 <= 0;
    end else begin

        // default: no valid
        valid1 <= 0;
        valid2 <= 0;
        valid3 <= 0;
        valid4 <= 0;

        // row 0
        if(valid[0][0]) begin outputbus1 <= S[0][0]; valid1 <= 1; end
        else if(valid[0][1]) begin outputbus1 <= S[0][1]; valid1 <= 1; end
        else if(valid[0][2]) begin outputbus1 <= S[0][2]; valid1 <= 1; end
        else if(valid[0][3]) begin outputbus1 <= S[0][3]; valid1 <= 1; end

        // row 1
        if(valid[1][0]) begin outputbus2 <= S[1][0]; valid2 <= 1; end
        else if(valid[1][1]) begin outputbus2 <= S[1][1]; valid2 <= 1; end
        else if(valid[1][2]) begin outputbus2 <= S[1][2]; valid2 <= 1; end
        else if(valid[1][3]) begin outputbus2 <= S[1][3]; valid2 <= 1; end

        // row 2
        if(valid[2][0]) begin outputbus3 <= S[2][0]; valid3 <= 1; end
        else if(valid[2][1]) begin outputbus3 <= S[2][1]; valid3 <= 1; end
        else if(valid[2][2]) begin outputbus3 <= S[2][2]; valid3 <= 1; end
        else if(valid[2][3]) begin outputbus3 <= S[2][3]; valid3 <= 1; end

        // row 3
        if(valid[3][0]) begin outputbus4 <= S[3][0]; valid4 <= 1; end
        else if(valid[3][1]) begin outputbus4 <= S[3][1]; valid4 <= 1; end
        else if(valid[3][2]) begin outputbus4 <= S[3][2]; valid4 <= 1; end
        else if(valid[3][3]) begin outputbus4 <= S[3][3]; valid4 <= 1; end

    end
end

endmodule
