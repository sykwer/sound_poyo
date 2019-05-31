module sound_poyo(
           clk, reset_n_btn, play_n_btn, record_n_btn, high,
           BUSY, AD7673_DATA, CNVST_N, RESET, PD, RD,
           ANALOG_PORT, clk2dac,
           led, // for debug
       );
parameter SAMPLE_INTERVAL_CLK = 6000;

input clk;
input reset_n_btn;
input play_n_btn;
input record_n_btn;
output high;

// AD7673 IO
input BUSY;
input [17:0] AD7673_DATA;
output CNVST_N;
output RESET;
output PD;
output RD;

// analog port IO
output [9:0] ANALOG_PORT;
output clk2dac;

reg [14:0] read_pointer;
reg [31:0] sampling_counter;
reg play_mode_n;

// outputs from chattering removers
wire reset_n_clk;
wire play_n_clk;
wire record_n_clk;

// outputs from sound recorder
wire [9:0] read_data;
wire [14:0] write_pointer;

// for debug
wire [7:0] sr2led;
output [7:0] led;
assign led[4:0] = sr2led[4:0];
assign led[5] = play_mode_n;
assign led[7:6] = write_pointer[14:13];

chattering_remover cr1(clk, 1'b1, reset_n_btn, reset_n_clk);
chattering_remover cr2(clk, 1'b1, play_n_btn, play_n_clk);
chattering_remover cr3(clk, 1'b1, record_n_btn, record_n_clk);

sound_recorder sr(
                   clk, reset_n_clk, record_n_clk || !play_mode_n, read_pointer,
                   read_data, write_pointer,
                   BUSY, AD7673_DATA, CNVST_N, RESET, PD, RD,
                   sr2led, // for debug
               );

sound_player sp(
                 read_data, play_mode_n || !(read_pointer < write_pointer),
                 ANALOG_PORT,
                 clk, reset_n_clk, // for debug
             );

always @(posedge clk or negedge reset_n_clk) begin
    if (!reset_n_clk) begin
        play_mode_n <= 1;
        read_pointer <= 0;
        sampling_counter <= 0;
    end
    else begin
        if (!play_n_clk) begin
            play_mode_n <= 0;
            read_pointer <= 0;
            sampling_counter <= 0;
        end
        else if (!play_mode_n) begin
            if (sampling_counter < SAMPLE_INTERVAL_CLK) begin
                sampling_counter <= sampling_counter + 1;
            end
            else begin
                sampling_counter <= 0;

                if (read_pointer < write_pointer - 1) begin
                    read_pointer <= read_pointer + 1;
                end
                else begin
                    play_mode_n <= 1;
                    read_pointer <= 0;
                end
            end
        end
    end
end

assign high = 1;
assign clk2dac= clk;
endmodule
