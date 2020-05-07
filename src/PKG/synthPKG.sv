//  Package: synthPKG
//
package synthPKG;
    //  Group: Parameters
    parameter   BITDEPTH = 24;
    parameter   DATA_MAXVAL = 1<<(BITDEPTH-4);
    parameter   DATA_MINVAL = -(1<<(BITDEPTH-4));
    parameter   F_MAX = 20_000;
    parameter   F_MIN = int'((sysPKG::CLK_FREQ / (1<<BITDEPTH)));
    //  Group: Typedefs
    typedef logic signed [BITDEPTH-1:0] synth_sig;

endpackage  : synthPKG
