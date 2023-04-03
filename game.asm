# s0 player x in bytes
# s1 player y in bytes
# s2 gravity x
# s3 gravity y
# s4 orientation (positive or negative)
# s5 flag: double_jump landed
# s6 jump distance remaining
# s7 end of platform array

# NOTE: 1 pixel === 4 bytes
.eqv BASE_ADDRESS   0x10008000  # ($gp)
.eqv REFRESH_RATE   40          # in miliseconds
.eqv SIZE           512         # screen width & height in bytes
.eqv WIDTH_SHIFT    7           # 4 << WIDTH_SHIFT == SIZE
.eqv PLAYER_SIZE    64          # in bytes
.eqv PLAYER_END     60           # PLAYER_SIZE - 4 bytes
.eqv BACKGROUND     $0          # black
.eqv PLAYER_INIT    32          # initial position
.eqv PLATFORMS      5           # number of platforms
.eqv JUMP_HEIGHT    96         # in bytes
.eqv STAGE_COUNT    2           # number of stages

.data
# space padding to support 128x128 resolution
padding: .space 36000
# bounding boxes (x1, y1, x2, y2) inclusive for collisions, each box is 16 bytes
platforms: .word 0 96 124 108 208 400 300 412 0 496 124 508 400 496 508 508 0 0 172 12 16 176 28 236
# number of platforms per stage
nplat: .word 4 6
door: .word 480 400 508 476
# stage gravity (Δx, Δy) for each stage
stage_gravity: .word 0 4 0 -4
# stage counter
stage: .word 0
.text

init:
    # if all stage completed
    lw $t2 stage
    bge $t2 STAGE_COUNT terminate

    # new gravity
    sll $t0 $t0 3 # convert to bytes
    lw $s2 stage_gravity($t0) # gravity x
    addi $t0 $t0 4
    lw $s3 stage_gravity($t0) # gravity y

    li $t0 BASE_ADDRESS
    li $t1 0x10018000
    clear_screen_loop:
        sw $0 0($t0)
        addi $t0 $t0 4
        ble $t0 $t1 clear_screen_loop

    li $s0 PLAYER_INIT # player x
    li $s1 PLAYER_INIT # player y
    li $s4 1 # face east
    li $s5 2 # not landed, allow double jump

    li $s6 0 # jump distance remaining
    # get end of platforms
    sll $t2 $t2 2 # stage index in bytes
    lw $t2 nplat($t2) # get number of platforms in word
    sll $t2 $t2 4 # convert to for of 16 bytes
    la $s7 platforms
    add $s7 $s7 $t2 # end of platforms

    # la $t0 nplat
    # li $t0 PLATFORMS
    # sll $t0 $t0 4
    # add $s7 $s7 $t0  # end of platforms

    sll $v0 $s1 WIDTH_SHIFT  # get current position to v0
    add $v0 $v0 BASE_ADDRESS
    add $v0 $v0 $s0
    jal draw_player
    jal draw_stage

.globl main
main:
    li $a0 0xffff0000 # check keypress
    lw $t0 0($a0)
    la $ra gravity
    beq $t0 1 keypressed # handle keypress

    andi $t0 $s5 0x1
    bnez $t0 refresh # skip gravity if landed
    gravity:
    # j refresh # disable gravity
    move $a0 $s2 # update player position
    move $a1 $s3
    beq $s6 0 gravity_end
        neg $a0 $a0 # reverse gravity
        neg $a1 $a1
        abs $t0 $s2 # get absolute value of jump distance
        sub $s6 $s6 $t0 # update jump distance, assume s2 == 0 or s3 == 0

        abs $t0 $s3
        sub $s6 $s6 $t0
    gravity_end:
    jal player_move

    refresh:
    li $a0 REFRESH_RATE # sleep
    li $v0 32
    syscall
    j main

# terminate the program gracefully
terminate:
    li $v0 10
    syscall

keypressed: # handle keypress in 4($a0)
    addi $sp $sp -4 # push ra to stack
    sw $ra 0($sp)

    lw $t0 4($a0)
    beq $t0 0x20 keypressed_spc
    beq $t0 0x77 keypressed_w
    beq $t0 0x61 keypressed_a
    beq $t0 0x73 keypressed_s
    beq $t0 0x64 keypressed_d

    keypressed_spc:
    andi $t0 $s5 3 # take double jump, landed
    beqz $t0 keypressed_end # can't jump
    # addi $s6 $s6 JUMP_HEIGHT # jump
    li $s6 JUMP_HEIGHT
    andi $s5 $s5 0xfffc # reset last 2 bits

    andi $t0 $t0 0x1 # take last bit
    sll $t0 $t0 1 # shift left
    or $s5 $s5 $t0 # double jump iff not landed
    j keypressed_end

    la $ra keypressed_end
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

    # update orientation
    move $t2 $s4 # backup orientation to t0
    movn $s4 $a0 $s3 # if gravity is vertical, set to Δx
    movn $s4 $a1 $s2 # if gravity is horizontal, set to Δy
    movz $s4 $t2 $s4 # restore orientation

    # check in bounds
    bltz $t0 player_move_landed
    bltz $t1 player_move_landed
    add $t2 $t0 PLAYER_SIZE
    bgt $t2 SIZE player_move_landed
    add $t3 $t1 PLAYER_SIZE
    bgt $t3 SIZE player_move_landed

    # check collision, player box is (t0, t1, t2, t3)
    jal collision
    bnez $v0 player_move_landed # landed

    # check collision with door
    jal complete
    bnez $v0 next_stage

    andi $s5 $s5 0xfffe # not landed
    move $s0 $t0 # update player position
    move $s1 $t1
    sll $v0 $s1 WIDTH_SHIFT # get current position to v0
    add $v0 $v0 BASE_ADDRESS
    add $v0 $v0 $s0

    la $ra player_move_end
    j draw_player # draw player at new position

    player_move_landed: # player not moved
        andi $s5 $s5 0xfffe # not landed
        # reset jump distance if move towards top and bonk heaad
        add $t0 $a0 $s2
        add $t1 $a1 $s3
        bnez $t0 player_reset_jump_end
        bnez $t1 player_reset_jump_end
        li $s6 0 # reset jump distance
        player_reset_jump_end:
        # consider landed if Δs == gravity
        bne $a0 $s2 player_move_end
        bne $a1 $s3 player_move_end
        ori $s5 $s5 0x1 # landed
    player_move_end:
    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4
    jr $ra # return

# check collision with box (t0, t1, t2, t3) to v0
collision:
    li $v0 0
    la $t8 platforms # get platforms address to t8
    move $t9 $s7 # get end of platforms to t9

    collision_loop:
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
    beq $v0 0 collision_loop # no collision
    # has collision
    collision_end:
    jr $ra

# check stage complete with box (t0, t1, t2, t3) to v0
complete:
    li $v0 0
    la $t8 door # get platforms address to t8
    lw $t4 0($t8)
    lw $t5 4($t8)
    lw $t6 8($t8)
    lw $t7 12($t8) # get door box (t4, t5, t6, t7)
    sle $v0 $t0 $t6  # ax1 <= bx2
    slt $v1 $t4 $t2  # bx1 < ax2
    and $v0 $v0 $v1
    sle $v1 $t1 $t7  # ay1 <= by2
    and $v0 $v0 $v1
    slt $v1 $t5 $t3  # by1 < ay2
    and $v0 $v0 $v1
    jr $ra

# prepare for next stage, then goto init
next_stage:
    lw $t0 stage
    addi $t0 $t0 1
    sw $t0 stage
    j init
