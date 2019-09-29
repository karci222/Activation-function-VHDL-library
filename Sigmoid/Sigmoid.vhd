library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
LIBRARY lpm; 
USE lpm.lpm_components.all;


entity sigmoid is
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
end sigmoid;


architecture PLAN of sigmoid is
  constant cond1 : signed((bit_width-1) downto 0) := to_signed(integer(5.0*(2**fractional_bits)), bit_width);-- number 5.0
  constant cond2 : signed((bit_width-1) downto 0) := to_signed(integer(2.375*(2**fractional_bits)), bit_width);-- number 2.375
  constant cond3 : signed((bit_width-1) downto 0) := to_signed(integer(1.0*(2**fractional_bits)), bit_width);-- number 1.0
  
  constant op1   : signed((bit_width-1) downto 0) := to_signed(integer(1.0*(2**fractional_bits)), bit_width);-- number 1.0
  constant op2   : signed((bit_width-1) downto 0) := to_signed(integer(0.84375*(2**fractional_bits)), bit_width);-- number 0.84375
  constant op3   : signed((bit_width-1) downto 0) := to_signed(integer(0.625*(2**fractional_bits)), bit_width);-- number 0.625
  constant op4   : signed((bit_width-1) downto 0) := to_signed(integer(0.5*(2**fractional_bits)), bit_width);-- number 0.5
  
  constant zero  : signed((bit_width-1) downto 0) := to_signed(integer(0.0*(2**fractional_bits)), bit_width);-- 0.0
  constant one   : signed((bit_width-1) downto 0) := to_signed(integer(1.0*(2**fractional_bits)), bit_width);-- 1.0
  constant max_neg : signed((bit_width-1) downto 0) := to_signed(integer(-2**(bit_width-1)), bit_width);
  
  signal x, x_abs, x_shift_1, x_shift_2, x_shift_3, op_1, op_2, res, res_neg: signed((bit_width - 1) downto 0);
  signal sel: std_logic_vector(1 downto 0);
begin
  valid_out <= valid_in;

  x <= input;
  x_abs <= abs(input);
  
  sel <= "00" when x_abs >= cond1 else	
		 "01" when x_abs >= cond2 else 
		 "10" when x_abs >= cond3 else
         "11";

  op_1 <= op1 when sel = "00" else
        op2 when sel = "01" else
		op3 when sel = "10" else
		op4;
		
  x_shift_1 <= shift_right(x_abs, 5);
  x_shift_2 <= shift_right(x_abs, 3);
  x_shift_3 <= shift_right(x_abs, 2);
  
  
  op_2 <= zero      when sel = "00" else
		  x_shift_1 when sel = "01" else
		  x_shift_2 when sel = "10" else
		  x_shift_3;
		  
  res     <= op_1 + op_2;
  res_neg <= one - res;
  
  output <= (others => '0') when (x = max_neg) else
			res_neg when x(bit_width-1) = '1'else
			res;
end PLAN;


architecture PLAN_PIPELINED of sigmoid is
  constant cond1 : signed((bit_width-1) downto 0) := to_signed(integer(5.0*(2**fractional_bits)), bit_width);-- number 5.0
  constant cond2 : signed((bit_width-1) downto 0) := to_signed(integer(2.375*(2**fractional_bits)), bit_width);-- number 2.375
  constant cond3 : signed((bit_width-1) downto 0) := to_signed(integer(1.0*(2**fractional_bits)), bit_width);-- number 1.0
  
  constant op1   : signed((bit_width-1) downto 0) := to_signed(integer(1.0*(2**fractional_bits)), bit_width);-- number 1.0
  constant op2   : signed((bit_width-1) downto 0) := to_signed(integer(0.84375*(2**fractional_bits)), bit_width);-- number 0.84375
  constant op3   : signed((bit_width-1) downto 0) := to_signed(integer(0.625*(2**fractional_bits)), bit_width);-- number 0.625
  constant op4   : signed((bit_width-1) downto 0) := to_signed(integer(0.5*(2**fractional_bits)), bit_width);-- number 0.5
  
  constant zero  : signed((bit_width-1) downto 0) := to_signed(integer(0.0*(2**fractional_bits)), bit_width);-- 0.0
  constant one   : signed((bit_width-1) downto 0) := to_signed(integer(1.0*(2**fractional_bits)), bit_width);-- 1.0
  constant max_neg : signed((bit_width-1) downto 0) := to_signed(integer(-2**(bit_width-1)), bit_width);
  
  signal x, x_abs, x_shift_1, x_shift_2, x_shift_3, op_1, op_2, res, res_neg: signed((bit_width - 1) downto 0);
  signal sel: std_logic_vector(1 downto 0);
  signal op_1_reg, op_2_reg, op_1_next, op_2_next: signed((bit_width - 1) downto 0);
  signal valid_out_reg, valid_out_next: std_logic;
begin
  x <= input;
  x_abs <= abs(input);
  valid_out_next <= valid_in;
  valid_out <= valid_out_reg;
  
  sel <= "00" when x_abs >= cond1 else	
		 "01" when x_abs >= cond2 else 
		 "10" when x_abs >= cond3 else
         "11";

  op_1 <= op1 when sel = "00" else
        op2 when sel = "01" else
		op3 when sel = "10" else
		op4;
		
  x_shift_1 <= shift_right(x_abs, 5);
  x_shift_2 <= shift_right(x_abs, 3);
  x_shift_3 <= shift_right(x_abs, 2);
  
  
  op_2 <= zero      when sel = "00" else
		  x_shift_1 when sel = "01" else
		  x_shift_2 when sel = "10" else
		  x_shift_3;
		  
  op_1_next <= op_1;
  op_2_next <= op_2;
  
  res     <= op_1 + op_2;
  res_neg <= one - res;
  
  output <= (others => '0') when (x = max_neg) else
			res_neg when x(bit_width-1) = '1'else
			res;
			
  seq: process(clk)
  begin
     if rising_edge(clk) then
	    valid_out_reg <= valid_out_next;
		op_1_reg <= op_1_next;
		op_2_reg <= op_2_reg;
	 end if;
  end process;
end PLAN_PIPELINED;