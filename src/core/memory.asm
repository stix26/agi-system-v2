section .data
    ; Memory configuration
    working_memory_size equ 1024
    long_term_memory_size equ 65536
    memory_dimension equ 64
    num_memory_slots equ 16
    
    ; Memory structures
    working_memory: times (working_memory_size * memory_dimension) dd 0
    long_term_memory: times (long_term_memory_size * memory_dimension) dd 0
    memory_keys: times (num_memory_slots * memory_dimension) dd 0
    memory_values: times (num_memory_slots * memory_dimension) dd 0
    
    ; Memory management
    memory_usage: times num_memory_slots dd 0
    memory_timestamps: times num_memory_slots dq 0
    current_timestamp dq 0
    
    ; Memory parameters
    memory_threshold dd 0.8
    decay_factor dq 0.95
    max_memory_age dq 86400  ; 24 hours in seconds

    ; Memory constants
    page_size equ 4096
    max_pages equ 1024
    max_blocks equ 4096
    block_size equ 64

    ; Error messages
    error_msg db "Error: Memory operation failed", 10
    error_msg_len equ $ - error_msg

section .bss
    ; Memory management structures
    page_table resq max_pages
    block_table resq max_blocks
    free_pages resq max_pages
    free_blocks resq max_blocks
    num_free_pages resq 1
    num_free_blocks resq 1

section .text
    global init_memory
    global store_memory
    global retrieve_memory
    global update_memory
    global consolidate_memory
    global get_memory_state
    global cleanup_memory
    global find_memory_slot
    global store_data
    global retrieve_data
    global update_data
    global check_consolidation_needed
    global consolidate_memories
    global cleanup_old_memories
    global allocate_page
    global free_page
    global allocate_block
    global free_block
    global copy_memory
    global clear_memory
    global memory_init
    global memory_process
    extern memcpy
    extern matrix_multiply
    
    ; Initialize memory system
memory_init:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Initialize working memory
    lea rdi, [rel working_memory]
    mov rcx, working_memory_size * memory_dimension
    call init_working_memory
    
    ; Initialize long-term memory
    lea rdi, [rel long_term_memory]
    mov rcx, long_term_memory_size * memory_dimension
    call init_long_term_memory
    
    ; Initialize memory slots
    lea rdi, [rel memory_keys]
    lea rsi, [rel memory_values]
    mov rdx, num_memory_slots
    call init_memory_slots
    
    ; Initialize page table
    mov rcx, max_pages
    xor rax, rax
.init_pages:
    mov [rel page_table + rcx * 8 - 8], rax
    loop .init_pages
    
    ; Initialize block table
    mov rcx, max_blocks
.init_blocks:
    mov [rel block_table + rcx * 8 - 8], rax
    loop .init_blocks
    
    ; Initialize free lists
    mov qword [rel num_free_pages], max_pages
    mov qword [rel num_free_blocks], max_blocks
    
    ; Mark all pages as free
    mov rcx, max_pages
    xor rax, rax
.init_free_pages:
    mov [rel free_pages + rcx * 8 - 8], rax
    loop .init_free_pages
    
    ; Mark all blocks as free
    mov rcx, max_blocks
.init_free_blocks:
    mov [rel free_blocks + rcx * 8 - 8], rax
    loop .init_free_blocks
    
    pop rbp
    ret

memory_process:
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
    
    ; Store in memory
    mov rdi, rax      ; result from matrix multiply
    mov rsi, [rsp+8]  ; size
    call store_memory
    
    ; Return result
    mov rsp, rbp
    pop rbp
    ret

; Store data in memory
store_memory:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    
    ; Save parameters
    mov [rsp], rdi    ; data
    mov [rsp+8], rsi  ; size
    
    ; Copy data to memory
    mov rdi, [rsp]    ; data
    mov rsi, [rsp+8]  ; size
    call memcpy
    
    ; Return success
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret

; Retrieve data from memory
retrieve_memory:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = key pointer
    ; rsi = output buffer
    ; rdx = memory type (0 = working, 1 = long-term)
    
    ; Check memory type
    test rdx, rdx
    jz .retrieve_working
    
    ; Retrieve from long-term memory
    lea rcx, [rel long_term_memory]
    mov r8, long_term_memory_size
    jmp .retrieve
    
.retrieve_working:
    ; Retrieve from working memory
    lea rcx, [rel working_memory]
    mov r8, working_memory_size
    
.retrieve:
    ; Find matching slot
    push rdi
    push rsi
    push rdx
    mov rdi, rcx
    mov rdx, r8
    call find_matching_slot
    pop rdx
    pop rsi
    pop rdi
    
    ; Retrieve data
    mov rcx, rax
    imul rcx, memory_dimension
    lea r8, [rel memory_keys]
    lea r9, [rel memory_values]
    call retrieve_data
    
    xor rax, rax  ; Return success
    pop rbp
    ret

