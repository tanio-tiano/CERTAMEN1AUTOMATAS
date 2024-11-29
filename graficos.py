import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

# Función para cargar los datos desde el archivo CSV
def cargar_datos():
    try:
        df = pd.read_csv("simulacion.csv")
        return df
    except FileNotFoundError:
        print("Error: El archivo 'simulacion.csv' no se encontró.")
        exit()

# Función para actualizar la gráfica de una celda específica
def actualizar_grafico_celda(fila, columna, ax):
    df = cargar_datos()  # Recargar los datos en cada fotograma para actualizaciones dinámicas
    celda_df = df[(df["Fila"] == fila) & (df["Columna"] == columna)]

    if celda_df.empty:
        print(f"No se encontraron datos para la celda en la posición ({fila}, {columna}).")
        return

    celda_df.set_index("Dia", inplace=True)

    ax.clear()
    ax.plot(celda_df.index, celda_df["Susceptibles"], label="Susceptibles")
    ax.plot(celda_df.index, celda_df["Expuestos"], label="Expuestos")
    ax.plot(celda_df.index, celda_df["Infectados"], label="Infectados")
    ax.plot(celda_df.index, celda_df["Recuperados"], label="Recuperados")
    ax.plot(celda_df.index, celda_df["Fallecidos"], label="Fallecidos")
    ax.plot(celda_df.index, celda_df["Vacunados"], label="Vacunados")

    ax.set_xlabel("Día")
    ax.set_ylabel("Número de Individuos")
    ax.set_title(f"Evolución de la Celda ({fila}, {columna})")
    ax.legend()
    ax.grid(True)

# Función para actualizar la gráfica de todos los datos para un ID específico
def actualizar_grafico_id(id_celda, ax):
    df = cargar_datos()  # Recargar los datos en cada fotograma
    id_df = df[df["ID"] == id_celda]

    if id_df.empty:
        print(f"No se encontraron datos para el ID {id_celda}.")
        return

    suma_por_dia = id_df.groupby("Dia")[["Susceptibles", "Expuestos", "Infectados", "Recuperados", "Fallecidos", "Vacunados"]].sum()

    ax.clear()
    ax.plot(suma_por_dia.index, suma_por_dia["Susceptibles"], label="Susceptibles")
    ax.plot(suma_por_dia.index, suma_por_dia["Expuestos"], label="Expuestos")
    ax.plot(suma_por_dia.index, suma_por_dia["Infectados"], label="Infectados")
    ax.plot(suma_por_dia.index, suma_por_dia["Recuperados"], label="Recuperados")
    ax.plot(suma_por_dia.index, suma_por_dia["Fallecidos"], label="Fallecidos")
    ax.plot(suma_por_dia.index, suma_por_dia["Vacunados"], label="Vacunados")

    ax.set_xlabel("Día")
    ax.set_ylabel("Total de Individuos")
    ax.set_title(f"Evolución  del Total de Celdas con ID {id_celda}")
    ax.legend()
    ax.grid(True)

# Función para seleccionar la opción de visualización
def seleccion_visualizacion():
    print("\nSelecciona una opción:")
    print("1. Visualizar evolución  de una celda específica (por fila y columna)")
    print("2. Visualizar evolución  del total de datos para un ID específico")
    opcion = input("Opción: ")

    fig, ax = plt.subplots(figsize=(10, 6))

    if opcion == "1":
        try:
            fila = int(input("Ingresa la fila de la celda que deseas graficar: "))
            columna = int(input("Ingresa la columna de la celda que deseas graficar: "))
        except ValueError:
            print("Error: Entrada no válida. Asegúrate de ingresar números enteros.")
            return

        # Llamada a la función de animación para actualizar el gráfico de la celda
        ani = FuncAnimation(fig, lambda i: actualizar_grafico_celda(fila, columna, ax), interval=1000, cache_frame_data=False)
        plt.show()

    elif opcion == "2":
        try:
            id_celda = int(input("Ingresa el ID de la celda que deseas graficar en su conjunto: "))
        except ValueError:
            print("Error: Entrada no válida. Asegúrate de ingresar un número entero.")
            return

        # Llamada a la función de animación para actualizar el gráfico del ID
        ani = FuncAnimation(fig, lambda i: actualizar_grafico_id(id_celda, ax), interval=1000, cache_frame_data=False)
        plt.show()

    else:
        print("Opción no válida. Por favor, elige entre 1 y 2.")

# Ejecutar la selección de visualización
seleccion_visualizacion()
