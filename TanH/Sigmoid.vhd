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
    --valid_in
	--valid_out
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


architecture ALIPPI of sigmoid is
  signal x, x_neg, number, frac_x, int_x, frac_x_shifted, frac_added, result, number_abs: signed((bit_width-1) downto 0);
  signal one, one_half:signed((bit_width-1) downto 0) := (others => '0');
  signal neg_number : std_logic;
begin
  x <= input;
  x_neg <= not(input) + 1;
  
  neg_number <= x(bit_width-1);
  
  number <= x when neg_number = '1' else
			x_neg;
  
  number_abs <= shift_right(abs(number), fractional_bits);
  int_x <= shift_left(number_abs, fractional_bits);
  
  frac_x <= number + int_x;
  frac_x_shifted <= shift_right(frac_x, 2);
  one_half(fractional_bits - 1) <= '1';
  one(fractional_bits) <= '1';
  frac_added <= frac_x_shifted + one_half;
  result <= shift_right(frac_added, to_integer(number_abs));
  output <= result when neg_number = '1' else
			one - result;
end ALIPPI;

architecture LINEAR_INTERPOLATION of sigmoid is
  constant max_neg : signed((bit_width-1) downto 0) := to_signed(integer(-2**(bit_width-1)), bit_width);
  
  component rom is
    generic (
        ADDR_BITS   : integer := 5;        
        DATA_BITS  : integer := 16;
		MIF_FILE    : string  := "init_file.mif");
    port (
        clk   : in  std_logic;
        addr  : in  std_logic_vector(ADDR_BITS-1 downto 0);          
        data  : out signed(DATA_BITS-1 downto 0));
	end component;
	
	component LPM_MULT
		generic ( LPM_WIDTHA : natural;                  
				  LPM_WIDTHB : natural;                 
				  LPM_WIDTHS : natural := 1;                 
				  LPM_WIDTHP : natural;
				  LPM_REPRESENTATION : string := "UNSIGNED";
				  LPM_PIPELINE : natural := 0;
				  LPM_TYPE: string := L_MULT;
				  LPM_HINT : string := "UNUSED");
		port ( DATAA : in std_logic_vector(LPM_WIDTHA-1 downto 0);
			   DATAB : in std_logic_vector(LPM_WIDTHB-1 downto 0);
			   ACLR : in std_logic := '0';
			   CLOCK : in std_logic := '0';
			   CLKEN : in std_logic := '1';
			   SUM : in std_logic_vector(LPM_WIDTHS-1 downto 0) := (OTHERS => '0');
			   RESULT : out std_logic_vector(LPM_WIDTHP-1 downto 0));
		end component;
	
	signal x, x_abs, c_1, c_2, mult_res_cut, result: signed((bit_width-1) downto 0);
	signal one, four : signed((bit_width-1) downto 0) := (others => '0');
	signal mult_res, mult_res_shifted : signed((2*bit_width - 1) downto 0);
	signal neg, out_of_bounds: std_logic;  
	
	--lpm multipliers inputs
	signal lpm_a_operand, lpm_b_operand: std_logic_vector((bit_width-1) downto 0);
	signal lpm_result: std_logic_vector((2*bit_width-1) downto 0);
begin
  ROM_1: rom generic map (ADDR_BITS => 5,
						  DATA_BITS => bit_width,
						  MIF_FILE => "linear_rom_mif_1.mif")
			 port map (clk => clk,
					   addr => std_logic_vector(x_abs((fractional_bits + 1) downto (fractional_bits - 3))),
					   data => c_1);
					   
  ROM_2: rom generic map (ADDR_BITS => 5,
						  DATA_BITS => bit_width,
						  MIF_FILE => "linear_rom_mif_2.mif")
			 port map (clk => clk,
					   addr => std_logic_vector(x_abs((fractional_bits + 1) downto (fractional_bits - 3))),
					   data => c_2);
				
  multiplier: LPM_MULT generic map(LPM_WIDTHA         => bit_width,
								   LPM_WIDTHB         => bit_width,
								   LPM_WIDTHP         => 2*bit_width,
								   LPM_REPRESENTATION => "SIGNED")
					   port map(DATAA  => lpm_a_operand,
								DATAB  => lpm_b_operand,
								RESULT => lpm_result);
  
  x <= input;				
  x_abs <= abs(x);
  
  lpm_a_operand <= std_logic_vector(x_abs);
  lpm_b_operand <= std_logic_vector(c_1);
  
  mult_res <= signed(lpm_result);
  
  mult_res_shifted <= shift_right(mult_res, fractional_bits);
  one(fractional_bits) <= '1';
  four(fractional_bits + 2) <= '1';
  mult_res_cut <= mult_res_shifted((bit_width-1) downto 0);
  result <= mult_res_cut + c_2;
  neg <= '1' when x(bit_width-1) = '1' else
		 '0';
  out_of_bounds <= '1' when x_abs >= four else
				   '0';
  
  output <= (others => '0') when x = max_neg else
			one when out_of_bounds = '1' and neg = '0' else
			(others => '0') when out_of_bounds = '1' and neg = '1' else
			one - result when neg = '1' else
			result;
  
