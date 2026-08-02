import 'package:concentration/features/echeances/domain/echeance.dart';
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
