//  Module: sound_chip
//
module sound_chip
(
    //  PORTS
    input logic CLK_IN,
    input logic RESET_N,
    input logic EN,
    input regPKG::reg_data_t FREQ_IN,
    output synthPKG::synth_sig TRI_OUT,
    output synthPKG::synth_sig SQ_OUT,
    output synthPKG::synth_sig SIN_OUT
);

synthPKG::synth_sig square_wave, tri_wave, sin_wave;
logic en_int0, en_int1;
assign TRI_OUT = tri_wave;
assign SQ_OUT = square_wave;
assign SIN_OUT = sin_wave;

always_ff @(posedge CLK_IN, negedge RESET_N)
begin
    if(RESET_N == '0)
    begin
        en_int0 <= '0;
        en_int1 <= '0;
    end
    else
    begin
        if((EN == '1) && (en_int0 == '0))
        begin
            en_int0 <= '1;
        end

        if((en_int0 == '1) && (en_int1 == '0))
        begin
            en_int1 <= '1;
        end
    end
end

square_gen square_wave_generator
(
    .clk_in(CLK_IN),
    .reset_n(RESET_N),
    .enable(EN),
    .freq_in(FREQ_IN),
    .square_out(square_wave)
);

integrator triangle_wave_generator
(
    .clk_in(CLK_IN),
    .reset_n(RESET_N),
    .enable(en_int0),
    .freq_in(FREQ_IN),
    .sig_in(square_wave),
    .sig_out(tri_wave)
);

integrator sine_wave_generator
(
    .clk_in(CLK_IN),
    .reset_n(RESET_N),
    .enable(en_int1),
    .freq_in(FREQ_IN),
    .sig_in(tri_wave),
    .sig_out(sin_wave)
);


endmodule: sound_chip
