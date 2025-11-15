.386
.model flat, stdcall
.stack 4096

INCLUDE Irvine32.inc

.data
	SCREEN_WIDTH = 80
	SCREEN_HEIGHT = 24
	MAX_FRUITS = 5
	FRUIT_SPEED = 1

	score DWORD 0
	lives DWORD 3
	gameOver BYTE 0

	fruit STRUCT 
		x BYTE ?
		y BYTE ?
		active BYTE	?
		type BYTE ?
		speed BYTE ?
	fruit ENDS
	fruits fruit MAX_FRUITS DUP(<>)

	welcomeMsg BYTE "Welcome to Fruit Ninja!", 0
	instructions BYTE "Use A/D to move. Space to slice", 0
	scoreMsg BYTE "Score: ", 0
	livesMsg BYTE "Lives: ", 0
	gameOverMsg BYTE "GAME OVER! Final Score: ", 0
	playAgainMsg BYTE "Press Y to play again, or any other key to exit", 0

	;player position
	playerX BYTE SCREEN_WIDTH /2 ;set the player to the middle of the screen
	fruitChars BYTE "0@#$&0" ; the different kinds of fruit
	playerChar BYTE "|" ;Ninja sword
	sliceChar BYTE "-" ;slice effect used 

 .code
 main PROC
 	call Randomize

 StartGame:
 	call ResetGame

 GameLoop:
 	call Clrscr
 	call UpdateFruits
 	call RenderFrame

 	mov al, gameOver
 	cmp al, 0
 	jne EndGame

 	jmp GameLoop

 EndGame:

 main ENDP