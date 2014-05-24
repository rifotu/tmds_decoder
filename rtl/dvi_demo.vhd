library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity dvi_demo is
port(

      rstbtn_n             : in  std_logic;
      clk100               : in  std_logic;
      rx0_tmds             : in  std_logic_vector(3 downto 0);
      rx0_tmdsb            : in  std_logic_vector(3 downto 0);
      rx1_tmds             : in  std_logic_vector(3 downto 0);
      rx1_tmdsb            : in  std_logic_vector(3 downto 0);

      tx0_tmds             : out  std_logic_vector(3 downto 0);
      tx0_tmdsb            : out  std_logic_vector(3 downto 0);
      tx1_tmds             : out  std_logic_vector(3 downto 0);
      tx1_tmdsb            : out  std_logic_vector(3 downto 0);

      sw                   : in   std_logic_vector(1 downto 0);
      led                  : out  std_logic_vector(7 downto 0)
);
end dvi_demo;


architecture rtl of dvi_demo is


signal clk25               : std_logic := '0';
signal clk25m              : std_logic := '0';
signal sws                 : std_logic_vector(1 downto 0) := "00";
signal select              : std_logic_vector(1 downto 0) := "00";
signal select_q            : std_logic_vector(1 downto 0) := "00";
signal switch              : std_logic_vector(1 downto 0) := "00";


-- Input Port 0
signal rx0_pclk            : std_logic := '0';
signal rx0_pclkx2          : std_logic := '0';
signal rx0_pclkx10         : std_logic := '0';
signal rx0_pllclk0         : std_logic := '0';
signal rx0_plllckd         : std_logic := '0';
signal rx0_reset           : std_logic := '0';

signal rx0_serdesstrobe    : std_logic := '0';
signal rx0_hsync           : std_logic := '0';    -- hsync data
signal rx0_vsync           : std_logic := '0';    -- vsync data
signal rx0_de              : std_logic := '0';    -- data enable
signal rx0_psalgnerr       : std_logic := '0';    -- channel phase alignment error

signal rx0_red             : std_logic_vector( 7 downto 0) := (others => '0');  -- pixel data out
signal rx0_green           : std_logic_vector( 7 downto 0) := (others => '0');  -- pixel data out
signal rx0_blue            : std_logic_vector( 7 downto 0) := (others => '0');  -- pixel data out
signal rx0_sdata           : std_logic_vector(29 downto 0) := (others => '0');
signal rx0_blue_vld        : std_logic := '0';
signal rx0_green_vld       : std_logic := '0';
signal rx0_red_vld         : std_logic := '0';
signal rx0_blue_rdy        : std_logic := '0';
signal rx0_green_rdy       : std_logic := '0';
signal rx0_red_rdy         : std_logic := '0';


signal rx1_serdesstrobe    : std_logic := '0';
signal rx1_hsync           : std_logic := '0';    -- hsync data
signal rx1_vsync           : std_logic := '0';    -- vsync data
signal rx1_de              : std_logic := '0';    -- data enable
signal rx1_psalgnerr       : std_logic := '0';    -- channel phase alignment error

signal rx1_red             : std_logic_vector( 7 downto 0) := (others => '0');  -- pixel data out
signal rx1_green           : std_logic_vector( 7 downto 0) := (others => '0');  -- pixel data out
signal rx1_blue            : std_logic_vector( 7 downto 0) := (others => '0');  -- pixel data out
signal rx1_sdata           : std_logic_vector(29 downto 0) := (others => '0');
signal rx1_blue_vld        : std_logic := '0';
signal rx1_green_vld       : std_logic := '0';
signal rx1_red_vld         : std_logic := '0';
signal rx1_blue_rdy        : std_logic := '0';
signal rx1_green_rdy       : std_logic := '0';
signal rx1_red_rdy         : std_logic := '0';

-- ifdef DIRECTPASS RELATED
signal rstin          : std_logic := '0';      
signal pclk           : std_logic := '0';
signal pclkx2         : std_logic := '0';
signal pclkx10        : std_logic := '0';
signal serdestrobe    : std_logic := '0';
signal s_data         : std_logic_vector(29 downto 0) := (others => '0');

signal tmdsclkint     : std_logic_vector( 4 downto 0) := (others => '0');
signal toggle         : std_logic := '0';
signal tmdsclk        : std_logic := '0';

signal tmds_data0     : std_logic_vector( 4 downto 0) := (others => '0');
signal tmds_data1     : std_logic_vector( 4 downto 0) := (others => '0');
signal tmds_data2     : std_logic_vector( 4 downto 0) := (others => '0');
signal tmdsint        : std_logic_vector( 2 downto 0) := (others => '0');
-- End of ifdef DIRECTPASS RELATED  ( see dvi_demo.v of XAPP495)

