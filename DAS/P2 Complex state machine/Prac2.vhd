----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:54:08 11/11/2009 
-- Design Name: 
-- Module Name:    Prac2 - Behavioral 
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


entity c7seg is
	port(	W:in std_logic_vector(2 downto 0);
			F:out std_logic_vector(6 downto 0)
			);
end c7seg;


architecture behaviour of c7seg is
begin
	with w select
		F<=	"1111110" when "000",
				"0110000" when "001",
				"1101101" when "010",
				"1111001" when "011",
				"0110011" when "100",
				"1011011" when "101",
				"1011111" when "110",
				"1110000" when "111",
				"0000000" when others;
end behaviour;
---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Prac2 is
    Port ( 
				reset: in STD_LOGIC;
				reloj: in STD_LOGIC;
				clk_out: out STD_LOGIC;
           estado_out : out  STD_LOGIC_VECTOR (6 downto 0);
           palabra_out : out  STD_LOGIC_VECTOR (6 downto 0);
			  palCompr_out: out STD_LOGIC_VECTOR (2 downto 0));
			  
end Prac2;

architecture Behavioral of Prac2 is

component fifo is
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
end component fifo;
component c7seg is 
	port(	W:in std_logic_vector(2 downto 0);
			F:out std_logic_vector(6 downto 0)
			);
end component c7seg;

signal escribir,escribir_s,leer,leer_s,vacio,vacio_s,lleno,lleno_s,clk: std_logic;
signal palabra, sigPalabra: std_logic_vector (7 downto 0);
signal palCompr,palCompr_sig,p_out,estado_c7: std_logic_vector (2 downto 0);
signal estado_aux,palabra_aux: std_logic_vector (6 downto 0);
signal contador: std_logic_vector(25 downto 0);
signal lim: std_logic_vector(1 downto 0);
type TEstado is (SReset,S1,S12,S13,S14,S2,S3,S4,S5,S52,S53); 
signal estado,nestado:TEstado;


begin


process (reloj,contador,reset)
begin
	if reset='0' then
		contador<= (others=>'0');
		clk<='0';
	elsif reloj'event and reloj='1' then
		contador<=contador+1;
		if (contador ="10111110101111000010000000") then
			clk <= not clk;
			contador <= (others=>'0');
		end if;
	end if;
end process;

process (estado)
begin
	case estado is
		when SReset => estado_c7<="000";
		when S1 => estado_c7<="001";
		when S2 => estado_c7<="010";
		when S3 => estado_c7<="011";
		when S4 => estado_c7<="100";
		when S5 => estado_c7<="101";
		when S52 => estado_c7<="110";
		when S53 => estado_c7<="111";
		when others => estado_c7<="111";
	end case;
end process;
-- Proceso de cambio de estado
process(clk,reset)
begin
	if reset='0' then 
		estado<=SReset;
	elsif clk'event and clk='1' then
		estado<=nestado;
		palCompr<=palCompr_sig;
	end if;
end process;
--Proceso para modificar el limite
process(estado,clk)
begin
	if (clk'event and clk='1') then
		if (estado=S1) then
			if(lim="11") then
				lim <= "00";
			else lim<=lim+1;
			end if;
		else lim<="00";
		end if;
	end if;
end process;
--Asignamos palabras a leer de forma "automática"
--process(estado,clk, lim)
--begin
--	if (clk'event and clk='1') then
--		if (estado=S1) then
--			case lim is
--				when "00" => palabra<="11001100";
--				when "01" => palabra<="00000000";
--				when "10" => palabra<="11111110";
--				when "11" => palabra<="00000000";
--				when others => palabra<="11111111";
--			end case;
--		else palabra <="11111111";
--		end if;
--	end if;
--end process;
process(estado)
begin
	case estado is
		when S1 => palabra<="11111111";
		when S12 => palabra<="10001011";
		when S13 => palabra<="10101010";
		when S14 => palabra<="11001100";
		when others => palabra<="11111111";
	end case;
end process;
		
	
--Proceso compresión
process (estado,sigPalabra,palCompr)
begin
	palCompr_sig<=palCompr;
	case estado is
		when S2 =>
			case sigPalabra is
				when "00000000" => palCompr_sig<="000";
				when "10001011" => palCompr_sig<="001";
				when "10101010" => palCompr_sig<="010";
				when "11001100" => palCompr_sig<="011";
				when "00000001" => palCompr_sig<="100";
				when "10000001" => palCompr_sig<="101";
				when "11111110" => palCompr_sig<="110";
				when others => palCompr_sig<="111";
			end case;
		when S5 =>
			palCompr_sig<=sigPalabra(7 downto 5);
		when S52 => palCompr_sig<=sigPalabra(4 downto 2);
		when S53 => palCompr_sig(2)<=sigPalabra(1);
						palCompr_sig(1)<=sigPalabra(0);
						palCompr_sig(0)<='0';
		when others => palCompr_sig<="111";
	end case;
		
end process;
--Process para cambiar flags
process (estado)
begin
	leer<='0';
	leer_s<='0';
	escribir<='0';
	escribir_s<='0';
	case estado is
		when S1 => escribir<='1';
		when S12 => escribir<='1';
		when S13 => escribir<='1';
		when S14 => escribir<='1';
		when S2 => leer<='1';
		when S3 => escribir_s<='1';
		when S5 => escribir_s<='1';
		when S52 => escribir_s<='1';
		when S53 => escribir_s<='1';
		when others=> leer<='0';
				leer_s<='0';
				escribir<='0';
				escribir_s<='0';
	end case;
end process;
--Máquina de estados
process (estado,lim,vacio)
begin
	nestado<=estado;
	case estado is
		when SReset => --Estado de Reset
				nestado<=S1;
		when S1 => -- Metemos los datos de forma automática en la fifo de entrada.
		--	if (lim="11") then
		--		nestado<=S2;
		--	else nestado<=S1;
		--	end if;
			nestado<=S12;
		when S12=> nestado<=S13;
		when S13=> nestado<=S14;
		when S14=> nestado<=S2;
		when S2 => --Hacemos bucle para leer palabras de la fifo
				if(vacio='0') then
					nestado<=S3; -- Todavía queda por leer
				else nestado<=S4;
				end if;
		when S3=> --Escribimos la salida 
		--	if (vacio='0') then
		--		nestado<=S2;
		--	else nestado<=S4;
		--	end if;
		if(palCompr="111") then
			nestado<=S5;
		else 		nestado<=S2;
		end if;
		
		when S4 => -- Hemos terminado de leer y escribir la fifo
			nestado<=S4;
			
		when S5 => nestado<=S52;
		when S52 => nestado <= S53;
		when S53 => nestado <=S2;
	end case;
end process;
	

entrada: fifo generic map (8,3) port map (escribir,leer,clk,reset,palabra,sigPalabra,vacio,lleno);
salida: fifo generic map (3,3) port map (escribir_s,leer_s,clk,reset,palCompr,p_out,vacio_s,lleno_s);
salida_estado: c7seg port map(estado_c7,estado_aux);
salida_palabra: c7seg port map(palCompr,palabra_aux);
palCompr_out<=palCompr;
estado_out<=estado_aux;
palabra_out<=palabra_aux;	
clk_out<=clk;
end Behavioral;

