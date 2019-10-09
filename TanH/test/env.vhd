library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

use STD.textio.all;
use ieee.std_logic_textio.all;

entity env is
  generic (bit_width : integer := 16);
  port(input : out std_logic_vector((bit_width-1) downto 0);
       res   : in  std_logic_vector((bit_width-1) downto 0);
	   clk   : out std_logic
	   );
end env;

architecture behaviour_non_pipelined of env is
	file file_handler : text;	
begin
  process 
     constant comma : string := ",";
	 constant max   : integer := (2**bit_width)-1;
     variable i : std_logic_vector((bit_width-1) downto 0) := std_logic_vector(to_signed(0, bit_width));
	 Variable row          : line;
	 Variable v_data_write : integer;
  begin
	file_open(file_handler, "plan_results.txt", write_mode);
	input <= (others => '0');
	wait for 1 ns;
	while (unsigned(i) <= max) loop
		input <= i;
		wait for 5 ns;
		write(row, to_integer(signed(i)));
		write(row, comma);
		write(row, to_integer(signed(res)));
		writeline(file_handler, row);
		exit when (unsigned(i) = max);
		wait for 5 ns;
		i := std_logic_vector(unsigned(i) + 1);
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
  
end behaviour_non_pipelined;

architecture behaviour_pipelined of env is
	file file_handler : text;	
begin
  process 
     constant comma : string := ",";
	 constant max   : integer := (2**bit_width)-1;
     variable i : std_logic_vector((bit_width-1) downto 0) := std_logic_vector(to_signed(0, bit_width));
	 Variable row          : line;
	 Variable v_data_write : integer;
  begin
	file_open(file_handler, "plan_pipelined_results.txt", write_mode);
	input <= (others => '0');
	wait for 1 ns;
	while (unsigned(i) <= max) loop
		input <= i;
		wait for 10 ns;
		write(row, to_integer(signed(i)));
		write(row, comma);
		write(row, to_integer(signed(res)));
		writeline(file_handler, row);
		exit when (unsigned(i) = max);
		i := std_logic_vector(unsigned(i) + 1);
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
  
end behaviour_pipelined;