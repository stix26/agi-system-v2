section .data
    memory_size db 1024
    stack_size db 256
    learning_rate db 0.01
    logging_enabled db 1
    log_file_path db "logs/agi.log", 0

section .text
    global init_config

init_config:
    ; Load memory settings
    mov rax, memory_size
    mov rbx, stack_size

    ; Load neural network settings
    mov rcx, learning_rate

    ; Load logging settings
    mov rdx, logging_enabled
    mov rsi, log_file_path

    ret
