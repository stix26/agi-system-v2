section .data
    ; I/O configuration
    input_buffer_size equ 4096
    output_buffer_size equ 4096
    max_connections equ 10
    
    ; I/O buffers
    input_buffer: times input_buffer_size db 0
    output_buffer: times output_buffer_size db 0
    
    ; Connection structures
    struc Connection
        .fd:          resd 1    ; File descriptor
        .type:        resd 1    ; Connection type
        .status:      resd 1    ; Connection status
        .buffer:      resq 1    ; Buffer pointer
        .buffer_size: resq 1    ; Buffer size
        .bytes_read:  resq 1    ; Bytes read/written
    endstruc
    
    ; Connection types
    CONNECTION_TYPE_FILE equ 1
    CONNECTION_TYPE_NETWORK equ 2
    CONNECTION_TYPE_MEMORY equ 3
    
    ; Connection status
    CONNECTION_STATUS_ACTIVE equ 1
    CONNECTION_STATUS_CLOSED equ 2
    CONNECTION_STATUS_ERROR equ 3
    
    ; Active connections
    connections: times (max_connections * Connection_size) db 0
    active_connections dd 0
    
    ; I/O formats
    FORMAT_RAW equ 1
    FORMAT_JSON equ 2
    FORMAT_BINARY equ 3
    
    ; Error messages
    error_buffer_full db "Error: Buffer full", 10
    error_buffer_full_len equ $ - error_buffer_full
    error_connection_closed db "Error: Connection closed", 10
    error_connection_closed_len equ $ - error_connection_closed

section .text
    global io_handler_init
    global read_input
    global write_output
    global process_data
    global handle_connection
    global format_data
    
    ; Initialize I/O handler
io_handler_init:
    push rbp
    mov rbp, rsp
    
    ; Initialize connection structures
    mov rdi, connections
    mov rcx, max_connections
.init_connections:
    mov dword [rdi + Connection.status], CONNECTION_STATUS_CLOSED
    add rdi, Connection_size
    loop .init_connections
    
    ; Initialize active connections counter
    mov dword [active_connections], 0
    
    pop rbp
    ret

; Read input from all active connections
read_input:
    push rbp
    mov rbp, rsp
    
    ; Process each active connection
    mov rdi, connections
    mov ecx, [active_connections]
.process_connection:
    ; Check connection status
    cmp dword [rdi + Connection.status], CONNECTION_STATUS_ACTIVE
    jne .next_connection
    
    ; Read data from connection
    mov eax, 0          ; sys_read
    mov edi, [rdi + Connection.fd]
    mov rsi, [rdi + Connection.buffer]
    mov rdx, [rdi + Connection.buffer_size]
    syscall
    
    ; Check for errors
    test rax, rax
    jle .connection_error
    
    ; Update bytes read
    mov [rdi + Connection.bytes_read], rax
    
    ; Process the data
    push rdi
    mov rdi, [rdi + Connection.buffer]
    mov rsi, rax
    call process_data
    pop rdi
    
.next_connection:
    add rdi, Connection_size
    loop .process_connection
    
    pop rbp
    ret

.connection_error:
    ; Handle connection error
    mov dword [rdi + Connection.status], CONNECTION_STATUS_ERROR
    jmp .next_connection

; Write output to all active connections
write_output:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = data pointer
    ; rsi = data size
    ; rdx = format type
    
    ; Format the data
    push rdi
    push rsi
    push rdx
    call format_data
    pop rdx
    pop rsi
    pop rdi
    
    ; Write to each active connection
    mov rdi, connections
    mov ecx, [active_connections]
.write_connection:
    ; Check connection status
    cmp dword [rdi + Connection.status], CONNECTION_STATUS_ACTIVE
    jne .next_write
    
    ; Write data to connection
    mov eax, 1          ; sys_write
    mov edi, [rdi + Connection.fd]
    mov rsi, output_buffer
    mov rdx, output_buffer_size
    syscall
    
    ; Check for errors
    test rax, rax
    jle .write_error
    
.next_write:
    add rdi, Connection_size
    loop .write_connection
    
    pop rbp
    ret

.write_error:
    ; Handle write error
    mov dword [rdi + Connection.status], CONNECTION_STATUS_ERROR
    jmp .next_write

; Process input data
process_data:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = data pointer
    ; rsi = data size
    
    ; Check for buffer overflow
    cmp rsi, input_buffer_size
    ja .buffer_full
    
    ; Copy data to input buffer
    mov rcx, rsi
    mov rsi, rdi
    mov rdi, input_buffer
    rep movsb
    
    ; Process based on data type
    call detect_data_type
    cmp rax, FORMAT_JSON
    je .process_json
    cmp rax, FORMAT_BINARY
    je .process_binary
    jmp .process_raw
    
.process_json:
    call parse_json
    jmp .done
    
.process_binary:
    call parse_binary
    jmp .done
    
.process_raw:
    call parse_raw
    
.done:
    pop rbp
    ret

.buffer_full:
    ; Handle buffer full error
    mov rax, 1          ; sys_write
    mov rdi, 2          ; stderr
    mov rsi, error_buffer_full
    mov rdx, error_buffer_full_len
    syscall
    jmp .done

; Handle new connection
handle_connection:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = file descriptor
    ; rsi = connection type
    
    ; Find free connection slot
    mov rdi, connections
    mov ecx, max_connections
.find_slot:
    cmp dword [rdi + Connection.status], CONNECTION_STATUS_CLOSED
    je .found_slot
    add rdi, Connection_size
    loop .find_slot
    
    ; No free slots
    xor rax, rax
    jmp .done
    
.found_slot:
    ; Initialize connection
    mov [rdi + Connection.fd], edi
    mov [rdi + Connection.type], esi
    mov dword [rdi + Connection.status], CONNECTION_STATUS_ACTIVE
    
    ; Allocate buffer
    call allocate_buffer
    mov [rdi + Connection.buffer], rax
    mov [rdi + Connection.buffer_size], rdx
    
    ; Update active connections
    inc dword [active_connections]
    
    mov rax, 1
    
.done:
    pop rbp
    ret

; Format data based on type
format_data:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = data pointer
    ; rsi = data size
    ; rdx = format type
    
    cmp edx, FORMAT_JSON
    je .format_json
    cmp edx, FORMAT_BINARY
    je .format_binary
    jmp .format_raw
    
.format_json:
    call format_json
    jmp .done
    
.format_binary:
    call format_binary
    jmp .done
    
.format_raw:
    call format_raw
    
.done:
    pop rbp
    ret
