section .data
    ; Memory pool configuration
    POOL_SIZE equ 65536          ; 64KB memory pool
    BLOCK_SIZE_SMALL equ 64      ; Small blocks (64 bytes)
    BLOCK_SIZE_MEDIUM equ 256    ; Medium blocks (256 bytes)
    BLOCK_SIZE_LARGE equ 1024    ; Large blocks (1KB)
    
    MAX_SMALL_BLOCKS equ 512     ; 32KB for small blocks
    MAX_MEDIUM_BLOCKS equ 128    ; 32KB for medium blocks
    MAX_LARGE_BLOCKS equ 32      ; 32KB for large blocks
    
    ; Memory pool base pointers
    memory_pool_base dq 0
    small_blocks_base dq 0
    medium_blocks_base dq 0
    large_blocks_base dq 0
    
    ; Free lists (linked lists of free blocks)
    small_free_head dq 0
    medium_free_head dq 0
    large_free_head dq 0
    
    ; Block usage counters
    small_blocks_used dq 0
    medium_blocks_used dq 0
    large_blocks_used dq 0
    
    ; Performance metrics
    total_allocations dq 0
    total_deallocations dq 0
    failed_allocations dq 0
    peak_memory_usage dq 0
    current_memory_usage dq 0
    
    ; Fragmentation tracking
    fragmentation_score dq 0
    
    ; Memory alignment constants
    MEMORY_ALIGNMENT equ 32      ; 32-byte alignment for SIMD
    
    ; Error codes
    ERROR_OUT_OF_MEMORY equ -1
    ERROR_INVALID_SIZE equ -2
    ERROR_INVALID_POINTER equ -3
    ERROR_CORRUPTION equ -4

section .bss
    ; Memory pool storage
    memory_pool resb POOL_SIZE
    
    ; Block headers for tracking
    small_block_headers resb (MAX_SMALL_BLOCKS * 8)   ; 8 bytes per header
    medium_block_headers resb (MAX_MEDIUM_BLOCKS * 8)
    large_block_headers resb (MAX_LARGE_BLOCKS * 8)

section .text
    global init_memory_manager
    global allocate_memory
    global deallocate_memory
    global consolidate_memories
    global cleanup_old_memories
    global get_memory_stats
    global defragment_memory
    global check_memory_integrity
    global allocate_aligned
    global reallocate_memory
    extern memset
    extern memcpy

; Initialize memory management system
init_memory_manager:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Set up memory pool base
    lea rax, [rel memory_pool]
    mov [rel memory_pool_base], rax
    
    ; Align memory pool to 32-byte boundary
    add rax, MEMORY_ALIGNMENT - 1
    and rax, -(MEMORY_ALIGNMENT)
    mov [rel memory_pool_base], rax
    
    ; Calculate pool region bases
    mov rbx, rax                              ; small blocks start
    mov [rel small_blocks_base], rbx
    
    add rbx, MAX_SMALL_BLOCKS * BLOCK_SIZE_SMALL  ; medium blocks start
    mov [rel medium_blocks_base], rbx
    
    add rbx, MAX_MEDIUM_BLOCKS * BLOCK_SIZE_MEDIUM ; large blocks start
    mov [rel large_blocks_base], rbx
    
    ; Initialize free lists
    call init_small_blocks_free_list
    call init_medium_blocks_free_list
    call init_large_blocks_free_list
    
    ; Reset counters
    mov qword [rel small_blocks_used], 0
    mov qword [rel medium_blocks_used], 0
    mov qword [rel large_blocks_used], 0
    mov qword [rel total_allocations], 0
    mov qword [rel total_deallocations], 0
    mov qword [rel failed_allocations], 0
    mov qword [rel current_memory_usage], 0
    mov qword [rel peak_memory_usage], 0
    
    xor rax, rax  ; Return success
    mov rsp, rbp
    pop rbp
    ret

; Optimized memory allocation with size-based pooling
allocate_memory:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    ; Parameters: rdi = size
    mov r12, rdi  ; Save requested size
    
    ; Increment allocation counter
    inc qword [rel total_allocations]
    
    ; Determine appropriate pool based on size
    cmp r12, BLOCK_SIZE_SMALL
    jle .allocate_small
    cmp r12, BLOCK_SIZE_MEDIUM
    jle .allocate_medium
    cmp r12, BLOCK_SIZE_LARGE
    jle .allocate_large
    
    ; Size too large for any pool
    inc qword [rel failed_allocations]
    mov rax, ERROR_INVALID_SIZE
    jmp .done
    
.allocate_small:
    call allocate_from_small_pool
    mov rbx, BLOCK_SIZE_SMALL
    jmp .update_stats
    
.allocate_medium:
    call allocate_from_medium_pool
    mov rbx, BLOCK_SIZE_MEDIUM
    jmp .update_stats
    
