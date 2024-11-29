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

// Definir tasas de cambio globales ajustadas para simular infecciones
float tasa_infeccion = 0.2;
float tasa_exposicion = 0.15;
float tasa_recuperacion = 0.1;
float tasa_mortalidad = 0.02;
float tasa_vacunacion = 0.05;

CeldaAutomata* inicializar_automata(int id, int susceptibles, int expuestos, int infectados, int recuperados, int fallecidos, int vacunados);
void imprimir_matriz();

void imprimir_automata(int id);
void avanzar_posicion();
int hay_vecino_con_id(int fila, int columna, int id);
void conectar_vecinos(CeldaAutomata *celda1, CeldaAutomata *celda2);
void aislar_celda(int fila, int columna);
void simular_epidemia(int num_pasos);
void desaislar_celda(int fila, int columna);
void imprimir_celda(int fila, int columna);
void aislar_todas_celdas();
%}

%token NUM INICIALIZAR IMPRIMIR_AUTOMATA IMPRIMIR_CELDA OTHER PUNTOCOMA SIMULAR AISLAR DESAISLAR AISLAR_TODO

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
    | AISLAR NUM NUM PUNTOCOMA {
        aislar_celda($2, $3);
    }
    | SIMULAR NUM PUNTOCOMA {
        simular_epidemia($2);
    }
    | DESAISLAR NUM NUM PUNTOCOMA {
        desaislar_celda($2, $3);
    }
    | IMPRIMIR_CELDA NUM NUM PUNTOCOMA {
        imprimir_celda($2, $3);
    }
    | AISLAR_TODO PUNTOCOMA {
        aislar_todas_celdas();
    }
    ;

%%

void avanzar_posicion() {
    posicion_actual_columna++;
    if (posicion_actual_columna >= MAX_COLUMNAS) {
        posicion_actual_columna = 0;
        posicion_actual_fila++;
    }
}

void conectar_vecinos(CeldaAutomata *celda1, CeldaAutomata *celda2) {
    celda1->vecinos = realloc(celda1->vecinos, (celda1->num_vecinos + 1) * sizeof(CeldaAutomata *));
    celda1->vecinos[celda1->num_vecinos++] = celda2;

    celda2->vecinos = realloc(celda2->vecinos, (celda2->num_vecinos + 1) * sizeof(CeldaAutomata *));
    celda2->vecinos[celda2->num_vecinos++] = celda1;
}

