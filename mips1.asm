.eqv BASE_ADDRESS  0x10008000 # ($gp)
.eqv BACKGROUND    0          # background color
.eqv WIDTH         512        # screen width in bytes
.eqv WIDTH_SHIFT   9          # screen width in bytes for sll
.eqv PLAYER_WIDTH  14
.eqv PLAYER_HEIGHT 16

.data padding: .space 36000 # space padding to support 128x128 resolution
.text

.globl main
main:
    li $s0, 1 # player x
    li $s1, 1 # player y

    jal draw_player
    loop:
        li $a0, 0xffff0000 # check keypress
        lw $t0, 0($a0)
        bne $t0, 1, update # skip keypressed if no press
        jal keypressed

        update:
        li $a0, 20 # sleep 20 ms
        li $v0, 32
        syscall
        j loop

    li $v0, 10 # terminate the program gracefully
    syscall

keypressed: # handle keypress in 4($a0)
    addi $sp, $sp, -4 # push ra to stack
    sw $ra, 0($sp)

    lw $t0, 4($a0)
    beq $t0, 0x77, keypressed_w
    beq $t0, 0x61, keypressed_a
    beq $t0, 0x73, keypressed_s
    beq $t0, 0x64, keypressed_d

    keypressed_w:
    li $a0, 0
    li $a1, -1
    j keypressed_move

    keypressed_a:
    li $a0, -1
    li $a1, 0
    j keypressed_move

    keypressed_s:
    li $a0, 0
    li $a1, 1
    j keypressed_move

    keypressed_d:
    li $a0, 1
    li $a1, 0
    j keypressed_move

    keypressed_move:
    jal player_move

    keypressed_end:
    lw $ra, 0($sp) # pop ra from stack
    addi $sp, $sp, 4
    jr $ra # return

player_move: # move towards (a0, a1)
    # todo check collision and boundary
    addi $sp, $sp, -4 # push ra to stack
    sw $ra, 0($sp)

    add $s0, $s0, $a0 # move x
    add $s1, $s1, $a1 # move y
    jal draw_player # draw player at new position

    lw $ra, 0($sp) # pop ra from stack
    addi $sp, $sp, 4
    jr $ra # return

flatten: # convert (a0, a1) to pixel address in display in v0
    sll $v0, $a1, WIDTH_SHIFT
    sll $a0, $a0, 2 # convert to byte position
    add $v0, $v0, BASE_ADDRESS
    add $v0, $v0, $a0
    jr $ra # jump to caller

draw_player: # start at (s0, s1)
    addi $sp, $sp, -4 # push ra to stack
    sw $ra, 0($sp)

    move $a0, $s0 # compute start position to v0
    move $a1, $s1
    jal flatten

    li $t0, 0x000000 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0x020101 # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0x603320 # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0x816153 # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0x6e6973 # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0x736266 # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0x67565d # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0x736870 # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0x384041 # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x010000 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0x301c14 # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0xb46548 # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0xf2beaa # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0xd29dae # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0xbe728e # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0xdc8998 # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0xda8795 # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0xc37691 # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0xc28d98 # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0x926857 # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0x060103 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x000000 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0x0e0805 # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0xaf6347 # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0xf6986b # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0xbf8a94 # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0xb87187 # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0xdfa189 # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0xeeb988 # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0xf1bb8c # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0xe3aa87 # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0xc78190 # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0xe48a80 # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0x986141 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0x0f0a0b # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x000000 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0x27150f # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0xd87c5d # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0xf3c56f # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0xde8b64 # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0xf4bf79 # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0xfdd972 # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0xfddd6f # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0xfcd96a # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0xfedc71 # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0xf7cc7a # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0xf4cc82 # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0xfdd175 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0x4a3322 # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x000000 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0x7d4333 # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0xf5a86d # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0xfada75 # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0xedb27a # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0xfdf1b7 # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0xf4ca87 # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0xf9da8c # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0xfef0bc # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0xf4c67d # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0xffeea1 # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0xf5cf93 # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0xfbcb73 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0xb39355 # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x000000 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0x914f3c # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0xfec879 # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0xf0c06e # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0xfcd07d # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0xfccb8a # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0xc26f50 # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0xf7da7d # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0xffe28e # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0xb86a46 # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0xdd9f69 # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0xfade85 # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0xea9f63 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0xbba15a # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x010000 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0x99543d # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0xf6bb6f # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0xf5c172 # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0xd1915a # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0x763d1d # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0x854c39 # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0xf1cc71 # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0xd8804e # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0x452422 # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0x814839 # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0xf6b768 # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0xb77648 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0xa5844d # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x000000 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0x924f39 # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0xe2ae62 # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0xf7c86f # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0x7b514c # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0x383d49 # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0x605d56 # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0xf3b091 # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0xecbbb2 # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0x698d9f # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0xbb9285 # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0xdb9251 # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0x583421 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0x1e1c11 # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x533125 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0xd37854 # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0xd69c5c # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0xf3c66a # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0xdaac83 # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0x71b6c7 # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0x8eb6b8 # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0xffe8df # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0xfcede5 # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0x92c9cf # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0xc1937d # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0xbd6643 # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0x221412 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x553327 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0xe1825a # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0xb16141 # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0xe7935f # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0xd08b66 # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0x89a0a8 # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0xb9c1c1 # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0xfff3e6 # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0xfee9e0 # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0xe5bbb2 # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0xd37e60 # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0x9d593d # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0x0c0605 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x241512 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0x754432 # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0x412316 # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0x874832 # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0xbc7050 # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0xf0b4b3 # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0xffded7 # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0xdc999b # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0xeeb4b8 # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0x9f7876 # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0x81452b # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0x4b2b1f # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x232331 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0x160d0b # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0x000103 # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0x060100 # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0x7d5142 # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0xdbd1df # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0xe1b4bb # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0xd27e89 # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0xd9949f # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0xc7bac1 # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0x40262c # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0x010000 # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x0c0b0f # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0x1c2e51 # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0x383d57 # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0x5e5e7e # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0x838999 # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0x706e77 # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0x27283a # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0x080e27 # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0x010103 # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x000000 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0x010101 # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0x080706 # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0x4b536d # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0x3f5480 # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0x000012 # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0x707694 # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0xd8d3e1 # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0xcfcbd7 # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0x717b9c # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0x383c4e # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0x0c0b0c # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0x000001 # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x010101 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0x030302 # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0x4d4e52 # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0x67677c # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0x7983a2 # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0x7d85a8 # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0x959cba # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0xc6cbde # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0x9ca0bd # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0x3c3c4a # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0x09080b # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 52($v0) # store pixel
    addi $v0, $v0, WIDTH # go to next row
    li $t0, 0x000000 # load color
    sw $t0, 0($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 4($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 8($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 12($v0) # store pixel
    li $t0, 0x1b1a23 # load color
    sw $t0, 16($v0) # store pixel
    li $t0, 0x8e8da0 # load color
    sw $t0, 20($v0) # store pixel
    li $t0, 0x565560 # load color
    sw $t0, 24($v0) # store pixel
    li $t0, 0x000514 # load color
    sw $t0, 28($v0) # store pixel
    li $t0, 0x838295 # load color
    sw $t0, 32($v0) # store pixel
    li $t0, 0x51505c # load color
    sw $t0, 36($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 40($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 44($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 48($v0) # store pixel
    li $t0, 0x000000 # load color
    sw $t0, 52($v0) # store pixel

    lw $ra, 0($sp) # pop ra from stack
    addi $sp, $sp, 4
    jr $ra # return
