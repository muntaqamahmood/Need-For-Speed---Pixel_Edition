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
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 2
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes / no / yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

#define constants
#ASCII codes for p, w, a, s, d, e
.eqv	ASCII_p 0x70	#restart game anytime
.eqv	ASCII_w 0x77	#move up
.eqv	ASCII_a 0x61	#move left
.eqv	ASCII_s 0x73	#move down (remove if not needed)
.eqv	ASCII_d 0x64	#move right
.eqv	ASCII_e 0x65	#exit game

.data
arrRep: 		.word 0:1536	# array to store 
onSleep: 		.word 40	# sleep timer
false:			.word 0		# int for bool false
true:			.word 1		# int for bool true
#lllbittt:		.word 32	# 32 bit
#hbit:			.word 64	# 64 bit
create:			.word 768	# object respawn/spawn frame
#0xffff0000:			.word 0xffff0000 # input control register
#0xffff0004:			.word 0xffff0004 # input data register

initpos_Character: 	.word 32	# char initial pos on screen
airTime_Character: 	.word 13	# jump duration in frames
airTime_PogoStick: 	.word 20	# pogoStick boost duration in frames
airTime_JetPack: 	.word 50

# colours for character, objects, platforms, background etc
colour_JetPack: 	.word 0x1C2EFF	#
colour_Platform: 	.word 0x1F5403	#
colour_Background: 	.word 0xFFB75E	#
colour_UnfixedPlatform: .word 0xB4D6D6	#
colour_ScoreBar: 	.word 0x20354D	#
colour_Character: 	.word 0xBF6235	#
colour_TempPlatform: 	.word 0x3DA606	#
colour_PogoStick: 	.word 0x7E10B0	#
colour_BaitPlatform: 	.word 0x5DFF08	#
colour_AirBar: 		.word 0x1BC9FA	#
colour_GG:		.word 0x171717	# Game over colour
		
.text
main:
	
	lw $t0, false			# difficulty / platform spacing		$t5
	lw $t1, create			# next spawn coord / spawn timer	$t4
	lw $t2, false 			# character gravity rate of change	$t1
	lw $t3, initpos_Character  	# character current position		$t0
	lw $t4, false			# jump timer				$t2
	lw $t5, false			# game state (false=on=0, true=off=1)	$t3
	li $t6, -128			# movingPlatform timer

	li $s0, 0			#init global pointer $s0 to 0
	
#
startLoop:
	beq $s0, 32, gameLoop
	jal move_Screen
	jal spawnNewPlatform
	jal paint_Screen
	addi $s0, $s0, 1
	j startLoop

#
gameLoop:
	bge $t3, 1536, skipScroll
	jal move_Screen
	jal spawnNewPlatform
	addi $t3, $t3, 128	# also move_ player

#
skipScroll:
	jal updateMovingPlatforms
	beq $t5, true, skipMoveCharacter
	jal moveCharacter		#drawDoodler

#
skipMoveCharacter:
	jal paint_Screen		#drawWorld
	jal paint_Character
	jal paint_ScoreMeter
	
	
	ble $t3, 4096, gameOn	# character reaches bottom of screen
	jal gameOverScreen
	jal gameOverText
	beq $t5,1, gameOn
	li $t5, 1
gameOn:
	jal sleep
	j gameLoop
	
endGameLoop:
	j exitGame


updateMovingPlatforms:
	addi $sp, $sp, -12
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)

	li $s0, 4864

	movePlatformLoop:
		beq $s0, 768, endMovePlatLoop
		lw $s1, arrRep($s0)
		bne $s1, 6, contMovePlatLoop

		addi $s2, $s0, 4
		sw $zero, arrRep($s0)
		sw $s1, arrRep($s2)

		contMovePlatLoop:
			addi $s0, $s0, -4
			j movePlatformLoop

	endMovePlatLoop:
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, ($sp)
	addi $sp, $sp, 12
	jr $ra

paint_ScoreMeter:
	addi $sp, $sp, -12
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	
	lw $s2, colour_ScoreBar
	div $s0, $t0, 12
	
	paint_ScoreMeterLoop:
		beq $s0, 0, endDrawScoreMeter
		
		mul $s1, $s0, -128
		add $s1, $s1, $gp
		
		add $s2, $s2, -4	# gradient
		sw $s2, 3972($s1)
		
		addi $s0, $s0, -1
		j paint_ScoreMeterLoop
	
	endDrawScoreMeter:
		lw $s2, 8($sp)
		lw $s1, 4($sp)
		lw $s0, ($sp)
		addi $sp, $sp, 12
		jr $ra

#Block edges so that player cant move past edge	

