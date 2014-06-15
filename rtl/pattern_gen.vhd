library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.sub_module_components.all;

entity pattern_gen is
port(
      i_clk         : in  std_logic;  -- should be 100Mhz with the current settings
      i_rst         : in  std_logic;  -- async user reset

       
      o_blue        : out std_logic_vector(7 downto 0);
      o_red         : out std_logic_vector(7 downto 0);
      o_green       : out std_logic_vector(7 downto 0);

      o_pclk        : out std_logic;
      o_rst         : out std_logic;

      o_hsync       : out std_logic;
      o_vsync       : out std_logic;
      o_de          : out std_logic

);
end pattern_gen;


architecture rtl of pattern_gen is

--1280x720@60HZ
constant HPIXELS_HDTV720P  : integer := 1280; -- 11'd1280; //Horizontal Live Pixels
constant VLINES_HDTV720P   : integer :=  720; -- 11'd720;  //Vertical Live ines
constant HSYNCPW_HDTV720P  : integer :=   80; -- 11'd80;   //HSYNC Pulse Width
constant VSYNCPW_HDTV720P  : integer :=    5; -- 11'd5;    //VSYNC Pulse Width
constant HFNPRCH_HDTV720P  : integer :=   72; -- 11'd72;   //Horizontal Front Portch
constant VFNPRCH_HDTV720P  : integer :=    3; -- 11'd3;    //Vertical Front Portch
constant HBKPRCH_HDTV720P  : integer :=  216; -- 11'd216;  //Horizontal Front Portch
constant VBKPRCH_HDTV720P  : integer :=   22; -- 11'd22;   //Vertical Front Portch

constant TC_HSBLNK_HD : integer := HPIXELS_HDTV720P - 1;
constant TC_HSSYNC_HD : integer := HPIXELS_HDTV720P - 1 + HFNPRCH_HDTV720P;
constant TC_HESYNC_HD : integer := HPIXELS_HDTV720P - 1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P;
constant TC_HEBLNK_HD : integer := HPIXELS_HDTV720P - 1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P + HBKPRCH_HDTV720P;    
constant TC_VSBLNK_HD : integer := VLINES_HDTV720P  - 1;       
constant TC_VSSYNC_HD : integer := VLINES_HDTV720P  - 1 + VFNPRCH_HDTV720P;     
constant TC_VESYNC_HD : integer := VLINES_HDTV720P  - 1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P;      
constant TC_VEBLNK_HD : integer := VLINES_HDTV720P  - 1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P + VBKPRCH_HDTV720P;      
                                          
constant HVSYNC_POLARITY_HD : std_logic := '0';
                                          
signal   sysclk_ibuf  : std_logic;
signal   clk50m       : std_logic;
signal   clk50m_bufg  : std_logic; 

signal clkfx_pclk     : std_logic;
signal pclk_lckd      : std_logic;
signal pclk           : std_logic;
signal tc_hsblnk      : std_logic_vector(10 downto 0);
signal tc_hssync      : std_logic_vector(10 downto 0);
signal tc_hesync      : std_logic_vector(10 downto 0);
signal tc_heblnk      : std_logic_vector(10 downto 0);
signal tc_vsblnk      : std_logic_vector(10 downto 0);
signal tc_vssync      : std_logic_vector(10 downto 0);
signal tc_vesync      : std_logic_vector(10 downto 0);
signal tc_veblnk      : std_logic_vector(10 downto 0);

signal bgnd_hcount    : std_logic_vector(10 downto 0);
signal bgnd_hblnk     : std_logic;
signal bgnd_vcount    : std_logic_vector(10 downto 0);
signal bgnd_vblnk     : std_logic;

signal active       : std_logic;
signal hsync        : std_logic;
signal vsync        : std_logic;
signal hsync_pre    : std_logic;
signal vsync_pre    : std_logic;
signal de           : std_logic;
signal pix_frm_lfsr : std_logic_vector(15 downto 0);
signal rst_lfsr    : std_logic;

begin


i_buf_sysclk : IBUF
port map(
  I  => i_clk,
  O  => sysclk_ibuf
);

-- Note that in the original design
-- a 100Mhz clock was supplied and divide
-- bypass was set to FALSE. However as of
-- ISE 14.6 this is not supported. See 
-- Answer record 56113,
-- As a workaround supply a clock of 50Mhz
i_bufio2_sysclk : BUFIO2
generic map(
  DIVIDE_BYPASS     => TRUE,
  DIVIDE            => 4
) 
port map(
  I                 => sysclk_ibuf,
  SERDESSTROBE      => open,
  IOCLK             => open,
  DIVCLK            => clk50m
);

-- this may be used in case 50M clock is needed
-- well for now it's not though
i_clk50m_bufg: BUFG
port map(
  I    => clk50m,
  O    => clk50m_bufg
);


