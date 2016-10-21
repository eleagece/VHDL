----------------------------------------------------------------------------------
-- Company:			 FDI 
-- Engineer: 		 Jorge Guirado
-- 
-- Create Date:    16:03:51 02/22/2010 
-- Design Name: 
-- Module Name:    morse_out - Behavioral 
-- Project Name:   morse_out
-- Target Devices: spartan3
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

package M_OUT is
	component morse_out is
		port(
			clk: 		in std_logic;								-- reloj de funcionamiento
			reset:	in std_logic;
			sdtio:	in std_logic;								-- frecuecia de pitido
			dout: 	in std_logic_vector(5 downto 0);		-- salida de la ram. letra a transmitir
			--en: in std_logic;
			transmit:in std_logic;								-- indicador de inicio de transmisión
			nwords:	in std_logic_vector(7 downto 0);		-- longitud de letras del mensaje (los espacios también cuentan)
			addr:		out std_logic_vector(7 downto 0);	-- dirección de lectura de la memoria del mensaje
			rd:		out std_logic;
			leds: 	out std_logic_vector(9 downto 0);	-- debug purposes
			sdti: 	out std_logic;								-- salida de audio
			ready:	out std_logic								-- listo para transmitir
			);
	end component;
end package M_OUT;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity morse_out is
	port(
		clk: 		in std_logic;								-- reloj de funcionamiento
		reset:	in std_logic;
		sdtio:	in std_logic;								-- frecuecia de pitido
		dout: 	in std_logic_vector(5 downto 0);		-- salida de la ram. letra a transmitir
		--en: in std_logic;
		transmit:in std_logic;								-- indicador de inicio de transmisión
		nwords:	in std_logic_vector(7 downto 0);		-- longitud de letras del mensaje (los espacios también cuentan)
		addr:		out std_logic_vector(7 downto 0);	-- dirección de lectura de la memoria del mensaje
		rd:		out std_logic;
		leds: 	out std_logic_vector(9 downto 0);	-- debug purposes
		sdti: 	out std_logic;								-- salida de audio
		ready:	out std_logic								-- listo para transmitir
		);
end morse_out;

architecture Behavioral of morse_out is

-- habilita la salida de audio
signal en: std_logic;
-- contador para el tamaño de la letra en morse
signal lword, nlword: std_logic_vector(2 downto 0);
-- código de la letra en morse: 1->punto, 0-> raya
signal dato, ndato: std_logic_vector(4 downto 0);
-- índice para recorrer la memoria del mensaje
signal dir, ndir: std_logic_vector(7 downto 0);

-- estados
type ESTADOS is (IDLE, WAIT1, WAIT2, WAIT3, WAIT4, DOT, LINE1, LINE2, LINE3, SPACE);
signal estado,nestado: ESTADOS;

--type data_test is array (0 to 10) of std_logic_vector(7 downto 0);
--signal mem_test: data_test:=(0=>"01100100", 1=>"01100000", 2=>"10010110", 3=>"11100001", 
--								4=>"01100100", 5=>"01100000", 6=>"10010110", others => "00000000");

-- tabla de conversión de letras a morse
-- 3 bits más siginificativos: tamaño de la letra
-- 5 bits menos significativos: código morse de la letra
-- Ejemplo:
--		C -> -.-.
-- 	tamaño = 4
--		código = 0101X
--		CONVERSIÓN ==>> 100 0101X
-- 
type data is array (0 to 63) of std_logic_vector(7 downto 0);
signal codex: data:=(
	0=>"10100000",  1=>"10110000", 2=>"10111000", 3=>"10111100", 4=>"10111110", 5=>"10111111", 
	6=>"10101111",  7=>"10100111", 8=>"10100011", 9=>"10100001", 10=>"01010000",11=>"10001110",
	12=>"10001010", 13=>"01101100",14=>"00110000",15=>"10011010",16=>"01100100",17=>"10011110",
	18=>"01011000", 19=>"10010000",20=>"01101000",21=>"10010110",22=>"01000000",23=>"01001000",
	24=>"01100000", 25=>"10010010",26=>"10000100",27=>"01110100",28=>"01111100",29=>"00100000",
	30=>"01111000", 31=>"10011100",32=>"01110000",33=>"10001100",34=>"10001000",35=>"10000110",
	36=>"11100000", others => "00000000");

begin

sdti <= sdtio when en='0' else '0';
addr <= dir;

	process(clk,reset,nestado,ndir,nlword,ndato)
		begin
			if reset='1' then
				estado<= IDLE;
				dir <= (others=>'0');
				lword <= "000";
				dato <= "00000";
			elsif clk'event and clk='1' then
				estado<=nestado;
				dir <= ndir;
				lword <= nlword;
				dato <= ndato;
			end if;
		end process;
		
	process(estado, nestado, transmit, nlword, ndato, ndir, dir, lword, dato)
		begin
			-- valores por defecto
			leds <= "0000000000";
			nestado <= estado;
			en <= '1';
			ndir <= dir;
			nlword <= lword;
			ndato <= dato;
			ready <= '0';
			rd<='0';
			case estado is
				when  IDLE		=>
					ready <= '1';
					-- comienzo de transmisión
					if transmit='0' then					
						nestado <= WAIT3;
					end if;
--				when  WAIT1	=>
--					nestado <= WAIT2;
--				when  WAIT2	=>
--					nestado <= WAIT3;
				when  WAIT3	=>
					-- lee la letra a transmitit
					rd<='1';
					nlword <= codex(conv_integer(dout))(7 downto 5);
					ndato <= codex(conv_integer(dout))(4 downto 0);
					nestado <= WAIT4;
				when  WAIT4	=>
					-- fin del mensaje
					if dir=nwords then
						nestado <= IDLE;
						ndir <= (others=>'0');
					-- espacio
					elsif lword="111" then
						nestado <= WAIT3;
						ndir <= dir+1;
					-- letra
					elsif lword/="000" then
						-- punto
						if dato(4)='1' then
							nestado <= DOT;
						-- raya
						else
							nestado <= LINE1;
						end if;
					-- fin de letra
					else
						nestado <= WAIT3;
						ndir <= dir+1;
					end if;
				when	DOT	=>
					leds <= "0000011111";
					-- habilita sonido
					en <= '0';
					-- decrementa el tamaño de la letra en morse
					nlword <= lword-1;
					-- actualiza el código a transmitir (desplaza a la izquierda)
					ndato <= dato(3 downto 0) & dato(4);
					nestado <= WAIT4;
				when	LINE1	=>
					leds <= "1111111111";
					-- habilita el sonido
					en <= '0';
					nestado <= LINE2;
				when	LINE2	=>
					leds <= "1111111111";
					-- habilita el sonido
					en <= '0';
					nestado <= LINE3;
				when 	LINE3 =>
					leds <= "1111111111";
					en <= '0';
					-- decrementa el tamaño de la letra en morse
					nlword <= lword-1;
					-- actualiza el código a transmitir (desplaza a la izquierda)
					ndato <= dato(3 downto 0) & dato(4);
					nestado <= WAIT4;
				when OTHERS => null;
			end case;
		end process;

end Behavioral;

