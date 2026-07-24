// Point d'entrée Flutter — squelette minimal de l'adapter `flutter`.
//
// Remplacer ce fichier au fil des US : le hub de pratiques réel (navigation,
// écrans, thème) vient ici, en suivant les conventions décrites dans
// docs/governance/STACK_PROFILE.md §Developer.

import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Concentration',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const SkeletonHomePage(),
    );
  }
}

class SkeletonHomePage extends StatefulWidget {
  const SkeletonHomePage({super.key});

  @override
  State<SkeletonHomePage> createState() => _SkeletonHomePageState();
}

class _SkeletonHomePageState extends State<SkeletonHomePage> {
  int _counter = 0;

  void _increment() => setState(() => _counter++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Squelette prêt'),
            const SizedBox(height: 8),
            Text('Compteur : $_counter'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _increment,
              child: const Text('Incrémenter'),
            ),
          ],
        ),
      ),
    );
  }
}
