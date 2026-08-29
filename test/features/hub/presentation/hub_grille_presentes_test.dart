import 'package:concentration/core/theme/concentration_theme.dart';
import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/echeance_document_repository.dart';
import 'package:concentration/features/echeances/data/echeance_schema_migrations.dart';
import 'package:concentration/features/echeances/presentation/echeances_notifier.dart';
import 'package:concentration/features/echeances/presentation/widgets/echeance_tile.dart';
import 'package:concentration/features/hub/presentation/hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/magasin_temporaire.dart';

/// **T4 — la GRILLE consomme `presentes`, et ⛔ pas `echeances`** *(C-7)*.
///
/// 🔴 **CE FICHIER EXISTE PARCE QU'UN MUTANT A SURVÉCU, et c'est MESURÉ.**
/// Après le commit de T4, remplacer `notifier.presentes` par
/// `notifier.echeances` dans `hub_page.dart` laissait **les 431 tests VERTS**.
/// Le câblage était juste et ⛔ **rien n'aurait signalé sa régression** : aucun
/// test ne posait d'échéance **retirée** sur le hub, parce que le geste de
/// retrait n'existe pas encore *(il arrive en T8)*.
///
/// ⇒ **c'est l'inverse d'une « clause sans surface » : une surface sans
/// clause.** Le remède est ici, et il ⛔ **n'attend PAS le geste** : l'état
/// `ÉCHUE RETIRÉE` est **déjà atteignable par le chemin de CHARGEMENT**, qui
/// est du code de production.
///
/// ⛔ **Aucun magasin factice** : le document est posé sur le **disque réel** et
/// relu par `EcheanceDocumentRepository`.
void main() {
  final maintenant = DateTime(2026, 8, 24, 12);
  late MagasinTemporaire harnais;

  setUp(() => harnais = MagasinTemporaire.creer());
  tearDown(() => harnais.nettoyer());

  /// Un document **à la version courante** portant **une entrée retirée** et
  /// deux entrées présentes. ⛔ La version se **LIT**.
  String documentAvecUneRetiree() =>
      '{"schemaVersion":$versionCourante,"echeances":['
      '{"id":"p1","description":"Presente une","dateEcheance":"2027-03-15T23:59"},'
      '{"id":"r1","description":"Retiree de la grille","dateEcheance":"2026-01-09T23:59",'
      '"retiree":true},'
      '{"id":"p2","description":"Presente deux","dateEcheance":"2027-06-02T09:00"}]}';

  Future<EcheancesNotifier> monter(WidgetTester tester) async {
    harnais.poser(documentAvecUneRetiree());
    final notifier = EcheancesNotifier(
      depot: EcheanceDocumentRepository(harnais.magasin),
      clock: FakeClock(maintenant),
    );
    await tester.runAsync(notifier.charger);
    await tester.pumpWidget(
      MaterialApp(
        theme: ConcentrationTheme.sombre,
        home: HubPage(notifier: notifier, clock: FakeClock(maintenant)),
      ),
    );
    await tester.pump();
    return notifier;
  }

  /// ⚖️ **T13 — LE CANAL A CHANGÉ, ⛔ PAS LA CLAUSE.** Une tuile `ACTIVE` ne
  /// PEINT plus sa description au repos : les contrôles de ce fichier lisent
  /// donc le **libellé d'accessibilité**, qui la porte toujours.
  /// ⛔ **PAS `.first`** : `FocusableActionDetector` insère son propre
  /// `Semantics` **sans libellé** (mesuré à T8).
  List<String> libellesDesTuiles(WidgetTester tester) => tester
      .widgetList<Semantics>(find.byType(Semantics))
      .map((w) => w.properties.label)
      .whereType<String>()
      .toList();

  testWidgets('🔴 une échéance RETIRÉE n’a AUCUNE tuile sur la grille du hub', (
    tester,
  ) async {
    final notifier = await monter(tester);

    // ⛔ CONTRÔLE POSITIF D'ABORD : sans lui, « la tuile est absente » serait
    // vrai sur un hub vide, et le test ne mesurerait rien.
    expect(
      notifier.echeances,
      hasLength(3),
      reason: 'les TROIS échéances sont bien chargées depuis le disque',
    );
    final libelles = libellesDesTuiles(tester).join(' | ');
    expect(libelles, contains('Presente une'));
    expect(libelles, contains('Presente deux'));

    // 🔴 LE MUTANT QUE CETTE ASSERTION TUE : `notifier.echeances` à la place
    // de `notifier.presentes` dans `hub_page.dart`. Il a SURVÉCU aux 431
    // tests antérieurs.
    expect(
      find.byType(EcheanceTile),
      findsNWidgets(2),
      reason: '⛔ 3 tuiles ⇒ la grille lit la liste NON filtrée',
    );
    // ⛔ **SUR LES DEUX CANAUX**, et c'est T13 qui l'impose : depuis qu'une
    // `ACTIVE` ne peint plus sa description, l'assertion visuelle seule serait
    // vraie **par accident** et ne tuerait plus le mutant qu'elle vise.
    expect(
      find.text('Retiree de la grille'),
      findsNothing,
      reason: 'la description de la retirée n’est PEINTE nulle part',
    );
    expect(
      libelles,
      isNot(contains('Retiree de la grille')),
      reason: 'et elle n’est ANNONCÉE nulle part non plus',
    );
  });

  testWidgets(
    '⛔ l’échéance retirée est CONSERVÉE — ce n’est pas une suppression',
    (tester) async {
      final notifier = await monter(tester);
      // La donnée est intacte sur le disque ET dans la liste complète, que la
      // page de GESTION consomme (AC-7). ⛔ « Absente de la grille » ⇒ jamais
      // « effacée ».
      expect(harnais.octets(), contains('Retiree de la grille'));
      expect(harnais.octets(), contains('"retiree":true'));
      expect(
        notifier.echeances.where((e) => e.retiree).map((e) => e.id),
        <String>['r1'],
      );
      expect(notifier.presentes.map((e) => e.id), <String>['p1', 'p2']);
    },
  );
}
