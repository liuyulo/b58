
# s0 player x in bytes
# s1 player y in bytes

# NOTE: 1 pixel === 4 bytes
.eqv BASE_ADDRESS   0x10008000  # ($gp)
.eqv REFRESH_RATE   40          # in miliseconds
.eqv SIZE           512         # screen width & height in bytes
.eqv WIDTH_SHIFT    7           # 4 << WIDTH_SHIFT == SIZE
.eqv PLAYER_WIDTH   56          # in bytes
.eqv PLAYER_HEIGHT  64          # in bytes
.eqv BACKGROUND     $0 # black

.data
    padding: .space 36000 # space padding to support 128x128 resolution
.text

.globl main
main:
    li $s0 4  # player x
    li $s1 4 # player y
    jal flatten_current # get current position to v0
    jal draw_player
    loop:
        li $a0 0xffff0000 # check keypress
        lw $t0 0($a0)
        la $ra update
        beq $t0 1 keypressed # handle keypress

        update:
        li $a0 REFRESH_RATE # sleep
        li $v0 32
        syscall
        j loop

    li $v0 10 # terminate the program gracefully
    syscall

keypressed: # handle keypress in 4($a0)
    addi $sp $sp -4 # push ra to stack
    sw $ra 0($sp)

    lw $t0 4($a0)
    beq $t0 0x77 keypressed_w
    beq $t0 0x61 keypressed_a
    beq $t0 0x73 keypressed_s
    beq $t0 0x64 keypressed_d

    la $ra keypressed_end
    keypressed_w:
    ble $s1 0 keypressed_end # reach top boundary
    li $a0 0
    li $a1 -4
    j player_move

    keypressed_a:
    ble $s0 0 keypressed_end # reach left boundary
    li $a0 -4
    li $a1 0
    j player_move

    keypressed_s:
    addi $t0 $s1 PLAYER_HEIGHT
    bge $t0 SIZE keypressed_end # reach bottom boundary
    li $a0 0
    li $a1 4
    j player_move

    keypressed_d:
    addi $t0 $s0 PLAYER_WIDTH
    bge $t0 SIZE keypressed_end # reach right boundary
    li $a0 4
    li $a1 0
    j player_move

    keypressed_end:
    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4
    jr $ra # return

player_move: # move towards (a0, a1)
    # todo check collision
    addi $sp $sp -4 # push ra to stack
    sw $ra 0($sp)

    move $t0 $s0 # backup
    move $t1 $s1
    add $s0 $s0 $a0 # new x
    add $s1 $s1 $a1 # new y

    jal flatten_current # get current position to v0
    jal draw_player # draw player at new position

    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4
    jr $ra # return

flatten_current: # convert (s0, s1) to pixel address in display in v0
    sll $v0 $s1 WIDTH_SHIFT
    add $v0 $v0 BASE_ADDRESS
    add $v0 $v0 $s0
    jr $ra # jump to caller

flatten: # convert (a0, a1) to pixel address in display in v0
    sll $v0 $a1 WIDTH_SHIFT
    add $v0 $v0 BASE_ADDRESS
    add $v0 $v0 $a0
    jr $ra # jump to caller

draw_player: # draw player at (x, y) in v0 with (Δx, Δy) in (a0, a1)
    move $t0 $v0 # save v0
    sw BACKGROUND 0($t0) # store background
    sw BACKGROUND 4($t0) # store background
    sw BACKGROUND 8($t0) # store background
    li $t1 0x020101 # load color
    sw $t1 12($t0) # store pixel at (3, 0)
    li $t1 0x603320 # load color
    sw $t1 16($t0) # store pixel at (4, 0)
    li $t1 0x816153 # load color
    sw $t1 20($t0) # store pixel at (5, 0)
    li $t1 0x6e6973 # load color
    sw $t1 24($t0) # store pixel at (6, 0)
    li $t1 0x736266 # load color
    sw $t1 28($t0) # store pixel at (7, 0)
    li $t1 0x67565d # load color
    sw $t1 32($t0) # store pixel at (8, 0)
    li $t1 0x736870 # load color
    sw $t1 36($t0) # store pixel at (9, 0)
    li $t1 0x384041 # load color
    sw $t1 40($t0) # store pixel at (10, 0)
    sw BACKGROUND 44($t0) # store background
    sw BACKGROUND 48($t0) # store background
    sw BACKGROUND 52($t0) # store background
    addi $t0 $t0 SIZE # go to next row
    li $t1 0x010000 # load color
    sw $t1 0($t0) # store pixel at (0, 1)
    sw BACKGROUND 4($t0) # store background
    li $t1 0x301c14 # load color
    sw $t1 8($t0) # store pixel at (2, 1)
    li $t1 0xb46548 # load color
    sw $t1 12($t0) # store pixel at (3, 1)
    li $t1 0xf2beaa # load color
    sw $t1 16($t0) # store pixel at (4, 1)
    li $t1 0xd29dae # load color
    sw $t1 20($t0) # store pixel at (5, 1)
    li $t1 0xbe728e # load color
    sw $t1 24($t0) # store pixel at (6, 1)
    li $t1 0xdc8998 # load color
    sw $t1 28($t0) # store pixel at (7, 1)
    li $t1 0xda8795 # load color
    sw $t1 32($t0) # store pixel at (8, 1)
    li $t1 0xc37691 # load color
    sw $t1 36($t0) # store pixel at (9, 1)
    li $t1 0xc28d98 # load color
    sw $t1 40($t0) # store pixel at (10, 1)
    li $t1 0x926857 # load color
    sw $t1 44($t0) # store pixel at (11, 1)
    li $t1 0x060103 # load color
    sw $t1 48($t0) # store pixel at (12, 1)
    sw BACKGROUND 52($t0) # store background
    addi $t0 $t0 SIZE # go to next row
    sw BACKGROUND 0($t0) # store background
    li $t1 0x0e0805 # load color
    sw $t1 4($t0) # store pixel at (1, 2)
    li $t1 0xaf6347 # load color
    sw $t1 8($t0) # store pixel at (2, 2)
    li $t1 0xf6986b # load color
    sw $t1 12($t0) # store pixel at (3, 2)
    li $t1 0xbf8a94 # load color
    sw $t1 16($t0) # store pixel at (4, 2)
    li $t1 0xb87187 # load color
    sw $t1 20($t0) # store pixel at (5, 2)
    li $t1 0xdfa189 # load color
    sw $t1 24($t0) # store pixel at (6, 2)
    li $t1 0xeeb988 # load color
    sw $t1 28($t0) # store pixel at (7, 2)
    li $t1 0xf1bb8c # load color
    sw $t1 32($t0) # store pixel at (8, 2)
    li $t1 0xe3aa87 # load color
    sw $t1 36($t0) # store pixel at (9, 2)
    li $t1 0xc78190 # load color
    sw $t1 40($t0) # store pixel at (10, 2)
    li $t1 0xe48a80 # load color
    sw $t1 44($t0) # store pixel at (11, 2)
    li $t1 0x986141 # load color
    sw $t1 48($t0) # store pixel at (12, 2)
    li $t1 0x0f0a0b # load color
    sw $t1 52($t0) # store pixel at (13, 2)
    addi $t0 $t0 SIZE # go to next row
    sw BACKGROUND 0($t0) # store background
    li $t1 0x27150f # load color
    sw $t1 4($t0) # store pixel at (1, 3)
    li $t1 0xd87c5d # load color
    sw $t1 8($t0) # store pixel at (2, 3)
    li $t1 0xf3c56f # load color
    sw $t1 12($t0) # store pixel at (3, 3)
    li $t1 0xde8b64 # load color
    sw $t1 16($t0) # store pixel at (4, 3)
    li $t1 0xf4bf79 # load color
    sw $t1 20($t0) # store pixel at (5, 3)
    li $t1 0xfdd972 # load color
    sw $t1 24($t0) # store pixel at (6, 3)
    li $t1 0xfddd6f # load color
    sw $t1 28($t0) # store pixel at (7, 3)
    li $t1 0xfcd96a # load color
    sw $t1 32($t0) # store pixel at (8, 3)
    li $t1 0xfedc71 # load color
    sw $t1 36($t0) # store pixel at (9, 3)
    li $t1 0xf7cc7a # load color
    sw $t1 40($t0) # store pixel at (10, 3)
    li $t1 0xf4cc82 # load color
    sw $t1 44($t0) # store pixel at (11, 3)
    li $t1 0xfdd175 # load color
    sw $t1 48($t0) # store pixel at (12, 3)
    li $t1 0x4a3322 # load color
    sw $t1 52($t0) # store pixel at (13, 3)
    addi $t0 $t0 SIZE # go to next row
    sw BACKGROUND 0($t0) # store background
    li $t1 0x7d4333 # load color
    sw $t1 4($t0) # store pixel at (1, 4)
    li $t1 0xf5a86d # load color
    sw $t1 8($t0) # store pixel at (2, 4)
    li $t1 0xfada75 # load color
    sw $t1 12($t0) # store pixel at (3, 4)
    li $t1 0xedb27a # load color
    sw $t1 16($t0) # store pixel at (4, 4)
    li $t1 0xfdf1b7 # load color
    sw $t1 20($t0) # store pixel at (5, 4)
    li $t1 0xf4ca87 # load color
    sw $t1 24($t0) # store pixel at (6, 4)
    li $t1 0xf9da8c # load color
    sw $t1 28($t0) # store pixel at (7, 4)
    li $t1 0xfef0bc # load color
    sw $t1 32($t0) # store pixel at (8, 4)
    li $t1 0xf4c67d # load color
    sw $t1 36($t0) # store pixel at (9, 4)
    li $t1 0xffeea1 # load color
    sw $t1 40($t0) # store pixel at (10, 4)
    li $t1 0xf5cf93 # load color
    sw $t1 44($t0) # store pixel at (11, 4)
    li $t1 0xfbcb73 # load color
    sw $t1 48($t0) # store pixel at (12, 4)
    li $t1 0xb39355 # load color
    sw $t1 52($t0) # store pixel at (13, 4)
    addi $t0 $t0 SIZE # go to next row
    sw BACKGROUND 0($t0) # store background
    li $t1 0x914f3c # load color
    sw $t1 4($t0) # store pixel at (1, 5)
    li $t1 0xfec879 # load color
    sw $t1 8($t0) # store pixel at (2, 5)
    li $t1 0xf0c06e # load color
    sw $t1 12($t0) # store pixel at (3, 5)
    li $t1 0xfcd07d # load color
    sw $t1 16($t0) # store pixel at (4, 5)
    li $t1 0xfccb8a # load color
    sw $t1 20($t0) # store pixel at (5, 5)
    li $t1 0xc26f50 # load color
    sw $t1 24($t0) # store pixel at (6, 5)
    li $t1 0xf7da7d # load color
    sw $t1 28($t0) # store pixel at (7, 5)
    li $t1 0xffe28e # load color
    sw $t1 32($t0) # store pixel at (8, 5)
    li $t1 0xb86a46 # load color
    sw $t1 36($t0) # store pixel at (9, 5)
    li $t1 0xdd9f69 # load color
    sw $t1 40($t0) # store pixel at (10, 5)
    li $t1 0xfade85 # load color
    sw $t1 44($t0) # store pixel at (11, 5)
    li $t1 0xea9f63 # load color
    sw $t1 48($t0) # store pixel at (12, 5)
    li $t1 0xbba15a # load color
    sw $t1 52($t0) # store pixel at (13, 5)
    addi $t0 $t0 SIZE # go to next row
    li $t1 0x010000 # load color
    sw $t1 0($t0) # store pixel at (0, 6)
    li $t1 0x99543d # load color
    sw $t1 4($t0) # store pixel at (1, 6)
    li $t1 0xf6bb6f # load color
    sw $t1 8($t0) # store pixel at (2, 6)
    li $t1 0xf5c172 # load color
    sw $t1 12($t0) # store pixel at (3, 6)
    li $t1 0xd1915a # load color
    sw $t1 16($t0) # store pixel at (4, 6)
    li $t1 0x763d1d # load color
    sw $t1 20($t0) # store pixel at (5, 6)
    li $t1 0x854c39 # load color
    sw $t1 24($t0) # store pixel at (6, 6)
    li $t1 0xf1cc71 # load color
    sw $t1 28($t0) # store pixel at (7, 6)
    li $t1 0xd8804e # load color
    sw $t1 32($t0) # store pixel at (8, 6)
    li $t1 0x452422 # load color
    sw $t1 36($t0) # store pixel at (9, 6)
    li $t1 0x814839 # load color
    sw $t1 40($t0) # store pixel at (10, 6)
    li $t1 0xf6b768 # load color
    sw $t1 44($t0) # store pixel at (11, 6)
    li $t1 0xb77648 # load color
    sw $t1 48($t0) # store pixel at (12, 6)
    li $t1 0xa5844d # load color
    sw $t1 52($t0) # store pixel at (13, 6)
    addi $t0 $t0 SIZE # go to next row
    sw BACKGROUND 0($t0) # store background
    li $t1 0x924f39 # load color
    sw $t1 4($t0) # store pixel at (1, 7)
    li $t1 0xe2ae62 # load color
    sw $t1 8($t0) # store pixel at (2, 7)
    li $t1 0xf7c86f # load color
    sw $t1 12($t0) # store pixel at (3, 7)
    li $t1 0x7b514c # load color
    sw $t1 16($t0) # store pixel at (4, 7)
    li $t1 0x383d49 # load color
    sw $t1 20($t0) # store pixel at (5, 7)
    li $t1 0x605d56 # load color
    sw $t1 24($t0) # store pixel at (6, 7)
    li $t1 0xf3b091 # load color
    sw $t1 28($t0) # store pixel at (7, 7)
    li $t1 0xecbbb2 # load color
    sw $t1 32($t0) # store pixel at (8, 7)
    li $t1 0x698d9f # load color
    sw $t1 36($t0) # store pixel at (9, 7)
    li $t1 0xbb9285 # load color
    sw $t1 40($t0) # store pixel at (10, 7)
    li $t1 0xdb9251 # load color
    sw $t1 44($t0) # store pixel at (11, 7)
    li $t1 0x583421 # load color
    sw $t1 48($t0) # store pixel at (12, 7)
    li $t1 0x1e1c11 # load color
    sw $t1 52($t0) # store pixel at (13, 7)
    addi $t0 $t0 SIZE # go to next row
    li $t1 0x533125 # load color
    sw $t1 0($t0) # store pixel at (0, 8)
    li $t1 0xd37854 # load color
    sw $t1 4($t0) # store pixel at (1, 8)
    li $t1 0xd69c5c # load color
    sw $t1 8($t0) # store pixel at (2, 8)
    li $t1 0xf3c66a # load color
    sw $t1 12($t0) # store pixel at (3, 8)
    li $t1 0xdaac83 # load color
    sw $t1 16($t0) # store pixel at (4, 8)
    li $t1 0x71b6c7 # load color
    sw $t1 20($t0) # store pixel at (5, 8)
    li $t1 0x8eb6b8 # load color
    sw $t1 24($t0) # store pixel at (6, 8)
    li $t1 0xffe8df # load color
    sw $t1 28($t0) # store pixel at (7, 8)
    li $t1 0xfcede5 # load color
    sw $t1 32($t0) # store pixel at (8, 8)
    li $t1 0x92c9cf # load color
    sw $t1 36($t0) # store pixel at (9, 8)
    li $t1 0xc1937d # load color
    sw $t1 40($t0) # store pixel at (10, 8)
    li $t1 0xbd6643 # load color
    sw $t1 44($t0) # store pixel at (11, 8)
    li $t1 0x221412 # load color
    sw $t1 48($t0) # store pixel at (12, 8)
    sw BACKGROUND 52($t0) # store background
    addi $t0 $t0 SIZE # go to next row
    li $t1 0x553327 # load color
    sw $t1 0($t0) # store pixel at (0, 9)
    li $t1 0xe1825a # load color
    sw $t1 4($t0) # store pixel at (1, 9)
    li $t1 0xb16141 # load color
    sw $t1 8($t0) # store pixel at (2, 9)
    li $t1 0xe7935f # load color
    sw $t1 12($t0) # store pixel at (3, 9)
    li $t1 0xd08b66 # load color
    sw $t1 16($t0) # store pixel at (4, 9)
    li $t1 0x89a0a8 # load color
    sw $t1 20($t0) # store pixel at (5, 9)
    li $t1 0xb9c1c1 # load color
    sw $t1 24($t0) # store pixel at (6, 9)
    li $t1 0xfff3e6 # load color
    sw $t1 28($t0) # store pixel at (7, 9)
    li $t1 0xfee9e0 # load color
    sw $t1 32($t0) # store pixel at (8, 9)
    li $t1 0xe5bbb2 # load color
    sw $t1 36($t0) # store pixel at (9, 9)
    li $t1 0xd37e60 # load color
    sw $t1 40($t0) # store pixel at (10, 9)
    li $t1 0x9d593d # load color
    sw $t1 44($t0) # store pixel at (11, 9)
    li $t1 0x0c0605 # load color
    sw $t1 48($t0) # store pixel at (12, 9)
    sw BACKGROUND 52($t0) # store background
    addi $t0 $t0 SIZE # go to next row
    li $t1 0x241512 # load color
    sw $t1 0($t0) # store pixel at (0, 10)
    li $t1 0x754432 # load color
    sw $t1 4($t0) # store pixel at (1, 10)
    li $t1 0x412316 # load color
    sw $t1 8($t0) # store pixel at (2, 10)
    li $t1 0x874832 # load color
    sw $t1 12($t0) # store pixel at (3, 10)
    li $t1 0xbc7050 # load color
    sw $t1 16($t0) # store pixel at (4, 10)
    li $t1 0xf0b4b3 # load color
    sw $t1 20($t0) # store pixel at (5, 10)
    li $t1 0xffded7 # load color
    sw $t1 24($t0) # store pixel at (6, 10)
    li $t1 0xdc999b # load color
    sw $t1 28($t0) # store pixel at (7, 10)
    li $t1 0xeeb4b8 # load color
    sw $t1 32($t0) # store pixel at (8, 10)
    li $t1 0x9f7876 # load color
    sw $t1 36($t0) # store pixel at (9, 10)
    li $t1 0x81452b # load color
    sw $t1 40($t0) # store pixel at (10, 10)
    li $t1 0x4b2b1f # load color
    sw $t1 44($t0) # store pixel at (11, 10)
    sw BACKGROUND 48($t0) # store background
    sw BACKGROUND 52($t0) # store background
    addi $t0 $t0 SIZE # go to next row
    li $t1 0x232331 # load color
    sw $t1 0($t0) # store pixel at (0, 11)
    li $t1 0x160d0b # load color
    sw $t1 4($t0) # store pixel at (1, 11)
    li $t1 0x000103 # load color
    sw $t1 8($t0) # store pixel at (2, 11)
    li $t1 0x060100 # load color
    sw $t1 12($t0) # store pixel at (3, 11)
    li $t1 0x7d5142 # load color
    sw $t1 16($t0) # store pixel at (4, 11)
    li $t1 0xdbd1df # load color
    sw $t1 20($t0) # store pixel at (5, 11)
    li $t1 0xe1b4bb # load color
    sw $t1 24($t0) # store pixel at (6, 11)
    li $t1 0xd27e89 # load color
    sw $t1 28($t0) # store pixel at (7, 11)
    li $t1 0xd9949f # load color
    sw $t1 32($t0) # store pixel at (8, 11)
    li $t1 0xc7bac1 # load color
    sw $t1 36($t0) # store pixel at (9, 11)
    li $t1 0x40262c # load color
    sw $t1 40($t0) # store pixel at (10, 11)
    li $t1 0x010000 # load color
    sw $t1 44($t0) # store pixel at (11, 11)
    sw BACKGROUND 48($t0) # store background
    sw BACKGROUND 52($t0) # store background
    addi $t0 $t0 SIZE # go to next row
    li $t1 0x0c0b0f # load color
    sw $t1 0($t0) # store pixel at (0, 12)
    sw BACKGROUND 4($t0) # store background
    sw BACKGROUND 8($t0) # store background
    sw BACKGROUND 12($t0) # store background
    li $t1 0x1c2e51 # load color
    sw $t1 16($t0) # store pixel at (4, 12)
    li $t1 0x383d57 # load color
    sw $t1 20($t0) # store pixel at (5, 12)
    li $t1 0x5e5e7e # load color
    sw $t1 24($t0) # store pixel at (6, 12)
    li $t1 0x838999 # load color
    sw $t1 28($t0) # store pixel at (7, 12)
    li $t1 0x706e77 # load color
    sw $t1 32($t0) # store pixel at (8, 12)
    li $t1 0x27283a # load color
    sw $t1 36($t0) # store pixel at (9, 12)
    li $t1 0x080e27 # load color
    sw $t1 40($t0) # store pixel at (10, 12)
    li $t1 0x010103 # load color
    sw $t1 44($t0) # store pixel at (11, 12)
    sw BACKGROUND 48($t0) # store background
    sw BACKGROUND 52($t0) # store background
    addi $t0 $t0 SIZE # go to next row
    sw BACKGROUND 0($t0) # store background
    li $t1 0x010101 # load color
    sw $t1 4($t0) # store pixel at (1, 13)
    li $t1 0x080706 # load color
    sw $t1 8($t0) # store pixel at (2, 13)
    li $t1 0x4b536d # load color
    sw $t1 12($t0) # store pixel at (3, 13)
    li $t1 0x3f5480 # load color
    sw $t1 16($t0) # store pixel at (4, 13)
    li $t1 0x000012 # load color
    sw $t1 20($t0) # store pixel at (5, 13)
    li $t1 0x707694 # load color
    sw $t1 24($t0) # store pixel at (6, 13)
    li $t1 0xd8d3e1 # load color
    sw $t1 28($t0) # store pixel at (7, 13)
    li $t1 0xcfcbd7 # load color
    sw $t1 32($t0) # store pixel at (8, 13)
    li $t1 0x717b9c # load color
    sw $t1 36($t0) # store pixel at (9, 13)
    li $t1 0x383c4e # load color
    sw $t1 40($t0) # store pixel at (10, 13)
    li $t1 0x0c0b0c # load color
    sw $t1 44($t0) # store pixel at (11, 13)
    sw BACKGROUND 48($t0) # store background
    li $t1 0x000001 # load color
    sw $t1 52($t0) # store pixel at (13, 13)
    addi $t0 $t0 SIZE # go to next row
    li $t1 0x010101 # load color
    sw $t1 0($t0) # store pixel at (0, 14)
    sw BACKGROUND 4($t0) # store background
    li $t1 0x030302 # load color
    sw $t1 8($t0) # store pixel at (2, 14)
    li $t1 0x4d4e52 # load color
    sw $t1 12($t0) # store pixel at (3, 14)
    li $t1 0x67677c # load color
    sw $t1 16($t0) # store pixel at (4, 14)
    li $t1 0x7983a2 # load color
    sw $t1 20($t0) # store pixel at (5, 14)
    li $t1 0x7d85a8 # load color
    sw $t1 24($t0) # store pixel at (6, 14)
    li $t1 0x959cba # load color
    sw $t1 28($t0) # store pixel at (7, 14)
    li $t1 0xc6cbde # load color
    sw $t1 32($t0) # store pixel at (8, 14)
    li $t1 0x9ca0bd # load color
    sw $t1 36($t0) # store pixel at (9, 14)
    li $t1 0x3c3c4a # load color
    sw $t1 40($t0) # store pixel at (10, 14)
    li $t1 0x09080b # load color
    sw $t1 44($t0) # store pixel at (11, 14)
    sw BACKGROUND 48($t0) # store background
    sw BACKGROUND 52($t0) # store background
    addi $t0 $t0 SIZE # go to next row
    sw BACKGROUND 0($t0) # store background
    sw BACKGROUND 4($t0) # store background
    sw BACKGROUND 8($t0) # store background
    sw BACKGROUND 12($t0) # store background
    li $t1 0x1b1a23 # load color
    sw $t1 16($t0) # store pixel at (4, 15)
    li $t1 0x8e8da0 # load color
    sw $t1 20($t0) # store pixel at (5, 15)
    li $t1 0x565560 # load color
    sw $t1 24($t0) # store pixel at (6, 15)
    li $t1 0x000514 # load color
    sw $t1 28($t0) # store pixel at (7, 15)
    li $t1 0x838295 # load color
    sw $t1 32($t0) # store pixel at (8, 15)
    li $t1 0x51505c # load color
    sw $t1 36($t0) # store pixel at (9, 15)
    sw BACKGROUND 40($t0) # store background
    sw BACKGROUND 44($t0) # store background
    sw BACKGROUND 48($t0) # store background
    sw BACKGROUND 52($t0) # store background

    jr $ra # return