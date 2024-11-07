%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
void yyerror(const char *s);

#define MAX_AUTOMATAS 10  // Número máximo de autómatas que se pueden crear

typedef struct EstadoCelda {
    int fila;
    int columna;
    int susceptibles;
    int infectados;
    int recuperados;
    int fallecidos;
    int vacunados;
    struct EstadoCelda **vecinos; // Lista de punteros a celdas vecinas
    int num_vecinos;              // Número de vecinos
} EstadoCelda;

typedef struct Automata {
    int id;                
    EstadoCelda **matriz;
    int filas;
    int columnas;
    struct Automata **vecinos;  // Lista de punteros a autómatas vecinos
    int num_vecinos;
} Automata;

Automata *automatas[MAX_AUTOMATAS];
int num_automatas = 0;
int next_id = 1; 

void inicializar_automata();
void imprimir_automata(int id);
void conectar_celdas_borde(int id1, int fila1, int columna1, int id2, int fila2, int columna2);
Automata* obtener_automata_por_id(int id);
void agregar_vecino(EstadoCelda *celda, EstadoCelda *vecino);
void imprimir_celdas_borde(Automata *automata);
int es_celda_borde(Automata *automata, int fila, int columna);
void agregar_vecino_automata(Automata *automata, Automata *vecino);

%}

%token NUM INICIALIZAR IMPRIMIR_AUTOMATA OTHER PUNTOCOMA CONECTAR SIMULAR AVANZAR CONECTAR_CELDAS_BORDE IMPRIMIR_CELDAS_BORDE

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
    | CONECTAR_CELDAS_BORDE NUM NUM NUM NUM NUM NUM PUNTOCOMA{ 
        conectar_celdas_borde($2, $3,$4, $5,$6, $7);   
    }
    | IMPRIMIR_CELDAS_BORDE NUM PUNTOCOMA {
    Automata *automata = obtener_automata_por_id($2);  // Convierte el ID en un puntero al autómata
    if (automata != NULL) {
        imprimir_celdas_borde(automata);
    } else {
        printf("Error: autómata con ID %d no encontrado.\n", $2);
    }
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

    printf("\nAutómata ID %d: Vecinos de automata %d\n", automata->id, automata->num_vecinos);

    // Encabezado de columnas
    
    printf("        ");
    for (int j = 0; j < automata->columnas; j++) {
        printf("    Col %d              ", j);
    }
    printf("\n");

    // Separador superior de la tabla
    printf("        ");
    for (int j = 0; j < automata->columnas; j++) {
        printf("────────────────────────");
    }
    printf("\n");

    // Imprimir cada fila de la matriz con los valores de cada celda
    for (int i = 0; i < automata->filas; i++) {
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
             printf("────────────────────────");
        }
        printf("\n");
    }
}

void conectar_celdas_borde(int id1, int fila1, int columna1, int id2, int fila2, int columna2) {
    // Obtiene los punteros a los autómatas usando sus IDs
    Automata *automata1 = obtener_automata_por_id(id1);
    Automata *automata2 = obtener_automata_por_id(id2);

    // Verifica si ambos autómatas existen
    if (!automata1 || !automata2) {
        printf("Error: Uno o ambos autómatas no existen.\n");
        return;
    }

    // Verifica que las coordenadas estén dentro de los límites de cada autómata
    if (fila1 < 0 || fila1 >= automata1->filas || columna1 < 0 || columna1 >= automata1->columnas ||
        fila2 < 0 || fila2 >= automata2->filas || columna2 < 0 || columna2 >= automata2->columnas) {
        printf("Error: Coordenadas fuera de los límites del autómata.\n");
        return;
    }

    // Obtiene las celdas específicas en los autómatas
    EstadoCelda *celda1 = &automata1->matriz[fila1][columna1];
    EstadoCelda *celda2 = &automata2->matriz[fila2][columna2];

    // Conecta las celdas añadiéndose mutuamente como vecinas
    agregar_vecino(celda1, celda2);
    agregar_vecino(celda2, celda1);

    // Agrega los autómatas como vecinos entre sí (solo si aún no son vecinos)
    agregar_vecino_automata(automata1, automata2);
    agregar_vecino_automata(automata2, automata1);

    printf("Celda (%d, %d) de Autómata %d conectada con Celda (%d, %d) de Autómata %d.\n",
           fila1, columna1, id1, fila2, columna2, id2);
}



void agregar_vecino(EstadoCelda *celda, EstadoCelda *vecino) {
    // Aumenta el espacio de vecinos si es necesario
    celda->vecinos = realloc(celda->vecinos, (celda->num_vecinos + 1) * sizeof(EstadoCelda *));
    if (celda->vecinos == NULL) {
        printf("Error: No se pudo asignar memoria para los vecinos.\n");
        return;
    }

    // Añade el nuevo vecino
    celda->vecinos[celda->num_vecinos] = vecino;
    celda->num_vecinos++;
}

void agregar_vecino_automata(Automata *automata, Automata *vecino) {
    // Verifica si el vecino ya está en la lista
    for (int i = 0; i < automata->num_vecinos; i++) {
        if (automata->vecinos[i] == vecino) {
            // El vecino ya está registrado, no se añade ni se incrementa el contador
            return;
        }
    }

    // Aumenta el espacio de vecinos y añade el nuevo vecino
    automata->vecinos = realloc(automata->vecinos, (automata->num_vecinos + 1) * sizeof(Automata *));
    if (automata->vecinos == NULL) {
        printf("Error: No se pudo asignar memoria para los vecinos del autómata.\n");
        return;
    }

    automata->vecinos[automata->num_vecinos] = vecino;
    automata->num_vecinos++;
}



Automata* obtener_automata_por_id(int id) {
    for (int i = 0; i < num_automatas; i++) {
        if (automatas[i]->id == id) {
            return automatas[i];
        }
    }
    return NULL; // Devuelve NULL si no se encuentra el autómata
}



int es_celda_borde(Automata *automata, int fila, int columna) {
    // Verifica si la celda está en el borde de la matriz
    return (fila == 0 || fila == automata->filas - 1 || 
            columna == 0 || columna == automata->columnas - 1);
}

void imprimir_celdas_borde(Automata *automata) {
    printf("Celdas de borde en el autómata ID %d:\n", automata->id);
    for (int i = 0; i < automata->filas; i++) {
        for (int j = 0; j < automata->columnas; j++) {
            if (es_celda_borde(automata, i, j)) {
                printf("Celda de borde en (%d, %d)\n", i, j);
            }
        }
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

