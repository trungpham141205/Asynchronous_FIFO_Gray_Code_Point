// Reference implementation for the asynchronous FIFO specification.
//
// The module name intentionally differs from the student's asyn_fifo module so
// both files can be compiled in the same project without a name collision.
module asyn_fifo_reference #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16,
    parameter int ADDR_WIDTH = $clog2(DEPTH),
    parameter int PTR_WIDTH  = ADDR_WIDTH + 1
) (
    input  logic                    wr_clk,
    input  logic                    wr_rst_n,
    input  logic                    wr_en,
    input  logic [DATA_WIDTH-1:0]   wr_data,
    output logic                    wr_full,
    output logic                    overflow,

    input  logic                    rd_clk,
    input  logic                    rd_rst_n,
    input  logic                    rd_en,
    output logic [DATA_WIDTH-1:0]   rd_data,
    output logic                    rd_valid,
    output logic                    rd_empty,
    output logic                    underflow
);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Local reset release pipes. External reset assertion is asynchronous;
    // reset release takes two rising edges of the corresponding local clock.
    logic [1:0] wr_reset_pipe;
    logic [1:0] rd_reset_pipe;
    logic wr_reset_done;
    logic rd_reset_done;

    logic [PTR_WIDTH-1:0] wr_bin,  wr_bin_next;
    logic [PTR_WIDTH-1:0] wr_gray, wr_gray_next;
    logic [PTR_WIDTH-1:0] rd_bin,  rd_bin_next;
    logic [PTR_WIDTH-1:0] rd_gray, rd_gray_next;

    // Gray-pointer synchronizers. Only stage 2 is used by functional logic.
    logic [PTR_WIDTH-1:0] rd_gray_wr_sync1;
    logic [PTR_WIDTH-1:0] rd_gray_wr_sync2;
    logic [PTR_WIDTH-1:0] wr_gray_rd_sync1;
    logic [PTR_WIDTH-1:0] wr_gray_rd_sync2;

    logic wr_accept;
    logic rd_accept;
    logic wr_full_next;
    logic rd_empty_next;

    assign wr_reset_done = wr_reset_pipe[1];
    assign rd_reset_done = rd_reset_pipe[1];

    // Gating with reset_done prevents memory accesses during the two local
    // reset-release edges. The first possible accepted request is edge E3.
    assign wr_accept = wr_reset_done && wr_en && !wr_full;
    assign rd_accept = rd_reset_done && rd_en && !rd_empty;

    // Binary pointers are used locally for addressing. Gray pointers are the
    // only pointer representation that crosses a clock-domain boundary.
    always_comb begin
        wr_bin_next  = wr_bin + wr_accept;
        wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;

        rd_bin_next  = rd_bin + rd_accept;
        rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;
    end

    // Empty after the prospective read when both Gray pointers are equal.
    assign rd_empty_next = (rd_gray_next == wr_gray_rd_sync2);

    // Full after the prospective write when the next write Gray pointer equals
    // the synchronized read Gray pointer with its two MSBs inverted.
    assign wr_full_next =
        (wr_gray_next == {
            ~rd_gray_wr_sync2[PTR_WIDTH-1:PTR_WIDTH-2],
             rd_gray_wr_sync2[PTR_WIDTH-3:0]
        });

    // Asynchronous assertion, two-edge synchronous release in write domain.
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n)
            wr_reset_pipe <= 2'b00;
        else
            wr_reset_pipe <= {wr_reset_pipe[0], 1'b1};
    end

    // Asynchronous assertion, two-edge synchronous release in read domain.
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            rd_reset_pipe <= 2'b00;
        else
            rd_reset_pipe <= {rd_reset_pipe[0], 1'b1};
    end

    // Synchronize the read Gray pointer into the write clock domain.
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_gray_wr_sync1 <= '0;
            rd_gray_wr_sync2 <= '0;
        end else if (!wr_reset_done) begin
            rd_gray_wr_sync1 <= '0;
            rd_gray_wr_sync2 <= '0;
        end else begin
            rd_gray_wr_sync1 <= rd_gray;
            rd_gray_wr_sync2 <= rd_gray_wr_sync1;
        end
    end

    // Synchronize the write Gray pointer into the read clock domain.
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_gray_rd_sync1 <= '0;
            wr_gray_rd_sync2 <= '0;
        end else if (!rd_reset_done) begin
            wr_gray_rd_sync1 <= '0;
            wr_gray_rd_sync2 <= '0;
        end else begin
            wr_gray_rd_sync1 <= wr_gray;
            wr_gray_rd_sync2 <= wr_gray_rd_sync1;
        end
    end

    // Write-domain state and registered outputs.
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin    <= '0;
            wr_gray   <= '0;
            wr_full   <= 1'b0;
            overflow  <= 1'b0;
        end else if (!wr_reset_done) begin
            wr_bin    <= '0;
            wr_gray   <= '0;
            wr_full   <= 1'b0;
            overflow  <= 1'b0;
        end else begin
            wr_bin    <= wr_bin_next;
            wr_gray   <= wr_gray_next;
            wr_full   <= wr_full_next;
            overflow  <= wr_en && wr_full;
        end
    end

    // The memory is deliberately not reset. It is written only by wr_clk.
    always_ff @(posedge wr_clk) begin
        if (wr_accept)
            mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;
    end

    // Read-domain state, registered read data, and registered outputs.
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin    <= '0;
            rd_gray   <= '0;
            rd_data   <= '0;
            rd_valid  <= 1'b0;
            rd_empty  <= 1'b1;
            underflow <= 1'b0;
        end else if (!rd_reset_done) begin
            rd_bin    <= '0;
            rd_gray   <= '0;
            rd_data   <= '0;
            rd_valid  <= 1'b0;
            rd_empty  <= 1'b1;
            underflow <= 1'b0;
        end else begin
            rd_bin    <= rd_bin_next;
            rd_gray   <= rd_gray_next;
            rd_empty  <= rd_empty_next;
            rd_valid  <= rd_accept;
            underflow <= rd_en && rd_empty;

            // rd_data holds its last valid value when no read is accepted.
            if (rd_accept)
                rd_data <= mem[rd_bin[ADDR_WIDTH-1:0]];
        end
    end

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
