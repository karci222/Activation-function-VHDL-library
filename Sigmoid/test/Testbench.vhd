use work.all;
library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;


entity testebench is
end testebench;

architecture test_plan of testebench is
  constant bit_width : integer := 16;
  constant fractional_bits : integer := 12;
  
  component env is
    generic (bit_width : integer := 16);
    port(input : out std_logic_vector((bit_width - 1) downto 0);
         res   : in  std_logic_vector((bit_width - 1) downto 0);
		 clk   : out std_logic);
  end component;
  
  component TanH is
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
  end component;
  
  signal input_internal, res_internal: std_logic_vector((bit_width - 1) downto 0);
  signal input_internal_2, output_internal: signed((bit_width - 1) downto 0);
  signal clk_internal : std_logic;
begin
  u1: entity work.sigmoid(PLAN) generic map(bit_width => bit_width, fractional_bits => fractional_bits)
			port map(input => input_internal_2, output => output_internal, clk => clk_internal, valid_in => '1', valid_out => open);
  u2: entity work.env(behaviour_non_pipelined) generic map(bit_width => bit_width)
		port map(input => input_internal, res => res_internal, clk => clk_internal);
  
  res_internal <= std_logic_vector(output_internal);
  input_internal_2 <= signed(input_internal);
end test_plan;

architecture test_plan_pipelined of testebench is
  constant bit_width : integer := 16;
  constant fractional_bits : integer := 12;
  
  component env is
    generic (bit_width : integer := 16);
    port(input : out std_logic_vector((bit_width - 1) downto 0);
         res   : in  std_logic_vector((bit_width - 1) downto 0);
		 clk   : out std_logic);
  end component;
  
  component TanH is
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
  end component;
  
  signal input_internal, res_internal: std_logic_vector((bit_width - 1) downto 0);
  signal input_internal_2, output_internal: signed((bit_width - 1) downto 0);
  signal clk_internal : std_logic;
begin
  u1: entity work.sigmoid(PLAN_PIPELINED) generic map(bit_width => bit_width, fractional_bits => fractional_bits)
			port map(input => input_internal_2, output => output_internal, clk => clk_internal, valid_in => '1', valid_out => open);
  u2: entity work.env(behaviour_pipelined) generic map(bit_width => bit_width)
		port map(input => input_internal, res => res_internal, clk => clk_internal);
  
  res_internal <= std_logic_vector(output_internal);
  input_internal_2 <= signed(input_internal);
end test_plan_pipelined;