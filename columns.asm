################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: Name, Student Number
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       256
# - Unit height in pixels:      256
# - Display width in pixels:    8
# - Display height in pixels:   8
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

.data
displayAddress:     .word 0x10008000
keyboardAddress:    .word 0xffff0000

#colours
beige:              .word 0xEEE0CB
periwinkle:         .word 0x7D80DA
wisteria:           .word 0xB0A3D4
pink:               .word 0xF45B69
amaranth:           .word 0x89043D
mauve:              .word 0x6E4555
borderColour:       .word 0x474350

borderX0:           .word 2
borderY0:           .word 9

blocksStartX:       .word 5
blocksX:            .word 5
blocksStartY:       .word 10
blocksY:            .word 10

COLS:               .word 6
ROWS:               .word 13
grid:               .space 312
match_grid:         .space 312

activeX:            .word 0     # column index
activeY:            .word 0     # row index of TOP gem
activeG0:           .word 0     # top gem colour ID
activeG1:           .word 0     # middle gem colour ID
activeG2:           .word 0

##############################################################################
# Code
##############################################################################
.text
Main:
j Initialization

Initialization:
jal DrawBorder
jal DrawPixel
jal MainLoop

MainLoop:
jal CheckKeyboard
jal Sleep
j MainLoop



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Sleep ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
Sleep:
li $v0, 32 		       	   # Sleep
li $a0, 16 		   	       # Sleep for 16 ms = 1/60 s
syscall
jr $ra

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CheckKeyboard ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
CheckKeyboard:
lw $t0, keyboardAddress  
lw $t1, 0($t0)       
bne $t1, 1, NoKey           # if not pressed, just return

CheckInput:
addi $t0, $t0, 4           
lw $t2, 0($t0)            
beq $t2, 0x71, PressQ       # q is pressed
beq $t2, 0x77, PressW	    # w is pressed
beq $t2, 0x61, PressA		# a is pressed
beq $t2, 0x73, PressS		# s is pressed
beq $t2, 0x64, PressD		# d is pressed
jr $ra                      # other key = ignore and return

PressQ:
li $v0, 10                  # Quit gracefully
syscall
 
    
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Rotate (W) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
PressW:
# rotate the colours upwards
lw $t0, displayAddress
lw $t1, blocksY             # current y
li $t2, 32
mul $t1, $t1, $t2           # t1 = y * 32

lw $t3, blocksX             # current x
add $t1, $t1, $t3           # t1 = y * 32 + x

sll $t1, $t1, 2           
addu $t0, $t0, $t1      

# Current colours
lw $t4, 0($t0)              # top colour
lw $t5, 128($t0)            # middle; 128 pixels
lw $t6, 256($t0)            # bottom; 256 pixels

# Rotate up
sw $t6, 0($t0)              # new top = previous bottom
sw $t4, 128($t0)            # new middle = previous top
sw $t5, 256($t0)            # new bottom = previous middle

jr $ra

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Move Left (A) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
PressA:
lw $t4, blocksX             # current x
lw $t5, blocksY             # current y

# left inner limit: borderX0 + 1
lw $t7, borderX0
addi $t7, $t7, 1  

# If at left inner limit
beq $t4, $t7, PressA_End

lw $t0, displayAddress      # $t0 = 0x10008000

# Find old column address to erase + colour copy
li $t1, 32
mul $t2, $t5, $t1           # t2 = y * 32
add $t2, $t2, $t4           # t2 = y*32 + x
sll $t2, $t2, 2              
addu $t3, $t0, $t2          # t3 = address of top old block

# check cell to the left of each gem:
# left of top pixel
addiu $t6, $t3, -4          # top pixel one pixel left (-4)
lw $t7, 0($t6)
bne $t7, $zero, PressA_End  # something there

# left of middle pixel
addiu $t6, $t3, 124         # middle pixel one left (128 + (-4) = 124)
lw $t7, 0($t6)
bne $t7, $zero, PressA_End

# left of bottom pixel
addiu $t6, $t3, 252         # bottom pixel one left (256 + (-4) = 252)
lw $t7, 0($t6)
bne $t7, $zero, PressA_End


# Read current colours
lw $t8, 0($t3)              # top
lw $t9, 128($t3)            # middle
lw $s1, 256($t3)            # bottom

# Erase old column by colouring it black
move $s0, $zero
sw $s0, 0($t3)
sw $s0, 128($t3)
sw $s0, 256($t3)

# update current x to x = x - 1
addi $t4, $t4, -1
sw $t4, blocksX

# Compute new column address and redraw colours 
li $t1, 32
mul $t2, $t5, $t1           # t2 = y * 32
add $t2, $t2, $t4           # t2 = y * 32 + newX
sll $t2, $t2, 2        
addu $t3, $t0, $t2          # t3 = address of top new block

sw $t8, 0($t3)            # top = old top
sw $t9, 128($t3)            # mid = old mid
sw $s1, 256($t3)            # bottom = old bottom

PressA_End:
jr $ra

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Move Down (S) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
PressS:
lw $t4, blocksX             # current x
lw $t5, blocksY             # current y
 
# Compute lower limit: borderY0 + 11
lw $t7, borderY0
addi $t7, $t7, 11  

# If at bottom limit
beq $t5, $t7, PressS_End

lw $t0, displayAddress 

# Find old column address and erase and copy colours
li $t1, 32
mul $t2, $t5, $t1           # t2 = y * 32
add $t2, $t2, $t4           # t2 = y * 32 + x
sll $t2, $t2, 2         
addu $t3, $t0, $t2          # t3 = address of top old block

# check if there is a gem below
addiu $t6, $t3, 384         # 3 * 128 = 3 rows down
lw $t7, 0($t6)              #check what is underneath
bne $t7, $zero, PressS_End

# Read current colours
lw $t8, 0($t3)              # top
lw $t9, 128($t3)            # middle
lw $s1, 256($t3)            # bottom

# Erase old column by colouring black
move $s0, $zero
sw $s0, 0($t3)
sw $s0, 128($t3)
sw $s0, 256($t3)

# Update y value to be y = y + 1
addi $t5, $t5, 1         
sw $t5, blocksY

# Get new address for the column and redraw it
li $t1, 32
mul $t2, $t5, $t1           # t2 = y * 32
add $t2, $t2, $t4           # t2 = y * 32 + newX
sll $t2, $t2, 2  
addu $t3, $t0, $t2          # t3 = address of top new block

sw $t8, 0($t3)              # top = old top
sw $t9, 128($t3)            # mid = old mid
sw $s1, 256($t3)            # bottom = old bottom
jr $ra
    
PressS_End:
lw $t4, blocksStartX      # x_spawn
lw $t5, blocksStartY      # y_spawn

lw $t0, displayAddress 
    
# Compute address of top spawn cell
li $t1, 32
mul $t2, $t5, $t1          # t2 = y * 32
add $t2, $t2, $t4          # t2 = y*32 + x
sll $t2, $t2, 2            
addu $t3, $t0, $t2          # t3 = addr of top spawn pixel

lw $t6, 0($t3)          # top
lw $t7, 128($t3)          # middle
lw $t8, 256($t3)          # bottom

# If any is non-zero  = game over
or $t9, $t6, $t7
or $t9, $t9, $t8
bne $t9, $zero, GameOver


#reading the columns that are at the bottom
lw $t4, blocksX          # x
lw $t5, blocksY          # y

lw $t0, displayAddress   # base again
li $t1, 32
mul $t2, $t5, $t1         # y * 32
add $t2, $t2, $t4         # y*32 + x
sll $t2, $t2, 2
addu $t3, $t0, $t2         # address of top landed gem

# Read final column colours
lw $t6, 0($t3)         # top gem colour
lw $t7, 128($t3)         # middle
lw $t8, 256($t3)         # bottom

lw $t0, blocksStartX
sw $t0, blocksX
lw $t0, blocksStartY
sw $t0, blocksY
jal DrawPixel

jr   $ra

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Move Right (D) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
PressD:
lw $t4, blocksX     #current x
lw $t5, blocksY     #current y

# Compute right limit
lw $t7, borderX0
addi $t7, $t7, 6  

# If at limit end the call
beq $t4, $t7, PressD_End

lw $t0, displayAddress  

# get old column and erase and redraw it
li $t1, 32
mul $t2, $t5, $t1             # t2 = y * 32
add $t2, $t2, $t4             # t2 = y*32 + x
sll $t2, $t2, 2         
addu $t3, $t0, $t2             # t3 = address of top old block


# check to see if there is a column to the right
# right of top block
addiu $t6, $t3, 4             # one pixel right
lw $t7, 0($t6)
bne $t7, $zero, PressD_End   #cant move

# rught of middle block
addiu $t6, $t3, 132          # one row down, one left
lw $t7, 0($t6)
bne $t7, $zero, PressD_End

# right of bottom block
addiu $t6, $t3, 260          # two rows down, one left
lw $t7, 0($t6)
bne $t7, $zero, PressD_End

# Read current colours
lw   $t8,   0($t3)             # top
lw   $t9, 128($t3)             # middle
lw   $s1, 256($t3)             #bottom

# Erase old column by colouring it black
move $s0, $zero
sw $s0, 0($t3)
sw $s0, 128($t3)
sw $s0, 256($t3)

# update current x value
addi $t4, $t4, 1              # x = x + 1
sw $t4, blocksX

# find new column address and redraw ti
li $t1, 32
mul $t2, $t5, $t1             # t2 = y * 32
add $t2, $t2, $t4             # t2 = y * 32 + newX
sll $t2, $t2, 2             
addu $t3, $t0, $t2        

sw $t8, 0($t3)             # top = old top
sw $t9, 128($t3)             # middle = old middle
sw $s1, 256($t3)             # bottom = old bottom

PressD_End:
jr $ra

NoKey:
jr  $ra

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ DrawBorder ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
DrawBorder:
lw $t0, displayAddress   # t0 = 0x10008000
lw $v1, borderColour     # v1 = border colour

# Load top-left cell (x0, y0) of border
lw $t2, borderX0            # t2 = x0 
lw $t3, borderY0            # t3 = y0

# Compute address of (x0, y0)
li $t4, 32
mul $t5, $t3, $t4            # t5 = y0 * 32
add $t5, $t5, $t2            # t5 = y0 * 32 + x0

sll $t5, $t5, 2              # t5 = index * 4
addu $t6, $t0, $t5           # t6 = pointer to (x0, y0) for current row

li $t7, 0                    # row counter; 15 rows total

RowLoop_8x15:
beq $t7, 15, BorderDone     # if row == 15 → done

# top (row 0) or bottom (row 14) → full row of 8 border pixels
beq $t7, $zero, FullRow
li $t8, 14
beq $t7, $t8, FullRow

# middle rows: no middle
sw $v1, 0($t6)               # left border at x0
addiu $t9, $t6, 28           # right border at x0 + 7; offset 7 * 4 = 28 bytes
sw $v1, 0($t9)
j AfterRow_8x15

# top and bottom rows
FullRow:
move $t9, $t6                # t9 = current pixel in row
li $t8, 0                    # column counter 0..7

FullRowLoop:
beq $t8, 8, AfterRow_8x15
sw $v1, 0($t9)
addiu $t9, $t9, 4             # next pixel (4 bytes)
addiu $t8, $t8, 1
j FullRowLoop

# next row
AfterRow_8x15:
addiu $t6, $t6, 128           # move down one row (32 * 4 bytes)
addiu $t7, $t7, 1             # row++
j RowLoop_8x15

BorderDone:
jr $ra



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ RandomColour ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

RandomColour:
li $v0, 42            # syscall 42: random int
li $a0, 0             # lower bound
li $a1, 6             # upper bound (exclusive) → 0..5
syscall                 # result in $a0

move $t1, $a0           # $t1 = random index

