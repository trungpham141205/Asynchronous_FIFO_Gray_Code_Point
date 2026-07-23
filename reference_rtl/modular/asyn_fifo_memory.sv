// Dual-clock FIFO storage.
// The array itself is not reset; only the registered read output is reset.
module asyn_fifo_memory #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16,
    parameter int ADDR_WIDTH = $clog2(DEPTH)
) (
    input  logic                  wr_clk,
    input  logic                  wr_accept,
    input  logic [ADDR_WIDTH-1:0] wr_addr,
    input  logic [DATA_WIDTH-1:0] wr_data,

    input  logic                  rd_clk,
    input  logic                  rd_rst_n,
    input  logic                  rd_reset_done,
    input  logic                  rd_accept,
    input  logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [DATA_WIDTH-1:0] rd_data
);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always_ff @(posedge wr_clk) begin
        if (wr_accept)
            mem[wr_addr] <= wr_data;
    end

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            rd_data <= '0;
        else if (!rd_reset_done)
            rd_data <= '0;
        else if (rd_accept)
            rd_data <= mem[rd_addr];
    end

endmodule