end LINEAR_INTERPOLATION;

architecture QUADRATIC_INTERPOLATION of sigmoid is
  constant max_neg : signed((bit_width-1) downto 0) := to_signed(integer(-2**(bit_width-1)), bit_width);
  
  component rom is
    generic (
        ADDR_BITS   : integer := 5;        
        DATA_BITS  : integer := 16;
		MIF_FILE    : string  := "init_file.mif");
    port (
        clk   : in  std_logic;
        addr  : in  std_logic_vector(ADDR_BITS-1 downto 0);          
        data  : out signed(DATA_BITS-1 downto 0));
	end component;
	
	signal x, x_abs, c_1, c_2, c_3, mult_res_cut_1, result_1, mult_res_cut_2, result_2: signed((bit_width-1) downto 0);
	signal one, four : signed((bit_width-1) downto 0) := (others => '0');
	signal mult_res_1, mult_res_shifted_1, mult_res_2, mult_res_shifted_2 : signed((2*bit_width - 1) downto 0);
	signal neg, out_of_bounds: std_logic;  

begin
  ROM_1: rom generic map (ADDR_BITS => 4,
						  DATA_BITS => bit_width,
						  MIF_FILE => "quadratic_rom_mif_1.mif")
			 port map (clk => clk,
					   addr => std_logic_vector(x_abs((fractional_bits + 1) downto (fractional_bits - 2))),
					   data => c_1);
					   
  ROM_2: rom generic map (ADDR_BITS => 4,
						  DATA_BITS => bit_width,
						  MIF_FILE => "quadratic_rom_mif_2.mif")
			 port map (clk => clk,
					   addr => std_logic_vector(x_abs((fractional_bits + 1) downto (fractional_bits - 2))),
					   data => c_2);
	
  ROM_3: rom generic map (ADDR_BITS => 4,
						  DATA_BITS => bit_width,
						  MIF_FILE => "quadratic_rom_mif_3.mif")
			 port map (clk => clk,
					   addr => std_logic_vector(x_abs((fractional_bits + 1) downto (fractional_bits - 2))),
					   data => c_3);
	
  x <= input;				
  x_abs <= abs(x);
  mult_res_1 <= x_abs * c_2;
  mult_res_shifted_1 <= shift_right(mult_res_1, fractional_bits);
  mult_res_cut_1 <= mult_res_shifted_1((bit_width-1) downto 0);
  result_1 <= c_1 - mult_res_cut_1;
  
  mult_res_2 <= x_abs * result_1;
  mult_res_shifted_2 <= shift_right(mult_res_2, fractional_bits);
  mult_res_cut_2 <= mult_res_shifted_2((bit_width-1) downto 0);
  result_2 <= c_3 + mult_res_cut_2;
  
  neg <= '1' when x(bit_width-1) = '1' else
		 '0';
  out_of_bounds <= '1' when x_abs >= four else
				   '0';
  
  one(fractional_bits) <= '1';
  four(fractional_bits + 2) <= '1';
  
  
  output <= (others => '0') when x = max_neg else
			one when out_of_bounds = '1' and neg = '0' else
			(others => '0') when out_of_bounds = '1' and neg = '1' else
			one - result_2 when neg = '1' else
			result_2;
  
end QUADRATIC_INTERPOLATION; 