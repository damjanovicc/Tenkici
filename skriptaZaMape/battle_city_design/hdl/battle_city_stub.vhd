-------------------------------------------------------------------------------
-- battle_city_stub.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity battle_city_stub is
  port (
    RESET : in std_logic;
    CLK_P : in std_logic;
    CLK_N : in std_logic;
    vga_periph_mem_0_reset_n_i_pin : in std_logic;
    battle_city_periph_0_clk_24MHz_i_pin : in std_logic;
    battle_city_periph_0_rst_in_pin : in std_logic;
    battle_city_periph_0_h_sync_on_pin : out std_logic;
    battle_city_periph_0_v_sync_on_pin : out std_logic;
    battle_city_periph_0_blank_on_pin : out std_logic;
    battle_city_periph_0_vga_clk_o_pin : out std_logic;
    battle_city_periph_0_pow_save_on_pin : out std_logic;
    battle_city_periph_0_sync_on_pin : out std_logic;
    battle_city_periph_0_red_o_pin : out std_logic_vector(7 downto 0);
    battle_city_periph_0_green_o_pin : out std_logic_vector(7 downto 0);
    battle_city_periph_0_blue_o_pin : out std_logic_vector(7 downto 0);
    io_periph_GPIO_IO_I_pin : in std_logic_vector(4 downto 0)
  );
end battle_city_stub;

architecture STRUCTURE of battle_city_stub is

  component battle_city is
    port (
      RESET : in std_logic;
      CLK_P : in std_logic;
      CLK_N : in std_logic;
      vga_periph_mem_0_reset_n_i_pin : in std_logic;
      battle_city_periph_0_clk_24MHz_i_pin : in std_logic;
      battle_city_periph_0_rst_in_pin : in std_logic;
      battle_city_periph_0_h_sync_on_pin : out std_logic;
      battle_city_periph_0_v_sync_on_pin : out std_logic;
      battle_city_periph_0_blank_on_pin : out std_logic;
      battle_city_periph_0_vga_clk_o_pin : out std_logic;
      battle_city_periph_0_pow_save_on_pin : out std_logic;
      battle_city_periph_0_sync_on_pin : out std_logic;
      battle_city_periph_0_red_o_pin : out std_logic_vector(7 downto 0);
      battle_city_periph_0_green_o_pin : out std_logic_vector(7 downto 0);
      battle_city_periph_0_blue_o_pin : out std_logic_vector(7 downto 0);
      io_periph_GPIO_IO_I_pin : in std_logic_vector(4 downto 0)
    );
  end component;

  attribute BOX_TYPE : STRING;
  attribute BOX_TYPE of battle_city : component is "user_black_box";

begin

  battle_city_i : battle_city
    port map (
      RESET => RESET,
      CLK_P => CLK_P,
      CLK_N => CLK_N,
      vga_periph_mem_0_reset_n_i_pin => vga_periph_mem_0_reset_n_i_pin,
      battle_city_periph_0_clk_24MHz_i_pin => battle_city_periph_0_clk_24MHz_i_pin,
      battle_city_periph_0_rst_in_pin => battle_city_periph_0_rst_in_pin,
      battle_city_periph_0_h_sync_on_pin => battle_city_periph_0_h_sync_on_pin,
      battle_city_periph_0_v_sync_on_pin => battle_city_periph_0_v_sync_on_pin,
      battle_city_periph_0_blank_on_pin => battle_city_periph_0_blank_on_pin,
      battle_city_periph_0_vga_clk_o_pin => battle_city_periph_0_vga_clk_o_pin,
      battle_city_periph_0_pow_save_on_pin => battle_city_periph_0_pow_save_on_pin,
      battle_city_periph_0_sync_on_pin => battle_city_periph_0_sync_on_pin,
      battle_city_periph_0_red_o_pin => battle_city_periph_0_red_o_pin,
      battle_city_periph_0_green_o_pin => battle_city_periph_0_green_o_pin,
      battle_city_periph_0_blue_o_pin => battle_city_periph_0_blue_o_pin,
      io_periph_GPIO_IO_I_pin => io_periph_GPIO_IO_I_pin
    );

end architecture STRUCTURE;

