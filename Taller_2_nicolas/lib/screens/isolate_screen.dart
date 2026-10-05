import 'package:flutter/material.dart';
import '../services/heavy_computation_service.dart';
import '../widgets/console_log_view.dart';

enum IsolateStatus { idle, runningIsolate, runningMainThread, finished }

class IsolateScreen extends StatefulWidget {
  const IsolateScreen({super.key});

  @override
  State<IsolateScreen> createState() => _IsolateScreenState();
}

class _IsolateScreenState extends State<IsolateScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _interactiveCounter = 0;
  int _workloadLimit = 3000000;
  IsolateStatus _status = IsolateStatus.idle;
  IsolateTaskResponse? _lastResult;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _addLog(String log) {
    if (mounted) {
      setState(() {
        final time = TimeOfDay.now().format(context);
        _logs.add('[$time] $log');
      });
    }
  }

  /// Ejecución en Isolate usando Isolate.spawn (No congela la UI)
  Future<void> _runTaskInIsolate() async {
    setState(() {
      _status = IsolateStatus.runningIsolate;
      _lastResult = null;
    });

    _addLog('==================================================');
    _addLog('>>> Iniciando tarea pesada en ISOLATE SECUNDARIO...');
    _addLog('>>> Observe cómo la animación y el contador siguen fluidos al 100%.');

    try {
      final result = await HeavyComputationService.runInIsolate(
        limit: _workloadLimit,
        onLog: (msg) => _addLog(msg),
      );

      if (mounted) {
        setState(() {
          _lastResult = result;
          _status = IsolateStatus.finished;
        });
        _addLog('>>> [FIN] Resultado recibido con éxito en la UI.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = IsolateStatus.idle;
        });
        _addLog('>>> [ERROR EN ISOLATE]: $e');
      }
    }
  }

  /// Ejecución síncrona en el Hilo Principal (Demuestra el congelamiento de la UI)
  void _runTaskOnMainThread() {
    setState(() {
      _status = IsolateStatus.runningMainThread;
      _lastResult = null;
    });

    _addLog('==================================================');
    _addLog('>>> ALERTA: Ejecutando en MAIN THREAD...');
    _addLog('>>> La animación y los toques en pantalla se CONGELARÁN completamente.');

    // Forzamos un microdelay para que la UI pinte el inicio antes de congelarse
    Future.delayed(const Duration(milliseconds: 100), () {
      final result = HeavyComputationService.runOnMainThreadSync(
        limit: _workloadLimit,
        onLog: (msg) => _addLog(msg),
      );

      if (mounted) {
        setState(() {
          _lastResult = result;
          _status = IsolateStatus.finished;
        });
        _addLog('>>> [FIN] Hilo principal desbloqueado.');
      }
    });
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
              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.memory, size: 40, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '3. Concurrencia con Isolate (Isolate.spawn)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Cálculo CPU-bound intensivo en un hilo de ejecución independiente con memoria aislada y paso de mensajes (SendPort/ReceivePort).',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Prueba de fluidez de UI en tiempo real
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Text(
                          'Test de Capacidad de Respuesta de la UI',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Animación continua a 60 FPS
                        Column(
                          children: [
                            RotationTransition(
                              turns: _animController,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const SweepGradient(
                                    colors: [Colors.blue, Colors.purple, Colors.amber, Colors.blue],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const Center(
                                  child: Icon(Icons.autorenew, color: Colors.white, size: 30),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Animación continua (60 FPS)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),

                        // Botón de interacción manual durante el cálculo
                        Column(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.touch_app, size: 18),
                              label: Text('Toques: $_interactiveCounter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade600,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _interactiveCounter++;
                                });
                              },
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Toca mientras calcula',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Controles de Configuración y Ejecución
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuración de Tarea CPU-Bound',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cálculo de primos hasta:'),
                        DropdownButton<int>(
                          value: _workloadLimit,
                          items: const [
                            DropdownMenuItem(value: 1000000, child: Text('1.000.000 números')),
                            DropdownMenuItem(value: 3000000, child: Text('3.000.000 números (Recomendado)')),
                            DropdownMenuItem(value: 6000000, child: Text('6.000.000 números (Pesado)')),
                          ],
                          onChanged: _status == IsolateStatus.runningIsolate || _status == IsolateStatus.runningMainThread
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() => _workloadLimit = val);
                                  }
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        // Botón Recomendado: En Isolate
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _status == IsolateStatus.runningIsolate
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Icon(Icons.flash_on),
                            label: Text(
                              _status == IsolateStatus.runningIsolate
                                  ? 'Calculando en Isolate (Segundo Plano)...'
                                  : 'Ejecutar en Isolate (Segundo Plano)',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _status == IsolateStatus.runningIsolate || _status == IsolateStatus.runningMainThread
                                ? null
                                : _runTaskInIsolate,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Botón Comparativo: En Hilo Principal
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.block, color: Colors.redAccent),
                            label: const Text(
                              'Ejecutar en Main Thread (Demuestra Congelamiento)',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _status == IsolateStatus.runningIsolate || _status == IsolateStatus.runningMainThread
                                ? null
                                : _runTaskOnMainThread,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Resultados del cálculo
            if (_lastResult != null) ...[
              Card(
                color: Colors.teal.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.teal.withValues(alpha: 0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.teal, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Resultado de la Computación',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildResultRow('Límite evaluado:', '${_lastResult!.limit} números'),
                      _buildResultRow('Números primos encontrados:', '${_lastResult!.primesCount}'),
                      _buildResultRow('Tiempo de procesamiento:', '${_lastResult!.elapsedMs} ms (${(_lastResult!.elapsedMs / 1000).toStringAsFixed(2)} s)'),
                      _buildResultRow('Tipo de ejecución:', _lastResult!.status),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Visor de consola en tiempo real
            ConsoleLogView(
              title: 'Consola de Comunicación de Isolates (SendPort/ReceivePort)',
              logs: _logs,
              onClear: () => setState(() => _logs.clear()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
