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
    super.dispose();
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
                children: [
                  for (final e in bornees)
                    EcheanceTile(
                      key: ValueKey(e.id),
                      description: e.description,
                      temps: widget.calculateur.calculer(
                        clock: widget.clock,
                        echeance: e,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
