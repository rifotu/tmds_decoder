library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.sub_module_components.all;

library unisim;
use unisim.vcomponents.all;

entity serdes_1_to_5_diff_data is
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
end serdes_1_to_5_diff_data;


architecture rtl of serdes_1_to_5_diff_data is

signal ddly_m            : std_logic := '0';
signal ddly_s            : std_logic := '0';
signal busys             : std_logic := '0';
signal rx_data_in        : std_logic := '0';
signal cascade           : std_logic := '0';
signal pd_edge           : std_logic := '0';
signal counter           : std_logic_vector(8 downto 0) := (others => '0');
signal state             : std_logic_vector(3 downto 0) := (others => '0');
signal cal_data_sint     : std_logic := '0';
signal busy_data         : std_logic := '0';
signal busy_data_d       : std_logic := '0';
signal cal_data_slave    : std_logic := '0';
signal enable            : std_logic := '0';
signal cal_data_master   : std_logic := '0';
signal rst_data          : std_logic := '0';
signal inc_data_int      : std_logic := '0';
signal inc_data          : std_logic := '0';
signal ce_data           : std_logic := '0';
signal valid_data_d      : std_logic := '0';
signal incdec_data_d     : std_logic := '0';
signal pdcounter         : std_logic_vector(4 downto 0) := b"01000";
signal valid_data        : std_logic := '0';
signal incdec_data       : std_logic := '0';
signal flag              : std_logic := '0';
signal mux               : std_logic := '1';
signal ce_data_inta      : std_logic := '0';
signal incdec_data_or    : std_logic_vector(1 downto 0) := (others => '0');
signal incdec_data_im    : std_logic := '0';
signal valid_data_or     : std_logic_vector(1 downto 0) := (others => '0');
signal valid_data_im     : std_logic := '0';
signal busy_data_or      : std_logic_vector(1 downto 0) := (others => '0');
signal all_ce            : std_logic := '0';
                
signal debug_in          : std_logic_vector(1 downto 0) := (others => '0');

signal rxpdcntr          : std_logic_vector(7 downto 0) := X"7F";


begin

busy_data        <= busys;
cal_data_slave   <= cal_data_sint;


-- IDELAY Calibration FSM
process(gclk, reset)
begin
  if(reset = '1') then
    state           <= (others => '0');
    cal_data_master <= '0';
    cal_data_sint   <= '0';
    counter         <= (others => '0');
    enable          <= '0';
    mux             <= '1';

  elsif rising_edge(gclk) then

    counter <= counter + '1';
    if(counter(8) = '1') then
      counter <= (others => '0');
    end if;

    if(counter(5) = '1') then
      enable  <= '1';
    end if;

    if(state = "0000" and enable = '1') then      -- Wait for IODELAY to be available
      cal_data_master <= '0';
      cal_data_sint   <= '0';
      rst_data        <= '0';
      if(busy_data_d = '0') then
        state <= "0001";
      end if;

    elsif(state = "0001") then     -- Issue calibrate command to both master and slave, needed for simulation, not for the silicon
      cal_data_master <= '1';
      cal_data_sint   <= '1';
      if(busy_data_d = '1') then      -- and wait for command to be accepted
        state <= "0010";
      end if;

    elsif(state = "0010") then     -- Now RST master and slave IODELAYs needed for simulation, not for the silicon
      cal_data_master <= '0';
      cal_data_sint   <= '0';
      if(busy_data_d = '0') then
        rst_data <= '1';
        state    <= "0011";
      end if;
    
    elsif(state = "0011") then      -- Wait for IODELAY to be available
      rst_data <= '0';
      if(busy_data_d = '0') then
        state <= "0100";
      end if;

    elsif(state = "0100") then  -- Wait for occasional enable
      if(counter(8) = '1') then
        state <= "0101";
      end if;

    elsif(state = "0101") then  -- Calibrate slave only
      if(busy_data_d = '0') then
        cal_data_sint <= '1';
        state <= "0110";
      end if;
      
    elsif(state = "0110") then  -- Wait for command to be accepted
      cal_data_sint <= '0';
      if(busy_data_d = '1') then
        state <= "0111";
      end if;

    elsif(state = "0111") then   -- Wait for all IODELAYs to be available, ie CAL command finished
      cal_data_sint <= '0';
      if(busy_data_d = '0') then
        state <= "0100";
      end if;
    end if;
  end if;
