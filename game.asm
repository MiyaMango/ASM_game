;----------------- padrão de uso de registradores: ------------;
;r0-r3 -> entrada e saida de funçoes                           ;
;r4-r6 -> temporarios                                          ;
;r7 -> posição do personagem                                   ;
;--------------------------------------------------------------;

;-------- TABELA DE CORES -------;
; 0 branco                       ;	
; 64512 azul                     ;
; 58112 verde                    ;
; 7936 vermelho                  ;
; todo: mais cores               ;
;--------------------------------;						

;---- strings --------------------------------------
errstring: string "error string"
teststring : string "hello world"
teststring2 : string "test string"
;---------------------------------------------------

;---- sprites --------------------------------------
player_sprite: string #"o+^"
blank_sprite: string " "
;---------------------------------------------------

;---- physics variables ----------------------------
; This architecture cannot represent negative numbers, so every "signed"
; quantity is split into a direction flag (0/1) and an unsigned magnitude.
; X: dir 0 = right, 1 = left.  Y: dir 0 = down, 1 = up.
vel_x_dir: string "\0"   
vel_x_mag: string "\0"   
vel_y_dir: string "\0"   
vel_y_mag: string "\0"   
accum_x_dir: string "\0"    ; fractional-tile progress toward the next X step
accum_x_mag: string "\0"    
accum_y_dir: string "\0"    ; fractional-tile progress toward the next Y step
accum_y_mag: string "\0"    
dirty: string "\0"          ; 1 if the player actually moved this tick (avoids
                             ; needless erase+redraw flicker when standing still)
;---------------------------------------------------
; THRESHOLD = 10 units == 1 tile. vel_x_mag/vel_y_mag are capped at
; THRESHOLD, so an accumulator can never gain more than THRESHOLD in a
; single tick, which guarantees at most 1 tile of movement per axis per
; tick.
;---------------------------------------------------

;---- map data --------------------------------------
; '0' = empty, '1' = wall
map_data:
    string "1111111111111111111111111111111111111111" ; 0
    string "1000000000000000000000000000000000000001" ; 1
    string "1000000000000000011100000000000000000001" ; 2
    string "1000000000000000011100000000000000000001" ; 3
    string "1000000000000000011100000000000000000001" ; 4
    string "1000000000000000011100000000000000000001" ; 5
    string "1000000000000000000000000000000000000001" ; 6
    string "1000000000000000000000000000000000000001" ; 7
    string "1000000000000000011100000000000000000001" ; 8
    string "1000000000000000011100000000000000000001" ; 9
    string "1000000000000000011100000000000000000001" ; 10
    string "1000000000000000011100000000000000000001" ; 11
    string "1000000000000000011100000000000000000001" ; 12
    string "1000000000000000000000000000000000000001" ; 13
    string "1000000000000000000000000000000000000001" ; 14
    string "1000000000000000000000000000000000000001" ; 15
    string "1000000000000000011100000000000000000001" ; 16
    string "1000000000000000011100000000000000000001" ; 17
    string "1000000000000000011100000000000000000001" ; 18
    string "1000000000000000011100000000000000000001" ; 19
    string "1000000000000000000000000000000000000001" ; 20
    string "1000000000000000000000000000000000000001" ; 21
    string "1000000000000000000000000000000000000001" ; 22
    string "1000000000000000000000000000000000000001" ; 23
    string "1000000000000000000000000000000000000001" ; 24
    string "1000000000000000000000000000000000000001" ; 25
    string "1000000000000000000000000000000000000001" ; 26
    string "1000000000000000011100000000000000000001" ; 27
    string "1000000000000000011100000000000000000001" ; 28
    string "1111111111111111111111111111111111111111" ; 29
;---------------------------------------------------

