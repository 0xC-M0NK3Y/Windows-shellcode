# Windows-shellcode
Example of shellcoding on Windows

You can see in main.c the equivalent C code of shellcode.asm.  
The shellcode is in shellcode.asm.  
In shellcode.c you have an example of using this shellcode.  
This is only for 64 bits, but its done the same way in 32 bits.

## Explanation

Get the address of the PEB (gs:0x60),  
Get the double linked list of the loader data,  
Search for kernel32.dll and get its image base (where its loaded),  
Go throught the export table and search for the function you need,  
Once you got your pointers, you can do whatever you want with.  
  
This shellcode contains nullbytes, but can be easely be removed.

## Build

```bash
  $ nasm -f win64 shellcode.asm
```
Extract the shellcode of shellcode.obj  
Put it in your buffer.  

To compile shellcode.c or main.c to test:
```bash
  $ x86_64-w64-mingw32-gcc shellcode.c -o shellcode.exe
  $ x86_64-w64-mingw32-gcc main.c -o test.exe
```
