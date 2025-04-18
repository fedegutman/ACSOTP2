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

    cmp rax, NULL ; si malloc falla -> return
    jeq .return
    
    ; inicializo la lista vaica
    mov qword [rax], NULL ; first = NULL
    mov qword [rax + 8], NULL ; last = null

.return
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

    cmp rdi, NULL
    jeq .return

    ; inicializo el nodo
    mov qword [rax], NULL ; next
    mov qword [rax + 8], NULL ; previous
    mov byte [rax + 16], r12b ; type
    mov qword [rax + 24], r13 ; hash

.return 
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
    jeq .return

    mov r14, rax ; guardo el nuevo nodo
    
    ; dos casos: i. lista vacia ii. lista no vacia
    ; i. lista vacia

    cmp qword [rbx], NULL ; chequeo si list->first=NULL
    jeq .empty_list

    ; ii. lista no vacia
    mov rcx, [rbx + 8] 
    mov [r14 + 8], rcx
    mov [rcx], r14
    mov [rbx + 8], r14

.empty_list
    mov [rbx], r14
    mov [rbx + 8], r14
    jmp .return ; ver de sacarlo

.return
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
    jeq .return
    
    ; while
    mov r15, [rbx] ; current

.loop:
    cmp r15, NULL
    jeq .return

    ; verificar tipo
    movzx eax, byte [r15+16] ; type
    cmp al, r12b
    jne .next
    
    ; Concatenar
    mov rdi, r14 ; resultado actual
    mov rsi, [r15+24]; hash
    call str_concat
    cmp rax, NULL
    jeq .concat_error
    
    ; libero el string anterior
    mov rdi, r14
    mov r14, rax ; result
    call free
    
.next:
    mov r15, [r15]; current
    jmp .loop
    
.concat_error:
    cmp r14, NULL
    jeq .return
    mov rdi, r14
    call free
    xor r14, r14 ; al hacer xor con dos registros se borra el contenido
    
.return:
    mov rax, r14
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret