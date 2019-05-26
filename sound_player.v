module sound_player(
  read_data, sound_enable_n,
  ANALOG_PORT,
);
  // parent module IO
  input [9:0] read_data;
  input sound_enable_n;

  // analog port IO
  output [9:0] ANALOG_PORT;

  assign ANALOG_PORT = !sound_enable_n ? read_data : 10'd0;
endmodule
