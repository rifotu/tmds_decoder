library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;


library work;
use work.sub_module_components.all;

entity DRAM16XN is
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
end DRAM16XN;


architecture rtl of DRAM16XN is

signal i  : integer  := 0;

begin

  dist_ram: for i in 0 to DATA_WIDTH-1 generate
  begin

   i_ram32X1D: RAM32X1D
   generic map (
      INIT => X"00000000") -- Initial contents of RAM
   port map (
      D     => data_in(i),     -- Write 1-bit data input
      WE    => write_en,       -- Write enable input
      WCLK  => clk,            -- Write clock input
      A0    => address(0),     -- R/W address[0] input bit
      A1    => address(1),     -- R/W address[1] input bit
      A2    => address(2),     -- R/W address[2] input bit
      A3    => address(3),     -- R/W address[3] input bit
      A4    => '0',            -- R/W address[4] input bit
      DPRA0 => address_dp(0),  -- Read-only address[0] input bit
      DPRA1 => address_dp(1),  -- Read-only address[1] input bit
      DPRA2 => address_dp(2),  -- Read-only address[2] input bit
      DPRA3 => address_dp(3),  -- Read-only address[3] input bit
      DPRA4 => '0',             -- Read-only address[4] input bit
      SPO   => o_data_out(i),   -- R/W 1-bit data output
      DPO   => o_data_out_dp(i) -- Read-only 1-bit data output
   );
  end generate dist_ram;

  
end rtl;
