module sound_recorder(
           clk, reset_n_clk, record_n, read_pointer,
           read_data, write_pointer,
           BUSY, AD7673_DATA, CNVST_N, RESET, PD, RD,
           led, // for debug
       );
// parameter SOUND_SAMPLING_RATE = 44100; // 44.1KHz
// parameter SAMPLING_DURATION = 10; // 10sec
parameter MEMORY_SIZE = 32768;

// occilator: 125M clk/sec
// sound sampling rate: 44.1KHz
// 125M / 44.1K = 3000
parameter SAMPLE_INTERVAL_CLK = 6000;

parameter NEUTRAL_MODE = 0;
parameter WAIT_STARTUP_MODE = 1;
parameter WAIT_CONVERSION_MODE = 2;
parameter WRITE_MEMORY_MODE = 3;

// occilator = 8ns/clk, negedge-posedge duration of CNVST_N = 23-70ns
parameter WAIT_STARTUP_CLK = 5;

// parent module IO
input clk;
input reset_n_clk;
input record_n;
input [14:0] read_pointer;
output [9:0] read_data;
output reg [14:0] write_pointer;

// AD7673 IO
input BUSY; // active when AD converting in progress
input [17:0] AD7673_DATA; // AD converted data
output reg CNVST_N; // activate negatively when start converting
output RESET; // reset ADC when high
output PD; // power down when high
output RD; // read bus enabled when CS and RD are both low

reg [31:0] sampling_counter;
reg write_enable_n;
reg reset_write_enable_n;
reg [1:0] adc_control_mode;
reg [2:0] wait_startup_clk_cnt;

wire [14:0] addr2mem;
wire [9:0] mem2out;
wire [9:0] data2mem;

// AD7673_DATA[17:8]
memory memory(addr2mem, clk, data2mem, !write_enable_n, mem2out);

// for debug
output [7:0] led;
assign led[0] = BUSY;
assign led[1] = CNVST_N;
assign led[2] = write_enable_n;
assign led[3] = record_n;
assign led[4] = reset_n_clk;
assign led[5] = 0;
assign led[6] = 0;
assign led[7] = 0;

always @(posedge clk or negedge reset_n_clk) begin
    if (!reset_n_clk) begin
        CNVST_N <= 1;
        write_pointer <= 0;
        sampling_counter <= 0;
        write_enable_n <= 1;
        reset_write_enable_n <= 1;
        adc_control_mode <= NEUTRAL_MODE;
        wait_startup_clk_cnt <= 0;
    end
    else begin
        if (adc_control_mode == NEUTRAL_MODE) begin
            if (!record_n && sampling_counter >= SAMPLE_INTERVAL_CLK) begin
                CNVST_N <= 0;
                sampling_counter <= 0;
                wait_startup_clk_cnt <= 0;
                adc_control_mode <= WAIT_STARTUP_MODE;
            end
        end
        else if (adc_control_mode == WAIT_STARTUP_MODE) begin
            if (wait_startup_clk_cnt <= WAIT_STARTUP_CLK) begin
                wait_startup_clk_cnt <= wait_startup_clk_cnt + 1;
            end
            else begin
                CNVST_N <= 1;
                adc_control_mode <= WAIT_CONVERSION_MODE;
            end
        end
        else if (adc_control_mode == WAIT_CONVERSION_MODE) begin
            if (!BUSY) begin
                write_enable_n <= 0;
                reset_write_enable_n <= 1;
                adc_control_mode <= WRITE_MEMORY_MODE;
            end
        end
        else if (adc_control_mode == WRITE_MEMORY_MODE) begin
            if (!reset_write_enable_n) begin
                write_enable_n <= 1;

                if (write_pointer < MEMORY_SIZE - 1) begin
                    write_pointer <= write_pointer + 1;
                end

                adc_control_mode <= NEUTRAL_MODE;
            end
            else begin
                reset_write_enable_n <= 0;
            end
        end

        if (!record_n && sampling_counter <= SAMPLE_INTERVAL_CLK) begin
            sampling_counter <= sampling_counter + 1;
        end
    end
end

assign read_data = (read_pointer < write_pointer) ? mem2out : 10'bZ;
assign addr2mem = !write_enable_n ? write_pointer : read_pointer;
assign data2mem = AD7673_DATA[17:8];
assign RESET = 0;
assign PD = 0;
assign RD = 0;
endmodule
