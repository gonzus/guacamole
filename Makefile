C_FILES    = \
	lexer.c \
	parser.c \
	expr.c \
	node.c \
	symtab.c \
	ast.c \
	main.c \

CC         = cc
CPPFLAGS  +=

# use ANSI C
CFLAGS    += -std=c89

# warn a lot
CFLAGS    += -Wall

# allow // comments
CFLAGS    += -Wno-comment

# compile / link for debugging
ALL_FLAGS += -g

all: main

O_FILES   = $(C_FILES:.c=.o)

%.o : %.c
	$(CC) -c $(ALL_FLAGS) $(CFLAGS) $(CPPFLAGS) $< -o $@

main: $(O_FILES)
	$(CC) $(ALL_FLAGS) $^ -o $@

lexer.c lexer.h: lexer.l
	flex --bison-locations lexer.l

parser.c parser.h: parser.y lexer.h
	bison --locations parser.y

lexer.o: lexer.c parser.h
parser.o: parser.c parser.h lexer.h
expr.o: expr.c parser.h lexer.h
node.o: node.c
symtab.o: symtab.c
ast.o: ast.c
main.o: main.c

clean:
	rm -f *.o *~ lexer.c lexer.h parser.c parser.h main
	rm -fr main.dSYM

