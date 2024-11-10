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

		avalon_waitRequest_i		: OUT std_logic;
	-- Master DMA interface 
		master_address_i 			: IN std_logic_vector (2 DOWNTO 0);
		master_read_i				: IN std_logic;
		master_RD_o					: OUT std_logic;
	
		master_waitRequest_i		: IN std_logic;
	-- IRQ gen
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
		type state_lcd_t is (IDLE, S1, S2, S3, S4);
		type state_ctrl_t is (MASTER_IDLE, MASTER_S1, MASTER_S2, MASTER_S3, MASTER_WAITREQUEST);
    -- Signals (Nomenclature : name of the signal + _s)
    -- exemple : signal a : signed(N_bit-1 downto 0);
	-- master
		signal state_ctrl_pres_s	: state_ctrl_t;
		signal state_ctrl_fut_s		: state_ctrl_t;

		signal reg_size_s			: std_logic_vector (31 DOWNTO 0);
		signal reg_status_s			: std_logic_vector (31 DOWNTO 0);
		signal reg_cnt_s			: std_logic_vector (31 DOWNTO 0);
		signal start_DMA_s			: std_logic;
		signal IRQ_s				: std_logic;
		signal pointer_reg_s		: std_logic_vector (31 DOWNTO 0);
	-- slave Avalon
		signal waitrequest_s		: std_logic;

	-- lcd ctrl
		signal DB_pres_s 		: std_logic_vector (N-1 DOWNTO 0);
		signal DB_fut_s 		: std_logic_vector (N-1 DOWNTO 0);
		
		signal DCn_pres_s 		: std_logic; 
		signal DCn_fut_s 		: std_logic; 
		signal state_lcd_pres_s 	: state_lcd_t;
		signal state_lcd_fut_s 	: state_lcd_t;
		signal start_lcd_s		: std_logic;
		signal start_lcd_DMA_s		: std_logic;

		signal WRn_pres_s		: std_logic;
		signal WRn_fut_s		: std_logic;
    -- Procedures (Nomenclature : name of the procedure + _p)

begin
    -- Declarations
    -- Process
    -- Avalon & Master W/R ====================================================
	RegWR_slave_p : 
	process(Clk_i, nReset_i)
	begin
	  if nReset_i ='0' then
		statePres_s <= IDLE;
		DBreg_s <= (others => '0');
		DCn_s <= '0';
	  elsif rising_edge(Clk_i) then

			state_ctrl_pres_s <= state_ctrl_fut_s;
			
			-- Write cycle
			if avalon_CS_i = '1' and avalon_Write_i = '1' then 
				case avalon_Address_i(2 downto 0) is
					when "010" => pointer_reg_s <= avalon_WD_i ;
					when "011" => reg_size_s <= avalon_WD_i;
					when "100" => 
					start_DMA_s <= avalon_WD_i(0);
					IRQ_s <= avalon_WD_i(2);
					when others => null;
				end case;
			end if;
			-- read 
			case avalon_Address_i(2 downto 0) is
				when "010" => avalon_RD_o <= pointer_reg_s;
				when "011" => avalon_RD_o <= reg_size_s;
				when "101" => avalon_RD_o <= reg_status_s;
				when "110" => avalon_RD_o <= reg_cnt_s;
				when others => null;
			end case;

	  end if; 
	end process RegWR_slave_p;
	-- State machine DMA ======================================================
		-- Process
		process(Clk)
		begin
			if rising_edge(Clk) then
				if state_ctrl_pres_s <= MASTER_IDLE then
					reg_cnt_s <= pointer_reg_s;
				elsif state_ctrl_pres_s <= MASTER_S3 then
					reg_cnt_s <= std_logic(unsigned(reg_cnt_s) + '2')
				end if
				
			end if;
		-- signal
		state_ctrl_fut_s <= state_ctrl_pres_s;
		waitrequest_s <= '1';
		case state_ctrl_pres_s is
			when MASTER_IDLE => 
				if avalon_CS_i = '1' and avalon_Write_i = '1' then 
					state_ctrl_fut_s <= MASTER_S1;
				end if;
			when MASTER_S1 => 
				state_ctrl_fut_s <= MASTER_S2;
				
			when MASTER_S2 =>
				state_ctrl_fut_s <= MASTER_S3;

			when MASTER_S3 =>
				state_ctrl_fut_s <= MASTER_WAITREQUEST;

			when MASTER_WAITREQUEST =>
				state_ctrl_fut_s <= MASTER_IDLE;				
			when others => 
			avalon_CS_i <= '0'
			avalon_Write_i <= '0';
		end case;
	StateMa_p: 
	process(ChipSelect_i,Write_i,statePres_s)
	begin
	-- LCD ctrl ===============================================================
	RegWrite_p : 
	process(Clk_i, nReset_i)
	begin
	  if nReset_i ='0' then
		state_lcd_pres_s <= IDLE;
		DB_pres_s <= (others => '0');
		DCn_pres_s <= '0';
	  elsif rising_edge(Clk_i) then
		state_lcd_pres_s <= state_lcd_fut_s;
			
		DCn_pres_s <= DCn_fut_s;
		DB_pres_s <= DB_fut_s;
		
		LCD_CS_o <= avalon_CS_i;
		LCD_WRn_o <= avalon_Write_i;
		
		case state_addr_s is
			when S1 => 
				
			when S2 => 
				
			when S3 => 
				
			when others => 

		end case;

	  end if; 
	end process RegWrite_p;
END comp;