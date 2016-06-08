
all:
	clang -arch i386 -arch x86_64 src/activate.m -o activate -framework Foundation -framework AppKit
