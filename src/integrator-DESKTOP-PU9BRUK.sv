//  Module: integrator
//
module integrator
#(
    parameter CLK_FREQ = sysPKG::CLK_FREQ
)(
    input logic                 clk_in,
    input logic                 reset_n,
    input logic                 enable,
    input regPKG::reg_data_t    freq_in,
    input synthPKG::synth_sig   sig_in,
    output synthPKG::synth_sig  sig_out
);
localparam ACCUM_INITVAL = 0;//synthPKG::DATA_MAXVAL;

typedef logic signed [synthPKG::BITDEPTH*2:0] int_sig;

synthPKG::synth_sig sig_reg;
typedef logic signed [regPKG::REG_DATAWIDTH:0] signed_reg;
int_sig accum0, accum1, accum2;
logic   en_reg;

assign sig_out = (enable) ? synthPKG::synth_sig'(accum2) : sig_in;

always_ff @(posedge clk_in, negedge reset_n)
begin
    if(reset_n == '0)
    begin
        accum0  <=  '0;
        accum1  <=  '0;
        accum2  <=  '0;
        en_reg  <=  '0;
        sig_reg <=  '0;
    end
    else
    begin
        en_reg  <=  enable;
        if(enable)
        begin
            sig_reg <=  sig_in;
            if(en_reg == '0)
            begin
                //  Set an initial value (may change in the future?)
                accum2  <=  sig_in;
                accum0  <=  '0;
                accum1  <=  '0;
            end
            else
            begin
                //  Do this in a pipeline.
                accum0  <=  (sig_reg + sig_in);// * synthPKG::synth_sig'(freq_in);
                accum1  <=  (accum0) / signed_reg'(freq_in);
                accum2 <= int_sig'(accum2 - accum1);
            end
        end
        else
        begin
            sig_reg <=  '0;
            accum0 <= '0;
            accum1 <= '0;
            accum2 <= '0;
        end
    end
end

endmodule: integrator