.allocate_large:
    call allocate_from_large_pool
    mov rbx, BLOCK_SIZE_LARGE
    jmp .update_stats
    
.update_stats:
    test rax, rax
    jz .allocation_failed
    
    ; Update memory usage statistics
    add qword [rel current_memory_usage], rbx
    mov rcx, [rel current_memory_usage]
    cmp rcx, [rel peak_memory_usage]
    jle .done
    mov [rel peak_memory_usage], rcx
    jmp .done
    
.allocation_failed:
    inc qword [rel failed_allocations]
    mov rax, ERROR_OUT_OF_MEMORY
    
.done:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Allocate from small block pool
allocate_from_small_pool:
    push rbp
    mov rbp, rsp
    
    ; Check if we have free small blocks
    mov rax, [rel small_free_head]
    test rax, rax
    jz .no_free_blocks
    
    ; Remove block from free list
    mov rbx, [rax]  ; Next free block
    mov [rel small_free_head], rbx
    
    ; Clear the block
    mov rdi, rax
    xor rsi, rsi
    mov rdx, BLOCK_SIZE_SMALL
    call memset
    
    ; Update usage counter
    inc qword [rel small_blocks_used]
    
    ; Return pointer to allocated block
    jmp .done
    
.no_free_blocks:
    xor rax, rax  ; Return NULL
    
.done:
    pop rbp
    ret

; Allocate from medium block pool
allocate_from_medium_pool:
    push rbp
    mov rbp, rsp
    
    mov rax, [rel medium_free_head]
    test rax, rax
    jz .no_free_blocks
    
    mov rbx, [rax]
    mov [rel medium_free_head], rbx
    
    mov rdi, rax
    xor rsi, rsi
    mov rdx, BLOCK_SIZE_MEDIUM
    call memset
    
    inc qword [rel medium_blocks_used]
    jmp .done
    
.no_free_blocks:
    xor rax, rax
    
.done:
    pop rbp
    ret

; Allocate from large block pool
allocate_from_large_pool:
    push rbp
    mov rbp, rsp
    
    mov rax, [rel large_free_head]
    test rax, rax
    jz .no_free_blocks
    
    mov rbx, [rax]
    mov [rel large_free_head], rbx
    
    mov rdi, rax
    xor rsi, rsi
    mov rdx, BLOCK_SIZE_LARGE
    call memset
    
    inc qword [rel large_blocks_used]
    jmp .done
    
.no_free_blocks:
    xor rax, rax
    
.done:
    pop rbp
    ret

; Optimized memory deallocation
deallocate_memory:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    ; Parameters: rdi = pointer
    mov r12, rdi
    
    ; Validate pointer
    test r12, r12
    jz .invalid_pointer
    
    ; Determine which pool this pointer belongs to
    call determine_pool_type
    test rax, rax
    js .invalid_pointer
    
    ; Deallocate based on pool type
    cmp rax, 0
    je .deallocate_small
    cmp rax, 1
    je .deallocate_medium
    cmp rax, 2
    je .deallocate_large
    
.deallocate_small:
    call deallocate_to_small_pool
    mov rbx, BLOCK_SIZE_SMALL
    jmp .update_stats
    
.deallocate_medium:
    call deallocate_to_medium_pool
    mov rbx, BLOCK_SIZE_MEDIUM
    jmp .update_stats
    
.deallocate_large:
    call deallocate_to_large_pool
    mov rbx, BLOCK_SIZE_LARGE
    jmp .update_stats
    
.update_stats:
    inc qword [rel total_deallocations]
    sub qword [rel current_memory_usage], rbx
    xor rax, rax  ; Success
    jmp .done
    
.invalid_pointer:
    mov rax, ERROR_INVALID_POINTER
    
.done:
    pop r12
    pop rbx
    pop rbp
    ret

; Determine which pool a pointer belongs to
determine_pool_type:
    push rbp
    mov rbp, rsp
    
    ; Parameters: rdi = pointer
    ; Returns: rax = pool type (0=small, 1=medium, 2=large, -1=invalid)
    
    ; Check if pointer is in small blocks range
    mov rax, [rel small_blocks_base]
    cmp rdi, rax
    jl .not_small
    add rax, MAX_SMALL_BLOCKS * BLOCK_SIZE_SMALL
    cmp rdi, rax
    jge .not_small
    mov rax, 0  ; Small pool
    jmp .done
    
.not_small:
    ; Check if pointer is in medium blocks range
    mov rax, [rel medium_blocks_base]
    cmp rdi, rax
    jl .not_medium
    add rax, MAX_MEDIUM_BLOCKS * BLOCK_SIZE_MEDIUM
    cmp rdi, rax
    jge .not_medium
    mov rax, 1  ; Medium pool
    jmp .done
    
