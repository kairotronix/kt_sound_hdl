//  Package: regPKG
//
package regPKG;
    //  Group: Parameters
    parameter REG_DATAWIDTH = 16;
    parameter NUM_REGS      = 16;
    parameter REG_ADDRWIDTH = $clog2(NUM_REGS);

    //  Group: Typedefs
    typedef logic [REG_DATAWIDTH-1:0]   reg_data_t;
    typedef logic [REG_ADDRWIDTH-1:0]   reg_addr_t;
    //  REG0:
    //  REG1:
    //  REG2:
    //  REG3:
    //  REG4:

endpackage: regPKG
