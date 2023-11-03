library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

architecture inferred of dpram_1024x16 is
    type mem_array_t is array (0 to 2047) of std_logic_vector(15 downto 0);
    signal mem_array : mem_array_t := (others => (others => '0'));
begin
    process (clk)
    begin
        if rising_edge(clk) then
            -- Port A
            if ena then
                douta <= mem_array(to_integer(unsigned(addra)));
                if wra then
                    mem_array(to_integer(unsigned(addra))) <= dina;
                end if;
            end if;

            -- Port B
            if enb then
                doutb <= mem_array(to_integer(unsigned(addrb)));
                if wrb then
                    mem_array(to_integer(unsigned(addrb))) <= dinb;
                end if;
            end if;

        end if;
    end process;

end architecture inferred;
