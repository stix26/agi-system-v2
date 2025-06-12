section .data
    ; Network architecture
    input_size equ 784    ; 28x28 input (e.g., for image processing)
    hidden_size equ 512   ; Hidden layer size
    output_size equ 10    ; Output layer size (e.g., for classification)
    
    ; Learning parameters
    learning_rate dq 0.001
    momentum dq 0.9
    
    ; Layer weights and biases
    weights1: times (input_size * hidden_size) dq 0
    biases1: times hidden_size dq 0
    weights2: times (hidden_size * output_size) dq 0
    biases2: times output_size dq 0
    
    ; Activation function constants
    relu_threshold dq 0.0
    
    ; Error tracking
    current_error dq 0.0
    best_error dq 999999.0
    
    ; Training state
    epoch_count dd 0
    max_epochs dd 1000
    
    ; Memory for backpropagation
    hidden_output: times hidden_size dq 0
    output_delta: times output_size dq 0
    hidden_delta: times hidden_size dq 0
    
    ; Momentum buffers
    weight1_momentum: times (input_size * hidden_size) dq 0
    weight2_momentum: times (hidden_size * output_size) dq 0

section .text
    global neural_network_main
    global forward_propagation
    global backpropagation
    global update_weights
    global relu_activation
    global softmax_activation
    
    ; Main neural network function
neural_network_main:
    push rbp
    mov rbp, rsp
    
    ; Initialize network
    call initialize_weights
    
    ; Training loop
.training_loop:
    ; Load input data
    mov rdi, input_data
    call forward_propagation
    
    ; Calculate error
    call calculate_error
    
    ; Backpropagation
    call backpropagation
    
    ; Update weights
    call update_weights
    
    ; Check convergence
    call check_convergence
    jnz .training_loop
    
    pop rbp
    ret

; Forward propagation through the network
forward_propagation:
    push rbp
    mov rbp, rsp
    
    ; First layer
    mov rdi, input_data
    mov rsi, weights1
    mov rdx, biases1
    mov rcx, hidden_output
    call matrix_multiply
    call relu_activation
    
    ; Second layer
    mov rdi, hidden_output
    mov rsi, weights2
    mov rdx, biases2
    mov rcx, output_data
    call matrix_multiply
    call softmax_activation
    
    pop rbp
    ret

; Backpropagation algorithm
backpropagation:
    push rbp
    mov rbp, rsp
    
    ; Calculate output layer delta
    mov rdi, output_data
    mov rsi, target_data
    mov rdx, output_delta
    call calculate_output_delta
    
    ; Calculate hidden layer delta
    mov rdi, output_delta
    mov rsi, weights2
    mov rdx, hidden_delta
    call calculate_hidden_delta
    
    pop rbp
    ret

; ReLU activation function
relu_activation:
    push rbp
    mov rbp, rsp
    
    mov rcx, hidden_size
.loop:
    movsd xmm0, [rdi + rcx * 8 - 8]
    xorpd xmm1, xmm1
    maxsd xmm0, xmm1
    movsd [rdi + rcx * 8 - 8], xmm0
    loop .loop
    
    pop rbp
    ret

; Softmax activation function
softmax_activation:
    push rbp
    mov rbp, rsp
    
    ; Calculate exponential sum
    xorpd xmm2, xmm2
    mov rcx, output_size
.sum_loop:
    movsd xmm0, [rdi + rcx * 8 - 8]
    call exp
    addsd xmm2, xmm0
    loop .sum_loop
    
    ; Normalize
    mov rcx, output_size
.norm_loop:
    movsd xmm0, [rdi + rcx * 8 - 8]
    call exp
    divsd xmm0, xmm2
    movsd [rdi + rcx * 8 - 8], xmm0
    loop .norm_loop
    
    pop rbp
    ret

; Update weights using gradient descent with momentum
update_weights:
    push rbp
    mov rbp, rsp
    
    ; Update first layer weights
    mov rdi, weights1
    mov rsi, weight1_momentum
    mov rdx, hidden_delta
    call update_layer_weights
    
    ; Update second layer weights
    mov rdi, weights2
    mov rsi, weight2_momentum
    mov rdx, output_delta
    call update_layer_weights
    
    pop rbp
    ret

; Initialize weights using Xavier/Glorot initialization
initialize_weights:
    push rbp
    mov rbp, rsp
    
    ; Initialize first layer weights
    mov rdi, weights1
    mov rsi, input_size
    mov rdx, hidden_size
    call xavier_init
    
    ; Initialize second layer weights
    mov rdi, weights2
    mov rsi, hidden_size
    mov rdx, output_size
    call xavier_init
    
    pop rbp
    ret

; Xavier/Glorot initialization
xavier_init:
    push rbp
    mov rbp, rsp
    
    ; Calculate scaling factor
    cvtsi2sd xmm0, rsi
    cvtsi2sd xmm1, rdx
    mulsd xmm0, xmm1
    sqrtsd xmm0, xmm0
    movsd xmm1, [relu_threshold]
    divsd xmm1, xmm0
    
    ; Initialize weights
    mov rcx, rsi
    imul rcx, rdx
.init_loop:
    call rand_normal
    mulsd xmm0, xmm1
    movsd [rdi + rcx * 8 - 8], xmm0
    loop .init_loop
    
    pop rbp
    ret