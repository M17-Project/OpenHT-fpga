--fifo_dc test
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fifo_dc_test is
	--
end fifo_dc_test;

architecture sim of fifo_dc_test is
	component fifo_dc is
        generic(
            DEPTH       : natural;
            D_WIDTH     : natural
        );
        port(
            en_i        : in std_logic;
            clk_a_i     : in std_logic;
            clk_b_i     : in std_logic;
            data_i      : in std_logic_vector;
            data_o      : out std_logic_vector;
            fifo_ae     : out std_logic -- fifo almost empty
        );
	end component;

	signal clk_a : std_logic := '0';
	signal clk_b : std_logic := '0';
	signal fifo_ae : std_logic := '0';
	signal data_i : std_logic_vector(15 downto 0) := (others => '0');
	signal data_o : std_logic_vector(15 downto 0) := (others => '0');
	signal nrst_i : std_logic := '1';
begin
	dut: fifo_dc
	generic map(
        DEPTH => 16,
        D_WIDTH => 16
	)
	port map(
        en_i => '1',
        clk_a_i => clk_a,
        clk_b_i => clk_b,
        data_i => data_i,
        data_o => data_o,
        fifo_ae => fifo_ae
	);

	--process
	--begin
        --
	--end process;

	process
	begin
        wait for 0.35 ms;

        --write 16
        for i in 1 to 16*2 loop
            data_i <= std_logic_vector(to_unsigned(i/2, 16)) when i<32;
            clk_a <= not clk_a;
            wait for 0.1 ms;
        end loop;

        --data_i <= (others => '0');
        wait for 0.5 ms;

        -- read 16
        for i in 1 to 16*2 loop
            wait for 0.1 ms;
            clk_b <= not clk_b;
        end loop;

        wait for 0.5 ms;

        -- write 16
        data_i <= std_logic_vector(to_unsigned(100, 16));
        wait for 0.1 ms;
        for i in 1 to 16*2 loop
            if i>1 and i<32 then data_i <= std_logic_vector(to_unsigned(i/2+100, 16)); end if;
            clk_a <= not clk_a;
            wait for 0.1 ms;
        end loop;

        --data_i <= (others => '0');
        wait for 0.5 ms;

        -- read 16
        for i in 1 to 16*2 loop
            wait for 0.1 ms;
            clk_b <= not clk_b;
        end loop;

        wait for 0.5 ms;

        -- write 5
        data_i <= std_logic_vector(to_unsigned(0, 16));
        wait for 0.1 ms;
        for i in 1 to 5*2 loop
            if i>1 and i<10 then data_i <= std_logic_vector(to_unsigned(i/2, 16)); end if;
            clk_a <= not clk_a;
            wait for 0.1 ms;
        end loop;

        --data_i <= (others => '0');
        wait for 0.5 ms;

        -- read 16
        for i in 1 to 16*2 loop
            wait for 0.1 ms;
            clk_b <= not clk_b;
        end loop;

        wait for 0.5 ms;

        -- write 20
        data_i <= std_logic_vector(to_unsigned(100, 16));
        wait for 0.1 ms;
        for i in 1 to 20*2 loop
            if i>1 and i<40 then data_i <= std_logic_vector(to_unsigned(i/2+100, 16)); end if;
            clk_a <= not clk_a;
            wait for 0.1 ms;
        end loop;

        data_i <= (others => '0');
        wait for 0.5 ms;

        -- read 16
        for i in 1 to 16*2 loop
            wait for 0.1 ms;
            clk_b <= not clk_b;
        end loop;

        wait for 0.5 ms;

        -- reset
        --nrst_i <= '0';
        --wait for 0.1 ms;
        --nrst_i <= '1';
        --wait for 0.1 ms;
	end process;
end sim;