end process;


process(gclk, reset)        -- Per bit phase detection state machine
begin
  if(reset = '1') then
    pdcounter     <= "01000";
    ce_data_inta  <= '0';
    flag          <= '0';  -- flag is there to only allow once inc or dec per cal (test)
    inc_data_int  <= '0';

  elsif(rising_edge(gclk)) then

    busy_data_d <= busy_data_or(1);

    if(use_phase_detector = '1') then
      incdec_data_d <= incdec_data_or(1);
      valid_data_d  <= valid_data_or(1);

      if(ce_data_inta = '1') then
        ce_data <= mux;
      else
        ce_data <= '0';
      end if;

      if(state = "0111") then 
        flag <= '0';
      elsif( (state /= "0100") and busy_data_d = '1') then
        pdcounter    <= "10000";
        ce_data_inta <= '0';
      elsif( (pdcounter = "11111") and flag = '0') then
        ce_data_inta <= '1';
        inc_data_int <= '1';
        pdcounter    <= "10000";
        flag         <= '1';
      elsif( (pdcounter = "00000") and flag = '0') then
        ce_data_inta <= '1';
        inc_data_int <= '0';
        pdcounter    <= "10000";
        flag         <= '1';
      elsif( valid_data_d = '1' ) then
        ce_data_inta <= '0';
        if(incdec_data_d = '1' and pdcounter /= "11111") then
          pdcounter <= pdcounter + '1';
        elsif(incdec_data_d = '0' and pdcounter /= "00000") then
          pdcounter <= pdcounter + "11111";
        end if;
      else
        ce_data_inta <= '0';
      end if;

    else
      ce_data     <= all_ce;
      inc_data_int <= debug_in(1);
    end if;
  end if;
end process;


inc_data            <= inc_data_int;
incdec_data_or(0)   <= '0';
valid_data_or(0)    <= '0';
busy_data_or(0)     <= '0';
incdec_data_im      <= incdec_Data and mux;
incdec_data_or(1)   <= incdec_data_im or incdec_data_or(1) or incdec_data_or(0);   -- DIDN'T GET WHAT THE VERILOG COUNTERPART REALLY MEANS
valid_data_im       <= valid_data and mux;
valid_data_or(1)    <= valid_data_im or valid_data_or(1) or valid_data_or(0);
busy_data_or(1)     <= busy_data or busy_data_or(1) or busy_data_or(0);
all_ce              <= debug_in(0);

i_datain_ibufds: IBUFDS
generic map(
    DIFF_TERM => DIFF_TERM
)
port map(
    I         => datain_p,
    IB        => datain_n,
    O         => rx_data_in
);


