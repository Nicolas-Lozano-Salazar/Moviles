import 'package:flutter/material.dart';
import 'future_screen.dart';
import 'timer_screen.dart';
import 'isolate_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FutureScreen(),
    TimerScreen(),
    IsolateScreen(),
  ];

  final List<String> _titles = const [
    'Future & Async/Await',
    'Cronómetro con Timer',
    'Concurrencia con Isolate',
  ];

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF0D47A1)),
            SizedBox(width: 8),
            Text('Taller 2: Segundo Plano', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('👤 Estudiante:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Nicolás Lozano Salazar\n'),
              Text('🎯 Objetivos del Taller:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('1. Asincronía con Future / async / await en servicios simulados.\n'
                  '2. Manejo de tiempo continuo y ciclo de vida con Timer.\n'
                  '3. Computación intensiva en hilos independientes con Isolate (Isolate.spawn).\n'
                  '4. Demostrar la fluidez de la UI sin bloqueos.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(_titles[_currentIndex]),
            const Text(
              'Nicolás Lozano Salazar • Taller 2',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Información del Proyecto',
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.cloud_sync_outlined),
            selectedIcon: Icon(Icons.cloud_sync, color: Color(0xFF0D47A1)),
            label: 'Future / Async',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer, color: Color(0xFF00897B)),
            label: 'Timer',
          ),
          NavigationDestination(
            icon: Icon(Icons.memory_outlined),
            selectedIcon: Icon(Icons.memory, color: Color(0xFFE65100)),
            label: 'Isolate',
          ),
        ],
      ),
    );
  }
}
