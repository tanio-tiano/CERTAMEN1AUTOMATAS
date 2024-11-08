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

// Definir tasas de cambio globales ajustadas para simular COVID-19
float tasa_infeccion = 0.2;
float tasa_exposicion = 0.15;
float tasa_recuperacion = 0.1;
float tasa_mortalidad = 0.02;
float tasa_vacunacion = 0.05;

CeldaAutomata* inicializar_automata(int id, int susceptibles, int expuestos, int infectados, int recuperados, int fallecidos, int vacunados);
void imprimir_automata(int id);
void avanzar_posicion();
int hay_vecino_con_id(int fila, int columna, int id);
void conectar_vecinos(CeldaAutomata *celda1, CeldaAutomata *celda2);
void imprimir_matriz();
void aislar_vecindad(int id);
void simular_epidemia(int num_pasos);
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
    | SIMULAR NUM PUNTOCOMA {
        printf("Número de días leído: %d\n", $2);
        simular_epidemia($2);
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

void aislar_vecindad(int id) {
    for (int i = 0; i < MAX_FILAS; i++) {
        for (int j = 0; j < MAX_COLUMNAS; j++) {
            CeldaAutomata *celda = matriz[i][j];
            if (celda != NULL && celda->id == id) {
                for (int k = 0; k < celda->num_vecinos; k++) {
                    CeldaAutomata *vecino = celda->vecinos[k];
                    if (vecino->id != id) {
                        for (int m = k; m < celda->num_vecinos - 1; m++) {
                            celda->vecinos[m] = celda->vecinos[m + 1];
                        }
                        celda->num_vecinos--;
                        celda->vecinos = realloc(celda->vecinos, celda->num_vecinos * sizeof(CeldaAutomata *));
                        k--;
                    }
                }
            }
        }
    }
    printf("Vecindad aislada para celdas con ID %d.\n", id);
}

void mover_individuos_entre_vecinos(CeldaAutomata *celda) {
    if (celda == NULL || celda->num_vecinos == 0) return;  // Verifica que la celda tenga vecinos

    // Porcentaje de individuos que se moverán (ajustable)
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

    // Nota: Puedes ajustar o agregar más compartimentos según sea necesario.
}


void simular_epidemia(int num_pasos) {
    if (num_pasos <= 0) {
        printf("Error: El número de pasos debe ser mayor que cero.\n");
        return;
    }
    printf("Simulando la epidemia durante %d pasos...\n", num_pasos);
    for (int paso = 0; paso < num_pasos; paso++) {
        printf("\n--- Día %d ---\n", paso + 1);
        for (int i = 0; i < MAX_FILAS; i++) {
            for (int j = 0; j < MAX_COLUMNAS; j++) {
                CeldaAutomata *celda = matriz[i][j];
                if (celda != NULL) {
                    // Generar factor aleatorio para variabilidad
                    float random_factor = ((float) rand() / RAND_MAX);

                    // Proceso de vacunación con aleatoriedad
                    int nuevos_vacunados = celda->susceptibles * tasa_vacunacion * random_factor;
                    celda->susceptibles -= nuevos_vacunados;
                    celda->vacunados += nuevos_vacunados;

                    // Proceso de infección con aleatoriedad
                    int nuevos_infectados = (celda->susceptibles - celda->vacunados) * tasa_infeccion * random_factor;
                    if (celda->vacunados > 0) {
                        int protegidos = celda->vacunados * 0.8 * random_factor; // Protección aleatoria
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

                    // Llamada a la función de movimiento entre vecinos
                    mover_individuos_entre_vecinos(celda);

                    // Agregar impresión para mostrar el estado actual de la celda
                    printf("Posición (%d, %d) - S: %d, E: %d, I: %d, R: %d, F: %d, V: %d\n",
                           celda->fila, celda->columna, celda->susceptibles, celda->expuestos,
                           celda->infectados, celda->recuperados, celda->fallecidos, celda->vacunados);
                }
            }
        }
    }
    printf("Simulación de la epidemia completada.\n");
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

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    // Inicializar semilla aleatoria
    srand(time(NULL));

    FILE *file = fopen("comandos.txt", "r");
    if (file == NULL) {
        perror("No se pudo abrir comandos.txt");
        return 1;
    }
    printf("Ingrese 'INICIALIZAR S I R F V;' donde S,I,R,V,F la inicial de cada estado\n");
    stdin = file;
    yyparse();
    fclose(file);
    imprimir_matriz();
    return 0;
}
