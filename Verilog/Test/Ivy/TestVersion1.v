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
    output right_pwm
  );
  // Wire, Reg signal
    reg [4:0]state, nextState;
    wire [2:0]detect;
    wire [19:0] distance;
    localparam [2:0]ERROR_ROAD = 3'b000;
    localparam [2:0]RIGHT_ROAD = 3'b001;
    localparam [2:0]STRAIGHT_ROAD = 3'b010;
    localparam [2:0]RIGHT_LITTLE_ROAD = 3'b011;
    localparam [2:0]LEFT_ROAD = 3'b100;
    localparam [2:0]TURN_ROAD101 = 3'b101;
    localparam [2:0]LEFT_LITTLE_ROAD = 3'b110;
    localparam [2:0]TURN_ROAD111 = 3'b111;

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
    localparam [4:0]BACK_LEFT = 5'd8;
    localparam [4:0]STOP = 5'd30;
    localparam [4:0]ERROR = 5'd31;

  // Counter signal
    wire countEnable = (state == COUNT)? 1:0;
    wire flash;
    wire countFinish;
    clockDriver cD( .clk(clk), .countEnable(countEnable), .countFinish(countFinish), .flash(flash));
    wire countSTOP = (state == STOP) ? 1:0;
    wire reSTART;
    reg [4:0]transitionState;
    clockDriver1 cD1( .clk(clk), .countEnable(countSTOP), .flash(reSTART));
    
  // Checkpoint setting
    // cp1: from straight(111) to choose(111)
    // cp2: from left(111) to straight(111)
    // cp3: from stop(111) to left(111)
    // cp4: from stop(111) to right(111)
    reg checkPoint1,checkPoint2,checkPoint3,checkPoint4;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            checkPoint1 <= 0;
            checkPoint2 <= 0;
            checkPoint3 <= 0;
            checkPoint4 <= 0;
        end else begin
            // straight -> choose(only detect 000)
            if(state == CHOOSE && detect == 3'b000) 
                checkPoint1 <= 1;
            else if(state != CHOOSE)checkPoint1 <= 0;
            
            // left -> straight(may detect 010 or 000)
            if (state == STRAIGHT && detect != 3'b111) checkPoint2 <= 1;
            else if(state != STRAIGHT)checkPoint2 <= 0;      

            // back/stop -> left(may detect anything)     
            if(state == LEFT && detect != 3'b111) checkPoint3 <= 1;
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
    reg [1:0]pop;
    

  // FSM transform sequencial
    always @(posedge clk or posedge clk)begin
        if(rst || sw[0] == 0) state <= IDLE;
        else state <= nextState;
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
  // FSM transform combination
    always @(*)begin
        case(state)
            IDLE: nextState = (sw[0])? START : IDLE;
            
            START: nextState = (detect == 3'b010) ? COUNT : START;
            
            COUNT: nextState = (countFinish) ? STRAIGHT: COUNT;
            
            STRAIGHT:begin
                case(detect)
                   // ERROR STATE(5)
                    RIGHT_ROAD, RIGHT_LITTLE_ROAD: nextState = ERROR;
                    LEFT_ROAD, LEFT_LITTLE_ROAD: nextState = ERROR;
                    TURN_ROAD101: nextState = ERROR;
                   // Transform state(2)
                   // TODO: STRAIGHT -> BACK (need insert STOP betweem two state)
                    ERROR_ROAD: begin 
                        nextState =  STOP;
                        transitionState = BACK;
                    end
                    TURN_ROAD111: nextState = (checkPoint2) ? CHOOSE : STRAIGHT;
                   // Nothing Change(1)
                    STRAIGHT_ROAD: nextState = STRAIGHT;                  
                    default : nextState = STRAIGHT;
                endcase
            end
            
            CHOOSE: begin  // find 下一個檢查點
                case(detect)
                   // ERROR STATE(5)
                    RIGHT_ROAD, RIGHT_LITTLE_ROAD:nextState = ERROR;
                    LEFT_ROAD, LEFT_LITTLE_ROAD:nextState = ERROR;
                    STRAIGHT_ROAD: nextState = ERROR;
                   // Transform state(2)
                    TURN_ROAD101: nextState = LEFT;
                    TURN_ROAD111: nextState = (checkPoint1)? STRAIGHT : CHOOSE;
                   // Nothing Change(1)
                    ERROR_ROAD: nextState = CHOOSE;
                    default :  nextState = CHOOSE;
                endcase
            end

            LEFT:begin
                case(detect)
                   // ERROR STATE(0)
                    
                   // Transform state(2)
                    TURN_ROAD101: nextState = RIGHT;
                    TURN_ROAD111: nextState = (checkPoint3)? STRAIGHT : LEFT;
                   // Nothing Change(6)
                    RIGHT_ROAD, RIGHT_LITTLE_ROAD:nextState = LEFT;
                    LEFT_ROAD, LEFT_LITTLE_ROAD:nextState = LEFT;
                    STRAIGHT_ROAD: nextState = LEFT;
                    ERROR_ROAD: nextState = LEFT;
                    default :  nextState = LEFT;
                endcase
            end
            
            RIGHT:begin
                case(detect)
                   // ERROR STATE(0)                    
                   // Transform state(2)
                    TURN_ROAD101: nextState = (DoneRight) ? ERROR : RIGHT;
                    TURN_ROAD111: nextState = (checkPoint4 && DoneRight)? STRAIGHT : RIGHT;
                   // Nothing Change(6)
                    RIGHT_ROAD, RIGHT_LITTLE_ROAD:nextState = RIGHT;
                    LEFT_ROAD, LEFT_LITTLE_ROAD:nextState = RIGHT;
                    STRAIGHT_ROAD: nextState = RIGHT;
                    ERROR_ROAD: nextState = RIGHT;
                    default :  nextState = RIGHT;
                endcase
            end
            
            BACK:begin
                case(detect)
                   // ERROR STATE(6)
                    RIGHT_ROAD, RIGHT_LITTLE_ROAD:nextState = ERROR;
                    LEFT_ROAD, LEFT_LITTLE_ROAD:nextState = ERROR;
                    ERROR_ROAD: nextState = ERROR;
                    TURN_ROAD101: nextState = ERROR;
                    
                   // Transform state(1)
                    TURN_ROAD111: begin
                        if(pop==2'd0)begin
                            nextState = STOP;
                            transitionState = LEFT;
                        end else if(pop==2'd1) begin
                            nextState = STOP;
                            transitionState = RIGHT;
                        end
                    end
                   // Nothing Change(1)
                    STRAIGHT_ROAD: nextState = BACK;
                    default :  nextState = BACK;
                endcase
            end

            STOP:nextState = (reSTART)?transitionState : STOP;
                       
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
            RIGHT_ROAD: led_right = 3'b001;
            STRAIGHT_ROAD: led_right = 3'b010;
            RIGHT_LITTLE_ROAD: led_right = 3'b011;
            LEFT_ROAD: led_right = 3'b100;
            TURN_ROAD101: led_right = 3'b101;
            LEFT_LITTLE_ROAD: led_right = 3'b110;
            TURN_ROAD111: led_right = 3'b111;
            default : led_right = 3'b000;
        endcase
    end
    // led left 5: Led state info 
    reg [4:0]led_left;
    reg [2:0]choose_lamp;
    reg [23:0]cnt;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt <= 0;
            choose_lamp <= 3'b001;
        end 
        else if(state == CHOOSE) begin
            cnt <= cnt + 1;
            if(cnt == 24'd500000) begin
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
            default:led_left = 6'd0;
        endcase
    end
    assign LED = {led_left,1'd0, led_middle ,1'd0,led_right};
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