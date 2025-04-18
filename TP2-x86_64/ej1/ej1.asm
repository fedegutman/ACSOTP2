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

.return_null:
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

.return_null:
    pop rbp
    ret

string_proc_list_add_node_asm:
    push rbp
    mov rbp, rsp

    test rdi, rdi        ; Check if the list pointer is NULL
    je .return_null

    call string_proc_node_create_asm
    test rax, rax ; chequeo si el nodo se creo correctamente
    je .return_null

    ; me fijo si la lista esta vacía
    mov rbx, [rdi]
    mov rdx, [rbx]
    cmp rdx, NULL
    je .add_as_first

    mov rdx, [rbx + 8]
    mov r8, rax
    mov qword [rdx], r8
    mov qword [rax + 8], rdx
    mov [rbx + 8], rax
    jmp .return

.add_as_first:
    mov [rbx], rax ; first
    mov [rbx + 8], rax ; last

.return:
    pop rbp
    ret

.return_null:
    pop rbp
    ret      

string_proc_list_concat_asm:
    push rbp
    mov rbp, rsp

    ; Validate input parameters (list and hash)
    test rdi, rdi        ; Check if list (rdi) is NULL
    je .return_null
    test rsi, rsi        ; Check if hash (rsi) is NULL
    je .return_null

    ; Allocate memory for the initial result (strlen(hash) + 1)
    mov rdi, rsi         ; Pass hash to strlen
    call strlen          ; rax = strlen(hash)
    add rax, 1           ; Add 1 for the null terminator
    mov rdi, rax         ; Pass size to malloc
    call malloc          ; Allocate memory for result
    test rax, rax        ; Check if malloc failed
    je .return_null
    mov rbx, rax         ; Save result pointer in rbx

    ; Copy hash into result
    mov rdi, rbx         ; Destination (result)
    mov rsi, rsi         ; Source (hash)
    call strcpy          ; Copy hash into result

    ; Iterate through the list
    mov rcx, [rdi]       ; rcx = list->first
.loop:
    test rcx, rcx        ; Check if current node is NULL
    je .done             ; Exit loop if NULL

    ; Check if current->type == type
    movzx rdx, byte [rcx + 16] ; Load current->type into rdx
    cmp dl, sil          ; Compare type (dl) with input type (sil)
    jne .next_node       ; Skip if types do not match

    ; Check if current->hash != NULL
    mov rdi, [rcx + 24]  ; Load current->hash into rdi
    test rdi, rdi        ; Check if hash is NULL
    je .next_node        ; Skip if NULL

    ; Concatenate result with current->hash
    mov rsi, rdi         ; Pass current->hash as second argument
    mov rdi, rbx         ; Pass result as first argument
    call str_concat      ; Call str_concat(result, current->hash)
    test rax, rax        ; Check if str_concat failed
    je .free_and_return_null
    mov rbx, rax         ; Update result pointer

.next_node:
    mov rcx, [rcx]       ; Move to the next node (current = current->next)
    jmp .loop            ; Repeat loop

.done:
    mov rax, rbx         ; Return the result
    pop rbp
    ret

.free_and_return_null:
    mov rdi, rbx         ; Free the allocated result
    call free
.return_null:
    xor rax, rax         ; Return NULL
    pop rbp
    ret

strlen:
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

strcpy:
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
