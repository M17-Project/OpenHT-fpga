-------------------------------------------------------------
-- Modulation resampler
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.regs_pkg.all;
use work.axi_stream_pkg.all;
use work.openht_utils_pkg.all;

entity mod_resampler is
	generic(
		C_TAPS_5_8K : taps_mod_t := (
			x"002c", x"fffe", x"fff8", x"fff1", x"ffec",
			x"ffec", x"fff2", x"fffc", x"0007", x"000f",
			x"0011", x"000a", x"fffe", x"fff0", x"ffe6",
			x"ffe5", x"ffee", x"ffff", x"0011", x"001f",
			x"0020", x"0015", x"0000", x"ffe8", x"ffd8",
			x"ffd6", x"ffe5", x"0000", x"001d", x"0032",
			x"0034", x"0021", x"0000", x"ffdc", x"ffc3",
			x"ffc0", x"ffd7", x"0000", x"002c", x"004a",
			x"004d", x"0031", x"0000", x"ffcb", x"ffa6",
			x"ffa3", x"ffc5", x"0000", x"0040", x"006b",
			x"006f", x"0047", x"0000", x"ffb5", x"ff81",
			x"ff7d", x"ffad", x"0000", x"0059", x"0095",
			x"009a", x"0062", x"0000", x"ff98", x"ff52",
			x"ff4d", x"ff8e", x"0000", x"0079", x"00ca",
			x"00d0", x"0084", x"0000", x"ff74", x"ff16",
			x"ff0f", x"ff67", x"0000", x"00a1", x"010d",
			x"0115", x"00b0", x"0000", x"ff47", x"fecb",
			x"fec3", x"ff37", x"0000", x"00d4", x"0160",
			x"016a", x"00e5", x"0000", x"ff0f", x"fe6f",
			x"fe64", x"fefb", x"0000", x"0112", x"01c8",
			x"01d3", x"0128", x"0000", x"fec9", x"fdfc",
			x"fdef", x"feb1", x"0000", x"0160", x"0247",
			x"0256", x"017b", x"0000", x"fe73", x"fd6d",
			x"fd5d", x"fe55", x"0000", x"01c0", x"02e7",
			x"02f9", x"01e1", x"0000", x"fe07", x"fcbb",
			x"fca7", x"fde1", x"0000", x"0239", x"03af",
			x"03c6", x"0264", x"0000", x"fd7e", x"fbd8",
			x"fbbe", x"fd4e", x"0000", x"02d5", x"04b2",
			x"04d0", x"030d", x"0000", x"fccc", x"faae",
			x"fa8b", x"fc8b", x"0000", x"03a4", x"060c",
			x"0635", x"03f0", x"0000", x"fbd8", x"f917",
			x"f8e5", x"fb7c", x"0000", x"04c7", x"07f5",
			x"0832", x"0538", x"0000", x"fa75", x"f6bf",
			x"f672", x"f9e7", x"0000", x"0684", x"0aea",
			x"0b4e", x"073e", x"0000", x"f832", x"f2df",
			x"f255", x"f732", x"0000", x"0999", x"1043",
			x"110d", x"0b13", x"0000", x"f3b3", x"eaef",
			x"e9a4", x"f149", x"0000", x"10e2", x"1d79",
			x"1ffb", x"1598", x"0000", x"e589", x"cfc5",
			x"c8d3", x"d82f", x"0000", x"3bce", x"8116",
			x"c1b2", x"ef78", x"7FFF", x"ef78", x"c1b2",
			x"8116", x"3bce", x"0000", x"d82f", x"c8d3",
			x"cfc5", x"e589", x"0000", x"1598", x"1ffb",
			x"1d79", x"10e2", x"0000", x"f149", x"e9a4",
			x"eaef", x"f3b3", x"0000", x"0b13", x"110d",
			x"1043", x"0999", x"0000", x"f732", x"f255",
			x"f2df", x"f832", x"0000", x"073e", x"0b4e",
			x"0aea", x"0684", x"0000", x"f9e7", x"f672",
			x"f6bf", x"fa75", x"0000", x"0538", x"0832",
			x"07f5", x"04c7", x"0000", x"fb7c", x"f8e5",
			x"f917", x"fbd8", x"0000", x"03f0", x"0635",
			x"060c", x"03a4", x"0000", x"fc8b", x"fa8b",
			x"faae", x"fccc", x"0000", x"030d", x"04d0",
			x"04b2", x"02d5", x"0000", x"fd4e", x"fbbe",
			x"fbd8", x"fd7e", x"0000", x"0264", x"03c6",
			x"03af", x"0239", x"0000", x"fde1", x"fca7",
			x"fcbb", x"fe07", x"0000", x"01e1", x"02f9",
			x"02e7", x"01c0", x"0000", x"fe55", x"fd5d",
			x"fd6d", x"fe73", x"0000", x"017b", x"0256",
			x"0247", x"0160", x"0000", x"feb1", x"fdef",
			x"fdfc", x"fec9", x"0000", x"0128", x"01d3",
			x"01c8", x"0112", x"0000", x"fefb", x"fe64",
			x"fe6f", x"ff0f", x"0000", x"00e5", x"016a",
			x"0160", x"00d4", x"0000", x"ff37", x"fec3",
			x"fecb", x"ff47", x"0000", x"00b0", x"0115",
			x"010d", x"00a1", x"0000", x"ff67", x"ff0f",
			x"ff16", x"ff74", x"0000", x"0084", x"00d0",
			x"00ca", x"0079", x"0000", x"ff8e", x"ff4d",
			x"ff52", x"ff98", x"0000", x"0062", x"009a",
			x"0095", x"0059", x"0000", x"ffad", x"ff7d",
			x"ff81", x"ffb5", x"0000", x"0047", x"006f",
			x"006b", x"0040", x"0000", x"ffc5", x"ffa3",
			x"ffa6", x"ffcb", x"0000", x"0031", x"004d",
			x"004a", x"002c", x"0000", x"ffd7", x"ffc0",
			x"ffc3", x"ffdc", x"0000", x"0021", x"0034",
			x"0032", x"001d", x"0000", x"ffe5", x"ffd6",
			x"ffd8", x"ffe8", x"0000", x"0015", x"0020",
			x"001f", x"0011", x"ffff", x"ffee", x"ffe5",
			x"ffe6", x"fff0", x"fffe", x"000a", x"0011",
			x"000f", x"0007", x"fffc", x"fff2", x"ffec",
			x"ffec", x"fff1", x"fff8", x"fffe", x"002c"
		);

		C_TAPS_5_40K : taps_mod_t := (
			x"fffc", x"fffe", x"fffe", x"fffe", x"ffff",
			x"0000", x"0001", x"0003", x"0006", x"0009",
			x"000c", x"000f", x"0013", x"0015", x"0016",
			x"0016", x"0014", x"000f", x"0008", x"0000",
			x"fff4", x"ffe6", x"ffd7", x"ffc7", x"ffb8",
			x"ffaa", x"ffa0", x"ff9a", x"ff9a", x"ffa0",
			x"ffaf", x"ffc6", x"ffe6", x"000c", x"0039",
			x"006b", x"009f", x"00d2", x"0100", x"0126",
			x"013f", x"0148", x"013f", x"0120", x"00ea",
			x"009e", x"003d", x"ffca", x"ff49", x"fec0",
			x"fe37", x"fdb7", x"fd48", x"fcf3", x"fcc1",
			x"fcba", x"fce4", x"fd42", x"fdd6", x"fe9d",
			x"ff93", x"00ad", x"01e2", x"0321", x"0459",
			x"0577", x"0667", x"0715", x"0770", x"0768",
			x"06f1", x"0606", x"04a6", x"02d5", x"00a2",
			x"fe21", x"fb6a", x"f89e", x"f5e3", x"f362",
			x"f146", x"efba", x"eee6", x"eef1", x"eff8",
			x"f213", x"f551", x"f9b4", x"ff34", x"05bc",
			x"0d2e", x"155f", x"1e1a", x"2723", x"3039",
			x"3916", x"4175", x"4911", x"4fab", x"550c",
			x"5906", x"5b77", x"5c4a", x"5b77", x"5906",
			x"550c", x"4fab", x"4911", x"4175", x"3916",
			x"3039", x"2723", x"1e1a", x"155f", x"0d2e",
			x"05bc", x"ff34", x"f9b4", x"f551", x"f213",
			x"eff8", x"eef1", x"eee6", x"efba", x"f146",
			x"f362", x"f5e3", x"f89e", x"fb6a", x"fe21",
			x"00a2", x"02d5", x"04a6", x"0606", x"06f1",
			x"0768", x"0770", x"0715", x"0667", x"0577",
			x"0459", x"0321", x"01e2", x"00ad", x"ff93",
			x"fe9d", x"fdd6", x"fd42", x"fce4", x"fcba",
			x"fcc1", x"fcf3", x"fd48", x"fdb7", x"fe37",
			x"fec0", x"ff49", x"ffca", x"003d", x"009e",
			x"00ea", x"0120", x"013f", x"0148", x"013f",
			x"0126", x"0100", x"00d2", x"009f", x"006b",
			x"0039", x"000c", x"ffe6", x"ffc6", x"ffaf",
			x"ffa0", x"ff9a", x"ff9a", x"ffa0", x"ffaa",
			x"ffb8", x"ffc7", x"ffd7", x"ffe6", x"fff4",
			x"0000", x"0008", x"000f", x"0014", x"0016",
			x"0016", x"0015", x"0013", x"000f", x"000c",
			x"0009", x"0006", x"0003", x"0001", x"0000",
			x"ffff", x"fffe", x"fffe", x"fffe", x"fffc"
		);

		C_TAPS_2_200K : taps_mod_t := (
			x"0000", x"ffff", x"fffe", x"fffc", x"fff8", x"fff4", x"ffef", x"ffe9", 
			x"ffe3", x"ffdf", x"ffdc", x"ffde", x"ffe6", x"fff5", x"000c", x"002d", 
			x"0057", x"0088", x"00bc", x"00ef", x"011a", x"0136", x"013a", x"011d", 
			x"00d9", x"0069", x"ffcd", x"ff06", x"fe1d", x"fd20", x"fc24", x"fb41", 
			x"fa93", x"fa3a", x"fa55", x"faff", x"fc50", x"fe56", x"0114", x"0487", 
			x"0898", x"0d28", x"120b", x"170d", x"1bf4", x"2082", x"247c", x"27ac", 
			x"29e6", x"2b0c", x"2b0c", x"29e6", x"27ac", x"247c", x"2082", x"1bf4", 
			x"170d", x"120b", x"0d28", x"0898", x"0487", x"0114", x"fe56", x"fc50", 
			x"faff", x"fa55", x"fa3a", x"fa93", x"fb41", x"fc24", x"fd20", x"fe1d", 
			x"ff06", x"ffcd", x"0069", x"00d9", x"011d", x"013a", x"0136", x"011a", 
			x"00ef", x"00bc", x"0088", x"0057", x"002d", x"000c", x"fff5", x"ffe6", 
			x"ffde", x"ffdc", x"ffdf", x"ffe3", x"ffe9", x"ffef", x"fff4", x"fff8",
			x"fffc", x"fffe", x"ffff", x"0000"
		)
	);
	port(
		clk_i        : in std_logic;
		s_axis_mod_i : in axis_in_mod_t;
		s_axis_mod_o : out axis_out_mod_t;
		m_axis_mod_o : out axis_in_mod_t;
		m_axis_mod_i : in axis_out_mod_t
	);
