library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package M_IN is
	component morse_in
		port(	sclk:in std_logic;								-- sclk del akm, tambien sirve para el automata
				lrck:in std_logic;								-- lrck del akm
				reset:in std_logic;								-- reset del sistema
				sdto:in std_logic;								-- sdto del akm
				dot:inout std_logic; 							-- para debug, se enciende siempre que coge un dot
				cuenta:inout std_logic_vector(7 downto 0);-- letras recibidas(los espacios tambien cuentan)
				addr:out std_logic_vector(7 downto 0);		-- direccion de memoria donde va a escribir
				we:out std_logic;									-- write enable
				dout:out std_logic_vector(5 downto 0)		-- data out para escribir en memoria
				);
	end component;
end package M_IN;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Version revisada, probar.
entity morse_in is
	port(	sclk:in std_logic;								-- sclk del akm, tambien sirve para el automata
			lrck:in std_logic;								-- lrck del akm
			reset:in std_logic;								-- reset del sistema
			sdto:in std_logic;								-- sdto del akm
			dot:inout std_logic; 							-- para debug, se enciende siempre que coge un dot
			cuenta:inout std_logic_vector(7 downto 0);-- letras recibidas(los espacios tambien cuentan)
			addr:out std_logic_vector(7 downto 0);		-- direccion de memoria donde va a escribir
			we:out std_logic;									-- write enable
			dout:out std_logic_vector(5 downto 0)		-- data out para escribir en memoria
			);
end morse_in;

architecture Behavioral of morse_in is
---------------------------------------
-- SEÑALES DEL AUTOMATA
-- estados del automata
type ESTADOS is (widle,idle,dot1,wdot1,dot2,wdot2,dot3,wdot3,storedot,storedash,space1,wspace1,space2,wspace2,space3,wspace3);
-- memoria donde se tienen guardadas las letras asociadas a los codigos que genera el automata
type rom is array(0 to 2**8-1) of std_logic_vector(5 downto 0);
-- tabla de traduccion entre codigo del sonido y codificacion de la letra
signal tabla:rom:=(	32=>"001110",33=>"011101",64=>"010010",65=>"001010",66=>"010111",67=>"010110",
							96=>"011100",97=>"011110",98=>"011011",99=>"100000",100=>"001101",101=>"010100",
							102=>"010000",103=>"011000",128=>"010001",129=>"011111",130=>"001111",132=>"010101",
							134=>"011001",135=>"010011",136=>"001011",137=>"100001",138=>"001100",139=>"100010",
							140=>"100011",141=>"011010",160=>"000101",161=>"000100",163=>"000011",167=>"000010",
							175=>"000001",176=>"000110",184=>"000111",188=>"001000",190=>"001001",others=>"111111");
-- direccion base desde la que se van a hacer todas las escrituras
constant base_addr:natural:=0;
signal estado,nestado:ESTADOS;
-- señales de control para calcular los codigos asociados a cada letra
signal add_length,shift,reset_code,typedot,add_cuenta:std_logic;
-- longitud del codigo actual
signal leng:std_logic_vector(2 downto 0);
-- dots y dashes del codigo actual, 0=punto, 1=dash, se guardan de derecha a izquierda
signal code:std_logic_vector(4 downto 0);
-- codigo concatenado
signal fcode:std_logic_vector(7 downto 0);
---------------------------------------
---------------------------------------
-- SEÑALES DEL MUESTREADOR
-- muestra inmediatamente anterior. Por como esta construido el modulo, solo mira la muestra del canal izuierdo
signal sample:std_logic_vector(31 downto 0);
-- cada dot dura 1024 ciclos de lrck
signal nciclos:std_logic_vector(9 downto 0);
-- cada vez que se cuenta el espacio de un dot, sube ready
signal ready:std_logic;
---------------------------------------

