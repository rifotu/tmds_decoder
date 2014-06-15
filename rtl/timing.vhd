library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity timing is
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
end timing;


architecture rtl of timing is

signal hpos_cnt      : std_logic_vector(10 downto 0) := (others => '0');
signal hpos_clr      : std_logic;
signal hpos_ena      : std_logic;

signal vpos_cnt      : std_logic_vector(10 downto 0) := (others => '0');
signal vpos_clr      : std_logic;
signal vpos_ena      : std_logic;

begin

------------------------------------
-- This logic describes a 11-bit  --
-- horizontal position counter.   --
------------------------------------

process(clk)
begin
  if(rising_edge(clk)) then
    if(hpos_clr = '1') then
      hpos_cnt <= (others => '0');
    elsif(hpos_ena = '1') then
      hpos_cnt <= hpos_cnt + '1';
    end if;
  end if;
end process;

------------------------------------
-- This logic describes a 11-bit  --
-- vertical position counter.   --
------------------------------------

process(clk)
begin
  if(rising_edge(clk)) then
    if(vpos_clr = '1') then
      vpos_cnt <= (others => '0');
    elsif(vpos_ena = '1') then
      vpos_cnt <= vpos_cnt + '1';
    end if;
  end if;
end process;


----------------------------------------------------------------------
-- This logic describes the position counter control.  Counters are --
-- reset when they reach the total count and the counter is then    --
-- enabled to advance.  Use of GTE operator ensures dynamic changes --
-- to display timing parameters do not allow counters to run away.  --
----------------------------------------------------------------------

hpos_ena <= '1';

hpos_clr <= '1' when (((hpos_cnt >= tc_heblnk) and (hpos_ena = '1')) or (restart = '1')) else
            '0';

vpos_ena <= hpos_clr;

vpos_clr <= '1' when (((vpos_cnt >= tc_veblnk) and (vpos_ena = '1')) or (restart = '1')) else
            '0';

----------------------------------------------------------------------
-- This is the logic for the horizontal outputs.  Active video is   --
-- always started when the horizontal count is zero.  Example:      --
--                                                                  --
-- tc_hsblnk = 03                                                   --
-- tc_hssync = 07                                                   --
-- tc_hesync = 11                                                   --
-- tc_heblnk = 15 (htotal)                                          --
--                                                                  --
-- hcount   00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15         --
-- hsync    ________________________------------____________        --
-- hblnk    ____________------------------------------------        --
--                                                                  --
-- hsync time  = (tc_hesync - tc_hssync) pixels                     --
-- hblnk time  = (tc_heblnk - tc_hsblnk) pixels                     --
-- active time = (tc_hsblnk + 1) pixels                             --
--                                                                  --
----------------------------------------------------------------------

hcount <= hpos_cnt;

hblnk  <= '1' when (hpos_cnt > tc_hsblnk) else
          '0';

hsync  <= '1' when ((hpos_cnt > tc_hssync) and (hpos_cnt <= tc_hesync)) else
          '0';


----------------------------------------------------------------------
-- This is the logic for the vertical outputs.  Active video is     --
-- always started when the vertical count is zero.  Example:        --
--                                                                  --
-- tc_vsblnk = 03                                                   --
-- tc_vssync = 07                                                   --
-- tc_vesync = 11                                                   --
-- tc_veblnk = 15 (vtotal)                                          --
--                                                                  --
-- vcount   00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15         --
-- vsync    ________________________------------____________        --
-- vblnk    ____________------------------------------------        --
--                                                                  --
-- vsync time  = (tc_vesync - tc_vssync) lines                      --
-- vblnk time  = (tc_veblnk - tc_vsblnk) lines                      --
-- active time = (tc_vsblnk + 1) lines                              --
--                                                                  --
----------------------------------------------------------------------

vcount  <= vpos_cnt;
vblnk   <= '1' when (vpos_cnt > tc_vsblnk) else
           '0';

vsync   <= '1' when ((vpos_cnt > tc_vssync) and (vpos_cnt <= tc_vesync)) else
           '0';



end rtl;

      
