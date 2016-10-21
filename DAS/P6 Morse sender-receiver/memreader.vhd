library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package mem_reader is
	component memreader
	port(	clk:in std_logic;
			reset:in std_logic;
			button:in std_logic;
			rd:out std_logic;
			addr:inout std_logic_vector(7 downto 0)
			);
	end component;
end package mem_reader;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Lector de memoria, accionado por un boton. Cuando se detecta la depresion del boton
-- se accede a una nueva posicion de memoria.
entity memreader is
	port(	clk:in std_logic;
			reset:in std_logic;
			button:in std_logic;
			rd:out std_logic;
			addr:inout std_logic_vector(7 downto 0)
			);
end memreader;

architecture Behavioral of memreader is
type ESTADOS is (s0,s1,s2);
signal estado,nestado:ESTADOS;
signal suma:std_logic;
begin
	process(clk,reset)
		begin
			if reset='0' then
				estado <= s0;
			elsif clk'event and clk='1' then
				estado <= nestado;
			end if;
		end process;
	
	process(estado,button)
		begin
			nestado <= estado;
			suma <= '0';
			rd <= '0';
			case estado is
				when s0 =>
					if button='0' then
						rd <= '1';
						nestado <= s1;
					end if;
				when s1 =>
					if button='1' then
						nestado <= s2;
					end if;
				when s2 =>
					suma <= '1';
					nestado <= s0;
			end case;
		end process;
		
	process(suma,clk,reset)
		begin
			if reset='0' then
				addr <= (others=>'0');
			elsif clk'event and clk='1' and suma='1' then
				addr <= addr+1;
			end if;
		end process;

end Behavioral;

