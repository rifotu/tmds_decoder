library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity top_tmds is
port(
      sys_clk      : in  std_logic;
      rst          : in  std_logic;

      tmds_in      : in  std_logic_vector(3 downto 0);
      tmds_inb     : in  std_logic_vector(3 downto 0);

      tmds         : out std_logic_vector(3 downto 0);
      tmdsb        : out std_logic_vector(3 downto 0);

);
end top_tmds;



architecture rtl of top_tmds is





begin


i_dvi_encoder: dvi_decoder 
port map(

      tmdsclk_p          => ,   -- : in  std_logic;
      tmdsclk_n          => ,   -- : in  std_logic;
      
      blue_p             => ,   -- : in  std_logic;
      green_p            => ,   -- : in  std_logic;
      red_p              => ,   -- : in  std_logic;

      blue_n             => ,   -- : in  std_logic;
      green_n            => ,   -- : in  std_logic;
      red_n              => ,   -- : in  std_logic;

      exrst              => ,   -- : in  std_logic;
 
      rst                => ,   -- : out std_logic;
    --pclk_o             => ,   -- : out std_logic;
    --pclkx2_o           => ,   -- : out std_logic;
    --pclkx10_o          => ,   -- : out std_logic;
      
    --pllclk0_o          => ,   -- : out std_logic; 
    --pllclk1_o          => ,   -- : out std_logic;
    --pllclk2_o          => ,   -- : out std_logic;

      pll_lckd_o         => ,   -- : out std_logic;
    --serdesstrobe_o     => ,   -- : out std_logic;
    --tmdsclk            => ,   -- : out std_logic;
    
      hsync              => ,   -- : out std_logic;
      vsync              => ,   -- : out std_logic;
      de                 => ,   -- : out std_logic;

      blue_vld_o         => ,   -- : out std_logic;
      green_vld_o        => ,   -- : out std_logic;
      red_vld_o          => ,   -- : out std_logic;
      
      blue_rdy_o         => ,   -- : out std_logic;
      green_rdy_o        => ,   -- : out std_logic;
      red_rdy_o          => ,   -- : out std_logic;

      psalgnerr          => ,   -- : out std_logic;
  
      sdout              => ,   -- : out std_logic_vector(29 downto 0);
      pixclk             => ,   -- : out std_logic;
      red                => ,   -- : out std_logic_vector( 7 downto 0);
      green              => ,   -- : out std_logic_vector( 7 downto 0);
      blue               =>     -- : out std_logic_vector( 7 downto 0)
);


i_dvi_encoder_top: dvi_encoder_top
port map(

      pclk           : in  std_logic;                        -- pixel clock
--    pclkx2         : in  std_logic;                        -- pixel clock x2
--    pclkx10        : in  std_logic;
--    serdesstrobe   : in  std_logic;                        -- oserdes2 serdesstrobe
      rstin          : in  std_logic;                        -- reset
      blue_din       : in  std_logic_vector(7 downto 0);     -- Blue data in
      green_din      : in  std_logic_vector(7 downto 0);     -- Green data in
      red_din        : in  std_logic_vector(7 downto 0);     -- Red data in
      hsync          : in  std_logic;                        -- hsync data
      vsync          : in  std_logic;                        -- vsync data
      de             : in  std_logic;                        -- data enable

      tmds           : out std_logic_vector(3 downto 0);                                                       
      tmdsb          : out std_logic_vector(3 downto 0)                                                             
);





end rtl;
