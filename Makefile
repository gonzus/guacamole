C_FILES    = \
	gmem.c \
	flags.c \
	lexer.c \
	parser.c \
	oper.c \
	node.c \
	symtab.c \
	ast.c \
	main.c \

CC         = cc
CPPFLAGS  += -DGMEM_CHECK

# use ANSI C
CFLAGS    += -std=c89

# warn a lot
CFLAGS    += -Wall

# allow // comments
CFLAGS    += -Wno-comment

# compile / link for debugging
ALL_FLAGS += -g

# C compiler flags for lexer.c
C_LEXER_FLAGS = -Wno-unused-function -Wno-unneeded-internal-declaration

all: main

O_FILES   = $(C_FILES:.c=.o)

%.o : %.c
	$(CC) -c $(ALL_FLAGS) $(CFLAGS) $(CPPFLAGS) $< -o $@

main: $(O_FILES)
	$(CC) $(ALL_FLAGS) $^ -o $@

lexer.c lexer.h: lexer.l
	flex --bison-locations lexer.l

parser.c parser.h: parser.y lexer.h
	bison --locations --verbose -g parser.y

lexer.o: lexer.c parser.h
	$(CC) -c $(ALL_FLAGS) $(CFLAGS) $(CPPFLAGS) $(C_LEXER_FLAGS) $< -o $@

gmem.o: gmem.c
flags.o: flags.c
parser.o: parser.c parser.h lexer.h
oper.o: oper.c
node.o: node.c
symtab.o: symtab.c
ast.o: ast.c
main.o: main.c

clean:
	rm -f *.o *~
	rm -f lexer.c lexer.h
	rm -f parser.c parser.h parser.dot parser.output
	rm -fr main main.dSYM

