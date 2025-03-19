    .intel_syntex noprefix
    
    .global _start
;-----------------------------------------------------------------------------------------------

    section .data

    BUFFER          db  512 dup (0)

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

;-----------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------
    section .text

;=========================================================== MACROS ============================

%macro printInCmd 0

    mov rdi, 1
    mov rax, 1
    syscall

%endmacro

;========================================================= START CODE ==========================

_start:
    push rax
    push rcx
    push rdx

    call Printf

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
;===============================================================================================

;QUESTIONS?
;
;1) How we get address of user`s string?
;
;2) Do we need to save all registers, without rax, rcx, rdx? 

Printf proc

    pop rdx                     ; save ret address

    pop rsi                     ; get user`s text address

;-----------------------------------------------------------------------------------------------

    push rdx                    ; save
    push rsi                    ; arg1

    call CountVargs             ; rax - quantity of vargs

    pop  rdx                    ; saved
;-----------------------------------------------------------------------------------------------

    mov rdi, BUFFER

.readInputData:
        
    call Switch

    cmp byte [rsi], byte END_OF_STR

    jne .readInputData

    call OutputBuffer

; TD end func


Printf endp

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                           SWITCH
;Entry:     RSI - address in user`s data            This func switch between
;           RDI - address in buffer             special symbols in user`s string
;           R13 - address of func args
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

    call ConverterSysMltplsTwo

    jmp .preTurnOver

.char:

    mov al, byte [r13]
    stosb

    push rdi
    jmp .funcRet

.decimal:

    call ConvertDecimal

    jmp .preTurnOver

.hexadecimal:

    mov r12, HEX_MASK
    mov r13, HEX_SHIFT

    call ConvertHexadecimal

    jmp .preTurnOver

.octal:
    
    mov r12, OCTAL_MASK
    mov r13, OCT_SHIFT

    call ConvertOctal

    jmp .preTurnOver

.string:

    call PutString

    push rdi
    jmp .funcRet

.error:



.justLetter:

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
;Destr:     RAX, RBX, RSI                                                                       ;
;===============================================================================================;

ConverterSysMltplsTwo proc

    lea rbx, ALPHABET

.loop:

    mov rsi, rax

    and rsi, r12
    shr rax, r13

    add rsi, rbx

    movsb

    cmp rax, 0

    jne .loop

    ret

ConverterSysMltplsTwo endp   

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                           DECIMAL
;Entry:     RAX - numbet                            Put user`s decimal num
;           RDI - address in buffer                      into buffer
;Retrn:
;Destr:     RAX, RDX
;===============================================================================================

ConvertDecimal proc
    cmp rax, 0

    ja .loop

    mov byte [rdi], byte '-'
    neg rax

.loop:

    div 10

    mov byte [rdi], '0' + rdx

    cmp rax, 0

    jne .loop

    ret

ConvertDecimal endp

;I*********************************************************************************************I
;I                                      I              I                                       I
;I=================================== END OF CONVERTATIONS ====================================I
;I                                      I              I                                       I
;I*********************************************************************************************I


;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                            PUT_STRING
;Entry:     RDI - address in buffer                 Put user`s string into buffer
;           RSI - address of input string           
;Retrn:
;Destr:
;===============================================================================================

PutString proc

.loop:

    movsb

    cmp byte [rsi], END_OF_STR

    jne .loop

    ret

PutString endp
