-------------------------------------------------------------
-- Channel filter with decimation
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- June 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity channel_filter is
	generic(
		SAMP_WIDTH	: integer := 16
	);
	port(
		clk_i		: in std_logic;											-- 38MHz clock in
		ch_width	: in std_logic_vector(1 downto 0);						-- channel width selector
		i_i			: in signed(SAMP_WIDTH-1 downto 0);						-- I in
		q_i			: in signed(SAMP_WIDTH-1 downto 0);						-- Q in
		i_o			: out signed(SAMP_WIDTH-1 downto 0) := (others => '0');	-- I out
		q_o			: out signed(SAMP_WIDTH-1 downto 0) := (others => '0');	-- Q out
		trig_i		: in std_logic;											-- trigger in
		drdy_o		: out std_logic := '0'									-- data ready out
	);
end channel_filter;

architecture magic of channel_filter is
	component fir_halfband is
		generic(
			TAPS_NUM	: integer := 81;
			SAMP_WIDTH	: integer := 16
		);
		port(
			clk_i		: in std_logic;							-- fast clock in
			data_i		: in signed(SAMP_WIDTH-1 downto 0);		-- data in
			data_o		: out signed(SAMP_WIDTH-1 downto 0);	-- data out
			trig_i		: in std_logic;							-- trigger in
			drdy_o		: out std_logic							-- data ready out
		);
	end component;

	component decim is
		generic(
			DECIM		: integer := 2;
			BIT_SIZE	: integer := 16
		);
		port(
			clk_i					: in std_logic;						-- fast clock in
			i_data_i, q_data_i		: in signed(BIT_SIZE-1 downto 0);	-- data in
			i_data_o, q_data_o		: out signed(BIT_SIZE-1 downto 0);	-- data out
			trig_i					: in std_logic;						-- trigger in
			drdy_o					: out std_logic						-- data ready out
		);
	end component;
	
	component fir_channel_6_25 is
		generic(
			TAPS_NUM	: integer := 81;
			SAMP_WIDTH	: integer := 16
		);
		port(
			clk_i		: in std_logic;							-- fast clock in
			data_i		: in signed(SAMP_WIDTH-1 downto 0);		-- data in
			data_o		: out signed(SAMP_WIDTH-1 downto 0);	-- data out
			trig_i		: in std_logic;							-- trigger in
			drdy_o		: out std_logic							-- data ready out
		);
	end component;
	
	component fir_channel_12_5 is
		generic(
			TAPS_NUM	: integer := 81;
			SAMP_WIDTH	: integer := 16
		);
		port(
			clk_i		: in std_logic;							-- fast clock in
			data_i		: in signed(SAMP_WIDTH-1 downto 0);		-- data in
			data_o		: out signed(SAMP_WIDTH-1 downto 0);	-- data out
			trig_i		: in std_logic;							-- trigger in
			drdy_o		: out std_logic							-- data ready out
		);
	end component;
	
	component fir_channel_25 is
		generic(
			TAPS_NUM	: integer := 81;
			SAMP_WIDTH	: integer := 16
		);
		port(
			clk_i		: in std_logic;							-- fast clock in
			data_i		: in signed(SAMP_WIDTH-1 downto 0);		-- data in
			data_o		: out signed(SAMP_WIDTH-1 downto 0);	-- data out
			trig_i		: in std_logic;							-- trigger in
			drdy_o		: out std_logic							-- data ready out
		);
	end component;
	
	signal i_flt0, i_flt1, i_flt2			: signed(SAMP_WIDTH-1 downto 0) := (others => '0');
	signal q_flt0, q_flt1, q_flt2			: signed(SAMP_WIDTH-1 downto 0) := (others => '0');
	signal i_dec0, i_dec1, i_dec2			: signed(SAMP_WIDTH-1 downto 0) := (others => '0');
	signal q_dec0, q_dec1, q_dec2			: signed(SAMP_WIDTH-1 downto 0) := (others => '0');
	
	signal i_rdy0, i_rdy1, i_rdy2			: std_logic := '0';
	signal q_rdy0, q_rdy1, q_rdy2			: std_logic := '0';
	signal i_rdy3_0, i_rdy3_1, i_rdy3_2		: std_logic := '0';
	signal q_rdy3_0, q_rdy3_1, q_rdy3_2		: std_logic := '0';
	
	signal rdy_d0, rdy_d1, rdy_d2			: std_logic := '0';
	
	signal i_o0, i_o1, i_o2					: signed(SAMP_WIDTH-1 downto 0) := (others => '0');
	signal q_o0, q_o1, q_o2					: signed(SAMP_WIDTH-1 downto 0) := (others => '0');
