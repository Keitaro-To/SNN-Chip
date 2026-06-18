// UART transmitter (8N1). Accepts one byte per frame.
module uart_tx #(
  parameter int CLK_HZ = 100_000_000,
  parameter int BAUD   = 115_200
) (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       send,
  input  logic [7:0] byte_in,
  output logic       busy,
  output logic       tx
);

  localparam int BAUD_DIV = CLK_HZ / BAUD;
  localparam int TICK_W = $clog2(BAUD_DIV);

  typedef enum logic [1:0] {
    TX_IDLE,
    TX_START,
    TX_DATA,
    TX_STOP
  } tx_state_t;

  tx_state_t state;
  logic [TICK_W-1:0] tick;
  logic [2:0] bit_idx;
  logic [7:0] shift;

  assign busy = (state != TX_IDLE);

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= TX_IDLE;
      tick  <= '0;
      bit_idx <= '0;
      shift <= '0;
      tx    <= 1'b1;
    end else begin
      unique case (state)
        TX_IDLE: begin
          tx <= 1'b1;
          if (send) begin
            shift <= byte_in;
            state <= TX_START;
            tick  <= '0;
          end
        end

        TX_START: begin
          tx <= 1'b0;
          if (tick == TICK_W'(BAUD_DIV - 1)) begin
            state <= TX_DATA;
            tick  <= '0;
            bit_idx <= '0;
          end else begin
            tick <= tick + 1'b1;
          end
        end

        TX_DATA: begin
          tx <= shift[bit_idx];
          if (tick == TICK_W'(BAUD_DIV - 1)) begin
            tick <= '0;
            if (bit_idx == 3'd7) begin
              state <= TX_STOP;
            end else begin
              bit_idx <= bit_idx + 1'b1;
            end
          end else begin
            tick <= tick + 1'b1;
          end
        end

        TX_STOP: begin
          tx <= 1'b1;
          if (tick == TICK_W'(BAUD_DIV - 1)) begin
            state <= TX_IDLE;
            tick  <= '0;
          end else begin
            tick <= tick + 1'b1;
          end
        end

        default: state <= TX_IDLE;
      endcase
    end
  end

endmodule