main:

	; --- 1. SETUP ---
	call draw_map

    loadn r0, #5           ;set initial player coords
    loadn r1, #5           
    call set_player_pos    
    call draw_player       ; initial draw so the player is visible before tick 1

	game_loop:

	; --- 2. PHYSICS TICK ---
    call apply_velocity     ; moves player based on current momentum

    ; --- 3. DRAW (only if the player actually moved this tick) ---
    loadn r0, #dirty        
    loadi r1, r0             
    loadn r0, #0             
    cmp r1, r0               
    jeq skip_draw            
    call draw_player        ; draw the character at the current r7 position

skip_draw:
    ; --- 4. INPUT ---
    call handle_input       ; wait for and process player input

    ; --- 5. REPEAT ---
    jmp game_loop           ; loop back to draw and wait for input again

;----------------------------------------------------------------;
;                      funcoes de graficos                       ;
;----------------------------------------------------------------;

;------------------- lembretes aleatorios -----------------------;
;resoluçao da tela: (40 largura(x) x 30 altura(y))               ;
;origem: canto superior esquerdo                                 ;
;x aumenta pra direita, y aumenta pra baixo                      ;
;----------------------------------------------------------------;

;desenha o mapa na tela -----------------------------------------;
draw_map:
    push r0                 
    push r1                 
    push r2                 
    push r3                 
    push r4                 
    push r5                 
    push r6                 

    loadn r0, #map_data     ; r0 = memory pointer for the map dat
    loadn r1, #0            ; r1 = screen position (starts at top-left, index 0
    loadn r2, #1200         ; r2 = total tiles on a 40x30 screen[cite: 1, 2]
    loadn r3, #'\0'         ; r3 = null terminator to check for[cite: 1, 2]
    loadn r4, #'1'          ; r4 = wall character in our map dat
    loadn r5, #'#'          ; r5 = visual character to draw for wall

