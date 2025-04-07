all: asm result

result: main.cpp MyPrintf.o
	gcc -g -no-pie main.cpp MyPrintf.o -o program

asm: My_Printf.asm
	nasm -g -f elf64 -l printf.lst -o MyPrintf.o My_Printf.asm

.PHONY: clean

clean:
	rm -rf *.o MyPrintf


