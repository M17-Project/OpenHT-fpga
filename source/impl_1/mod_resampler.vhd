-------------------------------------------------------------
-- Modulator resampler
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
		C_TAPS_5 : taps_mod_t := (
			x"0014", x"000C", x"0000", x"FFF4", x"FFEC", 
			x"FFEC", x"FFF3", x"0000", x"000D", x"0016", 
			x"0016", x"000E", x"0000", x"FFF2", x"FFE8", 
			x"FFE7", x"FFF0", x"0000", x"0010", x"001B", 
			x"001C", x"0012", x"0000", x"FFED", x"FFE1", 
			x"FFE0", x"FFEC", x"0000", x"0016", x"0024", 
			x"0025", x"0018", x"0000", x"FFE7", x"FFD6", 
			x"FFD4", x"FFE4", x"0000", x"001E", x"0031", 
			x"0033", x"0020", x"0000", x"FFDD", x"FFC6", 
			x"FFC5", x"FFDA", x"0000", x"0028", x"0043", 
			x"0045", x"002C", x"0000", x"FFD1", x"FFB2", 
			x"FFB0", x"FFCD", x"0000", x"0036", x"005A", 
			x"005D", x"003B", x"0000", x"FFC1", x"FF98", 
			x"FF95", x"FFBC", x"0000", x"0048", x"0077", 
			x"007B", x"004E", x"0000", x"FFAE", x"FF77", 
			x"FF74", x"FFA7", x"0000", x"005E", x"009C", 
			x"00A0", x"0065", x"0000", x"FF96", x"FF50", 
			x"FF4B", x"FF8D", x"0000", x"0078", x"00C8", 
			x"00CC", x"0081", x"0000", x"FF78", x"FF1F", 
			x"FF1A", x"FF6E", x"0000", x"0099", x"00FD", 
			x"0103", x"00A4", x"0000", x"FF54", x"FEE4", 
			x"FEDD", x"FF48", x"0000", x"00C0", x"013E", 
			x"0146", x"00CE", x"0000", x"FF29", x"FE9C", 
			x"FE93", x"FF1A", x"0000", x"00F1", x"018F", 
			x"0198", x"0102", x"0000", x"FEF3", x"FE42", 
			x"FE38", x"FEE0", x"0000", x"012D", x"01F3", 
			x"01FE", x"0142", x"0000", x"FEAF", x"FDD1", 
			x"FDC4", x"FE97", x"0000", x"017B", x"0273", 
			x"0282", x"0196", x"0000", x"FE56", x"FD3E", 
			x"FD2D", x"FE36", x"0000", x"01E1", x"031E", 
			x"0332", x"0207", x"0000", x"FDDE", x"FC75", 
			x"FC5D", x"FDB1", x"0000", x"0271", x"040F", 
			x"042D", x"02A8", x"0000", x"FD2E", x"FB4D", 
			x"FB27", x"FCE8", x"0000", x"034D", x"0586", 
			x"05B7", x"03A9", x"0000", x"FC10", x"F961", 
			x"F91C", x"FB91", x"0000", x"04D5", x"082E", 
			x"0892", x"0590", x"0000", x"F9D3", x"F56E", 
			x"F4C9", x"F89F", x"0000", x"0876", x"0EC4", 
			x"1004", x"0AD0", x"0000", x"F2C1", x"E7DE", 
			x"E466", x"EC15", x"0000", x"1DE9", x"408D", 
			x"60DA", x"77BC", x"7FFF", x"77BC", x"60DA", 
			x"408D", x"1DE9", x"0000", x"EC15", x"E466", 
			x"E7DE", x"F2C1", x"0000", x"0AD0", x"1004", 
			x"0EC4", x"0876", x"0000", x"F89F", x"F4C9", 
			x"F56E", x"F9D3", x"0000", x"0590", x"0892", 
			x"082E", x"04D5", x"0000", x"FB91", x"F91C", 
			x"F961", x"FC10", x"0000", x"03A9", x"05B7", 
			x"0586", x"034D", x"0000", x"FCE8", x"FB27", 
			x"FB4D", x"FD2E", x"0000", x"02A8", x"042D", 
			x"040F", x"0271", x"0000", x"FDB1", x"FC5D", 
			x"FC75", x"FDDE", x"0000", x"0207", x"0332", 
			x"031E", x"01E1", x"0000", x"FE36", x"FD2D", 
			x"FD3E", x"FE56", x"0000", x"0196", x"0282", 
			x"0273", x"017B", x"0000", x"FE97", x"FDC4", 
			x"FDD1", x"FEAF", x"0000", x"0142", x"01FE", 
			x"01F3", x"012D", x"0000", x"FEE0", x"FE38", 
			x"FE42", x"FEF3", x"0000", x"0102", x"0198", 
			x"018F", x"00F1", x"0000", x"FF1A", x"FE93", 
			x"FE9C", x"FF29", x"0000", x"00CE", x"0146", 
			x"013E", x"00C0", x"0000", x"FF48", x"FEDD", 
			x"FEE4", x"FF54", x"0000", x"00A4", x"0103", 
			x"00FD", x"0099", x"0000", x"FF6E", x"FF1A", 
			x"FF1F", x"FF78", x"0000", x"0081", x"00CC", 
			x"00C8", x"0078", x"0000", x"FF8D", x"FF4B", 
			x"FF50", x"FF96", x"0000", x"0065", x"00A0", 
			x"009C", x"005E", x"0000", x"FFA7", x"FF74", 
			x"FF77", x"FFAE", x"0000", x"004E", x"007B", 
			x"0077", x"0048", x"0000", x"FFBC", x"FF95", 
			x"FF98", x"FFC1", x"0000", x"003B", x"005D", 
			x"005A", x"0036", x"0000", x"FFCD", x"FFB0", 
			x"FFB2", x"FFD1", x"0000", x"002C", x"0045", 
			x"0043", x"0028", x"0000", x"FFDA", x"FFC5", 
			x"FFC6", x"FFDD", x"0000", x"0020", x"0033", 
			x"0031", x"001E", x"0000", x"FFE4", x"FFD4", 
			x"FFD6", x"FFE7", x"0000", x"0018", x"0025", 
			x"0024", x"0016", x"0000", x"FFEC", x"FFE0", 
			x"FFE1", x"FFED", x"0000", x"0012", x"001C", 
			x"001B", x"0010", x"0000", x"FFF0", x"FFE7", 
			x"FFE8", x"FFF2", x"0000", x"000E", x"0016", 
			x"0016", x"000D", x"0000", x"FFF3", x"FFEC", 
			x"FFEC", x"FFF4", x"0000", x"000C", x"0014"
		);
		C_TAPS_2 : taps_mod_t := (
			x"0000", x"0008", x"0000", x"FFF8", x"0000", 
			x"0009", x"0000", x"FFF7", x"0000", x"0009", 
			x"0000", x"FFF7", x"0000", x"000A", x"0000", 
			x"FFF6", x"0000", x"000B", x"0000", x"FFF5", 
			x"0000", x"000C", x"0000", x"FFF3", x"0000", 
			x"000D", x"0000", x"FFF2", x"0000", x"000F", 
			x"0000", x"FFF0", x"0000", x"0011", x"0000", 
			x"FFEE", x"0000", x"0013", x"0000", x"FFEB", 
			x"0000", x"0016", x"0000", x"FFE9", x"0000", 
			x"0019", x"0000", x"FFE5", x"0000", x"001C", 
			x"0000", x"FFE2", x"0000", x"0020", x"0000", 
			x"FFDE", x"0000", x"0024", x"0000", x"FFDA", 
			x"0000", x"0028", x"0000", x"FFD5", x"0000", 
			x"002D", x"0000", x"FFD0", x"0000", x"0032", 
			x"0000", x"FFCB", x"0000", x"0038", x"0000", 
			x"FFC5", x"0000", x"003E", x"0000", x"FFBF", 
			x"0000", x"0045", x"0000", x"FFB8", x"0000", 
			x"004C", x"0000", x"FFB0", x"0000", x"0054", 
			x"0000", x"FFA8", x"0000", x"005C", x"0000", 
			x"FF9F", x"0000", x"0066", x"0000", x"FF96", 
			x"0000", x"0070", x"0000", x"FF8B", x"0000", 
			x"007A", x"0000", x"FF80", x"0000", x"0086", 
			x"0000", x"FF74", x"0000", x"0093", x"0000", 
			x"FF67", x"0000", x"00A0", x"0000", x"FF58", 
			x"0000", x"00AF", x"0000", x"FF49", x"0000", 
			x"00C0", x"0000", x"FF37", x"0000", x"00D2", 
			x"0000", x"FF25", x"0000", x"00E6", x"0000", 
			x"FF10", x"0000", x"00FC", x"0000", x"FEF8", 
			x"0000", x"0114", x"0000", x"FEDE", x"0000", 
			x"0130", x"0000", x"FEC1", x"0000", x"014F", 
			x"0000", x"FE9F", x"0000", x"0174", x"0000", 
			x"FE78", x"0000", x"019D", x"0000", x"FE4B", 
			x"0000", x"01CF", x"0000", x"FE15", x"0000", 
			x"020A", x"0000", x"FDD4", x"0000", x"0253", 
			x"0000", x"FD82", x"0000", x"02AE", x"0000", 
			x"FD1A", x"0000", x"0326", x"0000", x"FC8F", 
			x"0000", x"03C9", x"0000", x"FBCC", x"0000", 
			x"04B7", x"0000", x"FAA3", x"0000", x"0636", 
			x"0000", x"F8A4", x"0000", x"0903", x"0000", 
			x"F464", x"0000", x"1046", x"0000", x"E4DA", 
			x"0000", x"517C", x"7FFF", x"517C", x"0000", 
			x"E4DA", x"0000", x"1046", x"0000", x"F464", 
			x"0000", x"0903", x"0000", x"F8A4", x"0000", 
			x"0636", x"0000", x"FAA3", x"0000", x"04B7", 
			x"0000", x"FBCC", x"0000", x"03C9", x"0000", 
			x"FC8F", x"0000", x"0326", x"0000", x"FD1A", 
			x"0000", x"02AE", x"0000", x"FD82", x"0000", 
			x"0253", x"0000", x"FDD4", x"0000", x"020A", 
			x"0000", x"FE15", x"0000", x"01CF", x"0000", 
			x"FE4B", x"0000", x"019D", x"0000", x"FE78", 
			x"0000", x"0174", x"0000", x"FE9F", x"0000", 
			x"014F", x"0000", x"FEC1", x"0000", x"0130", 
			x"0000", x"FEDE", x"0000", x"0114", x"0000", 
			x"FEF8", x"0000", x"00FC", x"0000", x"FF10", 
			x"0000", x"00E6", x"0000", x"FF25", x"0000", 
			x"00D2", x"0000", x"FF37", x"0000", x"00C0", 
			x"0000", x"FF49", x"0000", x"00AF", x"0000", 
			x"FF58", x"0000", x"00A0", x"0000", x"FF67", 
			x"0000", x"0093", x"0000", x"FF74", x"0000", 
			x"0086", x"0000", x"FF80", x"0000", x"007A", 
			x"0000", x"FF8B", x"0000", x"0070", x"0000", 
			x"FF96", x"0000", x"0066", x"0000", x"FF9F", 
			x"0000", x"005C", x"0000", x"FFA8", x"0000", 
			x"0054", x"0000", x"FFB0", x"0000", x"004C", 
			x"0000", x"FFB8", x"0000", x"0045", x"0000", 
			x"FFBF", x"0000", x"003E", x"0000", x"FFC5", 
			x"0000", x"0038", x"0000", x"FFCB", x"0000", 
			x"0032", x"0000", x"FFD0", x"0000", x"002D", 
			x"0000", x"FFD5", x"0000", x"0028", x"0000", 
			x"FFDA", x"0000", x"0024", x"0000", x"FFDE", 
			x"0000", x"0020", x"0000", x"FFE2", x"0000", 
			x"001C", x"0000", x"FFE5", x"0000", x"0019", 
			x"0000", x"FFE9", x"0000", x"0016", x"0000", 
			x"FFEB", x"0000", x"0013", x"0000", x"FFEE", 
			x"0000", x"0011", x"0000", x"FFF0", x"0000", 
			x"000F", x"0000", x"FFF2", x"0000", x"000D", 
			x"0000", x"FFF3", x"0000", x"000C", x"0000", 
			x"FFF5", x"0000", x"000B", x"0000", x"FFF6", 
			x"0000", x"000A", x"0000", x"FFF7", x"0000", 
			x"0009", x"0000", x"FFF7", x"0000", x"0009", 
			x"0000", x"FFF8", x"0000", x"0008", x"0000"
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
	signal interp0_axis_in		: axis_in_mod_t;
	signal interp0_axis_out		: axis_out_mod_t;
	signal interp1_axis_in		: axis_in_mod_t;
	signal interp1_axis_out		: axis_out_mod_t;
begin
	interpol0: entity work.mod_interpolator
	generic map(
		N_TAPS	=> 405,
		L		=> 5,
		C_TAPS	=> C_TAPS_5
	)
	port map
	(
		clk_i			=> clk_i,
		s_axis_mod_i	=> s_axis_mod_i,
		s_axis_mod_o	=> s_axis_mod_o,
		m_axis_mod_o	=> interp0_axis_in,
		m_axis_mod_i 	=> interp0_axis_out
	);
	
	interpol1: entity work.mod_interpolator
	generic map(
		N_TAPS	=> 405,
		L		=> 5,
		C_TAPS	=> C_TAPS_5
	)
	port map
	(
		clk_i			=> clk_i,
		s_axis_mod_i	=> interp0_axis_in,
		s_axis_mod_o	=> interp0_axis_out,
		m_axis_mod_o	=> interp1_axis_in,
		m_axis_mod_i 	=> interp1_axis_out
	);
	
	interpol2: entity work.mod_interpolator
	generic map(
		N_TAPS	=> 405,
		L		=> 2,
		C_TAPS	=> C_TAPS_2
	)
	port map
	(
		clk_i			=> clk_i,
		s_axis_mod_i	=> interp1_axis_in,
		s_axis_mod_o	=> interp1_axis_out,
		m_axis_mod_o	=> m_axis_mod_o,
		m_axis_mod_i 	=> m_axis_mod_i
	);	
end magic;
