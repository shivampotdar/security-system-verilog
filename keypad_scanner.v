`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		NITK Surathkal
// Engineer: 		Shivam Potdar
// 	
// Create Date:    19:06:51 06/11/2020 
// Design Name: 
// Module Name:    scanner 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: This scannner module is a smaller subset of the lock which is an FSM in itself
// to handle reading of correct values from the keypad module with decode, calculate and debounce.
//
//////////////////////////////////////////////////////////////////////////////////
module scanner(R0, R1, R2, R3, CLK, C0, C1, C2, N0, N1, N2, N3, V, Kd);
	input R0, R1, R2, R3, CLK;
	inout C0, C1, C2;
	output N0, N1, N2, N3, V, Kd;
	reg V;
	reg C0_tmp, C1_tmp, C2_tmp;

	reg QA, Kd;
	wire K;
	reg[2:0] nextstate, state;

	// C0, C1, C2 are inout as the testbench would be very difficult to code directly since R values depend on C
	// hence although the module itself can decode the entire input, this facility is incorporated to make the TB simpler
	initial
	begin
		state = 0;
		QA = 0;
		Kd = 0;
		nextstate = 0;
		C0_tmp = 1'b0 ;			// C's are expected to be regs but since they are inout too, temporary regs are made inside the module
		C1_tmp = 1'b0 ;
		C2_tmp = 1'b0 ;
		V = 1'b0 ;
	end
	
	assign C0 = C0_tmp;
	assign C1 = C1_tmp;
	assign C2 = C2_tmp;

	// assign output based on the R and C values. (Output is 4 bit as there are 12 distinct outputs)
	assign K = R0 | R1 | R2 | R3 ;
	assign N3 = (R2 & ~C0) | (R3 & ~C1) ;
	assign N2 = R1 | (R2 & C0) ;
	assign N1 = (R0 & ~C0) | (~R2 & C2) | (~R1 & ~R0 & C0) ;
	assign N0 = (R1 & C1) | (~R1 & C2) | (~R3 & ~R1 & ~C1) ;

	// the decoding part of scanning takes place in FSM as multiple cases are involed.

	always @(state or R0 or R1 or R2 or R3 or C0 or C1 or C2 or K or Kd or QA)
		begin
			C0_tmp = 1'b0 ;
			C1_tmp = 1'b0 ;
			C2_tmp = 1'b0 ;
			V = 1'b0 ;
			case (state)
				0 :	nextstate = 1 ;
				1 :
					begin
						C0_tmp = 1'b1 ;
						C1_tmp = 1'b1 ;
						C2_tmp = 1'b1 ;
						if ((Kd & K) == 1'b1)
							nextstate = 2 ;
						else nextstate = 1 ;
					end
				2 :
					begin
						C0_tmp = 1'b1 ;
						if ((Kd & K) == 1'b1)
						begin
							V = 1'b1 ;
							nextstate = 5 ;
						end
						else if (K == 1'b0)
							nextstate = 3 ;
						else nextstate = 2 ;
					end
				3:	
					begin
						C1_tmp = 1'b1 ;
						if ((Kd & K) == 1'b1)
						begin
							V = 1'b1 ;
							nextstate = 5 ;
						end
						else if (K == 1'b0)
							nextstate = 4 ;
						else nextstate = 3 ;
					end
				4:	
					begin
						C2_tmp = 1'b1 ;
						if ((Kd & K) == 1'b1)
						begin
							V = 1'b1 ;
							nextstate = 5 ;
						end
						else nextstate = 4 ;
					end
				5: 
					begin
						C0_tmp = 1'b1 ;
						C1_tmp = 1'b1 ;
						C2_tmp = 1'b1 ;
						if (Kd == 1'b0)
							nextstate = 1 ;
						else nextstate = 5 ;
					end
				default : nextstate = 0;
		endcase
	end
	always @(posedge CLK)
	begin
		state <= nextstate;
		QA <= K ;		// for debounce
		Kd <= QA ;		
	end
endmodule
