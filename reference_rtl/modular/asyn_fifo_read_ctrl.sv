// Read-domain pointer, empty detection, valid, and underflow reporting.
module asyn_fifo_read_ctrl #(
    parameter int ADDR_WIDTH = 4,
    parameter int PTR_WIDTH  = ADDR_WIDTH + 1
) (
    input  logic                  rd_clk,
    input  logic                  rd_rst_n,
    input  logic                  rd_reset_done,
    input  logic                  rd_en,
    input  logic [PTR_WIDTH-1:0]  wr_gray_sync,
    output logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [PTR_WIDTH-1:0]  rd_gray,
    output logic                  rd_accept,
    output logic                  rd_valid,
    output logic                  rd_empty,
    output logic                  underflow
);

    logic [PTR_WIDTH-1:0] rd_bin;
    logic [PTR_WIDTH-1:0] rd_bin_next;
    logic [PTR_WIDTH-1:0] rd_gray_next;
    logic                 rd_empty_next;

    assign rd_addr   = rd_bin[ADDR_WIDTH-1:0];
    assign rd_accept = rd_reset_done && rd_en && !rd_empty;

    always_comb begin
        rd_bin_next  = rd_bin + rd_accept;
        rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;
    end

    assign rd_empty_next = (rd_gray_next == wr_gray_sync);

   y always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin    <= '0;
            rd_gray   <= '0;
            rd_valid  <= 1'b0;
            rd_empty  <= 1'b1;
            underflow <= 1'b0;
        end else if (!rd_reset_done) begin
            rd_bin    <= '0;
            rd_gray   <= '0;
            rd_valid  <= 1'b0;
            rd_empty  <= 1'b1;
            underflow <= 1'b0;
        end else begin
            rd_bin    <= rd_bin_next;
            rd_gray   <= rd_gray_next;
            rd_valid  <= rd_accept;
            rd_empty  <= rd_empty_next;
            underflow <= rd_en && rd_empty;
        end
    end

endmodule
