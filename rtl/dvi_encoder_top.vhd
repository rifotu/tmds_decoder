library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.sub_module_components.all;

library unisim;
use unisim.vcomponents.all;


entity dvi_encoder_top is
  port(

      pclk           : in  std_logic;                        -- pixel clock
      i_rst          : in  std_logic;                        -- reset

      blue_din       : in  std_logic_vector(7 downto 0);     -- Blue data in
      green_din      : in  std_logic_vector(7 downto 0);     -- Green data in
      red_din        : in  std_logic_vector(7 downto 0);     -- Red data in
      hsync          : in  std_logic;                        -- hsync data
      vsync          : in  std_logic;                        -- vsync data
      de             : in  std_logic;                        -- data enable
      tmds           : out std_logic_vector(3 downto 0);                                                       
      tmdsb          : out std_logic_vector(3 downto 0)                                                             
);
end dvi_encoder_top;


architecture rtl of dvi_encoder_top is

signal red      : std_logic_vector(9 downto 0);
signal green    : std_logic_vector(9 downto 0);
signal blue     : std_logic_vector(9 downto 0);
signal s_data   : std_logic_vector(29 downto 0);
signal fifo_out : std_logic_vector(14 downto 0);

signal tmds_data2    : std_logic_vector(4 downto 0);
signal tmds_data1    : std_logic_vector(4 downto 0);
signal tmds_data0    : std_logic_vector(4 downto 0);
signal tmdsint       : std_logic_vector(2 downto 0);
signal tmdsclkint    : std_logic_vector(4 downto 0) := b"00000";
signal tmdsclk       : std_logic;
signal toggle        : std_logic := '0';

signal   tx0_clkfbin      : std_logic;
signal   tx0_plllckd      : std_logic;
signal   tx0_clkfbout     : std_logic;
signal   tx0_pllclk2      : std_logic;
signal   tx0_pllclk0      : std_logic;
signal   tx0_pclkx2       : std_logic;
signal   tx0_pclkx10      : std_logic;
signal   tx0_bufpll_lock  : std_logic;
signal   tx0_serdesstrobe : std_logic;
signal   rst_frm_bufpll   : std_logic := '0';

signal   pclkx2           : std_logic;
signal   pclkx10          : std_logic;
signal   serdesstrobe     : std_logic;

signal hsync_vsync   : std_logic_vector(1 downto 0) := "00";

begin


------------------------------------------

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
    COMPENSATION    => "SOURCE_SYNCHRONOUS"
)
port map(
    CLKFBOUT        => tx0_clkfbout,  -- 1 bit output: PLL BASE feedback outpu
    CLKOUT0         => tx0_pllclk0,   -- 10x clk
    CLKOUT1         => open,         
    CLKOUT2         => tx0_pllclk2,   -- 2x  clk
    CLKOUT3         => open,
    CLKOUT4         => open,
    CLKOUT5         => open,
    LOCKED          => tx0_plllckd,   -- 1 bit output
    CLKFBIN         => tx0_clkfbin,   -- 1 bit input: feedback clock input
    CLKIN           => pclk,          -- 1 bit input: clock input
    RST             => i_rst          -- 1 bit input: reset input
);

i_bufg_tx0_clkfb: BUFG
port map(
    I       => tx0_clkfbout,
    O       => tx0_clkfbin
);

i_bufg_tx0_pclkx2: BUFG
port map(
    I       => tx0_pllclk2,
    O       => tx0_pclkx2
);


i_bufpll_tx0_ioclk_buf: BUFPLL
generic map(
      DIVIDE			=> 5
)
port map (
      PLLIN			=> tx0_pllclk0,      -- what clock to use, this must be unbuffered  input 	
      GCLK			=> tx0_pclkx2,       -- global clock to use as a reference for serdes strobe input	 
      LOCKED			=> tx0_plllckd,      -- input     	
      IOCLK			=> tx0_pclkx10,      -- clock used to send bits   output
      LOCK			=> tx0_bufpll_lock,  -- when the upstream pll is locked  output      	
      serdesstrobe		=> tx0_serdesstrobe  -- clock used to load data into serdes output
); 	

pclkx2        <= tx0_pclkx2;
pclkx10       <= tx0_pclkx10;
serdesstrobe  <= tx0_serdesstrobe;

