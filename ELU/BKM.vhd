library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

entity BKM is
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
end BKM;

architecture iterative of BKM is
  CONSTANT e_0_const : signed((bit_width - 1) downto 0) := to_signed(integer(e_0*real(2**fractional_bits)), bit_width);
  CONSTANT iter_bits : integer := integer(CEIL(LOG(real(iterations), 2.0)) + 1.0);
  
  signal E_next, E_reg, L_next, L_reg, log_1, log_2, L_out_sig, E_out_sig: signed((bit_width - 1) downto 0);
  signal i_next, i_reg : unsigned((iter_bits - 1) downto 0) := (others => '0');
  signal started_next, started_reg : std_logic := '0';
  
  
  component BKM_ROM is
	generic(bit_width : integer := 16;
			fractional_bits : integer := 11;
			iter_bits: integer := 4);
	port(clk : in std_logic;
		 iteration : in unsigned((iter_bits  - 1) downto 0);
		 log_out_1 : out signed((bit_width - 1) downto 0)
		 );
  end component;
  
  component BKM_STAGE is
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
		 
  end component;
  
begin
  bkm_compute: BKM_STAGE generic map(bit_width => bit_width,
									 fractional_bits => fractional_bits,
									 iter_bits => iter_bits)
						 port map(E_in => E_reg,
								  L_in => L_reg,
								  logn_comp_in => log_1,
								  logn_in => log_1,
								  iteration => i_reg,
								  E_out => E_out_sig,
								  L_out => L_out_sig);
  
  rom: BKM_ROM generic map(bit_width => bit_width,
						   fractional_bits => fractional_bits,
						   iter_bits => iter_bits)
			   port map(clk => clk,
						iteration => i_reg,
						log_out_1 => log_1);
  
  
  
  
  
  L_next <= input when (valid_in = '1' and started_reg = '0') else -- when did not start set input, else output of BKM unit
			L_out_sig;
			
  E_next <= e_0_const when (valid_in = '1' and started_reg = '0') else -- when did not start initialize, else output of BKM unit
			E_out_sig;
			
  i_next <= to_unsigned(0, i_next'length) when (started_reg = '0') or (i_reg = iterations) else --when finished reset counter
			i_reg + 1;
			
  started_next <= '1' when valid_in = '1' and started_reg = '0' else
				  '1' when started_reg = '1' and i_reg < iterations else
				  '0';
  
  valid_out <= '0' when i_reg < iterations else
			   '1';
			   
  ready <= not started_reg;
  
  output <= E_next;
  
  
  seq: process(clk)
  begin
    if rising_edge(clk) then
		started_reg <= started_next;
		L_reg <= L_next;
		E_reg <= E_next;
		i_reg <= i_next;
	end if;
  end process;
end iterative;