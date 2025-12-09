module lab6_advanced(
    input clk,
    input rst,
    input echo,
    input left_track,
    input right_track,
    input mid_track,
    input wire sw,
    input wire sb,
    output trig,
    output IN1,
    output IN2,
    output IN3, 
    output IN4,
    output left_pwm,
    output right_pwm,
    output reg [7:0] LED
    // You may modify or add more input/ouput by yourself.
  );
    // We have connected the motor and sonic_top modules in the template file for you.
    // TODO: Control the motors with the information you get from ultrasonic sensor and 3-way track sensor.
    wire [2:0] mode;//01左轉、10右轉、00停止、11前進
    wire [1:0] state;
    wire [19:0] distance;
    localparam LEFT = 2'b01;
    localparam RIGHT = 2'b10;
    localparam STOP = 2'b00;
    localparam FORWARD = 2'b11;
    assign mode = (distance < 2) ? STOP : state;
    always@(*)begin
         LED[3:0] = {(distance < 2),left_track,mid_track,right_track};
         LED[7:4] = 4'b0000;
        case(state)
            LEFT:LED[7] = 1'b1;
            RIGHT:LED[6] = 1'b1;
            FORWARD:LED[5] = 1'b1;
            STOP:LED[4] = 1'b1;
        endcase
    end

    motor A(
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .sw(sw),
        .sb(sb),
        .pwm({left_pwm, right_pwm}),
        .l_IN({IN1, IN2}),
        .r_IN({IN3, IN4})
    );

    sonic_top B(
        .clk(clk), 
        .rst(rst), 
        .Echo(echo), 
        .Trig(trig),
        .distance(distance)
    );

    tracker_sensor C(
        .clk(clk),
        .reset(rst),
        .left_track(left_track),
        .mid_track(mid_track),
        .right_track(right_track),
        .state(state),
        .sb(sb)
    );
endmodule

module tracker_sensor(clk, reset, sb, left_track, right_track, mid_track, state);
    input clk;
    input reset;
    input sb;
    input left_track, right_track, mid_track;
    output reg [2:0] state;

    // TODO: Receive three tracks and create your own policy.
    // Hint: You can use output state to change your action.
    localparam LEFT = 3'b001;
    localparam RIGHT = 3'b010;
    localparam STOP = 3'b000;
    localparam FORWARD = 3'b011;
    localparam BACKWARD = 3'b100;
    always@(posedge clk)begin
        //blocked
        case({left_track,mid_track,right_track})
            3'b110,3'b100:begin
                state <= RIGHT;
            end
            3'b101:begin
                state <= FORWARD;
            end
            3'b011,3'b001:begin
                state <= LEFT;
            end
            3'b000:begin
                if(sb) state <= BACKWARD;
                else state <= state;
            end
            default:state <= state;
        endcase  
    end

endmodule

module motor(
    input clk,
    input rst,
    input [3:0]mode,
    output [1:0]pwm,
    input sb,
    input sw,
    output reg [1:0]r_IN,
    output reg [1:0]l_IN
  );

    reg [9:0]left_motor, right_motor;
    wire left_pwm, right_pwm;

    motor_pwm m0(clk, rst, left_motor, left_pwm);
    motor_pwm m1(clk, rst, right_motor, right_pwm);

    assign pwm = {left_pwm,right_pwm};

    // TODO: Trace the remaining code in motor.v and control the speed and direction of the two motors

    //r_IN & l_IN:forward(2'b10),stop(2'b00)
    localparam LEFT = 3'b001;
    localparam RIGHT = 3'b010;
    localparam STOP = 3'b000;
    localparam FORWARD = 3'b011;
    localparam BACKWARD = 3'b100;

    always@(posedge clk,posedge rst)begin
        if(rst)begin
            left_motor <= 0;
            right_motor <= 0;
            r_IN <= 2'b10;
            l_IN <= 2'b10;
        end
        else begin
            case(mode)
            STOP:begin//stop
                left_motor <= 0;
                right_motor <= 0;
                r_IN <= 2'b10;
                l_IN <= 2'b10;
            end
            LEFT:begin//turn left
                left_motor <= (sw) ? 10'd752 : 10'd800;//原本是752
                right_motor <= 10'd512;
                r_IN <= 2'b10;
                l_IN <= (sw) ? 2'b01 : 2'b10;
            end
            RIGHT:begin//turn right
                left_motor <= 10'd512;
                right_motor <= (sw) ? 10'd752 : 10'd800;
                r_IN <= (sw) ? 2'b01 : 2'b10;
                l_IN <= 2'b10;
            end
            FORWARD:begin//forward
                left_motor <= (sw) ? 10'd752 : 10'd800;
                right_motor <= (sw) ? 10'd752 : 10'd800;
                r_IN <= 2'b10;
                l_IN <= 2'b10;
            end
            BACKWARD:begin//backward
                left_motor <= 10'd752;
                right_motor <= 10'd752;
                r_IN <= 2'b01;
                l_IN <= 2'b01;
            end
            endcase
        end
    end

    
