--------------------------------------------------------------------
--  _    __ __  __ ____   __   =                                  --
-- | |  / // / / // __ \ / /   =                                  --
-- | | / // /_/ // / / // /    =    .__  |/ _/_  .__   .__    __  --
-- | |/ // __  // /_/ // /___  =   /___) |  /   /   ) /   )  (_ ` --
-- |___//_/ /_//_____//_____/  =  (___  /| (_  /     (___(_ (__)  --
--                           =====     /                          --
--                            ===                                 --
-----------------------------  =  ----------------------------------
--# cordic.vhdl - CORDIC operations for vector rotation and sin/cos generation
--# Freely available from VHDL-extras (http://github.com/kevinpt/vhdl-extras)
--#
--# Copyright © 2014 Kevin Thibedeau
--# (kevin 'period' thibedeau 'at' gmail 'punto' com)
--#
--# Permission is hereby granted, free of charge, to any person obtaining a
--# copy of this software and associated documentation files (the "Software"),
--# to deal in the Software without restriction, including without limitation
--# the rights to use, copy, modify, merge, publish, distribute, sublicense,
--# and/or sell copies of the Software, and to permit persons to whom the
--# Software is furnished to do so, subject to the following conditions:
--#
--# The above copyright notice and this permission notice shall be included in
--# all copies or substantial portions of the Software.
--#
--# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
--# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
--# DEALINGS IN THE SOFTWARE.
--#
--# DEPENDENCIES: pipelining
--#
--# DESCRIPTION:
--#  This package provides components and procedures used to implement the CORDIC
--#  algorithm. A variety of implementations are provided to meet different design
--#  requirements. These implementations are flexible in all parameters and are not
--#  constrained by a fixed arctan table.
--#
--#  A pair of procedures provide pure combinational CORDIC implementations:
--#  * rotate procedure - Combinational CORDIC in rotation mode
--#  * vector procedure - Combinational CORDIC in vectoring mode
--#
--#  The CORDIC components provide both rotation or vectoring mode based on
--#  a Mode input:
--#  * cordic_sequential     - Iterative algorithm with minimal hardware
--#  * cordic_pipelined      - One pipeline stage per iteration
--#  * cordic_flex_pipelined - Selectable pipeline stages independent of
--#                            the number of iterations
--#  A set of wrapper components are provided to conveniently generate
--#  sin and cos:
--#  * sincos_sequential - Iterative algorithm with minimal hardware
--#  * sincos_pipelined  - One pipeline stage per iteration
--#

--#  These CORDIC implementations take a common set of parameters. There are
--#  X, Y, and Z inputs defining the initial vector and angle value. The result
--#  is produced in a set of X, Y, and Z outputs. Depending on which CORDIC
--#  operation you are using, some inputs may be constants and some outputs
--#  may be ignored.

--#  The CORDIC algorithm performs pseudo-rotations that cause an unwanted growth
--#  in the length of the result vector. This growth is a gain parameter that
--#  approaches 1.647 but is dependent on the number of iterations performed. The
--#  cordic_gain() function produces a real-valued gain for a specified number of
--#  iterations. This can be converted to a synthesizable integer constant with
--#  the following:
--#    gain := integer(cordic_gain(ITERATIONS) * 2.0 ** FRAC_BITS)
--#  With some operations you can adjust the input vector by dividing by the gain
--#  ahead of time. In other cases you have to correct for the gain after the
--#  CORDIC operation. The gain from pseudo-rotation never affects the Z
--#  parameter.

--#  The following are some of the operations that can be performed with the
--#  CORDIC algorithm:
--#
--#  sin and cos:
--#    X0 = 1/gain, Y0 = 0, Z0 = angle; rotate --> sin(Z0) in Y, cos(Z0) in X
--#
--#  polar to rectangular:
--#    X0 = magnitude, Y0 = 0, Z0 = angle; rotate --> gain*X in X, gain*Y in Y
--#
--#  arctan:
--#    Y0 = y, X0 = x, Z0 = 0; vector --> arctan(Y0/X0) in Z
--#
--#  rectangular to polar:
--#    Y0 = y, X0 = x, Z0 = 0; vector --> gain*magnitude in X, angle in Z

--#  The X and Y parameters are represented as unconstrained signed vectors. You
--#  establish the precision of a CORDIC implementation by selecting the width of
--#  these vectors. The interpretation of these numbers does not affect the
--#  internal CORDIC implementation but most implementations will need them to be
--#  fixed point integers with the maximum number of fractional bits possible.
--#  When calculating sin and cos, the output is constrained to the range +/-1.0.
--#  Thus we only need to reserve two bits for the sign and integral portion of
--#  the numbers. The remaining bits can be fractional. Operations that work on
--#  larger vectors outside of the unit circle need to ensure that a sufficient
--#  number of integer bits are present to prevent overflow of X and Y.
--#  The angle parameter Z should be provided in units of binary-radians or brads.
--#  2*PI radians = 2**size brads for "size" number of bits. This maps the entire
--#  binary range of Z to the unit circle. The Z parameter is represented by the
--#  signed type in all of these CORDIC implementations but it can be viewed as
--#  an unsigned value. Because of the circular mapping, signed and unsigned
--#  angles are equivalent. It is easiest to think of the angle Z as an integer
--#  without fractional bits like X and Y. There is no risk of overflowing Z
--#  becuase of the circular mapping.

--#  The circular CORDIC algorithm only converges between angles of +/- 99.7
--#  degrees. If you want to use angles covering all four quadrants you must
--#  condition the inputs to the CORDIC algorithm using the adjust_angle()
--#  procedure. This will perform conditional negation on X and Y and flip the
--#  sign bit on Z to bring vectors in quadrants 2 and 3 (1-based) into quadrants
--#  1 and 4.

--#  EXAMPLE USAGE:
--#
--------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

--library extras;
use work.cordic.all;

entity cordic_sincos is
  generic (
    SIZE       : positive;
    ITERATIONS : positive;
    TRUNC_SIZE : positive;
    RESET_ACTIVE_LEVEL : std_ulogic := '1'
  );
  port (
    Clock : in std_ulogic;
    Reset : in std_ulogic;

    Data_valid   : in std_ulogic;  --# Load new input data
    Busy         : out std_ulogic; --# Generating new result
    Result_valid : out std_ulogic; --# Flag when result is valid
    Mode         : in cordic_mode; --# Rotation or vector mode selection

    X : in signed(SIZE-1 downto 0);
    Y : in signed(SIZE-1 downto 0);
    Z : in signed(SIZE-1 downto 0);

    X_result : out signed(TRUNC_SIZE-1 downto 0);
    Y_result : out signed(TRUNC_SIZE-1 downto 0);
    Z_result : out signed(TRUNC_SIZE-1 downto 0)
  );
end entity;

architecture rtl of cordic_sincos is
    signal data_valid_r : std_ulogic;
    signal Xa : signed(SIZE-1 downto 0);
    signal Ya : signed(SIZE-1 downto 0);
    signal Za : signed(SIZE-1 downto 0);

    signal X_result_i : signed(SIZE-1 downto 0);
    signal Y_result_i : signed(SIZE-1 downto 0);
    signal Z_result_i : signed(SIZE-1 downto 0);
    signal X_result_rnd : signed(SIZE-1 downto 0);
    signal Y_result_rnd : signed(SIZE-1 downto 0);
    signal Z_result_rnd : signed(SIZE-1 downto 0);
    
    signal X_rnd : signed(SIZE-1 downto 0);
    signal Y_rnd : signed(SIZE-1 downto 0);
    signal Z_rnd : signed(SIZE-1 downto 0);
    
    signal Result_valid_i : std_ulogic;

    signal X_lsb : std_ulogic;
    signal Y_lsb : std_ulogic;
    signal Z_lsb : std_ulogic;
begin

    -- LSBs for rounding
    X_lsb <= X_result_i(SIZE-TRUNC_SIZE);
    Y_lsb <= Y_result_i(SIZE-TRUNC_SIZE);
    Z_lsb <= Z_result_i(SIZE-TRUNC_SIZE);

    -- Actual truncated values
    X_result <= X_result_rnd(SIZE-1 downto SIZE-TRUNC_SIZE);
    Y_result <= Y_result_rnd(SIZE-1 downto SIZE-TRUNC_SIZE);
    Z_result <= Z_result_rnd(SIZE-1 downto SIZE-TRUNC_SIZE);

    X_rnd <= (TRUNC_SIZE-1 downto 0 => '0') & X_lsb & (SIZE - TRUNC_SIZE - 2 downto 0 => not X_lsb);
    Y_rnd <= (TRUNC_SIZE-1 downto 0 => '0') & Y_lsb & (SIZE - TRUNC_SIZE - 2 downto 0 => not Y_lsb);
    Z_rnd <= (TRUNC_SIZE-1 downto 0 => '0') & Z_lsb & (SIZE - TRUNC_SIZE - 2 downto 0 => not Z_lsb);


    process (Clock)
    begin
        if rising_edge(Clock) then
            -- Input
            data_valid_r <= data_valid;
            adjust_angle(X, Y, Z, Xa, Ya, Za);

            -- Output
            X_result_rnd <= X_result_i + X_rnd;
            Y_result_rnd <= Y_result_i + Y_rnd;
            Z_result_rnd <= Z_result_i + Z_rnd;
            Result_valid <= Result_valid_i;
        end if;
    end process;

	dut: entity work.cordic_sequential generic map(
        SIZE => SIZE,
        ITERATIONS => ITERATIONS,
        RESET_ACTIVE_LEVEL => RESET_ACTIVE_LEVEL
    )
    port map(
        Clock => Clock,
        Reset => Reset,

        X => Xa,
        Y => Ya,
        Z => Za,
        Data_Valid => data_valid_r,
        mode => mode,

        X_result => X_result_i,
        Y_result => Y_result_i,
        Z_result => Z_result_i,
        Result_valid => Result_valid_i
);

end architecture;