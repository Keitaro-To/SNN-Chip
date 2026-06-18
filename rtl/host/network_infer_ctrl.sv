// Host-side inference sequencer for network (matches network_tb handshake).
module network_infer_ctrl #(
  parameter int n_exc_inputs = 162,
  parameter int n_neurons    = 40,
  parameter int n_cycles     = 5
) (
  input  logic                        clk,
  input  logic                        rst_n,
  input  logic                        infer_req,
  input  logic [n_exc_inputs-1:0]     spikes_in,
  output logic                        busy,
  output logic                        done,
  output logic [n_neurons-1:0]        spikes_out,
  output logic                        net_start,
  output logic                        net_sample_ready,
  input  logic                        net_ready,
  input  logic                        net_sample,
  output logic [n_exc_inputs-1:0]     net_in_spikes,
  input  logic [n_neurons-1:0]        net_out_spikes
);

  typedef enum logic [2:0] {
    INF_IDLE,
    INF_WAIT_READY,
    INF_PULSE_START,
    INF_RUN,
    INF_WAIT_DONE
  } infer_state_t;

  infer_state_t state, next_state;
  logic [7:0] window_cnt;
  logic [n_exc_inputs-1:0] spikes_hold;
  logic [n_neurons-1:0] spikes_capture;

  assign busy = (state != INF_IDLE);
  assign done = (state == INF_WAIT_DONE) && net_ready;
  assign spikes_out = spikes_capture;
  assign net_sample_ready = 1'b1;
  assign net_in_spikes = spikes_hold;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= INF_IDLE;
      window_cnt <= '0;
      spikes_hold <= '0;
      spikes_capture <= '0;
      net_start <= 1'b0;
    end else begin
      state <= next_state;
      net_start <= 1'b0;

      if (infer_req)
        spikes_capture <= '0;
      else if (busy && (|net_out_spikes))
        spikes_capture <= net_out_spikes;

      unique case (state)
        INF_IDLE: begin
          window_cnt <= '0;
          if (infer_req) begin
            spikes_hold <= spikes_in;
          end
        end

        INF_PULSE_START: begin
          net_start <= 1'b1;
        end

        INF_RUN: begin
          window_cnt <= window_cnt + 1'b1;
          if (net_sample) begin
            spikes_hold <= spikes_in;
          end
        end

        default: ;
      endcase
    end
  end

  always_comb begin
    next_state = state;
    unique case (state)
      INF_IDLE: begin
        if (infer_req) begin
          next_state = INF_WAIT_READY;
        end
      end

      INF_WAIT_READY: begin
        if (net_ready) begin
          next_state = INF_PULSE_START;
        end
      end

      INF_PULSE_START: begin
        next_state = INF_RUN;
      end

      INF_RUN: begin
        if (window_cnt >= 8'(n_cycles + 1)) begin
          next_state = INF_WAIT_DONE;
        end
      end

      INF_WAIT_DONE: begin
        if (net_ready) begin
          next_state = INF_IDLE;
        end
      end

      default: next_state = INF_IDLE;
    endcase
  end

endmodule
