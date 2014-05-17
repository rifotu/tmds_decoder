library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.sub_module_components.all;

library unisim;
use unisim.vcomponents.all;

entity chnlbond is
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
end chnlbond;

architecture rtl of chnlbond is

CONSTANT CTRLTOKEN0         : std_logic_vector(9 downto 0) := b"1101010100";
CONSTANT CTRLTOKEN1         : std_logic_vector(9 downto 0) := b"0010101011";
CONSTANT CTRLTOKEN2         : std_logic_vector(9 downto 0) := b"0101010100";
CONSTANT CTRLTOKEN3         : std_logic_vector(9 downto 0) := b"1010101011";

signal rawdata_vld          : std_logic := '0';
signal wa                   : std_logic_vector(3 downto 0);
signal ra                   : std_logic_vector(3 downto 0);
signal we                   : std_logic := '0';

signal dpfo_dout            : std_logic_vector(9 downto 0);
signal rcvd_ctkn            : std_logic := '0';
signal rcvd_ctkn_q          : std_logic := '0';
signal blnkbgn              : std_logic := '0';
signal next_blnkbgn         : std_logic := '0';
signal skip_line            : std_logic := '0';
signal rawdata_vld_q        : std_logic := '0';
signal rawdata_vld_rising   : std_logic := '0';
signal ra_en                : std_logic := '0';
signal sdata                : std_logic_vector(9 downto 0) := b"0000000000";

begin



-- FIFO Write Control Logic
process(clk)
begin
  if(rising_edge(clk)) then
    we <= rawdata_vld;
  end if;
end process;

process(clk)
begin
  if(rising_edge(clk)) then
    if(rawdata_vld = '1') then
      wa <= wa + '1';
    else
      wa <= (others => '0');
    end if;
  end if;
end process;

i_cbfifo_dram16xn: DRAM16XN
generic map(
      data_width      => 10
)
port map(
      data_in         => rawdata,
      address         => wa,
      address_dp      => ra,
      write_en        => we,
      clk             => clk,
      o_data_out      => open,
      o_data_out_dp   => dpfo_dout
);

process(clk)
begin
  if(rising_edge(clk)) then
    sdata <= dpfo_dout;
  end if;
end process;


-- FIFO read Control Logic


-----------------------------
-- Use blank period beginning
-- as a speical marker to
-- align all channel together
-----------------------------
process(clk)
begin
  if(rising_edge(clk)) then

    if( (sdata = CTRLTOKEN0) or (sdata = CTRLTOKEN1) or (sdata = CTRLTOKEN2) or (sdata = CTRLTOKEN3)) then
      rcvd_ctkn   <= '1';
    else
      rcvd_ctkn   <= '0';
    end if;
  
    rcvd_ctkn_q <= rcvd_ctkn;
    blnkbgn     <= (not rcvd_ctkn_q) and rcvd_ctkn;
  end if;
end process;


----------------------------
-- Skip the current line  --
----------------------------
process(clk)
begin
  if(rising_edge(clk)) then
    if(rawdata_vld = '0') then
      skip_line <= '0';
    elsif(blnkbgn = '1') then
      skip_line <= '1';
    end if;
  end if;
end process;


next_blnkbgn <= skip_line and blnkbgn;

--------------------------------
-- Declare my own readiness ----
--------------------------------
process(clk)
begin
  if(rising_edge(clk)) then
    if(rawdata_vld = '0') then
      iamrdy <= '0';
    elsif(next_blnkbgn = '1') then
      iamrdy <= '1';
    end if;
  end if;
end process;

process(clk)
begin
  if(rising_edge(clk)) then
    rawdata_vld_q       <= rawdata_vld;
    rawdata_vld_rising  <= rawdata_vld and not(rawdata_vld_q);
  end if;
end process;


----------------------------------------------------------------------------------------
-- 1. FIFO flow through first when all channels are found valid(phase aligned)
-- 2. When the special marker on my channel is found, the fifo read is hold
-- 3. Until the same markers are found across all three channels, the fifo read resumes
----------------------------------------------------------------------------------------
process(clk)
begin
  if(rising_edge(clk)) then
    if(rawdata_vld = '0') then
      ra <= (others => '0');
    elsif(ra_en = '1') then
      ra <= ra + '1';
    end if;
  end if;
end process;


sdata_out  <= sdata;


end rtl;