CeldaAutomata* inicializar_automata(int id, int susceptibles, int expuestos, int infectados, int recuperados, int fallecidos, int vacunados) {
    if (posicion_actual_fila >= MAX_FILAS) {
        printf("Error: La matriz está llena. No se pueden agregar más autómatas.\n");
        return NULL;
    }

    // Crear el nuevo autómata
    CeldaAutomata *nuevo_automata = malloc(sizeof(CeldaAutomata));
    nuevo_automata->id = id;
    nuevo_automata->fila = posicion_actual_fila;
    nuevo_automata->columna = posicion_actual_columna;
    nuevo_automata->susceptibles = susceptibles - vacunados; // Restar los vacunados de los susceptibles
    nuevo_automata->expuestos = expuestos;
    nuevo_automata->infectados = infectados;
    nuevo_automata->recuperados = recuperados;
    nuevo_automata->fallecidos = fallecidos;
    nuevo_automata->vacunados = vacunados;
    nuevo_automata->vecinos = NULL;
    nuevo_automata->num_vecinos = 0;

    matriz[posicion_actual_fila][posicion_actual_columna] = nuevo_automata;

    int direcciones[4][2] = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
    for (int i = 0; i < 4; i++) {
        int nueva_fila = posicion_actual_fila + direcciones[i][0];
        int nueva_columna = posicion_actual_columna + direcciones[i][1];
        if (nueva_fila >= 0 && nueva_columna >= 0 && nueva_fila < MAX_FILAS && nueva_columna < MAX_COLUMNAS) {
            CeldaAutomata *vecino = matriz[nueva_fila][nueva_columna];
            if (vecino != NULL) {
                conectar_vecinos(nuevo_automata, vecino);
            }
        }
    }

    grupo_por_id[id][tamanio_grupo[id]++] = nuevo_automata;

    avanzar_posicion();

    printf("Autómata con ID %d inicializado en posición (%d, %d) - S: %d, E: %d, I: %d, R: %d, F: %d, V: %d.\n", 
            id, nuevo_automata->fila, nuevo_automata->columna, 
            nuevo_automata->susceptibles, nuevo_automata->expuestos, 
            nuevo_automata->infectados, nuevo_automata->recuperados, 
            nuevo_automata->fallecidos, nuevo_automata->vacunados);
    return nuevo_automata;
}
void imprimir_celda(int fila, int columna) {
    // Verificar que la fila y columna estén dentro de los límites de la matriz
    if (fila < 0 || fila >= MAX_FILAS || columna < 0 || columna >= MAX_COLUMNAS) {
        printf("Error: La posición (%d, %d) está fuera de los límites de la matriz.\n", fila, columna);
        return;
    }

    // Obtener la celda de la matriz
    CeldaAutomata *celda = matriz[fila][columna];

    // Verificar que la celda exista
    if (celda == NULL) {
        printf("La celda en la posición (%d, %d) no existe.\n", fila, columna);
        return;
    }

    // Imprimir el ID, fila y columna en una línea
    printf("ID: %d - Posición: (%d, %d)\n", celda->id, fila, columna);

    // Imprimir el resto de los datos en la siguiente línea
    printf("S: %d, E: %d, I: %d, R: %d, F: %d, V: %d\n",
           celda->susceptibles, celda->expuestos, celda->infectados,
           celda->recuperados, celda->fallecidos, celda->vacunados);

    // Imprimir los IDs de los vecinos en la misma línea de los estados
    printf("Vecinos (IDs): ");
    for (int i = 0; i < celda->num_vecinos; i++) {
        printf("%d ", celda->vecinos[i]->id);
    }
    printf("\n");
}


void imprimir_automata(int id) {
    printf("Información de las celdas con ID %d:\n", id);
    for (int i = 0; i < tamanio_grupo[id]; i++) {
        CeldaAutomata *celda = grupo_por_id[id][i];
        printf("Posición (%d, %d) - S: %d, E: %d, I: %d, R: %d, F: %d, V: %d | ID's de celdas Vecinas: ",
               celda->fila, celda->columna,
               celda->susceptibles, celda->expuestos, celda->infectados, celda->recuperados,
               celda->fallecidos, celda->vacunados);

        for (int j = 0; j < celda->num_vecinos; j++) {
            printf("%d ", celda->vecinos[j]->id);
        }
        printf("\n");
    }
}

void aislar_celda(int fila, int columna) {
    // Verificar que la celda especificada esté dentro de los límites y exista
    if (fila < 0 || fila >= MAX_FILAS || columna < 0 || columna >= MAX_COLUMNAS || matriz[fila][columna] == NULL) {
        printf("Error: La celda en (%d, %d) no es válida o no existe.\n", fila, columna);
        return;
    }

    CeldaAutomata *celda = matriz[fila][columna];

    // Desconectar a todos los vecinos de la celda especificada sin hacer realloc en cada iteración
    for (int k = 0; k < celda->num_vecinos; k++) {
        CeldaAutomata *vecino = celda->vecinos[k];

        // Remover la referencia de 'celda' de la lista de vecinos de 'vecino'
        for (int n = 0; n < vecino->num_vecinos; n++) {
            if (vecino->vecinos[n] == celda) {
                // Desplazar los vecinos hacia adelante para eliminar la referencia
                vecino->vecinos[n] = vecino->vecinos[vecino->num_vecinos - 1];
                vecino->num_vecinos--;
                vecino->vecinos = realloc(vecino->vecinos, vecino->num_vecinos * sizeof(CeldaAutomata *));
                break;
            }
        }
    }

    // Limpiar los vecinos de la celda especificada sin hacer realloc cada vez
    free(celda->vecinos);
    celda->vecinos = NULL;
    celda->num_vecinos = 0;

    printf("Celda aislada en la posición (%d, %d).\n", fila, columna);
}


