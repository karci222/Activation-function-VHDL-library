library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

entity CORDIC is
	generic(bit_width : integer := 16;
			fractional_bits : integer := 12;
			iterations : integer := 8;
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
end CORDIC;

architecture iterative of CORDIC is
  CONSTANT iter_bits : integer := integer(CEIL(LOG(real(iterations), 2.0)) + 2.0);
  CONSTANT x_init_circular : signed((bit_width - 1) downto 0) := to_signed(integer(0.6073*real(2**fractional_bits)), bit_width);
  CONSTANT x_init_hyperbolic : signed((	bit_width - 1) downto 0) := to_signed(integer(10.81507534030689*real(2**fractional_bits)), bit_width);
  CONSTANT y_init_circular : signed((bit_width - 1) downto 0) := (others => '0');
  CONSTANT y_init_hyperbolic : signed((bit_width - 1) downto 0) := (others => '0');
  
  signal X_next, X_reg, Y_next, Y_reg, Z_next, Z_reg, atan, X_out_sig, Y_out_sig, Z_out_sig: signed((bit_width - 1) downto 0);
  signal i_next, i_reg : signed((iter_bits - 1) downto 0) := to_signed(iter_start, iter_bits);
  signal started_next, started_reg : std_logic := '0';
  signal rom_addr : unsigned((iter_bits - 1) downto 0);
  signal flag_next, flag_reg : std_logic := '0';
  
  component CORDIC_ROM is
	generic(bit_width : integer := 16;
			fractional_bits : integer := 11;
			coor : std_logic := '1';
			iter_bits: integer := 5;
			iter_start: integer := -2);
	port(clk : in std_logic;
		 iteration : in unsigned((iter_bits  - 1) downto 0);
		 atan_out : out signed((bit_width - 1) downto 0)
		 );
  end component;
  
  component CORDIC_stage is
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
  end component;
  
begin
  cordic_unit: CORDIC_stage generic map(bit_width => bit_width,
									 fractional_bits => fractional_bits,
									 iter_bits => iter_bits)
						 port map(x_in => X_reg,
								  y_in => Y_reg,
								  z_in => Z_reg,
								  coor => coor,
								  rom_in => atan,
								  i_in => i_reg,
								  x_out => X_out_sig,
								  y_out => Y_out_sig,
								  z_out => Z_out_sig);
  
  rom: CORDIC_ROM generic map(bit_width => bit_width,
						   fractional_bits => fractional_bits,
						   coor => coor,
						   iter_bits => iter_bits,
						   iter_start => iter_start)
			   port map(clk => clk,
						iteration => rom_addr,
						atan_out => atan);
  
  
  
  
  
  X_next <= x_init_hyperbolic when (valid_in = '1' and started_reg = '0' and coor = '1') else  -- when did not start set input, else output of BKM unit
			x_init_circular when (valid_in = '1' and started_reg = '0' and coor = '0') else
			X_out_sig;
			
  Y_next <= y_init_hyperbolic when (valid_in = '1' and started_reg = '0' and coor = '1') else -- when did not start initialize, else output of BKM unit
			y_init_circular when (valid_in = '1' and started_reg = '0'and coor = '0') else
			Y_out_sig;
			
  Z_next <= input when (valid_in = '1' and started_reg = '0') else
			   Z_out_sig;
			
  i_next <= to_signed(iter_start, i_next'length) when (started_reg = '0') or (i_reg = iterations) else --when finished reset counter
			i_reg when flag_reg = '1' else
			i_reg + 1;
			
  started_next <= '1' when valid_in = '1' and started_reg = '0' else
				  '1' when started_reg = '1' and i_reg < iterations else
				  '0';
  
  valid_out <= '0' when i_reg < iterations else
			   '1';
			   
  rom_addr <= unsigned(i_reg + abs(iter_start));

  ready <= not started_reg;
  
  output <= X_next + Y_next;
  
  flag_next <= '1' when (i_next = 4 or i_next = 13 or i_next = 40) and flag_reg = '0' else
				'0';
  
  seq: process(clk)
  begin
    if rising_edge(clk) then
		started_reg <= started_next;
		X_reg <= X_next;
		Y_reg <= Y_next;
		Z_reg <= Z_next;
		i_reg <= i_next;
		flag_reg <= flag_next;
	end if;
  end process;
end iterative;