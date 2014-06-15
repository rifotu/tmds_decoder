library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.sub_module_components.all;

entity convert_30to15_fifo is
port(
      rst             : in  std_logic;
      clk             : in  std_logic;
      clk2x           : in  std_logic;
      datain          : in  std_logic_vector(29 downto 0);
      dataout         : out std_logic_vector(14 downto 0)
);
end convert_30to15_fifo;

architecture rtl of convert_30to15_fifo is

CONSTANT ADDR0       : std_logic_vector( 3 downto 0) := "0000";
CONSTANT ADDR1       : std_logic_vector( 3 downto 0) := "0001";
CONSTANT ADDR2       : std_logic_vector( 3 downto 0) := "0010";
CONSTANT ADDR3       : std_logic_vector( 3 downto 0) := "0011";
CONSTANT ADDR4       : std_logic_vector( 3 downto 0) := "0100";
CONSTANT ADDR5       : std_logic_vector( 3 downto 0) := "0101";
CONSTANT ADDR6       : std_logic_vector( 3 downto 0) := "0110";
CONSTANT ADDR7       : std_logic_vector( 3 downto 0) := "0111";
CONSTANT ADDR8       : std_logic_vector( 3 downto 0) := "1000";
CONSTANT ADDR9       : std_logic_vector( 3 downto 0) := "1001";
CONSTANT ADDR10      : std_logic_vector( 3 downto 0) := "1010";
CONSTANT ADDR11      : std_logic_vector( 3 downto 0) := "1011";
CONSTANT ADDR12      : std_logic_vector( 3 downto 0) := "1100";
CONSTANT ADDR13      : std_logic_vector( 3 downto 0) := "1101";
CONSTANT ADDR14      : std_logic_vector( 3 downto 0) := "1110";
CONSTANT ADDR15      : std_logic_vector( 3 downto 0) := "1111";


signal wa            : std_logic_vector( 3 downto 0);
signal wa_d          : std_logic_vector( 3 downto 0);
signal ra            : std_logic_vector( 3 downto 0);
signal ra_d          : std_logic_vector( 3 downto 0);
signal dataint       : std_logic_vector(29 downto 0);
signal rstsync       : std_logic := '0';
signal rstsync_q     : std_logic := '0';
signal rstp          : std_logic := '0';
signal sync          : std_logic := '0';
signal db            : std_logic_vector(29 downto 0) := (others => '0');
signal mux           : std_logic_vector(14 downto 0) := (others => '0');


attribute ASYNC_REG :  string;
attribute ASYNC_REG of rstsync: signal is "TRUE";

begin


process(wa)
begin
  case wa is
    when ADDR0  => wa_d <= ADDR1;
    when ADDR1  => wa_d <= ADDR2;
    when ADDR2  => wa_d <= ADDR3;
    when ADDR3  => wa_d <= ADDR4;
    when ADDR4  => wa_d <= ADDR5;
    when ADDR5  => wa_d <= ADDR6;
    when ADDR6  => wa_d <= ADDR7;
    when ADDR7  => wa_d <= ADDR8;
    when ADDR8  => wa_d <= ADDR9;
    when ADDR9  => wa_d <= ADDR10;
    when ADDR10 => wa_d <= ADDR11;
    when ADDR11 => wa_d <= ADDR12;
    when ADDR12 => wa_d <= ADDR13;
    when ADDR13 => wa_d <= ADDR14;
    when ADDR14 => wa_d <= ADDR15;

    when others =>
      wa_d <= ADDR0;
  end case;
end process;

i_fdc_wa0: FDC
port map(
    C    => clk,
    D    => wa_d(0),
    CLR  => rst,
    Q    => wa(0)
);

i_fdc_wa1: FDC
port map(
    C    => clk,
    D    => wa_d(1),
    CLR  => rst,
    Q    => wa(1)
);

i_fdc_wa2: FDC
port map(
    C    => clk,
    D    => wa_d(2),
    CLR  => rst,
    Q    => wa(2)
);

