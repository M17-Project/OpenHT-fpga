library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity dpram_1024x16 is
    port (
        clk : in std_logic;
        ena : in std_logic;
        enb : in std_logic;
        wra : in std_logic;
        wrb : in std_logic;
        addra : in std_logic_vector(9 downto 0);
        addrb : in std_logic_vector(9 downto 0);
        dina : in std_logic_vector(15 downto 0);
        dinb : in std_logic_vector(15 downto 0);
        douta : out std_logic_vector(15 downto 0);
        doutb : out std_logic_vector(15 downto 0)   
    );
end entity dpram_1024x16;
