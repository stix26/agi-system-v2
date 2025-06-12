section .data
    ; Decision engine configuration
    state_dimension equ 64
    action_dimension equ 32
    num_actions equ 16
    
    ; Q-learning parameters
    learning_rate dq 0.1
    discount_factor dq 0.9
    exploration_rate dq 0.1
    
    ; Q-table and buffers
    q_table: times (state_dimension * num_actions) dd 0
    current_state: times state_dimension dd 0
    next_state: times state_dimension dd 0
    current_action: times action_dimension dd 0
    next_action: times action_dimension dd 0
    
    ; Performance tracking
    total_reward dq 0
    episode_count dq 0
    step_count dq 0

    ; Decision constants
    max_decisions equ 1024
    max_options equ 64
    max_weights equ 256

    ; Decision engine configuration
    decision_threshold dq 0.5
    decision_learning_rate dq 0.01
    
    ; Error messages
    error_msg db "Error: Decision processing failed", 10
    error_msg_len equ $ - error_msg

section .bss
    ; Decision structures
    decision_table resq max_decisions
    option_table resq max_options
    weight_table resq max_weights
    num_decisions resq 1
    num_options resq 1
    num_weights resq 1

section .text
    global init_decision_engine
    global select_action
    global update_policy
    global get_decision_state
    global get_decision_action
    global apply_action_constraints
    global shutdown_decision
    global cleanup_decision_engine
    global init_decision
    global make_decision
    global add_option
    global remove_option
    global update_weights
    global cleanup_decision
    global decision_init
    global decision_process
    extern memcpy
    extern matrix_multiply
    
    ; Initialize decision engine
init_decision_engine:
    push rbp
    mov rbp, rsp
    
    ; Initialize Q-table
    lea rdi, [rel q_table]
    mov rcx, state_dimension * num_actions
    call init_q_table
    
    ; Initialize state buffers
    lea rdi, [rel current_state]
    mov rcx, state_dimension
    xor rax, rax
    rep stosd
    
    lea rdi, [rel next_state]
    mov rcx, state_dimension
    rep stosd
    
    ; Initialize action buffers
    lea rdi, [rel current_action]
    mov rcx, action_dimension
    rep stosd
    
    lea rdi, [rel next_action]
    mov rcx, action_dimension
    rep stosd
    
    ; Reset performance tracking
    mov qword [rel total_reward], 0
    mov qword [rel episode_count], 0
    mov qword [rel step_count], 0
    
    xor rax, rax  ; Return success
    pop rbp
    ret

    ; Select action based on current state
select_action:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = state pointer
    ; rsi = output action buffer
    
    ; Copy current state
    lea rcx, [rel current_state]
    mov rdx, state_dimension * 4
    call memcpy
    
    ; Check exploration vs exploitation
    call rand_float
    movss xmm1, [rel exploration_rate]
    comiss xmm0, xmm1
    jae .exploit
    
    ; Exploration: select random action
    call select_random_action
    jmp .done
    
.exploit:
    ; Exploitation: select best action
    call select_best_action
    
.done:
    ; Copy selected action to output buffer
    mov rdi, rsi
    lea rsi, [rel current_action]
    mov rdx, action_dimension * 4
    call memcpy
    
    xor rax, rax  ; Return success
    pop rbp
    ret

    ; Update policy based on experience
update_policy:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = next state pointer
    ; rsi = reward
    ; rdx = done flag
    
    ; Copy next state
    lea rcx, [rel next_state]
    mov r8, state_dimension * 4
    call memcpy
    
    ; Update Q-value
    movss xmm0, [rel learning_rate]
    movss xmm1, [rel discount_factor]
    
    ; Get current Q-value
    lea rdi, [rel current_state]
    lea rsi, [rel current_action]
    call get_q_value
    
    ; Get next Q-value
    lea rdi, [rel next_state]
    call get_max_q_value
    
    ; Update Q-value using Q-learning formula
    ; Q(s,a) = Q(s,a) + α[r + γ max Q(s',a') - Q(s,a)]
    movss xmm2, xmm0  ; Current Q-value
    movss xmm3, xmm1  ; Next Q-value
    mulss xmm3, [rel discount_factor]
    addss xmm3, rsi  ; Add reward
    subss xmm3, xmm2  ; Subtract current Q-value
    mulss xmm3, [rel learning_rate]
    addss xmm2, xmm3  ; Add update
    
    ; Store updated Q-value
    lea rdi, [rel current_state]
    lea rsi, [rel current_action]
    call set_q_value
    
    ; Update performance tracking
    add [rel total_reward], rsi
    inc qword [rel step_count]
    
    ; Check if episode is done
    test rdx, rdx
    jz .done
    
    ; Reset for next episode
    inc qword [rel episode_count]
    mov qword [rel step_count], 0
    
