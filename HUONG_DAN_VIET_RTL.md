# Hướng dẫn viết RTL Asynchronous FIFO

File bạn cần hoàn thiện là `asyn_fifo.sv`. Lời giải đầy đủ để đối chiếu nằm ở
`reference_rtl/asyn_fifo_reference.sv`; nên tự viết theo thứ tự dưới đây trước
khi so sánh với reference.

## 1. Chia thiết kế thành hai clock domain

Write domain chỉ chạy theo `wr_clk`, reset bởi `wr_rst_n` và sở hữu:

- `wr_bin`, `wr_gray`;
- synchronizer nhận `rd_gray`;
- `wr_full`, `overflow`;
- cổng ghi memory.

Read domain chỉ chạy theo `rd_clk`, reset bởi `rd_rst_n` và sở hữu:

- `rd_bin`, `rd_gray`;
- synchronizer nhận `wr_gray`;
- `rd_empty`, `underflow`, `rd_valid`, `rd_data`;
- cổng đọc memory.

Không dùng trực tiếp binary pointer, Gray pointer chưa đồng bộ hoặc stage 1 của
synchronizer ở domain bên kia.

## 2. Viết reset synchronizer trước

Mỗi domain cần một shift register hai bit:

```systemverilog
always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n)
        wr_reset_pipe <= 2'b00;
    else
        wr_reset_pipe <= {wr_reset_pipe[0], 1'b1};
end
```

Làm tương tự cho read domain. Dùng bit thứ hai làm `wr_reset_done` hoặc
`rd_reset_done`. Các state register phải reset bất đồng bộ khi external reset
low, đồng thời tiếp tục giữ reset đồng bộ khi `reset_done == 0`. Như vậy E1 và
E2 vẫn là cạnh reset, cạnh E3 mới được accept request.

## 3. Khai báo memory và pointer

```systemverilog
logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
logic [PTR_WIDTH-1:0] wr_bin, wr_bin_next, wr_gray, wr_gray_next;
logic [PTR_WIDTH-1:0] rd_bin, rd_bin_next, rd_gray, rd_gray_next;
```

Không reset `mem`. Bit thấp `ADDR_WIDTH` của binary pointer là địa chỉ memory;
bit cao nhất là bit wrap-around.

Request được accept bằng flag trước cạnh clock:

```systemverilog
wr_accept = wr_reset_done && wr_en && !wr_full;
rd_accept = rd_reset_done && rd_en && !rd_empty;
```

## 4. Tính next binary pointer và next Gray pointer

```systemverilog
wr_bin_next  = wr_bin + wr_accept;
wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;

rd_bin_next  = rd_bin + rd_accept;
rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;
```

Pointer giữ nguyên khi request bị từ chối. Phải register Gray pointer trong
source domain; không chuyển một binary counter tổ hợp trực tiếp qua CDC.

## 5. Đồng bộ Gray pointer qua hai flip-flop

Trong write domain, đồng bộ `rd_gray` qua `rd_gray_wr_sync1` rồi
`rd_gray_wr_sync2`. Trong read domain, đồng bộ `wr_gray` qua
`wr_gray_rd_sync1` rồi `wr_gray_rd_sync2`.

Chỉ stage 2 được đưa vào logic `full/empty`. Có thể gắn thuộc tính
`(* ASYNC_REG = "TRUE" *)` cho các synchronizer register. Ở bước implementation
thực tế còn cần CDC/timing constraints để giới hạn skew của các bit Gray.

## 6. Tính cờ empty và full từ next pointer

Read side sẽ empty sau operation hiện tại khi:

```systemverilog
rd_empty_next = (rd_gray_next == wr_gray_rd_sync2);
```

Write side sẽ full sau operation hiện tại khi hai bit cao nhất của read Gray
pointer được đảo và các bit còn lại bằng nhau:

```systemverilog
wr_full_next =
    (wr_gray_next == {
        ~rd_gray_wr_sync2[PTR_WIDTH-1:PTR_WIDTH-2],
         rd_gray_wr_sync2[PTR_WIDTH-3:0]
    });
```

Công thức đảo hai MSB áp dụng vì `DEPTH` là lũy thừa của hai và `PTR_WIDTH =
ADDR_WIDTH + 1`. Register `wr_full <= wr_full_next` theo `wr_clk` và
`rd_empty <= rd_empty_next` theo `rd_clk`. Dùng next pointer giúp flag assert
ngay sau write lấp ô cuối hoặc read lấy phần tử cuối.

## 7. Viết datapath memory

Write port:

```systemverilog
always_ff @(posedge wr_clk)
    if (wr_accept)
        mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;
```

Read port nằm trong read-domain sequential block:

```systemverilog
if (rd_accept)
    rd_data <= mem[rd_bin[ADDR_WIDTH-1:0]];
```

Khi không có accepted read, không gán lại `rd_data` để nó giữ giá trị hợp lệ
gần nhất. FIFO này không phải first-word fall-through.

## 8. Viết các output dạng registered

Trong write domain:

```systemverilog
overflow <= wr_en && wr_full;
```

Trong read domain:

```systemverilog
rd_valid  <= rd_accept;
underflow <= rd_en && rd_empty;
```

Reset value phải là `wr_full=0`, `overflow=0`, `rd_empty=1`, `rd_valid=0`,
`underflow=0`, `rd_data='0`.

## 9. Checklist trước khi mô phỏng

- `DEPTH >= 4` và là lũy thừa của hai.
- Pointer chỉ tăng khi request được accept.
- Memory không bị reset.
- Không có signal tổ hợp đi trực tiếp từ một domain sang domain kia.
- Stage 1 của synchronizer không điều khiển logic chức năng.
- `full/empty` dùng synchronized pointer và next local pointer.
- Ghi khi full không đổi pointer/memory và báo `overflow`.
- Đọc khi empty không đổi pointer/data, kéo `rd_valid=0` và báo `underflow`.
- Test với hai clock có chu kỳ và pha khác nhau, cả write nhanh hơn lẫn read
  nhanh hơn.
- Test reset khi clock đang dừng, wrap-around nhiều vòng, full, empty và traffic
  back-to-back.

## 10. Thứ tự debug đề xuất

Quan sát waveform theo nhóm: reset pipe; binary/Gray pointer cục bộ; hai stage
synchronizer; `wr_accept/rd_accept`; `wr_full/rd_empty`; cuối cùng mới kiểm tra
data và error flag. Khi remote pointer thay đổi, flag phía nhận trễ khoảng 2-3
chu kỳ destination clock là hành vi đúng và bảo thủ theo spec.

## 11. Nếu chia thiết kế thành nhiều file

Bản chia module hoàn chỉnh nằm trong `reference_rtl/modular/`. Cấu trúc nên là:

```text
asyn_fifo_modular_reference.sv  top-level và kết nối
asyn_fifo_reset_sync.sv         reset synchronizer dùng chung
asyn_fifo_gray_sync.sv          Gray-pointer synchronizer dùng chung
asyn_fifo_write_ctrl.sv         toàn bộ write-domain control
asyn_fifo_read_ctrl.sv          toàn bộ read-domain control
asyn_fifo_memory.sv             dual-clock storage
files.f                         danh sách source để compile
```

Nên tách theo clock domain và trách nhiệm như trên, thay vì tách mỗi công thức
thành một module nhỏ. `write_ctrl` không chứa logic chạy bằng `rd_clk`;
`read_ctrl` không chứa logic chạy bằng `wr_clk`; top-level là nơi duy nhất nối
hai Gray pointer vào hai CDC synchronizer.
