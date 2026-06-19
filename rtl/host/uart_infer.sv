// UART host protocol bridge for network inference.
module uart_infer #(
  parameter int CLK_HZ          = 100_000_000,
  parameter int BAUD            = 115_200,
  parameter int n_exc_inputs    = 162,
  parameter int n_neurons       = 40,
  parameter int infer_in_bytes  = 21,
  parameter int infer_out_bytes = 5,
  parameter logic [7:0] CMD_INFER    = 8'h01,
  parameter logic [7:0] STATUS_DONE  = 8'h80
) (
  input  logic clk,
  input  logic rst_n,
  input  logic uart_rx,
  output logic uart_tx,
  output logic                        infer_req,
  output logic [n_exc_inputs-1:0]     spikes_in,
  input  logic                        infer_busy,
  input  logic                        infer_done,
  input  logic [n_neurons-1:0]        spikes_out
);

  logic       rx_ready;
  logic [7:0] rx_byte;
  logic       tx_send;
  logic [7:0] tx_byte;
  logic       tx_busy;

  uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) rx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rx(uart_rx),
    .byte_ready(rx_ready),
    .byte_out(rx_byte)
  );

  uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) tx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .send(tx_send),
    .byte_in(tx_byte),
    .busy(tx_busy),
    .tx(uart_tx)
  );

  typedef enum logic [2:0] {
    ST_IDLE,
    ST_RX_PAYLOAD,
    ST_TRIGGER,
    ST_WAIT_DONE,
    ST_TX_STATUS,
    ST_TX_PAYLOAD
  } st_t;

  st_t state;
  logic [$clog2(infer_in_bytes + 1)-1:0] rx_cnt;
  logic [$clog2(infer_out_bytes + 1)-1:0] tx_cnt;
  logic [n_exc_inputs-1:0] spikes_reg;
  logic [n_neurons-1:0]   out_reg;

  assign infer_req  = (state == ST_TRIGGER);
  assign spikes_in  = spikes_reg;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= ST_IDLE;
      rx_cnt <= '0;
      tx_cnt <= '0;
      spikes_reg <= '0;
      out_reg <= '0;
      tx_send <= 1'b0;
      tx_byte <= '0;
    end else begin
      tx_send <= 1'b0;

      if (rx_ready) begin
        unique case (state)
          ST_IDLE: begin
            if (rx_byte == CMD_INFER && !infer_busy) begin
              state <= ST_RX_PAYLOAD;
              rx_cnt <= '0;
            end
          end

          ST_RX_PAYLOAD: begin
            for (int i = 0; i < 8; i++) begin
              if (rx_cnt * 8 + i < n_exc_inputs) begin
                spikes_reg[rx_cnt * 8 + i] <= rx_byte[i];
              end
            end
            if (rx_cnt == $bits(rx_cnt)'(infer_in_bytes - 1)) begin
              state <= ST_TRIGGER;
            end else begin
              rx_cnt <= rx_cnt + 1'b1;
            end
          end

          default: ;
        endcase
      end

      unique case (state)
        ST_TRIGGER: begin
          state <= ST_WAIT_DONE;
        end

        ST_WAIT_DONE: begin
          if (infer_done) begin
            out_reg <= spikes_out;
            state <= ST_TX_STATUS;
          end
        end

        ST_TX_STATUS: begin
          if (!tx_busy) begin
            tx_byte <= STATUS_DONE;
            tx_send <= 1'b1;
            state <= ST_TX_PAYLOAD;
            tx_cnt <= '0;
          end
        end

        ST_TX_PAYLOAD: begin
          if (!tx_busy && !tx_send) begin
            for (int i = 0; i < 8; i++) begin
              tx_byte[i] <= (tx_cnt * 8 + i < n_neurons) ? out_reg[tx_cnt * 8 + i] : 1'b0;
            end
            tx_send <= 1'b1;
            if (tx_cnt == $bits(tx_cnt)'(infer_out_bytes - 1)) begin
              state <= ST_IDLE;
            end else begin
              tx_cnt <= tx_cnt + 1'b1;
            end
          end
        end

        default: ;
      endcase
    end
  end

endmodule
