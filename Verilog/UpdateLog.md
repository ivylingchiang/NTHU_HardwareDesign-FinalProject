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
    FINISH   [1 1 1 1 1] [1] [ 11 11 11 ] [1] [---]
 
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

## 20251212
```
  1. finish BASIC map
```

## ~20251219
```
[Simon]
  1. stack update finish
  2. Pmod module updat in idle

[Ivy]
  1. Complete led, Seven Segment Display
```

## ~20251221
```
[Simon]
  1. Complete stack design
  2. Pmod module design
  3. Manual Mode design/debug

[Ivy]
  1. IO complete
  2. Advance Map design
  3. Manual Mode design/debug

```

## ~20251223
```
[Simon/Ivy]
  1. Complete All testing
  2. Complete Demo video recording
  3. Update All code structure
```