-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2023, Lars Asplund lars.anders.asplund@gmail.com

library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
use vunit_lib.stream_master_pkg.all;
use vunit_lib.queue_pkg.all;
use vunit_lib.sync_pkg.all;

use work.at86rf215_pkg.all;

entity at86rf215_master is
  generic (
    radio_if : at86rf215_master_t);
  port (
    ddr_clk : out std_logic;
    ddr_data : out std_logic_vector(1 downto 0));
end entity;

architecture a of at86rf215_master is
begin

  main : process
    procedure at86rf215_send(data : std_logic_vector;
                        signal ddr_clk : out std_logic;
                        signal ddr_data : out std_logic_vector) is
      constant time_per_bit : time := 15 ns;

      procedure send_bit(value : std_logic_vector) is
      begin
        ddr_clk <= '0';
        wait for time_per_bit/2;
        ddr_clk <= '1';
        ddr_data <= value;
        wait for time_per_bit/2;
      end procedure;
    begin
      debug("Sending " & to_string(data));
      for i in 15 downto 0 loop
        send_bit(data(i*2+1 downto i*2));
      end loop;

      for i in 0 to 8 loop
        for j in 0 to 15 loop
          send_bit("00");
        end loop;
      end loop;
    end procedure;

    variable msg : msg_t;
    variable msg_type : msg_type_t;
  begin
    receive(net, radio_if.p_actor, msg);
    msg_type := message_type(msg);

    handle_sync_message(net, msg_type, msg);

    if msg_type = stream_push_msg then
      at86rf215_send(pop_std_ulogic_vector(msg), ddr_clk, ddr_data);
    else
      unexpected_msg_type(msg_type);
    end if;
  end process;

end architecture;
