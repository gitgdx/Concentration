import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/concentration_theme.dart';
import '../../../core/theme/concentration_tokens.dart';
import '../../../core/time/clock.dart';
import '../domain/echeance.dart';
import '../domain/remaining_time_calculator.dart';
import '../domain/validation_echeance.dart';
import 'widgets/echeance_tile.dart';
import 'widgets/empty_echeances_placeholder.dart';

/// Grille des tuiles (T9).
///
/// * Tri **strict par date croissante** ⇒ une échue remonte **en tête**
///   (RF-07, AC-6, `clarify` nº 2) — `estEchue` ne relègue **pas** ;
/// * bornée à [ConcentrationTokens.tuilesMax] tuiles (RF-15) ;
/// * rafraîchie au moins une fois par minute via [Clock] (RF-05) ;
/// * bascule vers [EmptyEcheancesPlaceholder] quand **0** tuile (AC-9).
class EcheancesGrid extends StatefulWidget {
  const EcheancesGrid({
    required this.echeances,
    required this.clock,
    required this.onRetirer,
    super.key,
    this.calculateur = const RemainingTimeCalculator(),
  });

  final List<Echeance> echeances;
  final Clock clock;
  final RemainingTimeCalculator calculateur;

  /// 🔴 **LE RAPPEL DE RETRAIT — et rien de plus** *(ADR-013 §7)* : ⛔ ni le
  /// dépôt, ni le notifier, ce qui garde vrai le commentaire mesuré
  /// d'`hub_page.dart` *(« `EcheancesGrid` … n'a pas à connaître le dépôt »)*.
  ///
  /// 🔴 **`Future<RefusValidation?>`, ⛔ JAMAIS `void`** *(ADR-014 §B.3)* :
  /// `null` ⇒ **succès**, sinon le **refus à afficher**. C'est la signature des
  /// **quatre** chemins d'écriture existants, donc ⛔ **aucun pattern nouveau**.
  /// C'est aussi ce **type de retour** qui ferme le résidu d'`unawaited_futures`
  /// *(mesuré aveugle dans un appelant synchrone)* : la grille **ne peut pas
  /// ignorer** l'issue, donc elle ne peut pas laisser une tuile disparue après
  /// une écriture échouée *(AC-11)*.
  ///
  /// ⛔ **Le paramètre est un `id`, ⛔ pas une `Echeance`** : c'est la forme de
  /// `supprimer(String id)` et de `retirer(String id)`, et la **même clé** que
  /// les états éphémères de cette grille. Passer l'entité ferait **deux façons
  /// de désigner une échéance** dans le même écran.
  ///
  /// ⛔ **Nullable ET `required` : les deux, et c'est le précédent de T8.**
  /// `required` interdit qu'un appelant l'**oublie** ; nullable l'oblige à
  /// **dire** qu'il n'y a rien à retirer — et une échue **sans rappel** n'a
  /// alors **aucune intention**, donc **aucune enveloppe interactive**
  /// *(ADR-014 §A.1 : ⛔ jamais une surface annoncée sans effet)*.
  final Future<RefusValidation?> Function(String id)? onRetirer;

  /// 🔴 **L'ENVELOPPE D'ANIMATION SE DÉSIGNE PAR SON IDENTITÉ, ⛔ JAMAIS PAR
  /// SON TYPE NI PAR SA POSITION** — c'est **la leçon de `NB-7`** appliquée à
  /// une seconde boîte, et elle a déjà coûté une fois : un sélecteur en `.first`
  /// sur un type peut désigner la **mauvaise** boîte **sans rougir**.
  ///
  /// ⚖️ **Cette constante est dans le produit et consommée par les tests, et
  /// c'est ASSUMÉ** *(même arbitrage que `EcheanceTile.cleFond`)* : elle fait de
  /// « une animation se joue » une propriété **observable**, là où
  /// `find.byType(FadeTransition)` serait ambigu dès qu'un widget du SDK en
  /// insère une.
  ///
  /// 🔴 **Sa PRÉSENCE est l'instrument d'AC-8 et d'AC-11** : montée ⇔ une
  /// animation de disparition est **en cours**. Elle est ⛔ **absente** pendant
  /// l'écriture, ⛔ **absente** si l'écriture échoue, et ⛔ **absente** en mode
  /// « animations réduites » *(départ immédiat)*.
  static const Key cleDisparition = Key('echeances-grid-disparition');

  @override
  State<EcheancesGrid> createState() => _EcheancesGridState();
}

class _EcheancesGridState extends State<EcheancesGrid>
    with SingleTickerProviderStateMixin {
  Timer? _minuterie;

  /// 🔴 **L'EXCLUSIVITÉ DE LA RÉVÉLATION EST STRUCTURELLE** (C-1) : un champ
  /// nullable **ne peut pas** contenir deux `id`, donc *« appuyer une seconde
  /// tuile referme la première »* est vrai **par CONSTRUCTION** — ⛔ pas
  /// surveillé par une règle qu'on pourrait oublier.
  String? _idRevele;

  /// ⛔ **UN SEUL minuteur de révélation, JAMAIS un par tuile** (C-1, mutant
  /// **M-9**) : un minuteur par tuile ferait de l'exclusivité une propriété
  /// *surveillée* et ferait tourner jusqu'à 9 minuteurs concurrents.
  ///
  /// ⛔ **Et il est INDÉPENDANT de [_minuterie]** (C-2) : le `setState(() {})`
  /// périodique reconstruit la grille et **ne touche ni l'un ni l'autre** ⇒ la
  /// fenêtre n'est **ni coupée ni prolongée** *(AC-2 « Limite », mutant
  /// **M-10**)*.
  Timer? _minuterieRevelation;

  /// 🔴 **L'ÉTAT DE LA TUILE SORTANTE, et c'est une NÉCESSITÉ** *(ADR-013 §1)* :
  /// une tuile **retirée de la liste** n'existe plus dans l'arbre, donc ⛔ **elle
  /// ne peut pas s'animer elle-même** — la grille la **MAINTIENT rendue** le
  /// temps de l'animation *(AC-8)*.
  ///
  /// ⚖️ **ÉCART DÉCLARÉ, imposé par la MESURE — ADR-013 §1 écrit
  /// `String? _idEnRetrait`, ce champ porte l'ENTITÉ.** La **décision** de
  /// l'ADR *(un état de tuile sortante, UN seul, dans ce `State`)* est
  /// respectée ; seul son **type** est élargi, et voici pourquoi un `id` ne
  /// suffit pas : `EcheancesNotifier.retirer` **recharge depuis le disque avant
  /// de rendre son résultat** *(⛔ aucune mise à jour optimiste)*, donc à
  /// l'instant où l'animation peut démarrer l'échéance **a déjà quitté
  /// `widget.echeances`** ⇒ un `id` seul ne permet de rendre **ni le nombre, ni
  /// la couleur, ni la description**. `_sortante?.id` donne l'`id` ; l'inverse
  /// est impossible.
  ///
  /// 🔴 **CE CHAMP EST AUSSI LA GARDE « UN SEUL RETRAIT À LA FOIS »** — ⛔ pas
  /// un second drapeau : un champ nullable **ne peut pas** porter deux retraits,
  /// donc *« un second geste ne retire rien d'autre »* est vrai **par
  /// construction** *(AC-8 « Limite », même raisonnement que [_idRevele])*. Il
  /// couvre **l'écriture ET l'animation** : deux écritures concurrentes se
  /// disputeraient le même document.
  /// ⛔ **Ce n'est PAS une tuile désactivée** : son intention reste **branchée**,
  /// le geste est donc **REÇU** et **sans effet** — la clause reste observable.
  Echeance? _sortante;

  /// L'animation de disparition — **UN SEUL contrôleur**, réutilisé.
  ///
  /// ⛔ **Ce n'est PAS un quatrième état éphémère** : c'est le **mécanisme** de
  /// [_sortante], que l'ADR nomme lui-même *(« la grille la maintient rendue le
  /// temps de l'animation »)*. Le seuil de réexamen posé par ADR-013
  /// §Conséquences porte sur un état **de plus**, et le message d'échec — qui en
  /// serait un — vit **dans le hub** *(ADR-014 §B)*.
  late final AnimationController _disparition;

  /// La courbe, dérivée du contrôleur — ⛔ **construite UNE fois** : une
  /// `CurvedAnimation` créée à chaque `build` devrait être libérée à chaque
  /// `build`.
  late final CurvedAnimation _courbe;

  @override
  void initState() {
    super.initState();
    _minuterie = Timer.periodic(
      ConcentrationTokens.periodeRafraichissement,
      (_) => setState(() {}),
    );
    _disparition = AnimationController(
      vsync: this,
      duration: ConcentrationTokens.dureeDisparition,
    )..addStatusListener(_finDeDisparition);
    _courbe = CurvedAnimation(
      parent: _disparition,
      curve: ConcentrationTheme.courbeDisparition,
    );
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    _minuterieRevelation?.cancel();
    _courbe.dispose();
    _disparition.dispose();
    super.dispose();
  }

  /// Révèle la description de `id` pour [ConcentrationTokens.fenetreRevelation].
  ///
  /// **Un nouvel appui REDÉMARRE la fenêtre** — le minuteur précédent est
  /// annulé, ⛔ jamais laissé courir : sinon la description d'une tuile
  /// pourrait se refermer à cause de l'appui fait sur une AUTRE.
  void _reveler(String id) {
    _minuterieRevelation?.cancel();
    setState(() => _idRevele = id);
    _minuterieRevelation = Timer(
      ConcentrationTokens.fenetreRevelation,
      () => setState(() => _idRevele = null),
    );
  }

  /// Retire `e` de la grille — **l'écriture D'ABORD, l'animation ENSUITE**.
  ///
  /// 🔴 **L'ORDRE EST LA CLAUSE, et il est vérifiable** *(AC-8, AC-11
  /// « Erreur », ADR-013 §6)* : si l'écriture **échoue**, ⛔ **aucune animation
  /// ne se joue** — elle ferait **paraître** le geste abouti, et la tuile
  /// **RESTE**. **Réfuté par** : une animation qui démarre avant que le résultat
  /// de l'écriture soit connu.
  ///
  /// 🔴 **⛔ AUCUN `await` D'ANIMATION, NULLE PART** *(**C-6**, mutant
  /// **M-14**)* : la fin de l'animation est **signalée** par
  /// [_finDeDisparition], ⛔ jamais attendue. *« Un retrait qui n'aboutirait pas
  /// sans animation serait un retrait perdu »* — et le pire cas est le mode
  /// **« animations réduites »**, où un chemin d'écriture suspendu à l'animation
  /// **perdrait le retrait**.
  Future<void> _retirer(Echeance e) async {
    // ⛔ Un second geste — pendant l'écriture OU pendant l'animation — est
    // REÇU et SANS EFFET : il ⛔ ne retire rien d'autre et ⛔ ne lève rien.
    if (_sortante != null) return;
    final retirer = widget.onRetirer;
    if (retirer == null) return;
    // ⛔ Ce n'est PAS une mise à jour optimiste : la tuile est ENCORE dans
    // `widget.echeances`, donc elle reste rendue à l'identique. Ce champ ne
    // change rien de visible tant que l'écriture n'a pas abouti.
    setState(() => _sortante = e);
    // ⛔ Le contrôleur est RAMENÉ À ZÉRO ICI, ⛔ pas au départ de l'animation :
    // c'est ce qui rend « ⛔ aucune animation ne se joue » OBSERVABLE. Tant
    // qu'il est `dismissed`, [cleDisparition] n'est PAS montée du tout. Sans
    // cette ligne, un SECOND retrait trouverait le contrôleur `completed`
    // (état laissé par le précédent) et monterait l'enveloppe PENDANT
    // l'écriture — donc avant d'en connaître l'issue.
    _disparition.value = 0;

    final refus = await retirer(e.id);
    if (!mounted) return;
    if (refus != null) {
      // ⛔ AUCUNE animation : le geste n'a pas abouti, et la tuile est déjà à
      // sa place dans le tri, avec son nombre et sa couleur. Le message est
      // affiché par le HUB (ADR-014 §B) — ⛔ pas par la grille, qui ne reçoit
      // qu'un rappel (ADR-013 §7).
      setState(() => _sortante = null);
      return;
    }
    // `MediaQuery.disableAnimationsOf` ⇒ DÉPART IMMÉDIAT, et ⛔ l'état écrit
    // est EXACTEMENT le même : l'écriture est déjà faite quand on arrive ici.
    _disparition.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : ConcentrationTokens.dureeDisparition;
    // 🔴 `unawaited` — et ⛔ CE N'EST PAS UN CONTOURNEMENT DE LINT, c'est C-6
    // rendu LISIBLE PAR LE COMPILATEUR, et c'est MESURÉ : sans lui, `flutter
    // analyze` rend `unawaited_futures` sur `forward()` (qui rend un
    // `TickerFuture`) et demande donc **exactement ce qu'AC-8 « Erreur »
    // interdit** — attendre l'animation. ⇒ ici le lint N'EST PAS aveugle
    // (nous sommes dans une fonction `async`), et la seule réponse juste est de
    // déclarer que l'issue de l'animation N'INTÉRESSE PERSONNE : elle est un
    // FEEDBACK, la fin est signalée par [_finDeDisparition].
    unawaited(_disparition.forward(from: 0));
    // ═══════════════════════════════════════════════════════════════════════
    // 🔴 **LE DÉMARRAGE DE L'ANIMATION EST UN CHANGEMENT D'ÉTAT DE LA GRILLE,
    // ET IL DOIT ÊTRE DIT — ⛔ sans cette ligne, l'enveloppe n'est JAMAIS
    // montée par elle-même.** Le défaut a été **MESURÉ**, ⛔ pas supposé :
    // `forward()` fait passer le contrôleur de `dismissed` à `forward`, mais
    // ⛔ **un changement de valeur d'animation ne marque AUCUN élément sale** —
    // et c'est `build` qui décide de monter l'enveloppe. Tant que personne ne
    // reconstruit, elle n'existe pas.
    //
    // ⚠️ **Pourquoi le défaut serait resté invisible** : dans le cas où
    // l'écriture aboutit **en moins d'une frame**, la frame planifiée par le
    // `setState` d'entrée n'a pas encore été rendue et porte l'enveloppe **par
    // accident** ; et en production le rechargement du notifier renotifie
    // **avant** que l'écriture ne rende. ⇒ **deux béquilles fortuites**, l'une
    // et l'autre absentes dès qu'une écriture disque dure plus qu'une frame —
    // c'est-à-dire **le cas normal sur un appareil**. La tuile disparaîtrait
    // alors **sèchement**, AC-8 tomberait, et ⛔ **rien ne lèverait**.
    //
    // ⛔ **`isAnimating`, ⛔ pas `mounted` seul** : en mode « animations
    // réduites » la durée est nulle, `forward` **se termine dans cet appel**,
    // [_finDeDisparition] a **déjà** fait son `setState` — reconstruire ici
    // serait redondant, et surtout cela laisserait croire qu'une animation a
    // eu lieu. **Départ immédiat veut dire ⛔ AUCUNE enveloppe, à aucun
    // instant.**
    // ═══════════════════════════════════════════════════════════════════════
    if (_disparition.isAnimating) setState(() {});
  }

  /// La tuile quitte la grille : **RECOMPOSITION INSTANTANÉE**, ⛔ jamais
  /// animée *(Design UX §3.5 — passer de 5 à 4 tuiles fait passer la grille de
  /// 3 à 2 colonnes, et cette recomposition est **SÈCHE**)*.
  void _finDeDisparition(AnimationStatus statut) {
    if (statut != AnimationStatus.completed) return;
    setState(() => _sortante = null);
  }

  Widget _tuile(Echeance e) {
    // ⛔ Le temps est calculé UNE fois par tuile et par construction : la
    // tuile est une fonction PURE de ses entrées, et c'est ce qui permet à la
    // grille de la reconstruire à chaque tic sans rien lui faire perdre.
    final temps = widget.calculateur.calculer(clock: widget.clock, echeance: e);
    final tuile = EcheanceTile(
      key: ValueKey(e.id),
      temps: temps,
      description: e.description,
      // ⛔ Le nombre revenu à l'expiration est celui du CALCUL COURANT, pas
      // celui de l'instant de l'appui : rien n'est mémorisé, la révélation
      // n'est qu'un aiguillage de RENDU.
      revele: _idRevele == e.id,
      // ⛔ Une ÉCHUE SANS rappel de retrait n'a RIEN à activer : lui donner
      // l'enveloppe sans rappel serait J-1, et lui donner un rappel vide
      // serait la barrière muette (M-15).
      intention: temps.estEchue
          ? (widget.onRetirer == null ? null : () => unawaited(_retirer(e)))
          : () => _reveler(e.id),
    );
    // ⛔ L'enveloppe n'est montée QUE si l'animation a effectivement COMMENCÉ :
    // `dismissed` ⇒ l'écriture est en cours, ou elle a échoué, et il n'y a
    // RIEN à animer.
    if (_sortante?.id != e.id || _disparition.isDismissed) return tuile;

    // ⛔ `FadeTransition` + `ScaleTransition`, ⛔ PAS un `Container` ni une
    // `DecoratedBox` : mesuré (§G-6), seule une boîte porteuse d'une
    // `decoration` insère une SECONDE boîte décorée sous la tuile — ces deux
    // transitions ⛔ ne réveillent PAS `NB-7`.
    // ⛔ AUCUN déplacement, AUCUNE rotation, AUCUN clignotement (RNF-03).
    return FadeTransition(
      key: EcheancesGrid.cleDisparition,
      opacity: Tween<double>(begin: 1, end: 0).animate(_courbe),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 1,
          end: ConcentrationTokens.echelleDisparition,
        ).animate(_courbe),
        child: tuile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibles = [...widget.echeances];
    final sortante = _sortante;
    // 🔴 LA TUILE SORTANTE EST MAINTENUE RENDUE (ADR-013 §1) : l'écriture a
    // abouti, donc elle a déjà quitté la liste — sans cette ligne il n'y aurait
    // RIEN à animer et la disparition serait sèche, quel que soit le mode.
    // ⛔ La condition est nécessaire : pendant l'écriture elle est ENCORE dans
    // la liste, et l'ajouter là ferait DEUX tuiles portant la même clé.
    if (sortante != null && !visibles.any((e) => e.id == sortante.id)) {
      visibles.add(sortante);
    }
    // Le tri utilise le comparateur TOTAL de l'entité : à date égale, départage
    // par id, sans quoi deux tuiles pourraient échanger leur place entre deux
    // rafraîchissements (AC-6 « Erreur »).
    visibles.sort();
    final bornees = visibles
        .take(ConcentrationTokens.tuilesMax)
        .toList(growable: false);

    if (bornees.isEmpty) return const EmptyEcheancesPlaceholder();

    return LayoutBuilder(
      builder: (context, contraintes) {
        // ⛔ AUCUN DÉFILEMENT : AC-3 « Limite » exige que 9 tuiles restent
        // embrassables « d'un regard ». Un GridView défilant ne construisait que
        // 6 tuiles sur 9 dans un écran de test — les 3 dernières exigeaient de
        // faire défiler, ce qui contredit l'AC. Défaut trouvé par T12a.
        //
        // La grille est donc un BLOC CARRÉ centré, dimensionné sur le plus petit
        // côté disponible : les tuiles restent carrées (AC-3 « Nominal ») et
        // toutes visibles, quel que soit le nombre.
        final colonnes = bornees.length <= 4 ? 2 : 3;
        final cote = contraintes.maxWidth < contraintes.maxHeight
            ? contraintes.maxWidth
            : contraintes.maxHeight;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox.square(
              dimension: cote > 24 ? cote - 24 : cote,
              child: GridView.count(
                crossAxisCount: colonnes,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                children: [for (final e in bornees) _tuile(e)],
              ),
            ),
          ),
        );
      },
    );
  }
}
