library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
LIBRARY lpm; 
USE lpm.lpm_components.all;


entity TanH is
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
end TanH;


architecture PLAN_TANH of TanH is
  constant cond1 : signed((bit_width-1) downto 0) := to_signed(integer(2.5*(2**fractional_bits)), bit_width);-- number 5.0
  constant one : signed((bit_width-1) downto 0) := to_signed(integer(1.0*(2**fractional_bits)), bit_width);
  constant negative_one : signed((bit_width-1) downto 0) := to_signed(integer(-1.0*(2**fractional_bits)), bit_width);
  
  component sigmoid is
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
  
  
  signal x, input_shifted, x_abs, result: signed((bit_width - 1) downto 0);
  signal above_boundaries: std_logic;
begin
  plan_sigmoid: entity work.sigmoid(PLAN) generic map(bit_width=>bit_width,
						fractional_bits => fractional_bits)
									port map(input => x,
											 output => result,
											 clk => clk);
  
  x <= input_shifted when input(bit_width - 1) = '0' else
       -input_shifted;
  input_shifted <= shift_left(x_abs, 1);
  x_abs <= abs(input);
  

  above_boundaries <= '1' when x_abs >= cond1 else	
					  '0';
					  
  output <= one when above_boundaries = '1' and input(bit_width-1) = '0' else
			negative_one when above_boundaries = '1' and input (bit_width-1) = '1' else
			shift_left(result, 1) - one;
end PLAN_TANH;


architecture ALIPPI_TANH of TanH is
  constant one : signed((bit_width-1) downto 0) := to_signed(integer(1.0*(2**fractional_bits)), bit_width);
  constant negative_one : signed((bit_width-1) downto 0) := to_signed(integer(-1.0*(2**fractional_bits)), bit_width);

  component sigmoid is
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
  
  signal x, x_abs, input_shifted, result: signed((bit_width - 1) downto 0);
  signal above_boundaries : std_logic;
begin
  alippi_sigmoid: entity work.sigmoid(ALIPPI) generic map(bit_width=>bit_width,
						fractional_bits => fractional_bits)
									port map(input => x,
											 output => result,
				clk => clk);
  
  x <= input_shifted when input(bit_width - 1) = '0' else
       -input_shifted;
  input_shifted <= shift_left(x_abs, 1);
  x_abs <= abs(input);
  
  above_boundaries <= '1' when x_abs(bit_width-2) = '1' else
					  '0';
  
  output <= one when above_boundaries = '1' and input(bit_width-1) = '0' else
			negative_one when above_boundaries = '1' and input(bit_width-1) = '1' else
		    shift_left(result, 1) - one;
end ALIPPI_TANH;

architecture PLATANH of TanH is
  constant max_neg : signed((bit_width-1) downto 0) := to_signed(integer(-2**(bit_width-1)), bit_width);
  
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
  
  output <= (others => '0') when (x = max_neg) else
			res_neg when x(bit_width-1) = '1'else
			res;
end PLATANH;

architecture LINEAR_INTERPOLATION of TanH is
  constant max_neg : signed((bit_width-1) downto 0) := to_signed(integer(-2**(bit_width-1)), bit_width);
  constant negative_one : signed((bit_width-1) downto 0) := to_signed(integer(-1.0*(2**fractional_bits)), bit_width);
  
  
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
  ROM_1: rom generic map (ADDR_BITS => 4,
						  DATA_BITS => bit_width,
						  MIF_FILE => "linear_rom_mif_1.mif")
			 port map (clk => clk,
					   addr => std_logic_vector(x_abs((fractional_bits) downto (fractional_bits - 3))),
					   data => c_1);
					   
  ROM_2: rom generic map (ADDR_BITS => 4,
						  DATA_BITS => bit_width,
						  MIF_FILE => "linear_rom_mif_2.mif")
			 port map (clk => clk,
					   addr => std_logic_vector(x_abs((fractional_bits) downto (fractional_bits - 3))),
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
  four(fractional_bits + 1) <= '1';
  mult_res_cut <= mult_res_shifted((bit_width-1) downto 0);
  result <= mult_res_cut + c_2;
  neg <= '1' when x(bit_width-1) = '1' else
		 '0';
  out_of_bounds <= '1' when x_abs >= four else
				   '0';
  
  output <= (others => '0') when x = max_neg else
			one when out_of_bounds = '1' and neg = '0' else
			negative_one when out_of_bounds = '1' and neg = '1' else
			-result when neg = '1' else
			result;
  
end LINEAR_INTERPOLATION;

architecture QUADRATIC_INTERPOLATION of TanH is
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
  ROM_1: rom generic map (ADDR_BITS => 3,
						  DATA_BITS => bit_width,
						  MIF_FILE => "quadratic_rom_mif_1.mif")
			 port map (clk => clk,
					   addr => std_logic_vector(x_abs((fractional_bits) downto (fractional_bits - 2))),
					   data => c_1);
					   
  ROM_2: rom generic map (ADDR_BITS => 3,
						  DATA_BITS => bit_width,
						  MIF_FILE => "quadratic_rom_mif_2.mif")
			 port map (clk => clk,
					   addr => std_logic_vector(x_abs((fractional_bits) downto (fractional_bits - 2))),
					   data => c_2);
	
  ROM_3: rom generic map (ADDR_BITS => 3,
						  DATA_BITS => bit_width,
						  MIF_FILE => "quadratic_rom_mif_3.mif")
			 port map (clk => clk,
					   addr => std_logic_vector(x_abs((fractional_bits) downto (fractional_bits - 2))),
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