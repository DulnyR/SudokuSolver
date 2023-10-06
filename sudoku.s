  .syntax unified
  .cpu cortex-m3
  .fpu softvfp
  .thumb
  
  .global  countInRow
  .global  countInCol
  .global  countIn3x3
  .global  nextInCell
  .global  solveSudoku


@ countInRow subroutine
@ Count the number of occurrences of a specified value in one row of a Sudoku
@   grid.
@
@ Parameters:
@   R0: start address of 2D array representing the Sudoku grid
@   R1: row number
@   R2: value to count
@ Return:
@   R0: number of occurrences of value in specified row
countInRow:
  PUSH    {R4-R6, LR}

  MOV     R4, R0                @ startAddress
  MOV     R5, #9       
  MUL     R5, R1, R5            @ row number * 9 
  ADD     R4, R4, R5            @ startAddress += rowNumber * 9 

  MOV     R0, #0                @ counter = 0
  MOV     R6, #0                @ i = 0

.LforCIR:                         @ for (int i = 0; i < 9; i++)
  CMP     R6 , #9
  BGE     .LendCIR
  LDRB    R5, [R4, R6]          @   number = load newAddress + i
  CMP     R5, R2                @   if (number == value)
  BNE     .LnotEqualCIR
  ADD     R0, R0, #1            @     counter++
.LnotEqualCIR:
  ADD     R6, R6, #1            
  B       .LforCIR
.LendCIR:

  POP     {R4-R6, PC}



@ countInCol subroutine
@ Count the number of occurrences of a specified value in one column of a Sudoku
@   grid.
@
@ Parameters:
@   R0: start address of 2D array representing the Sudoku grid
@   R1: column number
@   R2: value to count
@ Return:
@   R0: number of occurrences of value in specified column
countInCol:
  PUSH    {R4-R6, LR}

  MOV     R4, R0                @ startAddress
  ADD     R4, R4, R1            @ startAddress += columnNumber

  MOV     R0, #0                @ counter = 0
  MOV     R6, #0                @ i = 0

.LforCIC:                         @ for (int i = 0; i < 9; i++)
  CMP     R6, #9
  BGE     .LendCIC
  LDRB    R5, [R4], #9          @   number = load newAddress + 9
  CMP     R5, R2                @   if (number == value)
  BNE     .LnotEqualCIC
  ADD     R0, R0, #1            @     counter++
.LnotEqualCIC:
  ADD     R6, R6, #1           
  B       .LforCIC
.LendCIC:

  POP     {R4-R6, PC}



@ countIn3x3 subroutine
@ Count the number of occurrences of a specified value in one 3x3 subgrid
@   of a Sudoku grid.
@
@ Parameters:
@   R0: start address of 2D array representing the Sudoku grid
@   R1: row number of any row in the 3x3 subgrid
@   R2: column number of any column in the 3x3 subgrid
@   R3: value to count
@ Return:
@   R0: number of occurrences of value in specified 3x3 subgrid
countIn3x3:
  PUSH    {R4-R7, LR}

  MOV     R4, #0              @ AA = addressAdd = 0
  CMP     R1, #3              @ if row > 3
  BLO     .LcolumnCheck         
  MOV     R4, #27             @   AA = 27
  CMP     R1, #6              @ if row > 6
  BLO     .LcolumnCheck 
  MOV     R4, #54             @   AA = 54
.LcolumnCheck:
  CMP     R2, #3              @ if column > 3
  BLO     .LnumCheck
  ADD     R4, R4, #3          @   AA += 3
  CMP     R2, #6              @ if column > 6
  BLO     .LnumCheck    
  ADD     R4, R4, #3          @   AA += 3
.LnumCheck:

  ADD     R4, R4, R0          @ startAddress of 3x3
  MOV     R0, #0              @ counter = 0
  MOV     R5, #0              @ i = 0
.Lfor3Col:                    @ for (int i = 0; i < 3; i++;)
  CMP     R5, #3
  BHS     .Lend3Check
  MOV     R6, #0              @   j = 0
.Lfor3Row:
  CMP     R6, #3              @   for (int j = 0; j < 3; j++)
  BHS     .LendRowCheck
  LDRB    R7, [R4, R6]        @     load startAddress += j
  CMP     R7, R3
  BNE     .LnotEqual3Row      @     if (loadedValue == searchValue)
  ADD     R0, R0, #1          @       counter++
.LnotEqual3Row:
  ADD     R6, R6, #1
  B       .Lfor3Row        
.LendRowCheck:
  ADD     R4, R4, #9
  ADD     R5, R5, #1
  B       .Lfor3Col
