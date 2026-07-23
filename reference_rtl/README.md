# Reference RTL

`asyn_fifo_reference.sv` là một lời giải tham khảo bám theo
`DesignSpecAsyncFIFOGrayPointer_Dual_Async_Reset_Revised.docx`.

Module được đặt tên `asyn_fifo_reference` để không xung đột với module
`asyn_fifo` trong file bài làm ở thư mục gốc. Muốn so sánh hai thiết kế trong
cùng testbench, hãy instantiate chúng với hai instance name khác nhau và nối
cùng input.

Các đặc điểm chính của lời giải:

- binary pointer rộng `ADDR_WIDTH + 1` dùng trong local clock domain;
- Gray pointer được register trước khi đi qua CDC;
- mỗi Gray pointer đi qua synchronizer hai tầng ở domain đích;
- `wr_full` và `rd_empty` là cờ registered, tính từ next pointer;
- reset assert bất đồng bộ, deassert đồng bộ qua hai cạnh local clock;
- memory không reset;
- `overflow`, `underflow`, `rd_valid` là tín hiệu registered theo đúng spec;
- không có FWFT, bypass khi empty hoặc read-and-replace khi full.

Đây là RTL tham khảo chức năng. Khi đưa lên FPGA/ASIC, vẫn cần khai báo CDC,
timing constraint và ràng buộc skew cho bus Gray phù hợp với flow của công cụ.
