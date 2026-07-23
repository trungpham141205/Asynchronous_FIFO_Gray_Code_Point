//------------------------------------------------------------------------------
// Module  : asyn_fifo_gray_sync
// Purpose : Two-flop synchronization of a Gray-code pointer into a clock domain
// Author  : Trung Pham
// Created : 2026-07-23
// Version : 1.0
//------------------------------------------------------------------------------
module asyn_fifo_gray_sync #(
    parameter int WIDTH = 5
) (
    input logic dst_clk,
    input logic dst_rst_n,
    input logic dst_reset_done,
    input logic [WIDTH-1:0] async_gray,
    output logic [WIDTH-1:0] sync_gray
);

    logic [WIDTH-1:0] sync_stage1_r;

    // The first stage may resolve metastability; only the registered second
    // stage output is exposed to functional logic in the destination domain.
    always_ff @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            sync_stage1_r <= '0;
            sync_gray     <= '0;
        end else if (!dst_reset_done) begin
            sync_stage1_r <= '0;
            sync_gray     <= '0;
        end else begin
            sync_stage1_r <= async_gray;
            sync_gray     <= sync_stage1_r;
        end
    end

endmodule
