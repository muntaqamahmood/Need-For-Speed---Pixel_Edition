#####################################################################
#
# CSCB58 Winter 2022 Assembly Final Project
# University of Toronto, Scarborough
#
# Student Name:   Muntaqa Abdullah Mahmood
# Student Number: 1007196927
# UtorID:	  mahmo428
# official email: muntaqa.mahmood@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 16
# - Unit height in pixels: 16
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 3
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Score (Score Bar)
# 2. Fail Condition (Falling through the bottom of screen) 
# 3. Win COndition (*Landing* on a Diamond)
# 4. Moving Platforms (White Platforms)
# 5. Disappearing Platform	(Bait Green Platforms)
# 6. Jet Pack	(Blue Jet Packs charged to the main platforms and gives boost to car's wheels when touched)
# 7. PogoStick PickUp => Double Jump (if considered by the grader) (car jumps higher than usual when landed on the pick up)
#
#
# Link to video demonstration for final submission:
# - https://youtu.be/pFJ1THULp-k
#
# Are you OK with us sharing the video with people outside course staff?
# - no
#
# Any additional information that the TA needs to know:
# - Hope you like it! :)
#
#####################################################################

#define constants
#ASCII codes for p, w, a, s, d, e
.eqv	ASCII_p 0x70	#restart game anytime
.eqv	ASCII_w 0x77	#move up
.eqv	ASCII_a 0x61	#move left
.eqv	ASCII_s 0x73	#move down (delete_ if not needed)
.eqv	ASCII_d 0x64	#move right
.eqv	ASCII_e 0x65	#exit game

.data
init_Position:		.word 0x10008000
arrayRep: 		.word 0:1536
onSleep: 		.word 40
array_char_R: 		.word 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1
array_char_E:		.word 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1
array_char_S:		.word 1, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1
array_char_T: 		.word 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0
array_char_A: 		.word 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1
baseDisplay:		.word 0x10008000
	
#All the Colours for painting different things on screen
colour_JetPack: 	.word 0x1C2EFF	# JetPack colour
colour_Platform: 	.word 0x1F5403	# Main Platform colour
colour_Background: 	.word 0xFFB75E	# Background colour
colour_UnfixedPlatform: .word 0xB4D6D6	# UnfixedPlatform colour
colour_ScoreBar: 	.word 0x20354D	# Score Bar colour
colour_Car: 		.word 0x576199	# Car colour
colour_TempPlatform: 	.word 0x3DA606	# Temporary Platform colour
colour_PogoStick: 	.word 0x7E10B0	# PogoStick colour
colour_BaitPlatform: 	.word 0x5DFF08	# Bait Platform colour
colour_AirTimeBar: 	.word 0x1BC9FA	# AirTime Bar colour
colour_Wheels:		.word 0x000000	# Wheels colour
colour_GG:		.word 0x171717	# Game over colour
colour_Diamond:		.word 0x80E1F2	# Diamond pick-up colour

isFalse:		.word 0		# int for bool false
isTrue:			.word 1		# int for bool true

initpos_Character: 	.word 84	# Car initial position on screen
airTime_Character: 	.word 13	# car in the air duration
airTime_PogoStick: 	.word 25	# PogoStick pick-up in the air duration
airTime_JetPack: 	.word 70	# JetPack pick-up in the air duration
	
.text
main:
	li $s0, 0			# initialize loop variable in main
	lw $t0, isFalse			# game state (false=on=0, true=off=1)
	li $t1, 768			# next create coord / create timer
	lw $t2, isFalse			# in the air timer
	lw $t3, isFalse			# difficulty / platform spacing	
	lw $t4, isFalse 		# character velocity
	lw $t5, initpos_Character  	# intitial car position
	li $t6, -128			# moving platforms duration

BEGIN:
	beq $s0, 32, LOOP
	jal move_Screen
	jal create_Objects
	jal paint_World
	addi $s0, $s0, 1
	j BEGIN

LOOP:
	bge $t5, 1536, not_MoveScreen	# if t5 >= 1536 jump to still Screen
	jal move_Screen			#
	jal create_Objects		#
	addi $t5, $t5, 128		# move car

