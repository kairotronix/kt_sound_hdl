//  Module: square_gen
//
module square_gen
#(
    CLK_FREQ = sysPKG::CLK_FREQ
)(
    input logic                 clk_in,
    input logic                 reset_n,
    input logic                 enable,
    input regPKG::reg_data_t      freq_in,
    output synthPKG::synth_sig  square_out
);
import synthPKG::*;
localparam max_ctr = CLK_FREQ / F_MIN;
localparam ctr_size = $clog2(max_ctr);

logic [ctr_size:0]  freq_ctr;
logic               en_reg;

always_ff @(posedge clk_in, negedge reset_n)
begin
    if(reset_n == '0)
    begin
        square_out  <=  '0;
        freq_ctr    <=  '0;
        en_reg      <=  '0;
    end
    else
    begin
        en_reg      <=  enable;
        if(enable)
        begin
            if(en_reg == '0)
            begin
                square_out  <=  DATA_MINVAL;
                freq_ctr    <=  freq_ctr + 1'b1;
            end
            else if(freq_ctr >= freq_in)
            begin
                //  If the value is the maximum (or 0) go to the minimum
                square_out  <=  -square_out;
                //  Reset the counter
                freq_ctr    <= '0;
            end
            else
            begin
                freq_ctr    <=  freq_ctr + 1'b1;
            end
        end
        else
        begin
            square_out  <=  '0;
        end
    end
end

endmodule: square_gen
