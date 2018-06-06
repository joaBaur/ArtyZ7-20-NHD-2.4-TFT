----------------------------------------------------------------------------------
-- Company: Baur 3.0 Service GmbH
-- Engineer: Joachim Baur
-- 
-- Create Date: 01.06.2018
-- Module Name: NHD_24_240320CF_Init - Behavioral
-- Description: initialization sequence for ST7789S driver ic in NHD-2.4-240320CF tft
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity NHD_24_240320CF_Init is
    Port ( 
        i_sys_clock     : in STD_LOGIC;                         -- 125 MHz system clock 
        i_reset         : in STD_LOGIC;                         -- reset (connected to btn0 of board)
        i_driver_ready  : in STD_LOGIC;                         -- display driver is ready for next output

        o_write_start   : out STD_LOGIC;                        -- write start signal for driver
        o_dc	        : out STD_LOGIC;                        -- data/command for driver
        o_db	        : out STD_LOGIC_VECTOR (15 downto 0);   -- 16 bit data bus for driver
        o_rs            : out STD_LOGIC;                        -- tft reset wire

        o_ready         : out STD_LOGIC                         -- init sequence completed
    );
end NHD_24_240320CF_Init;

architecture Behavioral of NHD_24_240320CF_Init is

	type init_phase is (
		PowerUp,
		PowerUpWait,
		Reset,
		ResetWait,
		ResetDelayAfter,
		DisplayOff,
		ExitSleep,
		ExitSleepWait,
		Madctrl,
		Madctrl_1,
		Colmod,
		Colmod_1,
		Porctrk,
		Porctrk_1,
		Porctrk_2,
		Porctrk_3,
		Porctrk_4,
		Porctrk_5,
		Gctrl,
		Gctrl_1,
		Vcom,
		Vcom_1,
		Lcm,
		Lcm_1,
		Vdvvrhen,
		Vdvvrhen_1,
		Vdvvrhen_2,
		Vhrs,
		Vhrs_1,
		Vdvs,
		Vdvs_1,
		Frctrl2,
		Frctrl2_1,
		Pwctrl1,
		Pwctrl1_1,
		Pwctrl1_2,
		Pvgamctrl,
		Pvgamctrl_1,
		Pvgamctrl_2,
		Pvgamctrl_3,
		Pvgamctrl_4,
		Pvgamctrl_5,
		Pvgamctrl_6,
		Pvgamctrl_7,
		Pvgamctrl_8,
		Pvgamctrl_9,
		Pvgamctrl_10,
		Pvgamctrl_11,
		Pvgamctrl_12,
		Pvgamctrl_13,
		Pvgamctrl_14,
		Nvgamctrl,
		Nvgamctrl_1,
		Nvgamctrl_2,
		Nvgamctrl_3,
		Nvgamctrl_4,
		Nvgamctrl_5,
		Nvgamctrl_6,
		Nvgamctrl_7,
		Nvgamctrl_8,
		Nvgamctrl_9,
		Nvgamctrl_10,
		Nvgamctrl_11,
		Nvgamctrl_12,
		Nvgamctrl_13,
		Nvgamctrl_14,
		Xadrset,
		Xadrset_1,
		Xadrset_2,
		Xadrset_3,
		Xadrset_4,
		Yadrset,
		Yadrset_1,
		Yadrset_2,
		Yadrset_3,
		Yadrset_4,
		Dspon,
		DsponWait,
		Finished,
		SendToDisplayDriver,
		WaitForDisplayDriver
		);
    signal curr_state : init_phase := PowerUp;
    signal next_state : init_phase := PowerUp;

    -- register buffers for output signals
    signal rs_reg            : STD_LOGIC := '1'; -- reset is active low, therefore high at startup
    signal dc_reg            : STD_LOGIC := '0';
    signal ws_reg            : STD_LOGIC := '0';
    signal db_reg            : std_logic_vector (15 downto 0) := (others => '0');

    signal ready_reg         : STD_LOGIC := '0';

    -- register for internal state of the driver's ready signal
    signal last_driver_ready : STD_LOGIC := '0';
	
begin

	init_sequence: process (i_sys_clock)
	
    -- delay in clock cycles (1 clock cycle @ 125 MHz = 8ns), 1 ms = 1,000,000 ns = 125,000 clock cycles
	variable delay_cycles : integer range 0 to 15000000 := 0;

	constant DC_CMD  : STD_LOGIC := '0'; -- tft dc wire pulled low: command
    constant DC_DATA : STD_LOGIC := '1'; -- tft dc wire pulled high: data

	begin
        if rising_edge(i_sys_clock) then
            
            if i_reset = '1' then
                ready_reg <= '0';
                curr_state <= RESET;
            else

                case curr_state is

                    when PowerUp =>
                        rs_reg <= '1'; -- pull reset high
                        -- init wait after power up for 120 ms (15,000,000 clock cycles * 8 ns)
                        delay_cycles := 15000000; -- 120 ms
                        curr_state <= PowerUpWait;

                    when PowerUpWait =>
                        -- wait for end of delay
						if delay_cycles = 0 then
							curr_state <= Reset;
                        else
                            delay_cycles := delay_cycles - 1;
						end if;

					when Reset =>
						rs_reg <= '0'; --  pull reset low = reset ACTIVE
                        --- init wait for reset pulse min duration = 20 us = 20,000 ns (2,500 clock cycles * 8 ns)
                        -- make it 30 us = 3,750 clock cycles
                        delay_cycles := 3750; 
                        curr_state <= ResetWait;

					when ResetWait =>
                        -- wait for end of delay
						if delay_cycles = 0 then
							rs_reg <= '1'; -- pull reset high again
                            -- init wait after reset for 120 ms (15,000,000 clock cycles * 8 ns)
							delay_cycles := 15000000; 
							curr_state <= ResetDelayAfter;
                        else 
                            delay_cycles := delay_cycles - 1;
						end if;
						
					when ResetDelayAfter => 
                        -- wait for end of delay
					    if delay_cycles = 0 then
                            curr_state <= DisplayOff;
                        else 
                            delay_cycles := delay_cycles - 1;
                        end if;

					when DisplayOff =>
                        -- CMD 0x0028, display off
						dc_reg <= DC_CMD;
                        db_reg <= x"0028";
                        curr_state <= SendToDisplayDriver;
                        next_state <= ExitSleep;

                    when ExitSleep =>
                        -- CMD 0x0011, exit sleep
						dc_reg <= DC_CMD;
                        db_reg <= x"0011";
 
                        -- init wait 100 ms (12,500,000 clock cycles * 8 ns)
                        delay_cycles := 12500000;

                        curr_state <= SendToDisplayDriver;
                        next_state <= ExitSleepWait;

                    when ExitSleepWait =>
                        -- wait for end of delay
						if delay_cycles = 0 then
							curr_state <= Madctrl;
                        else
                            delay_cycles := delay_cycles - 1;
						end if;

					when Madctrl =>
                        -- CMD 0x0036 MADCTRL
						dc_reg <= DC_CMD;
                        db_reg <= x"0036";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Madctrl_1;

                    when Madctrl_1 =>
                        -- DATA 0x0080 MADCTRL
						dc_reg <= DC_DATA;
                        db_reg <= x"0080";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Colmod;

                    when Colmod =>
                        -- CMD 0x003A COLMOD
						dc_reg <= DC_CMD;
                        db_reg <= x"003A";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Colmod_1;

                    when Colmod_1 =>
                        -- DATA 0x0055 COLMOD
						dc_reg <= DC_DATA;
                        db_reg <= x"0055";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Porctrk;

                    when Porctrk =>
                        -- CMD 0x00B2 PORCTRK
						dc_reg <= DC_CMD;
                        db_reg <= x"00B2";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Porctrk_1;

                    when Porctrk_1 =>
                        -- DATA 0x000C PORCTRK 1
						dc_reg <= DC_DATA;
                        db_reg <= x"000C";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Porctrk_2;

                    when Porctrk_2 =>
                        -- DATA 0x000C PORCTRK 2
						dc_reg <= DC_DATA;
                        db_reg <= x"000C";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Porctrk_3;

                    when Porctrk_3 =>
                        -- DATA 0x0000 PORCTRK 3
						dc_reg <= DC_DATA;
                        db_reg <= x"0000";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Porctrk_4;

                    when Porctrk_4 =>
                        -- DATA 0x0033 PORCTRK 4
						dc_reg <= DC_DATA;
                        db_reg <= x"0033";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Porctrk_5;

                    when Porctrk_5 =>
                        -- DATA 0x0033 PORCTRK 5
						dc_reg <= DC_DATA;
                        db_reg <= x"0033";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Gctrl;

                    when Gctrl =>
                        -- CMD 0x00B7 GCTRL
						dc_reg <= DC_CMD;
                        db_reg <= x"00B7";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Gctrl_1;

                    when Gctrl_1 =>
                        -- DATA 0x0035 GCTRL
						dc_reg <= DC_DATA;
                        db_reg <= x"0035";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Vcom;

                    when Vcom =>
                        -- CMD 0x00BB VCOM
						dc_reg <= DC_CMD;
                        db_reg <= x"00BB";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Vcom_1;

                    when Vcom_1 =>
                        -- DATA 0x002B VCOM
						dc_reg <= DC_DATA;
                        db_reg <= x"002B";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Lcm;

                    when Lcm =>
                        -- CMD 0x00C0 LCM
						dc_reg <= DC_CMD;
                        db_reg <= x"00C0";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Lcm_1;

                    when Lcm_1 =>
                        -- DATA 0x002C LCM
						dc_reg <= DC_DATA;
                        db_reg <= x"002C";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Vdvvrhen;

                    when Vdvvrhen =>
                        -- CMD 0x00C2 VDVVRHEN
						dc_reg <= DC_CMD;
                        db_reg <= x"00C2";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Vdvvrhen_1;

                    when Vdvvrhen_1 =>
                        -- DATA 0x0001 VDVVRHEN 1
						dc_reg <= DC_DATA;
                        db_reg <= x"0001";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Vdvvrhen_2;

                    when Vdvvrhen_2 =>
                        -- DATA 0x00FF VDVVRHEN 2
						dc_reg <= DC_DATA;
                        db_reg <= x"00FF";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Vhrs;

                    when Vhrs =>
                        -- CMD 0x00C3 VHRS
						dc_reg <= DC_CMD;
                        db_reg <= x"00C3";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Vhrs_1;

                    when Vhrs_1 =>
                        -- DATA 0x0011 VHRS
						dc_reg <= DC_DATA;
                        db_reg <= x"0011";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Vdvs;

                    when Vdvs =>
                        -- CMD 0x00C4 VDVS
						dc_reg <= DC_CMD;
                        db_reg <= x"00C4";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Vdvs_1;

                    when Vdvs_1 =>
                        -- DATA 0x0020 VDVS
						dc_reg <= DC_DATA;
                        db_reg <= x"0020";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Frctrl2;

                    when Frctrl2 =>
                        -- CMD 0x00C6 FRCTRL2
						dc_reg <= DC_CMD;
                        db_reg <= x"00C6";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Frctrl2_1;

                    when Frctrl2_1 =>
                        -- DATA 0x000F FRCTRL2
						dc_reg <= DC_DATA;
                        db_reg <= x"000F";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pwctrl1;

                    when Pwctrl1 =>
                        -- CMD 0x00D0 PWCTRL1
						dc_reg <= DC_CMD;
                        db_reg <= x"00D0";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pwctrl1_1;

                    when Pwctrl1_1 =>
                        -- DATA 0x00A4 PWCTRL1 1
						dc_reg <= DC_DATA;
                        db_reg <= x"00A4";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pwctrl1_2;

                    when Pwctrl1_2 =>
                        -- DATA 0x00A1 PWCTRL1 2
						dc_reg <= DC_DATA;
                        db_reg <= x"00A1";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl;

                    when Pvgamctrl =>
                        -- CMD 0x00E0 PVGAMCTRL
						dc_reg <= DC_CMD;
                        db_reg <= x"00E0";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl_1;

                    when Pvgamctrl_1 =>
                        -- DATA 0x00D0 PVGAMCTRL 1
						dc_reg <= DC_DATA;
                        db_reg <= x"00D0";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl_2;

                    when Pvgamctrl_2 =>
                        -- DATA 0x0000 PVGAMCTRL 2
						dc_reg <= DC_DATA;
                        db_reg <= x"0000";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl_3;

                    when Pvgamctrl_3 =>
                        -- DATA 0x0005 PVGAMCTRL 3
						dc_reg <= DC_DATA;
                        db_reg <= x"0005";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl_4;

                    when Pvgamctrl_4 =>
                        -- DATA 0x000E PVGAMCTRL 4
						dc_reg <= DC_DATA;
                        db_reg <= x"000E";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl_5;

                    when Pvgamctrl_5 =>
                        -- DATA 0x0015 PVGAMCTRL 5
						dc_reg <= DC_DATA;
                        db_reg <= x"0015";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl_6;

                    when Pvgamctrl_6 =>
                        -- DATA 0x000D PVGAMCTRL 6
						dc_reg <= DC_DATA;
                        db_reg <= x"000D";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl_7;

                    when Pvgamctrl_7 =>
                        -- DATA 0x0037 PVGAMCTRL 7
						dc_reg <= DC_DATA;
                        db_reg <= x"0037";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl_8;

                    when Pvgamctrl_8 =>
                        -- DATA 0x0043 PVGAMCTRL 8
						dc_reg <= DC_DATA;
                        db_reg <= x"0043";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl_9;

                    when Pvgamctrl_9 =>
                        -- DATA 0x0047 PVGAMCTRL 9
						dc_reg <= DC_DATA;
                        db_reg <= x"0047";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl_10;

                    when Pvgamctrl_10 =>
                        -- DATA 0x0009 PVGAMCTRL 10
						dc_reg <= DC_DATA;
                        db_reg <= x"0009";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl_11;

                    when Pvgamctrl_11 =>
                        -- DATA 0x0015 PVGAMCTRL 11
						dc_reg <= DC_DATA;
                        db_reg <= x"0015";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl_12;

                    when Pvgamctrl_12 =>
                        -- DATA 0x0012 PVGAMCTRL 12
						dc_reg <= DC_DATA;
                        db_reg <= x"0012";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl_13;

                    when Pvgamctrl_13 =>
                        -- DATA 0x0016 PVGAMCTRL 13
						dc_reg <= DC_DATA;
                        db_reg <= x"0016";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Pvgamctrl_14;

                    when Pvgamctrl_14 =>
                        -- DATA 0x0019 PVGAMCTRL 14
						dc_reg <= DC_DATA;
                        db_reg <= x"0019";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl;

                    when Nvgamctrl =>
                        -- CMD 0x00E1 NVGAMCTRL
						dc_reg <= DC_CMD;
                        db_reg <= x"00E1";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl_1;

                    when Nvgamctrl_1 =>
                        -- DATA 0x00D0 NVGAMCTRL 1
						dc_reg <= DC_DATA;
                        db_reg <= x"00D0";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl_2;

                    when Nvgamctrl_2 =>
                        -- DATA 0x0000 NVGAMCTRL 2
						dc_reg <= DC_DATA;
                        db_reg <= x"0000";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl_3;

                    when Nvgamctrl_3 =>
                        -- DATA 0x0005 NVGAMCTRL 3
						dc_reg <= DC_DATA;
                        db_reg <= x"0005";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl_4;

                    when Nvgamctrl_4 =>
                        -- DATA 0x000D NVGAMCTRL 4
						dc_reg <= DC_DATA;
                        db_reg <= x"000D";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl_5;

                    when Nvgamctrl_5 =>
                        -- DATA 0x000C NVGAMCTRL 5
						dc_reg <= DC_DATA;
                        db_reg <= x"000C";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl_6;

                    when Nvgamctrl_6 =>
                        -- DATA 0x0006 NVGAMCTRL 6
						dc_reg <= DC_DATA;
                        db_reg <= x"0006";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl_7;

                    when Nvgamctrl_7 =>
                        -- DATA 0x002D NVGAMCTRL 7
						dc_reg <= DC_DATA;
                        db_reg <= x"002D";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl_8;

                    when Nvgamctrl_8 =>
                        -- DATA 0x0044 NVGAMCTRL 8
						dc_reg <= DC_DATA;
                        db_reg <= x"0044";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl_9;

                    when Nvgamctrl_9 =>
                        -- DATA 0x0040 NVGAMCTRL 9
						dc_reg <= DC_DATA;
                        db_reg <= x"0040";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl_10;

                    when Nvgamctrl_10 =>
                        -- DATA 0x000E NVGAMCTRL 10
						dc_reg <= DC_DATA;
                        db_reg <= x"000E";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl_11;

                    when Nvgamctrl_11 =>
                        -- DATA 0x001C NVGAMCTRL 11
						dc_reg <= DC_DATA;
                        db_reg <= x"001C";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl_12;

                    when Nvgamctrl_12 =>
                        -- DATA 0x0018 NVGAMCTRL 12
						dc_reg <= DC_DATA;
                        db_reg <= x"0018";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl_13;

                    when Nvgamctrl_13 =>
                        -- DATA 0x0016 NVGAMCTRL 13
						dc_reg <= DC_DATA;
                        db_reg <= x"0016";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Nvgamctrl_14;

                    when Nvgamctrl_14 =>
                        -- DATA 0x0019 NVGAMCTRL 14
						dc_reg <= DC_DATA;
                        db_reg <= x"0019";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Xadrset;

                    when Xadrset =>
                        -- CMD 0x002A XADRSET
						dc_reg <= DC_CMD;
                        db_reg <= x"002A";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Xadrset_1;

                    when Xadrset_1 =>
                        -- DATA 0x0000 XADRSET 1
						dc_reg <= DC_DATA;
                        db_reg <= x"0000";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Xadrset_2;

                    when Xadrset_2 =>
                        -- DATA 0x0000 XADRSET 2
						dc_reg <= DC_DATA;
                        db_reg <= x"0000";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Xadrset_3;

                    when Xadrset_3 =>
                        -- DATA 0x0000 XADRSET 3
						dc_reg <= DC_DATA;
                        db_reg <= x"0000";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Xadrset_4;

                    when Xadrset_4 =>
                        -- DATA 0x00EF XADRSET 4
						dc_reg <= DC_DATA;
                        db_reg <= x"00EF";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Yadrset;

                    when Yadrset =>
                        -- CMD 0x002B YADRSET
						dc_reg <= DC_CMD;
                        db_reg <= x"002B";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Yadrset_1;

                    when Yadrset_1 =>
                        -- DATA 0x0000 YADRSET 1
						dc_reg <= DC_DATA;
                        db_reg <= x"0000";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Yadrset_2;

                    when Yadrset_2 =>
                        -- DATA 0x0000 YADRSET 2
						dc_reg <= DC_DATA;
                        db_reg <= x"0000";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Yadrset_3;

                    when Yadrset_3 =>
                        -- DATA 0x0001 YADRSET 3
						dc_reg <= DC_DATA;
                        db_reg <= x"0001";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Yadrset_4;

                    when Yadrset_4 =>
                        -- DATA 0x003F YADRSET 4
						dc_reg <= DC_DATA;
                        db_reg <= x"003F";
                        curr_state <= SendToDisplayDriver;
                        next_state <= Dspon;

                     when Dspon =>
                        -- CMD 0x0029 DISPON
						dc_reg <= DC_CMD;
                        db_reg <= x"0029";
                        curr_state <= SendToDisplayDriver;
                        next_state <= DsponWait;

                        -- wait 50 ms after DISPON
                        delay_cycles := 6250000;

                    when DsponWait =>
						if delay_cycles = 0 then
							curr_state <= Finished;
                        else
                            delay_cycles := delay_cycles - 1;
						end if;

					when Finished => 
						ready_reg <= '1';

                    --

                    when SendToDisplayDriver =>
                        if i_driver_ready = '1' then
                    	   ws_reg <= '1';
                    	   curr_state <= WaitForDisplayDriver;
                        end if;

                    when WaitForDisplayDriver =>
                        ws_reg <= '0';
                    	if i_driver_ready = '1' and last_driver_ready = '0' then
                    	   curr_state <= next_state;
                    	end if;

                    --

                    when others =>
                        curr_state <= Finished;

            	end case;
            
            end if;
            
            last_driver_ready <= i_driver_ready;
             
        end if;
    end process init_sequence;

    -- output the register buffers to the ports
    o_write_start   <= ws_reg;
    o_dc            <= dc_reg;
    o_db            <= db_reg;
    o_rs            <= rs_reg; 

    o_ready         <= ready_reg;

end Behavioral;
