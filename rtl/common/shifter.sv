// From vivado_project_prototype/shifter.vhd (arithmetic right shift by fixed shift)
module shifter #(
  parameter int N     = 16,
  parameter int shift = 3
) (
  input  logic signed [N-1:0] shifter_in,
  output logic signed [N-1:0] shifted_out
);

  // Match VHDL: sign-extend top `shift` bits; low part is in[N-1:shift]
  assign shifted_out = shifter_in >>> shift;

endmodule
