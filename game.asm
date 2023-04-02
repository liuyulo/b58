
# s0 player x in bytes
# s1 player y in bytes

# NOTE: 1 pixel === 4 bytes
.eqv BASE_ADDRESS   0x10008000  # ($gp)
.eqv REFRESH_RATE   40          # in miliseconds
.eqv BACKGROUND     0           # background color
.eqv WIDTH          512         # screen width in bytes
.eqv HEIGHT         512         # screen height in bytes
.eqv WIDTH_SHIFT    7           # 4 << WIDTH_SHIFT == WIDTH
.eqv PLAYER_WIDTH   56          # in bytes
.eqv PLAYER_HEIGHT  64          # in bytes

.data
    padding: .space 36000 # space padding to support 128x128 resolution
.text


.globl main
main:
    li $s0 0  # player x
    li $s1 0 # player y

    jal draw_player
    loop:
        li $a0 0xffff0000 # check keypress
        lw $t0 0($a0)
        bne $t0 1 update # skip keypressed if no press
        jal keypressed

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
    #li $t0 0x73

    beq $t0 0x77 keypressed_w
    beq $t0 0x61 keypressed_a
    beq $t0 0x73 keypressed_s
    beq $t0 0x64 keypressed_d

    keypressed_w:
    ble $s1 0 keypressed_end # reach top boundary
    li $a0 0
    li $a1 -4
    j keypressed_move

    keypressed_a:
    ble $s0 0 keypressed_end # reach left boundary
    li $a0 -4
    li $a1 0
    j keypressed_move

    keypressed_s:
    addi $t0 $s1 PLAYER_HEIGHT
    bge $t0 HEIGHT keypressed_end # reach bottom boundary
    li $a0 0
    li $a1 4
    j keypressed_move

    keypressed_d:
    addi $t0 $s0 PLAYER_WIDTH
    bge $t0 WIDTH keypressed_end # reach right boundary
    li $a0 4
    li $a1 0
    j keypressed_move

    keypressed_move:
    jal player_move

    keypressed_end:
    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4
    jr $ra # return

player_move: # move towards (a0, a1)
    # todo check collision and boundary
    addi $sp $sp -4 # push ra to stack
    sw $ra 0($sp)

    # beq $a0 0 clear_col_end # if move on x, clear column
    #     beq $a0 1 clear_col_else # if move left
    #         li $a0
    #     clear_row_else:
    #         e
    #     li $t1 PLAYER_WIDTH
    # clear_row_end:

    add $s0 $s0 $a0 # move x
    add $s1 $s1 $a1 # move y
    jal draw_player # draw player at new position

    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4
    jr $ra # return

flatten: # convert (a0, a1) to pixel address in display in v0
    sll $v0 $a1 WIDTH_SHIFT
    add $v0 $v0 BASE_ADDRESS
    add $v0 $v0 $a0
    jr $ra # jump to caller

draw_player: # draw player at (s0, s1)
    addi $sp $sp -4 # push ra to stack
    sw $ra 0($sp)

    move $a0 $s0 # compute start position to v0
    move $a1 $s1
    jal flatten
    li $t0 0x000000
    sw $t0 0($v0) # store pixel
    sw $t0 4($v0) # store pixel
    sw $t0 8($v0) # store pixel
    li $t1 0x020101 # load color
    sw $t1 12($v0) # store pixel
    li $t1 0x603320 # load color
    sw $t1 16($v0) # store pixel
    li $t1 0x816153 # load color
    sw $t1 20($v0) # store pixel
    li $t1 0x6e6973 # load color
    sw $t1 24($v0) # store pixel
    li $t1 0x736266 # load color
    sw $t1 28($v0) # store pixel
    li $t1 0x67565d # load color
    sw $t1 32($v0) # store pixel
    li $t1 0x736870 # load color
    sw $t1 36($v0) # store pixel
    li $t1 0x384041 # load color
    sw $t1 40($v0) # store pixel
    sw $t0 44($v0) # store pixel
    sw $t0 48($v0) # store pixel
    sw $t0 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    li $t1 0x010000 # load color
    sw $t1 0($v0) # store pixel
    sw $t0 4($v0) # store pixel
    li $t1 0x301c14 # load color
    sw $t1 8($v0) # store pixel
    li $t1 0xb46548 # load color
    sw $t1 12($v0) # store pixel
    li $t1 0xf2beaa # load color
    sw $t1 16($v0) # store pixel
    li $t1 0xd29dae # load color
    sw $t1 20($v0) # store pixel
    li $t1 0xbe728e # load color
    sw $t1 24($v0) # store pixel
    li $t1 0xdc8998 # load color
    sw $t1 28($v0) # store pixel
    li $t1 0xda8795 # load color
    sw $t1 32($v0) # store pixel
    li $t1 0xc37691 # load color
    sw $t1 36($v0) # store pixel
    li $t1 0xc28d98 # load color
    sw $t1 40($v0) # store pixel
    li $t1 0x926857 # load color
    sw $t1 44($v0) # store pixel
    li $t1 0x060103 # load color
    sw $t1 48($v0) # store pixel
    sw $t0 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    sw $t0 0($v0) # store pixel
    li $t1 0x0e0805 # load color
    sw $t1 4($v0) # store pixel
    li $t1 0xaf6347 # load color
    sw $t1 8($v0) # store pixel
    li $t1 0xf6986b # load color
    sw $t1 12($v0) # store pixel
    li $t1 0xbf8a94 # load color
    sw $t1 16($v0) # store pixel
    li $t1 0xb87187 # load color
    sw $t1 20($v0) # store pixel
    li $t1 0xdfa189 # load color
    sw $t1 24($v0) # store pixel
    li $t1 0xeeb988 # load color
    sw $t1 28($v0) # store pixel
    li $t1 0xf1bb8c # load color
    sw $t1 32($v0) # store pixel
    li $t1 0xe3aa87 # load color
    sw $t1 36($v0) # store pixel
    li $t1 0xc78190 # load color
    sw $t1 40($v0) # store pixel
    li $t1 0xe48a80 # load color
    sw $t1 44($v0) # store pixel
    li $t1 0x986141 # load color
    sw $t1 48($v0) # store pixel
    li $t1 0x0f0a0b # load color
    sw $t1 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    sw $t0 0($v0) # store pixel
    li $t1 0x27150f # load color
    sw $t1 4($v0) # store pixel
    li $t1 0xd87c5d # load color
    sw $t1 8($v0) # store pixel
    li $t1 0xf3c56f # load color
    sw $t1 12($v0) # store pixel
    li $t1 0xde8b64 # load color
    sw $t1 16($v0) # store pixel
    li $t1 0xf4bf79 # load color
    sw $t1 20($v0) # store pixel
    li $t1 0xfdd972 # load color
    sw $t1 24($v0) # store pixel
    li $t1 0xfddd6f # load color
    sw $t1 28($v0) # store pixel
    li $t1 0xfcd96a # load color
    sw $t1 32($v0) # store pixel
    li $t1 0xfedc71 # load color
    sw $t1 36($v0) # store pixel
    li $t1 0xf7cc7a # load color
    sw $t1 40($v0) # store pixel
    li $t1 0xf4cc82 # load color
    sw $t1 44($v0) # store pixel
    li $t1 0xfdd175 # load color
    sw $t1 48($v0) # store pixel
    li $t1 0x4a3322 # load color
    sw $t1 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    sw $t0 0($v0) # store pixel
    li $t1 0x7d4333 # load color
    sw $t1 4($v0) # store pixel
    li $t1 0xf5a86d # load color
    sw $t1 8($v0) # store pixel
    li $t1 0xfada75 # load color
    sw $t1 12($v0) # store pixel
    li $t1 0xedb27a # load color
    sw $t1 16($v0) # store pixel
    li $t1 0xfdf1b7 # load color
    sw $t1 20($v0) # store pixel
    li $t1 0xf4ca87 # load color
    sw $t1 24($v0) # store pixel
    li $t1 0xf9da8c # load color
    sw $t1 28($v0) # store pixel
    li $t1 0xfef0bc # load color
    sw $t1 32($v0) # store pixel
    li $t1 0xf4c67d # load color
    sw $t1 36($v0) # store pixel
    li $t1 0xffeea1 # load color
    sw $t1 40($v0) # store pixel
    li $t1 0xf5cf93 # load color
    sw $t1 44($v0) # store pixel
    li $t1 0xfbcb73 # load color
    sw $t1 48($v0) # store pixel
    li $t1 0xb39355 # load color
    sw $t1 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    sw $t0 0($v0) # store pixel
    li $t1 0x914f3c # load color
    sw $t1 4($v0) # store pixel
    li $t1 0xfec879 # load color
    sw $t1 8($v0) # store pixel
    li $t1 0xf0c06e # load color
    sw $t1 12($v0) # store pixel
    li $t1 0xfcd07d # load color
    sw $t1 16($v0) # store pixel
    li $t1 0xfccb8a # load color
    sw $t1 20($v0) # store pixel
    li $t1 0xc26f50 # load color
    sw $t1 24($v0) # store pixel
    li $t1 0xf7da7d # load color
    sw $t1 28($v0) # store pixel
    li $t1 0xffe28e # load color
    sw $t1 32($v0) # store pixel
    li $t1 0xb86a46 # load color
    sw $t1 36($v0) # store pixel
    li $t1 0xdd9f69 # load color
    sw $t1 40($v0) # store pixel
    li $t1 0xfade85 # load color
    sw $t1 44($v0) # store pixel
    li $t1 0xea9f63 # load color
    sw $t1 48($v0) # store pixel
    li $t1 0xbba15a # load color
    sw $t1 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    li $t1 0x010000 # load color
    sw $t1 0($v0) # store pixel
    li $t1 0x99543d # load color
    sw $t1 4($v0) # store pixel
    li $t1 0xf6bb6f # load color
    sw $t1 8($v0) # store pixel
    li $t1 0xf5c172 # load color
    sw $t1 12($v0) # store pixel
    li $t1 0xd1915a # load color
    sw $t1 16($v0) # store pixel
    li $t1 0x763d1d # load color
    sw $t1 20($v0) # store pixel
    li $t1 0x854c39 # load color
    sw $t1 24($v0) # store pixel
    li $t1 0xf1cc71 # load color
    sw $t1 28($v0) # store pixel
    li $t1 0xd8804e # load color
    sw $t1 32($v0) # store pixel
    li $t1 0x452422 # load color
    sw $t1 36($v0) # store pixel
    li $t1 0x814839 # load color
    sw $t1 40($v0) # store pixel
    li $t1 0xf6b768 # load color
    sw $t1 44($v0) # store pixel
    li $t1 0xb77648 # load color
    sw $t1 48($v0) # store pixel
    li $t1 0xa5844d # load color
    sw $t1 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    sw $t0 0($v0) # store pixel
    li $t1 0x924f39 # load color
    sw $t1 4($v0) # store pixel
    li $t1 0xe2ae62 # load color
    sw $t1 8($v0) # store pixel
    li $t1 0xf7c86f # load color
    sw $t1 12($v0) # store pixel
    li $t1 0x7b514c # load color
    sw $t1 16($v0) # store pixel
    li $t1 0x383d49 # load color
    sw $t1 20($v0) # store pixel
    li $t1 0x605d56 # load color
    sw $t1 24($v0) # store pixel
    li $t1 0xf3b091 # load color
    sw $t1 28($v0) # store pixel
    li $t1 0xecbbb2 # load color
    sw $t1 32($v0) # store pixel
    li $t1 0x698d9f # load color
    sw $t1 36($v0) # store pixel
    li $t1 0xbb9285 # load color
    sw $t1 40($v0) # store pixel
    li $t1 0xdb9251 # load color
    sw $t1 44($v0) # store pixel
    li $t1 0x583421 # load color
    sw $t1 48($v0) # store pixel
    li $t1 0x1e1c11 # load color
    sw $t1 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    li $t1 0x533125 # load color
    sw $t1 0($v0) # store pixel
    li $t1 0xd37854 # load color
    sw $t1 4($v0) # store pixel
    li $t1 0xd69c5c # load color
    sw $t1 8($v0) # store pixel
    li $t1 0xf3c66a # load color
    sw $t1 12($v0) # store pixel
    li $t1 0xdaac83 # load color
    sw $t1 16($v0) # store pixel
    li $t1 0x71b6c7 # load color
    sw $t1 20($v0) # store pixel
    li $t1 0x8eb6b8 # load color
    sw $t1 24($v0) # store pixel
    li $t1 0xffe8df # load color
    sw $t1 28($v0) # store pixel
    li $t1 0xfcede5 # load color
    sw $t1 32($v0) # store pixel
    li $t1 0x92c9cf # load color
    sw $t1 36($v0) # store pixel
    li $t1 0xc1937d # load color
    sw $t1 40($v0) # store pixel
    li $t1 0xbd6643 # load color
    sw $t1 44($v0) # store pixel
    li $t1 0x221412 # load color
    sw $t1 48($v0) # store pixel
    sw $t0 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    li $t1 0x553327 # load color
    sw $t1 0($v0) # store pixel
    li $t1 0xe1825a # load color
    sw $t1 4($v0) # store pixel
    li $t1 0xb16141 # load color
    sw $t1 8($v0) # store pixel
    li $t1 0xe7935f # load color
    sw $t1 12($v0) # store pixel
    li $t1 0xd08b66 # load color
    sw $t1 16($v0) # store pixel
    li $t1 0x89a0a8 # load color
    sw $t1 20($v0) # store pixel
    li $t1 0xb9c1c1 # load color
    sw $t1 24($v0) # store pixel
    li $t1 0xfff3e6 # load color
    sw $t1 28($v0) # store pixel
    li $t1 0xfee9e0 # load color
    sw $t1 32($v0) # store pixel
    li $t1 0xe5bbb2 # load color
    sw $t1 36($v0) # store pixel
    li $t1 0xd37e60 # load color
    sw $t1 40($v0) # store pixel
    li $t1 0x9d593d # load color
    sw $t1 44($v0) # store pixel
    li $t1 0x0c0605 # load color
    sw $t1 48($v0) # store pixel
    sw $t0 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    li $t1 0x241512 # load color
    sw $t1 0($v0) # store pixel
    li $t1 0x754432 # load color
    sw $t1 4($v0) # store pixel
    li $t1 0x412316 # load color
    sw $t1 8($v0) # store pixel
    li $t1 0x874832 # load color
    sw $t1 12($v0) # store pixel
    li $t1 0xbc7050 # load color
    sw $t1 16($v0) # store pixel
    li $t1 0xf0b4b3 # load color
    sw $t1 20($v0) # store pixel
    li $t1 0xffded7 # load color
    sw $t1 24($v0) # store pixel
    li $t1 0xdc999b # load color
    sw $t1 28($v0) # store pixel
    li $t1 0xeeb4b8 # load color
    sw $t1 32($v0) # store pixel
    li $t1 0x9f7876 # load color
    sw $t1 36($v0) # store pixel
    li $t1 0x81452b # load color
    sw $t1 40($v0) # store pixel
    li $t1 0x4b2b1f # load color
    sw $t1 44($v0) # store pixel
    sw $t0 48($v0) # store pixel
    sw $t0 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    li $t1 0x232331 # load color
    sw $t1 0($v0) # store pixel
    li $t1 0x160d0b # load color
    sw $t1 4($v0) # store pixel
    li $t1 0x000103 # load color
    sw $t1 8($v0) # store pixel
    li $t1 0x060100 # load color
    sw $t1 12($v0) # store pixel
    li $t1 0x7d5142 # load color
    sw $t1 16($v0) # store pixel
    li $t1 0xdbd1df # load color
    sw $t1 20($v0) # store pixel
    li $t1 0xe1b4bb # load color
    sw $t1 24($v0) # store pixel
    li $t1 0xd27e89 # load color
    sw $t1 28($v0) # store pixel
    li $t1 0xd9949f # load color
    sw $t1 32($v0) # store pixel
    li $t1 0xc7bac1 # load color
    sw $t1 36($v0) # store pixel
    li $t1 0x40262c # load color
    sw $t1 40($v0) # store pixel
    li $t1 0x010000 # load color
    sw $t1 44($v0) # store pixel
    sw $t0 48($v0) # store pixel
    sw $t0 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    li $t1 0x0c0b0f # load color
    sw $t1 0($v0) # store pixel
    sw $t0 4($v0) # store pixel
    sw $t0 8($v0) # store pixel
    sw $t0 12($v0) # store pixel
    li $t1 0x1c2e51 # load color
    sw $t1 16($v0) # store pixel
    li $t1 0x383d57 # load color
    sw $t1 20($v0) # store pixel
    li $t1 0x5e5e7e # load color
    sw $t1 24($v0) # store pixel
    li $t1 0x838999 # load color
    sw $t1 28($v0) # store pixel
    li $t1 0x706e77 # load color
    sw $t1 32($v0) # store pixel
    li $t1 0x27283a # load color
    sw $t1 36($v0) # store pixel
    li $t1 0x080e27 # load color
    sw $t1 40($v0) # store pixel
    li $t1 0x010103 # load color
    sw $t1 44($v0) # store pixel
    sw $t0 48($v0) # store pixel
    sw $t0 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    sw $t0 0($v0) # store pixel
    li $t1 0x010101 # load color
    sw $t1 4($v0) # store pixel
    li $t1 0x080706 # load color
    sw $t1 8($v0) # store pixel
    li $t1 0x4b536d # load color
    sw $t1 12($v0) # store pixel
    li $t1 0x3f5480 # load color
    sw $t1 16($v0) # store pixel
    li $t1 0x000012 # load color
    sw $t1 20($v0) # store pixel
    li $t1 0x707694 # load color
    sw $t1 24($v0) # store pixel
    li $t1 0xd8d3e1 # load color
    sw $t1 28($v0) # store pixel
    li $t1 0xcfcbd7 # load color
    sw $t1 32($v0) # store pixel
    li $t1 0x717b9c # load color
    sw $t1 36($v0) # store pixel
    li $t1 0x383c4e # load color
    sw $t1 40($v0) # store pixel
    li $t1 0x0c0b0c # load color
    sw $t1 44($v0) # store pixel
    sw $t0 48($v0) # store pixel
    li $t1 0x000001 # load color
    sw $t1 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    li $t1 0x010101 # load color
    sw $t1 0($v0) # store pixel
    sw $t0 4($v0) # store pixel
    li $t1 0x030302 # load color
    sw $t1 8($v0) # store pixel
    li $t1 0x4d4e52 # load color
    sw $t1 12($v0) # store pixel
    li $t1 0x67677c # load color
    sw $t1 16($v0) # store pixel
    li $t1 0x7983a2 # load color
    sw $t1 20($v0) # store pixel
    li $t1 0x7d85a8 # load color
    sw $t1 24($v0) # store pixel
    li $t1 0x959cba # load color
    sw $t1 28($v0) # store pixel
    li $t1 0xc6cbde # load color
    sw $t1 32($v0) # store pixel
    li $t1 0x9ca0bd # load color
    sw $t1 36($v0) # store pixel
    li $t1 0x3c3c4a # load color
    sw $t1 40($v0) # store pixel
    li $t1 0x09080b # load color
    sw $t1 44($v0) # store pixel
    sw $t0 48($v0) # store pixel
    sw $t0 52($v0) # store pixel
    addi $v0 $v0 WIDTH # go to next row
    sw $t0 0($v0) # store pixel
    sw $t0 4($v0) # store pixel
    sw $t0 8($v0) # store pixel
    sw $t0 12($v0) # store pixel
    li $t1 0x1b1a23 # load color
    sw $t1 16($v0) # store pixel
    li $t1 0x8e8da0 # load color
    sw $t1 20($v0) # store pixel
    li $t1 0x565560 # load color
    sw $t1 24($v0) # store pixel
    li $t1 0x000514 # load color
    sw $t1 28($v0) # store pixel
    li $t1 0x838295 # load color
    sw $t1 32($v0) # store pixel
    li $t1 0x51505c # load color
    sw $t1 36($v0) # store pixel
    sw $t0 40($v0) # store pixel
    sw $t0 44($v0) # store pixel
    sw $t0 48($v0) # store pixel
    sw $t0 52($v0) # store pixel

    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4
    jr $ra # return