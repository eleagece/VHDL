library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-------------------------------------------------------------------------------------------------------
-- Entity conv7seg
-------------------------------------------------------------------------------------------------------
entity conv7seg is
	port ( entrada: in std_logic_vector(3 downto 0);
			 salida: out std_logic_vector(6 downto 0) );
end conv7seg;

-------------------------------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------------------------------
architecture Behavioural of conv7seg is
begin
	with entrada select
		salida<="0111111" when "0000", --   -- 0 --
				  "0000110" when "0001", --  |       |
				  "1011011" when "0010", --  5       1
				  "1001111" when "0011", --  |       |
				  "1100110" when "0100", --   -- 6 --
				  "1101101" when "0101", --  |       |
				  "1111101" when "0110", --  4       2
				  "0000111" when "0111", --  |       |
				  "1111111" when "1000", --   -- 3 --
				  "1101111" when "1001", --  6 5 4 3 2 1 0
				  "1110111" when "1010",
				  "1111100" when "1011",
				  "0111001" when "1100",
				  "1011110" when "1101",
				  "1111001" when "1110",
				  "1100011" when "1111",
				  "0000100" when others;
end Behavioural;
