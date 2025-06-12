section .text
    global test_memory

test_memory:
    call init_memory_manager
    call allocate_memory
    ; Add assertions to verify memory allocation
    ret
