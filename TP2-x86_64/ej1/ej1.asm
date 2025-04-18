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

    call string_proc_node_create_asm
    test rax, rax
    je .return_null

    ; veo si la lista esta vacoia
    mov rbx, [rdi]              ; Obtener la lista (list)
    mov rdx, [rbx + 8]  ; Obtener list->last
    cmp rdx, NULL               ; Comprobar si last es NULL
    je .add_as_first            ; Si la lista está vacía, agregar como primer nodo

    ; veo si no
    mov rdx, [rbx + 8]  ; Obtener el último nodo
    mov [rdx], rax  ; last_node->next = new_node
    mov [rax + 8], rdx ; new_node->previous = last_node
    mov [rbx + 8], rax  ; list->last = new_node
    jmp .return

.add_as_first:
    ; Si la lista está vacía: establecer el primer y último nodo como el nuevo nodo
    mov [rbx], rax ; list->first = new_node
    mov [rbx + 8], rax  ; list->last = new_node

.return:
    pop rbp
    ret

.return_null:
    pop rbp
    ret


string_proc_list_concat_asm: