{controlSinLinea}      {depurar("Control sin línea"); // Ejemplo: if (condicion) noIntro();
                        int parentesis = ultimoParentesisDerecho(), i=0,j=0, inicio=0;
                        char fila1[yyleng], fila2[yyleng]; // Estructura de control

                        if (parentesis == 0){ // sentencia else
                          int index = 0;
                          while (yytext[index] == ' ' || yytext[index] == '\t')
                            ++index;
                          parentesis = index+4; // else
                        }

                        while (yytext[i] == ' ' || yytext[i] == '\t')
                          ++i;
                        inicio = i;

                        for (i; i<=parentesis; ++i)
                          fila1[i-inicio] = yytext[i];
                        //fila1[i] = '\0';

                        for (int j=0; j<numIndex; ++j)  // Escribimos primera fila
                          escribirCadena("\t", 1);
                        escribirCadena(fila1, parentesis+1-inicio);
                        escribirCadena("{\n", 2);

                        while (yytext[i] == ' ' || yytext[i] == '\t') // Quitamos espacios
                          ++i;
                        i = i-1; // Primera letra de la segunda fila

                        // Escribimos segunda fila
                        for (int k=0; k<(numIndex+1); ++k)
                          escribirCadena("\t", 1);

                        for (int k=0; k<(yyleng-i); ++k)
                          escribirCadena(yytext+i+k, 1);
                        escribirCadena("\n}\n", 3);

                        inicioLinea    = true;
                        insertadaLinea = true;
                        lineaProcesada = false;
                        anteriorLlave  = false;
                       }
