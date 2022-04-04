#####################################################################
#
# CSCB58 Winter 2022 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Muntaqa Abdullah Mahmood, 1007196927, mahmo428, muntaqa.mahmood@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3 (choose the one the applies)
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
#ASCII codes for p, w, a, s, d
.eqv	ASCII_p 0x70
.eqv	ASCII_w 0x77
.eqv	ASCII_a 0x61
.eqv	ASCII_s 0x73
.eqv	ASCII_d 0x64
.eqv	boolfalse 0
.eqv	booltrue 1

.data
baseAddress:		.word 0x10008000 #baseDisplayAddress
colour_Background:	.word 0xA27DDB 	 #background colour
colour_Character:	.word 0x0FFF0D	 #character colour
initpos_Character:	.word 59	 #character start position

#space_man_char	.word	0xff0ddbdc,0xff0ddbdc,0xff0ddbdc, 0xff0ddbdc, 0xff0ddbdc, 0xff0ddbdc,0xff0ddbdc,0xff0ddbdc,0xff0ddbdc,0xff0ddbdc,0xff0ddbdc,0xff0ddbdc,0xff0ddbdc,0xff0ddbdc,0xff0ddbdc,0xff0ddbdc,0xff0ddbdc,0xff0ddbdc,0xff74b2c0,0xff74b2c0,0xff74b2c0,0xff74b2c0,0xff74b2c0, 0xff74b2c0, 0xff74b2c0, 0xff74b2c0,0xffd92874, 0xff0ddbdc, 0xffd92874, 0xffd92874, 0xff0ddbdc, 0xffd92874,0xffd92874, 0xff0ddbdc, 0xffd92874, 0xffd92874, 0xff0ddbdc, 0xffd92874, 0xffd92874, 0xff0ddbdc, 0xff0ddbdc, 0xff0ddbdc, 0xff0ddbdc, 0xffd92874,0xffd92874, 0xffd92874, 0xffd92874, 0xffd92874, 0xffd92874, 0xffd92874,0xff13dc2d, 0xff13dc2d

.text
main:	
	# game begin -> load initial values:
	lw $t0, baseAddress	   #store base display address
	lw $t1, colour_Background  #background init colour
	lw $t2, initpos_Character  #char init pos
	li $t3, 0	   	   #init char gravity
	li $t4, 0	  	   #init game time
	li $t5, 0		   #game state
	li $t5, 768	   	   #char reset point
	li $t6, 0	  	   #initial game level
	li $s0, 0
	
paint_BG:
	sw $t1, 0($t0)		#store colour pixel of base address
	add $t0, $t0, 4		#move to next pixel
	addi $t2, $t2, 1
	bne $t3, 1024, paint_BG	#loop till end of screen
	
	#game just begun -> stationary screen (player not moving to another platform)
beginRound:
	beq $s0, keyPressed	#moving screen (player moving to another platform)
	jal moveScreen		#moveScreen to initial pos
	jal createObstacles	#create obstacles
	jal updateScreen	#updating screen
	addi $s0, $s0, 1	#increment till enough obstacles created for start of game
	j beginRound		#LOOP

	##game just begun -> moving screen (player moving to another platform)
keyPressed:
	bge $t2, 1536, stillScreen 	#player stops if t2 >= 1536
	jal moveScreen
	jal createObstacles
	addi $t0, $t0, 128


stillScreen:
	jal moveObjects
	beq $t5, 1, stillCharacter
	jal moveCharacter
	
	
stillCharacter:
	jal updateScreen
	jal createCharacter
	jal createAirTimer
	jal createScoreTimer
	ble $t2, 4096, gameOn	# if !t2 <= bottom edge of screen, game on		
	jal gameOver			# else GAME OVER!
	jal drawGameOverText		# paint on screen
			
	beq $t5, 1, gameOn
	li $t5, 1		# set gameOver to true
	
gameOn:
	jal sleep
	j keyPressed
		
endGameLoop:
	li $v0, 10 # terminate the program gracefully
	syscall

	
createCharacter:
	addi $sp, $sp, -8
	sw $s0, ($sp)
	sw $s1, 4($sp)
	
	lw $s1, colour_Character
	add $s0, $gp, $t2 

	
	
exit: 	li $v0, 10
	syscall
	
