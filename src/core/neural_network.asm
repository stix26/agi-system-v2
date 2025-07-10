section .data
    ; Neural network configuration
    INPUT_SIZE equ 64
    HIDDEN_SIZE equ 128
    OUTPUT_SIZE equ 32
    
    ; Weight matrices (aligned for SIMD)
    align 32
    input_weights: times (INPUT_SIZE * HIDDEN_SIZE) dd 0.0
    hidden_weights: times (HIDDEN_SIZE * OUTPUT_SIZE) dd 0.0
    
    ; Bias vectors
    align 32
    hidden_bias: times HIDDEN_SIZE dd 0.0
    output_bias: times OUTPUT_SIZE dd 0.0
    
    ; Activation buffers
    align 32
    input_layer: times INPUT_SIZE dd 0.0
    hidden_layer: times HIDDEN_SIZE dd 0.0
    output_layer: times OUTPUT_SIZE dd 0.0
    
    ; Gradient buffers
    align 32
    hidden_gradients: times HIDDEN_SIZE dd 0.0
    output_gradients: times OUTPUT_SIZE dd 0.0
    
    ; Learning parameters
    learning_rate dd 0.001
    momentum dd 0.9
    weight_decay dd 0.0001
    
    ; SIMD constants
    align 32
    ones: times 8 dd 1.0
    zeros: times 8 dd 0.0
    relu_threshold: times 8 dd 0.0

section .text
    global neural_network_main
    global neural_network_init
    global forward_propagation
    global backpropagation
    global update_weights
    global relu_activation
    global softmax_activation
    global train_network
    extern rand_normal

; Initialize neural network with Xavier initialization
neural_network_init:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Initialize input-to-hidden weights
    lea rdi, [rel input_weights]
    mov rsi, INPUT_SIZE
    mov rdx, HIDDEN_SIZE
    call xavier_initialize_matrix
    
    ; Initialize hidden-to-output weights
    lea rdi, [rel hidden_weights]
    mov rsi, HIDDEN_SIZE
    mov rdx, OUTPUT_SIZE
    call xavier_initialize_matrix
    
    ; Initialize biases to small random values
    lea rdi, [rel hidden_bias]
    mov rsi, HIDDEN_SIZE
    call initialize_bias_vector
    
    lea rdi, [rel output_bias]
    mov rsi, OUTPUT_SIZE
    call initialize_bias_vector
    
    xor rax, rax  ; Return success
    mov rsp, rbp
    pop rbp
    ret

; Main neural network processing function
neural_network_main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Parameters: rdi = input data, rsi = expected output, rdx = output buffer
    mov [rsp], rdi      ; Save input
    mov [rsp+8], rsi    ; Save expected
    mov [rsp+16], rdx   ; Save output buffer
    
    ; Forward propagation
    call forward_propagation
    test rax, rax
    jnz .error
    
    ; Calculate loss and gradients if training
    cmp qword [rsp+8], 0
    je .inference_only
    
    ; Backpropagation
    mov rdi, [rsp+8]    ; Expected output
    call backpropagation
    test rax, rax
    jnz .error
    
    ; Update weights
    call update_weights
    
.inference_only:
    ; Copy output
    mov rdi, [rsp+16]   ; Output buffer
    lea rsi, [rel output_layer]
    mov rcx, OUTPUT_SIZE
    call copy_output_data
    
    xor rax, rax        ; Success
    jmp .done
    
.error:
    mov rax, -1         ; Error
    
.done:
    mov rsp, rbp
    pop rbp
    ret

; Optimized forward propagation with SIMD
forward_propagation:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Input to hidden layer transformation
    lea rdi, [rel input_layer]     ; Input
    lea rsi, [rel input_weights]   ; Weights
    lea rdx, [rel hidden_bias]     ; Bias
    lea rcx, [rel hidden_layer]    ; Output
    mov r8, INPUT_SIZE
    mov r9, HIDDEN_SIZE
    call simd_matrix_multiply_add_bias
    
    ; Apply ReLU activation to hidden layer
    lea rdi, [rel hidden_layer]
    mov rsi, HIDDEN_SIZE
    call relu_activation
    
    ; Hidden to output layer transformation
    lea rdi, [rel hidden_layer]    ; Input
    lea rsi, [rel hidden_weights]  ; Weights
    lea rdx, [rel output_bias]     ; Bias
    lea rcx, [rel output_layer]    ; Output
    mov r8, HIDDEN_SIZE
    mov r9, OUTPUT_SIZE
    call simd_matrix_multiply_add_bias
    
    ; Apply softmax activation to output layer
    lea rdi, [rel output_layer]
    mov rsi, OUTPUT_SIZE
    call softmax_activation
    
    xor rax, rax  ; Success
    mov rsp, rbp
    pop rbp
    ret