.done:
    xor rax, rax  ; Return success
    pop rbp
    ret

    ; Get current decision state
get_decision_state:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = output buffer
    
    ; Copy current state
    lea rsi, [rel current_state]
    mov rdx, state_dimension * 4
    call memcpy
    
    xor rax, rax  ; Return success
    pop rbp
    ret

    ; Get current decision action
get_decision_action:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = output buffer
    
    ; Copy current action
    lea rsi, [rel current_action]
    mov rdx, action_dimension * 4
    call memcpy
    
    xor rax, rax  ; Return success
    pop rbp
    ret

    ; Apply constraints to action
apply_action_constraints:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = action pointer
    ; rsi = constraints pointer
    
    ; Apply constraints to action values
    mov rcx, action_dimension
.constraint_loop:
    movss xmm0, [rdi + rcx * 4 - 4]
    movss xmm1, [rsi + rcx * 4 - 4]
    minss xmm0, xmm1
    movss [rdi + rcx * 4 - 4], xmm0
    loop .constraint_loop
    
    xor rax, rax  ; Return success
    pop rbp
    ret

    ; Shutdown decision engine
shutdown_decision:
    push rbp
    mov rbp, rsp
    
    ; Save final statistics
    lea rdi, [rel total_reward]
    lea rsi, [rel episode_count]
    lea rdx, [rel step_count]
    call save_statistics
    
    xor rax, rax  ; Return success
    pop rbp
    ret

    ; Cleanup decision engine
cleanup_decision_engine:
    push rbp
    mov rbp, rsp
    
    ; Clear Q-table
    lea rdi, [rel q_table]
    mov rcx, state_dimension * num_actions
    xor rax, rax
    rep stosd
    
    ; Clear state buffers
    lea rdi, [rel current_state]
    mov rcx, state_dimension
    rep stosd
    
    lea rdi, [rel next_state]
    mov rcx, state_dimension
    rep stosd
    
    ; Clear action buffers
    lea rdi, [rel current_action]
    mov rcx, action_dimension
    rep stosd
    
    lea rdi, [rel next_action]
    mov rcx, action_dimension
    rep stosd
    
    ; Reset performance tracking
    mov qword [rel total_reward], 0
    mov qword [rel episode_count], 0
    mov qword [rel step_count], 0
    
    xor rax, rax  ; Return success
    pop rbp
    ret

    ; Helper functions
init_q_table:
    push rbp
    mov rbp, rsp
    
    ; Initialize Q-values to small random values
    mov rcx, state_dimension * num_actions
.init_loop:
    call rand_float
    mulss xmm0, [rel learning_rate]
    movss [rdi + rcx * 4 - 4], xmm0
    loop .init_loop
    
    pop rbp
    ret

select_best_action:
    push rbp
    mov rbp, rsp
    
    ; Find action with highest Q-value
    lea rdi, [rel current_state]
    call get_max_q_value
    
    ; Store best action
    lea rdi, [rel current_action]
    mov rcx, action_dimension
    rep movsd
    
    pop rbp
    ret

select_random_action:
    push rbp
    mov rbp, rsp
    
    ; Generate random action
    lea rdi, [rel current_action]
    mov rcx, action_dimension
.random_loop:
    call rand_float
    movss [rdi + rcx * 4 - 4], xmm0
    loop .random_loop
    
    pop rbp
    ret

get_q_value:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = state pointer
    ; rsi = action pointer
    
    ; Compute Q-table index
    mov rcx, rdi
    imul rcx, num_actions
    add rcx, rsi
    
    ; Get Q-value
    movss xmm0, [rel q_table + rcx * 4]
    
    pop rbp
    ret

get_max_q_value:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = state pointer
    
    ; Find maximum Q-value for state
    mov rcx, num_actions
    xorps xmm0, xmm0
.max_loop:
    movss xmm1, [rel q_table + rdi * num_actions * 4 + rcx * 4 - 4]
    maxss xmm0, xmm1
    loop .max_loop
    
    pop rbp
    ret

set_q_value:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = state pointer
    ; rsi = action pointer
    ; xmm0 = new Q-value
    
    ; Compute Q-table index
    mov rcx, rdi
    imul rcx, num_actions
    add rcx, rsi
    
    ; Set Q-value
    movss [rel q_table + rcx * 4], xmm0
    
    pop rbp
    ret

save_statistics:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = total reward pointer
    ; rsi = episode count pointer
    ; rdx = step count pointer
    
    ; Save statistics to file or memory
    ; Implementation depends on system requirements
    
    pop rbp
    ret

    ; Initialize decision system
init_decision:
    push rbp
    mov rbp, rsp
    
    ; Initialize decision table
    mov rcx, max_decisions
    xor rax, rax
