; /** defines bool y puntero **/
%define NULL 0

%define LIST_FIRST 0
%define LIST_LAST 8
%define LIST_SIZE 16 
%define NODE_NEXT 0
%define NODE_PREVIOUS 8
%define NODE_TYPE 16
%define NODE_HASH 24
%define NODE_SIZE 32 

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
extern strdup

string_proc_list_create_asm:
    ; inicializo la pila
    push rbp
    mov rbp, rsp

    mov rdi, 16 ; tamaño de la lista
    call malloc

    cmp rax, NULL ; si malloc falla -> return
    je .return
    
    ; inicializo la lista vaica
    mov qword [rax + LIST_FIRST], NULL ; first = NULL
    mov qword [rax + LIST_LAST], NULL ; last = NULL

.return:
    ; deshago la pila
    pop rbp
    ret

string_proc_node_create_asm:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12b, dil ; type
    mov r13, rsi ; hash

    mov rdi, 32 ; tamaño del nodo
    call malloc

    cmp rax, NULL
    je .return

    ; inicializo el nodo
    mov qword [rax + NODE_NEXT], NULL ; next
    mov qword [rax + + NODE_PREVIOUS], NULL ; previous
    mov byte [rax + NODE_TYPE], r12b ; type
    mov qword [rax + NODE_HASH], r13 ; hash

.return:
    pop r13
    pop r12
    pop rbp
    ret

string_proc_list_add_node_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    mov rbx, rdi ; esto contiene la lista
    mov r12b, sil ; esto el type
    mov r13, rdx ; esto el hash 
    ; ver string_prox_node_create_asm

    ; creo un nuevo nodo (le paso type y hash)
    movzx rdi, r12b
    mov rsi, r13
    call string_proc_node_create_asm

    cmp rax, NULL
    je .return

    mov r14, rax ; guardo el nuevo nodo
    
    ; dos casos: i. lista vacia ii. lista no vacia
    ; i. lista vacia

    cmp qword [rbx], NULL ; chequeo si list->first=NULL
    je .empty_list

    ; ii. lista no vacia
    mov rcx, [rbx + LIST_LAST] 
    mov [r14 + NODE_PREVIOUS], rcx
    mov [rcx + NODE_NEXT], r14
    mov [rbx + LIST_LAST], r14
    jmp .return

.empty_list:
    mov [rbx + LIST_FIRST], r14
    mov [rbx + LIST_LAST], r14

.return:
    pop r14
    pop r13
    pop r12
    pop rbx
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
    
    mov rbx, rdi ; esto contiene la lista
    mov r12b, sil ; esto el type
    mov r13, rdx ; esto el hash 

    mov rdi, r13
    call strdup
    mov r14, rax ; result
    cmp r14, NULL
    je .return
    
    mov r15, [rbx] ; current

.L:
    cmp r15, NULL
    je .return

    movzx eax, byte [r15 + NODE_TYPE] ; type
    cmp al, r12b
    jne .next
    
    mov rdi, r14
    mov rsi, [r15 + NODE_HASH]
    call str_concat
    cmp rax, NULL
    je .concat_error
    
    mov rdi, r14
    mov r14, rax
    call free
    
.next:
    mov r15, [r15 + NODE_NEXT]; current
    jmp .L
    
.concat_error:
    mov rdi, r14
    call free
    xor r14, r14 ; al hacer xor entre dos registros se borra el contenido
    
.return:
    mov rax, r14
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret