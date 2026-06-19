##==============================================================================
## Zybo Z7-20 (xc7z020clg400-1) constraints for top: network_uart
##
## Port names must match network_uart.sv:
##   clk, rst_n, uart_rx, uart_tx
##
## Pin definitions from Digilent Zybo-Z7-Master.xdc (Rev. B):
##   https://github.com/Digilent/digilent-xdc/blob/master/Zybo-Z7-Master.xdc
##
## Board clock: 125 MHz on PL pin K17 (not 100 MHz).
## When synthesizing for this board, override the top parameter:
##   network_uart #(.CLK_HZ(125_000_000), ...)
## Otherwise UART baud rate (115200) will be incorrect.
##
## On-board USB-UART (connector J12) is wired to Zynq PS MIO48/49, not PL pins.
## For a PL-only bitstream, connect a USB-serial adapter or Pmod USBUART to
## Pmod JC pins below (JC1 = TX, JC2 = RX from the FPGA side).
##==============================================================================

## Configuration bank voltage (3.3 V I/O on Zybo Z7)
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

##------------------------------------------------------------------------------
## Clock — 125 MHz system clock (PL)
##------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -add -name sys_clk_pin -period 8.000 -waveform {0 4.000} [get_ports { clk }]

##------------------------------------------------------------------------------
## Reset — active-low, tied to SW0
##   Switch UP (toward board edge label) = logic 1 = run
##   Switch DOWN = logic 0 = hold in reset
##------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { rst_n }]

##------------------------------------------------------------------------------
## UART — Pmod JC (host / USB-serial adapter)
##   FPGA uart_tx  -> host RX  (JC pin 1, jc_p[1])
##   FPGA uart_rx  <- host TX  (JC pin 2, jc_n[1])
##
## Wiring example (3.3 V USB-serial, e.g. FT232RL):
##   Adapter TX  -> JC2 (W15)  uart_rx
##   Adapter RX  <- JC1 (V15)  uart_tx
##   GND         -> JC GND
##------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { uart_rx }]

##------------------------------------------------------------------------------
## Optional debug (uncomment after adding ports to the top module)
##------------------------------------------------------------------------------
## LEDs [3:0]
# set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
# set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }]
# set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }]
# set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }]

## Button BTN0 as active-high reset (requires rst = btn[0] in RTL, not rst_n)
# set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]

##------------------------------------------------------------------------------
## Alternate UART pins — Pmod JD (comment out JC UART above before enabling)
##------------------------------------------------------------------------------
# set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]
# set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { uart_rx }]

##------------------------------------------------------------------------------
## Zynq PS USB-UART (J12) via EMIO — not for PL-only flows
## Requires a block design that exports UART1 TX/RX to PL ports.
## PS MIO48 = UART1 RX (input to PS), MIO49 = UART1 TX (output from PS).
##------------------------------------------------------------------------------
