.386
.model flat, stdcall
.stack 4096

INCLUDE Irvine32.inc

.data
	SCREEN_WIDTH = 80
	SCREEN_HEIGHT = 24
	MAX_FRUITS = 5
	FRUIT_SPEED = 100 ; Frame delay for smoother movement
	SPAWN_INTERVAL = 2000 ; 2 second interval between spawns (in ms)
	MAX_ON_SCREEN = 3 ; Maximum fruits allowed on screen at once

	score DWORD 0
	lives DWORD 3
	gameOver BYTE 0
	spawnTimer DWORD 2000 ; Start with 2 seconds for first spawn
	activeFruitCount BYTE 0 ; Track how many fruits are active

	fruit STRUCT 
		x BYTE ?
		y BYTE ?
		active BYTE	?
		var_type BYTE ?
		speed BYTE ?
		counter BYTE ?
	fruit ENDS
	fruits fruit MAX_FRUITS DUP(<0, 0, 0, 0, 1, 0>)

	welcomeMsg BYTE "Welcome to Fruit Ninja!", 0
	instructions BYTE "Use A/D to move. Space to slice", 0
	scoreMsg BYTE "Score: ", 0
	livesMsg BYTE "Lives: ", 0
	gameOverMsg BYTE "GAME OVER! Final Score: ", 0
	playAgainMsg BYTE "Press Y to play again, or any other key to exit", 0

	playerX BYTE SCREEN_WIDTH /2
	fruitChars BYTE "@#$&0"
	playerChar BYTE "|"
	sliceChar BYTE "-"

	SpawnFruit PROTO
	ResetGame PROTO
	HandleInput PROTO
	UpdateFruits PROTO
	RenderFrame PROTO
	PlayAgain PROTO
.code
 
ResetGame PROC
	mov score, 0
	mov lives, 3
	mov gameOver, 0
	mov spawnTimer, SPAWN_INTERVAL ; Reset timer
	mov activeFruitCount, 0
	
	mov ecx, MAX_FRUITS
	mov edi, OFFSET fruits
 
ClearLoop:
	mov BYTE PTR [edi].fruit.active, 0
	add edi, SIZEOF fruit
	dec ecx
	jnz ClearLoop
	
	; Don't spawn fruit immediately - wait for timer
	ret
ResetGame ENDP

SpawnFruit PROC USES eax ecx edi
	; Check if we can spawn more fruits
	cmp activeFruitCount, MAX_ON_SCREEN
	jge CannotSpawn ; Already at maximum
	
	mov ecx, MAX_FRUITS
	mov edi, OFFSET fruits
	
FindSlot:
	cmp BYTE PTR [edi].fruit.active, 0
	je FoundSlot
	add edi, SIZEOF fruit
	dec ecx
	jnz FindSlot
	ret ; No slots available
	
FoundSlot:
	; Generate random X position
	mov eax, SCREEN_WIDTH - 10 ; Leave some margin
	call RandomRange
	add eax, 5 ; Start from position 5
	
	; Make it a multiple of 5 for consistency
	mov bl, 5
	div bl
	mul bl
	mov [edi].fruit.x, al
	
	; Start at top of screen
	mov [edi].fruit.y, 0
	
	; Activate fruit
	mov BYTE PTR [edi].fruit.active, 1
	inc activeFruitCount
	
	; Random fruit type (0-4)
	mov eax, 5
	call RandomRange
	mov [edi].fruit.var_type, al
	
	; Set movement speed (2-5)
	mov eax, 5
	call RandomRange
	inc eax ; 2-5
	mov [edi].fruit.speed, al
	
	mov [edi].fruit.counter, 0
	ret
	
CannotSpawn:
	ret
SpawnFruit ENDP

HandleInput PROC
	call ReadKey
	jz NoInput
	cmp ax, 1E00h ; 'A' key
	je MoveLeft
	cmp ax, 2000h ; 'D' key
	je MoveRight
	cmp ax, 4B00h ; left arrow
	je MoveLeft
	cmp ax, 4D00h ; right arrow
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
	jne NextFruitSlice
	
	; Check if fruit is near player's Y position
	mov al, [edi].fruit.y
	cmp al, SCREEN_HEIGHT - 2 ; One above player
	je CheckSlice
	cmp al, SCREEN_HEIGHT - 1 ; At player position
	je CheckSlice
	cmp al, SCREEN_HEIGHT - 3 ; Two above player
	je CheckSlice
	jmp NextFruitSlice
	
CheckSlice:
	; Check if fruit is within ±2 X positions of player
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
	; Also check for multiples of 5 positions
	cmp al, 5
	je HitFruit
	cmp al, -5
	je HitFruit
	jmp NextFruitSlice
	
HitFruit:
	; Show slice effect
	mov dl, [edi].fruit.x
	mov dh, [edi].fruit.y
	call Gotoxy
	mov al, sliceChar
	call WriteChar
	
	; Deactivate fruit
	mov BYTE PTR [edi].fruit.active, 0
	dec activeFruitCount
	inc score
	
	push eax
	mov eax, 100 ; Brief delay to show slice
	call Delay
	pop eax
	
	; Don't reset spawn timer - keep spawning every 2 seconds
	; Continue checking for other fruits to slice
	jmp NextFruitSlice ; Allow slicing multiple fruits with one key press
	
NextFruitSlice:
	add edi, SIZEOF fruit
	dec ecx
	jnz FruitLoop
	
NoInput:
	ret
HandleInput ENDP

UpdateFruits PROC
	; Update spawn timer
	mov eax, spawnTimer
	cmp eax, 0
	jle TimerReady
	sub eax, FRUIT_SPEED ; Subtract frame time
	mov spawnTimer, eax
	jmp TimerUpdated
	
TimerReady:
	; Timer reached 0 - try to spawn a fruit
	call SpawnFruit
	; Reset timer for next spawn
	mov spawnTimer, SPAWN_INTERVAL
	
TimerUpdated:

	; Update fruits movement
	mov ecx, MAX_FRUITS
	mov edi, OFFSET fruits

UpdateLoop:
	cmp BYTE PTR [edi].fruit.active, 1
	jne NextUpdateFruit
	
	; Update counter
	mov al, [edi].fruit.counter
	inc al
	mov [edi].fruit.counter, al
	
	; Check if it's time to move based on speed
	mov bl, [edi].fruit.speed
	cmp bl, 1
	je MoveFast
	cmp bl, 2
	je MoveMedium
	cmp bl, 3
	je MoveSlow
	cmp bl, 4
	je MoveSlower
	cmp bl, 5
	je MoveSlowest
	; Speed = 3 (slowest)

MoveSlowest:
	test al, 7
	jnz NextUpdateFruit
	jmp DoMove
	
MoveSlower:
	mov ah, al
	mov dl, 6
	div dl
	cmp ah, 0
	jne NextUpdateFruit
	jmp DoMove

MoveSlow:
	; Move every 4 frames (slowest)
	test al, 3 ; Check if divisible by 4
	jnz NextUpdateFruit
	jmp DoMove
	
MoveMedium:
	; Move every 2 frames
	test al, 1
	jnz NextUpdateFruit
	jmp DoMove
	
MoveFast:
	; Move every frame
	; (no check needed)
	
DoMove:
	; Move fruit down by 1
	mov al, [edi].fruit.y
	inc al ; Move down by 1 position
	mov [edi].fruit.y, al
	
	; Check if fruit reached bottom
	cmp al, SCREEN_HEIGHT - 1
	jl NextUpdateFruit
	
	; Fruit reached bottom - player missed it
	mov BYTE PTR [edi].fruit.active, 0
	dec activeFruitCount
	dec lives
	
	cmp lives, 0
	jg NextUpdateFruit
	mov gameOver, 1
	
NextUpdateFruit:
	add edi, SIZEOF fruit
	dec ecx
	jnz UpdateLoop
	ret
UpdateFruits ENDP

RenderFrame PROC
	call Clrscr
	
	; Display score and lives
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
	
	; Display active fruit count and timer
	mov dl, 40
	call Gotoxy
	mov al, '['
	call WriteChar
	movzx eax, activeFruitCount
	call WriteDec
	mov al, '/'
	call WriteChar
	mov eax, MAX_ON_SCREEN
	call WriteDec
	mov al, ']'
	call WriteChar
	
	; Display next spawn timer
	mov dl, 50
	call Gotoxy
	mov eax, spawnTimer
	mov ebx, 1000
	xor edx, edx
	div ebx
	inc eax ; Round up
	call WriteDec
	mov al, 's'
	call WriteChar

	; Draw fruits
	mov ecx, MAX_FRUITS
	mov edi, OFFSET fruits
	
DrawFruitLoop:
	cmp BYTE PTR [edi].fruit.active, 1
	jne SkipDraw
	
	mov dl, [edi].fruit.x
	mov dh, [edi].fruit.y
	call Gotoxy
	
	movzx eax, [edi].fruit.var_type
	mov al, fruitChars[eax]
	call WriteChar
	
SkipDraw:
	add edi, SIZEOF fruit
	dec ecx
	jnz DrawFruitLoop
	
	; Draw player
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

