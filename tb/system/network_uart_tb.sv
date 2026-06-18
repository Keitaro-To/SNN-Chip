`timescale 1ns/1ps

// UART loopback smoke test for network_uart (tx tied to rx).
module network_uart_tb;
  localparam time CLK_HALF = 5ns;

  logic clk;
  logic rst_n;
  logic uart_loop;

  network_uart dut (
    .clk(clk),
    .rst_n(rst_n),
    .uart_rx(uart_loop),
    .uart_tx(uart_loop)
  );

  initial begin
    clk = 1'b0;
    forever #CLK_HALF clk = ~clk;
  end

  initial begin
    rst_n = 1'b0;
    repeat (8) @(posedge clk);
    rst_n = 1'b1;
  end

  initial begin
    $dumpfile("network_uart_tb.vcd");
    $dumpvars(0, network_uart_tb);
    repeat (2_000_000) @(posedge clk);
    $display("network_uart_tb: loopback idle completed");
    $finish;
  end

endmodule
