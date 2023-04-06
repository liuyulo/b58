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
    dolls: .word draw_doll_00 draw_doll_01
        draw_doll_02 draw_doll_03 draw_doll_04 draw_doll_05
        draw_doll_06 draw_doll_07 draw_doll_08 draw_doll_09
        draw_doll_10 draw_doll_11 draw_doll_12 draw_doll_13
        draw_doll_14 draw_doll_15 draw_doll_16 draw_doll_17
        draw_doll_18 draw_doll_19 draw_doll_20 draw_doll_21
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
    srl $t4 $s7 1
    rem $t4 $t4 DOLLS_FRAME
    sll $t4 $t4 2 # in words
    la $t5 dolls
    add $t5 $t5 $t4 # address to doll frame
    lw $t5 0($t5) # get doll frame
    lw $v0 doll_address
    jalr $t5

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
    flatten($s0, $s1, $v0)
    jal clear_alice
    li $s0 400
    li $s1 256
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
    sw $0 0($v0) # store background (2, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2f1c14 # load color
    sw $t4 0($v0) # store color (3, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x945138 # load color
    sw $t4 0($v0) # store color (4, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf0af8f # load color
    sw $t4 0($v0) # store color (5, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcfa0a8 # load color
    sw $t4 0($v0) # store color (6, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc0889e # load color
    sw $t4 0($v0) # store color (7, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd295a0 # load color
    sw $t4 0($v0) # store color (8, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf808d # load color
    sw $t4 0($v0) # store color (9, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcd9bae # load color
    sw $t4 0($v0) # store color (10, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x999198 # load color
    sw $t4 0($v0) # store color (11, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x382d1f # load color
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
    li $t4 0x0b0705 # load color
    sw $t4 0($v0) # store color (1, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x593122 # load color
    sw $t4 0($v0) # store color (2, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd1815e # load color
    sw $t4 0($v0) # store color (3, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6cec0 # load color
    sw $t4 0($v0) # store color (4, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbc788c # load color
    sw $t4 0($v0) # store color (5, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa33e5a # load color
    sw $t4 0($v0) # store color (6, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf7b86 # load color
    sw $t4 0($v0) # store color (7, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe09d9a # load color
    sw $t4 0($v0) # store color (8, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe19e9b # load color
    sw $t4 0($v0) # store color (9, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xba757f # load color
    sw $t4 0($v0) # store color (10, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb748b # load color
    sw $t4 0($v0) # store color (11, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd1958d # load color
    sw $t4 0($v0) # store color (12, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x65493f # load color
    sw $t4 0($v0) # store color (13, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x040303 # load color
    sw $t4 0($v0) # store color (14, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 1)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x724330 # load color
    sw $t4 0($v0) # store color (1, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc16c4d # load color
    sw $t4 0($v0) # store color (2, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdaa29a # load color
    sw $t4 0($v0) # store color (3, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb56c80 # load color
    sw $t4 0($v0) # store color (4, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xab465c # load color
    sw $t4 0($v0) # store color (5, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe7b895 # load color
    sw $t4 0($v0) # store color (6, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9cb7c # load color
    sw $t4 0($v0) # store color (7, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c871 # load color
    sw $t4 0($v0) # store color (8, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7c870 # load color
    sw $t4 0($v0) # store color (9, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8c57d # load color
    sw $t4 0($v0) # store color (10, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe1b8a6 # load color
    sw $t4 0($v0) # store color (11, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdc9e9e # load color
    sw $t4 0($v0) # store color (12, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebb284 # load color
    sw $t4 0($v0) # store color (13, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x825838 # load color
    sw $t4 0($v0) # store color (14, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x050004 # load color
    sw $t4 0($v0) # store color (15, 2)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x331e15 # load color
    sw $t4 0($v0) # store color (0, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb96c4e # load color
    sw $t4 0($v0) # store color (1, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd59b65 # load color
    sw $t4 0($v0) # store color (2, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd1907a # load color
    sw $t4 0($v0) # store color (3, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb35b69 # load color
    sw $t4 0($v0) # store color (4, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedc094 # load color
    sw $t4 0($v0) # store color (5, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdc7c # load color
    sw $t4 0($v0) # store color (6, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffde75 # load color
    sw $t4 0($v0) # store color (7, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbe686 # load color
    sw $t4 0($v0) # store color (8, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe690 # load color
    sw $t4 0($v0) # store color (9, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcdb76 # load color
    sw $t4 0($v0) # store color (10, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdf86 # load color
    sw $t4 0($v0) # store color (11, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe9b9 # load color
    sw $t4 0($v0) # store color (12, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcd280 # load color
    sw $t4 0($v0) # store color (13, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeec76d # load color
    sw $t4 0($v0) # store color (14, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3d2a1c # load color
    sw $t4 0($v0) # store color (15, 3)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x9e5c43 # load color
    sw $t4 0($v0) # store color (0, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbc6e50 # load color
    sw $t4 0($v0) # store color (1, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c372 # load color
    sw $t4 0($v0) # store color (2, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd67c # load color
    sw $t4 0($v0) # store color (3, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeab374 # load color
    sw $t4 0($v0) # store color (4, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe1a3 # load color
    sw $t4 0($v0) # store color (5, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7d7b2 # load color
    sw $t4 0($v0) # store color (6, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xda9e63 # load color
    sw $t4 0($v0) # store color (7, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfeeaa4 # load color
    sw $t4 0($v0) # store color (8, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffeabe # load color
    sw $t4 0($v0) # store color (9, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xde9e64 # load color
    sw $t4 0($v0) # store color (10, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfedf9e # load color
    sw $t4 0($v0) # store color (11, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9d69a # load color
    sw $t4 0($v0) # store color (12, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeeae6b # load color
    sw $t4 0($v0) # store color (13, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfede7b # load color
    sw $t4 0($v0) # store color (14, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb4914f # load color
    sw $t4 0($v0) # store color (15, 4)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbc6c4f # load color
    sw $t4 0($v0) # store color (0, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xda935f # load color
    sw $t4 0($v0) # store color (1, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad278 # load color
    sw $t4 0($v0) # store color (2, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9d177 # load color
    sw $t4 0($v0) # store color (3, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7b873 # load color
    sw $t4 0($v0) # store color (4, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4c672 # load color
    sw $t4 0($v0) # store color (5, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xba6844 # load color
    sw $t4 0($v0) # store color (6, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc17e50 # load color
    sw $t4 0($v0) # store color (7, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe67a # load color
    sw $t4 0($v0) # store color (8, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe3a358 # load color
    sw $t4 0($v0) # store color (9, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8e4025 # load color
    sw $t4 0($v0) # store color (10, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xac6943 # load color
    sw $t4 0($v0) # store color (11, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdd27b # load color
    sw $t4 0($v0) # store color (12, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdca468 # load color
    sw $t4 0($v0) # store color (13, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4b371 # load color
    sw $t4 0($v0) # store color (14, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7be68 # load color
    sw $t4 0($v0) # store color (15, 5)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbb6a4e # load color
    sw $t4 0($v0) # store color (0, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2a968 # load color
    sw $t4 0($v0) # store color (1, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebbc6e # load color
    sw $t4 0($v0) # store color (2, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdd279 # load color
    sw $t4 0($v0) # store color (3, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcc855d # load color
    sw $t4 0($v0) # store color (4, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x744737 # load color
    sw $t4 0($v0) # store color (5, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6f2e21 # load color
    sw $t4 0($v0) # store color (6, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa27757 # load color
    sw $t4 0($v0) # store color (7, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1b571 # load color
    sw $t4 0($v0) # store color (8, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd08470 # load color
    sw $t4 0($v0) # store color (9, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x60525a # load color
    sw $t4 0($v0) # store color (10, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x956261 # load color
    sw $t4 0($v0) # store color (11, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbb968 # load color
    sw $t4 0($v0) # store color (12, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc69c58 # load color
    sw $t4 0($v0) # store color (13, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb66a4c # load color
    sw $t4 0($v0) # store color (14, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xccae67 # load color
    sw $t4 0($v0) # store color (15, 6)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xce7a57 # load color
    sw $t4 0($v0) # store color (0, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe29f65 # load color
    sw $t4 0($v0) # store color (1, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd38a5b # load color
    sw $t4 0($v0) # store color (2, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdc7e # load color
    sw $t4 0($v0) # store color (3, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc08e56 # load color
    sw $t4 0($v0) # store color (4, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa6959a # load color
    sw $t4 0($v0) # store color (5, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x618389 # load color
    sw $t4 0($v0) # store color (6, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbfada4 # load color
    sw $t4 0($v0) # store color (7, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcc9b8 # load color
    sw $t4 0($v0) # store color (8, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5e1da # load color
    sw $t4 0($v0) # store color (9, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x64acbd # load color
    sw $t4 0($v0) # store color (10, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc99c8e # load color
    sw $t4 0($v0) # store color (11, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd08c48 # load color
    sw $t4 0($v0) # store color (12, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb57a49 # load color
    sw $t4 0($v0) # store color (13, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x432519 # load color
    sw $t4 0($v0) # store color (14, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x57522d # load color
    sw $t4 0($v0) # store color (15, 7)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xd07b58 # load color
    sw $t4 0($v0) # store color (0, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdc855e # load color
    sw $t4 0($v0) # store color (1, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc2754f # load color
    sw $t4 0($v0) # store color (2, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9a66a # load color
    sw $t4 0($v0) # store color (3, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe8a764 # load color
    sw $t4 0($v0) # store color (4, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc2b7b4 # load color
    sw $t4 0($v0) # store color (5, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2c98ac # load color
    sw $t4 0($v0) # store color (6, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7dad6 # load color
    sw $t4 0($v0) # store color (7, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffefe6 # load color
    sw $t4 0($v0) # store color (8, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8ebe2 # load color
    sw $t4 0($v0) # store color (9, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbed2cf # load color
    sw $t4 0($v0) # store color (10, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc9876d # load color
    sw $t4 0($v0) # store color (11, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdc7350 # load color
    sw $t4 0($v0) # store color (12, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7a4331 # load color
    sw $t4 0($v0) # store color (13, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x060302 # load color
    sw $t4 0($v0) # store color (14, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000202 # load color
    sw $t4 0($v0) # store color (15, 8)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x734333 # load color
    sw $t4 0($v0) # store color (0, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdc8260 # load color
    sw $t4 0($v0) # store color (1, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7c432d # load color
    sw $t4 0($v0) # store color (2, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x794631 # load color
    sw $t4 0($v0) # store color (3, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xda7f51 # load color
    sw $t4 0($v0) # store color (4, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf816e # load color
    sw $t4 0($v0) # store color (5, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xddbbc1 # load color
    sw $t4 0($v0) # store color (6, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad9d5 # load color
    sw $t4 0($v0) # store color (7, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe2d8 # load color
    sw $t4 0($v0) # store color (8, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed9d3 # load color
    sw $t4 0($v0) # store color (9, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcf9486 # load color
    sw $t4 0($v0) # store color (10, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb734f # load color
    sw $t4 0($v0) # store color (11, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcd724d # load color
    sw $t4 0($v0) # store color (12, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4d2b1f # load color
    sw $t4 0($v0) # store color (13, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010101 # load color
    sw $t4 0($v0) # store color (15, 9)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x000001 # load color
    sw $t4 0($v0) # store color (0, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x724233 # load color
    sw $t4 0($v0) # store color (1, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x43251d # load color
    sw $t4 0($v0) # store color (2, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1a0f08 # load color
    sw $t4 0($v0) # store color (3, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8c4a2a # load color
    sw $t4 0($v0) # store color (4, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdea89a # load color
    sw $t4 0($v0) # store color (5, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffd9e0 # load color
    sw $t4 0($v0) # store color (6, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4bfbb # load color
    sw $t4 0($v0) # store color (7, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd4e59 # load color
    sw $t4 0($v0) # store color (8, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdca6ae # load color
    sw $t4 0($v0) # store color (9, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcaacae # load color
    sw $t4 0($v0) # store color (10, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb46259 # load color
    sw $t4 0($v0) # store color (11, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2c1309 # load color
    sw $t4 0($v0) # store color (12, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0b0604 # load color
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
    sw $0 0($v0) # store background (2, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (3, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x110700 # load color
    sw $t4 0($v0) # store color (4, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x85757d # load color
    sw $t4 0($v0) # store color (5, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb6a3b8 # load color
    sw $t4 0($v0) # store color (6, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb68a95 # load color
    sw $t4 0($v0) # store color (7, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca9ca2 # load color
    sw $t4 0($v0) # store color (8, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc2949b # load color
    sw $t4 0($v0) # store color (9, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x92889b # load color
    sw $t4 0($v0) # store color (10, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x312840 # load color
    sw $t4 0($v0) # store color (11, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (12, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 11)
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
    sw $0 0($v0) # store background (2, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x040508 # load color
    sw $t4 0($v0) # store color (3, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x162c4a # load color
    sw $t4 0($v0) # store color (4, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x25406d # load color
    sw $t4 0($v0) # store color (5, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x303454 # load color
    sw $t4 0($v0) # store color (6, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7180a3 # load color
    sw $t4 0($v0) # store color (7, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8591a7 # load color
    sw $t4 0($v0) # store color (8, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x778090 # load color
    sw $t4 0($v0) # store color (9, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2c3756 # load color
    sw $t4 0($v0) # store color (10, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x202c4d # load color
    sw $t4 0($v0) # store color (11, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x212332 # load color
    sw $t4 0($v0) # store color (12, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010102 # load color
    sw $t4 0($v0) # store color (14, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 12)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (2, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3f414d # load color
    sw $t4 0($v0) # store color (3, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5d6e90 # load color
    sw $t4 0($v0) # store color (4, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x333d5e # load color
    sw $t4 0($v0) # store color (5, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2b345c # load color
    sw $t4 0($v0) # store color (6, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa9a8c3 # load color
    sw $t4 0($v0) # store color (7, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf0ecf6 # load color
    sw $t4 0($v0) # store color (8, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe8e5f2 # load color
    sw $t4 0($v0) # store color (9, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8c95b5 # load color
    sw $t4 0($v0) # store color (10, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x58586f # load color
    sw $t4 0($v0) # store color (11, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x171619 # load color
    sw $t4 0($v0) # store color (12, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 13)
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
    sw $0 0($v0) # store background (1, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (2, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0b0b0a # load color
    sw $t4 0($v0) # store color (3, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4d4d5a # load color
    sw $t4 0($v0) # store color (4, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x757998 # load color
    sw $t4 0($v0) # store color (5, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa5b0c6 # load color
    sw $t4 0($v0) # store color (6, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x717897 # load color
    sw $t4 0($v0) # store color (7, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6f7e9b # load color
    sw $t4 0($v0) # store color (8, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa3abc4 # load color
    sw $t4 0($v0) # store color (9, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8986a0 # load color
    sw $t4 0($v0) # store color (10, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1b191d # load color
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
    li $t4 0x0a0c10 # load color
    sw $t4 0($v0) # store color (4, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x676e8f # load color
    sw $t4 0($v0) # store color (5, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7e82a6 # load color
    sw $t4 0($v0) # store color (6, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4a4d62 # load color
    sw $t4 0($v0) # store color (7, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x262d42 # load color
    sw $t4 0($v0) # store color (8, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4b5376 # load color
    sw $t4 0($v0) # store color (9, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x48516d # load color
    sw $t4 0($v0) # store color (10, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (11, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010101 # load color
    sw $t4 0($v0) # store color (12, 15)
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
    sw $0 0($v0) # store background (2, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x281812 # load color
    sw $t4 0($v0) # store color (3, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8c503b # load color
    sw $t4 0($v0) # store color (4, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeca485 # load color
    sw $t4 0($v0) # store color (5, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7b1b8 # load color
    sw $t4 0($v0) # store color (6, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc89cae # load color
    sw $t4 0($v0) # store color (7, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd8a7b0 # load color
    sw $t4 0($v0) # store color (8, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc7959e # load color
    sw $t4 0($v0) # store color (9, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xccaab8 # load color
    sw $t4 0($v0) # store color (10, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7d7a7d # load color
    sw $t4 0($v0) # store color (11, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x22160e # load color
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
    li $t4 0x090504 # load color
    sw $t4 0($v0) # store color (1, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x502e21 # load color
    sw $t4 0($v0) # store color (2, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc77b5b # load color
    sw $t4 0($v0) # store color (3, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebb9ad # load color
    sw $t4 0($v0) # store color (4, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc37f8e # load color
    sw $t4 0($v0) # store color (5, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa7455d # load color
    sw $t4 0($v0) # store color (6, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc07b87 # load color
    sw $t4 0($v0) # store color (7, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xde9b9a # load color
    sw $t4 0($v0) # store color (8, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdb9898 # load color
    sw $t4 0($v0) # store color (9, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xba737f # load color
    sw $t4 0($v0) # store color (10, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcc7b8c # load color
    sw $t4 0($v0) # store color (11, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc19286 # load color
    sw $t4 0($v0) # store color (12, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x47332b # load color
    sw $t4 0($v0) # store color (13, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x020101 # load color
    sw $t4 0($v0) # store color (14, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 1)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x010000 # load color
    sw $t4 0($v0) # store color (0, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6c3f2d # load color
    sw $t4 0($v0) # store color (1, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc06f50 # load color
    sw $t4 0($v0) # store color (2, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdea396 # load color
    sw $t4 0($v0) # store color (3, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbe7786 # load color
    sw $t4 0($v0) # store color (4, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb05265 # load color
    sw $t4 0($v0) # store color (5, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2af94 # load color
    sw $t4 0($v0) # store color (6, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4c07b # load color
    sw $t4 0($v0) # store color (7, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4c173 # load color
    sw $t4 0($v0) # store color (8, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5c172 # load color
    sw $t4 0($v0) # store color (9, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1bb81 # load color
    sw $t4 0($v0) # store color (10, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdeb2a9 # load color
    sw $t4 0($v0) # store color (11, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xde9894 # load color
    sw $t4 0($v0) # store color (12, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7a378 # load color
    sw $t4 0($v0) # store color (13, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x62412a # load color
    sw $t4 0($v0) # store color (14, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010002 # load color
    sw $t4 0($v0) # store color (15, 2)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x351f17 # load color
    sw $t4 0($v0) # store color (0, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb46b4e # load color
    sw $t4 0($v0) # store color (1, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd69765 # load color
    sw $t4 0($v0) # store color (2, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcf8e7b # load color
    sw $t4 0($v0) # store color (3, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xba656c # load color
    sw $t4 0($v0) # store color (4, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9b98d # load color
    sw $t4 0($v0) # store color (5, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed67a # load color
    sw $t4 0($v0) # store color (6, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfddb75 # load color
    sw $t4 0($v0) # store color (7, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfce382 # load color
    sw $t4 0($v0) # store color (8, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe386 # load color
    sw $t4 0($v0) # store color (9, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd777 # load color
    sw $t4 0($v0) # store color (10, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfedd8c # load color
    sw $t4 0($v0) # store color (11, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfee3b3 # load color
    sw $t4 0($v0) # store color (12, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7cd7c # load color
    sw $t4 0($v0) # store color (13, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd5ad61 # load color
    sw $t4 0($v0) # store color (14, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2a1d14 # load color
    sw $t4 0($v0) # store color (15, 3)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x9b5b42 # load color
    sw $t4 0($v0) # store color (0, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf7452 # load color
    sw $t4 0($v0) # store color (1, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4c171 # load color
    sw $t4 0($v0) # store color (2, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7ce7b # load color
    sw $t4 0($v0) # store color (3, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe8b077 # load color
    sw $t4 0($v0) # store color (4, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbdba2 # load color
    sw $t4 0($v0) # store color (5, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4d1a7 # load color
    sw $t4 0($v0) # store color (6, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe1ab6d # load color
    sw $t4 0($v0) # store color (7, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfee9a7 # load color
    sw $t4 0($v0) # store color (8, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfce2b4 # load color
    sw $t4 0($v0) # store color (9, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdfa668 # load color
    sw $t4 0($v0) # store color (10, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcdfa1 # load color
    sw $t4 0($v0) # store color (11, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8ce92 # load color
    sw $t4 0($v0) # store color (12, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xefb76f # load color
    sw $t4 0($v0) # store color (13, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8d675 # load color
    sw $t4 0($v0) # store color (14, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0x997744 # load color
    sw $t4 0($v0) # store color (15, 4)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbe6f51 # load color
    sw $t4 0($v0) # store color (0, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdb9361 # load color
    sw $t4 0($v0) # store color (1, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9cf77 # load color
    sw $t4 0($v0) # store color (2, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad178 # load color
    sw $t4 0($v0) # store color (3, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3b672 # load color
    sw $t4 0($v0) # store color (4, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf0c172 # load color
    sw $t4 0($v0) # store color (5, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbe714c # load color
    sw $t4 0($v0) # store color (6, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca8a56 # load color
    sw $t4 0($v0) # store color (7, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe07a # load color
    sw $t4 0($v0) # store color (8, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe0a35e # load color
    sw $t4 0($v0) # store color (9, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0x964d2f # load color
    sw $t4 0($v0) # store color (10, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc08053 # load color
    sw $t4 0($v0) # store color (11, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd27a # load color
    sw $t4 0($v0) # store color (12, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdea167 # load color
    sw $t4 0($v0) # store color (13, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3bd72 # load color
    sw $t4 0($v0) # store color (14, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc0aa5c # load color
    sw $t4 0($v0) # store color (15, 5)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbe704f # load color
    sw $t4 0($v0) # store color (0, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2a867 # load color
    sw $t4 0($v0) # store color (1, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebbc6e # load color
    sw $t4 0($v0) # store color (2, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcd179 # load color
    sw $t4 0($v0) # store color (3, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb855c # load color
    sw $t4 0($v0) # store color (4, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7f513e # load color
    sw $t4 0($v0) # store color (5, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x753a29 # load color
    sw $t4 0($v0) # store color (6, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xac805e # load color
    sw $t4 0($v0) # store color (7, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xefb473 # load color
    sw $t4 0($v0) # store color (8, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca836f # load color
    sw $t4 0($v0) # store color (9, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x655356 # load color
    sw $t4 0($v0) # store color (10, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa56a5e # load color
    sw $t4 0($v0) # store color (11, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6bb6b # load color
    sw $t4 0($v0) # store color (12, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc08d52 # load color
    sw $t4 0($v0) # store color (13, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf7a53 # load color
    sw $t4 0($v0) # store color (14, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb8a15d # load color
    sw $t4 0($v0) # store color (15, 6)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xcc7956 # load color
    sw $t4 0($v0) # store color (0, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe19e65 # load color
    sw $t4 0($v0) # store color (1, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd48d5c # load color
    sw $t4 0($v0) # store color (2, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcd379 # load color
    sw $t4 0($v0) # store color (3, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbe8d5a # load color
    sw $t4 0($v0) # store color (4, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa19195 # load color
    sw $t4 0($v0) # store color (5, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x647c7f # load color
    sw $t4 0($v0) # store color (6, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xccb3a7 # load color
    sw $t4 0($v0) # store color (7, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbc8b6 # load color
    sw $t4 0($v0) # store color (8, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedd9d3 # load color
    sw $t4 0($v0) # store color (9, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6ea5b2 # load color
    sw $t4 0($v0) # store color (10, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc9917c # load color
    sw $t4 0($v0) # store color (11, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd39551 # load color
    sw $t4 0($v0) # store color (12, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa46c40 # load color
    sw $t4 0($v0) # store color (13, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x462c1c # load color
    sw $t4 0($v0) # store color (14, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5d552f # load color
    sw $t4 0($v0) # store color (15, 7)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xcb7856 # load color
    sw $t4 0($v0) # store color (0, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdc865e # load color
    sw $t4 0($v0) # store color (1, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc67952 # load color
    sw $t4 0($v0) # store color (2, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9a669 # load color
    sw $t4 0($v0) # store color (3, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdea568 # load color
    sw $t4 0($v0) # store color (4, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb7b3b3 # load color
    sw $t4 0($v0) # store color (5, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3594a6 # load color
    sw $t4 0($v0) # store color (6, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdfdbd7 # load color
    sw $t4 0($v0) # store color (7, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffebe2 # load color
    sw $t4 0($v0) # store color (8, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6e9e0 # load color
    sw $t4 0($v0) # store color (9, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb6c5c1 # load color
    sw $t4 0($v0) # store color (10, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc98166 # load color
    sw $t4 0($v0) # store color (11, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd77452 # load color
    sw $t4 0($v0) # store color (12, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x673928 # load color
    sw $t4 0($v0) # store color (13, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x050302 # load color
    sw $t4 0($v0) # store color (14, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x040504 # load color
    sw $t4 0($v0) # store color (15, 8)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x7f4a38 # load color
    sw $t4 0($v0) # store color (0, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcd7959 # load color
    sw $t4 0($v0) # store color (1, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7f462f # load color
    sw $t4 0($v0) # store color (2, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x844e36 # load color
    sw $t4 0($v0) # store color (3, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcf7c51 # load color
    sw $t4 0($v0) # store color (4, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc9907f # load color
    sw $t4 0($v0) # store color (5, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd8bdc3 # load color
    sw $t4 0($v0) # store color (6, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9d6d1 # load color
    sw $t4 0($v0) # store color (7, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdbd3 # load color
    sw $t4 0($v0) # store color (8, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad1cb # load color
    sw $t4 0($v0) # store color (9, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcf9686 # load color
    sw $t4 0($v0) # store color (10, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb7452 # load color
    sw $t4 0($v0) # store color (11, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc26b4a # load color
    sw $t4 0($v0) # store color (12, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3d2318 # load color
    sw $t4 0($v0) # store color (13, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 9)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x0a0506 # load color
    sw $t4 0($v0) # store color (0, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6c3f31 # load color
    sw $t4 0($v0) # store color (1, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x41231b # load color
    sw $t4 0($v0) # store color (2, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x24140b # load color
    sw $t4 0($v0) # store color (3, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x935435 # load color
    sw $t4 0($v0) # store color (4, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd8a79d # load color
    sw $t4 0($v0) # store color (5, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7d0d7 # load color
    sw $t4 0($v0) # store color (6, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeab7b7 # load color
    sw $t4 0($v0) # store color (7, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc15e69 # load color
    sw $t4 0($v0) # store color (8, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdaadb4 # load color
    sw $t4 0($v0) # store color (9, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd9a9c # load color
    sw $t4 0($v0) # store color (10, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa3594f # load color
    sw $t4 0($v0) # store color (11, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2c150d # load color
    sw $t4 0($v0) # store color (12, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0a0604 # load color
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
    sw $0 0($v0) # store background (2, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (3, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1d120b # load color
    sw $t4 0($v0) # store color (4, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x897780 # load color
    sw $t4 0($v0) # store color (5, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb69fb2 # load color
    sw $t4 0($v0) # store color (6, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf939d # load color
    sw $t4 0($v0) # store color (7, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcea0a4 # load color
    sw $t4 0($v0) # store color (8, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc599a0 # load color
    sw $t4 0($v0) # store color (9, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x857b8f # load color
    sw $t4 0($v0) # store color (10, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2c2537 # load color
    sw $t4 0($v0) # store color (11, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (12, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 11)
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
    sw $0 0($v0) # store background (2, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x05070a # load color
    sw $t4 0($v0) # store color (3, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1f324e # load color
    sw $t4 0($v0) # store color (4, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2f446e # load color
    sw $t4 0($v0) # store color (5, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x393e5d # load color
    sw $t4 0($v0) # store color (6, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x757fa0 # load color
    sw $t4 0($v0) # store color (7, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x878ea2 # load color
    sw $t4 0($v0) # store color (8, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x767c8e # load color
    sw $t4 0($v0) # store color (9, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x343c5b # load color
    sw $t4 0($v0) # store color (10, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x262f4e # load color
    sw $t4 0($v0) # store color (11, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x181924 # load color
    sw $t4 0($v0) # store color (12, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 12)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010102 # load color
    sw $t4 0($v0) # store color (2, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3c3f4c # load color
    sw $t4 0($v0) # store color (3, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x556689 # load color
    sw $t4 0($v0) # store color (4, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x363f61 # load color
    sw $t4 0($v0) # store color (5, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x373e65 # load color
    sw $t4 0($v0) # store color (6, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xacacc6 # load color
    sw $t4 0($v0) # store color (7, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe1dfec # load color
    sw $t4 0($v0) # store color (8, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd9d8e8 # load color
    sw $t4 0($v0) # store color (9, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7e87a5 # load color
    sw $t4 0($v0) # store color (10, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x535468 # load color
    sw $t4 0($v0) # store color (11, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0e0e10 # load color
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
    sw $0 0($v0) # store background (2, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0d0d0c # load color
    sw $t4 0($v0) # store color (3, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4f5160 # load color
    sw $t4 0($v0) # store color (4, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x767b98 # load color
    sw $t4 0($v0) # store color (5, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa1abc1 # load color
    sw $t4 0($v0) # store color (6, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x757b9b # load color
    sw $t4 0($v0) # store color (7, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7787a2 # load color
    sw $t4 0($v0) # store color (8, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa4aac3 # load color
    sw $t4 0($v0) # store color (9, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x78778f # load color
    sw $t4 0($v0) # store color (10, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x141316 # load color
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
    li $t4 0x16171e # load color
    sw $t4 0($v0) # store color (4, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x666d8e # load color
    sw $t4 0($v0) # store color (5, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x777ea1 # load color
    sw $t4 0($v0) # store color (6, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x41465b # load color
    sw $t4 0($v0) # store color (7, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x292f42 # load color
    sw $t4 0($v0) # store color (8, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4d5578 # load color
    sw $t4 0($v0) # store color (9, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3e465e # load color
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
draw_alice_02:
    sw $0 0($v0) # store background (0, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (2, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x140c09 # load color
    sw $t4 0($v0) # store color (3, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x794330 # load color
    sw $t4 0($v0) # store color (4, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xee9d78 # load color
    sw $t4 0($v0) # store color (5, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe1c2c4 # load color
    sw $t4 0($v0) # store color (6, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xceb2c4 # load color
    sw $t4 0($v0) # store color (7, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2c3ca # load color
    sw $t4 0($v0) # store color (8, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcbabb5 # load color
    sw $t4 0($v0) # store color (9, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd5bbc7 # load color
    sw $t4 0($v0) # store color (10, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x83858a # load color
    sw $t4 0($v0) # store color (11, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x170f09 # load color
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
    li $t4 0x3b2219 # load color
    sw $t4 0($v0) # store color (2, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb87050 # load color
    sw $t4 0($v0) # store color (3, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebb19f # load color
    sw $t4 0($v0) # store color (4, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xce959e # load color
    sw $t4 0($v0) # store color (5, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa53f58 # load color
    sw $t4 0($v0) # store color (6, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb5657a # load color
    sw $t4 0($v0) # store color (7, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd4878f # load color
    sw $t4 0($v0) # store color (8, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd3858d # load color
    sw $t4 0($v0) # store color (9, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb6697a # load color
    sw $t4 0($v0) # store color (10, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc77a8e # load color
    sw $t4 0($v0) # store color (11, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc39889 # load color
    sw $t4 0($v0) # store color (12, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3e3028 # load color
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
    li $t4 0x623928 # load color
    sw $t4 0($v0) # store color (1, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbb6b4c # load color
    sw $t4 0($v0) # store color (2, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2a592 # load color
    sw $t4 0($v0) # store color (3, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc78e99 # load color
    sw $t4 0($v0) # store color (4, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xab4a60 # load color
    sw $t4 0($v0) # store color (5, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd5a096 # load color
    sw $t4 0($v0) # store color (6, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xecb886 # load color
    sw $t4 0($v0) # store color (7, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3be7f # load color
    sw $t4 0($v0) # store color (8, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3be80 # load color
    sw $t4 0($v0) # store color (9, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9b485 # load color
    sw $t4 0($v0) # store color (10, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7a6a4 # load color
    sw $t4 0($v0) # store color (11, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd28789 # load color
    sw $t4 0($v0) # store color (12, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd39b7b # load color
    sw $t4 0($v0) # store color (13, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x64462d # load color
    sw $t4 0($v0) # store color (14, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x080404 # load color
    sw $t4 0($v0) # store color (15, 2)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x2d1a13 # load color
    sw $t4 0($v0) # store color (0, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xae674b # load color
    sw $t4 0($v0) # store color (1, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd28e63 # load color
    sw $t4 0($v0) # store color (2, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca8881 # load color
    sw $t4 0($v0) # store color (3, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb35564 # load color
    sw $t4 0($v0) # store color (4, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdda689 # load color
    sw $t4 0($v0) # store color (5, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbcd72 # load color
    sw $t4 0($v0) # store color (6, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfedc72 # load color
    sw $t4 0($v0) # store color (7, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbe179 # load color
    sw $t4 0($v0) # store color (8, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe07c # load color
    sw $t4 0($v0) # store color (9, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed876 # load color
    sw $t4 0($v0) # store color (10, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd384 # load color
    sw $t4 0($v0) # store color (11, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe8be # load color
    sw $t4 0($v0) # store color (12, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7cd88 # load color
    sw $t4 0($v0) # store color (13, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe1b365 # load color
    sw $t4 0($v0) # store color (14, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0x39291b # load color
    sw $t4 0($v0) # store color (15, 3)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x874e39 # load color
    sw $t4 0($v0) # store color (0, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf7553 # load color
    sw $t4 0($v0) # store color (1, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1bd70 # load color
    sw $t4 0($v0) # store color (2, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf0c37b # load color
    sw $t4 0($v0) # store color (3, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdea57a # load color
    sw $t4 0($v0) # store color (4, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad7a1 # load color
    sw $t4 0($v0) # store color (5, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfce2ae # load color
    sw $t4 0($v0) # store color (6, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebb973 # load color
    sw $t4 0($v0) # store color (7, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfde6a2 # load color
    sw $t4 0($v0) # store color (8, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe8b8 # load color
    sw $t4 0($v0) # store color (9, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebbb77 # load color
    sw $t4 0($v0) # store color (10, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe39b # load color
    sw $t4 0($v0) # store color (11, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad69f # load color
    sw $t4 0($v0) # store color (12, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1ba70 # load color
    sw $t4 0($v0) # store color (13, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcdc79 # load color
    sw $t4 0($v0) # store color (14, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa17e47 # load color
    sw $t4 0($v0) # store color (15, 4)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbb6d4f # load color
    sw $t4 0($v0) # store color (0, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd68d5d # load color
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
    li $t4 0xf8d182 # load color
    sw $t4 0($v0) # store color (5, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd08b64 # load color
    sw $t4 0($v0) # store color (6, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc78655 # load color
    sw $t4 0($v0) # store color (7, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe484 # load color
    sw $t4 0($v0) # store color (8, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf0c278 # load color
    sw $t4 0($v0) # store color (9, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xad633f # load color
    sw $t4 0($v0) # store color (10, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb8e5c # load color
    sw $t4 0($v0) # store color (11, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd483 # load color
    sw $t4 0($v0) # store color (12, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe7ad6d # load color
    sw $t4 0($v0) # store color (13, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedb76f # load color
    sw $t4 0($v0) # store color (14, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdcbf66 # load color
    sw $t4 0($v0) # store color (15, 5)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbb6e4e # load color
    sw $t4 0($v0) # store color (0, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe4aa68 # load color
    sw $t4 0($v0) # store color (1, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1c572 # load color
    sw $t4 0($v0) # store color (2, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd079 # load color
    sw $t4 0($v0) # store color (3, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdb9564 # load color
    sw $t4 0($v0) # store color (4, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9b6942 # load color
    sw $t4 0($v0) # store color (5, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x853f28 # load color
    sw $t4 0($v0) # store color (6, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xab7753 # load color
    sw $t4 0($v0) # store color (7, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3c270 # load color
    sw $t4 0($v0) # store color (8, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb7e5a # load color
    sw $t4 0($v0) # store color (9, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x72443b # load color
    sw $t4 0($v0) # store color (10, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8a564d # load color
    sw $t4 0($v0) # store color (11, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf0ad68 # load color
    sw $t4 0($v0) # store color (12, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd3a55f # load color
    sw $t4 0($v0) # store color (13, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc97e57 # load color
    sw $t4 0($v0) # store color (14, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd8b56b # load color
    sw $t4 0($v0) # store color (15, 6)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xca7856 # load color
    sw $t4 0($v0) # store color (0, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe5a768 # load color
    sw $t4 0($v0) # store color (1, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd99961 # load color
    sw $t4 0($v0) # store color (2, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed77a # load color
    sw $t4 0($v0) # store color (3, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb47e54 # load color
    sw $t4 0($v0) # store color (4, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x876e72 # load color
    sw $t4 0($v0) # store color (5, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6a5e5c # load color
    sw $t4 0($v0) # store color (6, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb49889 # load color
    sw $t4 0($v0) # store color (7, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6b89a # load color
    sw $t4 0($v0) # store color (8, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedc9c1 # load color
    sw $t4 0($v0) # store color (9, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6790a0 # load color
    sw $t4 0($v0) # store color (10, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbb938d # load color
    sw $t4 0($v0) # store color (11, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdc9f56 # load color
    sw $t4 0($v0) # store color (12, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc28e51 # load color
    sw $t4 0($v0) # store color (13, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x683b28 # load color
    sw $t4 0($v0) # store color (14, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x897945 # load color
    sw $t4 0($v0) # store color (15, 7)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xcf7a57 # load color
    sw $t4 0($v0) # store color (0, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdd8c5f # load color
    sw $t4 0($v0) # store color (1, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd08457 # load color
    sw $t4 0($v0) # store color (2, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4bb72 # load color
    sw $t4 0($v0) # store color (3, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd9a668 # load color
    sw $t4 0($v0) # store color (4, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbbb5b5 # load color
    sw $t4 0($v0) # store color (5, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3a94a4 # load color
    sw $t4 0($v0) # store color (6, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd2d1cd # load color
    sw $t4 0($v0) # store color (7, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe3da # load color
    sw $t4 0($v0) # store color (8, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbe8e1 # load color
    sw $t4 0($v0) # store color (9, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x93bdbf # load color
    sw $t4 0($v0) # store color (10, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb9783 # load color
    sw $t4 0($v0) # store color (11, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc96f4a # load color
    sw $t4 0($v0) # store color (12, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x915437 # load color
    sw $t4 0($v0) # store color (13, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1d0f0a # load color
    sw $t4 0($v0) # store color (14, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x10120a # load color
    sw $t4 0($v0) # store color (15, 8)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xa66248 # load color
    sw $t4 0($v0) # store color (0, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd67d5b # load color
    sw $t4 0($v0) # store color (1, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8d5036 # load color
    sw $t4 0($v0) # store color (2, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa86748 # load color
    sw $t4 0($v0) # store color (3, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd98d5b # load color
    sw $t4 0($v0) # store color (4, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc79e91 # load color
    sw $t4 0($v0) # store color (5, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9cb0bb # load color
    sw $t4 0($v0) # store color (6, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xecdbd7 # load color
    sw $t4 0($v0) # store color (7, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffece4 # load color
    sw $t4 0($v0) # store color (8, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfee2da # load color
    sw $t4 0($v0) # store color (9, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe4baae # load color
    sw $t4 0($v0) # store color (10, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc97958 # load color
    sw $t4 0($v0) # store color (11, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xde7a56 # load color
    sw $t4 0($v0) # store color (12, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6a3b2b # load color
    sw $t4 0($v0) # store color (13, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000001 # load color
    sw $t4 0($v0) # store color (14, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 9)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x291614 # load color
    sw $t4 0($v0) # store color (0, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa66249 # load color
    sw $t4 0($v0) # store color (1, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5d3122 # load color
    sw $t4 0($v0) # store color (2, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x472817 # load color
    sw $t4 0($v0) # store color (3, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb36440 # load color
    sw $t4 0($v0) # store color (4, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb8d7f # load color
    sw $t4 0($v0) # store color (5, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdc7ce # load color
    sw $t4 0($v0) # store color (6, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcd0cd # load color
    sw $t4 0($v0) # store color (7, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdf8f92 # load color
    sw $t4 0($v0) # store color (8, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeab9bd # load color
    sw $t4 0($v0) # store color (9, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb88e87 # load color
    sw $t4 0($v0) # store color (10, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc26c5a # load color
    sw $t4 0($v0) # store color (11, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x703922 # load color
    sw $t4 0($v0) # store color (12, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x26130b # load color
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
    li $t4 0x140b09 # load color
    sw $t4 0($v0) # store color (1, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0f0e13 # load color
    sw $t4 0($v0) # store color (2, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x192231 # load color
    sw $t4 0($v0) # store color (3, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4e352a # load color
    sw $t4 0($v0) # store color (4, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc2a2a1 # load color
    sw $t4 0($v0) # store color (5, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcab0b8 # load color
    sw $t4 0($v0) # store color (6, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb87e86 # load color
    sw $t4 0($v0) # store color (7, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x994451 # load color
    sw $t4 0($v0) # store color (8, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa76a74 # load color
    sw $t4 0($v0) # store color (9, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb29fac # load color
    sw $t4 0($v0) # store color (10, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x77525f # load color
    sw $t4 0($v0) # store color (11, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x263759 # load color
    sw $t4 0($v0) # store color (12, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0f1828 # load color
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
    li $t4 0x1d2637 # load color
    sw $t4 0($v0) # store color (2, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2c3d5b # load color
    sw $t4 0($v0) # store color (3, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2a456d # load color
    sw $t4 0($v0) # store color (4, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2d426b # load color
    sw $t4 0($v0) # store color (5, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x323554 # load color
    sw $t4 0($v0) # store color (6, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8387a5 # load color
    sw $t4 0($v0) # store color (7, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x989bb1 # load color
    sw $t4 0($v0) # store color (8, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8d8e9e # load color
    sw $t4 0($v0) # store color (9, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x454e6e # load color
    sw $t4 0($v0) # store color (10, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2e3551 # load color
    sw $t4 0($v0) # store color (11, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3b5483 # load color
    sw $t4 0($v0) # store color (12, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2e436b # load color
    sw $t4 0($v0) # store color (13, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000001 # load color
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
    li $t4 0x333e58 # load color
    sw $t4 0($v0) # store color (2, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3b4e76 # load color
    sw $t4 0($v0) # store color (3, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x455984 # load color
    sw $t4 0($v0) # store color (4, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x414969 # load color
    sw $t4 0($v0) # store color (5, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3d486e # load color
    sw $t4 0($v0) # store color (6, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9497b5 # load color
    sw $t4 0($v0) # store color (7, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd9d9e6 # load color
    sw $t4 0($v0) # store color (8, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd6d6e6 # load color
    sw $t4 0($v0) # store color (9, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9095b3 # load color
    sw $t4 0($v0) # store color (10, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x646b8c # load color
    sw $t4 0($v0) # store color (11, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x394e76 # load color
    sw $t4 0($v0) # store color (12, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0b121c # load color
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
    li $t4 0x101218 # load color
    sw $t4 0($v0) # store color (2, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x414d69 # load color
    sw $t4 0($v0) # store color (3, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3b4159 # load color
    sw $t4 0($v0) # store color (4, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x777b98 # load color
    sw $t4 0($v0) # store color (5, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaeb5cb # load color
    sw $t4 0($v0) # store color (6, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x797e9b # load color
    sw $t4 0($v0) # store color (7, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x617291 # load color
    sw $t4 0($v0) # store color (8, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8c94b0 # load color
    sw $t4 0($v0) # store color (9, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7c7a91 # load color
    sw $t4 0($v0) # store color (10, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x232d43 # load color
    sw $t4 0($v0) # store color (11, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0b121d # load color
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
    li $t4 0x18181e # load color
    sw $t4 0($v0) # store color (4, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x61688a # load color
    sw $t4 0($v0) # store color (5, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6b7198 # load color
    sw $t4 0($v0) # store color (6, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x35394c # load color
    sw $t4 0($v0) # store color (7, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1f2331 # load color
    sw $t4 0($v0) # store color (8, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x404665 # load color
    sw $t4 0($v0) # store color (9, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x424c6a # load color
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
draw_alice_03:
    sw $0 0($v0) # store background (0, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (2, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x150d0a # load color
    sw $t4 0($v0) # store color (3, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x703825 # load color
    sw $t4 0($v0) # store color (4, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1a079 # load color
    sw $t4 0($v0) # store color (5, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdebcbb # load color
    sw $t4 0($v0) # store color (6, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc8a3b7 # load color
    sw $t4 0($v0) # store color (7, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdbaeb7 # load color
    sw $t4 0($v0) # store color (8, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc497a1 # load color
    sw $t4 0($v0) # store color (9, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7aebc # load color
    sw $t4 0($v0) # store color (10, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x999ca4 # load color
    sw $t4 0($v0) # store color (11, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x261d14 # load color
    sw $t4 0($v0) # store color (12, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010000 # load color
    sw $t4 0($v0) # store color (15, 0)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x371f17 # load color
    sw $t4 0($v0) # store color (2, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbb6e4d # load color
    sw $t4 0($v0) # store color (3, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8c2ac # load color
    sw $t4 0($v0) # store color (4, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcd9aa6 # load color
    sw $t4 0($v0) # store color (5, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa03553 # load color
    sw $t4 0($v0) # store color (6, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb16078 # load color
    sw $t4 0($v0) # store color (7, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd58a92 # load color
    sw $t4 0($v0) # store color (8, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd98b92 # load color
    sw $t4 0($v0) # store color (9, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb66b7b # load color
    sw $t4 0($v0) # store color (10, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc06d87 # load color
    sw $t4 0($v0) # store color (11, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd79e95 # load color
    sw $t4 0($v0) # store color (12, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x59453c # load color
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
    li $t4 0x5b3526 # load color
    sw $t4 0($v0) # store color (1, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb76546 # load color
    sw $t4 0($v0) # store color (2, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe3a492 # load color
    sw $t4 0($v0) # store color (3, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc4909d # load color
    sw $t4 0($v0) # store color (4, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa33854 # load color
    sw $t4 0($v0) # store color (5, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd69f96 # load color
    sw $t4 0($v0) # store color (6, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2c38a # load color
    sw $t4 0($v0) # store color (7, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c57d # load color
    sw $t4 0($v0) # store color (8, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c67f # load color
    sw $t4 0($v0) # store color (9, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1bf81 # load color
    sw $t4 0($v0) # store color (10, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdbaba2 # load color
    sw $t4 0($v0) # store color (11, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd08c94 # load color
    sw $t4 0($v0) # store color (12, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe5a685 # load color
    sw $t4 0($v0) # store color (13, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x805b3c # load color
    sw $t4 0($v0) # store color (14, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0b0506 # load color
    sw $t4 0($v0) # store color (15, 2)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x22140e # load color
    sw $t4 0($v0) # store color (0, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb1684a # load color
    sw $t4 0($v0) # store color (1, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xce8d5f # load color
    sw $t4 0($v0) # store color (2, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcd8e81 # load color
    sw $t4 0($v0) # store color (3, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xab485f # load color
    sw $t4 0($v0) # store color (4, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdfa78c # load color
    sw $t4 0($v0) # store color (5, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdd173 # load color
    sw $t4 0($v0) # store color (6, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdd70 # load color
    sw $t4 0($v0) # store color (7, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbe278 # load color
    sw $t4 0($v0) # store color (8, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfee07e # load color
    sw $t4 0($v0) # store color (9, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfedc74 # load color
    sw $t4 0($v0) # store color (10, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdd57c # load color
    sw $t4 0($v0) # store color (11, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffeebf # load color
    sw $t4 0($v0) # store color (12, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8d28e # load color
    sw $t4 0($v0) # store color (13, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5c76c # load color
    sw $t4 0($v0) # store color (14, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4e3825 # load color
    sw $t4 0($v0) # store color (15, 3)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x89503a # load color
    sw $t4 0($v0) # store color (0, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb96c4f # load color
    sw $t4 0($v0) # store color (1, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xefbb6d # load color
    sw $t4 0($v0) # store color (2, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7ce7b # load color
    sw $t4 0($v0) # store color (3, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe0a778 # load color
    sw $t4 0($v0) # store color (4, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad59e # load color
    sw $t4 0($v0) # store color (5, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffebbd # load color
    sw $t4 0($v0) # store color (6, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe4ae6f # load color
    sw $t4 0($v0) # store color (7, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbe19a # load color
    sw $t4 0($v0) # store color (8, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffefc8 # load color
    sw $t4 0($v0) # store color (9, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9b778 # load color
    sw $t4 0($v0) # store color (10, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfee095 # load color
    sw $t4 0($v0) # store color (11, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbdda8 # load color
    sw $t4 0($v0) # store color (12, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xefb16b # load color
    sw $t4 0($v0) # store color (13, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfedf7d # load color
    sw $t4 0($v0) # store color (14, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbb9752 # load color
    sw $t4 0($v0) # store color (15, 4)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbd6e4f # load color
    sw $t4 0($v0) # store color (0, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd3865b # load color
    sw $t4 0($v0) # store color (1, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9cd77 # load color
    sw $t4 0($v0) # store color (2, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcd679 # load color
    sw $t4 0($v0) # store color (3, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6b86f # load color
    sw $t4 0($v0) # store color (4, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffda84 # load color
    sw $t4 0($v0) # store color (5, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd28b62 # load color
    sw $t4 0($v0) # store color (6, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbe754d # load color
    sw $t4 0($v0) # store color (7, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe681 # load color
    sw $t4 0($v0) # store color (8, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5c976 # load color
    sw $t4 0($v0) # store color (9, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa95a37 # load color
    sw $t4 0($v0) # store color (10, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb77349 # load color
    sw $t4 0($v0) # store color (11, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd684 # load color
    sw $t4 0($v0) # store color (12, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe8b16e # load color
    sw $t4 0($v0) # store color (13, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9ac6d # load color
    sw $t4 0($v0) # store color (14, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xefd170 # load color
    sw $t4 0($v0) # store color (15, 5)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xb8694c # load color
    sw $t4 0($v0) # store color (0, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe1a667 # load color
    sw $t4 0($v0) # store color (1, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1c773 # load color
    sw $t4 0($v0) # store color (2, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd179 # load color
    sw $t4 0($v0) # store color (3, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdf9668 # load color
    sw $t4 0($v0) # store color (4, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x915e3c # load color
    sw $t4 0($v0) # store color (5, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7b311b # load color
    sw $t4 0($v0) # store color (6, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9e694a # load color
    sw $t4 0($v0) # store color (7, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2c16e # load color
    sw $t4 0($v0) # store color (8, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd37f5a # load color
    sw $t4 0($v0) # store color (9, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x71433e # load color
    sw $t4 0($v0) # store color (10, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x764a4b # load color
    sw $t4 0($v0) # store color (11, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4a866 # load color
    sw $t4 0($v0) # store color (12, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdbb664 # load color
    sw $t4 0($v0) # store color (13, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbe6e4f # load color
    sw $t4 0($v0) # store color (14, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9be73 # load color
    sw $t4 0($v0) # store color (15, 6)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xc87554 # load color
    sw $t4 0($v0) # store color (0, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe4a567 # load color
    sw $t4 0($v0) # store color (1, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd4905d # load color
    sw $t4 0($v0) # store color (2, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdb7d # load color
    sw $t4 0($v0) # store color (3, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbe8854 # load color
    sw $t4 0($v0) # store color (4, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8b7276 # load color
    sw $t4 0($v0) # store color (5, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x716d6d # load color
    sw $t4 0($v0) # store color (6, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa49287 # load color
    sw $t4 0($v0) # store color (7, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7b99d # load color
    sw $t4 0($v0) # store color (8, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9d3ca # load color
    sw $t4 0($v0) # store color (9, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x689cac # load color
    sw $t4 0($v0) # store color (10, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb09899 # load color
    sw $t4 0($v0) # store color (11, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdb964f # load color
    sw $t4 0($v0) # store color (12, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcd9a58 # load color
    sw $t4 0($v0) # store color (13, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x633324 # load color
    sw $t4 0($v0) # store color (14, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7b6c3d # load color
    sw $t4 0($v0) # store color (15, 7)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xd07b58 # load color
    sw $t4 0($v0) # store color (0, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdd8b5f # load color
    sw $t4 0($v0) # store color (1, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcc7d55 # load color
    sw $t4 0($v0) # store color (2, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7bb74 # load color
    sw $t4 0($v0) # store color (3, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe3aa63 # load color
    sw $t4 0($v0) # store color (4, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xccbbb7 # load color
    sw $t4 0($v0) # store color (5, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2c99ae # load color
    sw $t4 0($v0) # store color (6, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbecccb # load color
    sw $t4 0($v0) # store color (7, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe8de # load color
    sw $t4 0($v0) # store color (8, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfeede4 # load color
    sw $t4 0($v0) # store color (9, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9fccce # load color
    sw $t4 0($v0) # store color (10, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc69e8d # load color
    sw $t4 0($v0) # store color (11, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca6945 # load color
    sw $t4 0($v0) # store color (12, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9d5a3f # load color
    sw $t4 0($v0) # store color (13, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1c0e09 # load color
    sw $t4 0($v0) # store color (14, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x050705 # load color
    sw $t4 0($v0) # store color (15, 8)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x955841 # load color
    sw $t4 0($v0) # store color (0, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe18461 # load color
    sw $t4 0($v0) # store color (1, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8f4f36 # load color
    sw $t4 0($v0) # store color (2, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x93583d # load color
    sw $t4 0($v0) # store color (3, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe48d58 # load color
    sw $t4 0($v0) # store color (4, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc38e7b # load color
    sw $t4 0($v0) # store color (5, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa9b0b9 # load color
    sw $t4 0($v0) # store color (6, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe8d4d1 # load color
    sw $t4 0($v0) # store color (7, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfff2e7 # load color
    sw $t4 0($v0) # store color (8, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe5dc # load color
    sw $t4 0($v0) # store color (9, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9baaf # load color
    sw $t4 0($v0) # store color (10, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc67757 # load color
    sw $t4 0($v0) # store color (11, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xee845a # load color
    sw $t4 0($v0) # store color (12, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x76422f # load color
    sw $t4 0($v0) # store color (13, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 9)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x140a0b # load color
    sw $t4 0($v0) # store color (0, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9e5d47 # load color
    sw $t4 0($v0) # store color (1, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x633425 # load color
    sw $t4 0($v0) # store color (2, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2b170c # load color
    sw $t4 0($v0) # store color (3, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xac5b35 # load color
    sw $t4 0($v0) # store color (4, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcc8a78 # load color
    sw $t4 0($v0) # store color (5, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffcfd6 # load color
    sw $t4 0($v0) # store color (6, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdfd9 # load color
    sw $t4 0($v0) # store color (7, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdf8589 # load color
    sw $t4 0($v0) # store color (8, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2babf # load color
    sw $t4 0($v0) # store color (9, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc29f9c # load color
    sw $t4 0($v0) # store color (10, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc26b5c # load color
    sw $t4 0($v0) # store color (11, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x713921 # load color
    sw $t4 0($v0) # store color (12, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x211006 # load color
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
    li $t4 0x070303 # load color
    sw $t4 0($v0) # store color (1, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0b0a0e # load color
    sw $t4 0($v0) # store color (2, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x172537 # load color
    sw $t4 0($v0) # store color (3, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x34231c # load color
    sw $t4 0($v0) # store color (4, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb99b9c # load color
    sw $t4 0($v0) # store color (5, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc0b0b9 # load color
    sw $t4 0($v0) # store color (6, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaa757f # load color
    sw $t4 0($v0) # store color (7, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x863546 # load color
    sw $t4 0($v0) # store color (8, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x92545f # load color
    sw $t4 0($v0) # store color (9, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaf9fad # load color
    sw $t4 0($v0) # store color (10, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x785364 # load color
    sw $t4 0($v0) # store color (11, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1f365b # load color
    sw $t4 0($v0) # store color (12, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x16233a # load color
    sw $t4 0($v0) # store color (13, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010102 # load color
    sw $t4 0($v0) # store color (14, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000101 # load color
    sw $t4 0($v0) # store color (15, 11)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x010101 # load color
    sw $t4 0($v0) # store color (0, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1b2333 # load color
    sw $t4 0($v0) # store color (2, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2f3e5c # load color
    sw $t4 0($v0) # store color (3, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x294771 # load color
    sw $t4 0($v0) # store color (4, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x233c68 # load color
    sw $t4 0($v0) # store color (5, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x232545 # load color
    sw $t4 0($v0) # store color (6, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8186a6 # load color
    sw $t4 0($v0) # store color (7, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa4acc2 # load color
    sw $t4 0($v0) # store color (8, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9b9fab # load color
    sw $t4 0($v0) # store color (9, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4b5474 # load color
    sw $t4 0($v0) # store color (10, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2a324d # load color
    sw $t4 0($v0) # store color (11, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3f5582 # load color
    sw $t4 0($v0) # store color (12, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x37507e # load color
    sw $t4 0($v0) # store color (13, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x020204 # load color
    sw $t4 0($v0) # store color (14, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 12)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x010101 # load color
    sw $t4 0($v0) # store color (0, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x030405 # load color
    sw $t4 0($v0) # store color (1, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x323c54 # load color
    sw $t4 0($v0) # store color (2, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3d4f77 # load color
    sw $t4 0($v0) # store color (3, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x475c88 # load color
    sw $t4 0($v0) # store color (4, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x484e6d # load color
    sw $t4 0($v0) # store color (5, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3c496f # load color
    sw $t4 0($v0) # store color (6, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x888cad # load color
    sw $t4 0($v0) # store color (7, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe0dfeb # load color
    sw $t4 0($v0) # store color (8, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe6e4f3 # load color
    sw $t4 0($v0) # store color (9, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa5a8c4 # load color
    sw $t4 0($v0) # store color (10, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x676d8e # load color
    sw $t4 0($v0) # store color (11, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x415580 # load color
    sw $t4 0($v0) # store color (12, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x09111c # load color
    sw $t4 0($v0) # store color (13, 13)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000101 # load color
    sw $t4 0($v0) # store color (15, 13)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x000001 # load color
    sw $t4 0($v0) # store color (0, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x070809 # load color
    sw $t4 0($v0) # store color (2, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3f4962 # load color
    sw $t4 0($v0) # store color (3, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x31374c # load color
    sw $t4 0($v0) # store color (4, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x717492 # load color
    sw $t4 0($v0) # store color (5, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb6bdd3 # load color
    sw $t4 0($v0) # store color (6, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7b809d # load color
    sw $t4 0($v0) # store color (7, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x516384 # load color
    sw $t4 0($v0) # store color (8, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x808ba9 # load color
    sw $t4 0($v0) # store color (9, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x84829a # load color
    sw $t4 0($v0) # store color (10, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1e263a # load color
    sw $t4 0($v0) # store color (11, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x0b1421 # load color
    sw $t4 0($v0) # store color (12, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000101 # load color
    sw $t4 0($v0) # store color (14, 14)
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
    li $t4 0x0b0b0b # load color
    sw $t4 0($v0) # store color (4, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5c6383 # load color
    sw $t4 0($v0) # store color (5, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x656d94 # load color
    sw $t4 0($v0) # store color (6, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x34384b # load color
    sw $t4 0($v0) # store color (7, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1a1d28 # load color
    sw $t4 0($v0) # store color (8, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x393e5d # load color
    sw $t4 0($v0) # store color (9, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x495477 # load color
    sw $t4 0($v0) # store color (10, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (11, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (12, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000101 # load color
    sw $t4 0($v0) # store color (13, 15)
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
    li $t4 0x2e1c13 # load color
    sw $t4 0($v0) # store color (3, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x935038 # load color
    sw $t4 0($v0) # store color (4, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf0ae8e # load color
    sw $t4 0($v0) # store color (5, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd0a1a8 # load color
    sw $t4 0($v0) # store color (6, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc0889e # load color
    sw $t4 0($v0) # store color (7, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd295a0 # load color
    sw $t4 0($v0) # store color (8, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf818d # load color
    sw $t4 0($v0) # store color (9, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xce9bad # load color
    sw $t4 0($v0) # store color (10, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9a939a # load color
    sw $t4 0($v0) # store color (11, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3a2d20 # load color
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
    li $t4 0x0b0705 # load color
    sw $t4 0($v0) # store color (1, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x583122 # load color
    sw $t4 0($v0) # store color (2, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd1815e # load color
    sw $t4 0($v0) # store color (3, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7cec0 # load color
    sw $t4 0($v0) # store color (4, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd798d # load color
    sw $t4 0($v0) # store color (5, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa33d5a # load color
    sw $t4 0($v0) # store color (6, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf7a86 # load color
    sw $t4 0($v0) # store color (7, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe09d99 # load color
    sw $t4 0($v0) # store color (8, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe19d9b # load color
    sw $t4 0($v0) # store color (9, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbb7680 # load color
    sw $t4 0($v0) # store color (10, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca738b # load color
    sw $t4 0($v0) # store color (11, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd2968e # load color
    sw $t4 0($v0) # store color (12, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x674c41 # load color
    sw $t4 0($v0) # store color (13, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x050303 # load color
    sw $t4 0($v0) # store color (14, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 1)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x714230 # load color
    sw $t4 0($v0) # store color (1, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc16c4c # load color
    sw $t4 0($v0) # store color (2, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdca29a # load color
    sw $t4 0($v0) # store color (3, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb66c81 # load color
    sw $t4 0($v0) # store color (4, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaa455c # load color
    sw $t4 0($v0) # store color (5, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe6b795 # load color
    sw $t4 0($v0) # store color (6, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9ca7d # load color
    sw $t4 0($v0) # store color (7, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c872 # load color
    sw $t4 0($v0) # store color (8, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8c871 # load color
    sw $t4 0($v0) # store color (9, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8c57c # load color
    sw $t4 0($v0) # store color (10, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe1b8a5 # load color
    sw $t4 0($v0) # store color (11, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdc9e9e # load color
    sw $t4 0($v0) # store color (12, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xecb285 # load color
    sw $t4 0($v0) # store color (13, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x835a38 # load color
    sw $t4 0($v0) # store color (14, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x050104 # load color
    sw $t4 0($v0) # store color (15, 2)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x321d15 # load color
    sw $t4 0($v0) # store color (0, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb96c4e # load color
    sw $t4 0($v0) # store color (1, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd59a65 # load color
    sw $t4 0($v0) # store color (2, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd1917a # load color
    sw $t4 0($v0) # store color (3, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb35a69 # load color
    sw $t4 0($v0) # store color (4, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedbf94 # load color
    sw $t4 0($v0) # store color (5, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdc7d # load color
    sw $t4 0($v0) # store color (6, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffde76 # load color
    sw $t4 0($v0) # store color (7, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbe685 # load color
    sw $t4 0($v0) # store color (8, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe690 # load color
    sw $t4 0($v0) # store color (9, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcdc76 # load color
    sw $t4 0($v0) # store color (10, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdf85 # load color
    sw $t4 0($v0) # store color (11, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffeab9 # load color
    sw $t4 0($v0) # store color (12, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcd281 # load color
    sw $t4 0($v0) # store color (13, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xefc86d # load color
    sw $t4 0($v0) # store color (14, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3f2c1d # load color
    sw $t4 0($v0) # store color (15, 3)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x9e5c43 # load color
    sw $t4 0($v0) # store color (0, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbc6e50 # load color
    sw $t4 0($v0) # store color (1, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c371 # load color
    sw $t4 0($v0) # store color (2, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbd67c # load color
    sw $t4 0($v0) # store color (3, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeab374 # load color
    sw $t4 0($v0) # store color (4, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe0a2 # load color
    sw $t4 0($v0) # store color (5, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8d8b4 # load color
    sw $t4 0($v0) # store color (6, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xda9e64 # load color
    sw $t4 0($v0) # store color (7, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfee9a3 # load color
    sw $t4 0($v0) # store color (8, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffeabf # load color
    sw $t4 0($v0) # store color (9, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xde9f65 # load color
    sw $t4 0($v0) # store color (10, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfddd9c # load color
    sw $t4 0($v0) # store color (11, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9d79b # load color
    sw $t4 0($v0) # store color (12, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeeae6a # load color
    sw $t4 0($v0) # store color (13, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfedf7c # load color
    sw $t4 0($v0) # store color (14, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb79351 # load color
    sw $t4 0($v0) # store color (15, 4)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbc6c4f # load color
    sw $t4 0($v0) # store color (0, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xda935f # load color
    sw $t4 0($v0) # store color (1, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9d178 # load color
    sw $t4 0($v0) # store color (2, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad177 # load color
    sw $t4 0($v0) # store color (3, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7b773 # load color
    sw $t4 0($v0) # store color (4, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf4c672 # load color
    sw $t4 0($v0) # store color (5, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xba6a45 # load color
    sw $t4 0($v0) # store color (6, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc07d50 # load color
    sw $t4 0($v0) # store color (7, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe67b # load color
    sw $t4 0($v0) # store color (8, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe4a55a # load color
    sw $t4 0($v0) # store color (9, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0x904126 # load color
    sw $t4 0($v0) # store color (10, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xab6842 # load color
    sw $t4 0($v0) # store color (11, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdd17b # load color
    sw $t4 0($v0) # store color (12, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdda568 # load color
    sw $t4 0($v0) # store color (13, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf2b170 # load color
    sw $t4 0($v0) # store color (14, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd8bf68 # load color
    sw $t4 0($v0) # store color (15, 5)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbc6b4e # load color
    sw $t4 0($v0) # store color (0, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2a968 # load color
    sw $t4 0($v0) # store color (1, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebbd6e # load color
    sw $t4 0($v0) # store color (2, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdd279 # load color
    sw $t4 0($v0) # store color (3, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcc865e # load color
    sw $t4 0($v0) # store color (4, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x754737 # load color
    sw $t4 0($v0) # store color (5, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6e2d1f # load color
    sw $t4 0($v0) # store color (6, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa17657 # load color
    sw $t4 0($v0) # store color (7, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1b571 # load color
    sw $t4 0($v0) # store color (8, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd0836f # load color
    sw $t4 0($v0) # store color (9, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x615158 # load color
    sw $t4 0($v0) # store color (10, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x916060 # load color
    sw $t4 0($v0) # store color (11, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfab768 # load color
    sw $t4 0($v0) # store color (12, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc89d59 # load color
    sw $t4 0($v0) # store color (13, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb5694c # load color
    sw $t4 0($v0) # store color (14, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xceaf67 # load color
    sw $t4 0($v0) # store color (15, 6)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xce7a56 # load color
    sw $t4 0($v0) # store color (0, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe29f65 # load color
    sw $t4 0($v0) # store color (1, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd38a5b # load color
    sw $t4 0($v0) # store color (2, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdc7e # load color
    sw $t4 0($v0) # store color (3, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc18e56 # load color
    sw $t4 0($v0) # store color (4, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa49498 # load color
    sw $t4 0($v0) # store color (5, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x628388 # load color
    sw $t4 0($v0) # store color (6, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbeaca3 # load color
    sw $t4 0($v0) # store color (7, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcc8b6 # load color
    sw $t4 0($v0) # store color (8, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6e1d9 # load color
    sw $t4 0($v0) # store color (9, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x64acbd # load color
    sw $t4 0($v0) # store color (10, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc79d91 # load color
    sw $t4 0($v0) # store color (11, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd08c49 # load color
    sw $t4 0($v0) # store color (12, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb77b4a # load color
    sw $t4 0($v0) # store color (13, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x442519 # load color
    sw $t4 0($v0) # store color (14, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x58522d # load color
    sw $t4 0($v0) # store color (15, 7)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xd17b58 # load color
    sw $t4 0($v0) # store color (0, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdd855e # load color
    sw $t4 0($v0) # store color (1, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc37650 # load color
    sw $t4 0($v0) # store color (2, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeaa86b # load color
    sw $t4 0($v0) # store color (3, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe8a864 # load color
    sw $t4 0($v0) # store color (4, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc1b7b4 # load color
    sw $t4 0($v0) # store color (5, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2997ab # load color
    sw $t4 0($v0) # store color (6, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd5d9d5 # load color
    sw $t4 0($v0) # store color (7, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffefe5 # load color
    sw $t4 0($v0) # store color (8, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8ebe2 # load color
    sw $t4 0($v0) # store color (9, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbcd1cf # load color
    sw $t4 0($v0) # store color (10, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc98970 # load color
    sw $t4 0($v0) # store color (11, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdb7250 # load color
    sw $t4 0($v0) # store color (12, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7d4532 # load color
    sw $t4 0($v0) # store color (13, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x070302 # load color
    sw $t4 0($v0) # store color (14, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000202 # load color
    sw $t4 0($v0) # store color (15, 8)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x744334 # load color
    sw $t4 0($v0) # store color (0, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdc8260 # load color
    sw $t4 0($v0) # store color (1, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7d432e # load color
    sw $t4 0($v0) # store color (2, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x794732 # load color
    sw $t4 0($v0) # store color (3, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xda7f51 # load color
    sw $t4 0($v0) # store color (4, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf826e # load color
    sw $t4 0($v0) # store color (5, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdbbac1 # load color
    sw $t4 0($v0) # store color (6, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9d8d5 # load color
    sw $t4 0($v0) # store color (7, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe2d9 # load color
    sw $t4 0($v0) # store color (8, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfed9d3 # load color
    sw $t4 0($v0) # store color (9, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd09688 # load color
    sw $t4 0($v0) # store color (10, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca7250 # load color
    sw $t4 0($v0) # store color (11, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcd734f # load color
    sw $t4 0($v0) # store color (12, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4f2c20 # load color
    sw $t4 0($v0) # store color (13, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010000 # load color
    sw $t4 0($v0) # store color (15, 9)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x010001 # load color
    sw $t4 0($v0) # store color (0, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x734434 # load color
    sw $t4 0($v0) # store color (1, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x44241c # load color
    sw $t4 0($v0) # store color (2, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x160900 # load color
    sw $t4 0($v0) # store color (3, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8f4927 # load color
    sw $t4 0($v0) # store color (4, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdea698 # load color
    sw $t4 0($v0) # store color (5, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdae1 # load color
    sw $t4 0($v0) # store color (6, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5c1bc # load color
    sw $t4 0($v0) # store color (7, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbe4f5a # load color
    sw $t4 0($v0) # store color (8, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdca5ad # load color
    sw $t4 0($v0) # store color (9, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcaacae # load color
    sw $t4 0($v0) # store color (10, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb7645b # load color
    sw $t4 0($v0) # store color (11, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2b0f00 # load color
    sw $t4 0($v0) # store color (12, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x090300 # load color
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
    sw $0 0($v0) # store background (2, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x111926 # load color
    sw $t4 0($v0) # store color (3, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x201c1d # load color
    sw $t4 0($v0) # store color (4, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x88777e # load color
    sw $t4 0($v0) # store color (5, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbaa8bc # load color
    sw $t4 0($v0) # store color (6, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb88b95 # load color
    sw $t4 0($v0) # store color (7, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca9ba0 # load color
    sw $t4 0($v0) # store color (8, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc4959c # load color
    sw $t4 0($v0) # store color (9, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x968c9e # load color
    sw $t4 0($v0) # store color (10, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x352b42 # load color
    sw $t4 0($v0) # store color (11, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x16253d # load color
    sw $t4 0($v0) # store color (12, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x070b13 # load color
    sw $t4 0($v0) # store color (13, 11)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000101 # load color
    sw $t4 0($v0) # store color (15, 11)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x010101 # load color
    sw $t4 0($v0) # store color (0, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x161c26 # load color
    sw $t4 0($v0) # store color (2, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2f3d59 # load color
    sw $t4 0($v0) # store color (3, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x253e61 # load color
    sw $t4 0($v0) # store color (4, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x263f6b # load color
    sw $t4 0($v0) # store color (5, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x323554 # load color
    sw $t4 0($v0) # store color (6, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x707ea1 # load color
    sw $t4 0($v0) # store color (7, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8590a6 # load color
    sw $t4 0($v0) # store color (8, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x767f8f # load color
    sw $t4 0($v0) # store color (9, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2d3755 # load color
    sw $t4 0($v0) # store color (10, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x202944 # load color
    sw $t4 0($v0) # store color (11, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3a537f # load color
    sw $t4 0($v0) # store color (12, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2f436a # load color
    sw $t4 0($v0) # store color (13, 12)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000001 # load color
    sw $t4 0($v0) # store color (15, 12)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x000101 # load color
    sw $t4 0($v0) # store color (0, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x030506 # load color
    sw $t4 0($v0) # store color (1, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x323d58 # load color
    sw $t4 0($v0) # store color (2, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x35486f # load color
    sw $t4 0($v0) # store color (3, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x425b8a # load color
    sw $t4 0($v0) # store color (4, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x374060 # load color
    sw $t4 0($v0) # store color (5, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x293059 # load color
    sw $t4 0($v0) # store color (6, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa9a7c3 # load color
    sw $t4 0($v0) # store color (7, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf0ebf6 # load color
    sw $t4 0($v0) # store color (8, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe9e5f2 # load color
    sw $t4 0($v0) # store color (9, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8c94b2 # load color
    sw $t4 0($v0) # store color (10, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x616583 # load color
    sw $t4 0($v0) # store color (11, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x415886 # load color
    sw $t4 0($v0) # store color (12, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x111b2b # load color
    sw $t4 0($v0) # store color (13, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000001 # load color
    sw $t4 0($v0) # store color (14, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000101 # load color
    sw $t4 0($v0) # store color (15, 13)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x000001 # load color
    sw $t4 0($v0) # store color (0, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (1, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x161922 # load color
    sw $t4 0($v0) # store color (2, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4c597c # load color
    sw $t4 0($v0) # store color (3, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x414968 # load color
    sw $t4 0($v0) # store color (4, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x737693 # load color
    sw $t4 0($v0) # store color (5, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa4afc5 # load color
    sw $t4 0($v0) # store color (6, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x727897 # load color
    sw $t4 0($v0) # store color (7, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x70809c # load color
    sw $t4 0($v0) # store color (8, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa4acc5 # load color
    sw $t4 0($v0) # store color (9, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8a869d # load color
    sw $t4 0($v0) # store color (10, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x344160 # load color
    sw $t4 0($v0) # store color (11, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x121d2e # load color
    sw $t4 0($v0) # store color (12, 14)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (13, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010102 # load color
    sw $t4 0($v0) # store color (14, 14)
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
    li $t4 0x08090b # load color
    sw $t4 0($v0) # store color (3, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x121216 # load color
    sw $t4 0($v0) # store color (4, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x666c8e # load color
    sw $t4 0($v0) # store color (5, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8185a8 # load color
    sw $t4 0($v0) # store color (6, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4b4f65 # load color
    sw $t4 0($v0) # store color (7, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x272e43 # load color
    sw $t4 0($v0) # store color (8, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4b5376 # load color
    sw $t4 0($v0) # store color (9, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4b526e # load color
    sw $t4 0($v0) # store color (10, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (11, 15)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (12, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000101 # load color
    sw $t4 0($v0) # store color (13, 15)
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
    li $t4 0x020201 # load color
    sw $t4 0($v0) # store color (2, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3c241b # load color
    sw $t4 0($v0) # store color (3, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9f5f48 # load color
    sw $t4 0($v0) # store color (4, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeaa790 # load color
    sw $t4 0($v0) # store color (5, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcfa1aa # load color
    sw $t4 0($v0) # store color (6, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc58c9e # load color
    sw $t4 0($v0) # store color (7, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd1949e # load color
    sw $t4 0($v0) # store color (8, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc58690 # load color
    sw $t4 0($v0) # store color (9, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc79eae # load color
    sw $t4 0($v0) # store color (10, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x857b7d # load color
    sw $t4 0($v0) # store color (11, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2b1d14 # load color
    sw $t4 0($v0) # store color (12, 0)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010000 # load color
    sw $t4 0($v0) # store color (13, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 0)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 0)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    sw $0 0($v0) # store background (0, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x120b07 # load color
    sw $t4 0($v0) # store color (1, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x663a2a # load color
    sw $t4 0($v0) # store color (2, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd28666 # load color
    sw $t4 0($v0) # store color (3, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe7bbb4 # load color
    sw $t4 0($v0) # store color (4, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xba6e80 # load color
    sw $t4 0($v0) # store color (5, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xac5065 # load color
    sw $t4 0($v0) # store color (6, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc98c8f # load color
    sw $t4 0($v0) # store color (7, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe4a89f # load color
    sw $t4 0($v0) # store color (8, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe0a49d # load color
    sw $t4 0($v0) # store color (9, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf7b83 # load color
    sw $t4 0($v0) # store color (10, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcc7b8b # load color
    sw $t4 0($v0) # store color (11, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc28f83 # load color
    sw $t4 0($v0) # store color (12, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4f3a30 # load color
    sw $t4 0($v0) # store color (13, 1)
    add $v0 $v0 $t0 # shift x
    li $t4 0x060302 # load color
    sw $t4 0($v0) # store color (14, 1)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 1)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x050302 # load color
    sw $t4 0($v0) # store color (0, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7b4834 # load color
    sw $t4 0($v0) # store color (1, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc47353 # load color
    sw $t4 0($v0) # store color (2, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd9a098 # load color
    sw $t4 0($v0) # store color (3, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb86778 # load color
    sw $t4 0($v0) # store color (4, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb7626d # load color
    sw $t4 0($v0) # store color (5, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xeab88d # load color
    sw $t4 0($v0) # store color (6, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c574 # load color
    sw $t4 0($v0) # store color (7, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c56f # load color
    sw $t4 0($v0) # store color (8, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7c56e # load color
    sw $t4 0($v0) # store color (9, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3bf80 # load color
    sw $t4 0($v0) # store color (10, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe4bba9 # load color
    sw $t4 0($v0) # store color (11, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe5a79c # load color
    sw $t4 0($v0) # store color (12, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdaa774 # load color
    sw $t4 0($v0) # store color (13, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x66442c # load color
    sw $t4 0($v0) # store color (14, 2)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000002 # load color
    sw $t4 0($v0) # store color (15, 2)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x3d241a # load color
    sw $t4 0($v0) # store color (0, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xba6f50 # load color
    sw $t4 0($v0) # store color (1, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xda9f68 # load color
    sw $t4 0($v0) # store color (2, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd09078 # load color
    sw $t4 0($v0) # store color (3, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc07072 # load color
    sw $t4 0($v0) # store color (4, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1c491 # load color
    sw $t4 0($v0) # store color (5, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffdd83 # load color
    sw $t4 0($v0) # store color (6, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcdc77 # load color
    sw $t4 0($v0) # store color (7, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfce48b # load color
    sw $t4 0($v0) # store color (8, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe48f # load color
    sw $t4 0($v0) # store color (9, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcd979 # load color
    sw $t4 0($v0) # store color (10, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffe394 # load color
    sw $t4 0($v0) # store color (11, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcdca9 # load color
    sw $t4 0($v0) # store color (12, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8cf79 # load color
    sw $t4 0($v0) # store color (13, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcdaa5e # load color
    sw $t4 0($v0) # store color (14, 3)
    add $v0 $v0 $t0 # shift x
    li $t4 0x271a12 # load color
    sw $t4 0($v0) # store color (15, 3)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xa66246 # load color
    sw $t4 0($v0) # store color (0, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc27753 # load color
    sw $t4 0($v0) # store color (1, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5c472 # load color
    sw $t4 0($v0) # store color (2, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf9d17b # load color
    sw $t4 0($v0) # store color (3, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xecb475 # load color
    sw $t4 0($v0) # store color (4, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbdba1 # load color
    sw $t4 0($v0) # store color (5, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xebc09b # load color
    sw $t4 0($v0) # store color (6, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdda769 # load color
    sw $t4 0($v0) # store color (7, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffeaa6 # load color
    sw $t4 0($v0) # store color (8, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8d8a8 # load color
    sw $t4 0($v0) # store color (9, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7995f # load color
    sw $t4 0($v0) # store color (10, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfada9f # load color
    sw $t4 0($v0) # store color (11, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7cc8a # load color
    sw $t4 0($v0) # store color (12, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xedb46e # load color
    sw $t4 0($v0) # store color (13, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf7d273 # load color
    sw $t4 0($v0) # store color (14, 4)
    add $v0 $v0 $t0 # shift x
    li $t4 0x967643 # load color
    sw $t4 0($v0) # store color (15, 4)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbd6f50 # load color
    sw $t4 0($v0) # store color (0, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xde9b62 # load color
    sw $t4 0($v0) # store color (1, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf8cf77 # load color
    sw $t4 0($v0) # store color (2, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfad078 # load color
    sw $t4 0($v0) # store color (3, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf1b271 # load color
    sw $t4 0($v0) # store color (4, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe2af67 # load color
    sw $t4 0($v0) # store color (5, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb06240 # load color
    sw $t4 0($v0) # store color (6, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb905a # load color
    sw $t4 0($v0) # store color (7, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcd974 # load color
    sw $t4 0($v0) # store color (8, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd48e53 # load color
    sw $t4 0($v0) # store color (9, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0x88452d # load color
    sw $t4 0($v0) # store color (10, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd7b50 # load color
    sw $t4 0($v0) # store color (11, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfbcf77 # load color
    sw $t4 0($v0) # store color (12, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd69962 # load color
    sw $t4 0($v0) # store color (13, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3bd72 # load color
    sw $t4 0($v0) # store color (14, 5)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaf9c56 # load color
    sw $t4 0($v0) # store color (15, 5)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xbf7151 # load color
    sw $t4 0($v0) # store color (0, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe3a967 # load color
    sw $t4 0($v0) # store color (1, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe8b66c # load color
    sw $t4 0($v0) # store color (2, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdd179 # load color
    sw $t4 0($v0) # store color (3, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd7b56 # load color
    sw $t4 0($v0) # store color (4, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x73493d # load color
    sw $t4 0($v0) # store color (5, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x70382a # load color
    sw $t4 0($v0) # store color (6, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb08663 # load color
    sw $t4 0($v0) # store color (7, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xecad76 # load color
    sw $t4 0($v0) # store color (8, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc7897b # load color
    sw $t4 0($v0) # store color (9, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0x625d66 # load color
    sw $t4 0($v0) # store color (10, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb47563 # load color
    sw $t4 0($v0) # store color (11, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf6c26c # load color
    sw $t4 0($v0) # store color (12, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb7814d # load color
    sw $t4 0($v0) # store color (13, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb77a51 # load color
    sw $t4 0($v0) # store color (14, 6)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaa9756 # load color
    sw $t4 0($v0) # store color (15, 6)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xcd7956 # load color
    sw $t4 0($v0) # store color (0, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe19b64 # load color
    sw $t4 0($v0) # store color (1, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd28a5b # load color
    sw $t4 0($v0) # store color (2, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfacf78 # load color
    sw $t4 0($v0) # store color (3, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc3935e # load color
    sw $t4 0($v0) # store color (4, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xaba2a5 # load color
    sw $t4 0($v0) # store color (5, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5d878e # load color
    sw $t4 0($v0) # store color (6, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd9c0b5 # load color
    sw $t4 0($v0) # store color (7, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfdd2c4 # load color
    sw $t4 0($v0) # store color (8, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe6dbd6 # load color
    sw $t4 0($v0) # store color (9, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x78acb6 # load color
    sw $t4 0($v0) # store color (10, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca8b71 # load color
    sw $t4 0($v0) # store color (11, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0xce8a4f # load color
    sw $t4 0($v0) # store color (12, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x905937 # load color
    sw $t4 0($v0) # store color (13, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x362517 # load color
    sw $t4 0($v0) # store color (14, 7)
    add $v0 $v0 $t0 # shift x
    li $t4 0x454023 # load color
    sw $t4 0($v0) # store color (15, 7)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0xc67555 # load color
    sw $t4 0($v0) # store color (0, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd9825d # load color
    sw $t4 0($v0) # store color (1, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xba704c # load color
    sw $t4 0($v0) # store color (2, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdc9862 # load color
    sw $t4 0($v0) # store color (3, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdca067 # load color
    sw $t4 0($v0) # store color (4, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xb4b0b0 # load color
    sw $t4 0($v0) # store color (5, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4599aa # load color
    sw $t4 0($v0) # store color (6, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe8e0da # load color
    sw $t4 0($v0) # store color (7, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xffebe3 # load color
    sw $t4 0($v0) # store color (8, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5e7e0 # load color
    sw $t4 0($v0) # store color (9, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc8c1ba # load color
    sw $t4 0($v0) # store color (10, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc8785b # load color
    sw $t4 0($v0) # store color (11, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd67453 # load color
    sw $t4 0($v0) # store color (12, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4f2b1f # load color
    sw $t4 0($v0) # store color (13, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x010001 # load color
    sw $t4 0($v0) # store color (14, 8)
    add $v0 $v0 $t0 # shift x
    li $t4 0x000202 # load color
    sw $t4 0($v0) # store color (15, 8)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x683c2f # load color
    sw $t4 0($v0) # store color (0, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc87657 # load color
    sw $t4 0($v0) # store color (1, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x76402c # load color
    sw $t4 0($v0) # store color (2, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x78462f # load color
    sw $t4 0($v0) # store color (3, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcb764e # load color
    sw $t4 0($v0) # store color (4, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xca8b7a # load color
    sw $t4 0($v0) # store color (5, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xefc2c6 # load color
    sw $t4 0($v0) # store color (6, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfcd4cf # load color
    sw $t4 0($v0) # store color (7, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xfccdc7 # load color
    sw $t4 0($v0) # store color (8, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf5c7c3 # load color
    sw $t4 0($v0) # store color (9, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xc08272 # load color
    sw $t4 0($v0) # store color (10, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xcc7351 # load color
    sw $t4 0($v0) # store color (11, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa35a3c # load color
    sw $t4 0($v0) # store color (12, 9)
    add $v0 $v0 $t0 # shift x
    li $t4 0x291710 # load color
    sw $t4 0($v0) # store color (13, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (14, 9)
    add $v0 $v0 $t0 # shift x
    sw $0 0($v0) # store background (15, 9)
    add $v0 $v0 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v0 $t2 # carriage return
    li $t4 0x030102 # load color
    sw $t4 0($v0) # store color (0, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x4c2c23 # load color
    sw $t4 0($v0) # store color (1, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2c1714 # load color
    sw $t4 0($v0) # store color (2, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x160b06 # load color
    sw $t4 0($v0) # store color (3, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x814b30 # load color
    sw $t4 0($v0) # store color (4, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xdcb1aa # load color
    sw $t4 0($v0) # store color (5, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xf3d2d8 # load color
    sw $t4 0($v0) # store color (6, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xe0a6a8 # load color
    sw $t4 0($v0) # store color (7, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbd5764 # load color
    sw $t4 0($v0) # store color (8, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd7acb3 # load color
    sw $t4 0($v0) # store color (9, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbf9da3 # load color
    sw $t4 0($v0) # store color (10, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x834843 # load color
    sw $t4 0($v0) # store color (11, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x110702 # load color
    sw $t4 0($v0) # store color (12, 10)
    add $v0 $v0 $t0 # shift x
    li $t4 0x030201 # load color
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
    li $t4 0x04070b # load color
    sw $t4 0($v0) # store color (2, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x12161e # load color
    sw $t4 0($v0) # store color (3, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1b1d25 # load color
    sw $t4 0($v0) # store color (4, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x6c6679 # load color
    sw $t4 0($v0) # store color (5, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x94839b # load color
    sw $t4 0($v0) # store color (6, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa98f9e # load color
    sw $t4 0($v0) # store color (7, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xbda3aa # load color
    sw $t4 0($v0) # store color (8, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0xac919a # load color
    sw $t4 0($v0) # store color (9, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x615d76 # load color
    sw $t4 0($v0) # store color (10, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x22273f # load color
    sw $t4 0($v0) # store color (11, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1a2438 # load color
    sw $t4 0($v0) # store color (12, 11)
    add $v0 $v0 $t0 # shift x
    li $t4 0x080b13 # load color
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
    li $t4 0x131821 # load color
    sw $t4 0($v0) # store color (2, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1a2130 # load color
    sw $t4 0($v0) # store color (3, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2c456d # load color
    sw $t4 0($v0) # store color (4, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x2c4069 # load color
    sw $t4 0($v0) # store color (5, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x353a5a # load color
    sw $t4 0($v0) # store color (6, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x8890ae # load color
    sw $t4 0($v0) # store color (7, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x979cae # load color
    sw $t4 0($v0) # store color (8, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x83889b # load color
    sw $t4 0($v0) # store color (9, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x394362 # load color
    sw $t4 0($v0) # store color (10, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x323a59 # load color
    sw $t4 0($v0) # store color (11, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3b5686 # load color
    sw $t4 0($v0) # store color (12, 12)
    add $v0 $v0 $t0 # shift x
    li $t4 0x171f2f # load color
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
    li $t4 0x050609 # load color
    sw $t4 0($v0) # store color (1, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x181d27 # load color
    sw $t4 0($v0) # store color (2, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x3c4f77 # load color
    sw $t4 0($v0) # store color (3, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x455983 # load color
    sw $t4 0($v0) # store color (4, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x414969 # load color
    sw $t4 0($v0) # store color (5, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x414c73 # load color
    sw $t4 0($v0) # store color (6, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xa2a4bf # load color
    sw $t4 0($v0) # store color (7, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd8d8e6 # load color
    sw $t4 0($v0) # store color (8, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0xd3d3e5 # load color
    sw $t4 0($v0) # store color (9, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7e85a4 # load color
    sw $t4 0($v0) # store color (10, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x5e678b # load color
    sw $t4 0($v0) # store color (11, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1d293e # load color
    sw $t4 0($v0) # store color (12, 13)
    add $v0 $v0 $t0 # shift x
    li $t4 0x05070b # load color
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
    li $t4 0x0e1015 # load color
    sw $t4 0($v0) # store color (2, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1f2531 # load color
    sw $t4 0($v0) # store color (3, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x252937 # load color
    sw $t4 0($v0) # store color (4, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x7c809e # load color
    sw $t4 0($v0) # store color (5, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0xacb2c8 # load color
    sw $t4 0($v0) # store color (6, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x717896 # load color
    sw $t4 0($v0) # store color (7, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x627292 # load color
    sw $t4 0($v0) # store color (8, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x9298b3 # load color
    sw $t4 0($v0) # store color (9, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x605f74 # load color
    sw $t4 0($v0) # store color (10, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x172133 # load color
    sw $t4 0($v0) # store color (11, 14)
    add $v0 $v0 $t0 # shift x
    li $t4 0x030509 # load color
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
    li $t4 0x1b1c22 # load color
    sw $t4 0($v0) # store color (4, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x62698c # load color
    sw $t4 0($v0) # store color (5, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x666e94 # load color
    sw $t4 0($v0) # store color (6, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x292d3c # load color
    sw $t4 0($v0) # store color (7, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x1d202d # load color
    sw $t4 0($v0) # store color (8, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x454e71 # load color
    sw $t4 0($v0) # store color (9, 15)
    add $v0 $v0 $t0 # shift x
    li $t4 0x323a51 # load color
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
    sw $0 40($v0) # (10, 0)
    sw $0 44($v0) # (11, 0)
    sw $0 48($v0) # (12, 0)
    sw $0 52($v0) # (13, 0)
    sw $0 56($v0) # (14, 0)
    sw $0 60($v0) # (15, 0)
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
    sw $0 552($v0) # (10, 1)
    sw $0 556($v0) # (11, 1)
    sw $0 560($v0) # (12, 1)
    sw $0 564($v0) # (13, 1)
    sw $0 568($v0) # (14, 1)
    sw $0 572($v0) # (15, 1)
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
    sw $0 1064($v0) # (10, 2)
    sw $0 1068($v0) # (11, 2)
    sw $0 1072($v0) # (12, 2)
    sw $0 1076($v0) # (13, 2)
    sw $0 1080($v0) # (14, 2)
    sw $0 1084($v0) # (15, 2)
    sw $0 1536($v0) # (0, 3)
    sw $0 1540($v0) # (1, 3)
    sw $0 1544($v0) # (2, 3)
    sw $0 1548($v0) # (3, 3)
    sw $0 1552($v0) # (4, 3)
    sw $0 1556($v0) # (5, 3)
    sw $0 1560($v0) # (6, 3)
    sw $0 1564($v0) # (7, 3)
    sw $0 1568($v0) # (8, 3)
    sw $0 1572($v0) # (9, 3)
    sw $0 1576($v0) # (10, 3)
    sw $0 1580($v0) # (11, 3)
    sw $0 1584($v0) # (12, 3)
    sw $0 1588($v0) # (13, 3)
    sw $0 1592($v0) # (14, 3)
    sw $0 1596($v0) # (15, 3)
    sw $0 2048($v0) # (0, 4)
    sw $0 2052($v0) # (1, 4)
    sw $0 2056($v0) # (2, 4)
    sw $0 2060($v0) # (3, 4)
    sw $0 2064($v0) # (4, 4)
    sw $0 2068($v0) # (5, 4)
    sw $0 2072($v0) # (6, 4)
    sw $0 2076($v0) # (7, 4)
    sw $0 2080($v0) # (8, 4)
    sw $0 2084($v0) # (9, 4)
    sw $0 2088($v0) # (10, 4)
    sw $0 2092($v0) # (11, 4)
    sw $0 2096($v0) # (12, 4)
    sw $0 2100($v0) # (13, 4)
    sw $0 2104($v0) # (14, 4)
    sw $0 2108($v0) # (15, 4)
    sw $0 2560($v0) # (0, 5)
    sw $0 2564($v0) # (1, 5)
    sw $0 2568($v0) # (2, 5)
    sw $0 2572($v0) # (3, 5)
    sw $0 2576($v0) # (4, 5)
    sw $0 2580($v0) # (5, 5)
    sw $0 2584($v0) # (6, 5)
    sw $0 2588($v0) # (7, 5)
    sw $0 2592($v0) # (8, 5)
    sw $0 2596($v0) # (9, 5)
    sw $0 2600($v0) # (10, 5)
    sw $0 2604($v0) # (11, 5)
    sw $0 2608($v0) # (12, 5)
    sw $0 2612($v0) # (13, 5)
    sw $0 2616($v0) # (14, 5)
    sw $0 2620($v0) # (15, 5)
    sw $0 3072($v0) # (0, 6)
    sw $0 3076($v0) # (1, 6)
    sw $0 3080($v0) # (2, 6)
    sw $0 3084($v0) # (3, 6)
    sw $0 3088($v0) # (4, 6)
    sw $0 3092($v0) # (5, 6)
    sw $0 3096($v0) # (6, 6)
    sw $0 3100($v0) # (7, 6)
    sw $0 3104($v0) # (8, 6)
    sw $0 3108($v0) # (9, 6)
    sw $0 3112($v0) # (10, 6)
    sw $0 3116($v0) # (11, 6)
    sw $0 3120($v0) # (12, 6)
    sw $0 3124($v0) # (13, 6)
    sw $0 3128($v0) # (14, 6)
    sw $0 3132($v0) # (15, 6)
    sw $0 3584($v0) # (0, 7)
    sw $0 3588($v0) # (1, 7)
    sw $0 3592($v0) # (2, 7)
    sw $0 3596($v0) # (3, 7)
    sw $0 3600($v0) # (4, 7)
    sw $0 3604($v0) # (5, 7)
    sw $0 3608($v0) # (6, 7)
    sw $0 3612($v0) # (7, 7)
    sw $0 3616($v0) # (8, 7)
    sw $0 3620($v0) # (9, 7)
    sw $0 3624($v0) # (10, 7)
    sw $0 3628($v0) # (11, 7)
    sw $0 3632($v0) # (12, 7)
    sw $0 3636($v0) # (13, 7)
    sw $0 3640($v0) # (14, 7)
    sw $0 3644($v0) # (15, 7)
    sw $0 4096($v0) # (0, 8)
    sw $0 4100($v0) # (1, 8)
    sw $0 4104($v0) # (2, 8)
    sw $0 4108($v0) # (3, 8)
    sw $0 4112($v0) # (4, 8)
    sw $0 4116($v0) # (5, 8)
    sw $0 4120($v0) # (6, 8)
    sw $0 4124($v0) # (7, 8)
    sw $0 4128($v0) # (8, 8)
    sw $0 4132($v0) # (9, 8)
    sw $0 4136($v0) # (10, 8)
    sw $0 4140($v0) # (11, 8)
    sw $0 4144($v0) # (12, 8)
    sw $0 4148($v0) # (13, 8)
    sw $0 4152($v0) # (14, 8)
    sw $0 4156($v0) # (15, 8)
    sw $0 4608($v0) # (0, 9)
    sw $0 4612($v0) # (1, 9)
    sw $0 4616($v0) # (2, 9)
    sw $0 4620($v0) # (3, 9)
    sw $0 4624($v0) # (4, 9)
    sw $0 4628($v0) # (5, 9)
    sw $0 4632($v0) # (6, 9)
    sw $0 4636($v0) # (7, 9)
    sw $0 4640($v0) # (8, 9)
    sw $0 4644($v0) # (9, 9)
    sw $0 4648($v0) # (10, 9)
    sw $0 4652($v0) # (11, 9)
    sw $0 4656($v0) # (12, 9)
    sw $0 4660($v0) # (13, 9)
    sw $0 4664($v0) # (14, 9)
    sw $0 4668($v0) # (15, 9)
    sw $0 5120($v0) # (0, 10)
    sw $0 5124($v0) # (1, 10)
    sw $0 5128($v0) # (2, 10)
    sw $0 5132($v0) # (3, 10)
    sw $0 5136($v0) # (4, 10)
    sw $0 5140($v0) # (5, 10)
    sw $0 5144($v0) # (6, 10)
    sw $0 5148($v0) # (7, 10)
    sw $0 5152($v0) # (8, 10)
    sw $0 5156($v0) # (9, 10)
    sw $0 5160($v0) # (10, 10)
    sw $0 5164($v0) # (11, 10)
    sw $0 5168($v0) # (12, 10)
    sw $0 5172($v0) # (13, 10)
    sw $0 5176($v0) # (14, 10)
    sw $0 5180($v0) # (15, 10)
    sw $0 5632($v0) # (0, 11)
    sw $0 5636($v0) # (1, 11)
    sw $0 5640($v0) # (2, 11)
    sw $0 5644($v0) # (3, 11)
    sw $0 5648($v0) # (4, 11)
    sw $0 5652($v0) # (5, 11)
    sw $0 5656($v0) # (6, 11)
    sw $0 5660($v0) # (7, 11)
    sw $0 5664($v0) # (8, 11)
    sw $0 5668($v0) # (9, 11)
    sw $0 5672($v0) # (10, 11)
    sw $0 5676($v0) # (11, 11)
    sw $0 5680($v0) # (12, 11)
    sw $0 5684($v0) # (13, 11)
    sw $0 5688($v0) # (14, 11)
    sw $0 5692($v0) # (15, 11)
    sw $0 6144($v0) # (0, 12)
    sw $0 6148($v0) # (1, 12)
    sw $0 6152($v0) # (2, 12)
    sw $0 6156($v0) # (3, 12)
    sw $0 6160($v0) # (4, 12)
    sw $0 6164($v0) # (5, 12)
    sw $0 6168($v0) # (6, 12)
    sw $0 6172($v0) # (7, 12)
    sw $0 6176($v0) # (8, 12)
    sw $0 6180($v0) # (9, 12)
    sw $0 6184($v0) # (10, 12)
    sw $0 6188($v0) # (11, 12)
    sw $0 6192($v0) # (12, 12)
    sw $0 6196($v0) # (13, 12)
    sw $0 6200($v0) # (14, 12)
    sw $0 6204($v0) # (15, 12)
    sw $0 6656($v0) # (0, 13)
    sw $0 6660($v0) # (1, 13)
    sw $0 6664($v0) # (2, 13)
    sw $0 6668($v0) # (3, 13)
    sw $0 6672($v0) # (4, 13)
    sw $0 6676($v0) # (5, 13)
    sw $0 6680($v0) # (6, 13)
    sw $0 6684($v0) # (7, 13)
    sw $0 6688($v0) # (8, 13)
    sw $0 6692($v0) # (9, 13)
    sw $0 6696($v0) # (10, 13)
    sw $0 6700($v0) # (11, 13)
    sw $0 6704($v0) # (12, 13)
    sw $0 6708($v0) # (13, 13)
    sw $0 6712($v0) # (14, 13)
    sw $0 6716($v0) # (15, 13)
    sw $0 7168($v0) # (0, 14)
    sw $0 7172($v0) # (1, 14)
    sw $0 7176($v0) # (2, 14)
    sw $0 7180($v0) # (3, 14)
    sw $0 7184($v0) # (4, 14)
    sw $0 7188($v0) # (5, 14)
    sw $0 7192($v0) # (6, 14)
    sw $0 7196($v0) # (7, 14)
    sw $0 7200($v0) # (8, 14)
    sw $0 7204($v0) # (9, 14)
    sw $0 7208($v0) # (10, 14)
    sw $0 7212($v0) # (11, 14)
    sw $0 7216($v0) # (12, 14)
    sw $0 7220($v0) # (13, 14)
    sw $0 7224($v0) # (14, 14)
    sw $0 7228($v0) # (15, 14)
    sw $0 7680($v0) # (0, 15)
    sw $0 7684($v0) # (1, 15)
    sw $0 7688($v0) # (2, 15)
    sw $0 7692($v0) # (3, 15)
    sw $0 7696($v0) # (4, 15)
    sw $0 7700($v0) # (5, 15)
    sw $0 7704($v0) # (6, 15)
    sw $0 7708($v0) # (7, 15)
    sw $0 7712($v0) # (8, 15)
    sw $0 7716($v0) # (9, 15)
    sw $0 7720($v0) # (10, 15)
    sw $0 7724($v0) # (11, 15)
    sw $0 7728($v0) # (12, 15)
    sw $0 7732($v0) # (13, 15)
    sw $0 7736($v0) # (14, 15)
    sw $0 7740($v0) # (15, 15)
    jr $ra

