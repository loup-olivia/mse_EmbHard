-------------------------------------------------------------------------------
-- HES-SO Master, projet du cours de EmbHard 
--
-- File         : int_LCD_DMA.vhd
-- Description  : The file contain a implementation of a LCD interface
--                
--
-- Author       : LOUP Olivia
-- Date         : 29.10.2024
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

		Clk_i 						: IN std_logic;
		nReset_i 					: IN std_logic;
	-- Avalon interfaces signals
		avalon_Address_i 			: IN std_logic;
		avalon_CS_i 				: IN std_logic;
		avalon_Write_i 			: IN std_logic;
		avalon_WD_i 				: IN std_logic_vector (N-1 DOWNTO 0);
		avalon_read_i				: IN std_logic;
		avalon_RD_o					: OUT std_logic_vector (N-1 DOWNTO 0);
	-- Master DMA interface 
		master_address_i 			: IN std_logic_vector (2 DOWNTO 0);
		master_read_i				: IN std_logic;
		master_RD_o					: OUT std_logic;
	
		waitRequest_o				: OUT std_logic;
		end_of_transaction_irq	: OUT std_logic;
		
	-- 8080 interfaces
		-- CSn_o			: OUT std_logic;
		LCD_D_Cn_o					: OUT std_logic;
		LCD_DB_o						: OUT std_logic_vector (N-1 DOWNTO 0);
		LCD_WRn_o					: OUT std_logic;
		LCD_CS_o						: OUT std_logic
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
		type state_t is (IDLE, S1, S2, S3, S4);
		type state_addr_t is (s2,s3,s4);
    -- Signals (Nomenclature : name of the signal + _s)
    -- exemple : signal a : signed(N_bit-1 downto 0);
		signal DBreg_s 		: std_logic_vector (N-1 DOWNTO 0);
		signal DCn_s 		: std_logic;  
		signal statePres_s 	: state_t;
		signal stateFut_s 	: state_t;
		signal state_addr_s : state_addr_t;
    -- Procedures (Nomenclature : name of the procedure + _p)

begin
    -- Declarations
    -- Process
    -- Avalon bus
	RegWr_p : 
	process()
	begin
	  if nReset_i ='0' then
		statePres_s <= IDLE;
		DBreg_s <= (others => '0');
		DCn_s <= '0';
	  elsif rising_edge(Clk_i) then
			statePres_s <= stateFut_s;
			
			DCn_s <= avalon_Address_i;
			DBreg_s <= avalon_WD_i;
			
			LCD_CS_o <= avalon_CS_i;
			LCD_WRn_o <= avalon_Write_i;
			
			avalon_CS_i <= '1';
			avalon_Write_i <= '1';
			case state_addr_s is
				when s2 => 
					
				when s3 => 
					
				when s4 => 
					
				when others => 
				avalon_CS_i <= '0'
				avalon_Write_i <= '0';
			end case;

	  end if; 
	end process RegWr_p;
 
	StateMa_p: 
	process(ChipSelect_i,Write_i,statePres_s)
	begin

END comp;