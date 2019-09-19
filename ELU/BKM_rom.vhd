library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

entity BKM_ROM is
	generic(bit_width : integer := 16;
			fractional_bits : integer := 11;
			iter_bits: integer := 4);
	port(clk : in std_logic;
		 iteration : in unsigned((iter_bits  - 1) downto 0);
		 log_out_1 : out signed((bit_width - 1) downto 0)
		 );
end BKM_ROM;

architecture rtl of BKM_ROM is
  constant MEM_DEPTH : integer := 2**iter_bits;
  type MEM_TYPE is array (0 to (MEM_DEPTH - 1)) of signed ((bit_width - 1) downto 0);
  
  function mem_init return MEM_TYPE is
	variable temp_mem: mem_type;
	constant SCALE : real := 2**real(fractional_bits);
  begin
	for i in 0 to MEM_DEPTH - 1 loop
	  temp_mem(i) := to_signed(integer(LOG(real(1.0 + 2**real(-i)))*SCALE), temp_mem(i)'length);
	end loop;
	
	return temp_mem;
  end;
  
  constant MEMORY: MEM_TYPE := mem_init;
begin
  process(iteration)
  begin
      log_out_1 <= MEMORY(to_integer(iteration));
  end process;
end rtl;