#still Screen
not_MoveScreen:
	jal update_movingPlatforms
	beq $t0, 1, stillScreen_Character
	jal update_movingCharacter

#Car steady as screen not moving up	
stillScreen_Character:
	jal paint_World
	jal paint_Character
	jal paint_JumpBar
	jal paint_Score_Bar
	ble $t5, 4096, gameOn	# character reaches bottom of screen
	jal paint_GameOverScreen
	jal paint_GameOverText
	beq $t0, 1, gameOn
	li $t0, 1		# set paint_GameOverScreen to true
			
gameOn:
	jal sleep
	j LOOP
		
gameOff:
	j exitGame

#game Over 
paint_GameOverScreen:
	lw $s0, 0xffff0000
	beq $s0, 1, paint_GameOverScreenInput
	jr $ra

#checking input after Game over screen
paint_GameOverScreenInput:
 	lw $s1, 0xffff0004
	beq $s1, ASCII_p, inputPend
	beq $s1, ASCII_e, inputE
	jr $ra

inputPend:
	j main
	
inputE:
	j exitGame

# "GAME OVER" => car fell thru the map	
paint_GameOverText:
	addi $sp, $sp, -12
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	
	#lw $s1, init_Position
	lw $s0, colour_GG	#get appropriate colour
	addi $s1, $gp, 1300	# placement on screen at 1300

	
	# paint GAME OVER on screen
	sw $s0, 0($s1)		#G
	sw $s0, 124($s1)
	sw $s0, 252($s1)
	sw $s0, 256($s1)
	sw $s0, 384($s1)
	sw $s0, 260($s1)
	
	
	sw $s0, 264($s1)	#A
	sw $s0, 392($s1)
	sw $s0, 136($s1)
	sw $s0, 268($s1)
	sw $s0, 12($s1)
	sw $s0, 144($s1)
	sw $s0, 272($s1)
	sw $s0, 400($s1)
	
	sw $s0, 20($s1)		#M 
	sw $s0, 148($s1)
	sw $s0, 276($s1)
	sw $s0, 404($s1)
	sw $s0, 152($s1)
	sw $s0, 156($s1)
	sw $s0, 28($s1)
	sw $s0, 284($s1)
	sw $s0, 412($s1)

	sw $s0, 416($s1)	#E 
	sw $s0, 288($s1)
	sw $s0, 160($s1)
	sw $s0, 32($s1)
	sw $s0, 36($s1)
	sw $s0, 292($s1)
	sw $s0, 420($s1)
	
	sw $s0, 432($s1)	#O 
	sw $s0, 304($s1)
	sw $s0, 176($s1)
	sw $s0, 48($s1)
	sw $s0, 52($s1)
	sw $s0, 436($s1)
	sw $s0, 440($s1)
	sw $s0, 312($s1)
	sw $s0, 184($s1)
	sw $s0, 56($s1)
	
	sw $s0, 60($s1)		#V
	sw $s0, 188($s1)
	sw $s0, 316($s1)
	sw $s0, 448($s1)
	sw $s0, 324($s1)
	sw $s0, 196($s1)
	sw $s0, 68($s1)
	
	
	sw $s0, 72($s1)		#E 
	sw $s0, 200($s1)
	#sw $s0, 328($s1)
	sw $s0, 456($s1)
	#sw $s0, 460($s1)
	sw $s0, 332($s1)
	sw $s0, 76($s1)
	
	
	sw $s0, 80($s1)		#R 
	sw $s0, 208($s1)
	sw $s0, 336($s1)
	sw $s0, 464($s1)
	sw $s0, 340($s1)
	sw $s0, 84($s1)
	sw $s0, 88($s1)
	sw $s0, 216($s1)
	sw $s0, 472($s1)
	
	
	lw $s2, 8($sp)		#load back to stack and send to caller
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 12
	jr $ra
	
#updating moving platforms while screen moving up/still screen
update_movingPlatforms:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	blt $t6, 128, keepMoving
	li $t6, -128
	
#constantly moving while not on the edges of screen
keepMoving:
	blt $t6, 0, move_Right_Platform
	jal move_Left_Platform
	j stopMoving
		
