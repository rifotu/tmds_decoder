library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity top_tmds is
port(
      sys_clk      : in  std_logic;
      rst          : in  std_logic;

      tmds_in      : in  std_logic_vector(3 downto 0);
      tmds_inb     : in  std_logic_vector(3 downto 0);

      tmds         : out std_logic_vector(3 downto 0);
      tmdsb        : out std_logic_vector(3 downto 0);

);
end top_tmds;



architecture rtl of top_tmds is





begin


i_sysclk_buf:  IBUF





end rtl;
