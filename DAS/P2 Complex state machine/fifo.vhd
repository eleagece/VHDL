----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:58:03 11/03/2009 
-- Design Name: 
-- Module Name:    fifo - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fifo is
generic( width:integer:=3; -- din width
				depth:integer:=3 -- ram depth in words(2^depth)
				);
port(	we: in std_logic;
		re: in std_logic;
		clk: in std_logic;
		rst: in std_logic;
		data_i: in std_logic_vector(width-1 downto 0);
		data_o: out std_logic_vector(width-1 downto 0);
		empty: out std_logic;
		full: out std_logic
		);
end fifo;

architecture Behavioral of fifo is

type fifo_table is array (0 to 2**depth-1) of std_logic_vector(width-1 downto 0);
signal fifomemory: fifo_table;
signal first: std_logic_vector(depth-1 downto 0);
signal last: std_logic_vector(depth-1 downto 0);
signal vacio, lleno: std_logic;
signal n: std_logic_vector(depth downto 0);

begin

full<=lleno;
empty<=vacio;
lleno<='1' when (n=(2**depth)) else '0';
vacio<='1' when (n=0) else '0';
		
	process(we,re,clk)
		begin
			if rst='0' then
					first <= (OTHERS=>'0');
					last <= (OTHERS=>'0');
					n<= (OTHERS=>'0');
			elsif clk'event and clk='1' then
				
					if we='1' and re='0' and lleno='0' then 
							fifomemory(conv_integer(last))<=data_i;
							last<=last+1;
							n<=n+1;
						end if;
						if re='1' and we='0' and vacio='0' then
							data_o<=fifomemory(conv_integer(first));
							first<=first+1;
							n<=n-1;
						end if;
						--if re='1' and we='0' then
						--	n<=n-1;
						--elsif re='0' and we='1' then
						--	n<=n+1;
						--end if;
				end if;
			
		end process;
	
end Behavioral;

