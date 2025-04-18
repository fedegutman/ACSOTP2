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
extern strdup

string_proc_list_create_asm:
    ; inicializo la pila
    push rbp
    mov rbp, rsp

    mov rdi, 16 ; tamaño de la lista
    call malloc

    test rax, rax ; si malloc falla -> return
    jz .return
    
    ; inicializo la lista vaica
    mov qword [rax], NULL ; first = NULL
    mov qword [rax + 8], NULL ; last = NULL

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

    test rax, rax
    jz .return

    ; inicializo el nodo
    mov qword [rax], NULL ; next
    mov qword [rax + 8], NULL ; previous
    mov byte [rax + 16], r12b ; type
    mov qword [rax + 24], r13 ; hash

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

    test rax, rax
    jz .return

    mov r14, rax ; guardo el nuevo nodo
    
    ; dos casos: i. lista vacia ii. lista no vacia
    ; i. lista vacia

    cmp qword [rbx], NULL ; chequeo si list->first=NULL
    je .empty_list

    ; ii. lista no vacia
    mov rcx, [rbx + 8] 
    mov [r14 + 8], rcx
    mov [rcx], r14
    mov [rbx + 8], r14
    jmp .return ; ver de sacarlo

.empty_list:
    mov [rbx], r14
    mov [rbx + 8], r14

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
    test r14, r14
    jz .return
    
    mov r15, [rbx] ; current

.loop:
    test r15, r15
    jz .return

    ; verificar tipo
    movzx eax, byte [r15+16] ; type
    cmp al, r12b
    jne .next
    
    ; Concatenar
    mov rdi, r14 ; resultado actual
    mov rsi, [r15 + 24]; hash
    call str_concat
    test rax, rax
    jz .concat_error
    
    ; libero el string anterior
    mov rdi, r14
    mov r14, rax ; result
    call free
    
.next:
    mov r15, [r15]; current
    jmp .loop
    
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