i_fdc_wa3: FDC
port map(
    C    => clk,
    D    => wa_d(3),
    CLR  => rst,
    Q    => wa(3)
);

 --Dual Port fifo to bridge data from clk to clk2x
i_dram16xn_fifo: DRAM16XN
generic map(
    data_width    => 30
)
port map(
    data_in       => datain,
    address       => wa,
    address_dp    => ra,
    write_en      => '1',
    clk           => clk,
    o_data_out    => open,
    o_data_out_dp => dataint
);


--  Here starts clk2x domain for fifo read out 
--  FIFO read is set to be once every 2 cycles of clk2x in order
--  to keep up pace with the fifo write speed
--  Also FIFO read reset is delayed a bit in order to avoid
--  underflow.

process(ra)
begin
  case ra is
    when ADDR0  => ra_d <= ADDR1;
    when ADDR1  => ra_d <= ADDR2;
    when ADDR2  => ra_d <= ADDR3;
    when ADDR3  => ra_d <= ADDR4;
    when ADDR4  => ra_d <= ADDR5;
    when ADDR5  => ra_d <= ADDR6;
    when ADDR6  => ra_d <= ADDR7;
    when ADDR7  => ra_d <= ADDR8;
    when ADDR8  => ra_d <= ADDR9;
    when ADDR9  => ra_d <= ADDR10;
    when ADDR10 => ra_d <= ADDR11;
    when ADDR11 => ra_d <= ADDR12;
    when ADDR12 => ra_d <= ADDR13;
    when ADDR13 => ra_d <= ADDR14;
    when ADDR14 => ra_d <= ADDR15;

    when others =>
      ra_d <= ADDR0;
  end case;
end process;

  
i_fdp_rst: FDP
port map(
    C   => clk2x,
    D   => rst,
    PRE => rst,
    Q   => rstsync
);

i_fd_rstsync: FD
port map(
    C   => clk2x,
    D   => rstsync,
    Q   => rstsync_q
);

i_fd_rstp: FD
port map(
    C   => clk2x,
    D   => rstsync_q,
    Q   => rstp
);


i_fdr_sync_gen: FDR
port map(
    C   => clk2x,
    D   => not(sync),
    Q   => sync,
    R   => rstp
);


i_fdc_ra0: FDRE
port map(
    C   => clk2x,
    D   => ra_d(0),
    R   => rstp,
    CE  => sync,
    Q   => ra(0)
);

i_fdc_ra1: FDRE
port map(
    C   => clk2x,
    D   => ra_d(1),
    R   => rstp,
    CE  => sync,
    Q   => ra(1)
);

i_fdc_ra2: FDRE
port map(
    C   => clk2x,
    D   => ra_d(2),
    R   => rstp,
    CE  => sync,
    Q   => ra(2)
);

i_fdc_ra3: FDRE
port map(
    C   => clk2x,
    D   => ra_d(3),
    R   => rstp,
    CE  => sync,
    Q   => ra(3)
);



