    global _start

;-----------------------------------------------------------------------------------------------

    section .data

    BUFFER_SIZE      equ 128
    BUFFER:          db  BUFFER_SIZE dup (0)

    INTERMDT_BUF_SZ  equ 64
    INTERMDT_BUF:    db  INTERMDT_BUF_SZ dup (0)

    ENTRY:           db  'Hello! I am %d years old'

    VARGS_B:         db  '%'
    LEN_OF_ADDR_PTR: equ 8

    BINARY_MASK:     db  1
    OCTAL_MASK:      db  8
    HEX_MASK:        db  16

    SWAP_BUF:        db  8 Dup (8)

    ALPHABET:        db  '0123456789ABCDEF'
    
    HEX_SHIFT        equ 4
    OCT_SHIFT        equ 3
    BIN_SHIFT        equ 1

    END_OF_STR       equ '\0'

    ERROR_MSG:       db 'You put wrong char after %, end of program...'

    MOV_TO_NEXT_VAR  equ 8

;-----------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------
    section .text

;=========================================================== MACROS ============================

%macro printInCmd 1

    mov rax, 1

    mov rdi, 1

    mov rsi, %1

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
;           RCX - reserved to count quantity of chars into intermediate buffer
;           RDI - reserved to buffer address
;           RSI - reserved to input data
;           R15 - reserved to char`s counter
;           
;===============================================================================================

;QUESTIONS?
;
;1) How we get address of user`s string?
;
;2) Do we need to save all registers, without rax, rcx, rdx? 

Printf:

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

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                           SWITCH
;Entry:     RSI - address in user`s data            This func switch between
;           RDI - address in buffer             special symbols in user`s string
;           RDX - address of last var
;Retrn:    
;Destr:     RBX
;===============================================================================================

Switch:

    cmp byte [rsi], byte '%'
    jne .justLetter

    inc rsi

    cmp byte [rsi], byte '%'
    je .justLetter

    xor rbx, rbx
    mov bl, byte [rsi]

    mov r12, .jmpTable[(rbx - 'b') * 8]

    jmp r12

;===========================================================JMP TABLE START=====================
.jmpTable:
                            dq .binary
                            dq .char
                            dq .decimal
    times ('h' - 'd' - 1)   dq .error
                            dq .hexadecimal,
    times ('o' - 'h' - 1)   dq .error
                            dq .octal,
    times ('s' - 'o' - 1)   dq .error
                            dq .string

;===========================================================JMP TABLE END=======================

.binary:

    mov r12, BINARY_MASK
    mov r13, BIN_SHIFT

    call ConverterSysMltplsTwo

    jmp .funcRet

.char:

    inc r15

    mov al, byte [rdx]
    stosb

    jmp .funcRet

.decimal:

    call ConvertDecimal

    jmp .funcRet

.hexadecimal:

    mov r12, HEX_MASK
    mov r13, HEX_SHIFT

    call ConverterSysMltplsTwo

    jmp .funcRet

.octal:
    
    mov r12, OCTAL_MASK
    mov r13, OCT_SHIFT

    call ConverterSysMltplsTwo

    jmp .funcRet

.string:

    call PutString

    jmp .funcRet

.error:

    ;;\td

.justLetter:

    inc r15

    mov al, byte [rsi]
    stosb
    inc rsi

    jmp .funcRet

.funcRet:

    ret

;I*********************************************************************************************I
;I                                       I             I                                       I
;I======================================= CONVERTATIONS =======================================I
;I                                       I             I                                       I
;I*********************************************************************************************I

;===============================================================================================;
;-----------------------------------------------------------------------------------------------;
;                                                 CONVERTER_SYS_MLTPLS_TWO                      ;
;Entry:     RDI - address in buffer             Put user`s multyples two num                    ;
;           R12 - MASK                                 into buffer                              ;
;           R13 - SHIFT                                                                         ;
;Retrn:     none                                                                                ;
;Destr:     RAX, RBX, RSI, RCX                                                                  ;
;===============================================================================================;

ConverterSysMltplsTwo:

    mov rax, [rdx]              ; put var in rax
    sub rdx, MOV_TO_NEXT_VAR

    push rsi                    ; save rsi

    xor rcx, rcx                ; reset to zero intermediate buffer counter

    mov rsi, rdi                ; | > prepare for movsb & PutInBuf
    lea rdi, INTERMDT_BUF       ; |/

    lea rbx, ALPHABET           ; for shift

.loop:

    inc rcx

    mov rsi, rax

    and rsi, rcx
    shr rax, cl

    add rsi, rbx

    movsb

    cmp rax, 0

    jne .loop

    call PutInBuf

    mov rdi, rsi
    pop rsi

    ret

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                           DECIMAL
;Entry:     RAX - numbet                            Put user`s decimal num
;           RDI - address in buffer                      into buffer
;Retrn:
;Destr:     
;===============================================================================================

ConvertDecimal:
    
    mov rax, [rdx]
    sub rdx, MOV_TO_NEXT_VAR

    push rdx

    push rsi

    xor rcx, rcx

    mov rsi, rdi
    lea rdi, INTERMDT_BUF

    mov r14, 10

    cmp rax, 0

    ja .loop

    inc rcx

    mov byte [rdi], byte '-'
    neg rax

.loop:

    inc rcx

    div r14

    mov rbx, '0'
    add rbx, rdx

    mov byte [rdi], dl

    cmp rax, 0

    jne .loop

    call PutInBuf

    mov rdi, rsi
    pop rsi

    pop rdx

    ret

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
;Retrn:
;Destr:     RCX
;===============================================================================================

PutInBuf:

    push rdx
    add rdx, rcx

    cmp rdx, BUFFER_SIZE

    pop rdx

    jb .loop

    call OutputBuffer

.loop:

    movsb
    dec rsi
    dec rsi

    loop .loop

    ret

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                              STRLEN
;Entry:     RDI - address of input string           Put user`s string into buffer
;Retrn:     RAX - lenght of string
;Destr:     RAX, RCX, RDI
;===============================================================================================

Strlen:

    mov rsi, [rdx]

    xor rcx, rcx
    dec rcx

    mov al, END_OF_STR

.loop:

    inc rcx

    scasb

    jne .loop

    mov rax, rcx

    ret

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                            PUT_STRING
;Entry:     RSI - address of input strin            Put user`s string into buffer
;                      
;Retrn:
;Destr:
;===============================================================================================

PutString:

    push rsi

    mov rdi, [rdx]
    sub rdx, MOV_TO_NEXT_VAR

    call Strlen

    pop rsi

    mov rbx, BUFFER_SIZE
    sub rbx, r15

    cmp rax, rbx

    jb .loop

    call OutputBuffer

.loop:

    movsb

    cmp byte [rsi], byte END_OF_STR

    jne .loop

    ret

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                          OUTPUT_BUFFER
;Entry:     RDI - address in buffer                 Put user`s string into buffer
;Retrn:     RDI - buffer address
;Destr:     RAX, RSI, RDI
;===============================================================================================

OutputBuffer:

;=-=-=-=-= Macro -=-=-=-=
;DESTR: RSI, RDI, RAX

    printInCmd rdi
;-=-=-=-=-=-=-=-=-=-=-=-=

    lea rdi, BUFFER
    mov r15, 0

    ret