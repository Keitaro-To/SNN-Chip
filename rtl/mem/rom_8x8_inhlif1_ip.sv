// Functional ROM model (was *_ip in VHDL)
module rom_8x8_inhlif1_ip (
  input  logic        clka,
  input  logic [2:0]  addra,
  output logic [63:0] douta
);

  // VHDL mem had 9 entries (0..8), all zeros.
  always_ff @(posedge clka) begin
    douta <= 64'h0;
  end

endmodule

