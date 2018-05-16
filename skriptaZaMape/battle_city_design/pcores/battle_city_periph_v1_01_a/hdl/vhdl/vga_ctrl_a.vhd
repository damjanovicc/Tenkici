-------------------------------------------------------------------------------
--
-- @author Milos Subotic <milos.subotic.sm@gmail.com>
-- @license MIT
--
-- @brief VGA controller.
--
-------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

library battle_city_periph_v1_01_a;
	use battle_city_periph_v1_01_a.vga_ctrl;
	use battle_city_periph_v1_01_a.clk_gen_100MHz;

architecture arch_v1 of vga_ctrl is

	signal clk_100MHz : std_logic;
	signal locked     : std_logic;
	signal n_reset    : std_logic;

	signal stage      : unsigned(1 downto 0);
	signal en_25MHz   : std_logic;

	signal pixel_x    : unsigned(9 downto 0);
	signal pixel_y    : unsigned(8 downto 0);

	signal vga_clk    : std_logic;

	signal red        : std_logic_vector(7 downto 0);
	signal green      : std_logic_vector(7 downto 0);
	signal blue       : std_logic_vector(7 downto 0);
	
	signal pixel_x_d1 : unsigned(9 downto 0);
	signal pixel_y_d1 : unsigned(8 downto 0);
	
	signal n_blank    : std_logic;
	signal n_h_sync   : std_logic;
	signal n_v_sync   : std_logic;
	signal n_sync     : std_logic;
begin

	-- Clock generation.
clk_1: if false generate
	clk_gen: entity clk_gen_100MHz
	port map(
		i_clk_24MHz  => i_clk_24MHz,
		in_reset     => in_reset,
		o_clk_100MHz => clk_100MHz,
		o_locked     => locked
	);
	n_reset      <= locked;
end generate;
clk_2: if true generate
	clk_100MHz   <= i_bus_clk;
	n_reset      <= in_bus_rst;
end generate;
	
	o_clk_100MHz <= clk_100MHz;
	on_reset     <= n_reset;
	
	stage_cnt: process(clk_100MHz)
	begin
		if rising_edge(clk_100MHz) then
			if n_reset = '0' then
				stage <= "00";
			else
				if stage = "11" then
					stage <= "00";
				else
					stage <= stage + 1;
				end if;
			end if;
		end if;
	end process stage_cnt;
	
	o_stage <= stage;
	
	-- Setting enable in 0th stage so we could have change on FFs between 3rd and 0th stage.
	en_25MHz <= '1' when stage = "11" else '0';
	
	pixel_x_cnt: process(clk_100MHz)
	begin
		if rising_edge(clk_100MHz) then
			if n_reset = '0' then
				pixel_x <= (others => '0');
			else
				if en_25MHz = '1' then
					if pixel_x = (640+16+96+48)-1 then
						pixel_x <= (others => '0');
					else
						pixel_x <= pixel_x + 1;
					end if;
				end if;
			end if;
		end if;
	end process pixel_x_cnt;
	o_pixel_x <= pixel_x;
	
	pixel_y_cnt: process(clk_100MHz)
	begin
		if rising_edge(clk_100MHz) then
			if n_reset = '0' then
				pixel_y <= (others => '0');
			else
				if en_25MHz = '1' and pixel_x = (640+16+96+48)-1 then
					if pixel_y = (480+10+2+33)-1 then
						pixel_y <= (others => '0');
					else
						pixel_y <= pixel_y + 1;
					end if;
				end if;
			end if;
		end if;
	end process pixel_y_cnt;
	o_pixel_y <= pixel_y;
	
	
	vga_clk_reg: process(clk_100MHz)
	begin
		if rising_edge(clk_100MHz) then
			vga_clk <= stage(1);
		end if;
	end process vga_clk_reg;
	o_vga_clk <= vga_clk;

	rgb_reg: process(clk_100MHz)
	begin
		if rising_edge(clk_100MHz) then
			if stage = "00" then
				red   <= i_red;
				green <= i_green;
				blue  <= i_blue;
			end if;
		end if;
	end process rgb_reg;
	o_red   <= red;
	o_green <= green;
	o_blue  <= blue;
	
	delay: process(clk_100MHz)
	begin
		if rising_edge(clk_100MHz) then
			if en_25MHz = '1' then
				pixel_x_d1 <= pixel_x;
				pixel_y_d1 <= pixel_y;
			end if;
		end if;
	end process delay;
	
	
	sync: process(clk_100MHz)
	begin
		if rising_edge(clk_100MHz) then
			if en_25MHz = '1' then
				if pixel_x_d1 >= 640 or pixel_y_d1 >= 480 then
					n_blank <= '0';
				else
					n_blank <= '1';
				end if;
				if 640+16 <= pixel_x_d1 and pixel_x_d1 < 640+16+96 then
					n_h_sync <= '0';
				else
					n_h_sync <= '1';
				end if;
				if 480+10 <= pixel_y_d1 and pixel_y_d1 < 480+10+2 then
					n_v_sync <= '0';
				else
					n_v_sync <= '1';
				end if;
				if (640+16 <= pixel_x_d1 and pixel_x_d1 < 640+16+96) or (480+10 <= pixel_y_d1 and pixel_y_d1 < 480+10+2) then
					n_sync <= '0';
				else
					n_sync <= '1';
				end if;
			end if;
		end if;
	end process sync;
	on_blank  <= n_blank;
	on_h_sync <= n_h_sync;
	on_v_sync <= n_v_sync;
	on_sync   <= n_sync;
	
	on_pow_save <= '1';
	
end architecture arch_v1;
