//------------------------------------------------------------------------------
// Module  : asyn_fifo_memory
// Purpose : Dual-clock FIFO storage with a registered read-data output
// Author  : Trung Pham
// Created : 2026-07-23
// Version : 1.0
//------------------------------------------------------------------------------
module asyn_fifo_memory #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH = 16,
    parameter int ADDR_WIDTH = $clog2(DEPTH)
) (
    // Write port
    input logic wr_clk,
    input logic wr_accept,
    input logic [ADDR_WIDTH-1:0] wr_addr,
    input logic [DATA_WIDTH-1:0] wr_data,

    // Read port
    input logic rd_clk,
    input logic rd_rst_n,
    input logic rd_reset_done,
    input logic rd_accept,
    input logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [DATA_WIDTH-1:0] rd_data
);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // The storage array is intentionally not reset. Resetting both pointers
    // invalidates old contents and omitting a memory reset supports RAM inference.
    always_ff @(posedge wr_clk) begin
        if (wr_accept) begin
            mem[wr_addr] <= wr_data;
        end
    end

    // rd_data holds its most recent valid value when no read is accepted.
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_data <= '0;
        end else if (!rd_reset_done) begin
            rd_data <= '0;
        end else if (rd_accept) begin
            rd_data <= mem[rd_addr];
        end
    end

endmodule
