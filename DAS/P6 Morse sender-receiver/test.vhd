library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.GCLK.all;
use WORK.M_IN.all;
use WORK.M_OUT.all;
use WORK.XSASDRAM.all;
use WORK.MEM_READER.all;
use WORK.kbd_ctrl_pckg.all;
use WORK.ps2_kbd_pckg.all;

entity test is
	port(	clk:in std_logic;
			clk_sd:in std_logic;
			reset:in std_logic;
			resetdb:in std_logic;
			pushb1:in std_logic;
			pushb2:in std_logic;
			sw:in std_logic_vector(2 downto 0);
			sdto:in std_logic;
			sdti:out std_logic;
			mclk:out std_logic;
			sclk:out std_logic;
			lrck:out std_logic;
			leds:out std_logic_vector(9 downto 0);
			disp:out std_logic_vector(6 downto 0);
			--------------------------------------
			hsyncb:inout std_logic;
			vsyncb:out std_logic;
			rgb:out std_logic_vector(8 downto 0);
			--------------------------------------
			ps2_clk:in std_logic;
			ps2_data:in std_logic;
			--------------------------------------
			sclkfb : in    std_logic;           -- clock from SDRAM after PCB delays
			sclk_sd: out   std_logic;        	-- SDRAM clock sync'ed to master clock
			cke    : out   std_logic;           -- clock-enable to SDRAM
			cs_n   : out   std_logic;           -- chip-select to SDRAM
			ras_n  : out   std_logic;           -- SDRAM row address strobe
			cas_n  : out   std_logic;           -- SDRAM column address strobe
			we_n   : out   std_logic;           -- SDRAM write enable
			ba     : out   std_logic_vector(1 downto 0);  -- SDRAM bank address bits
			sAddr  : out   std_logic_vector(12 downto 0);  -- SDRAM row/column address
			sData  : inout std_logic_vector(15 downto 0);  -- SDRAM in/out databus
			dqmh   : out   std_logic;           -- high databits I/O mask
			dqml   : out   std_logic            -- low databits I/O mask
			);
end test;

architecture Behavioral of test is

component vgacore
	port ( reset: in std_logic; -- reset
		    clock: in std_logic; -- reloj de la FPGA a 100 Mhz
			 weRX: in std_logic; -- llega dato nuevo
			 modo: in std_logic_vector(2 downto 0); -- permite recibir un mensaje
			 doutRX: in std_logic_vector(5 downto 0); -- dato actualmente leído de la memoria
		    hsyncb: inout std_logic; -- horizontal (line) sync
		    vsyncb: out std_logic;	-- vertical (frame) sync
		    rgb: out std_logic_vector(8 downto 0) ); -- red, green, blue colores
end component;

-- genclocks
signal mclko,sclko,lrcko,clkkb,clkdot,sdtio:std_logic;
-- morsein
signal dot,wrrx:std_logic;
signal addrrx,cuentarx:std_logic_vector(7 downto 0);
signal doutrx:std_logic_vector(5 downto 0);
-- morseout
signal rdtx,transmittx:std_logic;
signal addrtx:std_logic_vector(7 downto 0);
signal cuentatx:std_logic_vector(7 downto 0);
signal dintx:std_logic_vector(5 downto 0);
-- memoria externa
signal rd,wre,done:std_logic;
signal dout_sd,din_sd:std_logic_vector(15 downto 0);
signal addr_sd:std_logic_vector(22 downto 0);
-- interfaz de teclado
signal rdykb,errorkb:std_logic;
signal scancode:std_logic_vector(7 downto 0);
-- controlador de teclado
signal wrkb:std_logic;
signal addrkb,cuentakb:std_logic_vector(7 downto 0);
signal doutkb:std_logic_vector(5 downto 0);
-- ram interna
signal wri:std_logic;
signal dout_ram,dout_ram1,dout_ram2:std_logic_vector(5 downto 0);
-- memreader para debug
signal rddb:std_logic;
signal addrdb:std_logic_vector(7 downto 0);
-- error de memoria externa
signal leds2:std_logic_vector(1 downto 0);
-- modulo vga
signal dinvga:std_logic_vector(5 downto 0);
signal wrvga:std_logic;