endmodule

module motor_pwm (
    input clk,
    input reset,
    input [9:0]duty,
	output pmod_1 //PWM
  );
        
    PWM_gen pwm_0 ( 
        .clk(clk), 
        .reset(reset), 
        .freq(32'd25000),
        .duty(duty), 
        .PWM(pmod_1)
    );

endmodule

//generte PWM by input frequency & duty cycle
module PWM_gen (
    input wire clk,
    input wire reset,
	input [31:0] freq,
    input [9:0] duty,
    output reg PWM
  );
    wire [31:0] count_max = 100_000_000 / freq;
    wire [31:0] count_duty = count_max * duty / 1024;
    reg [31:0] count;
        
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
            PWM <= 0;
        end else if (count < count_max) begin
            count <= count + 1;
            // TODO: Set <PWM> accordingly
            PWM <= (count < count_duty);
        end else begin
            count <= 0;
            PWM <= 0;
        end
    end
endmodule

module sonic_top(clk, rst, Echo, Trig, distance);
	input clk, rst, Echo;
	output Trig;
    output [19:0] distance;

	wire[19:0] dis;
    wire clk1M;
	wire clk_2_17;

    assign distance = dis;

    div clk1(clk ,clk1M);
	TrigSignal u1(.clk(clk), .rst(rst), .trig(Trig));
	PosCounter u2(.clk(clk1M), .rst(rst), .echo(Echo), .distance_count(dis));
 
endmodule

module PosCounter(clk, rst, echo, distance_count); 
    input clk, rst, echo;
    output[19:0] distance_count;

    parameter S0 = 2'b00;
    parameter S1 = 2'b01; 
    parameter S2 = 2'b10;
    
    wire start, finish;
    reg[1:0] curr_state, next_state;
    reg echo_reg1, echo_reg2;
    reg[19:0] count, distance_register;

    always@(posedge clk) begin
        if(rst) begin
            echo_reg1 <= 0;
            echo_reg2 <= 0;
            count <= 0;
            distance_register  <= 0;
            curr_state <= S0;
        end
        else begin
            echo_reg1 <= echo;   
            echo_reg2 <= echo_reg1; 
            case(curr_state)
                S0:begin
                    if (start) curr_state <= next_state; //S1
                    else count <= 0;
                end
                S1:begin
                    if (finish) curr_state <= next_state; //S2
                    else count <= count + 1;
                end
                S2:begin
                    distance_register <= count;
                    count <= 0;
                    curr_state <= next_state; //S0
                end
            endcase
        end
    end

    always @(*) begin
        case(curr_state)
            S0:next_state = S1;
            S1:next_state = S2;
            S2:next_state = S0;
            default:next_state = S0;
        endcase
    end

    assign start = echo_reg1 & ~echo_reg2;  
    assign finish = ~echo_reg1 & echo_reg2;

    // TODO: Trace the code and calculate the distance, output it to <distance_count>
    // Hint: Be careful with the length units.
    // always@(*)begin
    // end
    assign distance_count = (distance_register * 17) / 10000;
    
endmodule

// send trigger signal to sensor
module TrigSignal(clk, rst, trig);
    input clk, rst;
    output trig;

    reg trig, next_trig;
    reg[23:0] count, next_count;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count <= 0;
            trig <= 0;
        end
        else begin
            count <= next_count;
            trig <= next_trig;
        end
    end

    // count 10us to set <trig> high and wait for 100ms, then set <trig> back to low
    always @(*) begin
        next_trig = trig;
        next_count = count + 1;
        // TODO: Set <next_trig> and <next_count> to let the sensor work properly
        if(trig == 0)begin
            if(count >= 10000000 - 1)begin
                next_trig = 1;
                next_count = 0;
            end
        end
        else if(trig == 1)begin
            if(count >= 1000 - 1)begin
                next_trig = 0;
                next_count = 0;
            end
        end
    end
endmodule



module div(clk ,out_clk);
    input clk;
    output out_clk;
    reg out_clk;
    reg [6:0]cnt;
    
    always @(posedge clk) begin   
        if(cnt < 7'd50) begin
            cnt <= cnt + 1'b1;
            out_clk <= 1'b1;
        end 
        else if(cnt < 7'd100) begin
	        cnt <= cnt + 1'b1;
	        out_clk <= 1'b0;
        end
        else if(cnt == 7'd100) begin
            cnt <= 0;
            out_clk <= 1'b1;
        end
    end
endmodule