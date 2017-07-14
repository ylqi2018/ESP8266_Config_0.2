----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/11/2017 04:24:16 PM
-- Design Name: 
-- Module Name: ESP8266_ClientConfig - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use	IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ESP8266_ClientConfig is
	port (
		clk		:	in	STD_LOGIC;
		rst		:	in	STD_LOGIC;
		rx		:	in	STD_LOGIC;
		tx		:	out	STD_LOGIC
	);
end ESP8266_ClientConfig;

architecture Behavioral of ESP8266_ClientConfig is

-- ##### component UART #####
	component uart is
	generic (
		baud                : positive;
		clock_frequency     : positive
		);
	port (  
		clock               :   in  std_logic;
		reset               :   in  std_logic;    
		data_stream_in      :   in  std_logic_vector(7 downto 0);
		data_stream_in_stb  :   in  std_logic;
		data_stream_in_ack  :   out std_logic;
		data_stream_out     :   out std_logic_vector(7 downto 0);
		data_stream_out_stb :   out std_logic;
		tx                  :   out std_logic;
		rx                  :   in  std_logic
		);
	end component;

    component ila_uart
    PORT (
        clk : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe3 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe5 : IN STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
    end component;


-- ##### type definition #####
	type	CMDString	is	array(natural range<>) of character;
		
-- ##### Config cmd #####
-- ####### Connect to WiFi hotspot #######
	CONSTANT	N0			:	natural		:= 2;
	CONSTANT	AT			:	CMDString(0 to N0-1)	:= "AT";
	CONSTANT	N1			:	natural		:= 11;
	CONSTANT	ATCWMODE	:	CMDString(0 to N1-1)	:= "AT+CWMODE=3";
	CONSTANT	N2			:	natural		:= 23;
	CONSTANT	ATCWJAP		:	CMDString(0 to N2-1)	:= "AT+CWJAP=""UNT_DRONE"",""""";
--	CONSTANT	N2			:	natural		:= 22;
--    CONSTANT    ATCWJAP     :    CMDString(0 to N2-1)    := "AT+CWJAP=""UNT_CTRL"",""""";
	CONSTANT	N3			:	natural		:= 25;
	CONSTANT	ATCIPSTA	:	CMDString(0 to N3-1)	:= "AT+CIPSTA=""192.168.43.90""";
		
signal	model_sel	:	STD_LOGIC_VECTOR(3 DOWNTO 0);	-- which case the State Machine is

signal	index		:	STD_LOGIC_VECTOR(7 DOWNTO 0);	
signal	char_index	:	natural     range 0 to N3-1;
signal	cmd_over	:	STD_LOGIC	:= '0';
signal  length_sig  :   STD_LOGIC_VECTOR(5 DOWNTO 0);
signal  byte_to_tx  :   STD_LOGIC_VECTOR(7 DOWNTO 0);
signal  send_byte   :   STD_LOGIC_VECTOR(7 DOWNTO 0);

signal	cnt_t1		:	STD_LOGIC_VECTOR(7 DOWNTO 0);

-- #########
signal  data_stream_in      :   STD_LOGIC_VECTOR(7 downto 0);	-- port data_stream_in connect to byte_to_tx to send
signal 	data_stream_in_stb 	: 	STD_LOGIC	:= '0';
signal  data_stream_in_ack  :   STD_LOGIC;
signal  data_stream_out     :   STD_LOGIC_VECTOR(7 downto 0); 
signal  data_stream_out_stb :   STD_LOGIC;
		
begin

--cmd1_s???
	
	model_sel_proc: process(clk, rst)
	begin
		if(rst = '1') then
			index		<= (others => '0');			-- STD_LOGIC_VECTOR
			model_sel	<= (others => '0');			-- STD_LOGIC_VECTOR
		elsif(clk'event and clk = '1') then
			char_index	<= conv_integer(index);	-- natural
			case model_sel is
				when "0000" => 
					length_sig	<= conv_std_logic_vector(N0, 6);	--"AT" N0=2, length_sig="000010"
					byte_to_tx	<= std_logic_vector(to_unsigned(character'pos(AT(char_index)),8));
				
				when "0001" =>
					length_sig 	<= conv_std_logic_vector(N1, 6);	--ATCWMODE, N1=11 length_sig="001011"
					byte_to_tx	<= std_logic_vector(to_unsigned(character'pos(ATCWMODE(char_index)),8));
					
				when "0010" =>
                    length_sig    <= conv_std_logic_vector(N2, 6);    --ATCWJAP, N2=23, length_sig="010111"
                    byte_to_tx    <= std_logic_vector(to_unsigned(character'pos(ATCWJAP(char_index)),8));
                
                when "0011" =>
                    length_sig    <= conv_std_logic_vector(N3, 6);    --ATCIPSTA, length_sig="011001"
                    byte_to_tx    <= std_logic_vector(to_unsigned(character'pos(ATCIPSTA(char_index)),8));
						
				when others =>
					length_sig	<= conv_std_logic_vector(N3, 6);
					byte_to_tx	<= (others => '0');				
			end case;
				
			if(index < length_sig) then
				char_index <= conv_integer(index);
				send_byte <= byte_to_tx;
				data_stream_in_stb <= '1';
				if(data_stream_in_ack = '1') then   -- Finish send one byte
					data_stream_in_stb <= '0';
					index <= index + 1;
				end if;
				cmd_over <= '0';
			elsif(index = length_sig) then
				send_byte <= x"0D";		-- carrage return
				data_stream_in_stb <= '1';
				if(data_stream_in_ack = '1') then				--data_stream_in_ack <= '1';	-- Give the signal that, CMD has been send over
					data_stream_in_stb <= '0';
					index <= index + 1;
					--cmd_over <= '1';
--                    if(model_sel = 4) then
--                    	model_sel <= (others => '0');
--                    end if;
				end if;
				cmd_over <= '0';
			elsif(index = length_sig + 1) then
				send_byte <= x"0A";
				data_stream_in_stb <= '1';
				if(data_stream_in_ack = '1') then
					data_stream_in_stb <= '0';
					index <= (others => '0');
					if(model_sel <= 3) then
						model_sel <= model_sel + 1;
					else
						model_sel <= (others => '0');
					end if;
				end if;
			end if;			
		end if;	
	end process model_sel_proc;


inst_uart : uart 
	generic map(
		baud             => 115200   ,        
		clock_frequency  => 100000000
		)
	port map(
		clock               =>  clk         ,
		reset               =>  rst                 ,
		data_stream_in      =>  send_byte			,
		data_stream_in_stb  =>  data_stream_in_stb  ,
		data_stream_in_ack  =>  data_stream_in_ack  ,
		data_stream_out     =>  data_stream_out     ,
		data_stream_out_stb =>  data_stream_out_stb ,
		tx                  =>  tx                  ,
		rx                  =>  rx
		);

inst_ila_uart: ila_uart
    PORT map(
        clk 		=> clk		,			--: IN STD_LOGIC;
        probe0 		=> send_byte,			--: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe1(0) 	=> data_stream_in_stb,	--: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe2(0) 	=> data_stream_in_stb,	--: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe3 		=> index,		--: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe4(0) 	=> data_stream_out_stb,	--: IN STD_LOGIC_VECTOR(0 DOWNTO 0)
        probe5      => model_sel
    );

end Behavioral;
