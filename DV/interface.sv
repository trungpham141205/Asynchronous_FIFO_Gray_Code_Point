`include "define.sv"

interface asyn_fifo_if;
    //write domain
    logic wr_clk;
    logic wr_rst_n;
    logic wr_en;
    logic [`DATA_WITDH - 1:0] wr_data;
    logic wr_full;
    logic overflow;

    //read domain
    logic rd_clk;
    logic rd_rst_n;
    logic rd_en;
    logic [`DATA_WIDTH - 1:0] rd_data;
    logic rd_valid;
    logic rd_empty;
    logic underflow;

    //Testbench timing markers
    bit wr_clk_setup;
    bit wr_clk_access;
    bit wr_clk_hold;

    bit rd_clk_setup;
    bit rd_clk_access;
    bit rd_clk_hold;
endinterface
