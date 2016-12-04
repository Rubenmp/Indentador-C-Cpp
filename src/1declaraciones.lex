
  /*----- Secci�n de Declaraciones --------------*/
%{
#include <stdio.h>
#include <stdlib.h>     /* atoi */
#include <ctype.h>      /* tolower */
#include <sys/wait.h>
typedef enum { false, true } bool;

// Variables
long int numIndex   = 0;      // Tabulaciones necesarias
int  esBloque       = 0;      // (Bloque)

bool inicioLinea    = true;
bool insertadaLinea = false;
bool lineaProcesada = false;
bool anteriorLlave  = false;  // Llave '}' solamente
bool salidaFichero  = false;  // Solo se modifica 0/1 veces



// Funciones

// Escribe yytext en pantalla teniendo en cuenta el formato,
// si es inicio de línea imprime las tabulaciones necesarias.
void escribir(){
  int i = 0, j;

  if (inicioLinea){
    while (yytext[i] == ' ' || yytext[i] == '\t')
      ++i;

    for(j=0; j<numIndex; ++j){
      if (salidaFichero)
        fwrite("\t", yyleng, 1, yyout);
      else
        printf("\t");
    }
  }

  if (salidaFichero)
    fwrite(yytext+i, yyleng-i, 1, yyout);
  else
    printf("%s", yytext+i);

  inicioLinea = false;
}


// Esta función es necesaria ya que no debemos cambiar yytext a lo largo
// del programa, además pueden darse situaciones en las que se necesite.
void escribirCadena(char *cadena, int n){
    if (salidaFichero)
      fwrite(cadena, n, 1, yyout);
    else{
      for (int i=0; i<n; ++i)
        printf("%c", cadena[i]);
    }
}


// Nos ayuda a saber si un carácter está dentro de unos paréntesis o no.
void bloque(){
  for (int i=0; i<yyleng; ++i){
    if (yytext[i] == '(')
      ++esBloque;
    else if (yytext[i] == ')')
      --esBloque;
  }
}

// Función claramente indicativa, nos ayuda a ajustar bloques sin saltos
// de línea como:
//    if (condicion) ahorrarespacio();

int ultimoParentesisDerecho(){
  int posParentesis = 0, i;
  for (i=0; i<yyleng; ++i){
    if (yytext[i] == ')')
      posParentesis = i;
  }

  return posParentesis;
}

// Nos dice si tiene comentario yytext, útil para arreglar las estructuras del tipo
// if (condicion) // comentario
// {
//    sentencias;
// }
bool hayComentario(int *lineaComent){
  char antes = ' ', actual;
  bool comentario = false;
  int i;

  for (i=0; i<yyleng && !comentario; ++i){
    actual = yytext[i];
    if ((antes == actual == '/') || ((antes == '/') && (actual == '*'))){
      comentario = true;
      *lineaComent = i-1;
    }
    antes = actual;
  }

  return comentario;
}

// Función para saber en qué expresión regular entra cada vez el programa.
bool boolDepurar = false;
void depurar(char * cadena){
  if (boolDepurar)
    printf("\n------ %s -------\n", cadena); fflush (stdout);
}

%}

  /* EXPRESIONES REGULARES */

  /* Texto */
espacio                (\ |\t)
blanco                 ({espacio}|\n)
caracter               ('(.|\\n|\\t|\\b)')
cadenaTexto            ((\"([^(\")]|"\"")+\")|{caracter})
sentencia              (([^;]|{cadenaTexto})*;)


  /* Estructuras de control */
obj                    (struct|class|union)
control                (if|else|for|while|switch|case)
excepcion              (try|catch)
clase                  (public|private)
main                   (int{blanco}+main)

tipomas                (({espacio}*)({obj}|{control}|{excepcion}|{clase}|{main}))
tipomenos              (\})


  /* Comentarios */
comentarioLinea        \/\/.*\n
comentarioLargo        ("/*"([^*]|(\*+[^\/]))*\*\/)

comentario             ({comentarioLinea}|{comentarioLargo})


  /* Separaciones con espacios */
tipoDoble              (=|==|\+=|-=|\*=|\/=|\+|-|\*)
tipoVacio              ("++"|"--"|\(|\))
parentesis             (\([^;]+\))
parentesisFor          (\([^;]*;[^;]*;[^;]*\))

espacioDoble           ({espacio}*{tipoDoble}{espacio}*)
espacioVacio           ({espacio}*{tipoVacio}{espacio}*)

llaveFea               ({blanco}*\)({comentario}|{blanco})*\{)
puntoComa              ({espacio}*;{espacio}*{comentarioLinea}?)
controlSinLinea        ({control}{espacio}({parentesis}|{parentesisFor})?{sentencia})
