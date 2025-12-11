module mainModule(
    input clk,
    input rst,
    input echo,
    input left_track,
    input right_track,
    input mid_track,
    input wire [15:0]sw,
    output wire [15:0]LED,
    output trig,
    output IN1,
    output IN2,
    output IN3, 
    output IN4,
    output left_pwm,
    output right_pwm,
    output wire [3:0]DIGIT,
    output wire [6:0]DISPLAY
);
  // Wire, Reg signal
    reg [4:0]state, nextState, lastState;
    wire [2:0]detect;
    wire [19:0] distance;
    localparam [2:0]ERROR_ROAD = 3'b000;
    localparam [2:0]RIGHT_ROAD = 3'b011;
    localparam [2:0]STRAIGHT_ROAD = 3'b010;
    localparam [2:0]RIGHT_LITTLE_ROAD = 3'b001;
    localparam [2:0]LEFT_ROAD = 3'b110;
    localparam [2:0]TURN_ROAD101 = 3'b101;
    localparam [2:0]LEFT_LITTLE_ROAD = 3'b100;
    localparam [2:0]TURN_ROAD111 = 3'b111;
    wire [15:0]nums;

  // debounce, one pulse
    wire rst_d,rst_op;
    debounce d0( .pb_debounced(rst_d), .clk(clk), .pb(rst));
    onepulse o0( .signal(rst_d), .clk(clk), .op(rst_op));

  // FSM signal
    localparam [4:0]IDLE = 5'd0;
    localparam [4:0]START = 5'd1;
    localparam [4:0]COUNT = 5'd2;
    localparam [4:0]STRAIGHT = 5'd3;
    localparam [4:0]CHOOSE = 5'd4;
    localparam [4:0]LEFT = 5'd5;
    localparam [4:0]RIGHT = 5'd6;
    localparam [4:0]BACK = 5'd7;
    localparam [4:0]LITTLE_LEFT = 5'd8;
    localparam [4:0]LITTLE_RIGHT = 5'd9;
    localparam [4:0]STOP = 5'd30;
    localparam [4:0]ERROR = 5'd31;

  // Counter signal
    wire countEnable = (state == COUNT)? 1:0;
    wire flash;
    wire countFinish;
    wire [1:0]countDetail;
    clockDriver cD( .clk(clk), .countEnable(countEnable), .countFinish(countFinish), .flash(flash), .countDetail(countDetail));
    wire countSTOP = (state == STOP) ? 1:0;
    wire reSTART;
    reg [4:0]transitionState;
    clockDriver1 cD1( .clk(clk), .countEnable(countSTOP), .flash(reSTART));
    wire flashBack;
    wire backEn = (state == BACK) ? 1:0;
    clockDriver2 cD2( .clk(clk), .countEnable(backEn), .flash(flashBack));
  
  // Checkpoint setting
    // cp1: from straight(111) to choose(111)
    // cp2: from left(111) to straight(111)
    // cp3: from stop(111) to left(111)
    // cp4: from stop(111) to right(111)
        reg checkPoint1,checkPoint2,checkPoint3,checkPoint4;
        reg [3:0]num0, num1, num2, num3;
        always @(*)begin
            case(state)
                IDLE: begin
                    num0 = 4'd1;
                    num1 = 4'd12;
                    num2 = 4'd13;
                    num3 = 4'd14;
                end

                START: begin
                    num0 = 4'd11;
                    num1 = 4'd11;
                    num2 = 4'd11;
                    num3 = 4'd11;
                end

                COUNT: begin
                    num0 = 4'd11;
                    num1 = 4'd11;
                    num2 = 4'd11;
                    num3 = 3 - countDetail;
                end

                STRAIGHT,LITTLE_LEFT,LITTLE_RIGHT: begin //checkPoint2
                    num0 = 4'd10;
                    num1 = 4'd2;
                    num2 = 4'd11;
                    num3 = (checkPoint2) ? 4'd1:4'd0;
                end

                CHOOSE: begin
                    num0 = 4'd10;
                    num1 = 4'd1;
                    num2 = 4'd11;
                    num3 = (checkPoint1) ? 4'd1:4'd0;
                end

                LEFT: begin
                    num0 = 4'd10;
                    num1 = 4'd3;
                    num2 = 4'd11;
                    num3 = (checkPoint3) ? 4'd1:4'd0;
                end

                RIGHT: begin
                    num0 = 4'd10;
                    num1 = 4'd4;
                    num2 = 4'd11;
                    num3 = (checkPoint4) ? 4'd1:4'd0;
                end

                BACK: begin
                    num0 = 4'd0;
                    num1 = 4'd0;
                    num2 = 4'd0;
                    num3 = 4'd0;
                end


                STOP: begin
                    num0 = 4'd0;
                    num1 = 4'd0;
                    num2 = 4'd0;
                    num3 = 4'd0;
                end


                default : begin
                    num0 = 4'd15;
                    num1 = 4'd15;
                    num2 = 4'd15;
                    num3 = 4'd15;
                end
            endcase
        end
        always @(posedge clk) begin
            if(rst) begin
                checkPoint1 <= 0;
                checkPoint2 <= 0;
                checkPoint3 <= 0;
                checkPoint4 <= 0;
                
            end else begin

                // if(state == IDLE) begining <= 0;
                // straight -> choose(only detect 000)
                if(state == CHOOSE && detect != 3'b111) 
                    checkPoint1 <= 1;
                else if(state != CHOOSE)checkPoint1 <= 0;
                
                // left -> straight(may detect 010 or 000)
                if ((lastState == COUNT) || (((state == STRAIGHT) || (state == LITTLE_LEFT) || (state ==  LITTLE_RIGHT) ) && (detect != 3'b111))) checkPoint2 <= 1;
                else if(state != STRAIGHT && state != LITTLE_LEFT && state != LITTLE_RIGHT)checkPoint2 <= 0;      

                // back/stop -> left(may detect anything)     
                if(state == LEFT && detect != 3'b111) 
                    checkPoint3 <= 1;
                else if(state != LEFT) checkPoint3 <= 0;

                // back/stop -> right (may detect anything) 
                if(state == RIGHT && detect != 3'b111)checkPoint4 <= 1;
                else if(state != RIGHT) checkPoint4<=0;


            end
        end

  // Turn detect, record signal
    // reg [1:0]turnDirection;
    // reg [31:0]turnRecord; // stake
    // TODO
    wire [1:0]pop = 2'd0;

  // FSM transform  
    always @(posedge clk or posedge rst)begin
        if(rst || sw[0] == 0) state <= IDLE;
        else begin
            state <= nextState;
            lastState <= state;
        end
    end
    reg [1:0]counterRight;
    reg DoneRight;
    always @(posedge clk)begin
        if(state == RIGHT && detect == 3'b111)begin
            counterRight <= counterRight +1;
            if(counterRight >= 2) DoneRight <= 1;
        end else if(state != RIGHT) begin 
            counterRight <= 0;
            DoneRight <= 0;
        end
    end
    always @(posedge clk)begin
        if(rst)begin
           transitionState <= IDLE; 
        end else begin
            if((state == STRAIGHT || state ==LITTLE_LEFT || state ==LITTLE_RIGHT) && detect == ERROR_ROAD)
                transitionState <= BACK;
            else if(state == CHOOSE && detect == TURN_ROAD101)
                transitionState <= LEFT;
            else if(state == LEFT)
                if(detect == TURN_ROAD101)
                    transitionState <= RIGHT;
                else if (detect == TURN_ROAD111)
                    transitionState <= STRAIGHT;
            else if(state == RIGHT && detect == TURN_ROAD111)
                transitionState <= STRAIGHT;
            else if (state == BACK)begin
                if(pop==2'd0)begin
                    transitionState <= LEFT;
                end else if(pop==2'd1) begin
                    transitionState <= RIGHT;
                end
            end else transitionState <= IDLE;            
        end
    end
    always @(*)begin
        case(state)
            IDLE: nextState = (sw[0])? START : IDLE;
            
            START: nextState = (detect == 3'b010) ? COUNT : START;
            
            COUNT: nextState = (countFinish) ? STRAIGHT: COUNT;
            
            STRAIGHT:begin
                case(detect)
                   // ERROR STATE(0)
                    
                   // Transform state(2)
                    ERROR_ROAD: begin 
                        nextState =  STOP;
                        // transitionState = BACK;
                    end
                    TURN_ROAD111: nextState = (checkPoint2) ? CHOOSE : STRAIGHT;
                   // Nothing Change(6)
                    RIGHT_ROAD, LEFT_ROAD: nextState = STRAIGHT;
                    RIGHT_LITTLE_ROAD: nextState = LITTLE_RIGHT;
                    LEFT_LITTLE_ROAD: nextState = LITTLE_LEFT;
                    TURN_ROAD101: nextState = STRAIGHT;
                    STRAIGHT_ROAD: nextState = STRAIGHT;                  
                    default : nextState = STRAIGHT;
                endcase
            end
            
            CHOOSE: begin 
                case(detect)
                   // ERROR STATE(0)
                    
                   // Transform state(2)
                    TURN_ROAD101: begin
                        nextState = STOP;
                        // transitionState = LEFT;
                    end
                    TURN_ROAD111: nextState = (checkPoint1)? STRAIGHT : CHOOSE;
                   // Nothing Change(6)
                    ERROR_ROAD: nextState = CHOOSE;
                    RIGHT_ROAD, RIGHT_LITTLE_ROAD:nextState = CHOOSE;
                    LEFT_ROAD, LEFT_LITTLE_ROAD:nextState = CHOOSE;
                    STRAIGHT_ROAD: nextState = CHOOSE;
                    default :  nextState = CHOOSE;
                endcase
            end
            
            LEFT:begin
                case(detect)
                   // ERROR STATE(0)
                    
                   // Transform state(2)
                    TURN_ROAD101: begin
                        nextState = STOP;
                        // transitionState = RIGHT;
                    end
                    TURN_ROAD111: begin
                        if(checkPoint3)begin
                            nextState = STOP;
                            // transitionState = STRAIGHT;
                        end else nextState = LEFT;
                    end
                   // Nothing Change(6)
                    RIGHT_ROAD, RIGHT_LITTLE_ROAD:nextState = LEFT;
                    LEFT_ROAD, LEFT_LITTLE_ROAD:nextState = LEFT;
                    STRAIGHT_ROAD: nextState = LEFT;
                    ERROR_ROAD: nextState = LEFT;
                    default :  nextState = LEFT;
                endcase
            end
            
            LITTLE_LEFT:begin//slightly fixing direction when going straight
                case(detect)
                   // ERROR STATE(0)
                    
                   // Transform state(2)
                    ERROR_ROAD: begin 
                        nextState =  STOP;
                        // transitionState = BACK;
                    end
                    TURN_ROAD111: nextState = (checkPoint2) ? CHOOSE : STRAIGHT;
                   // Nothing Change(6)
                    RIGHT_ROAD, LEFT_ROAD: nextState = STRAIGHT;
                    RIGHT_LITTLE_ROAD: nextState = LITTLE_RIGHT;
                    LEFT_LITTLE_ROAD: nextState = LITTLE_LEFT;
                    TURN_ROAD101: nextState = STRAIGHT;
                    STRAIGHT_ROAD: nextState = STRAIGHT;                  
                    default :  nextState = LITTLE_LEFT;
                endcase
            end
            
            RIGHT:begin
                case(detect)
                   // ERROR STATE(0)                    
                   // Transform state(2)
                    TURN_ROAD101: nextState = (DoneRight) ? ERROR : RIGHT;
                    TURN_ROAD111: begin
                        if(checkPoint4 && DoneRight)begin
                            // transitionState = STRAIGHT;
                            nextState = STOP;
                        end else nextState = RIGHT;
                    end
                   // Nothing Change(6)
                    RIGHT_ROAD, RIGHT_LITTLE_ROAD:nextState = RIGHT;
                    LEFT_ROAD, LEFT_LITTLE_ROAD:nextState = RIGHT;
                    STRAIGHT_ROAD: nextState = RIGHT;
                    ERROR_ROAD: nextState = RIGHT;
                    default :  nextState = RIGHT;
                endcase
            end
            
            LITTLE_RIGHT:begin//slightly fixing direction when going straight
                case(detect)
                   // ERROR STATE(0)
                    
                   // Transform state(2)
                    ERROR_ROAD: begin 
                        nextState =  STOP;
                        // transitionState = BACK;
                    end
                    TURN_ROAD111: nextState = (checkPoint2) ? CHOOSE : STRAIGHT;
                   // Nothing Change(6)
                    RIGHT_ROAD, LEFT_ROAD: nextState = STRAIGHT;
                    RIGHT_LITTLE_ROAD: nextState = LITTLE_RIGHT;
                    LEFT_LITTLE_ROAD: nextState = LITTLE_LEFT;
                    TURN_ROAD101: nextState = STRAIGHT;
                    STRAIGHT_ROAD: nextState = STRAIGHT;    
                    default :  nextState = LITTLE_RIGHT;
                endcase
            end
                        
            BACK:begin
                case(detect)
                   // ERROR STATE(0)
                    
                   // Transform state(1)
                    TURN_ROAD111: begin
                        // if(pop==2'd0)begin
                        //     nextState = STOP;
                        //     transitionState = LEFT;
                        // end else if(pop==2'd1) begin
                        //     nextState = STOP;
                        //     transitionState = RIGHT;
                        // end
                        nextState = STOP;
                    end
                   // Nothing Change(7)
                    RIGHT_ROAD, RIGHT_LITTLE_ROAD:nextState = BACK;
                    LEFT_ROAD, LEFT_LITTLE_ROAD:nextState = BACK;
                    ERROR_ROAD: nextState = BACK;
                    TURN_ROAD101: nextState = BACK;
                    STRAIGHT_ROAD: nextState = BACK;
                    default :  nextState = BACK;
                endcase
            end

            STOP:nextState = (reSTART)? transitionState : STOP;
         
            ERROR: nextState = (~sw[0]) ? IDLE : ERROR;
            
            default : nextState = state;
        endcase
    end
  
  // led display
    // led right 3: show detect info
        reg [2:0]led_right; 
        always @(*)begin
            case(detect)
                ERROR_ROAD: led_right = 3'b000;
                RIGHT_ROAD: led_right = 3'b011;
                STRAIGHT_ROAD: led_right = 3'b010;
                RIGHT_LITTLE_ROAD: led_right = 3'b001;
                LEFT_ROAD: led_right = 3'b110;
                TURN_ROAD101: led_right = 3'b101;
                LEFT_LITTLE_ROAD: led_right = 3'b100;
                TURN_ROAD111: led_right = 3'b111;
                default : led_right = 3'b000;
            endcase
        end
    // led left 5: Led state info 
        reg [4:0]led_left;
        reg [2:0]choose_lamp;
        reg [31:0]cnt;
        always @(posedge clk or posedge rst) begin
            if(rst) begin
                cnt <= 0;
                choose_lamp <= 3'b001;
            end 
            else if(state == CHOOSE) begin
                cnt <= cnt + 1;
                if(cnt == 31'd30000000) begin
                    cnt <= 0;
                    choose_lamp <= {choose_lamp[1:0], choose_lamp[2]}; 
                end
            end
            else begin
                choose_lamp <= 3'b001;
                cnt <= 0;
            end
        end
        always @(*) begin
            case (state)
                IDLE: led_left = 5'd0;
                START: led_left = 5'd1;
                COUNT: led_left = 5'b00010;
                STRAIGHT: led_left = 5'b01000;
                CHOOSE:led_left = {choose_lamp , 2'd0};
                LEFT : led_left = 5'b10000;
                RIGHT: led_left = 5'b00100;
                STOP:led_left = 5'b11100;
                BACK:led_left = 5'b01010;
                ERROR: led_left = 5'b11111;
                default:led_left = 5'd0;
            endcase
        end
    // led middle [15 14 13 12 11] [10] [9 - 4] [3] [2 1 0]:
    // [9 8 7 6 5 4]: count
        reg [5:0]led_middle;
        always @(*)begin
            case (state)
                COUNT: led_middle = (flash) ? 6'd0 : 6'b111111;
                STRAIGHT: led_middle = 6'b001100;
                RIGHT: led_middle = 6'b0000011;
                LEFT: led_middle = 6'b110000;
                STOP: led_middle = 6'b111111;
                BACK: led_middle = (flashBack) ? 6'd0:6'b111111;
                default:led_middle = 6'd0;
            endcase
        end
    assign LED = {led_left,1'd0, led_middle ,1'd0,led_right};
    assign nums = {num0, num1, num2, num3};

  // Seven Segment
    always @(*)begin
    end
  // Senser module
    SevenSegment(
	    .display(DISPLAY),
	    .digit(DIGIT),
	    .nums(nums),
	    .rst(rst),
	    .clk(clk)
    );
    motor A(
        .clk(clk),
        .rst(rst),
        .mode(state),
        .lastMode(lastState),
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