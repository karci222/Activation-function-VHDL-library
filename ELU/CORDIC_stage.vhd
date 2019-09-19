library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

entity CORDIC_stage is
  generic(bit_width : integer := 16;
		  fractional_bits : integer := 12;
		  iter_bits : integer := 5
		  );
  port(x_in : in signed((bit_width - 1) downto 0);
	   y_in : in signed((bit_width - 1) downto 0);
	   z_in : in signed((bit_width - 1) downto 0);
	   coor : in std_logic; -- 0 positive, 1 negative
	   rom_in : in signed((bit_width - 1) downto 0);
	   i_in : in signed((iter_bits - 1) downto 0);
	   x_out : out signed((bit_width - 1) downto 0);
	   y_out : out signed((bit_width - 1) downto 0);
	   z_out : out signed((bit_width - 1) downto 0)
	   );
end CORDIC_stage;

architecture behavioural of CORDIC_stage is
  signal x_neg, y_neg, z_neg, rom_in_neg : signed((bit_width - 1) downto 0);
  signal di : std_logic := '1'; -- 0 positive, 1 negative
  signal x_shifted_pos_i, y_shifted_pos_i, x_shifted_neg_i, y_shifted_neg_i: signed ((bit_width - 1) downto 0);
  signal x_sum_neg_i, y_sum_neg_i: signed ((bit_width - 1) downto 0);
  signal x_sum_neg_i_negative, y_sum_neg_i_negative: signed ((bit_width - 1) downto 0);
  signal x_term, y_term, z_term: signed((bit_width - 1) downto 0);
  signal shift_neg_i: signed((iter_bits - 1) downto 0);
begin
  di <= '0' when z_in >= 0 else
        '1';
		
  x_neg <= -x_in;
  y_neg <= -y_in;
  rom_in_neg <= -rom_in;
  
  shift_neg_i <= abs(i_in - 2);
  
  x_shifted_neg_i <= shift_right(x_in, to_integer(shift_neg_i));
  x_shifted_pos_i <= shift_right(x_in, to_integer(i_in));
  
  y_shifted_neg_i <= shift_right(y_in, to_integer(shift_neg_i));
  y_shifted_pos_i <= shift_right(y_in, to_integer(i_in));
  	   
  x_sum_neg_i <= x_in - x_shifted_neg_i;
  y_sum_neg_i <= y_in - y_shifted_neg_i;
  
  x_term <= -x_sum_neg_i when di = '1' and  i_in <= 0 else
			x_sum_neg_i when i_in <= 0 else
			-x_shifted_pos_i when di = '1' else
			x_shifted_pos_i;

  y_term <= -y_sum_neg_i when (di xor coor) = '1' and  i_in <= 0 else
            y_sum_neg_i when i_in <= 0 else
            -y_shifted_pos_i when (di xor coor) = '1' else
            y_shifted_pos_i;
  
  z_term <= rom_in_neg when di = '1' else
			rom_in;

  x_out <= x_in - y_term;
  y_out <= y_in + x_term;
  z_out <= z_in - z_term;
  
end behavioural;