import 'package:flutter/material.dart';

import '../core/theme/concentration_theme.dart';
import '../core/time/clock.dart';
import '../features/echeances/data/sample_echeances.dart';
import '../features/echeances/domain/echeance.dart';
import '../features/hub/presentation/hub_page.dart';

/// Widget racine (T1).
///
/// ⛔ **Mode sombre imposé** : `themeMode: ThemeMode.dark` et aucun thème clair
/// fourni (AC-8). Si l'appareil est en mode clair, l'application **reste
/// sombre** — choix produit assumé (RNF-03).
class ConcentrationApp extends StatelessWidget {
  const ConcentrationApp({
    super.key,
    this.clock = const SystemClock(),
    this.echeances,
  });

  final Clock clock;

  /// Jeu d'échéances injecté. `null` ⇒ les données d'exemple.
  ///
  /// ⚠️ Existe pour que les scénarios de track FULL montent **la RACINE de
  /// l'application**, comme ADR-008 §1 l'exige — c'est la seule chose qui a
  /// autorisé à écarter `integration_test/`. La revue de code du 2026-08-02 a
  /// relevé que **11 tests sur 13 montaient `MaterialApp(home: HubPage)`** et
  /// non la racine : le contrat de l'ADR n'était donc pas tenu à la lettre.
  final List<Echeance>? echeances;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Concentration',
      debugShowCheckedModeBanner: false,
      theme: ConcentrationTheme.sombre,
      darkTheme: ConcentrationTheme.sombre,
      themeMode: ThemeMode.dark,
      home: HubPage(
        echeances: echeances ?? SampleEcheances.depuis(clock),
        clock: clock,
      ),
    );
  }
}
