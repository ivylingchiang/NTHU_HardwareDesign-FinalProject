module PmodJSTK_TOP(
    CLK,
    RST,
    SS,
    MISO,
    MOSI,
    SCLK,
	DIRECTION
    );
	//參考網址:https://www.instructables.com/How-to-Use-the-PmodJSTK-With-the-Basys3-FPGA/
	// ===========================================================================
	// 										Port Declarations
	// ===========================================================================
			input wire CLK;					// 100Mhz onboard clock
			input wire RST;					// Button D
			input wire MISO;					// Master In Slave Out, Pin 3, Port JA
			output wire SS;					// Slave Select, Pin 1, Port JA
			output wire MOSI;				// Master Out Slave In, Pin 2, Port JA
			output wire SCLK;				// Serial Clock, Pin 4, Port JA
			output wire DIRECTION;

	// ===========================================================================
	// 							  Parameters, Regsiters, and Wires
	// ===========================================================================
			// wire SS;						// Active low
			// wire MOSI;					// Data transfer from master to slave
			// wire SCLK;					// Serial clock that controls communication
			// reg [2:0] LED;				// Status of PmodJSTK buttons displayed on LEDs
        

			// Holds data to be sent to PmodJSTK
			wire [7:0] sndData;

			// Signal to send/receive data to/from PmodJSTK
			wire sndRec;

			// Data read from PmodJSTK
			wire [39:0] jstkData;

			// Signal carrying output data that user selected
			wire [9:0] posData;


			
			//搖桿在左側，下到上六個腳分別是SS,MOSI,MISO,SCLK,GND,VCC
			localparam CHOOSE_STRAIGHT = 2'b00;
			localparam CHOOSE_LEFT = 2'b01;
			localparam CHOOSE_RIGHT = 2'b11;
			localparam CHOOSE_BACK = 2'b10;

			reg [1:0]curPos;
			wire [9:0]xAxis, yAxis;
			reg [3:0] num_0, num_1, num_2, num_3;
			wire [15:0] num = {num_3, num_2, num_1, num_0};

			assign xAxis = {jstkData[9:8], jstkData[23:16]};
			assign yAxis = {jstkData[25:24], jstkData[39:32]};
			// Data to be sent to PmodJSTK, lower two bits will turn on leds on PmodJSTK
			assign sndData = 8'b10000000;

			always@(posedge CLK,posedge RST)begin
				if(RST)begin
					curPos <= 2'b00;
				end
				else begin
					if(xAxis >= 550 && yAxis >= 320 && yAxis <= 720)curPos <= CHOOSE_LEFT;
					else if(xAxis <= 450 && yAxis >= 320 && yAxis <= 720)curPos <= CHOOSE_RIGHT;
					else if(yAxis < 320)curPos <= CHOOSE_STRAIGHT;
					else if(yAxis > 720)curPos <= CHOOSE_BACK;
				end
			end
			always@(*)begin
				num_3 = 0;
				num_2 = 0;
				num_1 = 0;
				num_0 = {2'b0,curPos};
			end
            
			ClkDiv_5Hz genSndRec(
					.CLK(CLK),
					.RST(RST),
					.CLKOUT(sndRec)
			);
			PmodJSTK PmodJSTK_Int(
					.CLK(CLK),
					.RST(RST),
					.sndRec(sndRec),
					.DIN(sndData),
					.MISO(MISO),
					.SS(SS),
					.SCLK(SCLK),
					.MOSI(MOSI),
					.DOUT(jstkData)
			);

endmodule
module PmodJSTK(
			CLK,
			RST,
			sndRec,
			DIN,
			MISO,
			SS,
			SCLK,
			MOSI,
			DOUT
    );

// ===========================================================================
// 										Port Declarations
// ===========================================================================
			input CLK;						// 100MHz onboard clock
			input RST;						// Reset
			input sndRec;					// Send receive, initializes data read/write
			input [7:0] DIN;				// Data that is to be sent to the slave
			input MISO;						// Master in slave out
			output SS;						// Slave select, active low
			output SCLK;					// Serial clock
			output MOSI;					// Master out slave in
			output [39:0] DOUT;			// All data read from the slave

// ===========================================================================
// 							  Parameters, Regsiters, and Wires
// ===========================================================================

			// Output wires and registers
			wire SS;
			wire SCLK;
			wire MOSI;
			wire [39:0] DOUT;

			wire getByte;									// Initiates a data byte transfer in SPI_Int
			wire [7:0] sndData;							// Data to be sent to Slave
			wire [7:0] RxData;							// Output data from SPI_Int
			wire BUSY;										// Handshake from SPI_Int to SPI_Ctrl
			

			// 66.67kHz Clock Divider, period 15us
			wire iSCLK;										// Internal serial clock,
																// not directly output to slave,
																// controls state machine, etc.

// ===========================================================================
// 										Implementation
// ===========================================================================

			//-----------------------------------------------
			//  	  				SPI Controller
			//-----------------------------------------------
			spiCtrl SPI_Ctrl(
					.CLK(iSCLK),
					.RST(RST),
					.sndRec(sndRec),
					.BUSY(BUSY),
					.DIN(DIN),
					.RxData(RxData),
					.SS(SS),
					.getByte(getByte),
					.sndData(sndData),
					.DOUT(DOUT)
			);

			//-----------------------------------------------
			//  	  				  SPI Mode 0
			//-----------------------------------------------
			spiMode0 SPI_Int(
					.CLK(iSCLK),
					.RST(RST),
					.sndRec(getByte),
					.DIN(sndData),
					.MISO(MISO),
					.MOSI(MOSI),
					.SCLK(SCLK),
					.BUSY(BUSY),
					.DOUT(RxData)
			);

			//-----------------------------------------------
			//  	  				SPI Controller
			//-----------------------------------------------
			ClkDiv_66_67kHz SerialClock(
					.CLK(CLK),
					.RST(RST),
					.CLKOUT(iSCLK)
			);

endmodule
module spiCtrl(
			CLK,
			RST,
			sndRec,
			BUSY,
			DIN,
			RxData,
			SS,
			getByte,
			sndData,
			DOUT
    );

	// ===========================================================================
	// 										Port Declarations
	// ===========================================================================

			input CLK;						// 66.67kHz onboard clock
			input RST;						// Reset
			input sndRec;					// Send receive, initializes data read/write
			input BUSY;						// If active data transfer currently in progress
			input [7:0] DIN;				// Data that is to be sent to the slave
			input [7:0] RxData;			// Last data byte received
			output SS;						// Slave select, active low
			output getByte;				// Initiates a data transfer in SPI_Int
			output [7:0] sndData;		// Data that is to be sent to the slave
			output [39:0] DOUT;			// All data read from the slave

	// ===========================================================================
	// 							  Parameters, Regsiters, and Wires
	// ===========================================================================

			// Output wires and registers
			reg SS = 1'b1;
			reg getByte = 1'b0;
			reg [7:0] sndData = 8'h00;
			reg [39:0] DOUT = 40'h0000000000;

			// FSM States
			parameter [2:0] Idle = 3'd0,
								 Init = 3'd1,
								 Wait = 3'd2,
								 Check = 3'd3,
								 Done = 3'd4;
			
			// Present State
			reg [2:0] pState = Idle;

			reg [2:0] byteCnt = 3'd0;					// Number bits read/written
			parameter byteEndVal = 3'd5;				// Number of bytes to send/receive
			reg [39:0] tmpSR = 40'h0000000000;		// Temporary shift register to
																// accumulate all five data bytes

	// ===========================================================================
	// 										Implementation
	// ===========================================================================

	always @(negedge CLK) begin
			if(RST == 1'b1) begin
					// Reest everything
					SS <= 1'b1;
					getByte <= 1'b0;
					sndData <= 8'h00;
					tmpSR <= 40'h0000000000;
					DOUT <= 40'h0000000000;
					byteCnt <= 3'd0;
					pState <= Idle;
			end
			else begin
					
					case(pState)

								// Idle
								Idle : begin

										SS <= 1'b1;								// Disable slave
										getByte <= 1'b0;						// Do not request data
										sndData <= 8'h00;						// Clear data to be sent
										tmpSR <= 40'h0000000000;			// Clear temporary data
										DOUT <= DOUT;							// Retain output data
										byteCnt <= 3'd0;						// Clear byte count

										// When send receive signal received begin data transmission
										if(sndRec == 1'b1) begin
											pState <= Init;
										end
										else begin
											pState <= Idle;
										end
										
								end

								// Init
								Init : begin
								
										SS <= 1'b0;								// Enable slave
										getByte <= 1'b1;						// Initialize data transfer
										sndData <= DIN;						// Store input data to be sent
										tmpSR <= tmpSR;						// Retain temporary data
										DOUT <= DOUT;							// Retain output data
										
										if(BUSY == 1'b1) begin
												pState <= Wait;
												byteCnt <= byteCnt + 1'b1;	// Count
										end
										else begin
												pState <= Init;
										end
										
								end

								// Wait
								Wait : begin

										SS <= 1'b0;								// Enable slave
										getByte <= 1'b0;						// Data request already in progress
										sndData <= sndData;					// Retain input data to send
										tmpSR <= tmpSR;						// Retain temporary data
										DOUT <= DOUT;							// Retain output data
										byteCnt <= byteCnt;					// Count
										
										// Finished reading byte so grab data
										if(BUSY == 1'b0) begin
												pState <= Check;
										end
										// Data transmission is not finished
										else begin
												pState <= Wait;
										end

								end

								// Check
								Check : begin

										SS <= 1'b0;								// Enable slave
										getByte <= 1'b0;						// Do not request data
										sndData <= sndData;					// Retain input data to send
										tmpSR <= {tmpSR[31:0], RxData};	// Store byte just read
										DOUT <= DOUT;							// Retain output data
										byteCnt <= byteCnt;					// Do not count

										// Finished reading bytes so done
										if(byteCnt == 3'd5) begin
												pState <= Done;
										end
										// Have not sent/received enough bytes
										else begin
												pState <= Init;
										end
								end

								// Done
								Done : begin

										SS <= 1'b1;							// Disable slave
										getByte <= 1'b0;					// Do not request data
										sndData <= 8'h00;					// Clear input
										tmpSR <= tmpSR;					// Retain temporary data
										DOUT[39:0] <= tmpSR[39:0];		// Update output data
										byteCnt <= byteCnt;				// Do not count
										
										// Wait for external sndRec signal to be de-asserted
										if(sndRec == 1'b0) begin
												pState <= Idle;
										end
										else begin
												pState <= Done;
										end

								end

								// Default State
								default : pState <= Idle;
						endcase
			end
	end

endmodule
module spiMode0(
    CLK,
    RST,
    sndRec,
    DIN,
    MISO,
    MOSI,
    SCLK,
	 BUSY,
    DOUT
    );


	// ===========================================================================
	// 										Port Declarations
	// ===========================================================================

			input CLK;						// 66.67kHz serial clock
			input RST;						// Reset
			input sndRec;					// Send receive, initializes data read/write
			input [7:0] DIN;				// Byte that is to be sent to the slave
			input MISO;						// Master input slave output
			output MOSI;					// Master out slave in
			output SCLK;					// Serial clock
			output BUSY;					// Busy if sending/receiving data
			output [7:0] DOUT;			// Current data byte read from the slave

	// ===========================================================================
	// 							  Parameters, Regsiters, and Wires
	// ===========================================================================
			wire MOSI;
			wire SCLK;
			wire [7:0] DOUT;
			reg BUSY;

			// FSM States
			parameter [1:0] Idle = 2'd0,
								 Init = 2'd1,
								 RxTx = 2'd2,
								 Done = 2'd3;

			reg [4:0] bitCount;							// Number bits read/written
			reg [7:0] rSR = 8'h00;						// Read shift register
			reg [7:0] wSR = 8'h00;						// Write shift register
			reg [1:0] pState = Idle;					// Present state

			reg CE = 0;										// Clock enable, controls serial
																// clock signal sent to slave
	
	 
	// ===========================================================================
	// 										Implementation
	// ===========================================================================

			// Serial clock output, allow if clock enable asserted
			assign SCLK = (CE == 1'b1) ? CLK : 1'b0;
			// Master out slave in, value always stored in MSB of write shift register
			assign MOSI = wSR[7];
			// Connect data output bus to read shift register
			assign DOUT = rSR;
	
			//-------------------------------------
			//			 Write Shift Register
			// 	slave reads on rising edges,
			// change output data on falling edges
			//-------------------------------------
			always @(negedge CLK) begin
					if(RST == 1'b1) begin
							wSR <= 8'h00;
					end
					else begin
							// Enable shift during RxTx state only
							case(pState)
									Idle : begin
											wSR <= DIN;
									end
									
									Init : begin
											wSR <= wSR;
									end
									
									RxTx : begin
											if(CE == 1'b1) begin
													wSR <= {wSR[6:0], 1'b0};
											end
									end
									
									Done : begin
											wSR <= wSR;
									end
							endcase
					end
			end




			//-------------------------------------
			//			 Read Shift Register
			// 	master reads on rising edges,
			// slave changes data on falling edges
			//-------------------------------------
			always @(posedge CLK) begin
					if(RST == 1'b1) begin
							rSR <= 8'h00;
					end
					else begin
							// Enable shift during RxTx state only
							case(pState)
									Idle : begin
											rSR <= rSR;
									end
									
									Init : begin
											rSR <= rSR;
									end
									
									RxTx : begin
											if(CE == 1'b1) begin
													rSR <= {rSR[6:0], MISO};
											end
									end
									
									Done : begin
											rSR <= rSR;
									end
							endcase
					end
			end



			
			//------------------------------
			//		   SPI Mode 0 FSM
			//------------------------------
			always @(negedge CLK) begin
			
					// Reset button pressed
					if(RST == 1'b1) begin
							CE <= 1'b0;				// Disable serial clock
							BUSY <= 1'b0;			// Not busy in Idle state
							bitCount <= 4'h0;		// Clear #bits read/written
							pState <= Idle;		// Go back to Idle state
					end
					else begin
							
							case (pState)
							
								// Idle
								Idle : begin

										CE <= 1'b0;				// Disable serial clock
										BUSY <= 1'b0;			// Not busy in Idle state
										bitCount <= 4'd0;		// Clear #bits read/written
										

										// When send receive signal received begin data transmission
										if(sndRec == 1'b1) begin
											pState <= Init;
										end
										else begin
											pState <= Idle;
										end
										
								end

								// Init
								Init : begin
								
										BUSY <= 1'b1;			// Output a busy signal
										bitCount <= 4'h0;		// Have not read/written anything yet
										CE <= 1'b0;				// Disable serial clock
										
										pState <= RxTx;		// Next state receive transmit
										
								end

								// RxTx
								RxTx : begin

										BUSY <= 1'b1;						// Output busy signal
										bitCount <= bitCount + 1'b1;	// Begin counting bits received/written
										
										// Have written all bits to slave so prevent another falling edge
										if(bitCount >= 4'd8) begin
												CE <= 1'b0;
										end
										// Have not written all data, normal operation
										else begin
												CE <= 1'b1;
										end
										
										// Read last bit so data transmission is finished
										if(bitCount == 4'd8) begin
												pState <= Done;
										end
										// Data transmission is not finished
										else begin
												pState <= RxTx;
										end

								end

								// Done
								Done : begin

										CE <= 1'b0;			// Disable serial clock
										BUSY <= 1'b1;		// Still busy
										bitCount <= 4'd0;	// Clear #bits read/written
										
										pState <= Idle;

								end

								// Default State
								default : pState <= Idle;
								
							endcase
					end
			end

endmodule