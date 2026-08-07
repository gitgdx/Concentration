import 'package:flutter/material.dart';

import '../core/theme/concentration_theme.dart';
import '../core/time/clock.dart';
import '../features/echeances/presentation/echeances_notifier.dart';
import '../features/hub/presentation/hub_page.dart';

/// Widget racine (T1 d'US-01.1, recâblé par T11 d'US-01.2).
///
/// ⛔ **Mode sombre imposé** : `themeMode: ThemeMode.dark` et aucun thème clair
/// fourni (AC-8). Si l'appareil est en mode clair, l'application **reste
/// sombre** — choix produit assumé (RNF-03).
///
/// ⚖️ **LE SEAM `echeances:` D'US-01.1 EST SUPPRIMÉ** (ADR-011 §5), et ce n'est
/// pas un nettoyage : il injectait des données **déjà chargées**, donc il
/// permettait d'écrire des tests « E2E » **verts sans toucher un octet** —
/// exactement ce qu'ADR-010 §1 interdit. La revue du 2026-08-02 avait relevé
/// que **11 tests sur 13 montaient un sous-arbre** ; l'ADR ferme les deux
/// portes à la fois. ⛔ **Il est supprimé, pas laissé « au cas où »** : deux
/// seams, c'est une règle en deux exemplaires, et deux copies dérivent.
///
/// ➡️ **Conséquence** : contourner la persistance exige désormais **d'écrire du
/// code pour le faire**, donc c'est **visible en revue** — et
/// `scripts/check_e2e_persistance.py` (T13) le vérifie par machine.
class ConcentrationApp extends StatelessWidget {
  const ConcentrationApp({
    required this.notifier,
    super.key,
    this.clock = const SystemClock(),
  });

  /// **Source de vérité unique**, injectée par la RACINE (ADR-011 §2).
  final EcheancesNotifier notifier;

  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Concentration',
      debugShowCheckedModeBanner: false,
      theme: ConcentrationTheme.sombre,
      darkTheme: ConcentrationTheme.sombre,
      themeMode: ThemeMode.dark,
      home: HubPage(notifier: notifier, clock: clock),
    );
  }
}
