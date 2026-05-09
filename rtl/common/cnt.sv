// From vivado_project_prototype/cnt.vhd
module cnt #(
  parameter int N         = 8,
  parameter int rst_value = 0
) (
  input  logic             clk,
  input  logic             cnt_en,
  input  logic             cnt_rst_n,
  output logic [N-1:0]     cnt_out
);

  always_ff @(posedge clk) begin
    if (!cnt_rst_n)
      cnt_out <= N'(rst_value);
    else if (cnt_en)
      cnt_out <= cnt_out + 1'b1;
  end

endmodule
