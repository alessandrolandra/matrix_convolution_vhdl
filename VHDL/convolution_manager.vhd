----------------------------------------------------------------------------------
-- Company: PoliTo
-- Engineer: Alessandro Landra
-- 
-- Create Date: 27.12.2020 17:15:20
-- Module Name: convolution_manager - Behavioral
-- Project Name: matrixConvolution
-- Description: entity responsible for feeding with the right addresses and data the matrixes_register_file
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity convolution_manager is
    PORT(load_m,load_k,compute,clk,rst: IN std_logic;         
         data_in: IN std_logic_vector(31 DOWNTO 0);
         data_out: OUT std_logic_vector(47 DOWNTO 0);
         rdy: OUT std_logic);
end convolution_manager;

architecture Behavioral of convolution_manager is
    COMPONENT matrices_register_file IS
        PORT(load_m,load_k,compute,clk,rst: IN std_logic;
             addr_row,addr_col: IN std_logic_vector(3 DOWNTO 0);
             data_in: IN std_logic_vector(31 DOWNTO 0);
             data_out: OUT std_logic_vector(47 DOWNTO 0));
    END COMPONENT;
    SIGNAL rdy_next,rdy_next_next: std_logic;
    SIGNAL addr_row_s,addr_col_s,row_next,col_next: std_logic_vector(3 DOWNTO 0);    
begin
    mat_rf: matrices_register_file PORT MAP(load_m=>load_m,load_k=>load_k,compute=>compute,clk=>clk,rst=>rst,data_in=>data_in,data_out=>data_out,addr_row=>addr_row_s,addr_col=>addr_col_s);
    
    process(rst,clk)
    begin
        IF rising_edge(clk) THEN
            IF (rst='1') THEN
                --sinchronous reset
                rdy<='0';
                rdy_next<='0';
                addr_row_s<=(OTHERS => '0');
                addr_col_s<=(OTHERS => '0');
            ELSE
                addr_row_s<=row_next;
                addr_col_s<=col_next;
                rdy_next<=rdy_next_next;
                rdy<=rdy_next;
                IF ((load_m='0' AND load_k='0' AND compute='0') OR (load_m='1' AND load_k='1')) THEN
                    --immediate change of the addresses, in order not to wait for the logic
                    addr_row_s<=(OTHERS => '0');
                    addr_col_s<=(OTHERS => '0');
                END IF;
            END IF;
        END IF;
    end process;
        
    process(addr_row_s,addr_col_s,load_m,load_k,compute)
        VARIABLE control: std_logic_vector(2 DOWNTO 0);
    begin
        control:= load_m&load_k&compute;
        
        row_next<=addr_row_s;
        col_next<=addr_col_s;
        
        CASE control IS
            WHEN "100"=>--load matrix
                IF (unsigned(addr_col_s)<15) THEN
                    col_next<=std_logic_vector(unsigned(addr_col_s)+1);
                ELSIF (unsigned(addr_row_s)<15) THEN
                    col_next<=(OTHERS => '0');
                    row_next<=std_logic_vector(unsigned(addr_row_s)+1);
                END IF;
             WHEN "010"=>--load kernel
                IF (unsigned(addr_col_s)<2) THEN
                    col_next<=std_logic_vector(unsigned(addr_col_s)+1);
                ELSIF (unsigned(addr_row_s)<2) THEN
                    col_next<=(OTHERS => '0');
                    row_next<=std_logic_vector(unsigned(addr_row_s)+1);
                END IF;
            WHEN "001"=>--compute convolution
                IF (unsigned(addr_col_s)<15) THEN
                    col_next<=std_logic_vector(unsigned(addr_col_s)+1);                    
                ELSIF (unsigned(addr_row_s)<15) THEN
                    col_next<=(OTHERS => '0');
                    row_next<=std_logic_vector(unsigned(addr_row_s)+1);
                END IF;
            WHEN OTHERS=>--idle
                row_next<=(OTHERS => '0');
                col_next<=(OTHERS => '0');            
        END CASE;      
    end process;
    
    rdy_next_setter:process(addr_row_s,addr_col_s,compute,rdy_next)
    begin
        rdy_next_next<=rdy_next;
        IF(compute='1' AND unsigned(addr_row_s)=15 AND unsigned(addr_col_s)=15) THEN
            rdy_next_next<='1';
        END IF;
    end process;
end Behavioral;