move_Right_Platform:
	jal move_toRight_Platform

stopMoving:
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
	
move_toRight_Platform:
	addi $sp, $sp, -12
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	addi $t6, $t6, 4
	li $s0, 4864

movingRight_Platform:
	beq $s0, 764, stop_MovingRight_Platform
	lw $s1, arrayRep($s0)
	bne $s1, 6, keep_MovingRight_Platform
	
	addi $s2, $s0, 4
	sw $zero, arrayRep($s0)
	sw $s1, arrayRep($s2)
		
keep_MovingRight_Platform:
	addi $s0, $s0, -4
	j movingRight_Platform
	
stop_MovingRight_Platform:
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 12
	jr $ra
		
move_Left_Platform:
	addi $sp, $sp, -12
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	addi $t6, $t6, 4
	li $s0, 768
	
moving_Left_Platform:
	beq $s0, 4864, stop_Moving_Left_Platform
	lw $s1, arrayRep($s0)
	bne $s1, 6, keep_Moving_Left_Platform
	
	addi $s2, $s0, -4
	sw $zero, arrayRep($s0)
	sw $s1, arrayRep($s2)
		
keep_Moving_Left_Platform:
	addi $s0, $s0, 4
	j moving_Left_Platform
	
stop_Moving_Left_Platform:
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 12
	jr $ra
		
paint_Score_Bar:
	addi $sp, $sp, -12
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	
	lw $s2, colour_ScoreBar
	div $s0, $t3, 28
		
calculate_Bar_IncreaseRatio:
	beq $s0, 0, endPaint_ScoreBar
		
	mul $s1, $s0, -128
	add $s1, $s1, $gp

	add $s2, $s2, -5	# gradient
	sw $s2, 3972($s1)
	beq $s1, 4, youWin
		
	addi $s0, $s0, -1
	j calculate_Bar_IncreaseRatio
	
endPaint_ScoreBar:
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 12
	jr $ra

#Win screen when landed on Diamond	
youWin:
	addi $sp, $sp, -12
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	
	#lw $s1, init_Position
	lw $s0, colour_GG	#load colour
	addi $s1, $gp, 1960
	
	# paint G for Good on screen
	sw $s0, 0($s1)		#locatons on screen/used guess and check
	sw $s0, 124($s1)
	sw $s0, 252($s1)
	sw $s0, 256($s1)
	sw $s0, 384($s1)
	sw $s0, 260($s1)
	
	# paint G for Game on screen
	sw $s0, 24($s1)
	sw $s0, 148($s1)
	sw $s0, 276($s1)
	sw $s0, 280($s1)
	sw $s0, 408($s1)
	sw $s0, 284($s1)
	
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 12
	jr $ra
	

paint_JumpBar:
	addi $sp, $sp, -12
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	
	lw $s2, colour_AirTimeBar
	
	div $s0, $t2, 3

paint_JumpBarLoop:
	beq $s0, 0, endPaint_JumpBar
	
	mul $s1, $s0, -128
	add $s1, $s1, $gp

	add $s2, $s2, 5	# gradient
	sw $s2, 4088($s1)
		
	addi $s0, $s0, -1
	j paint_JumpBarLoop
	
endPaint_JumpBar:
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 12
	jr $ra
		
create_Jet_Pack:
	addi $sp, $sp, -8
	sw $s0, ($sp)
	sw $s1, 4($sp)
	
	li $s1, 5	# checks Jet_Pack_Collision with 5 as parameter
	addi $s0, $t1, -128
	sw $s1, arrayRep($s0)
	addi $s0, $s0, -128
	sw $s1, arrayRep($s0)
	addi $s0, $s0, 132
	sw $s1, arrayRep($s0)
	addi $s0, $s0, 132
	sw $s1, arrayRep($s0)
	addi $s0, $s0, -128
	sw $s1, arrayRep($s0)
	addi $s0, $s0, -128
	sw $s1, arrayRep($s0)
	addi $s0, $s0, 132
	sw $s1, arrayRep($s0)
	
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 8
	jr $ra


