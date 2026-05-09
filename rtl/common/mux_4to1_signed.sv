// From vivado_project_prototype/mux_4to1_signed.vhd
module mux_4to1_signed #(
  parameter int bitwidth = 16
) (
  input  logic [1:0]                    mux_sel,
  input  logic signed [bitwidth-1:0]    in0,
  input  logic signed [bitwidth-1:0]    in1,
  input  logic signed [bitwidth-1:0]    in2,
  input  logic signed [bitwidth-1:0]    in3,
  output logic signed [bitwidth-1:0]    mux_out
);

  always_comb begin
    unique case (mux_sel)
      2'b00: mux_out = in0;
      2'b01: mux_out = in1;
      2'b10: mux_out = in2;
      default: mux_out = in3;
    endcase
  end

endmodule

