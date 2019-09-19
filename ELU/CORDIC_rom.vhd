library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

entity CORDIC_ROM is
	generic(bit_width : integer := 16;
			fractional_bits : integer := 11;
			coor : std_logic := '1';
			iter_bits: integer := 5;
			iter_start: integer := -2);
	port(clk : in std_logic;
		 iteration : in unsigned((iter_bits  - 1) downto 0);
		 atan_out : out signed((bit_width - 1) downto 0)
		 );
end CORDIC_ROM;

architecture rtl of CORDIC_ROM is
  constant MEM_DEPTH : integer := 2**iter_bits;
  type MEM_TYPE is array (0 to (MEM_DEPTH - 1)) of signed ((bit_width - 1) downto 0);
  constant SCALE : real := 2**real(fractional_bits);
  
  function mem_init return MEM_TYPE is
	variable temp_mem: mem_type;
	variable j: integer := iter_start;	
  begin
	for i in 0 to MEM_DEPTH - 1 loop
	  if coor = '1' then
		if j <= 0 then
			temp_mem(i) := to_signed(integer(ARCTANH(1.0 - 2**real(j - 2))*SCALE), temp_mem(i)'length);
		else
			temp_mem(i) := to_signed(integer(ARCTANH(2**real(-j))*SCALE), temp_mem(i)'length);
		end if;
	  else
	    if j <= 0 then
			temp_mem(i) := to_signed(integer(ARCTAN(1.0 - 2**real(j-2))*SCALE), temp_mem(i)'length);
		else
			temp_mem(i) := to_signed(integer(ARCTAN(2**real(-j))*SCALE), temp_mem(i)'length);
		end if;
	  end if;
	  
	  j := j + 1;
	end loop;
	
	return temp_mem;
  end;
  
  constant MEMORY: MEM_TYPE := mem_init;
begin
  process(iteration)
  begin
      atan_out <= MEMORY(to_integer(iteration));
  end process;
end rtl;