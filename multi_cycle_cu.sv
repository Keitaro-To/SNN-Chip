// From vivado_project_prototype/multi_cycle_cu.vhd
module multi_cycle_cu (
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  input  logic all_ready,
  input  logic stop,
  output logic cycles_cnt_en,
  output logic cycles_cnt_rst_n,
  output logic ready,
  output logic restart,
  output logic start_all
);

  import spiker_pkg::*;

  mc_states_t present_state, next_state;

  always_ff @(posedge clk) begin
    if (!rst_n)
      present_state <= MC_RESET;
    else
      present_state <= next_state;
  end

  always_comb begin
    unique case (present_state)
      MC_RESET: next_state = MC_IDLE_WAIT;

      MC_IDLE_WAIT: begin
        if (all_ready)
          next_state = MC_IDLE;
        else
          next_state = MC_IDLE_WAIT;
      end

      MC_IDLE: begin
        if (start)
          next_state = MC_INIT;
        else
          next_state = MC_IDLE;
      end

      MC_INIT: next_state = MC_UPDATE_WAIT;

      MC_UPDATE_WAIT: begin
        if (all_ready) begin
          if (stop)
            next_state = MC_IDLE;
          else
            next_state = MC_NETWORK_UPDATE;
        end else begin
          next_state = MC_UPDATE_WAIT;
        end
      end

      MC_NETWORK_UPDATE: next_state = MC_UPDATE_WAIT;

      default: next_state = MC_RESET;
    endcase
  end

  always_comb begin
    ready            = 1'b0;
    start_all        = 1'b0;
    cycles_cnt_en    = 1'b0;
    cycles_cnt_rst_n = 1'b1;
    restart          = 1'b0;

    unique case (present_state)
      MC_RESET: cycles_cnt_rst_n = 1'b0;
      MC_IDLE_WAIT: ready = 1'b0;
      MC_IDLE: begin
        ready            = 1'b1;
        cycles_cnt_rst_n = 1'b0;
      end
      MC_INIT: restart = 1'b1;
      MC_UPDATE_WAIT: begin
        start_all     = 1'b0;
        cycles_cnt_en = 1'b0;
      end
      MC_NETWORK_UPDATE: begin
        start_all     = 1'b1;
        cycles_cnt_en = 1'b1;
      end
      default: cycles_cnt_rst_n = 1'b0;
    endcase
  end

endmodule

