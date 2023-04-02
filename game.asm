
# s0 player x in bytes
# s1 player y in bytes
# s2 gravity x
# s3 gravity y
# s4
# s5 landed
# s6 jump distance left
# s7 end of platform array

# NOTE: 1 pixel === 4 bytes
.eqv BASE_ADDRESS   0x10008000  # ($gp)
.eqv REFRESH_RATE   40          # in miliseconds
.eqv SIZE           512         # screen width & height in bytes
.eqv WIDTH_SHIFT    7           # 4 << WIDTH_SHIFT == SIZE
.eqv PLAYER_WIDTH   56          # in bytes
.eqv PLAYER_HEIGHT  64          # in bytes
.eqv BACKGROUND     $0          # black
.eqv PLAYER_INIT    32          # initial position
.eqv PLATFORMS      4           # number of platforms
.eqv JUMP_HEIGHT    128         # in bytes

.data
# space padding to support 128x128 resolution
padding: .space 36000
# bounding boxes (x1, y1, x2, y2) inclusive for collisions, each box is 16 bytes
platforms: .word 0 96 124 108 208 400 300 412 0 496 124 508 400 496 508 508
.text

clear_screen:
    li $t0 BASE_ADDRESS
    li $t1 0x10018000
    clear_screen_loop:
        sw $0 0($t0)
        addi $t0 $t0 4
        ble $t0 $t1 clear_screen_loop

.globl main
main:
    li $s0 PLAYER_INIT # player x
    li $s1 PLAYER_INIT # player y
    li $s2 0 # gravity x
    li $s3 4 # gravity y
    li $s5 0 # landed

    li $s6 0 # jump distance left
    la $s7 platforms
    li $t0 PLATFORMS
    sll $t0 $t0 4
    add $s7 $s7 $t0  # end of platforms

    jal flatten_current # get current position to v0
    jal draw_player
    jal draw_stage
    loop:
        li $a0 0xffff0000 # check keypress
        lw $t0 0($a0)
        la $ra gravity
        beq $t0 1 keypressed # handle keypress

        bnez $s5 refresh # skip gravity if landed
        gravity:
        move $a0 $s2 # update player position
        move $a1 $s3
        beq $s6 0 gravity_end
            neg $a0 $a0 # reverse gravity
            neg $a1 $a1
            sub $s6 $s6 $s2 # update jump distance, assume s2 == 0 or s3 == 0
            sub $s6 $s6 $s3
        gravity_end:
        jal player_move

        refresh:
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
    beq $t0 0x20 keypressed_spc
    beq $t0 0x77 keypressed_spc
    beq $t0 0x61 keypressed_a
    beq $t0 0x73 keypressed_s
    beq $t0 0x64 keypressed_d

    la $ra keypressed_end
    keypressed_spc:
    beqz $s5 keypressed_end # not landed
    li $s6 JUMP_HEIGHT # jump
    li $a0 0
    li $a1 -4
    j player_move

    keypressed_w:
    li $a0 0
    li $a1 -4
    j player_move

    keypressed_a:
    li $a0 -4
    li $a1 0
    j player_move

    keypressed_s:
    li $a0 0
    li $a1 4
    j player_move

    keypressed_d:
    li $a0 4
    li $a1 0
    j player_move

    keypressed_end:
    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4
    jr $ra # return

player_move: # move towards (a0, a1)
    addi $sp $sp -4 # push ra to stack
    sw $ra 0($sp)

    sll $a3 $s1 WIDTH_SHIFT # save previous position to a3
    add $a3 $a3 BASE_ADDRESS
    add $a3 $a3 $s0

    add $t0 $s0 $a0 # get new coordinates
    add $t1 $s1 $a1

    # check in bounds
    bltz $t0 player_move_end
    bltz $t1 player_move_end
    add $t2 $t0 PLAYER_WIDTH
    bge $t2 SIZE player_move_end
    add $t3 $t1 PLAYER_HEIGHT
    bge $t3 SIZE player_move_end

    # check collision, player box is (t0, t1, t2, t3)
    la $t8 platforms # get platforms address to t8
    move $t9 $s7 # get end of platforms to t9
    collision:
        sub $t9 $t9 16 # decrement platform index
        blt $t9 $t8 collision_end # no more platforms
        lw $t4 0($t9)
        lw $t5 4($t9)
        lw $t6 8($t9)
        lw $t7 12($t9) # get platform box (t4, t5, t6, t7)

        sle $v0 $t0 $t6  # ax1 <= bx2
        slt $v1 $t4 $t2  # bx1 < ax2
        and $v0 $v0 $v1
        sle $v1 $t1 $t7  # ay1 <= by2
        and $v0 $v0 $v1
        slt $v1 $t5 $t3  # by1 < ay2
        and $v0 $v0 $v1
        beq $v0 0 collision # no collision

        # collision => landed
        li $s5 1
        j player_move_end
    collision_end:

    li $s5 0 # not landed
    move $s0 $t0 # update player position
    move $s1 $t1
    sll $v0 $s1 WIDTH_SHIFT # get current position to v0
    add $v0 $v0 BASE_ADDRESS
    add $v0 $v0 $s0
    jal draw_player # draw player at new position

    player_move_end:
    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4
    jr $ra # return

flatten_current: # convert (s0, s1) to pixel address in display in v0
    sll $v0 $s1 WIDTH_SHIFT
    add $v0 $v0 BASE_ADDRESS
    add $v0 $v0 $s0
    jr $ra # jump to caller

# flatten: # convert (a0, a1) to pixel address in display in v0
#     sll $v0 $a1 WIDTH_SHIFT
#     add $v0 $v0 BASE_ADDRESS
#     add $v0 $v0 $a0
#     jr $ra # jump to caller

