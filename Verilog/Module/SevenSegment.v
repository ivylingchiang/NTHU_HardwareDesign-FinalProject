// SevenSegment.v                                         //
// Use nums[15:0] control the 4-digit 7-segment display   //
// nums: {BCD4, BCD3, BCD2, BCD1}                         //
//       0-9:present num 0-9; 10:A; 11:b; 12:-;           //
//       others(1111):nothing                             //

// Modify: here you can add more display type if you want, then outside the module you can pass the "nums" wire to make here display what you want.
// Notice: here can just display at most 16 types, since each BCD is 4 bits.(You must modify nums bit size to make it bigger if you want more types)
module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit,
	input wire [15:0] nums,
	input wire rst,
	input wire clk,
	input wire [2:0]switchMode
  );
    
    reg [15:0] clk_divider;
    reg [3:0] display_num;
		// switchMode = 0 : AUTO;
		// switchMode = 1 : testBasic;
		// switchMode = 2 : testAdv1;
		// switchMode = 3 : testAdv2;
		// switchMode = 4 : Manual;
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		clk_divider <= 15'b0;
    	end else begin
    		clk_divider <= clk_divider + 15'b1;
    	end
    end
    
    always @ (posedge clk_divider[15]) begin
    		case (digit)
    			4'b1110 : begin
						display_num <= nums[7:4];
						digit <= 4'b1101;
					end
    			4'b1101 : begin
						display_num <= nums[11:8];
						digit <= 4'b1011;
					end
    			4'b1011 : begin
						display_num <= nums[15:12];
						digit <= 4'b0111;
					end
    			4'b0111 : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end
    			default : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end				
    		endcase
    end
    

		// switchMode = 0 : AUTO;
		// switchMode = 1 : testBasic;
		// switchMode = 2 : testAdv1;
		// switchMode = 3 : testAdv2;
		// switchMode = 4 : Manual;
    always @ (*) begin
			if(switchMode == 3'd0 || switchMode == 3'd4) begin
				case (display_num)
					0 : display = 7'b1000000;	 //0000
					1 : display = 7'b1111001;  //0001                                                
					2 : display = 7'b0100100;  //0010                                                
					3 : display = 7'b0110000;  //0011                                             
					4 : display = 7'b0011001;  //0100                                               
					5 : display = 7'b0010010;  //0101                                               
					6 : display = 7'b0000010;  //0110
					7 : display = 7'b1111000;  //0111
					8 : display = 7'b0000000;  //1000
					9 : display = 7'b0010000;	 //1001
					10: display = 7'b1000110;  // C
					11: display = 7'b0111111;  // -
					12: display = 7'b0100001 ; //d
					13: display = 7'b1000111 ; //L
					14: display = 7'b0000110 ; //E
					15: display = 7'b0101111 ; //r

				default : display = 7'b1111111; //nothing
				endcase
			end else begin
				case (display_num)
					0 : display = 7'b1000000;	 //0000
					1 : display = 7'b1111001;  //0001                                                
					2 : display = 7'b0100100;  //0010                                                
					3 : display = 7'b0110000;  //0011                                             
					4 : display = 7'b0011001;  //0100                                               
					5 : display = 7'b0010010;  //0101  //s                                        
					6 : display = 7'b0000010;  //0110
					7 : display = 7'b1111000;  //0111
					8 : display = 7'b0000000;  //1000
					9 : display = 7'b0010000;	 //1001
					10: display = 7'b0000111;  // t
					11: display = 7'b0111111;  // -
					12: display = 7'b0000011 ; //b
					13: display = 7'b1000111 ; //L
					14: display = 7'b0000110 ; //E
					15: display = 7'b0101111 ; //r

				default : display = 7'b1111111; //nothing
				endcase
			end
    end
endmodule