`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         NITK Surathkal
// Engineer:        Shivam Potdar
// 
// Create Date:    19:06:51 06/11/2020 
// Design Name:     Doorlock implementation in verilog
// Module Name:     doorlock_reg
// Project Name:    doorlock_reg
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

module doorlock_reg(R0, R1, R2, R3, CLK, rst, sw_reset, C0, C1, C2, V, Nout, Kd, storeLED, lockOP);
    input R0, R1, R2, R3, CLK, rst, sw_reset;       // R0, R1, R2, R3 are row signals from the keypad,
                                                    // rst is for resetting all the registers and flops in the circuit to zero
                                                    // sw_reset is for the physical reset button to send the machine to store mode
    inout C0, C1, C2;                               // C0, C1, C2 are column signals from keypad    
    output V, Kd, storeLED;                 		// Key valid and Keydown, from keypad scanner module    
	output lockOP;                    				// to indicate system is in store mode
    output [3:0] Nout;                              // read value by scanner        

    scanner scanner(R0, R1, R2, R3, CLK, C0, C1, C2, Nout[0], Nout[1], Nout[2], Nout[3], V, Kd);
    // instantiate the scanner module
		
    reg [2:0] counter;       // counter to count reqd number of inputs values
    reg [3:0] password[0:7]; // ROM to store correct password
    reg [3:0] ram[0:7];      // RAM to temporarily store input password
		
    wire [2:0] cnt_up, cnt_up_ram ; // cnt_up is for length of password in ROM, cnt_up_ram for RAM (while storing)
	 
	reg [2:0] state, nextstate;		// regs to store current and next states
	reg counter_en, counter_rst, ram_rst, ram_wr_en, rom_wr_en;		// RAM and ROM have synchronous writes (with the clock) and asynchronous reads,
																	// these control signals are taken care of by the FSM.

    // initialise RAM / ROM to zero 
	initial begin
		{ram[0],ram[1],ram[2],ram[3],ram[4],ram[5],ram[6],ram[7]}=0;
		{password[0],password[1],password[2],password[3],password[4],password[5],password[6],password[7]}=0;
		state=0;
		counter_en=0;
		counter_rst=0;
	end
	 
    // states encoding
	parameter   s_init      =   3'b000, 
                s_wait      =   3'b001, 
                s_correctip =   3'b010, 
                s_unlock    =   3'b011,
                s_resetram  =   3'b100,
                s_store     =   3'b101, 
                s_changedpd =   3'b110;

    // check the position of # and assign max value of counter
    assign cnt_up 		= 	(password[4] == 11) ? 4 :
							(password[5] == 11) ? 5 :
							(password[6] == 11) ? 6 :
							(password[7] == 11) ? 7 :
												  0 ;
	 
	assign cnt_up_ram   =   (ram[4] == 11) ? 4 :
							(ram[5] == 11) ? 5 :
							(ram[6] == 11) ? 6 :
							(ram[7] == 11) ? 7 :
											 0 ;
											 
	assign storeLED	= 	(state == s_store) || (state == s_changedpd) || (state == s_resetram) ? 1'b1 : 1'b0;
	assign lockOP	= 	(state == s_unlock) ? 1'b1 : 1'b0;
	
	integer i;
	
    always @(state, V, Nout, rst, cnt_up, cnt_up_ram, counter, ram) begin
        if (rst) begin
			ram_rst <= 1;
			ram_wr_en <= 0;
			counter_rst <= 1;
			counter_en <= 0;
			rom_wr_en <= 0;
            nextstate <= 0;
		end
		else begin
			case (state)		
				// initial state
				s_init      :   begin
									nextstate <= s_wait;
									counter_rst <= 1;
									counter_en  <= 0;
									ram_rst <= 1;
									ram_wr_en <= 0;
									rom_wr_en <= 0;
								end

				// checks input , compare with password, redirect to unlock / store mode
				s_wait      :   begin
									counter_rst <= 0;
									counter_en  <= (V && (counter < cnt_up) && (Nout == password[counter]));
									ram_rst <= 0;
									rom_wr_en <= 0;
									ram_wr_en <= 0;
									if (V && (counter < cnt_up) && (Nout == password[counter])) begin	
										ram_rst <= 0;
										ram_wr_en <= 1;
										nextstate <= s_wait;
									end
									else if (V && (counter==cnt_up) && (Nout == 11))
										nextstate <= s_unlock;       // if input is # and password is correct
									else if (V && (counter==cnt_up) && (Nout == 10))
										nextstate <= s_resetram;     // if input is * and password is correct
									else if ((V==1'b1) && (counter<=cnt_up) && (Nout!=password[counter]))
										nextstate <= s_init;         // if any input mismatches with password go back to intit
									else nextstate <= s_wait;
								end   

				s_unlock    :   begin
									counter_rst <= 1;
									counter_en  <= 0;
									ram_rst <= 1;
									ram_wr_en <= 0;
									rom_wr_en <= 0;
									if (V && Nout==11)
										nextstate <= s_unlock;           // stay here as long as input is #
									else
										nextstate <= s_init;             // go back to init is # is released
								end

				// to reset regs before storing in the new password
				s_resetram  :   begin
									counter_rst <= 1;
									counter_en  <= 0;
									ram_rst <= 1;
									ram_wr_en <= 0;
									rom_wr_en <= 0;
									nextstate <= s_store;
								end

				// the logic for store is, in the first run, all valid values are stored in the RAM,
				// given that the length is more than 4 and # is pressed
				// then in the s_changedpd, each input value is compared with values in RAM, 
				// if they all match, RAM value is dumped to ROM and it becomes the new password,
				// any mismatch takes the machine back to s_init
				s_store     :   begin
									counter_rst <= 0;
									counter_en  <= (V==1'b1) && (counter < 7) && (Nout>=0);
									ram_rst <= 0;
									ram_wr_en <= 0;
									rom_wr_en <= 0;
									if((counter>=3) && (Nout==11) && (V==1'b1)) begin
										ram_rst <= 0;
										ram_wr_en <= 1;
										counter_rst <= 1;
										counter_en <= 0;
										nextstate <= s_changedpd;
									end
									else if((V==1'b1) && (counter < 7) && (Nout>=0)) begin
										ram_rst <= 0;
										ram_wr_en <= 1;
										nextstate <= s_store;
									end
									else if(counter==7 && Nout!==11 && V==1'b1) 
										nextstate <= s_init;
									else nextstate <= s_store;
								end

				s_changedpd :  	begin
									counter_rst <= 0;
									counter_en  <= V && (counter < cnt_up_ram) && (Nout == ram[counter]);
									ram_rst <= 0;
									ram_wr_en <= 0;
									rom_wr_en <= 0;
									if (V && (counter < cnt_up_ram) && (Nout == ram[counter]))
										nextstate <= s_changedpd;
									else if ((V==1'b1) && (counter<=cnt_up_ram) && (Nout!=ram[counter]))
										nextstate <= s_init;
									else if (V && (counter==cnt_up_ram) && (Nout == 11)) begin
										rom_wr_en <= 1'b1;
										nextstate <= s_init;
									end
									else nextstate <= s_changedpd;
								end
								
				default	:		begin
									nextstate <= s_init;
									counter <= 0;
									counter_en <= 0;
									counter_rst <= 1;
									ram_rst <= 1;
									ram_wr_en <= 0;
									rom_wr_en <= 0;
								end

			endcase
		end
    end
	
	// Password ROM logic
	always @(posedge CLK, posedge rst) begin
		// define default password
		if(rst) begin
		    password[0] <= 1;
            password[1] <= 2;
            password[2] <= 3;
            password[3] <= 4;
            password[4] <= 11;
            password[5] <= 0;
            password[6] <= 0;
            password[7] <= 0;
		end	
		else if(rom_wr_en)
			for(i=0;i<=7;i=i+1)
                password[i] <= ram[i];
	end

	// RAM Logic
	always @(posedge CLK) begin
			if(ram_wr_en)
				ram[counter] <= Nout;
			else if(ram_rst)
				{ram[0],ram[1],ram[2],ram[3],ram[4],ram[5],ram[6],ram[7]}<=0;
	end
	
   always @(posedge CLK) begin
            if(sw_reset)
				state <= s_store;
			else 
				state <= nextstate;
				
			if(counter_en)
				counter <= counter + 1'b1;
			else if(counter_rst)
				counter <= 0;
				
    end

endmodule