beq $t1, $zero, Beige       # 0 = beige
li $t2, 1
beq $t1, $t2, Periwinkle    # 1 = periwinkle
li $t2, 2
beq $t1, $t2, Wisteria      # 2 = wisteria
li $t2, 3
beq $t1, $t2, Pink          # 3 = pink
li $t2, 4
beq $t1, $t2, Amaranth      # 4 = amaranth
j Mauve                   # if none of the above, must be 5:

Beige:
lw $v0, beige
jr $ra

Periwinkle:
lw $v0, periwinkle
jr $ra

Wisteria:
lw $v0, wisteria
jr $ra

Pink:
lw $v0, pink
jr $ra

Amaranth:
lw $v0, amaranth
jr $ra

Mauve:
lw $v0, mauve
jr $ra


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ DrawPixels ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
DrawPixel:
# Load display base address
lw $t0, displayAddress      # t0 = 0x10008000

# Load current column top position (x, y)
lw $t4, blocksX             # x
lw $t5, blocksY             # y

# index = y * 32 + x
li $t1, 32
mul $t2, $t5, $t1            # t2 = y * 32
add $t2, $t2, $t4            # t2 = y*32 + x
sll $t2, $t2, 2              # * 4 bytes
addu $t0, $t0, $t2            # t0 = addr of top pixel of column

# Draw exactly 3 random-coloured pixels downward
li $s0, 0

PixelLoop:
beq  $s0, 3, DonePixels       # stop after 3 blocks
jal  RandomColour             # $v0 = colour
sw $v0, 0($t0)              # paint pixel
addiu $t0, $t0, 128           # move down one row (32 * 4)
addiu $s0, $s0, 1
j PixelLoop

DonePixels:
jal MainLoop


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ CopyGrid ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
CopyGrid:
la $t0, grid
la $t1, match_grid
lw $t2, ROWS
lw $t3, COLS
mul $t4, $t2, $t3
li $t5, 0

CopyGrid_Loop:
beq $t5, $t4, CopyGrid_Done   # if i == totalCells, stop
sll $t6, $t5, 2        # offset = i * 4 bytes

# load from grid[i]
addu $t7, $t0, $t6      # &grid[i]
lw $t8, 0($t7)        # value = grid[i]

# store into match_grid[i]
addu $t9, $t1, $t6      # &match_grid[i]
sw $t8, 0($t9)

addi $t5, $t5, 1        # i++
j CopyGrid_Loop

CopyGrid_Done:
jr $ra

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ClearMatches ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
ClearMatches:
la $t0, grid           # grid
la $t1, match_grid     # match_grid

lw $t2, ROWS
lw $t3, COLS
mul $t4, $t2, $t3       # totalCells = ROWS * COLS = 78

li $t5, 0              # i = 0

ClearLoop:
beq $t5, $t4, ClearDone # if i == totalCells, exit

sll  $t6, $t5, 2

# read match_grid[i]
addu $t7, $t1, $t6
lw $t8, 0($t7)

beq $t8, $zero, NextCell   # if match_grid[i] == 0; skip

# match found; clear grid[i] = -1
addu $t9, $t0, $t6
li $s0, -1
sw   $s0, 0($t9)

NextCell:
addi $t5, $t5, 1
j ClearLoop

ClearDone:
jr $ra

#~~~~~~~~~~~~~~~~~~~~~~~~ Drop Matches After Clear ~~~~~~~~~~~~~~~~~~~~~~~~#
Gravity:



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Matches ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
ResetMatchGrid:
la $t0, match_grid
lw $t1, ROWS
lw $t2, COLS
mul $t3, $t1, $t2       # total cells
li  $t4, 0              # counter i

ResetLoop:
beq $t4, $t3, ResetDone
sll $t5, $t4, 2
addu $t6, $t0, $t5
sw $zero, 0($t6)
addi $t4, $t4, 1
j ResetLoop

ResetDone:
jr $ra

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ GameOver ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
GameOver:
li $v0, 10
syscall
