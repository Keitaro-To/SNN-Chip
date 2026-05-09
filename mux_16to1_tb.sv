// From vivado_project_prototype/mux_16to1.vhd
module mux_16to1 (
  input  logic [3:0] mux_sel,
  input  logic       in0,
  input  logic       in1,
  input  logic       in2,
  input  logic       in3,
  input  logic       in4,
  input  logic       in5,
  input  logic       in6,
  input  logic       in7,
  input  logic       in8,
  input  logic       in9,
  input  logic       in10,
  input  logic       in11,
  input  logic       in12,
  input  logic       in13,
  input  logic       in14,
  input  logic       in15,
  output logic       mux_out
);

  always_comb begin
    unique case (mux_sel)
      4'h0: mux_out = in0;
      4'h1: mux_out = in1;
      4'h2: mux_out = in2;
      4'h3: mux_out = in3;
      4'h4: mux_out = in4;
      4'h5: mux_out = in5;
      4'h6: mux_out = in6;
      4'h7: mux_out = in7;
      4'h8: mux_out = in8;
      4'h9: mux_out = in9;
      4'hA: mux_out = in10;
      4'hB: mux_out = in11;
      4'hC: mux_out = in12;
      4'hD: mux_out = in13;
      4'hE: mux_out = in14;
      default: mux_out = in15;
    endcase
  end

endmodule

