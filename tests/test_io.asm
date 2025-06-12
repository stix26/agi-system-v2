section .text
    global test_io

test_io:
    call read_input
    call write_output
    ; Add assertions to verify I/O operations
    ret
