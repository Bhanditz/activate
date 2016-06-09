
CFLAGS:=-arch i386 -arch x86_64 -Wall -Os ${CFLAGS}
LDFLAGS:=-framework Foundation -framework AppKit
CLANG:=clang
STRIP:=strip

ACTIVATE_CFLAGS?=-DACTIVATE_VERSION=\"head\"

all:
	${CLANG} ${CFLAGS} ${ACTIVATE_CFLAGS} src/activate.m -o activate ${LDFLAGS}
	${STRIP} activate
