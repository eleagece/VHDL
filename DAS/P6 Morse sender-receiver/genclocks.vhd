library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package GCLK is
	component genclocks
		port(	clk:in std_logic; 		-- reloj de la fpga, 100MHz
				reset:in std_logic; 		-- reset de la fpga, activo a 0 por la polaridad del push button
				mclk:out std_logic; 		-- reloj MCLK del akm, 6.25MHz tambien reloj general
				sclk:out std_logic; 		-- reloj SCLK del akm, 1.56MHz
				lrck:out std_logic; 		-- reloj LRCK del akm, 24.42KHz
				sdti:out std_logic;		-- frecuencia de sonido
				clk_kbd:out std_logic;
				clk_dot:out std_logic	-- reloj del pitido
				);
	end component;
end package GCLK;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity genclocks is
	port(	clk:in std_logic; 		-- reloj de la fpga, 100MHz
			reset:in std_logic; 		-- reset de la fpga, activo a 0 por la polaridad del push button
			mclk:out std_logic; 		-- reloj MCLK del akm, 6.25MHz tambien reloj general
			sclk:out std_logic; 		-- reloj SCLK del akm, 1.56MHz
			lrck:out std_logic; 		-- reloj LRCK del akm, 24.42KHz
			sdti:out std_logic;		-- frecuencia de sonido
			clk_kbd:out std_logic;
			clk_dot:out std_logic	-- reloj del pitido
			);
end genclocks;

architecture Behavioral of genclocks is

signal sdtio: std_logic;
signal cuenta:std_logic_vector(21 downto 0);
signal count: std_logic_vector(4 downto 0);

begin

	process(clk,reset)
		begin
			if reset='0' then
				cuenta <= (others=>'0');
			elsif clk'event and clk='1' then
				cuenta <= cuenta+1;
			end if;
		end process;
		
	process(cuenta,reset,sdtio,count)
		begin
			if reset='0' then
				sdtio <= '0';
				count <= (others => '0');
			elsif cuenta(3)'event and cuenta(3)='1' then
			-- sonido de pitido
			if count=9 then
				sdtio <= not sdtio;
				count <= (others => '0');
			else
				count <= count+1;
			end if;
		end if;
	end process;

	mclk <= cuenta(3);
	sclk <= cuenta(5);
	lrck <= cuenta(11);
	clk_kbd <= cuenta(2);
	sdti <= sdtio;
	-- Ajustar convenientemente
	clk_dot <= cuenta(21);
	

end Behavioral;