.init_decisions:
    mov [rel decision_table + rcx * 8 - 8], rax
    loop .init_decisions
    
    ; Initialize option table
    mov rcx, max_options
.init_options:
    mov [rel option_table + rcx * 8 - 8], rax
    loop .init_options
    
    ; Initialize weight table
    mov rcx, max_weights
.init_weights:
    mov [rel weight_table + rcx * 8 - 8], rax
    loop .init_weights
    
    ; Initialize counters
    mov qword [rel num_decisions], 0
    mov qword [rel num_options], 0
    mov qword [rel num_weights], 0
    
    pop rbp
    ret

    ; Make a decision
make_decision:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    ; Save parameters
    mov rbx, rdi  ; decision index
    mov r12, rsi  ; context
    
    ; Validate decision index
    cmp rbx, max_decisions
    jae .invalid
    
    ; Get decision
    mov rax, [rel decision_table + rbx * 8]
    test rax, rax
    jz .invalid
    
    ; Calculate weighted sum
    xor rcx, rcx  ; i = 0
    pxor xmm0, xmm0  ; sum = 0
.sum_loop:
    cmp rcx, [rel num_weights]
    jge .done_sum
    
    ; Get weight
    mov rax, [rel weight_table + rcx * 8]
    movsd xmm1, [rax]
    
    ; Get option value
    mov rax, [rel option_table + rcx * 8]
    movsd xmm2, [rax]
    
    ; Multiply and add
    mulsd xmm1, xmm2
    addsd xmm0, xmm1
    
    inc rcx
    jmp .sum_loop
    
.done_sum:
    ; Return decision
    mov rax, rbx
    jmp .done
    
.invalid:
    mov rax, -1
    
.done:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

    ; Add an option
add_option:
    push rbp
    mov rbp, rsp
    
    ; Check if we have space
    mov rax, [rel num_options]
    cmp rax, max_options
    jae .full
    
    ; Add option
    mov [rel option_table + rax * 8], rdi
    inc qword [rel num_options]
    
    ; Return option index
    mov rax, [rel num_options]
    dec rax
    jmp .done
    
.full:
    mov rax, -1
    
.done:
    pop rbp
    ret

    ; Remove an option
remove_option:
    push rbp
    mov rbp, rsp
    
    ; Validate option index
    cmp rdi, max_options
    jae .invalid
    
    ; Get last option
    mov rax, [rel num_options]
    dec rax
    mov rcx, [rel option_table + rax * 8]
    
    ; Move last option to removed position
    mov [rel option_table + rdi * 8], rcx
    
    ; Clear last option
    mov qword [rel option_table + rax * 8], 0
    
    ; Decrement counter
    dec qword [rel num_options]
    
    xor rax, rax  ; Return success
    jmp .done
    
.invalid:
    mov rax, -1
    
.done:
    pop rbp
    ret

    ; Update weights
update_weights:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    ; Save parameters
    mov rbx, rdi  ; weights
    mov r12, rsi  ; size
    
    ; Validate size
    cmp r12, max_weights
    ja .invalid
    
    ; Copy weights
    mov rdi, [rel weight_table]
    mov rsi, rbx
    mov rdx, r12
    shl rdx, 3  ; multiply by 8 (size of double)
    call memcpy
    
    ; Update counter
    mov [rel num_weights], r12
    
    xor rax, rax  ; Return success
    jmp .done
    
.invalid:
    mov rax, -1
    
.done:
    pop r12
    pop rbx
    pop rbp
    ret

    ; Cleanup decision system
cleanup_decision:
    push rbp
    mov rbp, rsp
    
    ; Clear decision table
    mov rcx, max_decisions
    xor rax, rax
.clear_decisions:
    mov [rel decision_table + rcx * 8 - 8], rax
    loop .clear_decisions
    
    ; Clear option table
    mov rcx, max_options
.clear_options:
    mov [rel option_table + rcx * 8 - 8], rax
    loop .clear_options
    
    ; Clear weight table
    mov rcx, max_weights
.clear_weights:
    mov [rel weight_table + rcx * 8 - 8], rax
    loop .clear_weights
    
    ; Reset counters
    mov qword [rel num_decisions], 0
    mov qword [rel num_options], 0
    mov qword [rel num_weights], 0
    
    pop rbp
    ret

decision_init:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Initialize decision engine
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret

decision_process:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Save input parameters
    mov [rsp], rdi    ; input buffer
    mov [rsp+8], rsi  ; input size
    
    ; Process input using matrix operations
    mov rdi, [rsp]    ; input buffer
    mov rsi, [rsp+8]  ; input size
    call matrix_multiply
    
    ; Return result
    mov rsp, rbp
    pop rbp
    ret 