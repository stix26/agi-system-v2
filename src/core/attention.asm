section .data
    ; Attention configuration
    attention_dimension equ 64
    num_heads equ 8
    attention_scale dq 0.125  ; 1/sqrt(attention_dimension)
    
    ; Weight matrices
    query_weights: times (attention_dimension * attention_dimension) dd 0
    key_weights: times (attention_dimension * attention_dimension) dd 0
    value_weights: times (attention_dimension * attention_dimension) dd 0
    
    ; Buffers
    attention_scores: times (num_heads * attention_dimension) dd 0
    attention_output: times (attention_dimension) dd 0
    
    ; Learning parameters
    learning_rate dq 0.001
    gradient_buffer: times (attention_dimension * attention_dimension) dd 0

section .text
    global attention_init
    global attention_process
    global update_attention_weights
    global get_attention_state
    extern memcpy
    extern matrix_multiply
    extern rand_normal
    
    ; Initialize attention mechanism
attention_init:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Initialize query weights
    lea rdi, [rel query_weights]
    mov rsi, attention_dimension
    mov rdx, attention_dimension
    call xavier_init
    
    ; Initialize key weights
    lea rdi, [rel key_weights]
    mov rsi, attention_dimension
    mov rdx, attention_dimension
    call xavier_init
    
    ; Initialize value weights
    lea rdi, [rel value_weights]
    mov rsi, attention_dimension
    mov rdx, attention_dimension
    call xavier_init
    
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret

    ; Compute attention scores and output
attention_process:
    push rbp
    mov rbp, rsp
    xor rax, rax
    pop rbp
    ret

    ; Update attention weights
update_attention_weights:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = gradient buffer
    ; rsi = learning rate
    
    ; Update query weights
    lea rdx, [rel query_weights]
    mov rcx, attention_dimension
    mov r8, attention_dimension
    call update_weights
    
    ; Update key weights
    lea rdx, [rel key_weights]
    mov rcx, attention_dimension
    mov r8, attention_dimension
    call update_weights
    
    ; Update value weights
    lea rdx, [rel value_weights]
    mov rcx, attention_dimension
    mov r8, attention_dimension
    call update_weights
    
    xor rax, rax  ; Return success
    pop rbp
    ret

    ; Get current attention state
get_attention_state:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = output buffer for weights
    ; rsi = output buffer for scores
    ; rdx = output buffer for output
    
    ; Copy weights
    lea rcx, [rel query_weights]
    mov r8, attention_dimension * attention_dimension * 4
    call memcpy
    
    ; Copy scores
    lea rcx, [rel attention_scores]
    mov r8, num_heads * attention_dimension * 4
    call memcpy
    
    ; Copy output
    lea rcx, [rel attention_output]
    mov r8, attention_dimension * 4
    call memcpy
    
    xor rax, rax  ; Return success
    pop rbp
    ret

    ; Helper function: Xavier/Glorot initialization
xavier_init:
    push rbp
    mov rbp, rsp
    xor rax, rax
    pop rbp
    ret

    ; Apply attention to values
apply_attention:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Save parameters
    mov [rsp], rdi    ; input
    mov [rsp+8], rsi  ; size
    
    ; Generate attention weights
    call rand_normal
    
    ; Apply weights to input
    mov rdi, [rsp]    ; input
    mov rsi, [rsp+8]  ; size
    mov rdx, rax      ; weight
    call matrix_multiply
    
    ; Return result
    mov rsp, rbp
    pop rbp
    ret

    ; Update weights with gradient
update_weights:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = gradient buffer
    ; rsi = learning rate
    ; rdx = weight matrix
    ; rcx = rows
    ; r8 = cols
    
    ; Initialize loop counters
    xor r9, r9  ; i = 0
.outer_loop:
    cmp r9, rcx
    jge .done
    
    xor r10, r10  ; j = 0
.inner_loop:
    cmp r10, r8
    jge .next_i
    
    ; Calculate index
    mov rax, r9
    imul rax, r8
    add rax, r10
    
    ; Load gradient and weight
    movss xmm0, [rdi + rax * 4]  ; gradient
    movss xmm1, [rdx + rax * 4]  ; weight
    
    ; Update weight
    mulss xmm0, xmm1  ; gradient * learning_rate
    subss xmm1, xmm0
    movss [rdx + rax * 4], xmm1
    
    inc r10
    jmp .inner_loop
    
.next_i:
    inc r9
    jmp .outer_loop
    
.done:
    xor rax, rax  ; Return success
    pop rbp
    ret 
