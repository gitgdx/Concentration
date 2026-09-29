import 'dart:io';

import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/domain/echeance_etat.dart';
import 'package:concentration/features/echeances/domain/remaining_time_calculator.dart';
import 'package:concentration/features/echeances/domain/validation_echeance.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests du prédicat d'état — **T1** *(US-01.4)*.
///
/// 🔴 **Ce que ce fichier doit prouver, et ⛔ ce qu'il ne prouve pas** : T1
/// **ne change AUCUN comportement**. La preuve de non-régression est que la
/// suite existante **reste verte sans être modifiée** — elle n'est donc pas
/// ici. Ce fichier prouve **deux choses de plus, qu'aucun test existant ne
/// voyait** : ⓵ la **borne exacte** du prédicat, ⓶ que la règle vit en **UN
/// SEUL exemplaire** dans `lib/`, ce qui était jusqu'ici un **critère manuel**
/// *(une commande `grep` dans un Story File)* — or *« un critère de sortie se
/// publie comme un script exécutable, jamais recopié à la main »*.
///
/// ⛔ **BORNE DU CONTRÔLE STRUCTUREL, mesurée et NON réparée** : il est
/// **LEXICAL**, indexé sur le jeton `isAfter`. Une copie du prédicat écrite
/// **avec un autre opérateur** — `!instant.isBefore(echeance.dateEcheance)`,
/// mesuré équivalent — lui serait **INVISIBLE**. ⛔ **Élargir au jeton
/// `isBefore` n'est PAS la sortie** : il compte **4 occurrences légitimes** dans
/// `remaining_time_calculator.dart` *(les seuils d'unité de RF-02)*, donc le
/// contrôle rendrait **4 faux positifs** — *« il n'y a pas de troisième voie
/// lexicale »* (`reports/US-00.5/tension_structurelle.md`). Ce qui rend ce
/// contrôle **utile malgré cela**, c'est qu'il **porte ses mutants dans les deux
/// sens** : la copie revenue **le fait rougir**, et la disparition du foyer
/// **fait rougir son contrôle négatif**.
void main() {
  Echeance a(DateTime date) =>
      Echeance(id: 'a1', description: 'Convention', dateEcheance: date);

  final instant = DateTime(2026, 8, 24, 21, 30);

  group('T1 — la BORNE du prédicat, et elle est INCLUSIVE', () {
    test('T == 0 : le terme atteint EST échu', () {
      expect(estEchue(a(instant), instant), isTrue);
    });

    test('T == +1 µs : ⛔ PAS échu — le plus petit écart possible suffit', () {
      expect(
        estEchue(a(instant.add(const Duration(microseconds: 1))), instant),
        isFalse,
        reason:
            'une borne EXCLUSIVE ferait apparaître une échéance « à zéro » qui '
            'ne serait ni active ni échue',
      );
    });

    test('T == −1 µs : échu', () {
      expect(
        estEchue(a(instant.subtract(const Duration(microseconds: 1))), instant),
        isTrue,
      );
    });

    test('⛔ le prédicat ne lit QUE la date — ni la description, ni l’id', () {
      final vide = Echeance(id: 'z', description: '', dateEcheance: instant);
      expect(estEchue(vide, instant), estEchue(a(instant), instant));
    });
  });

  group('T1 — LA MÊME borne pour TOUS les consommateurs', () {
    // 🔴 Ce groupe n'est PAS une tautologie, et c'est le point : il n'assère
    // pas la valeur du prédicat, il assère que **deux sites distincts
    // s'accordent À L'INSTANT EXACT de la borne**. Un mutant qui ré-écrirait
    // une comparaison locale dans l'un des deux (exactement l'état d'avant T1)
    // les ferait DIVERGER ici, et ⛔ nulle part ailleurs : aucun test existant
    // n'exerçait `T == 0` sur les deux à la fois.
    const calculateur = RemainingTimeCalculator();

    test(
      'à T == 0, le calculateur et le refus d’édition disent la MÊME chose',
      () {
        final clock = FakeClock(instant);
        final echue = a(instant);
        expect(
          calculateur.calculer(clock: clock, echeance: echue).estEchue,
          isTrue,
        );
        expect(ValidationEcheance(clock).refusEditionEchue(echue), isNotNull);
        expect(estEchue(echue, clock.now()), isTrue);
      },
    );

    test('à T == +1 µs, les deux disent la MÊME chose — l’autre côté', () {
      final clock = FakeClock(instant);
      final active = a(instant.add(const Duration(microseconds: 1)));
      expect(
        calculateur.calculer(clock: clock, echeance: active).estEchue,
        isFalse,
      );
      expect(ValidationEcheance(clock).refusEditionEchue(active), isNull);
      expect(estEchue(active, clock.now()), isFalse);
    });
  });

  group(
    'T1 — UN SEUL exemplaire dans `lib/`, et le contrôle porte son négatif',
    () {
      // Contrôle STATIQUE sur les sources, sur le patron déjà employé par le
      // scénario « aucune dépendance réseau » de `test/e2e/`. Il remplace le
      // `grep` manuel du Story File par une assertion du gate requis `test`.
      const foyer = 'echeance_etat.dart';
      // ⛔ La 5ᵉ occurrence est désignée PAR SON TEXTE, ⛔ jamais par un numéro de
      // ligne (« un numéro glisse en silence, et la couverture cesse de couvrir
      // sans qu'aucun outil ne le signale » — leçon US-00.7).
      const futurStrictDUneSaisie = 'instant.isAfter(clock.now())';

      List<String> occurrences({required bool dansLeFoyer}) {
        final trouvees = <String>[];
        for (final fichier in Directory('lib').listSync(recursive: true)) {
          if (fichier is! File || !fichier.path.endsWith('.dart')) continue;
          final estLeFoyer = fichier.path.endsWith(foyer);
          if (estLeFoyer != dansLeFoyer) continue;
          for (final ligne in fichier.readAsLinesSync()) {
            final code = ligne.trim();
            if (code.startsWith('///') || code.startsWith('//')) continue;
            if (code.contains('isAfter')) {
              trouvees.add('${fichier.path} :: $code');
            }
          }
        }
        return trouvees;
      }

      test('hors du foyer, il ne reste que le futur strict d’une SAISIE', () {
        final dehors = occurrences(dansLeFoyer: false);
        expect(
          dehors.map((l) => l.contains(futurStrictDUneSaisie)),
          everyElement(isTrue),
          reason:
              'toute comparaison de date résiduelle hors du foyer est une COPIE '
              'du prédicat : $dehors',
        );
        expect(
          dehors,
          hasLength(1),
          reason:
              'la règle du futur strict d’une saisie est une AUTRE règle, et elle '
              'existe elle aussi en un seul exemplaire',
        );
      });

      test('⛔ CONTRÔLE NÉGATIF — le foyer, lui, PORTE la comparaison', () {
        // Sans ce contrôle, le test précédent serait vert si le prédicat était
        // supprimé de `lib/` : « aucune copie » et « aucune règle » lui sont
        // indiscernables.
        expect(occurrences(dansLeFoyer: true), hasLength(1));
      });
    },
  );
}
