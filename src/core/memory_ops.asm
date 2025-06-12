section .text
    global memcpy
    global memset
    global memcmp

    ; Memory copy: dest = src
memcpy:
    push rbp
    mov rbp, rsp
    
    ; Check if size is 0
    test rdx, rdx
    jz .done
    
    ; Copy data
    mov rcx, rdx
    rep movsb
    
.done:
    pop rbp
    ret

    ; Memory set: dest = value
memset:
    push rbp
    mov rbp, rsp
    
    ; Check if size is 0
    test rdx, rdx
    jz .done
    
    ; Set data
    mov rcx, rdx
    rep stosb
    
.done:
    pop rbp
    ret

    ; Memory compare: compare src1 and src2
memcmp:
    push rbp
    mov rbp, rsp
    
    ; Check if size is 0
    test rdx, rdx
    jz .equal
    
    ; Compare data
    mov rcx, rdx
    repe cmpsb
    jz .equal
    
    ; Not equal
    movzx eax, byte [rsi - 1]
    movzx ecx, byte [rdi - 1]
    sub eax, ecx
    jmp .done
    
.equal:
    xor eax, eax
    
.done:
    pop rbp
    ret 