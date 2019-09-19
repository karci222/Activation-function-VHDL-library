library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use std.textio.all;

entity rom is
    generic (
        ADDR_BITS   : integer := 5;        
        DATA_BITS  : integer := 16;
		MIF_FILE    : string  := "init_file.mif");
    port (
        clk   : in  std_logic;
        addr  : in  std_logic_vector(ADDR_BITS-1 downto 0);          
        data  : out signed(DATA_BITS-1 downto 0));
end rom;

architecture beh of rom is

type mem_type is array (0 to (2**ADDR_BITS)-1) of signed(DATA_BITS-1 downto 0);

impure function init_mem(mif_file_name : in string) return mem_type is
    file mif_file : text open read_mode is mif_file_name;
    variable mif_line : line;
    variable temp_bv : bit_vector(DATA_BITS-1 downto 0);
    variable temp_mem : mem_type;
begin
    for i in mem_type'range loop
        readline(mif_file, mif_line);
        read(mif_line, temp_bv);
        temp_mem(i) := signed(to_stdlogicvector(temp_bv));
    end loop;
    return temp_mem;
end function;

constant mem : mem_type := init_mem(MIF_FILE);

begin

process (clk)
begin
    if rising_edge(clk) then
	     data <= mem(to_integer(unsigned(addr)));
    end if;
end process;

end beh;
