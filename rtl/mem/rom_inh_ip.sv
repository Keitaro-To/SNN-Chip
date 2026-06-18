// Functional ROM model (was *_ip in VHDL)
module rom_inh_ip #(
  parameter int n_neurons    = 8,
  parameter int weight_width = 8,
  parameter int addr_width   = 3
) (
  input  logic        clka,
  input  logic [addr_width-1:0] addra,
  output logic [n_neurons*weight_width-1:0] douta
);

  always_ff @(posedge clka) begin
    douta <= '0;
  end

endmodule
