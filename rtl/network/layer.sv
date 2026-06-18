// From vivado_project_prototype/layer_8_neurons_16_inputs.vhd
module layer #(
  parameter int n_exc_inputs          = 16,
  parameter int n_inh_inputs          = 8,
  parameter int n_neurons             = 8,
  parameter int exc_cnt_bitwidth      = 4,
  parameter int inh_cnt_bitwidth      = 3,
  parameter int neuron_bit_width      = 16,
  parameter int inh_weights_bit_width = 8,
  parameter int exc_weights_bit_width = 8,
  parameter int shift                 = 3
) (
  input  logic                     clk,
  input  logic                     rst_n,
  input  logic                     start,
  input  logic                     restart,
  input  logic [n_exc_inputs-1:0]   exc_spikes,
  input  logic [((n_inh_inputs > 0) ? n_inh_inputs : 1) - 1:0] inh_spikes,
  output logic                     ready,
  output logic [n_neurons-1:0]     out_spikes
);

  localparam logic signed [neuron_bit_width-1:0] v_th_fixed = 16'b0000_0000_0001_0000;

  logic neurons_ready;
  logic exc;
  logic inh;
  logic exc_spike;
  logic inh_spike;
  logic [exc_cnt_bitwidth-1:0] exc_cnt;
  logic [inh_cnt_bitwidth-1:0] inh_cnt;
  logic [exc_cnt_bitwidth-1:0] exc_addr;
  logic [inh_cnt_bitwidth-1:0] inh_addr;
  logic neuron_restart;
  logic barrier_ready;
  logic [n_neurons-1:0] out_spikes_inst;
  logic [n_neurons-1:0] exceed_inst;
  logic out_sample;
  logic scan_complete;

  logic [n_neurons-1:0] neuron_ready;
  logic [n_neurons*exc_weights_bit_width-1:0] exc_weights;
  logic [n_neurons*inh_weights_bit_width-1:0] inh_weights;

  assign neurons_ready = &neuron_ready & barrier_ready;

  multi_input #(
    .n_exc_inputs(n_exc_inputs),
    .n_inh_inputs(n_inh_inputs),
    .exc_cnt_bitwidth(exc_cnt_bitwidth),
    .inh_cnt_bitwidth(inh_cnt_bitwidth)
  ) multi_input_control (
    .clk(clk),
    .rst_n(rst_n),
    .restart(restart),
    .start(start),
    .exc_spikes(exc_spikes),
    .inh_spikes(inh_spikes),
    .neurons_ready(neurons_ready),
    .exc_cnt(exc_cnt),
    .inh_cnt(inh_cnt),
    .ready(ready),
    .neuron_restart(neuron_restart),
    .exc(exc),
    .inh(inh),
    .out_sample(out_sample),
    .exc_spike(exc_spike),
    .inh_spike(inh_spike),
    .scan_complete(scan_complete)
  );

  generate
    genvar n;
    for (n = 0; n < n_neurons; n++) begin : gen_neurons
      neuron_subtractive #(
        .neuron_bit_width(neuron_bit_width),
        .inh_weights_bit_width(inh_weights_bit_width),
        .exc_weights_bit_width(exc_weights_bit_width),
        .shift(shift)
      ) neuron_inst (
        .v_th(v_th_fixed),
        .inh_weight($signed(inh_weights[n*inh_weights_bit_width +: inh_weights_bit_width])),
        .exc_weight($signed(exc_weights[n*exc_weights_bit_width +: exc_weights_bit_width])),
        .clk(clk),
        .rst_n(rst_n),
        .restart(neuron_restart),
        .exc(exc),
        .inh(inh),
        .exc_spike(exc_spike),
        .inh_spike(inh_spike),
        .neuron_ready(neuron_ready[n]),
        .out_spike(out_spikes_inst[n]),
        .exceed_v_th_out(exceed_inst[n])
      );
    end
  endgenerate

  rom_exc #(
    .n_neurons(n_neurons),
    .weight_width(exc_weights_bit_width),
    .addr_width(exc_cnt_bitwidth)
  ) exc_mem (
    .clka(clk),
    .addra(exc_addr),
    .dout(exc_weights)
  );

  addr_converter #(.N(exc_cnt_bitwidth)) exc_addr_conv (
    .addr_in(exc_cnt),
    .addr_out(exc_addr)
  );

  generate
    if (n_inh_inputs > 0) begin : gen_inh_rom
      rom_inh #(
        .n_neurons(n_neurons),
        .weight_width(inh_weights_bit_width),
        .addr_width(inh_cnt_bitwidth)
      ) inh_mem (
        .clka(clk),
        .addra(inh_addr),
        .dout(inh_weights)
      );

      addr_converter #(.N(inh_cnt_bitwidth)) inh_addr_conv (
        .addr_in(inh_cnt),
        .addr_out(inh_addr)
      );
    end else begin : gen_no_inh_rom
      assign inh_weights = '0;
    end
  endgenerate

  barrier #(.N(n_neurons)) spikes_barrier (
    .clk(clk),
    .rst_n(rst_n),
    .restart(restart),
    .out_sample(scan_complete),
    .reg_in(exceed_inst),
    .ready(barrier_ready),
    .reg_out(out_spikes)
  );

endmodule
