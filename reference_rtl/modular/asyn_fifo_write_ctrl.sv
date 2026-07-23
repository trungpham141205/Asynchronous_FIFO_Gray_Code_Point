// Write-domain pointer, full detection, and overflow reporting.
moduley asyn_fifo_write_ctrl #(
    parameter int ADDR_WIDTH = 4,
    parameter int PTR_WIDTH  = ADDR_WIDTH + 1
) (
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,
    input  logic                  wr_reset_done,
    input  logic                  wr_en,
    input  logic [PTR_WIDTH-1:0]  rd_gray_sync,
    output logic [ADDR_WIDTH-1:0] wr_addr,
    output logic [PTR_WIDTH-1:0]  wr_gray,
    output logic                  wr_accept,
    output logic                  wr_full,
    output logic                  overflow
);

    logic [PTR_WIDTH-1:0] wr_bin;
    logic [PTR_WIDTH-1:0] wr_bin_next;
    logic [PTR_WIDTH-1:0] wr_gray_next;
    logic                 wr_full_next;

    assign wr_addr   = wr_bin[ADDR_WIDTH-1:0];
    assign wr_accept = wr_reset_done && wr_en && !wr_full;

    always_comb begin
        wr_bin_next  = wr_bin + wr_accept;
        wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
    end

    // A Gray pointer is full when its lower bits match the synchronized read
    // pointer and its two most-significant bits are inverted.
    assign wr_full_next =
        (wr_gray_next == {
            ~rd_gray_sync[PTR_WIDTH-1:PTR_WIDTH-2],
             rd_gray_sync[PTR_WIDTH-3:0]
        });

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin   <= '0;
            wr_gray  <= '0;
            wr_full  <= 1'b0;
            overflow <= 1'b0;
        end else if (!wr_reset_done) begin
            wr_bin   <= '0;
            wr_gray  <= '0;
            wr_full  <= 1'b0;
            overflow <= 1'b0;
        end else begin
            wr_bin   <= wr_bin_next;
            wr_gray  <= wr_gray_next;
            wr_full  <= wr_full_next;
            overflow <= wr_en && wr_full;
        end
    end

endmodule
