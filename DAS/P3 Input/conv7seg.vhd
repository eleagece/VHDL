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

--> Begin architecture
begin
	with entrada select
		salida<="0111111" when "0000", -- 0    -- 0 --
				  "0000110" when "0001", -- 1   |       |
				  "1011011" when "0010", -- 2   5       1
				  "1001111" when "0011", -- 3   |       |
				  "1100110" when "0100", -- 4    -- 6 --
				  "1101101" when "0101", -- 5   |       |
				  "1111101" when "0110", -- 6   4       2
				  "0000111" when "0111", -- 7   |       |
				  "1111111" when "1000", -- 8    -- 3 --
				  "1101111" when "1001", -- 9   6 5 4 3 2 1 0
				  "1110111" when "1010", -- A
				  "1111100" when "1011", -- b
				  "0111001" when "1100", -- C
				  "1011110" when "1101", -- d
				  "1111001" when "1110", -- E
				  "1110001" when "1111", -- F
				  "0000100" when others;
				  
end Behavioural;
