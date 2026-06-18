// From vivado_project_prototype/barrier_cu.vhd

module barrier_cu (
  input  logic clk,
  input  logic rst_n,
  input  logic restart,
  input  logic out_sample,
  output logic barrier_rst_n,
  output logic barrier_en,
  output logic ready
);

  import spiker_pkg::*;

  mi_states_t present_state, next_state;

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
      MI_RESET: next_state = MI_IDLE;
      MI_IDLE: begin
        if (restart)
          next_state = MI_INIT;
        else if (out_sample)
          next_state = MI_SAMPLE;
        else
          next_state = MI_IDLE;
      end
      MI_INIT:   next_state = MI_IDLE;
      MI_SAMPLE: next_state = MI_IDLE;
      default: next_state = MI_IDLE;
    endcase
  end

  // Outputs
  always_comb begin
    ready         = 1'b0;
    barrier_rst_n = 1'b1;
    barrier_en    = 1'b0;

    unique case (present_state)
      MI_RESET:  barrier_rst_n = 1'b0;
      MI_IDLE: begin
        ready = 1'b1;
        if (out_sample)
          barrier_en = 1'b1;
      end
      MI_INIT:   barrier_rst_n = 1'b0;
      MI_SAMPLE: barrier_en = 1'b1;
      default: ready = 1'b1;
    endcase
  end

endmodule

