// From vivado_project_prototype/multi_input_cu.vhd
module multi_input_cu (
  input  logic clk,
  input  logic rst_n,
  input  logic restart,
  input  logic start,
  input  logic neurons_ready,
  input  logic exc_yes,
  input  logic exc_stop,
  input  logic inh_yes,
  input  logic inh_stop,
  output logic exc_cnt_en,
  output logic exc_cnt_rst_n,
  output logic inh_cnt_en,
  output logic inh_cnt_rst_n,
  output logic exc,
  output logic inh,
  output logic spike_sample,
  output logic spike_rst_n,
  output logic neuron_restart,
  output logic ready,
  output logic scan_complete
);

  import spiker_pkg::*;

  mi_states_t present_state, next_state;
  logic scan_complete_d;

  always_ff @(posedge clk) begin
    if (!rst_n)
      scan_complete_d <= 1'b0;
    else
      scan_complete_d <= (present_state == MI_EXC_UPDATE) && exc_stop;
  end

  assign scan_complete = scan_complete_d;

  // State transition
  always_ff @(posedge clk) begin
    if (!rst_n)
      present_state <= MI_RESET;
    else
      present_state <= next_state;
  end

  // Next-state logic
  always_comb begin
    unique case (present_state)
      MI_RESET: next_state = MI_IDLE_WAIT;

      MI_IDLE_WAIT: begin
        if (neurons_ready)
          next_state = MI_IDLE;
        else
          next_state = MI_IDLE_WAIT;
      end

      MI_IDLE: begin
        if (restart)
          next_state = MI_INIT_WAIT;
        else if (start)
          next_state = MI_SAMPLE;
        else
          next_state = MI_IDLE;
      end

      MI_INIT_WAIT: begin
        if (neurons_ready)
          next_state = MI_INIT;
        else
          next_state = MI_INIT_WAIT;
      end

      MI_INIT: next_state = MI_IDLE;

      MI_SAMPLE: begin
        if (exc_yes) begin
          if (inh_yes)
            next_state = MI_EXC_INH_WAIT;
          else
            next_state = MI_EXC_WAIT;
        end else begin
          if (inh_yes)
            next_state = MI_INH_WAIT;
          else
            next_state = MI_IDLE;
        end
      end

      MI_EXC_INH_WAIT: begin
        if (neurons_ready)
          next_state = MI_EXC_UPDATE_FULL;
        else
          next_state = MI_EXC_INH_WAIT;
      end

      MI_EXC_UPDATE_FULL: begin
        if (exc_stop)
          next_state = MI_INH_WAIT_FULL;
        else
          next_state = MI_EXC_UPDATE_FULL;
      end

      MI_INH_WAIT_FULL: begin
        if (neurons_ready)
          next_state = MI_INH_UPDATE_FULL;
        else
          next_state = MI_INH_WAIT_FULL;
      end

      MI_INH_UPDATE_FULL: begin
        if (inh_stop)
          next_state = MI_IDLE;
        else
          next_state = MI_INH_UPDATE_FULL;
      end

      MI_EXC_WAIT: begin
        if (neurons_ready)
          next_state = MI_EXC_UPDATE;
        else
          next_state = MI_EXC_WAIT;
      end

      MI_INH_UPDATE: begin
        if (inh_stop)
          next_state = MI_IDLE;
        else
          next_state = MI_INH_UPDATE;
      end

      MI_INH_WAIT: begin
        if (neurons_ready)
          next_state = MI_INH_UPDATE;
        else
          next_state = MI_INH_WAIT;
      end

      MI_EXC_UPDATE: begin
        if (exc_stop)
          next_state = MI_IDLE;
        else
          next_state = MI_EXC_UPDATE;
      end

      default: next_state = MI_RESET;
    endcase
  end

  // Outputs
  always_comb begin
    exc_cnt_en      = 1'b0;
    exc_cnt_rst_n   = 1'b0;
    inh_cnt_en      = 1'b0;
    inh_cnt_rst_n   = 1'b0;
    exc             = 1'b0;
    inh             = 1'b0;
    spike_sample    = 1'b0;
    spike_rst_n     = 1'b1;
    neuron_restart  = 1'b0;
    ready           = 1'b0;

    unique case (present_state)
      MI_RESET: begin
        exc_cnt_rst_n = 1'b0;
        inh_cnt_rst_n = 1'b0;
        spike_rst_n   = 1'b0;
      end

      MI_IDLE_WAIT: ready = 1'b0;

      MI_IDLE: begin
        ready       = 1'b1;
        spike_rst_n = 1'b0;
      end

      MI_INIT_WAIT: ready = 1'b0;

      MI_INIT: neuron_restart = 1'b1;

      MI_SAMPLE: begin
        exc          = 1'b1;
        inh          = 1'b1;
        spike_sample = 1'b1;
        ready        = 1'b0;
      end

      MI_EXC_INH_WAIT: ready = 1'b0;

      MI_EXC_UPDATE_FULL: begin
        exc           = 1'b1;
        exc_cnt_rst_n  = 1'b1;
        exc_cnt_en     = 1'b1;
      end

      MI_INH_WAIT_FULL: ready = 1'b0;

      MI_INH_UPDATE_FULL: begin
        inh           = 1'b1;
        inh_cnt_en    = 1'b1;
        inh_cnt_rst_n = 1'b1;
      end

      MI_EXC_WAIT: ready = 1'b0;

      MI_INH_UPDATE: begin
        inh           = 1'b1;
        inh_cnt_en    = 1'b1;
        inh_cnt_rst_n = 1'b1;
      end

      MI_INH_WAIT: ready = 1'b0;

      MI_EXC_UPDATE: begin
        exc           = 1'b1;
        exc_cnt_rst_n  = 1'b1;
        exc_cnt_en     = 1'b1;
      end

      default: spike_rst_n = 1'b0;
    endcase
  end

endmodule