void desaislar_celda(int fila, int columna) {
    // Verificar que la celda especificada esté dentro de los límites y exista
    if (fila < 0 || fila >= MAX_FILAS || columna < 0 || columna >= MAX_COLUMNAS || matriz[fila][columna] == NULL) {
        printf("Error: La celda en (%d, %d) no es válida o no existe.\n", fila, columna);
        return;
    }

    CeldaAutomata *celda = matriz[fila][columna];

    // Definir las direcciones adyacentes (arriba, abajo, izquierda, derecha)
    int direcciones[4][2] = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};

    for (int i = 0; i < 4; i++) {
        int nueva_fila = fila + direcciones[i][0];
        int nueva_columna = columna + direcciones[i][1];

        // Verificar que el vecino esté dentro de los límites de la matriz
        if (nueva_fila >= 0 && nueva_fila < MAX_FILAS && nueva_columna >= 0 && nueva_columna < MAX_COLUMNAS) {
            CeldaAutomata *vecino = matriz[nueva_fila][nueva_columna];
            if (vecino != NULL) {
                // Reconectar bidireccionalmente, asegurando que ambos tienen referencias mutuas
                int already_connected = 0;
                // Verificar si ya están conectados para evitar duplicados
                for (int j = 0; j < celda->num_vecinos; j++) {
                    if (celda->vecinos[j] == vecino) {
                        already_connected = 1;
                        break;
                    }
                }
                if (!already_connected) {
                    // Conectar la celda con el vecino y el vecino con la celda
                    conectar_vecinos(celda, vecino);
                }
            }
        }
    }

    printf("Celda en la posición (%d, %d) ha sido reconectada con sus vecinos.\n", fila, columna);
}



void mover_individuos_entre_vecinos(CeldaAutomata *celda) {
    if (celda == NULL || celda->num_vecinos == 0) return;  // Verifica que la celda tenga vecinos

    // Porcentaje de individuos que se moverán a vecinos
    float porcentaje_movimiento = 0.1;  // 10% de la población se moverá a vecinos

    // Mover susceptibles
    int individuos_a_mover = celda->susceptibles * porcentaje_movimiento;
    for (int i = 0; i < celda->num_vecinos && individuos_a_mover > 0; i++) {
        CeldaAutomata *vecino = celda->vecinos[i];
        int cantidad_mover = individuos_a_mover / celda->num_vecinos;
        vecino->susceptibles += cantidad_mover;
        celda->susceptibles -= cantidad_mover;
    }

    // Mover expuestos
    individuos_a_mover = celda->expuestos * porcentaje_movimiento;
    for (int i = 0; i < celda->num_vecinos && individuos_a_mover > 0; i++) {
        CeldaAutomata *vecino = celda->vecinos[i];
        int cantidad_mover = individuos_a_mover / celda->num_vecinos;
        vecino->expuestos += cantidad_mover;
        celda->expuestos -= cantidad_mover;
    }

    // Mover infectados
    individuos_a_mover = celda->infectados * porcentaje_movimiento;
    for (int i = 0; i < celda->num_vecinos && individuos_a_mover > 0; i++) {
        CeldaAutomata *vecino = celda->vecinos[i];
        int cantidad_mover = individuos_a_mover / celda->num_vecinos;
        vecino->infectados += cantidad_mover;
        celda->infectados -= cantidad_mover;
    }

    // Mover recuperados
    individuos_a_mover = celda->recuperados * porcentaje_movimiento;
    for (int i = 0; i < celda->num_vecinos && individuos_a_mover > 0; i++) {
        CeldaAutomata *vecino = celda->vecinos[i];
        int cantidad_mover = individuos_a_mover / celda->num_vecinos;
        vecino->recuperados += cantidad_mover;
        celda->recuperados -= cantidad_mover;
    }
}

