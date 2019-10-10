library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;


entity TanH is
  generic (
	bit_width : integer := 16;
	fractional_bits : integer := 12
	);
  port (
    valid_in : in std_logic;
	valid_out : out std_logic;
    input : in signed((bit_width - 1) downto 0);
	output : out signed((bit_width - 1) downto 0);
	clk : in std_logic
	);
end TanH;


architecture PLATANH of TanH is
  constant max_neg : signed((bit_width-1) downto 0) := to_signed(integer(-2**(bit_width-1)), bit_width);
  constant neg_one : signed((bit_width-1) downto 0) := to_signed(integer(-1.0*2**(fractional_bits)), bit_width);
  
  constant a : signed((bit_width-1) downto 0) := to_signed(integer(5.5799959*(2**fractional_bits)), bit_width);
  constant b : signed((bit_width-1) downto 0) := to_signed(integer(3.02*(2**fractional_bits)), bit_width);
  constant c : signed((bit_width-1) downto 0) := to_signed(integer(2.02*(2**fractional_bits)), bit_width);
  constant d : signed((bit_width-1) downto 0) := to_signed(integer(1.475*(2**fractional_bits)), bit_width);-- number 5.0
  constant e : signed((bit_width-1) downto 0) := to_signed(integer(1.125*(2**fractional_bits)), bit_width);-- number 2.375
  constant f : signed((bit_width-1) downto 0) := to_signed(integer(0.5*(2**fractional_bits)), bit_width);-- number 1.0
  
  constant op1   : signed((bit_width-1) downto 0) := to_signed(integer(1.0*(2**fractional_bits)), bit_width);-- number 1.0
  constant op2   : signed((bit_width-1) downto 0) := to_signed(integer(0.9986377*(2**fractional_bits)), bit_width);-- number 0.84375
  constant op3   : signed((bit_width-1) downto 0) := to_signed(integer(0.905*(2**fractional_bits)), bit_width);-- number 0.625
  constant op4   : signed((bit_width-1) downto 0) := to_signed(integer(0.715625*(2**fractional_bits)), bit_width);-- number 0.5
  constant op5   : signed((bit_width-1) downto 0) := to_signed(integer(0.53125*(2**fractional_bits)), bit_width);-- number 0.5
  constant op6   : signed((bit_width-1) downto 0) := to_signed(integer(0.25*(2**fractional_bits)), bit_width);-- number 0.5
  constant op7   : signed((bit_width-1) downto 0) := to_signed(integer(0.0*(2**fractional_bits)), bit_width);-- number 0.5
  
  
  signal x, x_abs, x_shift_1, x_shift_2, x_shift_3, x_shift_4, x_shift_5, op_1, op_2, res, res_neg: signed((bit_width - 1) downto 0);
  signal sel: std_logic_vector(2 downto 0);
begin
  x <= input;
  x_abs <= abs(input);
  
  sel <= "000" when x_abs >= a else	
		 "001" when x_abs >= b else 
		 "010" when x_abs >= c else
         "011" when x_abs >= d else
		 "100" when x_abs >= e else
		 "101" when x_abs >= f else
		 "110";

  op_1 <= op1 when sel = "000" else
          op2 when sel = "001" else
		  op3 when sel = "010" else
		  op4 when sel = "011" else
		  op5 when sel = "100" else
		  op6 when sel = "101" else
		  op7;
	
  x_shift_1 <= shift_right(x_abs, 12);	
  x_shift_2 <= shift_right(x_abs, 5);
  x_shift_3 <= shift_right(x_abs, 3);
  x_shift_4 <= shift_right(x_abs, 2);
  x_shift_5 <= shift_right(x_abs, 1);
  
  
  op_2 <= op7      when sel = "000" else
		  x_shift_1 when sel = "001" else
		  x_shift_2 when sel = "010" else
		  x_shift_3 when sel = "011" else
		  x_shift_4 when sel = "100" else
		  x_shift_5 when sel = "101" else
		  x_abs;
		  
  res     <= op_1 + op_2;
  res_neg <= -res;
  
  output <= neg_one when (x = max_neg) else
			res_neg when x(bit_width-1) = '1'else
			res;
			
  valid_out <= valid_in;
end PLATANH;

