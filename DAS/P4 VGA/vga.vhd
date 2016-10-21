library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-------------------------------------------------------------------------------------------------------
-- Entity vgacore
-------------------------------------------------------------------------------------------------------
entity vgacore is
	port
	(
		reset: in std_logic;	-- reset
		clock: in std_logic; -- reloj de la FPGA a 100 Mhz
		hsyncb: inout std_logic;	-- horizontal (line) sync
		vsyncb: out std_logic;	-- vertical (frame) sync
		rgb: out std_logic_vector(8 downto 0); -- red,green,blue colors
		switches: in std_logic_vector(6 downto 0) -- para seleccionar el cuadrado
		
	);
end vgacore;

-------------------------------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------------------------------
architecture vgacore_arch of vgacore is

--> Components
component memoria is
	port ( clk: in std_logic;
			 reset: in std_logic; -- borra la memoria
			 en: in std_logic; -- enable
			 l: in std_logic; -- leer 1
			 e: in std_logic; -- escribir 1
			 dataIn: in std_logic_vector(8 downto 0); -- valor RGB para meter
			 dataOut: out std_logic_vector(8 downto 0); -- valor RGB para sacar
			 dir: in std_logic_vector(6 downto 0) ); -- selecciona una de las 128 posiciones para leer o escribir
end component memoria;

--> Types, cosntants, signals
-->> vgacore pantalla
signal hcnt: std_logic_vector(8 downto 0); -- horizontal pixel counter
signal vcnt: std_logic_vector(9 downto 0); -- vertical line counter
-->> vgacore reloj pantalla
signal contadorClk: std_logic_vector(1 downto 0); -- contador para dividir la frecuencia del contador interno
signal clk: std_logic; -- reloj interno
-->> vgacore reloj 1s
signal contadorClk2: std_logic_vector(25 downto 0);
signal clk2: std_logic; -- reloj interno
-->> memoria
signal re: std_logic;
signal wr: std_logic;
signal datosIn: std_logic_vector(8 downto 0);
signal datosOut: std_logic_vector(8 downto 0);
signal direccion: std_logic_vector(6 downto 0);

--> Begin architecture
begin

-->> Component port maps
-->>> Memoria
memoriaComp: memoria port map (clock,reset,'1',re,wr,datosIn,datosOut,direccion);

-->> Process
-->>> Proceso que consigue el reloj de 12,5 Mhz al que funciona la pantalla
process (reset,clock,contadorClk)
begin
	if (reset='1') then
		contadorClk<="00";
		clk<='0';
	elsif clock'event and clock='1' then
		if (contadorClk="11") then
			clk<=not clk;
			contadorClk<="00";
		else
			contadorClk<=contadorClk+1;
		end if;
	end if;
end process;

-->> Process
-->>> Proceso que consigue el reloj de 1 segundo
process (reset,clock,contadorClk2)
begin
	if (reset='1') then
		contadorClk2<=(others=>'0');
		--datos(3)<="111000000";
		clk2<='0';
	elsif clock'event and clock='1' then
		if (contadorClk2="10111110101111000010000000") then
			clk2<=not clk2;
			contadorClk2<=(others=>'0');
			--datos(3)<=datos(3)-"000000100";
		else
			contadorClk2<=contadorClk2+1;
		end if;
	end if;
end process;

-->>> Proceso A: aumenta hcnt con cada ciclo de reloj desde 0 a 380 y lo vuelve a 0.
A: process(clk,reset)
begin
	-- reset asynchronously clears pixel counter
	if reset='1' then
		hcnt <= "000000000";
	-- horiz. pixel counter increments on rising edge of dot clk
	elsif (clk'event and clk='1') then
		-- horiz. pixel counter rolls-over after 381 pixels
		if hcnt<380 then
			hcnt <= hcnt + 1;
		else
			hcnt <= "000000000";
		end if;
	end if;
end process;

-->>> Proceso B: aumenta vcnt con cada ciclo de hsyncb desde 0 a 527 y lo vuelve a 0.
B: process(hsyncb,reset)
begin
	-- reset asynchronously clears line counter
	if reset='1' then
		vcnt <= "0000000000";
	-- vert. line counter increments after every horiz. line
	elsif (hsyncb'event and hsyncb='1') then
		-- vert. line counter rolls-over after 528 lines
		if vcnt<527 then
			vcnt <= vcnt + 1;
		else
			vcnt <= "0000000000";
		end if;
	end if;
end process;

-->>> Proceso C
C: process(clk,reset)
begin
	-- reset asynchronously sets horizontal sync to inactive
	if reset='1' then
		hsyncb <= '1';
	-- horizontal sync is recomputed on the rising edge of every dot clk
	elsif (clk'event and clk='1') then
		-- horiz. sync is low in this interval to signal start of a new line
		if (hcnt>=291 and hcnt<337) then
			hsyncb <= '0';
		else
			hsyncb <= '1';
		end if;
	end if;
end process;

-->>> Proceso D
D: process(hsyncb,reset)
begin
	-- reset asynchronously sets vertical sync to inactive
	if reset='1' then
		vsyncb <= '1';
	-- vertical sync is recomputed at the end of every line of pixels
	elsif (hsyncb'event and hsyncb='1') then
		-- vert. sync is low in this interval to signal start of a new frame
		if (vcnt>=490 and vcnt<492) then
			vsyncb <= '0';
		else
			vsyncb <= '1';
		end if;
	end if;
end process;

-->>> Proceso de dibujado de rectángulos
process(vcnt,hcnt,switches)
begin
	re<='0'; wr<='0';
	if (vcnt>0 and vcnt<128) and 
		(hcnt>0 and hcnt<256) then
		if (switches=(vcnt(6 downto 4) & hcnt(7 downto 4))) then
			re<='0'; wr<='1';
			direccion<=vcnt(6 downto 4) & hcnt(7 downto 4);	
			datosIn<=(others=>'0');
			rgb<=(others=>'0');
		else
			re<='1'; wr<='0';
			direccion<=vcnt(6 downto 4) & hcnt(7 downto 4);
			rgb<=datosOut; -- pinta en el cuadrado n, la dirección de memoria n
		end if;
	else
		direccion<="0000000";
		rgb<=(others=>'0');
	end if;
end process;

end vgacore_arch;
