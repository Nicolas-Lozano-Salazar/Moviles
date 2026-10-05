import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/console_log_view.dart';

enum TimerState { stopped, running, paused }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _timer;
  int _milliseconds = 0;
  TimerState _timerState = TimerState.stopped;
  final List<String> _logs = [];
  final List<String> _laps = [];

  void _addLog(String log) {
    if (mounted) {
      setState(() {
        final time = TimeOfDay.now().format(context);
        _logs.add('[$time] $log');
      });
    }
  }

  /// Inicia el Timer periódico desde cero
  void _startTimer() {
    _timer?.cancel();
    _milliseconds = 0;
    _laps.clear();
    _timerState = TimerState.running;

    _addLog('[TIMER] Iniciando Timer.periodic (intervalo: 100 ms)...');

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _milliseconds += 100;
      });
    });

    setState(() {});
  }

  /// Pausa el Timer cancelando la instancia activa pero conservando el tiempo acumulado
  void _pauseTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      _timerState = TimerState.paused;
      _addLog('[TIMER] Pausando: Timer.cancel() ejecutado. Tiempo guardado: ${_formatTime(_milliseconds)}');
      setState(() {});
    }
  }

  /// Reanuda el Timer continuando desde el tiempo acumulado
  void _resumeTimer() {
    if (_timerState == TimerState.paused) {
      _timerState = TimerState.running;
      _addLog('[TIMER] Reanudando Timer.periodic desde ${_formatTime(_milliseconds)}...');

      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _milliseconds += 100;
        });
      });

      setState(() {});
    }
  }

  /// Reinicia el cronómetro y cancela cualquier Timer activo
  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    _milliseconds = 0;
    _timerState = TimerState.stopped;
    _laps.clear();
    _addLog('[TIMER] Reiniciando cronómetro a 00:00:00.0 y liberando recursos.');
    setState(() {});
  }

  /// Registra una vuelta (Lap)
  void _recordLap() {
    final lapTime = _formatTime(_milliseconds);
    setState(() {
      _laps.insert(0, 'Vuelta #${_laps.length + 1}: $lapTime');
    });
    _addLog('[TIMER] Vuelta registrada: $lapTime');
  }

  /// Formatea milisegundos a formato digital HH:MM:SS.S
  String _formatTime(int ms) {
    final int hundredths = (ms % 1000) ~/ 100;
    final int seconds = (ms ~/ 1000) % 60;
    final int minutes = (ms ~/ (1000 * 60)) % 60;
    final int hours = ms ~/ (1000 * 60 * 60);

    final String hoursStr = hours.toString().padLeft(2, '0');
    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secondsStr = seconds.toString().padLeft(2, '0');

    return '$hoursStr:$minutesStr:$secondsStr.$hundredths';
  }

  @override
  void dispose() {
    // Limpieza obligatoria de recursos al salir de la pantalla
    if (_timer != null && _timer!.isActive) {
      // ignore: avoid_print
      print('[TIMER DISPOSE] Cancelando Timer activo para evitar fugas de memoria.');
      _timer!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header explicativo
            Card(
              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.timer, size: 40, color: theme.colorScheme.secondary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '2. Cronómetro con Timer (dart:async)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Actualización periódica cada 100 ms. Control de ciclo de vida y limpieza de recursos (dispose) para evitar memory leaks.',
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

            // Marcador Digital Grande
            Card(
              elevation: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _timerState == TimerState.running
                                ? Colors.greenAccent
                                : (_timerState == TimerState.paused ? Colors.amberAccent : Colors.redAccent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timerState == TimerState.running
                              ? 'EN EJECUCIÓN'
                              : (_timerState == TimerState.paused ? 'EN PAUSA' : 'DETENIDO'),
                          style: const TextStyle(
                            color: Colors.white70,
                            letterSpacing: 2,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatTime(_milliseconds),
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          fontFamily: 'monospace',
                          color: Color(0xFF00E676),
                          shadows: [
                            Shadow(
                              color: Color(0x9900E676),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'HORAS : MIN : SEG . DÉCIMAS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botones de Control (Iniciar, Pausar, Reanudar, Reiniciar)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        // Botón Iniciar
                        if (_timerState == TimerState.stopped)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Iniciar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                            onPressed: _startTimer,
                          ),

                        // Botón Pausar
                        if (_timerState == TimerState.running)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.pause),
                            label: const Text('Pausar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                            onPressed: _pauseTimer,
                          ),

                        // Botón Reanudar
                        if (_timerState == TimerState.paused)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Reanudar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                            onPressed: _resumeTimer,
                          ),

                        // Botón Vuelta (Lap)
                        if (_timerState == TimerState.running)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.flag_outlined),
                            label: const Text('Vuelta'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            onPressed: _recordLap,
                          ),

                        // Botón Reiniciar
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reiniciar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          onPressed: _milliseconds == 0 && _timerState == TimerState.stopped ? null : _resetTimer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Lista de vueltas si existen
            if (_laps.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Vueltas Registradas (${_laps.length})',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => setState(() => _laps.clear()),
                            child: const Text('Borrar Vueltas'),
                          ),
                        ],
                      ),
                      const Divider(),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          itemCount: _laps.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                _laps[index],
                                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Visor de consola en tiempo real
            ConsoleLogView(
              title: 'Consola de Eventos del Timer',
              logs: _logs,
              onClear: () => setState(() => _logs.clear()),
            ),
          ],
        ),
      ),
    );
  }
}