; Update existing memory entry
update_memory:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = key pointer
    ; rsi = new value pointer
    ; rdx = memory type (0 = working, 1 = long-term)
    
    ; Check memory type
    test rdx, rdx
    jz .update_working
    
    ; Update in long-term memory
    lea rcx, [rel long_term_memory]
    mov r8, long_term_memory_size
    jmp .update
    
.update_working:
    ; Update in working memory
    lea rcx, [rel working_memory]
    mov r8, working_memory_size
    
.update:
    ; Find matching slot
    push rdi
    push rsi
    push rdx
    mov rdi, rcx
    mov rdx, r8
    call find_matching_slot
    pop rdx
    pop rsi
    pop rdi
    
    ; Update data
    mov rcx, rax
    imul rcx, memory_dimension
    lea r8, [rel memory_keys]
    lea r9, [rel memory_values]
    call update_data
    
    ; Update timestamp
    mov rax, [rel current_timestamp]
    inc rax
    mov [rel current_timestamp], rax
    mov [rel memory_timestamps + rcx * 8], rax
    
    xor rax, rax  ; Return success
    pop rbp
    ret

; Consolidate working memory to long-term memory
consolidate_memory:
    push rbp
    mov rbp, rsp
    
    ; Check if consolidation is needed
    lea rdi, [rel memory_usage]
    mov rsi, num_memory_slots
    call check_consolidation_needed
    test rax, rax
    jz .done
    
    ; Consolidate memories
    lea rdi, [rel working_memory]
    lea rsi, [rel long_term_memory]
    mov rdx, working_memory_size
    mov rcx, long_term_memory_size
    call consolidate_memories
    
    ; Cleanup old memories
    lea rdi, [rel long_term_memory]
    mov rsi, long_term_memory_size
    call cleanup_old_memories
    
.done:
    xor rax, rax  ; Return success
    pop rbp
    ret

; Get current memory state
get_memory_state:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = working memory output buffer
    ; rsi = long-term memory output buffer
    
    ; Copy working memory
    lea rcx, [rel working_memory]
    mov rdx, working_memory_size * memory_dimension * 4
    call memcpy
    
    ; Copy long-term memory
    lea rcx, [rel long_term_memory]
    mov rdx, long_term_memory_size * memory_dimension * 4
    call memcpy
    
    xor rax, rax  ; Return success
    pop rbp
    ret

; Cleanup memory system
cleanup_memory:
    push rbp
    mov rbp, rsp
    
    ; Clear working memory
    lea rdi, [rel working_memory]
    mov rcx, working_memory_size * memory_dimension
    xor rax, rax
    rep stosd
    
    ; Clear long-term memory
    lea rdi, [rel long_term_memory]
    mov rcx, long_term_memory_size * memory_dimension
    rep stosd
    
    ; Clear memory slots
    lea rdi, [rel memory_keys]
    mov rcx, num_memory_slots * memory_dimension
    rep stosd
    
    lea rdi, [rel memory_values]
    mov rcx, num_memory_slots * memory_dimension
    rep stosd
    
    ; Reset timestamps
    lea rdi, [rel memory_timestamps]
    mov rcx, num_memory_slots
    xor rax, rax
    rep stosq
    
    ; Reset current timestamp
    mov qword [rel current_timestamp], 0
    
    xor rax, rax  ; Return success
    pop rbp
    ret

; Helper functions
init_working_memory:
    push rbp
    mov rbp, rsp
    
    ; Clear working memory
    xor rax, rax
    rep stosd
    
    pop rbp
    ret

init_long_term_memory:
    push rbp
    mov rbp, rsp
    
    ; Clear long-term memory
    xor rax, rax
    rep stosd
    
    pop rbp
    ret

init_memory_slots:
    push rbp
    mov rbp, rsp
    
    ; Clear memory slots
    xor rax, rax
    rep stosd
    
    mov rdi, rsi
    mov rcx, rdx
    imul rcx, memory_dimension
    rep stosd
    
    pop rbp
    ret

find_free_slot:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = memory pointer
    ; rdx = memory size
    
    ; Find first unused slot
    xor rcx, rcx
.find_loop:
    cmp rcx, rdx
    jge .not_found
    
    mov eax, [rel memory_usage + rcx * 4]
    test eax, eax
    jz .found
    
    inc rcx
    jmp .find_loop
    
.found:
    mov rax, rcx
    jmp .done
    
.not_found:
    mov rax, -1
    
