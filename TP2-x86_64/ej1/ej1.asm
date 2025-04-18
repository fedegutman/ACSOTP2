; /** defines bool y puntero **/
%define NULL 0
%define TRUE 1
%define FALSE 0

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
    mov rdi, 16 ; bytes necesarios para malloc
    call malloc
    cmp rax, NULL
    je .return ; if rax == NULL (malloc falla) return null

    ; inicializo la lista
    mov qword [rax], NULL ; first
    mov qword [rax + 8], NULL ; last

    ret

.return:
    xor rax, rax     ; hago xor consigo mismo para limpiarlo
    ret

string_proc_node_create_asm:
    ; rdi = type (dil)
    ; rsi = hash (r12)

    mov rdi, dil            ; tipo
    mov rsi, r12            ; hash

    mov rdx, 32             ; tamaño del nodo
    call malloc
    cmp rax, NULL
    je .return
    
    ; inicializo el nodo
    mov qword [rax], NULL   ; next = NULL
    mov qword [rax + 8], NULL   ; previous = NULL
    mov byte [rax + 16], rdi   ; type = valor de tipo
    mov qword [rax + 24], rsi  ; hash = puntero

    ret

.return:
    xor rax, rax
    ret

string_proc_list_add_node_asm:
    ; rdi = lista (r12)
    ; rsi = nodo a agregar (rsi)
    ; rdx = nodo previo (rdx)

    mov r12, rdi           ; lista
    mov rsi, rdx           ; nuevo nodo
    call string_proc_node_create_asm
    cmp rax, NULL
    je .return

    mov r9, rax           ; r9 = nuevo nodo

    mov rbx, [r12 + 8]    ; rbx = último nodo
    test rbx, rbx
    je .empty_list

    mov [rbx], r9         ; next del último = nuevo nodo
    mov [r9 + 8], rbx     ; previous del nuevo nodo = último
    mov [r12 + 8], r9     ; last = nuevo nodo
    jmp .return

.empty_list:
    mov [r12], r9         ; first = nuevo nodo
    mov [r12 + 8], r9     ; last = nuevo nodo

.return:
    ret

string_proc_list_concat_asm:
    ; rdi = lista (r12)
    ; rsi = tipo de nodo (r13b)
    ; rdx = cadena a concatenar (r14)

    mov r12, rdi           ; lista
    mov r13b, sil          ; tipo de nodo
    mov r14, rdx           ; cadena a concatenar

    ; Usamos directamente rdi y rsi para concatenar, sin empty_string
    mov rdi, rsi           ; cadena a concatenar
    call str_concat
    mov rbx, rax           ; rbx = cadena concatenada

    mov r15, [r12]         ; r15 = primer nodo de la lista

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

.return:
    mov rax, rbx
    ret
