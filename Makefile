CXXFLAGS= -Wall -Wextra -pedantic -std=c++03 -g

INCLUDE= ./include
BIN=./bin
SRC=./src
OBJ=./obj

all: indentador

indentador: indentador.lex
	lex indentador.lex
	gcc lex.yy.c -ll -o indentador
	rm  lex.yy.c

################################################

clean:
	rm -f lex.lex

mrproper: clean
	rm -f indentador

.PHONY: clean mrproper all
