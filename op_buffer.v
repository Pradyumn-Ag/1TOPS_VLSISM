`ifndef GLOBAL_SVH
`include "global.svh"
`endif 
/* verilator lint_off UNUSEDSIGNAL */
module op_buffer (
    input clk,
    input rst_n,
    input [N*OUT_WIDTH-1:0] outputbus_flat,
    input [N-1:0] valid_row

);

localparam SIZE = N*N;
localparam BLOCK = OUT_WIDTH;
integer i,r;
reg [BLOCK-1:0] mem [0:SIZE-1];
reg [$clog2(N)-1:0] counter_row [0:N-1];

always @(posedge clk ) begin
    if (!rst_n)
    begin
       for (r = 0; r < N; r = r+1)
                counter_row[r] <= {$clog2(N){1'b0}};
    for (i=0;i<SIZE; i=i+1)
    begin
        mem[i]<=0;
    end
    end
    else begin
            for (r = 0; r < N; r = r+1) begin
                if (valid_row[r]) begin
                    /* verilator lint_off WIDTHEXPAND */
                    mem[r*N + counter_row[r]]
                        <= outputbus_flat[r*OUT_WIDTH +: OUT_WIDTH];
                    /* verilator lint_on WIDTHEXPAND */
                    counter_row[r] <= counter_row[r] + 1;
                end
            end

    end
end
endmodule
/* verilator lint_on UNUSEDSIGNAL */
