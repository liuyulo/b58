# s0 player x in bytes
# s1 player y in bytes
# s2 gravity x
# s3 gravity y
# s4 orientation (positive or negative)
# s5 flag: door_unlocked double_jump landed
# s6 jump distance remaining
# s7 time

# NOTE: 1 pixel === 4 bytes
.eqv BASE_ADDRESS   0x10008000  # ($gp)
.eqv REFRESH_RATE   40          # in miliseconds
.eqv SIZE           512         # screen width & height in bytes
.eqv WIDTH_SHIFT    7           # 4 << WIDTH_SHIFT == SIZE
.eqv PLAYER_SIZE    64          # in bytes
.eqv PLAYER_END     60           # PLAYER_SIZE - 4 bytes
.eqv BACKGROUND     $0          # black
.eqv PLAYER_INIT    32          # initial position
.eqv JUMP_HEIGHT    96          # in bytes
.eqv STAGE_COUNT    20           # size of platforms_end

.data
# space padding to support 128x128 resolution
pad: .space 36000
doll: .word 48 448 92 492
doll_address: .word 0 # address of doll
door: .word 464 400 508 492
door_address: .word 0 # address of door
# inclusive bounding boxes (x1, y1, x2, y2), each bbox is 16 bytes
platforms: .word 0 96 124 108 208 400 300 412 0 496 124 508 400 496 508 508 0 0 172 12 16 176 28 236 16 32 28 76 0 432 12 492 224 416 236 444 208 112 220 316 224 448 236 508 304 288 316 412
# address to end of platforms per stage
platforms_end: .word 64 96 144 160 192
# stage counter * 4
stage: .word 0
# stage gravity (Δx, Δy) for each stage
stage_gravity: .word 0 4 0 -4 -4 0 4 0 4 0

.text
# set address of doll
la $a0 doll
la $v0 doll_address
jal save_address

la $a0 door
la $v0 door_address
jal save_address


init:
    # if all stage completed
    lw $t0 stage
    bge $t0 STAGE_COUNT terminate

    # new gravity
    sll $t0 $t0 1 # convert to byte offset for stage_gravity
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
    li $s5 2 # door locked, not landed, can double jump

    li $s6 0 # jump distance remaining

    sll $v0 $s1 WIDTH_SHIFT  # get current position to v0
    add $v0 $v0 BASE_ADDRESS
    add $v0 $v0 $s0
    li $a0 0
    li $a1 0
    jal player_move
    jal draw_stage

.globl main
main:
    li $a0 0xffff0000 # check keypress
    lw $t0 0($a0)
    la $ra gravity
    beq $t0 1 keypressed # handle keypress

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
    addi $s7 $s7 1 # increment time
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
    move $t2 $s4 # backup orientation to t2
    movn $s4 $a0 $s3 # if gravity is vertical, set to Δx
    movn $s4 $a1 $s2 # if gravity is horizontal, set to Δy
    movz $s4 $t2 $s4 # restore orientation

    # check on screen
    bgez $t0 on_screen_1
    bltz $s2 init # fell off screen
    j player_move_landed
    on_screen_1:
        bgez $t1 on_screen_2
        bltz $s3 init # fell off screen
        j player_move_landed
    on_screen_2:
        add $t2 $t0 PLAYER_SIZE
        ble $t2 SIZE on_screen_3
        bgtz $s2 init # fell off screen
        j player_move_landed
    on_screen_3:
        add $t3 $t1 PLAYER_SIZE
        ble $t3 SIZE on_screen_end
        bgtz $s3 init # fell off screen
        j player_move_landed
    on_screen_end:

    # check collision with platforms, player box is (t0, t1, t2, t3)
    la $t9 platforms # t9 = address to platforms
    # get end of platforms to t9
    lw $t8 stage # get stage number
    lw $t8 platforms_end($t8) # number of platforms * 16 bytes
    add $t8 $t8 $t9 # t8 = address to end of platforms

    collision_loop:
    sub $t8 $t8 16 # decrement platform index
    blt $t8 $t9 collision_end # no more platforms
    jal collision
    beq $v0 0 collision_loop # no collision
    collision_end:
    bnez $v0 player_move_landed # landed

    andi $t4 $s5 4 # check door_unlocked
    bnez $t4 player_move_door # door unlocked
    lw $v0 doll_address
    jal draw_doll_0

    # check collision with collectibles
    la $t8 doll
    jal collision
    sll $v0 $v0 2
    or $s5 $s5 $v0 # update doll collected
    beq $v0 0 player_move_update # no doll collected
    # doll collected
    lw $v0 doll_address
    jal clear_doll
    lw $v0 door_address
    jal draw_door
    lw $t4 stage

    la $ra player_move_update
    beq $t4 4 stage_1
    beq $t4 12 stage_3
    j player_move_update

    player_move_door:
    # check collision with door
    la $t8 door
    jal collision
    bnez $v0 next_stage

    player_move_update:
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

# check collision bbox at t8 with with bbox (t0, t1, t2, t3)
# use t4 t5 t6 t7, return at v0
collision:
    # get platform box (t4, t5, t6, t7)
    lw $t4 0($t8)
    lw $t5 4($t8)
    lw $t6 8($t8)
    lw $t7 12($t8)

    sle $v0 $t0 $t6  # ax1 <= bx2
    slt $v1 $t4 $t2  # bx1 < ax2
    and $v0 $v0 $v1
    sle $v1 $t1 $t7  # ay1 <= by2
    and $v0 $v0 $v1
    slt $v1 $t5 $t3  # by1 < ay2
    and $v0 $v0 $v1
    jr $ra
next_stage: # prepare for next stage, then goto init
    lw $t0 stage
    addi $t0 $t0 4
    sw $t0 stage
    j init

save_address: # save address from $a0 to $v0
    lw $t0 0($a0)
    lw $t1 4($a0)
    sll $t1 $t1 WIDTH_SHIFT
    li $t2 BASE_ADDRESS
    add $t2 $t2 $t0
    add $t2 $t2 $t1
    sw $t2 0($v0)
    jr $ra
stage_1: # stage 1 gimmick
    li $s2 0 # reset gravity
    li $s3 4
    li $s6 0 # reset jump distance
    jr $ra
