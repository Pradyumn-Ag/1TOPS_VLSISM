    `ifndef GLOBAL_SVH
    `include "global.svh"
    `endif

    module pe_array(
        input clk,
        input rst_n,
        input flush_acc,   
        input [FIF_LINES-1:0] in_valid_a ,
        input [FIF_LINES-1:0] in_valid_b  ,

        // inputs from fifo controller
          input  [N*W-1:0]fifo_A_flat,
          input  [N*W-1:0] fifo_B_flat,

        // four output buses
          output reg [N*OUT_WIDTH-1:0] outputbus_flat,
          output reg [N-1:0]valid_row
    );

    wire [W-1:0] A [0:N-1][0:N];
    wire [W-1:0] B_mat [0:N][0:N-1];
    wire [OUT_WIDTH-1:0] S [0:N-1][0:N-1];
    wire valid [0:N-1][0:N-1];
    wire pass_a [0:N-1][0:N];
    wire pass_b [0:N][0:N-1];

    // inputs
   genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi+1) begin : INPUT_MAP
            // Unpack flat input bus into wire mesh
            assign A[gi][0]    = fifo_A_flat[gi*W +: W];
            assign B_mat[0][gi]= fifo_B_flat[gi*W +: W];
            assign pass_a[gi][0] = in_valid_a[gi];
            assign pass_b[0][gi] = in_valid_b[gi];
        end
    endgenerate
    // PE grid
    genvar i,j;

    generate
    for(i=0;i<N;i=i+1) begin
        for(j=0;j<N;j=j+1) begin

            pe_v2 PE (

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
  

   /* verilator lint_off BLKSEQ */

    integer r, c;
    reg found;

    always @(posedge clk) begin
        if (!rst_n) begin
            outputbus_flat <= {(N*OUT_WIDTH){1'b0}};
            valid_row      <= {N{1'b0}};
        end else begin

            valid_row <= {N{1'b0}};   // clear all valids each cycle

            for (r = 0; r < N; r = r+1) begin

                found = 0;   // blocking: resets per row, per cycle

                for (c = 0; c < N; c = c+1) begin
                    if (valid[r][c] && !found) begin
                        outputbus_flat[r*OUT_WIDTH +: OUT_WIDTH] <= S[r][c];
                        valid_row[r] <= 1'b1;
                        found = 1;   // blocking: prevents later cols overwriting
                    end
                end

            end

        end
    end

    /* verilator lint_on BLKSEQ */

    endmodule
