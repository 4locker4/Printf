    .intel_syntex noprefix
    
    .global _start
;-----------------------------------------------------------------------------------------------

    section .data

    BUFFER_SIZE     equ 128
    BUFFER          db  BUFFER_SIZE dup (0)

    INTERMDT_BUF_SZ equ 64
    INTERMDT_BUF    db  INTERMDT_BUF_SZ dup (0)

    ENTRY           db  'Hello! I am %d years old'

    VARGS_B         db  '%'
    LEN_OF_ADDR_PTR equ 8

    BINARY_MASK     db  1
    OCTAL_MASK      db  8
    HEX_MASK        db  16

    SWAP_BUF        db  8 Dup (8)

    ALPHABET        db  '0123456789ABCDEF'
    
    HEX_SHIFT       equ 4
    OCT_SHIFT       equ 3
    BIN_SHIFT       equ 1

    END_OF_STR      equ '\0'

    ERROR_MSG       db 'You put wrong char after %, end of program...'

    MOV_TO_NEXT_VAR equ 8

;-----------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------
    section .text

;=========================================================== MACROS ============================

%macro printInCmd bufAddr

    mov rax, 1

    mov rdi, 1

    mov rsi, bufAddr

    syscall

%endmacro

;========================================================= START CODE ==========================

_start:
    push rax
    push rcx
    push rdx
    push r11

    call Printf

    pop r11
    pop rax
    pop rcx
    pop rdx

    mov rax, 1
    mov rbx, 0

    int 0x80

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                           PRINTF
;arg1       String with text
;vargs      ...
;
;INFO:      RDX - reserved to variable`s address
;           RDI - reserved to buffer address
;           RSI - reserved to input data
;           R14 - reserved to count quantity of chars into intermediate buffer
;           R15 - reserved to char`s counter
;           
;===============================================================================================

;QUESTIONS?
;
;1) How we get address of user`s string?
;
;2) Do we need to save all registers, without rax, rcx, rdx? 

Printf proc

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    pop r12                     ; save ret address

    pop rsi                     ; get user`s text address

    mov rdx, rsp                ; get first variable`s address

    lea rdi, BUFFER             ; get buffer`s address

    push r12                    ; save the ret address

    xor r15, r15

.readInputData:


        
    call Switch

    cmp byte [rsi], byte END_OF_STR

    jne .readInputData
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    call OutputBuffer

    pop rbx                     ; get the ret address
 
    push rdx                    ; we get the difference between the current stack address and 
    pop rsp                     ; the address when calling the function

    push rbx                    ; put the ret address

    ret

Printf endp

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                           SWITCH
;Entry:     RSI - address in user`s data            This func switch between
;           RDI - address in buffer             special symbols in user`s string
;           RDX - address of last var
;Retrn:    
;Destr:
;===============================================================================================

Switch proc

    cmp byte [rsi], byte '%'
    jne .justLetter

    inc rsi

    cmp byte [rsi], byte '%'
    je .justLetter

    mov r15, rdi

    xor rbx, rbx
    mov bl, byte [rsi]

    mov r12, .jmpTable[(rbx - 'b') * 8]

    jmp r12

;===========================================================JMP TABLE START=====================
.jmpTable:
                            dq binary
                            dq char
                            dq decimal
    times ('h' - 'd' - 1)   dq error
                            dq hexadecimal,
    times ('o' - 'h' - 1)   dq error
                            dq octal,
    times ('s' - 'o' - 1)   dq error
                            dq string

;===========================================================JMP TABLE END=======================

.binary:

    mov r12, BINARY_MASK
    mov r13, BIN_SHIFT

    mov rax, [rdx]
    sub rdx, MOV_TO_NEXT_VAR

    call ConverterSysMltplsTwo

    jmp .preTurnOver

.char:

    inc r15

    mov al, byte [rdx]
    stosb

    sub rdx, MOV_TO_NEXT_VAR

    push rdi
    jmp .funcRet

.decimal:

    mov rax, [rdx]
    sub rdx, MOV_TO_NEXT_VAR

    call ConvertDecimal

    jmp .preTurnOver

.hexadecimal:

    mov r12, HEX_MASK
    mov r13, HEX_SHIFT

    mov rax, [rdx]
    sub rdx, MOV_TO_NEXT_VAR

    call ConvertHexadecimal

    jmp .preTurnOver

.octal:
    
    mov r12, OCTAL_MASK
    mov r13, OCT_SHIFT

    mov rax, [rdx]
    sub rdx, MOV_TO_NEXT_VAR

    call ConvertOctal

    jmp .preTurnOver

