module chattering_remover(clk, reset_n, in, out);
  input clk, reset_n, in;
  output reg out;

  reg buffer;
  reg [15:0] counter;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) counter <= 0;
    else counter <= counter + 1;
  end

  always @(posedge clk) begin
    if (counter == 0) begin
      out <= buffer;
      buffer <= in;
    end
  end
endmodule
