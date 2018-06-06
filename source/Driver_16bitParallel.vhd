----------------------------------------------------------------------------------
-- Company: Baur 3.0 Service GmbH
-- Engineer: Joachim Baur
-- 
-- Create Date: 01.06.2018
-- Module Name: Driver_16bitParallel - Behavioral
-- Description: Implements the 16 bit interface of the ST7789S Driver IC in the NHD-2.4-240320CF 
-- RGB-format is 5/6/5 bits
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Driver_16bitParallel is
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
end Driver_16bitParallel;

architecture Behavioral of Driver_16bitParallel is

    -- register buffers for output lines
    signal wr_reg : STD_LOGIC := '0';
    signal dc_reg : STD_LOGIC := '0';
    signal db_reg : std_logic_vector (15 downto 0) := (others => '0');
    
    signal ready_reg : STD_LOGIC := '1'; -- driver is ready at startup

    -- register for internal state of write_start
    signal last_write_start : STD_LOGIC := '0';

begin

    write_cycle: process (i_sys_clock)
    
    variable write_phase: integer range 0 to 6 := 6;  -- counter for rite cycle phases
    
    begin
        if rising_edge(i_sys_clock) then

            if i_write_start = '1' and last_write_start = '0' then 
                -- rising edge of i_write_start detected
                write_phase := 0;       -- start new write cycle
                ready_reg <= '0';       -- driver is busy
                dc_reg <= i_dc;         -- update d/c wire
            end if;

            if (write_phase < 6) then
                -- write cycle is active
                if (write_phase = 1) then
                    wr_reg <= '0';      -- set TFT wr wire to low
                    db_reg <= i_db;     -- update TFT data bus
                end if;
                if (write_phase = 5) then
                    wr_reg <= '1';      -- set TFT wr wire to high (rising edge: read data)
                    ready_reg <= '1';   -- driver is ready for next data transfer
                    -- it takes 4 additional cycles for new data to arrive
                end if;
                write_phase := write_phase + 1;
            end if;
            
            last_write_start <= i_write_start;  -- save value for comparison in next clock cycle
            
        end if;
    end process write_cycle;
    
    -- output the registers to the ports
    o_wr_tft <= wr_reg;
    o_dc_tft <= dc_reg;
    o_db_tft <= db_reg;
       
    o_ready <= ready_reg;

end Behavioral;
