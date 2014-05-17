library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.sub_module_components.all;

library unisim;
use unisim.vcomponents.all;

entity phsaligner is
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
end phsaligner;



architecture rtl of phsaligner is


constant  CTRLTOKEN0   : std_logic_vector(9 downto 0) := b"1101010100";
constant  CTRLTOKEN1   : std_logic_vector(9 downto 0) := b"0010101011";
constant  CTRLTOKEN2   : std_logic_vector(9 downto 0) := b"0101010100";
constant  CTRLTOKEN3   : std_logic_vector(9 downto 0) := b"1010101011";
constant  INIT         : std_logic_vector(5 downto 0) := b"000001";      -- 6'b1 << 0;
constant  SEARCH       : std_logic_vector(5 downto 0) := b"000010";      -- 6'b1 << 1;  // Searching for control tokens
constant  BITSLIP_C    : std_logic_vector(5 downto 0) := b"000100";      -- 6'b1 << 2;
constant  RCVDCTKN     : std_logic_vector(5 downto 0) := b"001000";      -- 6'b1 << 3;  // Received at one Control Token and check for more
constant  BLNKPRD      : std_logic_vector(5 downto 0) := b"010000";      -- 6'b1 << 4;
constant  PSALGND      : std_logic_vector(5 downto 0) := b"100000";      -- 6'b1 << 5;  // Phase alignment achieved
constant  nSTATES      : integer  := 6;

constant  BLNKPRD_CNT_WD  : integer := 1;


signal rcvd_ctkn       : std_logic := '0';
signal rcvd_ctkn_q     : std_logic := '0';
signal blnkgen         : std_logic := '0';  -- blank period begins

signal ctkn_srh_timer  : std_logic_vector(SRCHTIMERWD-1 downto 0);
signal ctkn_srh_rst    : std_logic := '0';
signal ctkn_srh_tout   : std_logic := '0';

signal cstate          : std_logic_vector(nSTATES-1 downto 0) := conv_std_logic_vector(1, nSTATES);
signal nstate          : std_logic_vector(nSTATES-1 downto 0);
signal blnkprd_cnt     : std_logic_vector(BLNKPRD_CNT_WD-1 downto 0) := (others => '0');
signal bitslip_cnt     : std_logic_vector(2 downto 0);

signal blnkbgn         : std_logic := '0';
signal ctkn_cnt_rst    : std_logic := '0';
signal ctkn_counter    : std_logic_vector(CTKNCNTWD-1 downto 0) := (others => '0');
signal ctkn_cnt_tout   : std_logic := '0';