-- default mode is HD 720P
-- clock frequency should be 74.25Mhz but
-- the values actually give 74Mhz
-- Note that initial values are used
-- clkfx and no reprogramming is done
DCM_CLKGEN_inst : DCM_CLKGEN
generic map (
   CLKFXDV_DIVIDE =>  2,       -- CLKFXDV divide value (2, 4, 8, 16, 32)
   CLKFX_DIVIDE  =>  25,       -- Divide value - D - (1-256)
   CLKFX_MD_MAX =>  2.0,       -- Specify maximum M/D ratio for timing anlysis
   CLKFX_MULTIPLY => 37,       -- Multiply value - M - (2-256)
   CLKIN_PERIOD => 20.0,       -- Input clock period specified in nS
   SPREAD_SPECTRUM => "NONE", -- Spread Spectrum mode "NONE", "CENTER_LOW_SPREAD", "CENTER_HIGH_SPREAD",
                              -- "VIDEO_LINK_M0", "VIDEO_LINK_M1" or "VIDEO_LINK_M2" 
   STARTUP_WAIT => FALSE      -- Delay config DONE until DCM_CLKGEN LOCKED (TRUE/FALSE)
)
port map (
   CLKFX => clkfx_pclk,   -- 1-bit output: Generated clock output
   CLKFX180 => open,      -- 1-bit output: Generated clock output 180 degree out of phase from CLKFX.
   CLKFXDV => open,       -- 1-bit output: Divided clock output
   LOCKED => pclk_lckd,   -- 1-bit output: Locked output
   PROGDONE => open,    -- 1-bit output: Active high output to indicate the successful re-programming
   STATUS => open,      -- 2-bit output: DCM_CLKGEN status
   CLKIN => clk50m,     -- 1-bit input: Input clock
   FREEZEDCM => '1',    -- 1-bit input: Prevents frequency adjustments to input clock
   PROGCLK => '0',      -- 1-bit input: Clock input for M/D reconfiguration
   PROGDATA => '0',     -- 1-bit input: Serial data input for M/D reconfiguration
   PROGEN => '0',       -- 1-bit input: Active high program enable
   RST => i_rst           -- 1-bit input: Reset input pin
);

-- UG382 pg 112 says that
--" When theoutput of the DCM is used to drive the PLL directly, both DCM and PLL must reside within
--the same CMT block. This is the preferred implementation since it produces a minimal
--amount of noise on the local, dedicated route. However, a connection can also be made by
--connecting the DCM to a BUFG and then to the CLKIN input of a PLL"

-- contrary to the original design, DCM output is not connected directly to PLL but to a BUFG
-- the only thing gained here is that the code can be written in a more structured way
i_pclk_bufg : BUFG
port map(
  I  => clkfx_pclk,
  O  => pclk
);

tc_hsblnk   <= conv_std_logic_vector(TC_HSBLNK_HD, 11); 
tc_hssync   <= conv_std_logic_vector(TC_HSSYNC_HD, 11); 
tc_hesync   <= conv_std_logic_vector(TC_HESYNC_HD, 11); 
tc_heblnk   <= conv_std_logic_vector(TC_HEBLNK_HD, 11); 
tc_vsblnk   <= conv_std_logic_vector(TC_VSBLNK_HD, 11); 
tc_vssync   <= conv_std_logic_vector(TC_VSSYNC_HD, 11); 
tc_vesync   <= conv_std_logic_vector(TC_VESYNC_HD, 11); 
tc_veblnk   <= conv_std_logic_vector(TC_VEBLNK_HD, 11); 


i_timing : timing
port map(
   tc_hsblnk    => tc_hsblnk, --      : in  std_logic_vector(10 downto 0);
   tc_hssync    => tc_hssync, --      : in  std_logic_vector(10 downto 0);
   tc_hesync    => tc_hesync, --      : in  std_logic_vector(10 downto 0);
   tc_heblnk    => tc_heblnk, --      : in  std_logic_vector(10 downto 0);
               
   hcount       => bgnd_hcount, --      : out std_logic_vector(10 downto 0);
   hsync        => hsync_pre, --       : out std_logic;
   hblnk        => bgnd_hblnk, --       : out std_logic;
   
   tc_vsblnk    => tc_vsblnk, --      : in  std_logic_vector(10 downto 0);
   tc_vssync    => tc_vssync, --      : in  std_logic_vector(10 downto 0);
   tc_vesync    => tc_vesync, --      : in  std_logic_vector(10 downto 0);
   tc_veblnk    => tc_veblnk, --      : in  std_logic_vector(10 downto 0);
                                                           
   vcount       => bgnd_vcount, --      : out std_logic_vector(10 downto 0);
   vsync        => vsync_pre, --       : out std_logic;
   vblnk        => bgnd_vblnk, --       : out std_logic;
   
   restart      => pclk_lckd, --      : in  std_logic;
   clk          => pclk       --      : in  std_logic
);

-------------------------------
-- V/H SYNC and DE generator --
-------------------------------

active  <= '1' when ( (not(bgnd_hblnk) = '1') and (not(bgnd_vblnk) = '1') ) else
           '0';

process(pclk)
begin
  if(rising_edge(pclk)) then
    hsync <= hsync_pre xor HVSYNC_POLARITY_HD;
    vsync <= vsync_pre xor HVSYNC_POLARITY_HD;

    o_hsync <= hsync;
    o_vsync <= vsync;
  end if;
end process;


process(pclk)
begin
  if(rising_edge(pclk)) then
    de   <= active;
    o_de <= de;
  end if;
end process;

rst_lfsr <= not pclk_lckd;

-- Random data is generated with 1CC delay
-- with respect to i_de
i_pix_lfsr: lfsr
generic map(
         seed => 293
)
port map(
         i_rst    => rst_lfsr,
         i_clk    => pclk,

         i_vsync  => vsync,
         i_hsync  => hsync,
         i_de     => de,
         o_pix    => pix_frm_lfsr
);

o_blue  <= pix_frm_lfsr( 7 downto 0);
o_red   <= pix_frm_lfsr(15 downto 8);
o_green <= pix_frm_lfsr(12 downto 5);

o_rst   <= pclk_lckd;
o_pclk  <= pclk;


end rtl;