draw_doll_00: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 4($v0)
    sw $t4 16($v0)
    sw $t4 20($v0)
    sw $t4 28($v0)
    sw $t4 32($v0)
    sw $t4 36($v0)
    sw $t4 512($v0)
    sw $t4 516($v0)
    sw $t4 520($v0)
    sw $t4 524($v0)
    sw $t4 536($v0)
    sw $t4 544($v0)
    sw $t4 548($v0)
    sw $t4 1060($v0)
    sw $t4 1536($v0)
    sw $t4 1540($v0)
    sw $t4 1568($v0)
    sw $t4 2080($v0)
    sw $t4 3584($v0)
    sw $t4 3616($v0)
    sw $t4 3620($v0)
    sw $t4 4128($v0)
    sw $t4 4132($v0)
    sw $t4 4644($v0)
    sw $t4 5156($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5652($v0)
    sw $t4 5660($v0)
    sw $t4 5664($v0)
    sw $t4 5668($v0)
    li $t4 0x010100
    sw $t4 8($v0)
    sw $t4 540($v0)
    li $t4 0x000100
    sw $t4 12($v0)
    sw $t4 3104($v0)
    sw $t4 4612($v0)
    sw $t4 5124($v0)
    sw $t4 5148($v0)
    sw $t4 5656($v0)
    li $t4 0x030201
    sw $t4 24($v0)
    sw $t4 4636($v0)
    li $t4 0x140b07
    sw $t4 528($v0)
    li $t4 0x0c0504
    sw $t4 532($v0)
    li $t4 0x030202
    sw $t4 1024($v0)
    li $t4 0x040403
    sw $t4 1028($v0)
    li $t4 0x1b060a
    sw $t4 1032($v0)
    li $t4 0xad523b
    sw $t4 1036($v0)
    li $t4 0xcd3f42
    sw $t4 1040($v0)
    li $t4 0xc94d41
    sw $t4 1044($v0)
    li $t4 0x5a2620
    sw $t4 1048($v0)
    li $t4 0x000001
    sw $t4 1052($v0)
    li $t4 0x010101
    sw $t4 1056($v0)
    sw $t4 2596($v0)
    li $t4 0x925432
    sw $t4 1544($v0)
    li $t4 0xfab252
    sw $t4 1548($v0)
    li $t4 0xd77f46
    sw $t4 1552($v0)
    li $t4 0xcf7446
    sw $t4 1556($v0)
    li $t4 0xe1934b
    sw $t4 1560($v0)
    li $t4 0x170705
    sw $t4 1564($v0)
    li $t4 0x020101
    sw $t4 1572($v0)
    sw $t4 2084($v0)
    li $t4 0x6a6a68
    sw $t4 2048($v0)
    li $t4 0x616168
    sw $t4 2052($v0)
    li $t4 0xa04e37
    sw $t4 2056($v0)
    li $t4 0xd47550
    sw $t4 2060($v0)
    li $t4 0x984441
    sw $t4 2064($v0)
    li $t4 0xbe6452
    sw $t4 2068($v0)
    li $t4 0xad3042
    sw $t4 2072($v0)
    li $t4 0x533237
    sw $t4 2076($v0)
    li $t4 0xcac8c8
    sw $t4 2560($v0)
    li $t4 0xe5ebeb
    sw $t4 2564($v0)
    li $t4 0xaa4262
    sw $t4 2568($v0)
    li $t4 0xac3745
    sw $t4 2572($v0)
    li $t4 0xc9847b
    sw $t4 2576($v0)
    li $t4 0xde947b
    sw $t4 2580($v0)
    li $t4 0x971143
    sw $t4 2584($v0)
    li $t4 0x594b54
    sw $t4 2588($v0)
    li $t4 0x000101
    sw $t4 2592($v0)
    li $t4 0x646262
    sw $t4 3072($v0)
    li $t4 0xc1cecb
    sw $t4 3076($v0)
    li $t4 0x964667
    sw $t4 3080($v0)
    li $t4 0x975971
    sw $t4 3084($v0)
    li $t4 0x8e8d84
    sw $t4 3088($v0)
    li $t4 0xad9fa1
    sw $t4 3092($v0)
    li $t4 0x963760
    sw $t4 3096($v0)
    li $t4 0x3c2c30
    sw $t4 3100($v0)
    li $t4 0x020102
    sw $t4 3108($v0)
    li $t4 0x332e28
    sw $t4 3588($v0)
    li $t4 0xa6415c
    sw $t4 3592($v0)
    li $t4 0x673347
    sw $t4 3596($v0)
    li $t4 0x8b4b67
    sw $t4 3600($v0)
    li $t4 0x882b4f
    sw $t4 3604($v0)
    li $t4 0x7c3642
    sw $t4 3608($v0)
    li $t4 0x060000
    sw $t4 3612($v0)
    li $t4 0x030303
    sw $t4 4096($v0)
    li $t4 0x220d0e
    sw $t4 4100($v0)
    li $t4 0x85143a
    sw $t4 4104($v0)
    li $t4 0x67223e
    sw $t4 4108($v0)
    li $t4 0x9d9295
    sw $t4 4112($v0)
    li $t4 0x916776
    sw $t4 4116($v0)
    li $t4 0x671229
    sw $t4 4120($v0)
    li $t4 0x060405
    sw $t4 4124($v0)
    li $t4 0x020001
    sw $t4 4608($v0)
    sw $t4 4640($v0)
    sw $t4 5152($v0)
    li $t4 0x53001e
    sw $t4 4616($v0)
    li $t4 0x95204b
    sw $t4 4620($v0)
    li $t4 0xd8f0e8
    sw $t4 4624($v0)
    li $t4 0xe0a7b9
    sw $t4 4628($v0)
    li $t4 0x38000c
    sw $t4 4632($v0)
    li $t4 0x010001
    sw $t4 5120($v0)
    li $t4 0x220811
    sw $t4 5128($v0)
    li $t4 0x771335
    sw $t4 5132($v0)
    li $t4 0x983857
    sw $t4 5136($v0)
    li $t4 0x94183f
    sw $t4 5140($v0)
    li $t4 0x200409
    sw $t4 5144($v0)
    li $t4 0x060704
    sw $t4 5640($v0)
    li $t4 0x2b2b22
    sw $t4 5644($v0)
    li $t4 0x190707
    sw $t4 5648($v0)
    jr $ra
draw_doll_01: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 4($v0)
    sw $t4 8($v0)
    sw $t4 12($v0)
    sw $t4 20($v0)
    sw $t4 24($v0)
    sw $t4 32($v0)
    sw $t4 36($v0)
    sw $t4 540($v0)
    sw $t4 548($v0)
    sw $t4 1028($v0)
    sw $t4 1056($v0)
    sw $t4 1568($v0)
    sw $t4 2048($v0)
    sw $t4 2052($v0)
    sw $t4 2076($v0)
    sw $t4 2084($v0)
    sw $t4 3616($v0)
    sw $t4 4132($v0)
    sw $t4 4608($v0)
    sw $t4 4612($v0)
    sw $t4 4644($v0)
    sw $t4 5148($v0)
    sw $t4 5152($v0)
    sw $t4 5156($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5660($v0)
    sw $t4 5664($v0)
    sw $t4 5668($v0)
    li $t4 0x000401
    sw $t4 16($v0)
    li $t4 0x010000
    sw $t4 28($v0)
    sw $t4 512($v0)
    sw $t4 1572($v0)
    sw $t4 5656($v0)
    li $t4 0x010100
    sw $t4 516($v0)
    li $t4 0x0c0205
    sw $t4 520($v0)
    li $t4 0x893d2f
    sw $t4 524($v0)
    li $t4 0xb23439
    sw $t4 528($v0)
    li $t4 0xaa3e37
    sw $t4 532($v0)
    li $t4 0x3a1115
    sw $t4 536($v0)
    li $t4 0x010101
    sw $t4 544($v0)
    sw $t4 2596($v0)
    sw $t4 5124($v0)
    li $t4 0x040201
    sw $t4 1024($v0)
    li $t4 0x803c2c
    sw $t4 1032($v0)
    li $t4 0xfba053
    sw $t4 1036($v0)
    li $t4 0xe17249
    sw $t4 1040($v0)
    li $t4 0xdc7b4b
    sw $t4 1044($v0)
    li $t4 0xde944b
    sw $t4 1048($v0)
    li $t4 0x170409
    sw $t4 1052($v0)
    li $t4 0x010001
    sw $t4 1060($v0)
    li $t4 0x050402
    sw $t4 1536($v0)
    li $t4 0x030403
    sw $t4 1540($v0)
    li $t4 0x9d4e36
    sw $t4 1544($v0)
    li $t4 0xd98a50
    sw $t4 1548($v0)
    li $t4 0x984939
    sw $t4 1552($v0)
    li $t4 0xbb6b48
    sw $t4 1556($v0)
    li $t4 0xbb6443
    sw $t4 1560($v0)
    li $t4 0x170509
    sw $t4 1564($v0)
    li $t4 0x55141a
    sw $t4 2056($v0)
    li $t4 0xc54c52
    sw $t4 2060($v0)
    li $t4 0xc27473
    sw $t4 2064($v0)
    li $t4 0xe28f78
    sw $t4 2068($v0)
    li $t4 0x850a31
    sw $t4 2072($v0)
    li $t4 0x000100
    sw $t4 2080($v0)
    sw $t4 2592($v0)
    sw $t4 5652($v0)
    li $t4 0x222020
    sw $t4 2560($v0)
    li $t4 0x555b5a
    sw $t4 2564($v0)
    li $t4 0x651c35
    sw $t4 2568($v0)
    li $t4 0xa55c73
    sw $t4 2572($v0)
    li $t4 0x8a8274
    sw $t4 2576($v0)
    li $t4 0xa58f8c
    sw $t4 2580($v0)
    li $t4 0x942d58
    sw $t4 2584($v0)
    li $t4 0x48393f
    sw $t4 2588($v0)
    li $t4 0xc4c4c5
    sw $t4 3072($v0)
    li $t4 0xddddd8
    sw $t4 3076($v0)
    li $t4 0x9f3a59
    sw $t4 3080($v0)
    li $t4 0x714254
    sw $t4 3084($v0)
    li $t4 0x804f66
    sw $t4 3088($v0)
    li $t4 0x813554
    sw $t4 3092($v0)
    li $t4 0x933951
    sw $t4 3096($v0)
    li $t4 0x5a3543
    sw $t4 3100($v0)
    li $t4 0x000200
    sw $t4 3104($v0)
    sw $t4 4636($v0)
    li $t4 0x020001
    sw $t4 3108($v0)
    sw $t4 3620($v0)
    sw $t4 4128($v0)
    sw $t4 4640($v0)
    li $t4 0xcdd0d1
    sw $t4 3584($v0)
    li $t4 0xbbaeaa
    sw $t4 3588($v0)
    li $t4 0x841d3a
    sw $t4 3592($v0)
    li $t4 0x611e3a
    sw $t4 3596($v0)
    li $t4 0x8d6571
    sw $t4 3600($v0)
    li $t4 0x733149
    sw $t4 3604($v0)
    li $t4 0x8e1f3d
    sw $t4 3608($v0)
    li $t4 0x1f040e
    sw $t4 3612($v0)
    li $t4 0x4a4848
    sw $t4 4096($v0)
    li $t4 0x141717
    sw $t4 4100($v0)
    li $t4 0x2c0011
    sw $t4 4104($v0)
    li $t4 0x8a0837
    sw $t4 4108($v0)
    li $t4 0xd5ebe3
    sw $t4 4112($v0)
    li $t4 0xcda2b0
    sw $t4 4116($v0)
    li $t4 0x480011
    sw $t4 4120($v0)
    li $t4 0x020201
    sw $t4 4124($v0)
    li $t4 0x1b070f
    sw $t4 4616($v0)
    li $t4 0x850e37
    sw $t4 4620($v0)
    li $t4 0xa37e8c
    sw $t4 4624($v0)
    li $t4 0xa13356
    sw $t4 4628($v0)
    li $t4 0x290207
    sw $t4 4632($v0)
    li $t4 0x030303
    sw $t4 5120($v0)
    li $t4 0x090806
    sw $t4 5128($v0)
    li $t4 0x332c27
    sw $t4 5132($v0)
    li $t4 0x20050a
    sw $t4 5136($v0)
    li $t4 0x020000
    sw $t4 5140($v0)
    sw $t4 5640($v0)
    li $t4 0x000101
    sw $t4 5144($v0)
    li $t4 0x040000
    sw $t4 5644($v0)
    li $t4 0x020401
    sw $t4 5648($v0)
    jr $ra
draw_doll_02: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 8($v0)
    sw $t4 24($v0)
    sw $t4 32($v0)
    sw $t4 36($v0)
    sw $t4 540($v0)
    sw $t4 548($v0)
    sw $t4 1056($v0)
    sw $t4 1536($v0)
    sw $t4 1568($v0)
    sw $t4 3616($v0)
    sw $t4 4096($v0)
    sw $t4 4100($v0)
    sw $t4 4132($v0)
    sw $t4 4636($v0)
    sw $t4 4644($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5144($v0)
    sw $t4 5148($v0)
    sw $t4 5152($v0)
    sw $t4 5156($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5644($v0)
    sw $t4 5660($v0)
    sw $t4 5664($v0)
    sw $t4 5668($v0)
    li $t4 0x010000
    sw $t4 4($v0)
    sw $t4 5656($v0)
    li $t4 0x090104
    sw $t4 12($v0)
    li $t4 0x2a130e
    sw $t4 16($v0)
    li $t4 0x1f0b0a
    sw $t4 20($v0)
    li $t4 0x010100
    sw $t4 28($v0)
    sw $t4 516($v0)
    li $t4 0x020101
    sw $t4 512($v0)
    sw $t4 1060($v0)
    sw $t4 2596($v0)
    sw $t4 4128($v0)
    li $t4 0x250c0d
    sw $t4 520($v0)
    li $t4 0xbd5a41
    sw $t4 524($v0)
    li $t4 0xd44044
    sw $t4 528($v0)
    li $t4 0xd25745
    sw $t4 532($v0)
    li $t4 0x6f3827
    sw $t4 536($v0)
    li $t4 0x010101
    sw $t4 544($v0)
    sw $t4 3108($v0)
    li $t4 0x050603
    sw $t4 1024($v0)
    li $t4 0x000101
    sw $t4 1028($v0)
    sw $t4 2080($v0)
    li $t4 0xa05d38
    sw $t4 1032($v0)
    li $t4 0xf8bc50
    sw $t4 1036($v0)
    li $t4 0xd69645
    sw $t4 1040($v0)
    li $t4 0xe09f4a
    sw $t4 1044($v0)
    li $t4 0xe1974d
    sw $t4 1048($v0)
    li $t4 0x210c0e
    sw $t4 1052($v0)
    li $t4 0x1a0009
    sw $t4 1540($v0)
    li $t4 0xc34347
    sw $t4 1544($v0)
    li $t4 0xd07b50
    sw $t4 1548($v0)
    li $t4 0xab514d
    sw $t4 1552($v0)
    li $t4 0xca725a
    sw $t4 1556($v0)
    li $t4 0xa11c3e
    sw $t4 1560($v0)
    li $t4 0x210006
    sw $t4 1564($v0)
    li $t4 0x020001
    sw $t4 1572($v0)
    li $t4 0x2c2f2e
    sw $t4 2048($v0)
    li $t4 0x431629
    sw $t4 2052($v0)
    li $t4 0x880530
    sw $t4 2056($v0)
    li $t4 0xab3f51
    sw $t4 2060($v0)
    li $t4 0xc38276
    sw $t4 2064($v0)
    li $t4 0xd7937c
    sw $t4 2068($v0)
    li $t4 0x90113f
    sw $t4 2072($v0)
    li $t4 0x42383e
    sw $t4 2076($v0)
    li $t4 0x010001
    sw $t4 2084($v0)
    sw $t4 3620($v0)
    sw $t4 4640($v0)
    li $t4 0xc0c0c0
    sw $t4 2560($v0)
    li $t4 0xcdd2d2
    sw $t4 2564($v0)
    li $t4 0x7b2646
    sw $t4 2568($v0)
    li $t4 0x975e75
    sw $t4 2572($v0)
    li $t4 0x8d8f88
    sw $t4 2576($v0)
    li $t4 0xa3989c
    sw $t4 2580($v0)
    li $t4 0x9c637c
    sw $t4 2584($v0)
    li $t4 0x5e4b51
    sw $t4 2588($v0)
    li $t4 0x000200
    sw $t4 2592($v0)
    li $t4 0xa5a6a7
    sw $t4 3072($v0)
    li $t4 0xddd6cf
    sw $t4 3076($v0)
    li $t4 0xa23a56
    sw $t4 3080($v0)
    li $t4 0x5f283d
    sw $t4 3084($v0)
    li $t4 0x865e6f
    sw $t4 3088($v0)
    li $t4 0x87274a
    sw $t4 3092($v0)
    li $t4 0x883848
    sw $t4 3096($v0)
    li $t4 0x3b2929
    sw $t4 3100($v0)
    li $t4 0x000100
    sw $t4 3104($v0)
    li $t4 0x616464
    sw $t4 3584($v0)
    li $t4 0x483437
    sw $t4 3588($v0)
    li $t4 0x74062a
    sw $t4 3592($v0)
    li $t4 0x73304b
    sw $t4 3596($v0)
    li $t4 0x99aca5
    sw $t4 3600($v0)
    li $t4 0x8f7d84
    sw $t4 3604($v0)
    li $t4 0x590821
    sw $t4 3608($v0)
    li $t4 0x190409
    sw $t4 3612($v0)
    li $t4 0x4d011d
    sw $t4 4104($v0)
    li $t4 0xa2325a
    sw $t4 4108($v0)
    li $t4 0xd88da3
    sw $t4 4112($v0)
    li $t4 0xcd6d8b
    sw $t4 4116($v0)
    li $t4 0x330717
    sw $t4 4120($v0)
    li $t4 0x030002
    sw $t4 4124($v0)
    li $t4 0x040304
    sw $t4 4608($v0)
    li $t4 0x020202
    sw $t4 4612($v0)
    li $t4 0x1c080f
    sw $t4 4616($v0)
    li $t4 0x731535
    sw $t4 4620($v0)
    li $t4 0x96002a
    sw $t4 4624($v0)
    li $t4 0x800021
    sw $t4 4628($v0)
    li $t4 0x1d050c
    sw $t4 4632($v0)
    li $t4 0x060603
    sw $t4 5128($v0)
    li $t4 0x20241a
    sw $t4 5132($v0)
    li $t4 0x0d130b
    sw $t4 5136($v0)
    li $t4 0x000300
    sw $t4 5140($v0)
    li $t4 0x020000
    sw $t4 5648($v0)
    li $t4 0x030001
    sw $t4 5652($v0)
    jr $ra
draw_doll_03: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 4($v0)
    sw $t4 12($v0)
    sw $t4 16($v0)
    sw $t4 20($v0)
    sw $t4 28($v0)
    sw $t4 32($v0)
    sw $t4 36($v0)
    sw $t4 520($v0)
    sw $t4 536($v0)
    sw $t4 544($v0)
    sw $t4 548($v0)
    sw $t4 1024($v0)
    sw $t4 1060($v0)
    sw $t4 1568($v0)
    sw $t4 3584($v0)
    sw $t4 4608($v0)
    sw $t4 4644($v0)
    sw $t4 5156($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5652($v0)
    sw $t4 5656($v0)
    sw $t4 5660($v0)
    sw $t4 5664($v0)
    sw $t4 5668($v0)
    li $t4 0x020101
    sw $t4 8($v0)
    sw $t4 516($v0)
    sw $t4 1572($v0)
    li $t4 0x010200
    sw $t4 24($v0)
    li $t4 0x010101
    sw $t4 512($v0)
    sw $t4 2596($v0)
    li $t4 0x1d060a
    sw $t4 524($v0)
    li $t4 0x451917
    sw $t4 528($v0)
    li $t4 0x381112
    sw $t4 532($v0)
    li $t4 0x000100
    sw $t4 540($v0)
    sw $t4 2080($v0)
    sw $t4 2592($v0)
    sw $t4 3616($v0)
    sw $t4 4128($v0)
    sw $t4 4636($v0)
    sw $t4 5124($v0)
    li $t4 0x000200
    sw $t4 1028($v0)
    li $t4 0x401318
    sw $t4 1032($v0)
    li $t4 0xdd7b4b
    sw $t4 1036($v0)
    li $t4 0xea6b4b
    sw $t4 1040($v0)
    li $t4 0xed8f4d
    sw $t4 1044($v0)
    li $t4 0x904f32
    sw $t4 1048($v0)
    li $t4 0x030001
    sw $t4 1052($v0)
    li $t4 0x010100
    sw $t4 1056($v0)
    sw $t4 5148($v0)
    li $t4 0x151816
    sw $t4 1536($v0)
    li $t4 0x140004
    sw $t4 1540($v0)
    li $t4 0xd06b47
    sw $t4 1544($v0)
    li $t4 0xe6a84c
    sw $t4 1548($v0)
    li $t4 0xb96345
    sw $t4 1552($v0)
    li $t4 0xbb6548
    sw $t4 1556($v0)
    li $t4 0xdd8c4c
    sw $t4 1560($v0)
    li $t4 0x250e0d
    sw $t4 1564($v0)
    li $t4 0xb8c0be
    sw $t4 2048($v0)
    li $t4 0xad7c8b
    sw $t4 2052($v0)
    li $t4 0xba3d38
    sw $t4 2056($v0)
    li $t4 0xba534d
    sw $t4 2060($v0)
    li $t4 0xac5c5c
    sw $t4 2064($v0)
    li $t4 0xd57a66
    sw $t4 2068($v0)
    li $t4 0x990f39
    sw $t4 2072($v0)
    li $t4 0x2a0b14
    sw $t4 2076($v0)
    li $t4 0x020001
    sw $t4 2084($v0)
    li $t4 0xd6d7d6
    sw $t4 2560($v0)
    li $t4 0xd9d9d9
    sw $t4 2564($v0)
    li $t4 0x8a0e47
    sw $t4 2568($v0)
    li $t4 0xa94257
    sw $t4 2572($v0)
    li $t4 0xc49c7f
    sw $t4 2576($v0)
    li $t4 0xd29c88
    sw $t4 2580($v0)
    li $t4 0x9f2a55
    sw $t4 2584($v0)
    li $t4 0x5f585d
    sw $t4 2588($v0)
    li $t4 0x646565
    sw $t4 3072($v0)
    li $t4 0x9fa6a4
    sw $t4 3076($v0)
    li $t4 0x913658
    sw $t4 3080($v0)
    li $t4 0x88546a
    sw $t4 3084($v0)
    li $t4 0x836f77
    sw $t4 3088($v0)
    li $t4 0x835369
    sw $t4 3092($v0)
    li $t4 0x905870
    sw $t4 3096($v0)
    li $t4 0x412a34
    sw $t4 3100($v0)
    li $t4 0x000301
    sw $t4 3104($v0)
    sw $t4 4612($v0)
    li $t4 0x010001
    sw $t4 3108($v0)
    sw $t4 4132($v0)
    li $t4 0x281a15
    sw $t4 3588($v0)
    li $t4 0xa9405b
    sw $t4 3592($v0)
    li $t4 0x562137
    sw $t4 3596($v0)
    li $t4 0x7a5b64
    sw $t4 3600($v0)
    li $t4 0x791f43
    sw $t4 3604($v0)
    li $t4 0x811336
    sw $t4 3608($v0)
    li $t4 0x492425
    sw $t4 3612($v0)
    li $t4 0x030101
    sw $t4 3620($v0)
    li $t4 0x030303
    sw $t4 4096($v0)
    li $t4 0x19090d
    sw $t4 4100($v0)
    li $t4 0x6f0429
    sw $t4 4104($v0)
    li $t4 0x835467
    sw $t4 4108($v0)
    li $t4 0xb4bab9
    sw $t4 4112($v0)
    li $t4 0xa69da1
    sw $t4 4116($v0)
    li $t4 0x55132b
    sw $t4 4120($v0)
    li $t4 0x1d050b
    sw $t4 4124($v0)
    li $t4 0x6c042d
    sw $t4 4616($v0)
    li $t4 0xac003c
    sw $t4 4620($v0)
    li $t4 0xcc003f
    sw $t4 4624($v0)
    li $t4 0xd30244
    sw $t4 4628($v0)
    li $t4 0x5a0926
    sw $t4 4632($v0)
    li $t4 0x020000
    sw $t4 4640($v0)
    li $t4 0x010000
    sw $t4 5120($v0)
    sw $t4 5152($v0)
    li $t4 0x200810
    sw $t4 5128($v0)
    li $t4 0x540c1e
    sw $t4 5132($v0)
    li $t4 0x7a0425
    sw $t4 5136($v0)
    li $t4 0x5e011e
    sw $t4 5140($v0)
    li $t4 0x17040a
    sw $t4 5144($v0)
    li $t4 0x000300
    sw $t4 5644($v0)
    sw $t4 5648($v0)
    jr $ra
draw_doll_04: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 36($v0)
    sw $t4 516($v0)
    sw $t4 544($v0)
    sw $t4 1056($v0)
    sw $t4 1536($v0)
    sw $t4 1540($v0)
    sw $t4 1568($v0)
    sw $t4 2084($v0)
    sw $t4 2596($v0)
    sw $t4 3616($v0)
    sw $t4 3620($v0)
    sw $t4 4096($v0)
    sw $t4 4100($v0)
    sw $t4 4132($v0)
    sw $t4 4616($v0)
    sw $t4 4632($v0)
    sw $t4 4640($v0)
    sw $t4 4644($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5128($v0)
    sw $t4 5148($v0)
    sw $t4 5152($v0)
    sw $t4 5156($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5644($v0)
    sw $t4 5652($v0)
    sw $t4 5656($v0)
    sw $t4 5660($v0)
    sw $t4 5664($v0)
    sw $t4 5668($v0)
    li $t4 0x010100
    sw $t4 4($v0)
    sw $t4 32($v0)
    li $t4 0x020001
    sw $t4 8($v0)
    sw $t4 4128($v0)
    li $t4 0x88412f
    sw $t4 12($v0)
    li $t4 0xd34445
    sw $t4 16($v0)
    li $t4 0xd54743
    sw $t4 20($v0)
    li $t4 0x7e2e2c
    sw $t4 24($v0)
    li $t4 0x040002
    sw $t4 28($v0)
    li $t4 0x030101
    sw $t4 512($v0)
    li $t4 0x4b171b
    sw $t4 520($v0)
    li $t4 0xf5aa52
    sw $t4 524($v0)
    li $t4 0xdc7e48
    sw $t4 528($v0)
    li $t4 0xd17746
    sw $t4 532($v0)
    li $t4 0xee9a4f
    sw $t4 536($v0)
    li $t4 0x52291d
    sw $t4 540($v0)
    li $t4 0x040201
    sw $t4 548($v0)
    sw $t4 1060($v0)
    li $t4 0x050302
    sw $t4 1024($v0)
    li $t4 0x030303
    sw $t4 1028($v0)
    li $t4 0x4f211b
    sw $t4 1032($v0)
    li $t4 0xe18250
    sw $t4 1036($v0)
    li $t4 0x9f5143
    sw $t4 1040($v0)
    li $t4 0xae4d47
    sw $t4 1044($v0)
    li $t4 0xbf5448
    sw $t4 1048($v0)
    li $t4 0x51261b
    sw $t4 1052($v0)
    li $t4 0x1a0004
    sw $t4 1544($v0)
    li $t4 0xb53648
    sw $t4 1548($v0)
    li $t4 0xb86566
    sw $t4 1552($v0)
    li $t4 0xe6a689
    sw $t4 1556($v0)
    li $t4 0x9d2941
    sw $t4 1560($v0)
    li $t4 0x050001
    sw $t4 1564($v0)
    li $t4 0x010000
    sw $t4 1572($v0)
    sw $t4 3108($v0)
    sw $t4 3612($v0)
    sw $t4 4636($v0)
    sw $t4 5132($v0)
    li $t4 0x1d1b1c
    sw $t4 2048($v0)
    li $t4 0x3a413e
    sw $t4 2052($v0)
    li $t4 0x5b3142
    sw $t4 2056($v0)
    li $t4 0x923559
    sw $t4 2060($v0)
    li $t4 0x9f9b93
    sw $t4 2064($v0)
    li $t4 0x8f7e7c
    sw $t4 2068($v0)
    li $t4 0xa47e8d
    sw $t4 2072($v0)
    li $t4 0x604f58
    sw $t4 2076($v0)
    li $t4 0x080b09
    sw $t4 2080($v0)
    li $t4 0x89898a
    sw $t4 2560($v0)
    li $t4 0xdee1dd
    sw $t4 2564($v0)
    li $t4 0xae6877
    sw $t4 2568($v0)
    li $t4 0x6f1534
    sw $t4 2572($v0)
    li $t4 0x9f9ea1
    sw $t4 2576($v0)
    li $t4 0x9b4064
    sw $t4 2580($v0)
    li $t4 0x7f3a55
    sw $t4 2584($v0)
    li $t4 0x702c3b
    sw $t4 2588($v0)
    li $t4 0x0e0f0c
    sw $t4 2592($v0)
    li $t4 0x888989
    sw $t4 3072($v0)
    li $t4 0xceccc9
    sw $t4 3076($v0)
    li $t4 0x882842
    sw $t4 3080($v0)
    li $t4 0x69082e
    sw $t4 3084($v0)
    li $t4 0x8b747c
    sw $t4 3088($v0)
    li $t4 0x9c8289
    sw $t4 3092($v0)
    li $t4 0x570125
    sw $t4 3096($v0)
    li $t4 0x67232d
    sw $t4 3100($v0)
    li $t4 0x070503
    sw $t4 3104($v0)
    li $t4 0x2c2b2b
    sw $t4 3584($v0)
    li $t4 0x181818
    sw $t4 3588($v0)
    li $t4 0x100009
    sw $t4 3592($v0)
    li $t4 0x7d0027
    sw $t4 3596($v0)
    li $t4 0xccb6bf
    sw $t4 3600($v0)
    li $t4 0xd3d1d2
    sw $t4 3604($v0)
    li $t4 0x570620
    sw $t4 3608($v0)
    li $t4 0x040706
    sw $t4 4104($v0)
    li $t4 0x690726
    sw $t4 4108($v0)
    li $t4 0xa84464
    sw $t4 4112($v0)
    li $t4 0xa24060
    sw $t4 4116($v0)
    li $t4 0x460112
    sw $t4 4120($v0)
    li $t4 0x000300
    sw $t4 4124($v0)
    li $t4 0x020202
    sw $t4 4608($v0)
    li $t4 0x030202
    sw $t4 4612($v0)
    li $t4 0x1a1713
    sw $t4 4620($v0)
    li $t4 0x2c1212
    sw $t4 4624($v0)
    li $t4 0x0c0000
    sw $t4 4628($v0)
    li $t4 0x000200
    sw $t4 5136($v0)
    li $t4 0x010201
    sw $t4 5140($v0)
    li $t4 0x020000
    sw $t4 5144($v0)
    li $t4 0x000001
    sw $t4 5648($v0)
    jr $ra
draw_doll_05: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 8($v0)
    sw $t4 1024($v0)
    sw $t4 1028($v0)
    sw $t4 1056($v0)
    sw $t4 2084($v0)
    sw $t4 2596($v0)
    sw $t4 3108($v0)
    sw $t4 3584($v0)
    sw $t4 3588($v0)
    sw $t4 4608($v0)
    sw $t4 4612($v0)
    sw $t4 4636($v0)
    sw $t4 4640($v0)
    sw $t4 4644($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5128($v0)
    sw $t4 5136($v0)
    sw $t4 5140($v0)
    sw $t4 5148($v0)
    sw $t4 5152($v0)
    sw $t4 5156($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5644($v0)
    sw $t4 5656($v0)
    sw $t4 5660($v0)
    sw $t4 5664($v0)
    sw $t4 5668($v0)
    li $t4 0x020201
    sw $t4 4($v0)
    li $t4 0x58251f
    sw $t4 12($v0)
    li $t4 0xcf5045
    sw $t4 16($v0)
    li $t4 0xd64543
    sw $t4 20($v0)
    li $t4 0xa84439
    sw $t4 24($v0)
    li $t4 0x19080a
    sw $t4 28($v0)
    li $t4 0x010100
    sw $t4 32($v0)
    li $t4 0x010000
    sw $t4 36($v0)
    sw $t4 1572($v0)
    sw $t4 3620($v0)
    sw $t4 4128($v0)
    sw $t4 4132($v0)
    li $t4 0x020101
    sw $t4 512($v0)
    sw $t4 1060($v0)
    sw $t4 4096($v0)
    li $t4 0x010201
    sw $t4 516($v0)
    li $t4 0x160309
    sw $t4 520($v0)
    li $t4 0xe19b4c
    sw $t4 524($v0)
    li $t4 0xe5924a
    sw $t4 528($v0)
    li $t4 0xce7145
    sw $t4 532($v0)
    li $t4 0xe58c4c
    sw $t4 536($v0)
    li $t4 0x905b31
    sw $t4 540($v0)
    li $t4 0x010101
    sw $t4 544($v0)
    sw $t4 5648($v0)
    li $t4 0x030301
    sw $t4 548($v0)
    li $t4 0x2c0a12
    sw $t4 1032($v0)
    li $t4 0xe2824e
    sw $t4 1036($v0)
    li $t4 0xac5646
    sw $t4 1040($v0)
    li $t4 0xaa5745
    sw $t4 1044($v0)
    li $t4 0xbf5250
    sw $t4 1048($v0)
    li $t4 0x82222c
    sw $t4 1052($v0)
    li $t4 0x0f0d0e
    sw $t4 1536($v0)
    li $t4 0x050505
    sw $t4 1540($v0)
    li $t4 0x120001
    sw $t4 1544($v0)
    li $t4 0xab2240
    sw $t4 1548($v0)
    li $t4 0xb3555a
    sw $t4 1552($v0)
    li $t4 0xdda288
    sw $t4 1556($v0)
    li $t4 0xc25159
    sw $t4 1560($v0)
    li $t4 0x681036
    sw $t4 1564($v0)
    li $t4 0x161b18
    sw $t4 1568($v0)
    li $t4 0x535252
    sw $t4 2048($v0)
    li $t4 0xbfc1c1
    sw $t4 2052($v0)
    li $t4 0x796d74
    sw $t4 2056($v0)
    li $t4 0x7d143d
    sw $t4 2060($v0)
    li $t4 0xac999b
    sw $t4 2064($v0)
    li $t4 0x888078
    sw $t4 2068($v0)
    li $t4 0xa6818f
    sw $t4 2072($v0)
    li $t4 0x8c546c
    sw $t4 2076($v0)
    li $t4 0x252d2b
    sw $t4 2080($v0)
    li $t4 0x2b2b2b
    sw $t4 2560($v0)
    li $t4 0xdde0df
    sw $t4 2564($v0)
    li $t4 0xd0abae
    sw $t4 2568($v0)
    li $t4 0x7f1034
    sw $t4 2572($v0)
    li $t4 0x747175
    sw $t4 2576($v0)
    li $t4 0x933a5f
    sw $t4 2580($v0)
    li $t4 0x792e4b
    sw $t4 2584($v0)
    li $t4 0x902246
    sw $t4 2588($v0)
    li $t4 0x2c1d1d
    sw $t4 2592($v0)
    li $t4 0x343334
    sw $t4 3072($v0)
    li $t4 0x7c817f
    sw $t4 3076($v0)
    li $t4 0x6e2b37
    sw $t4 3080($v0)
    li $t4 0x760931
    sw $t4 3084($v0)
    li $t4 0x715460
    sw $t4 3088($v0)
    li $t4 0xaa969b
    sw $t4 3092($v0)
    li $t4 0x6c213f
    sw $t4 3096($v0)
    li $t4 0x650824
    sw $t4 3100($v0)
    li $t4 0x150b09
    sw $t4 3104($v0)
    li $t4 0x0e0008
    sw $t4 3592($v0)
    li $t4 0x80002a
    sw $t4 3596($v0)
    li $t4 0xaa808f
    sw $t4 3600($v0)
    li $t4 0xf2fffe
    sw $t4 3604($v0)
    li $t4 0x9f4060
    sw $t4 3608($v0)
    li $t4 0x0a0001
    sw $t4 3612($v0)
    li $t4 0x000101
    sw $t4 3616($v0)
    sw $t4 5652($v0)
    li $t4 0x040303
    sw $t4 4100($v0)
    li $t4 0x030604
    sw $t4 4104($v0)
    li $t4 0x4b051d
    sw $t4 4108($v0)
    li $t4 0x902348
    sw $t4 4112($v0)
    li $t4 0xb44c6d
    sw $t4 4116($v0)
    li $t4 0x780428
    sw $t4 4120($v0)
    li $t4 0x0b0104
    sw $t4 4124($v0)
    li $t4 0x010001
    sw $t4 4616($v0)
    li $t4 0x000100
    sw $t4 4620($v0)
    sw $t4 4632($v0)
    li $t4 0x201916
    sw $t4 4624($v0)
    li $t4 0x3b201f
    sw $t4 4628($v0)
    li $t4 0x020000
    sw $t4 5132($v0)
    li $t4 0x030001
    sw $t4 5144($v0)
    jr $ra
draw_doll_06: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 512($v0)
    sw $t4 1028($v0)
    sw $t4 1060($v0)
    sw $t4 1572($v0)
    sw $t4 2084($v0)
    sw $t4 2596($v0)
    sw $t4 3072($v0)
    sw $t4 3108($v0)
    sw $t4 4100($v0)
    sw $t4 4608($v0)
    sw $t4 4612($v0)
    sw $t4 4636($v0)
    sw $t4 4644($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5128($v0)
    sw $t4 5132($v0)
    sw $t4 5136($v0)
    sw $t4 5152($v0)
    sw $t4 5156($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5644($v0)
    sw $t4 5652($v0)
    sw $t4 5656($v0)
    sw $t4 5660($v0)
    sw $t4 5664($v0)
    sw $t4 5668($v0)
    li $t4 0x010001
    sw $t4 4($v0)
    sw $t4 36($v0)
    sw $t4 3620($v0)
    sw $t4 4640($v0)
    sw $t4 5648($v0)
    li $t4 0x020101
    sw $t4 8($v0)
    li $t4 0x0f0006
    sw $t4 12($v0)
    li $t4 0x81302c
    sw $t4 16($v0)
    li $t4 0xa43234
    sw $t4 20($v0)
    li $t4 0x862a2c
    sw $t4 24($v0)
    li $t4 0x150009
    sw $t4 28($v0)
    li $t4 0x000100
    sw $t4 32($v0)
    li $t4 0x040402
    sw $t4 516($v0)
    li $t4 0x000201
    sw $t4 520($v0)
    li $t4 0x8c5131
    sw $t4 524($v0)
    li $t4 0xf59951
    sw $t4 528($v0)
    li $t4 0xe2744a
    sw $t4 532($v0)
    li $t4 0xf29b51
    sw $t4 536($v0)
    li $t4 0xaf753b
    sw $t4 540($v0)
    li $t4 0x040302
    sw $t4 544($v0)
    li $t4 0x020201
    sw $t4 548($v0)
    li $t4 0x040303
    sw $t4 1024($v0)
    li $t4 0x1c0005
    sw $t4 1032($v0)
    li $t4 0xeb9250
    sw $t4 1036($v0)
    li $t4 0xd5964a
    sw $t4 1040($v0)
    li $t4 0xb6763e
    sw $t4 1044($v0)
    li $t4 0xc47749
    sw $t4 1048($v0)
    li $t4 0xc95c46
    sw $t4 1052($v0)
    li $t4 0x310c0d
    sw $t4 1056($v0)
    li $t4 0x201d1e
    sw $t4 1536($v0)
    li $t4 0x9fa8a5
    sw $t4 1540($v0)
    li $t4 0x7d3550
    sw $t4 1544($v0)
    li $t4 0xbb2d39
    sw $t4 1548($v0)
    li $t4 0xb74c54
    sw $t4 1552($v0)
    li $t4 0xc97174
    sw $t4 1556($v0)
    li $t4 0xd57769
    sw $t4 1560($v0)
    li $t4 0x8d0239
    sw $t4 1564($v0)
    li $t4 0x39262d
    sw $t4 1568($v0)
    li $t4 0x191919
    sw $t4 2048($v0)
    li $t4 0xd8d9d8
    sw $t4 2052($v0)
    li $t4 0xe2eae9
    sw $t4 2056($v0)
    li $t4 0x93365d
    sw $t4 2060($v0)
    li $t4 0xa14d64
    sw $t4 2064($v0)
    li $t4 0xa89f87
    sw $t4 2068($v0)
    li $t4 0xad8282
    sw $t4 2072($v0)
    li $t4 0x984969
    sw $t4 2076($v0)
    li $t4 0x49504e
    sw $t4 2080($v0)
    li $t4 0x0b0b0b
    sw $t4 2560($v0)
    li $t4 0x919090
    sw $t4 2564($v0)
    li $t4 0xc3b2b7
    sw $t4 2568($v0)
    li $t4 0x973d5a
    sw $t4 2572($v0)
    li $t4 0x763f54
    sw $t4 2576($v0)
    li $t4 0x846073
    sw $t4 2580($v0)
    li $t4 0x7d4862
    sw $t4 2584($v0)
    li $t4 0x8d3959
    sw $t4 2588($v0)
    li $t4 0x3e1723
    sw $t4 2592($v0)
    li $t4 0x040000
    sw $t4 3076($v0)
    li $t4 0x930c3a
    sw $t4 3080($v0)
    li $t4 0x922f47
    sw $t4 3084($v0)
    li $t4 0x5a2e40
    sw $t4 3088($v0)
    li $t4 0x8c6672
    sw $t4 3092($v0)
    li $t4 0x702742
    sw $t4 3096($v0)
    li $t4 0x7a002a
    sw $t4 3100($v0)
    li $t4 0x41121a
    sw $t4 3104($v0)
    li $t4 0x010000
    sw $t4 3584($v0)
    sw $t4 4096($v0)
    sw $t4 4616($v0)
    sw $t4 5148($v0)
    li $t4 0x0b0205
    sw $t4 3588($v0)
    li $t4 0x310619
    sw $t4 3592($v0)
    li $t4 0x730024
    sw $t4 3596($v0)
    li $t4 0x924b66
    sw $t4 3600($v0)
    li $t4 0xe0fff9
    sw $t4 3604($v0)
    li $t4 0xb18a97
    sw $t4 3608($v0)
    li $t4 0x2b0109
    sw $t4 3612($v0)
    li $t4 0x050203
    sw $t4 3616($v0)
    li $t4 0x000603
    sw $t4 4104($v0)
    li $t4 0x70052a
    sw $t4 4108($v0)
    li $t4 0xa71948
    sw $t4 4112($v0)
    li $t4 0xc7859d
    sw $t4 4116($v0)
    li $t4 0xc62e5e
    sw $t4 4120($v0)
    li $t4 0x33010d
    sw $t4 4124($v0)
    li $t4 0x000200
    sw $t4 4128($v0)
    li $t4 0x020001
    sw $t4 4132($v0)
    li $t4 0x010303
    sw $t4 4620($v0)
    li $t4 0x150107
    sw $t4 4624($v0)
    li $t4 0x5f2430
    sw $t4 4628($v0)
    li $t4 0x291014
    sw $t4 4632($v0)
    li $t4 0x050902
    sw $t4 5140($v0)
    li $t4 0x060501
    sw $t4 5144($v0)
    jr $ra
draw_doll_07: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 4($v0)
    sw $t4 12($v0)
    sw $t4 28($v0)
    sw $t4 36($v0)
    sw $t4 512($v0)
    sw $t4 544($v0)
    sw $t4 1028($v0)
    sw $t4 1032($v0)
    sw $t4 1060($v0)
    sw $t4 1572($v0)
    sw $t4 2048($v0)
    sw $t4 2560($v0)
    sw $t4 3072($v0)
    sw $t4 3584($v0)
    sw $t4 4096($v0)
    sw $t4 4128($v0)
    sw $t4 4608($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5128($v0)
    sw $t4 5132($v0)
    sw $t4 5136($v0)
    sw $t4 5152($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5656($v0)
    sw $t4 5660($v0)
    sw $t4 5664($v0)
    sw $t4 5668($v0)
    li $t4 0x010000
    sw $t4 8($v0)
    sw $t4 1024($v0)
    sw $t4 4612($v0)
    li $t4 0x040002
    sw $t4 16($v0)
    li $t4 0x260d0d
    sw $t4 20($v0)
    li $t4 0x220a0b
    sw $t4 24($v0)
    li $t4 0x000100
    sw $t4 32($v0)
    sw $t4 4100($v0)
    sw $t4 5140($v0)
    sw $t4 5156($v0)
    li $t4 0x030202
    sw $t4 516($v0)
    li $t4 0x010201
    sw $t4 520($v0)
    li $t4 0x1a020a
    sw $t4 524($v0)
    li $t4 0xb45d3d
    sw $t4 528($v0)
    li $t4 0xdd5a47
    sw $t4 532($v0)
    li $t4 0xdb6b45
    sw $t4 536($v0)
    li $t4 0x7e3e2d
    sw $t4 540($v0)
    li $t4 0x010101
    sw $t4 548($v0)
    sw $t4 4640($v0)
    li $t4 0xb15640
    sw $t4 1036($v0)
    li $t4 0xf5b750
    sw $t4 1040($v0)
    li $t4 0xbc6740
    sw $t4 1044($v0)
    li $t4 0xc5744a
    sw $t4 1048($v0)
    li $t4 0xf0a551
    sw $t4 1052($v0)
    li $t4 0x4b2d1a
    sw $t4 1056($v0)
    li $t4 0x020001
    sw $t4 1536($v0)
    sw $t4 5648($v0)
    sw $t4 5652($v0)
    li $t4 0x2b302e
    sw $t4 1540($v0)
    li $t4 0x5b1e2f
    sw $t4 1544($v0)
    li $t4 0xce503b
    sw $t4 1548($v0)
    li $t4 0xce7c54
    sw $t4 1552($v0)
    li $t4 0x973b4f
    sw $t4 1556($v0)
    li $t4 0xd57b65
    sw $t4 1560($v0)
    li $t4 0xb53744
    sw $t4 1564($v0)
    li $t4 0x6c2423
    sw $t4 1568($v0)
    li $t4 0x6f7271
    sw $t4 2052($v0)
    li $t4 0xdac4ce
    sw $t4 2056($v0)
    li $t4 0x99284f
    sw $t4 2060($v0)
    li $t4 0xa02741
    sw $t4 2064($v0)
    li $t4 0xc09076
    sw $t4 2068($v0)
    li $t4 0xdfa987
    sw $t4 2072($v0)
    li $t4 0x9c1945
    sw $t4 2076($v0)
    li $t4 0x644e5b
    sw $t4 2080($v0)
    li $t4 0x030605
    sw $t4 2084($v0)
    li $t4 0x545454
    sw $t4 2564($v0)
    li $t4 0xedfffc
    sw $t4 2568($v0)
    li $t4 0x9e6d81
    sw $t4 2572($v0)
    li $t4 0x952550
    sw $t4 2576($v0)
    li $t4 0x827e80
    sw $t4 2580($v0)
    li $t4 0x88757d
    sw $t4 2584($v0)
    li $t4 0xa37085
    sw $t4 2588($v0)
    li $t4 0x593c49
    sw $t4 2592($v0)
    li $t4 0x040806
    sw $t4 2596($v0)
    li $t4 0x3a1423
    sw $t4 3076($v0)
    li $t4 0xb64d78
    sw $t4 3080($v0)
    li $t4 0xa94e5a
    sw $t4 3084($v0)
    li $t4 0x79464f
    sw $t4 3088($v0)
    li $t4 0x593143
    sw $t4 3092($v0)
    li $t4 0x721639
    sw $t4 3096($v0)
    li $t4 0x7b113a
    sw $t4 3100($v0)
    li $t4 0x6f132e
    sw $t4 3104($v0)
    li $t4 0x000300
    sw $t4 3108($v0)
    li $t4 0x20000b
    sw $t4 3588($v0)
    li $t4 0x430013
    sw $t4 3592($v0)
    li $t4 0x660026
    sw $t4 3596($v0)
    li $t4 0x701639
    sw $t4 3600($v0)
    li $t4 0xa4a7a6
    sw $t4 3604($v0)
    li $t4 0xb0acad
    sw $t4 3608($v0)
    li $t4 0x621937
    sw $t4 3612($v0)
    li $t4 0x380914
    sw $t4 3616($v0)
    li $t4 0x000200
    sw $t4 3620($v0)
    li $t4 0x000700
    sw $t4 4104($v0)
    li $t4 0x630729
    sw $t4 4108($v0)
    li $t4 0xbc0c42
    sw $t4 4112($v0)
    li $t4 0xc09ca8
    sw $t4 4116($v0)
    li $t4 0xdbb1bf
    sw $t4 4120($v0)
    li $t4 0x651d30
    sw $t4 4124($v0)
    li $t4 0x020101
    sw $t4 4132($v0)
    sw $t4 4616($v0)
    li $t4 0x17070c
    sw $t4 4620($v0)
    li $t4 0x2e0512
    sw $t4 4624($v0)
    li $t4 0x21000c
    sw $t4 4628($v0)
    li $t4 0x6d4855
    sw $t4 4632($v0)
    li $t4 0x351d24
    sw $t4 4636($v0)
    li $t4 0x020102
    sw $t4 4644($v0)
    li $t4 0x2c2920
    sw $t4 5144($v0)
    li $t4 0x1e1913
    sw $t4 5148($v0)
    li $t4 0x010001
    sw $t4 5644($v0)
    jr $ra
draw_doll_08: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 4($v0)
    sw $t4 8($v0)
    sw $t4 16($v0)
    sw $t4 20($v0)
    sw $t4 24($v0)
    sw $t4 28($v0)
    sw $t4 36($v0)
    sw $t4 512($v0)
    sw $t4 516($v0)
    sw $t4 524($v0)
    sw $t4 544($v0)
    sw $t4 548($v0)
    sw $t4 1024($v0)
    sw $t4 1032($v0)
    sw $t4 2048($v0)
    sw $t4 3584($v0)
    sw $t4 4096($v0)
    sw $t4 4100($v0)
    sw $t4 4608($v0)
    sw $t4 4616($v0)
    sw $t4 4640($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5132($v0)
    sw $t4 5140($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5644($v0)
    sw $t4 5668($v0)
    li $t4 0x020100
    sw $t4 12($v0)
    li $t4 0x000200
    sw $t4 32($v0)
    sw $t4 3072($v0)
    sw $t4 3620($v0)
    li $t4 0x020101
    sw $t4 520($v0)
    sw $t4 4644($v0)
    sw $t4 5664($v0)
    li $t4 0x26050e
    sw $t4 528($v0)
    li $t4 0x6f2127
    sw $t4 532($v0)
    li $t4 0x843a2a
    sw $t4 536($v0)
    li $t4 0x571e1e
    sw $t4 540($v0)
    li $t4 0x010000
    sw $t4 1028($v0)
    sw $t4 4612($v0)
    sw $t4 5128($v0)
    sw $t4 5652($v0)
    li $t4 0x5d1d21
    sw $t4 1036($v0)
    li $t4 0xe1814a
    sw $t4 1040($v0)
    li $t4 0xfdbf54
    sw $t4 1044($v0)
    li $t4 0xf19750
    sw $t4 1048($v0)
    li $t4 0xf6a751
    sw $t4 1052($v0)
    li $t4 0x936134
    sw $t4 1056($v0)
    li $t4 0x080304
    sw $t4 1060($v0)
    li $t4 0x020001
    sw $t4 1536($v0)
    li $t4 0x030404
    sw $t4 1540($v0)
    li $t4 0x38101e
    sw $t4 1544($v0)
    li $t4 0xb52039
    sw $t4 1548($v0)
    li $t4 0xf3b550
    sw $t4 1552($v0)
    li $t4 0xc0894a
    sw $t4 1556($v0)
    li $t4 0xa45044
    sw $t4 1560($v0)
    li $t4 0xc2554b
    sw $t4 1564($v0)
    li $t4 0xc35840
    sw $t4 1568($v0)
    li $t4 0x190209
    sw $t4 1572($v0)
    li $t4 0x0e0e0e
    sw $t4 2052($v0)
    li $t4 0xbdb1b9
    sw $t4 2056($v0)
    li $t4 0xaa4f6c
    sw $t4 2060($v0)
    li $t4 0xae333a
    sw $t4 2064($v0)
    li $t4 0xb86165
    sw $t4 2068($v0)
    li $t4 0xe5a58a
    sw $t4 2072($v0)
    li $t4 0xd26960
    sw $t4 2076($v0)
    li $t4 0x771039
    sw $t4 2080($v0)
    li $t4 0x0a0c0c
    sw $t4 2084($v0)
    li $t4 0x010101
    sw $t4 2560($v0)
    sw $t4 5156($v0)
    li $t4 0x020504
    sw $t4 2564($v0)
    li $t4 0xb6c3bd
    sw $t4 2568($v0)
    li $t4 0xdaeae3
    sw $t4 2572($v0)
    li $t4 0x870e47
    sw $t4 2576($v0)
    li $t4 0x984b60
    sw $t4 2580($v0)
    li $t4 0xa49f7f
    sw $t4 2584($v0)
    li $t4 0xb56a77
    sw $t4 2588($v0)
    li $t4 0x87586c
    sw $t4 2592($v0)
    li $t4 0x1b2622
    sw $t4 2596($v0)
    li $t4 0x23020c
    sw $t4 3076($v0)
    li $t4 0xba6e8d
    sw $t4 3080($v0)
    li $t4 0xaf6d87
    sw $t4 3084($v0)
    li $t4 0x9e3d4b
    sw $t4 3088($v0)
    li $t4 0x908889
    sw $t4 3092($v0)
    li $t4 0x90687f
    sw $t4 3096($v0)
    li $t4 0x874a64
    sw $t4 3100($v0)
    li $t4 0x6a2941
    sw $t4 3104($v0)
    li $t4 0x0b100e
    sw $t4 3108($v0)
    li $t4 0x170009
    sw $t4 3588($v0)
    li $t4 0x760028
    sw $t4 3592($v0)
    li $t4 0x8f0033
    sw $t4 3596($v0)
    li $t4 0x7c1736
    sw $t4 3600($v0)
    li $t4 0x53303d
    sw $t4 3604($v0)
    li $t4 0x8f5b6d
    sw $t4 3608($v0)
    li $t4 0x822247
    sw $t4 3612($v0)
    li $t4 0x6b1229
    sw $t4 3616($v0)
    li $t4 0x100308
    sw $t4 4104($v0)
    li $t4 0x400b20
    sw $t4 4108($v0)
    li $t4 0x8e0030
    sw $t4 4112($v0)
    li $t4 0xaa3e63
    sw $t4 4116($v0)
    li $t4 0xa5818b
    sw $t4 4120($v0)
    li $t4 0xb26d84
    sw $t4 4124($v0)
    li $t4 0x3f2831
    sw $t4 4128($v0)
    li $t4 0x000100
    sw $t4 4132($v0)
    sw $t4 5136($v0)
    li $t4 0x020303
    sw $t4 4620($v0)
    li $t4 0x330a16
    sw $t4 4624($v0)
    li $t4 0x3d2c31
    sw $t4 4628($v0)
    li $t4 0x826a72
    sw $t4 4632($v0)
    li $t4 0x55192e
    sw $t4 4636($v0)
    li $t4 0x51514d
    sw $t4 5144($v0)
    li $t4 0x4c514a
    sw $t4 5148($v0)
    li $t4 0x010100
    sw $t4 5152($v0)
    li $t4 0x030001
    sw $t4 5648($v0)
    li $t4 0x060000
    sw $t4 5656($v0)
    li $t4 0x140803
    sw $t4 5660($v0)
    jr $ra
draw_doll_09: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 4($v0)
    sw $t4 8($v0)
    sw $t4 12($v0)
    sw $t4 36($v0)
    sw $t4 512($v0)
    sw $t4 516($v0)
    sw $t4 520($v0)
    sw $t4 524($v0)
    sw $t4 528($v0)
    sw $t4 532($v0)
    sw $t4 536($v0)
    sw $t4 540($v0)
    sw $t4 544($v0)
    sw $t4 1024($v0)
    sw $t4 1028($v0)
    sw $t4 1060($v0)
    sw $t4 1536($v0)
    sw $t4 1540($v0)
    sw $t4 2048($v0)
    sw $t4 2564($v0)
    sw $t4 3076($v0)
    sw $t4 4096($v0)
    sw $t4 4608($v0)
    sw $t4 4612($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5156($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5644($v0)
    sw $t4 5668($v0)
    li $t4 0x010101
    sw $t4 16($v0)
    li $t4 0x030201
    sw $t4 20($v0)
    sw $t4 28($v0)
    li $t4 0x020101
    sw $t4 24($v0)
    sw $t4 32($v0)
    sw $t4 548($v0)
    sw $t4 1032($v0)
    li $t4 0x010100
    sw $t4 1036($v0)
    sw $t4 1544($v0)
    li $t4 0x1b060a
    sw $t4 1040($v0)
    li $t4 0x8a3330
    sw $t4 1044($v0)
    li $t4 0xa64735
    sw $t4 1048($v0)
    li $t4 0x9a4c32
    sw $t4 1052($v0)
    li $t4 0x21040d
    sw $t4 1056($v0)
    li $t4 0x020003
    sw $t4 1548($v0)
    li $t4 0xa34c38
    sw $t4 1552($v0)
    li $t4 0xffd856
    sw $t4 1556($v0)
    li $t4 0xe5934d
    sw $t4 1560($v0)
    li $t4 0xeea34f
    sw $t4 1564($v0)
    li $t4 0xd38a48
    sw $t4 1568($v0)
    li $t4 0x351e15
    sw $t4 1572($v0)
    li $t4 0x030101
    sw $t4 2052($v0)
    li $t4 0x020403
    sw $t4 2056($v0)
    li $t4 0x3f0211
    sw $t4 2060($v0)
    li $t4 0xea8b4d
    sw $t4 2064($v0)
    li $t4 0xd29952
    sw $t4 2068($v0)
    li $t4 0x974947
    sw $t4 2072($v0)
    li $t4 0xc05751
    sw $t4 2076($v0)
    li $t4 0xbd4243
    sw $t4 2080($v0)
    li $t4 0x711426
    sw $t4 2084($v0)
    li $t4 0x020202
    sw $t4 2560($v0)
    sw $t4 3584($v0)
    li $t4 0x878d8b
    sw $t4 2568($v0)
    li $t4 0xaf677e
    sw $t4 2572($v0)
    li $t4 0xa92337
    sw $t4 2576($v0)
    li $t4 0xb34a51
    sw $t4 2580($v0)
    li $t4 0xdb9985
    sw $t4 2584($v0)
    li $t4 0xe79978
    sw $t4 2588($v0)
    li $t4 0x910837
    sw $t4 2592($v0)
    li $t4 0x482c3a
    sw $t4 2596($v0)
    li $t4 0x030303
    sw $t4 3072($v0)
    li $t4 0x7f8683
    sw $t4 3080($v0)
    li $t4 0xeafff9
    sw $t4 3084($v0)
    li $t4 0x8e305d
    sw $t4 3088($v0)
    li $t4 0x952a52
    sw $t4 3092($v0)
    li $t4 0x8c8c79
    sw $t4 3096($v0)
    li $t4 0xad8c8a
    sw $t4 3100($v0)
    li $t4 0x9b4d6d
    sw $t4 3104($v0)
    li $t4 0x5c5c5d
    sw $t4 3108($v0)
    li $t4 0x040002
    sw $t4 3588($v0)
    li $t4 0x8f526b
    sw $t4 3592($v0)
    li $t4 0xcea8b7
    sw $t4 3596($v0)
    li $t4 0xa65c65
    sw $t4 3600($v0)
    li $t4 0x864a5b
    sw $t4 3604($v0)
    li $t4 0x75425a
    sw $t4 3608($v0)
    li $t4 0x7c3c59
    sw $t4 3612($v0)
    li $t4 0x853754
    sw $t4 3616($v0)
    li $t4 0x53192c
    sw $t4 3620($v0)
    li $t4 0x110007
    sw $t4 4100($v0)
    li $t4 0x2b000c
    sw $t4 4104($v0)
    li $t4 0x5b001e
    sw $t4 4108($v0)
    li $t4 0x881d3a
    sw $t4 4112($v0)
    li $t4 0x582d3e
    sw $t4 4116($v0)
    li $t4 0x827177
    sw $t4 4120($v0)
    li $t4 0x82445a
    sw $t4 4124($v0)
    li $t4 0x7d0734
    sw $t4 4128($v0)
    li $t4 0x51131f
    sw $t4 4132($v0)
    li $t4 0x000200
    sw $t4 4616($v0)
    sw $t4 5652($v0)
    li $t4 0x010605
    sw $t4 4620($v0)
    li $t4 0x760230
    sw $t4 4624($v0)
    li $t4 0xb60033
    sw $t4 4628($v0)
    li $t4 0xba8b9a
    sw $t4 4632($v0)
    li $t4 0xedfaf6
    sw $t4 4636($v0)
    li $t4 0x706469
    sw $t4 4640($v0)
    li $t4 0x010000
    sw $t4 4644($v0)
    sw $t4 5128($v0)
    sw $t4 5664($v0)
    li $t4 0x000302
    sw $t4 5132($v0)
    li $t4 0x4e0a21
    sw $t4 5136($v0)
    li $t4 0x790729
    sw $t4 5140($v0)
    li $t4 0x751d39
    sw $t4 5144($v0)
    li $t4 0x865c69
    sw $t4 5148($v0)
    li $t4 0x110c0d
    sw $t4 5152($v0)
    li $t4 0x000100
    sw $t4 5648($v0)
    li $t4 0x0e110a
    sw $t4 5656($v0)
    li $t4 0x1e110a
    sw $t4 5660($v0)
    jr $ra
draw_doll_10: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 4($v0)
    sw $t4 8($v0)
    sw $t4 12($v0)
    sw $t4 16($v0)
    sw $t4 20($v0)
    sw $t4 24($v0)
    sw $t4 28($v0)
    sw $t4 32($v0)
    sw $t4 36($v0)
    sw $t4 512($v0)
    sw $t4 516($v0)
    sw $t4 520($v0)
    sw $t4 524($v0)
    sw $t4 528($v0)
    sw $t4 548($v0)
    sw $t4 1024($v0)
    sw $t4 1028($v0)
    sw $t4 1032($v0)
    sw $t4 1036($v0)
    sw $t4 1044($v0)
    sw $t4 1048($v0)
    sw $t4 1052($v0)
    sw $t4 1056($v0)
    sw $t4 1536($v0)
    sw $t4 1540($v0)
    sw $t4 1544($v0)
    sw $t4 1552($v0)
    sw $t4 1572($v0)
    sw $t4 2048($v0)
    sw $t4 2052($v0)
    sw $t4 2056($v0)
    sw $t4 2060($v0)
    sw $t4 2560($v0)
    sw $t4 2564($v0)
    sw $t4 3076($v0)
    sw $t4 3588($v0)
    sw $t4 4100($v0)
    sw $t4 4608($v0)
    sw $t4 4616($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5668($v0)
    li $t4 0x030101
    sw $t4 532($v0)
    sw $t4 536($v0)
    sw $t4 540($v0)
    li $t4 0x020101
    sw $t4 544($v0)
    li $t4 0x010100
    sw $t4 1040($v0)
    sw $t4 1060($v0)
    li $t4 0x020202
    sw $t4 1548($v0)
    sw $t4 3072($v0)
    sw $t4 3584($v0)
    li $t4 0x421817
    sw $t4 1556($v0)
    li $t4 0x872c2c
    sw $t4 1560($v0)
    li $t4 0x8b322c
    sw $t4 1564($v0)
    li $t4 0x2c0511
    sw $t4 1568($v0)
    li $t4 0x371615
    sw $t4 2064($v0)
    li $t4 0xeb964e
    sw $t4 2068($v0)
    li $t4 0xe85d4a
    sw $t4 2072($v0)
    li $t4 0xe4684a
    sw $t4 2076($v0)
    li $t4 0xdd884a
    sw $t4 2080($v0)
    li $t4 0x2a1710
    sw $t4 2084($v0)
    li $t4 0x0e0d0b
    sw $t4 2568($v0)
    li $t4 0x0d0c0e
    sw $t4 2572($v0)
    li $t4 0x763124
    sw $t4 2576($v0)
    li $t4 0xf5ab57
    sw $t4 2580($v0)
    li $t4 0x8f4637
    sw $t4 2584($v0)
    li $t4 0xa13d3b
    sw $t4 2588($v0)
    li $t4 0xcd704a
    sw $t4 2592($v0)
    li $t4 0x86482a
    sw $t4 2596($v0)
    li $t4 0x282827
    sw $t4 3080($v0)
    li $t4 0xb6b9bd
    sw $t4 3084($v0)
    li $t4 0x9f3b4c
    sw $t4 3088($v0)
    li $t4 0xc44e48
    sw $t4 3092($v0)
    li $t4 0xbd726f
    sw $t4 3096($v0)
    li $t4 0xeba181
    sw $t4 3100($v0)
    li $t4 0xa51d3f
    sw $t4 3104($v0)
    li $t4 0x6c2c40
    sw $t4 3108($v0)
    li $t4 0x141213
    sw $t4 3592($v0)
    li $t4 0xdde8e5
    sw $t4 3596($v0)
    li $t4 0xb48398
    sw $t4 3600($v0)
    li $t4 0x8c0537
    sw $t4 3604($v0)
    li $t4 0x9a8478
    sw $t4 3608($v0)
    li $t4 0xa89680
    sw $t4 3612($v0)
    li $t4 0xa9506f
    sw $t4 3616($v0)
    li $t4 0x8e7582
    sw $t4 3620($v0)
    li $t4 0x010101
    sw $t4 4096($v0)
    li $t4 0x080908
    sw $t4 4104($v0)
    li $t4 0x808180
    sw $t4 4108($v0)
    li $t4 0xb97383
    sw $t4 4112($v0)
    li $t4 0x953d55
    sw $t4 4116($v0)
    li $t4 0x86707d
    sw $t4 4120($v0)
    li $t4 0x7a405d
    sw $t4 4124($v0)
    li $t4 0x905d72
    sw $t4 4128($v0)
    li $t4 0x671b35
    sw $t4 4132($v0)
    li $t4 0x020000
    sw $t4 4612($v0)
    li $t4 0x160000
    sw $t4 4620($v0)
    li $t4 0x94183c
    sw $t4 4624($v0)
    li $t4 0x693140
    sw $t4 4628($v0)
    li $t4 0x644a56
    sw $t4 4632($v0)
    li $t4 0x844258
    sw $t4 4636($v0)
    li $t4 0x6a0026
    sw $t4 4640($v0)
    li $t4 0x790f2b
    sw $t4 4644($v0)
    li $t4 0x020001
    sw $t4 5128($v0)
    li $t4 0x0d0407
    sw $t4 5132($v0)
    li $t4 0x450823
    sw $t4 5136($v0)
    li $t4 0x94002b
    sw $t4 5140($v0)
    li $t4 0xa75d74
    sw $t4 5144($v0)
    li $t4 0xdffaf1
    sw $t4 5148($v0)
    li $t4 0x91878b
    sw $t4 5152($v0)
    li $t4 0x110004
    sw $t4 5156($v0)
    li $t4 0x010000
    sw $t4 5640($v0)
    li $t4 0x000100
    sw $t4 5644($v0)
    li $t4 0x330a19
    sw $t4 5648($v0)
    li $t4 0x970633
    sw $t4 5652($v0)
    li $t4 0xb21b4a
    sw $t4 5656($v0)
    li $t4 0xca6d8c
    sw $t4 5660($v0)
    li $t4 0x5a434a
    sw $t4 5664($v0)
    jr $ra
draw_doll_11: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 4($v0)
    sw $t4 8($v0)
    sw $t4 12($v0)
    sw $t4 24($v0)
    sw $t4 28($v0)
    sw $t4 36($v0)
    sw $t4 512($v0)
    sw $t4 516($v0)
    sw $t4 520($v0)
    sw $t4 524($v0)
    sw $t4 528($v0)
    sw $t4 532($v0)
    sw $t4 544($v0)
    sw $t4 1024($v0)
    sw $t4 1028($v0)
    sw $t4 1060($v0)
    sw $t4 1536($v0)
    sw $t4 1540($v0)
    sw $t4 1548($v0)
    sw $t4 2048($v0)
    sw $t4 2052($v0)
    sw $t4 2560($v0)
    sw $t4 2564($v0)
    sw $t4 2568($v0)
    sw $t4 2572($v0)
    sw $t4 3588($v0)
    sw $t4 4100($v0)
    sw $t4 4612($v0)
    sw $t4 4644($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5128($v0)
    sw $t4 5132($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5648($v0)
    sw $t4 5668($v0)
    li $t4 0x020101
    sw $t4 16($v0)
    sw $t4 32($v0)
    li $t4 0x000100
    sw $t4 20($v0)
    li $t4 0x150c07
    sw $t4 536($v0)
    li $t4 0x0a0403
    sw $t4 540($v0)
    li $t4 0x010100
    sw $t4 548($v0)
    sw $t4 1036($v0)
    li $t4 0x020000
    sw $t4 1032($v0)
    li $t4 0x21090c
    sw $t4 1040($v0)
    li $t4 0xb4543d
    sw $t4 1044($v0)
    li $t4 0xce3f41
    sw $t4 1048($v0)
    li $t4 0xc74e41
    sw $t4 1052($v0)
    li $t4 0x50221d
    sw $t4 1056($v0)
    li $t4 0x030301
    sw $t4 1544($v0)
    li $t4 0xa06038
    sw $t4 1552($v0)
    li $t4 0xf8ae51
    sw $t4 1556($v0)
    li $t4 0xd77e46
    sw $t4 1560($v0)
    li $t4 0xd27747
    sw $t4 1564($v0)
    li $t4 0xd88d48
    sw $t4 1568($v0)
    li $t4 0x150808
    sw $t4 1572($v0)
    li $t4 0x020401
    sw $t4 2056($v0)
    li $t4 0x030303
    sw $t4 2060($v0)
    sw $t4 4096($v0)
    li $t4 0xa95439
    sw $t4 2064($v0)
    li $t4 0xcf7250
    sw $t4 2068($v0)
    li $t4 0x994540
    sw $t4 2072($v0)
    li $t4 0xc06352
    sw $t4 2076($v0)
    li $t4 0xa42b3e
    sw $t4 2080($v0)
    li $t4 0x25080d
    sw $t4 2084($v0)
    li $t4 0x821535
    sw $t4 2576($v0)
    li $t4 0xb64451
    sw $t4 2580($v0)
    li $t4 0xca867a
    sw $t4 2584($v0)
    li $t4 0xe2937d
    sw $t4 2588($v0)
    li $t4 0x840235
    sw $t4 2592($v0)
    li $t4 0x0c0408
    sw $t4 2596($v0)
    li $t4 0x010101
    sw $t4 3072($v0)
    sw $t4 3076($v0)
    sw $t4 5156($v0)
    li $t4 0x0f0f0f
    sw $t4 3080($v0)
    li $t4 0x707674
    sw $t4 3084($v0)
    li $t4 0x8a2b55
    sw $t4 3088($v0)
    li $t4 0x996076
    sw $t4 3092($v0)
    li $t4 0x88867c
    sw $t4 3096($v0)
    li $t4 0x968187
    sw $t4 3100($v0)
    li $t4 0x9b4468
    sw $t4 3104($v0)
    li $t4 0x53494e
    sw $t4 3108($v0)
    li $t4 0x020202
    sw $t4 3584($v0)
    sw $t4 4608($v0)
    sw $t4 5644($v0)
    li $t4 0x838886
    sw $t4 3592($v0)
    li $t4 0xe2cfd7
    sw $t4 3596($v0)
    li $t4 0xaa4a5c
    sw $t4 3600($v0)
    li $t4 0x815762
    sw $t4 3604($v0)
    li $t4 0x965973
    sw $t4 3608($v0)
    li $t4 0x702543
    sw $t4 3612($v0)
    li $t4 0x81133c
    sw $t4 3616($v0)
    li $t4 0x641c30
    sw $t4 3620($v0)
    li $t4 0x666a68
    sw $t4 4104($v0)
    li $t4 0xcfc0c6
    sw $t4 4108($v0)
    li $t4 0x7d1b33
    sw $t4 4112($v0)
    li $t4 0x741e3d
    sw $t4 4116($v0)
    li $t4 0x836571
    sw $t4 4120($v0)
    li $t4 0xa17f8b
    sw $t4 4124($v0)
    li $t4 0x802548
    sw $t4 4128($v0)
    li $t4 0x2e0c0f
    sw $t4 4132($v0)
    li $t4 0x292728
    sw $t4 4616($v0)
    li $t4 0x2e3130
    sw $t4 4620($v0)
    li $t4 0x290012
    sw $t4 4624($v0)
    li $t4 0xa70031
    sw $t4 4628($v0)
    li $t4 0xa24a67
    sw $t4 4632($v0)
    li $t4 0xf1fffd
    sw $t4 4636($v0)
    li $t4 0x866f76
    sw $t4 4640($v0)
    li $t4 0x11060b
    sw $t4 5136($v0)
    li $t4 0x610725
    sw $t4 5140($v0)
    li $t4 0x960a36
    sw $t4 5144($v0)
    li $t4 0xa54867
    sw $t4 5148($v0)
    li $t4 0x3e0c1b
    sw $t4 5152($v0)
    li $t4 0x010202
    sw $t4 5640($v0)
    li $t4 0x000200
    sw $t4 5652($v0)
    li $t4 0x0c0a08
    sw $t4 5656($v0)
    li $t4 0x3b2721
    sw $t4 5660($v0)
    li $t4 0x020501
    sw $t4 5664($v0)
    jr $ra
draw_doll_12: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 4($v0)
    sw $t4 8($v0)
    sw $t4 12($v0)
    sw $t4 16($v0)
    sw $t4 20($v0)
    sw $t4 24($v0)
    sw $t4 28($v0)
    sw $t4 32($v0)
    sw $t4 36($v0)
    sw $t4 512($v0)
    sw $t4 516($v0)
    sw $t4 520($v0)
    sw $t4 528($v0)
    sw $t4 1024($v0)
    sw $t4 1028($v0)
    sw $t4 1036($v0)
    sw $t4 1536($v0)
    sw $t4 1540($v0)
    sw $t4 2048($v0)
    sw $t4 2052($v0)
    sw $t4 2060($v0)
    sw $t4 2084($v0)
    sw $t4 2560($v0)
    sw $t4 2564($v0)
    sw $t4 4096($v0)
    sw $t4 4608($v0)
    sw $t4 4612($v0)
    sw $t4 4616($v0)
    sw $t4 4620($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5644($v0)
    sw $t4 5648($v0)
    sw $t4 5652($v0)
    sw $t4 5668($v0)
    li $t4 0x010100
    sw $t4 524($v0)
    sw $t4 5664($v0)
    li $t4 0x54201d
    sw $t4 532($v0)
    li $t4 0x7f2929
    sw $t4 536($v0)
    li $t4 0x6f2624
    sw $t4 540($v0)
    li $t4 0x0e0006
    sw $t4 544($v0)
    li $t4 0x000100
    sw $t4 548($v0)
    sw $t4 4644($v0)
    li $t4 0x030201
    sw $t4 1032($v0)
    li $t4 0x682f24
    sw $t4 1040($v0)
    li $t4 0xf78f52
    sw $t4 1044($v0)
    li $t4 0xe9614b
    sw $t4 1048($v0)
    li $t4 0xea764e
    sw $t4 1052($v0)
    li $t4 0xb36e3d
    sw $t4 1056($v0)
    li $t4 0x090104
    sw $t4 1060($v0)
    li $t4 0x020401
    sw $t4 1544($v0)
    li $t4 0x020202
    sw $t4 1548($v0)
    li $t4 0xb25f3c
    sw $t4 1552($v0)
    li $t4 0xdd954c
    sw $t4 1556($v0)
    li $t4 0xa85d37
    sw $t4 1560($v0)
    li $t4 0xbb7042
    sw $t4 1564($v0)
    li $t4 0xca7f46
    sw $t4 1568($v0)
    li $t4 0x18030a
    sw $t4 1572($v0)
    li $t4 0x030101
    sw $t4 2056($v0)
    li $t4 0x702825
    sw $t4 2064($v0)
    li $t4 0xcb5b54
    sw $t4 2068($v0)
    li $t4 0xb45e65
    sw $t4 2072($v0)
    li $t4 0xe1866f
    sw $t4 2076($v0)
    li $t4 0x80112d
    sw $t4 2080($v0)
    li $t4 0x030001
    sw $t4 2568($v0)
    li $t4 0x202121
    sw $t4 2572($v0)
    li $t4 0x5c0e25
    sw $t4 2576($v0)
    li $t4 0xac556a
    sw $t4 2580($v0)
    li $t4 0xa38975
    sw $t4 2584($v0)
    li $t4 0xb1817b
    sw $t4 2588($v0)
    li $t4 0x8a1c49
    sw $t4 2592($v0)
    li $t4 0x292527
    sw $t4 2596($v0)
    li $t4 0x010101
    sw $t4 3072($v0)
    sw $t4 3584($v0)
    li $t4 0x080808
    sw $t4 3076($v0)
    sw $t4 4100($v0)
    li $t4 0xa2a3a3
    sw $t4 3080($v0)
    li $t4 0xd5d6d6
    sw $t4 3084($v0)
    li $t4 0x93415d
    sw $t4 3088($v0)
    li $t4 0x9c7280
    sw $t4 3092($v0)
    li $t4 0x825f73
    sw $t4 3096($v0)
    li $t4 0x6e4157
    sw $t4 3100($v0)
    li $t4 0x933a59
    sw $t4 3104($v0)
    li $t4 0x634550
    sw $t4 3108($v0)
    li $t4 0x0d0c0d
    sw $t4 3588($v0)
    li $t4 0xcfd0cf
    sw $t4 3592($v0)
    li $t4 0xd4d5d5
    sw $t4 3596($v0)
    li $t4 0xaf5f65
    sw $t4 3600($v0)
    li $t4 0x71384b
    sw $t4 3604($v0)
    li $t4 0x833f57
    sw $t4 3608($v0)
    li $t4 0x710f32
    sw $t4 3612($v0)
    li $t4 0x962c43
    sw $t4 3616($v0)
    li $t4 0x270c16
    sw $t4 3620($v0)
    li $t4 0x7d7c7c
    sw $t4 4104($v0)
    li $t4 0x3a3b3b
    sw $t4 4108($v0)
    li $t4 0x380014
    sw $t4 4112($v0)
    li $t4 0x8f002f
    sw $t4 4116($v0)
    li $t4 0xb1a1a5
    sw $t4 4120($v0)
    li $t4 0xcad4d0
    sw $t4 4124($v0)
    li $t4 0x540626
    sw $t4 4128($v0)
    li $t4 0x040000
    sw $t4 4132($v0)
    li $t4 0x260c17
    sw $t4 4624($v0)
    li $t4 0xbb0235
    sw $t4 4628($v0)
    li $t4 0xc06380
    sw $t4 4632($v0)
    li $t4 0xbfb4ba
    sw $t4 4636($v0)
    li $t4 0x1d030b
    sw $t4 4640($v0)
    li $t4 0x030303
    sw $t4 5128($v0)
    li $t4 0x030202
    sw $t4 5132($v0)
    li $t4 0x050203
    sw $t4 5136($v0)
    li $t4 0x1b050c
    sw $t4 5140($v0)
    li $t4 0x4e1625
    sw $t4 5144($v0)
    li $t4 0x442b2f
    sw $t4 5148($v0)
    li $t4 0x050001
    sw $t4 5152($v0)
    li $t4 0x010001
    sw $t4 5156($v0)
    li $t4 0x030802
    sw $t4 5656($v0)
    li $t4 0x120c05
    sw $t4 5660($v0)
    jr $ra
draw_doll_13: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 4($v0)
    sw $t4 8($v0)
    sw $t4 12($v0)
    sw $t4 16($v0)
    sw $t4 20($v0)
    sw $t4 28($v0)
    sw $t4 32($v0)
    sw $t4 512($v0)
    sw $t4 516($v0)
    sw $t4 1024($v0)
    sw $t4 1028($v0)
    sw $t4 1036($v0)
    sw $t4 1536($v0)
    sw $t4 1540($v0)
    sw $t4 2048($v0)
    sw $t4 2052($v0)
    sw $t4 2056($v0)
    sw $t4 3584($v0)
    sw $t4 4096($v0)
    sw $t4 4100($v0)
    sw $t4 4104($v0)
    sw $t4 4108($v0)
    sw $t4 4608($v0)
    sw $t4 4612($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5128($v0)
    sw $t4 5132($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5644($v0)
    sw $t4 5652($v0)
    sw $t4 5668($v0)
    li $t4 0x010501
    sw $t4 24($v0)
    li $t4 0x010000
    sw $t4 36($v0)
    sw $t4 520($v0)
    sw $t4 4132($v0)
    sw $t4 5156($v0)
    sw $t4 5648($v0)
    li $t4 0x010100
    sw $t4 524($v0)
    li $t4 0x120306
    sw $t4 528($v0)
    li $t4 0x8f3d31
    sw $t4 532($v0)
    li $t4 0xb23439
    sw $t4 536($v0)
    li $t4 0xa53936
    sw $t4 540($v0)
    li $t4 0x310b13
    sw $t4 544($v0)
    li $t4 0x000100
    sw $t4 548($v0)
    sw $t4 4644($v0)
    sw $t4 5136($v0)
    sw $t4 5152($v0)
    li $t4 0x030301
    sw $t4 1032($v0)
    li $t4 0x89482f
    sw $t4 1040($v0)
    li $t4 0xfda452
    sw $t4 1044($v0)
    li $t4 0xe27849
    sw $t4 1048($v0)
    li $t4 0xef994e
    sw $t4 1052($v0)
    li $t4 0xd99e49
    sw $t4 1056($v0)
    li $t4 0x0d0205
    sw $t4 1060($v0)
    li $t4 0x030401
    sw $t4 1544($v0)
    li $t4 0x040303
    sw $t4 1548($v0)
    li $t4 0xaf623b
    sw $t4 1552($v0)
    li $t4 0xd98c4e
    sw $t4 1556($v0)
    li $t4 0x9d5239
    sw $t4 1560($v0)
    li $t4 0xc67f49
    sw $t4 1564($v0)
    li $t4 0xca7b48
    sw $t4 1568($v0)
    li $t4 0x260410
    sw $t4 1572($v0)
    li $t4 0x050000
    sw $t4 2060($v0)
    li $t4 0xb6373c
    sw $t4 2064($v0)
    li $t4 0xb94c4f
    sw $t4 2068($v0)
    li $t4 0xc77777
    sw $t4 2072($v0)
    li $t4 0xdb8b76
    sw $t4 2076($v0)
    li $t4 0x9a013a
    sw $t4 2080($v0)
    li $t4 0x400018
    sw $t4 2084($v0)
    li $t4 0x010101
    sw $t4 2560($v0)
    sw $t4 3072($v0)
    li $t4 0x060505
    sw $t4 2564($v0)
    li $t4 0x9a9d9c
    sw $t4 2568($v0)
    li $t4 0x90848a
    sw $t4 2572($v0)
    li $t4 0x820630
    sw $t4 2576($v0)
    li $t4 0xa46a7b
    sw $t4 2580($v0)
    li $t4 0x897d70
    sw $t4 2584($v0)
    li $t4 0x8d7574
    sw $t4 2588($v0)
    li $t4 0x9a2053
    sw $t4 2592($v0)
    li $t4 0x582a3d
    sw $t4 2596($v0)
    li $t4 0x0c0c0c
    sw $t4 3076($v0)
    li $t4 0xd2d2d2
    sw $t4 3080($v0)
    li $t4 0xf7f8f8
    sw $t4 3084($v0)
    li $t4 0xa5596a
    sw $t4 3088($v0)
    li $t4 0x956874
    sw $t4 3092($v0)
    li $t4 0x854965
    sw $t4 3096($v0)
    li $t4 0x6a203e
    sw $t4 3100($v0)
    li $t4 0x913750
    sw $t4 3104($v0)
    li $t4 0x533540
    sw $t4 3108($v0)
    li $t4 0x090909
    sw $t4 3588($v0)
    li $t4 0x969696
    sw $t4 3592($v0)
    li $t4 0xa1a3a2
    sw $t4 3596($v0)
    li $t4 0x923f4d
    sw $t4 3600($v0)
    li $t4 0x692e45
    sw $t4 3604($v0)
    li $t4 0x886470
    sw $t4 3608($v0)
    li $t4 0x833551
    sw $t4 3612($v0)
    li $t4 0x8e1f3e
    sw $t4 3616($v0)
    li $t4 0x19040b
    sw $t4 3620($v0)
    li $t4 0x3e0018
    sw $t4 4112($v0)
    li $t4 0xa80337
    sw $t4 4116($v0)
    li $t4 0xc0bfbe
    sw $t4 4120($v0)
    li $t4 0xe1e8e6
    sw $t4 4124($v0)
    li $t4 0x4c0924
    sw $t4 4128($v0)
    li $t4 0x030202
    sw $t4 4616($v0)
    li $t4 0x020402
    sw $t4 4620($v0)
    li $t4 0x430b1f
    sw $t4 4624($v0)
    li $t4 0xad0534
    sw $t4 4628($v0)
    li $t4 0xb42753
    sw $t4 4632($v0)
    li $t4 0x9a4b66
    sw $t4 4636($v0)
    li $t4 0x20060d
    sw $t4 4640($v0)
    li $t4 0x000302
    sw $t4 5140($v0)
    li $t4 0x2f1418
    sw $t4 5144($v0)
    li $t4 0x382020
    sw $t4 5148($v0)
    li $t4 0x000200
    sw $t4 5656($v0)
    li $t4 0x050300
    sw $t4 5660($v0)
    li $t4 0x020101
    sw $t4 5664($v0)
    jr $ra
draw_doll_14: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 4($v0)
    sw $t4 8($v0)
    sw $t4 12($v0)
    sw $t4 24($v0)
    sw $t4 28($v0)
    sw $t4 36($v0)
    sw $t4 512($v0)
    sw $t4 516($v0)
    sw $t4 520($v0)
    sw $t4 528($v0)
    sw $t4 532($v0)
    sw $t4 544($v0)
    sw $t4 1024($v0)
    sw $t4 1028($v0)
    sw $t4 1060($v0)
    sw $t4 1536($v0)
    sw $t4 1544($v0)
    sw $t4 2048($v0)
    sw $t4 3584($v0)
    sw $t4 3588($v0)
    sw $t4 3592($v0)
    sw $t4 4096($v0)
    sw $t4 4608($v0)
    sw $t4 4612($v0)
    sw $t4 4616($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5644($v0)
    sw $t4 5668($v0)
    li $t4 0x020101
    sw $t4 16($v0)
    sw $t4 32($v0)
    li $t4 0x000100
    sw $t4 20($v0)
    sw $t4 5156($v0)
    sw $t4 5648($v0)
    sw $t4 5664($v0)
    li $t4 0x010000
    sw $t4 524($v0)
    sw $t4 4644($v0)
    sw $t4 5128($v0)
    li $t4 0x130907
    sw $t4 536($v0)
    li $t4 0x080003
    sw $t4 540($v0)
    li $t4 0x010100
    sw $t4 548($v0)
    li $t4 0x040202
    sw $t4 1032($v0)
    li $t4 0x000301
    sw $t4 1036($v0)
    li $t4 0x21070c
    sw $t4 1040($v0)
    li $t4 0xb45c3e
    sw $t4 1044($v0)
    li $t4 0xd34c42
    sw $t4 1048($v0)
    li $t4 0xce6942
    sw $t4 1052($v0)
    li $t4 0x4f201d
    sw $t4 1056($v0)
    li $t4 0x010101
    sw $t4 1540($v0)
    sw $t4 2560($v0)
    sw $t4 3072($v0)
    sw $t4 4100($v0)
    sw $t4 4104($v0)
    li $t4 0x070000
    sw $t4 1548($v0)
    li $t4 0xcf7f45
    sw $t4 1552($v0)
    li $t4 0xf4b050
    sw $t4 1556($v0)
    li $t4 0xce6348
    sw $t4 1560($v0)
    li $t4 0xd17f4a
    sw $t4 1564($v0)
    li $t4 0xd89449
    sw $t4 1568($v0)
    li $t4 0x17080a
    sw $t4 1572($v0)
    li $t4 0x0b0909
    sw $t4 2052($v0)
    li $t4 0x909796
    sw $t4 2056($v0)
    li $t4 0x8b4c5a
    sw $t4 2060($v0)
    li $t4 0xdf7540
    sw $t4 2064($v0)
    li $t4 0xb95c4b
    sw $t4 2068($v0)
    li $t4 0xa2514e
    sw $t4 2072($v0)
    li $t4 0xc5645a
    sw $t4 2076($v0)
    li $t4 0xa2273b
    sw $t4 2080($v0)
    li $t4 0x200207
    sw $t4 2084($v0)
    li $t4 0x0c0b0c
    sw $t4 2564($v0)
    li $t4 0xd2d5d4
    sw $t4 2568($v0)
    li $t4 0xd0c4c9
    sw $t4 2572($v0)
    li $t4 0x8e0138
    sw $t4 2576($v0)
    li $t4 0xb14852
    sw $t4 2580($v0)
    li $t4 0xd0967d
    sw $t4 2584($v0)
    li $t4 0xdd957c
    sw $t4 2588($v0)
    li $t4 0x971145
    sw $t4 2592($v0)
    li $t4 0x5c4c54
    sw $t4 2596($v0)
    li $t4 0x060505
    sw $t4 3076($v0)
    li $t4 0x9a9b9a
    sw $t4 3080($v0)
    li $t4 0xccc3c8
    sw $t4 3084($v0)
    li $t4 0x88244b
    sw $t4 3088($v0)
    li $t4 0x99657a
    sw $t4 3092($v0)
    li $t4 0x8f837e
    sw $t4 3096($v0)
    li $t4 0x997b84
    sw $t4 3100($v0)
    li $t4 0x9c5775
    sw $t4 3104($v0)
    li $t4 0x503f45
    sw $t4 3108($v0)
    li $t4 0x8a3c52
    sw $t4 3596($v0)
    li $t4 0xa64a63
    sw $t4 3600($v0)
    li $t4 0x562337
    sw $t4 3604($v0)
    li $t4 0x753f53
    sw $t4 3608($v0)
    li $t4 0x700834
    sw $t4 3612($v0)
    li $t4 0x80223f
    sw $t4 3616($v0)
    li $t4 0x432325
    sw $t4 3620($v0)
    li $t4 0x2d0e12
    sw $t4 4108($v0)
    li $t4 0x7e0f33
    sw $t4 4112($v0)
    li $t4 0x74485a
    sw $t4 4116($v0)
    li $t4 0xa1bcb2
    sw $t4 4120($v0)
    li $t4 0x848285
    sw $t4 4124($v0)
    li $t4 0x5e0c28
    sw $t4 4128($v0)
    li $t4 0x2c1013
    sw $t4 4132($v0)
    li $t4 0x010304
    sw $t4 4620($v0)
    li $t4 0x73002a
    sw $t4 4624($v0)
    li $t4 0xa7355c
    sw $t4 4628($v0)
    li $t4 0xd36788
    sw $t4 4632($v0)
    li $t4 0xd8577e
    sw $t4 4636($v0)
    li $t4 0x540b25
    sw $t4 4640($v0)
    li $t4 0x010201
    sw $t4 5132($v0)
    li $t4 0x3d091d
    sw $t4 5136($v0)
    li $t4 0x790026
    sw $t4 5140($v0)
    li $t4 0xa90028
    sw $t4 5144($v0)
    li $t4 0x990027
    sw $t4 5148($v0)
    li $t4 0x310714
    sw $t4 5152($v0)
    li $t4 0x000500
    sw $t4 5652($v0)
    li $t4 0x0b0c05
    sw $t4 5656($v0)
    li $t4 0x050c03
    sw $t4 5660($v0)
    jr $ra
draw_doll_15: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 4($v0)
    sw $t4 12($v0)
    sw $t4 32($v0)
    sw $t4 512($v0)
    sw $t4 548($v0)
    sw $t4 1024($v0)
    sw $t4 1536($v0)
    sw $t4 1544($v0)
    sw $t4 1572($v0)
    sw $t4 2048($v0)
    sw $t4 2052($v0)
    sw $t4 2560($v0)
    sw $t4 3072($v0)
    sw $t4 3584($v0)
    sw $t4 4096($v0)
    sw $t4 4100($v0)
    sw $t4 4104($v0)
    sw $t4 4608($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5128($v0)
    sw $t4 5132($v0)
    sw $t4 5136($v0)
    sw $t4 5152($v0)
    sw $t4 5156($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5644($v0)
    sw $t4 5648($v0)
    sw $t4 5656($v0)
    sw $t4 5660($v0)
    sw $t4 5664($v0)
    sw $t4 5668($v0)
    li $t4 0x020100
    sw $t4 8($v0)
    li $t4 0x3e1916
    sw $t4 16($v0)
    li $t4 0x9a3333
    sw $t4 20($v0)
    li $t4 0xa63934
    sw $t4 24($v0)
    li $t4 0x53151e
    sw $t4 28($v0)
    li $t4 0x010001
    sw $t4 36($v0)
    sw $t4 4620($v0)
    li $t4 0x010000
    sw $t4 516($v0)
    sw $t4 4640($v0)
    sw $t4 4644($v0)
    sw $t4 5652($v0)
    li $t4 0x010100
    sw $t4 520($v0)
    li $t4 0x20050c
    sw $t4 524($v0)
    li $t4 0xdb8549
    sw $t4 528($v0)
    li $t4 0xec754c
    sw $t4 532($v0)
    li $t4 0xda6449
    sw $t4 536($v0)
    li $t4 0xeb934f
    sw $t4 540($v0)
    li $t4 0x512b1d
    sw $t4 544($v0)
    li $t4 0x030101
    sw $t4 1028($v0)
    li $t4 0x020202
    sw $t4 1032($v0)
    sw $t4 4132($v0)
    sw $t4 4612($v0)
    li $t4 0x4a151b
    sw $t4 1036($v0)
    li $t4 0xf09d52
    sw $t4 1040($v0)
    li $t4 0xac623d
    sw $t4 1044($v0)
    li $t4 0xa95d3b
    sw $t4 1048($v0)
    li $t4 0xd6834e
    sw $t4 1052($v0)
    li $t4 0x653223
    sw $t4 1056($v0)
    li $t4 0x000001
    sw $t4 1060($v0)
    li $t4 0x020000
    sw $t4 1540($v0)
    li $t4 0x130002
    sw $t4 1548($v0)
    li $t4 0xc04a47
    sw $t4 1552($v0)
    li $t4 0xb5565f
    sw $t4 1556($v0)
    li $t4 0xd98f7b
    sw $t4 1560($v0)
    li $t4 0xbf4250
    sw $t4 1564($v0)
    li $t4 0x220008
    sw $t4 1568($v0)
    li $t4 0x292c2a
    sw $t4 2056($v0)
    li $t4 0x3b222a
    sw $t4 2060($v0)
    li $t4 0x93264a
    sw $t4 2064($v0)
    li $t4 0x9f7f7a
    sw $t4 2068($v0)
    li $t4 0x9e917b
    sw $t4 2072($v0)
    li $t4 0xa7496b
    sw $t4 2076($v0)
    li $t4 0x5e283e
    sw $t4 2080($v0)
    li $t4 0x0a110e
    sw $t4 2084($v0)
    li $t4 0x5d5c5c
    sw $t4 2564($v0)
    li $t4 0xe2e8e6
    sw $t4 2568($v0)
    li $t4 0xbc949f
    sw $t4 2572($v0)
    li $t4 0x8f3d55
    sw $t4 2576($v0)
    li $t4 0x8a7882
    sw $t4 2580($v0)
    li $t4 0x733150
    sw $t4 2584($v0)
    li $t4 0x8a4d5f
    sw $t4 2588($v0)
    li $t4 0x863853
    sw $t4 2592($v0)
    li $t4 0x141d1a
    sw $t4 2596($v0)
    li $t4 0x717070
    sw $t4 3076($v0)
    li $t4 0xebf0f0
    sw $t4 3080($v0)
    li $t4 0xac8385
    sw $t4 3084($v0)
    li $t4 0x893143
    sw $t4 3088($v0)
    li $t4 0x734859
    sw $t4 3092($v0)
    li $t4 0x7e304a
    sw $t4 3096($v0)
    li $t4 0x89243f
    sw $t4 3100($v0)
    li $t4 0x611a2b
    sw $t4 3104($v0)
    li $t4 0x000101
    sw $t4 3108($v0)
    li $t4 0x3e3e3e
    sw $t4 3588($v0)
    li $t4 0x535655
    sw $t4 3592($v0)
    li $t4 0x0c0107
    sw $t4 3596($v0)
    li $t4 0x770025
    sw $t4 3600($v0)
    li $t4 0xa4395c
    sw $t4 3604($v0)
    li $t4 0xdbfff4
    sw $t4 3608($v0)
    li $t4 0x905c72
    sw $t4 3612($v0)
    li $t4 0x160003
    sw $t4 3616($v0)
    li $t4 0x010301
    sw $t4 3620($v0)
    li $t4 0x000502
    sw $t4 4108($v0)
    li $t4 0x7a062d
    sw $t4 4112($v0)
    li $t4 0xbe0e44
    sw $t4 4116($v0)
    li $t4 0xbda8b1
    sw $t4 4120($v0)
    li $t4 0x613f4b
    sw $t4 4124($v0)
    li $t4 0x000100
    sw $t4 4128($v0)
    sw $t4 5140($v0)
    li $t4 0x030303
    sw $t4 4616($v0)
    li $t4 0x040404
    sw $t4 4624($v0)
    li $t4 0x21030c
    sw $t4 4628($v0)
    li $t4 0x522b31
    sw $t4 4632($v0)
    li $t4 0x120c0a
    sw $t4 4636($v0)
    li $t4 0x090802
    sw $t4 5144($v0)
    li $t4 0x070401
    sw $t4 5148($v0)
    jr $ra
draw_doll_16: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 32($v0)
    sw $t4 512($v0)
    sw $t4 548($v0)
    sw $t4 1024($v0)
    sw $t4 1032($v0)
    sw $t4 1060($v0)
    sw $t4 2052($v0)
    sw $t4 2080($v0)
    sw $t4 2564($v0)
    sw $t4 3072($v0)
    sw $t4 3076($v0)
    sw $t4 3584($v0)
    sw $t4 3616($v0)
    sw $t4 4096($v0)
    sw $t4 4104($v0)
    sw $t4 4132($v0)
    sw $t4 4608($v0)
    sw $t4 4612($v0)
    sw $t4 4616($v0)
    sw $t4 4640($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5128($v0)
    sw $t4 5140($v0)
    sw $t4 5144($v0)
    sw $t4 5152($v0)
    sw $t4 5156($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5644($v0)
    sw $t4 5648($v0)
    sw $t4 5660($v0)
    sw $t4 5664($v0)
    sw $t4 5668($v0)
    li $t4 0x010000
    sw $t4 4($v0)
    sw $t4 1536($v0)
    sw $t4 4100($v0)
    sw $t4 4644($v0)
    sw $t4 5132($v0)
    sw $t4 5136($v0)
    li $t4 0x010100
    sw $t4 8($v0)
    li $t4 0x0e0005
    sw $t4 12($v0)
    li $t4 0xae7a3b
    sw $t4 16($v0)
    li $t4 0xe8974c
    sw $t4 20($v0)
    li $t4 0xbf2841
    sw $t4 24($v0)
    li $t4 0x642624
    sw $t4 28($v0)
    li $t4 0x010101
    sw $t4 36($v0)
    sw $t4 3592($v0)
    li $t4 0x030201
    sw $t4 516($v0)
    sw $t4 3108($v0)
    li $t4 0x000101
    sw $t4 520($v0)
    sw $t4 5652($v0)
    sw $t4 5656($v0)
    li $t4 0x692b25
    sw $t4 524($v0)
    li $t4 0xffff5a
    sw $t4 528($v0)
    li $t4 0xf7ea51
    sw $t4 532($v0)
    li $t4 0xdf8949
    sw $t4 536($v0)
    li $t4 0xe99f4e
    sw $t4 540($v0)
    li $t4 0x2d1710
    sw $t4 544($v0)
    li $t4 0x040301
    sw $t4 1028($v0)
    li $t4 0x935e32
    sw $t4 1036($v0)
    li $t4 0xfee158
    sw $t4 1040($v0)
    li $t4 0xe0b44e
    sw $t4 1044($v0)
    li $t4 0xb75849
    sw $t4 1048($v0)
    li $t4 0xc33f4a
    sw $t4 1052($v0)
    li $t4 0x3c1416
    sw $t4 1056($v0)
    li $t4 0x000200
    sw $t4 1540($v0)
    sw $t4 4624($v0)
    li $t4 0x0d0b0e
    sw $t4 1544($v0)
    li $t4 0xc37846
    sw $t4 1548($v0)
    li $t4 0xe17749
    sw $t4 1552($v0)
    li $t4 0xd29344
    sw $t4 1556($v0)
    li $t4 0xd67969
    sw $t4 1560($v0)
    li $t4 0x8a2c3f
    sw $t4 1564($v0)
    li $t4 0x070002
    sw $t4 1568($v0)
    li $t4 0x020201
    sw $t4 1572($v0)
    li $t4 0x030303
    sw $t4 2048($v0)
    li $t4 0x4e484f
    sw $t4 2056($v0)
    li $t4 0xcc5b60
    sw $t4 2060($v0)
    li $t4 0xcc6238
    sw $t4 2064($v0)
    li $t4 0xc28f65
    sw $t4 2068($v0)
    li $t4 0xad91a3
    sw $t4 2072($v0)
    li $t4 0x6d6567
    sw $t4 2076($v0)
    li $t4 0x030203
    sw $t4 2084($v0)
    li $t4 0x020001
    sw $t4 2560($v0)
    li $t4 0x220d14
    sw $t4 2568($v0)
    li $t4 0xa22143
    sw $t4 2572($v0)
    li $t4 0xb63435
    sw $t4 2576($v0)
    li $t4 0xab9895
    sw $t4 2580($v0)
    li $t4 0x988d95
    sw $t4 2584($v0)
    li $t4 0x8d2e4f
    sw $t4 2588($v0)
    li $t4 0x531522
    sw $t4 2592($v0)
    li $t4 0x010201
    sw $t4 2596($v0)
    li $t4 0x0b0003
    sw $t4 3080($v0)
    li $t4 0x73002f
    sw $t4 3084($v0)
    li $t4 0xa41a3a
    sw $t4 3088($v0)
    li $t4 0x904554
    sw $t4 3092($v0)
    li $t4 0x7a3653
    sw $t4 3096($v0)
    li $t4 0x56112b
    sw $t4 3100($v0)
    li $t4 0x341716
    sw $t4 3104($v0)
    li $t4 0x010001
    sw $t4 3588($v0)
    li $t4 0x3b071b
    sw $t4 3596($v0)
    li $t4 0x97033b
    sw $t4 3600($v0)
    li $t4 0xa90028
    sw $t4 3604($v0)
    li $t4 0xb74066
    sw $t4 3608($v0)
    li $t4 0x4d494a
    sw $t4 3612($v0)
    li $t4 0x030202
    sw $t4 3620($v0)
    li $t4 0x1f0b12
    sw $t4 4108($v0)
    li $t4 0x3c101e
    sw $t4 4112($v0)
    li $t4 0x6e3346
    sw $t4 4116($v0)
    li $t4 0x663c4b
    sw $t4 4120($v0)
    li $t4 0x2c0714
    sw $t4 4124($v0)
    li $t4 0x020101
    sw $t4 4128($v0)
    li $t4 0x000100
    sw $t4 4620($v0)
    li $t4 0x161d16
    sw $t4 4628($v0)
    li $t4 0x3c362c
    sw $t4 4632($v0)
    li $t4 0x010400
    sw $t4 4636($v0)
    li $t4 0x030101
    sw $t4 5148($v0)
    jr $ra
draw_doll_17: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 8($v0)
    sw $t4 516($v0)
    sw $t4 544($v0)
    sw $t4 1028($v0)
    sw $t4 1536($v0)
    sw $t4 2048($v0)
    sw $t4 2056($v0)
    sw $t4 2084($v0)
    sw $t4 3584($v0)
    sw $t4 3592($v0)
    sw $t4 4096($v0)
    sw $t4 4608($v0)
    sw $t4 4612($v0)
    sw $t4 4620($v0)
    sw $t4 4636($v0)
    sw $t4 4644($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5128($v0)
    sw $t4 5140($v0)
    sw $t4 5144($v0)
    sw $t4 5152($v0)
    sw $t4 5156($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5644($v0)
    sw $t4 5648($v0)
    sw $t4 5660($v0)
    sw $t4 5664($v0)
    sw $t4 5668($v0)
    li $t4 0x010101
    sw $t4 4($v0)
    sw $t4 512($v0)
    sw $t4 1540($v0)
    sw $t4 2564($v0)
    li $t4 0x55221f
    sw $t4 12($v0)
    li $t4 0xba243f
    sw $t4 16($v0)
    li $t4 0xe4894b
    sw $t4 20($v0)
    li $t4 0xbd8b40
    sw $t4 24($v0)
    li $t4 0x170209
    sw $t4 28($v0)
    li $t4 0x010100
    sw $t4 32($v0)
    sw $t4 2596($v0)
    li $t4 0x010000
    sw $t4 36($v0)
    sw $t4 2560($v0)
    sw $t4 3072($v0)
    sw $t4 3076($v0)
    sw $t4 3104($v0)
    sw $t4 3108($v0)
    sw $t4 4100($v0)
    sw $t4 4132($v0)
    sw $t4 4616($v0)
    sw $t4 5132($v0)
    sw $t4 5148($v0)
    li $t4 0x1b0b0a
    sw $t4 520($v0)
    li $t4 0xdd974a
    sw $t4 524($v0)
    li $t4 0xe28c4a
    sw $t4 528($v0)
    li $t4 0xf3dd51
    sw $t4 532($v0)
    li $t4 0xffff5b
    sw $t4 536($v0)
    li $t4 0x84432e
    sw $t4 540($v0)
    li $t4 0x040301
    sw $t4 548($v0)
    li $t4 0x020101
    sw $t4 1024($v0)
    sw $t4 4104($v0)
    li $t4 0x2a0e0f
    sw $t4 1032($v0)
    li $t4 0xc03f48
    sw $t4 1036($v0)
    li $t4 0xb24645
    sw $t4 1040($v0)
    li $t4 0xdb9742
    sw $t4 1044($v0)
    li $t4 0xfbf352
    sw $t4 1048($v0)
    li $t4 0xce8443
    sw $t4 1052($v0)
    li $t4 0x040000
    sw $t4 1056($v0)
    li $t4 0x010300
    sw $t4 1060($v0)
    li $t4 0x040002
    sw $t4 1544($v0)
    li $t4 0x762036
    sw $t4 1548($v0)
    li $t4 0xd36b5f
    sw $t4 1552($v0)
    li $t4 0xc89d71
    sw $t4 1556($v0)
    li $t4 0xe2b95f
    sw $t4 1560($v0)
    li $t4 0xce604b
    sw $t4 1564($v0)
    li $t4 0x170e15
    sw $t4 1568($v0)
    li $t4 0x000200
    sw $t4 1572($v0)
    li $t4 0x030203
    sw $t4 2052($v0)
    li $t4 0x56525d
    sw $t4 2060($v0)
    li $t4 0xd0897c
    sw $t4 2064($v0)
    li $t4 0xcad0a7
    sw $t4 2068($v0)
    li $t4 0xb46b70
    sw $t4 2072($v0)
    li $t4 0xd27463
    sw $t4 2076($v0)
    li $t4 0x292d34
    sw $t4 2080($v0)
    li $t4 0x4b131e
    sw $t4 2568($v0)
    li $t4 0x7c314f
    sw $t4 2572($v0)
    li $t4 0xb06459
    sw $t4 2576($v0)
    li $t4 0x9a5354
    sw $t4 2580($v0)
    li $t4 0xbd464b
    sw $t4 2584($v0)
    li $t4 0x942d37
    sw $t4 2588($v0)
    li $t4 0x000001
    sw $t4 2592($v0)
    li $t4 0x311515
    sw $t4 3080($v0)
    li $t4 0x2d0511
    sw $t4 3084($v0)
    li $t4 0x5d0c2c
    sw $t4 3088($v0)
    li $t4 0x880032
    sw $t4 3092($v0)
    li $t4 0x7d1a32
    sw $t4 3096($v0)
    li $t4 0x320619
    sw $t4 3100($v0)
    li $t4 0x020001
    sw $t4 3588($v0)
    sw $t4 3620($v0)
    li $t4 0x271019
    sw $t4 3596($v0)
    li $t4 0xc10642
    sw $t4 3600($v0)
    li $t4 0xae0034
    sw $t4 3604($v0)
    li $t4 0x820032
    sw $t4 3608($v0)
    li $t4 0x320a19
    sw $t4 3612($v0)
    li $t4 0x000100
    sw $t4 3616($v0)
    sw $t4 4128($v0)
    li $t4 0x1f050e
    sw $t4 4108($v0)
    li $t4 0x630b25
    sw $t4 4112($v0)
    li $t4 0x7b3a4f
    sw $t4 4116($v0)
    li $t4 0x4c2935
    sw $t4 4120($v0)
    li $t4 0x210510
    sw $t4 4124($v0)
    li $t4 0x000700
    sw $t4 4624($v0)
    li $t4 0x3b3a2f
    sw $t4 4628($v0)
    li $t4 0x141712
    sw $t4 4632($v0)
    li $t4 0x010001
    sw $t4 4640($v0)
    li $t4 0x040001
    sw $t4 5136($v0)
    li $t4 0x000101
    sw $t4 5652($v0)
    sw $t4 5656($v0)
    jr $ra
draw_doll_18: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 8($v0)
    sw $t4 28($v0)
    sw $t4 36($v0)
    sw $t4 516($v0)
    sw $t4 1056($v0)
    sw $t4 2084($v0)
    sw $t4 2560($v0)
    sw $t4 2596($v0)
    sw $t4 3072($v0)
    sw $t4 3584($v0)
    sw $t4 3592($v0)
    sw $t4 3616($v0)
    sw $t4 4096($v0)
    sw $t4 4608($v0)
    sw $t4 4616($v0)
    sw $t4 4640($v0)
    sw $t4 4644($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5128($v0)
    sw $t4 5140($v0)
    sw $t4 5144($v0)
    sw $t4 5152($v0)
    sw $t4 5156($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5644($v0)
    sw $t4 5648($v0)
    sw $t4 5656($v0)
    sw $t4 5660($v0)
    sw $t4 5664($v0)
    sw $t4 5668($v0)
    li $t4 0x010000
    sw $t4 4($v0)
    sw $t4 3108($v0)
    sw $t4 4100($v0)
    sw $t4 5148($v0)
    li $t4 0x450d19
    sw $t4 12($v0)
    li $t4 0xa12f32
    sw $t4 16($v0)
    li $t4 0xa55737
    sw $t4 20($v0)
    li $t4 0x50291b
    sw $t4 24($v0)
    li $t4 0x010100
    sw $t4 32($v0)
    sw $t4 1572($v0)
    li $t4 0x030201
    sw $t4 512($v0)
    li $t4 0x432a17
    sw $t4 520($v0)
    li $t4 0xde7b4b
    sw $t4 524($v0)
    li $t4 0xe66f4c
    sw $t4 528($v0)
    li $t4 0xe89d4e
    sw $t4 532($v0)
    li $t4 0xf7cd53
    sw $t4 536($v0)
    li $t4 0x2d0a12
    sw $t4 540($v0)
    li $t4 0x020302
    sw $t4 544($v0)
    sw $t4 3588($v0)
    li $t4 0x020101
    sw $t4 548($v0)
    li $t4 0x020201
    sw $t4 1024($v0)
    li $t4 0x020001
    sw $t4 1028($v0)
    sw $t4 1536($v0)
    sw $t4 2048($v0)
    sw $t4 4104($v0)
    sw $t4 4132($v0)
    li $t4 0x883b2f
    sw $t4 1032($v0)
    li $t4 0xd6744b
    sw $t4 1036($v0)
    li $t4 0xae6f3c
    sw $t4 1040($v0)
    li $t4 0xbc6f41
    sw $t4 1044($v0)
    li $t4 0xffe959
    sw $t4 1048($v0)
    li $t4 0x863b24
    sw $t4 1052($v0)
    li $t4 0x040301
    sw $t4 1060($v0)
    li $t4 0x000100
    sw $t4 1540($v0)
    sw $t4 3076($v0)
    sw $t4 4636($v0)
    li $t4 0x300314
    sw $t4 1544($v0)
    li $t4 0xcb5d64
    sw $t4 1548($v0)
    li $t4 0xb86670
    sw $t4 1552($v0)
    li $t4 0xcc8042
    sw $t4 1556($v0)
    li $t4 0xde9849
    sw $t4 1560($v0)
    li $t4 0xc2828a
    sw $t4 1564($v0)
    li $t4 0x484c4a
    sw $t4 1568($v0)
    li $t4 0x000200
    sw $t4 2052($v0)
    li $t4 0x2f121a
    sw $t4 2056($v0)
    li $t4 0xa64769
    sw $t4 2060($v0)
    li $t4 0xba887d
    sw $t4 2064($v0)
    li $t4 0xc76a49
    sw $t4 2068($v0)
    li $t4 0xbd5346
    sw $t4 2072($v0)
    li $t4 0xd0cecd
    sw $t4 2076($v0)
    li $t4 0x878a8a
    sw $t4 2080($v0)
    li $t4 0x000201
    sw $t4 2564($v0)
    li $t4 0x050000
    sw $t4 2568($v0)
    li $t4 0x76495d
    sw $t4 2572($v0)
    li $t4 0x902651
    sw $t4 2576($v0)
    li $t4 0x8c3247
    sw $t4 2580($v0)
    li $t4 0x8a1d37
    sw $t4 2584($v0)
    li $t4 0xc691a1
    sw $t4 2588($v0)
    li $t4 0xa8b0ae
    sw $t4 2592($v0)
    li $t4 0x060103
    sw $t4 3080($v0)
    li $t4 0x550c28
    sw $t4 3084($v0)
    li $t4 0x97566e
    sw $t4 3088($v0)
    li $t4 0x893548
    sw $t4 3092($v0)
    li $t4 0x790f33
    sw $t4 3096($v0)
    li $t4 0x780836
    sw $t4 3100($v0)
    li $t4 0x0f1010
    sw $t4 3104($v0)
    li $t4 0x6d6368
    sw $t4 3596($v0)
    li $t4 0x9e7583
    sw $t4 3600($v0)
    li $t4 0x8c002d
    sw $t4 3604($v0)
    li $t4 0x8c0136
    sw $t4 3608($v0)
    li $t4 0x3f061c
    sw $t4 3612($v0)
    li $t4 0x010001
    sw $t4 3620($v0)
    sw $t4 5652($v0)
    li $t4 0x60102d
    sw $t4 4108($v0)
    li $t4 0xc4003d
    sw $t4 4112($v0)
    li $t4 0xa00237
    sw $t4 4116($v0)
    li $t4 0x7a0531
    sw $t4 4120($v0)
    li $t4 0x19060d
    sw $t4 4124($v0)
    li $t4 0x010101
    sw $t4 4128($v0)
    sw $t4 4612($v0)
    li $t4 0x0e0706
    sw $t4 4620($v0)
    li $t4 0x643b40
    sw $t4 4624($v0)
    li $t4 0x280d16
    sw $t4 4628($v0)
    li $t4 0x050404
    sw $t4 4632($v0)
    li $t4 0x040201
    sw $t4 5132($v0)
    li $t4 0x090801
    sw $t4 5136($v0)
    jr $ra
draw_doll_19: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 8($v0)
    sw $t4 28($v0)
    sw $t4 36($v0)
    sw $t4 1056($v0)
    sw $t4 3072($v0)
    sw $t4 4100($v0)
    sw $t4 4132($v0)
    sw $t4 4608($v0)
    sw $t4 4640($v0)
    sw $t4 4644($v0)
    sw $t4 5120($v0)
    sw $t4 5128($v0)
    sw $t4 5144($v0)
    sw $t4 5148($v0)
    sw $t4 5152($v0)
    sw $t4 5156($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5640($v0)
    sw $t4 5644($v0)
    sw $t4 5648($v0)
    sw $t4 5660($v0)
    sw $t4 5664($v0)
    sw $t4 5668($v0)
    li $t4 0x010101
    sw $t4 4($v0)
    sw $t4 544($v0)
    sw $t4 4612($v0)
    li $t4 0x1c060a
    sw $t4 12($v0)
    li $t4 0x5e1f20
    sw $t4 16($v0)
    li $t4 0x64251f
    sw $t4 20($v0)
    li $t4 0x150008
    sw $t4 24($v0)
    li $t4 0x010000
    sw $t4 32($v0)
    sw $t4 512($v0)
    sw $t4 2084($v0)
    sw $t4 2596($v0)
    sw $t4 3108($v0)
    sw $t4 3584($v0)
    sw $t4 3620($v0)
    sw $t4 4128($v0)
    sw $t4 4636($v0)
    sw $t4 5124($v0)
    sw $t4 5656($v0)
    li $t4 0x000100
    sw $t4 516($v0)
    sw $t4 4124($v0)
    li $t4 0x160209
    sw $t4 520($v0)
    li $t4 0xcb7a45
    sw $t4 524($v0)
    li $t4 0xea614c
    sw $t4 528($v0)
    li $t4 0xe35d4a
    sw $t4 532($v0)
    li $t4 0xc87144
    sw $t4 536($v0)
    li $t4 0x21110d
    sw $t4 540($v0)
    li $t4 0x020101
    sw $t4 548($v0)
    sw $t4 3616($v0)
    li $t4 0x040503
    sw $t4 1024($v0)
    li $t4 0x040002
    sw $t4 1028($v0)
    li $t4 0x9a4b34
    sw $t4 1032($v0)
    li $t4 0xf4bc51
    sw $t4 1036($v0)
    li $t4 0xbe7c3e
    sw $t4 1040($v0)
    li $t4 0xba703c
    sw $t4 1044($v0)
    li $t4 0xe7a84d
    sw $t4 1048($v0)
    li $t4 0x613a1e
    sw $t4 1052($v0)
    li $t4 0x040301
    sw $t4 1060($v0)
    li $t4 0x181918
    sw $t4 1536($v0)
    li $t4 0xafafb0
    sw $t4 1540($v0)
    li $t4 0xc06b64
    sw $t4 1544($v0)
    li $t4 0xba4947
    sw $t4 1548($v0)
    li $t4 0xae5357
    sw $t4 1552($v0)
    li $t4 0xd18679
    sw $t4 1556($v0)
    li $t4 0xaf5847
    sw $t4 1560($v0)
    li $t4 0x925457
    sw $t4 1564($v0)
    li $t4 0x0a0f10
    sw $t4 1568($v0)
    li $t4 0x010100
    sw $t4 1572($v0)
    li $t4 0x181617
    sw $t4 2048($v0)
    li $t4 0xd6eae1
    sw $t4 2052($v0)
    li $t4 0xa45a81
    sw $t4 2056($v0)
    li $t4 0x961b44
    sw $t4 2060($v0)
    li $t4 0xbe8f7c
    sw $t4 2064($v0)
    li $t4 0xc59985
    sw $t4 2068($v0)
    li $t4 0xc85a4d
    sw $t4 2072($v0)
    li $t4 0x88465b
    sw $t4 2076($v0)
    li $t4 0x0a100f
    sw $t4 2080($v0)
    li $t4 0x030303
    sw $t4 2560($v0)
    li $t4 0x793d56
    sw $t4 2564($v0)
    li $t4 0x9c2a53
    sw $t4 2568($v0)
    li $t4 0x8a3e5a
    sw $t4 2572($v0)
    li $t4 0x84737e
    sw $t4 2576($v0)
    li $t4 0x85556c
    sw $t4 2580($v0)
    li $t4 0x975d74
    sw $t4 2584($v0)
    li $t4 0x64203a
    sw $t4 2588($v0)
    li $t4 0x050a07
    sw $t4 2592($v0)
    li $t4 0x260008
    sw $t4 3076($v0)
    li $t4 0xae445b
    sw $t4 3080($v0)
    li $t4 0x631031
    sw $t4 3084($v0)
    li $t4 0x8b3553
    sw $t4 3088($v0)
    li $t4 0x80354f
    sw $t4 3092($v0)
    li $t4 0x650d31
    sw $t4 3096($v0)
    li $t4 0x831830
    sw $t4 3100($v0)
    li $t4 0x060602
    sw $t4 3104($v0)
    li $t4 0x000502
    sw $t4 3588($v0)
    li $t4 0x51031f
    sw $t4 3592($v0)
    li $t4 0x832348
    sw $t4 3596($v0)
    li $t4 0xb9cfc8
    sw $t4 3600($v0)
    li $t4 0xb1a8ab
    sw $t4 3604($v0)
    li $t4 0x570220
    sw $t4 3608($v0)
    li $t4 0x280511
    sw $t4 3612($v0)
    li $t4 0x020001
    sw $t4 4096($v0)
    li $t4 0x20050f
    sw $t4 4104($v0)
    li $t4 0x920d3e
    sw $t4 4108($v0)
    li $t4 0xbe7c92
    sw $t4 4112($v0)
    li $t4 0xe43268
    sw $t4 4116($v0)
    li $t4 0x820128
    sw $t4 4120($v0)
    li $t4 0x030203
    sw $t4 4616($v0)
    li $t4 0x45222c
    sw $t4 4620($v0)
    li $t4 0x70152f
    sw $t4 4624($v0)
    li $t4 0x520015
    sw $t4 4628($v0)
    li $t4 0x19030a
    sw $t4 4632($v0)
    li $t4 0x0f0f09
    sw $t4 5132($v0)
    li $t4 0x13160c
    sw $t4 5136($v0)
    li $t4 0x000300
    sw $t4 5140($v0)
    li $t4 0x030001
    sw $t4 5652($v0)
    jr $ra
draw_doll_20: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 4($v0)
    sw $t4 12($v0)
    sw $t4 16($v0)
    sw $t4 20($v0)
    sw $t4 28($v0)
    sw $t4 32($v0)
    sw $t4 36($v0)
    sw $t4 520($v0)
    sw $t4 536($v0)
    sw $t4 544($v0)
    sw $t4 548($v0)
    sw $t4 1024($v0)
    sw $t4 1028($v0)
    sw $t4 1060($v0)
    sw $t4 1568($v0)
    sw $t4 2080($v0)
    sw $t4 3072($v0)
    sw $t4 3616($v0)
    sw $t4 3620($v0)
    sw $t4 4128($v0)
    sw $t4 4132($v0)
    sw $t4 4644($v0)
    sw $t4 5148($v0)
    sw $t4 5156($v0)
    sw $t4 5632($v0)
    sw $t4 5636($v0)
    sw $t4 5652($v0)
    sw $t4 5656($v0)
    sw $t4 5660($v0)
    sw $t4 5664($v0)
    sw $t4 5668($v0)
    li $t4 0x020101
    sw $t4 8($v0)
    li $t4 0x010200
    sw $t4 24($v0)
    sw $t4 4636($v0)
    li $t4 0x020202
    sw $t4 512($v0)
    li $t4 0x030302
    sw $t4 516($v0)
    li $t4 0x1d070a
    sw $t4 524($v0)
    li $t4 0x451b17
    sw $t4 528($v0)
    li $t4 0x391512
    sw $t4 532($v0)
    li $t4 0x000100
    sw $t4 540($v0)
    sw $t4 3104($v0)
    li $t4 0x3a1715
    sw $t4 1032($v0)
    li $t4 0xdb784b
    sw $t4 1036($v0)
    li $t4 0xe34849
    sw $t4 1040($v0)
    li $t4 0xe35f4a
    sw $t4 1044($v0)
    li $t4 0x934f33
    sw $t4 1048($v0)
    li $t4 0x050002
    sw $t4 1052($v0)
    li $t4 0x010100
    sw $t4 1056($v0)
    li $t4 0x3a3c38
    sw $t4 1536($v0)
    li $t4 0x312c33
    sw $t4 1540($v0)
    li $t4 0xa45a35
    sw $t4 1544($v0)
    li $t4 0xf3b751
    sw $t4 1548($v0)
    li $t4 0xcb8d41
    sw $t4 1552($v0)
    li $t4 0xba5f40
    sw $t4 1556($v0)
    li $t4 0xffd254
    sw $t4 1560($v0)
    li $t4 0x532e1e
    sw $t4 1564($v0)
    li $t4 0x040201
    sw $t4 1572($v0)
    li $t4 0x9b9e9a
    sw $t4 2048($v0)
    li $t4 0xe0d5e3
    sw $t4 2052($v0)
    li $t4 0xc67c51
    sw $t4 2056($v0)
    li $t4 0xcd6c4d
    sw $t4 2060($v0)
    li $t4 0xaf5d55
    sw $t4 2064($v0)
    li $t4 0xc96a5f
    sw $t4 2068($v0)
    li $t4 0xb33e41
    sw $t4 2072($v0)
    li $t4 0x794839
    sw $t4 2076($v0)
    li $t4 0x030200
    sw $t4 2084($v0)
    li $t4 0x686767
    sw $t4 2560($v0)
    li $t4 0xc2d4cc
    sw $t4 2564($v0)
    li $t4 0xa75360
    sw $t4 2568($v0)
    li $t4 0xa3384c
    sw $t4 2572($v0)
    li $t4 0xbe8d7c
    sw $t4 2576($v0)
    li $t4 0xd19b88
    sw $t4 2580($v0)
    li $t4 0xb42346
    sw $t4 2584($v0)
    li $t4 0x6f2938
    sw $t4 2588($v0)
    li $t4 0x000101
    sw $t4 2592($v0)
    li $t4 0x030001
    sw $t4 2596($v0)
    sw $t4 4640($v0)
    li $t4 0x593344
    sw $t4 3076($v0)
    li $t4 0x97194c
    sw $t4 3080($v0)
    li $t4 0x916375
    sw $t4 3084($v0)
    li $t4 0x897f83
    sw $t4 3088($v0)
    li $t4 0xa08f98
    sw $t4 3092($v0)
    li $t4 0x813b53
    sw $t4 3096($v0)
    li $t4 0x2f0813
    sw $t4 3100($v0)
    li $t4 0x020001
    sw $t4 3108($v0)
    sw $t4 4608($v0)
    li $t4 0x050102
    sw $t4 3584($v0)
    li $t4 0x5b0b27
    sw $t4 3588($v0)
    li $t4 0xa92a4e
    sw $t4 3592($v0)
    li $t4 0x5a253a
    sw $t4 3596($v0)
    li $t4 0x8b445f
    sw $t4 3600($v0)
    li $t4 0x7d1b3e
    sw $t4 3604($v0)
    li $t4 0x61252e
    sw $t4 3608($v0)
    li $t4 0x030100
    sw $t4 3612($v0)
    li $t4 0x010000
    sw $t4 4096($v0)
    sw $t4 5120($v0)
    sw $t4 5124($v0)
    sw $t4 5152($v0)
    li $t4 0x100908
    sw $t4 4100($v0)
    li $t4 0x6f072d
    sw $t4 4104($v0)
    li $t4 0x7b2b4a
    sw $t4 4108($v0)
    li $t4 0xaebfb9
    sw $t4 4112($v0)
    li $t4 0x96898f
    sw $t4 4116($v0)
    li $t4 0x5b1625
    sw $t4 4120($v0)
    li $t4 0x070304
    sw $t4 4124($v0)
    li $t4 0x000200
    sw $t4 4612($v0)
    li $t4 0x480018
    sw $t4 4616($v0)
    li $t4 0xa32f5a
    sw $t4 4620($v0)
    li $t4 0xd5d5d4
    sw $t4 4624($v0)
    li $t4 0xc15a7b
    sw $t4 4628($v0)
    li $t4 0x3d0012
    sw $t4 4632($v0)
    li $t4 0x15070b
    sw $t4 5128($v0)
    li $t4 0x5c2134
    sw $t4 5132($v0)
    li $t4 0x6b132f
    sw $t4 5136($v0)
    li $t4 0x5a001d
    sw $t4 5140($v0)
    li $t4 0x110407
    sw $t4 5144($v0)
    li $t4 0x050503
    sw $t4 5640($v0)
    li $t4 0x1b1c12
    sw $t4 5644($v0)
    li $t4 0x090b04
    sw $t4 5648($v0)
    jr $ra
draw_doll_21: # start at v0, use t4
    li $t4 0x000000
    sw $t4 0($v0)
    sw $t4 4($v0)
    sw $t4 8($v0)
    sw $t4 12($v0)
    sw $t4 20($v0)
    sw $t4 24($v0)
    sw $t4 28($v0)
    sw $t4 32($v0)
    sw $t4 36($v0)
    sw $t4 512($v0)
    sw $t4 516($v0)
    sw $t4 528($v0)
    sw $t4 532($v0)
    sw $t4 540($v0)
    sw $t4 544($v0)
    sw $t4 548($v0)
    sw $t4 1028($v0)
    sw $t4 1032($v0)
    sw $t4 1036($v0)
    sw $t4 1048($v0)
    sw $t4 1056($v0)
    sw $t4 1060($v0)
    sw $t4 1536($v0)
    sw $t4 1572($v0)
    sw $t4 2052($v0)
    sw $t4 2080($v0)
    sw $t4 2592($v0)
    sw $t4 3616($v0)
    sw $t4 4096($v0)
    sw $t4 4128($v0)
    sw $t4 4640($v0)
    sw $t4 4644($v0)
    sw $t4 5156($v0)
    sw $t4 5668($v0)
    li $t4 0x010000
    sw $t4 16($v0)
    sw $t4 520($v0)
    sw $t4 1052($v0)
    sw $t4 4132($v0)
    sw $t4 5124($v0)
    li $t4 0x020201
    sw $t4 524($v0)
    li $t4 0x020101
    sw $t4 536($v0)
    sw $t4 2596($v0)
    li $t4 0x020202
    sw $t4 1024($v0)
    sw $t4 1540($v0)
    li $t4 0x050602
    sw $t4 1040($v0)
    li $t4 0x000100
    sw $t4 1044($v0)
    sw $t4 1564($v0)
    sw $t4 3104($v0)
    sw $t4 5660($v0)
    li $t4 0x110207
    sw $t4 1544($v0)
    li $t4 0x954233
    sw $t4 1548($v0)
    li $t4 0xbc383c
    sw $t4 1552($v0)
    li $t4 0xb6433b
    sw $t4 1556($v0)
    li $t4 0x431819
    sw $t4 1560($v0)
    li $t4 0x010101
    sw $t4 1568($v0)
    sw $t4 2084($v0)
    sw $t4 3108($v0)
    sw $t4 4608($v0)
    li $t4 0x2d2c2a
    sw $t4 2048($v0)
    li $t4 0x84472b
    sw $t4 2056($v0)
    li $t4 0xfdb054
    sw $t4 2060($v0)
    li $t4 0xdf7c49
    sw $t4 2064($v0)
    li $t4 0xd77649
    sw $t4 2068($v0)
    li $t4 0xde914a
    sw $t4 2072($v0)
    li $t4 0x110403
    sw $t4 2076($v0)
    li $t4 0xcbcbc9
    sw $t4 2560($v0)
    li $t4 0x8f8d96
    sw $t4 2564($v0)
    li $t4 0xaf6243
    sw $t4 2568($v0)
    li $t4 0xd57c4d
    sw $t4 2572($v0)
    li $t4 0x9a493c
    sw $t4 2576($v0)
    li $t4 0xb9604c
    sw $t4 2580($v0)
    li $t4 0xb53d44
    sw $t4 2584($v0)
    li $t4 0x4e2d31
    sw $t4 2588($v0)
    li $t4 0xb8b7b7
    sw $t4 3072($v0)
    li $t4 0xe1edeb
    sw $t4 3076($v0)
    li $t4 0xa53958
    sw $t4 3080($v0)
    li $t4 0xb23a45
    sw $t4 3084($v0)
    li $t4 0xc87b77
    sw $t4 3088($v0)
    li $t4 0xe19379
    sw $t4 3092($v0)
    li $t4 0x8f0b3e
    sw $t4 3096($v0)
    li $t4 0x584952
    sw $t4 3100($v0)
    li $t4 0x191818
    sw $t4 3584($v0)
    li $t4 0x8c6c7a
    sw $t4 3588($v0)
    li $t4 0x8e0f41
    sw $t4 3592($v0)
    li $t4 0x9a5d72
    sw $t4 3596($v0)
    li $t4 0x959284
    sw $t4 3600($v0)
    li $t4 0xa79190
    sw $t4 3604($v0)
    li $t4 0x984555
    sw $t4 3608($v0)
    li $t4 0x423b3c
    sw $t4 3612($v0)
    li $t4 0x020102
    sw $t4 3620($v0)
    li $t4 0x3d0918
    sw $t4 4100($v0)
    li $t4 0xa02d4e
    sw $t4 4104($v0)
    li $t4 0x704153
    sw $t4 4108($v0)
    li $t4 0x8d536e
    sw $t4 4112($v0)
    li $t4 0x853655
    sw $t4 4116($v0)
    li $t4 0x3f2826
    sw $t4 4120($v0)
    li $t4 0x070000
    sw $t4 4124($v0)
    li $t4 0x281916
    sw $t4 4612($v0)
    li $t4 0x8f2043
    sw $t4 4616($v0)
    li $t4 0x621c38
    sw $t4 4620($v0)
    li $t4 0x967e85
    sw $t4 4624($v0)
    li $t4 0x8c5468
    sw $t4 4628($v0)
    li $t4 0x50001c
    sw $t4 4632($v0)
    li $t4 0x050204
    sw $t4 4636($v0)
    li $t4 0x010001
    sw $t4 5120($v0)
    li $t4 0x53001b
    sw $t4 5128($v0)
    li $t4 0x953156
    sw $t4 5132($v0)
    li $t4 0xdafdf1
    sw $t4 5136($v0)
    li $t4 0xb58d9a
    sw $t4 5140($v0)
    li $t4 0x400112
    sw $t4 5144($v0)
    li $t4 0x030202
    sw $t4 5148($v0)
    li $t4 0x020001
    sw $t4 5152($v0)
    sw $t4 5632($v0)
    sw $t4 5664($v0)
    li $t4 0x000200
    sw $t4 5636($v0)
    li $t4 0x2d0513
    sw $t4 5640($v0)
    li $t4 0x7f1239
    sw $t4 5644($v0)
    li $t4 0xc06784
    sw $t4 5648($v0)
    li $t4 0xb21f4d
    sw $t4 5652($v0)
    li $t4 0x2b030e
    sw $t4 5656($v0)
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

