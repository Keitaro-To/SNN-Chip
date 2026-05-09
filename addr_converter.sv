// From vivado_project_prototype/addr_converter.vhd (addr_out = addr_in + 1, unsigned wrap)
module addr_converter #(
  parameter int N = 4
) (
  input  logic [N-1:0] addr_in,
  output logic [N-1:0] addr_out
);

  always_comb begin
    addr_out = addr_in + 1'b1;
  end

endmodule
