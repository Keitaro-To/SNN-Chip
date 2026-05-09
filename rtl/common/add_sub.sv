// Auto-translated from vivado_project_prototype/add_sub.vhd
module add_sub #(
  parameter int N = 16
) (
  input  logic signed [N-1:0] in0,
  input  logic signed [N-1:0] in1,
  input  logic               add_or_sub, // 0:add, 1:sub
  output logic signed [N-1:0] add_sub_out
);

  localparam int sat_up   = (1 <<< (N-1)) - 1;
  localparam int sat_down = -(1 <<< (N-1));

  logic signed [N:0] local_in0;
  logic signed [N:0] local_in1;
  logic signed [N:0] local_out;

  always_comb begin
    // Sign-extend
    local_in0 = {in0[N-1], in0};
    local_in1 = {in1[N-1], in1};

    // Add/sub
    if (add_or_sub == 1'b0) begin
      local_out = local_in0 + local_in1;
    end else begin
      local_out = local_in0 - local_in1;
    end

    // Saturate on overflow (sign bit changes)
    if (local_out[N] != local_out[N-1]) begin
      if (local_out[N] == 1'b1) begin
        add_sub_out = $signed(N'(sat_down));
      end else begin
        add_sub_out = $signed(N'(sat_up));
      end
    end else begin
      add_sub_out = local_out[N-1:0];
    end
  end

endmodule

