-------------------------------------------------------------------------------
-- HES-SO Master, projet du cours de EmbHard 
--
-- File         : int_LCD.vhd
-- Description  : The file contain a implementation of a LCD interface
--                
--
-- Author       : LOUP Olivia
-- Date         : 23.10.2024
-- Version      : 1.0
--
-- Dependencies : None
--
--| Modifications |------------------------------------------------------------
-- Version   Author Date               Description
-- 1.0		 LOO 	  23.10.2024			Start of program
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY INT_LCD IS
 GENERIC(N : NATURAL := 16);
 PORT(
	-- Avalon interfaces signals
		Clk_i 			: IN std_logic;
		nReset_i 		: IN std_logic;
		Address_i 		: IN std_logic;
		ChipSelect_i 	: IN std_logic;
		Write_i 		: IN std_logic;
		WriteData_i 	: IN std_logic_vector (N-1 DOWNTO 0);
		
		waitRequest_o	: OUT std_logic;
		
	-- 8080 interfaces
		-- CSn_o			: OUT std_logic;
		D_Cn_o			: OUT std_logic;
		DB_o			: OUT std_logic_vector (N-1 DOWNTO 0);
		WRn_o			: OUT std_logic
		-- RD_n_o			: OUT std_logic;
		-- LCD_RESET_n_i	: OUT std_logic;
		-- IM0_i			: OUT std_logic;
	);
End INT_LCD;

ARCHITECTURE comp OF INT_LCD IS
    -- Déclaration of the signals,components,types and procedures
    -- Components (Nomenclature : name of the component + _c)
    -- Types (Nomenclature : name of the type + _t)
    -- exemple : type state_t is (idle, start, stop);
		type state_t is (IDLE, S1, S2, S3);
    -- Signals (Nomenclature : name of the signal + _s)
    -- exemple : signal a : signed(N_bit-1 downto 0);
    signal DBreg_s 		: std_logic_vector (N-1 DOWNTO 0);
	signal DCn_s 		: std_logic;  
	signal statePres_s 	: state_t;
	signal stateFut_s 	: state_t;
    -- Procedures (Nomenclature : name of the procedure + _p)

begin
    -- Declarations
    -- Process
    -- Avalon bus
	RegWr_p : 
	process(Clk_i,nReset_i)
	begin
	  if nReset_i ='0' then
		statePres_s <= IDLE;
		DBreg_s <= (others => '0');
		DCn_s <= '0';
	  elsif rising_edge(Clk_i) then
			statePres_s <= stateFut_s;
			DCn_s <= Address_i;
			DBreg_s <= WriteData_i;

	  end if; 
	end process RegWr_p;
 
	StateMa_p: 
	process(ChipSelect_i,Write_i,statePres_s)
	begin
		WRn_o <= '1';
		waitRequest_o <= '1';
		stateFut_s <= statePres_s;
		case statePres_s is
			when IDLE =>
				if (ChipSelect_i <= '1' and Write_i <= '1') then
					stateFut_s <= S1;
				end if;
			when S1 =>
				WRn_o <= '0';
				stateFut_s <= S2;
			when S2 =>
				stateFut_s <= S3; 
			when S3 =>
				waitRequest_o <= '0';
				stateFut_s <= IDLE;
			when others => 
				stateFut_s <= IDLE;
		end case;
	end process ;
    
	-- 8080
	-- CSn_o			<= '0';
	D_Cn_o			<= DCn_s;
	DB_o			<= DBreg_s;
	-- WRn_o			<= '0';
	-- RD_n_o		<= '0';
	-- LCD_RESET_n_i	<= nReset_i;
	-- IM0_i			<= '0';
END comp;
