library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.sub_module_components.all;

entity top_tmds is
port(
      i_sys_clk      : in  std_logic;
      i_usr_rst      : in  std_logic;

      i_tmds         : in  std_logic_vector(3 downto 0);
      i_tmdsb        : in  std_logic_vector(3 downto 0);

      o_tmds         : out std_logic_vector(3 downto 0);
      o_tmdsb        : out std_logic_vector(3 downto 0);

      o_err          : out std_logic
);
end top_tmds;



architecture rtl of top_tmds is

signal rx_lock            : std_logic;
signal hsync_rx           : std_logic;
signal vsync_rx           : std_logic;
signal de_rx              : std_logic;
signal blue_vld_rx        : std_logic;
signal green_vld_rx       : std_logic;
signal red_vld_rx         : std_logic;
signal blue_rdy_rx        : std_logic;
signal green_rdy_rx       : std_logic;
signal red_rdy_rx         : std_logic;
signal psalgnerr_rx       : std_logic;
signal pclk_rx            : std_logic;
signal red_rx             : std_logic_vector(7 downto 0);
signal green_rx           : std_logic_vector(7 downto 0);
signal blue_rx            : std_logic_vector(7 downto 0);


signal blue_tx      : std_logic_vector(7 downto 0);
signal red_tx       : std_logic_vector(7 downto 0);
signal green_tx     : std_logic_vector(7 downto 0);
signal pclk_tx      : std_logic;
signal rst_tx       : std_logic;
signal hsync_tx     : std_logic;
signal vsync_tx     : std_logic;
signal de_tx        : std_logic;
signal rst_checker  : std_logic;



begin


i_dvi_decoder: dvi_decoder 
port map(

      tmdsclk_p          => i_tmds(0),   -- : in  std_logic;
      tmdsclk_n          => i_tmdsb(1),  -- : in  std_logic;
      
      blue_p             => i_tmds(1),   -- : in  std_logic;
      green_p            => i_tmds(2),   -- : in  std_logic;
      red_p              => i_tmds(3),   -- : in  std_logic;

      blue_n             => i_tmdsb(1),  -- : in  std_logic;
      green_n            => i_tmdsb(2),  -- : in  std_logic;
      red_n              => i_tmdsb(3),  -- : in  std_logic;

      exrst              => i_usr_rst,   -- : in  std_logic;
 
      pll_lckd_o         => rx_lock,   -- : out std_logic;
    
      hsync              => hsync_rx,   -- : out std_logic;
      vsync              => vsync_rx,   -- : out std_logic;
      de                 => de_rx,      -- : out std_logic;

      blue_vld_o         => blue_vld_rx,   -- : out std_logic;
      green_vld_o        => green_vld_rx,  -- : out std_logic;
      red_vld_o          => red_vld_rx,    -- : out std_logic;
      
      blue_rdy_o         => blue_rdy_rx,   -- : out std_logic;
      green_rdy_o        => green_rdy_rx,  -- : out std_logic;
      red_rdy_o          => red_rdy_rx,    -- : out std_logic;

      psalgnerr          => psalgnerr_rx,   -- : out std_logic;
  
      sdout              => open,       -- : out std_logic_vector(29 downto 0);
      pixclk             => pclk_rx,    -- : out std_logic;
      red                => red_rx,     -- : out std_logic_vector( 7 downto 0);
      green              => green_rx,   -- : out std_logic_vector( 7 downto 0);
      blue               => blue_rx     -- : out std_logic_vector( 7 downto 0)
);

rst_checker <= not rx_lock;

i_checker: checker
port map(
    i_clk         => pclk_rx,      -- : in  std_logic;
    i_rst         => rst_checker,  -- : in  std_logic;
    
    i_blue        => blue_rx,  -- : in  std_logic_vector(7 downto 0);
    i_red         => red_rx,   -- : in  std_logic_vector(7 downto 0);
    i_green       => green_rx, -- : in  std_logic_vector(7 downto 0);

    i_hsync       => hsync_rx, -- : in  std_logic;
    i_vsync       => vsync_rx, -- : in  std_logic;
    i_de          => de_rx,    -- : in  std_logic;

    i_blue_vld    => blue_vld_rx,  -- : in  std_logic;
    i_green_vld   => green_vld_rx, -- : in  std_logic;
    i_red_vld     => red_vld_rx,   -- : in  std_logic;
    
    i_blue_rdy    => blue_rdy_rx,  -- : in  std_logic;
    i_green_rdy   => green_rdy_rx, -- : in  std_logic;
    i_red_rdy     => red_rdy_rx,   -- : in  std_logic;

    i_psalgnerr   => psalgnerr_rx, -- : in  std_logic;

    o_err         => o_err          -- : out std_logic
);


 


i_dvi_encoder_top: dvi_encoder_top
port map(

      pclk           => pclk_tx,  -- : in  std_logic;                        -- pixel clock

      i_rst          => rst_tx,   -- : in  std_logic;                        -- reset
      blue_din       => blue_tx,  -- : in  std_logic_vector(7 downto 0);     -- Blue data in
      green_din      => red_tx,   -- : in  std_logic_vector(7 downto 0);     -- Green data in
      red_din        => green_tx, -- : in  std_logic_vector(7 downto 0);     -- Red data in
      hsync          => hsync_tx, -- : in  std_logic;                        -- hsync data
      vsync          => vsync_tx, -- : in  std_logic;                        -- vsync data
      de             => de_tx,    -- : in  std_logic;                        -- data enable

      tmds           => o_tmds,   -- : out std_logic_vector(3 downto 0);                                                       
      tmdsb          => o_tmdsb   -- : out std_logic_vector(3 downto 0)                                                             
);

i_pattern_gen :  pattern_gen
port map(
      i_clk          => i_sys_clk,   -- : in  std_logic;  -- should be 100Mhz with the current settings
      i_rst          => i_usr_rst,   -- : in  std_logic;  -- async user reset

       
      o_blue         => blue_tx,    -- : out std_logic_vector(7 downto 0);
      o_red          => red_tx,     -- : out std_logic_vector(7 downto 0);
      o_green        => green_tx,   -- : out std_logic_vector(7 downto 0);

      o_pclk         => pclk_tx,    -- : out std_logic;
      o_rst          => rst_tx,     -- : out std_logic;

      o_hsync        => hsync_tx,   -- : out std_logic;
      o_vsync        => vsync_tx,   -- : out std_logic;
      o_de           => de_tx       -- : out std_logic
);



end rtl;
