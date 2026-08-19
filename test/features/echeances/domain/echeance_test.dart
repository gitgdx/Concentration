import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/domain/echeance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de l'entité et de son ordre (T2 / `MODELE_ECHEANCE.md`).
void main() {
  Echeance e(String id, DateTime date, [String description = 'x']) =>
      Echeance(id: id, description: description, dateEcheance: date);

  group('I-1 — immuabilité et égalité par valeur', () {
    test('deux instances de mêmes valeurs sont égales', () {
      expect(e('a', DateTime(2026)), e('a', DateTime(2026)));
      expect(e('a', DateTime(2026)).hashCode, e('a', DateTime(2026)).hashCode);
    });

    test('une valeur différente rompt l’égalité', () {
      expect(e('a', DateTime(2026)), isNot(e('b', DateTime(2026))));
      expect(e('a', DateTime(2026)), isNot(e('a', DateTime(2027))));
      expect(e('a', DateTime(2026), 'x'), isNot(e('a', DateTime(2026), 'y')));
    });
  });

  group('I-2 / I-3 / I-4 — les INTERDITS d’invariant', () {
    test('I-2 : un id vide est refusé', () {
      expect(() => e('', DateTime(2026)), throwsA(isA<AssertionError>()));
    });

    test(
      'I-3 : une description VIDE est acceptée — ce n’est pas une erreur',
      () {
        expect(e('a', DateTime(2026), '').description, '');
      },
    );

    test('I-4 : une date PASSÉE est acceptée — état normal (AC-7)', () {
      expect(e('a', DateTime(1999)).dateEcheance.year, 1999);
    });
  });

  group('I-6 — une donnée illisible est IGNORÉE, jamais fatale', () {
    test('rend null sans lever', () {
      expect(Echeance.depuisDonnee(null), isNull);
      expect(Echeance.depuisDonnee('pas une map'), isNull);
      expect(
        Echeance.depuisDonnee({'id': 'a'}),
        isNull,
        reason: 'date manquante',
      );
      expect(
        Echeance.depuisDonnee({'id': '', 'dateEcheance': DateTime(2026)}),
        isNull,
        reason:
            'NB-1 : le refus d’un id vide doit être du CODE EXÉCUTÉ — '
            'l’assert du constructeur est retiré en release',
      );
      expect(
        Echeance.depuisDonnee({'id': 42, 'dateEcheance': DateTime(2026)}),
        isNull,
      );
      expect(
        Echeance.depuisDonnee({'id': 'a', 'dateEcheance': 'demain'}),
        isNull,
      );
    });

    test('une description absente devient une chaîne vide, pas un rejet', () {
      final lu = Echeance.depuisDonnee({
        'id': 'a',
        'dateEcheance': DateTime(2026),
      });
      expect(lu, isNotNull);
      expect(lu!.description, '');
    });
  });

  group('NB-1 — la BARRIÈRE est du code exécuté, pas l’assert (T2)', () {
    // 🔴 Réfutation exigée par T2 : ce test doit ÉCHOUER si `depuisDonnee`
    // acceptait un `id` vide EN MODE RELEASE. On ne peut pas exécuter la suite
    // en release ici ; ce qui est éprouvé, c'est que le refus ne dépend PAS de
    // l'assert — il est prononcé par une instruction `return null` que le
    // compilateur conserve. Le mutant qui le tue : retirer la clause
    // `id.isEmpty` de `depuisDonnee` (l'assert, lui, ne serait plus atteint,
    // puisque `depuisDonnee` n'appellerait le constructeur qu'après).
    test(
      'un id vide est refusé SANS qu’aucune AssertionError ne soit levée',
      () {
        Object? capture;
        try {
          capture = Echeance.depuisDonnee({
            'id': '',
            'dateEcheance': DateTime(2026),
          });
        } on Object catch (erreur) {
          fail('depuisDonnee a LEVÉ ($erreur) là où I-6 exige un null');
        }
        expect(capture, isNull);
      },
    );

    test('un id NON VIDE passe la même frontière — contrôle négatif', () {
      // ⛔ Sans lui, un `depuisDonnee` qui rendrait TOUJOURS null passerait
      // pour un validateur exemplaire.
      expect(
        Echeance.depuisDonnee({'id': 'a', 'dateEcheance': DateTime(2026)}),
        isNotNull,
      );
    });
  });

  group('avec() — recopie modifiée, id CONSERVÉ (AC-6, T2)', () {
    final base = e('id-stable', DateTime(2026, 5, 5), 'Convention');

    test('la description change, l’id et la date NE CHANGENT PAS', () {
      final modifiee = base.avec(description: 'Convention annuelle');
      expect(modifiee.id, 'id-stable');
      expect(modifiee.description, 'Convention annuelle');
      expect(modifiee.dateEcheance, DateTime(2026, 5, 5));
    });

    test('la date change, l’id et la description NE CHANGENT PAS', () {
      final modifiee = base.avec(dateEcheance: DateTime(2027, 1, 2));
      expect(modifiee.id, 'id-stable');
      expect(modifiee.description, 'Convention');
      expect(modifiee.dateEcheance, DateTime(2027, 1, 2));
    });

    test('sans argument, la recopie est ÉGALE PAR VALEUR à l’originale', () {
      expect(base.avec(), base);
    });

    test('une description VIDE est une valeur, pas une omission (I-3)', () {
      // ⚠️ Assertion de GRANDEUR, pas une égalité au token : si `avec` traitait
      // `''` comme « inchangé » (par un `?.isEmpty` de trop), l'édition ne
      // pourrait JAMAIS vider une description — et le test ci-dessus, lui,
      // resterait vert.
      expect(base.avec(description: '').description, isEmpty);
      expect(base.avec(description: '').id, 'id-stable');
    });
  });

  group('ResultatEcriture — refus TYPÉ du port, jamais void (U-6 ①)', () {
    test('une réussite ne porte AUCUN message', () {
      const resultat = ResultatEcriture.reussie();
      expect(resultat.estReussi, isTrue);
      expect(resultat.message, isNull);
    });

    test('un échec porte le message de SON acte, et ils DIFFÈRENT', () {
      const enregistrement = ResultatEcriture.echec(
        ActeEcriture.enregistrement,
      );
      const suppression = ResultatEcriture.echec(ActeEcriture.suppression);
      expect(enregistrement.estReussi, isFalse);
      expect(suppression.estReussi, isFalse);
      // 🔴 Design UX §14.5 : DEUX textes, pas un. Un message générique unique
      // satisferait la lettre et raterait l'objet.
      expect(
        enregistrement.message,
        isNot(suppression.message),
        reason: 'l’utilisateur doit savoir CE QUI n’a pas eu lieu',
      );
    });

    test('aucun message ne porte de trace technique (AC-17 « Nominal »)', () {
      // ⛔ Une assertion doit ÉCHOUER si un libellé d'exception, un chemin ou un
      // code d'erreur entrait dans ces textes.
      const interdits = [
        'Exception',
        'Error',
        'null',
        '.json',
        '/',
        r'\',
        'code',
        'réessai',
        'brouillon',
      ];
      for (final acte in ActeEcriture.values) {
        expect(acte.messageEchec, isNotEmpty);
        for (final interdit in interdits) {
          expect(
            acte.messageEchec.toLowerCase(),
            isNot(contains(interdit.toLowerCase())),
            reason: '« ${acte.messageEchec} » ne doit pas porter « $interdit »',
          );
        }
      }
    });
  });

  group('ordre — comparateur TOTAL (AC-6)', () {
    test('tri par date croissante : la plus proche en premier', () {
      final liste = [
        e('c', DateTime(2026, 3, 1)),
        e('a', DateTime(2026, 1, 1)),
        e('b', DateTime(2026, 2, 1)),
      ]..sort();
      expect(liste.map((x) => x.id).toList(), ['a', 'b', 'c']);
    });

    test('une échéance DÉPASSÉE remonte en tête (clarify nº 2)', () {
      final liste = [
        e('futur', DateTime(2030)),
        e('echue', DateTime(2020)),
        e('proche', DateTime(2027)),
      ]..sort();
      expect(liste.first.id, 'echue');
    });

    test('ex æquo : départage par id, donc ordre DÉTERMINISTE', () {
      final date = DateTime(2026, 5, 5);
      final ordre1 = [e('zz', date), e('aa', date)]..sort();
      final ordre2 = [e('aa', date), e('zz', date)]..sort();
      expect(ordre1.map((x) => x.id).toList(), ['aa', 'zz']);
      expect(
        ordre2.map((x) => x.id).toList(),
        ordre1.map((x) => x.id).toList(),
        reason: 'deux tuiles ex æquo ne doivent JAMAIS échanger leur place',
      );
    });

    test(
      'le comparateur est total : jamais 0 pour deux échéances distinctes',
      () {
        final date = DateTime(2026, 5, 5);
        expect(e('aa', date).compareTo(e('zz', date)), isNot(0));
      },
    );
  });
}
