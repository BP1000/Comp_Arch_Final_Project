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
		var_type BYTE ?
		speed BYTE ?
	fruit ENDS
	fruits fruit MAX_FRUITS DUP(<0, 0, 0,1>)

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

	SpawnFruit PROTO
	ResetGame PROTO
	HandleInputs PROTO
	UpdateFruits PROTO
	RenderFrame PROTO
	PlayAgain PROTO
 .code
 main PROC
 	call Randomize
	call Clrscr
	mov edx, OFFSET welcomeMSG
	call WriteString
	call Crlf
	mov edx, OFFSET instructions
	call WriteString
	call Crlf
	call ReadKey

 StartGame:
 	call ResetGame

 GameLoop:
 	call Clrscr
 	call UpdateFruits
 	call RenderFrame

 	mov al, gameOver
 	cmp al, 0
 	jne EndGame

 	;avoid flashing screen 
 	mov eax, 30
 	call Delay

 	jmp GameLoop

 EndGame:
 	call PlayAgain
 	call ReadKey ;see if player wants to play again or not
 	cmp al, 'Y'
 	je StartGame
 	cmp al, 'y'
 	je StartGame

 	exit

 main ENDP

 ResetGame PROC
 ;spawn fruits n stuff

 ResetGame ENDP

 HandleInput PROC
 ;read / deal w input

 HandleInput ENDP

 UpdateFruits PROC
 ;handle fruit when its missed and make more

 UpdateFruits ENDP

 RenderFrame PROC

 RenderFrame ENDP

 PlayAgain PROC
 ;check if user wants to play again

 PlayAgain ENDP
 END main