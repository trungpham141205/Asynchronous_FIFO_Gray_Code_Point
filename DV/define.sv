`ifndef DEFINE_SV
`define DEFINE_SV

`define DATA_WIDTH 8
`define DEPTH 16
`define ADDR_WIDTH $clog2(`DEPTH)

`define WR_CLK_PERIOD 10
`define RD_CLK_PERIOD 14

`define WR_T_SETUP 3
`define WR_T_HOLD 2
`define WR_T_ACCESS 1

`define RD_T_SETUP 3
`define RD_T_HOLD 2
`define RD_T_ACCESS 1
