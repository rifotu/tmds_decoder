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
 
      rst                : out std_logic;
      pclk_o               : out std_logic;
      pclkx2_o             : out std_logic;
      pclkx10_o            : out std_logic;
      
      pllclk0_o            : out std_logic; 
      pllclk1_o            : out std_logic;
      pllclk2_o            : out std_logic;

      pll_lckd_o           : out std_logic;
      serdesstrobe_o       : out std_logic;
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


end sub_module_components;
