`timescale 1ns / 1ps
module testbench;

localparam NUM_TESTS = 1;

localparam TEST_1 = "Oscillator Test";
localparam NUM_PERIODS      =   5;
localparam CLK_TICKS_20HZ   =   int'(sysPKG::CLK_FREQ / 20.0);
localparam CLK_TICKS_100HZ  =   int'(sysPKG::CLK_FREQ / 100.0);
localparam CLK_TICKS_1KHZ   =   int'(sysPKG::CLK_FREQ / 1000.0);
localparam CLK_TICKS_10KHZ  =   int'(sysPKG::CLK_FREQ / 10000.0);
localparam CLK_TICKS_20KHZ  =   int'(sysPKG::CLK_FREQ / 20000.0);
localparam TICK_FREQ_CTR_SIZE = $clog2(CLK_TICKS_20HZ * NUM_PERIODS);

localparam TEST_2 = "ADSR Envelope Test";
//  TODO: Parameters for ADSR envelope generation

localparam TEST_3 = "Mixer Test";
//  TODO: Parameters for sound mixer

localparam TEST_4 = "Register File Test";
//  TODO: Parameters for register file test

localparam TEST_5 = "MIDI Test";
//  TODO: Paramters for MIDI (maybe a midiPKG as well...)

/*
    Will I make actual test matricies and check data for pass/fail?
    --> What denotes a success?
*/
/*
logic clock, reset_n, enable;
real freq_real;
logic [5:0] ctr;
logic [TICK_FREQ_CTR_SIZE : 0] tick_freq_ctr;
synthPKG::synth_sig triangle, square, sin;
regPKG::reg_data_t freq_ctrl;


typedef enum
{
    S_INIT,
    S_READ,
    S_REFRESH,
    S_OSC_TEST,     //  TESTNO 1
    S_ADSR_TEST,    //  TESTNO 2
    S_MIX_TEST,     //  TESTNO 3
    S_REG_TEST,     //  TESTNO 4
    S_MIDI_TEST     //  TESTNO 5
} test_state_t;

typedef enum
{
    S_TEST_20HZ,
    S_TEST_100HZ,
    S_TEST_1KHZ,
    S_TEST_10KHZ,
    S_TEST_20KHZ
} osc_test_state_t;

//  Clock generation

initial
begin
    clock = 0;
    tick_freq_ctr = 0;
    reset_n = 1;
    #5
    reset_n = 0;
    #5
    reset_n = 1;
end

always #20 clock = ~clock;

//  TODO: MAKE FSM FOR TESTING

always_ff @(posedge clock, negedge reset_n)
begin
    if(reset_n == '0)
    begin
        enable      <= '0;
        freq_ctrl   <= '0;
        ctr         <= '0;
    end
    else
    begin
        if(ctr < 500)
        begin
            ctr     <=  ctr + 1'b1;
            freq_ctrl <=  16'd2500; //  random freq, 10 kHz
            freq_real <= real'(sysPKG::CLK_FREQ) / real'(freq_ctrl);
            enable  <= '1;
        end
    end
end
*/

logic clock, reset_n, test_enable;
int ctr;
logic spi_clk_in, spi_clk, spi_MOSI, spi_MISO, spi_nCS;
logic [7:0] spi_word_in;
logic [7:0] spi_word_out;
int spi_ctr;
logic enable;
int word_ctr;

byte spi_word [300:0];
logic [7:0] spi_read;

initial
begin
    for(int i = 0; i < $size(spi_word); i++)
    begin
        spi_word[i] = byte'(i);
    end
    spi_clk = 0;
    clock = 0;
    reset_n = 1;
    #5
    reset_n = 0;
    #5
    reset_n = 1;
end

always #20 clock = ~clock;
always #108 spi_clk = ~spi_clk;


assign spi_clk_in = (spi_nCS) ? '0 : spi_clk;

always_ff@(posedge spi_clk, negedge reset_n)
begin
    if(reset_n == '0)
    begin
        enable <= '0;
        spi_MOSI <= 'X;
        spi_ctr <= '0;
        spi_nCS <= '1;
        word_ctr <= '0;
        spi_word_out    <=  '0;
    end
    else
    begin
        enable <= test_enable;
        if(enable)
        begin
            if((spi_ctr <= 7) && (word_ctr <= 300))
            begin
                spi_nCS <=  '0;
                spi_ctr <= spi_ctr + 1'b1;
                spi_MOSI <= spi_word[word_ctr][7-spi_ctr];
            end
            else if(spi_ctr > 7)
            begin
                word_ctr <= word_ctr + 1'b1;
                spi_ctr <= '0;
                spi_word_out <= spi_word[word_ctr];
            end
            else
            begin
                spi_MOSI <= 'X;
                spi_nCS  <=  '1;
            end
        end
    end
end
always_ff @(negedge spi_clk, negedge reset_n)
begin
    if(reset_n == '0)
    begin
        spi_read    <=  '0;
    end
    else
    begin
        spi_read <= {spi_read[6:0], spi_MISO};
    end
end

always_ff @(posedge clock, negedge reset_n)
begin
    if(reset_n == '0)
    begin
        test_enable <=  '0;
        ctr <=  '0;
    end
    else
    begin
        if(ctr >= 10)
        begin
            test_enable <= '1;
        end
        else
        begin
            ctr <= ctr + 1'b1;
        end
    end
end

spi_slave_dataxceive dut
(
    .clk_in(clock),
    .reset_n(reset_n),
    .spi_clk(spi_clk_in),
    .spi_MOSI(spi_MOSI),
    .spi_MISO(spi_MISO),
    .spi_nCS(spi_nCS),
    .spi_word_in(spi_word_in),
    .spi_word_out(spi_word_out)
);
endmodule : testbench