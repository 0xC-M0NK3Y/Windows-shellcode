#include <stdio.h>
#include <stdint.h>

#include <windows.h>
#include <winternl.h>

int checkchar(unsigned short *s1, size_t len, char c) {
	for (size_t i = 0; i < len; i++) {
		if ((char)s1[i] == c)
			return 1;
	}
	return 0;
}

void print_name(UNICODE_STRING s) {
	for (int i = 0; i < s.Length; i++) {
		printf("%c", s.Buffer[i]);
	}
	puts("");
}

/*  	Was to inspect the undocumented struct    */
void print_entry(PLDR_DATA_TABLE_ENTRY entry) {
	printf("NAME at : 0x%llx\n", &entry->FullDllName.Buffer);
	printf("NAME at : 0x%llx\n", entry->FullDllName.Buffer);
	print_name(entry->FullDllName);
	printf("0x%llx\n", entry->Reserved1[0]);
	printf("0x%llx\n", entry->Reserved1[1]);
	printf("0x%llx\n", entry->Reserved2[0]);
	printf("0x%llx\n", entry->Reserved2[1]);
	printf("0x%llx\n", entry->Reserved3[0]);
	printf("0x%llx\n", entry->Reserved3[1]);
	for (int i = 0; i < 8; i++)
		printf("%c 0x%X\n", entry->Reserved4[i]);
	printf("0x%llx\n", entry->Reserved5[0]);
	printf("0x%llx\n", entry->Reserved5[1]);
	printf("0x%llx\n", entry->Reserved5[2]);
	printf("0x%llx\n", entry->Reserved6);
	printf("dllbase 0x%llx\n", entry->DllBase);
	puts("\n");
}

int main(void)
{
	PPEB peb = (PPEB)__readgsqword(0x60);
	PPEB_LDR_DATA ldr = (PPEB_LDR_DATA) peb->Ldr;
	PLIST_ENTRY table = &ldr->InMemoryOrderModuleList;
	uintptr_t kern32;

	while (table)
	{
		PLDR_DATA_TABLE_ENTRY entry = (PLDR_DATA_TABLE_ENTRY)table->Flink;

		//print_entry(entry);
		table = table->Flink;
		if (checkchar(entry->FullDllName.Buffer, entry->FullDllName.Length, '3') && checkchar(entry->FullDllName.Buffer, entry->FullDllName.Length, '2')) {
			kern32 = (uintptr_t)entry->Reserved2[0];
			break;
		}
		if (entry->FullDllName.Buffer == NULL)
			break;
	}

	PIMAGE_DOS_HEADER dos = (PIMAGE_DOS_HEADER) kern32;
	PIMAGE_NT_HEADERS64 nt = (PIMAGE_NT_HEADERS64)(kern32 + dos->e_lfanew);
	PIMAGE_EXPORT_DIRECTORY exp = (PIMAGE_EXPORT_DIRECTORY)(kern32 + nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress);
	uint32_t *names = (uint32_t *)(kern32 + exp->AddressOfNames);
	uint32_t *funcs = (uint32_t *)(kern32 + exp->AddressOfFunctions);
	size_t nb = exp->NumberOfNames;

	uintptr_t getstdhandle = 0;
	uintptr_t writeconsolea = 0;

	for (size_t i = 0; i < nb; i++) {
		if (strcmp((const char *)(kern32 + names[i]), "GetStdHandle") == 0) {
			getstdhandle = kern32 + funcs[i];
		} else if (strcmp((const char *)(kern32 + names[i]), "WriteConsoleA") == 0) {
			writeconsolea = kern32 + funcs[i];
		}
	}

	BOOL (*w)(HANDLE, const VOID *, DWORD, LPDWORD, LPVOID) = (BOOL (*)(HANDLE, const VOID *, DWORD, LPDWORD, LPVOID))writeconsolea;
	HANDLE (*f)(DWORD) = (HANDLE (*)(DWORD))getstdhandle;

	HANDLE stdoout = f(STD_OUTPUT_HANDLE);
	unsigned long a;
	w(stdoout, "Bonjour!!!!!\n", sizeof("Bonjour!!!!!\n")-1, &a, NULL);
	return 0;
}