signal resetkb:std_logic;
begin
	-- Modos de funcionamiento, el estado se muestra en un display
	-- Modo 0: 000 no se hace nada
	-- Modo 1: 001 escritura de mensajes por teclado
	-- Modo 2: 010 envio de sonidos, TX
	-- Modo 3: 011 recepcion de sonidos, RX
	-- Modos de depuracion
	-- Modo 4: 100 lectura de memoria externa
	
	-- seleccion de la direccion de la memoria externa
	addr_sd <= 	"000000000000000" & addrdb when sw="100" else
					"000000000000000" & addrtx when sw="010" else
					"000000000000000" & addrkb when sw="001" else
					(others=>'0');
	-- entrada de datos de la memoria externa
	din_sd <= 	"0000000000" & doutkb;
	-- Lectura de la memoria externa. Leen TX y debug
	rd <= rdtx when sw="010" else
			rddb when sw="100" else
			'0';
	-- Escritura de la memoria externa
	wre <= wrkb when sw="001" else
			'0';
	-- Entrada de TX
	dintx <= dout_sd(5 downto 0);
	-- Boton de transmision
	transmittx <= pushb1 when sw="010" else '1';
	-- Entradas de vga
	dinvga <= doutrx when sw="011" else doutkb;
	wrvga <= wrkb when sw="001" else
				wrrx when sw="011" else
				'0';
				

	
	-- generador de frecuencias
	gen1:genclocks port map(clk,reset,mclko,sclko,lrcko,sdtio,clkkb,clkdot);
	-- modulo de sonido out
	mout:morse_out port map(clkdot,not reset,sdtio,dintx,transmittx,cuentakb,addrtx,rdtx,open,sdti,open);
	-- modulo de muestreo de sonido y automata de reconocimiento
	min:morse_in port map(sclko,lrcko,reset,sdto,dot,cuentarx,open,wrrx,doutrx);
	-- Memoria SDRAM externa
	me:XSASDRAMCntl generic map(SADDR_WIDTH => 13)
		port map(clk_sd,open,open,open,open,not reset,rd,wre,open,open,open,done,open,
					addr_sd,din_sd,dout_sd,open,sclkfb,sclk_sd,cke,cs_n,ras_n,cas_n,we_n,ba,sAddr,
					sData,dqmh,dqml);
	-- Lector de memoria externa
	memr:memreader port map(clkdot,resetdb,pushb2,rddb,addrdb);
	-- interfaz del teclado
	k1:ps2_kbd generic map(25_000) port map(clkkb,not reset,ps2_clk,ps2_data,scancode,open,open,rdykb,errorkb);
	-- controlador del teclado
	k2:kbd_ctrl port map(clk,reset,scancode,rdykb,done,addrkb,doutkb,wrkb,cuentakb,leds2);
	-- vga
	vga:vgacore port map(not reset,clk,wrvga,sw,dinvga,hsyncb,vsyncb,rgb);
	
	mclk <= mclko;
	sclk <= sclko;
	lrck <= lrcko;
	
	-- leds del 1 al 6
	leds(5 downto 0) <= 	cuentakb(5 downto 0) when sw="001" else -- numero de teclas pulsadas
								dintx when sw="010" else -- entrada de datos tx
								cuentarx(5 downto 0) when sw="011" else -- numero de letras recibidas
								dout_sd(5 downto 0) when sw="100" else -- salida de datos de memoria externa
								(others=>'0');
	-- led 7 vacio
	leds(6) <= '0';
	-- leds 8 y 9 muestran estado de teclado, para error de memoria externa
	leds(8 downto 7) <= leds2;
	-- led 10 muestra si se ha recibido dot o espacio
	leds(9) <= dot;
	-- displays, muestran el modo en que se encuentra el sistema
	disp <= 	"0111111" when sw="000" else
				"0000110" when sw="001" else
				"1011011" when sw="010" else
				"1001111" when sw="011" else
				"1100110" when sw="100" else
				"1111001";
	
end Behavioral;