-- Master IDELAY
i_iodelay2_master: IODELAY2
   generic map (
      DATA_RATE => "SDR",                    -- "SDR" or "DDR" 
      IDELAY_VALUE => 0,                     -- Amount of taps for fixed input delay (0-255)
      IDELAY2_VALUE => 0,                    -- Delay value when IDELAY_MODE="PCI" (0-255)
      IDELAY_MODE => "NORMAL",               -- "NORMAL" or "PCI" 
      ODELAY_VALUE => 0,                     -- Amount of taps fixed output delay (0-255)
      IDELAY_TYPE => "DIFF_PHASE_DETECTOR",  -- "FIXED", "DEFAULT", "VARIABLE_FROM_ZERO", "VARIABLE_FROM_HALF_MAX" 
                                             -- or "DIFF_PHASE_DETECTOR" 

      COUNTER_WRAPAROUND => "STAY_AT_LIMIT", -- "STAY_AT_LIMIT" or "WRAPAROUND" 
      DELAY_SRC => "IDATAIN",                -- "IO", "ODATAIN" or "IDATAIN" 
      SERDES_MODE => "MASTER",               -- "NONE", "MASTER" or "SLAVE" 
      SIM_TAPDELAY_VALUE => SIM_TAP_DELAY    -- Per tap delay used for simulation in ps
   )
   port map (
      IDATAIN => rx_data_in,   -- 1-bit input: Data input (connect to top-level port or I/O buffer)
      TOUT    => open,         -- 1-bit output: Delayed 3-state output
      DOUT    => open,         -- 1-bit output: Delayed data output
      T       => '1',          -- 1-bit input: 3-state input signal
      ODATAIN => '0',        -- 1-bit input: Output data input from output register or OSERDES2.
      DATAOUT => ddly_m,     -- 1-bit output: Delayed data output to ISERDES/input register
      DATAOUT2 => open,      -- 1-bit output: Delayed data output to general FPGA fabric
      IOCLK0 => rxioclk,     -- 1-bit input: Input from the I/O clock network
      IOCLK1 => '0',         -- 1-bit input: Input from the I/O clock network
      CLK => gclk,               -- 1-bit input: Clock input
      CAL => cal_data_master,    -- 1-bit input: Initiate calibration input
      INC => inc_data,           -- 1-bit input: Increment / decrement input
      CE => ce_data,             -- 1-bit input: Enable INC input
      RST => rst_data,           -- 1-bit input: Reset to zero or 1/2 of total delay period
      BUSY => open              -- 1-bit output: Busy output after CAL
   );

-- Slave IDELAY
i_iodelay2_slave: IODELAY2
   generic map (
      DATA_RATE => "SDR",                    -- "SDR" or "DDR" 
      IDELAY_VALUE => 0,                     -- Amount of taps for fixed input delay (0-255)
      IDELAY2_VALUE => 0,                    -- Delay value when IDELAY_MODE="PCI" (0-255)
      IDELAY_MODE => "NORMAL",               -- "NORMAL" or "PCI" 
      ODELAY_VALUE => 0,                     -- Amount of taps fixed output delay (0-255)
      IDELAY_TYPE => "DIFF_PHASE_DETECTOR",  -- "FIXED", "DEFAULT", "VARIABLE_FROM_ZERO", "VARIABLE_FROM_HALF_MAX" 
                                             -- or "DIFF_PHASE_DETECTOR" 

      COUNTER_WRAPAROUND => "WRAPAROUND", -- "STAY_AT_LIMIT" or "WRAPAROUND" 
      DELAY_SRC => "IDATAIN",                -- "IO", "ODATAIN" or "IDATAIN" 
      SERDES_MODE => "SLAVE",               -- "NONE", "MASTER" or "SLAVE" 
      SIM_TAPDELAY_VALUE => SIM_TAP_DELAY    -- Per tap delay used for simulation in ps
   )
   port map (
      IDATAIN => rx_data_in,    -- data from IBUFDS
      TOUT    => open,          -- tri-state signal to IOB
      DOUT    => open,          -- output data to IOB
      T       => '1',            -- tri-state control from OLOGIC/OSERDES2
      ODATAIN => '0',           -- data from OLOGIC/OSERDES2
      DATAOUT => ddly_s,        -- Slave output data to ILOGIC/ISERDES2
      DATAOUT2 => open,         
      IOCLK0 => rxioclk,        -- High speed IO clock for calibration
      IOCLK1 => '0',            --                                                                               
      CLK => gclk,              -- Fabric clock (GCLK) for control signals
      CAL => cal_data_slave,    -- Calibrate control signal
      INC => inc_data,          -- Increment counter
      CE => ce_data,            -- Clock Enable
      RST => rst_data,          -- Reset delay line
      BUSY => busys             -- output signal indicating sync circuit has finished / calibration has finished
   );


   -- Master ISERDES
   i_ISERDES2_master : ISERDES2
   generic map (
      DATA_WIDTH => 5,                  -- Parallel data width selection (2-8)
      DATA_RATE => "SDR",               -- Data-rate ("SDR" or "DDR")
      BITSLIP_ENABLE => BITSLIP_ENABLE, -- Enable Bitslip Functionality (TRUE/FALSE)
      SERDES_MODE => "MASTER",          -- "NONE", "MASTER" or "SLAVE" 
      INTERFACE_TYPE => "RETIMED"       -- "NETWORKING", "NETWORKING_PIPELINED" or "RETIMED" 
   )
   port map(
      D => ddly_m,                 -- 1-bit input: Input data
      CE0 => '1',                  -- 1-bit input: Clock enable input
      CLK0 => rxioclk,             -- 1-bit input: I/O clock network input
      CLK1 => '0',                 -- 1-bit input: Secondary I/O clock network input
      IOCE => rxserdesstrobe,      -- 1-bit input: Data strobe input
      RST => reset,                -- 1-bit input: Asynchronous reset input
      CLKDIV => gclk,              -- 1-bit input: FPGA logic domain clock input
      SHIFTIN => pd_edge,          -- 1-bit input: Cascade input signal for master/slave I/O
      BITSLIP => bitslip,          -- 1-bit input: Bitslip enable input
      FABRICOUT => open,           -- 1-bit output: Unsynchrnonized data output
      Q1 => data_out(1),           -- Q1 - Q4: 1-bit (each) output: Registered outputs to FPGA logic
      Q2 => data_out(2),
      Q3 => data_out(3),
      Q4 => data_out(4),
      DFB => open,                 -- 1-bit output: Feed-through clock output
      CFB0 => open ,               -- 1-bit output: Clock feed-through route output
      CFB1 => open,                -- 1-bit output: Clock feed-through route output
      VALID => valid_data,         -- 1-bit output: Output status of the phase detector
      INCDEC => incdec_data,       -- 1-bit output: Phase detector output
      SHIFTOUT => cascade          -- 1-bit output: Cascade output signal for master/slave I/O
   );
   



