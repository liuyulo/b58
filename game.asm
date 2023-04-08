# pregame
#   s0 start of music
#   s1 end of music
#   s2 instrument
#   s3 volume
#   s4 address to current note
#   s6 note duration remaining (ms)
#   s7 time
# ingame
#   s0 player x in bytes
#   s1 player y in bytes
#   s2 gravity x
#   s3 gravity y
#   s4 orientation (positive or negative)
#   s5 flag: door_unlocked double_jump landed
#   s6 jump distance remaining
#   s7 time
# postgame
#   s0 constant 0 (to differentiate with pregame)
#   s2 instrument
#   s3 max volume
#   s5 constant 5
#   s7 time
# .eqv
    .eqv BASE_ADDRESS   0x10008000  # ($gp)
    .eqv SIZE           512         # screen width & height in bytes
    .eqv WIDTH_SHIFT    7           # 4 << WIDTH_SHIFT == SIZE

    .eqv PRE_RATE       56          # 132 bpm, each frame is 1/32 note
    .eqv PRE_LEN        1728        # wonderland has 216 notes, each is 2 words
    .eqv PRE_FRAME      32          # frames to draw pre ui
    .eqv PRE_S          29456       # location of S key (start) in pregame
    .eqv PRE_Q          40720       # quit key
    .eqv REFRESH_RATE   40          # in miliseconds

    .eqv POST_RATE      50          # 120 bpm, 5 frames is a 1/8 note
    .eqv POST_FRAME     32          # frames to draw post ui
    .eqv POST_P         17008       # location of P key (reset) in postgame
    .eqv POST_S         28272       # restart key
    .eqv POST_Q         39536       # quit key

    .eqv CLEAR_FRAME    172         # 4 * num of frames for clear
# .eqv for gameplay
    .eqv PLAYER_SIZE    64          # in bytes
    .eqv PLAYER_END     60           # PLAYER_SIZE - 4 bytes
    .eqv PLAYER_INIT    32          # initial position
    .eqv JUMP_HEIGHT    96          # in bytes
    .eqv STAGE_COUNT    20           # size of platforms_end
    .eqv DOLLS_FRAME    88           # 4*number of frames for doll animation
    .eqv ALICE_FRAME    24          # 4 * number of frames for alice animation
.data
    # space padding to support 128x128 resolution
    pad: .space 36000
    # random integers go brrrr
    wonderland: .word
        72 56 74 616 72 1120 65 56 67 280 65 336 67 224 60 336 62 336 63 224 72 56 74 616 75 224 72 1792 74 336 75 336 77 224 74 56 77 616 75 1120 77 56 79 280 77 336 79 224 72 336 74 336 75 224 75 56 77 616 79 224 75 1792 62 336 63 336 65 224 72 56 74 616 72 1120 65 56 67 280 65 336 67 224 60 336 62 336 63 224 72 56 74 616 75 224 72 1792 74 336 75 336 77 224 74 56 77 616 75 1120 77 56 79 280 77 336 79 224 72 336 74 336 75 224 75 56 77 616 79 224 75 1792
        0 448 62 112 63 112 65 224 67 896 60 336 63 336 67 224 72 896 60 336 63 336 70 56 72 168 70 896 65 336 62 336 70 224 67 56 68 616 67 112 65 112 67 896 67 336 65 336 64 224 65 448 72 448 65 336 63 336 62 224 63 448 70 56 72 392 71 336 72 336 74 224 67 896 71 896
        62 336 63 336 65 224 67 896 60 336 63 336 67 224 72 896 60 336 63 336 70 56 72 168 70 896 65 336 62 336 70 224 67 56 68 616 67 112 65 112 67 896 67 336 65 336 64 224 65 448 72 448 65 336 63 336 62 224 63 448 70 56 72 392 71 336 72 336 74 224 67 896 71 896
        74 336 75 336 77 224 79 896 72 336 75 336 79 224 84 896 72 336 75 336 82 56 84 168 82 896 77 336 74 336 82 224 79 56 80 616 79 112 77 112 79 896 79 336 77 336 76 224 77 448 84 448 77 336 75 336 74 224 75 448 82 56 84 392 83 336 84 336 86 224 79 896 83 896
        74 336 75 336 77 224 79 896 72 336 75 336 79 224 84 896 72 336 75 336 82 56 84 168 82 896 77 336 74 336 82 224 79 56 80 616 79 112 77 112 79 896 79 336 77 336 76 224 77 448 84 448 77 336 75 336 74 224 75 448 82 56 84 392 83 336 84 336 86 224 79 336 89 336 86 224 87 1792    # each word is 8 frames
    pregame_frames: .word draw_title draw_subtitle draw_pre_start draw_pre_quit
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
    # each word is 8 frames
    postgame_frames: .word draw_game_clear draw_post_return draw_post_restart draw_post_quit
    # each word is 1 frame
    postgame_doll: .word draw_post_doll_00 draw_post_doll_01
        draw_post_doll_02 draw_post_doll_03 draw_post_doll_04 draw_post_doll_05
        draw_post_doll_06 draw_post_doll_07 draw_post_doll_08 draw_post_doll_09
        draw_post_doll_10 draw_post_doll_11 draw_post_doll_12 draw_post_doll_13
        draw_post_doll_14 draw_post_doll_15 draw_post_doll_16 draw_post_doll_17
        draw_post_doll_18 draw_post_doll_19 draw_post_doll_20 draw_post_doll_21
    clears: draw_clear_00 draw_clear_01 draw_clear_02 draw_clear_03 draw_clear_04 draw_clear_05 draw_clear_06 draw_clear_07
        draw_clear_08 draw_clear_09 draw_clear_10 draw_clear_11 draw_clear_12 draw_clear_13 draw_clear_14
        draw_clear_15 draw_clear_16 draw_clear_17 draw_clear_18 draw_clear_19 draw_clear_20 draw_clear_21
        draw_clear_22 draw_clear_23 draw_clear_24 draw_clear_25 draw_clear_26 draw_clear_27 draw_clear_28
        draw_clear_29 draw_clear_30 draw_clear_31 draw_clear_32 draw_clear_33 draw_clear_34 draw_clear_35
        draw_clear_36 draw_clear_37 draw_clear_38 draw_clear_39 draw_clear_40 draw_clear_41 draw_clear_42
    score: .word 70 82 65 77 63 75 61 73 58 70 61 73 63 75 65 77 # 16 pitches

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
    .macro frame(%n) # a2 = address to frames
        andi $t4 $t4 0xfffc
        rem $t4 $t4 %n
        add $v0 $a2 $t4
        lw $v0 0($v0)
    .end_macro
    .macro frame2(%n)  # rd = animation 2 frames per animation, rt = address of frames
        sll $t4 $s7 1
        frame(%n)
    .end_macro
    .macro frame4(%n) # jalr $v0 for 4 frames per animation
        move $t4 $s7
        frame(%n)
    .end_macro
    .macro check_keypress() # break if key not pressed, othewise v0 is key
        li $v0 0xffff0000
        lw $t0 0($v0)
        beqz $t0 jrra # break
        lw $v0 4($v0)
    .end_macro

    .macro setup_color(%rs)  # set up colors for UI in t0-t9
        # this creates transitions, idk how to explain
        andi $t1 %rs 0x7 # mod 8
        li $t2 0x5e4e1f
        li $t3 0x756127
        slti $t0 $t1 1
        movn $t3 $t2 $t0

        li $t4 0x8b742e
        slti $t0 $t1 2
        movn $t4 $t3 $t0

        li $t5 0xa98c38
        slti $t0 $t1 3
        movn $t5 $t4 $t0

        li $t6 0xba9b3e
        slti $t0 $t1 4
        movn $t6 $t5 $t0

        li $t7 0xd0ad45
        slti $t0 $t1 5
        movn $t7 $t6 $t0

        li $t8 0xe6c04c
        slti $t0 $t1 6
        movn $t8 $t7 $t0

        li $t9 0xfad053
        slti $t0 $t1 7
        movn $t9 $t8 $t0

        li $t0 0x2d260f
        li $t1 0x453917
    .end_macro
# .macros to reduce line number
    .macro draw4(%rs, %i0, %i1, %i2, %i3)
        sw %rs %i0($v1)
        sw %rs %i1($v1)
        sw %rs %i2($v1)
        sw %rs %i3($v1)
    .end_macro
    .macro draw16(%rs, %i0, %i1, %i2, %i3, %i4, %i5, %i6, %i7, %i8, %i9, %i10, %i11, %i12, %i13, %i14, %i15)
        draw4(%rs, %i0, %i1, %i2, %i3)
        draw4(%rs, %i4, %i5, %i6, %i7)
        draw4(%rs, %i8, %i9, %i10, %i11)
        draw4(%rs, %i12, %i13, %i14, %i15)
    .end_macro
    .macro draw64(%rs, %i0, %i1, %i2, %i3, %i4, %i5, %i6, %i7, %i8, %i9, %i10, %i11, %i12, %i13, %i14, %i15, %i16, %i17, %i18, %i19, %i20, %i21, %i22, %i23, %i24, %i25, %i26, %i27, %i28, %i29, %i30, %i31, %i32, %i33, %i34, %i35, %i36, %i37, %i38, %i39, %i40, %i41, %i42, %i43, %i44, %i45, %i46, %i47, %i48, %i49, %i50, %i51, %i52, %i53, %i54, %i55, %i56, %i57, %i58, %i59, %i60, %i61, %i62, %i63)
        draw16(%rs, %i0, %i1, %i2, %i3, %i4, %i5, %i6, %i7, %i8, %i9, %i10, %i11, %i12, %i13, %i14, %i15)
        draw16(%rs, %i16, %i17, %i18, %i19, %i20, %i21, %i22, %i23, %i24, %i25, %i26, %i27, %i28, %i29, %i30, %i31)
        draw16(%rs, %i32, %i33, %i34, %i35, %i36, %i37, %i38, %i39, %i40, %i41, %i42, %i43, %i44, %i45, %i46, %i47)
        draw16(%rs, %i48, %i49, %i50, %i51, %i52, %i53, %i54, %i55, %i56, %i57, %i58, %i59, %i60, %i61, %i62, %i63)
    .end_macro
    # macro expansion go brrrr
    .macro draw256(%rs, %i0, %i1, %i2, %i3, %i4, %i5, %i6, %i7, %i8, %i9, %i10, %i11, %i12, %i13, %i14, %i15, %i16, %i17, %i18, %i19, %i20, %i21, %i22, %i23, %i24, %i25, %i26, %i27, %i28, %i29, %i30, %i31, %i32, %i33, %i34, %i35, %i36, %i37, %i38, %i39, %i40, %i41, %i42, %i43, %i44, %i45, %i46, %i47, %i48, %i49, %i50, %i51, %i52, %i53, %i54, %i55, %i56, %i57, %i58, %i59, %i60, %i61, %i62, %i63, %i64, %i65, %i66, %i67, %i68, %i69, %i70, %i71, %i72, %i73, %i74, %i75, %i76, %i77, %i78, %i79, %i80, %i81, %i82, %i83, %i84, %i85, %i86, %i87, %i88, %i89, %i90, %i91, %i92, %i93, %i94, %i95, %i96, %i97, %i98, %i99, %i100, %i101, %i102, %i103, %i104, %i105, %i106, %i107, %i108, %i109, %i110, %i111, %i112, %i113, %i114, %i115, %i116, %i117, %i118, %i119, %i120, %i121, %i122, %i123, %i124, %i125, %i126, %i127, %i128, %i129, %i130, %i131, %i132, %i133, %i134, %i135, %i136, %i137, %i138, %i139, %i140, %i141, %i142, %i143, %i144, %i145, %i146, %i147, %i148, %i149, %i150, %i151, %i152, %i153, %i154, %i155, %i156, %i157, %i158, %i159, %i160, %i161, %i162, %i163, %i164, %i165, %i166, %i167, %i168, %i169, %i170, %i171, %i172, %i173, %i174, %i175, %i176, %i177, %i178, %i179, %i180, %i181, %i182, %i183, %i184, %i185, %i186, %i187, %i188, %i189, %i190, %i191, %i192, %i193, %i194, %i195, %i196, %i197, %i198, %i199, %i200, %i201, %i202, %i203, %i204, %i205, %i206, %i207, %i208, %i209, %i210, %i211, %i212, %i213, %i214, %i215, %i216, %i217, %i218, %i219, %i220, %i221, %i222, %i223, %i224, %i225, %i226, %i227, %i228, %i229, %i230, %i231, %i232, %i233, %i234, %i235, %i236, %i237, %i238, %i239, %i240, %i241, %i242, %i243, %i244, %i245, %i246, %i247, %i248, %i249, %i250, %i251, %i252, %i253, %i254, %i255)
        draw64(%rs, %i0, %i1, %i2, %i3, %i4, %i5, %i6, %i7, %i8, %i9, %i10, %i11, %i12, %i13, %i14, %i15, %i16, %i17, %i18, %i19, %i20, %i21, %i22, %i23, %i24, %i25, %i26, %i27, %i28, %i29, %i30, %i31, %i32, %i33, %i34, %i35, %i36, %i37, %i38, %i39, %i40, %i41, %i42, %i43, %i44, %i45, %i46, %i47, %i48, %i49, %i50, %i51, %i52, %i53, %i54, %i55, %i56, %i57, %i58, %i59, %i60, %i61, %i62, %i63)
        draw64(%rs, %i64, %i65, %i66, %i67, %i68, %i69, %i70, %i71, %i72, %i73, %i74, %i75, %i76, %i77, %i78, %i79, %i80, %i81, %i82, %i83, %i84, %i85, %i86, %i87, %i88, %i89, %i90, %i91, %i92, %i93, %i94, %i95, %i96, %i97, %i98, %i99, %i100, %i101, %i102, %i103, %i104, %i105, %i106, %i107, %i108, %i109, %i110, %i111, %i112, %i113, %i114, %i115, %i116, %i117, %i118, %i119, %i120, %i121, %i122, %i123, %i124, %i125, %i126, %i127)
        draw64(%rs, %i128, %i129, %i130, %i131, %i132, %i133, %i134, %i135, %i136, %i137, %i138, %i139, %i140, %i141, %i142, %i143, %i144, %i145, %i146, %i147, %i148, %i149, %i150, %i151, %i152, %i153, %i154, %i155, %i156, %i157, %i158, %i159, %i160, %i161, %i162, %i163, %i164, %i165, %i166, %i167, %i168, %i169, %i170, %i171, %i172, %i173, %i174, %i175, %i176, %i177, %i178, %i179, %i180, %i181, %i182, %i183, %i184, %i185, %i186, %i187, %i188, %i189, %i190, %i191)
        draw64(%rs, %i192, %i193, %i194, %i195, %i196, %i197, %i198, %i199, %i200, %i201, %i202, %i203, %i204, %i205, %i206, %i207, %i208, %i209, %i210, %i211, %i212, %i213, %i214, %i215, %i216, %i217, %i218, %i219, %i220, %i221, %i222, %i223, %i224, %i225, %i226, %i227, %i228, %i229, %i230, %i231, %i232, %i233, %i234, %i235, %i236, %i237, %i238, %i239, %i240, %i241, %i242, %i243, %i244, %i245, %i246, %i247, %i248, %i249, %i250, %i251, %i252, %i253, %i254, %i255)
    .end_macro
    # MACRO EXPANSION GO BRRRRR
    .macro draw1024(%rs, %i0, %i1, %i2, %i3, %i4, %i5, %i6, %i7, %i8, %i9, %i10, %i11, %i12, %i13, %i14, %i15, %i16, %i17, %i18, %i19, %i20, %i21, %i22, %i23, %i24, %i25, %i26, %i27, %i28, %i29, %i30, %i31, %i32, %i33, %i34, %i35, %i36, %i37, %i38, %i39, %i40, %i41, %i42, %i43, %i44, %i45, %i46, %i47, %i48, %i49, %i50, %i51, %i52, %i53, %i54, %i55, %i56, %i57, %i58, %i59, %i60, %i61, %i62, %i63, %i64, %i65, %i66, %i67, %i68, %i69, %i70, %i71, %i72, %i73, %i74, %i75, %i76, %i77, %i78, %i79, %i80, %i81, %i82, %i83, %i84, %i85, %i86, %i87, %i88, %i89, %i90, %i91, %i92, %i93, %i94, %i95, %i96, %i97, %i98, %i99, %i100, %i101, %i102, %i103, %i104, %i105, %i106, %i107, %i108, %i109, %i110, %i111, %i112, %i113, %i114, %i115, %i116, %i117, %i118, %i119, %i120, %i121, %i122, %i123, %i124, %i125, %i126, %i127, %i128, %i129, %i130, %i131, %i132, %i133, %i134, %i135, %i136, %i137, %i138, %i139, %i140, %i141, %i142, %i143, %i144, %i145, %i146, %i147, %i148, %i149, %i150, %i151, %i152, %i153, %i154, %i155, %i156, %i157, %i158, %i159, %i160, %i161, %i162, %i163, %i164, %i165, %i166, %i167, %i168, %i169, %i170, %i171, %i172, %i173, %i174, %i175, %i176, %i177, %i178, %i179, %i180, %i181, %i182, %i183, %i184, %i185, %i186, %i187, %i188, %i189, %i190, %i191, %i192, %i193, %i194, %i195, %i196, %i197, %i198, %i199, %i200, %i201, %i202, %i203, %i204, %i205, %i206, %i207, %i208, %i209, %i210, %i211, %i212, %i213, %i214, %i215, %i216, %i217, %i218, %i219, %i220, %i221, %i222, %i223, %i224, %i225, %i226, %i227, %i228, %i229, %i230, %i231, %i232, %i233, %i234, %i235, %i236, %i237, %i238, %i239, %i240, %i241, %i242, %i243, %i244, %i245, %i246, %i247, %i248, %i249, %i250, %i251, %i252, %i253, %i254, %i255, %i256, %i257, %i258, %i259, %i260, %i261, %i262, %i263, %i264, %i265, %i266, %i267, %i268, %i269, %i270, %i271, %i272, %i273, %i274, %i275, %i276, %i277, %i278, %i279, %i280, %i281, %i282, %i283, %i284, %i285, %i286, %i287, %i288, %i289, %i290, %i291, %i292, %i293, %i294, %i295, %i296, %i297, %i298, %i299, %i300, %i301, %i302, %i303, %i304, %i305, %i306, %i307, %i308, %i309, %i310, %i311, %i312, %i313, %i314, %i315, %i316, %i317, %i318, %i319, %i320, %i321, %i322, %i323, %i324, %i325, %i326, %i327, %i328, %i329, %i330, %i331, %i332, %i333, %i334, %i335, %i336, %i337, %i338, %i339, %i340, %i341, %i342, %i343, %i344, %i345, %i346, %i347, %i348, %i349, %i350, %i351, %i352, %i353, %i354, %i355, %i356, %i357, %i358, %i359, %i360, %i361, %i362, %i363, %i364, %i365, %i366, %i367, %i368, %i369, %i370, %i371, %i372, %i373, %i374, %i375, %i376, %i377, %i378, %i379, %i380, %i381, %i382, %i383, %i384, %i385, %i386, %i387, %i388, %i389, %i390, %i391, %i392, %i393, %i394, %i395, %i396, %i397, %i398, %i399, %i400, %i401, %i402, %i403, %i404, %i405, %i406, %i407, %i408, %i409, %i410, %i411, %i412, %i413, %i414, %i415, %i416, %i417, %i418, %i419, %i420, %i421, %i422, %i423, %i424, %i425, %i426, %i427, %i428, %i429, %i430, %i431, %i432, %i433, %i434, %i435, %i436, %i437, %i438, %i439, %i440, %i441, %i442, %i443, %i444, %i445, %i446, %i447, %i448, %i449, %i450, %i451, %i452, %i453, %i454, %i455, %i456, %i457, %i458, %i459, %i460, %i461, %i462, %i463, %i464, %i465, %i466, %i467, %i468, %i469, %i470, %i471, %i472, %i473, %i474, %i475, %i476, %i477, %i478, %i479, %i480, %i481, %i482, %i483, %i484, %i485, %i486, %i487, %i488, %i489, %i490, %i491, %i492, %i493, %i494, %i495, %i496, %i497, %i498, %i499, %i500, %i501, %i502, %i503, %i504, %i505, %i506, %i507, %i508, %i509, %i510, %i511, %i512, %i513, %i514, %i515, %i516, %i517, %i518, %i519, %i520, %i521, %i522, %i523, %i524, %i525, %i526, %i527, %i528, %i529, %i530, %i531, %i532, %i533, %i534, %i535, %i536, %i537, %i538, %i539, %i540, %i541, %i542, %i543, %i544, %i545, %i546, %i547, %i548, %i549, %i550, %i551, %i552, %i553, %i554, %i555, %i556, %i557, %i558, %i559, %i560, %i561, %i562, %i563, %i564, %i565, %i566, %i567, %i568, %i569, %i570, %i571, %i572, %i573, %i574, %i575, %i576, %i577, %i578, %i579, %i580, %i581, %i582, %i583, %i584, %i585, %i586, %i587, %i588, %i589, %i590, %i591, %i592, %i593, %i594, %i595, %i596, %i597, %i598, %i599, %i600, %i601, %i602, %i603, %i604, %i605, %i606, %i607, %i608, %i609, %i610, %i611, %i612, %i613, %i614, %i615, %i616, %i617, %i618, %i619, %i620, %i621, %i622, %i623, %i624, %i625, %i626, %i627, %i628, %i629, %i630, %i631, %i632, %i633, %i634, %i635, %i636, %i637, %i638, %i639, %i640, %i641, %i642, %i643, %i644, %i645, %i646, %i647, %i648, %i649, %i650, %i651, %i652, %i653, %i654, %i655, %i656, %i657, %i658, %i659, %i660, %i661, %i662, %i663, %i664, %i665, %i666, %i667, %i668, %i669, %i670, %i671, %i672, %i673, %i674, %i675, %i676, %i677, %i678, %i679, %i680, %i681, %i682, %i683, %i684, %i685, %i686, %i687, %i688, %i689, %i690, %i691, %i692, %i693, %i694, %i695, %i696, %i697, %i698, %i699, %i700, %i701, %i702, %i703, %i704, %i705, %i706, %i707, %i708, %i709, %i710, %i711, %i712, %i713, %i714, %i715, %i716, %i717, %i718, %i719, %i720, %i721, %i722, %i723, %i724, %i725, %i726, %i727, %i728, %i729, %i730, %i731, %i732, %i733, %i734, %i735, %i736, %i737, %i738, %i739, %i740, %i741, %i742, %i743, %i744, %i745, %i746, %i747, %i748, %i749, %i750, %i751, %i752, %i753, %i754, %i755, %i756, %i757, %i758, %i759, %i760, %i761, %i762, %i763, %i764, %i765, %i766, %i767, %i768, %i769, %i770, %i771, %i772, %i773, %i774, %i775, %i776, %i777, %i778, %i779, %i780, %i781, %i782, %i783, %i784, %i785, %i786, %i787, %i788, %i789, %i790, %i791, %i792, %i793, %i794, %i795, %i796, %i797, %i798, %i799, %i800, %i801, %i802, %i803, %i804, %i805, %i806, %i807, %i808, %i809, %i810, %i811, %i812, %i813, %i814, %i815, %i816, %i817, %i818, %i819, %i820, %i821, %i822, %i823, %i824, %i825, %i826, %i827, %i828, %i829, %i830, %i831, %i832, %i833, %i834, %i835, %i836, %i837, %i838, %i839, %i840, %i841, %i842, %i843, %i844, %i845, %i846, %i847, %i848, %i849, %i850, %i851, %i852, %i853, %i854, %i855, %i856, %i857, %i858, %i859, %i860, %i861, %i862, %i863, %i864, %i865, %i866, %i867, %i868, %i869, %i870, %i871, %i872, %i873, %i874, %i875, %i876, %i877, %i878, %i879, %i880, %i881, %i882, %i883, %i884, %i885, %i886, %i887, %i888, %i889, %i890, %i891, %i892, %i893, %i894, %i895, %i896, %i897, %i898, %i899, %i900, %i901, %i902, %i903, %i904, %i905, %i906, %i907, %i908, %i909, %i910, %i911, %i912, %i913, %i914, %i915, %i916, %i917, %i918, %i919, %i920, %i921, %i922, %i923, %i924, %i925, %i926, %i927, %i928, %i929, %i930, %i931, %i932, %i933, %i934, %i935, %i936, %i937, %i938, %i939, %i940, %i941, %i942, %i943, %i944, %i945, %i946, %i947, %i948, %i949, %i950, %i951, %i952, %i953, %i954, %i955, %i956, %i957, %i958, %i959, %i960, %i961, %i962, %i963, %i964, %i965, %i966, %i967, %i968, %i969, %i970, %i971, %i972, %i973, %i974, %i975, %i976, %i977, %i978, %i979, %i980, %i981, %i982, %i983, %i984, %i985, %i986, %i987, %i988, %i989, %i990, %i991, %i992, %i993, %i994, %i995, %i996, %i997, %i998, %i999, %i1000, %i1001, %i1002, %i1003, %i1004, %i1005, %i1006, %i1007, %i1008, %i1009, %i1010, %i1011, %i1012, %i1013, %i1014, %i1015, %i1016, %i1017, %i1018, %i1019, %i1020, %i1021, %i1022, %i1023)
        draw256(%rs, %i0, %i1, %i2, %i3, %i4, %i5, %i6, %i7, %i8, %i9, %i10, %i11, %i12, %i13, %i14, %i15, %i16, %i17, %i18, %i19, %i20, %i21, %i22, %i23, %i24, %i25, %i26, %i27, %i28, %i29, %i30, %i31, %i32, %i33, %i34, %i35, %i36, %i37, %i38, %i39, %i40, %i41, %i42, %i43, %i44, %i45, %i46, %i47, %i48, %i49, %i50, %i51, %i52, %i53, %i54, %i55, %i56, %i57, %i58, %i59, %i60, %i61, %i62, %i63, %i64, %i65, %i66, %i67, %i68, %i69, %i70, %i71, %i72, %i73, %i74, %i75, %i76, %i77, %i78, %i79, %i80, %i81, %i82, %i83, %i84, %i85, %i86, %i87, %i88, %i89, %i90, %i91, %i92, %i93, %i94, %i95, %i96, %i97, %i98, %i99, %i100, %i101, %i102, %i103, %i104, %i105, %i106, %i107, %i108, %i109, %i110, %i111, %i112, %i113, %i114, %i115, %i116, %i117, %i118, %i119, %i120, %i121, %i122, %i123, %i124, %i125, %i126, %i127, %i128, %i129, %i130, %i131, %i132, %i133, %i134, %i135, %i136, %i137, %i138, %i139, %i140, %i141, %i142, %i143, %i144, %i145, %i146, %i147, %i148, %i149, %i150, %i151, %i152, %i153, %i154, %i155, %i156, %i157, %i158, %i159, %i160, %i161, %i162, %i163, %i164, %i165, %i166, %i167, %i168, %i169, %i170, %i171, %i172, %i173, %i174, %i175, %i176, %i177, %i178, %i179, %i180, %i181, %i182, %i183, %i184, %i185, %i186, %i187, %i188, %i189, %i190, %i191, %i192, %i193, %i194, %i195, %i196, %i197, %i198, %i199, %i200, %i201, %i202, %i203, %i204, %i205, %i206, %i207, %i208, %i209, %i210, %i211, %i212, %i213, %i214, %i215, %i216, %i217, %i218, %i219, %i220, %i221, %i222, %i223, %i224, %i225, %i226, %i227, %i228, %i229, %i230, %i231, %i232, %i233, %i234, %i235, %i236, %i237, %i238, %i239, %i240, %i241, %i242, %i243, %i244, %i245, %i246, %i247, %i248, %i249, %i250, %i251, %i252, %i253, %i254, %i255)
        draw256(%rs, %i256, %i257, %i258, %i259, %i260, %i261, %i262, %i263, %i264, %i265, %i266, %i267, %i268, %i269, %i270, %i271, %i272, %i273, %i274, %i275, %i276, %i277, %i278, %i279, %i280, %i281, %i282, %i283, %i284, %i285, %i286, %i287, %i288, %i289, %i290, %i291, %i292, %i293, %i294, %i295, %i296, %i297, %i298, %i299, %i300, %i301, %i302, %i303, %i304, %i305, %i306, %i307, %i308, %i309, %i310, %i311, %i312, %i313, %i314, %i315, %i316, %i317, %i318, %i319, %i320, %i321, %i322, %i323, %i324, %i325, %i326, %i327, %i328, %i329, %i330, %i331, %i332, %i333, %i334, %i335, %i336, %i337, %i338, %i339, %i340, %i341, %i342, %i343, %i344, %i345, %i346, %i347, %i348, %i349, %i350, %i351, %i352, %i353, %i354, %i355, %i356, %i357, %i358, %i359, %i360, %i361, %i362, %i363, %i364, %i365, %i366, %i367, %i368, %i369, %i370, %i371, %i372, %i373, %i374, %i375, %i376, %i377, %i378, %i379, %i380, %i381, %i382, %i383, %i384, %i385, %i386, %i387, %i388, %i389, %i390, %i391, %i392, %i393, %i394, %i395, %i396, %i397, %i398, %i399, %i400, %i401, %i402, %i403, %i404, %i405, %i406, %i407, %i408, %i409, %i410, %i411, %i412, %i413, %i414, %i415, %i416, %i417, %i418, %i419, %i420, %i421, %i422, %i423, %i424, %i425, %i426, %i427, %i428, %i429, %i430, %i431, %i432, %i433, %i434, %i435, %i436, %i437, %i438, %i439, %i440, %i441, %i442, %i443, %i444, %i445, %i446, %i447, %i448, %i449, %i450, %i451, %i452, %i453, %i454, %i455, %i456, %i457, %i458, %i459, %i460, %i461, %i462, %i463, %i464, %i465, %i466, %i467, %i468, %i469, %i470, %i471, %i472, %i473, %i474, %i475, %i476, %i477, %i478, %i479, %i480, %i481, %i482, %i483, %i484, %i485, %i486, %i487, %i488, %i489, %i490, %i491, %i492, %i493, %i494, %i495, %i496, %i497, %i498, %i499, %i500, %i501, %i502, %i503, %i504, %i505, %i506, %i507, %i508, %i509, %i510, %i511)
        draw256(%rs, %i512, %i513, %i514, %i515, %i516, %i517, %i518, %i519, %i520, %i521, %i522, %i523, %i524, %i525, %i526, %i527, %i528, %i529, %i530, %i531, %i532, %i533, %i534, %i535, %i536, %i537, %i538, %i539, %i540, %i541, %i542, %i543, %i544, %i545, %i546, %i547, %i548, %i549, %i550, %i551, %i552, %i553, %i554, %i555, %i556, %i557, %i558, %i559, %i560, %i561, %i562, %i563, %i564, %i565, %i566, %i567, %i568, %i569, %i570, %i571, %i572, %i573, %i574, %i575, %i576, %i577, %i578, %i579, %i580, %i581, %i582, %i583, %i584, %i585, %i586, %i587, %i588, %i589, %i590, %i591, %i592, %i593, %i594, %i595, %i596, %i597, %i598, %i599, %i600, %i601, %i602, %i603, %i604, %i605, %i606, %i607, %i608, %i609, %i610, %i611, %i612, %i613, %i614, %i615, %i616, %i617, %i618, %i619, %i620, %i621, %i622, %i623, %i624, %i625, %i626, %i627, %i628, %i629, %i630, %i631, %i632, %i633, %i634, %i635, %i636, %i637, %i638, %i639, %i640, %i641, %i642, %i643, %i644, %i645, %i646, %i647, %i648, %i649, %i650, %i651, %i652, %i653, %i654, %i655, %i656, %i657, %i658, %i659, %i660, %i661, %i662, %i663, %i664, %i665, %i666, %i667, %i668, %i669, %i670, %i671, %i672, %i673, %i674, %i675, %i676, %i677, %i678, %i679, %i680, %i681, %i682, %i683, %i684, %i685, %i686, %i687, %i688, %i689, %i690, %i691, %i692, %i693, %i694, %i695, %i696, %i697, %i698, %i699, %i700, %i701, %i702, %i703, %i704, %i705, %i706, %i707, %i708, %i709, %i710, %i711, %i712, %i713, %i714, %i715, %i716, %i717, %i718, %i719, %i720, %i721, %i722, %i723, %i724, %i725, %i726, %i727, %i728, %i729, %i730, %i731, %i732, %i733, %i734, %i735, %i736, %i737, %i738, %i739, %i740, %i741, %i742, %i743, %i744, %i745, %i746, %i747, %i748, %i749, %i750, %i751, %i752, %i753, %i754, %i755, %i756, %i757, %i758, %i759, %i760, %i761, %i762, %i763, %i764, %i765, %i766, %i767)
        draw256(%rs, %i768, %i769, %i770, %i771, %i772, %i773, %i774, %i775, %i776, %i777, %i778, %i779, %i780, %i781, %i782, %i783, %i784, %i785, %i786, %i787, %i788, %i789, %i790, %i791, %i792, %i793, %i794, %i795, %i796, %i797, %i798, %i799, %i800, %i801, %i802, %i803, %i804, %i805, %i806, %i807, %i808, %i809, %i810, %i811, %i812, %i813, %i814, %i815, %i816, %i817, %i818, %i819, %i820, %i821, %i822, %i823, %i824, %i825, %i826, %i827, %i828, %i829, %i830, %i831, %i832, %i833, %i834, %i835, %i836, %i837, %i838, %i839, %i840, %i841, %i842, %i843, %i844, %i845, %i846, %i847, %i848, %i849, %i850, %i851, %i852, %i853, %i854, %i855, %i856, %i857, %i858, %i859, %i860, %i861, %i862, %i863, %i864, %i865, %i866, %i867, %i868, %i869, %i870, %i871, %i872, %i873, %i874, %i875, %i876, %i877, %i878, %i879, %i880, %i881, %i882, %i883, %i884, %i885, %i886, %i887, %i888, %i889, %i890, %i891, %i892, %i893, %i894, %i895, %i896, %i897, %i898, %i899, %i900, %i901, %i902, %i903, %i904, %i905, %i906, %i907, %i908, %i909, %i910, %i911, %i912, %i913, %i914, %i915, %i916, %i917, %i918, %i919, %i920, %i921, %i922, %i923, %i924, %i925, %i926, %i927, %i928, %i929, %i930, %i931, %i932, %i933, %i934, %i935, %i936, %i937, %i938, %i939, %i940, %i941, %i942, %i943, %i944, %i945, %i946, %i947, %i948, %i949, %i950, %i951, %i952, %i953, %i954, %i955, %i956, %i957, %i958, %i959, %i960, %i961, %i962, %i963, %i964, %i965, %i966, %i967, %i968, %i969, %i970, %i971, %i972, %i973, %i974, %i975, %i976, %i977, %i978, %i979, %i980, %i981, %i982, %i983, %i984, %i985, %i986, %i987, %i988, %i989, %i990, %i991, %i992, %i993, %i994, %i995, %i996, %i997, %i998, %i999, %i1000, %i1001, %i1002, %i1003, %i1004, %i1005, %i1006, %i1007, %i1008, %i1009, %i1010, %i1011, %i1012, %i1013, %i1014, %i1015, %i1016, %i1017, %i1018, %i1019, %i1020, %i1021, %i1022, %i1023)
    .end_macro
.text
    save(doll, doll_address)
    save(door, door_address)
init_pre:
    li $s7 0 # reset time
    li $a1 4 # clear outwards
    jal draw_clear
    jal draw_border
    jal draw_pre_eclipse
    jal draw_pre_alice
    # prepare music
    la $s0 wonderland
    move $s4 $s0
    addi $s1 $s0 PRE_LEN
    li $s2 1
    li $s6 0
    li $s3 64
pre:
    bge $s7 PRE_FRAME pre_ui_end
        # load frame addr from memory
        srl $t0 $s7 1
        andi $t0 $t0 0xfffc # unset last 2 bits to make word aligned
        la $t1 pregame_frames
        add $t0 $t0 $t1
        lw $v0 0($t0)
        setup_color($s7)
        jalr $v0
    pre_ui_end:

    bnez $s6 pre_music_end # wait
    slt $t0 $s4 $s1
    movz $s4 $s0 $t0 # rewind to start
    lw $a0 0($s4) # pitch
    lw $a1 4($s4) # duration
    move $s6 $a1
    addi $s4 $s4 8 # next note
    beqz $a0 pre_music_end # pitch == 0 => rest
    move $a2 $s2 # instrument
    move $a3 $s3 # volume
    li $v0 31
    syscall # midi
    pre_music_end:

    jal ui_keypress
    addi $s7 $s7 1 # increment time
    subi $s6 $s6 PRE_RATE
    li $a0 PRE_RATE # sleep
    li $v0 32
    syscall
    j pre

start:
    move $s7 $0 # reset time
    sw $0 stage # reset stage
    main_clear:
        li $a1 -4 # clear inw
        jal draw_clear
main_init:
    # if all stage completed
    lw $t0 stage
    bge $t0 STAGE_COUNT init_post

    li $s0 PLAYER_INIT # player x
    li $s1 PLAYER_INIT # player y
    li $s4 1 # face east
    li $s5 2 # door locked, not landed, can double jump
    move $s6 $0 # jump distance remaining
    la $ra cheat # i.e. label to next line
    beqz $t0 draw_collect

    cheat: # skip to final stage and tp to exit
    li $s0 352
    li $s1 384
    li $s5 7
    li $t0 16
    sw $t0 stage

    # new gravity
    lh $s2 stage_gravity($t0) # gravity x
    addi $t0 $t0 2
    lh $s3 stage_gravity($t0) # gravity y

    #li $t0 BASE_ADDRESS
    #li $t1 0x10018000
    #clear_screen_loop:
    #    sw $0 0($t0)
    #    addi $t0 $t0 4
    #    ble $t0 $t1 clear_screen_loop
    # get current position to v0
    jal draw_stage
    flatten($s0, $s1, $v1)
    li $a0 0
    li $a1 0
    jal draw_alice
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

ui_keypress:
    check_keypress()

    li $a0 7 # setup full color
    setup_color($a0)

    li $a0 BASE_ADDRESS
    add $a0 $a0 1536 # (0, 3)

    beq $v0 0x70 key_reset # p
    beq $v0 0x71 key_quit # q
    beq $v0 0x73 key_start # s
    jr $ra
    key_reset:
        la $ra init_pre
        add $v1 $a0 POST_P
        beqz $s0 draw_keyp
        jr $ra
    key_quit:
        la $ra terminate
        addi $v1 $a0 POST_Q
        beqz $s0 draw_keyq
        addi $v1 $a0 PRE_Q
        j draw_keyq
    key_start:
        la $ra start
        addi $v1 $a0 POST_S
        beqz $s0 draw_keys
        addi $v1 $a0 PRE_S
        j draw_keys

keypress: # check ingame keypress, return dx dy as a0 a1
    check_keypress()
    beq $v0 0x70 init_pre # p
    beq $v0 0x20 keypress_spc
    # the rest are movements
    beq $v0 0x77 keypress_w
    beq $v0 0x73 keypress_s

    # a or d pressed
    bnez $s2 jrra # can't move top/bottom
    beq $v0 0x61 keypress_a
    beq $v0 0x64 keypress_d
    # skip other keys
    jr $ra
    keypress_spc:
        andi $t0 $s5 3 # take double jump, landed
        beqz $t0 jrra # can't jump
        li $s6 JUMP_HEIGHT
        andi $s5 $s5 0xfffc # reset last 2 bits

        andi $t0 $t0 0x1 # take last bit
        sll $t0 $t0 1 # shift left
        or $s5 $s5 $t0 # double jump iff not landed
        jr $ra
    keypress_w:
    bnez $s3 jrra # can't move up
    movement(0,-4)
    keypress_s:
    bnez $s3 jrra # can't move up
    movement(0,4)
    keypress_a:
    movement(-4,0)
    keypress_d:
    movement(4,0)
gravity:
    move $a2 $s2 # update player position
    move $a3 $s3
    beq $s6 0 jrra
    # jumping
    neg $a2 $a2 # reverse gravity
    neg $a3 $a3
    abs $t0 $s2 # get absolute value of jump distance
    sub $s6 $s6 $t0 # update jump distance, assume s2 == 0 or s3 == 0
    abs $t0 $s3
    sub $s6 $s6 $t0
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
    bltz $s2 main_clear # fell off screen
    j collision_end
    player_bbox_1:
        bgez $t1 player_bbox_2
        bltz $s3 main_clear # fell off screen
        j collision_end
    player_bbox_2:
        add $t2 $t0 PLAYER_SIZE
        ble $t2 SIZE player_bbox_3
        bgtz $s2 main_clear # fell off screen
        j collision_end
    player_bbox_3:
        add $t3 $t1 PLAYER_SIZE
        ble $t3 SIZE player_bbox_end
        bgtz $s3 main_clear # fell off screen
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
        bne $a2 $s2 jrra
        bne $a3 $s3 jrra
        ori $s5 $s5 0x3 # landed (and can double jump)
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
            lw $v1 door_address
            jal draw_door
            lw $t4 stage
            # apply stage specific gimmicks
            beqz $t4 stage_0
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
    flatten($s0, $s1, $v1)
    jal draw_alice # draw player at new position
    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4
    jr $ra # return

next_stage: # prepare for next stage, then goto init
    lw $t0 stage
    addi $t0 $t0 4
    sw $t0 stage
    li $a1 4 # clear outw
    la $ra main_init
    j draw_clear
stage_0: # stage 0 gimmick
    la $ra player_move_update
    j draw_enter
stage_1: # stage 1 gimmick
    li $s2 0 # reset gravity
    li $s3 4
    li $s6 0 # reset jump distance
    j player_move_update
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
    j player_move_update

init_post:
    move $s0 $0
    li $s7 0 # reset time
    jal draw_border
    li $a0 REFRESH_RATE # sleep
    li $s2 112 # instrument
    li $s3 0x40 # max volume
    li $s5 5
    li $a1 250 # duration
post:
    bge $s7 POST_FRAME post_ui_end
        # consume keypress
        li $t0 0xffff0000
        lw $t1 4($t0)
        # load frame addr from memory
        srl $t0 $s7 1
        andi $t0 $t0 0xfffc # unset last 2 bits to make word aligned
        la $t1 postgame_frames
        add $t0 $t0 $t1
        lw $v0 0($t0)
        setup_color($s7)
        jalr $v0
    post_ui_end:
    jal ui_keypress
    # draw doll
    andi $t4 $s7 1 # every 2 frames
    bnez $t4 post_doll_end # skip
    jal draw_post_doll
    post_doll_end:

    # music
    div $s7 $s5
    mfhi $t0
    bnez $t0 post_refresh
    beqz $s7 post_refresh # skip first frame (so volume wont be 0)
    mflo $t0
    # mod 16
    and $t0 $t0 0xf
    sll $t0 $t0 2 # in bytes
    la $t1 score
    add $t0 $t0 $t1
    lw $a0 0($t0) # load pitch
    move $a2 $s2 # load instrument
    move $a3 $s3 # load volume
    slt $t0 $s7 $s3
    movn $a3 $s7 $t0 # increasing volume
    li $v0 31
    syscall # midi

    post_refresh:
    addi $s7 $s7 1 # increment time
    li $a0 POST_RATE # sleep
    li $v0 32
    syscall
    j post

terminate: # terminate the program gracefully
    li $a1 -4
    jal draw_clear
    li $v0 10
    syscall

draw_collect: # use t4
    li $v1 BASE_ADDRESS
    addi $v1 $v1 1312 # (72, 2)
    draw16($0, 0, 1032, 1044, 1048, 1540, 1556, 1588, 1592, 2056, 2068, 2108, 2112, 2564, 2584, 2612, 2616)
    draw16($0, 2636, 2692, 2752, 3080, 3092, 7172, 7688, 7692, 8196, 8200, 8216, 8284, 8360, 8380, 8756, 8760)
    draw4($0, 8764, 8796, 8872, 8892)
    draw4($0, 9728, 9800, 9812, 9824)
    sw $0 9840($v1)
    sw $0 9904($v1)
    sw $0 9924($v1)
    li $t4 0x372e12
    sw $t4 4($v1)
    sw $t4 2228($v1)
    sw $t4 3708($v1)
    li $t4 0xfad053
    draw64($t4, 8, 12, 16, 20, 516, 536, 564, 568, 1024, 1040, 1052, 1072, 1084, 1112, 1120, 1168, 1536, 1552, 1564, 1584, 1608, 1612, 1644, 1648, 1664, 1668, 1680, 1684, 1704, 1708, 2048, 2064, 2076, 2096, 2116, 2128, 2152, 2164, 2184, 2192, 2212, 2244, 2560, 2576, 2588, 2608, 2628, 2640, 2664, 2668, 2672, 2676, 2704, 2724, 2756, 3072, 3088, 3100, 3120, 3132, 3140, 3152, 3160, 3168)
    draw16($t4, 3176, 3196, 3208, 3216, 3236, 3248, 3256, 3268, 3588, 3608, 3636, 3640, 3656, 3660, 3672, 3680)
    draw4($t4, 3692, 3696, 3712, 3716)
    draw4($t4, 3732, 3752, 3756, 3772)
    draw4($t4, 3776, 4104, 4108, 4112)
    sw $t4 4116($v1)
    li $t4 0x4f421a
    sw $t4 24($v1)
    li $t4 0x2a230e
    sw $t4 88($v1)
    sw $t4 1212($v1)
    sw $t4 2748($v1)
    li $t4 0x050402
    sw $t4 92($v1)
    sw $t4 1028($v1)
    li $t4 0x201b0b
    draw4($t4, 96, 176, 1096, 3612)
    li $t4 0x1b1609
    sw $t4 200($v1)
    li $t4 0x120f06
    sw $t4 204($v1)
    li $t4 0x0a0803
    sw $t4 208($v1)
    sw $t4 2124($v1)
    sw $t4 2728($v1)
    li $t4 0x1f190a
    sw $t4 212($v1)
    li $t4 0x3c3214
    sw $t4 512($v1)
    sw $t4 2220($v1)
    li $t4 0x0f0c05
    sw $t4 520($v1)
    li $t4 0x2c250f
    sw $t4 524($v1)
    li $t4 0x4c401a
    sw $t4 528($v1)
    li $t4 0x020201
    draw4($t4, 532, 1560, 2568, 2580)
    sw $t4 2696($v1)
    li $t4 0x594a1e
    sw $t4 540($v1)
    sw $t4 3780($v1)
    li $t4 0x6e5b24
    sw $t4 560($v1)
    sw $t4 1080($v1)
    sw $t4 2168($v1)
    li $t4 0x605020
    sw $t4 572($v1)
    li $t4 0xf5cc51
    sw $t4 600($v1)
    sw $t4 2144($v1)
    li $t4 0x231d0c
    draw4($t4, 604, 1116, 1628, 2132)
    sw $t4 2140($v1)
    sw $t4 2644($v1)
    sw $t4 3156($v1)
    li $t4 0xf4cb51
    sw $t4 608($v1)
    sw $t4 2744($v1)
    li $t4 0x27210d
    draw4($t4, 612, 1132, 1204, 2208)
    li $t4 0x453917
    sw $t4 656($v1)
    li $t4 0x2e260f
    sw $t4 684($v1)
    li $t4 0xf6cd52
    draw4($t4, 688, 1712, 2136, 2224)
    li $t4 0x241e0c
    sw $t4 692($v1)
    sw $t4 1056($v1)
    sw $t4 2652($v1)
    li $t4 0x4b3f19
    draw4($t4, 712, 720, 1604, 2768)
    sw $t4 3184($v1)
    sw $t4 3748($v1)
    li $t4 0xe7c14d
    sw $t4 716($v1)
    sw $t4 724($v1)
    li $t4 0x967d32
    draw4($t4, 1036, 1548, 1580, 2060)
    draw4($t4, 2092, 2572, 2604, 3084)
    li $t4 0x58491d
    sw $t4 1068($v1)
    li $t4 0x655422
    sw $t4 1076($v1)
    li $t4 0x4d401a
    draw4($t4, 1088, 1196, 1224, 1232)
    sw $t4 1736($v1)
    li $t4 0x3f3415
    sw $t4 1100($v1)
    li $t4 0x29220e
    sw $t4 1124($v1)
    li $t4 0x3b3114
    sw $t4 1136($v1)
    li $t4 0x302810
    sw $t4 1152($v1)
    li $t4 0x322a11
    sw $t4 1156($v1)
    li $t4 0x2f2710
    sw $t4 1164($v1)
    sw $t4 3596($v1)
    li $t4 0x6d5a24
    sw $t4 1172($v1)
    li $t4 0x342b11
    sw $t4 1192($v1)
    li $t4 0xf8ce52
    sw $t4 1200($v1)
    sw $t4 3276($v1)
    sw $t4 3284($v1)
    li $t4 0x382e13
    sw $t4 1216($v1)
    sw $t4 2720($v1)
    li $t4 0xedc54f
    sw $t4 1228($v1)
    sw $t4 1236($v1)
    sw $t4 2736($v1)
    li $t4 0x010100
    sw $t4 1544($v1)
    sw $t4 2052($v1)
    sw $t4 2072($v1)
    li $t4 0x3e3315
    draw4($t4, 1568, 1600, 2080, 2592)
    li $t4 0x685623
    sw $t4 1596($v1)
    li $t4 0x8f7730
    sw $t4 1616($v1)
    sw $t4 2120($v1)
    sw $t4 3240($v1)
    li $t4 0xf9cf53
    sw $t4 1624($v1)
    sw $t4 1632($v1)
    li $t4 0x1d1809
    sw $t4 1636($v1)
    sw $t4 3192($v1)
    li $t4 0x5c4d1f
    sw $t4 1640($v1)
    sw $t4 2632($v1)
    li $t4 0xad9039
    sw $t4 1652($v1)
    li $t4 0x8c752f
    sw $t4 1660($v1)
    li $t4 0x907830
    sw $t4 1672($v1)
    li $t4 0x856f2c
    sw $t4 1676($v1)
    li $t4 0x191408
    sw $t4 1688($v1)
    sw $t4 2732($v1)
    li $t4 0xa18635
    sw $t4 1700($v1)
    li $t4 0x1a1609
    sw $t4 1716($v1)
    li $t4 0x6f5c25
    sw $t4 1720($v1)
    sw $t4 3124($v1)
    li $t4 0xe4be4c
    sw $t4 1724($v1)
    li $t4 0xdeb84a
    sw $t4 1728($v1)
    li $t4 0xb0933b
    sw $t4 1732($v1)
    li $t4 0xe9c24d
    sw $t4 1740($v1)
    sw $t4 1748($v1)
    li $t4 0x4c4019
    sw $t4 1744($v1)
    sw $t4 2256($v1)
    li $t4 0x060502
    sw $t4 2100($v1)
    li $t4 0x090703
    sw $t4 2104($v1)
    li $t4 0x2d260f
    sw $t4 2148($v1)
    li $t4 0x725f26
    draw4($t4, 2156, 2680, 3180, 3200)
    sw $t4 3204($v1)
    li $t4 0x4e411a
    sw $t4 2160($v1)
    sw $t4 3592($v1)
    li $t4 0xf2c950
    sw $t4 2172($v1)
    sw $t4 2232($v1)
    li $t4 0x413615
    sw $t4 2176($v1)
    sw $t4 3136($v1)
    li $t4 0x352c12
    sw $t4 2180($v1)
    li $t4 0x1a1509
    sw $t4 2188($v1)
    li $t4 0x4c3f19
    sw $t4 2196($v1)
    li $t4 0x3d3314
    sw $t4 2216($v1)
    sw $t4 2660($v1)
    li $t4 0x5e4e1f
    sw $t4 2236($v1)
    li $t4 0x130f06
    sw $t4 2240($v1)
    sw $t4 3212($v1)
    sw $t4 3232($v1)
    li $t4 0x7d6829
    sw $t4 2248($v1)
    li $t4 0xeac34e
    sw $t4 2252($v1)
    sw $t4 2260($v1)
    li $t4 0x6b5923
    sw $t4 2620($v1)
    sw $t4 3272($v1)
    li $t4 0x483c18
    sw $t4 2624($v1)
    li $t4 0xf1c950
    sw $t4 2648($v1)
    li $t4 0xf0c850
    sw $t4 2656($v1)
    sw $t4 2684($v1)
    li $t4 0x161207
    sw $t4 2688($v1)
    sw $t4 2700($v1)
    li $t4 0x3d3214
    sw $t4 2708($v1)
    li $t4 0x4b3e19
    sw $t4 2740($v1)
    li $t4 0x937a31
    sw $t4 2760($v1)
    li $t4 0xe8c14d
    sw $t4 2764($v1)
    sw $t4 2772($v1)
    li $t4 0x362d12
    sw $t4 3076($v1)
    li $t4 0x1a1508
    sw $t4 3096($v1)
    li $t4 0x54461c
    sw $t4 3116($v1)
    li $t4 0x7c6729
    sw $t4 3128($v1)
    li $t4 0xa98c38
    sw $t4 3144($v1)
    li $t4 0x5d4d1f
    sw $t4 3148($v1)
    li $t4 0x26200d
    sw $t4 3164($v1)
    li $t4 0x261f0c
    sw $t4 3172($v1)
    li $t4 0x816c2b
    sw $t4 3188($v1)
    li $t4 0x927a30
    sw $t4 3220($v1)
    li $t4 0x846e2c
    sw $t4 3244($v1)
    li $t4 0x28210d
    sw $t4 3252($v1)
    li $t4 0x675522
    sw $t4 3260($v1)
    li $t4 0x6c5a24
    sw $t4 3264($v1)
    li $t4 0x51441b
    sw $t4 3280($v1)
    sw $t4 3644($v1)
    li $t4 0x332a11
    sw $t4 3600($v1)
    sw $t4 3784($v1)
    sw $t4 3792($v1)
    li $t4 0x463a17
    sw $t4 3604($v1)
    li $t4 0x615120
    sw $t4 3632($v1)
    li $t4 0x181408
    sw $t4 3652($v1)
    sw $t4 3676($v1)
    sw $t4 3688($v1)
    li $t4 0x776327
    sw $t4 3664($v1)
    li $t4 0x151107
    sw $t4 3684($v1)
    li $t4 0x88712d
    sw $t4 3700($v1)
    li $t4 0x403515
    sw $t4 3720($v1)
    li $t4 0x796428
    sw $t4 3728($v1)
    li $t4 0x1d180a
    sw $t4 3736($v1)
    li $t4 0x9f8435
    sw $t4 3760($v1)
    li $t4 0x141007
    sw $t4 3764($v1)
    li $t4 0x251f0c
    sw $t4 3768($v1)
    li $t4 0x9e8334
    sw $t4 3788($v1)
    sw $t4 3796($v1)
    li $t4 0x535353
    draw64($t4, 5640, 5644, 5648, 5652, 6148, 6168, 6656, 6668, 6672, 6684, 6704, 6708, 6712, 6744, 6808, 7168, 7176, 7188, 7196, 7216, 7252, 7256, 7260, 7680, 7696, 7708, 7728, 7732, 7736, 7748, 7752, 7756, 7768, 7780, 7792, 7804, 7808, 7824, 7828, 7832, 7844, 7848, 7864, 7868, 7884, 7888, 8192, 8204, 8220, 8240, 8260, 8268, 8280, 8292, 8296, 8300, 8304, 8316, 8332, 8344, 8352, 8364, 8372, 8384)
    draw16($t4, 8396, 8704, 8716, 8720, 8724, 8732, 8752, 8772, 8780, 8792, 8804, 8828, 8844, 8856, 8876, 8884)
    draw16($t4, 8896, 8908, 9220, 9240, 9264, 9268, 9272, 9284, 9292, 9304, 9308, 9320, 9324, 9340, 9360, 9364)
    draw4($t4, 9368, 9380, 9384, 9400)
    draw4($t4, 9404, 9420, 9736, 9740)
    sw $t4 9744($v1)
    sw $t4 9748($v1)
    li $t4 0x1a1a1a
    sw $t4 5656($v1)
    sw $t4 9928($v1)
    li $t4 0x151515
    draw4($t4, 6144, 6156, 6700, 7200)
    draw4($t4, 7212, 7232, 7712, 8224)
    sw $t4 8328($v1)
    sw $t4 9260($v1)
    sw $t4 9332($v1)
    li $t4 0x1c1c1c
    draw4($t4, 6152, 7236, 7292, 7372)
    sw $t4 9876($v1)
    sw $t4 9880($v1)
    li $t4 0x1e1e1e
    sw $t4 6160($v1)
    sw $t4 9752($v1)
    li $t4 0x161616
    sw $t4 6164($v1)
    sw $t4 8820($v1)
    li $t4 0x212121
    sw $t4 6172($v1)
    sw $t4 6296($v1)
    sw $t4 9776($v1)
    li $t4 0x121212
    sw $t4 6660($v1)
    sw $t4 8708($v1)
    sw $t4 9792($v1)
    li $t4 0x080808
    sw $t4 6664($v1)
    sw $t4 8728($v1)
    li $t4 0x070707
    sw $t4 6676($v1)
    sw $t4 7740($v1)
    li $t4 0x0a0a0a
    sw $t4 6680($v1)
    li $t4 0x282828
    draw4($t4, 6716, 7724, 8236, 8244)
    sw $t4 8248($v1)
    sw $t4 8748($v1)
    sw $t4 9276($v1)
    li $t4 0x1f1f1f
    draw4($t4, 7180, 7184, 7700, 8208)
    draw4($t4, 9224, 9228, 9232, 9236)
    li $t4 0x010101
    sw $t4 7192($v1)
    sw $t4 7684($v1)
    sw $t4 7704($v1)
    li $t4 0x030303
    sw $t4 7220($v1)
    sw $t4 9884($v1)
    li $t4 0x050505
    sw $t4 7224($v1)
    sw $t4 8212($v1)
    sw $t4 9844($v1)
    li $t4 0x060606
    sw $t4 7228($v1)
    sw $t4 9392($v1)
    li $t4 0x242424
    draw4($t4, 7240, 7244, 7376, 7760)
    draw4($t4, 8812, 9780, 9836, 9892)
    li $t4 0x313131
    draw4($t4, 7268, 7744, 8800, 8824)
    sw $t4 9316($v1)
    li $t4 0x494949
    sw $t4 7272($v1)
    sw $t4 7276($v1)
    sw $t4 7820($v1)
    li $t4 0x1d1d1d
    draw4($t4, 7280, 7784, 7788, 7796)
    draw4($t4, 8308, 8816, 9328, 9816)
    li $t4 0x141414
    draw4($t4, 7288, 7776, 8840, 9312)
    sw $t4 9808($v1)
    li $t4 0x292929
    draw4($t4, 7296, 7312, 7772, 7852)
    draw4($t4, 7856, 7872, 7876, 9388)
    sw $t4 9408($v1)
    sw $t4 9872($v1)
    sw $t4 9896($v1)
    li $t4 0x2a2a2a
    sw $t4 7316($v1)
    li $t4 0x4f4f4f
    sw $t4 7320($v1)
    li $t4 0x262626
    sw $t4 7332($v1)
    sw $t4 8900($v1)
    li $t4 0x2b2b2b
    sw $t4 7336($v1)
    sw $t4 9916($v1)
    li $t4 0x222222
    sw $t4 7352($v1)
    sw $t4 8808($v1)
    li $t4 0x2c2c2c
    sw $t4 7356($v1)
    li $t4 0x191919
    draw4($t4, 7368, 8264, 8776, 9216)
    draw4($t4, 9288, 9788, 9796, 9804)
    li $t4 0x2f2f2f
    sw $t4 7764($v1)
    sw $t4 8256($v1)
    li $t4 0x2e2e2e
    sw $t4 7800($v1)
    sw $t4 8312($v1)
    sw $t4 8784($v1)
    li $t4 0x3b3b3b
    sw $t4 7840($v1)
    li $t4 0x343434
    sw $t4 7860($v1)
    li $t4 0x3d3d3d
    sw $t4 7880($v1)
    li $t4 0x0e0e0e
    sw $t4 8252($v1)
    sw $t4 8340($v1)
    sw $t4 8852($v1)
    li $t4 0x303030
    sw $t4 8272($v1)
    sw $t4 8288($v1)
    sw $t4 9820($v1)
    li $t4 0x0b0b0b
    sw $t4 8276($v1)
    li $t4 0x040404
    sw $t4 8336($v1)
    sw $t4 8848($v1)
    li $t4 0x181818
    sw $t4 8348($v1)
    sw $t4 9852($v1)
    li $t4 0x0f0f0f
    sw $t4 8356($v1)
    sw $t4 8868($v1)
    li $t4 0x252525
    draw4($t4, 8368, 8388, 8880, 9784)
    li $t4 0x1b1b1b
    sw $t4 8376($v1)
    sw $t4 8888($v1)
    li $t4 0x3a3a3a
    sw $t4 8392($v1)
    sw $t4 8904($v1)
    sw $t4 9376($v1)
    li $t4 0x424242
    sw $t4 8712($v1)
    sw $t4 9416($v1)
    li $t4 0x333333
    draw4($t4, 8768, 9280, 9296, 9396)
    li $t4 0x111111
    sw $t4 8788($v1)
    li $t4 0x171717
    sw $t4 8860($v1)
    sw $t4 9732($v1)
    li $t4 0x525252
    sw $t4 8864($v1)
    li $t4 0x232323
    sw $t4 9244($v1)
    li $t4 0x090909
    draw4($t4, 9300, 9372, 9412, 9900)
    li $t4 0x323232
    sw $t4 9336($v1)
    li $t4 0x484848
    sw $t4 9356($v1)
    li $t4 0x101010
    sw $t4 9828($v1)
    li $t4 0x2d2d2d
    sw $t4 9832($v1)
    li $t4 0x131313
    sw $t4 9848($v1)
    sw $t4 9932($v1)
    li $t4 0x020202
    sw $t4 9888($v1)
    sw $t4 9908($v1)
    li $t4 0x202020
    sw $t4 9912($v1)
    li $t4 0x0d0d0d
    sw $t4 9920($v1)
    jr $ra
draw_enter: # use t4
    li $v1 BASE_ADDRESS
    addi $v1 $v1 1312 # (72, 2)
    draw16($0, 0, 1032, 1044, 1048, 1540, 1556, 1588, 1592, 2056, 2068, 2108, 2112, 2564, 2584, 2612, 2616)
    draw16($0, 2636, 2752, 3080, 3092, 7172, 7688, 7692, 8200, 8284, 8360, 8380, 8756, 8760, 8764, 8796, 8872)
    draw4($0, 8892, 9728, 9800, 9812)
    draw4($0, 9824, 9840, 9904, 9924)
    li $t4 0x252525
    draw4($t4, 4, 1216, 2228, 2720)
    sw $t4 3708($v1)
    li $t4 0xa7a7a7
    draw64($t4, 8, 12, 16, 20, 516, 536, 564, 568, 1024, 1040, 1052, 1072, 1084, 1112, 1120, 1168, 1536, 1552, 1564, 1584, 1608, 1612, 1644, 1648, 1664, 1668, 1680, 1684, 1704, 1708, 2048, 2064, 2076, 2096, 2116, 2128, 2152, 2164, 2184, 2192, 2212, 2244, 2560, 2576, 2588, 2608, 2628, 2640, 2664, 2668, 2672, 2676, 2704, 2724, 2756, 3072, 3088, 3100, 3120, 3132, 3140, 3152, 3160, 3168)
    draw16($t4, 3176, 3196, 3208, 3216, 3236, 3248, 3256, 3268, 3588, 3608, 3636, 3640, 3656, 3660, 3672, 3680)
    draw4($t4, 3692, 3696, 3712, 3716)
    draw4($t4, 3732, 3752, 3756, 3772)
    draw4($t4, 3776, 4104, 4108, 4112)
    sw $t4 4116($v1)
    li $t4 0x353535
    sw $t4 24($v1)
    li $t4 0x1c1c1c
    draw4($t4, 88, 1124, 1212, 2748)
    li $t4 0x030303
    sw $t4 92($v1)
    sw $t4 1028($v1)
    li $t4 0x161616
    draw4($t4, 96, 176, 1096, 3612)
    li $t4 0x141414
    sw $t4 212($v1)
    sw $t4 3736($v1)
    li $t4 0x282828
    sw $t4 512($v1)
    sw $t4 2220($v1)
    li $t4 0x0a0a0a
    sw $t4 520($v1)
    li $t4 0x1d1d1d
    sw $t4 524($v1)
    li $t4 0x333333
    draw4($t4, 528, 1744, 2196, 2256)
    li $t4 0x010101
    draw4($t4, 532, 1544, 1560, 2052)
    sw $t4 2072($v1)
    sw $t4 2568($v1)
    sw $t4 2580($v1)
    li $t4 0x3c3c3c
    sw $t4 540($v1)
    sw $t4 3780($v1)
    li $t4 0x494949
    draw4($t4, 560, 1080, 1172, 2168)
    li $t4 0x404040
    sw $t4 572($v1)
    li $t4 0xa4a4a4
    draw4($t4, 600, 688, 1712, 2136)
    sw $t4 2144($v1)
    sw $t4 2224($v1)
    li $t4 0x181818
    draw4($t4, 604, 692, 1056, 1116)
    draw4($t4, 1628, 2132, 2140, 2644)
    sw $t4 2652($v1)
    sw $t4 3156($v1)
    li $t4 0xa3a3a3
    sw $t4 608($v1)
    sw $t4 2744($v1)
    li $t4 0x1a1a1a
    draw4($t4, 612, 1132, 1204, 2208)
    sw $t4 3164($v1)
    li $t4 0x2e2e2e
    sw $t4 656($v1)
    sw $t4 3604($v1)
    li $t4 0x1f1f1f
    sw $t4 684($v1)
    sw $t4 1164($v1)
    sw $t4 3596($v1)
    li $t4 0x323232
    draw4($t4, 712, 720, 1604, 2740)
    sw $t4 2768($v1)
    sw $t4 3184($v1)
    sw $t4 3748($v1)
    li $t4 0x9b9b9b
    draw4($t4, 716, 724, 2764, 2772)
    li $t4 0x646464
    draw4($t4, 1036, 1548, 1580, 2060)
    draw4($t4, 2092, 2572, 2604, 3084)
    li $t4 0x3b3b3b
    sw $t4 1068($v1)
    li $t4 0x434343
    sw $t4 1076($v1)
    li $t4 0x343434
    draw4($t4, 1088, 1196, 1224, 1232)
    sw $t4 1736($v1)
    sw $t4 2160($v1)
    sw $t4 3592($v1)
    li $t4 0x2a2a2a
    draw4($t4, 1100, 1568, 2080, 2592)
    li $t4 0x272727
    sw $t4 1136($v1)
    li $t4 0x202020
    sw $t4 1152($v1)
    li $t4 0x212121
    sw $t4 1156($v1)
    li $t4 0x232323
    sw $t4 1192($v1)
    sw $t4 2180($v1)
    li $t4 0xa6a6a6
    draw4($t4, 1200, 1624, 1632, 3276)
    sw $t4 3284($v1)
    li $t4 0x9e9e9e
    sw $t4 1228($v1)
    sw $t4 1236($v1)
    sw $t4 2736($v1)
    li $t4 0x454545
    sw $t4 1596($v1)
    sw $t4 3260($v1)
    li $t4 0x292929
    draw4($t4, 1600, 2216, 2660, 2708)
    li $t4 0x606060
    draw4($t4, 1616, 1672, 2120, 3240)
    li $t4 0x131313
    sw $t4 1636($v1)
    sw $t4 3192($v1)
    li $t4 0x3e3e3e
    sw $t4 1640($v1)
    sw $t4 2632($v1)
    sw $t4 3148($v1)
    li $t4 0x737373
    sw $t4 1652($v1)
    li $t4 0x5e5e5e
    sw $t4 1660($v1)
    li $t4 0x595959
    sw $t4 1676($v1)
    li $t4 0x6b6b6b
    sw $t4 1700($v1)
    li $t4 0x121212
    sw $t4 1716($v1)
    li $t4 0x4a4a4a
    sw $t4 1720($v1)
    sw $t4 3124($v1)
    li $t4 0x999999
    sw $t4 1724($v1)
    li $t4 0x949494
    sw $t4 1728($v1)
    li $t4 0x767676
    sw $t4 1732($v1)
    li $t4 0x9c9c9c
    sw $t4 1740($v1)
    sw $t4 1748($v1)
    li $t4 0x040404
    sw $t4 2100($v1)
    li $t4 0x060606
    sw $t4 2104($v1)
    sw $t4 2728($v1)
    li $t4 0x070707
    sw $t4 2124($v1)
    li $t4 0x1e1e1e
    sw $t4 2148($v1)
    li $t4 0x4c4c4c
    draw4($t4, 2156, 2680, 3180, 3200)
    sw $t4 3204($v1)
    li $t4 0xa2a2a2
    sw $t4 2172($v1)
    sw $t4 2232($v1)
    li $t4 0x2b2b2b
    sw $t4 2176($v1)
    sw $t4 3136($v1)
    sw $t4 3720($v1)
    li $t4 0x3f3f3f
    sw $t4 2236($v1)
    li $t4 0x0c0c0c
    sw $t4 2240($v1)
    li $t4 0x535353
    sw $t4 2248($v1)
    sw $t4 3128($v1)
    li $t4 0x9d9d9d
    sw $t4 2252($v1)
    sw $t4 2260($v1)
    li $t4 0x474747
    sw $t4 2620($v1)
    sw $t4 3272($v1)
    li $t4 0x303030
    sw $t4 2624($v1)
    li $t4 0xa1a1a1
    sw $t4 2648($v1)
    li $t4 0xa0a0a0
    sw $t4 2656($v1)
    sw $t4 2684($v1)
    li $t4 0x101010
    sw $t4 2732($v1)
    li $t4 0x626262
    sw $t4 2760($v1)
    sw $t4 3220($v1)
    li $t4 0x242424
    sw $t4 3076($v1)
    li $t4 0x111111
    sw $t4 3096($v1)
    li $t4 0x383838
    sw $t4 3116($v1)
    li $t4 0x717171
    sw $t4 3144($v1)
    li $t4 0x191919
    sw $t4 3172($v1)
    sw $t4 3768($v1)
    li $t4 0x565656
    sw $t4 3188($v1)
    li $t4 0x585858
    sw $t4 3244($v1)
    li $t4 0x1b1b1b
    sw $t4 3252($v1)
    li $t4 0x484848
    sw $t4 3264($v1)
    li $t4 0x363636
    sw $t4 3280($v1)
    sw $t4 3644($v1)
    li $t4 0x222222
    sw $t4 3600($v1)
    sw $t4 3784($v1)
    sw $t4 3792($v1)
    li $t4 0x414141
    sw $t4 3632($v1)
    li $t4 0x4f4f4f
    sw $t4 3664($v1)
    li $t4 0x5b5b5b
    sw $t4 3700($v1)
    li $t4 0x515151
    sw $t4 3728($v1)
    li $t4 0x6a6a6a
    sw $t4 3760($v1)
    li $t4 0x696969
    sw $t4 3788($v1)
    sw $t4 3796($v1)
    li $t4 0x372e12
    sw $t4 5636($v1)
    sw $t4 9792($v1)
    li $t4 0xfad053
    draw64($t4, 5640, 5644, 5648, 5652, 6148, 6168, 6656, 6668, 6672, 6684, 6704, 6708, 6712, 6744, 6808, 7168, 7176, 7188, 7196, 7216, 7252, 7256, 7260, 7680, 7696, 7708, 7728, 7732, 7736, 7748, 7752, 7756, 7768, 7780, 7792, 7804, 7808, 7824, 7828, 7832, 7844, 7848, 7864, 7868, 7884, 7888, 8192, 8204, 8220, 8240, 8260, 8268, 8280, 8292, 8296, 8300, 8304, 8316, 8332, 8344, 8352, 8364, 8372, 8384)
    draw16($t4, 8396, 8704, 8716, 8720, 8724, 8732, 8752, 8772, 8780, 8792, 8804, 8828, 8844, 8856, 8876, 8884)
    draw16($t4, 8896, 8908, 9220, 9240, 9264, 9268, 9272, 9284, 9292, 9304, 9308, 9320, 9324, 9340, 9360, 9364)
    draw4($t4, 9368, 9380, 9384, 9400)
    draw4($t4, 9404, 9420, 9736, 9740)
    sw $t4 9744($v1)
    sw $t4 9748($v1)
    li $t4 0x4f421a
    sw $t4 5656($v1)
    li $t4 0x3f3415
    sw $t4 6144($v1)
    li $t4 0x53451c
    sw $t4 6152($v1)
    sw $t4 7236($v1)
    li $t4 0x3f3515
    sw $t4 6156($v1)
    li $t4 0x5a4b1e
    sw $t4 6160($v1)
    li $t4 0x413616
    sw $t4 6164($v1)
    sw $t4 8820($v1)
    li $t4 0x635221
    sw $t4 6172($v1)
    sw $t4 6296($v1)
    li $t4 0x1f1a0a
    sw $t4 6192($v1)
    li $t4 0x211c0b
    sw $t4 6196($v1)
    sw $t4 8276($v1)
    li $t4 0x231d0c
    sw $t4 6200($v1)
    sw $t4 6812($v1)
    li $t4 0x1a1508
    sw $t4 6204($v1)
    sw $t4 8728($v1)
    li $t4 0x191408
    sw $t4 6292($v1)
    sw $t4 6740($v1)
    li $t4 0x362d12
    sw $t4 6660($v1)
    sw $t4 8708($v1)
    li $t4 0x181408
    sw $t4 6664($v1)
    li $t4 0x141007
    sw $t4 6676($v1)
    li $t4 0x1d180a
    sw $t4 6680($v1)
    li $t4 0x28210d
    sw $t4 6688($v1)
    li $t4 0x3e3315
    draw4($t4, 6700, 7200, 7212, 7232)
    draw4($t4, 7712, 8224, 8328, 9260)
    li $t4 0x786428
    draw4($t4, 6716, 7724, 8236, 8244)
    sw $t4 8248($v1)
    sw $t4 8748($v1)
    sw $t4 9276($v1)
    li $t4 0x2e270f
    sw $t4 6804($v1)
    li $t4 0x5b4c1f
    draw4($t4, 7180, 7184, 7700, 8208)
    draw4($t4, 9224, 9228, 9232, 9236)
    li $t4 0x020201
    sw $t4 7192($v1)
    sw $t4 7684($v1)
    sw $t4 7704($v1)
    li $t4 0x0a0803
    sw $t4 7220($v1)
    li $t4 0x0f0c05
    sw $t4 7224($v1)
    sw $t4 8212($v1)
    li $t4 0x120f06
    sw $t4 7228($v1)
    sw $t4 9392($v1)
    li $t4 0x6e5b24
    draw4($t4, 7240, 7244, 7376, 7760)
    sw $t4 9892($v1)
    li $t4 0x937a31
    sw $t4 7268($v1)
    sw $t4 8800($v1)
    sw $t4 9316($v1)
    li $t4 0xdcb749
    sw $t4 7272($v1)
    sw $t4 7276($v1)
    sw $t4 7820($v1)
    li $t4 0x56481d
    draw4($t4, 7280, 7784, 7788, 7796)
    sw $t4 8308($v1)
    sw $t4 8816($v1)
    sw $t4 9328($v1)
    li $t4 0x3d3214
    sw $t4 7288($v1)
    li $t4 0x55471c
    sw $t4 7292($v1)
    li $t4 0x7c6729
    draw4($t4, 7296, 7312, 7772, 7852)
    draw4($t4, 7856, 7872, 7876, 9388)
    sw $t4 9408($v1)
    sw $t4 9872($v1)
    li $t4 0x251f0d
    sw $t4 7308($v1)
    li $t4 0x7f6a2a
    sw $t4 7316($v1)
    li $t4 0xedc54f
    sw $t4 7320($v1)
    li $t4 0x1c1709
    sw $t4 7324($v1)
    li $t4 0x725f26
    sw $t4 7332($v1)
    li $t4 0x816c2b
    sw $t4 7336($v1)
    li $t4 0x1f190a
    sw $t4 7340($v1)
    li $t4 0x655422
    sw $t4 7352($v1)
    sw $t4 8808($v1)
    li $t4 0x846e2c
    sw $t4 7356($v1)
    li $t4 0x29220e
    sw $t4 7360($v1)
    sw $t4 8340($v1)
    li $t4 0x4b3e19
    sw $t4 7368($v1)
    sw $t4 9788($v1)
    sw $t4 9796($v1)
    li $t4 0x54461c
    sw $t4 7372($v1)
    sw $t4 9876($v1)
    sw $t4 9880($v1)
    li $t4 0x171307
    sw $t4 7740($v1)
    li $t4 0x947b31
    sw $t4 7744($v1)
    sw $t4 8824($v1)
    li $t4 0x8c752f
    sw $t4 7764($v1)
    li $t4 0x3d3314
    sw $t4 7776($v1)
    li $t4 0x8b742e
    sw $t4 7800($v1)
    li $t4 0x1b1609
    sw $t4 7836($v1)
    li $t4 0xb1943b
    sw $t4 7840($v1)
    li $t4 0x9d8334
    sw $t4 7860($v1)
    li $t4 0xb8993d
    sw $t4 7880($v1)
    li $t4 0x010100
    sw $t4 8196($v1)
    sw $t4 8216($v1)
    li $t4 0x2b240e
    sw $t4 8252($v1)
    li $t4 0x8e762f
    sw $t4 8256($v1)
    li $t4 0x4c3f19
    draw4($t4, 8264, 8776, 9288, 9804)
    li $t4 0x8f7730
    sw $t4 8272($v1)
    li $t4 0x917930
    sw $t4 8288($v1)
    li $t4 0x89722e
    sw $t4 8312($v1)
    li $t4 0x0b0904
    sw $t4 8336($v1)
    li $t4 0x493c18
    sw $t4 8348($v1)
    li $t4 0x2d260f
    sw $t4 8356($v1)
    sw $t4 8868($v1)
    li $t4 0x6f5c25
    sw $t4 8368($v1)
    li $t4 0x51441b
    sw $t4 8376($v1)
    li $t4 0x715e25
    sw $t4 8388($v1)
    sw $t4 8880($v1)
    sw $t4 9784($v1)
    li $t4 0xae903a
    sw $t4 8392($v1)
    li $t4 0xc7a642
    sw $t4 8712($v1)
    li $t4 0x312910
    sw $t4 8736($v1)
    li $t4 0x9b8133
    sw $t4 8768($v1)
    sw $t4 9280($v1)
    li $t4 0x8a732e
    sw $t4 8784($v1)
    li $t4 0x332a11
    sw $t4 8788($v1)
    li $t4 0x6d5b24
    sw $t4 8812($v1)
    sw $t4 9780($v1)
    li $t4 0x3c3214
    sw $t4 8840($v1)
    sw $t4 9312($v1)
    li $t4 0x0c0a04
    sw $t4 8848($v1)
    li $t4 0x2a230e
    sw $t4 8852($v1)
    li $t4 0x473b17
    sw $t4 8860($v1)
    sw $t4 9732($v1)
    li $t4 0xf8ce52
    sw $t4 8864($v1)
    li $t4 0x52451b
    sw $t4 8888($v1)
    li $t4 0x746026
    sw $t4 8900($v1)
    li $t4 0xaf913a
    sw $t4 8904($v1)
    sw $t4 9376($v1)
    li $t4 0x4c4019
    sw $t4 9216($v1)
    li $t4 0x6a5823
    sw $t4 9244($v1)
    li $t4 0x997f33
    sw $t4 9296($v1)
    li $t4 0x1b1709
    sw $t4 9300($v1)
    sw $t4 9900($v1)
    li $t4 0x403515
    sw $t4 9332($v1)
    li $t4 0x977e32
    sw $t4 9336($v1)
    li $t4 0xd9b448
    sw $t4 9356($v1)
    li $t4 0x1d1809
    sw $t4 9372($v1)
    li $t4 0x9a8033
    sw $t4 9396($v1)
    li $t4 0x1c1809
    sw $t4 9412($v1)
    li $t4 0xc8a642
    sw $t4 9416($v1)
    li $t4 0x5b4c1e
    sw $t4 9752($v1)
    li $t4 0x352c12
    sw $t4 9772($v1)
    li $t4 0x645321
    sw $t4 9776($v1)
    li $t4 0x3b3114
    sw $t4 9808($v1)
    li $t4 0x57491d
    sw $t4 9816($v1)
    li $t4 0x927a30
    sw $t4 9820($v1)
    li $t4 0x2f2710
    sw $t4 9828($v1)
    li $t4 0x88712d
    sw $t4 9832($v1)
    li $t4 0x6c5a24
    sw $t4 9836($v1)
    li $t4 0x0e0b05
    sw $t4 9844($v1)
    li $t4 0x3a3013
    sw $t4 9848($v1)
    sw $t4 9932($v1)
    li $t4 0x4a3d18
    sw $t4 9852($v1)
    li $t4 0x1e190a
    sw $t4 9868($v1)
    li $t4 0x090703
    sw $t4 9884($v1)
    li $t4 0x070602
    sw $t4 9888($v1)
    li $t4 0x7d6829
    sw $t4 9896($v1)
    li $t4 0x050402
    sw $t4 9908($v1)
    li $t4 0x615120
    sw $t4 9912($v1)
    li $t4 0x826c2b
    sw $t4 9916($v1)
    li $t4 0x26200d
    sw $t4 9920($v1)
    li $t4 0x4d401a
    sw $t4 9928($v1)
    jr $ra

draw_stage: # use v1 t0-t9
    lw $t9 stage
    li $v1 BASE_ADDRESS
    li $t0 0x887143
    li $t1 0xaf8f55
    li $t2 0xc29d62
    li $t3 0x967441
    li $t4 0x9f844d
    li $t5 0x7d6739
    li $t6 0x7e6237
    li $t7 0x846d40
    li $t8 0xb8945f
    draw16($t0, 12288, 12316, 12356, 12800, 12844, 12896, 12908, 13328, 13376, 51428, 51440, 51476, 51928, 51944, 51952, 51956)
    draw16($t0, 51984, 51988, 52008, 52432, 52480, 52520, 52524, 52944, 52968, 53024, 53036, 63556, 63604, 63948, 63988, 64040)
    draw16($t0, 64060, 64084, 64112, 64424, 64440, 64476, 64488, 64532, 64544, 64560, 64564, 64608, 64632, 64636, 64956, 65056)
    draw4($t0, 65060, 65076, 65100, 65132)
    sw $t0 65500($v1)
    sw $t0 65508($v1)
    sw $t0 65532($v1)
    draw16($t1, 12352, 12392, 12400, 12404, 12808, 12828, 12900, 13336, 13364, 13844, 13852, 13896, 13920, 13948, 51432, 51444)
    draw16($t1, 51480, 51972, 52000, 52012, 52512, 63500, 63532, 63572, 63956, 63984, 63996, 64000, 64036, 64048, 64416, 64444)
    draw4($t1, 64452, 64512, 64624, 64932)
    draw4($t1, 64972, 64988, 65012, 65032)
    draw4($t1, 65104, 65424, 65444, 65464)
    sw $t1 65472($v1)
    sw $t1 65492($v1)
    sw $t1 65516($v1)
    draw64($t2, 12320, 12332, 12412, 12880, 12892, 12912, 13344, 13352, 13384, 13396, 13432, 13832, 13836, 13848, 13856, 13868, 13892, 13908, 13912, 13924, 13940, 51408, 51472, 51484, 51488, 51492, 51980, 52444, 52460, 52464, 52468, 52476, 52496, 52960, 52964, 52984, 53004, 53008, 63520, 63524, 63560, 63892, 63912, 63920, 63924, 63964, 64008, 64044, 64052, 64088, 64104, 64480, 64496, 64500, 64516, 64552, 64556, 64568, 64576, 64588, 64596, 64600, 64604, 64616)
    draw4($t2, 64912, 65004, 65040, 65052)
    sw $t2 65096($v1)
    sw $t2 65520($v1)
    draw16($t3, 12292, 12348, 12368, 12384, 12408, 12876, 12904, 13340, 13388, 13404, 13416, 13428, 13880, 13916, 13928, 51416)
    draw16($t3, 51468, 51924, 52436, 52440, 52484, 52996, 53012, 53032, 63492, 63516, 63548, 63568, 63600, 63932, 64020, 64116)
    draw4($t3, 64124, 64412, 64436, 64524)
    draw4($t3, 64528, 64580, 64916, 65008)
    draw4($t3, 65028, 65084, 65088, 65116)
    sw $t3 65432($v1)
    draw16($t4, 12328, 12336, 12340, 12372, 12376, 12840, 12860, 12872, 12884, 12916, 13356, 13828, 13936, 51436, 51992, 52452)
    draw16($t4, 52456, 52952, 52956, 52980, 52992, 63496, 63588, 63888, 63896, 63904, 63992, 64012, 64024, 64032, 64080, 64092)
    draw16($t4, 64096, 64100, 64120, 64448, 64468, 64504, 64572, 64924, 64944, 64992, 65000, 65124, 65428, 65436, 65452, 65456)
    sw $t4 65496($v1)
    sw $t4 65512($v1)
    draw16($t5, 12300, 12380, 12396, 12804, 12812, 12824, 12836, 12848, 12864, 13348, 13408, 13436, 13872, 13888, 51412, 51420)
    draw16($t5, 51452, 51496, 51996, 52448, 52488, 52492, 52500, 53000, 53028, 63488, 63504, 63968, 63972, 64016, 64028, 64056)
    draw16($t5, 64432, 64612, 64628, 64960, 64968, 64976, 64980, 65016, 65048, 65064, 65068, 65136, 65144, 65440, 65468, 65480)
    sw $t5 65504($v1)
    draw16($t6, 12344, 12388, 12832, 13316, 13324, 13332, 13360, 13368, 13840, 13864, 13884, 13900, 13904, 13944, 51424, 51448)
    draw16($t6, 51456, 51460, 51500, 51940, 52976, 53016, 63508, 63512, 63552, 63576, 63612, 63952, 63960, 63980, 64064, 64068)
    draw16($t6, 64072, 64108, 64408, 64428, 64472, 64508, 64520, 64592, 64620, 64940, 64964, 65036, 65120, 65148, 65448, 65488)
    sw $t6 65524($v1)
    draw16($t7, 12304, 12308, 12312, 12360, 12852, 12868, 12888, 12920, 13312, 13320, 13380, 13392, 13424, 13824, 13860, 51920)
    draw16($t7, 51936, 51960, 51964, 51968, 52472, 52504, 52516, 52948, 52972, 52988, 63528, 63544, 63580, 63596, 63900, 63916)
    draw16($t7, 63928, 63936, 63976, 64400, 64456, 64460, 64484, 64492, 64548, 64584, 64920, 64948, 64952, 65020, 65024, 65072)
    draw4($t7, 65092, 65108, 65112, 65460)
    sw $t7 65476($v1)
    draw16($t8, 12296, 12324, 12364, 12816, 12820, 12856, 12924, 13372, 13400, 13412, 13420, 13876, 13932, 51464, 51932, 51948)
    draw16($t8, 51976, 52004, 52508, 53020, 63536, 63540, 63564, 63584, 63592, 63608, 63908, 63940, 63944, 64004, 64076, 64404)
    draw4($t8, 64420, 64464, 64536, 64540)
    draw4($t8, 64928, 64936, 64984, 64996)
    draw4($t8, 65044, 65080, 65128, 65140)
    sw $t8 65484($v1)
    sw $t8 65528($v1)
    beq $t9 0 jrra # end of stage 0
    draw16($t0, 0, 1048, 1072, 1172, 1196, 1564, 1608, 23056, 24, 26652, 48, 52, 520, 56, 604, 64)
    draw4($t0, 656, 680, 684, 72)
    draw16($t1, 1028, 1088, 1100, 1144, 116, 1180, 120, 136, 148, 1544, 1588, 1688, 1692, 1696, 22544, 23068)
    draw4($t1, 26140, 26640, 27152, 27668)
    draw4($t1, 28184, 28688, 512, 576)
    draw4($t1, 596, 620, 648, 80)
    sw $t1 96($v1)
    draw16($t2, 1068, 1152, 12, 1536, 1540, 1556, 1656, 1700, 22548, 22556, 23576, 24596, 25108, 26132, 26136, 27672)
    draw4($t2, 540, 560, 60, 600)
    draw4($t2, 608, 624, 636, 668)
    draw16($t3, 1040, 1056, 1060, 1080, 1096, 1124, 1128, 1132, 1176, 1192, 1572, 1584, 1596, 1624, 23064, 23568)
    draw16($t3, 23572, 24600, 24604, 25104, 25624, 26648, 27156, 27664, 28, 28696, 29204, 29208, 29212, 30232, 548, 552)
    draw4($t3, 556, 584, 592, 640)
    sw $t3 676($v1)
    draw16($t4, 112, 1548, 1552, 1568, 1580, 1640, 1708, 172, 20, 23580, 24088, 25616, 25620, 27164, 29200, 30224)
    sw $t4 40($v1)
    sw $t4 588($v1)
    sw $t4 76($v1)
    draw16($t5, 100, 1024, 1036, 1052, 108, 1092, 1108, 124, 132, 152, 1592, 1612, 1664, 168, 1684, 23060)
    draw16($t5, 24084, 24092, 25112, 25116, 25628, 26128, 27160, 27676, 4, 536, 568, 572, 580, 628, 644, 652)
    sw $t5 660($v1)
    draw16($t6, 1032, 104, 1044, 1064, 1156, 1164, 1184, 128, 156, 1560, 160, 1628, 1632, 164, 1648, 1660)
    draw4($t6, 1672, 1680, 28180, 29716)
    draw4($t6, 30236, 36, 616, 672)
    sw $t6 8($v1)
    draw16($t7, 1076, 1112, 1140, 1148, 1160, 1168, 1576, 1620, 1644, 1652, 1668, 1704, 22552, 24080, 24592, 26644)
    draw4($t7, 28188, 28700, 29712, 29720)
    draw4($t7, 29724, 516, 524, 528)
    draw4($t7, 532, 564, 664, 88)
    sw $t7 92($v1)
    draw16($t8, 1084, 1104, 1116, 1120, 1136, 1188, 140, 144, 16, 1600, 1604, 1616, 1636, 1676, 28176, 28692)
    draw4($t8, 30228, 32, 44, 544)
    draw4($t8, 612, 632, 68, 84)
    beq $t9 4 jrra # end of stage 1
    draw16($t0, 5144, 53472, 55016, 55020, 55296, 55300, 55812, 55816, 56832, 57868, 59392, 59912, 7704, 8720, 8724, 8732)
    sw $t0 9232($v1)
    sw $t0 9244($v1)
    sw $t0 9748($v1)
    draw16($t1, 4124, 54504, 55008, 55520, 55524, 55820, 56036, 56328, 5652, 57064, 57344, 57864, 61452, 7184, 7708, 9236)
    sw $t1 9744($v1)
    draw4($t2, 4116, 53480, 53996, 56044)
    draw4($t2, 57056, 57356, 57860, 58380)
    draw4($t2, 61444, 6160, 61952, 62980)
    sw $t2 6672($v1)
    sw $t2 7188($v1)
    sw $t2 9240($v1)
    draw16($t3, 4120, 5136, 5140, 53484, 55304, 56548, 56836, 57068, 57352, 58372, 58884, 58892, 59404, 59908, 59916, 60420)
    draw4($t3, 61956, 62468, 62476, 62976)
    draw4($t3, 62988, 7196, 9752, 9756)
    draw4($t4, 4632, 5148, 55528, 5648)
    draw4($t4, 56840, 61440, 62984, 6676)
    sw $t4 6680($v1)
    sw $t4 7192($v1)
    sw $t4 7700($v1)
    draw4($t5, 53984, 54496, 54500, 56040)
    draw4($t5, 56552, 57348, 6684, 8208)
    draw16($t6, 4112, 53988, 53992, 54508, 56320, 56324, 56556, 57060, 58376, 58888, 59400, 60424, 60928, 60932, 61960, 61964)
    sw $t6 8216($v1)
    draw4($t7, 4624, 53476, 55308, 56032)
    draw4($t7, 5656, 5660, 56844, 58880)
    draw4($t7, 60416, 60940, 6164, 62472)
    sw $t7 8212($v1)
    sw $t7 8728($v1)
    draw16($t8, 4628, 4636, 55012, 55532, 55808, 56332, 56544, 57856, 58368, 59396, 59904, 60428, 60936, 61448, 6168, 6172)
    sw $t8 62464($v1)
    sw $t8 7696($v1)
    sw $t8 8220($v1)
    beq $t9 8 jrra # end of stage 2
    draw16($t0, 14548, 14556, 15572, 18652, 19160, 21208, 21724, 22748, 23768, 25808, 26320, 26836, 29904, 30936, 31448, 31956)
    draw4($t0, 33496, 34516, 35024, 35536)
    draw4($t0, 37072, 38608, 40152, 40664)
    draw16($t1, 18128, 18140, 18644, 21204, 22232, 22236, 24284, 27860, 28372, 30428, 30940, 31452, 35540, 37080, 37588, 39640)
    sw $t1 39644($v1)
    sw $t1 40668($v1)
    draw16($t2, 17116, 17628, 18132, 19156, 20184, 21712, 22736, 24792, 26832, 26840, 26844, 27856, 27868, 28380, 28884, 29908)
    draw4($t2, 31440, 34520, 36564, 37584)
    sw $t2 39128($v1)
    sw $t2 39132($v1)
    sw $t2 40148($v1)
    draw4($t3, 15060, 20176, 22744, 23256)
    draw4($t3, 23760, 24272, 25296, 25308)
    draw4($t3, 26328, 27864, 29396, 30420)
    sw $t3 31444($v1)
    sw $t3 32476($v1)
    sw $t3 39120($v1)
    draw16($t4, 15056, 16088, 17112, 19164, 19664, 19668, 19676, 20696, 20700, 22224, 23772, 25300, 25820, 32464, 32984, 32988)
    draw4($t4, 33500, 35032, 36060, 40156)
    draw16($t5, 14552, 15068, 16596, 16600, 18136, 18648, 20180, 20188, 20692, 21200, 21720, 22228, 23248, 23252, 24280, 26332)
    draw4($t5, 28376, 28880, 29404, 30928)
    draw4($t5, 30932, 31952, 32976, 36056)
    sw $t5 36572($v1)
    sw $t5 40660($v1)
    draw16($t6, 15576, 16092, 21716, 24784, 24788, 24796, 25816, 26324, 27352, 27356, 28368, 29392, 29400, 29912, 32980, 33492)
    draw4($t6, 34000, 34008, 34524, 35028)
    draw4($t6, 35544, 36052, 37076, 37596)
    sw $t6 38096($v1)
    sw $t6 38108($v1)
    sw $t6 40144($v1)
    draw16($t7, 14544, 15568, 16084, 16604, 17104, 17616, 17620, 18640, 19672, 20688, 21212, 22740, 23260, 23764, 25812, 27344)
    draw16($t7, 28888, 28892, 29916, 30416, 31964, 32468, 32472, 33488, 34512, 35036, 35548, 36560, 37084, 37592, 38104, 38612)
    draw4($t7, 38620, 39124, 39632, 39636)
    sw $t7 40656($v1)
    draw16($t8, 15064, 15580, 16080, 16592, 17108, 17624, 19152, 24276, 25304, 27348, 30424, 31960, 34004, 34012, 36048, 36568)
    sw $t8 38100($v1)
    sw $t8 38616($v1)
    beq $t9 12 jrra # end of stage 3
    draw16($t0, 38200, 39220, 39728, 40244, 40756, 40764, 41264, 43316, 43828, 44348, 46392, 47412, 47920, 48436, 48444, 49464)
    draw4($t0, 50492, 53044, 53048, 57572)
    draw4($t0, 59112, 59628, 62188, 65248)
    draw16($t1, 38708, 39228, 40752, 42804, 43324, 44344, 44852, 45884, 46908, 47408, 49468, 49980, 50484, 50992, 51512, 52528)
    draw4($t1, 53040, 58092, 58592, 59108)
    sw $t1 61160($v1)
    sw $t1 63712($v1)
    sw $t1 63716($v1)
    draw16($t2, 37692, 38704, 39224, 39732, 42808, 42812, 43320, 45368, 45880, 51000, 51516, 52536, 57576, 58596, 58600, 61152)
    draw4($t2, 61672, 61676, 62688, 64736)
    draw16($t3, 43824, 44336, 44860, 45364, 46384, 48952, 48956, 49972, 51004, 51504, 52028, 53052, 57580, 58084, 58088, 59116)
    draw4($t3, 60136, 63200, 63212, 64228)
    sw $t3 64236($v1)
    sw $t3 65252($v1)
    draw4($t4, 38192, 40252, 42296, 42800)
    draw4($t4, 43836, 45360, 47416, 47420)
    draw4($t4, 52020, 57568, 60652, 61164)
    sw $t4 62184($v1)
    sw $t4 63724($v1)
    sw $t4 64740($v1)
    draw16($t5, 37172, 38204, 41268, 41276, 41776, 41788, 42288, 45872, 46896, 49456, 51508, 52532, 58080, 60132, 60140, 61156)
    sw $t5 62176($v1)
    sw $t5 63208($v1)
    sw $t5 65256($v1)
    draw16($t6, 37180, 37680, 39216, 39736, 39740, 40240, 41780, 44856, 45372, 45876, 46388, 46396, 47928, 47932, 48440, 48948)
    draw4($t6, 49460, 49968, 49976, 52016)
    draw4($t6, 52024, 59616, 60640, 62700)
    sw $t6 63204($v1)
    sw $t6 64224($v1)
    sw $t6 65260($v1)
    draw16($t7, 37684, 38716, 40248, 40760, 41272, 41784, 44848, 47924, 48944, 50480, 50488, 52540, 58604, 59624, 60648, 61664)
    sw $t7 61668($v1)
    sw $t7 62180($v1)
    sw $t7 64744($v1)
    draw16($t8, 37168, 37176, 37688, 38196, 38712, 42292, 42300, 43312, 43832, 44340, 46900, 46904, 48432, 50996, 59104, 59620)
    draw4($t8, 60128, 60644, 62692, 62696)
    sw $t8 63720($v1)
    sw $t8 64232($v1)
    sw $t8 64748($v1)
    jr $ra # return
draw_door: # start at v1, use t4
    li $t4 0x7d4400
    draw4($t4, 0, 44, 4608, 8748)
    sw $t4 11264($v1)
    sw $t4 11776($v1)
    sw $t4 11820($v1)
    li $t4 0x754000
    sw $t4 4($v1)
    li $t4 0x713d00
    sw $t4 8($v1)
    sw $t4 36($v1)
    li $t4 0x6e3a00
    sw $t4 12($v1)
    li $t4 0x6e3800
    sw $t4 16($v1)
    li $t4 0x733f00
    sw $t4 20($v1)
    li $t4 0x733e00
    sw $t4 24($v1)
    li $t4 0x6f3b00
    sw $t4 28($v1)
    li $t4 0x6d3800
    sw $t4 32($v1)
    li $t4 0x764100
    sw $t4 40($v1)
    li $t4 0x844800
    sw $t4 512($v1)
    li $t4 0xa6690d
    sw $t4 516($v1)
    sw $t4 8196($v1)
    li $t4 0xa0640d
    sw $t4 520($v1)
    sw $t4 8200($v1)
    li $t4 0xa86a0d
    draw4($t4, 524, 536, 5128, 7720)
    sw $t4 8204($v1)
    sw $t4 8216($v1)
    li $t4 0xac6c0e
    draw4($t4, 528, 540, 5136, 5148)
    sw $t4 8208($v1)
    sw $t4 8220($v1)
    li $t4 0xa1660d
    draw4($t4, 532, 1032, 5156, 8212)
    sw $t4 8712($v1)
    li $t4 0xa2660d
    draw4($t4, 544, 3624, 8224, 11304)
    li $t4 0xa3670d
    sw $t4 548($v1)
    sw $t4 8228($v1)
    li $t4 0xab6c0e
    sw $t4 552($v1)
    sw $t4 8232($v1)
    li $t4 0x834700
    sw $t4 556($v1)
    sw $t4 3584($v1)
    li $t4 0x864900
    sw $t4 1024($v1)
    sw $t4 3072($v1)
    li $t4 0xae6d0f
    sw $t4 1028($v1)
    sw $t4 8708($v1)
    li $t4 0x955e0c
    draw4($t4, 1036, 1064, 5144, 5160)
    sw $t4 8716($v1)
    sw $t4 8744($v1)
    li $t4 0xa96b0e
    draw4($t4, 1040, 1052, 8720, 8732)
    li $t4 0xac6d0e
    draw4($t4, 1044, 2084, 2596, 3600)
    draw4($t4, 3612, 6180, 8724, 9764)
    sw $t4 10276($v1)
    sw $t4 11280($v1)
    sw $t4 11292($v1)
    li $t4 0x935d0c
    sw $t4 1048($v1)
    sw $t4 8728($v1)
    li $t4 0xab6b0e
    sw $t4 1056($v1)
    sw $t4 8736($v1)
    li $t4 0x9c620d
    sw $t4 1060($v1)
    sw $t4 8740($v1)
    li $t4 0x854700
    sw $t4 1068($v1)
    li $t4 0x854900
    sw $t4 1536($v1)
    sw $t4 2048($v1)
    sw $t4 2560($v1)
    li $t4 0xca7f10
    draw4($t4, 1540, 1556, 7188, 9220)
    sw $t4 9236($v1)
    li $t4 0xb7740e
    sw $t4 1544($v1)
    sw $t4 5640($v1)
    sw $t4 9224($v1)
    li $t4 0x9e640c
    sw $t4 1548($v1)
    sw $t4 5644($v1)
    sw $t4 9228($v1)
    li $t4 0xb1700e
    draw4($t4, 1552, 1564, 5648, 5660)
    sw $t4 9232($v1)
    sw $t4 9244($v1)
    li $t4 0x9c630c
    draw4($t4, 1560, 5656, 6668, 9240)
    li $t4 0xc77d10
    draw4($t4, 1568, 3092, 9248, 10772)
    li $t4 0xaf6f0e
    sw $t4 1572($v1)
    sw $t4 9252($v1)
    li $t4 0x99610c
    draw4($t4, 1576, 2088, 2600, 5672)
    draw4($t4, 6184, 6696, 9256, 9768)
    sw $t4 10280($v1)
    li $t4 0x844700
    sw $t4 1580($v1)
    sw $t4 2092($v1)
    sw $t4 2604($v1)
    li $t4 0xc67c10
    draw4($t4, 2052, 2564, 3588, 7716)
    sw $t4 9732($v1)
    sw $t4 10244($v1)
    sw $t4 11268($v1)
    li $t4 0xb4720e
    draw4($t4, 2056, 2568, 6152, 9736)
    sw $t4 10248($v1)
    li $t4 0x9d630c
    draw4($t4, 2060, 2572, 3084, 6156)
    draw4($t4, 7192, 9740, 10252, 10764)
    li $t4 0xb06f0e
    draw16($t4, 2064, 2076, 2576, 2588, 3088, 3100, 6160, 6172, 6672, 6684, 9744, 9756, 10256, 10268, 10768, 10780)
    li $t4 0xc57c10
    draw4($t4, 2068, 2580, 3620, 6164)
    sw $t4 9748($v1)
    sw $t4 10260($v1)
    sw $t4 11300($v1)
    li $t4 0x9b620c
    draw4($t4, 2072, 2584, 3096, 6168)
    sw $t4 9752($v1)
    sw $t4 10264($v1)
    sw $t4 10776($v1)
    li $t4 0xc37a10
    draw4($t4, 2080, 2592, 6176, 9760)
    sw $t4 10272($v1)
    li $t4 0xc87d10
    sw $t4 3076($v1)
    sw $t4 7200($v1)
    sw $t4 10756($v1)
    li $t4 0xb6730e
    sw $t4 3080($v1)
    sw $t4 10760($v1)
    li $t4 0xc57b10
    sw $t4 3104($v1)
    sw $t4 6148($v1)
    sw $t4 10784($v1)
    li $t4 0xad6e0e
    sw $t4 3108($v1)
    sw $t4 10788($v1)
    li $t4 0x98600c
    sw $t4 3112($v1)
    sw $t4 7208($v1)
    sw $t4 10792($v1)
    li $t4 0x854800
    sw $t4 3116($v1)
    li $t4 0xcb8010
    sw $t4 3592($v1)
    sw $t4 11272($v1)
    li $t4 0xae6e0e
    draw4($t4, 3596, 3608, 4136, 11276)
    sw $t4 11288($v1)
    sw $t4 11816($v1)
    li $t4 0xcf8211
    sw $t4 3604($v1)
    sw $t4 11284($v1)
    li $t4 0xcc8010
    sw $t4 3616($v1)
    sw $t4 7700($v1)
    sw $t4 11296($v1)
    li $t4 0x824600
    sw $t4 3628($v1)
    li $t4 0x7d4300
    draw4($t4, 4096, 5164, 5676, 6144)
    draw4($t4, 6188, 6700, 8704, 9260)
    sw $t4 9772($v1)
    sw $t4 10284($v1)
    sw $t4 10796($v1)
    li $t4 0xc07910
    sw $t4 4100($v1)
    sw $t4 11780($v1)
    li $t4 0xc1780d
    sw $t4 4104($v1)
    sw $t4 11784($v1)
    li $t4 0xba7208
    sw $t4 4108($v1)
    sw $t4 11788($v1)
    li $t4 0xba750f
    sw $t4 4112($v1)
    sw $t4 11792($v1)
    li $t4 0xc37b10
    sw $t4 4116($v1)
    sw $t4 11796($v1)
    li $t4 0xc47b0f
    sw $t4 4120($v1)
    sw $t4 11800($v1)
    li $t4 0xb87107
    sw $t4 4124($v1)
    sw $t4 11804($v1)
    li $t4 0xbc760f
    sw $t4 4128($v1)
    sw $t4 11808($v1)
    li $t4 0xc0790f
    sw $t4 4132($v1)
    sw $t4 11812($v1)
    li $t4 0x7c4400
    sw $t4 4140($v1)
    sw $t4 7212($v1)
    sw $t4 7724($v1)
    li $t4 0xa0650d
    sw $t4 4612($v1)
    sw $t4 4620($v1)
    sw $t4 4632($v1)
    li $t4 0x9e630d
    sw $t4 4616($v1)
    li $t4 0xa96a0e
    sw $t4 4624($v1)
    sw $t4 4636($v1)
    li $t4 0x9f640d
    sw $t4 4628($v1)
    sw $t4 4640($v1)
    li $t4 0x9e640d
    sw $t4 4644($v1)
    li $t4 0xa6680d
    sw $t4 4648($v1)
    li $t4 0x7e4500
    draw4($t4, 4652, 5120, 5632, 9216)
    sw $t4 9728($v1)
    sw $t4 10240($v1)
    sw $t4 10752($v1)
    li $t4 0xb9740f
    sw $t4 5124($v1)
    li $t4 0x965f0c
    sw $t4 5132($v1)
    li $t4 0xb7730f
    sw $t4 5140($v1)
    li $t4 0xb5710f
    sw $t4 5152($v1)
    li $t4 0xc97e10
    sw $t4 5636($v1)
    sw $t4 5652($v1)
    li $t4 0xc77c10
    sw $t4 5664($v1)
    li $t4 0xae6f0e
    sw $t4 5668($v1)
    li $t4 0x824800
    sw $t4 6656($v1)
    sw $t4 8192($v1)
    li $t4 0xe0922a
    sw $t4 6660($v1)
    li $t4 0xcb862a
    sw $t4 6664($v1)
    li $t4 0xc47b10
    sw $t4 6676($v1)
    li $t4 0x9a610c
    sw $t4 6680($v1)
    li $t4 0xc27910
    sw $t4 6688($v1)
    li $t4 0xaa6c0e
    sw $t4 6692($v1)
    li $t4 0x935600
    sw $t4 7168($v1)
    sw $t4 7680($v1)
    li $t4 0xfeb721
    sw $t4 7172($v1)
    li $t4 0xdf9628
    sw $t4 7176($v1)
    li $t4 0x9b610d
    sw $t4 7180($v1)
    li $t4 0xaf6e0e
    sw $t4 7184($v1)
    sw $t4 7196($v1)
    li $t4 0xb2700e
    sw $t4 7204($v1)
    sw $t4 7692($v1)
    li $t4 0xf2a525
    sw $t4 7684($v1)
    li $t4 0xe2942a
    sw $t4 7688($v1)
    li $t4 0xae6d0e
    sw $t4 7696($v1)
    sw $t4 7708($v1)
    li $t4 0xb3710e
    sw $t4 7704($v1)
    li $t4 0xc97f10
    sw $t4 7712($v1)
    li $t4 0x7e4400
    sw $t4 8236($v1)
    li $t4 0x7b4400
    sw $t4 11308($v1)
    jr $ra

draw_alice: # start at v1 with Δx Δy in a0 a1, previous position in a2
    addi $sp $sp -4 # push ra to stack
    sw $ra 0($sp)
    # binary seach go brrr
    beqz $s3 draw_c # draw columns first
        bltz $s3 draw_rn # draw rows towards north
            li $t1 SIZE
            move $t2 $v1
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
            add $t2 $t2 $v1
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
                move $t2 $v1
                j draw_end
            draw_cen: # draw columns east north
                li $t0 -SIZE
                li $t2 PLAYER_END # set t2 to bottom left
                sll $t2 $t2 WIDTH_SHIFT
                add $t2 $t2 $v1
                j draw_end
        draw_cw: # draw columns west
            li $t1 -4
            bltz $s4 draw_cwn # draw columns west north
                li $t0 SIZE  # draw columns west south
                addi $t2 $v1 PLAYER_END # set t2 to top right
                j draw_end
            draw_cwn:
                li $t0 -SIZE
                li $t2 PLAYER_END # set t2 to bottom right
                sll $t2 $t2 WIDTH_SHIFT
                add $t2 $t2 $v1
                addi $t2 $t2 PLAYER_END
                j draw_end
    draw_end:

    move $v1 $t2
    # t0 t1 is Δs
    # t2 is start, v1 is current

    # get frame index in words
    la $a2 alice
    frame4(ALICE_FRAME)
    jalr $v0 # draw frame

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
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x030302 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3c231b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa46249 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeaa891 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd0a4af # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc68fa1 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd198a1 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc58993 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc7a3b2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7f7778 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x261911 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x120a07 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6d3f2d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd68969 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe7bcb6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb96a7d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xaa4e63 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc98a8f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe3a49e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdea09c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbc7781 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xce7c8c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbf9084 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x49352c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x040201 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x030201 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x854d37 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc87556 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdaa59e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb76476 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb7626e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeab990 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf6c374 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf5c370 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf6c26e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf2bd82 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe1b7ab # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe2a197 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd7a474 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x614029 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x000001 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x4c2c20 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbb7151 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdca16b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcb8877 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc17172 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf1c58e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfed97c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbdb75 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfce488 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe389 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfad677 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe092 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfcdeac # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf6ce78 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcea95e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x261a12 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xa55f46 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc47b55 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf7c873 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf7cd7b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeab377 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfcdfa7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xedc39c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe0ac6b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfeebab # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf9dbac # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdca063 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfce0a5 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf7ca8b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xefb76f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf7d473 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x937241 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xbe6f50 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe09e65 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfad378 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfacc77 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf2b672 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe7b36a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb46643 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcf955c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfddb76 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd69355 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8d482d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc38254 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbd178 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd99b64 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf5c073 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb39f56 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xbe6f4f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe7b06a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeaba6d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbcd79 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbc7955 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x764b3c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x733b2c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb78b66 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xecad75 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc48374 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x62585f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb2705f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf6c06c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb7814d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbd7d54 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xac9857 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xcf7d58 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe09d64 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd5915d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfcd27a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb8885c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa69da1 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x5f7f83 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xddbdb0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbcfbf # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe2d7d2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x74a7b4 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcb8b70 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd19251 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x975f3a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3e2b1a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x524c2b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xcd7a57 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd9835c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc37950 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe8a569 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd9a16a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xaab3b6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3c96a7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeee2db # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffebe2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf1e6df # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbfc1bb # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc7785c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd67453 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x562e21 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x020101 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x020303 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x7d4938 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xce7958 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6e3c27 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8e543a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcb7850 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xce9487 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe4c2c7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbd5cf # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfed5ce # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf6cbc5 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc78a79 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcd7451 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb36343 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2d1912 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x0b0506 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x683c2f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2e1913 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x261409 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x96573a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdeb2ad # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf7d2d8 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe2a9aa # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc05c68 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdab3b8 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbd979a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x914e44 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1d0b04 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x060302 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x020508 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x151e2d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x302b30 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x897c89 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xac93a7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbb939f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc9a1a7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbd99a0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x736a82 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x25253a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1e2d49 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x04060a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1d2636 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2d3d5a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x284167 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2e4169 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3a3f5e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7d87a7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x898ea0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x71788b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x303959 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2b3553 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3b5586 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1f2d46 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x07090d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x35415e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x384c74 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x425883 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x384061 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3e466e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb4b4cc # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdfdeeb # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd6d5e6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7881a0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x5d6586 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x304870 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x080c13 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1b1f2a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x475373 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x454c67 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7e82a0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa4adc3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x717897 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7383a0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa2a8c1 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x69677e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x283754 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x070b11 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x040506 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x21222b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6a7094 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x71779b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x383c4f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x292f41 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x4d5779 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x353b51 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    jr $ra
draw_alice_01:
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x020201 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x382119 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x9e5d46 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeaa78d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd2a7b0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc590a2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd39ba4 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc58a94 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc99fae # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8a8588 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x302016 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x0f0906 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x663b2a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd28564 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe9bcb5 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbc7184 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa94960 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc4848c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe2a39e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdfa19d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbd7982 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xca7688 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc9958b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x563f35 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x060303 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x020101 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x804b36 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc67354 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdca69d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb86a7b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb35a6a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe6b692 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf5c277 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf5c271 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf6c26f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf2bd7f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe2b8a9 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe09d99 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdda97b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x734e32 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x050204 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x472a1e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xba6f50 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xda9e69 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcc8978 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbe6b6f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xedbf8e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfed87b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfcdb75 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfce384 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe388 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbd777 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfedd8a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfee3b2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf7cd7d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdfb766 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x362719 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xa25d45 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc37954 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf7c673 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf7cd7c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe9b177 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbdda5 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf1cca4 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe0aa6b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfee9a8 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfce2b3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdea367 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbdd9f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf9d195 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xefb46e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf9d675 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa68349 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xbe6e50 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdf9a63 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfad278 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf9ce77 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf3b772 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xedbd6f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xba6d49 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcb8d58 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffdf79 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe0a25d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x954c2f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbd7d51 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbd17a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdea267 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf0b870 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcab160 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xbd6f4f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe6ae6a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xebbc6f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfccf79 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc58059 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7c4f3c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x753929 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xae825f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeeb273 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xca8370 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x665356 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa36a5e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf6b96b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc29154 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbb7550 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc0a560 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xcf7c58 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe19f65 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd5915d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfdd57a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb8875a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa19498 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x61797d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd0b5a9 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfac8b6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeddad3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6ea5b2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc9937f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd49451 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa87042 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x482c1b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x5e5630 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xd07b58 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xda855d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc97d54 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xedaa6c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdba46a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb0b4b6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3092a4 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe4ded8 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffeae2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf6e8e0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb4c4c1 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc98369 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd77452 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6e3c2a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x070403 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x040503 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x864f3c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd17b5a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x74402b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x91563b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcf7d52 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcb9485 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd5bec4 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf9d7d2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffddd4 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbd3cd # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd19788 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcb7552 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc86e4c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x43251b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x100809 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7a4737 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3c1f18 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2c170b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x9c5939 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd9a8a0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf8d0d7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeab8b8 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc3626d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdbb0b6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbc9899 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xaa5d51 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x311609 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x0c0604 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x000204 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x101723 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x362b2b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x98838b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbfa5b6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc6959d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd29da2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcb9ba2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8e8296 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x352d3f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x15233a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x03060a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1a2230 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2d3c58 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x263d60 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2f436c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3a405e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x727c9e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x82899d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x707789 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x323958 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x26304e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x395382 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x243553 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x07090c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x323f5b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x354970 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3f5682 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x333c5e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x363c63 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb4b3cc # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe0deec # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd9d8e7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7b85a4 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x5c617f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3b5381 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x101826 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x010101 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x202633 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x4a597c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x495271 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x747998 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x99a3bb # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x757b9b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8290ab # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xacb1c9 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7b7a93 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x384666 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x111a2a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x0d0e12 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x20212a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6d7395 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8286a8 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x4b5067 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x30384f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x535c7e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x434962 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x000104 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    jr $ra
draw_alice_02:
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2f1c14 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x93543d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeda88a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd5a9af # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc490a5 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd69ea8 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc38b97 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc999a9 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x9c98a0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3a2a20 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x0c0705 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x5d3627 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcd805f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeabcb1 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc27d8d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa7445c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbe7c87 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe0a19e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdfa09e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbf7e86 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc36d82 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd09992 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6a5044 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x0c0706 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7a4833 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc47152 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdda59a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbd7484 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xae4f64 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe1ae94 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf4c17b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf4c170 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf5c071 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf2bc7a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe3b8a8 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xda9a98 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe4aa85 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8c623f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x100908 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x41261c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb76d4e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd89967 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcc8b7a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb9636b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe8b78e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfed67a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfddb74 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbe380 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe387 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfdda79 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfdd881 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe7b4 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf8cf88 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf1c86e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x543f26 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x9d5b43 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc07653 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf6c372 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf6cd7b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe7af78 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfadaa3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf7d8ad # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe1aa6d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfde6a2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfee8ba # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe2ab70 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf9d994 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbdaa2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xefb36d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbd678 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbe9955 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xbd6e50 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdc9562 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf9d177 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfad178 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf3b771 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf6c977 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc57a52 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc58152 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe27c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe9b366 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa15635 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb57349 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf9cc7a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe6b16d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe8ac6c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe5c76d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xbc6e4f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe6ae6a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xedbf6f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfcd079 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd0895e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x86573e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x793a27 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa47656 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf0ba72 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xce8469 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x704e4b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8b5e5a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeea765 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd3a75e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb76d4c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd7b06a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xce7b57 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe3a366 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd6915e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfed67b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb98657 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x988588 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x697274 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbca69b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf9bfa9 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf5d8d0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6c9fac # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbf9c94 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd49250 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbf884e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x5b3322 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6d6036 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xd07b58 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdc895e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xce8056 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf1b26f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdda769 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbab5b5 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2f92a3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd3d5d1 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe8df # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfdeae2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa5c5c4 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcb9682 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcf6f4d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x905137 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x190d09 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x070805 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x955741 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd57d5b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x804730 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x975b3f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd58456 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc99586 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbdb8bf # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf3d8d4 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe6dd # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfedbd3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdfafa2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc77756 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd87853 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6b3c2b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x000001 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x1a0d0d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x935641 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x4d291e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x361e0f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa65c3b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd0988c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf8c9d1 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf5c9c7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcd7179 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdeacb3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbc9895 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbe6b5f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x572a18 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1c0f08 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x060303 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x020203 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x0b0f18 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3d2c26 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xaa8d8c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd3b8c6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd49ca0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd59094 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd3979e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb0a2b0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x5b4151 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x0e1726 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x04070d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x141b26 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2b3a53 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x213553 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2f446b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x414564 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x697394 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x818b9f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x727687 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x363d58 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1d2746 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x354d7a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2b3f64 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x010203 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x05070a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2d3852 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x32456a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3a5481 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2f3c5e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2f3459 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xadacc6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdcdae8 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd3d2df # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7f88a6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x525571 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x415784 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x21314d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x010101 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x020203 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x282f40 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x49597f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x4b587c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x646988 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7a88a5 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x777e9f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x9da7bd # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb7bbd0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x908faa # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x505a7b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x23324e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x010102 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x010101 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1b2029 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x21232d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6f7494 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x9a9cba # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x676a86 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3b4865 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x5a6384 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x5c617b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x04070e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x010202 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    jr $ra
draw_alice_03:
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x130c09 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6e3c2b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xed9973 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe2c0c0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcdb2c5 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe4c4cb # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcaaab3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd5b7c3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x999ba2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1e150f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x341e16 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb46d4d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xebaf9a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd29ea5 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa74159 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb06075 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd3868e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd4868e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb86b7b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc07189 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd09f93 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x4d3f35 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x020001 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x5c3626 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb7694a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe2a28d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcb969f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xaa475e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd29a94 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xebb889 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf2bd7e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf3bd80 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeab582 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdba9a3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcf878c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd99a7f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x78563a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x0e0707 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x281711 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xac6548 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcf8a60 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcb8b82 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb15263 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd99d88 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfac971 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffdb72 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbe177 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe07c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffdb76 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfacf7d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe9bd # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf8cf93 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe9bc69 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x543c26 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x824c37 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbd7352 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf0ba6e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf1c47b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdda37a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf8d29d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfee6b1 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xecb976 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfce39a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffeabb # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xecbf7e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfcde91 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfcdea8 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf1b870 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbd879 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb79351 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xbb6c4f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd3885c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf8cc76 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfcd478 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf2b670 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbd684 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd8986c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc27d52 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfee183 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf6cd80 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb66c46 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc58455 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfad487 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xecb671 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe5ac6c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeece6f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xba6c4e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe2a867 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf2c673 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbd279 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe29a68 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa67348 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8a442b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa56d4d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf4c772 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd18559 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7d463a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7b4d47 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe99f62 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdeb566 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc27952 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe9bc71 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xc87654 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe5a768 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xda9a61 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfed67a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xba8356 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x816668 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x715c58 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa58d80 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf4b592 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf0c6bb # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6f8f9b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xac9496 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdd9a56 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcf9f58 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x75422d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8f7946 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xce7a57 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xde8f61 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd08357 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf6be74 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdba866 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc1b2b0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x4498a6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc2cac7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe1d6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffeae2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8fbdbf # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc7a596 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc76d48 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa5613f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x301910 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x12130a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xac664a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd67e5c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x96553a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xaa6948 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdc905c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc89e8f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8fadb9 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe1d7d5 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffeee5 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe7de # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeac9bf # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xca8163 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe17b55 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x854935 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x050304 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x301a17 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xae674d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x693828 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x492919 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb56542 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc18271 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf4bcc3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfad1cf # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe39b9c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe9b6ba # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbc918a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbf6e5e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8c492e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x391f13 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1a0e0c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x120d10 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x161e2c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x4e3123 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc9a29c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd8bdc4 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xca9195 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa24451 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xae6873 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc0aeb7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x905f6b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x29334f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x111a2b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x17202e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2c3c58 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x283f63 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x344971 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x373956 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x757694 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8989a2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x84828f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x484e6d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2d334e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x384f7c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x364f7c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x05070b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x050609 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x313b56 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x394c73 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x415985 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3b4465 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x363f66 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x9194b3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdfdeec # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdbdbea # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x9ca1bc # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x646a89 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x445783 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x152033 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x010102 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x13161d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x475373 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3f4863 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x717492 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa7b0c6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7c829f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6b7b98 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x929cb7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x908ea7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x353c55 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x152135 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x050506 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x141419 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x616787 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x757ba0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x484c64 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x292f40 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x424969 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x4e5879 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x020305 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    jr $ra
draw_alice_04:
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x150c0a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7a4431 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xee9d79 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe1c2c4 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xceb1c3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe1c2c8 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xccabb4 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd4bac7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x7d8084 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x160e08 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3d231a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xba7152 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xebb3a1 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcc929d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa53e57 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb6687b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd58a90 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd3878f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb56a7a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc87a8e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc29789 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3d2e27 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x633a29 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbb6b4c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe2a693 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc68c98 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xac4a60 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd7a397 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xedb984 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf3be7d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf3be7e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xebb584 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd8a7a5 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd38888 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd39c7b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x62442b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x070304 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x2d1a13 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xaf684b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd28f63 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xca8980 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb35665 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdfa889 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfcce72 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfedc72 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbe17a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe17d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfed876 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfcd586 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfee7bd # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf7cd85 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdeb164 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x332419 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x884f3a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbf7553 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf2be70 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf1c57b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe0a77a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfad8a2 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfce1af # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeab873 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfde7a3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfee7b8 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe9b874 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe39e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf9d59c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf2ba70 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbdb78 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x9c7b44 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xbc6d4f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd78e5e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf9ce77 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbd278 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf2b770 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf7d080 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcd8760 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc78655 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe483 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xedbd75 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xaa5f3d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xca8d5c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbd481 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe5ab6c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeeb970 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd6ba64 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xba6c4e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe4aa68 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf0c471 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbd079 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd99263 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x966441 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x823d28 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xab7854 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf2bf70 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc97d5c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6f463f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8f5a50 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf1af69 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcfa05c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc97e57 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd2b168 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xca7855 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe5a668 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd8965f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfed77a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb48055 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8b7477 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6a6362 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb89c8f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf6ba9e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xeecdc6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6794a3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc0938a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xda9e55 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbc874e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x623826 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x827341 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xce7a57 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdd8c5f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcf8256 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xf3b971 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdaa668 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbab5b4 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3793a3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd4d2ce # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffe4db # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfae8e0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x96bebe # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xca917c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xcb704b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8a4e34 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x180c08 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x0e1009 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0xa05e45 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd57d5b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x894d35 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa16344 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd88a59 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc79c8e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa6b3bc # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xefdad7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xffeae1 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfedfd7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe1b5a8 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc97755 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdb7954 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x603527 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    li $t4 0x211111 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa05d47 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x5a2f21 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x412416 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb0623e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xce9183 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfecad0 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xfbcfcc # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xdc888b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xe9b8bd # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb88f89 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xc06958 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x65331f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1f1008 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x0d0706 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x0e0e14 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1a2535 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x47332c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb89b9e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xbea6ae # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xad7580 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x934452 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x9e656f # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa996a5 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x6a4c5e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x273c61 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x111a2b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1e2739 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2d3f5c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2b4770 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2b3f69 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x313555 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x8b8fad # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xa1a5b9 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x9498a7 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x485271 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x313753 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3c5584 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2b3f63 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x050709 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x343f5a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3d5078 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x465a84 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x444b6b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3f4c72 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x9295b3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd7d8e6 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xd7d7e8 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x9196b3 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x646c8e # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x364b74 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x080d14 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x0d0e13 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3d4760 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x373d52 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x777b99 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0xb0b5cb # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x787d9b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x5b6c8c # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x868eab # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x74738b # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1c263a # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x080d16 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    add $t2 $t2 $t1 # shift y
    move $v1 $t2 # carriage return
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x17181d # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x606788 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x666d94 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x2d3142 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x1b1e28 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x3d4464 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    li $t4 0x404966 # load color
    sw $t4 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    sw $0 0($v1)
    add $v1 $v1 $t0 # shift x
    jr $ra
draw_alice_05:
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x1c100e # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x93553d # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xeda587 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xdabfc8 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xd1b0bf # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xd8b5bd # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xcda9b1 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xcfbfcd # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x4b4946 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x070200 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x040201 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x4e2e22 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xc67b5b # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xe9b6aa # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xc17b89 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xa5445d # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xc27886 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xd88d91 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xd0858c # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xb2677b # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xd48e96 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x977869 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x1e1411 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        li $t4 0x010000 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x70412e # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xc37253 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xe0aa9d # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xbd7585 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xb45d6b # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xe3b296 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf1be7c # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf4c17c # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf3bf7a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xeab68e # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xd5a3a3 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xdd9588 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xbc8f64 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x352116 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x000001 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        li $t4 0x382118 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xb46b4e # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xd79869 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xc7827a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xbc666d # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xebbb89 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xfed575 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xfdde74 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xfde181 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xffe17f # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xfbd374 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xffe19c # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xfbdbac # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xfbd076 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xa4804b # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x100a09 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        li $t4 0x975840 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xc27954 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf6c672 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf2c77b # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xe7af7a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xfde0a9 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf0ca9e # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xe8b971 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xfeebb0 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf6d7a7 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xe6b069 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xffe7ae # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf4c181 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf5c474 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xe8c66a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x705231 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        li $t4 0xbe6f50 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xdc9761 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xfad378 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf9cc77 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf4bb73 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xedbc73 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xba6d4b # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xd7a060 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xfddc7a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xd49358 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x954c2f # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xd99f66 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf9cf79 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xda9864 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf9ce76 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x988649 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        li $t4 0xbd6f4f # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xe6ad6a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xedbe6f # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xfacb78 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xc17e58 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x7e503a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x7a3d2c # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xc09466 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xe9aa6f # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xb77565 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x604f56 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xbe755a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf3c36d # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xb07348 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xd29661 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x96874d # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        li $t4 0xcd7b57 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xe19e65 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xd7945f # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xfbd279 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xb18159 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x9e9498 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x63797c # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xe0baaa # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf8ccbc # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xcecbc8 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x79a5b3 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xcd8764 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xd19854 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x885132 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x4d3b23 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x544d2a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        li $t4 0xcf7b57 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xda845d # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xc87e54 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xecaa6b # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xd8a36c # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xa3b4b9 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x4098a8 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf5e4dc # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xffeae2 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xe5e1da # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xbabdb7 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xc77355 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xc96f4f # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x44241a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x020202 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x050604 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        li $t4 0x824c39 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xce7958 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x723f2a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x96593d # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xcc7b52 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xcd998d # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xdcc2c7 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xfdd8d2 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xffd9d1 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xf4c8c2 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xc68774 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xce7450 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xa85d40 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x1c100d # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        li $t4 0x0d0607 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x6d3f31 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x341c17 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x332018 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x9d5b3d # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xe0b2ad # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xfed7db # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xe5a8a9 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xcb6c77 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xdfbcc0 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xbd8d8e # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x86493f # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x261a1a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x030100 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x111823 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x202f45 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x3b3a47 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x827b8e # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x816d7c # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x7d566e # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x7a505f # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x755a69 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x6f6178 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x343c5e # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x314a78 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x0f1522 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x050608 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x2a364e # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x32466b # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x354f7c # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x2a375c # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x42476b # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xbcc0d8 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xcccfdd # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xb3b8cc # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x4e5978 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x495172 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x354f7d # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x0d141f # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x030305 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x2d354a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x47577e # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x4e5a7e # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x656b89 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x73809f # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x868ca9 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xabb4c8 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0xbcbdd3 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x737490 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x44557a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x0f1827 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x030304 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x1d222c # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x2b2d3a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x7d81a2 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x989ab7 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x555c77 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x3f4c6a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x6b7392 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x36394a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x04080f # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        add $t2 $t2 $t1 # shift y
        move $v1 $t2 # carriage return
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x25262f # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x5d668a # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x4f587c # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x050507 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x0b0b12 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x454e71 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        li $t4 0x282d40 # load color
        sw $t4 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        sw $0 0($v1)
        add $v1 $v1 $t0 # shift x
        jr $ra
clear_alice: # start at v1
    li $a0 REFRESH_RATE
    li $v0 32
    draw64($0, 0, 4, 8, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 512, 516, 520, 548, 552, 556, 560, 564, 568, 572, 1024, 1028, 1032, 1076, 1080, 1084, 1536, 1540, 1544, 2048, 2052, 2560, 2564, 2620, 3072, 3076, 3132, 3584, 3588, 3644, 4096, 4156, 4608, 4664, 4668, 5120, 5176, 5180, 5688, 5692, 6144, 6200, 6204, 6656, 6660, 6664, 6668, 6708, 6712, 6716, 7168)
    draw16($0, 7172, 7176, 7180, 7184, 7188, 7192, 7196, 7220, 7224, 7228, 7680, 7684, 7688, 7692, 7696, 7700)
    draw4($0, 7704, 7708, 7712, 7716)
    draw4($0, 7720, 7724, 7732, 7736)
    sw $0 7740($v1)
    syscall
    draw16($0, 12, 16, 20, 524, 528, 532, 540, 544, 1036, 1040, 1060, 1064, 1068, 1072, 1548, 1552)
    draw16($0, 1580, 1584, 1588, 1592, 1596, 2056, 2060, 2100, 2104, 2108, 2568, 2616, 3080, 3640, 4100, 4152)
    draw16($0, 4660, 5124, 5172, 5632, 5636, 5640, 5644, 5680, 5684, 6148, 6152, 6156, 6160, 6192, 6196, 6672)
    draw4($0, 6676, 6680, 6700, 6704)
    draw4($0, 7200, 7212, 7216, 7728)
    syscall
    draw16($0, 536, 1044, 1048, 1556, 1576, 2064, 2092, 2096, 2572, 2608, 2612, 3124, 3128, 4612, 4616, 5128)
    draw4($0, 5132, 5168, 5648, 5676)
    draw4($0, 6164, 6184, 6188, 6684)
    draw4($0, 6692, 6696, 7204, 7208)
    syscall
    draw16($0, 1052, 1056, 1560, 1564, 2068, 2072, 2088, 2576, 2604, 3116, 3120, 3592, 3632, 3636, 4104, 4108)
    draw4($0, 4148, 4620, 4624, 5136)
    draw4($0, 5164, 5652, 5668, 5672)
    sw $0 6176($v1)
    sw $0 6180($v1)
    sw $0 6688($v1)
    syscall
    draw4($0, 1568, 1572, 2076, 2080)
    draw4($0, 3084, 3596, 3600, 3628)
    draw4($0, 4112, 4144, 4656, 5660)
    sw $0 5664($v1)
    sw $0 6168($v1)
    sw $0 6172($v1)
    syscall
    draw16($0, 2084, 2580, 2584, 2588, 2592, 2596, 2600, 3088, 3092, 3112, 3604, 3624, 4116, 4136, 4140, 4628)
    draw4($0, 4648, 4652, 5140, 5144)
    draw4($0, 5148, 5152, 5156, 5160)
    sw $0 5656($v1)
    syscall
    draw4($0, 3096, 3100, 3108, 3620)
    draw4($0, 4120, 4632, 4640, 4644)
    syscall
    draw4($0, 3104, 3608, 4132, 4636)
    syscall
    draw4($0, 3612, 3616, 4124, 4128)
    jr $ra
draw_doll:
    addi $sp $sp -4 # push ra to stack
    sw $ra 0($sp)
    # t5 is address to array of frames
    lw $t4 stage # stage number * 4
    la $t5 dolls
    add $t5 $t5 $t4 # address to dolls
    lw $a2 0($t5) # get doll (i.e. array of frames)
    frame2(DOLLS_FRAME)
    lw $v1 doll_address
    jalr $v0

    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4
    jr $ra # return
draw_doll_01_00: # start at v1, use t4
    draw16($0, 0, 4, 16, 20, 28, 32, 36, 512, 516, 520, 524, 536, 544, 548, 1060, 1536)
    draw4($0, 1540, 1568, 2080, 3584)
    draw4($0, 3620, 4128, 4132, 4644)
    draw4($0, 5148, 5156, 5636, 5652)
    sw $0 5660($v1)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x000100
    draw4($t4, 12, 3104, 3616, 5124)
    li $t4 0x000102
    sw $t4 4608($v1)
    sw $t4 5120($v1)
    sw $t4 5152($v1)
    li $t4 0x010100
    sw $t4 8($v1)
    sw $t4 540($v1)
    li $t4 0x010101
    sw $t4 1056($v1)
    sw $t4 2596($v1)
    li $t4 0x020101
    sw $t4 1572($v1)
    sw $t4 2084($v1)
    li $t4 0x010000
    sw $t4 5632($v1)
    sw $t4 5656($v1)
    li $t4 0x030201
    sw $t4 24($v1)
    li $t4 0x140b07
    sw $t4 528($v1)
    li $t4 0x0c0504
    sw $t4 532($v1)
    li $t4 0x030202
    sw $t4 1024($v1)
    li $t4 0x040404
    sw $t4 1028($v1)
    li $t4 0x1b060a
    sw $t4 1032($v1)
    li $t4 0xae523b
    sw $t4 1036($v1)
    li $t4 0xcd3f43
    sw $t4 1040($v1)
    li $t4 0xc84e42
    sw $t4 1044($v1)
    li $t4 0x592620
    sw $t4 1048($v1)
    li $t4 0x000001
    sw $t4 1052($v1)
    li $t4 0x925431
    sw $t4 1544($v1)
    li $t4 0xf9b253
    sw $t4 1548($v1)
    li $t4 0xdc7d42
    sw $t4 1552($v1)
    li $t4 0xd27344
    sw $t4 1556($v1)
    li $t4 0xe2934a
    sw $t4 1560($v1)
    li $t4 0x160804
    sw $t4 1564($v1)
    li $t4 0x6d657f
    sw $t4 2048($v1)
    li $t4 0x645d7a
    sw $t4 2052($v1)
    li $t4 0x9f4e3a
    sw $t4 2056($v1)
    li $t4 0xd5744e
    sw $t4 2060($v1)
    li $t4 0x854d56
    sw $t4 2064($v1)
    li $t4 0xb06a5d
    sw $t4 2068($v1)
    li $t4 0xa73147
    sw $t4 2072($v1)
    li $t4 0x572d45
    sw $t4 2076($v1)
    li $t4 0xcfbff3
    sw $t4 2560($v1)
    li $t4 0xe8e4ff
    sw $t4 2564($v1)
    li $t4 0xae3f6a
    sw $t4 2568($v1)
    li $t4 0xb3333e
    sw $t4 2572($v1)
    li $t4 0xa298a6
    sw $t4 2576($v1)
    li $t4 0xc89f8e
    sw $t4 2580($v1)
    li $t4 0x90134e
    sw $t4 2584($v1)
    li $t4 0x604271
    sw $t4 2588($v1)
    li $t4 0x000101
    sw $t4 2592($v1)
    li $t4 0x655e75
    sw $t4 3072($v1)
    li $t4 0xc8c5e1
    sw $t4 3076($v1)
    li $t4 0x89478e
    sw $t4 3080($v1)
    li $t4 0x845da0
    sw $t4 3084($v1)
    li $t4 0x977cab
    sw $t4 3088($v1)
    li $t4 0xb197c0
    sw $t4 3092($v1)
    li $t4 0x92347e
    sw $t4 3096($v1)
    li $t4 0x3e2842
    sw $t4 3100($v1)
    li $t4 0x020102
    sw $t4 3108($v1)
    li $t4 0x39282f
    sw $t4 3588($v1)
    li $t4 0x6360ab
    sw $t4 3592($v1)
    li $t4 0x3a3a9a
    sw $t4 3596($v1)
    li $t4 0x954378
    sw $t4 3600($v1)
    li $t4 0x84295e
    sw $t4 3604($v1)
    li $t4 0x5a3d6f
    sw $t4 3608($v1)
    li $t4 0x020000
    sw $t4 3612($v1)
    li $t4 0x030303
    sw $t4 4096($v1)
    li $t4 0x250d0a
    sw $t4 4100($v1)
    li $t4 0x721650
    sw $t4 4104($v1)
    li $t4 0x342c91
    sw $t4 4108($v1)
    li $t4 0xa786c3
    sw $t4 4112($v1)
    li $t4 0x935ba0
    sw $t4 4116($v1)
    li $t4 0x660f2f
    sw $t4 4120($v1)
    li $t4 0x080403
    sw $t4 4124($v1)
    li $t4 0x030000
    sw $t4 4612($v1)
    li $t4 0x041270
    sw $t4 4616($v1)
    li $t4 0x2c4bb7
    sw $t4 4620($v1)
    li $t4 0xefe0fe
    sw $t4 4624($v1)
    li $t4 0xa3c7ff
    sw $t4 4628($v1)
    li $t4 0x020d46
    sw $t4 4632($v1)
    li $t4 0x050000
    sw $t4 4636($v1)
    li $t4 0x000103
    sw $t4 4640($v1)
    li $t4 0x070b33
    sw $t4 5128($v1)
    li $t4 0x1838a2
    sw $t4 5132($v1)
    li $t4 0x3f68bc
    sw $t4 5136($v1)
    li $t4 0x1a5eb8
    sw $t4 5140($v1)
    li $t4 0x01112d
    sw $t4 5144($v1)
    li $t4 0x0b0601
    sw $t4 5640($v1)
    li $t4 0x372033
    sw $t4 5644($v1)
    li $t4 0x110915
    sw $t4 5648($v1)
    jr $ra
draw_doll_01_01: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 20, 24, 32, 36, 540, 548, 1028, 1056, 1568, 2048, 2052, 2076)
    draw4($0, 2084, 3616, 4132, 4608)
    draw4($0, 4612, 4644, 5148, 5152)
    draw4($0, 5156, 5632, 5636, 5660)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x010000
    draw4($t4, 28, 512, 1572, 4636)
    li $t4 0x010100
    sw $t4 516($v1)
    sw $t4 5640($v1)
    sw $t4 5652($v1)
    li $t4 0x010101
    sw $t4 544($v1)
    sw $t4 2596($v1)
    sw $t4 5124($v1)
    li $t4 0x040304
    sw $t4 1540($v1)
    sw $t4 5120($v1)
    li $t4 0x020001
    sw $t4 3108($v1)
    sw $t4 3620($v1)
    li $t4 0x000102
    sw $t4 4128($v1)
    sw $t4 4640($v1)
    li $t4 0x000401
    sw $t4 16($v1)
    li $t4 0x0c0205
    sw $t4 520($v1)
    li $t4 0x893c2f
    sw $t4 524($v1)
    li $t4 0xb13539
    sw $t4 528($v1)
    li $t4 0xaa3e38
    sw $t4 532($v1)
    li $t4 0x3a1116
    sw $t4 536($v1)
    li $t4 0x040201
    sw $t4 1024($v1)
    li $t4 0x803c2c
    sw $t4 1032($v1)
    li $t4 0xfba053
    sw $t4 1036($v1)
    li $t4 0xe37146
    sw $t4 1040($v1)
    li $t4 0xde7a49
    sw $t4 1044($v1)
    li $t4 0xdf934a
    sw $t4 1048($v1)
    li $t4 0x170409
    sw $t4 1052($v1)
    li $t4 0x010001
    sw $t4 1060($v1)
    li $t4 0x050403
    sw $t4 1536($v1)
    li $t4 0x9c4e37
    sw $t4 1544($v1)
    li $t4 0xdb8a50
    sw $t4 1548($v1)
    li $t4 0x8e4d45
    sw $t4 1552($v1)
    li $t4 0xb36e4f
    sw $t4 1556($v1)
    li $t4 0xb86545
    sw $t4 1560($v1)
    li $t4 0x180509
    sw $t4 1564($v1)
    li $t4 0x541518
    sw $t4 2056($v1)
    li $t4 0xcb494d
    sw $t4 2060($v1)
    li $t4 0x958c9e
    sw $t4 2064($v1)
    li $t4 0xc69c8e
    sw $t4 2068($v1)
    li $t4 0x7a0e39
    sw $t4 2072($v1)
    li $t4 0x000100
    sw $t4 2080($v1)
    li $t4 0x231e28
    sw $t4 2560($v1)
    li $t4 0x595769
    sw $t4 2564($v1)
    li $t4 0x631a43
    sw $t4 2568($v1)
    li $t4 0x9c5b98
    sw $t4 2572($v1)
    li $t4 0x8e749d
    sw $t4 2576($v1)
    li $t4 0xa886ad
    sw $t4 2580($v1)
    li $t4 0x96296d
    sw $t4 2584($v1)
    li $t4 0x4b3355
    sw $t4 2588($v1)
    li $t4 0x000101
    sw $t4 2592($v1)
    li $t4 0xc7beeb
    sw $t4 3072($v1)
    li $t4 0xe8d1f6
    sw $t4 3076($v1)
    li $t4 0x575bb1
    sw $t4 3080($v1)
    li $t4 0x414bac
    sw $t4 3084($v1)
    li $t4 0x8e4081
    sw $t4 3088($v1)
    li $t4 0x73366d
    sw $t4 3092($v1)
    li $t4 0x74407f
    sw $t4 3096($v1)
    li $t4 0x602f54
    sw $t4 3100($v1)
    li $t4 0x000201
    sw $t4 3104($v1)
    li $t4 0xd2c7fa
    sw $t4 3584($v1)
    li $t4 0xbea9c6
    sw $t4 3588($v1)
    li $t4 0x7d1d47
    sw $t4 3592($v1)
    li $t4 0x362185
    sw $t4 3596($v1)
    li $t4 0x8f5da3
    sw $t4 3600($v1)
    li $t4 0x752469
    sw $t4 3604($v1)
    li $t4 0x8c1c42
    sw $t4 3608($v1)
    li $t4 0x20040c
    sw $t4 3612($v1)
    li $t4 0x4b445a
    sw $t4 4096($v1)
    li $t4 0x16161c
    sw $t4 4100($v1)
    li $t4 0x100235
    sw $t4 4104($v1)
    li $t4 0x1833a6
    sw $t4 4108($v1)
    li $t4 0xe7def9
    sw $t4 4112($v1)
    li $t4 0x9bbaff
    sw $t4 4116($v1)
    li $t4 0x1b0646
    sw $t4 4120($v1)
    li $t4 0x060000
    sw $t4 4124($v1)
    li $t4 0x030831
    sw $t4 4616($v1)
    li $t4 0x123cb1
    sw $t4 4620($v1)
    li $t4 0x8586cb
    sw $t4 4624($v1)
    li $t4 0x396ecd
    sw $t4 4628($v1)
    li $t4 0x001738
    sw $t4 4632($v1)
    li $t4 0x0b0606
    sw $t4 5128($v1)
    li $t4 0x362443
    sw $t4 5132($v1)
    li $t4 0x0f0b25
    sw $t4 5136($v1)
    li $t4 0x000004
    sw $t4 5140($v1)
    li $t4 0x020000
    sw $t4 5144($v1)
    li $t4 0x030100
    sw $t4 5644($v1)
    li $t4 0x070300
    sw $t4 5648($v1)
    li $t4 0x000001
    sw $t4 5656($v1)
    jr $ra
draw_doll_01_02: # start at v1, use t4
    draw16($0, 0, 8, 24, 32, 36, 540, 548, 1056, 1536, 1568, 3616, 4096, 4100, 4132, 4644, 5124)
    draw4($0, 5144, 5148, 5152, 5156)
    draw4($0, 5632, 5636, 5640, 5644)
    sw $0 5660($v1)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x000100
    sw $t4 3104($v1)
    sw $t4 4636($v1)
    sw $t4 5648($v1)
    li $t4 0x010000
    sw $t4 4($v1)
    sw $t4 5120($v1)
    li $t4 0x010100
    sw $t4 28($v1)
    sw $t4 516($v1)
    li $t4 0x020101
    sw $t4 512($v1)
    sw $t4 1060($v1)
    li $t4 0x010101
    sw $t4 544($v1)
    sw $t4 3108($v1)
    li $t4 0x000101
    sw $t4 1028($v1)
    sw $t4 2080($v1)
    li $t4 0x010001
    sw $t4 2084($v1)
    sw $t4 3620($v1)
    li $t4 0x090104
    sw $t4 12($v1)
    li $t4 0x2a130e
    sw $t4 16($v1)
    li $t4 0x1f0b0a
    sw $t4 20($v1)
    li $t4 0x250c0d
    sw $t4 520($v1)
    li $t4 0xbd5a41
    sw $t4 524($v1)
    li $t4 0xd34145
    sw $t4 528($v1)
    li $t4 0xd15746
    sw $t4 532($v1)
    li $t4 0x6f3827
    sw $t4 536($v1)
    li $t4 0x050603
    sw $t4 1024($v1)
    li $t4 0xa05d38
    sw $t4 1032($v1)
    li $t4 0xf7bd51
    sw $t4 1036($v1)
    li $t4 0xdb9340
    sw $t4 1040($v1)
    li $t4 0xe39d47
    sw $t4 1044($v1)
    li $t4 0xe3964c
    sw $t4 1048($v1)
    li $t4 0x210c0f
    sw $t4 1052($v1)
    li $t4 0x1a0007
    sw $t4 1540($v1)
    li $t4 0xc14448
    sw $t4 1544($v1)
    li $t4 0xd27a4e
    sw $t4 1548($v1)
    li $t4 0x915e68
    sw $t4 1552($v1)
    li $t4 0xb87b68
    sw $t4 1556($v1)
    li $t4 0x9a1e43
    sw $t4 1560($v1)
    li $t4 0x220102
    sw $t4 1564($v1)
    li $t4 0x020001
    sw $t4 1572($v1)
    li $t4 0x2e2c39
    sw $t4 2048($v1)
    li $t4 0x431531
    sw $t4 2052($v1)
    li $t4 0x8c0329
    sw $t4 2056($v1)
    li $t4 0xb4394f
    sw $t4 2060($v1)
    li $t4 0xa0919f
    sw $t4 2064($v1)
    li $t4 0xc49a92
    sw $t4 2068($v1)
    li $t4 0x8c1248
    sw $t4 2072($v1)
    li $t4 0x473252
    sw $t4 2076($v1)
    li $t4 0xc3bae3
    sw $t4 2560($v1)
    li $t4 0xd5c9ed
    sw $t4 2564($v1)
    li $t4 0x632d70
    sw $t4 2568($v1)
    li $t4 0x7e63ae
    sw $t4 2572($v1)
    li $t4 0x997bb4
    sw $t4 2576($v1)
    li $t4 0xa78fbc
    sw $t4 2580($v1)
    li $t4 0x955ead
    sw $t4 2584($v1)
    li $t4 0x614373
    sw $t4 2588($v1)
    li $t4 0x000200
    sw $t4 2592($v1)
    li $t4 0x020102
    sw $t4 2596($v1)
    li $t4 0xa89fca
    sw $t4 3072($v1)
    li $t4 0xe4ccec
    sw $t4 3076($v1)
    li $t4 0x64589c
    sw $t4 3080($v1)
    li $t4 0x342e92
    sw $t4 3084($v1)
    li $t4 0x8c5494
    sw $t4 3088($v1)
    li $t4 0x822857
    sw $t4 3092($v1)
    li $t4 0x683c76
    sw $t4 3096($v1)
    li $t4 0x3a2738
    sw $t4 3100($v1)
    li $t4 0x636078
    sw $t4 3584($v1)
    li $t4 0x4d323b
    sw $t4 3588($v1)
    li $t4 0x5d0744
    sw $t4 3592($v1)
    li $t4 0x3f3b9c
    sw $t4 3596($v1)
    li $t4 0xb593c7
    sw $t4 3600($v1)
    li $t4 0x996bad
    sw $t4 3604($v1)
    li $t4 0x560528
    sw $t4 3608($v1)
    li $t4 0x1b0403
    sw $t4 3612($v1)
    li $t4 0x02116f
    sw $t4 4104($v1)
    li $t4 0x3d5fc5
    sw $t4 4108($v1)
    li $t4 0x8ebfff
    sw $t4 4112($v1)
    li $t4 0x6da5ff
    sw $t4 4116($v1)
    li $t4 0x041356
    sw $t4 4120($v1)
    li $t4 0x040002
    sw $t4 4124($v1)
    li $t4 0x010103
    sw $t4 4128($v1)
    li $t4 0x030405
    sw $t4 4608($v1)
    li $t4 0x010202
    sw $t4 4612($v1)
    li $t4 0x090928
    sw $t4 4616($v1)
    li $t4 0x1a39a0
    sw $t4 4620($v1)
    li $t4 0x0055bb
    sw $t4 4624($v1)
    li $t4 0x00489c
    sw $t4 4628($v1)
    li $t4 0x040e2b
    sw $t4 4632($v1)
    li $t4 0x000102
    sw $t4 4640($v1)
    li $t4 0x090501
    sw $t4 5128($v1)
    li $t4 0x2e1821
    sw $t4 5132($v1)
    li $t4 0x1c0606
    sw $t4 5136($v1)
    li $t4 0x030000
    sw $t4 5140($v1)
    li $t4 0x000204
    sw $t4 5652($v1)
    li $t4 0x000001
    sw $t4 5656($v1)
    jr $ra
draw_doll_01_03: # start at v1, use t4
    draw16($0, 0, 4, 12, 16, 20, 28, 32, 36, 520, 536, 544, 548, 1024, 1060, 1568, 3584)
    draw4($0, 4608, 4636, 4644, 5156)
    draw4($0, 5632, 5636, 5652, 5656)
    sw $0 5660($v1)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x020101
    draw4($t4, 8, 516, 1572, 3620)
    li $t4 0x000100
    draw4($t4, 540, 2080, 3616, 4128)
    li $t4 0x000001
    draw4($t4, 5120, 5124, 5148, 5152)
    li $t4 0x010101
    sw $t4 512($v1)
    sw $t4 2596($v1)
    li $t4 0x000101
    sw $t4 2592($v1)
    sw $t4 4640($v1)
    li $t4 0x010001
    sw $t4 3108($v1)
    sw $t4 4132($v1)
    li $t4 0x070000
    sw $t4 5644($v1)
    sw $t4 5648($v1)
    li $t4 0x010200
    sw $t4 24($v1)
    li $t4 0x1d060a
    sw $t4 524($v1)
    li $t4 0x451917
    sw $t4 528($v1)
    li $t4 0x381112
    sw $t4 532($v1)
    li $t4 0x000200
    sw $t4 1028($v1)
    li $t4 0x401318
    sw $t4 1032($v1)
    li $t4 0xdd7b4b
    sw $t4 1036($v1)
    li $t4 0xe96b4c
    sw $t4 1040($v1)
    li $t4 0xec8f4e
    sw $t4 1044($v1)
    li $t4 0x904f32
    sw $t4 1048($v1)
    li $t4 0x030001
    sw $t4 1052($v1)
    li $t4 0x010100
    sw $t4 1056($v1)
    li $t4 0x16161e
    sw $t4 1536($v1)
    li $t4 0x140004
    sw $t4 1540($v1)
    li $t4 0xd06b46
    sw $t4 1544($v1)
    li $t4 0xe6a84d
    sw $t4 1548($v1)
    li $t4 0xbf6040
    sw $t4 1552($v1)
    li $t4 0xbe6345
    sw $t4 1556($v1)
    li $t4 0xde8c4b
    sw $t4 1560($v1)
    li $t4 0x250e0d
    sw $t4 1564($v1)
    li $t4 0xbcb8e2
    sw $t4 2048($v1)
    li $t4 0xae799f
    sw $t4 2052($v1)
    li $t4 0xb83e3a
    sw $t4 2056($v1)
    li $t4 0xbc5249
    sw $t4 2060($v1)
    li $t4 0x896e7e
    sw $t4 2064($v1)
    li $t4 0xbd8677
    sw $t4 2068($v1)
    li $t4 0x8f1340
    sw $t4 2072($v1)
    li $t4 0x2d0b14
    sw $t4 2076($v1)
    li $t4 0x020001
    sw $t4 2084($v1)
    li $t4 0xd9d0fb
    sw $t4 2560($v1)
    li $t4 0xdcd1ff
    sw $t4 2564($v1)
    li $t4 0x94074c
    sw $t4 2568($v1)
    li $t4 0xb13d57
    sw $t4 2572($v1)
    li $t4 0xaaa4a8
    sw $t4 2576($v1)
    li $t4 0xc4a09d
    sw $t4 2580($v1)
    li $t4 0x9f295f
    sw $t4 2584($v1)
    li $t4 0x684f7f
    sw $t4 2588($v1)
    li $t4 0x666177
    sw $t4 3072($v1)
    li $t4 0xa89cba
    sw $t4 3076($v1)
    li $t4 0x6a4496
    sw $t4 3080($v1)
    li $t4 0x655db0
    sw $t4 3084($v1)
    li $t4 0x8c6099
    sw $t4 3088($v1)
    li $t4 0x854d7f
    sw $t4 3092($v1)
    li $t4 0x7d58a4
    sw $t4 3096($v1)
    li $t4 0x3f264d
    sw $t4 3100($v1)
    li $t4 0x000302
    sw $t4 3104($v1)
    li $t4 0x2b1717
    sw $t4 3588($v1)
    li $t4 0x775895
    sw $t4 3592($v1)
    li $t4 0x342283
    sw $t4 3596($v1)
    li $t4 0x834c91
    sw $t4 3600($v1)
    li $t4 0x7d1b56
    sw $t4 3604($v1)
    li $t4 0x5c1b61
    sw $t4 3608($v1)
    li $t4 0x402531
    sw $t4 3612($v1)
    li $t4 0x030303
    sw $t4 4096($v1)
    li $t4 0x1d0808
    sw $t4 4100($v1)
    li $t4 0x4d0850
    sw $t4 4104($v1)
    li $t4 0x5f59ad
    sw $t4 4108($v1)
    li $t4 0xbbaee7
    sw $t4 4112($v1)
    li $t4 0xa093db
    sw $t4 4116($v1)
    li $t4 0x4f0e40
    sw $t4 4120($v1)
    li $t4 0x200505
    sw $t4 4124($v1)
    li $t4 0x000007
    sw $t4 4612($v1)
    li $t4 0x082392
    sw $t4 4616($v1)
    li $t4 0x0a53cc
    sw $t4 4620($v1)
    li $t4 0x037ff9
    sw $t4 4624($v1)
    li $t4 0x077ffb
    sw $t4 4628($v1)
    li $t4 0x042585
    sw $t4 4632($v1)
    li $t4 0x0a0830
    sw $t4 5128($v1)
    li $t4 0x122968
    sw $t4 5132($v1)
    li $t4 0x0d4685
    sw $t4 5136($v1)
    li $t4 0x023875
    sw $t4 5140($v1)
    li $t4 0x030a23
    sw $t4 5144($v1)
    li $t4 0x010000
    sw $t4 5640($v1)
    jr $ra
draw_doll_01_04: # start at v1, use t4
    draw16($0, 0, 36, 516, 544, 1056, 1536, 1540, 1568, 2084, 3620, 4096, 4100, 4132, 4616, 4640, 4644)
    draw4($0, 5120, 5124, 5128, 5148)
    draw4($0, 5152, 5156, 5632, 5636)
    draw4($0, 5640, 5656, 5660, 5664)
    sw $0 5668($v1)
    li $t4 0x010000
    draw4($t4, 1572, 3108, 4632, 4636)
    sw $t4 5132($v1)
    li $t4 0x000001
    sw $t4 2596($v1)
    sw $t4 5644($v1)
    sw $t4 5652($v1)
    li $t4 0x010100
    sw $t4 4($v1)
    sw $t4 32($v1)
    li $t4 0x040201
    sw $t4 548($v1)
    sw $t4 1060($v1)
    li $t4 0x000102
    sw $t4 3616($v1)
    sw $t4 5144($v1)
    li $t4 0x020001
    sw $t4 8($v1)
    li $t4 0x88412f
    sw $t4 12($v1)
    li $t4 0xd34446
    sw $t4 16($v1)
    li $t4 0xd44844
    sw $t4 20($v1)
    li $t4 0x7e2e2c
    sw $t4 24($v1)
    li $t4 0x040002
    sw $t4 28($v1)
    li $t4 0x030101
    sw $t4 512($v1)
    li $t4 0x4b171b
    sw $t4 520($v1)
    li $t4 0xf5aa52
    sw $t4 524($v1)
    li $t4 0xde7d45
    sw $t4 528($v1)
    li $t4 0xd57643
    sw $t4 532($v1)
    li $t4 0xf0994e
    sw $t4 536($v1)
    li $t4 0x52291d
    sw $t4 540($v1)
    li $t4 0x050303
    sw $t4 1024($v1)
    li $t4 0x030203
    sw $t4 1028($v1)
    li $t4 0x4e211c
    sw $t4 1032($v1)
    li $t4 0xe3814e
    sw $t4 1036($v1)
    li $t4 0x945650
    sw $t4 1040($v1)
    li $t4 0x9e5555
    sw $t4 1044($v1)
    li $t4 0xb9564d
    sw $t4 1048($v1)
    li $t4 0x52251b
    sw $t4 1052($v1)
    li $t4 0x190001
    sw $t4 1544($v1)
    li $t4 0xc0303e
    sw $t4 1548($v1)
    li $t4 0x9a7488
    sw $t4 1552($v1)
    li $t4 0xc5b7a8
    sw $t4 1556($v1)
    li $t4 0x902e4c
    sw $t4 1560($v1)
    li $t4 0x070000
    sw $t4 1564($v1)
    li $t4 0x1e1923
    sw $t4 2048($v1)
    li $t4 0x3d3d4c
    sw $t4 2052($v1)
    li $t4 0x5a2c5b
    sw $t4 2056($v1)
    li $t4 0x7d3b82
    sw $t4 2060($v1)
    li $t4 0xa28dbc
    sw $t4 2064($v1)
    li $t4 0x94739b
    sw $t4 2068($v1)
    li $t4 0xa877b3
    sw $t4 2072($v1)
    li $t4 0x66457e
    sw $t4 2076($v1)
    li $t4 0x080a0e
    sw $t4 2080($v1)
    li $t4 0x8b84a6
    sw $t4 2560($v1)
    li $t4 0xe9d4ff
    sw $t4 2564($v1)
    li $t4 0x8678bd
    sw $t4 2568($v1)
    li $t4 0x262e93
    sw $t4 2572($v1)
    li $t4 0xa88fc9
    sw $t4 2576($v1)
    li $t4 0xa03f65
    sw $t4 2580($v1)
    li $t4 0x55409a
    sw $t4 2584($v1)
    li $t4 0x4f306e
    sw $t4 2588($v1)
    li $t4 0x140d0c
    sw $t4 2592($v1)
    li $t4 0x8c82a8
    sw $t4 3072($v1)
    li $t4 0xd0c7e6
    sw $t4 3076($v1)
    li $t4 0x8a2745
    sw $t4 3080($v1)
    li $t4 0x321273
    sw $t4 3084($v1)
    li $t4 0x7e71bf
    sw $t4 3088($v1)
    li $t4 0xa475b3
    sw $t4 3092($v1)
    li $t4 0x50003f
    sw $t4 3096($v1)
    li $t4 0x63242d
    sw $t4 3100($v1)
    li $t4 0x080502
    sw $t4 3104($v1)
    li $t4 0x2c2838
    sw $t4 3584($v1)
    li $t4 0x19161f
    sw $t4 3588($v1)
    li $t4 0x0a0019
    sw $t4 3592($v1)
    li $t4 0x01239c
    sw $t4 3596($v1)
    li $t4 0xbcb9e5
    sw $t4 3600($v1)
    li $t4 0xcecfff
    sw $t4 3604($v1)
    li $t4 0x0b2676
    sw $t4 3608($v1)
    li $t4 0x040000
    sw $t4 3612($v1)
    li $t4 0x02020f
    sw $t4 4104($v1)
    li $t4 0x07248d
    sw $t4 4108($v1)
    li $t4 0x4676d7
    sw $t4 4112($v1)
    li $t4 0x4371d0
    sw $t4 4116($v1)
    li $t4 0x00255a
    sw $t4 4120($v1)
    li $t4 0x010201
    sw $t4 4124($v1)
    li $t4 0x000103
    sw $t4 4128($v1)
    li $t4 0x020202
    sw $t4 4608($v1)
    li $t4 0x020203
    sw $t4 4612($v1)
    li $t4 0x1e111e
    sw $t4 4620($v1)
    li $t4 0x191538
    sw $t4 4624($v1)
    li $t4 0x000115
    sw $t4 4628($v1)
    li $t4 0x050000
    sw $t4 5136($v1)
    li $t4 0x040100
    sw $t4 5140($v1)
    li $t4 0x000002
    sw $t4 5648($v1)
    jr $ra
draw_doll_01_05: # start at v1, use t4
    draw16($0, 0, 8, 1024, 1028, 1056, 2084, 2596, 3108, 3584, 3588, 3616, 4608, 4612, 4620, 4636, 4640)
    draw16($0, 4644, 5120, 5124, 5128, 5136, 5148, 5152, 5156, 5632, 5636, 5640, 5644, 5656, 5660, 5664, 5668)
    li $t4 0x010000
    sw $t4 36($v1)
    sw $t4 1572($v1)
    li $t4 0x020101
    sw $t4 512($v1)
    sw $t4 1060($v1)
    li $t4 0x000001
    sw $t4 3620($v1)
    sw $t4 4132($v1)
    li $t4 0x000101
    sw $t4 4128($v1)
    sw $t4 5132($v1)
    li $t4 0x000002
    sw $t4 5648($v1)
    sw $t4 5652($v1)
    li $t4 0x020201
    sw $t4 4($v1)
    li $t4 0x58251f
    sw $t4 12($v1)
    li $t4 0xcf5045
    sw $t4 16($v1)
    li $t4 0xd54644
    sw $t4 20($v1)
    li $t4 0xa8443a
    sw $t4 24($v1)
    li $t4 0x19080a
    sw $t4 28($v1)
    li $t4 0x010100
    sw $t4 32($v1)
    li $t4 0x010201
    sw $t4 516($v1)
    li $t4 0x160309
    sw $t4 520($v1)
    li $t4 0xe19b4c
    sw $t4 524($v1)
    li $t4 0xe69249
    sw $t4 528($v1)
    li $t4 0xd26f41
    sw $t4 532($v1)
    li $t4 0xe78c4b
    sw $t4 536($v1)
    li $t4 0x905b32
    sw $t4 540($v1)
    li $t4 0x010101
    sw $t4 544($v1)
    li $t4 0x030301
    sw $t4 548($v1)
    li $t4 0x2c0a12
    sw $t4 1032($v1)
    li $t4 0xe3824e
    sw $t4 1036($v1)
    li $t4 0xa7584d
    sw $t4 1040($v1)
    li $t4 0x986057
    sw $t4 1044($v1)
    li $t4 0xb75556
    sw $t4 1048($v1)
    li $t4 0x81232a
    sw $t4 1052($v1)
    li $t4 0x0f0c12
    sw $t4 1536($v1)
    li $t4 0x06040a
    sw $t4 1540($v1)
    li $t4 0x110001
    sw $t4 1544($v1)
    li $t4 0xb31f37
    sw $t4 1548($v1)
    li $t4 0xa55a6d
    sw $t4 1552($v1)
    li $t4 0xb3b7b0
    sw $t4 1556($v1)
    li $t4 0xb25765
    sw $t4 1560($v1)
    li $t4 0x680e41
    sw $t4 1564($v1)
    li $t4 0x171922
    sw $t4 1568($v1)
    li $t4 0x554d67
    sw $t4 2048($v1)
    li $t4 0xc2bbd8
    sw $t4 2052($v1)
    li $t4 0x7d678e
    sw $t4 2056($v1)
    li $t4 0x68195f
    sw $t4 2060($v1)
    li $t4 0xaa91c4
    sw $t4 2064($v1)
    li $t4 0x8d719a
    sw $t4 2068($v1)
    li $t4 0xa97bae
    sw $t4 2072($v1)
    li $t4 0x924995
    sw $t4 2076($v1)
    li $t4 0x28293c
    sw $t4 2080($v1)
    li $t4 0x2d2837
    sw $t4 2560($v1)
    li $t4 0xe4d7ff
    sw $t4 2564($v1)
    li $t4 0xc2adda
    sw $t4 2568($v1)
    li $t4 0x293394
    sw $t4 2572($v1)
    li $t4 0x7062b3
    sw $t4 2576($v1)
    li $t4 0x9a3767
    sw $t4 2580($v1)
    li $t4 0x622d74
    sw $t4 2584($v1)
    li $t4 0x4c3990
    sw $t4 2588($v1)
    li $t4 0x2d1b23
    sw $t4 2592($v1)
    li $t4 0x363040
    sw $t4 3072($v1)
    li $t4 0x7e7d93
    sw $t4 3076($v1)
    li $t4 0x712a38
    sw $t4 3080($v1)
    li $t4 0x491267
    sw $t4 3084($v1)
    li $t4 0x5b51ac
    sw $t4 3088($v1)
    li $t4 0xb489c0
    sw $t4 3092($v1)
    li $t4 0x6a175d
    sw $t4 3096($v1)
    li $t4 0x5d0c25
    sw $t4 3100($v1)
    li $t4 0x160a08
    sw $t4 3104($v1)
    li $t4 0x090018
    sw $t4 3592($v1)
    li $t4 0x0223a1
    sw $t4 3596($v1)
    li $t4 0x898acf
    sw $t4 3600($v1)
    li $t4 0xfcffff
    sw $t4 3604($v1)
    li $t4 0x416dcc
    sw $t4 3608($v1)
    li $t4 0x02000b
    sw $t4 3612($v1)
    li $t4 0x010102
    sw $t4 4096($v1)
    li $t4 0x030404
    sw $t4 4100($v1)
    li $t4 0x01030b
    sw $t4 4104($v1)
    li $t4 0x071764
    sw $t4 4108($v1)
    li $t4 0x2955ba
    sw $t4 4112($v1)
    li $t4 0x5383df
    sw $t4 4116($v1)
    li $t4 0x054699
    sw $t4 4120($v1)
    li $t4 0x01030e
    sw $t4 4124($v1)
    li $t4 0x020100
    sw $t4 4616($v1)
    li $t4 0x201427
    sw $t4 4624($v1)
    li $t4 0x321f3e
    sw $t4 4628($v1)
    li $t4 0x030000
    sw $t4 4632($v1)
    li $t4 0x020000
    sw $t4 5140($v1)
    li $t4 0x010202
    sw $t4 5144($v1)
    jr $ra
draw_doll_01_06: # start at v1, use t4
    draw16($0, 0, 512, 1028, 1060, 1572, 2084, 2596, 3072, 3108, 4100, 4608, 4644, 5120, 5124, 5128, 5132)
    draw4($0, 5152, 5156, 5632, 5636)
    draw4($0, 5640, 5660, 5664, 5668)
    li $t4 0x000001
    draw4($t4, 3584, 4096, 4612, 5148)
    sw $t4 5644($v1)
    sw $t4 5656($v1)
    li $t4 0x010000
    sw $t4 4616($v1)
    sw $t4 4636($v1)
    sw $t4 5136($v1)
    li $t4 0x010001
    sw $t4 4($v1)
    sw $t4 36($v1)
    li $t4 0x000002
    sw $t4 5648($v1)
    sw $t4 5652($v1)
    li $t4 0x020101
    sw $t4 8($v1)
    li $t4 0x0f0006
    sw $t4 12($v1)
    li $t4 0x81302c
    sw $t4 16($v1)
    li $t4 0xa43234
    sw $t4 20($v1)
    li $t4 0x862a2d
    sw $t4 24($v1)
    li $t4 0x150009
    sw $t4 28($v1)
    li $t4 0x000100
    sw $t4 32($v1)
    li $t4 0x030401
    sw $t4 516($v1)
    li $t4 0x000201
    sw $t4 520($v1)
    li $t4 0x8c5131
    sw $t4 524($v1)
    li $t4 0xf49951
    sw $t4 528($v1)
    li $t4 0xe37449
    sw $t4 532($v1)
    li $t4 0xf39b50
    sw $t4 536($v1)
    li $t4 0xaf753b
    sw $t4 540($v1)
    li $t4 0x040303
    sw $t4 544($v1)
    li $t4 0x020201
    sw $t4 548($v1)
    li $t4 0x040204
    sw $t4 1024($v1)
    li $t4 0x1c0003
    sw $t4 1032($v1)
    li $t4 0xeb9250
    sw $t4 1036($v1)
    li $t4 0xd6964b
    sw $t4 1040($v1)
    li $t4 0xb27743
    sw $t4 1044($v1)
    li $t4 0xc2784c
    sw $t4 1048($v1)
    li $t4 0xc85c46
    sw $t4 1052($v1)
    li $t4 0x310d0a
    sw $t4 1056($v1)
    li $t4 0x211a28
    sw $t4 1536($v1)
    li $t4 0xa3a2c2
    sw $t4 1540($v1)
    li $t4 0x7e335b
    sw $t4 1544($v1)
    li $t4 0xba2e37
    sw $t4 1548($v1)
    li $t4 0xb74c55
    sw $t4 1552($v1)
    li $t4 0x978da2
    sw $t4 1556($v1)
    li $t4 0xbb8278
    sw $t4 1560($v1)
    li $t4 0x840445
    sw $t4 1564($v1)
    li $t4 0x3d223a
    sw $t4 1568($v1)
    li $t4 0x1b1623
    sw $t4 2048($v1)
    li $t4 0xdcd1fd
    sw $t4 2052($v1)
    li $t4 0xe5e4ff
    sw $t4 2056($v1)
    li $t4 0x992f6f
    sw $t4 2060($v1)
    li $t4 0x9f4b77
    sw $t4 2064($v1)
    li $t4 0xa597ac
    sw $t4 2068($v1)
    li $t4 0xaf7c9f
    sw $t4 2072($v1)
    li $t4 0xa4407e
    sw $t4 2076($v1)
    li $t4 0x52466c
    sw $t4 2080($v1)
    li $t4 0x0b0a0f
    sw $t4 2560($v1)
    li $t4 0x928caa
    sw $t4 2564($v1)
    li $t4 0xcea7d1
    sw $t4 2568($v1)
    li $t4 0x6155a4
    sw $t4 2572($v1)
    li $t4 0x3951b2
    sw $t4 2576($v1)
    li $t4 0x90528c
    sw $t4 2580($v1)
    li $t4 0x79457c
    sw $t4 2584($v1)
    li $t4 0x4f4aac
    sw $t4 2588($v1)
    li $t4 0x2c1c3c
    sw $t4 2592($v1)
    li $t4 0x040000
    sw $t4 3076($v1)
    li $t4 0x980b36
    sw $t4 3080($v1)
    li $t4 0x773767
    sw $t4 3084($v1)
    li $t4 0x323099
    sw $t4 3088($v1)
    li $t4 0x935c98
    sw $t4 3092($v1)
    li $t4 0x721e5c
    sw $t4 3096($v1)
    li $t4 0x540a4b
    sw $t4 3100($v1)
    li $t4 0x311825
    sw $t4 3104($v1)
    li $t4 0x0a0205
    sw $t4 3588($v1)
    li $t4 0x33021e
    sw $t4 3592($v1)
    li $t4 0x111380
    sw $t4 3596($v1)
    li $t4 0x565fb7
    sw $t4 3600($v1)
    li $t4 0xfef2ff
    sw $t4 3604($v1)
    li $t4 0x8a96de
    sw $t4 3608($v1)
    li $t4 0x190223
    sw $t4 3612($v1)
    li $t4 0x0b0000
    sw $t4 3616($v1)
    li $t4 0x000101
    sw $t4 3620($v1)
    li $t4 0x00020f
    sw $t4 4104($v1)
    li $t4 0x072a91
    sw $t4 4108($v1)
    li $t4 0x1e65d1
    sw $t4 4112($v1)
    li $t4 0x8aa7eb
    sw $t4 4116($v1)
    li $t4 0x308bef
    sw $t4 4120($v1)
    li $t4 0x001947
    sw $t4 4124($v1)
    li $t4 0x010101
    sw $t4 4128($v1)
    li $t4 0x000103
    sw $t4 4132($v1)
    li $t4 0x020008
    sw $t4 4620($v1)
    li $t4 0x000823
    sw $t4 4624($v1)
    li $t4 0x343578
    sw $t4 4628($v1)
    li $t4 0x171637
    sw $t4 4632($v1)
    li $t4 0x010102
    sw $t4 4640($v1)
    li $t4 0x0f0400
    sw $t4 5140($v1)
    li $t4 0x0a0300
    sw $t4 5144($v1)
    jr $ra
draw_doll_01_07: # start at v1, use t4
    draw16($0, 0, 4, 12, 28, 36, 512, 544, 1028, 1032, 1060, 2048, 2560, 3072, 3584, 4096, 4128)
    draw4($0, 4608, 5120, 5124, 5128)
    draw4($0, 5132, 5136, 5140, 5152)
    draw4($0, 5632, 5636, 5640, 5656)
    sw $0 5660($v1)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x010000
    sw $t4 8($v1)
    sw $t4 1024($v1)
    li $t4 0x020001
    sw $t4 1536($v1)
    sw $t4 4616($v1)
    li $t4 0x010001
    sw $t4 4640($v1)
    sw $t4 5156($v1)
    li $t4 0x010103
    sw $t4 4644($v1)
    sw $t4 5652($v1)
    li $t4 0x040002
    sw $t4 16($v1)
    li $t4 0x260d0d
    sw $t4 20($v1)
    li $t4 0x220a0b
    sw $t4 24($v1)
    li $t4 0x000100
    sw $t4 32($v1)
    li $t4 0x030203
    sw $t4 516($v1)
    li $t4 0x010201
    sw $t4 520($v1)
    li $t4 0x1a020a
    sw $t4 524($v1)
    li $t4 0xb45d3d
    sw $t4 528($v1)
    li $t4 0xdd5a48
    sw $t4 532($v1)
    li $t4 0xdb6c46
    sw $t4 536($v1)
    li $t4 0x7e3e2d
    sw $t4 540($v1)
    li $t4 0x010101
    sw $t4 548($v1)
    li $t4 0xb15540
    sw $t4 1036($v1)
    li $t4 0xf5b750
    sw $t4 1040($v1)
    li $t4 0xbf653c
    sw $t4 1044($v1)
    li $t4 0xc87347
    sw $t4 1048($v1)
    li $t4 0xf2a450
    sw $t4 1052($v1)
    li $t4 0x4b2d1a
    sw $t4 1056($v1)
    li $t4 0x2c2d3b
    sw $t4 1540($v1)
    li $t4 0x5b1c36
    sw $t4 1544($v1)
    li $t4 0xcc5139
    sw $t4 1548($v1)
    li $t4 0xd17b52
    sw $t4 1552($v1)
    li $t4 0x6d5077
    sw $t4 1556($v1)
    li $t4 0xbe8577
    sw $t4 1560($v1)
    li $t4 0xae3a4a
    sw $t4 1564($v1)
    li $t4 0x6d2420
    sw $t4 1568($v1)
    li $t4 0x000101
    sw $t4 1572($v1)
    li $t4 0x726c8a
    sw $t4 2052($v1)
    li $t4 0xddbde7
    sw $t4 2056($v1)
    li $t4 0x9b255b
    sw $t4 2060($v1)
    li $t4 0xab2138
    sw $t4 2064($v1)
    li $t4 0xb39094
    sw $t4 2068($v1)
    li $t4 0xd1ad98
    sw $t4 2072($v1)
    li $t4 0x941c50
    sw $t4 2076($v1)
    li $t4 0x6d4579
    sw $t4 2080($v1)
    li $t4 0x030607
    sw $t4 2084($v1)
    li $t4 0x574f69
    sw $t4 2564($v1)
    li $t4 0xf0ffff
    sw $t4 2568($v1)
    li $t4 0x9f679f
    sw $t4 2572($v1)
    li $t4 0x623f8f
    sw $t4 2576($v1)
    li $t4 0x7d73b5
    sw $t4 2580($v1)
    li $t4 0x8e6a9e
    sw $t4 2584($v1)
    li $t4 0x9e6caf
    sw $t4 2588($v1)
    li $t4 0x593669
    sw $t4 2592($v1)
    li $t4 0x040809
    sw $t4 2596($v1)
    li $t4 0x3a1328
    sw $t4 3076($v1)
    li $t4 0xb84a87
    sw $t4 3080($v1)
    li $t4 0xb04c58
    sw $t4 3084($v1)
    li $t4 0x4e4f9e
    sw $t4 3088($v1)
    li $t4 0x4c2b79
    sw $t4 3092($v1)
    li $t4 0x79123f
    sw $t4 3096($v1)
    li $t4 0x3c2285
    sw $t4 3100($v1)
    li $t4 0x3a285d
    sw $t4 3104($v1)
    li $t4 0x040101
    sw $t4 3108($v1)
    li $t4 0x1f000a
    sw $t4 3588($v1)
    li $t4 0x46000e
    sw $t4 3592($v1)
    li $t4 0x44064c
    sw $t4 3596($v1)
    li $t4 0x2b298d
    sw $t4 3600($v1)
    li $t4 0xaf9bd2
    sw $t4 3604($v1)
    li $t4 0xbc9fcc
    sw $t4 3608($v1)
    li $t4 0x6a1041
    sw $t4 3612($v1)
    li $t4 0x350b14
    sw $t4 3616($v1)
    li $t4 0x010200
    sw $t4 3620($v1)
    li $t4 0x000200
    sw $t4 4100($v1)
    li $t4 0x000300
    sw $t4 4104($v1)
    li $t4 0x04268e
    sw $t4 4108($v1)
    li $t4 0x116be4
    sw $t4 4112($v1)
    li $t4 0xa0a7e5
    sw $t4 4116($v1)
    li $t4 0xb0c6fb
    sw $t4 4120($v1)
    li $t4 0x17438b
    sw $t4 4124($v1)
    li $t4 0x000203
    sw $t4 4132($v1)
    li $t4 0x000001
    sw $t4 4612($v1)
    li $t4 0x050a29
    sw $t4 4620($v1)
    li $t4 0x031348
    sw $t4 4624($v1)
    li $t4 0x01053b
    sw $t4 4628($v1)
    li $t4 0x544baf
    sw $t4 4632($v1)
    li $t4 0x202454
    sw $t4 4636($v1)
    li $t4 0x35212b
    sw $t4 5144($v1)
    li $t4 0x25131a
    sw $t4 5148($v1)
    li $t4 0x000002
    sw $t4 5644($v1)
    li $t4 0x000103
    sw $t4 5648($v1)
    jr $ra
draw_doll_01_08: # start at v1, use t4
    draw16($0, 0, 4, 8, 16, 20, 24, 28, 36, 512, 516, 524, 544, 548, 1024, 1032, 2048)
    draw4($0, 3584, 4096, 4608, 4616)
    draw4($0, 5120, 5124, 5140, 5632)
    sw $0 5636($v1)
    sw $0 5640($v1)
    sw $0 5668($v1)
    li $t4 0x010000
    sw $t4 1028($v1)
    sw $t4 5128($v1)
    sw $t4 5132($v1)
    li $t4 0x020000
    sw $t4 3620($v1)
    sw $t4 5136($v1)
    sw $t4 5152($v1)
    li $t4 0x000001
    sw $t4 4100($v1)
    sw $t4 4612($v1)
    sw $t4 5644($v1)
    li $t4 0x000200
    sw $t4 32($v1)
    sw $t4 3072($v1)
    li $t4 0x020101
    sw $t4 520($v1)
    sw $t4 5664($v1)
    li $t4 0x010102
    sw $t4 4644($v1)
    sw $t4 5156($v1)
    li $t4 0x020100
    sw $t4 12($v1)
    li $t4 0x26050e
    sw $t4 528($v1)
    li $t4 0x6f2127
    sw $t4 532($v1)
    li $t4 0x843a2a
    sw $t4 536($v1)
    li $t4 0x571e1e
    sw $t4 540($v1)
    li $t4 0x5d1c21
    sw $t4 1036($v1)
    li $t4 0xe1804a
    sw $t4 1040($v1)
    li $t4 0xfebf53
    sw $t4 1044($v1)
    li $t4 0xf4964d
    sw $t4 1048($v1)
    li $t4 0xf6a751
    sw $t4 1052($v1)
    li $t4 0x936134
    sw $t4 1056($v1)
    li $t4 0x080304
    sw $t4 1060($v1)
    li $t4 0x020001
    sw $t4 1536($v1)
    li $t4 0x030405
    sw $t4 1540($v1)
    li $t4 0x390e25
    sw $t4 1544($v1)
    li $t4 0xb42037
    sw $t4 1548($v1)
    li $t4 0xf3b54f
    sw $t4 1552($v1)
    li $t4 0xbf894e
    sw $t4 1556($v1)
    li $t4 0x975552
    sw $t4 1560($v1)
    li $t4 0xc2544b
    sw $t4 1564($v1)
    li $t4 0xc3583f
    sw $t4 1568($v1)
    li $t4 0x190208
    sw $t4 1572($v1)
    li $t4 0x0f0d14
    sw $t4 2052($v1)
    li $t4 0xc1aadc
    sw $t4 2056($v1)
    li $t4 0xab4c7c
    sw $t4 2060($v1)
    li $t4 0xb13237
    sw $t4 2064($v1)
    li $t4 0xb0656d
    sw $t4 2068($v1)
    li $t4 0xb6c1b4
    sw $t4 2072($v1)
    li $t4 0xbc736d
    sw $t4 2076($v1)
    li $t4 0x730f45
    sw $t4 2080($v1)
    li $t4 0x0c0b11
    sw $t4 2084($v1)
    li $t4 0x010101
    sw $t4 2560($v1)
    li $t4 0x030408
    sw $t4 2564($v1)
    li $t4 0xb8bce0
    sw $t4 2568($v1)
    li $t4 0xdfe1ff
    sw $t4 2572($v1)
    li $t4 0x870d58
    sw $t4 2576($v1)
    li $t4 0x934c79
    sw $t4 2580($v1)
    li $t4 0xa492a2
    sw $t4 2584($v1)
    li $t4 0xb86886
    sw $t4 2588($v1)
    li $t4 0x924c8d
    sw $t4 2592($v1)
    li $t4 0x1d2330
    sw $t4 2596($v1)
    li $t4 0x23020d
    sw $t4 3076($v1)
    li $t4 0xbc6aa1
    sw $t4 3080($v1)
    li $t4 0xb2689b
    sw $t4 3084($v1)
    li $t4 0x9b3e59
    sw $t4 3088($v1)
    li $t4 0x8085cb
    sw $t4 3092($v1)
    li $t4 0x966098
    sw $t4 3096($v1)
    li $t4 0x6b4c98
    sw $t4 3100($v1)
    li $t4 0x4a3172
    sw $t4 3104($v1)
    li $t4 0x0f0d12
    sw $t4 3108($v1)
    li $t4 0x170008
    sw $t4 3588($v1)
    li $t4 0x750027
    sw $t4 3592($v1)
    li $t4 0x95002c
    sw $t4 3596($v1)
    li $t4 0x631953
    sw $t4 3600($v1)
    li $t4 0x2f2c90
    sw $t4 3604($v1)
    li $t4 0xa34c7f
    sw $t4 3608($v1)
    li $t4 0x7c1c5c
    sw $t4 3612($v1)
    li $t4 0x4a1e46
    sw $t4 3616($v1)
    li $t4 0x100308
    sw $t4 4104($v1)
    li $t4 0x350737
    sw $t4 4108($v1)
    li $t4 0x0431b0
    sw $t4 4112($v1)
    li $t4 0x4872d0
    sw $t4 4116($v1)
    li $t4 0x7c98e3
    sw $t4 4120($v1)
    li $t4 0x758edc
    sw $t4 4124($v1)
    li $t4 0x42253c
    sw $t4 4128($v1)
    li $t4 0x000101
    sw $t4 4132($v1)
    li $t4 0x00030f
    sw $t4 4620($v1)
    li $t4 0x03185a
    sw $t4 4624($v1)
    li $t4 0x26257e
    sw $t4 4628($v1)
    li $t4 0x7468cb
    sw $t4 4632($v1)
    li $t4 0x1c3482
    sw $t4 4636($v1)
    li $t4 0x000103
    sw $t4 4640($v1)
    li $t4 0x5a446d
    sw $t4 5144($v1)
    li $t4 0x5d406d
    sw $t4 5148($v1)
    li $t4 0x010103
    sw $t4 5648($v1)
    li $t4 0x010100
    sw $t4 5652($v1)
    li $t4 0x050100
    sw $t4 5656($v1)
    li $t4 0x120904
    sw $t4 5660($v1)
    jr $ra
draw_doll_01_09: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 36, 512, 516, 520, 524, 528, 532, 536, 540, 544, 1024, 1028)
    draw16($0, 1060, 1536, 1540, 2048, 2564, 3076, 4096, 4608, 4612, 5120, 5632, 5636, 5640, 5644, 5652, 5668)
    li $t4 0x020101
    draw4($t4, 24, 32, 548, 1032)
    li $t4 0x010101
    sw $t4 16($v1)
    sw $t4 5128($v1)
    li $t4 0x030201
    sw $t4 20($v1)
    sw $t4 28($v1)
    li $t4 0x020202
    sw $t4 2560($v1)
    sw $t4 3584($v1)
    li $t4 0x010100
    sw $t4 1036($v1)
    li $t4 0x1b060a
    sw $t4 1040($v1)
    li $t4 0x8a3330
    sw $t4 1044($v1)
    li $t4 0xa54836
    sw $t4 1048($v1)
    li $t4 0x994c32
    sw $t4 1052($v1)
    li $t4 0x21040d
    sw $t4 1056($v1)
    li $t4 0x010200
    sw $t4 1544($v1)
    li $t4 0x020003
    sw $t4 1548($v1)
    li $t4 0xa34c38
    sw $t4 1552($v1)
    li $t4 0xffd856
    sw $t4 1556($v1)
    li $t4 0xea9148
    sw $t4 1560($v1)
    li $t4 0xf0a24e
    sw $t4 1564($v1)
    li $t4 0xd48a48
    sw $t4 1568($v1)
    li $t4 0x351e16
    sw $t4 1572($v1)
    li $t4 0x030101
    sw $t4 2052($v1)
    li $t4 0x030307
    sw $t4 2056($v1)
    li $t4 0x3f0210
    sw $t4 2060($v1)
    li $t4 0xe98b4d
    sw $t4 2064($v1)
    li $t4 0xd49852
    sw $t4 2068($v1)
    li $t4 0x82535e
    sw $t4 2072($v1)
    li $t4 0xb95a58
    sw $t4 2076($v1)
    li $t4 0xbd4243
    sw $t4 2080($v1)
    li $t4 0x701522
    sw $t4 2084($v1)
    li $t4 0x8b86a8
    sw $t4 2568($v1)
    li $t4 0xb16390
    sw $t4 2572($v1)
    li $t4 0xa92337
    sw $t4 2576($v1)
    li $t4 0xb8474d
    sw $t4 2580($v1)
    li $t4 0xb2afac
    sw $t4 2584($v1)
    li $t4 0xcea589
    sw $t4 2588($v1)
    li $t4 0x850c43
    sw $t4 2592($v1)
    li $t4 0x4d274c
    sw $t4 2596($v1)
    li $t4 0x030303
    sw $t4 3072($v1)
    li $t4 0x82809f
    sw $t4 3080($v1)
    li $t4 0xeef8ff
    sw $t4 3084($v1)
    li $t4 0x8d2d75
    sw $t4 3088($v1)
    li $t4 0x87326f
    sw $t4 3092($v1)
    li $t4 0x907ba2
    sw $t4 3096($v1)
    li $t4 0xaf86a5
    sw $t4 3100($v1)
    li $t4 0xa54581
    sw $t4 3104($v1)
    li $t4 0x675080
    sw $t4 3108($v1)
    li $t4 0x040002
    sw $t4 3588($v1)
    li $t4 0x914f7c
    sw $t4 3592($v1)
    li $t4 0xd2a2cb
    sw $t4 3596($v1)
    li $t4 0xa05f79
    sw $t4 3600($v1)
    li $t4 0x4564bd
    sw $t4 3604($v1)
    li $t4 0x713e7f
    sw $t4 3608($v1)
    li $t4 0x7f376b
    sw $t4 3612($v1)
    li $t4 0x4946a7
    sw $t4 3616($v1)
    li $t4 0x37234f
    sw $t4 3620($v1)
    li $t4 0x110007
    sw $t4 4100($v1)
    li $t4 0x2b000c
    sw $t4 4104($v1)
    li $t4 0x5d001d
    sw $t4 4108($v1)
    li $t4 0x7e1c48
    sw $t4 4112($v1)
    li $t4 0x392585
    sw $t4 4116($v1)
    li $t4 0x8c61a2
    sw $t4 4120($v1)
    li $t4 0x873c75
    sw $t4 4124($v1)
    li $t4 0x5e1156
    sw $t4 4128($v1)
    li $t4 0x3c1c2d
    sw $t4 4132($v1)
    li $t4 0x000200
    sw $t4 4616($v1)
    li $t4 0x03030a
    sw $t4 4620($v1)
    li $t4 0x0e2699
    sw $t4 4624($v1)
    li $t4 0x005cd5
    sw $t4 4628($v1)
    li $t4 0x8ca4ea
    sw $t4 4632($v1)
    li $t4 0xf1f3ff
    sw $t4 4636($v1)
    li $t4 0x755e7a
    sw $t4 4640($v1)
    li $t4 0x050000
    sw $t4 4644($v1)
    li $t4 0x000001
    sw $t4 5124($v1)
    li $t4 0x010006
    sw $t4 5132($v1)
    li $t4 0x092470
    sw $t4 5136($v1)
    li $t4 0x06439e
    sw $t4 5140($v1)
    li $t4 0x24419a
    sw $t4 5144($v1)
    li $t4 0x6861b1
    sw $t4 5148($v1)
    li $t4 0x080e22
    sw $t4 5152($v1)
    li $t4 0x000101
    sw $t4 5156($v1)
    li $t4 0x010000
    sw $t4 5648($v1)
    li $t4 0x180809
    sw $t4 5656($v1)
    li $t4 0x200f13
    sw $t4 5660($v1)
    li $t4 0x020000
    sw $t4 5664($v1)
    jr $ra
draw_doll_01_10: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 512, 516, 520, 524, 528, 548)
    draw16($0, 1024, 1028, 1032, 1036, 1044, 1048, 1052, 1056, 1536, 1540, 1552, 1572, 2048, 2052, 2056, 2060)
    draw4($0, 2564, 3076, 3588, 4100)
    draw4($0, 4608, 4616, 5120, 5124)
    sw $0 5632($v1)
    sw $0 5636($v1)
    sw $0 5644($v1)
    li $t4 0x030101
    sw $t4 532($v1)
    sw $t4 536($v1)
    sw $t4 540($v1)
    li $t4 0x010100
    sw $t4 1040($v1)
    sw $t4 1060($v1)
    li $t4 0x000001
    sw $t4 1544($v1)
    sw $t4 2560($v1)
    li $t4 0x000101
    sw $t4 5640($v1)
    sw $t4 5668($v1)
    li $t4 0x020101
    sw $t4 544($v1)
    li $t4 0x020202
    sw $t4 1548($v1)
    li $t4 0x421817
    sw $t4 1556($v1)
    li $t4 0x862c2d
    sw $t4 1560($v1)
    li $t4 0x8b322c
    sw $t4 1564($v1)
    li $t4 0x2c0511
    sw $t4 1568($v1)
    li $t4 0x371616
    sw $t4 2064($v1)
    li $t4 0xea964f
    sw $t4 2068($v1)
    li $t4 0xea5d48
    sw $t4 2072($v1)
    li $t4 0xe66748
    sw $t4 2076($v1)
    li $t4 0xdd884a
    sw $t4 2080($v1)
    li $t4 0x2a1711
    sw $t4 2084($v1)
    li $t4 0x0e0c0f
    sw $t4 2568($v1)
    li $t4 0x0e0b15
    sw $t4 2572($v1)
    li $t4 0x753122
    sw $t4 2576($v1)
    li $t4 0xf7aa56
    sw $t4 2580($v1)
    li $t4 0x864945
    sw $t4 2584($v1)
    li $t4 0x984043
    sw $t4 2588($v1)
    li $t4 0xce6f49
    sw $t4 2592($v1)
    li $t4 0x854927
    sw $t4 2596($v1)
    li $t4 0x020203
    sw $t4 3072($v1)
    li $t4 0x2a2533
    sw $t4 3080($v1)
    li $t4 0xb9b2dc
    sw $t4 3084($v1)
    li $t4 0x9f3a54
    sw $t4 3088($v1)
    li $t4 0xcb4b3e
    sw $t4 3092($v1)
    li $t4 0x9f8091
    sw $t4 3096($v1)
    li $t4 0xcdb096
    sw $t4 3100($v1)
    li $t4 0x93244b
    sw $t4 3104($v1)
    li $t4 0x6f284d
    sw $t4 3108($v1)
    li $t4 0x020102
    sw $t4 3584($v1)
    li $t4 0x15111a
    sw $t4 3592($v1)
    li $t4 0xe1e1ff
    sw $t4 3596($v1)
    li $t4 0xb87cb6
    sw $t4 3600($v1)
    li $t4 0x860743
    sw $t4 3604($v1)
    li $t4 0x9a789e
    sw $t4 3608($v1)
    li $t4 0xa98ca1
    sw $t4 3612($v1)
    li $t4 0xaf4c7e
    sw $t4 3616($v1)
    li $t4 0x9e65ae
    sw $t4 3620($v1)
    li $t4 0x010001
    sw $t4 4096($v1)
    li $t4 0x09080c
    sw $t4 4104($v1)
    li $t4 0x817c96
    sw $t4 4108($v1)
    li $t4 0xbe6e8e
    sw $t4 4112($v1)
    li $t4 0x555caa
    sw $t4 4116($v1)
    li $t4 0x6f70b8
    sw $t4 4120($v1)
    li $t4 0x833969
    sw $t4 4124($v1)
    li $t4 0x6a63b5
    sw $t4 4128($v1)
    li $t4 0x3d286a
    sw $t4 4132($v1)
    li $t4 0x020000
    sw $t4 4612($v1)
    li $t4 0x160000
    sw $t4 4620($v1)
    li $t4 0x9a1539
    sw $t4 4624($v1)
    li $t4 0x4d2d7b
    sw $t4 4628($v1)
    li $t4 0x5b3f91
    sw $t4 4632($v1)
    li $t4 0x8c3b71
    sw $t4 4636($v1)
    li $t4 0x4f004c
    sw $t4 4640($v1)
    li $t4 0x4d224c
    sw $t4 4644($v1)
    li $t4 0x000102
    sw $t4 5128($v1)
    li $t4 0x0e0407
    sw $t4 5132($v1)
    li $t4 0x1c0b5b
    sw $t4 5136($v1)
    li $t4 0x0036b1
    sw $t4 5140($v1)
    li $t4 0x6282d6
    sw $t4 5144($v1)
    li $t4 0xf1ecff
    sw $t4 5148($v1)
    li $t4 0x987eaa
    sw $t4 5152($v1)
    li $t4 0x190000
    sw $t4 5156($v1)
    li $t4 0x080e50
    sw $t4 5648($v1)
    li $t4 0x074bbc
    sw $t4 5652($v1)
    li $t4 0x1f76df
    sw $t4 5656($v1)
    li $t4 0x749de4
    sw $t4 5660($v1)
    li $t4 0x3d4b7e
    sw $t4 5664($v1)
    jr $ra
draw_doll_01_11: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 24, 28, 36, 512, 516, 520, 524, 528, 532, 544, 1024, 1028)
    draw16($0, 1060, 1536, 1540, 1548, 2048, 2052, 2560, 2564, 2568, 2572, 3588, 4100, 4612, 4644, 5120, 5124)
    draw4($0, 5128, 5132, 5632, 5636)
    sw $0 5648($v1)
    sw $0 5652($v1)
    sw $0 5668($v1)
    li $t4 0x010101
    sw $t4 3072($v1)
    sw $t4 3076($v1)
    sw $t4 5156($v1)
    li $t4 0x020101
    sw $t4 16($v1)
    sw $t4 32($v1)
    li $t4 0x010100
    sw $t4 548($v1)
    sw $t4 1036($v1)
    li $t4 0x000100
    sw $t4 20($v1)
    li $t4 0x150c07
    sw $t4 536($v1)
    li $t4 0x0a0403
    sw $t4 540($v1)
    li $t4 0x020000
    sw $t4 1032($v1)
    li $t4 0x21090c
    sw $t4 1040($v1)
    li $t4 0xb4543d
    sw $t4 1044($v1)
    li $t4 0xcd4042
    sw $t4 1048($v1)
    li $t4 0xc74f42
    sw $t4 1052($v1)
    li $t4 0x50221d
    sw $t4 1056($v1)
    li $t4 0x030301
    sw $t4 1544($v1)
    li $t4 0xa06038
    sw $t4 1552($v1)
    li $t4 0xf7af51
    sw $t4 1556($v1)
    li $t4 0xdb7c41
    sw $t4 1560($v1)
    li $t4 0xd57545
    sw $t4 1564($v1)
    li $t4 0xd98d47
    sw $t4 1568($v1)
    li $t4 0x150809
    sw $t4 1572($v1)
    li $t4 0x020402
    sw $t4 2056($v1)
    li $t4 0x030303
    sw $t4 2060($v1)
    li $t4 0xa85539
    sw $t4 2064($v1)
    li $t4 0xd07250
    sw $t4 2068($v1)
    li $t4 0x854f56
    sw $t4 2072($v1)
    li $t4 0xb2695d
    sw $t4 2076($v1)
    li $t4 0xa02c41
    sw $t4 2080($v1)
    li $t4 0x27080c
    sw $t4 2084($v1)
    li $t4 0x841436
    sw $t4 2576($v1)
    li $t4 0xbd404e
    sw $t4 2580($v1)
    li $t4 0xa19aa5
    sw $t4 2584($v1)
    li $t4 0xcd9d8f
    sw $t4 2588($v1)
    li $t4 0x7c043c
    sw $t4 2592($v1)
    li $t4 0x0e0409
    sw $t4 2596($v1)
    li $t4 0x0f0e14
    sw $t4 3080($v1)
    li $t4 0x757187
    sw $t4 3084($v1)
    li $t4 0x84286e
    sw $t4 3088($v1)
    li $t4 0x8764a8
    sw $t4 3092($v1)
    li $t4 0x9075a7
    sw $t4 3096($v1)
    li $t4 0x9c78ac
    sw $t4 3100($v1)
    li $t4 0x9d3e82
    sw $t4 3104($v1)
    li $t4 0x59406d
    sw $t4 3108($v1)
    li $t4 0x020303
    sw $t4 3584($v1)
    li $t4 0x8682a4
    sw $t4 3592($v1)
    li $t4 0xe8c7f4
    sw $t4 3596($v1)
    li $t4 0x9d4e73
    sw $t4 3600($v1)
    li $t4 0x4e6ac1
    sw $t4 3604($v1)
    li $t4 0xa05186
    sw $t4 3608($v1)
    li $t4 0x6f205a
    sw $t4 3612($v1)
    li $t4 0x37298e
    sw $t4 3616($v1)
    li $t4 0x3e2a57
    sw $t4 3620($v1)
    li $t4 0x030304
    sw $t4 4096($v1)
    li $t4 0x696483
    sw $t4 4104($v1)
    li $t4 0xd5bae1
    sw $t4 4108($v1)
    li $t4 0x741c41
    sw $t4 4112($v1)
    li $t4 0x302f90
    sw $t4 4116($v1)
    li $t4 0x7e5da6
    sw $t4 4120($v1)
    li $t4 0xaa74af
    sw $t4 4124($v1)
    li $t4 0x7d2357
    sw $t4 4128($v1)
    li $t4 0x260f13
    sw $t4 4132($v1)
    li $t4 0x020202
    sw $t4 4608($v1)
    li $t4 0x282632
    sw $t4 4616($v1)
    li $t4 0x332e38
    sw $t4 4620($v1)
    li $t4 0x060042
    sw $t4 4624($v1)
    li $t4 0x0040c1
    sw $t4 4628($v1)
    li $t4 0x4e78d6
    sw $t4 4632($v1)
    li $t4 0xfcfaff
    sw $t4 4636($v1)
    li $t4 0x717ba1
    sw $t4 4640($v1)
    li $t4 0x05051e
    sw $t4 5136($v1)
    li $t4 0x0a2980
    sw $t4 5140($v1)
    li $t4 0x0f5ab7
    sw $t4 5144($v1)
    li $t4 0x5074d4
    sw $t4 5148($v1)
    li $t4 0x0a2959
    sw $t4 5152($v1)
    li $t4 0x020102
    sw $t4 5640($v1)
    li $t4 0x020203
    sw $t4 5644($v1)
    li $t4 0x100509
    sw $t4 5656($v1)
    li $t4 0x38223f
    sw $t4 5660($v1)
    li $t4 0x090000
    sw $t4 5664($v1)
    jr $ra
draw_doll_01_12: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 512, 516, 520, 528, 1024, 1028)
    draw16($0, 1036, 1536, 1540, 2048, 2052, 2060, 2084, 2564, 4096, 4608, 4612, 4616, 4620, 5120, 5124, 5632)
    draw4($0, 5636, 5640, 5644, 5648)
    sw $0 5652($v1)
    sw $0 5668($v1)
    li $t4 0x010100
    sw $t4 524($v1)
    sw $t4 3584($v1)
    li $t4 0x010101
    sw $t4 3072($v1)
    sw $t4 5156($v1)
    li $t4 0x54201d
    sw $t4 532($v1)
    li $t4 0x7f2929
    sw $t4 536($v1)
    li $t4 0x6f2624
    sw $t4 540($v1)
    li $t4 0x0e0006
    sw $t4 544($v1)
    li $t4 0x000100
    sw $t4 548($v1)
    li $t4 0x030201
    sw $t4 1032($v1)
    li $t4 0x682f24
    sw $t4 1040($v1)
    li $t4 0xf78f52
    sw $t4 1044($v1)
    li $t4 0xe8614b
    sw $t4 1048($v1)
    li $t4 0xea764e
    sw $t4 1052($v1)
    li $t4 0xb36e3d
    sw $t4 1056($v1)
    li $t4 0x090104
    sw $t4 1060($v1)
    li $t4 0x020401
    sw $t4 1544($v1)
    li $t4 0x020102
    sw $t4 1548($v1)
    li $t4 0xb25f3c
    sw $t4 1552($v1)
    li $t4 0xdd954d
    sw $t4 1556($v1)
    li $t4 0xa95b38
    sw $t4 1560($v1)
    li $t4 0xbc6f43
    sw $t4 1564($v1)
    li $t4 0xca7e46
    sw $t4 1568($v1)
    li $t4 0x18030a
    sw $t4 1572($v1)
    li $t4 0x030200
    sw $t4 2056($v1)
    li $t4 0x6f2924
    sw $t4 2064($v1)
    li $t4 0xce5a51
    sw $t4 2068($v1)
    li $t4 0x857891
    sw $t4 2072($v1)
    li $t4 0xc49483
    sw $t4 2076($v1)
    li $t4 0x751534
    sw $t4 2080($v1)
    li $t4 0x000001
    sw $t4 2560($v1)
    li $t4 0x030003
    sw $t4 2568($v1)
    li $t4 0x212029
    sw $t4 2572($v1)
    li $t4 0x5d0c28
    sw $t4 2576($v1)
    li $t4 0xb04d7a
    sw $t4 2580($v1)
    li $t4 0x97859a
    sw $t4 2584($v1)
    li $t4 0xb17b96
    sw $t4 2588($v1)
    li $t4 0x8d1953
    sw $t4 2592($v1)
    li $t4 0x2b2236
    sw $t4 2596($v1)
    li $t4 0x09070c
    sw $t4 3076($v1)
    li $t4 0xa59ec0
    sw $t4 3080($v1)
    li $t4 0xdccdf5
    sw $t4 3084($v1)
    li $t4 0x844284
    sw $t4 3088($v1)
    li $t4 0x6787da
    sw $t4 3092($v1)
    li $t4 0x8f5289
    sw $t4 3096($v1)
    li $t4 0x633d83
    sw $t4 3100($v1)
    li $t4 0x7b3e87
    sw $t4 3104($v1)
    li $t4 0x6b3d68
    sw $t4 3108($v1)
    li $t4 0x0e0b12
    sw $t4 3588($v1)
    li $t4 0xd4c7f8
    sw $t4 3592($v1)
    li $t4 0xd9cdf6
    sw $t4 3596($v1)
    li $t4 0xae606e
    sw $t4 3600($v1)
    li $t4 0x483e99
    sw $t4 3604($v1)
    li $t4 0x85387d
    sw $t4 3608($v1)
    li $t4 0x6d0a4d
    sw $t4 3612($v1)
    li $t4 0x8e2d4d
    sw $t4 3616($v1)
    li $t4 0x290b18
    sw $t4 3620($v1)
    li $t4 0x08070c
    sw $t4 4100($v1)
    li $t4 0x7f7697
    sw $t4 4104($v1)
    li $t4 0x3c3943
    sw $t4 4108($v1)
    li $t4 0x28002d
    sw $t4 4112($v1)
    li $t4 0x0a36ac
    sw $t4 4116($v1)
    li $t4 0x9fa8e3
    sw $t4 4120($v1)
    li $t4 0xd3c7f3
    sw $t4 4124($v1)
    li $t4 0x4c063b
    sw $t4 4128($v1)
    li $t4 0x030000
    sw $t4 4132($v1)
    li $t4 0x060b42
    sw $t4 4624($v1)
    li $t4 0x0064e8
    sw $t4 4628($v1)
    li $t4 0x669cf0
    sw $t4 4632($v1)
    li $t4 0xb7aee8
    sw $t4 4636($v1)
    li $t4 0x000f31
    sw $t4 4640($v1)
    li $t4 0x000101
    sw $t4 4644($v1)
    li $t4 0x030304
    sw $t4 5128($v1)
    li $t4 0x020203
    sw $t4 5132($v1)
    li $t4 0x030108
    sw $t4 5136($v1)
    li $t4 0x030b2b
    sw $t4 5140($v1)
    li $t4 0x212a5f
    sw $t4 5144($v1)
    li $t4 0x372866
    sw $t4 5148($v1)
    li $t4 0x020205
    sw $t4 5152($v1)
    li $t4 0x0d0300
    sw $t4 5656($v1)
    li $t4 0x160b02
    sw $t4 5660($v1)
    li $t4 0x020100
    sw $t4 5664($v1)
    jr $ra
draw_doll_01_13: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 20, 28, 32, 512, 516, 1024, 1028, 1036, 1536, 1540, 2048)
    draw16($0, 2052, 2056, 3584, 4096, 4100, 4104, 4108, 4132, 4608, 4612, 5120, 5124, 5128, 5132, 5632, 5636)
    draw4($0, 5640, 5644, 5648, 5668)
    li $t4 0x010000
    sw $t4 36($v1)
    sw $t4 520($v1)
    sw $t4 5136($v1)
    li $t4 0x010100
    sw $t4 524($v1)
    sw $t4 3072($v1)
    li $t4 0x000100
    sw $t4 548($v1)
    sw $t4 5652($v1)
    li $t4 0x010501
    sw $t4 24($v1)
    li $t4 0x110306
    sw $t4 528($v1)
    li $t4 0x8f3d31
    sw $t4 532($v1)
    li $t4 0xb23439
    sw $t4 536($v1)
    li $t4 0xa53936
    sw $t4 540($v1)
    li $t4 0x310c13
    sw $t4 544($v1)
    li $t4 0x030301
    sw $t4 1032($v1)
    li $t4 0x89482f
    sw $t4 1040($v1)
    li $t4 0xfda452
    sw $t4 1044($v1)
    li $t4 0xe57746
    sw $t4 1048($v1)
    li $t4 0xf1984d
    sw $t4 1052($v1)
    li $t4 0xda9e48
    sw $t4 1056($v1)
    li $t4 0x0d0206
    sw $t4 1060($v1)
    li $t4 0x030500
    sw $t4 1544($v1)
    li $t4 0x040303
    sw $t4 1548($v1)
    li $t4 0xae623c
    sw $t4 1552($v1)
    li $t4 0xda8c4e
    sw $t4 1556($v1)
    li $t4 0x925645
    sw $t4 1560($v1)
    li $t4 0xbf8250
    sw $t4 1564($v1)
    li $t4 0xc87c4a
    sw $t4 1568($v1)
    li $t4 0x270410
    sw $t4 1572($v1)
    li $t4 0x050000
    sw $t4 2060($v1)
    li $t4 0xb6383a
    sw $t4 2064($v1)
    li $t4 0xbe494c
    sw $t4 2068($v1)
    li $t4 0x9890a4
    sw $t4 2072($v1)
    li $t4 0xc1978a
    sw $t4 2076($v1)
    li $t4 0x900540
    sw $t4 2080($v1)
    li $t4 0x430014
    sw $t4 2084($v1)
    li $t4 0x010101
    sw $t4 2560($v1)
    li $t4 0x060409
    sw $t4 2564($v1)
    li $t4 0x9c98b5
    sw $t4 2568($v1)
    li $t4 0x9380a0
    sw $t4 2572($v1)
    li $t4 0x7f043a
    sw $t4 2576($v1)
    li $t4 0x9d689e
    sw $t4 2580($v1)
    li $t4 0x8c6f95
    sw $t4 2584($v1)
    li $t4 0x926b9a
    sw $t4 2588($v1)
    li $t4 0x9b1d61
    sw $t4 2592($v1)
    li $t4 0x5b264d
    sw $t4 2596($v1)
    li $t4 0x0d0a13
    sw $t4 3076($v1)
    li $t4 0xd5ccf7
    sw $t4 3080($v1)
    li $t4 0xfdf1ff
    sw $t4 3084($v1)
    li $t4 0x975c8e
    sw $t4 3088($v1)
    li $t4 0x5a80d4
    sw $t4 3092($v1)
    li $t4 0x904078
    sw $t4 3096($v1)
    li $t4 0x5b1e63
    sw $t4 3100($v1)
    li $t4 0x743e7b
    sw $t4 3104($v1)
    li $t4 0x5b2e51
    sw $t4 3108($v1)
    li $t4 0x0a080e
    sw $t4 3588($v1)
    li $t4 0x998fb5
    sw $t4 3592($v1)
    li $t4 0xa49eb8
    sw $t4 3596($v1)
    li $t4 0x913e53
    sw $t4 3600($v1)
    li $t4 0x452e8b
    sw $t4 3604($v1)
    li $t4 0x90579f
    sw $t4 3608($v1)
    li $t4 0x832d6e
    sw $t4 3612($v1)
    li $t4 0x921c3b
    sw $t4 3616($v1)
    li $t4 0x19030c
    sw $t4 3620($v1)
    li $t4 0x090753
    sw $t4 4112($v1)
    li $t4 0x0d53ce
    sw $t4 4116($v1)
    li $t4 0xbac1f2
    sw $t4 4120($v1)
    li $t4 0xe3e3ff
    sw $t4 4124($v1)
    li $t4 0x2c1259
    sw $t4 4128($v1)
    li $t4 0x010203
    sw $t4 4616($v1)
    li $t4 0x020302
    sw $t4 4620($v1)
    li $t4 0x0a1961
    sw $t4 4624($v1)
    li $t4 0x0367d8
    sw $t4 4628($v1)
    li $t4 0x2c7bdc
    sw $t4 4632($v1)
    li $t4 0x506ecd
    sw $t4 4636($v1)
    li $t4 0x00123c
    sw $t4 4640($v1)
    li $t4 0x000001
    sw $t4 4644($v1)
    li $t4 0x020003
    sw $t4 5140($v1)
    li $t4 0x1f1932
    sw $t4 5144($v1)
    li $t4 0x2e2044
    sw $t4 5148($v1)
    li $t4 0x030000
    sw $t4 5152($v1)
    li $t4 0x010001
    sw $t4 5156($v1)
    li $t4 0x040000
    sw $t4 5656($v1)
    li $t4 0x080200
    sw $t4 5660($v1)
    li $t4 0x010102
    sw $t4 5664($v1)
    jr $ra
draw_doll_01_14: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 24, 28, 36, 512, 516, 520, 528, 532, 544, 1024, 1028, 1060)
    draw4($0, 1536, 1544, 2048, 3584)
    draw4($0, 3592, 4096, 4608, 5120)
    draw4($0, 5124, 5632, 5636, 5640)
    sw $0 5644($v1)
    sw $0 5648($v1)
    sw $0 5668($v1)
    li $t4 0x000100
    draw4($t4, 20, 3588, 4616, 5156)
    li $t4 0x010101
    sw $t4 1540($v1)
    sw $t4 3072($v1)
    sw $t4 4100($v1)
    li $t4 0x020101
    sw $t4 16($v1)
    sw $t4 32($v1)
    li $t4 0x010100
    sw $t4 548($v1)
    sw $t4 2560($v1)
    li $t4 0x000001
    sw $t4 4612($v1)
    sw $t4 5128($v1)
    li $t4 0x010000
    sw $t4 524($v1)
    li $t4 0x130907
    sw $t4 536($v1)
    li $t4 0x080003
    sw $t4 540($v1)
    li $t4 0x040302
    sw $t4 1032($v1)
    li $t4 0x000202
    sw $t4 1036($v1)
    li $t4 0x21070c
    sw $t4 1040($v1)
    li $t4 0xb45c3e
    sw $t4 1044($v1)
    li $t4 0xd24d43
    sw $t4 1048($v1)
    li $t4 0xcd6943
    sw $t4 1052($v1)
    li $t4 0x4f201d
    sw $t4 1056($v1)
    li $t4 0x070000
    sw $t4 1548($v1)
    li $t4 0xcf7f45
    sw $t4 1552($v1)
    li $t4 0xf4b150
    sw $t4 1556($v1)
    li $t4 0xd36144
    sw $t4 1560($v1)
    li $t4 0xd47e48
    sw $t4 1564($v1)
    li $t4 0xd99349
    sw $t4 1568($v1)
    li $t4 0x16080b
    sw $t4 1572($v1)
    li $t4 0x0c080e
    sw $t4 2052($v1)
    li $t4 0x9390b5
    sw $t4 2056($v1)
    li $t4 0x8c4b64
    sw $t4 2060($v1)
    li $t4 0xde7640
    sw $t4 2064($v1)
    li $t4 0xbb5b4b
    sw $t4 2068($v1)
    li $t4 0x8e5b64
    sw $t4 2072($v1)
    li $t4 0xb86a65
    sw $t4 2076($v1)
    li $t4 0x9d283f
    sw $t4 2080($v1)
    li $t4 0x200303
    sw $t4 2084($v1)
    li $t4 0x0d0a12
    sw $t4 2564($v1)
    li $t4 0xd6cefa
    sw $t4 2568($v1)
    li $t4 0xd3bdf0
    sw $t4 2572($v1)
    li $t4 0x920039
    sw $t4 2576($v1)
    li $t4 0xb7444e
    sw $t4 2580($v1)
    li $t4 0xa7abab
    sw $t4 2584($v1)
    li $t4 0xc7a08f
    sw $t4 2588($v1)
    li $t4 0x911350
    sw $t4 2592($v1)
    li $t4 0x634470
    sw $t4 2596($v1)
    li $t4 0x060409
    sw $t4 3076($v1)
    li $t4 0x9c96b4
    sw $t4 3080($v1)
    li $t4 0xd3bae6
    sw $t4 3084($v1)
    li $t4 0x78276f
    sw $t4 3088($v1)
    li $t4 0x8a66ab
    sw $t4 3092($v1)
    li $t4 0x96749e
    sw $t4 3096($v1)
    li $t4 0x9c749d
    sw $t4 3100($v1)
    li $t4 0x9b5398
    sw $t4 3104($v1)
    li $t4 0x533862
    sw $t4 3108($v1)
    li $t4 0x8f365c
    sw $t4 3596($v1)
    li $t4 0x5f6cba
    sw $t4 3600($v1)
    li $t4 0x2c288b
    sw $t4 3604($v1)
    li $t4 0x78357b
    sw $t4 3608($v1)
    li $t4 0x6a0944
    sw $t4 3612($v1)
    li $t4 0x4f2e7d
    sw $t4 3616($v1)
    li $t4 0x3b2336
    sw $t4 3620($v1)
    li $t4 0x010201
    sw $t4 4104($v1)
    li $t4 0x300e0c
    sw $t4 4108($v1)
    li $t4 0x6a0f4d
    sw $t4 4112($v1)
    li $t4 0x56479f
    sw $t4 4116($v1)
    li $t4 0xbda3d7
    sw $t4 4120($v1)
    li $t4 0x9968af
    sw $t4 4124($v1)
    li $t4 0x62062d
    sw $t4 4128($v1)
    li $t4 0x2e100e
    sw $t4 4132($v1)
    li $t4 0x04000b
    sw $t4 4620($v1)
    li $t4 0x0a1e91
    sw $t4 4624($v1)
    li $t4 0x3d67cc
    sw $t4 4628($v1)
    li $t4 0x6aadff
    sw $t4 4632($v1)
    li $t4 0x55abff
    sw $t4 4636($v1)
    li $t4 0x08297f
    sw $t4 4640($v1)
    li $t4 0x020000
    sw $t4 4644($v1)
    li $t4 0x000106
    sw $t4 5132($v1)
    li $t4 0x0b1258
    sw $t4 5136($v1)
    li $t4 0x013a9b
    sw $t4 5140($v1)
    li $t4 0x0061c1
    sw $t4 5144($v1)
    li $t4 0x0055b3
    sw $t4 5148($v1)
    li $t4 0x061749
    sw $t4 5152($v1)
    li $t4 0x040000
    sw $t4 5652($v1)
    li $t4 0x150200
    sw $t4 5656($v1)
    li $t4 0x140000
    sw $t4 5660($v1)
    li $t4 0x030000
    sw $t4 5664($v1)
    jr $ra
draw_doll_01_15: # start at v1, use t4
    draw16($0, 0, 4, 12, 32, 512, 548, 1024, 1536, 1544, 1572, 2048, 2052, 2560, 3072, 3584, 4096)
    draw16($0, 4100, 4104, 4608, 5120, 5124, 5128, 5132, 5136, 5152, 5156, 5632, 5636, 5640, 5644, 5660, 5664)
    sw $0 5668($v1)
    li $t4 0x000001
    sw $t4 1060($v1)
    sw $t4 5648($v1)
    sw $t4 5656($v1)
    li $t4 0x010001
    sw $t4 36($v1)
    sw $t4 4620($v1)
    li $t4 0x010000
    sw $t4 516($v1)
    sw $t4 4640($v1)
    li $t4 0x010100
    sw $t4 520($v1)
    sw $t4 1540($v1)
    li $t4 0x020100
    sw $t4 8($v1)
    li $t4 0x3e1916
    sw $t4 16($v1)
    li $t4 0x9a3333
    sw $t4 20($v1)
    li $t4 0xa63934
    sw $t4 24($v1)
    li $t4 0x53151e
    sw $t4 28($v1)
    li $t4 0x20050c
    sw $t4 524($v1)
    li $t4 0xdb854a
    sw $t4 528($v1)
    li $t4 0xec754c
    sw $t4 532($v1)
    li $t4 0xdb6448
    sw $t4 536($v1)
    li $t4 0xeb934e
    sw $t4 540($v1)
    li $t4 0x512b1d
    sw $t4 544($v1)
    li $t4 0x030101
    sw $t4 1028($v1)
    li $t4 0x020202
    sw $t4 1032($v1)
    li $t4 0x4a151b
    sw $t4 1036($v1)
    li $t4 0xf09d52
    sw $t4 1040($v1)
    li $t4 0xab6241
    sw $t4 1044($v1)
    li $t4 0xa65e3f
    sw $t4 1048($v1)
    li $t4 0xd5844f
    sw $t4 1052($v1)
    li $t4 0x653224
    sw $t4 1056($v1)
    li $t4 0x120001
    sw $t4 1548($v1)
    li $t4 0xc6483f
    sw $t4 1552($v1)
    li $t4 0x9b6378
    sw $t4 1556($v1)
    li $t4 0xaea79e
    sw $t4 1560($v1)
    li $t4 0xad495c
    sw $t4 1564($v1)
    li $t4 0x220004
    sw $t4 1568($v1)
    li $t4 0x2b2933
    sw $t4 2056($v1)
    li $t4 0x3c2034
    sw $t4 2060($v1)
    li $t4 0x942357
    sw $t4 2064($v1)
    li $t4 0x9d779f
    sw $t4 2068($v1)
    li $t4 0x9c87a1
    sw $t4 2072($v1)
    li $t4 0xac457d
    sw $t4 2076($v1)
    li $t4 0x612350
    sw $t4 2080($v1)
    li $t4 0x0b1014
    sw $t4 2084($v1)
    li $t4 0x605871
    sw $t4 2564($v1)
    li $t4 0xe5e1ff
    sw $t4 2568($v1)
    li $t4 0xc688ba
    sw $t4 2572($v1)
    li $t4 0x5556a5
    sw $t4 2576($v1)
    li $t4 0x8074c5
    sw $t4 2580($v1)
    li $t4 0x7a2861
    sw $t4 2584($v1)
    li $t4 0x695098
    sw $t4 2588($v1)
    li $t4 0x83356e
    sw $t4 2592($v1)
    li $t4 0x171a25
    sw $t4 2596($v1)
    li $t4 0x756a8b
    sw $t4 3076($v1)
    li $t4 0xeee9ff
    sw $t4 3080($v1)
    li $t4 0xb47e91
    sw $t4 3084($v1)
    li $t4 0x6c346c
    sw $t4 3088($v1)
    li $t4 0x5b45a1
    sw $t4 3092($v1)
    li $t4 0x852865
    sw $t4 3096($v1)
    li $t4 0x842054
    sw $t4 3100($v1)
    li $t4 0x601b2a
    sw $t4 3104($v1)
    li $t4 0x000101
    sw $t4 3108($v1)
    li $t4 0x413a4f
    sw $t4 3588($v1)
    li $t4 0x545463
    sw $t4 3592($v1)
    li $t4 0x15000b
    sw $t4 3596($v1)
    li $t4 0x0f1a86
    sw $t4 3600($v1)
    li $t4 0x3e72d3
    sw $t4 3604($v1)
    li $t4 0xf2f0ff
    sw $t4 3608($v1)
    li $t4 0x815b9d
    sw $t4 3612($v1)
    li $t4 0x160001
    sw $t4 3616($v1)
    li $t4 0x020301
    sw $t4 3620($v1)
    li $t4 0x000107
    sw $t4 4108($v1)
    li $t4 0x0638a0
    sw $t4 4112($v1)
    li $t4 0x117bee
    sw $t4 4116($v1)
    li $t4 0xaea9e7
    sw $t4 4120($v1)
    li $t4 0x3d4a86
    sw $t4 4124($v1)
    li $t4 0x000100
    sw $t4 4128($v1)
    li $t4 0x030203
    sw $t4 4132($v1)
    li $t4 0x020203
    sw $t4 4612($v1)
    li $t4 0x030304
    sw $t4 4616($v1)
    li $t4 0x03000c
    sw $t4 4624($v1)
    li $t4 0x060e27
    sw $t4 4628($v1)
    li $t4 0x3c2f6d
    sw $t4 4632($v1)
    li $t4 0x10091a
    sw $t4 4636($v1)
    li $t4 0x010101
    sw $t4 4644($v1)
    li $t4 0x020000
    sw $t4 5140($v1)
    li $t4 0x0f0600
    sw $t4 5144($v1)
    li $t4 0x080400
    sw $t4 5148($v1)
    li $t4 0x000002
    sw $t4 5652($v1)
    jr $ra
draw_doll_01_16: # start at v1, use t4
    draw16($0, 0, 32, 512, 548, 1024, 1032, 1060, 2052, 2080, 2564, 3072, 3076, 3584, 3616, 4096, 4104)
    draw16($0, 4608, 4612, 4616, 4640, 5120, 5124, 5128, 5132, 5140, 5144, 5152, 5156, 5632, 5636, 5640, 5644)
    draw4($0, 5648, 5660, 5664, 5668)
    li $t4 0x010001
    draw4($t4, 520, 1536, 4644, 5652)
    li $t4 0x010000
    sw $t4 4($v1)
    sw $t4 3592($v1)
    sw $t4 4624($v1)
    li $t4 0x000002
    sw $t4 3588($v1)
    sw $t4 4100($v1)
    sw $t4 4132($v1)
    li $t4 0x020101
    sw $t4 4128($v1)
    sw $t4 5148($v1)
    li $t4 0x010100
    sw $t4 8($v1)
    li $t4 0x0e0005
    sw $t4 12($v1)
    li $t4 0xae7a3b
    sw $t4 16($v1)
    li $t4 0xe8974c
    sw $t4 20($v1)
    li $t4 0xbf2841
    sw $t4 24($v1)
    li $t4 0x642624
    sw $t4 28($v1)
    li $t4 0x010101
    sw $t4 36($v1)
    li $t4 0x030201
    sw $t4 516($v1)
    li $t4 0x692b25
    sw $t4 524($v1)
    li $t4 0xffff5a
    sw $t4 528($v1)
    li $t4 0xf7ea51
    sw $t4 532($v1)
    li $t4 0xdf8949
    sw $t4 536($v1)
    li $t4 0xe99f4e
    sw $t4 540($v1)
    li $t4 0x2d1710
    sw $t4 544($v1)
    li $t4 0x040301
    sw $t4 1028($v1)
    li $t4 0x935e31
    sw $t4 1036($v1)
    li $t4 0xfee158
    sw $t4 1040($v1)
    li $t4 0xe0b44e
    sw $t4 1044($v1)
    li $t4 0xb75849
    sw $t4 1048($v1)
    li $t4 0xc33f4a
    sw $t4 1052($v1)
    li $t4 0x3c1416
    sw $t4 1056($v1)
    li $t4 0x000200
    sw $t4 1540($v1)
    li $t4 0x0e0915
    sw $t4 1544($v1)
    li $t4 0xc4774a
    sw $t4 1548($v1)
    li $t4 0xe17748
    sw $t4 1552($v1)
    li $t4 0xd29343
    sw $t4 1556($v1)
    li $t4 0xd67969
    sw $t4 1560($v1)
    li $t4 0x8a2b3e
    sw $t4 1564($v1)
    li $t4 0x070002
    sw $t4 1568($v1)
    li $t4 0x020201
    sw $t4 1572($v1)
    li $t4 0x030304
    sw $t4 2048($v1)
    li $t4 0x514368
    sw $t4 2056($v1)
    li $t4 0xcd5968
    sw $t4 2060($v1)
    li $t4 0xcc6335
    sw $t4 2064($v1)
    li $t4 0xc28d77
    sw $t4 2068($v1)
    li $t4 0xb088d0
    sw $t4 2072($v1)
    li $t4 0x6e6083
    sw $t4 2076($v1)
    li $t4 0x030203
    sw $t4 2084($v1)
    li $t4 0x020001
    sw $t4 2560($v1)
    li $t4 0x230c18
    sw $t4 2568($v1)
    li $t4 0xa22146
    sw $t4 2572($v1)
    li $t4 0xb53533
    sw $t4 2576($v1)
    li $t4 0xb78ebb
    sw $t4 2580($v1)
    li $t4 0xa87cbc
    sw $t4 2584($v1)
    li $t4 0x4f3b92
    sw $t4 2588($v1)
    li $t4 0x2f2441
    sw $t4 2592($v1)
    li $t4 0x030100
    sw $t4 2596($v1)
    li $t4 0x0b0002
    sw $t4 3080($v1)
    li $t4 0x76002e
    sw $t4 3084($v1)
    li $t4 0xa81736
    sw $t4 3088($v1)
    li $t4 0x644c93
    sw $t4 3092($v1)
    li $t4 0x523da2
    sw $t4 3096($v1)
    li $t4 0x5a0b35
    sw $t4 3100($v1)
    li $t4 0x2f191a
    sw $t4 3104($v1)
    li $t4 0x030102
    sw $t4 3108($v1)
    li $t4 0x190c47
    sw $t4 3596($v1)
    li $t4 0x28319f
    sw $t4 3600($v1)
    li $t4 0x004cbe
    sw $t4 3604($v1)
    li $t4 0x4382e4
    sw $t4 3608($v1)
    li $t4 0x48446e
    sw $t4 3612($v1)
    li $t4 0x020304
    sw $t4 3620($v1)
    li $t4 0x040940
    sw $t4 4108($v1)
    li $t4 0x031779
    sw $t4 4112($v1)
    li $t4 0x3849a5
    sw $t4 4116($v1)
    li $t4 0x3e41ae
    sw $t4 4120($v1)
    li $t4 0x031050
    sw $t4 4124($v1)
    li $t4 0x020000
    sw $t4 4620($v1)
    li $t4 0x23121c
    sw $t4 4628($v1)
    li $t4 0x462a45
    sw $t4 4632($v1)
    li $t4 0x060000
    sw $t4 4636($v1)
    li $t4 0x000100
    sw $t4 5136($v1)
    li $t4 0x000102
    sw $t4 5656($v1)
    jr $ra
draw_doll_01_17: # start at v1, use t4
    draw16($0, 0, 8, 516, 1028, 1536, 2048, 2056, 2084, 3584, 3592, 3616, 4096, 4608, 4612, 4620, 4636)
    draw16($0, 4644, 5120, 5124, 5128, 5140, 5144, 5152, 5156, 5632, 5636, 5640, 5644, 5648, 5660, 5664, 5668)
    li $t4 0x010101
    draw4($t4, 4, 512, 1540, 2564)
    sw $t4 4128($v1)
    sw $t4 4640($v1)
    li $t4 0x000001
    draw4($t4, 544, 4132, 5132, 5656)
    li $t4 0x010100
    sw $t4 32($v1)
    sw $t4 2596($v1)
    sw $t4 3104($v1)
    li $t4 0x010000
    sw $t4 36($v1)
    sw $t4 3072($v1)
    sw $t4 4616($v1)
    li $t4 0x000002
    sw $t4 2560($v1)
    sw $t4 4100($v1)
    sw $t4 5148($v1)
    li $t4 0x020101
    sw $t4 1024($v1)
    sw $t4 4104($v1)
    li $t4 0x010001
    sw $t4 3076($v1)
    sw $t4 3108($v1)
    li $t4 0x000102
    sw $t4 3620($v1)
    sw $t4 5652($v1)
    li $t4 0x55221f
    sw $t4 12($v1)
    li $t4 0xba243f
    sw $t4 16($v1)
    li $t4 0xe4894b
    sw $t4 20($v1)
    li $t4 0xbd8b40
    sw $t4 24($v1)
    li $t4 0x170209
    sw $t4 28($v1)
    li $t4 0x1b0b0a
    sw $t4 520($v1)
    li $t4 0xdd974a
    sw $t4 524($v1)
    li $t4 0xe28c4a
    sw $t4 528($v1)
    li $t4 0xf3dd52
    sw $t4 532($v1)
    li $t4 0xffff5c
    sw $t4 536($v1)
    li $t4 0x84432e
    sw $t4 540($v1)
    li $t4 0x040301
    sw $t4 548($v1)
    li $t4 0x2a0e0f
    sw $t4 1032($v1)
    li $t4 0xc03f49
    sw $t4 1036($v1)
    li $t4 0xb24645
    sw $t4 1040($v1)
    li $t4 0xdb9840
    sw $t4 1044($v1)
    li $t4 0xfbf351
    sw $t4 1048($v1)
    li $t4 0xce8443
    sw $t4 1052($v1)
    li $t4 0x040000
    sw $t4 1056($v1)
    li $t4 0x010300
    sw $t4 1060($v1)
    li $t4 0x040002
    sw $t4 1544($v1)
    li $t4 0x762035
    sw $t4 1548($v1)
    li $t4 0xd36b5e
    sw $t4 1552($v1)
    li $t4 0xca9984
    sw $t4 1556($v1)
    li $t4 0xe3b767
    sw $t4 1560($v1)
    li $t4 0xce604c
    sw $t4 1564($v1)
    li $t4 0x180d1c
    sw $t4 1568($v1)
    li $t4 0x000200
    sw $t4 1572($v1)
    li $t4 0x030203
    sw $t4 2052($v1)
    li $t4 0x574c79
    sw $t4 2060($v1)
    li $t4 0xd08789
    sw $t4 2064($v1)
    li $t4 0xccc9c9
    sw $t4 2068($v1)
    li $t4 0xb56883
    sw $t4 2072($v1)
    li $t4 0xd3726b
    sw $t4 2076($v1)
    li $t4 0x2c2846
    sw $t4 2080($v1)
    li $t4 0x2f2035
    sw $t4 2568($v1)
    li $t4 0x374599
    sw $t4 2572($v1)
    li $t4 0xb55f5c
    sw $t4 2576($v1)
    li $t4 0xa14c6b
    sw $t4 2580($v1)
    li $t4 0xc2444b
    sw $t4 2584($v1)
    li $t4 0x942d3b
    sw $t4 2588($v1)
    li $t4 0x000003
    sw $t4 2592($v1)
    li $t4 0x2e1718
    sw $t4 3080($v1)
    li $t4 0x2f0316
    sw $t4 3084($v1)
    li $t4 0x43075f
    sw $t4 3088($v1)
    li $t4 0x381974
    sw $t4 3092($v1)
    li $t4 0x5a1c63
    sw $t4 3096($v1)
    li $t4 0x350027
    sw $t4 3100($v1)
    li $t4 0x000103
    sw $t4 3588($v1)
    li $t4 0x100d46
    sw $t4 3596($v1)
    li $t4 0x0674f0
    sw $t4 3600($v1)
    li $t4 0x005dcb
    sw $t4 3604($v1)
    li $t4 0x042da7
    sw $t4 3608($v1)
    li $t4 0x070f54
    sw $t4 3612($v1)
    li $t4 0x030c34
    sw $t4 4108($v1)
    li $t4 0x023b93
    sw $t4 4112($v1)
    li $t4 0x4054bc
    sw $t4 4116($v1)
    li $t4 0x292685
    sw $t4 4120($v1)
    li $t4 0x050937
    sw $t4 4124($v1)
    li $t4 0x0a0000
    sw $t4 4624($v1)
    li $t4 0x4b2945
    sw $t4 4628($v1)
    li $t4 0x1c1019
    sw $t4 4632($v1)
    li $t4 0x010302
    sw $t4 5136($v1)
    jr $ra
draw_doll_01_18: # start at v1, use t4
    draw16($0, 0, 8, 28, 36, 516, 1056, 2084, 2560, 2596, 3072, 3584, 3592, 3616, 4608, 4616, 4640)
    draw4($0, 4644, 5120, 5124, 5128)
    draw4($0, 5144, 5148, 5152, 5156)
    draw4($0, 5632, 5636, 5640, 5644)
    sw $0 5660($v1)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x000001
    draw4($t4, 3076, 4096, 5648, 5656)
    li $t4 0x010000
    sw $t4 4($v1)
    sw $t4 3108($v1)
    sw $t4 5140($v1)
    li $t4 0x020001
    sw $t4 1028($v1)
    sw $t4 1536($v1)
    sw $t4 2048($v1)
    li $t4 0x000102
    sw $t4 3620($v1)
    sw $t4 4104($v1)
    sw $t4 4132($v1)
    li $t4 0x010100
    sw $t4 32($v1)
    sw $t4 1572($v1)
    li $t4 0x010101
    sw $t4 4128($v1)
    sw $t4 4612($v1)
    li $t4 0x450d19
    sw $t4 12($v1)
    li $t4 0xa02f32
    sw $t4 16($v1)
    li $t4 0xa55737
    sw $t4 20($v1)
    li $t4 0x50291b
    sw $t4 24($v1)
    li $t4 0x030201
    sw $t4 512($v1)
    li $t4 0x432918
    sw $t4 520($v1)
    li $t4 0xde7b4b
    sw $t4 524($v1)
    li $t4 0xe66f4a
    sw $t4 528($v1)
    li $t4 0xe99d4e
    sw $t4 532($v1)
    li $t4 0xf7cd53
    sw $t4 536($v1)
    li $t4 0x2d0a12
    sw $t4 540($v1)
    li $t4 0x020302
    sw $t4 544($v1)
    li $t4 0x020101
    sw $t4 548($v1)
    li $t4 0x020201
    sw $t4 1024($v1)
    li $t4 0x883b2e
    sw $t4 1032($v1)
    li $t4 0xd7744c
    sw $t4 1036($v1)
    li $t4 0xab6f40
    sw $t4 1040($v1)
    li $t4 0xbb6f42
    sw $t4 1044($v1)
    li $t4 0xffe958
    sw $t4 1048($v1)
    li $t4 0x863b23
    sw $t4 1052($v1)
    li $t4 0x040301
    sw $t4 1060($v1)
    li $t4 0x000100
    sw $t4 1540($v1)
    li $t4 0x2f0218
    sw $t4 1544($v1)
    li $t4 0xcf5b5f
    sw $t4 1548($v1)
    li $t4 0x8b7a9b
    sw $t4 1552($v1)
    li $t4 0xc1854a
    sw $t4 1556($v1)
    li $t4 0xe19747
    sw $t4 1560($v1)
    li $t4 0xc47e9b
    sw $t4 1564($v1)
    li $t4 0x4a485e
    sw $t4 1568($v1)
    li $t4 0x000200
    sw $t4 2052($v1)
    li $t4 0x301020
    sw $t4 2056($v1)
    li $t4 0xab427a
    sw $t4 2060($v1)
    li $t4 0xb98592
    sw $t4 2064($v1)
    li $t4 0xc96947
    sw $t4 2068($v1)
    li $t4 0xbd5349
    sw $t4 2072($v1)
    li $t4 0xd4c5f1
    sw $t4 2076($v1)
    li $t4 0x8a83a9
    sw $t4 2080($v1)
    li $t4 0x000201
    sw $t4 2564($v1)
    li $t4 0x050000
    sw $t4 2568($v1)
    li $t4 0x6c4485
    sw $t4 2572($v1)
    li $t4 0x8e265a
    sw $t4 2576($v1)
    li $t4 0x7f3166
    sw $t4 2580($v1)
    li $t4 0x8e1843
    sw $t4 2584($v1)
    li $t4 0xc88db7
    sw $t4 2588($v1)
    li $t4 0xabaace
    sw $t4 2592($v1)
    li $t4 0x060002
    sw $t4 3080($v1)
    li $t4 0x500542
    sw $t4 3084($v1)
    li $t4 0xa3498d
    sw $t4 3088($v1)
    li $t4 0x603f7b
    sw $t4 3092($v1)
    li $t4 0x511863
    sw $t4 3096($v1)
    li $t4 0x7d0536
    sw $t4 3100($v1)
    li $t4 0x100f16
    sw $t4 3104($v1)
    li $t4 0x030303
    sw $t4 3588($v1)
    li $t4 0x73598a
    sw $t4 3596($v1)
    li $t4 0x7384dc
    sw $t4 3600($v1)
    li $t4 0x0638a5
    sw $t4 3604($v1)
    li $t4 0x0c30a6
    sw $t4 3608($v1)
    li $t4 0x240942
    sw $t4 3612($v1)
    li $t4 0x000101
    sw $t4 4100($v1)
    li $t4 0x132f80
    sw $t4 4108($v1)
    li $t4 0x0273ea
    sw $t4 4112($v1)
    li $t4 0x0b4cbe
    sw $t4 4116($v1)
    li $t4 0x122695
    sw $t4 4120($v1)
    li $t4 0x000a31
    sw $t4 4124($v1)
    li $t4 0x0a0910
    sw $t4 4620($v1)
    li $t4 0x4b417c
    sw $t4 4624($v1)
    li $t4 0x141131
    sw $t4 4628($v1)
    li $t4 0x020110
    sw $t4 4632($v1)
    li $t4 0x020000
    sw $t4 4636($v1)
    li $t4 0x050100
    sw $t4 5132($v1)
    li $t4 0x100400
    sw $t4 5136($v1)
    li $t4 0x000002
    sw $t4 5652($v1)
    jr $ra
draw_doll_01_19: # start at v1, use t4
    draw16($0, 0, 8, 28, 36, 1056, 3072, 4124, 4132, 4608, 4644, 5120, 5128, 5144, 5148, 5152, 5156)
    draw4($0, 5632, 5636, 5640, 5644)
    draw4($0, 5648, 5660, 5664, 5668)
    li $t4 0x010000
    draw4($t4, 32, 512, 2084, 3620)
    sw $t4 4100($v1)
    sw $t4 4636($v1)
    sw $t4 5124($v1)
    li $t4 0x010101
    sw $t4 4($v1)
    sw $t4 544($v1)
    sw $t4 4612($v1)
    li $t4 0x000102
    sw $t4 3584($v1)
    sw $t4 4096($v1)
    sw $t4 5656($v1)
    li $t4 0x000001
    sw $t4 3108($v1)
    sw $t4 4640($v1)
    li $t4 0x1c060a
    sw $t4 12($v1)
    li $t4 0x5e1f20
    sw $t4 16($v1)
    li $t4 0x64251f
    sw $t4 20($v1)
    li $t4 0x150008
    sw $t4 24($v1)
    li $t4 0x000100
    sw $t4 516($v1)
    li $t4 0x160209
    sw $t4 520($v1)
    li $t4 0xcb7a45
    sw $t4 524($v1)
    li $t4 0xe9624d
    sw $t4 528($v1)
    li $t4 0xe25d4b
    sw $t4 532($v1)
    li $t4 0xc87144
    sw $t4 536($v1)
    li $t4 0x21110d
    sw $t4 540($v1)
    li $t4 0x020101
    sw $t4 548($v1)
    li $t4 0x040504
    sw $t4 1024($v1)
    li $t4 0x050005
    sw $t4 1028($v1)
    li $t4 0x9a4b33
    sw $t4 1032($v1)
    li $t4 0xf4bd51
    sw $t4 1036($v1)
    li $t4 0xc3793a
    sw $t4 1040($v1)
    li $t4 0xbb6e3b
    sw $t4 1044($v1)
    li $t4 0xe9a74c
    sw $t4 1048($v1)
    li $t4 0x603b1e
    sw $t4 1052($v1)
    li $t4 0x040301
    sw $t4 1060($v1)
    li $t4 0x1a1721
    sw $t4 1536($v1)
    li $t4 0xb3a8d0
    sw $t4 1540($v1)
    li $t4 0xbf6a71
    sw $t4 1544($v1)
    li $t4 0xbd4843
    sw $t4 1548($v1)
    li $t4 0x84697e
    sw $t4 1552($v1)
    li $t4 0xc08f8a
    sw $t4 1556($v1)
    li $t4 0x9d5f58
    sw $t4 1560($v1)
    li $t4 0x955062
    sw $t4 1564($v1)
    li $t4 0x0a0e17
    sw $t4 1568($v1)
    li $t4 0x010100
    sw $t4 1572($v1)
    li $t4 0x1a1320
    sw $t4 2048($v1)
    li $t4 0xd9e1ff
    sw $t4 2052($v1)
    li $t4 0xac5394
    sw $t4 2056($v1)
    li $t4 0xa1143f
    sw $t4 2060($v1)
    li $t4 0xad94a3
    sw $t4 2064($v1)
    li $t4 0xbd989a
    sw $t4 2068($v1)
    li $t4 0xc75c4e
    sw $t4 2072($v1)
    li $t4 0x913f69
    sw $t4 2076($v1)
    li $t4 0x0b0f16
    sw $t4 2080($v1)
    li $t4 0x040305
    sw $t4 2560($v1)
    li $t4 0x7f3b5b
    sw $t4 2564($v1)
    li $t4 0x81357b
    sw $t4 2568($v1)
    li $t4 0x4d55ad
    sw $t4 2572($v1)
    li $t4 0x8f639d
    sw $t4 2576($v1)
    li $t4 0x874e80
    sw $t4 2580($v1)
    li $t4 0x815cac
    sw $t4 2584($v1)
    li $t4 0x4d2463
    sw $t4 2588($v1)
    li $t4 0x07090a
    sw $t4 2592($v1)
    li $t4 0x010001
    sw $t4 2596($v1)
    li $t4 0x290003
    sw $t4 3076($v1)
    li $t4 0x95517a
    sw $t4 3080($v1)
    li $t4 0x2c1e7f
    sw $t4 3084($v1)
    li $t4 0x873271
    sw $t4 3088($v1)
    li $t4 0x882f60
    sw $t4 3092($v1)
    li $t4 0x451162
    sw $t4 3096($v1)
    li $t4 0x582950
    sw $t4 3100($v1)
    li $t4 0x0b0400
    sw $t4 3104($v1)
    li $t4 0x010402
    sw $t4 3588($v1)
    li $t4 0x420134
    sw $t4 3592($v1)
    li $t4 0x3b389f
    sw $t4 3596($v1)
    li $t4 0xccbee7
    sw $t4 3600($v1)
    li $t4 0xa9a1e4
    sw $t4 3604($v1)
    li $t4 0x300a4e
    sw $t4 3608($v1)
    li $t4 0x330107
    sw $t4 3612($v1)
    li $t4 0x010202
    sw $t4 3616($v1)
    li $t4 0x00093d
    sw $t4 4104($v1)
    li $t4 0x173db2
    sw $t4 4108($v1)
    li $t4 0x819ee4
    sw $t4 4112($v1)
    li $t4 0x35a3ff
    sw $t4 4116($v1)
    li $t4 0x0044a7
    sw $t4 4120($v1)
    li $t4 0x000101
    sw $t4 4128($v1)
    li $t4 0x030106
    sw $t4 4616($v1)
    li $t4 0x272668
    sw $t4 4620($v1)
    li $t4 0x203b94
    sw $t4 4624($v1)
    li $t4 0x002a60
    sw $t4 4628($v1)
    li $t4 0x030f24
    sw $t4 4632($v1)
    li $t4 0x160c07
    sw $t4 5132($v1)
    li $t4 0x220d06
    sw $t4 5136($v1)
    li $t4 0x030000
    sw $t4 5140($v1)
    li $t4 0x000204
    sw $t4 5652($v1)
    jr $ra
draw_doll_01_20: # start at v1, use t4
    draw16($0, 0, 4, 12, 16, 20, 28, 32, 36, 520, 536, 544, 548, 1024, 1028, 1060, 1568)
    draw16($0, 3072, 3616, 3620, 4128, 4132, 4644, 5124, 5148, 5156, 5632, 5636, 5652, 5656, 5660, 5664, 5668)
    li $t4 0x000100
    sw $t4 540($v1)
    sw $t4 3104($v1)
    li $t4 0x010100
    sw $t4 1056($v1)
    sw $t4 4096($v1)
    li $t4 0x000102
    sw $t4 2592($v1)
    sw $t4 4608($v1)
    li $t4 0x020000
    sw $t4 4612($v1)
    sw $t4 4636($v1)
    li $t4 0x000001
    sw $t4 5120($v1)
    sw $t4 5152($v1)
    li $t4 0x020101
    sw $t4 8($v1)
    li $t4 0x010200
    sw $t4 24($v1)
    li $t4 0x020203
    sw $t4 512($v1)
    li $t4 0x030203
    sw $t4 516($v1)
    li $t4 0x1d070a
    sw $t4 524($v1)
    li $t4 0x451b17
    sw $t4 528($v1)
    li $t4 0x391512
    sw $t4 532($v1)
    li $t4 0x3a1716
    sw $t4 1032($v1)
    li $t4 0xdb784a
    sw $t4 1036($v1)
    li $t4 0xe1484a
    sw $t4 1040($v1)
    li $t4 0xe25f4b
    sw $t4 1044($v1)
    li $t4 0x934f34
    sw $t4 1048($v1)
    li $t4 0x050001
    sw $t4 1052($v1)
    li $t4 0x3c3848
    sw $t4 1536($v1)
    li $t4 0x332941
    sw $t4 1540($v1)
    li $t4 0xa45a34
    sw $t4 1544($v1)
    li $t4 0xf2b852
    sw $t4 1548($v1)
    li $t4 0xd18a3c
    sw $t4 1552($v1)
    li $t4 0xbd5d3d
    sw $t4 1556($v1)
    li $t4 0xffd253
    sw $t4 1560($v1)
    li $t4 0x532e1f
    sw $t4 1564($v1)
    li $t4 0x040201
    sw $t4 1572($v1)
    li $t4 0x9f96bc
    sw $t4 2048($v1)
    li $t4 0xe4cfff
    sw $t4 2052($v1)
    li $t4 0xc47c58
    sw $t4 2056($v1)
    li $t4 0xd06a49
    sw $t4 2060($v1)
    li $t4 0x8c6f77
    sw $t4 2064($v1)
    li $t4 0xb17671
    sw $t4 2068($v1)
    li $t4 0xaa4247
    sw $t4 2072($v1)
    li $t4 0x7d4541
    sw $t4 2076($v1)
    li $t4 0x000002
    sw $t4 2080($v1)
    li $t4 0x030200
    sw $t4 2084($v1)
    li $t4 0x6c617f
    sw $t4 2560($v1)
    li $t4 0xc5ccee
    sw $t4 2564($v1)
    li $t4 0xb14b6d
    sw $t4 2568($v1)
    li $t4 0xab334c
    sw $t4 2572($v1)
    li $t4 0xa495a5
    sw $t4 2576($v1)
    li $t4 0xc69e9e
    sw $t4 2580($v1)
    li $t4 0xb0254a
    sw $t4 2584($v1)
    li $t4 0x732640
    sw $t4 2588($v1)
    li $t4 0x030001
    sw $t4 2596($v1)
    li $t4 0x622f4e
    sw $t4 3076($v1)
    li $t4 0x72267e
    sw $t4 3080($v1)
    li $t4 0x6e6cba
    sw $t4 3084($v1)
    li $t4 0x966ea6
    sw $t4 3088($v1)
    li $t4 0xa387b6
    sw $t4 3092($v1)
    li $t4 0x7c386f
    sw $t4 3096($v1)
    li $t4 0x2e0616
    sw $t4 3100($v1)
    li $t4 0x020001
    sw $t4 3108($v1)
    li $t4 0x050204
    sw $t4 3584($v1)
    li $t4 0x620a1e
    sw $t4 3588($v1)
    li $t4 0x7c3f79
    sw $t4 3592($v1)
    li $t4 0x31298c
    sw $t4 3596($v1)
    li $t4 0x913d74
    sw $t4 3600($v1)
    li $t4 0x7a194e
    sw $t4 3604($v1)
    li $t4 0x402c55
    sw $t4 3608($v1)
    li $t4 0x000201
    sw $t4 3612($v1)
    li $t4 0x140705
    sw $t4 4100($v1)
    li $t4 0x4f0b53
    sw $t4 4104($v1)
    li $t4 0x393ea3
    sw $t4 4108($v1)
    li $t4 0xc2aee0
    sw $t4 4112($v1)
    li $t4 0x967cc4
    sw $t4 4116($v1)
    li $t4 0x4f1439
    sw $t4 4120($v1)
    li $t4 0x090301
    sw $t4 4124($v1)
    li $t4 0x00116b
    sw $t4 4616($v1)
    li $t4 0x3b59c2
    sw $t4 4620($v1)
    li $t4 0xd7d2fd
    sw $t4 4624($v1)
    li $t4 0x5f91fc
    sw $t4 4628($v1)
    li $t4 0x00165f
    sw $t4 4632($v1)
    li $t4 0x000103
    sw $t4 4640($v1)
    li $t4 0x0a081c
    sw $t4 5128($v1)
    li $t4 0x273186
    sw $t4 5132($v1)
    li $t4 0x1b3d8a
    sw $t4 5136($v1)
    li $t4 0x013176
    sw $t4 5140($v1)
    li $t4 0x030a19
    sw $t4 5144($v1)
    li $t4 0x080501
    sw $t4 5640($v1)
    li $t4 0x271414
    sw $t4 5644($v1)
    li $t4 0x130400
    sw $t4 5648($v1)
    jr $ra
draw_doll_01_21: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 20, 24, 28, 32, 36, 512, 516, 528, 532, 540, 544, 548)
    draw16($0, 1028, 1032, 1036, 1048, 1056, 1060, 1536, 1572, 2052, 2080, 2592, 3616, 4096, 4128, 4640, 4644)
    sw $0 5156($v1)
    sw $0 5660($v1)
    sw $0 5668($v1)
    li $t4 0x010000
    draw4($t4, 16, 520, 1052, 4132)
    li $t4 0x010101
    draw4($t4, 1568, 2084, 3108, 4608)
    li $t4 0x020101
    sw $t4 536($v1)
    sw $t4 2596($v1)
    li $t4 0x000100
    sw $t4 1044($v1)
    sw $t4 3104($v1)
    li $t4 0x000101
    sw $t4 5120($v1)
    sw $t4 5636($v1)
    li $t4 0x060000
    sw $t4 5124($v1)
    sw $t4 5148($v1)
    li $t4 0x000102
    sw $t4 5152($v1)
    sw $t4 5632($v1)
    li $t4 0x020201
    sw $t4 524($v1)
    li $t4 0x020202
    sw $t4 1024($v1)
    li $t4 0x050602
    sw $t4 1040($v1)
    li $t4 0x020301
    sw $t4 1540($v1)
    li $t4 0x110207
    sw $t4 1544($v1)
    li $t4 0x954233
    sw $t4 1548($v1)
    li $t4 0xbc383d
    sw $t4 1552($v1)
    li $t4 0xb5433b
    sw $t4 1556($v1)
    li $t4 0x431819
    sw $t4 1560($v1)
    li $t4 0x000001
    sw $t4 1564($v1)
    li $t4 0x2f2936
    sw $t4 2048($v1)
    li $t4 0x84472a
    sw $t4 2056($v1)
    li $t4 0xfcb055
    sw $t4 2060($v1)
    li $t4 0xe27b45
    sw $t4 2064($v1)
    li $t4 0xd97547
    sw $t4 2068($v1)
    li $t4 0xde9149
    sw $t4 2072($v1)
    li $t4 0x110501
    sw $t4 2076($v1)
    li $t4 0xcfc3ef
    sw $t4 2560($v1)
    li $t4 0x9287b4
    sw $t4 2564($v1)
    li $t4 0xaf614a
    sw $t4 2568($v1)
    li $t4 0xd57c4b
    sw $t4 2572($v1)
    li $t4 0x8d4f4b
    sw $t4 2576($v1)
    li $t4 0xaf6454
    sw $t4 2580($v1)
    li $t4 0xb43e44
    sw $t4 2584($v1)
    li $t4 0x512a3c
    sw $t4 2588($v1)
    li $t4 0xbcb0d9
    sw $t4 3072($v1)
    li $t4 0xe5e4ff
    sw $t4 3076($v1)
    li $t4 0xa83666
    sw $t4 3080($v1)
    li $t4 0xb8373c
    sw $t4 3084($v1)
    li $t4 0x9c92a4
    sw $t4 3088($v1)
    li $t4 0xc7a08c
    sw $t4 3092($v1)
    li $t4 0x7e1054
    sw $t4 3096($v1)
    li $t4 0x5f406f
    sw $t4 3100($v1)
    li $t4 0x19171e
    sw $t4 3584($v1)
    li $t4 0x92658f
    sw $t4 3588($v1)
    li $t4 0x880e53
    sw $t4 3592($v1)
    li $t4 0x8f5d99
    sw $t4 3596($v1)
    li $t4 0x9b83ab
    sw $t4 3600($v1)
    li $t4 0xa988b0
    sw $t4 3604($v1)
    li $t4 0x774b84
    sw $t4 3608($v1)
    li $t4 0x433655
    sw $t4 3612($v1)
    li $t4 0x020102
    sw $t4 3620($v1)
    li $t4 0x430616
    sw $t4 4100($v1)
    li $t4 0x594e9d
    sw $t4 4104($v1)
    li $t4 0x414aa7
    sw $t4 4108($v1)
    li $t4 0x974981
    sw $t4 4112($v1)
    li $t4 0x83345e
    sw $t4 4116($v1)
    li $t4 0x42242a
    sw $t4 4120($v1)
    li $t4 0x070000
    sw $t4 4124($v1)
    li $t4 0x2a1914
    sw $t4 4612($v1)
    li $t4 0x7e235a
    sw $t4 4616($v1)
    li $t4 0x31248a
    sw $t4 4620($v1)
    li $t4 0x9b74b3
    sw $t4 4624($v1)
    li $t4 0x8f4a8d
    sw $t4 4628($v1)
    li $t4 0x4d0021
    sw $t4 4632($v1)
    li $t4 0x060203
    sw $t4 4636($v1)
    li $t4 0x080c69
    sw $t4 5128($v1)
    li $t4 0x3c53b9
    sw $t4 5132($v1)
    li $t4 0xfae9ff
    sw $t4 5136($v1)
    li $t4 0x8a9fef
    sw $t4 5140($v1)
    li $t4 0x100e49
    sw $t4 5144($v1)
    li $t4 0x030d42
    sw $t4 5640($v1)
    li $t4 0x1b3aa4
    sw $t4 5644($v1)
    li $t4 0x6d97dd
    sw $t4 5648($v1)
    li $t4 0x2374de
    sw $t4 5652($v1)
    li $t4 0x001546
    sw $t4 5656($v1)
    li $t4 0x000103
    sw $t4 5664($v1)
    jr $ra
draw_doll_02_00: # start at v1, use t4
    draw16($0, 0, 4, 16, 20, 28, 32, 36, 512, 516, 520, 524, 536, 544, 548, 1060, 1536)
    draw16($0, 1540, 1568, 2080, 3584, 3616, 3620, 4128, 4132, 4644, 5156, 5632, 5636, 5652, 5660, 5664, 5668)
    li $t4 0x000100
    draw4($t4, 12, 3104, 4612, 5124)
    sw $t4 5148($v1)
    sw $t4 5656($v1)
    li $t4 0x020001
    sw $t4 4608($v1)
    sw $t4 4640($v1)
    sw $t4 5152($v1)
    li $t4 0x010100
    sw $t4 8($v1)
    sw $t4 540($v1)
    li $t4 0x030201
    sw $t4 24($v1)
    sw $t4 4636($v1)
    li $t4 0x010101
    sw $t4 1056($v1)
    sw $t4 2596($v1)
    li $t4 0x020101
    sw $t4 1572($v1)
    sw $t4 2084($v1)
    li $t4 0x140b07
    sw $t4 528($v1)
    li $t4 0x0c0504
    sw $t4 532($v1)
    li $t4 0x030202
    sw $t4 1024($v1)
    li $t4 0x040403
    sw $t4 1028($v1)
    li $t4 0x1b060a
    sw $t4 1032($v1)
    li $t4 0xad523b
    sw $t4 1036($v1)
    li $t4 0xcd3f42
    sw $t4 1040($v1)
    li $t4 0xc94d41
    sw $t4 1044($v1)
    li $t4 0x5a2620
    sw $t4 1048($v1)
    li $t4 0x000001
    sw $t4 1052($v1)
    li $t4 0x925432
    sw $t4 1544($v1)
    li $t4 0xfab252
    sw $t4 1548($v1)
    li $t4 0xd77f46
    sw $t4 1552($v1)
    li $t4 0xcf7446
    sw $t4 1556($v1)
    li $t4 0xe1934b
    sw $t4 1560($v1)
    li $t4 0x170705
    sw $t4 1564($v1)
    li $t4 0x6a6a68
    sw $t4 2048($v1)
    li $t4 0x616168
    sw $t4 2052($v1)
    li $t4 0xa04e37
    sw $t4 2056($v1)
    li $t4 0xd47550
    sw $t4 2060($v1)
    li $t4 0x984441
    sw $t4 2064($v1)
    li $t4 0xbe6452
    sw $t4 2068($v1)
    li $t4 0xad3042
    sw $t4 2072($v1)
    li $t4 0x533237
    sw $t4 2076($v1)
    li $t4 0xcac8c8
    sw $t4 2560($v1)
    li $t4 0xe5ebeb
    sw $t4 2564($v1)
    li $t4 0xaa4262
    sw $t4 2568($v1)
    li $t4 0xac3745
    sw $t4 2572($v1)
    li $t4 0xc9847b
    sw $t4 2576($v1)
    li $t4 0xde947b
    sw $t4 2580($v1)
    li $t4 0x971143
    sw $t4 2584($v1)
    li $t4 0x594b54
    sw $t4 2588($v1)
    li $t4 0x000101
    sw $t4 2592($v1)
    li $t4 0x646262
    sw $t4 3072($v1)
    li $t4 0xc1cecb
    sw $t4 3076($v1)
    li $t4 0x964667
    sw $t4 3080($v1)
    li $t4 0x975971
    sw $t4 3084($v1)
    li $t4 0x8e8d84
    sw $t4 3088($v1)
    li $t4 0xad9fa1
    sw $t4 3092($v1)
    li $t4 0x963760
    sw $t4 3096($v1)
    li $t4 0x3c2c30
    sw $t4 3100($v1)
    li $t4 0x020102
    sw $t4 3108($v1)
    li $t4 0x332e28
    sw $t4 3588($v1)
    li $t4 0xa6415c
    sw $t4 3592($v1)
    li $t4 0x673347
    sw $t4 3596($v1)
    li $t4 0x8b4b67
    sw $t4 3600($v1)
    li $t4 0x882b4f
    sw $t4 3604($v1)
    li $t4 0x7c3642
    sw $t4 3608($v1)
    li $t4 0x060000
    sw $t4 3612($v1)
    li $t4 0x030303
    sw $t4 4096($v1)
    li $t4 0x220d0e
    sw $t4 4100($v1)
    li $t4 0x85143a
    sw $t4 4104($v1)
    li $t4 0x67223e
    sw $t4 4108($v1)
    li $t4 0x9d9295
    sw $t4 4112($v1)
    li $t4 0x916776
    sw $t4 4116($v1)
    li $t4 0x671229
    sw $t4 4120($v1)
    li $t4 0x060405
    sw $t4 4124($v1)
    li $t4 0x53001e
    sw $t4 4616($v1)
    li $t4 0x95204b
    sw $t4 4620($v1)
    li $t4 0xd8f0e8
    sw $t4 4624($v1)
    li $t4 0xe0a7b9
    sw $t4 4628($v1)
    li $t4 0x38000c
    sw $t4 4632($v1)
    li $t4 0x010001
    sw $t4 5120($v1)
    li $t4 0x220811
    sw $t4 5128($v1)
    li $t4 0x771335
    sw $t4 5132($v1)
    li $t4 0x983857
    sw $t4 5136($v1)
    li $t4 0x94183f
    sw $t4 5140($v1)
    li $t4 0x200409
    sw $t4 5144($v1)
    li $t4 0x060704
    sw $t4 5640($v1)
    li $t4 0x2b2b22
    sw $t4 5644($v1)
    li $t4 0x190707
    sw $t4 5648($v1)
    jr $ra
draw_doll_02_01: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 20, 24, 32, 36, 540, 548, 1028, 1056, 1568, 2048, 2052, 2076)
    draw4($0, 2084, 3616, 4132, 4608)
    draw4($0, 4612, 4644, 5148, 5152)
    draw4($0, 5156, 5632, 5636, 5660)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x010000
    draw4($t4, 28, 512, 1572, 5656)
    li $t4 0x020001
    draw4($t4, 3108, 3620, 4128, 4640)
    li $t4 0x010101
    sw $t4 544($v1)
    sw $t4 2596($v1)
    sw $t4 5124($v1)
    li $t4 0x000100
    sw $t4 2080($v1)
    sw $t4 2592($v1)
    sw $t4 5652($v1)
    li $t4 0x000200
    sw $t4 3104($v1)
    sw $t4 4636($v1)
    li $t4 0x020000
    sw $t4 5140($v1)
    sw $t4 5640($v1)
    li $t4 0x000401
    sw $t4 16($v1)
    li $t4 0x010100
    sw $t4 516($v1)
    li $t4 0x0c0205
    sw $t4 520($v1)
    li $t4 0x893d2f
    sw $t4 524($v1)
    li $t4 0xb23439
    sw $t4 528($v1)
    li $t4 0xaa3e37
    sw $t4 532($v1)
    li $t4 0x3a1115
    sw $t4 536($v1)
    li $t4 0x040201
    sw $t4 1024($v1)
    li $t4 0x803c2c
    sw $t4 1032($v1)
    li $t4 0xfba053
    sw $t4 1036($v1)
    li $t4 0xe17249
    sw $t4 1040($v1)
    li $t4 0xdc7b4b
    sw $t4 1044($v1)
    li $t4 0xde944b
    sw $t4 1048($v1)
    li $t4 0x170409
    sw $t4 1052($v1)
    li $t4 0x010001
    sw $t4 1060($v1)
    li $t4 0x050402
    sw $t4 1536($v1)
    li $t4 0x030403
    sw $t4 1540($v1)
    li $t4 0x9d4e36
    sw $t4 1544($v1)
    li $t4 0xd98a50
    sw $t4 1548($v1)
    li $t4 0x984939
    sw $t4 1552($v1)
    li $t4 0xbb6b48
    sw $t4 1556($v1)
    li $t4 0xbb6443
    sw $t4 1560($v1)
    li $t4 0x170509
    sw $t4 1564($v1)
    li $t4 0x55141a
    sw $t4 2056($v1)
    li $t4 0xc54c52
    sw $t4 2060($v1)
    li $t4 0xc27473
    sw $t4 2064($v1)
    li $t4 0xe28f78
    sw $t4 2068($v1)
    li $t4 0x850a31
    sw $t4 2072($v1)
    li $t4 0x222020
    sw $t4 2560($v1)
    li $t4 0x555b5a
    sw $t4 2564($v1)
    li $t4 0x651c35
    sw $t4 2568($v1)
    li $t4 0xa55c73
    sw $t4 2572($v1)
    li $t4 0x8a8274
    sw $t4 2576($v1)
    li $t4 0xa58f8c
    sw $t4 2580($v1)
    li $t4 0x942d58
    sw $t4 2584($v1)
    li $t4 0x48393f
    sw $t4 2588($v1)
    li $t4 0xc4c4c5
    sw $t4 3072($v1)
    li $t4 0xddddd8
    sw $t4 3076($v1)
    li $t4 0x9f3a59
    sw $t4 3080($v1)
    li $t4 0x714254
    sw $t4 3084($v1)
    li $t4 0x804f66
    sw $t4 3088($v1)
    li $t4 0x813554
    sw $t4 3092($v1)
    li $t4 0x933951
    sw $t4 3096($v1)
    li $t4 0x5a3543
    sw $t4 3100($v1)
    li $t4 0xcdd0d1
    sw $t4 3584($v1)
    li $t4 0xbbaeaa
    sw $t4 3588($v1)
    li $t4 0x841d3a
    sw $t4 3592($v1)
    li $t4 0x611e3a
    sw $t4 3596($v1)
    li $t4 0x8d6571
    sw $t4 3600($v1)
    li $t4 0x733149
    sw $t4 3604($v1)
    li $t4 0x8e1f3d
    sw $t4 3608($v1)
    li $t4 0x1f040e
    sw $t4 3612($v1)
    li $t4 0x4a4848
    sw $t4 4096($v1)
    li $t4 0x141717
    sw $t4 4100($v1)
    li $t4 0x2c0011
    sw $t4 4104($v1)
    li $t4 0x8a0837
    sw $t4 4108($v1)
    li $t4 0xd5ebe3
    sw $t4 4112($v1)
    li $t4 0xcda2b0
    sw $t4 4116($v1)
    li $t4 0x480011
    sw $t4 4120($v1)
    li $t4 0x020201
    sw $t4 4124($v1)
    li $t4 0x1b070f
    sw $t4 4616($v1)
    li $t4 0x850e37
    sw $t4 4620($v1)
    li $t4 0xa37e8c
    sw $t4 4624($v1)
    li $t4 0xa13356
    sw $t4 4628($v1)
    li $t4 0x290207
    sw $t4 4632($v1)
    li $t4 0x030303
    sw $t4 5120($v1)
    li $t4 0x090806
    sw $t4 5128($v1)
    li $t4 0x332c27
    sw $t4 5132($v1)
    li $t4 0x20050a
    sw $t4 5136($v1)
    li $t4 0x000101
    sw $t4 5144($v1)
    li $t4 0x040000
    sw $t4 5644($v1)
    li $t4 0x020401
    sw $t4 5648($v1)
    jr $ra
draw_doll_02_02: # start at v1, use t4
    draw16($0, 0, 8, 24, 32, 36, 540, 548, 1056, 1536, 1568, 3616, 4096, 4100, 4132, 4636, 4644)
    draw4($0, 5120, 5124, 5144, 5148)
    draw4($0, 5152, 5156, 5632, 5636)
    draw4($0, 5640, 5644, 5660, 5664)
    sw $0 5668($v1)
    li $t4 0x020101
    draw4($t4, 512, 1060, 2596, 4128)
    li $t4 0x010001
    sw $t4 2084($v1)
    sw $t4 3620($v1)
    sw $t4 4640($v1)
    li $t4 0x010000
    sw $t4 4($v1)
    sw $t4 5656($v1)
    li $t4 0x010100
    sw $t4 28($v1)
    sw $t4 516($v1)
    li $t4 0x010101
    sw $t4 544($v1)
    sw $t4 3108($v1)
    li $t4 0x000101
    sw $t4 1028($v1)
    sw $t4 2080($v1)
    li $t4 0x090104
    sw $t4 12($v1)
    li $t4 0x2a130e
    sw $t4 16($v1)
    li $t4 0x1f0b0a
    sw $t4 20($v1)
    li $t4 0x250c0d
    sw $t4 520($v1)
    li $t4 0xbd5a41
    sw $t4 524($v1)
    li $t4 0xd44044
    sw $t4 528($v1)
    li $t4 0xd25745
    sw $t4 532($v1)
    li $t4 0x6f3827
    sw $t4 536($v1)
    li $t4 0x050603
    sw $t4 1024($v1)
    li $t4 0xa05d38
    sw $t4 1032($v1)
    li $t4 0xf8bc50
    sw $t4 1036($v1)
    li $t4 0xd69645
    sw $t4 1040($v1)
    li $t4 0xe09f4a
    sw $t4 1044($v1)
    li $t4 0xe1974d
    sw $t4 1048($v1)
    li $t4 0x210c0e
    sw $t4 1052($v1)
    li $t4 0x1a0009
    sw $t4 1540($v1)
    li $t4 0xc34347
    sw $t4 1544($v1)
    li $t4 0xd07b50
    sw $t4 1548($v1)
    li $t4 0xab514d
    sw $t4 1552($v1)
    li $t4 0xca725a
    sw $t4 1556($v1)
    li $t4 0xa11c3e
    sw $t4 1560($v1)
    li $t4 0x210006
    sw $t4 1564($v1)
    li $t4 0x020001
    sw $t4 1572($v1)
    li $t4 0x2c2f2e
    sw $t4 2048($v1)
    li $t4 0x431629
    sw $t4 2052($v1)
    li $t4 0x880530
    sw $t4 2056($v1)
    li $t4 0xab3f51
    sw $t4 2060($v1)
    li $t4 0xc38276
    sw $t4 2064($v1)
    li $t4 0xd7937c
    sw $t4 2068($v1)
    li $t4 0x90113f
    sw $t4 2072($v1)
    li $t4 0x42383e
    sw $t4 2076($v1)
    li $t4 0xc0c0c0
    sw $t4 2560($v1)
    li $t4 0xcdd2d2
    sw $t4 2564($v1)
    li $t4 0x7b2646
    sw $t4 2568($v1)
    li $t4 0x975e75
    sw $t4 2572($v1)
    li $t4 0x8d8f88
    sw $t4 2576($v1)
    li $t4 0xa3989c
    sw $t4 2580($v1)
    li $t4 0x9c637c
    sw $t4 2584($v1)
    li $t4 0x5e4b51
    sw $t4 2588($v1)
    li $t4 0x000200
    sw $t4 2592($v1)
    li $t4 0xa5a6a7
    sw $t4 3072($v1)
    li $t4 0xddd6cf
    sw $t4 3076($v1)
    li $t4 0xa23a56
    sw $t4 3080($v1)
    li $t4 0x5f283d
    sw $t4 3084($v1)
    li $t4 0x865e6f
    sw $t4 3088($v1)
    li $t4 0x87274a
    sw $t4 3092($v1)
    li $t4 0x883848
    sw $t4 3096($v1)
    li $t4 0x3b2929
    sw $t4 3100($v1)
    li $t4 0x000100
    sw $t4 3104($v1)
    li $t4 0x616464
    sw $t4 3584($v1)
    li $t4 0x483437
    sw $t4 3588($v1)
    li $t4 0x74062a
    sw $t4 3592($v1)
    li $t4 0x73304b
    sw $t4 3596($v1)
    li $t4 0x99aca5
    sw $t4 3600($v1)
    li $t4 0x8f7d84
    sw $t4 3604($v1)
    li $t4 0x590821
    sw $t4 3608($v1)
    li $t4 0x190409
    sw $t4 3612($v1)
    li $t4 0x4d011d
    sw $t4 4104($v1)
    li $t4 0xa2325a
    sw $t4 4108($v1)
    li $t4 0xd88da3
    sw $t4 4112($v1)
    li $t4 0xcd6d8b
    sw $t4 4116($v1)
    li $t4 0x330717
    sw $t4 4120($v1)
    li $t4 0x030002
    sw $t4 4124($v1)
    li $t4 0x040304
    sw $t4 4608($v1)
    li $t4 0x020202
    sw $t4 4612($v1)
    li $t4 0x1c080f
    sw $t4 4616($v1)
    li $t4 0x731535
    sw $t4 4620($v1)
    li $t4 0x96002a
    sw $t4 4624($v1)
    li $t4 0x800021
    sw $t4 4628($v1)
    li $t4 0x1d050c
    sw $t4 4632($v1)
    li $t4 0x060603
    sw $t4 5128($v1)
    li $t4 0x20241a
    sw $t4 5132($v1)
    li $t4 0x0d130b
    sw $t4 5136($v1)
    li $t4 0x000300
    sw $t4 5140($v1)
    li $t4 0x020000
    sw $t4 5648($v1)
    li $t4 0x030001
    sw $t4 5652($v1)
    jr $ra
draw_doll_02_03: # start at v1, use t4
    draw16($0, 0, 4, 12, 16, 20, 28, 32, 36, 520, 536, 544, 548, 1024, 1060, 1568, 3584)
    draw4($0, 4608, 4644, 5156, 5632)
    draw4($0, 5636, 5640, 5652, 5656)
    sw $0 5660($v1)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x000100
    draw4($t4, 540, 2080, 2592, 3616)
    sw $t4 4128($v1)
    sw $t4 4636($v1)
    sw $t4 5124($v1)
    li $t4 0x020101
    sw $t4 8($v1)
    sw $t4 516($v1)
    sw $t4 1572($v1)
    li $t4 0x010101
    sw $t4 512($v1)
    sw $t4 2596($v1)
    li $t4 0x010100
    sw $t4 1056($v1)
    sw $t4 5148($v1)
    li $t4 0x000301
    sw $t4 3104($v1)
    sw $t4 4612($v1)
    li $t4 0x010001
    sw $t4 3108($v1)
    sw $t4 4132($v1)
    li $t4 0x010000
    sw $t4 5120($v1)
    sw $t4 5152($v1)
    li $t4 0x000300
    sw $t4 5644($v1)
    sw $t4 5648($v1)
    li $t4 0x010200
    sw $t4 24($v1)
    li $t4 0x1d060a
    sw $t4 524($v1)
    li $t4 0x451917
    sw $t4 528($v1)
    li $t4 0x381112
    sw $t4 532($v1)
    li $t4 0x000200
    sw $t4 1028($v1)
    li $t4 0x401318
    sw $t4 1032($v1)
    li $t4 0xdd7b4b
    sw $t4 1036($v1)
    li $t4 0xea6b4b
    sw $t4 1040($v1)
    li $t4 0xed8f4d
    sw $t4 1044($v1)
    li $t4 0x904f32
    sw $t4 1048($v1)
    li $t4 0x030001
    sw $t4 1052($v1)
    li $t4 0x151816
    sw $t4 1536($v1)
    li $t4 0x140004
    sw $t4 1540($v1)
    li $t4 0xd06b47
    sw $t4 1544($v1)
    li $t4 0xe6a84c
    sw $t4 1548($v1)
    li $t4 0xb96345
    sw $t4 1552($v1)
    li $t4 0xbb6548
    sw $t4 1556($v1)
    li $t4 0xdd8c4c
    sw $t4 1560($v1)
    li $t4 0x250e0d
    sw $t4 1564($v1)
    li $t4 0xb8c0be
    sw $t4 2048($v1)
    li $t4 0xad7c8b
    sw $t4 2052($v1)
    li $t4 0xba3d38
    sw $t4 2056($v1)
    li $t4 0xba534d
    sw $t4 2060($v1)
    li $t4 0xac5c5c
    sw $t4 2064($v1)
    li $t4 0xd57a66
    sw $t4 2068($v1)
    li $t4 0x990f39
    sw $t4 2072($v1)
    li $t4 0x2a0b14
    sw $t4 2076($v1)
    li $t4 0x020001
    sw $t4 2084($v1)
    li $t4 0xd6d7d6
    sw $t4 2560($v1)
    li $t4 0xd9d9d9
    sw $t4 2564($v1)
    li $t4 0x8a0e47
    sw $t4 2568($v1)
    li $t4 0xa94257
    sw $t4 2572($v1)
    li $t4 0xc49c7f
    sw $t4 2576($v1)
    li $t4 0xd29c88
    sw $t4 2580($v1)
    li $t4 0x9f2a55
    sw $t4 2584($v1)
    li $t4 0x5f585d
    sw $t4 2588($v1)
    li $t4 0x646565
    sw $t4 3072($v1)
    li $t4 0x9fa6a4
    sw $t4 3076($v1)
    li $t4 0x913658
    sw $t4 3080($v1)
    li $t4 0x88546a
    sw $t4 3084($v1)
    li $t4 0x836f77
    sw $t4 3088($v1)
    li $t4 0x835369
    sw $t4 3092($v1)
    li $t4 0x905870
    sw $t4 3096($v1)
    li $t4 0x412a34
    sw $t4 3100($v1)
    li $t4 0x281a15
    sw $t4 3588($v1)
    li $t4 0xa9405b
    sw $t4 3592($v1)
    li $t4 0x562137
    sw $t4 3596($v1)
    li $t4 0x7a5b64
    sw $t4 3600($v1)
    li $t4 0x791f43
    sw $t4 3604($v1)
    li $t4 0x811336
    sw $t4 3608($v1)
    li $t4 0x492425
    sw $t4 3612($v1)
    li $t4 0x030101
    sw $t4 3620($v1)
    li $t4 0x030303
    sw $t4 4096($v1)
    li $t4 0x19090d
    sw $t4 4100($v1)
    li $t4 0x6f0429
    sw $t4 4104($v1)
    li $t4 0x835467
    sw $t4 4108($v1)
    li $t4 0xb4bab9
    sw $t4 4112($v1)
    li $t4 0xa69da1
    sw $t4 4116($v1)
    li $t4 0x55132b
    sw $t4 4120($v1)
    li $t4 0x1d050b
    sw $t4 4124($v1)
    li $t4 0x6c042d
    sw $t4 4616($v1)
    li $t4 0xac003c
    sw $t4 4620($v1)
    li $t4 0xcc003f
    sw $t4 4624($v1)
    li $t4 0xd30244
    sw $t4 4628($v1)
    li $t4 0x5a0926
    sw $t4 4632($v1)
    li $t4 0x020000
    sw $t4 4640($v1)
    li $t4 0x200810
    sw $t4 5128($v1)
    li $t4 0x540c1e
    sw $t4 5132($v1)
    li $t4 0x7a0425
    sw $t4 5136($v1)
    li $t4 0x5e011e
    sw $t4 5140($v1)
    li $t4 0x17040a
    sw $t4 5144($v1)
    jr $ra
draw_doll_02_04: # start at v1, use t4
    draw16($0, 0, 36, 516, 544, 1056, 1536, 1540, 1568, 2084, 2596, 3616, 3620, 4096, 4100, 4132, 4616)
    draw16($0, 4632, 4640, 4644, 5120, 5124, 5128, 5148, 5152, 5156, 5632, 5636, 5640, 5644, 5652, 5656, 5660)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x010000
    draw4($t4, 1572, 3108, 3612, 4636)
    sw $t4 5132($v1)
    li $t4 0x010100
    sw $t4 4($v1)
    sw $t4 32($v1)
    li $t4 0x020001
    sw $t4 8($v1)
    sw $t4 4128($v1)
    li $t4 0x040201
    sw $t4 548($v1)
    sw $t4 1060($v1)
    li $t4 0x88412f
    sw $t4 12($v1)
    li $t4 0xd34445
    sw $t4 16($v1)
    li $t4 0xd54743
    sw $t4 20($v1)
    li $t4 0x7e2e2c
    sw $t4 24($v1)
    li $t4 0x040002
    sw $t4 28($v1)
    li $t4 0x030101
    sw $t4 512($v1)
    li $t4 0x4b171b
    sw $t4 520($v1)
    li $t4 0xf5aa52
    sw $t4 524($v1)
    li $t4 0xdc7e48
    sw $t4 528($v1)
    li $t4 0xd17746
    sw $t4 532($v1)
    li $t4 0xee9a4f
    sw $t4 536($v1)
    li $t4 0x52291d
    sw $t4 540($v1)
    li $t4 0x050302
    sw $t4 1024($v1)
    li $t4 0x030303
    sw $t4 1028($v1)
    li $t4 0x4f211b
    sw $t4 1032($v1)
    li $t4 0xe18250
    sw $t4 1036($v1)
    li $t4 0x9f5143
    sw $t4 1040($v1)
    li $t4 0xae4d47
    sw $t4 1044($v1)
    li $t4 0xbf5448
    sw $t4 1048($v1)
    li $t4 0x51261b
    sw $t4 1052($v1)
    li $t4 0x1a0004
    sw $t4 1544($v1)
    li $t4 0xb53648
    sw $t4 1548($v1)
    li $t4 0xb86566
    sw $t4 1552($v1)
    li $t4 0xe6a689
    sw $t4 1556($v1)
    li $t4 0x9d2941
    sw $t4 1560($v1)
    li $t4 0x050001
    sw $t4 1564($v1)
    li $t4 0x1d1b1c
    sw $t4 2048($v1)
    li $t4 0x3a413e
    sw $t4 2052($v1)
    li $t4 0x5b3142
    sw $t4 2056($v1)
    li $t4 0x923559
    sw $t4 2060($v1)
    li $t4 0x9f9b93
    sw $t4 2064($v1)
    li $t4 0x8f7e7c
    sw $t4 2068($v1)
    li $t4 0xa47e8d
    sw $t4 2072($v1)
    li $t4 0x604f58
    sw $t4 2076($v1)
    li $t4 0x080b09
    sw $t4 2080($v1)
    li $t4 0x89898a
    sw $t4 2560($v1)
    li $t4 0xdee1dd
    sw $t4 2564($v1)
    li $t4 0xae6877
    sw $t4 2568($v1)
    li $t4 0x6f1534
    sw $t4 2572($v1)
    li $t4 0x9f9ea1
    sw $t4 2576($v1)
    li $t4 0x9b4064
    sw $t4 2580($v1)
    li $t4 0x7f3a55
    sw $t4 2584($v1)
    li $t4 0x702c3b
    sw $t4 2588($v1)
    li $t4 0x0e0f0c
    sw $t4 2592($v1)
    li $t4 0x888989
    sw $t4 3072($v1)
    li $t4 0xceccc9
    sw $t4 3076($v1)
    li $t4 0x882842
    sw $t4 3080($v1)
    li $t4 0x69082e
    sw $t4 3084($v1)
    li $t4 0x8b747c
    sw $t4 3088($v1)
    li $t4 0x9c8289
    sw $t4 3092($v1)
    li $t4 0x570125
    sw $t4 3096($v1)
    li $t4 0x67232d
    sw $t4 3100($v1)
    li $t4 0x070503
    sw $t4 3104($v1)
    li $t4 0x2c2b2b
    sw $t4 3584($v1)
    li $t4 0x181818
    sw $t4 3588($v1)
    li $t4 0x100009
    sw $t4 3592($v1)
    li $t4 0x7d0027
    sw $t4 3596($v1)
    li $t4 0xccb6bf
    sw $t4 3600($v1)
    li $t4 0xd3d1d2
    sw $t4 3604($v1)
    li $t4 0x570620
    sw $t4 3608($v1)
    li $t4 0x040706
    sw $t4 4104($v1)
    li $t4 0x690726
    sw $t4 4108($v1)
    li $t4 0xa84464
    sw $t4 4112($v1)
    li $t4 0xa24060
    sw $t4 4116($v1)
    li $t4 0x460112
    sw $t4 4120($v1)
    li $t4 0x000300
    sw $t4 4124($v1)
    li $t4 0x020202
    sw $t4 4608($v1)
    li $t4 0x030202
    sw $t4 4612($v1)
    li $t4 0x1a1713
    sw $t4 4620($v1)
    li $t4 0x2c1212
    sw $t4 4624($v1)
    li $t4 0x0c0000
    sw $t4 4628($v1)
    li $t4 0x000200
    sw $t4 5136($v1)
    li $t4 0x010201
    sw $t4 5140($v1)
    li $t4 0x020000
    sw $t4 5144($v1)
    li $t4 0x000001
    sw $t4 5648($v1)
    jr $ra
draw_doll_02_05: # start at v1, use t4
    draw16($0, 0, 8, 1024, 1028, 1056, 2084, 2596, 3108, 3584, 3588, 4608, 4612, 4636, 4640, 4644, 5120)
    draw4($0, 5124, 5128, 5136, 5140)
    draw4($0, 5148, 5152, 5156, 5632)
    draw4($0, 5636, 5640, 5644, 5656)
    sw $0 5660($v1)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x010000
    draw4($t4, 36, 1572, 3620, 4128)
    sw $t4 4132($v1)
    li $t4 0x020101
    sw $t4 512($v1)
    sw $t4 1060($v1)
    sw $t4 4096($v1)
    li $t4 0x010101
    sw $t4 544($v1)
    sw $t4 5648($v1)
    li $t4 0x000101
    sw $t4 3616($v1)
    sw $t4 5652($v1)
    li $t4 0x000100
    sw $t4 4620($v1)
    sw $t4 4632($v1)
    li $t4 0x020201
    sw $t4 4($v1)
    li $t4 0x58251f
    sw $t4 12($v1)
    li $t4 0xcf5045
    sw $t4 16($v1)
    li $t4 0xd64543
    sw $t4 20($v1)
    li $t4 0xa84439
    sw $t4 24($v1)
    li $t4 0x19080a
    sw $t4 28($v1)
    li $t4 0x010100
    sw $t4 32($v1)
    li $t4 0x010201
    sw $t4 516($v1)
    li $t4 0x160309
    sw $t4 520($v1)
    li $t4 0xe19b4c
    sw $t4 524($v1)
    li $t4 0xe5924a
    sw $t4 528($v1)
    li $t4 0xce7145
    sw $t4 532($v1)
    li $t4 0xe58c4c
    sw $t4 536($v1)
    li $t4 0x905b31
    sw $t4 540($v1)
    li $t4 0x030301
    sw $t4 548($v1)
    li $t4 0x2c0a12
    sw $t4 1032($v1)
    li $t4 0xe2824e
    sw $t4 1036($v1)
    li $t4 0xac5646
    sw $t4 1040($v1)
    li $t4 0xaa5745
    sw $t4 1044($v1)
    li $t4 0xbf5250
    sw $t4 1048($v1)
    li $t4 0x82222c
    sw $t4 1052($v1)
    li $t4 0x0f0d0e
    sw $t4 1536($v1)
    li $t4 0x050505
    sw $t4 1540($v1)
    li $t4 0x120001
    sw $t4 1544($v1)
    li $t4 0xab2240
    sw $t4 1548($v1)
    li $t4 0xb3555a
    sw $t4 1552($v1)
    li $t4 0xdda288
    sw $t4 1556($v1)
    li $t4 0xc25159
    sw $t4 1560($v1)
    li $t4 0x681036
    sw $t4 1564($v1)
    li $t4 0x161b18
    sw $t4 1568($v1)
    li $t4 0x535252
    sw $t4 2048($v1)
    li $t4 0xbfc1c1
    sw $t4 2052($v1)
    li $t4 0x796d74
    sw $t4 2056($v1)
    li $t4 0x7d143d
    sw $t4 2060($v1)
    li $t4 0xac999b
    sw $t4 2064($v1)
    li $t4 0x888078
    sw $t4 2068($v1)
    li $t4 0xa6818f
    sw $t4 2072($v1)
    li $t4 0x8c546c
    sw $t4 2076($v1)
    li $t4 0x252d2b
    sw $t4 2080($v1)
    li $t4 0x2b2b2b
    sw $t4 2560($v1)
    li $t4 0xdde0df
    sw $t4 2564($v1)
    li $t4 0xd0abae
    sw $t4 2568($v1)
    li $t4 0x7f1034
    sw $t4 2572($v1)
    li $t4 0x747175
    sw $t4 2576($v1)
    li $t4 0x933a5f
    sw $t4 2580($v1)
    li $t4 0x792e4b
    sw $t4 2584($v1)
    li $t4 0x902246
    sw $t4 2588($v1)
    li $t4 0x2c1d1d
    sw $t4 2592($v1)
    li $t4 0x343334
    sw $t4 3072($v1)
    li $t4 0x7c817f
    sw $t4 3076($v1)
    li $t4 0x6e2b37
    sw $t4 3080($v1)
    li $t4 0x760931
    sw $t4 3084($v1)
    li $t4 0x715460
    sw $t4 3088($v1)
    li $t4 0xaa969b
    sw $t4 3092($v1)
    li $t4 0x6c213f
    sw $t4 3096($v1)
    li $t4 0x650824
    sw $t4 3100($v1)
    li $t4 0x150b09
    sw $t4 3104($v1)
    li $t4 0x0e0008
    sw $t4 3592($v1)
    li $t4 0x80002a
    sw $t4 3596($v1)
    li $t4 0xaa808f
    sw $t4 3600($v1)
    li $t4 0xf2fffe
    sw $t4 3604($v1)
    li $t4 0x9f4060
    sw $t4 3608($v1)
    li $t4 0x0a0001
    sw $t4 3612($v1)
    li $t4 0x040303
    sw $t4 4100($v1)
    li $t4 0x030604
    sw $t4 4104($v1)
    li $t4 0x4b051d
    sw $t4 4108($v1)
    li $t4 0x902348
    sw $t4 4112($v1)
    li $t4 0xb44c6d
    sw $t4 4116($v1)
    li $t4 0x780428
    sw $t4 4120($v1)
    li $t4 0x0b0104
    sw $t4 4124($v1)
    li $t4 0x010001
    sw $t4 4616($v1)
    li $t4 0x201916
    sw $t4 4624($v1)
    li $t4 0x3b201f
    sw $t4 4628($v1)
    li $t4 0x020000
    sw $t4 5132($v1)
    li $t4 0x030001
    sw $t4 5144($v1)
    jr $ra
draw_doll_02_06: # start at v1, use t4
    draw16($0, 0, 512, 1028, 1060, 1572, 2084, 2596, 3072, 3108, 4100, 4608, 4612, 4636, 4644, 5120, 5124)
    draw4($0, 5128, 5132, 5136, 5152)
    draw4($0, 5156, 5632, 5636, 5640)
    draw4($0, 5644, 5652, 5656, 5660)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x010001
    draw4($t4, 4, 36, 3620, 4640)
    sw $t4 5648($v1)
    li $t4 0x010000
    draw4($t4, 3584, 4096, 4616, 5148)
    li $t4 0x020101
    sw $t4 8($v1)
    li $t4 0x0f0006
    sw $t4 12($v1)
    li $t4 0x81302c
    sw $t4 16($v1)
    li $t4 0xa43234
    sw $t4 20($v1)
    li $t4 0x862a2c
    sw $t4 24($v1)
    li $t4 0x150009
    sw $t4 28($v1)
    li $t4 0x000100
    sw $t4 32($v1)
    li $t4 0x040402
    sw $t4 516($v1)
    li $t4 0x000201
    sw $t4 520($v1)
    li $t4 0x8c5131
    sw $t4 524($v1)
    li $t4 0xf59951
    sw $t4 528($v1)
    li $t4 0xe2744a
    sw $t4 532($v1)
    li $t4 0xf29b51
    sw $t4 536($v1)
    li $t4 0xaf753b
    sw $t4 540($v1)
    li $t4 0x040302
    sw $t4 544($v1)
    li $t4 0x020201
    sw $t4 548($v1)
    li $t4 0x040303
    sw $t4 1024($v1)
    li $t4 0x1c0005
    sw $t4 1032($v1)
    li $t4 0xeb9250
    sw $t4 1036($v1)
    li $t4 0xd5964a
    sw $t4 1040($v1)
    li $t4 0xb6763e
    sw $t4 1044($v1)
    li $t4 0xc47749
    sw $t4 1048($v1)
    li $t4 0xc95c46
    sw $t4 1052($v1)
    li $t4 0x310c0d
    sw $t4 1056($v1)
    li $t4 0x201d1e
    sw $t4 1536($v1)
    li $t4 0x9fa8a5
    sw $t4 1540($v1)
    li $t4 0x7d3550
    sw $t4 1544($v1)
    li $t4 0xbb2d39
    sw $t4 1548($v1)
    li $t4 0xb74c54
    sw $t4 1552($v1)
    li $t4 0xc97174
    sw $t4 1556($v1)
    li $t4 0xd57769
    sw $t4 1560($v1)
    li $t4 0x8d0239
    sw $t4 1564($v1)
    li $t4 0x39262d
    sw $t4 1568($v1)
    li $t4 0x191919
    sw $t4 2048($v1)
    li $t4 0xd8d9d8
    sw $t4 2052($v1)
    li $t4 0xe2eae9
    sw $t4 2056($v1)
    li $t4 0x93365d
    sw $t4 2060($v1)
    li $t4 0xa14d64
    sw $t4 2064($v1)
    li $t4 0xa89f87
    sw $t4 2068($v1)
    li $t4 0xad8282
    sw $t4 2072($v1)
    li $t4 0x984969
    sw $t4 2076($v1)
    li $t4 0x49504e
    sw $t4 2080($v1)
    li $t4 0x0b0b0b
    sw $t4 2560($v1)
    li $t4 0x919090
    sw $t4 2564($v1)
    li $t4 0xc3b2b7
    sw $t4 2568($v1)
    li $t4 0x973d5a
    sw $t4 2572($v1)
    li $t4 0x763f54
    sw $t4 2576($v1)
    li $t4 0x846073
    sw $t4 2580($v1)
    li $t4 0x7d4862
    sw $t4 2584($v1)
    li $t4 0x8d3959
    sw $t4 2588($v1)
    li $t4 0x3e1723
    sw $t4 2592($v1)
    li $t4 0x040000
    sw $t4 3076($v1)
    li $t4 0x930c3a
    sw $t4 3080($v1)
    li $t4 0x922f47
    sw $t4 3084($v1)
    li $t4 0x5a2e40
    sw $t4 3088($v1)
    li $t4 0x8c6672
    sw $t4 3092($v1)
    li $t4 0x702742
    sw $t4 3096($v1)
    li $t4 0x7a002a
    sw $t4 3100($v1)
    li $t4 0x41121a
    sw $t4 3104($v1)
    li $t4 0x0b0205
    sw $t4 3588($v1)
    li $t4 0x310619
    sw $t4 3592($v1)
    li $t4 0x730024
    sw $t4 3596($v1)
    li $t4 0x924b66
    sw $t4 3600($v1)
    li $t4 0xe0fff9
    sw $t4 3604($v1)
    li $t4 0xb18a97
    sw $t4 3608($v1)
    li $t4 0x2b0109
    sw $t4 3612($v1)
    li $t4 0x050203
    sw $t4 3616($v1)
    li $t4 0x000603
    sw $t4 4104($v1)
    li $t4 0x70052a
    sw $t4 4108($v1)
    li $t4 0xa71948
    sw $t4 4112($v1)
    li $t4 0xc7859d
    sw $t4 4116($v1)
    li $t4 0xc62e5e
    sw $t4 4120($v1)
    li $t4 0x33010d
    sw $t4 4124($v1)
    li $t4 0x000200
    sw $t4 4128($v1)
    li $t4 0x020001
    sw $t4 4132($v1)
    li $t4 0x010303
    sw $t4 4620($v1)
    li $t4 0x150107
    sw $t4 4624($v1)
    li $t4 0x5f2430
    sw $t4 4628($v1)
    li $t4 0x291014
    sw $t4 4632($v1)
    li $t4 0x050902
    sw $t4 5140($v1)
    li $t4 0x060501
    sw $t4 5144($v1)
    jr $ra
draw_doll_02_07: # start at v1, use t4
    draw16($0, 0, 4, 12, 28, 36, 512, 544, 1028, 1032, 1060, 1572, 2048, 2560, 3072, 3584, 4096)
    draw4($0, 4128, 4608, 5120, 5124)
    draw4($0, 5128, 5132, 5136, 5152)
    draw4($0, 5632, 5636, 5640, 5656)
    sw $0 5660($v1)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x000100
    draw4($t4, 32, 4100, 5140, 5156)
    li $t4 0x010000
    sw $t4 8($v1)
    sw $t4 1024($v1)
    sw $t4 4612($v1)
    li $t4 0x020001
    sw $t4 1536($v1)
    sw $t4 5648($v1)
    sw $t4 5652($v1)
    li $t4 0x010101
    sw $t4 548($v1)
    sw $t4 4640($v1)
    li $t4 0x020101
    sw $t4 4132($v1)
    sw $t4 4616($v1)
    li $t4 0x040002
    sw $t4 16($v1)
    li $t4 0x260d0d
    sw $t4 20($v1)
    li $t4 0x220a0b
    sw $t4 24($v1)
    li $t4 0x030202
    sw $t4 516($v1)
    li $t4 0x010201
    sw $t4 520($v1)
    li $t4 0x1a020a
    sw $t4 524($v1)
    li $t4 0xb45d3d
    sw $t4 528($v1)
    li $t4 0xdd5a47
    sw $t4 532($v1)
    li $t4 0xdb6b45
    sw $t4 536($v1)
    li $t4 0x7e3e2d
    sw $t4 540($v1)
    li $t4 0xb15640
    sw $t4 1036($v1)
    li $t4 0xf5b750
    sw $t4 1040($v1)
    li $t4 0xbc6740
    sw $t4 1044($v1)
    li $t4 0xc5744a
    sw $t4 1048($v1)
    li $t4 0xf0a551
    sw $t4 1052($v1)
    li $t4 0x4b2d1a
    sw $t4 1056($v1)
    li $t4 0x2b302e
    sw $t4 1540($v1)
    li $t4 0x5b1e2f
    sw $t4 1544($v1)
    li $t4 0xce503b
    sw $t4 1548($v1)
    li $t4 0xce7c54
    sw $t4 1552($v1)
    li $t4 0x973b4f
    sw $t4 1556($v1)
    li $t4 0xd57b65
    sw $t4 1560($v1)
    li $t4 0xb53744
    sw $t4 1564($v1)
    li $t4 0x6c2423
    sw $t4 1568($v1)
    li $t4 0x6f7271
    sw $t4 2052($v1)
    li $t4 0xdac4ce
    sw $t4 2056($v1)
    li $t4 0x99284f
    sw $t4 2060($v1)
    li $t4 0xa02741
    sw $t4 2064($v1)
    li $t4 0xc09076
    sw $t4 2068($v1)
    li $t4 0xdfa987
    sw $t4 2072($v1)
    li $t4 0x9c1945
    sw $t4 2076($v1)
    li $t4 0x644e5b
    sw $t4 2080($v1)
    li $t4 0x030605
    sw $t4 2084($v1)
    li $t4 0x545454
    sw $t4 2564($v1)
    li $t4 0xedfffc
    sw $t4 2568($v1)
    li $t4 0x9e6d81
    sw $t4 2572($v1)
    li $t4 0x952550
    sw $t4 2576($v1)
    li $t4 0x827e80
    sw $t4 2580($v1)
    li $t4 0x88757d
    sw $t4 2584($v1)
    li $t4 0xa37085
    sw $t4 2588($v1)
    li $t4 0x593c49
    sw $t4 2592($v1)
    li $t4 0x040806
    sw $t4 2596($v1)
    li $t4 0x3a1423
    sw $t4 3076($v1)
    li $t4 0xb64d78
    sw $t4 3080($v1)
    li $t4 0xa94e5a
    sw $t4 3084($v1)
    li $t4 0x79464f
    sw $t4 3088($v1)
    li $t4 0x593143
    sw $t4 3092($v1)
    li $t4 0x721639
    sw $t4 3096($v1)
    li $t4 0x7b113a
    sw $t4 3100($v1)
    li $t4 0x6f132e
    sw $t4 3104($v1)
    li $t4 0x000300
    sw $t4 3108($v1)
    li $t4 0x20000b
    sw $t4 3588($v1)
    li $t4 0x430013
    sw $t4 3592($v1)
    li $t4 0x660026
    sw $t4 3596($v1)
    li $t4 0x701639
    sw $t4 3600($v1)
    li $t4 0xa4a7a6
    sw $t4 3604($v1)
    li $t4 0xb0acad
    sw $t4 3608($v1)
    li $t4 0x621937
    sw $t4 3612($v1)
    li $t4 0x380914
    sw $t4 3616($v1)
    li $t4 0x000200
    sw $t4 3620($v1)
    li $t4 0x000700
    sw $t4 4104($v1)
    li $t4 0x630729
    sw $t4 4108($v1)
    li $t4 0xbc0c42
    sw $t4 4112($v1)
    li $t4 0xc09ca8
    sw $t4 4116($v1)
    li $t4 0xdbb1bf
    sw $t4 4120($v1)
    li $t4 0x651d30
    sw $t4 4124($v1)
    li $t4 0x17070c
    sw $t4 4620($v1)
    li $t4 0x2e0512
    sw $t4 4624($v1)
    li $t4 0x21000c
    sw $t4 4628($v1)
    li $t4 0x6d4855
    sw $t4 4632($v1)
    li $t4 0x351d24
    sw $t4 4636($v1)
    li $t4 0x020102
    sw $t4 4644($v1)
    li $t4 0x2c2920
    sw $t4 5144($v1)
    li $t4 0x1e1913
    sw $t4 5148($v1)
    li $t4 0x010001
    sw $t4 5644($v1)
    jr $ra
draw_doll_02_08: # start at v1, use t4
    draw16($0, 0, 4, 8, 16, 20, 24, 28, 36, 512, 516, 524, 544, 548, 1024, 1032, 2048)
    draw4($0, 3584, 4096, 4100, 4608)
    draw4($0, 4616, 4640, 5120, 5124)
    draw4($0, 5132, 5140, 5632, 5636)
    sw $0 5640($v1)
    sw $0 5644($v1)
    sw $0 5668($v1)
    li $t4 0x010000
    draw4($t4, 1028, 4612, 5128, 5652)
    li $t4 0x000200
    sw $t4 32($v1)
    sw $t4 3072($v1)
    sw $t4 3620($v1)
    li $t4 0x020101
    sw $t4 520($v1)
    sw $t4 4644($v1)
    sw $t4 5664($v1)
    li $t4 0x010101
    sw $t4 2560($v1)
    sw $t4 5156($v1)
    li $t4 0x000100
    sw $t4 4132($v1)
    sw $t4 5136($v1)
    li $t4 0x020100
    sw $t4 12($v1)
    li $t4 0x26050e
    sw $t4 528($v1)
    li $t4 0x6f2127
    sw $t4 532($v1)
    li $t4 0x843a2a
    sw $t4 536($v1)
    li $t4 0x571e1e
    sw $t4 540($v1)
    li $t4 0x5d1d21
    sw $t4 1036($v1)
    li $t4 0xe1814a
    sw $t4 1040($v1)
    li $t4 0xfdbf54
    sw $t4 1044($v1)
    li $t4 0xf19750
    sw $t4 1048($v1)
    li $t4 0xf6a751
    sw $t4 1052($v1)
    li $t4 0x936134
    sw $t4 1056($v1)
    li $t4 0x080304
    sw $t4 1060($v1)
    li $t4 0x020001
    sw $t4 1536($v1)
    li $t4 0x030404
    sw $t4 1540($v1)
    li $t4 0x38101e
    sw $t4 1544($v1)
    li $t4 0xb52039
    sw $t4 1548($v1)
    li $t4 0xf3b550
    sw $t4 1552($v1)
    li $t4 0xc0894a
    sw $t4 1556($v1)
    li $t4 0xa45044
    sw $t4 1560($v1)
    li $t4 0xc2554b
    sw $t4 1564($v1)
    li $t4 0xc35840
    sw $t4 1568($v1)
    li $t4 0x190209
    sw $t4 1572($v1)
    li $t4 0x0e0e0e
    sw $t4 2052($v1)
    li $t4 0xbdb1b9
    sw $t4 2056($v1)
    li $t4 0xaa4f6c
    sw $t4 2060($v1)
    li $t4 0xae333a
    sw $t4 2064($v1)
    li $t4 0xb86165
    sw $t4 2068($v1)
    li $t4 0xe5a58a
    sw $t4 2072($v1)
    li $t4 0xd26960
    sw $t4 2076($v1)
    li $t4 0x771039
    sw $t4 2080($v1)
    li $t4 0x0a0c0c
    sw $t4 2084($v1)
    li $t4 0x020504
    sw $t4 2564($v1)
    li $t4 0xb6c3bd
    sw $t4 2568($v1)
    li $t4 0xdaeae3
    sw $t4 2572($v1)
    li $t4 0x870e47
    sw $t4 2576($v1)
    li $t4 0x984b60
    sw $t4 2580($v1)
    li $t4 0xa49f7f
    sw $t4 2584($v1)
    li $t4 0xb56a77
    sw $t4 2588($v1)
    li $t4 0x87586c
    sw $t4 2592($v1)
    li $t4 0x1b2622
    sw $t4 2596($v1)
    li $t4 0x23020c
    sw $t4 3076($v1)
    li $t4 0xba6e8d
    sw $t4 3080($v1)
    li $t4 0xaf6d87
    sw $t4 3084($v1)
    li $t4 0x9e3d4b
    sw $t4 3088($v1)
    li $t4 0x908889
    sw $t4 3092($v1)
    li $t4 0x90687f
    sw $t4 3096($v1)
    li $t4 0x874a64
    sw $t4 3100($v1)
    li $t4 0x6a2941
    sw $t4 3104($v1)
    li $t4 0x0b100e
    sw $t4 3108($v1)
    li $t4 0x170009
    sw $t4 3588($v1)
    li $t4 0x760028
    sw $t4 3592($v1)
    li $t4 0x8f0033
    sw $t4 3596($v1)
    li $t4 0x7c1736
    sw $t4 3600($v1)
    li $t4 0x53303d
    sw $t4 3604($v1)
    li $t4 0x8f5b6d
    sw $t4 3608($v1)
    li $t4 0x822247
    sw $t4 3612($v1)
    li $t4 0x6b1229
    sw $t4 3616($v1)
    li $t4 0x100308
    sw $t4 4104($v1)
    li $t4 0x400b20
    sw $t4 4108($v1)
    li $t4 0x8e0030
    sw $t4 4112($v1)
    li $t4 0xaa3e63
    sw $t4 4116($v1)
    li $t4 0xa5818b
    sw $t4 4120($v1)
    li $t4 0xb26d84
    sw $t4 4124($v1)
    li $t4 0x3f2831
    sw $t4 4128($v1)
    li $t4 0x020303
    sw $t4 4620($v1)
    li $t4 0x330a16
    sw $t4 4624($v1)
    li $t4 0x3d2c31
    sw $t4 4628($v1)
    li $t4 0x826a72
    sw $t4 4632($v1)
    li $t4 0x55192e
    sw $t4 4636($v1)
    li $t4 0x51514d
    sw $t4 5144($v1)
    li $t4 0x4c514a
    sw $t4 5148($v1)
    li $t4 0x010100
    sw $t4 5152($v1)
    li $t4 0x030001
    sw $t4 5648($v1)
    li $t4 0x060000
    sw $t4 5656($v1)
    li $t4 0x140803
    sw $t4 5660($v1)
    jr $ra
draw_doll_02_09: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 36, 512, 516, 520, 524, 528, 532, 536, 540, 544, 1024, 1028)
    draw16($0, 1060, 1536, 1540, 2048, 2564, 3076, 4096, 4608, 4612, 5120, 5124, 5156, 5632, 5636, 5640, 5644)
    sw $0 5668($v1)
    li $t4 0x020101
    draw4($t4, 24, 32, 548, 1032)
    li $t4 0x010000
    sw $t4 4644($v1)
    sw $t4 5128($v1)
    sw $t4 5664($v1)
    li $t4 0x030201
    sw $t4 20($v1)
    sw $t4 28($v1)
    li $t4 0x010100
    sw $t4 1036($v1)
    sw $t4 1544($v1)
    li $t4 0x020202
    sw $t4 2560($v1)
    sw $t4 3584($v1)
    li $t4 0x000200
    sw $t4 4616($v1)
    sw $t4 5652($v1)
    li $t4 0x010101
    sw $t4 16($v1)
    li $t4 0x1b060a
    sw $t4 1040($v1)
    li $t4 0x8a3330
    sw $t4 1044($v1)
    li $t4 0xa64735
    sw $t4 1048($v1)
    li $t4 0x9a4c32
    sw $t4 1052($v1)
    li $t4 0x21040d
    sw $t4 1056($v1)
    li $t4 0x020003
    sw $t4 1548($v1)
    li $t4 0xa34c38
    sw $t4 1552($v1)
    li $t4 0xffd856
    sw $t4 1556($v1)
    li $t4 0xe5934d
    sw $t4 1560($v1)
    li $t4 0xeea34f
    sw $t4 1564($v1)
    li $t4 0xd38a48
    sw $t4 1568($v1)
    li $t4 0x351e15
    sw $t4 1572($v1)
    li $t4 0x030101
    sw $t4 2052($v1)
    li $t4 0x020403
    sw $t4 2056($v1)
    li $t4 0x3f0211
    sw $t4 2060($v1)
    li $t4 0xea8b4d
    sw $t4 2064($v1)
    li $t4 0xd29952
    sw $t4 2068($v1)
    li $t4 0x974947
    sw $t4 2072($v1)
    li $t4 0xc05751
    sw $t4 2076($v1)
    li $t4 0xbd4243
    sw $t4 2080($v1)
    li $t4 0x711426
    sw $t4 2084($v1)
    li $t4 0x878d8b
    sw $t4 2568($v1)
    li $t4 0xaf677e
    sw $t4 2572($v1)
    li $t4 0xa92337
    sw $t4 2576($v1)
    li $t4 0xb34a51
    sw $t4 2580($v1)
    li $t4 0xdb9985
    sw $t4 2584($v1)
    li $t4 0xe79978
    sw $t4 2588($v1)
    li $t4 0x910837
    sw $t4 2592($v1)
    li $t4 0x482c3a
    sw $t4 2596($v1)
    li $t4 0x030303
    sw $t4 3072($v1)
    li $t4 0x7f8683
    sw $t4 3080($v1)
    li $t4 0xeafff9
    sw $t4 3084($v1)
    li $t4 0x8e305d
    sw $t4 3088($v1)
    li $t4 0x952a52
    sw $t4 3092($v1)
    li $t4 0x8c8c79
    sw $t4 3096($v1)
    li $t4 0xad8c8a
    sw $t4 3100($v1)
    li $t4 0x9b4d6d
    sw $t4 3104($v1)
    li $t4 0x5c5c5d
    sw $t4 3108($v1)
    li $t4 0x040002
    sw $t4 3588($v1)
    li $t4 0x8f526b
    sw $t4 3592($v1)
    li $t4 0xcea8b7
    sw $t4 3596($v1)
    li $t4 0xa65c65
    sw $t4 3600($v1)
    li $t4 0x864a5b
    sw $t4 3604($v1)
    li $t4 0x75425a
    sw $t4 3608($v1)
    li $t4 0x7c3c59
    sw $t4 3612($v1)
    li $t4 0x853754
    sw $t4 3616($v1)
    li $t4 0x53192c
    sw $t4 3620($v1)
    li $t4 0x110007
    sw $t4 4100($v1)
    li $t4 0x2b000c
    sw $t4 4104($v1)
    li $t4 0x5b001e
    sw $t4 4108($v1)
    li $t4 0x881d3a
    sw $t4 4112($v1)
    li $t4 0x582d3e
    sw $t4 4116($v1)
    li $t4 0x827177
    sw $t4 4120($v1)
    li $t4 0x82445a
    sw $t4 4124($v1)
    li $t4 0x7d0734
    sw $t4 4128($v1)
    li $t4 0x51131f
    sw $t4 4132($v1)
    li $t4 0x010605
    sw $t4 4620($v1)
    li $t4 0x760230
    sw $t4 4624($v1)
    li $t4 0xb60033
    sw $t4 4628($v1)
    li $t4 0xba8b9a
    sw $t4 4632($v1)
    li $t4 0xedfaf6
    sw $t4 4636($v1)
    li $t4 0x706469
    sw $t4 4640($v1)
    li $t4 0x000302
    sw $t4 5132($v1)
    li $t4 0x4e0a21
    sw $t4 5136($v1)
    li $t4 0x790729
    sw $t4 5140($v1)
    li $t4 0x751d39
    sw $t4 5144($v1)
    li $t4 0x865c69
    sw $t4 5148($v1)
    li $t4 0x110c0d
    sw $t4 5152($v1)
    li $t4 0x000100
    sw $t4 5648($v1)
    li $t4 0x0e110a
    sw $t4 5656($v1)
    li $t4 0x1e110a
    sw $t4 5660($v1)
    jr $ra
draw_doll_02_10: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 512, 516, 520, 524, 528, 548)
    draw16($0, 1024, 1028, 1032, 1036, 1044, 1048, 1052, 1056, 1536, 1540, 1544, 1552, 1572, 2048, 2052, 2056)
    draw4($0, 2060, 2560, 2564, 3076)
    draw4($0, 3588, 4100, 4608, 4616)
    draw4($0, 5120, 5124, 5632, 5636)
    sw $0 5668($v1)
    li $t4 0x030101
    sw $t4 532($v1)
    sw $t4 536($v1)
    sw $t4 540($v1)
    li $t4 0x020202
    sw $t4 1548($v1)
    sw $t4 3072($v1)
    sw $t4 3584($v1)
    li $t4 0x010100
    sw $t4 1040($v1)
    sw $t4 1060($v1)
    li $t4 0x020101
    sw $t4 544($v1)
    li $t4 0x421817
    sw $t4 1556($v1)
    li $t4 0x872c2c
    sw $t4 1560($v1)
    li $t4 0x8b322c
    sw $t4 1564($v1)
    li $t4 0x2c0511
    sw $t4 1568($v1)
    li $t4 0x371615
    sw $t4 2064($v1)
    li $t4 0xeb964e
    sw $t4 2068($v1)
    li $t4 0xe85d4a
    sw $t4 2072($v1)
    li $t4 0xe4684a
    sw $t4 2076($v1)
    li $t4 0xdd884a
    sw $t4 2080($v1)
    li $t4 0x2a1710
    sw $t4 2084($v1)
    li $t4 0x0e0d0b
    sw $t4 2568($v1)
    li $t4 0x0d0c0e
    sw $t4 2572($v1)
    li $t4 0x763124
    sw $t4 2576($v1)
    li $t4 0xf5ab57
    sw $t4 2580($v1)
    li $t4 0x8f4637
    sw $t4 2584($v1)
    li $t4 0xa13d3b
    sw $t4 2588($v1)
    li $t4 0xcd704a
    sw $t4 2592($v1)
    li $t4 0x86482a
    sw $t4 2596($v1)
    li $t4 0x282827
    sw $t4 3080($v1)
    li $t4 0xb6b9bd
    sw $t4 3084($v1)
    li $t4 0x9f3b4c
    sw $t4 3088($v1)
    li $t4 0xc44e48
    sw $t4 3092($v1)
    li $t4 0xbd726f
    sw $t4 3096($v1)
    li $t4 0xeba181
    sw $t4 3100($v1)
    li $t4 0xa51d3f
    sw $t4 3104($v1)
    li $t4 0x6c2c40
    sw $t4 3108($v1)
    li $t4 0x141213
    sw $t4 3592($v1)
    li $t4 0xdde8e5
    sw $t4 3596($v1)
    li $t4 0xb48398
    sw $t4 3600($v1)
    li $t4 0x8c0537
    sw $t4 3604($v1)
    li $t4 0x9a8478
    sw $t4 3608($v1)
    li $t4 0xa89680
    sw $t4 3612($v1)
    li $t4 0xa9506f
    sw $t4 3616($v1)
    li $t4 0x8e7582
    sw $t4 3620($v1)
    li $t4 0x010101
    sw $t4 4096($v1)
    li $t4 0x080908
    sw $t4 4104($v1)
    li $t4 0x808180
    sw $t4 4108($v1)
    li $t4 0xb97383
    sw $t4 4112($v1)
    li $t4 0x953d55
    sw $t4 4116($v1)
    li $t4 0x86707d
    sw $t4 4120($v1)
    li $t4 0x7a405d
    sw $t4 4124($v1)
    li $t4 0x905d72
    sw $t4 4128($v1)
    li $t4 0x671b35
    sw $t4 4132($v1)
    li $t4 0x020000
    sw $t4 4612($v1)
    li $t4 0x160000
    sw $t4 4620($v1)
    li $t4 0x94183c
    sw $t4 4624($v1)
    li $t4 0x693140
    sw $t4 4628($v1)
    li $t4 0x644a56
    sw $t4 4632($v1)
    li $t4 0x844258
    sw $t4 4636($v1)
    li $t4 0x6a0026
    sw $t4 4640($v1)
    li $t4 0x790f2b
    sw $t4 4644($v1)
    li $t4 0x020001
    sw $t4 5128($v1)
    li $t4 0x0d0407
    sw $t4 5132($v1)
    li $t4 0x450823
    sw $t4 5136($v1)
    li $t4 0x94002b
    sw $t4 5140($v1)
    li $t4 0xa75d74
    sw $t4 5144($v1)
    li $t4 0xdffaf1
    sw $t4 5148($v1)
    li $t4 0x91878b
    sw $t4 5152($v1)
    li $t4 0x110004
    sw $t4 5156($v1)
    li $t4 0x010000
    sw $t4 5640($v1)
    li $t4 0x000100
    sw $t4 5644($v1)
    li $t4 0x330a19
    sw $t4 5648($v1)
    li $t4 0x970633
    sw $t4 5652($v1)
    li $t4 0xb21b4a
    sw $t4 5656($v1)
    li $t4 0xca6d8c
    sw $t4 5660($v1)
    li $t4 0x5a434a
    sw $t4 5664($v1)
    jr $ra
draw_doll_02_11: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 24, 28, 36, 512, 516, 520, 524, 528, 532, 544, 1024, 1028)
    draw16($0, 1060, 1536, 1540, 1548, 2048, 2052, 2560, 2564, 2568, 2572, 3588, 4100, 4612, 4644, 5120, 5124)
    draw4($0, 5128, 5132, 5632, 5636)
    sw $0 5648($v1)
    sw $0 5668($v1)
    li $t4 0x010101
    sw $t4 3072($v1)
    sw $t4 3076($v1)
    sw $t4 5156($v1)
    li $t4 0x020202
    sw $t4 3584($v1)
    sw $t4 4608($v1)
    sw $t4 5644($v1)
    li $t4 0x020101
    sw $t4 16($v1)
    sw $t4 32($v1)
    li $t4 0x010100
    sw $t4 548($v1)
    sw $t4 1036($v1)
    li $t4 0x030303
    sw $t4 2060($v1)
    sw $t4 4096($v1)
    li $t4 0x000100
    sw $t4 20($v1)
    li $t4 0x150c07
    sw $t4 536($v1)
    li $t4 0x0a0403
    sw $t4 540($v1)
    li $t4 0x020000
    sw $t4 1032($v1)
    li $t4 0x21090c
    sw $t4 1040($v1)
    li $t4 0xb4543d
    sw $t4 1044($v1)
    li $t4 0xce3f41
    sw $t4 1048($v1)
    li $t4 0xc74e41
    sw $t4 1052($v1)
    li $t4 0x50221d
    sw $t4 1056($v1)
    li $t4 0x030301
    sw $t4 1544($v1)
    li $t4 0xa06038
    sw $t4 1552($v1)
    li $t4 0xf8ae51
    sw $t4 1556($v1)
    li $t4 0xd77e46
    sw $t4 1560($v1)
    li $t4 0xd27747
    sw $t4 1564($v1)
    li $t4 0xd88d48
    sw $t4 1568($v1)
    li $t4 0x150808
    sw $t4 1572($v1)
    li $t4 0x020401
    sw $t4 2056($v1)
    li $t4 0xa95439
    sw $t4 2064($v1)
    li $t4 0xcf7250
    sw $t4 2068($v1)
    li $t4 0x994540
    sw $t4 2072($v1)
    li $t4 0xc06352
    sw $t4 2076($v1)
    li $t4 0xa42b3e
    sw $t4 2080($v1)
    li $t4 0x25080d
    sw $t4 2084($v1)
    li $t4 0x821535
    sw $t4 2576($v1)
    li $t4 0xb64451
    sw $t4 2580($v1)
    li $t4 0xca867a
    sw $t4 2584($v1)
    li $t4 0xe2937d
    sw $t4 2588($v1)
    li $t4 0x840235
    sw $t4 2592($v1)
    li $t4 0x0c0408
    sw $t4 2596($v1)
    li $t4 0x0f0f0f
    sw $t4 3080($v1)
    li $t4 0x707674
    sw $t4 3084($v1)
    li $t4 0x8a2b55
    sw $t4 3088($v1)
    li $t4 0x996076
    sw $t4 3092($v1)
    li $t4 0x88867c
    sw $t4 3096($v1)
    li $t4 0x968187
    sw $t4 3100($v1)
    li $t4 0x9b4468
    sw $t4 3104($v1)
    li $t4 0x53494e
    sw $t4 3108($v1)
    li $t4 0x838886
    sw $t4 3592($v1)
    li $t4 0xe2cfd7
    sw $t4 3596($v1)
    li $t4 0xaa4a5c
    sw $t4 3600($v1)
    li $t4 0x815762
    sw $t4 3604($v1)
    li $t4 0x965973
    sw $t4 3608($v1)
    li $t4 0x702543
    sw $t4 3612($v1)
    li $t4 0x81133c
    sw $t4 3616($v1)
    li $t4 0x641c30
    sw $t4 3620($v1)
    li $t4 0x666a68
    sw $t4 4104($v1)
    li $t4 0xcfc0c6
    sw $t4 4108($v1)
    li $t4 0x7d1b33
    sw $t4 4112($v1)
    li $t4 0x741e3d
    sw $t4 4116($v1)
    li $t4 0x836571
    sw $t4 4120($v1)
    li $t4 0xa17f8b
    sw $t4 4124($v1)
    li $t4 0x802548
    sw $t4 4128($v1)
    li $t4 0x2e0c0f
    sw $t4 4132($v1)
    li $t4 0x292728
    sw $t4 4616($v1)
    li $t4 0x2e3130
    sw $t4 4620($v1)
    li $t4 0x290012
    sw $t4 4624($v1)
    li $t4 0xa70031
    sw $t4 4628($v1)
    li $t4 0xa24a67
    sw $t4 4632($v1)
    li $t4 0xf1fffd
    sw $t4 4636($v1)
    li $t4 0x866f76
    sw $t4 4640($v1)
    li $t4 0x11060b
    sw $t4 5136($v1)
    li $t4 0x610725
    sw $t4 5140($v1)
    li $t4 0x960a36
    sw $t4 5144($v1)
    li $t4 0xa54867
    sw $t4 5148($v1)
    li $t4 0x3e0c1b
    sw $t4 5152($v1)
    li $t4 0x010202
    sw $t4 5640($v1)
    li $t4 0x000200
    sw $t4 5652($v1)
    li $t4 0x0c0a08
    sw $t4 5656($v1)
    li $t4 0x3b2721
    sw $t4 5660($v1)
    li $t4 0x020501
    sw $t4 5664($v1)
    jr $ra
draw_doll_02_12: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 512, 516, 520, 528, 1024, 1028)
    draw16($0, 1036, 1536, 1540, 2048, 2052, 2060, 2084, 2560, 2564, 4096, 4608, 4612, 4616, 4620, 5120, 5124)
    draw4($0, 5632, 5636, 5640, 5644)
    sw $0 5648($v1)
    sw $0 5652($v1)
    sw $0 5668($v1)
    li $t4 0x010100
    sw $t4 524($v1)
    sw $t4 5664($v1)
    li $t4 0x000100
    sw $t4 548($v1)
    sw $t4 4644($v1)
    li $t4 0x010101
    sw $t4 3072($v1)
    sw $t4 3584($v1)
    li $t4 0x080808
    sw $t4 3076($v1)
    sw $t4 4100($v1)
    li $t4 0x54201d
    sw $t4 532($v1)
    li $t4 0x7f2929
    sw $t4 536($v1)
    li $t4 0x6f2624
    sw $t4 540($v1)
    li $t4 0x0e0006
    sw $t4 544($v1)
    li $t4 0x030201
    sw $t4 1032($v1)
    li $t4 0x682f24
    sw $t4 1040($v1)
    li $t4 0xf78f52
    sw $t4 1044($v1)
    li $t4 0xe9614b
    sw $t4 1048($v1)
    li $t4 0xea764e
    sw $t4 1052($v1)
    li $t4 0xb36e3d
    sw $t4 1056($v1)
    li $t4 0x090104
    sw $t4 1060($v1)
    li $t4 0x020401
    sw $t4 1544($v1)
    li $t4 0x020202
    sw $t4 1548($v1)
    li $t4 0xb25f3c
    sw $t4 1552($v1)
    li $t4 0xdd954c
    sw $t4 1556($v1)
    li $t4 0xa85d37
    sw $t4 1560($v1)
    li $t4 0xbb7042
    sw $t4 1564($v1)
    li $t4 0xca7f46
    sw $t4 1568($v1)
    li $t4 0x18030a
    sw $t4 1572($v1)
    li $t4 0x030101
    sw $t4 2056($v1)
    li $t4 0x702825
    sw $t4 2064($v1)
    li $t4 0xcb5b54
    sw $t4 2068($v1)
    li $t4 0xb45e65
    sw $t4 2072($v1)
    li $t4 0xe1866f
    sw $t4 2076($v1)
    li $t4 0x80112d
    sw $t4 2080($v1)
    li $t4 0x030001
    sw $t4 2568($v1)
    li $t4 0x202121
    sw $t4 2572($v1)
    li $t4 0x5c0e25
    sw $t4 2576($v1)
    li $t4 0xac556a
    sw $t4 2580($v1)
    li $t4 0xa38975
    sw $t4 2584($v1)
    li $t4 0xb1817b
    sw $t4 2588($v1)
    li $t4 0x8a1c49
    sw $t4 2592($v1)
    li $t4 0x292527
    sw $t4 2596($v1)
    li $t4 0xa2a3a3
    sw $t4 3080($v1)
    li $t4 0xd5d6d6
    sw $t4 3084($v1)
    li $t4 0x93415d
    sw $t4 3088($v1)
    li $t4 0x9c7280
    sw $t4 3092($v1)
    li $t4 0x825f73
    sw $t4 3096($v1)
    li $t4 0x6e4157
    sw $t4 3100($v1)
    li $t4 0x933a59
    sw $t4 3104($v1)
    li $t4 0x634550
    sw $t4 3108($v1)
    li $t4 0x0d0c0d
    sw $t4 3588($v1)
    li $t4 0xcfd0cf
    sw $t4 3592($v1)
    li $t4 0xd4d5d5
    sw $t4 3596($v1)
    li $t4 0xaf5f65
    sw $t4 3600($v1)
    li $t4 0x71384b
    sw $t4 3604($v1)
    li $t4 0x833f57
    sw $t4 3608($v1)
    li $t4 0x710f32
    sw $t4 3612($v1)
    li $t4 0x962c43
    sw $t4 3616($v1)
    li $t4 0x270c16
    sw $t4 3620($v1)
    li $t4 0x7d7c7c
    sw $t4 4104($v1)
    li $t4 0x3a3b3b
    sw $t4 4108($v1)
    li $t4 0x380014
    sw $t4 4112($v1)
    li $t4 0x8f002f
    sw $t4 4116($v1)
    li $t4 0xb1a1a5
    sw $t4 4120($v1)
    li $t4 0xcad4d0
    sw $t4 4124($v1)
    li $t4 0x540626
    sw $t4 4128($v1)
    li $t4 0x040000
    sw $t4 4132($v1)
    li $t4 0x260c17
    sw $t4 4624($v1)
    li $t4 0xbb0235
    sw $t4 4628($v1)
    li $t4 0xc06380
    sw $t4 4632($v1)
    li $t4 0xbfb4ba
    sw $t4 4636($v1)
    li $t4 0x1d030b
    sw $t4 4640($v1)
    li $t4 0x030303
    sw $t4 5128($v1)
    li $t4 0x030202
    sw $t4 5132($v1)
    li $t4 0x050203
    sw $t4 5136($v1)
    li $t4 0x1b050c
    sw $t4 5140($v1)
    li $t4 0x4e1625
    sw $t4 5144($v1)
    li $t4 0x442b2f
    sw $t4 5148($v1)
    li $t4 0x050001
    sw $t4 5152($v1)
    li $t4 0x010001
    sw $t4 5156($v1)
    li $t4 0x030802
    sw $t4 5656($v1)
    li $t4 0x120c05
    sw $t4 5660($v1)
    jr $ra
draw_doll_02_13: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 20, 28, 32, 512, 516, 1024, 1028, 1036, 1536, 1540, 2048)
    draw16($0, 2052, 2056, 3584, 4096, 4100, 4104, 4108, 4608, 4612, 5120, 5124, 5128, 5132, 5632, 5636, 5640)
    sw $0 5644($v1)
    sw $0 5652($v1)
    sw $0 5668($v1)
    li $t4 0x010000
    draw4($t4, 36, 520, 4132, 5156)
    sw $t4 5648($v1)
    li $t4 0x000100
    draw4($t4, 548, 4644, 5136, 5152)
    li $t4 0x010101
    sw $t4 2560($v1)
    sw $t4 3072($v1)
    li $t4 0x010501
    sw $t4 24($v1)
    li $t4 0x010100
    sw $t4 524($v1)
    li $t4 0x120306
    sw $t4 528($v1)
    li $t4 0x8f3d31
    sw $t4 532($v1)
    li $t4 0xb23439
    sw $t4 536($v1)
    li $t4 0xa53936
    sw $t4 540($v1)
    li $t4 0x310b13
    sw $t4 544($v1)
    li $t4 0x030301
    sw $t4 1032($v1)
    li $t4 0x89482f
    sw $t4 1040($v1)
    li $t4 0xfda452
    sw $t4 1044($v1)
    li $t4 0xe27849
    sw $t4 1048($v1)
    li $t4 0xef994e
    sw $t4 1052($v1)
    li $t4 0xd99e49
    sw $t4 1056($v1)
    li $t4 0x0d0205
    sw $t4 1060($v1)
    li $t4 0x030401
    sw $t4 1544($v1)
    li $t4 0x040303
    sw $t4 1548($v1)
    li $t4 0xaf623b
    sw $t4 1552($v1)
    li $t4 0xd98c4e
    sw $t4 1556($v1)
    li $t4 0x9d5239
    sw $t4 1560($v1)
    li $t4 0xc67f49
    sw $t4 1564($v1)
    li $t4 0xca7b48
    sw $t4 1568($v1)
    li $t4 0x260410
    sw $t4 1572($v1)
    li $t4 0x050000
    sw $t4 2060($v1)
    li $t4 0xb6373c
    sw $t4 2064($v1)
    li $t4 0xb94c4f
    sw $t4 2068($v1)
    li $t4 0xc77777
    sw $t4 2072($v1)
    li $t4 0xdb8b76
    sw $t4 2076($v1)
    li $t4 0x9a013a
    sw $t4 2080($v1)
    li $t4 0x400018
    sw $t4 2084($v1)
    li $t4 0x060505
    sw $t4 2564($v1)
    li $t4 0x9a9d9c
    sw $t4 2568($v1)
    li $t4 0x90848a
    sw $t4 2572($v1)
    li $t4 0x820630
    sw $t4 2576($v1)
    li $t4 0xa46a7b
    sw $t4 2580($v1)
    li $t4 0x897d70
    sw $t4 2584($v1)
    li $t4 0x8d7574
    sw $t4 2588($v1)
    li $t4 0x9a2053
    sw $t4 2592($v1)
    li $t4 0x582a3d
    sw $t4 2596($v1)
    li $t4 0x0c0c0c
    sw $t4 3076($v1)
    li $t4 0xd2d2d2
    sw $t4 3080($v1)
    li $t4 0xf7f8f8
    sw $t4 3084($v1)
    li $t4 0xa5596a
    sw $t4 3088($v1)
    li $t4 0x956874
    sw $t4 3092($v1)
    li $t4 0x854965
    sw $t4 3096($v1)
    li $t4 0x6a203e
    sw $t4 3100($v1)
    li $t4 0x913750
    sw $t4 3104($v1)
    li $t4 0x533540
    sw $t4 3108($v1)
    li $t4 0x090909
    sw $t4 3588($v1)
    li $t4 0x969696
    sw $t4 3592($v1)
    li $t4 0xa1a3a2
    sw $t4 3596($v1)
    li $t4 0x923f4d
    sw $t4 3600($v1)
    li $t4 0x692e45
    sw $t4 3604($v1)
    li $t4 0x886470
    sw $t4 3608($v1)
    li $t4 0x833551
    sw $t4 3612($v1)
    li $t4 0x8e1f3e
    sw $t4 3616($v1)
    li $t4 0x19040b
    sw $t4 3620($v1)
    li $t4 0x3e0018
    sw $t4 4112($v1)
    li $t4 0xa80337
    sw $t4 4116($v1)
    li $t4 0xc0bfbe
    sw $t4 4120($v1)
    li $t4 0xe1e8e6
    sw $t4 4124($v1)
    li $t4 0x4c0924
    sw $t4 4128($v1)
    li $t4 0x030202
    sw $t4 4616($v1)
    li $t4 0x020402
    sw $t4 4620($v1)
    li $t4 0x430b1f
    sw $t4 4624($v1)
    li $t4 0xad0534
    sw $t4 4628($v1)
    li $t4 0xb42753
    sw $t4 4632($v1)
    li $t4 0x9a4b66
    sw $t4 4636($v1)
    li $t4 0x20060d
    sw $t4 4640($v1)
    li $t4 0x000302
    sw $t4 5140($v1)
    li $t4 0x2f1418
    sw $t4 5144($v1)
    li $t4 0x382020
    sw $t4 5148($v1)
    li $t4 0x000200
    sw $t4 5656($v1)
    li $t4 0x050300
    sw $t4 5660($v1)
    li $t4 0x020101
    sw $t4 5664($v1)
    jr $ra
draw_doll_02_14: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 24, 28, 36, 512, 516, 520, 528, 532, 544, 1024, 1028, 1060)
    draw16($0, 1536, 1544, 2048, 3584, 3588, 3592, 4096, 4608, 4612, 4616, 5120, 5124, 5632, 5636, 5640, 5644)
    sw $0 5668($v1)
    li $t4 0x010101
    draw4($t4, 1540, 2560, 3072, 4100)
    sw $t4 4104($v1)
    li $t4 0x000100
    draw4($t4, 20, 5156, 5648, 5664)
    li $t4 0x010000
    sw $t4 524($v1)
    sw $t4 4644($v1)
    sw $t4 5128($v1)
    li $t4 0x020101
    sw $t4 16($v1)
    sw $t4 32($v1)
    li $t4 0x130907
    sw $t4 536($v1)
    li $t4 0x080003
    sw $t4 540($v1)
    li $t4 0x010100
    sw $t4 548($v1)
    li $t4 0x040202
    sw $t4 1032($v1)
    li $t4 0x000301
    sw $t4 1036($v1)
    li $t4 0x21070c
    sw $t4 1040($v1)
    li $t4 0xb45c3e
    sw $t4 1044($v1)
    li $t4 0xd34c42
    sw $t4 1048($v1)
    li $t4 0xce6942
    sw $t4 1052($v1)
    li $t4 0x4f201d
    sw $t4 1056($v1)
    li $t4 0x070000
    sw $t4 1548($v1)
    li $t4 0xcf7f45
    sw $t4 1552($v1)
    li $t4 0xf4b050
    sw $t4 1556($v1)
    li $t4 0xce6348
    sw $t4 1560($v1)
    li $t4 0xd17f4a
    sw $t4 1564($v1)
    li $t4 0xd89449
    sw $t4 1568($v1)
    li $t4 0x17080a
    sw $t4 1572($v1)
    li $t4 0x0b0909
    sw $t4 2052($v1)
    li $t4 0x909796
    sw $t4 2056($v1)
    li $t4 0x8b4c5a
    sw $t4 2060($v1)
    li $t4 0xdf7540
    sw $t4 2064($v1)
    li $t4 0xb95c4b
    sw $t4 2068($v1)
    li $t4 0xa2514e
    sw $t4 2072($v1)
    li $t4 0xc5645a
    sw $t4 2076($v1)
    li $t4 0xa2273b
    sw $t4 2080($v1)
    li $t4 0x200207
    sw $t4 2084($v1)
    li $t4 0x0c0b0c
    sw $t4 2564($v1)
    li $t4 0xd2d5d4
    sw $t4 2568($v1)
    li $t4 0xd0c4c9
    sw $t4 2572($v1)
    li $t4 0x8e0138
    sw $t4 2576($v1)
    li $t4 0xb14852
    sw $t4 2580($v1)
    li $t4 0xd0967d
    sw $t4 2584($v1)
    li $t4 0xdd957c
    sw $t4 2588($v1)
    li $t4 0x971145
    sw $t4 2592($v1)
    li $t4 0x5c4c54
    sw $t4 2596($v1)
    li $t4 0x060505
    sw $t4 3076($v1)
    li $t4 0x9a9b9a
    sw $t4 3080($v1)
    li $t4 0xccc3c8
    sw $t4 3084($v1)
    li $t4 0x88244b
    sw $t4 3088($v1)
    li $t4 0x99657a
    sw $t4 3092($v1)
    li $t4 0x8f837e
    sw $t4 3096($v1)
    li $t4 0x997b84
    sw $t4 3100($v1)
    li $t4 0x9c5775
    sw $t4 3104($v1)
    li $t4 0x503f45
    sw $t4 3108($v1)
    li $t4 0x8a3c52
    sw $t4 3596($v1)
    li $t4 0xa64a63
    sw $t4 3600($v1)
    li $t4 0x562337
    sw $t4 3604($v1)
    li $t4 0x753f53
    sw $t4 3608($v1)
    li $t4 0x700834
    sw $t4 3612($v1)
    li $t4 0x80223f
    sw $t4 3616($v1)
    li $t4 0x432325
    sw $t4 3620($v1)
    li $t4 0x2d0e12
    sw $t4 4108($v1)
    li $t4 0x7e0f33
    sw $t4 4112($v1)
    li $t4 0x74485a
    sw $t4 4116($v1)
    li $t4 0xa1bcb2
    sw $t4 4120($v1)
    li $t4 0x848285
    sw $t4 4124($v1)
    li $t4 0x5e0c28
    sw $t4 4128($v1)
    li $t4 0x2c1013
    sw $t4 4132($v1)
    li $t4 0x010304
    sw $t4 4620($v1)
    li $t4 0x73002a
    sw $t4 4624($v1)
    li $t4 0xa7355c
    sw $t4 4628($v1)
    li $t4 0xd36788
    sw $t4 4632($v1)
    li $t4 0xd8577e
    sw $t4 4636($v1)
    li $t4 0x540b25
    sw $t4 4640($v1)
    li $t4 0x010201
    sw $t4 5132($v1)
    li $t4 0x3d091d
    sw $t4 5136($v1)
    li $t4 0x790026
    sw $t4 5140($v1)
    li $t4 0xa90028
    sw $t4 5144($v1)
    li $t4 0x990027
    sw $t4 5148($v1)
    li $t4 0x310714
    sw $t4 5152($v1)
    li $t4 0x000500
    sw $t4 5652($v1)
    li $t4 0x0b0c05
    sw $t4 5656($v1)
    li $t4 0x050c03
    sw $t4 5660($v1)
    jr $ra
draw_doll_02_15: # start at v1, use t4
    draw16($0, 0, 4, 12, 32, 512, 548, 1024, 1536, 1544, 1572, 2048, 2052, 2560, 3072, 3584, 4096)
    draw16($0, 4100, 4104, 4608, 5120, 5124, 5128, 5132, 5136, 5152, 5156, 5632, 5636, 5640, 5644, 5648, 5656)
    sw $0 5660($v1)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x010000
    draw4($t4, 516, 4640, 4644, 5652)
    li $t4 0x020202
    sw $t4 1032($v1)
    sw $t4 4132($v1)
    sw $t4 4612($v1)
    li $t4 0x010001
    sw $t4 36($v1)
    sw $t4 4620($v1)
    li $t4 0x000100
    sw $t4 4128($v1)
    sw $t4 5140($v1)
    li $t4 0x020100
    sw $t4 8($v1)
    li $t4 0x3e1916
    sw $t4 16($v1)
    li $t4 0x9a3333
    sw $t4 20($v1)
    li $t4 0xa63934
    sw $t4 24($v1)
    li $t4 0x53151e
    sw $t4 28($v1)
    li $t4 0x010100
    sw $t4 520($v1)
    li $t4 0x20050c
    sw $t4 524($v1)
    li $t4 0xdb8549
    sw $t4 528($v1)
    li $t4 0xec754c
    sw $t4 532($v1)
    li $t4 0xda6449
    sw $t4 536($v1)
    li $t4 0xeb934f
    sw $t4 540($v1)
    li $t4 0x512b1d
    sw $t4 544($v1)
    li $t4 0x030101
    sw $t4 1028($v1)
    li $t4 0x4a151b
    sw $t4 1036($v1)
    li $t4 0xf09d52
    sw $t4 1040($v1)
    li $t4 0xac623d
    sw $t4 1044($v1)
    li $t4 0xa95d3b
    sw $t4 1048($v1)
    li $t4 0xd6834e
    sw $t4 1052($v1)
    li $t4 0x653223
    sw $t4 1056($v1)
    li $t4 0x000001
    sw $t4 1060($v1)
    li $t4 0x020000
    sw $t4 1540($v1)
    li $t4 0x130002
    sw $t4 1548($v1)
    li $t4 0xc04a47
    sw $t4 1552($v1)
    li $t4 0xb5565f
    sw $t4 1556($v1)
    li $t4 0xd98f7b
    sw $t4 1560($v1)
    li $t4 0xbf4250
    sw $t4 1564($v1)
    li $t4 0x220008
    sw $t4 1568($v1)
    li $t4 0x292c2a
    sw $t4 2056($v1)
    li $t4 0x3b222a
    sw $t4 2060($v1)
    li $t4 0x93264a
    sw $t4 2064($v1)
    li $t4 0x9f7f7a
    sw $t4 2068($v1)
    li $t4 0x9e917b
    sw $t4 2072($v1)
    li $t4 0xa7496b
    sw $t4 2076($v1)
    li $t4 0x5e283e
    sw $t4 2080($v1)
    li $t4 0x0a110e
    sw $t4 2084($v1)
    li $t4 0x5d5c5c
    sw $t4 2564($v1)
    li $t4 0xe2e8e6
    sw $t4 2568($v1)
    li $t4 0xbc949f
    sw $t4 2572($v1)
    li $t4 0x8f3d55
    sw $t4 2576($v1)
    li $t4 0x8a7882
    sw $t4 2580($v1)
    li $t4 0x733150
    sw $t4 2584($v1)
    li $t4 0x8a4d5f
    sw $t4 2588($v1)
    li $t4 0x863853
    sw $t4 2592($v1)
    li $t4 0x141d1a
    sw $t4 2596($v1)
    li $t4 0x717070
    sw $t4 3076($v1)
    li $t4 0xebf0f0
    sw $t4 3080($v1)
    li $t4 0xac8385
    sw $t4 3084($v1)
    li $t4 0x893143
    sw $t4 3088($v1)
    li $t4 0x734859
    sw $t4 3092($v1)
    li $t4 0x7e304a
    sw $t4 3096($v1)
    li $t4 0x89243f
    sw $t4 3100($v1)
    li $t4 0x611a2b
    sw $t4 3104($v1)
    li $t4 0x000101
    sw $t4 3108($v1)
    li $t4 0x3e3e3e
    sw $t4 3588($v1)
    li $t4 0x535655
    sw $t4 3592($v1)
    li $t4 0x0c0107
    sw $t4 3596($v1)
    li $t4 0x770025
    sw $t4 3600($v1)
    li $t4 0xa4395c
    sw $t4 3604($v1)
    li $t4 0xdbfff4
    sw $t4 3608($v1)
    li $t4 0x905c72
    sw $t4 3612($v1)
    li $t4 0x160003
    sw $t4 3616($v1)
    li $t4 0x010301
    sw $t4 3620($v1)
    li $t4 0x000502
    sw $t4 4108($v1)
    li $t4 0x7a062d
    sw $t4 4112($v1)
    li $t4 0xbe0e44
    sw $t4 4116($v1)
    li $t4 0xbda8b1
    sw $t4 4120($v1)
    li $t4 0x613f4b
    sw $t4 4124($v1)
    li $t4 0x030303
    sw $t4 4616($v1)
    li $t4 0x040404
    sw $t4 4624($v1)
    li $t4 0x21030c
    sw $t4 4628($v1)
    li $t4 0x522b31
    sw $t4 4632($v1)
    li $t4 0x120c0a
    sw $t4 4636($v1)
    li $t4 0x090802
    sw $t4 5144($v1)
    li $t4 0x070401
    sw $t4 5148($v1)
    jr $ra
draw_doll_02_16: # start at v1, use t4
    draw16($0, 0, 32, 512, 548, 1024, 1032, 1060, 2052, 2080, 2564, 3072, 3076, 3584, 3616, 4096, 4104)
    draw16($0, 4132, 4608, 4612, 4616, 4640, 5120, 5124, 5128, 5140, 5144, 5152, 5156, 5632, 5636, 5640, 5644)
    draw4($0, 5648, 5660, 5664, 5668)
    li $t4 0x010000
    draw4($t4, 4, 1536, 4100, 4644)
    sw $t4 5132($v1)
    sw $t4 5136($v1)
    li $t4 0x000101
    sw $t4 520($v1)
    sw $t4 5652($v1)
    sw $t4 5656($v1)
    li $t4 0x010101
    sw $t4 36($v1)
    sw $t4 3592($v1)
    li $t4 0x030201
    sw $t4 516($v1)
    sw $t4 3108($v1)
    li $t4 0x000200
    sw $t4 1540($v1)
    sw $t4 4624($v1)
    li $t4 0x010100
    sw $t4 8($v1)
    li $t4 0x0e0005
    sw $t4 12($v1)
    li $t4 0xae7a3b
    sw $t4 16($v1)
    li $t4 0xe8974c
    sw $t4 20($v1)
    li $t4 0xbf2841
    sw $t4 24($v1)
    li $t4 0x642624
    sw $t4 28($v1)
    li $t4 0x692b25
    sw $t4 524($v1)
    li $t4 0xffff5a
    sw $t4 528($v1)
    li $t4 0xf7ea51
    sw $t4 532($v1)
    li $t4 0xdf8949
    sw $t4 536($v1)
    li $t4 0xe99f4e
    sw $t4 540($v1)
    li $t4 0x2d1710
    sw $t4 544($v1)
    li $t4 0x040301
    sw $t4 1028($v1)
    li $t4 0x935e32
    sw $t4 1036($v1)
    li $t4 0xfee158
    sw $t4 1040($v1)
    li $t4 0xe0b44e
    sw $t4 1044($v1)
    li $t4 0xb75849
    sw $t4 1048($v1)
    li $t4 0xc33f4a
    sw $t4 1052($v1)
    li $t4 0x3c1416
    sw $t4 1056($v1)
    li $t4 0x0d0b0e
    sw $t4 1544($v1)
    li $t4 0xc37846
    sw $t4 1548($v1)
    li $t4 0xe17749
    sw $t4 1552($v1)
    li $t4 0xd29344
    sw $t4 1556($v1)
    li $t4 0xd67969
    sw $t4 1560($v1)
    li $t4 0x8a2c3f
    sw $t4 1564($v1)
    li $t4 0x070002
    sw $t4 1568($v1)
    li $t4 0x020201
    sw $t4 1572($v1)
    li $t4 0x030303
    sw $t4 2048($v1)
    li $t4 0x4e484f
    sw $t4 2056($v1)
    li $t4 0xcc5b60
    sw $t4 2060($v1)
    li $t4 0xcc6238
    sw $t4 2064($v1)
    li $t4 0xc28f65
    sw $t4 2068($v1)
    li $t4 0xad91a3
    sw $t4 2072($v1)
    li $t4 0x6d6567
    sw $t4 2076($v1)
    li $t4 0x030203
    sw $t4 2084($v1)
    li $t4 0x020001
    sw $t4 2560($v1)
    li $t4 0x220d14
    sw $t4 2568($v1)
    li $t4 0xa22143
    sw $t4 2572($v1)
    li $t4 0xb63435
    sw $t4 2576($v1)
    li $t4 0xab9895
    sw $t4 2580($v1)
    li $t4 0x988d95
    sw $t4 2584($v1)
    li $t4 0x8d2e4f
    sw $t4 2588($v1)
    li $t4 0x531522
    sw $t4 2592($v1)
    li $t4 0x010201
    sw $t4 2596($v1)
    li $t4 0x0b0003
    sw $t4 3080($v1)
    li $t4 0x73002f
    sw $t4 3084($v1)
    li $t4 0xa41a3a
    sw $t4 3088($v1)
    li $t4 0x904554
    sw $t4 3092($v1)
    li $t4 0x7a3653
    sw $t4 3096($v1)
    li $t4 0x56112b
    sw $t4 3100($v1)
    li $t4 0x341716
    sw $t4 3104($v1)
    li $t4 0x010001
    sw $t4 3588($v1)
    li $t4 0x3b071b
    sw $t4 3596($v1)
    li $t4 0x97033b
    sw $t4 3600($v1)
    li $t4 0xa90028
    sw $t4 3604($v1)
    li $t4 0xb74066
    sw $t4 3608($v1)
    li $t4 0x4d494a
    sw $t4 3612($v1)
    li $t4 0x030202
    sw $t4 3620($v1)
    li $t4 0x1f0b12
    sw $t4 4108($v1)
    li $t4 0x3c101e
    sw $t4 4112($v1)
    li $t4 0x6e3346
    sw $t4 4116($v1)
    li $t4 0x663c4b
    sw $t4 4120($v1)
    li $t4 0x2c0714
    sw $t4 4124($v1)
    li $t4 0x020101
    sw $t4 4128($v1)
    li $t4 0x000100
    sw $t4 4620($v1)
    li $t4 0x161d16
    sw $t4 4628($v1)
    li $t4 0x3c362c
    sw $t4 4632($v1)
    li $t4 0x010400
    sw $t4 4636($v1)
    li $t4 0x030101
    sw $t4 5148($v1)
    jr $ra
draw_doll_02_17: # start at v1, use t4
    draw16($0, 0, 8, 516, 544, 1028, 1536, 2048, 2056, 2084, 3584, 3592, 4096, 4608, 4612, 4620, 4636)
    draw16($0, 4644, 5120, 5124, 5128, 5140, 5144, 5152, 5156, 5632, 5636, 5640, 5644, 5648, 5660, 5664, 5668)
    li $t4 0x010000
    draw4($t4, 36, 2560, 3072, 3076)
    draw4($t4, 3104, 3108, 4100, 4132)
    sw $t4 4616($v1)
    sw $t4 5132($v1)
    sw $t4 5148($v1)
    li $t4 0x010101
    draw4($t4, 4, 512, 1540, 2564)
    li $t4 0x010100
    sw $t4 32($v1)
    sw $t4 2596($v1)
    li $t4 0x020101
    sw $t4 1024($v1)
    sw $t4 4104($v1)
    li $t4 0x020001
    sw $t4 3588($v1)
    sw $t4 3620($v1)
    li $t4 0x000100
    sw $t4 3616($v1)
    sw $t4 4128($v1)
    li $t4 0x000101
    sw $t4 5652($v1)
    sw $t4 5656($v1)
    li $t4 0x55221f
    sw $t4 12($v1)
    li $t4 0xba243f
    sw $t4 16($v1)
    li $t4 0xe4894b
    sw $t4 20($v1)
    li $t4 0xbd8b40
    sw $t4 24($v1)
    li $t4 0x170209
    sw $t4 28($v1)
    li $t4 0x1b0b0a
    sw $t4 520($v1)
    li $t4 0xdd974a
    sw $t4 524($v1)
    li $t4 0xe28c4a
    sw $t4 528($v1)
    li $t4 0xf3dd51
    sw $t4 532($v1)
    li $t4 0xffff5b
    sw $t4 536($v1)
    li $t4 0x84432e
    sw $t4 540($v1)
    li $t4 0x040301
    sw $t4 548($v1)
    li $t4 0x2a0e0f
    sw $t4 1032($v1)
    li $t4 0xc03f48
    sw $t4 1036($v1)
    li $t4 0xb24645
    sw $t4 1040($v1)
    li $t4 0xdb9742
    sw $t4 1044($v1)
    li $t4 0xfbf352
    sw $t4 1048($v1)
    li $t4 0xce8443
    sw $t4 1052($v1)
    li $t4 0x040000
    sw $t4 1056($v1)
    li $t4 0x010300
    sw $t4 1060($v1)
    li $t4 0x040002
    sw $t4 1544($v1)
    li $t4 0x762036
    sw $t4 1548($v1)
    li $t4 0xd36b5f
    sw $t4 1552($v1)
    li $t4 0xc89d71
    sw $t4 1556($v1)
    li $t4 0xe2b95f
    sw $t4 1560($v1)
    li $t4 0xce604b
    sw $t4 1564($v1)
    li $t4 0x170e15
    sw $t4 1568($v1)
    li $t4 0x000200
    sw $t4 1572($v1)
    li $t4 0x030203
    sw $t4 2052($v1)
    li $t4 0x56525d
    sw $t4 2060($v1)
    li $t4 0xd0897c
    sw $t4 2064($v1)
    li $t4 0xcad0a7
    sw $t4 2068($v1)
    li $t4 0xb46b70
    sw $t4 2072($v1)
    li $t4 0xd27463
    sw $t4 2076($v1)
    li $t4 0x292d34
    sw $t4 2080($v1)
    li $t4 0x4b131e
    sw $t4 2568($v1)
    li $t4 0x7c314f
    sw $t4 2572($v1)
    li $t4 0xb06459
    sw $t4 2576($v1)
    li $t4 0x9a5354
    sw $t4 2580($v1)
    li $t4 0xbd464b
    sw $t4 2584($v1)
    li $t4 0x942d37
    sw $t4 2588($v1)
    li $t4 0x000001
    sw $t4 2592($v1)
    li $t4 0x311515
    sw $t4 3080($v1)
    li $t4 0x2d0511
    sw $t4 3084($v1)
    li $t4 0x5d0c2c
    sw $t4 3088($v1)
    li $t4 0x880032
    sw $t4 3092($v1)
    li $t4 0x7d1a32
    sw $t4 3096($v1)
    li $t4 0x320619
    sw $t4 3100($v1)
    li $t4 0x271019
    sw $t4 3596($v1)
    li $t4 0xc10642
    sw $t4 3600($v1)
    li $t4 0xae0034
    sw $t4 3604($v1)
    li $t4 0x820032
    sw $t4 3608($v1)
    li $t4 0x320a19
    sw $t4 3612($v1)
    li $t4 0x1f050e
    sw $t4 4108($v1)
    li $t4 0x630b25
    sw $t4 4112($v1)
    li $t4 0x7b3a4f
    sw $t4 4116($v1)
    li $t4 0x4c2935
    sw $t4 4120($v1)
    li $t4 0x210510
    sw $t4 4124($v1)
    li $t4 0x000700
    sw $t4 4624($v1)
    li $t4 0x3b3a2f
    sw $t4 4628($v1)
    li $t4 0x141712
    sw $t4 4632($v1)
    li $t4 0x010001
    sw $t4 4640($v1)
    li $t4 0x040001
    sw $t4 5136($v1)
    jr $ra
draw_doll_02_18: # start at v1, use t4
    draw16($0, 0, 8, 28, 36, 516, 1056, 2084, 2560, 2596, 3072, 3584, 3592, 3616, 4096, 4608, 4616)
    draw16($0, 4640, 4644, 5120, 5124, 5128, 5140, 5144, 5152, 5156, 5632, 5636, 5640, 5644, 5648, 5656, 5660)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x020001
    draw4($t4, 1028, 1536, 2048, 4104)
    sw $t4 4132($v1)
    li $t4 0x010000
    draw4($t4, 4, 3108, 4100, 5148)
    li $t4 0x000100
    sw $t4 1540($v1)
    sw $t4 3076($v1)
    sw $t4 4636($v1)
    li $t4 0x010100
    sw $t4 32($v1)
    sw $t4 1572($v1)
    li $t4 0x020302
    sw $t4 544($v1)
    sw $t4 3588($v1)
    li $t4 0x010001
    sw $t4 3620($v1)
    sw $t4 5652($v1)
    li $t4 0x010101
    sw $t4 4128($v1)
    sw $t4 4612($v1)
    li $t4 0x450d19
    sw $t4 12($v1)
    li $t4 0xa12f32
    sw $t4 16($v1)
    li $t4 0xa55737
    sw $t4 20($v1)
    li $t4 0x50291b
    sw $t4 24($v1)
    li $t4 0x030201
    sw $t4 512($v1)
    li $t4 0x432a17
    sw $t4 520($v1)
    li $t4 0xde7b4b
    sw $t4 524($v1)
    li $t4 0xe66f4c
    sw $t4 528($v1)
    li $t4 0xe89d4e
    sw $t4 532($v1)
    li $t4 0xf7cd53
    sw $t4 536($v1)
    li $t4 0x2d0a12
    sw $t4 540($v1)
    li $t4 0x020101
    sw $t4 548($v1)
    li $t4 0x020201
    sw $t4 1024($v1)
    li $t4 0x883b2f
    sw $t4 1032($v1)
    li $t4 0xd6744b
    sw $t4 1036($v1)
    li $t4 0xae6f3c
    sw $t4 1040($v1)
    li $t4 0xbc6f41
    sw $t4 1044($v1)
    li $t4 0xffe959
    sw $t4 1048($v1)
    li $t4 0x863b24
    sw $t4 1052($v1)
    li $t4 0x040301
    sw $t4 1060($v1)
    li $t4 0x300314
    sw $t4 1544($v1)
    li $t4 0xcb5d64
    sw $t4 1548($v1)
    li $t4 0xb86670
    sw $t4 1552($v1)
    li $t4 0xcc8042
    sw $t4 1556($v1)
    li $t4 0xde9849
    sw $t4 1560($v1)
    li $t4 0xc2828a
    sw $t4 1564($v1)
    li $t4 0x484c4a
    sw $t4 1568($v1)
    li $t4 0x000200
    sw $t4 2052($v1)
    li $t4 0x2f121a
    sw $t4 2056($v1)
    li $t4 0xa64769
    sw $t4 2060($v1)
    li $t4 0xba887d
    sw $t4 2064($v1)
    li $t4 0xc76a49
    sw $t4 2068($v1)
    li $t4 0xbd5346
    sw $t4 2072($v1)
    li $t4 0xd0cecd
    sw $t4 2076($v1)
    li $t4 0x878a8a
    sw $t4 2080($v1)
    li $t4 0x000201
    sw $t4 2564($v1)
    li $t4 0x050000
    sw $t4 2568($v1)
    li $t4 0x76495d
    sw $t4 2572($v1)
    li $t4 0x902651
    sw $t4 2576($v1)
    li $t4 0x8c3247
    sw $t4 2580($v1)
    li $t4 0x8a1d37
    sw $t4 2584($v1)
    li $t4 0xc691a1
    sw $t4 2588($v1)
    li $t4 0xa8b0ae
    sw $t4 2592($v1)
    li $t4 0x060103
    sw $t4 3080($v1)
    li $t4 0x550c28
    sw $t4 3084($v1)
    li $t4 0x97566e
    sw $t4 3088($v1)
    li $t4 0x893548
    sw $t4 3092($v1)
    li $t4 0x790f33
    sw $t4 3096($v1)
    li $t4 0x780836
    sw $t4 3100($v1)
    li $t4 0x0f1010
    sw $t4 3104($v1)
    li $t4 0x6d6368
    sw $t4 3596($v1)
    li $t4 0x9e7583
    sw $t4 3600($v1)
    li $t4 0x8c002d
    sw $t4 3604($v1)
    li $t4 0x8c0136
    sw $t4 3608($v1)
    li $t4 0x3f061c
    sw $t4 3612($v1)
    li $t4 0x60102d
    sw $t4 4108($v1)
    li $t4 0xc4003d
    sw $t4 4112($v1)
    li $t4 0xa00237
    sw $t4 4116($v1)
    li $t4 0x7a0531
    sw $t4 4120($v1)
    li $t4 0x19060d
    sw $t4 4124($v1)
    li $t4 0x0e0706
    sw $t4 4620($v1)
    li $t4 0x643b40
    sw $t4 4624($v1)
    li $t4 0x280d16
    sw $t4 4628($v1)
    li $t4 0x050404
    sw $t4 4632($v1)
    li $t4 0x040201
    sw $t4 5132($v1)
    li $t4 0x090801
    sw $t4 5136($v1)
    jr $ra
draw_doll_02_19: # start at v1, use t4
    draw16($0, 0, 8, 28, 36, 1056, 3072, 4100, 4132, 4608, 4640, 4644, 5120, 5128, 5144, 5148, 5152)
    draw4($0, 5156, 5632, 5636, 5640)
    draw4($0, 5644, 5648, 5660, 5664)
    sw $0 5668($v1)
    li $t4 0x010000
    draw4($t4, 32, 512, 2084, 2596)
    draw4($t4, 3108, 3584, 3620, 4128)
    sw $t4 4636($v1)
    sw $t4 5124($v1)
    sw $t4 5656($v1)
    li $t4 0x010101
    sw $t4 4($v1)
    sw $t4 544($v1)
    sw $t4 4612($v1)
    li $t4 0x000100
    sw $t4 516($v1)
    sw $t4 4124($v1)
    li $t4 0x020101
    sw $t4 548($v1)
    sw $t4 3616($v1)
    li $t4 0x1c060a
    sw $t4 12($v1)
    li $t4 0x5e1f20
    sw $t4 16($v1)
    li $t4 0x64251f
    sw $t4 20($v1)
    li $t4 0x150008
    sw $t4 24($v1)
    li $t4 0x160209
    sw $t4 520($v1)
    li $t4 0xcb7a45
    sw $t4 524($v1)
    li $t4 0xea614c
    sw $t4 528($v1)
    li $t4 0xe35d4a
    sw $t4 532($v1)
    li $t4 0xc87144
    sw $t4 536($v1)
    li $t4 0x21110d
    sw $t4 540($v1)
    li $t4 0x040503
    sw $t4 1024($v1)
    li $t4 0x040002
    sw $t4 1028($v1)
    li $t4 0x9a4b34
    sw $t4 1032($v1)
    li $t4 0xf4bc51
    sw $t4 1036($v1)
    li $t4 0xbe7c3e
    sw $t4 1040($v1)
    li $t4 0xba703c
    sw $t4 1044($v1)
    li $t4 0xe7a84d
    sw $t4 1048($v1)
    li $t4 0x613a1e
    sw $t4 1052($v1)
    li $t4 0x040301
    sw $t4 1060($v1)
    li $t4 0x181918
    sw $t4 1536($v1)
    li $t4 0xafafb0
    sw $t4 1540($v1)
    li $t4 0xc06b64
    sw $t4 1544($v1)
    li $t4 0xba4947
    sw $t4 1548($v1)
    li $t4 0xae5357
    sw $t4 1552($v1)
    li $t4 0xd18679
    sw $t4 1556($v1)
    li $t4 0xaf5847
    sw $t4 1560($v1)
    li $t4 0x925457
    sw $t4 1564($v1)
    li $t4 0x0a0f10
    sw $t4 1568($v1)
    li $t4 0x010100
    sw $t4 1572($v1)
    li $t4 0x181617
    sw $t4 2048($v1)
    li $t4 0xd6eae1
    sw $t4 2052($v1)
    li $t4 0xa45a81
    sw $t4 2056($v1)
    li $t4 0x961b44
    sw $t4 2060($v1)
    li $t4 0xbe8f7c
    sw $t4 2064($v1)
    li $t4 0xc59985
    sw $t4 2068($v1)
    li $t4 0xc85a4d
    sw $t4 2072($v1)
    li $t4 0x88465b
    sw $t4 2076($v1)
    li $t4 0x0a100f
    sw $t4 2080($v1)
    li $t4 0x030303
    sw $t4 2560($v1)
    li $t4 0x793d56
    sw $t4 2564($v1)
    li $t4 0x9c2a53
    sw $t4 2568($v1)
    li $t4 0x8a3e5a
    sw $t4 2572($v1)
    li $t4 0x84737e
    sw $t4 2576($v1)
    li $t4 0x85556c
    sw $t4 2580($v1)
    li $t4 0x975d74
    sw $t4 2584($v1)
    li $t4 0x64203a
    sw $t4 2588($v1)
    li $t4 0x050a07
    sw $t4 2592($v1)
    li $t4 0x260008
    sw $t4 3076($v1)
    li $t4 0xae445b
    sw $t4 3080($v1)
    li $t4 0x631031
    sw $t4 3084($v1)
    li $t4 0x8b3553
    sw $t4 3088($v1)
    li $t4 0x80354f
    sw $t4 3092($v1)
    li $t4 0x650d31
    sw $t4 3096($v1)
    li $t4 0x831830
    sw $t4 3100($v1)
    li $t4 0x060602
    sw $t4 3104($v1)
    li $t4 0x000502
    sw $t4 3588($v1)
    li $t4 0x51031f
    sw $t4 3592($v1)
    li $t4 0x832348
    sw $t4 3596($v1)
    li $t4 0xb9cfc8
    sw $t4 3600($v1)
    li $t4 0xb1a8ab
    sw $t4 3604($v1)
    li $t4 0x570220
    sw $t4 3608($v1)
    li $t4 0x280511
    sw $t4 3612($v1)
    li $t4 0x020001
    sw $t4 4096($v1)
    li $t4 0x20050f
    sw $t4 4104($v1)
    li $t4 0x920d3e
    sw $t4 4108($v1)
    li $t4 0xbe7c92
    sw $t4 4112($v1)
    li $t4 0xe43268
    sw $t4 4116($v1)
    li $t4 0x820128
    sw $t4 4120($v1)
    li $t4 0x030203
    sw $t4 4616($v1)
    li $t4 0x45222c
    sw $t4 4620($v1)
    li $t4 0x70152f
    sw $t4 4624($v1)
    li $t4 0x520015
    sw $t4 4628($v1)
    li $t4 0x19030a
    sw $t4 4632($v1)
    li $t4 0x0f0f09
    sw $t4 5132($v1)
    li $t4 0x13160c
    sw $t4 5136($v1)
    li $t4 0x000300
    sw $t4 5140($v1)
    li $t4 0x030001
    sw $t4 5652($v1)
    jr $ra
draw_doll_02_20: # start at v1, use t4
    draw16($0, 0, 4, 12, 16, 20, 28, 32, 36, 520, 536, 544, 548, 1024, 1028, 1060, 1568)
    draw16($0, 2080, 3072, 3616, 3620, 4128, 4132, 4644, 5148, 5156, 5632, 5636, 5652, 5656, 5660, 5664, 5668)
    li $t4 0x010000
    draw4($t4, 4096, 5120, 5124, 5152)
    li $t4 0x010200
    sw $t4 24($v1)
    sw $t4 4636($v1)
    li $t4 0x000100
    sw $t4 540($v1)
    sw $t4 3104($v1)
    li $t4 0x030001
    sw $t4 2596($v1)
    sw $t4 4640($v1)
    li $t4 0x020001
    sw $t4 3108($v1)
    sw $t4 4608($v1)
    li $t4 0x020101
    sw $t4 8($v1)
    li $t4 0x020202
    sw $t4 512($v1)
    li $t4 0x030302
    sw $t4 516($v1)
    li $t4 0x1d070a
    sw $t4 524($v1)
    li $t4 0x451b17
    sw $t4 528($v1)
    li $t4 0x391512
    sw $t4 532($v1)
    li $t4 0x3a1715
    sw $t4 1032($v1)
    li $t4 0xdb784b
    sw $t4 1036($v1)
    li $t4 0xe34849
    sw $t4 1040($v1)
    li $t4 0xe35f4a
    sw $t4 1044($v1)
    li $t4 0x934f33
    sw $t4 1048($v1)
    li $t4 0x050002
    sw $t4 1052($v1)
    li $t4 0x010100
    sw $t4 1056($v1)
    li $t4 0x3a3c38
    sw $t4 1536($v1)
    li $t4 0x312c33
    sw $t4 1540($v1)
    li $t4 0xa45a35
    sw $t4 1544($v1)
    li $t4 0xf3b751
    sw $t4 1548($v1)
    li $t4 0xcb8d41
    sw $t4 1552($v1)
    li $t4 0xba5f40
    sw $t4 1556($v1)
    li $t4 0xffd254
    sw $t4 1560($v1)
    li $t4 0x532e1e
    sw $t4 1564($v1)
    li $t4 0x040201
    sw $t4 1572($v1)
    li $t4 0x9b9e9a
    sw $t4 2048($v1)
    li $t4 0xe0d5e3
    sw $t4 2052($v1)
    li $t4 0xc67c51
    sw $t4 2056($v1)
    li $t4 0xcd6c4d
    sw $t4 2060($v1)
    li $t4 0xaf5d55
    sw $t4 2064($v1)
    li $t4 0xc96a5f
    sw $t4 2068($v1)
    li $t4 0xb33e41
    sw $t4 2072($v1)
    li $t4 0x794839
    sw $t4 2076($v1)
    li $t4 0x030200
    sw $t4 2084($v1)
    li $t4 0x686767
    sw $t4 2560($v1)
    li $t4 0xc2d4cc
    sw $t4 2564($v1)
    li $t4 0xa75360
    sw $t4 2568($v1)
    li $t4 0xa3384c
    sw $t4 2572($v1)
    li $t4 0xbe8d7c
    sw $t4 2576($v1)
    li $t4 0xd19b88
    sw $t4 2580($v1)
    li $t4 0xb42346
    sw $t4 2584($v1)
    li $t4 0x6f2938
    sw $t4 2588($v1)
    li $t4 0x000101
    sw $t4 2592($v1)
    li $t4 0x593344
    sw $t4 3076($v1)
    li $t4 0x97194c
    sw $t4 3080($v1)
    li $t4 0x916375
    sw $t4 3084($v1)
    li $t4 0x897f83
    sw $t4 3088($v1)
    li $t4 0xa08f98
    sw $t4 3092($v1)
    li $t4 0x813b53
    sw $t4 3096($v1)
    li $t4 0x2f0813
    sw $t4 3100($v1)
    li $t4 0x050102
    sw $t4 3584($v1)
    li $t4 0x5b0b27
    sw $t4 3588($v1)
    li $t4 0xa92a4e
    sw $t4 3592($v1)
    li $t4 0x5a253a
    sw $t4 3596($v1)
    li $t4 0x8b445f
    sw $t4 3600($v1)
    li $t4 0x7d1b3e
    sw $t4 3604($v1)
    li $t4 0x61252e
    sw $t4 3608($v1)
    li $t4 0x030100
    sw $t4 3612($v1)
    li $t4 0x100908
    sw $t4 4100($v1)
    li $t4 0x6f072d
    sw $t4 4104($v1)
    li $t4 0x7b2b4a
    sw $t4 4108($v1)
    li $t4 0xaebfb9
    sw $t4 4112($v1)
    li $t4 0x96898f
    sw $t4 4116($v1)
    li $t4 0x5b1625
    sw $t4 4120($v1)
    li $t4 0x070304
    sw $t4 4124($v1)
    li $t4 0x000200
    sw $t4 4612($v1)
    li $t4 0x480018
    sw $t4 4616($v1)
    li $t4 0xa32f5a
    sw $t4 4620($v1)
    li $t4 0xd5d5d4
    sw $t4 4624($v1)
    li $t4 0xc15a7b
    sw $t4 4628($v1)
    li $t4 0x3d0012
    sw $t4 4632($v1)
    li $t4 0x15070b
    sw $t4 5128($v1)
    li $t4 0x5c2134
    sw $t4 5132($v1)
    li $t4 0x6b132f
    sw $t4 5136($v1)
    li $t4 0x5a001d
    sw $t4 5140($v1)
    li $t4 0x110407
    sw $t4 5144($v1)
    li $t4 0x050503
    sw $t4 5640($v1)
    li $t4 0x1b1c12
    sw $t4 5644($v1)
    li $t4 0x090b04
    sw $t4 5648($v1)
    jr $ra
draw_doll_02_21: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 20, 24, 28, 32, 36, 512, 516, 528, 532, 540, 544, 548)
    draw16($0, 1028, 1032, 1036, 1048, 1056, 1060, 1536, 1572, 2052, 2080, 2592, 3616, 4096, 4128, 4640, 4644)
    sw $0 5156($v1)
    sw $0 5668($v1)
    li $t4 0x010000
    draw4($t4, 16, 520, 1052, 4132)
    sw $t4 5124($v1)
    li $t4 0x000100
    draw4($t4, 1044, 1564, 3104, 5660)
    li $t4 0x010101
    draw4($t4, 1568, 2084, 3108, 4608)
    li $t4 0x020001
    sw $t4 5152($v1)
    sw $t4 5632($v1)
    sw $t4 5664($v1)
    li $t4 0x020101
    sw $t4 536($v1)
    sw $t4 2596($v1)
    li $t4 0x020202
    sw $t4 1024($v1)
    sw $t4 1540($v1)
    li $t4 0x020201
    sw $t4 524($v1)
    li $t4 0x050602
    sw $t4 1040($v1)
    li $t4 0x110207
    sw $t4 1544($v1)
    li $t4 0x954233
    sw $t4 1548($v1)
    li $t4 0xbc383c
    sw $t4 1552($v1)
    li $t4 0xb6433b
    sw $t4 1556($v1)
    li $t4 0x431819
    sw $t4 1560($v1)
    li $t4 0x2d2c2a
    sw $t4 2048($v1)
    li $t4 0x84472b
    sw $t4 2056($v1)
    li $t4 0xfdb054
    sw $t4 2060($v1)
    li $t4 0xdf7c49
    sw $t4 2064($v1)
    li $t4 0xd77649
    sw $t4 2068($v1)
    li $t4 0xde914a
    sw $t4 2072($v1)
    li $t4 0x110403
    sw $t4 2076($v1)
    li $t4 0xcbcbc9
    sw $t4 2560($v1)
    li $t4 0x8f8d96
    sw $t4 2564($v1)
    li $t4 0xaf6243
    sw $t4 2568($v1)
    li $t4 0xd57c4d
    sw $t4 2572($v1)
    li $t4 0x9a493c
    sw $t4 2576($v1)
    li $t4 0xb9604c
    sw $t4 2580($v1)
    li $t4 0xb53d44
    sw $t4 2584($v1)
    li $t4 0x4e2d31
    sw $t4 2588($v1)
    li $t4 0xb8b7b7
    sw $t4 3072($v1)
    li $t4 0xe1edeb
    sw $t4 3076($v1)
    li $t4 0xa53958
    sw $t4 3080($v1)
    li $t4 0xb23a45
    sw $t4 3084($v1)
    li $t4 0xc87b77
    sw $t4 3088($v1)
    li $t4 0xe19379
    sw $t4 3092($v1)
    li $t4 0x8f0b3e
    sw $t4 3096($v1)
    li $t4 0x584952
    sw $t4 3100($v1)
    li $t4 0x191818
    sw $t4 3584($v1)
    li $t4 0x8c6c7a
    sw $t4 3588($v1)
    li $t4 0x8e0f41
    sw $t4 3592($v1)
    li $t4 0x9a5d72
    sw $t4 3596($v1)
    li $t4 0x959284
    sw $t4 3600($v1)
    li $t4 0xa79190
    sw $t4 3604($v1)
    li $t4 0x984555
    sw $t4 3608($v1)
    li $t4 0x423b3c
    sw $t4 3612($v1)
    li $t4 0x020102
    sw $t4 3620($v1)
    li $t4 0x3d0918
    sw $t4 4100($v1)
    li $t4 0xa02d4e
    sw $t4 4104($v1)
    li $t4 0x704153
    sw $t4 4108($v1)
    li $t4 0x8d536e
    sw $t4 4112($v1)
    li $t4 0x853655
    sw $t4 4116($v1)
    li $t4 0x3f2826
    sw $t4 4120($v1)
    li $t4 0x070000
    sw $t4 4124($v1)
    li $t4 0x281916
    sw $t4 4612($v1)
    li $t4 0x8f2043
    sw $t4 4616($v1)
    li $t4 0x621c38
    sw $t4 4620($v1)
    li $t4 0x967e85
    sw $t4 4624($v1)
    li $t4 0x8c5468
    sw $t4 4628($v1)
    li $t4 0x50001c
    sw $t4 4632($v1)
    li $t4 0x050204
    sw $t4 4636($v1)
    li $t4 0x010001
    sw $t4 5120($v1)
    li $t4 0x53001b
    sw $t4 5128($v1)
    li $t4 0x953156
    sw $t4 5132($v1)
    li $t4 0xdafdf1
    sw $t4 5136($v1)
    li $t4 0xb58d9a
    sw $t4 5140($v1)
    li $t4 0x400112
    sw $t4 5144($v1)
    li $t4 0x030202
    sw $t4 5148($v1)
    li $t4 0x000200
    sw $t4 5636($v1)
    li $t4 0x2d0513
    sw $t4 5640($v1)
    li $t4 0x7f1239
    sw $t4 5644($v1)
    li $t4 0xc06784
    sw $t4 5648($v1)
    li $t4 0xb21f4d
    sw $t4 5652($v1)
    li $t4 0x2b030e
    sw $t4 5656($v1)
    jr $ra
draw_doll_03_00: # start at v1, use t4
    draw16($0, 0, 4, 8, 20, 28, 32, 36, 512, 516, 520, 524, 536, 540, 544, 548, 1056)
    draw16($0, 1060, 1536, 1540, 1564, 1568, 1572, 2084, 3584, 3612, 3620, 4128, 4132, 4612, 4644, 5156, 5632)
    draw4($0, 5636, 5652, 5660, 5664)
    sw $0 5668($v1)
    li $t4 0x010101
    draw4($t4, 1052, 2080, 2592, 2596)
    sw $t4 3104($v1)
    sw $t4 3108($v1)
    sw $t4 5124($v1)
    li $t4 0x000101
    draw4($t4, 24, 4608, 5120, 5152)
    li $t4 0x010000
    sw $t4 12($v1)
    sw $t4 5148($v1)
    sw $t4 5656($v1)
    li $t4 0x020000
    sw $t4 16($v1)
    sw $t4 4636($v1)
    li $t4 0x000201
    sw $t4 532($v1)
    sw $t4 4640($v1)
    li $t4 0x000401
    sw $t4 528($v1)
    li $t4 0x020202
    sw $t4 1024($v1)
    li $t4 0x030304
    sw $t4 1028($v1)
    li $t4 0x010302
    sw $t4 1032($v1)
    li $t4 0x2a2023
    sw $t4 1036($v1)
    li $t4 0x711a34
    sw $t4 1040($v1)
    li $t4 0x441f2a
    sw $t4 1044($v1)
    li $t4 0x090f0d
    sw $t4 1048($v1)
    li $t4 0x1c1f1d
    sw $t4 1544($v1)
    li $t4 0x4e4046
    sw $t4 1548($v1)
    li $t4 0x522935
    sw $t4 1552($v1)
    li $t4 0x2a2429
    sw $t4 1556($v1)
    li $t4 0x353636
    sw $t4 1560($v1)
    li $t4 0x6b637f
    sw $t4 2048($v1)
    li $t4 0x6a6379
    sw $t4 2052($v1)
    li $t4 0x1d1d1f
    sw $t4 2056($v1)
    li $t4 0x433835
    sw $t4 2060($v1)
    li $t4 0x223530
    sw $t4 2064($v1)
    li $t4 0x746042
    sw $t4 2068($v1)
    li $t4 0x1e1c19
    sw $t4 2072($v1)
    li $t4 0x2b2539
    sw $t4 2076($v1)
    li $t4 0xccbff3
    sw $t4 2560($v1)
    li $t4 0xf2e7ff
    sw $t4 2564($v1)
    li $t4 0x383345
    sw $t4 2568($v1)
    li $t4 0x552a21
    sw $t4 2572($v1)
    li $t4 0xa4ae86
    sw $t4 2576($v1)
    li $t4 0xc7ac7d
    sw $t4 2580($v1)
    li $t4 0x26191d
    sw $t4 2584($v1)
    li $t4 0x4f426b
    sw $t4 2588($v1)
    li $t4 0x645e74
    sw $t4 3072($v1)
    li $t4 0xcfc4e4
    sw $t4 3076($v1)
    li $t4 0x445064
    sw $t4 3080($v1)
    li $t4 0x5a667f
    sw $t4 3084($v1)
    li $t4 0x9985a7
    sw $t4 3088($v1)
    li $t4 0xa996be
    sw $t4 3092($v1)
    li $t4 0x323950
    sw $t4 3096($v1)
    li $t4 0x2f283e
    sw $t4 3100($v1)
    li $t4 0x3c2633
    sw $t4 3588($v1)
    li $t4 0x4c7d70
    sw $t4 3592($v1)
    li $t4 0x215f62
    sw $t4 3596($v1)
    li $t4 0x9b407f
    sw $t4 3600($v1)
    li $t4 0x652d4b
    sw $t4 3604($v1)
    li $t4 0x455747
    sw $t4 3608($v1)
    li $t4 0x000001
    sw $t4 3616($v1)
    li $t4 0x030404
    sw $t4 4096($v1)
    li $t4 0x190d09
    sw $t4 4100($v1)
    li $t4 0x20271b
    sw $t4 4104($v1)
    li $t4 0x1d4e5e
    sw $t4 4108($v1)
    li $t4 0xae84c7
    sw $t4 4112($v1)
    li $t4 0x796292
    sw $t4 4116($v1)
    li $t4 0x23110e
    sw $t4 4120($v1)
    li $t4 0x080404
    sw $t4 4124($v1)
    li $t4 0x004628
    sw $t4 4616($v1)
    li $t4 0x267771
    sw $t4 4620($v1)
    li $t4 0xefd8ff
    sw $t4 4624($v1)
    li $t4 0xa5dbe2
    sw $t4 4628($v1)
    li $t4 0x002614
    sw $t4 4632($v1)
    li $t4 0x03211a
    sw $t4 5128($v1)
    li $t4 0x0f6853
    sw $t4 5132($v1)
    li $t4 0x3b857c
    sw $t4 5136($v1)
    li $t4 0x16875c
    sw $t4 5140($v1)
    li $t4 0x022010
    sw $t4 5144($v1)
    li $t4 0x0b0205
    sw $t4 5640($v1)
    li $t4 0x371f36
    sw $t4 5644($v1)
    li $t4 0x100c10
    sw $t4 5648($v1)
    jr $ra
draw_doll_03_01: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 20, 24, 28, 32, 36, 512, 516, 540, 544, 548, 1028, 1056)
    draw16($0, 1060, 1568, 1572, 2048, 2052, 2076, 2084, 3108, 3616, 3620, 4132, 4608, 4612, 4644, 5148, 5152)
    draw4($0, 5156, 5632, 5636, 5656)
    sw $0 5660($v1)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x010101
    draw4($t4, 1024, 2080, 2592, 2596)
    sw $t4 5124($v1)
    li $t4 0x000100
    sw $t4 520($v1)
    sw $t4 5140($v1)
    li $t4 0x020203
    sw $t4 1564($v1)
    sw $t4 3104($v1)
    li $t4 0x010000
    sw $t4 4124($v1)
    sw $t4 5144($v1)
    li $t4 0x000201
    sw $t4 4128($v1)
    sw $t4 4640($v1)
    li $t4 0x000200
    sw $t4 16($v1)
    li $t4 0x1d1819
    sw $t4 524($v1)
    li $t4 0x591529
    sw $t4 528($v1)
    li $t4 0x371922
    sw $t4 532($v1)
    li $t4 0x030706
    sw $t4 536($v1)
    li $t4 0x131716
    sw $t4 1032($v1)
    li $t4 0x4d3b41
    sw $t4 1036($v1)
    li $t4 0x67293a
    sw $t4 1040($v1)
    li $t4 0x372a31
    sw $t4 1044($v1)
    li $t4 0x343636
    sw $t4 1048($v1)
    li $t4 0x020202
    sw $t4 1052($v1)
    li $t4 0x030203
    sw $t4 1536($v1)
    li $t4 0x040304
    sw $t4 1540($v1)
    li $t4 0x1e1f1f
    sw $t4 1544($v1)
    li $t4 0x403b3a
    sw $t4 1548($v1)
    li $t4 0x0f2423
    sw $t4 1552($v1)
    li $t4 0x4b4334
    sw $t4 1556($v1)
    li $t4 0x2f2d2b
    sw $t4 1560($v1)
    li $t4 0x000101
    sw $t4 2056($v1)
    li $t4 0x643a2f
    sw $t4 2060($v1)
    li $t4 0x8fa179
    sw $t4 2064($v1)
    li $t4 0xbea977
    sw $t4 2068($v1)
    li $t4 0x1d140d
    sw $t4 2072($v1)
    li $t4 0x211e27
    sw $t4 2560($v1)
    li $t4 0x5c566b
    sw $t4 2564($v1)
    li $t4 0x171a25
    sw $t4 2568($v1)
    li $t4 0x5e5e78
    sw $t4 2572($v1)
    li $t4 0x928294
    sw $t4 2576($v1)
    li $t4 0x9d89a6
    sw $t4 2580($v1)
    li $t4 0x2d2842
    sw $t4 2584($v1)
    li $t4 0x3c334f
    sw $t4 2588($v1)
    li $t4 0xc7bfea
    sw $t4 3072($v1)
    li $t4 0xe9cffa
    sw $t4 3076($v1)
    li $t4 0x437c70
    sw $t4 3080($v1)
    li $t4 0x316f76
    sw $t4 3084($v1)
    li $t4 0x903f86
    sw $t4 3088($v1)
    li $t4 0x6b405c
    sw $t4 3092($v1)
    li $t4 0x425550
    sw $t4 3096($v1)
    li $t4 0x3c2d49
    sw $t4 3100($v1)
    li $t4 0xd2c8f9
    sw $t4 3584($v1)
    li $t4 0xc2a8c8
    sw $t4 3588($v1)
    li $t4 0x2e2122
    sw $t4 3592($v1)
    li $t4 0x0f454c
    sw $t4 3596($v1)
    li $t4 0x995ea5
    sw $t4 3600($v1)
    li $t4 0x572e57
    sw $t4 3604($v1)
    li $t4 0x312017
    sw $t4 3608($v1)
    li $t4 0x090405
    sw $t4 3612($v1)
    li $t4 0x4a4559
    sw $t4 4096($v1)
    li $t4 0x17141e
    sw $t4 4100($v1)
    li $t4 0x001a0d
    sw $t4 4104($v1)
    li $t4 0x0a6955
    sw $t4 4108($v1)
    li $t4 0xe7d7ff
    sw $t4 4112($v1)
    li $t4 0x9dcbdb
    sw $t4 4116($v1)
    li $t4 0x001c0d
    sw $t4 4120($v1)
    li $t4 0x012117
    sw $t4 4616($v1)
    li $t4 0x097456
    sw $t4 4620($v1)
    li $t4 0x8294b4
    sw $t4 4624($v1)
    li $t4 0x35907d
    sw $t4 4628($v1)
    li $t4 0x022b12
    sw $t4 4632($v1)
    li $t4 0x020001
    sw $t4 4636($v1)
    li $t4 0x030304
    sw $t4 5120($v1)
    li $t4 0x0b0507
    sw $t4 5128($v1)
    li $t4 0x35283e
    sw $t4 5132($v1)
    li $t4 0x0d1218
    sw $t4 5136($v1)
    li $t4 0x010100
    sw $t4 5640($v1)
    li $t4 0x030000
    sw $t4 5644($v1)
    li $t4 0x070000
    sw $t4 5648($v1)
    li $t4 0x020000
    sw $t4 5652($v1)
    jr $ra
draw_doll_03_02: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 24, 28, 32, 36, 512, 516, 540, 544, 548, 1056, 1060, 1536)
    draw16($0, 1540, 1564, 1572, 2056, 2084, 3616, 3620, 4096, 4100, 4124, 4132, 4644, 5120, 5124, 5148, 5152)
    draw4($0, 5156, 5632, 5636, 5640)
    draw4($0, 5644, 5660, 5664, 5668)
    li $t4 0x000100
    sw $t4 1568($v1)
    sw $t4 4640($v1)
    sw $t4 5648($v1)
    li $t4 0x010101
    sw $t4 2596($v1)
    sw $t4 3108($v1)
    li $t4 0x000101
    sw $t4 4636($v1)
    sw $t4 5656($v1)
    li $t4 0x000805
    sw $t4 16($v1)
    li $t4 0x030404
    sw $t4 20($v1)
    li $t4 0x020504
    sw $t4 520($v1)
    li $t4 0x312327
    sw $t4 524($v1)
    li $t4 0x791b37
    sw $t4 528($v1)
    li $t4 0x47232e
    sw $t4 532($v1)
    li $t4 0x101514
    sw $t4 536($v1)
    li $t4 0x030304
    sw $t4 1024($v1)
    li $t4 0x010102
    sw $t4 1028($v1)
    li $t4 0x212322
    sw $t4 1032($v1)
    li $t4 0x4d4348
    sw $t4 1036($v1)
    li $t4 0x4a2f37
    sw $t4 1040($v1)
    li $t4 0x383438
    sw $t4 1044($v1)
    li $t4 0x373737
    sw $t4 1048($v1)
    li $t4 0x050506
    sw $t4 1052($v1)
    li $t4 0x181a19
    sw $t4 1544($v1)
    li $t4 0x4f3e3a
    sw $t4 1548($v1)
    li $t4 0x314841
    sw $t4 1552($v1)
    li $t4 0x8d7550
    sw $t4 1556($v1)
    li $t4 0x171610
    sw $t4 1560($v1)
    li $t4 0x302c3a
    sw $t4 2048($v1)
    li $t4 0x18161d
    sw $t4 2052($v1)
    li $t4 0x5d3532
    sw $t4 2060($v1)
    li $t4 0xa3aa80
    sw $t4 2064($v1)
    li $t4 0xc0a681
    sw $t4 2068($v1)
    li $t4 0x221519
    sw $t4 2072($v1)
    li $t4 0x3c334f
    sw $t4 2076($v1)
    li $t4 0x020201
    sw $t4 2080($v1)
    li $t4 0xc4bae2
    sw $t4 2560($v1)
    li $t4 0xd4c7ee
    sw $t4 2564($v1)
    li $t4 0x243c43
    sw $t4 2568($v1)
    li $t4 0x5d728c
    sw $t4 2572($v1)
    li $t4 0x9983b1
    sw $t4 2576($v1)
    li $t4 0xa391b9
    sw $t4 2580($v1)
    li $t4 0x60658e
    sw $t4 2584($v1)
    li $t4 0x4e456c
    sw $t4 2588($v1)
    li $t4 0x020102
    sw $t4 2592($v1)
    li $t4 0xa7a0ca
    sw $t4 3072($v1)
    li $t4 0xe8cbf1
    sw $t4 3076($v1)
    li $t4 0x487163
    sw $t4 3080($v1)
    li $t4 0x165357
    sw $t4 3084($v1)
    li $t4 0x915694
    sw $t4 3088($v1)
    li $t4 0x772a4c
    sw $t4 3092($v1)
    li $t4 0x49574a
    sw $t4 3096($v1)
    li $t4 0x372a34
    sw $t4 3100($v1)
    li $t4 0x020101
    sw $t4 3104($v1)
    li $t4 0x65617a
    sw $t4 3584($v1)
    li $t4 0x3f3139
    sw $t4 3588($v1)
    li $t4 0x101b0d
    sw $t4 3592($v1)
    li $t4 0x2e5c6d
    sw $t4 3596($v1)
    li $t4 0xba8cd7
    sw $t4 3600($v1)
    li $t4 0x8970a8
    sw $t4 3604($v1)
    li $t4 0x130807
    sw $t4 3608($v1)
    li $t4 0x0b0300
    sw $t4 3612($v1)
    li $t4 0x00462c
    sw $t4 4104($v1)
    li $t4 0x368780
    sw $t4 4108($v1)
    li $t4 0x8ecfc8
    sw $t4 4112($v1)
    li $t4 0x6ec0bf
    sw $t4 4116($v1)
    li $t4 0x00332a
    sw $t4 4120($v1)
    li $t4 0x010202
    sw $t4 4128($v1)
    li $t4 0x030405
    sw $t4 4608($v1)
    li $t4 0x020203
    sw $t4 4612($v1)
    li $t4 0x041a16
    sw $t4 4616($v1)
    li $t4 0x116655
    sw $t4 4620($v1)
    li $t4 0x00814d
    sw $t4 4624($v1)
    li $t4 0x007238
    sw $t4 4628($v1)
    li $t4 0x011e12
    sw $t4 4632($v1)
    li $t4 0x0a0204
    sw $t4 5128($v1)
    li $t4 0x2f1528
    sw $t4 5132($v1)
    li $t4 0x1c0310
    sw $t4 5136($v1)
    li $t4 0x030000
    sw $t4 5140($v1)
    li $t4 0x010000
    sw $t4 5144($v1)
    li $t4 0x000301
    sw $t4 5652($v1)
    jr $ra
draw_doll_03_03: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 20, 28, 32, 36, 516, 520, 536, 540, 544, 548, 1024)
    draw16($0, 1052, 1056, 1060, 1540, 1568, 1572, 2084, 3584, 4132, 4608, 4636, 4644, 5120, 5148, 5156, 5632)
    draw4($0, 5636, 5652, 5656, 5660)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x010101
    draw4($t4, 24, 512, 2080, 2592)
    sw $t4 2596($v1)
    sw $t4 4128($v1)
    li $t4 0x000100
    sw $t4 4640($v1)
    sw $t4 5124($v1)
    sw $t4 5152($v1)
    li $t4 0x070000
    sw $t4 5644($v1)
    sw $t4 5648($v1)
    li $t4 0x000302
    sw $t4 524($v1)
    li $t4 0x0d0b0b
    sw $t4 528($v1)
    li $t4 0x0b0808
    sw $t4 532($v1)
    li $t4 0x010201
    sw $t4 1028($v1)
    li $t4 0x050807
    sw $t4 1032($v1)
    li $t4 0x3f2f34
    sw $t4 1036($v1)
    li $t4 0x732541
    sw $t4 1040($v1)
    li $t4 0x46323c
    sw $t4 1044($v1)
    li $t4 0x1a1e1d
    sw $t4 1048($v1)
    li $t4 0x191520
    sw $t4 1536($v1)
    li $t4 0x252726
    sw $t4 1544($v1)
    li $t4 0x443d41
    sw $t4 1548($v1)
    li $t4 0x5b352f
    sw $t4 1552($v1)
    li $t4 0x52362f
    sw $t4 1556($v1)
    li $t4 0x353434
    sw $t4 1560($v1)
    li $t4 0x040404
    sw $t4 1564($v1)
    li $t4 0xc5b8e3
    sw $t4 2048($v1)
    li $t4 0x7c758d
    sw $t4 2052($v1)
    li $t4 0x101312
    sw $t4 2056($v1)
    li $t4 0x5d3d32
    sw $t4 2060($v1)
    li $t4 0x8b8165
    sw $t4 2064($v1)
    li $t4 0xc89968
    sw $t4 2068($v1)
    li $t4 0x15130c
    sw $t4 2072($v1)
    li $t4 0x060609
    sw $t4 2076($v1)
    li $t4 0xdacffb
    sw $t4 2560($v1)
    li $t4 0xdfd2ff
    sw $t4 2564($v1)
    li $t4 0x11081b
    sw $t4 2568($v1)
    li $t4 0x633c3a
    sw $t4 2572($v1)
    li $t4 0xb0b492
    sw $t4 2576($v1)
    li $t4 0xb0a68a
    sw $t4 2580($v1)
    li $t4 0x382935
    sw $t4 2584($v1)
    li $t4 0x5e4e7d
    sw $t4 2588($v1)
    li $t4 0x666177
    sw $t4 3072($v1)
    li $t4 0xa799bd
    sw $t4 3076($v1)
    li $t4 0x34575e
    sw $t4 3080($v1)
    li $t4 0x4e7286
    sw $t4 3084($v1)
    li $t4 0x8b6895
    sw $t4 3088($v1)
    li $t4 0x884f80
    sw $t4 3092($v1)
    li $t4 0x586584
    sw $t4 3096($v1)
    li $t4 0x2a2c3f
    sw $t4 3100($v1)
    li $t4 0x040305
    sw $t4 3104($v1)
    li $t4 0x000101
    sw $t4 3108($v1)
    li $t4 0x2d161a
    sw $t4 3588($v1)
    li $t4 0x526c61
    sw $t4 3592($v1)
    li $t4 0x15474a
    sw $t4 3596($v1)
    li $t4 0x8a5290
    sw $t4 3600($v1)
    li $t4 0x641a4d
    sw $t4 3604($v1)
    li $t4 0x1b3627
    sw $t4 3608($v1)
    li $t4 0x3c2d27
    sw $t4 3612($v1)
    li $t4 0x010001
    sw $t4 3616($v1)
    li $t4 0x020201
    sw $t4 3620($v1)
    li $t4 0x030404
    sw $t4 4096($v1)
    li $t4 0x0e0806
    sw $t4 4100($v1)
    li $t4 0x082111
    sw $t4 4104($v1)
    li $t4 0x56708f
    sw $t4 4108($v1)
    li $t4 0xbbafe8
    sw $t4 4112($v1)
    li $t4 0x979cd0
    sw $t4 4116($v1)
    li $t4 0x12191e
    sw $t4 4120($v1)
    li $t4 0x0c0404
    sw $t4 4124($v1)
    li $t4 0x000402
    sw $t4 4612($v1)
    li $t4 0x006044
    sw $t4 4616($v1)
    li $t4 0x008e5b
    sw $t4 4620($v1)
    li $t4 0x00b667
    sw $t4 4624($v1)
    li $t4 0x05b86c
    sw $t4 4628($v1)
    li $t4 0x005a3d
    sw $t4 4632($v1)
    li $t4 0x041f16
    sw $t4 5128($v1)
    li $t4 0x0c4b2d
    sw $t4 5132($v1)
    li $t4 0x096538
    sw $t4 5136($v1)
    li $t4 0x00562f
    sw $t4 5140($v1)
    li $t4 0x00180e
    sw $t4 5144($v1)
    li $t4 0x020000
    sw $t4 5640($v1)
    jr $ra
draw_doll_03_04: # start at v1, use t4
    draw16($0, 0, 8, 28, 32, 36, 516, 544, 1536, 1540, 1544, 1564, 1572, 2084, 2596, 3108, 3612)
    draw16($0, 3620, 4096, 4100, 4132, 4616, 4632, 4636, 4640, 4644, 5120, 5124, 5128, 5148, 5152, 5156, 5632)
    draw4($0, 5636, 5640, 5656, 5660)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x010101
    draw4($t4, 4, 512, 548, 1060)
    li $t4 0x000101
    sw $t4 5144($v1)
    sw $t4 5648($v1)
    sw $t4 5652($v1)
    li $t4 0x020202
    sw $t4 1024($v1)
    sw $t4 4608($v1)
    li $t4 0x010000
    sw $t4 1568($v1)
    sw $t4 5132($v1)
    li $t4 0x161918
    sw $t4 12($v1)
    li $t4 0x631b31
    sw $t4 16($v1)
    li $t4 0x5d1e31
    sw $t4 20($v1)
    li $t4 0x0e1311
    sw $t4 24($v1)
    li $t4 0x080909
    sw $t4 520($v1)
    li $t4 0x423e40
    sw $t4 524($v1)
    li $t4 0x592b39
    sw $t4 528($v1)
    li $t4 0x38252e
    sw $t4 532($v1)
    li $t4 0x343738
    sw $t4 536($v1)
    li $t4 0x101010
    sw $t4 540($v1)
    li $t4 0x030303
    sw $t4 1028($v1)
    li $t4 0x0d0d0e
    sw $t4 1032($v1)
    li $t4 0x413836
    sw $t4 1036($v1)
    li $t4 0x233130
    sw $t4 1040($v1)
    li $t4 0x444431
    sw $t4 1044($v1)
    li $t4 0x312e28
    sw $t4 1048($v1)
    li $t4 0x0d0e0e
    sw $t4 1052($v1)
    li $t4 0x010100
    sw $t4 1056($v1)
    li $t4 0x431f1c
    sw $t4 1548($v1)
    li $t4 0x8c8768
    sw $t4 1552($v1)
    li $t4 0xd1c993
    sw $t4 1556($v1)
    li $t4 0x483627
    sw $t4 1560($v1)
    li $t4 0x1c1a22
    sw $t4 2048($v1)
    li $t4 0x423c4e
    sw $t4 2052($v1)
    li $t4 0x2f3048
    sw $t4 2056($v1)
    li $t4 0x354454
    sw $t4 2060($v1)
    li $t4 0xa498b4
    sw $t4 2064($v1)
    li $t4 0x8c7a93
    sw $t4 2068($v1)
    li $t4 0x8475a6
    sw $t4 2072($v1)
    li $t4 0x514574
    sw $t4 2076($v1)
    li $t4 0x0a0a0e
    sw $t4 2080($v1)
    li $t4 0x8b84a6
    sw $t4 2560($v1)
    li $t4 0xecd2ff
    sw $t4 2564($v1)
    li $t4 0x7b8a98
    sw $t4 2568($v1)
    li $t4 0x0d5948
    sw $t4 2572($v1)
    li $t4 0xa794c7
    sw $t4 2576($v1)
    li $t4 0xa13b6b
    sw $t4 2580($v1)
    li $t4 0x3d616a
    sw $t4 2584($v1)
    li $t4 0x3b4b44
    sw $t4 2588($v1)
    li $t4 0x160a10
    sw $t4 2592($v1)
    li $t4 0x8b82a7
    sw $t4 3072($v1)
    li $t4 0xd5c6e8
    sw $t4 3076($v1)
    li $t4 0x3c2725
    sw $t4 3080($v1)
    li $t4 0x043b30
    sw $t4 3084($v1)
    li $t4 0x817bb4
    sw $t4 3088($v1)
    li $t4 0xa476b4
    sw $t4 3092($v1)
    li $t4 0x000b12
    sw $t4 3096($v1)
    li $t4 0x3d281d
    sw $t4 3100($v1)
    li $t4 0x0b0504
    sw $t4 3104($v1)
    li $t4 0x2d2938
    sw $t4 3584($v1)
    li $t4 0x18151f
    sw $t4 3588($v1)
    li $t4 0x000805
    sw $t4 3592($v1)
    li $t4 0x006341
    sw $t4 3596($v1)
    li $t4 0xbabedd
    sw $t4 3600($v1)
    li $t4 0xcfd1fd
    sw $t4 3604($v1)
    li $t4 0x06473b
    sw $t4 3608($v1)
    li $t4 0x000102
    sw $t4 3616($v1)
    li $t4 0x040b09
    sw $t4 4104($v1)
    li $t4 0x025c3b
    sw $t4 4108($v1)
    li $t4 0x419b89
    sw $t4 4112($v1)
    li $t4 0x3e9783
    sw $t4 4116($v1)
    li $t4 0x003f1f
    sw $t4 4120($v1)
    li $t4 0x030101
    sw $t4 4124($v1)
    li $t4 0x000201
    sw $t4 4128($v1)
    li $t4 0x020203
    sw $t4 4612($v1)
    li $t4 0x1b161a
    sw $t4 4620($v1)
    li $t4 0x16251f
    sw $t4 4624($v1)
    li $t4 0x000d04
    sw $t4 4628($v1)
    li $t4 0x050000
    sw $t4 5136($v1)
    li $t4 0x040000
    sw $t4 5140($v1)
    li $t4 0x000001
    sw $t4 5644($v1)
    jr $ra
draw_doll_03_05: # start at v1, use t4
    draw16($0, 0, 8, 32, 36, 1024, 1028, 1056, 1060, 1544, 1572, 2596, 3108, 3584, 3588, 3616, 4132)
    draw16($0, 4608, 4612, 4620, 4636, 4640, 4644, 5120, 5124, 5128, 5136, 5148, 5152, 5156, 5632, 5636, 5640)
    draw4($0, 5644, 5656, 5660, 5664)
    sw $0 5668($v1)
    li $t4 0x010101
    draw4($t4, 4, 512, 516, 520)
    sw $t4 544($v1)
    sw $t4 548($v1)
    li $t4 0x000101
    sw $t4 3620($v1)
    sw $t4 5132($v1)
    sw $t4 5648($v1)
    li $t4 0x030000
    sw $t4 4632($v1)
    sw $t4 5140($v1)
    li $t4 0x090f0d
    sw $t4 12($v1)
    li $t4 0x4e202e
    sw $t4 16($v1)
    li $t4 0x6f1c34
    sw $t4 20($v1)
    li $t4 0x1f1b1c
    sw $t4 24($v1)
    li $t4 0x020303
    sw $t4 28($v1)
    li $t4 0x383a3a
    sw $t4 524($v1)
    li $t4 0x58333e
    sw $t4 528($v1)
    li $t4 0x44232f
    sw $t4 532($v1)
    li $t4 0x2e3032
    sw $t4 536($v1)
    li $t4 0x232324
    sw $t4 540($v1)
    li $t4 0x050505
    sw $t4 1032($v1)
    li $t4 0x3b3534
    sw $t4 1036($v1)
    li $t4 0x2a2e2e
    sw $t4 1040($v1)
    li $t4 0x424837
    sw $t4 1044($v1)
    li $t4 0x5c4734
    sw $t4 1048($v1)
    li $t4 0x060807
    sw $t4 1052($v1)
    li $t4 0x0e0c12
    sw $t4 1536($v1)
    li $t4 0x06040a
    sw $t4 1540($v1)
    li $t4 0x200d0c
    sw $t4 1548($v1)
    li $t4 0x7e6550
    sw $t4 1552($v1)
    li $t4 0xc1cc97
    sw $t4 1556($v1)
    li $t4 0x7d6245
    sw $t4 1560($v1)
    li $t4 0x14101e
    sw $t4 1564($v1)
    li $t4 0x1d1925
    sw $t4 1568($v1)
    li $t4 0x554d67
    sw $t4 2048($v1)
    li $t4 0xc5bbd8
    sw $t4 2052($v1)
    li $t4 0x6c6787
    sw $t4 2056($v1)
    li $t4 0x12242b
    sw $t4 2060($v1)
    li $t4 0x9f9ab8
    sw $t4 2064($v1)
    li $t4 0x8c7c93
    sw $t4 2068($v1)
    li $t4 0x8879a3
    sw $t4 2072($v1)
    li $t4 0x544a7b
    sw $t4 2076($v1)
    li $t4 0x2d293f
    sw $t4 2080($v1)
    li $t4 0x000001
    sw $t4 2084($v1)
    li $t4 0x2c2937
    sw $t4 2560($v1)
    li $t4 0xe6d6ff
    sw $t4 2564($v1)
    li $t4 0xbfb4cd
    sw $t4 2568($v1)
    li $t4 0x105d43
    sw $t4 2572($v1)
    li $t4 0x67769e
    sw $t4 2576($v1)
    li $t4 0x9d326e
    sw $t4 2580($v1)
    li $t4 0x4f4354
    sw $t4 2584($v1)
    li $t4 0x275f50
    sw $t4 2588($v1)
    li $t4 0x2d1b24
    sw $t4 2592($v1)
    li $t4 0x343040
    sw $t4 3072($v1)
    li $t4 0x847d94
    sw $t4 3076($v1)
    li $t4 0x402a2a
    sw $t4 3080($v1)
    li $t4 0x093324
    sw $t4 3084($v1)
    li $t4 0x586395
    sw $t4 3088($v1)
    li $t4 0xbc87c4
    sw $t4 3092($v1)
    li $t4 0x2c223d
    sw $t4 3096($v1)
    li $t4 0x140f08
    sw $t4 3100($v1)
    li $t4 0x190a0a
    sw $t4 3104($v1)
    li $t4 0x000904
    sw $t4 3592($v1)
    li $t4 0x006642
    sw $t4 3596($v1)
    li $t4 0x8698b9
    sw $t4 3600($v1)
    li $t4 0xfef8ff
    sw $t4 3604($v1)
    li $t4 0x3e9386
    sw $t4 3608($v1)
    li $t4 0x000401
    sw $t4 3612($v1)
    li $t4 0x010202
    sw $t4 4096($v1)
    li $t4 0x030404
    sw $t4 4100($v1)
    li $t4 0x040807
    sw $t4 4104($v1)
    li $t4 0x00412a
    sw $t4 4108($v1)
    li $t4 0x217f6a
    sw $t4 4112($v1)
    li $t4 0x50a09b
    sw $t4 4116($v1)
    li $t4 0x016e3f
    sw $t4 4120($v1)
    li $t4 0x010906
    sw $t4 4124($v1)
    li $t4 0x010100
    sw $t4 4128($v1)
    li $t4 0x010000
    sw $t4 4616($v1)
    li $t4 0x1f1723
    sw $t4 4624($v1)
    li $t4 0x302436
    sw $t4 4628($v1)
    li $t4 0x010201
    sw $t4 5144($v1)
    li $t4 0x000102
    sw $t4 5652($v1)
    jr $ra
draw_doll_03_06: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 28, 32, 36, 512, 1028, 1032, 1060, 1572, 2084, 2596, 3072, 3076)
    draw16($0, 3108, 4100, 4608, 4612, 4616, 4636, 4644, 5120, 5124, 5128, 5132, 5148, 5152, 5156, 5632, 5636)
    draw4($0, 5640, 5644, 5656, 5660)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x000101
    draw4($t4, 3584, 3620, 4096, 5648)
    li $t4 0x010000
    sw $t4 3616($v1)
    sw $t4 5136($v1)
    li $t4 0x1a1315
    sw $t4 16($v1)
    li $t4 0x491423
    sw $t4 20($v1)
    li $t4 0x221216
    sw $t4 24($v1)
    li $t4 0x020201
    sw $t4 516($v1)
    li $t4 0x020202
    sw $t4 520($v1)
    li $t4 0x191e1d
    sw $t4 524($v1)
    li $t4 0x5a3943
    sw $t4 528($v1)
    li $t4 0x772b41
    sw $t4 532($v1)
    li $t4 0x3f373c
    sw $t4 536($v1)
    li $t4 0x2a2c2c
    sw $t4 540($v1)
    li $t4 0x020203
    sw $t4 544($v1)
    li $t4 0x010101
    sw $t4 548($v1)
    li $t4 0x030203
    sw $t4 1024($v1)
    li $t4 0x3a3939
    sw $t4 1036($v1)
    li $t4 0x37383b
    sw $t4 1040($v1)
    li $t4 0x202d2b
    sw $t4 1044($v1)
    li $t4 0x504236
    sw $t4 1048($v1)
    li $t4 0x212121
    sw $t4 1052($v1)
    li $t4 0x000100
    sw $t4 1056($v1)
    li $t4 0x1e1a27
    sw $t4 1536($v1)
    li $t4 0xaca2c3
    sw $t4 1540($v1)
    li $t4 0x363240
    sw $t4 1544($v1)
    li $t4 0x0f0e0b
    sw $t4 1548($v1)
    li $t4 0x6c473a
    sw $t4 1552($v1)
    li $t4 0x8ba279
    sw $t4 1556($v1)
    li $t4 0xb49661
    sw $t4 1560($v1)
    li $t4 0x0e0a0d
    sw $t4 1564($v1)
    li $t4 0x272133
    sw $t4 1568($v1)
    li $t4 0x1a1623
    sw $t4 2048($v1)
    li $t4 0xdcd1fc
    sw $t4 2052($v1)
    li $t4 0xede5ff
    sw $t4 2056($v1)
    li $t4 0x3a314c
    sw $t4 2060($v1)
    li $t4 0x594b58
    sw $t4 2064($v1)
    li $t4 0xafa3a5
    sw $t4 2068($v1)
    li $t4 0x907d91
    sw $t4 2072($v1)
    li $t4 0x4e3a62
    sw $t4 2076($v1)
    li $t4 0x54456e
    sw $t4 2080($v1)
    li $t4 0x0c0a0f
    sw $t4 2560($v1)
    li $t4 0x928ca9
    sw $t4 2564($v1)
    li $t4 0xbaa4cc
    sw $t4 2568($v1)
    li $t4 0x436c6d
    sw $t4 2572($v1)
    li $t4 0x2f7777
    sw $t4 2576($v1)
    li $t4 0x8f5390
    sw $t4 2580($v1)
    li $t4 0x7d4c76
    sw $t4 2584($v1)
    li $t4 0x34706f
    sw $t4 2588($v1)
    li $t4 0x1f252a
    sw $t4 2592($v1)
    li $t4 0x1c0909
    sw $t4 3080($v1)
    li $t4 0x44493b
    sw $t4 3084($v1)
    li $t4 0x23526a
    sw $t4 3088($v1)
    li $t4 0x9c5b9a
    sw $t4 3092($v1)
    li $t4 0x4e2648
    sw $t4 3096($v1)
    li $t4 0x001e0f
    sw $t4 3100($v1)
    li $t4 0x2a1e19
    sw $t4 3104($v1)
    li $t4 0x020302
    sw $t4 3588($v1)
    li $t4 0x010907
    sw $t4 3592($v1)
    li $t4 0x004b29
    sw $t4 3596($v1)
    li $t4 0x527991
    sw $t4 3600($v1)
    li $t4 0xffe6ff
    sw $t4 3604($v1)
    li $t4 0x85a9bf
    sw $t4 3608($v1)
    li $t4 0x010c04
    sw $t4 3612($v1)
    li $t4 0x020b09
    sw $t4 4104($v1)
    li $t4 0x026240
    sw $t4 4108($v1)
    li $t4 0x179569
    sw $t4 4112($v1)
    li $t4 0x88b9bd
    sw $t4 4116($v1)
    li $t4 0x2db784
    sw $t4 4120($v1)
    li $t4 0x00321a
    sw $t4 4124($v1)
    li $t4 0x020101
    sw $t4 4128($v1)
    li $t4 0x000201
    sw $t4 4132($v1)
    li $t4 0x000404
    sw $t4 4620($v1)
    li $t4 0x00180d
    sw $t4 4624($v1)
    li $t4 0x304558
    sw $t4 4628($v1)
    li $t4 0x152025
    sw $t4 4632($v1)
    li $t4 0x010102
    sw $t4 4640($v1)
    li $t4 0x100000
    sw $t4 5140($v1)
    li $t4 0x0b0000
    sw $t4 5144($v1)
    li $t4 0x000001
    sw $t4 5652($v1)
    jr $ra
draw_doll_03_07: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 28, 32, 36, 512, 544, 548, 1024, 1028, 1032, 1060, 1536)
    draw16($0, 2048, 2560, 3072, 3584, 3588, 3592, 4096, 4128, 4608, 4616, 5120, 5124, 5128, 5132, 5152, 5632)
    draw4($0, 5636, 5640, 5656, 5660)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x000100
    sw $t4 524($v1)
    sw $t4 4612($v1)
    li $t4 0x010101
    sw $t4 1572($v1)
    sw $t4 4100($v1)
    li $t4 0x010000
    sw $t4 5136($v1)
    sw $t4 5140($v1)
    li $t4 0x000201
    sw $t4 5648($v1)
    sw $t4 5652($v1)
    li $t4 0x000603
    sw $t4 20($v1)
    li $t4 0x030504
    sw $t4 24($v1)
    li $t4 0x020202
    sw $t4 516($v1)
    li $t4 0x020102
    sw $t4 520($v1)
    li $t4 0x292425
    sw $t4 528($v1)
    li $t4 0x6d213b
    sw $t4 532($v1)
    li $t4 0x512536
    sw $t4 536($v1)
    li $t4 0x111816
    sw $t4 540($v1)
    li $t4 0x202222
    sw $t4 1036($v1)
    li $t4 0x494146
    sw $t4 1040($v1)
    li $t4 0x4c292c
    sw $t4 1044($v1)
    li $t4 0x543a34
    sw $t4 1048($v1)
    li $t4 0x3e3d3d
    sw $t4 1052($v1)
    li $t4 0x111112
    sw $t4 1056($v1)
    li $t4 0x322d3d
    sw $t4 1540($v1)
    li $t4 0x1b1821
    sw $t4 1544($v1)
    li $t4 0x111512
    sw $t4 1548($v1)
    li $t4 0x704e44
    sw $t4 1552($v1)
    li $t4 0x696c55
    sw $t4 1556($v1)
    li $t4 0xcb9a68
    sw $t4 1560($v1)
    li $t4 0x322920
    sw $t4 1564($v1)
    li $t4 0x070908
    sw $t4 1568($v1)
    li $t4 0x756c8b
    sw $t4 2052($v1)
    li $t4 0xc9bedb
    sw $t4 2056($v1)
    li $t4 0x272333
    sw $t4 2060($v1)
    li $t4 0x371819
    sw $t4 2064($v1)
    li $t4 0xb49f83
    sw $t4 2068($v1)
    li $t4 0xc9b38b
    sw $t4 2072($v1)
    li $t4 0x2d2020
    sw $t4 2076($v1)
    li $t4 0x554671
    sw $t4 2080($v1)
    li $t4 0x070608
    sw $t4 2084($v1)
    li $t4 0x564f68
    sw $t4 2564($v1)
    li $t4 0xffffff
    sw $t4 2568($v1)
    li $t4 0x716b88
    sw $t4 2572($v1)
    li $t4 0x245150
    sw $t4 2576($v1)
    li $t4 0x7d83a5
    sw $t4 2580($v1)
    li $t4 0x8e6f9b
    sw $t4 2584($v1)
    li $t4 0x717096
    sw $t4 2588($v1)
    li $t4 0x3d385a
    sw $t4 2592($v1)
    li $t4 0x08080b
    sw $t4 2596($v1)
    li $t4 0x151319
    sw $t4 3076($v1)
    li $t4 0x4d4a5b
    sw $t4 3080($v1)
    li $t4 0x764747
    sw $t4 3084($v1)
    li $t4 0x45706d
    sw $t4 3088($v1)
    li $t4 0x4a3f62
    sw $t4 3092($v1)
    li $t4 0x751140
    sw $t4 3096($v1)
    li $t4 0x0b4c3c
    sw $t4 3100($v1)
    li $t4 0x264133
    sw $t4 3104($v1)
    li $t4 0x070101
    sw $t4 3108($v1)
    li $t4 0x002112
    sw $t4 3596($v1)
    li $t4 0x145352
    sw $t4 3600($v1)
    li $t4 0xb396da
    sw $t4 3604($v1)
    li $t4 0xb79fce
    sw $t4 3608($v1)
    li $t4 0x191222
    sw $t4 3612($v1)
    li $t4 0x150c09
    sw $t4 3616($v1)
    li $t4 0x040202
    sw $t4 3620($v1)
    li $t4 0x040304
    sw $t4 4104($v1)
    li $t4 0x00613f
    sw $t4 4108($v1)
    li $t4 0x0da269
    sw $t4 4112($v1)
    li $t4 0x9cb6ca
    sw $t4 4116($v1)
    li $t4 0xb0d4dc
    sw $t4 4120($v1)
    li $t4 0x1c614d
    sw $t4 4124($v1)
    li $t4 0x010202
    sw $t4 4132($v1)
    li $t4 0x011b12
    sw $t4 4620($v1)
    li $t4 0x00321b
    sw $t4 4624($v1)
    li $t4 0x001f1a
    sw $t4 4628($v1)
    li $t4 0x515797
    sw $t4 4632($v1)
    li $t4 0x1f2d3f
    sw $t4 4636($v1)
    li $t4 0x010100
    sw $t4 4640($v1)
    li $t4 0x010102
    sw $t4 4644($v1)
    li $t4 0x351e30
    sw $t4 5144($v1)
    li $t4 0x24111e
    sw $t4 5148($v1)
    li $t4 0x010001
    sw $t4 5156($v1)
    li $t4 0x000101
    sw $t4 5644($v1)
    jr $ra
draw_doll_03_08: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 20, 24, 28, 36, 512, 516, 524, 544, 548, 1024, 1028)
    draw16($0, 1032, 1536, 2048, 3584, 3588, 3592, 3596, 4096, 4608, 4612, 4616, 5120, 5124, 5128, 5132, 5140)
    draw4($0, 5632, 5636, 5640, 5644)
    sw $0 5668($v1)
    li $t4 0x010101
    sw $t4 32($v1)
    sw $t4 520($v1)
    sw $t4 2560($v1)
    li $t4 0x010102
    sw $t4 1060($v1)
    sw $t4 4644($v1)
    sw $t4 5156($v1)
    li $t4 0x010201
    sw $t4 528($v1)
    sw $t4 5648($v1)
    li $t4 0x010000
    sw $t4 1572($v1)
    sw $t4 5152($v1)
    li $t4 0x000101
    sw $t4 4100($v1)
    sw $t4 4132($v1)
    li $t4 0x150e10
    sw $t4 532($v1)
    li $t4 0x30181f
    sw $t4 536($v1)
    li $t4 0x110d0d
    sw $t4 540($v1)
    li $t4 0x0d0d0e
    sw $t4 1036($v1)
    li $t4 0x2d3130
    sw $t4 1040($v1)
    li $t4 0x4f4448
    sw $t4 1044($v1)
    li $t4 0x643344
    sw $t4 1048($v1)
    li $t4 0x3b3b3e
    sw $t4 1052($v1)
    li $t4 0x252525
    sw $t4 1056($v1)
    li $t4 0x040405
    sw $t4 1540($v1)
    li $t4 0x0f0c15
    sw $t4 1544($v1)
    li $t4 0x050603
    sw $t4 1548($v1)
    li $t4 0x454444
    sw $t4 1552($v1)
    li $t4 0x614848
    sw $t4 1556($v1)
    li $t4 0x69503b
    sw $t4 1560($v1)
    li $t4 0x523b2c
    sw $t4 1564($v1)
    li $t4 0x171a1a
    sw $t4 1568($v1)
    li $t4 0x0f0c14
    sw $t4 2052($v1)
    li $t4 0xb7add6
    sw $t4 2056($v1)
    li $t4 0x484457
    sw $t4 2060($v1)
    li $t4 0x1b1312
    sw $t4 2064($v1)
    li $t4 0x9f735b
    sw $t4 2068($v1)
    li $t4 0xc7d29b
    sw $t4 2072($v1)
    li $t4 0x9f8052
    sw $t4 2076($v1)
    li $t4 0x130f1c
    sw $t4 2080($v1)
    li $t4 0x0f0c12
    sw $t4 2084($v1)
    li $t4 0x060409
    sw $t4 2564($v1)
    li $t4 0xc6bce5
    sw $t4 2568($v1)
    li $t4 0xeee2ff
    sw $t4 2572($v1)
    li $t4 0x101224
    sw $t4 2576($v1)
    li $t4 0x584e57
    sw $t4 2580($v1)
    li $t4 0xaaa399
    sw $t4 2584($v1)
    li $t4 0x7b666f
    sw $t4 2588($v1)
    li $t4 0x5d497c
    sw $t4 2592($v1)
    li $t4 0x282335
    sw $t4 2596($v1)
    li $t4 0x020202
    sw $t4 3072($v1)
    li $t4 0x030204
    sw $t4 3076($v1)
    li $t4 0x706a82
    sw $t4 3080($v1)
    li $t4 0x706782
    sw $t4 3084($v1)
    li $t4 0x5f403b
    sw $t4 3088($v1)
    li $t4 0x8296b5
    sw $t4 3092($v1)
    li $t4 0x986198
    sw $t4 3096($v1)
    li $t4 0x635d7f
    sw $t4 3100($v1)
    li $t4 0x27444a
    sw $t4 3104($v1)
    li $t4 0x130c14
    sw $t4 3108($v1)
    li $t4 0x253121
    sw $t4 3600($v1)
    li $t4 0x2a5168
    sw $t4 3604($v1)
    li $t4 0xa7468c
    sw $t4 3608($v1)
    li $t4 0x44243f
    sw $t4 3612($v1)
    li $t4 0x252d22
    sw $t4 3616($v1)
    li $t4 0x070000
    sw $t4 3620($v1)
    li $t4 0x030303
    sw $t4 4104($v1)
    li $t4 0x041914
    sw $t4 4108($v1)
    li $t4 0x007345
    sw $t4 4112($v1)
    li $t4 0x44908e
    sw $t4 4116($v1)
    li $t4 0x7da2c1
    sw $t4 4120($v1)
    li $t4 0x6ca1ab
    sw $t4 4124($v1)
    li $t4 0x2b2434
    sw $t4 4128($v1)
    li $t4 0x010b08
    sw $t4 4620($v1)
    li $t4 0x013d22
    sw $t4 4624($v1)
    li $t4 0x214951
    sw $t4 4628($v1)
    li $t4 0x746ebb
    sw $t4 4632($v1)
    li $t4 0x1a4b53
    sw $t4 4636($v1)
    li $t4 0x000401
    sw $t4 4640($v1)
    li $t4 0x020000
    sw $t4 5136($v1)
    li $t4 0x5a446f
    sw $t4 5144($v1)
    li $t4 0x5d3b75
    sw $t4 5148($v1)
    li $t4 0x010001
    sw $t4 5652($v1)
    li $t4 0x050000
    sw $t4 5656($v1)
    li $t4 0x110902
    sw $t4 5660($v1)
    li $t4 0x020101
    sw $t4 5664($v1)
    jr $ra
draw_doll_03_09: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 32, 36, 512, 516, 520, 524, 528, 532, 536, 540, 544)
    draw16($0, 548, 1024, 1028, 1060, 1536, 1540, 1544, 2048, 2052, 2060, 2564, 3076, 3588, 4096, 4100, 4104)
    draw4($0, 4108, 4608, 4644, 5120)
    draw4($0, 5124, 5128, 5632, 5636)
    draw4($0, 5640, 5644, 5652, 5668)
    li $t4 0x010101
    draw4($t4, 20, 28, 1032, 1036)
    sw $t4 1548($v1)
    sw $t4 5156($v1)
    li $t4 0x020202
    draw4($t4, 1040, 2560, 3584, 4616)
    li $t4 0x010000
    sw $t4 5648($v1)
    sw $t4 5664($v1)
    li $t4 0x020001
    sw $t4 24($v1)
    li $t4 0x161414
    sw $t4 1044($v1)
    li $t4 0x401c28
    sw $t4 1048($v1)
    li $t4 0x2c1e22
    sw $t4 1052($v1)
    li $t4 0x000201
    sw $t4 1056($v1)
    li $t4 0x1e1e1e
    sw $t4 1552($v1)
    li $t4 0x4b4e4f
    sw $t4 1556($v1)
    li $t4 0x60343f
    sw $t4 1560($v1)
    li $t4 0x42393e
    sw $t4 1564($v1)
    li $t4 0x323434
    sw $t4 1568($v1)
    li $t4 0x0c0c0d
    sw $t4 1572($v1)
    li $t4 0x040307
    sw $t4 2056($v1)
    li $t4 0x2d3130
    sw $t4 2064($v1)
    li $t4 0x70524f
    sw $t4 2068($v1)
    li $t4 0x695847
    sw $t4 2072($v1)
    li $t4 0x7e5b3d
    sw $t4 2076($v1)
    li $t4 0x141618
    sw $t4 2080($v1)
    li $t4 0x030400
    sw $t4 2084($v1)
    li $t4 0x9086ab
    sw $t4 2568($v1)
    li $t4 0x666074
    sw $t4 2572($v1)
    li $t4 0x0a080b
    sw $t4 2576($v1)
    li $t4 0x784537
    sw $t4 2580($v1)
    li $t4 0xc0c193
    sw $t4 2584($v1)
    li $t4 0xceb078
    sw $t4 2588($v1)
    li $t4 0x13110e
    sw $t4 2592($v1)
    li $t4 0x302941
    sw $t4 2596($v1)
    li $t4 0x030303
    sw $t4 3072($v1)
    li $t4 0x8980a2
    sw $t4 3080($v1)
    li $t4 0xfff9ff
    sw $t4 3084($v1)
    li $t4 0x31334b
    sw $t4 3088($v1)
    li $t4 0x2e3340
    sw $t4 3092($v1)
    li $t4 0x948c98
    sw $t4 3096($v1)
    li $t4 0x9b899b
    sw $t4 3100($v1)
    li $t4 0x524164
    sw $t4 3104($v1)
    li $t4 0x5f4e7f
    sw $t4 3108($v1)
    li $t4 0x534f63
    sw $t4 3592($v1)
    li $t4 0xaaa1ba
    sw $t4 3596($v1)
    li $t4 0x7d5f66
    sw $t4 3600($v1)
    li $t4 0x3f897f
    sw $t4 3604($v1)
    li $t4 0x704674
    sw $t4 3608($v1)
    li $t4 0x82396a
    sw $t4 3612($v1)
    li $t4 0x316c6c
    sw $t4 3616($v1)
    li $t4 0x233133
    sw $t4 3620($v1)
    li $t4 0x30281c
    sw $t4 4112($v1)
    li $t4 0x26495c
    sw $t4 4116($v1)
    li $t4 0x9262a4
    sw $t4 4120($v1)
    li $t4 0x704069
    sw $t4 4124($v1)
    li $t4 0x05241a
    sw $t4 4128($v1)
    li $t4 0x2d251c
    sw $t4 4132($v1)
    li $t4 0x000100
    sw $t4 4612($v1)
    li $t4 0x020806
    sw $t4 4620($v1)
    li $t4 0x006141
    sw $t4 4624($v1)
    li $t4 0x009657
    sw $t4 4628($v1)
    li $t4 0x8ab0c7
    sw $t4 4632($v1)
    li $t4 0xf3f4ff
    sw $t4 4636($v1)
    li $t4 0x655d76
    sw $t4 4640($v1)
    li $t4 0x000303
    sw $t4 5132($v1)
    li $t4 0x034d32
    sw $t4 5136($v1)
    li $t4 0x007340
    sw $t4 5140($v1)
    li $t4 0x1d6658
    sw $t4 5144($v1)
    li $t4 0x637296
    sw $t4 5148($v1)
    li $t4 0x0a1717
    sw $t4 5152($v1)
    li $t4 0x18070e
    sw $t4 5656($v1)
    li $t4 0x1f0d15
    sw $t4 5660($v1)
    jr $ra
draw_doll_03_10: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 512, 516, 520, 524, 528, 532)
    draw16($0, 544, 548, 1024, 1028, 1032, 1036, 1040, 1044, 1048, 1052, 1056, 1060, 1536, 1540, 1552, 1572)
    draw16($0, 2048, 2052, 2056, 2060, 2564, 3076, 3588, 4100, 4608, 4612, 4616, 4620, 5120, 5124, 5156, 5632)
    sw $0 5636($v1)
    sw $0 5644($v1)
    li $t4 0x000101
    sw $t4 5128($v1)
    sw $t4 5640($v1)
    sw $t4 5668($v1)
    li $t4 0x000001
    sw $t4 1544($v1)
    sw $t4 2560($v1)
    li $t4 0x070a09
    sw $t4 1556($v1)
    sw $t4 2064($v1)
    li $t4 0x020101
    sw $t4 536($v1)
    li $t4 0x020001
    sw $t4 540($v1)
    li $t4 0x010102
    sw $t4 1548($v1)
    li $t4 0x30121b
    sw $t4 1560($v1)
    li $t4 0x33151e
    sw $t4 1564($v1)
    li $t4 0x000201
    sw $t4 1568($v1)
    li $t4 0x3c3739
    sw $t4 2068($v1)
    li $t4 0x75203a
    sw $t4 2072($v1)
    li $t4 0x4f2333
    sw $t4 2076($v1)
    li $t4 0x2d3332
    sw $t4 2080($v1)
    li $t4 0x0b0a0b
    sw $t4 2084($v1)
    li $t4 0x0c0a0f
    sw $t4 2568($v1)
    li $t4 0x0f0c15
    sw $t4 2572($v1)
    li $t4 0x0d0d0c
    sw $t4 2576($v1)
    li $t4 0x524747
    sw $t4 2580($v1)
    li $t4 0x192627
    sw $t4 2584($v1)
    li $t4 0x2b291e
    sw $t4 2588($v1)
    li $t4 0x362f2d
    sw $t4 2592($v1)
    li $t4 0x131512
    sw $t4 2596($v1)
    li $t4 0x020203
    sw $t4 3072($v1)
    li $t4 0x292432
    sw $t4 3080($v1)
    li $t4 0xc2b7dc
    sw $t4 3084($v1)
    li $t4 0x24252f
    sw $t4 3088($v1)
    li $t4 0x573226
    sw $t4 3092($v1)
    li $t4 0xac967a
    sw $t4 3096($v1)
    li $t4 0xdac187
    sw $t4 3100($v1)
    li $t4 0x382e1b
    sw $t4 3104($v1)
    li $t4 0x262136
    sw $t4 3108($v1)
    li $t4 0x020102
    sw $t4 3584($v1)
    li $t4 0x131119
    sw $t4 3592($v1)
    li $t4 0xede1ff
    sw $t4 3596($v1)
    li $t4 0x807ca0
    sw $t4 3600($v1)
    li $t4 0x050910
    sw $t4 3604($v1)
    li $t4 0x92868e
    sw $t4 3608($v1)
    li $t4 0xa29498
    sw $t4 3612($v1)
    li $t4 0x5b4761
    sw $t4 3616($v1)
    li $t4 0x7d63a5
    sw $t4 3620($v1)
    li $t4 0x010001
    sw $t4 4096($v1)
    li $t4 0x0a080c
    sw $t4 4104($v1)
    li $t4 0x847c95
    sw $t4 4108($v1)
    li $t4 0x8a6d7b
    sw $t4 4112($v1)
    li $t4 0x45776e
    sw $t4 4116($v1)
    li $t4 0x6e879a
    sw $t4 4120($v1)
    li $t4 0x86386d
    sw $t4 4124($v1)
    li $t4 0x5d7e8f
    sw $t4 4128($v1)
    li $t4 0x1f3c3e
    sw $t4 4132($v1)
    li $t4 0x2e160f
    sw $t4 4624($v1)
    li $t4 0x324e51
    sw $t4 4628($v1)
    li $t4 0x5a5081
    sw $t4 4632($v1)
    li $t4 0x893b73
    sw $t4 4636($v1)
    li $t4 0x001213
    sw $t4 4640($v1)
    li $t4 0x263624
    sw $t4 4644($v1)
    li $t4 0x030304
    sw $t4 5132($v1)
    li $t4 0x003225
    sw $t4 5136($v1)
    li $t4 0x007643
    sw $t4 5140($v1)
    li $t4 0x6095a4
    sw $t4 5144($v1)
    li $t4 0xf3e6ff
    sw $t4 5148($v1)
    li $t4 0x897da6
    sw $t4 5152($v1)
    li $t4 0x033427
    sw $t4 5648($v1)
    li $t4 0x02844d
    sw $t4 5652($v1)
    li $t4 0x1c9f73
    sw $t4 5656($v1)
    li $t4 0x70b8a7
    sw $t4 5660($v1)
    li $t4 0x3d615e
    sw $t4 5664($v1)
    jr $ra
draw_doll_03_11: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 28, 36, 512, 516, 520, 524, 528, 532, 544, 548, 1024)
    draw16($0, 1028, 1032, 1036, 1060, 1536, 1540, 1548, 2048, 2052, 2560, 2564, 2568, 2572, 3588, 4100, 4612)
    draw4($0, 4644, 5120, 5124, 5128)
    draw4($0, 5132, 5632, 5636, 5652)
    sw $0 5668($v1)
    li $t4 0x010101
    draw4($t4, 1544, 3072, 3076, 5156)
    li $t4 0x010000
    sw $t4 20($v1)
    sw $t4 5648($v1)
    li $t4 0x020202
    sw $t4 2056($v1)
    sw $t4 4608($v1)
    li $t4 0x020203
    sw $t4 2060($v1)
    sw $t4 5644($v1)
    li $t4 0x020000
    sw $t4 24($v1)
    li $t4 0x000101
    sw $t4 32($v1)
    li $t4 0x000501
    sw $t4 536($v1)
    li $t4 0x000201
    sw $t4 540($v1)
    li $t4 0x010302
    sw $t4 1040($v1)
    li $t4 0x2e2125
    sw $t4 1044($v1)
    li $t4 0x721a34
    sw $t4 1048($v1)
    li $t4 0x3f2029
    sw $t4 1052($v1)
    li $t4 0x080d0c
    sw $t4 1056($v1)
    li $t4 0x222524
    sw $t4 1552($v1)
    li $t4 0x4e3e44
    sw $t4 1556($v1)
    li $t4 0x512834
    sw $t4 1560($v1)
    li $t4 0x29252a
    sw $t4 1564($v1)
    li $t4 0x333434
    sw $t4 1568($v1)
    li $t4 0x030303
    sw $t4 1572($v1)
    li $t4 0x1f201e
    sw $t4 2064($v1)
    li $t4 0x423836
    sw $t4 2068($v1)
    li $t4 0x233731
    sw $t4 2072($v1)
    li $t4 0x765f42
    sw $t4 2076($v1)
    li $t4 0x181614
    sw $t4 2080($v1)
    li $t4 0x010202
    sw $t4 2084($v1)
    li $t4 0x0c080e
    sw $t4 2576($v1)
    li $t4 0x653a31
    sw $t4 2580($v1)
    li $t4 0xa5b085
    sw $t4 2584($v1)
    li $t4 0xc6aa7d
    sw $t4 2588($v1)
    li $t4 0x130b0b
    sw $t4 2592($v1)
    li $t4 0x060507
    sw $t4 2596($v1)
    li $t4 0x100f14
    sw $t4 3080($v1)
    li $t4 0x796f8a
    sw $t4 3084($v1)
    li $t4 0x262f3f
    sw $t4 3088($v1)
    li $t4 0x5f6e86
    sw $t4 3092($v1)
    li $t4 0x927ea3
    sw $t4 3096($v1)
    li $t4 0x9277a8
    sw $t4 3100($v1)
    li $t4 0x42405b
    sw $t4 3104($v1)
    li $t4 0x4b4068
    sw $t4 3108($v1)
    li $t4 0x020303
    sw $t4 3584($v1)
    li $t4 0x8b82a6
    sw $t4 3592($v1)
    li $t4 0xd2c5ec
    sw $t4 3596($v1)
    li $t4 0x695452
    sw $t4 3600($v1)
    li $t4 0x528593
    sw $t4 3604($v1)
    li $t4 0xa34c8d
    sw $t4 3608($v1)
    li $t4 0x562a47
    sw $t4 3612($v1)
    li $t4 0x0d5742
    sw $t4 3616($v1)
    li $t4 0x303b38
    sw $t4 3620($v1)
    li $t4 0x030304
    sw $t4 4096($v1)
    li $t4 0x6d6584
    sw $t4 4104($v1)
    li $t4 0xc4b8de
    sw $t4 4108($v1)
    li $t4 0x322318
    sw $t4 4112($v1)
    li $t4 0x1f5756
    sw $t4 4116($v1)
    li $t4 0x82639f
    sw $t4 4120($v1)
    li $t4 0x9272a6
    sw $t4 4124($v1)
    li $t4 0x262632
    sw $t4 4128($v1)
    li $t4 0x1e120e
    sw $t4 4132($v1)
    li $t4 0x282731
    sw $t4 4616($v1)
    li $t4 0x332b3b
    sw $t4 4620($v1)
    li $t4 0x002216
    sw $t4 4624($v1)
    li $t4 0x00854a
    sw $t4 4628($v1)
    li $t4 0x499296
    sw $t4 4632($v1)
    li $t4 0xfff6ff
    sw $t4 4636($v1)
    li $t4 0x728091
    sw $t4 4640($v1)
    li $t4 0x031410
    sw $t4 5136($v1)
    li $t4 0x015738
    sw $t4 5140($v1)
    li $t4 0x0a8353
    sw $t4 5144($v1)
    li $t4 0x4a9394
    sw $t4 5148($v1)
    li $t4 0x083f2b
    sw $t4 5152($v1)
    li $t4 0x020102
    sw $t4 5640($v1)
    li $t4 0x0f060b
    sw $t4 5656($v1)
    li $t4 0x37253a
    sw $t4 5660($v1)
    li $t4 0x080003
    sw $t4 5664($v1)
    jr $ra
draw_doll_03_12: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 20, 24, 28, 36, 512, 516, 520, 524, 528, 544, 548)
    draw16($0, 1024, 1028, 1036, 1060, 1536, 1540, 2048, 2052, 2060, 2084, 2564, 4096, 4132, 4608, 4612, 4616)
    draw4($0, 4620, 5120, 5124, 5632)
    draw4($0, 5636, 5640, 5644, 5652)
    sw $0 5668($v1)
    li $t4 0x010101
    draw4($t4, 1032, 3072, 4644, 5156)
    li $t4 0x010000
    sw $t4 32($v1)
    sw $t4 5648($v1)
    li $t4 0x020102
    sw $t4 1544($v1)
    sw $t4 1548($v1)
    li $t4 0x020203
    sw $t4 1572($v1)
    sw $t4 5132($v1)
    li $t4 0x010100
    sw $t4 2056($v1)
    sw $t4 3584($v1)
    li $t4 0x0c0d0d
    sw $t4 532($v1)
    li $t4 0x30101a
    sw $t4 536($v1)
    li $t4 0x1f0f14
    sw $t4 540($v1)
    li $t4 0x0d1210
    sw $t4 1040($v1)
    li $t4 0x50363e
    sw $t4 1044($v1)
    li $t4 0x822640
    sw $t4 1048($v1)
    li $t4 0x422c34
    sw $t4 1052($v1)
    li $t4 0x252928
    sw $t4 1056($v1)
    li $t4 0x252525
    sw $t4 1552($v1)
    li $t4 0x383739
    sw $t4 1556($v1)
    li $t4 0x111b1c
    sw $t4 1560($v1)
    li $t4 0x332e2a
    sw $t4 1564($v1)
    li $t4 0x323131
    sw $t4 1568($v1)
    li $t4 0x0b0d0b
    sw $t4 2064($v1)
    li $t4 0x674236
    sw $t4 2068($v1)
    li $t4 0x6c8569
    sw $t4 2072($v1)
    li $t4 0xae9b69
    sw $t4 2076($v1)
    li $t4 0x17130c
    sw $t4 2080($v1)
    li $t4 0x000001
    sw $t4 2560($v1)
    li $t4 0x000002
    sw $t4 2568($v1)
    li $t4 0x23202a
    sw $t4 2572($v1)
    li $t4 0x05050b
    sw $t4 2576($v1)
    li $t4 0x604c5c
    sw $t4 2580($v1)
    li $t4 0xa0998a
    sw $t4 2584($v1)
    li $t4 0x9c8089
    sw $t4 2588($v1)
    li $t4 0x24182a
    sw $t4 2592($v1)
    li $t4 0x282235
    sw $t4 2596($v1)
    li $t4 0x09070c
    sw $t4 3076($v1)
    li $t4 0xa69ec0
    sw $t4 3080($v1)
    li $t4 0xdacaf6
    sw $t4 3084($v1)
    li $t4 0x4c4f5d
    sw $t4 3088($v1)
    li $t4 0x68a0ac
    sw $t4 3092($v1)
    li $t4 0x8d528b
    sw $t4 3096($v1)
    li $t4 0x644777
    sw $t4 3100($v1)
    li $t4 0x394f56
    sw $t4 3104($v1)
    li $t4 0x4b3b60
    sw $t4 3108($v1)
    li $t4 0x0e0b12
    sw $t4 3588($v1)
    li $t4 0xd4c7f8
    sw $t4 3592($v1)
    li $t4 0xdacdf6
    sw $t4 3596($v1)
    li $t4 0x895f5c
    sw $t4 3600($v1)
    li $t4 0x315d69
    sw $t4 3604($v1)
    li $t4 0x8b3a7d
    sw $t4 3608($v1)
    li $t4 0x471334
    sw $t4 3612($v1)
    li $t4 0x443428
    sw $t4 3616($v1)
    li $t4 0x110a10
    sw $t4 3620($v1)
    li $t4 0x08070c
    sw $t4 4100($v1)
    li $t4 0x7e7796
    sw $t4 4104($v1)
    li $t4 0x3d3744
    sw $t4 4108($v1)
    li $t4 0x000d05
    sw $t4 4112($v1)
    li $t4 0x006f48
    sw $t4 4116($v1)
    li $t4 0xa2abd6
    sw $t4 4120($v1)
    li $t4 0xd2c7f6
    sw $t4 4124($v1)
    li $t4 0x040d16
    sw $t4 4128($v1)
    li $t4 0x042c23
    sw $t4 4624($v1)
    li $t4 0x01a559
    sw $t4 4628($v1)
    li $t4 0x66b2ac
    sw $t4 4632($v1)
    li $t4 0xb5b7df
    sw $t4 4636($v1)
    li $t4 0x041e1b
    sw $t4 4640($v1)
    li $t4 0x030304
    sw $t4 5128($v1)
    li $t4 0x010404
    sw $t4 5136($v1)
    li $t4 0x001e12
    sw $t4 5140($v1)
    li $t4 0x1d3b3e
    sw $t4 5144($v1)
    li $t4 0x333355
    sw $t4 5148($v1)
    li $t4 0x000401
    sw $t4 5152($v1)
    li $t4 0x0e0001
    sw $t4 5656($v1)
    li $t4 0x160805
    sw $t4 5660($v1)
    li $t4 0x020000
    sw $t4 5664($v1)
    jr $ra
draw_doll_03_13: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 20, 28, 32, 36, 512, 516, 520, 524, 548, 1024, 1028)
    draw16($0, 1036, 1536, 1540, 2048, 2052, 2056, 2060, 2084, 3584, 4096, 4100, 4104, 4108, 4132, 4608, 4612)
    draw4($0, 5120, 5124, 5128, 5132)
    draw4($0, 5156, 5632, 5636, 5640)
    draw4($0, 5644, 5648, 5652, 5668)
    li $t4 0x010101
    draw4($t4, 1032, 1060, 2560, 5664)
    li $t4 0x010000
    sw $t4 5136($v1)
    sw $t4 5152($v1)
    li $t4 0x000200
    sw $t4 24($v1)
    li $t4 0x000101
    sw $t4 528($v1)
    li $t4 0x1f181a
    sw $t4 532($v1)
    li $t4 0x591529
    sw $t4 536($v1)
    li $t4 0x32171f
    sw $t4 540($v1)
    li $t4 0x010504
    sw $t4 544($v1)
    li $t4 0x171b1a
    sw $t4 1040($v1)
    li $t4 0x523c43
    sw $t4 1044($v1)
    li $t4 0x682b3c
    sw $t4 1048($v1)
    li $t4 0x40353b
    sw $t4 1052($v1)
    li $t4 0x393b3a
    sw $t4 1056($v1)
    li $t4 0x020201
    sw $t4 1544($v1)
    li $t4 0x030303
    sw $t4 1548($v1)
    li $t4 0x252525
    sw $t4 1552($v1)
    li $t4 0x413d3c
    sw $t4 1556($v1)
    li $t4 0x132726
    sw $t4 1560($v1)
    li $t4 0x544b3c
    sw $t4 1564($v1)
    li $t4 0x343332
    sw $t4 1568($v1)
    li $t4 0x020202
    sw $t4 1572($v1)
    li $t4 0x101111
    sw $t4 2064($v1)
    li $t4 0x693e33
    sw $t4 2068($v1)
    li $t4 0x91a67d
    sw $t4 2072($v1)
    li $t4 0xbda774
    sw $t4 2076($v1)
    li $t4 0x140c07
    sw $t4 2080($v1)
    li $t4 0x060409
    sw $t4 2564($v1)
    li $t4 0x9f98b6
    sw $t4 2568($v1)
    li $t4 0x877f9a
    sw $t4 2572($v1)
    li $t4 0x00030a
    sw $t4 2576($v1)
    li $t4 0x6a6c83
    sw $t4 2580($v1)
    li $t4 0x8f7e8c
    sw $t4 2584($v1)
    li $t4 0x876d94
    sw $t4 2588($v1)
    li $t4 0x1e1d2e
    sw $t4 2592($v1)
    li $t4 0x2d263b
    sw $t4 2596($v1)
    li $t4 0x010100
    sw $t4 3072($v1)
    li $t4 0x0d0a13
    sw $t4 3076($v1)
    li $t4 0xd6ccf6
    sw $t4 3080($v1)
    li $t4 0xfbefff
    sw $t4 3084($v1)
    li $t4 0x736670
    sw $t4 3088($v1)
    li $t4 0x5d9da1
    sw $t4 3092($v1)
    li $t4 0x8e3e7a
    sw $t4 3096($v1)
    li $t4 0x532b50
    sw $t4 3100($v1)
    li $t4 0x3f524c
    sw $t4 3104($v1)
    li $t4 0x3b2d49
    sw $t4 3108($v1)
    li $t4 0x0a080e
    sw $t4 3588($v1)
    li $t4 0x998fb5
    sw $t4 3592($v1)
    li $t4 0xa69db8
    sw $t4 3596($v1)
    li $t4 0x5e403b
    sw $t4 3600($v1)
    li $t4 0x284d60
    sw $t4 3604($v1)
    li $t4 0x9a57a5
    sw $t4 3608($v1)
    li $t4 0x5a3458
    sw $t4 3612($v1)
    li $t4 0x331c18
    sw $t4 3616($v1)
    li $t4 0x070304
    sw $t4 3620($v1)
    li $t4 0x002f1a
    sw $t4 4112($v1)
    li $t4 0x06895d
    sw $t4 4116($v1)
    li $t4 0xbcc0ea
    sw $t4 4120($v1)
    li $t4 0xe4e4ff
    sw $t4 4124($v1)
    li $t4 0x022927
    sw $t4 4128($v1)
    li $t4 0x010302
    sw $t4 4616($v1)
    li $t4 0x020302
    sw $t4 4620($v1)
    li $t4 0x04412e
    sw $t4 4624($v1)
    li $t4 0x009f54
    sw $t4 4628($v1)
    li $t4 0x29a07a
    sw $t4 4632($v1)
    li $t4 0x4c8b93
    sw $t4 4636($v1)
    li $t4 0x02291b
    sw $t4 4640($v1)
    li $t4 0x010001
    sw $t4 4644($v1)
    li $t4 0x000003
    sw $t4 5140($v1)
    li $t4 0x1c2026
    sw $t4 5144($v1)
    li $t4 0x2c2738
    sw $t4 5148($v1)
    li $t4 0x040000
    sw $t4 5656($v1)
    li $t4 0x080000
    sw $t4 5660($v1)
    jr $ra
draw_doll_03_14: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 28, 36, 512, 516, 520, 524, 528, 532, 540, 544, 548)
    draw16($0, 1024, 1028, 1060, 1536, 1540, 1544, 1548, 2048, 2084, 3584, 3592, 4096, 4608, 4644, 5120, 5124)
    draw4($0, 5128, 5632, 5636, 5640)
    sw $0 5644($v1)
    sw $0 5648($v1)
    sw $0 5668($v1)
    li $t4 0x010101
    sw $t4 3072($v1)
    sw $t4 4100($v1)
    sw $t4 5156($v1)
    li $t4 0x010000
    sw $t4 20($v1)
    sw $t4 24($v1)
    li $t4 0x000100
    sw $t4 32($v1)
    sw $t4 4612($v1)
    li $t4 0x020202
    sw $t4 1032($v1)
    sw $t4 1036($v1)
    li $t4 0x010100
    sw $t4 2560($v1)
    sw $t4 3588($v1)
    li $t4 0x000400
    sw $t4 536($v1)
    li $t4 0x020302
    sw $t4 1040($v1)
    li $t4 0x2b2326
    sw $t4 1044($v1)
    li $t4 0x651c35
    sw $t4 1048($v1)
    li $t4 0x3a272e
    sw $t4 1052($v1)
    li $t4 0x090c0c
    sw $t4 1056($v1)
    li $t4 0x2e3130
    sw $t4 1552($v1)
    li $t4 0x4d4045
    sw $t4 1556($v1)
    li $t4 0x5d2b32
    sw $t4 1560($v1)
    li $t4 0x3e3132
    sw $t4 1564($v1)
    li $t4 0x363737
    sw $t4 1568($v1)
    li $t4 0x040405
    sw $t4 1572($v1)
    li $t4 0x0a080e
    sw $t4 2052($v1)
    li $t4 0x9c91b7
    sw $t4 2056($v1)
    li $t4 0x46424f
    sw $t4 2060($v1)
    li $t4 0x252826
    sw $t4 2064($v1)
    li $t4 0x4b3733
    sw $t4 2068($v1)
    li $t4 0x7e654e
    sw $t4 2072($v1)
    li $t4 0xad7853
    sw $t4 2076($v1)
    li $t4 0x141311
    sw $t4 2080($v1)
    li $t4 0x0c0a12
    sw $t4 2564($v1)
    li $t4 0xd9cefa
    sw $t4 2568($v1)
    li $t4 0xcabeec
    sw $t4 2572($v1)
    li $t4 0x000004
    sw $t4 2576($v1)
    li $t4 0x744434
    sw $t4 2580($v1)
    li $t4 0xaebb8f
    sw $t4 2584($v1)
    li $t4 0xbaa87b
    sw $t4 2588($v1)
    li $t4 0x22191d
    sw $t4 2592($v1)
    li $t4 0x51446b
    sw $t4 2596($v1)
    li $t4 0x060409
    sw $t4 3076($v1)
    li $t4 0x9d97b5
    sw $t4 3080($v1)
    li $t4 0xc4b8e1
    sw $t4 3084($v1)
    li $t4 0x22323e
    sw $t4 3088($v1)
    li $t4 0x65708d
    sw $t4 3092($v1)
    li $t4 0x967f98
    sw $t4 3096($v1)
    li $t4 0x97769a
    sw $t4 3100($v1)
    li $t4 0x575479
    sw $t4 3104($v1)
    li $t4 0x3f395b
    sw $t4 3108($v1)
    li $t4 0x4c3543
    sw $t4 3596($v1)
    li $t4 0x558981
    sw $t4 3600($v1)
    li $t4 0x174f50
    sw $t4 3604($v1)
    li $t4 0x7c3c75
    sw $t4 3608($v1)
    li $t4 0x5b0b39
    sw $t4 3612($v1)
    li $t4 0x275044
    sw $t4 3616($v1)
    li $t4 0x342b29
    sw $t4 3620($v1)
    li $t4 0x010201
    sw $t4 4104($v1)
    li $t4 0x1c0e09
    sw $t4 4108($v1)
    li $t4 0x192215
    sw $t4 4112($v1)
    li $t4 0x45607c
    sw $t4 4116($v1)
    li $t4 0xc39ce6
    sw $t4 4120($v1)
    li $t4 0x816bab
    sw $t4 4124($v1)
    li $t4 0x120c0a
    sw $t4 4128($v1)
    li $t4 0x1f0f0d
    sw $t4 4132($v1)
    li $t4 0x000101
    sw $t4 4616($v1)
    li $t4 0x000403
    sw $t4 4620($v1)
    li $t4 0x005a3c
    sw $t4 4624($v1)
    li $t4 0x398d85
    sw $t4 4628($v1)
    li $t4 0x69c6b0
    sw $t4 4632($v1)
    li $t4 0x5bcbb2
    sw $t4 4636($v1)
    li $t4 0x02533b
    sw $t4 4640($v1)
    li $t4 0x010403
    sw $t4 5132($v1)
    li $t4 0x01392a
    sw $t4 5136($v1)
    li $t4 0x006d3b
    sw $t4 5140($v1)
    li $t4 0x009046
    sw $t4 5144($v1)
    li $t4 0x008742
    sw $t4 5148($v1)
    li $t4 0x01321e
    sw $t4 5152($v1)
    li $t4 0x040000
    sw $t4 5652($v1)
    li $t4 0x140104
    sw $t4 5656($v1)
    li $t4 0x130001
    sw $t4 5660($v1)
    li $t4 0x030000
    sw $t4 5664($v1)
    jr $ra
draw_doll_03_15: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 32, 36, 512, 516, 520, 548, 1024, 1028, 1536, 1540, 1544, 1548)
    draw16($0, 1568, 1572, 2048, 2052, 2560, 3072, 3584, 3616, 4096, 4100, 4104, 4608, 4640, 5120, 5124, 5128)
    draw4($0, 5132, 5136, 5152, 5156)
    draw4($0, 5632, 5636, 5640, 5644)
    draw4($0, 5656, 5660, 5664, 5668)
    li $t4 0x020202
    sw $t4 524($v1)
    sw $t4 1032($v1)
    li $t4 0x010101
    sw $t4 4128($v1)
    sw $t4 4644($v1)
    li $t4 0x020203
    sw $t4 4132($v1)
    sw $t4 4612($v1)
    li $t4 0x050a09
    sw $t4 16($v1)
    li $t4 0x33141e
    sw $t4 20($v1)
    li $t4 0x441724
    sw $t4 24($v1)
    li $t4 0x080908
    sw $t4 28($v1)
    li $t4 0x323232
    sw $t4 528($v1)
    li $t4 0x702c41
    sw $t4 532($v1)
    li $t4 0x582535
    sw $t4 536($v1)
    li $t4 0x313636
    sw $t4 540($v1)
    li $t4 0x111111
    sw $t4 544($v1)
    li $t4 0x0a090a
    sw $t4 1036($v1)
    li $t4 0x3f3c3d
    sw $t4 1040($v1)
    li $t4 0x1a2325
    sw $t4 1044($v1)
    li $t4 0x222722
    sw $t4 1048($v1)
    li $t4 0x453c37
    sw $t4 1052($v1)
    li $t4 0x111214
    sw $t4 1056($v1)
    li $t4 0x010001
    sw $t4 1060($v1)
    li $t4 0x41261f
    sw $t4 1552($v1)
    li $t4 0x756d57
    sw $t4 1556($v1)
    li $t4 0xaab480
    sw $t4 1560($v1)
    li $t4 0x655136
    sw $t4 1564($v1)
    li $t4 0x2e2934
    sw $t4 2056($v1)
    li $t4 0x201f2b
    sw $t4 2060($v1)
    li $t4 0x211d2c
    sw $t4 2064($v1)
    li $t4 0x93848f
    sw $t4 2068($v1)
    li $t4 0xa29499
    sw $t4 2072($v1)
    li $t4 0x54435b
    sw $t4 2076($v1)
    li $t4 0x2a233a
    sw $t4 2080($v1)
    li $t4 0x131017
    sw $t4 2084($v1)
    li $t4 0x5f5870
    sw $t4 2564($v1)
    li $t4 0xe9e1ff
    sw $t4 2568($v1)
    li $t4 0xa188af
    sw $t4 2572($v1)
    li $t4 0x43726c
    sw $t4 2576($v1)
    li $t4 0x857eb6
    sw $t4 2580($v1)
    li $t4 0x772862
    sw $t4 2584($v1)
    li $t4 0x536770
    sw $t4 2588($v1)
    li $t4 0x42364f
    sw $t4 2592($v1)
    li $t4 0x1e1928
    sw $t4 2596($v1)
    li $t4 0x746a8b
    sw $t4 3076($v1)
    li $t4 0xf0e9ff
    sw $t4 3080($v1)
    li $t4 0x9f7a8d
    sw $t4 3084($v1)
    li $t4 0x424840
    sw $t4 3088($v1)
    li $t4 0x5b5b89
    sw $t4 3092($v1)
    li $t4 0x7e2862
    sw $t4 3096($v1)
    li $t4 0x39292c
    sw $t4 3100($v1)
    li $t4 0x2d1a1a
    sw $t4 3104($v1)
    li $t4 0x000102
    sw $t4 3108($v1)
    li $t4 0x403a4e
    sw $t4 3588($v1)
    li $t4 0x585365
    sw $t4 3592($v1)
    li $t4 0x000003
    sw $t4 3596($v1)
    li $t4 0x005229
    sw $t4 3600($v1)
    li $t4 0x3d908b
    sw $t4 3604($v1)
    li $t4 0xfbe7ff
    sw $t4 3608($v1)
    li $t4 0x5a6680
    sw $t4 3612($v1)
    li $t4 0x040203
    sw $t4 3620($v1)
    li $t4 0x020505
    sw $t4 4108($v1)
    li $t4 0x027045
    sw $t4 4112($v1)
    li $t4 0x0faa6f
    sw $t4 4116($v1)
    li $t4 0xabb0d7
    sw $t4 4120($v1)
    li $t4 0x3f5e69
    sw $t4 4124($v1)
    li $t4 0x030304
    sw $t4 4616($v1)
    li $t4 0x000001
    sw $t4 4620($v1)
    li $t4 0x000706
    sw $t4 4624($v1)
    li $t4 0x031c11
    sw $t4 4628($v1)
    li $t4 0x383a5a
    sw $t4 4632($v1)
    li $t4 0x0e0d15
    sw $t4 4636($v1)
    li $t4 0x020000
    sw $t4 5140($v1)
    li $t4 0x0f0300
    sw $t4 5144($v1)
    li $t4 0x080201
    sw $t4 5148($v1)
    li $t4 0x000100
    sw $t4 5648($v1)
    li $t4 0x000101
    sw $t4 5652($v1)
    jr $ra
draw_doll_03_16: # start at v1, use t4
    draw16($0, 0, 4, 12, 32, 36, 512, 548, 1024, 1032, 2052, 2080, 2560, 2564, 3072, 3076, 3080)
    draw16($0, 3084, 3584, 3616, 4096, 4104, 4608, 4612, 4616, 4624, 4640, 4644, 5120, 5124, 5128, 5132, 5136)
    draw4($0, 5140, 5144, 5152, 5156)
    draw4($0, 5632, 5636, 5640, 5644)
    draw4($0, 5648, 5660, 5664, 5668)
    li $t4 0x010101
    draw4($t4, 8, 516, 520, 1028)
    sw $t4 1540($v1)
    sw $t4 5148($v1)
    sw $t4 5652($v1)
    li $t4 0x010000
    sw $t4 1060($v1)
    sw $t4 1568($v1)
    sw $t4 4620($v1)
    li $t4 0x000101
    sw $t4 4100($v1)
    sw $t4 4132($v1)
    li $t4 0x2d2e2d
    sw $t4 16($v1)
    li $t4 0x3c3a3a
    sw $t4 20($v1)
    li $t4 0x471021
    sw $t4 24($v1)
    li $t4 0x0e0f0f
    sw $t4 28($v1)
    li $t4 0x111111
    sw $t4 524($v1)
    li $t4 0x636363
    sw $t4 528($v1)
    li $t4 0x565556
    sw $t4 532($v1)
    li $t4 0x423138
    sw $t4 536($v1)
    li $t4 0x383a3b
    sw $t4 540($v1)
    li $t4 0x090808
    sw $t4 544($v1)
    li $t4 0x222322
    sw $t4 1036($v1)
    li $t4 0x545455
    sw $t4 1040($v1)
    li $t4 0x4c4747
    sw $t4 1044($v1)
    li $t4 0x373029
    sw $t4 1048($v1)
    li $t4 0x24201d
    sw $t4 1052($v1)
    li $t4 0x080808
    sw $t4 1056($v1)
    li $t4 0x000001
    sw $t4 1536($v1)
    li $t4 0x0d0a13
    sw $t4 1544($v1)
    li $t4 0x333136
    sw $t4 1548($v1)
    li $t4 0x292c2c
    sw $t4 1552($v1)
    li $t4 0x413735
    sw $t4 1556($v1)
    li $t4 0xa47657
    sw $t4 1560($v1)
    li $t4 0x442d21
    sw $t4 1564($v1)
    li $t4 0x030202
    sw $t4 1572($v1)
    li $t4 0x030304
    sw $t4 2048($v1)
    li $t4 0x4f4765
    sw $t4 2056($v1)
    li $t4 0x3c3943
    sw $t4 2060($v1)
    li $t4 0x1b1c18
    sw $t4 2064($v1)
    li $t4 0x565568
    sw $t4 2068($v1)
    li $t4 0x9c8ec4
    sw $t4 2072($v1)
    li $t4 0x655f7f
    sw $t4 2076($v1)
    li $t4 0x020202
    sw $t4 2084($v1)
    li $t4 0x0c0b10
    sw $t4 2568($v1)
    li $t4 0x131215
    sw $t4 2572($v1)
    li $t4 0x090a07
    sw $t4 2576($v1)
    li $t4 0x9681b8
    sw $t4 2580($v1)
    li $t4 0x927eb5
    sw $t4 2584($v1)
    li $t4 0x2d644f
    sw $t4 2588($v1)
    li $t4 0x2d342a
    sw $t4 2592($v1)
    li $t4 0x040101
    sw $t4 2596($v1)
    li $t4 0x070405
    sw $t4 3088($v1)
    li $t4 0x3f5a6c
    sw $t4 3092($v1)
    li $t4 0x3c557b
    sw $t4 3096($v1)
    li $t4 0x140b1a
    sw $t4 3100($v1)
    li $t4 0x311b18
    sw $t4 3104($v1)
    li $t4 0x030102
    sw $t4 3108($v1)
    li $t4 0x000201
    sw $t4 3588($v1)
    li $t4 0x010001
    sw $t4 3592($v1)
    li $t4 0x00291d
    sw $t4 3596($v1)
    li $t4 0x036445
    sw $t4 3600($v1)
    li $t4 0x008a3c
    sw $t4 3604($v1)
    li $t4 0x43a693
    sw $t4 3608($v1)
    li $t4 0x4a4969
    sw $t4 3612($v1)
    li $t4 0x020303
    sw $t4 3620($v1)
    li $t4 0x01291e
    sw $t4 4108($v1)
    li $t4 0x005131
    sw $t4 4112($v1)
    li $t4 0x346276
    sw $t4 4116($v1)
    li $t4 0x38617f
    sw $t4 4120($v1)
    li $t4 0x00341e
    sw $t4 4124($v1)
    li $t4 0x030101
    sw $t4 4128($v1)
    li $t4 0x230f24
    sw $t4 4628($v1)
    li $t4 0x462849
    sw $t4 4632($v1)
    li $t4 0x070000
    sw $t4 4636($v1)
    li $t4 0x000102
    sw $t4 5656($v1)
    jr $ra
draw_doll_03_17: # start at v1, use t4
    draw16($0, 0, 4, 8, 32, 36, 512, 516, 1024, 1028, 1056, 1536, 2048, 2056, 2084, 3076, 3104)
    draw16($0, 3584, 3592, 3616, 4096, 4608, 4612, 4620, 4636, 4644, 5120, 5124, 5128, 5140, 5144, 5152, 5156)
    draw4($0, 5632, 5636, 5640, 5644)
    draw4($0, 5648, 5660, 5664, 5668)
    li $t4 0x010101
    draw4($t4, 28, 544, 548, 1060)
    sw $t4 1572($v1)
    sw $t4 2564($v1)
    sw $t4 2596($v1)
    li $t4 0x000101
    draw4($t4, 2560, 3588, 3620, 4100)
    sw $t4 4132($v1)
    sw $t4 5132($v1)
    sw $t4 5148($v1)
    li $t4 0x010000
    sw $t4 1544($v1)
    sw $t4 3072($v1)
    sw $t4 4616($v1)
    li $t4 0x020101
    sw $t4 1540($v1)
    sw $t4 4104($v1)
    li $t4 0x010001
    sw $t4 4128($v1)
    sw $t4 4640($v1)
    li $t4 0x0a0d0c
    sw $t4 12($v1)
    li $t4 0x430f1f
    sw $t4 16($v1)
    li $t4 0x3c3437
    sw $t4 20($v1)
    li $t4 0x323433
    sw $t4 24($v1)
    li $t4 0x040404
    sw $t4 520($v1)
    li $t4 0x343737
    sw $t4 524($v1)
    li $t4 0x45333a
    sw $t4 528($v1)
    li $t4 0x585355
    sw $t4 532($v1)
    li $t4 0x666767
    sw $t4 536($v1)
    li $t4 0x191919
    sw $t4 540($v1)
    li $t4 0x060606
    sw $t4 1032($v1)
    li $t4 0x25201d
    sw $t4 1036($v1)
    li $t4 0x22221d
    sw $t4 1040($v1)
    li $t4 0x2d302e
    sw $t4 1044($v1)
    li $t4 0x5a5a59
    sw $t4 1048($v1)
    li $t4 0x313130
    sw $t4 1052($v1)
    li $t4 0x39241b
    sw $t4 1548($v1)
    li $t4 0x805e45
    sw $t4 1552($v1)
    li $t4 0x635e78
    sw $t4 1556($v1)
    li $t4 0x59555f
    sw $t4 1560($v1)
    li $t4 0x29292a
    sw $t4 1564($v1)
    li $t4 0x110f17
    sw $t4 1568($v1)
    li $t4 0x020203
    sw $t4 2052($v1)
    li $t4 0x5a5574
    sw $t4 2060($v1)
    li $t4 0x696373
    sw $t4 2064($v1)
    li $t4 0xb0a7ce
    sw $t4 2068($v1)
    li $t4 0x585369
    sw $t4 2072($v1)
    li $t4 0x45424c
    sw $t4 2076($v1)
    li $t4 0x363045
    sw $t4 2080($v1)
    li $t4 0x2c2c23
    sw $t4 2568($v1)
    li $t4 0x337261
    sw $t4 2572($v1)
    li $t4 0x3a3c3d
    sw $t4 2576($v1)
    li $t4 0x3e3153
    sw $t4 2580($v1)
    li $t4 0x231e24
    sw $t4 2584($v1)
    li $t4 0x141317
    sw $t4 2588($v1)
    li $t4 0x020104
    sw $t4 2592($v1)
    li $t4 0x301916
    sw $t4 3080($v1)
    li $t4 0x090208
    sw $t4 3084($v1)
    li $t4 0x052628
    sw $t4 3088($v1)
    li $t4 0x003f2a
    sw $t4 3092($v1)
    li $t4 0x063325
    sw $t4 3096($v1)
    li $t4 0x000a06
    sw $t4 3100($v1)
    li $t4 0x000100
    sw $t4 3108($v1)
    li $t4 0x072a25
    sw $t4 3596($v1)
    li $t4 0x05b06b
    sw $t4 3600($v1)
    li $t4 0x009751
    sw $t4 3604($v1)
    li $t4 0x00714a
    sw $t4 3608($v1)
    li $t4 0x003626
    sw $t4 3612($v1)
    li $t4 0x002315
    sw $t4 4108($v1)
    li $t4 0x006c3a
    sw $t4 4112($v1)
    li $t4 0x3b6e87
    sw $t4 4116($v1)
    li $t4 0x1f4d56
    sw $t4 4120($v1)
    li $t4 0x002416
    sw $t4 4124($v1)
    li $t4 0x090000
    sw $t4 4624($v1)
    li $t4 0x4a274d
    sw $t4 4628($v1)
    li $t4 0x1c0e1d
    sw $t4 4632($v1)
    li $t4 0x010201
    sw $t4 5136($v1)
    li $t4 0x000102
    sw $t4 5652($v1)
    li $t4 0x000001
    sw $t4 5656($v1)
    jr $ra
draw_doll_03_18: # start at v1, use t4
    draw16($0, 0, 4, 8, 28, 32, 36, 516, 548, 1028, 1056, 1536, 1572, 2048, 2084, 2560, 2568)
    draw16($0, 2596, 3072, 3108, 3584, 3592, 3616, 4096, 4608, 4616, 4640, 4644, 5120, 5124, 5128, 5144, 5148)
    draw4($0, 5152, 5156, 5632, 5636)
    draw4($0, 5640, 5644, 5648, 5660)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x010101
    draw4($t4, 512, 1024, 1060, 4128)
    sw $t4 4612($v1)
    li $t4 0x020202
    sw $t4 544($v1)
    sw $t4 2052($v1)
    sw $t4 2564($v1)
    li $t4 0x000101
    sw $t4 4100($v1)
    sw $t4 4104($v1)
    sw $t4 5652($v1)
    li $t4 0x000201
    sw $t4 3620($v1)
    sw $t4 4132($v1)
    li $t4 0x0b0507
    sw $t4 12($v1)
    li $t4 0x451322
    sw $t4 16($v1)
    li $t4 0x292123
    sw $t4 20($v1)
    li $t4 0x0e100f
    sw $t4 24($v1)
    li $t4 0x101010
    sw $t4 520($v1)
    li $t4 0x312e30
    sw $t4 524($v1)
    li $t4 0x72283e
    sw $t4 528($v1)
    li $t4 0x5d3a45
    sw $t4 532($v1)
    li $t4 0x474c4a
    sw $t4 536($v1)
    li $t4 0x060606
    sw $t4 540($v1)
    li $t4 0x141514
    sw $t4 1032($v1)
    li $t4 0x33302e
    sw $t4 1036($v1)
    li $t4 0x242e2a
    sw $t4 1040($v1)
    li $t4 0x242828
    sw $t4 1044($v1)
    li $t4 0x585756
    sw $t4 1048($v1)
    li $t4 0x0d0d0c
    sw $t4 1052($v1)
    li $t4 0x030202
    sw $t4 1540($v1)
    li $t4 0x040409
    sw $t4 1544($v1)
    li $t4 0x7d5842
    sw $t4 1548($v1)
    li $t4 0x949c7a
    sw $t4 1552($v1)
    li $t4 0x2a3531
    sw $t4 1556($v1)
    li $t4 0x363435
    sw $t4 1560($v1)
    li $t4 0x767085
    sw $t4 1564($v1)
    li $t4 0x4f4860
    sw $t4 1568($v1)
    li $t4 0x12101a
    sw $t4 2056($v1)
    li $t4 0x524159
    sw $t4 2060($v1)
    li $t4 0x8f827f
    sw $t4 2064($v1)
    li $t4 0x2f2a2b
    sw $t4 2068($v1)
    li $t4 0x232327
    sw $t4 2072($v1)
    li $t4 0xd0c4f2
    sw $t4 2076($v1)
    li $t4 0x8e84aa
    sw $t4 2080($v1)
    li $t4 0x4e5469
    sw $t4 2572($v1)
    li $t4 0x632648
    sw $t4 2576($v1)
    li $t4 0x29343a
    sw $t4 2580($v1)
    li $t4 0x110b1a
    sw $t4 2584($v1)
    li $t4 0x8f87a4
    sw $t4 2588($v1)
    li $t4 0xb4abd1
    sw $t4 2592($v1)
    li $t4 0x020102
    sw $t4 3076($v1)
    li $t4 0x010001
    sw $t4 3080($v1)
    li $t4 0x15141d
    sw $t4 3084($v1)
    li $t4 0x9e4990
    sw $t4 3088($v1)
    li $t4 0x4e5a54
    sw $t4 3092($v1)
    li $t4 0x103524
    sw $t4 3096($v1)
    li $t4 0x08050a
    sw $t4 3100($v1)
    li $t4 0x120f17
    sw $t4 3104($v1)
    li $t4 0x030203
    sw $t4 3588($v1)
    li $t4 0x665987
    sw $t4 3596($v1)
    li $t4 0x7095b9
    sw $t4 3600($v1)
    li $t4 0x006c47
    sw $t4 3604($v1)
    li $t4 0x00704d
    sw $t4 3608($v1)
    li $t4 0x002216
    sw $t4 3612($v1)
    li $t4 0x0d5544
    sw $t4 4108($v1)
    li $t4 0x00ac61
    sw $t4 4112($v1)
    li $t4 0x018552
    sw $t4 4116($v1)
    li $t4 0x016145
    sw $t4 4120($v1)
    li $t4 0x012117
    sw $t4 4124($v1)
    li $t4 0x0a0b0a
    sw $t4 4620($v1)
    li $t4 0x484c67
    sw $t4 4624($v1)
    li $t4 0x101e22
    sw $t4 4628($v1)
    li $t4 0x000a07
    sw $t4 4632($v1)
    li $t4 0x010000
    sw $t4 4636($v1)
    li $t4 0x050101
    sw $t4 5132($v1)
    li $t4 0x100100
    sw $t4 5136($v1)
    li $t4 0x020000
    sw $t4 5140($v1)
    li $t4 0x000100
    sw $t4 5656($v1)
    jr $ra
draw_doll_03_19: # start at v1, use t4
    draw16($0, 0, 8, 24, 28, 32, 36, 512, 548, 1056, 1572, 2084, 2596, 3072, 3108, 3620, 4100)
    draw16($0, 4124, 4132, 4608, 4636, 4644, 5120, 5128, 5144, 5148, 5152, 5156, 5632, 5636, 5640, 5644, 5648)
    sw $0 5660($v1)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x010101
    sw $t4 4($v1)
    sw $t4 1060($v1)
    sw $t4 4612($v1)
    li $t4 0x000100
    sw $t4 516($v1)
    sw $t4 4128($v1)
    sw $t4 4640($v1)
    li $t4 0x000302
    sw $t4 12($v1)
    sw $t4 5652($v1)
    li $t4 0x000201
    sw $t4 520($v1)
    sw $t4 4096($v1)
    li $t4 0x131119
    sw $t4 1568($v1)
    sw $t4 2080($v1)
    li $t4 0x000101
    sw $t4 3584($v1)
    sw $t4 5656($v1)
    li $t4 0x130c0e
    sw $t4 16($v1)
    li $t4 0x1d0f13
    sw $t4 20($v1)
    li $t4 0x312f2f
    sw $t4 524($v1)
    li $t4 0x7e2642
    sw $t4 528($v1)
    li $t4 0x622538
    sw $t4 532($v1)
    li $t4 0x262b2a
    sw $t4 536($v1)
    li $t4 0x080708
    sw $t4 540($v1)
    li $t4 0x010001
    sw $t4 544($v1)
    li $t4 0x040304
    sw $t4 1024($v1)
    li $t4 0x000002
    sw $t4 1028($v1)
    li $t4 0x171816
    sw $t4 1032($v1)
    li $t4 0x454447
    sw $t4 1036($v1)
    li $t4 0x2b2529
    sw $t4 1040($v1)
    li $t4 0x1c2020
    sw $t4 1044($v1)
    li $t4 0x3e3c3c
    sw $t4 1048($v1)
    li $t4 0x121211
    sw $t4 1052($v1)
    li $t4 0x1a1622
    sw $t4 1536($v1)
    li $t4 0xb3a9cf
    sw $t4 1540($v1)
    li $t4 0x464452
    sw $t4 1544($v1)
    li $t4 0x4c3026
    sw $t4 1548($v1)
    li $t4 0x586d56
    sw $t4 1552($v1)
    li $t4 0xb39977
    sw $t4 1556($v1)
    li $t4 0x2c3a35
    sw $t4 1560($v1)
    li $t4 0x403b4b
    sw $t4 1564($v1)
    li $t4 0x17141f
    sw $t4 2048($v1)
    li $t4 0xede1ff
    sw $t4 2052($v1)
    li $t4 0x625775
    sw $t4 2056($v1)
    li $t4 0x30131d
    sw $t4 2060($v1)
    li $t4 0xafa091
    sw $t4 2064($v1)
    li $t4 0xb9a58c
    sw $t4 2068($v1)
    li $t4 0x2e292b
    sw $t4 2072($v1)
    li $t4 0x413550
    sw $t4 2076($v1)
    li $t4 0x030405
    sw $t4 2560($v1)
    li $t4 0x3f3b46
    sw $t4 2564($v1)
    li $t4 0x2a4042
    sw $t4 2568($v1)
    li $t4 0x327372
    sw $t4 2572($v1)
    li $t4 0x9467a0
    sw $t4 2576($v1)
    li $t4 0x6d5273
    sw $t4 2580($v1)
    li $t4 0x596f85
    sw $t4 2584($v1)
    li $t4 0x25303f
    sw $t4 2588($v1)
    li $t4 0x0a070c
    sw $t4 2592($v1)
    li $t4 0x050000
    sw $t4 3076($v1)
    li $t4 0x615954
    sw $t4 3080($v1)
    li $t4 0x004539
    sw $t4 3084($v1)
    li $t4 0x89366e
    sw $t4 3088($v1)
    li $t4 0x772f5c
    sw $t4 3092($v1)
    li $t4 0x052d24
    sw $t4 3096($v1)
    li $t4 0x3a3c2a
    sw $t4 3100($v1)
    li $t4 0x0e0202
    sw $t4 3104($v1)
    li $t4 0x070405
    sw $t4 3588($v1)
    li $t4 0x051307
    sw $t4 3592($v1)
    li $t4 0x246261
    sw $t4 3596($v1)
    li $t4 0xcfb8ef
    sw $t4 3600($v1)
    li $t4 0xa9a9db
    sw $t4 3604($v1)
    li $t4 0x02211a
    sw $t4 3608($v1)
    li $t4 0x080000
    sw $t4 3612($v1)
    li $t4 0x020303
    sw $t4 3616($v1)
    li $t4 0x00291a
    sw $t4 4104($v1)
    li $t4 0x0b7859
    sw $t4 4108($v1)
    li $t4 0x7eb1b4
    sw $t4 4112($v1)
    li $t4 0x34cf94
    sw $t4 4116($v1)
    li $t4 0x007844
    sw $t4 4120($v1)
    li $t4 0x000303
    sw $t4 4616($v1)
    li $t4 0x223e47
    sw $t4 4620($v1)
    li $t4 0x1b5957
    sw $t4 4624($v1)
    li $t4 0x004724
    sw $t4 4628($v1)
    li $t4 0x00190f
    sw $t4 4632($v1)
    li $t4 0x010000
    sw $t4 5124($v1)
    li $t4 0x17070d
    sw $t4 5132($v1)
    li $t4 0x220710
    sw $t4 5136($v1)
    li $t4 0x030000
    sw $t4 5140($v1)
    jr $ra
draw_doll_03_20: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 20, 28, 32, 36, 520, 536, 540, 544, 548, 1024, 1028)
    draw16($0, 1052, 1056, 1060, 1568, 2084, 2596, 3072, 3108, 3616, 3620, 4132, 4612, 4644, 5124, 5148, 5156)
    draw4($0, 5632, 5636, 5656, 5660)
    sw $0 5664($v1)
    sw $0 5668($v1)
    li $t4 0x000101
    draw4($t4, 4096, 4128, 4608, 5120)
    li $t4 0x010101
    sw $t4 24($v1)
    sw $t4 1572($v1)
    li $t4 0x020203
    sw $t4 512($v1)
    sw $t4 516($v1)
    li $t4 0x010102
    sw $t4 2080($v1)
    sw $t4 3104($v1)
    li $t4 0x010000
    sw $t4 4636($v1)
    sw $t4 5652($v1)
    li $t4 0x000302
    sw $t4 524($v1)
    li $t4 0x0b0b0b
    sw $t4 528($v1)
    li $t4 0x0d0809
    sw $t4 532($v1)
    li $t4 0x060a09
    sw $t4 1032($v1)
    li $t4 0x402e33
    sw $t4 1036($v1)
    li $t4 0x841e3c
    sw $t4 1040($v1)
    li $t4 0x492531
    sw $t4 1044($v1)
    li $t4 0x181e1c
    sw $t4 1048($v1)
    li $t4 0x3b3649
    sw $t4 1536($v1)
    li $t4 0x322d3f
    sw $t4 1540($v1)
    li $t4 0x1d1f1d
    sw $t4 1544($v1)
    li $t4 0x474246
    sw $t4 1548($v1)
    li $t4 0x342a2e
    sw $t4 1552($v1)
    li $t4 0x221f20
    sw $t4 1556($v1)
    li $t4 0x4e4d4d
    sw $t4 1560($v1)
    li $t4 0x121213
    sw $t4 1564($v1)
    li $t4 0xa094be
    sw $t4 2048($v1)
    li $t4 0xe1d7fc
    sw $t4 2052($v1)
    li $t4 0x38393e
    sw $t4 2056($v1)
    li $t4 0x533b32
    sw $t4 2060($v1)
    li $t4 0x4e6355
    sw $t4 2064($v1)
    li $t4 0x9e8557
    sw $t4 2068($v1)
    li $t4 0x27251e
    sw $t4 2072($v1)
    li $t4 0x27232f
    sw $t4 2076($v1)
    li $t4 0x69617e
    sw $t4 2560($v1)
    li $t4 0xd9ccf2
    sw $t4 2564($v1)
    li $t4 0x3f3350
    sw $t4 2568($v1)
    li $t4 0x522e2f
    sw $t4 2572($v1)
    li $t4 0xaaab8c
    sw $t4 2576($v1)
    li $t4 0xc1a692
    sw $t4 2580($v1)
    li $t4 0x221819
    sw $t4 2584($v1)
    li $t4 0x1e1b27
    sw $t4 2588($v1)
    li $t4 0x030204
    sw $t4 2592($v1)
    li $t4 0x342e43
    sw $t4 3076($v1)
    li $t4 0x1c3a3a
    sw $t4 3080($v1)
    li $t4 0x5c8095
    sw $t4 3084($v1)
    li $t4 0x9671a7
    sw $t4 3088($v1)
    li $t4 0x9f88b4
    sw $t4 3092($v1)
    li $t4 0x2c3949
    sw $t4 3096($v1)
    li $t4 0x08080c
    sw $t4 3100($v1)
    li $t4 0x010202
    sw $t4 3584($v1)
    li $t4 0x120906
    sw $t4 3588($v1)
    li $t4 0x354f3c
    sw $t4 3592($v1)
    li $t4 0x154e53
    sw $t4 3596($v1)
    li $t4 0x983b7a
    sw $t4 3600($v1)
    li $t4 0x571f3a
    sw $t4 3604($v1)
    li $t4 0x394533
    sw $t4 3608($v1)
    li $t4 0x050302
    sw $t4 3612($v1)
    li $t4 0x0e0707
    sw $t4 4100($v1)
    li $t4 0x0c2717
    sw $t4 4104($v1)
    li $t4 0x2d626f
    sw $t4 4108($v1)
    li $t4 0xc6a7e9
    sw $t4 4112($v1)
    li $t4 0x8d84bb
    sw $t4 4116($v1)
    li $t4 0x281f1a
    sw $t4 4120($v1)
    li $t4 0x060102
    sw $t4 4124($v1)
    li $t4 0x004528
    sw $t4 4616($v1)
    li $t4 0x30877a
    sw $t4 4620($v1)
    li $t4 0xd8d0f4
    sw $t4 4624($v1)
    li $t4 0x5eafb2
    sw $t4 4628($v1)
    li $t4 0x003d20
    sw $t4 4632($v1)
    li $t4 0x000201
    sw $t4 4640($v1)
    li $t4 0x061210
    sw $t4 5128($v1)
    li $t4 0x205254
    sw $t4 5132($v1)
    li $t4 0x175751
    sw $t4 5136($v1)
    li $t4 0x00532f
    sw $t4 5140($v1)
    li $t4 0x02120a
    sw $t4 5144($v1)
    li $t4 0x000100
    sw $t4 5152($v1)
    li $t4 0x090203
    sw $t4 5640($v1)
    li $t4 0x280f1c
    sw $t4 5644($v1)
    li $t4 0x130105
    sw $t4 5648($v1)
    jr $ra
draw_doll_03_21: # start at v1, use t4
    draw16($0, 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 512, 516, 520, 536, 540, 544)
    draw16($0, 548, 1028, 1032, 1036, 1048, 1052, 1056, 1060, 1536, 1568, 1572, 2052, 2076, 2080, 2084, 2596)
    draw4($0, 3616, 4096, 4124, 4128)
    draw4($0, 4132, 4632, 4640, 4644)
    sw $0 5124($v1)
    sw $0 5156($v1)
    sw $0 5668($v1)
    li $t4 0x010101
    draw4($t4, 524, 2592, 3104, 3108)
    li $t4 0x000101
    sw $t4 1544($v1)
    sw $t4 5120($v1)
    sw $t4 5632($v1)
    li $t4 0x020000
    sw $t4 528($v1)
    sw $t4 5148($v1)
    li $t4 0x010000
    sw $t4 532($v1)
    sw $t4 5660($v1)
    li $t4 0x000201
    sw $t4 5152($v1)
    sw $t4 5664($v1)
    li $t4 0x020202
    sw $t4 1024($v1)
    li $t4 0x000200
    sw $t4 1040($v1)
    li $t4 0x000100
    sw $t4 1044($v1)
    li $t4 0x020201
    sw $t4 1540($v1)
    li $t4 0x201a1c
    sw $t4 1548($v1)
    li $t4 0x61172d
    sw $t4 1552($v1)
    li $t4 0x3c1c25
    sw $t4 1556($v1)
    li $t4 0x050908
    sw $t4 1560($v1)
    li $t4 0x010102
    sw $t4 1564($v1)
    li $t4 0x2c2736
    sw $t4 2048($v1)
    li $t4 0x151916
    sw $t4 2056($v1)
    li $t4 0x524147
    sw $t4 2060($v1)
    li $t4 0x622a3a
    sw $t4 2064($v1)
    li $t4 0x30262d
    sw $t4 2068($v1)
    li $t4 0x343635
    sw $t4 2072($v1)
    li $t4 0xcdc1ef
    sw $t4 2560($v1)
    li $t4 0x988eb3
    sw $t4 2564($v1)
    li $t4 0x2d2b32
    sw $t4 2568($v1)
    li $t4 0x3b3633
    sw $t4 2572($v1)
    li $t4 0x182b29
    sw $t4 2576($v1)
    li $t4 0x615038
    sw $t4 2580($v1)
    li $t4 0x211d1b
    sw $t4 2584($v1)
    li $t4 0x252031
    sw $t4 2588($v1)
    li $t4 0xbaafd9
    sw $t4 3072($v1)
    li $t4 0xf5e7ff
    sw $t4 3076($v1)
    li $t4 0x2d293e
    sw $t4 3080($v1)
    li $t4 0x572d1f
    sw $t4 3084($v1)
    li $t4 0x9aa881
    sw $t4 3088($v1)
    li $t4 0xcaae7a
    sw $t4 3092($v1)
    li $t4 0x1a1d1d
    sw $t4 3096($v1)
    li $t4 0x4b4067
    sw $t4 3100($v1)
    li $t4 0x19171e
    sw $t4 3584($v1)
    li $t4 0x6d6581
    sw $t4 3588($v1)
    li $t4 0x0d1119
    sw $t4 3592($v1)
    li $t4 0x60637c
    sw $t4 3596($v1)
    li $t4 0x9e8da6
    sw $t4 3600($v1)
    li $t4 0x998ea4
    sw $t4 3604($v1)
    li $t4 0x5b625c
    sw $t4 3608($v1)
    li $t4 0x403753
    sw $t4 3612($v1)
    li $t4 0x020102
    sw $t4 3620($v1)
    li $t4 0x130507
    sw $t4 4100($v1)
    li $t4 0x376a58
    sw $t4 4104($v1)
    li $t4 0x316d72
    sw $t4 4108($v1)
    li $t4 0x9c4787
    sw $t4 4112($v1)
    li $t4 0x683652
    sw $t4 4116($v1)
    li $t4 0x372624
    sw $t4 4120($v1)
    li $t4 0x010202
    sw $t4 4608($v1)
    li $t4 0x281916
    sw $t4 4612($v1)
    li $t4 0x2e3228
    sw $t4 4616($v1)
    li $t4 0x154754
    sw $t4 4620($v1)
    li $t4 0xa572b6
    sw $t4 4624($v1)
    li $t4 0x6f4f7e
    sw $t4 4628($v1)
    li $t4 0x020203
    sw $t4 4636($v1)
    li $t4 0x003e21
    sw $t4 5128($v1)
    li $t4 0x377a7f
    sw $t4 5132($v1)
    li $t4 0xfadeff
    sw $t4 5136($v1)
    li $t4 0x8cafce
    sw $t4 5140($v1)
    li $t4 0x022918
    sw $t4 5144($v1)
    li $t4 0x020101
    sw $t4 5636($v1)
    li $t4 0x022c1d
    sw $t4 5640($v1)
    li $t4 0x0e6c54
    sw $t4 5644($v1)
    li $t4 0x69b09f
    sw $t4 5648($v1)
    li $t4 0x1ea271
    sw $t4 5652($v1)
    li $t4 0x00301a
    sw $t4 5656($v1)
    jr $ra
clear_doll: # start at v1, use t4
    lw $v1 doll_address
    draw64($0, 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 512, 516, 520, 524, 528, 532, 536, 540, 544, 548, 1024, 1028, 1032, 1036, 1040, 1044, 1048, 1052, 1056, 1060, 1536, 1540, 1544, 1548, 1552, 1556, 1560, 1564, 1568, 1572, 2048, 2052, 2056, 2060, 2064, 2068, 2072, 2076, 2080, 2084, 2560, 2564, 2568, 2572, 2576, 2580, 2584, 2588, 2592, 2596, 3072, 3076, 3080, 3084)
    draw16($0, 3088, 3092, 3096, 3100, 3104, 3108, 3584, 3588, 3592, 3596, 3600, 3604, 3608, 3612, 3616, 3620)
    draw16($0, 4096, 4100, 4104, 4108, 4112, 4116, 4120, 4124, 4128, 4132, 4608, 4612, 4616, 4620, 4624, 4628)
    draw16($0, 4632, 4636, 4640, 4644, 5120, 5124, 5128, 5132, 5136, 5140, 5144, 5148, 5152, 5156, 5632, 5636)
    draw4($0, 5640, 5644, 5648, 5652)
    draw4($0, 5656, 5660, 5664, 5668)
    jr $ra

draw_clear: # a1 == 4 for outwards, a1 == -4 for inwards, use v1 a0 t4
    addi $sp $sp -4 # push ra to stack
    sw $ra 0($sp)

    # t0 = &clears[0], t1 = &clears[-1]
    # t2 = current, a1 = dt2
    la $t0 clears
    addi $t1 $t0 CLEAR_FRAME
    subi $t1 $t1 4 # points to last frame
    addi $v1 $a1 4
    movn $t2 $t0 $v1 # out
    movz $t2 $t1 $v1 # in

    li $v1 BASE_ADDRESS
    li $a0 REFRESH_RATE
    sra $a0 $a0 1 # 2x speed
    li $v0 32
    draw_clear_loop:
        blt $t2 $t0 draw_clear_end
        bgt $t2 $t1 draw_clear_end
        li $t4 0xfad053

        lw $t3 0($t2)
        jalr $t3

        add $t2 $t2 $a1
        j draw_clear_loop
    draw_clear_end:
    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4
    jr $ra # return
    draw_clear_00: # draw t4, sleep, draw 0
        sw $t4 32512($v1)
        sw $t4 33020($v1)
        sw $t4 33024($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_00
    draw_clear_01: # draw t4, sleep, draw 0
        sw $t4 32508($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_01
    draw_clear_02: # draw t4, sleep, draw 0
        draw4($t4, 31992, 31996, 32000, 32504)
        sw $t4 33016($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_02
    draw_clear_03: # draw t4, sleep, draw 0
        draw4($t4, 31484, 32516, 32520, 33012)
        draw4($t4, 33028, 33532, 33536, 34048)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_03
    draw_clear_04: # draw t4, sleep, draw 0
        draw4($t4, 30976, 31492, 32008, 32524)
        draw4($t4, 33008, 33032, 33036, 33524)
        draw4($t4, 33540, 33544, 34040, 34052)
        sw $t4 34556($v1)
        sw $t4 34560($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_04
    draw_clear_05: # draw t4, sleep, draw 0
        draw4($t4, 30972, 31480, 31488, 31988)
        draw4($t4, 32004, 32496, 32500, 33528)
        sw $t4 34044($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_05
    draw_clear_06: # draw t4, sleep, draw 0
        draw4($t4, 30464, 30980, 31496, 32012)
        draw4($t4, 32528, 33004, 33040, 33520)
        draw4($t4, 33548, 34036, 34056, 34552)
        sw $t4 34564($v1)
        sw $t4 35068($v1)
        sw $t4 35072($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_06
    draw_clear_07: # draw t4, sleep, draw 0
        draw4($t4, 30460, 30968, 31476, 31984)
        sw $t4 32492($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_07
    draw_clear_08: # draw t4, sleep, draw 0
        draw16($t4, 29444, 29956, 30472, 30988, 32016, 32532, 33000, 33552, 33556, 33560, 34060, 34064, 34544, 34568, 34572, 35060)
        draw4($t4, 35076, 35580, 35584, 36088)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_08
    draw_clear_09: # draw t4, sleep, draw 0
        draw16($t4, 29440, 29948, 29952, 30452, 30456, 30468, 30960, 30964, 30984, 31468, 31472, 31500, 31972, 31976, 31980, 32488)
        draw4($t4, 33044, 33516, 34032, 34548)
        sw $t4 35064($v1)
        sw $t4 35576($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_09
    draw_clear_10: # draw t4, sleep, draw 0
        draw16($t4, 28936, 29448, 29964, 30992, 32020, 33048, 34068, 34072, 34076, 34576, 34580, 35080, 35084, 35568, 35588, 36092)
        sw $t4 36596($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_10
    draw_clear_11: # draw t4, sleep, draw 0
        draw16($t4, 28932, 29436, 29940, 29944, 29960, 30444, 30448, 30476, 30952, 30956, 31456, 31460, 31464, 31504, 32484, 33512)
        draw4($t4, 34028, 34540, 35056, 35572)
        sw $t4 36084($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_11
    draw_clear_12: # draw t4, sleep, draw 0
        draw16($t4, 28428, 28432, 28944, 29456, 29928, 29968, 29972, 30428, 30484, 30996, 31512, 32024, 33052, 33564, 34020, 34588)
        draw16($t4, 34592, 35048, 35088, 35092, 35096, 35100, 35104, 35560, 35592, 35596, 35600, 35604, 36096, 36100, 36104, 36588)
        draw4($t4, 36600, 36604, 37100, 37104)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_12
    draw_clear_13: # draw t4, sleep, draw 0
        draw16($t4, 28424, 28924, 28928, 28940, 29428, 29432, 29452, 29932, 29936, 30432, 30436, 30440, 30480, 30940, 30944, 30948)
        draw4($t4, 31508, 31968, 32480, 32536)
        draw4($t4, 32996, 33508, 34024, 34536)
        draw4($t4, 34584, 35052, 35564, 36076)
        sw $t4 36080($v1)
        sw $t4 36592($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_13
    draw_clear_14: # draw t4, sleep, draw 0
        draw16($t4, 27920, 28416, 28420, 28916, 28920, 29412, 29416, 29420, 29424, 29460, 29912, 29916, 29920, 29924, 31452, 31964)
        draw4($t4, 32992, 33504, 34532, 35044)
        draw4($t4, 35556, 36072, 36584, 37096)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_14
    draw_clear_15: # draw t4, sleep, draw 0
        draw16($t4, 27908, 27912, 27916, 27924, 28400, 28404, 28408, 28412, 28436, 28440, 28892, 28896, 28900, 28904, 28908, 28912)
        draw16($t4, 28948, 28952, 29400, 29404, 29408, 29464, 29976, 30424, 30488, 30936, 31000, 31004, 31448, 31516, 32028, 32476)
        draw16($t4, 32540, 32988, 33500, 33568, 34012, 34016, 34080, 34528, 35040, 35552, 35608, 35612, 35616, 36064, 36068, 36108)
        draw4($t4, 36112, 36116, 36120, 36124)
        draw4($t4, 36576, 36580, 36608, 36612)
        sw $t4 36616($v1)
        sw $t4 37092($v1)
        sw $t4 37108($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_15
    draw_clear_16: # draw t4, sleep, draw 0
        draw64($t4, 27404, 27408, 27412, 27416, 27420, 27884, 27888, 27892, 27896, 27900, 27904, 27928, 27932, 28372, 28376, 28380, 28384, 28388, 28392, 28396, 28444, 28884, 28888, 28956, 29396, 29468, 29908, 29980, 30420, 30492, 30496, 31008, 31520, 31960, 32032, 32472, 32544, 32984, 33056, 33496, 34008, 34520, 34524, 34596, 35036, 35108, 35548, 35620, 36060, 36128, 36132, 36572, 36620, 36624, 36628, 36632, 36636, 36640, 36644, 37084, 37088, 37112, 37116, 37120)
        draw4($t4, 37124, 37128, 37132, 37596)
        draw4($t4, 37600, 37604, 37608, 37612)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_16
    draw_clear_17: # draw t4, sleep, draw 0
        draw64($t4, 26908, 26912, 27360, 27364, 27368, 27372, 27376, 27380, 27384, 27388, 27392, 27396, 27400, 27424, 27856, 27860, 27864, 27868, 27872, 27876, 27880, 27936, 28368, 28448, 28960, 28964, 29472, 29476, 29984, 29988, 30500, 30932, 31012, 31444, 31524, 31956, 32036, 32468, 32548, 32980, 33060, 33492, 33572, 34004, 34084, 34516, 35028, 35032, 35540, 35544, 36052, 36056, 36568, 36648, 37080, 37136, 37140, 37144, 37148, 37152, 37156, 37160, 37592, 37616)
        draw4($t4, 37620, 37624, 37628, 37632)
        draw4($t4, 37636, 37640, 37644, 37648)
        draw4($t4, 37652, 37656, 38104, 38108)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_17
    draw_clear_18: # draw t4, sleep, draw 0
        draw64($t4, 26832, 26836, 26840, 26844, 26848, 26852, 26856, 26860, 26864, 26868, 26872, 26876, 26880, 26884, 26888, 26892, 26896, 26900, 26904, 26916, 26920, 27344, 27348, 27352, 27356, 27428, 27432, 27940, 27944, 28452, 28456, 28880, 28968, 29392, 29480, 29904, 29992, 30416, 30504, 30928, 31016, 31440, 31528, 31952, 32040, 32464, 32552, 32976, 33064, 33488, 33576, 34000, 34088, 34512, 34600, 35024, 35112, 35536, 35624, 36048, 36136, 36560, 36564, 37072)
        draw16($t4, 37076, 37584, 37588, 37660, 37664, 37668, 37672, 38096, 38100, 38112, 38116, 38120, 38124, 38128, 38132, 38136)
        draw4($t4, 38140, 38144, 38148, 38152)
        draw4($t4, 38156, 38160, 38164, 38168)
        draw4($t4, 38172, 38176, 38180, 38184)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_18
    draw_clear_19: # draw t4, sleep, draw 0
        draw64($t4, 25808, 25812, 25816, 25820, 26320, 26324, 26328, 26332, 26336, 26340, 26344, 26348, 26352, 26356, 26360, 26364, 26368, 26372, 26376, 26380, 26384, 26388, 26392, 26396, 26924, 26928, 27436, 27440, 27948, 27952, 28364, 28460, 28464, 28876, 28972, 29388, 29484, 29900, 29996, 30412, 30508, 30924, 31020, 31436, 31532, 31948, 32044, 32460, 32556, 32972, 33068, 33484, 33580, 33996, 34092, 34508, 34604, 35020, 35116, 35532, 35628, 36044, 36140, 36552)
        draw16($t4, 36556, 36652, 37064, 37068, 37576, 37580, 38088, 38092, 38620, 38624, 38628, 38632, 38636, 38640, 38644, 38648)
        draw16($t4, 38652, 38656, 38660, 38664, 38668, 38672, 38676, 38680, 38684, 38688, 38692, 38696, 39196, 39200, 39204, 39208)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_19
    draw_clear_20: # draw t4, sleep, draw 0
        draw64($t4, 24784, 25296, 25300, 25304, 25308, 25312, 25316, 25320, 25324, 25328, 25824, 25828, 25832, 25836, 25840, 25844, 25848, 25852, 25856, 25860, 25864, 25868, 26316, 26400, 26404, 26408, 26412, 26828, 26932, 26936, 27340, 27444, 27852, 27956, 28468, 28976, 28980, 29488, 29492, 30000, 30004, 30408, 30512, 30516, 30920, 31024, 31028, 31432, 31536, 31944, 32048, 32456, 32560, 32968, 33072, 33480, 33584, 33988, 33992, 34096, 34500, 34504, 34608, 35012)
        draw16($t4, 35016, 35524, 35528, 36036, 36040, 36548, 37060, 37164, 37572, 37676, 38080, 38084, 38188, 38604, 38608, 38612)
        draw16($t4, 38616, 38700, 39148, 39152, 39156, 39160, 39164, 39168, 39172, 39176, 39180, 39184, 39188, 39192, 39688, 39692)
        draw4($t4, 39696, 39700, 39704, 39708)
        draw4($t4, 39712, 39716, 39720, 40232)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_20
    draw_clear_21: # draw t4, sleep, draw 0
        draw64($t4, 24272, 24276, 24280, 24284, 24288, 24788, 24792, 24796, 24800, 24804, 24808, 24812, 24816, 24820, 25332, 25336, 25340, 25344, 25348, 25352, 25804, 25872, 25876, 25880, 25884, 26416, 26940, 27448, 27452, 27960, 27964, 28360, 28472, 28476, 28872, 28984, 28988, 29384, 29496, 29896, 30008, 30520, 30916, 31032, 31428, 31540, 31544, 31940, 32052, 32452, 32564, 32964, 33076, 33472, 33476, 33588, 33984, 34100, 34496, 35008, 35120, 35520, 35632, 36028)
        draw16($t4, 36032, 36144, 36540, 36544, 36656, 37052, 37056, 37564, 37568, 38076, 38600, 39132, 39136, 39140, 39144, 39212)
        draw16($t4, 39664, 39668, 39672, 39676, 39680, 39684, 40196, 40200, 40204, 40208, 40212, 40216, 40220, 40224, 40228, 40728)
        draw4($t4, 40732, 40736, 40740, 40744)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_21
    draw_clear_22: # draw t4, sleep, draw 0
        draw64($t4, 23248, 23252, 23256, 23260, 23760, 23764, 23768, 23772, 23776, 23780, 23784, 23788, 24292, 24296, 24300, 24304, 24308, 24312, 24316, 24780, 24824, 24828, 24832, 24836, 24840, 25292, 25356, 25360, 25364, 25368, 25888, 25892, 25896, 26420, 26424, 26824, 26944, 26948, 27336, 27456, 27460, 27848, 27968, 27972, 28480, 28484, 28868, 28992, 29380, 29500, 29504, 29892, 30012, 30016, 30404, 30524, 30528, 30912, 31036, 31424, 31548, 31936, 32056, 32060)
        draw64($t4, 32444, 32448, 32568, 32572, 32956, 32960, 33080, 33468, 33592, 33980, 34104, 34488, 34492, 34612, 35000, 35004, 35124, 35512, 35516, 35636, 36024, 36148, 36532, 36536, 37044, 37048, 37168, 37556, 37560, 37680, 38068, 38072, 38192, 38592, 38596, 39120, 39124, 39128, 39648, 39652, 39656, 39660, 39724, 40176, 40180, 40184, 40188, 40192, 40236, 40700, 40704, 40708, 40712, 40716, 40720, 40724, 41228, 41232, 41236, 41240, 41244, 41248, 41252, 41256)
        draw4($t4, 41756, 41760, 41764, 41768)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_22
    draw_clear_23: # draw t4, sleep, draw 0
        draw64($t4, 21716, 22228, 22232, 22236, 22740, 22744, 22748, 22752, 22756, 22760, 23264, 23268, 23272, 23276, 23280, 23284, 23792, 23796, 23800, 23804, 23808, 24320, 24324, 24328, 24332, 24844, 24848, 24852, 24856, 25372, 25376, 25380, 25900, 25904, 26312, 26428, 26952, 27464, 27468, 27472, 27476, 27844, 27976, 27980, 27984, 28356, 28488, 28492, 28496, 28996, 29000, 29004, 29376, 29508, 29512, 29516, 29888, 30020, 30024, 30028, 30400, 30532, 30536, 30908)
        draw64($t4, 31040, 31044, 31048, 31420, 31552, 31556, 31560, 31932, 32064, 32068, 32440, 32576, 32580, 32952, 33084, 33088, 33092, 33464, 33596, 33600, 33972, 33976, 34108, 34112, 34484, 34616, 34620, 34624, 34996, 35128, 35132, 35504, 35508, 35640, 35644, 36016, 36020, 36152, 36156, 36528, 36660, 36664, 37036, 37040, 37172, 37176, 37548, 37552, 37684, 37688, 38056, 38060, 38064, 38196, 38580, 38584, 38588, 38704, 38708, 39104, 39108, 39112, 39116, 39216)
        draw16($t4, 39220, 39628, 39632, 39636, 39640, 39644, 39728, 40152, 40156, 40160, 40164, 40168, 40172, 40240, 40676, 40680)
        draw16($t4, 40684, 40688, 40692, 40696, 40748, 40752, 41200, 41204, 41208, 41212, 41216, 41220, 41224, 41260, 41724, 41728)
        draw16($t4, 41732, 41736, 41740, 41744, 41748, 41752, 41772, 42248, 42252, 42256, 42260, 42264, 42268, 42272, 42276, 42280)
        draw4($t4, 42284, 42772, 42776, 42780)
        draw4($t4, 42784, 42788, 42792, 43296)
        sw $t4 43300($v1)
        sw $t4 43304($v1)
        sw $t4 43816($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_23
    draw_clear_24: # draw t4, sleep, draw 0
        draw64($t4, 20180, 20692, 20696, 20700, 21204, 21208, 21212, 21216, 21220, 21224, 21712, 21720, 21724, 21728, 21732, 21736, 21740, 21744, 22224, 22240, 22244, 22248, 22252, 22256, 22260, 22264, 22268, 22732, 22736, 22764, 22768, 22772, 22776, 22780, 22784, 22788, 23244, 23288, 23292, 23296, 23300, 23304, 23308, 23756, 23812, 23816, 23820, 23824, 23828, 23832, 24264, 24268, 24336, 24340, 24344, 24348, 24352, 24776, 24860, 24864, 24868, 24872, 24876, 25284)
        draw64($t4, 25288, 25384, 25388, 25392, 25396, 25796, 25800, 25908, 25912, 25916, 26304, 26308, 26432, 26436, 26440, 26816, 26820, 26956, 26960, 27328, 27332, 27480, 27484, 27836, 27840, 27988, 27992, 28348, 28352, 28500, 28504, 28856, 28860, 28864, 29008, 29012, 29368, 29372, 29520, 29524, 29880, 29884, 30032, 30036, 30388, 30392, 30396, 30540, 30544, 30900, 30904, 31052, 31056, 31408, 31412, 31416, 31564, 31920, 31924, 31928, 32072, 32076, 32428, 32432)
        draw64($t4, 32436, 32584, 32588, 32940, 32944, 32948, 33096, 33452, 33456, 33460, 33604, 33608, 33960, 33964, 33968, 34116, 34472, 34476, 34480, 34628, 34980, 34984, 34988, 34992, 35136, 35492, 35496, 35500, 35648, 36004, 36008, 36012, 36160, 36512, 36516, 36520, 36524, 36668, 37024, 37028, 37032, 37180, 37532, 37536, 37540, 37544, 38200, 38576, 38712, 39100, 39620, 39624, 39732, 40140, 40144, 40148, 40664, 40668, 40672, 41184, 41188, 41192, 41196, 41708)
        draw16($t4, 41712, 41716, 41720, 42228, 42232, 42236, 42240, 42244, 42748, 42752, 42756, 42760, 42764, 42768, 43272, 43276)
        draw4($t4, 43280, 43284, 43288, 43292)
        draw4($t4, 43792, 43796, 43800, 43804)
        draw4($t4, 43808, 43812, 44316, 44320)
        sw $t4 44324($v1)
        sw $t4 44836($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_24
    draw_clear_25: # draw t4, sleep, draw 0
        draw64($t4, 19672, 19676, 19680, 19684, 20184, 20188, 20192, 20196, 20200, 20204, 20704, 20708, 20712, 20716, 20720, 20724, 21228, 21232, 21236, 21240, 21244, 21748, 21752, 21756, 21760, 21764, 22272, 22276, 22280, 22284, 22792, 22796, 22800, 22804, 23312, 23316, 23320, 23324, 23752, 23836, 23840, 23844, 24356, 24360, 24364, 24772, 24880, 24884, 25400, 25404, 25792, 25920, 25924, 26444, 26812, 26964, 27324, 27832, 27996, 28000, 28004, 28344, 28508, 28512)
        draw64($t4, 28516, 28852, 29016, 29020, 29024, 29028, 29364, 29528, 29532, 29536, 29540, 29872, 29876, 30040, 30044, 30048, 30384, 30548, 30552, 30556, 30560, 30892, 30896, 31060, 31064, 31068, 31404, 31568, 31572, 31576, 31580, 31912, 31916, 32080, 32084, 32088, 32424, 32592, 32596, 32600, 32932, 32936, 33100, 33104, 33108, 33444, 33448, 33612, 33616, 33620, 33952, 33956, 34120, 34124, 34128, 34464, 34468, 34632, 34636, 34640, 34972, 34976, 35140, 35144)
        draw64($t4, 35148, 35484, 35488, 35652, 35656, 35660, 35992, 35996, 36000, 36164, 36168, 36504, 36508, 36672, 36676, 36680, 37016, 37020, 37184, 37188, 37528, 37692, 37696, 37700, 38048, 38052, 38204, 38208, 38568, 38572, 38716, 38720, 39088, 39092, 39096, 39224, 39228, 39608, 39612, 39616, 39736, 39740, 40128, 40132, 40136, 40244, 40248, 40648, 40652, 40656, 40660, 40756, 40760, 41168, 41172, 41176, 41180, 41264, 41268, 41688, 41692, 41696, 41700, 41704)
        draw16($t4, 41776, 41780, 42208, 42212, 42216, 42220, 42224, 42288, 42728, 42732, 42736, 42740, 42744, 42796, 42800, 43248)
        draw16($t4, 43252, 43256, 43260, 43264, 43268, 43308, 43768, 43772, 43776, 43780, 43784, 43788, 43820, 44288, 44292, 44296)
        draw16($t4, 44300, 44304, 44308, 44312, 44328, 44808, 44812, 44816, 44820, 44824, 44828, 44832, 44840, 45328, 45332, 45336)
        draw4($t4, 45340, 45344, 45348, 45848)
        sw $t4 45852($v1)
        sw $t4 45856($v1)
        sw $t4 45860($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_25
    draw_clear_26: # draw t4, sleep, draw 0
        draw64($t4, 17628, 18140, 18144, 18148, 18648, 18652, 18656, 18660, 18664, 18668, 19160, 19164, 19168, 19172, 19176, 19180, 19184, 19668, 19688, 19692, 19696, 19700, 19704, 20208, 20212, 20216, 20220, 20224, 20688, 20728, 20732, 20736, 20740, 20744, 21196, 21200, 21248, 21252, 21256, 21260, 21708, 21768, 21772, 21776, 21780, 22216, 22220, 22288, 22292, 22296, 22300, 22728, 22808, 22812, 22816, 22820, 23236, 23240, 23328, 23332, 23336, 23744, 23748, 23848)
        draw64($t4, 23852, 23856, 24256, 24260, 24368, 24372, 24376, 24764, 24768, 24888, 24892, 24896, 25276, 25280, 25408, 25412, 25784, 25788, 25928, 25932, 26296, 26300, 26448, 26452, 26804, 26808, 26968, 27312, 27316, 27320, 27488, 27824, 27828, 28008, 28332, 28336, 28340, 28520, 28524, 28528, 28844, 28848, 29032, 29036, 29352, 29356, 29360, 29544, 29548, 29864, 29868, 30052, 30056, 30372, 30376, 30380, 30564, 30568, 30880, 30884, 30888, 31072, 31076, 31392)
        draw64($t4, 31396, 31400, 31584, 31900, 31904, 31908, 32092, 32096, 32412, 32416, 32420, 32604, 32920, 32924, 32928, 33112, 33116, 33432, 33436, 33440, 33624, 33940, 33944, 33948, 34132, 34136, 34448, 34452, 34456, 34460, 34644, 34960, 34964, 34968, 35152, 35468, 35472, 35476, 35480, 35664, 35980, 35984, 35988, 36172, 36488, 36492, 36496, 36500, 36684, 37008, 37012, 37192, 37704, 38212, 38564, 39084, 39232, 39604, 40120, 40124, 40252, 40640, 40644, 41160)
        draw16($t4, 41164, 41272, 41680, 41684, 42196, 42200, 42204, 42716, 42720, 42724, 43236, 43240, 43244, 43756, 43760, 43764)
        draw16($t4, 44272, 44276, 44280, 44284, 44792, 44796, 44800, 44804, 45312, 45316, 45320, 45324, 45832, 45836, 45840, 45844)
        draw4($t4, 46348, 46352, 46356, 46360)
        draw4($t4, 46364, 46368, 46868, 46872)
        sw $t4 46876($v1)
        sw $t4 47388($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_26
    draw_clear_27: # draw t4, sleep, draw 0
        draw256($t4, 16612, 17124, 17128, 17132, 17632, 17636, 17640, 17644, 17648, 18152, 18156, 18160, 18164, 18168, 18672, 18676, 18680, 18684, 19188, 19192, 19196, 19200, 19204, 19708, 19712, 19716, 19720, 20228, 20232, 20236, 20240, 20748, 20752, 20756, 21264, 21268, 21272, 21276, 21784, 21788, 21792, 22304, 22308, 22312, 22724, 22824, 22828, 23340, 23344, 23348, 23860, 23864, 24252, 24380, 24384, 24900, 25272, 25416, 25420, 25780, 25936, 26292, 26456, 26800, 26972, 27308, 27492, 27820, 28328, 28836, 28840, 29040, 29044, 29348, 29552, 29556, 29560, 29564, 29856, 29860, 30060, 30064, 30068, 30072, 30364, 30368, 30572, 30576, 30580, 30584, 30876, 31080, 31084, 31088, 31092, 31384, 31388, 31588, 31592, 31596, 31600, 31892, 31896, 32100, 32104, 32108, 32112, 32404, 32408, 32608, 32612, 32616, 32620, 32912, 32916, 33120, 33124, 33128, 33420, 33424, 33428, 33628, 33632, 33636, 33640, 33932, 33936, 34140, 34144, 34148, 34440, 34444, 34648, 34652, 34656, 34948, 34952, 34956, 35156, 35160, 35164, 35168, 35460, 35464, 35668, 35672, 35676, 35968, 35972, 35976, 36176, 36180, 36184, 36688, 36692, 36696, 37004, 37196, 37200, 37204, 37524, 37708, 37712, 38040, 38044, 38216, 38220, 38224, 38560, 38724, 38728, 38732, 39076, 39080, 39236, 39240, 39596, 39600, 39744, 39748, 39752, 40112, 40116, 40256, 40260, 40632, 40636, 40764, 40768, 41148, 41152, 41156, 41276, 41280, 41668, 41672, 41676, 41784, 41788, 42184, 42188, 42192, 42292, 42296, 42704, 42708, 42712, 42804, 42808, 43220, 43224, 43228, 43232, 43312, 43316, 43740, 43744, 43748, 43752, 43824, 44256, 44260, 44264, 44268, 44332, 44336, 44776, 44780, 44784, 44788, 44844, 45292, 45296, 45300, 45304, 45308, 45352, 45812, 45816, 45820, 45824, 45828, 45864, 46328, 46332, 46336, 46340, 46344, 46372, 46848, 46852, 46856, 46860, 46864, 46880, 47364)
        draw4($t4, 47368, 47372, 47376, 47380)
        draw4($t4, 47384, 47392, 47884, 47888)
        draw4($t4, 47892, 47896, 47900, 48400)
        sw $t4 48404($v1)
        sw $t4 48408($v1)
        sw $t4 48920($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_27
    draw_clear_28: # draw t4, sleep, draw 0
        draw256($t4, 15592, 15596, 15600, 16100, 16104, 16108, 16112, 16116, 16608, 16616, 16620, 16624, 16628, 16632, 17120, 17136, 17140, 17144, 17148, 17152, 17652, 17656, 17660, 17664, 17668, 18136, 18172, 18176, 18180, 18184, 18644, 18688, 18692, 18696, 18700, 18704, 19156, 19208, 19212, 19216, 19220, 19664, 19724, 19728, 19732, 19736, 20172, 20176, 20244, 20248, 20252, 20680, 20684, 20760, 20764, 20768, 20772, 21188, 21192, 21280, 21284, 21288, 21700, 21704, 21796, 21800, 21804, 22208, 22212, 22316, 22320, 22324, 22716, 22720, 22832, 22836, 22840, 23224, 23228, 23232, 23352, 23356, 23736, 23740, 23868, 23872, 23876, 24244, 24248, 24388, 24392, 24752, 24756, 24760, 24904, 24908, 25260, 25264, 25268, 25424, 25428, 25772, 25776, 25940, 25944, 26280, 26284, 26288, 26460, 26788, 26792, 26796, 26976, 27296, 27300, 27304, 27496, 27808, 27812, 27816, 28012, 28316, 28320, 28324, 28824, 28828, 28832, 29048, 29332, 29336, 29340, 29344, 29840, 29844, 29848, 29852, 30076, 30080, 30352, 30356, 30360, 30588, 30592, 30860, 30864, 30868, 30872, 31096, 31100, 31104, 31368, 31372, 31376, 31380, 31604, 31608, 31612, 31876, 31880, 31884, 31888, 32116, 32120, 32388, 32392, 32396, 32400, 32624, 32628, 32896, 32900, 32904, 32908, 33132, 33136, 33140, 33404, 33408, 33412, 33416, 33644, 33648, 33912, 33916, 33920, 33924, 33928, 34152, 34156, 34424, 34428, 34432, 34436, 34660, 34664, 34936, 34940, 34944, 35172, 35176, 35452, 35456, 35680, 35684, 36188, 36192, 36700, 37208, 37520, 37716, 37720, 38228, 38556, 38736, 39072, 39244, 39588, 39592, 39756, 40108, 40264, 40624, 40628, 40772, 41140, 41144, 41660, 41664, 41792, 42176, 42180, 42300, 42692, 42696, 42700, 43212, 43216, 43728, 43732, 43736, 43828, 44244, 44248, 44252, 44764, 44768, 44772, 45280, 45284, 45288, 45796, 45800, 45804, 45808, 46312, 46316)
        draw16($t4, 46320, 46324, 46832, 46836, 46840, 46844, 47348, 47352, 47356, 47360, 47864, 47868, 47872, 47876, 47880, 48384)
        draw4($t4, 48388, 48392, 48396, 48900)
        draw4($t4, 48904, 48908, 48912, 48916)
        sw $t4 49416($v1)
        sw $t4 49420($v1)
        sw $t4 49424($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_28
    draw_clear_29: # draw t4, sleep, draw 0
        draw256($t4, 13556, 14064, 14068, 14072, 14572, 14576, 14580, 14584, 14588, 15080, 15084, 15088, 15092, 15096, 15100, 15104, 15588, 15604, 15608, 15612, 15616, 15620, 16096, 16120, 16124, 16128, 16132, 16136, 16604, 16636, 16640, 16644, 16648, 16652, 17116, 17156, 17160, 17164, 17168, 17624, 17672, 17676, 17680, 17684, 17688, 18132, 18188, 18192, 18196, 18200, 18204, 18640, 18708, 18712, 18716, 18720, 19148, 19152, 19224, 19228, 19232, 19236, 19656, 19660, 19740, 19744, 19748, 19752, 20164, 20168, 20256, 20260, 20264, 20268, 20672, 20676, 20776, 20780, 20784, 21184, 21292, 21296, 21300, 21304, 21692, 21696, 21808, 21812, 21816, 21820, 22200, 22204, 22328, 22332, 22336, 22708, 22712, 22844, 22848, 22852, 23216, 23220, 23360, 23364, 23368, 23724, 23728, 23732, 23880, 23884, 24232, 24236, 24240, 24396, 24400, 24740, 24744, 24748, 24912, 24916, 24920, 25252, 25256, 25432, 25436, 25760, 25764, 25768, 25948, 25952, 26268, 26272, 26276, 26464, 26468, 26776, 26780, 26784, 26980, 26984, 27284, 27288, 27292, 27500, 27792, 27796, 27800, 27804, 28016, 28300, 28304, 28308, 28312, 28532, 28536, 28808, 28812, 28816, 28820, 29052, 29320, 29324, 29328, 29568, 29828, 29832, 29836, 30084, 30336, 30340, 30344, 30348, 30596, 30600, 30844, 30848, 30852, 30856, 31108, 31112, 31116, 31352, 31356, 31360, 31364, 31616, 31620, 31624, 31628, 31632, 31860, 31864, 31868, 31872, 32124, 32128, 32132, 32136, 32140, 32368, 32372, 32376, 32380, 32384, 32632, 32636, 32640, 32644, 32648, 32876, 32880, 32884, 32888, 32892, 33144, 33148, 33152, 33156, 33384, 33388, 33392, 33396, 33400, 33652, 33656, 33660, 33664, 33900, 33904, 33908, 34160, 34164, 34168, 34172, 34416, 34420, 34668, 34672, 34676, 34680, 34932, 35180, 35184, 35188, 35448, 35688, 35692, 35696, 35964, 36196, 36200, 36204, 36208, 36480, 36484, 36704)
        draw64($t4, 36708, 36712, 36716, 37000, 37212, 37216, 37220, 37224, 37516, 37724, 37728, 37732, 38032, 38036, 38232, 38236, 38240, 38548, 38552, 38740, 38744, 38748, 39064, 39068, 39248, 39252, 39256, 39580, 39584, 39760, 39764, 40096, 40100, 40104, 40268, 40272, 40276, 40616, 40620, 40776, 40780, 40784, 41132, 41136, 41284, 41288, 41292, 41648, 41652, 41656, 41796, 41800, 42164, 42168, 42172, 42304, 42308, 42680, 42684, 42688, 42812, 42816, 43196, 43200)
        draw64($t4, 43204, 43208, 43320, 43324, 43712, 43716, 43720, 43724, 43832, 44232, 44236, 44240, 44340, 44344, 44748, 44752, 44756, 44760, 44848, 44852, 45264, 45268, 45272, 45276, 45356, 45360, 45780, 45784, 45788, 45792, 45868, 46296, 46300, 46304, 46308, 46376, 46812, 46816, 46820, 46824, 46828, 46884, 47328, 47332, 47336, 47340, 47344, 47848, 47852, 47856, 47860, 48364, 48368, 48372, 48376, 48380, 48412, 48880, 48884, 48888, 48892, 48896, 49396, 49400)
        draw16($t4, 49404, 49408, 49412, 49428, 49912, 49916, 49920, 49924, 49928, 49932, 49936, 50428, 50432, 50436, 50440, 50444)
        draw4($t4, 50944, 50948, 50952, 51460)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_29
    draw_clear_30: # draw t4, sleep, draw 0
        draw256($t4, 12028, 12536, 12540, 12544, 13044, 13048, 13052, 13056, 13060, 13552, 13560, 13564, 13568, 13572, 13576, 14060, 14076, 14080, 14084, 14088, 14092, 14568, 14592, 14596, 14600, 14604, 14608, 15076, 15108, 15112, 15116, 15120, 15124, 15584, 15624, 15628, 15632, 15636, 15640, 16092, 16140, 16144, 16148, 16152, 16156, 16600, 16656, 16660, 16664, 16668, 16672, 17108, 17112, 17172, 17176, 17180, 17184, 17188, 17616, 17620, 17692, 17696, 17700, 17704, 18124, 18128, 18208, 18212, 18216, 18220, 18632, 18636, 18724, 18728, 18732, 18736, 19140, 19144, 19240, 19244, 19248, 19252, 19648, 19652, 19756, 19760, 19764, 19768, 20156, 20160, 20272, 20276, 20280, 20284, 20664, 20668, 20788, 20792, 20796, 20800, 21172, 21176, 21180, 21308, 21312, 21316, 21680, 21684, 21688, 21824, 21828, 21832, 22188, 22192, 22196, 22340, 22344, 22348, 22696, 22700, 22704, 22856, 22860, 22864, 23204, 23208, 23212, 23372, 23376, 23380, 23712, 23716, 23720, 23888, 23892, 23896, 24220, 24224, 24228, 24404, 24408, 24412, 24728, 24732, 24736, 24924, 24928, 25236, 25240, 25244, 25248, 25440, 25444, 25744, 25748, 25752, 25756, 25956, 25960, 26252, 26256, 26260, 26264, 26472, 26476, 26760, 26764, 26768, 26772, 26988, 26992, 27268, 27272, 27276, 27280, 27504, 27508, 27776, 27780, 27784, 27788, 28020, 28024, 28284, 28288, 28292, 28296, 28540, 28792, 28796, 28800, 28804, 29056, 29300, 29304, 29308, 29312, 29316, 29572, 29808, 29812, 29816, 29820, 29824, 30088, 30316, 30320, 30324, 30328, 30332, 30604, 30824, 30828, 30832, 30836, 30840, 31120, 31332, 31336, 31340, 31344, 31348, 31636, 31840, 31844, 31848, 31852, 31856, 32144, 32148, 32152, 32348, 32352, 32356, 32360, 32364, 32652, 32656, 32660, 32664, 32668, 32864, 32868, 32872, 33160, 33164, 33168, 33172, 33176, 33380, 33668, 33672, 33676, 33680, 33684, 33896)
        draw64($t4, 34176, 34180, 34184, 34188, 34192, 34412, 34684, 34688, 34692, 34696, 34700, 34928, 35192, 35196, 35200, 35204, 35208, 35444, 35700, 35704, 35708, 35712, 35716, 35960, 36212, 36216, 36220, 36224, 36476, 36720, 36724, 36728, 36732, 36992, 36996, 37228, 37232, 37236, 37240, 37508, 37512, 37736, 37740, 37744, 37748, 38024, 38028, 38244, 38248, 38252, 38256, 38540, 38544, 38752, 38756, 38760, 38764, 39056, 39060, 39260, 39264, 39268, 39272, 39572)
        draw64($t4, 39576, 39768, 39772, 39776, 39780, 40088, 40092, 40280, 40284, 40288, 40604, 40608, 40612, 40788, 40792, 40796, 41120, 41124, 41128, 41296, 41300, 41304, 41636, 41640, 41644, 41804, 41808, 41812, 42152, 42156, 42160, 42312, 42316, 42320, 42668, 42672, 42676, 42820, 42824, 42828, 43184, 43188, 43192, 43328, 43332, 43336, 43700, 43704, 43708, 43836, 43840, 43844, 44216, 44220, 44224, 44228, 44348, 44352, 44732, 44736, 44740, 44744, 44856, 44860)
        draw64($t4, 45248, 45252, 45256, 45260, 45364, 45368, 45764, 45768, 45772, 45776, 45872, 45876, 46280, 46284, 46288, 46292, 46380, 46384, 46796, 46800, 46804, 46808, 46888, 46892, 47312, 47316, 47320, 47324, 47396, 47400, 47828, 47832, 47836, 47840, 47844, 47904, 47908, 48344, 48348, 48352, 48356, 48360, 48416, 48860, 48864, 48868, 48872, 48876, 48924, 49376, 49380, 49384, 49388, 49392, 49432, 49892, 49896, 49900, 49904, 49908, 49940, 50408, 50412, 50416)
        draw16($t4, 50420, 50424, 50448, 50924, 50928, 50932, 50936, 50940, 50956, 51440, 51444, 51448, 51452, 51456, 51464, 51956)
        draw4($t4, 51960, 51964, 51968, 51972)
        draw4($t4, 52472, 52476, 52480, 52988)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_30
    draw_clear_31: # draw t4, sleep, draw 0
        draw256($t4, 11012, 11016, 11520, 11524, 11528, 11532, 12032, 12036, 12040, 12044, 12048, 12548, 12552, 12556, 12560, 12564, 13064, 13068, 13072, 13076, 13080, 13548, 13580, 13584, 13588, 13592, 13596, 14056, 14096, 14100, 14104, 14108, 14564, 14612, 14616, 14620, 14624, 15072, 15128, 15132, 15136, 15140, 15580, 15644, 15648, 15652, 15656, 16088, 16160, 16164, 16168, 16172, 16596, 16676, 16680, 16684, 16688, 17100, 17104, 17192, 17196, 17200, 17204, 17608, 17612, 17708, 17712, 17716, 17720, 18116, 18120, 18224, 18228, 18232, 18236, 18624, 18628, 18740, 18744, 18748, 19132, 19136, 19256, 19260, 19264, 19640, 19644, 19772, 19776, 19780, 20148, 20152, 20288, 20292, 20296, 20652, 20656, 20660, 20804, 20808, 20812, 21160, 21164, 21168, 21320, 21324, 21328, 21668, 21672, 21676, 21836, 21840, 21844, 22176, 22180, 22184, 22352, 22356, 22360, 22684, 22688, 22692, 22868, 22872, 23192, 23196, 23200, 23384, 23388, 23700, 23704, 23708, 23900, 23904, 24204, 24208, 24212, 24216, 24416, 24420, 24712, 24716, 24720, 24724, 24932, 24936, 25220, 25224, 25228, 25232, 25448, 25452, 25728, 25732, 25736, 25740, 25964, 25968, 26236, 26240, 26244, 26248, 26480, 26484, 26744, 26748, 26752, 26756, 26996, 27252, 27256, 27260, 27264, 27512, 27760, 27764, 27768, 27772, 28028, 28264, 28268, 28272, 28276, 28280, 28544, 28772, 28776, 28780, 28784, 28788, 29060, 29280, 29284, 29288, 29292, 29296, 29576, 29788, 29792, 29796, 29800, 29804, 30092, 30296, 30300, 30304, 30308, 30312, 30608, 30804, 30808, 30812, 30816, 30820, 31316, 31320, 31324, 31328, 31832, 31836, 33180, 33184, 33688, 33692, 33696, 33700, 34196, 34200, 34204, 34208, 34212, 34408, 34704, 34708, 34712, 34716, 34720, 34924, 35212, 35216, 35220, 35224, 35228, 35440, 35720, 35724, 35728, 35732, 35736, 35956, 36228, 36232, 36236, 36240, 36244, 36472)
        draw64($t4, 36736, 36740, 36744, 36748, 36752, 36988, 37244, 37248, 37252, 37256, 37504, 37752, 37756, 37760, 37764, 38020, 38260, 38264, 38268, 38272, 38532, 38536, 38768, 38772, 38776, 38780, 39048, 39052, 39276, 39280, 39284, 39288, 39564, 39568, 39784, 39788, 39792, 39796, 40080, 40084, 40292, 40296, 40300, 40304, 40596, 40600, 40800, 40804, 40808, 40812, 41112, 41116, 41308, 41312, 41316, 41628, 41632, 41816, 41820, 41824, 42144, 42148, 42324, 42328)
        draw64($t4, 42332, 42656, 42660, 42664, 42832, 42836, 42840, 43172, 43176, 43180, 43340, 43344, 43348, 43688, 43692, 43696, 43848, 43852, 43856, 44204, 44208, 44212, 44356, 44360, 44364, 44720, 44724, 44728, 44864, 44868, 45236, 45240, 45244, 45372, 45376, 45752, 45756, 45760, 45880, 45884, 46268, 46272, 46276, 46388, 46392, 46780, 46784, 46788, 46792, 46896, 46900, 47296, 47300, 47304, 47308, 47404, 47408, 47812, 47816, 47820, 47824, 47912, 47916, 48328)
        draw16($t4, 48332, 48336, 48340, 48420, 48844, 48848, 48852, 48856, 48928, 49360, 49364, 49368, 49372, 49436, 49876, 49880)
        draw16($t4, 49884, 49888, 49944, 50392, 50396, 50400, 50404, 50452, 50908, 50912, 50916, 50920, 50960, 51420, 51424, 51428)
        draw16($t4, 51432, 51436, 51468, 51936, 51940, 51944, 51948, 51952, 52452, 52456, 52460, 52464, 52468, 52968, 52972, 52976)
        draw4($t4, 52980, 52984, 53484, 53488)
        draw4($t4, 53492, 53496, 54000, 54004)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_31
    draw_clear_32: # draw t4, sleep, draw 0
        draw256($t4, 9492, 9996, 10000, 10004, 10008, 10504, 10508, 10512, 10516, 10520, 11020, 11024, 11028, 11032, 11036, 11536, 11540, 11544, 11548, 11552, 12024, 12052, 12056, 12060, 12064, 12068, 12532, 12568, 12572, 12576, 12580, 12584, 13040, 13084, 13088, 13092, 13096, 13544, 13600, 13604, 13608, 13612, 14052, 14112, 14116, 14120, 14124, 14128, 14560, 14628, 14632, 14636, 14640, 14644, 15064, 15068, 15144, 15148, 15152, 15156, 15572, 15576, 15660, 15664, 15668, 15672, 16080, 16084, 16176, 16180, 16184, 16188, 16588, 16592, 16692, 16696, 16700, 16704, 17092, 17096, 17208, 17212, 17216, 17600, 17604, 17724, 17728, 17732, 18108, 18112, 18240, 18244, 18248, 18612, 18616, 18620, 18752, 18756, 18760, 18764, 19120, 19124, 19128, 19268, 19272, 19276, 19280, 19628, 19632, 19636, 19784, 19788, 19792, 20132, 20136, 20140, 20144, 20300, 20304, 20308, 20640, 20644, 20648, 20816, 20820, 20824, 21148, 21152, 21156, 21332, 21336, 21340, 21652, 21656, 21660, 21664, 21848, 21852, 22160, 22164, 22168, 22172, 22364, 22368, 22668, 22672, 22676, 22680, 22876, 22880, 22884, 23176, 23180, 23184, 23188, 23392, 23396, 23400, 23680, 23684, 23688, 23692, 23696, 23908, 23912, 24188, 24192, 24196, 24200, 24424, 24428, 24696, 24700, 24704, 24708, 24940, 24944, 25200, 25204, 25208, 25212, 25216, 25456, 25460, 25708, 25712, 25716, 25720, 25724, 25972, 26216, 26220, 26224, 26228, 26232, 26488, 26720, 26724, 26728, 26732, 26736, 26740, 27000, 27004, 27228, 27232, 27236, 27240, 27244, 27248, 27516, 27520, 27736, 27740, 27744, 27748, 27752, 27756, 28032, 28036, 28244, 28248, 28252, 28256, 28260, 28548, 28748, 28752, 28756, 28760, 28764, 28768, 29064, 29256, 29260, 29264, 29268, 29272, 29276, 29580, 29772, 29776, 29780, 29784, 30096, 30284, 30288, 30292, 30800, 31124, 31640, 32156, 32860, 33376, 33892, 34216)
        draw64($t4, 34724, 34728, 34732, 34920, 35232, 35236, 35240, 35244, 35436, 35740, 35744, 35748, 35752, 35756, 35760, 35952, 36248, 36252, 36256, 36260, 36264, 36268, 36468, 36756, 36760, 36764, 36768, 36772, 36980, 36984, 37260, 37264, 37268, 37272, 37276, 37280, 37496, 37500, 37768, 37772, 37776, 37780, 37784, 37788, 38012, 38016, 38276, 38280, 38284, 38288, 38292, 38296, 38528, 38784, 38788, 38792, 38796, 38800, 39044, 39292, 39296, 39300, 39304, 39308)
        draw64($t4, 39556, 39560, 39800, 39804, 39808, 39812, 39816, 40072, 40076, 40308, 40312, 40316, 40320, 40588, 40592, 40816, 40820, 40824, 40828, 41104, 41108, 41320, 41324, 41328, 41332, 41336, 41616, 41620, 41624, 41828, 41832, 41836, 41840, 42132, 42136, 42140, 42336, 42340, 42344, 42348, 42648, 42652, 42844, 42848, 42852, 42856, 43164, 43168, 43352, 43356, 43360, 43364, 43676, 43680, 43684, 43860, 43864, 43868, 44192, 44196, 44200, 44368, 44372, 44376)
        draw64($t4, 44708, 44712, 44716, 44872, 44876, 44880, 44884, 45224, 45228, 45232, 45380, 45384, 45388, 45736, 45740, 45744, 45748, 45888, 45892, 45896, 46252, 46256, 46260, 46264, 46396, 46400, 46404, 46768, 46772, 46776, 46904, 46908, 47284, 47288, 47292, 47412, 47416, 47800, 47804, 47808, 47920, 47924, 48312, 48316, 48320, 48324, 48424, 48428, 48828, 48832, 48836, 48840, 48932, 48936, 49344, 49348, 49352, 49356, 49440, 49444, 49860, 49864, 49868, 49872)
        draw16($t4, 49948, 49952, 50372, 50376, 50380, 50384, 50388, 50456, 50888, 50892, 50896, 50900, 50904, 50964, 51404, 51408)
        draw16($t4, 51412, 51416, 51472, 51920, 51924, 51928, 51932, 51976, 52432, 52436, 52440, 52444, 52448, 52484, 52948, 52952)
        draw16($t4, 52956, 52960, 52964, 52992, 53464, 53468, 53472, 53476, 53480, 53980, 53984, 53988, 53992, 53996, 54496, 54500)
        draw4($t4, 54504, 54508, 54512, 55008)
        draw4($t4, 55012, 55016, 55020, 55524)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_32
    draw_clear_33: # draw t4, sleep, draw 0
        draw256($t4, 8480, 8484, 8988, 8992, 8996, 9000, 9496, 9500, 9504, 9508, 9512, 9516, 10012, 10016, 10020, 10024, 10028, 10524, 10528, 10532, 10536, 10540, 10544, 11040, 11044, 11048, 11052, 11056, 11060, 11516, 11556, 11560, 11564, 11568, 11572, 12072, 12076, 12080, 12084, 12088, 12528, 12588, 12592, 12596, 12600, 12604, 13036, 13100, 13104, 13108, 13112, 13116, 13540, 13616, 13620, 13624, 13628, 13632, 14048, 14132, 14136, 14140, 14144, 14148, 14552, 14556, 14648, 14652, 14656, 14660, 15060, 15160, 15164, 15168, 15172, 15176, 15564, 15568, 15676, 15680, 15684, 15688, 15692, 16072, 16076, 16192, 16196, 16200, 16204, 16576, 16580, 16584, 16708, 16712, 16716, 16720, 17084, 17088, 17220, 17224, 17228, 17232, 17236, 17588, 17592, 17596, 17736, 17740, 17744, 17748, 18096, 18100, 18104, 18252, 18256, 18260, 18264, 18600, 18604, 18608, 18768, 18772, 18776, 18780, 19108, 19112, 19116, 19284, 19288, 19292, 19612, 19616, 19620, 19624, 19796, 19800, 19804, 19808, 20120, 20124, 20128, 20312, 20316, 20320, 20324, 20624, 20628, 20632, 20636, 20828, 20832, 20836, 21132, 21136, 21140, 21144, 21344, 21348, 21352, 21636, 21640, 21644, 21648, 21856, 21860, 21864, 21868, 22144, 22148, 22152, 22156, 22372, 22376, 22380, 22648, 22652, 22656, 22660, 22664, 22888, 22892, 22896, 23156, 23160, 23164, 23168, 23172, 23404, 23408, 23412, 23660, 23664, 23668, 23672, 23676, 23916, 23920, 23924, 24168, 24172, 24176, 24180, 24184, 24432, 24436, 24440, 24672, 24676, 24680, 24684, 24688, 24692, 24948, 24952, 24956, 25180, 25184, 25188, 25192, 25196, 25464, 25468, 25684, 25688, 25692, 25696, 25700, 25704, 25976, 25980, 25984, 26192, 26196, 26200, 26204, 26208, 26212, 26492, 26496, 26500, 26696, 26700, 26704, 26708, 26712, 26716, 27008, 27012, 27204, 27208, 27212, 27216, 27220, 27224, 27524, 27528)
        draw256($t4, 27712, 27716, 27720, 27724, 27728, 27732, 28040, 28044, 28224, 28228, 28232, 28236, 28240, 28552, 28556, 28740, 28744, 29068, 29072, 29584, 29588, 29768, 30100, 30612, 30616, 31128, 31132, 31312, 31644, 31828, 32160, 32344, 32672, 32676, 32856, 33188, 33372, 33704, 33888, 34220, 34400, 34404, 34916, 35248, 35432, 35764, 35944, 35948, 36272, 36276, 36460, 36464, 36776, 36780, 36784, 36788, 36792, 36976, 37284, 37288, 37292, 37296, 37300, 37304, 37308, 37488, 37492, 37792, 37796, 37800, 37804, 37808, 37812, 37816, 37820, 38004, 38008, 38300, 38304, 38308, 38312, 38316, 38320, 38324, 38328, 38520, 38524, 38804, 38808, 38812, 38816, 38820, 38824, 38828, 38832, 38836, 39032, 39036, 39040, 39312, 39316, 39320, 39324, 39328, 39332, 39336, 39340, 39548, 39552, 39820, 39824, 39828, 39832, 39836, 39840, 39844, 39848, 40064, 40068, 40324, 40328, 40332, 40336, 40340, 40344, 40348, 40352, 40576, 40580, 40584, 40832, 40836, 40840, 40844, 40848, 40852, 40856, 40860, 41092, 41096, 41100, 41340, 41344, 41348, 41352, 41356, 41360, 41364, 41608, 41612, 41844, 41848, 41852, 41856, 41860, 41864, 41868, 41872, 42120, 42124, 42128, 42352, 42356, 42360, 42364, 42368, 42372, 42376, 42636, 42640, 42644, 42860, 42864, 42868, 42872, 42876, 42880, 42884, 43152, 43156, 43160, 43368, 43372, 43376, 43380, 43384, 43388, 43664, 43668, 43672, 43872, 43876, 43880, 43884, 43888, 43892, 43896, 44180, 44184, 44188, 44380, 44384, 44388, 44392, 44396, 44400, 44696, 44700, 44704, 44888, 44892, 44896, 44900, 44904, 44908, 45208, 45212, 45216, 45220, 45392, 45396, 45400, 45404, 45408, 45412, 45724, 45728, 45732, 45900, 45904, 45908, 45912, 45916, 45920, 46240, 46244, 46248, 46408, 46412, 46416, 46420, 46424, 46752, 46756, 46760, 46764, 46912, 46916, 46920, 46924, 46928, 46932, 47268, 47272, 47276, 47280)
        draw64($t4, 47420, 47424, 47428, 47432, 47436, 47784, 47788, 47792, 47796, 47928, 47932, 47936, 47940, 47944, 48296, 48300, 48304, 48308, 48432, 48436, 48440, 48444, 48448, 48812, 48816, 48820, 48824, 48940, 48944, 48948, 48952, 48956, 49328, 49332, 49336, 49340, 49448, 49452, 49456, 49460, 49840, 49844, 49848, 49852, 49856, 49956, 49960, 49964, 49968, 50356, 50360, 50364, 50368, 50460, 50464, 50468, 50472, 50872, 50876, 50880, 50884, 50968, 50972, 50976)
        draw64($t4, 50980, 51384, 51388, 51392, 51396, 51400, 51476, 51480, 51484, 51900, 51904, 51908, 51912, 51916, 51980, 51984, 51988, 51992, 52416, 52420, 52424, 52428, 52488, 52492, 52496, 52928, 52932, 52936, 52940, 52944, 52996, 53000, 53004, 53444, 53448, 53452, 53456, 53460, 53500, 53504, 53508, 53960, 53964, 53968, 53972, 53976, 54008, 54012, 54016, 54472, 54476, 54480, 54484, 54488, 54492, 54516, 54520, 54988, 54992, 54996, 55000, 55004, 55024, 55028)
        draw16($t4, 55504, 55508, 55512, 55516, 55520, 55528, 55532, 56016, 56020, 56024, 56028, 56032, 56036, 56040, 56532, 56536)
        draw4($t4, 56540, 56544, 57048, 57052)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_33
    draw_clear_34: # draw t4, sleep, draw 0
        draw256($t4, 6956, 6960, 6964, 7460, 7464, 7468, 7472, 7476, 7480, 7968, 7972, 7976, 7980, 7984, 7988, 7992, 8472, 8476, 8488, 8492, 8496, 8500, 8504, 8508, 8976, 8980, 8984, 9004, 9008, 9012, 9016, 9020, 9480, 9484, 9488, 9520, 9524, 9528, 9532, 9536, 9988, 9992, 10032, 10036, 10040, 10044, 10048, 10492, 10496, 10500, 10548, 10552, 10556, 10560, 10564, 10996, 11000, 11004, 11008, 11064, 11068, 11072, 11076, 11080, 11504, 11508, 11512, 11576, 11580, 11584, 11588, 11592, 12008, 12012, 12016, 12020, 12092, 12096, 12100, 12104, 12108, 12512, 12516, 12520, 12524, 12608, 12612, 12616, 12620, 13016, 13020, 13024, 13028, 13032, 13120, 13124, 13128, 13132, 13136, 13524, 13528, 13532, 13536, 13636, 13640, 13644, 13648, 14028, 14032, 14036, 14040, 14044, 14152, 14156, 14160, 14164, 14532, 14536, 14540, 14544, 14548, 14664, 14668, 14672, 14676, 14680, 15036, 15040, 15044, 15048, 15052, 15056, 15180, 15184, 15188, 15192, 15544, 15548, 15552, 15556, 15560, 15696, 15700, 15704, 15708, 16048, 16052, 16056, 16060, 16064, 16068, 16208, 16212, 16216, 16220, 16552, 16556, 16560, 16564, 16568, 16572, 16724, 16728, 16732, 16736, 17056, 17060, 17064, 17068, 17072, 17076, 17080, 17240, 17244, 17248, 17564, 17568, 17572, 17576, 17580, 17584, 17752, 17756, 17760, 17764, 18068, 18072, 18076, 18080, 18084, 18088, 18092, 18268, 18272, 18276, 18280, 18572, 18576, 18580, 18584, 18588, 18592, 18596, 18784, 18788, 18792, 19080, 19084, 19088, 19092, 19096, 19100, 19104, 19296, 19300, 19304, 19308, 19584, 19588, 19592, 19596, 19600, 19604, 19608, 19812, 19816, 19820, 20088, 20092, 20096, 20100, 20104, 20108, 20112, 20116, 20328, 20332, 20336, 20592, 20596, 20600, 20604, 20608, 20612, 20616, 20620, 20840, 20844, 20848, 20852, 21100, 21104, 21108, 21112, 21116, 21120)
        draw256($t4, 21124, 21128, 21356, 21360, 21364, 21604, 21608, 21612, 21616, 21620, 21624, 21628, 21632, 21872, 21876, 21880, 22108, 22112, 22116, 22120, 22124, 22128, 22132, 22136, 22140, 22384, 22388, 22392, 22612, 22616, 22620, 22624, 22628, 22632, 22636, 22640, 22644, 22900, 22904, 22908, 23120, 23124, 23128, 23132, 23136, 23140, 23144, 23148, 23152, 23416, 23420, 23624, 23628, 23632, 23636, 23640, 23644, 23648, 23652, 23656, 23928, 23932, 23936, 24128, 24132, 24136, 24140, 24144, 24148, 24152, 24156, 24160, 24164, 24444, 24448, 24452, 24632, 24636, 24640, 24644, 24648, 24652, 24656, 24660, 24664, 24668, 24960, 24964, 25140, 25144, 25148, 25152, 25156, 25160, 25164, 25168, 25172, 25176, 25472, 25476, 25480, 25652, 25656, 25660, 25664, 25668, 25672, 25676, 25680, 25988, 25992, 26164, 26168, 26172, 26176, 26180, 26184, 26188, 26504, 26508, 26680, 26684, 26688, 26692, 27016, 27020, 27192, 27196, 27200, 27532, 27536, 27708, 28048, 28052, 28560, 28564, 28736, 29076, 29080, 29252, 29592, 29764, 30104, 30108, 30280, 30620, 30792, 30796, 31136, 31308, 31648, 31652, 31824, 32164, 32336, 32340, 32680, 32852, 33192, 33364, 33368, 33708, 33880, 33884, 34224, 34396, 34736, 34908, 34912, 35252, 35424, 35428, 35936, 35940, 36280, 36452, 36456, 36964, 36968, 36972, 37480, 37484, 37824, 37996, 38000, 38332, 38336, 38508, 38512, 38516, 38840, 38844, 38848, 38852, 39024, 39028, 39344, 39348, 39352, 39356, 39360, 39364, 39536, 39540, 39544, 39852, 39856, 39860, 39864, 39868, 39872, 39876, 40052, 40056, 40060, 40356, 40360, 40364, 40368, 40372, 40376, 40380, 40384, 40564, 40568, 40572, 40864, 40868, 40872, 40876, 40880, 40884, 40888, 41080, 41084, 41088, 41368, 41372, 41376, 41380, 41384, 41388, 41392, 41596, 41600, 41604, 41876, 41880, 41884, 41888, 41892, 41896, 42108, 42112, 42116, 42380)
        draw64($t4, 42384, 42388, 42392, 42396, 42400, 42404, 42624, 42628, 42632, 42888, 42892, 42896, 42900, 42904, 42908, 43136, 43140, 43144, 43148, 43392, 43396, 43400, 43404, 43408, 43412, 43652, 43656, 43660, 43900, 43904, 43908, 43912, 43916, 44164, 44168, 44172, 44176, 44404, 44408, 44412, 44416, 44420, 44424, 44680, 44684, 44688, 44692, 44912, 44916, 44920, 44924, 44928, 45196, 45200, 45204, 45416, 45420, 45424, 45428, 45432, 45708, 45712, 45716, 45720)
        draw64($t4, 45924, 45928, 45932, 45936, 46224, 46228, 46232, 46236, 46428, 46432, 46436, 46440, 46444, 46736, 46740, 46744, 46748, 46936, 46940, 46944, 46948, 47252, 47256, 47260, 47264, 47440, 47444, 47448, 47452, 47768, 47772, 47776, 47780, 47948, 47952, 47956, 47960, 48280, 48284, 48288, 48292, 48452, 48456, 48460, 48464, 48796, 48800, 48804, 48808, 48960, 48964, 48968, 49308, 49312, 49316, 49320, 49324, 49464, 49468, 49472, 49824, 49828, 49832, 49836)
        draw64($t4, 49972, 49976, 49980, 50336, 50340, 50344, 50348, 50352, 50476, 50480, 50484, 50852, 50856, 50860, 50864, 50868, 50984, 50988, 51368, 51372, 51376, 51380, 51488, 51492, 51880, 51884, 51888, 51892, 51896, 51996, 52000, 52396, 52400, 52404, 52408, 52412, 52500, 52504, 52908, 52912, 52916, 52920, 52924, 53008, 53424, 53428, 53432, 53436, 53440, 53512, 53936, 53940, 53944, 53948, 53952, 53956, 54020, 54452, 54456, 54460, 54464, 54468, 54524, 54968)
        draw16($t4, 54972, 54976, 54980, 54984, 55480, 55484, 55488, 55492, 55496, 55500, 55536, 55996, 56000, 56004, 56008, 56012)
        draw16($t4, 56508, 56512, 56516, 56520, 56524, 56528, 57024, 57028, 57032, 57036, 57040, 57044, 57536, 57540, 57544, 57548)
        draw4($t4, 57552, 57556, 58052, 58056)
        sw $t4 58060($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_34
    draw_clear_35: # draw t4, sleep, draw 0
        draw256($t4, 5952, 5956, 5960, 6456, 6460, 6464, 6468, 6472, 6968, 6972, 6976, 6980, 6984, 6988, 7484, 7488, 7492, 7496, 7500, 7996, 8000, 8004, 8008, 8012, 8016, 8512, 8516, 8520, 8524, 8528, 9024, 9028, 9032, 9036, 9040, 9044, 9540, 9544, 9548, 9552, 9556, 9984, 10052, 10056, 10060, 10064, 10068, 10072, 10488, 10568, 10572, 10576, 10580, 10584, 10992, 11084, 11088, 11092, 11096, 11100, 11496, 11500, 11596, 11600, 11604, 11608, 11612, 12000, 12004, 12112, 12116, 12120, 12124, 12128, 12504, 12508, 12624, 12628, 12632, 12636, 12640, 13008, 13012, 13140, 13144, 13148, 13152, 13156, 13512, 13516, 13520, 13652, 13656, 13660, 13664, 13668, 14016, 14020, 14024, 14168, 14172, 14176, 14180, 14184, 14520, 14524, 14528, 14684, 14688, 14692, 14696, 15024, 15028, 15032, 15196, 15200, 15204, 15208, 15212, 15524, 15528, 15532, 15536, 15540, 15712, 15716, 15720, 15724, 16028, 16032, 16036, 16040, 16044, 16224, 16228, 16232, 16236, 16240, 16532, 16536, 16540, 16544, 16548, 16740, 16744, 16748, 16752, 17036, 17040, 17044, 17048, 17052, 17252, 17256, 17260, 17264, 17268, 17540, 17544, 17548, 17552, 17556, 17560, 17768, 17772, 17776, 17780, 18044, 18048, 18052, 18056, 18060, 18064, 18284, 18288, 18292, 18296, 18548, 18552, 18556, 18560, 18564, 18568, 18796, 18800, 18804, 18808, 19052, 19056, 19060, 19064, 19068, 19072, 19076, 19312, 19316, 19320, 19324, 19556, 19560, 19564, 19568, 19572, 19576, 19580, 19824, 19828, 19832, 19836, 20060, 20064, 20068, 20072, 20076, 20080, 20084, 20340, 20344, 20348, 20352, 20564, 20568, 20572, 20576, 20580, 20584, 20588, 20856, 20860, 20864, 21068, 21072, 21076, 21080, 21084, 21088, 21092, 21096, 21368, 21372, 21376, 21380, 21572, 21576, 21580, 21584, 21588, 21592, 21596, 21600, 21884, 21888, 21892, 22076, 22080, 22084)
        draw256($t4, 22088, 22092, 22096, 22100, 22104, 22396, 22400, 22404, 22580, 22584, 22588, 22592, 22596, 22600, 22604, 22608, 22912, 22916, 22920, 23084, 23088, 23092, 23096, 23100, 23104, 23108, 23112, 23116, 23424, 23428, 23432, 23596, 23600, 23604, 23608, 23612, 23616, 23620, 23940, 23944, 23948, 24108, 24112, 24116, 24120, 24124, 24456, 24460, 24624, 24628, 24968, 24972, 24976, 25136, 25484, 25488, 25996, 26000, 26004, 26512, 26516, 27024, 27028, 27032, 27540, 27544, 28056, 28060, 28220, 28568, 28572, 29084, 29088, 29248, 29596, 29600, 30112, 30116, 30276, 30624, 30628, 31140, 31144, 31304, 31656, 31820, 32168, 32172, 32332, 32684, 32848, 33196, 33200, 33360, 33712, 33876, 34228, 34388, 34392, 34740, 34904, 35256, 35416, 35420, 35768, 35932, 36284, 36444, 36448, 36796, 36960, 37312, 37472, 37476, 37988, 37992, 38340, 38500, 38504, 39016, 39020, 39368, 39528, 39532, 39880, 40044, 40048, 40388, 40392, 40396, 40556, 40560, 40892, 40896, 40900, 40904, 40908, 41072, 41076, 41396, 41400, 41404, 41408, 41412, 41416, 41420, 41424, 41584, 41588, 41592, 41900, 41904, 41908, 41912, 41916, 41920, 41924, 41928, 41932, 41936, 42100, 42104, 42408, 42412, 42416, 42420, 42424, 42428, 42432, 42436, 42440, 42444, 42448, 42612, 42616, 42620, 42912, 42916, 42920, 42924, 42928, 42932, 42936, 42940, 42944, 42948, 42952, 43128, 43132, 43416, 43420, 43424, 43428, 43432, 43436, 43440, 43444, 43448, 43452, 43456, 43640, 43644, 43648, 43920, 43924, 43928, 43932, 43936, 43940, 43944, 43948, 43952, 43956, 43960, 44152, 44156, 44160, 44428, 44432, 44436, 44440, 44444, 44448, 44452, 44456, 44460, 44464, 44668, 44672, 44676, 44932, 44936, 44940, 44944, 44948, 44952, 44956, 44960, 44964, 44968, 45180, 45184, 45188, 45192, 45436, 45440, 45444, 45448, 45452, 45456, 45460, 45464, 45468, 45472, 45696, 45700)
        draw256($t4, 45704, 45940, 45944, 45948, 45952, 45956, 45960, 45964, 45968, 45972, 45976, 46208, 46212, 46216, 46220, 46448, 46452, 46456, 46460, 46464, 46468, 46472, 46476, 46480, 46724, 46728, 46732, 46952, 46956, 46960, 46964, 46968, 46972, 46976, 46980, 46984, 47236, 47240, 47244, 47248, 47456, 47460, 47464, 47468, 47472, 47476, 47480, 47484, 47488, 47752, 47756, 47760, 47764, 47964, 47968, 47972, 47976, 47980, 47984, 47988, 47992, 48264, 48268, 48272, 48276, 48468, 48472, 48476, 48480, 48484, 48488, 48492, 48496, 48780, 48784, 48788, 48792, 48972, 48976, 48980, 48984, 48988, 48992, 48996, 49000, 49292, 49296, 49300, 49304, 49476, 49480, 49484, 49488, 49492, 49496, 49500, 49504, 49808, 49812, 49816, 49820, 49984, 49988, 49992, 49996, 50000, 50004, 50008, 50320, 50324, 50328, 50332, 50488, 50492, 50496, 50500, 50504, 50508, 50836, 50840, 50844, 50848, 50992, 50996, 51000, 51004, 51008, 51012, 51348, 51352, 51356, 51360, 51364, 51496, 51500, 51504, 51508, 51512, 51516, 51864, 51868, 51872, 51876, 52004, 52008, 52012, 52016, 52020, 52376, 52380, 52384, 52388, 52392, 52508, 52512, 52516, 52520, 52524, 52892, 52896, 52900, 52904, 53012, 53016, 53020, 53024, 53028, 53404, 53408, 53412, 53416, 53420, 53516, 53520, 53524, 53528, 53532, 53920, 53924, 53928, 53932, 54024, 54028, 54032, 54036, 54432, 54436, 54440, 54444, 54448, 54528, 54532, 54536, 54540, 54948, 54952, 54956, 54960, 54964, 55032, 55036, 55040, 55044, 55460, 55464, 55468, 55472, 55476, 55540, 55544, 55548, 55976, 55980, 55984, 55988, 55992, 56044, 56048, 56052, 56488, 56492, 56496, 56500, 56504, 56548, 56552, 56556, 57004, 57008, 57012, 57016, 57020, 57056, 57060, 57516, 57520, 57524, 57528, 57532, 57560, 57564, 58032, 58036, 58040, 58044, 58048, 58064, 58068, 58544, 58548, 58552, 58556, 58560, 58564, 58568, 58572)
        draw4($t4, 59060, 59064, 59068, 59072)
        draw4($t4, 59076, 59572, 59576, 59580)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_35
    draw_clear_36: # draw t4, sleep, draw 0
        draw256($t4, 4440, 4444, 4940, 4944, 4948, 4952, 4956, 5444, 5448, 5452, 5456, 5460, 5464, 5468, 5944, 5948, 5964, 5968, 5972, 5976, 5980, 5984, 6448, 6452, 6476, 6480, 6484, 6488, 6492, 6496, 6952, 6992, 6996, 7000, 7004, 7008, 7012, 7452, 7456, 7504, 7508, 7512, 7516, 7520, 7524, 7956, 7960, 7964, 8020, 8024, 8028, 8032, 8036, 8456, 8460, 8464, 8468, 8532, 8536, 8540, 8544, 8548, 8552, 8960, 8964, 8968, 8972, 9048, 9052, 9056, 9060, 9064, 9460, 9464, 9468, 9472, 9476, 9560, 9564, 9568, 9572, 9576, 9580, 9964, 9968, 9972, 9976, 9980, 10076, 10080, 10084, 10088, 10092, 10468, 10472, 10476, 10480, 10484, 10588, 10592, 10596, 10600, 10604, 10608, 10968, 10972, 10976, 10980, 10984, 10988, 11104, 11108, 11112, 11116, 11120, 11472, 11476, 11480, 11484, 11488, 11492, 11616, 11620, 11624, 11628, 11632, 11972, 11976, 11980, 11984, 11988, 11992, 11996, 12132, 12136, 12140, 12144, 12148, 12476, 12480, 12484, 12488, 12492, 12496, 12500, 12644, 12648, 12652, 12656, 12660, 12980, 12984, 12988, 12992, 12996, 13000, 13004, 13160, 13164, 13168, 13172, 13176, 13480, 13484, 13488, 13492, 13496, 13500, 13504, 13508, 13672, 13676, 13680, 13684, 13688, 13984, 13988, 13992, 13996, 14000, 14004, 14008, 14012, 14188, 14192, 14196, 14200, 14484, 14488, 14492, 14496, 14500, 14504, 14508, 14512, 14516, 14700, 14704, 14708, 14712, 14716, 14988, 14992, 14996, 15000, 15004, 15008, 15012, 15016, 15020, 15216, 15220, 15224, 15228, 15492, 15496, 15500, 15504, 15508, 15512, 15516, 15520, 15728, 15732, 15736, 15740, 15744, 15992, 15996, 16000, 16004, 16008, 16012, 16016, 16020, 16024, 16244, 16248, 16252, 16256, 16496, 16500, 16504, 16508, 16512, 16516, 16520, 16524, 16528, 16756, 16760, 16764, 16768, 16996, 17000, 17004)
        draw256($t4, 17008, 17012, 17016, 17020, 17024, 17028, 17032, 17272, 17276, 17280, 17284, 17500, 17504, 17508, 17512, 17516, 17520, 17524, 17528, 17532, 17536, 17784, 17788, 17792, 17796, 18000, 18004, 18008, 18012, 18016, 18020, 18024, 18028, 18032, 18036, 18040, 18300, 18304, 18308, 18312, 18504, 18508, 18512, 18516, 18520, 18524, 18528, 18532, 18536, 18540, 18544, 18812, 18816, 18820, 18824, 19008, 19012, 19016, 19020, 19024, 19028, 19032, 19036, 19040, 19044, 19048, 19328, 19332, 19336, 19340, 19508, 19512, 19516, 19520, 19524, 19528, 19532, 19536, 19540, 19544, 19548, 19552, 19840, 19844, 19848, 19852, 20012, 20016, 20020, 20024, 20028, 20032, 20036, 20040, 20044, 20048, 20052, 20056, 20356, 20360, 20364, 20512, 20516, 20520, 20524, 20528, 20532, 20536, 20540, 20544, 20548, 20552, 20556, 20560, 20868, 20872, 20876, 20880, 21024, 21028, 21032, 21036, 21040, 21044, 21048, 21052, 21056, 21060, 21064, 21384, 21388, 21392, 21540, 21544, 21548, 21552, 21556, 21560, 21564, 21568, 21896, 21900, 21904, 21908, 22052, 22056, 22060, 22064, 22068, 22072, 22408, 22412, 22416, 22420, 22564, 22568, 22572, 22576, 22924, 22928, 22932, 23080, 23436, 23440, 23444, 23448, 23592, 23952, 23956, 23960, 24464, 24468, 24472, 24476, 24620, 24980, 24984, 24988, 25132, 25492, 25496, 25500, 25504, 25648, 26008, 26012, 26016, 26160, 26520, 26524, 26528, 26676, 27036, 27040, 27044, 27188, 27548, 27552, 27556, 27704, 28064, 28068, 28072, 28216, 28576, 28580, 28584, 28728, 28732, 29092, 29096, 29244, 29604, 29608, 29612, 29756, 29760, 30120, 30124, 30272, 30632, 30636, 30640, 30784, 30788, 31148, 31152, 31296, 31300, 31660, 31664, 31668, 31812, 31816, 32176, 32180, 32324, 32328, 32688, 32692, 32840, 32844, 33204, 33208, 33352, 33356, 33716, 33720, 33864, 33868, 33872, 34232, 34236, 34380, 34384, 34744)
        draw256($t4, 34748, 34892, 34896, 34900, 35260, 35408, 35412, 35772, 35776, 35920, 35924, 35928, 36288, 36436, 36440, 36800, 36804, 36948, 36952, 36956, 37316, 37460, 37464, 37468, 37828, 37976, 37980, 37984, 38344, 38488, 38492, 38496, 38856, 39004, 39008, 39012, 39372, 39516, 39520, 39524, 39884, 40028, 40032, 40036, 40040, 40400, 40544, 40548, 40552, 40912, 41056, 41060, 41064, 41068, 41572, 41576, 41580, 41940, 42084, 42088, 42092, 42096, 42452, 42600, 42604, 42608, 42956, 42960, 42964, 42968, 43112, 43116, 43120, 43124, 43460, 43464, 43468, 43472, 43476, 43480, 43624, 43628, 43632, 43636, 43964, 43968, 43972, 43976, 43980, 43984, 43988, 43992, 44140, 44144, 44148, 44468, 44472, 44476, 44480, 44484, 44488, 44492, 44496, 44500, 44504, 44508, 44652, 44656, 44660, 44664, 44972, 44976, 44980, 44984, 44988, 44992, 44996, 45000, 45004, 45008, 45012, 45016, 45020, 45168, 45172, 45176, 45476, 45480, 45484, 45488, 45492, 45496, 45500, 45504, 45508, 45512, 45516, 45520, 45680, 45684, 45688, 45692, 45980, 45984, 45988, 45992, 45996, 46000, 46004, 46008, 46012, 46016, 46020, 46024, 46192, 46196, 46200, 46204, 46484, 46488, 46492, 46496, 46500, 46504, 46508, 46512, 46516, 46520, 46524, 46708, 46712, 46716, 46720, 46988, 46992, 46996, 47000, 47004, 47008, 47012, 47016, 47020, 47024, 47028, 47220, 47224, 47228, 47232, 47492, 47496, 47500, 47504, 47508, 47512, 47516, 47520, 47524, 47528, 47532, 47736, 47740, 47744, 47748, 47996, 48000, 48004, 48008, 48012, 48016, 48020, 48024, 48028, 48032, 48248, 48252, 48256, 48260, 48500, 48504, 48508, 48512, 48516, 48520, 48524, 48528, 48532, 48536, 48764, 48768, 48772, 48776, 49004, 49008, 49012, 49016, 49020, 49024, 49028, 49032, 49036, 49276, 49280, 49284, 49288, 49508, 49512, 49516, 49520, 49524, 49528, 49532, 49536, 49540, 49788, 49792, 49796)
        draw64($t4, 49800, 49804, 50012, 50016, 50020, 50024, 50028, 50032, 50036, 50040, 50304, 50308, 50312, 50316, 50512, 50516, 50520, 50524, 50528, 50532, 50536, 50540, 50544, 50816, 50820, 50824, 50828, 50832, 51016, 51020, 51024, 51028, 51032, 51036, 51040, 51044, 51048, 51332, 51336, 51340, 51344, 51520, 51524, 51528, 51532, 51536, 51540, 51544, 51548, 51844, 51848, 51852, 51856, 51860, 52024, 52028, 52032, 52036, 52040, 52044, 52048, 52052, 52356, 52360)
        draw64($t4, 52364, 52368, 52372, 52528, 52532, 52536, 52540, 52544, 52548, 52552, 52872, 52876, 52880, 52884, 52888, 53032, 53036, 53040, 53044, 53048, 53052, 53056, 53384, 53388, 53392, 53396, 53400, 53536, 53540, 53544, 53548, 53552, 53556, 53560, 53900, 53904, 53908, 53912, 53916, 54040, 54044, 54048, 54052, 54056, 54060, 54412, 54416, 54420, 54424, 54428, 54544, 54548, 54552, 54556, 54560, 54564, 54924, 54928, 54932, 54936, 54940, 54944, 55048, 55052)
        draw64($t4, 55056, 55060, 55064, 55440, 55444, 55448, 55452, 55456, 55552, 55556, 55560, 55564, 55568, 55952, 55956, 55960, 55964, 55968, 55972, 56056, 56060, 56064, 56068, 56072, 56468, 56472, 56476, 56480, 56484, 56560, 56564, 56568, 56572, 56980, 56984, 56988, 56992, 56996, 57000, 57064, 57068, 57072, 57076, 57496, 57500, 57504, 57508, 57512, 57568, 57572, 57576, 58008, 58012, 58016, 58020, 58024, 58028, 58072, 58076, 58080, 58520, 58524, 58528, 58532)
        draw16($t4, 58536, 58540, 58576, 58580, 59036, 59040, 59044, 59048, 59052, 59056, 59080, 59084, 59548, 59552, 59556, 59560)
        draw16($t4, 59564, 59568, 59584, 59588, 60064, 60068, 60072, 60076, 60080, 60084, 60088, 60576, 60580, 60584, 60588, 60592)
        sw $t4 61088($v1)
        sw $t4 61092($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_36
    draw_clear_37: # draw t4, sleep, draw 0
        draw1024($t4, 3432, 3436, 3440, 3932, 3936, 3940, 3944, 3948, 3952, 4432, 4436, 4448, 4452, 4456, 4460, 4464, 4468, 4932, 4936, 4960, 4964, 4968, 4972, 4976, 4980, 5432, 5436, 5440, 5472, 5476, 5480, 5484, 5488, 5492, 5936, 5940, 5988, 5992, 5996, 6000, 6004, 6008, 6436, 6440, 6444, 6500, 6504, 6508, 6512, 6516, 6520, 6936, 6940, 6944, 6948, 7016, 7020, 7024, 7028, 7032, 7436, 7440, 7444, 7448, 7528, 7532, 7536, 7540, 7544, 7548, 7936, 7940, 7944, 7948, 7952, 8040, 8044, 8048, 8052, 8056, 8060, 8436, 8440, 8444, 8448, 8452, 8556, 8560, 8564, 8568, 8572, 8936, 8940, 8944, 8948, 8952, 8956, 9068, 9072, 9076, 9080, 9084, 9088, 9436, 9440, 9444, 9448, 9452, 9456, 9584, 9588, 9592, 9596, 9600, 9936, 9940, 9944, 9948, 9952, 9956, 9960, 10096, 10100, 10104, 10108, 10112, 10436, 10440, 10444, 10448, 10452, 10456, 10460, 10464, 10612, 10616, 10620, 10624, 10628, 10936, 10940, 10944, 10948, 10952, 10956, 10960, 10964, 11124, 11128, 11132, 11136, 11140, 11436, 11440, 11444, 11448, 11452, 11456, 11460, 11464, 11468, 11636, 11640, 11644, 11648, 11652, 11936, 11940, 11944, 11948, 11952, 11956, 11960, 11964, 11968, 12152, 12156, 12160, 12164, 12168, 12436, 12440, 12444, 12448, 12452, 12456, 12460, 12464, 12468, 12472, 12664, 12668, 12672, 12676, 12680, 12936, 12940, 12944, 12948, 12952, 12956, 12960, 12964, 12968, 12972, 12976, 13180, 13184, 13188, 13192, 13196, 13436, 13440, 13444, 13448, 13452, 13456, 13460, 13464, 13468, 13472, 13476, 13692, 13696, 13700, 13704, 13708, 13936, 13940, 13944, 13948, 13952, 13956, 13960, 13964, 13968, 13972, 13976, 13980, 14204, 14208, 14212, 14216, 14220, 14436, 14440, 14444, 14448, 14452, 14456, 14460, 14464, 14468, 14472, 14476, 14480, 14720, 14724, 14728, 14732, 14736, 14940, 14944, 14948, 14952, 14956, 14960, 14964, 14968, 14972, 14976, 14980, 14984, 15232, 15236, 15240, 15244, 15248, 15440, 15444, 15448, 15452, 15456, 15460, 15464, 15468, 15472, 15476, 15480, 15484, 15488, 15748, 15752, 15756, 15760, 15940, 15944, 15948, 15952, 15956, 15960, 15964, 15968, 15972, 15976, 15980, 15984, 15988, 16260, 16264, 16268, 16272, 16276, 16440, 16444, 16448, 16452, 16456, 16460, 16464, 16468, 16472, 16476, 16480, 16484, 16488, 16492, 16772, 16776, 16780, 16784, 16788, 16940, 16944, 16948, 16952, 16956, 16960, 16964, 16968, 16972, 16976, 16980, 16984, 16988, 16992, 17288, 17292, 17296, 17300, 17440, 17444, 17448, 17452, 17456, 17460, 17464, 17468, 17472, 17476, 17480, 17484, 17488, 17492, 17496, 17800, 17804, 17808, 17812, 17816, 17944, 17948, 17952, 17956, 17960, 17964, 17968, 17972, 17976, 17980, 17984, 17988, 17992, 17996, 18316, 18320, 18324, 18328, 18456, 18460, 18464, 18468, 18472, 18476, 18480, 18484, 18488, 18492, 18496, 18500, 18828, 18832, 18836, 18840, 18968, 18972, 18976, 18980, 18984, 18988, 18992, 18996, 19000, 19004, 19344, 19348, 19352, 19356, 19484, 19488, 19492, 19496, 19500, 19504, 19856, 19860, 19864, 19868, 19996, 20000, 20004, 20008, 20368, 20372, 20376, 20380, 20508, 20884, 20888, 20892, 20896, 21396, 21400, 21404, 21408, 21536, 21912, 21916, 21920, 22048, 22424, 22428, 22432, 22436, 22936, 22940, 22944, 22948, 23076, 23452, 23456, 23460, 23588, 23964, 23968, 23972, 23976, 24104, 24480, 24484, 24488, 24616, 24992, 24996, 25000, 25128, 25508, 25512, 25516, 25644, 26020, 26024, 26028, 26156, 26532, 26536, 26540, 26672, 27048, 27052, 27056, 27184, 27560, 27564, 27568, 27696, 27700, 28076, 28080, 28212, 28588, 28592, 28596, 28724, 29100, 29104, 29108, 29236, 29240, 29616, 29620, 29752, 30128, 30132, 30136, 30264, 30268, 30644, 30648, 30776, 30780, 31156, 31160, 31292, 31672, 31676, 31804, 31808, 32184, 32188, 32316, 32320, 32696, 32700, 32832, 32836, 33212, 33216, 33344, 33348, 33724, 33728, 33856, 33860, 34240, 34372, 34376, 34752, 34756, 34884, 34888, 35264, 35268, 35396, 35400, 35404, 35780, 35912, 35916, 36292, 36296, 36424, 36428, 36432, 36808, 36936, 36940, 36944, 37320, 37452, 37456, 37832, 37836, 37964, 37968, 37972, 38348, 38476, 38480, 38484, 38860, 38992, 38996, 39000, 39376, 39504, 39508, 39512, 39888, 40016, 40020, 40024, 40404, 40532, 40536, 40540, 40916, 41044, 41048, 41052, 41428, 41556, 41560, 41564, 41568, 41944, 42072, 42076, 42080, 42456, 42584, 42588, 42592, 42596, 43096, 43100, 43104, 43108, 43484, 43612, 43616, 43620, 43996, 44124, 44128, 44132, 44136, 44636, 44640, 44644, 44648, 45024, 45152, 45156, 45160, 45164, 45524, 45528, 45532, 45536, 45664, 45668, 45672, 45676, 46028, 46032, 46036, 46040, 46044, 46048, 46176, 46180, 46184, 46188, 46528, 46532, 46536, 46540, 46544, 46548, 46552, 46556, 46560, 46564, 46692, 46696, 46700, 46704, 47032, 47036, 47040, 47044, 47048, 47052, 47056, 47060, 47064, 47068, 47072, 47076, 47204, 47208, 47212, 47216, 47536, 47540, 47544, 47548, 47552, 47556, 47560, 47564, 47568, 47572, 47576, 47580, 47584, 47588, 47716, 47720, 47724, 47728, 47732, 48036, 48040, 48044, 48048, 48052, 48056, 48060, 48064, 48068, 48072, 48076, 48080, 48084, 48088, 48092, 48232, 48236, 48240, 48244, 48540, 48544, 48548, 48552, 48556, 48560, 48564, 48568, 48572, 48576, 48580, 48584, 48588, 48592, 48744, 48748, 48752, 48756, 48760, 49040, 49044, 49048, 49052, 49056, 49060, 49064, 49068, 49072, 49076, 49080, 49084, 49088, 49092, 49256, 49260, 49264, 49268, 49272, 49544, 49548, 49552, 49556, 49560, 49564, 49568, 49572, 49576, 49580, 49584, 49588, 49592, 49772, 49776, 49780, 49784, 50044, 50048, 50052, 50056, 50060, 50064, 50068, 50072, 50076, 50080, 50084, 50088, 50092, 50284, 50288, 50292, 50296, 50300, 50548, 50552, 50556, 50560, 50564, 50568, 50572, 50576, 50580, 50584, 50588, 50592, 50796, 50800, 50804, 50808, 50812, 51052, 51056, 51060, 51064, 51068, 51072, 51076, 51080, 51084, 51088, 51092, 51096, 51312, 51316, 51320, 51324, 51328, 51552, 51556, 51560, 51564, 51568, 51572, 51576, 51580, 51584, 51588, 51592, 51596, 51824, 51828, 51832, 51836, 51840, 52056, 52060, 52064, 52068, 52072, 52076, 52080, 52084, 52088, 52092, 52096, 52336, 52340, 52344, 52348, 52352, 52556, 52560, 52564, 52568, 52572, 52576, 52580, 52584, 52588, 52592, 52596, 52852, 52856, 52860, 52864, 52868, 53060, 53064, 53068, 53072, 53076, 53080, 53084, 53088, 53092, 53096, 53364, 53368, 53372, 53376, 53380, 53564, 53568, 53572, 53576, 53580, 53584, 53588, 53592, 53596, 53880, 53884, 53888, 53892, 53896, 54064, 54068, 54072, 54076, 54080, 54084, 54088, 54092, 54096, 54392, 54396, 54400, 54404, 54408, 54568, 54572, 54576, 54580, 54584, 54588, 54592, 54596, 54904, 54908, 54912, 54916, 54920, 55068, 55072, 55076, 55080, 55084, 55088, 55092, 55096, 55420, 55424, 55428, 55432, 55436, 55572, 55576, 55580, 55584, 55588, 55592, 55596, 55932, 55936, 55940, 55944, 55948, 56076, 56080, 56084, 56088, 56092, 56096, 56444, 56448, 56452, 56456, 56460, 56464, 56576, 56580, 56584, 56588, 56592, 56596, 56960, 56964, 56968, 56972, 56976, 57080, 57084, 57088, 57092, 57096, 57472, 57476, 57480, 57484, 57488, 57492, 57580, 57584, 57588, 57592, 57596, 57984, 57988, 57992, 57996, 58000, 58004, 58084, 58088, 58092, 58096, 58500, 58504, 58508, 58512, 58516, 58584, 58588, 58592, 58596, 59012, 59016, 59020, 59024, 59028, 59032, 59088)
        draw16($t4, 59092, 59096, 59524, 59528, 59532, 59536, 59540, 59544, 59592, 59596, 60040, 60044, 60048, 60052, 60056, 60060)
        draw16($t4, 60092, 60096, 60100, 60552, 60556, 60560, 60564, 60568, 60572, 60596, 60600, 61064, 61068, 61072, 61076, 61080)
        draw4($t4, 61084, 61096, 61100, 61580)
        draw4($t4, 61584, 61588, 61592, 61596)
        draw4($t4, 61600, 62092, 62096, 62100)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_37
    draw_clear_38: # draw t4, sleep, draw 0
        draw1024($t4, 2436, 2440, 2932, 2936, 2940, 2944, 2948, 2952, 3428, 3444, 3448, 3452, 3456, 3460, 3464, 3928, 3956, 3960, 3964, 3968, 3972, 3976, 3980, 4424, 4428, 4472, 4476, 4480, 4484, 4488, 4492, 4920, 4924, 4928, 4984, 4988, 4992, 4996, 5000, 5004, 5416, 5420, 5424, 5428, 5496, 5500, 5504, 5508, 5512, 5516, 5916, 5920, 5924, 5928, 5932, 6012, 6016, 6020, 6024, 6028, 6032, 6412, 6416, 6420, 6424, 6428, 6432, 6524, 6528, 6532, 6536, 6540, 6544, 6908, 6912, 6916, 6920, 6924, 6928, 6932, 7036, 7040, 7044, 7048, 7052, 7056, 7404, 7408, 7412, 7416, 7420, 7424, 7428, 7432, 7552, 7556, 7560, 7564, 7568, 7904, 7908, 7912, 7916, 7920, 7924, 7928, 7932, 8064, 8068, 8072, 8076, 8080, 8084, 8400, 8404, 8408, 8412, 8416, 8420, 8424, 8428, 8432, 8576, 8580, 8584, 8588, 8592, 8596, 8896, 8900, 8904, 8908, 8912, 8916, 8920, 8924, 8928, 8932, 9092, 9096, 9100, 9104, 9108, 9392, 9396, 9400, 9404, 9408, 9412, 9416, 9420, 9424, 9428, 9432, 9604, 9608, 9612, 9616, 9620, 9624, 9892, 9896, 9900, 9904, 9908, 9912, 9916, 9920, 9924, 9928, 9932, 10116, 10120, 10124, 10128, 10132, 10136, 10388, 10392, 10396, 10400, 10404, 10408, 10412, 10416, 10420, 10424, 10428, 10432, 10632, 10636, 10640, 10644, 10648, 10884, 10888, 10892, 10896, 10900, 10904, 10908, 10912, 10916, 10920, 10924, 10928, 10932, 11144, 11148, 11152, 11156, 11160, 11384, 11388, 11392, 11396, 11400, 11404, 11408, 11412, 11416, 11420, 11424, 11428, 11432, 11656, 11660, 11664, 11668, 11672, 11676, 11880, 11884, 11888, 11892, 11896, 11900, 11904, 11908, 11912, 11916, 11920, 11924, 11928, 11932, 12172, 12176, 12180, 12184, 12188, 12376, 12380, 12384, 12388, 12392, 12396, 12400, 12404, 12408, 12412, 12416, 12420, 12424, 12428, 12432, 12684, 12688, 12692, 12696, 12700, 12872, 12876, 12880, 12884, 12888, 12892, 12896, 12900, 12904, 12908, 12912, 12916, 12920, 12924, 12928, 12932, 13200, 13204, 13208, 13212, 13372, 13376, 13380, 13384, 13388, 13392, 13396, 13400, 13404, 13408, 13412, 13416, 13420, 13424, 13428, 13432, 13712, 13716, 13720, 13724, 13728, 13868, 13872, 13876, 13880, 13884, 13888, 13892, 13896, 13900, 13904, 13908, 13912, 13916, 13920, 13924, 13928, 13932, 14224, 14228, 14232, 14236, 14240, 14364, 14368, 14372, 14376, 14380, 14384, 14388, 14392, 14396, 14400, 14404, 14408, 14412, 14416, 14420, 14424, 14428, 14432, 14740, 14744, 14748, 14752, 14864, 14868, 14872, 14876, 14880, 14884, 14888, 14892, 14896, 14900, 14904, 14908, 14912, 14916, 14920, 14924, 14928, 14932, 14936, 15252, 15256, 15260, 15264, 15376, 15380, 15384, 15388, 15392, 15396, 15400, 15404, 15408, 15412, 15416, 15420, 15424, 15428, 15432, 15436, 15764, 15768, 15772, 15776, 15780, 15892, 15896, 15900, 15904, 15908, 15912, 15916, 15920, 15924, 15928, 15932, 15936, 16280, 16284, 16288, 16292, 16404, 16408, 16412, 16416, 16420, 16424, 16428, 16432, 16436, 16792, 16796, 16800, 16804, 16916, 16920, 16924, 16928, 16932, 16936, 17304, 17308, 17312, 17316, 17320, 17428, 17432, 17436, 17820, 17824, 17828, 17832, 18332, 18336, 18340, 18344, 18844, 18848, 18852, 18856, 19360, 19364, 19368, 19372, 19480, 19872, 19876, 19880, 19884, 20384, 20388, 20392, 20396, 20900, 20904, 20908, 21020, 21412, 21416, 21420, 21424, 21924, 21928, 21932, 21936, 22440, 22444, 22448, 22560, 22952, 22956, 22960, 22964, 23072, 23464, 23468, 23472, 23476, 23980, 23984, 23988, 24100, 24492, 24496, 24500, 24612, 25004, 25008, 25012, 25016, 25124, 25520, 25524, 25528, 25640, 26032, 26036, 26040, 26152, 26544, 26548, 26552, 26664, 26668, 27060, 27064, 27068, 27176, 27180, 27572, 27576, 27580, 27692, 28084, 28088, 28092, 28204, 28208, 28600, 28604, 28716, 28720, 29112, 29116, 29120, 29232, 29624, 29628, 29632, 29744, 29748, 30140, 30144, 30256, 30260, 30652, 30656, 30660, 30768, 30772, 31164, 31168, 31172, 31284, 31288, 31680, 31684, 31796, 31800, 32192, 32196, 32308, 32312, 32704, 32708, 32712, 32820, 32824, 32828, 33220, 33224, 33336, 33340, 33732, 33736, 33848, 33852, 34244, 34248, 34360, 34364, 34368, 34760, 34764, 34872, 34876, 34880, 35272, 35276, 35388, 35392, 35784, 35788, 35900, 35904, 35908, 36300, 36412, 36416, 36420, 36812, 36816, 36928, 36932, 37324, 37328, 37440, 37444, 37448, 37840, 37952, 37956, 37960, 38352, 38356, 38464, 38468, 38472, 38864, 38868, 38980, 38984, 38988, 39380, 39492, 39496, 39500, 39892, 40004, 40008, 40012, 40408, 40516, 40520, 40524, 40528, 40920, 41032, 41036, 41040, 41432, 41544, 41548, 41552, 42056, 42060, 42064, 42068, 42460, 42568, 42572, 42576, 42580, 42972, 43084, 43088, 43092, 43596, 43600, 43604, 43608, 44108, 44112, 44116, 44120, 44512, 44624, 44628, 44632, 45136, 45140, 45144, 45148, 45648, 45652, 45656, 45660, 46052, 46160, 46164, 46168, 46172, 46676, 46680, 46684, 46688, 47188, 47192, 47196, 47200, 47700, 47704, 47708, 47712, 48096, 48100, 48104, 48212, 48216, 48220, 48224, 48228, 48596, 48600, 48604, 48608, 48612, 48616, 48728, 48732, 48736, 48740, 49096, 49100, 49104, 49108, 49112, 49116, 49120, 49124, 49128, 49240, 49244, 49248, 49252, 49596, 49600, 49604, 49608, 49612, 49616, 49620, 49624, 49628, 49632, 49636, 49640, 49752, 49756, 49760, 49764, 49768, 50096, 50100, 50104, 50108, 50112, 50116, 50120, 50124, 50128, 50132, 50136, 50140, 50144, 50148, 50152, 50156, 50268, 50272, 50276, 50280, 50596, 50600, 50604, 50608, 50612, 50616, 50620, 50624, 50628, 50632, 50636, 50640, 50644, 50648, 50652, 50656, 50660, 50664, 50668, 50780, 50784, 50788, 50792, 51100, 51104, 51108, 51112, 51116, 51120, 51124, 51128, 51132, 51136, 51140, 51144, 51148, 51152, 51156, 51160, 51164, 51168, 51292, 51296, 51300, 51304, 51308, 51600, 51604, 51608, 51612, 51616, 51620, 51624, 51628, 51632, 51636, 51640, 51644, 51648, 51652, 51656, 51660, 51664, 51804, 51808, 51812, 51816, 51820, 52100, 52104, 52108, 52112, 52116, 52120, 52124, 52128, 52132, 52136, 52140, 52144, 52148, 52152, 52156, 52160, 52320, 52324, 52328, 52332, 52600, 52604, 52608, 52612, 52616, 52620, 52624, 52628, 52632, 52636, 52640, 52644, 52648, 52652, 52656, 52660, 52832, 52836, 52840, 52844, 52848, 53100, 53104, 53108, 53112, 53116, 53120, 53124, 53128, 53132, 53136, 53140, 53144, 53148, 53152, 53156, 53344, 53348, 53352, 53356, 53360, 53600, 53604, 53608, 53612, 53616, 53620, 53624, 53628, 53632, 53636, 53640, 53644, 53648, 53652, 53856, 53860, 53864, 53868, 53872, 53876, 54100, 54104, 54108, 54112, 54116, 54120, 54124, 54128, 54132, 54136, 54140, 54144, 54148, 54372, 54376, 54380, 54384, 54388, 54600, 54604, 54608, 54612, 54616, 54620, 54624, 54628, 54632, 54636, 54640, 54644, 54648, 54884, 54888, 54892, 54896, 54900, 55100, 55104, 55108, 55112, 55116, 55120, 55124, 55128, 55132, 55136, 55140, 55144, 55396, 55400, 55404, 55408, 55412, 55416, 55600, 55604, 55608, 55612, 55616, 55620, 55624, 55628, 55632, 55636, 55640, 55908, 55912, 55916, 55920, 55924, 55928, 56100, 56104, 56108, 56112, 56116, 56120, 56124, 56128, 56132, 56136, 56140, 56424, 56428, 56432, 56436, 56440, 56600, 56604, 56608, 56612, 56616, 56620, 56624, 56628, 56632, 56636, 56936, 56940, 56944, 56948, 56952, 56956, 57100, 57104, 57108, 57112, 57116, 57120)
        draw64($t4, 57124, 57128, 57132, 57448, 57452, 57456, 57460, 57464, 57468, 57600, 57604, 57608, 57612, 57616, 57620, 57624, 57628, 57964, 57968, 57972, 57976, 57980, 58100, 58104, 58108, 58112, 58116, 58120, 58124, 58128, 58476, 58480, 58484, 58488, 58492, 58496, 58600, 58604, 58608, 58612, 58616, 58620, 58624, 58988, 58992, 58996, 59000, 59004, 59008, 59100, 59104, 59108, 59112, 59116, 59120, 59500, 59504, 59508, 59512, 59516, 59520, 59600, 59604, 59608)
        draw16($t4, 59612, 59616, 60016, 60020, 60024, 60028, 60032, 60036, 60104, 60108, 60112, 60116, 60528, 60532, 60536, 60540)
        draw16($t4, 60544, 60548, 60604, 60608, 60612, 61040, 61044, 61048, 61052, 61056, 61060, 61104, 61108, 61552, 61556, 61560)
        draw16($t4, 61564, 61568, 61572, 61576, 61604, 62068, 62072, 62076, 62080, 62084, 62088, 62104, 62580, 62584, 62588, 62592)
        draw4($t4, 62596, 62600, 63092, 63096)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_38
    draw_clear_39: # draw t4, sleep, draw 0
        draw1024($t4, 1428, 1432, 1436, 1440, 1920, 1924, 1928, 1932, 1936, 1940, 1944, 1948, 1952, 2412, 2416, 2420, 2424, 2428, 2432, 2444, 2448, 2452, 2456, 2460, 2464, 2904, 2908, 2912, 2916, 2920, 2924, 2928, 2956, 2960, 2964, 2968, 2972, 2976, 3396, 3400, 3404, 3408, 3412, 3416, 3420, 3424, 3468, 3472, 3476, 3480, 3484, 3488, 3492, 3888, 3892, 3896, 3900, 3904, 3908, 3912, 3916, 3920, 3924, 3984, 3988, 3992, 3996, 4000, 4004, 4380, 4384, 4388, 4392, 4396, 4400, 4404, 4408, 4412, 4416, 4420, 4496, 4500, 4504, 4508, 4512, 4516, 4872, 4876, 4880, 4884, 4888, 4892, 4896, 4900, 4904, 4908, 4912, 4916, 5008, 5012, 5016, 5020, 5024, 5028, 5364, 5368, 5372, 5376, 5380, 5384, 5388, 5392, 5396, 5400, 5404, 5408, 5412, 5520, 5524, 5528, 5532, 5536, 5540, 5856, 5860, 5864, 5868, 5872, 5876, 5880, 5884, 5888, 5892, 5896, 5900, 5904, 5908, 5912, 6036, 6040, 6044, 6048, 6052, 6056, 6348, 6352, 6356, 6360, 6364, 6368, 6372, 6376, 6380, 6384, 6388, 6392, 6396, 6400, 6404, 6408, 6548, 6552, 6556, 6560, 6564, 6568, 6840, 6844, 6848, 6852, 6856, 6860, 6864, 6868, 6872, 6876, 6880, 6884, 6888, 6892, 6896, 6900, 6904, 7060, 7064, 7068, 7072, 7076, 7080, 7332, 7336, 7340, 7344, 7348, 7352, 7356, 7360, 7364, 7368, 7372, 7376, 7380, 7384, 7388, 7392, 7396, 7400, 7572, 7576, 7580, 7584, 7588, 7592, 7824, 7828, 7832, 7836, 7840, 7844, 7848, 7852, 7856, 7860, 7864, 7868, 7872, 7876, 7880, 7884, 7888, 7892, 7896, 7900, 8088, 8092, 8096, 8100, 8104, 8316, 8320, 8324, 8328, 8332, 8336, 8340, 8344, 8348, 8352, 8356, 8360, 8364, 8368, 8372, 8376, 8380, 8384, 8388, 8392, 8396, 8600, 8604, 8608, 8612, 8616, 8620, 8808, 8812, 8816, 8820, 8824, 8828, 8832, 8836, 8840, 8844, 8848, 8852, 8856, 8860, 8864, 8868, 8872, 8876, 8880, 8884, 8888, 8892, 9112, 9116, 9120, 9124, 9128, 9132, 9300, 9304, 9308, 9312, 9316, 9320, 9324, 9328, 9332, 9336, 9340, 9344, 9348, 9352, 9356, 9360, 9364, 9368, 9372, 9376, 9380, 9384, 9388, 9628, 9632, 9636, 9640, 9644, 9792, 9796, 9800, 9804, 9808, 9812, 9816, 9820, 9824, 9828, 9832, 9836, 9840, 9844, 9848, 9852, 9856, 9860, 9864, 9868, 9872, 9876, 9880, 9884, 9888, 10140, 10144, 10148, 10152, 10156, 10284, 10288, 10292, 10296, 10300, 10304, 10308, 10312, 10316, 10320, 10324, 10328, 10332, 10336, 10340, 10344, 10348, 10352, 10356, 10360, 10364, 10368, 10372, 10376, 10380, 10384, 10652, 10656, 10660, 10664, 10668, 10776, 10780, 10784, 10788, 10792, 10796, 10800, 10804, 10808, 10812, 10816, 10820, 10824, 10828, 10832, 10836, 10840, 10844, 10848, 10852, 10856, 10860, 10864, 10868, 10872, 10876, 10880, 11164, 11168, 11172, 11176, 11180, 11184, 11272, 11276, 11280, 11284, 11288, 11292, 11296, 11300, 11304, 11308, 11312, 11316, 11320, 11324, 11328, 11332, 11336, 11340, 11344, 11348, 11352, 11356, 11360, 11364, 11368, 11372, 11376, 11380, 11680, 11684, 11688, 11692, 11696, 11784, 11788, 11792, 11796, 11800, 11804, 11808, 11812, 11816, 11820, 11824, 11828, 11832, 11836, 11840, 11844, 11848, 11852, 11856, 11860, 11864, 11868, 11872, 11876, 12192, 12196, 12200, 12204, 12208, 12296, 12300, 12304, 12308, 12312, 12316, 12320, 12324, 12328, 12332, 12336, 12340, 12344, 12348, 12352, 12356, 12360, 12364, 12368, 12372, 12704, 12708, 12712, 12716, 12720, 12808, 12812, 12816, 12820, 12824, 12828, 12832, 12836, 12840, 12844, 12848, 12852, 12856, 12860, 12864, 12868, 13216, 13220, 13224, 13228, 13232, 13324, 13328, 13332, 13336, 13340, 13344, 13348, 13352, 13356, 13360, 13364, 13368, 13732, 13736, 13740, 13744, 13748, 13836, 13840, 13844, 13848, 13852, 13856, 13860, 13864, 14244, 14248, 14252, 14256, 14260, 14348, 14352, 14356, 14360, 14756, 14760, 14764, 14768, 14772, 14860, 15268, 15272, 15276, 15280, 15284, 15372, 15784, 15788, 15792, 15796, 15888, 16296, 16300, 16304, 16308, 16312, 16400, 16808, 16812, 16816, 16820, 16824, 16912, 17324, 17328, 17332, 17336, 17424, 17836, 17840, 17844, 17848, 17936, 17940, 18348, 18352, 18356, 18360, 18452, 18860, 18864, 18868, 18872, 18876, 18964, 19376, 19380, 19384, 19388, 19476, 19888, 19892, 19896, 19900, 19988, 19992, 20400, 20404, 20408, 20412, 20500, 20504, 20912, 20916, 20920, 20924, 21016, 21428, 21432, 21436, 21440, 21528, 21532, 21940, 21944, 21948, 21952, 22040, 22044, 22452, 22456, 22460, 22464, 22552, 22556, 22968, 22972, 22976, 23064, 23068, 23480, 23484, 23488, 23580, 23584, 23992, 23996, 24000, 24004, 24092, 24096, 24504, 24508, 24512, 24516, 24604, 24608, 25020, 25024, 25028, 25116, 25120, 25532, 25536, 25540, 25628, 25632, 25636, 26044, 26048, 26052, 26144, 26148, 26556, 26560, 26564, 26568, 26656, 26660, 27072, 27076, 27080, 27168, 27172, 27584, 27588, 27592, 27680, 27684, 27688, 28096, 28100, 28104, 28192, 28196, 28200, 28608, 28612, 28616, 28708, 28712, 29124, 29128, 29132, 29220, 29224, 29228, 29636, 29640, 29644, 29732, 29736, 29740, 30148, 30152, 30156, 30244, 30248, 30252, 30664, 30668, 30756, 30760, 30764, 31176, 31180, 31272, 31276, 31280, 31688, 31692, 31696, 31784, 31788, 31792, 32200, 32204, 32208, 32296, 32300, 32304, 32716, 32720, 32808, 32812, 32816, 33228, 33232, 33320, 33324, 33328, 33332, 33740, 33744, 33836, 33840, 33844, 34252, 34256, 34260, 34348, 34352, 34356, 34768, 34772, 34860, 34864, 34868, 35280, 35284, 35372, 35376, 35380, 35384, 35792, 35796, 35884, 35888, 35892, 35896, 36304, 36308, 36400, 36404, 36408, 36820, 36824, 36912, 36916, 36920, 36924, 37332, 37336, 37424, 37428, 37432, 37436, 37844, 37848, 37936, 37940, 37944, 37948, 38360, 38448, 38452, 38456, 38460, 38872, 38964, 38968, 38972, 38976, 39384, 39388, 39476, 39480, 39484, 39488, 39896, 39900, 39988, 39992, 39996, 40000, 40412, 40500, 40504, 40508, 40512, 40924, 41012, 41016, 41020, 41024, 41028, 41436, 41528, 41532, 41536, 41540, 41948, 41952, 42040, 42044, 42048, 42052, 42464, 42552, 42556, 42560, 42564, 42976, 43064, 43068, 43072, 43076, 43080, 43488, 43576, 43580, 43584, 43588, 43592, 44000, 44092, 44096, 44100, 44104, 44516, 44604, 44608, 44612, 44616, 44620, 45028, 45116, 45120, 45124, 45128, 45132, 45540, 45628, 45632, 45636, 45640, 45644, 46140, 46144, 46148, 46152, 46156, 46656, 46660, 46664, 46668, 46672, 47080, 47168, 47172, 47176, 47180, 47184, 47592, 47680, 47684, 47688, 47692, 47696, 48192, 48196, 48200, 48204, 48208, 48704, 48708, 48712, 48716, 48720, 48724, 49220, 49224, 49228, 49232, 49236, 49644, 49732, 49736, 49740, 49744, 49748, 50244, 50248, 50252, 50256, 50260, 50264, 50756, 50760, 50764, 50768, 50772, 50776, 51172, 51176, 51180, 51268, 51272, 51276, 51280, 51284, 51288, 51668, 51672, 51676, 51680, 51684, 51688, 51692, 51784, 51788, 51792, 51796, 51800, 52164, 52168, 52172, 52176, 52180, 52184, 52188, 52192, 52196, 52200, 52204, 52208, 52296, 52300, 52304, 52308, 52312, 52316, 52664, 52668, 52672, 52676, 52680, 52684, 52688, 52692, 52696, 52700, 52704, 52708, 52712, 52716, 52720, 52808, 52812, 52816, 52820, 52824, 52828, 53160, 53164, 53168, 53172, 53176, 53180, 53184, 53188)
        draw256($t4, 53192, 53196, 53200, 53204, 53208, 53212, 53216, 53220, 53224, 53228, 53232, 53320, 53324, 53328, 53332, 53336, 53340, 53656, 53660, 53664, 53668, 53672, 53676, 53680, 53684, 53688, 53692, 53696, 53700, 53704, 53708, 53712, 53716, 53720, 53724, 53728, 53732, 53736, 53740, 53744, 53832, 53836, 53840, 53844, 53848, 53852, 54152, 54156, 54160, 54164, 54168, 54172, 54176, 54180, 54184, 54188, 54192, 54196, 54200, 54204, 54208, 54212, 54216, 54220, 54224, 54228, 54232, 54236, 54240, 54348, 54352, 54356, 54360, 54364, 54368, 54652, 54656, 54660, 54664, 54668, 54672, 54676, 54680, 54684, 54688, 54692, 54696, 54700, 54704, 54708, 54712, 54716, 54720, 54724, 54728, 54732, 54860, 54864, 54868, 54872, 54876, 54880, 55148, 55152, 55156, 55160, 55164, 55168, 55172, 55176, 55180, 55184, 55188, 55192, 55196, 55200, 55204, 55208, 55212, 55216, 55220, 55224, 55372, 55376, 55380, 55384, 55388, 55392, 55644, 55648, 55652, 55656, 55660, 55664, 55668, 55672, 55676, 55680, 55684, 55688, 55692, 55696, 55700, 55704, 55708, 55712, 55716, 55884, 55888, 55892, 55896, 55900, 55904, 56144, 56148, 56152, 56156, 56160, 56164, 56168, 56172, 56176, 56180, 56184, 56188, 56192, 56196, 56200, 56204, 56208, 56396, 56400, 56404, 56408, 56412, 56416, 56420, 56640, 56644, 56648, 56652, 56656, 56660, 56664, 56668, 56672, 56676, 56680, 56684, 56688, 56692, 56696, 56700, 56912, 56916, 56920, 56924, 56928, 56932, 57136, 57140, 57144, 57148, 57152, 57156, 57160, 57164, 57168, 57172, 57176, 57180, 57184, 57188, 57192, 57424, 57428, 57432, 57436, 57440, 57444, 57632, 57636, 57640, 57644, 57648, 57652, 57656, 57660, 57664, 57668, 57672, 57676, 57680, 57684, 57936, 57940, 57944, 57948, 57952, 57956, 57960, 58132, 58136, 58140, 58144, 58148, 58152, 58156, 58160, 58164, 58168, 58172, 58176, 58448, 58452, 58456)
        draw64($t4, 58460, 58464, 58468, 58472, 58628, 58632, 58636, 58640, 58644, 58648, 58652, 58656, 58660, 58664, 58668, 58960, 58964, 58968, 58972, 58976, 58980, 58984, 59124, 59128, 59132, 59136, 59140, 59144, 59148, 59152, 59156, 59160, 59476, 59480, 59484, 59488, 59492, 59496, 59620, 59624, 59628, 59632, 59636, 59640, 59644, 59648, 59652, 59988, 59992, 59996, 60000, 60004, 60008, 60012, 60120, 60124, 60128, 60132, 60136, 60140, 60144, 60500, 60504, 60508)
        draw16($t4, 60512, 60516, 60520, 60524, 60616, 60620, 60624, 60628, 60632, 60636, 61012, 61016, 61020, 61024, 61028, 61032)
        draw16($t4, 61036, 61112, 61116, 61120, 61124, 61128, 61524, 61528, 61532, 61536, 61540, 61544, 61548, 61608, 61612, 61616)
        draw16($t4, 61620, 62040, 62044, 62048, 62052, 62056, 62060, 62064, 62108, 62112, 62552, 62556, 62560, 62564, 62568, 62572)
        draw4($t4, 62576, 62604, 63064, 63068)
        draw4($t4, 63072, 63076, 63080, 63084)
        draw4($t4, 63088, 63576, 63580, 63584)
        sw $t4 63588($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_39
    draw_clear_40: # draw t4, sleep, draw 0
        draw1024($t4, 952, 956, 1444, 1448, 1452, 1456, 1460, 1464, 1468, 1916, 1956, 1960, 1964, 1968, 1972, 1976, 1980, 1984, 2396, 2400, 2404, 2408, 2468, 2472, 2476, 2480, 2484, 2488, 2492, 2496, 2876, 2880, 2884, 2888, 2892, 2896, 2900, 2980, 2984, 2988, 2992, 2996, 3000, 3004, 3008, 3360, 3364, 3368, 3372, 3376, 3380, 3384, 3388, 3392, 3496, 3500, 3504, 3508, 3512, 3516, 3520, 3840, 3844, 3848, 3852, 3856, 3860, 3864, 3868, 3872, 3876, 3880, 3884, 4008, 4012, 4016, 4020, 4024, 4028, 4032, 4324, 4328, 4332, 4336, 4340, 4344, 4348, 4352, 4356, 4360, 4364, 4368, 4372, 4376, 4520, 4524, 4528, 4532, 4536, 4540, 4544, 4804, 4808, 4812, 4816, 4820, 4824, 4828, 4832, 4836, 4840, 4844, 4848, 4852, 4856, 4860, 4864, 4868, 5032, 5036, 5040, 5044, 5048, 5052, 5056, 5284, 5288, 5292, 5296, 5300, 5304, 5308, 5312, 5316, 5320, 5324, 5328, 5332, 5336, 5340, 5344, 5348, 5352, 5356, 5360, 5544, 5548, 5552, 5556, 5560, 5564, 5568, 5768, 5772, 5776, 5780, 5784, 5788, 5792, 5796, 5800, 5804, 5808, 5812, 5816, 5820, 5824, 5828, 5832, 5836, 5840, 5844, 5848, 5852, 6060, 6064, 6068, 6072, 6076, 6080, 6084, 6248, 6252, 6256, 6260, 6264, 6268, 6272, 6276, 6280, 6284, 6288, 6292, 6296, 6300, 6304, 6308, 6312, 6316, 6320, 6324, 6328, 6332, 6336, 6340, 6344, 6572, 6576, 6580, 6584, 6588, 6592, 6596, 6732, 6736, 6740, 6744, 6748, 6752, 6756, 6760, 6764, 6768, 6772, 6776, 6780, 6784, 6788, 6792, 6796, 6800, 6804, 6808, 6812, 6816, 6820, 6824, 6828, 6832, 6836, 7084, 7088, 7092, 7096, 7100, 7104, 7108, 7212, 7216, 7220, 7224, 7228, 7232, 7236, 7240, 7244, 7248, 7252, 7256, 7260, 7264, 7268, 7272, 7276, 7280, 7284, 7288, 7292, 7296, 7300, 7304, 7308, 7312, 7316, 7320, 7324, 7328, 7596, 7600, 7604, 7608, 7612, 7616, 7620, 7692, 7696, 7700, 7704, 7708, 7712, 7716, 7720, 7724, 7728, 7732, 7736, 7740, 7744, 7748, 7752, 7756, 7760, 7764, 7768, 7772, 7776, 7780, 7784, 7788, 7792, 7796, 7800, 7804, 7808, 7812, 7816, 7820, 8108, 8112, 8116, 8120, 8124, 8128, 8132, 8196, 8200, 8204, 8208, 8212, 8216, 8220, 8224, 8228, 8232, 8236, 8240, 8244, 8248, 8252, 8256, 8260, 8264, 8268, 8272, 8276, 8280, 8284, 8288, 8292, 8296, 8300, 8304, 8308, 8312, 8624, 8628, 8632, 8636, 8640, 8644, 8708, 8712, 8716, 8720, 8724, 8728, 8732, 8736, 8740, 8744, 8748, 8752, 8756, 8760, 8764, 8768, 8772, 8776, 8780, 8784, 8788, 8792, 8796, 8800, 8804, 9136, 9140, 9144, 9148, 9152, 9156, 9224, 9228, 9232, 9236, 9240, 9244, 9248, 9252, 9256, 9260, 9264, 9268, 9272, 9276, 9280, 9284, 9288, 9292, 9296, 9648, 9652, 9656, 9660, 9664, 9668, 9736, 9740, 9744, 9748, 9752, 9756, 9760, 9764, 9768, 9772, 9776, 9780, 9784, 9788, 10160, 10164, 10168, 10172, 10176, 10180, 10184, 10248, 10252, 10256, 10260, 10264, 10268, 10272, 10276, 10280, 10672, 10676, 10680, 10684, 10688, 10692, 10696, 10760, 10764, 10768, 10772, 11188, 11192, 11196, 11200, 11204, 11208, 11700, 11704, 11708, 11712, 11716, 11720, 12212, 12216, 12220, 12224, 12228, 12232, 12724, 12728, 12732, 12736, 12740, 12744, 13236, 13240, 13244, 13248, 13252, 13256, 13752, 13756, 13760, 13764, 13768, 13772, 14264, 14268, 14272, 14276, 14280, 14284, 14776, 14780, 14784, 14788, 14792, 14796, 15288, 15292, 15296, 15300, 15304, 15308, 15800, 15804, 15808, 15812, 15816, 15820, 15884, 16316, 16320, 16324, 16328, 16332, 16396, 16828, 16832, 16836, 16840, 16844, 17340, 17344, 17348, 17352, 17356, 17852, 17856, 17860, 17864, 17868, 17872, 18364, 18368, 18372, 18376, 18380, 18384, 18448, 18880, 18884, 18888, 18892, 18896, 18960, 19392, 19396, 19400, 19404, 19408, 19472, 19904, 19908, 19912, 19916, 19920, 19984, 20416, 20420, 20424, 20428, 20432, 20496, 20928, 20932, 20936, 20940, 20944, 21012, 21444, 21448, 21452, 21456, 21460, 21524, 21956, 21960, 21964, 21968, 21972, 22036, 22468, 22472, 22476, 22480, 22484, 22548, 22980, 22984, 22988, 22992, 22996, 23060, 23492, 23496, 23500, 23504, 23508, 23572, 23576, 24008, 24012, 24016, 24020, 24084, 24088, 24520, 24524, 24528, 24532, 24596, 24600, 25032, 25036, 25040, 25044, 25112, 25544, 25548, 25552, 25556, 25560, 25624, 26056, 26060, 26064, 26068, 26072, 26136, 26140, 26572, 26576, 26580, 26584, 26648, 26652, 27084, 27088, 27092, 27096, 27160, 27164, 27596, 27600, 27604, 27608, 27672, 27676, 28108, 28112, 28116, 28120, 28184, 28188, 28620, 28624, 28628, 28632, 28700, 28704, 29136, 29140, 29144, 29212, 29216, 29648, 29652, 29656, 29660, 29724, 29728, 30160, 30164, 30168, 30172, 30236, 30240, 30672, 30676, 30680, 30684, 30748, 30752, 31184, 31188, 31192, 31196, 31260, 31264, 31268, 31700, 31704, 31708, 31772, 31776, 31780, 32212, 32216, 32220, 32284, 32288, 32292, 32724, 32728, 32732, 32800, 32804, 33236, 33240, 33244, 33248, 33312, 33316, 33748, 33752, 33756, 33760, 33824, 33828, 33832, 34264, 34268, 34272, 34336, 34340, 34344, 34776, 34780, 34784, 34848, 34852, 34856, 35288, 35292, 35296, 35360, 35364, 35368, 35800, 35804, 35808, 35872, 35876, 35880, 36312, 36316, 36320, 36388, 36392, 36396, 36828, 36832, 36900, 36904, 36908, 37340, 37344, 37348, 37412, 37416, 37420, 37852, 37856, 37860, 37924, 37928, 37932, 38364, 38368, 38372, 38436, 38440, 38444, 38876, 38880, 38884, 38948, 38952, 38956, 38960, 39392, 39396, 39460, 39464, 39468, 39472, 39904, 39908, 39972, 39976, 39980, 39984, 40416, 40420, 40488, 40492, 40496, 40928, 40932, 40936, 41000, 41004, 41008, 41440, 41444, 41448, 41512, 41516, 41520, 41524, 41956, 41960, 42024, 42028, 42032, 42036, 42468, 42472, 42536, 42540, 42544, 42548, 42980, 42984, 43048, 43052, 43056, 43060, 43492, 43496, 43560, 43564, 43568, 43572, 44004, 44008, 44072, 44076, 44080, 44084, 44088, 44520, 44588, 44592, 44596, 44600, 45032, 45036, 45100, 45104, 45108, 45112, 45544, 45548, 45612, 45616, 45620, 45624, 46056, 46060, 46124, 46128, 46132, 46136, 46568, 46572, 46636, 46640, 46644, 46648, 46652, 47084, 47148, 47152, 47156, 47160, 47164, 47596, 47660, 47664, 47668, 47672, 47676, 48108, 48176, 48180, 48184, 48188, 48620, 48688, 48692, 48696, 48700, 49132, 49136, 49200, 49204, 49208, 49212, 49216, 49648, 49712, 49716, 49720, 49724, 49728, 50160, 50224, 50228, 50232, 50236, 50240, 50672, 50736, 50740, 50744, 50748, 50752, 51184, 51248, 51252, 51256, 51260, 51264, 51696, 51760, 51764, 51768, 51772, 51776, 51780, 52276, 52280, 52284, 52288, 52292, 52724, 52788, 52792, 52796, 52800, 52804, 53236, 53300, 53304, 53308, 53312, 53316, 53748, 53812, 53816, 53820, 53824, 53828, 54244, 54248, 54252, 54256, 54260, 54324, 54328, 54332, 54336, 54340, 54344, 54736, 54740, 54744, 54748, 54752, 54756, 54760, 54764, 54768, 54772, 54836, 54840, 54844, 54848, 54852, 54856, 55228, 55232, 55236, 55240, 55244, 55248, 55252, 55256, 55260, 55264, 55268, 55272, 55276, 55280, 55284, 55348, 55352, 55356, 55360, 55364, 55368, 55720, 55724, 55728, 55732, 55736, 55740, 55744, 55748, 55752, 55756, 55760, 55764, 55768, 55772)
        draw256($t4, 55776, 55780, 55784, 55788, 55792, 55796, 55864, 55868, 55872, 55876, 55880, 56212, 56216, 56220, 56224, 56228, 56232, 56236, 56240, 56244, 56248, 56252, 56256, 56260, 56264, 56268, 56272, 56276, 56280, 56284, 56288, 56292, 56296, 56300, 56304, 56308, 56376, 56380, 56384, 56388, 56392, 56704, 56708, 56712, 56716, 56720, 56724, 56728, 56732, 56736, 56740, 56744, 56748, 56752, 56756, 56760, 56764, 56768, 56772, 56776, 56780, 56784, 56788, 56792, 56796, 56800, 56804, 56808, 56812, 56816, 56820, 56824, 56888, 56892, 56896, 56900, 56904, 56908, 57196, 57200, 57204, 57208, 57212, 57216, 57220, 57224, 57228, 57232, 57236, 57240, 57244, 57248, 57252, 57256, 57260, 57264, 57268, 57272, 57276, 57280, 57284, 57288, 57292, 57296, 57300, 57304, 57308, 57312, 57316, 57320, 57324, 57328, 57332, 57336, 57400, 57404, 57408, 57412, 57416, 57420, 57688, 57692, 57696, 57700, 57704, 57708, 57712, 57716, 57720, 57724, 57728, 57732, 57736, 57740, 57744, 57748, 57752, 57756, 57760, 57764, 57768, 57772, 57776, 57780, 57784, 57788, 57792, 57796, 57800, 57804, 57808, 57812, 57816, 57820, 57824, 57828, 57832, 57836, 57840, 57912, 57916, 57920, 57924, 57928, 57932, 58180, 58184, 58188, 58192, 58196, 58200, 58204, 58208, 58212, 58216, 58220, 58224, 58228, 58232, 58236, 58240, 58244, 58248, 58252, 58256, 58260, 58264, 58268, 58272, 58276, 58280, 58284, 58288, 58292, 58296, 58300, 58304, 58308, 58312, 58316, 58320, 58424, 58428, 58432, 58436, 58440, 58444, 58672, 58676, 58680, 58684, 58688, 58692, 58696, 58700, 58704, 58708, 58712, 58716, 58720, 58724, 58728, 58732, 58736, 58740, 58744, 58748, 58752, 58756, 58760, 58764, 58768, 58772, 58776, 58780, 58784, 58788, 58792, 58796, 58800, 58936, 58940, 58944, 58948, 58952, 58956, 59164, 59168, 59172, 59176, 59180, 59184, 59188, 59192, 59196, 59200)
        draw64($t4, 59204, 59208, 59212, 59216, 59220, 59224, 59228, 59232, 59236, 59240, 59244, 59248, 59252, 59256, 59260, 59264, 59268, 59272, 59276, 59280, 59284, 59448, 59452, 59456, 59460, 59464, 59468, 59472, 59656, 59660, 59664, 59668, 59672, 59676, 59680, 59684, 59688, 59692, 59696, 59700, 59704, 59708, 59712, 59716, 59720, 59724, 59728, 59732, 59736, 59740, 59744, 59748, 59752, 59756, 59760, 59764, 59964, 59968, 59972, 59976, 59980, 59984, 60148, 60152)
        draw64($t4, 60156, 60160, 60164, 60168, 60172, 60176, 60180, 60184, 60188, 60192, 60196, 60200, 60204, 60208, 60212, 60216, 60220, 60224, 60228, 60232, 60236, 60240, 60244, 60248, 60476, 60480, 60484, 60488, 60492, 60496, 60640, 60644, 60648, 60652, 60656, 60660, 60664, 60668, 60672, 60676, 60680, 60684, 60688, 60692, 60696, 60700, 60704, 60708, 60712, 60716, 60720, 60724, 60728, 60988, 60992, 60996, 61000, 61004, 61008, 61132, 61136, 61140, 61144, 61148)
        draw64($t4, 61152, 61156, 61160, 61164, 61168, 61172, 61176, 61180, 61184, 61188, 61192, 61196, 61200, 61204, 61208, 61500, 61504, 61508, 61512, 61516, 61520, 61624, 61628, 61632, 61636, 61640, 61644, 61648, 61652, 61656, 61660, 61664, 61668, 61672, 61676, 61680, 61684, 61688, 61692, 62012, 62016, 62020, 62024, 62028, 62032, 62036, 62116, 62120, 62124, 62128, 62132, 62136, 62140, 62144, 62148, 62152, 62156, 62160, 62164, 62168, 62172, 62524, 62528, 62532)
        draw16($t4, 62536, 62540, 62544, 62548, 62608, 62612, 62616, 62620, 62624, 62628, 62632, 62636, 62640, 62644, 62648, 62652)
        draw16($t4, 62656, 63036, 63040, 63044, 63048, 63052, 63056, 63060, 63100, 63104, 63108, 63112, 63116, 63120, 63124, 63128)
        draw16($t4, 63132, 63136, 63548, 63552, 63556, 63560, 63564, 63568, 63572, 63592, 63596, 63600, 63604, 63608, 63612, 63616)
        draw4($t4, 64064, 64068, 64072, 64076)
        draw4($t4, 64080, 64084, 64088, 64092)
        draw4($t4, 64096, 64100, 64576, 64580)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_40
    draw_clear_41: # draw t4, sleep, draw 0
        draw1024($t4, 460, 464, 468, 472, 476, 912, 916, 920, 924, 928, 932, 936, 940, 944, 948, 960, 964, 968, 972, 976, 980, 984, 988, 1364, 1368, 1372, 1376, 1380, 1384, 1388, 1392, 1396, 1400, 1404, 1408, 1412, 1416, 1420, 1424, 1472, 1476, 1480, 1484, 1488, 1492, 1496, 1500, 1816, 1820, 1824, 1828, 1832, 1836, 1840, 1844, 1848, 1852, 1856, 1860, 1864, 1868, 1872, 1876, 1880, 1884, 1888, 1892, 1896, 1900, 1904, 1908, 1912, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2264, 2268, 2272, 2276, 2280, 2284, 2288, 2292, 2296, 2300, 2304, 2308, 2312, 2316, 2320, 2324, 2328, 2332, 2336, 2340, 2344, 2348, 2352, 2356, 2360, 2364, 2368, 2372, 2376, 2380, 2384, 2388, 2392, 2500, 2504, 2508, 2512, 2516, 2520, 2524, 2716, 2720, 2724, 2728, 2732, 2736, 2740, 2744, 2748, 2752, 2756, 2760, 2764, 2768, 2772, 2776, 2780, 2784, 2788, 2792, 2796, 2800, 2804, 2808, 2812, 2816, 2820, 2824, 2828, 2832, 2836, 2840, 2844, 2848, 2852, 2856, 2860, 2864, 2868, 2872, 3012, 3016, 3020, 3024, 3028, 3032, 3036, 3168, 3172, 3176, 3180, 3184, 3188, 3192, 3196, 3200, 3204, 3208, 3212, 3216, 3220, 3224, 3228, 3232, 3236, 3240, 3244, 3248, 3252, 3256, 3260, 3264, 3268, 3272, 3276, 3280, 3284, 3288, 3292, 3296, 3300, 3304, 3308, 3312, 3316, 3320, 3324, 3328, 3332, 3336, 3340, 3344, 3348, 3352, 3356, 3524, 3528, 3532, 3536, 3540, 3544, 3548, 3620, 3624, 3628, 3632, 3636, 3640, 3644, 3648, 3652, 3656, 3660, 3664, 3668, 3672, 3676, 3680, 3684, 3688, 3692, 3696, 3700, 3704, 3708, 3712, 3716, 3720, 3724, 3728, 3732, 3736, 3740, 3744, 3748, 3752, 3756, 3760, 3764, 3768, 3772, 3776, 3780, 3784, 3788, 3792, 3796, 3800, 3804, 3808, 3812, 3816, 3820, 3824, 3828, 3832, 3836, 4036, 4040, 4044, 4048, 4052, 4056, 4060, 4096, 4100, 4104, 4108, 4112, 4116, 4120, 4124, 4128, 4132, 4136, 4140, 4144, 4148, 4152, 4156, 4160, 4164, 4168, 4172, 4176, 4180, 4184, 4188, 4192, 4196, 4200, 4204, 4208, 4212, 4216, 4220, 4224, 4228, 4232, 4236, 4240, 4244, 4248, 4252, 4256, 4260, 4264, 4268, 4272, 4276, 4280, 4284, 4288, 4292, 4296, 4300, 4304, 4308, 4312, 4316, 4320, 4548, 4552, 4556, 4560, 4564, 4568, 4572, 4608, 4612, 4616, 4620, 4624, 4628, 4632, 4636, 4640, 4644, 4648, 4652, 4656, 4660, 4664, 4668, 4672, 4676, 4680, 4684, 4688, 4692, 4696, 4700, 4704, 4708, 4712, 4716, 4720, 4724, 4728, 4732, 4736, 4740, 4744, 4748, 4752, 4756, 4760, 4764, 4768, 4772, 4776, 4780, 4784, 4788, 4792, 4796, 4800, 5060, 5064, 5068, 5072, 5076, 5080, 5084, 5088, 5120, 5124, 5128, 5132, 5136, 5140, 5144, 5148, 5152, 5156, 5160, 5164, 5168, 5172, 5176, 5180, 5184, 5188, 5192, 5196, 5200, 5204, 5208, 5212, 5216, 5220, 5224, 5228, 5232, 5236, 5240, 5244, 5248, 5252, 5256, 5260, 5264, 5268, 5272, 5276, 5280, 5572, 5576, 5580, 5584, 5588, 5592, 5596, 5600, 5632, 5636, 5640, 5644, 5648, 5652, 5656, 5660, 5664, 5668, 5672, 5676, 5680, 5684, 5688, 5692, 5696, 5700, 5704, 5708, 5712, 5716, 5720, 5724, 5728, 5732, 5736, 5740, 5744, 5748, 5752, 5756, 5760, 5764, 6088, 6092, 6096, 6100, 6104, 6108, 6112, 6144, 6148, 6152, 6156, 6160, 6164, 6168, 6172, 6176, 6180, 6184, 6188, 6192, 6196, 6200, 6204, 6208, 6212, 6216, 6220, 6224, 6228, 6232, 6236, 6240, 6244, 6600, 6604, 6608, 6612, 6616, 6620, 6624, 6660, 6664, 6668, 6672, 6676, 6680, 6684, 6688, 6692, 6696, 6700, 6704, 6708, 6712, 6716, 6720, 6724, 6728, 7112, 7116, 7120, 7124, 7128, 7132, 7136, 7172, 7176, 7180, 7184, 7188, 7192, 7196, 7200, 7204, 7208, 7624, 7628, 7632, 7636, 7640, 7644, 7648, 7684, 7688, 8136, 8140, 8144, 8148, 8152, 8156, 8160, 8648, 8652, 8656, 8660, 8664, 8668, 8672, 9160, 9164, 9168, 9172, 9176, 9180, 9184, 9220, 9672, 9676, 9680, 9684, 9688, 9692, 9696, 9732, 10188, 10192, 10196, 10200, 10204, 10208, 10244, 10700, 10704, 10708, 10712, 10716, 10720, 10756, 11212, 11216, 11220, 11224, 11228, 11232, 11268, 11724, 11728, 11732, 11736, 11740, 11744, 11780, 12236, 12240, 12244, 12248, 12252, 12256, 12292, 12748, 12752, 12756, 12760, 12764, 12768, 12772, 12804, 13260, 13264, 13268, 13272, 13276, 13280, 13284, 13316, 13320, 13776, 13780, 13784, 13788, 13792, 13796, 13828, 13832, 14288, 14292, 14296, 14300, 14304, 14308, 14344, 14800, 14804, 14808, 14812, 14816, 14820, 14856, 15312, 15316, 15320, 15324, 15328, 15332, 15368, 15824, 15828, 15832, 15836, 15840, 15844, 15880, 16336, 16340, 16344, 16348, 16352, 16356, 16392, 16848, 16852, 16856, 16860, 16864, 16868, 16904, 16908, 17360, 17364, 17368, 17372, 17376, 17380, 17416, 17420, 17876, 17880, 17884, 17888, 17892, 17928, 17932, 18388, 18392, 18396, 18400, 18404, 18440, 18444, 18900, 18904, 18908, 18912, 18916, 18952, 18956, 19412, 19416, 19420, 19424, 19428, 19464, 19468, 19924, 19928, 19932, 19936, 19940, 19976, 19980, 20436, 20440, 20444, 20448, 20452, 20456, 20488, 20492, 20948, 20952, 20956, 20960, 20964, 20968, 21000, 21004, 21008, 21464, 21468, 21472, 21476, 21480, 21512, 21516, 21520, 21976, 21980, 21984, 21988, 21992, 22028, 22032, 22488, 22492, 22496, 22500, 22504, 22540, 22544, 23000, 23004, 23008, 23012, 23016, 23052, 23056, 23512, 23516, 23520, 23524, 23528, 23564, 23568, 24024, 24028, 24032, 24036, 24040, 24076, 24080, 24536, 24540, 24544, 24548, 24552, 24588, 24592, 25048, 25052, 25056, 25060, 25064, 25100, 25104, 25108, 25564, 25568, 25572, 25576, 25612, 25616, 25620, 26076, 26080, 26084, 26088, 26124, 26128, 26132, 26588, 26592, 26596, 26600, 26636, 26640, 26644, 27100, 27104, 27108, 27112, 27148, 27152, 27156, 27612, 27616, 27620, 27624, 27660, 27664, 27668, 28124, 28128, 28132, 28136, 28140, 28172, 28176, 28180, 28636, 28640, 28644, 28648, 28652, 28684, 28688, 28692, 28696, 29148, 29152, 29156, 29160, 29164, 29196, 29200, 29204, 29208, 29664, 29668, 29672, 29676, 29712, 29716, 29720, 30176, 30180, 30184, 30188, 30224, 30228, 30232, 30688, 30692, 30696, 30700, 30736, 30740, 30744, 31200, 31204, 31208, 31212, 31248, 31252, 31256, 31712, 31716, 31720, 31724, 31760, 31764, 31768, 32224, 32228, 32232, 32236, 32272, 32276, 32280, 32736, 32740, 32744, 32748, 32784, 32788, 32792, 32796, 33252, 33256, 33260, 33296, 33300, 33304, 33308, 33764, 33768, 33772, 33808, 33812, 33816, 33820, 34276, 34280, 34284, 34320, 34324, 34328, 34332, 34788, 34792, 34796, 34832, 34836, 34840, 34844, 35300, 35304, 35308, 35344, 35348, 35352, 35356, 35812, 35816, 35820, 35856, 35860, 35864, 35868, 36324, 36328, 36332, 36336, 36368, 36372, 36376, 36380, 36384, 36836, 36840, 36844, 36848, 36880, 36884, 36888, 36892, 36896, 37352, 37356, 37360, 37392, 37396, 37400, 37404, 37408, 37864, 37868, 37872, 37908, 37912, 37916, 37920, 38376, 38380, 38384, 38420, 38424, 38428, 38432, 38888, 38892, 38896, 38932, 38936, 38940, 38944, 39400, 39404)
        draw256($t4, 39408, 39444, 39448, 39452, 39456, 39912, 39916, 39920, 39956, 39960, 39964, 39968, 40424, 40428, 40432, 40468, 40472, 40476, 40480, 40484, 40940, 40944, 40980, 40984, 40988, 40992, 40996, 41452, 41456, 41492, 41496, 41500, 41504, 41508, 41964, 41968, 42004, 42008, 42012, 42016, 42020, 42476, 42480, 42516, 42520, 42524, 42528, 42532, 42988, 42992, 43028, 43032, 43036, 43040, 43044, 43500, 43504, 43540, 43544, 43548, 43552, 43556, 44012, 44016, 44020, 44052, 44056, 44060, 44064, 44068, 44524, 44528, 44532, 44564, 44568, 44572, 44576, 44580, 44584, 45040, 45044, 45076, 45080, 45084, 45088, 45092, 45096, 45552, 45556, 45592, 45596, 45600, 45604, 45608, 46064, 46068, 46104, 46108, 46112, 46116, 46120, 46576, 46580, 46616, 46620, 46624, 46628, 46632, 47088, 47092, 47128, 47132, 47136, 47140, 47144, 47600, 47604, 47640, 47644, 47648, 47652, 47656, 48112, 48116, 48152, 48156, 48160, 48164, 48168, 48172, 48624, 48628, 48664, 48668, 48672, 48676, 48680, 48684, 49140, 49176, 49180, 49184, 49188, 49192, 49196, 49652, 49688, 49692, 49696, 49700, 49704, 49708, 50164, 50200, 50204, 50208, 50212, 50216, 50220, 50676, 50712, 50716, 50720, 50724, 50728, 50732, 51188, 51224, 51228, 51232, 51236, 51240, 51244, 51700, 51704, 51736, 51740, 51744, 51748, 51752, 51756, 52212, 52216, 52248, 52252, 52256, 52260, 52264, 52268, 52272, 52728, 52760, 52764, 52768, 52772, 52776, 52780, 52784, 53240, 53276, 53280, 53284, 53288, 53292, 53296, 53752, 53788, 53792, 53796, 53800, 53804, 53808, 54264, 54300, 54304, 54308, 54312, 54316, 54320, 54776, 54812, 54816, 54820, 54824, 54828, 54832, 55288, 55324, 55328, 55332, 55336, 55340, 55344, 55800, 55836, 55840, 55844, 55848, 55852, 55856, 55860, 56312, 56348, 56352, 56356, 56360, 56364, 56368, 56372, 56860, 56864, 56868, 56872, 56876, 56880, 56884)
        draw256($t4, 57372, 57376, 57380, 57384, 57388, 57392, 57396, 57844, 57848, 57884, 57888, 57892, 57896, 57900, 57904, 57908, 58324, 58328, 58332, 58336, 58340, 58344, 58348, 58352, 58356, 58360, 58396, 58400, 58404, 58408, 58412, 58416, 58420, 58804, 58808, 58812, 58816, 58820, 58824, 58828, 58832, 58836, 58840, 58844, 58848, 58852, 58856, 58860, 58864, 58868, 58872, 58908, 58912, 58916, 58920, 58924, 58928, 58932, 59288, 59292, 59296, 59300, 59304, 59308, 59312, 59316, 59320, 59324, 59328, 59332, 59336, 59340, 59344, 59348, 59352, 59356, 59360, 59364, 59368, 59372, 59376, 59380, 59384, 59388, 59420, 59424, 59428, 59432, 59436, 59440, 59444, 59768, 59772, 59776, 59780, 59784, 59788, 59792, 59796, 59800, 59804, 59808, 59812, 59816, 59820, 59824, 59828, 59832, 59836, 59840, 59844, 59848, 59852, 59856, 59860, 59864, 59868, 59872, 59876, 59880, 59884, 59888, 59892, 59896, 59900, 59932, 59936, 59940, 59944, 59948, 59952, 59956, 59960, 60252, 60256, 60260, 60264, 60268, 60272, 60276, 60280, 60284, 60288, 60292, 60296, 60300, 60304, 60308, 60312, 60316, 60320, 60324, 60328, 60332, 60336, 60340, 60344, 60348, 60352, 60356, 60360, 60364, 60368, 60372, 60376, 60380, 60384, 60388, 60392, 60396, 60400, 60404, 60408, 60412, 60444, 60448, 60452, 60456, 60460, 60464, 60468, 60472, 60732, 60736, 60740, 60744, 60748, 60752, 60756, 60760, 60764, 60768, 60772, 60776, 60780, 60784, 60788, 60792, 60796, 60800, 60804, 60808, 60812, 60816, 60820, 60824, 60828, 60832, 60836, 60840, 60844, 60848, 60852, 60856, 60860, 60864, 60868, 60872, 60876, 60880, 60884, 60888, 60892, 60896, 60900, 60904, 60908, 60912, 60916, 60920, 60924, 60960, 60964, 60968, 60972, 60976, 60980, 60984, 61212, 61216, 61220, 61224, 61228, 61232, 61236, 61240, 61244, 61248, 61252, 61256, 61260, 61264, 61268, 61272, 61276, 61280)
        draw256($t4, 61284, 61288, 61292, 61296, 61300, 61304, 61308, 61312, 61316, 61320, 61324, 61328, 61332, 61336, 61340, 61344, 61348, 61352, 61356, 61360, 61364, 61368, 61372, 61376, 61380, 61384, 61388, 61392, 61396, 61400, 61404, 61408, 61412, 61416, 61420, 61424, 61428, 61432, 61436, 61472, 61476, 61480, 61484, 61488, 61492, 61496, 61696, 61700, 61704, 61708, 61712, 61716, 61720, 61724, 61728, 61732, 61736, 61740, 61744, 61748, 61752, 61756, 61760, 61764, 61768, 61772, 61776, 61780, 61784, 61788, 61792, 61796, 61800, 61804, 61808, 61812, 61816, 61820, 61824, 61828, 61832, 61836, 61840, 61844, 61848, 61852, 61856, 61860, 61864, 61868, 61872, 61876, 61880, 61884, 61888, 61892, 61896, 61900, 61904, 61908, 61912, 61984, 61988, 61992, 61996, 62000, 62004, 62008, 62176, 62180, 62184, 62188, 62192, 62196, 62200, 62204, 62208, 62212, 62216, 62220, 62224, 62228, 62232, 62236, 62240, 62244, 62248, 62252, 62256, 62260, 62264, 62268, 62272, 62276, 62280, 62284, 62288, 62292, 62296, 62300, 62304, 62308, 62312, 62316, 62320, 62324, 62328, 62332, 62336, 62340, 62344, 62348, 62352, 62356, 62360, 62364, 62496, 62500, 62504, 62508, 62512, 62516, 62520, 62660, 62664, 62668, 62672, 62676, 62680, 62684, 62688, 62692, 62696, 62700, 62704, 62708, 62712, 62716, 62720, 62724, 62728, 62732, 62736, 62740, 62744, 62748, 62752, 62756, 62760, 62764, 62768, 62772, 62776, 62780, 62784, 62788, 62792, 62796, 62800, 62804, 62808, 62812, 62816, 63008, 63012, 63016, 63020, 63024, 63028, 63032, 63140, 63144, 63148, 63152, 63156, 63160, 63164, 63168, 63172, 63176, 63180, 63184, 63188, 63192, 63196, 63200, 63204, 63208, 63212, 63216, 63220, 63224, 63228, 63232, 63236, 63240, 63244, 63248, 63252, 63256, 63260, 63264, 63268, 63520, 63524, 63528, 63532, 63536, 63540, 63544, 63620, 63624, 63628, 63632, 63636, 63640)
        draw64($t4, 63644, 63648, 63652, 63656, 63660, 63664, 63668, 63672, 63676, 63680, 63684, 63688, 63692, 63696, 63700, 63704, 63708, 63712, 63716, 64032, 64036, 64040, 64044, 64048, 64052, 64056, 64060, 64104, 64108, 64112, 64116, 64120, 64124, 64128, 64132, 64136, 64140, 64144, 64148, 64152, 64156, 64160, 64164, 64168, 64544, 64548, 64552, 64556, 64560, 64564, 64568, 64572, 64584, 64588, 64592, 64596, 64600, 64604, 64608, 64612, 64616, 64620, 65056, 65060)
        sw $t4 65064($v1)
        sw $t4 65068($v1)
        sw $t4 65072($v1)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_41
    draw_clear_42: # draw t4, sleep, draw 0
        draw1024($t4, 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 68, 72, 76, 80, 84, 88, 92, 96, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144, 148, 152, 156, 160, 164, 168, 172, 176, 180, 184, 188, 192, 196, 200, 204, 208, 212, 216, 220, 224, 228, 232, 236, 240, 244, 248, 252, 256, 260, 264, 268, 272, 276, 280, 284, 288, 292, 296, 300, 304, 308, 312, 316, 320, 324, 328, 332, 336, 340, 344, 348, 352, 356, 360, 364, 368, 372, 376, 380, 384, 388, 392, 396, 400, 404, 408, 412, 416, 420, 424, 428, 432, 436, 440, 444, 448, 452, 456, 480, 484, 488, 492, 496, 500, 504, 508, 512, 516, 520, 524, 528, 532, 536, 540, 544, 548, 552, 556, 560, 564, 568, 572, 576, 580, 584, 588, 592, 596, 600, 604, 608, 612, 616, 620, 624, 628, 632, 636, 640, 644, 648, 652, 656, 660, 664, 668, 672, 676, 680, 684, 688, 692, 696, 700, 704, 708, 712, 716, 720, 724, 728, 732, 736, 740, 744, 748, 752, 756, 760, 764, 768, 772, 776, 780, 784, 788, 792, 796, 800, 804, 808, 812, 816, 820, 824, 828, 832, 836, 840, 844, 848, 852, 856, 860, 864, 868, 872, 876, 880, 884, 888, 892, 896, 900, 904, 908, 992, 996, 1000, 1004, 1008, 1012, 1016, 1020, 1024, 1028, 1032, 1036, 1040, 1044, 1048, 1052, 1056, 1060, 1064, 1068, 1072, 1076, 1080, 1084, 1088, 1092, 1096, 1100, 1104, 1108, 1112, 1116, 1120, 1124, 1128, 1132, 1136, 1140, 1144, 1148, 1152, 1156, 1160, 1164, 1168, 1172, 1176, 1180, 1184, 1188, 1192, 1196, 1200, 1204, 1208, 1212, 1216, 1220, 1224, 1228, 1232, 1236, 1240, 1244, 1248, 1252, 1256, 1260, 1264, 1268, 1272, 1276, 1280, 1284, 1288, 1292, 1296, 1300, 1304, 1308, 1312, 1316, 1320, 1324, 1328, 1332, 1336, 1340, 1344, 1348, 1352, 1356, 1360, 1504, 1508, 1512, 1516, 1520, 1524, 1528, 1532, 1536, 1540, 1544, 1548, 1552, 1556, 1560, 1564, 1568, 1572, 1576, 1580, 1584, 1588, 1592, 1596, 1600, 1604, 1608, 1612, 1616, 1620, 1624, 1628, 1632, 1636, 1640, 1644, 1648, 1652, 1656, 1660, 1664, 1668, 1672, 1676, 1680, 1684, 1688, 1692, 1696, 1700, 1704, 1708, 1712, 1716, 1720, 1724, 1728, 1732, 1736, 1740, 1744, 1748, 1752, 1756, 1760, 1764, 1768, 1772, 1776, 1780, 1784, 1788, 1792, 1796, 1800, 1804, 1808, 1812, 2016, 2020, 2024, 2028, 2032, 2036, 2040, 2044, 2048, 2052, 2056, 2060, 2064, 2068, 2072, 2076, 2080, 2084, 2088, 2092, 2096, 2100, 2104, 2108, 2112, 2116, 2120, 2124, 2128, 2132, 2136, 2140, 2144, 2148, 2152, 2156, 2160, 2164, 2168, 2172, 2176, 2180, 2184, 2188, 2192, 2196, 2200, 2204, 2208, 2212, 2216, 2220, 2224, 2228, 2232, 2236, 2240, 2244, 2248, 2252, 2256, 2260, 2528, 2532, 2536, 2540, 2544, 2548, 2552, 2556, 2560, 2564, 2568, 2572, 2576, 2580, 2584, 2588, 2592, 2596, 2600, 2604, 2608, 2612, 2616, 2620, 2624, 2628, 2632, 2636, 2640, 2644, 2648, 2652, 2656, 2660, 2664, 2668, 2672, 2676, 2680, 2684, 2688, 2692, 2696, 2700, 2704, 2708, 2712, 3040, 3044, 3048, 3052, 3056, 3060, 3064, 3068, 3072, 3076, 3080, 3084, 3088, 3092, 3096, 3100, 3104, 3108, 3112, 3116, 3120, 3124, 3128, 3132, 3136, 3140, 3144, 3148, 3152, 3156, 3160, 3164, 3552, 3556, 3560, 3564, 3568, 3572, 3576, 3580, 3584, 3588, 3592, 3596, 3600, 3604, 3608, 3612, 3616, 4064, 4068, 4072, 4076, 4080, 4084, 4088, 4092, 4576, 4580, 4584, 4588, 4592, 4596, 4600, 4604, 5092, 5096, 5100, 5104, 5108, 5112, 5116, 5604, 5608, 5612, 5616, 5620, 5624, 5628, 6116, 6120, 6124, 6128, 6132, 6136, 6140, 6628, 6632, 6636, 6640, 6644, 6648, 6652, 6656, 7140, 7144, 7148, 7152, 7156, 7160, 7164, 7168, 7652, 7656, 7660, 7664, 7668, 7672, 7676, 7680, 8164, 8168, 8172, 8176, 8180, 8184, 8188, 8192, 8676, 8680, 8684, 8688, 8692, 8696, 8700, 8704, 9188, 9192, 9196, 9200, 9204, 9208, 9212, 9216, 9700, 9704, 9708, 9712, 9716, 9720, 9724, 9728, 10212, 10216, 10220, 10224, 10228, 10232, 10236, 10240, 10724, 10728, 10732, 10736, 10740, 10744, 10748, 10752, 11236, 11240, 11244, 11248, 11252, 11256, 11260, 11264, 11748, 11752, 11756, 11760, 11764, 11768, 11772, 11776, 12260, 12264, 12268, 12272, 12276, 12280, 12284, 12288, 12776, 12780, 12784, 12788, 12792, 12796, 12800, 13288, 13292, 13296, 13300, 13304, 13308, 13312, 13800, 13804, 13808, 13812, 13816, 13820, 13824, 14312, 14316, 14320, 14324, 14328, 14332, 14336, 14340, 14824, 14828, 14832, 14836, 14840, 14844, 14848, 14852, 15336, 15340, 15344, 15348, 15352, 15356, 15360, 15364, 15848, 15852, 15856, 15860, 15864, 15868, 15872, 15876, 16360, 16364, 16368, 16372, 16376, 16380, 16384, 16388, 16872, 16876, 16880, 16884, 16888, 16892, 16896, 16900, 17384, 17388, 17392, 17396, 17400, 17404, 17408, 17412, 17896, 17900, 17904, 17908, 17912, 17916, 17920, 17924, 18408, 18412, 18416, 18420, 18424, 18428, 18432, 18436, 18920, 18924, 18928, 18932, 18936, 18940, 18944, 18948, 19432, 19436, 19440, 19444, 19448, 19452, 19456, 19460, 19944, 19948, 19952, 19956, 19960, 19964, 19968, 19972, 20460, 20464, 20468, 20472, 20476, 20480, 20484, 20972, 20976, 20980, 20984, 20988, 20992, 20996, 21484, 21488, 21492, 21496, 21500, 21504, 21508, 21996, 22000, 22004, 22008, 22012, 22016, 22020, 22024, 22508, 22512, 22516, 22520, 22524, 22528, 22532, 22536, 23020, 23024, 23028, 23032, 23036, 23040, 23044, 23048, 23532, 23536, 23540, 23544, 23548, 23552, 23556, 23560, 24044, 24048, 24052, 24056, 24060, 24064, 24068, 24072, 24556, 24560, 24564, 24568, 24572, 24576, 24580, 24584, 25068, 25072, 25076, 25080, 25084, 25088, 25092, 25096, 25580, 25584, 25588, 25592, 25596, 25600, 25604, 25608, 26092, 26096, 26100, 26104, 26108, 26112, 26116, 26120, 26604, 26608, 26612, 26616, 26620, 26624, 26628, 26632, 27116, 27120, 27124, 27128, 27132, 27136, 27140, 27144, 27628, 27632, 27636, 27640, 27644, 27648, 27652, 27656, 28144, 28148, 28152, 28156, 28160, 28164, 28168, 28656, 28660, 28664, 28668, 28672, 28676, 28680, 29168, 29172, 29176, 29180, 29184, 29188, 29192, 29680, 29684, 29688, 29692, 29696, 29700, 29704, 29708, 30192, 30196, 30200, 30204, 30208, 30212, 30216, 30220, 30704, 30708, 30712, 30716, 30720, 30724, 30728, 30732, 31216, 31220, 31224, 31228, 31232, 31236, 31240, 31244, 31728, 31732, 31736, 31740, 31744, 31748, 31752, 31756, 32240, 32244, 32248, 32252, 32256, 32260, 32264, 32268, 32752, 32756, 32760, 32764, 32768, 32772, 32776, 32780, 33264, 33268, 33272, 33276, 33280, 33284, 33288, 33292, 33776, 33780, 33784, 33788, 33792, 33796, 33800, 33804, 34288, 34292, 34296, 34300, 34304, 34308, 34312, 34316, 34800, 34804, 34808, 34812)
        draw256($t4, 34816, 34820, 34824, 34828, 35312, 35316, 35320, 35324, 35328, 35332, 35336, 35340, 35824, 35828, 35832, 35836, 35840, 35844, 35848, 35852, 36340, 36344, 36348, 36352, 36356, 36360, 36364, 36852, 36856, 36860, 36864, 36868, 36872, 36876, 37364, 37368, 37372, 37376, 37380, 37384, 37388, 37876, 37880, 37884, 37888, 37892, 37896, 37900, 37904, 38388, 38392, 38396, 38400, 38404, 38408, 38412, 38416, 38900, 38904, 38908, 38912, 38916, 38920, 38924, 38928, 39412, 39416, 39420, 39424, 39428, 39432, 39436, 39440, 39924, 39928, 39932, 39936, 39940, 39944, 39948, 39952, 40436, 40440, 40444, 40448, 40452, 40456, 40460, 40464, 40948, 40952, 40956, 40960, 40964, 40968, 40972, 40976, 41460, 41464, 41468, 41472, 41476, 41480, 41484, 41488, 41972, 41976, 41980, 41984, 41988, 41992, 41996, 42000, 42484, 42488, 42492, 42496, 42500, 42504, 42508, 42512, 42996, 43000, 43004, 43008, 43012, 43016, 43020, 43024, 43508, 43512, 43516, 43520, 43524, 43528, 43532, 43536, 44024, 44028, 44032, 44036, 44040, 44044, 44048, 44536, 44540, 44544, 44548, 44552, 44556, 44560, 45048, 45052, 45056, 45060, 45064, 45068, 45072, 45560, 45564, 45568, 45572, 45576, 45580, 45584, 45588, 46072, 46076, 46080, 46084, 46088, 46092, 46096, 46100, 46584, 46588, 46592, 46596, 46600, 46604, 46608, 46612, 47096, 47100, 47104, 47108, 47112, 47116, 47120, 47124, 47608, 47612, 47616, 47620, 47624, 47628, 47632, 47636, 48120, 48124, 48128, 48132, 48136, 48140, 48144, 48148, 48632, 48636, 48640, 48644, 48648, 48652, 48656, 48660, 49144, 49148, 49152, 49156, 49160, 49164, 49168, 49172, 49656, 49660, 49664, 49668, 49672, 49676, 49680, 49684, 50168, 50172, 50176, 50180, 50184, 50188, 50192, 50196, 50680, 50684, 50688, 50692, 50696, 50700, 50704, 50708, 51192, 51196, 51200, 51204, 51208, 51212, 51216, 51220, 51708, 51712)
        draw256($t4, 51716, 51720, 51724, 51728, 51732, 52220, 52224, 52228, 52232, 52236, 52240, 52244, 52732, 52736, 52740, 52744, 52748, 52752, 52756, 53244, 53248, 53252, 53256, 53260, 53264, 53268, 53272, 53756, 53760, 53764, 53768, 53772, 53776, 53780, 53784, 54268, 54272, 54276, 54280, 54284, 54288, 54292, 54296, 54780, 54784, 54788, 54792, 54796, 54800, 54804, 54808, 55292, 55296, 55300, 55304, 55308, 55312, 55316, 55320, 55804, 55808, 55812, 55816, 55820, 55824, 55828, 55832, 56316, 56320, 56324, 56328, 56332, 56336, 56340, 56344, 56828, 56832, 56836, 56840, 56844, 56848, 56852, 56856, 57340, 57344, 57348, 57352, 57356, 57360, 57364, 57368, 57852, 57856, 57860, 57864, 57868, 57872, 57876, 57880, 58364, 58368, 58372, 58376, 58380, 58384, 58388, 58392, 58876, 58880, 58884, 58888, 58892, 58896, 58900, 58904, 59392, 59396, 59400, 59404, 59408, 59412, 59416, 59904, 59908, 59912, 59916, 59920, 59924, 59928, 60416, 60420, 60424, 60428, 60432, 60436, 60440, 60928, 60932, 60936, 60940, 60944, 60948, 60952, 60956, 61440, 61444, 61448, 61452, 61456, 61460, 61464, 61468, 61916, 61920, 61924, 61928, 61932, 61936, 61940, 61944, 61948, 61952, 61956, 61960, 61964, 61968, 61972, 61976, 61980, 62368, 62372, 62376, 62380, 62384, 62388, 62392, 62396, 62400, 62404, 62408, 62412, 62416, 62420, 62424, 62428, 62432, 62436, 62440, 62444, 62448, 62452, 62456, 62460, 62464, 62468, 62472, 62476, 62480, 62484, 62488, 62492, 62820, 62824, 62828, 62832, 62836, 62840, 62844, 62848, 62852, 62856, 62860, 62864, 62868, 62872, 62876, 62880, 62884, 62888, 62892, 62896, 62900, 62904, 62908, 62912, 62916, 62920, 62924, 62928, 62932, 62936, 62940, 62944, 62948, 62952, 62956, 62960, 62964, 62968, 62972, 62976, 62980, 62984, 62988, 62992, 62996, 63000, 63004, 63272, 63276, 63280, 63284, 63288, 63292, 63296, 63300)
        draw256($t4, 63304, 63308, 63312, 63316, 63320, 63324, 63328, 63332, 63336, 63340, 63344, 63348, 63352, 63356, 63360, 63364, 63368, 63372, 63376, 63380, 63384, 63388, 63392, 63396, 63400, 63404, 63408, 63412, 63416, 63420, 63424, 63428, 63432, 63436, 63440, 63444, 63448, 63452, 63456, 63460, 63464, 63468, 63472, 63476, 63480, 63484, 63488, 63492, 63496, 63500, 63504, 63508, 63512, 63516, 63720, 63724, 63728, 63732, 63736, 63740, 63744, 63748, 63752, 63756, 63760, 63764, 63768, 63772, 63776, 63780, 63784, 63788, 63792, 63796, 63800, 63804, 63808, 63812, 63816, 63820, 63824, 63828, 63832, 63836, 63840, 63844, 63848, 63852, 63856, 63860, 63864, 63868, 63872, 63876, 63880, 63884, 63888, 63892, 63896, 63900, 63904, 63908, 63912, 63916, 63920, 63924, 63928, 63932, 63936, 63940, 63944, 63948, 63952, 63956, 63960, 63964, 63968, 63972, 63976, 63980, 63984, 63988, 63992, 63996, 64000, 64004, 64008, 64012, 64016, 64020, 64024, 64028, 64172, 64176, 64180, 64184, 64188, 64192, 64196, 64200, 64204, 64208, 64212, 64216, 64220, 64224, 64228, 64232, 64236, 64240, 64244, 64248, 64252, 64256, 64260, 64264, 64268, 64272, 64276, 64280, 64284, 64288, 64292, 64296, 64300, 64304, 64308, 64312, 64316, 64320, 64324, 64328, 64332, 64336, 64340, 64344, 64348, 64352, 64356, 64360, 64364, 64368, 64372, 64376, 64380, 64384, 64388, 64392, 64396, 64400, 64404, 64408, 64412, 64416, 64420, 64424, 64428, 64432, 64436, 64440, 64444, 64448, 64452, 64456, 64460, 64464, 64468, 64472, 64476, 64480, 64484, 64488, 64492, 64496, 64500, 64504, 64508, 64512, 64516, 64520, 64524, 64528, 64532, 64536, 64540, 64624, 64628, 64632, 64636, 64640, 64644, 64648, 64652, 64656, 64660, 64664, 64668, 64672, 64676, 64680, 64684, 64688, 64692, 64696, 64700, 64704, 64708, 64712, 64716, 64720, 64724, 64728, 64732, 64736, 64740, 64744)
        draw64($t4, 64748, 64752, 64756, 64760, 64764, 64768, 64772, 64776, 64780, 64784, 64788, 64792, 64796, 64800, 64804, 64808, 64812, 64816, 64820, 64824, 64828, 64832, 64836, 64840, 64844, 64848, 64852, 64856, 64860, 64864, 64868, 64872, 64876, 64880, 64884, 64888, 64892, 64896, 64900, 64904, 64908, 64912, 64916, 64920, 64924, 64928, 64932, 64936, 64940, 64944, 64948, 64952, 64956, 64960, 64964, 64968, 64972, 64976, 64980, 64984, 64988, 64992, 64996, 65000)
        draw64($t4, 65004, 65008, 65012, 65016, 65020, 65024, 65028, 65032, 65036, 65040, 65044, 65048, 65052, 65076, 65080, 65084, 65088, 65092, 65096, 65100, 65104, 65108, 65112, 65116, 65120, 65124, 65128, 65132, 65136, 65140, 65144, 65148, 65152, 65156, 65160, 65164, 65168, 65172, 65176, 65180, 65184, 65188, 65192, 65196, 65200, 65204, 65208, 65212, 65216, 65220, 65224, 65228, 65232, 65236, 65240, 65244, 65248, 65252, 65256, 65260, 65264, 65268, 65272, 65276)
        draw64($t4, 65280, 65284, 65288, 65292, 65296, 65300, 65304, 65308, 65312, 65316, 65320, 65324, 65328, 65332, 65336, 65340, 65344, 65348, 65352, 65356, 65360, 65364, 65368, 65372, 65376, 65380, 65384, 65388, 65392, 65396, 65400, 65404, 65408, 65412, 65416, 65420, 65424, 65428, 65432, 65436, 65440, 65444, 65448, 65452, 65456, 65460, 65464, 65468, 65472, 65476, 65480, 65484, 65488, 65492, 65496, 65500, 65504, 65508, 65512, 65516, 65520, 65524, 65528, 65532)
        beqz $t4 jrra # return
        syscall # sleep
        move $t4 $0
        j draw_clear_42
draw_border: # start at v1, use t4
    li $t4 0xfad053
    draw256($t4, 1548, 1552, 1556, 1560, 1564, 1568, 1572, 1576, 1580, 1584, 1588, 1592, 1596, 1600, 1604, 1608, 1612, 1616, 1620, 1624, 1628, 1632, 1636, 1640, 1644, 1648, 1652, 1656, 1660, 1664, 1668, 1672, 1676, 1680, 1684, 1688, 1692, 1696, 1700, 1704, 1708, 1712, 1716, 1720, 1724, 1728, 1732, 1736, 1740, 1744, 1748, 1752, 1756, 1760, 1764, 1768, 1772, 1776, 1780, 1784, 1788, 1792, 1796, 1800, 1804, 1808, 1812, 1816, 1820, 1824, 1828, 1832, 1836, 1840, 1844, 1848, 1852, 1856, 1860, 1864, 1868, 1872, 1876, 1880, 1884, 1888, 1892, 1896, 1900, 1904, 1908, 1912, 1916, 1920, 1924, 1928, 1932, 1936, 1940, 1944, 1948, 1952, 1956, 1960, 1964, 1968, 1972, 1976, 1980, 1984, 1988, 1992, 1996, 2000, 2004, 2008, 2012, 2016, 2020, 2024, 2028, 2032, 2060, 2064, 2068, 2072, 2076, 2080, 2084, 2088, 2092, 2096, 2100, 2104, 2108, 2112, 2116, 2120, 2124, 2128, 2132, 2136, 2140, 2144, 2148, 2152, 2156, 2160, 2164, 2168, 2172, 2176, 2180, 2184, 2188, 2192, 2196, 2200, 2204, 2208, 2212, 2216, 2220, 2224, 2228, 2232, 2236, 2240, 2244, 2248, 2252, 2256, 2260, 2264, 2268, 2272, 2276, 2280, 2284, 2288, 2292, 2296, 2300, 2304, 2308, 2312, 2316, 2320, 2324, 2328, 2332, 2336, 2340, 2344, 2348, 2352, 2356, 2360, 2364, 2368, 2372, 2376, 2380, 2384, 2388, 2392, 2396, 2400, 2404, 2408, 2412, 2416, 2420, 2424, 2428, 2432, 2436, 2440, 2444, 2448, 2452, 2456, 2460, 2464, 2468, 2472, 2476, 2480, 2484, 2488, 2492, 2496, 2500, 2504, 2508, 2512, 2516, 2520, 2524, 2528, 2532, 2536, 2540, 2544, 2572, 2576, 3052, 3056, 3084, 3088, 3564, 3568, 3596, 3600, 4076, 4080)
    draw256($t4, 4108, 4112, 4588, 4592, 4620, 4624, 5100, 5104, 5132, 5136, 5612, 5616, 5644, 5648, 6124, 6128, 6156, 6160, 6636, 6640, 6668, 6672, 7148, 7152, 7180, 7184, 7660, 7664, 7692, 7696, 8172, 8176, 8204, 8208, 8684, 8688, 8716, 8720, 9196, 9200, 9228, 9232, 9708, 9712, 9740, 9744, 10220, 10224, 10252, 10256, 10732, 10736, 10764, 10768, 11244, 11248, 11276, 11280, 11756, 11760, 11788, 11792, 12268, 12272, 12300, 12304, 12780, 12784, 12812, 12816, 13292, 13296, 13324, 13328, 13804, 13808, 13836, 13840, 14316, 14320, 14348, 14352, 14828, 14832, 14860, 14864, 15340, 15344, 15372, 15376, 15852, 15856, 15884, 15888, 16364, 16368, 16396, 16400, 16876, 16880, 16908, 16912, 17388, 17392, 17420, 17424, 17900, 17904, 17932, 17936, 18412, 18416, 18444, 18448, 18924, 18928, 18956, 18960, 19436, 19440, 19468, 19472, 19948, 19952, 19980, 19984, 20460, 20464, 20492, 20496, 20972, 20976, 21004, 21008, 21484, 21488, 21516, 21520, 21996, 22000, 22028, 22032, 22508, 22512, 22540, 22544, 23020, 23024, 23052, 23056, 23532, 23536, 23564, 23568, 24044, 24048, 24076, 24080, 24556, 24560, 24588, 24592, 25068, 25072, 25100, 25104, 25580, 25584, 25612, 25616, 26092, 26096, 26124, 26128, 26604, 26608, 26636, 26640, 27116, 27120, 27148, 27152, 27628, 27632, 27660, 27664, 28140, 28144, 28172, 28176, 28652, 28656, 28684, 28688, 29164, 29168, 29196, 29200, 29676, 29680, 29708, 29712, 30188, 30192, 30220, 30224, 30700, 30704, 30732, 30736, 31212, 31216, 31244, 31248, 31724, 31728, 31756, 31760, 32236, 32240, 32268, 32272, 32748, 32752, 32780, 32784, 33260, 33264, 33292, 33296, 33772, 33776, 33804, 33808, 34284, 34288, 34316, 34320, 34796, 34800, 34828, 34832, 35308, 35312, 35340, 35344, 35820, 35824, 35852, 35856, 36332, 36336, 36364, 36368, 36844, 36848)
    draw256($t4, 36876, 36880, 37356, 37360, 37388, 37392, 37868, 37872, 37900, 37904, 38380, 38384, 38412, 38416, 38892, 38896, 38924, 38928, 39404, 39408, 39436, 39440, 39916, 39920, 39948, 39952, 40428, 40432, 40460, 40464, 40940, 40944, 40972, 40976, 41452, 41456, 41484, 41488, 41964, 41968, 41996, 42000, 42476, 42480, 42508, 42512, 42988, 42992, 43020, 43024, 43500, 43504, 43532, 43536, 44012, 44016, 44044, 44048, 44524, 44528, 44556, 44560, 45036, 45040, 45068, 45072, 45548, 45552, 45580, 45584, 46060, 46064, 46092, 46096, 46572, 46576, 46604, 46608, 47084, 47088, 47116, 47120, 47596, 47600, 47628, 47632, 48108, 48112, 48140, 48144, 48620, 48624, 48652, 48656, 49132, 49136, 49164, 49168, 49644, 49648, 49676, 49680, 50156, 50160, 50188, 50192, 50668, 50672, 50700, 50704, 51180, 51184, 51212, 51216, 51692, 51696, 51724, 51728, 52204, 52208, 52236, 52240, 52716, 52720, 52748, 52752, 53228, 53232, 53260, 53264, 53740, 53744, 53772, 53776, 54252, 54256, 54284, 54288, 54764, 54768, 54796, 54800, 55276, 55280, 55308, 55312, 55788, 55792, 55820, 55824, 56300, 56304, 56332, 56336, 56812, 56816, 56844, 56848, 57324, 57328, 57356, 57360, 57836, 57840, 57868, 57872, 58348, 58352, 58380, 58384, 58860, 58864, 58892, 58896, 59372, 59376, 59404, 59408, 59884, 59888, 59916, 59920, 60396, 60400, 60428, 60432, 60908, 60912, 60940, 60944, 61420, 61424, 61452, 61456, 61932, 61936, 61964, 61968, 62444, 62448, 62476, 62480, 62956, 62960, 62988, 62992, 62996, 63000, 63004, 63008, 63012, 63016, 63020, 63024, 63028, 63032, 63036, 63040, 63044, 63048, 63052, 63056, 63060, 63064, 63068, 63072, 63076, 63080, 63084, 63088, 63092, 63096, 63100, 63104, 63108, 63112, 63116, 63120, 63124, 63128, 63132, 63136, 63140, 63144, 63148, 63152, 63156, 63160, 63164, 63168, 63172, 63176, 63180, 63184, 63188, 63192)
    draw64($t4, 63196, 63200, 63204, 63208, 63212, 63216, 63220, 63224, 63228, 63232, 63236, 63240, 63244, 63248, 63252, 63256, 63260, 63264, 63268, 63272, 63276, 63280, 63284, 63288, 63292, 63296, 63300, 63304, 63308, 63312, 63316, 63320, 63324, 63328, 63332, 63336, 63340, 63344, 63348, 63352, 63356, 63360, 63364, 63368, 63372, 63376, 63380, 63384, 63388, 63392, 63396, 63400, 63404, 63408, 63412, 63416, 63420, 63424, 63428, 63432, 63436, 63440, 63444, 63448)
    draw64($t4, 63452, 63456, 63460, 63464, 63468, 63472, 63500, 63504, 63508, 63512, 63516, 63520, 63524, 63528, 63532, 63536, 63540, 63544, 63548, 63552, 63556, 63560, 63564, 63568, 63572, 63576, 63580, 63584, 63588, 63592, 63596, 63600, 63604, 63608, 63612, 63616, 63620, 63624, 63628, 63632, 63636, 63640, 63644, 63648, 63652, 63656, 63660, 63664, 63668, 63672, 63676, 63680, 63684, 63688, 63692, 63696, 63700, 63704, 63708, 63712, 63716, 63720, 63724, 63728)
    draw64($t4, 63732, 63736, 63740, 63744, 63748, 63752, 63756, 63760, 63764, 63768, 63772, 63776, 63780, 63784, 63788, 63792, 63796, 63800, 63804, 63808, 63812, 63816, 63820, 63824, 63828, 63832, 63836, 63840, 63844, 63848, 63852, 63856, 63860, 63864, 63868, 63872, 63876, 63880, 63884, 63888, 63892, 63896, 63900, 63904, 63908, 63912, 63916, 63920, 63924, 63928, 63932, 63936, 63940, 63944, 63948, 63952, 63956, 63960, 63964, 63968, 63972, 63976, 63980, 63984)
    jr $ra

draw_title: # use t0-t9 v1
    sll $v1 $s7 9 # (0, s7)
    addi $v1 $v1 2604 # (11, 5 + s7)
    addi $v1 $v1 BASE_ADDRESS

    draw64($0, 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 124, 128, 132, 136, 140, 144, 148, 200, 204, 208, 216, 220, 224, 244, 248, 252, 256, 260, 280, 284, 288, 292, 332, 336, 340, 664, 720, 736, 772, 788, 1080, 1084, 1088, 1108, 1112, 1116, 1180, 1196, 1200, 1204, 1332, 1336, 1340, 1396, 1400, 1404, 1432, 1436, 1536, 1540, 1544)
    draw64($0, 1548, 1564, 1568, 1572, 1588, 1592, 1600, 1604, 1616, 1620, 1628, 1632, 1636, 1672, 1700, 1704, 1708, 1716, 1720, 1724, 1800, 1836, 1840, 1844, 1852, 1856, 1860, 1884, 1888, 1892, 1896, 1904, 1908, 1916, 1920, 1924, 1932, 1936, 1940, 1944, 2116, 2124, 2152, 2192, 2212, 2240, 2312, 2320, 2372, 2392, 2412, 2440, 2664, 2720, 2752, 2856, 2952, 3124, 3160, 3164, 3232, 3252, 3340, 3368)
    draw64($0, 3380, 3384, 3448, 3452, 3484, 3744, 3840, 3852, 3864, 3880, 3884, 3936, 4240, 4256, 4276, 4392, 4452, 4696, 4700, 4704, 4712, 4744, 4748, 4768, 4784, 4788, 4916, 4920, 4968, 4984, 4988, 4992, 5000, 5224, 5312, 5380, 5396, 5464, 5480, 5512, 5736, 5784, 5796, 5892, 5996, 6024, 6160, 6168, 6184, 6204, 6212, 6228, 6240, 6268, 6284, 6316, 6328, 6352, 6368, 6388, 6400, 6404, 6408, 6416)
    draw4($0, 6436, 6460, 6476, 6484)
    draw4($0, 6496, 6504, 6508, 6512)
    draw4($0, 6516, 6528, 6532, 6536)
    sw $0 6540($v1)
    sw $0 6548($v1)
    draw64($t0, 512, 552, 660, 756, 852, 1024, 1232, 1248, 1268, 1300, 1596, 1624, 1676, 1692, 1712, 1744, 1760, 1780, 1848, 1912, 1948, 2148, 2236, 2256, 2272, 2292, 2348, 2408, 2436, 2768, 2784, 2804, 2832, 3176, 3280, 3296, 3316, 3328, 3464, 3480, 3756, 3792, 3808, 3828, 4268, 4304, 4320, 4340, 4352, 4708, 4764, 4816, 4832, 4852, 4864, 4868, 4904, 4964, 4996, 5328, 5344, 5364, 5376, 5416)
    draw16($t0, 5820, 5840, 5856, 5876, 5888, 5980, 6164, 6188, 6192, 6208, 6232, 6236, 6272, 6276, 6280, 6324)
    draw16($t0, 6344, 6348, 6360, 6364, 6392, 6396, 6412, 6428, 6432, 6448, 6456, 6464, 6468, 6480, 6500, 6520)
    sw $t0 6524($v1)
    sw $t0 6544($v1)
    draw64($t6, 516, 520, 524, 528, 532, 536, 540, 544, 640, 644, 648, 652, 760, 764, 768, 796, 800, 1356, 1668, 1868, 2144, 2180, 2232, 2324, 2352, 2380, 2432, 2652, 2692, 2716, 2840, 2844, 2868, 2892, 2948, 3140, 3148, 3204, 3404, 3436, 3652, 3672, 3676, 3716, 3740, 3892, 3916, 3932, 3956, 3960, 3964, 4164, 4184, 4188, 4192, 4196, 4228, 4404, 4412, 4428, 4472, 4476, 4480, 4484)
    draw4($t6, 4676, 4684, 4740, 4940)
    draw4($t6, 5188, 5260, 5300, 5384)
    draw4($t6, 5452, 5468, 5700, 5948)
    sw $t6 5964($v1)
    draw16($t4, 548, 656, 792, 1148, 1660, 1680, 1796, 2172, 2368, 2396, 2628, 2684, 2708, 2816, 3196, 3388)
    draw16($t4, 3708, 3776, 3888, 4220, 4252, 4288, 4364, 4732, 4924, 5212, 5244, 5272, 5296, 5428, 5500, 5756)
    sw $t4 5800($v1)
    sw $t4 5904($v1)
    draw16($t2, 556, 560, 636, 712, 716, 728, 732, 848, 1560, 2072, 2128, 2584, 2724, 2884, 2904, 2924)
    draw16($t2, 3096, 3244, 3264, 3352, 3424, 3608, 3644, 3688, 4120, 4156, 4448, 4632, 4668, 4780, 4952, 5144)
    draw4($t2, 5180, 5196, 5484, 5656)
    draw4($t2, 5692, 5780, 5896, 5992)
    sw $t2 6020($v1)
    draw16($t1, 804, 844, 1064, 1176, 1284, 1316, 1576, 1828, 2088, 2340, 2600, 2636, 2824, 2852, 2916, 3112)
    draw16($t1, 3364, 3624, 3876, 3976, 4136, 4200, 4388, 4488, 4648, 4752, 4884, 4900, 5160, 5412, 5672, 5924)
    sw $t1 6320($v1)
    sw $t1 6452($v1)
    draw64($t9, 1028, 1032, 1036, 1040, 1044, 1048, 1052, 1056, 1068, 1152, 1156, 1160, 1164, 1168, 1224, 1228, 1244, 1272, 1276, 1280, 1304, 1308, 1312, 1360, 1556, 1580, 1664, 1684, 1736, 1740, 1756, 1784, 1788, 1792, 1816, 1820, 1824, 1872, 2068, 2092, 2104, 2108, 2136, 2140, 2176, 2200, 2224, 2228, 2248, 2252, 2268, 2296, 2328, 2336, 2356, 2360, 2364, 2384, 2400, 2424, 2428, 2448, 2460, 2580)
    draw64($t9, 2604, 2608, 2624, 2640, 2644, 2656, 2688, 2712, 2728, 2732, 2744, 2760, 2764, 2780, 2808, 2812, 2820, 2836, 2848, 2864, 2880, 2896, 2908, 2912, 2928, 2932, 2944, 2960, 2964, 2968, 2972, 3092, 3116, 3136, 3152, 3172, 3200, 3224, 3240, 3260, 3272, 3276, 3292, 3320, 3324, 3332, 3348, 3360, 3392, 3408, 3416, 3420, 3440, 3460, 3472, 3604, 3628, 3648, 3664, 3684, 3712, 3736, 3748, 3752)
    draw64($t9, 3772, 3784, 3788, 3804, 3832, 3836, 3848, 3860, 3872, 3904, 3920, 3924, 3928, 3948, 3952, 3972, 3984, 4116, 4140, 4160, 4176, 4224, 4248, 4260, 4264, 4284, 4296, 4300, 4316, 4344, 4348, 4360, 4368, 4384, 4400, 4416, 4432, 4436, 4440, 4444, 4460, 4464, 4496, 4628, 4652, 4672, 4688, 4736, 4756, 4760, 4776, 4796, 4808, 4812, 4828, 4856, 4860, 4872, 4876, 4880, 4896, 4908, 4912, 4928)
    draw16($t9, 4944, 4956, 4976, 5008, 5140, 5164, 5184, 5200, 5204, 5248, 5264, 5268, 5288, 5304, 5320, 5324)
    draw16($t9, 5340, 5368, 5372, 5388, 5408, 5420, 5424, 5440, 5456, 5472, 5488, 5492, 5520, 5652, 5676, 5696)
    draw16($t9, 5720, 5724, 5728, 5760, 5764, 5768, 5772, 5804, 5808, 5812, 5832, 5836, 5852, 5880, 5884, 5900)
    draw4($t9, 5920, 5936, 5940, 5944)
    draw4($t9, 5952, 5968, 5984, 5988)
    draw4($t9, 6004, 6008, 6012, 6032)
    draw16($t5, 1060, 2100, 2452, 2616, 2648, 2736, 2936, 3336, 3396, 3412, 3768, 3908, 3988, 4244, 4280, 4372)
    draw4($t5, 4420, 4500, 4932, 4948)
    draw4($t5, 5012, 5208, 5256, 5444)
    draw4($t5, 5476, 5496, 5524, 6036)
    draw16($t8, 1072, 1172, 1240, 1552, 1584, 1688, 1752, 2064, 2096, 2132, 2220, 2264, 2300, 2304, 2308, 2404)
    draw16($t8, 2420, 2456, 2576, 2620, 2776, 2876, 3088, 3120, 3168, 3256, 3288, 3456, 3600, 3632, 3660, 3680)
    draw16($t8, 3800, 3868, 3900, 3968, 4112, 4144, 4172, 4312, 4380, 4624, 4656, 4772, 4824, 4892, 4960, 5136)
    draw4($t8, 5168, 5252, 5292, 5308)
    draw4($t8, 5336, 5392, 5404, 5436)
    draw4($t8, 5648, 5680, 5716, 5848)
    sw $t8 5916($v1)
    sw $t8 6016($v1)
    draw16($t3, 1364, 1812, 1876, 2204, 2216, 2388, 2416, 2444, 2872, 2900, 2956, 3132, 3156, 3220, 3344, 3372)
    draw16($t3, 3376, 3444, 3468, 3732, 3980, 4356, 4408, 4492, 4692, 4800, 4980, 5004, 5284, 5432, 5460, 5516)
    draw4($t3, 5712, 5732, 5932, 5972)
    sw $t3 6000($v1)
    sw $t3 6028($v1)
    draw16($t7, 2112, 2196, 2332, 2612, 2660, 2740, 2748, 2860, 2940, 3228, 3236, 3356, 3476, 3668, 3844, 3856)
    draw4($t7, 3896, 4180, 4396, 4468)
    draw4($t7, 4792, 4972, 5216, 5220)
    draw4($t7, 5504, 5508, 5776, 5816)
    sw $t7 5956($v1)
    jr $ra
draw_subtitle: # use t0-t9 v1
    sll $v1 $s7 9 # (0, s7)
    neg $v1 $v1 # (0, -s7)
    addi $v1 $v1 21680 # (44, 42 - s7)
    addi $v1 $v1 BASE_ADDRESS

    draw16($t2, 36, 68, 72, 76, 280, 600, 776, 1096, 1104, 1640, 1648, 1688, 1784, 2092, 2152, 2160)
    draw16($t2, 2184, 2196, 2200, 2260, 2648, 2664, 2672, 2684, 2708, 2712, 3072, 3176, 3184, 3204, 3224, 3320)
    draw4($t2, 3688, 3696, 3708, 3736)
    draw4($t2, 3792, 4192, 4244, 4364)
    draw16($t8, 40, 552, 1112, 1620, 1668, 1728, 1744, 1780, 2180, 2292, 2632, 2636, 2640, 3308, 3316, 3828)
    draw16($t8, 4100, 4184, 4224, 4228, 4304, 4316, 4644, 4676, 4680, 4684, 4688, 4716, 4724, 4748, 4780, 4792)
    sw $t8 4884($v1)
    draw64($t9, 44, 548, 580, 584, 588, 592, 596, 788, 1060, 1092, 1108, 1284, 1548, 1552, 1568, 1572, 1576, 1580, 1604, 1624, 1636, 1652, 1672, 1676, 1692, 1708, 1720, 1748, 1752, 1772, 1776, 1792, 1796, 1800, 1812, 2056, 2068, 2084, 2116, 2132, 2148, 2164, 2176, 2192, 2204, 2220, 2232, 2236, 2252, 2268, 2280, 2296, 2308, 2324, 2564, 2584, 2596, 2628, 2644, 2660, 2676, 2688, 2716, 2732)
    draw64($t9, 2744, 2764, 2780, 2792, 2820, 2836, 3076, 3096, 3108, 3140, 3160, 3172, 3188, 3200, 3228, 3244, 3256, 3276, 3280, 3284, 3288, 3292, 3312, 3332, 3348, 3588, 3608, 3620, 3652, 3672, 3684, 3700, 3712, 3740, 3756, 3768, 3788, 3832, 3844, 3860, 4104, 4116, 4132, 4164, 4180, 4196, 4212, 4240, 4252, 4268, 4280, 4300, 4328, 4344, 4356, 4372, 4620, 4624, 4712, 4744, 4768, 4772, 4820, 4824)
    sw $t9 4844($v1)
    sw $t9 4848($v1)
    sw $t9 4872($v1)
    draw16($t1, 48, 64, 80, 784, 1280, 1564, 1608, 1664, 1704, 1740, 1788, 2216, 2288, 2316, 2560, 2728)
    draw16($t1, 2800, 2816, 3144, 3240, 3328, 3584, 3656, 3732, 3752, 3816, 3824, 3840, 4248, 4336, 4352, 4736)
    sw $t1 4812($v1)
    sw $t1 4856($v1)
    draw16($t0, 84, 272, 560, 768, 1036, 1056, 1100, 1160, 1220, 1236, 1264, 1300, 1540, 1808, 2076, 2172)
    draw16($t0, 2248, 2272, 2300, 2320, 2592, 2700, 2772, 2804, 2808, 2832, 3100, 3104, 3164, 3344, 3616, 3676)
    draw4($t0, 3724, 3804, 3812, 3856)
    draw4($t0, 4128, 4296, 4320, 4368)
    draw4($t0, 4612, 4640, 4696, 4880)
    draw16($t5, 276, 576, 772, 792, 1064, 1088, 1600, 1768, 1804, 1816, 2072, 2112, 2120, 2128, 2312, 2328)
    draw16($t5, 2600, 2624, 2796, 2840, 3092, 3112, 3136, 3272, 3352, 3592, 3624, 3648, 3864, 4112, 4120, 4136)
    draw4($t5, 4160, 4168, 4376, 4628)
    draw4($t5, 4672, 4692, 4720, 4764)
    sw $t5 4776($v1)
    sw $t5 4796($v1)
    sw $t5 4840($v1)
    draw64($0, 544, 1032, 1040, 1068, 1072, 1116, 1156, 1164, 1216, 1232, 1240, 1260, 1268, 1296, 1304, 1560, 1584, 1612, 1616, 1628, 1684, 1716, 1764, 2048, 2096, 2140, 2228, 2572, 2576, 2588, 2604, 2608, 2652, 2696, 2740, 2752, 2756, 2812, 2828, 3088, 3148, 3152, 3212, 3216, 3220, 3252, 3264, 3300, 3324, 3600, 3612, 3660, 3664, 3764, 3796, 3800, 3808, 3820, 3836, 4096, 4124, 4188, 4220, 4276)
    draw64($0, 4348, 4608, 4632, 4700, 4704, 4732, 4756, 4760, 4788, 4808, 4832, 4836, 4860, 4864, 5124, 5128, 5132, 5136, 5140, 5144, 5152, 5156, 5160, 5184, 5188, 5192, 5196, 5200, 5204, 5208, 5216, 5220, 5224, 5228, 5232, 5236, 5240, 5248, 5252, 5256, 5260, 5264, 5268, 5272, 5276, 5280, 5284, 5288, 5292, 5296, 5300, 5304, 5308, 5324, 5328, 5332, 5336, 5340, 5344, 5348, 5352, 5356, 5360, 5364)
    draw4($0, 5368, 5376, 5380, 5384)
    draw4($0, 5388, 5392, 5396, 5400)
    draw16($t4, 556, 1288, 1680, 1712, 2064, 2136, 2224, 2244, 2284, 2304, 2568, 2704, 2736, 2784, 2824, 3248)
    draw16($t4, 3296, 3304, 3336, 3760, 3784, 3848, 4108, 4172, 4272, 4312, 4324, 4332, 4648, 4752, 4784, 4828)
    sw $t4 4888($v1)
    draw16($t7, 1544, 1724, 1732, 2052, 2240, 2256, 2580, 2748, 3156, 3604, 4200, 4208, 4256, 4264, 4340, 4360)
    sw $t7 4740($v1)
    sw $t7 4816($v1)
    sw $t7 4852($v1)
    draw4($t6, 1556, 2088, 2188, 2264)
    draw4($t6, 3260, 3668, 3772, 4176)
    draw4($t6, 4236, 4284, 4616, 4708)
    sw $t6 4868($v1)
    sw $t6 4876($v1)
    draw16($t3, 1632, 1656, 1696, 1756, 2060, 2080, 2124, 2144, 2168, 2208, 2276, 2656, 2680, 2692, 2720, 2760)
    draw16($t3, 2768, 2776, 2788, 3080, 3168, 3192, 3196, 3232, 3680, 3704, 3716, 3728, 3744, 4204, 4216, 4232)
    sw $t3 4260($v1)
    sw $t3 4308($v1)
    sw $t3 4728($v1)
    jr $ra
draw_pre_start:
    li $v0 BASE_ADDRESS
    addi $v1 $v0 34056 # (66, 66)
    jal draw_keybase
    addi $v1 $v0 PRE_S
    jal draw_keys
    addi $v1 $v0 34648 # (86, 67)
    jal draw_start
    # to lazy to store ra in stack
    j pre_ui_end
draw_pre_quit:
    li $v0 BASE_ADDRESS
    addi $v1 $v0 45320 # (66, 88)
    jal draw_keybase
    addi $v1 $v0 PRE_Q
    jal draw_keyq
    addi $v1 $v0 44376 # (86, 86)
    jal draw_quit
    j pre_ui_end
draw_pre_eclipse: # start at v1, use t4
    li $v1 BASE_ADDRESS
    addi $v1 $v1 58388 # (5, 114)
    li $t4 0x474359
    draw256($t4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 68, 72, 76, 80, 84, 88, 92, 96, 100, 104, 108, 112, 120, 124, 128, 132, 136, 140, 512, 516, 520, 524, 528, 532, 536, 540, 544, 548, 552, 556, 560, 564, 568, 572, 576, 580, 584, 588, 592, 596, 600, 604, 608, 612, 616, 620, 624, 628, 632, 636, 640, 644, 648, 652, 656, 660, 664, 668, 672, 1024, 1028, 1032, 1036, 1040, 1044, 1048, 1052, 1056, 1060, 1064, 1068, 1072, 1076, 1080, 1084, 1088, 1092, 1096, 1100, 1104, 1108, 1112, 1116, 1120, 1124, 1128, 1132, 1136, 1140, 1144, 1148, 1152, 1156, 1160, 1164, 1168, 1172, 1176, 1180, 1184, 1188, 1192, 1196, 1536, 1540, 1544, 1548, 1552, 1556, 1560, 1564, 1568, 1572, 1576, 1580, 1584, 1588, 1592, 1596, 1600, 1604, 1608, 1612, 1616, 1620, 1624, 1628, 1632, 1636, 1640, 1644, 1648, 1652, 1656, 1660, 1664, 1668, 1672, 1676, 1680, 1684, 1688, 1692, 1696, 1700, 1704, 1708, 1712, 1716, 2048, 2052, 2056, 2060, 2064, 2068, 2072, 2076, 2080, 2084, 2088, 2092, 2096, 2100, 2104, 2108, 2112, 2116, 2120, 2124, 2128, 2132, 2136, 2140, 2144, 2148, 2152, 2156, 2160, 2164, 2168, 2172, 2176, 2180, 2184, 2188, 2192, 2196, 2200, 2204, 2208, 2212, 2216, 2220, 2224, 2228, 2232, 2236, 2560, 2564, 2568, 2572, 2576, 2580, 2584, 2588, 2592, 2596, 2600, 2604, 2608, 2612, 2616, 2620, 2624, 2628, 2632, 2636, 2640, 2644, 2648, 2652, 2656, 2660, 2664, 2668, 2672, 2676, 2680, 2684, 2688, 2692, 2696, 2700, 2704, 2708, 2712, 2716, 2720, 2724, 2728, 2732)
    draw64($t4, 2736, 2740, 2744, 2748, 2752, 2756, 3072, 3076, 3080, 3084, 3088, 3092, 3096, 3100, 3104, 3108, 3112, 3116, 3120, 3124, 3128, 3132, 3136, 3140, 3144, 3148, 3152, 3156, 3160, 3164, 3168, 3172, 3176, 3180, 3184, 3188, 3192, 3196, 3200, 3204, 3208, 3212, 3216, 3220, 3224, 3228, 3232, 3236, 3240, 3244, 3248, 3252, 3256, 3260, 3264, 3268, 3584, 3588, 3592, 3596, 3600, 3604, 3608, 3612)
    draw64($t4, 3616, 3620, 3624, 3628, 3632, 3636, 3640, 3644, 3648, 3652, 3656, 3660, 3664, 3668, 3672, 3676, 3680, 3684, 3688, 3692, 3696, 3700, 3704, 3708, 3712, 3716, 3720, 3724, 3728, 3732, 3736, 3740, 3744, 3748, 3752, 3756, 3760, 3764, 3768, 3772, 3776, 3780, 4096, 4100, 4104, 4108, 4112, 4116, 4120, 4124, 4128, 4132, 4136, 4140, 4144, 4148, 4152, 4156, 4160, 4164, 4168, 4172, 4176, 4180)
    draw16($t4, 4184, 4188, 4192, 4196, 4200, 4204, 4208, 4212, 4216, 4220, 4224, 4228, 4232, 4236, 4240, 4244)
    draw4($t4, 4248, 4252, 4256, 4260)
    draw4($t4, 4264, 4268, 4272, 4276)
    draw4($t4, 4280, 4284, 4288, 4292)
    li $t4 0x474258
    sw $t4 116($v1)
    jr $ra
draw_pre_alice:
    li $v1 BASE_ADDRESS
    addi $v1 $v1 27668 # (5, 54)
    li $t4 0x3b001b
    sw $t4 44($v1)
    li $t4 0x7a152c
    sw $t4 48($v1)
    li $t4 0xb5313d
    sw $t4 52($v1)
    li $t4 0xab223b
    sw $t4 56($v1)
    li $t4 0x820039
    sw $t4 60($v1)
    li $t4 0xa21a3c
    sw $t4 64($v1)
    li $t4 0xc85746
    sw $t4 68($v1)
    li $t4 0xad383b
    sw $t4 72($v1)
    li $t4 0x591f1e
    sw $t4 76($v1)
    li $t4 0x660629
    sw $t4 552($v1)
    li $t4 0xbb463d
    sw $t4 556($v1)
    li $t4 0xdc7246
    sw $t4 560($v1)
    li $t4 0xfee24f
    sw $t4 564($v1)
    li $t4 0xf3e04e
    sw $t4 568($v1)
    li $t4 0xd47449
    sw $t4 572($v1)
    li $t4 0xad323b
    sw $t4 576($v1)
    li $t4 0xd87545
    sw $t4 580($v1)
    li $t4 0xfbad4d
    sw $t4 584($v1)
    li $t4 0xcd623f
    sw $t4 588($v1)
    li $t4 0xb65a39
    sw $t4 592($v1)
    li $t4 0x711629
    sw $t4 596($v1)
    li $t4 0x620127
    sw $t4 1060($v1)
    li $t4 0xc7523d
    sw $t4 1064($v1)
    li $t4 0xe89545
    sw $t4 1068($v1)
    li $t4 0xca5848
    sw $t4 1072($v1)
    li $t4 0xb72c51
    sw $t4 1076($v1)
    li $t4 0xff5157
    sw $t4 1080($v1)
    li $t4 0xff4954
    sw $t4 1084($v1)
    li $t4 0xfa2f51
    sw $t4 1088($v1)
    li $t4 0xf0224e
    sw $t4 1092($v1)
    li $t4 0xff3b53
    sw $t4 1096($v1)
    li $t4 0xe92f52
    sw $t4 1100($v1)
    li $t4 0xab1549
    sw $t4 1104($v1)
    li $t4 0xc34641
    sw $t4 1108($v1)
    li $t4 0xc1653b
    sw $t4 1112($v1)
    li $t4 0x600127
    sw $t4 1116($v1)
    li $t4 0x630726
    sw $t4 1568($v1)
    li $t4 0xd16143
    sw $t4 1572($v1)
    li $t4 0xdb7c40
    sw $t4 1576($v1)
    li $t4 0xcc494f
    sw $t4 1580($v1)
    li $t4 0xd91c53
    sw $t4 1584($v1)
    li $t4 0xd8174a
    sw $t4 1588($v1)
    li $t4 0xf1304c
    sw $t4 1592($v1)
    li $t4 0xea234c
    sw $t4 1596($v1)
    li $t4 0xe8214c
    sw $t4 1600($v1)
    li $t4 0xff4552
    sw $t4 1604($v1)
    li $t4 0xf5394d
    sw $t4 1608($v1)
    li $t4 0xfd4951
    sw $t4 1612($v1)
    li $t4 0xf84450
    sw $t4 1616($v1)
    li $t4 0xb30f4e
    sw $t4 1620($v1)
    li $t4 0xc04e43
    sw $t4 1624($v1)
    li $t4 0xd3653f
    sw $t4 1628($v1)
    li $t4 0x5f0827
    sw $t4 1632($v1)
    li $t4 0x1d000f
    sw $t4 2076($v1)
    li $t4 0xb95441
    sw $t4 2080($v1)
    li $t4 0xf6b44b
    sw $t4 2084($v1)
    li $t4 0xd36644
    sw $t4 2088($v1)
    li $t4 0xb10a4c
    sw $t4 2092($v1)
    li $t4 0xa6013e
    sw $t4 2096($v1)
    li $t4 0x921938
    sw $t4 2100($v1)
    li $t4 0xea9548
    sw $t4 2104($v1)
    li $t4 0xd08744
    sw $t4 2108($v1)
    li $t4 0xbf6340
    sw $t4 2112($v1)
    li $t4 0xfcd952
    sw $t4 2116($v1)
    li $t4 0xdf8147
    sw $t4 2120($v1)
    li $t4 0xc55740
    sw $t4 2124($v1)
    li $t4 0xf7ac4c
    sw $t4 2128($v1)
    li $t4 0xc3533f
    sw $t4 2132($v1)
    li $t4 0xa4153a
    sw $t4 2136($v1)
    li $t4 0xbd4c3e
    sw $t4 2140($v1)
    li $t4 0xc9573f
    sw $t4 2144($v1)
    li $t4 0x2e1011
    sw $t4 2148($v1)
    li $t4 0x1e000d
    sw $t4 2196($v1)
    li $t4 0x5c2120
    sw $t4 2200($v1)
    li $t4 0xd76f47
    sw $t4 2204($v1)
    li $t4 0xb6413e
    sw $t4 2208($v1)
    li $t4 0xb6453f
    sw $t4 2212($v1)
    li $t4 0xf0a14b
    sw $t4 2216($v1)
    li $t4 0xda7a42
    sw $t4 2220($v1)
    sw $t4 8216($v1)
    li $t4 0x8b2132
    sw $t4 2224($v1)
    li $t4 0x210011
    sw $t4 2228($v1)
    li $t4 0x74042b
    sw $t4 2588($v1)
    li $t4 0xe5c34b
    sw $t4 2592($v1)
    li $t4 0xe6aa46
    sw $t4 2596($v1)
    li $t4 0xa31a3b
    sw $t4 2600($v1)
    li $t4 0x940a38
    sw $t4 2604($v1)
    li $t4 0xba483c
    sw $t4 2608($v1)
    li $t4 0xea804a
    sw $t4 2612($v1)
    li $t4 0xfff157
    sw $t4 2616($v1)
    li $t4 0xf4d84e
    sw $t4 2620($v1)
    li $t4 0xf3c14a
    sw $t4 2624($v1)
    li $t4 0xffff58
    sw $t4 2628($v1)
    li $t4 0xf1ce52
    sw $t4 2632($v1)
    li $t4 0x810037
    sw $t4 2636($v1)
    li $t4 0xdc744a
    sw $t4 2640($v1)
    li $t4 0xcd5a47
    sw $t4 2644($v1)
    li $t4 0xe6b849
    sw $t4 2648($v1)
    li $t4 0xbf453f
    sw $t4 2652($v1)
    li $t4 0xe17e40
    sw $t4 2656($v1)
    li $t4 0x872330
    sw $t4 2660($v1)
    li $t4 0x250011
    sw $t4 2704($v1)
    li $t4 0xaf2b3c
    sw $t4 2708($v1)
    li $t4 0xf8ac50
    sw $t4 2712($v1)
    li $t4 0xda7d4f
    sw $t4 2716($v1)
    li $t4 0xcb303e
    sw $t4 2720($v1)
    li $t4 0xe03843
    sw $t4 2724($v1)
    li $t4 0xe64249
    sw $t4 2728($v1)
    li $t4 0xd83741
    sw $t4 2732($v1)
    li $t4 0xaf2c3c
    sw $t4 2736($v1)
    li $t4 0xc75744
    sw $t4 2740($v1)
    li $t4 0x6c0f2b
    sw $t4 2744($v1)
    li $t4 0x240e0c
    sw $t4 3096($v1)
    li $t4 0xda6b45
    sw $t4 3100($v1)
    li $t4 0xfeec55
    sw $t4 3104($v1)
    li $t4 0xdd9345
    sw $t4 3108($v1)
    li $t4 0x94003a
    sw $t4 3112($v1)
    li $t4 0xe19f47
    sw $t4 3116($v1)
    li $t4 0xffd052
    sw $t4 3120($v1)
    li $t4 0xf8d753
    sw $t4 3124($v1)
    li $t4 0xfeff55
    sw $t4 3128($v1)
    li $t4 0xd8af4c
    sw $t4 3132($v1)
    li $t4 0xac223b
    sw $t4 3136($v1)
    li $t4 0xfae64f
    sw $t4 3140($v1)
    li $t4 0xfeff53
    sw $t4 3144($v1)
    li $t4 0xb1273c
    sw $t4 3148($v1)
    li $t4 0xc77c47
    sw $t4 3152($v1)
    li $t4 0xb95b44
    sw $t4 3156($v1)
    li $t4 0x9b253e
    sw $t4 3160($v1)
    li $t4 0xffed53
    sw $t4 3164($v1)
    li $t4 0xee8e4a
    sw $t4 3168($v1)
    li $t4 0xa6223b
    sw $t4 3172($v1)
    li $t4 0xa8283c
    sw $t4 3216($v1)
    li $t4 0xf7bb4f
    sw $t4 3220($v1)
    li $t4 0xcf9a4b
    sw $t4 3224($v1)
    li $t4 0xab073c
    sw $t4 3228($v1)
    li $t4 0xd30140
    sw $t4 3232($v1)
    li $t4 0xda0740
    sw $t4 3236($v1)
    li $t4 0xb0003c
    sw $t4 3240($v1)
    li $t4 0xc23a3f
    sw $t4 3244($v1)
    li $t4 0xe99c50
    sw $t4 3248($v1)
    li $t4 0xd06a47
    sw $t4 3252($v1)
    li $t4 0xca6348
    sw $t4 3256($v1)
    li $t4 0x5f0a24
    sw $t4 3260($v1)
    li $t4 0x91063a
    sw $t4 3608($v1)
    li $t4 0xfbce53
    sw $t4 3612($v1)
    li $t4 0xf9dd53
    sw $t4 3616($v1)
    li $t4 0xa6133f
    sw $t4 3620($v1)
    li $t4 0x9a183d
    sw $t4 3624($v1)
    li $t4 0xffff54
    sw $t4 3628($v1)
    li $t4 0xfccf55
    sw $t4 3632($v1)
    li $t4 0xf9ce51
    sw $t4 3636($v1)
    li $t4 0xfffc54
    sw $t4 3640($v1)
    li $t4 0xdbb34b
    sw $t4 3644($v1)
    li $t4 0x87043c
    sw $t4 3648($v1)
    li $t4 0xba413f
    sw $t4 3652($v1)
    li $t4 0xfcea50
    sw $t4 3656($v1)
    li $t4 0xdd904f
    sw $t4 3660($v1)
    li $t4 0x9f1739
    sw $t4 3664($v1)
    li $t4 0xf6e750
    sw $t4 3668($v1)
    li $t4 0xa52f41
    sw $t4 3672($v1)
    li $t4 0xfdfa56
    sw $t4 3676($v1)
    li $t4 0xebc64b
    sw $t4 3680($v1)
    li $t4 0xd7663e
    sw $t4 3684($v1)
    li $t4 0x911238
    sw $t4 3688($v1)
    li $t4 0x4a081d
    sw $t4 3724($v1)
    li $t4 0xd76348
    sw $t4 3728($v1)
    li $t4 0xf8f753
    sw $t4 3732($v1)
    li $t4 0xb7483f
    sw $t4 3736($v1)
    li $t4 0xf3a64b
    sw $t4 3740($v1)
    li $t4 0xf7d952
    sw $t4 3744($v1)
    li $t4 0xd28545
    sw $t4 3748($v1)
    li $t4 0xfff457
    sw $t4 3752($v1)
    li $t4 0xa61b3e
    sw $t4 3756($v1)
    li $t4 0xe8ac48
    sw $t4 3760($v1)
    li $t4 0xebbc4a
    sw $t4 3764($v1)
    li $t4 0xf6c74e
    sw $t4 3768($v1)
    li $t4 0xba793b
    sw $t4 3772($v1)
    li $t4 0x300014
    sw $t4 4116($v1)
    li $t4 0xb23a3e
    sw $t4 4120($v1)
    li $t4 0xfee556
    sw $t4 4124($v1)
    li $t4 0xf2c64a
    sw $t4 4128($v1)
    li $t4 0x990039
    sw $t4 4132($v1)
    li $t4 0x98173e
    sw $t4 4136($v1)
    li $t4 0xfefe55
    sw $t4 4140($v1)
    li $t4 0xf6cb50
    sw $t4 4144($v1)
    li $t4 0xc13a3f
    sw $t4 4148($v1)
    li $t4 0xfaff53
    sw $t4 4152($v1)
    li $t4 0xd8b14a
    sw $t4 4156($v1)
    li $t4 0x9e1f46
    sw $t4 4160($v1)
    li $t4 0xa53649
    sw $t4 4164($v1)
    li $t4 0xba3f3c
    sw $t4 4168($v1)
    li $t4 0xdfa649
    sw $t4 4172($v1)
    li $t4 0x780036
    sw $t4 4176($v1)
    li $t4 0xd48f45
    sw $t4 4180($v1)
    li $t4 0xaa2c3f
    sw $t4 4184($v1)
    li $t4 0xf0a34f
    sw $t4 4188($v1)
    li $t4 0xecab4c
    sw $t4 4192($v1)
    li $t4 0xd7623e
    sw $t4 4196($v1)
    li $t4 0x921338
    sw $t4 4200($v1)
    li $t4 0xac243f
    sw $t4 4236($v1)
    li $t4 0xfcc851
    sw $t4 4240($v1)
    li $t4 0xffff56
    sw $t4 4244($v1)
    li $t4 0xe8a24e
    sw $t4 4248($v1)
    li $t4 0xd5a048
    sw $t4 4252($v1)
    li $t4 0xf7da54
    sw $t4 4256($v1)
    li $t4 0xaa2741
    sw $t4 4260($v1)
    li $t4 0xffff57
    sw $t4 4264($v1)
    sw $t4 4652($v1)
    li $t4 0x9d223d
    sw $t4 4268($v1)
    li $t4 0xc46d43
    sw $t4 4272($v1)
    li $t4 0xd79e49
    sw $t4 4276($v1)
    li $t4 0xdf7746
    sw $t4 4280($v1)
    li $t4 0xdbb74d
    sw $t4 4284($v1)
    li $t4 0x3f001c
    sw $t4 4288($v1)
    li $t4 0x790031
    sw $t4 4628($v1)
    li $t4 0xda7e43
    sw $t4 4632($v1)
    li $t4 0xfdfd56
    sw $t4 4636($v1)
    sw $t4 5148($v1)
    li $t4 0xce8647
    sw $t4 4640($v1)
    li $t4 0xb1233c
    sw $t4 4644($v1)
    li $t4 0xa52a3f
    sw $t4 4648($v1)
    li $t4 0xefbc49
    sw $t4 4656($v1)
    li $t4 0x980039
    sw $t4 4660($v1)
    li $t4 0xf1b74b
    sw $t4 4664($v1)
    li $t4 0xe4bb4a
    sw $t4 4668($v1)
    li $t4 0xb93354
    sw $t4 4672($v1)
    li $t4 0xf6ba75
    sw $t4 4676($v1)
    li $t4 0xab3b4b
    sw $t4 4680($v1)
    li $t4 0x940434
    sw $t4 4684($v1)
    li $t4 0xa02544
    sw $t4 4688($v1)
    li $t4 0xb52c45
    sw $t4 4692($v1)
    li $t4 0x980839
    sw $t4 4696($v1)
    li $t4 0xde6f41
    sw $t4 4700($v1)
    li $t4 0xeeaf4c
    sw $t4 4704($v1)
    li $t4 0xe39645
    sw $t4 4708($v1)
    li $t4 0x8e0537
    sw $t4 4712($v1)
    li $t4 0xaf2942
    sw $t4 4748($v1)
    li $t4 0xfffb58
    sw $t4 4752($v1)
    li $t4 0xffd253
    sw $t4 4756($v1)
    li $t4 0xb8273f
    sw $t4 4760($v1)
    li $t4 0xc59148
    sw $t4 4764($v1)
    li $t4 0xeb944c
    sw $t4 4768($v1)
    li $t4 0xa90440
    sw $t4 4772($v1)
    li $t4 0xffe952
    sw $t4 4776($v1)
    li $t4 0x98243b
    sw $t4 4780($v1)
    li $t4 0xb44946
    sw $t4 4784($v1)
    li $t4 0xc37348
    sw $t4 4788($v1)
    li $t4 0xc14f3e
    sw $t4 4792($v1)
    li $t4 0xddb24f
    sw $t4 4796($v1)
    li $t4 0x30000d
    sw $t4 4800($v1)
    li $t4 0x71002e
    sw $t4 5140($v1)
    li $t4 0xcf6941
    sw $t4 5144($v1)
    li $t4 0xb66545
    sw $t4 5152($v1)
    li $t4 0xbf433e
    sw $t4 5156($v1)
    li $t4 0xa51a3c
    sw $t4 5160($v1)
    li $t4 0xefbf4b
    sw $t4 5164($v1)
    li $t4 0xd1994a
    sw $t4 5168($v1)
    li $t4 0x890038
    sw $t4 5172($v1)
    li $t4 0x4d201c
    sw $t4 5176($v1)
    li $t4 0x372f0f
    sw $t4 5180($v1)
    li $t4 0x63091e
    sw $t4 5184($v1)
    li $t4 0xb55353
    sw $t4 5188($v1)
    li $t4 0xed9e68
    sw $t4 5192($v1)
    li $t4 0xe99871
    sw $t4 5196($v1)
    li $t4 0x9d5f44
    sw $t4 5200($v1)
    li $t4 0x1f0909
    sw $t4 5204($v1)
    li $t4 0x870337
    sw $t4 5208($v1)
    li $t4 0xab193c
    sw $t4 5212($v1)
    li $t4 0xedc54a
    sw $t4 5216($v1)
    li $t4 0xe9b049
    sw $t4 5220($v1)
    li $t4 0x8d0236
    sw $t4 5224($v1)
    li $t4 0x8879a8
    sw $t4 5240($v1)
    li $t4 0xbfaeea
    sw $t4 5244($v1)
    li $t4 0x2e2343
    sw $t4 5248($v1)
    li $t4 0xae2841
    sw $t4 5260($v1)
    li $t4 0xffdc53
    sw $t4 5264($v1)
    li $t4 0xf1a54e
    sw $t4 5268($v1)
    li $t4 0x800035
    sw $t4 5272($v1)
    li $t4 0xd68e4d
    sw $t4 5276($v1)
    li $t4 0x8c3e25
    sw $t4 5280($v1)
    li $t4 0x5f0215
    sw $t4 5284($v1)
    li $t4 0xa55e32
    sw $t4 5288($v1)
    li $t4 0xd36d59
    sw $t4 5292($v1)
    li $t4 0xd37658
    sw $t4 5296($v1)
    li $t4 0x760025
    sw $t4 5300($v1)
    li $t4 0xa41842
    sw $t4 5304($v1)
    li $t4 0xd46742
    sw $t4 5308($v1)
    li $t4 0x581540
    sw $t4 5312($v1)
    li $t4 0x363149
    sw $t4 5316($v1)
    li $t4 0x580025
    sw $t4 5652($v1)
    li $t4 0x920139
    sw $t4 5656($v1)
    li $t4 0xdd9a45
    sw $t4 5660($v1)
    li $t4 0xc16c43
    sw $t4 5664($v1)
    li $t4 0xdcb44b
    sw $t4 5668($v1)
    li $t4 0x960f3d
    sw $t4 5672($v1)
    li $t4 0xa1373e
    sw $t4 5676($v1)
    li $t4 0xf6eb54
    sw $t4 5680($v1)
    li $t4 0xc85a44
    sw $t4 5684($v1)
    li $t4 0x0a0066
    sw $t4 5688($v1)
    li $t4 0x13237c
    sw $t4 5692($v1)
    li $t4 0x421f1f
    sw $t4 5696($v1)
    li $t4 0x4b2013
    sw $t4 5700($v1)
    li $t4 0xebaa79
    sw $t4 5704($v1)
    li $t4 0xffcd7f
    sw $t4 5708($v1)
    li $t4 0x855a74
    sw $t4 5712($v1)
    li $t4 0x11032a
    sw $t4 5716($v1)
    li $t4 0x920930
    sw $t4 5720($v1)
    li $t4 0x8c003e
    sw $t4 5724($v1)
    li $t4 0xb32a3c
    sw $t4 5728($v1)
    li $t4 0xfdee50
    sw $t4 5732($v1)
    li $t4 0x952b3b
    sw $t4 5736($v1)
    li $t4 0x2d2241
    sw $t4 5748($v1)
    li $t4 0xd1c6f2
    sw $t4 5752($v1)
    li $t4 0xf7f9f9
    sw $t4 5756($v1)
    li $t4 0xd2c7f1
    sw $t4 5760($v1)
    li $t4 0x968bbe
    sw $t4 5764($v1)
    li $t4 0x5c467a
    sw $t4 5768($v1)
    li $t4 0x920c3a
    sw $t4 5772($v1)
    li $t4 0xe0784a
    sw $t4 5776($v1)
    li $t4 0xc24d44
    sw $t4 5780($v1)
    li $t4 0x9d2f48
    sw $t4 5784($v1)
    li $t4 0xd96845
    sw $t4 5788($v1)
    li $t4 0x846876
    sw $t4 5792($v1)
    li $t4 0x001659
    sw $t4 5796($v1)
    li $t4 0x6c2d53
    sw $t4 5800($v1)
    li $t4 0xffaf70
    sw $t4 5804($v1)
    li $t4 0xb18e6f
    sw $t4 5808($v1)
    li $t4 0x3f0246
    sw $t4 5812($v1)
    li $t4 0xa40439
    sw $t4 5816($v1)
    li $t4 0xa01728
    sw $t4 5820($v1)
    li $t4 0x9c4a95
    sw $t4 5824($v1)
    li $t4 0xad9ff0
    sw $t4 5828($v1)
    li $t4 0x800036
    sw $t4 6168($v1)
    li $t4 0xbe4040
    sw $t4 6172($v1)
    li $t4 0xee8248
    sw $t4 6176($v1)
    li $t4 0xf8e951
    sw $t4 6180($v1)
    li $t4 0xb54741
    sw $t4 6184($v1)
    li $t4 0x850038
    sw $t4 6188($v1)
    li $t4 0xaf4b41
    sw $t4 6192($v1)
    li $t4 0xd68447
    sw $t4 6196($v1)
    li $t4 0x150d70
    sw $t4 6200($v1)
    li $t4 0x3e7fe0
    sw $t4 6204($v1)
    li $t4 0xe3a4af
    sw $t4 6208($v1)
    li $t4 0xffaf75
    sw $t4 6212($v1)
    li $t4 0xfae9bd
    sw $t4 6216($v1)
    li $t4 0xffe8a7
    sw $t4 6220($v1)
    li $t4 0x72799f
    sw $t4 6224($v1)
    li $t4 0x510063
    sw $t4 6228($v1)
    li $t4 0xa40034
    sw $t4 6232($v1)
    li $t4 0x87003b
    sw $t4 6236($v1)
    li $t4 0xa1163b
    sw $t4 6240($v1)
    li $t4 0xe3a548
    sw $t4 6244($v1)
    li $t4 0x96223a
    sw $t4 6248($v1)
    li $t4 0x33274a
    sw $t4 6260($v1)
    li $t4 0xc1b1ea
    sw $t4 6264($v1)
    li $t4 0xe8e7f6
    sw $t4 6268($v1)
    li $t4 0xeff2fa
    sw $t4 6272($v1)
    li $t4 0xeff3fe
    sw $t4 6276($v1)
    li $t4 0xb397dc
    sw $t4 6280($v1)
    li $t4 0x820036
    sw $t4 6284($v1)
    li $t4 0xcd6048
    sw $t4 6288($v1)
    li $t4 0xa8253c
    sw $t4 6292($v1)
    li $t4 0xd99c7a
    sw $t4 6296($v1)
    li $t4 0xc76160
    sw $t4 6300($v1)
    li $t4 0xc695cc
    sw $t4 6304($v1)
    li $t4 0x004dde
    sw $t4 6308($v1)
    li $t4 0x97c4d5
    sw $t4 6312($v1)
    li $t4 0xfeed99
    sw $t4 6316($v1)
    li $t4 0xa08696
    sw $t4 6320($v1)
    li $t4 0x514285
    sw $t4 6324($v1)
    li $t4 0xaf1734
    sw $t4 6328($v1)
    li $t4 0x870136
    sw $t4 6332($v1)
    li $t4 0x995194
    sw $t4 6336($v1)
    li $t4 0x272c38
    sw $t4 6340($v1)
    li $t4 0x48011d
    sw $t4 6676($v1)
    li $t4 0xb93c3c
    sw $t4 6680($v1)
    li $t4 0xeba647
    sw $t4 6684($v1)
    li $t4 0xffca57
    sw $t4 6688($v1)
    li $t4 0xfce853
    sw $t4 6692($v1)
    li $t4 0xd87541
    sw $t4 6696($v1)
    li $t4 0x8f013b
    sw $t4 6700($v1)
    li $t4 0x8a0038
    sw $t4 6704($v1)
    li $t4 0xa0153f
    sw $t4 6708($v1)
    li $t4 0x0066dc
    sw $t4 6712($v1)
    li $t4 0x31b1ff
    sw $t4 6716($v1)
    li $t4 0xffeccc
    sw $t4 6720($v1)
    li $t4 0xf9dda6
    sw $t4 6724($v1)
    li $t4 0xfbe4b6
    sw $t4 6728($v1)
    li $t4 0xfcecb6
    sw $t4 6732($v1)
    li $t4 0xd0bda5
    sw $t4 6736($v1)
    li $t4 0x803144
    sw $t4 6740($v1)
    li $t4 0x940937
    sw $t4 6744($v1)
    li $t4 0xb5313e
    sw $t4 6748($v1)
    li $t4 0x81003a
    sw $t4 6752($v1)
    li $t4 0xbf3f3d
    sw $t4 6756($v1)
    li $t4 0x900e37
    sw $t4 6760($v1)
    li $t4 0xb098e3
    sw $t4 6772($v1)
    li $t4 0xc2b1e9
    sw $t4 6776($v1)
    li $t4 0xa285dd
    sw $t4 6780($v1)
    li $t4 0xad95e2
    sw $t4 6784($v1)
    li $t4 0xeff6fc
    sw $t4 6788($v1)
    li $t4 0xede9f2
    sw $t4 6792($v1)
    li $t4 0x86002e
    sw $t4 6796($v1)
    li $t4 0xc24c3f
    sw $t4 6800($v1)
    li $t4 0xa41e3a
    sw $t4 6804($v1)
    li $t4 0xc0625b
    sw $t4 6808($v1)
    li $t4 0xe36b57
    sw $t4 6812($v1)
    li $t4 0xdabba7
    sw $t4 6816($v1)
    li $t4 0x8acfe6
    sw $t4 6820($v1)
    li $t4 0xfff4b8
    sw $t4 6824($v1)
    li $t4 0xfffdc1
    sw $t4 6828($v1)
    li $t4 0xcbbaa3
    sw $t4 6832($v1)
    li $t4 0x744167
    sw $t4 6836($v1)
    li $t4 0xa40d32
    sw $t4 6840($v1)
    li $t4 0x7d1b4e
    sw $t4 6844($v1)
    li $t4 0x464866
    sw $t4 6848($v1)
    li $t4 0x2d253a
    sw $t4 6852($v1)
    li $t4 0x760030
    sw $t4 7188($v1)
    li $t4 0xd96743
    sw $t4 7192($v1)
    li $t4 0xf7cf51
    sw $t4 7196($v1)
    li $t4 0xfbd553
    sw $t4 7200($v1)
    li $t4 0xfee754
    sw $t4 7204($v1)
    li $t4 0xe8d34e
    sw $t4 7208($v1)
    li $t4 0x8d003b
    sw $t4 7212($v1)
    li $t4 0x900638
    sw $t4 7216($v1)
    li $t4 0xba574f
    sw $t4 7220($v1)
    li $t4 0xd3d7bb
    sw $t4 7224($v1)
    li $t4 0xdcd7bf
    sw $t4 7228($v1)
    li $t4 0xfbe4b9
    sw $t4 7232($v1)
    li $t4 0xfadcab
    sw $t4 7236($v1)
    li $t4 0xf6d9ab
    sw $t4 7240($v1)
    li $t4 0xfee7b7
    sw $t4 7244($v1)
    li $t4 0xfff5b7
    sw $t4 7248($v1)
    li $t4 0xcb8066
    sw $t4 7252($v1)
    li $t4 0x9c233b
    sw $t4 7256($v1)
    li $t4 0xe4ba4c
    sw $t4 7260($v1)
    li $t4 0x800137
    sw $t4 7264($v1)
    li $t4 0xdb7c4b
    sw $t4 7268($v1)
    li $t4 0xd36843
    sw $t4 7272($v1)
    li $t4 0x5e0725
    sw $t4 7276($v1)
    li $t4 0xc0ade8
    sw $t4 7284($v1)
    li $t4 0xfeffff
    sw $t4 7288($v1)
    li $t4 0xdcd5f6
    sw $t4 7292($v1)
    li $t4 0xbcaae9
    sw $t4 7296($v1)
    li $t4 0xb09ae6
    sw $t4 7300($v1)
    li $t4 0xc7bcf2
    sw $t4 7304($v1)
    li $t4 0x973a7c
    sw $t4 7308($v1)
    li $t4 0xa31e35
    sw $t4 7312($v1)
    li $t4 0x990839
    sw $t4 7316($v1)
    li $t4 0x92002b
    sw $t4 7320($v1)
    li $t4 0x7d3751
    sw $t4 7324($v1)
    li $t4 0xc79278
    sw $t4 7328($v1)
    li $t4 0xf8a774
    sw $t4 7332($v1)
    li $t4 0xdd9b78
    sw $t4 7336($v1)
    li $t4 0xd69171
    sw $t4 7340($v1)
    li $t4 0xbd383e
    sw $t4 7344($v1)
    li $t4 0x9d0733
    sw $t4 7348($v1)
    li $t4 0x8c0033
    sw $t4 7352($v1)
    li $t4 0x79123c
    sw $t4 7356($v1)
    li $t4 0x887dbe
    sw $t4 7360($v1)
    li $t4 0xaa8ddd
    sw $t4 7364($v1)
    li $t4 0x69002b
    sw $t4 7700($v1)
    li $t4 0xd37143
    sw $t4 7704($v1)
    li $t4 0xfdfd54
    sw $t4 7708($v1)
    li $t4 0xf5be51
    sw $t4 7712($v1)
    li $t4 0xfbe352
    sw $t4 7716($v1)
    li $t4 0xf1f051
    sw $t4 7720($v1)
    li $t4 0x87043a
    sw $t4 7724($v1)
    li $t4 0xb83b3c
    sw $t4 7728($v1)
    li $t4 0xc25f49
    sw $t4 7732($v1)
    li $t4 0xfa9e71
    sw $t4 7736($v1)
    li $t4 0xffeeae
    sw $t4 7740($v1)
    li $t4 0xfff2be
    sw $t4 7744($v1)
    li $t4 0xffd097
    sw $t4 7748($v1)
    li $t4 0xdf8869
    sw $t4 7752($v1)
    li $t4 0xf1d3a6
    sw $t4 7756($v1)
    li $t4 0xd49274
    sw $t4 7760($v1)
    li $t4 0x970c3e
    sw $t4 7764($v1)
    li $t4 0x98193e
    sw $t4 7768($v1)
    li $t4 0xfdf451
    sw $t4 7772($v1)
    li $t4 0xaf1b3c
    sw $t4 7776($v1)
    li $t4 0xd3a94c
    sw $t4 7780($v1)
    li $t4 0xffcc53
    sw $t4 7784($v1)
    li $t4 0x9b3d32
    sw $t4 7788($v1)
    li $t4 0x46395b
    sw $t4 7796($v1)
    li $t4 0xcec2f0
    sw $t4 7800($v1)
    li $t4 0xf0f0fd
    sw $t4 7804($v1)
    li $t4 0xf4f7fe
    sw $t4 7808($v1)
    li $t4 0xe3dff7
    sw $t4 7812($v1)
    li $t4 0xb4aaf4
    sw $t4 7816($v1)
    li $t4 0xa375c4
    sw $t4 7820($v1)
    li $t4 0x930024
    sw $t4 7824($v1)
    li $t4 0x930846
    sw $t4 7828($v1)
    li $t4 0x9667ae
    sw $t4 7832($v1)
    li $t4 0x7c60b8
    sw $t4 7836($v1)
    li $t4 0x230865
    sw $t4 7840($v1)
    li $t4 0x170055
    sw $t4 7844($v1)
    li $t4 0x583782
    sw $t4 7848($v1)
    li $t4 0xae83c1
    sw $t4 7852($v1)
    li $t4 0x9168bf
    sw $t4 7856($v1)
    li $t4 0x781963
    sw $t4 7860($v1)
    li $t4 0x900023
    sw $t4 7864($v1)
    li $t4 0x992e72
    sw $t4 7868($v1)
    li $t4 0xada3f5
    sw $t4 7872($v1)
    li $t4 0x362b44
    sw $t4 7876($v1)
    li $t4 0x780031
    sw $t4 8212($v1)
    li $t4 0xfdfc55
    sw $t4 8220($v1)
    li $t4 0xe9a948
    sw $t4 8224($v1)
    li $t4 0xf7e64f
    sw $t4 8228($v1)
    li $t4 0xf1ed52
    sw $t4 8232($v1)
    li $t4 0x7b0036
    sw $t4 8236($v1)
    li $t4 0xc85244
    sw $t4 8240($v1)
    li $t4 0xa71d3e
    sw $t4 8244($v1)
    li $t4 0x99393c
    sw $t4 8248($v1)
    li $t4 0xc78563
    sw $t4 8252($v1)
    li $t4 0xe3b190
    sw $t4 8256($v1)
    li $t4 0xd1a687
    sw $t4 8260($v1)
    li $t4 0xcc7d5b
    sw $t4 8264($v1)
    li $t4 0x8f3e39
    sw $t4 8268($v1)
    li $t4 0x5a0d46
    sw $t4 8272($v1)
    li $t4 0x890039
    sw $t4 8276($v1)
    li $t4 0x9a133a
    sw $t4 8280($v1)
    li $t4 0xfeff57
    sw $t4 8284($v1)
    li $t4 0xbb4645
    sw $t4 8288($v1)
    li $t4 0xd3b04a
    sw $t4 8292($v1)
    li $t4 0xf7fe52
    sw $t4 8296($v1)
    li $t4 0x66002b
    sw $t4 8300($v1)
    li $t4 0x403457
    sw $t4 8312($v1)
    li $t4 0x7d6aa3
    sw $t4 8316($v1)
    li $t4 0xd3c9f2
    sw $t4 8320($v1)
    li $t4 0xecedff
    sw $t4 8324($v1)
    li $t4 0xf6fdff
    sw $t4 8328($v1)
    li $t4 0xaf4685
    sw $t4 8332($v1)
    li $t4 0x7e0021
    sw $t4 8336($v1)
    li $t4 0x523793
    sw $t4 8340($v1)
    li $t4 0xdbdef8
    sw $t4 8344($v1)
    li $t4 0xf7f6ff
    sw $t4 8348($v1)
    li $t4 0xc0b3ee
    sw $t4 8352($v1)
    li $t4 0x725ba5
    sw $t4 8356($v1)
    li $t4 0x9e87ca
    sw $t4 8360($v1)
    li $t4 0xfdffff
    sw $t4 8364($v1)
    li $t4 0xfcffff
    sw $t4 8368($v1)
    li $t4 0xbcbcf1
    sw $t4 8372($v1)
    li $t4 0x8f053f
    sw $t4 8376($v1)
    li $t4 0xa22057
    sw $t4 8380($v1)
    li $t4 0x493759
    sw $t4 8384($v1)
    li $t4 0x290011
    sw $t4 8724($v1)
    li $t4 0xb03f3e
    sw $t4 8728($v1)
    li $t4 0xfefe57
    sw $t4 8732($v1)
    li $t4 0xca7e46
    sw $t4 8736($v1)
    li $t4 0xd57944
    sw $t4 8740($v1)
    li $t4 0xfbfc54
    sw $t4 8744($v1)
    li $t4 0xb05c42
    sw $t4 8748($v1)
    li $t4 0xcc7f4a
    sw $t4 8752($v1)
    li $t4 0xdd8d48
    sw $t4 8756($v1)
    li $t4 0x530e47
    sw $t4 8760($v1)
    li $t4 0xb15a42
    sw $t4 8764($v1)
    li $t4 0xe17d5b
    sw $t4 8768($v1)
    li $t4 0x7b292b
    sw $t4 8772($v1)
    li $t4 0x692325
    sw $t4 8776($v1)
    li $t4 0x532565
    sw $t4 8780($v1)
    li $t4 0x6c5dbb
    sw $t4 8784($v1)
    li $t4 0x6d2e81
    sw $t4 8788($v1)
    li $t4 0x93043a
    sw $t4 8792($v1)
    li $t4 0xffe755
    sw $t4 8796($v1)
    li $t4 0xe2b94a
    sw $t4 8800($v1)
    li $t4 0xb54141
    sw $t4 8804($v1)
    li $t4 0xe9db50
    sw $t4 8808($v1)
    li $t4 0x6f062c
    sw $t4 8812($v1)
    li $t4 0x40325d
    sw $t4 8832($v1)
    li $t4 0x9489bc
    sw $t4 8836($v1)
    li $t4 0xc6b2e7
    sw $t4 8840($v1)
    li $t4 0x40003d
    sw $t4 8844($v1)
    li $t4 0x1b3fa4
    sw $t4 8848($v1)
    li $t4 0x0031a6
    sw $t4 8852($v1)
    li $t4 0x4d4ca7
    sw $t4 8856($v1)
    li $t4 0xac92db
    sw $t4 8860($v1)
    li $t4 0xf6f9ff
    sw $t4 8864($v1)
    li $t4 0xaf96ba
    sw $t4 8868($v1)
    li $t4 0x470d2d
    sw $t4 8872($v1)
    li $t4 0xc9bbea
    sw $t4 8876($v1)
    li $t4 0xeaeeff
    sw $t4 8880($v1)
    li $t4 0x7363b4
    sw $t4 8884($v1)
    li $t4 0x3a1a7b
    sw $t4 8888($v1)
    li $t4 0x5d0045
    sw $t4 8892($v1)
    li $t4 0x4e0013
    sw $t4 8896($v1)
    li $t4 0x850035
    sw $t4 9240($v1)
    li $t4 0xf1c34b
    sw $t4 9244($v1)
    li $t4 0xbf7f47
    sw $t4 9248($v1)
    li $t4 0x8b0033
    sw $t4 9252($v1)
    li $t4 0xffff55
    sw $t4 9256($v1)
    li $t4 0xdcbc4f
    sw $t4 9260($v1)
    li $t4 0xaa2b37
    sw $t4 9264($v1)
    li $t4 0xfeb54a
    sw $t4 9268($v1)
    li $t4 0xdcc9ea
    sw $t4 9272($v1)
    li $t4 0x9d7cb8
    sw $t4 9276($v1)
    li $t4 0x965562
    sw $t4 9280($v1)
    li $t4 0xbf6452
    sw $t4 9284($v1)
    li $t4 0x63376d
    sw $t4 9288($v1)
    li $t4 0x5e45a8
    sw $t4 9292($v1)
    li $t4 0xbeafe6
    sw $t4 9296($v1)
    li $t4 0x8275b0
    sw $t4 9300($v1)
    li $t4 0x73002e
    sw $t4 9304($v1)
    li $t4 0xc16845
    sw $t4 9308($v1)
    li $t4 0xda9c46
    sw $t4 9312($v1)
    li $t4 0x2a0011
    sw $t4 9316($v1)
    li $t4 0x882235
    sw $t4 9320($v1)
    li $t4 0x7a0231
    sw $t4 9324($v1)
    li $t4 0x5b3d95
    sw $t4 9352($v1)
    li $t4 0x5a7edf
    sw $t4 9356($v1)
    li $t4 0x008ffd
    sw $t4 9360($v1)
    li $t4 0x0842b2
    sw $t4 9364($v1)
    li $t4 0x0d0157
    sw $t4 9368($v1)
    li $t4 0x5b49a6
    sw $t4 9372($v1)
    li $t4 0xab9bdb
    sw $t4 9376($v1)
    li $t4 0x7f0d46
    sw $t4 9380($v1)
    li $t4 0x800023
    sw $t4 9384($v1)
    li $t4 0x550f3a
    sw $t4 9388($v1)
    li $t4 0x792163
    sw $t4 9392($v1)
    li $t4 0x000574
    sw $t4 9396($v1)
    li $t4 0x072a94
    sw $t4 9400($v1)
    li $t4 0x101e6e
    sw $t4 9404($v1)
    li $t4 0xa6533d
    sw $t4 9756($v1)
    li $t4 0xbf7346
    sw $t4 9760($v1)
    li $t4 0x7c0a45
    sw $t4 9764($v1)
    li $t4 0xd97c40
    sw $t4 9768($v1)
    li $t4 0xdeac4b
    sw $t4 9772($v1)
    li $t4 0x84094a
    sw $t4 9776($v1)
    li $t4 0xc54a3e
    sw $t4 9780($v1)
    li $t4 0xa089ac
    sw $t4 9784($v1)
    li $t4 0xfdf8ff
    sw $t4 9788($v1)
    li $t4 0x696976
    sw $t4 9792($v1)
    li $t4 0x19022b
    sw $t4 9796($v1)
    li $t4 0x24203c
    sw $t4 9800($v1)
    li $t4 0xd1d0dd
    sw $t4 9804($v1)
    li $t4 0xcdbfef
    sw $t4 9808($v1)
    li $t4 0x231830
    sw $t4 9812($v1)
    li $t4 0x751552
    sw $t4 9816($v1)
    li $t4 0x763f97
    sw $t4 9820($v1)
    li $t4 0x830740
    sw $t4 9824($v1)
    li $t4 0x3a041d
    sw $t4 9828($v1)
    li $t4 0x5d0026
    sw $t4 9836($v1)
    li $t4 0x6d3527
    sw $t4 9860($v1)
    li $t4 0x8b7e99
    sw $t4 9864($v1)
    li $t4 0xaaaccf
    sw $t4 9868($v1)
    li $t4 0x212591
    sw $t4 9872($v1)
    li $t4 0x44034c
    sw $t4 9876($v1)
    li $t4 0x7b2169
    sw $t4 9880($v1)
    li $t4 0x4843a5
    sw $t4 9884($v1)
    li $t4 0x2a001a
    sw $t4 9888($v1)
    li $t4 0xa6001c
    sw $t4 9892($v1)
    li $t4 0x830021
    sw $t4 9896($v1)
    li $t4 0x840016
    sw $t4 9900($v1)
    li $t4 0x740037
    sw $t4 9904($v1)
    li $t4 0x5c294f
    sw $t4 9908($v1)
    li $t4 0xd28865
    sw $t4 9912($v1)
    li $t4 0x5d2b29
    sw $t4 9916($v1)
    li $t4 0x7c0020
    sw $t4 10272($v1)
    li $t4 0x6b3f97
    sw $t4 10276($v1)
    li $t4 0x802b6f
    sw $t4 10280($v1)
    li $t4 0xac0d0e
    sw $t4 10284($v1)
    li $t4 0xa15aa8
    sw $t4 10288($v1)
    li $t4 0x84429a
    sw $t4 10292($v1)
    li $t4 0x130011
    sw $t4 10296($v1)
    li $t4 0x65578a
    sw $t4 10300($v1)
    li $t4 0x343155
    sw $t4 10304($v1)
    li $t4 0x6d102a
    sw $t4 10308($v1)
    li $t4 0x6b185d
    sw $t4 10312($v1)
    li $t4 0x232348
    sw $t4 10316($v1)
    li $t4 0x342746
    sw $t4 10320($v1)
    li $t4 0x422266
    sw $t4 10324($v1)
    li $t4 0xc8bafa
    sw $t4 10328($v1)
    li $t4 0xb8a7e8
    sw $t4 10332($v1)
    li $t4 0x5a49a7
    sw $t4 10336($v1)
    li $t4 0x601046
    sw $t4 10340($v1)
    li $t4 0x562925
    sw $t4 10372($v1)
    li $t4 0xd7906a
    sw $t4 10376($v1)
    li $t4 0x97274d
    sw $t4 10380($v1)
    li $t4 0x9e0c48
    sw $t4 10384($v1)
    li $t4 0x53003c
    sw $t4 10388($v1)
    li $t4 0x26349a
    sw $t4 10392($v1)
    li $t4 0x9e80d4
    sw $t4 10396($v1)
    li $t4 0x865d9c
    sw $t4 10400($v1)
    li $t4 0xd48ba8
    sw $t4 10404($v1)
    li $t4 0xc88fa7
    sw $t4 10408($v1)
    li $t4 0xb361a2
    sw $t4 10412($v1)
    li $t4 0x891e65
    sw $t4 10416($v1)
    li $t4 0xac1738
    sw $t4 10420($v1)
    li $t4 0xad7565
    sw $t4 10424($v1)
    li $t4 0x5a2d26
    sw $t4 10428($v1)
    li $t4 0x33183c
    sw $t4 10784($v1)
    li $t4 0x7a1862
    sw $t4 10788($v1)
    li $t4 0x6b4daa
    sw $t4 10792($v1)
    li $t4 0x9f64aa
    sw $t4 10796($v1)
    li $t4 0x9b377c
    sw $t4 10800($v1)
    li $t4 0xae8fc5
    sw $t4 10804($v1)
    li $t4 0x8f78cc
    sw $t4 10808($v1)
    li $t4 0x412d56
    sw $t4 10812($v1)
    li $t4 0x25195c
    sw $t4 10816($v1)
    li $t4 0xe6366e
    sw $t4 10820($v1)
    li $t4 0xf92b56
    sw $t4 10824($v1)
    li $t4 0x691451
    sw $t4 10828($v1)
    li $t4 0x3c2567
    sw $t4 10832($v1)
    li $t4 0xceb9fa
    sw $t4 10836($v1)
    li $t4 0xf2f5fe
    sw $t4 10840($v1)
    li $t4 0xf4f5f8
    sw $t4 10844($v1)
    li $t4 0x9b86cb
    sw $t4 10848($v1)
    li $t4 0x070b25
    sw $t4 10852($v1)
    li $t4 0x79032f
    sw $t4 10888($v1)
    li $t4 0x9f0031
    sw $t4 10892($v1)
    li $t4 0x500045
    sw $t4 10896($v1)
    li $t4 0x002192
    sw $t4 10900($v1)
    li $t4 0x0d2f9c
    sw $t4 10904($v1)
    li $t4 0x524aa8
    sw $t4 10908($v1)
    li $t4 0x8368c4
    sw $t4 10912($v1)
    li $t4 0x8882cc
    sw $t4 10916($v1)
    li $t4 0x938cce
    sw $t4 10920($v1)
    li $t4 0x7a6fc9
    sw $t4 10924($v1)
    li $t4 0x3e389b
    sw $t4 10928($v1)
    li $t4 0x5d0042
    sw $t4 10932($v1)
    li $t4 0x8c002a
    sw $t4 10936($v1)
    li $t4 0x62072a
    sw $t4 10940($v1)
    li $t4 0x8f87bd
    sw $t4 11296($v1)
    li $t4 0x9773ae
    sw $t4 11300($v1)
    li $t4 0x48273b
    sw $t4 11304($v1)
    li $t4 0xa497e9
    sw $t4 11308($v1)
    li $t4 0x9d70c5
    sw $t4 11312($v1)
    li $t4 0xedd9f6
    sw $t4 11316($v1)
    li $t4 0xffffff
    sw $t4 11320($v1)
    sw $t4 11860($v1)
    sw $t4 11864($v1)
    li $t4 0xcebbfb
    sw $t4 11324($v1)
    li $t4 0x360952
    sw $t4 11328($v1)
    li $t4 0xcd2344
    sw $t4 11332($v1)
    li $t4 0xc52054
    sw $t4 11336($v1)
    li $t4 0x6e3486
    sw $t4 11340($v1)
    li $t4 0xc4b4f2
    sw $t4 11344($v1)
    li $t4 0xeff1fc
    sw $t4 11348($v1)
    li $t4 0xe4e3f9
    sw $t4 11352($v1)
    li $t4 0xf3f6fe
    sw $t4 11356($v1)
    li $t4 0xddd2fe
    sw $t4 11360($v1)
    li $t4 0x55347e
    sw $t4 11364($v1)
    li $t4 0x870031
    sw $t4 11400($v1)
    li $t4 0x530650
    sw $t4 11404($v1)
    li $t4 0x002390
    sw $t4 11408($v1)
    li $t4 0x0b329f
    sw $t4 11412($v1)
    li $t4 0x223198
    sw $t4 11416($v1)
    li $t4 0x8f71c5
    sw $t4 11420($v1)
    li $t4 0xb39be3
    sw $t4 11424($v1)
    li $t4 0xb59ee0
    sw $t4 11428($v1)
    li $t4 0xefeff7
    sw $t4 11432($v1)
    li $t4 0xc8afe5
    sw $t4 11436($v1)
    li $t4 0x5055b8
    sw $t4 11440($v1)
    li $t4 0x361069
    sw $t4 11444($v1)
    li $t4 0x38000f
    sw $t4 11448($v1)
    li $t4 0x6c002d
    sw $t4 11452($v1)
    li $t4 0x1c112b
    sw $t4 11804($v1)
    li $t4 0x8c65a9
    sw $t4 11808($v1)
    li $t4 0xcdcbf2
    sw $t4 11812($v1)
    li $t4 0xc8c8e4
    sw $t4 11816($v1)
    li $t4 0x584239
    sw $t4 11820($v1)
    li $t4 0x6c5678
    sw $t4 11824($v1)
    li $t4 0xaca2bf
    sw $t4 11828($v1)
    li $t4 0xbcb5bc
    sw $t4 11832($v1)
    li $t4 0x775f95
    sw $t4 11836($v1)
    li $t4 0x33062e
    sw $t4 11840($v1)
    li $t4 0xa11342
    sw $t4 11844($v1)
    li $t4 0x590434
    sw $t4 11848($v1)
    li $t4 0x554196
    sw $t4 11852($v1)
    li $t4 0xe7daff
    sw $t4 11856($v1)
    li $t4 0xeef0ff
    sw $t4 11868($v1)
    li $t4 0xa397bb
    sw $t4 11872($v1)
    li $t4 0x312140
    sw $t4 11876($v1)
    li $t4 0x300114
    sw $t4 11912($v1)
    li $t4 0x070f77
    sw $t4 11916($v1)
    li $t4 0x1137a3
    sw $t4 11920($v1)
    li $t4 0x082b99
    sw $t4 11924($v1)
    li $t4 0x24339a
    sw $t4 11928($v1)
    li $t4 0x9270c7
    sw $t4 11932($v1)
    li $t4 0xe0dafd
    sw $t4 11936($v1)
    li $t4 0xbdace9
    sw $t4 11940($v1)
    li $t4 0xf5f8ff
    sw $t4 11944($v1)
    li $t4 0xfef9ff
    sw $t4 11948($v1)
    li $t4 0x8c7ccf
    sw $t4 11952($v1)
    li $t4 0x001887
    sw $t4 11956($v1)
    li $t4 0x0a081f
    sw $t4 11960($v1)
    li $t4 0x2f0111
    sw $t4 11964($v1)
    li $t4 0xa94f3b
    sw $t4 12320($v1)
    li $t4 0x8a4e73
    sw $t4 12324($v1)
    li $t4 0x9f73ad
    sw $t4 12328($v1)
    li $t4 0xb4afde
    sw $t4 12332($v1)
    li $t4 0x9d95a9
    sw $t4 12336($v1)
    li $t4 0x72655a
    sw $t4 12340($v1)
    li $t4 0x7a6a65
    sw $t4 12344($v1)
    li $t4 0x4a3948
    sw $t4 12348($v1)
    li $t4 0x420a31
    sw $t4 12352($v1)
    li $t4 0xf22351
    sw $t4 12356($v1)
    li $t4 0x69062c
    sw $t4 12360($v1)
    li $t4 0x6b3084
    sw $t4 12364($v1)
    li $t4 0x8a7ea8
    sw $t4 12368($v1)
    li $t4 0x808186
    sw $t4 12372($v1)
    li $t4 0x848486
    sw $t4 12376($v1)
    li $t4 0x7d7f7e
    sw $t4 12380($v1)
    li $t4 0x57575f
    sw $t4 12384($v1)
    li $t4 0x4e3785
    sw $t4 12388($v1)
    li $t4 0x522c7e
    sw $t4 12392($v1)
    li $t4 0x0d0e73
    sw $t4 12428($v1)
    li $t4 0x1033a0
    sw $t4 12432($v1)
    li $t4 0x082d9b
    sw $t4 12436($v1)
    li $t4 0x1c2894
    sw $t4 12440($v1)
    li $t4 0xaf93cd
    sw $t4 12444($v1)
    li $t4 0xfcfdff
    sw $t4 12448($v1)
    li $t4 0xe8e8fc
    sw $t4 12452($v1)
    li $t4 0xf6faff
    sw $t4 12456($v1)
    li $t4 0xffe7f9
    sw $t4 12460($v1)
    li $t4 0x7490ea
    sw $t4 12464($v1)
    li $t4 0x0350c2
    sw $t4 12468($v1)
    li $t4 0x804738
    sw $t4 12828($v1)
    li $t4 0xd27961
    sw $t4 12832($v1)
    li $t4 0xd97a53
    sw $t4 12836($v1)
    li $t4 0xe18859
    sw $t4 12840($v1)
    li $t4 0x9a5262
    sw $t4 12844($v1)
    li $t4 0x936ba0
    sw $t4 12848($v1)
    li $t4 0xa296d1
    sw $t4 12852($v1)
    li $t4 0x9a89ce
    sw $t4 12856($v1)
    li $t4 0x704ea2
    sw $t4 12860($v1)
    li $t4 0x7c2647
    sw $t4 12864($v1)
    li $t4 0xa92e40
    sw $t4 12868($v1)
    li $t4 0x730a2b
    sw $t4 12872($v1)
    li $t4 0xc7225b
    sw $t4 12876($v1)
    li $t4 0x382a6e
    sw $t4 12880($v1)
    li $t4 0x7a7786
    sw $t4 12884($v1)
    li $t4 0x7f8387
    sw $t4 12888($v1)
    li $t4 0x635892
    sw $t4 12892($v1)
    li $t4 0xa683b2
    sw $t4 12896($v1)
    li $t4 0x7e476d
    sw $t4 12900($v1)
    li $t4 0x231332
    sw $t4 12904($v1)
    li $t4 0x0c0e75
    sw $t4 12940($v1)
    li $t4 0x1037a3
    sw $t4 12944($v1)
    li $t4 0x102c97
    sw $t4 12948($v1)
    li $t4 0x0939a7
    sw $t4 12952($v1)
    li $t4 0x293da5
    sw $t4 12956($v1)
    li $t4 0xc1a2cd
    sw $t4 12960($v1)
    li $t4 0xf0daf4
    sw $t4 12964($v1)
    li $t4 0xf5d6f2
    sw $t4 12968($v1)
    li $t4 0x8b9beb
    sw $t4 12972($v1)
    li $t4 0x0091fd
    sw $t4 12976($v1)
    li $t4 0x095ccb
    sw $t4 12980($v1)
    li $t4 0xa55a47
    sw $t4 13340($v1)
    li $t4 0xfcb176
    sw $t4 13344($v1)
    li $t4 0xf7cb9c
    sw $t4 13348($v1)
    li $t4 0xfcd6a4
    sw $t4 13352($v1)
    li $t4 0xe17f59
    sw $t4 13356($v1)
    li $t4 0x8b3b3b
    sw $t4 13360($v1)
    li $t4 0x7d3243
    sw $t4 13364($v1)
    li $t4 0x9e4b52
    sw $t4 13368($v1)
    li $t4 0x8e4745
    sw $t4 13372($v1)
    li $t4 0x94493a
    sw $t4 13376($v1)
    li $t4 0x7e3f38
    sw $t4 13380($v1)
    li $t4 0x540524
    sw $t4 13384($v1)
    li $t4 0x651044
    sw $t4 13388($v1)
    li $t4 0x5e3d93
    sw $t4 13392($v1)
    li $t4 0x8667af
    sw $t4 13396($v1)
    li $t4 0x8b6ca8
    sw $t4 13400($v1)
    li $t4 0x955166
    sw $t4 13404($v1)
    li $t4 0x9f4843
    sw $t4 13408($v1)
    li $t4 0x8c3c2d
    sw $t4 13412($v1)
    li $t4 0x230e01
    sw $t4 13416($v1)
    li $t4 0x070643
    sw $t4 13452($v1)
    li $t4 0x0f248e
    sw $t4 13456($v1)
    li $t4 0x102a97
    sw $t4 13460($v1)
    li $t4 0x0954c3
    sw $t4 13464($v1)
    li $t4 0x0084f4
    sw $t4 13468($v1)
    li $t4 0x1a61d1
    sw $t4 13472($v1)
    li $t4 0x448af4
    sw $t4 13476($v1)
    li $t4 0x4a89f2
    sw $t4 13480($v1)
    li $t4 0x018dff
    sw $t4 13484($v1)
    li $t4 0x009eff
    sw $t4 13488($v1)
    li $t4 0x0848b4
    sw $t4 13492($v1)
    li $t4 0x8f4738
    sw $t4 13852($v1)
    li $t4 0xefbd8b
    sw $t4 13856($v1)
    li $t4 0xf7e3af
    sw $t4 13860($v1)
    li $t4 0xfaecbb
    sw $t4 13864($v1)
    li $t4 0xf2c69c
    sw $t4 13868($v1)
    li $t4 0xfbc490
    sw $t4 13872($v1)
    li $t4 0xffe8b2
    sw $t4 13876($v1)
    li $t4 0xffdfa9
    sw $t4 13880($v1)
    li $t4 0xfbdda7
    sw $t4 13884($v1)
    li $t4 0xbe8970
    sw $t4 13888($v1)
    li $t4 0xbb5d49
    sw $t4 13892($v1)
    li $t4 0xa95d5b
    sw $t4 13896($v1)
    li $t4 0x2a2f83
    sw $t4 13900($v1)
    li $t4 0x562c81
    sw $t4 13904($v1)
    li $t4 0x280e23
    sw $t4 13908($v1)
    li $t4 0x1f0300
    sw $t4 13912($v1)
    li $t4 0x873930
    sw $t4 13916($v1)
    li $t4 0xce6f5a
    sw $t4 13920($v1)
    li $t4 0xbf6558
    sw $t4 13924($v1)
    li $t4 0x3c1d14
    sw $t4 13928($v1)
    li $t4 0x0b0861
    sw $t4 13972($v1)
    li $t4 0x0d0e6d
    sw $t4 13976($v1)
    li $t4 0x123aa3
    sw $t4 13980($v1)
    li $t4 0x0c51c2
    sw $t4 13984($v1)
    li $t4 0x0040ab
    sw $t4 13988($v1)
    li $t4 0x0042ad
    sw $t4 13992($v1)
    li $t4 0x0b3ea7
    sw $t4 13996($v1)
    li $t4 0x091f7e
    sw $t4 14000($v1)
    li $t4 0x04093f
    sw $t4 14004($v1)
    li $t4 0x7a3232
    sw $t4 14368($v1)
    li $t4 0xc26d52
    sw $t4 14372($v1)
    li $t4 0xe9b28a
    sw $t4 14376($v1)
    li $t4 0xfce2ab
    sw $t4 14380($v1)
    li $t4 0xfde5b5
    sw $t4 14384($v1)
    li $t4 0xfce8b8
    sw $t4 14388($v1)
    li $t4 0xffeab5
    sw $t4 14392($v1)
    li $t4 0xe59974
    sw $t4 14396($v1)
    li $t4 0xcc6a53
    sw $t4 14400($v1)
    li $t4 0xe9a672
    sw $t4 14404($v1)
    li $t4 0xdc825a
    sw $t4 14408($v1)
    li $t4 0xaf626c
    sw $t4 14412($v1)
    li $t4 0x715ccc
    sw $t4 14416($v1)
    li $t4 0x3b2534
    sw $t4 14420($v1)
    li $t4 0x2b1100
    sw $t4 14424($v1)
    li $t4 0x974541
    sw $t4 14428($v1)
    li $t4 0xf3ad7e
    sw $t4 14432($v1)
    li $t4 0xe9946d
    sw $t4 14436($v1)
    li $t4 0x34170b
    sw $t4 14440($v1)
    li $t4 0x6f55a7
    sw $t4 14484($v1)
    li $t4 0x4a367c
    sw $t4 14488($v1)
    li $t4 0x271434
    sw $t4 14492($v1)
    li $t4 0x6948a1
    sw $t4 14496($v1)
    sw $0 14500($v1)
    li $t4 0x280b10
    sw $t4 14884($v1)
    li $t4 0x501f1a
    sw $t4 14888($v1)
    li $t4 0xca8a68
    sw $t4 14892($v1)
    li $t4 0xfefdc8
    sw $t4 14896($v1)
    li $t4 0xfecc98
    sw $t4 14900($v1)
    li $t4 0xfedfad
    sw $t4 14904($v1)
    li $t4 0xf9ce9c
    sw $t4 14908($v1)
    li $t4 0xc58871
    sw $t4 14912($v1)
    li $t4 0xd0384a
    sw $t4 14916($v1)
    li $t4 0xe77b5a
    sw $t4 14920($v1)
    li $t4 0xd4918b
    sw $t4 14924($v1)
    li $t4 0xa89ced
    sw $t4 14928($v1)
    li $t4 0x31172d
    sw $t4 14932($v1)
    li $t4 0x241000
    sw $t4 14936($v1)
    sw $t4 16984($v1)
    li $t4 0x733529
    sw $t4 14940($v1)
    li $t4 0xf4c195
    sw $t4 14944($v1)
    li $t4 0xffe3ac
    sw $t4 14948($v1)
    li $t4 0x633126
    sw $t4 14952($v1)
    li $t4 0x563f51
    sw $t4 14996($v1)
    li $t4 0x302341
    sw $t4 15000($v1)
    li $t4 0x3e273a
    sw $t4 15008($v1)
    li $t4 0x100803
    sw $t4 15012($v1)
    li $t4 0x2c1116
    sw $t4 15404($v1)
    li $t4 0xcf9370
    sw $t4 15408($v1)
    li $t4 0xde8866
    sw $t4 15412($v1)
    li $t4 0xfaac7a
    sw $t4 15416($v1)
    li $t4 0xec9b70
    sw $t4 15420($v1)
    li $t4 0xe49c75
    sw $t4 15424($v1)
    li $t4 0xee6f59
    sw $t4 15428($v1)
    li $t4 0x580a1c
    sw $t4 15432($v1)
    li $t4 0x816d5d
    sw $t4 15436($v1)
    li $t4 0xc4baf9
    sw $t4 15440($v1)
    li $t4 0x2c112b
    sw $t4 15444($v1)
    sw $t4 15956($v1)
    sw $t4 16468($v1)
    li $t4 0x231200
    sw $t4 15448($v1)
    li $t4 0x441a12
    sw $t4 15452($v1)
    li $t4 0xe5a084
    sw $t4 15456($v1)
    li $t4 0xfef3be
    sw $t4 15460($v1)
    li $t4 0xae6256
    sw $t4 15464($v1)
    li $t4 0x240f00
    sw $t4 15520($v1)
    li $t4 0x231007
    sw $t4 15524($v1)
    li $t4 0xb96445
    sw $t4 15920($v1)
    li $t4 0xdb7f5b
    sw $t4 15924($v1)
    li $t4 0xe78a5c
    sw $t4 15928($v1)
    li $t4 0xcb694f
    sw $t4 15932($v1)
    li $t4 0xb15449
    sw $t4 15936($v1)
    li $t4 0xa77071
    sw $t4 15940($v1)
    li $t4 0x0e1e70
    sw $t4 15944($v1)
    li $t4 0x62574b
    sw $t4 15948($v1)
    li $t4 0xc4b7fa
    sw $t4 15952($v1)
    li $t4 0x281600
    sw $t4 15960($v1)
    li $t4 0x380f0b
    sw $t4 15964($v1)
    li $t4 0xbf8972
    sw $t4 15968($v1)
    li $t4 0xfffac3
    sw $t4 15972($v1)
    li $t4 0xc2735d
    sw $t4 15976($v1)
    li $t4 0x541f20
    sw $t4 15980($v1)
    li $t4 0x4e1e3d
    sw $t4 16432($v1)
    li $t4 0x743a55
    sw $t4 16436($v1)
    li $t4 0x60385b
    sw $t4 16440($v1)
    li $t4 0x794257
    sw $t4 16444($v1)
    li $t4 0x250951
    sw $t4 16448($v1)
    li $t4 0x0063e4
    sw $t4 16452($v1)
    li $t4 0x012f90
    sw $t4 16456($v1)
    li $t4 0x6e5848
    sw $t4 16460($v1)
    li $t4 0xc3b9fa
    sw $t4 16464($v1)
    sw $t4 16976($v1)
    li $t4 0x261500
    sw $t4 16472($v1)
    li $t4 0x350f0a
    sw $t4 16476($v1)
    li $t4 0xc88e77
    sw $t4 16480($v1)
    li $t4 0xfffac2
    sw $t4 16484($v1)
    li $t4 0xeea171
    sw $t4 16488($v1)
    sw $t4 17000($v1)
    li $t4 0x5d2424
    sw $t4 16492($v1)
    li $t4 0x030044
    sw $t4 16940($v1)
    li $t4 0x040069
    sw $t4 16944($v1)
    li $t4 0x0053cd
    sw $t4 16948($v1)
    li $t4 0x02188b
    sw $t4 16952($v1)
    li $t4 0x0037b1
    sw $t4 16956($v1)
    li $t4 0x0136a8
    sw $t4 16960($v1)
    li $t4 0x085ccc
    sw $t4 16964($v1)
    li $t4 0x003ea4
    sw $t4 16968($v1)
    li $t4 0x6d5948
    sw $t4 16972($v1)
    li $t4 0x2b112b
    sw $t4 16980($v1)
    li $t4 0x773429
    sw $t4 16988($v1)
    li $t4 0xf8bd8e
    sw $t4 16992($v1)
    li $t4 0xfef1be
    sw $t4 16996($v1)
    li $t4 0x5b2323
    sw $t4 17004($v1)
    li $t4 0x070048
    sw $t4 17448($v1)
    li $t4 0x0e0163
    sw $t4 17452($v1)
    li $t4 0x0c5ac7
    sw $t4 17456($v1)
    li $t4 0x0b64d3
    sw $t4 17460($v1)
    li $t4 0x11005a
    sw $t4 17464($v1)
    li $t4 0x0f61cf
    sw $t4 17468($v1)
    li $t4 0x0644ae
    sw $t4 17472($v1)
    li $t4 0x065acc
    sw $t4 17476($v1)
    li $t4 0x004bb4
    sw $t4 17480($v1)
    li $t4 0x6c5848
    sw $t4 17484($v1)
    li $t4 0xc3b8fa
    sw $t4 17488($v1)
    li $t4 0x230d26
    sw $t4 17492($v1)
    li $t4 0x2b0e00
    sw $t4 17496($v1)
    li $t4 0xce816a
    sw $t4 17500($v1)
    li $t4 0xffeab3
    sw $t4 17504($v1)
    li $t4 0xfee8b7
    sw $t4 17508($v1)
    li $t4 0xf0a473
    sw $t4 17512($v1)
    li $t4 0x592222
    sw $t4 17516($v1)
    li $t4 0x070047
    sw $t4 17956($v1)
    li $t4 0x0e0264
    sw $t4 17960($v1)
    li $t4 0x0955c2
    sw $t4 17964($v1)
    li $t4 0x066bde
    sw $t4 17968($v1)
    li $t4 0x0e0369
    sw $t4 17972($v1)
    sw $t4 23608($v1)
    li $t4 0x0e2791
    sw $t4 17976($v1)
    li $t4 0x0a5ccd
    sw $t4 17980($v1)
    li $t4 0x053ea9
    sw $t4 17984($v1)
    li $t4 0x0659cb
    sw $t4 17988($v1)
    li $t4 0x004fb9
    sw $t4 17992($v1)
    li $t4 0x6f5b49
    sw $t4 17996($v1)
    li $t4 0xc3bbf9
    sw $t4 18000($v1)
    li $t4 0x33132d
    sw $t4 18004($v1)
    li $t4 0xba6e4c
    sw $t4 18008($v1)
    li $t4 0xf2d3aa
    sw $t4 18012($v1)
    li $t4 0xfce1af
    sw $t4 18016($v1)
    li $t4 0xfee9b6
    sw $t4 18020($v1)
    li $t4 0xe99e72
    sw $t4 18024($v1)
    li $t4 0x612525
    sw $t4 18028($v1)
    li $t4 0x08003f
    sw $t4 18464($v1)
    li $t4 0x0e0263
    sw $t4 18468($v1)
    li $t4 0x0a57c3
    sw $t4 18472($v1)
    li $t4 0x0184f9
    sw $t4 18476($v1)
    li $t4 0x0b2a97
    sw $t4 18480($v1)
    li $t4 0x0e1178
    sw $t4 18484($v1)
    li $t4 0x0470e1
    sw $t4 18488($v1)
    li $t4 0x0b57c6
    sw $t4 18492($v1)
    li $t4 0x064ab7
    sw $t4 18496($v1)
    li $t4 0x065fd3
    sw $t4 18500($v1)
    li $t4 0x007de4
    sw $t4 18504($v1)
    li $t4 0x6a5249
    sw $t4 18508($v1)
    li $t4 0xaca3ed
    sw $t4 18512($v1)
    li $t4 0x8d445d
    sw $t4 18516($v1)
    li $t4 0xd47950
    sw $t4 18520($v1)
    li $t4 0xdca17f
    sw $t4 18524($v1)
    li $t4 0xfbcb9b
    sw $t4 18528($v1)
    li $t4 0xffc18e
    sw $t4 18532($v1)
    li $t4 0xb26759
    sw $t4 18536($v1)
    li $t4 0x3d1617
    sw $t4 18540($v1)
    li $t4 0x0a044b
    sw $t4 18972($v1)
    li $t4 0x0a1c84
    sw $t4 18976($v1)
    li $t4 0x0755c4
    sw $t4 18980($v1)
    li $t4 0x0092ff
    draw4($t4, 18984, 20532, 21576, 23128)
    li $t4 0x0562d6
    sw $t4 18988($v1)
    li $t4 0x10076b
    sw $t4 18992($v1)
    li $t4 0x072996
    sw $t4 18996($v1)
    li $t4 0x037bef
    sw $t4 19000($v1)
    li $t4 0x055fd1
    sw $t4 19004($v1)
    li $t4 0x095fcf
    sw $t4 19008($v1)
    li $t4 0x076de3
    sw $t4 19012($v1)
    li $t4 0x0081e2
    sw $t4 19016($v1)
    li $t4 0x472835
    sw $t4 19020($v1)
    li $t4 0x856be3
    sw $t4 19024($v1)
    li $t4 0x48243e
    sw $t4 19028($v1)
    li $t4 0x9a4937
    sw $t4 19032($v1)
    li $t4 0xffbb80
    sw $t4 19036($v1)
    li $t4 0xa66351
    sw $t4 19040($v1)
    li $t4 0xb75b3f
    sw $t4 19044($v1)
    li $t4 0x5b2b1f
    sw $t4 19048($v1)
    li $t4 0x0a024c
    sw $t4 19480($v1)
    li $t4 0x0c2794
    sw $t4 19484($v1)
    li $t4 0x026cdf
    sw $t4 19488($v1)
    li $t4 0x0095ff
    draw4($t4, 19492, 21552, 21588, 25160)
    li $t4 0x0284f8
    sw $t4 19496($v1)
    li $t4 0x0b248f
    sw $t4 19500($v1)
    li $t4 0x0f0b72
    sw $t4 19504($v1)
    li $t4 0x036adc
    sw $t4 19508($v1)
    li $t4 0x0082f7
    sw $t4 19512($v1)
    li $t4 0x0069df
    sw $t4 19516($v1)
    li $t4 0x095ac9
    sw $t4 19520($v1)
    sw $t4 20032($v1)
    li $t4 0x056adf
    sw $t4 19524($v1)
    li $t4 0x0287ee
    sw $t4 19528($v1)
    li $t4 0x2f1106
    sw $t4 19532($v1)
    li $t4 0x3b2334
    sw $t4 19536($v1)
    li $t4 0x27140c
    sw $t4 19540($v1)
    li $t4 0x904634
    sw $t4 19544($v1)
    li $t4 0x803a43
    sw $t4 19548($v1)
    li $t4 0x14004f
    sw $t4 19552($v1)
    li $t4 0x210954
    sw $t4 19556($v1)
    li $t4 0x0a024b
    sw $t4 19988($v1)
    li $t4 0x0c2894
    sw $t4 19992($v1)
    li $t4 0x0068da
    sw $t4 19996($v1)
    li $t4 0x008ffe
    sw $t4 20000($v1)
    li $t4 0x008cfd
    sw $t4 20004($v1)
    li $t4 0x017ff3
    sw $t4 20008($v1)
    li $t4 0x11137a
    sw $t4 20012($v1)
    li $t4 0x072591
    sw $t4 20016($v1)
    li $t4 0x018aff
    sw $t4 20020($v1)
    li $t4 0x0181f5
    sw $t4 20024($v1)
    li $t4 0x006de0
    sw $t4 20028($v1)
    li $t4 0x0669db
    sw $t4 20036($v1)
    li $t4 0x008dfe
    sw $t4 20040($v1)
    li $t4 0x10207e
    sw $t4 20044($v1)
    li $t4 0x0c0354
    sw $t4 20048($v1)
    li $t4 0x0f0760
    sw $t4 20052($v1)
    li $t4 0x0e005c
    sw $t4 20056($v1)
    li $t4 0x0a066a
    sw $t4 20060($v1)
    li $t4 0x06046f
    sw $t4 20064($v1)
    li $t4 0x070068
    sw $t4 20068($v1)
    li $t4 0x090447
    sw $t4 20496($v1)
    li $t4 0x0c2994
    sw $t4 20500($v1)
    li $t4 0x0068db
    sw $t4 20504($v1)
    li $t4 0x0090ff
    sw $t4 20508($v1)
    sw $t4 21584($v1)
    sw $t4 22048($v1)
    li $t4 0x008bff
    draw16($t4, 20512, 21020, 21024, 21532, 22548, 22552, 22608, 23060, 23064, 23120, 23124, 23632, 23636, 24144, 24148, 24656)
    draw4($t4, 24660, 25168, 25172, 25176)
    sw $t4 25680($v1)
    sw $t4 25684($v1)
    sw $t4 25692($v1)
    li $t4 0x008fff
    draw4($t4, 20516, 21016, 22616, 26196)
    li $t4 0x0542b3
    sw $t4 20520($v1)
    li $t4 0x0c0065
    sw $t4 20524($v1)
    li $t4 0x0569dd
    sw $t4 20528($v1)
    li $t4 0x0187fa
    sw $t4 20536($v1)
    li $t4 0x0098ff
    sw $t4 20540($v1)
    sw $t4 23584($v1)
    li $t4 0x0955c4
    draw4($t4, 20544, 21056, 21568, 22080)
    li $t4 0x0669da
    sw $t4 20548($v1)
    li $t4 0x0093ff
    draw4($t4, 20552, 22032, 22088, 22560)
    sw $t4 22600($v1)
    sw $t4 23072($v1)
    sw $t4 23112($v1)
    li $t4 0x0354cb
    sw $t4 20556($v1)
    li $t4 0x0c32a4
    sw $t4 20560($v1)
    li $t4 0x0b35a8
    sw $t4 20564($v1)
    li $t4 0x091782
    sw $t4 20568($v1)
    li $t4 0x034fc4
    sw $t4 20572($v1)
    li $t4 0x11157b
    sw $t4 20576($v1)
    li $t4 0x0b005d
    sw $t4 20580($v1)
    li $t4 0x0c0161
    sw $t4 20584($v1)
    li $t4 0x09064b
    sw $t4 21004($v1)
    li $t4 0x0d2894
    sw $t4 21008($v1)
    li $t4 0x0169db
    sw $t4 21012($v1)
    li $t4 0x008eff
    draw4($t4, 21028, 21524, 24668, 26192)
    li $t4 0x0f1880
    sw $t4 21032($v1)
    li $t4 0x0a2c97
    sw $t4 21036($v1)
    li $t4 0x0086f7
    sw $t4 21040($v1)
    li $t4 0x008bfe
    sw $t4 21044($v1)
    li $t4 0x0088fc
    sw $t4 21048($v1)
    sw $t4 26188($v1)
    sw $t4 26200($v1)
    li $t4 0x0096ff
    draw4($t4, 21052, 21064, 21564, 22076)
    sw $t4 24136($v1)
    sw $t4 25184($v1)
    sw $t4 25696($v1)
    li $t4 0x0668d9
    sw $t4 21060($v1)
    sw $t4 21572($v1)
    sw $t4 22084($v1)
    li $t4 0x0086fa
    sw $t4 21068($v1)
    li $t4 0x006ee2
    sw $t4 21072($v1)
    li $t4 0x0074e6
    sw $t4 21076($v1)
    li $t4 0x0844b5
    sw $t4 21080($v1)
    li $t4 0x0945b5
    sw $t4 21084($v1)
    li $t4 0x0b2b98
    sw $t4 21088($v1)
    li $t4 0x0d0264
    sw $t4 21092($v1)
    li $t4 0x09005b
    sw $t4 21096($v1)
    li $t4 0x0a0e77
    sw $t4 21516($v1)
    li $t4 0x016de0
    sw $t4 21520($v1)
    li $t4 0x008bfd
    sw $t4 21528($v1)
    li $t4 0x008cff
    draw4($t4, 21536, 22068, 22612, 23572)
    sw $t4 23576($v1)
    sw $t4 23656($v1)
    li $t4 0x008dff
    draw4($t4, 21540, 23568, 23640, 25688)
    li $t4 0x090b72
    sw $t4 21544($v1)
    li $t4 0x045ed1
    sw $t4 21548($v1)
    li $t4 0x0089fd
    draw4($t4, 21556, 21560, 22096, 22556)
    draw4($t4, 23068, 23580, 23628, 24140)
    draw4($t4, 24152, 24652, 25164, 25676)
    li $t4 0x008afe
    draw4($t4, 21580, 22044, 22092, 22544)
    draw4($t4, 22604, 23056, 23116, 24664)
    li $t4 0x0171e4
    sw $t4 21592($v1)
    li $t4 0x0a137d
    sw $t4 21596($v1)
    li $t4 0x0177ee
    sw $t4 21600($v1)
    li $t4 0x0a258d
    sw $t4 21604($v1)
    li $t4 0x0b0057
    sw $t4 21608($v1)
    li $t4 0x060237
    sw $t4 21612($v1)
    li $t4 0x0a0056
    sw $t4 22024($v1)
    li $t4 0x0950bc
    sw $t4 22028($v1)
    li $t4 0x008afd
    sw $t4 22036($v1)
    li $t4 0x008aff
    sw $t4 22040($v1)
    li $t4 0x015cd0
    sw $t4 22052($v1)
    li $t4 0x09157c
    sw $t4 22056($v1)
    li $t4 0x008bfc
    sw $t4 22060($v1)
    li $t4 0x0083f8
    sw $t4 22064($v1)
    li $t4 0x0088fb
    sw $t4 22072($v1)
    li $t4 0x008efe
    sw $t4 22100($v1)
    sw $t4 23564($v1)
    li $t4 0x0082f4
    sw $t4 22104($v1)
    li $t4 0x0c0166
    sw $t4 22108($v1)
    li $t4 0x0566d8
    sw $t4 22112($v1)
    li $t4 0x075aca
    sw $t4 22116($v1)
    li $t4 0x0c015f
    sw $t4 22120($v1)
    li $t4 0x0b0064
    draw4($t4, 22124, 23152, 25724, 26236)
    li $t4 0x05002f
    sw $t4 22128($v1)
    li $t4 0x0b1f84
    sw $t4 22536($v1)
    li $t4 0x0092fe
    sw $t4 22540($v1)
    li $t4 0x0d3fad
    sw $t4 22564($v1)
    li $t4 0x0b1279
    sw $t4 22568($v1)
    li $t4 0x0379ee
    sw $t4 22572($v1)
    li $t4 0x0840b1
    sw $t4 22576($v1)
    li $t4 0x0375ea
    sw $t4 22580($v1)
    li $t4 0x0091ff
    sw $t4 22584($v1)
    sw $t4 24156($v1)
    li $t4 0x0094fe
    sw $t4 22588($v1)
    li $t4 0x0955c3
    sw $t4 22592($v1)
    li $t4 0x0668d8
    sw $t4 22596($v1)
    li $t4 0x0341b0
    sw $t4 22620($v1)
    li $t4 0x0a0e76
    sw $t4 22624($v1)
    li $t4 0x028dff
    sw $t4 22628($v1)
    li $t4 0x0c1a80
    sw $t4 22632($v1)
    li $t4 0x0b015e
    sw $t4 22636($v1)
    li $t4 0x080145
    sw $t4 22640($v1)
    li $t4 0x09004b
    sw $t4 23044($v1)
    li $t4 0x0741b0
    sw $t4 23048($v1)
    li $t4 0x0091fc
    sw $t4 23052($v1)
    li $t4 0x0d4ab9
    sw $t4 23076($v1)
    li $t4 0x0a0469
    sw $t4 23080($v1)
    li $t4 0x001984
    sw $t4 23084($v1)
    li $t4 0x080c73
    sw $t4 23088($v1)
    li $t4 0x001881
    sw $t4 23092($v1)
    li $t4 0x0661d2
    sw $t4 23096($v1)
    li $t4 0x009fff
    sw $t4 23100($v1)
    li $t4 0x0a57c6
    sw $t4 23104($v1)
    li $t4 0x066adb
    sw $t4 23108($v1)
    li $t4 0x0371e3
    sw $t4 23132($v1)
    li $t4 0x120267
    sw $t4 23136($v1)
    li $t4 0x035acb
    sw $t4 23140($v1)
    li $t4 0x0661d3
    sw $t4 23144($v1)
    li $t4 0x0c0057
    sw $t4 23148($v1)
    li $t4 0x03001f
    sw $t4 23156($v1)
    li $t4 0x080042
    sw $t4 23552($v1)
    li $t4 0x0e1c7c
    sw $t4 23556($v1)
    li $t4 0x007df1
    sw $t4 23560($v1)
    li $t4 0x072d97
    sw $t4 23588($v1)
    li $t4 0x120061
    sw $t4 23592($v1)
    li $t4 0x4d308c
    sw $t4 23596($v1)
    li $t4 0x4b338f
    sw $t4 23600($v1)
    li $t4 0x4b2e89
    sw $t4 23604($v1)
    li $t4 0x046edc
    sw $t4 23612($v1)
    li $t4 0x0649b6
    sw $t4 23616($v1)
    li $t4 0x0559c8
    sw $t4 23620($v1)
    li $t4 0x0097ff
    sw $t4 23624($v1)
    li $t4 0x0181f6
    sw $t4 23644($v1)
    li $t4 0x081982
    sw $t4 23648($v1)
    li $t4 0x0c1a82
    sw $t4 23652($v1)
    li $t4 0x042b96
    sw $t4 23660($v1)
    li $t4 0x0c005c
    sw $t4 23664($v1)
    li $t4 0x090151
    sw $t4 23668($v1)
    li $t4 0x0c0160
    sw $t4 24064($v1)
    li $t4 0x0c208b
    sw $t4 24068($v1)
    li $t4 0x0160d3
    sw $t4 24072($v1)
    li $t4 0x048afc
    sw $t4 24076($v1)
    li $t4 0x0487fb
    sw $t4 24080($v1)
    li $t4 0x028cff
    sw $t4 24084($v1)
    li $t4 0x018cff
    sw $t4 24088($v1)
    sw $t4 26700($v1)
    li $t4 0x0190ff
    sw $t4 24092($v1)
    li $t4 0x0378eb
    sw $t4 24096($v1)
    li $t4 0x030771
    sw $t4 24100($v1)
    li $t4 0x2d1f74
    sw $t4 24104($v1)
    li $t4 0xdfd7fc
    sw $t4 24108($v1)
    li $t4 0x7759b8
    sw $t4 24112($v1)
    li $t4 0xc5bde8
    sw $t4 24116($v1)
    li $t4 0x7057a5
    sw $t4 24120($v1)
    li $t4 0x0c1580
    sw $t4 24124($v1)
    li $t4 0x0f1379
    sw $t4 24128($v1)
    li $t4 0x035ccb
    sw $t4 24132($v1)
    li $t4 0x065fd1
    sw $t4 24160($v1)
    li $t4 0x0f0065
    sw $t4 24164($v1)
    li $t4 0x0254c6
    sw $t4 24168($v1)
    li $t4 0x026add
    sw $t4 24172($v1)
    li $t4 0x0d0055
    sw $t4 24176($v1)
    li $t4 0x0b0266
    sw $t4 24180($v1)
    li $t4 0x01003e
    sw $t4 24576($v1)
    li $t4 0x15045b
    sw $t4 24580($v1)
    li $t4 0x16218d
    sw $t4 24584($v1)
    li $t4 0x092087
    sw $t4 24588($v1)
    li $t4 0x091b85
    sw $t4 24592($v1)
    li $t4 0x00309e
    sw $t4 24596($v1)
    li $t4 0x0036a5
    sw $t4 24600($v1)
    li $t4 0x0035a5
    sw $t4 24604($v1)
    li $t4 0x042a97
    sw $t4 24608($v1)
    li $t4 0x020065
    sw $t4 24612($v1)
    li $t4 0x573383
    sw $t4 24616($v1)
    li $t4 0x8e6fc9
    sw $t4 24620($v1)
    li $t4 0x593b9c
    sw $t4 24624($v1)
    li $t4 0x8c6ec6
    sw $t4 24628($v1)
    li $t4 0xf1eeff
    sw $t4 24632($v1)
    li $t4 0x473390
    sw $t4 24636($v1)
    li $t4 0x00004a
    sw $t4 24640($v1)
    li $t4 0x0667d7
    sw $t4 24644($v1)
    li $t4 0x0094ff
    sw $t4 24648($v1)
    li $t4 0x0081f4
    sw $t4 24672($v1)
    li $t4 0x081e87
    sw $t4 24676($v1)
    li $t4 0x0d238c
    sw $t4 24680($v1)
    li $t4 0x028cfb
    sw $t4 24684($v1)
    li $t4 0x0d228b
    sw $t4 24688($v1)
    li $t4 0x0a005c
    sw $t4 24692($v1)
    li $t4 0x0a0261
    sw $t4 24696($v1)
    li $t4 0x23112e
    sw $t4 25088($v1)
    li $t4 0x5a3b7f
    sw $t4 25092($v1)
    li $t4 0x9d8ac4
    sw $t4 25096($v1)
    li $t4 0x230d73
    sw $t4 25100($v1)
    li $t4 0x2f197a
    sw $t4 25104($v1)
    li $t4 0x2c1174
    sw $t4 25108($v1)
    li $t4 0x2e1175
    sw $t4 25112($v1)
    li $t4 0x341879
    sw $t4 25116($v1)
    li $t4 0x2d1477
    sw $t4 25120($v1)
    li $t4 0x2e1873
    sw $t4 25124($v1)
    li $t4 0x48246e
    sw $t4 25128($v1)
    li $t4 0x371638
    sw $t4 25132($v1)
    li $t4 0x3c1c3e
    sw $t4 25136($v1)
    li $t4 0x351537
    sw $t4 25140($v1)
    li $t4 0x9680ba
    sw $t4 25144($v1)
    li $t4 0x614ca9
    sw $t4 25148($v1)
    li $t4 0x1e0c61
    sw $t4 25152($v1)
    li $t4 0x0361d1
    sw $t4 25156($v1)
    li $t4 0x0088fd
    sw $t4 25180($v1)
    li $t4 0x0b53c2
    sw $t4 25188($v1)
    li $t4 0x0d0061
    sw $t4 25192($v1)
    li $t4 0x057ae3
    sw $t4 25196($v1)
    li $t4 0x0455c3
    sw $t4 25200($v1)
    li $t4 0x0c0053
    sw $t4 25204($v1)
    li $t4 0x0b0365
    sw $t4 25208($v1)
    li $t4 0x050030
    sw $t4 25212($v1)
    li $t4 0x4b2573
    sw $t4 25600($v1)
    li $t4 0x62469f
    sw $t4 25604($v1)
    li $t4 0xc7baf2
    sw $t4 25608($v1)
    li $t4 0xdad6f0
    sw $t4 25612($v1)
    li $t4 0xb39fe2
    sw $t4 25616($v1)
    li $t4 0xc7bbec
    sw $t4 25620($v1)
    li $t4 0xbfb5e4
    sw $t4 25624($v1)
    li $t4 0x8e7bc2
    sw $t4 25628($v1)
    li $t4 0xcabbf3
    sw $t4 25632($v1)
    li $t4 0x643b92
    sw $t4 25636($v1)
    li $t4 0x482363
    sw $t4 25640($v1)
    li $t4 0x281300
    sw $t4 25644($v1)
    sw $t4 25648($v1)
    sw $t4 25652($v1)
    li $t4 0x280923
    sw $t4 25656($v1)
    li $t4 0x6b4ba5
    sw $t4 25660($v1)
    li $t4 0x411f7e
    sw $t4 25664($v1)
    li $t4 0x005acb
    sw $t4 25668($v1)
    li $t4 0x0196ff
    sw $t4 25672($v1)
    li $t4 0x0b4ebd
    sw $t4 25700($v1)
    li $t4 0x0e005e
    sw $t4 25704($v1)
    li $t4 0x0c50c0
    sw $t4 25708($v1)
    li $t4 0x0257c5
    sw $t4 25712($v1)
    li $t4 0x0b0052
    sw $t4 25716($v1)
    li $t4 0x0b0368
    sw $t4 25720($v1)
    li $t4 0x47256b
    sw $t4 26112($v1)
    li $t4 0x4b2971
    sw $t4 26116($v1)
    li $t4 0x583c98
    sw $t4 26120($v1)
    li $t4 0xab9fcf
    sw $t4 26124($v1)
    li $t4 0xa090ca
    sw $t4 26128($v1)
    li $t4 0xc1b8df
    sw $t4 26132($v1)
    li $t4 0xe1dff3
    sw $t4 26136($v1)
    li $t4 0xa087d3
    sw $t4 26140($v1)
    li $t4 0x937ec9
    sw $t4 26144($v1)
    li $t4 0x512d83
    sw $t4 26148($v1)
    li $t4 0x4a2668
    sw $t4 26152($v1)
    li $t4 0x2b1407
    sw $t4 26156($v1)
    sw $t4 29752($v1)
    sw $t4 31288($v1)
    li $t4 0x2c140b
    sw $t4 26160($v1)
    li $t4 0x2c150b
    sw $t4 26164($v1)
    li $t4 0x281400
    sw $t4 26168($v1)
    li $t4 0x3e2236
    sw $t4 26172($v1)
    li $t4 0x310b6b
    sw $t4 26176($v1)
    li $t4 0x005dcd
    sw $t4 26180($v1)
    li $t4 0x0192fd
    sw $t4 26184($v1)
    li $t4 0x0188fc
    sw $t4 26204($v1)
    li $t4 0x0293ff
    sw $t4 26208($v1)
    li $t4 0x0e52c1
    sw $t4 26212($v1)
    li $t4 0x0f0262
    sw $t4 26216($v1)
    li $t4 0x0a187e
    sw $t4 26220($v1)
    li $t4 0x0b2089
    sw $t4 26224($v1)
    li $t4 0x0b015d
    sw $t4 26228($v1)
    li $t4 0x060064
    sw $t4 26232($v1)
    li $t4 0x361756
    sw $t4 26636($v1)
    li $t4 0x371b56
    sw $t4 26640($v1)
    li $t4 0x4b2474
    sw $t4 26644($v1)
    li $t4 0x4d2675
    sw $t4 26648($v1)
    li $t4 0x4e2877
    sw $t4 26652($v1)
    li $t4 0x4a2373
    sw $t4 26656($v1)
    li $t4 0x4d2977
    sw $t4 26660($v1)
    li $t4 0x4b266a
    sw $t4 26664($v1)
    li $t4 0x2a1304
    draw4($t4, 26668, 27180, 29744, 29748)
    li $t4 0x2b1408
    draw4($t4, 26672, 27184, 27696, 28204)
    draw4($t4, 28208, 28716, 28720, 29228)
    sw $t4 29232($v1)
    sw $t4 29796($v1)
    li $t4 0x2b1409
    draw4($t4, 26676, 27188, 27700, 28212)
    sw $t4 28724($v1)
    li $t4 0x271201
    sw $t4 26680($v1)
    li $t4 0x3b202a
    sw $t4 26684($v1)
    li $t4 0x310868
    sw $t4 26688($v1)
    li $t4 0x0166d6
    sw $t4 26692($v1)
    li $t4 0x01a0ff
    sw $t4 26696($v1)
    li $t4 0x017ef3
    sw $t4 26704($v1)
    li $t4 0x057ff0
    sw $t4 26708($v1)
    li $t4 0x0651c3
    sw $t4 26712($v1)
    li $t4 0x0044b6
    sw $t4 26716($v1)
    li $t4 0x032d97
    sw $t4 26720($v1)
    li $t4 0x091e88
    sw $t4 26724($v1)
    li $t4 0x030366
    sw $t4 26728($v1)
    li $t4 0x070061
    sw $t4 26732($v1)
    li $t4 0x44247e
    sw $t4 26736($v1)
    li $t4 0x31166d
    sw $t4 26740($v1)
    li $t4 0x160a66
    sw $t4 26744($v1)
    li $t4 0x09014b
    sw $t4 26748($v1)
    li $t4 0x1f102f
    sw $t4 27156($v1)
    sw $t4 28276($v1)
    li $t4 0x2c1742
    sw $t4 27160($v1)
    li $t4 0x2b1640
    sw $t4 27164($v1)
    li $t4 0x432365
    sw $t4 27168($v1)
    li $t4 0x502a7b
    sw $t4 27172($v1)
    li $t4 0x4a2669
    sw $t4 27176($v1)
    li $t4 0x271200
    sw $t4 27192($v1)
    li $t4 0x3d212d
    sw $t4 27196($v1)
    li $t4 0x2d0b6c
    sw $t4 27200($v1)
    li $t4 0x003eac
    sw $t4 27204($v1)
    li $t4 0x016ad4
    sw $t4 27208($v1)
    li $t4 0x0155c8
    sw $t4 27212($v1)
    li $t4 0x003bad
    sw $t4 27216($v1)
    li $t4 0x031985
    sw $t4 27220($v1)
    li $t4 0x0b137d
    sw $t4 27224($v1)
    li $t4 0x2b248d
    sw $t4 27228($v1)
    li $t4 0x260c70
    sw $t4 27232($v1)
    li $t4 0x301b7c
    sw $t4 27236($v1)
    li $t4 0x211068
    sw $t4 27240($v1)
    li $t4 0x6c5eb0
    sw $t4 27244($v1)
    li $t4 0xa992c9
    sw $t4 27248($v1)
    li $t4 0x421869
    sw $t4 27252($v1)
    li $t4 0x532e74
    sw $t4 27256($v1)
    li $t4 0x1b0e29
    sw $t4 27684($v1)
    li $t4 0x4a2567
    sw $t4 27688($v1)
    li $t4 0x2b1406
    sw $t4 27692($v1)
    sw $t4 29740($v1)
    li $t4 0x281301
    sw $t4 27704($v1)
    li $t4 0x381c29
    sw $t4 27708($v1)
    li $t4 0x46227a
    sw $t4 27712($v1)
    li $t4 0x3f2c8a
    sw $t4 27716($v1)
    li $t4 0x443193
    sw $t4 27720($v1)
    li $t4 0x3e2981
    sw $t4 27724($v1)
    li $t4 0x473fa1
    sw $t4 27728($v1)
    li $t4 0x3c268b
    sw $t4 27732($v1)
    li $t4 0x442476
    sw $t4 27736($v1)
    li $t4 0xcec4e9
    sw $t4 27740($v1)
    li $t4 0xd7d1ee
    sw $t4 27744($v1)
    li $t4 0x907cc6
    sw $t4 27748($v1)
    li $t4 0x4b2074
    sw $t4 27752($v1)
    li $t4 0x8468af
    sw $t4 27756($v1)
    li $t4 0x9981c0
    sw $t4 27760($v1)
    li $t4 0x41196a
    sw $t4 27764($v1)
    li $t4 0x4f2c79
    sw $t4 27768($v1)
    li $t4 0x291301
    sw $t4 28216($v1)
    li $t4 0x371c2b
    sw $t4 28220($v1)
    li $t4 0x4c2277
    sw $t4 28224($v1)
    li $t4 0x997dc2
    sw $t4 28228($v1)
    li $t4 0xdad4f2
    sw $t4 28232($v1)
    li $t4 0x704fa8
    sw $t4 28236($v1)
    li $t4 0xcfbef1
    sw $t4 28240($v1)
    li $t4 0xf1f2fa
    sw $t4 28244($v1)
    li $t4 0x7b62b2
    sw $t4 28248($v1)
    li $t4 0xc2b1f1
    sw $t4 28252($v1)
    li $t4 0xfefeff
    sw $t4 28256($v1)
    li $t4 0x917fc8
    sw $t4 28260($v1)
    li $t4 0x47217a
    sw $t4 28264($v1)
    li $t4 0x48256d
    sw $t4 28268($v1)
    li $t4 0x4e2a77
    sw $t4 28272($v1)
    li $t4 0x2a1303
    sw $t4 28728($v1)
    li $t4 0x301920
    sw $t4 28732($v1)
    li $t4 0x3d166a
    sw $t4 28736($v1)
    li $t4 0xa899c8
    sw $t4 28740($v1)
    li $t4 0xbdb4d6
    sw $t4 28744($v1)
    li $t4 0x583387
    sw $t4 28748($v1)
    li $t4 0xaf9cd5
    sw $t4 28752($v1)
    li $t4 0xcac4db
    sw $t4 28756($v1)
    li $t4 0x6f54ac
    sw $t4 28760($v1)
    li $t4 0x4c2e73
    sw $t4 28764($v1)
    li $t4 0x421f58
    sw $t4 28768($v1)
    li $t4 0x46245d
    sw $t4 28772($v1)
    li $t4 0x422257
    sw $t4 28776($v1)
    li $t4 0x2a1408
    sw $t4 29236($v1)
    li $t4 0x2c140a
    sw $t4 29240($v1)
    li $t4 0x2d1b4e
    sw $t4 29252($v1)
    li $t4 0x220b3c
    sw $t4 29256($v1)
    li $t4 0x2b1540
    sw $t4 29260($v1)
    li $t4 0x220a38
    sw $t4 29264($v1)
    li $t4 0x20073b
    sw $t4 29268($v1)
    li $t4 0x38193c
    sw $t4 29272($v1)
    li $t4 0x261100
    sw $t4 29276($v1)
    li $t4 0x281200
    sw $t4 29280($v1)
    sw $t4 29284($v1)
    sw $t4 30776($v1)
    li $t4 0x251100
    sw $t4 29288($v1)
    li $t4 0x231100
    sw $t4 29784($v1)
    li $t4 0x2c150a
    sw $t4 29788($v1)
    li $t4 0x2a1305
    sw $t4 29792($v1)
    li $t4 0x291309
    sw $t4 29800($v1)
    li $t4 0x361b2a
    sw $t4 30252($v1)
    li $t4 0x381c32
    sw $t4 30256($v1)
    li $t4 0x3e2045
    sw $t4 30260($v1)
    li $t4 0x301616
    sw $t4 30264($v1)
    li $t4 0x27130a
    sw $t4 30296($v1)
    li $t4 0x281201
    sw $t4 30300($v1)
    li $t4 0x3c1e3f
    sw $t4 30304($v1)
    li $t4 0x351a27
    sw $t4 30308($v1)
    li $t4 0x251203
    sw $t4 30312($v1)
    li $t4 0x291306
    sw $t4 30764($v1)
    li $t4 0x482563
    sw $t4 30768($v1)
    li $t4 0x331a26
    sw $t4 30772($v1)
    li $t4 0x251109
    sw $t4 30808($v1)
    li $t4 0x3a1d37
    sw $t4 30812($v1)
    li $t4 0x40204a
    sw $t4 30816($v1)
    li $t4 0x2e1615
    sw $t4 30820($v1)
    li $t4 0x291408
    sw $t4 30824($v1)
    li $t4 0x2e1611
    sw $t4 31272($v1)
    li $t4 0x3d1f40
    sw $t4 31276($v1)
    sw $t4 31324($v1)
    li $t4 0x4d2872
    sw $t4 31280($v1)
    li $t4 0x452359
    sw $t4 31284($v1)
    li $t4 0x33211e
    sw $t4 31292($v1)
    li $t4 0x2f1814
    sw $t4 31320($v1)
    li $t4 0x3e1f43
    sw $t4 31328($v1)
    li $t4 0x32181f
    sw $t4 31332($v1)
    li $t4 0x291101
    sw $t4 31336($v1)
    li $t4 0x311d18
    sw $t4 31340($v1)
    li $t4 0x311b1b
    sw $t4 31784($v1)
    li $t4 0x341923
    sw $t4 31788($v1)
    li $t4 0x2d150f
    sw $t4 31792($v1)
    li $t4 0x3d1e40
    sw $t4 31796($v1)
    li $t4 0x2c150c
    sw $t4 31800($v1)
    li $t4 0x32211e
    sw $t4 31804($v1)
    li $t4 0x311e18
    sw $t4 31828($v1)
    li $t4 0x2d140c
    sw $t4 31832($v1)
    li $t4 0x3e1f44
    sw $t4 31836($v1)
    li $t4 0x3f1f47
    sw $t4 31840($v1)
    li $t4 0x31181f
    sw $t4 31844($v1)
    li $t4 0x31211c
    sw $t4 31848($v1)
    li $t4 0x33211f
    sw $t4 31852($v1)
    sw $t4 32852($v1)
    li $t4 0x2d180d
    sw $t4 32296($v1)
    li $t4 0x281302
    sw $t4 32300($v1)
    li $t4 0x261003
    sw $t4 32304($v1)
    li $t4 0x261301
    sw $t4 32308($v1)
    li $t4 0x2b1306
    sw $t4 32312($v1)
    li $t4 0x342120
    sw $t4 32316($v1)
    li $t4 0x342321
    sw $t4 32340($v1)
    li $t4 0x35252a
    sw $t4 32344($v1)
    li $t4 0x2c1517
    sw $t4 32348($v1)
    li $t4 0x2a120d
    sw $t4 32352($v1)
    li $t4 0x2c1313
    sw $t4 32356($v1)
    li $t4 0x35292b
    sw $t4 32360($v1)
    li $t4 0x32201e
    sw $t4 32364($v1)
    li $t4 0x2c1c13
    sw $t4 32808($v1)
    li $t4 0x403442
    sw $t4 32812($v1)
    li $t4 0x504351
    sw $t4 32816($v1)
    li $t4 0x423544
    sw $t4 32820($v1)
    li $t4 0x2d1912
    sw $t4 32824($v1)
    li $t4 0x30231d
    sw $t4 32828($v1)
    li $t4 0x301d16
    sw $t4 32856($v1)
    li $t4 0x4a414b
    sw $t4 32860($v1)
    li $t4 0x49404a
    sw $t4 32864($v1)
    li $t4 0x4b434d
    sw $t4 32868($v1)
    li $t4 0x311e19
    sw $t4 32872($v1)
    li $t4 0x311e1a
    sw $t4 32876($v1)
    li $t4 0x380d19
    sw $t4 33320($v1)
    li $t4 0x404149
    sw $t4 33324($v1)
    li $t4 0x5b6169
    sw $t4 33328($v1)
    li $t4 0x374045
    sw $t4 33332($v1)
    li $t4 0x362e37
    sw $t4 33336($v1)
    li $t4 0x3e1724
    sw $t4 33340($v1)
    li $t4 0x2f211c
    sw $t4 33364($v1)
    li $t4 0x3b3037
    sw $t4 33368($v1)
    li $t4 0x655969
    sw $t4 33372($v1)
    li $t4 0x625765
    sw $t4 33376($v1)
    li $t4 0x655a69
    sw $t4 33380($v1)
    li $t4 0x3d343d
    sw $t4 33384($v1)
    li $t4 0x2e2017
    sw $t4 33388($v1)
    li $t4 0x472645
    sw $t4 33832($v1)
    li $t4 0x571536
    sw $t4 33836($v1)
    li $t4 0x841c49
    sw $t4 33840($v1)
    li $t4 0x82204b
    sw $t4 33844($v1)
    li $t4 0x4e1131
    sw $t4 33848($v1)
    li $t4 0x43162a
    sw $t4 33876($v1)
    li $t4 0x382b36
    sw $t4 33880($v1)
    li $t4 0x2a2e34
    sw $t4 33884($v1)
    li $t4 0x2b2c33
    sw $t4 33888($v1)
    li $t4 0x292e34
    sw $t4 33892($v1)
    li $t4 0x372e38
    sw $t4 33896($v1)
    li $t4 0x421227
    sw $t4 33900($v1)
    li $t4 0x683c5e
    sw $t4 34352($v1)
    li $t4 0x63395b
    sw $t4 34356($v1)
    li $t4 0x510e32
    sw $t4 34392($v1)
    li $t4 0x9a1f53
    sw $t4 34396($v1)
    li $t4 0x9b1f53
    sw $t4 34400($v1)
    li $t4 0x9c2054
    sw $t4 34404($v1)
    li $t4 0x540e33
    sw $t4 34408($v1)
    jr $ra

draw_game_clear: # use t0-t9 v1
    # set position to (13, 5 + s7)
    sll $v1 $s7 9 # to (0, s7)
    addi $v1 $v1 2612 # to (13, 13 + s7)
    addi $v1 $v1 BASE_ADDRESS

    draw64($0, 12, 16, 20, 24, 28, 32, 236, 240, 244, 248, 252, 256, 276, 280, 284, 288, 520, 548, 552, 744, 772, 776, 1028, 1252, 1536, 1580, 1604, 1608, 1636, 1640, 1652, 1656, 1676, 1680, 1712, 1716, 1720, 1804, 1848, 1852, 1856, 1888, 1892, 1896, 1936, 1940, 2104, 2108, 2112, 2124, 2128, 2144, 2156, 2160, 2172, 2176, 2180, 2184, 2196, 2200, 2216, 2220, 2236, 2240)
    draw64($0, 2272, 2352, 2356, 2372, 2376, 2392, 2396, 2412, 2416, 2432, 2436, 2440, 2444, 2644, 2724, 2756, 2860, 2900, 2932, 3124, 3368, 3404, 3608, 3612, 3616, 3620, 3624, 3628, 3784, 4156, 4160, 4164, 4168, 4272, 4276, 4280, 4408, 4412, 4416, 4440, 4444, 4448, 4452, 4456, 4620, 4660, 4664, 4868, 4872, 4876, 4948, 5376, 5648, 5808, 5824, 5828, 5872, 5956, 5960, 6164, 6168, 6172, 6208, 6212)
    draw4($0, 6216, 6324, 6328, 6332)
    draw4($0, 6388, 6392, 6396, 6456)
    draw4($0, 6460, 6464, 6476, 6496)
    sw $0 6500($v1)
    sw $0 6504($v1)
    sw $0 8040($v1)
    draw16($t2, 524, 792, 796, 1764, 2604, 2752, 2904, 2928, 3268, 3412, 3820, 3916, 3988, 4332, 4404, 4844)
    draw16($t2, 5460, 5664, 6384, 7336, 7696, 7740, 7760, 7764, 7780, 7784, 7804, 7808, 7828, 7832, 7856, 7868)
    draw4($t2, 7920, 7960, 7964, 8048)
    sw $t2 8052($v1)
    sw $t2 8064($v1)
    sw $t2 8068($v1)
    draw16($t5, 528, 540, 1540, 1780, 2796, 3224, 3748, 3956, 4172, 4428, 4752, 4956, 5000, 5192, 5264, 5416)
    draw16($t5, 5476, 5480, 5512, 5708, 5776, 6024, 6288, 6372, 6400, 6536, 6800, 6840, 6972, 7008, 7012, 7048)
    sw $t5 7312($v1)
    sw $t5 7496($v1)
    sw $t5 7560($v1)
    draw16($t7, 532, 536, 760, 1060, 1564, 1576, 2148, 2596, 2600, 2656, 2664, 2684, 2708, 2956, 3140, 3168)
    draw16($t7, 3400, 3428, 3584, 3680, 4096, 4192, 4268, 4608, 4672, 4704, 4784, 4788, 4792, 4916, 4920, 4924)
    draw16($t7, 4928, 4940, 5216, 5452, 5728, 6240, 6676, 6684, 6720, 6728, 6752, 6852, 6900, 6904, 6920, 6996)
    sw $t7 7224($v1)
    sw $t7 7244($v1)
    sw $t7 7264($v1)
    draw16($t3, 544, 768, 1256, 1312, 1824, 2152, 2336, 2572, 2668, 2848, 2864, 3296, 3308, 3360, 3372, 3636)
    draw16($t3, 3648, 3692, 3760, 3872, 3984, 4140, 4384, 4392, 4896, 5152, 5344, 5356, 5408, 5632, 5920, 6176)
    draw16($t3, 6412, 6432, 6472, 6660, 6700, 6944, 7176, 7208, 7456, 7708, 7748, 7932, 7992, 8000, 8028, 8036)
    draw16($t0, 748, 788, 800, 1064, 2048, 2116, 2120, 2164, 2168, 2188, 2192, 2224, 2232, 2288, 2360, 2364)
    draw16($t0, 2368, 2400, 2408, 2448, 2452, 2616, 2688, 2712, 2728, 2816, 2888, 3084, 3236, 3700, 3724, 3768)
    draw4($t0, 3880, 3896, 4296, 5172)
    draw4($t0, 5856, 5888, 6340, 6468)
    draw4($t0, 7752, 7756, 7936, 7956)
    sw $t0 7968($v1)
    sw $t0 8004($v1)
    sw $t0 8024($v1)
    draw16($t4, 752, 1556, 1560, 1784, 2304, 2316, 2560, 2640, 2692, 2952, 3156, 3716, 3808, 3904, 4284, 4320)
    draw16($t4, 4652, 4668, 4832, 4904, 5164, 5644, 5676, 5684, 5928, 6188, 6336, 6708, 6724, 7700, 7704, 7744)
    draw4($t4, 7860, 7864, 7924, 7928)
    sw $t4 7996($v1)
    sw $t4 8032($v1)
    draw16($t6, 756, 764, 1032, 1788, 2080, 2620, 2732, 2828, 2884, 2964, 3072, 3476, 3924, 3980, 4216, 4240)
    draw16($t6, 4468, 4488, 4728, 4980, 5120, 5188, 5240, 5492, 5752, 5804, 5868, 5900, 6004, 6196, 6220, 6264)
    draw4($t6, 6308, 6452, 6492, 6516)
    draw4($t6, 6680, 6776, 6836, 6956)
    draw4($t6, 6976, 7028, 7288, 7428)
    sw $t6 7472($v1)
    draw256($t9, 1036, 1040, 1044, 1048, 1052, 1056, 1260, 1264, 1268, 1272, 1276, 1280, 1304, 1308, 1544, 1548, 1568, 1572, 1768, 1772, 1776, 1792, 1796, 1816, 1820, 2052, 2056, 2084, 2088, 2280, 2284, 2308, 2312, 2328, 2332, 2564, 2568, 2624, 2628, 2632, 2636, 2660, 2672, 2676, 2680, 2696, 2700, 2704, 2736, 2740, 2744, 2788, 2792, 2820, 2824, 2840, 2844, 2872, 2876, 2880, 2912, 2916, 2920, 2944, 2948, 2960, 3076, 3080, 3132, 3136, 3148, 3152, 3172, 3176, 3180, 3184, 3188, 3192, 3196, 3204, 3208, 3212, 3216, 3220, 3244, 3248, 3252, 3256, 3260, 3264, 3300, 3304, 3352, 3356, 3376, 3380, 3384, 3388, 3392, 3396, 3416, 3420, 3424, 3432, 3436, 3440, 3456, 3460, 3464, 3468, 3472, 3588, 3592, 3640, 3644, 3664, 3668, 3684, 3688, 3704, 3708, 3712, 3732, 3736, 3752, 3756, 3776, 3812, 3816, 3864, 3868, 3884, 3888, 3908, 3912, 3928, 3932, 3948, 3952, 3968, 3972, 3976, 4100, 4104, 4176, 4180, 4196, 4200, 4220, 4224, 4244, 4248, 4264, 4288, 4292, 4324, 4328, 4376, 4380, 4396, 4400, 4420, 4424, 4460, 4464, 4480, 4484, 4612, 4616, 4636, 4640, 4644, 4648, 4676, 4680, 4684, 4688, 4692, 4708, 4712, 4732, 4736, 4756, 4760, 4772, 4776, 4800, 4804, 4836, 4840, 4888, 4892, 4908, 4912, 4932, 4936, 4964, 4968, 4972, 4976, 4992, 4996, 5124, 5128, 5156, 5160, 5180, 5184, 5200, 5204, 5220, 5224, 5244, 5248, 5268, 5272, 5284, 5288, 5292, 5296, 5300, 5304, 5308, 5312, 5316, 5348, 5352, 5400, 5404, 5420, 5424, 5428, 5432, 5436, 5440, 5444, 5448, 5464, 5468, 5484, 5488, 5504, 5508, 5636, 5640, 5668, 5672, 5688, 5692, 5712, 5716, 5732, 5736, 5756, 5760, 5780)
    draw64($t9, 5784, 5796, 5800, 5860, 5864, 5892, 5896, 5912, 5916, 5932, 5936, 5976, 5996, 6000, 6016, 6020, 6148, 6152, 6156, 6180, 6184, 6200, 6204, 6224, 6228, 6244, 6248, 6268, 6272, 6292, 6296, 6312, 6316, 6376, 6380, 6404, 6408, 6424, 6428, 6444, 6448, 6484, 6488, 6508, 6512, 6528, 6532, 6664, 6668, 6672, 6688, 6692, 6696, 6712, 6716, 6732, 6736, 6740, 6756, 6760, 6780, 6784, 6804, 6808)
    draw16($t9, 6824, 6828, 6832, 6848, 6888, 6892, 6896, 6912, 6916, 6936, 6940, 6960, 6964, 6980, 6984, 7000)
    draw16($t9, 7004, 7020, 7024, 7040, 7044, 7184, 7188, 7192, 7196, 7200, 7228, 7232, 7236, 7240, 7248, 7252)
    draw16($t9, 7268, 7272, 7292, 7296, 7316, 7320, 7344, 7348, 7352, 7356, 7408, 7412, 7416, 7420, 7424, 7448)
    draw4($t9, 7452, 7476, 7480, 7484)
    draw4($t9, 7488, 7492, 7512, 7516)
    draw4($t9, 7520, 7524, 7536, 7552)
    sw $t9 7556($v1)
    draw16($t8, 1284, 1552, 1800, 2060, 2276, 2748, 2868, 2908, 2924, 3128, 3144, 3200, 3240, 3660, 3728, 3772)
    draw16($t8, 3780, 3892, 4120, 4124, 4128, 4132, 4136, 4260, 4632, 4780, 4796, 4960, 5176, 5196, 5472, 5972)
    draw4($t8, 5980, 6844, 6908, 6968)
    draw4($t8, 7016, 7180, 7204, 7340)
    draw4($t8, 7360, 7404, 7528, 7532)
    sw $t8 7540($v1)
    draw16($t1, 1288, 1300, 1812, 2092, 2228, 2324, 2404, 2592, 2784, 2836, 3348, 3444, 3860, 3944, 4372, 4808)
    draw16($t1, 4884, 4952, 5132, 5320, 5380, 5384, 5388, 5396, 5696, 5908, 5940, 6160, 6320, 6420, 6440, 6820)
    draw4($t1, 6932, 6988, 7364, 7400)
    draw4($t1, 7444, 7508, 7712, 7776)
    draw4($t1, 7800, 7824, 7988, 8044)
    sw $t1 8072($v1)
    jr $ra
draw_post_return: # use t0-t9 v1
    li $v0 BASE_ADDRESS
    addi $v1 $v0 21608 # (26, 42)
    jal draw_keybase
    addi $v1 $v0 POST_P
    jal draw_keyp
    addi $v1 $v0 21692 # (47, 42)
    jal draw_to
    addi $v1 $v0 22264 # (62, 43)
    jal draw_re
    addi $v1 $v0 21796 # (73, 42)
    jal draw_turn
    # to lazy to store ra in stack
    j post_ui_end
draw_post_restart: # use t0-t9 v1
    li $v0 BASE_ADDRESS
    addi $v1 $v0 32872 # (26, 64)
    jal draw_keybase
    addi $v1 $v0 POST_S
    jal draw_keys
    addi $v1 $v0 32956 # (47, 64)
    jal draw_to
    addi $v1 $v0 33528 # (62, 65)
    jal draw_re
    addi $v1 $v0 33064 # (74, 64)
    jal draw_start
    j post_ui_end
draw_post_quit: # use t0-t9 v1
    li $v0 BASE_ADDRESS
    addi $v1 $v0 44136 # (26, 86)
    jal draw_keybase
    addi $v1 $v0 POST_Q
    jal draw_keyq
    addi $v1 $v0 44732 # (47, 87)
    jal draw_to
    addi $v1 $v0 44280 # (62, 86)
    jal draw_quit
    j post_ui_end
draw_post_doll:
    addi $sp $sp -4 # push ra to stack
    sw $ra 0($sp)

    la $a2 postgame_doll # array of frames
    frame2(DOLLS_FRAME)
    li $v1 BASE_ADDRESS
    addi $v1 $v1 41308 # (87, 80)
    jalr $v0

    lw $ra 0($sp) # pop ra from stack
    addi $sp $sp 4
    jr $ra
draw_post_doll_00: # start at v1, use t4
    li $t4 0x91003b
    draw64($t4, 3636, 3644, 3648, 3664, 4140, 4180, 4184, 4648, 4664, 4688, 4700, 5156, 5172, 5192, 5208, 5216, 5668, 5680, 5708, 6176, 6208, 6220, 6244, 6688, 6708, 6720, 6732, 6736, 6744, 6756, 7200, 7220, 7232, 7244, 7248, 7256, 7268, 7712, 7728, 7732, 7740, 7744, 7748, 7756, 7764, 7768, 7772, 7780, 8224, 8240, 8244, 8264, 8280, 8284, 8292, 8736, 8740, 8748, 8792, 8796, 8800, 8804, 9248, 9252)
    draw64($t4, 9260, 9272, 9308, 9312, 9316, 9760, 9764, 9772, 9784, 9820, 9824, 10272, 10276, 10284, 10288, 10328, 10332, 10336, 10788, 10792, 10796, 10800, 10804, 10832, 10836, 10840, 10844, 10848, 11300, 11304, 11308, 11352, 11356, 11360, 11812, 11816, 11868, 11872, 12320, 12324, 12380, 12384, 12388, 12900, 13392, 13872, 13904, 14376, 14380, 14416, 14420, 14880, 14884, 14888, 14932, 14936, 15388, 15392, 15396, 15448, 15452, 15456, 15900, 15904)
    draw4($t4, 15960, 15968, 16412, 16480)
    li $t4 0xda7141
    draw16($t4, 3640, 3652, 3656, 3660, 4144, 4156, 4160, 4172, 4176, 4652, 4692, 5160, 5196, 5696, 5712, 5720)
    draw16($t4, 5728, 6180, 6196, 6224, 6232, 6748, 7216, 7228, 7236, 7260, 8228, 8236, 8288, 8760, 9768, 10280)
    li $t4 0xfaa753
    draw16($t4, 4148, 4152, 4164, 4168, 4656, 4660, 4696, 5164, 5200, 5204, 5212, 5672, 5692, 5704, 6184, 6236)
    draw4($t4, 6692, 6704, 6716, 6724)
    draw4($t4, 7204, 7212, 7716, 7724)
    draw4($t4, 7776, 8232, 8248, 8744)
    sw $t4 9256($v1)
    li $t4 0xd1003f
    draw4($t4, 4668, 4672, 4676, 4680)
    draw4($t4, 4684, 5176, 5180, 5184)
    draw4($t4, 5188, 5684, 13380, 13892)
    sw $t4 14404($v1)
    sw $t4 14412($v1)
    li $t4 0xfaff53
    draw16($t4, 5168, 5676, 5688, 5700, 5716, 5724, 6188, 6192, 6200, 6204, 6212, 6216, 6228, 6240, 6696, 6700)
    draw4($t4, 6712, 6728, 6740, 6752)
    draw4($t4, 7208, 7224, 7240, 7252)
    draw4($t4, 7264, 7720, 7736, 7752)
    li $t4 0xaa90e0
    draw64($t4, 7688, 7692, 8196, 8208, 8212, 8296, 8300, 8708, 8728, 8732, 8764, 8808, 8812, 9220, 9244, 9320, 9728, 9732, 9736, 9740, 9744, 9828, 10240, 10252, 10256, 10260, 10344, 10348, 10752, 10772, 10776, 10780, 10784, 10852, 10856, 10860, 11268, 11292, 11296, 11316, 11340, 11344, 11364, 11368, 11784, 11788, 11808, 11836, 11876, 12304, 12308, 12344, 12360, 12376, 12824, 12828, 12856, 12864, 12876, 13344, 13368, 13372, 14388, 14904)
    draw16($t4, 14908, 14924, 15928, 15932, 15936, 15948, 16440, 16448, 16464, 16952, 16960, 16976, 17488, 17996, 18496, 18500)
    sw $t4 18504($v1)
    sw $t4 20524($v1)
    li $t4 0xffaa73
    draw4($t4, 7760, 8268, 8272, 8776)
    draw4($t4, 8780, 8784, 9296, 9780)
    sw $t4 10296($v1)
    sw $t4 10320($v1)
    li $t4 0xededff
    draw64($t4, 8200, 8204, 8712, 8716, 8720, 8724, 9224, 9228, 9232, 9236, 9240, 9276, 9748, 9752, 9756, 10244, 10248, 10264, 10268, 10756, 10760, 10764, 10768, 11272, 11276, 11280, 11284, 11288, 11792, 11796, 11800, 11804, 11824, 11828, 11832, 11848, 11852, 11856, 11860, 12312, 12316, 12340, 12348, 12352, 12364, 12368, 12372, 12860, 12880, 13856, 14912, 14916, 14920, 15940, 15944, 16444, 16452, 16456, 16460, 16956, 16964, 16968, 16972, 17464)
    draw4($t4, 17468, 17472, 17476, 17480)
    draw4($t4, 17484, 17980, 17984, 17988)
    sw $t4 17992($v1)
    li $t4 0x2b1408
    draw16($t4, 8252, 8256, 8260, 8276, 20520, 20536, 21032, 21036, 21040, 21048, 21052, 21056, 21548, 21552, 21564, 21568)
    draw64($0, 8704, 9216, 10340, 11264, 11776, 11780, 12292, 12296, 12300, 12392, 12396, 12808, 12812, 12816, 12820, 12904, 12908, 13328, 13332, 13336, 13412, 13416, 13844, 13924, 14356, 14436, 14868, 14948, 15380, 15896, 16408, 16920, 16924, 16988, 16992, 17436, 17500, 17504, 17948, 18016, 18460, 18528, 18976, 19488, 19492, 19496, 19544, 20000, 20004, 20008, 20020, 20032, 20036, 20040, 20044, 20048, 20052, 20056, 20060, 20512, 20516, 20532, 20544, 20548)
    draw16($0, 20552, 20556, 20560, 20564, 20568, 20572, 21028, 21044, 21060, 21064, 21068, 21072, 21076, 21080, 21556, 21560)
    draw4($0, 21572, 21576, 21580, 21584)
    sw $0 21588($v1)
    li $t4 0xbd6455
    draw16($t4, 8752, 8756, 9264, 9304, 9776, 9816, 10292, 10324, 10812, 10816, 10820, 10824, 10828, 13848, 13916, 14360)
    sw $t4 14368($v1)
    sw $t4 14424($v1)
    sw $t4 14876($v1)
    li $t4 0x10309c
    draw16($t4, 8768, 8772, 8788, 9280, 9300, 9812, 12332, 12836, 12844, 12848, 12892, 13356, 13400, 13404, 13408, 13852)
    draw16($t4, 13860, 13864, 14896, 15404, 15408, 15412, 15912, 15916, 15920, 15956, 16420, 16424, 16428, 16432, 16468, 16932)
    draw16($t4, 16936, 16940, 16944, 16980, 16984, 17444, 17448, 17452, 17456, 17496, 17956, 17960, 17964, 17968, 17972, 18008)
    draw4($t4, 18468, 18472, 18476, 18480)
    draw4($t4, 18488, 18520, 18984, 18988)
    draw4($t4, 18992, 19512, 19516, 19520)
    sw $t4 19524($v1)
    sw $t4 19528($v1)
    sw $t4 19532($v1)
    li $t4 0xfde3b2
    draw4($t4, 9268, 9288, 9292, 9788)
    draw4($t4, 9796, 9800, 9804, 9808)
    draw4($t4, 10300, 10304, 10308, 10312)
    sw $t4 10316($v1)
    sw $t4 14364($v1)
    sw $t4 14428($v1)
    li $t4 0x008bff
    draw16($t4, 9284, 9792, 12840, 13348, 13352, 17492, 18000, 18004, 18484, 18508, 18512, 18516, 18996, 19000, 19004, 19008)
    draw4($t4, 19012, 19016, 19020, 19024)
    sw $t4 19028($v1)
    li $t4 0x0b0064
    draw16($t4, 10808, 11324, 11328, 11332, 12328, 12832, 12888, 12896, 13360, 13364, 13396, 13868, 13880, 13908, 14384, 14892)
    draw16($t4, 15400, 15444, 15908, 16416, 16472, 16928, 17440, 17952, 18464, 18980, 19032, 19500, 19504, 19508, 19536, 19540)
    li $t4 0x674da7
    draw16($t4, 11312, 11320, 11336, 11348, 11820, 11840, 11844, 11864, 12336, 12852, 12884, 13340, 13876, 14372, 14392, 14900)
    draw16($t4, 14928, 15416, 15420, 15424, 15428, 15432, 15436, 15440, 15924, 15952, 16436, 16948, 17460, 17976, 18492, 20012)
    draw4($t4, 20016, 20024, 20028, 20528)
    sw $t4 20540($v1)
    li $t4 0x4d0027
    draw4($t4, 12356, 12868, 12872, 13376)
    draw4($t4, 13384, 13388, 13884, 13896)
    sw $t4 14396($v1)
    sw $t4 14408($v1)
    li $t4 0x880033
    sw $t4 13888($v1)
    sw $t4 13900($v1)
    sw $t4 14400($v1)
    li $t4 0x7a3332
    draw4($t4, 13912, 13920, 14432, 14872)
    sw $t4 14940($v1)
    sw $t4 14944($v1)
    jr $ra
draw_post_doll_01: # start at v1, use t4
    li $t4 0x91003b
    draw64($t4, 2100, 2108, 2112, 2128, 2604, 2644, 2648, 3112, 3128, 3152, 3164, 3620, 3636, 3656, 3672, 3680, 4132, 4144, 4172, 4640, 4672, 4684, 4708, 5152, 5172, 5184, 5196, 5200, 5208, 5220, 5664, 5684, 5696, 5708, 5712, 5720, 5732, 6176, 6192, 6196, 6204, 6208, 6212, 6220, 6232, 6688, 6704, 6708, 6732, 6744, 6752, 7204, 7212, 7240, 7256, 7264, 7716, 7724, 7736, 7772, 7776, 8228, 8236, 8248)
    draw64($t4, 8284, 8288, 8740, 8748, 8752, 8792, 8796, 8800, 9252, 9260, 9264, 9268, 9296, 9300, 9304, 9308, 9312, 9764, 9768, 9772, 9816, 9820, 9824, 10276, 10280, 10332, 10336, 10784, 10788, 10844, 10848, 10852, 11360, 11364, 11872, 11876, 12336, 12368, 12388, 12840, 12844, 12880, 12884, 12900, 13344, 13348, 13352, 13396, 13400, 13412, 13856, 13860, 13864, 13912, 13916, 13920, 13924, 14368, 14372, 14424, 14428, 14432, 14884, 14940)
    sw $t4 14944($v1)
    li $t4 0xda7141
    draw16($t4, 2104, 2116, 2120, 2124, 2608, 2620, 2624, 2636, 2640, 3116, 3156, 3624, 3660, 4136, 4156, 4160)
    draw16($t4, 4176, 4184, 4192, 4644, 4660, 4688, 4696, 5156, 5668, 5680, 5692, 5700, 5728, 6180, 6240, 6692)
    draw4($t4, 7224, 7260, 8744, 9256)
    li $t4 0xfaa753
    draw16($t4, 2612, 2616, 2628, 2632, 3120, 3124, 3160, 3628, 3664, 3668, 3676, 4168, 4648, 4656, 4668, 4704)
    draw4($t4, 5160, 5168, 5180, 5188)
    draw4($t4, 5216, 5672, 6184, 6236)
    draw4($t4, 6696, 6712, 6748, 7208)
    sw $t4 7720($v1)
    sw $t4 8232($v1)
    li $t4 0xd1003f
    draw4($t4, 3132, 3136, 3140, 3144)
    draw4($t4, 3148, 3640, 3644, 3648)
    draw4($t4, 3652, 4148, 11844, 12356)
    sw $t4 12868($v1)
    sw $t4 12876($v1)
    sw $t4 13380($v1)
    li $t4 0xfaff53
    draw16($t4, 3632, 4140, 4152, 4164, 4180, 4188, 4652, 4664, 4676, 4680, 4692, 4700, 5164, 5176, 5192, 5204)
    draw4($t4, 5212, 5676, 5688, 5704)
    draw4($t4, 5716, 5724, 6188, 6200)
    draw4($t4, 6216, 6228, 6700, 6728)
    li $t4 0xffaa73
    draw4($t4, 6224, 6736, 7244, 7248)
    draw4($t4, 7760, 8244, 8760, 8784)
    draw64($0, 6244, 6756, 7200, 7268, 7688, 7692, 7712, 7780, 8196, 8200, 8204, 8208, 8212, 8224, 8292, 8296, 8300, 8708, 8712, 8716, 8720, 8724, 8728, 8732, 8736, 8804, 8808, 8812, 9220, 9224, 9228, 9232, 9236, 9240, 9244, 9248, 9316, 9320, 9728, 9732, 9736, 9740, 9744, 9748, 9752, 9756, 9760, 10240, 10244, 10248, 10752, 11368, 14360, 14364, 14872, 14876, 14880, 15388, 15392, 15452, 15456, 15900, 15904, 15968)
    draw16($0, 16412, 16416, 16480, 16928, 17440, 17952, 17956, 17960, 18004, 18008, 18464, 18468, 18472, 18484, 18496, 18500)
    draw16($0, 18504, 18508, 18512, 18516, 18520, 18980, 18996, 19008, 19012, 19016, 19020, 19024, 19028, 19032, 19508, 19524)
    draw16($0, 19528, 19532, 19536, 19540, 20024, 20520, 20524, 20528, 20536, 20540, 21032, 21036, 21040, 21048, 21052, 21056)
    draw4($0, 21548, 21552, 21564, 21568)
    li $t4 0x2b1408
    draw16($t4, 6716, 6720, 6724, 6740, 18984, 19000, 19496, 19500, 19504, 19512, 19516, 19520, 20012, 20016, 20028, 20032)
    li $t4 0xbd6455
    draw16($t4, 7216, 7220, 7728, 7768, 8240, 8280, 8756, 8788, 9276, 9280, 9284, 9288, 9292, 12312, 12380, 12824)
    sw $t4 12832($v1)
    sw $t4 12888($v1)
    sw $t4 13340($v1)
    li $t4 0xaa90e0
    draw64($t4, 7228, 9780, 9808, 9828, 9832, 10252, 10256, 10260, 10264, 10268, 10272, 10300, 10312, 10324, 10340, 10344, 10348, 10756, 10760, 10808, 10812, 10840, 10856, 10860, 11264, 11292, 11320, 11324, 11328, 11344, 11776, 11796, 11800, 11808, 11832, 11836, 11880, 11884, 12288, 12300, 12304, 12308, 12392, 12800, 12804, 12808, 12812, 12816, 12852, 13316, 13368, 13372, 13824, 13848, 13852, 14336, 14352, 14356, 14396, 14400, 14412, 14848, 14852, 14856)
    draw4($t4, 14860, 14912, 14928, 15928)
    draw4($t4, 15948, 16956, 16968, 18988)
    li $t4 0x10309c
    draw16($t4, 7232, 7236, 7252, 7744, 7764, 8276, 10796, 11300, 11308, 11312, 11352, 11820, 11860, 11864, 11868, 12316)
    draw16($t4, 12324, 12328, 13360, 13872, 13876, 14380, 14384, 14388, 14420, 14892, 14896, 14900, 14932, 15400, 15404, 15408)
    draw16($t4, 15412, 15444, 15448, 15912, 15916, 15920, 15924, 15960, 16424, 16428, 16432, 16436, 16472, 16936, 16940, 16944)
    draw4($t4, 16952, 16984, 17448, 17452)
    draw4($t4, 17456, 17976, 17980, 17984)
    sw $t4 17988($v1)
    sw $t4 17992($v1)
    sw $t4 17996($v1)
    li $t4 0xfde3b2
    draw4($t4, 7732, 7752, 7756, 8252)
    draw4($t4, 8260, 8264, 8268, 8272)
    draw4($t4, 8764, 8768, 8772, 8776)
    sw $t4 8780($v1)
    sw $t4 12828($v1)
    sw $t4 12892($v1)
    li $t4 0xededff
    draw64($t4, 7740, 10288, 10292, 10296, 10316, 10320, 10764, 10768, 10772, 10776, 10780, 10804, 10816, 10828, 10832, 10836, 11268, 11272, 11276, 11280, 11284, 11288, 11340, 11780, 11784, 11788, 11792, 12292, 12296, 12320, 12820, 13320, 13324, 13328, 13332, 13376, 13828, 13832, 13836, 13840, 13844, 14340, 14344, 14348, 14404, 14408, 14908, 14916, 14920, 14924, 15420, 15424, 15428, 15432, 15436, 15932, 15936, 15940, 15944, 16444, 16448, 16452, 16456, 16960)
    sw $t4 16964($v1)
    li $t4 0x008bff
    draw16($t4, 7748, 8256, 11304, 11812, 11816, 15952, 15956, 16464, 16468, 16948, 16976, 16980, 17460, 17464, 17484, 17488)
    sw $t4 17492($v1)
    li $t4 0x0b0064
    draw16($t4, 9272, 9788, 9792, 9796, 9800, 10792, 11296, 11356, 11824, 11828, 11856, 12332, 12344, 12348, 12372, 12848)
    draw16($t4, 13356, 13392, 13868, 13908, 14376, 14888, 14936, 15396, 15908, 16420, 16932, 17444, 17496, 17964, 17968, 17972)
    sw $t4 18000($v1)
    li $t4 0x674da7
    draw16($t4, 9776, 9784, 9804, 9812, 10284, 10304, 10308, 10328, 10800, 11316, 11348, 11804, 12340, 12836, 12856, 12860)
    draw16($t4, 13364, 13388, 13880, 13884, 13888, 13892, 13896, 13900, 13904, 14392, 14416, 14904, 15416, 15440, 16440, 16460)
    draw4($t4, 16972, 17468, 17472, 17476)
    draw4($t4, 17480, 18476, 18480, 18488)
    sw $t4 18492($v1)
    sw $t4 18992($v1)
    sw $t4 19004($v1)
    li $t4 0x4d0027
    draw4($t4, 10820, 10824, 11332, 11336)
    draw4($t4, 11840, 11848, 11852, 12360)
    sw $t4 12872($v1)
    sw $t4 13384($v1)
    li $t4 0x880033
    sw $t4 12352($v1)
    sw $t4 12364($v1)
    sw $t4 12864($v1)
    li $t4 0x7a3332
    draw4($t4, 12376, 12384, 12896, 13336)
    sw $t4 13404($v1)
    sw $t4 13408($v1)
    jr $ra
draw_post_doll_02: # start at v1, use t4
    li $t4 0x91003b
    draw64($t4, 1588, 1596, 1600, 1616, 2092, 2132, 2136, 2600, 2616, 2640, 2652, 3108, 3124, 3144, 3160, 3168, 3620, 3632, 3660, 4128, 4144, 4160, 4172, 4196, 4640, 4672, 4700, 4708, 5148, 5152, 5184, 5200, 5208, 5212, 5220, 5660, 5664, 5680, 5684, 5696, 5700, 5708, 5716, 5720, 5724, 5732, 6168, 6172, 6176, 6192, 6196, 6204, 6216, 6232, 6236, 6244, 6680, 6684, 6688, 6692, 6700, 6744, 6748, 6752)
    draw64($t4, 6756, 7192, 7196, 7200, 7204, 7212, 7224, 7260, 7264, 7268, 7704, 7708, 7712, 7716, 7724, 7736, 7772, 7776, 8216, 8220, 8228, 8236, 8240, 8280, 8284, 8288, 8728, 8732, 8740, 8744, 8748, 8752, 8756, 8784, 8788, 8792, 8796, 8800, 9244, 9252, 9256, 9260, 9308, 9312, 9764, 9768, 9824, 10272, 10276, 10336, 10340, 10852, 11824, 12328, 12332, 12372, 12376, 12832, 12836, 12840, 12884, 12888, 12892, 13340)
    draw4($t4, 13344, 13348, 13400, 13408)
    draw4($t4, 13412, 13852, 13856, 13912)
    sw $t4 13924($v1)
    sw $t4 14364($v1)
    sw $t4 14436($v1)
    li $t4 0xda7141
    draw16($t4, 1592, 1604, 1608, 1612, 2096, 2108, 2112, 2124, 2128, 2604, 2644, 3112, 3148, 3648, 3672, 3680)
    draw4($t4, 4132, 4148, 4188, 4656)
    draw4($t4, 4688, 5168, 5188, 5692)
    draw4($t4, 6180, 6188, 6240, 6712)
    sw $t4 7720($v1)
    sw $t4 8232($v1)
    li $t4 0xfaa753
    draw16($t4, 2100, 2104, 2116, 2120, 2608, 2612, 2648, 3116, 3152, 3156, 3164, 3624, 3644, 3656, 4176, 4644)
    draw4($t4, 4684, 4696, 5156, 5164)
    draw4($t4, 5180, 5196, 5668, 5676)
    draw4($t4, 5728, 6184, 6200, 6696)
    sw $t4 7208($v1)
    li $t4 0xd1003f
    draw4($t4, 2620, 2624, 2628, 2632)
    draw4($t4, 2636, 3128, 3132, 3136)
    draw4($t4, 3140, 3636, 11336, 11848)
    sw $t4 12360($v1)
    sw $t4 12368($v1)
    li $t4 0xfaff53
    draw16($t4, 3120, 3628, 3640, 3652, 3664, 3668, 3676, 4136, 4140, 4152, 4156, 4164, 4168, 4180, 4184, 4192)
    draw16($t4, 4648, 4652, 4660, 4664, 4668, 4676, 4680, 4692, 4704, 5160, 5172, 5176, 5192, 5204, 5216, 5672)
    sw $t4 5688($v1)
    sw $t4 5704($v1)
    li $t4 0xffaa73
    draw4($t4, 5712, 6220, 6224, 6728)
    draw4($t4, 6732, 6736, 7248, 7732)
    sw $t4 8248($v1)
    sw $t4 8272($v1)
    li $t4 0x2b1408
    draw4($t4, 6208, 6212, 6228, 18472)
    draw4($t4, 18488, 18984, 18988, 18992)
    draw4($t4, 19000, 19004, 19008, 19500)
    sw $t4 19504($v1)
    sw $t4 19516($v1)
    sw $t4 19520($v1)
    li $t4 0xbd6455
    draw16($t4, 6704, 6708, 7216, 7256, 7728, 7768, 8244, 8276, 8764, 8768, 8772, 8776, 8780, 11800, 11872, 12312)
    sw $t4 12320($v1)
    sw $t4 12380($v1)
    sw $t4 12828($v1)
    li $t4 0xaa90e0
    draw64($t4, 6716, 8296, 8300, 8708, 8712, 8716, 8720, 8804, 8808, 8812, 9216, 9236, 9240, 9268, 9296, 9300, 9316, 9320, 9324, 9728, 9756, 9760, 9788, 9792, 9816, 9828, 9832, 10240, 10296, 10300, 10328, 10332, 10756, 10760, 10764, 10768, 10772, 10776, 10780, 10808, 10812, 10820, 10828, 10856, 10860, 11272, 11276, 11280, 11296, 11320, 11324, 11328, 11368, 11372, 11780, 12288, 12340, 12800, 12816, 12820, 12856, 12860, 12876, 13316)
    draw4($t4, 13320, 13324, 13880, 13892)
    draw4($t4, 13900, 14400, 14416, 14928)
    draw4($t4, 15416, 15420, 15424, 15428)
    sw $t4 15432($v1)
    sw $t4 15436($v1)
    sw $t4 18476($v1)
    li $t4 0x10309c
    draw16($t4, 6720, 6724, 6740, 7232, 7252, 7764, 10284, 10788, 10796, 10800, 10844, 11308, 11352, 11356, 11360, 11804)
    draw16($t4, 11812, 11816, 12848, 13356, 13360, 13364, 13864, 13868, 13872, 13908, 14372, 14376, 14380, 14384, 14420, 14884)
    draw16($t4, 14888, 14892, 14936, 15396, 15400, 15404, 15448, 15908, 15912, 15916, 15920, 15924, 15960, 16420, 16424, 16428)
    draw4($t4, 16432, 16472, 16936, 16940)
    draw4($t4, 16944, 17464, 17468, 17472)
    sw $t4 17476($v1)
    sw $t4 17480($v1)
    sw $t4 17484($v1)
    li $t4 0xfde3b2
    draw4($t4, 7220, 7240, 7244, 7740)
    draw4($t4, 7748, 7752, 7756, 7760)
    draw4($t4, 8252, 8256, 8260, 8264)
    sw $t4 8268($v1)
    sw $t4 12316($v1)
    sw $t4 12384($v1)
    li $t4 0xededff
    draw64($t4, 7228, 9220, 9224, 9228, 9232, 9732, 9736, 9740, 9744, 9748, 9752, 9776, 9780, 9784, 9804, 9808, 9812, 10244, 10248, 10252, 10256, 10260, 10264, 10268, 10292, 10304, 10308, 10316, 10320, 10324, 10816, 10832, 10836, 11284, 11288, 11784, 11788, 11792, 11796, 11808, 12292, 12296, 12300, 12304, 12308, 12804, 12808, 12812, 12864, 12868, 12872, 13896, 14392, 14396, 14404, 14408, 14412, 14900, 14904, 14908, 14912, 14916, 14920, 14924)
    li $t4 0x008bff
    draw16($t4, 7236, 7744, 10792, 11300, 11304, 15928, 15932, 15936, 15940, 15944, 15948, 15952, 15956, 16436, 16440, 16444)
    draw4($t4, 16448, 16452, 16456, 16460)
    draw4($t4, 16464, 16468, 16948, 16952)
    draw4($t4, 16956, 16960, 16964, 16968)
    sw $t4 16972($v1)
    sw $t4 16976($v1)
    sw $t4 16980($v1)
    li $t4 0x0b0064
    draw16($t4, 8760, 9276, 9280, 9284, 9288, 10280, 10784, 10848, 11312, 11316, 11348, 11364, 11820, 11832, 11836, 11860)
    draw16($t4, 11864, 12336, 12844, 13352, 13396, 13860, 14368, 14424, 14880, 15392, 15452, 15904, 15964, 16416, 16476, 16932)
    draw4($t4, 16984, 17452, 17456, 17460)
    sw $t4 17488($v1)
    li $t4 0x674da7
    draw16($t4, 9264, 9272, 9292, 9304, 9772, 9796, 9800, 9820, 10288, 10804, 10840, 11292, 11828, 12324, 12344, 12348)
    draw16($t4, 12852, 12880, 13368, 13372, 13376, 13380, 13384, 13388, 13392, 13876, 13884, 13888, 13904, 14388, 14896, 14932)
    draw4($t4, 15408, 15412, 15440, 15444)
    draw4($t4, 17964, 17968, 17976, 17980)
    sw $t4 18480($v1)
    sw $t4 18492($v1)
    li $t4 0x4d0027
    draw4($t4, 10312, 10824, 11332, 11340)
    draw4($t4, 11344, 11840, 11852, 12352)
    sw $t4 12364($v1)
    draw16($0, 10344, 10348, 11264, 11268, 11776, 11880, 11884, 12392, 13328, 13332, 13336, 13404, 13824, 13828, 13832, 13836)
    draw16($0, 13840, 13844, 13848, 13916, 13920, 14336, 14340, 14344, 14348, 14352, 14356, 14428, 14432, 14848, 14852, 14856)
    draw16($0, 14860, 14940, 14944, 17444, 17448, 17492, 17496, 17972, 17984, 17988, 17992, 17996, 18000, 19496, 19512, 20012)
    sw $0 20016($v1)
    sw $0 20028($v1)
    sw $0 20032($v1)
    li $t4 0x880033
    sw $t4 11844($v1)
    sw $t4 11856($v1)
    sw $t4 12356($v1)
    li $t4 0x7a3332
    draw4($t4, 11868, 11876, 12388, 12824)
    sw $t4 12896($v1)
    sw $t4 12900($v1)
    jr $ra
draw_post_doll_03: # start at v1, use t4
    draw64($0, 1588, 1592, 1596, 1600, 1604, 1608, 1612, 1616, 2092, 2096, 2100, 2104, 2108, 2112, 2116, 2120, 2124, 2128, 2132, 2136, 2600, 2604, 2608, 2612, 2616, 2620, 2624, 2628, 2632, 2636, 2640, 2644, 2648, 2652, 3108, 3112, 3116, 3120, 3156, 3160, 3164, 3168, 3620, 3624, 3676, 3680, 4128, 4132, 4192, 4196, 4640, 4708, 5148, 5220, 6168, 8296, 8300, 8808, 8812, 9316, 10860, 11364, 11368, 11372)
    draw16($0, 11780, 12288, 12292, 12296, 12300, 12304, 12308, 12800, 12804, 12808, 12812, 12816, 12820, 12824, 13316, 13320)
    sw $0 13324($v1)
    sw $0 15452($v1)
    li $t4 0x91003b
    draw64($t4, 3124, 3132, 3136, 3152, 3628, 3668, 3672, 4136, 4152, 4176, 4188, 4644, 4660, 4696, 4704, 5152, 5156, 5168, 5184, 5196, 5660, 5664, 5712, 5732, 6172, 6176, 6204, 6208, 6212, 6216, 6220, 6224, 6232, 6244, 6680, 6688, 6708, 6716, 6732, 6740, 6744, 6756, 7192, 7200, 7216, 7220, 7256, 7260, 7268, 7700, 7712, 7728, 7732, 7768, 7772, 7780, 8216, 8220, 8224, 8236, 8280, 8284, 8288, 8292)
    draw64($t4, 8732, 8736, 8744, 8748, 8796, 8800, 8804, 9248, 9252, 9256, 9260, 9308, 9312, 9760, 9764, 9768, 9772, 9776, 9816, 9820, 9824, 10268, 10272, 10276, 10280, 10284, 10288, 10292, 10320, 10324, 10328, 10332, 10336, 10780, 10788, 10792, 10796, 10844, 10848, 11300, 11304, 11360, 11808, 11812, 11872, 11876, 12388, 13360, 13864, 13868, 13904, 13908, 13912, 13916, 14368, 14372, 14376, 14420, 14424, 14428, 14432, 14876, 14880, 14884)
    draw4($t4, 14936, 14944, 14948, 15388)
    draw4($t4, 15392, 15460, 15900, 15972)
    li $t4 0xda7141
    draw16($t4, 3128, 3140, 3144, 3148, 3632, 3644, 3648, 3660, 3664, 4140, 4180, 4648, 4684, 5208, 5216, 5668)
    draw16($t4, 5680, 5696, 5708, 6200, 6236, 6684, 6704, 6748, 7196, 7204, 7212, 7704, 7708, 7716, 7724, 7776)
    sw $t4 8228($v1)
    sw $t4 8232($v1)
    sw $t4 8740($v1)
    li $t4 0xfaa753
    draw16($t4, 3636, 3640, 3652, 3656, 4144, 4148, 4184, 4652, 4692, 4700, 5160, 5180, 5672, 5724, 6180, 6192)
    draw4($t4, 6692, 6700, 7264, 7720)
    sw $t4 7736($v1)
    li $t4 0xd1003f
    draw4($t4, 4156, 4160, 4164, 4172)
    draw4($t4, 4664, 4672, 4676, 5172)
    draw4($t4, 12864, 12868, 12872, 12880)
    sw $t4 13384($v1)
    li $t4 0xfaff53
    draw16($t4, 4168, 4656, 4668, 4680, 4688, 5164, 5176, 5188, 5192, 5200, 5204, 5212, 5676, 5684, 5688, 5692)
    draw4($t4, 5700, 5704, 5716, 5720)
    draw4($t4, 5728, 6184, 6188, 6196)
    draw4($t4, 6228, 6240, 6696, 6752)
    sw $t4 7208($v1)
    li $t4 0xbd6455
    draw16($t4, 6712, 6720, 6724, 6728, 6736, 7224, 7252, 7752, 8240, 8244, 8264, 8752, 8792, 9264, 9304, 9780)
    draw4($t4, 9812, 10300, 10304, 10308)
    draw4($t4, 10312, 10316, 13336, 13412)
    draw4($t4, 13848, 13856, 13920, 14364)
    li $t4 0xaa90e0
    draw64($t4, 7168, 7172, 7176, 7180, 7680, 7696, 8192, 8212, 8252, 8708, 8728, 9216, 9220, 9224, 9228, 9244, 9320, 9324, 9728, 9740, 9744, 9748, 9752, 9756, 9828, 9832, 9836, 10240, 10260, 10264, 10340, 10344, 10348, 10752, 10776, 10784, 10804, 10852, 10856, 11268, 11292, 11296, 11328, 11784, 11788, 11792, 11796, 11828, 11856, 11860, 11864, 11868, 11880, 11884, 12312, 12316, 12396, 12832, 13876, 14392, 14396, 14400, 14404, 14408)
    draw4($t4, 14412, 14900, 14928, 15420)
    draw4($t4, 15424, 15428, 15432, 15444)
    draw4($t4, 15928, 15932, 15936, 15940)
    sw $t4 15944($v1)
    sw $t4 15948($v1)
    sw $t4 15952($v1)
    li $t4 0xffaa73
    draw16($t4, 7228, 7232, 7236, 7240, 7244, 7248, 7756, 7760, 8268, 8272, 8760, 8784, 9268, 9272, 9784, 9808)
    li $t4 0xededff
    draw16($t4, 7684, 7688, 7692, 8196, 8200, 8204, 8208, 8712, 8716, 8720, 8724, 8764, 9232, 9236, 9240, 9732)
    draw16($t4, 9736, 10244, 10248, 10252, 10256, 10756, 10760, 10764, 10768, 10772, 10832, 10836, 11272, 11276, 11280, 11284)
    draw16($t4, 11288, 11312, 11316, 11320, 11324, 11340, 11344, 11348, 11352, 11800, 11804, 11832, 11836, 11840, 11844, 13344)
    draw4($t4, 14904, 14908, 14912, 14916)
    draw4($t4, 14920, 14924, 15412, 15416)
    sw $t4 15436($v1)
    sw $t4 15440($v1)
    li $t4 0x2b1408
    draw4($t4, 7740, 7744, 7748, 7764)
    draw4($t4, 8248, 19496, 19500, 19504)
    draw4($t4, 19512, 19516, 19520, 20012)
    sw $t4 20016($v1)
    sw $t4 20028($v1)
    sw $t4 20032($v1)
    li $t4 0x10309c
    draw64($t4, 8256, 8260, 8276, 8768, 8788, 9300, 11820, 12324, 12332, 12336, 12380, 12844, 12888, 12892, 12896, 12900, 13340, 13348, 13352, 13404, 14384, 14892, 15400, 15404, 15908, 15912, 15916, 15960, 16416, 16420, 16424, 16428, 16432, 16436, 16440, 16444, 16448, 16452, 16456, 16460, 16464, 16468, 16472, 16928, 16932, 16936, 16940, 16944, 16948, 16980, 16984, 16988, 17440, 17444, 17448, 17452, 17456, 17496, 17500, 17952, 17956, 17960, 17964, 18008)
    draw4($t4, 18012, 18468, 18472, 18476)
    draw4($t4, 18480, 19000, 19004, 19008)
    sw $t4 19012($v1)
    sw $t4 19016($v1)
    sw $t4 19020($v1)
    li $t4 0xfde3b2
    draw4($t4, 8756, 8776, 8780, 9276)
    draw4($t4, 9284, 9288, 9292, 9296)
    draw4($t4, 9788, 9792, 9796, 9800)
    sw $t4 9804($v1)
    sw $t4 13852($v1)
    sw $t4 13924($v1)
    li $t4 0x008bff
    draw16($t4, 8772, 9280, 12328, 12836, 12840, 16952, 16956, 16960, 16964, 16968, 16972, 16976, 17460, 17464, 17468, 17472)
    draw16($t4, 17476, 17480, 17484, 17488, 17492, 17968, 17972, 17976, 17980, 17984, 17988, 17992, 17996, 18000, 18004, 18484)
    draw4($t4, 18488, 18492, 18496, 18500)
    draw4($t4, 18504, 18508, 18512, 18516)
    li $t4 0x0b0064
    draw16($t4, 10296, 10812, 10816, 10820, 10824, 11816, 12320, 12384, 12848, 12852, 12856, 12904, 13356, 13368, 13372, 13376)
    draw16($t4, 13396, 13400, 13408, 13872, 14380, 14888, 15396, 15448, 15904, 15964, 16412, 16476, 16924, 16992, 17436, 17504)
    draw4($t4, 17948, 18016, 18464, 18520)
    draw4($t4, 18524, 18980, 18984, 18988)
    sw $t4 18992($v1)
    sw $t4 18996($v1)
    sw $t4 19024($v1)
    li $t4 0x674da7
    draw16($t4, 10800, 10808, 10828, 10840, 11308, 11332, 11336, 11356, 11824, 12340, 12344, 12348, 12352, 12376, 12828, 13364)
    draw4($t4, 13860, 13880, 13884, 13888)
    draw4($t4, 13892, 13896, 13900, 14388)
    draw4($t4, 14416, 14896, 14932, 15408)
    sw $t4 15920($v1)
    sw $t4 15924($v1)
    sw $t4 15956($v1)
    li $t4 0x4d0027
    draw4($t4, 11848, 11852, 12356, 12360)
    draw4($t4, 12364, 12368, 12372, 12860)
    draw4($t4, 12876, 12884, 13388, 13392)
    li $t4 0x880033
    sw $t4 13380($v1)
    li $t4 0x7a3332
    draw4($t4, 13416, 13928, 14360, 14436)
    sw $t4 14440($v1)
    jr $ra
draw_post_doll_04: # start at v1, use t4
    li $t4 0x91003b
    draw64($t4, 56, 64, 68, 84, 560, 600, 604, 1068, 1084, 1108, 1120, 1576, 1592, 1612, 1628, 1636, 2088, 2100, 2128, 2596, 2628, 2640, 2664, 3108, 3128, 3140, 3152, 3164, 3176, 3620, 3640, 3652, 3664, 3672, 3676, 3688, 4132, 4148, 4152, 4160, 4164, 4168, 4176, 4180, 4184, 4188, 4200, 4660, 4664, 4684, 4692, 4700, 5160, 5168, 5212, 5220, 5672, 5680, 5692, 5728, 5732, 6184, 6192, 6204)
    draw16($t4, 6240, 6696, 6704, 6708, 6748, 6752, 7208, 7212, 7216, 7220, 7224, 7252, 7256, 7260, 7264, 7720)
    draw16($t4, 7724, 7728, 7776, 8232, 8236, 8740, 8744, 8804, 8808, 9320, 10292, 10796, 10800, 10840, 10844, 11300)
    draw16($t4, 11304, 11308, 11352, 11356, 11360, 11364, 11808, 11812, 11816, 11868, 11876, 11880, 12320, 12324, 12328, 12380)
    sw $t4 12392($v1)
    sw $t4 12832($v1)
    sw $t4 12904($v1)
    li $t4 0xda7141
    draw16($t4, 60, 72, 76, 80, 564, 576, 580, 592, 596, 1072, 1112, 1580, 1616, 1624, 2116, 2136)
    draw16($t4, 2140, 2148, 2600, 2616, 2652, 3112, 3160, 3624, 3636, 3648, 4136, 4196, 4648, 4656, 4708, 5180)
    sw $t4 5216($v1)
    sw $t4 6188($v1)
    sw $t4 6700($v1)
    li $t4 0xfaa753
    draw16($t4, 568, 572, 584, 588, 1076, 1080, 1116, 1584, 1620, 1632, 2092, 2112, 2124, 2604, 2624, 2636)
    draw16($t4, 2648, 2660, 3116, 3124, 3136, 3148, 3172, 3628, 3660, 3684, 4140, 4172, 4652, 4668, 4704, 5164)
    sw $t4 5676($v1)
    li $t4 0xd1003f
    draw4($t4, 1088, 1092, 1096, 1100)
    draw4($t4, 1104, 1596, 1600, 1604)
    draw4($t4, 1608, 2104, 9804, 10316)
    sw $t4 10828($v1)
    sw $t4 10836($v1)
    li $t4 0xfaff53
    draw16($t4, 1588, 2096, 2108, 2120, 2132, 2144, 2608, 2612, 2620, 2632, 2644, 2656, 3120, 3132, 3144, 3156)
    draw4($t4, 3168, 3632, 3644, 3656)
    draw4($t4, 3668, 3680, 4144, 4156)
    sw $t4 4192($v1)
    draw64($0, 4644, 5152, 5156, 5660, 5664, 5668, 6172, 6176, 6180, 6244, 6680, 6684, 6688, 6692, 6756, 7168, 7172, 7176, 7180, 7192, 7196, 7200, 7204, 7268, 7680, 7684, 7688, 7692, 7696, 7700, 7704, 7708, 7712, 7716, 8192, 8196, 8200, 8204, 8208, 8212, 8216, 8708, 9216, 9324, 9728, 10240, 10752, 10756, 11268, 11872, 12316, 12384, 12388, 12396, 12828, 12836, 12896, 12900, 13336, 13340, 13344, 13348, 13408, 13412)
    draw64($0, 13416, 13848, 13852, 13856, 13860, 13920, 13924, 13928, 14360, 14364, 14368, 14372, 14432, 14436, 14440, 14876, 14880, 14884, 14944, 14948, 15388, 15392, 15396, 15460, 15900, 15904, 15908, 15912, 15960, 15964, 15972, 16412, 16416, 16420, 16424, 16428, 16432, 16468, 16472, 16476, 16924, 16928, 16932, 16936, 16940, 16956, 16968, 16972, 16976, 16980, 16984, 16988, 16992, 17436, 17440, 17444, 17448, 17452, 17468, 17484, 17488, 17492, 17496, 17500)
    draw16($0, 17504, 17948, 17952, 17956, 17960, 17964, 17968, 17980, 17984, 17996, 18000, 18004, 18008, 18012, 18016, 18464)
    draw16($0, 18468, 18472, 18476, 18480, 18484, 18488, 18492, 18496, 18500, 18504, 18508, 18512, 18516, 18520, 18524, 18980)
    draw16($0, 18984, 18988, 18992, 18996, 19000, 19004, 19008, 19012, 19016, 19020, 19024, 19496, 19500, 19504, 19512, 19516)
    draw4($0, 19520, 20012, 20016, 20028)
    sw $0 20032($v1)
    li $t4 0x2b1408
    draw16($t4, 4672, 4676, 4680, 4696, 16944, 16960, 17456, 17460, 17464, 17472, 17476, 17480, 17972, 17976, 17988, 17992)
    li $t4 0xffaa73
    draw4($t4, 4688, 5196, 5200, 5204)
    draw4($t4, 5716, 6200, 6716, 6740)
    li $t4 0xbd6455
    draw16($t4, 5172, 5176, 5684, 5724, 6196, 6236, 6712, 6744, 7232, 7236, 7240, 7244, 7248, 10268, 10780, 10788)
    sw $t4 10856($v1)
    sw $t4 10860($v1)
    sw $t4 11296($v1)
    li $t4 0xaa90e0
    draw64($t4, 5184, 7736, 7764, 7768, 7780, 7784, 7788, 8220, 8224, 8228, 8256, 8260, 8284, 8292, 8296, 8300, 8304, 8712, 8716, 8720, 8724, 8728, 8736, 8764, 8796, 8800, 8812, 8816, 9220, 9244, 9248, 9276, 9288, 9304, 9732, 9752, 9756, 9764, 9788, 9840, 10244, 10256, 10260, 10264, 10308, 10760, 10764, 10768, 10772, 10808, 11272, 11324, 11328, 11344, 11780, 11804, 12292, 12308, 12312, 12348, 12352, 12356, 12368, 12804)
    draw4($t4, 12808, 12812, 12816, 12860)
    draw4($t4, 12868, 12880, 13372, 13392)
    draw4($t4, 13884, 13904, 14912, 14924)
    sw $t4 16948($v1)
    li $t4 0x10309c
    draw64($t4, 5188, 5192, 5208, 5700, 5720, 6232, 8752, 9256, 9264, 9268, 9312, 9776, 9820, 9824, 9828, 10272, 10280, 10284, 10336, 10340, 10344, 11316, 11824, 11828, 11832, 12336, 12340, 12344, 12376, 12844, 12848, 12852, 12856, 12888, 13356, 13360, 13364, 13368, 13400, 13404, 13868, 13872, 13876, 13880, 13916, 14380, 14384, 14388, 14392, 14420, 14428, 14892, 14896, 14900, 14908, 14928, 14940, 15404, 15408, 15412, 15424, 15436, 15924, 15928)
    sw $t4 15952($v1)
    li $t4 0xfde3b2
    draw4($t4, 5688, 5708, 5712, 6208)
    draw4($t4, 6216, 6220, 6224, 6228)
    draw4($t4, 6720, 6724, 6728, 6732)
    sw $t4 6736($v1)
    sw $t4 10784($v1)
    sw $t4 11372($v1)
    li $t4 0xededff
    draw64($t4, 5696, 8244, 8248, 8252, 8272, 8276, 8280, 8732, 8760, 8768, 8772, 8776, 8788, 8792, 9224, 9228, 9232, 9236, 9240, 9280, 9284, 9300, 9736, 9740, 9744, 9748, 9792, 9796, 9812, 10248, 10252, 10276, 10304, 10776, 11276, 11280, 11284, 11288, 11332, 11336, 11340, 11784, 11788, 11792, 11796, 11800, 12296, 12300, 12304, 12360, 12364, 12864, 12872, 12876, 13376, 13380, 13384, 13388, 13888, 13892, 13896, 13900, 14400, 14404)
    draw4($t4, 14408, 14412, 14916, 14920)
    li $t4 0x008bff
    draw16($t4, 5704, 6212, 9260, 9768, 9772, 13912, 14424, 14904, 14932, 14936, 15416, 15420, 15440, 15444, 15448, 15932)
    draw4($t4, 15936, 15940, 15944, 15948)
    li $t4 0x0b0064
    draw16($t4, 7228, 7744, 7748, 7752, 7756, 8748, 9252, 9316, 9780, 9784, 9832, 9836, 10288, 10300, 10328, 10332)
    draw16($t4, 10804, 10848, 10852, 11312, 11820, 11864, 12332, 12840, 12892, 13352, 13864, 14376, 14888, 15400, 15452, 15916)
    draw4($t4, 15920, 15956, 16436, 16440)
    draw4($t4, 16444, 16448, 16452, 16456)
    sw $t4 16460($v1)
    sw $t4 16464($v1)
    li $t4 0x674da7
    draw16($t4, 7732, 7740, 7760, 7772, 8240, 8264, 8268, 8288, 8756, 9272, 9308, 9760, 9816, 10296, 10792, 10812)
    draw16($t4, 10816, 11320, 11348, 11836, 11840, 11844, 11848, 11852, 11856, 11860, 12372, 12884, 13396, 13908, 14396, 14416)
    draw4($t4, 15428, 15432, 16952, 16964)
    li $t4 0x4d0027
    draw4($t4, 8780, 8784, 9292, 9296)
    draw4($t4, 9800, 9808, 10320, 10820)
    sw $t4 10832($v1)
    li $t4 0x880033
    sw $t4 10312($v1)
    sw $t4 10324($v1)
    sw $t4 10824($v1)
    li $t4 0x7a3332
    draw4($t4, 10348, 10352, 10864, 11292)
    sw $t4 11368($v1)
    sw $t4 11376($v1)
    sw $t4 11884($v1)
    jr $ra
draw_post_doll_05: # start at v1, use t4
    draw16($0, 56, 560, 1068, 1576, 2088, 2596, 3108, 3620, 4132, 7208, 7720, 8816, 9220, 9224, 9732, 9736)
    draw16($0, 9740, 10244, 10248, 11780, 11784, 11800, 11804, 11808, 11876, 12292, 12296, 12300, 12304, 12308, 12312, 12320)
    draw16($0, 12392, 12804, 12808, 12812, 12816, 12832, 12904, 15400, 15916, 15920, 16436, 16440, 16444, 16944, 16948, 16952)
    draw4($0, 17456, 17460, 17464, 17972)
    sw $0 17976($v1)
    li $t4 0x91003b
    draw64($t4, 60, 68, 72, 88, 564, 604, 608, 1072, 1088, 1112, 1124, 1580, 1596, 1616, 1632, 1640, 2092, 2104, 2132, 2600, 2632, 2644, 2668, 3112, 3132, 3144, 3156, 3160, 3168, 3180, 3624, 3644, 3656, 3668, 3672, 3680, 3692, 4136, 4152, 4156, 4164, 4168, 4172, 4180, 4188, 4192, 4196, 4204, 4648, 4664, 4668, 4688, 4704, 4708, 4716, 5160, 5164, 5172, 5216, 5220, 5224, 5228, 5672, 5676)
    draw64($t4, 5684, 5696, 5732, 5736, 5740, 6184, 6188, 6196, 6208, 6244, 6248, 6696, 6700, 6708, 6712, 6752, 6756, 6760, 7212, 7216, 7220, 7224, 7228, 7256, 7260, 7264, 7268, 7272, 7724, 7728, 7732, 7780, 7784, 8236, 8240, 8296, 8744, 8748, 8808, 8812, 9324, 10296, 10800, 10804, 10844, 10848, 10852, 11304, 11308, 11312, 11356, 11360, 11364, 11368, 11372, 11812, 11816, 11820, 11872, 11880, 11884, 12324, 12328, 12384)
    sw $t4 12396($v1)
    sw $t4 12836($v1)
    sw $t4 12908($v1)
    li $t4 0xda7141
    draw16($t4, 64, 76, 80, 84, 568, 580, 584, 596, 600, 1076, 1116, 1584, 1620, 2120, 2136, 2144)
    draw16($t4, 2152, 2604, 2620, 2648, 2656, 3172, 3640, 3652, 3660, 3684, 4652, 4660, 4712, 5184, 6192, 6704)
    li $t4 0xfaa753
    draw16($t4, 572, 576, 588, 592, 1080, 1084, 1120, 1588, 1624, 1628, 1636, 2096, 2116, 2128, 2608, 2660)
    draw4($t4, 3116, 3128, 3140, 3148)
    draw4($t4, 3628, 3636, 4140, 4148)
    draw4($t4, 4200, 4656, 4672, 5168)
    sw $t4 5680($v1)
    li $t4 0xd1003f
    draw4($t4, 1092, 1096, 1100, 1104)
    draw4($t4, 1108, 1600, 1604, 1608)
    draw4($t4, 1612, 2108, 9808, 10320)
    sw $t4 10828($v1)
    sw $t4 10836($v1)
    sw $t4 10840($v1)
    li $t4 0xfaff53
    draw16($t4, 1592, 2100, 2112, 2124, 2140, 2148, 2612, 2616, 2624, 2628, 2636, 2640, 2652, 2664, 3120, 3124)
    draw4($t4, 3136, 3152, 3164, 3176)
    draw4($t4, 3632, 3648, 3664, 3676)
    draw4($t4, 3688, 4144, 4160, 4176)
    li $t4 0xffaa73
    draw4($t4, 4184, 4692, 4696, 5200)
    draw4($t4, 5204, 5208, 5720, 6204)
    sw $t4 6720($v1)
    sw $t4 6744($v1)
    li $t4 0x2b1408
    draw16($t4, 4676, 4680, 4684, 4700, 16960, 16972, 16980, 17472, 17476, 17480, 17484, 17488, 17492, 17988, 17992, 18000)
    sw $t4 18004($v1)
    li $t4 0xbd6455
    draw16($t4, 5176, 5180, 5688, 5728, 6200, 6240, 6716, 6748, 7236, 7240, 7244, 7248, 7252, 10272, 10784, 10792)
    sw $t4 10860($v1)
    sw $t4 10864($v1)
    sw $t4 11300($v1)
    li $t4 0xaa90e0
    draw64($t4, 5188, 6768, 6772, 7176, 7180, 7184, 7276, 7280, 7284, 7688, 7700, 7704, 7708, 7712, 7740, 7768, 7772, 7788, 7792, 7796, 8200, 8228, 8232, 8260, 8264, 8288, 8300, 8304, 8712, 8800, 8804, 9228, 9232, 9236, 9240, 9244, 9248, 9252, 9280, 9284, 9292, 9304, 9328, 9332, 9744, 9748, 9752, 9768, 9792, 9796, 9800, 9844, 10252, 10760, 10812, 11272, 11288, 11292, 11328, 11332, 11348, 11788, 11792, 11796)
    draw4($t4, 12352, 12356, 12360, 12372)
    draw4($t4, 12864, 12872, 12888, 13376)
    draw4($t4, 13400, 13912, 14420, 14920)
    sw $t4 14924($v1)
    sw $t4 14928($v1)
    sw $t4 16964($v1)
    li $t4 0x10309c
    draw64($t4, 5192, 5196, 5212, 5704, 5724, 6236, 8756, 9260, 9268, 9272, 9316, 9780, 9824, 9828, 9832, 9836, 9840, 10276, 10284, 10288, 10340, 10344, 10348, 10856, 11320, 11828, 11832, 11836, 12336, 12340, 12344, 12380, 12844, 12848, 12852, 12856, 12892, 13356, 13360, 13364, 13368, 13404, 13408, 13868, 13872, 13876, 13880, 13920, 14380, 14384, 14388, 14392, 14396, 14432, 14436, 14892, 14896, 14900, 14904, 14912, 14944, 14948, 15408, 15412)
    draw4($t4, 15416, 15936, 15940, 15944)
    sw $t4 15948($v1)
    sw $t4 15952($v1)
    sw $t4 15956($v1)
    li $t4 0xfde3b2
    draw4($t4, 5692, 5712, 5716, 6212)
    draw4($t4, 6220, 6224, 6228, 6232)
    draw4($t4, 6724, 6728, 6732, 6736)
    sw $t4 6740($v1)
    sw $t4 10788($v1)
    li $t4 0xededff
    draw64($t4, 5700, 7692, 7696, 8204, 8208, 8212, 8216, 8220, 8224, 8248, 8252, 8256, 8276, 8280, 8284, 8716, 8720, 8724, 8728, 8732, 8736, 8740, 8764, 8768, 8772, 8776, 8780, 8792, 8796, 9288, 9308, 9756, 9760, 10256, 10260, 10264, 10268, 10280, 10764, 10768, 10772, 10776, 10780, 11276, 11280, 11284, 11336, 11340, 11344, 12364, 12368, 12868, 12876, 12880, 12884, 13380, 13384, 13388, 13392, 13396, 13888, 13892, 13896, 13900)
    draw4($t4, 13904, 13908, 14404, 14408)
    sw $t4 14412($v1)
    sw $t4 14416($v1)
    li $t4 0x008bff
    draw16($t4, 5708, 6216, 9264, 9772, 9776, 13916, 14424, 14428, 14908, 14932, 14936, 14940, 15420, 15424, 15428, 15432)
    draw4($t4, 15436, 15440, 15444, 15448)
    sw $t4 15452($v1)
    li $t4 0x0b0064
    draw16($t4, 7232, 7748, 7752, 7756, 7760, 8752, 9256, 9320, 9784, 9788, 9820, 10292, 10304, 10308, 10332, 10336)
    draw16($t4, 10808, 11316, 11824, 11868, 12332, 12840, 12896, 13352, 13864, 13924, 14376, 14888, 15404, 15456, 15924, 15928)
    sw $t4 15932($v1)
    sw $t4 15960($v1)
    li $t4 0x674da7
    draw16($t4, 7736, 7744, 7764, 7776, 8244, 8268, 8272, 8292, 8760, 9276, 9312, 9764, 10300, 10796, 10816, 10820)
    draw16($t4, 11324, 11352, 11840, 11844, 11848, 11852, 11856, 11860, 11864, 12348, 12376, 12860, 13372, 13884, 14400, 14916)
    draw4($t4, 16448, 16452, 16456, 16460)
    sw $t4 16464($v1)
    sw $t4 16968($v1)
    sw $t4 16976($v1)
    li $t4 0x4d0027
    draw4($t4, 8784, 8788, 9296, 9300)
    draw4($t4, 9804, 9812, 9816, 10312)
    sw $t4 10324($v1)
    sw $t4 10824($v1)
    li $t4 0x880033
    sw $t4 10316($v1)
    sw $t4 10328($v1)
    sw $t4 10832($v1)
    li $t4 0x7a3332
    draw4($t4, 10352, 10356, 10868, 11296)
    sw $t4 11376($v1)
    sw $t4 11380($v1)
    jr $ra
draw_post_doll_06: # start at v1, use t4
    draw16($0, 60, 64, 68, 72, 76, 80, 84, 88, 564, 568, 572, 608, 1072, 1076, 1580, 1584)
    draw16($0, 2092, 2600, 2604, 3112, 3624, 6768, 7176, 7688, 7692, 8200, 8712, 10252, 10256, 10760, 10764, 10768)
    draw16($0, 10772, 10776, 11272, 11276, 11280, 11284, 11288, 11788, 11792, 11796, 12836, 12908, 16960, 16964, 17472, 17476)
    sw $0 17988($v1)
    li $t4 0x91003b
    draw64($t4, 576, 584, 588, 604, 1080, 1120, 1124, 1588, 1604, 1628, 1640, 2096, 2112, 2132, 2148, 2156, 2608, 2620, 2648, 3116, 3132, 3148, 3160, 3184, 3628, 3660, 3688, 4136, 4172, 4188, 4196, 4200, 4212, 4648, 4668, 4672, 4684, 4688, 4696, 4704, 4708, 4712, 4724, 5156, 5160, 5180, 5184, 5192, 5204, 5220, 5224, 5232, 5236, 5668, 5672, 5680, 5688, 5732, 5736, 5740, 5744, 5748, 6180, 6184)
    draw64($t4, 6192, 6200, 6212, 6248, 6252, 6256, 6692, 6696, 6700, 6704, 6712, 6724, 6760, 6764, 7208, 7212, 7216, 7224, 7228, 7268, 7272, 7276, 7728, 7732, 7736, 7740, 7744, 7772, 7776, 7780, 7784, 7788, 8244, 8248, 8252, 8296, 8300, 8756, 8760, 8812, 9264, 9268, 9324, 9328, 9772, 9840, 10280, 10780, 10784, 10788, 11292, 11296, 11300, 11320, 11360, 11364, 11368, 11804, 11808, 11812, 11824, 11828, 11872, 11876)
    draw16($t4, 11880, 11884, 11888, 12316, 12320, 12324, 12328, 12332, 12336, 12388, 12396, 12400, 12828, 12832, 12840, 12844)
    draw4($t4, 12900, 12912, 13340, 13352)
    sw $t4 13424($v1)
    li $t4 0xda7141
    draw16($t4, 580, 592, 596, 600, 1084, 1096, 1100, 1112, 1116, 1592, 1632, 2100, 2136, 2636, 2660, 2668)
    draw16($t4, 3120, 3136, 3176, 3644, 3676, 3696, 4140, 4156, 4176, 4652, 4680, 4716, 5168, 5176, 5228, 5700)
    sw $t4 6188($v1)
    sw $t4 6708($v1)
    sw $t4 7220($v1)
    li $t4 0xfaa753
    draw16($t4, 1088, 1092, 1104, 1108, 1596, 1600, 1636, 2104, 2140, 2144, 2152, 2612, 2632, 2644, 3164, 3632)
    draw16($t4, 3672, 3684, 4148, 4152, 4168, 4184, 4208, 4656, 4660, 4664, 4720, 5164, 5172, 5188, 5676, 5684)
    sw $t4 6196($v1)
    li $t4 0xd1003f
    draw4($t4, 1608, 1612, 1616, 1620)
    draw4($t4, 1624, 2116, 2120, 2124)
    draw4($t4, 2128, 2624, 10324, 10832)
    sw $t4 11344($v1)
    sw $t4 11352($v1)
    li $t4 0xfaff53
    draw16($t4, 2108, 2616, 2628, 2640, 2652, 2656, 2664, 3124, 3128, 3140, 3144, 3152, 3156, 3168, 3172, 3180)
    draw16($t4, 3636, 3640, 3648, 3652, 3656, 3664, 3668, 3680, 3692, 4144, 4160, 4164, 4180, 4192, 4204, 4676)
    sw $t4 4692($v1)
    li $t4 0xffaa73
    draw4($t4, 4700, 5208, 5212, 5716)
    draw4($t4, 5720, 5724, 6236, 6720)
    sw $t4 7236($v1)
    sw $t4 7260($v1)
    li $t4 0x2b1408
    draw4($t4, 5196, 5200, 5216, 17480)
    draw4($t4, 17492, 17992, 17996, 18000)
    draw4($t4, 18004, 18008, 18012, 18508)
    sw $t4 18512($v1)
    sw $t4 18520($v1)
    sw $t4 18524($v1)
    li $t4 0xaa90e0
    draw64($t4, 5644, 5648, 5652, 5704, 6156, 6168, 6172, 6668, 6688, 6772, 6776, 7180, 7204, 7280, 7284, 7288, 7696, 7700, 7720, 7724, 7792, 7796, 7800, 8204, 8208, 8212, 8216, 8220, 8236, 8240, 8260, 8284, 8288, 8304, 8308, 8716, 8736, 8740, 8752, 8780, 8792, 8804, 8824, 9228, 9256, 9260, 9320, 9332, 9336, 9744, 9768, 9800, 9804, 9820, 9824, 9844, 10260, 10264, 10268, 10272, 10276, 10288, 11328, 11844)
    draw16($t4, 11848, 11864, 12868, 12872, 12876, 12888, 13380, 13388, 13404, 13916, 14428, 14936, 15436, 15440, 15444, 17484)
    li $t4 0xbd6455
    draw16($t4, 5692, 5696, 6204, 6244, 6716, 6756, 7232, 7264, 7752, 7756, 7760, 7764, 7768, 10792, 11304, 11312)
    sw $t4 11380($v1)
    sw $t4 11820($v1)
    li $t4 0x10309c
    draw64($t4, 5708, 5712, 5728, 6220, 6240, 6752, 9276, 9780, 9788, 9792, 9832, 10300, 10340, 10344, 10348, 10352, 10356, 10796, 10804, 10808, 10856, 10860, 10864, 10868, 11372, 11376, 11836, 12344, 12348, 12352, 12852, 12856, 12860, 12896, 13360, 13364, 13368, 13372, 13408, 13868, 13872, 13876, 13880, 13884, 13920, 13924, 14380, 14384, 14388, 14392, 14396, 14436, 14892, 14896, 14900, 14904, 14912, 14952, 15404, 15408, 15412, 15428, 15464, 15920)
    draw4($t4, 15924, 15928, 16452, 16456)
    draw4($t4, 16460, 16464, 16468, 16472)
    li $t4 0xededff
    draw64($t4, 6160, 6164, 6216, 6672, 6676, 6680, 6684, 7184, 7188, 7192, 7196, 7200, 7704, 7708, 7712, 7716, 8224, 8228, 8232, 8720, 8724, 8728, 8732, 8744, 8748, 8768, 8772, 8776, 8796, 8800, 9232, 9236, 9240, 9244, 9248, 9252, 9284, 9288, 9292, 9296, 9308, 9312, 9316, 9748, 9752, 9756, 9760, 9764, 9808, 10800, 11852, 11856, 11860, 12880, 12884, 13384, 13392, 13396, 13400, 13892, 13896, 13900, 13904, 13908)
    draw4($t4, 13912, 14404, 14408, 14412)
    draw4($t4, 14416, 14420, 14424, 14920)
    sw $t4 14924($v1)
    sw $t4 14928($v1)
    sw $t4 14932($v1)
    li $t4 0xfde3b2
    draw4($t4, 6208, 6228, 6232, 6728)
    draw4($t4, 6736, 6740, 6744, 6748)
    draw4($t4, 7240, 7244, 7248, 7252)
    sw $t4 7256($v1)
    sw $t4 11308($v1)
    li $t4 0x008bff
    draw16($t4, 6224, 6732, 9784, 10292, 10296, 14432, 14908, 14940, 14944, 14948, 15416, 15420, 15424, 15448, 15452, 15456)
    draw4($t4, 15460, 15932, 15936, 15940)
    draw4($t4, 15944, 15948, 15952, 15956)
    sw $t4 15960($v1)
    sw $t4 15964($v1)
    sw $t4 15968($v1)
    li $t4 0x0b0064
    draw16($t4, 7748, 8268, 8272, 8276, 9272, 9776, 9836, 10304, 10308, 10336, 10812, 10820, 10824, 10848, 10852, 11324)
    draw16($t4, 11832, 12340, 12384, 12848, 13356, 13412, 13864, 14376, 14440, 14888, 15400, 15916, 15972, 16436, 16440, 16444)
    sw $t4 16448($v1)
    sw $t4 16476($v1)
    li $t4 0x674da7
    draw16($t4, 8256, 8264, 8280, 8292, 8764, 8784, 8788, 8808, 9280, 9796, 9828, 10284, 10312, 10316, 10816, 11316)
    draw16($t4, 11332, 11336, 11840, 11868, 12356, 12360, 12364, 12368, 12372, 12376, 12380, 12864, 12892, 13376, 13888, 14400)
    draw4($t4, 14916, 15432, 16968, 16972)
    draw4($t4, 16976, 16980, 16984, 17488)
    sw $t4 17496($v1)
    li $t4 0x4d0027
    draw4($t4, 9300, 9304, 9812, 9816)
    draw4($t4, 10320, 10328, 10332, 10828)
    draw4($t4, 10840, 11340, 11348, 11356)
    li $t4 0x880033
    sw $t4 10836($v1)
    sw $t4 10844($v1)
    li $t4 0x7a3332
    draw4($t4, 10872, 11384, 11816, 11892)
    sw $t4 11896($v1)
    jr $ra
draw_post_doll_07: # start at v1, use t4
    draw64($0, 576, 580, 584, 588, 592, 596, 600, 604, 1080, 1084, 1088, 1092, 1096, 1100, 1104, 1108, 1112, 1116, 1120, 1124, 1588, 1592, 1596, 1600, 1636, 1640, 2096, 2100, 2104, 2156, 2608, 2612, 3116, 3120, 3628, 4136, 4648, 5156, 5644, 5648, 5652, 5668, 6156, 6160, 6164, 6168, 6172, 6668, 6672, 6688, 7180, 7184, 7288, 7696, 7796, 8204, 8208, 8716, 8720, 8724, 9228, 9232, 9236, 9744)
    draw16($0, 9844, 10800, 13352, 13864, 14376, 14888, 15400, 17480, 17484, 17488, 17492, 17992, 17996, 18000, 18004, 18508)
    sw $0 18512($v1)
    li $t4 0x91003b
    draw64($t4, 1604, 1612, 1616, 1632, 2108, 2148, 2152, 2616, 2632, 2656, 2668, 3124, 3140, 3176, 3184, 3632, 3636, 3648, 3664, 3676, 4140, 4144, 4192, 4212, 4652, 4684, 4688, 4692, 4696, 4700, 4704, 4712, 5160, 5168, 5188, 5196, 5220, 5224, 5240, 5672, 5680, 5696, 5700, 5736, 5740, 5752, 6180, 6192, 6248, 6252, 6264, 6692, 6700, 6704, 6716, 6760, 6764, 6772, 6776, 7204, 7208, 7212, 7216, 7228)
    draw64($t4, 7276, 7280, 7284, 7720, 7724, 7728, 7732, 7740, 7744, 7788, 7792, 8240, 8244, 8248, 8252, 8256, 8260, 8296, 8300, 8304, 8756, 8760, 8764, 8768, 8772, 8800, 8804, 8808, 8812, 8816, 9268, 9272, 9276, 9280, 9324, 9328, 9780, 9784, 9788, 9840, 10288, 10292, 10352, 10356, 10868, 11288, 11308, 11800, 11804, 11808, 11812, 11816, 11820, 12312, 12316, 12320, 12324, 12328, 12332, 12344, 12348, 12388, 12392, 12396)
    draw16($t4, 12824, 12828, 12832, 12836, 12840, 12844, 12848, 12852, 12856, 12900, 12904, 12908, 12912, 12916, 13336, 13340)
    draw4($t4, 13348, 13356, 13360, 13416)
    draw4($t4, 13424, 13428, 13848, 13868)
    sw $t4 13928($v1)
    sw $t4 13940($v1)
    sw $t4 14452($v1)
    li $t4 0xda7141
    draw16($t4, 1608, 1620, 1624, 1628, 2112, 2124, 2128, 2140, 2144, 2620, 2660, 3128, 3164, 3688, 3696, 4148)
    draw16($t4, 4160, 4176, 4188, 4656, 4680, 4716, 4724, 5164, 5184, 5228, 5676, 6184, 6188, 6196, 6204, 6260)
    draw4($t4, 6696, 6708, 6768, 7220)
    sw $t4 7736($v1)
    li $t4 0xfaa753
    draw16($t4, 2116, 2120, 2132, 2136, 2624, 2628, 2664, 3132, 3172, 3180, 3640, 3660, 4152, 4204, 4660, 4672)
    draw4($t4, 5172, 5180, 5236, 5684)
    draw4($t4, 5692, 5744, 5748, 6200)
    sw $t4 6256($v1)
    sw $t4 6712($v1)
    sw $t4 7224($v1)
    li $t4 0xd1003f
    draw4($t4, 2636, 2640, 2644, 2648)
    draw4($t4, 2652, 3144, 3152, 3156)
    draw4($t4, 3652, 11352, 11860, 12380)
    li $t4 0xfaff53
    draw16($t4, 3136, 3148, 3160, 3168, 3644, 3656, 3668, 3672, 3680, 3684, 3692, 4156, 4164, 4168, 4172, 4180)
    draw4($t4, 4184, 4196, 4200, 4208)
    draw4($t4, 4664, 4668, 4676, 4708)
    draw4($t4, 4720, 5176, 5232, 5688)
    li $t4 0xbd6455
    draw16($t4, 5192, 5200, 5216, 5704, 5720, 5732, 6208, 6212, 6720, 6728, 7232, 7272, 7748, 7784, 8264, 8268)
    draw4($t4, 8292, 8788, 8792, 8796)
    draw4($t4, 11312, 11316, 11320, 11824)
    sw $t4 11832($v1)
    sw $t4 12340($v1)
    sw $t4 12408($v1)
    li $t4 0xffaa73
    draw16($t4, 5204, 5208, 5212, 5724, 5728, 6232, 6236, 6240, 6744, 6748, 6752, 7236, 7240, 7252, 7264, 7752)
    sw $t4 8272($v1)
    sw $t4 8288($v1)
    li $t4 0x2b1408
    draw16($t4, 5708, 5712, 5716, 6216, 6244, 18520, 18532, 19032, 19036, 19040, 19044, 19048, 19052, 19548, 19552, 19560)
    sw $t4 19564($v1)
    li $t4 0x10309c
    draw16($t4, 6220, 6224, 6228, 6736, 6740, 6756, 7268, 7780, 10300, 10820, 10824, 10860, 11328, 11368, 11372, 11376)
    draw16($t4, 11380, 11384, 11884, 11888, 11892, 11896, 12400, 12404, 12864, 13372, 13376, 13380, 13876, 13880, 13884, 13888)
    draw16($t4, 13892, 14384, 14388, 14392, 14396, 14400, 14896, 14900, 14904, 14908, 15408, 15412, 15416, 15468, 15920, 15924)
    draw4($t4, 15948, 15980, 16440, 16444)
    draw4($t4, 16448, 16452, 16456, 16460)
    draw4($t4, 16464, 16468, 16472, 16476)
    sw $t4 16480($v1)
    li $t4 0xaa90e0
    draw64($t4, 6676, 6680, 6684, 6732, 7188, 7200, 7700, 7716, 7800, 7804, 8212, 8232, 8236, 8308, 8312, 8316, 8728, 8732, 8748, 8752, 8820, 8824, 8828, 9240, 9244, 9248, 9252, 9264, 9288, 9312, 9316, 9332, 9336, 9748, 9768, 9776, 9808, 9852, 10260, 10284, 10344, 10348, 10360, 10364, 10776, 10804, 10808, 10848, 10852, 10872, 11292, 11296, 11300, 11304, 12356, 12872, 12876, 12892, 13900, 13904, 13908, 13920, 14948, 15436)
    draw4($t4, 15956, 15960, 15964, 18012)
    sw $t4 18524($v1)
    li $t4 0xfde3b2
    draw4($t4, 6724, 7256, 7260, 7756)
    draw4($t4, 7760, 7764, 7768, 7772)
    draw4($t4, 7776, 8276, 8280, 8284)
    sw $t4 11828($v1)
    li $t4 0xededff
    draw64($t4, 7192, 7196, 7244, 7704, 7708, 7712, 8216, 8220, 8224, 8228, 8736, 8740, 8744, 9256, 9260, 9752, 9756, 9760, 9764, 9772, 9796, 9800, 9804, 9820, 9824, 9828, 9832, 10264, 10268, 10272, 10276, 10280, 10312, 10316, 10320, 10324, 10336, 10340, 10780, 10784, 10788, 10792, 10796, 11324, 12880, 12884, 12888, 13912, 13916, 14408, 14412, 14416, 14420, 14424, 14428, 14432, 14436, 14920, 14924, 14928, 14932, 14936, 14940, 14944)
    draw4($t4, 15440, 15444, 15448, 15452)
    li $t4 0x008bff
    draw16($t4, 7248, 10304, 10812, 10816, 14912, 15420, 15424, 15428, 15460, 15464, 15928, 15932, 15936, 15940, 15944, 15968)
    draw4($t4, 15972, 15976, 16436, 16484)
    li $t4 0x0b0064
    draw16($t4, 8776, 8780, 8784, 9296, 9300, 9304, 10296, 10864, 11332, 11336, 11340, 11344, 11364, 11840, 11848, 11852)
    draw16($t4, 11876, 11880, 12352, 12860, 13364, 13368, 13412, 13872, 14380, 14892, 14956, 15404, 15916, 16428, 16432, 16488)
    draw4($t4, 16948, 16952, 16956, 16960)
    draw4($t4, 16964, 16968, 16972, 16976)
    li $t4 0x674da7
    draw16($t4, 9284, 9292, 9308, 9320, 9792, 9812, 9816, 9836, 10308, 10828, 10832, 10836, 10856, 11836, 11844, 12360)
    draw16($t4, 12364, 12868, 12896, 13384, 13388, 13392, 13396, 13400, 13404, 13408, 13896, 13924, 14404, 14440, 14916, 14952)
    draw16($t4, 15432, 15456, 15952, 16980, 16984, 16988, 16992, 16996, 17496, 17500, 17504, 17508, 17512, 18008, 18016, 18020)
    sw $t4 18024($v1)
    sw $t4 18528($v1)
    sw $t4 18536($v1)
    li $t4 0x4d0027
    draw4($t4, 10328, 10332, 10840, 10844)
    draw4($t4, 11348, 11356, 11360, 11856)
    draw4($t4, 11864, 12368, 12376, 12384)
    li $t4 0x880033
    sw $t4 11868($v1)
    sw $t4 11872($v1)
    sw $t4 12372($v1)
    li $t4 0x7a3332
    draw4($t4, 11900, 12336, 12412, 12920)
    sw $t4 12924($v1)
    jr $ra
draw_post_doll_08: # start at v1, use t4
    draw64($0, 1604, 1608, 1612, 1616, 1620, 1624, 1628, 1632, 2108, 2112, 2116, 2120, 2124, 2128, 2132, 2136, 2140, 2144, 2148, 2152, 2616, 2620, 2624, 2628, 2668, 3124, 3128, 3132, 3632, 3636, 4140, 4144, 4652, 5160, 6180, 6676, 6680, 6684, 7188, 7192, 7700, 7704, 8212, 8216, 8316, 8728, 9240, 9244, 9748, 9752, 9756, 10260, 10264, 10776, 10872, 11288, 12412, 13340, 13848, 14892, 15404, 15916, 15920, 16428)
    draw4($0, 16432, 16948, 18520, 19032)
    li $t4 0x91003b
    draw64($t4, 2632, 2636, 2644, 2648, 2664, 3136, 3140, 3180, 3184, 3640, 3644, 3664, 3688, 3700, 4148, 4172, 4208, 4216, 4656, 4668, 4696, 4732, 5164, 5176, 5208, 5220, 5248, 5672, 5684, 5716, 5720, 5724, 5732, 5736, 5744, 5760, 6184, 6192, 6200, 6248, 6252, 6256, 6268, 6272, 6692, 6696, 6700, 6704, 6708, 6712, 6728, 6764, 6768, 6772, 6780, 6784, 7208, 7212, 7216, 7220, 7280, 7284, 7292, 7724)
    draw64($t4, 7728, 7732, 7744, 7748, 7792, 7800, 7804, 8240, 8244, 8252, 8256, 8260, 8308, 8312, 8760, 8764, 8768, 8772, 8776, 8820, 8824, 9276, 9280, 9284, 9288, 9292, 9328, 9332, 9788, 9792, 9796, 9800, 9804, 9832, 9836, 9840, 9844, 10304, 10308, 10312, 10352, 10356, 10808, 10812, 10816, 10820, 10868, 11292, 11320, 11324, 11380, 11384, 11800, 11804, 11808, 11828, 11832, 11896, 12312, 12316, 12320, 12324, 12328, 12332)
    draw16($t4, 12336, 12340, 12344, 12824, 12828, 12832, 12836, 12840, 12844, 12848, 12852, 12856, 12868, 13336, 13344, 13348)
    draw16($t4, 13352, 13356, 13360, 13364, 13368, 13372, 13376, 13420, 13424, 13856, 13860, 13864, 13868, 13872, 13876, 13880)
    draw16($t4, 13884, 13928, 13932, 13936, 13940, 14368, 14372, 14380, 14384, 14388, 14392, 14452, 14456, 14880, 14896, 14900)
    sw $t4 14968($v1)
    sw $t4 15408($v1)
    li $t4 0xda7141
    draw16($t4, 2640, 2652, 2656, 2660, 3144, 3156, 3160, 3172, 3176, 3648, 3652, 3692, 4152, 4156, 4160, 4660)
    draw16($t4, 4664, 4680, 4712, 4720, 5168, 5172, 5180, 5224, 5232, 5676, 5680, 5688, 5748, 6188, 6196, 6216)
    draw4($t4, 6260, 7224, 7236, 7288)
    sw $t4 7736($v1)
    sw $t4 7796($v1)
    sw $t4 8248($v1)
    li $t4 0xfaa753
    draw16($t4, 3148, 3152, 3164, 3168, 3656, 3660, 3696, 4164, 4180, 4200, 4212, 4672, 5184, 5212, 5236, 5692)
    draw4($t4, 5704, 5712, 5728, 5740)
    draw4($t4, 5752, 6204, 6212, 6220)
    draw4($t4, 6264, 6720, 6724, 6776)
    sw $t4 7232($v1)
    sw $t4 7740($v1)
    li $t4 0xd1003f
    draw4($t4, 3668, 3672, 3676, 3684)
    draw4($t4, 4184, 12384, 12892, 13404)
    sw $t4 13412($v1)
    li $t4 0xfaff53
    draw16($t4, 3680, 4168, 4176, 4188, 4192, 4196, 4204, 4676, 4684, 4688, 4692, 4700, 4704, 4708, 4716, 4724)
    draw16($t4, 4728, 5188, 5192, 5196, 5200, 5204, 5216, 5228, 5240, 5244, 5696, 5700, 5708, 5756, 6208, 6716)
    sw $t4 7228($v1)
    li $t4 0xbd6455
    draw16($t4, 6224, 6228, 6232, 6732, 6736, 6752, 7240, 7244, 7752, 7760, 8264, 8304, 8780, 8816, 9296, 9300)
    draw4($t4, 9324, 9820, 9824, 9828)
    draw4($t4, 11836, 11840, 11844, 12348)
    sw $t4 12356($v1)
    sw $t4 12864($v1)
    sw $t4 13432($v1)
    li $t4 0xffaa73
    draw4($t4, 6236, 6240, 6244, 6756)
    draw4($t4, 6760, 7264, 7268, 7272)
    draw4($t4, 7780, 7784, 8268, 8296)
    sw $t4 9304($v1)
    sw $t4 9308($v1)
    sw $t4 9320($v1)
    li $t4 0x2b1408
    draw16($t4, 6740, 6744, 6748, 7248, 7276, 19548, 19560, 20060, 20064, 20068, 20072, 20076, 20080, 20576, 20580, 20588)
    sw $t4 20592($v1)
    li $t4 0xaa90e0
    draw64($t4, 7196, 7200, 7204, 7252, 7708, 7720, 8220, 8236, 8732, 8752, 8756, 8828, 8832, 9248, 9252, 9268, 9272, 9336, 9340, 9344, 9760, 9764, 9768, 9772, 9784, 9848, 9852, 9856, 10268, 10288, 10296, 10300, 10320, 10344, 10360, 10364, 10780, 10804, 10840, 10880, 11296, 11316, 11332, 11364, 11368, 11376, 11388, 11392, 11812, 11816, 11820, 11824, 11860, 11868, 11880, 11900, 12372, 12376, 13388, 13912, 13924, 14932, 14960, 15448)
    draw4($t4, 15468, 16984, 17496, 17500)
    draw4($t4, 18012, 18016, 18524, 18528)
    draw4($t4, 19040, 19044, 19552, 19556)
    li $t4 0x10309c
    draw16($t4, 7256, 7260, 7768, 7788, 8300, 8812, 11852, 11888, 12396, 12400, 12404, 12408, 12912, 12916, 12920, 13428)
    draw16($t4, 13892, 13896, 13900, 14400, 14404, 14408, 14412, 14416, 14908, 14912, 14916, 14920, 14924, 15416, 15420, 15424)
    draw4($t4, 15428, 15432, 15928, 15932)
    draw4($t4, 15936, 15984, 16440, 16452)
    draw4($t4, 16456, 16484, 16488, 16496)
    li $t4 0xededff
    draw16($t4, 7712, 7716, 7764, 8224, 8228, 8232, 8736, 8740, 8744, 8748, 9256, 9260, 9264, 9776, 9780, 10272)
    draw16($t4, 10276, 10280, 10284, 10292, 10784, 10788, 10792, 10796, 10800, 10828, 10832, 10836, 10848, 10852, 10856, 10860)
    draw16($t4, 11300, 11304, 11308, 11312, 11344, 11348, 11352, 11356, 11372, 11848, 11864, 13916, 13920, 14936, 14940, 14944)
    draw4($t4, 14948, 14952, 14956, 15440)
    sw $t4 15444($v1)
    sw $t4 15472($v1)
    sw $t4 15476($v1)
    li $t4 0xfde3b2
    draw16($t4, 7756, 7776, 8272, 8276, 8284, 8288, 8292, 8784, 8788, 8792, 8796, 8800, 8804, 8808, 9312, 9316)
    sw $t4 12352($v1)
    li $t4 0x008bff
    draw16($t4, 7772, 8280, 11336, 15940, 15944, 15948, 15952, 15956, 15960, 15964, 15968, 15972, 15976, 15980, 16444, 16448)
    sw $t4 16492($v1)
    sw $t4 17000($v1)
    li $t4 0x0b0064
    draw16($t4, 9808, 9812, 9816, 10328, 10332, 10336, 11328, 11892, 12364, 12368, 12872, 12880, 12884, 12908, 13380, 13384)
    draw16($t4, 13888, 14396, 14904, 15412, 15924, 16436, 16952, 16956, 16960, 16964, 16968, 16972, 17004, 17472, 17476, 17480)
    draw4($t4, 17484, 17488, 17996, 18000)
    sw $t4 18004($v1)
    li $t4 0x674da7
    draw16($t4, 10316, 10324, 10340, 10348, 10824, 10844, 10864, 11340, 11856, 11884, 12360, 12876, 13392, 13396, 13904, 13908)
    draw16($t4, 14420, 14424, 14428, 14432, 14436, 14440, 14444, 14928, 14964, 15436, 15452, 15456, 15460, 15464, 15480, 16460)
    draw16($t4, 16464, 16468, 16472, 16476, 16480, 16976, 16980, 16988, 16992, 16996, 17492, 17504, 17508, 17512, 18008, 18020)
    draw4($t4, 18024, 18532, 18536, 18540)
    draw4($t4, 19036, 19048, 19052, 19564)
    li $t4 0x4d0027
    draw4($t4, 11360, 11872, 11876, 12380)
    draw4($t4, 12388, 12392, 12888, 12896)
    sw $t4 12904($v1)
    sw $t4 13400($v1)
    sw $t4 13416($v1)
    li $t4 0x7a3332
    draw4($t4, 12860, 12924, 13436, 13944)
    sw $t4 13948($v1)
    li $t4 0x880033
    sw $t4 12900($v1)
    sw $t4 13408($v1)
    jr $ra
draw_post_doll_09: # start at v1, use t4
    draw64($0, 2632, 2636, 2640, 2644, 2648, 2652, 2656, 2660, 2664, 3136, 3140, 3144, 3148, 3152, 3156, 3160, 3164, 3168, 3172, 3176, 3180, 3184, 3640, 3644, 3648, 3652, 3656, 3660, 3664, 3668, 3672, 3676, 3680, 3684, 3688, 3692, 3696, 3700, 4148, 4152, 4156, 4160, 4164, 4168, 4208, 4212, 4216, 4656, 4660, 4664, 4668, 4672, 4728, 4732, 5164, 5168, 5172, 5176, 5180, 5244, 5248, 5672, 5676, 5680)
    draw16($0, 5684, 5688, 5692, 5760, 6184, 6188, 6192, 6196, 6200, 6692, 6696, 6700, 6704, 6708, 7196, 7200)
    draw16($0, 7204, 7208, 7212, 7216, 7220, 7708, 7712, 7716, 7720, 7724, 7728, 8220, 8224, 8228, 8232, 8236)
    draw16($0, 8240, 8732, 8736, 8740, 8744, 8748, 9260, 10268, 10780, 11292, 11296, 11800, 11804, 11808, 12312, 12316)
    draw4($0, 12824, 12828, 13336, 13372)
    sw $0 15924($v1)
    sw $0 16436($v1)
    sw $0 20080($v1)
    li $t4 0x91003b
    draw64($t4, 4172, 4176, 4184, 4188, 4204, 4676, 4680, 4720, 4724, 5184, 5204, 5228, 5240, 5712, 5748, 5756, 6204, 6208, 6236, 6272, 6712, 6716, 6748, 6760, 6788, 7224, 7256, 7260, 7264, 7272, 7276, 7284, 7296, 7304, 7732, 7740, 7788, 7792, 7796, 7808, 7812, 7816, 8244, 8252, 8268, 8304, 8308, 8312, 8320, 8324, 8332, 8752, 8764, 8820, 8824, 8832, 8836, 9264, 9272, 9276, 9284, 9288, 9332, 9340)
    draw64($t4, 9344, 9348, 9776, 9780, 9784, 9788, 9800, 9848, 9852, 9856, 10292, 10296, 10300, 10304, 10312, 10316, 10360, 10364, 10812, 10816, 10820, 10824, 10828, 10832, 10868, 10872, 10876, 11328, 11332, 11336, 11340, 11344, 11372, 11376, 11380, 11384, 11388, 11840, 11844, 11848, 11852, 11896, 11900, 12352, 12356, 12360, 12412, 12860, 12864, 12924, 12928, 13344, 13440, 13856, 13860, 13880, 14364, 14368, 14372, 14376, 14380, 14384, 14388, 14392)
    draw16($t4, 14876, 14880, 14892, 14896, 14900, 14904, 14916, 14920, 14960, 14964, 14968, 15384, 15404, 15408, 15412, 15416)
    draw16($t4, 15420, 15424, 15428, 15472, 15476, 15480, 15484, 15488, 15912, 15928, 15932, 15988, 15996, 16000, 16440, 16512)
    sw $t4 17024($v1)
    li $t4 0xda7141
    draw16($t4, 4180, 4192, 4196, 4200, 4684, 4696, 4700, 4712, 4716, 5188, 5192, 5232, 5696, 5700, 6220, 6252)
    draw16($t4, 6260, 6720, 6764, 6772, 7228, 7288, 7736, 7756, 7800, 8248, 8756, 8760, 8776, 8828, 9268, 9336)
    sw $t4 9792($v1)
    sw $t4 10308($v1)
    li $t4 0xfaa753
    draw16($t4, 4688, 4692, 4704, 4708, 5196, 5200, 5236, 5704, 5720, 5740, 5752, 6212, 6724, 6752, 6776, 7232)
    draw4($t4, 7244, 7252, 7268, 7280)
    draw4($t4, 7292, 7744, 7752, 7760)
    draw4($t4, 7804, 8260, 8264, 8316)
    sw $t4 8772($v1)
    sw $t4 9280($v1)
    sw $t4 9796($v1)
    li $t4 0xd1003f
    draw4($t4, 5208, 5212, 5216, 5224)
    draw4($t4, 5724, 13920, 13924, 14432)
    sw $t4 14952($v1)
    li $t4 0xfaff53
    draw16($t4, 5220, 5708, 5716, 5728, 5732, 5736, 5744, 6216, 6224, 6228, 6232, 6240, 6244, 6248, 6256, 6264)
    draw16($t4, 6268, 6728, 6732, 6736, 6740, 6744, 6756, 6768, 6780, 6784, 7236, 7240, 7248, 7300, 7748, 8256)
    sw $t4 8768($v1)
    li $t4 0xbd6455
    draw16($t4, 7764, 7768, 7772, 8272, 8276, 8292, 8780, 8784, 9292, 9300, 9804, 9844, 10320, 10356, 10836, 10840)
    draw4($t4, 10864, 11360, 11364, 11368)
    draw4($t4, 13884, 13888, 13892, 14396)
    sw $t4 14404($v1)
    sw $t4 14912($v1)
    sw $t4 14980($v1)
    li $t4 0xffaa73
    draw16($t4, 7776, 7780, 7784, 8296, 8300, 8804, 8808, 8812, 9320, 9324, 9808, 9812, 9824, 9836, 10324, 10844)
    sw $t4 10860($v1)
    li $t4 0x2b1408
    draw16($t4, 8280, 8284, 8288, 8788, 8816, 20060, 20072, 20572, 20576, 20580, 20584, 20588, 20592, 21088, 21092, 21100)
    sw $t4 21104($v1)
    li $t4 0xaa90e0
    draw64($t4, 8792, 9248, 9252, 9256, 9760, 9772, 10272, 10288, 10372, 10376, 10784, 10804, 10808, 10880, 10884, 10888, 11300, 11304, 11320, 11324, 11392, 11396, 11400, 11812, 11816, 11820, 11824, 11836, 11860, 11884, 11888, 11904, 11908, 12320, 12340, 12348, 12380, 12424, 12832, 12856, 12916, 12920, 12932, 12936, 13348, 13376, 13380, 13420, 13424, 13444, 13864, 13868, 13872, 13876, 14928, 15444, 15448, 15464, 16476, 16484, 16488, 16500, 17528, 18016)
    draw4($t4, 18536, 18540, 18544, 20064)
    li $t4 0x10309c
    draw16($t4, 8796, 8800, 9308, 9328, 9840, 10352, 12872, 13392, 13396, 13432, 13900, 13940, 13944, 13948, 13952, 13956)
    draw16($t4, 14456, 14460, 14464, 14468, 14972, 14976, 15436, 15944, 15948, 15952, 16448, 16452, 16456, 16460, 16464, 16468)
    draw16($t4, 16956, 16960, 16964, 16968, 16972, 16976, 16980, 17468, 17472, 17476, 17480, 17980, 17984, 17988, 18492, 18496)
    draw4($t4, 18528, 19012, 19016, 19020)
    draw4($t4, 19024, 19028, 19032, 19036)
    draw4($t4, 19040, 19044, 19048, 19052)
    li $t4 0xfde3b2
    draw4($t4, 9296, 9316, 9828, 9832)
    draw4($t4, 10328, 10332, 10336, 10340)
    draw4($t4, 10344, 10348, 10848, 10852)
    sw $t4 10856($v1)
    sw $t4 14400($v1)
    li $t4 0xededff
    draw64($t4, 9304, 9764, 9768, 9816, 10276, 10280, 10284, 10788, 10792, 10796, 10800, 11308, 11312, 11316, 11828, 11832, 12324, 12328, 12332, 12336, 12344, 12368, 12372, 12376, 12392, 12396, 12400, 12404, 12836, 12840, 12844, 12848, 12852, 12884, 12888, 12892, 12896, 12908, 12912, 13352, 13356, 13360, 13364, 13368, 13896, 15452, 15456, 15460, 16480, 16492, 16496, 16988, 16992, 16996, 17000, 17004, 17008, 17012, 17016, 17500, 17504, 17508, 17512, 17516)
    draw4($t4, 17520, 17524, 18020, 18024)
    sw $t4 18028($v1)
    sw $t4 18032($v1)
    li $t4 0x008bff
    draw16($t4, 9312, 9820, 12876, 13384, 13388, 17484, 17488, 17492, 17992, 17996, 18000, 18004, 18008, 18500, 18504, 18508)
    draw4($t4, 18512, 18516, 18520, 18524)
    sw $t4 19008($v1)
    sw $t4 19056($v1)
    li $t4 0x0b0064
    draw16($t4, 11348, 11352, 11356, 11868, 11872, 11876, 12868, 13436, 13904, 13908, 13912, 13936, 14412, 14420, 14424, 14448)
    draw16($t4, 14452, 14924, 15432, 15936, 15940, 15984, 16444, 16952, 17464, 17976, 18488, 18548, 19000, 19004, 19060, 19520)
    draw4($t4, 19524, 19528, 19532, 19536)
    sw $t4 19540($v1)
    sw $t4 19544($v1)
    sw $t4 19548($v1)
    li $t4 0x674da7
    draw16($t4, 11856, 11864, 11880, 11892, 12364, 12384, 12388, 12408, 12880, 13400, 13404, 13408, 13428, 14408, 14416, 14932)
    draw16($t4, 14936, 14940, 15440, 15468, 15956, 15960, 15964, 15968, 15972, 15976, 15980, 16472, 16504, 16984, 17496, 18012)
    draw4($t4, 18036, 18532, 19552, 19556)
    draw4($t4, 19560, 19564, 19568, 20068)
    sw $t4 20076($v1)
    li $t4 0x4d0027
    draw4($t4, 12900, 12904, 13412, 13416)
    draw4($t4, 13916, 13928, 13932, 14428)
    sw $t4 14436($v1)
    sw $t4 14948($v1)
    sw $t4 14956($v1)
    li $t4 0x880033
    sw $t4 14440($v1)
    sw $t4 14444($v1)
    sw $t4 14944($v1)
    li $t4 0x7a3332
    draw4($t4, 14472, 14908, 14984, 15492)
    sw $t4 15496($v1)
    jr $ra
draw_post_doll_10: # start at v1, use t4
    draw64($0, 4172, 4176, 4180, 4184, 4188, 4192, 4196, 4200, 4204, 4676, 4680, 4684, 4688, 4692, 4696, 4700, 4704, 4708, 4712, 4716, 4720, 4724, 5184, 5188, 5192, 5196, 5200, 5204, 5208, 5212, 5216, 5220, 5224, 5228, 5232, 5236, 5240, 5696, 5700, 5704, 5708, 5712, 5716, 5720, 5724, 5728, 5732, 5736, 5740, 5744, 5748, 5752, 5756, 6204, 6208, 6212, 6216, 6220, 6224, 6260, 6264, 6268, 6272, 6712)
    draw64($0, 6716, 6720, 6724, 6728, 6780, 6784, 6788, 7224, 7228, 7232, 7236, 7296, 7300, 7304, 7732, 7736, 7740, 7744, 7812, 7816, 8244, 8248, 8252, 8256, 8324, 8332, 8752, 8756, 8760, 8764, 9248, 9252, 9256, 9264, 9268, 9272, 9276, 9760, 9764, 9768, 9772, 9776, 9780, 9784, 9788, 10272, 10276, 10280, 10284, 10288, 10292, 10296, 10300, 10784, 10788, 10804, 10808, 11300, 11320, 11400, 11812, 12320, 12324, 12832)
    draw16($0, 12836, 12840, 13344, 13348, 13352, 13856, 13860, 14364, 14368, 14372, 14876, 14880, 15384, 15496, 15912, 18488)
    sw $0 19000($v1)
    sw $0 19004($v1)
    li $t4 0x91003b
    draw64($t4, 6228, 6236, 6240, 6256, 6732, 6772, 6776, 7240, 7256, 7280, 7292, 7748, 7764, 7800, 7808, 8260, 8272, 8288, 8300, 8768, 8800, 8812, 8836, 9280, 9300, 9312, 9324, 9328, 9336, 9348, 9792, 9812, 9820, 9824, 9828, 9836, 9840, 9848, 9864, 10304, 10320, 10324, 10344, 10348, 10356, 10360, 10364, 10376, 10812, 10816, 10872, 10876, 10884, 10888, 11324, 11328, 11340, 11384, 11388, 11396, 11836, 11840, 11852, 11900)
    draw64($t4, 11904, 11908, 12352, 12356, 12364, 12368, 12412, 12416, 12864, 12868, 12876, 12880, 12884, 12920, 12924, 12928, 13380, 13384, 13388, 13392, 13396, 13424, 13428, 13432, 13436, 13440, 13892, 13896, 13900, 13904, 13948, 13952, 14404, 14408, 14412, 14464, 14912, 14916, 14976, 14980, 15424, 15492, 15928, 15932, 16440, 16444, 16952, 16956, 16968, 16972, 17012, 17016, 17020, 17460, 17464, 17468, 17472, 17476, 17480, 17524, 17528, 17532, 17536, 17540)
    draw4($t4, 17972, 17976, 17980, 17984)
    draw4($t4, 18040, 18048, 18052, 18492)
    sw $t4 18564($v1)
    sw $t4 19076($v1)
    li $t4 0xda7141
    draw16($t4, 6232, 6244, 6248, 6252, 6736, 6748, 6752, 6764, 6768, 7244, 7284, 7752, 7784, 7788, 8280, 8296)
    draw16($t4, 8304, 8312, 8320, 8772, 8788, 8816, 8824, 9308, 9316, 9340, 9808, 9852, 10820, 10828, 10880, 11332)
    draw4($t4, 11392, 11844, 12360, 12872)
    li $t4 0xfaa753
    draw16($t4, 6740, 6744, 6756, 6760, 7248, 7252, 7288, 7756, 7792, 7796, 7804, 8264, 8776, 8796, 8804, 8828)
    draw4($t4, 9284, 9296, 9796, 9804)
    draw4($t4, 9832, 10308, 10312, 10316)
    draw4($t4, 10328, 10368, 10824, 11336)
    sw $t4 11848($v1)
    li $t4 0xd1003f
    draw4($t4, 7260, 7264, 7268, 7272)
    draw4($t4, 7276, 7768, 7772, 7776)
    draw4($t4, 7780, 8276, 15976, 16484)
    sw $t4 17004($v1)
    li $t4 0xfaff53
    draw16($t4, 7760, 8268, 8284, 8292, 8308, 8316, 8780, 8784, 8792, 8808, 8820, 8832, 9288, 9292, 9304, 9320)
    draw4($t4, 9332, 9344, 9800, 9816)
    draw4($t4, 9844, 9856, 9860, 10372)
    li $t4 0x2b1408
    draw4($t4, 10332, 10336, 10340, 10840)
    sw $t4 10868($v1)
    li $t4 0xffaa73
    draw4($t4, 10352, 10860, 10864, 11368)
    draw4($t4, 11372, 11376, 11860, 11864)
    draw4($t4, 11876, 11888, 12376, 12896)
    sw $t4 12912($v1)
    li $t4 0xaa90e0
    draw64($t4, 10792, 10796, 10800, 10844, 11304, 11316, 11356, 11816, 11832, 12328, 12348, 12420, 12424, 12428, 12844, 12848, 12932, 12936, 12940, 13356, 13360, 13364, 13368, 13372, 13376, 13444, 13448, 13864, 13884, 13888, 13912, 13936, 13940, 13956, 13960, 13964, 14376, 14400, 14432, 14444, 14468, 14472, 14476, 14892, 14948, 14968, 14972, 14984, 15404, 15408, 15412, 15416, 15428, 15432, 15460, 15476, 16980, 17496, 17500, 17516, 18532, 18536, 18540, 18548)
    draw4($t4, 19064, 19580, 20064, 20088)
    sw $t4 20580($v1)
    sw $t4 20584($v1)
    sw $t4 20588($v1)
    li $t4 0xbd6455
    draw16($t4, 10832, 10836, 10856, 11344, 11352, 11856, 11896, 12372, 12408, 12888, 12892, 12916, 13412, 13416, 13420, 15936)
    draw4($t4, 15940, 15944, 16448, 16456)
    sw $t4 16964($v1)
    sw $t4 17032($v1)
    li $t4 0x10309c
    draw16($t4, 10848, 10852, 11360, 11364, 11380, 11892, 12404, 14924, 15444, 15448, 15484, 15952, 15992, 15996, 16000, 16004)
    draw16($t4, 16008, 16508, 16512, 16516, 16520, 17024, 17028, 17488, 17996, 18000, 18004, 18504, 18508, 18512, 18516, 18520)
    draw16($t4, 18524, 19012, 19016, 19020, 19024, 19028, 19520, 19524, 19528, 19532, 19536, 20032, 20036, 20040, 20044, 20544)
    draw4($t4, 20548, 20552, 20556, 21060)
    draw4($t4, 21064, 21068, 21588, 21592)
    draw4($t4, 21596, 21600, 21604, 21608)
    sw $t4 21612($v1)
    sw $t4 21616($v1)
    li $t4 0xededff
    draw64($t4, 11308, 11312, 11820, 11824, 11828, 11868, 12332, 12336, 12340, 12344, 12852, 12856, 12860, 13868, 13872, 13876, 13880, 14380, 14384, 14388, 14392, 14396, 14420, 14424, 14428, 14448, 14452, 14456, 14896, 14900, 14904, 14908, 14936, 14940, 14944, 14960, 14964, 15420, 15452, 15456, 15472, 15948, 17504, 17508, 17512, 18544, 19040, 19044, 19048, 19052, 19056, 19060, 19552, 19556, 19560, 19564, 19568, 19572, 19576, 20068, 20072, 20076, 20080, 20084)
    sw $t4 20592($v1)
    sw $t4 20596($v1)
    li $t4 0xfde3b2
    draw4($t4, 11348, 11880, 11884, 12380)
    draw4($t4, 12384, 12388, 12392, 12396)
    draw4($t4, 12400, 12900, 12904, 12908)
    sw $t4 16452($v1)
    li $t4 0x008bff
    draw16($t4, 11872, 14928, 15436, 15440, 19032, 19540, 19544, 20048, 20052, 20056, 20560, 20564, 20568, 20572, 21072, 21076)
    draw4($t4, 21080, 21084, 21088, 21092)
    draw4($t4, 21096, 21100, 21104, 21108)
    li $t4 0x0b0064
    draw16($t4, 13400, 13404, 13408, 13920, 13924, 13928, 14920, 15488, 15956, 15960, 15964, 15968, 15988, 16464, 16472, 16476)
    draw16($t4, 16500, 16504, 16976, 17484, 17988, 17992, 18496, 18500, 19008, 19516, 20028, 20092, 20540, 20604, 21052, 21056)
    draw4($t4, 21112, 21576, 21580, 21584)
    sw $t4 21620($v1)
    li $t4 0x674da7
    draw16($t4, 13908, 13916, 13932, 13944, 14416, 14436, 14440, 14460, 14932, 15480, 16460, 16468, 16984, 16988, 17492, 17520)
    draw16($t4, 18008, 18012, 18016, 18020, 18024, 18028, 18032, 18036, 18528, 18552, 19036, 19068, 19548, 20060, 20576, 20600)
    li $t4 0x4d0027
    draw4($t4, 14952, 14956, 15464, 15468)
    draw4($t4, 15972, 15980, 15984, 16480)
    draw4($t4, 16488, 16992, 17000, 17008)
    li $t4 0x880033
    sw $t4 16492($v1)
    sw $t4 16496($v1)
    sw $t4 16996($v1)
    li $t4 0x7a3332
    draw4($t4, 16524, 16960, 17036, 17544)
    sw $t4 17548($v1)
    jr $ra
draw_post_doll_11: # start at v1, use t4
    li $t4 0x91003b
    draw64($t4, 3664, 3672, 3676, 3692, 4168, 4208, 4212, 4676, 4692, 4716, 4728, 5184, 5200, 5220, 5236, 5244, 5696, 5708, 5736, 6204, 6236, 6248, 6272, 6716, 6736, 6748, 6760, 6764, 6772, 6784, 7228, 7248, 7260, 7272, 7276, 7284, 7296, 7740, 7756, 7760, 7768, 7772, 7776, 7784, 7792, 7796, 7800, 7808, 8252, 8268, 8272, 8292, 8308, 8312, 8320, 8764, 8768, 8776, 8820, 8824, 8828, 8832, 9276, 9280)
    draw64($t4, 9288, 9300, 9336, 9340, 9344, 9788, 9792, 9800, 9812, 9848, 9852, 10300, 10304, 10312, 10316, 10356, 10360, 10364, 10816, 10820, 10824, 10828, 10832, 10860, 10864, 10868, 10872, 10876, 11328, 11332, 11336, 11380, 11384, 11388, 11836, 11840, 11844, 11896, 11900, 12348, 12352, 12408, 12412, 12416, 12860, 12864, 12928, 13368, 13372, 13880, 13932, 14392, 14444, 14448, 14452, 14456, 14904, 14916, 14920, 14960, 14964, 14968, 14972, 14976)
    draw4($t4, 15416, 15420, 15424, 15476)
    draw4($t4, 15480, 15484, 15932, 15936)
    sw $t4 16000($v1)
    sw $t4 16444($v1)
    sw $t4 16512($v1)
    li $t4 0xda7141
    draw16($t4, 3668, 3680, 3684, 3688, 4172, 4184, 4188, 4200, 4204, 4680, 4720, 5188, 5224, 5724, 5740, 5748)
    draw16($t4, 5756, 6208, 6224, 6252, 6260, 6776, 7244, 7256, 7264, 7288, 8256, 8264, 8316, 8788, 9796, 10308)
    li $t4 0xfaa753
    draw16($t4, 4176, 4180, 4192, 4196, 4684, 4688, 4724, 5192, 5228, 5232, 5240, 5700, 5720, 5732, 6212, 6264)
    draw4($t4, 6720, 6732, 6744, 6752)
    draw4($t4, 7232, 7240, 7744, 7752)
    draw4($t4, 7804, 8260, 8276, 8772)
    sw $t4 9284($v1)
    li $t4 0xd1003f
    draw4($t4, 4696, 4700, 4704, 4708)
    draw4($t4, 4712, 5204, 5208, 5212)
    draw4($t4, 5216, 5712, 13408, 13920)
    sw $t4 14432($v1)
    sw $t4 14440($v1)
    li $t4 0xfaff53
    draw16($t4, 5196, 5704, 5716, 5728, 5744, 5752, 6216, 6220, 6228, 6232, 6240, 6244, 6256, 6268, 6724, 6728)
    draw4($t4, 6740, 6756, 6768, 6780)
    draw4($t4, 7236, 7252, 7268, 7280)
    draw4($t4, 7292, 7748, 7764, 7780)
    li $t4 0xffaa73
    draw4($t4, 7788, 8296, 8300, 8804)
    draw4($t4, 8808, 8812, 9324, 9808)
    sw $t4 10324($v1)
    sw $t4 10348($v1)
    li $t4 0x2b1408
    draw16($t4, 8280, 8284, 8288, 8304, 20576, 20588, 21088, 21092, 21096, 21100, 21104, 21108, 21604, 21608, 21616, 21620)
    li $t4 0xbd6455
    draw16($t4, 8780, 8784, 9292, 9332, 9804, 9844, 10320, 10352, 10840, 10844, 10848, 10852, 10856, 13884, 13888, 13892)
    draw4($t4, 14396, 14404, 14468, 14912)
    li $t4 0xaa90e0
    draw64($t4, 8792, 10812, 10880, 11320, 11324, 11344, 11368, 11372, 11392, 11396, 11824, 11828, 11864, 11880, 11904, 11908, 11912, 12328, 12332, 12372, 12384, 12404, 12420, 12424, 12836, 12856, 12912, 12932, 13344, 13364, 13376, 13380, 13400, 13404, 13856, 13868, 13872, 13876, 14368, 14372, 14376, 14380, 14416, 14888, 14932, 14936, 14952, 15396, 15412, 15908, 15924, 15968, 15972, 15976, 15988, 16420, 16432, 16480, 16488, 16504, 16936, 16940, 16992, 17000)
    draw4($t4, 17016, 17528, 18036, 18536)
    sw $t4 18540($v1)
    sw $t4 18544($v1)
    sw $t4 20580($v1)
    li $t4 0x10309c
    draw64($t4, 8796, 8800, 8816, 9308, 9328, 9840, 12360, 12872, 12920, 13428, 13432, 13436, 13440, 13444, 13900, 13944, 13948, 13952, 13956, 14460, 14464, 14924, 15432, 15436, 15440, 15944, 15948, 15952, 15956, 15960, 16452, 16456, 16460, 16464, 16468, 16472, 16964, 16968, 16972, 16976, 16984, 17476, 17480, 17484, 17488, 17988, 17992, 17996, 18000, 18012, 18500, 18504, 18508, 18512, 18528, 19016, 19020, 19024, 19544, 19548, 19552, 19556, 19560, 19564)
    draw64($0, 8836, 9348, 9856, 9860, 9864, 10368, 10372, 10376, 10792, 10796, 10800, 10884, 10888, 11304, 11308, 11312, 11316, 11816, 11820, 12428, 12936, 12940, 13448, 13964, 14476, 15488, 15492, 15928, 15996, 16004, 16008, 16440, 16508, 16516, 16520, 16524, 16952, 16956, 17020, 17024, 17028, 17032, 17036, 17460, 17464, 17468, 17532, 17536, 17540, 17544, 17548, 17972, 17976, 17980, 18048, 18052, 18492, 18564, 19008, 19068, 19076, 19516, 19520, 19524)
    draw16($0, 19528, 19576, 19580, 20028, 20032, 20036, 20040, 20044, 20048, 20052, 20056, 20060, 20064, 20084, 20088, 20092)
    draw16($0, 20540, 20544, 20548, 20552, 20556, 20560, 20564, 20568, 20572, 20596, 20600, 20604, 21052, 21056, 21060, 21064)
    draw4($0, 21068, 21072, 21076, 21080)
    draw4($0, 21084, 21112, 21576, 21580)
    draw4($0, 21584, 21588, 21592, 21596)
    sw $0 21600($v1)
    sw $0 21612($v1)
    li $t4 0xfde3b2
    draw4($t4, 9296, 9316, 9320, 9816)
    draw4($t4, 9824, 9828, 9832, 9836)
    draw4($t4, 10328, 10332, 10336, 10340)
    sw $t4 10344($v1)
    sw $t4 14400($v1)
    li $t4 0xededff
    draw64($t4, 9304, 11832, 11852, 11856, 11860, 11884, 11888, 12336, 12340, 12344, 12368, 12376, 12380, 12396, 12400, 12840, 12844, 12848, 12852, 12888, 12892, 12908, 13348, 13352, 13356, 13360, 13860, 13864, 13896, 14384, 14388, 14892, 14896, 14900, 14940, 14944, 14948, 15400, 15404, 15408, 15912, 15916, 15920, 15980, 15984, 16424, 16428, 16484, 16492, 16496, 16500, 16996, 17004, 17008, 17012, 17504, 17508, 17512, 17516, 17520, 17524, 18020, 18024, 18028)
    sw $t4 18032($v1)
    li $t4 0x008bff
    draw16($t4, 9312, 9820, 12876, 13384, 13388, 16980, 17492, 17496, 18004, 18008, 18040, 18516, 18520, 18524, 18548, 18552)
    draw4($t4, 19028, 19032, 19036, 19040)
    draw4($t4, 19044, 19048, 19052, 19056)
    sw $t4 19060($v1)
    li $t4 0x0b0064
    draw16($t4, 10836, 11352, 11356, 11360, 12356, 12868, 12924, 13392, 13420, 13424, 13908, 13936, 13940, 14412, 15428, 15940)
    draw4($t4, 16448, 16960, 17472, 17984)
    draw4($t4, 18496, 19012, 19064, 19532)
    draw4($t4, 19536, 19540, 19568, 19572)
    li $t4 0x674da7
    draw16($t4, 11340, 11348, 11364, 11376, 11848, 11868, 11872, 11892, 12364, 12392, 12880, 12884, 12896, 12904, 12916, 13396)
    draw16($t4, 13904, 14408, 14420, 14928, 14956, 15444, 15448, 15452, 15456, 15460, 15464, 15468, 15472, 15964, 15992, 16476)
    draw4($t4, 16988, 17500, 18016, 18532)
    draw4($t4, 20068, 20072, 20076, 20080)
    sw $t4 20584($v1)
    sw $t4 20592($v1)
    li $t4 0x4d0027
    draw4($t4, 11876, 12388, 12900, 13412)
    draw4($t4, 13416, 13912, 13924, 14424)
    sw $t4 14436($v1)
    li $t4 0x880033
    sw $t4 13916($v1)
    sw $t4 13928($v1)
    sw $t4 14428($v1)
    li $t4 0x7a3332
    draw4($t4, 13960, 14472, 14908, 14980)
    sw $t4 14984($v1)
    jr $ra
draw_post_doll_12: # start at v1, use t4
    li $t4 0x91003b
    draw64($t4, 2640, 2648, 2652, 2668, 3144, 3184, 3188, 3652, 3668, 3692, 3704, 4160, 4176, 4196, 4212, 4220, 4672, 4684, 4712, 5180, 5212, 5224, 5248, 5692, 5712, 5724, 5736, 5740, 5748, 5760, 6204, 6224, 6236, 6248, 6252, 6260, 6272, 6716, 6732, 6736, 6744, 6748, 6752, 6760, 6772, 7228, 7244, 7248, 7272, 7284, 7292, 7744, 7752, 7780, 7796, 7804, 8256, 8264, 8276, 8312, 8316, 8768, 8776, 8788)
    draw64($t4, 8824, 8828, 9280, 9288, 9292, 9332, 9336, 9340, 9792, 9800, 9804, 9808, 9836, 9840, 9844, 9848, 9852, 10304, 10308, 10312, 10356, 10360, 10364, 10816, 10820, 10872, 10876, 11324, 11328, 11384, 11388, 11392, 11836, 11840, 11900, 11904, 12348, 12412, 12416, 12908, 12928, 13420, 13424, 13440, 13892, 13896, 13936, 13940, 13952, 14396, 14400, 14404, 14452, 14456, 14460, 14464, 14908, 14912, 14964, 14968, 14972, 15424, 15480, 15484)
    li $t4 0xda7141
    draw16($t4, 2644, 2656, 2660, 2664, 3148, 3160, 3164, 3176, 3180, 3656, 3696, 4164, 4200, 4676, 4696, 4700)
    draw16($t4, 4716, 4724, 4732, 5184, 5200, 5228, 5236, 5696, 6208, 6220, 6232, 6240, 6268, 6720, 6780, 7232)
    draw4($t4, 7764, 7800, 9284, 9796)
    li $t4 0xfaa753
    draw16($t4, 3152, 3156, 3168, 3172, 3660, 3664, 3700, 4168, 4204, 4208, 4216, 4708, 5188, 5196, 5208, 5244)
    draw4($t4, 5700, 5708, 5720, 5728)
    draw4($t4, 5756, 6212, 6724, 6776)
    draw4($t4, 7236, 7252, 7288, 7748)
    sw $t4 8260($v1)
    sw $t4 8772($v1)
    li $t4 0xd1003f
    draw4($t4, 3672, 3676, 3680, 3684)
    draw4($t4, 3688, 4180, 4184, 4188)
    draw4($t4, 4192, 4688, 12384, 12896)
    sw $t4 13408($v1)
    sw $t4 13416($v1)
    sw $t4 13920($v1)
    li $t4 0xfaff53
    draw16($t4, 4172, 4680, 4692, 4704, 4720, 4728, 5192, 5204, 5216, 5220, 5232, 5240, 5704, 5716, 5732, 5744)
    draw4($t4, 5752, 6216, 6228, 6244)
    draw4($t4, 6256, 6264, 6728, 6740)
    draw4($t4, 6756, 6768, 7240, 7268)
    li $t4 0xffaa73
    draw4($t4, 6764, 7276, 7784, 7788)
    draw4($t4, 8300, 8784, 9300, 9324)
    draw64($0, 6784, 7296, 7740, 7808, 8252, 8320, 8764, 8832, 9276, 9344, 9788, 10300, 11908, 11912, 13444, 13956, 13960, 14392, 14468, 14472, 14900, 14904, 14976, 14980, 14984, 15404, 15408, 15412, 15416, 15420, 15908, 15912, 15916, 15920, 15924, 15932, 15992, 16000, 16420, 16424, 16428, 16432, 16444, 16504, 16512, 16936, 16940, 17016, 17528, 18040, 18496, 18500, 18544, 18548, 18552, 19012, 19016, 19020, 19024, 19028, 19032, 19036, 19056, 19060)
    draw16($0, 19064, 19532, 19536, 19540, 19544, 19568, 19572, 20584, 21088, 21092, 21096, 21100, 21104, 21108, 21604, 21608)
    sw $0 21616($v1)
    sw $0 21620($v1)
    li $t4 0x2b1408
    draw16($t4, 7256, 7260, 7264, 7280, 19548, 19560, 20060, 20064, 20068, 20072, 20076, 20080, 20576, 20580, 20588, 20592)
    li $t4 0xbd6455
    draw16($t4, 7756, 7760, 8268, 8308, 8780, 8820, 9296, 9328, 9816, 9820, 9824, 9828, 9832, 12860, 12864, 12868)
    draw4($t4, 12920, 13372, 13380, 13428)
    sw $t4 13888($v1)
    li $t4 0xaa90e0
    draw64($t4, 7768, 10320, 10348, 10368, 10372, 10792, 10796, 10800, 10804, 10808, 10812, 10840, 10856, 10864, 10880, 10884, 10888, 11296, 11300, 11380, 11396, 11400, 11804, 11832, 11860, 11868, 11884, 12316, 12336, 12340, 12344, 12352, 12356, 12372, 12376, 12420, 12424, 12828, 12840, 12844, 12848, 12852, 12932, 13340, 13344, 13348, 13352, 13356, 13392, 13856, 13880, 13908, 13912, 14364, 14388, 14876, 14892, 14896, 14940, 14944, 14956, 15388, 15392, 15396)
    draw4($t4, 15400, 15456, 15472, 16476)
    draw4($t4, 16496, 17504, 17516, 19552)
    li $t4 0x10309c
    draw16($t4, 7772, 7776, 7792, 8284, 8304, 8816, 11336, 11848, 11892, 12400, 12404, 12408, 12876, 13900, 14412, 14416)
    draw16($t4, 14420, 14920, 14924, 14928, 14932, 15432, 15436, 15440, 15940, 15944, 15948, 15988, 16452, 16456, 16460, 16500)
    draw4($t4, 16964, 16968, 17012, 17476)
    draw4($t4, 17480, 17524, 17988, 17992)
    draw4($t4, 17996, 18516, 18520, 18524)
    sw $t4 18528($v1)
    sw $t4 18532($v1)
    sw $t4 18536($v1)
    li $t4 0xfde3b2
    draw4($t4, 8272, 8292, 8296, 8792)
    draw4($t4, 8800, 8804, 8808, 8812)
    draw4($t4, 9304, 9308, 9312, 9316)
    sw $t4 9320($v1)
    sw $t4 13376($v1)
    sw $t4 13432($v1)
    li $t4 0xededff
    draw64($t4, 8280, 10828, 10832, 10836, 10860, 11304, 11308, 11312, 11316, 11320, 11344, 11348, 11352, 11356, 11372, 11376, 11808, 11812, 11816, 11820, 11824, 11828, 11864, 12320, 12324, 12328, 12332, 12832, 12836, 12856, 12872, 13360, 13364, 13368, 13860, 13864, 13868, 13872, 13876, 13916, 14368, 14372, 14376, 14380, 14384, 14880, 14884, 14888, 14948, 14952, 15452, 15460, 15464, 15468, 15964, 15968, 15972, 15976, 15980, 16480, 16484, 16488, 16492, 16992)
    draw4($t4, 16996, 17000, 17004, 17508)
    sw $t4 17512($v1)
    li $t4 0x008bff
    draw16($t4, 8288, 8796, 11852, 12360, 12364, 15444, 15952, 15956, 16464, 16468, 16972, 16976, 16980, 16984, 17484, 17488)
    draw4($t4, 17492, 17496, 18000, 18004)
    sw $t4 18008($v1)
    sw $t4 18012($v1)
    sw $t4 18032($v1)
    li $t4 0x0b0064
    draw16($t4, 9812, 10328, 10332, 10336, 10340, 11332, 11844, 11896, 12368, 12396, 12884, 12888, 12912, 13388, 13932, 14408)
    draw4($t4, 14916, 15428, 15476, 15936)
    draw4($t4, 16448, 16960, 17472, 17984)
    draw4($t4, 18036, 18504, 18508, 18512)
    sw $t4 18540($v1)
    li $t4 0x674da7
    draw16($t4, 10316, 10324, 10344, 10352, 10824, 10844, 10848, 10868, 11340, 11368, 11856, 11880, 11888, 12880, 13384, 13396)
    draw16($t4, 13400, 13904, 13928, 14424, 14428, 14432, 14436, 14440, 14444, 14448, 14936, 14960, 15448, 15960, 15984, 16472)
    draw4($t4, 16988, 17008, 17500, 17520)
    draw4($t4, 18016, 18020, 18024, 18028)
    draw4($t4, 19040, 19044, 19048, 19052)
    sw $t4 19556($v1)
    sw $t4 19564($v1)
    li $t4 0x4d0027
    draw4($t4, 10852, 11360, 11364, 11872)
    draw4($t4, 11876, 12380, 12388, 12392)
    sw $t4 12900($v1)
    sw $t4 13412($v1)
    sw $t4 13924($v1)
    li $t4 0x880033
    sw $t4 12892($v1)
    sw $t4 12904($v1)
    sw $t4 13404($v1)
    li $t4 0x7a3332
    draw4($t4, 12916, 12924, 13436, 13884)
    sw $t4 13944($v1)
    sw $t4 13948($v1)
    jr $ra
draw_post_doll_13: # start at v1, use t4
    li $t4 0x91003b
    draw64($t4, 2128, 2136, 2140, 2156, 2632, 2672, 2676, 3140, 3156, 3180, 3192, 3648, 3664, 3684, 3700, 3708, 4160, 4172, 4200, 4668, 4700, 4736, 5180, 5212, 5228, 5248, 5692, 5708, 5724, 5740, 5760, 6204, 6220, 6232, 6236, 6240, 6248, 6260, 6272, 6716, 6732, 6736, 6760, 6772, 6780, 6784, 7224, 7228, 7240, 7268, 7284, 7292, 7296, 7300, 7736, 7740, 7752, 7764, 7800, 7804, 7808, 7812, 8248, 8252)
    draw64($t4, 8264, 8276, 8312, 8316, 8320, 8324, 8760, 8764, 8776, 8780, 8820, 8824, 8828, 8832, 8836, 9272, 9276, 9280, 9288, 9292, 9296, 9324, 9328, 9332, 9336, 9340, 9344, 9348, 9784, 9788, 9792, 9796, 9800, 9844, 9848, 9852, 9856, 10300, 10304, 10308, 10360, 10364, 10368, 10812, 10816, 10872, 10876, 10880, 11324, 11328, 11388, 11392, 11836, 11900, 11904, 12396, 12416, 12908, 12912, 12928, 13380, 13384, 13424, 13428)
    draw16($t4, 13440, 13884, 13888, 13892, 13936, 13940, 13944, 13948, 13952, 14396, 14400, 14452, 14456, 14460, 14968, 14972)
    li $t4 0xda7141
    draw16($t4, 2132, 2144, 2148, 2152, 2636, 2648, 2652, 2664, 2668, 3144, 3184, 3652, 3688, 4164, 4184, 4188)
    draw16($t4, 4204, 4212, 4220, 4672, 4688, 4712, 4716, 5184, 5196, 5200, 5696, 5712, 5720, 5728, 5736, 5748)
    draw4($t4, 6208, 6224, 6268, 6720)
    draw4($t4, 6728, 7232, 7252, 7288)
    draw4($t4, 7744, 8256, 8768, 8772)
    sw $t4 9284($v1)
    li $t4 0xfaa753
    draw16($t4, 2640, 2644, 2656, 2660, 3148, 3152, 3188, 3656, 3692, 3696, 3704, 4196, 4676, 4684, 4696, 4724)
    draw4($t4, 4732, 5208, 5224, 5236)
    draw4($t4, 6216, 6740, 6776, 7236)
    sw $t4 7748($v1)
    sw $t4 8260($v1)
    li $t4 0xd1003f
    draw4($t4, 3160, 3164, 3168, 3172)
    draw4($t4, 3176, 3668, 3672, 3676)
    draw4($t4, 3680, 4176, 11872, 12384)
    sw $t4 12896($v1)
    sw $t4 12904($v1)
    sw $t4 13408($v1)
    li $t4 0xfaff53
    draw16($t4, 3660, 4168, 4180, 4192, 4208, 4216, 4680, 4692, 4704, 4708, 4720, 4728, 5188, 5192, 5204, 5216)
    draw16($t4, 5220, 5232, 5240, 5244, 5700, 5704, 5716, 5732, 5744, 5752, 5756, 6212, 6228, 6244, 6256, 6264)
    sw $t4 6724($v1)
    sw $t4 6756($v1)
    li $t4 0xffaa73
    draw4($t4, 6252, 6764, 7272, 7276)
    draw4($t4, 7788, 8272, 8788, 8812)
    li $t4 0x2b1408
    draw16($t4, 6744, 6748, 6752, 6768, 19036, 19048, 19548, 19552, 19556, 19560, 19564, 19568, 20064, 20068, 20076, 20080)
    li $t4 0xbd6455
    draw16($t4, 7244, 7248, 7756, 7796, 8268, 8308, 8784, 8816, 9304, 9308, 9312, 9316, 9320, 12348, 12352, 12356)
    draw4($t4, 12408, 12860, 12868, 12916)
    sw $t4 13376($v1)
    li $t4 0xaa90e0
    draw64($t4, 7256, 9252, 9256, 9760, 9772, 9776, 9808, 9836, 9860, 10268, 10292, 10296, 10328, 10352, 10372, 10376, 10780, 10844, 10868, 10884, 10888, 11292, 11320, 11356, 11372, 11804, 11808, 11812, 11816, 11820, 11824, 11828, 11832, 11840, 11844, 11860, 11864, 11908, 11912, 12320, 12420, 12828, 12880, 13340, 13368, 13396, 13400, 13852, 13856, 13860, 13864, 13868, 13872, 13876, 14424, 14428, 14432, 14444, 14936, 14944, 14960, 15448, 15472, 15984)
    sw $t4 16492($v1)
    sw $t4 19040($v1)
    li $t4 0x10309c
    draw16($t4, 7260, 7264, 7280, 7772, 7792, 8304, 10824, 11336, 11380, 11888, 11892, 11896, 12364, 13388, 13900, 13904)
    draw16($t4, 14408, 14412, 14416, 14916, 14920, 14924, 14928, 15428, 15432, 15436, 15476, 15936, 15940, 15944, 16448, 16452)
    draw4($t4, 16960, 16964, 17012, 17472)
    draw4($t4, 17476, 17480, 17520, 18004)
    draw4($t4, 18008, 18012, 18016, 18020)
    sw $t4 18024($v1)
    li $t4 0xfde3b2
    draw4($t4, 7760, 7780, 7784, 8280)
    draw4($t4, 8288, 8292, 8296, 8300)
    draw4($t4, 8792, 8796, 8800, 8804)
    sw $t4 8808($v1)
    sw $t4 12864($v1)
    sw $t4 12920($v1)
    li $t4 0xededff
    draw64($t4, 7768, 9764, 9768, 10272, 10276, 10280, 10284, 10288, 10316, 10320, 10324, 10348, 10784, 10788, 10792, 10796, 10800, 10804, 10808, 10832, 10836, 10840, 10860, 10864, 11296, 11300, 11304, 11308, 11312, 11316, 11348, 11352, 12324, 12328, 12332, 12336, 12340, 12344, 12360, 12832, 12836, 12840, 12844, 12848, 12852, 12856, 13344, 13348, 13352, 13356, 13360, 13364, 13404, 14436, 14440, 14940, 14948, 14952, 14956, 15452, 15456, 15460, 15464, 15468)
    draw4($t4, 15964, 15968, 15972, 15976)
    draw4($t4, 15980, 16480, 16484, 16488)
    li $t4 0x008bff
    draw16($t4, 7776, 8284, 11340, 11848, 11852, 15440, 15948, 15952, 15956, 15988, 16456, 16460, 16464, 16468, 16472, 16500)
    draw16($t4, 16968, 16972, 16976, 16980, 16984, 16988, 17008, 17484, 17488, 17492, 17496, 17500, 17504, 17508, 17512, 17516)
    li $t4 0x0b0064
    draw16($t4, 9300, 9816, 9820, 9824, 9828, 10820, 11332, 11384, 11856, 11884, 12372, 12376, 12400, 12876, 13420, 13896)
    draw16($t4, 14404, 14912, 14964, 15424, 15480, 15932, 15992, 16444, 16504, 16956, 17016, 17468, 17524, 17988, 17992, 17996)
    sw $t4 18000($v1)
    sw $t4 18028($v1)
    li $t4 0x674da7
    draw16($t4, 9804, 9812, 9832, 9840, 10312, 10332, 10336, 10344, 10356, 10828, 10856, 11344, 11368, 11376, 12368, 12872)
    draw16($t4, 12884, 12888, 13392, 13416, 13908, 13912, 13916, 13920, 13924, 13928, 13932, 14420, 14448, 14932, 15444, 15960)
    draw4($t4, 16476, 16496, 16992, 16996)
    draw4($t4, 17000, 17004, 18528, 18532)
    draw4($t4, 18536, 18540, 19044, 19052)
    li $t4 0x4d0027
    draw4($t4, 10340, 10848, 10852, 11360)
    draw4($t4, 11364, 11868, 11876, 11880)
    sw $t4 12388($v1)
    sw $t4 12900($v1)
    sw $t4 13412($v1)
    draw16($0, 11396, 11400, 12316, 12424, 12932, 13880, 14364, 14368, 14372, 14376, 14380, 14384, 14388, 14464, 14876, 14880)
    draw16($0, 14884, 14888, 14892, 14896, 14908, 15388, 15392, 15396, 15400, 15484, 17984, 18032, 18036, 18504, 18508, 18512)
    draw4($0, 18516, 18520, 18524, 20060)
    draw4($0, 20072, 20576, 20580, 20588)
    sw $0 20592($v1)
    li $t4 0x880033
    sw $t4 12380($v1)
    sw $t4 12392($v1)
    sw $t4 12892($v1)
    li $t4 0x7a3332
    draw4($t4, 12404, 12412, 12924, 13372)
    sw $t4 13432($v1)
    sw $t4 13436($v1)
    jr $ra
draw_post_doll_14: # start at v1, use t4
    draw64($0, 2128, 2132, 2136, 2140, 2144, 2148, 2152, 2156, 2632, 2636, 2640, 2644, 2648, 2652, 2656, 2660, 2664, 2668, 2672, 2676, 3140, 3144, 3148, 3152, 3156, 3160, 3164, 3168, 3172, 3176, 3180, 3184, 3188, 3192, 3648, 3652, 3656, 3660, 3696, 3700, 3704, 3708, 4160, 4164, 4216, 4220, 4668, 4672, 4732, 4736, 5180, 5248, 5760, 7300, 7812, 8324, 8836, 9348, 11804, 11908, 11912, 12320, 12828, 12832)
    draw4($0, 12836, 12840, 13340, 13344)
    draw4($0, 13348, 13352, 13852, 13856)
    draw4($0, 13860, 13864, 15480, 15992)
    sw $0 20068($v1)
    li $t4 0x91003b
    draw64($t4, 3664, 3672, 3676, 3692, 4168, 4208, 4212, 4676, 4692, 4716, 4728, 5184, 5200, 5236, 5244, 5692, 5708, 5724, 5736, 6200, 6252, 6272, 6712, 6744, 6748, 6752, 6756, 6760, 6764, 6772, 6784, 7220, 7248, 7256, 7272, 7280, 7284, 7296, 7732, 7756, 7760, 7796, 7800, 7808, 8240, 8268, 8272, 8308, 8312, 8320, 8756, 8760, 8764, 8776, 8820, 8824, 8828, 8832, 9272, 9276, 9284, 9288, 9336, 9340)
    draw64($t4, 9344, 9788, 9792, 9796, 9800, 9848, 9852, 9856, 10300, 10304, 10308, 10312, 10316, 10356, 10360, 10364, 10808, 10812, 10816, 10820, 10824, 10828, 10832, 10860, 10864, 10868, 10872, 10876, 11320, 11324, 11328, 11332, 11336, 11384, 11388, 11836, 11840, 11844, 11900, 11904, 12412, 12416, 12844, 12848, 12928, 13356, 13360, 13364, 13868, 13872, 13900, 14380, 14404, 14408, 14444, 14448, 14452, 14456, 14908, 14912, 14916, 14960, 14964, 14968)
    draw4($t4, 14972, 15416, 15420, 15424)
    draw4($t4, 15476, 15484, 15488, 15928)
    draw4($t4, 15932, 16000, 16440, 16512)
    li $t4 0xda7141
    draw16($t4, 3668, 3680, 3684, 3688, 4172, 4184, 4188, 4196, 4200, 4204, 4680, 4720, 5188, 5224, 5696, 5748)
    draw16($t4, 5756, 6204, 6208, 6220, 6236, 6248, 6716, 6740, 6776, 7224, 7228, 7244, 7288, 7736, 7740, 7744)
    draw4($t4, 7752, 8244, 8248, 8252)
    draw4($t4, 8256, 8264, 8316, 8768)
    sw $t4 8772($v1)
    sw $t4 9280($v1)
    li $t4 0xfaa753
    draw16($t4, 4176, 4180, 4192, 4684, 4688, 4708, 4724, 5192, 5232, 5240, 5700, 5720, 5728, 6232, 6264, 6720)
    draw4($t4, 6728, 6732, 7232, 7240)
    sw $t4 7804($v1)
    sw $t4 8260($v1)
    sw $t4 8276($v1)
    li $t4 0xd1003f
    draw4($t4, 4696, 4700, 4704, 4712)
    draw4($t4, 5208, 5212, 5216, 5712)
    draw4($t4, 13404, 13408, 13412, 13420)
    sw $t4 13924($v1)
    li $t4 0xfaff53
    draw16($t4, 5196, 5204, 5220, 5228, 5704, 5716, 5732, 5740, 5744, 5752, 6212, 6216, 6224, 6228, 6240, 6244)
    draw4($t4, 6256, 6260, 6268, 6724)
    draw4($t4, 6736, 6768, 6780, 7236)
    sw $t4 7292($v1)
    sw $t4 7748($v1)
    li $t4 0xbd6455
    draw16($t4, 7252, 7260, 7264, 7268, 7276, 7764, 7792, 8292, 8780, 8784, 8804, 9292, 9332, 9804, 9844, 10320)
    draw4($t4, 10352, 10840, 10844, 10848)
    draw4($t4, 10852, 10856, 13876, 13952)
    draw4($t4, 14388, 14396, 14460, 14904)
    li $t4 0xaa90e0
    draw64($t4, 7708, 7712, 7716, 7720, 8220, 8236, 8732, 8752, 8792, 9248, 9268, 9756, 9760, 9764, 9768, 9784, 9860, 9864, 10268, 10280, 10284, 10288, 10292, 10296, 10368, 10372, 10376, 10780, 10800, 10804, 10880, 10884, 10888, 11292, 11316, 11344, 11392, 11396, 11808, 11832, 11868, 12324, 12328, 12332, 12336, 12348, 12352, 12368, 12396, 12400, 12404, 12408, 12420, 12424, 12852, 12856, 12936, 13372, 14416, 14932, 14936, 14952, 15952, 15964)
    draw4($t4, 15968, 15972, 15980, 16496)
    draw4($t4, 16980, 16984, 16988, 16992)
    sw $t4 16996($v1)
    sw $t4 17000($v1)
    sw $t4 17004($v1)
    li $t4 0xffaa73
    draw16($t4, 7768, 7772, 7776, 7780, 7784, 7788, 8296, 8300, 8808, 8812, 9300, 9324, 9808, 9812, 10324, 10348)
    li $t4 0xededff
    draw16($t4, 8224, 8228, 8232, 8736, 8740, 8744, 8748, 9252, 9256, 9260, 9264, 9304, 9772, 9776, 9780, 10272)
    draw16($t4, 10276, 10784, 10788, 10792, 10796, 11296, 11300, 11304, 11308, 11312, 11372, 11376, 11812, 11816, 11820, 11824)
    draw16($t4, 11828, 11852, 11856, 11860, 11864, 11880, 11884, 11888, 11892, 12340, 12344, 12372, 12376, 12380, 12384, 13884)
    draw4($t4, 14940, 14944, 14948, 15956)
    draw4($t4, 15960, 15976, 16464, 16468)
    draw4($t4, 16472, 16476, 16480, 16484)
    sw $t4 16488($v1)
    sw $t4 16492($v1)
    li $t4 0x2b1408
    draw16($t4, 8280, 8284, 8288, 8304, 8788, 20052, 20056, 20060, 20064, 20072, 20076, 20080, 20568, 20572, 20576, 20584)
    sw $t4 20588($v1)
    sw $t4 20592($v1)
    li $t4 0x10309c
    draw64($t4, 8796, 8800, 8816, 9308, 9328, 9840, 12360, 12864, 12872, 12876, 12920, 13384, 13428, 13432, 13436, 13440, 13880, 13888, 13892, 13944, 14924, 15432, 15436, 15440, 15940, 15944, 16448, 16452, 16456, 16500, 16956, 16960, 16964, 16968, 17012, 17468, 17472, 17476, 17480, 17484, 17488, 17492, 17528, 17980, 17984, 17988, 17992, 17996, 18040, 18492, 18496, 18500, 18504, 18552, 19008, 19012, 19016, 19020, 19056, 19540, 19544, 19548, 19552, 19556)
    sw $t4 19560($v1)
    li $t4 0xfde3b2
    draw4($t4, 9296, 9316, 9320, 9816)
    draw4($t4, 9824, 9828, 9832, 9836)
    draw4($t4, 10328, 10332, 10336, 10340)
    sw $t4 10344($v1)
    sw $t4 14392($v1)
    sw $t4 14464($v1)
    li $t4 0x008bff
    draw16($t4, 9312, 9820, 12868, 13376, 13380, 17496, 17500, 17504, 17508, 17512, 17516, 17520, 17524, 18000, 18004, 18008)
    draw16($t4, 18012, 18016, 18020, 18024, 18028, 18032, 18036, 18508, 18512, 18516, 18520, 18524, 18528, 18532, 18536, 18540)
    draw4($t4, 18544, 18548, 19024, 19028)
    draw4($t4, 19032, 19036, 19040, 19044)
    sw $t4 19048($v1)
    sw $t4 19052($v1)
    li $t4 0x0b0064
    draw16($t4, 10836, 11352, 11356, 11360, 11364, 12356, 12860, 12924, 13388, 13392, 13396, 13444, 13896, 13908, 13912, 13916)
    draw16($t4, 13936, 13940, 13948, 14412, 14920, 15428, 15472, 15936, 15988, 16444, 16504, 16952, 17016, 17464, 17532, 17976)
    draw4($t4, 18044, 18488, 18556, 19004)
    draw4($t4, 19060, 19064, 19520, 19524)
    draw4($t4, 19528, 19532, 19536, 19564)
    sw $t4 19568($v1)
    li $t4 0x674da7
    draw16($t4, 11340, 11348, 11368, 11380, 11848, 11872, 11876, 11896, 12364, 12880, 12884, 12888, 12892, 12916, 13368, 13904)
    draw16($t4, 14400, 14420, 14424, 14428, 14432, 14436, 14440, 14928, 14956, 15444, 15448, 15452, 15456, 15460, 15464, 15468)
    draw4($t4, 15948, 15984, 16460, 16972)
    sw $t4 16976($v1)
    sw $t4 17008($v1)
    li $t4 0x4d0027
    draw4($t4, 12388, 12392, 12896, 12900)
    draw4($t4, 12904, 12908, 12912, 13400)
    draw4($t4, 13416, 13424, 13928, 13932)
    li $t4 0x880033
    sw $t4 13920($v1)
    li $t4 0x7a3332
    draw4($t4, 13956, 14468, 14900, 14976)
    sw $t4 14980($v1)
    jr $ra
draw_post_doll_15: # start at v1, use t4
    li $t4 0x91003b
    draw64($t4, 584, 592, 596, 612, 1088, 1128, 1132, 1596, 1612, 1636, 1648, 2104, 2120, 2140, 2156, 2164, 2616, 2628, 2656, 3124, 3156, 3168, 3192, 3636, 3656, 3668, 3680, 3684, 3692, 3704, 4148, 4168, 4180, 4192, 4196, 4204, 4216, 4660, 4676, 4680, 4688, 4692, 4696, 4704, 4716, 5172, 5188, 5192, 5216, 5228, 5236, 5688, 5696, 5724, 5740, 5748, 6200, 6208, 6220, 6256, 6260, 6712, 6720, 6732)
    draw64($t4, 6768, 6772, 7224, 7232, 7236, 7276, 7280, 7284, 7736, 7744, 7748, 7752, 7780, 7784, 7788, 7792, 7796, 8248, 8252, 8256, 8300, 8304, 8308, 8760, 8764, 8816, 8820, 9268, 9272, 9328, 9332, 9336, 9780, 9784, 9844, 9848, 10292, 10356, 10360, 10852, 10872, 11364, 11368, 11384, 11836, 11840, 11880, 11884, 11896, 12340, 12344, 12348, 12396, 12400, 12404, 12408, 12852, 12856, 12908, 12912, 12916, 13368, 13424, 13428)
    li $t4 0xda7141
    draw16($t4, 588, 600, 604, 608, 1092, 1104, 1108, 1120, 1124, 1600, 1640, 2108, 2144, 2620, 2640, 2644)
    draw16($t4, 2660, 2668, 2676, 3128, 3144, 3172, 3180, 3640, 4152, 4164, 4176, 4184, 4212, 4664, 4724, 5176)
    draw4($t4, 5708, 5744, 7228, 7740)
    li $t4 0xfaa753
    draw16($t4, 1096, 1100, 1112, 1116, 1604, 1608, 1644, 2112, 2148, 2152, 2160, 2652, 3132, 3140, 3152, 3188)
    draw4($t4, 3644, 3652, 3664, 3672)
    draw4($t4, 3700, 4156, 4668, 4720)
    draw4($t4, 5180, 5196, 5232, 5692)
    sw $t4 6204($v1)
    sw $t4 6716($v1)
    li $t4 0xd1003f
    draw4($t4, 1616, 1620, 1624, 1628)
    draw4($t4, 1632, 2124, 2128, 2132)
    draw4($t4, 2136, 2632, 10328, 10840)
    sw $t4 11352($v1)
    sw $t4 11360($v1)
    sw $t4 11864($v1)
    li $t4 0xfaff53
    draw16($t4, 2116, 2624, 2636, 2648, 2664, 2672, 3136, 3148, 3160, 3164, 3176, 3184, 3648, 3660, 3676, 3688)
    draw4($t4, 3696, 4160, 4172, 4188)
    draw4($t4, 4200, 4208, 4672, 4684)
    draw4($t4, 4700, 4712, 5184, 5212)
    li $t4 0xffaa73
    draw4($t4, 4708, 5220, 5728, 5732)
    draw4($t4, 6244, 6728, 7244, 7268)
    draw64($0, 4728, 5240, 5244, 5752, 5756, 6264, 6268, 6272, 6776, 6780, 6784, 7220, 7288, 7292, 7296, 7708, 7712, 7716, 7720, 7732, 7800, 7804, 7808, 8220, 8224, 8228, 8232, 8236, 8240, 8244, 8320, 8732, 9852, 9856, 9860, 9864, 10372, 10376, 10880, 10884, 10888, 11388, 11392, 11396, 11900, 11904, 12336, 12412, 12416, 12420, 12424, 12844, 12848, 12920, 12924, 12928, 12936, 13356, 13360, 13364, 13432, 13436, 13440, 13444)
    draw64($0, 13868, 13872, 13876, 13936, 13940, 13944, 13948, 13952, 13956, 14380, 14388, 14448, 14452, 14456, 14460, 14464, 14468, 14900, 14960, 14964, 14968, 14972, 14976, 14980, 15472, 15476, 15484, 15488, 15984, 15988, 16000, 16440, 16444, 16488, 16492, 16496, 16500, 16504, 16512, 16952, 16956, 16960, 16964, 16968, 16972, 16976, 16980, 17000, 17004, 17008, 17012, 17016, 17464, 17468, 17472, 17476, 17480, 17484, 17488, 17512, 17516, 17520, 17524, 17528)
    draw64($0, 17532, 17976, 17980, 17984, 17988, 17992, 17996, 18000, 18028, 18032, 18036, 18040, 18044, 18488, 18492, 18496, 18500, 18504, 18508, 18512, 18516, 18528, 18540, 18544, 18548, 18552, 18556, 19004, 19008, 19012, 19016, 19020, 19024, 19028, 19032, 19036, 19040, 19044, 19048, 19052, 19056, 19060, 19064, 19520, 19524, 19528, 19532, 19536, 19540, 19544, 19548, 19552, 19556, 19560, 19564, 19568, 20052, 20056, 20060, 20064, 20072, 20076, 20080, 20568)
    draw4($0, 20572, 20576, 20584, 20588)
    sw $0 20592($v1)
    li $t4 0x2b1408
    draw16($t4, 5200, 5204, 5208, 5224, 17492, 17504, 18004, 18008, 18012, 18016, 18020, 18024, 18520, 18524, 18532, 18536)
    li $t4 0xbd6455
    draw16($t4, 5700, 5704, 6212, 6252, 6724, 6764, 7240, 7272, 7760, 7764, 7768, 7772, 7776, 10804, 10808, 10812)
    draw4($t4, 10864, 11316, 11324, 11372)
    sw $t4 11832($v1)
    li $t4 0xaa90e0
    draw64($t4, 5712, 8264, 8292, 8312, 8316, 8736, 8740, 8744, 8748, 8752, 8756, 8784, 8808, 8824, 8828, 8832, 9240, 9244, 9292, 9296, 9312, 9324, 9340, 9344, 9748, 9776, 9804, 9808, 9812, 9824, 9828, 10260, 10280, 10284, 10288, 10296, 10300, 10316, 10320, 10364, 10368, 10772, 10784, 10788, 10792, 10796, 10876, 11284, 11288, 11292, 11296, 11300, 11336, 11800, 11824, 11852, 11856, 12308, 12332, 12820, 12836, 12840, 12884, 12888)
    draw4($t4, 12900, 13332, 13336, 13340)
    draw4($t4, 13344, 13400, 13416, 14420)
    draw4($t4, 14440, 15448, 15460, 17496)
    li $t4 0x10309c
    draw16($t4, 5716, 5720, 5736, 6228, 6248, 6760, 9280, 9792, 9836, 10344, 10348, 10352, 10820, 11844, 12356, 12360)
    draw16($t4, 12364, 12864, 12868, 12872, 12876, 13376, 13380, 13384, 13884, 13888, 13892, 13932, 14396, 14400, 14404, 14444)
    draw4($t4, 14908, 14912, 14956, 15420)
    draw4($t4, 15424, 15468, 15932, 15936)
    draw4($t4, 15940, 16460, 16464, 16468)
    sw $t4 16472($v1)
    sw $t4 16476($v1)
    sw $t4 16480($v1)
    li $t4 0xfde3b2
    draw4($t4, 6216, 6236, 6240, 6736)
    draw4($t4, 6744, 6748, 6752, 6756)
    draw4($t4, 7248, 7252, 7256, 7260)
    sw $t4 7264($v1)
    sw $t4 11320($v1)
    sw $t4 11376($v1)
    li $t4 0xededff
    draw64($t4, 6224, 8772, 8776, 8780, 8800, 8804, 9248, 9252, 9256, 9260, 9264, 9288, 9300, 9316, 9320, 9752, 9756, 9760, 9764, 9768, 9772, 10264, 10268, 10272, 10276, 10776, 10780, 10800, 10816, 11304, 11308, 11312, 11804, 11808, 11812, 11816, 11820, 11860, 12312, 12316, 12320, 12324, 12328, 12824, 12828, 12832, 12892, 12896, 13396, 13404, 13408, 13412, 13908, 13912, 13916, 13920, 13924, 14424, 14428, 14432, 14436, 14936, 14940, 14944)
    sw $t4 14948($v1)
    sw $t4 15452($v1)
    sw $t4 15456($v1)
    li $t4 0x008bff
    draw16($t4, 6232, 6740, 9796, 10304, 10308, 13388, 13896, 13900, 14408, 14412, 14916, 14920, 14924, 14928, 15428, 15432)
    draw4($t4, 15436, 15440, 15944, 15948)
    sw $t4 15952($v1)
    sw $t4 15956($v1)
    sw $t4 15976($v1)
    li $t4 0x0b0064
    draw16($t4, 7756, 8272, 8276, 8280, 8284, 9276, 9788, 9840, 10312, 10340, 10828, 10832, 10856, 11332, 11876, 12352)
    draw4($t4, 12860, 13372, 13420, 13880)
    draw4($t4, 14392, 14904, 15416, 15928)
    draw4($t4, 15980, 16448, 16452, 16456)
    sw $t4 16484($v1)
    li $t4 0x674da7
    draw16($t4, 8260, 8268, 8288, 8296, 8768, 8788, 8792, 8796, 8812, 9284, 9800, 9832, 10824, 11328, 11340, 11344)
    draw16($t4, 11848, 11872, 12368, 12372, 12376, 12380, 12384, 12388, 12392, 12880, 12904, 13392, 13904, 13928, 14416, 14932)
    draw4($t4, 14952, 15444, 15464, 15960)
    draw4($t4, 15964, 15968, 15972, 16984)
    draw4($t4, 16988, 16992, 16996, 17500)
    sw $t4 17508($v1)
    li $t4 0x4d0027
    draw4($t4, 9304, 9308, 9816, 9820)
    draw4($t4, 10324, 10332, 10336, 10844)
    sw $t4 11356($v1)
    sw $t4 11868($v1)
    li $t4 0x880033
    sw $t4 10836($v1)
    sw $t4 10848($v1)
    sw $t4 11348($v1)
    li $t4 0x7a3332
    draw4($t4, 10860, 10868, 11380, 11828)
    sw $t4 11888($v1)
    sw $t4 11892($v1)
    jr $ra
draw_post_doll_16: # start at v1, use t4
    li $t4 0x91003b
    draw64($t4, 68, 76, 80, 92, 96, 572, 600, 608, 612, 616, 1080, 1112, 1120, 1132, 1588, 1640, 1648, 2100, 2608, 2660, 2676, 3120, 3160, 3172, 3188, 3632, 3672, 3684, 3700, 4144, 4180, 4184, 4192, 4196, 4200, 4204, 4212, 4656, 4692, 4696, 4704, 4708, 4712, 4716, 4724, 5192, 5216, 5224, 5232, 5236, 5676, 5704, 5724, 5740, 5744, 6188, 6204, 6216, 6252, 6700, 6716, 6728, 6740, 6744)
    draw64($t4, 6760, 6764, 7212, 7224, 7252, 7256, 7260, 7264, 7268, 7272, 7724, 7732, 7748, 7760, 8236, 8240, 8256, 8748, 8752, 8764, 8768, 9260, 9272, 9276, 9288, 9768, 9776, 9780, 9784, 9788, 9800, 9824, 10280, 10284, 10288, 10292, 10296, 10308, 10312, 10332, 10336, 10792, 10800, 10804, 10812, 10816, 10820, 10848, 10852, 10856, 10860, 11304, 11312, 11316, 11320, 11324, 11328, 11364, 11368, 11372, 11820, 11824, 11828, 11832)
    draw4($t4, 11836, 11848, 11880, 12332)
    draw4($t4, 12336, 12340, 12344, 12348)
    draw4($t4, 12352, 12356, 12392, 12844)
    sw $t4 12856($v1)
    sw $t4 12864($v1)
    sw $t4 12868($v1)
    li $t4 0xda7141
    draw16($t4, 72, 84, 88, 576, 588, 592, 1124, 1592, 1620, 1632, 2132, 2148, 2160, 2612, 2648, 3124)
    draw16($t4, 3180, 3668, 3680, 3688, 3692, 4680, 4720, 5168, 5212, 5228, 5692, 6200, 6212, 6712, 6724, 7220)
    draw16($t4, 7228, 7236, 7240, 7728, 7736, 7744, 8244, 8252, 8260, 8268, 8760, 8776, 9264, 9268, 9280, 9772)
    draw4($t4, 9796, 10304, 10808, 10824)
    draw4($t4, 11332, 11336, 11840, 11844)
    li $t4 0xfaa753
    draw16($t4, 580, 584, 596, 1084, 1100, 1104, 1108, 1128, 1616, 1636, 1644, 2104, 2136, 2144, 2644, 2668)
    draw16($t4, 3156, 3168, 3176, 3636, 3656, 4148, 4160, 4168, 4208, 4660, 4672, 4676, 4700, 5172, 5180, 5184)
    draw16($t4, 5188, 5680, 5688, 5696, 5700, 6196, 6208, 6704, 6708, 6720, 7216, 7232, 7248, 7740, 7756, 8248)
    draw4($t4, 8756, 9284, 9792, 10300)
    li $t4 0xd1003f
    draw4($t4, 604, 1116, 1624, 1628)
    li $t4 0xfaff53
    draw64($t4, 1088, 1092, 1096, 1596, 1600, 1604, 1608, 1612, 2108, 2112, 2116, 2120, 2124, 2128, 2140, 2152, 2156, 2616, 2620, 2624, 2628, 2632, 2636, 2640, 2652, 2656, 2664, 2672, 3128, 3132, 3136, 3140, 3144, 3148, 3152, 3164, 3184, 3640, 3644, 3648, 3652, 3660, 3664, 3676, 3696, 4152, 4156, 4164, 4172, 4176, 4188, 4664, 4668, 4684, 4688, 5176, 5196, 5200, 5684, 5708, 5712, 6192, 6220, 6224)
    draw4($t4, 6732, 6736, 7244, 7752)
    sw $t4 8264($v1)
    sw $t4 8772($v1)
    draw64($0, 2164, 3192, 3704, 4216, 5748, 6256, 6260, 6768, 6772, 7276, 7280, 7284, 7788, 7792, 7796, 8304, 8308, 8312, 8316, 8736, 8816, 8820, 8824, 8828, 8832, 9240, 9244, 9248, 9252, 9332, 9336, 9340, 9344, 9748, 9752, 9756, 9760, 9764, 10260, 10264, 10268, 10272, 10276, 10368, 10772, 10776, 10780, 10784, 10788, 10796, 11284, 11288, 11292, 11296, 11300, 11308, 11376, 11800, 11804, 11808, 11812, 11816, 11884, 11888)
    draw16($0, 11892, 11896, 12308, 12312, 12316, 12320, 12324, 12328, 12396, 12400, 12404, 12408, 12820, 12824, 12828, 12832)
    draw16($0, 12836, 12840, 12908, 12912, 12916, 13332, 13336, 13340, 13344, 13420, 13424, 13428, 13932, 15980, 16448, 16452)
    draw4($0, 16456, 16460, 16484, 18012)
    draw4($0, 18024, 18520, 18524, 18532)
    sw $0 18536($v1)
    li $t4 0xbd6455
    draw4($t4, 5204, 5208, 5716, 5736)
    draw4($t4, 6228, 6248, 6756, 10868)
    sw $t4 10872($v1)
    li $t4 0xffaa73
    draw4($t4, 5220, 5728, 6232, 6236)
    sw $t4 6748($v1)
    li $t4 0xfde3b2
    draw4($t4, 5720, 5732, 6240, 6244)
    sw $t4 6752($v1)
    li $t4 0x674da7
    draw16($t4, 6696, 7204, 7768, 7772, 7784, 8272, 8284, 8300, 8740, 8780, 8796, 9256, 9292, 9308, 9804, 9820)
    draw16($t4, 10316, 10828, 10840, 10844, 11340, 11352, 11356, 11360, 11872, 11876, 12384, 12896, 12904, 13416, 13916, 13928)
    draw16($t4, 14428, 14432, 15436, 15440, 15444, 15448, 15948, 15952, 15956, 15960, 15964, 16464, 16468, 16472, 16476, 16480)
    sw $t4 16984($v1)
    sw $t4 16992($v1)
    li $t4 0xaa90e0
    draw16($t4, 7208, 7716, 7764, 7776, 7780, 8228, 8280, 8296, 8792, 8812, 9304, 9816, 10320, 10324, 10328, 10836)
    draw4($t4, 11344, 11348, 11856, 12388)
    sw $t4 13408($v1)
    sw $t4 13924($v1)
    sw $t4 16980($v1)
    li $t4 0xededff
    draw16($t4, 7720, 8232, 8276, 8288, 8292, 8744, 8784, 8788, 8800, 8804, 8808, 9296, 9300, 9312, 9316, 9320)
    draw4($t4, 9808, 9812, 10832, 12900)
    sw $t4 13412($v1)
    sw $t4 13920($v1)
    li $t4 0x10309c
    draw16($t4, 9324, 9832, 9836, 9840, 9844, 9848, 10348, 10352, 10356, 10864, 11852, 11860, 11864, 11868, 12360, 12364)
    draw16($t4, 12368, 12372, 12376, 12380, 12860, 12872, 12876, 12880, 12884, 12888, 12892, 13368, 13372, 13376, 13380, 13384)
    draw16($t4, 13388, 13392, 13876, 13880, 13884, 13888, 13892, 13896, 14388, 14392, 14396, 14444, 14900, 14904, 14908, 14920)
    draw4($t4, 14924, 14928, 14932, 14936)
    sw $t4 14940($v1)
    sw $t4 14952($v1)
    sw $t4 14956($v1)
    li $t4 0x0b0064
    draw16($t4, 9328, 9828, 10340, 10344, 12852, 13364, 13872, 14384, 14440, 14896, 14912, 14916, 14944, 15408, 15412, 15416)
    draw16($t4, 15420, 15424, 15428, 15432, 15452, 15456, 15460, 15464, 15468, 15924, 15928, 15932, 15936, 15940, 15944, 15968)
    sw $t4 15972($v1)
    sw $t4 15976($v1)
    li $t4 0x7a3332
    draw4($t4, 10360, 10364, 10876, 11380)
    sw $t4 11384($v1)
    sw $t4 11388($v1)
    li $t4 0x008bff
    draw16($t4, 13396, 13400, 13404, 13900, 13904, 13908, 13912, 14400, 14404, 14408, 14412, 14416, 14420, 14424, 14436, 14948)
    li $t4 0x2b1408
    draw4($t4, 16976, 16988, 16996, 17488)
    draw4($t4, 17492, 17496, 17500, 17504)
    draw4($t4, 17508, 18004, 18008, 18016)
    sw $t4 18020($v1)
    jr $ra
draw_post_doll_17: # start at v1, use t4
    li $t4 0x91003b
    draw64($t4, 60, 64, 76, 80, 88, 564, 568, 572, 580, 608, 1072, 1084, 1092, 1124, 1580, 1588, 1640, 2152, 2600, 2616, 2668, 3112, 3128, 3140, 3180, 3624, 3640, 3652, 3692, 4136, 4144, 4148, 4152, 4156, 4164, 4168, 4208, 4648, 4656, 4660, 4664, 4668, 4676, 4680, 4720, 5160, 5164, 5172, 5180, 5188, 5204, 5232, 5676, 5680, 5696, 5700, 5716, 5744, 6192, 6212, 6240, 6252, 6256, 6704)
    draw64($t4, 6708, 6724, 6752, 6764, 6768, 7220, 7224, 7228, 7232, 7236, 7264, 7276, 7744, 7776, 7788, 8256, 8284, 8288, 8300, 8768, 8796, 8800, 8812, 9280, 9308, 9312, 9324, 9788, 9800, 9816, 9820, 9832, 9836, 10300, 10308, 10312, 10324, 10328, 10332, 10344, 10348, 10808, 10816, 10820, 10824, 10828, 10832, 10836, 10840, 10852, 10856, 10860, 11320, 11324, 11336, 11348, 11356, 11368, 11372, 11828, 11832, 11860, 11864, 11880)
    sw $t4 12340($v1)
    sw $t4 12392($v1)
    li $t4 0xda7141
    draw16($t4, 68, 72, 84, 588, 592, 604, 1080, 1596, 1608, 1636, 2092, 2104, 2120, 2628, 2664, 3120)
    draw16($t4, 3176, 3632, 3636, 3644, 3656, 4204, 4652, 4692, 4716, 5168, 5184, 5192, 5200, 5228, 5712, 5728)
    draw16($t4, 5740, 6220, 7748, 7772, 8260, 8776, 9288, 9320, 9796, 9824, 10304, 10340, 10812, 10844, 10848, 11352)
    draw64($0, 92, 96, 612, 616, 1128, 1132, 1644, 1648, 2156, 2160, 2672, 2676, 3184, 3188, 3696, 3700, 4212, 4724, 5236, 6188, 6696, 6700, 7204, 7208, 7212, 7216, 7716, 7720, 7724, 7728, 8228, 8232, 8236, 8740, 8744, 8748, 9256, 9840, 9844, 9848, 10352, 10356, 10360, 10364, 10800, 10804, 10864, 10868, 10872, 10876, 11312, 11316, 11380, 11384, 11388, 11820, 11824, 12332, 12336, 12844, 15408, 15468, 15924, 15928)
    draw4($0, 15972, 15976, 16476, 16480)
    draw4($0, 16988, 16992, 16996, 17500)
    draw4($0, 17504, 17508, 18008, 18016)
    sw $0 18020($v1)
    li $t4 0xd1003f
    draw4($t4, 576, 1088, 1600, 1604)
    li $t4 0xfaa753
    draw16($t4, 584, 596, 600, 1076, 1096, 1100, 1104, 1120, 1584, 1592, 1612, 2108, 2116, 2148, 2608, 2632)
    draw16($t4, 3124, 3132, 3144, 3668, 3688, 4140, 4180, 4200, 4672, 4688, 4712, 5216, 5224, 5704, 5732, 5736)
    draw16($t4, 6244, 6248, 6756, 6760, 7260, 7268, 7272, 7780, 7784, 8292, 8296, 8804, 8808, 9304, 9316, 9812)
    sw $t4 9828($v1)
    sw $t4 10320($v1)
    sw $t4 10336($v1)
    li $t4 0xfaff53
    draw64($t4, 1108, 1112, 1116, 1616, 1620, 1624, 1628, 1632, 2096, 2100, 2112, 2124, 2128, 2132, 2136, 2140, 2144, 2604, 2612, 2620, 2624, 2636, 2640, 2644, 2648, 2652, 2656, 2660, 3116, 3136, 3148, 3152, 3156, 3160, 3164, 3168, 3172, 3628, 3648, 3660, 3664, 3672, 3676, 3680, 3684, 4160, 4172, 4176, 4184, 4188, 4192, 4196, 4684, 4696, 4700, 4704, 4708, 5196, 5208, 5212, 5220, 5708, 5720, 5724)
    draw4($t4, 6216, 6232, 6236, 6728)
    draw4($t4, 6744, 6748, 7240, 7752)
    draw4($t4, 8264, 8772, 9284, 9792)
    li $t4 0xffaa73
    draw4($t4, 5176, 5692, 6208, 6720)
    li $t4 0xbd6455
    draw4($t4, 5684, 6196, 6712, 10788)
    sw $t4 10792($v1)
    li $t4 0xfde3b2
    draw4($t4, 5688, 6200, 6204, 6716)
    li $t4 0xaa90e0
    draw16($t4, 6224, 6228, 6732, 6740, 7244, 7256, 7284, 7736, 7740, 7756, 7768, 7796, 8244, 8268, 8752, 8816)
    sw $t4 16980($v1)
    li $t4 0xededff
    draw16($t4, 6736, 7248, 7252, 7280, 7760, 7764, 7792, 8248, 8252, 8272, 8276, 8304, 8756, 8760, 8764, 8784)
    draw4($t4, 8788, 9268, 9272, 9276)
    sw $t4 9296($v1)
    li $t4 0x674da7
    draw16($t4, 6772, 7732, 8240, 8280, 8308, 8780, 8792, 9292, 9300, 9328, 9804, 9808, 10316, 11836, 12344, 12852)
    draw4($t4, 15436, 15440, 15444, 15448)
    draw4($t4, 15948, 15952, 15956, 15960)
    draw4($t4, 16456, 16460, 16464, 16468)
    sw $t4 16472($v1)
    sw $t4 16968($v1)
    sw $t4 16976($v1)
    li $t4 0x0b0064
    draw16($t4, 9260, 9784, 10292, 10296, 11328, 11332, 11360, 11364, 11840, 11872, 11876, 12348, 12384, 12388, 12856, 12896)
    draw16($t4, 12900, 12904, 13364, 13416, 13872, 13876, 13932, 14384, 14444, 14896, 14936, 14940, 14944, 14956, 15412, 15416)
    draw4($t4, 15420, 15424, 15428, 15432)
    draw4($t4, 15452, 15456, 15460, 15464)
    draw4($t4, 15932, 15936, 15940, 15944)
    sw $t4 15964($v1)
    sw $t4 15968($v1)
    li $t4 0x10309c
    draw16($t4, 9264, 9764, 9768, 9772, 9776, 9780, 10280, 10284, 10288, 10796, 11340, 11344, 11844, 11848, 11852, 11856)
    draw16($t4, 11868, 12352, 12356, 12360, 12364, 12368, 12372, 12376, 12380, 12860, 12864, 12868, 12872, 12876, 12880, 12884)
    draw16($t4, 12888, 12892, 13368, 13372, 13388, 13392, 13396, 13400, 13404, 13408, 13412, 13880, 13904, 13908, 13912, 13916)
    draw4($t4, 13920, 13924, 13928, 14388)
    draw4($t4, 14428, 14432, 14436, 14440)
    draw4($t4, 14900, 14924, 14928, 14932)
    sw $t4 14948($v1)
    sw $t4 14952($v1)
    li $t4 0x7a3332
    draw4($t4, 10272, 10276, 10784, 11296)
    sw $t4 11300($v1)
    sw $t4 11304($v1)
    li $t4 0x008bff
    draw16($t4, 13376, 13380, 13384, 13884, 13888, 13892, 13896, 13900, 14392, 14396, 14400, 14404, 14408, 14412, 14416, 14420)
    draw4($t4, 14424, 14904, 14908, 14912)
    sw $t4 14916($v1)
    sw $t4 14920($v1)
    li $t4 0x2b1408
    draw4($t4, 16964, 16972, 16984, 17476)
    draw4($t4, 17480, 17484, 17488, 17492)
    draw4($t4, 17496, 17988, 17992, 18000)
    sw $t4 18004($v1)
    jr $ra
draw_post_doll_18: # start at v1, use t4
    draw16($0, 60, 64, 68, 72, 76, 80, 84, 88, 564, 600, 604, 608, 1120, 1124, 1636, 1640)
    draw16($0, 2152, 2664, 2668, 3180, 3692, 4204, 4208, 4720, 5232, 5744, 9764, 9768, 10272, 10276, 10280, 10784)
    draw16($0, 10788, 10792, 11296, 11300, 11304, 13932, 14444, 14956, 16972, 16976, 16980, 16984, 17484, 17488, 17492, 17496)
    sw $0 18000($v1)
    sw $0 18004($v1)
    li $t4 0x91003b
    draw64($t4, 568, 584, 588, 596, 1072, 1076, 1116, 1580, 1608, 1632, 2088, 2096, 2104, 2124, 2148, 2612, 2660, 3108, 3124, 3136, 3148, 3176, 3616, 3632, 3648, 3660, 3664, 3688, 4128, 4144, 4160, 4172, 4176, 4636, 4644, 4652, 4656, 4668, 4672, 4684, 4716, 5156, 5164, 5168, 5172, 5196, 5228, 5668, 5672, 5680, 5708, 5724, 5740, 6184, 6188, 6216, 6220, 6236, 6244, 6248, 6696, 6700, 6728, 6748)
    draw64($t4, 6756, 7208, 7212, 7216, 7240, 7260, 7720, 7724, 7728, 7732, 7736, 7752, 7772, 8232, 8236, 8240, 8260, 8268, 8272, 8280, 8284, 8744, 8748, 8768, 8776, 8784, 8792, 8796, 8804, 9260, 9276, 9280, 9284, 9292, 9300, 9304, 9308, 9316, 9772, 9800, 9808, 9820, 9828, 10284, 10312, 10316, 10336, 10340, 10796, 10820, 10840, 10844, 10848, 10852, 10856, 10860, 11308, 11356, 11360, 11364, 11368, 11372, 11820, 11824)
    draw4($t4, 11828, 11848, 11852, 11872)
    draw4($t4, 11876, 11880, 11884, 12336)
    draw4($t4, 12388, 12392, 12396, 12848)
    sw $t4 12904($v1)
    sw $t4 12908($v1)
    sw $t4 13420($v1)
    li $t4 0xda7141
    draw16($t4, 572, 576, 580, 592, 1080, 1084, 1096, 1100, 1112, 1588, 1628, 2144, 2600, 2608, 2624, 3120)
    draw16($t4, 3152, 3172, 3628, 4140, 4156, 4200, 4664, 4680, 4688, 5160, 5192, 5212, 5676, 5704, 5732, 6732)
    draw4($t4, 6740, 7252, 7760, 7764)
    draw4($t4, 8276, 8788, 8800, 9312)
    sw $t4 9804($v1)
    sw $t4 9824($v1)
    sw $t4 10332($v1)
    li $t4 0xfaa753
    draw16($t4, 1088, 1092, 1104, 1108, 1584, 1612, 2092, 2100, 2140, 2616, 2628, 2640, 2656, 3116, 3168, 3620)
    draw16($t4, 3636, 3644, 3684, 4136, 4152, 4168, 4188, 4196, 4648, 4700, 4708, 4712, 5200, 5216, 5220, 5224)
    draw4($t4, 5728, 5736, 6228, 6240)
    draw4($t4, 6752, 7248, 7264, 7776)
    sw $t4 8288($v1)
    sw $t4 8772($v1)
    li $t4 0xd1003f
    draw4($t4, 1592, 1596, 1600, 1604)
    draw4($t4, 2108, 2112, 2116, 2120)
    draw4($t4, 2636, 10304, 10816, 11320)
    sw $t4 11324($v1)
    sw $t4 11332($v1)
    li $t4 0xfaff53
    draw16($t4, 1616, 1620, 1624, 2128, 2132, 2136, 2604, 2620, 2632, 2644, 2648, 2652, 3112, 3128, 3132, 3140)
    draw16($t4, 3144, 3156, 3160, 3164, 3624, 3640, 3652, 3656, 3668, 3672, 3676, 3680, 4132, 4148, 4164, 4180)
    draw16($t4, 4184, 4192, 4660, 4676, 4692, 4696, 4704, 5204, 5208, 5712, 5716, 5720, 6224, 6232, 6736, 6744)
    draw4($t4, 7244, 7256, 7756, 7768)
    sw $t4 8264($v1)
    sw $t4 9296($v1)
    li $t4 0xffaa73
    draw4($t4, 5176, 5684, 5688, 7224)
    li $t4 0x2b1408
    draw16($t4, 5180, 5184, 5188, 17460, 17468, 17480, 17972, 17976, 17980, 17984, 17988, 17992, 18488, 18492, 18496, 18500)
    li $t4 0xaa90e0
    draw16($t4, 5692, 6252, 6256, 6260, 6264, 6760, 6776, 7204, 7268, 7288, 7716, 7800, 8248, 8292, 8296, 8300)
    draw16($t4, 8304, 8312, 8756, 8780, 8828, 9264, 9340, 9784, 9796, 9852, 10344, 10348, 10364, 10864, 10868, 10872)
    draw4($t4, 11836, 12852, 12856, 12864)
    draw4($t4, 13364, 13372, 14388, 17472)
    li $t4 0x10309c
    draw64($t4, 5696, 5700, 6208, 6212, 10288, 10320, 10824, 10832, 11864, 12364, 12368, 12372, 12376, 12380, 12872, 12876, 12880, 12884, 12888, 12892, 12896, 13384, 13388, 13392, 13396, 13400, 13404, 13408, 13412, 13888, 13892, 13900, 13904, 13908, 13912, 13916, 13920, 13924, 14396, 14400, 14412, 14416, 14420, 14424, 14428, 14432, 14436, 14892, 14896, 14900, 14904, 14908, 14928, 14932, 14936, 14940, 14944, 14948, 15404, 15408, 15412, 15436, 15440, 15444)
    draw16($t4, 15448, 15452, 15456, 15460, 15944, 15948, 15952, 15956, 15960, 15964, 15968, 16444, 16448, 16452, 16456, 16460)
    sw $t4 16464($v1)
    li $t4 0xbd6455
    draw4($t4, 6192, 6704, 7220, 7740)
    draw4($t4, 7744, 7748, 11340, 11348)
    sw $t4 11856($v1)
    li $t4 0xfde3b2
    draw4($t4, 6196, 6200, 6708, 6712)
    draw4($t4, 6716, 6724, 7228, 7232)
    sw $t4 7236($v1)
    sw $t4 11344($v1)
    li $t4 0xededff
    draw16($t4, 6204, 6764, 6768, 6772, 7272, 7276, 7280, 7284, 7780, 7784, 7788, 7792, 7796, 8760, 8764, 8820)
    draw16($t4, 8824, 9268, 9272, 9288, 9320, 9324, 9328, 9332, 9336, 9780, 9832, 9836, 9840, 9844, 9848, 10352)
    draw4($t4, 10356, 10360, 11840, 11844)
    draw4($t4, 12860, 13368, 13876, 13880)
    li $t4 0x008bff
    draw16($t4, 6720, 13896, 14404, 14408, 14912, 14916, 14920, 14924, 15416, 15420, 15424, 15428, 15432, 15924, 15928, 15932)
    sw $t4 15936($v1)
    sw $t4 15940($v1)
    li $t4 0x674da7
    draw16($t4, 8244, 8252, 8308, 8752, 8808, 8812, 8816, 9776, 9812, 9816, 10328, 11336, 11832, 12340, 12344, 12348)
    draw16($t4, 12352, 12356, 12360, 12868, 13360, 13376, 13380, 13872, 13884, 14384, 14392, 16952, 16956, 16960, 16964, 16968)
    sw $t4 17464($v1)
    sw $t4 17476($v1)
    li $t4 0x0b0064
    draw16($t4, 8256, 10292, 10324, 10800, 10804, 10828, 10836, 11312, 11316, 11352, 11868, 12384, 12900, 13416, 13928, 14380)
    draw4($t4, 14440, 14952, 15464, 15920)
    draw4($t4, 15972, 16440, 16468, 16472)
    sw $t4 16476($v1)
    li $t4 0x4d0027
    draw4($t4, 9788, 9792, 10296, 10300)
    sw $t4 10308($v1)
    sw $t4 10812($v1)
    li $t4 0x880033
    sw $t4 10808($v1)
    sw $t4 11328($v1)
    li $t4 0x7a3332
    sw $t4 11860($v1)
    jr $ra
draw_post_doll_19: # start at v1, use t4
    draw64($0, 568, 572, 576, 580, 584, 588, 592, 596, 1072, 1076, 1112, 1116, 1580, 1632, 2088, 2148, 3108, 3176, 3616, 4716, 5228, 5740, 6260, 6264, 6772, 6776, 7284, 7288, 7792, 7796, 7800, 8300, 8304, 8308, 8312, 8820, 8824, 8828, 9332, 9336, 9340, 9840, 9844, 9848, 9852, 10348, 10352, 10356, 10360, 10364, 10864, 10868, 10872, 11348, 11860, 12896, 12908, 13408, 13412, 13420, 13920, 13924, 14432, 14436)
    draw4($0, 14440, 14948, 14952, 15460)
    draw4($0, 15464, 15972, 17476, 17480)
    sw $0 17992($v1)
    li $t4 0x91003b
    draw64($t4, 1080, 1088, 1092, 1108, 1584, 1624, 1628, 2092, 2108, 2132, 2144, 2600, 2616, 2636, 2652, 2660, 3112, 3124, 3152, 3620, 3652, 3664, 3688, 4128, 4132, 4152, 4164, 4176, 4188, 4200, 4636, 4640, 4644, 4664, 4676, 4688, 4700, 4712, 5148, 5152, 5172, 5184, 5188, 5196, 5200, 5208, 5212, 5224, 5660, 5680, 5684, 5704, 5712, 5724, 5736, 6176, 6184, 6188, 6236, 6244, 6248, 6692, 6696, 6700)
    draw64($t4, 6712, 6748, 6756, 6760, 7204, 7208, 7212, 7224, 7268, 7272, 7716, 7720, 7724, 7728, 7732, 7768, 7780, 7784, 8228, 8232, 8236, 8240, 8244, 8248, 8276, 8280, 8292, 8296, 8740, 8744, 8748, 8752, 8788, 8796, 8800, 8804, 8808, 9252, 9256, 9260, 9300, 9304, 9316, 9320, 9748, 9752, 9756, 9760, 9764, 9768, 9808, 9828, 9832, 10260, 10264, 10268, 10272, 10344, 10772, 10776, 10780, 11288, 11316, 11344)
    draw16($t4, 11800, 11820, 11824, 11856, 11864, 11868, 11872, 12324, 12328, 12332, 12376, 12380, 12384, 12388, 12392, 12832)
    draw4($t4, 12836, 12840, 12892, 12900)
    draw4($t4, 12904, 13344, 13348, 13404)
    sw $t4 13416($v1)
    sw $t4 13856($v1)
    sw $t4 13928($v1)
    li $t4 0xda7141
    draw16($t4, 1084, 1096, 1100, 1104, 1588, 1600, 1604, 1616, 1620, 2096, 2136, 2604, 2640, 3140, 3156, 3164)
    draw16($t4, 3172, 3624, 3640, 3668, 3676, 4180, 4660, 4672, 5168, 5180, 5676, 5732, 6180, 6200, 7260, 8288)
    sw $t4 8792($v1)
    li $t4 0xfaa753
    draw16($t4, 1592, 1596, 1608, 1612, 2100, 2104, 2140, 2608, 2644, 2648, 2656, 3116, 3136, 3148, 4136, 4148)
    draw4($t4, 4160, 4656, 4684, 4692)
    draw4($t4, 5164, 5220, 5668, 5672)
    sw $t4 5688($v1)
    sw $t4 7776($v1)
    li $t4 0xd1003f
    draw4($t4, 2112, 2116, 2120, 2124)
    draw4($t4, 2128, 2620, 2624, 2628)
    draw4($t4, 2632, 3128, 10820, 11332)
    sw $t4 11840($v1)
    sw $t4 11848($v1)
    sw $t4 11852($v1)
    li $t4 0xfaff53
    draw16($t4, 2612, 3120, 3132, 3144, 3160, 3168, 3628, 3632, 3636, 3644, 3648, 3656, 3660, 3672, 3680, 3684)
    draw16($t4, 4140, 4144, 4156, 4168, 4172, 4184, 4192, 4196, 4648, 4652, 4668, 4680, 4696, 4704, 4708, 5156)
    draw4($t4, 5160, 5176, 5192, 5204)
    draw4($t4, 5216, 5664, 5728, 6240)
    draw4($t4, 6752, 7264, 7772, 8284)
    li $t4 0xaa90e0
    draw64($t4, 5644, 5648, 5652, 5656, 6156, 6172, 6204, 6228, 6252, 6256, 6668, 6688, 6768, 7184, 7200, 7280, 7692, 7696, 7700, 7704, 7708, 7712, 7788, 8204, 8224, 8716, 8736, 8760, 8812, 8816, 9232, 9236, 9248, 9276, 9280, 9308, 9324, 9328, 9820, 9824, 9836, 10304, 10316, 10328, 10788, 10812, 11832, 12348, 12364, 12368, 13372, 13380, 13392, 13876, 13880, 13904, 14388, 14412, 14416, 14920, 14924, 15424, 15428, 17972)
    li $t4 0x2b1408
    draw16($t4, 5692, 5696, 5700, 5716, 5720, 17968, 17980, 17988, 18480, 18484, 18488, 18492, 18496, 18500, 18996, 19000)
    sw $t4 19008($v1)
    sw $t4 19012($v1)
    li $t4 0xffaa73
    draw4($t4, 5708, 6216, 6220, 6224)
    draw4($t4, 6736, 7220, 7740, 7764)
    li $t4 0xededff
    draw16($t4, 6160, 6164, 6168, 6672, 6676, 6680, 6684, 6716, 6740, 6764, 7188, 7192, 7196, 7252, 7276, 8208)
    draw16($t4, 8212, 8216, 8220, 8720, 8724, 8728, 8732, 9240, 9244, 9268, 9272, 9292, 9296, 9784, 9788, 9792)
    draw16($t4, 9804, 9812, 9816, 10300, 10320, 10324, 11300, 12352, 12356, 12360, 13384, 13388, 13884, 13888, 13892, 13896)
    draw4($t4, 13900, 14392, 14396, 14400)
    draw4($t4, 14404, 14408, 14908, 14912)
    sw $t4 14916($v1)
    li $t4 0xbd6455
    draw16($t4, 6192, 6196, 6704, 7216, 7736, 8252, 8256, 8260, 8264, 8268, 8272, 11292, 11804, 11812, 11880, 11884)
    sw $t4 12320($v1)
    li $t4 0x10309c
    draw64($t4, 6208, 6212, 6232, 6720, 6744, 7256, 9776, 10280, 10288, 10292, 10336, 10800, 10844, 10848, 10852, 10856, 10860, 11296, 11304, 11308, 11360, 11364, 11368, 11876, 12340, 12848, 12852, 12856, 13356, 13360, 13364, 13396, 13400, 13864, 13868, 13872, 13908, 13912, 14376, 14380, 14384, 14420, 14424, 14428, 14888, 14892, 14896, 14900, 14940, 15400, 15404, 15408, 15412, 15416, 15452, 15456, 15912, 15916, 15920, 15924, 15932, 15964, 15968, 16428)
    draw4($t4, 16432, 16436, 16956, 16960)
    draw4($t4, 16964, 16968, 16972, 16976)
    li $t4 0xfde3b2
    draw4($t4, 6708, 6728, 6732, 7228)
    draw4($t4, 7236, 7240, 7244, 7248)
    draw4($t4, 7744, 7748, 7752, 7756)
    sw $t4 7760($v1)
    sw $t4 11808($v1)
    li $t4 0x008bff
    draw16($t4, 6724, 7232, 10284, 10792, 10796, 14928, 14932, 14936, 15432, 15436, 15440, 15444, 15448, 15928, 15940, 15944)
    draw4($t4, 15948, 15952, 15956, 15960)
    draw4($t4, 16440, 16444, 16448, 16452)
    draw4($t4, 16456, 16460, 16464, 16468)
    sw $t4 16472($v1)
    li $t4 0x674da7
    draw16($t4, 8756, 8764, 8784, 9264, 9284, 9288, 9312, 9780, 10296, 10332, 10784, 10832, 11320, 11816, 12344, 12372)
    draw16($t4, 12860, 12864, 12868, 12872, 12876, 12880, 12884, 13368, 13376, 14904, 15420, 15936, 17456, 17460, 17464, 17468)
    sw $t4 17472($v1)
    sw $t4 17976($v1)
    sw $t4 17984($v1)
    li $t4 0x0b0064
    draw16($t4, 8768, 8772, 8776, 8780, 9772, 10276, 10340, 10804, 10808, 10836, 10840, 11312, 11352, 11356, 11828, 12336)
    draw16($t4, 12844, 12888, 13352, 13860, 13916, 14372, 14884, 14944, 15396, 15908, 16424, 16476, 16944, 16948, 16952, 16980)
    li $t4 0x4d0027
    draw4($t4, 9796, 9800, 10308, 10312)
    draw4($t4, 10816, 10824, 10828, 11324)
    sw $t4 11336($v1)
    sw $t4 11836($v1)
    li $t4 0x880033
    sw $t4 11328($v1)
    sw $t4 11340($v1)
    sw $t4 11844($v1)
    li $t4 0x7a3332
    draw4($t4, 11372, 11376, 11888, 12316)
    sw $t4 12396($v1)
    sw $t4 12400($v1)
    jr $ra
draw_post_doll_20: # start at v1, use t4
    draw64($0, 1080, 1084, 1088, 1092, 1096, 1100, 1104, 1108, 1584, 1588, 1592, 1596, 1600, 1604, 1608, 1612, 1616, 1620, 1624, 1628, 2092, 2096, 2100, 2104, 2108, 2112, 2116, 2120, 2124, 2128, 2132, 2136, 2140, 2144, 2600, 2604, 2608, 2612, 2616, 2620, 2624, 2628, 2632, 2636, 2640, 2644, 2648, 2652, 2656, 2660, 3112, 3116, 3120, 3156, 3160, 3164, 3168, 3172, 3620, 3624, 3676, 3680, 3684, 3688)
    draw16($0, 4128, 4132, 4192, 4196, 4200, 4636, 4640, 4708, 4712, 5148, 5152, 5224, 5644, 5648, 5652, 5656)
    draw16($0, 5660, 5736, 6156, 6160, 6164, 6168, 6172, 6252, 6256, 6680, 6684, 6764, 6768, 7276, 7280, 8812)
    draw16($0, 8816, 9324, 9328, 10860, 11372, 11376, 11880, 11884, 11888, 12380, 12384, 12392, 12396, 12400, 12884, 12888)
    draw4($0, 12900, 12904, 13416, 13928)
    sw $0 15452($v1)
    sw $0 15964($v1)
    li $t4 0x91003b
    draw64($t4, 3124, 3132, 3136, 3152, 3628, 3668, 3672, 4136, 4152, 4176, 4188, 4644, 4660, 4680, 4696, 4704, 5156, 5168, 5196, 5220, 5664, 5696, 5708, 6176, 6196, 6208, 6220, 6224, 6248, 6688, 6708, 6720, 6732, 6736, 6760, 7196, 7200, 7216, 7240, 7244, 7252, 7260, 7272, 7708, 7712, 7728, 7732, 7752, 7768, 7772, 7784, 8224, 8236, 8280, 8284, 8288, 8296, 8736, 8748, 8760, 8796, 8800, 8808, 9252)
    draw64($t4, 9260, 9272, 9308, 9312, 9320, 9760, 9764, 9772, 9776, 9816, 9820, 9824, 9832, 10276, 10280, 10284, 10288, 10292, 10320, 10324, 10328, 10336, 10344, 10784, 10788, 10792, 10796, 10840, 10848, 10852, 10856, 11296, 11300, 11304, 11356, 11360, 11368, 11808, 11812, 11868, 11872, 11876, 12304, 12308, 12312, 12316, 12320, 12388, 12816, 12820, 12824, 12828, 12832, 12880, 13328, 13336, 13340, 13360, 13392, 13836, 13848, 13864, 13868, 13904)
    draw4($t4, 14368, 14372, 14376, 14420)
    draw4($t4, 14876, 14880, 14884, 14936)
    draw4($t4, 15388, 15392, 15448, 15456)
    sw $t4 15900($v1)
    sw $t4 15968($v1)
    li $t4 0xda7141
    draw16($t4, 3128, 3140, 3144, 3148, 3632, 3644, 3648, 3660, 3664, 4140, 4180, 4648, 4684, 5184, 5192, 5200)
    draw16($t4, 5208, 5216, 5668, 5684, 5712, 5732, 6236, 6704, 6728, 6748, 7228, 7236, 7264, 7724, 7776, 8248)
    draw4($t4, 9256, 9316, 9768, 9828)
    sw $t4 10332($v1)
    sw $t4 10340($v1)
    li $t4 0xfaa753
    draw16($t4, 3636, 3640, 3652, 3656, 4144, 4148, 4184, 4652, 4688, 4692, 4700, 5160, 5180, 5188, 5672, 5704)
    draw16($t4, 5724, 6180, 6192, 6216, 6692, 6700, 6716, 6752, 7204, 7212, 7224, 7720, 7736, 8232, 8744, 8804)
    sw $t4 10844($v1)
    li $t4 0xd1003f
    draw4($t4, 4156, 4160, 4164, 4168)
    draw4($t4, 4172, 4664, 4668, 4672)
    draw4($t4, 4676, 5172, 12868, 13380)
    sw $t4 13892($v1)
    sw $t4 13900($v1)
    li $t4 0xfaff53
    draw16($t4, 4656, 5164, 5176, 5204, 5212, 5676, 5680, 5688, 5692, 5700, 5716, 5720, 5728, 6184, 6188, 6200)
    draw16($t4, 6204, 6212, 6228, 6232, 6240, 6244, 6696, 6712, 6724, 6740, 6744, 6756, 7208, 7220, 7232, 7256)
    draw4($t4, 7268, 7716, 7780, 8228)
    sw $t4 8292($v1)
    sw $t4 8740($v1)
    sw $t4 9248($v1)
    li $t4 0xaa90e0
    draw64($t4, 6660, 6664, 6668, 6672, 6676, 7172, 7188, 7192, 7684, 7788, 8200, 8252, 8300, 8708, 8712, 8716, 8720, 8724, 8728, 8732, 9220, 9240, 9244, 9732, 9756, 9836, 10248, 10252, 10256, 10268, 10272, 10348, 10772, 10776, 10780, 10804, 10828, 10832, 11292, 11324, 11364, 11800, 11804, 11832, 11848, 11864, 12344, 12352, 12364, 12856, 12860, 13876, 14392, 14396, 14412, 15416, 15420, 15436, 15928, 15936, 15948, 15952, 16436, 16444)
    draw4($t4, 16460, 16948, 16968, 16972)
    draw4($t4, 17476, 17480, 17984, 17988)
    sw $t4 20012($v1)
    li $t4 0xededff
    draw16($t4, 7176, 7180, 7184, 7688, 7692, 7696, 7700, 7704, 8204, 8208, 8212, 8216, 8220, 8764, 9224, 9228)
    draw16($t4, 9232, 9236, 9736, 9740, 9744, 9748, 9752, 10260, 10264, 11288, 11312, 11316, 11320, 11336, 11340, 11344)
    draw16($t4, 11348, 11828, 11836, 11840, 11852, 11856, 11860, 12348, 12368, 13344, 14400, 14404, 14408, 15428, 15432, 15932)
    draw4($t4, 15940, 15944, 16440, 16448)
    draw4($t4, 16452, 16456, 16952, 16956)
    draw4($t4, 16960, 16964, 17464, 17468)
    sw $t4 17472($v1)
    li $t4 0xffaa73
    draw4($t4, 7248, 7756, 7760, 8264)
    draw4($t4, 8268, 8272, 8784, 9268)
    sw $t4 9784($v1)
    sw $t4 9808($v1)
    li $t4 0x2b1408
    draw16($t4, 7740, 7744, 7748, 7764, 20008, 20024, 20520, 20524, 20528, 20536, 20540, 20544, 21036, 21040, 21052, 21056)
    li $t4 0xbd6455
    draw16($t4, 8240, 8244, 8752, 8792, 9264, 9304, 9780, 9812, 10300, 10304, 10308, 10312, 10316, 13856, 13916, 14364)
    sw $t4 14424($v1)
    li $t4 0x10309c
    draw16($t4, 8256, 8260, 8276, 8768, 8788, 9300, 11820, 12324, 12332, 12336, 12844, 12892, 13348, 13352, 13400, 13404)
    draw16($t4, 13408, 14384, 14892, 14896, 14900, 15400, 15404, 15408, 15444, 15908, 15912, 15916, 15920, 15956, 16420, 16424)
    draw16($t4, 16428, 16432, 16468, 16472, 16932, 16936, 16940, 16944, 16984, 17444, 17448, 17452, 17456, 17496, 17956, 17960)
    draw4($t4, 17964, 17968, 17972, 18008)
    draw4($t4, 18472, 18476, 18480, 19000)
    draw4($t4, 19004, 19008, 19012, 19016)
    sw $t4 19020($v1)
    li $t4 0xfde3b2
    draw4($t4, 8756, 8776, 8780, 9276)
    draw4($t4, 9284, 9288, 9292, 9296)
    draw4($t4, 9788, 9792, 9796, 9800)
    sw $t4 9804($v1)
    sw $t4 13852($v1)
    sw $t4 14428($v1)
    li $t4 0x008bff
    draw16($t4, 8772, 9280, 12328, 12836, 12840, 16980, 17488, 17492, 17996, 18000, 18004, 18484, 18488, 18492, 18496, 18500)
    draw4($t4, 18504, 18508, 18512, 18516)
    li $t4 0x0b0064
    draw16($t4, 10296, 10812, 10816, 10820, 11816, 12376, 12848, 12852, 12896, 13356, 13368, 13396, 13872, 13908, 14380, 14888)
    draw16($t4, 14932, 15396, 15904, 15960, 16416, 16476, 16928, 16988, 17440, 17500, 17952, 18468, 18520, 18988, 18992, 18996)
    sw $t4 19024($v1)
    sw $t4 19028($v1)
    li $t4 0x674da7
    draw16($t4, 10800, 10808, 10824, 10836, 11308, 11328, 11332, 11352, 11824, 12340, 12372, 13364, 13860, 13880, 14388, 14416)
    draw16($t4, 14904, 14908, 14912, 14916, 14920, 14924, 14928, 15412, 15424, 15440, 15924, 16464, 16976, 17460, 17484, 17976)
    draw4($t4, 17980, 17992, 19500, 19504)
    draw4($t4, 19512, 19516, 20016, 20028)
    li $t4 0x4d0027
    draw4($t4, 11844, 12356, 12360, 12864)
    draw4($t4, 12872, 12876, 13372, 13384)
    sw $t4 13884($v1)
    sw $t4 13896($v1)
    li $t4 0x880033
    sw $t4 13376($v1)
    sw $t4 13388($v1)
    sw $t4 13888($v1)
    li $t4 0x7a3332
    draw4($t4, 13912, 13920, 14360, 14432)
    sw $t4 14940($v1)
    sw $t4 14944($v1)
    jr $ra
draw_post_doll_21: # start at v1, use t4
    draw64($0, 3124, 3128, 3132, 3136, 3140, 3144, 3148, 3152, 3628, 3632, 3636, 3640, 3644, 3648, 3652, 3656, 3660, 3664, 3668, 3672, 4136, 4140, 4144, 4148, 4152, 4156, 4160, 4164, 4168, 4172, 4176, 4180, 4184, 4188, 4644, 4648, 4652, 4656, 4660, 4664, 4668, 4672, 4676, 4680, 4684, 4688, 4692, 4696, 4700, 4704, 5156, 5160, 5164, 5168, 5172, 5176, 5180, 5184, 5188, 5192, 5196, 5200, 5204, 5208)
    draw64($0, 5212, 5216, 5220, 5664, 5668, 5672, 5676, 5680, 5716, 5720, 5724, 5728, 5732, 6176, 6180, 6184, 6236, 6240, 6244, 6248, 6660, 6664, 6668, 6672, 6676, 6688, 6692, 6752, 6756, 6760, 7172, 7176, 7180, 7184, 7188, 7192, 7196, 7200, 7268, 7272, 7684, 7688, 7692, 7696, 7700, 7704, 7708, 7712, 7780, 7784, 7788, 8200, 8204, 8208, 8212, 8216, 8220, 8296, 8300, 8716, 8720, 8724, 8728, 8732)
    draw16($0, 8808, 9236, 9240, 9244, 9320, 9756, 9832, 9836, 12388, 13836, 15444, 15448, 15456, 15956, 15960, 15968)
    sw $0 16476($v1)
    li $t4 0x91003b
    draw64($t4, 5684, 5692, 5696, 5712, 6188, 6228, 6232, 6696, 6712, 6736, 6748, 7204, 7220, 7240, 7256, 7264, 7716, 7728, 7756, 8224, 8256, 8268, 8292, 8736, 8756, 8768, 8780, 8784, 8792, 8804, 9248, 9268, 9280, 9292, 9296, 9304, 9316, 9760, 9776, 9780, 9788, 9792, 9796, 9804, 9812, 9816, 9820, 9828, 10272, 10288, 10292, 10312, 10328, 10332, 10340, 10784, 10788, 10796, 10840, 10844, 10848, 10852, 11296, 11300)
    draw64($t4, 11308, 11320, 11356, 11360, 11364, 11808, 11812, 11820, 11832, 11868, 11872, 12320, 12324, 12332, 12336, 12376, 12380, 12384, 12832, 12836, 12840, 12844, 12848, 12852, 12880, 12884, 12888, 13344, 13348, 13352, 13356, 13844, 13852, 13856, 13860, 13864, 14356, 14360, 14364, 14368, 14372, 14436, 14868, 14872, 14876, 14948, 15380, 15440, 15920, 15952, 16424, 16428, 16464, 16468, 16472, 16928, 16932, 16936, 16980, 16984, 16988, 16992, 17436, 17440)
    draw4($t4, 17444, 17496, 17500, 17504)
    draw4($t4, 17948, 17952, 18008, 18016)
    sw $t4 18460($v1)
    sw $t4 18528($v1)
    li $t4 0xda7141
    draw16($t4, 5688, 5700, 5704, 5708, 6192, 6204, 6208, 6220, 6224, 6700, 6740, 7208, 7244, 7744, 7760, 7768)
    draw16($t4, 7776, 8228, 8244, 8272, 8280, 8796, 9264, 9276, 9284, 9308, 10276, 10284, 10336, 10808, 11816, 12328)
    li $t4 0xfaa753
    draw16($t4, 6196, 6200, 6212, 6216, 6704, 6708, 6744, 7212, 7248, 7252, 7260, 7720, 7740, 7752, 8232, 8284)
    draw4($t4, 8740, 8752, 8764, 8772)
    draw4($t4, 9252, 9260, 9764, 9772)
    draw4($t4, 9824, 10280, 10296, 10792)
    sw $t4 11304($v1)
    li $t4 0xd1003f
    draw4($t4, 6716, 6720, 6724, 6728)
    draw4($t4, 6732, 7224, 7228, 7232)
    draw4($t4, 7236, 7732, 15428, 15940)
    sw $t4 16452($v1)
    sw $t4 16460($v1)
    li $t4 0xfaff53
    draw16($t4, 7216, 7724, 7736, 7748, 7764, 7772, 8236, 8240, 8248, 8252, 8260, 8264, 8276, 8288, 8744, 8748)
    draw4($t4, 8760, 8776, 8788, 8800)
    draw4($t4, 9256, 9272, 9288, 9300)
    draw4($t4, 9312, 9768, 9784, 9800)
    li $t4 0xaa90e0
    draw64($t4, 8704, 8708, 8712, 9216, 9228, 9232, 9728, 9748, 9752, 10244, 10264, 10268, 10344, 10348, 10752, 10756, 10760, 10764, 10780, 10812, 10856, 10860, 11264, 11276, 11280, 11284, 11292, 11368, 11776, 11796, 11800, 11804, 11876, 12292, 12316, 12392, 12396, 12808, 12812, 12828, 12900, 12904, 12908, 13328, 13332, 13336, 13340, 13364, 13388, 13392, 13412, 13416, 13848, 13884, 13924, 14392, 14408, 14904, 14912, 14924, 15392, 15416, 15420, 16436)
    draw4($t4, 16952, 16956, 16972, 17976)
    draw4($t4, 17980, 17984, 17996, 18488)
    draw4($t4, 18496, 18508, 18512, 19008)
    sw $t4 19020($v1)
    sw $t4 19532($v1)
    sw $t4 20540($v1)
    li $t4 0xededff
    draw64($t4, 9220, 9224, 9732, 9736, 9740, 9744, 10248, 10252, 10256, 10260, 10768, 10772, 10776, 11268, 11272, 11288, 11324, 11780, 11784, 11788, 11792, 12296, 12300, 12304, 12308, 12312, 12816, 12820, 12824, 13872, 13876, 13880, 13896, 13900, 13904, 14388, 14396, 14400, 14412, 14416, 14420, 14908, 14928, 15904, 16960, 16964, 16968, 17988, 17992, 18492, 18500, 18504, 19000, 19004, 19012, 19016, 19512, 19516, 19520, 19524, 19528, 20024, 20028, 20032)
    draw4($t4, 20036, 20040, 20544, 20548)
    li $t4 0xffaa73
    draw4($t4, 9808, 10316, 10320, 10824)
    draw4($t4, 10828, 10832, 11344, 11828)
    sw $t4 12344($v1)
    sw $t4 12368($v1)
    li $t4 0x2b1408
    draw4($t4, 10300, 10304, 10308, 10324)
    li $t4 0xbd6455
    draw16($t4, 10800, 10804, 11312, 11352, 11824, 11864, 12340, 12372, 12860, 12864, 12868, 12872, 12876, 13916, 14424, 15896)
    sw $t4 16408($v1)
    sw $t4 16416($v1)
    sw $t4 16924($v1)
    li $t4 0x10309c
    draw16($t4, 10816, 10820, 10836, 11328, 11348, 11860, 12892, 13400, 13404, 13408, 14380, 14884, 14892, 14896, 15404, 15900)
    draw16($t4, 15908, 15912, 16944, 17452, 17456, 17460, 17960, 17964, 17968, 18004, 18468, 18472, 18476, 18480, 18516, 18980)
    draw16($t4, 18984, 18988, 18992, 19028, 19032, 19492, 19496, 19500, 19504, 19544, 20004, 20008, 20012, 20016, 20056, 20516)
    draw4($t4, 20520, 20524, 20528, 20532)
    draw4($t4, 20568, 21032, 21036, 21040)
    draw4($t4, 21560, 21564, 21568, 21572)
    sw $t4 21576($v1)
    sw $t4 21580($v1)
    li $t4 0xfde3b2
    draw4($t4, 11316, 11336, 11340, 11836)
    draw4($t4, 11844, 11848, 11852, 11856)
    draw4($t4, 12348, 12352, 12356, 12360)
    sw $t4 12364($v1)
    sw $t4 14428($v1)
    sw $t4 16412($v1)
    li $t4 0x008bff
    draw16($t4, 11332, 11840, 14888, 15396, 15400, 19540, 20048, 20052, 20556, 20560, 20564, 21044, 21048, 21052, 21056, 21060)
    draw4($t4, 21064, 21068, 21072, 21076)
    li $t4 0x0b0064
    draw16($t4, 12856, 12896, 13372, 13376, 13380, 13396, 13908, 14376, 14880, 14936, 15408, 15412, 15916, 15928, 16432, 16940)
    draw16($t4, 17448, 17492, 17956, 18464, 18520, 18976, 19488, 20000, 20060, 20512, 20572, 21028, 21080, 21548, 21552, 21556)
    sw $t4 21584($v1)
    sw $t4 21588($v1)
    li $t4 0x674da7
    draw16($t4, 13360, 13368, 13384, 13868, 13888, 13892, 14384, 14900, 14932, 15388, 15924, 16420, 16440, 16948, 16976, 17464)
    draw16($t4, 17468, 17472, 17476, 17480, 17484, 17488, 17972, 18000, 18484, 18996, 19024, 19508, 19536, 20020, 20044, 20536)
    sw $t4 20552($v1)
    li $t4 0x7a3332
    draw4($t4, 13912, 13920, 14432, 14940)
    sw $t4 14944($v1)
    sw $t4 16920($v1)
    li $t4 0x4d0027
    draw4($t4, 14404, 14916, 14920, 15424)
    draw4($t4, 15432, 15436, 15932, 15944)
    sw $t4 16444($v1)
    sw $t4 16456($v1)
    li $t4 0x880033
    sw $t4 15936($v1)
    sw $t4 15948($v1)
    sw $t4 16448($v1)
    jr $ra

draw_quit: # start at v1, use t4
    draw16($t6, 60, 576, 592, 1588, 2100, 2128, 2560, 2612, 2640, 3072, 3124, 3152, 3620, 3636, 3664, 4148)
    sw $t6 4180($v1)
    draw4($t8, 64, 1540, 1552, 1620)
    sw $t8 4128($v1)
    sw $t8 4140($v1)
    sw $t8 4172($v1)
    draw4($0, 68, 580, 1028, 1052)
    draw4($0, 1068, 1092, 2060, 2116)
    draw4($0, 2132, 2572, 3084, 3596)
    sw $0 4124($v1)
    sw $0 4168($v1)
    sw $0 4676($v1)
    draw4($t5, 572, 1572, 2084, 2596)
    draw4($t5, 3108, 4616, 4620, 4644)
    sw $t5 4648($v1)
    sw $t5 4688($v1)
    draw16($t0, 584, 1040, 1048, 1060, 1076, 1536, 1564, 1580, 1604, 2076, 2092, 2120, 2568, 2588, 2604, 2632)
    draw4($t0, 3080, 3100, 3116, 3144)
    draw4($t0, 3612, 3628, 3656, 4096)
    sw $t0 4640($v1)
    draw16($t9, 588, 1100, 1544, 1548, 1556, 1568, 1584, 1600, 1608, 1612, 1616, 2052, 2068, 2080, 2096, 2112)
    draw16($t9, 2124, 2564, 2580, 2592, 2608, 2624, 2636, 3076, 3092, 3104, 3120, 3136, 3148, 3588, 3604, 3616)
    draw4($t9, 3632, 3648, 3660, 4100)
    draw4($t9, 4104, 4112, 4116, 4132)
    draw4($t9, 4144, 4160, 4176, 4628)
    sw $t9 5140($v1)
    sw $t9 5652($v1)
    draw4($t2, 1032, 1036, 1096, 2576)
    draw4($t2, 3088, 3592, 5136, 5648)
    draw4($t1, 1044, 1056, 1072, 1084)
    draw4($t1, 1088, 1108, 4612, 4652)
    sw $t1 4684($v1)
    draw4($t7, 1104, 1596, 2108, 2620)
    draw4($t7, 3132, 3644, 4108, 4136)
    sw $t7 4156($v1)
    draw4($t3, 1560, 2072, 2584, 3096)
    draw4($t3, 3600, 3608, 4120, 4632)
    draw4($t3, 4660, 4668, 5144, 5656)
    draw4($t4, 2048, 2056, 2064, 3584)
    draw4($t4, 4624, 4656, 4672, 4692)
    jr $ra
draw_re: # start at v1, use t4
    draw4($t0, 0, 8, 16, 36)
    draw4($t0, 532, 1040, 1056, 2588)
    sw $t0 2596($v1)
    sw $t0 2600($v1)
    sw $t0 3592($v1)
    draw4($t1, 4, 1052, 3584, 3608)
    draw4($t2, 12, 28, 32, 552)
    draw4($t2, 1036, 1544, 2056, 2568)
    sw $t2 3080($v1)
    sw $t2 3092($v1)
    draw4($0, 20, 24, 1552, 2064)
    sw $0 2576($v1)
    draw4($t3, 512, 528, 1024, 1536)
    sw $t3 2048($v1)
    sw $t3 2560($v1)
    sw $t3 3072($v1)
    draw16($t9, 516, 524, 540, 544, 548, 1028, 1048, 1540, 1576, 2052, 2068, 2564, 3076, 3096, 3100, 3108)
    draw4($t8, 520, 536, 1060, 1064)
    draw4($t8, 1556, 1560, 2072, 2580)
    sw $t8 2584($v1)
    sw $t7 1032($v1)
    sw $t7 1572($v1)
    sw $t7 3104($v1)
    draw4($t6, 1044, 2076, 2080, 2084)
    sw $t6 2088($v1)
    sw $t6 3112($v1)
    draw4($t4, 1564, 1568, 3588, 3620)
    sw $t5 3612($v1)
    sw $t5 3616($v1)
    jr $ra
draw_start: # start at v1, use t4
    draw4($t6, 28, 1584, 2048, 2056)
    draw4($t6, 2112, 2604, 2624, 3136)
    sw $t6 3636($v1)
    sw $t6 3648($v1)
    draw16($t9, 32, 96, 544, 608, 1028, 1036, 1052, 1056, 1060, 1072, 1076, 1080, 1084, 1100, 1108, 1116)
    draw16($t9, 1120, 1124, 1568, 1596, 1612, 1632, 2052, 2080, 2108, 2124, 2144, 2572, 2576, 2592, 2608, 2620)
    draw4($t9, 2636, 2656, 3088, 3104)
    draw4($t9, 3116, 3132, 3148, 3168)
    draw4($t9, 3588, 3600, 3616, 3632)
    sw $t9 3644($v1)
    sw $t9 3660($v1)
    sw $t9 3680($v1)
    draw16($0, 36, 528, 552, 1544, 1560, 1576, 1588, 1624, 1640, 2088, 2092, 2128, 2560, 2600, 3080, 3108)
    draw4($0, 3112, 3124, 4096, 4164)
    sw $0 4188($v1)
    draw4($t3, 92, 1024, 1112, 1556)
    draw4($t3, 1628, 1636, 2060, 2140)
    draw4($t3, 2652, 3164, 3688, 4100)
    sw $t3 4168($v1)
    sw $t3 4192($v1)
    draw16($t2, 100, 520, 524, 564, 568, 596, 1068, 1620, 2096, 2148, 2564, 2660, 3076, 3172, 3604, 4152)
    sw $t2 4200($v1)
    draw16($t0, 516, 560, 572, 592, 600, 616, 1044, 1064, 1572, 1592, 2064, 3128, 3624, 4124, 4136, 4140)
    draw4($t1, 536, 548, 584, 588)
    draw4($t1, 1088, 1548, 2580, 3084)
    sw $t1 3676($v1)
    sw $t1 4112($v1)
    draw16($t7, 540, 1048, 1096, 1540, 1552, 1564, 1608, 2076, 2120, 2568, 2588, 2632, 3100, 3120, 3144, 3584)
    draw4($t7, 3596, 3620, 3628, 3656)
    draw4($t4, 604, 612, 1128, 1616)
    draw4($t4, 2100, 2612, 2616, 4144)
    sw $t4 4156($v1)
    sw $t4 4160($v1)
    sw $t4 4172($v1)
    draw4($t8, 1032, 1040, 1104, 1536)
    sw $t8 3640($v1)
    sw $t8 3684($v1)
    draw4($t5, 1580, 1600, 2104, 3072)
    draw4($t5, 3092, 3592, 3612, 4104)
    draw4($t5, 4108, 4128, 4132, 4148)
    sw $t5 4196($v1)
    jr $ra
draw_to: # start at v1, use t4
    draw4($t7, 4, 516, 1024, 1540)
    draw4($t7, 2052, 2564, 3076, 3096)
    sw $t7 3596($v1)
    draw16($t9, 8, 520, 1028, 1032, 1036, 1048, 1052, 1056, 1060, 1544, 1572, 2056, 2068, 2088, 2568, 2580)
    draw4($t9, 2600, 3080, 3092, 3112)
    sw $t9 3592($v1)
    sw $t9 3608($v1)
    sw $t9 3620($v1)
    draw4($0, 12, 528, 1536, 1548)
    draw4($0, 1552, 1580, 2060, 2572)
    draw4($0, 3084, 3100, 3104, 3116)
    sw $0 4116($v1)
    sw $0 4136($v1)
    draw4($t1, 512, 524, 1044, 1064)
    sw $t1 1568($v1)
    sw $t1 2064($v1)
    sw $t1 2576($v1)
    draw4($t0, 536, 548, 1040, 1564)
    draw4($t0, 2092, 2604, 3088, 3600)
    sw $t0 4100($v1)
    sw $t0 4112($v1)
    draw4($t2, 540, 544, 4120, 4132)
    draw4($t8, 1556, 1560, 1576, 3108)
    sw $t8 3612($v1)
    sw $t8 3616($v1)
    sw $t4 2072($v1)
    sw $t4 2584($v1)
    sw $t4 3604($v1)
    draw4($t5, 2084, 2596, 3588, 4104)
    sw $t5 4108($v1)
    sw $t5 4124($v1)
    sw $t5 4128($v1)
    sw $t3 3624($v1)
    jr $ra
draw_turn: # start at v1, use t4
    draw4($0, 0, 560, 588, 1116)
    draw4($0, 1536, 1552, 1616, 4100)
    sw $0 4116($v1)
    draw16($t3, 4, 1024, 1044, 1060, 1068, 1540, 1556, 1572, 1580, 1596, 2052, 2068, 2084, 2092, 2132, 2564)
    draw4($t3, 2580, 2596, 2604, 2644)
    draw4($t3, 3076, 3092, 3108, 3116)
    draw4($t3, 3156, 3600, 3628, 3668)
    sw $t3 4104($v1)
    draw16($t9, 8, 520, 1028, 1032, 1036, 1048, 1064, 1076, 1084, 1096, 1104, 1108, 1544, 1560, 1576, 1588)
    draw16($t9, 1608, 1624, 2056, 2072, 2088, 2100, 2120, 2136, 2568, 2584, 2600, 2612, 2632, 2648, 3080, 3096)
    draw4($t9, 3112, 3124, 3144, 3160)
    draw4($t9, 3592, 3608, 3612, 3620)
    draw4($t9, 3624, 3636, 3656, 3672)
    draw16($t2, 12, 596, 1052, 1548, 1564, 1628, 2060, 2076, 2140, 2572, 2588, 2652, 3084, 3100, 3164, 3588)
    draw4($t2, 3676, 4112, 4120, 4152)
    draw16($t0, 512, 528, 532, 540, 548, 556, 568, 580, 600, 1072, 1584, 2048, 2096, 2560, 2608, 3120)
    sw $t0 3632($v1)
    sw $t0 4144($v1)
    sw $t0 4172($v1)
    draw4($t5, 516, 1088, 1620, 4108)
    sw $t5 4124($v1)
    draw16($t4, 524, 1040, 1092, 1604, 1612, 2104, 2116, 2616, 2628, 3128, 3140, 3640, 3652, 4128, 4136, 4148)
    sw $t4 4168($v1)
    sw $t4 4184($v1)
    draw16($t1, 536, 552, 564, 572, 576, 584, 592, 1600, 2124, 2636, 3148, 3604, 3660, 4132, 4140, 4164)
    sw $t1 4180($v1)
    sw $t1 4188($v1)
    draw4($t8, 1080, 1112, 1592, 3596)
    sw $t7 1100($v1)
    sw $t7 3616($v1)
    jr $ra

draw_keybase: # start at v1
    draw16($t2, 0, 4, 60, 64, 512, 516, 572, 576, 1024, 1028, 1084, 1088, 1536, 1540, 1596, 1600)
    draw16($t2, 2048, 2052, 2108, 2112, 2560, 2564, 2620, 2624, 3072, 3076, 3132, 3136, 3584, 3588, 3644, 3648)
    draw4($t2, 4096, 4100, 4156, 4160)
    draw4($t2, 4608, 4612, 4668, 4672)
    draw16($t4, 4104, 4108, 4112, 4116, 4120, 4124, 4128, 4132, 4136, 4140, 4144, 4148, 4152, 4616, 4620, 4624)
    draw16($t4, 4628, 4632, 4636, 4640, 4644, 4648, 4652, 4656, 4660, 4664, 5128, 5132, 5136, 5140, 5144, 5148)
    draw16($t4, 5152, 5156, 5160, 5164, 5168, 5172, 5176, 5640, 5644, 5648, 5652, 5656, 5660, 5664, 5668, 5672)
    draw4($t4, 5676, 5680, 5684, 5688)
    jr $ra
draw_keyp: # start at v1
    draw16($0, 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 512, 516, 520)
    draw16($0, 524, 528, 532, 536, 540, 544, 548, 552, 556, 560, 1024, 1028, 1032, 1036, 1040, 1044)
    draw4($0, 1048, 1052, 1056, 1060)
    sw $0 1064($v1)
    sw $0 1068($v1)
    sw $0 1072($v1)
    draw64($t9, 1536, 1540, 1544, 1548, 1552, 1556, 1560, 1564, 1568, 1572, 1576, 1580, 1584, 2048, 2096, 2560, 2608, 3072, 3092, 3096, 3100, 3120, 3584, 3600, 3616, 3632, 4096, 4112, 4128, 4132, 4144, 4608, 4624, 4640, 4656, 5120, 5136, 5140, 5144, 5148, 5168, 5632, 5648, 5680, 6144, 6160, 6192, 6656, 6704, 7168, 7216, 7680, 7728, 8192, 8196, 8200, 8204, 8208, 8212, 8216, 8220, 8224, 8228, 8232)
    sw $t9 8236($v1)
    sw $t9 8240($v1)
    draw64($t1, 2052, 2056, 2060, 2064, 2068, 2072, 2076, 2080, 2084, 2088, 2092, 2564, 2568, 2572, 2576, 2580, 2584, 2588, 2592, 2596, 2600, 2604, 3076, 3080, 3084, 3108, 3112, 3116, 3588, 3592, 3624, 3628, 4100, 4104, 4120, 4136, 4140, 4612, 4616, 4648, 4652, 5124, 5128, 5160, 5164, 5636, 5640, 5664, 5668, 5672, 5676, 6148, 6152, 6168, 6172, 6176, 6180, 6184, 6188, 6660, 6664, 6680, 6684, 6688)
    draw16($t1, 6692, 6696, 6700, 7172, 7176, 7180, 7184, 7188, 7192, 7196, 7200, 7204, 7208, 7212, 7684, 7688)
    draw4($t1, 7692, 7696, 7700, 7704)
    draw4($t1, 7708, 7712, 7716, 7720)
    sw $t1 7724($v1)
    sw $t7 3088($v1)
    draw4($t4, 3104, 3608, 4116, 5652)
    sw $t4 6164($v1)
    draw4($t3, 3596, 4108, 4620, 4632)
    draw4($t3, 5132, 5644, 6156, 6676)
    draw4($t6, 3604, 3620, 4628, 4644)
    sw $t6 6672($v1)
    sw $t5 3612($v1)
    sw $t5 4636($v1)
    sw $t5 5152($v1)
    draw4($t2, 4124, 5156, 5656, 5660)
    sw $t2 6668($v1)
    jr $ra
draw_keyq: # start at v1
    draw16($0, 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 512, 516, 520)
    draw16($0, 524, 528, 532, 536, 540, 544, 548, 552, 556, 560, 1024, 1028, 1032, 1036, 1040, 1044)
    draw4($0, 1048, 1052, 1056, 1060)
    sw $0 1064($v1)
    sw $0 1068($v1)
    sw $0 1072($v1)
    draw64($t9, 1536, 1540, 1544, 1548, 1552, 1556, 1560, 1564, 1568, 1572, 1576, 1580, 1584, 2048, 2096, 2560, 2608, 3072, 3092, 3096, 3100, 3120, 3584, 3600, 3616, 3632, 4096, 4112, 4128, 4144, 4608, 4624, 4640, 4656, 5120, 5136, 5152, 5168, 5632, 5648, 5664, 5680, 6144, 6164, 6168, 6172, 6192, 6656, 6684, 6688, 6704, 7168, 7216, 7680, 7728, 8192, 8196, 8200, 8204, 8208, 8212, 8216, 8220, 8224)
    draw4($t9, 8228, 8232, 8236, 8240)
    draw64($t1, 2052, 2056, 2060, 2064, 2068, 2072, 2076, 2080, 2084, 2088, 2092, 2564, 2568, 2572, 2576, 2580, 2588, 2592, 2596, 2600, 2604, 3076, 3080, 3084, 3108, 3112, 3116, 3588, 3592, 3608, 3620, 3624, 3628, 4100, 4104, 4116, 4120, 4136, 4140, 4612, 4616, 4628, 4632, 4636, 4648, 4652, 5124, 5128, 5140, 5144, 5160, 5164, 5636, 5640, 5668, 5672, 5676, 6148, 6152, 6156, 6180, 6184, 6188, 6660)
    draw16($t1, 6664, 6668, 6672, 6676, 6696, 6700, 7172, 7176, 7180, 7184, 7188, 7192, 7196, 7200, 7204, 7208)
    draw4($t1, 7212, 7684, 7688, 7692)
    draw4($t1, 7696, 7700, 7704, 7708)
    draw4($t1, 7712, 7716, 7720, 7724)
    draw4($t2, 2584, 3596, 4124, 5148)
    draw4($t2, 5644, 5656, 6160, 6692)
    sw $t3 3088($v1)
    sw $t3 3104($v1)
    sw $t3 5132($v1)
    draw4($t8, 3604, 3612, 5652, 5660)
    sw $t4 4108($v1)
    sw $t4 6176($v1)
    sw $t4 6680($v1)
    sw $t5 4132($v1)
    sw $t5 5156($v1)
    sw $t6 4620($v1)
    sw $t6 4644($v1)
    jr $ra
draw_keys: # start at v1
    draw16($0, 0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 512, 516, 520)
    draw16($0, 524, 528, 532, 536, 540, 544, 548, 552, 556, 560, 1024, 1028, 1032, 1036, 1040, 1044)
    draw4($0, 1048, 1052, 1056, 1060)
    sw $0 1064($v1)
    sw $0 1068($v1)
    sw $0 1072($v1)
    draw64($t9, 1536, 1540, 1544, 1548, 1552, 1556, 1560, 1564, 1568, 1572, 1576, 1580, 1584, 2048, 2096, 2560, 2608, 3072, 3096, 3120, 3584, 3600, 3604, 3608, 3612, 3616, 3632, 4096, 4112, 4128, 4144, 4608, 4628, 4656, 5120, 5144, 5148, 5168, 5632, 5664, 5680, 6144, 6160, 6176, 6192, 6656, 6676, 6680, 6684, 6704, 7168, 7216, 7680, 7728, 8192, 8196, 8200, 8204, 8208, 8212, 8216, 8220, 8224, 8228)
    sw $t9 8232($v1)
    sw $t9 8236($v1)
    sw $t9 8240($v1)
    draw64($t1, 2052, 2056, 2060, 2064, 2068, 2072, 2076, 2080, 2084, 2088, 2092, 2564, 2568, 2572, 2576, 2580, 2584, 2588, 2592, 2596, 2600, 2604, 3076, 3080, 3084, 3108, 3112, 3116, 3588, 3592, 3624, 3628, 4100, 4104, 4120, 4136, 4140, 4612, 4616, 4640, 4644, 4648, 4652, 5124, 5128, 5132, 5136, 5160, 5164, 5636, 5640, 5652, 5656, 5672, 5676, 6148, 6152, 6184, 6188, 6660, 6664, 6668, 6692, 6696)
    draw16($t1, 6700, 7172, 7176, 7180, 7184, 7188, 7192, 7196, 7200, 7204, 7208, 7212, 7684, 7688, 7692, 7696)
    draw4($t1, 7700, 7704, 7708, 7712)
    sw $t1 7716($v1)
    sw $t1 7720($v1)
    sw $t1 7724($v1)
    draw4($t2, 3088, 3104, 3596, 4124)
    sw $t2 4620($v1)
    sw $t2 5156($v1)
    sw $t2 6168($v1)
    draw4($t5, 3092, 3100, 5140, 5668)
    sw $t5 6164($v1)
    sw $t5 6180($v1)
    draw4($t3, 3620, 4636, 5644, 5660)
    draw4($t4, 4108, 4116, 4132, 5648)
    sw $t4 6156($v1)
    sw $t4 6172($v1)
    sw $t4 6672($v1)
    sw $t8 4624($v1)
    sw $t8 4632($v1)
    sw $t8 5152($v1)
    sw $t6 6688($v1)
    jr $ra

jrra:
    jr $ra