# a0 holds platform type
spawnPlatform:
	addi $sp, $sp, -4
	sw $s0, ($sp)
	move $s0, $t1
	sw $a0, arrRep($s0) # spawn platform
	addi $s0, $s0, 4
	sw $a0, arrRep($s0)
	addi $s0, $s0, 4
	sw $a0, arrRep($s0)
	addi $s0, $s0, 4
	sw $a0, arrRep($s0)
	lw $s0, ($sp)
	addi $sp, $sp, 4
	jr $ra


# $a0 reference in array matrix representation of coordnations
removePlatform:
	addi $sp, $sp, -16
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	
	lw $s0, arrRep($a0)	# load reference pixel to know which platform it is
	li $s1, -12	# iterate all possibilities of a 4 wide platform
	
	removeLoop:
		beq $s1, 16, finishRemove
		add $s3, $a0, $s1	# current coord we are looking at
		
		lw $s4, arrRep($s3)	# load contents of current pixel
		bne $s4, $s0, contRemoveLoop	# check if same as reference
		sw $zero, arrRep($s3)
	
	contRemoveLoop:
		addi $s1, $s1, 4
		j removeLoop
	
	finishRemove:
		lw $s3, 12($sp)
		lw $s2, 8($sp)
		lw $s1, 4($sp)
		lw $s0, ($sp)
		addi $sp, $sp, 16
		jr $ra
		

spawnNewPlatform:
	addi $sp, $sp, -8
	sw $ra, ($sp)
	sw $s0, 4($sp)
	
	bge $t1, 768, endSpawnNewPlat
	
	addi $t0, $t0, 1	# increase difficulty
	
	# RNG for type of obstacle
	li $v0, 42
	li $a0, 0
	li $a1, 30
	syscall
	
	blt $a0, 10, spawnNext1
	li $a0, 1	# 1 represents standard platform
	jal spawnPlatform
	j endSpawn

	spawnNext1:
		blt $a0, 9, spawnNext2
		blt $a0, 10, spawnNext2
		li $a0, 3	# 3 represents broken platform
		jal spawnPlatform
		j endSpawn

	spawnNext2:
		blt $a0, 8, spawnNext3
		blt $a0, 10, spawnNext3
		li $a0, 4	# 4 represents cloud platform
		jal spawnPlatform
		j endSpawn

	spawnNext3:
		blt $a0, 7, spawnNext4
		blt $a0, 4, spawnNext4
		li $a0, 6	# 6 represents moving platform
		jal spawnPlatform
		j endSpawn
	
	spawnNext4:
		blt $a0, 4, spawnNext5
		li $a0, 1	
		jal spawnPlatform
		j endSpawn
		
	spawnNext5:
		li $a0, 1	
		jal spawnPlatform
		j endSpawn
	
	endSpawn:
		# RNG for next platform
		li $v0, 42
		li $a0, 0
		li $a1, 192
		syscall
		
		add $a0, $a0, $t0	# apply difficulty as spacing
		mul $a0, $a0, 4		# coord form
		addi $t1, $a0, 768	# apply offset for buffer
		#add $t1, $t1, $t0	# apply general spacing
	
	endSpawnNewPlat:
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
	
	addi $t1, $t1, -128 	# update move_ timer
	
	li $s0, 4864
	moveUp:
		blt $s0, $zero, endScrollScreen
		lw $s1, arrRep($s0)
		addi $s2, $s0, 128	# move_ amount
		sw $s1, arrRep($s2)
		addi $s0, $s0, -4
		j moveUp
		
	endScrollScreen:
		lw $s3, 16($sp)
		lw $s2, 12($sp)
		lw $s1, 8($sp)
		lw $s0, 4($sp)
		lw $ra, ($sp)
		addi $sp, $sp, 20
		jr $ra
		

