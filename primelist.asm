section .bss
    PrimeCache: resq 100000
    StrBuffer:  resb 10

section .data
    SYS_EXIT    equ  60                     ; const int SYS_EXIT
    SYS_WRITE   equ  1                      ; const int SYS_WRITE
    
    STDOUT      equ  1                      ; const int STDOUT
    
section .text
    ; (%r10=number)
    ; This function sets %r10 to 0 if the number in %r10 is even or to -1 otherwise.
    isOdd:
        test r10, 1                         ; test if bit 1 is set
        jz .lastbitzero                     ; if it's not, go to .lastbitzero
        or r10, 0xffffffffffffffff          ; if yes, set return value to -1
        jmp .leavefunction                  ; and return
        .lastbitzero:                       ; bit 1 is set: even number
        xor r10, r10                        ; return 0
        .leavefunction:
    ret

    ; (%rax=number)
    ; This function sets %rax to 0 if the number in %rax is prime or to -1 otherwise. Works for numbers greater than 3. (No exception handling!)
    ; Don't use this function for even numbers. 2 as a divisor won't be tested.
    isPrime:
        push rbx                            ; backup the gp registers
        push rcx                            ; ...
        push rdx                            ; ...
        push r10                            ; done
        
        mov rbx, rax                        ; store a backup of the number in %rbx
        mov rcx, rax                        ; store the number also in %rcx, but
        shr rcx, 1                          ; divide %rcx by 2
        mov r10, rcx                        ; copy %rcx to %r10
        call isOdd                          ; test if value in %rcx odd or even
        test r10, r10                       ; if odd, ...
        jnz .divide                         ; start testing for primeness, otherwise...
        inc rcx                             ; increment %rcx
        
        .divide:
            mov rax, rbx                    ; restore number to %rax
            xor rdx, rdx                    ; set %rdx to zero to avoid SIGFPE
            div rcx                         ; divide number by %rcx
            test rdx, rdx                   ; is there no remainder?
            jz .isnotprime                  ; leave loop, number isn't prime
            sub rcx, 2                      ; decrement counter by 2
            cmp rcx, 2                      ; is rcx greater than 2?
        ja .divide                          ; if so, loop again
        xor rax, rax                        ; return value in %rbx is 0 - we have a prime number
        jmp .tidyup                         ; skip the .isnotprime part
        
        .isnotprime:
            or rax, 0xffffffffffffffff      ; set %rax to -1 because we have no prime number
            
        .tidyup:
        pop r10                             ; restore the gp registers
        pop rdx                             ; ...
        pop rcx                             ; ...
        pop rbx                             ; done
    ret                                     ; return
        

    ; (%rax=number, %rdi=destination, %rcx=length of string (maximum digits+1), %rbx=radix)
    ; This function sets %rcx to beginning of string and %rdx to the actual buffer length, ready for a SYS_WRITE syscall.
    itoafast:
        push rdi                            ; backup gp registers
        push r8                             ; ...
        push rax                            ; done!
        
        dec rcx                             ; reduce %rcx by one: this makes %rcx a usable offset *and* already counts in null termination
        lea rdi, [rdi+rcx]                  ; move behind %rdi to end of string
        mov byte [rdi], 0                   ; terminate string
        xor r8, r8                          ; set %r8 to zero
        inc r8                              ; increment %r8 (we already have a 0 in the output buffer)
        
        .scan:
            xor rdx, rdx                    ; set %rdx to zero
            div rbx                         ; divide %rax by radix
            add rdx, 0x30                   ; make content or remainder in %rdx human readable
            dec rdi                         ; move %rdi one position to the left and...
            mov byte [rdi], dl              ; ...write character to string.
            inc r8                          ; increase r8 to count actual characters in buffer
            test rax, rax                   ; is %rax zero?
            jz .postscan                    ; if so, quit the loop
        loop .scan                          ; if not, continue the loop until %rcx is zero

        .postscan:
        mov rdx, r8                         ; copy string length from %r8 to %rcx
        mov rcx, rdi                        ; copy buffer start vector to %rcx
        pop rax                             ; ...
        pop r8                              ; ...
        pop rdi                             ; done!
    ret

    ; (%rax=number, %rdi=destination, %rcx=length of string (maximum digits+1 due to null termination), %rbx=radix)
    itoa:
        push rax                            ; backup registers
        push rbx                            ; ...
        push rcx                            ; ...
        push rdx                            ; ...
        push rdi                            ; ...
        push r8                             ; ...
        push r9                             ; ...
        push r10                            ; ...
        push r11                            ; till here
        
        ; we start here
        dec rcx                             ; convert length to offset
        mov byte [rdi+rcx], 0               ; null termination
        inc rcx                             ; convert offset back to length
        xor r8, r8                          ; reset r8, which will continue the actual length of the string
        
        .scan:
            xor rdx, rdx                    ; set %rdx to zero
            div rbx                         ; divide %rax by radix
            add rdx, 0x30                   ; convert %rdx to ASCII character by adding 0x30
            mov byte [rdi+r8], dl           ; write ASCII character into output buffer
            inc r8                          ; increase %r8, the actual string length counter
            test rax, rax                   ; check if %rax==0 (we completely converted the number)
            jz .postloop                    ; if so, go to .postloop to terminate string
            loop .scan                      ; continue scanning if buffer not full yet and number not converted yet
        jmp .reverse                        ; fall through when buffer full and continue without terminating string (because that's done already)
        .postloop:                          ; we're done with the conversion: terminate string
            mov byte [rdi+r8], 0            ; terminate string, finally
        .reverse:
            cmp r8, 1                       ; at least one character?
            jbe .donereversing              ; skip reversing if not
            mov r9, r8                      ; copy actual string length into %r9
            shr r9, 1                       ; divide %r9 by 2
            dec r9                          ; decrease %r9 so we get the index of the last character to reverse
            xor rcx, rcx                    ; reset %rcx to zero - it will be the pointer to the left character
            dec r8                          ; while %r8 will be the pointer to the right character
            .revloop:
                mov r10b, byte [rdi+rcx]    ; copy left character to %r10
                mov r11b, byte [rdi+r8]     ; copy right character to %r11
                mov byte [rdi+rcx], r11b    ; write right character to position of left character
                mov byte [rdi+r8], r10b     ; write left character to position of right character
                cmp rcx, r9                 ; are we done now? check if left pointer is on last position to swap
                je .donereversing           ; if so, leave this loop
                dec r8                      ; shift right pointer one step to the left
                inc rcx                     ; shift left pointer one step to the right
            jmp .revloop                    ; continue reversing
        .donereversing:
        
        pop r11                             ; restore registers
        pop r10                             ; ...
        pop r9                              ; ...
        pop r8                              ; ...
        pop rdi                             ; ...
        pop rdx                             ; ...
        pop rcx                             ; ...
        pop rbx                             ; ...
        pop rax                             ; till here
    ret
    
    global _start
    _start:                                 ; main procedure
    
    ; initialize counters and buffers and add prime number 2 "manually"
    xor r8, r8                              ; set %r8 to zero - we'll count the found prime numbers here.
    mov qword [PrimeCache], 2               ; add 2 to the buffer of prime numbers and...
    inc r8                                  ; increase r8
    mov qword [PrimeCache+r8*8], 3          ; add 3 to the buffer of prime numbers and...
    inc r8                                  ; increase r8
    mov rax, 5                              ; start counting at 5
    
    ; and off we go
    .fillprimecache:
        mov rbx, rax                        ; store current number in %rbx
        call isPrime                        ; test if number in %rax is prime
        test rax, rax                       ; if so...
        jz .addnumberinrbx                  ; add the number
        .continueafteradding:               ; (or after falling through)
        mov rax, rbx                        ; restore the number in %rax
        add rax, 2                          ; and go to the next number
        cmp rax, 100000                     ; compare this number to 100000
    jb .fillprimecache                      ; if it's not 100000 yet, continue the loop
    jmp .printresults                       ; otherwise, print results
    
    .addnumberinrbx:                        ; add the number in %rbx to PrimeCache
        mov qword [PrimeCache+r8*8], rbx    ; store the number at the spot where it belongs
        inc r8                              ; and increment %r8
    jmp .continueafteradding                ; continue the loop
    
    .printresults:
        xor r9, r9                          ; set %r9 to zero
        .printloop:
            mov rax, [PrimeCache+r9*8]      ; load current prime number
            
            mov rbx, 10                     ; set radix to 10
            mov rcx, 9                      ; set buffer length to 9 so we can add newline after the number
            mov rdi, StrBuffer              ; pass pointer to StrBuffer
            call itoafast                   ; convert to human-readable number
            mov word [StrBuffer+8], 0x0a    ; write 0a 00 at end of StrBuffer (LF NUL)
            
            mov rax, SYS_WRITE              ; select SYS_WRITE
            mov rdi, STDOUT                 ; select STDOUT
            mov rsi, rcx                    ; pass buffer pointer to %rsi
            syscall                         ; perform SYS_WRITE
            
            inc r9                          ; increase counter
            cmp r9, r8                      ; are we still below %r8, the prime number count?
        jb .printloop                       ; then continue looping.
        
        ; Otherwise end:
        mov rax, SYS_EXIT                   ; select SYS_EXIT
        mov rdi, 0                          ; pass return value 0
        syscall                             ; perform SYS_EXIT
