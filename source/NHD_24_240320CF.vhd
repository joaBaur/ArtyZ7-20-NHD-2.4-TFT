-- Company: Baur 3.0 Service GmbH
-- Engineer: Joachim Baur
-- 
-- Create Date: 01.06.2018
-- Module Name: NHD_24_240320CF - Behavioral
-- Description: Top module to write data to the NHD_2.4_240320CF tft
-- Components Driver_16bitParallel and NHD_24_240320CF_Init
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity NHD_24_240320CF is
    Port (
    	sys_clock      : in STD_LOGIC; 				         -- 125 MHz system clock 
    	i_reset        : in STD_LOGIC;					     -- btn0 for reset
    	i_rgb_test     : in STD_LOGIC;                       -- sw1 to enable rgb test mode

    	o_wr           : out STD_LOGIC;						 -- tft write
    	o_dc           : out STD_LOGIC;						 -- tft data/command
    	o_db           : out STD_LOGIC_VECTOR (15 downto 0); -- tft 16 bit data bus
    	o_rs           : out STD_LOGIC;					 	 -- tft reset
    	
        bram_addrb  : out STD_LOGIC_VECTOR (16 downto 0);
        bram_doutb  : in STD_LOGIC_VECTOR (23 downto 0)
    );
end NHD_24_240320CF;

architecture Behavioral of NHD_24_240320CF is

component Driver_16bitParallel is
	Port ( 
		i_sys_clock     : in STD_LOGIC;                         -- 125 MHz system clock 
        i_write_start   : in STD_LOGIC;                         -- start output to TFT on rising edge of signal
        i_dc            : in STD_LOGIC;                         -- d/c status for output
        i_db            : in STD_LOGIC_VECTOR (15 downto 0);    -- 16 bit data for output
        o_wr_tft        : out STD_LOGIC;                        -- tft write
        o_dc_tft        : out STD_LOGIC;                        -- tft data/command  
        o_db_tft        : out STD_LOGIC_VECTOR (15 downto 0);   -- tft 16 bit data bus 
        o_ready         : out STD_LOGIC                         -- driver is ready for next command/data write
    );
end component;

component NHD_24_240320CF_Init is
	Port ( 
        i_sys_clock     : in STD_LOGIC;                         -- 125 MHz system clock 
        i_reset         : in STD_LOGIC;                         -- reset
        i_driver_ready  : in STD_LOGIC;                         -- display driver is ready for next output
        o_write_start   : out STD_LOGIC;                        -- write start signal for driver
        o_dc            : out STD_LOGIC;                        -- data/command for driver
        o_db            : out STD_LOGIC_VECTOR (15 downto 0);   -- 16 bit data bus for driver
        o_rs            : out STD_LOGIC;                        -- tft reset
        o_ready         : out STD_LOGIC                         -- init sequence completed
    );
end component;

	type display_phase is (
		TftReset,
		TftInit,
        TftBeginFrame,
        TftDisplayFrame,
        TftEndFrame,
		SendToDisplayDriver,
		WaitForDisplayDriver,
		Idle
	);
	signal curr_state : display_phase := TftInit;
    signal next_state : display_phase := TftInit;

	-- signals to connect the driver component
	signal ws_driver       : STD_LOGIC := '0';
	signal dc_driver       : STD_LOGIC := '0';
	signal db_driver       : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
	signal ready_driver    : STD_LOGIC := '0';

    -- register for internal state of the driver's ready signal
    signal last_ready_driver : STD_LOGIC := '0';

	-- signals to connect the init component
	signal ws_init         : STD_LOGIC := '0';
	signal dc_init         : STD_LOGIC := '0';
	signal db_init         : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
	signal ready_init      : STD_LOGIC := '0';

	-- register buffers for output lines
	signal ws_reg          : STD_LOGIC := '0';
	signal dc_reg          : STD_LOGIC := '0';
	signal db_reg          : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
	signal read_frame_reg  : STD_LOGIC := '0';

