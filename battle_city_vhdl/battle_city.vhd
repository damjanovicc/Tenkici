library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity battle_city is
   generic(
      DATA_WIDTH           : natural := 32;
      COLOR_WIDTH          : natural := 24;
      ADDR_WIDTH           : natural := 13;
      REGISTER_OFFSET      : natural := 0;      -- Pointer to registers in memory map
      C_BASEADDR           : natural := 0;      -- Pointer to local memory in memory map
      REGISTER_NUMBER      : natural := 10;     -- Number of registers used for sprites
      NUM_BITS_FOR_REG_NUM : natural := 4;      -- Number of bits required for number of registers
      MAP_OFFSET           : natural := 1424;   -- Pointer to start of map in memory
      OVERHEAD             : natural := 5;      -- Number of overhead bits
      SPRITE_Z             : natural := 0       -- Z coordinate of sprite
	);
   Port (
      clk_i          : in  std_logic;
      rst_n_i        : in  std_logic;
      pixel_row_i    : in  unsigned(8 downto 0);
      pixel_col_i    : in  unsigned(9 downto 0);
      bus_addr_i     : in  std_logic_vector(31 downto 0);            -- Address used to point to registers
      bus_data_i     : in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- Data to be writed to registers
      we_i           : in  std_logic;
      stage_i        : in  unsigned(1 downto 0);
      
		-- VGA --
		rgb_o          : out std_logic_vector(COLOR_WIDTH-1 downto 0)  -- Value of RGB color
   );
end battle_city;

