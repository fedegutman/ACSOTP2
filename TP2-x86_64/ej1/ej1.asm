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

    mov rdi, empty_string
    mov rsi, r14
    call str_concat
    mov rbx, rax

    mov r15, [r12]

.process_node:
    test r15, r15
    jz .return

    cmp byte [r15 + 16], r13b
    jne .next_node

    mov rdi, rbx
    mov rsi, [r15 + 24]
    call str_concat

    xchg rbx, rax
    mov rdi, rax
    call free

.next_node:
    mov r15, [r15]
    jmp .process_node

.end:
    mov rax, rbx
    pop r15
    pop rbx
    pop r14
    pop r13
    pop r12
    ret