/*
 * cpelib.v
 *
 * Gate level description of a CPE using a set of simplified library elements
 * for post-implementation simulation with back annotated timings.
 *
 * Copyright (C) 2023 Cologne Chip AG <support@colognechip.com>
 *
 * Revision history:
 *   2023-02-21 - Added C_D, C_DST and C_DRS initial values.
 *   2023-02-13 - Fixed CADD_{A,S} in C_ADDFx.
 *   2022-12-02 - Added CC_IO_SEL module.
 *   2022-11-01 - C_D, C_DST, C_DRS revision.
 *   2022-08-29 - C_MULT, C_AND and C_OR revision.
 *   2022-06-01 - Initial version.
 */

`timescale 1 ps / 1 ps

`define xUSE_PLL
`define xUSE_RAM
`define xUSE_TIMING
`define xUSE_TIMINGCHECKS

module CPE_IBF #(
	parameter [71:0] BUF_CFG = 72'b0
)(
	input  I,
	output Y
);
	assign Y = I;

`ifdef USE_TIMING
	specify
		(I => Y) = 0;
	endspecify
`endif
endmodule


module CPE_OBF #(
	parameter [71:0] BUF_CFG = 72'b0
)(
	input  A,
	output O
);
	assign O = A;

`ifdef USE_TIMING
	specify
		(A => O) = 0;
	endspecify
`endif
endmodule


module CPE_IOBF #(
	parameter [71:0] BUF_CFG = 72'b0
)(
	input  A, EN,
	output Y,
	inout  O
);
	assign O = EN ? A : 1'bz;
	assign Y = O;

`ifdef USE_TIMING
	specify
		(A  => O) = 0;
		(EN => O) = 0;
		(A  => Y) = 0;
		(EN => Y) = 0;
		(O  => Y) = 0;
	endspecify
`endif
endmodule


module CPE_LVDS_IBF #(
	parameter [71:0] BUF_CFG = 72'b0
)(
	input  I, IB,
	output Y
);

	assign Y = I;

`ifdef USE_TIMING
	specify
		(I => Y) = 0;
		(IB => Y) = 0;
	endspecify
`endif
endmodule


module CPE_LVDS_OBF #(
	parameter [71:0] BUF_CFG = 72'b0
)(
	input  A,
	output O, OB
);

	assign O = A;
	assign OB = ~A;

`ifdef USE_TIMING
	specify
		(A => O) = 0;
		(A => OB) = 0;
	endspecify
`endif
endmodule


module CC_IO_SEL #(
	parameter [71:0] IO_SEL_CFG = 72'b0
)(
	output IN1_O, IN2_O,
	output GPIO_OUT,
	input  CLOCK1, CLOCK2, CLOCK3, CLOCK4,
	input  OUT1_I, OUT2_I, OUT3_I, OUT4_I,
	input  GPIO_IN, GPIO_EN,
	input  RESET, // does not exist
	input  DDR_I
);
	reg q0_o = 1'bx;
	reg q1_o = 1'bx;
	reg q2_o = 1'bx;
	reg q3_o = 1'bx;

	assign q0_i = IO_SEL_CFG[9]  ? OUT4_I : OUT1_I;
	assign q1_i = IO_SEL_CFG[10] ? OUT3_I : OUT2_I;
	assign q2_i = GPIO_IN;
	assign q3_i = GPIO_IN;

	assign q0mx_o = IO_SEL_CFG[20] ? q0_o : q0_i;
	assign q1mx_o = IO_SEL_CFG[21] ? q1_o : q1_i;

	assign OMUX_SEL = (IO_SEL_CFG[13] & ~IO_SEL_CFG[12]) ? DDR_I : IO_SEL_CFG[11];
	assign GPIO_OUT = IO_SEL_CFG[8] ? (OMUX_SEL ? q1mx_o : q0mx_o) : (OMUX_SEL ? 1'b1 : 1'b0);

	assign clk_o = IO_SEL_CFG[25] ? (IO_SEL_CFG[24] ? CLOCK4 : CLOCK3) : (IO_SEL_CFG[24] ? CLOCK2 : CLOCK1);
	assign clk_i = IO_SEL_CFG[29] ? (IO_SEL_CFG[28] ? CLOCK4 : CLOCK3) : (IO_SEL_CFG[28] ? CLOCK2 : CLOCK1);

	assign q0clk = IO_SEL_CFG[26] ^ clk_o;
	assign q1clk = IO_SEL_CFG[27] ^ clk_o;
	assign q2clk = IO_SEL_CFG[30] ^ clk_i;
	assign q3clk = IO_SEL_CFG[31] ^ clk_i;

	assign IN1_O = IO_SEL_CFG[22] ? q2_o : q2_i;
	assign IN2_O = IO_SEL_CFG[23] ? q3_o : q3_i;

	always @(posedge q0clk)
	begin
		q0_o <= q0_i;
	end

	always @(posedge q1clk)
	begin
		q1_o <= q1_i;
	end

	always @(posedge q2clk)
	begin
		q2_o <= q2_i;
	end

	always @(posedge q3clk)
	begin
		q3_o <= q3_i;
	end

endmodule


module C_L2T4(
	output O,
	input I0, I1, I2, I3
);
	parameter [3:0] INIT_L00 = 4'b0000;
	parameter [3:0] INIT_L01 = 4'b0000;
	parameter [3:0] INIT_L10 = 4'b0000;

	wire [1:0] l00_s1 = I1 ? INIT_L00[3:2] : INIT_L00[1:0];
	wire l00 = I0 ? l00_s1[1] : l00_s1[0];

	wire [1:0] l01_s1 = I3 ? INIT_L01[3:2] : INIT_L01[1:0];
	wire l01 = I2 ? l01_s1[1] : l01_s1[0];

	wire [1:0] l10_s1 = l01 ? INIT_L10[3:2] : INIT_L10[1:0];
	assign O = l00 ? l10_s1[1] : l10_s1[0];

endmodule


module C_L2T5(
	output O,
	input I0, I1, I2, I3, I4
);
	parameter [3:0] INIT_L02 = 4'b0000;
	parameter [3:0] INIT_L03 = 4'b0000;
	parameter [3:0] INIT_L11 = 4'b0000;
	parameter [3:0] INIT_L20 = 4'b0000;

	wire [1:0] l02_s1 = I1 ? INIT_L02[3:2] : INIT_L02[1:0];
	wire l02 = I0 ? l02_s1[1] : l02_s1[0];

	wire [1:0] l03_s1 = I3 ? INIT_L03[3:2] : INIT_L03[1:0];
	wire l03 = I2 ? l03_s1[1] : l03_s1[0];

	wire [1:0] l11_s1 = l03 ? INIT_L11[3:2] : INIT_L11[1:0];
	wire l11 = l02 ? l11_s1[1] : l11_s1[0];

	wire [1:0] l20_s1 = l11 ? INIT_L20[3:2] : INIT_L20[1:0];
	assign O = I4 ? l20_s1[1] : l20_s1[0];

endmodule


module C_AND #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, COUTX, COUTY1,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	wire [8:0] cpe_i;

	assign cpe_i[1] = IN1;
	assign cpe_i[2] = CPE_CFG[0] ? PINY1 : IN2;
	assign cpe_i[3] = IN3;
	assign cpe_i[4] = CPE_CFG[1] ? CINX : IN4;
	assign cpe_i[5] = IN5;
	assign cpe_i[6] = CPE_CFG[2] ? PINY1 : IN6;
	assign cpe_i[7] = IN7;
	assign cpe_i[8] = CPE_CFG[3] ? PINX : IN8;

	assign CIN = CPE_CFG[6] ? CINX : CINY1; // C_HORIZ
	assign L10 = &cpe_i[4:1];
	assign L20 = (&cpe_i[6:5]) & (CPE_CFG[4] ? CINY1 : &cpe_i[8:7]); // handle C_EN_CIN
	assign LUT = (L10 & L20) ^ (CPE_CFG[5] & CIN);
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

`ifdef USE_TIMING
	specify
		(IN1   => OUT) = 0;
		(IN2   => OUT) = 0;
		(IN3   => OUT) = 0;
		(IN4   => OUT) = 0;
		(IN5   => OUT) = 0;
		(IN6   => OUT) = 0;
		(IN7   => OUT) = 0;
		(IN8   => OUT) = 0;
		(CINX  => OUT) = 0;
		(CINY1 => OUT) = 0;
		(PINX  => OUT) = 0;
		(PINY1 => OUT) = 0;
	endspecify
`endif
endmodule


module C_OR #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, COUTX, COUTY1,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	wire [8:0] cpe_i;

	assign cpe_i[1] = IN1;
	assign cpe_i[2] = CPE_CFG[0] ? PINY1 : IN2;
	assign cpe_i[3] = IN3;
	assign cpe_i[4] = CPE_CFG[1] ? CINX : IN4;
	assign cpe_i[5] = IN5;
	assign cpe_i[6] = CPE_CFG[2] ? PINY1 : IN6;
	assign cpe_i[7] = IN7;
	assign cpe_i[8] = CPE_CFG[3] ? PINX : IN8;

	assign L10 = |cpe_i[4:1];
	assign L20 = (|cpe_i[6:5]) | (CPE_CFG[4] ? CINY1 : |cpe_i[8:7]); // handle C_EN_CIN
	assign LUT = (L10 | L20);
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

`ifdef USE_TIMING
	specify
		(IN1   => OUT) = 0;
		(IN2   => OUT) = 0;
		(IN3   => OUT) = 0;
		(IN4   => OUT) = 0;
		(IN5   => OUT) = 0;
		(IN6   => OUT) = 0;
		(IN7   => OUT) = 0;
		(IN8   => OUT) = 0;
		(CINX  => OUT) = 0;
		(CINY1 => OUT) = 0;
		(PINX  => OUT) = 0;
		(PINY1 => OUT) = 0;
	endspecify
`endif
endmodule


module C_XOR #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, COUTX, COUTY1,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	wire [8:0] cpe_i;

	assign cpe_i[1] = IN1;
	assign cpe_i[2] = CPE_CFG[0] ? PINY1 : IN2;
	assign cpe_i[3] = IN3;
	assign cpe_i[4] = CPE_CFG[1] ? CINX : IN4;
	assign cpe_i[5] = IN5;
	assign cpe_i[6] = CPE_CFG[2] ? PINY1 : IN6;
	assign cpe_i[7] = IN7;
	assign cpe_i[8] = CPE_CFG[3] ? PINX : IN8;

	assign LUT = ^cpe_i[8:1];
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

`ifdef USE_TIMING
	specify
		(IN1   => OUT) = 0;
		(IN2   => OUT) = 0;
		(IN3   => OUT) = 0;
		(IN4   => OUT) = 0;
		(IN5   => OUT) = 0;
		(IN6   => OUT) = 0;
		(IN7   => OUT) = 0;
		(IN8   => OUT) = 0;
		(CINX  => OUT) = 0;
		(PINX  => OUT) = 0;
		(PINY1 => OUT) = 0;
	endspecify
`endif
endmodule


module C_ORAND #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, COUTX, COUTY1,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	wire [8:0] cpe_i;

	assign cpe_i[1] = IN1;
	assign cpe_i[2] = CPE_CFG[0] ? PINY1 : IN2;
	assign cpe_i[3] = IN3;
	assign cpe_i[4] = CPE_CFG[1] ? CINX : IN4;
	assign cpe_i[5] = IN5;
	assign cpe_i[6] = CPE_CFG[2] ? PINY1 : IN6;
	assign cpe_i[7] = IN7;
	assign cpe_i[8] = CPE_CFG[3] ? PINX : IN8;

	assign LUT = (|cpe_i[2:1]) & (|cpe_i[4:3]) & (|cpe_i[6:5]) & (|cpe_i[8:7]);
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

`ifdef USE_TIMING
	specify
		(IN1   => OUT) = 0;
		(IN2   => OUT) = 0;
		(IN3   => OUT) = 0;
		(IN4   => OUT) = 0;
		(IN5   => OUT) = 0;
		(IN6   => OUT) = 0;
		(IN7   => OUT) = 0;
		(IN8   => OUT) = 0;
		(CINX  => OUT) = 0;
		(PINX  => OUT) = 0;
		(PINY1 => OUT) = 0;
	endspecify
`endif
endmodule


module C_ANDXOR #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, COUTX, COUTY1,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	wire [8:0] cpe_i;

	assign cpe_i[1] = IN1;
	assign cpe_i[2] = CPE_CFG[0] ? PINY1 : IN2;
	assign cpe_i[3] = IN3;
	assign cpe_i[4] = CPE_CFG[1] ? CINX : IN4;
	assign cpe_i[5] = IN5;
	assign cpe_i[6] = CPE_CFG[2] ? PINY1 : IN6;
	assign cpe_i[7] = IN7;
	assign cpe_i[8] = CPE_CFG[3] ? PINX : IN8;

	assign LUT = (~&cpe_i[2:1]) ^ (~&cpe_i[4:3]) ^ (~&cpe_i[6:5]) ^ (~&cpe_i[8:7]);
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

`ifdef USE_TIMING
	specify
		(IN1   => OUT) = 0;
		(IN2   => OUT) = 0;
		(IN3   => OUT) = 0;
		(IN4   => OUT) = 0;
		(IN5   => OUT) = 0;
		(IN6   => OUT) = 0;
		(IN7   => OUT) = 0;
		(IN8   => OUT) = 0;
		(CINX  => OUT) = 0;
		(PINX  => OUT) = 0;
		(PINY1 => OUT) = 0;
	endspecify
`endif
endmodule


module C_ICOMP #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, COUTX, COUTY1,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	wire [8:0] cpe_i;

	assign cpe_i[1] = IN1;
	assign cpe_i[2] = CPE_CFG[0] ? PINY1 : IN2;
	assign cpe_i[3] = IN3;
	assign cpe_i[4] = CPE_CFG[1] ? CINX : IN4;
	assign cpe_i[5] = IN5;
	assign cpe_i[6] = CPE_CFG[2] ? PINY1 : IN6;
	assign cpe_i[7] = IN7;
	assign cpe_i[8] = CPE_CFG[3] ? PINX : IN8;

	assign LUT = (~^cpe_i[2:1]) & (~^cpe_i[4:3]) & (~^cpe_i[6:5]) & (~^cpe_i[8:7]);
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

`ifdef USE_TIMING
	specify
		(IN1   => OUT) = 0;
		(IN2   => OUT) = 0;
		(IN3   => OUT) = 0;
		(IN4   => OUT) = 0;
		(IN5   => OUT) = 0;
		(IN6   => OUT) = 0;
		(IN7   => OUT) = 0;
		(IN8   => OUT) = 0;
		(CINX  => OUT) = 0;
		(PINX  => OUT) = 0;
		(PINY1 => OUT) = 0;
	endspecify
`endif
endmodule


module C_C_OR #(
	parameter [6:0] CPE_CFG = 7'b0
)(
	output OUT, COUTY1, POUTY1,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	wire [8:0] cpe_i;

	assign cpe_i[1] = IN1;
	assign cpe_i[2] = CPE_CFG[0] ? PINY1 : IN2;
	assign cpe_i[3] = IN3;
	assign cpe_i[4] = CPE_CFG[1] ? CINX : IN4;
	assign cpe_i[5] = IN5;
	assign cpe_i[6] = CPE_CFG[2] ? PINY1 : IN6;

	assign COUTY1 = (|cpe_i[6:1]) | CINY1;
	assign POUTY1 = (|cpe_i[6:1]) | PINY1;

`ifdef USE_TIMING
	specify
		(IN1   => COUTY1) = 0;
		(IN2   => COUTY1) = 0;
		(IN3   => COUTY1) = 0;
		(IN4   => COUTY1) = 0;
		(IN5   => COUTY1) = 0;
		(IN6   => COUTY1) = 0;
		(IN7   => COUTY1) = 0;
		(IN8   => COUTY1) = 0;
		(CINX  => COUTY1) = 0;
		(CINY1 => COUTY1) = 0;
		(PINY1 => COUTY1) = 0;
		(IN1   => POUTY1) = 0;
		(IN2   => POUTY1) = 0;
		(IN3   => POUTY1) = 0;
		(IN4   => POUTY1) = 0;
		(IN5   => POUTY1) = 0;
		(IN6   => POUTY1) = 0;
		(IN7   => POUTY1) = 0;
		(IN8   => POUTY1) = 0;
		(CINX  => POUTY1) = 0;
		(PINY1 => POUTY1) = 0;
	endspecify
`endif
endmodule


module C_C_XOR #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, COUTY1, POUTY1,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	wire [8:0] cpe_i;

	assign cpe_i[1] = IN1;
	assign cpe_i[2] = CPE_CFG[0] ? PINY1 : IN2;
	assign cpe_i[3] = IN3;
	assign cpe_i[4] = CPE_CFG[1] ? CINX : IN4;
	assign cpe_i[5] = IN5;
	assign cpe_i[6] = CPE_CFG[2] ? PINY1 : IN6;
	assign cpe_i[7] = IN7;
	assign cpe_i[8] = CPE_CFG[3] ? PINX : IN8;

	//assign COUTY1 = (|cpe_i[6:1]) ^ CINY1;
	//assign POUTY1 = (|cpe_i[6:1]) ^ PINY1;
	assign LUT = (^cpe_i[8:1]) ^ CINY1;
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

`ifdef USE_TIMING
	specify
		(IN1   => OUT) = 0;
		(IN2   => OUT) = 0;
		(IN3   => OUT) = 0;
		(IN4   => OUT) = 0;
		(IN5   => OUT) = 0;
		(IN6   => OUT) = 0;
		(IN7   => OUT) = 0;
		(IN8   => OUT) = 0;
		(CINX  => OUT) = 0;
		(PINX  => OUT) = 0;
		(CINY1 => OUT) = 0;
		(PINY1 => OUT) = 0;
	endspecify
`endif
endmodule


module C_MX2a #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	wire s1 = (IN7 & IN8);
	wire s0 = (IN5 & IN6);

	assign LUT = s1 ? (s0 ? IN4 : IN3) : (s0 ? IN2 : IN1);
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

`ifdef USE_TIMING
	specify
		(IN1 => OUT) = 0;
		(IN2 => OUT) = 0;
		(IN3 => OUT) = 0;
		(IN4 => OUT) = 0;
		(IN5 => OUT) = 0;
		(IN6 => OUT) = 0;
		(IN7 => OUT) = 0;
		(IN8 => OUT) = 0;
	endspecify
`endif
endmodule


module C_MX2b #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	wire s0 = (IN1 & IN2);
	wire s1 = (IN3 & IN4);

	assign LUT = s1 ? (s0 ? IN8 : IN7) : (s0 ? IN6 : IN5);
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

`ifdef USE_TIMING
	specify
		(IN1 => OUT) = 0;
		(IN2 => OUT) = 0;
		(IN3 => OUT) = 0;
		(IN4 => OUT) = 0;
		(IN5 => OUT) = 0;
		(IN6 => OUT) = 0;
		(IN7 => OUT) = 0;
		(IN8 => OUT) = 0;
	endspecify
`endif
endmodule


module C_MX4a #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	wire s1 = (IN7 & IN8);
	wire s0 = (IN5 & IN6);

	assign LUT = s1 ? (s0 ? IN4 : IN3) : (s0 ? IN2 : IN1);
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

`ifdef USE_TIMING
	specify
		(IN1 => OUT) = 0;
		(IN2 => OUT) = 0;
		(IN3 => OUT) = 0;
		(IN4 => OUT) = 0;
		(IN5 => OUT) = 0;
		(IN6 => OUT) = 0;
		(IN7 => OUT) = 0;
		(IN8 => OUT) = 0;
	endspecify
`endif
endmodule


module C_MX4b #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	wire s0 = (IN1 & IN2);
	wire s1 = (IN3 & IN4);

	assign LUT = s1 ? (s0 ? IN8 : IN7) : (s0 ? IN6 : IN5);
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

`ifdef USE_TIMING
	specify
		(IN1 => OUT) = 0;
		(IN2 => OUT) = 0;
		(IN3 => OUT) = 0;
		(IN4 => OUT) = 0;
		(IN5 => OUT) = 0;
		(IN6 => OUT) = 0;
		(IN7 => OUT) = 0;
		(IN8 => OUT) = 0;
	endspecify
`endif
endmodule


module C_O_MUX (
	output COMP_OUT,
	input COMB1, COMB2
);

	assign COMP_OUT = COMB1;

`ifdef USE_TIMING
	specify
		(COMB1 => COMP_OUT) = 0;
	endspecify
`endif
endmodule


module C_O_OR2 (
	output COMP_OUT,
	input COMB1, COMB2
);

	assign COMP_OUT = COMB1 | COMB2;

`ifdef USE_TIMING
	specify
		(COMB1 => COMP_OUT) = 0;
		(COMB2 => COMP_OUT) = 0;
	endspecify
`endif
endmodule


module C_0 #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);

	assign OUT = 0;

endmodule


module C_1 #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);

	assign OUT = 1;

endmodule


module C_C_0_1 #(
	parameter [7:0] CPE_CFG = 8'b0
)(
	output OUT, COUTY1,
	input  CLK, EN, SR,
	input  CINY2, PINY2,
	input  RAM_I, CP_O, D_IN
);

	assign OUT = SR;

endmodule


module C_C_CAT #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, COUTY1,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);

	// COMB01
	assign OROUT = ~(~((IN1 & IN2) | (IN3 & IN4)) & ~(IN5 & IN6));
	assign L11 = IN7 & IN8;
	assign COMBOUT = IN7 & IN8;

	// COMB02
	assign CADD_S = L11;
	assign CADD_A = OROUT;

	// COMB03
	assign COUTY1 = CADD_S ? CADD_A : CINY1;

	// SEQ01
	assign OUT = COMBOUT;

endmodule


module C_ADDF #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, COUTX, COUTY1,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);

	wire [8:0] cpe_i;
	wire CIN, CADD_A, CADD_S;

	assign cpe_i[1] = IN1;
	assign cpe_i[2] = CPE_CFG[0] ? PINY1 : IN2;
	assign cpe_i[3] = IN3;
	assign cpe_i[4] = CPE_CFG[1] ? CINX : IN4;
	assign cpe_i[5] = IN5;
	assign cpe_i[6] = CPE_CFG[2] ? PINY1 : IN6;
	assign cpe_i[7] = IN7;
	assign cpe_i[8] = CPE_CFG[3] ? PINX : IN8;

	assign CIN = CPE_CFG[6] ? CINX : CINY1; // C_HORIZ
	assign LUT = (&cpe_i[2:1]) ^ (&cpe_i[4:3]) ^ (&cpe_i[6:5]) ^ (&cpe_i[8:7] ^ CIN);
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

	assign CADD_A = (&cpe_i[2:1]) | (&cpe_i[4:3]) | (&cpe_i[6:5]); // OR3
	assign CADD_S = (&cpe_i[2:1]) ^ (&cpe_i[4:3]) ^ (&cpe_i[6:5]) ^ (&cpe_i[8:7]);

	generate
		if (CPE_CFG[6]) begin
			assign COUTX = CADD_S ? CIN : CADD_A;
		end
		else begin
			assign COUTY1 = CADD_S ? CIN : CADD_A;
		end
	endgenerate

`ifdef USE_TIMING
	specify
		(IN1   => OUT) = 0;
		(IN2   => OUT) = 0;
		(IN3   => OUT) = 0;
		(IN4   => OUT) = 0;
		(IN5   => OUT) = 0;
		(IN6   => OUT) = 0;
		(IN7   => OUT) = 0;
		(IN8   => OUT) = 0;
		(CINY1 => OUT) = 0;
		(PINY1 => OUT) = 0;
		(CINX  => OUT) = 0;
		(PINX  => OUT) = 0;

		(IN1   => COUTY1) = 0;
		(IN2   => COUTY1) = 0;
		(IN3   => COUTY1) = 0;
		(IN4   => COUTY1) = 0;
		(IN5   => COUTY1) = 0;
		(IN6   => COUTY1) = 0;
		(IN7   => COUTY1) = 0;
		(IN8   => COUTY1) = 0;
		(CINY1 => COUTY1) = 0;
		(PINY1 => COUTY1) = 0;
		(CINX  => COUTY1) = 0;
		(PINX  => COUTY1) = 0;
	endspecify
`endif
endmodule


module C_ADDFx #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, COUTX, COUTY1,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);

	wire [8:0] cpe_i;
	wire CIN, CADD_A, CADD_S;

	assign cpe_i[1] = IN1;
	assign cpe_i[2] = CPE_CFG[0] ? PINY1 : IN2;
	assign cpe_i[3] = IN3;
	assign cpe_i[4] = CPE_CFG[1] ? CINX : IN4;
	assign cpe_i[5] = IN5;
	assign cpe_i[6] = CPE_CFG[2] ? PINY1 : IN6;
	assign cpe_i[7] = IN7;
	assign cpe_i[8] = CPE_CFG[3] ? PINX : IN8;

	assign CIN = CPE_CFG[6] ? CINX : CINY1; // C_HORIZ
	assign LUT = (^cpe_i[2:1]) ^ (^cpe_i[4:3]) ^ (^cpe_i[6:5]) ^ (^cpe_i[8:7] ^ CIN);
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

	assign CADD_A = (^cpe_i[2:1]) | (^cpe_i[4:3]) | (^cpe_i[6:5]); // OR3
	assign CADD_S = (^cpe_i[2:1]) ^ (^cpe_i[4:3]) ^ (^cpe_i[6:5]) ^ (^cpe_i[8:7]);

	generate
		if (CPE_CFG[6]) begin
			assign COUTX = CADD_S ? CIN : CADD_A;
		end
		else begin
			assign COUTY1 = CADD_S ? CIN : CADD_A;
		end
	endgenerate

`ifdef USE_TIMING
	specify
		(IN1   => OUT) = 0;
		(IN2   => OUT) = 0;
		(IN3   => OUT) = 0;
		(IN4   => OUT) = 0;
		(IN5   => OUT) = 0;
		(IN6   => OUT) = 0;
		(IN7   => OUT) = 0;
		(IN8   => OUT) = 0;
		(CINY1 => OUT) = 0;
		(PINY1 => OUT) = 0;
		(CINX  => OUT) = 0;
		(PINX  => OUT) = 0;

		(IN1   => COUTY1) = 0;
		(IN2   => COUTY1) = 0;
		(IN3   => COUTY1) = 0;
		(IN4   => COUTY1) = 0;
		(IN5   => COUTY1) = 0;
		(IN6   => COUTY1) = 0;
		(IN7   => COUTY1) = 0;
		(IN8   => COUTY1) = 0;
		(CINY1 => COUTY1) = 0;
		(PINY1 => COUTY1) = 0;
		(CINX  => COUTY1) = 0;
		(PINX  => COUTY1) = 0;
	endspecify
`endif
endmodule


module C_ADDF2 #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, COUTX, COUTY1,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);

	wire [8:1] cpe_i;
	wire CIN, C1;

	assign cpe_i[1] = IN1;
	assign cpe_i[2] = CPE_CFG[0] ? PINY1 : IN2;
	assign cpe_i[3] = IN3;
	assign cpe_i[4] = CPE_CFG[1] ? CINX : IN4;
	assign cpe_i[5] = IN5;
	assign cpe_i[6] = CPE_CFG[2] ? PINY1 : IN6;
	assign cpe_i[7] = IN7;
	assign cpe_i[8] = CPE_CFG[3] ? PINX : IN8;

	assign L10 = (&cpe_i[2:1]) ^ (&cpe_i[4:3]);
	assign L11 = (&cpe_i[6:5]) ^ (&cpe_i[8:7]);
	assign L02 =  &cpe_i[6:5];

	assign na2_1 = ~(~CIN & L11);
	assign na2_2 = ~(L02 & ~L11);
	assign na3_1 = ~(na2_1 & na2_1);

	assign na2_3 = ~(L10 & na3_1);
	assign or2_1 = (L10 | na3_1);
	assign COMB2OUT = ~(na2_3 & or2_1);
	assign COMB1OUT = CIN ^ L11; // CIN ? 0 : L11;

	assign CIN = CPE_CFG[6] ? CINX : CINY1; // C_HORIZ
	assign o2 = ~(L10 ^ (L11 ? ~CIN : ~L02));
	assign LUT = CPE_CFG[7] ? o2 : COMB1OUT;
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

	assign CADD_A = (L10) ? (&cpe_i[6:5]) : ((&cpe_i[2:1]) | (&cpe_i[4:3]));
	assign CADD_S = (L10) & (L11);

	generate
		if (CPE_CFG[6]) begin
			assign COUTX = CADD_S ? CIN : CADD_A;
		end
		else begin
			assign COUTY1 = CADD_S ? CIN : CADD_A;
		end
	endgenerate

`ifdef USE_TIMING
	specify
		(IN1   => OUT) = 0;
		(IN2   => OUT) = 0;
		(IN3   => OUT) = 0;
		(IN4   => OUT) = 0;
		(IN5   => OUT) = 0;
		(IN6   => OUT) = 0;
		(IN7   => OUT) = 0;
		(IN8   => OUT) = 0;
		(CINY1 => OUT) = 0;
		(PINY1 => OUT) = 0;
		(CINX  => OUT) = 0;
		(PINX  => OUT) = 0;

		(IN1   => COUTY1) = 0;
		(IN2   => COUTY1) = 0;
		(IN3   => COUTY1) = 0;
		(IN4   => COUTY1) = 0;
		(IN5   => COUTY1) = 0;
		(IN6   => COUTY1) = 0;
		(IN7   => COUTY1) = 0;
		(IN8   => COUTY1) = 0;
		(CINY1 => COUTY1) = 0;
		(PINY1 => COUTY1) = 0;
		(CINX  => COUTY1) = 0;
		(PINX  => COUTY1) = 0;
	endspecify
`endif
endmodule


module C_ADDF2x #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, COUTX, COUTY1,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);

	wire [8:1] cpe_i;
	wire CIN, C1;

	assign cpe_i[1] = IN1;
	assign cpe_i[2] = CPE_CFG[0] ? PINY1 : IN2;
	assign cpe_i[3] = IN3;
	assign cpe_i[4] = CPE_CFG[1] ? CINX : IN4;
	assign cpe_i[5] = IN5;
	assign cpe_i[6] = CPE_CFG[2] ? PINY1 : IN6;
	assign cpe_i[7] = IN7;
	assign cpe_i[8] = CPE_CFG[3] ? PINX : IN8;

	assign L10 = (^cpe_i[2:1]) ^ (^cpe_i[4:3]);
	assign L11 = (^cpe_i[6:5]) ^ (^cpe_i[8:7]);
	assign L02 =  ^cpe_i[6:5];

	assign na2_1 = ~(~CIN & L11);
	assign na2_2 = ~(L02 & ~L11);
	assign na3_1 = ~(na2_1 & na2_1);

	assign na2_3 = ~(L10 & na3_1);
	assign or2_1 = (L10 | na3_1);
	assign COMB2OUT = ~(na2_3 & or2_1);
	assign COMB1OUT = CIN ^ L11; // CIN ? 0 : L11;

	assign CIN = CPE_CFG[6] ? CINX : CINY1; // C_HORIZ
	assign o2 = ~(L10 ^ (L11 ? ~CIN : ~L02));
	assign LUT = CPE_CFG[7] ? o2 : COMB1OUT;
	assign OUT = CPE_CFG[8] ? ~LUT : LUT;

	assign CADD_A = (L10) ? (&cpe_i[6:5]) : ((&cpe_i[2:1]) | (&cpe_i[4:3]));
	assign CADD_S = (L10) & (L11);

	generate
		if (CPE_CFG[6]) begin
			assign COUTX = CADD_S ? CIN : CADD_A;
		end
		else begin
			assign COUTY1 = CADD_S ? CIN : CADD_A;
		end
	endgenerate

`ifdef USE_TIMING
	specify
		(IN1   => OUT) = 0;
		(IN2   => OUT) = 0;
		(IN3   => OUT) = 0;
		(IN4   => OUT) = 0;
		(IN5   => OUT) = 0;
		(IN6   => OUT) = 0;
		(IN7   => OUT) = 0;
		(IN8   => OUT) = 0;
		(CINY1 => OUT) = 0;
		(PINY1 => OUT) = 0;
		(CINX  => OUT) = 0;
		(PINX  => OUT) = 0;

		(IN1   => COUTX) = 0;
		(IN2   => COUTX) = 0;
		(IN3   => COUTX) = 0;
		(IN4   => COUTX) = 0;
		(IN5   => COUTX) = 0;
		(IN6   => COUTX) = 0;
		(IN7   => COUTX) = 0;
		(IN8   => COUTX) = 0;
		(CINY1 => COUTX) = 0;
		(PINY1 => COUTX) = 0;
		(CINX  => COUTX) = 0;
		(PINX  => COUTX) = 0;

		(IN1   => COUTY1) = 0;
		(IN2   => COUTY1) = 0;
		(IN3   => COUTY1) = 0;
		(IN4   => COUTY1) = 0;
		(IN5   => COUTY1) = 0;
		(IN6   => COUTY1) = 0;
		(IN7   => COUTY1) = 0;
		(IN8   => COUTY1) = 0;
		(CINY1 => COUTY1) = 0;
		(PINY1 => COUTY1) = 0;
		(CINX  => COUTY1) = 0;
		(PINX  => COUTY1) = 0;
	endspecify
`endif
endmodule


module C_Carry #(
	parameter [7:0] CPE_CFG = 8'b0
)(
	output OUT, RAM_O,
	input  CLK, EN, SR,
	input  CINY2, PINY2,
	input  RAM_I, CP_O, D_IN
);
	assign OUT = CP_O;

`ifdef USE_TIMING
	specify
		(CP_O => OUT) = 0;
	endspecify
`endif
endmodule


module C_MULT #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT1, OUT2,
	output COUTX, POUTX,
	output COUTY1, POUTY1,
	output COUTY2, POUTY2,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CLK, EN, SR,
	input  CINX, CINY1, CINY2,
	input  PINX, PINY1, PINY2,
	input  RAM_I1, RAM_I2
);

	wire [8:1] cpe_i;

	assign cpe_i[1] = IN1;
	assign cpe_i[2] = PINY1;
	assign cpe_i[4] = CINX;
	assign cpe_i[5] = IN5;
	assign cpe_i[6] = PINY1;
	assign cpe_i[8] = PINX;

	assign L10 = ~((&cpe_i[2:1]) ^ CINX);
	assign L11 = ~((&cpe_i[6:5]) ^ PINX);
	assign L02OUT = &cpe_i[6:5];
	assign NOROUT = ~((&cpe_i[2:1]) | CINX);

	// COMB02 ADDF2
	assign CADD_A = ((~NOROUT | ~L10) & ~(~L02OUT & ~L10));
	assign CADD_S = (~L10) & (~L11);
	assign ADDF2 = ~(~(~L11 & ~CINY1) & ~(~L02OUT & L11));

	// COMB02 MULT
	assign nand2_0 = ~(PINY2 & IN5);
	assign nand2_1 = ~(PINY2 & IN8);
	assign xnor3_0 = ~(nand2_0 ^ ~L10 ^ ~ADDF2);
	assign xnor3_1 = ~(nand2_1 ^ CINY1 ^ ~L11);
	assign mx2_0 = ~(( nand2_0 | xnor3_0) & (nand2_1 | ~xnor3_0));
	assign mx2_1 = ~((~nand2_1 | xnor3_1) & (CINY2 | ~xnor3_1));

	assign COY2_A = mx2_0;
	assign COY2_S = ~(~xnor3_0 | ~xnor3_1);
	assign MULTO1 = ~(xnor3_1 ^ ~CINY2);
	assign MULTO2 = ~(xnor3_0 ^ mx2_1);

	// COMB03
	assign COUTX  = MULTO2;
	assign COUTY1 = CADD_S ? CINY1 : CADD_A;
	assign COUTY2 = COY2_S ? CINY2 : COY2_A;
	assign OUT2   = COUTX;

	// COMB04
	assign POUTX  = MULTO1;
	assign POUTY1 = CPE_CFG[4] ? COUTX : PINY1;
	assign POUTY2 = PINY2;
	assign OUT1   = CPE_CFG[4] ? COUTX : POUTX;

`ifdef USE_TIMING
	specify
		(IN1   => OUT1) = 0;
		(IN3   => OUT1) = 0;
		(IN5   => OUT1) = 0;
		(IN7   => OUT1) = 0;
		(IN8   => OUT1) = 0;
		(CINY1 => OUT1) = 0;
		(CINY2 => OUT1) = 0;
		(PINY1 => OUT1) = 0;
		(PINY2 => OUT1) = 0;
		(CINX  => OUT1) = 0;
		(PINX  => OUT1) = 0;
		(IN1   => OUT2) = 0;
		(IN3   => OUT2) = 0;
		(IN5   => OUT2) = 0;
		(IN7   => OUT2) = 0;
		(IN8   => OUT2) = 0;
		(CINY1 => OUT2) = 0;
		(CINY2 => OUT2) = 0;
		(PINY1 => OUT2) = 0;
		(PINY2 => OUT2) = 0;
		(CINX  => OUT2) = 0;
		(PINX  => OUT2) = 0;
		(IN1   => COUTX) = 0;
		(IN3   => COUTX) = 0;
		(IN5   => COUTX) = 0;
		(IN7   => COUTX) = 0;
		(IN8   => COUTX) = 0;
		(CINY1 => COUTX) = 0;
		(CINY2 => COUTX) = 0;
		(PINY1 => COUTX) = 0;
		(PINY2 => COUTX) = 0;
		(CINX  => COUTX) = 0;
		(PINX  => COUTX) = 0;
		(IN1   => POUTX) = 0;
		(IN3   => POUTX) = 0;
		(IN5   => POUTX) = 0;
		(IN7   => POUTX) = 0;
		(IN8   => POUTX) = 0;
		(CINY1 => POUTX) = 0;
		(CINY2 => POUTX) = 0;
		(PINY1 => POUTX) = 0;
		(PINY2 => POUTX) = 0;
		(CINX  => POUTX) = 0;
		(PINX  => POUTX) = 0;
		(IN1   => COUTY1) = 0;
		(IN3   => COUTY1) = 0;
		(IN5   => COUTY1) = 0;
		(IN7   => COUTY1) = 0;
		(IN8   => COUTY1) = 0;
		(CINY1 => COUTY1) = 0;
		(CINY2 => COUTY1) = 0;
		(PINY1 => COUTY1) = 0;
		(PINY2 => COUTY1) = 0;
		(CINX  => COUTY1) = 0;
		(PINX  => COUTY1) = 0;
		(PINY1 => POUTY1) = 0;
		(IN1   => COUTY2) = 0;
		(IN3   => COUTY2) = 0;
		(IN5   => COUTY2) = 0;
		(IN7   => COUTY2) = 0;
		(IN8   => COUTY2) = 0;
		(CINY1 => COUTY2) = 0;
		(CINY2 => COUTY2) = 0;
		(PINY1 => COUTY2) = 0;
		(PINY2 => COUTY2) = 0;
		(CINX  => COUTY2) = 0;
		(PINX  => COUTY2) = 0;
		(PINY2 => POUTY2) = 0;
	endspecify
`endif
endmodule


module C_MULTFa #(
	parameter [7:0] CPE_CFG = 8'b0
)(
	output COUTX, POUTX,
	output COUTY1, POUTY1,
	output COUTY2,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CLK, EN, SR,
	input  CINX, CINY1, CINY2,
	input  PINX, PINY1, PINY2,
	input  RAM_I1, RAM_I2
);

	assign COUTY1 = PINY1 ^ CINX;
	assign COUTY2 = CINY2;
	assign COUTX  = CINY2;
	assign POUTY1 = CINY1 ^ (PINY1 & CINX);

`ifdef USE_TIMING
	specify
		(CINY2 => COUTX) = 0;
		(PINY1 => COUTY1) = 0;
		(CINX  => COUTY1) = 0;
		(CINY1 => POUTY1) = 0;
		(PINY1 => POUTY1) = 0;
		(CINX  => POUTY1) = 0;
		(CINY2 => COUTY2) = 0;
	endspecify
`endif
endmodule


module C_MULTFb #(
	parameter [7:0] CPE_CFG = 8'b0
)(
	output COUTX, POUTX,
	output COUTY1, POUTY1,
	output COUTY2, POUTY2,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CLK, EN, SR,
	input  CINX, CINY1, CINY2,
	input  PINX, PINY1, PINY2,
	input  RAM_I1, RAM_I2
);

	assign COUTY1 = PINY1 ^ CINX;
	assign COUTY2 = CINY2;
	assign COUTX  = CINY2;
	assign POUTY1 = CINY1 ^ (PINY1 | CINX);

`ifdef USE_TIMING
	specify
		(CINY2 => COUTX) = 0;
		(PINY1 => COUTY1) = 0;
		(CINX  => COUTY1) = 0;
		(CINY1 => POUTY1) = 0;
		(PINY1 => POUTY1) = 0;
		(CINX  => POUTY1) = 0;
		(CINY2 => COUTY2) = 0;
	endspecify
`endif
endmodule


module C_O_O1 #(
	parameter CPE_CFG = 0
)(
	output COMP_OUT,
	input  COMB1, COMB2
);
	assign COMP_OUT = COMB1;

`ifdef USE_TIMING
	specify
		(COMB1 => COMP_OUT) = 0;
	endspecify
`endif
endmodule


module C_O_O2 #(
	parameter CPE_CFG = 0
)(
	output COMP_OUT,
	input  COMB1, COMB2
);
	assign COMP_OUT = COMB2;

`ifdef USE_TIMING
	specify
		(COMB2 => COMP_OUT) = 0;
	endspecify
`endif
endmodule


module C_O_0 #(
	parameter CPE_CFG = 0
)(
	output COMP_OUT,
	input  COMB1, COMB2
);
	assign COMP_OUT = 1'b0;
endmodule


module C_D #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, RAM_O,
	input  CLK, EN, SR,
	input  CINY2, PINY2,
	input  RAM_I, CP_O, D_IN
);
	wire CP_i, EN_i, SR_i, D_i;
	reg  q_i = CPE_CFG[8];

	assign D_i  = D_IN;
	assign SR_i = ~SR; // reset
	assign CP_i = CPE_CFG[4] ? CINY2 : CLK; // C_CLKSEL
	assign EN_i  = CPE_CFG[5] ? PINY2 : EN;  // C_ENSEL

	assign OUT = q_i;
	assign RAM_O = CPE_CFG[7] ? RAM_I : q_i;

	always @(posedge CP_i or posedge SR_i)
	begin
		if (SR_i) begin
			q_i <= 1'b0;
		end
		else if (EN_i) begin
			q_i <= D_i;
		end
	end

`ifdef USE_TIMING
	reg notifier;
	specify
		(CLK => OUT) = 0;
`ifdef USE_TIMINGCHECKS
		$width(posedge CLK &&& EN, 0, 0, notifier);
		$width(negedge CLK &&& EN, 0, 0, notifier);
		$width(negedge SR, 0, 0, notifier);
		$recrem(posedge SR, posedge CLK, 0, 0, notifier,,, SR_i, CP_i);
		$setuphold(posedge CLK, posedge D_IN, 0, 0, notifier,,, CP_i, D_i);
		$setuphold(posedge CLK, negedge D_IN, 0, 0, notifier,,, CP_i, D_i);
		$setuphold(posedge CLK, posedge EN, 0, 0, notifier,,, CP_i, EN_i);
		$setuphold(posedge CLK, negedge EN, 0, 0, notifier,,, CP_i, EN_i);
`endif
	endspecify
`endif
endmodule


module C_DST #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, RAM_O,
	input  CLK, EN, SR,
	input  CINY2, PINY2,
	input  RAM_I, CP_O, D_IN
);
	wire CP_i, SR_i, D_i;
	reg  q_i = CPE_CFG[8];

	assign D_i  = D_IN;
	assign SR_i = ~SR; // set
	assign CP_i = CPE_CFG[4] ? CINY2 : CLK; // C_CLKSEL
	assign EN_i  = CPE_CFG[5] ? PINY2 : EN;  // C_ENSEL

	assign OUT = q_i;
	assign RAM_O = CPE_CFG[7] ? RAM_I : q_i;

	always @(posedge CP_i or posedge SR_i)
	begin
		if (SR_i) begin
			q_i <= 1'b1;
		end
		else if (EN_i) begin
			q_i <= D_i;
		end
	end

`ifdef USE_TIMING
	reg notifier;
	specify
		(CLK => OUT) = 0;
`ifdef USE_TIMINGCHECKS
		$width(posedge CLK &&& EN, 0, 0, notifier);
		$width(negedge CLK &&& EN, 0, 0, notifier);
		$width(negedge SR, 0, 0, notifier);
		$recrem(posedge SR, posedge CLK, 0, 0, notifier,,, SR_i, CP_i);
		$setuphold(posedge CLK, posedge D_IN, 0, 0, notifier,,, CP_i, D_i);
		$setuphold(posedge CLK, negedge D_IN, 0, 0, notifier,,, CP_i, D_i);
		$setuphold(posedge CLK, posedge EN, 0, 0, notifier,,, CP_i, EN_i);
`endif
	endspecify
`endif
endmodule


module C_DRS #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT, RAM_O,
	input  CLK, EN, SR, // EN is SET, SR is RST
	input  CINY2, PINY2,
	input  RAM_I, CP_O, D_IN
);
	wire CP_i, EN_i, SR_i, D_i;
	reg  q_i = CPE_CFG[9];

	assign D_i  = D_IN;
	assign SR_i = ~SR; // reset
	assign CP_i = CPE_CFG[4] ? CINY2 : CLK; // C_CLKSEL
	assign EN_i = CPE_CFG[5] ? PINY2 : EN;  // C_ENSEL // set

	assign OUT = q_i;
	assign RAM_O = CPE_CFG[7] ? RAM_I : q_i; // C_ENSEL

	always @(posedge CP_i or posedge SR_i or posedge EN_i)
	begin
		if (EN_i) begin
			q_i <= 1'b1;
		end
		else if (SR_i) begin
			q_i <= 1'b0;
		end
		else begin
			q_i <= D_i;
		end
	end

`ifdef USE_TIMING
	reg notifier;
	specify
		(CLK => OUT) = 0;
`ifdef USE_TIMINGCHECKS
		$width(posedge CLK &&& EN, 0, 0, notifier);
		$width(negedge CLK &&& EN, 0, 0, notifier);
		$width(negedge SR, 0, 0, notifier);
		$width(negedge EN, 0, 0, notifier);
		$recrem(posedge SR, posedge CLK, 0, 0, notifier,,, SR_i, CP_i);
		$recrem(posedge EN, posedge CLK, 0, 0, notifier,,, EN_i, CP_i);
		$setuphold(posedge CLK, posedge D_IN, 0, 0, notifier,,, CP_i, D_i);
		$setuphold(posedge CLK, negedge D_IN, 0, 0, notifier,,, CP_i, D_i);
		$setuphold(posedge CLK, posedge EN, 0, 0, notifier,,, CP_i, EN_i);
`endif
	endspecify
`endif
endmodule


module C_CPlines #(
	parameter [18:0] CPE_CFG = 19'b0
)(
	output RAM_O1, RAM_O2,
	output COUTX, POUTX,
	output COUTY1, POUTY1,
	output COUTY2, POUTY2,
	input  OUT1, OUT2, COMP_OUT,
	input  CINX, CINY1, CINY2,
	input  PINX, PINY1, PINY2,
	input  RAM_I1, RAM_I2
);

	// Decode
	wire C_SELX  = CPE_CFG[6];
	wire C_SELY1 = CPE_CFG[7];
	wire C_SELY2 = CPE_CFG[8];
	wire C_SEL_C = CPE_CFG[9];
	wire C_SEL_P = CPE_CFG[10];
	wire C_Y12   = CPE_CFG[11];
	wire C_CX_I  = CPE_CFG[12];
	wire C_CY1_I = CPE_CFG[13];
	wire C_CY2_I = CPE_CFG[14];
	wire C_PX_I  = CPE_CFG[15];
	wire C_PY1_I = CPE_CFG[16];
	wire C_PY2_I = CPE_CFG[17];

	wire CIY12 = C_Y12 ? CINY2 : CINY1;
	wire PIY12 = C_Y12 ? PINY2 : PINY1;

	wire CX_VAL  = C_SEL_C ? (C_SELX ? CIY12 : COMP_OUT) : (C_SELX  ? OUT2 : OUT1);
	wire PX_VAL  = C_SEL_P ? (C_SELX ? PIY12 : COMP_OUT) : (C_SELX  ? OUT1 : OUT2);
	wire CY1_VAL = C_SEL_C ? (C_SELY1 ? CINX : COMP_OUT) : (C_SELY1 ? OUT1 : OUT2);
	wire PY1_VAL = C_SEL_P ? (C_SELY1 ? PINX : COMP_OUT) : (C_SELY1 ? OUT2 : OUT1);
	wire CY2_VAL = C_SEL_C ? (C_SELY2 ? CINX : COMP_OUT) : (C_SELY2 ? OUT2 : OUT1);
	wire PY2_VAL = C_SEL_P ? (C_SELY2 ? PINX : COMP_OUT) : (C_SELY2 ? OUT1 : OUT2);

	assign RAM_O1 = OUT1;
	assign RAM_O2 = OUT2;
	assign COUTX  = C_CX_I  ? CX_VAL  : CINX;
	assign COUTY1 = C_CY1_I ? CY1_VAL : CINY1;
	assign COUTY2 = C_CY2_I ? CY2_VAL : CINY2;
	assign POUTX  = C_PX_I  ? PX_VAL  : PINX;
	assign POUTY1 = C_PY1_I ? PY1_VAL : PINY1;
	assign POUTY2 = C_PY2_I ? PY2_VAL : PINY2;

`ifdef USE_TIMING
	specify
		(OUT1  => RAM_O1) = 0;
		(OUT2  => RAM_O2) = 0;
		(CINX  => COUTX) = 0;
		(CINY1 => COUTX) = 0;
		(CINY2 => COUTX) = 0;
		(COMP_OUT  => COUTX) = 0;
		(OUT1  => COUTX) = 0;
		(OUT2  => COUTX) = 0;
		(CINX  => COUTY1) = 0;
		(CINY1 => COUTY1) = 0;
		(COMP_OUT  => COUTY1) = 0;
		(OUT1  => COUTY1) = 0;
		(OUT2  => COUTY1) = 0;
		(CINX  => COUTY2) = 0;
		(CINY2 => COUTY2) = 0;
		(COMP_OUT  => COUTY2) = 0;
		(OUT1  => COUTY2) = 0;
		(OUT2  => COUTY2) = 0;
		(PINX  => POUTX) = 0;
		(PINY1 => POUTX) = 0;
		(PINY2 => POUTX) = 0;
		(COMP_OUT  => POUTX) = 0;
		(OUT1  => POUTX) = 0;
		(OUT2  => POUTX) = 0;
		(PINX  => POUTY1) = 0;
		(PINY1 => POUTY1) = 0;
		(COMP_OUT  => POUTY1) = 0;
		(OUT1  => POUTY1) = 0;
		(OUT2  => POUTY1) = 0;
		(PINX  => POUTY2) = 0;
		(PINY2 => POUTY2) = 0;
		(COMP_OUT  => POUTY2) = 0;
		(OUT1  => POUTY2) = 0;
		(OUT2  => POUTY2) = 0;
	endspecify
`endif
endmodule


module C_Route1 #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	assign OUT = CPE_CFG[8] ? ~CINY1 : CINY1;

`ifdef USE_TIMING
	specify
		(CINY1 => OUT) = 0;
	endspecify
`endif
endmodule


module C_Route2 #(
	parameter [8:0] CPE_CFG = 9'b0
)(
	output OUT,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	assign OUT = CPE_CFG[8] ? ~CINY1 : CINY1;
endmodule


module C_CP_route #(
	parameter [6:0] CPE_CFG = 7'b0
)(
	output OUT,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8,
	input  CINX, CINY1,
	input  PINX, PINY1
);
	// blackbox
endmodule


module C_Bridge #(
	parameter [8:0] CPE_CFG = 8'b0
)(
	output OUT,
	input  IN1, IN2, IN3, IN4,
	input  IN5, IN6, IN7, IN8
);
	wire [8:0] cpe_i;

	assign cpe_i[1] = IN1;
	assign cpe_i[2] = IN2;
	assign cpe_i[3] = IN3;
	assign cpe_i[4] = IN4;
	assign cpe_i[5] = IN5;
	assign cpe_i[6] = IN6;
	assign cpe_i[7] = IN7;
	assign cpe_i[8] = IN8;

	assign OUT = |cpe_i[8:1];

`ifdef USE_TIMING
	specify
		(IN1 => OUT) = 0;
		(IN2 => OUT) = 0;
		(IN3 => OUT) = 0;
		(IN4 => OUT) = 0;
		(IN5 => OUT) = 0;
		(IN6 => OUT) = 0;
		(IN7 => OUT) = 0;
		(IN8 => OUT) = 0;
	endspecify
`endif
endmodule


module C_RAM_I1 #(
	parameter [8:0] CPE_CFG = 8'b0
)(
	output OUT, RAM_O,
	input  CLK, EN, SR,
	input  CINY2, PINY2,
	input  RAM_I, CP_O, D_IN
);
	assign OUT = RAM_I;
endmodule


module C_RAM_I2 #(
	parameter [8:0] CPE_CFG = 8'b0
)(
	output OUT, RAM_O,
	input  CLK, EN, SR,
	input  CINY2, PINY2,
	input  RAM_I, CP_O, D_IN
);
	assign OUT = RAM_I;
endmodule


`ifdef USE_PLL
module CC_PLL #(
	parameter PLL_CFG = 96'b0
)(
	input  CLK_REF, CLK_FEEDBACK, USR_CLK_REF,
	input  USR_LOCKED_STDY_RST, USR_SET_SEL,
	output USR_PLL_LOCKED_STDY, USR_PLL_LOCKED,
	output CLK270, CLK180, CLK90, CLK0, CLK_REF_OUT
);

	reg r_user_pll_locked_stdy;
	reg r_user_pll_locked;
	reg r_clk270;
	reg r_clk180;
	reg r_clk90;
	reg r_clk0;
	reg r_clk_ref_out;

	assign USR_PLL_LOCKED_STDY = r_user_pll_locked_stdy;
	assign USR_PLL_LOCKED      = r_user_pll_locked;
	assign CLK270              = r_clk270;
	assign CLK180              = r_clk180;
	assign CLK90               = r_clk90;
	assign CLK0                = r_clk0;
	assign CLK_REF_OUT         = CLK_REF | USR_CLK_REF;

	integer clkcnt = 0;
	initial begin
		$display ("%m PLL_CFG:%h", PLL_CFG);
		r_user_pll_locked_stdy = 1'b0;
		r_user_pll_locked = 1'b0;
		r_clk270 = 1'b0;
		r_clk180 = 1'b0;
		r_clk90 = 1'b0;
		r_clk0 = 1'b0;
	end

	always @(CLK_REF or USR_CLK_REF)
	begin
		if ((clkcnt > 1) && (clkcnt % 2 == 0)) begin
			r_clk0 = ~r_clk0;
		end
		if ((clkcnt > 2) && ((clkcnt-1) % 2 == 0)) begin
			r_clk90 = ~r_clk90;
		end
		if ((clkcnt > 3) && ((clkcnt-2) % 2 == 0)) begin
			r_clk180 = ~r_clk180;
		end
		if ((clkcnt > 4) && ((clkcnt-3) % 2 == 0)) begin
			r_clk270 = ~r_clk270;
		end
		clkcnt = clkcnt + 1;
	end
endmodule
`endif

module CLKIN #(
	parameter [31:0] CLKIN_CFG = 32'h0
)(
	output PCLK0, PCLK1, PCLK2, PCLK3,
	input  CLK0, CLK1, CLK2, CLK3,
	input  SER_CLK, SPI_CLK, JTAG_CLK
);

	assign {C4_7_NC, C4_6_NC, C4_5_NC, C4_4_NC, C4_3, C4_2, C4_1, C4_0} = CLKIN_CFG[31:24];
	assign {C3_7_NC, C3_6_NC, C3_5_NC, C3_4_NC, C3_3, C3_2, C3_1, C3_0} = CLKIN_CFG[23:16];
	assign {C2_7_NC, C2_6_NC, C2_5_NC, C2_4_NC, C2_3, C2_2, C2_1, C2_0} = CLKIN_CFG[15:8];
	assign {C1_7_NC, C1_6_NC, C1_5_NC, C1_4_NC, C1_3, C1_2, C1_1, C1_0} = CLKIN_CFG[7:0];

	assign CLK1MX = C1_2 ? (C1_1 ? (C1_0 ? 1'b0 : JTAG_CLK) : (C1_0 ? SPI_CLK : SER_CLK)) : (C1_1 ? (C1_0 ? CLK3 : CLK2) : (C1_0 ? CLK1 : CLK0));
	assign CLK2MX = C2_2 ? (C1_1 ? (C2_0 ? 1'b0 : JTAG_CLK) : (C2_0 ? SPI_CLK : SER_CLK)) : (C2_1 ? (C2_0 ? CLK3 : CLK2) : (C2_0 ? CLK1 : CLK0));
	assign CLK3MX = C3_2 ? (C1_1 ? (C3_0 ? 1'b0 : JTAG_CLK) : (C3_0 ? SPI_CLK : SER_CLK)) : (C3_1 ? (C3_0 ? CLK3 : CLK2) : (C3_0 ? CLK1 : CLK0));
	assign CLK4MX = C4_2 ? (C1_1 ? (C4_0 ? 1'b0 : JTAG_CLK) : (C4_0 ? SPI_CLK : SER_CLK)) : (C4_1 ? (C4_0 ? CLK3 : CLK2) : (C4_0 ? CLK1 : CLK0));

	assign PCLK0 = CLK1MX ^ C1_3;
	assign PCLK1 = CLK2MX ^ C2_3;
	assign PCLK2 = CLK3MX ^ C3_3;
	assign PCLK3 = CLK4MX ^ C3_3;

`ifdef USE_TIMING
	specify
		(CLK0 => PCLK0) = 0;
		(CLK0 => PCLK1) = 0;
		(CLK0 => PCLK2) = 0;
		(CLK0 => PCLK3) = 0;
		(CLK1 => PCLK0) = 0;
		(CLK1 => PCLK1) = 0;
		(CLK1 => PCLK2) = 0;
		(CLK1 => PCLK3) = 0;
		(CLK2 => PCLK0) = 0;
		(CLK2 => PCLK1) = 0;
		(CLK2 => PCLK2) = 0;
		(CLK2 => PCLK3) = 0;
		(CLK3 => PCLK0) = 0;
		(CLK3 => PCLK1) = 0;
		(CLK3 => PCLK2) = 0;
		(CLK3 => PCLK3) = 0;
		(JTAG_CLK => PCLK0) = 0;
		(JTAG_CLK => PCLK1) = 0;
		(JTAG_CLK => PCLK2) = 0;
		(JTAG_CLK => PCLK3) = 0;
		(SER_CLK => PCLK0) = 0;
		(SER_CLK => PCLK1) = 0;
		(SER_CLK => PCLK2) = 0;
		(SER_CLK => PCLK3) = 0;
		(SPI_CLK => PCLK0) = 0;
		(SPI_CLK => PCLK1) = 0;
		(SPI_CLK => PCLK2) = 0;
		(SPI_CLK => PCLK3) = 0;
	endspecify
