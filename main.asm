.386
.model flat, stdcall
.stack 4096

INCLUDE Irvine32.inc

.data
	SCREEN_WIDTH = 80
	SCREEN_HEIGHT = 24
	MAX_FRUITS = 5
	FRUIT_SPEED = 200 ;increase delay so that the game doesn't end instantly
	FRUIT_SPAWN_CHANCE = 80 ;decreaes the chance for fruits to spawn

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
	fruits fruit MAX_FRUITS DUP(<0, 0, 0, 0,100>)

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
	mov eax, SCREEN_WIDTH - 2
	call RandomRange
	inc eax
	mov [edi].fruit.x, al
	mov BYTE PTR [edi].fruit.y, 0
	mov eax, 5
	call RandomRange
	mov [edi].fruit.var_type, al
	mov BYTE PTR [edi].fruit.speed, 1
	ret
SpawnFruit ENDP

HandleInput PROC
 ;read / deal w input
 call ReadKey
 jz NoInput ;No key pressed
 cmp ax, 1E00h;'A' key scan code
 je MoveLeft
 cmp ax, 2000h ; 'D' key scan code
 je MoveRight

 cmp ax, 4B00h ;left arrow
 je MoveLeft
 cmp ax, 4D00h ;right arrow
 je MoveRight

 cmp al, ' '
 je SliceKey
 jmp NoInput
 MoveLeft:
 	sub playerX, 5
 	cmp playerX, 1
 	jge ClampDoneLeft 
 	mov playerX, 1
 ClampDoneLeft:
 	jmp NoInput
 MoveRight:
    add playerX, 5
 	cmp playerX, SCREEN_WIDTH-1
 	jle ClampDoneRight
 	mov playerX, SCREEN_WIDTH-1
 ClampDoneRight:
 	jmp NoInput

 SliceKey:
 	mov ecx, MAX_FRUITS
 	mov edi, OFFSET fruits
 FruitLoop:
 	cmp BYTE PTR [edi].fruit.active, 1
 	jne NextFruit
	mov al, [edi].fruit.y
	cmp al, SCREEN_HEIGHT - 2
	je CheckSlice
	cmp al, SCREEN_HEIGHT - 1
	jne NextFruit

  CheckSlice:
	mov al, [edi].fruit.x
	sub al, playerX
	cmp al, 0
	je HitFruit
	cmp al, 1
	je HitFruit
	cmp al, -1
	je HitFruit
	jmp NextFruit
NotAtSliceHeight:
	mov al, [edi].fruit.y
	cmp al, SCREEN_HEIGHT - 1
	jne NextFruit
	mov al, [edi].fruit.x
	sub al, playerX
	cmp al, 0
	je HitFruit
	cmp al, 1
	je HitFruit
	cmp al, -1
	je HitFruit
	cmp al, 2
	je HitFruit
	cmp al, -2
	je HitFruit
	jmp NextFruit
HitFruit:
	mov dl, [edi].fruit.x
	mov dh, [edi].fruit.y
	call Gotoxy
	mov al, sliceChar
	call WriteChar

	mov BYTE PTR [edi].fruit.active, 0
	inc score

	push eax
	mov eax, 50
	call Delay
	pop eax
	call SpawnFruit
	ret
NextFruit:
	add edi, SIZEOF fruit
	jnz FruitLoop
NoInput:
	ret
HandleInput ENDP


UpdateFruits PROC
 ;handle fruit when its missed and make more
	mov ecx, MAX_FRUITS
	mov edi, OFFSET fruits

UpdateLoop:
	cmp BYTE PTR [edi].fruit.active, 1
	jne NextFruit
	mov al, [edi].fruit.y
	add al, [edi].fruit.speed
	mov [edi].fruit.y, al
	cmp al, SCREEN_HEIGHT - 1
	jl NextFruit
	; Fruit reached bottom
	mov al, [edi].fruit.x
	sub al, playerX
	cmp al, 0
	je PlayerAtFruit
	cmp al, 1
	je PlayerAtFruit
	cmp al, -1
	je PlayerAtFruit

	mov BYTE PTR [edi].fruit.active, 0
	dec lives
	cmp lives ,0
	jg Respawn
	mov gameOver, 1
	jmp NextFruit

PlayerAtFruit:
	mov BYTE PTR [edi].fruit.active, 0
Respawn:
	call SpawnFruit
NextFruit:
	add edi, SIZEOF fruit
	dec ecx
	jnz UpdateLoop
	ret
 UpdateFruits ENDP



RenderFrame PROC
	call Clrscr
	;Save curosr position
	mov dh, 0
	mov dl, 0
	call Gotoxy

	;display score and lives
	mov edx, OFFSET scoreMsg
	call WriteString
	mov eax, score
	call WriteDec
	
	mov dl, 20 
	call Gotoxy
	mov edx, OFFSET livesMsg
	call WriteString
	mov eax, lives
	call WriteDec

	mov ecx, MAX_FRUITS
	mov edi, OFFSET fruits
DrawFruitLoop:
	cmp BYTE PTR [edi].fruit.active, 1
	jne Skip
	mov dl, [edi].fruit.x
	mov dh, [edi].fruit.y
	call Gotoxy
	movzx eax, [edi].fruit.var_type
	mov al, fruitChars[eax]
	call WriteChar
Skip:
	add edi, SIZEOF fruit
	loop DrawFruitLoop
	mov dl, playerX
	mov dh, SCREEN_HEIGHT - 1
	call Gotoxy
	mov al, playerChar
	call WriteChar
	ret
RenderFrame ENDP

 PlayAgain PROC
 call Clrscr
 mov edx, OFFSET gameOverMsg
 call WriteString
 mov eax, score
		call WriteDec
 call Crlf
 mov edx, OFFSET playAgainMsg
 call WriteString
 call Crlf
 call ReadKey
 cmp al, 'Y'
 je ChooseRestart
 cmp al, 'y'
 je ChooseRestart
 mov al, 0
 ret
ChooseRestart:
   mov al, 1
   ret
 PlayAgain ENDP

main PROC
 	call Randomize
	call Clrscr
	mov edx, OFFSET welcomeMsg
	call WriteString
	call Crlf
	mov edx, OFFSET instructions
	call WriteString
	call Crlf
	call WaitMsg

 StartGame:
 	call ResetGame

 GameLoop:
	call HandleInput
 	call UpdateFruits

	;check if game over
 	mov al, gameOver
 	cmp al, 1
 	je EndGame
	call RenderFrame

 	;avoid flashing screen 
 	mov eax, FRUIT_SPEED
 	call Delay

 	mov eax, FRUIT_SPAWN_CHANCE
	call RandomRange
	cmp eax, 0
	jne NoSpawn
	call SpawnFruit
NoSpawn:
	jmp GameLoop

 EndGame:
 	call PlayAgain
 	cmp al, 1
 	je DoRestart
 	exit
 DoRestart:
  call ResetGame
  jmp Gameloop

 main ENDP
 END main