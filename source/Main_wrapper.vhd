--Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2018.1 (win64) Build 2188600 Wed Apr  4 18:40:38 MDT 2018
--Date        : Fri Jun  8 10:09:59 2018
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
    ddc_scl_io : inout STD_LOGIC;
    ddc_sda_io : inout STD_LOGIC;
    hdmi_rx_clk_n : in STD_LOGIC;
    hdmi_rx_clk_p : in STD_LOGIC;
    hdmi_rx_data_n : in STD_LOGIC_VECTOR ( 2 downto 0 );
    hdmi_rx_data_p : in STD_LOGIC_VECTOR ( 2 downto 0 );
    hdmi_tx_clk_n : out STD_LOGIC;
    hdmi_tx_clk_p : out STD_LOGIC;
    hdmi_tx_data_n : out STD_LOGIC_VECTOR ( 2 downto 0 );
    hdmi_tx_data_p : out STD_LOGIC_VECTOR ( 2 downto 0 );
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
    ddc_scl_i : in STD_LOGIC;
    ddc_scl_o : out STD_LOGIC;
    ddc_scl_t : out STD_LOGIC;
    ddc_sda_i : in STD_LOGIC;
    ddc_sda_o : out STD_LOGIC;
    ddc_sda_t : out STD_LOGIC;
    o_db : out STD_LOGIC_VECTOR ( 15 downto 0 );
    o_dc : out STD_LOGIC;
    o_rs : out STD_LOGIC;
    o_wr : out STD_LOGIC;
    i_reset : in STD_LOGIC;
    i_resolution : in STD_LOGIC;
    i_rgb_test : in STD_LOGIC;
    sys_clock : in STD_LOGIC
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
  signal ddc_scl_i : STD_LOGIC;
  signal ddc_scl_o : STD_LOGIC;
  signal ddc_scl_t : STD_LOGIC;
  signal ddc_sda_i : STD_LOGIC;
  signal ddc_sda_o : STD_LOGIC;
  signal ddc_sda_t : STD_LOGIC;
begin
Main_i: component Main
     port map (
      ddc_scl_i => ddc_scl_i,
      ddc_scl_o => ddc_scl_o,
      ddc_scl_t => ddc_scl_t,
      ddc_sda_i => ddc_sda_i,
      ddc_sda_o => ddc_sda_o,
      ddc_sda_t => ddc_sda_t,
      hdmi_rx_clk_n => hdmi_rx_clk_n,
      hdmi_rx_clk_p => hdmi_rx_clk_p,
      hdmi_rx_data_n(2 downto 0) => hdmi_rx_data_n(2 downto 0),
      hdmi_rx_data_p(2 downto 0) => hdmi_rx_data_p(2 downto 0),
      hdmi_tx_clk_n => hdmi_tx_clk_n,
      hdmi_tx_clk_p => hdmi_tx_clk_p,
      hdmi_tx_data_n(2 downto 0) => hdmi_tx_data_n(2 downto 0),
      hdmi_tx_data_p(2 downto 0) => hdmi_tx_data_p(2 downto 0),
      i_reset => i_reset,
      i_resolution => i_resolution,
      i_rgb_test => i_rgb_test,
      o_db(15 downto 0) => o_db(15 downto 0),
      o_dc => o_dc,
      o_rs => o_rs,
      o_wr => o_wr,
      sys_clock => sys_clock
    );
ddc_scl_iobuf: component IOBUF
     port map (
      I => ddc_scl_o,
      IO => ddc_scl_io,
      O => ddc_scl_i,
      T => ddc_scl_t
    );
ddc_sda_iobuf: component IOBUF
     port map (
      I => ddc_sda_o,
      IO => ddc_sda_io,
      O => ddc_sda_i,
      T => ddc_sda_t
    );
end STRUCTURE;
