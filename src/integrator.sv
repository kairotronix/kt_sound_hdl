//  Module: integrator
//
module integrator
#(
    parameter CLK_FREQ = sysPKG::CLK_FREQ
)(
    input logic                 clk_in,
    input logic                 reset_n,
    input logic                 enable,
    input regPKG::reg_data_t      freq_in,
    input synthPKG::synth_sig   sig_in,
    output synthPKG::synth_sig  sig_out
);
localparam ACCUM_INITVAL = synthPKG::DATA_MAXVAL;

localparam DIV_VAL = CLK_FREQ >>> 10;


typedef logic signed [synthPKG::BITDEPTH*10:0] int_sig;

int_sig accum0, accum1, accum2, sig;
synthPKG::synth_sig buff0, buff1, buff2;
logic   en_reg;

assign sig_out = (enable) ? synthPKG::synth_sig'(sig) : sig_in;

always_ff @(posedge clk_in, negedge reset_n)
begin
    if(reset_n == '0)
    begin
        accum0  <=  '0;
        accum1  <=  '0;
        accum2  <=  '0;
        sig     <=  '0;
        en_reg  <=  '0;
        buff0   <=  '0;
        buff1   <=  '0;
        buff2   <=  '0;
    end
    else
    begin
        en_reg  <=  enable;
        if(enable)
        begin
            if(en_reg == '0)
            begin
                //  Set an initial value (may change in the future?)
                accum2  <=  ACCUM_INITVAL;
            end
            else
            begin
                //  Do this in a pipeline.
                accum0  <= int_sig'(sig_in / DIV_VAL);
                accum1  <= accum0 + accum1;
                accum2  <= accum1 <<< 7;
                sig     <= (accum2);// - int_sig'(buff2);
                buff0   <= sig_in;
                buff1   <= buff0;
                buff2   <= buff1;

                // accum2 is the current raw integrated output
                // buff2 is the original signal
                // find phase difference between the two...how?
            end
        end
        else
        begin
            accum0 <= '0;
            accum1 <= '0;
            accum2 <= '0;
        end
    end
end

endmodule: integrator