stage_3: # stage 3 gimmick
    lw $t2 stage
    addi $t2 $t2 4
    sw $t2 stage
    li $v0 BASE_ADDRESS
    li $t2 0xc29d62
    li $t3 0x967441
    li $t4 0x9f844d
    li $t5 0x7d6739
    li $t6 0x7e6237
    li $t7 0x846d40
    li $t8 0xb8945f
    sw $t2 57568($v0)
    sw $t2 57572($v0)
    sw $t3 57576($v0)
    sw $t5 57580($v0)
    sw $t2 58080($v0)
    sw $t3 58084($v0)
    sw $t8 58088($v0)
    sw $t8 58092($v0)
    sw $t5 58592($v0)
    sw $t2 58596($v0)
    sw $t4 58600($v0)
    sw $t2 58604($v0)
    sw $t6 59104($v0)
    sw $t2 59108($v0)
    sw $t2 59112($v0)
    sw $t6 59116($v0)
    sw $t4 59616($v0)
    sw $t2 59620($v0)
    sw $t2 59624($v0)
    sw $t4 59628($v0)
    sw $t5 60128($v0)
    sw $t3 60132($v0)
    sw $t3 60136($v0)
    sw $t2 60140($v0)
    sw $t6 60640($v0)
    sw $t5 60644($v0)
    sw $t4 60648($v0)
    sw $t6 60652($v0)
    sw $t3 61152($v0)
    sw $t5 61156($v0)
    sw $t2 61160($v0)
    sw $t5 61164($v0)
    sw $t8 61664($v0)
    sw $t7 61668($v0)
    sw $t4 61672($v0)
    sw $t2 61676($v0)
    sw $t5 62176($v0)
    sw $t7 62180($v0)
    sw $t2 62184($v0)
    sw $t2 62188($v0)
    sw $t8 62688($v0)
    sw $t6 62692($v0)
    sw $t2 62696($v0)
    sw $t7 62700($v0)
    sw $t3 63200($v0)
    sw $t2 63204($v0)
    sw $t2 63208($v0)
    sw $t8 63212($v0)
    sw $t2 63712($v0)
    sw $t8 63716($v0)
    sw $t3 63720($v0)
    sw $t5 63724($v0)
    sw $t3 64224($v0)
    sw $t5 64228($v0)
    sw $t3 64232($v0)
    sw $t3 64236($v0)
    sw $t8 64736($v0)
    sw $t5 64740($v0)
    sw $t2 64744($v0)
    sw $t4 64748($v0)
    sw $t5 65248($v0)
    sw $t8 65252($v0)
    sw $t4 65256($v0)
    sw $t8 65260($v0)
    sw $t4 37168($v0)
    sw $t6 37172($v0)
    sw $t7 37176($v0)
    sw $t4 37180($v0)
    sw $t7 37680($v0)
    sw $t3 37684($v0)
    sw $t6 37688($v0)
    sw $t6 37692($v0)
    sw $t6 38192($v0)
    sw $t3 38196($v0)
    sw $t7 38200($v0)
    sw $t4 38204($v0)
    sw $t8 38704($v0)
    sw $t8 38708($v0)
    sw $t5 38712($v0)
    sw $t7 38716($v0)
    sw $t3 39216($v0)
    sw $t2 39220($v0)
    sw $t8 39224($v0)
    sw $t3 39228($v0)
    sw $t5 39728($v0)
    sw $t3 39732($v0)
    sw $t6 39736($v0)
    sw $t4 39740($v0)
    sw $t4 40240($v0)
    sw $t7 40244($v0)
    sw $t5 40248($v0)
    sw $t6 40252($v0)
    sw $t3 40752($v0)
    sw $t8 40756($v0)
    sw $t7 40760($v0)
    sw $t8 40764($v0)
    sw $t6 41264($v0)
    sw $t6 41268($v0)
    sw $t3 41272($v0)
    sw $t8 41276($v0)
    sw $t6 41776($v0)
    sw $t8 41780($v0)
    sw $t8 41784($v0)
    sw $t8 41788($v0)
    sw $t2 42288($v0)
    sw $t4 42292($v0)
    sw $t3 42296($v0)
    sw $t4 42300($v0)
    sw $t7 42800($v0)
    sw $t5 42804($v0)
    sw $t3 42808($v0)
    sw $t8 42812($v0)
    sw $t3 43312($v0)
    sw $t8 43316($v0)
    sw $t6 43320($v0)
    sw $t3 43324($v0)
    sw $t8 43824($v0)
    sw $t7 43828($v0)
    sw $t7 43832($v0)
    sw $t2 43836($v0)
    sw $t8 44336($v0)
    sw $t3 44340($v0)
    sw $t6 44344($v0)
    sw $t3 44348($v0)
    sw $t8 44848($v0)
    sw $t3 44852($v0)
    sw $t2 44856($v0)
    sw $t2 44860($v0)
    sw $t8 45360($v0)
    sw $t8 45364($v0)
    sw $t3 45368($v0)
    sw $t3 45372($v0)
    sw $t2 45872($v0)
    sw $t2 45876($v0)
    sw $t7 45880($v0)
    sw $t3 45884($v0)
    sw $t3 46384($v0)
    sw $t3 46388($v0)
    sw $t7 46392($v0)
    sw $t7 46396($v0)
    sw $t2 46896($v0)
    sw $t2 46900($v0)
    sw $t6 46904($v0)
    sw $t2 46908($v0)
    sw $t3 47408($v0)
    sw $t2 47412($v0)
    sw $t3 47416($v0)
    sw $t7 47420($v0)
    sw $t3 47920($v0)
    sw $t5 47924($v0)
    sw $t2 47928($v0)
    sw $t2 47932($v0)
    sw $t7 48432($v0)
    sw $t4 48436($v0)
    sw $t8 48440($v0)
    sw $t8 48444($v0)
    sw $t5 48944($v0)
    sw $t2 48948($v0)
    sw $t2 48952($v0)
    sw $t2 48956($v0)
    sw $t8 49456($v0)
    sw $t5 49460($v0)
    sw $t3 49464($v0)
    sw $t3 49468($v0)
    sw $t7 49968($v0)
    sw $t8 49972($v0)
    sw $t5 49976($v0)
    sw $t3 49980($v0)
    sw $t6 50480($v0)
    sw $t5 50484($v0)
    sw $t2 50488($v0)
    sw $t2 50492($v0)
    sw $t7 50992($v0)
    sw $t2 50996($v0)
    sw $t3 51000($v0)
    sw $t5 51004($v0)
    sw $t2 51504($v0)
    sw $t6 51508($v0)
    sw $t8 51512($v0)
    sw $t3 51516($v0)
    sw $t7 52016($v0)
    sw $t3 52020($v0)
    sw $t3 52024($v0)
    sw $t2 52028($v0)
    sw $t5 52528($v0)
    sw $t8 52532($v0)
    sw $t6 52536($v0)
    sw $t4 52540($v0)
    sw $t6 53040($v0)
    sw $t2 53044($v0)
    sw $t5 53048($v0)
    sw $t7 53052($v0)
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
    sw $t2 12288($v0)
    sw $t2 12292($v0)
    sw $t5 12296($v0)
    sw $t8 12300($v0)
    sw $t3 12304($v0)
    sw $t5 12308($v0)
    sw $t8 12312($v0)
    sw $t6 12316($v0)
    sw $t6 12320($v0)
    sw $t0 12324($v0)
    sw $t7 12328($v0)
    sw $t1 12332($v0)
    sw $t4 12336($v0)
    sw $t5 12340($v0)
    sw $t5 12344($v0)
    sw $t8 12348($v0)
    sw $t0 12352($v0)
    sw $t4 12356($v0)
    sw $t3 12360($v0)
    sw $t1 12364($v0)
    sw $t1 12368($v0)
    sw $t8 12372($v0)
    sw $t1 12376($v0)
    sw $t1 12380($v0)
    sw $t1 12384($v0)
    sw $t4 12388($v0)
    sw $t3 12392($v0)
    sw $t2 12396($v0)
    sw $t1 12400($v0)
    sw $t5 12404($v0)
    sw $t5 12408($v0)
    sw $t1 12412($v0)
    sw $t5 12800($v0)
    sw $t8 12804($v0)
    sw $t8 12808($v0)
    sw $t0 12812($v0)
    sw $t4 12816($v0)
    sw $t4 12820($v0)
    sw $t2 12824($v0)
    sw $t3 12828($v0)
    sw $t1 12832($v0)
    sw $t4 12836($v0)
    sw $t2 12840($v0)
    sw $t8 12844($v0)
    sw $t4 12848($v0)
    sw $t5 12852($v0)
    sw $t1 12856($v0)
    sw $t5 12860($v0)
    sw $t3 12864($v0)
    sw $t7 12868($v0)
    sw $t5 12872($v0)
    sw $t8 12876($v0)
    sw $t0 12880($v0)
    sw $t7 12884($v0)
    sw $t6 12888($v0)
    sw $t7 12892($v0)
    sw $t5 12896($v0)
    sw $t5 12900($v0)
    sw $t7 12904($v0)
    sw $t6 12908($v0)
    sw $t2 12912($v0)
    sw $t1 12916($v0)
    sw $t7 12920($v0)
    sw $t5 12924($v0)
    sw $t1 13312($v0)
    sw $t8 13316($v0)
    sw $t5 13320($v0)
    sw $t8 13324($v0)
    sw $t2 13328($v0)
    sw $t8 13332($v0)
    sw $t7 13336($v0)
    sw $t5 13340($v0)
    sw $t1 13344($v0)
    sw $t7 13348($v0)
    sw $t3 13352($v0)
    sw $t0 13356($v0)
    sw $t5 13360($v0)
    sw $t7 13364($v0)
    sw $t5 13368($v0)
    sw $t0 13372($v0)
    sw $t6 13376($v0)
    sw $t4 13380($v0)
    sw $t5 13384($v0)
    sw $t1 13388($v0)
    sw $t3 13392($v0)
    sw $t0 13396($v0)
    sw $t2 13400($v0)
    sw $t5 13404($v0)
    sw $t8 13408($v0)
    sw $t8 13412($v0)
    sw $t7 13416($v0)
    sw $t7 13420($v0)
    sw $t2 13424($v0)
    sw $t1 13428($v0)
    sw $t6 13432($v0)
    sw $t6 13436($v0)
    sw $t8 13824($v0)
    sw $t6 13828($v0)
    sw $t8 13832($v0)
    sw $t5 13836($v0)
    sw $t2 13840($v0)
    sw $t7 13844($v0)
    sw $t6 13848($v0)
    sw $t5 13852($v0)
    sw $t8 13856($v0)
    sw $t3 13860($v0)
    sw $t4 13864($v0)
    sw $t0 13868($v0)
    sw $t4 13872($v0)
    sw $t2 13876($v0)
    sw $t3 13880($v0)
    sw $t7 13884($v0)
    sw $t5 13888($v0)
    sw $t4 13892($v0)
    sw $t8 13896($v0)
    sw $t8 13900($v0)
    sw $t8 13904($v0)
    sw $t1 13908($v0)
    sw $t4 13912($v0)
    sw $t6 13916($v0)
    sw $t4 13920($v0)
    sw $t6 13924($v0)
    sw $t6 13928($v0)
    sw $t5 13932($v0)
    sw $t6 13936($v0)
    sw $t5 13940($v0)
    sw $t2 13944($v0)
    sw $t6 13948($v0)
    sw $t7 51408($v0)
    sw $t6 51412($v0)
    sw $t1 51416($v0)
    sw $t2 51420($v0)
    sw $t0 51424($v0)
    sw $t2 51428($v0)
    sw $t8 51432($v0)
    sw $t6 51436($v0)
    sw $t2 51440($v0)
    sw $t7 51444($v0)
    sw $t7 51448($v0)
    sw $t8 51452($v0)
    sw $t8 51456($v0)
    sw $t4 51460($v0)
    sw $t2 51464($v0)
    sw $t7 51468($v0)
    sw $t0 51472($v0)
    sw $t7 51476($v0)
    sw $t7 51480($v0)
    sw $t5 51484($v0)
    sw $t1 51488($v0)
    sw $t5 51492($v0)
    sw $t3 51496($v0)
    sw $t0 51500($v0)
    sw $t6 51920($v0)
    sw $t5 51924($v0)
    sw $t6 51928($v0)
    sw $t5 51932($v0)
    sw $t8 51936($v0)
    sw $t7 51940($v0)
    sw $t4 51944($v0)
    sw $t7 51948($v0)
    sw $t8 51952($v0)
    sw $t5 51956($v0)
    sw $t1 51960($v0)
    sw $t5 51964($v0)
    sw $t0 51968($v0)
    sw $t8 51972($v0)
    sw $t6 51976($v0)
    sw $t8 51980($v0)
    sw $t7 51984($v0)
    sw $t0 51988($v0)
    sw $t8 51992($v0)
    sw $t8 51996($v0)
    sw $t1 52000($v0)
    sw $t7 52004($v0)
    sw $t2 52008($v0)
    sw $t6 52012($v0)
    sw $t1 52432($v0)
    sw $t3 52436($v0)
    sw $t3 52440($v0)
    sw $t5 52444($v0)
    sw $t5 52448($v0)
    sw $t2 52452($v0)
    sw $t8 52456($v0)
    sw $t8 52460($v0)
    sw $t8 52464($v0)
    sw $t5 52468($v0)
    sw $t5 52472($v0)
    sw $t1 52476($v0)
    sw $t6 52480($v0)
    sw $t2 52484($v0)
    sw $t6 52488($v0)
    sw $t5 52492($v0)
    sw $t7 52496($v0)
    sw $t0 52500($v0)
    sw $t7 52504($v0)
    sw $t5 52508($v0)
    sw $t0 52512($v0)
    sw $t4 52516($v0)
    sw $t1 52520($v0)
    sw $t8 52524($v0)
    sw $t6 52944($v0)
    sw $t3 52948($v0)
    sw $t8 52952($v0)
    sw $t2 52956($v0)
    sw $t1 52960($v0)
    sw $t3 52964($v0)
    sw $t0 52968($v0)
    sw $t2 52972($v0)
    sw $t4 52976($v0)
    sw $t3 52980($v0)
    sw $t5 52984($v0)
    sw $t7 52988($v0)
    sw $t2 52992($v0)
    sw $t5 52996($v0)
    sw $t2 53000($v0)
    sw $t1 53004($v0)
    sw $t7 53008($v0)
    sw $t6 53012($v0)
    sw $t0 53016($v0)
    sw $t0 53020($v0)
    sw $t7 53024($v0)
    sw $t1 53028($v0)
    sw $t1 53032($v0)
    sw $t8 53036($v0)
    sw $t2 63488($v0)
    sw $t0 63492($v0)
    sw $t8 63496($v0)
    sw $t3 63500($v0)
    sw $t7 63504($v0)
    sw $t2 63508($v0)
    sw $t3 63512($v0)
    sw $t2 63516($v0)
    sw $t0 63520($v0)
    sw $t5 63524($v0)
    sw $t2 63528($v0)
    sw $t0 63532($v0)
    sw $t4 63536($v0)
    sw $t3 63540($v0)
    sw $t5 63544($v0)
    sw $t0 63548($v0)
    sw $t3 63552($v0)
    sw $t5 63556($v0)
    sw $t3 63560($v0)
    sw $t7 63564($v0)
    sw $t4 63568($v0)
    sw $t8 63572($v0)
    sw $t2 63576($v0)
    sw $t1 63580($v0)
    sw $t0 63584($v0)
    sw $t2 63588($v0)
    sw $t4 63592($v0)
    sw $t0 63596($v0)
    sw $t4 63600($v0)
    sw $t6 63604($v0)
    sw $t8 63608($v0)
    sw $t4 63612($v0)
    sw $t4 64000($v0)
    sw $t8 64004($v0)
    sw $t0 64008($v0)
    sw $t2 64012($v0)
    sw $t5 64016($v0)
    sw $t8 64020($v0)
    sw $t4 64024($v0)
    sw $t6 64028($v0)
    sw $t8 64032($v0)
    sw $t8 64036($v0)
    sw $t2 64040($v0)
    sw $t5 64044($v0)
    sw $t5 64048($v0)
    sw $t3 64052($v0)
    sw $t8 64056($v0)
    sw $t3 64060($v0)
    sw $t3 64064($v0)
    sw $t7 64068($v0)
    sw $t3 64072($v0)
    sw $t4 64076($v0)
    sw $t6 64080($v0)
    sw $t8 64084($v0)
    sw $t5 64088($v0)
    sw $t6 64092($v0)
    sw $t3 64096($v0)
    sw $t8 64100($v0)
    sw $t3 64104($v0)
    sw $t1 64108($v0)
    sw $t6 64112($v0)
    sw $t4 64116($v0)
    sw $t2 64120($v0)
    sw $t8 64124($v0)
    sw $t0 64512($v0)
    sw $t2 64516($v0)
    sw $t6 64520($v0)
    sw $t7 64524($v0)
    sw $t6 64528($v0)
    sw $t4 64532($v0)
    sw $t8 64536($v0)
    sw $t1 64540($v0)
    sw $t2 64544($v0)
    sw $t5 64548($v0)
    sw $t0 64552($v0)
    sw $t0 64556($v0)
    sw $t5 64560($v0)
    sw $t6 64564($v0)
    sw $t8 64568($v0)
    sw $t2 64572($v0)
    sw $t3 64576($v0)
    sw $t2 64580($v0)
    sw $t1 64584($v0)
    sw $t1 64588($v0)
    sw $t0 64592($v0)
    sw $t8 64596($v0)
    sw $t8 64600($v0)
    sw $t7 64604($v0)
    sw $t0 64608($v0)
    sw $t0 64612($v0)
    sw $t3 64616($v0)
    sw $t2 64620($v0)
    sw $t3 64624($v0)
    sw $t0 64628($v0)
    sw $t0 64632($v0)
    sw $t6 64636($v0)
    sw $t2 65024($v0)
    sw $t1 65028($v0)
    sw $t1 65032($v0)
    sw $t1 65036($v0)
    sw $t0 65040($v0)
    sw $t6 65044($v0)
    sw $t1 65048($v0)
    sw $t8 65052($v0)
    sw $t7 65056($v0)
    sw $t0 65060($v0)
    sw $t5 65064($v0)
    sw $t7 65068($v0)
    sw $t1 65072($v0)
    sw $t2 65076($v0)
    sw $t6 65080($v0)
    sw $t6 65084($v0)
    sw $t7 65088($v0)
    sw $t5 65092($v0)
    sw $t3 65096($v0)
    sw $t4 65100($v0)
    sw $t2 65104($v0)
    sw $t6 65108($v0)
    sw $t2 65112($v0)
    sw $t4 65116($v0)
    sw $t1 65120($v0)
    sw $t4 65124($v0)
    sw $t5 65128($v0)
    sw $t8 65132($v0)
    sw $t5 65136($v0)
    sw $t8 65140($v0)
    sw $t6 65144($v0)
    sw $t2 65148($v0)
    sw $t5 63888($v0)
    sw $t8 63892($v0)
    sw $t2 63896($v0)
    sw $t5 63900($v0)
    sw $t0 63904($v0)
    sw $t0 63908($v0)
    sw $t0 63912($v0)
    sw $t7 63916($v0)
    sw $t7 63920($v0)
    sw $t8 63924($v0)
    sw $t8 63928($v0)
    sw $t1 63932($v0)
    sw $t0 63936($v0)
    sw $t8 63940($v0)
    sw $t6 63944($v0)
    sw $t0 63948($v0)
    sw $t7 63952($v0)
    sw $t2 63956($v0)
    sw $t2 63960($v0)
    sw $t0 63964($v0)
    sw $t2 63968($v0)
    sw $t8 63972($v0)
    sw $t1 63976($v0)
    sw $t3 63980($v0)
    sw $t5 63984($v0)
    sw $t7 63988($v0)
    sw $t5 63992($v0)
    sw $t8 63996($v0)
    sw $t4 64400($v0)
    sw $t6 64404($v0)
    sw $t4 64408($v0)
    sw $t7 64412($v0)
    sw $t5 64416($v0)
    sw $t0 64420($v0)
    sw $t6 64424($v0)
    sw $t3 64428($v0)
    sw $t5 64432($v0)
    sw $t3 64436($v0)
    sw $t0 64440($v0)
    sw $t3 64444($v0)
    sw $t0 64448($v0)
    sw $t3 64452($v0)
    sw $t2 64456($v0)
    sw $t5 64460($v0)
    sw $t6 64464($v0)
    sw $t3 64468($v0)
    sw $t5 64472($v0)
    sw $t2 64476($v0)
    sw $t0 64480($v0)
    sw $t2 64484($v0)
    sw $t4 64488($v0)
    sw $t7 64492($v0)
    sw $t4 64496($v0)
    sw $t8 64500($v0)
    sw $t6 64504($v0)
    sw $t4 64508($v0)
    sw $t1 64912($v0)
    sw $t2 64916($v0)
    sw $t2 64920($v0)
    sw $t4 64924($v0)
    sw $t2 64928($v0)
    sw $t3 64932($v0)
    sw $t6 64936($v0)
    sw $t8 64940($v0)
    sw $t8 64944($v0)
    sw $t5 64948($v0)
    sw $t4 64952($v0)
    sw $t8 64956($v0)
    sw $t0 64960($v0)
    sw $t0 64964($v0)
    sw $t5 64968($v0)
    sw $t3 64972($v0)
    sw $t8 64976($v0)
    sw $t2 64980($v0)
    sw $t5 64984($v0)
    sw $t3 64988($v0)
    sw $t3 64992($v0)
    sw $t2 64996($v0)
    sw $t6 65000($v0)
    sw $t6 65004($v0)
    sw $t5 65008($v0)
    sw $t3 65012($v0)
    sw $t2 65016($v0)
    sw $t3 65020($v0)
    sw $t1 65424($v0)
    sw $t2 65428($v0)
    sw $t0 65432($v0)
    sw $t3 65436($v0)
    sw $t7 65440($v0)
    sw $t8 65444($v0)
    sw $t6 65448($v0)
    sw $t6 65452($v0)
    sw $t7 65456($v0)
    sw $t3 65460($v0)
    sw $t5 65464($v0)
    sw $t1 65468($v0)
    sw $t4 65472($v0)
    sw $t4 65476($v0)
    sw $t1 65480($v0)
    sw $t6 65484($v0)
    sw $t0 65488($v0)
    sw $t5 65492($v0)
    sw $t0 65496($v0)
    sw $t4 65500($v0)
    sw $t8 65504($v0)
    sw $t0 65508($v0)
    sw $t0 65512($v0)
    sw $t0 65516($v0)
    sw $t5 65520($v0)
    sw $t1 65524($v0)
    sw $t0 65528($v0)
    sw $t4 65532($v0)
    beq $t9 0 draw_stage_end # end of stage 0
    sw $t3 0($v0)
    sw $t6 4($v0)
    sw $t2 8($v0)
    sw $t0 12($v0)
    sw $t1 16($v0)
    sw $t0 20($v0)
    sw $t8 24($v0)
    sw $t7 28($v0)
    sw $t2 32($v0)
    sw $t3 36($v0)
    sw $t1 40($v0)
    sw $t6 44($v0)
    sw $t4 48($v0)
    sw $t2 52($v0)
    sw $t5 56($v0)
    sw $t0 60($v0)
    sw $t4 64($v0)
    sw $t6 68($v0)
    sw $t5 72($v0)
    sw $t5 76($v0)
    sw $t6 80($v0)
    sw $t1 84($v0)
    sw $t6 88($v0)
    sw $t8 92($v0)
    sw $t1 96($v0)
    sw $t8 100($v0)
    sw $t1 104($v0)
    sw $t0 108($v0)
    sw $t3 112($v0)
    sw $t8 116($v0)
    sw $t2 120($v0)
    sw $t5 124($v0)
    sw $t4 128($v0)
    sw $t1 132($v0)
    sw $t0 136($v0)
    sw $t1 140($v0)
    sw $t0 144($v0)
    sw $t2 148($v0)
    sw $t6 152($v0)
    sw $t4 156($v0)
    sw $t7 160($v0)
    sw $t3 164($v0)
    sw $t4 168($v0)
    sw $t8 172($v0)
    sw $t5 512($v0)
    sw $t4 516($v0)
    sw $t0 520($v0)
    sw $t7 524($v0)
    sw $t8 528($v0)
    sw $t4 532($v0)
    sw $t1 536($v0)
    sw $t3 540($v0)
    sw $t0 544($v0)
    sw $t8 548($v0)
    sw $t8 552($v0)
    sw $t6 556($v0)
    sw $t6 560($v0)
    sw $t4 564($v0)
    sw $t8 568($v0)
    sw $t0 572($v0)
    sw $t6 576($v0)
    sw $t7 580($v0)
    sw $t5 584($v0)
    sw $t5 588($v0)
    sw $t0 592($v0)
    sw $t1 596($v0)
    sw $t2 600($v0)
    sw $t3 604($v0)
    sw $t8 608($v0)
    sw $t3 612($v0)
    sw $t6 616($v0)
    sw $t4 620($v0)
    sw $t0 624($v0)
    sw $t2 628($v0)
    sw $t2 632($v0)
    sw $t1 636($v0)
    sw $t5 640($v0)
    sw $t6 644($v0)
    sw $t6 648($v0)
    sw $t3 652($v0)
    sw $t5 656($v0)
    sw $t4 660($v0)
    sw $t5 664($v0)
    sw $t8 668($v0)
    sw $t7 672($v0)
    sw $t7 676($v0)
    sw $t3 680($v0)
    sw $t2 684($v0)
    sw $t3 1024($v0)
    sw $t1 1028($v0)
    sw $t6 1032($v0)
    sw $t8 1036($v0)
    sw $t5 1040($v0)
    sw $t7 1044($v0)
    sw $t1 1048($v0)
    sw $t4 1052($v0)
    sw $t6 1056($v0)
    sw $t2 1060($v0)
    sw $t2 1064($v0)
    sw $t0 1068($v0)
    sw $t1 1072($v0)
    sw $t6 1076($v0)
    sw $t5 1080($v0)
    sw $t7 1084($v0)
    sw $t4 1088($v0)
    sw $t8 1092($v0)
    sw $t8 1096($v0)
    sw $t6 1100($v0)
    sw $t5 1104($v0)
    sw $t1 1108($v0)
    sw $t7 1112($v0)
    sw $t6 1116($v0)
    sw $t6 1120($v0)
    sw $t2 1124($v0)
    sw $t1 1128($v0)
    sw $t0 1132($v0)
    sw $t0 1136($v0)
    sw $t7 1140($v0)
    sw $t4 1144($v0)
    sw $t5 1148($v0)
    sw $t4 1152($v0)
    sw $t4 1156($v0)
    sw $t4 1160($v0)
    sw $t4 1164($v0)
    sw $t8 1168($v0)
    sw $t5 1172($v0)
    sw $t3 1176($v0)
    sw $t4 1180($v0)
    sw $t4 1184($v0)
    sw $t6 1188($v0)
    sw $t5 1192($v0)
    sw $t5 1196($v0)
    sw $t6 1536($v0)
    sw $t0 1540($v0)
    sw $t4 1544($v0)
    sw $t7 1548($v0)
    sw $t4 1552($v0)
    sw $t2 1556($v0)
    sw $t1 1560($v0)
    sw $t2 1564($v0)
    sw $t6 1568($v0)
    sw $t1 1572($v0)
    sw $t1 1576($v0)
    sw $t4 1580($v0)
    sw $t2 1584($v0)
    sw $t5 1588($v0)
    sw $t0 1592($v0)
    sw $t4 1596($v0)
    sw $t7 1600($v0)
    sw $t1 1604($v0)
    sw $t1 1608($v0)
    sw $t6 1612($v0)
    sw $t6 1616($v0)
    sw $t0 1620($v0)
    sw $t4 1624($v0)
    sw $t4 1628($v0)
    sw $t8 1632($v0)
    sw $t2 1636($v0)
    sw $t1 1640($v0)
    sw $t7 1644($v0)
    sw $t8 1648($v0)
    sw $t6 1652($v0)
    sw $t2 1656($v0)
    sw $t1 1660($v0)
    sw $t0 1664($v0)
    sw $t7 1668($v0)
    sw $t0 1672($v0)
    sw $t2 1676($v0)
    sw $t7 1680($v0)
    sw $t4 1684($v0)
    sw $t2 1688($v0)
    sw $t0 1692($v0)
    sw $t7 1696($v0)
    sw $t0 1700($v0)
    sw $t7 1704($v0)
    sw $t7 1708($v0)
    sw $t5 22544($v0)
    sw $t2 22548($v0)
    sw $t2 22552($v0)
    sw $t6 22556($v0)
    sw $t4 23056($v0)
    sw $t2 23060($v0)
    sw $t8 23064($v0)
    sw $t6 23068($v0)
    sw $t6 23568($v0)
    sw $t5 23572($v0)
    sw $t1 23576($v0)
    sw $t4 23580($v0)
    sw $t6 24080($v0)
    sw $t1 24084($v0)
    sw $t7 24088($v0)
    sw $t5 24092($v0)
    sw $t7 24592($v0)
    sw $t8 24596($v0)
    sw $t0 24600($v0)
    sw $t8 24604($v0)
    sw $t1 25104($v0)
    sw $t5 25108($v0)
    sw $t7 25112($v0)
    sw $t3 25116($v0)
    sw $t7 25616($v0)
    sw $t7 25620($v0)
    sw $t6 25624($v0)
    sw $t1 25628($v0)
    sw $t2 26128($v0)
    sw $t6 26132($v0)
    sw $t3 26136($v0)
    sw $t0 26140($v0)
    sw $t5 26640($v0)
    sw $t7 26644($v0)
    sw $t2 26648($v0)
    sw $t3 26652($v0)
    sw $t5 27152($v0)
    sw $t3 27156($v0)
    sw $t0 27160($v0)
    sw $t7 27164($v0)
    sw $t7 27664($v0)
    sw $t0 27668($v0)
    sw $t0 27672($v0)
    sw $t0 27676($v0)
    sw $t3 28176($v0)
    sw $t2 28180($v0)
    sw $t7 28184($v0)
    sw $t5 28188($v0)
    sw $t7 28688($v0)
    sw $t1 28692($v0)
    sw $t3 28696($v0)
    sw $t2 28700($v0)
    sw $t2 29200($v0)
    sw $t1 29204($v0)
    sw $t6 29208($v0)
    sw $t7 29212($v0)
    sw $t2 29712($v0)
    sw $t3 29716($v0)
    sw $t3 29720($v0)
    sw $t4 29724($v0)
    sw $t2 30224($v0)
    sw $t6 30228($v0)
    sw $t8 30232($v0)
    sw $t2 30236($v0)
    beq $t9 4 draw_stage_end # end of stage 1
    sw $t0 4112($v0)
    sw $t4 4116($v0)
    sw $t2 4120($v0)
    sw $t5 4124($v0)
    sw $t4 4624($v0)
    sw $t5 4628($v0)
    sw $t6 4632($v0)
    sw $t5 4636($v0)
    sw $t0 5136($v0)
    sw $t2 5140($v0)
    sw $t2 5144($v0)
    sw $t3 5148($v0)
    sw $t5 5648($v0)
    sw $t7 5652($v0)
    sw $t3 5656($v0)
    sw $t3 5660($v0)
    sw $t2 6160($v0)
    sw $t6 6164($v0)
    sw $t7 6168($v0)
    sw $t3 6172($v0)
    sw $t1 6672($v0)
    sw $t6 6676($v0)
    sw $t2 6680($v0)
    sw $t7 6684($v0)
    sw $t6 7184($v0)
    sw $t4 7188($v0)
    sw $t1 7192($v0)
    sw $t1 7196($v0)
    sw $t4 7696($v0)
    sw $t8 7700($v0)
    sw $t6 7704($v0)
    sw $t7 7708($v0)
    sw $t4 8208($v0)
    sw $t5 8212($v0)
    sw $t1 8216($v0)
    sw $t4 8220($v0)
    sw $t5 8720($v0)
    sw $t2 8724($v0)
    sw $t3 8728($v0)
    sw $t4 8732($v0)
    sw $t5 9232($v0)
    sw $t7 9236($v0)
    sw $t1 9240($v0)
    sw $t5 9244($v0)
    sw $t4 9744($v0)
    sw $t5 9748($v0)
    sw $t7 9752($v0)
    sw $t8 9756($v0)
    sw $t1 55296($v0)
    sw $t7 55300($v0)
    sw $t2 55304($v0)
    sw $t1 55308($v0)
    sw $t2 55808($v0)
    sw $t2 55812($v0)
    sw $t4 55816($v0)
    sw $t8 55820($v0)
    sw $t5 56320($v0)
    sw $t7 56324($v0)
    sw $t8 56328($v0)
    sw $t7 56332($v0)
    sw $t6 56832($v0)
    sw $t2 56836($v0)
    sw $t1 56840($v0)
    sw $t5 56844($v0)
    sw $t8 57344($v0)
    sw $t2 57348($v0)
    sw $t3 57352($v0)
    sw $t0 57356($v0)
    sw $t6 57856($v0)
    sw $t7 57860($v0)
    sw $t7 57864($v0)
    sw $t1 57868($v0)
    sw $t3 58368($v0)
    sw $t7 58372($v0)
    sw $t0 58376($v0)
    sw $t3 58380($v0)
    sw $t7 58880($v0)
    sw $t1 58884($v0)
    sw $t0 58888($v0)
    sw $t1 58892($v0)
    sw $t4 59392($v0)
    sw $t3 59396($v0)
    sw $t8 59400($v0)
    sw $t2 59404($v0)
    sw $t0 59904($v0)
    sw $t3 59908($v0)
    sw $t0 59912($v0)
    sw $t5 59916($v0)
    sw $t2 60416($v0)
    sw $t1 60420($v0)
    sw $t4 60424($v0)
    sw $t7 60428($v0)
    sw $t0 60928($v0)
    sw $t4 60932($v0)
    sw $t1 60936($v0)
    sw $t1 60940($v0)
    sw $t3 61440($v0)
    sw $t0 61444($v0)
    sw $t8 61448($v0)
    sw $t0 61452($v0)
    sw $t2 61952($v0)
    sw $t7 61956($v0)
    sw $t2 61960($v0)
    sw $t0 61964($v0)
    sw $t8 62464($v0)
    sw $t5 62468($v0)
    sw $t8 62472($v0)
    sw $t2 62476($v0)
    sw $t6 62976($v0)
    sw $t0 62980($v0)
    sw $t5 62984($v0)
    sw $t0 62988($v0)
    sw $t0 53472($v0)
    sw $t6 53476($v0)
    sw $t2 53480($v0)
    sw $t5 53484($v0)
    sw $t8 53984($v0)
    sw $t8 53988($v0)
    sw $t4 53992($v0)
    sw $t6 53996($v0)
    sw $t0 54496($v0)
    sw $t0 54500($v0)
    sw $t3 54504($v0)
    sw $t7 54508($v0)
    sw $t2 55008($v0)
    sw $t4 55012($v0)
    sw $t2 55016($v0)
    sw $t3 55020($v0)
    sw $t5 55520($v0)
    sw $t1 55524($v0)
    sw $t3 55528($v0)
    sw $t8 55532($v0)
    sw $t8 56032($v0)
    sw $t1 56036($v0)
    sw $t6 56040($v0)
    sw $t5 56044($v0)
    sw $t6 56544($v0)
    sw $t0 56548($v0)
    sw $t5 56552($v0)
    sw $t0 56556($v0)
    sw $t6 57056($v0)
    sw $t5 57060($v0)
    sw $t7 57064($v0)
    sw $t7 57068($v0)
    beq $t9 8 draw_stage_end # end of stage 2
    sw $t3 14544($v0)
    sw $t7 14548($v0)
    sw $t8 14552($v0)
    sw $t6 14556($v0)
    sw $t6 15056($v0)
    sw $t4 15060($v0)
    sw $t7 15064($v0)
    sw $t8 15068($v0)
    sw $t4 15568($v0)
    sw $t1 15572($v0)
    sw $t4 15576($v0)
    sw $t1 15580($v0)
    sw $t6 16080($v0)
    sw $t8 16084($v0)
    sw $t5 16088($v0)
    sw $t5 16092($v0)
    sw $t3 16592($v0)
    sw $t7 16596($v0)
    sw $t7 16600($v0)
    sw $t4 16604($v0)
    sw $t1 17104($v0)
    sw $t4 17108($v0)
    sw $t4 17112($v0)
    sw $t4 17116($v0)
    sw $t0 17616($v0)
    sw $t3 17620($v0)
    sw $t0 17624($v0)
    sw $t0 17628($v0)
    sw $t8 18128($v0)
    sw $t2 18132($v0)
    sw $t8 18136($v0)
    sw $t8 18140($v0)
    sw $t0 18640($v0)
    sw $t6 18644($v0)
    sw $t4 18648($v0)
    sw $t0 18652($v0)
    sw $t7 19152($v0)
    sw $t1 19156($v0)
    sw $t7 19160($v0)
    sw $t1 19164($v0)
    sw $t7 19664($v0)
    sw $t1 19668($v0)
    sw $t8 19672($v0)
    sw $t5 19676($v0)
    sw $t1 20176($v0)
    sw $t2 20180($v0)
    sw $t6 20184($v0)
    sw $t0 20188($v0)
    sw $t1 20688($v0)
    sw $t4 20692($v0)
    sw $t8 20696($v0)
    sw $t0 20700($v0)
    sw $t6 21200($v0)
    sw $t7 21204($v0)
    sw $t6 21208($v0)
    sw $t3 21212($v0)
    sw $t3 21712($v0)
    sw $t1 21716($v0)
    sw $t7 21720($v0)
    sw $t4 21724($v0)
    sw $t2 22224($v0)
    sw $t7 22228($v0)
    sw $t3 22232($v0)
    sw $t5 22236($v0)
    sw $t0 22736($v0)
    sw $t6 22740($v0)
    sw $t7 22744($v0)
    sw $t7 22748($v0)
    sw $t8 23248($v0)
    sw $t2 23252($v0)
    sw $t1 23256($v0)
    sw $t1 23260($v0)
    sw $t3 23760($v0)
    sw $t1 23764($v0)
    sw $t4 23768($v0)
    sw $t1 23772($v0)
    sw $t2 24272($v0)
    sw $t0 24276($v0)
    sw $t2 24280($v0)
    sw $t6 24284($v0)
    sw $t7 24784($v0)
    sw $t1 24788($v0)
    sw $t2 24792($v0)
    sw $t6 24796($v0)
    sw $t4 25296($v0)
    sw $t2 25300($v0)
    sw $t2 25304($v0)
    sw $t5 25308($v0)
    sw $t0 25808($v0)
    sw $t1 25812($v0)
    sw $t0 25816($v0)
    sw $t2 25820($v0)
    sw $t0 26320($v0)
    sw $t0 26324($v0)
    sw $t8 26328($v0)
    sw $t5 26332($v0)
    sw $t2 26832($v0)
    sw $t8 26836($v0)
    sw $t8 26840($v0)
    sw $t2 26844($v0)
    sw $t4 27344($v0)
    sw $t8 27348($v0)
    sw $t1 27352($v0)
    sw $t7 27356($v0)
    sw $t5 27856($v0)
    sw $t3 27860($v0)
    sw $t5 27864($v0)
    sw $t3 27868($v0)
    sw $t1 28368($v0)
    sw $t1 28372($v0)
    sw $t1 28376($v0)
    sw $t3 28380($v0)
    sw $t1 28880($v0)
    sw $t6 28884($v0)
    sw $t3 28888($v0)
    sw $t6 28892($v0)
    sw $t4 29392($v0)
    sw $t1 29396($v0)
    sw $t1 29400($v0)
    sw $t3 29404($v0)
    sw $t4 29904($v0)
    sw $t3 29908($v0)
    sw $t8 29912($v0)
    sw $t2 29916($v0)
    sw $t5 30416($v0)
    sw $t6 30420($v0)
    sw $t1 30424($v0)
    sw $t3 30428($v0)
    sw $t2 30928($v0)
    sw $t0 30932($v0)
    sw $t3 30936($v0)
    sw $t1 30940($v0)
    sw $t1 31440($v0)
    sw $t4 31444($v0)
    sw $t0 31448($v0)
    sw $t2 31452($v0)
    sw $t7 31952($v0)
    sw $t2 31956($v0)
    sw $t6 31960($v0)
    sw $t5 31964($v0)
    sw $t8 32464($v0)
    sw $t0 32468($v0)
    sw $t7 32472($v0)
    sw $t1 32476($v0)
    sw $t0 32976($v0)
    sw $t6 32980($v0)
    sw $t3 32984($v0)
    sw $t2 32988($v0)
    sw $t7 33488($v0)
    sw $t2 33492($v0)
    sw $t4 33496($v0)
    sw $t1 33500($v0)
    sw $t0 34000($v0)
    sw $t5 34004($v0)
    sw $t2 34008($v0)
    sw $t7 34012($v0)
    sw $t0 34512($v0)
    sw $t6 34516($v0)
    sw $t2 34520($v0)
    sw $t1 34524($v0)
    sw $t0 35024($v0)
    sw $t5 35028($v0)
    sw $t4 35032($v0)
    sw $t4 35036($v0)
    sw $t1 35536($v0)
    sw $t5 35540($v0)
    sw $t0 35544($v0)
    sw $t4 35548($v0)
    sw $t0 36048($v0)
    sw $t6 36052($v0)
    sw $t2 36056($v0)
    sw $t8 36060($v0)
    sw $t7 36560($v0)
    sw $t6 36564($v0)
    sw $t7 36568($v0)
    sw $t5 36572($v0)
    sw $t3 37072($v0)
    sw $t8 37076($v0)
    sw $t3 37080($v0)
    sw $t0 37084($v0)
    sw $t0 37584($v0)
    sw $t4 37588($v0)
    sw $t4 37592($v0)
    sw $t7 37596($v0)
    sw $t2 38096($v0)
    sw $t8 38100($v0)
    sw $t6 38104($v0)
    sw $t7 38108($v0)
    sw $t4 38608($v0)
    sw $t4 38612($v0)
    sw $t4 38616($v0)
    sw $t3 38620($v0)
    sw $t0 39120($v0)
    sw $t6 39124($v0)
    sw $t1 39128($v0)
    sw $t8 39132($v0)
    sw $t0 39632($v0)
    sw $t6 39636($v0)
    sw $t8 39640($v0)
    sw $t3 39644($v0)
    sw $t7 40144($v0)
    sw $t6 40148($v0)
    sw $t7 40152($v0)
    sw $t3 40156($v0)
    sw $t4 40656($v0)
    sw $t3 40660($v0)
    sw $t6 40664($v0)
    sw $t1 40668($v0)

    draw_stage_end:
    jr $ra # return