.done:
    pop rbp
    ret

find_matching_slot:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = memory pointer
    ; rdx = memory size
    
    ; Find matching slot
    xor rcx, rcx
.find_loop:
    cmp rcx, rdx
    jge .not_found
    
    mov eax, [rel memory_usage + rcx * 4]
    test eax, eax
    jz .next
    
    ; Compare keys
    push rdi
    push rsi
    push rdx
    push rcx
    lea rdi, [rel memory_keys + rcx * memory_dimension * 4]
    mov rsi, rdi
    mov rdx, memory_dimension
    call vector_dot_product
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    
    ; Check similarity
    movss xmm1, [rel memory_threshold]
    comiss xmm0, xmm1
    jae .found
    
.next:
    inc rcx
    jmp .find_loop
    
.found:
    mov rax, rcx
    jmp .done
    
.not_found:
    mov rax, -1
    
.done:
    pop rbp
    ret

store_data:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = data pointer
    ; rsi = data size
    ; rcx = slot index
    ; r8 = keys pointer
    ; r9 = values pointer
    
    ; Store key
    mov rax, rcx
    imul rax, memory_dimension * 4
    add rax, r8
    mov rdx, memory_dimension * 4
    call memcpy
    
    ; Store value
    mov rax, rcx
    imul rax, memory_dimension * 4
    add rax, r9
    mov rdx, memory_dimension * 4
    call memcpy
    
    ; Mark slot as used
    mov dword [rel memory_usage + rcx * 4], 1
    
    pop rbp
    ret

retrieve_data:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = output buffer
    ; rcx = slot index
    ; r8 = keys pointer
    ; r9 = values pointer
    
    ; Copy value
    mov rax, rcx
    imul rax, memory_dimension * 4
    add rax, r9
    mov rdx, memory_dimension * 4
    call memcpy
    
    pop rbp
    ret

update_data:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = new value pointer
    ; rcx = slot index
    ; r8 = keys pointer
    ; r9 = values pointer
    
    ; Update value
    mov rax, rcx
    imul rax, memory_dimension * 4
    add rax, r9
    mov rdx, memory_dimension * 4
    call memcpy
    
    pop rbp
    ret

check_consolidation_needed:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = usage array
    ; rsi = num slots
    
    ; Calculate usage ratio
    xor rcx, rcx
    xor rdx, rdx
.count_loop:
    cmp rcx, rsi
    jge .check_threshold
    
    mov eax, [rdi + rcx * 4]
    add rdx, rax
    
    inc rcx
    jmp .count_loop
    
.check_threshold:
    cvtsi2ss xmm0, rdx
    cvtsi2ss xmm1, rsi
    divss xmm0, xmm1
    
    movss xmm1, [rel memory_threshold]
    comiss xmm0, xmm1
    
    setae al
    movzx rax, al
    
    pop rbp
    ret

consolidate_memories:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = working memory
    ; rsi = long-term memory
    ; rdx = working size
    ; rcx = long-term size
    
    ; Copy working memory to long-term memory
    mov r8, rdx
    imul r8, memory_dimension * 4
    call memcpy
    
    pop rbp
    ret

cleanup_old_memories:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = memory pointer
    ; rsi = memory size
    
    ; Get current timestamp
    mov rax, [rel current_timestamp]
    
    ; Check each slot
    xor rcx, rcx
.check_loop:
    cmp rcx, rsi
    jge .done
    
    ; Check if slot is used
    mov edx, [rel memory_usage + rcx * 4]
    test edx, edx
    jz .next
    
    ; Check age
    mov rdx, [rel memory_timestamps + rcx * 8]
    sub rax, rdx
    cmp rax, [rel max_memory_age]
    jle .next
    
    ; Clear slot
    mov dword [rel memory_usage + rcx * 4], 0
    mov qword [rel memory_timestamps + rcx * 8], 0
    
.next:
    inc rcx
    jmp .check_loop
    
.done:
    pop rbp
    ret

; Find slot for memory operation
find_memory_slot:
    push rbp
    mov rbp, rsp
    
    ; Parameters:
    ; rdi = key pointer
    ; rsi = num slots
    
    ; Find matching slot
    xor rcx, rcx
.find_loop:
    cmp rcx, rsi
    jge .not_found
    
    mov eax, [memory_usage + rcx * 4]
    test eax, eax
    jz .next
    
    ; Compare keys
    push rdi
    push rsi
    push rdx
    push rcx
    lea rdi, [memory_keys + rcx * memory_dimension * 4]
    mov rsi, rdi
    mov rdx, memory_dimension
    call vector_dot_product
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    
    ; Check similarity
    movss xmm1, [memory_threshold]
    comiss xmm0, xmm1
    jae .found
    
