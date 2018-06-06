--Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2018.1 (win64) Build 2188600 Wed Apr  4 18:40:38 MDT 2018
--Date        : Fri Jun  1 13:29:58 2018
--Host        : CorsairWin10 running 64-bit major release  (build 9200)
--Command     : generate_target Main_wrapper.bd
--Design      : Main_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity Main_wrapper is
  port (
    hdmi_rx_clk_n : in STD_LOGIC;
    hdmi_rx_clk_p : in STD_LOGIC;
    hdmi_rx_data_n : in STD_LOGIC_VECTOR ( 2 downto 0 );
    hdmi_rx_data_p : in STD_LOGIC_VECTOR ( 2 downto 0 );
    hdmi_tx_clk_n : out STD_LOGIC;
    hdmi_tx_clk_p : out STD_LOGIC;
    hdmi_tx_data_n : out STD_LOGIC_VECTOR ( 2 downto 0 );
    hdmi_tx_data_p : out STD_LOGIC_VECTOR ( 2 downto 0 );
    i2c_scl_io : inout STD_LOGIC;
    i2c_sda_io : inout STD_LOGIC;
    i_reset : in STD_LOGIC;
    i_resolution : in STD_LOGIC;
    i_rgb_test : in STD_LOGIC;
    o_db : out STD_LOGIC_VECTOR ( 15 downto 0 );
    o_dc : out STD_LOGIC;
    o_rs : out STD_LOGIC;
    o_wr : out STD_LOGIC;
    sys_clock : in STD_LOGIC
  );
end Main_wrapper;

architecture STRUCTURE of Main_wrapper is
  component Main is
  port (
    hdmi_rx_clk_p : in STD_LOGIC;
    hdmi_rx_clk_n : in STD_LOGIC;
    hdmi_rx_data_p : in STD_LOGIC_VECTOR ( 2 downto 0 );
    hdmi_rx_data_n : in STD_LOGIC_VECTOR ( 2 downto 0 );
    hdmi_tx_clk_p : out STD_LOGIC;
    hdmi_tx_clk_n : out STD_LOGIC;
    hdmi_tx_data_p : out STD_LOGIC_VECTOR ( 2 downto 0 );
    hdmi_tx_data_n : out STD_LOGIC_VECTOR ( 2 downto 0 );
    i2c_scl_i : in STD_LOGIC;
    i2c_scl_o : out STD_LOGIC;
    i2c_scl_t : out STD_LOGIC;
    i2c_sda_i : in STD_LOGIC;
    i2c_sda_o : out STD_LOGIC;
    i2c_sda_t : out STD_LOGIC;
    sys_clock : in STD_LOGIC;
    o_wr : out STD_LOGIC;
    o_dc : out STD_LOGIC;
    o_db : out STD_LOGIC_VECTOR ( 15 downto 0 );
    o_rs : out STD_LOGIC;
    i_resolution : in STD_LOGIC;
    i_rgb_test : in STD_LOGIC;
    i_reset : in STD_LOGIC
  );
  end component Main;
  component IOBUF is
  port (
    I : in STD_LOGIC;
    O : out STD_LOGIC;
    T : in STD_LOGIC;
    IO : inout STD_LOGIC
  );
  end component IOBUF;
  signal i2c_scl_i : STD_LOGIC;
  signal i2c_scl_o : STD_LOGIC;
  signal i2c_scl_t : STD_LOGIC;
  signal i2c_sda_i : STD_LOGIC;
  signal i2c_sda_o : STD_LOGIC;
  signal i2c_sda_t : STD_LOGIC;
begin
Main_i: component Main
     port map (
      hdmi_rx_clk_n => hdmi_rx_clk_n,
      hdmi_rx_clk_p => hdmi_rx_clk_p,
      hdmi_rx_data_n(2 downto 0) => hdmi_rx_data_n(2 downto 0),
      hdmi_rx_data_p(2 downto 0) => hdmi_rx_data_p(2 downto 0),
      hdmi_tx_clk_n => hdmi_tx_clk_n,
      hdmi_tx_clk_p => hdmi_tx_clk_p,
      hdmi_tx_data_n(2 downto 0) => hdmi_tx_data_n(2 downto 0),
      hdmi_tx_data_p(2 downto 0) => hdmi_tx_data_p(2 downto 0),
      i2c_scl_i => i2c_scl_i,
      i2c_scl_o => i2c_scl_o,
      i2c_scl_t => i2c_scl_t,
      i2c_sda_i => i2c_sda_i,
      i2c_sda_o => i2c_sda_o,
      i2c_sda_t => i2c_sda_t,
      i_reset => i_reset,
      i_resolution => i_resolution,
      i_rgb_test => i_rgb_test,
      o_db(15 downto 0) => o_db(15 downto 0),
      o_dc => o_dc,
      o_rs => o_rs,
      o_wr => o_wr,
      sys_clock => sys_clock
    );
i2c_scl_iobuf: component IOBUF
     port map (
      I => i2c_scl_o,
      IO => i2c_scl_io,
      O => i2c_scl_i,
      T => i2c_scl_t
    );
i2c_sda_iobuf: component IOBUF
     port map (
      I => i2c_sda_o,
      IO => i2c_sda_io,
      O => i2c_sda_i,
      T => i2c_sda_t
    );
end STRUCTURE;
