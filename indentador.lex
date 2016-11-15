

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
    else
      printf("%s", cadena);
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
controlSinLinea        ({tipomas}{espacio}({parentesis}|{parentesisFor}){sentencia})


%%
  /*----- Sección de Reglas ----------------*/

{comentario}           {depurar("Comentario");
                        escribir(); // Debemos dejarlos igual
                        if (yytext[1] == '*') // Si es un comentario largo
                          escribirCadena("\n", 1);

                        // Consecuencias
                        inicioLinea    = true;
                        insertadaLinea = true;
                        lineaProcesada = false;
                        anteriorLlave  = false;
                       }

{cadenaTexto}          {depurar("Cadena texto");
                        escribir(); // Debemos dejarla igual

                        // Consecuencias
                        insertadaLinea = false;
                        anteriorLlave  = false;
                       }

(\ )+                  {depurar("Espacios");
                        escribirCadena(" ", 1); // Conseguimos homogeneidad

                        // Consecuencias
                        insertadaLinea = false;
                        anteriorLlave  = false;
                       }

(\t)+                  {depurar("Tabuladores");
                        escribirCadena("\t", 1); // Homogeneidad

                        // Consecuencias
                        insertadaLinea = false;
                        anteriorLlave  = false;
                       }

{espacio}*,{espacio}*  {depurar("Coma");
                        escribirCadena(", ", 2);

                        // Consecuencias
                        insertadaLinea = false;
                        anteriorLlave = false;
                       }

{espacio}+\*{espacio}+ {depurar("Asterisco");
                       escribirCadena(" *", 2);

                       // Consecuencias
                       insertadaLinea = false;
                       anteriorLlave = false;
                      }


{puntoComa}            {depurar("PuntoComa"); // Separamos esto del espacioVacia por los comentarios
                        int posicion;
                        bool comentario = hayComentario(&posicion);

                        escribirCadena(";", 1);
                        if (comentario){
                          escribirCadena("\t", 1);
                          escribirCadena(yytext+posicion, yyleng-posicion);
                        }

                        if (!esBloque){
                            escribirCadena("\n", 1);
                            inicioLinea    = true;
                            insertadaLinea = true;
                            lineaProcesada = false;
                            anteriorLlave  = false;
                        }
                        else{
                          escribirCadena(" ", 1);
                          anteriorLlave = false;
                        }
                       }

{espacioDoble}         {depurar("Espacio doble");
                        char *c;
                        int i;

                        escribirCadena(" ", 1);
                        for (i=0; i<yyleng; ++i){
                          if (yytext[i] != ' ' && yytext[i] != '\t'){
                            *c = yytext[i];
                            escribirCadena(yytext+i, 1);
                          }
                        }
                        escribirCadena(" ", 1);

                        // Consecuencias
                        anteriorLlave = false;
                       }

{espacioVacio}         {depurar("Espacio vacío");
                        char *c;
                        int antes = esBloque, despues, i;
                        bloque();     // Comprueba si hay nuevos paréntesis
                        despues = esBloque;

                        if ( ((despues - antes) == 1) && (despues == 1) ) // Si es el primer (
                          escribirCadena(" ", 1);

                        for (int i=0; i<yyleng; ++i){
                          if (yytext[i] != ' ' && yytext[i] != '\t'){
                            *c = yytext[i];
                            escribirCadena(yytext+i, 1);
                          }
                        }
                       }

{llaveFea}             {depurar("Llave fea");
                        int lineaComent, i;
                        char *c;

                        escribirCadena("){", 2);
                        --esBloque;

                        if (hayComentario(&lineaComent)){
                          for (i=lineaComent; i<(yyleng-1); ++i){
                            *c = yytext[i];
                            escribirCadena(yytext+i, 1);
                          }
                        }

                        if (!lineaProcesada)
                          ++numIndex;

                        escribirCadena("\n", 1);

                        // Consecuencias
                        inicioLinea    = true;
                        insertadaLinea = true;
                        lineaProcesada = false;
                        anteriorLlave  = false; // Usamos este bool solo para llaves '}'
                       }

{controlSinLinea}      {depurar("Control sin línea"); // Ejemplo: if (condicion) noIntro();
                        int parentesis = ultimoParentesisDerecho(), i,j;
                        char c;

                        // Estructura de control
                        char fila1[yyleng], fila2[yyleng];

                        for (i=0; i<=parentesis; ++i)
                          fila1[i] = yytext[i];
                        fila1[i] = '\0';

                        // Escribimos primera fila
                        for (int j=0; j<numIndex; ++j)
                          escribirCadena("\t", 1);
                        escribirCadena(fila1, parentesis+1);
                        escribirCadena("\n", 1);

                        while (yytext[i] == ' ' || yytext[i] == '\t') // Quitamos espacios
                          ++i;

                        i = i-1; // Primera letra de la segunda fila
                        for(j=i; j<yyleng; ++j)
                          fila2[j-i] = yytext[j];
                        fila2[j] = '\0';

                        // Escribimos segunda fila
                        for (i=0; i<(numIndex+1); ++i)
                          escribirCadena("\t", 1);
                        escribirCadena(fila2, yyleng-i);
                       }


{tipomas}              {depurar("Tipo más"); // Añadimos una tabulación
                        escribir();
                        ++numIndex;

                        // Consecuencias
                        insertadaLinea = false;
                        inicioLinea    = false;
                        lineaProcesada = true;
                        anteriorLlave  = false;
                       }


{tipomenos}            {depurar("Tipo menos"); // Quitamos una tabulación
                        --numIndex;
                        if (anteriorLlave == false)
                          escribirCadena("\n", 1);
                        escribir();
                        escribirCadena("\n", 1);

                        // Consecuencias
                        insertadaLinea = true;
                        inicioLinea    = true;
                        lineaProcesada = false;
                        anteriorLlave  = true;
                       }

\n                     {depurar("Nueva línea");
                        if (!insertadaLinea){
                          escribirCadena("\n", 1);

                          // Consecuencias
                          lineaProcesada = false;
                          inicioLinea    = true;
                          insertadaLinea = false;
                          // Si pones anteriorLlave=false la variable no serviría de nada
                        }
                       }

.                     {depurar("Punto");
                       escribir();

                       // Consecuencias
                       insertadaLinea = false;
                       anteriorLlave  = false;
                      }


%%


  /*----- Sección de Procedimientos --------*/

int main (int argc, char *argv[]){
  if (argc == 2 || argc == 3){
    yyin = fopen (argv[1], "rt");

    if (yyin == NULL){
      printf ("El fichero %s no se puede abrir para lectura.\n", argv[1]);
      exit (-1);
    }
    if (argc == 3){
       //fichSalida = argv[2];
       //fp = fopen(fichSalida, "w");
       yyout = fopen(argv[2], "w");

       salidaFichero = true;
    }
  }
  else return 1;

  yylex ();
  return 0;
}
