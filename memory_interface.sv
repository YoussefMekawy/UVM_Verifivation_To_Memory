interface mem_if#(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 32
)
(input bit clk);
logic en;
logic rst_n;
logic wr;
logic [ADDR_WIDTH-1:0] addr;
logic [DATA_WIDTH-1:0] data_in;
logic [DATA_WIDTH-1:0] data_out;
logic valid_out;
    

endinterface //interfacename