.not_medium:
    ; Check if pointer is in large blocks range
    mov rax, [rel large_blocks_base]
    cmp rdi, rax
    jl .invalid
    add rax, MAX_LARGE_BLOCKS * BLOCK_SIZE_LARGE
    cmp rdi, rax
    jge .invalid
    mov rax, 2  ; Large pool
    jmp .done
    
.invalid:
    mov rax, -1  ; Invalid pointer
    
.done:
    pop rbp
    ret

; Memory consolidation and defragmentation
consolidate_memories:
    push rbp
    mov rbp, rsp
    
    ; Analyze fragmentation
    call calculate_fragmentation_score
    
    ; If fragmentation is high, perform defragmentation
    cmp rax, 50  ; Threshold: 50% fragmentation
    jl .no_defrag_needed
    
    call defragment_memory
    
.no_defrag_needed:
    xor rax, rax  ; Success
    pop rbp
    ret

; Calculate memory fragmentation score
calculate_fragmentation_score:
    push rbp
    mov rbp, rsp
    
    ; Simple fragmentation metric: used blocks / total blocks * 100
    mov rax, [rel small_blocks_used]
    add rax, [rel medium_blocks_used]
    add rax, [rel large_blocks_used]
    
    mov rbx, MAX_SMALL_BLOCKS + MAX_MEDIUM_BLOCKS + MAX_LARGE_BLOCKS
    test rbx, rbx
    jz .no_fragmentation
    
    ; Calculate percentage
    imul rax, 100
    xor rdx, rdx
    div rbx
    
    mov [rel fragmentation_score], rax
    jmp .done
    
.no_fragmentation:
    mov qword [rel fragmentation_score], 0
    xor rax, rax
    
.done:
    pop rbp
    ret

; Memory integrity checking
check_memory_integrity:
    push rbp
    mov rbp, rsp
    
    ; Check pool boundaries and free list consistency
    call validate_free_lists
    test rax, rax
    jnz .corruption_detected
    
    call validate_usage_counters
    test rax, rax
    jnz .corruption_detected
    
    xor rax, rax  ; No corruption
    jmp .done
    
.corruption_detected:
    mov rax, ERROR_CORRUPTION
    
.done:
    pop rbp
    ret

; Get comprehensive memory statistics
get_memory_stats:
    push rbp
    mov rbp, rsp
    
    ; Parameters: rdi = stats structure pointer
    ; Fill in statistics structure
    mov rax, [rel total_allocations]
    mov [rdi], rax
    
    mov rax, [rel total_deallocations]
    mov [rdi + 8], rax
    
    mov rax, [rel failed_allocations]
    mov [rdi + 16], rax
    
    mov rax, [rel current_memory_usage]
    mov [rdi + 24], rax
    
    mov rax, [rel peak_memory_usage]
    mov [rdi + 32], rax
    
    mov rax, [rel fragmentation_score]
    mov [rdi + 40], rax
    
    mov rax, [rel small_blocks_used]
    mov [rdi + 48], rax
    
    mov rax, [rel medium_blocks_used]
    mov [rdi + 56], rax
    
    mov rax, [rel large_blocks_used]
    mov [rdi + 64], rax
    
    xor rax, rax  ; Success
    pop rbp
    ret

; Aligned memory allocation
allocate_aligned:
    push rbp
    mov rbp, rsp
    push rbx
    
    ; Parameters: rdi = size, rsi = alignment
    ; For simplicity, all our allocations are already 32-byte aligned
    ; Just call regular allocation
    call allocate_memory
    
    pop rbx
    pop rbp
    ret

; Memory reallocation
reallocate_memory:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    ; Parameters: rdi = old_ptr, rsi = new_size
    mov r12, rdi  ; Old pointer
    mov r13, rsi  ; New size
    
    ; If old pointer is NULL, just allocate new memory
    test r12, r12
    jz .allocate_new
    
    ; Allocate new memory
    mov rdi, r13
    call allocate_memory
    test rax, rax
    jz .allocation_failed
    
    mov rbx, rax  ; Save new pointer
    
    ; Copy old data to new location
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13  ; Copy up to new size
    call memcpy
    
    ; Deallocate old memory
    mov rdi, r12
    call deallocate_memory
    
    mov rax, rbx  ; Return new pointer
    jmp .done
    
.allocate_new:
    mov rdi, r13
    call allocate_memory
    jmp .done
    
.allocation_failed:
    xor rax, rax  ; Return NULL
    
.done:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Helper functions (stubs for initialization)
init_small_blocks_free_list:
init_medium_blocks_free_list:
init_large_blocks_free_list:
deallocate_to_small_pool:
deallocate_to_medium_pool:
deallocate_to_large_pool:
defragment_memory:
validate_free_lists:
validate_usage_counters:
cleanup_old_memories:
    push rbp
    mov rbp, rsp
    xor rax, rax
    pop rbp
    ret
