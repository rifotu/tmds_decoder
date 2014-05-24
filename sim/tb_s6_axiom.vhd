------------------------------------------------------------------------------
-- Copyright (c) 2009 Xilinx, Inc.
-- This design is confidential and proprietary of Xilinx, All Rights Reserved.
------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor: Xilinx
-- \   \   \/    Version: 1.0
--  \   \        Filename: tb_s6_axiom.vhd
--  /   /        Date Last Modified:  November 5 2009
-- /___/   /\    Date Created: June 1 2009
-- \   \  /  \
--  \___\/\___\
-- 
--Device: 	Spartan 6
--Purpose:  	Test Bench
--Reference:
--    
--Revision History:
--    Rev 1.0 - First created (nicks)
--
------------------------------------------------------------------------------
--
--  Disclaimer: 
--
--		This disclaimer is not a license and does not grant any rights to the materials 
--              distributed herewith. Except as otherwise provided in a valid license issued to you 
--              by Xilinx, and to the maximum extent permitted by applicable law: 
--              (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL FAULTS, 
--              AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, 
--              INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT, OR 
--              FITNESS FOR ANY PARTICULAR PURPOSE; and (2) Xilinx shall not be liable (whether in contract 
--              or tort, including negligence, or under any other theory of liability) for any loss or damage 
--              of any kind or nature related to, arising under or in connection with these materials, 
--              including for any direct, or any indirect, special, incidental, or consequential loss 
--              or damage (including loss of data, profits, goodwill, or any type of loss or damage suffered 
--              as a result of any action brought by a third party) even if such damage or loss was 
--              reasonably foreseeable or Xilinx had been advised of the possibility of the same.
--
--  Critical Applications:
--
--		Xilinx products are not designed or intended to be fail-safe, or for use in any application 
--		requiring fail-safe performance, such as life-support or safety devices or systems, 
--		Class III medical devices, nuclear facilities, applications related to the deployment of airbags,
--		or any other applications that could lead to death, personal injury, or severe property or 
--		environmental damage (individually and collectively, "Critical Applications"). Customer assumes 
--		the sole risk and liability of any use of Xilinx products in Critical Applications, subject only 
--		to applicable laws and regulations governing limitations on product liability.
--
--  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
--
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all ;

library work;
use work.sub_module_components.all;


entity tb_s6_axiom is end tb_s6_axiom ;

architecture sim of tb_s6_axiom is


signal clkp 	   : std_logic := '0';
signal clkn        : std_logic := '1';
signal rst	   : std_logic := '1' ;
signal sys_error   : std_logic := '1' ;
signal datap 	   : std_logic_vector(5 downto 0) ;
signal datan 	   : std_logic_vector(5 downto 0) ;

signal board_clk   : std_logic := '0';

begin

board_clk <= not board_clk after 4 nS ;		-- local clock

rst <= '0' after 150 nS;




i_top_s6_axiom: top_s6_axiom 
port map(

       i_clk         => board_clk,   --   : in  std_logic;  -- clk from oscillator on board
       i_rst         => rst,         --   : in  std_logic;

       i_data_p      => datap, --   : in  std_logic_vector(5 downto 0);
       i_data_n      => datan, --   : in  std_logic_vector(5 downto 0);
  
       i_clk_p       => clkp, --   : in  std_logic;
       i_clk_n       => clkn, --   : in  std_logic;

       o_data_p      => datap, --   : out std_logic_vector(5 downto 0);
       o_data_n      => datan, --   : out std_logic_vector(5 downto 0);

       o_clk_p       => clkp, --   : out std_logic;
       o_clk_n       => clkn, --   : out std_logic;

       o_error       => sys_error  --   : out std_logic
);


end sim ;