.Lend3Check:

  POP     {R4-R7, PC}


@ nextInCell subroutine
@ Find the next higher valid value that can be placed in a specified cell in a
@   Sudoku grid.
@
@ Parameters:
@   R0: start address of 2D array representing the Sudoku grid
@   R1: row number of cell
@   R2: column number of cell
@ Return:
@   R0: next higher value or 0 if there is no valid higher value
nextInCell:
  PUSH    {R4-R7, LR}

  MOV      R4, #9          
  MUL      R4, R4, R1           @   addAddress = row * 9
  ADD      R4, R4, R2           @   AA += column
  LDRB     R4, [R0, R4]         @   load value from start + addAddress
  MOV      R5, R1               @ copy row number
  MOV      R6, R2               @ copy col number
  MOV      R7, R0               
.LnextLoop:
  CMP      R4, #10              @ while (valueToCheck < 10)
  BHS      .LnoMatch
  MOV      R0, R7        
  MOV      R1, R5               @ enter correct values and call subroutines
  MOV      R2, R4 
  BL       countInRow
  CMP      R0, #0
  BNE      .LrestartLoop
  MOV      R0, R7
  MOV      R1, R6
  MOV      R2, R4
  BL       countInCol
  CMP      R0, #0
  BNE      .LrestartLoop
  MOV      R0, R7
  MOV      R1, R5
  MOV      R2, R6
  MOV      R3, R4
  BL       countIn3x3
  CMP      R0, #0
  BNE      .LrestartLoop
  MOV      R0, R4
  B        .LendNext
.LrestartLoop:
  ADD      R4, R4, #1
  B        .LnextLoop

.LnoMatch:
  MOV      R0, #0

.LendNext:

  POP     {R4-R7, PC}



@ solveSudoku subroutine
@ Solve a Sudoku puzzle.
@
@ Parameters:
@   R0: start address of 2D array representing the Sudoku grid
@   R1: row number of next cell to modify
@   R2: column number of next cell to modify
@ Return:
@   R0: 1 if a solution was found, zero otherwise
solveSudoku:
  PUSH    {R4-R12, LR}

  MOV     R4, R0
  MOV     R5, R1
  MOV     R6, R2

  CMP     R5, #9          @ if (row >= 9)
  BLT     .Lelse
  MOV     R12, #1          @   result = 1
  B       .LendSolve
.Lelse:                   @ else
  MOV     R12, #0         @   result = 0
  ADD     R7, R6, #1      @   nextColumn = column + 1
  MOV     R8, R1          @   nextRow = row
  CMP     R7, #9          @   if (nextColumn >= 9)
  BLT     .LsameRow       
  MOV     R7, #0          @     nextColumn = 0
  ADD     R8, R8, #1      @     nextRow += 1
.LsameRow:

  MOV     R9, #9          
  MUL     R10, R9, R5     @   addAddress = row * 9
  ADD     R10, R10, R6    @   AA += column
  LDRB    R10, [R4, R10]  @   load value from start + addAddress

  CMP     R10, #0
  BEQ     .LchangeValue   @   if (current != 0)
  MOV     R0, R4
  MOV     R1, R8
  MOV     R2, R7
  BL      solveSudoku     @     call itself
  MOV     R12, R0
  B       .LendSolve
.LchangeValue:
                          @   else
  MOV     R0, R4
  MOV     R1, R5
  MOV     R2, R6
  BL      nextInCell
  MOV     R11, R0         @     next = nextNumber
.LwhileFill:
  CMP     R11, #0
  BEQ     .LendWhileFill
  CMP     R12, #1                                         
  BEQ     .LendWhileFill
  MOV     R9, #9          
  MUL     R10, R9, R5     @   addAddress = row * 9
  ADD     R10, R10, R6    @   AA += column
  STRB    R11, [R4, R10]  @   store value at start + addAddress
  MOV     R0, R4
  MOV     R1, R8
  MOV     R2, R7
  BL      solveSudoku     @     call itself
  MOV     R12, R0
  MOV     R0, R4
  MOV     R1, R5
  MOV     R2, R6
  BL      nextInCell
  MOV     R11, R0         @     next = nextNumber
  B       .LwhileFill
.LendWhileFill:

  CMP     R12, #0
  BNE     .LendSolve
  MOV     R11, #0
  MUL     R10, R9, R5     @   addAddress = row * 9
  ADD     R10, R10, R6    @   AA += column
  STRB    R11, [R4, R10]  @   store value at start + addAddress
.LendSolve:
  MOV     R0, R12 

  POP     {R4-R12, PC}

  .end