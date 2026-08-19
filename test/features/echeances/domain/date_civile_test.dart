import 'package:concentration/features/echeances/domain/date_civile.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le prédicat de forme canonique (T3, règle **V-1/V-2**).
///
/// ⚠️ **Ce fichier ne teste PAS une bascule d'heure d'été** — borne **NM-9** :
/// le fuseau du processus Dart est **lu au démarrage** et n'est **pas pilotable**
/// depuis un test, et un hôte sous `TZ=UTC` **n'a aucune transition**, donc un
/// tel test y serait **vrai quoi qu'il arrive**. Ce serait l'un des **2 faux
/// verts d'US-01.1**, refait à l'identique. Ce qui est éprouvé à la place : le
/// **même prédicat**, sur la **date hors calendrier**, reproductible **sous tout
/// fuseau**.
void main() {
  group('texteCivil — le candidat NE PASSE JAMAIS par un DateTime', () {
    test('les composantes sont écrites telles quelles, zéros compris', () {
      expect(texteCivil(2026, 11, 15, 23, 59), '2026-11-15T23:59');
      expect(texteCivil(2026, 1, 2, 3, 4), '2026-01-02T03:04');
    });

    test(
      '🔴 une date HORS CALENDRIER survit au formatage — c’est tout l’objet',
      () {
        // ⛔ La mesure qui fonde ce module : `DateTime(2027, 2, 31)` rend le
        // 3 mars. Si `texteCivil` passait par un DateTime, le 31 février
        // n'existerait déjà plus ici et le refus d'AC-16 serait impossible.
        expect(texteCivil(2027, 2, 31, 23, 59), '2027-02-31T23:59');
        expect(DateTime(2027, 2, 31).day, isNot(31));
      },
    );
  });

  group('litDateCivile — LA barrière (règle V-1)', () {
    test(
      'une date-heure civile réelle est acceptée et relue à l’identique',
      () {
        final lu = litDateCivile('2026-11-15T23:59');
        expect(lu, isNotNull);
        expect(formatCivil(lu!), '2026-11-15T23:59');
        expect(lu.isUtc, isFalse);
      },
    );

    test('🔴 le 31 février est REFUSÉ — sans exception, par la FORME', () {
      // ⛔ `DateTime.parse` NE LÈVE PAS : il rend une autre date, en silence.
      // C'est la comparaison à la forme canonique qui refuse, et elle seule.
      expect(
        () => DateTime.parse('2027-02-31T23:59'),
        returnsNormally,
        reason: 'une exception n’est PAS la barrière — mesure du 2026-08-06',
      );
      expect(litDateCivile('2027-02-31T23:59'), isNull);
    });

    test('le 28 février est ACCEPTÉ — contrôle négatif de la borne', () {
      // ⛔ Sans ce côté-ci, un prédicat qui refuserait TOUT passerait pour un
      // validateur exemplaire.
      expect(litDateCivile('2027-02-28T23:59'), isNotNull);
    });

    test('une marque de temps universel est refusée', () {
      expect(litDateCivile('2026-11-15T23:59:00Z'), isNull);
    });

    test('une date SANS heure est refusée (forme non canonique)', () {
      expect(litDateCivile('2026-11-15'), isNull);
    });

    test('des secondes rendent la forme non canonique', () {
      expect(litDateCivile('2026-11-15T23:59:30'), isNull);
    });

    test('un texte qui n’est pas une date rend null, il ne LÈVE pas', () {
      expect(litDateCivile('demain'), isNull);
      expect(litDateCivile(''), isNull);
    });

    test('une heure hors plage est refusée sans lever', () {
      expect(litDateCivile('2026-11-15T25:70'), isNull);
    });
  });

  group('jourExisteAuCalendrier — ANCRAGE du message, jamais la barrière', () {
    test('les jours réels existent, les jours inventés non', () {
      expect(jourExisteAuCalendrier(2027, 2, 28), isTrue);
      expect(jourExisteAuCalendrier(2028, 2, 29), isTrue, reason: 'bissextile');
      expect(jourExisteAuCalendrier(2027, 2, 29), isFalse);
      expect(jourExisteAuCalendrier(2027, 2, 31), isFalse);
      expect(jourExisteAuCalendrier(2027, 13, 1), isFalse);
      expect(jourExisteAuCalendrier(2027, 4, 31), isFalse);
    });

    test(
      '⛔ elle n’est PAS un second exemplaire de V-1 : le prédicat refuse SEUL',
      () {
        // Réfutation de l'accusation de doublon : si cette fonction était
        // retirée, `litDateCivile` refuserait toujours le 31 février. Ce qui
        // serait perdu, c'est l'ANCRAGE du message sous le champ « date ».
        expect(litDateCivile(texteCivil(2027, 2, 31, 23, 59)), isNull);
      },
    );
  });
}
