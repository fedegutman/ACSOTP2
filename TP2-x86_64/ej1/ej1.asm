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
extern strcpy
extern strlen

string_proc_list_create_asm:

    push rbp
    mov rbp, rsp ; puntero de la pila

    mov edi, 16 ; bytes necesarios para malloc
    call malloc

    cmp rax, NULL
    je .return_null ; if rax == NULL (malloc falla) return null

    ; inicializo la lista (first y last)
    mov qword [rax], NULL
    mov qword [rax + 8], NULL

    ; mov rsp, rbp
    pop rbp
    ret

.return_null:
    xor rax, rax     ; hago xor consigo mismo para limpiarlo
    pop rbp
    ret

string_proc_node_create_asm:
    push rbp
    mov rbp, rsp
    push rsi

    mov edi, 32 ; tamaño del nodo
    call malloc

    cmp rax, NULL
    je .return_null
    
    pop rsi

    ; inicializo el nodo
    mov qword [rax], NULL ; next = NULL
    mov qword [rax + 8], NULL ; previous = NULL
    mov byte [rax + 16], dil ; type = valor d dil
    mov qword [rax + 24], rsi ; hash = puntero

    mov rax, rbx

    mov rsp, rbp
    pop rbp
    ret

.return_null:
    pop rsi
    xor rax, rax
    ret

string_proc_list_add_node_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13

    mov r12, rdi
    mov r13b, sil
    mov rbx, rdx

    movzx edi, r13b
    mov rsi, rbx
    call string_proc_node_create_asm

    cmp rax, NULL
    je .return  

    mov rbx, rax
    mov rdi, r12
    mov rdx, [rdi + 8]

    cmp rdx, NULL
    jne .list_not_empty

    mov [rdi], rbx
    mov [rdi + 8], rbx
    
.not_empty:
    mov rcx, [rbx + 8]
    mov [rax + 8], rcx
    mov [rcx], rax
    mov [rbx + 8], rax
    jmp .return

.return:
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

string_proc_list_concat_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi
    mov r13b, sil
    mov r14, rdx

    cmp r12, NULL
    je .fail_null_input
    cmp r14, NULL
    je .fail_null_input

    mov rdi, r14
    call strlen
    inc rax

    mov rdi, rax
    call malloc
    cmp rax, NULL
    je .fail
    mov r15, rax

    mov rdi, r15
    mov rsi, r14
    call strcpy

    mov rbx, [r12]

.loop_start:
    cmp rbx, NULL
    je .loop_end

    movzx edi, byte [rbx + 16]

    cmp dil, r13b
    jne .next_node

    mov rsi, [rbx + 24]

    mov rdi, r15
    call str_concat

    cmp rax, NULL
    je .fail_concat

    mov rdi, r15
    call free

    mov r15, rax

.next_node:
    mov rbx, [rbx]
    jmp .loop_start

.loop_end:
    mov rax, r15
    jmp .end

.fail_concat:
    mov rdi, r15
    call free

.fail:
.fail_null_input:
    mov rax, NULL

.end:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret