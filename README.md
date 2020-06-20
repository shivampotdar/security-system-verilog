# Verilog Implementation of Security System with 3x4 (phone) keypad and FSMs

Author - Shivam Mahesh Potdar, Jr Yr EE, NITK, IN


### Problem Statement - 
Design a push-button door lock that uses a standard telephone keypad as input. Use the keypad
scanner as a module. The length of the combination is 4 to 7 digits. To unlock the door, enter the
combination followed by the # key. As long as # is held down, the door will remain unlocked
and can be opened. When # is released, the door is relocked. To change the combination, first
enter the correct combination followed by the * key. The lock is then in the “store” mode. The
“store” indicator light comes on and remains on until the combination has been successfully
changed. Next enter the new combination (4 to 7 digits) followed by #. Then enter the new
combination a second time followed by #. If the second time does not match the first time, the
new combination must be entered two times again. Store the combination in an array of eight 4
bit registers or in a small RAM. Store the 4-bit key codes followed by the code for the # key.
Also provide a reset button that is not part of the keypad. When the reset button is pushed, the
system enters the “store” state and a new combination may be entered. Use a separate counter for
counting the inputs as they come in. A four-bit code, a key-down signal (Kd), and a valid data
signal (V) are available from the keypad module.

Write a Verilog code and simulate your solution.

### This Repo:

- The implementation is split in two major modules. One is keypad scanner, which is largely adopted from Charles Roth, Lizy K. John, Byeong Kil Lee - Digital Systems Design Using Verilog-CL Engineering (2015), Section 4.11

- Based on this module, `doorlock_reg.v` contains the FSM to control this scanner, based on the problem statement above. 

- `tb_store_reg.v` has a testbench implementation which simulates all cases above.

- The code is synthesisable, verified in Xilinx ISE 14
