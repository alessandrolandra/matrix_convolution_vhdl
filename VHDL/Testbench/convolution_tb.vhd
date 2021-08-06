----------------------------------------------------------------------------------
-- Company: PoliTo
-- Engineer: Alessandro Landra
-- 
-- Create Date: 27.12.2020 17:11:23
-- Module Name: convolution_tb - Behavioral
-- Project Name: matrixConvolution
-- Description: Test Bench to test the convolution_manager and the matrices_register_file entities
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;--to perform the floor function
use STD.TEXTIO.ALL;

entity convolution_tb is
end convolution_tb;

architecture Behavioral of convolution_tb is
    COMPONENT convolution_manager IS
        PORT(load_m,load_k,compute,clk,rst: IN std_logic;         
             data_in: IN std_logic_vector(31 DOWNTO 0);
             data_out: OUT std_logic_vector(47 DOWNTO 0);
             rdy: OUT std_logic);
    END COMPONENT;
    SIGNAL load_m,load_k,clk,rst,rdy,compute: std_logic;
    SIGNAL data_in: std_logic_vector(31 DOWNTO 0);
    SIGNAL data_out: std_logic_vector(47 DOWNTO 0);
    CONSTANT clk_period: time := 10ns;
    
    file file_in,file_sim: text;    
begin
    DUT: convolution_manager PORT MAP(clk=>clk,rst=>rst,load_m=>load_m,load_k=>load_k,compute=>compute,data_in=>data_in,data_out=>data_out,rdy=>rdy);

    clk_generator:process
    begin
        clk<='0';
        WAIT FOR clk_period/2;
        clk<='1';
        WAIT FOR clk_period/2;
    end process;
    
    signal_feeder:process
        VARIABLE line_in,line_sim: line;
        VARIABLE item: bit_vector(31 DOWNTO 0);
        VARIABLE item_out,item_expected_out: bit_vector(47 DOWNTO 0);
        VARIABLE space: character;
    begin
        rst<='1';
        load_m<='0';
        load_k<='0';
        compute<='0';
        WAIT FOR clk_period;
        rst<='0';               
        file_open(file_in, "matrixIn.mem",  read_mode);
        load_m<='1';--load matrix
        WHILE NOT endfile(file_in) LOOP
            readline(file_in, line_in);
            FOR i IN 0 TO 15 LOOP
                read(line_in, item);
                data_in<=to_stdLogicVector(item);
                read(line_in, space);-- read in the space character
                WAIT FOR clk_period;
            END LOOP;
        END LOOP;
        file_close(file_in);        
        load_m<='0';
        WAIT FOR clk_period;--reset addresses
        load_k<='1';--load kernel
        file_open(file_in, "invertedKernel.mem",  read_mode);        
        WHILE NOT endfile(file_in) LOOP
            readline(file_in, line_in);
            FOR i IN 0 TO 2 LOOP
                read(line_in, item);
                data_in<=to_stdLogicVector(item);
                read(line_in, space);
                WAIT FOR clk_period;
            END LOOP;
        END LOOP;
        file_close(file_in);
        load_k<='0';
        WAIT FOR clk_period;--reset addresses
        compute<='1';        
        WAIT FOR clk_period;
        file_open(file_sim, "simOut.mem",  write_mode);
        FOR i IN 0 TO 15 LOOP            
            FOR k IN 0 TO 15 LOOP
                item_out:=to_bitVector(data_out);
                write(line_sim, item_out);
                write(line_sim, ' ');
                WAIT FOR clk_period;
            END LOOP;
            writeline(file_sim, line_sim);
        END LOOP;
        file_close(file_in);        
        compute<='0';
        WAIT FOR 2*clk_period;
        rst<='1';
        WAIT FOR 2*clk_period;
        rst<='0';       
        
        file_open(file_in, "matrixOut.mem",  read_mode);
        file_open(file_sim, "simOut.mem",  read_mode);
        FOR i IN 0 TO 15 LOOP
            readline(file_in, line_in);
            readline(file_sim, line_sim);
            FOR k IN 0 TO 15 LOOP
                read(line_in, item_expected_out);
                read(line_sim, item_out);
                ASSERT item_out = item_expected_out REPORT "output inatteso (" & integer'image(i) & "," & integer'image(k) &")";
                read(line_in, space);
            END LOOP;
        END LOOP;
        file_close(file_in);
        file_close(file_sim);
        
        WAIT;
    end process;
end Behavioral;
