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
    localparam [4:0]TURN_LEFT = 5'd5;
    // localparam [4:0]RIGHT = 5'd6;
    // localparam [4:0]BACK = 5'd7;
    // localparam [4:0]STOP = 5'd8;
    localparam [4:0]ERROR = 5'd31;

  // Counter signal
    wire countEnable = (state == COUNT)? 1:0;
    wire flash;
    wire countFinish;
    clockDriver cD( .clk(clk), .countEnable(countEnable), .countFinish(countFinish), .flash(flash));
    reg checkPoint1;
    always @(posedge clk or posedge rst) begin
        if(rst)
            checkPoint1 <= 0;
        else if(state == CHOOSE && detect == 3'b000)
            checkPoint1 <= 1;
        else if(state != CHOOSE)
            checkPoint1 <= 0;
    end

  // Turn detect, record signal
    // reg [1:0]turnDirection;
    // reg [31:0]turnRecord; // stake
    

  // FSM transform  
    always @(posedge clk or posedge clk)begin
        if(rst || sw[0] == 0) state <= IDLE;
        else state <= nextState;
    end
    
    always @(*)begin
        case(state)
            IDLE: nextState = (sw[0])? START : IDLE;
            START: nextState = (detect == 3'b010) ? COUNT : START;
            COUNT: nextState = (countFinish) ? STRAIGHT: COUNT;
            STRAIGHT:begin
                case(detect)
                   ERROR_ROAD: nextState = STRAIGHT;
                   RIGHT_ROAD: nextState = ERROR;
                   RIGHT_LITTLE_ROAD: nextState = ERROR;
                   LEFT_ROAD: nextState = ERROR;
                   LEFT_LITTLE_ROAD: nextState = ERROR;


                   STRAIGHT_ROAD: nextState = STRAIGHT;
                   TURN_ROAD111: nextState = CHOOSE;
                   TURN_ROAD101: nextState = ERROR; // Turn 之前不會遇到101 detect
                   default : nextState = STRAIGHT;
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
                   TURN_ROAD111: nextState = (checkPoint1)? STRAIGHT : CHOOSE;
                    default :  nextState = CHOOSE;
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
            TURN_LEFT: begin 
                case(detect)
                   ERROR_ROAD: nextState = TURN_LEFT;
                   RIGHT_ROAD:nextState = TURN_LEFT;
                   RIGHT_LITTLE_ROAD:nextState = TURN_LEFT;
                   LEFT_ROAD:nextState = TURN_LEFT;
                   LEFT_LITTLE_ROAD:nextState = TURN_LEFT;
                   STRAIGHT_ROAD:nextState = TURN_LEFT;
                endcase
            end


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