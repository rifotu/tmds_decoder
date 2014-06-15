library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity lfsr is
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
end lfsr;


architecture rtl of lfsr is

constant HSYNC_BASE_SEED : std_logic_vector(15 downto 0) := conv_std_logic_vector(147, 16);
constant INC_SEED_VALUE  : std_logic_vector(15 downto 0) := conv_std_logic_vector( 47, 16);

signal lfsr       : std_logic_vector(15 downto 0);
signal input      : std_logic;

signal hsync_d1   : std_logic;
signal vsync_d1   : std_logic;
signal hsync_ris  : std_logic;
signal vsync_ris  : std_logic;
signal new_lfsr   : std_logic_vector(15 downto 0);



begin

process(i_clk)
begin
  if(i_clk'event and i_clk = '1') then
    hsync_d1 <= i_hsync;
    vsync_d1 <= i_vsync;
  end if;
end process;

hsync_ris <= not(hsync_d1) and i_hsync;
vsync_ris <= not(vsync_d1) and i_vsync;

process(i_clk)
begin
  if(i_clk'event and i_clk = '1') then
    if(vsync_ris = '1') then
      new_lfsr <= HSYNC_BASE_SEED;
    elsif(hsync_ris = '1') then
      new_lfsr <= new_lfsr + INC_SEED_VALUE;
    end if;
  end if;
end process;


-- linear feedback shift register
process(i_clk, i_rst)
begin
  if(i_rst = '1') then
      lfsr <= (others => '0');
  elsif(i_clk'event and i_clk = '1') then
    if(hsync_ris = '1') then
      lfsr <= new_lfsr;
    elsif(i_de = '1') then
      lfsr <= lfsr(14 downto 0) & input;
    end if;
  end if;
end process;

-- tap choices are made according to XAPP052
input <= not(lfsr(3) xor lfsr(12) xor lfsr(14) xor lfsr(15));

-- assign outputs

o_pix  <= lfsr;

end rtl;