begin
-- MUESTREADOR
---------------------------------------
-- El ADC muestrea una onda cuadrada que varia entre 7FXXX y 00XXX cuando no esta sonando
-- nada. Estos valores no se repiten cuando si esta muestreando algun sonido.
	-- proceso para shifting de la muestra
	process(sclk,reset)
		begin
			if reset='0' then
				sample <= (others=>'0');
			elsif sclk'event and sclk='0' then
				sample <= sample(30 downto 0) & sdto;
			end if;
		end process;
		
	-- proceso para contar cuantos ciclos se han esperado desde el ultimo sonido, para subir el bit ready
	process(lrck,reset)
		begin
			if reset='0' then
				nciclos <= (others=>'0');
			elsif lrck'event and lrck='0' then
				-- Esto evita posibles desfases entre los relojes de las fpgas. El bit ready
				-- sube antes de haber terminado de reconocer un dot/espacio, y se mantiene 
				-- activo el tiempo teorico que debe durar un dot.
				if nciclos>"1111111000" then
					ready <= '1';
				else
					ready <= '0';
				end if;
				nciclos <= nciclos+1;
			end if;
		end process;
	
	-- proceso para subir o bajar dot cuando es necesario hacerlo, actua con flanco de ready
	process(ready,reset)
		begin
			if reset='0' then
				dot <= '0';
			elsif ready'event and ready='1' then
				-- Si hay un flanco de subida de ready, significa que se ha agotado el tiempo de
				-- un dot. Como la ausencia de sonido sigue el patron de una onda cuadrada, hay
				-- un dot si la muestra anterior no es parte de una onda cuadrada. Cuando hay un
				-- espacio las muestras varian entre 7FXXX y 00XXX
				if (sample(31 downto 23)="011111111" or sample(31 downto 24)="00000000") then
					dot <= '0';
				else
					dot <= '1';
				end if;
			end if;
		end process;
