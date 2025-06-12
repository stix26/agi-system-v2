section .data
    ; Random number generation constants
    rand_seed dq 12345  ; Initial seed for random number generation
    
    ; Math constants
    pi dq 3.14159265358979323846
    two_pi dd 6.283185307179586  ; 2π for normal distribution
    six dd 6.0
    one_twenty dd 120.0

section .text
    global matrix_multiply
    global memcpy
    global rand_float
    global rand_normal
    global matrix_transpose
    global vector_dot_product
    global xavier_init
    
    ; Matrix multiplication: C = A * B
    ; rdi = A matrix pointer
    ; rsi = B matrix pointer
    ; rdx = C matrix pointer (output)
    ; rcx = rows of A
    ; r8 = cols of A (rows of B)
    ; r9 = cols of B
matrix_multiply:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    ; Save parameters
    mov r10, rcx  ; rows_A
    mov r11, r8   ; cols_A
    mov r12, r9   ; cols_B
    
    ; Initialize outer loop counter
    xor r10, r10  ; i = 0
.outer_loop:
    cmp r10, rcx  ; i < rows_A
    jge .done
    
    ; Initialize middle loop counter
    xor r11, r11  ; j = 0
.middle_loop:
    cmp r11, r9   ; j < cols_B
    jge .next_i
    
    ; Initialize sum
    pxor xmm0, xmm0  ; sum = 0
    
    ; Initialize inner loop counter
    xor r12, r12  ; k = 0
.inner_loop:
    cmp r12, r8   ; k < cols_A
    jge .store_result
    
    ; Load A[i][k]
    mov rax, r10
    mul r8        ; rax = i * cols_A
    add rax, r12  ; rax = i * cols_A + k
    movss xmm1, [rdi + rax * 4]  ; xmm1 = A[i][k]
    
    ; Load B[k][j]
    mov rax, r12
    mul r9        ; rax = k * cols_B
    add rax, r11  ; rax = k * cols_B + j
    movss xmm2, [rsi + rax * 4]  ; xmm2 = B[k][j]
    
    ; Multiply and add to sum
    mulss xmm1, xmm2
    addss xmm0, xmm1
    
    inc r12
    jmp .inner_loop
    
.store_result:
    ; Store C[i][j]
    mov rax, r10
    mul r9        ; rax = i * cols_B
    add rax, r11  ; rax = i * cols_B + j
    movss [rdx + rax * 4], xmm0
    
    inc r11
    jmp .middle_loop
    
.next_i:
    inc r10
    jmp .outer_loop
    
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

    ; Memory copy: dest = src
    ; rdi = destination pointer
    ; rsi = source pointer
    ; rdx = number of bytes
memcpy:
    push rbp
    mov rbp, rsp
    push rbx
    
    mov rcx, rdx  ; size
    mov rbx, rdi  ; save destination
    
    ; Copy data
    rep movsb
    
    mov rax, rbx  ; return destination
    
    pop rbx
    pop rbp
    ret

    ; Generate random float in [0,1]
    ; Returns: xmm0 = random float
rand_float:
    push rbp
    mov rbp, rsp
    
    ; Update seed
    mov rax, [rel rand_seed]
    mov rcx, 6364136223846793005
    mul rcx
    add rax, 1
    mov [rel rand_seed], rax
    
    ; Convert to float
    cvtsi2ss xmm0, rax
    movss xmm1, [rel rand_seed]
    divss xmm0, xmm1
    
    pop rbp
    ret

    ; Generate random number from normal distribution
    ; Returns: xmm0 = random float
rand_normal:
    push rbp
    mov rbp, rsp
    
    ; Generate two uniform random numbers
    call rand_float
    movss xmm1, xmm0  ; u1
    call rand_float   ; u2
    
    ; Box-Muller transform
    movss xmm2, [rel two_pi]
    mulss xmm0, xmm2  ; u2 * 2π
    cvtsi2ss xmm2, dword [rel rand_seed]
    mulss xmm1, xmm2  ; u1 * seed
    
    ; Calculate z0 using sine approximation
    sqrtss xmm1, xmm1
    ; Use sine approximation: sin(x) ≈ x - x^3/6 + x^5/120
    movss xmm3, xmm0    ; x
    mulss xmm3, xmm3    ; x^2
    mulss xmm3, xmm0    ; x^3
    movss xmm4, xmm3    ; x^3
    mulss xmm4, xmm3    ; x^5
    movss xmm5, xmm4    ; x^5
    divss xmm4, [rel six]  ; x^3/6
    divss xmm5, [rel one_twenty]  ; x^5/120
    subss xmm0, xmm4    ; x - x^3/6
    addss xmm0, xmm5    ; + x^5/120
    mulss xmm0, xmm1    ; * sqrt(-2*ln(u1))
    
    pop rbp
    ret

    ; Matrix transpose: B = A^T
    ; rdi = A matrix pointer
    ; rsi = B matrix pointer
    ; rdx = rows of A
    ; rcx = cols of A
matrix_transpose:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    ; Initialize loop counters
    xor r8, r8  ; i = 0
.outer_loop:
    cmp r8, rdx  ; i < rows_A
    jge .done
    
    xor r9, r9  ; j = 0
.inner_loop:
    cmp r9, rcx  ; j < cols_A
    jge .next_i
    
    ; Load A[i][j]
    mov rax, r8
    mul rcx     ; rax = i * cols_A
    add rax, r9 ; rax = i * cols_A + j
    movss xmm0, [rdi + rax * 4]
    
    ; Store B[j][i]
    mov rax, r9
    mul rdx     ; rax = j * rows_A
    add rax, r8 ; rax = j * rows_A + i
    movss [rsi + rax * 4], xmm0
    
    inc r9
    jmp .inner_loop
    
.next_i:
    inc r8
    jmp .outer_loop
    
.done:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

    ; Vector dot product: result = a · b
    ; rdi = a vector pointer
    ; rsi = b vector pointer
    ; rdx = vector length
    ; Returns: xmm0 = dot product
vector_dot_product:
    push rbp
    mov rbp, rsp
    
    ; Initialize sum
    pxor xmm0, xmm0  ; sum = 0
    
    ; Initialize counter
    xor rcx, rcx  ; i = 0
.loop:
    cmp rcx, rdx  ; i < length
    jge .done
    
    ; Load a[i] and b[i]
    movss xmm1, [rdi + rcx * 4]  ; xmm1 = a[i]
    movss xmm2, [rsi + rcx * 4]  ; xmm2 = b[i]
    
    ; Multiply and add to sum
    mulss xmm1, xmm2
    addss xmm0, xmm1
    
    inc rcx
    jmp .loop
    
.done:
    pop rbp
    ret 

; Placeholder: check if a termination signal has been issued
; Returns rax = 1 if termination requested, 0 otherwise
    global check_termination_signal
check_termination_signal:
    push rbp
    mov rbp, rsp
    xor rax, rax
    pop rbp
    ret

; Placeholder: check if an error condition has occurred
    global check_error_condition
check_error_condition:
    push rbp
    mov rbp, rsp
    xor rax, rax
    pop rbp
    ret

; Placeholder: check if the current goal condition has been met
    global check_goal_condition
check_goal_condition:
    push rbp
    mov rbp, rsp
    xor rax, rax
    pop rbp
    ret

; Combine component states into a single representation
    global combine_states
combine_states:
    push rbp
    mov rbp, rsp
    xor rax, rax
    pop rbp
    ret

; Dummy training routine for the neural network
    global train_network
train_network:
    push rbp
    mov rbp, rsp
    xor rax, rax
    pop rbp
    ret