# draw player at v0 with (Δx, Δy) in (a0, a1) and previous position in a2
draw_player:
    sw BACKGROUND 0($v0) # store background (0, 0)
    sw BACKGROUND 4($v0) # store background (1, 0)
    sw BACKGROUND 8($v0) # store background (2, 0)
    li $t0 0x020101 # load color
    sw $t0 12($v0) # store color (3, 0)
    li $t0 0x603320 # load color
    sw $t0 16($v0) # store color (4, 0)
    li $t0 0x816153 # load color
    sw $t0 20($v0) # store color (5, 0)
    li $t0 0x6e6973 # load color
    sw $t0 24($v0) # store color (6, 0)
    li $t0 0x736266 # load color
    sw $t0 28($v0) # store color (7, 0)
    li $t0 0x67565d # load color
    sw $t0 32($v0) # store color (8, 0)
    li $t0 0x736870 # load color
    sw $t0 36($v0) # store color (9, 0)
    li $t0 0x384041 # load color
    sw $t0 40($v0) # store color (10, 0)
    sw BACKGROUND 44($v0) # store background (11, 0)
    sw BACKGROUND 48($v0) # store background (12, 0)
    sw BACKGROUND 52($v0) # store background (13, 0)
    li $t0 0x010000 # load color
    sw $t0 512($v0) # store color (0, 1)
    sw BACKGROUND 516($v0) # store background (1, 1)
    li $t0 0x301c14 # load color
    sw $t0 520($v0) # store color (2, 1)
    li $t0 0xb46548 # load color
    sw $t0 524($v0) # store color (3, 1)
    li $t0 0xf2beaa # load color
    sw $t0 528($v0) # store color (4, 1)
    li $t0 0xd29dae # load color
    sw $t0 532($v0) # store color (5, 1)
    li $t0 0xbe728e # load color
    sw $t0 536($v0) # store color (6, 1)
    li $t0 0xdc8998 # load color
    sw $t0 540($v0) # store color (7, 1)
    li $t0 0xda8795 # load color
    sw $t0 544($v0) # store color (8, 1)
    li $t0 0xc37691 # load color
    sw $t0 548($v0) # store color (9, 1)
    li $t0 0xc28d98 # load color
    sw $t0 552($v0) # store color (10, 1)
    li $t0 0x926857 # load color
    sw $t0 556($v0) # store color (11, 1)
    li $t0 0x060103 # load color
    sw $t0 560($v0) # store color (12, 1)
    sw BACKGROUND 564($v0) # store background (13, 1)
    sw BACKGROUND 1024($v0) # store background (0, 2)
    li $t0 0x0e0805 # load color
    sw $t0 1028($v0) # store color (1, 2)
    li $t0 0xaf6347 # load color
    sw $t0 1032($v0) # store color (2, 2)
    li $t0 0xf6986b # load color
    sw $t0 1036($v0) # store color (3, 2)
    li $t0 0xbf8a94 # load color
    sw $t0 1040($v0) # store color (4, 2)
    li $t0 0xb87187 # load color
    sw $t0 1044($v0) # store color (5, 2)
    li $t0 0xdfa189 # load color
    sw $t0 1048($v0) # store color (6, 2)
    li $t0 0xeeb988 # load color
    sw $t0 1052($v0) # store color (7, 2)
    li $t0 0xf1bb8c # load color
    sw $t0 1056($v0) # store color (8, 2)
    li $t0 0xe3aa87 # load color
    sw $t0 1060($v0) # store color (9, 2)
    li $t0 0xc78190 # load color
    sw $t0 1064($v0) # store color (10, 2)
    li $t0 0xe48a80 # load color
    sw $t0 1068($v0) # store color (11, 2)
    li $t0 0x986141 # load color
    sw $t0 1072($v0) # store color (12, 2)
    li $t0 0x0f0a0b # load color
    sw $t0 1076($v0) # store color (13, 2)
    sw BACKGROUND 1536($v0) # store background (0, 3)
    li $t0 0x27150f # load color
    sw $t0 1540($v0) # store color (1, 3)
    li $t0 0xd87c5d # load color
    sw $t0 1544($v0) # store color (2, 3)
    li $t0 0xf3c56f # load color
    sw $t0 1548($v0) # store color (3, 3)
    li $t0 0xde8b64 # load color
    sw $t0 1552($v0) # store color (4, 3)
    li $t0 0xf4bf79 # load color
    sw $t0 1556($v0) # store color (5, 3)
    li $t0 0xfdd972 # load color
    sw $t0 1560($v0) # store color (6, 3)
    li $t0 0xfddd6f # load color
    sw $t0 1564($v0) # store color (7, 3)
    li $t0 0xfcd96a # load color
    sw $t0 1568($v0) # store color (8, 3)
    li $t0 0xfedc71 # load color
    sw $t0 1572($v0) # store color (9, 3)
    li $t0 0xf7cc7a # load color
    sw $t0 1576($v0) # store color (10, 3)
    li $t0 0xf4cc82 # load color
    sw $t0 1580($v0) # store color (11, 3)
    li $t0 0xfdd175 # load color
    sw $t0 1584($v0) # store color (12, 3)
    li $t0 0x4a3322 # load color
    sw $t0 1588($v0) # store color (13, 3)
    sw BACKGROUND 2048($v0) # store background (0, 4)
    li $t0 0x7d4333 # load color
    sw $t0 2052($v0) # store color (1, 4)
    li $t0 0xf5a86d # load color
    sw $t0 2056($v0) # store color (2, 4)
    li $t0 0xfada75 # load color
    sw $t0 2060($v0) # store color (3, 4)
    li $t0 0xedb27a # load color
    sw $t0 2064($v0) # store color (4, 4)
    li $t0 0xfdf1b7 # load color
    sw $t0 2068($v0) # store color (5, 4)
    li $t0 0xf4ca87 # load color
    sw $t0 2072($v0) # store color (6, 4)
    li $t0 0xf9da8c # load color
    sw $t0 2076($v0) # store color (7, 4)
    li $t0 0xfef0bc # load color
    sw $t0 2080($v0) # store color (8, 4)
    li $t0 0xf4c67d # load color
    sw $t0 2084($v0) # store color (9, 4)
    li $t0 0xffeea1 # load color
    sw $t0 2088($v0) # store color (10, 4)
    li $t0 0xf5cf93 # load color
    sw $t0 2092($v0) # store color (11, 4)
    li $t0 0xfbcb73 # load color
    sw $t0 2096($v0) # store color (12, 4)
    li $t0 0xb39355 # load color
    sw $t0 2100($v0) # store color (13, 4)
    sw BACKGROUND 2560($v0) # store background (0, 5)
    li $t0 0x914f3c # load color
    sw $t0 2564($v0) # store color (1, 5)
    li $t0 0xfec879 # load color
    sw $t0 2568($v0) # store color (2, 5)
    li $t0 0xf0c06e # load color
    sw $t0 2572($v0) # store color (3, 5)
    li $t0 0xfcd07d # load color
    sw $t0 2576($v0) # store color (4, 5)
    li $t0 0xfccb8a # load color
    sw $t0 2580($v0) # store color (5, 5)
    li $t0 0xc26f50 # load color
    sw $t0 2584($v0) # store color (6, 5)
    li $t0 0xf7da7d # load color
    sw $t0 2588($v0) # store color (7, 5)
    li $t0 0xffe28e # load color
    sw $t0 2592($v0) # store color (8, 5)
    li $t0 0xb86a46 # load color
    sw $t0 2596($v0) # store color (9, 5)
    li $t0 0xdd9f69 # load color
    sw $t0 2600($v0) # store color (10, 5)
    li $t0 0xfade85 # load color
    sw $t0 2604($v0) # store color (11, 5)
    li $t0 0xea9f63 # load color
    sw $t0 2608($v0) # store color (12, 5)
    li $t0 0xbba15a # load color
    sw $t0 2612($v0) # store color (13, 5)
    li $t0 0x010000 # load color
    sw $t0 3072($v0) # store color (0, 6)
    li $t0 0x99543d # load color
    sw $t0 3076($v0) # store color (1, 6)
    li $t0 0xf6bb6f # load color
    sw $t0 3080($v0) # store color (2, 6)
    li $t0 0xf5c172 # load color
    sw $t0 3084($v0) # store color (3, 6)
    li $t0 0xd1915a # load color
    sw $t0 3088($v0) # store color (4, 6)
    li $t0 0x763d1d # load color
    sw $t0 3092($v0) # store color (5, 6)
    li $t0 0x854c39 # load color
    sw $t0 3096($v0) # store color (6, 6)
    li $t0 0xf1cc71 # load color
    sw $t0 3100($v0) # store color (7, 6)
    li $t0 0xd8804e # load color
    sw $t0 3104($v0) # store color (8, 6)
    li $t0 0x452422 # load color
    sw $t0 3108($v0) # store color (9, 6)
    li $t0 0x814839 # load color
    sw $t0 3112($v0) # store color (10, 6)
    li $t0 0xf6b768 # load color
    sw $t0 3116($v0) # store color (11, 6)
    li $t0 0xb77648 # load color
    sw $t0 3120($v0) # store color (12, 6)
    li $t0 0xa5844d # load color
    sw $t0 3124($v0) # store color (13, 6)
    sw BACKGROUND 3584($v0) # store background (0, 7)
    li $t0 0x924f39 # load color
    sw $t0 3588($v0) # store color (1, 7)
    li $t0 0xe2ae62 # load color
    sw $t0 3592($v0) # store color (2, 7)
    li $t0 0xf7c86f # load color
    sw $t0 3596($v0) # store color (3, 7)
    li $t0 0x7b514c # load color
    sw $t0 3600($v0) # store color (4, 7)
    li $t0 0x383d49 # load color
    sw $t0 3604($v0) # store color (5, 7)
    li $t0 0x605d56 # load color
    sw $t0 3608($v0) # store color (6, 7)
    li $t0 0xf3b091 # load color
    sw $t0 3612($v0) # store color (7, 7)
    li $t0 0xecbbb2 # load color
    sw $t0 3616($v0) # store color (8, 7)
    li $t0 0x698d9f # load color
    sw $t0 3620($v0) # store color (9, 7)
    li $t0 0xbb9285 # load color
    sw $t0 3624($v0) # store color (10, 7)
    li $t0 0xdb9251 # load color
    sw $t0 3628($v0) # store color (11, 7)
    li $t0 0x583421 # load color
    sw $t0 3632($v0) # store color (12, 7)
    li $t0 0x1e1c11 # load color
    sw $t0 3636($v0) # store color (13, 7)
    li $t0 0x533125 # load color
    sw $t0 4096($v0) # store color (0, 8)
    li $t0 0xd37854 # load color
    sw $t0 4100($v0) # store color (1, 8)
    li $t0 0xd69c5c # load color
    sw $t0 4104($v0) # store color (2, 8)
    li $t0 0xf3c66a # load color
    sw $t0 4108($v0) # store color (3, 8)
    li $t0 0xdaac83 # load color
    sw $t0 4112($v0) # store color (4, 8)
    li $t0 0x71b6c7 # load color
    sw $t0 4116($v0) # store color (5, 8)
    li $t0 0x8eb6b8 # load color
    sw $t0 4120($v0) # store color (6, 8)
    li $t0 0xffe8df # load color
    sw $t0 4124($v0) # store color (7, 8)
    li $t0 0xfcede5 # load color
    sw $t0 4128($v0) # store color (8, 8)
    li $t0 0x92c9cf # load color
    sw $t0 4132($v0) # store color (9, 8)
    li $t0 0xc1937d # load color
    sw $t0 4136($v0) # store color (10, 8)
    li $t0 0xbd6643 # load color
    sw $t0 4140($v0) # store color (11, 8)
    li $t0 0x221412 # load color
    sw $t0 4144($v0) # store color (12, 8)
    sw BACKGROUND 4148($v0) # store background (13, 8)
    li $t0 0x553327 # load color
    sw $t0 4608($v0) # store color (0, 9)
    li $t0 0xe1825a # load color
    sw $t0 4612($v0) # store color (1, 9)
    li $t0 0xb16141 # load color
    sw $t0 4616($v0) # store color (2, 9)
    li $t0 0xe7935f # load color
    sw $t0 4620($v0) # store color (3, 9)
    li $t0 0xd08b66 # load color
    sw $t0 4624($v0) # store color (4, 9)
    li $t0 0x89a0a8 # load color
    sw $t0 4628($v0) # store color (5, 9)
    li $t0 0xb9c1c1 # load color
    sw $t0 4632($v0) # store color (6, 9)
    li $t0 0xfff3e6 # load color
    sw $t0 4636($v0) # store color (7, 9)
    li $t0 0xfee9e0 # load color
    sw $t0 4640($v0) # store color (8, 9)
    li $t0 0xe5bbb2 # load color
    sw $t0 4644($v0) # store color (9, 9)
    li $t0 0xd37e60 # load color
    sw $t0 4648($v0) # store color (10, 9)
    li $t0 0x9d593d # load color
    sw $t0 4652($v0) # store color (11, 9)
    li $t0 0x0c0605 # load color
    sw $t0 4656($v0) # store color (12, 9)
    sw BACKGROUND 4660($v0) # store background (13, 9)
    li $t0 0x241512 # load color
    sw $t0 5120($v0) # store color (0, 10)
    li $t0 0x754432 # load color
    sw $t0 5124($v0) # store color (1, 10)
    li $t0 0x412316 # load color
    sw $t0 5128($v0) # store color (2, 10)
    li $t0 0x874832 # load color
    sw $t0 5132($v0) # store color (3, 10)
    li $t0 0xbc7050 # load color
    sw $t0 5136($v0) # store color (4, 10)
    li $t0 0xf0b4b3 # load color
    sw $t0 5140($v0) # store color (5, 10)
    li $t0 0xffded7 # load color
    sw $t0 5144($v0) # store color (6, 10)
    li $t0 0xdc999b # load color
    sw $t0 5148($v0) # store color (7, 10)
    li $t0 0xeeb4b8 # load color
    sw $t0 5152($v0) # store color (8, 10)
    li $t0 0x9f7876 # load color
    sw $t0 5156($v0) # store color (9, 10)
    li $t0 0x81452b # load color
    sw $t0 5160($v0) # store color (10, 10)
    li $t0 0x4b2b1f # load color
    sw $t0 5164($v0) # store color (11, 10)
    sw BACKGROUND 5168($v0) # store background (12, 10)
    sw BACKGROUND 5172($v0) # store background (13, 10)
    li $t0 0x232331 # load color
    sw $t0 5632($v0) # store color (0, 11)
    li $t0 0x160d0b # load color
    sw $t0 5636($v0) # store color (1, 11)
    li $t0 0x000103 # load color
    sw $t0 5640($v0) # store color (2, 11)
    li $t0 0x060100 # load color
    sw $t0 5644($v0) # store color (3, 11)
    li $t0 0x7d5142 # load color
    sw $t0 5648($v0) # store color (4, 11)
    li $t0 0xdbd1df # load color
    sw $t0 5652($v0) # store color (5, 11)
    li $t0 0xe1b4bb # load color
    sw $t0 5656($v0) # store color (6, 11)
    li $t0 0xd27e89 # load color
    sw $t0 5660($v0) # store color (7, 11)
    li $t0 0xd9949f # load color
    sw $t0 5664($v0) # store color (8, 11)
    li $t0 0xc7bac1 # load color
    sw $t0 5668($v0) # store color (9, 11)
    li $t0 0x40262c # load color
    sw $t0 5672($v0) # store color (10, 11)
    li $t0 0x010000 # load color
    sw $t0 5676($v0) # store color (11, 11)
    sw BACKGROUND 5680($v0) # store background (12, 11)
    sw BACKGROUND 5684($v0) # store background (13, 11)
    li $t0 0x0c0b0f # load color
    sw $t0 6144($v0) # store color (0, 12)
    sw BACKGROUND 6148($v0) # store background (1, 12)
    sw BACKGROUND 6152($v0) # store background (2, 12)
    sw BACKGROUND 6156($v0) # store background (3, 12)
    li $t0 0x1c2e51 # load color
    sw $t0 6160($v0) # store color (4, 12)
    li $t0 0x383d57 # load color
    sw $t0 6164($v0) # store color (5, 12)
    li $t0 0x5e5e7e # load color
    sw $t0 6168($v0) # store color (6, 12)
    li $t0 0x838999 # load color
    sw $t0 6172($v0) # store color (7, 12)
    li $t0 0x706e77 # load color
    sw $t0 6176($v0) # store color (8, 12)
    li $t0 0x27283a # load color
    sw $t0 6180($v0) # store color (9, 12)
    li $t0 0x080e27 # load color
    sw $t0 6184($v0) # store color (10, 12)
    li $t0 0x010103 # load color
    sw $t0 6188($v0) # store color (11, 12)
    sw BACKGROUND 6192($v0) # store background (12, 12)
    sw BACKGROUND 6196($v0) # store background (13, 12)
    sw BACKGROUND 6656($v0) # store background (0, 13)
    li $t0 0x010101 # load color
    sw $t0 6660($v0) # store color (1, 13)
    li $t0 0x080706 # load color
    sw $t0 6664($v0) # store color (2, 13)
    li $t0 0x4b536d # load color
    sw $t0 6668($v0) # store color (3, 13)
    li $t0 0x3f5480 # load color
    sw $t0 6672($v0) # store color (4, 13)
    li $t0 0x000012 # load color
    sw $t0 6676($v0) # store color (5, 13)
    li $t0 0x707694 # load color
    sw $t0 6680($v0) # store color (6, 13)
    li $t0 0xd8d3e1 # load color
    sw $t0 6684($v0) # store color (7, 13)
    li $t0 0xcfcbd7 # load color
    sw $t0 6688($v0) # store color (8, 13)
    li $t0 0x717b9c # load color
    sw $t0 6692($v0) # store color (9, 13)
    li $t0 0x383c4e # load color
    sw $t0 6696($v0) # store color (10, 13)
    li $t0 0x0c0b0c # load color
    sw $t0 6700($v0) # store color (11, 13)
    sw BACKGROUND 6704($v0) # store background (12, 13)
    li $t0 0x000001 # load color
    sw $t0 6708($v0) # store color (13, 13)
    li $t0 0x010101 # load color
    sw $t0 7168($v0) # store color (0, 14)
    sw BACKGROUND 7172($v0) # store background (1, 14)
    li $t0 0x030302 # load color
    sw $t0 7176($v0) # store color (2, 14)
    li $t0 0x4d4e52 # load color
    sw $t0 7180($v0) # store color (3, 14)
    li $t0 0x67677c # load color
    sw $t0 7184($v0) # store color (4, 14)
    li $t0 0x7983a2 # load color
    sw $t0 7188($v0) # store color (5, 14)
    li $t0 0x7d85a8 # load color
    sw $t0 7192($v0) # store color (6, 14)
    li $t0 0x959cba # load color
    sw $t0 7196($v0) # store color (7, 14)
    li $t0 0xc6cbde # load color
    sw $t0 7200($v0) # store color (8, 14)
    li $t0 0x9ca0bd # load color
    sw $t0 7204($v0) # store color (9, 14)
    li $t0 0x3c3c4a # load color
    sw $t0 7208($v0) # store color (10, 14)
    li $t0 0x09080b # load color
    sw $t0 7212($v0) # store color (11, 14)
    sw BACKGROUND 7216($v0) # store background (12, 14)
    sw BACKGROUND 7220($v0) # store background (13, 14)
    sw BACKGROUND 7680($v0) # store background (0, 15)
    sw BACKGROUND 7684($v0) # store background (1, 15)
    sw BACKGROUND 7688($v0) # store background (2, 15)
    sw BACKGROUND 7692($v0) # store background (3, 15)
    li $t0 0x1b1a23 # load color
    sw $t0 7696($v0) # store color (4, 15)
    li $t0 0x8e8da0 # load color
    sw $t0 7700($v0) # store color (5, 15)
    li $t0 0x565560 # load color
    sw $t0 7704($v0) # store color (6, 15)
    li $t0 0x000514 # load color
    sw $t0 7708($v0) # store color (7, 15)
    li $t0 0x838295 # load color
    sw $t0 7712($v0) # store color (8, 15)
    li $t0 0x51505c # load color
    sw $t0 7716($v0) # store color (9, 15)
    sw BACKGROUND 7720($v0) # store background (10, 15)
    sw BACKGROUND 7724($v0) # store background (11, 15)
    sw BACKGROUND 7728($v0) # store background (12, 15)
    sw BACKGROUND 7732($v0) # store background (13, 15)

    # clean previous, a3 is previous top left corner
    beqz $a1 clear_row_end # no movement on y axis
    move $t0 $a3
    bgez $a1 clear_row # skip shift
        addi $t2 $a1 PLAYER_HEIGHT
        sll $t2 $t2 WIDTH_SHIFT
        add $t0 $t0 $t2 # shift to bottom row
    clear_row:
        sw BACKGROUND 0($t0) # clear (0, y)
        sw BACKGROUND 4($t0) # clear (1, y)
        sw BACKGROUND 8($t0) # clear (2, y)
        sw BACKGROUND 12($t0) # clear (3, y)
        sw BACKGROUND 16($t0) # clear (4, y)
        sw BACKGROUND 20($t0) # clear (5, y)
        sw BACKGROUND 24($t0) # clear (6, y)
        sw BACKGROUND 28($t0) # clear (7, y)
        sw BACKGROUND 32($t0) # clear (8, y)
        sw BACKGROUND 36($t0) # clear (9, y)
        sw BACKGROUND 40($t0) # clear (10, y)
        sw BACKGROUND 44($t0) # clear (11, y)
        sw BACKGROUND 48($t0) # clear (12, y)
        sw BACKGROUND 52($t0) # clear (13, y)
        clear_row_end:
    beqz $a0 clear_end # no movement on x axis
    bgez $a0 clear_column # skip shift
        add $a3 $a3 $a0
        addi $a3 $a3 PLAYER_WIDTH # shift to right column
    clear_column:
        sw BACKGROUND 0($a3) # clear (x, 0)
        sw BACKGROUND 512($a3) # clear (x, 1)
        sw BACKGROUND 1024($a3) # clear (x, 2)
        sw BACKGROUND 1536($a3) # clear (x, 3)
        sw BACKGROUND 2048($a3) # clear (x, 4)
        sw BACKGROUND 2560($a3) # clear (x, 5)
        sw BACKGROUND 3072($a3) # clear (x, 6)
        sw BACKGROUND 3584($a3) # clear (x, 7)
        sw BACKGROUND 4096($a3) # clear (x, 8)
        sw BACKGROUND 4608($a3) # clear (x, 9)
        sw BACKGROUND 5120($a3) # clear (x, 10)
        sw BACKGROUND 5632($a3) # clear (x, 11)
        sw BACKGROUND 6144($a3) # clear (x, 12)
        sw BACKGROUND 6656($a3) # clear (x, 13)
        sw BACKGROUND 7168($a3) # clear (x, 14)
        sw BACKGROUND 7680($a3) # clear (x, 15)
    clear_end:
    jr $ra # return