i_fd_db0 : FDE port map( C => clk2x, D => dataint(0 ),CE => sync, Q   => db(0)  );
i_fd_db1 : FDE port map( C => clk2x, D => dataint(1 ),CE => sync, Q   => db(1)  );
i_fd_db2 : FDE port map( C => clk2x, D => dataint(2 ),CE => sync, Q   => db(2)  );
i_fd_db3 : FDE port map( C => clk2x, D => dataint(3 ),CE => sync, Q   => db(3)  );
i_fd_db4 : FDE port map( C => clk2x, D => dataint(4 ),CE => sync, Q   => db(4)  );
i_fd_db5 : FDE port map( C => clk2x, D => dataint(5 ),CE => sync, Q   => db(5)  );
i_fd_db6 : FDE port map( C => clk2x, D => dataint(6 ),CE => sync, Q   => db(6)  );
i_fd_db7 : FDE port map( C => clk2x, D => dataint(7 ),CE => sync, Q   => db(7)  );
i_fd_db8 : FDE port map( C => clk2x, D => dataint(8 ),CE => sync, Q   => db(8)  );
i_fd_db9 : FDE port map( C => clk2x, D => dataint(9 ),CE => sync, Q   => db(9)  );
i_fd_db10: FDE port map( C => clk2x, D => dataint(10),CE => sync, Q   => db(10) );
i_fd_db11: FDE port map( C => clk2x, D => dataint(11),CE => sync, Q   => db(11) );
i_fd_db12: FDE port map( C => clk2x, D => dataint(12),CE => sync, Q   => db(12) );
i_fd_db13: FDE port map( C => clk2x, D => dataint(13),CE => sync, Q   => db(13) );
i_fd_db14: FDE port map( C => clk2x, D => dataint(14),CE => sync, Q   => db(14) );
i_fd_db15: FDE port map( C => clk2x, D => dataint(15),CE => sync, Q   => db(15) );
i_fd_db16: FDE port map( C => clk2x, D => dataint(16),CE => sync, Q   => db(16) );
i_fd_db17: FDE port map( C => clk2x, D => dataint(17),CE => sync, Q   => db(17) );
i_fd_db18: FDE port map( C => clk2x, D => dataint(18),CE => sync, Q   => db(18) );
i_fd_db19: FDE port map( C => clk2x, D => dataint(19),CE => sync, Q   => db(19) );
i_fd_db20: FDE port map( C => clk2x, D => dataint(20),CE => sync, Q   => db(20) );
i_fd_db21: FDE port map( C => clk2x, D => dataint(21),CE => sync, Q   => db(21) );
i_fd_db22: FDE port map( C => clk2x, D => dataint(22),CE => sync, Q   => db(22) );
i_fd_db23: FDE port map( C => clk2x, D => dataint(23),CE => sync, Q   => db(23) );
i_fd_db24: FDE port map( C => clk2x, D => dataint(24),CE => sync, Q   => db(24) );
i_fd_db25: FDE port map( C => clk2x, D => dataint(25),CE => sync, Q   => db(25) );
i_fd_db26: FDE port map( C => clk2x, D => dataint(26),CE => sync, Q   => db(26) );
i_fd_db27: FDE port map( C => clk2x, D => dataint(27),CE => sync, Q   => db(27) );
i_fd_db28: FDE port map( C => clk2x, D => dataint(28),CE => sync, Q   => db(28) );
i_fd_db29: FDE port map( C => clk2x, D => dataint(29),CE => sync, Q   => db(29) );


mux   <= db(14 downto  0) when sync = '0' else
         db(29 downto 15);



i_fd_out0 : FD port map( C => clk2x, D => mux(0 ), Q => dataout(0 ) );
i_fd_out1 : FD port map( C => clk2x, D => mux(1 ), Q => dataout(1 ) );
i_fd_out2 : FD port map( C => clk2x, D => mux(2 ), Q => dataout(2 ) );
i_fd_out3 : FD port map( C => clk2x, D => mux(3 ), Q => dataout(3 ) );
i_fd_out4 : FD port map( C => clk2x, D => mux(4 ), Q => dataout(4 ) );
i_fd_out5 : FD port map( C => clk2x, D => mux(5 ), Q => dataout(5 ) );
i_fd_out6 : FD port map( C => clk2x, D => mux(6 ), Q => dataout(6 ) );
i_fd_out7 : FD port map( C => clk2x, D => mux(7 ), Q => dataout(7 ) );
i_fd_out8 : FD port map( C => clk2x, D => mux(8 ), Q => dataout(8 ) );
i_fd_out9 : FD port map( C => clk2x, D => mux(9 ), Q => dataout(9 ) );
i_fd_out10: FD port map( C => clk2x, D => mux(10), Q => dataout(10) );
i_fd_out11: FD port map( C => clk2x, D => mux(11), Q => dataout(11) );
i_fd_out12: FD port map( C => clk2x, D => mux(12), Q => dataout(12) );
i_fd_out13: FD port map( C => clk2x, D => mux(13), Q => dataout(13) );
i_fd_out14: FD port map( C => clk2x, D => mux(14), Q => dataout(14) );


end rtl;
