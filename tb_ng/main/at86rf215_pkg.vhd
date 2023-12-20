-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2023, Lars Asplund lars.anders.asplund@gmail.com

library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.com_context;
use vunit_lib.stream_master_pkg.all;
use vunit_lib.stream_slave_pkg.all;
use vunit_lib.sync_pkg.all;
use vunit_lib.integer_vector_ptr_pkg.all;
use vunit_lib.queue_pkg.all;

package at86rf215_pkg is
  type at86rf215_master_t is record
    p_actor : actor_t;
  end record;

  type at86rf215_slave_t is record
    p_actor : actor_t;
  end record;

  impure function new_at86rf215_master return at86rf215_master_t;
  impure function new_at86rf215_slave return at86rf215_slave_t;

  impure function as_stream(at86rf215_master : at86rf215_master_t) return stream_master_t;
  impure function as_stream(at86rf215_slave : at86rf215_slave_t) return stream_slave_t;
  impure function as_sync(at86rf215_master : at86rf215_master_t) return sync_handle_t;
  impure function as_sync(at86rf215_slave : at86rf215_slave_t) return sync_handle_t;
  function rf_iq(i : std_logic_vector(12 downto 0); q : std_logic_vector(12 downto 0)) return std_logic_vector;
end package;

package body at86rf215_pkg is

  impure function new_at86rf215_master return at86rf215_master_t is
  begin
    return (p_actor => new_actor);
  end;

  impure function new_at86rf215_slave return at86rf215_slave_t is
  begin
    return (p_actor => new_actor);
  end;

  impure function as_stream(at86rf215_master : at86rf215_master_t) return stream_master_t is
  begin
    return stream_master_t'(p_actor => at86rf215_master.p_actor);
  end;

  impure function as_stream(at86rf215_slave : at86rf215_slave_t) return stream_slave_t is
  begin
    return stream_slave_t'(p_actor => at86rf215_slave.p_actor);
  end;

  impure function as_sync(at86rf215_master : at86rf215_master_t) return sync_handle_t is
  begin
    return at86rf215_master.p_actor;
  end;

  impure function as_sync(at86rf215_slave : at86rf215_slave_t) return sync_handle_t is
  begin
    return at86rf215_slave.p_actor;
  end;

  function rf_iq(i : std_logic_vector(12 downto 0); q : std_logic_vector(12 downto 0)) return std_logic_vector is
    variable retval : std_logic_vector(31 downto 0) := (others => '0');
  begin
    retval(31 downto 30) := "01";
    retval(29 downto 17) := i;
    retval(15 downto 14) := "10";
    retval(13 downto 1) := q;
    return retval;
  end;

  end package body;
