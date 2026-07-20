;----------------- padrão de uso de registradores: ------------;
;r0-r3 -> entrada e saida de funçoes                           ;
;r4-r6 -> temporarios                                          ;
;r7 -> posição do cursor                                       ;
;--------------------------------------------------------------;

;-------- TABELA DE CORES -------;
; 0 branco                       ;	
; todo                           ;
;--------------------------------;						

;---- strings --------------------------------------
errstring: string "error string"
teststring : string "hello world"
teststring2 : string "test string"
;-- end strings ------------------------------------

main:

	;exemplo: desenhar linhas ----------------------
    loadn r0, #1
    loadn r1, #10
    call set_cursor_pos ;set cursor to (1,10)

    loadn r0, #'.'
    loadn r1, #38
	loadn r2, #0
    call print_hline ;print horizontal line of 5 '.' with white color


	loadn r0, #39
	loadn r1, #0
	call set_cursor_pos ;set cursor to (39,1)

	loadn r0, #'|'
	loadn r1, #30
	loadn r2, #0
	call print_vline ;print vertical line of 30 '|'  with white color

	loadn r0, #0
	loadn r1, #0
	call set_cursor_pos ;set cursor to (0,0)

	loadn r0, #'|'
	loadn r1, #30
	loadn r2, #0
	call print_vline ;print vertical line of 30 '|'  with white color

	;end exemplo -----------------------------------

	;exemplo: printar strings ----------------------
	loadn r0, #1
    loadn r1, #0
    call set_cursor_pos ;set cursor to (1,0)

	loadn r0, #teststring
	call print_string ;printar 'teststring'

	loadn r0, #1
    loadn r1, #11
    call set_cursor_pos ;set cursor to (1,1)

	loadn r0, #teststring2
	call print_string ;printar 'teststring2'
	;end exemplo -----------------------------------
	

    jmp end

;----------------------------------------------------------------;
;                      funcoes de graficos                       ;
;----------------------------------------------------------------;

;------------------- lembretes aleatorios -----------------------;
;resoluçao da tela: (40 largura(x) x 30 altura(y))               ;
;origem: canto superior esquerdo                                 ;
;x aumenta pra direita, y aumenta pra baixo                      ;
;----------------------------------------------------------------;

;observaçao: todas as funçoes de graficos tomam a posiçao atual do cursor,
;que sempre está em r7, como a origem pra printar

;setar posiçao do cursor
;entrada-> (r0,r1) como posicao (x,y)
;saida-> (r7) recebe o valor equivalente
set_cursor_pos:
    loadn r4, #40
    mul r7, r1, r4
    add r7, r7, r0
    rts

;getar posiçao do cursor
;entrada-> nenhuma
;efeito-> (r0,r1) recebe o valor (x,y) de r7
get_cursor_pos:
    loadn r4, #40
    div r0, r7, r4
    mod r1, r7, r4
    rts

;printa linha horizontal
;entradas:
;caracter-> r0
;comprimento-> r1 (indo pra direita)
;cor-> r2
print_hline: 
    add r1, r7, r1
	add r0, r0, r2

    hline_loop:
        outchar r0, r7
        inc r7
        cmp r7, r1
        jle hline_loop

    rts

;printa linha vertical
;entradas:
;caracter-> r0
;comprimento-> r1 (indo pra baixo)
;cor-> r2
print_vline:
	add r0, r0, r2 
	loadn r4, #0
	loadn r5, #40
	
	vline_loop:
		outchar r0,r7
		add r7, r7, r5
		inc r4
		cmp r4, r1
		jle vline_loop
	rts
;printa retangulo
;entradas:
;r0


;printa string
;entrada:
;r0-> end. da string

print_string:

    loadn r4, #'\0';

	print_loop:
    	loadi r5, r0
    	cmp r5, r4          
    	jeq print_end ;parar se chegou no \0
   
    	outchar r5, r7; printa 1 char

    	inc r7; incrementa o cursor
    	inc r0; incrementa o endereco na string
    	jmp print_loop

	print_end:
    rts

end:
    halt