# a0 platform type
create_Platform:
	addi $sp, $sp, -4
	sw $s0, ($sp)

	move $s0, $t1
	sw $a0, arrayRep($s0) # create platform
	addi $s0, $s0, 4
	sw $a0, arrayRep($s0)
	addi $s0, $s0, 4
	sw $a0, arrayRep($s0)
	addi $s0, $s0, 4
	sw $a0, arrayRep($s0)
	addi $s0, $s0, 4
	sw $a0, arrayRep($s0)

	lw $s0, ($sp)
	addi $sp, $sp, 4
	jr $ra

# $a0 random position on platform
create_PogoStick:
	addi $sp, $sp, -8
	sw $s0, ($sp)
	sw $s1, 4($sp)
	
	mul $s0, $a0, 4		# multiply random num by 4 
	add $s0, $s0, $t1	# get coords of platform
	addi $s0, $s0, -128	# create above platform
	
	li $s1, 2	# checks PogoStick_Collision with 2 as parameter
	sw $s1, arrayRep($s0)
	addi $s0, $s0, 4
	sw $s1, arrayRep($s0)
	addi $s0, $s0, 4
	sw $s1, arrayRep($s0)
	addi $s0, $s0, 4	
	
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 8
	jr $ra
	

create_Diamond:
	addi $sp, $sp, -8
	sw $s0, ($sp)
	sw $s1, 4($sp)
	
	mul $s0, $a0, 4		# multiply random num by 4 
	add $s0, $s0, $t1	# get coords of platform
	addi $s0, $s0, -128	# create above platform
	
	li $s1, 7	# checks Diamond Collision with 7 as parameter
	sw $s1, arrayRep($s0)
	addi $s0, $s0, 4
	sw $s1, arrayRep($s0)
	addi $s0, $s0, 4
	sw $s1, arrayRep($s0)
	addi $s0, $s0, 4	
	
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 8
	jr $ra


delete_Platform:
addi $sp, $sp, -16
sw $s0, ($sp)
sw $s1, 4($sp)
sw $s2, 8($sp)
sw $s3, 12($sp)
	
lw $s0, arrayRep($a0)	#check type of platform by loading into array
li $s1, -16	# go through all types of the 4 platforms
	

delete_Loop:
	beq $s1, 20, finishRemove
	# current co ordination
	add $s3, $a0, $s1
	
	lw $s4, arrayRep($s3)	# load into that index in array
	bne $s4, $s0, keep_RemoveLoop	# if not equal to that indexed variable, keep remove looping
	sw $zero, arrayRep($s3)
	
keep_RemoveLoop:
	addi $s1, $s1, 4
	j delete_Loop
	
finishRemove:
	lw $s3, 12($sp)
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 16
	jr $ra
		
create_Objects:
	addi $sp, $sp, -8
	sw $ra, ($sp)
	sw $s0, 4($sp)
	
	bge $t1, 768, endCreateObstacle
	
	
	li $v0, 42
	li $a0, 0
	li $a1, 30
	syscall
	
	blt $a0, 13, create_variation1
	li $a0, 1	# checks Main platform with 1 as parameter
	jal create_Platform
	j endCreate
	
create_variation1:
	blt $a0, 9, create_variation2
	li $a0, 1	
	jal create_Platform
		
	
	li $v0, 42	#randomly generate platforms
	li $a0, 0
	li $a1, 64
	syscall
		
	move $s0, $a0
	mul $s0, $s0, 4		
	addi $s0, $s0, 256	
	
	add $t1, $t1, $s0	#platforms position to create
	
	li $a0, 3	# for temporary Platform  with 3 as parameter
	jal create_Platform
	
	mul $s0, $s0, -1
	add $t1, $t1, $s0
	j endCreate

create_variation2:
	blt $a0, 6, create_variation3
	li $a0, 4	# checks moving platform with 4 as parameter
	jal create_Platform
	j endCreate

create_variation3:
	blt $a0, 5, create_variation4
	li $a0, 6	
	jal create_Platform
	jal create_Diamond
	j endCreate

create_variation4:
	blt $a0, 4, create_variation5
	li $a0, 1	
	jal create_Platform
	jal create_Jet_Pack
	j endCreate
	
