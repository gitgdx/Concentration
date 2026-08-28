import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/concentration_tokens.dart';
import '../../../core/theme/rgb_extension.dart';
import '../../../core/time/clock.dart';
import '../../echeances/domain/validation_echeance.dart';
import '../../echeances/presentation/echeances_grid.dart';
import '../../echeances/presentation/echeances_notifier.dart';
import '../../echeances/presentation/gestion_echeances_page.dart';
import '../../echeances/presentation/widgets/message_ecriture.dart';
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
class HubPage extends StatefulWidget {
  const HubPage({
    required this.notifier,
    required this.clock,
    super.key,
    this.registre = const PracticeModuleRegistry(),
  });

  final EcheancesNotifier notifier;
  final Clock clock;
  final PracticeModuleRegistry registre;

  /// Clé de la ZONE DE MESSAGE — ⛔ **elle désigne l'enveloppe, pas le texte**.
  ///
  /// La zone est **montée en permanence** *(sa hauteur est réservée)*, donc
  /// `find.byType(MessageEcriture)` la trouve **même sans message** : une
  /// assertion écrite sur le TYPE ne saurait donc pas dire *« il n'y a pas de
  /// message »*. ⇒ ce qui se teste est la **visibilité**, lue sur cette clé.
  static const Key cleZoneMessage = Key('hub-zone-message');

  @override
  State<HubPage> createState() => _HubPageState();
}

/// 🔴 **`HubPage` est `Stateful` DEPUIS T19, et ⛔ pas par confort**
/// *([ADR-014](../../../../docs/adr/ADR-014-enveloppe-interactive-conditionnelle-etat-message-hub.md) §B.1)*.
///
/// Le message d'échec d'un retrait est un **quatrième état éphémère** qui n'avait
/// de place nulle part : il n'est **pas** un état de tuile *(il est peint hors de
/// la grille)*, et le hub est **le seul** widget qui l'affiche.
///
/// ⚠️ **ADR-013 avait écarté `HubPage` pour la RÉVÉLATION, et ce motif NE SE
/// TRANSFÈRE PAS** : il portait sur *« la discipline de `dispose` d'un
/// minuteur »*. ⛔ **Ici il n'y a AUCUN minuteur**, donc aucun `dispose` à
/// tenir — c'est précisément ce qui rend ce choix licite.
///
/// ⛔ **UN SEUL champ, et « remplacé par un nouvel échec » est vrai PAR
/// CONSTRUCTION** : un `String?` ne peut pas contenir deux messages. ⛔ Rien ne
/// le surveille, parce que rien ne peut le violer.
class _HubPageState extends State<HubPage> {
  /// ⛔ **Aucun `Timer`, aucun `AnimationController`, aucun bouton de
  /// fermeture, aucun effacement au rafraîchissement de 30 s** (ADR-014 §B.2).
  String? _messageEcriture;

  /// Le rappel de retrait — ⛔ **jamais `void`** (ADR-014 §B.3).
  ///
  /// `null` ⇒ succès, sinon le refus à afficher : c'est **exactement** la
  /// signature des chemins d'écriture existants *(`creer`, `modifier`,
  /// `supprimer`)*, donc ⛔ **aucun patron nouveau**.
  ///
  /// 🔴 **Le retour typé n'est pas une élégance** : `unawaited_futures` est
  /// **aveugle dans un appelant synchrone** *(prouvé par mutant dans les deux
  /// sens en US-01.2)*. Un retour non-`void` est ce qui **interdit** à la grille
  /// d'ignorer l'issue — donc de laisser une tuile disparue après un échec.
  ///
  /// **Premier des trois effacements** : un retrait qui RÉUSSIT rend `null`, et
  /// le message tombe.
  Future<RefusValidation?> _retirer(String id) async {
    final refus = await widget.notifier.retirer(id);
    if (!mounted) return refus;
    setState(() => _messageEcriture = refus?.message);
    return refus;
  }