begin

	Driver_Comp : Driver_16bitParallel port map(
		i_sys_clock   => sys_clock,
		i_write_start => ws_driver,
		i_dc          => dc_driver,
		i_db          => db_driver,
		o_wr_tft      => o_wr,
		o_dc_tft      => o_dc,
		o_db_tft      => o_db,
		o_ready       => ready_driver
    );

	Init_Comp : NHD_24_240320CF_Init port map(
        i_sys_clock     => sys_clock,
        i_reset         => i_reset,
        i_driver_ready  => ready_driver,
        o_write_start   => ws_init,
        o_dc            => dc_init,
        o_db            => db_init,
        o_rs            => o_rs,
        o_ready         => ready_init
    );

	display: process(sys_clock)

    constant DC_CMD  : STD_LOGIC := '0'; -- tft dc wire pulled low: command
    constant DC_DATA : STD_LOGIC := '1'; -- tft dc wire pulled high: data

    variable curr_row : integer range 0 to 240 := 0; -- pixel# in row
    variable curr_col : integer range 0 to 320 := 0; -- pixel# in column

    variable frame_counter: integer range 0 to 160 := 0;
    variable color_selector : integer range 0 to 3 := 0;
    
    variable ram_address : integer range 0 to 76800 := 0;
    variable vid_data    : STD_LOGIC_VECTOR (23 downto 0) := (others => '0');

    begin
        if rising_edge(sys_clock) then

            if i_reset = '1' then
                curr_state <= TftReset;
            else
                case(curr_state) is

                    when TftReset =>
                        -- component NHD_24_240320CF_Init also received the reset signal
                        curr_state <= TftInit;

                    when TftInit =>
                        if ready_init = '1' then
                            -- initialization sequence for the TFT is finished
                            curr_state <= TftBeginFrame;
                        end if;

                    when TftBeginFrame =>
                        -- CMD 0x002C start ram write
                        dc_reg <= DC_CMD;
                        db_reg <= x"002C";
                        curr_state <= SendToDisplayDriver;
                        next_state <= TftDisplayFrame;

                    when TftDisplayFrame =>

                        -- i_rgb_test is connected to hardware switch SW1 on Arty board
                        if i_rgb_test = '1' then
                            -- read pixel data from block ram

                            -- don't set a new ram address during the last loop iteration when curr_col = 320
                            if curr_col < 320 then
                                ram_address := curr_row * 320 + curr_col;
                                bram_addrb <= conv_std_logic_vector(ram_address, bram_addrb'length);
                            end if;
                            
                            vid_data := bram_doutb;
                            
                            -- the vid_data requested from the ram read above takes 1 clock cycle to arrive
                            -- so ignore data on first cycle
                            if curr_col = 0 and curr_row < 1 then
                                -- do nothing
                            else
                                -- send the pixel data to the display
                                dc_reg <= DC_DATA;
                                -- vid_data byte order is R/B/G, not R/G/B!
                                db_reg(15 downto 11) <= vid_data(23 downto 19); -- 5 topmost bits of red
                                db_reg(10 downto  5) <= vid_data( 7 downto  2); -- 6 topmost bits of green
                                db_reg( 4 downto  0) <= vid_data(15 downto 11); -- 5 topmost bits of blue
                                    
                                curr_state <= SendToDisplayDriver;
                                next_state <= TftDisplayFrame;
                            end if;
                            
                            -- switch curr_col and _curr_row iterations in regard to block ram write
                            -- because the display driver expects the rows/cols in portrait orientation
                            -- but in the ram they are stored in landscape
                            curr_row := curr_row + 1;
                            if curr_row = 240 then
                                curr_row := 0;
                                curr_col := curr_col + 1;
                            end if;
                            
                            -- add 1 additional loop iteration after curr_col = 319 and curr_row = 239
                            -- because the pixel data from the ram takes 1 cycle to arrive
                            if curr_col = 320 and curr_row = 1 then
                                curr_col := 0;
                                curr_row := 0;
                                next_state <= TftEndFrame;
                            end if;
                        else
                            -- show fullscreen color sequence red/green/blue (5/6/5 bits)
                            dc_reg <= DC_DATA;
                            if color_selector = 0 then
                                db_reg <= "1111100000000000"; -- red,   x"F800"
                            end if;
                            if color_selector = 1 then
                                db_reg <= "0000011111100000"; -- green, x"07E0"
                            end if;
                            if color_selector = 2 then
                                db_reg <= "0000000000111111"; -- blue,  x"003F"
                            end if;
                            curr_state <= SendToDisplayDriver;
                            next_state <= TftDisplayFrame;

                            curr_col := curr_col + 1;
                            if curr_col = 320 then
                                curr_col := 0;
                                curr_row := curr_row + 1;
                                if curr_row = 240 then
                                    curr_row := 0;
                                    frame_counter := frame_counter + 1;
                                    if frame_counter = 160 then
                                        frame_counter := 0;
                                        color_selector := color_selector + 1;
                                        if color_selector = 3 then
                                            color_selector := 0;
                                        end if;
                                    end if;
                                    next_state <= TftEndFrame;
                                end if;
                            end if;
                        end if;

                    when TftEndFrame =>
                        -- CMD 0x0029 DISPON, stops ram write
                        dc_reg <= DC_CMD;
                        db_reg <= x"0029";
                        curr_state <= SendToDisplayDriver;
                        next_state <= TftBeginFrame;    -- start next frame

                    --

                    when SendToDisplayDriver =>
                        if ready_driver = '1' then
                            ws_reg <= '1';
                            curr_state <= WaitForDisplayDriver;
                        end if;

                    when WaitForDisplayDriver =>
                        ws_reg <= '0';
                        if ready_driver = '1' and last_ready_driver = '0' then
                            curr_state <= next_state;
                        end if;

                    -- 
                    when Idle =>
                        curr_state <= Idle;
                    when others =>
                        curr_state <= Idle;
                        
                end case;
            end if;
            
            last_ready_driver <= ready_driver;  -- save value for comparison in next clock cycle

        end if;
    end process display;

    -- MUX register output to ports depending on the current display_phase
    ws_driver <= ws_init when (curr_state = TftInit) else ws_reg;
    dc_driver <= dc_init when (curr_state = TftInit) else dc_reg;
    db_driver <= db_init when (curr_state = TftInit) else db_reg;

end Behavioral;