begin


  process(clk)
  begin
    if(rising_edge(clk)) then
       if((sdata = CTRLTOKEN0) or (sdata = CTRLTOKEN1) or (sdata = CTRLTOKEN2) or (sdata = CTRLTOKEN3)) then
         rcvd_ctkn <= '1';
       end if;

       rcvd_ctkn_q <= rcvd_ctkn;
       blnkbgn     <= not(rcvd_ctkn_q) and rcvd_ctkn;
    end if;
  end process;

  -----------------------------------------------------
  -- Control Token Search Timer
  --
  -- DVI 1.0 Spec. says periodic blanking should start
  -- no less than every 50ms or 20HZ
  -- 2^24 of 74.25MHZ cycles is about 200ms
  -----------------------------------------------------
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(ctkn_srh_rst = '1') then
        ctkn_srh_timer <= (others => '0');
      else
        ctkn_srh_timer <= ctkn_srh_timer + '1';
      end if;
    end if;
  end process;

  process(clk)
  begin
    if(rising_edge(clk)) then
      if(ctkn_srh_timer = conv_std_logic_vector(1, SRCHTIMERWD)) then
        ctkn_srh_tout <= '1';
      else
        ctkn_srh_tout <= '0';
      end if;
    end if;
  end process;

  

  -----------------------------------------------------
  -- Contorl Token Event Counter
  --
  -- DVI 1.0 Spec. says the minimal blanking period
  -- is at least 128 pixels long in order to achieve
  -- synchronization
  --
  -- HDMI reduces this to as little as 8
  -----------------------------------------------------
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(ctkn_cnt_rst = '1') then
        ctkn_counter <= (others => '0');
      else
        ctkn_counter <= ctkn_counter + '1';
      end if;
    end if;
  end process;


  process(clk)
  begin
    if(rising_edge(clk)) then
      if(ctkn_counter = conv_std_logic_vector(1, CTKNCNTWD)) then
        ctkn_cnt_tout <= '1';
      else
        ctkn_cnt_tout <= '0';
      end if;
    end if;
  end process;


  process(clk, rst)
  begin
    if(rst = '1') then
      cstate <= INIT;
    elsif(rising_edge(clk)) then
      cstate <= nstate;
    end if;
  end process;

  ----------------------------------------------------------
  -- Counter counts number of blank period detected
  -- in order to qualify the bitslip position
  ----------------------------------------------------------

  process(cstate, blnkbgn, rcvd_ctkn, blnkprd_cnt, ctkn_cnt_tout, ctkn_srh_tout)
  begin
    
    nstate <= cstate;

    case cstate is

      when INIT =>
        if(ctkn_srh_tout = '1') then
          nstate <= SEARCH;
        else
          nstate <= INIT;
        end if;

      when SEARCH =>
        if(blnkbgn = '1') then
          nstate <= RCVDCTKN;
        else
          if(ctkn_srh_tout = '1') then
            nstate <= BITSLIP_C;
          else
            nstate <= SEARCH;
          end if;
        end if;
     
      when BITSLIP_C =>
        nstate <= SEARCH;

      when RCVDCTKN =>
        if(rcvd_ctkn = '1') then
          if(ctkn_cnt_tout = '1') then
            nstate <= BLNKPRD;
          else
            nstate <= RCVDCTKN;
          end if;
        else
          nstate <= SEARCH;
        end if;

      when BLNKPRD =>
        if(blnkprd_cnt = conv_std_logic_vector(1, BLNKPRD_CNT_WD)) then
          nstate <= PSALGND;
        else
          nstate <= SEARCH;
        end if;
    
      when PSALGND =>
        nstate <= PSALGND;  -- phase aligned so hang around here

      when others =>
        null;

    end case;
  end process;


  process(clk, rst)
  begin
    if(rst = '1') then
      psaligned     <= '0';
      ctkn_srh_rst  <= '1';
      ctkn_cnt_rst  <= '1';

      bitslip       <= '0';
      bitslip_cnt   <= (others => '0');
      flipgear      <= '0';
      blnkprd_cnt   <= (others => '0');

    elsif(rising_edge(clk)) then

      case cstate is

        when INIT => 
          ctkn_srh_rst <= '0';
          ctkn_cnt_rst <= '1';
          bitslip      <= '0';
          psaligned    <= '0';
          bitslip      <= '0';
          bitslip_cnt  <= (others => '0');
          flipgear     <= '0';
          blnkprd_cnt  <= (others => '0');


        when SEARCH =>
          ctkn_srh_rst <= '0';
          ctkn_cnt_rst <= '1';
          bitslip      <= '0';
          psaligned    <= '0';


        when BITSLIP_C =>
          ctkn_srh_rst <= '1';
          bitslip      <= '1';
          bitslip_cnt  <= bitslip_cnt + '1';
          flipgear     <= bitslip_cnt(2);    -- bitslip has toggled for 4 times

        when RCVDCTKN => 
          ctkn_srh_rst <= '0';
          ctkn_cnt_rst <= '0';

        when BLNKPRD =>
          blnkprd_cnt <= blnkprd_cnt + '1';

        when PSALGND => 
          psaligned <= '1';

        when others =>
          null;

      end case;
    end if;
  end process;
                          
end rtl;
