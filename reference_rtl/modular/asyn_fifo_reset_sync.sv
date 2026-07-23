// Asynchronous reset assertion and two-clock synchronous reset release.
module asyn_fifo_reset_sync (
    input  logic clk,
    input  logic rst_n,
    output logic reset_done
);

    logic [1:0] reset_pipe;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reset_pipe <= 2'b00;
        else
            reset_pipe <= {reset_pipe[0], 1'b1};
    end

    assign reset_done = reset_pipe[1];

endmodule
