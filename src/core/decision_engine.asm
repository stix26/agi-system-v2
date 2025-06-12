section .data
    decision_msg db "Decision made: Task executed.", 0
    
    ; Decision engine configuration
    state_size equ 256
    action_size equ 64
    reward_size equ 32
    
    ; Q-learning parameters
    learning_rate dq 0.1
    discount_factor dq 0.9
    exploration_rate dq 0.1
    
    ; Meta-cognition parameters
    meta_learning_rate dq 0.01
    confidence_threshold dq 0.8
    
    ; State and action spaces
    current_state: times state_size dq 0
    next_state: times state_size dq 0
    current_action: times action_size dq 0
    current_reward: times reward_size dq 0
    
    ; Q-table
    q_table: times (state_size * action_size) dq 0
    
    ; Meta-cognition structures
    struc MetaState
        .confidence:    resq 1    ; Confidence in current state
        .uncertainty:   resq 1    ; Uncertainty measure
        .learning_rate: resq 1    ; Adaptive learning rate
        .exploration:   resq 1    ; Exploration rate
    endstruc
    
    current_meta_state: istruc MetaState
        at MetaState.confidence,    dq 0.5
        at MetaState.uncertainty,   dq 0.5
        at MetaState.learning_rate, dq 0.1
        at MetaState.exploration,   dq 0.1
    iend

section .text
    global decision_engine_main
    global select_action
    global update_q_value
    global meta_cognition_update
    global calculate_reward
    global adapt_parameters
    extern write_output

decision_engine_main:
    mov rdi, decision_msg
    call write_output
    ret

; Select action using epsilon-greedy policy with meta-cognition
select_action:
    push rbp
    mov rbp, rsp
    
    ; Get exploration rate from meta-state
    movsd xmm0, [current_meta_state + MetaState.exploration]
    
    ; Generate random number
    call rand_double
    comisd xmm0, xmm1
    jb .exploit
    
    ; Exploration: select random action
    call select_random_action
    jmp .done
    
.exploit:
    ; Exploitation: select best action from Q-table
    call select_best_action
    
.done:
    pop rbp
    ret

; Update Q-value using Q-learning with meta-cognition
update_q_value:
    push rbp
    mov rbp, rsp
    
    ; Get current Q-value
    call get_q_value
    
    ; Get next state's maximum Q-value
    call get_max_q_value
    
    ; Calculate temporal difference
    movsd xmm0, [current_reward]
    movsd xmm1, [discount_factor]
    mulsd xmm1, [next_max_q_value]
    addsd xmm0, xmm1
    subsd xmm0, [current_q_value]
    
    ; Get adaptive learning rate from meta-state
    movsd xmm1, [current_meta_state + MetaState.learning_rate]
    mulsd xmm0, xmm1
    
    ; Update Q-value
    addsd [current_q_value], xmm0
    
    pop rbp
    ret

; Meta-cognition update
meta_cognition_update:
    push rbp
    mov rbp, rsp
    
    ; Update confidence based on prediction accuracy
    call calculate_prediction_accuracy
    movsd xmm0, [prediction_accuracy]
    movsd [current_meta_state + MetaState.confidence], xmm0
    
    ; Update uncertainty based on state novelty
    call calculate_state_novelty
    movsd xmm0, [state_novelty]
    movsd [current_meta_state + MetaState.uncertainty], xmm0
    
    ; Adapt learning rate based on confidence and uncertainty
    call adapt_learning_rate
    
    ; Adapt exploration rate based on performance
    call adapt_exploration_rate
    
    pop rbp
    ret

; Calculate reward with meta-cognition
calculate_reward:
    push rbp
    mov rbp, rsp
    
    ; Get base reward
    call get_base_reward
    
    ; Adjust reward based on meta-cognition
    movsd xmm0, [current_meta_state + MetaState.confidence]
    mulsd [current_reward], xmm0
    
    ; Add exploration bonus
    movsd xmm0, [current_meta_state + MetaState.uncertainty]
    mulsd xmm0, [exploration_bonus]
    addsd [current_reward], xmm0
    
    pop rbp
    ret

; Adapt parameters based on performance
adapt_parameters:
    push rbp
    mov rbp, rsp
    
    ; Calculate performance metrics
    call calculate_performance_metrics
    
    ; Adapt learning rate
    movsd xmm0, [performance_improvement]
    movsd xmm1, [current_meta_state + MetaState.learning_rate]
    mulsd xmm1, xmm0
    movsd [current_meta_state + MetaState.learning_rate], xmm1
    
    ; Adapt exploration rate
    movsd xmm0, [exploration_effectiveness]
    movsd xmm1, [current_meta_state + MetaState.exploration]
    mulsd xmm1, xmm0
    movsd [current_meta_state + MetaState.exploration], xmm1
    
    pop rbp
    ret

; Helper function to generate random double
rand_double:
    push rbp
    mov rbp, rsp
    
    ; Get random number
    rdrand rax
    
    ; Convert to double between 0 and 1
    cvtsi2sd xmm0, rax
    movsd xmm1, [double_max]
    divsd xmm0, xmm1
    
    pop rbp
    ret
