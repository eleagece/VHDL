----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:12:18 10/16/2009 
-- Design Name: 
-- Module Name:    p1 - Behavioral 
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

entity p1 is
	generic(n:integer:=4; -- numero de productos
			  p:integer:=3 --bits de cantidad de cada producto
			  );
	port(entrada: in std_logic_vector(3 downto 0);
		  clk: in std_logic;
		  reset: in std_logic;
		  r: out std_logic;
		  e1: out std_logic;
		  e2: out std_logic;
		  e3: out std_logic;
		  e4: out std_logic;
		  producto_expedido:out std_logic;
		  producto_agotado:out std_logic
		  );
end p1;

architecture Behavioral of p1 is
type TEstado is (SReset,S1,S2,S3,S4); -- estado S1: idle, estado S2: pedir producto, estado S3: expedido/agotado, estado S4:wait
signal estado,nestado:TEstado;
signal agotado:std_logic;
--signal cantidad:std_logic_vector(n*p-1 downto 0);
signal c0,c1,c2,c3: std_logic_vector (2 downto 0);
signal reloj: std_logic;
signal contador: std_logic_vector (24 downto 0);

begin
	process(clk,reset) 
	begin
		if reset='0' then
			contador <= (others=>'0');
			reloj <= '0';
			r<='0';
		elsif clk'event and clk='1' then
				contador <= contador +1;
				if (contador = "1111111111111111111111111") then
					if (reloj = '0') then
						reloj <= '1';
						r <='1';
					else reloj <= '0';
						r<='0';
					end if;
				else null;
				end if;
		end if;
	end process;
	process(reloj,reset)
		begin
			if reset='0' then
				estado<=SReset;
			elsif reloj'event and reloj='1' then
				estado<=nestado;
			end if;
		end process;
	
	process(entrada,estado)
		begin
		producto_expedido <='0';
		producto_agotado<='0';
			case estado is
				when SReset =>
						c0 <= "111";
						c1 <= "111";
						c2 <= "111";
						c3 <= "111";
							agotado <= '0';
							nestado <=S1;
							e1 <= '0';
							e3 <= '0';
							e2 <= '0';
							e4 <= '0';
				when S1 => --if (entrada/=(others=>'0')) then
							--if (entrada(0) = '1' and entrada(1) ='0' and entrada(2) ='0' and entrada(3) ='0') then
								e1<='1';
								e4<='0';
								e2<='0';
								if (entrada /= "0000") then
								nestado<=S2;
								else nestado <=S1;
							  end if;
				when S2 => e1<='0';
							e2<='1';
							case entrada is
								when "0001" => 	if (c0 = "000") then agotado <='1';
														else c0 <= c0-1;
														end if;
														--if (c0>0) then c0 <= c0-1;-- bajar en 1 el producto si no esta agotado
														--else agotado <= '1'; -- si el producto esta agotado subir agotado
														--end if;
														nestado <= S3; -- pasar al estado de espera
															  -- todas las entradas son iguales
								when "0010" => if (c1 = "000") then agotado <='1';
														else c1 <= c1-1;
														end if;
														--if (c1>0) then c1 <= c1-1;-- bajar en 1 el producto si no esta agotado
														--else agotado <= '1'; -- si el producto esta agotado subir agotado
														--end if;
														nestado <= S3; -- pasar al estado de espera
															  -- todas las entradas son iguales
								when "0100" => if (c2 = "000") then agotado <='1';
														else c2 <= c2-1;
														end if;
													--	if (c2>0) then c2 <= c2-1;-- bajar en 1 el producto si no esta agotado
													--	else agotado <= '1'; -- si el producto esta agotado subir agotado
													--	end if;
														nestado <= S3; -- pasar al estado de espera
															  -- todas las entradas son iguales
								when "1000" => if (c3 = "000") then agotado <='1';
														else c3 <= c3-1;
														end if;
														--if (c3>0) then c3 <= c3-1;-- bajar en 1 el producto si no esta agotado
														--else agotado <= '1'; -- si el producto esta agotado subir agotado
														--end if;
														nestado <= S3; -- pasar al estado de espera
															  -- todas las entradas son iguales
								when others => nestado <= S1;
							  end case;
				
				when S3 => -- activar la salida durante un ciclo
							  -- comprobar si la señal agotado esta activa o no para elegir la salida
							  -- bajar señal agotado
							  e2<='0';
								e3<='1';
								if (agotado ='1') then
									producto_agotado <= '1';
								else producto_expedido <= '1';
								end if;
								agotado <= '0';
								nestado <= S4;
				
				when S4 => producto_agotado <= '0';
								producto_expedido <= '0';
								e3<='0';
								e4<='1';
								if (entrada = "0000") then
									nestado <= S1;
								else nestado <=S4;
								end if;
								-- bajar la señal y volver a idle
							  -- hacer un if para comprobar que se han bajado todos los switches y volver a idle
				
			
			end case;
		end process;
		
end Behavioral;

