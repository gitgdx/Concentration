import 'package:flutter/material.dart';

import '../../../core/theme/concentration_tokens.dart';
import '../../../core/theme/rgb_extension.dart';
import '../../../core/time/clock.dart';
import '../../echeances/domain/echeance.dart';
import '../../echeances/presentation/echeances_grid.dart';
import '../domain/practice_module.dart';
import '../domain/practice_module_registry.dart';

/// Écran du hub de pratiques (T10).
///
/// Le hub **itère sur le registre** : il ne connaît aucun module en dur
/// (ADR-004). Les modules `grise` sont rendus **sans aucun gestionnaire de
/// geste** — jamais par un `onTap` vide, qui mentirait à l'accessibilité et
/// resterait révocable par accident (AC-2).
class HubPage extends StatelessWidget {
  const HubPage({
    required this.echeances,
    required this.clock,
    super.key,
    this.registre = const PracticeModuleRegistry(),
  });

  final List<Echeance> echeances;
  final Clock clock;
  final PracticeModuleRegistry registre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Concentration')),
      body: EcheancesGrid(echeances: echeances, clock: clock),
      bottomNavigationBar: _BarreModules(registre: registre),
    );
  }
}

/// Barre basse : module actif mis en avant, modules futurs **estompés et
/// non-interactifs**.
///
/// Placement retenu par @UXDesigner (`DESIGN_SYSTEM.md`) plutôt que des tuiles
/// grisées dans la grille, qui voleraient de la surface aux 9 tuiles d'AC-3.
class _BarreModules extends StatelessWidget {
  const _BarreModules({required this.registre});

  final PracticeModuleRegistry registre;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: ConcentrationTokens.fondApp.couleur),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [for (final m in registre.tous) _EntreeModule(module: m)],
          ),
        ),
      ),
    );
  }
}

class _EntreeModule extends StatelessWidget {
  const _EntreeModule({required this.module});

  final PracticeModule module;

  @override
  Widget build(BuildContext context) {
    final estActif = module.statut == StatutModule.actif;
    final couleur = estActif
        ? ConcentrationTokens.moduleActif.couleur
        : ConcentrationTokens.moduleGrise.couleur;

    final libelle = Text(
      module.libelle,
      style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: couleur),
    );

    // ⛔ AUCUN GestureDetector / InkWell / onTap pour un module grisé : c'est
    // l'ABSENCE de gestionnaire qui rend l'interdit d'AC-2 vérifiable, là où un
    // callback vide le laisserait révocable.
    if (!estActif) {
      return Semantics(enabled: false, container: true, child: libelle);
    }
    return Semantics(selected: true, container: true, child: libelle);
  }
}
