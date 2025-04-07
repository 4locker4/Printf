    global MyPrintf

;-----------------------------------------------------------------------------------------------

    section .data

    BUFFER_SIZE      equ 8
    BUFFER:          times BUFFER_SIZE db 0

    INTERMDT_BUF_SZ  equ 64
    INTERMDT_BUF:    times INTERMDT_BUF_SZ db 0

    VARGS_B:         db  '%'
    LEN_OF_ADDR_PTR  equ 8

    HEX_MASK         equ 15
    OCTAL_MASK       equ 7
    BINARY_MASK      equ 1

    ALPHABET:        db  '0123456789ABCDEF'
    
    HEX_SHIFT        equ 4
    OCT_SHIFT        equ 3
    BIN_SHIFT        equ 1

    END_OF_STR       equ 0d

    IS_NUM_NEG       equ 8000000h
    NEG_MASK         equ 0FFFFFFFFh

    ERROR_MSG:       db 'You put wrong char after %, end of program...'
    ERROR_MSG_SIZE   equ $ - ERROR_MSG

    MOV_TO_NEXT_VAR  equ 8

;-----------------------------------------------------------------------------------------------

;-----------------------------------------------------------------------------------------------
    section .text

;// TD Replace Intermadiate buf -> stack

;=========================================================== MACROS ============================

%macro PUT_CHAR_INTO_BUFFER 1

                call CheckBuffer     

                mov al, %1
                stosb

                inc r15                  
%endmacro

;========================================================= START CODE ==========================

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
;Destr:     RAX, RBX, RCX, RDX, RDI, RSI, R12, R13, R14, R15
;===============================================================================================

MyPrintf:

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- Springboard -=-=-=-=-=-=-=-=-=-=
    pop r12                         ; save ret address
    mov rdx, rsp

    push r9
    push r8
    push rcx
    push rdx
    push rsi

    push rdx
    push r12                        ; save the ret address

    mov rsi, rdi
    lea rdi, BUFFER

    mov rdx, rsp                    ; get first variable`s address
    add rdx, MOV_TO_NEXT_VAR * 2
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    xor r15, r15

.readInputData:
        
    call Switch

    cmp byte [rsi], byte END_OF_STR

    jne .readInputData
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    call OutputBuffer

    pop rbx                     ; get the ret address
    
    pop rsp                     ; the address when calling the function

    push rbx                    ; put the ret address

    ret

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                           SWITCH
;           RDX - address of last var                Switch to needed func
;Retrn:    
;Destr:     RAX, RBX, RCX, RDX, RDI, RSI, R12, R13, R14
;===============================================================================================

Switch:

    cmp byte [rsi], byte "%"
    jne .justLetter

    inc rsi

    cmp byte [rsi], byte "%"
    je .justLetter

    xor rbx, rbx
    mov bl, byte [rsi]

    inc rsi

    cmp bl, byte 'b'
    jb .error

    cmp bl, byte 'x'
    ja .error

    jmp .jmpTable[(rbx - 'b') * 8]

;===========================================================JMP TABLE START=====================
.jmpTable:
                            dq .binary
                            dq .char
                            dq .decimal
    times ('o' - 'd' - 1)   dq .error
                            dq .octal
    times ('s' - 'o' - 1)   dq .error
                            dq .string
    times ('x' - 's' - 1)   dq .error
                            dq .hexadecimal

;===========================================================JMP TABLE END=======================

.binary:

    mov r12, BINARY_MASK
    mov r13, BIN_SHIFT

    call ConverterSysMltplsTwo

    jmp .funcRet

.char:

    PUT_CHAR_INTO_BUFFER byte [rdx]

    add rdx, MOV_TO_NEXT_VAR

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

    mov rdi, ERROR_MSG
    mov r15, ERROR_MSG_SIZE
    call OutputBuffer

    jmp .funcRet

.justLetter:

    call CheckBuffer

    mov al, byte [rsi]
    stosb

    inc r15
    inc rsi

.funcRet:

    ret

;===============================================================================================;
;-----------------------------------------------------------------------------------------------;
;                                                     CHECK_BUFFER                              ;
;Entry:     RDI - address in buffer             Check if size of var more                       ;
;           R15 - quantity of chars in buf            than buffer`s                             ;
;Retrn:     none                                                                                ;
;Destr:     none                                                                                ;
;===============================================================================================;

