# UpdateLog

## 20251209
```
  1. Create main file, and basic module
  2. Counter seens to have some bugs
```

## 20251210

```
[Ivy]
  1. Update main module file with new clk, fsm state transition
  2. Update led display:
    [15 14 13 12 11] [10] [  9  -  4  ]  [3]  [2 1 0]
    [   led_left   ] [0]  [ led_middle]  [0] [led_right]
    [  state info  ] [0]  [ direction ]  [0] [ detect ]

    IDLE     [0 0 0 0 0] [0] [ 00 00 00 ] [0] [---]
    START    [0 0 0 0 1] [0] [ 00 00 00 ] [0] [---]
    COUNT    [0 0 0 1 0] [0] [  flash   ] [0] [---]
    STRAIGHT [0 1 0 0 0] [0] [ 00 11 00 ] [0] [---]
    CHOOSE   [(flow) 0 0] [0] [ 00 00 00 ] [0] [---]
    ERROR    [1 1 1 1 1] [0] [ 00 00 00 ] [0] [---]

    ----Expect----
    LEFT     [1 0 0 0 0] [0] [ 11 00 00 ] [0] [---]
    RIGHT    [0 0 1 0 0] [0] [ 00 00 11 ] [0] [---]
    STOP     [1 1 1 0 0] [0] [ 11 11 11 ] [0] [---]
    BACK     [0 1 0 1 0] [0] [  flash   ] [0] [---]
        
  4. Update "flow" led display of the CHOOSE state
```

## 20251210

```
[Simon]
  1. add "TURN_LEFT" state
  2. add new "counter" module

```
```
[ivy - pm 11:40]
  1. Create test dirctory for testing verilog file.   
```

## 20251211

```
[ivy - am 2:55]
  1. finish design all FSM transition
  2. finish design all checkpoint signal
  
  ---TODO---
  (1) Stack design
  (2) Debug led signal design
```


# Note

## git command 
***Git commit***
```
git status // modified, untracked, staged change => commit

git add .
git commit -m "{update info}"


// update local file
git fetch
git log HEAD..origin/{branchName}

git pull --ff-only
git pull --rebase // need to fix conflict
git rebase --continue // fixed and continue
git rebase --abort // back to origin state
```


```
git branch

git checkout {branchName} // switch branch
git checkout -b {newBranchName} // create new branch
```

* Update Main branch's content
```
git checkout main
git pull --ff-only

// switch to local branch
git checkout {localBranch}
git merge main

// conflict state
{fix the conflict file}

```

## code setting
* Setting
```
1. Note: 
    (1) Tracker: 
        0: detect black
        1: detect white
        detect: different with tracker
    (2) r_IN & l_IN:
        forward(2'b10)
        stop(2'b00)
```

* Detecter(0: white; 1: black)
```
localparam [2:0]ERROR_ROAD = 3'b000;
localparam [2:0]RIGHT_ROAD = 3'b011;
localparam [2:0]STRAIGHT_ROAD = 3'b010;
localparam [2:0]RIGHT_LITTLE_ROAD = 3'b001;
localparam [2:0]LEFT_ROAD = 3'b110;
localparam [2:0]TURN_ROAD101 = 3'b101;
localparam [2:0]LEFT_LITTLE_ROAD = 3'b100;
localparam [2:0]TURN_ROAD111 = 3'b111;
```

* FSM state
```
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
```


* Seven Segment Setting
```
0 : display = 7'b1000000;	//0000
1 : display = 7'b1111001;   //0001
2 : display = 7'b0100100;   //0010
3 : display = 7'b0110000;   //0011
4 : display = 7'b0011001;   //0100
5 : display = 7'b0010010;   //0101
6 : display = 7'b0000010;   //0110
7 : display = 7'b1111000;   //0111
8 : display = 7'b0000000;   //1000
9 : display = 7'b0010000;	 //1001

10: display = 7'b1000110; // C
11: display = 7'b0111111; // -
12: display = 7'b0100001 ; //d
13: display = 7'b1000111 ; //L
14: display = 7'b0000110 ; //E
``` 