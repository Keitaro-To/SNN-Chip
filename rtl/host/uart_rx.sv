// UART receiver (8N1). Samples one byte per frame.
module uart_rx #(
  parameter int CLK_HZ     = 100_000_000,
  parameter int BAUD       = 115_200
) (
  input  logic clk,
  input  logic rst_n,
  input  logic rx,
  output logic       byte_ready,
  output logic [7:0] byte_out
);

  localparam int BAUD_DIV = CLK_HZ / BAUD;
  localparam int HALF_BIT = BAUD_DIV / 2;
  localparam int TICK_W = $clog2(BAUD_DIV);

  typedef enum logic [1:0] {
    RX_IDLE,
    RX_START,
    RX_DATA,
    RX_STOP
  } rx_state_t;

  rx_state_t state;
  logic [TICK_W-1:0] tick;
  logic [2:0] bit_idx;
  logic [7:0] shift;

  assign byte_out   = shift;
  assign byte_ready = (state == RX_STOP) && (tick == TICK_W'(HALF_BIT));

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= RX_IDLE;
      tick  <= '0;
      bit_idx <= '0;
      shift <= '0;
    end else begin
      unique case (state)
        RX_IDLE: begin
          tick <= '0;
          if (rx == 1'b0) begin
            state <= RX_START;
            tick  <= '0;
          end
        end

        RX_START: begin
          if (tick == TICK_W'(HALF_BIT)) begin
            state <= RX_DATA;
            tick  <= '0;
            bit_idx <= '0;
          end else begin
            tick <= tick + 1'b1;
          end
        end

        RX_DATA: begin
          if (tick == TICK_W'(BAUD_DIV - 1)) begin
            tick <= '0;
            shift[bit_idx] <= rx;
            if (bit_idx == 3'd7) begin
              state <= RX_STOP;
            end else begin
              bit_idx <= bit_idx + 1'b1;
            end
          end else begin
            tick <= tick + 1'b1;
          end
        end

        RX_STOP: begin
          if (tick == TICK_W'(BAUD_DIV - 1)) begin
            state <= RX_IDLE;
            tick  <= '0;
          end else begin
            tick <= tick + 1'b1;
          end
        end

        default: state <= RX_IDLE;
      endcase
    end
  end

endmodule
