`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         NITK Surathkal
// Engineer:        Anusha Misra
// 
// Create Date:    19:06:51 06/11/2020 
// Design Name:     Testbench for Doorlock implementation in verilog
// Module Name:     tb_store_reg
// Project Name:    tb_store_reg
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module tb_store_reg();

    reg CLK, rst, sw_reset;
    wire R0, R1, R2, R3;
	wire C0, C1, C2, V, Kd, storeLED, lockOP;
    wire [3:0] N;

    initial begin
        $dumpfile("trystore.vcd");              // store the waveforms in a vcd file
        $dumpvars(0,tb_store_reg);
    end

    integer KARRAY[0:23];
	integer KN, i;

	initial begin
		CLK = 0;
		forever #10 CLK = ~CLK;                 // clock
	end
	
	initial begin
	    KN =0;
		sw_reset = 0;
        rst = 1;
        #5 rst = 0;
	end

   initial begin                                // test stimulus array
		KARRAY[0]  = 1;
		KARRAY[1]  = 2;
		KARRAY[2]  = 3;
		KARRAY[3]  = 4;
		KARRAY[4]  = 11;
		KARRAY[5]  = 11;
		KARRAY[6]  = 1;
		KARRAY[7]  = 2;
		KARRAY[8]  = 3;
		KARRAY[9]  = 4;
		KARRAY[10] = 10;
		KARRAY[11] = 7;
		KARRAY[12] = 8;
		KARRAY[13] = 9;
		KARRAY[14] = 1;
		KARRAY[15] = 11;
		KARRAY[16] = 7;
		KARRAY[17] = 8;
		KARRAY[18] = 9;
		KARRAY[19] = 1;
		KARRAY[20] = 11;
		KARRAY[21] = 4;
		KARRAY[22] = 7;
		KARRAY[23] = 10;
	end
	
    // this testbench decides R values based on C values, to simulate keypresses, this is why C's are inout in the scanner.
	assign R0 = ((C0 == 1'b1 & KN == 1)  | (C1 == 1'b1 & KN == 2) | (C2 == 1'b1 & KN == 3))  ? 1'b1	: 1'b0 ;
	assign R1 = ((C0 == 1'b1 & KN == 4)  | (C1 == 1'b1 & KN == 5) | (C2 == 1'b1 & KN == 6))  ? 1'b1	: 1'b0 ;
	assign R2 = ((C0 == 1'b1 & KN == 7)  | (C1 == 1'b1 & KN == 8) | (C2 == 1'b1 & KN == 9))  ? 1'b1 : 1'b0 ;
	assign R3 = ((C0 == 1'b1 & KN == 10) | (C1 == 1'b1 & KN == 0) | (C2 == 1'b1 & KN == 11)) ? 1'b1 : 1'b0 ;
	
    always @(posedge CLK)
        begin
            for(i = 0; i <= 23; i = i + 1) begin
                KN = KARRAY[i] ;
                if((KN == 10 || KN==11))        // give some extra time if * and # are pressed for states to stabilise
                    #100;
                @(posedge CLK);
                @(posedge CLK);
                @(posedge CLK);
                @(posedge CLK);
                @(posedge CLK);
                @(posedge CLK);
                @(posedge CLK);			        // wait for a few clock cycles after giving in input, just for visual ease
                if (V == 1'b1)
                    if (~(N == KN)) $display("Numbers don't match.");   // if input is valid, check if it matches array
                KN = 15 ;                       // 15 is an invalid input, so it pulls all C's down to 0
                @(posedge CLK);
                @(posedge CLK);
                @(posedge CLK);
                if(storeLED==1)                 // extra time for ROM writes
                    #100;
            end
            $display("Test Complete.");
        $finish;
    end

doorlock_reg doorlock_reg(R0, R1, R2, R3, CLK, rst, sw_reset, C0, C1, C2, V, N, Kd, storeLED, lockOP);


endmodule
