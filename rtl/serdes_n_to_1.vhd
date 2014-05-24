library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.sub_module_components.all;

library unisim;
use unisim.vcomponents.all;

entity serdes_n_to_1 is
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
end serdes_n_to_1;

architecture rtl of serdes_n_to_1 is


signal cascade_di        : std_logic;
signal cascade_do        : std_logic;
signal cascade_ti        : std_logic;
signal cascade_to        : std_logic;
signal mdatain           : std_logic_vector(8 downto 0);
signal i                 : integer := 0;


begin



for i in 0 to SF-1 generate
begin
  mdatain(i) <= datain(i);
end generate;


for i in SF to 8 generate
begin
  mdatain(i) <= '0';
end generate;


i_OSERDES2_m : OSERDES2
   generic map (
      DATA_WIDTH   => SF,               -- Parallel data width (2-8)
      DATA_RATE_OQ => "SDR",            -- Output Data Rate ("SDR" or "DDR")
      DATA_RATE_OT => "SDR",            -- 3-state Data Rate ("SDR" or "DDR")
      SERDES_MODE  => "MASTER",         -- "NONE", "MASTER" or "SLAVE" 
      OUTPUT_MODE  => "DIFFERENTIAL"    -- "SINGLE_ENDED" or "DIFFERENTIAL" 
   )
   port map (
      OQ     => iob_data_out,  -- 1-bit output: Data output to pad or IODELAY2
      OCE    => '1',           -- 1-bit input: Clock enable input
      CLK0   => ioclk,         -- 1-bit input: I/O clock input
      CLK1   => '0',           -- 1-bit input: Secondary I/O clock input
      IOCE   => serdesstrobe,  -- 1-bit input: Data strobe input
      RST    => reset,         -- 1-bit input: Asynchrnous reset input
      CLKDIV => gclk,          -- 1-bit input: Logic domain clock input
      D4     => mdatain(7),    -- D1 - D4: 1-bit (each) input: Parallel data inputs
      D3     => mdatain(6),
      D2     => mdatain(5),
      D1     => mdatain(4),              
      TQ     => open,           -- 1-bit output: 3-state output to pad or IODELAY2
      T1     => '0',            -- T1 - T4: 1-bit (each) input: 3-state control inputs
      T2     => '0',
      T3     => '0',
      T4     => '0',
      TRAIN  => '0',            -- 1-bit input: Training pattern enable input
      TCE    => '1',            -- 1-bit input: 3-state clock enable input
      SHIFTIN1  => '1',         -- 1-bit input: Cascade data input
      SHIFTIN2  => '1',         -- 1-bit input: Cascade 3-state input
      SHIFTIN3  => cascade_do,  -- 1-bit input: Cascade differential data input
      SHIFTIN4  => cascade_to,  -- 1-bit input: Cascade differential 3-state input
      SHIFTOUT1 => cascade_di,  -- 1-bit output: Cascade data output
      SHIFTOUT2 => cascade_ti,  -- 1-bit output: Cascade 3-state output
      SHIFTOUT3 => open,        -- 1-bit output: Cascade differential data output
      SHIFTOUT4 => open         -- 1-bit output: Cascade differential 3-state output
   );



i_OSERDES2_s : OSERDES2
   generic map (
      DATA_WIDTH   => SF,               -- Parallel data width (2-8)
      DATA_RATE_OQ => "SDR",            -- Output Data Rate ("SDR" or "DDR")
      DATA_RATE_OT => "SDR",            -- 3-state Data Rate ("SDR" or "DDR")
      SERDES_MODE  => "SLAVE",          -- "NONE", "MASTER" or "SLAVE" 
      OUTPUT_MODE  => "DIFFERENTIAL"    -- "SINGLE_ENDED" or "DIFFERENTIAL" 
   )
   port map (
      OQ     => open,          -- 1-bit output: Data output to pad or IODELAY2
      OCE    => '1',           -- 1-bit input: Clock enable input
      CLK0   => ioclk,         -- 1-bit input: I/O clock input
      CLK1   => '0',           -- 1-bit input: Secondary I/O clock input
      IOCE   => serdesstrobe,  -- 1-bit input: Data strobe input
      RST    => reset,         -- 1-bit input: Asynchrnous reset input
      CLKDIV => gclk,          -- 1-bit input: Logic domain clock input
      D4     => mdatain(3),    -- D1 - D4: 1-bit (each) input: Parallel data inputs
      D3     => mdatain(2),
      D2     => mdatain(1),
      D1     => mdatain(0),              
      TQ     => open,           -- 1-bit output: 3-state output to pad or IODELAY2
      T1     => '0',            -- T1 - T4: 1-bit (each) input: 3-state control inputs
      T2     => '0',
      T3     => '0',
      T4     => '0',
      TRAIN  => '0',                  -- 1-bit input: Training pattern enable input
      TCE    => '1',                  -- 1-bit input: 3-state clock enable input
      SHIFTIN1  => cascade_di,        -- 1-bit input: Cascade data input
      SHIFTIN2  => cascade_ti,        -- 1-bit input: Cascade 3-state input
      SHIFTIN3  => '1',               -- 1-bit input: Cascade differential data input
      SHIFTIN4  => '1',               -- 1-bit input: Cascade differential 3-state input
      SHIFTOUT1 => open,              -- 1-bit output: Cascade data output
      SHIFTOUT2 => open,              -- 1-bit output: Cascade 3-state output
      SHIFTOUT3 => cascade_do,        -- 1-bit output: Cascade differential data output
      SHIFTOUT4 => cascade_to         -- 1-bit output: Cascade differential 3-state output
   );



end rtl;
