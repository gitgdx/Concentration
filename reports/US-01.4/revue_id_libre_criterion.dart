// ignore_for_file: avoid_print
//
// ⛔ `print` est VOULU : ce fichier est un CRITÈRE DE REVUE, sa valeur est la
// sortie qu'il imprime. Sans cette directive le gate requis `flutter analyze`
// rougit. ⚠️ Vérifié APRÈS écriture : `run_gates --gate analyze` rend
// `No issues found!`.
/// CRITÈRE DE REVUE EXÉCUTABLE — audit @CodeReviewer d'US-01.4, SHA `8509f44`.
///
/// 🔴 **QUESTION MESURÉE** : `ValidationEcheance._idLibre(presentes)` cherche
/// un `id` libre **dans la liste qu'on lui passe**. Jusqu'à T5 c'était
/// `_echeances` *(la liste COMPLÈTE)* ; depuis T5 c'est `presentes`, dont
/// `presentesSurLaGrille` **EXCLUT les retirées** *(C-7)*. **Un `id` déjà porté
/// par une échéance RETIRÉE est donc vu comme LIBRE.** Que devient l'entrée
/// retirée quand l'écriture, elle, porte sur la liste **DU DOCUMENT** ?
///
/// ⛔ **Ce fichier ne modifie AUCUNE ligne de `lib/`** : il exerce le code de
/// production tel qu'il est, à travers le **magasin fichier réel**.
///
/// 🔴 **IL PORTE SON CONTRÔLE NÉGATIF** *(règle du projet : un contrôle qui ne
/// peut pas rougir est nul)* : le **même** scénario **SANS le retrait** doit
/// rendre le verdict **INVERSE** — deux entrées, deux `id` distincts. Sans lui,
/// un magasin qui perdrait TOUJOURS une entrée rendrait le 1ᵉʳ cas « vert »
/// pour une mauvaise raison.
///
/// 🔴 **ET IL MESURE SON ATTEIGNABILITÉ** — ⛔ elle ne s'affirme pas : la
/// granularité observée de `DateTime.now()` et la durée réelle de
/// `créer → retirer → créer` sont **LUES**, jamais estimées. C'est ce couple de
/// nombres, et lui seul, qui dit si le défaut est atteignable par l'IHM.
///
/// Lancement :
///   flutter test reports/US-01.4/revue_id_libre_criterion.dart
/// (⛔ il n'est PAS sous `test/` : il ne doit pas entrer dans le gate `test`.)
library;

import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/echeance_document_repository.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/presentation/echeances_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/support/magasin_temporaire.dart';

/// Horloge **FIGÉE** — elle ne simule rien du produit : elle rend seulement
/// **observable** la collision que la granularité de l'horloge réelle rend
/// rare. ⛔ Ce n'est pas un mock du dépôt (ADR-010 §1) : le magasin, le codec et
/// le dépôt sont ceux de la PRODUCTION.
class _HorlogeFigee implements Clock {
  _HorlogeFigee(this._t);
  final DateTime _t;
  @override
  DateTime now() => _t;
}

Future<EcheancesNotifier> _notifier(WidgetTester tester, Clock horloge) async {
  final harnais = MagasinTemporaire.creer();
  final notifier = EcheancesNotifier(
    depot: EcheanceDocumentRepository(harnais.magasin),
    clock: horloge,
  );
  await tester.runAsync(notifier.charger);
  return notifier;
}

