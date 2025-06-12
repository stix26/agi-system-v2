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
    global cleanup_decision
    global decision_init
    global decision_process

; Simple stubs returning success
init_decision_engine:
select_action:
update_policy:
get_decision_state:
get_decision_action:
apply_action_constraints:
shutdown_decision:
cleanup_decision_engine:
init_decision:
make_decision:
add_option:
remove_option:
cleanup_decision:
decision_init:
decision_process:
    push rbp
    mov rbp, rsp
    xor rax, rax
    pop rbp
    ret
