----------------------------------------------------------------------------
--  enc_tmds_pipe.vhd
--	Pipelined TMDS Encoder
--	Version 1.1
--
--  Copyright (C) 2014 R.Tursen
--
--	This program is free software: you can redistribute it and/or
--	modify it under the terms of the GNU General Public License
--	as published by the Free Software Foundation, either version
--	2 of the License, or (at your option) any later version.
----------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity encode is
    port(
	i_clk	 : in  std_logic;
	i_data	 : in  std_logic_vector(7 downto 0);
	i_audio	 : in  std_logic_vector(3 downto 0);
	i_cntrl	 : in  std_logic_vector(1 downto 0);

	i_vid_de : in  std_logic;
	i_aud_de : in  std_logic;

	o_data	 : out std_logic_vector(9 downto 0)
    );
end encode;


architecture RTL of encode is

    constant EIGHT	: unsigned (3 downto 0) := "1000";

    signal data_p1	: std_logic_vector (7 downto 0);
    signal data_p2	: std_logic_vector (7 downto 0);
    signal data_p3	: std_logic_vector (7 downto 0);
    signal data_p4	: std_logic_vector (7 downto 0);
    signal data_p5	: std_logic_vector (7 downto 0);

    signal sum1_8a_p2	: unsigned (2 downto 0);
    signal sum1_8b_p2	: unsigned (2 downto 0);
    signal sum1_8a_p3	: unsigned (2 downto 0);
    signal sum1_8b_p3	: unsigned (2 downto 0);
    signal sum1_p3	: unsigned (3 downto 0);
    signal sum1_p4	: unsigned (3 downto 0);
    signal select1_p4	: std_logic := '0';
    signal select1_p5	: std_logic := '0';

    signal word8a_p5	: std_logic_vector (8 downto 0);
    signal word8b_p5	: std_logic_vector (8 downto 0);
    signal word8_p6	: std_logic_vector (8 downto 0);
    signal word8_p7	: std_logic_vector (8 downto 0);
    signal word8_p8	: std_logic_vector (8 downto 0);
    signal word8_p9	: std_logic_vector (8 downto 0);
    signal word8_p10	: std_logic_vector (8 downto 0);
    signal word8_p11	: std_logic_vector (8 downto 0);
    signal word8_p12	: std_logic_vector (8 downto 0);
    signal word8_p13	: std_logic_vector (8 downto 0);
    signal word8_p14	: std_logic_vector (8 downto 0);
    signal word8_p15	: std_logic_vector (8 downto 0);
    signal word8_p16	: std_logic_vector (8 downto 0);

    signal sum1a_p7		: unsigned (2 downto 0);
    signal sum1b_p7		: unsigned (2 downto 0);
    signal sum1a_p8		: unsigned (2 downto 0);
    signal sum1b_p8		: unsigned (2 downto 0);
    signal sum1_p8		: unsigned (3 downto 0);
    signal sum1_p9		: unsigned (3 downto 0);
    signal sum1_p10		: unsigned (3 downto 0);
    signal sum0_p9		: unsigned (3 downto 0);
    signal sum0_p10		: unsigned (3 downto 0);
    signal sum1_p11		: unsigned (3 downto 0);
    signal sum0_p11		: unsigned (3 downto 0);
    signal sum1_clone_p11	: unsigned (3 downto 0);
    signal sum0_clone_p11	: unsigned (3 downto 0);

    signal ones_gt_zeros_p11	: std_logic;
    signal ones_eq_zeros_p11	: std_logic;
    signal ones_gt_zeros_p12	: std_logic;
    signal ones_eq_zeros_p12	: std_logic;
    signal ones_gt_zeros_p13	: std_logic;
    signal ones_eq_zeros_p13	: std_logic;

    signal excess_ones_p11	: signed (4 downto 0);
    signal excess_zeros_p11	: signed (4 downto 0);
    signal mult2_p11		: signed (4 downto 0);
    signal mult2_cmpl_p11	: signed (4 downto 0);
    signal excess_ones_p12	: signed (4 downto 0);
    signal excess_zeros_p12	: signed (4 downto 0);
    signal mult2_p12		: signed (4 downto 0);
    signal mult2_cmpl_p12	: signed (4 downto 0);

    signal dc_bias_pre_a_p12	: signed (5 downto 0);
    signal dc_bias_pre_b_p12	: signed (5 downto 0);
    signal dc_bias_pre_c_p12	: signed (5 downto 0);
    signal dc_bias_pre_d_p12	: signed (5 downto 0);

    signal dc_bias_pre_a_p13	: signed (5 downto 0);
    signal dc_bias_pre_b_p13	: signed (5 downto 0);
    signal dc_bias_pre_c_p13	: signed (5 downto 0);
    signal dc_bias_pre_d_p13	: signed (5 downto 0);

    signal dc_bias_a_p13	: signed (6 downto 0);
    signal dc_bias_b_p13	: signed (6 downto 0);
    signal dc_bias_c_p13	: signed (6 downto 0);
    signal dc_bias_d_p13	: signed (6 downto 0);

    signal dc_bias_p13		: signed (6 downto 0);

    signal dc_bias_zero_p13	: std_logic := '0';
    signal dc_bias_pos_p13	: std_logic := '0';
    signal dc_bias_neg_p13	: std_logic := '0';
    signal select2_p13		: std_logic := '0';
    signal select3_p13		: std_logic := '0';
    signal select2_p14		: std_logic := '0';
    signal select3_p14		: std_logic := '0';

    signal word9_a_p14		: std_logic_vector (9 downto 0);
    signal word9_b_p14		: std_logic_vector (9 downto 0);
    signal word9_c_p14		: std_logic_vector (9 downto 0);
    signal word9_d_p14		: std_logic_vector (9 downto 0);
    signal word9_p15		: std_logic_vector (9 downto 0);
    signal video9_p16		: std_logic_vector (9 downto 0);

    signal vid_de	: std_logic_vector (17 downto 0);
    signal aud_de	: std_logic_vector (17 downto 0);
    signal audio_d1	: std_logic_vector ( 3 downto 0);
    signal audio_d2	: std_logic_vector ( 3 downto 0);
    signal audio_d3	: std_logic_vector ( 3 downto 0);
    signal audio_d4	: std_logic_vector ( 3 downto 0);
    signal audio_d5	: std_logic_vector ( 3 downto 0);
    signal audio_d6	: std_logic_vector ( 3 downto 0);
    signal audio_d7	: std_logic_vector ( 3 downto 0);
    signal audio_d8	: std_logic_vector ( 3 downto 0);
    signal audio_d9	: std_logic_vector ( 3 downto 0);
    signal audio_d10	: std_logic_vector ( 3 downto 0);
    signal audio_d11	: std_logic_vector ( 3 downto 0);
    signal audio_d12	: std_logic_vector ( 3 downto 0);
    signal audio_d13	: std_logic_vector ( 3 downto 0);
    signal audio_d14	: std_logic_vector ( 3 downto 0);
    signal audio_d15	: std_logic_vector ( 3 downto 0);
    signal audio_d16	: std_logic_vector ( 3 downto 0);

    signal cntrl_d1	: std_logic_vector ( 1 downto 0);
    signal cntrl_d2	: std_logic_vector ( 1 downto 0);
    signal cntrl_d3	: std_logic_vector ( 1 downto 0);
    signal cntrl_d4	: std_logic_vector ( 1 downto 0);
    signal cntrl_d5	: std_logic_vector ( 1 downto 0);
    signal cntrl_d6	: std_logic_vector ( 1 downto 0);
    signal cntrl_d7	: std_logic_vector ( 1 downto 0);
    signal cntrl_d8	: std_logic_vector ( 1 downto 0);
    signal cntrl_d9	: std_logic_vector ( 1 downto 0);
    signal cntrl_d10	: std_logic_vector ( 1 downto 0);
    signal cntrl_d11	: std_logic_vector ( 1 downto 0);
    signal cntrl_d12	: std_logic_vector ( 1 downto 0);
    signal cntrl_d13	: std_logic_vector ( 1 downto 0);
    signal cntrl_d14	: std_logic_vector ( 1 downto 0);
    signal cntrl_d15	: std_logic_vector ( 1 downto 0);
    signal cntrl_d16	: std_logic_vector ( 1 downto 0);

    signal audio9_p15	: std_logic_vector (9 downto 0);
    signal audio9_p16	: std_logic_vector (9 downto 0);
    signal cntrl9_p15	: std_logic_vector (9 downto 0);
    signal cntrl9_p16	: std_logic_vector (9 downto 0);
    signal data		: std_logic_vector (9 downto 0);

