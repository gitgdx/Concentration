import 'package:flutter/material.dart';

import '../core/theme/concentration_theme.dart';
import '../core/time/clock.dart';
import '../features/echeances/data/sample_echeances.dart';
import '../features/hub/presentation/hub_page.dart';

/// Widget racine (T1).
///
/// ⛔ **Mode sombre imposé** : `themeMode: ThemeMode.dark` et aucun thème clair
/// fourni (AC-8). Si l'appareil est en mode clair, l'application **reste
/// sombre** — choix produit assumé (RNF-03).
class ConcentrationApp extends StatelessWidget {
  const ConcentrationApp({super.key, this.clock = const SystemClock()});

  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Concentration',
      debugShowCheckedModeBanner: false,
      theme: ConcentrationTheme.sombre,
      darkTheme: ConcentrationTheme.sombre,
      themeMode: ThemeMode.dark,
      home: HubPage(echeances: SampleEcheances.depuis(clock), clock: clock),
    );
  }
}