void main() {
  testWidgets('A1 — COLLISION avec une RETIRÉE : l’entrée retirée DISPARAÎT', (
    tester,
  ) async {
    final notifier = await _notifier(
      tester,
      _HorlogeFigee(DateTime(2026, 9, 11, 10)),
    );
    await tester.runAsync(
      () => notifier.creer(
        description: 'la premiere',
        date: '15/03/2027',
        heure: '23:59',
      ),
    );
    final idPremiere = notifier.echeances.single.id;
    await tester.runAsync(() => notifier.retirer(idPremiere));
    await tester.runAsync(
      () => notifier.creer(
        description: 'la seconde',
        date: '20/06/2027',
        heure: '12:00',
      ),
    );
    print('A1| entrees apres = ${notifier.echeances.length}');
    for (final Echeance e in notifier.echeances) {
      print('A1|   id=${e.id} desc="${e.description}" retiree=${e.retiree}');
    }
    // ⚠️ L'assertion dit le DÉFAUT MESURÉ, ⛔ pas le comportement souhaité :
    // ce critère rougira le jour où le défaut sera corrigé — c'est voulu, il
    // est le témoin du défaut, pas sa spécification.
    expect(
      notifier.echeances,
      hasLength(1),
      reason: 'DÉFAUT : la retirée a été ÉCRASÉE par la nouvelle échéance',
    );
    expect(notifier.echeances.single.description, 'la seconde');
    expect(notifier.echeances.single.retiree, isFalse);
  });

  testWidgets('A2 — CONTRÔLE NÉGATIF : sans retrait, AUCUNE perte', (
    tester,
  ) async {
    final notifier = await _notifier(
      tester,
      _HorlogeFigee(DateTime(2026, 9, 11, 10)),
    );
    await tester.runAsync(
      () => notifier.creer(
        description: 'la premiere',
        date: '15/03/2027',
        heure: '23:59',
      ),
    );
    // ⛔ AUCUN retrait ici — c'est la SEULE différence avec A1.
    await tester.runAsync(
      () => notifier.creer(
        description: 'la seconde',
        date: '20/06/2027',
        heure: '12:00',
      ),
    );
    print('A2| entrees apres = ${notifier.echeances.length}');
    for (final Echeance e in notifier.echeances) {
      print('A2|   id=${e.id} desc="${e.description}"');
    }
    expect(
      notifier.echeances,
      hasLength(2),
      reason: 'la boucle de _idLibre a bien depareille les id',
    );
    expect(notifier.echeances.map((e) => e.id).toSet(), hasLength(2));
  });

  testWidgets('A3 — ATTEIGNABILITÉ : les deux nombres se LISENT', (
    tester,
  ) async {
    var repetitions = 0;
    var precedent = DateTime.now().microsecondsSinceEpoch;
    final ecarts = <int>[];
    for (var i = 0; i < 200000; i++) {
      final t = DateTime.now().microsecondsSinceEpoch;
      if (t == precedent) {
        repetitions++;
      } else {
        ecarts.add(t - precedent);
        precedent = t;
      }
    }
    ecarts.sort();
    print('A3| repetitions de microsecondsSinceEpoch = $repetitions / 200000');
    print('A3| plus petit ecart NON NUL (us)          = ${ecarts.first}');

    final notifier = await _notifier(tester, const SystemClock());
    final t0 = DateTime.now();
    await tester.runAsync(
      () => notifier.creer(
        description: 'a',
        date: '15/03/2027',
        heure: '23:59',
      ),
    );
    final idA = notifier.echeances.single.id;
    await tester.runAsync(() => notifier.retirer(idA));
    await tester.runAsync(
      () => notifier.creer(
        description: 'b',
        date: '20/06/2027',
        heure: '12:00',
      ),
    );
    final ecoule = DateTime.now().difference(t0).inMicroseconds;
    print('A3| duree creer->retirer->creer (us)       = $ecoule');
    print('A3| entrees = ${notifier.echeances.length}, '
        'id distincts = ${notifier.echeances.map((e) => e.id).toSet().length}');
    // ⛔ AUCUNE perte sur le chemin RÉEL : c'est la mesure qui rend ce défaut
    // NON BLOQUANT, ⛔ pas une opinion.
    expect(notifier.echeances, hasLength(2));
    expect(notifier.echeances.map((e) => e.id).toSet(), hasLength(2));
  });
}
