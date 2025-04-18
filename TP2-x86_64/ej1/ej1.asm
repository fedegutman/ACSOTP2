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

    mov rdi, 16 ; bytes necesarios para malloc
    call malloc

    cmp rax, NULL
    je .return_null ; if rax == NULL (malloc falla) return null

    ; inicializo la lista (first y last)
    mov qword [rax], NULL
    mov qword [rax + 8], NULL

    pop rbp
    ret

.return_null:
    xor rax, rax     ; hago xor consigo mismo para limpiarlo
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
    mov byte [rax + 16], dil ; type = valor d dil
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
    
    call string_proc_node_create_asm
    cmp rax, NULL
    je .return_null

    cmp qword [rbx], NULL
    jne .not_empty

    mov [rbx], rax
    mov [rbx + 8], rax
    jmp .end

.not_empty:
    mov rcx, [rbx + 8] ; rcx = list->last
    mov [rax + 8], rcx ; new_node->previous = list->last
    mov [rcx], rax ; list->last->next = new_node
    mov [rbx + 8], rax ; list->last = rax (new node)

.end:
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

.return_null:
    xor rax, rax
    jmp .end


string_proc_list_concat_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; rdi = pointer to the list
    ; rsi = type
    ; rdx = pointer to hash

    ; Check for NULL list or NULL hash
    test rdi, rdi              ; check if list is NULL
    jz .return_null
    test rdx, rdx              ; check if hash is NULL
    jz .return_null

    ; Allocate memory for the result string (strlen(hash) + 1)
    ; rdx = pointer to hash (input string)
    call strlen_asm            ; call strlen to get the length of the hash
    mov rdi, rax               ; rdi = length of the hash (rax from strlen)
    inc rdi                    ; +1 for null terminator
    call malloc                ; allocate memory for result

    test rax, rax              ; check if malloc failed
    jz .return_null

    ; Copy hash into result string
    mov rdi, rax               ; rdi = pointer to result
    mov rsi, rdx               ; rsi = pointer to hash
    call strcpy_asm            ; copy hash to result

    ; Iterate through the list and concatenate matching nodes
    mov rbx, [rdi]             ; rbx = list->first (start with first node)
    test rbx, rbx              ; check if list is empty
    jz .end_concat

    ; Loop through each node in the list
    .loop:
        ; Check if node type matches
        movzx r12, byte [rbx + 16]  ; r12 = current node->type
        cmp r12, rsi                ; compare with the passed type
        jne .next_node

        ; Check if node hash is not NULL
        mov r13, [rbx + 24]         ; r13 = current node->hash
        test r13, r13               ; check if hash is NULL
        jz .next_node

        ; Concatenate current node's hash to result
        mov rdi, rax                ; rdi = result (current string)
        mov rsi, r13                ; rsi = current node->hash
        call str_concat_asm         ; concatenate result with node hash
        test rax, rax               ; check if str_concat failed
        jz .return_null
        mov rax, rdi                ; update result with the new concatenated string

        .next_node:
        mov rbx, [rbx]              ; move to the next node
        test rbx, rbx               ; check if we reached the end
        jnz .loop

    .end_concat:
        ; Return result
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
        mov rsp, rbp
        pop rbp
        ret

.return_null:
    xor rax, rax                ; return NULL (rax = 0)
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

strlen_asm:
    ; rdi = pointer to the string
    xor rax, rax            ; clear rax (to store the length)
    
.strlen_loop:
    mov al, byte [rdi]      ; load the current byte of the string into al
    test al, al             ; check if it's the null-terminator (0)
    jz .done                ; if it is null, we are done
    inc rdi                 ; move to the next byte
    inc rax                 ; increment the length
    jmp .strlen_loop        ; repeat the loop

.done:
    ret

strcpy_asm:
    ; rdi = destination pointer
    ; rsi = source pointer
    
    .strcpy_loop:
        mov al, byte [rsi]  ; load the current byte from the source string
        mov byte [rdi], al   ; store it in the destination string
        test al, al          ; check if it's the null-terminator (0)
        jz .done             ; if it is null, we're done
        inc rdi              ; move to the next byte in the destination
        inc rsi              ; move to the next byte in the source
        jmp .strcpy_loop     ; repeat the loop

    .done:
        ret