  /// **Troisième effacement — on QUITTE le hub.**
  ///
  /// 🔴 **`dispose()` NE SUFFIT PAS, et c'est MESURÉ : il n'est JAMAIS appelé**
  /// *(ADR-014 §Contexte 6 — `Navigator.push` ⛔ **ne démonte pas** la route du
  /// dessous, `disposes=0`, même `State`)*. ⇒ l'état **attend le retour du
  /// `push`** et efface, sous garde `if (!mounted)`.
  ///
  /// ⚖️ **C'est ici que le `.ignore()` de `_CommandeGestion` a disparu** : il
  /// **jetait** le `Future` qui porte l'information *« on est revenu »*. ⛔ Et le
  /// remplacer par un `await` **dans la commande** *(un `StatelessWidget`)*
  /// aurait rendu le lint vert **sans que personne n'apprenne le retour** — le
  /// mensonge aurait été déplacé, pas supprimé.
  ///
  /// ⛔ **Aucun `RouteObserver`** : un mécanisme **global** sur `MaterialApp`
  /// pour un effet **d'un seul écran**, alors que ce `Future` est déjà là.
  void _surRetourDeGestion(Future<void> retour) {
    unawaited(
      retour.then((_) {
        if (!mounted) return;
        setState(() => _messageEcriture = null);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = widget.notifier;
    final clock = widget.clock;
    return Scaffold(
      appBar: AppBar(title: const Text('Concentration')),
      // ⛔ La grille se reconstruit par NOTIFICATION, jamais par redémarrage
      // (AC-6 « Nominal », AC-13 « Limite »). `EcheancesGrid` est INCHANGÉE :
      // elle reçoit une `List<Echeance>` et n'a pas à connaître le dépôt.
      //
      // ⚖️ **`presentes` ET ⛔ PAS `echeances` depuis le 2026-08-24 (T4
      // d'US-01.4)** : une échue **retirée** est **conservée** mais ⛔ **absente
      // de la grille** *(AC-4, AC-5)*. **C-7** — c'est le **MÊME** getter que
      // consomme la limite de 9, ⛔ **jamais un second filtre écrit ici** : deux
      // filtres dériveraient, et le symptôme serait *la grille montre 8 tuiles
      // et la création est refusée*.
      // 🔴 **LA ZONE DE MESSAGE EST LE DERNIER ENFANT DU CORPS, et sa hauteur
      // est RÉSERVÉE EN PERMANENCE** (Design UX §5.2, ADR-014 §B).
      // ⛔ **Ce n'est PAS de la mise en page, c'est de la SÛRETÉ.** Le bloc de
      // grille est **centré** : une bande qui *apparaît* le remonterait
      // d'environ la moitié de sa hauteur — **au moment exact où le pratiquant
      // réessaie son double appui**. Un double appui égaré retire la
      // **MAUVAISE** échéance, ce qui est **irréversible** ⇒ le reflux
      // **aggraverait le risque nº 5**.
      // ⛔ **Aucune constante de hauteur devinée** *(défaut nº 1)* : `maintainSize`
      // réserve la place que le texte occupe **réellement**, à la largeur et à
      // l'échelle courantes.
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: notifier,
              builder: (context, _) => EcheancesGrid(
                echeances: notifier.presentes,
                clock: clock,
                // ⚖️ **T19 BRANCHE le rappel — c'est le commit où le retrait
                // devient réellement utilisable sur le hub.** À T10 il valait
                // `null` DÉLIBÉRÉMENT : brancher un retrait sans surface de
                // message aurait livré un échec **silencieux**, soit AC-11
                // violé. La surface et le branchement sont ici, ⛔ dans le
                // MÊME commit — l'un sans l'autre est un défaut.
                onRetirer: _retirer,
              ),
            ),
          ),
          Visibility(
            key: HubPage.cleZoneMessage,
            visible: _messageEcriture != null,
            maintainSize: true,
            maintainState: true,
            maintainAnimation: true,
            // ⛔ Le texte vide n'est JAMAIS peint (`visible: false`) : il ne
            // sert qu'à réserver la hauteur d'une ligne avant tout message.
            child: MessageEcriture(
              texte: _messageEcriture ?? '',
              // ⛔ **PAS `erreur` sur le hub, et c'est une MESURE** : `erreur`,
              // `moduleActif` et `texteSecondaire` sont à **1,00:1 ENTRE EUX**
              // ⇒ le rouge ne distinguerait **rien** de la barre basse, tout en
              // perdant **3,47 points** de contraste (14,39:1 → 10,93:1).
              ton: TonMessage.surfaceDePratique,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BarreModules(
        registre: widget.registre,
        notifier: notifier,
        clock: clock,
        onRetourDeGestion: _surRetourDeGestion,
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
    required this.onRetourDeGestion,
  });

  final PracticeModuleRegistry registre;
  final EcheancesNotifier notifier;
  final Clock clock;

  /// ⛔ **La barre ne fait que TRANSPORTER le `Future`** : elle ne l'attend pas
  /// et ne l'ignore pas. Le seul qui peut l'attendre est le porteur de l'état
  /// (ADR-014 §B.2).
  final void Function(Future<void> retour) onRetourDeGestion;

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
              _CommandeGestion(
                notifier: notifier,
                clock: clock,
                onRetourDeGestion: onRetourDeGestion,
              ),
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
  const _CommandeGestion({
    required this.notifier,
    required this.clock,
    required this.onRetourDeGestion,
  });

  final EcheancesNotifier notifier;
  final Clock clock;

  /// ⛔ **Le `Future` du `push` REMONTE ici, il n'est plus jeté.**
  ///
  /// ⚖️ **Ce paramètre remplace un `.ignore()`** *(T19, ADR-014 §B.2)* : celui-ci
  /// existait pour taire `unawaited_futures`, et il **jetait avec lui
  /// l'information « on est revenu »**. ⛔ Le remède au symptôme aurait été un
  /// `await` **ici** — dans un `StatelessWidget` qui ne porte aucun état : le
  /// lint serait vert et **personne n'apprendrait le retour**.
  final void Function(Future<void> retour) onRetourDeGestion;

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
          onPressed: () => onRetourDeGestion(
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    GestionEcheancesPage(notifier: notifier, clock: clock),
              ),
            ),
          ),
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
