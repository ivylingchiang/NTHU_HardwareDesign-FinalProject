module mainModule(
    input clk,
    input rst,
    input echo,
    input left_track,
    input right_track,
    input mid_track,
    input wire [15:0]sw,
    output wire [15:0]LED,
    input wire MISO,
    output wire SS,
    output wire MOSI,
    output wire SCLK,
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
  // Parameter: FSM, Detect tracker
    // FSM
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
        localparam [4:0]CHOOSE_DIR_STEP1 =  5'd10;
        localparam [4:0]CHOOSE_DIR_STEP2 =  5'd11;
        localparam [4:0]CHOOSE_DIR_STEP3 =  5'd12;
        localparam [4:0]FINISH = 5'd29;
        localparam [4:0]STOP = 5'd30;
        localparam [4:0]ERROR = 5'd31;
    // Detect tracker
        localparam [2:0]ERROR_ROAD = 3'b000;
        localparam [2:0]RIGHT_ROAD = 3'b011;
        localparam [2:0]STRAIGHT_ROAD = 3'b010;
        localparam [2:0]RIGHT_LITTLE_ROAD = 3'b001;
        localparam [2:0]LEFT_ROAD = 3'b110;
        localparam [2:0]TURN_ROAD101 = 3'b101;
        localparam [2:0]LEFT_LITTLE_ROAD = 3'b100;
        localparam [2:0]TURN_ROAD111 = 3'b111;
    // Mem
        localparam [1:0] DEC_STRAIGHT  = 2'b01;
        localparam [1:0] DEC_LEFT  = 2'b10;
        localparam [1:0] DEC_RIGHT = 2'b11;
        parameter MEM_DEPTH = 50;
        parameter LAST_MEM_INDEX = MEM_DEPTH - 1;

  // Signal: wire, reg
    // System signal
        // debounce, one pulse
            wire rst_d,rst_op;
        // FSM signal
            reg [4:0]state, nextState, lastState;
            reg [4:0]transitionState;
            reg [4:0]storeState, lastStoreState;
        // Distence signal
            wire mode;
            wire [19:0] distance;
        // Tracker signal
            wire [2:0]detect;
        // Checkpoint setting
            // cp1: from straight(111) to choose(111)
            // cp2: from left(111) to straight(111)
            // cp3: from stop(111) to left(111)
            // cp4: from stop(111) to right(111)
            // cp5: from choose(101) to left(101)
            reg checkPoint1,checkPoint2,checkPoint3,checkPoint4, checkPoint5;
        // Stack singal
            reg pop;
            reg [4:0] index;
            reg [4:0] indexM;
            integer rst_index;
            reg [1:0] mem [0:LAST_MEM_INDEX];
            reg [1:0] memManual [0:LAST_MEM_INDEX];
            reg pushDecision, pushDecision_s;
            reg popDecision, popDecision_s;
            reg pushDecision2, pushDecision_s2;
            reg popDecision2, popDecision_s2;
            reg [1:0]addVal;
            reg [1:0]storeDir;
        // Joystick signal
            wire [1:0] joyStickDir;
            wire joyStickButton;
            reg joyStickButton_s;
            wire pressButton;
            reg [4:0]chosenState;
    // Sys.Counter signal
        // Counter Enable signal
            wire clk_update;
            wire countEnable;
            wire backEn; 
            wire countSTOP;
        // Counter Return
            wire flash;
            wire countFinish;
            wire [1:0]countDetail;
            wire reSTART;
            wire flashBack;
        // Main module counter
            // #turn right
            reg [1:0]counterRight;
            reg DoneRight;
            reg control;
            reg control_s;
            // #led display routine
            reg [2:0]choose_lamp;
            reg [31:0]cnt;
    // IO signal
        // Seven Segment signal
            wire [15:0]nums;
            wire [15:0]display;
            wire num_override;
            reg [3:0] num0, num1, num2, num3;
            reg [3:0] shift_reg [0:3];  
            reg [5:0] mem_idx;          
            reg [2:0] valid_cnt; 
            reg done;
        // Led signal
            reg [5:0]led_middle;
            reg [2:0]led_right;
            reg [4:0]led_left;
  
  // Assign Block
    // Distence
        assign mode = (distance < 2) ? 1 : 0;
    // Counter Enable signal
        assign countEnable = (state == COUNT)? 1:0;
        assign countSTOP = (state == STOP) ? 1 : 0;
        assign backEn = (state == BACK) ? 1:0;
    // Led display && SevenSegment
        assign LED = (state == FINISH) ?  {16'b1111_1111_1111_1111}:{led_left,1'd0, led_middle ,1'd0,led_right};
        assign nums =  (state == FINISH) ? display : {num0, num1, num2, num3};
        assign display ={shift_reg[3],shift_reg[2],shift_reg[1],shift_reg[0]};   
    // Joystick
        assign pressButton = (!joyStickButton_s && joyStickButton) ;

  // Circuit 
    // System
        // Sys.Counter Update
            // #turn right
                always @(posedge clk)begin
                    control_s <= control;
                    if(state == RIGHT && detect == 3'b111)begin
                        control <= 1;
                    end else control <= 0;
                end
                always @(posedge clk)begin
                    if(checkPoint4 && state == RIGHT && detect == 3'b111)begin
                        if(control && !control_s)
                            counterRight <= counterRight +1;
                        
                        if(counterRight >= 2) DoneRight <= 1;
                    end else if(state != RIGHT) begin 
                        counterRight <= 0;
                        DoneRight <= 0;
                    end
                end
            // led display
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
        // "CHECKPOINT" && "STACK-StorePOP" && "STATE-StoreSTARE" Update
            always @(posedge clk) begin
                if(rst) begin
                    checkPoint1 <= 0;
                    checkPoint2 <= 0;
                    checkPoint3 <= 0;
                    checkPoint4 <= 0;
                    checkPoint5 <= 0;
                    storeState <= LEFT; 
                end else begin
                    storeState <= transitionState;
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
                    // choose(101) -> left(101)
                    if(state == LEFT && detect != 3'b101) checkPoint5 <= 1;
                    else if(state != LEFT) checkPoint5<=0;
                end
            end
        // FSM
            // "CHOOSE" Update:sequential
                always@(posedge clk,posedge rst)begin
                    if(rst)begin
                        joyStickButton_s <= 0;
                        chosenState <= STRAIGHT;
                    end
                    else begin
                        joyStickButton_s <= joyStickButton;
                        if(state == CHOOSE_DIR_STEP1)begin
                            if(pressButton)begin
                                case(joyStickDir)
                                2'b00: chosenState<= LEFT;
                                2'b01:chosenState <= STRAIGHT; 
                                2'b10: chosenState <= RIGHT;
                                // 2'b11:chosenState <= LEFT;
                                default:chosenState <= STRAIGHT;
                                endcase
                            end
                        end
                    end
                end
            // "STATE" Update: Sequencial
                always @(posedge clk or posedge rst)begin
                    if(rst || sw[0] == 0) state <= IDLE;
                    else if (mode)begin
                        state <= FINISH;
                    end
                    else begin
                        state <= nextState;
                        lastState <= state;
                    end
                end
            // "NEXTSTATE" Update: Combinational
                always @(*)begin
                    if(mode) nextState = FINISH;
                    else begin
                        case(state)
                            IDLE: nextState = (sw[0])? START : IDLE;
                            
                            START: nextState = (detect == 3'b010) ? COUNT : START;
                            
                            COUNT: nextState = (countFinish) ? STRAIGHT: COUNT;
                            
                            STRAIGHT:begin
                                case(detect)
                                // ERROR STATE(0)
                                    
                                // Transform state(2)
                                    ERROR_ROAD: begin 
                                        // transitionState = BACK;
                                        nextState =  STOP;                        
                                    end
                                    TURN_ROAD111: nextState = (checkPoint2) ? CHOOSE : STRAIGHT;
                                // Nothing Change(6)
                                    RIGHT_ROAD, RIGHT_LITTLE_ROAD: nextState = LITTLE_RIGHT;
                                    LEFT_ROAD, LEFT_LITTLE_ROAD: nextState = LITTLE_LEFT;
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
                                        // transitionState = LEFT;
                                        nextState = STOP;                        
                                    end
                                    TURN_ROAD111:begin//nextState = (checkPoint1)? STRAIGHT : CHOOSE;
                                        if(sw[1])begin
                                            nextState = (checkPoint1)? CHOOSE_DIR_STEP1 : CHOOSE;
                                        end
                                        else begin
                                            nextState = (checkPoint1)? STRAIGHT : CHOOSE;
                                        end
                                    end
                                // Nothing Change(6)
                                    ERROR_ROAD: nextState = CHOOSE;
                                    RIGHT_ROAD, RIGHT_LITTLE_ROAD:nextState = CHOOSE;
                                    LEFT_ROAD, LEFT_LITTLE_ROAD:nextState = CHOOSE;
                                    STRAIGHT_ROAD: nextState = CHOOSE;
                                    default :  nextState = CHOOSE;
                                endcase
                            end
                            CHOOSE_DIR_STEP1:begin
                                if(pressButton)begin
                                    case(joyStickDir)
                                    2'b00: begin
                                        nextState = STRAIGHT;
                                    end
                                    // 2'b01:chosenState = RIGHT;
                                    // 2'b11:chosenState = LEFT;
                                    default:nextState = CHOOSE_DIR_STEP2;
                                    endcase
                                end
                                else nextState = CHOOSE_DIR_STEP1;
                            end
                            CHOOSE_DIR_STEP2:begin //choose
                                if(detect != 3'b111)nextState = CHOOSE_DIR_STEP3;
                                else nextState = CHOOSE_DIR_STEP2;
                            end
                            CHOOSE_DIR_STEP3:begin
                                nextState = chosenState;
                            end
                        
                            
                            LEFT:begin
                                case(detect)
                                // ERROR STATE(0)
                                    
                                // Transform state(2)
                                    TURN_ROAD101: begin
                                        // transitionState = RIGHT;
                                        if(checkPoint5)begin
                                            nextState = STOP;
                                        end else begin
                                            nextState = LEFT;
                                        end                      
                                    end
                                    TURN_ROAD111: begin
                                        if(checkPoint3)begin
                                            // transitionState = STRAIGHT;
                                            nextState = STOP;                 
                                        end else begin
                                            nextState = LEFT;
                                        end
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
                                        // transitionState = BACK;
                                        nextState =  STOP;
                                    end
                                    TURN_ROAD111: nextState = (checkPoint2) ? CHOOSE : STRAIGHT;
                                // Nothing Change(6)
                                    RIGHT_ROAD, RIGHT_LITTLE_ROAD: nextState = LITTLE_RIGHT;
                                    LEFT_ROAD, LEFT_LITTLE_ROAD: nextState = LITTLE_LEFT;
                                    TURN_ROAD101: nextState = STRAIGHT;
                                    STRAIGHT_ROAD: nextState = STRAIGHT;                  
                                    default :  nextState = LITTLE_LEFT;
                                endcase
                            end
                            
                            RIGHT:begin
                                if(!sw[1])begin
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
                                end else begin
                                    case(detect)
                                    // ERROR STATE(0)                    
                                    // Transform state(2)
                                        TURN_ROAD101: nextState = CHOOSE_DIR_STEP1;
                                        TURN_ROAD111: begin
                                            if(checkPoint4)begin
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
                            end
                            
                            LITTLE_RIGHT:begin//slightly fixing direction when going straight
                                case(detect)
                                // ERROR STATE(0)
                                    
                                // Transform state(2)
                                    ERROR_ROAD: begin 
                                        // transitionState = BACK;
                                        nextState =  STOP;
                                    end
                                    TURN_ROAD111: nextState = (checkPoint2) ? CHOOSE : STRAIGHT;
                                // Nothing Change(6)
                                    RIGHT_ROAD, RIGHT_LITTLE_ROAD: nextState = LITTLE_RIGHT;
                                    LEFT_ROAD, LEFT_LITTLE_ROAD: nextState = LITTLE_LEFT;
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
                                        // transitionState = LEFT;
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

                            STOP: nextState = (reSTART)? storeState : STOP;
                        
                            ERROR: nextState = (~sw[0]) ? IDLE : ERROR;
                            
                            default : nextState = state;
                        endcase
                    end
                end
            // "TRANSITIONSTATE" && "POP" && "Push/Pop_Stack" Update: Combinational
                // TransitionState
                    always @(*)begin
                        transitionState = storeState;
                        case(state)
                            STRAIGHT, LITTLE_LEFT,LITTLE_RIGHT: begin
                                transitionState = (detect == ERROR_ROAD) ? BACK : STRAIGHT;
                            end
                            CHOOSE: begin
                                if(sw[1]) transitionState = (detect == TURN_ROAD101) ? CHOOSE_DIR_STEP1 : CHOOSE;
                                else transitionState = (detect == TURN_ROAD101) ? LEFT : CHOOSE;
                            end
                            LEFT: begin
                                if(sw[1]) begin
                                    if(detect == TURN_ROAD101) transitionState = CHOOSE_DIR_STEP1;
                                    else if (detect == TURN_ROAD111) transitionState = STRAIGHT;
                                    else transitionState = LEFT;
                                end else begin
                                    if(detect == TURN_ROAD101) transitionState = RIGHT;
                                    else if (detect == TURN_ROAD111) transitionState = STRAIGHT;
                                    else transitionState = LEFT;
                                end
                            end
                            RIGHT: begin
                                if(sw[1]) begin
                                    if(detect == TURN_ROAD101) transitionState = CHOOSE_DIR_STEP1;
                                    else if (detect == TURN_ROAD111) transitionState = STRAIGHT;
                                    else transitionState = RIGHT;
                                end
                                else transitionState = (detect == TURN_ROAD111) ? STRAIGHT : RIGHT;
                            end
                            BACK: begin  
                                if(sw[1])begin
                                    if(detect == 3'b111)begin
                                        transitionState = CHOOSE_DIR_STEP1;
                                    end else transitionState = BACK;
                                end else begin
                                    if(detect == 3'b111 && mem[index] == DEC_STRAIGHT)begin
                                            transitionState = LEFT;
                                    end else if(detect == 3'b111 && mem[index] == DEC_LEFT)begin
                                            transitionState = RIGHT;    
                                    end else transitionState = BACK;
                                end
                            end
                        endcase
                    end
                // AUTO + Manual
                    always @(*)begin
                        pushDecision2 = 0;
                        popDecision2 = 0;
                        pushDecision = 0;
                        popDecision = 0;
                        storeDir = 0;
                        addVal = 0;
                        if(sw[1])begin // Manual
                            case(state)
                                STRAIGHT, LITTLE_LEFT,LITTLE_RIGHT: begin
                                    if(detect == TURN_ROAD111 && checkPoint2)begin
                                        pushDecision2 = 1;
                                        popDecision2 = 1;
                                        storeDir = memManual[indexM]; // 1
                                    end
                                end
                                CHOOSE_DIR_STEP1: begin
                                    if(joyStickDir == STRAIGHT) begin
                                        storeDir = memManual[indexM];
                                        pushDecision2 = 1;
                                        popDecision2 = 1;
                                    end
                                end
                                CHOOSE_DIR_STEP3: begin
                                    pushDecision2 = 1;
                                    popDecision2 = 1;
                                    case (chosenState)
                                        LEFT: storeDir = ( memManual[indexM] + 1 ) % 3;
                                        RIGHT: storeDir = ( memManual[indexM] + 2 ) % 3;
                                    endcase
                                end
                            endcase
                        end else begin // AUTO
                            case(state)
                                STRAIGHT, LITTLE_LEFT,LITTLE_RIGHT: begin
                                    if(detect == TURN_ROAD111 && checkPoint2)begin
                                        pushDecision = 1;
                                        addVal = DEC_STRAIGHT;
                                    end
                                end
                                CHOOSE: begin
                                    if(detect == TURN_ROAD101)begin
                                        // transitionState = LEFT;
                                        pushDecision = 1;
                                        popDecision = 1;
                                        addVal = DEC_LEFT;
                                    end
                                    // else transitionState = CHOOSE;
                                end
                                LEFT: begin
                                    if(detect == TURN_ROAD101)begin
                                        // transitionState = RIGHT;
                                        pushDecision = 1;
                                        popDecision = 1;
                                        addVal = DEC_RIGHT;
                                    end
                                    // else if (detect == TURN_ROAD111) transitionState = STRAIGHT;
                                    // else transitionState = LEFT;
                                end
                                // RIGHT: transitionState = (detect == TURN_ROAD111) ? STRAIGHT : RIGHT;
                                BACK: begin                            
                                    if(detect == 3'b111)begin
                                        if(mem[index] == DEC_STRAIGHT)begin
                                            // transitionState = LEFT;
                                            pushDecision = 1;
                                            popDecision = 1;
                                            addVal = DEC_LEFT; 
                                        end
                                        else if(mem[index] == DEC_LEFT)begin
                                            // transitionState = RIGHT;
                                            pushDecision = 1;
                                            popDecision = 1;
                                            addVal = DEC_RIGHT;
                                        // end else transitionState = BACK;
                                        end
                                    end
                                end
                            endcase
                        end
                    end
            // "TRANSITIONSTATE" && "POP" && "STACK" Update: Sequential
                // AUTO
                always@(posedge clk,posedge rst)begin
                    if(rst)begin
                        index <= 0;
                        for(rst_index = 0; rst_index <= 49; rst_index = rst_index + 1)begin
                            mem[rst_index] <= 2'b00;
                        end

                        pushDecision_s <= 0;
                        popDecision_s <= 0;
                    end
                    else begin
                        pushDecision_s <= pushDecision;
                        popDecision_s <= popDecision;
                        if(!pushDecision_s && pushDecision && !popDecision_s && popDecision)begin
                            mem[index] <= addVal;
                        end
                        else if(!pushDecision_s && pushDecision)begin
                            if(index < MEM_DEPTH - 1)begin
                                mem[index + 1] <= addVal;
                                index <= index + 1;
                            end
                        end
                        else if(!popDecision_s && popDecision)begin
                            if(index > 0)begin
                                mem[index] <= 2'b00;
                                index <= index - 1;
                            end
                        end
                    end
                end
                //Manual
                always@(posedge clk,posedge rst)begin
                    if(rst)begin
                        indexM <= 0;
                        for(rst_index = 0; rst_index <= 49; rst_index = rst_index + 1)begin
                            memManual[rst_index] <= 2'b00;
                        end
                        pushDecision_s2 <= 0;
                        popDecision_s2 <= 0;
                    end
                    else begin
                        pushDecision_s2 <= pushDecision2;
                        popDecision_s2 <= popDecision2;
                        if(!pushDecision_s2 && pushDecision2 && !popDecision_s && popDecision2)begin
                            memManual[indexM] <= storeDir;
                        end
                        else if(!pushDecision_s2 && pushDecision2)begin
                            if(indexM < MEM_DEPTH - 1)begin
                                memManual[indexM + 1] <= storeDir;
                                indexM <= indexM + 1;
                            end
                        end
                        else if(!popDecision_s2 && popDecision2)begin
                            if(indexM > 0)begin
                                memManual[indexM] <= 2'b00;
                                indexM <= indexM - 1;
                            end
                        end
                    end
                end

    // IO
        // SevenSegment Display
            always @(*)begin
                // num0 = 4'd0;
                // num1 = 4'd0;
                // num2 = 4'd0;
                // num3 = {2'b00,joyStickDir};
                case(state)
                    IDLE: begin
                        // num0 = 4'd1;
                        // num1 = 4'd12;
                        // num2 = 4'd13;
                        // num3 = 4'd14;
                        num0 = 4'd0;
                        num1 = 4'd0;
                        num2 = 4'd0;
                        num3 = {2'b00,joyStickDir};
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
                    CHOOSE_DIR_STEP1,CHOOSE_DIR_STEP2,CHOOSE_DIR_STEP3: begin
                        num0 = 4'd0;
                        num1 = 4'd0;
                        num2 = 4'd0;
                        num3 = {2'b00,joyStickDir};
                    end
                    LEFT: begin
                        num0 = 4'd10;
                        num1 = 4'd3;
                        num2 = 4'd11;
                        num3 = (checkPoint3) ? 4'd1:4'd0;
                    end
                    RIGHT: begin
                        num0 = 4'd4;
                        num1 = (checkPoint4) ? 4'd1:4'd0;
                        num2 = 4'd11;
                        num3 = (counterRight == 2'd0)? 4'd0: (counterRight == 2'd1) ? 4'd1:4'd2;
                    end
                    BACK: begin
                        num0 = 4'd11; //-
                        num1 = 4'd0;
                        num2 = 4'd0;
                        case(storeState)
                            IDLE: num3 = 4'd12;
                            STRAIGHT: num3 = 4'd1;
                            LEFT: num3 = 4'd13;
                            RIGHT: num3 = 4'd15;
                            BACK: num3 = 4'd11; //-
                            default : num3 = 4'd0;
                        endcase
                    end
                    STOP: begin
                        num0 = (reSTART)? 4'd1 : 4'd0;
                        num1 = 4'd0;
                        num2 = 4'd0;
                        case(storeState)
                            IDLE: num3 = 4'd12;
                            STRAIGHT: num3 = 4'd1;
                            LEFT: num3 = 4'd13;
                            RIGHT: num3 = 4'd15;
                            BACK: num3 = 4'd11;
                            default : num3 = 4'd0;
                        endcase
                    end
                    default : begin
                        num0 = 4'd0;
                        num1 = 4'd0;
                        num2 = 4'd0;
                        num3 = 4'd0;
                    end
                endcase
            end
            always @(posedge clk_update) begin
                if (state != FINISH) begin
                    shift_reg[0] <= 4'd0;
                    shift_reg[1] <= 4'd0;
                    shift_reg[2] <= 4'd0;
                    shift_reg[3] <= 4'd0;
                    mem_idx <= 0;
                    valid_cnt <= 0;
                    done <= 0;
                end
                else if (!done) begin
                    if(sw[1])begin
                        shift_reg[3] <= shift_reg[2];
                        shift_reg[2] <= shift_reg[1];
                        shift_reg[1] <= shift_reg[0];
                        if (memManual[mem_idx] != 2'd0) begin
                            shift_reg[0] <={2'd0, memManual[mem_idx]};
                        end else begin
                            shift_reg[0] <= 4'd0;
                            valid_cnt <= valid_cnt + 1;
                        end
                        mem_idx <= mem_idx + 1;
                        if (mem_idx == LAST_MEM_INDEX || valid_cnt >= 4) begin
                            done <= 1'b1;
                        end
                    end else begin
                        shift_reg[3] <= shift_reg[2];
                        shift_reg[2] <= shift_reg[1];
                        shift_reg[1] <= shift_reg[0];
                        if (mem[mem_idx] != 2'd0) begin
                            shift_reg[0] <={2'd0, mem[mem_idx]};
                        end else begin
                            shift_reg[0] <= 4'd0;
                            valid_cnt <= valid_cnt + 1;
                        end
                        mem_idx <= mem_idx + 1;
                        if (mem_idx == LAST_MEM_INDEX || valid_cnt >= 4) begin
                            done <= 1'b1;
                        end
                    end
                end else begin
                    shift_reg[0] <= {2'd0, memManual[2]};
                    shift_reg[1] <= {2'd0, memManual[1]};
                    shift_reg[2] <= 4'd0;
                    shift_reg[3] <= 4'd0;
                end
            end
        // LED Display
            // led right 3: show detect info
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
    
  // Module
    debounce d0( .pb_debounced(rst_d), .clk(clk), .pb(rst));
    onepulse o0( .signal(rst_d), .clk(clk), .op(rst_op));
    clockDriver cD( .clk(clk), .countEnable(countEnable), .countFinish(countFinish), .flash(flash), .countDetail(countDetail));
    clockDriver1 cD1( .clk(clk), .countEnable(countSTOP), .flash(reSTART));
    clockDriver2 cD2( .clk(clk), .countEnable(backEn), .flash(flashBack));
    clock_divider cD3( .clk(clk), .clk_div(clk_update));
    SevenSegment S( .display(DISPLAY), .digit(DIGIT), .nums(nums), .rst(rst), .clk(clk));
    motor A( .clk(clk), .rst(rst), .mode(state), .lastMode(lastState), .pwm({left_pwm, right_pwm}), .l_IN({IN1, IN2}), .r_IN({IN3, IN4}));
    sonic_top B( .clk(clk), .rst(rst), .Echo(echo), .Trig(trig), .distance(distance));
    tracker_sensor C( .clk(clk), .reset(rst), .left_track(left_track), .mid_track(mid_track), .right_track(right_track), .detect_road(detect));
    PmodJSTK_TOP JSTK_inst( .CLK(clk), .RST(rst), .SS(SS), .MOSI(MOSI), .MISO(MISO), .SCLK(SCLK), .DIRECTION(joyStickDir), .BUTTON(joyStickButton));
endmodule