---------------------------------------
-- AUTOMATA
	-- fcode contiene el codigo generado por el automata
	fcode <= leng & code;
	-- calculo de la direccion de memoria donde se escribe
	addr <= base_addr+cuenta;

	process(sclk,reset)
		begin
			if reset='0'  then
				estado <= widle;
			elsif sclk'event and sclk='1' then
				estado <= nestado;
			end if;
		end process;

	process(estado,ready,dot)
		begin
			nestado <= estado;
			add_cuenta <= '0';
			add_length <= '0';
			shift <= '0';
			reset_code <= '0';
			typedot <= '0';
			dout <= tabla(conv_integer(fcode));
			we <= '0';
			case estado is
				-- estado inicial, se resetean codigos, y si ready esta a baja se va al estado de espera idle.
				when widle =>
					reset_code <= '1';
					if ready='0' then
						nestado <= idle;
					end if;
				-- estado idle. Aqui se espera hasta que llegue un dot, mientras tanto no se hace nada, por lo que sirve como estado de error o timeout. 
				when idle =>
					-- si llega un dot nos esperamos a que baje ready y seguimos procesando la cadena de sonidos
					if ready='1' and dot='1' then
						nestado <= wdot1;
					end if;
				-- esperar a que baje ready
				when wdot1 =>
					if ready='0' then
						nestado <= dot1;
					end if;
				-- estado dot1. Ya se ha recibido un dot, si llega otro seguido es que viene un dash, si viene un espacio hay que ver el caso
				when dot1 =>
					if ready='1' then
						-- si viene otro dot entonces solo puede formar parte de un dash. ir al estado de espera y seguir procesando el sonido
						if dot='1' then
							nestado <= wdot2;
						-- si viene un espacio, esto era un dot, guardarlo
						else
							nestado <= storedot;
						end if;
					end if;
				-- esperar a que baje ready
				when wdot2 =>
					if ready='0' then
						nestado <= dot2;
					end if;
				-- estado dot2. Se han recibido 2 dots seguidos, solo se puede esperar otro mas, si viene un espacio es un error
				when dot2 =>
					if ready='1' then
						-- si viene otro punto el dash está completo
						if dot='1' then
							nestado <= wdot3;
						-- si viene un espacio es un error, no pueden venir 2 puntos seguidos de un espacio
						else
							nestado <= widle;
						end if;
					end if;
				-- esperar a que baje ready
				when wdot3 =>
					if ready='0' then
						nestado <= dot3;
					end if;
				-- estado dot3. Se han recibido 3 dots seguidos, si viene otro es un error, se espera un espacio
				when dot3 =>
					if ready='1' then
						-- si viene un espacio entonces hay que guardar, pues se ha recibido un dash completo
						if dot='0' then
							nestado <= storedash;
						-- si viene otro dot es un error, no hay ningun codigo que genere 4 dots seguidos
						else
							nestado <= widle;
						end if;
					end if;
				-- estado storedot. se guarda un punto en el codigo de letra
				when storedot =>
					add_length <= '1';
					shift <= '1';
					nestado <= wspace1;
				-- estado storedash. se guarda un dash en el codigo de letra
				when storedash =>
					typedot <= '1';
					add_length <= '1';
					shift <= '1';
					nestado <= wspace1;
				-- esperar a que baje ready
				when wspace1 =>
					if ready='0' then
						nestado <= space1;
					end if;
				-- estado space1. Se ha recibido un espacio, si viene otro dot era la separacion entre partes de una letra, si viene otro espacio
				-- puede ser separacion entre 2 letras o 2 palabras, y la letra se ha acabado
				when space1 =>
					if ready='1' then
						-- si viene un dot es otra parte de la misma letra
						if dot='1' then
							nestado <= wdot1;
						-- si viene un espacio es parte de una separacion entre 2 letras o 2 palabras, guardar a memoria el codigo almacenado hasta el momento
						else
							we <= '1';
							add_cuenta <= '1';
							nestado <= wspace2;
						end if;
					end if;
				-- esperar a que baje ready
				when wspace2 =>
					if ready='0' then
						nestado <= space2;
					end if;
				-- estado space2. Se han recibido 2 espacios seguidos, por lo que va a ser espacio entre 2 letras o entre 2 palabras, hay que esperar otro espacio.
				-- si viene un dot es un error. Si viene un espacio solo va a poder ser separacion entre letras o palabras distintas, por lo que se resetea el codigo.
				when space2 =>
					if ready='1' then
						if dot='0' then
							reset_code <= '1';
							nestado <= wspace3;
						else
							nestado <= widle;
						end if;
					end if;
				-- esperar a que baje ready
				when wspace3 =>
					if ready='0' then
						nestado <= space3;
					end if;
				-- estado space3. Se han recibido 3 espacios seguidos, si viene otro espacio, puede ser un timeout o la separacion entre 2 palabras. Si viene un dot era
				-- la separacion entre 2 letras, pero ya se resetearon los codigos antes.
				when space3 =>
					if ready='1' then
						-- separacion entre 2 letras, hay que guardar la letra a memoria
						if dot='1' then
							nestado <= wdot1;
						-- otro espacio, con este serian 4, como despues de esto solo puede venir un timeout o un espacio entre palabras, se guarda un espacio en memoria
						else
							we <= '1';
							dout <= "100100";
							add_cuenta <= '1';
							nestado <= widle;
						end if;
					end if;
			end case;
		end process;
		
		process(sclk,reset,add_cuenta,add_length,shift,reset_code)
			begin
				if reset='0' then
					cuenta <= (others=>'0');
				elsif reset='0' or reset_code='1' then
					leng <= (others=>'0');
					code <= (others=>'0');
				elsif sclk'event and sclk='1' then
					if add_length='1' then
						leng <= leng+1;
					end if;
					if shift='1' then
						code <= code(3 downto 0) & typedot;
					end if;
					if add_cuenta='1' then
						cuenta <= cuenta+1;
					end if;
				end if;
			end process;
end Behavioral;

