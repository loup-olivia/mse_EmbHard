-------------------------------------------------------------------------------
-- HES-SO Master, projet du cours de EmbHard 
--
-- File         : GPIO.vhd
-- Description  : The file contain a implementation of a GPIO component
--                
--
-- Author       : KENZI Antonin, LOUP Olivia (modification)
-- Date         : 16.10.2024
-- Version      : 1.2
--
-- Dependencies : None
--
--| Modifications |------------------------------------------------------------
-- Version   Author Date               Description
-- 1.0       AKI    3.10.2024          Creation of the file
-- 1.1       AKI    11.10.2024         Finish and tested 
-- 1.2		 LOO 	  16.10.2024			Recuperation of program	
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY ParallelPort IS
 GENERIC(N : NATURAL := 32);
 PORT(
	-- Avalon interfaces signals
		Clk : IN std_logic;
		nReset : IN std_logic;
		Address : IN std_logic_vector (2 DOWNTO 0);
		ChipSelect : IN std_logic;
		Read : IN std_logic;
		Write : IN std_logic;
		WriteData : IN std_logic_vector (N-1 DOWNTO 0);
		
		ReadData: OUT std_logic_vector (N-1 DOWNTO 0);
	-- Parallel Port external interface
		ParPort : INOUT std_logic_vector (N-1 DOWNTO 0)
	);
End ParallelPort;

ARCHITECTURE comp OF ParallelPort IS
    -- Déclaration of the signals,components,types and procedures
    -- Components (Nomenclature : name of the component + _c)
    -- Types (Nomenclature : name of the type + _t)
    -- exemple : type state_t is (idle, start, stop);
	
    -- Signals (Nomenclature : name of the signal + _s)
    -- exemple : signal a : signed(N_bit-1 downto 0);
    signal iRegDir_s : std_logic_vector (N-1 DOWNTO 0);
	 
    signal iRegPort_s : std_logic_vector (N-1 DOWNTO 0);
	 
    signal iRegPin_s : std_logic_vector (N-1 DOWNTO 0);
    -- Procedures (Nomenclature : name of the procedure + _p)

begin
    -- Declarations
    -- Process
    
	pRegWr : 
	process(Clk, nReset)
	begin
	  if nReset='0' then
			iRegDir_s <= (others => '0');
			iRegPort_s <= (others => '0');
	  elsif rising_edge(Clk) then
			if ChipSelect = '1' and Write = '1' then -- Write cycle
				case Address(2 downto 0) is
					when "000" => iRegDir_s <= WriteData ;
					when "010" => iRegPort_s <= WriteData;
					when "011" => iRegPort_s <= iRegPort_s OR WriteData;
					when "100" => iRegPort_s <= iRegPort_s AND NOT WriteData;
					when others => null;
				end case;
			end if; 
	  end if; 
	end process pRegWr;
 
	pRegRd: 
	process(Clk)
	begin
		if rising_edge(Clk) then
			ReadData <= (others => '0'); -- default value
			if ChipSelect = '1' and Read = '1' then -- Read cycle
				case Address(2 downto 0) is
					when "000" => ReadData <= iRegDir_s ;
					when "001" => ReadData <= iRegPin_s;
					when "010" => ReadData <= iRegPort_s;
					when others => null;
				end case;
			end if;
		end if;
	end process pRegRd;
    
	-- Parallel Port output value
	pPort:process(iRegDir_s, iRegPort_s)
		begin
			for i in 0 to N-1 loop
				if iRegDir_s(i) = '1' then
					ParPort(i) <= iRegPort_s(i);
				else
					ParPort(i) <= 'Z';
				end if;
		end loop;
	end process pPort;
	-- Parallel Port Input value
	iRegPin_s <= ParPort;
END comp;
