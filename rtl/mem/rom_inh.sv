// From vivado_project_prototype/rom_8x8_inhlif1.vhd
module rom_inh #(
  parameter int n_neurons    = 8,
  parameter int weight_width = 8,
  parameter int addr_width   = 3
) (
  input  logic [addr_width-1:0] addra,
  input  logic        clka,
  output logic [n_neurons*weight_width-1:0] dout
);

  logic [n_neurons*weight_width-1:0] douta;

  assign dout = douta;

  rom_inh_ip #(
    .n_neurons(n_neurons),
    .weight_width(weight_width),
    .addr_width(addr_width)
  ) u_ip (
    .clka(clka),
    .addra(addra),
    .douta(douta)
  );

endmodule
