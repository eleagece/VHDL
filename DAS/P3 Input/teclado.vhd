library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-------------------------------------------------------------------------------------------------------
-- Entity teclado
-------------------------------------------------------------------------------------------------------
entity teclado is
	port ( clkTecl: in std_logic; -- reloj del teclado
		    --clk: in std_logic; -- reloj del diseño
			 reset: in std_logic; -- reset global
			 bitSerie: in std_logic; -- bit que se recibe en serie del teclado, primero el menos significativo
			 --data_out: out std_logic_vector(7 downto 0);
			 codIzq7seg: out std_logic_vector(6 downto 0); -- código del dígito izquierdo para mostrar por el 7 segmentos
			 codDer7seg: out std_logic_vector(6 downto 0) ); -- código del dígito derecho para mostrar por el 7 segmentos
end teclado;

-------------------------------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------------------------------
architecture Behavioral of teclado is

--> Components
component conv7seg is
	port ( entrada: in std_logic_vector(3 downto 0);
			 salida: out std_logic_vector(6 downto 0) );
end component;

--> Types, signals
signal data: std_logic_vector (10 downto 0); -- 11 bits acumulados del flujo recibido por bitSerie
signal contador: std_logic_vector (3 downto 0); -- contador para identificar 11 ciclos
signal dataOk: std_logic_vector(7 downto 0); -- 8 bits que identifican tecla actual
signal dataAnt: std_logic_vector(7 downto 0); -- 8 bits que identifican tecla anterior
-->> conv7seg
signal salidaIzq7seg: std_logic_vector(6 downto 0);
signal salidaDer7seg: std_logic_vector(6 downto 0);

--> Begin architecture
begin
codIzq7seg<=salidaIzq7seg;
codDer7seg<=salidaDer7seg;

-->> Component port maps
conv7segIzqComp: conv7seg port map(dataOk(7 downto 4),salidaIzq7seg);
conv7segDerComp: conv7seg port map(dataOk(3 downto 0),salidaDer7seg);

-->> Process
-->>> Proceso de obtención de bits en serie en data
process(clkTecl)
begin
	if (clkTecl'event and clkTecl='0') then
		data<=data(9 downto 0) & bitSerie;
	end if;
end process;

-->>> Proceso para mostrar el código de tecla en los displays 7 segmentos
process(reset,clkTecl,contador)--,clkTecl,contador)
begin
	if (reset='1') then
		dataOk<="00000000";
		dataAnt<="00000000";
		contador<="0000"; -- indica el ciclo por el que vamos. Según el ciclo el valor bitSerie significará una cosa u otra.
								-- en este caso bitSerie en C1=0, en C2-9=dato, en C10-11=10
	elsif (clkTecl'event and clkTecl='0') then
		if (contador="1010") then -- si estamos en C11...
			dataOk<=data(9 downto 2); -- ...preparamos dataOk para poder mostrar la tecla pulsada por el 7seg en el siguiente ciclo (C1)
			dataAnt<=data(9 downto 2); -- ...preparamos dataAnt para poder mostrar la tecla pulsada por el 7seg en los ciclos siguientes (C2-C11)
			contador<="0000";
		else -- si no estamos en C11...
			dataOk<=dataAnt; -- ...preparamos dataOk para poder mostrar la tecla pulsada por el 7seg en los ciclos siguientes (C2-C11)
			contador<=contador+1; -- ...aumentamos contador
		end if;
	end if;
end process;

end Behavioral;