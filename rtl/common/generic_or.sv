// From vivado_project_prototype/generic_or.vhd
module generic_or #(
  parameter int N = 16
) (
  input  logic [N-1:0] or_in,
  output logic         or_out
);

  always_comb begin
    or_out = 1'b0;
    for (int i = 0; i < N; i++) begin
      or_out |= or_in[i];
    end
  end

endmodule