begin

    -- cycle 1,2,3,4,5
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    data_p1 <= i_data;
	    data_p2 <= data_p1;
	    data_p3 <= data_p2;
	    data_p4 <= data_p3;
	    data_p5 <= data_p4;
	end if;
    end process;

    -- sum1_8b_p2 <= unsigned("00" & data_p2(0)) +
    --		  unsigned("00" & data_p2(1)) +
    --		  unsigned("00" & data_p2(2)) +
    --		  unsigned("00" & data_p2(3));

    -- sum1_8b_p2 <= unsigned("00" & data_p2(4)) +
    --		  unsigned("00" & data_p2(5)) +
    --		  unsigned("00" & data_p2(6)) +
    --		  unsigned("00" & data_p2(7));

    sum1_8a_p2 <= resize(('0' & data_p2(0)), sum1_8a_p2'length) +
		  resize(('0' & data_p2(1)), sum1_8a_p2'length) +
		  resize(('0' & data_p2(2)), sum1_8a_p2'length) +
		  resize(('0' & data_p2(3)), sum1_8a_p2'length);

    sum1_8b_p2 <= resize(('0' & data_p2(4)), sum1_8b_p2'length) +
		  resize(('0' & data_p2(5)), sum1_8b_p2'length) +
		  resize(('0' & data_p2(6)), sum1_8b_p2'length) +
		  resize(('0' & data_p2(7)), sum1_8b_p2'length);

    -- cycle 3
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    sum1_8a_p3 <= sum1_8a_p2;
	    sum1_8b_p3 <= sum1_8b_p2;
	end if;
    end process;

    -- 4bits, since 8 can't be represented with 3 bits
    sum1_p3 <= ('0' & sum1_8a_p3) + ('0' & sum1_8b_p3);

    -- cycle 4
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    sum1_p4 <= sum1_p3;
	end if;
    end process;

    select1_p4 <= '1' when sum1_p4 > "0100" or
	(sum1_p4 = "0100" and data_p4(0) = '0')
	else '0';

    -- cycle 5
    -- Select1_r aligns with data_p5
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    select1_p5 <= select1_p4;
	end if;
    end process;

    word8a_p5(0) <= data_p5(0);
    word8a_p5(1) <= word8a_p5(0) xor data_p5(1);
    word8a_p5(2) <= word8a_p5(1) xor data_p5(2);
    word8a_p5(3) <= word8a_p5(2) xor data_p5(3);
    word8a_p5(4) <= word8a_p5(3) xor data_p5(4);
    word8a_p5(5) <= word8a_p5(4) xor data_p5(5);
    word8a_p5(6) <= word8a_p5(5) xor data_p5(6);
    word8a_p5(7) <= word8a_p5(6) xor data_p5(7);
    word8a_p5(8) <= '1';

    word8b_p5(0) <= data_p5(0);
    word8b_p5(1) <= word8b_p5(0) xnor data_p5(1);
    word8b_p5(2) <= word8b_p5(1) xnor data_p5(2);
    word8b_p5(3) <= word8b_p5(2) xnor data_p5(3);
    word8b_p5(4) <= word8b_p5(3) xnor data_p5(4);
    word8b_p5(5) <= word8b_p5(4) xnor data_p5(5);
    word8b_p5(6) <= word8b_p5(5) xnor data_p5(6);
    word8b_p5(7) <= word8b_p5(6) xnor data_p5(7);
    word8b_p5(8) <= '0';

    -- cycle 6
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    if select1_p5 = '1' then
		word8_p6 <= word8b_p5;
	    else
		word8_p6 <= word8a_p5;
	    end if;
	end if;
    end process;

    -- cycle 7
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    word8_p7  <= word8_p6;
	    word8_p8  <= word8_p7;
	    word8_p9  <= word8_p8;
	    word8_p10 <= word8_p9;
	    word8_p11 <= word8_p10;
	    word8_p12 <= word8_p11;
	    word8_p13 <= word8_p12;
	    word8_p14 <= word8_p13;
	    word8_p15 <= word8_p14;
	    word8_p16 <= word8_p15;
	end if;
    end process;

    sum1a_p7 <= resize('0' & word8_p7(0), sum1a_p7'length) +
		resize('0' & word8_p7(1), sum1a_p7'length) +
		resize('0' & word8_p7(2), sum1a_p7'length) +
		resize('0' & word8_p7(3), sum1a_p7'length);

    sum1b_p7 <= resize('0' & word8_p7(4), sum1b_p7'length) +
		resize('0' & word8_p7(5), sum1b_p7'length) +
		resize('0' & word8_p7(6), sum1b_p7'length) +
		resize('0' & word8_p7(7), sum1b_p7'length);

    -- cycle 8
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    sum1a_p8 <= sum1a_p7;
	    sum1b_p8 <= sum1b_p7;
	end if;
    end process;

    sum1_p8 <= unsigned('0' & sum1a_p8) + unsigned('0' & sum1b_p8);

    -- cycle 9,10
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    sum1_p9 <= sum1_p8;
	    sum1_p10 <= sum1_p9;
	end if;
    end process;

    sum0_p9 <= EIGHT - unsigned(sum1_p9);

    -- cycle 10
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    sum0_p10 <= sum0_p9;
	end if;
    end process;

    -- cycle 11
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    sum1_p11 <= sum1_p10;
	    sum0_p11 <= sum0_p10;

	    sum1_clone_p11 <= sum1_p10;
	    sum0_clone_p11 <= sum0_p10;
	end if;
    end process;

    ones_gt_zeros_p11 <= '1'
	when sum1_p11 > sum0_p11 else '0';

    ones_eq_zeros_p11 <= '1'
	when sum1_p11 = sum0_p11 else '0';


    excess_ones_p11 <= signed('0' & sum1_clone_p11) -
	signed('0' & sum0_clone_p11);		-- 5 bits
    excess_zeros_p11 <= signed('0' & sum0_clone_p11) -
	signed('0' & sum1_clone_p11);

    mult2_p11      <= "000" &     word8_p11(8) & '0';
    mult2_cmpl_p11 <= "000" & not word8_p11(8) & '0';

    -- cycle 12 releated
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    excess_ones_p12  <= excess_ones_p11;
	    excess_zeros_p12 <= excess_zeros_p11;
	    mult2_p12	   <= mult2_p11;
	    mult2_cmpl_p12   <= mult2_cmpl_p11;

	    ones_eq_zeros_p12     <= ones_eq_zeros_p11;
	    ones_gt_zeros_p12 <= ones_gt_zeros_p11;
	end if;
    end process;

    dc_bias_pre_a_p12 <=
	resize(excess_ones_p12, dc_bias_pre_a_p12'length) -
	resize(mult2_cmpl_p12, dc_bias_pre_a_p12'length);
    dc_bias_pre_b_p12 <=
	resize(excess_zeros_p12, dc_bias_pre_b_p12'length) +
	resize(mult2_p12, dc_bias_pre_b_p12'length);
    dc_bias_pre_c_p12 <=
	resize(excess_zeros_p12, dc_bias_pre_c_p12'length);
    dc_bias_pre_d_p12 <=
	resize(excess_ones_p12, dc_bias_pre_d_p12'length);

    -- cycle 13
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    dc_bias_pre_a_p13 <= dc_bias_pre_a_p12;
	    dc_bias_pre_b_p13 <= dc_bias_pre_b_p12;
	    dc_bias_pre_c_p13 <= dc_bias_pre_c_p12;
	    dc_bias_pre_d_p13 <= dc_bias_pre_d_p12;

	    ones_eq_zeros_p13 <= ones_eq_zeros_p12;
	    ones_gt_zeros_p13 <= ones_gt_zeros_p12;
	end if;
    end process;

    dc_bias_a_p13 <= dc_bias_p13 +
	resize(dc_bias_pre_a_p13, dc_bias_a_p13'length);
    dc_bias_b_p13 <= dc_bias_p13 +
	resize(dc_bias_pre_b_p13, dc_bias_b_p13'length);
    dc_bias_c_p13 <= dc_bias_p13 +
	resize(dc_bias_pre_c_p13, dc_bias_c_p13'length);
    dc_bias_d_p13 <= dc_bias_p13 +
	resize(dc_bias_pre_d_p13, dc_bias_d_p13'length);

    dc_bias_zero_p13 <=
	'1' when dc_bias_p13 = to_signed(0, 7) else '0';
    dc_bias_pos_p13 <= not dc_bias_p13(6);
    dc_bias_neg_p13 <= dc_bias_p13(6);

    select2_p13 <= dc_bias_zero_p13 or ones_eq_zeros_p13;

    select3_p13 <= (dc_bias_pos_p13 and	 ones_gt_zeros_p13) or
		   (dc_bias_neg_p13 and not ones_gt_zeros_p13);

    -- cycle 14
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    if vid_de(14) = '1' then
		if select2_p13 = '1' then
		    if word8_p13(8) = '0' then
			dc_bias_p13 <= dc_bias_c_p13;
		    else
			dc_bias_p13 <= dc_bias_d_p13;
		    end if;
		else
		    if select3_p13 = '1' then
			dc_bias_p13 <= dc_bias_b_p13;
		    else
			dc_bias_p13 <= dc_bias_a_p13;
		    end if;
		end if;
	    else
		dc_bias_p13 <= (others => '0');
	    end if;
	end if;
    end process;

    -- cycle 14
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    select2_p14 <= select2_p13;
	    select3_p14 <= select3_p13;
	end if;
    end process;

    -- cycle 15
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    if select2_p14 = '1' then
		if word8_p14(8) = '1' then
		    word9_p15 <= word9_c_p14;
		else
		    word9_p15 <= word9_d_p14;
		end if;
	    else
		if select3_p14 = '1' then
		    word9_p15 <= word9_b_p14;
		else
		    word9_p15 <= word9_a_p14;
		end if;
	    end if;
	end if;
    end process;

    word9_a_p14(9) <= '0';
    word9_a_p14(8) <= word8_p14(8);
    word9_a_p14(7 downto 0) <= word8_p14(7 downto 0);

    word9_b_p14(9) <= '1';
    word9_b_p14(8) <= word8_p14(8);
    word9_b_p14(7 downto 0) <= not word8_p14(7 downto 0);

    word9_c_p14(9) <= not word8_p14(8);
    word9_c_p14(8) <= word8_p14(8);
    word9_c_p14(7 downto 0) <= word8_p14(7 downto 0);

    word9_d_p14(9) <= not word8_p14(8);
    word9_d_p14(8) <= word8_p14(8);
    word9_d_p14(7 downto 0) <= not word8_p14(7 downto 0);

    ---------------------------

    -- delay line for video9_p16 de
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    vid_de(0) <= i_vid_de;

	    for I in 0 to 16 loop
		vid_de(I + 1) <= vid_de(I);
	    end loop;
	end if;
    end process;

    -- delay line for audio9_p16 de
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    aud_de(0) <= i_aud_de;

	    for I in 0 to 16 loop
		aud_de(I + 1) <= aud_de(I);
	    end loop;
	end if;
    end process;

    -- delay line for audio9_p16 data
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    audio_d1  <= i_audio;
	    audio_d2  <= audio_d1;
	    audio_d3  <= audio_d2;
	    audio_d4  <= audio_d3;
	    audio_d5  <= audio_d4;
	    audio_d6  <= audio_d5;
	    audio_d7  <= audio_d6;
	    audio_d8  <= audio_d7;
	    audio_d9  <= audio_d8;
	    audio_d10 <= audio_d9;
	    audio_d11 <= audio_d10;
	    audio_d12 <= audio_d11;
	    audio_d13 <= audio_d12;
	    audio_d14 <= audio_d13;
	    audio_d15 <= audio_d14;
	end if;
    end process;

    -- delay line for cntrl9_p16 data
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    cntrl_d1  <= i_cntrl;
	    cntrl_d2  <= cntrl_d1;
	    cntrl_d3  <= cntrl_d2;
	    cntrl_d4  <= cntrl_d3;
	    cntrl_d5  <= cntrl_d4;
	    cntrl_d6  <= cntrl_d5;
	    cntrl_d7  <= cntrl_d6;
	    cntrl_d8  <= cntrl_d7;
	    cntrl_d9  <= cntrl_d8;
	    cntrl_d10 <= cntrl_d9;
	    cntrl_d11 <= cntrl_d10;
	    cntrl_d12 <= cntrl_d11;
	    cntrl_d13 <= cntrl_d12;
	    cntrl_d14 <= cntrl_d13;
	    cntrl_d15 <= cntrl_d14;
	end if;
    end process;

    audio9_p15 <=
	"1010011100" when audio_d15 = "0000" else
	"1001100011" when audio_d15 = "0001" else
	"1011100100" when audio_d15 = "0010" else
	"1011100010" when audio_d15 = "0011" else
	"0101110001" when audio_d15 = "0100" else
	"0100011110" when audio_d15 = "0101" else
	"0110001110" when audio_d15 = "0110" else
	"0100111100" when audio_d15 = "0111" else
	"1011001100" when audio_d15 = "1000" else
	"0100111001" when audio_d15 = "1001" else
	"0110011100" when audio_d15 = "1010" else
	"1011000110" when audio_d15 = "1011" else
	"1010001110" when audio_d15 = "1100" else
	"1001110001" when audio_d15 = "1101" else
	"0101100011" when audio_d15 = "1110" else
	"1011000011" when audio_d15 = "1111" else
	"0000000000";

    cntrl9_p15 <=
	"1101010100"  when cntrl_d15 = "00" else
	"0010101011"  when cntrl_d15 = "01" else
	"0101010100"  when cntrl_d15 = "10" else
	"1010101011"  when cntrl_d15 = "11" else
	"0000000000";

    -- should be cycle 16
    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    video9_p16 <= word9_p15;
	    audio9_p16 <= audio9_p15;
	    cntrl9_p16 <= cntrl9_p15;
	end if;
    end process;

    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    if vid_de(15) = '1' then
		data <= video9_p16;
	    elsif aud_de(15) = '1' then
		data <= audio9_p16;
	    else
		data <= cntrl9_p16;
	    end if;
	end if;
    end process;

    process (i_clk)
    begin
	if rising_edge(i_clk) then
	    o_data <= data;
	end if;
    end process;

end RTL;

