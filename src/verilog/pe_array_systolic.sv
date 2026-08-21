module pe_array_systolic (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        valid_in,
    input  logic [15:0] weight,
    input  logic [15:0] input_act,
    output logic [31:0] accum_out,
    output logic        valid_out
);
    // Systolic PE: accumulates MAC operations for GEMV
    // y = sum(w_i * x_i) across vector elements
    
    logic signed [31:0] partial_sum;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            partial_sum <= 32'sd0;
            accum_out <= 32'sd0;
            valid_out <= 1'b0;
        end else begin
            if (valid_in) begin
                partial_sum <= $signed(partial_sum) + $signed({weight}) * $signed({input_act});
                accum_out <= partial_sum;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule