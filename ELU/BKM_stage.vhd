library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity BKM_STAGE is
	generic(bit_width : integer := 16;
			fractional_bits : integer := 12;
			iter_bits: integer := 4);
	port(E_in : in signed((bit_width - 1) downto 0);
		 L_in : in signed((bit_width - 1) downto 0);
		 logn_comp_in : in signed((bit_width - 1) downto 0);
		 logn_in : in signed((bit_width - 1) downto 0);
		 iteration : in unsigned((iter_bits - 1) downto 0);
		 E_out : out signed((bit_width - 1) downto 0);
		 L_out : out signed((bit_width - 1) downto 0));
		 
end BKM_STAGE;

architecture rtl of BKM_STAGE is
	signal E_shifted : signed((bit_width - 1) downto 0);
	signal di : std_logic;
begin
  E_shifted <= shift_right(E_in, to_integer(iteration));
  di <= '1' when L_in >= logn_comp_in else
		'0';

  E_out <= E_in + E_shifted when di = '1' else
		   E_in;
  
  L_out <= L_in - logn_in when di = '1' else
		   L_in;
end rtl;
