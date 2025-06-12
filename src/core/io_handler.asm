section .text
    global io_init
    global read_input
    global write_output
    global process_neural_input
    global format_output
    global io_process
    global shutdown_io
    global cleanup_io_handler

io_init:
read_input:
process_neural_input:
format_output:
io_process:
shutdown_io:
cleanup_io_handler:
    push rbp
    mov rbp, rsp
    xor rax, rax
    pop rbp
    ret

; Write output buffer to stdout
; rdi = buffer pointer
; rsi = buffer size
write_output:
    push rbp
    mov rbp, rsp
    mov rax, 1          ; syscall: write
    mov rdx, rsi        ; length
    mov rsi, rdi        ; buffer pointer
    mov rdi, 1          ; stdout
    syscall
    xor rax, rax        ; return success
    pop rbp
    ret
