// Functional ROM model (was *_ip in VHDL)
module rom_16x8_exclif1_ip (
  input  logic        clka,
  input  logic [3:0]  addra,
  output logic [63:0] douta
);

  always_ff @(posedge clka) begin
    // VHDL mem had 17 entries (0..16) but addra is 4 bits (0..15),
    // so only the first 16 entries are addressable in this prototype.
    douta <= {8{8'h10}};
  end

endmodule

