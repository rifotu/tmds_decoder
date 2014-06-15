library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.sub_module_components.all;

--TODO----------
-- Add a register map for status
-- info which can be read by master
-- via i2c, uart or spi

entity checker is
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
end checker;


architecture rtl of checker is

signal data_rdy     : std_logic_vector(2 downto 0);
signal data_vld     : std_logic_vector(2 downto 0);
signal pix_frm_lfsr : std_logic_vector(15 downto 0);
signal red          : std_logic_vector(7 downto 0);
signal green        : std_logic_vector(7 downto 0);
signal blue         : std_logic_vector(7 downto 0);

signal blue_match      : std_logic := '0';
signal red_match       : std_logic := '0';
signal green_match     : std_logic := '0';
signal match_err       : std_logic := '0';


begin


data_rdy <= i_blue_rdy & i_green_rdy & i_red_rdy;
data_vld <= i_blue_vld & i_green_vld & i_red_vld;


-- Random data is generated with 1CC delay
-- with respect to i_de
i_pix_lfsr: lfsr
generic map(
         seed => 293
)
port map(
         i_rst    => i_rst,
         i_clk      => i_clk,

         i_vsync  => i_vsync,
         i_hsync  => i_hsync,
         i_de     => i_de,
         o_pix    => pix_frm_lfsr
);

-- Register incoming pixel values
process(i_clk)
begin
  if(rising_edge(i_clk)) then
    blue  <= i_blue;
    red   <= i_red;
    green <= i_green;
  end if;
end process;


blue_match <= '1' when pix_frm_lfsr(7 downto 0) = blue else
              '0';

red_match <=  '1' when pix_frm_lfsr(15 downto 8) = red else
              '0';
  
green_match <= '1' when pix_frm_lfsr(12 downto 5) = green else
               '0';

match_err <= green_match or red_match or blue_match;


process(i_clk)
begin
  if(rising_edge(i_clk)) then
    if((data_rdy = "111") and (data_vld = "111") and (i_psalgnerr = '0')) then
      o_err <= match_err;
    else
      o_err <= '1';
    end if;
  end if;
end process;


end rtl;