; SIMD-optimized matrix multiplication with bias addition
simd_matrix_multiply_add_bias:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    ; Parameters: rdi=input, rsi=weights, rdx=bias, rcx=output, r8=input_size, r9=output_size
    mov r10, r9         ; Output size
    xor r11, r11        ; Output index
    
.output_loop:
    cmp r11, r10
    jge .done
    
    ; Initialize accumulator
    vxorps ymm0, ymm0, ymm0
    
    ; Process 8 inputs at a time with AVX2
    xor r12, r12        ; Input index
    mov r13, r8         ; Input size
    and r13, -8         ; Round down to nearest 8
    
.simd_loop:
    cmp r12, r13
    jge .scalar_remainder
    
    ; Load 8 input values
    vmovups ymm1, [rdi + r12 * 4]
    
    ; Load corresponding 8 weights
    mov rax, r11
    imul rax, r8
    add rax, r12
    vmovups ymm2, [rsi + rax * 4]
    
    ; Multiply and accumulate
    vfmadd231ps ymm0, ymm1, ymm2
    
    add r12, 8
    jmp .simd_loop
    
.scalar_remainder:
    ; Handle remaining elements
    cmp r12, r8
    jge .sum_accumulator
    
    movss xmm1, [rdi + r12 * 4]
    mov rax, r11
    imul rax, r8
    add rax, r12
    movss xmm2, [rsi + rax * 4]
    mulss xmm1, xmm2
    addss xmm0, xmm1
    
    inc r12
    jmp .scalar_remainder
    
.sum_accumulator:
    ; Sum all elements in ymm0
    vextractf128 xmm1, ymm0, 1
    vaddps xmm0, xmm0, xmm1
    vhaddps xmm0, xmm0, xmm0
    vhaddps xmm0, xmm0, xmm0
    
    ; Add bias
    addss xmm0, [rdx + r11 * 4]
    
    ; Store result
    movss [rcx + r11 * 4], xmm0
    
    inc r11
    jmp .output_loop
    
.done:
    vzeroupper  ; Clear upper YMM registers
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Optimized ReLU activation with SIMD
relu_activation:
    push rbp
    mov rbp, rsp
    
    ; Parameters: rdi = data pointer, rsi = size
    mov rcx, rsi
    and rcx, -8         ; Process 8 elements at a time
    xor rax, rax
    
    ; Load zero threshold
    vxorps ymm1, ymm1, ymm1
    
.simd_loop:
    cmp rax, rcx
    jge .scalar_remainder
    
    ; Load 8 values
    vmovups ymm0, [rdi + rax * 4]
    
    ; Apply ReLU: max(0, x)
    vmaxps ymm0, ymm0, ymm1
    
    ; Store result
    vmovups [rdi + rax * 4], ymm0
    
    add rax, 8
    jmp .simd_loop
    
.scalar_remainder:
    ; Handle remaining elements
    cmp rax, rsi
    jge .done
    
    movss xmm0, [rdi + rax * 4]
    maxss xmm0, xmm1
    movss [rdi + rax * 4], xmm0
    
    inc rax
    jmp .scalar_remainder
    
.done:
    vzeroupper
    pop rbp
    ret

; Optimized softmax activation
softmax_activation:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Parameters: rdi = data pointer, rsi = size
    ; Find maximum value for numerical stability
    movss xmm0, [rdi]   ; max = first element
    mov rcx, 1
    
.find_max:
    cmp rcx, rsi
    jge .subtract_max
    
    movss xmm1, [rdi + rcx * 4]
    maxss xmm0, xmm1
    inc rcx
    jmp .find_max
    
.subtract_max:
    ; Subtract max and compute exp, accumulate sum
    vxorps xmm2, xmm2, xmm2  ; sum = 0
    xor rcx, rcx
    
