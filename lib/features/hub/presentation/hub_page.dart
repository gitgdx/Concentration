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
          // ⛔ Chaque entrée est EXPANDED : sans cela le Row debordait de 63 px a
          // 390 de large et de 133 px a 320 — trois libelles francais longs
          // (« Échéances », « Respiration », « Concentration ») ne tiennent pas
          // sur un telephone. Defaut invisible pour 90 tests, parce qu ils
          // tournaient TOUS au gabarit par defaut de flutter_test (800x600) ;
          // trouve en LANCANT l application, puis reproduit par
          // grille_gabarits_test.dart.
          child: Row(
            children: [
              for (final m in registre.tous)
                Expanded(child: _EntreeModule(module: m)),
              // ⛔ B-2 de la revue de code (2026-08-02) : ces deux commandes sont
              // exigées par AC-2 « Limite », ADR-004 §5, la tâche T10 ET une étape
              // du scénario Gherkin 2 — elles n'existaient NI en code NI en
              // assertion. Le contrôle T12b ne pouvait pas le voir : il compare
              // des TITRES de scénario, pas des étapes.
              // Rendues NON-INTERACTIVES par le même mécanisme que les modules
              // grisés : ABSENCE de gestionnaire, jamais un onTap vide.
              for (final c in _CommandeBarre.values)
                _CommandeNonInteractive(commande: c),
            ],
          ),
        ),
      ),
    );
  }
}

/// Commandes de la barre basse, **hors périmètre fonctionnel d'US-01.1**.
///
/// AC-2 « Limite » : *« Les autres commandes de la barre de navigation basse
/// (ajout, réglages) sont rendues **non-interactives** dans le périmètre
/// US-01.1 — leur activation relève d'US ultérieures. »*
enum _CommandeBarre {
  ajout('Ajouter une échéance', Icons.add),
  reglages('Réglages', Icons.settings);

  const _CommandeBarre(this.libelleAccessibilite, this.icone);

  /// Libellé **en français** — lu par le lecteur d'écran uniquement.
  final String libelleAccessibilite;
  final IconData icone;
}

/// Commande **visible mais inerte** (AC-2 « Limite », ADR-004 §5).
///
/// ⛔ Aucun `IconButton` : il porte un `onPressed` et une ondulation, donc il
/// **annoncerait une action**. Une simple `Icon` estompée, marquée
/// `enabled: false`, dit la vérité — et l'absence de gestionnaire rend
/// l'interdit **assertionnable** plutôt que révocable.
class _CommandeNonInteractive extends StatelessWidget {
  const _CommandeNonInteractive({required this.commande});

  final _CommandeBarre commande;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: commande.libelleAccessibilite,
      enabled: false,
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Icon(
          commande.icone,
          size: 20,
          color: ConcentrationTokens.moduleGrise.couleur,
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
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
