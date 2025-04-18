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

    mov r12, rdi 
    movzx edi, sil
    mov rsi, rdx

    call string_proc_node_create_asm
    cmp rax, NULL
    je .end 

    mov rbx, rax
    mov rdi, r12

    mov rdx, [rdi + 8]
    cmp rdx, NULL
    je .list_empty   ; Si está vacía, proceder a agregar el primer nodo

.list_not_empty:
    mov [rdx], rbx
    mov [rbx + 8], rdx
    mov [rdi + 8], rbx
    jmp .end

.list_empty:
    mov [rdi], rbx
    mov [rdi + 8], rbx
    jmp .end

.end:
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

string_proc_list_concat_asm: