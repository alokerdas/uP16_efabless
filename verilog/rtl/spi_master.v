module spi_master (
  reset,
  clock_in,
  load,
  unload,
  datain,
  dataout,
  sclk,
  miso,
  mosi,
  ssn
);

  input reset, clock_in, miso, load, unload;
  input [7:0] datain;
  output [7:0] dataout;
  output sclk, mosi, ssn;

  wire int_clk;
  reg [7:0] datareg, dataout;
  reg [2:0] cntreg;

  assign mosi = datareg[7];
  assign ssn = |cntreg;

  always @(posedge clock_in or posedge reset) begin
    if (reset) begin
      datareg  <= 8'h00;
    end else if (load) begin
      datareg <= datain;
    end else if (unload) begin
      dataout <= datareg;
    end else begin
      datareg <= datareg << 1;
      datareg[0] <= miso;
    end
  end

  always @(posedge clock_in or posedge reset) begin
    if (reset) begin
      cntreg  <= 3'h0;
    end else if (ssn || load) begin
      cntreg  <= cntreg + 1;
    end
  end

endmodule
