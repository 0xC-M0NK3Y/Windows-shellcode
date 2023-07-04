bits 64

SECTION .text

WRITECONSOLEA equ 0x8
GETSTDHANDLE equ 0x10
DUMMY equ 0x14

WRITECONSOLEA_STR equ 0x22
GETSTDHANDLE_STR equ 0x2F
MESSAGE_STR equ 0x34

global main

main:
    mov rbp, rsp
    sub rsp, 0x40

    xor rax, rax
    mov BYTE [rbp-WRITECONSOLEA_STR], 0x57
    mov DWORD [rbp-WRITECONSOLEA_STR+1], 0x65746972
    mov DWORD [rbp-WRITECONSOLEA_STR+5], 0x736E6F43
    mov DWORD [rbp-WRITECONSOLEA_STR+9], 0x41656C6F
    mov DWORD [rbp-GETSTDHANDLE_STR], 0x53746547
    mov DWORD [rbp-GETSTDHANDLE_STR+4], 0x61486474
    mov DWORD [rbp-GETSTDHANDLE_STR+8], 0x656C646E
    mov DWORD [rbp-MESSAGE_STR], 0x68736557

    xor rdi, rdi
    mov rdi, QWORD [gs:0x60] ; PEB
    mov rdi, QWORD [rdi+0x18] ; LDR_DATA
    lea rdi, QWORD [rdi+0x20] ; &LDR_DATA->InMemoryOrderModuleList.Flink
for:
    mov rdi, QWORD [rdi]
    mov rax, QWORD [rdi+0x50] ; entry->FullDllName.Buffer
    test rax, rax
    je fail
    mov rax, QWORD [rax+8]  ; windows has string like this in ram "K\0E\0R\0N\0E\0L\03\02\0"
                            ; so check for the '3' and '2', should not interfere with other names in theory
                            ; could also check all chars with [rax] and [rax+8] of "KERNEL32"
    shr rax, 0x20
    cmp al, 0x33
    je check_next
    jmp for
found:
    mov rax, QWORD [rdi+0x20] ; *kernel32.dll, dos_header
    xor rcx, rcx
    mov ecx, DWORD [rax+0x3c] ; e_lfanew
    lea rdi, QWORD [rax+rcx]  ; nt_headers
    mov ecx, DWORD [rdi+0x88] ; DataDirectory[0].VirtualAddress
    lea rdi, QWORD [rax+rcx]  ; *exports
    mov ecx, DWORD [rdi+0x20] ; AddressOfNames
    lea r8, QWORD [rax+rcx]   ; *names
    mov ecx, DWORD [rdi+0x1C] ; AddressOfFunctions
    lea r9, QWORD [rax+rcx]   ; *funcs
    mov ecx, DWORD [rdi+0x18] ; NumberOfNames

    ; search with comparing names our functions
    xor rdx, rdx
    xor r11, r11
for2:
    mov r11d, DWORD [r8+rdx*4] ; names[i]
    lea r10, QWORD [rax+r11]   ; *kernel32.dll + names[i]
    lea r12, [rbp-GETSTDHANDLE_STR]
    call strcmp
    cmp r13b, 1
    je found_getstdhandle
back:
    lea r12, [rbp-WRITECONSOLEA_STR]
    call strcmp
    cmp r13b, 1
    je found_writeconsolea
back2:
    inc rdx
    cmp edx, ecx 
    jb for2

    ; once you have the functions, do what you want

    or ecx, 0xFFFFFFFF
    sub cx, 11
    mov rax, QWORD [rbp-GETSTDHANDLE]   
    call rax                            ; GetStdHandle((DWORD)-11);
    mov rcx, rax ; HANDLE stdout
    lea rdx, [rbp-MESSAGE_STR]
    xor r8, r8
    push r8
    add r8, 4
    lea r9, QWORD [rbp-DUMMY]
    mov rax, QWORD [rbp-WRITECONSOLEA]
    call rax                            ; WriteConsoleA(HANDLE, msg, msg_len, &, NULL);
    ret

check_next:
    shr rax, 0x10
    cmp al, 0x32
    jne for
    jmp found

found_writeconsolea:
    mov r11d, DWORD [r9+rdx*4]
    lea rdi, QWORD [rax+r11]
    mov [rbp-WRITECONSOLEA], rdi
    jmp back2

found_getstdhandle:
    mov r11d, DWORD [r9+rdx*4]
    lea rdi, QWORD [rax+r11]
    mov [rbp-GETSTDHANDLE], rdi
    jmp back

; custom strcmp function, no convention calling
strcmp:
    xor r15, r15
    xor r14, r14
    xor r13, r13
for_strcmp:
    mov r14b, BYTE [r10+r15]
    cmp r14b, BYTE [r12+r15]
    jne end_strcmp
    test r14b, r14b
    je ret_one_strcmp
    inc r15
    jmp for_strcmp
ret_one_strcmp:
    mov r13b, 1
end_strcmp:
    ret

fail:
    ret