draw_stage: # draw stage a0
    li $v0 BASE_ADDRESS
    li $t0 0x887143
    li $t1 0xaf8f55
    li $t2 0xc29d62
    li $t3 0x967441
    li $t4 0x9f844d
    li $t5 0x7d6739
    li $t6 0x7e6237
    li $t7 0x846d40
    li $t8 0xb8945f
    sw $t4 12288($v0)
    sw $t6 12292($v0)
    sw $t4 12296($v0)
    sw $t8 12300($v0)
    sw $t5 12304($v0)
    sw $t3 12308($v0)
    sw $t0 12312($v0)
    sw $t0 12316($v0)
    sw $t8 12320($v0)
    sw $t2 12324($v0)
    sw $t4 12328($v0)
    sw $t8 12332($v0)
    sw $t7 12336($v0)
    sw $t6 12340($v0)
    sw $t5 12344($v0)
    sw $t7 12348($v0)
    sw $t7 12352($v0)
    sw $t8 12356($v0)
    sw $t5 12360($v0)
    sw $t3 12364($v0)
    sw $t6 12368($v0)
    sw $t4 12372($v0)
    sw $t1 12376($v0)
    sw $t7 12380($v0)
    sw $t0 12384($v0)
    sw $t7 12388($v0)
    sw $t5 12392($v0)
    sw $t7 12396($v0)
    sw $t3 12400($v0)
    sw $t3 12404($v0)
    sw $t8 12408($v0)
    sw $t1 12412($v0)
    sw $t0 12800($v0)
    sw $t0 12804($v0)
    sw $t5 12808($v0)
    sw $t3 12812($v0)
    sw $t4 12816($v0)
    sw $t7 12820($v0)
    sw $t3 12824($v0)
    sw $t8 12828($v0)
    sw $t7 12832($v0)
    sw $t5 12836($v0)
    sw $t0 12840($v0)
    sw $t0 12844($v0)
    sw $t8 12848($v0)
    sw $t8 12852($v0)
    sw $t0 12856($v0)
    sw $t1 12860($v0)
    sw $t6 12864($v0)
    sw $t4 12868($v0)
    sw $t5 12872($v0)
    sw $t2 12876($v0)
    sw $t8 12880($v0)
    sw $t5 12884($v0)
    sw $t6 12888($v0)
    sw $t6 12892($v0)
    sw $t6 12896($v0)
    sw $t7 12900($v0)
    sw $t3 12904($v0)
    sw $t2 12908($v0)
    sw $t5 12912($v0)
    sw $t6 12916($v0)
    sw $t2 12920($v0)
    sw $t0 12924($v0)
    sw $t8 13312($v0)
    sw $t4 13316($v0)
    sw $t1 13320($v0)
    sw $t4 13324($v0)
    sw $t5 13328($v0)
    sw $t3 13332($v0)
    sw $t7 13336($v0)
    sw $t2 13340($v0)
    sw $t8 13344($v0)
    sw $t3 13348($v0)
    sw $t5 13352($v0)
    sw $t0 13356($v0)
    sw $t7 13360($v0)
    sw $t0 13364($v0)
    sw $t8 13368($v0)
    sw $t1 13372($v0)
    sw $t2 13376($v0)
    sw $t0 13380($v0)
    sw $t2 13384($v0)
    sw $t8 13388($v0)
    sw $t0 13392($v0)
    sw $t2 13396($v0)
    sw $t3 13400($v0)
    sw $t2 13404($v0)
    sw $t4 13408($v0)
    sw $t4 13412($v0)
    sw $t8 13416($v0)
    sw $t5 13420($v0)
    sw $t8 13424($v0)
    sw $t2 13428($v0)
    sw $t8 13432($v0)
    sw $t8 13436($v0)
    sw $t7 13824($v0)
    sw $t8 13828($v0)
    sw $t0 13832($v0)
    sw $t3 13836($v0)
    sw $t5 13840($v0)
    sw $t0 13844($v0)
    sw $t8 13848($v0)
    sw $t3 13852($v0)
    sw $t3 13856($v0)
    sw $t4 13860($v0)
    sw $t0 13864($v0)
    sw $t3 13868($v0)
    sw $t6 13872($v0)
    sw $t7 13876($v0)
    sw $t0 13880($v0)
    sw $t3 13884($v0)
    sw $t0 13888($v0)
    sw $t6 13892($v0)
    sw $t1 13896($v0)
    sw $t2 13900($v0)
    sw $t4 13904($v0)
    sw $t3 13908($v0)
    sw $t6 13912($v0)
    sw $t1 13916($v0)
    sw $t8 13920($v0)
    sw $t0 13924($v0)
    sw $t8 13928($v0)
    sw $t6 13932($v0)
    sw $t8 13936($v0)
    sw $t2 13940($v0)
    sw $t0 13944($v0)
    sw $t6 13948($v0)
    sw $t5 51408($v0)
    sw $t3 51412($v0)
    sw $t7 51416($v0)
    sw $t5 51420($v0)
    sw $t7 51424($v0)
    sw $t0 51428($v0)
    sw $t7 51432($v0)
    sw $t4 51436($v0)
    sw $t2 51440($v0)
    sw $t5 51444($v0)
    sw $t4 51448($v0)
    sw $t6 51452($v0)
    sw $t3 51456($v0)
    sw $t0 51460($v0)
    sw $t5 51464($v0)
    sw $t4 51468($v0)
    sw $t8 51472($v0)
    sw $t2 51476($v0)
    sw $t5 51480($v0)
    sw $t4 51484($v0)
    sw $t7 51488($v0)
    sw $t2 51492($v0)
    sw $t6 51496($v0)
    sw $t1 51500($v0)
    sw $t0 51920($v0)
    sw $t5 51924($v0)
    sw $t5 51928($v0)
    sw $t7 51932($v0)
    sw $t8 51936($v0)
    sw $t5 51940($v0)
    sw $t4 51944($v0)
    sw $t8 51948($v0)
    sw $t8 51952($v0)
    sw $t0 51956($v0)
    sw $t5 51960($v0)
    sw $t5 51964($v0)
    sw $t4 51968($v0)
    sw $t5 51972($v0)
    sw $t6 51976($v0)
    sw $t5 51980($v0)
    sw $t5 51984($v0)
    sw $t0 51988($v0)
    sw $t3 51992($v0)
    sw $t8 51996($v0)
    sw $t3 52000($v0)
    sw $t7 52004($v0)
    sw $t7 52008($v0)
    sw $t1 52012($v0)
    sw $t3 52432($v0)
    sw $t2 52436($v0)
    sw $t7 52440($v0)
    sw $t2 52444($v0)
    sw $t6 52448($v0)
    sw $t5 52452($v0)
    sw $t4 52456($v0)
    sw $t5 52460($v0)
    sw $t8 52464($v0)
    sw $t4 52468($v0)
    sw $t3 52472($v0)
    sw $t7 52476($v0)
    sw $t6 52480($v0)
    sw $t4 52484($v0)
    sw $t4 52488($v0)
    sw $t2 52492($v0)
    sw $t0 52496($v0)
    sw $t8 52500($v0)
    sw $t5 52504($v0)
    sw $t8 52508($v0)
    sw $t2 52512($v0)
    sw $t0 52516($v0)
    sw $t2 52520($v0)
    sw $t6 52524($v0)
    sw $t2 52944($v0)
    sw $t7 52948($v0)
    sw $t0 52952($v0)
    sw $t2 52956($v0)
    sw $t7 52960($v0)
    sw $t3 52964($v0)
    sw $t1 52968($v0)
    sw $t5 52972($v0)
    sw $t3 52976($v0)
    sw $t7 52980($v0)
    sw $t3 52984($v0)
    sw $t8 52988($v0)
    sw $t8 52992($v0)
    sw $t0 52996($v0)
    sw $t5 53000($v0)
    sw $t2 53004($v0)
    sw $t1 53008($v0)
    sw $t1 53012($v0)
    sw $t8 53016($v0)
    sw $t1 53020($v0)
    sw $t6 53024($v0)
    sw $t1 53028($v0)
    sw $t0 53032($v0)
    sw $t2 53036($v0)
    sw $t4 63488($v0)
    sw $t6 63492($v0)
    sw $t3 63496($v0)
    sw $t1 63500($v0)
    sw $t7 63504($v0)
    sw $t5 63508($v0)
    sw $t8 63512($v0)
    sw $t7 63516($v0)
    sw $t7 63520($v0)
    sw $t7 63524($v0)
    sw $t7 63528($v0)
    sw $t1 63532($v0)
    sw $t2 63536($v0)
    sw $t2 63540($v0)
    sw $t8 63544($v0)
    sw $t3 63548($v0)
    sw $t0 63552($v0)
    sw $t7 63556($v0)
    sw $t6 63560($v0)
    sw $t1 63564($v0)
    sw $t7 63568($v0)
    sw $t0 63572($v0)
    sw $t5 63576($v0)
    sw $t5 63580($v0)
    sw $t2 63584($v0)
    sw $t8 63588($v0)
    sw $t0 63592($v0)
    sw $t1 63596($v0)
    sw $t2 63600($v0)
    sw $t4 63604($v0)
    sw $t4 63608($v0)
    sw $t2 63612($v0)
    sw $t6 64000($v0)
    sw $t8 64004($v0)
    sw $t3 64008($v0)
    sw $t7 64012($v0)
    sw $t7 64016($v0)
    sw $t6 64020($v0)
    sw $t0 64024($v0)
    sw $t7 64028($v0)
    sw $t4 64032($v0)
    sw $t6 64036($v0)
    sw $t1 64040($v0)
    sw $t1 64044($v0)
    sw $t1 64048($v0)
    sw $t5 64052($v0)
    sw $t5 64056($v0)
    sw $t1 64060($v0)
    sw $t8 64064($v0)
    sw $t1 64068($v0)
    sw $t2 64072($v0)
    sw $t0 64076($v0)
    sw $t6 64080($v0)
    sw $t3 64084($v0)
    sw $t0 64088($v0)
    sw $t6 64092($v0)
    sw $t4 64096($v0)
    sw $t8 64100($v0)
    sw $t3 64104($v0)
    sw $t5 64108($v0)
    sw $t3 64112($v0)
    sw $t2 64116($v0)
    sw $t4 64120($v0)
    sw $t3 64124($v0)
    sw $t4 64512($v0)
    sw $t1 64516($v0)
    sw $t7 64520($v0)
    sw $t4 64524($v0)
    sw $t5 64528($v0)
    sw $t2 64532($v0)
    sw $t4 64536($v0)
    sw $t6 64540($v0)
    sw $t6 64544($v0)
    sw $t7 64548($v0)
    sw $t6 64552($v0)
    sw $t7 64556($v0)
    sw $t0 64560($v0)
    sw $t1 64564($v0)
    sw $t0 64568($v0)
    sw $t5 64572($v0)
    sw $t5 64576($v0)
    sw $t4 64580($v0)
    sw $t1 64584($v0)
    sw $t0 64588($v0)
    sw $t7 64592($v0)
    sw $t3 64596($v0)
    sw $t7 64600($v0)
    sw $t7 64604($v0)
    sw $t7 64608($v0)
    sw $t2 64612($v0)
    sw $t4 64616($v0)
    sw $t3 64620($v0)
    sw $t5 64624($v0)
    sw $t4 64628($v0)
    sw $t3 64632($v0)
    sw $t3 64636($v0)
    sw $t2 65024($v0)
    sw $t8 65028($v0)
    sw $t3 65032($v0)
    sw $t4 65036($v0)
    sw $t4 65040($v0)
    sw $t3 65044($v0)
    sw $t1 65048($v0)
    sw $t1 65052($v0)
    sw $t4 65056($v0)
    sw $t6 65060($v0)
    sw $t0 65064($v0)
    sw $t1 65068($v0)
    sw $t5 65072($v0)
    sw $t3 65076($v0)
    sw $t3 65080($v0)
    sw $t2 65084($v0)
    sw $t1 65088($v0)
    sw $t1 65092($v0)
    sw $t2 65096($v0)
    sw $t2 65100($v0)
    sw $t8 65104($v0)
    sw $t0 65108($v0)
    sw $t7 65112($v0)
    sw $t5 65116($v0)
    sw $t7 65120($v0)
    sw $t4 65124($v0)
    sw $t7 65128($v0)
    sw $t8 65132($v0)
    sw $t1 65136($v0)
    sw $t7 65140($v0)
    sw $t5 65144($v0)
    sw $t0 65148($v0)
    sw $t8 63888($v0)
    sw $t0 63892($v0)
    sw $t4 63896($v0)
    sw $t8 63900($v0)
    sw $t5 63904($v0)
    sw $t2 63908($v0)
    sw $t5 63912($v0)
    sw $t6 63916($v0)
    sw $t1 63920($v0)
    sw $t7 63924($v0)
    sw $t2 63928($v0)
    sw $t2 63932($v0)
    sw $t6 63936($v0)
    sw $t3 63940($v0)
    sw $t8 63944($v0)
    sw $t0 63948($v0)
    sw $t5 63952($v0)
    sw $t7 63956($v0)
    sw $t4 63960($v0)
    sw $t6 63964($v0)
    sw $t3 63968($v0)
    sw $t1 63972($v0)
    sw $t4 63976($v0)
    sw $t8 63980($v0)
    sw $t5 63984($v0)
    sw $t5 63988($v0)
    sw $t0 63992($v0)
    sw $t2 63996($v0)
    sw $t6 64400($v0)
    sw $t4 64404($v0)
    sw $t0 64408($v0)
    sw $t2 64412($v0)
    sw $t0 64416($v0)
    sw $t0 64420($v0)
    sw $t5 64424($v0)
    sw $t2 64428($v0)
    sw $t7 64432($v0)
    sw $t1 64436($v0)
    sw $t6 64440($v0)
    sw $t8 64444($v0)
    sw $t0 64448($v0)
    sw $t0 64452($v0)
    sw $t8 64456($v0)
    sw $t1 64460($v0)
    sw $t6 64464($v0)
    sw $t1 64468($v0)
    sw $t4 64472($v0)
    sw $t3 64476($v0)
    sw $t8 64480($v0)
    sw $t8 64484($v0)
    sw $t8 64488($v0)
    sw $t1 64492($v0)
    sw $t1 64496($v0)
    sw $t6 64500($v0)
    sw $t6 64504($v0)
    sw $t4 64508($v0)
    sw $t2 64912($v0)
    sw $t1 64916($v0)
    sw $t2 64920($v0)
    sw $t2 64924($v0)
    sw $t2 64928($v0)
    sw $t8 64932($v0)
    sw $t6 64936($v0)
    sw $t7 64940($v0)
    sw $t4 64944($v0)
    sw $t2 64948($v0)
    sw $t3 64952($v0)
    sw $t1 64956($v0)
    sw $t7 64960($v0)
    sw $t6 64964($v0)
    sw $t3 64968($v0)
    sw $t7 64972($v0)
    sw $t5 64976($v0)
    sw $t2 64980($v0)
    sw $t7 64984($v0)
    sw $t3 64988($v0)
    sw $t7 64992($v0)
    sw $t3 64996($v0)
    sw $t2 65000($v0)
    sw $t8 65004($v0)
    sw $t4 65008($v0)
    sw $t5 65012($v0)
    sw $t1 65016($v0)
    sw $t2 65020($v0)
    sw $t7 65424($v0)
    sw $t5 65428($v0)
    sw $t8 65432($v0)
    sw $t7 65436($v0)
    sw $t1 65440($v0)
    sw $t8 65444($v0)
    sw $t3 65448($v0)
    sw $t4 65452($v0)
    sw $t4 65456($v0)
    sw $t1 65460($v0)
    sw $t4 65464($v0)
    sw $t7 65468($v0)
    sw $t8 65472($v0)
    sw $t8 65476($v0)
    sw $t0 65480($v0)
    sw $t7 65484($v0)
    sw $t4 65488($v0)
    sw $t6 65492($v0)
    sw $t0 65496($v0)
    sw $t5 65500($v0)
    sw $t5 65504($v0)
    sw $t5 65508($v0)
    sw $t3 65512($v0)
    sw $t1 65516($v0)
    sw $t1 65520($v0)
    sw $t5 65524($v0)
    sw $t7 65528($v0)
    sw $t1 65532($v0)
    jr $ra # return