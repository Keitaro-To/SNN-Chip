// Minimal SystemVerilog equivalent of spiker_pkg.vhd for the generated design.
// Only includes the enum used by barrier_cu/barrier in this prototype output.
package spiker_pkg;
  typedef enum logic [3:0] {
    reset      = 4'd0,
    idle_wait  = 4'd1,
    idle       = 4'd2,
    init_wait  = 4'd3,
    init       = 4'd4,
    sample     = 4'd5,
    exc_inh_wait=4'd6,
    exc_update_full=4'd7,
    inh_wait_full=4'd8,
    inh_update_full=4'd9,
    exc_wait   = 4'd10,
    inh_update = 4'd11,
    inh_wait   = 4'd12,
    exc_update = 4'd13
  } mi_states_t;
endpackage

