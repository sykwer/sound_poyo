module sound_recorder(
  clk, reset_n_clk, record_n, read_pointer,
  read_data, write_pointer,
  BUSY, AD7673_DATA, CNVST_N,
);
  parameter SOUND_SAMPLING_RATE = 44100; // 44.1KHz
  parameter SAMPLING_DURATION = 10; // 10sec
  parameter MEMORY_SIZE = SOUND_SAMPLING_RATE * SAMPLING_DURATION;

  // occilator: 125M clk/sec
  // sound sampling rate: 44.1KHz
  // 125M / 44.1K = 3000
  parameter SAMPLE_INTERVAL_CLK = 3000;

  // parent module IO
  input clk;
  input reset_n_clk;
  input record_n;
  input [18:0] read_pointer;
  output [9:0] read_data;
  output reg [18:0] write_pointer;

  // AD7673 IO
  input BUSY; // active when AD converting in progress
  input [17:0] AD7673_DATA; // AD converted data
  output reg CNVST_N; // activate negatively when start converting

  reg [9:0] memory [0:MEMORY_SIZE-1];
  reg [31:0] sampling_counter;

  // negedge BUSY : signal of finished conversion
  always @(posedge clk or negedge reset_n_clk or negedge BUSY) begin
    if (clk) begin // explicit syncronous circuit description is needed
      if (!reset_n_clk) begin
        CNVST_N <= 1;
        write_pointer <= 0;
        sampling_counter <= 0;
      end
      else if (!BUSY && !CNVST_N) begin
        CNVST_N <= 1;

        if (write_pointer < MEMORY_SIZE) begin
          memory[write_pointer] <= AD7673_DATA[9:0];
          write_pointer <= write_pointer + 1;
        end
      end
      else if (!record_n) begin
        if (sampling_counter >= SAMPLE_INTERVAL_CLK && !BUSY) begin
          sampling_counter <= 0;
          CNVST_N <= 0; // start converting by CNVST_N negedge
        end
        else if (sampling_counter < SAMPLE_INTERVAL_CLK) begin
          sampling_counter <= sampling_counter + 1;
        end
      end
    end
  end

  assign read_data = (read_pointer < write_pointer) ? memory[read_pointer] : 10'bZ;
endmodule
