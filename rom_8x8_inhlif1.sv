// From vivado_project_prototype/rom_8x8_inhlif1.vhd
module rom_8x8_inhlif1 (
  input  logic        clka,
  input  logic [2:0]  addra,
  output logic [7:0]  dout_0,
  output logic [7:0]  dout_1,
  output logic [7:0]  dout_2,
  output logic [7:0]  dout_3,
  output logic [7:0]  dout_4,
  output logic [7:0]  dout_5,
  output logic [7:0]  dout_6,
  output logic [7:0]  dout_7
);

  logic [63:0] douta;

  assign dout_0 = douta[7:0];
  assign dout_1 = douta[15:8];
  assign dout_2 = douta[23:16];
  assign dout_3 = douta[31:24];
  assign dout_4 = douta[39:32];
  assign dout_5 = douta[47:40];
  assign dout_6 = douta[55:48];
  assign dout_7 = douta[63:56];

  rom_8x8_inhlif1_ip u_ip (
    .clka(clka),
    .addra(addra),
    .douta(douta)
  );

endmodule

