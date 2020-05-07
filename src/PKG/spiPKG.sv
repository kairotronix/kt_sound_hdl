//
//  COMPANY:    Kairotronix
//  Author:     Justin Wilson
//  Date:       2020/05/05
//
//  Duplication of this code is allowed with written recognition of the source
//      in the comments of the code if made public or on the product page if
//      the code is made closed source.
//
//  Package Name: spiPKG
//
//  Description:
//      Contains parameters, constants, and types needed for SPI transactions
//
package spiPKG;

    parameter   CMD_WIDTH       =   8;
    parameter   READ_CMD        =   8'h00;
    parameter   WRITE_CMD       =   8'h40;
    parameter   READMULT_CMD    =   8'h80;
    parameter   WRITEMULT_CMD   =   8'hC0;
    paramter    CMD_BITMASK     =   8'hC0;
    parameter   MAX_SPI_XACTIONS=   256;  

    parameter   CPOL = 1'b0;
    parameter   CPHA = 1'b1;
//                    ___     ___     ___     ___
//      CPOL = 0  ___|   |___|   |___|   |___|   |___
//                ___     ___     ___     ___     ___
//      CPOL = 1     |___|   |___|   |___|   |___|
//                   .   .   .   .   .   .   .   .
//                   .   .   .   .   .   .   .   .
//                   .   .   .   .   .   .   .   .
//                ___.___.___.___.___.___.___.___.
//      CPHA = 0 |___1___|___2___|___3___|___4___|
//                   .   .   .   .   .   .   .   .
//                   .___.___.___.___.___.___.___.___
//      CPHA = 1     |___1___|___2___|___3___|___4___|
//                   .   .   .   .   .   .   .   .
//                   .   .   .   .   .   .   .   . 

    typedef enum logic[2:0] 
    {
        SPI_MODE_NULL = 0,
        SPI_MODE_READ,
        SPI_MODE_WRITE,
        SPI_MODE_READMULT,
        SPI_MODE_WRITEMULT
    } spi_mode_t;

endpackage: spiPKG