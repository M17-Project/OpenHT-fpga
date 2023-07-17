-------------------------------------------------------------
-- CORDIC sincos resolver
--
-- Wojciech Kaczmarski, SP5WWP
-- M17 Project
-- July 2023
-------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity cordic is
    generic(
        RES_WIDTH       : natural := 16;
        ITER_NUM        : natural := 14;
        COMP_COEFF      : signed(RES_WIDTH-1 downto 0) := x"26DD"				-- this is the coeff for N=14 (0x4000=1.0)
    );
	port(
		clk_i           : in std_logic;                                 		-- clock in
		phase_i         : in unsigned(RES_WIDTH-1 downto 0);                    -- phase word in
        phase_valid_i   : in std_logic;                                         -- Phase word valid
        sin_o           : out signed(RES_WIDTH-1 downto 0) := (others => '0');  -- sine out
		cos_o           : out signed(RES_WIDTH-1 downto 0) := (others => '0');  -- cosine out
		valid_o         : out std_logic := '0'                          		-- data ready
	);
end cordic;

architecture magic of cordic is
    constant deg_90     : unsigned(RES_WIDTH-1 downto 0) := shift_right(to_unsigned(2**(RES_WIDTH-1), RES_WIDTH), 1);
    constant deg_180    : unsigned(RES_WIDTH-1 downto 0) := shift_left(deg_90, 1);
    constant deg_270    : unsigned(RES_WIDTH-1 downto 0) := deg_90+deg_180;

    type arr is array(0 to ITER_NUM-1) of signed(RES_WIDTH-1 downto 0);
    signal angles       : arr := (others => (others => '0'));
	signal sin_val      : signed(RES_WIDTH-1 downto 0) := COMP_COEFF;
	signal cos_val      : signed(RES_WIDTH-1 downto 0) := (others => '0');
	signal sin_next     : signed(RES_WIDTH-1 downto 0) := (others => '0');
	signal cos_next     : signed(RES_WIDTH-1 downto 0) := (others => '0');
    signal angle        : signed(RES_WIDTH-1 downto 0) := (others => '0');
    signal angle_next   : signed(RES_WIDTH-1 downto 0) := (others => '0');
    signal cnt          : integer := -1;
    signal left_half    : std_logic := '0';
begin
    -- compute angles at synthesis-time
    compute_angles: for i in 0 to ITER_NUM-1 generate
        angles(i) <= to_signed(integer(
            arctan(real(1)/real(2**i))/math_pi*real(2**(RES_WIDTH-1))
        ), RES_WIDTH);
    end generate;

	process(clk_i)
	begin
		if rising_edge(clk_i) then
            valid_o <= '0';
            if cnt=-1 and phase_valid_i = '1' then
                --  quadrant check
                if phase_i>deg_270 then
                    angle <= signed(phase_i);
                    left_half <= '0';
                elsif phase_i>deg_180 then
                    angle <= signed(phase_i+deg_180); -- add 180 degrees
                    left_half <= '1';
                elsif phase_i>deg_90 then
                     angle <= signed(phase_i-deg_180); -- subtract 180 degrees
                    left_half <= '1';
                else
                    angle <= signed(phase_i);
                    left_half <= '0';
                end if;

                sin_val <= COMP_COEFF;
                cos_val <= (others => '0');
            end if;

            if cnt=ITER_NUM-1 then
                --  quadrant check
                if left_half='0' then
                    sin_o <= cos_next; -- this swap is intentional
                    cos_o <= sin_next;
                else
                    sin_o <= -cos_next; -- this swap is intentional
                    cos_o <= -sin_next;
                end if;
                valid_o <= '1';
            end if;

            if cnt<ITER_NUM then
                if cnt>-1 then
                    sin_val <= sin_next;
                    cos_val <= cos_next;
                    angle <= angle_next;
                    cnt <= cnt + 1;
                else
                    if phase_valid_i then
                        cnt <= cnt + 1;
                    end if;
                end if;
            else
                cnt <= -1;
            end if;
        end if;
	end process;

    process(sin_val, cos_val, angle, cnt)
    begin
        if cnt=-1 then
            sin_next <= sin_val - cos_val;
            cos_next <= cos_val + sin_val;
            angle_next <= angle;
        elsif cnt>-1 and cnt<ITER_NUM then
            if angle>0 then
                sin_next <= sin_val - shift_right(cos_val, cnt);
                cos_next <= cos_val + shift_right(sin_val, cnt);
                angle_next <= angle - angles(cnt);
            else
                sin_next <= sin_val + shift_right(cos_val, cnt);
                cos_next <= cos_val - shift_right(sin_val, cnt);
                angle_next <= angle + angles(cnt);
            end if;
        end if;
    end process;
end magic;
