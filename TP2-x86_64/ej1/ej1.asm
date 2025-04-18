; /** defines bool y puntero **/
%define NULL 0
%define TRUE 1
%define FALSE 0

section .data
empty_string: db 0

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
    mov edi, 32          ; Pass 32 (size of the node) to malloc
    call malloc
    test rax, rax        ; Check if malloc failed
    je .return_null

    ; Initialize the node
    mov qword [rax], NULL ; next = NULL
    mov qword [rax + 8], NULL ; previous = NULL
    mov byte [rax + 16], dil  ; type = dil (first argument)
    mov qword [rax + 24], rsi ; hash = rsi (second argument)

    ret

.return_null:
    xor rax, rax         ; Return NULL
    ret

string_proc_list_add_node_asm:
    ; Validate input list pointer
    test rdi, rdi        ; Check if the list pointer is NULL
    je .return_null

    ; Call string_proc_node_create_asm with type (sil) and hash (rdx)
    movzx rsi, sil       ; Zero-extend type (sil) into rsi (second argument for node creation)
    mov rdx, rdx         ; Hash is already in rdx
    call string_proc_node_create_asm
    test rax, rax        ; Check if node creation failed
    je .return

    ; rax now contains the new node
    mov r8, rax          ; Save the new node in r8
    mov r9, [rdi + 8]    ; Load list->last into r9
    test r9, r9          ; Check if the list is empty
    je .empty_list

    ; Add the node to the end of the list
    mov [r9], r8         ; last->next = new_node
    mov [r8 + 8], r9     ; new_node->previous = last
    mov [rdi + 8], r8    ; list->last = new_node
    ret

.empty_list:
    mov [rdi], r8        ; list->first = new_node
    mov [rdi + 8], r8    ; list->last = new_node
    ret

.return_null:
    xor rax, rax         ; Return NULL
    ret

string_proc_list_concat_asm:
    push rbx             ; Save registers
    push r12
    push r13
    push r14
    push r15

    ; Initialize variables
    mov r12, rdi         ; r12 = list
    mov r13b, sil        ; r13b = type
    mov r14, rdx         ; r14 = hash

    ; Allocate memory for the result (str_concat(empty_string, hash))
    mov rdi, empty_string ; First argument to str_concat
    mov rsi, r14          ; Second argument to str_concat
    call str_concat
    test rax, rax         ; Check if str_concat failed
    je .return_null
    mov rbx, rax          ; rbx = result

    ; Iterate through the list
    mov r15, [r12]        ; r15 = list->first

.process_node:
    test r15, r15         ; Check if current node is NULL
    jz .return_result

    ; Check if current->type == type
    cmp byte [r15 + 16], r13b
    jne .next_node

    ; Check if current->hash != NULL
    mov rdi, rbx          ; First argument to str_concat (current result)
    mov rsi, [r15 + 24]   ; Second argument to str_concat (current->hash)
    call str_concat
    test rax, rax         ; Check if str_concat failed
    je .free_and_return_null
    mov rbx, rax          ; Update result

.next_node:
    mov r15, [r15]        ; Move to the next node (current = current->next)
    jmp .process_node

.return_result:
    mov rax, rbx          ; Return the result
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.free_and_return_null:
    mov rdi, rbx          ; Free the allocated result
    call free
.return_null:
    xor rax, rax          ; Return NULL
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret