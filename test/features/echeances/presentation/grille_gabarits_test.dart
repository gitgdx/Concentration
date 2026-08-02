import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/presentation/echeances_grid.dart';
import 'package:concentration/features/echeances/presentation/widgets/echeance_tile.dart';
import 'package:concentration/features/hub/presentation/hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La grille sur PLUSIEURS GABARITS — le trou que l'application tournant a
/// révélé.
///
/// ⚠️ Tous les autres tests de widgets utilisent le gabarit **par défaut de
/// `flutter_test`, 800×600**. Ils passaient donc tous alors que, lancée sur un
/// **format téléphone**, la grille **débordait horizontalement** : la 3ᵉ colonne
/// était coupée. **Un test qui ne s'exécute qu'à une seule taille ne dit rien du
/// responsive.**
void main() {
  final maintenant = DateTime(2026, 8, 1, 12);

  List<Echeance> neuf() => [
    for (var i = 0; i < 9; i++)
      Echeance(
        id: 'e$i',
        description: 'Échéance $i',
        dateEcheance: maintenant.add(Duration(days: i + 1)),
      ),
  ];

  Future<void> monterA(
    WidgetTester tester,
    Size taille, {
    bool hub = true,
  }) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ConcentrationTheme.sombre,
        home: hub
            ? HubPage(echeances: neuf(), clock: FakeClock(maintenant))
            : Scaffold(
                body: EcheancesGrid(
                  echeances: neuf(),
                  clock: FakeClock(maintenant),
                ),
              ),
      ),
    );
    await tester.pump();
  }

  /// Gabarits éprouvés : téléphone étroit, téléphone courant, tablette, bureau.
  const gabarits = <String, Size>{
    'téléphone étroit 320x568': Size(320, 568),
    'téléphone courant 390x844': Size(390, 844),
    'tablette 768x1024': Size(768, 1024),
    'bureau 1280x800': Size(1280, 800),
    'bureau large 1920x1080': Size(1920, 1080),
  };

  gabarits.forEach((nom, taille) {
    testWidgets('$nom — les 9 tuiles tiennent SANS débordement', (
      tester,
    ) async {
      await monterA(tester, taille);

      expect(
        find.byType(EcheanceTile),
        findsNWidgets(9),
        reason: 'les 9 tuiles doivent exister',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'aucun débordement de mise en page',
      );

      // ⛔ L'assertion décisive : CHAQUE tuile doit être ENTIÈREMENT dans l'écran.
      // C'est ce qui manquait — « la tuile existe » ne veut pas dire « on la voit ».
      for (final element in find.byType(EcheanceTile).evaluate()) {
        final boite = tester.getRect(find.byWidget(element.widget));
        expect(
          boite.left,
          greaterThanOrEqualTo(-0.5),
          reason: 'tuile coupée à gauche : $boite',
        );
        expect(
          boite.right,
          lessThanOrEqualTo(taille.width + 0.5),
          reason:
              'tuile coupée à DROITE : $boite (écran ${taille.width} de large)',
        );
        expect(
          boite.top,
          greaterThanOrEqualTo(-0.5),
          reason: 'tuile coupée en haut : $boite',
        );
        expect(
          boite.bottom,
          lessThanOrEqualTo(taille.height + 0.5),
          reason:
              'tuile coupée en BAS : $boite (écran ${taille.height} de haut)',
        );
      }
    });

    testWidgets('$nom — les tuiles restent CARRÉES (AC-3 « Nominal »)', (
      tester,
    ) async {
      await monterA(tester, taille);
      final boite = tester.getRect(find.byType(EcheanceTile).first);
      expect(
        boite.width,
        closeTo(boite.height, 1.0),
        reason: 'tuile non carrée : ${boite.width} × ${boite.height}',
      );
    });
  });
}
