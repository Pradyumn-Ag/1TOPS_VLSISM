// `ifndef GLOBAL_SVH
// `include "global.svh"
// `endif 

module buffer #(
    parameter int WIDTH = 64,   // Line WIDTH of buffer
    parameter int SIZE = 1024,   // number of buffer lines
    parameter INIT = 1,
    parameter string INIT_FILE = ""
) (
    input logic clk,
    input logic rst_n,

    // read port
    input logic [$clog2(SIZE)-1:0] r_addr,
    output logic [WIDTH-1:0] dout,
    input logic ren,
    output logic r_valid_out,

    // write port
    input logic [$clog2(SIZE)-1:0] w_addr,
    input logic [WIDTH-1:0] din,
    input logic wen           
    
    
);

  logic [WIDTH-1:0] mem[0:SIZE-1];


  initial begin
    if (INIT) begin
       $readmemh(INIT_FILE,mem);
    end    
  end

  always_ff @( posedge clk ) begin 
    if(!rst_n)begin
       if (INIT) begin
          dout <= '0;
          r_valid_out <= '0;
       end else begin
        for(int i = 0; i< SIZE;i++)begin
            mem[i] <= '0;
        end
        dout <= '0;
        r_valid_out <= '0;
       end
    end else begin
        if(ren) begin
            dout <= mem[r_addr];
            r_valid_out <= 1;
        end 
        if (wen) begin
            mem[w_addr] <= din;
        end
    end
  end

    
endmodule
