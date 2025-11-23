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
	fruits fruit MAX_FRUITS DUP(<0, 0, 0, 0,1>)

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
	HandleInput PROTO
	UpdateFruits PROTO
	RenderFrame PROTO
	PlayAgain PROTO
 .code
 main PROC
 	call Randomize
	call Clrscr
	mov edx, OFFSET welcomeMsg
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
	call HandleInput
 	;call UpdateFruits
 	;call RenderFrame

	;check if game over
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
 mov score, 0
 mov lives, 3
 mov gameOver, 0
 mov ecx, MAX_FRUITS
 mov edi, OFFSET fruits
 
 ClearLoop:
	mov BYTE PTR [edi].fruit.active, 0
	add edi, SIZEOF fruit
	loop ClearLoop
	;spawn 2 fruits
	call SpawnFruit
	call SpawnFruit
	ret
ResetGame ENDP

SpawnFruit PROC
	mov edi, OFFSET fruits
	mov ecx, MAX_FRUITS
FindSlot:
	cmp BYTE PTR [edi].fruit.active, 0
	je Found
	add edi, SIZEOF fruit
	loop FindSlot
	ret
Found:
	mov BYTE PTR [edi].fruit.active, 1
	;random X value
	mov eax, SCREEN_WIDTH - 2
	call RandomRange
	mov [edi].fruit.x, al
	mov BYTE PTR [edi].fruit.y, 1
	mov eax, 5
	call RandomRange
	mov [edi].fruit.var_type, al
	mov BYTE PTR [edi].fruit.speed, 1
	ret
SpawnFruit ENDP

 HandleInput PROC
 ;read / deal w input
 	;call KeyPressed
 	cmp eax, 0
 	je NoInput

 	call ReadKey
 	cmp al, 'A'
 	je MoveLeft
 	cmp al, 'D'
 	je MoveRight
 	cmp al, ' '
 	je Slice
 	jmp NoInput

 MoveLeft:
 	cmp playerX, 0
 	jle NoInput
 	dec playerX
 	jmp NoInput
 MoveRight:
 	cmp playerX, SCREEN_WIDTH-1
 	jge NoInput
 	inc playerX
 	jmp NoInput
 NoInput:
 	ret
 Slice:
 	mov ecx, MAX_FRUITS
 	mov edi, OFFSET fruits
 FruitLoop:
 	cmp BYTE PTR [edi].fruit.active, 1
 	jne MissedSlice

 	;check columns
 	mov al, [edi].fruit.x
 	cmp al, playerX
 	jne MissedSlice

 	;check fruit near bottom
 	mov al, [edi].fruit.y
 	cmp al, SCREEN_HEIGHT-2
 	jl MissedSlice

 	;user hit fruit
 	mov BYTE PTR [edi].fruit.active, 0
 	inc score
 	call SpawnFruit

MissedSlice:
 	add edi, SIZEOF fruit
 	loop FruitLoop
 	jmp NoInput

HandleInput ENDP

UpdateFruits PROC
 ;handle fruit when its missed and make more
	mov ecx, MAX_FRUITS
	mov edi, OFFSET fruits

FruitLoop:
	cmp BYTE PTR [edi].fruit.active, 1
	jne NextFruit
	mov al, [edi].fruit.y
	inc al
	mov [edi].fruit.y, al
	cmp al, SCREEN_HEIGHT - 1
	jl NextFruit
	mov BYTE PTR [edi].fruit.active, 0
	dec lives
	cmp lives, 0
	jne Respawn
	mov gameOver, 1
	jmp EndF
Respawn:
	call SpawnFruit
NextFruit:
	add edi, SIZEOF fruit
	loop FruitLoop
EndF:
	ret
 UpdateFruits ENDP

 RenderFrame PROC

 RenderFrame ENDP

 PlayAgain PROC
 ;check if user wants to play again

 PlayAgain ENDP
 END main