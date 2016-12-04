
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
                        if (!inicioLinea){
                          escribirCadena(" ", 1); // Conseguimos homogeneidad

                          // Consecuencias
                          insertadaLinea = false;
                          anteriorLlave  = false;
                          inicioLinea = false;
                        }
                       }

(\t)+                  {depurar("Tabuladores");
                        if (!inicioLinea){
                          escribirCadena("\t", 1); // Conseguimos homogeneidad

                          // Consecuencias
                          insertadaLinea = false;
                          anteriorLlave  = false;
                          inicioLinea = false;
                        }
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
                          //printf("\n-%c-\n", yytext[i]);fflush(stdout);

                            escribirCadena(yytext+i, 1);

                          }
                        }
                        escribirCadena(" ", 1);

                        // Consecuencias
                        anteriorLlave = false;
                       }

{espacioVacio}         {depurar("Espacio vacío");
                        int antes = esBloque, despues, i;

                        bloque();     // Comprueba si hay nuevos paréntesis
                        despues = esBloque;
                        if ( ((despues - antes) == 1) && (despues == 1) ) // Si es el primer (
                          escribirCadena(" ", 1);

                        for (int i=0; i<yyleng; ++i){
                          if (yytext[i] != ' ' && yytext[i] != '\t')
                            escribirCadena(yytext+i, 1);
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
                        if (anteriorLlave == false && (!insertadaLinea)){
                          escribirCadena("\n", 1);
                          //printf("--");
                          }
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
                          insertadaLinea = true;
                          // Si pones anteriorLlave=false la variable no serviría de nada
                        }
                       }

.                     {depurar("Punto");
                       escribir();

                       // Consecuencias
                       insertadaLinea = false;
                       anteriorLlave  = false;
                      }
