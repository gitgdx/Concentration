import 'package:flutter/material.dart';

import '../../../core/theme/concentration_tokens.dart';
import '../../../core/theme/rgb_extension.dart';
import '../../../core/time/clock.dart';
import '../../echeances/presentation/echeances_grid.dart';
import '../../echeances/presentation/echeances_notifier.dart';
import '../../echeances/presentation/gestion_echeances_page.dart';
import '../domain/practice_module.dart';
import '../domain/practice_module_registry.dart';

/// Écran du hub de pratiques (T10 d'US-01.1, recâblé par T11 d'US-01.2).
///
/// Le hub **itère sur le registre** : il ne connaît aucun module en dur
/// (ADR-004). Les modules `grise` sont rendus **sans aucun gestionnaire de
/// geste** — jamais par un `onTap` vide, qui mentirait à l'accessibilité et
/// resterait révocable par accident (AC-2).
///
/// ⚖️ **US-01.2 active UNE SEULE commande** : « Gérer les échéances ».
/// ⛔ « Réglages » **reste inerte** *(son activation relève d'une US
/// ultérieure)* et ⛔ les modules grisés **restent sans gestionnaire**.
class HubPage extends StatelessWidget {
  const HubPage({
    required this.notifier,
    required this.clock,
    super.key,
    this.registre = const PracticeModuleRegistry(),
  });

  final EcheancesNotifier notifier;
  final Clock clock;
  final PracticeModuleRegistry registre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Concentration')),
      // ⛔ La grille se reconstruit par NOTIFICATION, jamais par redémarrage
      // (AC-6 « Nominal », AC-13 « Limite »). `EcheancesGrid` est INCHANGÉE :
      // elle reçoit une `List<Echeance>` et n'a pas à connaître le dépôt.
      body: ListenableBuilder(
        listenable: notifier,
        builder: (context, _) =>
            EcheancesGrid(echeances: notifier.echeances, clock: clock),
      ),
      bottomNavigationBar: _BarreModules(
        registre: registre,
        notifier: notifier,
        clock: clock,
      ),
    );
  }
}

/// Barre basse : module actif mis en avant, modules futurs **estompés et
/// non-interactifs**.
///
/// Placement retenu par @UXDesigner (`DESIGN_SYSTEM.md`) plutôt que des tuiles
/// grisées dans la grille, qui voleraient de la surface aux 9 tuiles d'AC-3.
class _BarreModules extends StatelessWidget {
  const _BarreModules({
    required this.registre,
    required this.notifier,
    required this.clock,
  });

  final PracticeModuleRegistry registre;
  final EcheancesNotifier notifier;
  final Clock clock;

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
              // ⚖️ US-01.2 : « ajout » devient INTERACTIVE, « Réglages » reste
              // rendue NON-INTERACTIVE par le même mécanisme que les modules
              // grisés — ABSENCE de gestionnaire, jamais un onTap vide.
              _CommandeGestion(notifier: notifier, clock: clock),
              const _CommandeNonInteractive(commande: _CommandeBarre.reglages),
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

/// 🔴 **LA SEULE commande que cette US rend INTERACTIVE** (AC-1).
///
/// **Trois choses changent, et chacune a son motif chiffré** :
/// 1. **Le LIBELLÉ devient « Gérer les échéances »** — ⛔ pas « Ajouter une
///    échéance » : la commande **ouvre la gestion** *(création, édition,
///    suppression)*. Un libellé qui **promet moins que ce qu'il fait**
///    **trompe le lecteur d'écran** (RNF-06).
/// 2. **La COULEUR passe à `moduleActif`** — et c'est une **conséquence
///    chiffrée, pas un goût** : tant qu'elle était inerte, `moduleGrise` était
///    licite *(composant désactivé, exempté SC 1.4.3)* ; **devenue
///    interactive**, elle est soumise à **SC 1.4.11 ⇒ ≥ 3:1**, or
///    `moduleGrise / fondApp` rend **1,50:1**. `moduleActif` rend **10,89:1**.
/// 3. **Elle porte un `IconButton`** — c'est précisément ce qu'AC-2 « Limite »
///    d'US-01.1 interdisait pour une commande **hors périmètre** : *« un
///    `IconButton` annoncerait une action inexistante »*. **L'action existe
///    désormais.**
///
/// ⛔ **`Icons.add` est CONSERVÉE** : une assertion d'US-01.1
/// *(`find.byIcon(Icons.add)`)* est mesurée comme **survivante** ; la changer
/// ferait tomber une **5ᵉ** assertion là où le §Effet de bord en mesure **4**.
/// ⚠️ **Incohérence assumée et nommée** : pour un utilisateur voyant, l'icône
/// dit *« ajouter »* alors que l'action dit *« gérer »*. Le remplacement est
/// porté à l'US qui retouchera la barre basse *(recommandation U-3)*.
class _CommandeGestion extends StatelessWidget {
  const _CommandeGestion({required this.notifier, required this.clock});

  final EcheancesNotifier notifier;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 48,
      // ⛔ `Semantics(label:)` EXPLICITE, ⛔ pas seulement un `tooltip` :
      // `Tooltip` renseigne `SemanticsProperties.tooltip`, ⛔ PAS le `label`.
      // Mesuré : `find.bySemanticsLabel('Gérer les échéances')` rendait
      // **0 widget** avec le seul tooltip — le NOM ACCESSIBLE de la commande
      // aurait donc été absent, exactement ce qu'AC-1 exige de garantir.
      // Le libellé vit en UN exemplaire : `GestionEcheancesPage.titre`.
      child: Semantics(
        label: GestionEcheancesPage.titre,
        button: true,
        container: true,
        child: IconButton(
          tooltip: GestionEcheancesPage.titre,
          onPressed: () => Navigator.of(context)
              .push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      GestionEcheancesPage(notifier: notifier, clock: clock),
                ),
              )
              .ignore(),
          icon: Icon(
            Icons.add,
            size: 20,
            color: ConcentrationTokens.moduleActif.couleur,
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