create_variation5:
	li $a0, 1	
	jal create_Platform
	jal create_PogoStick
	j endCreate

endCreate:
	li $v0, 42
	li $a0, 0
	li $a1, 192
	syscall

	mul $a0, $a0, 4	
	add $a0, $a0, $t3
	addi $t1, $a0, 768	# buffer offset
	
	bgt $t3, 712, endCreateObstacle	
	addi $t3, $t3, 4	

endCreateObstacle:
	lw $s0, 4($sp)
	lw $ra, ($sp)
	addi $sp, $sp, 8
	jr $ra

move_Screen:
	addi $sp, $sp, -20
	sw $ra, ($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	
	addi $t1, $t1, -128 	# update moving timer
	
	li $s0, 4864
moving:
	blt $s0, $zero, endMovingWorld
	lw $s1, arrayRep($s0)
	addi $s2, $s0, 128	# moving amount
	sw $s1, arrayRep($s2)
	addi $s0, $s0, -4
	j moving
		
endMovingWorld:
	lw $s3, 16($sp)
	lw $s2, 12($sp)
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, ($sp)
	addi $sp, $sp, 20
	jr $ra
		
paint_World:
	addi $sp, $sp, -20
	sw $ra, ($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)

	li $s0, 0
paint_Loop:
	beq $s0, 4096, endPaint_World
	
	addi $s2, $s0, 768	# array coords by applying offset
	lw $s1, arrayRep($s2)	# get value at coords
	add $s2, $s0, $gp	# get address at coords
	beq $s1, 0, dBackground
	beq $s1, 1, dPlatform
	beq $s1, 2, dPogoStick
	beq $s1, 3, dBrokenPlatform
	beq $s1, 4, dCloudPlatform
	beq $s1, 5, dJetpack
	beq $s1, 6, dMovingPlatform
	beq $s1, 7, dDiamond
	j keep_Paint_Loop
		
dBackground:
	lw $s3, colour_Background
	div $s1, $s0, 40	# gradient
	add $s3, $s3, $s1
	j keep_Paint_Loop

dPlatform:
	lw $s3, colour_Platform
	j keep_Paint_Loop
	
dPogoStick:
	lw $s3, colour_PogoStick
	j keep_Paint_Loop

dBrokenPlatform:
	lw $s3, colour_TempPlatform
	j keep_Paint_Loop
	
dCloudPlatform:
	lw $s3, colour_BaitPlatform
	j keep_Paint_Loop

dJetpack:
	lw $s3, colour_JetPack
	j keep_Paint_Loop
	
dMovingPlatform:
	lw $s3, colour_UnfixedPlatform
	j keep_Paint_Loop

dDiamond:
	lw $s3, colour_Diamond
	j keep_Paint_Loop

keep_Paint_Loop:
	sw $s3, ($s2)
	addi $s0, $s0, 4
	j paint_Loop
	
endPaint_World:
	lw $s3, 16($sp)
	lw $s2, 12($sp)
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, ($sp)
	addi $sp, $sp, 20
	jr $ra


update_movingCharacter:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	li $t4, 0	# reset velocity
	jal get_User_Input
	
	bne $t2, $zero, moveUp
	addi $t4, $t4, 128	# apply gravity
	
	jal if_Car_Collision
	j endMoveCharacter
	
moveUp:
	addi $t4, $t4, -128
	addi $t2, $t2, -1

endMoveCharacter:
	add $t5, $t5, $t4	# move character based on velocity

	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra

if_Car_Collision:
	addi $sp, $sp, -20
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $ra, 16($sp)

	addi $s0, $t5, 768 	# current pos in game array coords
	
	li $s3, 384	# check left, middle and right
	
type_Of_Collision:
	beq $s3, 396, stop_Collision
	add $s1, $s0, $s3
	lw $s2, arrayRep($s1)
	beq $s2, 1, Main_Platform_Collision
	beq $s2, 2, pogoStick_PickUp_Collision
	beq $s2, 3, temporary_Platform_Collision
	beq $s2, 4, bait_Platform_Collision
	beq $s2, 5, jetPack_PickUp_Collision
	beq $s2, 6, Main_Platform_Collision
	beq $s2, 7, diamond_PickUp_Collision
	
	addi $s3, $s3, 4	
	j type_Of_Collision

Main_Platform_Collision:
	addi $t4, $t4, -128		
	lw $t2, airTime_Character	
	j stop_Collision

pogoStick_PickUp_Collision:
	addi $t4, $t4, -128		
	lw $t2, airTime_PogoStick	
	j stop_Collision
	
temporary_Platform_Collision:
	move $a0, $s1			
	jal delete_Platform
	j stop_Collision

bait_Platform_Collision:
	addi $t4, $t4, -128		
	lw $t2, airTime_Character	
	move $a0, $s1			
	jal delete_Platform
	j stop_Collision
	
jetPack_PickUp_Collision:
	lw $t2, airTime_JetPack
	j stop_Collision

diamond_PickUp_Collision:
	jal youWin
	j get_User_Input

stop_Collision:
	lw $ra, 16($sp)
	lw $s3, 12($sp)
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 20
	jr $ra

#get user input and check what input
get_User_Input:
	addi $sp, $sp, -8
	sw $s0, ($sp)
	sw $s1, 4($sp)
	
	lw $s0, 0xffff0000	# Mem Mapped I/O from this address/input control register
	beq $s0, 1, inputDetected
	j endInput

#check what type of input
inputDetected:
 	lw $s1, 0xffff0004	# move when input detected to input data register
	beq $s1, ASCII_a, inputA
	beq $s1, ASCII_d, inputD
	beq $s1, ASCII_p, inputP
	beq $s1, ASCII_e, inputE_anytime
	j endInput
	
inputP:
	j main

inputA:
	addi $t4, $t4, -8
	j endInput

inputD:
	addi $t4, $t4, 8
	j endInput

inputE_anytime:
	jal end_Screen
	j inputDetected
						
endInput:
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 8
	jr $ra
	
#painting Car with body as purple and wheels as black colour
paint_Character:
	addi $sp, $sp, -8
	sw $s0, ($sp)
	sw $s1, 4($sp)
	
	lw $s1, colour_Car
	add $s0, $gp, $t5
	sw $s1, 4($s0)
	sw $s1, 132($s0)
	sw $s1, 260($s0)
	sw $s1, 388($s0)
	
	lw $s1, colour_Wheels
	sw $s1, 128($s0)
	sw $s1, 136($s0)
	sw $s1, 384($s0)
	sw $s1, 392($s0)

	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 8
	jr $ra
	
#sleep syscall for delay whenever needed
sleep:	
	li $v0, 32
	lw $a0, onSleep
	syscall
	jr $ra
	
	
end_Screen:
	addi $sp, $sp, -12
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	
	#lw $s1, init_Position
	lw $s0, colour_GG	#get appropriate colour
	addi $s1, $gp, 1960	#locate frame to paint END

	# char E
	sw $s0, 384($s1)
	sw $s0, 256($s1)
	sw $s0, 128($s1)
	sw $s0, 0($s1)
	sw $s0, 4($s1)
	sw $s0, 260($s1)
	sw $s0, 512($s1)
	sw $s0, 516($s1)
	
	#char N
	sw $s0, 16($s1)
	sw $s0, 144($s1)
	sw $s0, 272($s1)
	sw $s0, 400($s1)
	sw $s0, 528($s1)
	sw $s0, 20($s1)
	sw $s0, 24($s1)
	sw $s0, 152($s1)
	sw $s0, 280($s1)
	sw $s0, 408($s1)
	sw $s0, 536($s1)
	#sw $s0, 12($s1)
	
	#char D
	sw $s0, 48($s1)
	sw $s0, 176($s1)
	sw $s0, 296($s1)
	sw $s0, 300($s1)
	sw $s0, 304($s1)
	sw $s0, 424($s1)
	sw $s0, 432($s1)
	sw $s0, 552($s1)
	sw $s0, 556($s1)
	sw $s0, 560($s1)
	
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 12
	jr $ra
	

		
#exit the Game
exitGame:
	addi $v0, $zero, 10	# 10: exit syscall 
	syscall			# system called
	