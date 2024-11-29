%{
#include "parser.tab.h"  // Incluir el archivo de encabezado generado por Bison
#include <stdlib.h>      // Incluir stdlib.h para usar atoi
void showError ();
%}

DIGIT       [0-9]
ID          [a-zA-Z_][a-zA-Z0-9_]*
NUM         {DIGIT}+(\.{DIGIT}+)?([eE][-+]?{DIGIT}+)?

%%

[0-9]+         { yylval = atoi(yytext); return NUM; }   // Reconoce números y los guarda en yylval
"INICIALIZAR"       { return INICIALIZAR; }
"IMPRIMIR_AUTOMATA"   { return IMPRIMIR_AUTOMATA; }
"AISLAR"        { return AISLAR; }
"SIMULAR"       { return SIMULAR; }
"DESAISLAR"     { return DESAISLAR; }
"IMPRIMIR_CELDA"    { return IMPRIMIR_CELDA; }
"AISLAR_TODO"       { return AISLAR_TODO; }
";"                 { return PUNTOCOMA; }

"/*"([^*]|(\*+[^*/]))*\*+"/"     { /* Ignorar comentarios de bloque */ }
"//".*                           { /* Ignorar comentarios de línea */ }
[\n\r]                           { /* Ignorar saltos de línea */ }
[ \t]+                           { /* Ignorar espacios y tabulaciones */ }

.                {showError(); return(OTHER);}  // Retorna cualquier otro símbolo como su valor ASCII

%%

void showError(){
    printf(" <<ErrorLexico: \"%s\">>\n", yytext);
}