end mod_resampler;

architecture magic of mod_resampler is
	signal interp0_axis_in		: axis_out_mod_t;
	signal interp0_axis_out		: axis_in_mod_t;
	signal interp1_axis_in		: axis_out_mod_t;
	signal interp1_axis_out		: axis_in_mod_t;
begin
	interpol0: entity work.mod_interpolator
	generic map(
		N_TAPS	=> 405,
		L		=> 5,
		C_TAPS	=> C_TAPS_5_8K
	)
	port map(
		clk_i			=> clk_i,
		s_axis_mod_i	=> s_axis_mod_i,
		s_axis_mod_o	=> s_axis_mod_o,
		m_axis_mod_o	=> interp0_axis_out,
		m_axis_mod_i 	=> interp0_axis_in
	);

	interpol1: entity work.mod_interpolator
	generic map(
		N_TAPS	=> 205,
		L		=> 5,
		C_TAPS	=> C_TAPS_5_40K
	)
	port map(
		clk_i			=> clk_i,
		s_axis_mod_i	=> interp0_axis_out,
		s_axis_mod_o	=> interp0_axis_in,
		m_axis_mod_o	=> interp1_axis_out,
		m_axis_mod_i 	=> interp1_axis_in
	);

	interpol2: entity work.mod_interpolator
	generic map(
		N_TAPS	=> 100,
		L		=> 2,
		C_TAPS	=> C_TAPS_2_200K
	)
	port map(
		clk_i			=> clk_i,
		s_axis_mod_i	=> interp1_axis_out,
		s_axis_mod_o	=> interp1_axis_in,
		m_axis_mod_o	=> m_axis_mod_o,
		m_axis_mod_i 	=> m_axis_mod_i
	);
end magic;
