// From vivado_project_prototype/rom_16x8_exclif1.vhd
module rom_exc #(
  parameter int n_neurons    = 8,
  parameter int weight_width = 8,
  parameter int addr_width   = 4
) (
  input  logic [addr_width-1:0] addra,
  input  logic        clka,
  output logic [n_neurons*weight_width-1:0] dout
);

  logic [n_neurons*weight_width-1:0] douta;

  assign dout = douta;

  rom_exc_ip #(
    .n_neurons(n_neurons),
    .weight_width(weight_width),
    .addr_width(addr_width)
  ) u_ip (
    .clka(clka),
    .addra(addra),
    .douta(douta)
  );

endmodule
