
all:
	clang -arch i386 -arch x86_64 -fmodules src/activate.m -o activate -framework Foundation