void simular_epidemia(int num_pasos) {
    if (num_pasos <= 0) {
        printf("Error: El número de pasos debe ser mayor que cero.\n");
        return;
    }
    
    // Abre el archivo CSV para escribir los resultados
    FILE *file = fopen("simulacion.csv", "w");
    if (file == NULL) {
        perror("No se pudo abrir simulacion.csv");
        return;
    }
    
    // Escribe los encabezados del CSV, incluyendo el ID
    fprintf(file, "Dia,ID,Fila,Columna,Susceptibles,Expuestos,Infectados,Recuperados,Fallecidos,Vacunados\n");

    printf("Simulando la epidemia durante %d días...\n", num_pasos);
    for (int paso = 0; paso < num_pasos; paso++) {
        for (int i = 0; i < MAX_FILAS; i++) {
            for (int j = 0; j < MAX_COLUMNAS; j++) {
                CeldaAutomata *celda = matriz[i][j];
                if (celda != NULL) {
                    float random_factor = ((float) rand() / RAND_MAX);

                    int nuevos_vacunados = celda->susceptibles * tasa_vacunacion * random_factor;
                    celda->susceptibles -= nuevos_vacunados;
                    celda->vacunados += nuevos_vacunados;

                    int nuevos_infectados = (celda->susceptibles - celda->vacunados) * tasa_infeccion * random_factor;
                    if (celda->vacunados > 0) {
                        int protegidos = celda->vacunados * 0.8 * random_factor;
                        nuevos_infectados -= protegidos;
                        if (nuevos_infectados < 0) nuevos_infectados = 0;
                    }

                    celda->susceptibles -= nuevos_infectados;
                    celda->infectados += nuevos_infectados;

                    int nuevos_expuestos = celda->infectados * tasa_exposicion * random_factor;
                    celda->expuestos += nuevos_expuestos;
                    celda->infectados -= nuevos_expuestos;

                    int nuevos_recuperados = celda->infectados * tasa_recuperacion * random_factor;
                    celda->recuperados += nuevos_recuperados;
                    celda->infectados -= nuevos_recuperados;

                    int nuevos_fallecidos = celda->infectados * tasa_mortalidad * random_factor;
                    celda->fallecidos += nuevos_fallecidos;
                    celda->infectados -= nuevos_fallecidos;

                    mover_individuos_entre_vecinos(celda);

                    // Escribir el estado de la celda en el archivo CSV, incluyendo el ID
                    fprintf(file, "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n",
                            paso + 1, celda->id, celda->fila, celda->columna,
                            celda->susceptibles, celda->expuestos, celda->infectados,
                            celda->recuperados, celda->fallecidos, celda->vacunados);

                    // Imprimir el estado de la celda en consola
                   
                }
            }
        }
    }
    
    // Cierra el archivo CSV después de la simulación
    fclose(file);
    
    printf("Simulación de la epidemia completada y guardada en simulacion.csv.\n");
}



void imprimir_matriz() {
    printf("Matriz de IDs de autómatas:\n");
    for (int i = 0; i < MAX_FILAS; i++) {
        for (int j = 0; j < MAX_COLUMNAS; j++) {
            if (matriz[i][j] != NULL) {
                printf("%2d ", matriz[i][j]->id);
            } else {
                printf(" . ");
            }
        }
        printf("\n");
    }
    printf("\n");
}


void aislar_todas_celdas() {
    for (int i = 0; i < MAX_FILAS; i++) {
        for (int j = 0; j < MAX_COLUMNAS; j++) {
            if (matriz[i][j] != NULL) {
                aislar_celda(i, j);
            }
        }
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {

    srand(time(NULL));
    FILE *file = fopen("comandos.txt", "r");
    if (file == NULL) {
        perror("No se pudo abrir comandos.txt");
        return 1;
    }
    stdin = file;
    yyparse();
    fclose(file);
    imprimir_matriz();
    return 0;
}
