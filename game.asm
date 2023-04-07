# s0 player x in bytes
# s1 player y in bytes
# s2 gravity x
# s3 gravity y
# s4 orientation (positive or negative)
# s5 flag: door_unlocked double_jump landed
# s6 jump distance remaining
# s7 time

# .eqv 1 pixel === 4 bytes
    .eqv BASE_ADDRESS   0x10008000  # ($gp)
    .eqv REFRESH_RATE   40          # in miliseconds
    .eqv SIZE           512         # screen width & height in bytes
    .eqv WIDTH_SHIFT    7           # 4 << WIDTH_SHIFT == SIZE
    .eqv PLAYER_SIZE    64          # in bytes
    .eqv PLAYER_END     60           # PLAYER_SIZE - 4 bytes
    .eqv PLAYER_INIT    32          # initial position
    .eqv JUMP_HEIGHT    96          # in bytes
    .eqv STAGE_COUNT    20           # size of platforms_end
    .eqv DOLLS_FRAME    22           # number of frames for doll animation
    .eqv ALICE_FRAME    6          # number of frames for alice animation
.data
    # space padding to support 128x128 resolution
    pad: .space 36000
    # inclusive bounding boxes (x1, y1, x2, y2), each bbox is 16 bytes
    platforms: .word
        0   96  124 108   208 400 300 412   0   496 124 508   400 496 508 508 # stage 0
        0   0   172 12    16  176 28  236                                     # stage 0-1
        16  32  28  76    0   432 12  492   224 416 236 444
        208 112 220 316
        224 448 236 508   304 288 316 412
    # address to end of platforms per stage
    platforms_end:  .word 64 96 144 160 192
    doll:           .word 48 448 92 492 # bbox
    doll_address:   .word 0 # address on screen
    draw_doll_01: .word draw_doll_01_00 draw_doll_01_01
        draw_doll_01_02 draw_doll_01_03 draw_doll_01_04 draw_doll_01_05
        draw_doll_01_06 draw_doll_01_07 draw_doll_01_08 draw_doll_01_09
        draw_doll_01_10 draw_doll_01_11 draw_doll_01_12 draw_doll_01_13
        draw_doll_01_14 draw_doll_01_15 draw_doll_01_16 draw_doll_01_17
        draw_doll_01_18 draw_doll_01_19 draw_doll_01_20 draw_doll_01_21
    draw_doll_02: .word draw_doll_02_00 draw_doll_02_01
        draw_doll_02_02 draw_doll_02_03 draw_doll_02_04 draw_doll_02_05
        draw_doll_02_06 draw_doll_02_07 draw_doll_02_08 draw_doll_02_09
        draw_doll_02_10 draw_doll_02_11 draw_doll_02_12 draw_doll_02_13
        draw_doll_02_14 draw_doll_02_15 draw_doll_02_16 draw_doll_02_17
        draw_doll_02_18 draw_doll_02_19 draw_doll_02_20 draw_doll_02_21
    draw_doll_03: .word draw_doll_03_00 draw_doll_03_01
        draw_doll_03_02 draw_doll_03_03 draw_doll_03_04 draw_doll_03_05
        draw_doll_03_06 draw_doll_03_07 draw_doll_03_08 draw_doll_03_09
        draw_doll_03_10 draw_doll_03_11 draw_doll_03_12 draw_doll_03_13
        draw_doll_03_14 draw_doll_03_15 draw_doll_03_16 draw_doll_03_17
        draw_doll_03_18 draw_doll_03_19 draw_doll_03_20 draw_doll_03_21
    # doll per stage (2d array go brrr)
    dolls: draw_doll_03 draw_doll_01 draw_doll_02 draw_doll_03 draw_doll_03
    door:           .word 464 400 508 492 # bbox
    door_address:   .word 0 # address on screen
    alice: .word draw_alice_00 draw_alice_01 draw_alice_02
        draw_alice_03 draw_alice_04 draw_alice_05
    stage:          .word 0 # stage counter * 4
    # stage gravity (Δx, Δy) for each stage
    stage_gravity:  .half 0 4 0 -4 -4 0 4 0 4 0

# .macro
    .macro flatten(%x, %y, %out) # flatten 2d coordinates to 1d
        sll %out %y WIDTH_SHIFT # add y
        add %out %out %x # add x
        addi %out %out BASE_ADDRESS # add base
    .end_macro

    .macro save(%bbox, %addr) # save address on screen
        la $t0 %bbox # load bbox
        lw $t1 4($t0) # load y
        lw $t0 0($t0) # load x
        flatten($t0, $t1, $t2)
        sw $t2 %addr # save to memory
    .end_macro

    .macro movement(%dx, %dy) # set a0 a1 and jump to player_move
        li $a2 %dx
        li $a3 %dy
        jr $ra
    .end_macro

    # check collision bbox with with bbox t0 t1 t2 t3 return at v0
    .macro collision(%bbox)
        # get platform box (t4, t5, t6, t7)
        lw $t4 0(%bbox)
        lw $t5 4(%bbox)
        lw $t6 8(%bbox)
        lw $t7 12(%bbox)

        sle $v0 $t0 $t6  # ax1 <= bx2
        slt $v1 $t4 $t2  # bx1 < ax2
        and $v0 $v0 $v1
        sle $v1 $t1 $t7  # ay1 <= by2
        and $v0 $v0 $v1
        slt $v1 $t5 $t3  # by1 < ay2
        and $v0 $v0 $v1
    .end_macro
.text
    save(doll, doll_address)
    save(door, door_address)
init:
    # if all stage completed
    lw $t0 stage
    bge $t0 STAGE_COUNT terminate
    # new gravity
    lh $s2 stage_gravity($t0) # gravity x
    addi $t0 $t0 2
    lh $s3 stage_gravity($t0) # gravity y

    li $t0 BASE_ADDRESS
    li $t1 0x10018000
    clear_screen_loop:
        sw $0 0($t0)
        addi $t0 $t0 4
        ble $t0 $t1 clear_screen_loop

    li $s0 PLAYER_INIT # player x
    li $s1 PLAYER_INIT # player y
    li $s4 1 # face east
    li $s5 2 # door locked, not landed, can double jump
    li $s6 0 # jump distance remaining
    # get current position to v0
    flatten($s0, $s1, $v0)
    li $a0 0
    li $a1 0
    jal draw_alice
    jal draw_stage
.globl main
main:
    li $a0 0
    li $a1 0
    li $a2 0
    li $a3 0
    jal keypress
    jal check_move
    jal gravity
    jal check_move
    jal player_move

    # draw current doll frame
    andi $t4 $s5 4 # check door_unlocked
    bnez $t4 refresh # doll not on screen
    andi $t4 $s7 1 # every 2 frames
    bnez $t4 refresh # skip
    jal draw_doll

    refresh:
    addi $s7 $s7 1 # increment time
    li $a0 REFRESH_RATE # sleep
    li $v0 32
    syscall
    j main
terminate: # terminate the program gracefully
    li $v0 10
    syscall

keypress: # check keypress, return dx dy as a0 a1
    li $t1 0xffff0000 # check keypress
    lw $t0 0($t1)
    beqz $t0 keypress_end # handle keypress
    lw $t0 4($t1)
    beq $t0 0x20 keypress_spc
    # the rest are movements
    beq $t0 0x77 keypress_w
    beq $t0 0x73 keypress_s

    # a or d pressed
    bnez $s2 keypress_end # can't move top/bottom
    beq $t0 0x61 keypress_a
    beq $t0 0x64 keypress_d

    keypress_spc:
        andi $t0 $s5 3 # take double jump, landed
        beqz $t0 keypress_end # can't jump
        li $s6 JUMP_HEIGHT
        andi $s5 $s5 0xfffc # reset last 2 bits

        andi $t0 $t0 0x1 # take last bit
        sll $t0 $t0 1 # shift left
        or $s5 $s5 $t0 # double jump iff not landed
        jr $ra
    keypress_w:
    bnez $s3 keypress_end # can't move up
    movement(0,-4)
    keypress_s:
    bnez $s3 keypress_end # can't move up
    movement(0,4)
    keypress_a:
    movement(-4,0)
    keypress_d:
    movement(4,0)
    keypress_end:
    jr $ra
gravity:
    move $a2 $s2 # update player position
    move $a3 $s3
    beq $s6 0 gravity_end
    # jumping
    neg $a2 $a2 # reverse gravity
    neg $a3 $a3
    abs $t0 $s2 # get absolute value of jump distance
    sub $s6 $s6 $t0 # update jump distance, assume s2 == 0 or s3 == 0
    abs $t0 $s3
    sub $s6 $s6 $t0
    gravity_end:
    jr $ra
check_move: # possibly a0 += a2 and a1 += a3 but ensure no collision
    # get new coordinates
    add $t0 $s0 $a0
    add $t1 $s1 $a1
    add $t0 $t0 $a2
    add $t1 $t1 $a3

    li $v0 1
    # check on screen and get bbox t0 t1 t2 t3
    bgez $t0 player_bbox_1
    bltz $s2 init # fell off screen
    j collision_end
    player_bbox_1:
        bgez $t1 player_bbox_2
        bltz $s3 init # fell off screen
        j collision_end
    player_bbox_2:
        add $t2 $t0 PLAYER_SIZE
        ble $t2 SIZE player_bbox_3
        bgtz $s2 init # fell off screen
        j collision_end
    player_bbox_3:
        add $t3 $t1 PLAYER_SIZE
        ble $t3 SIZE player_bbox_end
        bgtz $s3 init # fell off screen
        j collision_end
    player_bbox_end:

    # collision with platforms
    la $t9 platforms # t9 = address to platforms
    # get end of platforms to t8
    lw $t8 stage
    lw $t8 platforms_end($t8)
    add $t8 $t8 $t9
    collision_loop:
        sub $t8 $t8 16 # decrement platform index
        blt $t8 $t9 collision_end # no more platforms
        collision($t8)
        beq $v0 0 collision_loop # no collision
    collision_end:
        beqz $v0 no_collision
        # has collision
        andi $s5 $s5 0xfffe # set not landed
        # reset jump distance if move towards top and bonk heaad
        add $t0 $a2 $s2
        add $t1 $a3 $s3
        bnez $t0 player_bonk_end
        bnez $t1 player_bonk_end
        li $s6 0 # reset jump distance
        player_bonk_end:
        # consider landed if Δs == gravity
        bne $a2 $s2 has_collision
        bne $a3 $s3 has_collision
        ori $s5 $s5 0x3 # landed (and can double jump)
    has_collision:
        jr $ra
    no_collision:
        add $a0 $a0 $a2
        add $a1 $a1 $a3
        jr $ra
player_move: # move towards (a0, a1)
    addi $sp $sp -4 # push ra to stack
    sw $ra 0($sp)

    flatten($s0, $s1, $a3)  # save previous position to a3

    # update orientation
    move $t0 $s4 # backup orientation to t8
    movn $s4 $a0 $s3 # if gravity is vertical, set to Δx
    movn $s4 $a1 $s2 # if gravity is horizontal, set to Δy
    movz $s4 $t0 $s4 # restore orientation

    or $t0 $a0 $a1
    beqz $t0 player_move_end # no movement

    # get new coordinates
    add $t0 $s0 $a0
    add $t1 $s1 $a1

    andi $t4 $s5 4 # check door_unlocked
    bnez $t4 player_move_door # door unlocked
        # check collision with collectibles
        la $t8 doll
        collision($t8)
        sll $v0 $v0 2
        or $s5 $s5 $v0 # update collected
        beq $v0 0 player_move_update # not collected
            # collected
            lw $v0 doll_address
            jal clear_doll
            lw $v0 door_address
            jal draw_door
            lw $t4 stage
            # apply stage specific gimmicks
            la $ra player_move_update
            beq $t4 4 stage_1
            beq $t4 8 stage_2
            beq $t4 12 stage_3
            j player_move_update
    player_move_door: # check collision with door
        la $t8 door
        collision($t8)
        bnez $v0 next_stage
    player_move_update:
        andi $s5 $s5 0xfffe # not landed
        move $s0 $t0 # update player position
        move $s1 $t1
    player_move_end:
    flatten($s0, $s1, $v0)
    jal draw_alice # draw player at new position
    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4
    jr $ra # return

next_stage: # prepare for next stage, then goto init
    lw $t0 stage
    addi $t0 $t0 4
    sw $t0 stage
    j init

stage_1: # stage 1 gimmick
    li $s2 0 # reset gravity
    li $s3 4
    li $s6 0 # reset jump distance
    jr $ra
stage_2: # stage 2 gimmick
    flatten($s0, $s1, $v1)
    jal clear_alice
    li $s0 400
    li $s1 296
    li $s6 0
    j main # return
stage_3: # stage 3 gimmick
    # push ra t0 t1 to stack
    addi $sp $sp -12
    sw $ra 0($sp)
    sw $t0 4($sp)
    sw $t1 8($sp)

    lw $t2 stage
    addi $t2 $t2 4
    sw $t2 stage
    jal draw_stage

    lw $ra 0($sp)
    lw $t0 4($sp)
    lw $t1 8($sp)
    addi $sp $sp 12
    jr $ra

draw_stage: # use t\d
    lw $t9 stage
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
    sw $t0 12288($v0)
    sw $t3 12292($v0)
    sw $t8 12296($v0)
    sw $t5 12300($v0)
    sw $t7 12304($v0)
    sw $t7 12308($v0)
    sw $t7 12312($v0)
    sw $t0 12316($v0)
    sw $t2 12320($v0)
    sw $t8 12324($v0)
    sw $t4 12328($v0)
    sw $t2 12332($v0)
    sw $t4 12336($v0)
    sw $t4 12340($v0)
    sw $t6 12344($v0)
    sw $t3 12348($v0)
    sw $t1 12352($v0)
    sw $t0 12356($v0)
    sw $t7 12360($v0)
    sw $t8 12364($v0)
    sw $t3 12368($v0)
    sw $t4 12372($v0)
    sw $t4 12376($v0)
    sw $t5 12380($v0)
    sw $t3 12384($v0)
    sw $t6 12388($v0)
    sw $t1 12392($v0)
    sw $t5 12396($v0)
    sw $t1 12400($v0)
    sw $t1 12404($v0)
    sw $t3 12408($v0)
    sw $t2 12412($v0)
    sw $t0 12800($v0)
    sw $t5 12804($v0)
    sw $t1 12808($v0)
    sw $t5 12812($v0)
    sw $t8 12816($v0)
    sw $t8 12820($v0)
    sw $t5 12824($v0)
    sw $t1 12828($v0)
    sw $t6 12832($v0)
    sw $t5 12836($v0)
    sw $t4 12840($v0)
    sw $t0 12844($v0)
    sw $t5 12848($v0)
    sw $t7 12852($v0)
    sw $t8 12856($v0)
    sw $t4 12860($v0)
    sw $t5 12864($v0)
    sw $t7 12868($v0)
    sw $t4 12872($v0)
    sw $t3 12876($v0)
    sw $t2 12880($v0)
    sw $t4 12884($v0)
    sw $t7 12888($v0)
    sw $t2 12892($v0)
    sw $t0 12896($v0)
    sw $t1 12900($v0)
    sw $t3 12904($v0)
    sw $t0 12908($v0)
    sw $t2 12912($v0)
    sw $t4 12916($v0)
    sw $t7 12920($v0)
    sw $t8 12924($v0)
    sw $t7 13312($v0)
    sw $t6 13316($v0)
    sw $t7 13320($v0)
    sw $t6 13324($v0)
    sw $t0 13328($v0)
    sw $t6 13332($v0)
    sw $t1 13336($v0)
    sw $t3 13340($v0)
    sw $t2 13344($v0)
    sw $t5 13348($v0)
    sw $t2 13352($v0)
    sw $t4 13356($v0)
    sw $t6 13360($v0)
    sw $t1 13364($v0)
    sw $t6 13368($v0)
    sw $t8 13372($v0)
    sw $t0 13376($v0)
    sw $t7 13380($v0)
    sw $t2 13384($v0)
    sw $t3 13388($v0)
    sw $t7 13392($v0)
    sw $t2 13396($v0)
    sw $t8 13400($v0)
    sw $t3 13404($v0)
    sw $t5 13408($v0)
    sw $t8 13412($v0)
    sw $t3 13416($v0)
    sw $t8 13420($v0)
    sw $t7 13424($v0)
    sw $t3 13428($v0)
    sw $t2 13432($v0)
    sw $t5 13436($v0)
    sw $t7 13824($v0)
    sw $t4 13828($v0)
    sw $t2 13832($v0)
    sw $t2 13836($v0)
    sw $t6 13840($v0)
    sw $t1 13844($v0)
    sw $t2 13848($v0)
    sw $t1 13852($v0)
    sw $t2 13856($v0)
    sw $t7 13860($v0)
    sw $t6 13864($v0)
    sw $t2 13868($v0)
    sw $t5 13872($v0)
    sw $t8 13876($v0)
    sw $t3 13880($v0)
    sw $t6 13884($v0)
    sw $t5 13888($v0)
    sw $t2 13892($v0)
    sw $t1 13896($v0)
    sw $t6 13900($v0)
    sw $t6 13904($v0)
    sw $t2 13908($v0)
    sw $t2 13912($v0)
    sw $t3 13916($v0)
    sw $t1 13920($v0)
    sw $t2 13924($v0)
    sw $t3 13928($v0)
    sw $t8 13932($v0)
    sw $t4 13936($v0)
    sw $t2 13940($v0)
    sw $t6 13944($v0)
    sw $t1 13948($v0)
    sw $t2 51408($v0)
    sw $t5 51412($v0)
    sw $t3 51416($v0)
    sw $t5 51420($v0)
    sw $t6 51424($v0)
    sw $t0 51428($v0)
    sw $t1 51432($v0)
    sw $t4 51436($v0)
    sw $t0 51440($v0)
    sw $t1 51444($v0)
    sw $t6 51448($v0)
    sw $t5 51452($v0)
    sw $t6 51456($v0)
    sw $t6 51460($v0)
    sw $t8 51464($v0)
    sw $t3 51468($v0)
    sw $t2 51472($v0)
    sw $t0 51476($v0)
    sw $t1 51480($v0)
    sw $t2 51484($v0)
    sw $t2 51488($v0)
    sw $t2 51492($v0)
    sw $t5 51496($v0)
    sw $t6 51500($v0)
    sw $t7 51920($v0)
    sw $t3 51924($v0)
    sw $t0 51928($v0)
    sw $t8 51932($v0)
    sw $t7 51936($v0)
    sw $t6 51940($v0)
    sw $t0 51944($v0)
    sw $t8 51948($v0)
    sw $t0 51952($v0)
    sw $t0 51956($v0)
    sw $t7 51960($v0)
    sw $t7 51964($v0)
    sw $t7 51968($v0)
    sw $t1 51972($v0)
    sw $t8 51976($v0)
    sw $t2 51980($v0)
    sw $t0 51984($v0)
    sw $t0 51988($v0)
    sw $t4 51992($v0)
    sw $t5 51996($v0)
    sw $t1 52000($v0)
    sw $t8 52004($v0)
    sw $t0 52008($v0)
    sw $t1 52012($v0)
    sw $t0 52432($v0)
    sw $t3 52436($v0)
    sw $t3 52440($v0)
    sw $t2 52444($v0)
    sw $t5 52448($v0)
    sw $t4 52452($v0)
    sw $t4 52456($v0)
    sw $t2 52460($v0)
    sw $t2 52464($v0)
    sw $t2 52468($v0)
    sw $t7 52472($v0)
    sw $t2 52476($v0)
    sw $t0 52480($v0)
    sw $t3 52484($v0)
    sw $t5 52488($v0)
    sw $t5 52492($v0)
    sw $t2 52496($v0)
    sw $t5 52500($v0)
    sw $t7 52504($v0)
    sw $t8 52508($v0)
    sw $t1 52512($v0)
    sw $t7 52516($v0)
    sw $t0 52520($v0)
    sw $t0 52524($v0)
    sw $t0 52944($v0)
    sw $t7 52948($v0)
    sw $t4 52952($v0)
    sw $t4 52956($v0)
    sw $t2 52960($v0)
    sw $t2 52964($v0)
    sw $t0 52968($v0)
    sw $t7 52972($v0)
    sw $t6 52976($v0)
    sw $t4 52980($v0)
    sw $t2 52984($v0)
    sw $t7 52988($v0)
    sw $t4 52992($v0)
    sw $t3 52996($v0)
    sw $t5 53000($v0)
    sw $t2 53004($v0)
    sw $t2 53008($v0)
    sw $t3 53012($v0)
    sw $t6 53016($v0)
    sw $t8 53020($v0)
    sw $t0 53024($v0)
    sw $t5 53028($v0)
    sw $t3 53032($v0)
    sw $t0 53036($v0)
    sw $t5 63488($v0)
    sw $t3 63492($v0)
    sw $t4 63496($v0)
    sw $t1 63500($v0)
    sw $t5 63504($v0)
    sw $t6 63508($v0)
    sw $t6 63512($v0)
    sw $t3 63516($v0)
    sw $t2 63520($v0)
    sw $t2 63524($v0)
    sw $t7 63528($v0)
    sw $t1 63532($v0)
    sw $t8 63536($v0)
    sw $t8 63540($v0)
    sw $t7 63544($v0)
    sw $t3 63548($v0)
    sw $t6 63552($v0)
    sw $t0 63556($v0)
    sw $t2 63560($v0)
    sw $t8 63564($v0)
    sw $t3 63568($v0)
    sw $t1 63572($v0)
    sw $t6 63576($v0)
    sw $t7 63580($v0)
    sw $t8 63584($v0)
    sw $t4 63588($v0)
    sw $t8 63592($v0)
    sw $t7 63596($v0)
    sw $t3 63600($v0)
    sw $t0 63604($v0)
    sw $t8 63608($v0)
    sw $t6 63612($v0)
    sw $t1 64000($v0)
    sw $t8 64004($v0)
    sw $t2 64008($v0)
    sw $t4 64012($v0)
    sw $t5 64016($v0)
    sw $t3 64020($v0)
    sw $t4 64024($v0)
    sw $t5 64028($v0)
    sw $t4 64032($v0)
    sw $t1 64036($v0)
    sw $t0 64040($v0)
    sw $t2 64044($v0)
    sw $t1 64048($v0)
    sw $t2 64052($v0)
    sw $t5 64056($v0)
    sw $t0 64060($v0)
    sw $t6 64064($v0)
    sw $t6 64068($v0)
    sw $t6 64072($v0)
    sw $t8 64076($v0)
    sw $t4 64080($v0)
    sw $t0 64084($v0)
    sw $t2 64088($v0)
    sw $t4 64092($v0)
    sw $t4 64096($v0)
    sw $t4 64100($v0)
    sw $t2 64104($v0)
    sw $t6 64108($v0)
    sw $t0 64112($v0)
    sw $t3 64116($v0)
    sw $t4 64120($v0)
    sw $t3 64124($v0)
    sw $t1 64512($v0)
    sw $t2 64516($v0)
    sw $t6 64520($v0)
    sw $t3 64524($v0)
    sw $t3 64528($v0)
    sw $t0 64532($v0)
    sw $t8 64536($v0)
    sw $t8 64540($v0)
    sw $t0 64544($v0)
    sw $t7 64548($v0)
    sw $t2 64552($v0)
    sw $t2 64556($v0)
    sw $t0 64560($v0)
    sw $t0 64564($v0)
    sw $t2 64568($v0)
    sw $t4 64572($v0)
    sw $t2 64576($v0)
    sw $t3 64580($v0)
    sw $t7 64584($v0)
    sw $t2 64588($v0)
    sw $t6 64592($v0)
    sw $t2 64596($v0)
    sw $t2 64600($v0)
    sw $t2 64604($v0)
    sw $t0 64608($v0)
    sw $t5 64612($v0)
    sw $t2 64616($v0)
    sw $t6 64620($v0)
    sw $t1 64624($v0)
    sw $t5 64628($v0)
    sw $t0 64632($v0)
    sw $t0 64636($v0)
    sw $t7 65024($v0)
    sw $t3 65028($v0)
    sw $t1 65032($v0)
    sw $t6 65036($v0)
    sw $t2 65040($v0)
    sw $t8 65044($v0)
    sw $t5 65048($v0)
    sw $t2 65052($v0)
    sw $t0 65056($v0)
    sw $t0 65060($v0)
    sw $t5 65064($v0)
    sw $t5 65068($v0)
    sw $t7 65072($v0)
    sw $t0 65076($v0)
    sw $t8 65080($v0)
    sw $t3 65084($v0)
    sw $t3 65088($v0)
    sw $t7 65092($v0)
    sw $t2 65096($v0)
    sw $t0 65100($v0)
    sw $t1 65104($v0)
    sw $t7 65108($v0)
    sw $t7 65112($v0)
    sw $t3 65116($v0)
    sw $t6 65120($v0)
    sw $t4 65124($v0)
    sw $t8 65128($v0)
    sw $t0 65132($v0)
    sw $t5 65136($v0)
    sw $t8 65140($v0)
    sw $t5 65144($v0)
    sw $t6 65148($v0)
    sw $t4 63888($v0)
    sw $t2 63892($v0)
    sw $t4 63896($v0)
    sw $t7 63900($v0)
    sw $t4 63904($v0)
    sw $t8 63908($v0)
    sw $t2 63912($v0)
    sw $t7 63916($v0)
    sw $t2 63920($v0)
    sw $t2 63924($v0)
    sw $t7 63928($v0)
    sw $t3 63932($v0)
    sw $t7 63936($v0)
    sw $t8 63940($v0)
    sw $t8 63944($v0)
    sw $t0 63948($v0)
    sw $t6 63952($v0)
    sw $t1 63956($v0)
    sw $t6 63960($v0)
    sw $t2 63964($v0)
    sw $t5 63968($v0)
    sw $t5 63972($v0)
    sw $t7 63976($v0)
    sw $t6 63980($v0)
    sw $t1 63984($v0)
    sw $t0 63988($v0)
    sw $t4 63992($v0)
    sw $t1 63996($v0)
    sw $t7 64400($v0)
    sw $t8 64404($v0)
    sw $t6 64408($v0)
    sw $t3 64412($v0)
    sw $t1 64416($v0)
    sw $t8 64420($v0)
    sw $t0 64424($v0)
    sw $t6 64428($v0)
    sw $t5 64432($v0)
    sw $t3 64436($v0)
    sw $t0 64440($v0)
    sw $t1 64444($v0)
    sw $t4 64448($v0)
    sw $t1 64452($v0)
    sw $t7 64456($v0)
    sw $t7 64460($v0)
    sw $t8 64464($v0)
    sw $t4 64468($v0)
    sw $t6 64472($v0)
    sw $t0 64476($v0)
    sw $t2 64480($v0)
    sw $t7 64484($v0)
    sw $t0 64488($v0)
    sw $t7 64492($v0)
    sw $t2 64496($v0)
    sw $t2 64500($v0)
    sw $t4 64504($v0)
    sw $t6 64508($v0)
    sw $t2 64912($v0)
    sw $t3 64916($v0)
    sw $t7 64920($v0)
    sw $t4 64924($v0)
    sw $t8 64928($v0)
    sw $t1 64932($v0)
    sw $t8 64936($v0)
    sw $t6 64940($v0)
    sw $t4 64944($v0)
    sw $t7 64948($v0)
    sw $t7 64952($v0)
    sw $t0 64956($v0)
    sw $t5 64960($v0)
    sw $t6 64964($v0)
    sw $t5 64968($v0)
    sw $t1 64972($v0)
    sw $t5 64976($v0)
    sw $t5 64980($v0)
    sw $t8 64984($v0)
    sw $t1 64988($v0)
    sw $t4 64992($v0)
    sw $t8 64996($v0)
    sw $t4 65000($v0)
    sw $t2 65004($v0)
    sw $t3 65008($v0)
    sw $t1 65012($v0)
    sw $t5 65016($v0)
    sw $t7 65020($v0)
    sw $t1 65424($v0)
    sw $t4 65428($v0)
    sw $t3 65432($v0)
    sw $t4 65436($v0)
    sw $t5 65440($v0)
    sw $t1 65444($v0)
    sw $t6 65448($v0)
    sw $t4 65452($v0)
    sw $t4 65456($v0)
    sw $t7 65460($v0)
    sw $t1 65464($v0)
    sw $t5 65468($v0)
    sw $t1 65472($v0)
    sw $t7 65476($v0)
    sw $t5 65480($v0)
    sw $t8 65484($v0)
    sw $t6 65488($v0)
    sw $t1 65492($v0)
    sw $t4 65496($v0)
    sw $t0 65500($v0)
    sw $t5 65504($v0)
    sw $t0 65508($v0)
    sw $t4 65512($v0)
    sw $t1 65516($v0)
    sw $t2 65520($v0)
    sw $t6 65524($v0)
    sw $t8 65528($v0)
    sw $t0 65532($v0)
    beq $t9 0 draw_stage_end # end of stage 0
    sw $t0 0($v0)
    sw $t5 4($v0)
    sw $t6 8($v0)
    sw $t2 12($v0)
    sw $t8 16($v0)
    sw $t4 20($v0)
    sw $t0 24($v0)
    sw $t3 28($v0)
    sw $t8 32($v0)
    sw $t6 36($v0)
    sw $t4 40($v0)
    sw $t8 44($v0)
    sw $t0 48($v0)
    sw $t0 52($v0)
    sw $t0 56($v0)
    sw $t2 60($v0)
    sw $t0 64($v0)
    sw $t8 68($v0)
    sw $t0 72($v0)
    sw $t4 76($v0)
    sw $t1 80($v0)
    sw $t8 84($v0)
    sw $t7 88($v0)
    sw $t7 92($v0)
    sw $t1 96($v0)
    sw $t5 100($v0)
    sw $t6 104($v0)
    sw $t5 108($v0)
    sw $t4 112($v0)
    sw $t1 116($v0)
    sw $t1 120($v0)
    sw $t5 124($v0)
    sw $t6 128($v0)
    sw $t5 132($v0)
    sw $t1 136($v0)
    sw $t8 140($v0)
    sw $t8 144($v0)
    sw $t1 148($v0)
    sw $t5 152($v0)
    sw $t6 156($v0)
    sw $t6 160($v0)
    sw $t6 164($v0)
    sw $t5 168($v0)
    sw $t4 172($v0)
    sw $t1 512($v0)
    sw $t7 516($v0)
    sw $t0 520($v0)
    sw $t7 524($v0)
    sw $t7 528($v0)
    sw $t7 532($v0)
    sw $t5 536($v0)
    sw $t2 540($v0)
    sw $t8 544($v0)
    sw $t3 548($v0)
    sw $t3 552($v0)
    sw $t3 556($v0)
    sw $t2 560($v0)
    sw $t7 564($v0)
    sw $t5 568($v0)
    sw $t5 572($v0)
    sw $t1 576($v0)
    sw $t5 580($v0)
    sw $t3 584($v0)
    sw $t4 588($v0)
    sw $t3 592($v0)
    sw $t1 596($v0)
    sw $t2 600($v0)
    sw $t0 604($v0)
    sw $t2 608($v0)
    sw $t8 612($v0)
    sw $t6 616($v0)
    sw $t1 620($v0)
    sw $t2 624($v0)
    sw $t5 628($v0)
    sw $t8 632($v0)
    sw $t2 636($v0)
    sw $t3 640($v0)
    sw $t5 644($v0)
    sw $t1 648($v0)
    sw $t5 652($v0)
    sw $t0 656($v0)
    sw $t5 660($v0)
    sw $t7 664($v0)
    sw $t2 668($v0)
    sw $t6 672($v0)
    sw $t3 676($v0)
    sw $t0 680($v0)
    sw $t0 684($v0)
    sw $t5 1024($v0)
    sw $t1 1028($v0)
    sw $t6 1032($v0)
    sw $t5 1036($v0)
    sw $t3 1040($v0)
    sw $t6 1044($v0)
    sw $t0 1048($v0)
    sw $t5 1052($v0)
    sw $t3 1056($v0)
    sw $t3 1060($v0)
    sw $t6 1064($v0)
    sw $t2 1068($v0)
    sw $t0 1072($v0)
    sw $t7 1076($v0)
    sw $t3 1080($v0)
    sw $t8 1084($v0)
    sw $t1 1088($v0)
    sw $t5 1092($v0)
    sw $t3 1096($v0)
    sw $t1 1100($v0)
    sw $t8 1104($v0)
    sw $t5 1108($v0)
    sw $t7 1112($v0)
    sw $t8 1116($v0)
    sw $t8 1120($v0)
    sw $t3 1124($v0)
    sw $t3 1128($v0)
    sw $t3 1132($v0)
    sw $t8 1136($v0)
    sw $t7 1140($v0)
    sw $t1 1144($v0)
    sw $t7 1148($v0)
    sw $t2 1152($v0)
    sw $t6 1156($v0)
    sw $t7 1160($v0)
    sw $t6 1164($v0)
    sw $t7 1168($v0)
    sw $t0 1172($v0)
    sw $t3 1176($v0)
    sw $t1 1180($v0)
    sw $t6 1184($v0)
    sw $t8 1188($v0)
    sw $t3 1192($v0)
    sw $t0 1196($v0)
    sw $t2 1536($v0)
    sw $t2 1540($v0)
    sw $t1 1544($v0)
    sw $t4 1548($v0)
    sw $t4 1552($v0)
    sw $t2 1556($v0)
    sw $t6 1560($v0)
    sw $t0 1564($v0)
    sw $t4 1568($v0)
    sw $t3 1572($v0)
    sw $t7 1576($v0)
    sw $t4 1580($v0)
    sw $t3 1584($v0)
    sw $t1 1588($v0)
    sw $t5 1592($v0)
    sw $t3 1596($v0)
    sw $t8 1600($v0)
    sw $t8 1604($v0)
    sw $t0 1608($v0)
    sw $t5 1612($v0)
    sw $t8 1616($v0)
    sw $t7 1620($v0)
    sw $t3 1624($v0)
    sw $t6 1628($v0)
    sw $t6 1632($v0)
    sw $t8 1636($v0)
    sw $t4 1640($v0)
    sw $t7 1644($v0)
    sw $t6 1648($v0)
    sw $t7 1652($v0)
    sw $t2 1656($v0)
    sw $t6 1660($v0)
    sw $t5 1664($v0)
    sw $t7 1668($v0)
    sw $t6 1672($v0)
    sw $t8 1676($v0)
    sw $t6 1680($v0)
    sw $t5 1684($v0)
    sw $t1 1688($v0)
    sw $t1 1692($v0)
    sw $t1 1696($v0)
    sw $t2 1700($v0)
    sw $t7 1704($v0)
    sw $t4 1708($v0)
    sw $t1 22544($v0)
    sw $t2 22548($v0)
    sw $t7 22552($v0)
    sw $t2 22556($v0)
    sw $t0 23056($v0)
    sw $t5 23060($v0)
    sw $t3 23064($v0)
    sw $t1 23068($v0)
    sw $t3 23568($v0)
    sw $t3 23572($v0)
    sw $t2 23576($v0)
    sw $t4 23580($v0)
    sw $t7 24080($v0)
    sw $t5 24084($v0)
    sw $t4 24088($v0)
    sw $t5 24092($v0)
    sw $t7 24592($v0)
    sw $t2 24596($v0)
    sw $t3 24600($v0)
    sw $t3 24604($v0)
    sw $t3 25104($v0)
    sw $t2 25108($v0)
    sw $t5 25112($v0)
    sw $t5 25116($v0)
    sw $t4 25616($v0)
    sw $t4 25620($v0)
    sw $t3 25624($v0)
    sw $t5 25628($v0)
    sw $t5 26128($v0)
    sw $t2 26132($v0)
    sw $t2 26136($v0)
    sw $t1 26140($v0)
    sw $t1 26640($v0)
    sw $t7 26644($v0)
    sw $t3 26648($v0)
    sw $t0 26652($v0)
    sw $t1 27152($v0)
    sw $t3 27156($v0)
    sw $t5 27160($v0)
    sw $t4 27164($v0)
    sw $t3 27664($v0)
    sw $t1 27668($v0)
    sw $t2 27672($v0)
    sw $t5 27676($v0)
    sw $t8 28176($v0)
    sw $t6 28180($v0)
    sw $t1 28184($v0)
    sw $t7 28188($v0)
    sw $t1 28688($v0)
    sw $t8 28692($v0)
    sw $t3 28696($v0)
    sw $t7 28700($v0)
    sw $t4 29200($v0)
    sw $t3 29204($v0)
    sw $t3 29208($v0)
    sw $t3 29212($v0)
    sw $t7 29712($v0)
    sw $t6 29716($v0)
    sw $t7 29720($v0)
    sw $t7 29724($v0)
    sw $t4 30224($v0)
    sw $t8 30228($v0)
    sw $t3 30232($v0)
    sw $t6 30236($v0)
    beq $t9 4 draw_stage_end # end of stage 1
    sw $t6 4112($v0)
    sw $t2 4116($v0)
    sw $t3 4120($v0)
    sw $t1 4124($v0)
    sw $t7 4624($v0)
    sw $t8 4628($v0)
    sw $t4 4632($v0)
    sw $t8 4636($v0)
    sw $t3 5136($v0)
    sw $t3 5140($v0)
    sw $t0 5144($v0)
    sw $t4 5148($v0)
    sw $t4 5648($v0)
    sw $t1 5652($v0)
    sw $t7 5656($v0)
    sw $t7 5660($v0)
    sw $t2 6160($v0)
    sw $t7 6164($v0)
    sw $t8 6168($v0)
    sw $t8 6172($v0)
    sw $t2 6672($v0)
    sw $t4 6676($v0)
    sw $t4 6680($v0)
    sw $t5 6684($v0)
    sw $t1 7184($v0)
    sw $t2 7188($v0)
    sw $t4 7192($v0)
    sw $t3 7196($v0)
    sw $t8 7696($v0)
    sw $t4 7700($v0)
    sw $t0 7704($v0)
    sw $t1 7708($v0)
    sw $t5 8208($v0)
    sw $t7 8212($v0)
    sw $t6 8216($v0)
    sw $t8 8220($v0)
    sw $t0 8720($v0)
    sw $t0 8724($v0)
    sw $t7 8728($v0)
    sw $t0 8732($v0)
    sw $t0 9232($v0)
    sw $t1 9236($v0)
    sw $t2 9240($v0)
    sw $t0 9244($v0)
    sw $t1 9744($v0)
    sw $t0 9748($v0)
    sw $t3 9752($v0)
    sw $t3 9756($v0)
    sw $t0 55296($v0)
    sw $t0 55300($v0)
    sw $t3 55304($v0)
    sw $t7 55308($v0)
    sw $t8 55808($v0)
    sw $t0 55812($v0)
    sw $t0 55816($v0)
    sw $t1 55820($v0)
    sw $t6 56320($v0)
    sw $t6 56324($v0)
    sw $t1 56328($v0)
    sw $t8 56332($v0)
    sw $t0 56832($v0)
    sw $t3 56836($v0)
    sw $t4 56840($v0)
    sw $t7 56844($v0)
    sw $t1 57344($v0)
    sw $t5 57348($v0)
    sw $t3 57352($v0)
    sw $t2 57356($v0)
    sw $t8 57856($v0)
    sw $t2 57860($v0)
    sw $t1 57864($v0)
    sw $t0 57868($v0)
    sw $t8 58368($v0)
    sw $t3 58372($v0)
    sw $t6 58376($v0)
    sw $t2 58380($v0)
    sw $t7 58880($v0)
    sw $t3 58884($v0)
    sw $t6 58888($v0)
    sw $t3 58892($v0)
    sw $t0 59392($v0)
    sw $t8 59396($v0)
    sw $t6 59400($v0)
    sw $t3 59404($v0)
    sw $t8 59904($v0)
    sw $t3 59908($v0)
    sw $t0 59912($v0)
    sw $t3 59916($v0)
    sw $t7 60416($v0)
    sw $t3 60420($v0)
    sw $t6 60424($v0)
    sw $t8 60428($v0)
    sw $t6 60928($v0)
    sw $t6 60932($v0)
    sw $t8 60936($v0)
    sw $t7 60940($v0)
    sw $t4 61440($v0)
    sw $t2 61444($v0)
    sw $t8 61448($v0)
    sw $t1 61452($v0)
    sw $t2 61952($v0)
    sw $t3 61956($v0)
    sw $t6 61960($v0)
    sw $t6 61964($v0)
    sw $t8 62464($v0)
    sw $t3 62468($v0)
    sw $t7 62472($v0)
    sw $t3 62476($v0)
    sw $t3 62976($v0)
    sw $t2 62980($v0)
    sw $t4 62984($v0)
    sw $t3 62988($v0)
    sw $t0 53472($v0)
    sw $t7 53476($v0)
    sw $t2 53480($v0)
    sw $t3 53484($v0)
    sw $t5 53984($v0)
    sw $t6 53988($v0)
    sw $t6 53992($v0)
    sw $t2 53996($v0)
    sw $t5 54496($v0)
    sw $t5 54500($v0)
    sw $t1 54504($v0)
    sw $t6 54508($v0)
    sw $t1 55008($v0)
    sw $t8 55012($v0)
    sw $t0 55016($v0)
    sw $t0 55020($v0)
    sw $t1 55520($v0)
    sw $t1 55524($v0)
    sw $t4 55528($v0)
    sw $t8 55532($v0)
    sw $t7 56032($v0)
    sw $t1 56036($v0)
    sw $t5 56040($v0)
    sw $t2 56044($v0)
    sw $t8 56544($v0)
    sw $t3 56548($v0)
    sw $t5 56552($v0)
    sw $t6 56556($v0)
    sw $t2 57056($v0)
    sw $t6 57060($v0)
    sw $t1 57064($v0)
    sw $t3 57068($v0)
    beq $t9 8 draw_stage_end # end of stage 2
    sw $t7 14544($v0)
    sw $t0 14548($v0)
    sw $t5 14552($v0)
    sw $t0 14556($v0)
    sw $t4 15056($v0)
    sw $t3 15060($v0)
    sw $t8 15064($v0)
    sw $t5 15068($v0)
    sw $t7 15568($v0)
    sw $t0 15572($v0)
    sw $t6 15576($v0)
    sw $t8 15580($v0)
    sw $t8 16080($v0)
    sw $t7 16084($v0)
    sw $t4 16088($v0)
    sw $t6 16092($v0)
    sw $t8 16592($v0)
    sw $t5 16596($v0)
    sw $t5 16600($v0)
    sw $t7 16604($v0)
    sw $t7 17104($v0)
    sw $t8 17108($v0)
    sw $t4 17112($v0)
    sw $t2 17116($v0)
    sw $t7 17616($v0)
    sw $t7 17620($v0)
    sw $t8 17624($v0)
    sw $t2 17628($v0)
    sw $t1 18128($v0)
    sw $t2 18132($v0)
    sw $t5 18136($v0)
    sw $t1 18140($v0)
    sw $t7 18640($v0)
    sw $t1 18644($v0)
    sw $t5 18648($v0)
    sw $t0 18652($v0)
    sw $t8 19152($v0)
    sw $t2 19156($v0)
    sw $t0 19160($v0)
    sw $t4 19164($v0)
    sw $t4 19664($v0)
    sw $t4 19668($v0)
    sw $t7 19672($v0)
    sw $t4 19676($v0)
    sw $t3 20176($v0)
    sw $t5 20180($v0)
    sw $t2 20184($v0)
    sw $t5 20188($v0)
    sw $t7 20688($v0)
    sw $t5 20692($v0)
    sw $t4 20696($v0)
    sw $t4 20700($v0)
    sw $t5 21200($v0)
    sw $t1 21204($v0)
    sw $t0 21208($v0)
    sw $t7 21212($v0)
    sw $t2 21712($v0)
    sw $t6 21716($v0)
    sw $t5 21720($v0)
    sw $t0 21724($v0)
    sw $t4 22224($v0)
    sw $t5 22228($v0)
    sw $t1 22232($v0)
    sw $t1 22236($v0)
    sw $t2 22736($v0)
    sw $t7 22740($v0)
    sw $t3 22744($v0)
    sw $t0 22748($v0)
    sw $t5 23248($v0)
    sw $t5 23252($v0)
    sw $t3 23256($v0)
    sw $t7 23260($v0)
    sw $t3 23760($v0)
    sw $t7 23764($v0)
    sw $t0 23768($v0)
    sw $t4 23772($v0)
    sw $t3 24272($v0)
    sw $t8 24276($v0)
    sw $t5 24280($v0)
    sw $t1 24284($v0)
    sw $t6 24784($v0)
    sw $t6 24788($v0)
    sw $t2 24792($v0)
    sw $t6 24796($v0)
    sw $t3 25296($v0)
    sw $t4 25300($v0)
    sw $t8 25304($v0)
    sw $t3 25308($v0)
    sw $t0 25808($v0)
    sw $t7 25812($v0)
    sw $t6 25816($v0)
    sw $t4 25820($v0)
    sw $t0 26320($v0)
    sw $t6 26324($v0)
    sw $t3 26328($v0)
    sw $t5 26332($v0)
    sw $t2 26832($v0)
    sw $t0 26836($v0)
    sw $t2 26840($v0)
    sw $t2 26844($v0)
    sw $t7 27344($v0)
    sw $t8 27348($v0)
    sw $t6 27352($v0)
    sw $t6 27356($v0)
    sw $t2 27856($v0)
    sw $t1 27860($v0)
    sw $t3 27864($v0)
    sw $t2 27868($v0)
    sw $t6 28368($v0)
    sw $t1 28372($v0)
    sw $t5 28376($v0)
    sw $t2 28380($v0)
    sw $t5 28880($v0)
    sw $t2 28884($v0)
    sw $t7 28888($v0)
    sw $t7 28892($v0)
    sw $t6 29392($v0)
    sw $t3 29396($v0)
    sw $t6 29400($v0)
    sw $t5 29404($v0)
    sw $t0 29904($v0)
    sw $t2 29908($v0)
    sw $t6 29912($v0)
    sw $t7 29916($v0)
    sw $t7 30416($v0)
    sw $t3 30420($v0)
    sw $t8 30424($v0)
    sw $t1 30428($v0)
    sw $t5 30928($v0)
    sw $t5 30932($v0)
    sw $t0 30936($v0)
    sw $t1 30940($v0)
    sw $t2 31440($v0)
    sw $t3 31444($v0)
    sw $t0 31448($v0)
    sw $t1 31452($v0)
    sw $t5 31952($v0)
    sw $t0 31956($v0)
    sw $t8 31960($v0)
    sw $t7 31964($v0)
    sw $t4 32464($v0)
    sw $t7 32468($v0)
    sw $t7 32472($v0)
    sw $t3 32476($v0)
    sw $t5 32976($v0)
    sw $t6 32980($v0)
    sw $t4 32984($v0)
    sw $t4 32988($v0)
    sw $t7 33488($v0)
    sw $t6 33492($v0)
    sw $t0 33496($v0)
    sw $t4 33500($v0)
    sw $t6 34000($v0)
    sw $t8 34004($v0)
    sw $t6 34008($v0)
    sw $t8 34012($v0)
    sw $t7 34512($v0)
    sw $t0 34516($v0)
    sw $t2 34520($v0)
    sw $t6 34524($v0)
    sw $t0 35024($v0)
    sw $t6 35028($v0)
    sw $t4 35032($v0)
    sw $t7 35036($v0)
    sw $t0 35536($v0)
    sw $t1 35540($v0)
    sw $t6 35544($v0)
    sw $t7 35548($v0)
    sw $t8 36048($v0)
    sw $t6 36052($v0)
    sw $t5 36056($v0)
    sw $t4 36060($v0)
    sw $t7 36560($v0)
    sw $t2 36564($v0)
    sw $t8 36568($v0)
    sw $t5 36572($v0)
    sw $t0 37072($v0)
    sw $t6 37076($v0)
    sw $t1 37080($v0)
    sw $t7 37084($v0)
    sw $t2 37584($v0)
    sw $t1 37588($v0)
    sw $t7 37592($v0)
    sw $t6 37596($v0)
    sw $t6 38096($v0)
    sw $t8 38100($v0)
    sw $t7 38104($v0)
    sw $t6 38108($v0)
    sw $t0 38608($v0)
    sw $t7 38612($v0)
    sw $t8 38616($v0)
    sw $t7 38620($v0)
    sw $t3 39120($v0)
    sw $t7 39124($v0)
    sw $t2 39128($v0)
    sw $t2 39132($v0)
    sw $t7 39632($v0)
    sw $t7 39636($v0)
    sw $t1 39640($v0)
    sw $t1 39644($v0)
    sw $t6 40144($v0)
    sw $t2 40148($v0)
    sw $t0 40152($v0)
    sw $t4 40156($v0)
    sw $t7 40656($v0)
    sw $t5 40660($v0)
    sw $t0 40664($v0)
    sw $t1 40668($v0)
    beq $t9 12 draw_stage_end # end of stage 3
    sw $t4 57568($v0)
    sw $t0 57572($v0)
    sw $t2 57576($v0)
    sw $t3 57580($v0)
    sw $t5 58080($v0)
    sw $t3 58084($v0)
    sw $t3 58088($v0)
    sw $t1 58092($v0)
    sw $t1 58592($v0)
    sw $t2 58596($v0)
    sw $t2 58600($v0)
    sw $t7 58604($v0)
    sw $t8 59104($v0)
    sw $t1 59108($v0)
    sw $t0 59112($v0)
    sw $t3 59116($v0)
    sw $t6 59616($v0)
    sw $t8 59620($v0)
    sw $t7 59624($v0)
    sw $t0 59628($v0)
    sw $t8 60128($v0)
    sw $t5 60132($v0)
    sw $t3 60136($v0)
    sw $t5 60140($v0)
    sw $t6 60640($v0)
    sw $t8 60644($v0)
    sw $t7 60648($v0)
    sw $t4 60652($v0)
    sw $t2 61152($v0)
    sw $t5 61156($v0)
    sw $t1 61160($v0)
    sw $t4 61164($v0)
    sw $t7 61664($v0)
    sw $t7 61668($v0)
    sw $t2 61672($v0)
    sw $t2 61676($v0)
    sw $t5 62176($v0)
    sw $t7 62180($v0)
    sw $t4 62184($v0)
    sw $t0 62188($v0)
    sw $t2 62688($v0)
    sw $t8 62692($v0)
    sw $t8 62696($v0)
    sw $t6 62700($v0)
    sw $t3 63200($v0)
    sw $t6 63204($v0)
    sw $t5 63208($v0)
    sw $t3 63212($v0)
    sw $t1 63712($v0)
    sw $t1 63716($v0)
    sw $t8 63720($v0)
    sw $t4 63724($v0)
    sw $t6 64224($v0)
    sw $t3 64228($v0)
    sw $t8 64232($v0)
    sw $t3 64236($v0)
    sw $t2 64736($v0)
    sw $t4 64740($v0)
    sw $t7 64744($v0)
    sw $t8 64748($v0)
    sw $t0 65248($v0)
    sw $t3 65252($v0)
    sw $t5 65256($v0)
    sw $t6 65260($v0)
    sw $t8 37168($v0)
    sw $t5 37172($v0)
    sw $t8 37176($v0)
    sw $t6 37180($v0)
    sw $t6 37680($v0)
    sw $t7 37684($v0)
    sw $t8 37688($v0)
    sw $t2 37692($v0)
    sw $t4 38192($v0)
    sw $t8 38196($v0)
    sw $t0 38200($v0)
    sw $t5 38204($v0)
    sw $t2 38704($v0)
    sw $t1 38708($v0)
    sw $t8 38712($v0)
    sw $t7 38716($v0)
    sw $t6 39216($v0)
    sw $t0 39220($v0)
    sw $t2 39224($v0)
    sw $t1 39228($v0)
    sw $t0 39728($v0)
    sw $t2 39732($v0)
    sw $t6 39736($v0)
    sw $t6 39740($v0)
    sw $t6 40240($v0)
    sw $t0 40244($v0)
    sw $t7 40248($v0)
    sw $t4 40252($v0)
    sw $t1 40752($v0)
    sw $t0 40756($v0)
    sw $t7 40760($v0)
    sw $t0 40764($v0)
    sw $t0 41264($v0)
    sw $t5 41268($v0)
    sw $t7 41272($v0)
    sw $t5 41276($v0)
    sw $t5 41776($v0)
    sw $t6 41780($v0)
    sw $t7 41784($v0)
    sw $t5 41788($v0)
    sw $t5 42288($v0)
    sw $t8 42292($v0)
    sw $t4 42296($v0)
    sw $t8 42300($v0)
    sw $t4 42800($v0)
    sw $t1 42804($v0)
    sw $t2 42808($v0)
    sw $t2 42812($v0)
    sw $t8 43312($v0)
    sw $t0 43316($v0)
    sw $t2 43320($v0)
    sw $t1 43324($v0)
    sw $t3 43824($v0)
    sw $t0 43828($v0)
    sw $t8 43832($v0)
    sw $t4 43836($v0)
    sw $t3 44336($v0)
    sw $t8 44340($v0)
    sw $t1 44344($v0)
    sw $t0 44348($v0)
    sw $t7 44848($v0)
    sw $t1 44852($v0)
    sw $t6 44856($v0)
    sw $t3 44860($v0)
    sw $t4 45360($v0)
    sw $t3 45364($v0)
    sw $t2 45368($v0)
    sw $t6 45372($v0)
    sw $t5 45872($v0)
    sw $t6 45876($v0)
    sw $t2 45880($v0)
    sw $t1 45884($v0)
    sw $t3 46384($v0)
    sw $t6 46388($v0)
    sw $t0 46392($v0)
    sw $t6 46396($v0)
    sw $t5 46896($v0)
    sw $t8 46900($v0)
    sw $t8 46904($v0)
    sw $t1 46908($v0)
    sw $t1 47408($v0)
    sw $t0 47412($v0)
    sw $t4 47416($v0)
    sw $t4 47420($v0)
    sw $t0 47920($v0)
    sw $t7 47924($v0)
    sw $t6 47928($v0)
    sw $t6 47932($v0)
    sw $t8 48432($v0)
    sw $t0 48436($v0)
    sw $t6 48440($v0)
    sw $t0 48444($v0)
    sw $t7 48944($v0)
    sw $t6 48948($v0)
    sw $t3 48952($v0)
    sw $t3 48956($v0)
    sw $t5 49456($v0)
    sw $t6 49460($v0)
    sw $t0 49464($v0)
    sw $t1 49468($v0)
    sw $t6 49968($v0)
    sw $t3 49972($v0)
    sw $t6 49976($v0)
    sw $t1 49980($v0)
    sw $t7 50480($v0)
    sw $t1 50484($v0)
    sw $t7 50488($v0)
    sw $t0 50492($v0)
    sw $t1 50992($v0)
    sw $t8 50996($v0)
    sw $t2 51000($v0)
    sw $t3 51004($v0)
    sw $t3 51504($v0)
    sw $t5 51508($v0)
    sw $t1 51512($v0)
    sw $t2 51516($v0)
    sw $t6 52016($v0)
    sw $t4 52020($v0)
    sw $t6 52024($v0)
    sw $t3 52028($v0)
    sw $t1 52528($v0)
    sw $t5 52532($v0)
    sw $t2 52536($v0)
    sw $t7 52540($v0)
    sw $t1 53040($v0)
    sw $t0 53044($v0)
    sw $t0 53048($v0)
    sw $t3 53052($v0)

    draw_stage_end:
    jr $ra # return

draw_door: # start at v0, use t4
    li $t4 0x7d4400
    sw $t4 0($v0)
    sw $t4 44($v0)
    sw $t4 4608($v0)
    sw $t4 8748($v0)
    sw $t4 11264($v0)
    sw $t4 11776($v0)
    sw $t4 11820($v0)
    li $t4 0x754000
    sw $t4 4($v0)
    li $t4 0x713d00
    sw $t4 8($v0)
    sw $t4 36($v0)
    li $t4 0x6e3a00
    sw $t4 12($v0)
    li $t4 0x6e3800
    sw $t4 16($v0)
    li $t4 0x733f00
    sw $t4 20($v0)
    li $t4 0x733e00
    sw $t4 24($v0)
    li $t4 0x6f3b00
    sw $t4 28($v0)
    li $t4 0x6d3800
    sw $t4 32($v0)
    li $t4 0x764100
    sw $t4 40($v0)
    li $t4 0x844800
    sw $t4 512($v0)
    li $t4 0xa6690d
    sw $t4 516($v0)
    sw $t4 8196($v0)
    li $t4 0xa0640d
    sw $t4 520($v0)
    sw $t4 8200($v0)
    li $t4 0xa86a0d
    sw $t4 524($v0)
    sw $t4 536($v0)
    sw $t4 5128($v0)
    sw $t4 7720($v0)
    sw $t4 8204($v0)
    sw $t4 8216($v0)
    li $t4 0xac6c0e
    sw $t4 528($v0)
    sw $t4 540($v0)
    sw $t4 5136($v0)
    sw $t4 5148($v0)
    sw $t4 8208($v0)
    sw $t4 8220($v0)
    li $t4 0xa1660d
    sw $t4 532($v0)
    sw $t4 1032($v0)
    sw $t4 5156($v0)
    sw $t4 8212($v0)
    sw $t4 8712($v0)
    li $t4 0xa2660d
    sw $t4 544($v0)
    sw $t4 3624($v0)
    sw $t4 8224($v0)
    sw $t4 11304($v0)
    li $t4 0xa3670d
    sw $t4 548($v0)
    sw $t4 8228($v0)
    li $t4 0xab6c0e
    sw $t4 552($v0)
    sw $t4 8232($v0)
    li $t4 0x834700
    sw $t4 556($v0)
    sw $t4 3584($v0)
    li $t4 0x864900
    sw $t4 1024($v0)
    sw $t4 3072($v0)
    li $t4 0xae6d0f
    sw $t4 1028($v0)
    sw $t4 8708($v0)
    li $t4 0x955e0c
    sw $t4 1036($v0)
    sw $t4 1064($v0)
    sw $t4 5144($v0)
    sw $t4 5160($v0)
    sw $t4 8716($v0)
    sw $t4 8744($v0)
    li $t4 0xa96b0e
    sw $t4 1040($v0)
    sw $t4 1052($v0)
    sw $t4 8720($v0)
    sw $t4 8732($v0)
    li $t4 0xac6d0e
    sw $t4 1044($v0)
    sw $t4 2084($v0)
    sw $t4 2596($v0)
    sw $t4 3600($v0)
    sw $t4 3612($v0)
    sw $t4 6180($v0)
    sw $t4 8724($v0)
    sw $t4 9764($v0)
    sw $t4 10276($v0)
    sw $t4 11280($v0)
    sw $t4 11292($v0)
    li $t4 0x935d0c
    sw $t4 1048($v0)
    sw $t4 8728($v0)
    li $t4 0xab6b0e
    sw $t4 1056($v0)
    sw $t4 8736($v0)
    li $t4 0x9c620d
    sw $t4 1060($v0)
    sw $t4 8740($v0)
    li $t4 0x854700
    sw $t4 1068($v0)
    li $t4 0x854900
    sw $t4 1536($v0)
    sw $t4 2048($v0)
    sw $t4 2560($v0)
    li $t4 0xca7f10
    sw $t4 1540($v0)
    sw $t4 1556($v0)
    sw $t4 7188($v0)
    sw $t4 9220($v0)
    sw $t4 9236($v0)
    li $t4 0xb7740e
    sw $t4 1544($v0)
    sw $t4 5640($v0)
    sw $t4 9224($v0)
    li $t4 0x9e640c
    sw $t4 1548($v0)
    sw $t4 5644($v0)
    sw $t4 9228($v0)
    li $t4 0xb1700e
    sw $t4 1552($v0)
    sw $t4 1564($v0)
    sw $t4 5648($v0)
    sw $t4 5660($v0)
    sw $t4 9232($v0)
    sw $t4 9244($v0)
    li $t4 0x9c630c
    sw $t4 1560($v0)
    sw $t4 5656($v0)
    sw $t4 6668($v0)
    sw $t4 9240($v0)
    li $t4 0xc77d10
    sw $t4 1568($v0)
    sw $t4 3092($v0)
    sw $t4 9248($v0)
    sw $t4 10772($v0)
    li $t4 0xaf6f0e
    sw $t4 1572($v0)
    sw $t4 9252($v0)
    li $t4 0x99610c
    sw $t4 1576($v0)
    sw $t4 2088($v0)
    sw $t4 2600($v0)
    sw $t4 5672($v0)
    sw $t4 6184($v0)
    sw $t4 6696($v0)
    sw $t4 9256($v0)
    sw $t4 9768($v0)
    sw $t4 10280($v0)
    li $t4 0x844700
    sw $t4 1580($v0)
    sw $t4 2092($v0)
    sw $t4 2604($v0)
    li $t4 0xc67c10
    sw $t4 2052($v0)
    sw $t4 2564($v0)
    sw $t4 3588($v0)
    sw $t4 7716($v0)
    sw $t4 9732($v0)
    sw $t4 10244($v0)
    sw $t4 11268($v0)
    li $t4 0xb4720e
    sw $t4 2056($v0)
    sw $t4 2568($v0)
    sw $t4 6152($v0)
    sw $t4 9736($v0)
    sw $t4 10248($v0)
    li $t4 0x9d630c
    sw $t4 2060($v0)
    sw $t4 2572($v0)
    sw $t4 3084($v0)
    sw $t4 6156($v0)
    sw $t4 7192($v0)
    sw $t4 9740($v0)
    sw $t4 10252($v0)
    sw $t4 10764($v0)
    li $t4 0xb06f0e
    sw $t4 2064($v0)
    sw $t4 2076($v0)
    sw $t4 2576($v0)
    sw $t4 2588($v0)
    sw $t4 3088($v0)
    sw $t4 3100($v0)
    sw $t4 6160($v0)
    sw $t4 6172($v0)
    sw $t4 6672($v0)
    sw $t4 6684($v0)
    sw $t4 9744($v0)
    sw $t4 9756($v0)
    sw $t4 10256($v0)
    sw $t4 10268($v0)
    sw $t4 10768($v0)
    sw $t4 10780($v0)
    li $t4 0xc57c10
    sw $t4 2068($v0)
    sw $t4 2580($v0)
    sw $t4 3620($v0)
    sw $t4 6164($v0)
    sw $t4 9748($v0)
    sw $t4 10260($v0)
    sw $t4 11300($v0)
    li $t4 0x9b620c
    sw $t4 2072($v0)
    sw $t4 2584($v0)
    sw $t4 3096($v0)
    sw $t4 6168($v0)
    sw $t4 9752($v0)
    sw $t4 10264($v0)
    sw $t4 10776($v0)
    li $t4 0xc37a10
    sw $t4 2080($v0)
    sw $t4 2592($v0)
    sw $t4 6176($v0)
    sw $t4 9760($v0)
    sw $t4 10272($v0)
    li $t4 0xc87d10
    sw $t4 3076($v0)
    sw $t4 7200($v0)
    sw $t4 10756($v0)
    li $t4 0xb6730e
    sw $t4 3080($v0)
    sw $t4 10760($v0)
    li $t4 0xc57b10
    sw $t4 3104($v0)
    sw $t4 6148($v0)
    sw $t4 10784($v0)
    li $t4 0xad6e0e
    sw $t4 3108($v0)
    sw $t4 10788($v0)
    li $t4 0x98600c
    sw $t4 3112($v0)
    sw $t4 7208($v0)
    sw $t4 10792($v0)
    li $t4 0x854800
    sw $t4 3116($v0)
    li $t4 0xcb8010
    sw $t4 3592($v0)
    sw $t4 11272($v0)
    li $t4 0xae6e0e
    sw $t4 3596($v0)
    sw $t4 3608($v0)
    sw $t4 4136($v0)
    sw $t4 11276($v0)
    sw $t4 11288($v0)
    sw $t4 11816($v0)
    li $t4 0xcf8211
    sw $t4 3604($v0)
    sw $t4 11284($v0)
    li $t4 0xcc8010
    sw $t4 3616($v0)
    sw $t4 7700($v0)
    sw $t4 11296($v0)
    li $t4 0x824600
    sw $t4 3628($v0)
    li $t4 0x7d4300
    sw $t4 4096($v0)
    sw $t4 5164($v0)
    sw $t4 5676($v0)
    sw $t4 6144($v0)
    sw $t4 6188($v0)
    sw $t4 6700($v0)
    sw $t4 8704($v0)
    sw $t4 9260($v0)
    sw $t4 9772($v0)
    sw $t4 10284($v0)
    sw $t4 10796($v0)
    li $t4 0xc07910
    sw $t4 4100($v0)
    sw $t4 11780($v0)
    li $t4 0xc1780d
    sw $t4 4104($v0)
    sw $t4 11784($v0)
    li $t4 0xba7208
    sw $t4 4108($v0)
    sw $t4 11788($v0)
    li $t4 0xba750f
    sw $t4 4112($v0)
    sw $t4 11792($v0)
    li $t4 0xc37b10
    sw $t4 4116($v0)
    sw $t4 11796($v0)
    li $t4 0xc47b0f
    sw $t4 4120($v0)
    sw $t4 11800($v0)
    li $t4 0xb87107
    sw $t4 4124($v0)
    sw $t4 11804($v0)
    li $t4 0xbc760f
    sw $t4 4128($v0)
    sw $t4 11808($v0)
    li $t4 0xc0790f
    sw $t4 4132($v0)
    sw $t4 11812($v0)
    li $t4 0x7c4400
    sw $t4 4140($v0)
    sw $t4 7212($v0)
    sw $t4 7724($v0)
    li $t4 0xa0650d
    sw $t4 4612($v0)
    sw $t4 4620($v0)
    sw $t4 4632($v0)
    li $t4 0x9e630d
    sw $t4 4616($v0)
    li $t4 0xa96a0e
    sw $t4 4624($v0)
    sw $t4 4636($v0)
    li $t4 0x9f640d
    sw $t4 4628($v0)
    sw $t4 4640($v0)
    li $t4 0x9e640d
    sw $t4 4644($v0)
    li $t4 0xa6680d
    sw $t4 4648($v0)
    li $t4 0x7e4500
    sw $t4 4652($v0)
    sw $t4 5120($v0)
    sw $t4 5632($v0)
    sw $t4 9216($v0)
    sw $t4 9728($v0)
    sw $t4 10240($v0)
    sw $t4 10752($v0)
    li $t4 0xb9740f
    sw $t4 5124($v0)
    li $t4 0x965f0c
    sw $t4 5132($v0)
    li $t4 0xb7730f
    sw $t4 5140($v0)
    li $t4 0xb5710f
    sw $t4 5152($v0)
    li $t4 0xc97e10
    sw $t4 5636($v0)
    sw $t4 5652($v0)
    li $t4 0xc77c10
    sw $t4 5664($v0)
    li $t4 0xae6f0e
    sw $t4 5668($v0)
    li $t4 0x824800
    sw $t4 6656($v0)
    sw $t4 8192($v0)
    li $t4 0xe0922a
    sw $t4 6660($v0)
    li $t4 0xcb862a
    sw $t4 6664($v0)
    li $t4 0xc47b10
    sw $t4 6676($v0)
    li $t4 0x9a610c
    sw $t4 6680($v0)
    li $t4 0xc27910
    sw $t4 6688($v0)
    li $t4 0xaa6c0e
    sw $t4 6692($v0)
    li $t4 0x935600
    sw $t4 7168($v0)
    sw $t4 7680($v0)
    li $t4 0xfeb721
    sw $t4 7172($v0)
    li $t4 0xdf9628
    sw $t4 7176($v0)
    li $t4 0x9b610d
    sw $t4 7180($v0)
    li $t4 0xaf6e0e
    sw $t4 7184($v0)
    sw $t4 7196($v0)
    li $t4 0xb2700e
    sw $t4 7204($v0)
    sw $t4 7692($v0)
    li $t4 0xf2a525
    sw $t4 7684($v0)
    li $t4 0xe2942a
    sw $t4 7688($v0)
    li $t4 0xae6d0e
    sw $t4 7696($v0)
    sw $t4 7708($v0)
    li $t4 0xb3710e
    sw $t4 7704($v0)
    li $t4 0xc97f10
    sw $t4 7712($v0)
    li $t4 0x7e4400
    sw $t4 8236($v0)
    li $t4 0x7b4400
    sw $t4 11308($v0)
    jr $ra

draw_alice: # start at v0 with Δx Δy in a0 a1, previous position in a2
    addi $sp $sp -4 # push ra to stack
    sw $ra 0($sp)
    # binary seach go brrr
    beqz $s3 draw_c # draw columns first
        bltz $s3 draw_rn # draw rows towards north
            li $t1 SIZE
            move $t2 $v0
            bltz $s4 draw_rsw # draw rows south west
                li $t0 4  # draw rows south east
                j draw_end
            draw_rsw:
                li $t0 -4  # draw rows south west
                addi $t2 $t2 PLAYER_END
                j draw_end
        draw_rn: # draw rows north
            li $t1 -SIZE
            li $t2 PLAYER_END # set t2 to bottom left
            sll $t2 $t2 WIDTH_SHIFT
            add $t2 $t2 $v0
            bltz $s4 draw_rnw # draw rows north west
                li $t0 4  # draw rows north east
                j draw_end
            draw_rnw: # draw rows north west
                li $t0 -4
                addi $t2 $t2 PLAYER_END
                j draw_end
            j draw_end
    draw_c: # draw columns
        bltz $s2 draw_cw # draw columns west
            li $t1 4
            bltz $s4 draw_cen # draw columns east north
                li $t0 SIZE  # draw columns east south
                move $t2 $v0
                j draw_end
            draw_cen: # draw columns east north
                li $t0 -SIZE
                li $t2 PLAYER_END # set t2 to bottom left
                sll $t2 $t2 WIDTH_SHIFT
                add $t2 $t2 $v0
                j draw_end
        draw_cw: # draw columns west
            li $t1 -4
            bltz $s4 draw_cwn # draw columns west north
                li $t0 SIZE  # draw columns west south
                addi $t2 $v0 PLAYER_END # set t2 to top right
                j draw_end
            draw_cwn:
                li $t0 -SIZE
                li $t2 PLAYER_END # set t2 to bottom right
                sll $t2 $t2 WIDTH_SHIFT
                add $t2 $t2 $v0
                addi $t2 $t2 PLAYER_END
                j draw_end
    draw_end:

    move $v0 $t2
    # t0 t1 is Δs
    # t2 is start, v0 is current

    # get frame index in words
    srl $t4 $s7 2
    rem $t4 $t4 ALICE_FRAME
    sll $t4 $t4 2
    la $t5 alice
    add $t5 $t5 $t4
    lw $t5 0($t5) # load frame index

    jalr $t5 # draw frame

    # clean previously drawed
    beqz $a1 clear_row_end # no movement on y axis
    move $t0 $a3
    bgez $a1 clear_row # skip shift
        li $t2 PLAYER_END
        sll $t2 $t2 WIDTH_SHIFT
        add $t0 $t0 $t2 # shift to bottom row
    clear_row:
        sw $0 0($t0) # clear (0, y)
        sw $0 4($t0) # clear (1, y)
        sw $0 8($t0) # clear (2, y)
        sw $0 12($t0) # clear (3, y)
        sw $0 16($t0) # clear (4, y)
        sw $0 20($t0) # clear (5, y)
        sw $0 24($t0) # clear (6, y)
        sw $0 28($t0) # clear (7, y)
        sw $0 32($t0) # clear (8, y)
        sw $0 36($t0) # clear (9, y)
        sw $0 40($t0) # clear (10, y)
        sw $0 44($t0) # clear (11, y)
        sw $0 48($t0) # clear (12, y)
        sw $0 52($t0) # clear (13, y)
        sw $0 56($t0) # clear (14, y)
        sw $0 60($t0) # clear (15, y)
    clear_row_end:
        beqz $a0 clear_end # no movement on x axis
        bgez $a0 clear_column # skip shift
        addi $a3 $a3 PLAYER_END # shift to right column
    clear_column:
        sw $0 0($a3) # clear (x, 0)
        sw $0 512($a3) # clear (x, 1)
        sw $0 1024($a3) # clear (x, 2)
        sw $0 1536($a3) # clear (x, 3)
        sw $0 2048($a3) # clear (x, 4)
        sw $0 2560($a3) # clear (x, 5)
        sw $0 3072($a3) # clear (x, 6)
        sw $0 3584($a3) # clear (x, 7)
        sw $0 4096($a3) # clear (x, 8)
        sw $0 4608($a3) # clear (x, 9)
        sw $0 5120($a3) # clear (x, 10)
        sw $0 5632($a3) # clear (x, 11)
        sw $0 6144($a3) # clear (x, 12)
        sw $0 6656($a3) # clear (x, 13)
        sw $0 7168($a3) # clear (x, 14)
        sw $0 7680($a3) # clear (x, 15)
    clear_end:
    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4
    jr $ra # return
draw_alice_00:
    sw $0 0($v0) # store background (0, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x030302 # load color
    sw $t4 0($v0) # store color (2, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3c231b # load color
    sw $t4 0($v0) # store color (3, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa46249 # load color
    sw $t4 0($v0) # store color (4, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeaa891 # load color
    sw $t4 0($v0) # store color (5, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd0a4af # load color
    sw $t4 0($v0) # store color (6, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc68fa1 # load color
    sw $t4 0($v0) # store color (7, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd198a1 # load color
    sw $t4 0($v0) # store color (8, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc58993 # load color
    sw $t4 0($v0) # store color (9, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc7a3b2 # load color
    sw $t4 0($v0) # store color (10, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7f7778 # load color
    sw $t4 0($v0) # store color (11, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x261911 # load color
    sw $t4 0($v0) # store color (12, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 0)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x120a07 # load color
    sw $t4 0($v0) # store color (1, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6d3f2d # load color
    sw $t4 0($v0) # store color (2, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd68969 # load color
    sw $t4 0($v0) # store color (3, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe7bcb6 # load color
    sw $t4 0($v0) # store color (4, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb96a7d # load color
    sw $t4 0($v0) # store color (5, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaa4e63 # load color
    sw $t4 0($v0) # store color (6, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc98a8f # load color
    sw $t4 0($v0) # store color (7, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe3a49e # load color
    sw $t4 0($v0) # store color (8, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdea09c # load color
    sw $t4 0($v0) # store color (9, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbc7781 # load color
    sw $t4 0($v0) # store color (10, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xce7c8c # load color
    sw $t4 0($v0) # store color (11, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf9084 # load color
    sw $t4 0($v0) # store color (12, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x49352c # load color
    sw $t4 0($v0) # store color (13, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x040201 # load color
    sw $t4 0($v0) # store color (14, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 1)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x030201 # load color
    sw $t4 0($v0) # store color (0, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x854d37 # load color
    sw $t4 0($v0) # store color (1, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc87556 # load color
    sw $t4 0($v0) # store color (2, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdaa59e # load color
    sw $t4 0($v0) # store color (3, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb76476 # load color
    sw $t4 0($v0) # store color (4, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb7626e # load color
    sw $t4 0($v0) # store color (5, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeab990 # load color
    sw $t4 0($v0) # store color (6, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c374 # load color
    sw $t4 0($v0) # store color (7, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5c370 # load color
    sw $t4 0($v0) # store color (8, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c26e # load color
    sw $t4 0($v0) # store color (9, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2bd82 # load color
    sw $t4 0($v0) # store color (10, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe1b7ab # load color
    sw $t4 0($v0) # store color (11, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2a197 # load color
    sw $t4 0($v0) # store color (12, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7a474 # load color
    sw $t4 0($v0) # store color (13, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x614029 # load color
    sw $t4 0($v0) # store color (14, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000001 # load color
    sw $t4 0($v0) # store color (15, 2)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x4c2c20 # load color
    sw $t4 0($v0) # store color (0, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbb7151 # load color
    sw $t4 0($v0) # store color (1, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdca16b # load color
    sw $t4 0($v0) # store color (2, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb8877 # load color
    sw $t4 0($v0) # store color (3, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc17172 # load color
    sw $t4 0($v0) # store color (4, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1c58e # load color
    sw $t4 0($v0) # store color (5, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed97c # load color
    sw $t4 0($v0) # store color (6, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbdb75 # load color
    sw $t4 0($v0) # store color (7, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfce488 # load color
    sw $t4 0($v0) # store color (8, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe389 # load color
    sw $t4 0($v0) # store color (9, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad677 # load color
    sw $t4 0($v0) # store color (10, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe092 # load color
    sw $t4 0($v0) # store color (11, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcdeac # load color
    sw $t4 0($v0) # store color (12, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6ce78 # load color
    sw $t4 0($v0) # store color (13, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcea95e # load color
    sw $t4 0($v0) # store color (14, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0x261a12 # load color
    sw $t4 0($v0) # store color (15, 3)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xa55f46 # load color
    sw $t4 0($v0) # store color (0, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc47b55 # load color
    sw $t4 0($v0) # store color (1, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7c873 # load color
    sw $t4 0($v0) # store color (2, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7cd7b # load color
    sw $t4 0($v0) # store color (3, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeab377 # load color
    sw $t4 0($v0) # store color (4, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcdfa7 # load color
    sw $t4 0($v0) # store color (5, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedc39c # load color
    sw $t4 0($v0) # store color (6, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe0ac6b # load color
    sw $t4 0($v0) # store color (7, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfeebab # load color
    sw $t4 0($v0) # store color (8, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9dbac # load color
    sw $t4 0($v0) # store color (9, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdca063 # load color
    sw $t4 0($v0) # store color (10, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfce0a5 # load color
    sw $t4 0($v0) # store color (11, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7ca8b # load color
    sw $t4 0($v0) # store color (12, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xefb76f # load color
    sw $t4 0($v0) # store color (13, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7d473 # load color
    sw $t4 0($v0) # store color (14, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0x937241 # load color
    sw $t4 0($v0) # store color (15, 4)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbe6f50 # load color
    sw $t4 0($v0) # store color (0, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe09e65 # load color
    sw $t4 0($v0) # store color (1, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad378 # load color
    sw $t4 0($v0) # store color (2, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfacc77 # load color
    sw $t4 0($v0) # store color (3, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2b672 # load color
    sw $t4 0($v0) # store color (4, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe7b36a # load color
    sw $t4 0($v0) # store color (5, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb46643 # load color
    sw $t4 0($v0) # store color (6, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcf955c # load color
    sw $t4 0($v0) # store color (7, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfddb76 # load color
    sw $t4 0($v0) # store color (8, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd69355 # load color
    sw $t4 0($v0) # store color (9, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8d482d # load color
    sw $t4 0($v0) # store color (10, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc38254 # load color
    sw $t4 0($v0) # store color (11, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd178 # load color
    sw $t4 0($v0) # store color (12, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd99b64 # load color
    sw $t4 0($v0) # store color (13, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5c073 # load color
    sw $t4 0($v0) # store color (14, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb39f56 # load color
    sw $t4 0($v0) # store color (15, 5)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbe6f4f # load color
    sw $t4 0($v0) # store color (0, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe7b06a # load color
    sw $t4 0($v0) # store color (1, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeaba6d # load color
    sw $t4 0($v0) # store color (2, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbcd79 # load color
    sw $t4 0($v0) # store color (3, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbc7955 # load color
    sw $t4 0($v0) # store color (4, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x764b3c # load color
    sw $t4 0($v0) # store color (5, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x733b2c # load color
    sw $t4 0($v0) # store color (6, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb78b66 # load color
    sw $t4 0($v0) # store color (7, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xecad75 # load color
    sw $t4 0($v0) # store color (8, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc48374 # load color
    sw $t4 0($v0) # store color (9, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x62585f # load color
    sw $t4 0($v0) # store color (10, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb2705f # load color
    sw $t4 0($v0) # store color (11, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c06c # load color
    sw $t4 0($v0) # store color (12, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb7814d # load color
    sw $t4 0($v0) # store color (13, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd7d54 # load color
    sw $t4 0($v0) # store color (14, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xac9857 # load color
    sw $t4 0($v0) # store color (15, 6)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xcf7d58 # load color
    sw $t4 0($v0) # store color (0, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe09d64 # load color
    sw $t4 0($v0) # store color (1, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd5915d # load color
    sw $t4 0($v0) # store color (2, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcd27a # load color
    sw $t4 0($v0) # store color (3, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb8885c # load color
    sw $t4 0($v0) # store color (4, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa69da1 # load color
    sw $t4 0($v0) # store color (5, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5f7f83 # load color
    sw $t4 0($v0) # store color (6, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xddbdb0 # load color
    sw $t4 0($v0) # store color (7, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbcfbf # load color
    sw $t4 0($v0) # store color (8, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2d7d2 # load color
    sw $t4 0($v0) # store color (9, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x74a7b4 # load color
    sw $t4 0($v0) # store color (10, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb8b70 # load color
    sw $t4 0($v0) # store color (11, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd19251 # load color
    sw $t4 0($v0) # store color (12, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x975f3a # load color
    sw $t4 0($v0) # store color (13, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3e2b1a # load color
    sw $t4 0($v0) # store color (14, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x524c2b # load color
    sw $t4 0($v0) # store color (15, 7)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xcd7a57 # load color
    sw $t4 0($v0) # store color (0, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd9835c # load color
    sw $t4 0($v0) # store color (1, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc37950 # load color
    sw $t4 0($v0) # store color (2, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe8a569 # load color
    sw $t4 0($v0) # store color (3, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd9a16a # load color
    sw $t4 0($v0) # store color (4, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaab3b6 # load color
    sw $t4 0($v0) # store color (5, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3c96a7 # load color
    sw $t4 0($v0) # store color (6, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeee2db # load color
    sw $t4 0($v0) # store color (7, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffebe2 # load color
    sw $t4 0($v0) # store color (8, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1e6df # load color
    sw $t4 0($v0) # store color (9, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbfc1bb # load color
    sw $t4 0($v0) # store color (10, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc7785c # load color
    sw $t4 0($v0) # store color (11, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd67453 # load color
    sw $t4 0($v0) # store color (12, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x562e21 # load color
    sw $t4 0($v0) # store color (13, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x020101 # load color
    sw $t4 0($v0) # store color (14, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x020303 # load color
    sw $t4 0($v0) # store color (15, 8)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x7d4938 # load color
    sw $t4 0($v0) # store color (0, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xce7958 # load color
    sw $t4 0($v0) # store color (1, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6e3c27 # load color
    sw $t4 0($v0) # store color (2, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8e543a # load color
    sw $t4 0($v0) # store color (3, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb7850 # load color
    sw $t4 0($v0) # store color (4, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xce9487 # load color
    sw $t4 0($v0) # store color (5, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe4c2c7 # load color
    sw $t4 0($v0) # store color (6, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd5cf # load color
    sw $t4 0($v0) # store color (7, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed5ce # load color
    sw $t4 0($v0) # store color (8, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6cbc5 # load color
    sw $t4 0($v0) # store color (9, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc78a79 # load color
    sw $t4 0($v0) # store color (10, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcd7451 # load color
    sw $t4 0($v0) # store color (11, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb36343 # load color
    sw $t4 0($v0) # store color (12, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2d1912 # load color
    sw $t4 0($v0) # store color (13, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 9)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x0b0506 # load color
    sw $t4 0($v0) # store color (0, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x683c2f # load color
    sw $t4 0($v0) # store color (1, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2e1913 # load color
    sw $t4 0($v0) # store color (2, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x261409 # load color
    sw $t4 0($v0) # store color (3, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x96573a # load color
    sw $t4 0($v0) # store color (4, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdeb2ad # load color
    sw $t4 0($v0) # store color (5, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7d2d8 # load color
    sw $t4 0($v0) # store color (6, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2a9aa # load color
    sw $t4 0($v0) # store color (7, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc05c68 # load color
    sw $t4 0($v0) # store color (8, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdab3b8 # load color
    sw $t4 0($v0) # store color (9, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd979a # load color
    sw $t4 0($v0) # store color (10, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x914e44 # load color
    sw $t4 0($v0) # store color (11, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1d0b04 # load color
    sw $t4 0($v0) # store color (12, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x060302 # load color
    sw $t4 0($v0) # store color (13, 10)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 10)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 10)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x020508 # load color
    sw $t4 0($v0) # store color (2, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x151e2d # load color
    sw $t4 0($v0) # store color (3, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x302b30 # load color
    sw $t4 0($v0) # store color (4, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x897c89 # load color
    sw $t4 0($v0) # store color (5, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xac93a7 # load color
    sw $t4 0($v0) # store color (6, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbb939f # load color
    sw $t4 0($v0) # store color (7, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc9a1a7 # load color
    sw $t4 0($v0) # store color (8, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd99a0 # load color
    sw $t4 0($v0) # store color (9, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x736a82 # load color
    sw $t4 0($v0) # store color (10, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x25253a # load color
    sw $t4 0($v0) # store color (11, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1e2d49 # load color
    sw $t4 0($v0) # store color (12, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x04060a # load color
    sw $t4 0($v0) # store color (13, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 11)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1d2636 # load color
    sw $t4 0($v0) # store color (2, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2d3d5a # load color
    sw $t4 0($v0) # store color (3, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x284167 # load color
    sw $t4 0($v0) # store color (4, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2e4169 # load color
    sw $t4 0($v0) # store color (5, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3a3f5e # load color
    sw $t4 0($v0) # store color (6, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7d87a7 # load color
    sw $t4 0($v0) # store color (7, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x898ea0 # load color
    sw $t4 0($v0) # store color (8, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x71788b # load color
    sw $t4 0($v0) # store color (9, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x303959 # load color
    sw $t4 0($v0) # store color (10, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2b3553 # load color
    sw $t4 0($v0) # store color (11, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3b5586 # load color
    sw $t4 0($v0) # store color (12, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1f2d46 # load color
    sw $t4 0($v0) # store color (13, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 12)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x07090d # load color
    sw $t4 0($v0) # store color (1, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x35415e # load color
    sw $t4 0($v0) # store color (2, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x384c74 # load color
    sw $t4 0($v0) # store color (3, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x425883 # load color
    sw $t4 0($v0) # store color (4, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x384061 # load color
    sw $t4 0($v0) # store color (5, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3e466e # load color
    sw $t4 0($v0) # store color (6, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb4b4cc # load color
    sw $t4 0($v0) # store color (7, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdfdeeb # load color
    sw $t4 0($v0) # store color (8, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd6d5e6 # load color
    sw $t4 0($v0) # store color (9, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7881a0 # load color
    sw $t4 0($v0) # store color (10, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5d6586 # load color
    sw $t4 0($v0) # store color (11, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x304870 # load color
    sw $t4 0($v0) # store color (12, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x080c13 # load color
    sw $t4 0($v0) # store color (13, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 13)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1b1f2a # load color
    sw $t4 0($v0) # store color (2, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x475373 # load color
    sw $t4 0($v0) # store color (3, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x454c67 # load color
    sw $t4 0($v0) # store color (4, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7e82a0 # load color
    sw $t4 0($v0) # store color (5, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa4adc3 # load color
    sw $t4 0($v0) # store color (6, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x717897 # load color
    sw $t4 0($v0) # store color (7, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7383a0 # load color
    sw $t4 0($v0) # store color (8, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa2a8c1 # load color
    sw $t4 0($v0) # store color (9, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x69677e # load color
    sw $t4 0($v0) # store color (10, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x283754 # load color
    sw $t4 0($v0) # store color (11, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x070b11 # load color
    sw $t4 0($v0) # store color (12, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 14)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (2, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x040506 # load color
    sw $t4 0($v0) # store color (3, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x21222b # load color
    sw $t4 0($v0) # store color (4, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6a7094 # load color
    sw $t4 0($v0) # store color (5, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x71779b # load color
    sw $t4 0($v0) # store color (6, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x383c4f # load color
    sw $t4 0($v0) # store color (7, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x292f41 # load color
    sw $t4 0($v0) # store color (8, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4d5779 # load color
    sw $t4 0($v0) # store color (9, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x353b51 # load color
    sw $t4 0($v0) # store color (10, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (11, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (12, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 15)
    add $v0 $v0 $t0 # shift x
    jr $ra
draw_alice_01:
    sw $0 0($v0) # store background (0, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x020201 # load color
    sw $t4 0($v0) # store color (2, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x382119 # load color
    sw $t4 0($v0) # store color (3, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9e5d46 # load color
    sw $t4 0($v0) # store color (4, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeaa78d # load color
    sw $t4 0($v0) # store color (5, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd2a7b0 # load color
    sw $t4 0($v0) # store color (6, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc590a2 # load color
    sw $t4 0($v0) # store color (7, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd39ba4 # load color
    sw $t4 0($v0) # store color (8, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc58a94 # load color
    sw $t4 0($v0) # store color (9, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc99fae # load color
    sw $t4 0($v0) # store color (10, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8a8588 # load color
    sw $t4 0($v0) # store color (11, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x302016 # load color
    sw $t4 0($v0) # store color (12, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 0)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0f0906 # load color
    sw $t4 0($v0) # store color (1, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x663b2a # load color
    sw $t4 0($v0) # store color (2, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd28564 # load color
    sw $t4 0($v0) # store color (3, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9bcb5 # load color
    sw $t4 0($v0) # store color (4, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbc7184 # load color
    sw $t4 0($v0) # store color (5, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa94960 # load color
    sw $t4 0($v0) # store color (6, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc4848c # load color
    sw $t4 0($v0) # store color (7, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2a39e # load color
    sw $t4 0($v0) # store color (8, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdfa19d # load color
    sw $t4 0($v0) # store color (9, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd7982 # load color
    sw $t4 0($v0) # store color (10, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca7688 # load color
    sw $t4 0($v0) # store color (11, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc9958b # load color
    sw $t4 0($v0) # store color (12, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x563f35 # load color
    sw $t4 0($v0) # store color (13, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x060303 # load color
    sw $t4 0($v0) # store color (14, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 1)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x020101 # load color
    sw $t4 0($v0) # store color (0, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x804b36 # load color
    sw $t4 0($v0) # store color (1, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc67354 # load color
    sw $t4 0($v0) # store color (2, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdca69d # load color
    sw $t4 0($v0) # store color (3, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb86a7b # load color
    sw $t4 0($v0) # store color (4, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb35a6a # load color
    sw $t4 0($v0) # store color (5, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe6b692 # load color
    sw $t4 0($v0) # store color (6, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5c277 # load color
    sw $t4 0($v0) # store color (7, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5c271 # load color
    sw $t4 0($v0) # store color (8, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c26f # load color
    sw $t4 0($v0) # store color (9, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2bd7f # load color
    sw $t4 0($v0) # store color (10, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2b8a9 # load color
    sw $t4 0($v0) # store color (11, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe09d99 # load color
    sw $t4 0($v0) # store color (12, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdda97b # load color
    sw $t4 0($v0) # store color (13, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x734e32 # load color
    sw $t4 0($v0) # store color (14, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x050204 # load color
    sw $t4 0($v0) # store color (15, 2)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x472a1e # load color
    sw $t4 0($v0) # store color (0, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xba6f50 # load color
    sw $t4 0($v0) # store color (1, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xda9e69 # load color
    sw $t4 0($v0) # store color (2, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcc8978 # load color
    sw $t4 0($v0) # store color (3, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbe6b6f # load color
    sw $t4 0($v0) # store color (4, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedbf8e # load color
    sw $t4 0($v0) # store color (5, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed87b # load color
    sw $t4 0($v0) # store color (6, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcdb75 # load color
    sw $t4 0($v0) # store color (7, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfce384 # load color
    sw $t4 0($v0) # store color (8, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe388 # load color
    sw $t4 0($v0) # store color (9, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd777 # load color
    sw $t4 0($v0) # store color (10, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfedd8a # load color
    sw $t4 0($v0) # store color (11, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfee3b2 # load color
    sw $t4 0($v0) # store color (12, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7cd7d # load color
    sw $t4 0($v0) # store color (13, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdfb766 # load color
    sw $t4 0($v0) # store color (14, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0x362719 # load color
    sw $t4 0($v0) # store color (15, 3)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xa25d45 # load color
    sw $t4 0($v0) # store color (0, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc37954 # load color
    sw $t4 0($v0) # store color (1, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7c673 # load color
    sw $t4 0($v0) # store color (2, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7cd7c # load color
    sw $t4 0($v0) # store color (3, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9b177 # load color
    sw $t4 0($v0) # store color (4, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbdda5 # load color
    sw $t4 0($v0) # store color (5, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1cca4 # load color
    sw $t4 0($v0) # store color (6, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe0aa6b # load color
    sw $t4 0($v0) # store color (7, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfee9a8 # load color
    sw $t4 0($v0) # store color (8, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfce2b3 # load color
    sw $t4 0($v0) # store color (9, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdea367 # load color
    sw $t4 0($v0) # store color (10, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbdd9f # load color
    sw $t4 0($v0) # store color (11, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9d195 # load color
    sw $t4 0($v0) # store color (12, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xefb46e # load color
    sw $t4 0($v0) # store color (13, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9d675 # load color
    sw $t4 0($v0) # store color (14, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa68349 # load color
    sw $t4 0($v0) # store color (15, 4)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbe6e50 # load color
    sw $t4 0($v0) # store color (0, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdf9a63 # load color
    sw $t4 0($v0) # store color (1, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad278 # load color
    sw $t4 0($v0) # store color (2, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9ce77 # load color
    sw $t4 0($v0) # store color (3, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3b772 # load color
    sw $t4 0($v0) # store color (4, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedbd6f # load color
    sw $t4 0($v0) # store color (5, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xba6d49 # load color
    sw $t4 0($v0) # store color (6, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb8d58 # load color
    sw $t4 0($v0) # store color (7, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdf79 # load color
    sw $t4 0($v0) # store color (8, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe0a25d # load color
    sw $t4 0($v0) # store color (9, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0x954c2f # load color
    sw $t4 0($v0) # store color (10, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd7d51 # load color
    sw $t4 0($v0) # store color (11, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd17a # load color
    sw $t4 0($v0) # store color (12, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdea267 # load color
    sw $t4 0($v0) # store color (13, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf0b870 # load color
    sw $t4 0($v0) # store color (14, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcab160 # load color
    sw $t4 0($v0) # store color (15, 5)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbd6f4f # load color
    sw $t4 0($v0) # store color (0, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe6ae6a # load color
    sw $t4 0($v0) # store color (1, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebbc6f # load color
    sw $t4 0($v0) # store color (2, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfccf79 # load color
    sw $t4 0($v0) # store color (3, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc58059 # load color
    sw $t4 0($v0) # store color (4, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7c4f3c # load color
    sw $t4 0($v0) # store color (5, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x753929 # load color
    sw $t4 0($v0) # store color (6, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xae825f # load color
    sw $t4 0($v0) # store color (7, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeeb273 # load color
    sw $t4 0($v0) # store color (8, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca8370 # load color
    sw $t4 0($v0) # store color (9, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x665356 # load color
    sw $t4 0($v0) # store color (10, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa36a5e # load color
    sw $t4 0($v0) # store color (11, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6b96b # load color
    sw $t4 0($v0) # store color (12, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc29154 # load color
    sw $t4 0($v0) # store color (13, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbb7550 # load color
    sw $t4 0($v0) # store color (14, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc0a560 # load color
    sw $t4 0($v0) # store color (15, 6)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xcf7c58 # load color
    sw $t4 0($v0) # store color (0, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe19f65 # load color
    sw $t4 0($v0) # store color (1, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd5915d # load color
    sw $t4 0($v0) # store color (2, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdd57a # load color
    sw $t4 0($v0) # store color (3, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb8875a # load color
    sw $t4 0($v0) # store color (4, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa19498 # load color
    sw $t4 0($v0) # store color (5, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x61797d # load color
    sw $t4 0($v0) # store color (6, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd0b5a9 # load color
    sw $t4 0($v0) # store color (7, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfac8b6 # load color
    sw $t4 0($v0) # store color (8, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeddad3 # load color
    sw $t4 0($v0) # store color (9, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6ea5b2 # load color
    sw $t4 0($v0) # store color (10, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc9937f # load color
    sw $t4 0($v0) # store color (11, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd49451 # load color
    sw $t4 0($v0) # store color (12, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa87042 # load color
    sw $t4 0($v0) # store color (13, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x482c1b # load color
    sw $t4 0($v0) # store color (14, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5e5630 # load color
    sw $t4 0($v0) # store color (15, 7)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xd07b58 # load color
    sw $t4 0($v0) # store color (0, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xda855d # load color
    sw $t4 0($v0) # store color (1, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc97d54 # load color
    sw $t4 0($v0) # store color (2, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedaa6c # load color
    sw $t4 0($v0) # store color (3, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdba46a # load color
    sw $t4 0($v0) # store color (4, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb0b4b6 # load color
    sw $t4 0($v0) # store color (5, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3092a4 # load color
    sw $t4 0($v0) # store color (6, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe4ded8 # load color
    sw $t4 0($v0) # store color (7, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffeae2 # load color
    sw $t4 0($v0) # store color (8, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6e8e0 # load color
    sw $t4 0($v0) # store color (9, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb4c4c1 # load color
    sw $t4 0($v0) # store color (10, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc98369 # load color
    sw $t4 0($v0) # store color (11, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd77452 # load color
    sw $t4 0($v0) # store color (12, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6e3c2a # load color
    sw $t4 0($v0) # store color (13, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x070403 # load color
    sw $t4 0($v0) # store color (14, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x040503 # load color
    sw $t4 0($v0) # store color (15, 8)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x864f3c # load color
    sw $t4 0($v0) # store color (0, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd17b5a # load color
    sw $t4 0($v0) # store color (1, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x74402b # load color
    sw $t4 0($v0) # store color (2, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x91563b # load color
    sw $t4 0($v0) # store color (3, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcf7d52 # load color
    sw $t4 0($v0) # store color (4, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb9485 # load color
    sw $t4 0($v0) # store color (5, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd5bec4 # load color
    sw $t4 0($v0) # store color (6, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9d7d2 # load color
    sw $t4 0($v0) # store color (7, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffddd4 # load color
    sw $t4 0($v0) # store color (8, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd3cd # load color
    sw $t4 0($v0) # store color (9, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd19788 # load color
    sw $t4 0($v0) # store color (10, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb7552 # load color
    sw $t4 0($v0) # store color (11, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc86e4c # load color
    sw $t4 0($v0) # store color (12, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x43251b # load color
    sw $t4 0($v0) # store color (13, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 9)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x100809 # load color
    sw $t4 0($v0) # store color (0, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7a4737 # load color
    sw $t4 0($v0) # store color (1, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3c1f18 # load color
    sw $t4 0($v0) # store color (2, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2c170b # load color
    sw $t4 0($v0) # store color (3, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9c5939 # load color
    sw $t4 0($v0) # store color (4, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd9a8a0 # load color
    sw $t4 0($v0) # store color (5, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8d0d7 # load color
    sw $t4 0($v0) # store color (6, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeab8b8 # load color
    sw $t4 0($v0) # store color (7, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc3626d # load color
    sw $t4 0($v0) # store color (8, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdbb0b6 # load color
    sw $t4 0($v0) # store color (9, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbc9899 # load color
    sw $t4 0($v0) # store color (10, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaa5d51 # load color
    sw $t4 0($v0) # store color (11, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x311609 # load color
    sw $t4 0($v0) # store color (12, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0c0604 # load color
    sw $t4 0($v0) # store color (13, 10)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 10)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 10)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000204 # load color
    sw $t4 0($v0) # store color (2, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x101723 # load color
    sw $t4 0($v0) # store color (3, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x362b2b # load color
    sw $t4 0($v0) # store color (4, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x98838b # load color
    sw $t4 0($v0) # store color (5, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbfa5b6 # load color
    sw $t4 0($v0) # store color (6, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc6959d # load color
    sw $t4 0($v0) # store color (7, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd29da2 # load color
    sw $t4 0($v0) # store color (8, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb9ba2 # load color
    sw $t4 0($v0) # store color (9, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8e8296 # load color
    sw $t4 0($v0) # store color (10, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x352d3f # load color
    sw $t4 0($v0) # store color (11, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x15233a # load color
    sw $t4 0($v0) # store color (12, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x03060a # load color
    sw $t4 0($v0) # store color (13, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 11)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1a2230 # load color
    sw $t4 0($v0) # store color (2, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2d3c58 # load color
    sw $t4 0($v0) # store color (3, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x263d60 # load color
    sw $t4 0($v0) # store color (4, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2f436c # load color
    sw $t4 0($v0) # store color (5, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3a405e # load color
    sw $t4 0($v0) # store color (6, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x727c9e # load color
    sw $t4 0($v0) # store color (7, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x82899d # load color
    sw $t4 0($v0) # store color (8, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x707789 # load color
    sw $t4 0($v0) # store color (9, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x323958 # load color
    sw $t4 0($v0) # store color (10, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x26304e # load color
    sw $t4 0($v0) # store color (11, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x395382 # load color
    sw $t4 0($v0) # store color (12, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x243553 # load color
    sw $t4 0($v0) # store color (13, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 12)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x07090c # load color
    sw $t4 0($v0) # store color (1, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x323f5b # load color
    sw $t4 0($v0) # store color (2, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x354970 # load color
    sw $t4 0($v0) # store color (3, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3f5682 # load color
    sw $t4 0($v0) # store color (4, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x333c5e # load color
    sw $t4 0($v0) # store color (5, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x363c63 # load color
    sw $t4 0($v0) # store color (6, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb4b3cc # load color
    sw $t4 0($v0) # store color (7, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe0deec # load color
    sw $t4 0($v0) # store color (8, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd9d8e7 # load color
    sw $t4 0($v0) # store color (9, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7b85a4 # load color
    sw $t4 0($v0) # store color (10, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5c617f # load color
    sw $t4 0($v0) # store color (11, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3b5381 # load color
    sw $t4 0($v0) # store color (12, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x101826 # load color
    sw $t4 0($v0) # store color (13, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 13)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010101 # load color
    sw $t4 0($v0) # store color (1, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x202633 # load color
    sw $t4 0($v0) # store color (2, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4a597c # load color
    sw $t4 0($v0) # store color (3, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x495271 # load color
    sw $t4 0($v0) # store color (4, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x747998 # load color
    sw $t4 0($v0) # store color (5, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x99a3bb # load color
    sw $t4 0($v0) # store color (6, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x757b9b # load color
    sw $t4 0($v0) # store color (7, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8290ab # load color
    sw $t4 0($v0) # store color (8, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xacb1c9 # load color
    sw $t4 0($v0) # store color (9, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7b7a93 # load color
    sw $t4 0($v0) # store color (10, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x384666 # load color
    sw $t4 0($v0) # store color (11, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x111a2a # load color
    sw $t4 0($v0) # store color (12, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 14)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (2, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0d0e12 # load color
    sw $t4 0($v0) # store color (3, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x20212a # load color
    sw $t4 0($v0) # store color (4, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6d7395 # load color
    sw $t4 0($v0) # store color (5, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8286a8 # load color
    sw $t4 0($v0) # store color (6, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4b5067 # load color
    sw $t4 0($v0) # store color (7, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x30384f # load color
    sw $t4 0($v0) # store color (8, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x535c7e # load color
    sw $t4 0($v0) # store color (9, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x434962 # load color
    sw $t4 0($v0) # store color (10, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000104 # load color
    sw $t4 0($v0) # store color (11, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (12, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 15)
    add $v0 $v0 $t0 # shift x
    jr $ra
draw_alice_02:
    sw $0 0($v0) # store background (0, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (2, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2f1c14 # load color
    sw $t4 0($v0) # store color (3, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x93543d # load color
    sw $t4 0($v0) # store color (4, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeda88a # load color
    sw $t4 0($v0) # store color (5, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd5a9af # load color
    sw $t4 0($v0) # store color (6, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc490a5 # load color
    sw $t4 0($v0) # store color (7, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd69ea8 # load color
    sw $t4 0($v0) # store color (8, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc38b97 # load color
    sw $t4 0($v0) # store color (9, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc999a9 # load color
    sw $t4 0($v0) # store color (10, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9c98a0 # load color
    sw $t4 0($v0) # store color (11, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3a2a20 # load color
    sw $t4 0($v0) # store color (12, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 0)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0c0705 # load color
    sw $t4 0($v0) # store color (1, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5d3627 # load color
    sw $t4 0($v0) # store color (2, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcd805f # load color
    sw $t4 0($v0) # store color (3, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeabcb1 # load color
    sw $t4 0($v0) # store color (4, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc27d8d # load color
    sw $t4 0($v0) # store color (5, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa7445c # load color
    sw $t4 0($v0) # store color (6, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbe7c87 # load color
    sw $t4 0($v0) # store color (7, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe0a19e # load color
    sw $t4 0($v0) # store color (8, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdfa09e # load color
    sw $t4 0($v0) # store color (9, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf7e86 # load color
    sw $t4 0($v0) # store color (10, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc36d82 # load color
    sw $t4 0($v0) # store color (11, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd09992 # load color
    sw $t4 0($v0) # store color (12, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6a5044 # load color
    sw $t4 0($v0) # store color (13, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0c0706 # load color
    sw $t4 0($v0) # store color (14, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 1)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7a4833 # load color
    sw $t4 0($v0) # store color (1, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc47152 # load color
    sw $t4 0($v0) # store color (2, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdda59a # load color
    sw $t4 0($v0) # store color (3, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd7484 # load color
    sw $t4 0($v0) # store color (4, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xae4f64 # load color
    sw $t4 0($v0) # store color (5, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe1ae94 # load color
    sw $t4 0($v0) # store color (6, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4c17b # load color
    sw $t4 0($v0) # store color (7, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4c170 # load color
    sw $t4 0($v0) # store color (8, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5c071 # load color
    sw $t4 0($v0) # store color (9, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2bc7a # load color
    sw $t4 0($v0) # store color (10, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe3b8a8 # load color
    sw $t4 0($v0) # store color (11, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xda9a98 # load color
    sw $t4 0($v0) # store color (12, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe4aa85 # load color
    sw $t4 0($v0) # store color (13, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8c623f # load color
    sw $t4 0($v0) # store color (14, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x100908 # load color
    sw $t4 0($v0) # store color (15, 2)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x41261c # load color
    sw $t4 0($v0) # store color (0, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb76d4e # load color
    sw $t4 0($v0) # store color (1, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd89967 # load color
    sw $t4 0($v0) # store color (2, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcc8b7a # load color
    sw $t4 0($v0) # store color (3, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb9636b # load color
    sw $t4 0($v0) # store color (4, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe8b78e # load color
    sw $t4 0($v0) # store color (5, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed67a # load color
    sw $t4 0($v0) # store color (6, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfddb74 # load color
    sw $t4 0($v0) # store color (7, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbe380 # load color
    sw $t4 0($v0) # store color (8, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe387 # load color
    sw $t4 0($v0) # store color (9, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdda79 # load color
    sw $t4 0($v0) # store color (10, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdd881 # load color
    sw $t4 0($v0) # store color (11, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe7b4 # load color
    sw $t4 0($v0) # store color (12, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8cf88 # load color
    sw $t4 0($v0) # store color (13, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1c86e # load color
    sw $t4 0($v0) # store color (14, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0x543f26 # load color
    sw $t4 0($v0) # store color (15, 3)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x9d5b43 # load color
    sw $t4 0($v0) # store color (0, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc07653 # load color
    sw $t4 0($v0) # store color (1, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c372 # load color
    sw $t4 0($v0) # store color (2, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6cd7b # load color
    sw $t4 0($v0) # store color (3, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe7af78 # load color
    sw $t4 0($v0) # store color (4, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfadaa3 # load color
    sw $t4 0($v0) # store color (5, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7d8ad # load color
    sw $t4 0($v0) # store color (6, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe1aa6d # load color
    sw $t4 0($v0) # store color (7, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfde6a2 # load color
    sw $t4 0($v0) # store color (8, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfee8ba # load color
    sw $t4 0($v0) # store color (9, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2ab70 # load color
    sw $t4 0($v0) # store color (10, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9d994 # load color
    sw $t4 0($v0) # store color (11, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbdaa2 # load color
    sw $t4 0($v0) # store color (12, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xefb36d # load color
    sw $t4 0($v0) # store color (13, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd678 # load color
    sw $t4 0($v0) # store color (14, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbe9955 # load color
    sw $t4 0($v0) # store color (15, 4)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbd6e50 # load color
    sw $t4 0($v0) # store color (0, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdc9562 # load color
    sw $t4 0($v0) # store color (1, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9d177 # load color
    sw $t4 0($v0) # store color (2, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad178 # load color
    sw $t4 0($v0) # store color (3, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3b771 # load color
    sw $t4 0($v0) # store color (4, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c977 # load color
    sw $t4 0($v0) # store color (5, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc57a52 # load color
    sw $t4 0($v0) # store color (6, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc58152 # load color
    sw $t4 0($v0) # store color (7, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe27c # load color
    sw $t4 0($v0) # store color (8, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9b366 # load color
    sw $t4 0($v0) # store color (9, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa15635 # load color
    sw $t4 0($v0) # store color (10, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb57349 # load color
    sw $t4 0($v0) # store color (11, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9cc7a # load color
    sw $t4 0($v0) # store color (12, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe6b16d # load color
    sw $t4 0($v0) # store color (13, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe8ac6c # load color
    sw $t4 0($v0) # store color (14, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe5c76d # load color
    sw $t4 0($v0) # store color (15, 5)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbc6e4f # load color
    sw $t4 0($v0) # store color (0, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe6ae6a # load color
    sw $t4 0($v0) # store color (1, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedbf6f # load color
    sw $t4 0($v0) # store color (2, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcd079 # load color
    sw $t4 0($v0) # store color (3, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd0895e # load color
    sw $t4 0($v0) # store color (4, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x86573e # load color
    sw $t4 0($v0) # store color (5, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x793a27 # load color
    sw $t4 0($v0) # store color (6, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa47656 # load color
    sw $t4 0($v0) # store color (7, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf0ba72 # load color
    sw $t4 0($v0) # store color (8, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xce8469 # load color
    sw $t4 0($v0) # store color (9, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x704e4b # load color
    sw $t4 0($v0) # store color (10, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8b5e5a # load color
    sw $t4 0($v0) # store color (11, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeea765 # load color
    sw $t4 0($v0) # store color (12, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd3a75e # load color
    sw $t4 0($v0) # store color (13, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb76d4c # load color
    sw $t4 0($v0) # store color (14, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7b06a # load color
    sw $t4 0($v0) # store color (15, 6)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xce7b57 # load color
    sw $t4 0($v0) # store color (0, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe3a366 # load color
    sw $t4 0($v0) # store color (1, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd6915e # load color
    sw $t4 0($v0) # store color (2, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed67b # load color
    sw $t4 0($v0) # store color (3, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb98657 # load color
    sw $t4 0($v0) # store color (4, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x988588 # load color
    sw $t4 0($v0) # store color (5, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x697274 # load color
    sw $t4 0($v0) # store color (6, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbca69b # load color
    sw $t4 0($v0) # store color (7, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9bfa9 # load color
    sw $t4 0($v0) # store color (8, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5d8d0 # load color
    sw $t4 0($v0) # store color (9, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6c9fac # load color
    sw $t4 0($v0) # store color (10, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf9c94 # load color
    sw $t4 0($v0) # store color (11, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd49250 # load color
    sw $t4 0($v0) # store color (12, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf884e # load color
    sw $t4 0($v0) # store color (13, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5b3322 # load color
    sw $t4 0($v0) # store color (14, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6d6036 # load color
    sw $t4 0($v0) # store color (15, 7)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xd07b58 # load color
    sw $t4 0($v0) # store color (0, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdc895e # load color
    sw $t4 0($v0) # store color (1, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xce8056 # load color
    sw $t4 0($v0) # store color (2, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1b26f # load color
    sw $t4 0($v0) # store color (3, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdda769 # load color
    sw $t4 0($v0) # store color (4, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbab5b5 # load color
    sw $t4 0($v0) # store color (5, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2f92a3 # load color
    sw $t4 0($v0) # store color (6, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd3d5d1 # load color
    sw $t4 0($v0) # store color (7, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe8df # load color
    sw $t4 0($v0) # store color (8, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdeae2 # load color
    sw $t4 0($v0) # store color (9, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa5c5c4 # load color
    sw $t4 0($v0) # store color (10, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb9682 # load color
    sw $t4 0($v0) # store color (11, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcf6f4d # load color
    sw $t4 0($v0) # store color (12, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x905137 # load color
    sw $t4 0($v0) # store color (13, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x190d09 # load color
    sw $t4 0($v0) # store color (14, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x070805 # load color
    sw $t4 0($v0) # store color (15, 8)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x955741 # load color
    sw $t4 0($v0) # store color (0, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd57d5b # load color
    sw $t4 0($v0) # store color (1, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x804730 # load color
    sw $t4 0($v0) # store color (2, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x975b3f # load color
    sw $t4 0($v0) # store color (3, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd58456 # load color
    sw $t4 0($v0) # store color (4, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc99586 # load color
    sw $t4 0($v0) # store color (5, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbdb8bf # load color
    sw $t4 0($v0) # store color (6, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3d8d4 # load color
    sw $t4 0($v0) # store color (7, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe6dd # load color
    sw $t4 0($v0) # store color (8, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfedbd3 # load color
    sw $t4 0($v0) # store color (9, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdfafa2 # load color
    sw $t4 0($v0) # store color (10, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc77756 # load color
    sw $t4 0($v0) # store color (11, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd87853 # load color
    sw $t4 0($v0) # store color (12, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6b3c2b # load color
    sw $t4 0($v0) # store color (13, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000001 # load color
    sw $t4 0($v0) # store color (14, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 9)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x1a0d0d # load color
    sw $t4 0($v0) # store color (0, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x935641 # load color
    sw $t4 0($v0) # store color (1, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4d291e # load color
    sw $t4 0($v0) # store color (2, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x361e0f # load color
    sw $t4 0($v0) # store color (3, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa65c3b # load color
    sw $t4 0($v0) # store color (4, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd0988c # load color
    sw $t4 0($v0) # store color (5, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8c9d1 # load color
    sw $t4 0($v0) # store color (6, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5c9c7 # load color
    sw $t4 0($v0) # store color (7, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcd7179 # load color
    sw $t4 0($v0) # store color (8, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdeacb3 # load color
    sw $t4 0($v0) # store color (9, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbc9895 # load color
    sw $t4 0($v0) # store color (10, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbe6b5f # load color
    sw $t4 0($v0) # store color (11, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x572a18 # load color
    sw $t4 0($v0) # store color (12, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1c0f08 # load color
    sw $t4 0($v0) # store color (13, 10)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 10)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 10)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x060303 # load color
    sw $t4 0($v0) # store color (1, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x020203 # load color
    sw $t4 0($v0) # store color (2, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0b0f18 # load color
    sw $t4 0($v0) # store color (3, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3d2c26 # load color
    sw $t4 0($v0) # store color (4, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaa8d8c # load color
    sw $t4 0($v0) # store color (5, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd3b8c6 # load color
    sw $t4 0($v0) # store color (6, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd49ca0 # load color
    sw $t4 0($v0) # store color (7, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd59094 # load color
    sw $t4 0($v0) # store color (8, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd3979e # load color
    sw $t4 0($v0) # store color (9, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb0a2b0 # load color
    sw $t4 0($v0) # store color (10, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5b4151 # load color
    sw $t4 0($v0) # store color (11, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0e1726 # load color
    sw $t4 0($v0) # store color (12, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x04070d # load color
    sw $t4 0($v0) # store color (13, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 11)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x141b26 # load color
    sw $t4 0($v0) # store color (2, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2b3a53 # load color
    sw $t4 0($v0) # store color (3, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x213553 # load color
    sw $t4 0($v0) # store color (4, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2f446b # load color
    sw $t4 0($v0) # store color (5, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x414564 # load color
    sw $t4 0($v0) # store color (6, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x697394 # load color
    sw $t4 0($v0) # store color (7, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x818b9f # load color
    sw $t4 0($v0) # store color (8, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x727687 # load color
    sw $t4 0($v0) # store color (9, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x363d58 # load color
    sw $t4 0($v0) # store color (10, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1d2746 # load color
    sw $t4 0($v0) # store color (11, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x354d7a # load color
    sw $t4 0($v0) # store color (12, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2b3f64 # load color
    sw $t4 0($v0) # store color (13, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010203 # load color
    sw $t4 0($v0) # store color (14, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 12)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x05070a # load color
    sw $t4 0($v0) # store color (1, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2d3852 # load color
    sw $t4 0($v0) # store color (2, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x32456a # load color
    sw $t4 0($v0) # store color (3, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3a5481 # load color
    sw $t4 0($v0) # store color (4, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2f3c5e # load color
    sw $t4 0($v0) # store color (5, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2f3459 # load color
    sw $t4 0($v0) # store color (6, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xadacc6 # load color
    sw $t4 0($v0) # store color (7, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdcdae8 # load color
    sw $t4 0($v0) # store color (8, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd3d2df # load color
    sw $t4 0($v0) # store color (9, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7f88a6 # load color
    sw $t4 0($v0) # store color (10, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x525571 # load color
    sw $t4 0($v0) # store color (11, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x415784 # load color
    sw $t4 0($v0) # store color (12, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x21314d # load color
    sw $t4 0($v0) # store color (13, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010101 # load color
    sw $t4 0($v0) # store color (14, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 13)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x020203 # load color
    sw $t4 0($v0) # store color (1, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x282f40 # load color
    sw $t4 0($v0) # store color (2, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x49597f # load color
    sw $t4 0($v0) # store color (3, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4b587c # load color
    sw $t4 0($v0) # store color (4, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x646988 # load color
    sw $t4 0($v0) # store color (5, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7a88a5 # load color
    sw $t4 0($v0) # store color (6, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x777e9f # load color
    sw $t4 0($v0) # store color (7, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9da7bd # load color
    sw $t4 0($v0) # store color (8, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb7bbd0 # load color
    sw $t4 0($v0) # store color (9, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x908faa # load color
    sw $t4 0($v0) # store color (10, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x505a7b # load color
    sw $t4 0($v0) # store color (11, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x23324e # load color
    sw $t4 0($v0) # store color (12, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010102 # load color
    sw $t4 0($v0) # store color (13, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 14)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010101 # load color
    sw $t4 0($v0) # store color (2, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1b2029 # load color
    sw $t4 0($v0) # store color (3, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x21232d # load color
    sw $t4 0($v0) # store color (4, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6f7494 # load color
    sw $t4 0($v0) # store color (5, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9a9cba # load color
    sw $t4 0($v0) # store color (6, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x676a86 # load color
    sw $t4 0($v0) # store color (7, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3b4865 # load color
    sw $t4 0($v0) # store color (8, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5a6384 # load color
    sw $t4 0($v0) # store color (9, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5c617b # load color
    sw $t4 0($v0) # store color (10, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x04070e # load color
    sw $t4 0($v0) # store color (11, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010202 # load color
    sw $t4 0($v0) # store color (12, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 15)
    add $v0 $v0 $t0 # shift x
    jr $ra
draw_alice_03:
    sw $0 0($v0) # store background (0, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (2, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x130c09 # load color
    sw $t4 0($v0) # store color (3, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6e3c2b # load color
    sw $t4 0($v0) # store color (4, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xed9973 # load color
    sw $t4 0($v0) # store color (5, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2c0c0 # load color
    sw $t4 0($v0) # store color (6, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcdb2c5 # load color
    sw $t4 0($v0) # store color (7, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe4c4cb # load color
    sw $t4 0($v0) # store color (8, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcaaab3 # load color
    sw $t4 0($v0) # store color (9, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd5b7c3 # load color
    sw $t4 0($v0) # store color (10, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x999ba2 # load color
    sw $t4 0($v0) # store color (11, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1e150f # load color
    sw $t4 0($v0) # store color (12, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 0)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x341e16 # load color
    sw $t4 0($v0) # store color (2, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb46d4d # load color
    sw $t4 0($v0) # store color (3, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebaf9a # load color
    sw $t4 0($v0) # store color (4, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd29ea5 # load color
    sw $t4 0($v0) # store color (5, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa74159 # load color
    sw $t4 0($v0) # store color (6, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb06075 # load color
    sw $t4 0($v0) # store color (7, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd3868e # load color
    sw $t4 0($v0) # store color (8, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd4868e # load color
    sw $t4 0($v0) # store color (9, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb86b7b # load color
    sw $t4 0($v0) # store color (10, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc07189 # load color
    sw $t4 0($v0) # store color (11, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd09f93 # load color
    sw $t4 0($v0) # store color (12, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4d3f35 # load color
    sw $t4 0($v0) # store color (13, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x020001 # load color
    sw $t4 0($v0) # store color (14, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 1)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5c3626 # load color
    sw $t4 0($v0) # store color (1, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb7694a # load color
    sw $t4 0($v0) # store color (2, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2a28d # load color
    sw $t4 0($v0) # store color (3, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb969f # load color
    sw $t4 0($v0) # store color (4, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaa475e # load color
    sw $t4 0($v0) # store color (5, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd29a94 # load color
    sw $t4 0($v0) # store color (6, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebb889 # load color
    sw $t4 0($v0) # store color (7, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2bd7e # load color
    sw $t4 0($v0) # store color (8, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3bd80 # load color
    sw $t4 0($v0) # store color (9, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeab582 # load color
    sw $t4 0($v0) # store color (10, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdba9a3 # load color
    sw $t4 0($v0) # store color (11, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcf878c # load color
    sw $t4 0($v0) # store color (12, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd99a7f # load color
    sw $t4 0($v0) # store color (13, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x78563a # load color
    sw $t4 0($v0) # store color (14, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0e0707 # load color
    sw $t4 0($v0) # store color (15, 2)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x281711 # load color
    sw $t4 0($v0) # store color (0, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xac6548 # load color
    sw $t4 0($v0) # store color (1, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcf8a60 # load color
    sw $t4 0($v0) # store color (2, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb8b82 # load color
    sw $t4 0($v0) # store color (3, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb15263 # load color
    sw $t4 0($v0) # store color (4, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd99d88 # load color
    sw $t4 0($v0) # store color (5, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfac971 # load color
    sw $t4 0($v0) # store color (6, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdb72 # load color
    sw $t4 0($v0) # store color (7, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbe177 # load color
    sw $t4 0($v0) # store color (8, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe07c # load color
    sw $t4 0($v0) # store color (9, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdb76 # load color
    sw $t4 0($v0) # store color (10, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfacf7d # load color
    sw $t4 0($v0) # store color (11, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe9bd # load color
    sw $t4 0($v0) # store color (12, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8cf93 # load color
    sw $t4 0($v0) # store color (13, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9bc69 # load color
    sw $t4 0($v0) # store color (14, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0x543c26 # load color
    sw $t4 0($v0) # store color (15, 3)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x824c37 # load color
    sw $t4 0($v0) # store color (0, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd7352 # load color
    sw $t4 0($v0) # store color (1, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf0ba6e # load color
    sw $t4 0($v0) # store color (2, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1c47b # load color
    sw $t4 0($v0) # store color (3, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdda37a # load color
    sw $t4 0($v0) # store color (4, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8d29d # load color
    sw $t4 0($v0) # store color (5, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfee6b1 # load color
    sw $t4 0($v0) # store color (6, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xecb976 # load color
    sw $t4 0($v0) # store color (7, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfce39a # load color
    sw $t4 0($v0) # store color (8, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffeabb # load color
    sw $t4 0($v0) # store color (9, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xecbf7e # load color
    sw $t4 0($v0) # store color (10, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcde91 # load color
    sw $t4 0($v0) # store color (11, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcdea8 # load color
    sw $t4 0($v0) # store color (12, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1b870 # load color
    sw $t4 0($v0) # store color (13, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd879 # load color
    sw $t4 0($v0) # store color (14, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb79351 # load color
    sw $t4 0($v0) # store color (15, 4)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbb6c4f # load color
    sw $t4 0($v0) # store color (0, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd3885c # load color
    sw $t4 0($v0) # store color (1, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8cc76 # load color
    sw $t4 0($v0) # store color (2, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcd478 # load color
    sw $t4 0($v0) # store color (3, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2b670 # load color
    sw $t4 0($v0) # store color (4, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd684 # load color
    sw $t4 0($v0) # store color (5, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd8986c # load color
    sw $t4 0($v0) # store color (6, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc27d52 # load color
    sw $t4 0($v0) # store color (7, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfee183 # load color
    sw $t4 0($v0) # store color (8, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6cd80 # load color
    sw $t4 0($v0) # store color (9, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb66c46 # load color
    sw $t4 0($v0) # store color (10, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc58455 # load color
    sw $t4 0($v0) # store color (11, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad487 # load color
    sw $t4 0($v0) # store color (12, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xecb671 # load color
    sw $t4 0($v0) # store color (13, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe5ac6c # load color
    sw $t4 0($v0) # store color (14, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeece6f # load color
    sw $t4 0($v0) # store color (15, 5)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xba6c4e # load color
    sw $t4 0($v0) # store color (0, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2a867 # load color
    sw $t4 0($v0) # store color (1, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2c673 # load color
    sw $t4 0($v0) # store color (2, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd279 # load color
    sw $t4 0($v0) # store color (3, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe29a68 # load color
    sw $t4 0($v0) # store color (4, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa67348 # load color
    sw $t4 0($v0) # store color (5, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8a442b # load color
    sw $t4 0($v0) # store color (6, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa56d4d # load color
    sw $t4 0($v0) # store color (7, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4c772 # load color
    sw $t4 0($v0) # store color (8, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd18559 # load color
    sw $t4 0($v0) # store color (9, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7d463a # load color
    sw $t4 0($v0) # store color (10, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7b4d47 # load color
    sw $t4 0($v0) # store color (11, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe99f62 # load color
    sw $t4 0($v0) # store color (12, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdeb566 # load color
    sw $t4 0($v0) # store color (13, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc27952 # load color
    sw $t4 0($v0) # store color (14, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9bc71 # load color
    sw $t4 0($v0) # store color (15, 6)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xc87654 # load color
    sw $t4 0($v0) # store color (0, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe5a768 # load color
    sw $t4 0($v0) # store color (1, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xda9a61 # load color
    sw $t4 0($v0) # store color (2, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed67a # load color
    sw $t4 0($v0) # store color (3, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xba8356 # load color
    sw $t4 0($v0) # store color (4, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x816668 # load color
    sw $t4 0($v0) # store color (5, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x715c58 # load color
    sw $t4 0($v0) # store color (6, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa58d80 # load color
    sw $t4 0($v0) # store color (7, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4b592 # load color
    sw $t4 0($v0) # store color (8, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf0c6bb # load color
    sw $t4 0($v0) # store color (9, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6f8f9b # load color
    sw $t4 0($v0) # store color (10, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xac9496 # load color
    sw $t4 0($v0) # store color (11, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdd9a56 # load color
    sw $t4 0($v0) # store color (12, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcf9f58 # load color
    sw $t4 0($v0) # store color (13, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x75422d # load color
    sw $t4 0($v0) # store color (14, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8f7946 # load color
    sw $t4 0($v0) # store color (15, 7)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xce7a57 # load color
    sw $t4 0($v0) # store color (0, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xde8f61 # load color
    sw $t4 0($v0) # store color (1, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd08357 # load color
    sw $t4 0($v0) # store color (2, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6be74 # load color
    sw $t4 0($v0) # store color (3, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdba866 # load color
    sw $t4 0($v0) # store color (4, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc1b2b0 # load color
    sw $t4 0($v0) # store color (5, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4498a6 # load color
    sw $t4 0($v0) # store color (6, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc2cac7 # load color
    sw $t4 0($v0) # store color (7, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe1d6 # load color
    sw $t4 0($v0) # store color (8, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffeae2 # load color
    sw $t4 0($v0) # store color (9, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8fbdbf # load color
    sw $t4 0($v0) # store color (10, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc7a596 # load color
    sw $t4 0($v0) # store color (11, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc76d48 # load color
    sw $t4 0($v0) # store color (12, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa5613f # load color
    sw $t4 0($v0) # store color (13, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x301910 # load color
    sw $t4 0($v0) # store color (14, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x12130a # load color
    sw $t4 0($v0) # store color (15, 8)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xac664a # load color
    sw $t4 0($v0) # store color (0, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd67e5c # load color
    sw $t4 0($v0) # store color (1, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x96553a # load color
    sw $t4 0($v0) # store color (2, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaa6948 # load color
    sw $t4 0($v0) # store color (3, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdc905c # load color
    sw $t4 0($v0) # store color (4, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc89e8f # load color
    sw $t4 0($v0) # store color (5, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8fadb9 # load color
    sw $t4 0($v0) # store color (6, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe1d7d5 # load color
    sw $t4 0($v0) # store color (7, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffeee5 # load color
    sw $t4 0($v0) # store color (8, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe7de # load color
    sw $t4 0($v0) # store color (9, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeac9bf # load color
    sw $t4 0($v0) # store color (10, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca8163 # load color
    sw $t4 0($v0) # store color (11, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe17b55 # load color
    sw $t4 0($v0) # store color (12, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x854935 # load color
    sw $t4 0($v0) # store color (13, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x050304 # load color
    sw $t4 0($v0) # store color (14, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 9)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x301a17 # load color
    sw $t4 0($v0) # store color (0, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xae674d # load color
    sw $t4 0($v0) # store color (1, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x693828 # load color
    sw $t4 0($v0) # store color (2, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x492919 # load color
    sw $t4 0($v0) # store color (3, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb56542 # load color
    sw $t4 0($v0) # store color (4, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc18271 # load color
    sw $t4 0($v0) # store color (5, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4bcc3 # load color
    sw $t4 0($v0) # store color (6, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad1cf # load color
    sw $t4 0($v0) # store color (7, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe39b9c # load color
    sw $t4 0($v0) # store color (8, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9b6ba # load color
    sw $t4 0($v0) # store color (9, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbc918a # load color
    sw $t4 0($v0) # store color (10, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf6e5e # load color
    sw $t4 0($v0) # store color (11, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8c492e # load color
    sw $t4 0($v0) # store color (12, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x391f13 # load color
    sw $t4 0($v0) # store color (13, 10)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 10)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 10)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1a0e0c # load color
    sw $t4 0($v0) # store color (1, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x120d10 # load color
    sw $t4 0($v0) # store color (2, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x161e2c # load color
    sw $t4 0($v0) # store color (3, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4e3123 # load color
    sw $t4 0($v0) # store color (4, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc9a29c # load color
    sw $t4 0($v0) # store color (5, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd8bdc4 # load color
    sw $t4 0($v0) # store color (6, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca9195 # load color
    sw $t4 0($v0) # store color (7, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa24451 # load color
    sw $t4 0($v0) # store color (8, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xae6873 # load color
    sw $t4 0($v0) # store color (9, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc0aeb7 # load color
    sw $t4 0($v0) # store color (10, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x905f6b # load color
    sw $t4 0($v0) # store color (11, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x29334f # load color
    sw $t4 0($v0) # store color (12, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x111a2b # load color
    sw $t4 0($v0) # store color (13, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 11)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x17202e # load color
    sw $t4 0($v0) # store color (2, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2c3c58 # load color
    sw $t4 0($v0) # store color (3, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x283f63 # load color
    sw $t4 0($v0) # store color (4, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x344971 # load color
    sw $t4 0($v0) # store color (5, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x373956 # load color
    sw $t4 0($v0) # store color (6, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x757694 # load color
    sw $t4 0($v0) # store color (7, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8989a2 # load color
    sw $t4 0($v0) # store color (8, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x84828f # load color
    sw $t4 0($v0) # store color (9, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x484e6d # load color
    sw $t4 0($v0) # store color (10, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2d334e # load color
    sw $t4 0($v0) # store color (11, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x384f7c # load color
    sw $t4 0($v0) # store color (12, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x364f7c # load color
    sw $t4 0($v0) # store color (13, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x05070b # load color
    sw $t4 0($v0) # store color (14, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 12)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x050609 # load color
    sw $t4 0($v0) # store color (1, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x313b56 # load color
    sw $t4 0($v0) # store color (2, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x394c73 # load color
    sw $t4 0($v0) # store color (3, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x415985 # load color
    sw $t4 0($v0) # store color (4, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3b4465 # load color
    sw $t4 0($v0) # store color (5, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x363f66 # load color
    sw $t4 0($v0) # store color (6, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9194b3 # load color
    sw $t4 0($v0) # store color (7, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdfdeec # load color
    sw $t4 0($v0) # store color (8, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdbdbea # load color
    sw $t4 0($v0) # store color (9, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9ca1bc # load color
    sw $t4 0($v0) # store color (10, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x646a89 # load color
    sw $t4 0($v0) # store color (11, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x445783 # load color
    sw $t4 0($v0) # store color (12, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x152033 # load color
    sw $t4 0($v0) # store color (13, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010102 # load color
    sw $t4 0($v0) # store color (14, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 13)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x13161d # load color
    sw $t4 0($v0) # store color (2, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x475373 # load color
    sw $t4 0($v0) # store color (3, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3f4863 # load color
    sw $t4 0($v0) # store color (4, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x717492 # load color
    sw $t4 0($v0) # store color (5, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa7b0c6 # load color
    sw $t4 0($v0) # store color (6, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7c829f # load color
    sw $t4 0($v0) # store color (7, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6b7b98 # load color
    sw $t4 0($v0) # store color (8, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x929cb7 # load color
    sw $t4 0($v0) # store color (9, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x908ea7 # load color
    sw $t4 0($v0) # store color (10, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x353c55 # load color
    sw $t4 0($v0) # store color (11, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x152135 # load color
    sw $t4 0($v0) # store color (12, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 14)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (2, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x050506 # load color
    sw $t4 0($v0) # store color (3, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x141419 # load color
    sw $t4 0($v0) # store color (4, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x616787 # load color
    sw $t4 0($v0) # store color (5, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x757ba0 # load color
    sw $t4 0($v0) # store color (6, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x484c64 # load color
    sw $t4 0($v0) # store color (7, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x292f40 # load color
    sw $t4 0($v0) # store color (8, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x424969 # load color
    sw $t4 0($v0) # store color (9, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4e5879 # load color
    sw $t4 0($v0) # store color (10, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x020305 # load color
    sw $t4 0($v0) # store color (11, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (12, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 15)
    add $v0 $v0 $t0 # shift x
    jr $ra
draw_alice_04:
    sw $0 0($v0) # store background (0, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (2, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x150c0a # load color
    sw $t4 0($v0) # store color (3, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7a4431 # load color
    sw $t4 0($v0) # store color (4, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xee9d79 # load color
    sw $t4 0($v0) # store color (5, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe1c2c4 # load color
    sw $t4 0($v0) # store color (6, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xceb1c3 # load color
    sw $t4 0($v0) # store color (7, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe1c2c8 # load color
    sw $t4 0($v0) # store color (8, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xccabb4 # load color
    sw $t4 0($v0) # store color (9, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd4bac7 # load color
    sw $t4 0($v0) # store color (10, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7d8084 # load color
    sw $t4 0($v0) # store color (11, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x160e08 # load color
    sw $t4 0($v0) # store color (12, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 0)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3d231a # load color
    sw $t4 0($v0) # store color (2, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xba7152 # load color
    sw $t4 0($v0) # store color (3, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebb3a1 # load color
    sw $t4 0($v0) # store color (4, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcc929d # load color
    sw $t4 0($v0) # store color (5, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa53e57 # load color
    sw $t4 0($v0) # store color (6, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb6687b # load color
    sw $t4 0($v0) # store color (7, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd58a90 # load color
    sw $t4 0($v0) # store color (8, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd3878f # load color
    sw $t4 0($v0) # store color (9, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb56a7a # load color
    sw $t4 0($v0) # store color (10, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc87a8e # load color
    sw $t4 0($v0) # store color (11, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc29789 # load color
    sw $t4 0($v0) # store color (12, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3d2e27 # load color
    sw $t4 0($v0) # store color (13, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 1)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x633a29 # load color
    sw $t4 0($v0) # store color (1, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbb6b4c # load color
    sw $t4 0($v0) # store color (2, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2a693 # load color
    sw $t4 0($v0) # store color (3, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc68c98 # load color
    sw $t4 0($v0) # store color (4, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xac4a60 # load color
    sw $t4 0($v0) # store color (5, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7a397 # load color
    sw $t4 0($v0) # store color (6, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedb984 # load color
    sw $t4 0($v0) # store color (7, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3be7d # load color
    sw $t4 0($v0) # store color (8, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3be7e # load color
    sw $t4 0($v0) # store color (9, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebb584 # load color
    sw $t4 0($v0) # store color (10, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd8a7a5 # load color
    sw $t4 0($v0) # store color (11, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd38888 # load color
    sw $t4 0($v0) # store color (12, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd39c7b # load color
    sw $t4 0($v0) # store color (13, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x62442b # load color
    sw $t4 0($v0) # store color (14, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x070304 # load color
    sw $t4 0($v0) # store color (15, 2)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x2d1a13 # load color
    sw $t4 0($v0) # store color (0, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaf684b # load color
    sw $t4 0($v0) # store color (1, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd28f63 # load color
    sw $t4 0($v0) # store color (2, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca8980 # load color
    sw $t4 0($v0) # store color (3, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb35665 # load color
    sw $t4 0($v0) # store color (4, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdfa889 # load color
    sw $t4 0($v0) # store color (5, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcce72 # load color
    sw $t4 0($v0) # store color (6, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfedc72 # load color
    sw $t4 0($v0) # store color (7, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbe17a # load color
    sw $t4 0($v0) # store color (8, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe17d # load color
    sw $t4 0($v0) # store color (9, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed876 # load color
    sw $t4 0($v0) # store color (10, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcd586 # load color
    sw $t4 0($v0) # store color (11, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfee7bd # load color
    sw $t4 0($v0) # store color (12, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7cd85 # load color
    sw $t4 0($v0) # store color (13, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdeb164 # load color
    sw $t4 0($v0) # store color (14, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0x332419 # load color
    sw $t4 0($v0) # store color (15, 3)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x884f3a # load color
    sw $t4 0($v0) # store color (0, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf7553 # load color
    sw $t4 0($v0) # store color (1, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2be70 # load color
    sw $t4 0($v0) # store color (2, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1c57b # load color
    sw $t4 0($v0) # store color (3, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe0a77a # load color
    sw $t4 0($v0) # store color (4, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad8a2 # load color
    sw $t4 0($v0) # store color (5, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfce1af # load color
    sw $t4 0($v0) # store color (6, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeab873 # load color
    sw $t4 0($v0) # store color (7, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfde7a3 # load color
    sw $t4 0($v0) # store color (8, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfee7b8 # load color
    sw $t4 0($v0) # store color (9, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9b874 # load color
    sw $t4 0($v0) # store color (10, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe39e # load color
    sw $t4 0($v0) # store color (11, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9d59c # load color
    sw $t4 0($v0) # store color (12, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2ba70 # load color
    sw $t4 0($v0) # store color (13, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbdb78 # load color
    sw $t4 0($v0) # store color (14, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9c7b44 # load color
    sw $t4 0($v0) # store color (15, 4)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbc6d4f # load color
    sw $t4 0($v0) # store color (0, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd78e5e # load color
    sw $t4 0($v0) # store color (1, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9ce77 # load color
    sw $t4 0($v0) # store color (2, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd278 # load color
    sw $t4 0($v0) # store color (3, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2b770 # load color
    sw $t4 0($v0) # store color (4, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7d080 # load color
    sw $t4 0($v0) # store color (5, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcd8760 # load color
    sw $t4 0($v0) # store color (6, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc78655 # load color
    sw $t4 0($v0) # store color (7, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe483 # load color
    sw $t4 0($v0) # store color (8, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedbd75 # load color
    sw $t4 0($v0) # store color (9, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaa5f3d # load color
    sw $t4 0($v0) # store color (10, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca8d5c # load color
    sw $t4 0($v0) # store color (11, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd481 # load color
    sw $t4 0($v0) # store color (12, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe5ab6c # load color
    sw $t4 0($v0) # store color (13, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeeb970 # load color
    sw $t4 0($v0) # store color (14, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd6ba64 # load color
    sw $t4 0($v0) # store color (15, 5)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xba6c4e # load color
    sw $t4 0($v0) # store color (0, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe4aa68 # load color
    sw $t4 0($v0) # store color (1, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf0c471 # load color
    sw $t4 0($v0) # store color (2, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd079 # load color
    sw $t4 0($v0) # store color (3, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd99263 # load color
    sw $t4 0($v0) # store color (4, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x966441 # load color
    sw $t4 0($v0) # store color (5, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x823d28 # load color
    sw $t4 0($v0) # store color (6, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xab7854 # load color
    sw $t4 0($v0) # store color (7, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2bf70 # load color
    sw $t4 0($v0) # store color (8, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc97d5c # load color
    sw $t4 0($v0) # store color (9, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6f463f # load color
    sw $t4 0($v0) # store color (10, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8f5a50 # load color
    sw $t4 0($v0) # store color (11, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1af69 # load color
    sw $t4 0($v0) # store color (12, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcfa05c # load color
    sw $t4 0($v0) # store color (13, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc97e57 # load color
    sw $t4 0($v0) # store color (14, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd2b168 # load color
    sw $t4 0($v0) # store color (15, 6)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xca7855 # load color
    sw $t4 0($v0) # store color (0, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe5a668 # load color
    sw $t4 0($v0) # store color (1, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd8965f # load color
    sw $t4 0($v0) # store color (2, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed77a # load color
    sw $t4 0($v0) # store color (3, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb48055 # load color
    sw $t4 0($v0) # store color (4, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8b7477 # load color
    sw $t4 0($v0) # store color (5, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6a6362 # load color
    sw $t4 0($v0) # store color (6, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb89c8f # load color
    sw $t4 0($v0) # store color (7, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6ba9e # load color
    sw $t4 0($v0) # store color (8, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeecdc6 # load color
    sw $t4 0($v0) # store color (9, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6794a3 # load color
    sw $t4 0($v0) # store color (10, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc0938a # load color
    sw $t4 0($v0) # store color (11, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xda9e55 # load color
    sw $t4 0($v0) # store color (12, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbc874e # load color
    sw $t4 0($v0) # store color (13, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x623826 # load color
    sw $t4 0($v0) # store color (14, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x827341 # load color
    sw $t4 0($v0) # store color (15, 7)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xce7a57 # load color
    sw $t4 0($v0) # store color (0, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdd8c5f # load color
    sw $t4 0($v0) # store color (1, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcf8256 # load color
    sw $t4 0($v0) # store color (2, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3b971 # load color
    sw $t4 0($v0) # store color (3, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdaa668 # load color
    sw $t4 0($v0) # store color (4, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbab5b4 # load color
    sw $t4 0($v0) # store color (5, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3793a3 # load color
    sw $t4 0($v0) # store color (6, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd4d2ce # load color
    sw $t4 0($v0) # store color (7, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe4db # load color
    sw $t4 0($v0) # store color (8, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfae8e0 # load color
    sw $t4 0($v0) # store color (9, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x96bebe # load color
    sw $t4 0($v0) # store color (10, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca917c # load color
    sw $t4 0($v0) # store color (11, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb704b # load color
    sw $t4 0($v0) # store color (12, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8a4e34 # load color
    sw $t4 0($v0) # store color (13, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x180c08 # load color
    sw $t4 0($v0) # store color (14, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0e1009 # load color
    sw $t4 0($v0) # store color (15, 8)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xa05e45 # load color
    sw $t4 0($v0) # store color (0, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd57d5b # load color
    sw $t4 0($v0) # store color (1, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x894d35 # load color
    sw $t4 0($v0) # store color (2, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa16344 # load color
    sw $t4 0($v0) # store color (3, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd88a59 # load color
    sw $t4 0($v0) # store color (4, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc79c8e # load color
    sw $t4 0($v0) # store color (5, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa6b3bc # load color
    sw $t4 0($v0) # store color (6, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xefdad7 # load color
    sw $t4 0($v0) # store color (7, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffeae1 # load color
    sw $t4 0($v0) # store color (8, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfedfd7 # load color
    sw $t4 0($v0) # store color (9, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe1b5a8 # load color
    sw $t4 0($v0) # store color (10, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc97755 # load color
    sw $t4 0($v0) # store color (11, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdb7954 # load color
    sw $t4 0($v0) # store color (12, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x603527 # load color
    sw $t4 0($v0) # store color (13, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 9)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x211111 # load color
    sw $t4 0($v0) # store color (0, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa05d47 # load color
    sw $t4 0($v0) # store color (1, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5a2f21 # load color
    sw $t4 0($v0) # store color (2, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x412416 # load color
    sw $t4 0($v0) # store color (3, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb0623e # load color
    sw $t4 0($v0) # store color (4, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xce9183 # load color
    sw $t4 0($v0) # store color (5, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfecad0 # load color
    sw $t4 0($v0) # store color (6, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbcfcc # load color
    sw $t4 0($v0) # store color (7, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdc888b # load color
    sw $t4 0($v0) # store color (8, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9b8bd # load color
    sw $t4 0($v0) # store color (9, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb88f89 # load color
    sw $t4 0($v0) # store color (10, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc06958 # load color
    sw $t4 0($v0) # store color (11, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x65331f # load color
    sw $t4 0($v0) # store color (12, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1f1008 # load color
    sw $t4 0($v0) # store color (13, 10)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 10)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 10)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0d0706 # load color
    sw $t4 0($v0) # store color (1, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0e0e14 # load color
    sw $t4 0($v0) # store color (2, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1a2535 # load color
    sw $t4 0($v0) # store color (3, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x47332c # load color
    sw $t4 0($v0) # store color (4, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb89b9e # load color
    sw $t4 0($v0) # store color (5, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbea6ae # load color
    sw $t4 0($v0) # store color (6, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xad7580 # load color
    sw $t4 0($v0) # store color (7, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x934452 # load color
    sw $t4 0($v0) # store color (8, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9e656f # load color
    sw $t4 0($v0) # store color (9, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa996a5 # load color
    sw $t4 0($v0) # store color (10, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6a4c5e # load color
    sw $t4 0($v0) # store color (11, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x273c61 # load color
    sw $t4 0($v0) # store color (12, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x111a2b # load color
    sw $t4 0($v0) # store color (13, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 11)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1e2739 # load color
    sw $t4 0($v0) # store color (2, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2d3f5c # load color
    sw $t4 0($v0) # store color (3, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2b4770 # load color
    sw $t4 0($v0) # store color (4, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2b3f69 # load color
    sw $t4 0($v0) # store color (5, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x313555 # load color
    sw $t4 0($v0) # store color (6, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8b8fad # load color
    sw $t4 0($v0) # store color (7, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa1a5b9 # load color
    sw $t4 0($v0) # store color (8, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9498a7 # load color
    sw $t4 0($v0) # store color (9, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x485271 # load color
    sw $t4 0($v0) # store color (10, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x313753 # load color
    sw $t4 0($v0) # store color (11, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3c5584 # load color
    sw $t4 0($v0) # store color (12, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2b3f63 # load color
    sw $t4 0($v0) # store color (13, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 12)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x050709 # load color
    sw $t4 0($v0) # store color (1, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x343f5a # load color
    sw $t4 0($v0) # store color (2, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3d5078 # load color
    sw $t4 0($v0) # store color (3, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x465a84 # load color
    sw $t4 0($v0) # store color (4, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x444b6b # load color
    sw $t4 0($v0) # store color (5, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3f4c72 # load color
    sw $t4 0($v0) # store color (6, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9295b3 # load color
    sw $t4 0($v0) # store color (7, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7d8e6 # load color
    sw $t4 0($v0) # store color (8, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7d7e8 # load color
    sw $t4 0($v0) # store color (9, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9196b3 # load color
    sw $t4 0($v0) # store color (10, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x646c8e # load color
    sw $t4 0($v0) # store color (11, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x364b74 # load color
    sw $t4 0($v0) # store color (12, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x080d14 # load color
    sw $t4 0($v0) # store color (13, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 13)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0d0e13 # load color
    sw $t4 0($v0) # store color (2, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3d4760 # load color
    sw $t4 0($v0) # store color (3, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x373d52 # load color
    sw $t4 0($v0) # store color (4, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x777b99 # load color
    sw $t4 0($v0) # store color (5, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb0b5cb # load color
    sw $t4 0($v0) # store color (6, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x787d9b # load color
    sw $t4 0($v0) # store color (7, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5b6c8c # load color
    sw $t4 0($v0) # store color (8, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x868eab # load color
    sw $t4 0($v0) # store color (9, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x74738b # load color
    sw $t4 0($v0) # store color (10, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1c263a # load color
    sw $t4 0($v0) # store color (11, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x080d16 # load color
    sw $t4 0($v0) # store color (12, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 14)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (2, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (3, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x17181d # load color
    sw $t4 0($v0) # store color (4, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x606788 # load color
    sw $t4 0($v0) # store color (5, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x666d94 # load color
    sw $t4 0($v0) # store color (6, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2d3142 # load color
    sw $t4 0($v0) # store color (7, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1b1e28 # load color
    sw $t4 0($v0) # store color (8, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3d4464 # load color
    sw $t4 0($v0) # store color (9, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x404966 # load color
    sw $t4 0($v0) # store color (10, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (11, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (12, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 15)
    add $v0 $v0 $t0 # shift x
    jr $ra
draw_alice_05:
    sw $0 0($v0) # store background (0, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (2, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1c100e # load color
    sw $t4 0($v0) # store color (3, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x93553d # load color
    sw $t4 0($v0) # store color (4, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeda587 # load color
    sw $t4 0($v0) # store color (5, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdabfc8 # load color
    sw $t4 0($v0) # store color (6, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd1b0bf # load color
    sw $t4 0($v0) # store color (7, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd8b5bd # load color
    sw $t4 0($v0) # store color (8, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcda9b1 # load color
    sw $t4 0($v0) # store color (9, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcfbfcd # load color
    sw $t4 0($v0) # store color (10, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4b4946 # load color
    sw $t4 0($v0) # store color (11, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x070200 # load color
    sw $t4 0($v0) # store color (12, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 0)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x040201 # load color
    sw $t4 0($v0) # store color (1, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4e2e22 # load color
    sw $t4 0($v0) # store color (2, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc67b5b # load color
    sw $t4 0($v0) # store color (3, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9b6aa # load color
    sw $t4 0($v0) # store color (4, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc17b89 # load color
    sw $t4 0($v0) # store color (5, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa5445d # load color
    sw $t4 0($v0) # store color (6, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc27886 # load color
    sw $t4 0($v0) # store color (7, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd88d91 # load color
    sw $t4 0($v0) # store color (8, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd0858c # load color
    sw $t4 0($v0) # store color (9, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb2677b # load color
    sw $t4 0($v0) # store color (10, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd48e96 # load color
    sw $t4 0($v0) # store color (11, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x977869 # load color
    sw $t4 0($v0) # store color (12, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1e1411 # load color
    sw $t4 0($v0) # store color (13, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 1)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x010000 # load color
    sw $t4 0($v0) # store color (0, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x70412e # load color
    sw $t4 0($v0) # store color (1, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc37253 # load color
    sw $t4 0($v0) # store color (2, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe0aa9d # load color
    sw $t4 0($v0) # store color (3, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd7585 # load color
    sw $t4 0($v0) # store color (4, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb45d6b # load color
    sw $t4 0($v0) # store color (5, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe3b296 # load color
    sw $t4 0($v0) # store color (6, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1be7c # load color
    sw $t4 0($v0) # store color (7, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4c17c # load color
    sw $t4 0($v0) # store color (8, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3bf7a # load color
    sw $t4 0($v0) # store color (9, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeab68e # load color
    sw $t4 0($v0) # store color (10, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd5a3a3 # load color
    sw $t4 0($v0) # store color (11, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdd9588 # load color
    sw $t4 0($v0) # store color (12, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbc8f64 # load color
    sw $t4 0($v0) # store color (13, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x352116 # load color
    sw $t4 0($v0) # store color (14, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000001 # load color
    sw $t4 0($v0) # store color (15, 2)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x382118 # load color
    sw $t4 0($v0) # store color (0, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb46b4e # load color
    sw $t4 0($v0) # store color (1, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd79869 # load color
    sw $t4 0($v0) # store color (2, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc7827a # load color
    sw $t4 0($v0) # store color (3, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbc666d # load color
    sw $t4 0($v0) # store color (4, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebbb89 # load color
    sw $t4 0($v0) # store color (5, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed575 # load color
    sw $t4 0($v0) # store color (6, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdde74 # load color
    sw $t4 0($v0) # store color (7, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfde181 # load color
    sw $t4 0($v0) # store color (8, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe17f # load color
    sw $t4 0($v0) # store color (9, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd374 # load color
    sw $t4 0($v0) # store color (10, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe19c # load color
    sw $t4 0($v0) # store color (11, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbdbac # load color
    sw $t4 0($v0) # store color (12, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd076 # load color
    sw $t4 0($v0) # store color (13, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa4804b # load color
    sw $t4 0($v0) # store color (14, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0x100a09 # load color
    sw $t4 0($v0) # store color (15, 3)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x975840 # load color
    sw $t4 0($v0) # store color (0, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc27954 # load color
    sw $t4 0($v0) # store color (1, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c672 # load color
    sw $t4 0($v0) # store color (2, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2c77b # load color
    sw $t4 0($v0) # store color (3, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe7af7a # load color
    sw $t4 0($v0) # store color (4, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfde0a9 # load color
    sw $t4 0($v0) # store color (5, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf0ca9e # load color
    sw $t4 0($v0) # store color (6, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe8b971 # load color
    sw $t4 0($v0) # store color (7, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfeebb0 # load color
    sw $t4 0($v0) # store color (8, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6d7a7 # load color
    sw $t4 0($v0) # store color (9, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe6b069 # load color
    sw $t4 0($v0) # store color (10, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe7ae # load color
    sw $t4 0($v0) # store color (11, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4c181 # load color
    sw $t4 0($v0) # store color (12, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5c474 # load color
    sw $t4 0($v0) # store color (13, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe8c66a # load color
    sw $t4 0($v0) # store color (14, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0x705231 # load color
    sw $t4 0($v0) # store color (15, 4)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbe6f50 # load color
    sw $t4 0($v0) # store color (0, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdc9761 # load color
    sw $t4 0($v0) # store color (1, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad378 # load color
    sw $t4 0($v0) # store color (2, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9cc77 # load color
    sw $t4 0($v0) # store color (3, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4bb73 # load color
    sw $t4 0($v0) # store color (4, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedbc73 # load color
    sw $t4 0($v0) # store color (5, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xba6d4b # load color
    sw $t4 0($v0) # store color (6, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7a060 # load color
    sw $t4 0($v0) # store color (7, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfddc7a # load color
    sw $t4 0($v0) # store color (8, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd49358 # load color
    sw $t4 0($v0) # store color (9, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0x954c2f # load color
    sw $t4 0($v0) # store color (10, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd99f66 # load color
    sw $t4 0($v0) # store color (11, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9cf79 # load color
    sw $t4 0($v0) # store color (12, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xda9864 # load color
    sw $t4 0($v0) # store color (13, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9ce76 # load color
    sw $t4 0($v0) # store color (14, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0x988649 # load color
    sw $t4 0($v0) # store color (15, 5)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbd6f4f # load color
    sw $t4 0($v0) # store color (0, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe6ad6a # load color
    sw $t4 0($v0) # store color (1, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedbe6f # load color
    sw $t4 0($v0) # store color (2, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfacb78 # load color
    sw $t4 0($v0) # store color (3, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc17e58 # load color
    sw $t4 0($v0) # store color (4, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7e503a # load color
    sw $t4 0($v0) # store color (5, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7a3d2c # load color
    sw $t4 0($v0) # store color (6, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc09466 # load color
    sw $t4 0($v0) # store color (7, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9aa6f # load color
    sw $t4 0($v0) # store color (8, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb77565 # load color
    sw $t4 0($v0) # store color (9, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x604f56 # load color
    sw $t4 0($v0) # store color (10, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbe755a # load color
    sw $t4 0($v0) # store color (11, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3c36d # load color
    sw $t4 0($v0) # store color (12, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb07348 # load color
    sw $t4 0($v0) # store color (13, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd29661 # load color
    sw $t4 0($v0) # store color (14, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x96874d # load color
    sw $t4 0($v0) # store color (15, 6)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xcd7b57 # load color
    sw $t4 0($v0) # store color (0, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe19e65 # load color
    sw $t4 0($v0) # store color (1, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7945f # load color
    sw $t4 0($v0) # store color (2, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd279 # load color
    sw $t4 0($v0) # store color (3, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb18159 # load color
    sw $t4 0($v0) # store color (4, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9e9498 # load color
    sw $t4 0($v0) # store color (5, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x63797c # load color
    sw $t4 0($v0) # store color (6, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe0baaa # load color
    sw $t4 0($v0) # store color (7, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8ccbc # load color
    sw $t4 0($v0) # store color (8, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcecbc8 # load color
    sw $t4 0($v0) # store color (9, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x79a5b3 # load color
    sw $t4 0($v0) # store color (10, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcd8764 # load color
    sw $t4 0($v0) # store color (11, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd19854 # load color
    sw $t4 0($v0) # store color (12, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x885132 # load color
    sw $t4 0($v0) # store color (13, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4d3b23 # load color
    sw $t4 0($v0) # store color (14, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x544d2a # load color
    sw $t4 0($v0) # store color (15, 7)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xcf7b57 # load color
    sw $t4 0($v0) # store color (0, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xda845d # load color
    sw $t4 0($v0) # store color (1, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc87e54 # load color
    sw $t4 0($v0) # store color (2, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xecaa6b # load color
    sw $t4 0($v0) # store color (3, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd8a36c # load color
    sw $t4 0($v0) # store color (4, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa3b4b9 # load color
    sw $t4 0($v0) # store color (5, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4098a8 # load color
    sw $t4 0($v0) # store color (6, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5e4dc # load color
    sw $t4 0($v0) # store color (7, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffeae2 # load color
    sw $t4 0($v0) # store color (8, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe5e1da # load color
    sw $t4 0($v0) # store color (9, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbabdb7 # load color
    sw $t4 0($v0) # store color (10, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc77355 # load color
    sw $t4 0($v0) # store color (11, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc96f4f # load color
    sw $t4 0($v0) # store color (12, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x44241a # load color
    sw $t4 0($v0) # store color (13, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x020202 # load color
    sw $t4 0($v0) # store color (14, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x050604 # load color
    sw $t4 0($v0) # store color (15, 8)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x824c39 # load color
    sw $t4 0($v0) # store color (0, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xce7958 # load color
    sw $t4 0($v0) # store color (1, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x723f2a # load color
    sw $t4 0($v0) # store color (2, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x96593d # load color
    sw $t4 0($v0) # store color (3, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcc7b52 # load color
    sw $t4 0($v0) # store color (4, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcd998d # load color
    sw $t4 0($v0) # store color (5, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdcc2c7 # load color
    sw $t4 0($v0) # store color (6, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdd8d2 # load color
    sw $t4 0($v0) # store color (7, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffd9d1 # load color
    sw $t4 0($v0) # store color (8, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4c8c2 # load color
    sw $t4 0($v0) # store color (9, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc68774 # load color
    sw $t4 0($v0) # store color (10, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xce7450 # load color
    sw $t4 0($v0) # store color (11, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa85d40 # load color
    sw $t4 0($v0) # store color (12, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1c100d # load color
    sw $t4 0($v0) # store color (13, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 9)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x0d0607 # load color
    sw $t4 0($v0) # store color (0, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6d3f31 # load color
    sw $t4 0($v0) # store color (1, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x341c17 # load color
    sw $t4 0($v0) # store color (2, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x332018 # load color
    sw $t4 0($v0) # store color (3, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9d5b3d # load color
    sw $t4 0($v0) # store color (4, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe0b2ad # load color
    sw $t4 0($v0) # store color (5, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed7db # load color
    sw $t4 0($v0) # store color (6, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe5a8a9 # load color
    sw $t4 0($v0) # store color (7, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb6c77 # load color
    sw $t4 0($v0) # store color (8, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdfbcc0 # load color
    sw $t4 0($v0) # store color (9, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd8d8e # load color
    sw $t4 0($v0) # store color (10, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x86493f # load color
    sw $t4 0($v0) # store color (11, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x261a1a # load color
    sw $t4 0($v0) # store color (12, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x030100 # load color
    sw $t4 0($v0) # store color (13, 10)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 10)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 10)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x111823 # load color
    sw $t4 0($v0) # store color (2, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x202f45 # load color
    sw $t4 0($v0) # store color (3, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3b3a47 # load color
    sw $t4 0($v0) # store color (4, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x827b8e # load color
    sw $t4 0($v0) # store color (5, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x816d7c # load color
    sw $t4 0($v0) # store color (6, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7d566e # load color
    sw $t4 0($v0) # store color (7, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7a505f # load color
    sw $t4 0($v0) # store color (8, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x755a69 # load color
    sw $t4 0($v0) # store color (9, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6f6178 # load color
    sw $t4 0($v0) # store color (10, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x343c5e # load color
    sw $t4 0($v0) # store color (11, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x314a78 # load color
    sw $t4 0($v0) # store color (12, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0f1522 # load color
    sw $t4 0($v0) # store color (13, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 11)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x050608 # load color
    sw $t4 0($v0) # store color (1, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2a364e # load color
    sw $t4 0($v0) # store color (2, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x32466b # load color
    sw $t4 0($v0) # store color (3, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x354f7c # load color
    sw $t4 0($v0) # store color (4, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2a375c # load color
    sw $t4 0($v0) # store color (5, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x42476b # load color
    sw $t4 0($v0) # store color (6, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbcc0d8 # load color
    sw $t4 0($v0) # store color (7, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcccfdd # load color
    sw $t4 0($v0) # store color (8, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb3b8cc # load color
    sw $t4 0($v0) # store color (9, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4e5978 # load color
    sw $t4 0($v0) # store color (10, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x495172 # load color
    sw $t4 0($v0) # store color (11, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x354f7d # load color
    sw $t4 0($v0) # store color (12, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0d141f # load color
    sw $t4 0($v0) # store color (13, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 12)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x030305 # load color
    sw $t4 0($v0) # store color (1, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2d354a # load color
    sw $t4 0($v0) # store color (2, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x47577e # load color
    sw $t4 0($v0) # store color (3, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4e5a7e # load color
    sw $t4 0($v0) # store color (4, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x656b89 # load color
    sw $t4 0($v0) # store color (5, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x73809f # load color
    sw $t4 0($v0) # store color (6, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x868ca9 # load color
    sw $t4 0($v0) # store color (7, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xabb4c8 # load color
    sw $t4 0($v0) # store color (8, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbcbdd3 # load color
    sw $t4 0($v0) # store color (9, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x737490 # load color
    sw $t4 0($v0) # store color (10, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x44557a # load color
    sw $t4 0($v0) # store color (11, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0f1827 # load color
    sw $t4 0($v0) # store color (12, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 13)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x030304 # load color
    sw $t4 0($v0) # store color (2, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1d222c # load color
    sw $t4 0($v0) # store color (3, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2b2d3a # load color
    sw $t4 0($v0) # store color (4, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7d81a2 # load color
    sw $t4 0($v0) # store color (5, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x989ab7 # load color
    sw $t4 0($v0) # store color (6, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x555c77 # load color
    sw $t4 0($v0) # store color (7, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3f4c6a # load color
    sw $t4 0($v0) # store color (8, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6b7392 # load color
    sw $t4 0($v0) # store color (9, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x36394a # load color
    sw $t4 0($v0) # store color (10, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x04080f # load color
    sw $t4 0($v0) # store color (11, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (12, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 14)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (2, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (3, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x25262f # load color
    sw $t4 0($v0) # store color (4, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5d668a # load color
    sw $t4 0($v0) # store color (5, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4f587c # load color
    sw $t4 0($v0) # store color (6, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x050507 # load color
    sw $t4 0($v0) # store color (7, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0b0b12 # load color
    sw $t4 0($v0) # store color (8, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x454e71 # load color
    sw $t4 0($v0) # store color (9, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x282d40 # load color
    sw $t4 0($v0) # store color (10, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (11, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (12, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 15)
    add $v0 $v0 $t0 # shift x
    jr $ra
clear_alice: # start at v0
    sw $0 0($v1) # clear (0, 0)
    sw $0 4($v1) # clear (1, 0)
    sw $0 8($v1) # clear (2, 0)
    sw $0 24($v1) # clear (6, 0)
    sw $0 28($v1) # clear (7, 0)
    sw $0 32($v1) # clear (8, 0)
    sw $0 36($v1) # clear (9, 0)
    sw $0 40($v1) # clear (10, 0)
    sw $0 44($v1) # clear (11, 0)
    sw $0 48($v1) # clear (12, 0)
    sw $0 52($v1) # clear (13, 0)
    sw $0 56($v1) # clear (14, 0)
    sw $0 60($v1) # clear (15, 0)
    sw $0 512($v1) # clear (0, 1)
    sw $0 516($v1) # clear (1, 1)
    sw $0 520($v1) # clear (2, 1)
    sw $0 548($v1) # clear (9, 1)
    sw $0 552($v1) # clear (10, 1)
    sw $0 556($v1) # clear (11, 1)
    sw $0 560($v1) # clear (12, 1)
    sw $0 564($v1) # clear (13, 1)
    sw $0 568($v1) # clear (14, 1)
    sw $0 572($v1) # clear (15, 1)
    sw $0 1024($v1) # clear (0, 2)
    sw $0 1028($v1) # clear (1, 2)
    sw $0 1032($v1) # clear (2, 2)
    sw $0 1076($v1) # clear (13, 2)
    sw $0 1080($v1) # clear (14, 2)
    sw $0 1084($v1) # clear (15, 2)
    sw $0 1536($v1) # clear (0, 3)
    sw $0 1540($v1) # clear (1, 3)
    sw $0 1544($v1) # clear (2, 3)
    sw $0 2048($v1) # clear (0, 4)
    sw $0 2052($v1) # clear (1, 4)
    sw $0 2560($v1) # clear (0, 5)
    sw $0 2564($v1) # clear (1, 5)
    sw $0 2620($v1) # clear (15, 5)
    sw $0 3072($v1) # clear (0, 6)
    sw $0 3076($v1) # clear (1, 6)
    sw $0 3132($v1) # clear (15, 6)
    sw $0 3584($v1) # clear (0, 7)
    sw $0 3588($v1) # clear (1, 7)
    sw $0 3644($v1) # clear (15, 7)
    sw $0 4096($v1) # clear (0, 8)
    sw $0 4156($v1) # clear (15, 8)
    sw $0 4608($v1) # clear (0, 9)
    sw $0 4664($v1) # clear (14, 9)
    sw $0 4668($v1) # clear (15, 9)
    sw $0 5120($v1) # clear (0, 10)
    sw $0 5176($v1) # clear (14, 10)
    sw $0 5180($v1) # clear (15, 10)
    sw $0 5688($v1) # clear (14, 11)
    sw $0 5692($v1) # clear (15, 11)
    sw $0 6144($v1) # clear (0, 12)
    sw $0 6200($v1) # clear (14, 12)
    sw $0 6204($v1) # clear (15, 12)
    sw $0 6656($v1) # clear (0, 13)
    sw $0 6660($v1) # clear (1, 13)
    sw $0 6664($v1) # clear (2, 13)
    sw $0 6668($v1) # clear (3, 13)
    sw $0 6708($v1) # clear (13, 13)
    sw $0 6712($v1) # clear (14, 13)
    sw $0 6716($v1) # clear (15, 13)
    sw $0 7168($v1) # clear (0, 14)
    sw $0 7172($v1) # clear (1, 14)
    sw $0 7176($v1) # clear (2, 14)
    sw $0 7180($v1) # clear (3, 14)
    sw $0 7184($v1) # clear (4, 14)
    sw $0 7188($v1) # clear (5, 14)
    sw $0 7192($v1) # clear (6, 14)
    sw $0 7196($v1) # clear (7, 14)
    sw $0 7220($v1) # clear (13, 14)
    sw $0 7224($v1) # clear (14, 14)
    sw $0 7228($v1) # clear (15, 14)
    sw $0 7680($v1) # clear (0, 15)
    sw $0 7684($v1) # clear (1, 15)
    sw $0 7688($v1) # clear (2, 15)
    sw $0 7692($v1) # clear (3, 15)
    sw $0 7696($v1) # clear (4, 15)
    sw $0 7700($v1) # clear (5, 15)
    sw $0 7704($v1) # clear (6, 15)
    sw $0 7708($v1) # clear (7, 15)
    sw $0 7712($v1) # clear (8, 15)
    sw $0 7716($v1) # clear (9, 15)
    sw $0 7720($v1) # clear (10, 15)
    sw $0 7724($v1) # clear (11, 15)
    sw $0 7732($v1) # clear (13, 15)
    sw $0 7736($v1) # clear (14, 15)
    sw $0 7740($v1) # clear (15, 15)
    li $a0 REFRESH_RATE
    li $v0 32
    syscall
    sw $0 12($v1) # clear (3, 0)
    sw $0 16($v1) # clear (4, 0)
    sw $0 20($v1) # clear (5, 0)
    sw $0 524($v1) # clear (3, 1)
    sw $0 528($v1) # clear (4, 1)
    sw $0 532($v1) # clear (5, 1)
    sw $0 540($v1) # clear (7, 1)
    sw $0 544($v1) # clear (8, 1)
    sw $0 1036($v1) # clear (3, 2)
    sw $0 1040($v1) # clear (4, 2)
    sw $0 1060($v1) # clear (9, 2)
    sw $0 1064($v1) # clear (10, 2)
    sw $0 1068($v1) # clear (11, 2)
    sw $0 1072($v1) # clear (12, 2)
    sw $0 1548($v1) # clear (3, 3)
    sw $0 1552($v1) # clear (4, 3)
    sw $0 1580($v1) # clear (11, 3)
    sw $0 1584($v1) # clear (12, 3)
    sw $0 1588($v1) # clear (13, 3)
    sw $0 1592($v1) # clear (14, 3)
    sw $0 1596($v1) # clear (15, 3)
    sw $0 2056($v1) # clear (2, 4)
    sw $0 2060($v1) # clear (3, 4)
    sw $0 2100($v1) # clear (13, 4)
    sw $0 2104($v1) # clear (14, 4)
    sw $0 2108($v1) # clear (15, 4)
    sw $0 2568($v1) # clear (2, 5)
    sw $0 2616($v1) # clear (14, 5)
    sw $0 3080($v1) # clear (2, 6)
    sw $0 3640($v1) # clear (14, 7)
    sw $0 4100($v1) # clear (1, 8)
    sw $0 4152($v1) # clear (14, 8)
    sw $0 4660($v1) # clear (13, 9)
    sw $0 5124($v1) # clear (1, 10)
    sw $0 5172($v1) # clear (13, 10)
    sw $0 5632($v1) # clear (0, 11)
    sw $0 5636($v1) # clear (1, 11)
    sw $0 5640($v1) # clear (2, 11)
    sw $0 5644($v1) # clear (3, 11)
    sw $0 5680($v1) # clear (12, 11)
    sw $0 5684($v1) # clear (13, 11)
    sw $0 6148($v1) # clear (1, 12)
    sw $0 6152($v1) # clear (2, 12)
    sw $0 6156($v1) # clear (3, 12)
    sw $0 6160($v1) # clear (4, 12)
    sw $0 6192($v1) # clear (12, 12)
    sw $0 6196($v1) # clear (13, 12)
    sw $0 6672($v1) # clear (4, 13)
    sw $0 6676($v1) # clear (5, 13)
    sw $0 6680($v1) # clear (6, 13)
    sw $0 6700($v1) # clear (11, 13)
    sw $0 6704($v1) # clear (12, 13)
    sw $0 7200($v1) # clear (8, 14)
    sw $0 7212($v1) # clear (11, 14)
    sw $0 7216($v1) # clear (12, 14)
    sw $0 7728($v1) # clear (12, 15)
    li $a0 REFRESH_RATE
    li $v0 32
    syscall
    sw $0 536($v1) # clear (6, 1)
    sw $0 1044($v1) # clear (5, 2)
    sw $0 1048($v1) # clear (6, 2)
    sw $0 1556($v1) # clear (5, 3)
    sw $0 1576($v1) # clear (10, 3)
    sw $0 2064($v1) # clear (4, 4)
    sw $0 2092($v1) # clear (11, 4)
    sw $0 2096($v1) # clear (12, 4)
    sw $0 2572($v1) # clear (3, 5)
    sw $0 2608($v1) # clear (12, 5)
    sw $0 2612($v1) # clear (13, 5)
    sw $0 3124($v1) # clear (13, 6)
    sw $0 3128($v1) # clear (14, 6)
    sw $0 4612($v1) # clear (1, 9)
    sw $0 4616($v1) # clear (2, 9)
    sw $0 5128($v1) # clear (2, 10)
    sw $0 5132($v1) # clear (3, 10)
    sw $0 5168($v1) # clear (12, 10)
    sw $0 5648($v1) # clear (4, 11)
    sw $0 5676($v1) # clear (11, 11)
    sw $0 6164($v1) # clear (5, 12)
    sw $0 6184($v1) # clear (10, 12)
    sw $0 6188($v1) # clear (11, 12)
    sw $0 6684($v1) # clear (7, 13)
    sw $0 6692($v1) # clear (9, 13)
    sw $0 6696($v1) # clear (10, 13)
    sw $0 7204($v1) # clear (9, 14)
    sw $0 7208($v1) # clear (10, 14)
    li $a0 REFRESH_RATE
    li $v0 32
    syscall
    sw $0 1052($v1) # clear (7, 2)
    sw $0 1056($v1) # clear (8, 2)
    sw $0 1560($v1) # clear (6, 3)
    sw $0 1564($v1) # clear (7, 3)
    sw $0 2068($v1) # clear (5, 4)
    sw $0 2072($v1) # clear (6, 4)
    sw $0 2088($v1) # clear (10, 4)
    sw $0 2576($v1) # clear (4, 5)
    sw $0 2604($v1) # clear (11, 5)
    sw $0 3116($v1) # clear (11, 6)
    sw $0 3120($v1) # clear (12, 6)
    sw $0 3592($v1) # clear (2, 7)
    sw $0 3632($v1) # clear (12, 7)
    sw $0 3636($v1) # clear (13, 7)
    sw $0 4104($v1) # clear (2, 8)
    sw $0 4108($v1) # clear (3, 8)
    sw $0 4148($v1) # clear (13, 8)
    sw $0 4620($v1) # clear (3, 9)
    sw $0 4624($v1) # clear (4, 9)
    sw $0 5136($v1) # clear (4, 10)
    sw $0 5164($v1) # clear (11, 10)
    sw $0 5652($v1) # clear (5, 11)
    sw $0 5668($v1) # clear (9, 11)
    sw $0 5672($v1) # clear (10, 11)
    sw $0 6176($v1) # clear (8, 12)
    sw $0 6180($v1) # clear (9, 12)
    sw $0 6688($v1) # clear (8, 13)
    li $a0 REFRESH_RATE
    li $v0 32
    syscall
    sw $0 1568($v1) # clear (8, 3)
    sw $0 1572($v1) # clear (9, 3)
    sw $0 2076($v1) # clear (7, 4)
    sw $0 2080($v1) # clear (8, 4)
    sw $0 3084($v1) # clear (3, 6)
    sw $0 3596($v1) # clear (3, 7)
    sw $0 3600($v1) # clear (4, 7)
    sw $0 3628($v1) # clear (11, 7)
    sw $0 4112($v1) # clear (4, 8)
    sw $0 4144($v1) # clear (12, 8)
    sw $0 4656($v1) # clear (12, 9)
    sw $0 5660($v1) # clear (7, 11)
    sw $0 5664($v1) # clear (8, 11)
    sw $0 6168($v1) # clear (6, 12)
    sw $0 6172($v1) # clear (7, 12)
    li $a0 REFRESH_RATE
    li $v0 32
    syscall
    sw $0 2084($v1) # clear (9, 4)
    sw $0 2580($v1) # clear (5, 5)
    sw $0 2584($v1) # clear (6, 5)
    sw $0 2588($v1) # clear (7, 5)
    sw $0 2592($v1) # clear (8, 5)
    sw $0 2596($v1) # clear (9, 5)
    sw $0 2600($v1) # clear (10, 5)
    sw $0 3088($v1) # clear (4, 6)
    sw $0 3092($v1) # clear (5, 6)
    sw $0 3112($v1) # clear (10, 6)
    sw $0 3604($v1) # clear (5, 7)
    sw $0 3624($v1) # clear (10, 7)
    sw $0 4116($v1) # clear (5, 8)
    sw $0 4136($v1) # clear (10, 8)
    sw $0 4140($v1) # clear (11, 8)
    sw $0 4628($v1) # clear (5, 9)
    sw $0 4648($v1) # clear (10, 9)
    sw $0 4652($v1) # clear (11, 9)
    sw $0 5140($v1) # clear (5, 10)
    sw $0 5144($v1) # clear (6, 10)
    sw $0 5148($v1) # clear (7, 10)
    sw $0 5152($v1) # clear (8, 10)
    sw $0 5156($v1) # clear (9, 10)
    sw $0 5160($v1) # clear (10, 10)
    sw $0 5656($v1) # clear (6, 11)
    li $a0 REFRESH_RATE
    li $v0 32
    syscall
    sw $0 3096($v1) # clear (6, 6)
    sw $0 3100($v1) # clear (7, 6)
    sw $0 3108($v1) # clear (9, 6)
    sw $0 3620($v1) # clear (9, 7)
    sw $0 4120($v1) # clear (6, 8)
    sw $0 4632($v1) # clear (6, 9)
    sw $0 4640($v1) # clear (8, 9)
    sw $0 4644($v1) # clear (9, 9)
    li $a0 REFRESH_RATE
    li $v0 32
    syscall
    sw $0 3104($v1) # clear (8, 6)
    sw $0 3608($v1) # clear (6, 7)
    sw $0 4132($v1) # clear (9, 8)
    sw $0 4636($v1) # clear (7, 9)
    li $a0 REFRESH_RATE
    li $v0 32
    syscall
    sw $0 3612($v1) # clear (7, 7)
    sw $0 3616($v1) # clear (8, 7)
    sw $0 4124($v1) # clear (7, 8)
    sw $0 4128($v1) # clear (8, 8)
    li $a0 REFRESH_RATE
    li $v0 32
    syscall

    jr $ra

draw_doll:
    andi $t4 $s7 1 # every 2 frames
    bnez $t4 draw_doll_end # skip

    addi $sp $sp -4 # push ra to stack
    sw $ra 0($sp)
    # t5 is address to array of frames
    lw $t4 stage # stage number * 4
    la $t5 dolls
    add $t5 $t5 $t4 # address to dolls
    lw $t5 0($t5) # get doll (i.e. array of frames)
    # t4 frame index in words
    srl $t4 $s7 1
    rem $t4 $t4 DOLLS_FRAME
    sll $t4 $t4 2
    add $t5 $t5 $t4 # address to doll frame
    lw $t5 0($t5) # get doll frame
    lw $v0 doll_address

    jalr $t5

    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4

    draw_doll_end:
    jr $ra # return
draw_doll_01_00: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 536($v0) # (6, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1568($v0) # (8, 3)
    sw $0 2080($v0) # (8, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 3620($v0) # (9, 7)
    sw $0 4128($v0) # (8, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4644($v0) # (9, 9)
    sw $0 5148($v0) # (7, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5636($v0) # (1, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010100
    sw $t4 8($v0) # (2, 0)
    sw $t4 540($v0) # (7, 1)
    li $t4 0x000100
    sw $t4 12($v0) # (3, 0)
    sw $t4 3104($v0) # (8, 6)
    sw $t4 3616($v0) # (8, 7)
    sw $t4 5124($v0) # (1, 10)
    li $t4 0x030201
    sw $t4 24($v0) # (6, 0)
    li $t4 0x140b07
    sw $t4 528($v0) # (4, 1)
    li $t4 0x0c0504
    sw $t4 532($v0) # (5, 1)
    li $t4 0x030202
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x040404
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x1b060a
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xae523b
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xcd3f43
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xc84e42
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x592620
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x000001
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x010101
    sw $t4 1056($v0) # (8, 2)
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x925431
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xf9b253
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xdc7d42
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xd27344
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xe2934a
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x160804
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x020101
    sw $t4 1572($v0) # (9, 3)
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x6d657f
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x645d7a
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x9f4e3a
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xd5744e
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x854d56
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xb06a5d
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xa73147
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x572d45
    sw $t4 2076($v0) # (7, 4)
    li $t4 0xcfbff3
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xe8e4ff
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xae3f6a
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xb3333e
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xa298a6
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xc89f8e
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x90134e
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x604271
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x000101
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x655e75
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xc8c5e1
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x89478e
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x845da0
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x977cab
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xb197c0
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x92347e
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x3e2842
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x020102
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x39282f
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x6360ab
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x3a3a9a
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x954378
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x84295e
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x5a3d6f
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x020000
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x030303
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x250d0a
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x721650
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x342c91
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xa786c3
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x935ba0
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x660f2f
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x080403
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x000102
    sw $t4 4608($v0) # (0, 9)
    sw $t4 5120($v0) # (0, 10)
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x030000
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x041270
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x2c4bb7
    sw $t4 4620($v0) # (3, 9)
    li $t4 0xefe0fe
    sw $t4 4624($v0) # (4, 9)
    li $t4 0xa3c7ff
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x020d46
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x050000
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x000103
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x070b33
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x1838a2
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x3f68bc
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x1a5eb8
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x01112d
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x010000
    sw $t4 5632($v0) # (0, 11)
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x0b0601
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x372033
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x110915
    sw $t4 5648($v0) # (4, 11)
    jr $ra
draw_doll_01_01: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 540($v0) # (7, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1028($v0) # (1, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 1568($v0) # (8, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2076($v0) # (7, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 3616($v0) # (8, 7)
    sw $0 4132($v0) # (9, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x000401
    sw $t4 16($v0) # (4, 0)
    li $t4 0x010000
    sw $t4 28($v0) # (7, 0)
    sw $t4 512($v0) # (0, 1)
    sw $t4 1572($v0) # (9, 3)
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x010100
    sw $t4 516($v0) # (1, 1)
    sw $t4 5640($v0) # (2, 11)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x0c0205
    sw $t4 520($v0) # (2, 1)
    li $t4 0x893c2f
    sw $t4 524($v0) # (3, 1)
    li $t4 0xb13539
    sw $t4 528($v0) # (4, 1)
    li $t4 0xaa3e38
    sw $t4 532($v0) # (5, 1)
    li $t4 0x3a1116
    sw $t4 536($v0) # (6, 1)
    li $t4 0x010101
    sw $t4 544($v0) # (8, 1)
    sw $t4 2596($v0) # (9, 5)
    sw $t4 5124($v0) # (1, 10)
    li $t4 0x040201
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x803c2c
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xfba053
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xe37146
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xde7a49
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xdf934a
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x170409
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x010001
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x050403
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x040304
    sw $t4 1540($v0) # (1, 3)
    sw $t4 5120($v0) # (0, 10)
    li $t4 0x9c4e37
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xdb8a50
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x8e4d45
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xb36e4f
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xb86545
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x180509
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x541518
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xcb494d
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x958c9e
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xc69c8e
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x7a0e39
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x000100
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x231e28
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x595769
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x631a43
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x9c5b98
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x8e749d
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xa886ad
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x96296d
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x4b3355
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x000101
    sw $t4 2592($v0) # (8, 5)
    li $t4 0xc7beeb
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xe8d1f6
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x575bb1
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x414bac
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x8e4081
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x73366d
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x74407f
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x602f54
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x000201
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x020001
    sw $t4 3108($v0) # (9, 6)
    sw $t4 3620($v0) # (9, 7)
    li $t4 0xd2c7fa
    sw $t4 3584($v0) # (0, 7)
    li $t4 0xbea9c6
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x7d1d47
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x362185
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x8f5da3
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x752469
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x8c1c42
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x20040c
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x4b445a
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x16161c
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x100235
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x1833a6
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xe7def9
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x9bbaff
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x1b0646
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x060000
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x000102
    sw $t4 4128($v0) # (8, 8)
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x030831
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x123cb1
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x8586cb
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x396ecd
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x001738
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x0b0606
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x362443
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x0f0b25
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x000004
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x020000
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x030100
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x070300
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x000001
    sw $t4 5656($v0) # (6, 11)
    jr $ra
draw_doll_01_02: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 540($v0) # (7, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1056($v0) # (8, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1568($v0) # (8, 3)
    sw $0 3616($v0) # (8, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4644($v0) # (9, 9)
    sw $0 5124($v0) # (1, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010000
    sw $t4 4($v0) # (1, 0)
    sw $t4 5120($v0) # (0, 10)
    li $t4 0x090104
    sw $t4 12($v0) # (3, 0)
    li $t4 0x2a130e
    sw $t4 16($v0) # (4, 0)
    li $t4 0x1f0b0a
    sw $t4 20($v0) # (5, 0)
    li $t4 0x010100
    sw $t4 28($v0) # (7, 0)
    sw $t4 516($v0) # (1, 1)
    li $t4 0x020101
    sw $t4 512($v0) # (0, 1)
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x250c0d
    sw $t4 520($v0) # (2, 1)
    li $t4 0xbd5a41
    sw $t4 524($v0) # (3, 1)
    li $t4 0xd34145
    sw $t4 528($v0) # (4, 1)
    li $t4 0xd15746
    sw $t4 532($v0) # (5, 1)
    li $t4 0x6f3827
    sw $t4 536($v0) # (6, 1)
    li $t4 0x010101
    sw $t4 544($v0) # (8, 1)
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x050603
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x000101
    sw $t4 1028($v0) # (1, 2)
    sw $t4 2080($v0) # (8, 4)
    li $t4 0xa05d38
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xf7bd51
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xdb9340
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xe39d47
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xe3964c
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x210c0f
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x1a0007
    sw $t4 1540($v0) # (1, 3)
    li $t4 0xc14448
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xd27a4e
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x915e68
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xb87b68
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x9a1e43
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x220102
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x020001
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x2e2c39
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x431531
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x8c0329
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xb4394f
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xa0919f
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xc49a92
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x8c1248
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x473252
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x010001
    sw $t4 2084($v0) # (9, 4)
    sw $t4 3620($v0) # (9, 7)
    li $t4 0xc3bae3
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xd5c9ed
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x632d70
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x7e63ae
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x997bb4
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xa78fbc
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x955ead
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x614373
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x000200
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x020102
    sw $t4 2596($v0) # (9, 5)
    li $t4 0xa89fca
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xe4ccec
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x64589c
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x342e92
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x8c5494
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x822857
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x683c76
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x3a2738
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x000100
    sw $t4 3104($v0) # (8, 6)
    sw $t4 4636($v0) # (7, 9)
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x636078
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x4d323b
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x5d0744
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x3f3b9c
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xb593c7
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x996bad
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x560528
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x1b0403
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x02116f
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x3d5fc5
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x8ebfff
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x6da5ff
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x041356
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x040002
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x010103
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x030405
    sw $t4 4608($v0) # (0, 9)
    li $t4 0x010202
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x090928
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x1a39a0
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x0055bb
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x00489c
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x040e2b
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x000102
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x090501
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x2e1821
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x1c0606
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x030000
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x000204
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x000001
    sw $t4 5656($v0) # (6, 11)
    jr $ra
draw_doll_01_03: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 520($v0) # (2, 1)
    sw $0 536($v0) # (6, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1568($v0) # (8, 3)
    sw $0 3584($v0) # (0, 7)
    sw $0 4608($v0) # (0, 9)
    sw $0 4636($v0) # (7, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x020101
    sw $t4 8($v0) # (2, 0)
    sw $t4 516($v0) # (1, 1)
    sw $t4 1572($v0) # (9, 3)
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x010200
    sw $t4 24($v0) # (6, 0)
    li $t4 0x010101
    sw $t4 512($v0) # (0, 1)
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x1d060a
    sw $t4 524($v0) # (3, 1)
    li $t4 0x451917
    sw $t4 528($v0) # (4, 1)
    li $t4 0x381112
    sw $t4 532($v0) # (5, 1)
    li $t4 0x000100
    sw $t4 540($v0) # (7, 1)
    sw $t4 2080($v0) # (8, 4)
    sw $t4 3616($v0) # (8, 7)
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x000200
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x401318
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xdd7b4b
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xe96b4c
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xec8f4e
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x904f32
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x030001
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x010100
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x16161e
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x140004
    sw $t4 1540($v0) # (1, 3)
    li $t4 0xd06b46
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xe6a84d
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xbf6040
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xbe6345
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xde8c4b
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x250e0d
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xbcb8e2
    sw $t4 2048($v0) # (0, 4)
    li $t4 0xae799f
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xb83e3a
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xbc5249
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x896e7e
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xbd8677
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x8f1340
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x2d0b14
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x020001
    sw $t4 2084($v0) # (9, 4)
    li $t4 0xd9d0fb
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xdcd1ff
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x94074c
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xb13d57
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xaaa4a8
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xc4a09d
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x9f295f
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x684f7f
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x000101
    sw $t4 2592($v0) # (8, 5)
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x666177
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xa89cba
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x6a4496
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x655db0
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x8c6099
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x854d7f
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x7d58a4
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x3f264d
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x000302
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x010001
    sw $t4 3108($v0) # (9, 6)
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x2b1717
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x775895
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x342283
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x834c91
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x7d1b56
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x5c1b61
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x402531
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x030303
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x1d0808
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x4d0850
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x5f59ad
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xbbaee7
    sw $t4 4112($v0) # (4, 8)
    li $t4 0xa093db
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x4f0e40
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x200505
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x000007
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x082392
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x0a53cc
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x037ff9
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x077ffb
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x042585
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x000001
    sw $t4 5120($v0) # (0, 10)
    sw $t4 5124($v0) # (1, 10)
    sw $t4 5148($v0) # (7, 10)
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x0a0830
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x122968
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x0d4685
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x023875
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x030a23
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x010000
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x070000
    sw $t4 5644($v0) # (3, 11)
    sw $t4 5648($v0) # (4, 11)
    jr $ra
draw_doll_01_04: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 516($v0) # (1, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 1056($v0) # (8, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1568($v0) # (8, 3)
    sw $0 2084($v0) # (9, 4)
    sw $0 3620($v0) # (9, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4616($v0) # (2, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010100
    sw $t4 4($v0) # (1, 0)
    sw $t4 32($v0) # (8, 0)
    li $t4 0x020001
    sw $t4 8($v0) # (2, 0)
    li $t4 0x88412f
    sw $t4 12($v0) # (3, 0)
    li $t4 0xd34446
    sw $t4 16($v0) # (4, 0)
    li $t4 0xd44844
    sw $t4 20($v0) # (5, 0)
    li $t4 0x7e2e2c
    sw $t4 24($v0) # (6, 0)
    li $t4 0x040002
    sw $t4 28($v0) # (7, 0)
    li $t4 0x030101
    sw $t4 512($v0) # (0, 1)
    li $t4 0x4b171b
    sw $t4 520($v0) # (2, 1)
    li $t4 0xf5aa52
    sw $t4 524($v0) # (3, 1)
    li $t4 0xde7d45
    sw $t4 528($v0) # (4, 1)
    li $t4 0xd57643
    sw $t4 532($v0) # (5, 1)
    li $t4 0xf0994e
    sw $t4 536($v0) # (6, 1)
    li $t4 0x52291d
    sw $t4 540($v0) # (7, 1)
    li $t4 0x040201
    sw $t4 548($v0) # (9, 1)
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x050303
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x030203
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x4e211c
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xe3814e
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x945650
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x9e5555
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xb9564d
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x52251b
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x190001
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xc0303e
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x9a7488
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xc5b7a8
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x902e4c
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x070000
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x010000
    sw $t4 1572($v0) # (9, 3)
    sw $t4 3108($v0) # (9, 6)
    sw $t4 4632($v0) # (6, 9)
    sw $t4 4636($v0) # (7, 9)
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x1e1923
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x3d3d4c
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x5a2c5b
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x7d3b82
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xa28dbc
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x94739b
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xa877b3
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x66457e
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x080a0e
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x8b84a6
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xe9d4ff
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x8678bd
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x262e93
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xa88fc9
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xa03f65
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x55409a
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x4f306e
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x140d0c
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x000001
    sw $t4 2596($v0) # (9, 5)
    sw $t4 5644($v0) # (3, 11)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x8c82a8
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xd0c7e6
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x8a2745
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x321273
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x7e71bf
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xa475b3
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x50003f
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x63242d
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x080502
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x2c2838
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x19161f
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x0a0019
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x01239c
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xbcb9e5
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xcecfff
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x0b2676
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x040000
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x000102
    sw $t4 3616($v0) # (8, 7)
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x02020f
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x07248d
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x4676d7
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x4371d0
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x00255a
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x010201
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x000103
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x020202
    sw $t4 4608($v0) # (0, 9)
    li $t4 0x020203
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x1e111e
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x191538
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x000115
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x050000
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x040100
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x000002
    sw $t4 5648($v0) # (4, 11)
    jr $ra
draw_doll_01_05: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 2084($v0) # (9, 4)
    sw $0 2596($v0) # (9, 5)
    sw $0 3108($v0) # (9, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 3588($v0) # (1, 7)
    sw $0 3616($v0) # (8, 7)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4620($v0) # (3, 9)
    sw $0 4636($v0) # (7, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5136($v0) # (4, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x020201
    sw $t4 4($v0) # (1, 0)
    li $t4 0x58251f
    sw $t4 12($v0) # (3, 0)
    li $t4 0xcf5045
    sw $t4 16($v0) # (4, 0)
    li $t4 0xd54644
    sw $t4 20($v0) # (5, 0)
    li $t4 0xa8443a
    sw $t4 24($v0) # (6, 0)
    li $t4 0x19080a
    sw $t4 28($v0) # (7, 0)
    li $t4 0x010100
    sw $t4 32($v0) # (8, 0)
    li $t4 0x010000
    sw $t4 36($v0) # (9, 0)
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x020101
    sw $t4 512($v0) # (0, 1)
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x010201
    sw $t4 516($v0) # (1, 1)
    li $t4 0x160309
    sw $t4 520($v0) # (2, 1)
    li $t4 0xe19b4c
    sw $t4 524($v0) # (3, 1)
    li $t4 0xe69249
    sw $t4 528($v0) # (4, 1)
    li $t4 0xd26f41
    sw $t4 532($v0) # (5, 1)
    li $t4 0xe78c4b
    sw $t4 536($v0) # (6, 1)
    li $t4 0x905b32
    sw $t4 540($v0) # (7, 1)
    li $t4 0x010101
    sw $t4 544($v0) # (8, 1)
    li $t4 0x030301
    sw $t4 548($v0) # (9, 1)
    li $t4 0x2c0a12
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xe3824e
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xa7584d
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x986057
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xb75556
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x81232a
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x0f0c12
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x06040a
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x110001
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xb31f37
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xa55a6d
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xb3b7b0
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xb25765
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x680e41
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x171922
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x554d67
    sw $t4 2048($v0) # (0, 4)
    li $t4 0xc2bbd8
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x7d678e
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x68195f
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xaa91c4
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x8d719a
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xa97bae
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x924995
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x28293c
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x2d2837
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xe4d7ff
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xc2adda
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x293394
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x7062b3
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x9a3767
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x622d74
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x4c3990
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x2d1b23
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x363040
    sw $t4 3072($v0) # (0, 6)
    li $t4 0x7e7d93
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x712a38
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x491267
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x5b51ac
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xb489c0
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x6a175d
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x5d0c25
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x160a08
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x090018
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x0223a1
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x898acf
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xfcffff
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x416dcc
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x02000b
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x000001
    sw $t4 3620($v0) # (9, 7)
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x010102
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x030404
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x01030b
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x071764
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x2955ba
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x5383df
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x054699
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x01030e
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x000101
    sw $t4 4128($v0) # (8, 8)
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x020100
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x201427
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x321f3e
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x030000
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x020000
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x010202
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x000002
    sw $t4 5648($v0) # (4, 11)
    sw $t4 5652($v0) # (5, 11)
    jr $ra
draw_doll_01_06: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 1028($v0) # (1, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1572($v0) # (9, 3)
    sw $0 2084($v0) # (9, 4)
    sw $0 2596($v0) # (9, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3108($v0) # (9, 6)
    sw $0 4100($v0) # (1, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010001
    sw $t4 4($v0) # (1, 0)
    sw $t4 36($v0) # (9, 0)
    li $t4 0x020101
    sw $t4 8($v0) # (2, 0)
    li $t4 0x0f0006
    sw $t4 12($v0) # (3, 0)
    li $t4 0x81302c
    sw $t4 16($v0) # (4, 0)
    li $t4 0xa43234
    sw $t4 20($v0) # (5, 0)
    li $t4 0x862a2d
    sw $t4 24($v0) # (6, 0)
    li $t4 0x150009
    sw $t4 28($v0) # (7, 0)
    li $t4 0x000100
    sw $t4 32($v0) # (8, 0)
    li $t4 0x030401
    sw $t4 516($v0) # (1, 1)
    li $t4 0x000201
    sw $t4 520($v0) # (2, 1)
    li $t4 0x8c5131
    sw $t4 524($v0) # (3, 1)
    li $t4 0xf49951
    sw $t4 528($v0) # (4, 1)
    li $t4 0xe37449
    sw $t4 532($v0) # (5, 1)
    li $t4 0xf39b50
    sw $t4 536($v0) # (6, 1)
    li $t4 0xaf753b
    sw $t4 540($v0) # (7, 1)
    li $t4 0x040303
    sw $t4 544($v0) # (8, 1)
    li $t4 0x020201
    sw $t4 548($v0) # (9, 1)
    li $t4 0x040204
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x1c0003
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xeb9250
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xd6964b
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xb27743
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xc2784c
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xc85c46
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x310d0a
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x211a28
    sw $t4 1536($v0) # (0, 3)
    li $t4 0xa3a2c2
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x7e335b
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xba2e37
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xb74c55
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x978da2
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xbb8278
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x840445
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x3d223a
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x1b1623
    sw $t4 2048($v0) # (0, 4)
    li $t4 0xdcd1fd
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xe5e4ff
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x992f6f
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x9f4b77
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xa597ac
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xaf7c9f
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xa4407e
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x52466c
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x0b0a0f
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x928caa
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xcea7d1
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x6155a4
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x3951b2
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x90528c
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x79457c
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x4f4aac
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x2c1c3c
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x040000
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x980b36
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x773767
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x323099
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x935c98
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x721e5c
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x540a4b
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x311825
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x000001
    sw $t4 3584($v0) # (0, 7)
    sw $t4 4096($v0) # (0, 8)
    sw $t4 4612($v0) # (1, 9)
    sw $t4 5148($v0) # (7, 10)
    sw $t4 5644($v0) # (3, 11)
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x0a0205
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x33021e
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x111380
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x565fb7
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xfef2ff
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x8a96de
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x190223
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x0b0000
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x000101
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x00020f
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x072a91
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x1e65d1
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x8aa7eb
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x308bef
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x001947
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x010101
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x000103
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x010000
    sw $t4 4616($v0) # (2, 9)
    sw $t4 4636($v0) # (7, 9)
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x020008
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x000823
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x343578
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x171637
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x010102
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x0f0400
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x0a0300
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x000002
    sw $t4 5648($v0) # (4, 11)
    sw $t4 5652($v0) # (5, 11)
    jr $ra
draw_doll_01_07: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 1028($v0) # (1, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 2048($v0) # (0, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4128($v0) # (8, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5136($v0) # (4, 10)
    sw $0 5140($v0) # (5, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010000
    sw $t4 8($v0) # (2, 0)
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x040002
    sw $t4 16($v0) # (4, 0)
    li $t4 0x260d0d
    sw $t4 20($v0) # (5, 0)
    li $t4 0x220a0b
    sw $t4 24($v0) # (6, 0)
    li $t4 0x000100
    sw $t4 32($v0) # (8, 0)
    li $t4 0x030203
    sw $t4 516($v0) # (1, 1)
    li $t4 0x010201
    sw $t4 520($v0) # (2, 1)
    li $t4 0x1a020a
    sw $t4 524($v0) # (3, 1)
    li $t4 0xb45d3d
    sw $t4 528($v0) # (4, 1)
    li $t4 0xdd5a48
    sw $t4 532($v0) # (5, 1)
    li $t4 0xdb6c46
    sw $t4 536($v0) # (6, 1)
    li $t4 0x7e3e2d
    sw $t4 540($v0) # (7, 1)
    li $t4 0x010101
    sw $t4 548($v0) # (9, 1)
    li $t4 0xb15540
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xf5b750
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xbf653c
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xc87347
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xf2a450
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x4b2d1a
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x020001
    sw $t4 1536($v0) # (0, 3)
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x2c2d3b
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x5b1c36
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xcc5139
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xd17b52
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x6d5077
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xbe8577
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xae3a4a
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x6d2420
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x000101
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x726c8a
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xddbde7
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x9b255b
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xab2138
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xb39094
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xd1ad98
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x941c50
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x6d4579
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x030607
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x574f69
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xf0ffff
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x9f679f
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x623f8f
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x7d73b5
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x8e6a9e
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x9e6caf
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x593669
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x040809
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x3a1328
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xb84a87
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xb04c58
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x4e4f9e
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x4c2b79
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x79123f
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x3c2285
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x3a285d
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x040101
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x1f000a
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x46000e
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x44064c
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x2b298d
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xaf9bd2
    sw $t4 3604($v0) # (5, 7)
    li $t4 0xbc9fcc
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x6a1041
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x350b14
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x010200
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x000200
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x000300
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x04268e
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x116be4
    sw $t4 4112($v0) # (4, 8)
    li $t4 0xa0a7e5
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xb0c6fb
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x17438b
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x000203
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x000001
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x050a29
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x031348
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x01053b
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x544baf
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x202454
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x010001
    sw $t4 4640($v0) # (8, 9)
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x010103
    sw $t4 4644($v0) # (9, 9)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x35212b
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x25131a
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x000002
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x000103
    sw $t4 5648($v0) # (4, 11)
    jr $ra
draw_doll_01_08: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 2048($v0) # (0, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5140($v0) # (5, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x020100
    sw $t4 12($v0) # (3, 0)
    li $t4 0x000200
    sw $t4 32($v0) # (8, 0)
    sw $t4 3072($v0) # (0, 6)
    li $t4 0x020101
    sw $t4 520($v0) # (2, 1)
    sw $t4 5664($v0) # (8, 11)
    li $t4 0x26050e
    sw $t4 528($v0) # (4, 1)
    li $t4 0x6f2127
    sw $t4 532($v0) # (5, 1)
    li $t4 0x843a2a
    sw $t4 536($v0) # (6, 1)
    li $t4 0x571e1e
    sw $t4 540($v0) # (7, 1)
    li $t4 0x010000
    sw $t4 1028($v0) # (1, 2)
    sw $t4 5128($v0) # (2, 10)
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x5d1c21
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xe1804a
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xfebf53
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xf4964d
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xf6a751
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x936134
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x080304
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x020001
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x030405
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x390e25
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xb42037
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xf3b54f
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xbf894e
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x975552
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xc2544b
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xc3583f
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x190208
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x0f0d14
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xc1aadc
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xab4c7c
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xb13237
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xb0656d
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xb6c1b4
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xbc736d
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x730f45
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x0c0b11
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x010101
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x030408
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xb8bce0
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xdfe1ff
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x870d58
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x934c79
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xa492a2
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xb86886
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x924c8d
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x1d2330
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x23020d
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xbc6aa1
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xb2689b
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x9b3e59
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x8085cb
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x966098
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x6b4c98
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x4a3172
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x0f0d12
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x170008
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x750027
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x95002c
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x631953
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x2f2c90
    sw $t4 3604($v0) # (5, 7)
    li $t4 0xa34c7f
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x7c1c5c
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x4a1e46
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x020000
    sw $t4 3620($v0) # (9, 7)
    sw $t4 5136($v0) # (4, 10)
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x000001
    sw $t4 4100($v0) # (1, 8)
    sw $t4 4612($v0) # (1, 9)
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x100308
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x350737
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x0431b0
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x4872d0
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x7c98e3
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x758edc
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x42253c
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x000101
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x00030f
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x03185a
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x26257e
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x7468cb
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x1c3482
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x000103
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x010102
    sw $t4 4644($v0) # (9, 9)
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x5a446d
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x5d406d
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x010103
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x010100
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x050100
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x120904
    sw $t4 5660($v0) # (7, 11)
    jr $ra
draw_doll_01_09: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 532($v0) # (5, 1)
    sw $0 536($v0) # (6, 1)
    sw $0 540($v0) # (7, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2564($v0) # (1, 5)
    sw $0 3076($v0) # (1, 6)
    sw $0 4096($v0) # (0, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 16($v0) # (4, 0)
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x030201
    sw $t4 20($v0) # (5, 0)
    sw $t4 28($v0) # (7, 0)
    li $t4 0x020101
    sw $t4 24($v0) # (6, 0)
    sw $t4 32($v0) # (8, 0)
    sw $t4 548($v0) # (9, 1)
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x010100
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x1b060a
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x8a3330
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xa54836
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x994c32
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x21040d
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x010200
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x020003
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xa34c38
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xffd856
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xea9148
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xf0a24e
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xd48a48
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x351e16
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x030101
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x030307
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x3f0210
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xe98b4d
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xd49852
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x82535e
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xb95a58
    sw $t4 2076($v0) # (7, 4)
    li $t4 0xbd4243
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x701522
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x020202
    sw $t4 2560($v0) # (0, 5)
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x8b86a8
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xb16390
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xa92337
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xb8474d
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xb2afac
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xcea589
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x850c43
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x4d274c
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x030303
    sw $t4 3072($v0) # (0, 6)
    li $t4 0x82809f
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xeef8ff
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x8d2d75
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x87326f
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x907ba2
    sw $t4 3096($v0) # (6, 6)
    li $t4 0xaf86a5
    sw $t4 3100($v0) # (7, 6)
    li $t4 0xa54581
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x675080
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x040002
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x914f7c
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xd2a2cb
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xa05f79
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x4564bd
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x713e7f
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x7f376b
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x4946a7
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x37234f
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x110007
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x2b000c
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x5d001d
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x7e1c48
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x392585
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x8c61a2
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x873c75
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x5e1156
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x3c1c2d
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x000200
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x03030a
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x0e2699
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x005cd5
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x8ca4ea
    sw $t4 4632($v0) # (6, 9)
    li $t4 0xf1f3ff
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x755e7a
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x050000
    sw $t4 4644($v0) # (9, 9)
    li $t4 0x000001
    sw $t4 5124($v0) # (1, 10)
    li $t4 0x010006
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x092470
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x06439e
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x24419a
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x6861b1
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x080e22
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x000101
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x010000
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x180809
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x200f13
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x020000
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_01_10: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 1036($v0) # (3, 2)
    sw $0 1044($v0) # (5, 2)
    sw $0 1048($v0) # (6, 2)
    sw $0 1052($v0) # (7, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1552($v0) # (4, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2056($v0) # (2, 4)
    sw $0 2060($v0) # (3, 4)
    sw $0 2564($v0) # (1, 5)
    sw $0 3076($v0) # (1, 6)
    sw $0 3588($v0) # (1, 7)
    sw $0 4100($v0) # (1, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5644($v0) # (3, 11)
    li $t4 0x030101
    sw $t4 532($v0) # (5, 1)
    sw $t4 536($v0) # (6, 1)
    sw $t4 540($v0) # (7, 1)
    li $t4 0x020101
    sw $t4 544($v0) # (8, 1)
    li $t4 0x010100
    sw $t4 1040($v0) # (4, 2)
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x000001
    sw $t4 1544($v0) # (2, 3)
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x020202
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x421817
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x862c2d
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x8b322c
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x2c0511
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x371616
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xea964f
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xea5d48
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xe66748
    sw $t4 2076($v0) # (7, 4)
    li $t4 0xdd884a
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x2a1711
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x0e0c0f
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x0e0b15
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x753122
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xf7aa56
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x864945
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x984043
    sw $t4 2588($v0) # (7, 5)
    li $t4 0xce6f49
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x854927
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x020203
    sw $t4 3072($v0) # (0, 6)
    li $t4 0x2a2533
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xb9b2dc
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x9f3a54
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xcb4b3e
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x9f8091
    sw $t4 3096($v0) # (6, 6)
    li $t4 0xcdb096
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x93244b
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x6f284d
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x020102
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x15111a
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xe1e1ff
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xb87cb6
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x860743
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x9a789e
    sw $t4 3608($v0) # (6, 7)
    li $t4 0xa98ca1
    sw $t4 3612($v0) # (7, 7)
    li $t4 0xaf4c7e
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x9e65ae
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x010001
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x09080c
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x817c96
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xbe6e8e
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x555caa
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x6f70b8
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x833969
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x6a63b5
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x3d286a
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x020000
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x160000
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x9a1539
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x4d2d7b
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x5b3f91
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x8c3b71
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x4f004c
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x4d224c
    sw $t4 4644($v0) # (9, 9)
    li $t4 0x000102
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x0e0407
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x1c0b5b
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x0036b1
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x6282d6
    sw $t4 5144($v0) # (6, 10)
    li $t4 0xf1ecff
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x987eaa
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x190000
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x000101
    sw $t4 5640($v0) # (2, 11)
    sw $t4 5668($v0) # (9, 11)
    li $t4 0x080e50
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x074bbc
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x1f76df
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x749de4
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x3d4b7e
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_01_11: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 532($v0) # (5, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1548($v0) # (3, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 2564($v0) # (1, 5)
    sw $0 2568($v0) # (2, 5)
    sw $0 2572($v0) # (3, 5)
    sw $0 3588($v0) # (1, 7)
    sw $0 4100($v0) # (1, 8)
    sw $0 4612($v0) # (1, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x020101
    sw $t4 16($v0) # (4, 0)
    sw $t4 32($v0) # (8, 0)
    li $t4 0x000100
    sw $t4 20($v0) # (5, 0)
    li $t4 0x150c07
    sw $t4 536($v0) # (6, 1)
    li $t4 0x0a0403
    sw $t4 540($v0) # (7, 1)
    li $t4 0x010100
    sw $t4 548($v0) # (9, 1)
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x020000
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x21090c
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xb4543d
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xcd4042
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xc74f42
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x50221d
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x030301
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xa06038
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xf7af51
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xdb7c41
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xd57545
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xd98d47
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x150809
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x020402
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x030303
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xa85539
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xd07250
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x854f56
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xb2695d
    sw $t4 2076($v0) # (7, 4)
    li $t4 0xa02c41
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x27080c
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x841436
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xbd404e
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xa19aa5
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xcd9d8f
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x7c043c
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x0e0409
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x010101
    sw $t4 3072($v0) # (0, 6)
    sw $t4 3076($v0) # (1, 6)
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x0f0e14
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x757187
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x84286e
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x8764a8
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x9075a7
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x9c78ac
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x9d3e82
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x59406d
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x020303
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x8682a4
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xe8c7f4
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x9d4e73
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x4e6ac1
    sw $t4 3604($v0) # (5, 7)
    li $t4 0xa05186
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x6f205a
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x37298e
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x3e2a57
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x030304
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x696483
    sw $t4 4104($v0) # (2, 8)
    li $t4 0xd5bae1
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x741c41
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x302f90
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x7e5da6
    sw $t4 4120($v0) # (6, 8)
    li $t4 0xaa74af
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x7d2357
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x260f13
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x020202
    sw $t4 4608($v0) # (0, 9)
    li $t4 0x282632
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x332e38
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x060042
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x0040c1
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x4e78d6
    sw $t4 4632($v0) # (6, 9)
    li $t4 0xfcfaff
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x717ba1
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x05051e
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x0a2980
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x0f5ab7
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x5074d4
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x0a2959
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x020102
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x020203
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x100509
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x38223f
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x090000
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_01_12: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1036($v0) # (3, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2060($v0) # (3, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 2564($v0) # (1, 5)
    sw $0 4096($v0) # (0, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 4620($v0) # (3, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010100
    sw $t4 524($v0) # (3, 1)
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x54201d
    sw $t4 532($v0) # (5, 1)
    li $t4 0x7f2929
    sw $t4 536($v0) # (6, 1)
    li $t4 0x6f2624
    sw $t4 540($v0) # (7, 1)
    li $t4 0x0e0006
    sw $t4 544($v0) # (8, 1)
    li $t4 0x000100
    sw $t4 548($v0) # (9, 1)
    li $t4 0x030201
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x682f24
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xf78f52
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xe8614b
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xea764e
    sw $t4 1052($v0) # (7, 2)
    li $t4 0xb36e3d
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x090104
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x020401
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x020102
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xb25f3c
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xdd954d
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xa95b38
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xbc6f43
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xca7e46
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x18030a
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x030200
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x6f2924
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xce5a51
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x857891
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xc49483
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x751534
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x000001
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x030003
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x212029
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x5d0c28
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xb04d7a
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x97859a
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xb17b96
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x8d1953
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x2b2236
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x010101
    sw $t4 3072($v0) # (0, 6)
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x09070c
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xa59ec0
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xdccdf5
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x844284
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x6787da
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x8f5289
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x633d83
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x7b3e87
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x6b3d68
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x0e0b12
    sw $t4 3588($v0) # (1, 7)
    li $t4 0xd4c7f8
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xd9cdf6
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xae606e
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x483e99
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x85387d
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x6d0a4d
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x8e2d4d
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x290b18
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x08070c
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x7f7697
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x3c3943
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x28002d
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x0a36ac
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x9fa8e3
    sw $t4 4120($v0) # (6, 8)
    li $t4 0xd3c7f3
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x4c063b
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x030000
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x060b42
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x0064e8
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x669cf0
    sw $t4 4632($v0) # (6, 9)
    li $t4 0xb7aee8
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x000f31
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x000101
    sw $t4 4644($v0) # (9, 9)
    li $t4 0x030304
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x020203
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x030108
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x030b2b
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x212a5f
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x372866
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x020205
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x0d0300
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x160b02
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x020100
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_01_13: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1036($v0) # (3, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2056($v0) # (2, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4104($v0) # (2, 8)
    sw $0 4108($v0) # (3, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010501
    sw $t4 24($v0) # (6, 0)
    li $t4 0x010000
    sw $t4 36($v0) # (9, 0)
    sw $t4 520($v0) # (2, 1)
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x010100
    sw $t4 524($v0) # (3, 1)
    sw $t4 3072($v0) # (0, 6)
    li $t4 0x110306
    sw $t4 528($v0) # (4, 1)
    li $t4 0x8f3d31
    sw $t4 532($v0) # (5, 1)
    li $t4 0xb23439
    sw $t4 536($v0) # (6, 1)
    li $t4 0xa53936
    sw $t4 540($v0) # (7, 1)
    li $t4 0x310c13
    sw $t4 544($v0) # (8, 1)
    li $t4 0x000100
    sw $t4 548($v0) # (9, 1)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x030301
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x89482f
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xfda452
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xe57746
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xf1984d
    sw $t4 1052($v0) # (7, 2)
    li $t4 0xda9e48
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x0d0206
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x030500
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x040303
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xae623c
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xda8c4e
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x925645
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xbf8250
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xc87c4a
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x270410
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x050000
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xb6383a
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xbe494c
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x9890a4
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xc1978a
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x900540
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x430014
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x010101
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x060409
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x9c98b5
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x9380a0
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x7f043a
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x9d689e
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x8c6f95
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x926b9a
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x9b1d61
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x5b264d
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x0d0a13
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xd5ccf7
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xfdf1ff
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x975c8e
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x5a80d4
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x904078
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x5b1e63
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x743e7b
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x5b2e51
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x0a080e
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x998fb5
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xa49eb8
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x913e53
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x452e8b
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x90579f
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x832d6e
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x921c3b
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x19030c
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x090753
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x0d53ce
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xbac1f2
    sw $t4 4120($v0) # (6, 8)
    li $t4 0xe3e3ff
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x2c1259
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x010203
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x020302
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x0a1961
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x0367d8
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x2c7bdc
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x506ecd
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x00123c
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x000001
    sw $t4 4644($v0) # (9, 9)
    li $t4 0x020003
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x1f1932
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x2e2044
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x030000
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x010001
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x040000
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x080200
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x010102
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_01_14: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 532($v0) # (5, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1544($v0) # (2, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 3592($v0) # (2, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x020101
    sw $t4 16($v0) # (4, 0)
    sw $t4 32($v0) # (8, 0)
    li $t4 0x000100
    sw $t4 20($v0) # (5, 0)
    sw $t4 3588($v0) # (1, 7)
    sw $t4 4616($v0) # (2, 9)
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x010000
    sw $t4 524($v0) # (3, 1)
    li $t4 0x130907
    sw $t4 536($v0) # (6, 1)
    li $t4 0x080003
    sw $t4 540($v0) # (7, 1)
    li $t4 0x010100
    sw $t4 548($v0) # (9, 1)
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x040302
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x000202
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x21070c
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xb45c3e
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xd24d43
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xcd6943
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x4f201d
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x010101
    sw $t4 1540($v0) # (1, 3)
    sw $t4 3072($v0) # (0, 6)
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x070000
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xcf7f45
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xf4b150
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xd36144
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xd47e48
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xd99349
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x16080b
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x0c080e
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x9390b5
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x8c4b64
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xde7640
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xbb5b4b
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x8e5b64
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xb86a65
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x9d283f
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x200303
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x0d0a12
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xd6cefa
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xd3bdf0
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x920039
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xb7444e
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xa7abab
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xc7a08f
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x911350
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x634470
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x060409
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x9c96b4
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xd3bae6
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x78276f
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x8a66ab
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x96749e
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x9c749d
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x9b5398
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x533862
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x8f365c
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x5f6cba
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x2c288b
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x78357b
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x6a0944
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x4f2e7d
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x3b2336
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x010201
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x300e0c
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x6a0f4d
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x56479f
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xbda3d7
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x9968af
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x62062d
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x2e100e
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x000001
    sw $t4 4612($v0) # (1, 9)
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x04000b
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x0a1e91
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x3d67cc
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x6aadff
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x55abff
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x08297f
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x020000
    sw $t4 4644($v0) # (9, 9)
    li $t4 0x000106
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x0b1258
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x013a9b
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x0061c1
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x0055b3
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x061749
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x040000
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x150200
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x140000
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x030000
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_01_15: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1544($v0) # (2, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4104($v0) # (2, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5136($v0) # (4, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x020100
    sw $t4 8($v0) # (2, 0)
    li $t4 0x3e1916
    sw $t4 16($v0) # (4, 0)
    li $t4 0x9a3333
    sw $t4 20($v0) # (5, 0)
    li $t4 0xa63934
    sw $t4 24($v0) # (6, 0)
    li $t4 0x53151e
    sw $t4 28($v0) # (7, 0)
    li $t4 0x010001
    sw $t4 36($v0) # (9, 0)
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x010000
    sw $t4 516($v0) # (1, 1)
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x010100
    sw $t4 520($v0) # (2, 1)
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x20050c
    sw $t4 524($v0) # (3, 1)
    li $t4 0xdb854a
    sw $t4 528($v0) # (4, 1)
    li $t4 0xec754c
    sw $t4 532($v0) # (5, 1)
    li $t4 0xdb6448
    sw $t4 536($v0) # (6, 1)
    li $t4 0xeb934e
    sw $t4 540($v0) # (7, 1)
    li $t4 0x512b1d
    sw $t4 544($v0) # (8, 1)
    li $t4 0x030101
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x020202
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x4a151b
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xf09d52
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xab6241
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xa65e3f
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xd5844f
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x653224
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x000001
    sw $t4 1060($v0) # (9, 2)
    sw $t4 5648($v0) # (4, 11)
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x120001
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xc6483f
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x9b6378
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xaea79e
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xad495c
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x220004
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x2b2933
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x3c2034
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x942357
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x9d779f
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x9c87a1
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xac457d
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x612350
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x0b1014
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x605871
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xe5e1ff
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xc688ba
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x5556a5
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x8074c5
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x7a2861
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x695098
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x83356e
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x171a25
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x756a8b
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xeee9ff
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xb47e91
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x6c346c
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x5b45a1
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x852865
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x842054
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x601b2a
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x000101
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x413a4f
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x545463
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x15000b
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x0f1a86
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x3e72d3
    sw $t4 3604($v0) # (5, 7)
    li $t4 0xf2f0ff
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x815b9d
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x160001
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x020301
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x000107
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x0638a0
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x117bee
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xaea9e7
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x3d4a86
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x000100
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x030203
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x020203
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x030304
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x03000c
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x060e27
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x3c2f6d
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x10091a
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x010101
    sw $t4 4644($v0) # (9, 9)
    li $t4 0x020000
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x0f0600
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x080400
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x000002
    sw $t4 5652($v0) # (5, 11)
    jr $ra
draw_doll_01_16: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 2052($v0) # (1, 4)
    sw $0 2080($v0) # (8, 4)
    sw $0 2564($v0) # (1, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3076($v0) # (1, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 3616($v0) # (8, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4104($v0) # (2, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5140($v0) # (5, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010000
    sw $t4 4($v0) # (1, 0)
    sw $t4 3592($v0) # (2, 7)
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x010100
    sw $t4 8($v0) # (2, 0)
    li $t4 0x0e0005
    sw $t4 12($v0) # (3, 0)
    li $t4 0xae7a3b
    sw $t4 16($v0) # (4, 0)
    li $t4 0xe8974c
    sw $t4 20($v0) # (5, 0)
    li $t4 0xbf2841
    sw $t4 24($v0) # (6, 0)
    li $t4 0x642624
    sw $t4 28($v0) # (7, 0)
    li $t4 0x010101
    sw $t4 36($v0) # (9, 0)
    li $t4 0x030201
    sw $t4 516($v0) # (1, 1)
    li $t4 0x010001
    sw $t4 520($v0) # (2, 1)
    sw $t4 1536($v0) # (0, 3)
    sw $t4 4644($v0) # (9, 9)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x692b25
    sw $t4 524($v0) # (3, 1)
    li $t4 0xffff5a
    sw $t4 528($v0) # (4, 1)
    li $t4 0xf7ea51
    sw $t4 532($v0) # (5, 1)
    li $t4 0xdf8949
    sw $t4 536($v0) # (6, 1)
    li $t4 0xe99f4e
    sw $t4 540($v0) # (7, 1)
    li $t4 0x2d1710
    sw $t4 544($v0) # (8, 1)
    li $t4 0x040301
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x935e31
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xfee158
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xe0b44e
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xb75849
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xc33f4a
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x3c1416
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x000200
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x0e0915
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xc4774a
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xe17748
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xd29343
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xd67969
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x8a2b3e
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x070002
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x020201
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x030304
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x514368
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xcd5968
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xcc6335
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xc28d77
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xb088d0
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x6e6083
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x030203
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x020001
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x230c18
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xa22146
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xb53533
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xb78ebb
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xa87cbc
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x4f3b92
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x2f2441
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x030100
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x0b0002
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x76002e
    sw $t4 3084($v0) # (3, 6)
    li $t4 0xa81736
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x644c93
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x523da2
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x5a0b35
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x2f191a
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x030102
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x000002
    sw $t4 3588($v0) # (1, 7)
    sw $t4 4100($v0) # (1, 8)
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x190c47
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x28319f
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x004cbe
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x4382e4
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x48446e
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x020304
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x040940
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x031779
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x3849a5
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x3e41ae
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x031050
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x020101
    sw $t4 4128($v0) # (8, 8)
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x020000
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x23121c
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x462a45
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x060000
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x000100
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x000102
    sw $t4 5656($v0) # (6, 11)
    jr $ra
draw_doll_01_17: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 516($v0) # (1, 1)
    sw $0 1028($v0) # (1, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2056($v0) # (2, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 3592($v0) # (2, 7)
    sw $0 3616($v0) # (8, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4620($v0) # (3, 9)
    sw $0 4636($v0) # (7, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5140($v0) # (5, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 4($v0) # (1, 0)
    sw $t4 512($v0) # (0, 1)
    sw $t4 1540($v0) # (1, 3)
    sw $t4 2564($v0) # (1, 5)
    sw $t4 4128($v0) # (8, 8)
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x55221f
    sw $t4 12($v0) # (3, 0)
    li $t4 0xba243f
    sw $t4 16($v0) # (4, 0)
    li $t4 0xe4894b
    sw $t4 20($v0) # (5, 0)
    li $t4 0xbd8b40
    sw $t4 24($v0) # (6, 0)
    li $t4 0x170209
    sw $t4 28($v0) # (7, 0)
    li $t4 0x010100
    sw $t4 32($v0) # (8, 0)
    sw $t4 2596($v0) # (9, 5)
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x010000
    sw $t4 36($v0) # (9, 0)
    sw $t4 3072($v0) # (0, 6)
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x1b0b0a
    sw $t4 520($v0) # (2, 1)
    li $t4 0xdd974a
    sw $t4 524($v0) # (3, 1)
    li $t4 0xe28c4a
    sw $t4 528($v0) # (4, 1)
    li $t4 0xf3dd52
    sw $t4 532($v0) # (5, 1)
    li $t4 0xffff5c
    sw $t4 536($v0) # (6, 1)
    li $t4 0x84432e
    sw $t4 540($v0) # (7, 1)
    li $t4 0x000001
    sw $t4 544($v0) # (8, 1)
    sw $t4 4132($v0) # (9, 8)
    sw $t4 5132($v0) # (3, 10)
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x040301
    sw $t4 548($v0) # (9, 1)
    li $t4 0x020101
    sw $t4 1024($v0) # (0, 2)
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x2a0e0f
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xc03f49
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xb24645
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xdb9840
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xfbf351
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xce8443
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x040000
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x010300
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x040002
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x762035
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xd36b5e
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xca9984
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xe3b767
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xce604c
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x180d1c
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x000200
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x030203
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x574c79
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xd08789
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xccc9c9
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xb56883
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xd3726b
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x2c2846
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x000002
    sw $t4 2560($v0) # (0, 5)
    sw $t4 4100($v0) # (1, 8)
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x2f2035
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x374599
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xb55f5c
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xa14c6b
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xc2444b
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x942d3b
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x000003
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x010001
    sw $t4 3076($v0) # (1, 6)
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x2e1718
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x2f0316
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x43075f
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x381974
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x5a1c63
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x350027
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x000103
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x100d46
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x0674f0
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x005dcb
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x042da7
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x070f54
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x000102
    sw $t4 3620($v0) # (9, 7)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x030c34
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x023b93
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x4054bc
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x292685
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x050937
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x0a0000
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x4b2945
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x1c1019
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x010302
    sw $t4 5136($v0) # (4, 10)
    jr $ra
draw_doll_01_18: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 516($v0) # (1, 1)
    sw $0 1056($v0) # (8, 2)
    sw $0 2084($v0) # (9, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 2596($v0) # (9, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 3592($v0) # (2, 7)
    sw $0 3616($v0) # (8, 7)
    sw $0 4608($v0) # (0, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010000
    sw $t4 4($v0) # (1, 0)
    sw $t4 3108($v0) # (9, 6)
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x450d19
    sw $t4 12($v0) # (3, 0)
    li $t4 0xa02f32
    sw $t4 16($v0) # (4, 0)
    li $t4 0xa55737
    sw $t4 20($v0) # (5, 0)
    li $t4 0x50291b
    sw $t4 24($v0) # (6, 0)
    li $t4 0x010100
    sw $t4 32($v0) # (8, 0)
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x030201
    sw $t4 512($v0) # (0, 1)
    li $t4 0x432918
    sw $t4 520($v0) # (2, 1)
    li $t4 0xde7b4b
    sw $t4 524($v0) # (3, 1)
    li $t4 0xe66f4a
    sw $t4 528($v0) # (4, 1)
    li $t4 0xe99d4e
    sw $t4 532($v0) # (5, 1)
    li $t4 0xf7cd53
    sw $t4 536($v0) # (6, 1)
    li $t4 0x2d0a12
    sw $t4 540($v0) # (7, 1)
    li $t4 0x020302
    sw $t4 544($v0) # (8, 1)
    li $t4 0x020101
    sw $t4 548($v0) # (9, 1)
    li $t4 0x020201
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x020001
    sw $t4 1028($v0) # (1, 2)
    sw $t4 1536($v0) # (0, 3)
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x883b2e
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xd7744c
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xab6f40
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xbb6f42
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xffe958
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x863b23
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x040301
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x000100
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x2f0218
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xcf5b5f
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x8b7a9b
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xc1854a
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xe19747
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xc47e9b
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x4a485e
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x000200
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x301020
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xab427a
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xb98592
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xc96947
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xbd5349
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xd4c5f1
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x8a83a9
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x000201
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x050000
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x6c4485
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x8e265a
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x7f3166
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x8e1843
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xc88db7
    sw $t4 2588($v0) # (7, 5)
    li $t4 0xabaace
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x000001
    sw $t4 3076($v0) # (1, 6)
    sw $t4 4096($v0) # (0, 8)
    sw $t4 5648($v0) # (4, 11)
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x060002
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x500542
    sw $t4 3084($v0) # (3, 6)
    li $t4 0xa3498d
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x603f7b
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x511863
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x7d0536
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x100f16
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x030303
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x73598a
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x7384dc
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x0638a5
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x0c30a6
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x240942
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x000102
    sw $t4 3620($v0) # (9, 7)
    sw $t4 4104($v0) # (2, 8)
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x000101
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x132f80
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x0273ea
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x0b4cbe
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x122695
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x000a31
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x010101
    sw $t4 4128($v0) # (8, 8)
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x0a0910
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x4b417c
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x141131
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x020110
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x020000
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x050100
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x100400
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x000002
    sw $t4 5652($v0) # (5, 11)
    jr $ra
draw_doll_01_19: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 1056($v0) # (8, 2)
    sw $0 3072($v0) # (0, 6)
    sw $0 4124($v0) # (7, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 4($v0) # (1, 0)
    sw $t4 544($v0) # (8, 1)
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x1c060a
    sw $t4 12($v0) # (3, 0)
    li $t4 0x5e1f20
    sw $t4 16($v0) # (4, 0)
    li $t4 0x64251f
    sw $t4 20($v0) # (5, 0)
    li $t4 0x150008
    sw $t4 24($v0) # (6, 0)
    li $t4 0x010000
    sw $t4 32($v0) # (8, 0)
    sw $t4 512($v0) # (0, 1)
    sw $t4 2084($v0) # (9, 4)
    sw $t4 3620($v0) # (9, 7)
    sw $t4 4100($v0) # (1, 8)
    sw $t4 4636($v0) # (7, 9)
    sw $t4 5124($v0) # (1, 10)
    li $t4 0x000100
    sw $t4 516($v0) # (1, 1)
    li $t4 0x160209
    sw $t4 520($v0) # (2, 1)
    li $t4 0xcb7a45
    sw $t4 524($v0) # (3, 1)
    li $t4 0xe9624d
    sw $t4 528($v0) # (4, 1)
    li $t4 0xe25d4b
    sw $t4 532($v0) # (5, 1)
    li $t4 0xc87144
    sw $t4 536($v0) # (6, 1)
    li $t4 0x21110d
    sw $t4 540($v0) # (7, 1)
    li $t4 0x020101
    sw $t4 548($v0) # (9, 1)
    li $t4 0x040504
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x050005
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x9a4b33
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xf4bd51
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xc3793a
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xbb6e3b
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xe9a74c
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x603b1e
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x040301
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x1a1721
    sw $t4 1536($v0) # (0, 3)
    li $t4 0xb3a8d0
    sw $t4 1540($v0) # (1, 3)
    li $t4 0xbf6a71
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xbd4843
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x84697e
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xc08f8a
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x9d5f58
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x955062
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x0a0e17
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x010100
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x1a1320
    sw $t4 2048($v0) # (0, 4)
    li $t4 0xd9e1ff
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xac5394
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xa1143f
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xad94a3
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xbd989a
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xc75c4e
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x913f69
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x0b0f16
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x040305
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x7f3b5b
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x81357b
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x4d55ad
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x8f639d
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x874e80
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x815cac
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x4d2463
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x07090a
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x010001
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x290003
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x95517a
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x2c1e7f
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x873271
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x882f60
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x451162
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x582950
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x0b0400
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x000001
    sw $t4 3108($v0) # (9, 6)
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x000102
    sw $t4 3584($v0) # (0, 7)
    sw $t4 4096($v0) # (0, 8)
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x010402
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x420134
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x3b389f
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xccbee7
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xa9a1e4
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x300a4e
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x330107
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x010202
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x00093d
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x173db2
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x819ee4
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x35a3ff
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x0044a7
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x000101
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x030106
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x272668
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x203b94
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x002a60
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x030f24
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x160c07
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x220d06
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x030000
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x000204
    sw $t4 5652($v0) # (5, 11)
    jr $ra
draw_doll_01_20: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 520($v0) # (2, 1)
    sw $0 536($v0) # (6, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1568($v0) # (8, 3)
    sw $0 3072($v0) # (0, 6)
    sw $0 3616($v0) # (8, 7)
    sw $0 3620($v0) # (9, 7)
    sw $0 4128($v0) # (8, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4644($v0) # (9, 9)
    sw $0 5124($v0) # (1, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x020101
    sw $t4 8($v0) # (2, 0)
    li $t4 0x010200
    sw $t4 24($v0) # (6, 0)
    li $t4 0x020203
    sw $t4 512($v0) # (0, 1)
    li $t4 0x030203
    sw $t4 516($v0) # (1, 1)
    li $t4 0x1d070a
    sw $t4 524($v0) # (3, 1)
    li $t4 0x451b17
    sw $t4 528($v0) # (4, 1)
    li $t4 0x391512
    sw $t4 532($v0) # (5, 1)
    li $t4 0x000100
    sw $t4 540($v0) # (7, 1)
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x3a1716
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xdb784a
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xe1484a
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xe25f4b
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x934f34
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x050001
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x010100
    sw $t4 1056($v0) # (8, 2)
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x3c3848
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x332941
    sw $t4 1540($v0) # (1, 3)
    li $t4 0xa45a34
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xf2b852
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xd18a3c
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xbd5d3d
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xffd253
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x532e1f
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x040201
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x9f96bc
    sw $t4 2048($v0) # (0, 4)
    li $t4 0xe4cfff
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xc47c58
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xd06a49
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x8c6f77
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xb17671
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xaa4247
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x7d4541
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x000002
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x030200
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x6c617f
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xc5ccee
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xb14b6d
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xab334c
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xa495a5
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xc69e9e
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xb0254a
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x732640
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x000102
    sw $t4 2592($v0) # (8, 5)
    sw $t4 4608($v0) # (0, 9)
    li $t4 0x030001
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x622f4e
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x72267e
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x6e6cba
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x966ea6
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xa387b6
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x7c386f
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x2e0616
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x020001
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x050204
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x620a1e
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x7c3f79
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x31298c
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x913d74
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x7a194e
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x402c55
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x000201
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x140705
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x4f0b53
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x393ea3
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xc2aee0
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x967cc4
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x4f1439
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x090301
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x020000
    sw $t4 4612($v0) # (1, 9)
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x00116b
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x3b59c2
    sw $t4 4620($v0) # (3, 9)
    li $t4 0xd7d2fd
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x5f91fc
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x00165f
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x000103
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x000001
    sw $t4 5120($v0) # (0, 10)
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x0a081c
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x273186
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x1b3d8a
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x013176
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x030a19
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x080501
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x271414
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x130400
    sw $t4 5648($v0) # (4, 11)
    jr $ra
draw_doll_01_21: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 532($v0) # (5, 1)
    sw $0 540($v0) # (7, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1028($v0) # (1, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 1036($v0) # (3, 2)
    sw $0 1048($v0) # (6, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2052($v0) # (1, 4)
    sw $0 2080($v0) # (8, 4)
    sw $0 2592($v0) # (8, 5)
    sw $0 3616($v0) # (8, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4128($v0) # (8, 8)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5156($v0) # (9, 10)
    sw $0 5660($v0) # (7, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010000
    sw $t4 16($v0) # (4, 0)
    sw $t4 520($v0) # (2, 1)
    sw $t4 1052($v0) # (7, 2)
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x020201
    sw $t4 524($v0) # (3, 1)
    li $t4 0x020101
    sw $t4 536($v0) # (6, 1)
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x020202
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x050602
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x000100
    sw $t4 1044($v0) # (5, 2)
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x020301
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x110207
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x954233
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xbc383d
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xb5433b
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x431819
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x000001
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x010101
    sw $t4 1568($v0) # (8, 3)
    sw $t4 2084($v0) # (9, 4)
    sw $t4 3108($v0) # (9, 6)
    sw $t4 4608($v0) # (0, 9)
    li $t4 0x2f2936
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x84472a
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xfcb055
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xe27b45
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xd97547
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xde9149
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x110501
    sw $t4 2076($v0) # (7, 4)
    li $t4 0xcfc3ef
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x9287b4
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xaf614a
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xd57c4b
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x8d4f4b
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xaf6454
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xb43e44
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x512a3c
    sw $t4 2588($v0) # (7, 5)
    li $t4 0xbcb0d9
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xe5e4ff
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xa83666
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xb8373c
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x9c92a4
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xc7a08c
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x7e1054
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x5f406f
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x19171e
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x92658f
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x880e53
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x8f5d99
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x9b83ab
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xa988b0
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x774b84
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x433655
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x020102
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x430616
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x594e9d
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x414aa7
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x974981
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x83345e
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x42242a
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x070000
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x2a1914
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x7e235a
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x31248a
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x9b74b3
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x8f4a8d
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x4d0021
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x060203
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x000101
    sw $t4 5120($v0) # (0, 10)
    sw $t4 5636($v0) # (1, 11)
    li $t4 0x060000
    sw $t4 5124($v0) # (1, 10)
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x080c69
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x3c53b9
    sw $t4 5132($v0) # (3, 10)
    li $t4 0xfae9ff
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x8a9fef
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x100e49
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x000102
    sw $t4 5152($v0) # (8, 10)
    sw $t4 5632($v0) # (0, 11)
    li $t4 0x030d42
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x1b3aa4
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x6d97dd
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x2374de
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x001546
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x000103
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_02_00: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 536($v0) # (6, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1568($v0) # (8, 3)
    sw $0 2080($v0) # (8, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 3616($v0) # (8, 7)
    sw $0 3620($v0) # (9, 7)
    sw $0 4128($v0) # (8, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4644($v0) # (9, 9)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010100
    sw $t4 8($v0) # (2, 0)
    sw $t4 540($v0) # (7, 1)
    li $t4 0x000100
    sw $t4 12($v0) # (3, 0)
    sw $t4 3104($v0) # (8, 6)
    sw $t4 4612($v0) # (1, 9)
    sw $t4 5124($v0) # (1, 10)
    sw $t4 5148($v0) # (7, 10)
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x030201
    sw $t4 24($v0) # (6, 0)
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x140b07
    sw $t4 528($v0) # (4, 1)
    li $t4 0x0c0504
    sw $t4 532($v0) # (5, 1)
    li $t4 0x030202
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x040403
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x1b060a
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xad523b
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xcd3f42
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xc94d41
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x5a2620
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x000001
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x010101
    sw $t4 1056($v0) # (8, 2)
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x925432
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xfab252
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xd77f46
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xcf7446
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xe1934b
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x170705
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x020101
    sw $t4 1572($v0) # (9, 3)
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x6a6a68
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x616168
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xa04e37
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xd47550
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x984441
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xbe6452
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xad3042
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x533237
    sw $t4 2076($v0) # (7, 4)
    li $t4 0xcac8c8
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xe5ebeb
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xaa4262
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xac3745
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xc9847b
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xde947b
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x971143
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x594b54
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x000101
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x646262
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xc1cecb
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x964667
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x975971
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x8e8d84
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xad9fa1
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x963760
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x3c2c30
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x020102
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x332e28
    sw $t4 3588($v0) # (1, 7)
    li $t4 0xa6415c
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x673347
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x8b4b67
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x882b4f
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x7c3642
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x060000
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x030303
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x220d0e
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x85143a
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x67223e
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x9d9295
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x916776
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x671229
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x060405
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x020001
    sw $t4 4608($v0) # (0, 9)
    sw $t4 4640($v0) # (8, 9)
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x53001e
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x95204b
    sw $t4 4620($v0) # (3, 9)
    li $t4 0xd8f0e8
    sw $t4 4624($v0) # (4, 9)
    li $t4 0xe0a7b9
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x38000c
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x010001
    sw $t4 5120($v0) # (0, 10)
    li $t4 0x220811
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x771335
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x983857
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x94183f
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x200409
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x060704
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x2b2b22
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x190707
    sw $t4 5648($v0) # (4, 11)
    jr $ra
draw_doll_02_01: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 540($v0) # (7, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1028($v0) # (1, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 1568($v0) # (8, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2076($v0) # (7, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 3616($v0) # (8, 7)
    sw $0 4132($v0) # (9, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x000401
    sw $t4 16($v0) # (4, 0)
    li $t4 0x010000
    sw $t4 28($v0) # (7, 0)
    sw $t4 512($v0) # (0, 1)
    sw $t4 1572($v0) # (9, 3)
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x010100
    sw $t4 516($v0) # (1, 1)
    li $t4 0x0c0205
    sw $t4 520($v0) # (2, 1)
    li $t4 0x893d2f
    sw $t4 524($v0) # (3, 1)
    li $t4 0xb23439
    sw $t4 528($v0) # (4, 1)
    li $t4 0xaa3e37
    sw $t4 532($v0) # (5, 1)
    li $t4 0x3a1115
    sw $t4 536($v0) # (6, 1)
    li $t4 0x010101
    sw $t4 544($v0) # (8, 1)
    sw $t4 2596($v0) # (9, 5)
    sw $t4 5124($v0) # (1, 10)
    li $t4 0x040201
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x803c2c
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xfba053
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xe17249
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xdc7b4b
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xde944b
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x170409
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x010001
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x050402
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x030403
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x9d4e36
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xd98a50
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x984939
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xbb6b48
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xbb6443
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x170509
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x55141a
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xc54c52
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xc27473
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xe28f78
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x850a31
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x000100
    sw $t4 2080($v0) # (8, 4)
    sw $t4 2592($v0) # (8, 5)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x222020
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x555b5a
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x651c35
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xa55c73
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x8a8274
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xa58f8c
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x942d58
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x48393f
    sw $t4 2588($v0) # (7, 5)
    li $t4 0xc4c4c5
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xddddd8
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x9f3a59
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x714254
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x804f66
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x813554
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x933951
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x5a3543
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x000200
    sw $t4 3104($v0) # (8, 6)
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x020001
    sw $t4 3108($v0) # (9, 6)
    sw $t4 3620($v0) # (9, 7)
    sw $t4 4128($v0) # (8, 8)
    sw $t4 4640($v0) # (8, 9)
    li $t4 0xcdd0d1
    sw $t4 3584($v0) # (0, 7)
    li $t4 0xbbaeaa
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x841d3a
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x611e3a
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x8d6571
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x733149
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x8e1f3d
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x1f040e
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x4a4848
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x141717
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x2c0011
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x8a0837
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xd5ebe3
    sw $t4 4112($v0) # (4, 8)
    li $t4 0xcda2b0
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x480011
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x020201
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x1b070f
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x850e37
    sw $t4 4620($v0) # (3, 9)
    li $t4 0xa37e8c
    sw $t4 4624($v0) # (4, 9)
    li $t4 0xa13356
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x290207
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x030303
    sw $t4 5120($v0) # (0, 10)
    li $t4 0x090806
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x332c27
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x20050a
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x020000
    sw $t4 5140($v0) # (5, 10)
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x000101
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x040000
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x020401
    sw $t4 5648($v0) # (4, 11)
    jr $ra
draw_doll_02_02: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 540($v0) # (7, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1056($v0) # (8, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1568($v0) # (8, 3)
    sw $0 3616($v0) # (8, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4636($v0) # (7, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010000
    sw $t4 4($v0) # (1, 0)
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x090104
    sw $t4 12($v0) # (3, 0)
    li $t4 0x2a130e
    sw $t4 16($v0) # (4, 0)
    li $t4 0x1f0b0a
    sw $t4 20($v0) # (5, 0)
    li $t4 0x010100
    sw $t4 28($v0) # (7, 0)
    sw $t4 516($v0) # (1, 1)
    li $t4 0x020101
    sw $t4 512($v0) # (0, 1)
    sw $t4 1060($v0) # (9, 2)
    sw $t4 2596($v0) # (9, 5)
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x250c0d
    sw $t4 520($v0) # (2, 1)
    li $t4 0xbd5a41
    sw $t4 524($v0) # (3, 1)
    li $t4 0xd44044
    sw $t4 528($v0) # (4, 1)
    li $t4 0xd25745
    sw $t4 532($v0) # (5, 1)
    li $t4 0x6f3827
    sw $t4 536($v0) # (6, 1)
    li $t4 0x010101
    sw $t4 544($v0) # (8, 1)
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x050603
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x000101
    sw $t4 1028($v0) # (1, 2)
    sw $t4 2080($v0) # (8, 4)
    li $t4 0xa05d38
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xf8bc50
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xd69645
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xe09f4a
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xe1974d
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x210c0e
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x1a0009
    sw $t4 1540($v0) # (1, 3)
    li $t4 0xc34347
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xd07b50
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xab514d
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xca725a
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xa11c3e
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x210006
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x020001
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x2c2f2e
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x431629
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x880530
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xab3f51
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xc38276
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xd7937c
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x90113f
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x42383e
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x010001
    sw $t4 2084($v0) # (9, 4)
    sw $t4 3620($v0) # (9, 7)
    sw $t4 4640($v0) # (8, 9)
    li $t4 0xc0c0c0
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xcdd2d2
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x7b2646
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x975e75
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x8d8f88
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xa3989c
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x9c637c
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x5e4b51
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x000200
    sw $t4 2592($v0) # (8, 5)
    li $t4 0xa5a6a7
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xddd6cf
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xa23a56
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x5f283d
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x865e6f
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x87274a
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x883848
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x3b2929
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x000100
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x616464
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x483437
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x74062a
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x73304b
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x99aca5
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x8f7d84
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x590821
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x190409
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x4d011d
    sw $t4 4104($v0) # (2, 8)
    li $t4 0xa2325a
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xd88da3
    sw $t4 4112($v0) # (4, 8)
    li $t4 0xcd6d8b
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x330717
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x030002
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x040304
    sw $t4 4608($v0) # (0, 9)
    li $t4 0x020202
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x1c080f
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x731535
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x96002a
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x800021
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x1d050c
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x060603
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x20241a
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x0d130b
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x000300
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x020000
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x030001
    sw $t4 5652($v0) # (5, 11)
    jr $ra
draw_doll_02_03: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 520($v0) # (2, 1)
    sw $0 536($v0) # (6, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1568($v0) # (8, 3)
    sw $0 3584($v0) # (0, 7)
    sw $0 4608($v0) # (0, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x020101
    sw $t4 8($v0) # (2, 0)
    sw $t4 516($v0) # (1, 1)
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x010200
    sw $t4 24($v0) # (6, 0)
    li $t4 0x010101
    sw $t4 512($v0) # (0, 1)
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x1d060a
    sw $t4 524($v0) # (3, 1)
    li $t4 0x451917
    sw $t4 528($v0) # (4, 1)
    li $t4 0x381112
    sw $t4 532($v0) # (5, 1)
    li $t4 0x000100
    sw $t4 540($v0) # (7, 1)
    sw $t4 2080($v0) # (8, 4)
    sw $t4 2592($v0) # (8, 5)
    sw $t4 3616($v0) # (8, 7)
    sw $t4 4128($v0) # (8, 8)
    sw $t4 4636($v0) # (7, 9)
    sw $t4 5124($v0) # (1, 10)
    li $t4 0x000200
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x401318
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xdd7b4b
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xea6b4b
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xed8f4d
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x904f32
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x030001
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x010100
    sw $t4 1056($v0) # (8, 2)
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x151816
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x140004
    sw $t4 1540($v0) # (1, 3)
    li $t4 0xd06b47
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xe6a84c
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xb96345
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xbb6548
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xdd8c4c
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x250e0d
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xb8c0be
    sw $t4 2048($v0) # (0, 4)
    li $t4 0xad7c8b
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xba3d38
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xba534d
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xac5c5c
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xd57a66
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x990f39
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x2a0b14
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x020001
    sw $t4 2084($v0) # (9, 4)
    li $t4 0xd6d7d6
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xd9d9d9
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x8a0e47
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xa94257
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xc49c7f
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xd29c88
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x9f2a55
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x5f585d
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x646565
    sw $t4 3072($v0) # (0, 6)
    li $t4 0x9fa6a4
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x913658
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x88546a
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x836f77
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x835369
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x905870
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x412a34
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x000301
    sw $t4 3104($v0) # (8, 6)
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x010001
    sw $t4 3108($v0) # (9, 6)
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x281a15
    sw $t4 3588($v0) # (1, 7)
    li $t4 0xa9405b
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x562137
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x7a5b64
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x791f43
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x811336
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x492425
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x030101
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x030303
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x19090d
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x6f0429
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x835467
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xb4bab9
    sw $t4 4112($v0) # (4, 8)
    li $t4 0xa69da1
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x55132b
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x1d050b
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x6c042d
    sw $t4 4616($v0) # (2, 9)
    li $t4 0xac003c
    sw $t4 4620($v0) # (3, 9)
    li $t4 0xcc003f
    sw $t4 4624($v0) # (4, 9)
    li $t4 0xd30244
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x5a0926
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x020000
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x010000
    sw $t4 5120($v0) # (0, 10)
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x200810
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x540c1e
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x7a0425
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x5e011e
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x17040a
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x000300
    sw $t4 5644($v0) # (3, 11)
    sw $t4 5648($v0) # (4, 11)
    jr $ra
draw_doll_02_04: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 516($v0) # (1, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 1056($v0) # (8, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1568($v0) # (8, 3)
    sw $0 2084($v0) # (9, 4)
    sw $0 2596($v0) # (9, 5)
    sw $0 3616($v0) # (8, 7)
    sw $0 3620($v0) # (9, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4616($v0) # (2, 9)
    sw $0 4632($v0) # (6, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010100
    sw $t4 4($v0) # (1, 0)
    sw $t4 32($v0) # (8, 0)
    li $t4 0x020001
    sw $t4 8($v0) # (2, 0)
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x88412f
    sw $t4 12($v0) # (3, 0)
    li $t4 0xd34445
    sw $t4 16($v0) # (4, 0)
    li $t4 0xd54743
    sw $t4 20($v0) # (5, 0)
    li $t4 0x7e2e2c
    sw $t4 24($v0) # (6, 0)
    li $t4 0x040002
    sw $t4 28($v0) # (7, 0)
    li $t4 0x030101
    sw $t4 512($v0) # (0, 1)
    li $t4 0x4b171b
    sw $t4 520($v0) # (2, 1)
    li $t4 0xf5aa52
    sw $t4 524($v0) # (3, 1)
    li $t4 0xdc7e48
    sw $t4 528($v0) # (4, 1)
    li $t4 0xd17746
    sw $t4 532($v0) # (5, 1)
    li $t4 0xee9a4f
    sw $t4 536($v0) # (6, 1)
    li $t4 0x52291d
    sw $t4 540($v0) # (7, 1)
    li $t4 0x040201
    sw $t4 548($v0) # (9, 1)
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x050302
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x030303
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x4f211b
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xe18250
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x9f5143
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xae4d47
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xbf5448
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x51261b
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x1a0004
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xb53648
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xb86566
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xe6a689
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x9d2941
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x050001
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x010000
    sw $t4 1572($v0) # (9, 3)
    sw $t4 3108($v0) # (9, 6)
    sw $t4 3612($v0) # (7, 7)
    sw $t4 4636($v0) # (7, 9)
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x1d1b1c
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x3a413e
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x5b3142
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x923559
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x9f9b93
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x8f7e7c
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xa47e8d
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x604f58
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x080b09
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x89898a
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xdee1dd
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xae6877
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x6f1534
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x9f9ea1
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x9b4064
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x7f3a55
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x702c3b
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x0e0f0c
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x888989
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xceccc9
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x882842
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x69082e
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x8b747c
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x9c8289
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x570125
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x67232d
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x070503
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x2c2b2b
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x181818
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x100009
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x7d0027
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xccb6bf
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xd3d1d2
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x570620
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x040706
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x690726
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xa84464
    sw $t4 4112($v0) # (4, 8)
    li $t4 0xa24060
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x460112
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x000300
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x020202
    sw $t4 4608($v0) # (0, 9)
    li $t4 0x030202
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x1a1713
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x2c1212
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x0c0000
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x000200
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x010201
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x020000
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x000001
    sw $t4 5648($v0) # (4, 11)
    jr $ra
draw_doll_02_05: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 2084($v0) # (9, 4)
    sw $0 2596($v0) # (9, 5)
    sw $0 3108($v0) # (9, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 3588($v0) # (1, 7)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4636($v0) # (7, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5136($v0) # (4, 10)
    sw $0 5140($v0) # (5, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x020201
    sw $t4 4($v0) # (1, 0)
    li $t4 0x58251f
    sw $t4 12($v0) # (3, 0)
    li $t4 0xcf5045
    sw $t4 16($v0) # (4, 0)
    li $t4 0xd64543
    sw $t4 20($v0) # (5, 0)
    li $t4 0xa84439
    sw $t4 24($v0) # (6, 0)
    li $t4 0x19080a
    sw $t4 28($v0) # (7, 0)
    li $t4 0x010100
    sw $t4 32($v0) # (8, 0)
    li $t4 0x010000
    sw $t4 36($v0) # (9, 0)
    sw $t4 1572($v0) # (9, 3)
    sw $t4 3620($v0) # (9, 7)
    sw $t4 4128($v0) # (8, 8)
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x020101
    sw $t4 512($v0) # (0, 1)
    sw $t4 1060($v0) # (9, 2)
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x010201
    sw $t4 516($v0) # (1, 1)
    li $t4 0x160309
    sw $t4 520($v0) # (2, 1)
    li $t4 0xe19b4c
    sw $t4 524($v0) # (3, 1)
    li $t4 0xe5924a
    sw $t4 528($v0) # (4, 1)
    li $t4 0xce7145
    sw $t4 532($v0) # (5, 1)
    li $t4 0xe58c4c
    sw $t4 536($v0) # (6, 1)
    li $t4 0x905b31
    sw $t4 540($v0) # (7, 1)
    li $t4 0x010101
    sw $t4 544($v0) # (8, 1)
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x030301
    sw $t4 548($v0) # (9, 1)
    li $t4 0x2c0a12
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xe2824e
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xac5646
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xaa5745
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xbf5250
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x82222c
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x0f0d0e
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x050505
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x120001
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xab2240
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xb3555a
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xdda288
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xc25159
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x681036
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x161b18
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x535252
    sw $t4 2048($v0) # (0, 4)
    li $t4 0xbfc1c1
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x796d74
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x7d143d
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xac999b
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x888078
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xa6818f
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x8c546c
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x252d2b
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x2b2b2b
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xdde0df
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xd0abae
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x7f1034
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x747175
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x933a5f
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x792e4b
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x902246
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x2c1d1d
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x343334
    sw $t4 3072($v0) # (0, 6)
    li $t4 0x7c817f
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x6e2b37
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x760931
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x715460
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xaa969b
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x6c213f
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x650824
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x150b09
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x0e0008
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x80002a
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xaa808f
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xf2fffe
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x9f4060
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x0a0001
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x000101
    sw $t4 3616($v0) # (8, 7)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x040303
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x030604
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x4b051d
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x902348
    sw $t4 4112($v0) # (4, 8)
    li $t4 0xb44c6d
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x780428
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x0b0104
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x010001
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x000100
    sw $t4 4620($v0) # (3, 9)
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x201916
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x3b201f
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x020000
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x030001
    sw $t4 5144($v0) # (6, 10)
    jr $ra
draw_doll_02_06: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 1028($v0) # (1, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1572($v0) # (9, 3)
    sw $0 2084($v0) # (9, 4)
    sw $0 2596($v0) # (9, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3108($v0) # (9, 6)
    sw $0 4100($v0) # (1, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4636($v0) # (7, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5136($v0) # (4, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010001
    sw $t4 4($v0) # (1, 0)
    sw $t4 36($v0) # (9, 0)
    sw $t4 3620($v0) # (9, 7)
    sw $t4 4640($v0) # (8, 9)
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x020101
    sw $t4 8($v0) # (2, 0)
    li $t4 0x0f0006
    sw $t4 12($v0) # (3, 0)
    li $t4 0x81302c
    sw $t4 16($v0) # (4, 0)
    li $t4 0xa43234
    sw $t4 20($v0) # (5, 0)
    li $t4 0x862a2c
    sw $t4 24($v0) # (6, 0)
    li $t4 0x150009
    sw $t4 28($v0) # (7, 0)
    li $t4 0x000100
    sw $t4 32($v0) # (8, 0)
    li $t4 0x040402
    sw $t4 516($v0) # (1, 1)
    li $t4 0x000201
    sw $t4 520($v0) # (2, 1)
    li $t4 0x8c5131
    sw $t4 524($v0) # (3, 1)
    li $t4 0xf59951
    sw $t4 528($v0) # (4, 1)
    li $t4 0xe2744a
    sw $t4 532($v0) # (5, 1)
    li $t4 0xf29b51
    sw $t4 536($v0) # (6, 1)
    li $t4 0xaf753b
    sw $t4 540($v0) # (7, 1)
    li $t4 0x040302
    sw $t4 544($v0) # (8, 1)
    li $t4 0x020201
    sw $t4 548($v0) # (9, 1)
    li $t4 0x040303
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x1c0005
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xeb9250
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xd5964a
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xb6763e
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xc47749
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xc95c46
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x310c0d
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x201d1e
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x9fa8a5
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x7d3550
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xbb2d39
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xb74c54
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xc97174
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xd57769
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x8d0239
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x39262d
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x191919
    sw $t4 2048($v0) # (0, 4)
    li $t4 0xd8d9d8
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xe2eae9
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x93365d
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xa14d64
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xa89f87
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xad8282
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x984969
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x49504e
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x0b0b0b
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x919090
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xc3b2b7
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x973d5a
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x763f54
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x846073
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x7d4862
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x8d3959
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x3e1723
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x040000
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x930c3a
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x922f47
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x5a2e40
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x8c6672
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x702742
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x7a002a
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x41121a
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x010000
    sw $t4 3584($v0) # (0, 7)
    sw $t4 4096($v0) # (0, 8)
    sw $t4 4616($v0) # (2, 9)
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x0b0205
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x310619
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x730024
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x924b66
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xe0fff9
    sw $t4 3604($v0) # (5, 7)
    li $t4 0xb18a97
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x2b0109
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x050203
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x000603
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x70052a
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xa71948
    sw $t4 4112($v0) # (4, 8)
    li $t4 0xc7859d
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xc62e5e
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x33010d
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x000200
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x020001
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x010303
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x150107
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x5f2430
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x291014
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x050902
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x060501
    sw $t4 5144($v0) # (6, 10)
    jr $ra
draw_doll_02_07: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 1028($v0) # (1, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1572($v0) # (9, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4128($v0) # (8, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5136($v0) # (4, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010000
    sw $t4 8($v0) # (2, 0)
    sw $t4 1024($v0) # (0, 2)
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x040002
    sw $t4 16($v0) # (4, 0)
    li $t4 0x260d0d
    sw $t4 20($v0) # (5, 0)
    li $t4 0x220a0b
    sw $t4 24($v0) # (6, 0)
    li $t4 0x000100
    sw $t4 32($v0) # (8, 0)
    sw $t4 4100($v0) # (1, 8)
    sw $t4 5140($v0) # (5, 10)
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x030202
    sw $t4 516($v0) # (1, 1)
    li $t4 0x010201
    sw $t4 520($v0) # (2, 1)
    li $t4 0x1a020a
    sw $t4 524($v0) # (3, 1)
    li $t4 0xb45d3d
    sw $t4 528($v0) # (4, 1)
    li $t4 0xdd5a47
    sw $t4 532($v0) # (5, 1)
    li $t4 0xdb6b45
    sw $t4 536($v0) # (6, 1)
    li $t4 0x7e3e2d
    sw $t4 540($v0) # (7, 1)
    li $t4 0x010101
    sw $t4 548($v0) # (9, 1)
    sw $t4 4640($v0) # (8, 9)
    li $t4 0xb15640
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xf5b750
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xbc6740
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xc5744a
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xf0a551
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x4b2d1a
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x020001
    sw $t4 1536($v0) # (0, 3)
    sw $t4 5648($v0) # (4, 11)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x2b302e
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x5b1e2f
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xce503b
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xce7c54
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x973b4f
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xd57b65
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xb53744
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x6c2423
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x6f7271
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xdac4ce
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x99284f
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xa02741
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xc09076
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xdfa987
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x9c1945
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x644e5b
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x030605
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x545454
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xedfffc
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x9e6d81
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x952550
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x827e80
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x88757d
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xa37085
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x593c49
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x040806
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x3a1423
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xb64d78
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xa94e5a
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x79464f
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x593143
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x721639
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x7b113a
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x6f132e
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x000300
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x20000b
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x430013
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x660026
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x701639
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xa4a7a6
    sw $t4 3604($v0) # (5, 7)
    li $t4 0xb0acad
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x621937
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x380914
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x000200
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x000700
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x630729
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xbc0c42
    sw $t4 4112($v0) # (4, 8)
    li $t4 0xc09ca8
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xdbb1bf
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x651d30
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x020101
    sw $t4 4132($v0) # (9, 8)
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x17070c
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x2e0512
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x21000c
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x6d4855
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x351d24
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x020102
    sw $t4 4644($v0) # (9, 9)
    li $t4 0x2c2920
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x1e1913
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x010001
    sw $t4 5644($v0) # (3, 11)
    jr $ra
draw_doll_02_08: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 2048($v0) # (0, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5140($v0) # (5, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x020100
    sw $t4 12($v0) # (3, 0)
    li $t4 0x000200
    sw $t4 32($v0) # (8, 0)
    sw $t4 3072($v0) # (0, 6)
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x020101
    sw $t4 520($v0) # (2, 1)
    sw $t4 4644($v0) # (9, 9)
    sw $t4 5664($v0) # (8, 11)
    li $t4 0x26050e
    sw $t4 528($v0) # (4, 1)
    li $t4 0x6f2127
    sw $t4 532($v0) # (5, 1)
    li $t4 0x843a2a
    sw $t4 536($v0) # (6, 1)
    li $t4 0x571e1e
    sw $t4 540($v0) # (7, 1)
    li $t4 0x010000
    sw $t4 1028($v0) # (1, 2)
    sw $t4 4612($v0) # (1, 9)
    sw $t4 5128($v0) # (2, 10)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x5d1d21
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xe1814a
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xfdbf54
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xf19750
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xf6a751
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x936134
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x080304
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x020001
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x030404
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x38101e
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xb52039
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xf3b550
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xc0894a
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xa45044
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xc2554b
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xc35840
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x190209
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x0e0e0e
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xbdb1b9
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xaa4f6c
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xae333a
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xb86165
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xe5a58a
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xd26960
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x771039
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x0a0c0c
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x010101
    sw $t4 2560($v0) # (0, 5)
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x020504
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xb6c3bd
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xdaeae3
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x870e47
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x984b60
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xa49f7f
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xb56a77
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x87586c
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x1b2622
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x23020c
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xba6e8d
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xaf6d87
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x9e3d4b
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x908889
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x90687f
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x874a64
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x6a2941
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x0b100e
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x170009
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x760028
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x8f0033
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x7c1736
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x53303d
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x8f5b6d
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x822247
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x6b1229
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x100308
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x400b20
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x8e0030
    sw $t4 4112($v0) # (4, 8)
    li $t4 0xaa3e63
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xa5818b
    sw $t4 4120($v0) # (6, 8)
    li $t4 0xb26d84
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x3f2831
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x000100
    sw $t4 4132($v0) # (9, 8)
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x020303
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x330a16
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x3d2c31
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x826a72
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x55192e
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x51514d
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x4c514a
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x010100
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x030001
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x060000
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x140803
    sw $t4 5660($v0) # (7, 11)
    jr $ra
draw_doll_02_09: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 532($v0) # (5, 1)
    sw $0 536($v0) # (6, 1)
    sw $0 540($v0) # (7, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2564($v0) # (1, 5)
    sw $0 3076($v0) # (1, 6)
    sw $0 4096($v0) # (0, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 16($v0) # (4, 0)
    li $t4 0x030201
    sw $t4 20($v0) # (5, 0)
    sw $t4 28($v0) # (7, 0)
    li $t4 0x020101
    sw $t4 24($v0) # (6, 0)
    sw $t4 32($v0) # (8, 0)
    sw $t4 548($v0) # (9, 1)
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x010100
    sw $t4 1036($v0) # (3, 2)
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x1b060a
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x8a3330
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xa64735
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x9a4c32
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x21040d
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x020003
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xa34c38
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xffd856
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xe5934d
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xeea34f
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xd38a48
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x351e15
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x030101
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x020403
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x3f0211
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xea8b4d
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xd29952
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x974947
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xc05751
    sw $t4 2076($v0) # (7, 4)
    li $t4 0xbd4243
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x711426
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x020202
    sw $t4 2560($v0) # (0, 5)
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x878d8b
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xaf677e
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xa92337
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xb34a51
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xdb9985
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xe79978
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x910837
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x482c3a
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x030303
    sw $t4 3072($v0) # (0, 6)
    li $t4 0x7f8683
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xeafff9
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x8e305d
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x952a52
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x8c8c79
    sw $t4 3096($v0) # (6, 6)
    li $t4 0xad8c8a
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x9b4d6d
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x5c5c5d
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x040002
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x8f526b
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xcea8b7
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xa65c65
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x864a5b
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x75425a
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x7c3c59
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x853754
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x53192c
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x110007
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x2b000c
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x5b001e
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x881d3a
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x582d3e
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x827177
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x82445a
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x7d0734
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x51131f
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x000200
    sw $t4 4616($v0) # (2, 9)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x010605
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x760230
    sw $t4 4624($v0) # (4, 9)
    li $t4 0xb60033
    sw $t4 4628($v0) # (5, 9)
    li $t4 0xba8b9a
    sw $t4 4632($v0) # (6, 9)
    li $t4 0xedfaf6
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x706469
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x010000
    sw $t4 4644($v0) # (9, 9)
    sw $t4 5128($v0) # (2, 10)
    sw $t4 5664($v0) # (8, 11)
    li $t4 0x000302
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x4e0a21
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x790729
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x751d39
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x865c69
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x110c0d
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x000100
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x0e110a
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x1e110a
    sw $t4 5660($v0) # (7, 11)
    jr $ra
draw_doll_02_10: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 1036($v0) # (3, 2)
    sw $0 1044($v0) # (5, 2)
    sw $0 1048($v0) # (6, 2)
    sw $0 1052($v0) # (7, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1544($v0) # (2, 3)
    sw $0 1552($v0) # (4, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2056($v0) # (2, 4)
    sw $0 2060($v0) # (3, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 2564($v0) # (1, 5)
    sw $0 3076($v0) # (1, 6)
    sw $0 3588($v0) # (1, 7)
    sw $0 4100($v0) # (1, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x030101
    sw $t4 532($v0) # (5, 1)
    sw $t4 536($v0) # (6, 1)
    sw $t4 540($v0) # (7, 1)
    li $t4 0x020101
    sw $t4 544($v0) # (8, 1)
    li $t4 0x010100
    sw $t4 1040($v0) # (4, 2)
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x020202
    sw $t4 1548($v0) # (3, 3)
    sw $t4 3072($v0) # (0, 6)
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x421817
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x872c2c
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x8b322c
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x2c0511
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x371615
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xeb964e
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xe85d4a
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xe4684a
    sw $t4 2076($v0) # (7, 4)
    li $t4 0xdd884a
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x2a1710
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x0e0d0b
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x0d0c0e
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x763124
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xf5ab57
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x8f4637
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xa13d3b
    sw $t4 2588($v0) # (7, 5)
    li $t4 0xcd704a
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x86482a
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x282827
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xb6b9bd
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x9f3b4c
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xc44e48
    sw $t4 3092($v0) # (5, 6)
    li $t4 0xbd726f
    sw $t4 3096($v0) # (6, 6)
    li $t4 0xeba181
    sw $t4 3100($v0) # (7, 6)
    li $t4 0xa51d3f
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x6c2c40
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x141213
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xdde8e5
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xb48398
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x8c0537
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x9a8478
    sw $t4 3608($v0) # (6, 7)
    li $t4 0xa89680
    sw $t4 3612($v0) # (7, 7)
    li $t4 0xa9506f
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x8e7582
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x010101
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x080908
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x808180
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xb97383
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x953d55
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x86707d
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x7a405d
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x905d72
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x671b35
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x020000
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x160000
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x94183c
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x693140
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x644a56
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x844258
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x6a0026
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x790f2b
    sw $t4 4644($v0) # (9, 9)
    li $t4 0x020001
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x0d0407
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x450823
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x94002b
    sw $t4 5140($v0) # (5, 10)
    li $t4 0xa75d74
    sw $t4 5144($v0) # (6, 10)
    li $t4 0xdffaf1
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x91878b
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x110004
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x010000
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x000100
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x330a19
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x970633
    sw $t4 5652($v0) # (5, 11)
    li $t4 0xb21b4a
    sw $t4 5656($v0) # (6, 11)
    li $t4 0xca6d8c
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x5a434a
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_02_11: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 532($v0) # (5, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1548($v0) # (3, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 2564($v0) # (1, 5)
    sw $0 2568($v0) # (2, 5)
    sw $0 2572($v0) # (3, 5)
    sw $0 3588($v0) # (1, 7)
    sw $0 4100($v0) # (1, 8)
    sw $0 4612($v0) # (1, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x020101
    sw $t4 16($v0) # (4, 0)
    sw $t4 32($v0) # (8, 0)
    li $t4 0x000100
    sw $t4 20($v0) # (5, 0)
    li $t4 0x150c07
    sw $t4 536($v0) # (6, 1)
    li $t4 0x0a0403
    sw $t4 540($v0) # (7, 1)
    li $t4 0x010100
    sw $t4 548($v0) # (9, 1)
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x020000
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x21090c
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xb4543d
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xce3f41
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xc74e41
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x50221d
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x030301
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xa06038
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xf8ae51
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xd77e46
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xd27747
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xd88d48
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x150808
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x020401
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x030303
    sw $t4 2060($v0) # (3, 4)
    sw $t4 4096($v0) # (0, 8)
    li $t4 0xa95439
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xcf7250
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x994540
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xc06352
    sw $t4 2076($v0) # (7, 4)
    li $t4 0xa42b3e
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x25080d
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x821535
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xb64451
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xca867a
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xe2937d
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x840235
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x0c0408
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x010101
    sw $t4 3072($v0) # (0, 6)
    sw $t4 3076($v0) # (1, 6)
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x0f0f0f
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x707674
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x8a2b55
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x996076
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x88867c
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x968187
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x9b4468
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x53494e
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x020202
    sw $t4 3584($v0) # (0, 7)
    sw $t4 4608($v0) # (0, 9)
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x838886
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xe2cfd7
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xaa4a5c
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x815762
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x965973
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x702543
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x81133c
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x641c30
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x666a68
    sw $t4 4104($v0) # (2, 8)
    li $t4 0xcfc0c6
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x7d1b33
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x741e3d
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x836571
    sw $t4 4120($v0) # (6, 8)
    li $t4 0xa17f8b
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x802548
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x2e0c0f
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x292728
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x2e3130
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x290012
    sw $t4 4624($v0) # (4, 9)
    li $t4 0xa70031
    sw $t4 4628($v0) # (5, 9)
    li $t4 0xa24a67
    sw $t4 4632($v0) # (6, 9)
    li $t4 0xf1fffd
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x866f76
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x11060b
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x610725
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x960a36
    sw $t4 5144($v0) # (6, 10)
    li $t4 0xa54867
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x3e0c1b
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x010202
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x000200
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x0c0a08
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x3b2721
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x020501
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_02_12: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1036($v0) # (3, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2060($v0) # (3, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 2564($v0) # (1, 5)
    sw $0 4096($v0) # (0, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 4620($v0) # (3, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010100
    sw $t4 524($v0) # (3, 1)
    sw $t4 5664($v0) # (8, 11)
    li $t4 0x54201d
    sw $t4 532($v0) # (5, 1)
    li $t4 0x7f2929
    sw $t4 536($v0) # (6, 1)
    li $t4 0x6f2624
    sw $t4 540($v0) # (7, 1)
    li $t4 0x0e0006
    sw $t4 544($v0) # (8, 1)
    li $t4 0x000100
    sw $t4 548($v0) # (9, 1)
    sw $t4 4644($v0) # (9, 9)
    li $t4 0x030201
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x682f24
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xf78f52
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xe9614b
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xea764e
    sw $t4 1052($v0) # (7, 2)
    li $t4 0xb36e3d
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x090104
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x020401
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x020202
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xb25f3c
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xdd954c
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xa85d37
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xbb7042
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xca7f46
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x18030a
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x030101
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x702825
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xcb5b54
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xb45e65
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xe1866f
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x80112d
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x030001
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x202121
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x5c0e25
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xac556a
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xa38975
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xb1817b
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x8a1c49
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x292527
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x010101
    sw $t4 3072($v0) # (0, 6)
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x080808
    sw $t4 3076($v0) # (1, 6)
    sw $t4 4100($v0) # (1, 8)
    li $t4 0xa2a3a3
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xd5d6d6
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x93415d
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x9c7280
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x825f73
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x6e4157
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x933a59
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x634550
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x0d0c0d
    sw $t4 3588($v0) # (1, 7)
    li $t4 0xcfd0cf
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xd4d5d5
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xaf5f65
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x71384b
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x833f57
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x710f32
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x962c43
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x270c16
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x7d7c7c
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x3a3b3b
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x380014
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x8f002f
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xb1a1a5
    sw $t4 4120($v0) # (6, 8)
    li $t4 0xcad4d0
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x540626
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x040000
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x260c17
    sw $t4 4624($v0) # (4, 9)
    li $t4 0xbb0235
    sw $t4 4628($v0) # (5, 9)
    li $t4 0xc06380
    sw $t4 4632($v0) # (6, 9)
    li $t4 0xbfb4ba
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x1d030b
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x030303
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x030202
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x050203
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x1b050c
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x4e1625
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x442b2f
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x050001
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x010001
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x030802
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x120c05
    sw $t4 5660($v0) # (7, 11)
    jr $ra
draw_doll_02_13: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1036($v0) # (3, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2056($v0) # (2, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4104($v0) # (2, 8)
    sw $0 4108($v0) # (3, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010501
    sw $t4 24($v0) # (6, 0)
    li $t4 0x010000
    sw $t4 36($v0) # (9, 0)
    sw $t4 520($v0) # (2, 1)
    sw $t4 4132($v0) # (9, 8)
    sw $t4 5156($v0) # (9, 10)
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x010100
    sw $t4 524($v0) # (3, 1)
    li $t4 0x120306
    sw $t4 528($v0) # (4, 1)
    li $t4 0x8f3d31
    sw $t4 532($v0) # (5, 1)
    li $t4 0xb23439
    sw $t4 536($v0) # (6, 1)
    li $t4 0xa53936
    sw $t4 540($v0) # (7, 1)
    li $t4 0x310b13
    sw $t4 544($v0) # (8, 1)
    li $t4 0x000100
    sw $t4 548($v0) # (9, 1)
    sw $t4 4644($v0) # (9, 9)
    sw $t4 5136($v0) # (4, 10)
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x030301
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x89482f
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xfda452
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xe27849
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xef994e
    sw $t4 1052($v0) # (7, 2)
    li $t4 0xd99e49
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x0d0205
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x030401
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x040303
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xaf623b
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xd98c4e
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x9d5239
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xc67f49
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xca7b48
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x260410
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x050000
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xb6373c
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xb94c4f
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xc77777
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xdb8b76
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x9a013a
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x400018
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x010101
    sw $t4 2560($v0) # (0, 5)
    sw $t4 3072($v0) # (0, 6)
    li $t4 0x060505
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x9a9d9c
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x90848a
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x820630
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xa46a7b
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x897d70
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x8d7574
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x9a2053
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x582a3d
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x0c0c0c
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xd2d2d2
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xf7f8f8
    sw $t4 3084($v0) # (3, 6)
    li $t4 0xa5596a
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x956874
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x854965
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x6a203e
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x913750
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x533540
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x090909
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x969696
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xa1a3a2
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x923f4d
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x692e45
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x886470
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x833551
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x8e1f3e
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x19040b
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x3e0018
    sw $t4 4112($v0) # (4, 8)
    li $t4 0xa80337
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xc0bfbe
    sw $t4 4120($v0) # (6, 8)
    li $t4 0xe1e8e6
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x4c0924
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x030202
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x020402
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x430b1f
    sw $t4 4624($v0) # (4, 9)
    li $t4 0xad0534
    sw $t4 4628($v0) # (5, 9)
    li $t4 0xb42753
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x9a4b66
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x20060d
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x000302
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x2f1418
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x382020
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x000200
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x050300
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x020101
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_02_14: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 532($v0) # (5, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1544($v0) # (2, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 3588($v0) # (1, 7)
    sw $0 3592($v0) # (2, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x020101
    sw $t4 16($v0) # (4, 0)
    sw $t4 32($v0) # (8, 0)
    li $t4 0x000100
    sw $t4 20($v0) # (5, 0)
    sw $t4 5156($v0) # (9, 10)
    sw $t4 5648($v0) # (4, 11)
    sw $t4 5664($v0) # (8, 11)
    li $t4 0x010000
    sw $t4 524($v0) # (3, 1)
    sw $t4 4644($v0) # (9, 9)
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x130907
    sw $t4 536($v0) # (6, 1)
    li $t4 0x080003
    sw $t4 540($v0) # (7, 1)
    li $t4 0x010100
    sw $t4 548($v0) # (9, 1)
    li $t4 0x040202
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x000301
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x21070c
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xb45c3e
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xd34c42
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xce6942
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x4f201d
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x010101
    sw $t4 1540($v0) # (1, 3)
    sw $t4 2560($v0) # (0, 5)
    sw $t4 3072($v0) # (0, 6)
    sw $t4 4100($v0) # (1, 8)
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x070000
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xcf7f45
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xf4b050
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xce6348
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xd17f4a
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xd89449
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x17080a
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x0b0909
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x909796
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x8b4c5a
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xdf7540
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xb95c4b
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xa2514e
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xc5645a
    sw $t4 2076($v0) # (7, 4)
    li $t4 0xa2273b
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x200207
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x0c0b0c
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xd2d5d4
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xd0c4c9
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x8e0138
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xb14852
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xd0967d
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xdd957c
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x971145
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x5c4c54
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x060505
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x9a9b9a
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xccc3c8
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x88244b
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x99657a
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x8f837e
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x997b84
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x9c5775
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x503f45
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x8a3c52
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xa64a63
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x562337
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x753f53
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x700834
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x80223f
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x432325
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x2d0e12
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x7e0f33
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x74485a
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xa1bcb2
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x848285
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x5e0c28
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x2c1013
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x010304
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x73002a
    sw $t4 4624($v0) # (4, 9)
    li $t4 0xa7355c
    sw $t4 4628($v0) # (5, 9)
    li $t4 0xd36788
    sw $t4 4632($v0) # (6, 9)
    li $t4 0xd8577e
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x540b25
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x010201
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x3d091d
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x790026
    sw $t4 5140($v0) # (5, 10)
    li $t4 0xa90028
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x990027
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x310714
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x000500
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x0b0c05
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x050c03
    sw $t4 5660($v0) # (7, 11)
    jr $ra
draw_doll_02_15: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1544($v0) # (2, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4104($v0) # (2, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5136($v0) # (4, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x020100
    sw $t4 8($v0) # (2, 0)
    li $t4 0x3e1916
    sw $t4 16($v0) # (4, 0)
    li $t4 0x9a3333
    sw $t4 20($v0) # (5, 0)
    li $t4 0xa63934
    sw $t4 24($v0) # (6, 0)
    li $t4 0x53151e
    sw $t4 28($v0) # (7, 0)
    li $t4 0x010001
    sw $t4 36($v0) # (9, 0)
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x010000
    sw $t4 516($v0) # (1, 1)
    sw $t4 4640($v0) # (8, 9)
    sw $t4 4644($v0) # (9, 9)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x010100
    sw $t4 520($v0) # (2, 1)
    li $t4 0x20050c
    sw $t4 524($v0) # (3, 1)
    li $t4 0xdb8549
    sw $t4 528($v0) # (4, 1)
    li $t4 0xec754c
    sw $t4 532($v0) # (5, 1)
    li $t4 0xda6449
    sw $t4 536($v0) # (6, 1)
    li $t4 0xeb934f
    sw $t4 540($v0) # (7, 1)
    li $t4 0x512b1d
    sw $t4 544($v0) # (8, 1)
    li $t4 0x030101
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x020202
    sw $t4 1032($v0) # (2, 2)
    sw $t4 4132($v0) # (9, 8)
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x4a151b
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xf09d52
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xac623d
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xa95d3b
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xd6834e
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x653223
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x000001
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x020000
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x130002
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xc04a47
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xb5565f
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xd98f7b
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xbf4250
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x220008
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x292c2a
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x3b222a
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x93264a
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x9f7f7a
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x9e917b
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xa7496b
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x5e283e
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x0a110e
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x5d5c5c
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xe2e8e6
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xbc949f
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x8f3d55
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x8a7882
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x733150
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x8a4d5f
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x863853
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x141d1a
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x717070
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xebf0f0
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xac8385
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x893143
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x734859
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x7e304a
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x89243f
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x611a2b
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x000101
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x3e3e3e
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x535655
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x0c0107
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x770025
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xa4395c
    sw $t4 3604($v0) # (5, 7)
    li $t4 0xdbfff4
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x905c72
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x160003
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x010301
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x000502
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x7a062d
    sw $t4 4112($v0) # (4, 8)
    li $t4 0xbe0e44
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xbda8b1
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x613f4b
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x000100
    sw $t4 4128($v0) # (8, 8)
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x030303
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x040404
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x21030c
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x522b31
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x120c0a
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x090802
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x070401
    sw $t4 5148($v0) # (7, 10)
    jr $ra
draw_doll_02_16: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 2052($v0) # (1, 4)
    sw $0 2080($v0) # (8, 4)
    sw $0 2564($v0) # (1, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3076($v0) # (1, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 3616($v0) # (8, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4104($v0) # (2, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5140($v0) # (5, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010000
    sw $t4 4($v0) # (1, 0)
    sw $t4 1536($v0) # (0, 3)
    sw $t4 4100($v0) # (1, 8)
    sw $t4 4644($v0) # (9, 9)
    sw $t4 5132($v0) # (3, 10)
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x010100
    sw $t4 8($v0) # (2, 0)
    li $t4 0x0e0005
    sw $t4 12($v0) # (3, 0)
    li $t4 0xae7a3b
    sw $t4 16($v0) # (4, 0)
    li $t4 0xe8974c
    sw $t4 20($v0) # (5, 0)
    li $t4 0xbf2841
    sw $t4 24($v0) # (6, 0)
    li $t4 0x642624
    sw $t4 28($v0) # (7, 0)
    li $t4 0x010101
    sw $t4 36($v0) # (9, 0)
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x030201
    sw $t4 516($v0) # (1, 1)
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x000101
    sw $t4 520($v0) # (2, 1)
    sw $t4 5652($v0) # (5, 11)
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x692b25
    sw $t4 524($v0) # (3, 1)
    li $t4 0xffff5a
    sw $t4 528($v0) # (4, 1)
    li $t4 0xf7ea51
    sw $t4 532($v0) # (5, 1)
    li $t4 0xdf8949
    sw $t4 536($v0) # (6, 1)
    li $t4 0xe99f4e
    sw $t4 540($v0) # (7, 1)
    li $t4 0x2d1710
    sw $t4 544($v0) # (8, 1)
    li $t4 0x040301
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x935e32
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xfee158
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xe0b44e
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xb75849
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xc33f4a
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x3c1416
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x000200
    sw $t4 1540($v0) # (1, 3)
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x0d0b0e
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xc37846
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xe17749
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xd29344
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xd67969
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x8a2c3f
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x070002
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x020201
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x030303
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x4e484f
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xcc5b60
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xcc6238
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xc28f65
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xad91a3
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x6d6567
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x030203
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x020001
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x220d14
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xa22143
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xb63435
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xab9895
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x988d95
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x8d2e4f
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x531522
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x010201
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x0b0003
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x73002f
    sw $t4 3084($v0) # (3, 6)
    li $t4 0xa41a3a
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x904554
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x7a3653
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x56112b
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x341716
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x010001
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x3b071b
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x97033b
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xa90028
    sw $t4 3604($v0) # (5, 7)
    li $t4 0xb74066
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x4d494a
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x030202
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x1f0b12
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x3c101e
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x6e3346
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x663c4b
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x2c0714
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x020101
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x000100
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x161d16
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x3c362c
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x010400
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x030101
    sw $t4 5148($v0) # (7, 10)
    jr $ra
draw_doll_02_17: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 516($v0) # (1, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 1028($v0) # (1, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2056($v0) # (2, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 3592($v0) # (2, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4620($v0) # (3, 9)
    sw $0 4636($v0) # (7, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5140($v0) # (5, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 4($v0) # (1, 0)
    sw $t4 512($v0) # (0, 1)
    sw $t4 1540($v0) # (1, 3)
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x55221f
    sw $t4 12($v0) # (3, 0)
    li $t4 0xba243f
    sw $t4 16($v0) # (4, 0)
    li $t4 0xe4894b
    sw $t4 20($v0) # (5, 0)
    li $t4 0xbd8b40
    sw $t4 24($v0) # (6, 0)
    li $t4 0x170209
    sw $t4 28($v0) # (7, 0)
    li $t4 0x010100
    sw $t4 32($v0) # (8, 0)
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x010000
    sw $t4 36($v0) # (9, 0)
    sw $t4 2560($v0) # (0, 5)
    sw $t4 3072($v0) # (0, 6)
    sw $t4 3076($v0) # (1, 6)
    sw $t4 3104($v0) # (8, 6)
    sw $t4 3108($v0) # (9, 6)
    sw $t4 4100($v0) # (1, 8)
    sw $t4 4132($v0) # (9, 8)
    sw $t4 4616($v0) # (2, 9)
    sw $t4 5132($v0) # (3, 10)
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x1b0b0a
    sw $t4 520($v0) # (2, 1)
    li $t4 0xdd974a
    sw $t4 524($v0) # (3, 1)
    li $t4 0xe28c4a
    sw $t4 528($v0) # (4, 1)
    li $t4 0xf3dd51
    sw $t4 532($v0) # (5, 1)
    li $t4 0xffff5b
    sw $t4 536($v0) # (6, 1)
    li $t4 0x84432e
    sw $t4 540($v0) # (7, 1)
    li $t4 0x040301
    sw $t4 548($v0) # (9, 1)
    li $t4 0x020101
    sw $t4 1024($v0) # (0, 2)
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x2a0e0f
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xc03f48
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xb24645
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xdb9742
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xfbf352
    sw $t4 1048($v0) # (6, 2)
    li $t4 0xce8443
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x040000
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x010300
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x040002
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x762036
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xd36b5f
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xc89d71
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xe2b95f
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xce604b
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x170e15
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x000200
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x030203
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x56525d
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xd0897c
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xcad0a7
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xb46b70
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xd27463
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x292d34
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x4b131e
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x7c314f
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xb06459
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x9a5354
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xbd464b
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x942d37
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x000001
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x311515
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x2d0511
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x5d0c2c
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x880032
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x7d1a32
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x320619
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x020001
    sw $t4 3588($v0) # (1, 7)
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x271019
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xc10642
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xae0034
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x820032
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x320a19
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x000100
    sw $t4 3616($v0) # (8, 7)
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x1f050e
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x630b25
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x7b3a4f
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x4c2935
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x210510
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x000700
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x3b3a2f
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x141712
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x010001
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x040001
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x000101
    sw $t4 5652($v0) # (5, 11)
    sw $t4 5656($v0) # (6, 11)
    jr $ra
draw_doll_02_18: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 516($v0) # (1, 1)
    sw $0 1056($v0) # (8, 2)
    sw $0 2084($v0) # (9, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 2596($v0) # (9, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 3592($v0) # (2, 7)
    sw $0 3616($v0) # (8, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5140($v0) # (5, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010000
    sw $t4 4($v0) # (1, 0)
    sw $t4 3108($v0) # (9, 6)
    sw $t4 4100($v0) # (1, 8)
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x450d19
    sw $t4 12($v0) # (3, 0)
    li $t4 0xa12f32
    sw $t4 16($v0) # (4, 0)
    li $t4 0xa55737
    sw $t4 20($v0) # (5, 0)
    li $t4 0x50291b
    sw $t4 24($v0) # (6, 0)
    li $t4 0x010100
    sw $t4 32($v0) # (8, 0)
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x030201
    sw $t4 512($v0) # (0, 1)
    li $t4 0x432a17
    sw $t4 520($v0) # (2, 1)
    li $t4 0xde7b4b
    sw $t4 524($v0) # (3, 1)
    li $t4 0xe66f4c
    sw $t4 528($v0) # (4, 1)
    li $t4 0xe89d4e
    sw $t4 532($v0) # (5, 1)
    li $t4 0xf7cd53
    sw $t4 536($v0) # (6, 1)
    li $t4 0x2d0a12
    sw $t4 540($v0) # (7, 1)
    li $t4 0x020302
    sw $t4 544($v0) # (8, 1)
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x020101
    sw $t4 548($v0) # (9, 1)
    li $t4 0x020201
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x020001
    sw $t4 1028($v0) # (1, 2)
    sw $t4 1536($v0) # (0, 3)
    sw $t4 2048($v0) # (0, 4)
    sw $t4 4104($v0) # (2, 8)
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x883b2f
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xd6744b
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xae6f3c
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xbc6f41
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xffe959
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x863b24
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x040301
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x000100
    sw $t4 1540($v0) # (1, 3)
    sw $t4 3076($v0) # (1, 6)
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x300314
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xcb5d64
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xb86670
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xcc8042
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xde9849
    sw $t4 1560($v0) # (6, 3)
    li $t4 0xc2828a
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x484c4a
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x000200
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x2f121a
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xa64769
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xba887d
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xc76a49
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xbd5346
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xd0cecd
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x878a8a
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x000201
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x050000
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x76495d
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x902651
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x8c3247
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x8a1d37
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xc691a1
    sw $t4 2588($v0) # (7, 5)
    li $t4 0xa8b0ae
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x060103
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x550c28
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x97566e
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x893548
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x790f33
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x780836
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x0f1010
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x6d6368
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x9e7583
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x8c002d
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x8c0136
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x3f061c
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x010001
    sw $t4 3620($v0) # (9, 7)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x60102d
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xc4003d
    sw $t4 4112($v0) # (4, 8)
    li $t4 0xa00237
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x7a0531
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x19060d
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x010101
    sw $t4 4128($v0) # (8, 8)
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x0e0706
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x643b40
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x280d16
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x050404
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x040201
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x090801
    sw $t4 5136($v0) # (4, 10)
    jr $ra
draw_doll_02_19: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 1056($v0) # (8, 2)
    sw $0 3072($v0) # (0, 6)
    sw $0 4100($v0) # (1, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 4($v0) # (1, 0)
    sw $t4 544($v0) # (8, 1)
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x1c060a
    sw $t4 12($v0) # (3, 0)
    li $t4 0x5e1f20
    sw $t4 16($v0) # (4, 0)
    li $t4 0x64251f
    sw $t4 20($v0) # (5, 0)
    li $t4 0x150008
    sw $t4 24($v0) # (6, 0)
    li $t4 0x010000
    sw $t4 32($v0) # (8, 0)
    sw $t4 512($v0) # (0, 1)
    sw $t4 2084($v0) # (9, 4)
    sw $t4 2596($v0) # (9, 5)
    sw $t4 3108($v0) # (9, 6)
    sw $t4 3584($v0) # (0, 7)
    sw $t4 3620($v0) # (9, 7)
    sw $t4 4128($v0) # (8, 8)
    sw $t4 4636($v0) # (7, 9)
    sw $t4 5124($v0) # (1, 10)
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x000100
    sw $t4 516($v0) # (1, 1)
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x160209
    sw $t4 520($v0) # (2, 1)
    li $t4 0xcb7a45
    sw $t4 524($v0) # (3, 1)
    li $t4 0xea614c
    sw $t4 528($v0) # (4, 1)
    li $t4 0xe35d4a
    sw $t4 532($v0) # (5, 1)
    li $t4 0xc87144
    sw $t4 536($v0) # (6, 1)
    li $t4 0x21110d
    sw $t4 540($v0) # (7, 1)
    li $t4 0x020101
    sw $t4 548($v0) # (9, 1)
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x040503
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x040002
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x9a4b34
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xf4bc51
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xbe7c3e
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xba703c
    sw $t4 1044($v0) # (5, 2)
    li $t4 0xe7a84d
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x613a1e
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x040301
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x181918
    sw $t4 1536($v0) # (0, 3)
    li $t4 0xafafb0
    sw $t4 1540($v0) # (1, 3)
    li $t4 0xc06b64
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xba4947
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xae5357
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xd18679
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xaf5847
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x925457
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x0a0f10
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x010100
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x181617
    sw $t4 2048($v0) # (0, 4)
    li $t4 0xd6eae1
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xa45a81
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x961b44
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xbe8f7c
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xc59985
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xc85a4d
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x88465b
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x0a100f
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x030303
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x793d56
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x9c2a53
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x8a3e5a
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x84737e
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x85556c
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x975d74
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x64203a
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x050a07
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x260008
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xae445b
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x631031
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x8b3553
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x80354f
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x650d31
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x831830
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x060602
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x000502
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x51031f
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x832348
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xb9cfc8
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xb1a8ab
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x570220
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x280511
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x020001
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x20050f
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x920d3e
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xbe7c92
    sw $t4 4112($v0) # (4, 8)
    li $t4 0xe43268
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x820128
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x030203
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x45222c
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x70152f
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x520015
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x19030a
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x0f0f09
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x13160c
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x000300
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x030001
    sw $t4 5652($v0) # (5, 11)
    jr $ra
draw_doll_02_20: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 520($v0) # (2, 1)
    sw $0 536($v0) # (6, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1568($v0) # (8, 3)
    sw $0 2080($v0) # (8, 4)
    sw $0 3072($v0) # (0, 6)
    sw $0 3616($v0) # (8, 7)
    sw $0 3620($v0) # (9, 7)
    sw $0 4128($v0) # (8, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4644($v0) # (9, 9)
    sw $0 5148($v0) # (7, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x020101
    sw $t4 8($v0) # (2, 0)
    li $t4 0x010200
    sw $t4 24($v0) # (6, 0)
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x020202
    sw $t4 512($v0) # (0, 1)
    li $t4 0x030302
    sw $t4 516($v0) # (1, 1)
    li $t4 0x1d070a
    sw $t4 524($v0) # (3, 1)
    li $t4 0x451b17
    sw $t4 528($v0) # (4, 1)
    li $t4 0x391512
    sw $t4 532($v0) # (5, 1)
    li $t4 0x000100
    sw $t4 540($v0) # (7, 1)
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x3a1715
    sw $t4 1032($v0) # (2, 2)
    li $t4 0xdb784b
    sw $t4 1036($v0) # (3, 2)
    li $t4 0xe34849
    sw $t4 1040($v0) # (4, 2)
    li $t4 0xe35f4a
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x934f33
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x050002
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x010100
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x3a3c38
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x312c33
    sw $t4 1540($v0) # (1, 3)
    li $t4 0xa45a35
    sw $t4 1544($v0) # (2, 3)
    li $t4 0xf3b751
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xcb8d41
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xba5f40
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xffd254
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x532e1e
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x040201
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x9b9e9a
    sw $t4 2048($v0) # (0, 4)
    li $t4 0xe0d5e3
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xc67c51
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xcd6c4d
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xaf5d55
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xc96a5f
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xb33e41
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x794839
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x030200
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x686767
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xc2d4cc
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xa75360
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xa3384c
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xbe8d7c
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xd19b88
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xb42346
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x6f2938
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x000101
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x030001
    sw $t4 2596($v0) # (9, 5)
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x593344
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x97194c
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x916375
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x897f83
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xa08f98
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x813b53
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x2f0813
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x020001
    sw $t4 3108($v0) # (9, 6)
    sw $t4 4608($v0) # (0, 9)
    li $t4 0x050102
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x5b0b27
    sw $t4 3588($v0) # (1, 7)
    li $t4 0xa92a4e
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x5a253a
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x8b445f
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x7d1b3e
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x61252e
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x030100
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x010000
    sw $t4 4096($v0) # (0, 8)
    sw $t4 5120($v0) # (0, 10)
    sw $t4 5124($v0) # (1, 10)
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x100908
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x6f072d
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x7b2b4a
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xaebfb9
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x96898f
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x5b1625
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x070304
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x000200
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x480018
    sw $t4 4616($v0) # (2, 9)
    li $t4 0xa32f5a
    sw $t4 4620($v0) # (3, 9)
    li $t4 0xd5d5d4
    sw $t4 4624($v0) # (4, 9)
    li $t4 0xc15a7b
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x3d0012
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x15070b
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x5c2134
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x6b132f
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x5a001d
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x110407
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x050503
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x1b1c12
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x090b04
    sw $t4 5648($v0) # (4, 11)
    jr $ra
draw_doll_02_21: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 532($v0) # (5, 1)
    sw $0 540($v0) # (7, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1028($v0) # (1, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 1036($v0) # (3, 2)
    sw $0 1048($v0) # (6, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2052($v0) # (1, 4)
    sw $0 2080($v0) # (8, 4)
    sw $0 2592($v0) # (8, 5)
    sw $0 3616($v0) # (8, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4128($v0) # (8, 8)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5156($v0) # (9, 10)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010000
    sw $t4 16($v0) # (4, 0)
    sw $t4 520($v0) # (2, 1)
    sw $t4 1052($v0) # (7, 2)
    sw $t4 4132($v0) # (9, 8)
    sw $t4 5124($v0) # (1, 10)
    li $t4 0x020201
    sw $t4 524($v0) # (3, 1)
    li $t4 0x020101
    sw $t4 536($v0) # (6, 1)
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x020202
    sw $t4 1024($v0) # (0, 2)
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x050602
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x000100
    sw $t4 1044($v0) # (5, 2)
    sw $t4 1564($v0) # (7, 3)
    sw $t4 3104($v0) # (8, 6)
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x110207
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x954233
    sw $t4 1548($v0) # (3, 3)
    li $t4 0xbc383c
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xb6433b
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x431819
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x010101
    sw $t4 1568($v0) # (8, 3)
    sw $t4 2084($v0) # (9, 4)
    sw $t4 3108($v0) # (9, 6)
    sw $t4 4608($v0) # (0, 9)
    li $t4 0x2d2c2a
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x84472b
    sw $t4 2056($v0) # (2, 4)
    li $t4 0xfdb054
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xdf7c49
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xd77649
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xde914a
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x110403
    sw $t4 2076($v0) # (7, 4)
    li $t4 0xcbcbc9
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x8f8d96
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xaf6243
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xd57c4d
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x9a493c
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xb9604c
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xb53d44
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x4e2d31
    sw $t4 2588($v0) # (7, 5)
    li $t4 0xb8b7b7
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xe1edeb
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xa53958
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xb23a45
    sw $t4 3084($v0) # (3, 6)
    li $t4 0xc87b77
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xe19379
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x8f0b3e
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x584952
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x191818
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x8c6c7a
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x8e0f41
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x9a5d72
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x959284
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xa79190
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x984555
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x423b3c
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x020102
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x3d0918
    sw $t4 4100($v0) # (1, 8)
    li $t4 0xa02d4e
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x704153
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x8d536e
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x853655
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x3f2826
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x070000
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x281916
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x8f2043
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x621c38
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x967e85
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x8c5468
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x50001c
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x050204
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x010001
    sw $t4 5120($v0) # (0, 10)
    li $t4 0x53001b
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x953156
    sw $t4 5132($v0) # (3, 10)
    li $t4 0xdafdf1
    sw $t4 5136($v0) # (4, 10)
    li $t4 0xb58d9a
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x400112
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x030202
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x020001
    sw $t4 5152($v0) # (8, 10)
    sw $t4 5632($v0) # (0, 11)
    sw $t4 5664($v0) # (8, 11)
    li $t4 0x000200
    sw $t4 5636($v0) # (1, 11)
    li $t4 0x2d0513
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x7f1239
    sw $t4 5644($v0) # (3, 11)
    li $t4 0xc06784
    sw $t4 5648($v0) # (4, 11)
    li $t4 0xb21f4d
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x2b030e
    sw $t4 5656($v0) # (6, 11)
    jr $ra
draw_doll_03_00: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 536($v0) # (6, 1)
    sw $0 540($v0) # (7, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1056($v0) # (8, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1564($v0) # (7, 3)
    sw $0 1568($v0) # (8, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2084($v0) # (9, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 3612($v0) # (7, 7)
    sw $0 3620($v0) # (9, 7)
    sw $0 4128($v0) # (8, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4612($v0) # (1, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010000
    sw $t4 12($v0) # (3, 0)
    sw $t4 5148($v0) # (7, 10)
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x020000
    sw $t4 16($v0) # (4, 0)
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x000101
    sw $t4 24($v0) # (6, 0)
    sw $t4 4608($v0) # (0, 9)
    sw $t4 5120($v0) # (0, 10)
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x000401
    sw $t4 528($v0) # (4, 1)
    li $t4 0x000201
    sw $t4 532($v0) # (5, 1)
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x020202
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x030304
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x010302
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x2a2023
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x711a34
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x441f2a
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x090f0d
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x010101
    sw $t4 1052($v0) # (7, 2)
    sw $t4 2080($v0) # (8, 4)
    sw $t4 2592($v0) # (8, 5)
    sw $t4 2596($v0) # (9, 5)
    sw $t4 3104($v0) # (8, 6)
    sw $t4 3108($v0) # (9, 6)
    sw $t4 5124($v0) # (1, 10)
    li $t4 0x1c1f1d
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x4e4046
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x522935
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x2a2429
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x353636
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x6b637f
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x6a6379
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x1d1d1f
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x433835
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x223530
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x746042
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x1e1c19
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x2b2539
    sw $t4 2076($v0) # (7, 4)
    li $t4 0xccbff3
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xf2e7ff
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x383345
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x552a21
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xa4ae86
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xc7ac7d
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x26191d
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x4f426b
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x645e74
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xcfc4e4
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x445064
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x5a667f
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x9985a7
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xa996be
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x323950
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x2f283e
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x3c2633
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x4c7d70
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x215f62
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x9b407f
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x652d4b
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x455747
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x000001
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x030404
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x190d09
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x20271b
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x1d4e5e
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xae84c7
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x796292
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x23110e
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x080404
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x004628
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x267771
    sw $t4 4620($v0) # (3, 9)
    li $t4 0xefd8ff
    sw $t4 4624($v0) # (4, 9)
    li $t4 0xa5dbe2
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x002614
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x03211a
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x0f6853
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x3b857c
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x16875c
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x022010
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x0b0205
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x371f36
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x100c10
    sw $t4 5648($v0) # (4, 11)
    jr $ra
draw_doll_03_01: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 540($v0) # (7, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1028($v0) # (1, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1568($v0) # (8, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2076($v0) # (7, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 3108($v0) # (9, 6)
    sw $0 3616($v0) # (8, 7)
    sw $0 3620($v0) # (9, 7)
    sw $0 4132($v0) # (9, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x000200
    sw $t4 16($v0) # (4, 0)
    li $t4 0x000100
    sw $t4 520($v0) # (2, 1)
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x1d1819
    sw $t4 524($v0) # (3, 1)
    li $t4 0x591529
    sw $t4 528($v0) # (4, 1)
    li $t4 0x371922
    sw $t4 532($v0) # (5, 1)
    li $t4 0x030706
    sw $t4 536($v0) # (6, 1)
    li $t4 0x010101
    sw $t4 1024($v0) # (0, 2)
    sw $t4 2080($v0) # (8, 4)
    sw $t4 2592($v0) # (8, 5)
    sw $t4 2596($v0) # (9, 5)
    sw $t4 5124($v0) # (1, 10)
    li $t4 0x131716
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x4d3b41
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x67293a
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x372a31
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x343636
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x020202
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x030203
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x040304
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x1e1f1f
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x403b3a
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x0f2423
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x4b4334
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x2f2d2b
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x020203
    sw $t4 1564($v0) # (7, 3)
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x000101
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x643a2f
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x8fa179
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xbea977
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x1d140d
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x211e27
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x5c566b
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x171a25
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x5e5e78
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x928294
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x9d89a6
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x2d2842
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x3c334f
    sw $t4 2588($v0) # (7, 5)
    li $t4 0xc7bfea
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xe9cffa
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x437c70
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x316f76
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x903f86
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x6b405c
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x425550
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x3c2d49
    sw $t4 3100($v0) # (7, 6)
    li $t4 0xd2c8f9
    sw $t4 3584($v0) # (0, 7)
    li $t4 0xc2a8c8
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x2e2122
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x0f454c
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x995ea5
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x572e57
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x312017
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x090405
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x4a4559
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x17141e
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x001a0d
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x0a6955
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xe7d7ff
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x9dcbdb
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x001c0d
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x010000
    sw $t4 4124($v0) # (7, 8)
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x000201
    sw $t4 4128($v0) # (8, 8)
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x012117
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x097456
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x8294b4
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x35907d
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x022b12
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x020001
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x030304
    sw $t4 5120($v0) # (0, 10)
    li $t4 0x0b0507
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x35283e
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x0d1218
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x010100
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x030000
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x070000
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x020000
    sw $t4 5652($v0) # (5, 11)
    jr $ra
draw_doll_03_02: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 540($v0) # (7, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1056($v0) # (8, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1564($v0) # (7, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2056($v0) # (2, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 3616($v0) # (8, 7)
    sw $0 3620($v0) # (9, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4124($v0) # (7, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x000805
    sw $t4 16($v0) # (4, 0)
    li $t4 0x030404
    sw $t4 20($v0) # (5, 0)
    li $t4 0x020504
    sw $t4 520($v0) # (2, 1)
    li $t4 0x312327
    sw $t4 524($v0) # (3, 1)
    li $t4 0x791b37
    sw $t4 528($v0) # (4, 1)
    li $t4 0x47232e
    sw $t4 532($v0) # (5, 1)
    li $t4 0x101514
    sw $t4 536($v0) # (6, 1)
    li $t4 0x030304
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x010102
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x212322
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x4d4348
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x4a2f37
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x383438
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x373737
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x050506
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x181a19
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x4f3e3a
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x314841
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x8d7550
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x171610
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x000100
    sw $t4 1568($v0) # (8, 3)
    sw $t4 4640($v0) # (8, 9)
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x302c3a
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x18161d
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x5d3532
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xa3aa80
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xc0a681
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x221519
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x3c334f
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x020201
    sw $t4 2080($v0) # (8, 4)
    li $t4 0xc4bae2
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xd4c7ee
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x243c43
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x5d728c
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x9983b1
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xa391b9
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x60658e
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x4e456c
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x020102
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x010101
    sw $t4 2596($v0) # (9, 5)
    sw $t4 3108($v0) # (9, 6)
    li $t4 0xa7a0ca
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xe8cbf1
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x487163
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x165357
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x915694
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x772a4c
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x49574a
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x372a34
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x020101
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x65617a
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x3f3139
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x101b0d
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x2e5c6d
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xba8cd7
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x8970a8
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x130807
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x0b0300
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x00462c
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x368780
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x8ecfc8
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x6ec0bf
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x00332a
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x010202
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x030405
    sw $t4 4608($v0) # (0, 9)
    li $t4 0x020203
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x041a16
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x116655
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x00814d
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x007238
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x011e12
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x000101
    sw $t4 4636($v0) # (7, 9)
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x0a0204
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x2f1528
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x1c0310
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x030000
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x010000
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x000301
    sw $t4 5652($v0) # (5, 11)
    jr $ra
draw_doll_03_03: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 536($v0) # (6, 1)
    sw $0 540($v0) # (7, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1052($v0) # (7, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1540($v0) # (1, 3)
    sw $0 1568($v0) # (8, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2084($v0) # (9, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 4132($v0) # (9, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4636($v0) # (7, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 24($v0) # (6, 0)
    sw $t4 512($v0) # (0, 1)
    sw $t4 2080($v0) # (8, 4)
    sw $t4 2592($v0) # (8, 5)
    sw $t4 2596($v0) # (9, 5)
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x000302
    sw $t4 524($v0) # (3, 1)
    li $t4 0x0d0b0b
    sw $t4 528($v0) # (4, 1)
    li $t4 0x0b0808
    sw $t4 532($v0) # (5, 1)
    li $t4 0x010201
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x050807
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x3f2f34
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x732541
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x46323c
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x1a1e1d
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x191520
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x252726
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x443d41
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x5b352f
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x52362f
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x353434
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x040404
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xc5b8e3
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x7c758d
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x101312
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x5d3d32
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x8b8165
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xc89968
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x15130c
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x060609
    sw $t4 2076($v0) # (7, 4)
    li $t4 0xdacffb
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xdfd2ff
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x11081b
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x633c3a
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xb0b492
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xb0a68a
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x382935
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x5e4e7d
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x666177
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xa799bd
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x34575e
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x4e7286
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x8b6895
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x884f80
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x586584
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x2a2c3f
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x040305
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x000101
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x2d161a
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x526c61
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x15474a
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x8a5290
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x641a4d
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x1b3627
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x3c2d27
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x010001
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x020201
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x030404
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x0e0806
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x082111
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x56708f
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xbbafe8
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x979cd0
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x12191e
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x0c0404
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x000402
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x006044
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x008e5b
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x00b667
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x05b86c
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x005a3d
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x000100
    sw $t4 4640($v0) # (8, 9)
    sw $t4 5124($v0) # (1, 10)
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x041f16
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x0c4b2d
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x096538
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x00562f
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x00180e
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x020000
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x070000
    sw $t4 5644($v0) # (3, 11)
    sw $t4 5648($v0) # (4, 11)
    jr $ra
draw_doll_03_04: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 516($v0) # (1, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1544($v0) # (2, 3)
    sw $0 1564($v0) # (7, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2084($v0) # (9, 4)
    sw $0 2596($v0) # (9, 5)
    sw $0 3108($v0) # (9, 6)
    sw $0 3612($v0) # (7, 7)
    sw $0 3620($v0) # (9, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4616($v0) # (2, 9)
    sw $0 4632($v0) # (6, 9)
    sw $0 4636($v0) # (7, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 4($v0) # (1, 0)
    sw $t4 512($v0) # (0, 1)
    sw $t4 548($v0) # (9, 1)
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x161918
    sw $t4 12($v0) # (3, 0)
    li $t4 0x631b31
    sw $t4 16($v0) # (4, 0)
    li $t4 0x5d1e31
    sw $t4 20($v0) # (5, 0)
    li $t4 0x0e1311
    sw $t4 24($v0) # (6, 0)
    li $t4 0x080909
    sw $t4 520($v0) # (2, 1)
    li $t4 0x423e40
    sw $t4 524($v0) # (3, 1)
    li $t4 0x592b39
    sw $t4 528($v0) # (4, 1)
    li $t4 0x38252e
    sw $t4 532($v0) # (5, 1)
    li $t4 0x343738
    sw $t4 536($v0) # (6, 1)
    li $t4 0x101010
    sw $t4 540($v0) # (7, 1)
    li $t4 0x020202
    sw $t4 1024($v0) # (0, 2)
    sw $t4 4608($v0) # (0, 9)
    li $t4 0x030303
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x0d0d0e
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x413836
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x233130
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x444431
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x312e28
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x0d0e0e
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x010100
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x431f1c
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x8c8768
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xd1c993
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x483627
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x010000
    sw $t4 1568($v0) # (8, 3)
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x1c1a22
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x423c4e
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x2f3048
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x354454
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xa498b4
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x8c7a93
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x8475a6
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x514574
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x0a0a0e
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x8b84a6
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xecd2ff
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x7b8a98
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x0d5948
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xa794c7
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xa13b6b
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x3d616a
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x3b4b44
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x160a10
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x8b82a7
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xd5c6e8
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x3c2725
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x043b30
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x817bb4
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xa476b4
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x000b12
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x3d281d
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x0b0504
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x2d2938
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x18151f
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x000805
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x006341
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xbabedd
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xcfd1fd
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x06473b
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x000102
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x040b09
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x025c3b
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x419b89
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x3e9783
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x003f1f
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x030101
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x000201
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x020203
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x1b161a
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x16251f
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x000d04
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x050000
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x040000
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x000101
    sw $t4 5144($v0) # (6, 10)
    sw $t4 5648($v0) # (4, 11)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x000001
    sw $t4 5644($v0) # (3, 11)
    jr $ra
draw_doll_03_05: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1544($v0) # (2, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2596($v0) # (9, 5)
    sw $0 3108($v0) # (9, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 3588($v0) # (1, 7)
    sw $0 3616($v0) # (8, 7)
    sw $0 4132($v0) # (9, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4620($v0) # (3, 9)
    sw $0 4636($v0) # (7, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5136($v0) # (4, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 4($v0) # (1, 0)
    sw $t4 512($v0) # (0, 1)
    sw $t4 516($v0) # (1, 1)
    sw $t4 520($v0) # (2, 1)
    sw $t4 544($v0) # (8, 1)
    sw $t4 548($v0) # (9, 1)
    li $t4 0x090f0d
    sw $t4 12($v0) # (3, 0)
    li $t4 0x4e202e
    sw $t4 16($v0) # (4, 0)
    li $t4 0x6f1c34
    sw $t4 20($v0) # (5, 0)
    li $t4 0x1f1b1c
    sw $t4 24($v0) # (6, 0)
    li $t4 0x020303
    sw $t4 28($v0) # (7, 0)
    li $t4 0x383a3a
    sw $t4 524($v0) # (3, 1)
    li $t4 0x58333e
    sw $t4 528($v0) # (4, 1)
    li $t4 0x44232f
    sw $t4 532($v0) # (5, 1)
    li $t4 0x2e3032
    sw $t4 536($v0) # (6, 1)
    li $t4 0x232324
    sw $t4 540($v0) # (7, 1)
    li $t4 0x050505
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x3b3534
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x2a2e2e
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x424837
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x5c4734
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x060807
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x0e0c12
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x06040a
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x200d0c
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x7e6550
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xc1cc97
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x7d6245
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x14101e
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x1d1925
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x554d67
    sw $t4 2048($v0) # (0, 4)
    li $t4 0xc5bbd8
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x6c6787
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x12242b
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x9f9ab8
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x8c7c93
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x8879a3
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x544a7b
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x2d293f
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x000001
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x2c2937
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xe6d6ff
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xbfb4cd
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x105d43
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x67769e
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x9d326e
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x4f4354
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x275f50
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x2d1b24
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x343040
    sw $t4 3072($v0) # (0, 6)
    li $t4 0x847d94
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x402a2a
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x093324
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x586395
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xbc87c4
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x2c223d
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x140f08
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x190a0a
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x000904
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x006642
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x8698b9
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xfef8ff
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x3e9386
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x000401
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x000101
    sw $t4 3620($v0) # (9, 7)
    sw $t4 5132($v0) # (3, 10)
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x010202
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x030404
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x040807
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x00412a
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x217f6a
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x50a09b
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x016e3f
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x010906
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x010100
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x010000
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x1f1723
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x302436
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x030000
    sw $t4 4632($v0) # (6, 9)
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x010201
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x000102
    sw $t4 5652($v0) # (5, 11)
    jr $ra
draw_doll_03_06: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 1028($v0) # (1, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1572($v0) # (9, 3)
    sw $0 2084($v0) # (9, 4)
    sw $0 2596($v0) # (9, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3076($v0) # (1, 6)
    sw $0 3108($v0) # (9, 6)
    sw $0 4100($v0) # (1, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 4636($v0) # (7, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x1a1315
    sw $t4 16($v0) # (4, 0)
    li $t4 0x491423
    sw $t4 20($v0) # (5, 0)
    li $t4 0x221216
    sw $t4 24($v0) # (6, 0)
    li $t4 0x020201
    sw $t4 516($v0) # (1, 1)
    li $t4 0x020202
    sw $t4 520($v0) # (2, 1)
    li $t4 0x191e1d
    sw $t4 524($v0) # (3, 1)
    li $t4 0x5a3943
    sw $t4 528($v0) # (4, 1)
    li $t4 0x772b41
    sw $t4 532($v0) # (5, 1)
    li $t4 0x3f373c
    sw $t4 536($v0) # (6, 1)
    li $t4 0x2a2c2c
    sw $t4 540($v0) # (7, 1)
    li $t4 0x020203
    sw $t4 544($v0) # (8, 1)
    li $t4 0x010101
    sw $t4 548($v0) # (9, 1)
    li $t4 0x030203
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x3a3939
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x37383b
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x202d2b
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x504236
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x212121
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x000100
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x1e1a27
    sw $t4 1536($v0) # (0, 3)
    li $t4 0xaca2c3
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x363240
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x0f0e0b
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x6c473a
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x8ba279
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xb49661
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x0e0a0d
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x272133
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x1a1623
    sw $t4 2048($v0) # (0, 4)
    li $t4 0xdcd1fc
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xede5ff
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x3a314c
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x594b58
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xafa3a5
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x907d91
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x4e3a62
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x54456e
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x0c0a0f
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x928ca9
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xbaa4cc
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x436c6d
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x2f7777
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x8f5390
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x7d4c76
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x34706f
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x1f252a
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x1c0909
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x44493b
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x23526a
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x9c5b9a
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x4e2648
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x001e0f
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x2a1e19
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x000101
    sw $t4 3584($v0) # (0, 7)
    sw $t4 3620($v0) # (9, 7)
    sw $t4 4096($v0) # (0, 8)
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x020302
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x010907
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x004b29
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x527991
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xffe6ff
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x85a9bf
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x010c04
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x010000
    sw $t4 3616($v0) # (8, 7)
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x020b09
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x026240
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x179569
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x88b9bd
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x2db784
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x00321a
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x020101
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x000201
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x000404
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x00180d
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x304558
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x152025
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x010102
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x100000
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x0b0000
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x000001
    sw $t4 5652($v0) # (5, 11)
    jr $ra
draw_doll_03_07: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 3588($v0) # (1, 7)
    sw $0 3592($v0) # (2, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4128($v0) # (8, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x000603
    sw $t4 20($v0) # (5, 0)
    li $t4 0x030504
    sw $t4 24($v0) # (6, 0)
    li $t4 0x020202
    sw $t4 516($v0) # (1, 1)
    li $t4 0x020102
    sw $t4 520($v0) # (2, 1)
    li $t4 0x000100
    sw $t4 524($v0) # (3, 1)
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x292425
    sw $t4 528($v0) # (4, 1)
    li $t4 0x6d213b
    sw $t4 532($v0) # (5, 1)
    li $t4 0x512536
    sw $t4 536($v0) # (6, 1)
    li $t4 0x111816
    sw $t4 540($v0) # (7, 1)
    li $t4 0x202222
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x494146
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x4c292c
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x543a34
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x3e3d3d
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x111112
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x322d3d
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x1b1821
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x111512
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x704e44
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x696c55
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xcb9a68
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x322920
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x070908
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x010101
    sw $t4 1572($v0) # (9, 3)
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x756c8b
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xc9bedb
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x272333
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x371819
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xb49f83
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xc9b38b
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x2d2020
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x554671
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x070608
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x564f68
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xffffff
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x716b88
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x245150
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x7d83a5
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x8e6f9b
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x717096
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x3d385a
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x08080b
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x151319
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x4d4a5b
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x764747
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x45706d
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x4a3f62
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x751140
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x0b4c3c
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x264133
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x070101
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x002112
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x145352
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xb396da
    sw $t4 3604($v0) # (5, 7)
    li $t4 0xb79fce
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x191222
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x150c09
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x040202
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x040304
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x00613f
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x0da269
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x9cb6ca
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xb0d4dc
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x1c614d
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x010202
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x011b12
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x00321b
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x001f1a
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x515797
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x1f2d3f
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x010100
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x010102
    sw $t4 4644($v0) # (9, 9)
    li $t4 0x010000
    sw $t4 5136($v0) # (4, 10)
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x351e30
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x24111e
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x010001
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x000101
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x000201
    sw $t4 5648($v0) # (4, 11)
    sw $t4 5652($v0) # (5, 11)
    jr $ra
draw_doll_03_08: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 3588($v0) # (1, 7)
    sw $0 3592($v0) # (2, 7)
    sw $0 3596($v0) # (3, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5140($v0) # (5, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 32($v0) # (8, 0)
    sw $t4 520($v0) # (2, 1)
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x010201
    sw $t4 528($v0) # (4, 1)
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x150e10
    sw $t4 532($v0) # (5, 1)
    li $t4 0x30181f
    sw $t4 536($v0) # (6, 1)
    li $t4 0x110d0d
    sw $t4 540($v0) # (7, 1)
    li $t4 0x0d0d0e
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x2d3130
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x4f4448
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x643344
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x3b3b3e
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x252525
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x010102
    sw $t4 1060($v0) # (9, 2)
    sw $t4 4644($v0) # (9, 9)
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x040405
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x0f0c15
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x050603
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x454444
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x614848
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x69503b
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x523b2c
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x171a1a
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x010000
    sw $t4 1572($v0) # (9, 3)
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x0f0c14
    sw $t4 2052($v0) # (1, 4)
    li $t4 0xb7add6
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x484457
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x1b1312
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x9f735b
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xc7d29b
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x9f8052
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x130f1c
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x0f0c12
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x060409
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xc6bce5
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xeee2ff
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x101224
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x584e57
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xaaa399
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x7b666f
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x5d497c
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x282335
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x020202
    sw $t4 3072($v0) # (0, 6)
    li $t4 0x030204
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x706a82
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x706782
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x5f403b
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x8296b5
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x986198
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x635d7f
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x27444a
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x130c14
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x253121
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x2a5168
    sw $t4 3604($v0) # (5, 7)
    li $t4 0xa7468c
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x44243f
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x252d22
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x070000
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x000101
    sw $t4 4100($v0) # (1, 8)
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x030303
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x041914
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x007345
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x44908e
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x7da2c1
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x6ca1ab
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x2b2434
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x010b08
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x013d22
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x214951
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x746ebb
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x1a4b53
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x000401
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x020000
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x5a446f
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x5d3b75
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x010001
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x050000
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x110902
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x020101
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_03_09: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 532($v0) # (5, 1)
    sw $0 536($v0) # (6, 1)
    sw $0 540($v0) # (7, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1544($v0) # (2, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2060($v0) # (3, 4)
    sw $0 2564($v0) # (1, 5)
    sw $0 3076($v0) # (1, 6)
    sw $0 3588($v0) # (1, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4104($v0) # (2, 8)
    sw $0 4108($v0) # (3, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 20($v0) # (5, 0)
    sw $t4 28($v0) # (7, 0)
    sw $t4 1032($v0) # (2, 2)
    sw $t4 1036($v0) # (3, 2)
    sw $t4 1548($v0) # (3, 3)
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x020001
    sw $t4 24($v0) # (6, 0)
    li $t4 0x020202
    sw $t4 1040($v0) # (4, 2)
    sw $t4 2560($v0) # (0, 5)
    sw $t4 3584($v0) # (0, 7)
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x161414
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x401c28
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x2c1e22
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x000201
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x1e1e1e
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x4b4e4f
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x60343f
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x42393e
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x323434
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x0c0c0d
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x040307
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x2d3130
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x70524f
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x695847
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x7e5b3d
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x141618
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x030400
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x9086ab
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x666074
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x0a080b
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x784537
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xc0c193
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xceb078
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x13110e
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x302941
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x030303
    sw $t4 3072($v0) # (0, 6)
    li $t4 0x8980a2
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xfff9ff
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x31334b
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x2e3340
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x948c98
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x9b899b
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x524164
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x5f4e7f
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x534f63
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xaaa1ba
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x7d5f66
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x3f897f
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x704674
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x82396a
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x316c6c
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x233133
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x30281c
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x26495c
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x9262a4
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x704069
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x05241a
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x2d251c
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x000100
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x020806
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x006141
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x009657
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x8ab0c7
    sw $t4 4632($v0) # (6, 9)
    li $t4 0xf3f4ff
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x655d76
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x000303
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x034d32
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x007340
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x1d6658
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x637296
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x0a1717
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x010000
    sw $t4 5648($v0) # (4, 11)
    sw $t4 5664($v0) # (8, 11)
    li $t4 0x18070e
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x1f0d15
    sw $t4 5660($v0) # (7, 11)
    jr $ra
draw_doll_03_10: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 532($v0) # (5, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 1036($v0) # (3, 2)
    sw $0 1040($v0) # (4, 2)
    sw $0 1044($v0) # (5, 2)
    sw $0 1048($v0) # (6, 2)
    sw $0 1052($v0) # (7, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1552($v0) # (4, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2056($v0) # (2, 4)
    sw $0 2060($v0) # (3, 4)
    sw $0 2564($v0) # (1, 5)
    sw $0 3076($v0) # (1, 6)
    sw $0 3588($v0) # (1, 7)
    sw $0 4100($v0) # (1, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 4620($v0) # (3, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5644($v0) # (3, 11)
    li $t4 0x020101
    sw $t4 536($v0) # (6, 1)
    li $t4 0x020001
    sw $t4 540($v0) # (7, 1)
    li $t4 0x000001
    sw $t4 1544($v0) # (2, 3)
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x010102
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x070a09
    sw $t4 1556($v0) # (5, 3)
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x30121b
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x33151e
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x000201
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x3c3739
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x75203a
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x4f2333
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x2d3332
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x0b0a0b
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x0c0a0f
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x0f0c15
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x0d0d0c
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x524747
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x192627
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x2b291e
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x362f2d
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x131512
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x020203
    sw $t4 3072($v0) # (0, 6)
    li $t4 0x292432
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xc2b7dc
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x24252f
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x573226
    sw $t4 3092($v0) # (5, 6)
    li $t4 0xac967a
    sw $t4 3096($v0) # (6, 6)
    li $t4 0xdac187
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x382e1b
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x262136
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x020102
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x131119
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xede1ff
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x807ca0
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x050910
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x92868e
    sw $t4 3608($v0) # (6, 7)
    li $t4 0xa29498
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x5b4761
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x7d63a5
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x010001
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x0a080c
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x847c95
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x8a6d7b
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x45776e
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x6e879a
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x86386d
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x5d7e8f
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x1f3c3e
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x2e160f
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x324e51
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x5a5081
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x893b73
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x001213
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x263624
    sw $t4 4644($v0) # (9, 9)
    li $t4 0x000101
    sw $t4 5128($v0) # (2, 10)
    sw $t4 5640($v0) # (2, 11)
    sw $t4 5668($v0) # (9, 11)
    li $t4 0x030304
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x003225
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x007643
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x6095a4
    sw $t4 5144($v0) # (6, 10)
    li $t4 0xf3e6ff
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x897da6
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x033427
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x02844d
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x1c9f73
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x70b8a7
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x3d615e
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_03_11: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 532($v0) # (5, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 1036($v0) # (3, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1548($v0) # (3, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 2564($v0) # (1, 5)
    sw $0 2568($v0) # (2, 5)
    sw $0 2572($v0) # (3, 5)
    sw $0 3588($v0) # (1, 7)
    sw $0 4100($v0) # (1, 8)
    sw $0 4612($v0) # (1, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010000
    sw $t4 20($v0) # (5, 0)
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x020000
    sw $t4 24($v0) # (6, 0)
    li $t4 0x000101
    sw $t4 32($v0) # (8, 0)
    li $t4 0x000501
    sw $t4 536($v0) # (6, 1)
    li $t4 0x000201
    sw $t4 540($v0) # (7, 1)
    li $t4 0x010302
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x2e2125
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x721a34
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x3f2029
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x080d0c
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x010101
    sw $t4 1544($v0) # (2, 3)
    sw $t4 3072($v0) # (0, 6)
    sw $t4 3076($v0) # (1, 6)
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x222524
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x4e3e44
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x512834
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x29252a
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x333434
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x030303
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x020202
    sw $t4 2056($v0) # (2, 4)
    sw $t4 4608($v0) # (0, 9)
    li $t4 0x020203
    sw $t4 2060($v0) # (3, 4)
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x1f201e
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x423836
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x233731
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x765f42
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x181614
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x010202
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x0c080e
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x653a31
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xa5b085
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xc6aa7d
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x130b0b
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x060507
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x100f14
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x796f8a
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x262f3f
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x5f6e86
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x927ea3
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x9277a8
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x42405b
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x4b4068
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x020303
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x8b82a6
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xd2c5ec
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x695452
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x528593
    sw $t4 3604($v0) # (5, 7)
    li $t4 0xa34c8d
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x562a47
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x0d5742
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x303b38
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x030304
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x6d6584
    sw $t4 4104($v0) # (2, 8)
    li $t4 0xc4b8de
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x322318
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x1f5756
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x82639f
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x9272a6
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x262632
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x1e120e
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x282731
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x332b3b
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x002216
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x00854a
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x499296
    sw $t4 4632($v0) # (6, 9)
    li $t4 0xfff6ff
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x728091
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x031410
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x015738
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x0a8353
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x4a9394
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x083f2b
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x020102
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x0f060b
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x37253a
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x080003
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_03_12: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1036($v0) # (3, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2060($v0) # (3, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 2564($v0) # (1, 5)
    sw $0 4096($v0) # (0, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 4620($v0) # (3, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010000
    sw $t4 32($v0) # (8, 0)
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x0c0d0d
    sw $t4 532($v0) # (5, 1)
    li $t4 0x30101a
    sw $t4 536($v0) # (6, 1)
    li $t4 0x1f0f14
    sw $t4 540($v0) # (7, 1)
    li $t4 0x010101
    sw $t4 1032($v0) # (2, 2)
    sw $t4 3072($v0) # (0, 6)
    sw $t4 4644($v0) # (9, 9)
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x0d1210
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x50363e
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x822640
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x422c34
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x252928
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x020102
    sw $t4 1544($v0) # (2, 3)
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x252525
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x383739
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x111b1c
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x332e2a
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x323131
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x020203
    sw $t4 1572($v0) # (9, 3)
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x010100
    sw $t4 2056($v0) # (2, 4)
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x0b0d0b
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x674236
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x6c8569
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xae9b69
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x17130c
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x000001
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x000002
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x23202a
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x05050b
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x604c5c
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xa0998a
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x9c8089
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x24182a
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x282235
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x09070c
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xa69ec0
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xdacaf6
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x4c4f5d
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x68a0ac
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x8d528b
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x644777
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x394f56
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x4b3b60
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x0e0b12
    sw $t4 3588($v0) # (1, 7)
    li $t4 0xd4c7f8
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xdacdf6
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x895f5c
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x315d69
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x8b3a7d
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x471334
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x443428
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x110a10
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x08070c
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x7e7796
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x3d3744
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x000d05
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x006f48
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xa2abd6
    sw $t4 4120($v0) # (6, 8)
    li $t4 0xd2c7f6
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x040d16
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x042c23
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x01a559
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x66b2ac
    sw $t4 4632($v0) # (6, 9)
    li $t4 0xb5b7df
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x041e1b
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x030304
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x010404
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x001e12
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x1d3b3e
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x333355
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x000401
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x0e0001
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x160805
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x020000
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_03_13: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1036($v0) # (3, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2056($v0) # (2, 4)
    sw $0 2060($v0) # (3, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4104($v0) # (2, 8)
    sw $0 4108($v0) # (3, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x000200
    sw $t4 24($v0) # (6, 0)
    li $t4 0x000101
    sw $t4 528($v0) # (4, 1)
    li $t4 0x1f181a
    sw $t4 532($v0) # (5, 1)
    li $t4 0x591529
    sw $t4 536($v0) # (6, 1)
    li $t4 0x32171f
    sw $t4 540($v0) # (7, 1)
    li $t4 0x010504
    sw $t4 544($v0) # (8, 1)
    li $t4 0x010101
    sw $t4 1032($v0) # (2, 2)
    sw $t4 1060($v0) # (9, 2)
    sw $t4 2560($v0) # (0, 5)
    sw $t4 5664($v0) # (8, 11)
    li $t4 0x171b1a
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x523c43
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x682b3c
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x40353b
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x393b3a
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x020201
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x030303
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x252525
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x413d3c
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x132726
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x544b3c
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x343332
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x020202
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x101111
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x693e33
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x91a67d
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xbda774
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x140c07
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x060409
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x9f98b6
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x877f9a
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x00030a
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x6a6c83
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x8f7e8c
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x876d94
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x1e1d2e
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x2d263b
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x010100
    sw $t4 3072($v0) # (0, 6)
    li $t4 0x0d0a13
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xd6ccf6
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xfbefff
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x736670
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x5d9da1
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x8e3e7a
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x532b50
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x3f524c
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x3b2d49
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x0a080e
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x998fb5
    sw $t4 3592($v0) # (2, 7)
    li $t4 0xa69db8
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x5e403b
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x284d60
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x9a57a5
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x5a3458
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x331c18
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x070304
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x002f1a
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x06895d
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xbcc0ea
    sw $t4 4120($v0) # (6, 8)
    li $t4 0xe4e4ff
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x022927
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x010302
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x020302
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x04412e
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x009f54
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x29a07a
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x4c8b93
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x02291b
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x010001
    sw $t4 4644($v0) # (9, 9)
    li $t4 0x010000
    sw $t4 5136($v0) # (4, 10)
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x000003
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x1c2026
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x2c2738
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x040000
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x080000
    sw $t4 5660($v0) # (7, 11)
    jr $ra
draw_doll_03_14: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 524($v0) # (3, 1)
    sw $0 528($v0) # (4, 1)
    sw $0 532($v0) # (5, 1)
    sw $0 540($v0) # (7, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1544($v0) # (2, 3)
    sw $0 1548($v0) # (3, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 3584($v0) # (0, 7)
    sw $0 3592($v0) # (2, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010000
    sw $t4 20($v0) # (5, 0)
    sw $t4 24($v0) # (6, 0)
    li $t4 0x000100
    sw $t4 32($v0) # (8, 0)
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x000400
    sw $t4 536($v0) # (6, 1)
    li $t4 0x020202
    sw $t4 1032($v0) # (2, 2)
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x020302
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x2b2326
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x651c35
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x3a272e
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x090c0c
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x2e3130
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x4d4045
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x5d2b32
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x3e3132
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x363737
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x040405
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x0a080e
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x9c91b7
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x46424f
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x252826
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x4b3733
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x7e654e
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xad7853
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x141311
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x010100
    sw $t4 2560($v0) # (0, 5)
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x0c0a12
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xd9cefa
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xcabeec
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x000004
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x744434
    sw $t4 2580($v0) # (5, 5)
    li $t4 0xaebb8f
    sw $t4 2584($v0) # (6, 5)
    li $t4 0xbaa87b
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x22191d
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x51446b
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x010101
    sw $t4 3072($v0) # (0, 6)
    sw $t4 4100($v0) # (1, 8)
    sw $t4 5156($v0) # (9, 10)
    li $t4 0x060409
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x9d97b5
    sw $t4 3080($v0) # (2, 6)
    li $t4 0xc4b8e1
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x22323e
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x65708d
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x967f98
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x97769a
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x575479
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x3f395b
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x4c3543
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x558981
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x174f50
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x7c3c75
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x5b0b39
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x275044
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x342b29
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x010201
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x1c0e09
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x192215
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x45607c
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xc39ce6
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x816bab
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x120c0a
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x1f0f0d
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x000101
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x000403
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x005a3c
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x398d85
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x69c6b0
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x5bcbb2
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x02533b
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x010403
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x01392a
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x006d3b
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x009046
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x008742
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x01321e
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x040000
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x140104
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x130001
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x030000
    sw $t4 5664($v0) # (8, 11)
    jr $ra
draw_doll_03_15: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1544($v0) # (2, 3)
    sw $0 1548($v0) # (3, 3)
    sw $0 1568($v0) # (8, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 3616($v0) # (8, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4104($v0) # (2, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5136($v0) # (4, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x050a09
    sw $t4 16($v0) # (4, 0)
    li $t4 0x33141e
    sw $t4 20($v0) # (5, 0)
    li $t4 0x441724
    sw $t4 24($v0) # (6, 0)
    li $t4 0x080908
    sw $t4 28($v0) # (7, 0)
    li $t4 0x020202
    sw $t4 524($v0) # (3, 1)
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x323232
    sw $t4 528($v0) # (4, 1)
    li $t4 0x702c41
    sw $t4 532($v0) # (5, 1)
    li $t4 0x582535
    sw $t4 536($v0) # (6, 1)
    li $t4 0x313636
    sw $t4 540($v0) # (7, 1)
    li $t4 0x111111
    sw $t4 544($v0) # (8, 1)
    li $t4 0x0a090a
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x3f3c3d
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x1a2325
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x222722
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x453c37
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x111214
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x010001
    sw $t4 1060($v0) # (9, 2)
    li $t4 0x41261f
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x756d57
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xaab480
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x655136
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x2e2934
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x201f2b
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x211d2c
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x93848f
    sw $t4 2068($v0) # (5, 4)
    li $t4 0xa29499
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x54435b
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x2a233a
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x131017
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x5f5870
    sw $t4 2564($v0) # (1, 5)
    li $t4 0xe9e1ff
    sw $t4 2568($v0) # (2, 5)
    li $t4 0xa188af
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x43726c
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x857eb6
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x772862
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x536770
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x42364f
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x1e1928
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x746a8b
    sw $t4 3076($v0) # (1, 6)
    li $t4 0xf0e9ff
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x9f7a8d
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x424840
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x5b5b89
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x7e2862
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x39292c
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x2d1a1a
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x000102
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x403a4e
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x585365
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x000003
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x005229
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x3d908b
    sw $t4 3604($v0) # (5, 7)
    li $t4 0xfbe7ff
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x5a6680
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x040203
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x020505
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x027045
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x0faa6f
    sw $t4 4116($v0) # (5, 8)
    li $t4 0xabb0d7
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x3f5e69
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x010101
    sw $t4 4128($v0) # (8, 8)
    sw $t4 4644($v0) # (9, 9)
    li $t4 0x020203
    sw $t4 4132($v0) # (9, 8)
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x030304
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x000001
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x000706
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x031c11
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x383a5a
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x0e0d15
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x020000
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x0f0300
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x080201
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x000100
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x000101
    sw $t4 5652($v0) # (5, 11)
    jr $ra
draw_doll_03_16: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 2052($v0) # (1, 4)
    sw $0 2080($v0) # (8, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 2564($v0) # (1, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3076($v0) # (1, 6)
    sw $0 3080($v0) # (2, 6)
    sw $0 3084($v0) # (3, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 3616($v0) # (8, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4104($v0) # (2, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 4624($v0) # (4, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5136($v0) # (4, 10)
    sw $0 5140($v0) # (5, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 8($v0) # (2, 0)
    sw $t4 516($v0) # (1, 1)
    sw $t4 520($v0) # (2, 1)
    sw $t4 1028($v0) # (1, 2)
    sw $t4 1540($v0) # (1, 3)
    sw $t4 5148($v0) # (7, 10)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x2d2e2d
    sw $t4 16($v0) # (4, 0)
    li $t4 0x3c3a3a
    sw $t4 20($v0) # (5, 0)
    li $t4 0x471021
    sw $t4 24($v0) # (6, 0)
    li $t4 0x0e0f0f
    sw $t4 28($v0) # (7, 0)
    li $t4 0x111111
    sw $t4 524($v0) # (3, 1)
    li $t4 0x636363
    sw $t4 528($v0) # (4, 1)
    li $t4 0x565556
    sw $t4 532($v0) # (5, 1)
    li $t4 0x423138
    sw $t4 536($v0) # (6, 1)
    li $t4 0x383a3b
    sw $t4 540($v0) # (7, 1)
    li $t4 0x090808
    sw $t4 544($v0) # (8, 1)
    li $t4 0x222322
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x545455
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x4c4747
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x373029
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x24201d
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x080808
    sw $t4 1056($v0) # (8, 2)
    li $t4 0x010000
    sw $t4 1060($v0) # (9, 2)
    sw $t4 1568($v0) # (8, 3)
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x000001
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x0d0a13
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x333136
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x292c2c
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x413735
    sw $t4 1556($v0) # (5, 3)
    li $t4 0xa47657
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x442d21
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x030202
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x030304
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x4f4765
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x3c3943
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x1b1c18
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x565568
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x9c8ec4
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x655f7f
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x020202
    sw $t4 2084($v0) # (9, 4)
    li $t4 0x0c0b10
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x131215
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x090a07
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x9681b8
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x927eb5
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x2d644f
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x2d342a
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x040101
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x070405
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x3f5a6c
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x3c557b
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x140b1a
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x311b18
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x030102
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x000201
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x010001
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x00291d
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x036445
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x008a3c
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x43a693
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x4a4969
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x020303
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x000101
    sw $t4 4100($v0) # (1, 8)
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x01291e
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x005131
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x346276
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x38617f
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x00341e
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x030101
    sw $t4 4128($v0) # (8, 8)
    li $t4 0x230f24
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x462849
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x070000
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x000102
    sw $t4 5656($v0) # (6, 11)
    jr $ra
draw_doll_03_17: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2056($v0) # (2, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 3076($v0) # (1, 6)
    sw $0 3104($v0) # (8, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 3592($v0) # (2, 7)
    sw $0 3616($v0) # (8, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4620($v0) # (3, 9)
    sw $0 4636($v0) # (7, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5140($v0) # (5, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x0a0d0c
    sw $t4 12($v0) # (3, 0)
    li $t4 0x430f1f
    sw $t4 16($v0) # (4, 0)
    li $t4 0x3c3437
    sw $t4 20($v0) # (5, 0)
    li $t4 0x323433
    sw $t4 24($v0) # (6, 0)
    li $t4 0x010101
    sw $t4 28($v0) # (7, 0)
    sw $t4 544($v0) # (8, 1)
    sw $t4 548($v0) # (9, 1)
    sw $t4 1060($v0) # (9, 2)
    sw $t4 1572($v0) # (9, 3)
    sw $t4 2564($v0) # (1, 5)
    sw $t4 2596($v0) # (9, 5)
    li $t4 0x040404
    sw $t4 520($v0) # (2, 1)
    li $t4 0x343737
    sw $t4 524($v0) # (3, 1)
    li $t4 0x45333a
    sw $t4 528($v0) # (4, 1)
    li $t4 0x585355
    sw $t4 532($v0) # (5, 1)
    li $t4 0x666767
    sw $t4 536($v0) # (6, 1)
    li $t4 0x191919
    sw $t4 540($v0) # (7, 1)
    li $t4 0x060606
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x25201d
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x22221d
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x2d302e
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x5a5a59
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x313130
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x020101
    sw $t4 1540($v0) # (1, 3)
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x010000
    sw $t4 1544($v0) # (2, 3)
    sw $t4 3072($v0) # (0, 6)
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x39241b
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x805e45
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x635e78
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x59555f
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x29292a
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x110f17
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x020203
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x5a5574
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x696373
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xb0a7ce
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x585369
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x45424c
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x363045
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x000101
    sw $t4 2560($v0) # (0, 5)
    sw $t4 3588($v0) # (1, 7)
    sw $t4 3620($v0) # (9, 7)
    sw $t4 4100($v0) # (1, 8)
    sw $t4 4132($v0) # (9, 8)
    sw $t4 5132($v0) # (3, 10)
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x2c2c23
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x337261
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x3a3c3d
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x3e3153
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x231e24
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x141317
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x020104
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x301916
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x090208
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x052628
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x003f2a
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x063325
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x000a06
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x000100
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x072a25
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x05b06b
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x009751
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x00714a
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x003626
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x002315
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x006c3a
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x3b6e87
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x1f4d56
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x002416
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x010001
    sw $t4 4128($v0) # (8, 8)
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x090000
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x4a274d
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x1c0e1d
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x010201
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x000102
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x000001
    sw $t4 5656($v0) # (6, 11)
    jr $ra
draw_doll_03_18: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 516($v0) # (1, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1028($v0) # (1, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 2568($v0) # (2, 5)
    sw $0 2596($v0) # (9, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3108($v0) # (9, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 3592($v0) # (2, 7)
    sw $0 3616($v0) # (8, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x0b0507
    sw $t4 12($v0) # (3, 0)
    li $t4 0x451322
    sw $t4 16($v0) # (4, 0)
    li $t4 0x292123
    sw $t4 20($v0) # (5, 0)
    li $t4 0x0e100f
    sw $t4 24($v0) # (6, 0)
    li $t4 0x010101
    sw $t4 512($v0) # (0, 1)
    sw $t4 1024($v0) # (0, 2)
    sw $t4 1060($v0) # (9, 2)
    sw $t4 4128($v0) # (8, 8)
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x101010
    sw $t4 520($v0) # (2, 1)
    li $t4 0x312e30
    sw $t4 524($v0) # (3, 1)
    li $t4 0x72283e
    sw $t4 528($v0) # (4, 1)
    li $t4 0x5d3a45
    sw $t4 532($v0) # (5, 1)
    li $t4 0x474c4a
    sw $t4 536($v0) # (6, 1)
    li $t4 0x060606
    sw $t4 540($v0) # (7, 1)
    li $t4 0x020202
    sw $t4 544($v0) # (8, 1)
    sw $t4 2052($v0) # (1, 4)
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x141514
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x33302e
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x242e2a
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x242828
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x585756
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x0d0d0c
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x030202
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x040409
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x7d5842
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x949c7a
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x2a3531
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x363435
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x767085
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x4f4860
    sw $t4 1568($v0) # (8, 3)
    li $t4 0x12101a
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x524159
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x8f827f
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x2f2a2b
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x232327
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xd0c4f2
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x8e84aa
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x4e5469
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x632648
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x29343a
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x110b1a
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x8f87a4
    sw $t4 2588($v0) # (7, 5)
    li $t4 0xb4abd1
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x020102
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x010001
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x15141d
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x9e4990
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x4e5a54
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x103524
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x08050a
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x120f17
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x030203
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x665987
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x7095b9
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x006c47
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x00704d
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x002216
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x000201
    sw $t4 3620($v0) # (9, 7)
    sw $t4 4132($v0) # (9, 8)
    li $t4 0x000101
    sw $t4 4100($v0) # (1, 8)
    sw $t4 4104($v0) # (2, 8)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x0d5544
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x00ac61
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x018552
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x016145
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x012117
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x0a0b0a
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x484c67
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x101e22
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x000a07
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x010000
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x050101
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x100100
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x020000
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x000100
    sw $t4 5656($v0) # (6, 11)
    jr $ra
draw_doll_03_19: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1056($v0) # (8, 2)
    sw $0 1572($v0) # (9, 3)
    sw $0 2084($v0) # (9, 4)
    sw $0 2596($v0) # (9, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3108($v0) # (9, 6)
    sw $0 3620($v0) # (9, 7)
    sw $0 4100($v0) # (1, 8)
    sw $0 4124($v0) # (7, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4636($v0) # (7, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 4($v0) # (1, 0)
    sw $t4 1060($v0) # (9, 2)
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x000302
    sw $t4 12($v0) # (3, 0)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x130c0e
    sw $t4 16($v0) # (4, 0)
    li $t4 0x1d0f13
    sw $t4 20($v0) # (5, 0)
    li $t4 0x000100
    sw $t4 516($v0) # (1, 1)
    sw $t4 4128($v0) # (8, 8)
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x000201
    sw $t4 520($v0) # (2, 1)
    sw $t4 4096($v0) # (0, 8)
    li $t4 0x312f2f
    sw $t4 524($v0) # (3, 1)
    li $t4 0x7e2642
    sw $t4 528($v0) # (4, 1)
    li $t4 0x622538
    sw $t4 532($v0) # (5, 1)
    li $t4 0x262b2a
    sw $t4 536($v0) # (6, 1)
    li $t4 0x080708
    sw $t4 540($v0) # (7, 1)
    li $t4 0x010001
    sw $t4 544($v0) # (8, 1)
    li $t4 0x040304
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x000002
    sw $t4 1028($v0) # (1, 2)
    li $t4 0x171816
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x454447
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x2b2529
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x1c2020
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x3e3c3c
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x121211
    sw $t4 1052($v0) # (7, 2)
    li $t4 0x1a1622
    sw $t4 1536($v0) # (0, 3)
    li $t4 0xb3a9cf
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x464452
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x4c3026
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x586d56
    sw $t4 1552($v0) # (4, 3)
    li $t4 0xb39977
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x2c3a35
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x403b4b
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x131119
    sw $t4 1568($v0) # (8, 3)
    sw $t4 2080($v0) # (8, 4)
    li $t4 0x17141f
    sw $t4 2048($v0) # (0, 4)
    li $t4 0xede1ff
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x625775
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x30131d
    sw $t4 2060($v0) # (3, 4)
    li $t4 0xafa091
    sw $t4 2064($v0) # (4, 4)
    li $t4 0xb9a58c
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x2e292b
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x413550
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x030405
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x3f3b46
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x2a4042
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x327372
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x9467a0
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x6d5273
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x596f85
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x25303f
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x0a070c
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x050000
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x615954
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x004539
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x89366e
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x772f5c
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x052d24
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x3a3c2a
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x0e0202
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x000101
    sw $t4 3584($v0) # (0, 7)
    sw $t4 5656($v0) # (6, 11)
    li $t4 0x070405
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x051307
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x246261
    sw $t4 3596($v0) # (3, 7)
    li $t4 0xcfb8ef
    sw $t4 3600($v0) # (4, 7)
    li $t4 0xa9a9db
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x02211a
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x080000
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x020303
    sw $t4 3616($v0) # (8, 7)
    li $t4 0x00291a
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x0b7859
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x7eb1b4
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x34cf94
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x007844
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x000303
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x223e47
    sw $t4 4620($v0) # (3, 9)
    li $t4 0x1b5957
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x004724
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x00190f
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x010000
    sw $t4 5124($v0) # (1, 10)
    li $t4 0x17070d
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x220710
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x030000
    sw $t4 5140($v0) # (5, 10)
    jr $ra
draw_doll_03_20: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 520($v0) # (2, 1)
    sw $0 536($v0) # (6, 1)
    sw $0 540($v0) # (7, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1024($v0) # (0, 2)
    sw $0 1028($v0) # (1, 2)
    sw $0 1052($v0) # (7, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1568($v0) # (8, 3)
    sw $0 2084($v0) # (9, 4)
    sw $0 2596($v0) # (9, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3108($v0) # (9, 6)
    sw $0 3616($v0) # (8, 7)
    sw $0 3620($v0) # (9, 7)
    sw $0 4132($v0) # (9, 8)
    sw $0 4612($v0) # (1, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5124($v0) # (1, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 24($v0) # (6, 0)
    sw $t4 1572($v0) # (9, 3)
    li $t4 0x020203
    sw $t4 512($v0) # (0, 1)
    sw $t4 516($v0) # (1, 1)
    li $t4 0x000302
    sw $t4 524($v0) # (3, 1)
    li $t4 0x0b0b0b
    sw $t4 528($v0) # (4, 1)
    li $t4 0x0d0809
    sw $t4 532($v0) # (5, 1)
    li $t4 0x060a09
    sw $t4 1032($v0) # (2, 2)
    li $t4 0x402e33
    sw $t4 1036($v0) # (3, 2)
    li $t4 0x841e3c
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x492531
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x181e1c
    sw $t4 1048($v0) # (6, 2)
    li $t4 0x3b3649
    sw $t4 1536($v0) # (0, 3)
    li $t4 0x322d3f
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x1d1f1d
    sw $t4 1544($v0) # (2, 3)
    li $t4 0x474246
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x342a2e
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x221f20
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x4e4d4d
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x121213
    sw $t4 1564($v0) # (7, 3)
    li $t4 0xa094be
    sw $t4 2048($v0) # (0, 4)
    li $t4 0xe1d7fc
    sw $t4 2052($v0) # (1, 4)
    li $t4 0x38393e
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x533b32
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x4e6355
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x9e8557
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x27251e
    sw $t4 2072($v0) # (6, 4)
    li $t4 0x27232f
    sw $t4 2076($v0) # (7, 4)
    li $t4 0x010102
    sw $t4 2080($v0) # (8, 4)
    sw $t4 3104($v0) # (8, 6)
    li $t4 0x69617e
    sw $t4 2560($v0) # (0, 5)
    li $t4 0xd9ccf2
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x3f3350
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x522e2f
    sw $t4 2572($v0) # (3, 5)
    li $t4 0xaaab8c
    sw $t4 2576($v0) # (4, 5)
    li $t4 0xc1a692
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x221819
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x1e1b27
    sw $t4 2588($v0) # (7, 5)
    li $t4 0x030204
    sw $t4 2592($v0) # (8, 5)
    li $t4 0x342e43
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x1c3a3a
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x5c8095
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x9671a7
    sw $t4 3088($v0) # (4, 6)
    li $t4 0x9f88b4
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x2c3949
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x08080c
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x010202
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x120906
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x354f3c
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x154e53
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x983b7a
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x571f3a
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x394533
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x050302
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x000101
    sw $t4 4096($v0) # (0, 8)
    sw $t4 4128($v0) # (8, 8)
    sw $t4 4608($v0) # (0, 9)
    sw $t4 5120($v0) # (0, 10)
    li $t4 0x0e0707
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x0c2717
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x2d626f
    sw $t4 4108($v0) # (3, 8)
    li $t4 0xc6a7e9
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x8d84bb
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x281f1a
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x060102
    sw $t4 4124($v0) # (7, 8)
    li $t4 0x004528
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x30877a
    sw $t4 4620($v0) # (3, 9)
    li $t4 0xd8d0f4
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x5eafb2
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x003d20
    sw $t4 4632($v0) # (6, 9)
    li $t4 0x010000
    sw $t4 4636($v0) # (7, 9)
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x000201
    sw $t4 4640($v0) # (8, 9)
    li $t4 0x061210
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x205254
    sw $t4 5132($v0) # (3, 10)
    li $t4 0x175751
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x00532f
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x02120a
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x000100
    sw $t4 5152($v0) # (8, 10)
    li $t4 0x090203
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x280f1c
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x130105
    sw $t4 5648($v0) # (4, 11)
    jr $ra
draw_doll_03_21: # start at v0, use t4
    sw $0 0($v0) # (0, 0)
    sw $0 4($v0) # (1, 0)
    sw $0 8($v0) # (2, 0)
    sw $0 12($v0) # (3, 0)
    sw $0 16($v0) # (4, 0)
    sw $0 20($v0) # (5, 0)
    sw $0 24($v0) # (6, 0)
    sw $0 28($v0) # (7, 0)
    sw $0 32($v0) # (8, 0)
    sw $0 36($v0) # (9, 0)
    sw $0 512($v0) # (0, 1)
    sw $0 516($v0) # (1, 1)
    sw $0 520($v0) # (2, 1)
    sw $0 536($v0) # (6, 1)
    sw $0 540($v0) # (7, 1)
    sw $0 544($v0) # (8, 1)
    sw $0 548($v0) # (9, 1)
    sw $0 1028($v0) # (1, 2)
    sw $0 1032($v0) # (2, 2)
    sw $0 1036($v0) # (3, 2)
    sw $0 1048($v0) # (6, 2)
    sw $0 1052($v0) # (7, 2)
    sw $0 1056($v0) # (8, 2)
    sw $0 1060($v0) # (9, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1568($v0) # (8, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 2052($v0) # (1, 4)
    sw $0 2076($v0) # (7, 4)
    sw $0 2080($v0) # (8, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 2596($v0) # (9, 5)
    sw $0 3616($v0) # (8, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4124($v0) # (7, 8)
    sw $0 4128($v0) # (8, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4632($v0) # (6, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 5124($v0) # (1, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5668($v0) # (9, 11)
    li $t4 0x010101
    sw $t4 524($v0) # (3, 1)
    sw $t4 2592($v0) # (8, 5)
    sw $t4 3104($v0) # (8, 6)
    sw $t4 3108($v0) # (9, 6)
    li $t4 0x020000
    sw $t4 528($v0) # (4, 1)
    sw $t4 5148($v0) # (7, 10)
    li $t4 0x010000
    sw $t4 532($v0) # (5, 1)
    sw $t4 5660($v0) # (7, 11)
    li $t4 0x020202
    sw $t4 1024($v0) # (0, 2)
    li $t4 0x000200
    sw $t4 1040($v0) # (4, 2)
    li $t4 0x000100
    sw $t4 1044($v0) # (5, 2)
    li $t4 0x020201
    sw $t4 1540($v0) # (1, 3)
    li $t4 0x000101
    sw $t4 1544($v0) # (2, 3)
    sw $t4 5120($v0) # (0, 10)
    sw $t4 5632($v0) # (0, 11)
    li $t4 0x201a1c
    sw $t4 1548($v0) # (3, 3)
    li $t4 0x61172d
    sw $t4 1552($v0) # (4, 3)
    li $t4 0x3c1c25
    sw $t4 1556($v0) # (5, 3)
    li $t4 0x050908
    sw $t4 1560($v0) # (6, 3)
    li $t4 0x010102
    sw $t4 1564($v0) # (7, 3)
    li $t4 0x2c2736
    sw $t4 2048($v0) # (0, 4)
    li $t4 0x151916
    sw $t4 2056($v0) # (2, 4)
    li $t4 0x524147
    sw $t4 2060($v0) # (3, 4)
    li $t4 0x622a3a
    sw $t4 2064($v0) # (4, 4)
    li $t4 0x30262d
    sw $t4 2068($v0) # (5, 4)
    li $t4 0x343635
    sw $t4 2072($v0) # (6, 4)
    li $t4 0xcdc1ef
    sw $t4 2560($v0) # (0, 5)
    li $t4 0x988eb3
    sw $t4 2564($v0) # (1, 5)
    li $t4 0x2d2b32
    sw $t4 2568($v0) # (2, 5)
    li $t4 0x3b3633
    sw $t4 2572($v0) # (3, 5)
    li $t4 0x182b29
    sw $t4 2576($v0) # (4, 5)
    li $t4 0x615038
    sw $t4 2580($v0) # (5, 5)
    li $t4 0x211d1b
    sw $t4 2584($v0) # (6, 5)
    li $t4 0x252031
    sw $t4 2588($v0) # (7, 5)
    li $t4 0xbaafd9
    sw $t4 3072($v0) # (0, 6)
    li $t4 0xf5e7ff
    sw $t4 3076($v0) # (1, 6)
    li $t4 0x2d293e
    sw $t4 3080($v0) # (2, 6)
    li $t4 0x572d1f
    sw $t4 3084($v0) # (3, 6)
    li $t4 0x9aa881
    sw $t4 3088($v0) # (4, 6)
    li $t4 0xcaae7a
    sw $t4 3092($v0) # (5, 6)
    li $t4 0x1a1d1d
    sw $t4 3096($v0) # (6, 6)
    li $t4 0x4b4067
    sw $t4 3100($v0) # (7, 6)
    li $t4 0x19171e
    sw $t4 3584($v0) # (0, 7)
    li $t4 0x6d6581
    sw $t4 3588($v0) # (1, 7)
    li $t4 0x0d1119
    sw $t4 3592($v0) # (2, 7)
    li $t4 0x60637c
    sw $t4 3596($v0) # (3, 7)
    li $t4 0x9e8da6
    sw $t4 3600($v0) # (4, 7)
    li $t4 0x998ea4
    sw $t4 3604($v0) # (5, 7)
    li $t4 0x5b625c
    sw $t4 3608($v0) # (6, 7)
    li $t4 0x403753
    sw $t4 3612($v0) # (7, 7)
    li $t4 0x020102
    sw $t4 3620($v0) # (9, 7)
    li $t4 0x130507
    sw $t4 4100($v0) # (1, 8)
    li $t4 0x376a58
    sw $t4 4104($v0) # (2, 8)
    li $t4 0x316d72
    sw $t4 4108($v0) # (3, 8)
    li $t4 0x9c4787
    sw $t4 4112($v0) # (4, 8)
    li $t4 0x683652
    sw $t4 4116($v0) # (5, 8)
    li $t4 0x372624
    sw $t4 4120($v0) # (6, 8)
    li $t4 0x010202
    sw $t4 4608($v0) # (0, 9)
    li $t4 0x281916
    sw $t4 4612($v0) # (1, 9)
    li $t4 0x2e3228
    sw $t4 4616($v0) # (2, 9)
    li $t4 0x154754
    sw $t4 4620($v0) # (3, 9)
    li $t4 0xa572b6
    sw $t4 4624($v0) # (4, 9)
    li $t4 0x6f4f7e
    sw $t4 4628($v0) # (5, 9)
    li $t4 0x020203
    sw $t4 4636($v0) # (7, 9)
    li $t4 0x003e21
    sw $t4 5128($v0) # (2, 10)
    li $t4 0x377a7f
    sw $t4 5132($v0) # (3, 10)
    li $t4 0xfadeff
    sw $t4 5136($v0) # (4, 10)
    li $t4 0x8cafce
    sw $t4 5140($v0) # (5, 10)
    li $t4 0x022918
    sw $t4 5144($v0) # (6, 10)
    li $t4 0x000201
    sw $t4 5152($v0) # (8, 10)
    sw $t4 5664($v0) # (8, 11)
    li $t4 0x020101
    sw $t4 5636($v0) # (1, 11)
    li $t4 0x022c1d
    sw $t4 5640($v0) # (2, 11)
    li $t4 0x0e6c54
    sw $t4 5644($v0) # (3, 11)
    li $t4 0x69b09f
    sw $t4 5648($v0) # (4, 11)
    li $t4 0x1ea271
    sw $t4 5652($v0) # (5, 11)
    li $t4 0x00301a
    sw $t4 5656($v0) # (6, 11)
    jr $ra
clear_doll: # start at v0, use t4
    sw $0 0($v0)
    sw $0 4($v0)
    sw $0 8($v0)
    sw $0 12($v0)
    sw $0 16($v0)
    sw $0 20($v0)
    sw $0 24($v0)
    sw $0 28($v0)
    sw $0 32($v0)
    sw $0 36($v0)
    sw $0 512($v0)
    sw $0 516($v0)
    sw $0 520($v0)
    sw $0 524($v0)
    sw $0 528($v0)
    sw $0 532($v0)
    sw $0 536($v0)
    sw $0 540($v0)
    sw $0 544($v0)
    sw $0 548($v0)
    sw $0 1024($v0)
    sw $0 1028($v0)
    sw $0 1032($v0)
    sw $0 1036($v0)
    sw $0 1040($v0)
    sw $0 1044($v0)
    sw $0 1048($v0)
    sw $0 1052($v0)
    sw $0 1056($v0)
    sw $0 1060($v0)
    sw $0 1536($v0)
    sw $0 1540($v0)
    sw $0 1544($v0)
    sw $0 1548($v0)
    sw $0 1552($v0)
    sw $0 1556($v0)
    sw $0 1560($v0)
    sw $0 1564($v0)
    sw $0 1568($v0)
    sw $0 1572($v0)
    sw $0 2048($v0)
    sw $0 2052($v0)
    sw $0 2056($v0)
    sw $0 2060($v0)
    sw $0 2064($v0)
    sw $0 2068($v0)
    sw $0 2072($v0)
    sw $0 2076($v0)
    sw $0 2080($v0)
    sw $0 2084($v0)
    sw $0 2560($v0)
    sw $0 2564($v0)
    sw $0 2568($v0)
    sw $0 2572($v0)
    sw $0 2576($v0)
    sw $0 2580($v0)
    sw $0 2584($v0)
    sw $0 2588($v0)
    sw $0 2592($v0)
    sw $0 2596($v0)
    sw $0 3072($v0)
    sw $0 3076($v0)
    sw $0 3080($v0)
    sw $0 3084($v0)
    sw $0 3088($v0)
    sw $0 3092($v0)
    sw $0 3096($v0)
    sw $0 3100($v0)
    sw $0 3104($v0)
    sw $0 3108($v0)
    sw $0 3584($v0)
    sw $0 3588($v0)
    sw $0 3592($v0)
    sw $0 3596($v0)
    sw $0 3600($v0)
    sw $0 3604($v0)
    sw $0 3608($v0)
    sw $0 3612($v0)
    sw $0 3616($v0)
    sw $0 3620($v0)
    sw $0 4096($v0)
    sw $0 4100($v0)
    sw $0 4104($v0)
    sw $0 4108($v0)
    sw $0 4112($v0)
    sw $0 4116($v0)
    sw $0 4120($v0)
    sw $0 4124($v0)
    sw $0 4128($v0)
    sw $0 4132($v0)
    sw $0 4608($v0)
    sw $0 4612($v0)
    sw $0 4616($v0)
    sw $0 4620($v0)
    sw $0 4624($v0)
    sw $0 4628($v0)
    sw $0 4632($v0)
    sw $0 4636($v0)
    sw $0 4640($v0)
    sw $0 4644($v0)
    sw $0 5120($v0)
    sw $0 5124($v0)
    sw $0 5128($v0)
    sw $0 5132($v0)
    sw $0 5136($v0)
    sw $0 5140($v0)
    sw $0 5144($v0)
    sw $0 5148($v0)
    sw $0 5152($v0)
    sw $0 5156($v0)
    sw $0 5632($v0)
    sw $0 5636($v0)
    sw $0 5640($v0)
    sw $0 5644($v0)
    sw $0 5648($v0)
    sw $0 5652($v0)
    sw $0 5656($v0)
    sw $0 5660($v0)
    sw $0 5664($v0)
    sw $0 5668($v0)
    jr $ra

