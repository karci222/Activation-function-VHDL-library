library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

use STD.textio.all;
use ieee.std_logic_textio.all;

entity env is
  generic (bit_width : integer := 16;
		   fractional_bits : integer := 12);
  port(input : out std_logic_vector((bit_width-1) downto 0);
       res   : in  std_logic_vector((bit_width-1) downto 0);
	   valid_out : in std_logic;
	   valid_in : out std_logic;
	   ready_in : in std_logic;
	   clk   : out std_logic
	   );
end env;

architecture beh of env is
	file file_handler : text;	
	constant max   : integer := integer(4.0*real(2**fractional_bits));
	constant min   : integer := integer(-8.5*real(2**fractional_bits));
     
begin
  process 
     constant comma : string := ",";
	 variable i : std_logic_vector((bit_width-1) downto 0) := std_logic_vector(to_signed(min, bit_width));
	 Variable row          : line;
	 Variable v_data_write : integer;
  begin
	file_open(file_handler, "ELU_results.txt", write_mode);
	input <= std_logic_vector(to_signed(min, input'length));
	wait for 5 ns;
	while (signed(i) <= max) loop
		input <= i;
		valid_in <= '1';
		if (valid_out = '1') then
			write(row, to_integer(signed(i)));
			write(row, comma);
			write(row, to_integer(signed(res)));
			writeline(file_handler, row);
		end if;
		
		if(ready_in = '1') then
			i := std_logic_vector(signed(i) + 1);
		end if;
		
		exit when (signed(i) = max);
		
		wait for 5 ns;	
		
	end loop;
	file_close(file_handler);
	assert 1/= 1 report "Simulation finished" severity failure;
  end process;
  
  clk_process :process
   begin
        clk <= '0';
        wait for 2500 ps;  --for 0.5 ns signal is '0'.
        clk <= '1';
        wait for 2500 ps;  --for next 0.5 ns signal is '1'.
   end process;
  
end beh;