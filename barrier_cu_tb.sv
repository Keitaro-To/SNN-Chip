// From vivado_project_prototype/barrier_cu.vhd
`include "spiker_pkg.sv"

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
      present_state <= reset;
    else
      present_state <= next_state;
  end

  // Next-state logic
  always_comb begin
    unique case (present_state)
      reset: next_state = idle;
      idle: begin
        if (restart)
          next_state = init;
        else if (out_sample)
          next_state = sample;
        else
          next_state = idle;
      end
      init:   next_state = idle;
      sample: next_state = idle;
      default: next_state = idle;
    endcase
  end

  // Outputs
  always_comb begin
    ready         = 1'b0;
    barrier_rst_n = 1'b1;
    barrier_en    = 1'b0;

    unique case (present_state)
      reset:  barrier_rst_n = 1'b0;
      idle:   ready = 1'b1;
      init:   barrier_rst_n = 1'b0;
      sample: barrier_en = 1'b1;
      default: ready = 1'b1;
    endcase
  end

endmodule