begin


i_bufio2_sysclk_div: BUFIO2
generic map(
    DIVIDE_BYPASS => FALSE,
    DIVIDE        => 5
)
port map(
    I             => clk100,
    IOCLK         => open,
    DIVCLK        => clk25m,
    SERDESSTROBE  => open
);

i_bufg_clk25_buf: BUFG
port map(
         I => clk25m,
         O => clk25
);

i_synchro_sws_0: synchro
generic map(
    INITIALIZE   => LOGIC0
)
port map(
    async        => sw(0),
    sync         => sws(0),
    clk          => clk25
);


i_synchro_sws_1: synchro
generic map(
    INITIALIZE   => LOGIC0
)
port map(
    async        => sw(1),
    sync         => sws(1),
    clk          => clk25
);

select  <= sws;

process(clk25)
begin
  if(rising_edge(clk25)) then
    select_q  <= select;
    
    switch(0) <= select(0) xor select_q(0);
    switch(1) <= select(1) xor select_q(1);
  end if;
end process;

i_dvi_decoder_rx0: dvi_decoder
port map(
      tmdsclk_p       => rx0_tmds(3),       -- : in  std_logic;
      tmdsclk_n       => rx0_tmdsb(3),       -- : in  std_logic;
      
      blue_p          => rx0_tmds(0),       -- : in  std_logic;
      green_p         => rx0_tmds(1),       -- : in  std_logic;
      red_p           => rx0_tmds(2),       -- : in  std_logic;

      blue_n          => rx0_tmdsb(0),       -- : in  std_logic;
      green_n         => rx0_tmdsb(1),       -- : in  std_logic;
      red_n           => rx0_tmdsb(2),       -- : in  std_logic;

      exrst           => not(rstbtn_n),      -- : in  std_logic;
 
      rst             => rx0_reset,         -- : out std_logic;
      pclk            => rx0_pclk,          -- : out std_logic;
      pclkx2          => rx0_pclkx2,        -- : out std_logic;
      pclkx10         => rx0_pclkx10,       -- : out std_logic;
      
      pllclk0         => rx0_pllclk0,       -- : out std_logic; 
      pllclk1         => rx0_pllclk1,       -- : out std_logic;
      pllclk2         => rx0_pllclk2,       -- : out std_logic;

      pll_lckd        => rx0_plllckd,            -- : out std_logic;
      serdesstrobe    => rx0_tmdsclk,            -- : out std_logic;
      tmdsclk         => rx0_serdesstrobe,       -- : out std_logic;
    
      hsync           => rx0_hsync,       -- : out std_logic;
      vsync           => rx0_vsync,       -- : out std_logic;
      de              => rx0_de,          -- : out std_logic;

      blue_vld        => rx0_blue_vld,        -- : out std_logic;
      green_vld       => rx0_green_vld,       -- : out std_logic;
      red_vld         => rx0_red_vld,         -- : out std_logic;
                         
      blue_rdy        => rx0_blue_rdy,        -- : out std_logic;
      green_rdy       => rx0_green_rdy,       -- : out std_logic;
      red_rdy         => rx0_red_rdy,         -- : out std_logic;

      psalgnerr       => rx0_psalgnerr,       -- : out std_logic;
  
      sdout           => rx0_sdata,       -- : out std_logic_vector(29 downto 0);
      red             => rx0_red,         -- : out std_logic_vector( 7 downto 0);
      green           => rx0_green,       -- : out std_logic_vector( 7 downto 0);
      blue            => rx0_blue         -- : out std_logic_vector( 7 downto 0);
);


