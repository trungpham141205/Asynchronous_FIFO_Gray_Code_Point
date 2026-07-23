//------------------------------------------------------------------------------
// Module  : asyn_fifo
// Purpose : Top-level asynchronous FIFO using Gray-code pointer synchronization
// Author  : Trung Pham
// Created : 2026-07-23
// Version : 1.0
//------------------------------------------------------------------------------
module asyn_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH = 16,
    parameter int ADDR_WIDTH = $clog2(DEPTH),
    parameter int PTR_WIDTH = ADDR_WIDTH + 1
) (
    // Write-domain interface
    input logic wr_clk,
    input logic wr_rst_n,
    input logic wr_en,
    input logic [DATA_WIDTH-1:0] wr_data,
    output logic wr_full,
    output logic overflow,

    // Read-domain interface
    input logic rd_clk,
    input logic rd_rst_n,
    input logic rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic rd_valid,
    output logic rd_empty,
    output logic underflow
);

    // Either external reset request asynchronously flushes the complete FIFO.
    logic fifo_rst_n;

    // Local reset-release status
    logic wr_reset_done;
    logic rd_reset_done;

    // Local memory addresses and accepted-operation controls
    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [ADDR_WIDTH-1:0] rd_addr;
    logic                  wr_accept;
    logic                  rd_accept;

    // Source-domain and destination-synchronized Gray pointers
    logic [PTR_WIDTH-1:0] wr_gray;
    logic [PTR_WIDTH-1:0] rd_gray;
    logic [PTR_WIDTH-1:0] wr_gray_sync;
    logic [PTR_WIDTH-1:0] rd_gray_sync;

    assign fifo_rst_n = wr_rst_n & rd_rst_n;

    asyn_fifo_reset_sync wr_reset_sync_inst (
        .clk(wr_clk),
        .rst_n(fifo_rst_n),
        .reset_done(wr_reset_done)
    );

    asyn_fifo_reset_sync rd_reset_sync_inst (
        .clk(rd_clk),
        .rst_n(fifo_rst_n),
        .reset_done(rd_reset_done)
    );

    // Synchronize the read pointer into the write clock domain.
    asyn_fifo_gray_sync #(
        .WIDTH(PTR_WIDTH)
    ) rd_gray_to_wr_inst (
        .dst_clk(wr_clk),
        .dst_rst_n(fifo_rst_n),
        .dst_reset_done(wr_reset_done),
        .async_gray(rd_gray),
        .sync_gray(rd_gray_sync)
    );

    // Synchronize the write pointer into the read clock domain.
    asyn_fifo_gray_sync #(
        .WIDTH(PTR_WIDTH)
    ) wr_gray_to_rd_inst (
        .dst_clk(rd_clk),
        .dst_rst_n(fifo_rst_n),
        .dst_reset_done(rd_reset_done),
        .async_gray(wr_gray),
        .sync_gray(wr_gray_sync)
    );

    asyn_fifo_write_ctrl #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .PTR_WIDTH(PTR_WIDTH)
    ) write_ctrl_inst (
        .wr_clk(wr_clk),
        .wr_rst_n(fifo_rst_n),
        .wr_reset_done(wr_reset_done),
        .wr_en(wr_en),
        .rd_gray_sync(rd_gray_sync),
        .wr_addr(wr_addr),
        .wr_gray(wr_gray),
        .wr_accept(wr_accept),
        .wr_full(wr_full),
        .overflow(overflow)
    );

    asyn_fifo_read_ctrl #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .PTR_WIDTH(PTR_WIDTH)
    ) read_ctrl_inst (
        .rd_clk(rd_clk),
        .rd_rst_n(fifo_rst_n),
        .rd_reset_done(rd_reset_done),
        .rd_en(rd_en),
        .wr_gray_sync(wr_gray_sync),
        .rd_addr(rd_addr),
        .rd_gray(rd_gray),
        .rd_accept(rd_accept),
        .rd_valid(rd_valid),
        .rd_empty(rd_empty),
        .underflow(underflow)
    );

    asyn_fifo_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) memory_inst (
        .wr_clk(wr_clk),
        .wr_accept(wr_accept),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_clk(rd_clk),
        .rd_rst_n(fifo_rst_n),
        .rd_reset_done(rd_reset_done),
        .rd_accept(rd_accept),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

endmodule
