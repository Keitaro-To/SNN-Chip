// Auto-translated from vivado_project_prototype/and_mask.vhd
module and_mask #(
  parameter int N = 8
) (
  input  logic signed [N-1:0] input_bits,
  input  logic                mask_bit,
  output logic signed [N-1:0] output_bits
);

  always_comb begin
    for (int i = 0; i < N; i++) begin
      output_bits[i] = input_bits[i] & mask_bit;
    end
  end

endmodule

