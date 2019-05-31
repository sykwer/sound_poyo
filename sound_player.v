module sound_player(
  read_data, sound_enable_n,
  ANALOG_PORT,
  clk, reset_n_clk, // for debug
);
  // parent module IO
  input [9:0] read_data;
  input sound_enable_n;

  // analog port IO
  output [9:0] ANALOG_PORT;

  // for debug;
  input clk;
  input reset_n_clk;

  reg [9:0] out;
  reg [31:0] cnt;

  always @(posedge clk or negedge reset_n_clk) begin
    if (!reset_n_clk) begin
	    out <= 0;
		  cnt <= 0;
	  end
	  else begin
	    if (cnt >= 125000) begin
		    cnt <= 0;
		    out <= out + 1;
		  end
		  else begin
		    cnt <= cnt + 1;
		  end
	  end
  end

  // assign ANALOG_PORT = !sound_enable_n ? read_data : 10'd0;
  assign ANALOG_PORT = out;
endmodule
