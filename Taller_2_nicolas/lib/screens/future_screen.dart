import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../services/mock_api_service.dart';
import '../widgets/console_log_view.dart';

enum FutureUiState { initial, loading, success, error }

class FutureScreen extends StatefulWidget {
  const FutureScreen({super.key});

  @override
  State<FutureScreen> createState() => _FutureScreenState();
}

class _FutureScreenState extends State<FutureScreen> {
  FutureUiState _state = FutureUiState.initial;
  UserData? _userData;
  String? _errorMessage;
  bool _simulateError = false;
  int _delaySeconds = 3;
  final List<String> _executionLogs = [];

  void _addLog(String log) {
    if (mounted) {
      setState(() {
        final time = TimeOfDay.now().format(context);
        _executionLogs.add('[$time] $log');
      });
    }
  }

  /// Método que ejecuta la petición asíncrona usando async/await
  Future<void> _fetchDataAsync() async {
    // 1. Estado CARGANDO antes de iniciar
    setState(() {
      _state = FutureUiState.loading;
      _errorMessage = null;
      _userData = null;
    });

    _addLog('>>> [UI] Botón presionado. Estado cambiado a CARGANDO...');

    try {
      // 2. Espera asíncrona sin bloquear el hilo de la UI
      final result = await MockApiService.fetchUserData(
        shouldFail: _simulateError,
        delaySeconds: _delaySeconds,
        onLog: (msg) => _addLog(msg),
      );

      // 3. Estado ÉXITO tras completarse
      if (mounted) {
        setState(() {
          _userData = result;
          _state = FutureUiState.success;
        });
        _addLog('>>> [UI] Future completado exitosamente. Renderizando datos.');
      }
    } catch (e) {
      // 3. Estado ERROR si ocurre una excepción
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _state = FutureUiState.error;
        });
        _addLog('>>> [UI] Captura en bloque catch: $_errorMessage');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header explicativo
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.network_ping, size: 40, color: theme.colorScheme.primary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1. Asincronía con Future / async / await',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Consulta de servicio simulado con Future.delayed (${_delaySeconds}s). La UI no se bloquea mientras espera el resultado.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Controles de configuración
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuración de la Petición',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Simular fallo de red (Error):'),
                        Switch(
                          value: _simulateError,
                          activeThumbColor: Colors.redAccent,
                          onChanged: _state == FutureUiState.loading
                              ? null
                              : (val) {
                                  setState(() {
                                    _simulateError = val;
                                  });
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text('Tiempo de espera: $_delaySeconds segundos')),
                        const SizedBox(width: 8),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 2, label: Text('2s')),
                            ButtonSegment(value: 3, label: Text('3s')),
                            ButtonSegment(value: 4, label: Text('4s')),
                          ],
                          selected: {_delaySeconds},
                          onSelectionChanged: _state == FutureUiState.loading
                              ? null
                              : (newSet) {
                                  setState(() {
                                    _delaySeconds = newSet.first;
                                  });
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _state == FutureUiState.loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_download),
                        label: Text(
                          _state == FutureUiState.loading
                              ? 'Consultando con await...'
                              : 'Realizar Consulta Asíncrona (Future)',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _simulateError ? Colors.orange.shade800 : theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _state == FutureUiState.loading ? null : _fetchDataAsync,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Visualizador del Estado Actual
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estado en Pantalla',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        _buildStatusBadge(),
                      ],
                    ),
                    const Divider(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildStateContent(theme),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Visor de consola en tiempo real
            ConsoleLogView(
              title: 'Consola de Depuración (Orden: Antes / Durante / Después)',
              logs: _executionLogs,
              onClear: () {
                setState(() {
                  _executionLogs.clear();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bg;
    Color fg;
    String label;

    switch (_state) {
      case FutureUiState.initial:
        bg = Colors.grey.shade300;
        fg = Colors.black87;
        label = 'INICIAL';
        break;
      case FutureUiState.loading:
        bg = Colors.amber.shade200;
        fg = Colors.amber.shade900;
        label = 'CARGANDO...';
        break;
      case FutureUiState.success:
        bg = Colors.green.shade200;
        fg = Colors.green.shade900;
        label = 'ÉXITO';
        break;
      case FutureUiState.error:
        bg = Colors.red.shade200;
        fg = Colors.red.shade900;
        label = 'ERROR';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildStateContent(ThemeData theme) {
    switch (_state) {
      case FutureUiState.initial:
        return const Padding(
          key: ValueKey('initial'),
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.touch_app, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Presione el botón para iniciar la petición asíncrona',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );

      case FutureUiState.loading:
        return Padding(
          key: const ValueKey('loading'),
          padding: const EdgeInsets.symmetric(vertical: 28.0),
          child: Center(
            child: Column(
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(strokeWidth: 4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando datos desde el servidor...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hilo UI libre: la animación es totalmente fluida (60 FPS)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );

      case FutureUiState.success:
        return Container(
          key: const ValueKey('success'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.green.shade600,
                child: Text(
                  _userData?.avatar ?? 'NL',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Respuesta Exitosa (Future)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userData?.nombre ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _userData?.correo ?? '',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rol: ${_userData?.rol ?? ''}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case FutureUiState.error:
        return Container(
          key: const ValueKey('error'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.error_outline, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error en la petición asíncrona',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _errorMessage ?? 'Ocurrió un error inesperado al procesar el Future.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}
