
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

    move $t0 $a0 # backup (Δx, Δy)
    move $t1 $a1

    move $a0 $s0 # backup previous position to a3
    move $a1 $s1
    jal flatten
    move $a3 $v0

    move $a0 $t0 # restore (Δx, Δy)
    move $a1 $t1

    add $s0 $s0 $a0 # update coordinates
    add $s1 $s1 $a1

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

# draw player v0 with (Δx, Δy) in (a0, a1) and previous position in a2
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