library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package kbd_ctrl_pckg is
	component kbd_ctrl
		port(	clk:in std_logic;
				reset:in std_logic;
				din:in std_logic_vector(7 downto 0);
				ready:in std_logic;
				done:in std_logic;
				addr:out std_logic_vector(7 downto 0);
				dout:out std_logic_vector(5 downto 0);
				we:out std_logic;
				cuenta:inout std_logic_vector(7 downto 0);
				led:out std_logic_vector(1 downto 0)
				);
	end component;
end package kbd_ctrl_pckg;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity kbd_ctrl is
	port(	clk:in std_logic;
			reset:in std_logic;
			din:in std_logic_vector(7 downto 0);
			ready:in std_logic;
			done:in std_logic;
			addr:out std_logic_vector(7 downto 0);
			dout:out std_logic_vector(5 downto 0);
			we:out std_logic;
			cuenta:inout std_logic_vector(7 downto 0);
			led:out std_logic_vector(1 downto 0)
			);
end kbd_ctrl;

architecture Behavioral of kbd_ctrl is
type ESTADOS is (s0,s1,s2);
signal estado,nestado:ESTADOS;
type tabla is array(0 to 2**8-1) of std_logic_vector(5 downto 0);
signal add_addr,loaddout:std_logic;
signal rom:tabla:=(
69=>"000000",22=>"000001",30=>"000010",38=>"000011",37=>"000100",
46=>"000101",54=>"000110",61=>"000111",62=>"001000",70=>"001001",
28=>"001010",50=>"001011",33=>"001100",35=>"001101",36=>"001110",
43=>"001111",52=>"010000",51=>"010001",67=>"010010",59=>"010011",
66=>"010100",75=>"010101",58=>"010110",49=>"010111",68=>"011000",
77=>"011001",21=>"011010",45=>"011011",27=>"011100",44=>"011101",
60=>"011110",42=>"011111",29=>"100000",34=>"100001",53=>"100010",
26=>"100011",41=>"100100",others=>"000000");

begin
	addr <= cuenta;
		
	process(clk,reset)
		begin
			if reset='0' then
				estado <= s0;
			elsif clk'event and clk='1' then
				estado <= nestado;
			end if;
		end process;

	process(din,ready)
		begin
			nestado <= estado;
			we <= '0';
			add_addr <= '0';
			loaddout <= '0';
			led <= "00";
			case estado is
				when s0 =>
					if ready='1' then
						loaddout <= '1';
						nestado <= s1;
					end if;
				when s1 =>
					led <= "01";
					if ready='0' then
						nestado <= s2;
					end if;
				when s2 =>
					led <= "10";
					we <= '1';
					if done='1' then
						add_addr <= '1';
						nestado <= s0;
					end if;
				when others => null;
			end case;
		end process;

	process(clk,reset,add_addr,loaddout)
		begin
			if reset='0' then
				cuenta <= (others=>'0');
				dout <= (others=>'0');
			elsif clk'event and clk='1' then
				if add_addr='1' then
					cuenta <= cuenta+1;
				end if;
				if loaddout='1' then
					dout <= rom(conv_integer(din));
				end if;
			end if;
		end process;

end Behavioral;

