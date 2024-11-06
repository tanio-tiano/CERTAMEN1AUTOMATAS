%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
void yyerror(const char *s);

#define MAX_AUTOMATAS 10  // Número máximo de autómatas que se pueden crear

typedef struct EstadoCelda {
    int susceptibles;
    int infectados;
    int recuperados;
    int fallecidos;
    int vacunados;
} EstadoCelda;

typedef struct Automata {
    int id;                
    EstadoCelda **matriz;
    int filas;
    int columnas;
} Automata;

Automata *automatas[MAX_AUTOMATAS];
int num_automatas = 0;
int next_id = 1; 

void inicializar_automata();
void imprimir_automata(int id);

%}

%token NUM INICIALIZAR IMPRIMIR_AUTOMATA OTHER PUNTOCOMA CONECTAR SIMULAR AVANZAR 

%%
program:
    program statement
    | statement
    ;

statement:
    INICIALIZAR NUM NUM NUM NUM NUM NUM NUM PUNTOCOMA {
        // Extrae los valores de los parámetros
        int filas = $2;
        int columnas = $3;
        EstadoCelda valores_iniciales = {
            .susceptibles = $4,
            .infectados = $5,
            .recuperados = $6,
            .fallecidos = $7,
            .vacunados = $8
        };
        
        inicializar_automata(filas, columnas, valores_iniciales);
    }
    | IMPRIMIR_AUTOMATA NUM PUNTOCOMA {
        imprimir_automata($2);
    }
    ;

%%



void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
void inicializar_automata(int filas, int columnas, EstadoCelda valores_iniciales) {
    if (num_automatas >= MAX_AUTOMATAS) {
        printf("Error: no se pueden crear más autómatas.\n");
        return;
    }
    // Crear y asignar memoria para el nuevo autómata
    Automata *nuevo = malloc(sizeof(Automata));
    nuevo->id = next_id++;  // Asignar ID único y luego incrementar el contador
    nuevo->filas = filas;
    nuevo->columnas = columnas;
    nuevo->matriz = malloc(filas * sizeof(EstadoCelda *));
    
    // Inicializar cada celda con los mismos valores
    for (int i = 0; i < filas; i++) {
        nuevo->matriz[i] = malloc(columnas * sizeof(EstadoCelda));
        for (int j = 0; j < columnas; j++) {
            nuevo->matriz[i][j] = valores_iniciales;  // Asignar los mismos valores a cada celda
        }
    }

    // Guardar el autómata en la lista de autómatas
    automatas[num_automatas++] = nuevo;
    printf("Autómata con ID %d inicializado con éxito.\n", nuevo->id);
}
void imprimir_automata(int id) {
    // Buscar el autómata con el ID especificado
    Automata *automata = NULL;
    for (int i = 0; i < num_automatas; i++) {
        if (automatas[i]->id == id) {
            automata = automatas[i];
            break;
        }
    }

    if (automata == NULL) {
        printf("Error: autómata no encontrado con el ID %d.\n", id);
        return;
    }

    printf("\nAutómata ID %d:\n", automata->id);

    // Encabezado de columnas
    printf("        ");
    for (int j = 0; j < automata->columnas; j++) {
        printf("    Col %d           ", j);
    }
    printf("\n");

    // Separador superior de la tabla
    printf("        ");
    for (int j = 0; j < automata->columnas; j++) {
        printf("───────────────");
    }
    printf("\n");

    // Imprimir cada fila de la matriz con los valores de cada celda
    for (int i = 1; i < automata->filas; i++) {
        printf("Fila %d │", i);
        for (int j = 0; j < automata->columnas; j++) {
            EstadoCelda celda = automata->matriz[i][j];
            printf("S:%d I:%d R:%d F:%d V:%d│",
                   celda.susceptibles,
                   celda.infectados,
                   celda.recuperados,
                   celda.fallecidos,
                   celda.vacunados);
        }
        printf("\n");

        // Separador entre filas
        printf("        ");
        for (int j = 0; j < automata->columnas; j++) {
            printf("───────────────");
        }
        printf("\n");
    }
}

int main() {
    // Abre el archivo para escribir los comandos
    FILE *file = fopen("comandos.txt", "r");
    if (file == NULL) {
        perror("No se pudo abrir comandos.txt");
        return 1;
    }
    printf("Ingrese 'INICIALIZAR X Y S I R F V;' donde X,Y es la dimension de la matriz y S,I,R,V,F la inicial de cada estado\n");
    stdin = file;
    yyparse();

    // Cierra el archivo después de terminar
    fclose(file);
    return 0;
}