.string:

    mov rsi, [rdx]
    sub rdx, MOV_TO_NEXT_VAR

    call PutString

    push rdi
    jmp .funcRet

.error:

;//TD

.justLetter:

    inc r15

    mov al, byte [rsi]
    stosb
    inc rsi

    push rdi
    jmp .funcRet

.preTurnOver:

    push rdi

.turnOver:

    cmp rdi, r15
    jge .exit

    mov al, byte [rdi]
    mov ah, byte [r15]

    mov byte [rdi], ah
    mov byte [r15], al

    inc r15
    dec rdi

    jmp .turnOver

.funcRet:

    pop rdi

    ret

Switch endp

;I*********************************************************************************************I
;I                                       I             I                                       I
;I======================================= CONVERTATIONS =======================================I
;I                                       I             I                                       I
;I*********************************************************************************************I

;===============================================================================================;
;-----------------------------------------------------------------------------------------------;
;                                                 CONVERTER_SYS_MLTPLS_TWO                      ;
;Entry:     RAX - number                        Put user`s multyples two num                    ;
;           RDI - address in buffer                     into buffer                             ;
;           R12 - MASK                                                                          ;
;           R13 - SHIFT                                                                         ;
;Retrn:     none                                                                                ;
;Destr:     RAX, RBX, RSI, R14                                                                  ;
;===============================================================================================;

ConverterSysMltplsTwo proc

    xor r14, r14

    push rdi
    lea rdi, INTERMDT_BUF

    lea rbx, ALPHABET

.loop:

    inc r14

    mov rsi, rax

    and rsi, r12
    shr rax, r13

    add rsi, rbx

    movsb

    cmp rax, 0

    jne .loop

    ;call PutInBuf

    ret

ConverterSysMltplsTwo endp   

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                           DECIMAL
;Entry:     RAX - numbet                            Put user`s decimal num
;           RDI - address in buffer                      into buffer
;Retrn:
;Destr:     
;===============================================================================================

ConvertDecimal proc

    xor r14, r14

    push rdi
    lea rdi, INTERMDT_BUF

    cmp rax, 0

    ja .loop

    inc r14

    mov byte [rdi], byte '-'
    neg rax

.loop:

    inc r14

    div 10

    mov byte [rdi], '0' + r15

    cmp rax, 0

    jne .loop

    call PutInBuf

    ret

ConvertDecimal endp

;I*********************************************************************************************I
;I                                      I              I                                       I
;I=================================== END OF CONVERTATIONS ====================================I
;I                                      I              I                                       I
;I*********************************************************************************************I

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                            PUT_IN_BUF
;Entry:     RDI - address of buffer                 Put user`s string into buffer
;           RSI - address of last char in 
;                 intermadiate buffer
;           
;Retrn:     RAX - lenght of string
;Destr:     RAX, RCX, RDI
;===============================================================================================

PutInBuf proc

    push rdx
    add rdx, r14

    cmp rdx, BUFFER_SIZE

    pop rdx

    jb .start

    call OutputBuffer

.start:

    mov rcx, r14

.loop:

    movsb
    dec rsi
    dec rsi

    loop .loop

    ret


PutInBuf endp

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                              STRLEN
;Entry:     RDI - address of input string           Put user`s string into buffer
;Retrn:     RAX - lenght of string
;Destr:     RAX, RCX, RDI
;===============================================================================================

Strlen proc

    xor rcx, rcx
    dec rcx

    mov al, END_OF_STR

.loop:

    inc rcx

    scasb

    jne .loop

    mov rax, rcx

    ret
Strlen endp

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                            PUT_STRING
;Entry:     RDI - address in buffer                 Put user`s string into buffer
;           RSI - address of input string           
;Retrn:
;Destr:
;===============================================================================================

PutString proc

    push rdi
    push rsi
    mov rdi, rsi

    call Strlen

    pop rsi
    pop rdi

    cmp rax, BUFFER_SIZE - r15

    jb .loop

    call OutputBuffer

.loop:

    movsb

    cmp byte [rsi], END_OF_STR

    jne .loop

    ret

PutString endp

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                          OUTPUT_BUFFER
;Entry:     RDI - address in buffer                 Put user`s string into buffer
;Retrn:     RDI - buffer address
;Destr:     RAX, RSI, RDI
;===============================================================================================

OutputBuffer proc

;=-=-=-=-= Macro -=-=-=-=
;DESTR: RSI, RDI, RAX

    printInCmd rdi
;-=-=-=-=-=-=-=-=-=-=-=-=

    lea rdi, BUFFER
    mov r15, 0

    ret

OutputBuffer endp