draw_stage:
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
    sw $t6 12288($v0)
    sw $t8 12292($v0)
    sw $t0 12296($v0)
    sw $t7 12300($v0)
    sw $t4 12304($v0)
    sw $t7 12308($v0)
    sw $t8 12312($v0)
    sw $t3 12316($v0)
    sw $t0 12320($v0)
    sw $t6 12324($v0)
    sw $t4 12328($v0)
    sw $t7 12332($v0)
    sw $t1 12336($v0)
    sw $t2 12340($v0)
    sw $t2 12344($v0)
    sw $t8 12348($v0)
    sw $t0 12352($v0)
    sw $t1 12356($v0)
    sw $t4 12360($v0)
    sw $t2 12364($v0)
    sw $t0 12368($v0)
    sw $t3 12372($v0)
    sw $t1 12376($v0)
    sw $t6 12380($v0)
    sw $t0 12384($v0)
    sw $t4 12388($v0)
    sw $t4 12392($v0)
    sw $t8 12396($v0)
    sw $t5 12400($v0)
    sw $t7 12404($v0)
    sw $t1 12408($v0)
    sw $t0 12412($v0)
    sw $t2 12800($v0)
    sw $t6 12804($v0)
    sw $t2 12808($v0)
    sw $t5 12812($v0)
    sw $t2 12816($v0)
    sw $t4 12820($v0)
    sw $t2 12824($v0)
    sw $t8 12828($v0)
    sw $t7 12832($v0)
    sw $t1 12836($v0)
    sw $t5 12840($v0)
    sw $t4 12844($v0)
    sw $t4 12848($v0)
    sw $t4 12852($v0)
    sw $t6 12856($v0)
    sw $t3 12860($v0)
    sw $t7 12864($v0)
    sw $t8 12868($v0)
    sw $t2 12872($v0)
    sw $t6 12876($v0)
    sw $t8 12880($v0)
    sw $t7 12884($v0)
    sw $t4 12888($v0)
    sw $t5 12892($v0)
    sw $t5 12896($v0)
    sw $t1 12900($v0)
    sw $t3 12904($v0)
    sw $t5 12908($v0)
    sw $t8 12912($v0)
    sw $t6 12916($v0)
    sw $t3 12920($v0)
    sw $t8 12924($v0)
    sw $t5 13312($v0)
    sw $t2 13316($v0)
    sw $t8 13320($v0)
    sw $t3 13324($v0)
    sw $t5 13328($v0)
    sw $t3 13332($v0)
    sw $t6 13336($v0)
    sw $t4 13340($v0)
    sw $t7 13344($v0)
    sw $t8 13348($v0)
    sw $t6 13352($v0)
    sw $t8 13356($v0)
    sw $t2 13360($v0)
    sw $t5 13364($v0)
    sw $t8 13368($v0)
    sw $t6 13372($v0)
    sw $t4 13376($v0)
    sw $t7 13380($v0)
    sw $t2 13384($v0)
    sw $t7 13388($v0)
    sw $t5 13392($v0)
    sw $t5 13396($v0)
    sw $t8 13400($v0)
    sw $t8 13404($v0)
    sw $t3 13408($v0)
    sw $t0 13412($v0)
    sw $t4 13416($v0)
    sw $t2 13420($v0)
    sw $t7 13424($v0)
    sw $t6 13428($v0)
    sw $t1 13432($v0)
    sw $t8 13436($v0)
    sw $t4 13824($v0)
    sw $t7 13828($v0)
    sw $t8 13832($v0)
    sw $t7 13836($v0)
    sw $t2 13840($v0)
    sw $t7 13844($v0)
    sw $t2 13848($v0)
    sw $t6 13852($v0)
    sw $t4 13856($v0)
    sw $t0 13860($v0)
    sw $t1 13864($v0)
    sw $t4 13868($v0)
    sw $t6 13872($v0)
    sw $t2 13876($v0)
    sw $t7 13880($v0)
    sw $t6 13884($v0)
    sw $t6 13888($v0)
    sw $t8 13892($v0)
    sw $t5 13896($v0)
    sw $t5 13900($v0)
    sw $t8 13904($v0)
    sw $t6 13908($v0)
    sw $t0 13912($v0)
    sw $t7 13916($v0)
    sw $t0 13920($v0)
    sw $t3 13924($v0)
    sw $t3 13928($v0)
    sw $t1 13932($v0)
    sw $t5 13936($v0)
    sw $t2 13940($v0)
    sw $t8 13944($v0)
    sw $t2 13948($v0)
    sw $t1 51408($v0)
    sw $t5 51412($v0)
    sw $t6 51416($v0)
    sw $t2 51420($v0)
    sw $t4 51424($v0)
    sw $t5 51428($v0)
    sw $t2 51432($v0)
    sw $t1 51436($v0)
    sw $t0 51440($v0)
    sw $t6 51444($v0)
    sw $t6 51448($v0)
    sw $t2 51452($v0)
    sw $t0 51456($v0)
    sw $t6 51460($v0)
    sw $t6 51464($v0)
    sw $t5 51468($v0)
    sw $t5 51472($v0)
    sw $t5 51476($v0)
    sw $t0 51480($v0)
    sw $t1 51484($v0)
    sw $t7 51488($v0)
    sw $t6 51492($v0)
    sw $t4 51496($v0)
    sw $t2 51500($v0)
    sw $t2 51920($v0)
    sw $t1 51924($v0)
    sw $t5 51928($v0)
    sw $t8 51932($v0)
    sw $t3 51936($v0)
    sw $t1 51940($v0)
    sw $t7 51944($v0)
    sw $t2 51948($v0)
    sw $t1 51952($v0)
    sw $t7 51956($v0)
    sw $t2 51960($v0)
    sw $t5 51964($v0)
    sw $t0 51968($v0)
    sw $t3 51972($v0)
    sw $t1 51976($v0)
    sw $t3 51980($v0)
    sw $t8 51984($v0)
    sw $t3 51988($v0)
    sw $t5 51992($v0)
    sw $t8 51996($v0)
    sw $t7 52000($v0)
    sw $t6 52004($v0)
    sw $t1 52008($v0)
    sw $t8 52012($v0)
    sw $t2 52432($v0)
    sw $t7 52436($v0)
    sw $t7 52440($v0)
    sw $t0 52444($v0)
    sw $t7 52448($v0)
    sw $t0 52452($v0)
    sw $t6 52456($v0)
    sw $t2 52460($v0)
    sw $t2 52464($v0)
    sw $t5 52468($v0)
    sw $t1 52472($v0)
    sw $t6 52476($v0)
    sw $t3 52480($v0)
    sw $t8 52484($v0)
    sw $t2 52488($v0)
    sw $t6 52492($v0)
    sw $t0 52496($v0)
    sw $t4 52500($v0)
    sw $t8 52504($v0)
    sw $t3 52508($v0)
    sw $t2 52512($v0)
    sw $t2 52516($v0)
    sw $t2 52520($v0)
    sw $t4 52524($v0)
    sw $t6 52944($v0)
    sw $t2 52948($v0)
    sw $t6 52952($v0)
    sw $t5 52956($v0)
    sw $t6 52960($v0)
    sw $t4 52964($v0)
    sw $t8 52968($v0)
    sw $t7 52972($v0)
    sw $t0 52976($v0)
    sw $t5 52980($v0)
    sw $t8 52984($v0)
    sw $t5 52988($v0)
    sw $t7 52992($v0)
    sw $t2 52996($v0)
    sw $t2 53000($v0)
    sw $t5 53004($v0)
    sw $t1 53008($v0)
    sw $t0 53012($v0)
    sw $t2 53016($v0)
    sw $t8 53020($v0)
    sw $t6 53024($v0)
    sw $t2 53028($v0)
    sw $t1 53032($v0)
    sw $t6 53036($v0)
    sw $t2 63488($v0)
    sw $t6 63492($v0)
    sw $t8 63496($v0)
    sw $t8 63500($v0)
    sw $t3 63504($v0)
    sw $t1 63508($v0)
    sw $t3 63512($v0)
    sw $t3 63516($v0)
    sw $t4 63520($v0)
    sw $t5 63524($v0)
    sw $t6 63528($v0)
    sw $t6 63532($v0)
    sw $t4 63536($v0)
    sw $t1 63540($v0)
    sw $t3 63544($v0)
    sw $t1 63548($v0)
    sw $t5 63552($v0)
    sw $t3 63556($v0)
    sw $t5 63560($v0)
    sw $t5 63564($v0)
    sw $t4 63568($v0)
    sw $t6 63572($v0)
    sw $t8 63576($v0)
    sw $t5 63580($v0)
    sw $t1 63584($v0)
    sw $t7 63588($v0)
    sw $t3 63592($v0)
    sw $t3 63596($v0)
    sw $t5 63600($v0)
    sw $t2 63604($v0)
    sw $t4 63608($v0)
    sw $t1 63612($v0)
    sw $t4 64000($v0)
    sw $t3 64004($v0)
    sw $t0 64008($v0)
    sw $t8 64012($v0)
    sw $t0 64016($v0)
    sw $t0 64020($v0)
    sw $t4 64024($v0)
    sw $t7 64028($v0)
    sw $t7 64032($v0)
    sw $t4 64036($v0)
    sw $t0 64040($v0)
    sw $t3 64044($v0)
    sw $t0 64048($v0)
    sw $t3 64052($v0)
    sw $t7 64056($v0)
    sw $t7 64060($v0)
    sw $t1 64064($v0)
    sw $t7 64068($v0)
    sw $t7 64072($v0)
    sw $t5 64076($v0)
    sw $t4 64080($v0)
    sw $t8 64084($v0)
    sw $t3 64088($v0)
    sw $t2 64092($v0)
    sw $t5 64096($v0)
    sw $t6 64100($v0)
    sw $t4 64104($v0)
    sw $t2 64108($v0)
    sw $t5 64112($v0)
    sw $t8 64116($v0)
    sw $t0 64120($v0)
    sw $t0 64124($v0)
    sw $t6 64512($v0)
    sw $t1 64516($v0)
    sw $t3 64520($v0)
    sw $t1 64524($v0)
    sw $t2 64528($v0)
    sw $t8 64532($v0)
    sw $t6 64536($v0)
    sw $t6 64540($v0)
    sw $t8 64544($v0)
    sw $t6 64548($v0)
    sw $t1 64552($v0)
    sw $t8 64556($v0)
    sw $t3 64560($v0)
    sw $t6 64564($v0)
    sw $t1 64568($v0)
    sw $t6 64572($v0)
    sw $t3 64576($v0)
    sw $t3 64580($v0)
    sw $t5 64584($v0)
    sw $t3 64588($v0)
    sw $t0 64592($v0)
    sw $t4 64596($v0)
    sw $t8 64600($v0)
    sw $t6 64604($v0)
    sw $t5 64608($v0)
    sw $t7 64612($v0)
    sw $t8 64616($v0)
    sw $t6 64620($v0)
    sw $t2 64624($v0)
    sw $t1 64628($v0)
    sw $t0 64632($v0)
    sw $t8 64636($v0)
    sw $t1 65024($v0)
    sw $t2 65028($v0)
    sw $t3 65032($v0)
    sw $t4 65036($v0)
    sw $t3 65040($v0)
    sw $t2 65044($v0)
    sw $t7 65048($v0)
    sw $t4 65052($v0)
    sw $t4 65056($v0)
    sw $t7 65060($v0)
    sw $t3 65064($v0)
    sw $t3 65068($v0)
    sw $t5 65072($v0)
    sw $t8 65076($v0)
    sw $t1 65080($v0)
    sw $t6 65084($v0)
    sw $t1 65088($v0)
    sw $t2 65092($v0)
    sw $t7 65096($v0)
    sw $t4 65100($v0)
    sw $t4 65104($v0)
    sw $t2 65108($v0)
    sw $t5 65112($v0)
    sw $t2 65116($v0)
    sw $t3 65120($v0)
    sw $t4 65124($v0)
    sw $t5 65128($v0)
    sw $t4 65132($v0)
    sw $t5 65136($v0)
    sw $t1 65140($v0)
    sw $t8 65144($v0)
    sw $t2 65148($v0)
    sw $t3 63888($v0)
    sw $t2 63892($v0)
    sw $t4 63896($v0)
    sw $t6 63900($v0)
    sw $t8 63904($v0)
    sw $t5 63908($v0)
    sw $t6 63912($v0)
    sw $t2 63916($v0)
    sw $t5 63920($v0)
    sw $t3 63924($v0)
    sw $t5 63928($v0)
    sw $t3 63932($v0)
    sw $t6 63936($v0)
    sw $t7 63940($v0)
    sw $t3 63944($v0)
    sw $t5 63948($v0)
    sw $t6 63952($v0)
    sw $t3 63956($v0)
    sw $t8 63960($v0)
    sw $t5 63964($v0)
    sw $t0 63968($v0)
    sw $t5 63972($v0)
    sw $t4 63976($v0)
    sw $t0 63980($v0)
    sw $t4 63984($v0)
    sw $t8 63988($v0)
    sw $t7 63992($v0)
    sw $t6 63996($v0)
    sw $t5 64400($v0)
    sw $t7 64404($v0)
    sw $t4 64408($v0)
    sw $t0 64412($v0)
    sw $t6 64416($v0)
    sw $t1 64420($v0)
    sw $t2 64424($v0)
    sw $t4 64428($v0)
    sw $t7 64432($v0)
    sw $t3 64436($v0)
    sw $t7 64440($v0)
    sw $t0 64444($v0)
    sw $t5 64448($v0)
    sw $t4 64452($v0)
    sw $t3 64456($v0)
    sw $t5 64460($v0)
    sw $t6 64464($v0)
    sw $t4 64468($v0)
    sw $t7 64472($v0)
    sw $t8 64476($v0)
    sw $t3 64480($v0)
    sw $t4 64484($v0)
    sw $t7 64488($v0)
    sw $t1 64492($v0)
    sw $t4 64496($v0)
    sw $t3 64500($v0)
    sw $t8 64504($v0)
    sw $t5 64508($v0)
    sw $t8 64912($v0)
    sw $t8 64916($v0)
    sw $t3 64920($v0)
    sw $t6 64924($v0)
    sw $t8 64928($v0)
    sw $t6 64932($v0)
    sw $t1 64936($v0)
    sw $t3 64940($v0)
    sw $t7 64944($v0)
    sw $t5 64948($v0)
    sw $t3 64952($v0)
    sw $t3 64956($v0)
    sw $t8 64960($v0)
    sw $t7 64964($v0)
    sw $t6 64968($v0)
    sw $t5 64972($v0)
    sw $t0 64976($v0)
    sw $t6 64980($v0)
    sw $t1 64984($v0)
    sw $t0 64988($v0)
    sw $t6 64992($v0)
    sw $t5 64996($v0)
    sw $t7 65000($v0)
    sw $t7 65004($v0)
    sw $t4 65008($v0)
    sw $t8 65012($v0)
    sw $t2 65016($v0)
    sw $t2 65020($v0)
    sw $t3 65424($v0)
    sw $t6 65428($v0)
    sw $t1 65432($v0)
    sw $t3 65436($v0)
    sw $t4 65440($v0)
    sw $t4 65444($v0)
    sw $t3 65448($v0)
    sw $t7 65452($v0)
    sw $t4 65456($v0)
    sw $t8 65460($v0)
    sw $t3 65464($v0)
    sw $t3 65468($v0)
    sw $t3 65472($v0)
    sw $t4 65476($v0)
    sw $t6 65480($v0)
    sw $t5 65484($v0)
    sw $t3 65488($v0)
    sw $t5 65492($v0)
    sw $t2 65496($v0)
    sw $t1 65500($v0)
    sw $t6 65504($v0)
    sw $t2 65508($v0)
    sw $t1 65512($v0)
    sw $t7 65516($v0)
    sw $t1 65520($v0)
    sw $t7 65524($v0)
    sw $t2 65528($v0)
    sw $t4 65532($v0)
    beq $t9 0 draw_stage_end # end of stage 0
    sw $t3 0($v0)
    sw $t6 4($v0)
    sw $t6 8($v0)
    sw $t7 12($v0)
    sw $t7 16($v0)
    sw $t7 20($v0)
    sw $t5 24($v0)
    sw $t7 28($v0)
    sw $t8 32($v0)
    sw $t1 36($v0)
    sw $t3 40($v0)
    sw $t2 44($v0)
    sw $t7 48($v0)
    sw $t8 52($v0)
    sw $t3 56($v0)
    sw $t4 60($v0)
    sw $t0 64($v0)
    sw $t7 68($v0)
    sw $t6 72($v0)
    sw $t0 76($v0)
    sw $t7 80($v0)
    sw $t3 84($v0)
    sw $t3 88($v0)
    sw $t3 92($v0)
    sw $t7 96($v0)
    sw $t6 100($v0)
    sw $t4 104($v0)
    sw $t0 108($v0)
    sw $t1 112($v0)
    sw $t4 116($v0)
    sw $t2 120($v0)
    sw $t5 124($v0)
    sw $t0 128($v0)
    sw $t3 132($v0)
    sw $t6 136($v0)
    sw $t8 140($v0)
    sw $t7 144($v0)
    sw $t0 148($v0)
    sw $t7 152($v0)
    sw $t0 156($v0)
    sw $t7 160($v0)
    sw $t1 164($v0)
    sw $t0 168($v0)
    sw $t1 172($v0)
    sw $t6 512($v0)
    sw $t5 516($v0)
    sw $t3 520($v0)
    sw $t3 524($v0)
    sw $t8 528($v0)
    sw $t3 532($v0)
    sw $t0 536($v0)
    sw $t6 540($v0)
    sw $t0 544($v0)
    sw $t4 548($v0)
    sw $t6 552($v0)
    sw $t1 556($v0)
    sw $t2 560($v0)
    sw $t2 564($v0)
    sw $t6 568($v0)
    sw $t3 572($v0)
    sw $t6 576($v0)
    sw $t1 580($v0)
    sw $t4 584($v0)
    sw $t2 588($v0)
    sw $t2 592($v0)
    sw $t4 596($v0)
    sw $t1 600($v0)
    sw $t6 604($v0)
    sw $t0 608($v0)
    sw $t0 612($v0)
    sw $t6 616($v0)
    sw $t2 620($v0)
    sw $t2 624($v0)
    sw $t6 628($v0)
    sw $t4 632($v0)
    sw $t1 636($v0)
    sw $t7 640($v0)
    sw $t3 644($v0)
    sw $t6 648($v0)
    sw $t5 652($v0)
    sw $t8 656($v0)
    sw $t4 660($v0)
    sw $t1 664($v0)
    sw $t3 668($v0)
    sw $t2 672($v0)
    sw $t4 676($v0)
    sw $t2 680($v0)
    sw $t1 684($v0)
    sw $t7 1024($v0)
    sw $t0 1028($v0)
    sw $t8 1032($v0)
    sw $t5 1036($v0)
    sw $t5 1040($v0)
    sw $t3 1044($v0)
    sw $t4 1048($v0)
    sw $t4 1052($v0)
    sw $t5 1056($v0)
    sw $t5 1060($v0)
    sw $t1 1064($v0)
    sw $t6 1068($v0)
    sw $t6 1072($v0)
    sw $t6 1076($v0)
    sw $t0 1080($v0)
    sw $t5 1084($v0)
    sw $t0 1088($v0)
    sw $t1 1092($v0)
    sw $t3 1096($v0)
    sw $t7 1100($v0)
    sw $t4 1104($v0)
    sw $t5 1108($v0)
    sw $t0 1112($v0)
    sw $t8 1116($v0)
    sw $t4 1120($v0)
    sw $t4 1124($v0)
    sw $t3 1128($v0)
    sw $t6 1132($v0)
    sw $t3 1136($v0)
    sw $t3 1140($v0)
    sw $t2 1144($v0)
    sw $t7 1148($v0)
    sw $t7 1152($v0)
    sw $t5 1156($v0)
    sw $t4 1160($v0)
    sw $t8 1164($v0)
    sw $t4 1168($v0)
    sw $t0 1172($v0)
    sw $t8 1176($v0)
    sw $t0 1180($v0)
    sw $t7 1184($v0)
    sw $t2 1188($v0)
    sw $t3 1192($v0)
    sw $t6 1196($v0)
    sw $t1 1536($v0)
    sw $t3 1540($v0)
    sw $t4 1544($v0)
    sw $t7 1548($v0)
    sw $t1 1552($v0)
    sw $t5 1556($v0)
    sw $t3 1560($v0)
    sw $t6 1564($v0)
    sw $t0 1568($v0)
    sw $t4 1572($v0)
    sw $t6 1576($v0)
    sw $t6 1580($v0)
    sw $t6 1584($v0)
    sw $t3 1588($v0)
    sw $t7 1592($v0)
    sw $t6 1596($v0)
    sw $t2 1600($v0)
    sw $t6 1604($v0)
    sw $t7 1608($v0)
    sw $t1 1612($v0)
    sw $t5 1616($v0)
    sw $t4 1620($v0)
    sw $t8 1624($v0)
    sw $t7 1628($v0)
    sw $t2 1632($v0)
    sw $t2 1636($v0)
    sw $t0 1640($v0)
    sw $t1 1644($v0)
    sw $t0 1648($v0)
    sw $t0 1652($v0)
    sw $t6 1656($v0)
    sw $t0 1660($v0)
    sw $t4 1664($v0)
    sw $t8 1668($v0)
    sw $t3 1672($v0)
    sw $t1 1676($v0)
    sw $t5 1680($v0)
    sw $t2 1684($v0)
    sw $t7 1688($v0)
    sw $t8 1692($v0)
    sw $t8 1696($v0)
    sw $t5 1700($v0)
    sw $t5 1704($v0)
    sw $t1 1708($v0)
    sw $t8 22544($v0)
    sw $t6 22548($v0)
    sw $t4 22552($v0)
    sw $t2 22556($v0)
    sw $t3 23056($v0)
    sw $t8 23060($v0)
    sw $t3 23064($v0)
    sw $t4 23068($v0)
    sw $t7 23568($v0)
    sw $t1 23572($v0)
    sw $t1 23576($v0)
    sw $t2 23580($v0)
    sw $t4 24080($v0)
    sw $t0 24084($v0)
    sw $t3 24088($v0)
    sw $t4 24092($v0)
    sw $t5 24592($v0)
    sw $t5 24596($v0)
    sw $t2 24600($v0)
    sw $t3 24604($v0)
    sw $t5 25104($v0)
    sw $t5 25108($v0)
    sw $t0 25112($v0)
    sw $t3 25116($v0)
    sw $t0 25616($v0)
    sw $t5 25620($v0)
    sw $t8 25624($v0)
    sw $t7 25628($v0)
    sw $t1 26128($v0)
    sw $t6 26132($v0)
    sw $t2 26136($v0)
    sw $t4 26140($v0)
    sw $t0 26640($v0)
    sw $t5 26644($v0)
    sw $t5 26648($v0)
    sw $t3 26652($v0)
    sw $t2 27152($v0)
    sw $t4 27156($v0)
    sw $t0 27160($v0)
    sw $t8 27164($v0)
    sw $t1 27664($v0)
    sw $t0 27668($v0)
    sw $t6 27672($v0)
    sw $t4 27676($v0)
    sw $t0 28176($v0)
    sw $t3 28180($v0)
    sw $t0 28184($v0)
    sw $t2 28188($v0)
    sw $t4 28688($v0)
    sw $t2 28692($v0)
    sw $t2 28696($v0)
    sw $t5 28700($v0)
    sw $t8 29200($v0)
    sw $t2 29204($v0)
    sw $t3 29208($v0)
    sw $t8 29212($v0)
    sw $t4 29712($v0)
    sw $t0 29716($v0)
    sw $t5 29720($v0)
    sw $t1 29724($v0)
    sw $t7 30224($v0)
    sw $t4 30228($v0)
    sw $t2 30232($v0)
    sw $t8 30236($v0)

    draw_stage_end:
    jr $ra # return
# draw alice at v0 with orientation and gravity
# (Δx, Δy) in (a0, a1)
# previous position in a2
draw_player:
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

    move $t3 $t2 # t3 tracks position
    sw BACKGROUND 0($t3) # store background (0, 0)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (1, 0)
    add $t3 $t3 $t0 # shift x
    li $t4 0x020101 # load color
    sw $t4 0($t3) # store color (2, 0)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (3, 0)
    add $t3 $t3 $t0 # shift x
    li $t4 0x1f0e08 # load color
    sw $t4 0($t3) # store color (4, 0)
    add $t3 $t3 $t0 # shift x
    li $t4 0x73432d # load color
    sw $t4 0($t3) # store color (5, 0)
    add $t3 $t3 $t0 # shift x
    li $t4 0x7f655c # load color
    sw $t4 0($t3) # store color (6, 0)
    add $t3 $t3 $t0 # shift x
    li $t4 0x6d6973 # load color
    sw $t4 0($t3) # store color (7, 0)
    add $t3 $t3 $t0 # shift x
    li $t4 0x736266 # load color
    sw $t4 0($t3) # store color (8, 0)
    add $t3 $t3 $t0 # shift x
    li $t4 0x66555c # load color
    sw $t4 0($t3) # store color (9, 0)
    add $t3 $t3 $t0 # shift x
    li $t4 0x75676f # load color
    sw $t4 0($t3) # store color (10, 0)
    add $t3 $t3 $t0 # shift x
    li $t4 0x4e5255 # load color
    sw $t4 0($t3) # store color (11, 0)
    add $t3 $t3 $t0 # shift x
    li $t4 0x0f1313 # load color
    sw $t4 0($t3) # store color (12, 0)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (13, 0)
    add $t3 $t3 $t0 # shift x
    li $t4 0x020202 # load color
    sw $t4 0($t3) # store color (14, 0)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (15, 0)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    li $t4 0x020101 # load color
    sw $t4 0($t3) # store color (0, 1)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (1, 1)
    add $t3 $t3 $t0 # shift x
    li $t4 0x0e0a08 # load color
    sw $t4 0($t3) # store color (2, 1)
    add $t3 $t3 $t0 # shift x
    li $t4 0x6b3724 # load color
    sw $t4 0($t3) # store color (3, 1)
    add $t3 $t3 $t0 # shift x
    li $t4 0xda8e6f # load color
    sw $t4 0($t3) # store color (4, 1)
    add $t3 $t3 $t0 # shift x
    li $t4 0xefc1b7 # load color
    sw $t4 0($t3) # store color (5, 1)
    add $t3 $t3 $t0 # shift x
    li $t4 0xca91a7 # load color
    sw $t4 0($t3) # store color (6, 1)
    add $t3 $t3 $t0 # shift x
    li $t4 0xbf728d # load color
    sw $t4 0($t3) # store color (7, 1)
    add $t3 $t3 $t0 # shift x
    li $t4 0xdc8998 # load color
    sw $t4 0($t3) # store color (8, 1)
    add $t3 $t3 $t0 # shift x
    li $t4 0xdc8996 # load color
    sw $t4 0($t3) # store color (9, 1)
    add $t3 $t3 $t0 # shift x
    li $t4 0xc5758f # load color
    sw $t4 0($t3) # store color (10, 1)
    add $t3 $t3 $t0 # shift x
    li $t4 0xc2879b # load color
    sw $t4 0($t3) # store color (11, 1)
    add $t3 $t3 $t0 # shift x
    li $t4 0xb48479 # load color
    sw $t4 0($t3) # store color (12, 1)
    add $t3 $t3 $t0 # shift x
    li $t4 0x442e24 # load color
    sw $t4 0($t3) # store color (13, 1)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (14, 1)
    add $t3 $t3 $t0 # shift x
    li $t4 0x030302 # load color
    sw $t4 0($t3) # store color (15, 1)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    li $t4 0x030201 # load color
    sw $t4 0($t3) # store color (0, 2)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (1, 2)
    add $t3 $t3 $t0 # shift x
    li $t4 0x623728 # load color
    sw $t4 0($t3) # store color (2, 2)
    add $t3 $t3 $t0 # shift x
    li $t4 0xe7865a # load color
    sw $t4 0($t3) # store color (3, 2)
    add $t3 $t3 $t0 # shift x
    li $t4 0xe89a7d # load color
    sw $t4 0($t3) # store color (4, 2)
    add $t3 $t3 $t0 # shift x
    li $t4 0xb37e94 # load color
    sw $t4 0($t3) # store color (5, 2)
    add $t3 $t3 $t0 # shift x
    li $t4 0xbe7585 # load color
    sw $t4 0($t3) # store color (6, 2)
    add $t3 $t3 $t0 # shift x
    li $t4 0xe2a589 # load color
    sw $t4 0($t3) # store color (7, 2)
    add $t3 $t3 $t0 # shift x
    li $t4 0xeeb988 # load color
    sw $t4 0($t3) # store color (8, 2)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf1bc8c # load color
    sw $t4 0($t3) # store color (9, 2)
    add $t3 $t3 $t0 # shift x
    li $t4 0xe8b187 # load color
    sw $t4 0($t3) # store color (10, 2)
    add $t3 $t3 $t0 # shift x
    li $t4 0xc8888d # load color
    sw $t4 0($t3) # store color (11, 2)
    add $t3 $t3 $t0 # shift x
    li $t4 0xdc868d # load color
    sw $t4 0($t3) # store color (12, 2)
    add $t3 $t3 $t0 # shift x
    li $t4 0xd08063 # load color
    sw $t4 0($t3) # store color (13, 2)
    add $t3 $t3 $t0 # shift x
    li $t4 0x573924 # load color
    sw $t4 0($t3) # store color (14, 2)
    add $t3 $t3 $t0 # shift x
    li $t4 0x010106 # load color
    sw $t4 0($t3) # store color (15, 2)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    li $t4 0x010101 # load color
    sw $t4 0($t3) # store color (0, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0x060401 # load color
    sw $t4 0($t3) # store color (1, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0x8d483b # load color
    sw $t4 0($t3) # store color (2, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0xfab06f # load color
    sw $t4 0($t3) # store color (3, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0xe8b269 # load color
    sw $t4 0($t3) # store color (4, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0xe08d68 # load color
    sw $t4 0($t3) # store color (5, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf8c87a # load color
    sw $t4 0($t3) # store color (6, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0xfdda71 # load color
    sw $t4 0($t3) # store color (7, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0xfddd6f # load color
    sw $t4 0($t3) # store color (8, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0xfcd96a # load color
    sw $t4 0($t3) # store color (9, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0xfedd6f # load color
    sw $t4 0($t3) # store color (10, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf9d077 # load color
    sw $t4 0($t3) # store color (11, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0xeec67f # load color
    sw $t4 0($t3) # store color (12, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0xffe185 # load color
    sw $t4 0($t3) # store color (13, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0xb59151 # load color
    sw $t4 0($t3) # store color (14, 3)
    add $t3 $t3 $t0 # shift x
    li $t4 0x352019 # load color
    sw $t4 0($t3) # store color (15, 3)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    sw BACKGROUND 0($t3) # store background (0, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0x47231c # load color
    sw $t4 0($t3) # store color (1, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0xce7d59 # load color
    sw $t4 0($t3) # store color (2, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0xffce77 # load color
    sw $t4 0($t3) # store color (3, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf1c970 # load color
    sw $t4 0($t3) # store color (4, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf0be8c # load color
    sw $t4 0($t3) # store color (5, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0xfdf1b5 # load color
    sw $t4 0($t3) # store color (6, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf4c883 # load color
    sw $t4 0($t3) # store color (7, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf9da8c # load color
    sw $t4 0($t3) # store color (8, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0xfef2bd # load color
    sw $t4 0($t3) # store color (9, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf5c985 # load color
    sw $t4 0($t3) # store color (10, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0xfde494 # load color
    sw $t4 0($t3) # store color (11, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf7dd9f # load color
    sw $t4 0($t3) # store color (12, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0xffcf83 # load color
    sw $t4 0($t3) # store color (13, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0xdfb564 # load color
    sw $t4 0($t3) # store color (14, 4)
    add $t3 $t3 $t0 # shift x
    li $t4 0xaa8d52 # load color
    sw $t4 0($t3) # store color (15, 4)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    sw BACKGROUND 0($t3) # store background (0, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0x552721 # load color
    sw $t4 0($t3) # store color (1, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0xe09e67 # load color
    sw $t4 0($t3) # store color (2, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0xffce78 # load color
    sw $t4 0($t3) # store color (3, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0xefc16e # load color
    sw $t4 0($t3) # store color (4, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0xffd886 # load color
    sw $t4 0($t3) # store color (5, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf1b981 # load color
    sw $t4 0($t3) # store color (6, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0xc2714f # load color
    sw $t4 0($t3) # store color (7, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf7da7d # load color
    sw $t4 0($t3) # store color (8, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0xffeb92 # load color
    sw $t4 0($t3) # store color (9, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0xc0794f # load color
    sw $t4 0($t3) # store color (10, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0xcb8157 # load color
    sw $t4 0($t3) # store color (11, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf5d583 # load color
    sw $t4 0($t3) # store color (12, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf9c377 # load color
    sw $t4 0($t3) # store color (13, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0xd4975b # load color
    sw $t4 0($t3) # store color (14, 5)
    add $t3 $t3 $t0 # shift x
    li $t4 0xb6a35a # load color
    sw $t4 0($t3) # store color (15, 5)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    sw BACKGROUND 0($t3) # store background (0, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0x5d2d24 # load color
    sw $t4 0($t3) # store color (1, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0xdd965f # load color
    sw $t4 0($t3) # store color (2, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0xffcb76 # load color
    sw $t4 0($t3) # store color (3, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0xeeb66f # load color
    sw $t4 0($t3) # store color (4, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0xb77747 # load color
    sw $t4 0($t3) # store color (5, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0x6c331a # load color
    sw $t4 0($t3) # store color (6, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0x8e573f # load color
    sw $t4 0($t3) # store color (7, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf1cc71 # load color
    sw $t4 0($t3) # store color (8, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0xe58e55 # load color
    sw $t4 0($t3) # store color (9, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0x572d26 # load color
    sw $t4 0($t3) # store color (10, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0x592b2a # load color
    sw $t4 0($t3) # store color (11, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0xda9c5e # load color
    sw $t4 0($t3) # store color (12, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0xe39f5b # load color
    sw $t4 0($t3) # store color (13, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0xa57145 # load color
    sw $t4 0($t3) # store color (14, 6)
    add $t3 $t3 $t0 # shift x
    li $t4 0xa5874e # load color
    sw $t4 0($t3) # store color (15, 6)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    sw BACKGROUND 0($t3) # store background (0, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0x5a2b22 # load color
    sw $t4 0($t3) # store color (1, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0xc98754 # load color
    sw $t4 0($t3) # store color (2, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0xfdcf6f # load color
    sw $t4 0($t3) # store color (3, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0xd3a264 # load color
    sw $t4 0($t3) # store color (4, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0x5b3d47 # load color
    sw $t4 0($t3) # store color (5, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0x343f49 # load color
    sw $t4 0($t3) # store color (6, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0x6b6359 # load color
    sw $t4 0($t3) # store color (7, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf2b091 # load color
    sw $t4 0($t3) # store color (8, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf8bfb2 # load color
    sw $t4 0($t3) # store color (9, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0x7594a4 # load color
    sw $t4 0($t3) # store color (10, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0x968b8e # load color
    sw $t4 0($t3) # store color (11, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0xe79e67 # load color
    sw $t4 0($t3) # store color (12, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0x9f6435 # load color
    sw $t4 0($t3) # store color (13, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0x312016 # load color
    sw $t4 0($t3) # store color (14, 7)
    add $t3 $t3 $t0 # shift x
    li $t4 0x1b1c10 # load color
    sw $t4 0($t3) # store color (15, 7)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    li $t4 0x462b20 # load color
    sw $t4 0($t3) # store color (0, 8)
    add $t3 $t3 $t0 # shift x
    li $t4 0xaa5e44 # load color
    sw $t4 0($t3) # store color (1, 8)
    add $t3 $t3 $t0 # shift x
    li $t4 0xde8e5c # load color
    sw $t4 0($t3) # store color (2, 8)
    add $t3 $t3 $t0 # shift x
    li $t4 0xe1b561 # load color
    sw $t4 0($t3) # store color (3, 8)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf8c06e # load color
    sw $t4 0($t3) # store color (4, 8)
    add $t3 $t3 $t0 # shift x
    li $t4 0xbcab97 # load color
    sw $t4 0($t3) # store color (5, 8)
    add $t3 $t3 $t0 # shift x
    li $t4 0x68b5c9 # load color
    sw $t4 0($t3) # store color (6, 8)
    add $t3 $t3 $t0 # shift x
    li $t4 0x97b9b9 # load color
    sw $t4 0($t3) # store color (7, 8)
    add $t3 $t3 $t0 # shift x
    li $t4 0xffe8df # load color
    sw $t4 0($t3) # store color (8, 8)
    add $t3 $t3 $t0 # shift x
    li $t4 0xffefe5 # load color
    sw $t4 0($t3) # store color (9, 8)
    add $t3 $t3 $t0 # shift x
    li $t4 0x9dd2d9 # load color
    sw $t4 0($t3) # store color (10, 8)
    add $t3 $t3 $t0 # shift x
    li $t4 0xaaa195 # load color
    sw $t4 0($t3) # store color (11, 8)
    add $t3 $t3 $t0 # shift x
    li $t4 0xd67b56 # load color
    sw $t4 0($t3) # store color (12, 8)
    add $t3 $t3 $t0 # shift x
    li $t4 0x6f3a27 # load color
    sw $t4 0($t3) # store color (13, 8)
    add $t3 $t3 $t0 # shift x
    li $t4 0x030407 # load color
    sw $t4 0($t3) # store color (14, 8)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (15, 8)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    li $t4 0x452a21 # load color
    sw $t4 0($t3) # store color (0, 9)
    add $t3 $t3 $t0 # shift x
    li $t4 0xbb6e4d # load color
    sw $t4 0($t3) # store color (1, 9)
    add $t3 $t3 $t0 # shift x
    li $t4 0xcd714e # load color
    sw $t4 0($t3) # store color (2, 9)
    add $t3 $t3 $t0 # shift x
    li $t4 0xc2744b # load color
    sw $t4 0($t3) # store color (3, 9)
    add $t3 $t3 $t0 # shift x
    li $t4 0xee9660 # load color
    sw $t4 0($t3) # store color (4, 9)
    add $t3 $t3 $t0 # shift x
    li $t4 0xb88c74 # load color
    sw $t4 0($t3) # store color (5, 9)
    add $t3 $t3 $t0 # shift x
    li $t4 0x87a4af # load color
    sw $t4 0($t3) # store color (6, 9)
    add $t3 $t3 $t0 # shift x
    li $t4 0xc0c5c4 # load color
    sw $t4 0($t3) # store color (7, 9)
    add $t3 $t3 $t0 # shift x
    li $t4 0xfff3e6 # load color
    sw $t4 0($t3) # store color (8, 9)
    add $t3 $t3 $t0 # shift x
    li $t4 0xffece3 # load color
    sw $t4 0($t3) # store color (9, 9)
    add $t3 $t3 $t0 # shift x
    li $t4 0xe9c6bf # load color
    sw $t4 0($t3) # store color (10, 9)
    add $t3 $t3 $t0 # shift x
    li $t4 0xd88c74 # load color
    sw $t4 0($t3) # store color (11, 9)
    add $t3 $t3 $t0 # shift x
    li $t4 0xc06b49 # load color
    sw $t4 0($t3) # store color (12, 9)
    add $t3 $t3 $t0 # shift x
    li $t4 0x4d2c1e # load color
    sw $t4 0($t3) # store color (13, 9)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (14, 9)
    add $t3 $t3 $t0 # shift x
    li $t4 0x030201 # load color
    sw $t4 0($t3) # store color (15, 9)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    li $t4 0x1a0f0e # load color
    sw $t4 0($t3) # store color (0, 10)
    add $t3 $t3 $t0 # shift x
    li $t4 0x633a2c # load color
    sw $t4 0($t3) # store color (1, 10)
    add $t3 $t3 $t0 # shift x
    li $t4 0x593323 # load color
    sw $t4 0($t3) # store color (2, 10)
    add $t3 $t3 $t0 # shift x
    li $t4 0x552c1e # load color
    sw $t4 0($t3) # store color (3, 10)
    add $t3 $t3 $t0 # shift x
    li $t4 0x9e5538 # load color
    sw $t4 0($t3) # store color (4, 10)
    add $t3 $t3 $t0 # shift x
    li $t4 0xcb8067 # load color
    sw $t4 0($t3) # store color (5, 10)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf7c2c3 # load color
    sw $t4 0($t3) # store color (6, 10)
    add $t3 $t3 $t0 # shift x
    li $t4 0xfddbd3 # load color
    sw $t4 0($t3) # store color (7, 10)
    add $t3 $t3 $t0 # shift x
    li $t4 0xdc999b # load color
    sw $t4 0($t3) # store color (8, 10)
    add $t3 $t3 $t0 # shift x
    li $t4 0xf0b3b7 # load color
    sw $t4 0($t3) # store color (9, 10)
    add $t3 $t3 $t0 # shift x
    li $t4 0xae8788 # load color
    sw $t4 0($t3) # store color (10, 10)
    add $t3 $t3 $t0 # shift x
    li $t4 0x874f39 # load color
    sw $t4 0($t3) # store color (11, 10)
    add $t3 $t3 $t0 # shift x
    li $t4 0x663621 # load color
    sw $t4 0($t3) # store color (12, 10)
    add $t3 $t3 $t0 # shift x
    li $t4 0x1f130f # load color
    sw $t4 0($t3) # store color (13, 10)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (14, 10)
    add $t3 $t3 $t0 # shift x
    li $t4 0x020101 # load color
    sw $t4 0($t3) # store color (15, 10)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    li $t4 0x242535 # load color
    sw $t4 0($t3) # store color (0, 11)
    add $t3 $t3 $t0 # shift x
    li $t4 0x1d1518 # load color
    sw $t4 0($t3) # store color (1, 11)
    add $t3 $t3 $t0 # shift x
    li $t4 0x0b0605 # load color
    sw $t4 0($t3) # store color (2, 11)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (3, 11)
    add $t3 $t3 $t0 # shift x
    li $t4 0x281108 # load color
    sw $t4 0($t3) # store color (4, 11)
    add $t3 $t3 $t0 # shift x
    li $t4 0xa07a71 # load color
    sw $t4 0($t3) # store color (5, 11)
    add $t3 $t3 $t0 # shift x
    li $t4 0xe2d8e8 # load color
    sw $t4 0($t3) # store color (6, 11)
    add $t3 $t3 $t0 # shift x
    li $t4 0xdfaeb4 # load color
    sw $t4 0($t3) # store color (7, 11)
    add $t3 $t3 $t0 # shift x
    li $t4 0xd27e89 # load color
    sw $t4 0($t3) # store color (8, 11)
    add $t3 $t3 $t0 # shift x
    li $t4 0xd78d98 # load color
    sw $t4 0($t3) # store color (9, 11)
    add $t3 $t3 $t0 # shift x
    li $t4 0xd5c2c9 # load color
    sw $t4 0($t3) # store color (10, 11)
    add $t3 $t3 $t0 # shift x
    li $t4 0x675258 # load color
    sw $t4 0($t3) # store color (11, 11)
    add $t3 $t3 $t0 # shift x
    li $t4 0x0c0002 # load color
    sw $t4 0($t3) # store color (12, 11)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (13, 11)
    add $t3 $t3 $t0 # shift x
    li $t4 0x020101 # load color
    sw $t4 0($t3) # store color (14, 11)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (15, 11)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    li $t4 0x0d0c11 # load color
    sw $t4 0($t3) # store color (0, 12)
    add $t3 $t3 $t0 # shift x
    li $t4 0x040405 # load color
    sw $t4 0($t3) # store color (1, 12)
    add $t3 $t3 $t0 # shift x
    li $t4 0x000001 # load color
    sw $t4 0($t3) # store color (2, 12)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (3, 12)
    add $t3 $t3 $t0 # shift x
    li $t4 0x080f1c # load color
    sw $t4 0($t3) # store color (4, 12)
    add $t3 $t3 $t0 # shift x
    li $t4 0x516088 # load color
    sw $t4 0($t3) # store color (5, 12)
    add $t3 $t3 $t0 # shift x
    li $t4 0x666985 # load color
    sw $t4 0($t3) # store color (6, 12)
    add $t3 $t3 $t0 # shift x
    li $t4 0x626282 # load color
    sw $t4 0($t3) # store color (7, 12)
    add $t3 $t3 $t0 # shift x
    li $t4 0x838999 # load color
    sw $t4 0($t3) # store color (8, 12)
    add $t3 $t3 $t0 # shift x
    li $t4 0x76747d # load color
    sw $t4 0($t3) # store color (9, 12)
    add $t3 $t3 $t0 # shift x
    li $t4 0x343342 # load color
    sw $t4 0($t3) # store color (10, 12)
    add $t3 $t3 $t0 # shift x
    li $t4 0x0c112c # load color
    sw $t4 0($t3) # store color (11, 12)
    add $t3 $t3 $t0 # shift x
    li $t4 0x020510 # load color
    sw $t4 0($t3) # store color (12, 12)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (13, 12)
    add $t3 $t3 $t0 # shift x
    li $t4 0x000001 # load color
    sw $t4 0($t3) # store color (14, 12)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (15, 12)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    sw BACKGROUND 0($t3) # store background (0, 13)
    add $t3 $t3 $t0 # shift x
    li $t4 0x020203 # load color
    sw $t4 0($t3) # store color (1, 13)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (2, 13)
    add $t3 $t3 $t0 # shift x
    li $t4 0x282932 # load color
    sw $t4 0($t3) # store color (3, 13)
    add $t3 $t3 $t0 # shift x
    li $t4 0x56658b # load color
    sw $t4 0($t3) # store color (4, 13)
    add $t3 $t3 $t0 # shift x
    li $t4 0x53628b # load color
    sw $t4 0($t3) # store color (5, 13)
    add $t3 $t3 $t0 # shift x
    li $t4 0x3d3c49 # load color
    sw $t4 0($t3) # store color (6, 13)
    add $t3 $t3 $t0 # shift x
    li $t4 0x7c82a0 # load color
    sw $t4 0($t3) # store color (7, 13)
    add $t3 $t3 $t0 # shift x
    li $t4 0xd8d3e1 # load color
    sw $t4 0($t3) # store color (8, 13)
    add $t3 $t3 $t0 # shift x
    li $t4 0xd6d1dc # load color
    sw $t4 0($t3) # store color (9, 13)
    add $t3 $t3 $t0 # shift x
    li $t4 0x838baa # load color
    sw $t4 0($t3) # store color (10, 13)
    add $t3 $t3 $t0 # shift x
    li $t4 0x444b64 # load color
    sw $t4 0($t3) # store color (11, 13)
    add $t3 $t3 $t0 # shift x
    li $t4 0x1a1a1f # load color
    sw $t4 0($t3) # store color (12, 13)
    add $t3 $t3 $t0 # shift x
    li $t4 0x020100 # load color
    sw $t4 0($t3) # store color (13, 13)
    add $t3 $t3 $t0 # shift x
    li $t4 0x000001 # load color
    sw $t4 0($t3) # store color (14, 13)
    add $t3 $t3 $t0 # shift x
    li $t4 0x000001 # load color
    sw $t4 0($t3) # store color (15, 13)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    li $t4 0x010101 # load color
    sw $t4 0($t3) # store color (0, 14)
    add $t3 $t3 $t0 # shift x
    li $t4 0x020202 # load color
    sw $t4 0($t3) # store color (1, 14)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (2, 14)
    add $t3 $t3 $t0 # shift x
    li $t4 0x232423 # load color
    sw $t4 0($t3) # store color (3, 14)
    add $t3 $t3 $t0 # shift x
    li $t4 0x5d5d66 # load color
    sw $t4 0($t3) # store color (4, 14)
    add $t3 $t3 $t0 # shift x
    li $t4 0x6c6e87 # load color
    sw $t4 0($t3) # store color (5, 14)
    add $t3 $t3 $t0 # shift x
    li $t4 0x7a84a5 # load color
    sw $t4 0($t3) # store color (6, 14)
    add $t3 $t3 $t0 # shift x
    li $t4 0x7d85a8 # load color
    sw $t4 0($t3) # store color (7, 14)
    add $t3 $t3 $t0 # shift x
    li $t4 0x959cba # load color
    sw $t4 0($t3) # store color (8, 14)
    add $t3 $t3 $t0 # shift x
    li $t4 0xc4c9dc # load color
    sw $t4 0($t3) # store color (9, 14)
    add $t3 $t3 $t0 # shift x
    li $t4 0xacb0cd # load color
    sw $t4 0($t3) # store color (10, 14)
    add $t3 $t3 $t0 # shift x
    li $t4 0x56576b # load color
    sw $t4 0($t3) # store color (11, 14)
    add $t3 $t3 $t0 # shift x
    li $t4 0x141319 # load color
    sw $t4 0($t3) # store color (12, 14)
    add $t3 $t3 $t0 # shift x
    li $t4 0x010001 # load color
    sw $t4 0($t3) # store color (13, 14)
    add $t3 $t3 $t0 # shift x
    li $t4 0x000100 # load color
    sw $t4 0($t3) # store color (14, 14)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (15, 14)
    add $t3 $t3 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $t3 $t2 # carriage return
    sw BACKGROUND 0($t3) # store background (0, 15)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (1, 15)
    add $t3 $t3 $t0 # shift x
    li $t4 0x010101 # load color
    sw $t4 0($t3) # store color (2, 15)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (3, 15)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (4, 15)
    add $t3 $t3 $t0 # shift x
    li $t4 0x3d3b48 # load color
    sw $t4 0($t3) # store color (5, 15)
    add $t3 $t3 $t0 # shift x
    li $t4 0x9492a5 # load color
    sw $t4 0($t3) # store color (6, 15)
    add $t3 $t3 $t0 # shift x
    li $t4 0x4a4a55 # load color
    sw $t4 0($t3) # store color (7, 15)
    add $t3 $t3 $t0 # shift x
    li $t4 0x000514 # load color
    sw $t4 0($t3) # store color (8, 15)
    add $t3 $t3 $t0 # shift x
    li $t4 0x79798c # load color
    sw $t4 0($t3) # store color (9, 15)
    add $t3 $t3 $t0 # shift x
    li $t4 0x666573 # load color
    sw $t4 0($t3) # store color (10, 15)
    add $t3 $t3 $t0 # shift x
    li $t4 0x101012 # load color
    sw $t4 0($t3) # store color (11, 15)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (12, 15)
    add $t3 $t3 $t0 # shift x
    li $t4 0x020202 # load color
    sw $t4 0($t3) # store color (13, 15)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (14, 15)
    add $t3 $t3 $t0 # shift x
    sw BACKGROUND 0($t3) # store background (15, 15)
    add $t3 $t3 $t0 # shift x

    # clean previous, a3 is previous top left corner
    beqz $a1 clear_row_end # no movement on y axis
    move $t0 $a3
    bgez $a1 clear_row # skip shift
        li $t2 PLAYER_END
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
        sw BACKGROUND 56($t0) # clear (14, y)
        sw BACKGROUND 60($t0) # clear (15, y)
    	clear_row_end:
    beqz $a0 clear_end # no movement on x axis
    bgez $a0 clear_column # skip shift
        addi $a3 $a3 PLAYER_END # shift to right column
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