-- Slave ISERDES
   i_ISERDES2_slave : ISERDES2
   generic map (
      DATA_WIDTH => 5,                  -- Parallel data width selection (2-8)
      DATA_RATE => "SDR",               -- Data-rate ("SDR" or "DDR")
      BITSLIP_ENABLE => BITSLIP_ENABLE, -- Enable Bitslip Functionality (TRUE/FALSE)
      SERDES_MODE => "SLAVE",            -- "NONE", "MASTER" or "SLAVE" 
      INTERFACE_TYPE => "RETIMED"       -- "NETWORKING", "NETWORKING_PIPELINED" or "RETIMED" 
   )
   port map(
      D => ddly_s,                 -- 1-bit input: Input data
      CE0 => '1',                  -- 1-bit input: Clock enable input
      CLK0 => rxioclk,             -- 1-bit input: I/O clock network input
      CLK1 => '0',                 -- 1-bit input: Secondary I/O clock network input
      IOCE => rxserdesstrobe,      -- 1-bit input: Data strobe input
      RST => reset,                -- 1-bit input: Asynchronous reset input
      CLKDIV => gclk,              -- 1-bit input: FPGA logic domain clock input
      SHIFTIN => cascade,           -- 1-bit input: Cascade input signal for master/slave I/O
      BITSLIP => bitslip,          -- 1-bit input: Bitslip enable input
      FABRICOUT => open,           -- 1-bit output: Unsynchrnonized data output
      Q1 => open,           -- Q1 - Q4: 1-bit (each) output: Registered outputs to FPGA logic
      Q2 => open,
      Q3 => open,
      Q4 => data_out(0),
      DFB => open,                 -- 1-bit output: Feed-through clock output
      CFB0 => open ,               -- 1-bit output: Clock feed-through route output
      CFB1 => open,                -- 1-bit output: Clock feed-through route output
      VALID => open,           -- 1-bit output: Output status of the phase detector
      INCDEC => open,          -- 1-bit output: Phase detector output
      SHIFTOUT => pd_edge      -- 1-bit output: Cascade output signal for master/slave I/O
   );
  
   -- this should be related to simulation
   process(gclk, reset)
   begin
     if(reset = '1') then
       rxpdcntr <= X"7F";
     elsif(rising_edge(gclk)) then
       if(inc_data = '1') then
         rxpdcntr <= rxpdcntr + '1';
       else
         rxpdcntr <= rxpdcntr - '1';
       end if;
     end if;
   end process;


end rtl;
