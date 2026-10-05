import 'package:flutter/material.dart';

class ConsoleLogView extends StatelessWidget {
  final List<String> logs;
  final VoidCallback? onClear;
  final String title;

  const ConsoleLogView({
    super.key,
    required this.logs,
    this.onClear,
    this.title = 'Consola de Eventos y Mensajes',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF090D16) : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blueGrey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C2E) : const Color(0xFF2D2D2D),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.terminal, color: Colors.greenAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white60),
                    tooltip: 'Limpiar consola',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onClear,
                  ),
              ],
            ),
          ),
          Container(
            height: 140,
            padding: const EdgeInsets.all(12),
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'Esperando ejecución... Los mensajes se imprimirán aquí.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: logs.length,
                    reverse: false,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      Color textColor = Colors.greenAccent;
                      if (log.contains('ERROR') || log.contains('Error') || log.contains('fallo')) {
                        textColor = Colors.redAccent;
                      } else if (log.contains('ANTES') || log.contains('Iniciando')) {
                        textColor = Colors.cyanAccent;
                      } else if (log.contains('DURANTE') || log.contains('Esperando') || log.contains('Procesando')) {
                        textColor = Colors.amberAccent;
                      } else if (log.contains('WORKER') || log.contains('Isolate Secundario')) {
                        textColor = Colors.purpleAccent;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          log,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
