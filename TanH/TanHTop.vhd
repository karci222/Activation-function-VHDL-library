library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TanHTop is
  generic (
	bit_width : integer := 16;
	fractional_bits : integer := 12
	);
  port (
    valid_in : in std_logic;
	valid_out : out std_logic;
    input  : in signed((bit_width - 1) downto 0);
	output : out signed((bit_width - 1) downto 0);
	clk    : in std_logic
	);
	
	
end TanHTop;

architecture behavioural of TanHTop is
  signal valid_in_reg, valid_in_next, valid_out_reg, valid_out_next : std_logic;
  signal input_reg, input_next, output_reg, output_next : signed ((bit_width - 1) downto 0);
  
  component tanh is
    generic (
	   bit_width : integer := 16;
	   fractional_bits : integer := 12
	 );
    port (
       --valid_in
	   --valid_out
       input  : in signed((bit_width - 1) downto 0);
	   output : out signed((bit_width - 1) downto 0);
	   clk    : in std_logic
	  );
  end component;
begin
  u1: entity work.tanh(PLATANH) generic map(bit_width => bit_width, fractional_bits => fractional_bits)
              port map(input => input_reg, output => output_next, clk => clk);          

  input_next <= input;
  valid_in_next <= valid_in;
  valid_out_next <= valid_in_reg;
  
  
  seq: process(clk)
  begin
    if (rising_edge(clk)) then
	    input_reg <= input_next;
		 valid_in_reg <= valid_in_next;
		 output_reg <= output_next;
		 valid_out_reg <= valid_out_next;
	 end if;
  end process;
  
  output<=output_reg;
  valid_out<=valid_out_reg;
end behavioural;


