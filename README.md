# Windows-shellcode
Example of shellcoding on Windows

You can see in main.c the equivalent C code of shellcode.asm.  
The shellcode is in shellcode.asm.  
In shellcode.c you have an example of using this shellcode.  

## Explanation

Get the address of the PEB (gs:0x60),  
Get the double linked list of the loader data,  
Search for kernel32.dll and get its image base (where its loaded),  
Go throught the export table and search for the function you need,  
Once you got your pointers, you can do whatever you want with.  
  
This shellcode contains nullbytes, but can be easely be removed.

