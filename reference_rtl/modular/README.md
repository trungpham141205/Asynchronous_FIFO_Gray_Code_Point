# Modular reference RTL

Thiết kế được chia theo trách nhiệm:

```text
asyn_fifo_modular_reference.sv
├── asyn_fifo_reset_sync.sv   (instantiate 2 lần)
├── asyn_fifo_gray_sync.sv    (instantiate 2 lần)
├── asyn_fifo_write_ctrl.sv
├── asyn_fifo_read_ctrl.sv
└── asyn_fifo_memory.sv
```

Vai trò từng file:

- `asyn_fifo_modular_reference.sv`: top-level, chỉ khai báo wire và nối module.
- `asyn_fifo_reset_sync.sv`: reset assert bất đồng bộ, deassert đồng bộ hai cạnh.
- `asyn_fifo_gray_sync.sv`: synchronizer hai flip-flop cho Gray pointer.
- `asyn_fifo_write_ctrl.sv`: write pointer, Gray conversion, `wr_full`,
  `overflow` và `wr_accept`.
- `asyn_fifo_read_ctrl.sv`: read pointer, Gray conversion, `rd_empty`,
  `rd_valid`, `underflow` và `rd_accept`.
- `asyn_fifo_memory.sv`: cổng ghi theo `wr_clk`, cổng đọc registered theo
  `rd_clk`; array memory không reset.
- `files.f`: thứ tự các source file để đưa cho simulator.

Từ thư mục này có thể compile bằng Questa:

```bash
vlib work
vlog -sv -f files.f
```

Top-level tham khảo là `asyn_fifo_modular_reference`. Không file nào trong thư
mục này sử dụng thuộc tính `ASYNC_REG`.