architecture Behavioral of battle_city is

   component ram 	
   port
   (
      clk_i    : in  std_logic;
      addr_i   : in  unsigned(ADDR_WIDTH-1 downto 0 );
      data_o   : out std_logic_vector( DATA_WIDTH-1 downto 0 )
   );
   end component ram;

	-- Types --
   type registers_t  is array (0 to REGISTER_NUMBER-1) of unsigned (63 downto  0);
   type coor_row_t   is array (0 to REGISTER_NUMBER-1) of unsigned (8 downto 0);
   type coor_col_t   is array (0 to REGISTER_NUMBER-1) of unsigned (9 downto 0);
   type pointer_t    is array (0 to REGISTER_NUMBER-1) of unsigned (15 downto 0);
   type rotation_t   is array (0 to REGISTER_NUMBER-1) of unsigned (7 downto 0);
   type size_t       is array (0 to REGISTER_NUMBER-1) of unsigned (3 downto 0);
	
	-- Constants --
   constant size_8_c       : unsigned (3 downto 0) := "0111";
   constant overhead_c     : std_logic_vector( OVERHEAD-1 downto 0 ) := ( others => '0' );
	
   -- Globals --
   signal registers_s      : registers_t :=                                -- Array representing registers 
   --   row   |    col  |en&size|  rot  | pointer
   (( x"0000" & x"0001" & x"8f" & x"00" & x"03d0" ), 
    ( x"0011" & x"0001" & x"8f" & x"01" & x"03d0" ),
    ( x"0022" & x"0001" & x"8f" & x"02" & x"03d0" ),
    ( x"0033" & x"0001" & x"8f" & x"03" & x"03d0" ),
    ( x"0000" & x"0021" & x"8f" & x"00" & x"03d0" ), 
    ( x"0005" & x"0021" & x"8f" & x"01" & x"03d0" ),
    ( x"000a" & x"0021" & x"8f" & x"02" & x"03d0" ),
    ( x"000f" & x"0021" & x"8f" & x"03" & x"03d0" ),
    ( x"0008" & x"0008" & x"10" & x"00" & x"03d0" ),
    ( x"0008" & x"0008" & x"10" & x"00" & x"03d0" ));
    
   signal thrd_stg_addr_s  : unsigned(ADDR_WIDTH-1 downto 0);              -- Addresses needed in third stage
   signal scnd_stg_addr_s  : unsigned(ADDR_WIDTH-1 downto 0);              -- Addresses needed in second stage
   signal frst_stg_addr_s  : unsigned(ADDR_WIDTH-1 downto 0);              -- Addresses needed in first stage
   signal zero_stg_addr_s  : unsigned(ADDR_WIDTH-1 downto 0);              -- Addresses needed in zero stage
   signal glb_sprite_en_s  : std_logic;                                    -- Global sprite enable signal
   signal reg_intersected_s: unsigned(NUM_BITS_FOR_REG_NUM-1 downto 0);    -- Index of intersected sprite
   signal reg_row_s        : coor_row_t;                                   -- Sprite start row
   signal reg_col_s        : coor_col_t;                                   -- Sprite start column
   signal reg_rot_s        : rotation_t;                                   -- Rotation of sprite
   signal img_z_coor_s     : unsigned(7 downto 0);                         -- Z coor of static img
   signal img_z_coor_r     : unsigned(7 downto 0);                         -- Z coor of static img
   signal spr_color_idx_s  : unsigned(7 downto 0);                         -- Sprite color index
   signal address_s        : unsigned(ADDR_WIDTH-1 downto 0);              -- Memory address line 
	
   -- Memory --
   signal mem_data_s       : std_logic_vector(DATA_WIDTH-1 downto 0);      -- Data from local memory
   signal mem_address_s    : std_logic_vector(ADDR_WIDTH-1 downto 0);      -- Address used to read from memory
	
   -- Zero stage --
   signal local_addr_s     : signed(31 downto 0);	
   signal reg_size_s       : size_t;
   signal reg_en_s         : std_logic_vector(REGISTER_NUMBER-1 downto 0);
   signal reg_pointer_s    : pointer_t;
   signal reg_end_row_s    : coor_row_t;
   signal reg_end_col_s    : coor_col_t;
   signal reg_intsect_s    : std_logic_vector(REGISTER_NUMBER-1 downto 0);
   signal rel_addr_s       : unsigned(12 downto 0);
   signal map_index_s      : unsigned(11 downto 0);
	
   -- First stage --
   signal img_rot_s        : unsigned(7 downto 0);
   signal img_index_s      : unsigned(15 downto 0);
   signal img_row_s        : unsigned(2 downto 0);
   signal img_col_s        : unsigned(2 downto 0);
   signal img_tex_row_s    : unsigned(3 downto 0);
   signal img_tex_col_s    : unsigned(3 downto 0);
   signal img_tex_offset_s : unsigned(5 downto 0);
   signal img_tex_pix_sel_r: unsigned(1 downto 0);
   signal img_addr_s       : unsigned(ADDR_WIDTH-1 downto 0);
	
	-- Second stage --
   signal scnd_stg_data_s  : std_logic_vector(DATA_WIDTH-1 downto 0);
   signal max_s            : unsigned(3 downto 0);
   signal sprt_size_s      : std_logic;
   signal sprt_int_row_s   : unsigned(8 downto 0);
   signal sprt_int_col_s   : unsigned(9 downto 0);
   signal sprt_row_s       : unsigned(3 downto 0);
   signal sprt_col_s       : unsigned(3 downto 0);
   signal rot_s            : unsigned(7 downto 0);
   signal s_row_s          : unsigned(3 downto 0);
   signal s_col_s          : unsigned(3 downto 0);
   signal sprt_tex_offset_s: unsigned(7 downto 0);
   signal sprt_tex_offset_r: unsigned(7 downto 0);   
   signal img_color_idx_r  : unsigned(7 downto 0);
   signal img_color_idx_s  : unsigned(7 downto 0);
	
   -- Third stage --
   signal thrd_stg_data_s  : std_logic_vector(DATA_WIDTH-1 downto 0);
   signal stage_data_s     : std_logic_vector(DATA_WIDTH-1 downto 0);
   signal palette_idx_s    : unsigned(7 downto 0);
	
