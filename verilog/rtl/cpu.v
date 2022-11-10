module cpu (
`ifdef USE_POWER_PINS
  vccd1,
  vssd1,
`endif
  clkin,
  addr,
  datain,
  dataout,
  en_inp,
  en_out,
  rdwr,
  en,
  rst,
  keyboard,
  display
);

`ifdef USE_POWER_PINS
  inout vccd1; // User area 1 1.8V power
  inout vssd1; // User area 1 digital ground
`endif

  input [15:0] datain;
  output [15:0] dataout;
  output [11:0] addr;
  input clkin, en_inp, rst;
  output en, rdwr, en_out;
  input [7:0] keyboard;
  output [7:0] display;

  reg e, ac0,ac15;
  reg [15:0] ir, ac, dr;
  reg [11:0] pc, addr;
  reg [10:0] t;
  wire [7:0] d;
  wire rstEn, rstT;
  wire rdwr, en, clk;


  assign clk = clkin || (!ir[15] && d[7] && t[3] && ir[0]);
  assign dataout = (t[4] && d[3]) ? ac : 16'hzzzz;
  assign dataout = (t[4] && d[5]) ? {4'h0, pc} : 16'hzzzz;
  assign dataout = (t[6] && d[6]) ? dr : 16'hzzzz;

  assign en_out =   t[3] && d[7] && ir[10] && ir[15];
  assign display = en_out ? ac[7:0] : display;

  DECODER decode2 (
    .d(d),
    .a(ir[14:12]),
    .e(1'b1)
  );

  assign rstT =  rst || (t[4] && d[7] && !ir[6] && !ir[7]) || (!ir[15] && ((t[4] && d[4]) || (t[5] && d[3]))) || (t[5] && d[7] && (ir[6] || ir[7])) || (ir[15] && t[7] && d[4]) || (!ir[15] && t[7] && (d[0] || d[1] || d[2] || d[5])) || (t[7] && d[3]) || (t[9] && (d[0] || d[1] || d[2])) || (t[10] && d[6]);
  always @(posedge clk or posedge rstT) begin
    if (rstT) begin
      t <= 1;
    end else begin
      t <= t << 1;
    end
  end

  assign en =  (t[1] || (t[6] && !d[7] && ir[15]) || (t[4] && (d[0] || d[1] || d[2] || d[3] || d[5] || d[6])) || (ir[15] && t[4] && d[4]) || (t[6] && d[6]));
  assign rdwr =  (!ir[15] && t[4] && (d[3] || d[5])) || (!ir[15] && t[6] && d[6]) || (ir[15] && t[8] && d[6]);
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      pc <= 0;
    end else if ( t[0] ||
                 (t[6] && d[5]) ||
                 (!ir[15] && t[7] && d[6] && !dr) ||
                 (t[9] && d[6] && ir[15] && !dr) ||
	         (t[3] && d[7] && ((ir[15] && ((ir[8] && en_out) ||
		                               (ir[9] && en_inp))) ||
		                   (!ir[15] && ((ir[1] && !e) ||
				                (ir[2] && !ac) ||
					        (ir[3] && ac[15]) ||
					        (ir[4] && !ac[15]))))))
    begin
      pc <= pc + 1;
    end else if ((t[4] && d[4]) || (t[5] && d[5]) || (ir[15] && t[6] && d[4])) begin
      pc <= addr;
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      ir <= 0;
    end else if (!rdwr && t[2]) begin
      ir <= datain;
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      dr <= 0;
    end else if (!rdwr && ((!d[5] && t[5]) || (t[7] && ir[15]))) begin
      dr <= datain;
    end else if ((!ir[15] && t[6] && d[6]) || (ir[15] && t[8] && d[6])) begin
      dr <= dr + 1;
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      addr <= 0;
    end else if (t[0]) begin
      addr <= pc;
    end else if (t[3]) begin
      addr <= ir[11:0];
    end else if (!rdwr && (t[5] && ir[15])) begin
      addr <= datain;
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      e <= 0;
      ac <= 0;
      ac0 <= 0;
      ac15 <= 0;
    end else if (t[3]) begin
      if (d[7]) begin
////////////////////////*  input/output instructions  */////////////////////////
        if (ir[15]) begin
          if (ir[11] && en_inp) begin
            ac[7:0] <= keyboard;
          end
            
////////////////////*  REGISTER REFERENCE INSTRUCTIONS  *///////////////////////
        end else begin
          if (ir[5]) ac <= ac + 1;
          if (ir[6]) begin
	    ac15 <= ac[15];
            ac <= ac << 1;
            ac[0] <= e;
            //e <= ac15;
          end
          if (ir[7]) begin
	    ac0 <= ac[0];
            ac <= ac >> 1;
            ac[15] <= e;
            //e <= ac0;
          end
          if (ir[8]) e <= ~e;
          if (ir[9]) ac <= ~ac;
          if (ir[10]) e <= 0;
          if (ir[11]) ac <= 0;
        end
      end
    end else if (t[4]) begin
      if (d[7]) begin
        if (!ir[15]) begin
          if (ir[6]) begin
            e <= ac15;
          end
          if (ir[7]) begin
            e <= ac0;
          end
        end
      end
    end else if (t[8] || (!ir[15] && t[6])) begin
      if (d[0]) begin
        ac <= (ac & dr);
      end
      if (d[1]) begin
        {e, ac} <= ac + dr;
      end
      if (d[2]) begin
        ac <= dr;
      end
    end
  end

endmodule

module DECODER (
  d,
  e,
  a
);
  input [2:0] a;
  input e;
  output [7:0] d;

  assign d[0] = ~a[2] & ~a[1] & ~a[0] & e;
  assign d[1] = ~a[2] & ~a[1] &  a[0] & e;
  assign d[2] = ~a[2] &  a[1] & ~a[0] & e;
  assign d[3] = ~a[2] &  a[1] &  a[0] & e;
  assign d[4] =  a[2] & ~a[1] & ~a[0] & e;
  assign d[5] =  a[2] & ~a[1] &  a[0] & e;
  assign d[6] =  a[2] &  a[1] & ~a[0] & e;
  assign d[7] =  a[2] &  a[1] &  a[0] & e;

endmodule