draw_map_loop:
    cmp r1, r2              ; check if we have drawn 1200 tile
    jeq draw_map_end        ; if equal, we are don

    loadi r6, r0            ; read the current character from map dat
    
    ; check for null terminator and skip if found
    cmp r6, r3              
    jeq skip_null           

    ; check if it is a wall ('1')
    cmp r6, r4              
    jeq draw_wall           
    
    ; if it is not a wall (it's '0'), draw an empty space
    loadn r6, #' '          
    outchar r6, r1          ; print space at current screen positio
    jmp next_tile           

draw_wall:
    outchar r5, r1          ; print '#' at current screen positio

next_tile:
    inc r1                  ; advance to the next screen positio

skip_null:
    inc r0                  ; advance the memory pointe
    jmp draw_map_loop       ; repea

draw_map_end:
    pop r6                  
    pop r5                  
    pop r4                  
    pop r3                  
    pop r2                  
    pop r1                  
    pop r0                  
    rts                     
;----------------------------------------------------------------;

;draws player in position (r7)
draw_player:
    push r0                  
    push r1                  
    push r2                  
    push r4                  

    loadn r0, #player_sprite ; r0 points to the first character
    loadn r2, #40            ; load screen width into r2
    mov r4, r7               ; copy player's position (r7) into r4 so we don't alter r7

    ; --- Draw Top Character ---
    loadi r1, r0             ; pull first char from memory into r1
    outchar r1, r4           ; draw at current position

    ; --- Draw Middle Character ---
    inc r0                   ; move memory pointer to 2nd char
    add r4, r4, r2           ; move temp position down 1 row by adding 40
    loadi r1, r0             ; pull second char from memory into r1
    outchar r1, r4           ; draw

    ; --- Draw Bottom Character ---
    inc r0                   ; move memory pointer to 3rd char
    add r4, r4, r2           ; move temp position down another row
    loadi r1, r0             ; pull third char from memory into r1
    outchar r1, r4           ; draw 

    pop r4                   
    pop r2                   
    pop r1                   
    pop r0                   
    rts                      

;erases player in position (r7)
erase_player:
    push r0                  
    push r1                  
    push r2                  
    push r4                  

    loadn r0, #blank_sprite  ; r0 now points to the blank space
    loadn r2, #40            
    mov r4, r7               ; start erasing at the player's position

    ; --- Erase Top ---
    loadi r1, r0             
    outchar r1, r4           

    ; --- Erase Middle ---
    add r4, r4, r2           
    outchar r1, r4           

    ; --- Erase Bottom ---
    add r4, r4, r2           
    outchar r1, r4          

    pop r4                   
    pop r2                   
    pop r1                   
    pop r0                   
    rts                      

;printa string
 em (r0) na posicao (r1)
print_string:

    loadn r4, #'\0';

	print_loop:
    	loadi r5, r0
    	cmp r5, r4          
    	jeq print_end ;parar se chegou no \0
   
    	outchar r5, r1; printa 1 char

    	inc r1; incrementa o cursor
    	inc r0; incrementa o endereco na string
    	jmp print_loop

	print_end:
    rts

;----------------------------------------------------------------;
;                      funcoes de movimento                      ;
;----------------------------------------------------------------;

;setar posiçao do player
;entrada-> (r0,r1) como posicao (x,y)
;saida-> (r7) recebe o valor equivalente
set_player_pos:
    loadn r4, #40
    mul r7, r1, r4
    add r7, r7, r0
    rts

;getar posiçao do player
;entrada-> nenhuma
;efeito-> (r0,r1) recebe o valor (x,y) de r7
get_player_pos:
    loadn r4, #40
    div r0, r7, r4
    mod r1, r7, r4
    rts

;le WASD e chama a funcao de movimento equivalente
handle_input:
    push r4                 
    push r5                 

    inchar r4               ; read keyboard input into r4
    
    ; check if 'w' (up)
    loadn r5, #'w'          ; load 'w' into r5
    cmp r4, r5              ; compare input with 'w'
    ceq accel_up            ; call accel_up if equal

    ; check if 'a' (left)
    loadn r5, #'a'
    cmp r4, r5
    ceq accel_left

    ; check if 'd' (right)
    loadn r5, #'d'
    cmp r4, r5
    ceq accel_right

    pop r5                  ; restore r5 state
    pop r4                  ; restore r4 state
    rts                     

;----------------------------------------------------------------;

;----------------------------------------------------------------;
;                      funcoes de aceleracao                     ;
;----------------------------------------------------------------;
accel_up: ;(this is jumping)
    push r0                 
    push r1                 
    push r2                 
    push r3                 
    push r4                 

    ; --- 1. Check if standing on a floor ---
    ; Calculate screen position for the tile right below the player (r7 + 120)
    loadn r4, #120          
    add r6, r7, r4          ; r6 = target screen position below playe

    ; Convert screen index in r6 to memory index (using stride of 41)
    loadn r4, #40           ;[cite: 1, 2]
    div r2, r6, r4          ; r2 = 
    mod r3, r6, r4          ; r3 = 
    loadn r4, #41           ; memory row lengt
    mul r2, r2, r4          ; Y * 4
    add r2, r2, r3          ; exact memory offse

    loadn r0, #map_data     
    add r0, r0, r2          ; map address + offse
    loadi r1, r0            ; load tile from memor

    loadn r4, #'0'          ; '0' means empty space (not a floor
    cmp r1, r4              ; check if the tile below is empty spac
    jeq cancel_jump         ; if it is '0' (air), you cannot jump

    ; --- 2. Apply Jump Velocity (upward impulse of THRESHOLD units) ---
    loadn r4, #vel_y_dir     
    loadi r0, r4             ; r0 = current dir
    loadn r4, #vel_y_mag     
    loadi r1, r4             ; r1 = current mag

    loadn r2, #1             ; delta dir = 1 (up)
    loadn r3, #10            ; delta mag = THRESHOLD (full jump strength)
    call signed_add          ; r0,r1 = new dir,mag
    call clamp_mag10         ; keep mag <= THRESHOLD (tunneling guard)

    loadn r4, #vel_y_dir     
    storei r4, r0            
    loadn r4, #vel_y_mag     
    storei r4, r1            

cancel_jump:
    pop r4                  
    pop r3                  
    pop r2                  
    pop r1                  
    pop r0                  
    rts                     

accel_left:
    push r0               
    push r1               
    push r2               
    push r3               
    push r4               

    loadn r4, #vel_x_dir  
    loadi r0, r4           ; r0 = current dir
    loadn r4, #vel_x_mag  
    loadi r1, r4           ; r1 = current mag

    loadn r2, #1           ; delta dir = 1 (left)
    loadn r3, #2          ; delta mag = 1
    call signed_add        ; r0,r1 = new dir,mag
    call clamp_mag10       ; keep mag <= THRESHOLD

    loadn r4, #vel_x_dir  
    storei r4, r0          
    loadn r4, #vel_x_mag  
    storei r4, r1          

    pop r4                 
    pop r3                
    pop r2                
    pop r1                
    pop r0                 
    rts                   

accel_right:
    push r0               
    push r1               
    push r2               
    push r3               
    push r4               

    loadn r4, #vel_x_dir  
    loadi r0, r4           ; r0 = current dir
    loadn r4, #vel_x_mag  
    loadi r1, r4           ; r1 = current mag

    loadn r2, #0           ; delta dir = 0 (right)
    loadn r3, #2           ; delta mag = 1
    call signed_add        ; r0,r1 = new dir,mag
    call clamp_mag10       ; keep mag <= THRESHOLD

    loadn r4, #vel_x_dir  
    storei r4, r0          
    loadn r4, #vel_x_mag  
    storei r4, r1          

    pop r4                
    pop r3                
    pop r2                
    pop r1                
    pop r0                
    rts                   

;----------------------------------------------------------------;

; signed_add: adds two (direction, magnitude) pairs without ever needing
; a negative literal. Same direction -> magnitudes add. Opposite
; direction -> subtract the smaller magnitude from the larger, and the
; result takes on whichever direction "won".
; entrada: r0=dir_a, r1=mag_a, r2=dir_b, r3=mag_b
; saida:   r0=dir_result, r1=mag_result
signed_add:
    push r4                  

    cmp r0, r2               
    jeq sa_same_dir          

    ; --- opposite directions: result = larger magnitude minus smaller ---
    cmp r1, r3               
    jeq sa_cancel            ; equal magnitudes -> cancels out to zero
    jgr sa_a_bigger          ; mag_a > mag_b

    ; mag_b > mag_a
    mov r4, r1               
    sub r1, r3, r4           ; mag_result = mag_b - mag_a
    mov r0, r2               ; dir_result = dir_b
    jmp sa_end

sa_a_bigger:
    sub r1, r1, r3           ; mag_result = mag_a - mag_b (dir_result stays dir_a)
    jmp sa_end

sa_cancel:
    loadn r1, #0             ; mag_result = 0 (direction doesn't matter at rest)
    jmp sa_end

sa_same_dir:
    add r1, r1, r3           ; mag_result = mag_a + mag_b (dir_result stays dir_a)

sa_end:
    pop r4                   
    rts                      

; clamp_mag10: caps a magnitude at THRESHOLD (10) -- the tunneling guard
; entrada/saida: r1 = magnitude
clamp_mag10:
    push r4                  
    loadn r4, #10            
    cmp r1, r4               
    jgr clamp_mag10_do       
    jmp clamp_mag10_end

clamp_mag10_do:
    mov r1, r4               

clamp_mag10_end:
    pop r4                   
    rts                      

; mark_dirty: called right before the player's position actually changes.
; Erases the sprite from its current spot (only once per tick, even if
; both axes move) and sets the dirty flag so game_loop knows to redraw.
mark_dirty:
    push r0                  
    push r4                  

    loadn r4, #dirty         
    loadi r0, r4             
    loadn r4, #0             
    cmp r0, r4               
    jne mark_dirty_end       ; already dirty this tick -- already erased, skip

    call erase_player        

    loadn r4, #dirty         
    loadn r0, #1             
    storei r4, r0            

mark_dirty_end:
    pop r4                   
    pop r0                   
    rts                      

;----------------------------------------------------------------;

; apply_friction: slows vel_x back toward 0, but only when grounded
; (reuses the same "check tile below" trick as accel_up's jump check)
apply_friction:
    push r0                 
    push r1                 
    push r2                 
    push r3                 
    push r4                 
    push r6                 

    ; --- 1. Check if standing on a floor (tile directly below player) ---
    loadn r4, #120          
    add r6, r7, r4          ; r6 = screen position below player

    loadn r4, #40           
    div r2, r6, r4          ; r2 = Y
    mod r3, r6, r4          ; r3 = X

    loadn r4, #41           ; row length in memory (40 chars + '\0')
    mul r2, r2, r4          
    add r2, r2, r3          ; exact memory offset

    loadn r0, #map_data     
    add r0, r0, r2          
    loadi r1, r0            ; tile below the player

    loadn r4, #'0'          
    cmp r1, r4              
    jeq skip_friction       ; tile below is air, not on the ground, no friction

    ; --- 2. Decay vel_x_mag by 1 toward 0 (direction is irrelevant at 0) ---
    loadn r0, #vel_x_mag     
    loadi r1, r0             ; r1 = current mag

    loadn r4, #0             
    cmp r1, r4               
    jeq skip_friction        ; already at rest

    dec r1                   
    storei r0, r1            

skip_friction:
    pop r6                  
    pop r4                  
    pop r3                  
    pop r2                  
    pop r1                  
    pop r0                  
    rts                     

;----------------------------------------------------------------;

; checar colisao
; entrada: r6 -> posicao alvo
; saida: r5 -> 0 se livre, 1 se houver colisao
check_collision:
    push r0                 
    push r1                 
    push r2                 
    push r3                 
    push r4                 

    loadn r5, #0            ; default: assume no collisio
    loadn r0, #map_data     ; load the base address of the ma

    ; --- Convert Screen Index to Memory Index ---
    ; r6 is the screen index (stride of 40). We map it to memory (stride of 41).
    loadn r4, #40           ;[cite: 1, 2]
    div r2, r6, r4          ; r2 = Y (r6 / 40
    mod r3, r6, r4          ; r3 = X (r6 % 40

    loadn r4, #41           ; row length in memory (40 chars + '\0')
    mul r2, r2, r4          ; r2 = Y * 4
    add r2, r2, r3          ; r2 = (Y * 41) + X (exact memory offset

    add r1, r0, r2          ; r1 = map_data address + exact memory offse
    loadn r4, #'0'          ; we consider '0' as our empty space til

    ; --- Check Top Character ---
    loadi r2, r1            ; pull the map tile from memor
    cmp r2, r4              ; compare the tile to '0
    jne collision_found     ; if it is NOT '0', we hit a wall typ

    ; --- Check Middle Character ---
    loadn r3, #41           ; load memory stride of 41
    add r1, r1, r3          ; advance map address by exactly 1 row in memor
    loadi r2, r1            ; pull the middle til
    cmp r2, r4              
    jne collision_found     

    ; --- Check Bottom Character ---
    add r1, r1, r3          ; advance map address by another row in memor
    loadi r2, r1            ; pull the bottom til
    cmp r2, r4              
    jne collision_found     

    jmp end_collision       ; if we reach here, all 3 tiles are empty space ('0'

collision_found:
    loadn r5, #1            ; set the output flag to 1 (collision

end_collision:
    pop r4                  
    pop r3                  
    pop r2                  
    pop r1                  
    pop r0                  
    rts                      
      
;----------------------------------------------------------------;

;----------------------------------------------------------------;
; apply_velocity: handles velocity, gravity, speed caps, and collisions
;----------------------------------------------------------------;
;----------------------------------------------------------------;
; apply_velocity: handles axis-independent velocity and collisions
;----------------------------------------------------------------;
apply_velocity:
    push r0                 
    push r1                 
    push r2                 
    push r3                 
    push r4                 
    push r5                 
    push r6                 

    ; Reset the dirty flag for this tick -- mark_dirty will set it back to
    ; 1 the moment (if ever) the player's position actually changes below.
    loadn r0, #dirty         
    loadn r1, #0             
    storei r0, r1            

    ; --- 1. Apply Gravity to Vertical Velocity (capped at THRESHOLD) ---
    loadn r4, #vel_y_dir     
    loadi r0, r4             ; r0 = current dir
    loadn r4, #vel_y_mag     
    loadi r1, r4             ; r1 = current mag

    loadn r2, #0             ; delta dir = 0 (down)
    loadn r3, #1             ; delta mag = 1 (gravity strength per tick)
    call signed_add          ; r0,r1 = new dir,mag
    call clamp_mag10         ; keep mag <= THRESHOLD

    loadn r4, #vel_y_dir     
    storei r4, r0            
    loadn r4, #vel_y_mag     
    storei r4, r1            

    ; --- 2. Check if both velocities are at rest ---
    loadn r4, #vel_x_mag     
    loadi r1, r4              ; r1 = vel_x_mag
    loadn r4, #0             
    cmp r1, r4               
    jne start_movement       

    loadn r4, #vel_y_mag     
    loadi r2, r4              ; r2 = vel_y_mag
    loadn r4, #0             
    cmp r2, r4               
    jne start_movement       

    ; both velocities are 0 -- check the tile directly below the character
    loadn r4, #120          
    add r6, r7, r4          ; r6 = screen position below player

    loadn r4, #40           
    div r3, r6, r4          ; r3 = Y
    mod r0, r6, r4          ; r0 = X

    loadn r4, #41           ; row length in memory (40 chars + '\0')
    mul r3, r3, r4          
    add r3, r3, r0          ; r3 = exact memory offset

    loadn r0, #map_data     
    add r0, r0, r3          ; r0 = address of tile below
    loadi r3, r0            ; r3 = tile character below the player

    loadn r4, #'0'          
    cmp r3, r4              
    jeq start_movement      ; tile below is air -- not grounded, keep processing

    jmp skip_velocity       ; grounded with 0 velocity -- truly nothing to do

start_movement:
    ; ==========================================
    ; HORIZONTAL MOVEMENT (X Axis)
    ; accum_x += vel_x (both are dir+magnitude pairs). Only when the
    ; magnitude crosses THRESHOLD does the player actually step 1 tile,
    ; in whichever direction the accumulator is currently pointing.
    ; Since vel_x_mag is capped at THRESHOLD, the accumulator can never
    ; gain more than THRESHOLD in one tick, so it can cross the boundary
    ; at most once -- guaranteeing at most 1 tile/tick, no matter how
    ; "fast" the character is going.
    ; ==========================================
    loadn r4, #accum_x_dir   
    loadi r0, r4             ; r0 = accum_x dir
    loadn r4, #accum_x_mag   
    loadi r1, r4             ; r1 = accum_x mag

    loadn r4, #vel_x_dir     
    loadi r2, r4             ; r2 = vel_x dir
    loadn r4, #vel_x_mag     
    loadi r3, r4             ; r3 = vel_x mag

    call signed_add          ; r0,r1 = new accum_x dir,mag

    loadn r4, #accum_x_dir   
    storei r4, r0            
    loadn r4, #accum_x_mag   
    storei r4, r1            ; save (may be overwritten again below)

    loadn r4, #9             ; THRESHOLD - 1
    cmp r1, r4               
    jgr accum_x_cross        ; accum_x_mag > 9  ==  >= THRESHOLD -> step 1 tile

    jmp test_vertical        ; below threshold, no horizontal step this tick

accum_x_cross:
    ; r0 holds accum_x dir (0 = right, 1 = left) -- step that way
    mov r6, r7               
    loadn r4, #0              
    cmp r0, r4                
    jeq accum_x_move_right    

    dec r6                    ; dir == left
    jmp accum_x_check_collision

accum_x_move_right:
    inc r6                    

accum_x_check_collision:
    call check_collision      
    loadn r4, #1               
    cmp r5, r4                 
    jeq hit_horizontal_wall    

    call mark_dirty              ; erase old sprite + flag this tick as dirty
    mov r7, r6                  ; step succeeds
    loadn r4, #10                ; THRESHOLD
    sub r1, r1, r4                ; consume the threshold, keep the remainder
    loadn r4, #accum_x_mag        
    storei r4, r1                  
    jmp test_vertical

hit_horizontal_wall:
    ; Blocked: kill horizontal momentum AND its accumulator, so we don't
    ; keep "pressing" into the wall and lurch forward the instant it opens.
    loadn r4, #0               
    loadn r0, #vel_x_mag        
    storei r0, r4                
    loadn r0, #accum_x_mag       
    storei r0, r4                 

test_vertical:
    ; ==========================================
    ; VERTICAL MOVEMENT (Y Axis) -- same accumulator/threshold scheme
    ; ==========================================
    loadn r4, #accum_y_dir     
    loadi r0, r4                ; r0 = accum_y dir
    loadn r4, #accum_y_mag      
    loadi r1, r4                 ; r1 = accum_y mag

    loadn r4, #vel_y_dir         
    loadi r2, r4                  ; r2 = vel_y dir
    loadn r4, #vel_y_mag          
    loadi r3, r4                   ; r3 = vel_y mag

    call signed_add                ; r0,r1 = new accum_y dir,mag

    loadn r4, #accum_y_dir          
    storei r4, r0                    
    loadn r4, #accum_y_mag            
    storei r4, r1                      

    loadn r4, #9                       ; THRESHOLD - 1
    cmp r1, r4                          
    jgr accum_y_cross                   ; accum_y_mag > 9  ==  >= THRESHOLD -> step 1 tile

    jmp skip_velocity                    ; below threshold, no vertical step this tick

accum_y_cross:
    ; r0 holds accum_y dir (0 = down, 1 = up) -- step that way
    mov r6, r7                            
    loadn r4, #0                           
    cmp r0, r4                              
    jeq accum_y_move_down                    

    loadn r4, #40                             
    sub r6, r6, r4                             ; dir == up
    jmp accum_y_check_collision

accum_y_move_down:
    loadn r4, #40                               
    add r6, r6, r4                                

accum_y_check_collision:
    call check_collision                          
    loadn r4, #1                                   
    cmp r5, r4                                      
    jeq hit_vertical_wall                            

    call mark_dirty                                       ; erase old sprite + flag this tick as dirty
    mov r7, r6                                        ; step succeeds
    loadn r4, #10                                       ; THRESHOLD
    sub r1, r1, r4                                        ; consume the threshold, keep remainder
    loadn r4, #accum_y_mag                                 
    storei r4, r1                                           
    jmp skip_velocity

hit_vertical_wall:
    ; Blocked: kill vertical momentum AND its accumulator (same reasoning
    ; as the horizontal wall case above).
    loadn r4, #0                    
    loadn r0, #vel_y_mag              
    storei r0, r4                      
    loadn r0, #accum_y_mag               
    storei r0, r4                         

skip_velocity:
    ; Friction decays vel_x AFTER this tick's movement has already used it,
    ; so it slows you down for next tick instead of erasing a fresh tap
    ; before it ever gets a chance to move you.
    call apply_friction     

    pop r6                  
    pop r5                  
    pop r4                  
    pop r3                  
    pop r2                  
    pop r1                  
    pop r0                  
    rts
;----------------------------------------------------------------;
;                         outras funcoes                         ;
;----------------------------------------------------------------;

end:
    halt