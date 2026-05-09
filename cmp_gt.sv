// From vivado_project_prototype/cmp_gt.vhd
module cmp_gt #(
  parameter int N = 16
) (
  input  logic signed [N-1:0] in0,
  input  logic signed [N-1:0] in1,
  output logic                 cmp_out
);

  always_comb begin
    cmp_out = (in0 > in1);
  end

endmodule
