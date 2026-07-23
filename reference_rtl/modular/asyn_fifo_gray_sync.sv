// Two-flop synchronizer for a Gray-code pointer.
// Only sync_gray (the second stage) is visible to functional logic.
module asyn_fifo_gray_sync #(
    parameter int WIDTH = 5
) (
    input  logic             dst_clk,
    input  logic             dst_rst_n,
    input  logic             dst_reset_done,
    input  logic [WIDTH-1:0] async_gray,
    output logic [WIDTH-1:0] sync_gray
);

    logic [WIDTH-1:0] sync_stage1;

    always_ff @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            sync_stage1 <= '0;
            sync_gray   <= '0;
        end else if (!dst_reset_done) begin
            sync_stage1 <= '0;
            sync_gray   <= '0;
        end else begin
            sync_stage1 <= async_gray;
            sync_gray   <= sync_stage1;
        end
    end

endmodule
