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

  3. Note: 
    (1) Tracker: 
        0: detect black
        1: detect white
        detect: different with tracker
    (2) r_IN & l_IN:
        forward(2'b10)
        stop(2'b00)
        
  4. Update "flow" led display of the CHOOSE state
```