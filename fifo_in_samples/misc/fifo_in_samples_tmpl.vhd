component fifo_in_samples is
    port(
        wr_clk_i: in std_logic;
        rd_clk_i: in std_logic;
        rst_i: in std_logic;
        rp_rst_i: in std_logic;
        wr_en_i: in std_logic;
        rd_en_i: in std_logic;
        wr_data_i: in std_logic_vector(15 downto 0);
        full_o: out std_logic;
        empty_o: out std_logic;
        almost_empty_o: out std_logic;
        rd_data_o: out std_logic_vector(15 downto 0)
    );
end component;

__: fifo_in_samples port map(
    wr_clk_i=>,
    rd_clk_i=>,
    rst_i=>,
    rp_rst_i=>,
    wr_en_i=>,
    rd_en_i=>,
    wr_data_i=>,
    full_o=>,
    empty_o=>,
    almost_empty_o=>,
    rd_data_o=>
);
