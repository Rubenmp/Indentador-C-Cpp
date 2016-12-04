#!/bin/bash

# Primera pasada para poner los bloques correctamente
cat ./src/1declaraciones.lex  > indentador.lex
echo "%%"                     >> indentador.lex
cat ./src/2reglas.lex         >> indentador.lex
cat ./src/controlSinLinea.lex >> indentador.lex
echo "%%"                     >> indentador.lex
cat ./src/3procedimientos.lex >> indentador.lex

lex indentador.lex
gcc lex.yy.c -ll -o indentador
#rm  -f lex.yy.c indentador.lex
./indentador $1 archivoaux.txt


# Segunda pasada
cat ./src/1declaraciones.lex  > indentador.lex
echo "%%"                     >> indentador.lex
cat ./src/2reglas.lex         >> indentador.lex
echo "%%"                     >> indentador.lex
cat ./src/3procedimientos.lex >> indentador.lex

lex indentador.lex
gcc lex.yy.c -ll -o indentador
#rm  -f lex.yy.c indentador.lex
./indentador archivoaux.txt

rm -f archivoaux.txt
