all: primelist_asm primelist_gcc primelist_asm_debug primelist_clang

primelist_asm: primelist_asm.o
	ld -o primelist_asm primelist_asm.o
	
primelist_asm.o: primelist.asm
	nasm -f elf64 primelist.asm -o primelist_asm.o
	
primelist_asm_debug: primelist_asm_debug.o
	ld -o primelist_asm_debug primelist_asm_debug.o
	
primelist_asm_debug.o: primelist.asm
	nasm -f elf64 -g -F stabs -o primelist_asm_debug.o -l primelist_asm_debug.lst primelist.asm
	
primelist_gcc: primelist.c
	gcc primelist.c -o primelist_gcc -O3
	
primelist_clang: primelist.c
	clang primelist.c -o primelist_clang -O3

clean:
	rm *.o primelist_asm primelist_gcc primelist_asm_debug primelist_clang *.lst

benchmark: all
	time ./primelist_asm_debug > /dev/null
	time ./primelist_asm > /dev/null
	time ./primelist_gcc > /dev/null
	time ./primelist_clang > /dev/null
