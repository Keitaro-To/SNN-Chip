// From vivado_project_prototype/mux_8to1.vhd
module mux_8to1 (
  input  logic [2:0] mux_sel,
  input  logic       in0,
  input  logic       in1,
  input  logic       in2,
  input  logic       in3,
  input  logic       in4,
  input  logic       in5,
  input  logic       in6,
  input  logic       in7,
  output logic       mux_out
);

  always_comb begin
    unique case (mux_sel)
      3'b000: mux_out = in0;
      3'b001: mux_out = in1;
      3'b010: mux_out = in2;
      3'b011: mux_out = in3;
      3'b100: mux_out = in4;
      3'b101: mux_out = in5;
      3'b110: mux_out = in6;
      default: mux_out = in7;
    endcase
  end

endmodule

