    global MyPrintf

;-----------------------------------------------------------------------------------------------
    section .text

;=========================================================== MACROS ============================

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

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    pop r12                     ; save ret address

    push r9
    push r8
    push rcx
    push rdx
    push rsi

    mov rsi, rdi
    lea rdi, BUFFER

    mov rdx, rsp                ; get first variable`s address

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

    mov rax, 1
    mov rbx, 0

    ret

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                           SWITCH
;           RDX - address of last var
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

    mov r12, .jmpTable[(rbx - 'b') * 8]

    jmp r12

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

    mov rdi, ERROR_MSG
    call OutputBuffer

    jmp .funcRet

.justLetter:

    inc r15

    mov al, byte [rsi]
    stosb
    inc rsi

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
;Destr:     RAX, RBX, RCX, RSI                                                                  ;
;===============================================================================================;

ConverterSysMltplsTwo:

;-= Here the variabel is in RBX -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    mov rbx, [rdx]              ; put var in rbx
    sub rdx, MOV_TO_NEXT_VAR

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    push rsi                    ; save
    push rdx

    lea rsi, INTERMDT_BUF
    xchg rsi, rdi               ; for stosw

    lea rdx, ALPHABET           ; for shift

    xor rcx, rcx                ; reset to zero intermediate buffer counter
    xchg rcx, r13               ; becouse we can`t shift (by shr) at r13

.loop:

    inc r13

    mov rax, rbx

    and rdx, r12                ; mask
    shr rbx, cl                 ; shift

    add rax, rdx                ; offset in alphabet

    stosb                       ; put alphabet`s char = rdx

    cmp rbx, 0

    jne .loop

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
;Retrn:
;Destr:     
;===============================================================================================

ConvertDecimal:

;-= Here the variabel is in RAX -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    mov rax, [rdx]
    sub rdx, MOV_TO_NEXT_VAR

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    cmp rax, 0

    ja .positive

    inc r15

    mov byte [rdi], byte '-'
    inc rdi

    neg rax

.positive:

    push rdx                    ; save
    push rsi

    lea rsi, INTERMDT_BUF       ; rsi - intermediate buffer

    xor rcx, rcx                ; xor counter of intermediate buffer chars
    xor rdx, rdx                ; for div

    mov r14, 10                 ; becouse we will div on it

.loop:

    inc rcx

    div r14

    mov rbx, '0'
    add rbx, rdx

    mov byte [rsi], bl
    inc rsi

    cmp rax, 0

    jne .loop

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

;// why the rsi is 1 here?
;// and why the rcx is 4199438

PutInBuf:

    push r15
    add r15, rcx

    cmp r15, BUFFER_SIZE

    pop r15

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

    xchg rsi, rdi               ; for scasb

    xor rcx, rcx
    dec rcx

    xor rax, rax

    mov al, END_OF_STR

.loop:

    inc rcx

    scasb

    jne .loop

    mov rax, rcx
    xchg rsi, rdi               ; because of scasb

    ret

;===============================================================================================
;-----------------------------------------------------------------------------------------------
;                                                            PUT_STRING
;Entry:                                            Put user`s string into buffer
;                      
;Retrn:
;Destr:
;===============================================================================================

PutString:

;-= Here the variabel is in RSI -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    mov rsi, [rdx]
    sub rdx, MOV_TO_NEXT_VAR

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    push rsi

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

    ;printInCmd rdi
;-=-=-=-=-=-=-=-=-=-=-=-=
    push rdx
    push rsi

    mov rax, 1
    lea rsi, BUFFER
    mov rdi, 1
    mov rdx, r15
    syscall

    pop rsi
    pop rdx

    lea rdi, BUFFER
    mov r15, 0

    ret

;-----------------------------------------------------------------------------------------------

    section .data

    BUFFER_SIZE      equ 128
    BUFFER:          times BUFFER_SIZE db 0

    INTERMDT_BUF_SZ  equ 64
    INTERMDT_BUF:    times INTERMDT_BUF_SZ db 0

    VARGS_B:         db  '%'
    LEN_OF_ADDR_PTR  equ 8

    HEX_MASK         equ 16
    OCTAL_MASK       equ 8
    BINARY_MASK      equ 1

    ALPHABET:        db  '0123456789ABCDEF'
    
    HEX_SHIFT        equ 4
    OCT_SHIFT        equ 3
    BIN_SHIFT        equ 1

    END_OF_STR       equ 0d

    ERROR_MSG:       db 'You put wrong char after %, end of program...'

    MOV_TO_NEXT_VAR  equ 8

;-----------------------------------------------------------------------------------------------