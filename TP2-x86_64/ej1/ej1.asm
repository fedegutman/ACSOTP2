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

    ; inicializo la lista
    mov qword [rax], NULL ; first
    mov qword [rax + 8], NULL ; last

    pop rbp
    ret

.return_null:
    xor rax, rax     ; hago xor consigo mismo para limpiarlo
    pop rbp
    ret

string_proc_node_create_asm:
    push rbx
    push r12
    mov r12, rsi

    mov edi, 32 ; tamaño del nodo
    call malloc
    cmp rax, NULL
    je .return_null
    
    ; inicializo el nodo
    mov qword [rax], NULL ; next = NULL
    mov qword [rax + 8], NULL ; previous = NULL
    mov byte [rax + 16], dil ; type = valor d dil
    mov qword [rax + 24], r12 ; hash = puntero

    pop r12
    pop rbx
    ret

.return_null:
    pop r12    
    xor rax, rax
    pop rbx
    ret

string_proc_list_add_node_asm:
    push r12
    mov r12, rdi
    mov rdi, rsi
    mov rsi, rdx

    call string_proc_node_create_asm
    cmp rax, NULL
    je .return  

    mov r9, rax
    mov rcx, [r12 + 8]
    cmp rcx, NULL
    jne .not_empty

    mov [r12 + LIST_FIRST], r9
    mov [r12 + LIST_LAST], r9
    
.not_empty:
    mov [rcx + NODE_NEXT], r9
    mov [r9 + NODE_PREVIOUS], rcx
    mov [r12 + LIST_LAST], r9
    jmp .return

.return:
    pop r12
    ret

string_proc_list_concat_asm:
    push r12
    push r13
    push r14
    push rbx          
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
    test rsi, rsi
    je .next_node

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