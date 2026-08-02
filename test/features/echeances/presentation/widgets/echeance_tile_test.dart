import 'package:concentration/core/color/temporal_gradient.dart';
import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/theme/rgb_extension.dart';
import 'package:concentration/features/echeances/domain/remaining_time.dart';
import 'package:concentration/features/echeances/domain/time_unit.dart';
import 'package:concentration/features/echeances/presentation/widgets/echeance_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/rendu_couleur.dart';

/// Tests du **rendu** de la tuile (T7).
///
/// ⛔ Ce fichier existe parce que la campagne de mutation de la QA du
/// 2026-08-02 a montré que **trois comportements exigés par des AC** pouvaient
/// être retirés de `echeance_tile.dart` sans qu'aucun des 102 tests ne
/// rougisse : le fond cessant de suivre `temps.progression` (`QA-M1`), le
/// `FittedBox` anti-débordement retiré (`QA-M3`), la description jamais rendue
/// (`QA-M4`). Un AC dont le comportement est supprimable sans rougeur n'est pas
/// *couvert* par un test, il en est seulement *accompagné*.
void main() {
  RemainingTime temps(double progression, {int nombre = 6}) => RemainingTime(
    unite: TimeUnit.heures,
    nombreAffiche: nombre,
    progression: progression,
    estEchue: false,
    libelleAccessibilite: '$nombre heures',
  );

  Widget hote(Widget enfant, {double cote = 220}) => MaterialApp(
    theme: ConcentrationTheme.sombre,
    home: Scaffold(
      body: Center(
        child: SizedBox.square(dimension: cote, child: enfant),
      ),
    ),
  );

  Future<Color> fondPour(WidgetTester tester, double progression) async {
    await tester.pumpWidget(
      hote(EcheanceTile(temps: temps(progression), description: 'Rendez-vous')),
    );
    return fondDeLaTuile(tester);
  }

  // ⛔ CINQ points, jamais un seul. Tant que seul `p = 0` était vérifié sur le
  // rendu, la tuile pouvait ignorer ENTIÈREMENT `temps.progression` : forcée en
  // bleu elle faisait rougir un test, forcée en orange elle n'en faisait rougir
  // AUCUN. Cette asymétrie était le résultat le plus net de la QA — or « la
  // couleur reflète la proximité du prochain changement » EST AC-5.
  const points = <double>[0, 0.25, 0.5, 0.75, 1];

  group('AC-5 — le fond de la tuile est CÂBLÉ sur temps.progression', () {
    testWidgets('chaque progression rend le dégradé À CE POINT', (
      tester,
    ) async {
      const gradient = TemporalGradient();
      for (final p in points) {
        expect(
          await fondPour(tester, p),
          gradient.backgroundFor(p).couleur,
          reason:
              'à p = $p la tuile doit rendre le dégradé EN p, jamais une '
              'couleur figée',
        );
      }
    });

    testWidgets('la clarté DÉCROÎT strictement quand p augmente', (
      tester,
    ) async {
      // Propriété indépendante de l'implémentation du dégradé : quelle que soit
      // la façon dont la couleur est produite, s'approcher du changement doit
      // FAIRE BOUGER le rendu, toujours dans le même sens (ADR-003, « sens non
      // inversé »). Un fond constant échoue ici même s'il est « la bonne
      // couleur » en un point.
      final clartes = [
        for (final p in points) clarteDe(await fondPour(tester, p)),
      ];
      for (var i = 1; i < clartes.length; i++) {
        expect(
          clartes[i],
          lessThan(clartes[i - 1]),
          reason:
              'de p=${points[i - 1]} à p=${points[i]} le rendu doit avancer '
              'vers le bleu — clartés mesurées : $clartes',
        );
      }
    });
  });

  testWidgets(
    'AC-3 « Nominal » — la tuile PORTE la description de son échéance',
    (tester) async {
      await tester.pumpWidget(
        hote(EcheanceTile(temps: temps(0.5), description: 'Visite médicale')),
      );
      expect(
        find.descendant(
          of: find.byType(EcheanceTile),
          matching: find.text('Visite médicale'),
        ),
        findsOneWidget,
        reason:
            'le corpus vérifiait le cas VIDE et jamais le cas peuplé : la '
            'description était supprimable sans faire rougir un test',
      );
    },
  );

  testWidgets(
    'AC-3 « Limite » — un nombre trop large est MIS À L’ÉCHELLE, jamais rogné',
    (tester) async {
      // 90 px : la largeur réelle d'une tuile quand 9 tuiles tiennent sur un
      // écran de 320. Le défaut d'origine — le nombre débordait à 9 tuiles — a
      // été trouvé en LANÇANT l'application, jamais par un test ; son correctif
      // (`FittedBox(scaleDown)`) n'était toujours adossé à aucune assertion.
      const cote = 90.0;
      const nombre = 108;
      final texte = '$nombre';

      await tester.pumpWidget(
        hote(
          EcheanceTile(
            temps: temps(0.5, nombre: nombre),
            description: 'Passeport',
          ),
          cote: cote,
        ),
      );

      // ⚠️ La largeur naturelle est LUE SUR LE PARAGRAPHE LUI-MÊME, jamais
      // reconstruite à côté : un `TextPainter` monté dans le test rendait
      // 144,75 px là où le paragraphe rendait 144,0 — deux mesures de la « même »
      // grandeur qui divergent, exactement la classe de défaut que ce projet
      // traque. `getMaxIntrinsicWidth` est la largeur que le texte DEMANDE, elle
      // ne dépend pas des contraintes reçues.
      final paragraphe = tester.renderObject<RenderBox>(find.text(texte));
      final naturelle = paragraphe.getMaxIntrinsicWidth(double.infinity);

      // ⛔ Garde-fou : sans lui, ce test cesserait de contrôler EN SILENCE le
      // jour où le nombre choisi tiendrait naturellement dans la tuile.
      expect(
        naturelle,
        greaterThan(cote),
        reason:
            'le cas doit être un VRAI débordement ($naturelle px de nombre '
            'pour $cote px de tuile), sinon il ne prouve rien',
      );

      // 1) La boîte du nombre vaut la largeur qu'il DEMANDE : rien n'est rogné.
      expect(
        paragraphe.size.width,
        closeTo(naturelle, 0.5),
        reason:
            'un nombre posé à une largeur CONTRAINTE est un nombre COUPÉ ; il '
            'doit être posé à sa taille naturelle puis réduit',
      );

      // 2) ...et le résultat PEINT tient entièrement dans la tuile.
      final nombreRect = tester.getRect(find.text(texte));
      final tuileRect = tester.getRect(find.byType(EcheanceTile));
      expect(nombreRect.left, greaterThanOrEqualTo(tuileRect.left - 0.5));
      expect(nombreRect.right, lessThanOrEqualTo(tuileRect.right + 0.5));
      expect(nombreRect.top, greaterThanOrEqualTo(tuileRect.top - 0.5));
      expect(nombreRect.bottom, lessThanOrEqualTo(tuileRect.bottom + 0.5));
      expect(tester.takeException(), isNull);
    },
  );
}
