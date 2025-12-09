module mainModule(
    input clk,
    input rst,
    input echo,
    input left_track,
    input right_track,
    input mid_track,
    input wire [15:0]sw,
    output reg [15:0]LED,
    output trig,
    output IN1,
    output IN2,
    output IN3, 
    output IN4,
    output left_pwm,
    output right_pwm
);
  // Wire, Reg signal
    reg [4:0]state, nextState;
    wire [2:0]detect;
    localparam [2:0]ERROR_ROAD = 3'b000;
    localparam [2:0]RIGHT_ROAD = 3'b001;
    localparam [2:0]STRAIGHT_ROAD = 3'b010;
    localparam [2:0]RIGHT_LITTLE_ROAD = 3'b011;
    localparam [2:0]LEFT_ROAD = 3'b100;
    localparam [2:0]TURN_ROAD101 = 3'b101;
    localparam [2:0]LEFT_LITTLE_ROAD = 3'b110;
    localparam [2:0]TURN_ROAD111 = 3'b111;

  // FSM signal
    reg checkPoint1;
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

  // Counter signal
    wire countEnable = (state == START)? 1:0;
    wire flash;
    wire countFinish;
    clockDriver cD( .clk(clk), .countEnable(countEnable), .countFinish(countFinish), .flash(flash));

  // Turn detect, record signal
    reg [1:0]turnDirection;
    reg [31:0]turnRecord; // stake
    

  // FSM transform  
    always @(posedge clk)begin
        if(rst) state <= IDLE;
        else state <= nextState;
    end
    always @(posedge clk)begin
        case(state)
            IDLE:begin
                checkPoint1<= 0;
            end
            START:begin
                checkPoint1<= 0;
            end
            COUNT:begin
                checkPoint1<= 0;
            end
            STRAIGHT:begin
                checkPoint1<= 0;
            end
            CHOOSE:begin
                if(detect == 3'b000) checkPoint1 <= 1;
            end
            ERROR:begin
                checkPoint1<= 0;
            end
        endcase
    end
    always @(*)begin
        nextState = state;
        case(state)
            IDLE: nextState = (sw[0])? START : IDLE;
            START: nextState = (detect == 3'b010) ? COUNT : START;
            COUNT: nextState = (countFinish) ? STRAIGHT: COUNT;
            STRAIGHT:begin
                case(detect)
                   ERROR_ROAD: nextState = ERROR;
                   RIGHT_ROAD: nextState = ERROR;
                   RIGHT_LITTLE_ROAD: nextState = ERROR;
                   LEFT_ROAD: nextState = ERROR;
                   LEFT_LITTLE_ROAD: nextState = ERROR;


                   STRAIGHT_ROAD: nextState = STRAIGHT;
                   TURN_ROAD111: nextState = CHOOSE;
                   TURN_ROAD101: nextState = ERROR; // Turn 之前不會遇到101 detect
                endcase
            end
            CHOOSE: begin 
                case(detect)
                   ERROR_ROAD: nextState = CHOOSE;
                   RIGHT_ROAD:nextState = CHOOSE;
                   RIGHT_LITTLE_ROAD:nextState = CHOOSE;
                   LEFT_ROAD:nextState = CHOOSE;
                   LEFT_LITTLE_ROAD:nextState = CHOOSE;
                   STRAIGHT_ROAD: nextState = CHOOSE;


                   TURN_ROAD101: nextState = CHOOSE; 
                   TURN_ROAD111: nextState = (checkPoint1)? TURN_STRAIGHT : CHOOSE; 
                endcase
            end
            // TURN_STRAIGHT:begin // straight
            //     // TODO: Update stack: input 1
            //     case(detect)
            //        ERROR_ROAD: nextState = ERROR;
            //        // TODO: back forward
            //        // TODO: pop(), backforward to checkpoint, turn to TURN state 
            //        RIGHT_ROAD:nextState = TURN_STRAIGHT;
            //        RIGHT_LITTLE_ROAD:nextState = TURN_STRAIGHT;
            //        LEFT_ROAD:nextState = TURN_STRAIGHT;
            //        LEFT_LITTLE_ROAD:nextState = TURN_STRAIGHT;
            //        STRAIGHT_ROAD:nextState = TURN_STRAIGHT;


            //        TURN_ROAD101: nextState = ERROR;
            //        TURN_ROAD111: nextState = TURN_STRAIGHT;
            //     endcase
            // end
            // TURN_LEFT: begin 
            //     case(detect)
            //        ERROR_ROAD: nextState = TURN_LEFT;
            //        RIGHT_ROAD:nextState = TURN_LEFT;
            //        RIGHT_LITTLE_ROAD:nextState = TURN_LEFT;
            //        LEFT_ROAD:nextState = TURN_LEFT;
            //        LEFT_LITTLE_ROAD:nextState = TURN_LEFT;
            //        STRAIGHT_ROAD:nextState = TURN_LEFT;


            //        TURN_ROAD101:begin
            //         // TODO: back forward
            //         // TODO: pop(), backforward to checkpoint, turn to TURN_RIGHT
            //        end
            //        TURN_ROAD111: begin
            //         // TODO: Update stack 
            //         nextState = STRAIGHT;
            //        end
            //         // straight
            //     endcase
            // end
            ERROR: nextState = (~sw[0]) ? IDLE : ERROR;
        endcase
    end

  // Led transform
    always @(*)begin
        case (state)
            IDLE: LED = 16'd0;
            START: LED = 16'hFFFF;
            COUNT: LED = (flash)? ~LED : LED;
            STRAIGHT: LED = 16'd0;
            CHOOSE: LED = 16'hAAAA;
            // TURN:
            ERROR: LED = 16'h8001; 
        endcase
    end


  // Senser module
    motor A(
        .clk(clk),
        .rst(rst),
        .mode(state),
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
        .detect_road(detect)
    );

endmodule