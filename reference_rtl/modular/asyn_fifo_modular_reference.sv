// Top-level reference composed from reset, CDC, control, and memory modules.
module asyn_fifo_modular_reference #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16,
    parameter int ADDR_WIDTH = $clog2(DEPTH),
    parameter int PTR_WIDTH  = ADDR_WIDTH + 1
) (
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  wr_full,
    output logic                  overflow,

    input  logic                  rd_clk,
    input  logic                  rd_rst_n,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  rd_valid,
    output logic                  rd_empty,
    output logic                  underflow
);

    logic wr_reset_done;
    logic rd_reset_done;

    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [ADDR_WIDTH-1:0] rd_addr;
    logic [PTR_WIDTH-1:0]  wr_gray;
    logic [PTR_WIDTH-1:0]  rd_gray;
    logic [PTR_WIDTH-1:0]  wr_gray_sync;
    logic [PTR_WIDTH-1:0]  rd_gray_sync;
    logic                  wr_accept;
    logic                  rd_accept;

    asyn_fifo_reset_sync u_wr_reset_sync (
        .clk        (wr_clk),
        .rst_n      (wr_rst_n),
        .reset_done (wr_reset_done)
    );

    asyn_fifo_reset_sync u_rd_reset_sync (
        .clk        (rd_clk),
        .rst_n      (rd_rst_n),
        .reset_done (rd_reset_done)
    );

    // Read pointer crossing into the write domain.
    asyn_fifo_gray_sync #(
        .WIDTH (PTR_WIDTH)
    ) u_rd_gray_to_wr (
        .dst_clk        (wr_clk),
        .dst_rst_n      (wr_rst_n),
        .dst_reset_done (wr_reset_done),
        .async_gray     (rd_gray),
        .sync_gray      (rd_gray_sync)
    );

    // Write pointer crossing into the read domain.
    asyn_fifo_gray_sync #(
        .WIDTH (PTR_WIDTH)
    ) u_wr_gray_to_rd (
        .dst_clk        (rd_clk),
        .dst_rst_n      (rd_rst_n),
        .dst_reset_done (rd_reset_done),
        .async_gray     (wr_gray),
        .sync_gray      (wr_gray_sync)
    );

    asyn_fifo_write_ctrl #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .PTR_WIDTH  (PTR_WIDTH)
    ) u_write_ctrl (
        .wr_clk        (wr_clk),
        .wr_rst_n      (wr_rst_n),
        .wr_reset_done (wr_reset_done),
        .wr_en         (wr_en),
        .rd_gray_sync  (rd_gray_sync),
        .wr_addr       (wr_addr),
        .wr_gray       (wr_gray),
        .wr_accept     (wr_accept),
        .wr_full       (wr_full),
        .overflow      (overflow)
    );

    asyn_fifo_read_ctrl #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .PTR_WIDTH  (PTR_WIDTH)
    ) u_read_ctrl (
        .rd_clk        (rd_clk),
        .rd_rst_n      (rd_rst_n),
        .rd_reset_done (rd_reset_done),
        .rd_en         (rd_en),
        .wr_gray_sync  (wr_gray_sync),
        .rd_addr       (rd_addr),
        .rd_gray       (rd_gray),
        .rd_accept     (rd_accept),
        .rd_valid      (rd_valid),
        .rd_empty      (rd_empty),
        .underflow     (underflow)
    );

    asyn_fifo_memory #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_memory (
        .wr_clk        (wr_clk),
        .wr_accept     (wr_accept),
        .wr_addr       (wr_addr),
        .wr_data       (wr_data),
        .rd_clk        (rd_clk),
        .rd_rst_n      (rd_rst_n),
        .rd_reset_done (rd_reset_done),
        .rd_accept     (rd_accept),
        .rd_addr       (rd_addr),
        .rd_data       (rd_data)
    );

`ifndef SYNTHESIS
    initial begin
        if (DATA_WIDTH < 1)
            $fatal(1, "DATA_WIDTH must be at least 1");
        if (DEPTH < 4 || (DEPTH & (DEPTH - 1)) != 0)
            $fatal(1, "DEPTH must be a power of two and at least 4");
        if (ADDR_WIDTH != $clog2(DEPTH))
            $fatal(1, "ADDR_WIDTH must equal $clog2(DEPTH)");
        if (PTR_WIDTH != ADDR_WIDTH + 1)
            $fatal(1, "PTR_WIDTH must equal ADDR_WIDTH + 1");
    end
`endif

endmodule
