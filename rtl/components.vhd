library ieee;
use ieee.std_logic_1164.all;

package sub_module_components is

  
component DRAM16XN is
generic(
    DATA_WIDTH       : integer  := 20
);
port(
    data_in          : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    address          : in  std_logic_vector(3 downto 0);
    address_dp       : in  std_logic_vector(3 downto 0);
    write_en         : in  std_logic;
    clk              : in  std_logic;
    o_data_out       : out std_logic_vector(DATA_WIDTH-1 downto 0);
    o_data_out_dp    : out std_logic_vector(DATA_WIDTH-1 downto 0)
);
end component;


component serdes_1_to_5_diff_data is
generic(
      DIFF_TERM      : boolean   := TRUE;
      SIM_TAP_DELAY  : integer   := 49;
      BITSLIP_ENABLE : boolean   := FALSE
);
port(
    use_phase_detector    : in  std_logic;                     -- '1' enables the phase detector logic
    datain_p              : in  std_logic;                     -- Input from LVDS receiver pin
    datain_n              : in  std_logic;                     -- Input from LVDS receiver pin
    rxioclk               : in  std_logic;                     -- IO Clock network
    rxserdesstrobe        : in  std_logic;                     -- Parallel data capture strobe
    reset                 : in  std_logic;                     -- Reset line
    gclk                  : in  std_logic;                     -- Global clock
    bitslip               : in  std_logic;                     -- Bitslip control line
    data_out              : out std_logic_vector(4 downto 0)   -- Output data
);
end component;

component chnlbond is
port(
      clk              : in  std_logic;
      rawdata          : in  std_logic_vector(9 downto 0);
      iamvld           : in  std_logic;
      other_ch0_vld    : in  std_logic;
      other_ch1_vld    : in  std_logic;
      other_ch0_rdy    : in  std_logic;
      other_ch1_rdy    : in  std_logic;
      iamrdy           : out std_logic;
      sdata_out        : out std_logic_vector(9 downto 0)
);
end component;

component decode  is 
port(
      reset              : in  std_logic;
      pclk               : in  std_logic;
      pclkx2             : in  std_logic;
      pclkx10            : in  std_logic;
      serdesstrobe       : in  std_logic;
      din_p              : in  std_logic;
      din_n              : in  std_logic;
      other_ch0_vld      : in  std_logic;
      other_ch1_vld      : in  std_logic;
      other_ch0_rdy      : in  std_logic;
      other_ch1_rdy      : in  std_logic;
 
      iamvld_out         : out std_logic;
      iamrdy             : out std_logic;
      psalgnerr          : out std_logic;
      c0                 : out std_logic;
      c1                 : out std_logic;
      de                 : out std_logiC;
      sdout              : out std_logic_vector(9 downto 0);
      dout               : out std_logic_vector(7 downto 0)
);
end component;



component dvi_decoder is 
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
 
      pll_lckd_o         : out std_logic;
    
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
      pixclk             : out std_logic;
      red                : out std_logic_vector( 7 downto 0);
      green              : out std_logic_vector( 7 downto 0);
      blue               : out std_logic_vector( 7 downto 0)
);
end component;


component phsaligner is
generic(
    OPENEYE_CNT_WD     : integer  := 3;
    CTKNCNTWD          : integer  := 7;
    SRCHTIMERWD        : integer  := 12
);
port(
    rst                : in  std_logic;
    clk                : in  std_logic;
    sdata              : in  std_logic_vector(9 downto 0);  -- 10 bit 
    flipgear           : out std_logic;
    bitslip            : out std_logic;
    psaligned          : out std_logic  -- FSM output
);
end component;

component encode is
    port(
	i_clk	 : in  std_logic;
	i_data	 : in  std_logic_vector(7 downto 0);
	i_audio	 : in  std_logic_vector(3 downto 0);
	i_cntrl	 : in  std_logic_vector(1 downto 0);

	i_vid_de : in  std_logic;
	i_aud_de : in  std_logic;

	o_data	 : out std_logic_vector(9 downto 0)
    );
end component;

component dvi_encoder_top is
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
end component;

component serdes_n_to_1 is
generic(
      SF              : integer := 8
);
port(
      ioclk           : in  std_logic;
      serdesstrobe    : in  std_logic;
      reset           : in  std_logic;
      gclk            : in  std_logic;
      datain          : in  std_logic_vector(SF-1 downto 0);
      iob_data_out    : out std_logic
);
end component;


component pattern_gen is
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
end component;

component checker is
port(
    i_clk        : in  std_logic;
    i_rst        : in  std_logic;
    
    i_blue       : in  std_logic_vector(7 downto 0);
    i_red        : in  std_logic_vector(7 downto 0);
    i_green      : in  std_logic_vector(7 downto 0);

    i_hsync      : in  std_logic;
    i_vsync      : in  std_logic;
    i_de         : in  std_logic;

    i_blue_vld   : in  std_logic;
    i_green_vld  : in  std_logic;
    i_red_vld    : in  std_logic;
    
    i_blue_rdy   : in  std_logic;
    i_green_rdy  : in  std_logic;
    i_red_rdy    : in  std_logic;

    i_psalgnerr  : in  std_logic;

    o_err        : out std_logic
);
end component;


component convert_30to15_fifo is
port(
      rst             : in  std_logic;
      clk             : in  std_logic;
      clk2x           : in  std_logic;
      datain          : in  std_logic_vector(29 downto 0);
      dataout         : out std_logic_vector(14 downto 0)
);
end component;


component timing is
port(
      tc_hsblnk          : in  std_logic_vector(10 downto 0);
      tc_hssync          : in  std_logic_vector(10 downto 0);
      tc_hesync          : in  std_logic_vector(10 downto 0);
      tc_heblnk          : in  std_logic_vector(10 downto 0);

      hcount             : out std_logic_vector(10 downto 0);
      hsync              : out std_logic;
      hblnk              : out std_logic;
      
      tc_vsblnk          : in  std_logic_vector(10 downto 0);
      tc_vssync          : in  std_logic_vector(10 downto 0);
      tc_vesync          : in  std_logic_vector(10 downto 0);
      tc_veblnk          : in  std_logic_vector(10 downto 0);

      vcount             : out std_logic_vector(10 downto 0);
      vsync              : out std_logic;
      vblnk              : out std_logic;
      
      restart            : in  std_logic;
      clk                : in  std_logic
);
end component;

component lfsr is
generic(
       seed          : integer := 783   -- random number
);
port(
       i_rst         : in  std_logic;
       i_clk         : in  std_logic;

       i_vsync       : in  std_logic;
       i_hsync       : in  std_logic;
       i_de          : in  std_logic;
       
       o_pix         : out std_logic_vector(15 downto 0)  -- 1CC delay with respect to i_de
);
end component;






component top_tmds is
port(
      i_sys_clk      : in  std_logic;
      i_usr_rst      : in  std_logic;

      i_tmds         : in  std_logic_vector(3 downto 0);
      i_tmdsb        : in  std_logic_vector(3 downto 0);

      o_tmds         : out std_logic_vector(3 downto 0);
      o_tmdsb        : out std_logic_vector(3 downto 0);

      o_err          : out std_logic
);
end component;












end sub_module_components;
