module gguf_q4_0_dequantizer (
    input  logic [15:0] scale_fp16,
    input  logic [3:0]  quant_nibble,
    output logic [15:0] dequant_fp16
);
    // Implements the GGUF Q4_0 dequantization formula:
    //   w_i = d * (q_i - 8)
    // where d is an IEEE 754 binary16 (FP16) scale and q_i is a stored
    // 4-bit value in [0, 15], giving a signed weight offset in [-8, 7].
    //
    // Supported range: normal FP16 scales. Subnormal scales flush to zero
    // and results round toward zero (truncation), which is acceptable for
    // this research datapath.

    // 1. Signed weight offset: q_i - 8 in [-8, 7]
    logic signed [4:0] q_off;
    assign q_off = $signed({1'b0, quant_nibble}) - 5'sd8;

    // 2. Decode FP16 scale into sign / exponent / mantissa fields
    wire        s_sign = scale_fp16[15];
    wire [4:0]  s_exp  = scale_fp16[14:10];
    wire [9:0]  s_man  = scale_fp16[9:0];

    wire s_normal = (s_exp != 5'd0) && (s_exp != 5'd31); // not subnormal/inf/NaN

    // 3. Magnitude of the integer factor: |q_i - 8| in [0, 8]
    wire [4:0] mag = q_off[4] ? (5'd0 - q_off) : q_off;

    // 4. Multiply |q_i - 8| by the implicit-1 mantissa (Q4.10 fixed point):
    //    |w| = mag * 1.mantissa * 2^(s_exp - 15)
    wire [14:0] man_one = {5'b00001, s_man};          // Q5.10, value in [1, 2)
    wire [19:0] prod    = mag * man_one;              // Q9.10 product

    // 5. Normalize: position of leading one defines the result exponent.
    //    |w| = prod * 2^(s_exp - 25); with prod's MSB at bit k,
    //    result exponent field E = (s_exp + k - 10)
    function automatic [4:0] msb_index;
        input [19:0] x;
        integer b;
        begin
            msb_index = 5'd0;
            for (b = 19; b >= 0; b = b - 1) begin
                if (x[b] && (msb_index == 5'd0)) msb_index = b[4:0];
            end
        end
    endfunction

    wire [4:0] k   = msb_index(prod);
    wire       zero = (mag == 5'd0) || !s_normal || (prod == 20'd0);

    // Align so the leading one sits at bit 10: shift left when k < 10,
    // right when k > 10. The 10 bits below bit 10 are the stored fraction
    // (truncated toward zero).
    wire [19:0] aligned = (k >= 5'd10) ? (prod >> (k - 5'd10))
                                       : (prod << (5'd10 - k));
    wire [9:0]  r_man   = aligned[9:0];

    wire signed [6:0] r_exp = $signed({2'b00, s_exp}) + $signed({3'b000, k}) - 7'sd10;

    wire exp_overflow  = (r_exp > 7'sd30);
    wire exp_underflow = (r_exp <= 7'sd0);

    // 6. Assemble result
    assign dequant_fp16 = zero            ? 16'h0000 :
                          exp_overflow    ? {q_off[4] ^ s_sign, 5'd31, 10'd0} : // inf
                          exp_underflow   ? 16'h0000 :                          // flush to zero
                          {(q_off[4] ^ s_sign), r_exp[4:0], r_man};
endmodule
