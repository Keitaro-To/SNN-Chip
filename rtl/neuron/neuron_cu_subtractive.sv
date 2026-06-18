// From vivado_project_prototype/neuron_cu_subtractive.vhd
module neuron_cu_subtractive (
  input  logic       clk,
  input  logic       rst_n,
  input  logic       restart,
  input  logic       exc,
  input  logic       inh,
  input  logic       exceed_v_th,
  output logic [1:0] update_sel,
  output logic       add_or_sub,
  output logic       v_en,
  output logic       v_rst_n,
  output logic       neuron_ready,
  output logic       out_spike
);

  import spiker_pkg::*;

  neuron_states_t present_state, next_state;

  always_ff @(posedge clk) begin
    if (!rst_n)
      present_state <= NS_RESET;
    else
      present_state <= next_state;
  end

  always_comb begin
    unique case (present_state)
      NS_RESET: next_state = NS_IDLE;

      NS_IDLE: begin
        if (restart) begin
          next_state = NS_INIT;
        end else if (exc) begin
          if (inh) begin
            if (exceed_v_th)
              next_state = NS_FIRE;
            else
              next_state = NS_LEAK;
          end else begin
            next_state = NS_EXCITE;
          end
        end else if (inh) begin
          next_state = NS_INHIBIT;
        end else begin
          next_state = NS_IDLE;
        end
      end

      NS_INIT: next_state = NS_IDLE;

      NS_FIRE: begin
        if (exc && inh)
          next_state = NS_LEAK;
        else
          next_state = NS_IDLE;
      end

      NS_LEAK: begin
        if (exc && inh)
          next_state = NS_LEAK;
        else
          next_state = NS_IDLE;
      end

      NS_EXCITE: begin
        if (exc)
          next_state = NS_EXCITE;
        else
          next_state = NS_IDLE;
      end

      NS_INHIBIT: begin
        if (inh)
          next_state = NS_INHIBIT;
        else
          next_state = NS_IDLE;
      end

      default: next_state = NS_RESET;
    endcase
  end

  always_comb begin
    update_sel   = 2'b01;
    add_or_sub   = 1'b0;
    v_en         = 1'b0;
    v_rst_n      = 1'b1;
    out_spike    = 1'b0;
    neuron_ready = 1'b0;

    unique case (present_state)
      NS_RESET: v_rst_n = 1'b0;
      NS_IDLE: begin
        neuron_ready = 1'b1;
        if (exc && inh && exceed_v_th)
          out_spike = 1'b1;
        else if (!exc && !inh && exceed_v_th)
          out_spike = 1'b1;
      end
      NS_INIT:  v_rst_n = 1'b0;
      NS_EXCITE: begin
        update_sel = 2'b10;
        v_en       = 1'b1;
      end
      NS_INHIBIT: begin
        update_sel = 2'b11;
        v_en       = 1'b1;
      end
      NS_LEAK: begin
        update_sel = 2'b01;
        v_en       = 1'b1;
        add_or_sub = 1'b1;
      end
      NS_FIRE: begin
        update_sel = 2'b00;
        add_or_sub = 1'b1;
        v_en       = 1'b1;
        out_spike  = 1'b1;
      end
      default: v_rst_n = 1'b0;
    endcase
  end

endmodule

