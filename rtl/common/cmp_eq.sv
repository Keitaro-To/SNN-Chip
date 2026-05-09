// From vivado_project_prototype/cmp_eq.vhd
module cmp_eq #(
  parameter int N = 4
) (
  input  logic [N-1:0] in0,
  input  logic [N-1:0] in1,
  output logic         cmp_out
);

  always_comb begin
    cmp_out = (in0 == in1);
  end

endmodule
