----------------------------------------------------------------------------------
-- Company: PoliTo
-- Engineer: Alessandro Landra
-- 
-- Create Date: 26.12.2020 21:58:20
-- Module Name: padded_matrix - Behavioral
-- Project Name: matrixConvolution
-- Description: entity responsible for storing the padded matrix and the kernel, and computing their convolution
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity matrices_register_file is
    PORT(load_m,load_k,compute,clk,rst: IN std_logic;
         addr_row,addr_col: IN std_logic_vector(3 DOWNTO 0);
         data_in: IN std_logic_vector(31 DOWNTO 0);
         data_out: OUT std_logic_vector(47 DOWNTO 0));
end matrices_register_file;

architecture Behavioral of matrices_register_file is
    TYPE ROW_P IS ARRAY(0 TO 17) OF std_logic_vector(31 DOWNTO 0);
    TYPE ROW_K IS ARRAY(0 TO 2) OF std_logic_vector(31 DOWNTO 0);
    TYPE MATRIX_P IS ARRAY(0 TO 17) OF ROW_P;
    TYPE KERNEL IS ARRAY(0 TO 2) OF ROW_K;    
    SIGNAL mat_in,next_mat_in: MATRIX_P;--16x16 padded matrix (-> 18x18)
    SIGNAL ker,next_ker: KERNEL;--3x3 kernel
    SIGNAL data_out_s,data_out_next: std_logic_vector(47 DOWNTO 0);--fixed point number with the following bitwidth: 32.16
begin

    reg_update:process(clk,rst)
    begin
        IF rising_edge(clk) THEN
            IF (rst='1') THEN--SYNCHRONOUS RESET
                mat_in <= (OTHERS => (OTHERS => (OTHERS => '0')));
                ker <= (OTHERS => (OTHERS => (OTHERS => '0')));
                data_out_s<=(OTHERS => 'Z');
            ELSE
                mat_in <= next_mat_in;
                ker <= next_ker;                
                data_out_s<=data_out_next;
            END IF;
        END IF;
    end process;
    data_out<=data_out_s;
    
    comb_logic:process(addr_row,addr_col,data_in,ker,mat_in)
    begin
        next_mat_in<=mat_in;
        next_ker<=ker;
        IF (load_m='1') THEN --matrix in load, taking into account the needed padding            
            next_mat_in(to_integer('0'&unsigned(addr_row)+1))(to_integer('0'&unsigned(addr_col)+1))<=data_in;
        ELSIF (load_k='1') THEN --kernel load
            next_ker(to_integer(unsigned(addr_row)))(to_integer(unsigned(addr_col)))<=data_in;            
        END IF;
    end process;
    
    convolution_computer:process(compute,data_out_s,addr_row,addr_col)        
        VARIABLE sum: unsigned(63 DOWNTO 0);
    begin        
        IF (compute='1') THEN
            sum:=(OTHERS => '0');
            FOR i IN 0 TO 2 LOOP
                FOR k IN 0 TO 2 LOOP
                    sum:=sum+unsigned(mat_in(to_integer(unsigned(addr_row))+i)(to_integer(unsigned(addr_col))+k))*unsigned(ker(i)(k));                    
                END LOOP;
            END LOOP;
            data_out_next<=std_logic_vector(sum(63 DOWNTO 16));--last 16 fractional bit are not taken into account, to have the same precision of the input data
        ELSE
            data_out_next<=(OTHERS => 'Z');
        END IF;
    end process;
end Behavioral;