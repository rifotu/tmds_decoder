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
      pclkx2         : in  std_logic;                        -- pixel clock x2
      pclkx10        : in  std_logic;
      serdesstrobe   : in  std_logic;                        -- oserdes2 serdesstrobe
      rstin          : in  std_logic;                        -- reset
      blue_din       : in  std_logic_vector(7 downto 0);     -- Blue data in
      green_din      : in  std_logic_vector(7 downto 0);     -- Green data in
      red_din        : in  std_logic_vector(7 downto 0);     -- Red data in
      hsync          : in  std_logic;                        -- hsync data
      vsync          : in  std_logic;                        -- vsync data
      de             : in  std_logic;                        -- data enable
      tmds           : out std_logic_vector(4 downto 0);                                                       
      tmdsb          : out std_logic_vector(4 downto 0)                                                             
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

begin


  process(pclkx2, rstin)
  begin
    if(rstin = '1') then
      toggle <= '0';
    elsif (rising_edge(pclkx2)) then
      toggle <= not toggle;
    end if;
  end process;

  process(pclkx2)
  begin
    if(rising_edge(pclkx2) then
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
      reset           => rstin,
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
      reset           => rstin,
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
      reset           => rstin,
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
      reset           => rstin,
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


i_encb: encode
port map(

     i_clk       => pclk,
   --rstin       => rstin,
     i_data      => blue_din,
     i_cntrl     => (hsync & vsync),
     i_vid_de    => de,
     i_aud_de    => '0',
     o_data      => blue
);

i_encg: encode
port map(

     i_clk       => pclk,
   --rstin       => rstin,
     i_data      => green_din,
     i_cntrl     => "00",
     i_vid_de    => de,
     i_aud_de    => '0',
     o_data      => green

);

i_encr: encode
port map(

     i_clk       => pclk,
   --rstin       => rstin,
     i_data      => red_din,
     i_cntrl     => "00",
     i_vid_de    => de,
     i_aud_de    => '0',
     o_data      => red

);

s_data  <=  red(9 downto 5) & green(9 downto 5) & blue(9 downto 5) &
            red(4 downto 0) & green(4 downto 0) & blue(4 downto 0);

i_fifo_pix2x:  convert_30to15_fifo
port map(
    rst          => rstin,
    clk          => pclk,
    clkx2        => pclkx2,
    datain       => s_data,
    datout       => fifo_out

);

tmds_data2  <=  fifo_out(14 downto 10);
tmds_data1  <=  fifo_out( 9 downto  5);
tmds_data0  <=  fifo_out( 4 downto  0);

  
end rtl;
