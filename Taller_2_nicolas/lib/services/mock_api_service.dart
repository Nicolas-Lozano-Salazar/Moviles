import 'dart:async';
import '../models/user_data.dart';

class MockApiService {
  /// Simula una petición asíncrona a un backend usando Future.delayed
  /// Imprime el orden de ejecución exacto en la consola:
  /// 1. ANTES de la llamada
  /// 2. DURANTE la espera asíncrona
  /// 3. DESPUÉS de completarse (Éxito o Error)
  static Future<UserData> fetchUserData({
    bool shouldFail = false,
    int delaySeconds = 3,
    void Function(String)? onLog,
  }) async {
    void log(String message) {
      // ignore: avoid_print
      print(message);
      if (onLog != null) {
        onLog(message);
      }
    }

    log('[1. ANTES] Iniciando petición asíncrona MockApiService.fetchUserData()...');
    log('[1. ANTES] Hilo principal libre, la UI sigue respondiendo mientras se programa el Future.');

    try {
      log('[2. DURANTE] Esperando respuesta del servidor simulado con await Future.delayed (${delaySeconds}s)...');
      
      // Simulación de latencia de red de 2 a 3 segundos
      await Future.delayed(Duration(seconds: delaySeconds));

      if (shouldFail) {
        log('[2. DURANTE] Se ha detectado un fallo simulado en la respuesta del servidor (HTTP 500 / Timeout).');
        throw Exception('Error 500: No se pudo establecer conexión con el servidor.');
      }

      final data = UserData.sample();
      log('[3. DESPUÉS] Datos recibidos con éxito: ${data.nombre} (${data.rol}).');
      return data;
    } catch (e) {
      log('[3. DESPUÉS] Ocurrió un error en el Future: $e');
      rethrow;
    }
  }
}
