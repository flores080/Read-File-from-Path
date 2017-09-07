.model small
.stack 100h
writest macro _str 		;it make the sequence to print a string
	push ax
	push dx
	mov ah,9
	mov dx,offset _str	;display the string passed as messlab
	int 21h				;dos call
	pop dx
	pop ax
endm
.386					;to use 32bits
.data
prompt1 db "Ingrese la ruta del archivo (*.arq): ",13,10, '$'
prompt2 	db 10,13,'No valid char $'
break 		db 10,13,'$'
filename      db 80 dup(?)
string_len  dw ?

handle     dw   ?
fbuff      db   ?     		  ;file data buffer
oemsg      db   'Cannot open the file$'
rfmsg      db   'Cannot read the file$'
cfmsg      db   'Cannot close the file$'

header db "UNIVERSIDAD DE SAN CARLOS DE GUATEMALA",13,10
       db "FACULTAD DE INGENIERIA",13,10
       db "ESCUELA DE CIENCIAS Y SISTEMAS",13,10
       db "ARQUITECTURA DE COMPUTADORAS Y ENSAMBLADORES 1 A",13,10
       db "SEGUNDO SEMESTRE 2017",13,10
       db "FERNANDO JOSUE FLORES VALDEZ",13,10
       db "201504385",13,10,13,10
       db "          ___         ___         ___         ___     ",13,10
       db "         /\__\       /\  \       /\__\       /\__\    ",13,10
       db "        /::|  |     /::\  \     /::|  |     /:/  /    ",13,10
       db "       /:|:|  |    /:/\:\  \   /:|:|  |    /:/  /     ",13,10
       db "      /:/|:|__|__ /::\~\:\  \ /:/|:|  |__ /:/  /  ___     1. Cargar Archivo ",13,10
       db "     /:/ |::::\__/:/\:\ \:\__/:/ |:| /\__/:/__/  /\__\",13,10
       db "     \/__/~~/:/  \:\~\:\ \/__\/__|:|/:/  \:\  \ /:/  /    2. Salir",13,10
       db "           /:/  / \:\ \:\__\     |:/:/  / \:\  /:/  / ",13,10
       db "          /:/  /   \:\ \/__/     |::/  /   \:\/:/  /  ",13,10
       db "         /:/  /     \:\__\       /:/  /     \::/  /   ",13,10
       db "         \/__/       \/__/       \/__/       \/__/    ",13,10,13,10,13,10,'$'

.code
start:
  mov ax, @data
  mov ds, ax
  mov cx, 3
  m:
  push cx
  call menu
  pop cx
  loop m



;---------------------------------------------
menu proc                   ;display the menu options
  call clear_screen
  call display_header

  ;WAIT FOR ANY KEY.
  call wait_for_key         ;read the char value

  ;COMPARE WITH 1 (ASCII)
  cmp al, 49
  je filerequest

  ;COMPARE WITH 2 (ASCII)
  cmp al, 50
  je exit

  ret
menu endp

filerequest proc
	writest prompt1           ;display prompt1

	lea     si, filename      ;load string into si
	call    readstring        ;get info from keyboard
	mov     string_len, ax	  ;sets the string lenght

	call openfile         	  ;open file (path)
	jc   exit             	  ;jump if error
	call readfile         	  ;read file (path)
	call closefile        	  ;close file (path)
filerequest endp

readstring proc near
    mov     cx, si            ;cx == buffer start address
	read:
		mov ah,01h
		int 21h               ;dos call
		cmp al,13             ;is it return?
		je done               ;yes, we are done reading in characters
		cmp al,37
		je read
		mov [si],al           ;no, move character into buffer
		inc si                ;increase pointer
		jmp read              ;loop back
	done:
		mov ax, '$'
	    mov [si], ax          ;terminate string
	    mov ax, si            ;ax == buffer end address
	    sub ax, cx            ;return characters read in ax
		ret
readstring endp

openfile proc near
         mov  ah,3dh         ;open file with handle function
         lea  dx,filename    ;set up pointer to asciiz string
		 mov  al,0           ;read access
         int  21h            ;dos call
         jc   openerr        ;jump if error
         mov  handle,ax      ;save file handle
         ret
openerr: lea  dx,oemsg       ;set up pointer to error message
         mov  ah,9           ;display string function
         int  21h            ;dos call
         stc                 ;set error flag
         ret
openfile endp

readfile proc near
        mov  ah,3fh         ;read from file function
        mov  bx,handle      ;load file handle
        lea  dx,fbuff       ;set up pointer to data buffer
        mov  cx,1           ;read one byte
        int  21h            ;dos call
        jc   readerr        ;jump if error
        cmp  ax,0           ;were 0 bytes read?
        jz   eoff           ;yes, end of file found
        mov  dl,fbuff       ;no, load file character
        cmp  dl,1ah         ;is it <eof>?
        jz   eoff           ;jump if yes

		jmp case0
;------------------------------------- check if its number, '-' or breakline
case0:	cmp dl, 48
		jne case1
		jmp ok
case1:	cmp dl, 49
		jne case2
		jmp ok
case2:	cmp dl, 50
		jne case3
		jmp ok
case3:	cmp dl, 51
		jne case4
		jmp ok
case4:	cmp dl, 52
		jne case5
		jmp ok
case5:	cmp dl, 53
		jne case6
		jmp ok
case6:	cmp dl, 54
		jne case7
		jmp ok
case7:	cmp dl, 55
		jne case8
		jmp ok
case8:	cmp dl, 56
		jne case9
		jmp ok
case9:	cmp dl, 57
		jne casesig
		jmp ok
casesig:cmp dl, 45
		jne casebrk
		jmp ok
casebrk:cmp dl, 0dh
		jne casebrk1
		jmp ok
casebrk1:cmp dl, 0ah
		jne caseend
		jmp ok
caseend:cmp dl, 59
		jne norecog
		jmp ok
;------------------------------------------------------------------------


ok:	    mov  ah,2           ;display character function
        int  21h            ;dos call
        jmp  readfile       ;and repeat
		ret
readerr: lea  dx,rfmsg       ;set up pointer to error message
         mov  ah,9           ;display string function
         int  21h            ;dos call
         stc                ;set error flag
		 ret
norecog: writest prompt2
		 mov  ah,2           ;display character function
         int  21h            ;dos call
		 writest break
		 jmp filerequest
eoff:    ret
readfile endp

closefile proc near
          mov  ah,3eh        ;close file with handle function
          mov  bx,handle     ;load file handle
          int  21h           ;dos call
          jc   closerr       ;jump if error
          ret
closerr:  lea  dx,cfmsg      ;set up pointer to error message
          mov  ah,9          ;display string function
          int  21h           ;dos call
          stc                ;set error flag
          ret
closefile endp

wait_for_key proc
  mov  ah, 7
  int  21h
  ret
wait_for_key endp

clear_screen proc           ;clear the console
  mov  ah, 0
  mov  al, 3
  int  10H
  ret
clear_screen endp

display_header proc
  mov  dx, offset header
  mov  ah, 9
  int  21h
  ret
display_header endp

exit proc
  mov  ax, 4c00h
  int  21h
exit endp
end start
