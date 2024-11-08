%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define MAX_FILAS 6
#define MAX_COLUMNAS 6  
#define MAX_IDS 5  

int yylex();
void yyerror(const char *s);

typedef struct CeldaAutomata {
    int id;  
    int fila, columna;
    int susceptibles, expuestos, infectados, recuperados, fallecidos, vacunados;
    struct CeldaAutomata **vecinos;  // Lista de punteros a vecinos
    int num_vecinos;
} CeldaAutomata;

// Declaración de la matriz y contador de autómatas
CeldaAutomata *matriz[MAX_FILAS][MAX_COLUMNAS] = {NULL};
CeldaAutomata *grupo_por_id[MAX_IDS][MAX_FILAS * MAX_COLUMNAS] = {NULL};
int tamanio_grupo[MAX_IDS] = {0}; // Contador de celdas en cada grupo de ID
int posicion_actual_fila = 0;
int posicion_actual_columna = 0;

CeldaAutomata* inicializar_automata(int id, int susceptibles, int expuestos, int infectados, int recuperados, int fallecidos, int vacunados);
void imprimir_automata(int id);
void avanzar_posicion();
int hay_vecino_con_id(int fila, int columna, int id);
void conectar_vecinos(CeldaAutomata *celda1, CeldaAutomata *celda2);
void imprimir_matriz();
void aislar_vecindad(int id);
void simular_epidemia();
%}

%token NUM INICIALIZAR IMPRIMIR_AUTOMATA OTHER PUNTOCOMA SIMULAR AISLAR

%%

program:
    program statement
    | statement
    ;

statement:
    INICIALIZAR NUM NUM NUM NUM NUM NUM NUM PUNTOCOMA {
        inicializar_automata($2, $3, $4, $5, $6, $7, $8);
    }
    | IMPRIMIR_AUTOMATA NUM PUNTOCOMA {
        imprimir_automata($2);
    }
    | AISLAR NUM PUNTOCOMA {
        aislar_vecindad($2);
    }
    | SIMULAR PUNTOCOMA {
        simular_epidemia();
    }

%%
void avanzar_posicion() {
    posicion_actual_columna++;
    if (posicion_actual_columna >= MAX_COLUMNAS) {
        posicion_actual_columna = 0;
        posicion_actual_fila++;
    }
}

void conectar_vecinos(CeldaAutomata *celda1, CeldaAutomata *celda2) {
    // Aumenta el tamaño del arreglo de vecinos para celda1 y agrega celda2
    celda1->vecinos = realloc(celda1->vecinos, (celda1->num_vecinos + 1) * sizeof(CeldaAutomata *));
    celda1->vecinos[celda1->num_vecinos++] = celda2;

    // Aumenta el tamaño del arreglo de vecinos para celda2 y agrega celda1
    celda2->vecinos = realloc(celda2->vecinos, (celda2->num_vecinos + 1) * sizeof(CeldaAutomata *));
    celda2->vecinos[celda2->num_vecinos++] = celda1;
}

CeldaAutomata* inicializar_automata(int id, int susceptibles, int expuestos, int infectados, int recuperados, int fallecidos, int vacunados) {
    // Si la matriz está llena
    if (posicion_actual_fila >= MAX_FILAS) {
        printf("Error: La matriz está llena. No se pueden agregar más autómatas.\n");
        return NULL;
    }

    // Crear el nuevo autómata
    CeldaAutomata *nuevo_automata = malloc(sizeof(CeldaAutomata));
    nuevo_automata->id = id;
    nuevo_automata->fila = posicion_actual_fila;
    nuevo_automata->columna = posicion_actual_columna;
    nuevo_automata->susceptibles = susceptibles;
    nuevo_automata->expuestos = expuestos;
    nuevo_automata->infectados = infectados;
    nuevo_automata->recuperados = recuperados;
    nuevo_automata->fallecidos = fallecidos;
    nuevo_automata->vacunados = vacunados;
    nuevo_automata->vecinos = NULL;
    nuevo_automata->num_vecinos = 0;

    // Colocar el autómata en la matriz
    matriz[posicion_actual_fila][posicion_actual_columna] = nuevo_automata;

    // Conectar a vecinos adyacentes sin importar el ID
    int direcciones[4][2] = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
    for (int i = 0; i < 4; i++) {
        int nueva_fila = posicion_actual_fila + direcciones[i][0];
        int nueva_columna = posicion_actual_columna + direcciones[i][1];
        if (nueva_fila >= 0 && nueva_fila < MAX_FILAS && nueva_columna >= 0 && nueva_columna < MAX_COLUMNAS) {
            CeldaAutomata *vecino = matriz[nueva_fila][nueva_columna];
            if (vecino != NULL) {
                conectar_vecinos(nuevo_automata, vecino);
            }
        }
    }

    // Añadir al grupo de celdas con la misma ID
    grupo_por_id[id][tamanio_grupo[id]++] = nuevo_automata;

    // Avanzar a la siguiente posición
    avanzar_posicion();

    printf("Autómata con ID %d inicializado en posición (%d, %d).\n", id, nuevo_automata->fila, nuevo_automata->columna);
    return nuevo_automata;
}



// Función para imprimir todos los autómatas con una ID específica en dos líneas
void imprimir_automata(int id) {
    printf("Información de las celdas con ID %d:\n", id);
    for (int i = 0; i < tamanio_grupo[id]; i++) {
        CeldaAutomata *celda = grupo_por_id[id][i];
        printf("Posición (%d, %d) - S: %d, E: %d, I: %d, R: %d, F: %d, V: %d | ID's de celdas Vecinas: ",
               celda->fila, celda->columna,
               celda->susceptibles, celda->expuestos, celda->infectados, celda->recuperados,
               celda->fallecidos, celda->vacunados);

        // Imprimir los IDs de los vecinos
        for (int j = 0; j < celda->num_vecinos; j++) {
            printf("%d ", celda->vecinos[j]->id);
        }
        printf("\n");
    }
}

void aislar_vecindad(int id) {
    for (int i = 0; i < MAX_FILAS; i++) {
        for (int j = 0; j < MAX_COLUMNAS; j++) {
            CeldaAutomata *celda = matriz[i][j];
            if (celda != NULL && celda->id == id) {
                for (int k = 0; k < celda->num_vecinos; k++) {
                    CeldaAutomata *vecino = celda->vecinos[k];
                    if (vecino->id != id) {
                        // Eliminar la conexión con el vecino de diferente ID
                        for (int m = k; m < celda->num_vecinos - 1; m++) {
                            celda->vecinos[m] = celda->vecinos[m + 1];
                        }
                        celda->num_vecinos--;
                        celda->vecinos = realloc(celda->vecinos, celda->num_vecinos * sizeof(CeldaAutomata *));
                        k--; // Ajustar el índice debido a la eliminación
                    }
                }
            }
        }
    }
    printf("Vecindad aislada para celdas con ID %d.\n", id);
}

void simular_epidemia() {
    // Implementar la simulación de la epidemia
    printf("Simulación de la epidemia realizada.\n");
}
void imprimir_matriz() {
    printf("Matriz de IDs de autómatas:\n");
    for (int i = 0; i < MAX_FILAS; i++) {
        for (int j = 0; j < MAX_COLUMNAS; j++) {
            if (matriz[i][j] != NULL) {
                printf("%2d ", matriz[i][j]->id);  // Imprime la ID con dos dígitos de ancho
            } else {
                printf(" . ");  // Espacio en blanco para celdas vacías
            }
        }
        printf("\n");  // Salto de línea después de cada fila
    }
    printf("\n");
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    // Abre el archivo para escribir los comandos
    FILE *file = fopen("comandos.txt", "r");
    if (file == NULL) {
        perror("No se pudo abrir comandos.txt");
        return 1;
    }
    printf("Ingrese 'INICIALIZAR S I R F V;' donde S,I,R,V,F la inicial de cada estado\n");
    stdin = file;
    yyparse();

    // Cierra el archivo después de terminar
    fclose(file);
    imprimir_matriz();
    return 0;
}
