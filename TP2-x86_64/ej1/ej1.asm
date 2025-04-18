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

    mov rsp
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

    mov rdi, 32 ; tamaño del nodo
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