begin
   -----------------------------------------------------------------------------------
   --                            GLOBAL                                             --
   -----------------------------------------------------------------------------------		   
   process(clk_i, we_i, bus_data_i, local_addr_s) begin
      if rising_edge(clk_i) then
         if we_i = '1' and REGISTER_OFFSET <= local_addr_s and local_addr_s < REGISTER_OFFSET + REGISTER_NUMBER then
            registers_s(to_integer(local_addr_s - REGISTER_OFFSET)) <= unsigned(bus_data_i);
         end if;
      end if;
   end process;
	
   with stage_i select
      address_s <= 
         frst_stg_addr_s when "00",
         scnd_stg_addr_s when "01",
         thrd_stg_addr_s when "10",
         zero_stg_addr_s when others;

   local_addr_s <= signed(bus_addr_i) - C_BASEADDR;  	
	
   -----------------------------------------------------------------------------------
   --                           ZERO  STAGE                                         --
   -----------------------------------------------------------------------------------	
	
	rgb_o <= mem_data_s(23 downto 0);
	
	comp_gen: for i in 0 to REGISTER_NUMBER-1 generate
	
      -- Slice out data from registers --
		reg_row_s(i)    <= registers_s(i)(56 downto 48);
		reg_col_s(i)    <= registers_s(i)(41 downto 32);
		reg_size_s(i)   <= registers_s(i)(27 downto 24);
		reg_en_s(i)     <= registers_s(i)(31);
		reg_rot_s(i)    <= registers_s(i)(23 downto 16);
		reg_pointer_s(i)<= registers_s(i)(15 downto 0);
		
      -- Prepare some additional data, based on known values --
		reg_end_row_s(i) <= reg_row_s(i) + reg_size_s(i);
		reg_end_col_s(i) <= reg_col_s(i) + reg_size_s(i);
		
		reg_intsect_s(i) <= '1' when 
                          ( pixel_row_i >= reg_row_s(i)      and
                            pixel_row_i <=  reg_end_row_s(i)  and
                            pixel_col_i >= reg_col_s(i)      and
                            pixel_col_i <=  reg_end_col_s(i)
                          ) and reg_en_s(i) = '1'  
                          else
                          '0';	
	end generate comp_gen;

	reg_intersected_s <= "1001" when reg_intsect_s(9) = '1' else
                        "1000" when reg_intsect_s(8) = '1' else
                        "0111" when reg_intsect_s(7) = '1' else
                        "0110" when reg_intsect_s(6) = '1' else
                        "0101" when reg_intsect_s(5) = '1' else
                        "0100" when reg_intsect_s(4) = '1' else
                        "0011" when reg_intsect_s(3) = '1' else
                        "0010" when reg_intsect_s(2) = '1' else
                        "0001" when reg_intsect_s(1) = '1' else
                        "0000" when reg_intsect_s(0) = '1' else
                        "0000"; 
		
	glb_sprite_en_s <= reg_intsect_s(to_integer(reg_intersected_s));				

	map_index_s     <= pixel_row_i(8 downto 3) * 80 + pixel_col_i(9 downto 3);
	frst_stg_addr_s <= "0" & map_index_s + MAP_OFFSET;
	
	-----------------------------------------------------------------------------------
	--            	               FIRST STAGE             									--
	-----------------------------------------------------------------------------------   
   process(clk_i) begin
      if rising_edge(clk_i) then
         img_tex_pix_sel_r <= img_tex_offset_s(1 downto 0);
      end if;
	end process;
   
	img_row_s <= pixel_row_i(2 downto 0);
	img_col_s <= pixel_col_i(2 downto 0);
	
	img_z_coor_s <= unsigned(mem_data_s(31 downto 24));
	img_rot_s    <= unsigned(mem_data_s(23 downto 16));
	img_addr_s   <= unsigned(mem_data_s(ADDR_WIDTH-1 downto 0));
	
	with img_rot_s select
		img_tex_col_s <= 
			'0' & img_col_s        when "00000000",   -- 0
		   size_8_c - img_row_s   when "00000001",   -- 90
			size_8_c - img_col_s   when "00000010",   -- 180
			'0' & img_row_s		  when others; 		-- 270
	
	with img_rot_s select
		img_tex_row_s <= 
			'0' & img_row_s        when "00000000",   -- 0
			'0' & img_col_s        when "00000001",   -- 90
			size_8_c - img_row_s   when "00000010",	-- 180
			size_8_c - img_col_s   when others;       -- 270
	
	img_tex_offset_s <= img_tex_row_s(2 downto 0) & img_tex_col_s(2 downto 0);	
	
	scnd_stg_addr_s <= img_addr_s + img_tex_offset_s(5 downto 2);
	
	-----------------------------------------------------------------------------------
	--                           SECOND STAGE                                        --
	-----------------------------------------------------------------------------------	
	max_s      <= reg_size_s(to_integer(reg_intersected_s));
	rot_s      <= reg_rot_s(to_integer(reg_intersected_s));		
	
	sprt_int_row_s <= pixel_row_i - reg_row_s(to_integer(reg_intersected_s));
	sprt_int_col_s <= pixel_col_i - reg_col_s(to_integer(reg_intersected_s));
	
	sprt_row_s <= sprt_int_row_s(3 downto 0);
	sprt_col_s <= sprt_int_col_s(3 downto 0);
	
	s_col_s <= sprt_col_s         when rot_s = x"00" else -- 0
				  max_s - sprt_row_s when rot_s = x"01" else -- 90
				  max_s - sprt_col_s when rot_s = x"02" else -- 180
				  sprt_row_s;                                -- 270
				  
	s_row_s <= sprt_row_s         when rot_s = x"00" else  -- 0
				  sprt_col_s			when rot_s = x"01" else  -- 90
				  max_s - sprt_row_s when rot_s = x"02" else  -- 180
				  max_s - sprt_col_s;                         -- 270
				  
	sprt_tex_offset_s <= s_row_s & s_col_s;

	-- Get color index of static image.
	with img_tex_pix_sel_r select	
		img_color_idx_s <= 	
			unsigned(mem_data_s( 7 downto  0)) when "00",
			unsigned(mem_data_s(15 downto  8)) when "01",
			unsigned(mem_data_s(23 downto 16)) when "10",
			unsigned(mem_data_s(31 downto 24)) when others;

	process(clk_i) begin
		if rising_edge(clk_i) then
			img_color_idx_r <= img_color_idx_s;
		end if;
	end process;
   
   process(clk_i) begin
		if rising_edge(clk_i) then
			sprt_tex_offset_r <= sprt_tex_offset_s;
		end if;
	end process;
   
   	process (clk_i) begin
      if rising_edge(clk_i) then
         if (stage_i = "10") then
            img_z_coor_r <= img_z_coor_s;
         end if;
      end if;
   end process;
	
	thrd_stg_addr_s <= reg_pointer_s(to_integer(reg_intersected_s))(12 downto 0) + sprt_tex_offset_s(7 downto 2);

	-----------------------------------------------------------------------------------
	--                            THIRD STAGE                                        --
	-----------------------------------------------------------------------------------	
							
	-- Calclulate color index of sprite --
   with sprt_tex_offset_s(1 downto 0) select
      spr_color_idx_s <= 
         unsigned(mem_data_s( 7 downto  0)) when "00",
			unsigned(mem_data_s(15 downto  8)) when "01",
			unsigned(mem_data_s(23 downto 16)) when "10",
			unsigned(mem_data_s(31 downto 24)) when others;
         
	 palette_idx_s   <= 
--                       spr_color_idx_s when 
--                       (
--                        glb_sprite_en_s = '1' and
--                        (
--                           -- z sort --
--                           ( ( img_z_coor_r < SPRITE_Z ) and ( spr_color_idx_s > x"00" ) ) or
--                           -- alpha sort ( if static img index is transparent ) --
--                           ( ( img_z_coor_r > SPRITE_Z ) and ( img_color_idx_r = x"00" ) )
--                        )
--                      ) else 
                      img_color_idx_r; 
                      
	 zero_stg_addr_s <= (ADDR_WIDTH-1 downto 8 => '0') & palette_idx_s;
								
	-----------------------------------------------------------------------------------
	--                            COMMON                                --
	-----------------------------------------------------------------------------------
						
	ram_i : ram
	port map(
		clk_i		=> clk_i,
		addr_i	=> address_s,
		data_o	=> mem_data_s
	);		
	
end Behavioral;