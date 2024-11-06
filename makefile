all: parser

parser: scanner.l parser.y
	bison -d parser.y
	flex scanner.l
	gcc parser.tab.c lex.yy.c -o intento -lfl

clean:
	rm -f parser lex.yy.c parser.tab.c parser.tab.h