CheckBuffer:

    cmp r15, BUFFER_SIZE - 1

    jb .BufIsOk

    call OutputBuffer

.BufIsOk:

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
;Destr:     RAX, RBX, RCX, RSI                                                                  ;
;===============================================================================================;

ConverterSysMltplsTwo:

;-= Here the variabel is in RBX -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    mov rbx, [rdx]              ; put var in rbx
    add rdx, MOV_TO_NEXT_VAR

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    push rsi                    ; save
    push rdx

    lea rsi, INTERMDT_BUF
    xchg rsi, rdi               ; for stosb

    lea rdx, ALPHABET           ; for shift

    xor rcx, rcx                ; reset to zero intermediate buffer counter
    xchg rcx, r13               ; becouse we can`t shift (by shr) at r13

.loop:

    inc r13

    mov rax, rbx

    and rax, r12                ; mask
    shr rbx, cl                 ; shift

    add rax, rdx                ; offset in alphabet
    mov rax, [rax]

    stosb                       ; put alphabet`s char = rdx

    cmp rbx, 0

    jne .loop

    dec rdi

    xchg r13, rcx               ; was for shift
    xchg rdi, rsi               ; was for stosw

    call PutInBuf

    pop rdx
    pop rsi

    ret

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                           DECIMAL
;Entry:     RAX - numbet                            Put user`s decimal num
;           RDI - address in buffer                      into buffer
;           
;Retrn:
;Destr:     RAX, RBX, RCX
;===============================================================================================

ConvertDecimal:

;-= Here the variabel is in RAX -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    mov rax, [rdx]
    add rdx, MOV_TO_NEXT_VAR

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    cmp rax, IS_NUM_NEG

    jb .positive

    inc r15

    mov byte [rdi], byte '-'
    inc rdi

    not eax
    inc eax

.positive:

    push rdx                    ; save
    push rsi

    lea rsi, INTERMDT_BUF       ; rsi - intermediate buffer

    xor rcx, rcx                ; xor counter of intermediate buffer chars

    mov r14, 10                 ; becouse we will div on it

.loop:

    inc rcx
    xor rdx, rdx                ; for div

    div r14

    mov rbx, '0'
    add rbx, rdx

    mov byte [rsi], bl
    inc rsi

    cmp rax, 0

    jne .loop

    dec rsi

    call PutInBuf

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

    add r15, rcx

    cmp r15, BUFFER_SIZE

    jb .loop

    sub r15, rcx

    call OutputBuffer

    add r15, rcx

.loop:

    movsb
    
    dec rsi 
    dec rsi

    loop .loop
    
    inc rsi

    ret

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                            PUT_STRING
;Entry:     RDX - var`s address                      Put user`s string into buffer
;                      
;Retrn:     none
;Destr:     RBX
;===============================================================================================

PutString:

    push rsi                    ; to save user`s string

;-= Here the variabel is in RSI -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    mov rsi, [rdx]
    add rdx, MOV_TO_NEXT_VAR

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=

.loop:

    PUT_CHAR_INTO_BUFFER byte [rsi]

    inc rsi

    mov bl, byte [rsi]
    cmp bl, END_OF_STR

    jne .loop

    pop rsi

    ret

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                          OUTPUT_BUFFER
;Entry:     RDI - address in buffer                 Put user`s string into buffer
;Retrn:     RDI - buffer address
;Destr:     RAX, RSI, RDI
;===============================================================================================

OutputBuffer:

    push rdx
    push rsi
    push rcx

    lea rsi, BUFFER

    mov rax, 1
    mov rdi, 1
    mov rdx, r15
    syscall
 
    lea rdi, BUFFER
    mov r15, 0

    pop rcx
    pop rsi
    pop rdx

    ret
