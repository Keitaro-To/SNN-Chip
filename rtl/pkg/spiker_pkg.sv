`timescale 1ns/1ps
// Minimal SystemVerilog equivalent of spiker_pkg.vhd for the generated design.
// Only includes the enum used by barrier_cu/barrier in this prototype output.
package spiker_pkg;
  typedef enum logic [3:0] {
    MI_RESET           = 4'd0,
    MI_IDLE_WAIT       = 4'd1,
    MI_IDLE            = 4'd2,
    MI_INIT_WAIT       = 4'd3,
    MI_INIT            = 4'd4,
    MI_SAMPLE          = 4'd5,
    MI_EXC_INH_WAIT    = 4'd6,
    MI_EXC_UPDATE_FULL = 4'd7,
    MI_INH_WAIT_FULL   = 4'd8,
    MI_INH_UPDATE_FULL = 4'd9,
    MI_EXC_WAIT        = 4'd10,
    MI_INH_UPDATE      = 4'd11,
    MI_INH_WAIT        = 4'd12,
    MI_EXC_UPDATE      = 4'd13
  } mi_states_t;

  typedef enum logic [2:0] {
    MC_RESET          = 3'd0,
    MC_IDLE_WAIT      = 3'd1,
    MC_IDLE           = 3'd2,
    MC_INIT           = 3'd3,
    MC_UPDATE_WAIT    = 3'd4,
    MC_NETWORK_UPDATE = 3'd5
  } mc_states_t;

  typedef enum logic [2:0] {
    NS_RESET   = 3'd0,
    NS_IDLE    = 3'd1,
    NS_INIT    = 3'd2,
    NS_EXCITE  = 3'd3,
    NS_INHIBIT = 3'd4,
    NS_FIRE    = 3'd5,
    NS_LEAK    = 3'd6
  } neuron_states_t;
endpackage

