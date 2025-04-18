; string_proc_list.asm

; DEFINES de tamaños y offsets para las estructuras

; Para la lista: 
%define LIST_FIRST  0          ; offset del puntero "first"
%define LIST_LAST   8          ; offset del puntero "last"
%define LIST_SIZE   16         ; tamaño total de la estructura (16 bytes)

; DEFINES para el nodo
%define NODE_NEXT       0      ; offset del puntero "next", 8 bytes
%define NODE_PREVIOUS   8      ; offset del puntero "previous", 8 bytes
%define NODE_TYPE       16     ; offset del campo "type" (1 byte)
%define NODE_HASH       24     ; offset del puntero "hash"
%define NODE_SIZE       32     ; tamaño total del nodo

%define NULL 0


section .data
empty_string: db 0

section .text

; Funciones exportadas
global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

; Funciones externas
extern malloc
extern free
extern str_concat



string_proc_list_create_asm:
    mov     rdi, LIST_SIZE       ; sizeof(string_proc_list) (16 bytes)
    call    malloc
    test    rax, rax                ;fallo en memoria
    je      .return_null_list

    mov     qword [rax + LIST_FIRST], NULL   ; first = NULL
    mov     qword [rax + LIST_LAST], NULL    ; last = NULL
    ret

.return_null_list:
    xor rax, rax
    ret

string_proc_node_create_asm:
    push    rbx
    push    r12            

    mov     bl, dil         ; BL = type (byte)
    mov     r12, rsi        ; R12 = hash

    mov     edi, NODE_SIZE  ; tamaño del nodo
    call    malloc
    test    rax, rax        ;fallo de memoria
    jz      .fail

    ; inicializar estructura
    mov     byte  [rax + NODE_TYPE], bl         ; type
    mov     qword [rax + NODE_HASH], r12        ; hash, ¡ya preservado!
    mov     qword [rax + NODE_NEXT], NULL          ; next = NULL
    mov     qword [rax + NODE_PREVIOUS], NULL      ; previous = NULL

    pop     r12             ; restaurar r12
    pop     rbx
    ret

.fail:
    pop     r12             ; restaurar r12
    xor     rax, rax
    pop     rbx
    ret


string_proc_list_add_node_asm:
    push r12                ; Guardar el valor de r12
    mov r12, rdi            ; r12 = lista 

    mov rdi, rsi            ; RDI = type 
    mov rsi, rdx            ; RSI = hash
    
    call string_proc_node_create_asm
    test rax, rax
    je .fin_add

    mov r9, rax             ; r9 = nuevo nodo

    ; Obtener el último nodo de la lista (list->last)
    mov rcx, [r12 + LIST_LAST]
    test rcx, rcx
    je .lista_vacia

    ; Si la lista no está vacía, enlaza el nuevo nodo:
    mov [rcx + NODE_NEXT], r9     ; last->next = nuevo nodo
    mov [r9 + NODE_PREVIOUS], rcx ; nuevo nodo->previous = last
    mov [r12 + LIST_LAST], r9     ; list->last = nuevo nodo
    jmp .fin_add

.lista_vacia:
    ; Si la lista está vacía, asigna el mismo nodo a first y last.
    mov [r12 + LIST_FIRST], r9    ; list->first = nuevo nodo
    mov [r12 + LIST_LAST], r9     ; list->last = nuevo nodo

.fin_add:
    pop r12                 ; Recupera el registro r12
    ret

;

; string_proc_list_concat_asm:
;   rdi = puntero a la lista
;   sil = tipo de nodo a filtrar
;   rdx = string adicional

string_proc_list_concat_asm:
    push    r12
    push    r13
    push    r14
    push    rbx          
    push    r15          

    mov     r12, rdi     ; r12 = lista
    mov     r13b, sil    ; r13b = type
    mov     r14, rdx     ; r14 = string base

    ; str_concat("", string) → rax
    mov     rdi, empty_string
    mov     rsi, r14
    call    str_concat
    mov     rbx, rax     ; rbx = acumulador

    mov     r15, [r12 + LIST_FIRST]   ; r15 = primer nodo

.process_node:
    test    r15, r15
    jz      .finalize

    cmp     byte [r15 + NODE_TYPE], r13b
    jne     .next_node

    ; concatenar hash al acumulador en rbx
    mov     rdi, rbx
    mov     rsi, [r15 + NODE_HASH]
    call    str_concat              ; devuelve nueva cadena en rax

    xchg    rbx, rax                ; rbx = nueva cadena; rax = cadena vieja
    mov     rdi, rax
    call    free                    ; liberamos la vieja

.next_node:
    mov     r15, [r15 + NODE_NEXT]  ; avanzamos al siguiente nodo
    jmp     .process_node

.finalize:
    mov     rax, rbx     ; devolvemos acumulador

    pop     r15
    pop     rbx
    pop     r14
    pop     r13
    pop     r12
    ret