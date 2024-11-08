import pandas as pd
import matplotlib.pyplot as plt
import os

# Función para listar los archivos de simulación disponibles
def listar_archivos_simulacion():
    archivos = [f for f in os.listdir() if f.startswith("simulacion_") and f.endswith(".csv")]
    if not archivos:
        print("No se encontraron archivos de simulación en el directorio.")
        return []
    print("Archivos de simulación disponibles:")
    for i, archivo in enumerate(archivos):
        print(f"{i + 1}. {archivo}")
    return archivos

# Función para cargar un archivo de simulación específico
def cargar_archivo_simulacion():
    archivos = listar_archivos_simulacion()
    if not archivos:
        return None
    try:
        seleccion = int(input("Selecciona el número del archivo que deseas cargar: ")) - 1
        if seleccion < 0 or seleccion >= len(archivos):
            print("Selección no válida.")
            return None
        df = pd.read_csv(archivos[seleccion])
        print(f"Archivo {archivos[seleccion]} cargado exitosamente.")
        return df
    except ValueError:
        print("Error: Entrada no válida. Asegúrate de ingresar un número.")
        return None

# Función para graficar la evolución de una celda específica
def graficar_evolucion_celda(df):
    try:
        fila = int(input("Ingresa la fila de la celda que deseas graficar: "))
        columna = int(input("Ingresa la columna de la celda que deseas graficar: "))
    except ValueError:
        print("Error: Entrada no válida. Asegúrate de ingresar números enteros.")
        return
    
    # Filtrar los datos para la celda especificada (fila y columna)
    celda_df = df[(df["Fila"] == fila) & (df["Columna"] == columna)]
    
    # Verificar que haya datos para la celda especificada
    if celda_df.empty:
        print(f"No se encontraron datos para la celda en la posición ({fila}, {columna}).")
        return
    
    # Establecer el día como el índice para facilitar la gráfica
    celda_df.set_index("Dia", inplace=True)
    
    # Crear la gráfica de líneas
    plt.figure(figsize=(10, 6))
    plt.plot(celda_df.index, celda_df["Susceptibles"], label="Susceptibles")
    plt.plot(celda_df.index, celda_df["Expuestos"], label="Expuestos")
    plt.plot(celda_df.index, celda_df["Infectados"], label="Infectados")
    plt.plot(celda_df.index, celda_df["Recuperados"], label="Recuperados")
    plt.plot(celda_df.index, celda_df["Fallecidos"], label="Fallecidos")
    plt.plot(celda_df.index, celda_df["Vacunados"], label="Vacunados")
    
    # Configuración de la gráfica
    plt.xlabel("Día")
    plt.ylabel("Número de Individuos")
    plt.title(f"Evolución de la Celda ({fila}, {columna})")
    plt.legend()
    plt.grid(True)
    plt.show()

# Función para graficar la sumatoria total de los datos para un ID específico
def graficar_suma_por_id(df):
    try:
        id_celda = int(input("Ingresa el ID de la celda que deseas graficar en su conjunto: "))
    except ValueError:
        print("Error: Entrada no válida. Asegúrate de ingresar un número entero.")
        return
    
    # Filtrar los datos para el ID especificado
    id_df = df[df["ID"] == id_celda]
    
    # Verificar que haya datos para el ID especificado
    if id_df.empty:
        print(f"No se encontraron datos para el ID {id_celda}.")
        return
    
    # Agrupar por día y sumar los valores para cada estado
    suma_por_dia = id_df.groupby("Dia")[["Susceptibles", "Expuestos", "Infectados", "Recuperados", "Fallecidos", "Vacunados"]].sum()
    
    # Crear la gráfica de líneas
    plt.figure(figsize=(10, 6))
    plt.plot(suma_por_dia.index, suma_por_dia["Susceptibles"], label="Susceptibles")
    plt.plot(suma_por_dia.index, suma_por_dia["Expuestos"], label="Expuestos")
    plt.plot(suma_por_dia.index, suma_por_dia["Infectados"], label="Infectados")
    plt.plot(suma_por_dia.index, suma_por_dia["Recuperados"], label="Recuperados")
    plt.plot(suma_por_dia.index, suma_por_dia["Fallecidos"], label="Fallecidos")
    plt.plot(suma_por_dia.index, suma_por_dia["Vacunados"], label="Vacunados")
    
    # Configuración de la gráfica
    plt.xlabel("Día")
    plt.ylabel("Total de Individuos")
    plt.title(f"Evolución Total de las Celdas con ID {id_celda}")
    plt.legend()
    plt.grid(True)
    plt.show()

# Función para graficar la evolución total de todas las zonas geográficas
def graficar_evolucion_total(df):
    # Agrupar por día y sumar los valores para cada estado en todas las zonas
    total_por_dia = df.groupby("Dia")[["Susceptibles", "Expuestos", "Infectados", "Recuperados", "Fallecidos", "Vacunados"]].sum()
    
    # Crear la gráfica de líneas
    plt.figure(figsize=(10, 6))
    plt.plot(total_por_dia.index, total_por_dia["Susceptibles"], label="Susceptibles")
    plt.plot(total_por_dia.index, total_por_dia["Expuestos"], label="Expuestos")
    plt.plot(total_por_dia.index, total_por_dia["Infectados"], label="Infectados")
    plt.plot(total_por_dia.index, total_por_dia["Recuperados"], label="Recuperados")
    plt.plot(total_por_dia.index, total_por_dia["Fallecidos"], label="Fallecidos")
    plt.plot(total_por_dia.index, total_por_dia["Vacunados"], label="Vacunados")
    
    # Configuración de la gráfica
    plt.xlabel("Día")
    plt.ylabel("Total de Individuos")
    plt.title("Evolución Total de Todas las Zonas Geográficas")
    plt.legend()
    plt.grid(True)
    plt.show()

# Menú iterativo para seleccionar la opción de graficar
def menu():
    while True:
        # Cargar archivo de simulación al inicio del menú
        df = cargar_archivo_simulacion()
        if df is None:
            print("No se pudo cargar ningún archivo. Saliendo del programa.")
            break
        
        print("\nSelecciona una opción:")
        print("1. Graficar evolución de una celda específica (por fila y columna)")
        print("2. Graficar la sumatoria total de los datos para un ID específico")
        print("3. Graficar la evolución total de todas las zonas geográficas")
        print("4. Seleccionar otro archivo")
        print("5. Salir")
        
        try:
            opcion = int(input("Opción: "))
        except ValueError:
            print("Error: Entrada no válida. Asegúrate de ingresar un número entero.")
            continue
        
        if opcion == 1:
            graficar_evolucion_celda(df)
        elif opcion == 2:
            graficar_suma_por_id(df)
        elif opcion == 3:
            graficar_evolucion_total(df)
        elif opcion == 4:
            # Seleccionar otro archivo, volverá a cargar otro archivo al inicio del bucle
            continue
        elif opcion == 5:
            print("Saliendo del programa.")
            break
        else:
            print("Opción no válida. Por favor, elige entre 1 y 5.")

# Ejecutar el menú
menu()
