section .text
    global memcpy
    global matrix_multiply
    global rand_normal

    ; memcpy implementation
memcpy:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    ; Save parameters
    mov rbx, rdi  ; destination
    mov r12, rsi  ; source
    mov r13, rdx  ; size
    
    ; Copy data
    mov rcx, r13
    cld
    rep movsb
    
    ; Return destination
    mov rax, rbx
    
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

    ; Matrix multiplication implementation
matrix_multiply:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    ; Save parameters
    mov rbx, rdi  ; result matrix
    mov r12, rsi  ; matrix A
    mov r13, rdx  ; matrix B
    mov r14, rcx  ; rows
    mov r15, [rsp + 48]  ; cols
    
    ; Initialize result matrix to zero
    mov rdi, rbx
    mov rcx, r14
    imul rcx, r15
    shl rcx, 3  ; multiply by 8 (size of double)
    xor rax, rax
    rep stosq
    
    ; Matrix multiplication
    xor rcx, rcx  ; i = 0
.outer_loop:
    cmp rcx, r14
    jge .done
    
    xor rdx, rdx  ; j = 0
.inner_loop:
    cmp rdx, r15
    jge .next_row
    
    ; Calculate result[i][j]
    mov rax, rcx
    imul rax, r15
    add rax, rdx
    shl rax, 3  ; multiply by 8 (size of double)
    add rax, rbx  ; result[i][j]
    
    ; Sum over k
    xor r8, r8  ; k = 0
.sum_loop:
    cmp r8, r15
    jge .next_col
    
    ; Get A[i][k]
    mov r9, rcx
    imul r9, r15
    add r9, r8
    shl r9, 3
    add r9, r12
    movsd xmm0, [r9]
    
    ; Get B[k][j]
    mov r9, r8
    imul r9, r15
    add r9, rdx
    shl r9, 3
    add r9, r13
    movsd xmm1, [r9]
    
    ; Multiply and add
    mulsd xmm0, xmm1
    addsd xmm0, [rax]
    movsd [rax], xmm0
    
    inc r8
    jmp .sum_loop
    
.next_col:
    inc rdx
    jmp .inner_loop
    
.next_row:
    inc rcx
    jmp .outer_loop
    
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

    ; Normal distribution random number generator
rand_normal:
    push rbp
    mov rbp, rsp
    
    ; Box-Muller transform
    ; Generate two uniform random numbers
    rdrand rax
    mov rcx, rax
    rdrand rax
    
    ; Convert to double in [0,1]
    cvtsi2sd xmm0, rax
    cvtsi2sd xmm1, rcx
    movsd xmm2, [rel .max_int]
    divsd xmm0, xmm2
    divsd xmm1, xmm2
    
    ; Transform to normal distribution
    mulsd xmm0, xmm0
    mulsd xmm1, xmm1
    addsd xmm0, xmm1
    sqrtsd xmm0, xmm0
    mulsd xmm0, [rel .scale]
    
    pop rbp
    ret

section .data
    .max_int dq 0x7fffffffffffffff
    .scale dq 2.0 