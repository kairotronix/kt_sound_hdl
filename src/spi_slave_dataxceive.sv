//
//  COMPANY:    Kairotronix
//  Author:     Justin Wilson
//  Date:       2020/05/05
//
//  Duplication of this code is allowed with written recognition of the source
//      in the comments of the code if made public or on the product page if
//      the code is made closed source.
//
//  Module Name: spi_slave_dataxceive
//  Module inputs:
//                  clk_in              :   Input clock
//                  reset_n             :   Input reset (falling edge)
//                  spi_clk             :   SPI input clock (polarity determiend 
//                                              by CPOL)
//                  spi_MOSI            :   SPI master out slave in
//                  spi_nCS             :   SPI chip select (enables SPI module)
//                  spi_word_out        :   Word from master
//  Module outputs:
//                  spi_MISO            :   SPI master out slave in
//                  spi_word_in         :   Word to master
//  Parameterized inputs:
//                  CLK_FREQ            :   Determines master clock frequency. Unused.
//                                              default value: 50_000_000
//                  SPI_WORDLEN         :   Word length for SPI words.
//                                              default value: 8 (1 byte)
//                  CPOL                :   Clock polarity. See ASCII art below.
//                                              default value: 1'b0
//                  CPHA                :   Clock phase. See ASCII art below.
//                                              default value: 1'b1
//                  CSPOL               :   Chip/Slave select polarity. Active hi/lo
//                                              default value: 1'b0 (active low)
//                  MAX_SPI_XACTIONS    :   Maximum number of transactions on the SPI bus
//                                              default value: 256
//
//  Module Description:
//      SPI Slave parameterized module data serializer/deserializer unit
//          Sends and receives data to/from a master controller. Synchronized to a master
//          clock to prevent crossing clock boundaries. SPI behavior is defined by parameters
//          for clock phase, polarity, and chip select active high/low. Desired word length can
//          be changed as needed and maximum number of transactions before the unit deactivates
//          can also be set.
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
//  REVISION TABLE:
//  +------------+-----+--------------------------------------------------------+
//  | YYYY/MM/DD | INI | NOTE                                                   |
//  +------------+-----+--------------------------------------------------------+
//  | 2020/05/05 | JDW | File created                                           |
//  +------------+-----+--------------------------------------------------------+
//
module spi_slave_dataxceive
#(
    parameter   CLK_FREQ    =       50_000_000,
    parameter   SPI_WORDLEN =       8,
    parameter   CPOL        =       1'b0,
    parameter   CPHA        =       1'b1,
    parameter   CSPOL       =       1'b0,
    parameter   MAX_SPI_XACTIONS =  256
)(
    input logic                     clk_in,
    input logic                     reset_n,
    input logic                     spi_clk,
    input logic                     spi_MOSI,
    output logic                    spi_MISO,
    input logic                     spi_nCS,
    input logic[SPI_WORDLEN-1:0]    spi_word_out,
    output logic[SPI_WORDLEN-1:0]   spi_word_in
);

localparam  XACTION_CTR_SIZ =   $clog2(MAX_SPI_XACTIONS);
localparam  BIT_CTR_SIZ     =   $clog2(SPI_WORDLEN);

//  Localized types
typedef logic [BIT_CTR_SIZ:0]     bit_ctr_t;
typedef logic [XACTION_CTR_SIZ:0] xaction_ctr_t;

//  Signals for logical operations
logic cs_reg, clk_reg;
logic clk_rising, clk_falling;
logic xaction_lim;
//  Enable signal for the SPI module
logic enable;
//  Counter for bits per transaction
bit_ctr_t bit_ctr;
//  Counter for words (transactions)
xaction_ctr_t xaction_ctr;
//  Register for data read from the SPI master
logic [SPI_WORDLEN-1:0] mosi_word;
logic [SPI_WORDLEN-1:0] miso_word;
logic word_latch;

//  SPI Subsystem enable and clk edge detect logic
always_ff @(posedge clk_in, negedge reset_n)
begin
    if(reset_n == '0)
    begin
        //  Known values on system reset
        cs_reg      <=  '0;
        clk_reg     <=  '0;
        clk_rising  <=  '0;
        clk_falling <=  '0;
        enable      <=  '0;
    end
    else
    begin
        //  Register the clocks for edge detection
        cs_reg      <=  spi_nCS;
        clk_reg     <=  spi_clk;
        //  Calculate falling/rising edge of clock
        clk_rising  <=  ~clk_reg & spi_clk;
        clk_falling <=  clk_reg & ~spi_clk;

        if(cs_reg & ~spi_nCS)       //  Falling edge
        begin
            enable  <=  ~CSPOL;     //  Falling edge if CS polarity is 0 set to 1, and vice versa
        end
        else if(~cs_reg & spi_nCS)  //  Rising edge
        begin
            enable  <=  CSPOL;      //  Rising edge, if CS polarity is 1 set to 0, and vice versa
        end
        
    end
end

//  SPI  word capture/send
always_ff @(posedge clk_in, negedge reset_n)
begin
    if(reset_n == '0)
    begin
        //  Known values on system reset
        spi_MISO    <=  '0;
        mosi_word   <=  '0;
        bit_ctr     <=  '0;
        xaction_ctr <=  '0;
        xaction_lim <=  '0;
        miso_word   <=  '0;
        spi_word_in <=  '0;
        word_latch  <=  '0;
    end
    else 
    begin
        //  Register the word to be written
        miso_word   <=  spi_word_out;
        if(word_latch)
        begin
            spi_word_in <=  mosi_word;
            word_latch  <=  '0;
        end
        //  If CS is high reset any previous limits from the last transaction
        if(~enable)
        begin
            xaction_lim <= '0;
            word_latch  <= '0;
        end
        //  SPI slave enabled
        if(enable & ~xaction_lim)
        begin
            //  Input data on rising or falling edge depdning on CPOL and CPHA
            if(
                (clk_falling & ((CPOL & ~CPHA) | (~CPOL & CPHA))) |
                (clk_rising  & ((CPOL & CPHA) | (~CPOL & ~CPHA)))
            )
            begin
                //  input shift register to shift in bit-by-bit
                mosi_word       <= {mosi_word[SPI_WORDLEN-2:0],spi_MOSI};
                if(bit_ctr < SPI_WORDLEN)
                begin
                    bit_ctr     <= bit_ctr + 1'b1;
                    if(bit_ctr == SPI_WORDLEN-1)
                        word_latch  <=  '1;
                    else
                        word_latch  <=  '0;
                end
                else
                begin
                    bit_ctr     <=  '0;
                    spi_word_in    <=  mosi_word;
                    xaction_ctr <= xaction_ctr + 1'b1;
                    //  If the transaction limit is reach disable the SPI bus.
                    if(xaction_ctr >= MAX_SPI_XACTIONS)
                    begin
                        xaction_lim <= '1;
                    end
                end
            end
            //  Output on rising or falling depending on CPOL and CPHA
            if(
                (clk_falling & ((CPOL & CPHA) | (~CPOL & ~CPHA))) |
                (clk_rising  & ((CPOL & ~CPHA) | (~CPOL & CPHA)))
            )
            begin
                //  Write out word to master bit-by-bit
                if(bit_ctr == SPI_WORDLEN)
                    spi_MISO    <= miso_word[SPI_WORDLEN-1];
                else
                    spi_MISO    <= miso_word[SPI_WORDLEN - 1 - bit_ctr];
            end
        end
        else
        begin
            //  Reset to known values on module disable.
            spi_MISO    <=  '0;
            mosi_word   <=  '0;
            bit_ctr     <=  '0;
            xaction_ctr <=  '0;
        end
    end
end
endmodule : spi_slave_dataxceive