section .text
    global init_memory_manager
    global consolidate_memories
    global cleanup_old_memories

init_memory_manager:
consolidate_memories:
cleanup_old_memories:
    push rbp
    mov rbp, rsp
    xor rax, rax
    pop rbp
    ret
