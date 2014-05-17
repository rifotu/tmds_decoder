library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library work;
use work.sub_module_components.all;

library unisim;
use unisim.vcomponents.all;

entity decode  is 
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
end decode ;

architecture rtl of decode  is

constant CTRLTOKEN0       : std_logic_vector(9 downto 0) := b"1101010100";
constant CTRLTOKEN1       : std_logic_vector(9 downto 0):= b"0010101011";
constant CTRLTOKEN2       : std_logic_vector(9 downto 0):= b"0101010100";
constant CTRLTOKEN3       : std_logic_vector(9 downto 0):= b"1010101011";

signal flipgear           : std_logic := '0';
signal flipgearx2         : std_logic := '0';
signal toggle             : std_logic := '0';
signal rx_toggle          : std_logic := '0';
signal raw5bit            : std_logic_vector(4 downto 0);
signal raw5bit_q          : std_logic_vector(4 downto 0);
signal rawword            : std_logic_vector(9 downto 0);

signal bitslipx2          : std_logic := '0';
signal bitslip_q          : std_logic := '0';
signal bitslip            : std_logic;

signal rawdata            : std_logic_vector(9 downto 0);
signal sdata              : std_logic_vector(9 downto 0);
signal data               : std_logic_vector(7 downto 0);
signal iamvld             : std_logic := '0';

begin

------------------------------
-- 5 bit to 10 bit gear box --
------------------------------
process(pclkx2)
begin
  if(rising_edge(pclkx2)) then
    flipgearx2 <= flipgear;
  end if;
end process;

process(pclkx2, reset)
begin
  if(reset = '1') then
    toggle <= '0';
  elsif(rising_edge(pclkx2)) then
    toggle <= not toggle;
  end if;
end process;

rx_toggle <= toggle xor flipgearx2;   -- reverse hi-lo position

process(pclkx2)
begin
  if(rising_edge(pclkx2)) then
    raw5bit_q <= raw5bit;
    if(rx_toggle = '1') then -- gear from 5bit to 10 bit
      rawword <= raw5bit & raw5bit_q;
    end if;
  end if;
end process;


-- bitslip signal sync to pclkx2
process(pclkx2)
begin
  if(rising_edge(pclkx2)) then
    bitslip_q <= bitslip;
    bitslipx2 <= bitslip and (not bitslip_q);
  end if;
end process;

-- 1:5 deserializer working at x2 pclk rate
i_serdes_0: serdes_1_to_5_diff_data
generic map(
    DIFF_TERM          => FALSE,
    BITSLIP_ENABLE     => TRUE
)
port map(
    use_phase_detector => '1',
    datain_p           => din_p,
    datain_n           => din_n,
    rxioclk            => pclkx10,
    rxserdesstrobe     => serdesstrobe,
    reset              => reset,
    gclk               => pclkx2,
    bitslip            => bitslipx2,
    data_out           => raw5bit
);

-- Doing word boundary detection here
rawdata <= rawword;

-- Phase aligner instance
i_phsalgn_0: phsaligner
port map(
    rst         => reset,
    clk         => pclk,
    sdata       => rawdata,
    bitslip     => bitslip,
    flipgear    => flipgear,
    psaligned   => iamvld
);


psalgnerr <= '0';

i_chnlbond_cbnd: chnlbond
port map(
    clk           => pclk,
    rawdata       => rawdata,
    iamvld        => iamvld,
    other_ch0_vld => other_ch0_vld,
    other_ch1_vld => other_ch1_vld,
    other_ch0_rdy => other_ch0_rdy,
    other_ch1_rdy => other_ch1_rdy,
    iamrdy        => iamrdy,
    sdata_out     => sdata
);

iamvld_out  <= iamvld;

end rtl;
