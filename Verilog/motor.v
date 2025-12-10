// This module take "mode" input and control two motors accordingly.
// clk should be 100MHz for PWM_gen module to work correctly.
// You can modify or add more inputs and outputs by yourself.
module motor(
    input clk,
    input rst,
    input [4:0]mode,
    output [1:0]pwm,
    output reg [1:0]r_IN,
    output reg [1:0]l_IN
);

    reg [9:0]left_motor, right_motor;
    wire left_pwm, right_pwm;

    motor_pwm m0(clk, rst, left_motor, left_pwm);
    motor_pwm m1(clk, rst, right_motor, right_pwm);

    assign pwm = {left_pwm,right_pwm};

    // TODO: Trace the remaining code in motor.v and control the speed and direction of the two motors
    localparam [4:0]IDLE = 5'd0;
    localparam [4:0]START = 5'd1;
    localparam [4:0]COUNT = 5'd2;
    localparam [4:0]STRAIGHT = 5'd3;
    localparam [4:0]CHOOSE = 5'd4;
    localparam [4:0]TURN_STRAIGHT = 5'd5;
    localparam [4:0]TURN_LEFT = 5'd6;
    localparam [4:0]TURN_RIGHT = 5'd7;
    localparam [4:0]STOP = 5'd30;
    localparam [4:0]ERROR = 5'd31;

    reg turnEn;
    wire turnFinish;

    always@(posedge clk,posedge rst)begin
        if(rst)begin
            left_motor <= 0;
            right_motor <= 0;
            r_IN <= 2'b10;
            l_IN <= 2'b10;
        end
        else begin
            turnEn <= 0;
            case(mode)
                IDLE: begin
                    left_motor <= 0;
                    right_motor <= 0;
                    r_IN <= 2'b10;
                    l_IN <= 2'b10;  
                end
                START: begin
                    left_motor <= 0;
                    right_motor <= 0;
                    r_IN <= 2'b10;
                    l_IN <= 2'b10;  
                end
                COUNT: begin
                    left_motor <= 0;
                    right_motor <= 0;
                    r_IN <= 2'b10;
                    l_IN <= 2'b10; 
                end
                STRAIGHT: begin
                    left_motor <= 10'd800;
                    right_motor <= 10'd800;
                    r_IN <= 2'b10;
                    l_IN <= 2'b10; 
                end
                CHOOSE: begin
                    left_motor <= 10'd800;
                    right_motor <= 10'd800;
                    r_IN <= 2'b10;
                    l_IN <= 2'b10; 
                end
                ERROR: begin
                    left_motor <= 0;
                    right_motor <= 0;
                    r_IN <= 2'b10;
                    l_IN <= 2'b10; 
                end
                TURN_LEFT:begin
                    turnEn <= 1;
                    r_IN <= 2'b01;
                    l_IN <= 2'b10; 
                    if(turnFinish)begin
                        left_motor <= 10'd700;
                        right_motor <= 10'd700;
                    end else begin
                        left_motor <= 0;
                        right_motor <= 0;

                    end

                end
            endcase
        end
    end
    
    counter #(.timeLength(1)) t1(
        .clk(clk),
        .en(turnEn),
        .finish(turnFinish)
    );
    
endmodule

