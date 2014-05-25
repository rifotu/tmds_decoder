library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sub_module_components.all;

library unisim;
use unisim.vcomponents.all;

entity dvi_decoder is 
port(
      tmdsclk_p          : in  std_logic;
      tmdsclk_n          : in  std_logic;
      
      blue_p             : in  std_logic;
      green_p            : in  std_logic;
      red_p              : in  std_logic;

      blue_n             : in  std_logic;
      green_n            : in  std_logic;
      red_n              : in  std_logic;

      exrst              : in  std_logic;
 
      rst                : out std_logic;
      --pclk_o             : out std_logic;
      --pclkx2_o           : out std_logic;
      --pclkx10_o          : out std_logic;
      
      --pllclk0_o          : out std_logic; 
      --pllclk1_o          : out std_logic;
      --pllclk2_o          : out std_logic;

      pll_lckd_o         : out std_logic;
      --serdesstrobe_o     : out std_logic;
      tmdsclk            : out std_logic;
    
      hsync              : out std_logic;
      vsync              : out std_logic;
      de                 : out std_logic;

      blue_vld_o           : out std_logic;
      green_vld_o          : out std_logic;
      red_vld_o            : out std_logic;
      
      blue_rdy_o           : out std_logic;
      green_rdy_o          : out std_logic;
      red_rdy_o            : out std_logic;

      psalgnerr          : out std_logic;
  
      sdout              : out std_logic_vector(29 downto 0);
      red                : out std_logic_vector( 7 downto 0);
      green              : out std_logic_vector( 7 downto 0);
      blue               : out std_logic_vector( 7 downto 0)
);
end dvi_decoder;


architecture rtl of dvi_decoder is



signal sdout_blue           : std_logic_vector( 9 downto 0);
signal sdout_green          : std_logic_vector( 9 downto 0);
signal sdout_red            : std_logic_vector( 9 downto 0);

signal de_b                 : std_logic;
signal de_g                 : std_logic;
signal de_r                 : std_logic;

signal blue_psalgnerr       : std_logic;
signal green_psalgnerr      : std_logic;
signal red_psalgnerr        : std_logic;

signal rxclkint             : std_logic;
signal rxclk                : std_logic;
signal bufpll_lock          : std_logic;
signal pllclk0              : std_logic;
signal pll_lckd             : std_logic := '0';
signal pclkx2               : std_logic;
signal reset                : std_logic := '0';
signal pclk                 : std_logic; 
signal pclkx10              : std_logic;
signal serdesstrobe         : std_logic;
signal green_rdy            : std_logic := '0';
signal red_rdy              : std_logic := '0';
signal green_vld            : std_logic := '0';
signal red_vld              : std_logic := '0';
signal blue_rdy             : std_logic := '0';
signal blue_vld             : std_logic := '0';

signal pllclk1              : std_logic;
signal pllclk2              : std_logic;


signal clkfbout           : std_logic := '0';

begin

green_vld_o <= green_vld;
red_rdy_o   <= red_rdy;
green_rdy_o <= green_rdy;

red_vld_o   <= red_vld;
blue_rdy_o  <= blue_rdy;
blue_vld_o  <= blue_vld;

pllclk1_o   <= pllclk1;
pllclk2_o   <= pllclk2;

sdout  <= sdout_red(9 downto 5) & sdout_green(9 downto 5) & sdout_blue(9 downto 5) &
          sdout_red(4 downto 0) & sdout_green(4 downto 0) & sdout_blue(4 downto 0);


de <= de_b;


-- Send TMDS clock to a differential buffer and then a BUFIO2
-- This is a required path in Spartan-6 feed a PLL CLKIN


i_ibufds_tmds: IBUFDS
generic map(
    IOSTANDARD   => "TMDS_33",
    DIFF_TERM    => FALSE
)
port map(
    I            => tmdsclk_p,
    IB           => tmdsclk_n,
    O            => rxclkint
);

i_bufio2_rxclk: BUFIO2
generic map(
    DIVIDE_BYPASS => TRUE,
    DIVIDE        => 1
)
port map(
    I             => rxclkint,
    IOCLK         => open,
    DIVCLK        => rxclk,
    SERDESSTROBE  => open
);

i_bufg_tmdsclk: BUFG
port map(
    I       => rxclk,
    O       => tmdsclk
);

