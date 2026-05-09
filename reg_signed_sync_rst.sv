// From vivado_project_prototype/reg_signed_sync_rst.vhd (synchronous reset)
module reg_signed_sync_rst #(
  parameter int N = 16
) (
  input  logic                  clk,
  input  logic                  en,
  input  logic                  rst_n,
  input  logic signed [N-1:0]   reg_in,
  output logic signed [N-1:0]   reg_out
);

  always_ff @(posedge clk) begin
    if (!rst_n)
      reg_out <= '0;
    else if (en)
      reg_out <= reg_in;
  end

endmodule
