
typedef enum logic [1:0]{
    WR_IDLE,
    WR_WRITE,
    WR_RESET
} wr_cmd;

typedef enum logic [1:0]{
    RD_IDLE,
    RD_READ,
    RD_RESET
} rd_cmd;

//Write Transaction
class wr_transaction;
    rand wr_cmd cmd;
    rand logic [`DATA_WIDTH - 1:0] wr_data;
    rand int num_clk;

    logic wr_rst_n;
    logic wr_en;
    logic wr_full;
    logic overflow;

    time sample_time;

    function void display(string name = "");
        $display("[ %0t ] === %s ===", $time, name);
        $display(" Write command = %s", cmd.name());
        $display(" Write data = %0h", wr_data);
        $display(" Num of clocks = %0d", num_clk);
        $display(" Write full = %0b", wr_full);
        $display(" Overflow = %0b", overflow);
    endfunction

    constraint cmd_c {
        cmd inside {WR_IDLE, WR_WRITE, WR_RESET};
    }

    constraint num_clk_c {
        solve cmd before num_clk;

        if (cmd == WR_RESET) begin
            num_clk inside {[2:4]};
        end
        else begin
            soft num_clk inside {[1:5]};
        end
    }
endclass

//Read Transaction
class rd_transaction;
    rand rd_cmd cmd;
    rand int num_clk;

    logic rd_rst_n;
    logic rd_en;
    logic [`DATA_WIDTH - 1:0] rd_data;
    logic rd_valid;
    logic rd_empty;
    logic underflow;

    time sample_time;

    function void display(string name = "");
        $display("[ %0t ] === %s ===", $time, name);
        $display(" Read command = %s", cmd.name());
        $display(" Num of clocks = %0d", num_clk);
        $display(" Read data = %0h", rd_data);
        $display(" Read valid = %0b", rd_valid);
        $display(" Read empty = %0b", rd_empty);
        $display(" Underflow = %0b", underflow);
    endfunction

    constraint cmd_c {
        cmd inside {RD_IDLE, RD_READ, RD_RESET};
    }

    constraint num_clk_c {
        solve cmd before num_clk;

        if (cmd == RD_RESET) begin
            num_clk inside {[2:4]};
        end
        else begin
            soft num_clk inside {[1:5]};
        end
    }
endclass
