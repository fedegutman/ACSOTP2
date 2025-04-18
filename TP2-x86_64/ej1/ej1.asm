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
    mov rbp, rsp ; puntero de la pil;a

    mov edi, 16 ; bytes necesarios para malloc
    call malloc ;

    test rax, rax
    je .return_null ; if rax == NULL (malloc falló) return null

    mov qword [rax], 0 ; *(rax) = 0 (first = NULL)
    mov qword [rax + 8], 0 ; *(rax + 8) = 0 (last = NULL)

.return_null:
    pop rbp
    ret

string_proc_node_create_asm:

string_proc_list_add_node_asm:

string_proc_list_concat_asm:

