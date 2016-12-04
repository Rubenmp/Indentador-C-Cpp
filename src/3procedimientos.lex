
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