i_dvi_decoder_rx1: dvi_decoder
port map(
      tmdsclk_p       => rx1_tmds(3),       -- : in  std_logic;
      tmdsclk_n       => rx1_tmdsb(3),       -- : in  std_logic;
      
      blue_p          => rx1_tmds(0),       -- : in  std_logic;
      green_p         => rx1_tmds(1),       -- : in  std_logic;
      red_p           => rx1_tmds(2),       -- : in  std_logic;

      blue_n          => rx1_tmdsb(0),       -- : in  std_logic;
      green_n         => rx1_tmdsb(1),       -- : in  std_logic;
      red_n           => rx1_tmdsb(2),       -- : in  std_logic;

      exrst           => not(rstbtn_n),      -- : in  std_logic;
 
      --These are output ports
      rst             => rx1_reset,         -- : out std_logic;
      pclk            => rx1_pclk,          -- : out std_logic;
      pclkx2          => rx1_pclkx2,        -- : out std_logic;
      pclkx10         => rx1_pclkx10,       -- : out std_logic;
      
      pllclk0         => rx1_pllclk0,       -- : out std_logic; 
      pllclk1         => rx1_pllclk1,       -- : out std_logic;
      pllclk2         => rx1_pllclk2,       -- : out std_logic;

      pll_lckd        => rx1_plllckd,            -- : out std_logic;
      serdesstrobe    => rx1_tmdsclk,            -- : out std_logic;
      tmdsclk         => rx1_serdesstrobe,       -- : out std_logic;
    
      hsync           => rx1_hsync,       -- : out std_logic;
      vsync           => rx1_vsync,       -- : out std_logic;
      de              => rx1_de,          -- : out std_logic;

      blue_vld        => rx1_blue_vld,        -- : out std_logic;
      green_vld       => rx1_green_vld,       -- : out std_logic;
      red_vld         => rx1_red_vld,         -- : out std_logic;
                         
      blue_rdy        => rx1_blue_rdy,        -- : out std_logic;
      green_rdy       => rx1_green_rdy,       -- : out std_logic;
      red_rdy         => rx1_red_rdy,         -- : out std_logic;

      psalgnerr       => rx1_psalgnerr,       -- : out std_logic;
  
      sdout           => rx1_sdata,       -- : out std_logic_vector(29 downto 0);
      red             => rx1_red,         -- : out std_logic_vector( 7 downto 0);
      green           => rx1_green,       -- : out std_logic_vector( 7 downto 0);
      blue            => rx1_blue         -- : out std_logic_vector( 7 downto 0);
);


--------------------------
--------------------------

rstin        <= rx0_reset;
pclk         <= rx0_pclk;
pclkx2       <= rx0_pclkx2;
pclkx10      <= rx0_pclkx10;
serdestrobe  <= rx0_serdesstrobe;
s_data       <= rx0_sdata;

process(pclkx2, rstin)
begin
  if(rstin = '1') then
    toggle <= '0';
  elsif(rising_edge(pclkx2)) then
    toggle <= not toggle;
  end if;
end process;

process(pclkx2)
begin
  if(rising_edge(pclkx2)) then
    if(toggle = '1') then
      tmdsclkint <= "11111";
    else
      tmdsclkint <= "00000";
    end if;
  end if;
end process;

i_serdesNto1_clkout: serdes_n_to_1:
generic map(
    SF      => 5
)
port map(
    iob_data_out => tmdsclk,
    ioclk        => pclkx10,
    serdesstrobe => serdesstrobe,
    gclk         => pclkx2,
    reset        => rstin,
    datain       => tmdsclkint
);

i_tmds3_obufds: OBUFDS
port map(
    O    => tx0_tmds(3),
    OB   => tx0_tmdsb(3),
    I    => tmdsclk
);

-- Forward TMDS Data: 3 chanels

i_serdesNto1_oserdes0: serdes_n_to_1:
generic map(
    SF      => 5
)
port map(
    iob_data_out => tmdsint(0),
    ioclk        => pclkx10,
    serdesstrobe => serdesstrobe,
    gclk         => pclkx2,
    reset        => rstin,
    datain       => tmds_data0
);

i_serdesNto1_oserdes1: serdes_n_to_1:
generic map(
    SF      => 5
)
port map(
    iob_data_out => tmdsint(1),
    ioclk        => pclkx10,
    serdesstrobe => serdesstrobe,
    gclk         => pclkx2,
    reset        => rstin,
    datain       => tmds_data1
);


i_serdesNto1_oserdes2: serdes_n_to_1:
generic map(
    SF      => 5
)
port map(
    iob_data_out => tmdsint(2),
    ioclk        => pclkx10,
    serdesstrobe => serdesstrobe,
    gclk         => pclkx2,
    reset        => rstin,
    datain       => tmds_data2
);


i_tmds0_obufds: OBUFDS
port map(
    O    => tx0_tmds(0),
    OB   => tx0_tmdsb(0),
    I    => tmdsint(0)
);

i_tmds1_obufds: OBUFDS
port map(
    O    => tx0_tmds(1),
    OB   => tx0_tmdsb(1),
    I    => tmdsint(1)
);

i_tmds2_obufds: OBUFDS
port map(
    O    => tx0_tmds(2),
    OB   => tx0_tmdsb(2),
    I    => tmdsint(2)
);


i_cnvrt_30to15_fifo_pixel2x: convert_30to15_fifo
port map(
    rst     => rstin,
    clk     => pclk,
    clkx2   => pclkx2,
    datain  => s_data,
    datout  => (tmds_data2 & tmds_data1 & tmds_data0)
);

-- end of ifdef DIRECTPASS
-------------------------
-------------------------


led <= rx0_red_rdy & rx0_green_rdy & rx0_blue_rdy & rx1_red_rdy & rx1_green_rdy & rx1_blue_rdy & rx0_de & rx1_de;


end rtl;      
