// Functional ROM model (was *_ip in VHDL)
// Simulation: $readmemh with plusargs / relative paths.
// Synthesis:  $readmemh("rom_exc_weights.hex") colocated in rtl/mem/ (run scripts/weights_to_rom.py).
module rom_exc_ip #(
  parameter int n_neurons    = 8,
  parameter int weight_width = 8,
  parameter int addr_width   = 4
) (
  input  logic        clka,
  input  logic [addr_width-1:0] addra,
  output logic [n_neurons*weight_width-1:0] douta
);

  localparam int mem_depth = 1 << addr_width;
  localparam int dout_width = n_neurons * weight_width;

  (* rom_style = "block" *)
  logic [dout_width-1:0] mem [0:mem_depth-1];

`ifdef SYNTHESIS
  initial begin
    $readmemh("rom_exc_weights.hex", mem);
  end
`else
  initial begin
    string weight_file;
    if ($value$plusargs("WEIGHTS=%s", weight_file)) begin
      $readmemh(weight_file, mem);
    end else if ($test$plusargs("HOST_SIM")) begin
      $readmemh("rom_exc_weights.hex", mem);
    end else begin
      $readmemh("../../sim/mem/rom_exc_weights.hex", mem);
    end
  end
`endif

  always_ff @(posedge clka) begin
    douta <= mem[addra];
  end

endmodule