.next:
    inc rcx
    jmp .find_loop
    
.found:
    mov rax, rcx
    jmp .done
    
.not_found:
    mov rax, -1
    
.done:
    pop rbp
    ret

; Allocate a page
allocate_page:
    push rbp
    mov rbp, rsp
    
    ; Check if we have free pages
    mov rax, [rel num_free_pages]
    test rax, rax
    jz .no_pages
    
    ; Get next free page
    dec rax
    mov [rel num_free_pages], rax
    mov rcx, [rel free_pages + rax * 8]
    
    ; Allocate page
    mov rax, 0x2000005  ; syscall number for mmap
    xor rdi, rdi        ; addr = NULL
    mov rsi, page_size  ; length
    mov rdx, 3          ; prot = PROT_READ | PROT_WRITE
    mov r10, 0x1002     ; flags = MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1          ; fd = -1
    xor r9, r9          ; offset = 0
    syscall
    
    ; Check for error
    test rax, rax
    js .error
    
    ; Store page address
    mov [rel page_table + rcx * 8], rax
    
    ; Return page index
    mov rax, rcx
    jmp .done
    
.no_pages:
    mov rax, -1
    jmp .done
    
.error:
    mov rax, -1
    
.done:
    pop rbp
    ret

; Free a page
free_page:
    push rbp
    mov rbp, rsp
    
    ; Validate page index
    cmp rdi, max_pages
    jae .invalid
    
    ; Get page address
    mov rax, [rel page_table + rdi * 8]
    test rax, rax
    jz .invalid
    
    ; Free page
    mov rsi, page_size
    mov rax, 0x2000006  ; syscall number for munmap
    syscall
    
    ; Check for error
    test rax, rax
    js .error
    
    ; Clear page table entry
    mov qword [rel page_table + rdi * 8], 0
    
    ; Add to free list
    mov rax, [rel num_free_pages]
    mov [rel free_pages + rax * 8], rdi
    inc qword [rel num_free_pages]
    
    xor rax, rax  ; Return success
    jmp .done
    
.invalid:
    mov rax, -1
    jmp .done
    
.error:
    mov rax, -1
    
.done:
    pop rbp
    ret

; Allocate a block
allocate_block:
    push rbp
    mov rbp, rsp
    
    ; Check if we have free blocks
    mov rax, [rel num_free_blocks]
    test rax, rax
    jz .no_blocks
    
    ; Get next free block
    dec rax
    mov [rel num_free_blocks], rax
    mov rcx, [rel free_blocks + rax * 8]
    
    ; Allocate block
    mov rax, 0x2000005  ; syscall number for mmap
    xor rdi, rdi        ; addr = NULL
    mov rsi, block_size ; length
    mov rdx, 3          ; prot = PROT_READ | PROT_WRITE
    mov r10, 0x1002     ; flags = MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1          ; fd = -1
    xor r9, r9          ; offset = 0
    syscall
    
    ; Check for error
    test rax, rax
    js .error
    
    ; Store block address
    mov [rel block_table + rcx * 8], rax
    
    ; Return block index
    mov rax, rcx
    jmp .done
    
.no_blocks:
    mov rax, -1
    jmp .done
    
.error:
    mov rax, -1
    
.done:
    pop rbp
    ret

; Free a block
free_block:
    push rbp
    mov rbp, rsp
    
    ; Validate block index
    cmp rdi, max_blocks
    jae .invalid
    
    ; Get block address
    mov rax, [rel block_table + rdi * 8]
    test rax, rax
    jz .invalid
    
    ; Free block
    mov rsi, block_size
    mov rax, 0x2000006  ; syscall number for munmap
    syscall
    
    ; Check for error
    test rax, rax
    js .error
    
    ; Clear block table entry
    mov qword [rel block_table + rdi * 8], 0
    
    ; Add to free list
    mov rax, [rel num_free_blocks]
    mov [rel free_blocks + rax * 8], rdi
    inc qword [rel num_free_blocks]
    
    xor rax, rax  ; Return success
    jmp .done
    
.invalid:
    mov rax, -1
    jmp .done
    
.error:
    mov rax, -1
    
.done:
    pop rbp
    ret

; Copy memory
copy_memory:
    push rbp
    mov rbp, rsp
    
    ; Save parameters
    mov rcx, rdx  ; size
    
    ; Copy data
    rep movsb
    
    pop rbp
    ret

; Clear memory
clear_memory:
    push rbp
    mov rbp, rsp
    
    ; Save parameters
    mov rcx, rsi  ; size
    
    ; Clear data
    xor al, al
    rep stosb
    
    pop rbp
    ret 