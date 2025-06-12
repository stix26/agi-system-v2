section .data
    ; Memory configuration
    working_memory_size equ 1024 * 1024  ; 1MB working memory
    long_term_memory_size equ 1024 * 1024 * 100  ; 100MB long-term memory
    memory_block_size equ 4096  ; 4KB memory blocks
    
    ; Memory structures
    working_memory: times working_memory_size db 0
    long_term_memory: times long_term_memory_size db 0
    
    ; Memory management metadata
    working_memory_used dq 0
    long_term_memory_used dq 0
    
    ; Memory block headers
    struc MemoryBlock
        .size:        resq 1    ; Size of the block
        .type:        resd 1    ; Type of data stored
        .timestamp:   resq 1    ; Last access time
        .priority:    resd 1    ; Memory priority
        .next:        resq 1    ; Pointer to next block
        .prev:        resq 1    ; Pointer to previous block
    endstruc
    
    ; Memory types
    MEMORY_TYPE_WORKING equ 1
    MEMORY_TYPE_LONG_TERM equ 2
    MEMORY_TYPE_CACHE equ 3
    
    ; Memory priorities
    PRIORITY_HIGH equ 3
    PRIORITY_MEDIUM equ 2
    PRIORITY_LOW equ 1

section .text
    global init_memory_manager
    global allocate_memory
    global free_memory
    global consolidate_memory
    global memory_garbage_collect
    global memory_defragment
    
    ; Initialize memory manager
init_memory_manager:
    push rbp
    mov rbp, rsp
    
    ; Initialize working memory
    mov rdi, working_memory
    mov rcx, working_memory_size
    xor al, al
    rep stosb
    
    ; Initialize long-term memory
    mov rdi, long_term_memory
    mov rcx, long_term_memory_size
    xor al, al
    rep stosb
    
    ; Initialize metadata
    mov qword [working_memory_used], 0
    mov qword [long_term_memory_used], 0
    
    pop rbp
    ret

; Allocate memory block
allocate_memory:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = size
    ; rsi = type
    ; rdx = priority
    
    ; Check if we need to consolidate memory
    call check_memory_fragmentation
    test rax, rax
    jz .no_consolidation
    call consolidate_memory
    
.no_consolidation:
    ; Find suitable memory block
    call find_free_memory_block
    test rax, rax
    jz .allocation_failed
    
    ; Initialize memory block header
    mov [rax + MemoryBlock.size], rdi
    mov [rax + MemoryBlock.type], esi
    mov [rax + MemoryBlock.priority], edx
    call get_current_timestamp
    mov [rax + MemoryBlock.timestamp], rax
    
    ; Update memory usage
    add [working_memory_used], rdi
    
    pop rbp
    ret

.allocation_failed:
    ; Try to free some memory
    call memory_garbage_collect
    ; Retry allocation
    jmp allocate_memory

; Free memory block
free_memory:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = pointer to memory block
    
    ; Update memory usage
    mov rax, [rdi + MemoryBlock.size]
    sub [working_memory_used], rax
    
    ; Mark block as free
    mov dword [rdi + MemoryBlock.type], 0
    
    ; Update linked list
    mov rax, [rdi + MemoryBlock.next]
    mov rdx, [rdi + MemoryBlock.prev]
    mov [rax + MemoryBlock.prev], rdx
    mov [rdx + MemoryBlock.next], rax
    
    pop rbp
    ret

; Consolidate memory blocks
consolidate_memory:
    push rbp
    mov rbp, rsp
    
    ; Find adjacent free blocks
    mov rdi, working_memory
.consolidate_loop:
    cmp rdi, working_memory + working_memory_size
    jae .consolidate_done
    
    ; Check if current block is free
    cmp dword [rdi + MemoryBlock.type], 0
    jne .next_block
    
    ; Check if next block is free
    mov rax, [rdi + MemoryBlock.next]
    cmp dword [rax + MemoryBlock.type], 0
    jne .next_block
    
    ; Merge blocks
    mov rcx, [rax + MemoryBlock.size]
    add [rdi + MemoryBlock.size], rcx
    
    ; Update linked list
    mov rdx, [rax + MemoryBlock.next]
    mov [rdi + MemoryBlock.next], rdx
    mov [rdx + MemoryBlock.prev], rdi
    
    jmp .consolidate_loop
    
.next_block:
    mov rdi, [rdi + MemoryBlock.next]
    jmp .consolidate_loop
    
.consolidate_done:
    pop rbp
    ret

; Garbage collection
memory_garbage_collect:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = minimum free memory required
    
    ; Find low priority blocks
    mov rsi, working_memory
.gc_loop:
    cmp rsi, working_memory + working_memory_size
    jae .gc_done
    
    ; Check block priority
    cmp dword [rsi + MemoryBlock.priority], PRIORITY_LOW
    jne .next_gc_block
    
    ; Free the block
    mov rdi, rsi
    call free_memory
    
.next_gc_block:
    mov rsi, [rsi + MemoryBlock.next]
    jmp .gc_loop
    
.gc_done:
    pop rbp
    ret

; Memory defragmentation
memory_defragment:
    push rbp
    mov rbp, rsp
    
    ; Move blocks to minimize fragmentation
    mov rdi, working_memory
.defrag_loop:
    cmp rdi, working_memory + working_memory_size
    jae .defrag_done
    
    ; Check if block is in use
    cmp dword [rdi + MemoryBlock.type], 0
    je .next_defrag_block
    
    ; Calculate optimal position
    call calculate_optimal_position
    cmp rax, rdi
    je .next_defrag_block
    
    ; Move block to optimal position
    mov rsi, rdi
    mov rdi, rax
    call move_memory_block
    
.next_defrag_block:
    mov rdi, [rdi + MemoryBlock.next]
    jmp .defrag_loop
    
.defrag_done:
    pop rbp
    ret

; Helper function to get current timestamp
get_current_timestamp:
    push rbp
    mov rbp, rsp
    
    ; Get system time
    mov rax, 201  ; sys_gettimeofday
    xor rdi, rdi
    mov rsi, rsp
    syscall
    
    ; Convert to milliseconds
    mov rax, [rsp]
    imul rax, 1000
    add rax, [rsp + 8]
    div qword 1000
    
    pop rbp
    ret