begin
	---------------------------- STAGE 1 ----------------------------
	i_fir_hb0: fir_halfband
	port map(
		clk_i		=> clk_i,
		data_i		=> i_i,
		data_o		=> i_flt0,
		trig_i		=> trig_i,
		drdy_o		=> i_rdy0
	);
	
	q_fir_hb0: fir_halfband
	port map(
		clk_i		=> clk_i,
		data_i		=> q_i,
		data_o		=> q_flt0,
		trig_i		=> trig_i,
		drdy_o		=> q_rdy0
	);
	
	decim0: decim
	generic map(
		DECIM		=> 2,
		BIT_SIZE	=> 16
	)
	port map(
		clk_i		=> clk_i,
		i_data_i	=> i_flt0(14 downto 0) & '0',
		q_data_i	=> q_flt0(14 downto 0) & '0',
		i_data_o	=> i_dec0,
		q_data_o	=> q_dec0,
		trig_i		=> i_rdy0 and q_rdy0,
		drdy_o		=> rdy_d0
	);
	
	---------------------------- STAGE 2 ----------------------------
	i_fir_hb1: fir_halfband
	port map(
		clk_i		=> clk_i,
		data_i		=> i_dec0,
		data_o		=> i_flt1,
		trig_i		=> rdy_d0,
		drdy_o		=> i_rdy1
	);
	
	q_fir_hb1: fir_halfband
	port map(
		clk_i		=> clk_i,
		data_i		=> q_dec0,
		data_o		=> q_flt1,
		trig_i		=> rdy_d0,
		drdy_o		=> q_rdy1
	);
	
	decim1: decim
	generic map(
		DECIM		=> 2,
		BIT_SIZE	=> 16
	)
	port map(
		clk_i		=> clk_i,
		i_data_i	=> i_flt1(14 downto 0) & '0',
		q_data_i	=> q_flt1(14 downto 0) & '0',
		i_data_o	=> i_dec1,
		q_data_o	=> q_dec1,
		trig_i		=> i_rdy1 and q_rdy1,
		drdy_o		=> rdy_d1
	);
	
	---------------------------- STAGE 3 ----------------------------
	i_fir_hb2: fir_halfband
	port map(
		clk_i		=> clk_i,
		data_i		=> i_dec1,
		data_o		=> i_flt2,
		trig_i		=> rdy_d1,
		drdy_o		=> i_rdy2
	);
	
	q_fir_hb2: fir_halfband
	port map(
		clk_i		=> clk_i,
		data_i		=> q_dec1,
		data_o		=> q_flt2,
		trig_i		=> rdy_d1,
		drdy_o		=> q_rdy2
	);
	
	decim2: decim
	generic map(
		DECIM		=> 2,
		BIT_SIZE	=> 16
	)
	port map(
		clk_i		=> clk_i,
		i_data_i	=> i_flt2(14 downto 0) & '0',
		q_data_i	=> q_flt2(14 downto 0) & '0',
		i_data_o	=> i_dec2,
		q_data_o	=> q_dec2,
		trig_i		=> i_rdy2 and q_rdy2,
		drdy_o		=> rdy_d2
	);
	
	---------------------------- STAGE 4 ----------------------------
	i_fir_ch0: fir_channel_6_25
	port map(
		clk_i		=> clk_i,
		data_i		=> i_dec2,
		data_o		=> i_o0,
		trig_i		=> rdy_d2,
		drdy_o		=> i_rdy3_0
	);
	
	q_fir_ch0: fir_channel_12_5
	port map(
		clk_i		=> clk_i,
		data_i		=> q_dec2,
		data_o		=> q_o0,
		trig_i		=> rdy_d2,
		drdy_o		=> q_rdy3_0
	);
	
	i_fir_ch1: fir_channel_12_5
	port map(
		clk_i		=> clk_i,
		data_i		=> i_dec2,
		data_o		=> i_o1,
		trig_i		=> rdy_d2,
		drdy_o		=> i_rdy3_1
	);
	
	q_fir_ch1: fir_channel_12_5
	port map(
		clk_i		=> clk_i,
		data_i		=> q_dec2,
		data_o		=> q_o1,
		trig_i		=> rdy_d2,
		drdy_o		=> q_rdy3_1
	);
	
	i_fir_ch2: fir_channel_25
	port map(
		clk_i		=> clk_i,
		data_i		=> i_dec2,
		data_o		=> i_o2,
		trig_i		=> rdy_d2,
		drdy_o		=> i_rdy3_2
	);
	
	q_fir_ch2: fir_channel_25
	port map(
		clk_i		=> clk_i,
		data_i		=> q_dec2,
		data_o		=> q_o2,
		trig_i		=> rdy_d2,
		drdy_o		=> q_rdy3_2
	);
	
	-- select the right signals
	with ch_width select
    drdy_o <= i_rdy3_0 and q_rdy3_0	when "00",
       i_rdy3_1 and q_rdy3_1		when "01",
	   i_rdy3_2 and q_rdy3_2		when "10",
       '0'							when others;
	   
	with ch_width select
    i_o <= i_o0			when "00",
       i_o1				when "01",
	   i_o2				when "10",
       (others => '0')	when others;
	   
	with ch_width select
    q_o <= q_o0			when "00",
       q_o1				when "01",
	   q_o2				when "10",
       (others => '0')	when others;
end magic;