draw_doll_0: # start at v0, use t4
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
clear_doll: # start at v0, use t4
    sw BACKGROUND 0($v0)
    sw BACKGROUND 4($v0)
    sw BACKGROUND 8($v0)
    sw BACKGROUND 12($v0)
    sw BACKGROUND 16($v0)
    sw BACKGROUND 20($v0)
    sw BACKGROUND 24($v0)
    sw BACKGROUND 28($v0)
    sw BACKGROUND 32($v0)
    sw BACKGROUND 36($v0)
    sw BACKGROUND 512($v0)
    sw BACKGROUND 516($v0)
    sw BACKGROUND 520($v0)
    sw BACKGROUND 524($v0)
    sw BACKGROUND 528($v0)
    sw BACKGROUND 532($v0)
    sw BACKGROUND 536($v0)
    sw BACKGROUND 540($v0)
    sw BACKGROUND 544($v0)
    sw BACKGROUND 548($v0)
    sw BACKGROUND 1024($v0)
    sw BACKGROUND 1028($v0)
    sw BACKGROUND 1032($v0)
    sw BACKGROUND 1036($v0)
    sw BACKGROUND 1040($v0)
    sw BACKGROUND 1044($v0)
    sw BACKGROUND 1048($v0)
    sw BACKGROUND 1052($v0)
    sw BACKGROUND 1056($v0)
    sw BACKGROUND 1060($v0)
    sw BACKGROUND 1536($v0)
    sw BACKGROUND 1540($v0)
    sw BACKGROUND 1544($v0)
    sw BACKGROUND 1548($v0)
    sw BACKGROUND 1552($v0)
    sw BACKGROUND 1556($v0)
    sw BACKGROUND 1560($v0)
    sw BACKGROUND 1564($v0)
    sw BACKGROUND 1568($v0)
    sw BACKGROUND 1572($v0)
    sw BACKGROUND 2048($v0)
    sw BACKGROUND 2052($v0)
    sw BACKGROUND 2056($v0)
    sw BACKGROUND 2060($v0)
    sw BACKGROUND 2064($v0)
    sw BACKGROUND 2068($v0)
    sw BACKGROUND 2072($v0)
    sw BACKGROUND 2076($v0)
    sw BACKGROUND 2080($v0)
    sw BACKGROUND 2084($v0)
    sw BACKGROUND 2560($v0)
    sw BACKGROUND 2564($v0)
    sw BACKGROUND 2568($v0)
    sw BACKGROUND 2572($v0)
    sw BACKGROUND 2576($v0)
    sw BACKGROUND 2580($v0)
    sw BACKGROUND 2584($v0)
    sw BACKGROUND 2588($v0)
    sw BACKGROUND 2592($v0)
    sw BACKGROUND 2596($v0)
    sw BACKGROUND 3072($v0)
    sw BACKGROUND 3076($v0)
    sw BACKGROUND 3080($v0)
    sw BACKGROUND 3084($v0)
    sw BACKGROUND 3088($v0)
    sw BACKGROUND 3092($v0)
    sw BACKGROUND 3096($v0)
    sw BACKGROUND 3100($v0)
    sw BACKGROUND 3104($v0)
    sw BACKGROUND 3108($v0)
    sw BACKGROUND 3584($v0)
    sw BACKGROUND 3588($v0)
    sw BACKGROUND 3592($v0)
    sw BACKGROUND 3596($v0)
    sw BACKGROUND 3600($v0)
    sw BACKGROUND 3604($v0)
    sw BACKGROUND 3608($v0)
    sw BACKGROUND 3612($v0)
    sw BACKGROUND 3616($v0)
    sw BACKGROUND 3620($v0)
    sw BACKGROUND 4096($v0)
    sw BACKGROUND 4100($v0)
    sw BACKGROUND 4104($v0)
    sw BACKGROUND 4108($v0)
    sw BACKGROUND 4112($v0)
    sw BACKGROUND 4116($v0)
    sw BACKGROUND 4120($v0)
    sw BACKGROUND 4124($v0)
    sw BACKGROUND 4128($v0)
    sw BACKGROUND 4132($v0)
    sw BACKGROUND 4608($v0)
    sw BACKGROUND 4612($v0)
    sw BACKGROUND 4616($v0)
    sw BACKGROUND 4620($v0)
    sw BACKGROUND 4624($v0)
    sw BACKGROUND 4628($v0)
    sw BACKGROUND 4632($v0)
    sw BACKGROUND 4636($v0)
    sw BACKGROUND 4640($v0)
    sw BACKGROUND 4644($v0)
    sw BACKGROUND 5120($v0)
    sw BACKGROUND 5124($v0)
    sw BACKGROUND 5128($v0)
    sw BACKGROUND 5132($v0)
    sw BACKGROUND 5136($v0)
    sw BACKGROUND 5140($v0)
    sw BACKGROUND 5144($v0)
    sw BACKGROUND 5148($v0)
    sw BACKGROUND 5152($v0)
    sw BACKGROUND 5156($v0)
    sw BACKGROUND 5632($v0)
    sw BACKGROUND 5636($v0)
    sw BACKGROUND 5640($v0)
    sw BACKGROUND 5644($v0)
    sw BACKGROUND 5648($v0)
    sw BACKGROUND 5652($v0)
    sw BACKGROUND 5656($v0)
    sw BACKGROUND 5660($v0)
    sw BACKGROUND 5664($v0)
    sw BACKGROUND 5668($v0)
    jr $ra
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
draw_player: # start at v0 with (Δx, Δy) in (a0, a1), previous position in a2
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