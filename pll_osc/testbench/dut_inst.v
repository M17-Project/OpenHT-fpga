    pll_osc u_pll_osc(.clki_i(clki_i),
        .rstn_i(rstn_i),
        .clkop_o(clkop_o),
        .clkos_o(clkos_o),
        .clkos2_o(clkos2_o),
        .lock_o(lock_o));