--PLL is used to generate three clocks:
--1. pclk:    same rate as TMDS clock
--2. pclkx2:  double rate of pclk used for 5:10 soft gear box and ISERDES DIVCLK
--3. pclkx10: 10x rate of pclk used as IO clock
i_pll_base: PLL_BASE
generic map(
    CLKIN_PERIOD    => 10.0,
    CLKFBOUT_MULT   => 10,
    CLKOUT0_DIVIDE  =>  1,
    CLKOUT1_DIVIDE  => 10,
    CLKOUT2_DIVIDE  =>  5,
    COMPENSATION    => "INTERNAL"
)
port map(
    CLKFBOUT        => clkfbout,
    CLKOUT0         => pllclk0,
    CLKOUT1         => pllclk1,
    CLKOUT2         => pllclk2, 
    CLKOUT3         => open,
    CLKOUT4         => open,
    CLKOUT5         => open,
    LOCKED          => pll_lckd,   -- output
    CLKFBIN         => clkfbout,
    CLKIN           => rxclk,
    RST             => exrst
);

pllclk0_o  <= pllclk0;


i_bufg_pclkbufg: BUFG
port map(
    I       => pllclk1,
    O       => pclk
);

pclk_o  <= pclk;

i_bufg_pclkx2bufg: BUFG
port map(
    I       => pllclk2,
    O       => pclkx2
);

pclkx2_o <= pclkx2;
pll_lckd_o <= pll_lckd;

i_bufpll_ioclk: BUFPLL
generic map(
      DIVIDE			=> 5
)
port map (
      PLLIN			=> pllclk0,        	
      GCLK			=> pclkx2, 		
      LOCKED			=> pll_lckd,   -- input            	
      IOCLK			=> pclkx10, 		
      LOCK			=> bufpll_lock,         	
      serdesstrobe		=> serdesstrobe
); 	

reset <= not bufpll_lock;

pclkx10_o <= pclkx10;
serdesstrobe_o <= serdesstrobe;

i_decode_decB: decode
port map(
    reset          => reset,
    pclk           => pclk,
    pclkx2         => pclkx2,  
    pclkx10        => pclkx10, 
    serdesstrobe   => serdesstrobe, 
    din_p          => blue_p, 
    din_n          => blue_n, 
    other_ch0_rdy  => green_rdy, 
    other_ch1_rdy  => red_rdy, 
    other_ch0_vld  => green_vld, 
    other_ch1_vld  => red_vld, 
    iamvld_out     => blue_vld, 
    iamrdy         => blue_rdy, 
    psalgnerr      => blue_psalgnerr, 
    c0             => hsync, 
    c1             => vsync, 
    de             => de_b, 
    sdout          => sdout_blue, 
    dout           => blue 
);
                      
i_decode_decG: decode
port map(
    reset          => reset,
    pclk           => pclk,
    pclkx2         => pclkx2,  
    pclkx10        => pclkx10, 
    serdesstrobe   => serdesstrobe, 
    din_p          => green_p, 
    din_n          => green_n, 
    other_ch0_rdy  => blue_rdy, 
    other_ch1_rdy  => red_rdy, 
    other_ch0_vld  => blue_vld, 
    other_ch1_vld  => red_vld, 
    iamvld_out     => green_vld, 
    iamrdy         => green_rdy, 
    psalgnerr      => green_psalgnerr, 
    c0             => open, 
    c1             => open, 
    de             => de_g, 
    sdout          => sdout_green, 
    dout           => green 
);
                      

i_decode_decR: decode
port map(
    reset          => reset,
    pclk           => pclk,
    pclkx2         => pclkx2,  
    pclkx10        => pclkx10, 
    serdesstrobe   => serdesstrobe, 
    din_p          => red_p, 
    din_n          => red_n, 
    other_ch0_rdy  => blue_rdy, 
    other_ch1_rdy  => green_rdy, 
    other_ch0_vld  => blue_vld, 
    other_ch1_vld  => green_vld, 
    iamvld_out     => red_vld, 
    iamrdy         => red_rdy, 
    psalgnerr      => red_psalgnerr, 
    c0             => open, 
    c1             => open, 
    de             => de_r, 
    sdout          => sdout_red, 
    dout           => red 
);
                      

psalgnerr <= red_psalgnerr or blue_psalgnerr or green_psalgnerr;

end rtl;
