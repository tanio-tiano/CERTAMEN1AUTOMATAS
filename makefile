all: parser

parser: scanner.l parser.y
	bison -d parser.y
	flex scanner.l
	gcc parser.tab.c lex.yy.c -o pandemia -lfl -lm
	./pandemia

clear:
	rm -f parser lex.yy.c parser.tab.c parser.tab.h intento
	clear
