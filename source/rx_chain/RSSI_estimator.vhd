-------------------------------------------------------------
-- RSSI estimator
--
--
-- Frédéric Druppel, ON4PFD, fredcorp.cc
-- Sebastien, ON4SEB
-- M17 Project
-- November 2023
--
-- TODO : define TODO's
--
-------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.axi_stream_pkg.all;
use work.cordic_pkg.all;
use work.apb_pkg.all;

entity FM_demodulator is
  generic  (
    PSEL_ID : natural
  );
  port (
    clk_i    : in std_logic;            -- Clock, from upstream
    nrst_i   : in std_logic;            -- Reset, from upstream

    s_apb_o  : out apb_out_t;           -- slave apb interface out, to upstream
    s_apb_i  : in apb_in_t;             -- slave apb interface in, from upstream

    s_axis_o : out axis_out_iq_t;       -- slave out, to upstream entity (ready)                      -- This entity's ready to receive flag (tready)
    s_axis_i : in axis_in_iq_t;         -- slave in, from upstream entity (data and valid)            -- IQ signal (tdata), valid (tvalid)
    m_axis_o : out axis_in_iq_t;        -- master out, to downstream entity (data and valid)          -- Demodulated signal (tdata), valid (tvalid)
    m_axis_i : in axis_out_iq_t         -- master input, from downstream entity (ready)               -- From next entity's ready to receive flag (tready)
  );
end entity;