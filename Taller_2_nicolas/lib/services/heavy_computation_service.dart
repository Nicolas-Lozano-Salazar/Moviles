import 'dart:async';
import 'dart:isolate';

/// Modelo para los mensajes enviados entre Isolates
class IsolateTaskRequest {
  final int limit;
  final SendPort sendPort;

  IsolateTaskRequest({
    required this.limit,
    required this.sendPort,
  });
}

class IsolateTaskResponse {
  final int primesCount;
  final int limit;
  final int elapsedMs;
  final int sumLastPrimes;
  final String status;

  IsolateTaskResponse({
    required this.primesCount,
    required this.limit,
    required this.elapsedMs,
    required this.sumLastPrimes,
    required this.status,
  });
}

class HeavyComputationService {
  /// Función pura CPU-bound que corre en el Isolate secundario.
  /// No comparte memoria con el Isolate principal.
  static void _isolateWorkerEntryPoint(IsolateTaskRequest request) {
    // ignore: avoid_print
    print('[ISOLATE WORKER] === Isolate Secundario Iniciado ===');
    // ignore: avoid_print
    print('[ISOLATE WORKER] Procesando cálculo intensivo de números primos hasta ${request.limit}...');

    final stopwatch = Stopwatch()..start();
    int count = 0;
    int sum = 0;
    final int limit = request.limit;

    for (int i = 2; i <= limit; i++) {
      if (_isPrime(i)) {
        count++;
        if (count <= 1000) {
          sum = (sum + i) % 1000000007;
        }
      }
    }

    stopwatch.stop();

    // ignore: avoid_print
    print('[ISOLATE WORKER] Cálculo completado en ${stopwatch.elapsedMilliseconds} ms. Primos encontrados: $count.');
    // ignore: avoid_print
    print('[ISOLATE WORKER] Enviando respuesta a través del SendPort...');

    final response = IsolateTaskResponse(
      primesCount: count,
      limit: limit,
      elapsedMs: stopwatch.elapsedMilliseconds,
      sumLastPrimes: sum,
      status: 'ÉXITO (Completado en Isolate independiente)',
    );

    // Enviar el resultado al Isolate principal
    request.sendPort.send(response);
  }

  /// Verifica si un número es primo (función CPU-intensiva)
  static bool _isPrime(int n) {
    if (n <= 1) return false;
    if (n <= 3) return true;
    if (n % 2 == 0 || n % 3 == 0) return false;
    for (int i = 5; i * i <= n; i += 6) {
      if (n % i == 0 || n % (i + 2) == 0) return false;
    }
    return true;
  }

  /// Ejecuta la tarea pesada en un Isolate secundario usando `Isolate.spawn`
  static Future<IsolateTaskResponse> runInIsolate({
    required int limit,
    void Function(String)? onLog,
  }) async {
    void log(String message) {
      // ignore: avoid_print
      print(message);
      if (onLog != null) {
        onLog(message);
      }
    }

    log('[ISOLATE MAIN] 1. Creando ReceivePort para escuchar mensajes...');
    final receivePort = ReceivePort();
    final completer = Completer<IsolateTaskResponse>();

    log('[ISOLATE MAIN] 2. Ejecutando Isolate.spawn() para crear un nuevo hilo de ejecución...');
    final isolate = await Isolate.spawn<IsolateTaskRequest>(
      _isolateWorkerEntryPoint,
      IsolateTaskRequest(limit: limit, sendPort: receivePort.sendPort),
    );

    receivePort.listen((message) {
      if (message is IsolateTaskResponse) {
        log('[ISOLATE MAIN] 3. Mensaje recibido desde el Isolate secundario!');
        log('[ISOLATE MAIN] -> Total de primos: ${message.primesCount}');
        log('[ISOLATE MAIN] -> Tiempo transcurrido: ${message.elapsedMs} ms');
        log('[ISOLATE MAIN] 4. Cerrando ReceivePort y destruyendo Isolate secundario.');
        
        receivePort.close();
        isolate.kill(priority: Isolate.immediate);
        completer.complete(message);
      }
    });

    return completer.future;
  }

  /// Ejecuta la misma tarea en el Hilo Principal (UI Thread) para comparar el congelamiento de pantalla
  static IsolateTaskResponse runOnMainThreadSync({
    required int limit,
    void Function(String)? onLog,
  }) {
    void log(String message) {
      // ignore: avoid_print
      print(message);
      if (onLog != null) {
        onLog(message);
      }
    }

    log('[MAIN THREAD] ADVERTENCIA: Ejecutando en el hilo principal (La UI se congelará hasta terminar)...');
    final stopwatch = Stopwatch()..start();
    int count = 0;
    int sum = 0;

    for (int i = 2; i <= limit; i++) {
      if (_isPrime(i)) {
        count++;
        if (count <= 1000) {
          sum = (sum + i) % 1000000007;
        }
      }
    }

    stopwatch.stop();
    log('[MAIN THREAD] Terminado en ${stopwatch.elapsedMilliseconds} ms.');

    return IsolateTaskResponse(
      primesCount: count,
      limit: limit,
      elapsedMs: stopwatch.elapsedMilliseconds,
      sumLastPrimes: sum,
      status: 'ÉXITO (Ejecutado en Main Thread - causó freeze)',
    );
  }
}
