.386
.model flat, stdcall
.stack 4096

INCLUDE Irvine32.inc

.data
	SCREEN_WIDTH = 80
	SCREEN_HEIGHT = 24
	MAX_FRUITS = 5
	FRUIT_SPEED = 150 ; Frame delay (ms) - reduced slightly for smoother movement
	FRUIT_SPAWN_CHANCE = 80

	score DWORD 0
	lives DWORD 3
	gameOver BYTE 0

	fruit STRUCT 
		x BYTE ?
		y BYTE ?
		active BYTE	?
		var_type BYTE ?
		speed BYTE ?
		counter BYTE ? ; Counter to control movement speed
	fruit ENDS
	fruits fruit MAX_FRUITS DUP(<0, 0, 0, 0, 1, 0>)

	welcomeMsg BYTE "Welcome to Fruit Ninja!", 0
	instructions BYTE "Use A/D to move. Space to slice", 0
	scoreMsg BYTE "Score: ", 0
	livesMsg BYTE "Lives: ", 0
	gameOverMsg BYTE "GAME OVER! Final Score: ", 0
	playAgainMsg BYTE "Press Y to play again, or any other key to exit", 0

	playerX BYTE SCREEN_WIDTH /2
	fruitChars BYTE "0@#$&"
	playerChar BYTE "|"
	sliceChar BYTE "-"

	SpawnFruit PROTO
	CheckCollision PROTO xPos:BYTE, yPos:BYTE
	ResetGame PROTO
	HandleInput PROTO
	UpdateFruits PROTO
	RenderFrame PROTO
	PlayAgain PROTO
.code

CheckCollision PROC USES ecx edi, xPos:BYTE, yPos:BYTE
	mov ecx, MAX_FRUITS
	mov edi, OFFSET fruits
	
CheckLoop:
	cmp BYTE PTR [edi].fruit.active, 1
	jne SkipCheck
	
	mov al, [edi].fruit.x
	cmp al, xPos
	jne SkipCheck
	
	mov al, [edi].fruit.y
	cmp al, yPos
	jne SkipCheck
	
	mov eax, 1
	ret
	
SkipCheck:
	add edi, SIZEOF fruit
	dec ecx
	jnz CheckLoop
	
	mov eax, 0
	ret
CheckCollision ENDP
 
ResetGame PROC
	mov score, 0
	mov lives, 3
	mov gameOver, 0
	mov ecx, MAX_FRUITS
	mov edi, OFFSET fruits
 
ClearLoop:
	mov BYTE PTR [edi].fruit.active, 0
	mov BYTE PTR [edi].fruit.counter, 0
	add edi, SIZEOF fruit
	dec ecx
	jnz ClearLoop
	
	call SpawnFruit
	call SpawnFruit
	ret
ResetGame ENDP

SpawnFruit PROC USES eax ebx ecx edi
	LOCAL attempts:BYTE
	mov attempts, 20
	
TryAgain:
	dec attempts
	cmp attempts, 0
	je SpawnFailed
	
	mov ecx, MAX_FRUITS
	mov edi, OFFSET fruits
FindSlot:
	cmp BYTE PTR [edi].fruit.active, 0
	je FoundSlot
	add edi, SIZEOF fruit
	dec ecx
	jnz FindSlot
	ret
	
FoundSlot:
	; Generate random X position as multiple of 5
	mov eax, SCREEN_WIDTH - 1
	xor edx, edx
	mov ebx, 5
	div ebx
	mul ebx
	
	mov ebx, eax
	mov eax, ebx
	mov ecx, 5
	xor edx, edx
	div ecx
	
	call RandomRange
	inc eax
	mov bl, 5
	mul bl
	mov dl, al ; X position (multiple of 5)
	
	; Y position starts at 0 (top of screen)
	mov dh, 0
	
	invoke CheckCollision, dl, dh
	cmp eax, 1
	je TryAgain
	
	; Good position found
	mov BYTE PTR [edi].fruit.active, 1
	mov [edi].fruit.x, dl
	mov [edi].fruit.y, dh
	
	mov eax, 5
	call RandomRange
	mov [edi].fruit.var_type, al
	
	; Set speed (movement delay)
	; 1 = fastest, 3 = slowest
	mov eax, 3
	call RandomRange
	inc eax ; Now 1-3
	mov [edi].fruit.speed, al
	
	; Initialize counter to 0
	mov [edi].fruit.counter, 0
	
	ret
	
SpawnFailed:
	mov ecx, MAX_FRUITS
	mov edi, OFFSET fruits
FindAnySlot:
	cmp BYTE PTR [edi].fruit.active, 0
	je ForceSpawn
	add edi, SIZEOF fruit
	dec ecx
	jnz FindAnySlot
	ret
	
ForceSpawn:
	mov BYTE PTR [edi].fruit.active, 1
	mov [edi].fruit.x, 5
	mov [edi].fruit.y, 0
	mov eax, 5
	call RandomRange
	mov [edi].fruit.var_type, al
	mov [edi].fruit.speed, 1
	mov [edi].fruit.counter, 0
	ret
SpawnFruit ENDP

HandleInput PROC
	call ReadKey
	jz NoInput
	cmp ax, 1E00h
	je MoveLeft
	cmp ax, 2000h
	je MoveRight
	cmp ax, 4B00h
	je MoveLeft
	cmp ax, 4D00h
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
	mov bl, 0
	
SliceLoop:
	cmp BYTE PTR [edi].fruit.active, 1
	jne NextFruitSlice
	
	; Check if fruit is at slicing height (one above player or at player height)
	mov al, [edi].fruit.y
	cmp al, SCREEN_HEIGHT - 2
	je CheckSlice
	cmp al, SCREEN_HEIGHT - 1
	jne NextFruitSlice
	
CheckSlice:
	mov al, [edi].fruit.x
	sub al, playerX
	cmp al, 0
	je HitFruit
	cmp al, 5
	je HitFruit
	cmp al, -5
	je HitFruit
	cmp al, 10
	je HitFruit
	cmp al, -10
	je HitFruit
	jmp NextFruitSlice
	
HitFruit:
	mov dl, [edi].fruit.x
	mov dh, [edi].fruit.y
	call Gotoxy
	mov al, sliceChar
	call WriteChar
	
	mov BYTE PTR [edi].fruit.active, 0
	inc score
	mov bl, 1
	
	push eax
	mov eax, 50
	call Delay
	pop eax
	
NextFruitSlice:
	add edi, SIZEOF fruit
	dec ecx
	jnz SliceLoop
	
	cmp bl, 1
	jne NoInput
	call SpawnFruit
	
NoInput:
	ret
HandleInput ENDP

UpdateFruits PROC
	mov ecx, MAX_FRUITS
	mov edi, OFFSET fruits

UpdateLoop:
	cmp BYTE PTR [edi].fruit.active, 1
	jne NextUpdateFruit
	
	; Increment counter
	mov al, [edi].fruit.counter
	inc al
	mov [edi].fruit.counter, al
	
	; Check if it's time to move this fruit based on its speed
	mov bl, [edi].fruit.speed
	cmp bl, 1
	je MoveFast
	cmp bl, 2
	je MoveMedium
	; Speed = 3 (slowest)
	
MoveSlow:
	; Move every 3 frames
	mov bl, al
	and bl, 3 ; Check if divisible by 3 (bits 0-1 = 0)
	cmp bl, 0
	jne NextUpdateFruit
	jmp DoMove
	
MoveMedium:
	; Move every 2 frames
	test al, 1 ; Check if odd/even
	jnz NextUpdateFruit
	jmp DoMove
	
MoveFast:
	; Move every frame (always move)
	
DoMove:
	; Move the fruit down by 1
	mov al, [edi].fruit.y
	inc al ; Move down by 1 position
	mov [edi].fruit.y, al
	
	; Check if fruit reached or passed bottom
	cmp al, SCREEN_HEIGHT - 1
	jl NextUpdateFruit
	
	; Fruit reached bottom
	mov BYTE PTR [edi].fruit.active, 0
	dec lives
	cmp lives, 0
	jg RespawnUpdate
	mov gameOver, 1
	jmp NextUpdateFruit
	
RespawnUpdate:
	call SpawnFruit
	
NextUpdateFruit:
	add edi, SIZEOF fruit
	dec ecx
	jnz UpdateLoop
	ret
UpdateFruits ENDP

RenderFrame PROC
	call Clrscr
	
	mov dh, 0
	mov dl, 0
	call Gotoxy
	
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
	jne SkipDraw
	
	mov dl, [edi].fruit.x
	mov dh, [edi].fruit.y
	call Gotoxy
	
	push ecx
	push edi
	invoke CheckCollision, dl, dh
	pop edi
	pop ecx
	
	cmp eax, 1
	ja SkipDraw
	
	movzx eax, [edi].fruit.var_type
	mov al, fruitChars[eax]
	call WriteChar
	
SkipDraw:
	add edi, SIZEOF fruit
	dec ecx
	jnz DrawFruitLoop
	
	; Adjust playerX to nearest multiple of 5
	mov al, playerX
	xor ah, ah
	mov bl, 5
	div bl
	cmp ah, 0
	je PlayerPosOK
	mov al, playerX
	add al, 2
	mov bl, 5
	div bl
	mul bl
	mov playerX, al
	
PlayerPosOK:
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
	
	mov al, gameOver
	cmp al, 1
	je EndGame
	
	call RenderFrame
	
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
	jmp GameLoop

main ENDP
END main