rst_frm_bufpll <= not(tx0_bufpll_lock);



-------------------------------------------

  process(pclkx2, rst_frm_bufpll)
  begin
    if(rst_frm_bufpll = '1') then
      toggle <= '0';
    elsif (rising_edge(pclkx2)) then
      toggle <= not toggle;
    end if;
  end process;

  process(pclkx2)
  begin
    if(rising_edge(pclkx2)) then
      if(toggle = '1') then
        tmdsclkint <= (others => '1');
      else
        tmdsclkint <= (others => '0');
      end if;
    end if;
  end process;

  i_obufds_tmds3: OBUFDS
  port map(
      I       => tmdsclk,
      O       => tmds(3),
      OB      => tmdsb(3)
  );

  i_serdes_n_to_1_clkout: serdes_n_to_1
  generic map(
      SF              => 5
  ) 
  port map(
      iob_data_out    => tmdsclk,
      ioclk           => pclkx10,
      serdesstrobe    => serdesstrobe,
      gclk            => pclkx2,
      reset           => rst_frm_bufpll,
      datain          => tmdsclkint
  );


  i_serdes_n_to_1_oserdes0: serdes_n_to_1
  generic map(
      SF              => 5
  ) 
  port map(
      iob_data_out    => tmdsint(0),
      ioclk           => pclkx10,
      serdesstrobe    => serdesstrobe,
      gclk            => pclkx2,
      reset           => rst_frm_bufpll,
      datain          => tmds_data0
  );



  i_serdes_n_to_1_oserdes1: serdes_n_to_1
  generic map(
      SF              => 5
  ) 
  port map(
      iob_data_out    => tmdsint(1),
      ioclk           => pclkx10,
      serdesstrobe    => serdesstrobe,
      gclk            => pclkx2,
      reset           => rst_frm_bufpll,
      datain          => tmds_data1
  );


  i_serdes_n_to_1_oserdes2: serdes_n_to_1
  generic map(
      SF              => 5
  ) 
  port map(
      iob_data_out    => tmdsint(2),
      ioclk           => pclkx10,
      serdesstrobe    => serdesstrobe,
      gclk            => pclkx2,
      reset           => rst_frm_bufpll,
      datain          => tmds_data2
  );


  i_obufds_tmds0: OBUFDS
  port map(
      I       => tmdsint(0),
      O       => tmds(0),
      OB      => tmdsb(0)
  );

  i_obufds_tmds1: OBUFDS
  port map(
      I       => tmdsint(1),
      O       => tmds(1),
      OB      => tmdsb(1)
  );

  i_obufds_tmds2: OBUFDS
  port map(
      I       => tmdsint(2),
      O       => tmds(2),
      OB      => tmdsb(2)
  );

hsync_vsync <= hsync & vsync;

i_encb: encode
port map(

     i_clk       => pclk,
   --rstin       => rst_frm_bufpll,
     i_data      => blue_din,
     i_audio     => "0000",
     i_cntrl     => hsync_vsync,
     i_vid_de    => de,
     i_aud_de    => '0',
     o_data      => blue
);

i_encg: encode
port map(

     i_clk       => pclk,
   --rstin       => rst_frm_bufpll,
     i_data      => green_din,
     i_audio     => "0000",
     i_cntrl     => "00",
     i_vid_de    => de,
     i_aud_de    => '0',
     o_data      => green

);

i_encr: encode
port map(

     i_clk       => pclk,
   --rstin       => rst_frm_bufpll,
     i_data      => red_din,
     i_audio     => "0000",
     i_cntrl     => "00",
     i_vid_de    => de,
     i_aud_de    => '0',
     o_data      => red

);

s_data  <=  red(9 downto 5) & green(9 downto 5) & blue(9 downto 5) &
            red(4 downto 0) & green(4 downto 0) & blue(4 downto 0);

i_fifo_pix2x:  convert_30to15_fifo
port map(
    rst          => rst_frm_bufpll,
    clk          => pclk,
    clk2x        => pclkx2,
    datain       => s_data,
    dataout      => fifo_out

);

tmds_data2  <=  fifo_out(14 downto 10);
tmds_data1  <=  fifo_out( 9 downto  5);
tmds_data0  <=  fifo_out( 4 downto  0);

  
end rtl;