`endif
endmodule


module GLBOUT #(
	parameter [63:0] GLBOUT_CFG = 64'h0
)(
	output GLB0, GLB1, GLB2, GLB3,
	output CLK_FB0, CLK_FB1, CLK_FB2, CLK_FB3,
	input  CLK0_0, CLK0_90, CLK0_180, CLK0_270, CLK0_BYP,
	input  CLK1_0, CLK1_90, CLK1_180, CLK1_270, CLK1_BYP,
	input  CLK2_0, CLK2_90, CLK2_180, CLK2_270, CLK2_BYP,
	input  CLK3_0, CLK3_90, CLK3_180, CLK3_270, CLK3_BYP,
	input  USR_GLB0, USR_GLB1, USR_GLB2, USR_GLB3,
	input  USR_FB0, USR_FB1, USR_FB2, USR_FB3
);
	assign {C_63,C_62,C_61,C_60,C_59,C_58,C_57,C_56} = GLBOUT_CFG[63:56];
	assign {C_55,C_54,C_53,C_52,C_51,C_50,C_49,C_48} = GLBOUT_CFG[55:48];
	assign {C_47,C_46,C_45,C_44,C_43,C_42,C_41,C_40} = GLBOUT_CFG[47:40];
	assign {C_39,C_38,C_37,C_36,C_35,C_34,C_33,C_32} = GLBOUT_CFG[39:32];
	assign {C_31,C_30,C_29,C_28,C_27,C_26,C_25,C_24} = GLBOUT_CFG[31:24];
	assign {C_23,C_22,C_21,C_20,C_19,C_18,C_17,C_16} = GLBOUT_CFG[23:16];
	assign {C_15,C_14,C_13,C_12,C_11,C_10, C_9, C_8} = GLBOUT_CFG[15: 8];
	assign { C_7, C_6, C_5, C_4, C_3, C_2, C_1, C_0} = GLBOUT_CFG[ 7: 0];

	assign CLK1MXO =  C_2 ? ( C_1 ? ( C_0 ? CLK0_270 : CLK0_180) : ( C_0 ? CLK0_90 : CLK0_0)) : ( C_1 ? ( C_0 ? CLK3_0 : CLK2_0) : ( C_0 ? CLK1_0 : CLK0_BYP));
	assign CLK2MXO = C_18 ? (C_17 ? (C_16 ? CLK1_270 : CLK1_180) : (C_16 ? CLK1_90 : CLK1_0)) : (C_17 ? (C_16 ? CLK3_0 : CLK2_0) : (C_16 ? CLK1_0 : CLK1_BYP));
	assign CLK3MXO = C_34 ? (C_33 ? (C_32 ? CLK2_270 : CLK2_180) : (C_32 ? CLK2_90 : CLK2_0)) : (C_33 ? (C_32 ? CLK3_0 : CLK2_0) : (C_32 ? CLK1_0 : CLK2_BYP));
	assign CLK4MXO = C_50 ? (C_49 ? (C_48 ? CLK3_270 : CLK3_180) : (C_48 ? CLK3_90 : CLK3_0)) : (C_49 ? (C_48 ? CLK3_0 : CLK2_0) : (C_48 ? CLK1_0 : CLK3_BYP));

	assign GLB0 =  C_4 ? ( C_3 ? USR_GLB0 : CLK1MXO) : 1'b0;
	assign GLB1 = C_20 ? (C_19 ? USR_GLB1 : CLK2MXO) : 1'b0;
	assign GLB2 = C_36 ? (C_35 ? USR_GLB2 : CLK3MXO) : 1'b0;
	assign GLB3 = C_52 ? (C_51 ? USR_GLB3 : CLK4MXO) : 1'b0;

	assign CLK1MXI =  C_9 ? ( C_8 ? GLB3 : GLB2) : ( C_8 ? GLB1 : GLB0);
	assign CLK2MXI = C_25 ? (C_24 ? GLB3 : GLB2) : (C_24 ? GLB1 : GLB0);
	assign CLK3MXI = C_41 ? (C_40 ? GLB3 : GLB2) : (C_40 ? GLB1 : GLB0);
	assign CLK4MXI = C_57 ? (C_56 ? GLB3 : GLB2) : (C_56 ? GLB1 : GLB0);

	assign CLK_FB0 = C_10 ? USR_FB0 : CLK1MXI;
	assign CLK_FB1 = C_26 ? USR_FB1 : CLK2MXI;
	assign CLK_FB2 = C_42 ? USR_FB2 : CLK3MXI;
	assign CLK_FB3 = C_58 ? USR_FB3 : CLK4MXI;

`ifdef USE_TIMING
	specify
		(CLK0_0 => GLB0) = 0;
		(CLK0_90 => GLB0) = 0;
		(CLK0_90 => GLB1) = 0;
		(CLK0_180 => GLB0) = 0;
		(CLK0_180 => GLB2) = 0;
		(CLK0_270 => GLB0) = 0;
		(CLK0_270 => GLB3) = 0;
		(CLK0_BYP => GLB0) = 0;
		(CLK1_0 => GLB0) = 0;
		(CLK1_0 => GLB1) = 0;
		(CLK1_90 => GLB1) = 0;
		(CLK1_180 => GLB1) = 0;
		(CLK1_180 => GLB2) = 0;
		(CLK1_270 => GLB1) = 0;
		(CLK1_270 => GLB3) = 0;
		(CLK1_BYP => GLB1) = 0;
		(CLK2_0 => GLB0) = 0;
		(CLK2_0 => GLB2) = 0;
		(CLK2_90 => GLB1) = 0;
		(CLK2_90 => GLB2) = 0;
		(CLK2_180 => GLB2) = 0;
		(CLK2_270 => GLB2) = 0;
		(CLK2_270 => GLB3) = 0;
		(CLK2_BYP => GLB2) = 0;
		(CLK3_0 => GLB0) = 0;
		(CLK3_0 => GLB3) = 0;
		(CLK3_90 => GLB1) = 0;
		(CLK3_90 => GLB3) = 0;
		(CLK3_180 => GLB2) = 0;
		(CLK3_180 => GLB3) = 0;
		(CLK3_270 => GLB3) = 0;
		(CLK3_BYP => GLB3) = 0;
		(USR_GLB0 => GLB0) = 0;
		(USR_GLB1 => GLB1) = 0;
		(USR_GLB2 => GLB2) = 0;
		(USR_GLB3 => GLB3) = 0;
		(USR_FB0 => CLK_FB0) = 0;
		(USR_FB1 => CLK_FB1) = 0;
		(USR_FB2 => CLK_FB2) = 0;
		(USR_FB3 => CLK_FB3) = 0;
	endspecify
