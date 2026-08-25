import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/concentration_tokens.dart';
import '../../../core/time/clock.dart';
import '../domain/echeance.dart';
import '../domain/remaining_time_calculator.dart';
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
    super.key,
    this.calculateur = const RemainingTimeCalculator(),
  });

  final List<Echeance> echeances;
  final Clock clock;
  final RemainingTimeCalculator calculateur;

  @override
  State<EcheancesGrid> createState() => _EcheancesGridState();
}

class _EcheancesGridState extends State<EcheancesGrid> {
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

  @override
  void initState() {
    super.initState();
    _minuterie = Timer.periodic(
      ConcentrationTokens.periodeRafraichissement,
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    _minuterieRevelation?.cancel();
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

  Widget _tuile(Echeance e) {
    // ⛔ Le temps est calculé UNE fois par tuile et par construction : la
    // tuile est une fonction PURE de ses entrées, et c'est ce qui permet à la
    // grille de la reconstruire à chaque tic sans rien lui faire perdre.
    final temps = widget.calculateur.calculer(clock: widget.clock, echeance: e);
    return EcheanceTile(
      key: ValueKey(e.id),
      temps: temps,
      description: e.description,
      // ⛔ Le nombre revenu à l'expiration est celui du CALCUL COURANT, pas
      // celui de l'instant de l'appui : rien n'est mémorisé, la révélation
      // n'est qu'un aiguillage de RENDU.
      revele: _idRevele == e.id,
      // ⛔ Une ÉCHUE n'a RIEN à activer à ce commit : son intention est le
      // RETRAIT, qui n'existe pas encore (le rappel arrive avec T10/T19).
      // Lui donner l'enveloppe sans rappel serait exactement J-1, et lui
      // donner un rappel vide serait la barrière muette (M-15).
      intention: temps.estEchue ? null : () => _reveler(e.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Le tri utilise le comparateur TOTAL de l'entité : à date égale, départage
    // par id, sans quoi deux tuiles pourraient échanger leur place entre deux
    // rafraîchissements (AC-6 « Erreur »).
    final visibles = [...widget.echeances]..sort();
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
