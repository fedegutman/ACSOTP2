; /** defines bool y puntero **/
%define NULL 0
%define TRUE 1
%define FALSE 0

section .data

section .text

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

; FUNCIONES auxiliares que pueden llegar a necesitar:
extern malloc
extern free
extern str_concat

string_proc_list_create_asm:
    push rbp
    mov rbp, rsp ; puntero de la pila

    mov edi, 16 ; bytes necesarios para malloc
    call malloc ;

    cmp rax, NULL
    je .return_null ; if rax == NULL (malloc falla) return null

    ; inicializo la lista (first y last)
    mov qword [rax], NULL
    mov qword [rax + 8], NULL

    mov rsp, rbp
    pop rbp
    ret

.return_null:
    mov rax, NULL
    mov rsp, rbp
    pop rbp
    ret

string_proc_node_create_asm:
    push rbp
    mov rbp, rsp

    mov edi, 32 ; tamaño del nodo
    call malloc

    cmp rax, NULL
    je .return_null

    ; inicializo el nodo
    mov qword [rax], NULL ; next = NULL
    mov qword [rax + 8], NULL ; previous = NULL
    mov byte [rax + 16], 0 ; type = 0
    mov qword [rax + 24], NULL ; hash = NULL

    mov rsp, rbp
    pop rbp
    ret

.return_null:
    mov rax, NULL
    mov rsp, rbp
    pop rbp
    ret

string_proc_list_add_node_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    mov rbx, rdi
    test rbx, rbx
    jz .return_null

    movzx r12, sil
    mov rsi, rdx
    movzx edi, r12b

    call string_proc_node_create_asm
    cmp rax, NULL
    je .return_null

    cmp qword [rbx], 0
    jne .not_empty

    mov [rbx], rax
    mov [rbx + 8], rax
    jmp .end

.not_empty:
    mov rcx, [rbx + 8]
    mov [rax + 8], rcx
    mov [rcx], rax
    mov [rbx + 8], rax

.end:
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

.return_null:
    mov rax, NULL
    jmp .end

string_proc_list_concat_asm:
    push rbp
    mov rbp, rsp

    ; Validate input parameters (list and hash)
    test rdi, rdi        ; Check if list (rdi) is NULL
    jz .return_null
    test rsi, rsi        ; Check if hash (rsi) is NULL
    jz .return_null

    ; Allocate memory for the initial result (strlen(hash) + 1)
    mov rdx, rsi         ; Pass hash to strlen
    call strlen_asm
    add rax, 1           ; Add 1 for the null terminator
    mov edi, rax         ; Pass size to malloc
    call malloc          ; Allocate memory for result
    test rax, rax        ; Check if malloc failed
    jz .return_null
    mov rbx, rax         ; Save result pointer in rbx

    ; Copy hash into result
    mov rdi, rbx         ; Destination (result)
    mov rsi, rsi         ; Source (hash)
    call strcpy_asm

    ; Iterate through the list
    mov rcx, [rdi]       ; rcx = list->first
    
.loop_start:
    test rcx, rcx        ; Check if current node is NULL
    jz .end_concat

    ; Check if current->type == type
    movzx r8b, byte [rcx + 16] ; Load current->type into r8b
    cmp r8b, dil          ; Compare type (r8b) with input type (dil)
    jne .next_node        ; Skip if types do not match

    ; Check if current->hash != NULL
    mov r8, [rcx + 24]    ; Load current->hash into r8
    test r8, r8           ; Check if hash is NULL
    jz .next_node         ; Skip if NULL

    ; Concatenate result with current->hash
    mov rsi, r8           ; Pass current->hash as second argument
    mov rdi, rbx          ; Pass result as first argument
    call str_concat       ; Call str_concat(result, current->hash)
    test rax, rax         ; Check if str_concat failed
    jz .free_and_return_null
    mov rbx, rax          ; Update result pointer

.next_node:
    mov rcx, [rcx]        ; Move to the next node (current = current->next)
    jmp .loop_start       ; Repeat loop

.end_concat:
    mov rax, rbx          ; Return the result
    pop rbp
    ret

.free_and_return_null:
    mov rdi, rbx          ; Free the allocated result
    call free
.return_null:
    xor rax, rax          ; Return NULL
    pop rbp
    ret

strlen_asm:
    push rbp
    mov rbp, rsp

    mov rax, rdi        ; rdi contains the pointer to the string
    xor rcx, rcx        ; rcx will count the length

strlen_loop:
    cmp byte [rax], 0   ; Check if the current byte is null
    je strlen_done      ; If null, we're done
    inc rax             ; Move to the next character
    inc rcx             ; Increment the length counter
    jmp strlen_loop     ; Repeat the loop

strlen_done:
    mov rax, rcx        ; Return the length in rax
    pop rbp
    ret

strcpy_asm:
    push rbp
    mov rbp, rsp

    mov rax, rdi        ; Save the destination pointer to return it

strcpy_loop:
    mov bl, byte [rsi]  ; Load the current byte from the source
    mov byte [rdi], bl  ; Copy the byte to the destination
    test bl, bl         ; Check if the byte is null
    je strcpy_done      ; If null, we're done
    inc rsi             ; Move to the next byte in the source
    inc rdi             ; Move to the next byte in the destination
    jmp strcpy_loop     ; Repeat the loop

strcpy_done:
    pop rbp
    ret

