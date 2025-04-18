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

    test rdi, rdi
    jz .return_null

    test rsi, rsi
    jz .return_null

    mov rdx, rsi
    call strlen_asm
    add rax, 1

    mov edi, rax
    call malloc
    test rax, rax
    jz .return_null

    mov rsi, rsi
    mov rdi, rax
    call strcpy_asm

    mov rbx, rdi
    mov rdx, [rbx]
    mov rcx, rax

.loop_start:
    test rdx, rdx
    jz .end_concat

    movzx r8b, byte [rdx + 16]
    cmp r8b, dil
    jne .next_node

    mov r8, [rdx + 24]
    test r8, r8        
    jz .next_node

    mov rsi, r8
    mov rdi, rcx
    call str_concat_asm
    mov rcx, rax

.next_node:
    mov rdx, [rdx]
    jmp .loop_start

.end_concat:
    mov rax, rcx

.return_null:
    mov rax, NULL
    mov rsp, rbp
    pop rbp
    ret