.exp_loop:
    cmp rcx, rsi
    jge .normalize
    
    ; x[i] = x[i] - max
    movss xmm1, [rdi + rcx * 4]
    subss xmm1, xmm0
    
    ; Approximate exp(x) using Taylor series for small x
    ; exp(x) ≈ 1 + x + x²/2 + x³/6
    movss xmm3, xmm1    ; x
    movss xmm4, xmm1    ; x
    mulss xmm4, xmm1    ; x²
    movss xmm5, xmm4    ; x²
    mulss xmm5, xmm1    ; x³
    
    ; Build approximation
    movss xmm6, dword [rel ones]  ; 1
    addss xmm6, xmm3              ; 1 + x
    movss xmm7, dword [rel ones + 4]  ; 0.5
    mulss xmm7, xmm4              ; x²/2
    addss xmm6, xmm7              ; 1 + x + x²/2
    movss xmm7, dword [rel ones + 8]  ; 1/6 ≈ 0.1667
    mulss xmm7, xmm5              ; x³/6
    addss xmm6, xmm7              ; final approximation
    
    ; Store exp value
    movss [rdi + rcx * 4], xmm6
    
    ; Add to sum
    addss xmm2, xmm6
    
    inc rcx
    jmp .exp_loop
    
.normalize:
    ; Divide all values by sum
    xor rcx, rcx
    
.normalize_loop:
    cmp rcx, rsi
    jge .done
    
    movss xmm0, [rdi + rcx * 4]
    divss xmm0, xmm2
    movss [rdi + rcx * 4], xmm0
    
    inc rcx
    jmp .normalize_loop
    
.done:
    mov rsp, rbp
    pop rbp
    ret

; Backpropagation implementation
backpropagation:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Parameters: rdi = expected output
    ; Calculate output layer gradients (cross-entropy loss)
    lea rsi, [rel output_layer]
    lea rdx, [rel output_gradients]
    mov rcx, OUTPUT_SIZE
    
.output_grad_loop:
    cmp rcx, 0
    jle .hidden_gradients
    
    dec rcx
    movss xmm0, [rsi + rcx * 4]    ; predicted
    movss xmm1, [rdi + rcx * 4]    ; expected
    subss xmm0, xmm1               ; predicted - expected
    movss [rdx + rcx * 4], xmm0    ; store gradient
    
    jmp .output_grad_loop
    
.hidden_gradients:
    ; Calculate hidden layer gradients
    ; gradient = (weights^T * output_gradients) * relu_derivative
    lea rdi, [rel hidden_gradients]
    lea rsi, [rel hidden_weights]
    lea rdx, [rel output_gradients]
    lea rcx, [rel hidden_layer]
    mov r8, HIDDEN_SIZE
    mov r9, OUTPUT_SIZE
    call calculate_hidden_gradients
    
    xor rax, rax  ; Success
    mov rsp, rbp
    pop rbp
    ret

; Update weights using gradients
update_weights:
    push rbp
    mov rbp, rsp
    
    ; Update hidden-to-output weights
    lea rdi, [rel hidden_weights]
    lea rsi, [rel hidden_layer]
    lea rdx, [rel output_gradients]
    mov rcx, HIDDEN_SIZE
    mov r8, OUTPUT_SIZE
    call update_weight_matrix
    
    ; Update input-to-hidden weights
    lea rdi, [rel input_weights]
    lea rsi, [rel input_layer]
    lea rdx, [rel hidden_gradients]
    mov rcx, INPUT_SIZE
    mov r8, HIDDEN_SIZE
    call update_weight_matrix
    
    xor rax, rax  ; Success
    pop rbp
    ret

; Copy output data function
copy_output_data:
    push rbp
    mov rbp, rsp
    
    ; Parameters: rdi = destination, rsi = source, rcx = count (in floats)
    test rcx, rcx
    jz .done
    
.copy_loop:
    movss xmm0, [rsi]
    movss [rdi], xmm0
    add rsi, 4
    add rdi, 4
    dec rcx
    jnz .copy_loop
    
.done:
    pop rbp
    ret

; Helper functions (stubs for now, can be expanded)
xavier_initialize_matrix:
calculate_hidden_gradients:
initialize_bias_vector:
update_weight_matrix:
train_network:
    push rbp
    mov rbp, rsp
    xor rax, rax
    pop rbp
    ret