paint_Screen:
	addi $sp, $sp, -20
	sw $ra, ($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	li $s0, 0
	paint_Loop:
		beq $s0, 4096, endPaintScreen
		
		addi $s2, $s0, 768	# matrix coords by applying offset
		lw $s1, arrRep($s2)	# get value at coords
		add $s2, $s0, $gp	# get address at coords
		beq $s1, 0, dBackground
		beq $s1, 1, dPlatform
		
		beq $s1, 6, dMovingPlatform
		j contDrawLoop
		
	dBackground:
		lw $s3, colour_Background
		div $s1, $s0, 64	# gradient
		add $s3, $s3, $s1
		j contDrawLoop
		
	dPlatform:
		lw $s3, colour_Platform
		j contDrawLoop
		
	
		
	dMovingPlatform:
		lw $s3, colour_UnfixedPlatform
		j contDrawLoop
	
	contDrawLoop:
		sw $s3, ($s2)
		addi $s0, $s0, 4
		j paint_Loop
		
	endPaintScreen:
		lw $s3, 16($sp)
		lw $s2, 12($sp)
		lw $s1, 8($sp)
		lw $s0, 4($sp)
		lw $ra, ($sp)
		addi $sp, $sp, 20
		jr $ra


moveCharacter:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	li $t2, 0	# reset velocity
	jal checkKeyboardInput
	
	bne $t4, $zero, jumping
	addi $t2, $t2, 128	# apply gravity
	
	jal checkCharacterCollision
	j endMoveCharacter
	
	jumping:
		addi $t2, $t2, -128
		addi $t4, $t4, -1
	
	endMoveCharacter:
		add $t3, $t3, $t2	# move character based on velocity
	
		lw $ra, ($sp)
		addi $sp, $sp, 4
		jr $ra
	

checkCharacterCollision:
	addi $sp, $sp, -20
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $ra, 16($sp)
	addi $s0, $t3, 768 	# current pos in game matrix coords
	
	li $s3, 384	# check left, middle and right
	
	checkCollisions:
		beq $s3, 396, endCheckCollisions
		add $s1, $s0, $s3
		lw $s2, arrRep($s1)
		beq $s2, 1, standardPlatformCollision
		beq $s2, 6, standardPlatformCollision
		addi $s3, $s3, 4	# increase iterator
		j checkCollisions
	
	standardPlatformCollision:
		addi $t2, $t2, -128		# cancel gravity
		lw $t4, airTime_Character	# start jump
		j endCheckCollisions

	endCheckCollisions:
		lw $ra, 16($sp)
		lw $s3, 12($sp)
		lw $s2, 8($sp)
		lw $s1, 4($sp)
		lw $s0, ($sp)
		addi $sp, $sp, 20
		jr $ra


checkKeyboardInput:
	addi $sp, $sp, -8
	sw $s0, ($sp)
	sw $s1, 4($sp)
	
	lw $s0, 0xffff0000	# Mem Mapped I/O from this address/input control register
	beq $s0, 1, inputDetected
	j endInput
	
	inputDetected:
	 	lw $s1, 0xffff0004	# move when input detected to input data register
		beq $s1, ASCII_a, inputA
		beq $s1, ASCII_d, inputD
		beq $s1, ASCII_p, inputP
		j endInput
	
	inputP:
		j main
	
	inputA:
		addi $t2, $t2, -8
		j endInput
	
	inputD:
		addi $t2, $t2, 8
	
	endInput:
		lw $s1, 4($sp)
		lw $s0, ($sp)
		addi $sp, $sp, 8
		jr $ra
	
# Draw character at $a0 position with $a1 color
paint_Character:
	addi $sp, $sp, -4
	sw $s0, ($sp)
	add $s0, $gp, $a0
	
	sw $a1, 0($s0)
	sw $a1, 4($s0)
	sw $a1, 8($s0)
	sw $a1, 128($s0)
	sw $a1, 136($s0)
	sw $a1, 132($s0)
	sw $a1, 256($s0)
	sw $a1, 260($s0)
	sw $a1, 264($s0)

	lw $s0, ($sp)
	addi $sp, $sp, 4
	jr $ra

# Draw background with $a0 color
paint_Background:
	addi $sp, $sp, -8
	sw $s0, ($sp)
	sw $s1, 4($sp)
	
	li $s0, 0
	bgDrawLoop:
		beq $s0, 4096, endBgDraw
		add $s1, $s0, $gp
		sw $a0, ($s1)
		
		addi $s0, $s0, 4
		j bgDrawLoop
	
	endBgDraw:
		lw $s1, 4($sp)
		lw $s0, ($sp)
		addi $sp, $sp, 8
		jr $ra
		
sleep:	
	li $v0, 32
	lw $a0, onSleep
	syscall
	jr $ra
	

gameOverText:
	addi $sp, $sp, -12
	sw $s0, ($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	
	lw $s0, colour_GG	#load colour
	addi $s1, $gp, 1960	#locate frame to paint GG
	
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

	
gameOverScreen:
	lw $s0, 0xffff0000
	beq $s0, 1, gameOverInput
	jr $ra
	
	gameOverInput:
	 	lw $s1, 0xffff0004
		beq $s1, ASCII_p, inputPend
		beq $s1, ASCII_e, inputE
		jr $ra
	
	inputPend:
		j main
	
	inputE:
		j exitGame

#exit the Game
exitGame:
	addi $v0, $zero, 10	# 10: exit syscall 
	syscall			# system called
	