`endif
endmodule

`ifdef USE_RAM
module FPGA_RAM  ( DOA, DOAX, DOB, DOBX,
	ECC1B_ERRA,
	ECC1B_ERRB,
	ECC2B_ERRA,
	ECC2B_ERRB,
	CLKA,
	CLKB,
	ENA,
	ENB,
	GLWEA,
	GLWEB,
	ADDRA0,
	ADDRA1,
	ADDRA0X,
	ADDRA1X,
	ADDRB0,
	ADDRB0X,
	ADDRB1,
	ADDRB1X,
	C_ADDRA,
	C_ADDRB,
	DIA,
	DIB,
	WEA,
	WEB,

	FORW_CAS_WRAO,
	FORW_CAS_WRBO,
	FORW_CAS_BMAO,
	FORW_CAS_BMBO,
	FORW_CAS_RDAO,
	FORW_CAS_RDBO,

	FORW_UADDRAO,
	FORW_LADDRAO,
	FORW_UADDRBO,
	FORW_LADDRBO,

	FORW_UA0CLKO, FORW_UA0ENO, FORW_UA0WEO, FORW_LA0CLKO, FORW_LA0ENO, FORW_LA0WEO,
	FORW_UA1CLKO, FORW_UA1ENO, FORW_UA1WEO, FORW_LA1CLKO, FORW_LA1ENO, FORW_LA1WEO,
	FORW_UB0CLKO, FORW_UB0ENO, FORW_UB0WEO, FORW_LB0CLKO, FORW_LB0ENO, FORW_LB0WEO,
	FORW_UB1CLKO, FORW_UB1ENO, FORW_UB1WEO, FORW_LB1CLKO, FORW_LB1ENO, FORW_LB1WEO,

	CLOCKA, CLOCKB,
	CLOCK1, CLOCK2, CLOCK3, CLOCK4,

	FORW_CAS_WRAI, FORW_CAS_WRBI, FORW_CAS_BMAI, FORW_CAS_BMBI,

	FORW_CAS_RDAI, FORW_CAS_RDBI,
	FORW_LADDRAI, FORW_UADDRAI, FORW_LADDRBI, FORW_UADDRBI,

	FORW_LA0CLKI, FORW_LA0ENI, FORW_LA0WEI, FORW_UA0CLKI, FORW_UA0ENI, FORW_UA0WEI,
	FORW_LA1CLKI, FORW_LA1ENI, FORW_LA1WEI, FORW_UA1CLKI, FORW_UA1ENI, FORW_UA1WEI,
	FORW_LB0CLKI, FORW_LB0ENI, FORW_LB0WEI, FORW_UB0CLKI, FORW_UB0ENI, FORW_UB0WEI,
	FORW_LB1CLKI, FORW_LB1ENI, FORW_LB1WEI, FORW_UB1CLKI, FORW_UB1ENI, FORW_UB1WEI
	);

	parameter RAM_CFG = 216'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;

	output[39:0] DOA, DOAX, DOB,DOBX;
	output [3:0] ECC1B_ERRA, ECC1B_ERRB, ECC2B_ERRA, ECC2B_ERRB;
	output FORW_CAS_WRAO, FORW_CAS_WRBO, FORW_CAS_BMAO, FORW_CAS_BMBO, FORW_CAS_RDAO, FORW_CAS_RDBO;
	output [15:0] FORW_UADDRAO, FORW_LADDRAO, FORW_UADDRBO, FORW_LADDRBO;
	output FORW_UA0CLKO, FORW_UA0ENO, FORW_UA0WEO, FORW_LA0CLKO, FORW_LA0ENO, FORW_LA0WEO;
	output FORW_UA1CLKO, FORW_UA1ENO, FORW_UA1WEO, FORW_LA1CLKO, FORW_LA1ENO, FORW_LA1WEO;
	output FORW_UB0CLKO, FORW_UB0ENO, FORW_UB0WEO, FORW_LB0CLKO, FORW_LB0ENO, FORW_LB0WEO;
	output FORW_UB1CLKO, FORW_UB1ENO, FORW_UB1WEO, FORW_LB1CLKO, FORW_LB1ENO, FORW_LB1WEO;

	output [3:0] CLOCKA;
	output [3:0] CLOCKB;

	input CLOCK1, CLOCK2, CLOCK3, CLOCK4;
	input FORW_CAS_WRAI, FORW_CAS_WRBI, FORW_CAS_BMAI, FORW_CAS_BMBI, FORW_CAS_RDAI, FORW_CAS_RDBI;
	input [15:0] FORW_LADDRAI, FORW_UADDRAI, FORW_LADDRBI, FORW_UADDRBI;

	input FORW_LA0CLKI, FORW_LA0ENI, FORW_LA0WEI, FORW_UA0CLKI, FORW_UA0ENI, FORW_UA0WEI;
	input FORW_LA1CLKI, FORW_LA1ENI, FORW_LA1WEI, FORW_UA1CLKI, FORW_UA1ENI, FORW_UA1WEI;
	input FORW_LB0CLKI, FORW_LB0ENI, FORW_LB0WEI, FORW_UB0CLKI, FORW_UB0ENI, FORW_UB0WEI;
	input FORW_LB1CLKI, FORW_LB1ENI, FORW_LB1WEI, FORW_UB1CLKI, FORW_UB1ENI, FORW_UB1WEI;

	input [3:0] CLKA,CLKB,ENA,ENB, GLWEA,GLWEB;
	input [15:0] ADDRA0,ADDRA1, ADDRA0X, ADDRA1X, ADDRB0,ADDRB1, ADDRB0X, ADDRB1X;
	input [39:0] DIA,DIB,WEA,WEB;
	input [7:0] C_ADDRA, C_ADDRB;

	assign a0_clk1_in = CLKA[0];
	assign a0_clk2_in = CLKA[1];
	assign a1_clk1_in = CLKA[2];
	assign a1_clk2_in = CLKA[3];

	assign b0_clk1_in = CLKB[0];
	assign b0_clk2_in = CLKB[1];
	assign b1_clk1_in = CLKB[2];
	assign b1_clk2_in = CLKB[3];

	// forward_up
	wire forward_up_a0_en_in, forward_up_a1_en_in, forward_up_b0_en_in, forward_up_b1_en_in;
	wire forward_up_a0_we_in, forward_up_a1_we_in, forward_up_b0_we_in, forward_up_b1_we_in;
	wire forward_up_a0_clk_in, forward_up_a1_clk_in, forward_up_b0_clk_in, forward_up_b1_clk_in;
	// EN
	assign forward_up_a0_en_in = FORW_UA0ENI;
	assign forward_up_a1_en_in = FORW_UA1ENI;
	assign forward_up_b0_en_in = FORW_UB0ENI;
	assign forward_up_b1_en_in = FORW_UB1ENI;
	// WE
	assign forward_up_a0_we_in = FORW_UA0WEI;
	assign forward_up_a1_we_in = FORW_UA1WEI;
	assign forward_up_b0_we_in = FORW_UB0WEI;
	assign forward_up_b1_we_in = FORW_UB1WEI;
	// CLK
	assign forward_up_a0_clk_in = FORW_UA0CLKI;
	assign forward_up_a1_clk_in = FORW_UA1CLKI;
	assign forward_up_b0_clk_in = FORW_UB0CLKI;
	assign forward_up_b1_clk_in = FORW_UB1CLKI;

	// forward_low
	wire forward_low_a0_en_in, forward_low_a1_en_in,forward_low_b0_en_in, forward_low_b1_en_in;
	wire forward_low_a0_we_in, forward_low_a1_we_in, forward_low_b0_we_in, forward_low_b1_we_in;
	wire forward_low_a0_clk_in, forward_low_a1_clk_in, forward_low_b0_clk_in, forward_low_b1_clk_in;
	// EN
	assign forward_low_a0_en_in = FORW_LA0ENI;
	assign forward_low_a1_en_in = FORW_LA1ENI;
	assign forward_low_b0_en_in = FORW_LB0ENI;
	assign forward_low_b1_en_in = FORW_LB1ENI;
	// WE
	assign forward_low_a0_we_in = FORW_LA0WEI;
	assign forward_low_a1_we_in = FORW_LA1WEI;
	assign forward_low_b0_we_in = FORW_LB0WEI;
	assign forward_low_b1_we_in = FORW_LB1WEI;
	// CLK
	assign forward_low_a0_clk_in = FORW_LA0CLKI;
	assign forward_low_a1_clk_in = FORW_LA1CLKI;
	assign forward_low_b0_clk_in = FORW_LB0CLKI;
	assign forward_low_b1_clk_in = FORW_LB1CLKI;


	wire [7:0] cdyn_cfg_forward_a_addr, cdyn_cfg_forward_b_addr;
	assign cdyn_cfg_forward_a_addr = 8'b0;
	assign cdyn_cfg_forward_b_addr = 8'b0;

	wire [15:0] a0_addr1_in;
	assign a0_addr1_in = ADDRA0;

	wire [15:0] a1_addr1_in;
	assign a1_addr1_in = ADDRA1;


	wire [15:0] b0_addr1_in;
	assign b0_addr1_in = ADDRB0;

	wire [15:0] b1_addr1_in;
	assign b1_addr1_in = ADDRB1;


	wire [7:0] a0_addr2_in;
	assign a0_addr2_in = {ADDRA0X[14],ADDRA0X[12],ADDRA0X[11],ADDRA0X[9],ADDRA0X[7],ADDRA0X[5],ADDRA0X[3],ADDRA0X[1]};

	wire [7:0] a1_addr2_in;
	assign a1_addr2_in = {ADDRA1X[14],ADDRA1X[12],ADDRA1X[11],ADDRA1X[9],ADDRA1X[7],ADDRA1X[5],ADDRA1X[3],ADDRA1X[1]};

	wire [7:0] b0_addr2_in;
	assign b0_addr2_in = {ADDRB0X[15],ADDRB0X[13],ADDRB0X[10],ADDRB0X[8],ADDRB0X[6],ADDRB0X[4],ADDRB0X[2],ADDRB0X[0]};

	wire [7:0] b1_addr2_in;
	assign b1_addr2_in = {ADDRB1X[15],ADDRB1X[13],ADDRB1X[10],ADDRB1X[8],ADDRB1X[6],ADDRB1X[4],ADDRB1X[2],ADDRB1X[0]};

	wire [19:0] a0_wrdata_in;
	assign a0_wrdata_in = DIA[19:0];

	wire [19:0] a1_wrdata_in;
	assign a1_wrdata_in = DIA[39:20];

	wire [19:0] b0_wrdata_in;
	assign b0_wrdata_in = DIB[19:0];

	wire [19:0] b1_wrdata_in;
	assign b1_wrdata_in = DIB[39:20];

	wire [19:0] a0_bitmask_in;
	assign a0_bitmask_in = WEA[19:0];

	wire [19:0] a1_bitmask_in;
	assign a1_bitmask_in = WEA[39:20];

	wire [19:0] b0_bitmask_in;
	assign b0_bitmask_in = WEB[19:0];

	wire [19:0] b1_bitmask_in;
	assign b1_bitmask_in = WEB[39:20];

	wire [19:0] a0_rddata_out;
	assign DOA[19:0] = a0_rddata_out;
	assign DOAX[19:0] = a0_rddata_out;

	wire [19:0] a1_rddata_out;
	assign DOA[39:20] = a1_rddata_out;
	assign DOAX[39:20] = a1_rddata_out;

	wire [19:0] b0_rddata_out;
	assign DOB[19:0] = b0_rddata_out;
	assign DOBX[19:0] = b0_rddata_out;

	wire [19:0] b1_rddata_out;
	assign DOB[39:20] = b1_rddata_out;
	assign DOBX[39:20] = b1_rddata_out;

	assign a0_en1_in = ENA[0];
	assign a0_en2_in = ENA[1];
	assign a1_en1_in = ENA[2];
	assign a1_en2_in = ENA[3];

	assign a0_we1_in = GLWEA[0];
	assign a0_we2_in = GLWEA[1];
	assign a1_we1_in = GLWEA[2];
	assign a1_we2_in = GLWEA[3];

	assign b0_en1_in = ENB[0];
	assign b0_en2_in = ENB[1];
	assign b1_en1_in = ENB[2];
	assign b1_en2_in = ENB[3];

	assign b0_we1_in = GLWEB[0];
	assign b0_we2_in = GLWEB[1];
	assign b1_we1_in = GLWEB[2];
	assign b1_we2_in = GLWEB[3];

	wire [1:0] lo_left_ecc_single_error_flag_out;
	wire [1:0] up_left_ecc_single_error_flag_out;
	wire [1:0] lo_right_ecc_single_error_flag_out;
	wire [1:0] up_right_ecc_single_error_flag_out;

	wire [1:0] lo_left_ecc_double_error_flag_out;
	wire [1:0] up_left_ecc_double_error_flag_out;
	wire [1:0] lo_right_ecc_double_error_flag_out;
	wire [1:0] up_right_ecc_double_error_flag_out;

	assign ECC1B_ERRA[0] = lo_left_ecc_single_error_flag_out[0];
	assign ECC1B_ERRA[1] = up_left_ecc_single_error_flag_out[0];
	assign ECC1B_ERRA[2] = lo_right_ecc_single_error_flag_out[0];
	assign ECC1B_ERRA[3] = up_right_ecc_single_error_flag_out[0];

	assign ECC2B_ERRA[0] = lo_left_ecc_double_error_flag_out[0];
	assign ECC2B_ERRA[1] = up_left_ecc_double_error_flag_out[0];
	assign ECC2B_ERRA[2] = lo_right_ecc_double_error_flag_out[0];
	assign ECC2B_ERRA[3] = up_right_ecc_double_error_flag_out[0];

	assign ECC1B_ERRB[0] = lo_left_ecc_single_error_flag_out[1];
	assign ECC1B_ERRB[1] = up_left_ecc_single_error_flag_out[1];
	assign ECC1B_ERRB[2] = lo_right_ecc_single_error_flag_out[1];
	assign ECC1B_ERRB[3] = up_right_ecc_single_error_flag_out[1];

	assign ECC2B_ERRB[0] = lo_left_ecc_double_error_flag_out[1];
	assign ECC2B_ERRB[1] = up_left_ecc_double_error_flag_out[1];
	assign ECC2B_ERRB[2] = lo_right_ecc_double_error_flag_out[1];
	assign ECC2B_ERRB[3] = up_right_ecc_double_error_flag_out[1];

	// initialize memory arrays to 0
	integer i;

	dpsram_block_4x512x20
	i_dpsram_block
	(
	.testmode_i   (1'b0),
	.testmode_o   (),
	// Configuration interface
	.ram_cfg(RAM_CFG),
	.cfg_gx_i     (1'b0     ),
	.lo_y1CFG_GLOBAL_DEC_Y_i     (1'b0     ),
	.cfg_addr_i   (5'b0),
	.cfg_data_i   (8'b0),
	.cfg_set_all_i(1'b0),

	.cfg_gx_o     (),
	.cfg_addr_o   (),
	.cfg_data_o   (),
	.cfg_set_all_o(),

	.left_clock1_o(CLOCKA[0]),
	.left_clock2_o(CLOCKA[1]),
	.left_clock3_o(CLOCKA[2]),
	.left_clock4_o(CLOCKA[3]),

	.right_clock1_o(CLOCKB[0]),
	.right_clock2_o(CLOCKB[1]),
	.right_clock3_o(CLOCKB[2]),
	.right_clock4_o(CLOCKB[3]),


	//.cdyn_almost_empty_offset_i(cdyn_almost_empty_offset_in),
	//.cdyn_almost_full_offset_i (cdyn_almost_full_offset_in ),
	.cdyn_cfg_forward_a_addr_i (cdyn_cfg_forward_a_addr),
	.cdyn_cfg_forward_b_addr_i (cdyn_cfg_forward_b_addr),

	// Interface for BIST and preloading
	.bist_enable_i (1'b0),
	.bist_wrdata_i (40'b0),
	.bist_rddata_i (40'b0),
	.bist_enable_o (),
	.bist_wrdata_o (),
	.bist_rddata_o (),

	// Global clocks
	.global_clk_x1_i(CLOCK1),
	.global_clk_x2_i(CLOCK2),
	.global_clk_y1_i(CLOCK3),
	.global_clk_y2_i(CLOCK4),

	// DPSRAM-block port A0
	.a0_clk1_i   (a0_clk1_in   ),
	.a0_clk2_i   (a0_clk2_in   ),
	.a0_en1_i    (a0_en1_in    ),
	.a0_en2_i    (a0_en2_in    ),
	.a0_we1_i    (a0_we1_in    ),
	.a0_we2_i    (a0_we2_in    ),
	.a0_addr1_i  (a0_addr1_in   ),
	.a0_addr2_dblin_i  (a0_addr2_in   ),
	.a0_wrdata_i (a0_wrdata_in ),
	.a0_bitmask_i(a0_bitmask_in),
	.a0_rddata_o (a0_rddata_out ),

	// DPSRAM-block port A1
	.a1_clk1_i   (a1_clk1_in   ),
	.a1_clk2_i   (a1_clk2_in   ),
	.a1_en1_i    (a1_en1_in    ),
	.a1_en2_i    (a1_en2_in    ),
	.a1_we1_i    (a1_we1_in    ),
	.a1_we2_i    (a1_we2_in    ),
	.a1_addr1_i  (a1_addr1_in   ),
	.a1_addr2_dblin_i  (a1_addr2_in   ),
	.a1_wrdata_i (a1_wrdata_in ),
	.a1_bitmask_i(a1_bitmask_in),
	.a1_rddata_o (a1_rddata_out ),

	// DPSRAM-block port B0
	.b0_clk1_i   (b0_clk1_in   ),
	.b0_clk2_i   (b0_clk2_in   ),
	.b0_en1_i    (b0_en1_in    ),
	.b0_en2_i    (b0_en2_in    ),
	.b0_we1_i    (b0_we1_in    ),
	.b0_we2_i    (b0_we2_in    ),
	.b0_addr1_i  (b0_addr1_in   ),
	.b0_addr2_dblin_i  (b0_addr2_in   ),
	.b0_wrdata_i (b0_wrdata_in ),
	.b0_bitmask_i(b0_bitmask_in),
	.b0_rddata_o (b0_rddata_out ),

	// DPSRAM-block port B1
	.b1_clk1_i   (b1_clk1_in   ),
	.b1_clk2_i   (b1_clk2_in   ),
	.b1_en1_i    (b1_en1_in    ),
	.b1_en2_i    (b1_en2_in    ),
	.b1_we1_i    (b1_we1_in    ),
	.b1_we2_i    (b1_we2_in    ),
	.b1_addr1_i  (b1_addr1_in   ),
	.b1_addr2_dblin_i  (b1_addr2_in   ),
	.b1_wrdata_i (b1_wrdata_in ),
	.b1_bitmask_i(b1_bitmask_in),
	.b1_rddata_o (b1_rddata_out ),


	// forward signals addr
	.forward_low_a_addr_i(16'b0),
	.forward_up_a_addr_i (16'b0 ),
	.forward_low_a_addr_o(),
	.forward_up_a_addr_o ( ),
	.forward_low_b_addr_i(16'b0),
	.forward_up_b_addr_i (16'b0 ),
	.forward_low_b_addr_o(),
	.forward_up_b_addr_o ( ),


	// forward signals cascade mode
	.forward_cascade_wrdata_a_i (1'b0),
	.forward_cascade_wrdata_b_i (1'b0),
	.forward_cascade_wrdata_a_o (FORW_CAS_WRAO),
	.forward_cascade_wrdata_b_o (FORW_CAS_WRBO),
	.forward_cascade_bitmask_a_i(1'b0),
	.forward_cascade_bitmask_b_i(1'b0),
	.forward_cascade_bitmask_a_o(FORW_CAS_BMAO),
	.forward_cascade_bitmask_b_o(FORW_CAS_BMBO),
	.forward_cascade_rddata_a_i (1'b0),
	.forward_cascade_rddata_b_i (1'b0),
	.forward_cascade_rddata_a_o (FORW_CAS_RDAO),
	.forward_cascade_rddata_b_o (FORW_CAS_RDBO),


	// forward signals port A0
	.forward_low_a0_clk_i(forward_low_a0_clk_in),
	.forward_low_a0_en_i (forward_low_a0_en_in ),
	.forward_low_a0_we_i (forward_low_a0_we_in ),
	.forward_up_a0_clk_i (forward_up_a0_clk_in ),
	.forward_up_a0_en_i  (forward_up_a0_en_in  ),
	.forward_up_a0_we_i  (forward_up_a0_we_in  ),
	.forward_low_a0_clk_o(),
	.forward_low_a0_en_o ( ),
	.forward_low_a0_we_o ( ),
	.forward_up_a0_clk_o ( ),
	.forward_up_a0_en_o  (  ),
	.forward_up_a0_we_o  (  ),

	// forward signals port A1
	.forward_low_a1_clk_i(forward_low_a1_clk_in),
	.forward_low_a1_en_i (forward_low_a1_en_in ),
	.forward_low_a1_we_i (forward_low_a1_we_in ),
	.forward_up_a1_clk_i (forward_up_a1_clk_in ),
	.forward_up_a1_en_i  (forward_up_a1_en_in  ),
	.forward_up_a1_we_i  (forward_up_a1_we_in  ),
	.forward_low_a1_clk_o(),
	.forward_low_a1_en_o ( ),
	.forward_low_a1_we_o ( ),
	.forward_up_a1_clk_o ( ),
	.forward_up_a1_en_o  (  ),
	.forward_up_a1_we_o  (  ),

	// forward signals port B0
	.forward_low_b0_clk_i(forward_low_b0_clk_in),
	.forward_low_b0_en_i (forward_low_b0_en_in ),
	.forward_low_b0_we_i (forward_low_b0_we_in ),
	.forward_up_b0_clk_i (forward_up_b0_clk_in ),
	.forward_up_b0_en_i  (forward_up_b0_en_in  ),
	.forward_up_b0_we_i  (forward_up_b0_we_in  ),
	.forward_low_b0_clk_o(),
	.forward_low_b0_en_o ( ),
	.forward_low_b0_we_o ( ),
	.forward_up_b0_clk_o ( ),
	.forward_up_b0_en_o  (  ),
	.forward_up_b0_we_o  (  ),

	// forward signals port B1
	.forward_low_b1_clk_i(forward_low_b1_clk_in),
	.forward_low_b1_en_i (forward_low_b1_en_in ),
	.forward_low_b1_we_i (forward_low_b1_we_in ),
	.forward_up_b1_clk_i (forward_up_b1_clk_in ),
	.forward_up_b1_en_i  (forward_up_b1_en_in  ),
	.forward_up_b1_we_i  (forward_up_b1_we_in  ),
	.forward_low_b1_clk_o(),
	.forward_low_b1_en_o ( ),
	.forward_low_b1_we_o ( ),
	.forward_up_b1_clk_o ( ),
	.forward_up_b1_en_o  (  ),
	.forward_up_b1_we_o  (  ),


	// ECC status
	.lo_left_ecc_single_error_flag_o(lo_left_ecc_single_error_flag_out),
	.up_left_ecc_single_error_flag_o(up_left_ecc_single_error_flag_out),
	.lo_right_ecc_single_error_flag_o(lo_right_ecc_single_error_flag_out),
	.up_right_ecc_single_error_flag_o(up_right_ecc_single_error_flag_out),

	.lo_left_ecc_double_error_flag_o(lo_left_ecc_double_error_flag_out),
	.up_left_ecc_double_error_flag_o(up_left_ecc_double_error_flag_out),
	.lo_right_ecc_double_error_flag_o(lo_right_ecc_double_error_flag_out),
	.up_right_ecc_double_error_flag_o(up_right_ecc_double_error_flag_out),


	// FIFO ctrl/status data
	.fifo_rstn_i         (1'b1),
	.left1_fifo_full_o         (),
	.left1_fifo_empty_o        (),
	.left1_fifo_almost_full_o  (),
	.left1_fifo_almost_empty_o (),
	.left1_fifo_write_error_o  (),
	.left1_fifo_read_error_o   (),
	.left2_fifo_full_o         (),
	.left2_fifo_empty_o        (),
	.left2_fifo_almost_full_o  (),
	.left2_fifo_almost_empty_o (),
	.left2_fifo_write_error_o  (),
	.left2_fifo_read_error_o   (),
	.fifo_write_address_o(),
	.fifo_read_address_o ()
	);

	integer k;

	initial begin

		for (k = 0; k < 512; k = k + 1) begin
			i_dpsram_block.RAM_i1.RM_GF28SLP_2P_512x20_c2_inst.SRAM_2P_behavioral_i.mem_arr[k]=20'b0;
			i_dpsram_block.RAM_i2.RM_GF28SLP_2P_512x20_c2_inst.SRAM_2P_behavioral_i.mem_arr[k]=20'b0;
			i_dpsram_block.RAM_i3.RM_GF28SLP_2P_512x20_c2_inst.SRAM_2P_behavioral_i.mem_arr[k]=20'b0;
			i_dpsram_block.RAM_i4.RM_GF28SLP_2P_512x20_c2_inst.SRAM_2P_behavioral_i.mem_arr[k]=20'b0;
		end

		i_dpsram_block.RAM_i1.RM_GF28SLP_2P_512x20_c2_inst.SRAM_2P_behavioral_i.dr_a_r=20'b0;
		i_dpsram_block.RAM_i1.RM_GF28SLP_2P_512x20_c2_inst.SRAM_2P_behavioral_i.dr_b_r=20'b0;
		i_dpsram_block.RAM_i2.RM_GF28SLP_2P_512x20_c2_inst.SRAM_2P_behavioral_i.dr_a_r=20'b0;
		i_dpsram_block.RAM_i2.RM_GF28SLP_2P_512x20_c2_inst.SRAM_2P_behavioral_i.dr_b_r=20'b0;
		i_dpsram_block.RAM_i3.RM_GF28SLP_2P_512x20_c2_inst.SRAM_2P_behavioral_i.dr_a_r=20'b0;
		i_dpsram_block.RAM_i3.RM_GF28SLP_2P_512x20_c2_inst.SRAM_2P_behavioral_i.dr_b_r=20'b0;
		i_dpsram_block.RAM_i4.RM_GF28SLP_2P_512x20_c2_inst.SRAM_2P_behavioral_i.dr_a_r=20'b0;
		i_dpsram_block.RAM_i4.RM_GF28SLP_2P_512x20_c2_inst.SRAM_2P_behavioral_i.dr_b_r=20'b0;
		i_dpsram_block.output_registering_i.r_a0_rddata=20'b0;
		i_dpsram_block.output_registering_i.r_a1_rddata=20'b0;
		i_dpsram_block.output_registering_i.r_b0_rddata=20'b0;
		i_dpsram_block.output_registering_i.r_b1_rddata=20'b0;
		i_dpsram_block.output_registering_i.r_ecc_single_error_flag=2'b0;
		i_dpsram_block.output_registering_i.r_ecc_double_error_flag=2'b0;
	end

`ifdef USE_TIMING
	specify
		(CLOCK1 => DOA[0]) = 0;
		(CLOCK1 => DOA[1]) = 0;
		(CLOCK1 => DOA[2]) = 0;
		(CLOCK1 => DOA[3]) = 0;
		(CLOCK1 => DOA[4]) = 0;
		(CLOCK1 => DOA[5]) = 0;
		(CLOCK1 => DOA[6]) = 0;
		(CLOCK1 => DOA[7]) = 0;
		(CLOCK1 => DOA[8]) = 0;
		(CLOCK1 => DOA[9]) = 0;
		(CLOCK1 => DOA[10]) = 0;
		(CLOCK1 => DOA[11]) = 0;
		(CLOCK1 => DOA[12]) = 0;
		(CLOCK1 => DOA[13]) = 0;
		(CLOCK1 => DOA[14]) = 0;
		(CLOCK1 => DOA[15]) = 0;
		(CLOCK1 => DOA[16]) = 0;
		(CLOCK1 => DOA[17]) = 0;
		(CLOCK1 => DOA[18]) = 0;
		(CLOCK1 => DOA[19]) = 0;
		(CLOCK1 => DOA[20]) = 0;
		(CLOCK1 => DOA[21]) = 0;
		(CLOCK1 => DOA[22]) = 0;
		(CLOCK1 => DOA[23]) = 0;
		(CLOCK1 => DOA[24]) = 0;
		(CLOCK1 => DOA[25]) = 0;
		(CLOCK1 => DOA[26]) = 0;
		(CLOCK1 => DOA[27]) = 0;
		(CLOCK1 => DOA[28]) = 0;
		(CLOCK1 => DOA[29]) = 0;
		(CLOCK1 => DOA[30]) = 0;
		(CLOCK1 => DOA[31]) = 0;
		(CLOCK1 => DOA[32]) = 0;
		(CLOCK1 => DOA[33]) = 0;
		(CLOCK1 => DOA[34]) = 0;
		(CLOCK1 => DOA[35]) = 0;
		(CLOCK1 => DOA[36]) = 0;
		(CLOCK1 => DOA[37]) = 0;
		(CLOCK1 => DOA[38]) = 0;
		(CLOCK1 => DOA[39]) = 0;
		(CLOCK1 => DOB[0]) = 0;
		(CLOCK1 => DOB[1]) = 0;
		(CLOCK1 => DOB[2]) = 0;
		(CLOCK1 => DOB[3]) = 0;
		(CLOCK1 => DOB[4]) = 0;
		(CLOCK1 => DOB[5]) = 0;
		(CLOCK1 => DOB[6]) = 0;
		(CLOCK1 => DOB[7]) = 0;
		(CLOCK1 => DOB[8]) = 0;
		(CLOCK1 => DOB[9]) = 0;
		(CLOCK1 => DOB[10]) = 0;
		(CLOCK1 => DOB[11]) = 0;
		(CLOCK1 => DOB[12]) = 0;
		(CLOCK1 => DOB[13]) = 0;
		(CLOCK1 => DOB[14]) = 0;
		(CLOCK1 => DOB[15]) = 0;
		(CLOCK1 => DOB[16]) = 0;
		(CLOCK1 => DOB[17]) = 0;
		(CLOCK1 => DOB[18]) = 0;
		(CLOCK1 => DOB[19]) = 0;
		(CLOCK1 => DOB[20]) = 0;
		(CLOCK1 => DOB[21]) = 0;
		(CLOCK1 => DOB[22]) = 0;
		(CLOCK1 => DOB[23]) = 0;
		(CLOCK1 => DOB[24]) = 0;
		(CLOCK1 => DOB[25]) = 0;
		(CLOCK1 => DOB[26]) = 0;
		(CLOCK1 => DOB[27]) = 0;
		(CLOCK1 => DOB[28]) = 0;
		(CLOCK1 => DOB[29]) = 0;
		(CLOCK1 => DOB[30]) = 0;
		(CLOCK1 => DOB[31]) = 0;
		(CLOCK1 => DOB[32]) = 0;
		(CLOCK1 => DOB[33]) = 0;
		(CLOCK1 => DOB[34]) = 0;
		(CLOCK1 => DOB[35]) = 0;
		(CLOCK1 => DOB[36]) = 0;
		(CLOCK1 => DOB[37]) = 0;
		(CLOCK1 => DOB[38]) = 0;
		(CLOCK1 => DOB[39]) = 0;
	endspecify
`endif

endmodule
`endif // USE_RAM
