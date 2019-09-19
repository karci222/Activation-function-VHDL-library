library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
LIBRARY lpm; 
USE lpm.lpm_components.all;

entity ELU is
  generic (
	bit_width : integer := 16;
	fractional_bits : integer := 12
	);
  port (
      valid_in : in std_logic;
	  valid_out : out std_logic;
	  ready : out std_logic;
      input  : in signed((bit_width - 1) downto 0);
	  output : out signed((bit_width - 1) downto 0);
	  clk    : in std_logic
	);
end ELU;

architecture BKM_ELU of ELU is
  component BKM is
	generic(bit_width : integer := 16;
			fractional_bits : integer := 12;
			iterations : integer := 8;
			e_0 : real := 1.0
			);
	port(clk: in std_logic;
	     valid_in: in std_logic;
		 valid_out: out std_logic;
		 ready : out std_logic;
		 input: in signed((bit_width - 1) downto 0);
		 output: out signed((bit_width - 1) downto 0)
		 );
  end component;
  
  constant boundary_last : signed((bit_width-1) downto 0) := to_signed(integer(-8.0*(2**fractional_bits)), bit_width);
  constant negative_one  : signed((bit_width-1) downto 0) := to_signed(integer(-1.0*(2**fractional_bits)), bit_width);
  constant one  : signed((bit_width-1) downto 0) := to_signed(integer(1.0*(2**fractional_bits)), bit_width);
  
  
  --to select n
  constant cond1 : signed((bit_width-1) downto 0) := to_signed(integer(-0.6957*(2**fractional_bits)), bit_width);
  constant cond2 : signed((bit_width-1) downto 0) := to_signed(integer(-1.3914*(2**fractional_bits)), bit_width);
  constant cond3 : signed((bit_width-1) downto 0) := to_signed(integer(-2.087*(2**fractional_bits)), bit_width);
  constant cond4 : signed((bit_width-1) downto 0) := to_signed(integer(-2.7827*(2**fractional_bits)), bit_width);
  constant cond5 : signed((bit_width-1) downto 0) := to_signed(integer(-3.4783*(2**fractional_bits)), bit_width);
  constant cond6 : signed((bit_width-1) downto 0) := to_signed(integer(-4.174*(2**fractional_bits)), bit_width);
  constant cond7 : signed((bit_width-1) downto 0) := to_signed(integer(-4.8696*(2**fractional_bits)), bit_width);
  
  
  
  
  signal valid_in_internal, valid_out_internal: std_logic;
  signal input_internal, output_internal: signed((bit_width - 1) downto 0);
  signal started_reg, started_next: std_logic;
  signal ready_internal :std_logic;
  signal n_reg, n_next : unsigned(3 downto 0);
