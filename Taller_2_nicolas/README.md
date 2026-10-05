# Taller 2: Asincronía, Temporizadores y Concurrencia en Flutter

**Estudiante:** Nicolás Lozano Salazar  
**Asignatura:** Desarrollo Móvil / Flutter  
**Proyecto:** Taller Segundo Plano (Asincronía con Future, Timer y Concurrencia con Isolate)

---

## 📋 Tabla de Contenido
1. [Descripción del Proyecto](#-descripción-del-proyecto)
2. [Conceptos Clave: ¿Cuándo usar cada herramienta?](#-conceptos-clave-cuándo-usar-cada-herramienta)
3. [Arquitectura y Estructura del Código](#-arquitectura-y-estructura-del-código)
4. [Flujos de Trabajo y Diagramas](#-flujos-de-trabajo-y-diagramas)
   - [Flujo 1: Asincronía con Future / async / await](#flujo-1-asincronía-con-future--async--await)
   - [Flujo 2: Ciclo de Vida del Timer (Cronómetro)](#flujo-2-ciclo-de-vida-del-timer-cronómetro)
   - [Flujo 3: Concurrencia y Paso de Mensajes con Isolate](#flujo-3-concurrencia-y-paso-de-mensajes-con-isolate)
5. [Pantallas y Funcionalidades de la App](#-pantallas-y-funcionalidades-de-la-app)
6. [Guía para el Flujo GitFlow](#-guía-para-el-flujo-gitflow)
7. [Instrucciones de Ejecución](#-instrucciones-de-ejecución)
8. [Estructura Recomendada para el PDF de Evidencias](#-estructura-recomendada-para-el-pdf-de-evidencias)

---

## 🎯 Descripción del Proyecto
Esta aplicación desarrollada en Flutter demuestra los tres pilares fundamentales del manejo de operaciones en segundo plano y asincronía en Dart:
1. **Asincronía I/O-Bound (Future / async / await):** Simulación de llamadas a red/servidores sin congelar el Event Loop ni la interfaz gráfica.
2. **Eventos Periódicos y Control Temporal (Timer):** Creación de un cronómetro de alta precisión con inicio, pausa, reanudación, reinicio, registro de vueltas y liberación obligatoria de recursos en `dispose()`.
3. **Cálculo Intensivo CPU-Bound (Isolates):** Ejecución de tareas pesadas en un hilo de sistema operativo independiente con memoria aislada mediante `Isolate.spawn`, comunicándose por paso de mensajes (`SendPort` / `ReceivePort`), garantizando 60 FPS continuos en la UI.

---

## 🧠 Conceptos Clave: ¿Cuándo usar cada herramienta?

| Mecanismo | ¿Cuándo usarlo? | Tipo de Tarea | Impacto en el Main Thread / UI |
| :--- | :--- | :--- | :--- |
| **`Future` / `async` / `await`** | Peticiones HTTP, consultas a bases de datos (SQLite, Hive), lectura/escritura de archivos locales o esperas de eventos I/O. | **I/O-Bound** (espera de operaciones externas). | **No bloquea la UI**; cede el control del *Event Loop* mientras espera. |
| **`Timer` / `Timer.periodic`** | Cronómetros, cuentas regresivas, polling periódico, auto-guardado o ejecuciones retrasadas en el tiempo. | **Control Temporal** basado en eventos del *Event Loop*. | **No bloquea la UI** si el callback es ligero. Requiere llamar a `.cancel()` en `dispose()` para evitar fugas de memoria. |
| **`Isolate` (`Isolate.spawn`)** | Procesamiento de imágenes/video, compresión/encriptación de datos grandes, algoritmos matemáticos complejos, machine learning o parseo de JSONs gigantescos (+10MB). | **CPU-Bound** (cálculo pesado que satura el procesador). | **Aislamiento total:** se ejecuta en un hilo separado de la CPU. Si se hiciera en el hilo principal, la UI se congelaría (0 FPS). |

---

## 📂 Arquitectura y Estructura del Código

```text
lib/
├── main.dart                          # Punto de entrada de la aplicación
├── theme/
│   └── app_theme.dart                 # Tema visual Material 3 (Dark / Light)
├── models/
│   └── user_data.dart                 # Modelo de datos para la simulación API
├── services/
│   ├── mock_api_service.dart          # Servicio asíncrono con Future.delayed y logs
│   └── heavy_computation_service.dart # Servicio de cómputo intensivo con Isolate.spawn
├── screens/
│   ├── home_screen.dart               # Scaffold con NavigationBar y selector de tabs
│   ├── future_screen.dart             # Vista 1: Demostración Future / async / await
│   ├── timer_screen.dart              # Vista 2: Cronómetro con Timer y limpieza de recursos
│   └── isolate_screen.dart            # Vista 3: Computación en Isolate vs Main Thread
└── widgets/
    └── console_log_view.dart          # Consola interactiva en tiempo real integrada en la UI
```

---

## 🔄 Flujos de Trabajo y Diagramas

### Flujo 1: Asincronía con Future / async / await
```
[ Usuario presiona botón ]
         │
         ▼
[ Estado: CARGANDO (CircularProgressIndicator activo) ]
[ Consola: "1. ANTES: Iniciando petición..." ]
         │
         ▼
[ await Future.delayed(3s) - Event Loop libre ]
[ Consola: "2. DURANTE: Esperando respuesta del servidor..." ]
         │
         ├───────────────────────────────────┐
         │ (Respuesta Exitosa)              │ (Fallo Simulado)
         ▼                                   ▼
[ Estado: ÉXITO ]                   [ Estado: ERROR ]
[ Tarjeta con datos de usuario ]    [ Tarjeta roja de error ]
[ Consola: "3. DESPUÉS: Éxito" ]    [ Consola: "3. DESPUÉS: Error capturado" ]
```

---

### Flujo 2: Ciclo de Vida del Timer (Cronómetro)
```
     ┌──────────────┐
     │   DETENIDO   │ ◄────────────────────────┐
     └──────┬───────┘                          │
            │ Iniciar                          │
            ▼                                  │
     ┌──────────────┐                          │
     │ EN EJECUCIÓN │ ────► Vuelta (Lap)       │
     └──────┬───────┘                          │ Reiniciar
            │ Pausar                           │ (Timer.cancel)
            ▼                                  │
     ┌──────────────┐                          │
     │   EN PAUSA   │ ─────────────────────────┘
     └──────┬───────┘
            │ Reanudar
            ▼
     [ Continúa en EJECUCIÓN ]

* Al destruir el Widget (dispose), se ejecuta `_timer?.cancel()` obligatoriamente.
```

---

### Flujo 3: Concurrencia y Paso de Mensajes con Isolate
```
  [ ISOLATE PRINCIPAL (UI Thread) ]              [ ISOLATE SECUNDARIO (Worker) ]
                  │                                             │
   1. Crea ReceivePort()                                       │
   2. Ejecuta Isolate.spawn(entryPoint, request) ------------->│
                  │                                    3. Inicia ejecución aislada
   4. UI sigue fluida a 60 FPS (Animación)                      │
      y responde a toques del usuario                           │ Calcula millones de primos
                  │                                             │ (Stopwatch activo)
                  │                                             │
                  │◄── 5. request.sendPort.send(response) ──────┘
   6. ReceivePort recibe IsolateTaskResponse
   7. Actualiza UI con resultado y tiempo transcurrido
   8. Cierra ReceivePort y llama isolate.kill()
```

---

## 📱 Pantallas y Funcionalidades de la App

### 1. Pestaña Future / Async
- Botón interactivo para disparar la consulta asíncrona.
- Selector de latencia simulada (2s, 3s, 4s).
- Switch para alternar entre **Simulación de Éxito** y **Simulación de Error HTTP 500**.
- Indicadores visuales de estado: `Inicial`, `Cargando...`, `Éxito` y `Error`.
- Consola integrada que imprime en tiempo real los logs en el orden: **Antes**, **Durante** y **Después**.

### 2. Pestaña Timer (Cronómetro)
- Marcador digital con formato `HH:MM:SS.d` actualizado cada 100 milisegundos.
- Botones de acción dinámicos según el estado:
  - **Iniciar:** Arranca el `Timer.periodic`.
  - **Pausar:** Detiene el `Timer` guardando el acumulado.
  - **Reanudar:** Continúa el conteo desde el tiempo pausado.
  - **Vuelta:** Registra marcas de tiempo parciales.
  - **Reiniciar:** Restablece a 0 y cancela el timer.
- Gestión segura del ciclo de vida en `dispose()`.

### 3. Pestaña Isolate (Concurrencia)
- Selector de volumen de datos (1.000.000, 3.000.000 o 6.000.000 de números para evaluar primalidad).
- **Test de respuesta de UI:** Spinner animado a 60 FPS continuo y contador táctil manual.
- **Botón "Ejecutar en Isolate (Segundo Plano)":** Ejecuta la computación en `Isolate.spawn`. La animación y los toques nunca se congelan.
- **Botón "Ejecutar en Main Thread":** Ejecución sincrónica comparativa para demostrar visualmente el bloqueo y congelamiento que ocurre cuando no se usa un Isolate.
- Tarjeta de métricas con: Primos encontrados, tiempo exacto en milisegundos y estado.

---

## 🌿 Guía para el Flujo GitFlow

Cuando vayas a subir el proyecto a tu repositorio remoto de GitHub, ejecuta los siguientes comandos en tu terminal:

```bash
# 1. Inicializar git y crear rama principal
git init
git checkout -b main
git add .
git commit -m "feat: commit inicial del taller de segundo plano"

# 2. Crear rama dev
git checkout -b dev

# 3. Crear y trabajar en la rama feature
git checkout -b feature/taller_segundo_plano

# 4. (Opcional) Hacer commits adicionales de tus pruebas
git add .
git commit -m "feat: implementacion completa de Future, Timer e Isolate"

# 5. Configurar tu repositorio remoto en GitHub
git remote add origin https://github.com/TU_USUARIO/TU_REPOSITORIO.git

# 6. Subir las ramas
git push -u origin feature/taller_segundo_plano
git push -u origin dev
git push -u origin main
```

**Flujo en GitHub:**
1. Crear Pull Request desde `feature/taller_segundo_plano` hacia `dev`.
2. Hacer Merge del Pull Request a `dev`.
3. Integrar los cambios de `dev` a `main`.

---

## 🚀 Instrucciones de Ejecución

Para correr la aplicación localmente:

```bash
# Obtener dependencias
flutter pub get

# Ejecutar análisis estático y pruebas
flutter analyze
flutter test

# Correr en emulador o dispositivo físico
flutter run
```

---

## 📄 Estructura Recomendada para el PDF de Evidencias

Para la entrega en Moodle, crea un documento PDF con la siguiente estructura:

### **Página 1: Portada y Enlaces**
- **Nombre del Estudiante:** Nicolás Lozano Salazar
- **Asignatura:** Desarrollo Móvil / Flutter - Taller 2
- **URL del Repositorio de GitHub:** `https://github.com/TU_USUARIO/TU_REPOSITORIO`
- **Ramas activas:** `main`, `dev`, `feature/taller_segundo_plano`.

### **Página 2: Evidencias de Asincronía (Future / async / await)**
- **Captura 1:** Estado inicial y configuración (toggle de error / tiempo de espera).
- **Captura 2:** Estado `Cargando...` con `CircularProgressIndicator` en acción.
- **Captura 3:** Estado `Éxito` con la tarjeta de datos de Nicolás Lozano Salazar.
- **Captura 4:** Estado `Error` al activar el switch de fallo de red.
- **Captura 5 / Texto:** Consola de depuración con el orden `1. ANTES`, `2. DURANTE`, `3. DESPUÉS`.

### **Página 3: Evidencias del Cronómetro (Timer)**
- **Captura 1:** Cronómetro en estado `Iniciar` y conteo activo a 100 ms.
- **Captura 2:** Cronómetro en estado `Pausar` con tiempo retenido.
- **Captura 3:** Cronómetro en estado `Reanudar` y lista de vueltas (Laps) registradas.
- **Captura 4:** Acción de `Reiniciar` volviendo a `00:00:00.0`.
- **Descripción:** Explicación del método `dispose()` implementado para cancelar el timer y prevenir memory leaks.

### **Página 4: Evidencias de Concurrencia con Isolate**
- **Captura 1:** Animación girando a 60 FPS y contador táctil mientras el Isolate procesa 3.000.000 de números en segundo plano.
- **Captura 2:** Tarjeta de resultados finales (Total de primos encontrados y tiempo en ms).
- **Captura 3:** Consola con el intercambio de mensajes entre `ReceivePort` y `SendPort` (`Isolate.spawn`).
- **Descripción:** Contraste técnico de por qué la UI no se bloqueó en el Isolate frente a la ejecución sincrónica en el hilo principal.
