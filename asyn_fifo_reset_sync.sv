//------------------------------------------------------------------------------
// Module  : asyn_fifo_reset_sync
// Purpose : Asynchronous reset assertion and two-clock synchronous release
// Author  : Trung Pham
// Created : 2026-07-23
// Version : 1.0
//------------------------------------------------------------------------------
module asyn_fifo_reset_sync (
    input logic clk,
    input logic rst_n,
    output logic reset_done
);

    logic [1:0] reset_pipe_r;

    // Reset assertion remains asynchronous when the local clock is stopped.
    // Shifting in two ones makes reset release synchronous to the local clock.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_pipe_r <= 2'b00;
        end else begin
            reset_pipe_r <= {reset_pipe_r[0], 1'b1};
        end
    end

    assign reset_done = reset_pipe_r[1];

endmodule