begin
  bkm_unit : BKM generic map(fractional_bits => fractional_bits, bit_width => bit_width)
				 port map(clk => clk, valid_in=>valid_in_internal, valid_out => valid_out_internal,
						  ready => ready_internal, input=>input_internal, output=>output_internal);
  
  input_internal <= input - cond1 when input > cond1 else
					input - cond2 when input > cond2 else
					input - cond3 when input > cond3 else
					input - cond4 when input > cond4 else
					input - cond5 when input > cond5 else
					input - cond6 when input > cond6 else
					input - cond7;
					
  n_next <= n_reg when started_reg = '1' else
			to_unsigned(1, n_next'length) when input > cond1 else
			to_unsigned(2, n_next'length) when input > cond2 else
			to_unsigned(3, n_next'length) when input > cond3 else
			to_unsigned(4, n_next'length) when input > cond4 else
			to_unsigned(5, n_next'length) when input > cond5 else
			to_unsigned(6, n_next'length) when input > cond6 else
			to_unsigned(7, n_next'length);
  
  output <= input when valid_out_internal = '0' and input(bit_width-1) = '0' else
            negative_one when valid_out_internal = '0' and input <= cond7 else
			shift_right(output_internal, to_integer(n_reg))- one;
  
  started_next <= '0' when valid_in = '1' and input(bit_width-1) = '0' else--positive number forward
				  '0' when valid_in = '1' and input <= cond7 else-- too small number already -1
				  '1' when valid_in = '1' and ready_internal = '1' else --valid_in and have to compute
				  '1' when started_reg = '1' and valid_out_internal = '0' else --did not finish yet
				  '0';
				  
  ready <= not started_reg and ready_internal;--if i did not started yet, i can do whatever I want

				  
				  
  valid_in_internal <= '1' when valid_in ='1' and input >= cond7 and input <= 0 else --valid input to compute
					   '0';
  
  valid_out <= '1' when input(bit_width-1) = '0' else-- just foward
			   '1' when input <= cond7 else -- -1 is forwarded
			   '1' when valid_out_internal = '1' else -- when the computation was finished
			   '0';
			   
  seq: process(clk)
  begin
    if rising_edge(clk) then
      started_reg <= started_next;
	  n_reg <= n_next;
	end if;
  end process;
end BKM_ELU;

architecture CORDIC_ELU of ELU is
  component CORDIC is
	generic(bit_width : integer := 16;
			fractional_bits : integer := 12;
			iterations : integer := 6;
			coor : std_logic := '1';
			iter_start : integer := -2
			);
	port(clk: in std_logic;
	     valid_in: in std_logic;
		 valid_out: out std_logic;
		 ready : out std_logic;
		 input: in signed((bit_width - 1) downto 0);
		 output: out signed((bit_width - 1) downto 0)
		 );
  end component;
  
  constant negative_one  : signed((bit_width-1) downto 0) := to_signed(integer(-1.0*(2**fractional_bits)), bit_width);
  constant one  : signed((bit_width-1) downto 0) := to_signed(integer(1.0*(2**fractional_bits)), bit_width);

  --to select n
  constant cond7 : signed((bit_width-1) downto 0) := to_signed(integer(-5.0*(2**fractional_bits)), bit_width);

  signal valid_in_internal, valid_out_internal: std_logic;
  signal input_internal, output_internal: signed((bit_width - 1) downto 0);
  signal started_reg, started_next: std_logic;
  signal ready_internal :std_logic;
begin
  cordic_unit : CORDIC generic map(fractional_bits => fractional_bits, bit_width => bit_width)
				 port map(clk => clk, valid_in=>valid_in_internal, valid_out => valid_out_internal,
						  ready => ready_internal, input=>input_internal, output=>output_internal);
  
  input_internal <= input;
					
  
  output <= input when valid_out_internal = '0' and input(bit_width-1) = '0' else
            negative_one when valid_out_internal = '0' and input <= cond7 else
			output_internal - one;
  
  started_next <= '0' when valid_in = '1' and input(bit_width-1) = '0' else--positive number forward
				  '0' when valid_in = '1' and input <= cond7 else-- too small number already -1
				  '1' when valid_in = '1' and ready_internal = '1' else --valid_in and have to compute
				  '1' when started_reg = '1' and valid_out_internal = '0' else --did not finish yet
				  '0';
				  
  ready <= not started_reg and ready_internal;--if i did not started yet, i can do whatever I want

				  
				  
  valid_in_internal <= '1' when valid_in ='1' and input >= cond7 and input <= 0 else --valid input to compute
					   '0';
  
  valid_out <= '1' when input(bit_width-1) = '0' else-- just foward
			   '1' when input <= cond7 else -- -1 is forwarded
			   '1' when valid_out_internal = '1' else -- when the computation was finished
			   '0';
			   
  seq: process(clk)
  begin
    if rising_edge(clk) then
      started_reg <= started_next;
	end if;
  end process;
end CORDIC_ELU;

architecture LINEAR_ELU of ELU is
  constant boundary_last : signed((bit_width-1) downto 0) := to_signed(integer(-4.0*(2**fractional_bits)), bit_width);
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
	signal address: unsigned (4 downto 0);
begin
  ROM_1: rom generic map (ADDR_BITS => 5,
						  DATA_BITS => bit_width,
						  MIF_FILE => "linear_rom_mif_1.mif")
			 port map (clk => clk,
					   addr => std_logic_vector(address),
					   data => c_1);
					   
  ROM_2: rom generic map (ADDR_BITS => 5,
						  DATA_BITS => bit_width,
						  MIF_FILE => "linear_rom_mif_2.mif")
			 port map (clk => clk,
					   addr => std_logic_vector(address),
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
  
  address <= unsigned(31 - x_abs((fractional_bits+1) downto (fractional_bits - 3)));
  
  lpm_a_operand <= std_logic_vector(x);
  lpm_b_operand <= std_logic_vector(c_1);
  
  mult_res <= signed(lpm_result);
  
  mult_res_shifted <= shift_right(mult_res, fractional_bits);
  one(fractional_bits) <= '1';
  four(fractional_bits + 1) <= '1';
  mult_res_cut <= mult_res_shifted((bit_width-1) downto 0);
  result <= mult_res_cut + c_2;
  neg <= '1' when x(bit_width-1) = '1' else
		 '0';
  
  output <= input when input >= 0 else
			result when input < 0 and input > boundary_last else
			negative_one;
			
  valid_out <= valid_in;
  ready <= '1';
end LINEAR_ELU;