architecture PLATANH_PIPELINED of TanH is
  constant max_neg : signed((bit_width-1) downto 0) := to_signed(integer(-2**(bit_width-1)), bit_width);
  constant neg_one : signed((bit_width-1) downto 0) := to_signed(integer(-1.0*2**(fractional_bits)), bit_width);
  
  constant a : signed((bit_width-1) downto 0) := to_signed(integer(5.5799959*(2**fractional_bits)), bit_width);
  constant b : signed((bit_width-1) downto 0) := to_signed(integer(3.02*(2**fractional_bits)), bit_width);
  constant c : signed((bit_width-1) downto 0) := to_signed(integer(2.02*(2**fractional_bits)), bit_width);
  constant d : signed((bit_width-1) downto 0) := to_signed(integer(1.475*(2**fractional_bits)), bit_width);-- number 5.0
  constant e : signed((bit_width-1) downto 0) := to_signed(integer(1.125*(2**fractional_bits)), bit_width);-- number 2.375
  constant f : signed((bit_width-1) downto 0) := to_signed(integer(0.5*(2**fractional_bits)), bit_width);-- number 1.0
  
  constant op1   : signed((bit_width-1) downto 0) := to_signed(integer(1.0*(2**fractional_bits)), bit_width);-- number 1.0
  constant op2   : signed((bit_width-1) downto 0) := to_signed(integer(0.9986377*(2**fractional_bits)), bit_width);-- number 0.84375
  constant op3   : signed((bit_width-1) downto 0) := to_signed(integer(0.905*(2**fractional_bits)), bit_width);-- number 0.625
  constant op4   : signed((bit_width-1) downto 0) := to_signed(integer(0.715625*(2**fractional_bits)), bit_width);-- number 0.5
  constant op5   : signed((bit_width-1) downto 0) := to_signed(integer(0.53125*(2**fractional_bits)), bit_width);-- number 0.5
  constant op6   : signed((bit_width-1) downto 0) := to_signed(integer(0.25*(2**fractional_bits)), bit_width);-- number 0.5
  constant op7   : signed((bit_width-1) downto 0) := to_signed(integer(0.0*(2**fractional_bits)), bit_width);-- number 0.5
  
  
  signal x, x_abs, x_shift_1, x_shift_2, x_shift_3, x_shift_4, x_shift_5, op_1, op_2, res, res_neg: signed((bit_width - 1) downto 0);
  signal sel: std_logic_vector(2 downto 0);
  signal op1_reg, op2_reg, op1_next, op2_next : signed((bit_width-1) downto 0); 
  signal valid_out_reg, valid_out_next, x_neg_next, x_neg_reg, x_max_next, x_max_reg : std_logic := '0';
begin
  x <= input;
  x_abs <= abs(input);
  valid_out_next <= valid_in;
  valid_out <= valid_out_reg;
  x_neg_next <= std_logic(x(bit_width-1));
  x_max_next <= '1' when (x = max_neg) else
                '0';
  
  sel <= "000" when x_abs >= a else	
		 "001" when x_abs >= b else 
		 "010" when x_abs >= c else
         "011" when x_abs >= d else
		 "100" when x_abs >= e else
		 "101" when x_abs >= f else
		 "110";

  op_1 <= op1 when sel = "000" else
          op2 when sel = "001" else
		  op3 when sel = "010" else
		  op4 when sel = "011" else
		  op5 when sel = "100" else
		  op6 when sel = "101" else
		  op7;
	
  op1_next <= op_1;
  
  x_shift_1 <= shift_right(x_abs, 12);	
  x_shift_2 <= shift_right(x_abs, 5);
  x_shift_3 <= shift_right(x_abs, 3);
  x_shift_4 <= shift_right(x_abs, 2);
  x_shift_5 <= shift_right(x_abs, 1);
  
  
  op_2 <= op7      when sel = "000" else
		  x_shift_1 when sel = "001" else
		  x_shift_2 when sel = "010" else
		  x_shift_3 when sel = "011" else
		  x_shift_4 when sel = "100" else
		  x_shift_5 when sel = "101" else
		  x_abs;

  op2_next <= op_2;		  	 
  
  res     <= op1_reg + op2_reg;
  res_neg <= -op1_reg - op2_reg;
  
  output <= neg_one when x_max_reg = '1' else
			res_neg when x_neg_reg = '1'else
			res;
			
  seq: process(clk)
  begin
     if rising_edge(clk) then
        op1_reg <= op1_next;
	    op2_reg <= op2_next;
	    valid_out_reg <= valid_out_next;
		x_max_reg <= x_max_next;
		x_neg_reg <= x_neg_next;
	 end if;
  end process;
end PLATANH_PIPELINED;

