import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/domain/remaining_time_calculator.dart';
import 'package:concentration/features/echeances/domain/time_unit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests du moteur d'unité adaptative (T4 / ADR-002).
void main() {
  const moteur = RemainingTimeCalculator();
  final maintenant = DateTime(2026, 8, 1, 12);

  ({TimeUnit unite, int nombre, double p, bool echue}) calcul(DateTime cible) {
    final r = moteur.calculer(
      clock: FakeClock(maintenant),
      echeance: Echeance(id: 'x', description: 'projet', dateEcheance: cible),
    );
    return (
      unite: r.unite,
      nombre: r.nombreAffiche,
      p: r.progression,
      echue: r.estEchue,
    );
  }

  group('exemples de référence du PRD — ils font contrat', () {
    test('2 ans 3 mois -> 3 ans', () {
      final r = calcul(DateTime(2028, 11, 1, 12));
      expect(r.unite, TimeUnit.annees);
      expect(r.nombre, 3);
    });

    test('8 mois 12 jours -> 9 mois', () {
      final r = calcul(DateTime(2027, 4, 13, 12));
      expect(r.unite, TimeUnit.mois);
      expect(r.nombre, 9);
    });

    test('2 semaines 1 heure -> 3 semaines', () {
      final r = calcul(DateTime(2026, 8, 15, 13));
      expect(r.unite, TimeUnit.semaines);
      expect(r.nombre, 3);
    });

    test('5 h 10 min -> 6 heures', () {
      final r = calcul(DateTime(2026, 8, 1, 17, 10));
      expect(r.unite, TimeUnit.heures);
      expect(r.nombre, 6);
    });
  });

  group('frontières de seuil — mesurées, pas supposées', () {
    test('exactement 12 mois -> années', () {
      expect(calcul(DateTime(2027, 8, 1, 12)).unite, TimeUnit.annees);
    });

    test('un instant sous 12 mois -> mois', () {
      expect(calcul(DateTime(2027, 8, 1, 11, 59)).unite, TimeUnit.mois);
    });

    test('exactement 1 mois -> mois', () {
      expect(calcul(DateTime(2026, 9, 1, 12)).unite, TimeUnit.mois);
    });

    test('un instant sous 1 mois -> semaines', () {
      expect(calcul(DateTime(2026, 9, 1, 11, 59)).unite, TimeUnit.semaines);
    });

    test('exactement 7 jours -> semaines', () {
      expect(calcul(DateTime(2026, 8, 8, 12)).unite, TimeUnit.semaines);
    });

    test('un instant sous 7 jours -> jours', () {
      expect(calcul(DateTime(2026, 8, 8, 11, 59)).unite, TimeUnit.jours);
    });

    test('la bascule jours -> heures est EXACTEMENT à 24 h (AC-4)', () {
      expect(calcul(DateTime(2026, 8, 2, 12)).unite, TimeUnit.jours);
      expect(calcul(DateTime(2026, 8, 2, 11, 59)).unite, TimeUnit.heures);
    });
  });

  group('calendaire réel (RNF-05) — jamais des durées moyennes', () {
    test(
      '29 février existe : du 31 janvier, +1 mois donne le 29/02 en année bissextile',
      () {
        final r = moteur.calculer(
          clock: FakeClock(DateTime(2028, 1, 31, 12)),
          echeance: Echeance(
            id: 'a',
            description: '',
            dateEcheance: DateTime(2028, 2, 29, 12),
          ),
        );
        expect(r.unite, TimeUnit.mois);
        expect(r.nombreAffiche, 1);
        // Comportement DOCUMENTÉ de l'écrêtage : le nombre est passé à 1 le
        // 29 JANVIER (addMois(29/01, 1) = 29/02), donc au 31 janvier il s'est
        // déjà écoulé 2 jours sur les 31 du palier. p n'est PAS nul à cet
        // instant, et ce n'est pas un artefact : c'est la borne exacte.
        expect(r.progression, closeTo(2 / 31, 1e-6));
      },
    );

    test('mois de longueurs différentes : février puis mars, même nombre', () {
      final fevrier = moteur.calculer(
        clock: FakeClock(DateTime(2026, 2, 1, 12)),
        echeance: Echeance(
          id: 'a',
          description: '',
          dateEcheance: DateTime(2026, 4, 1, 12),
        ),
      );
      final mars = moteur.calculer(
        clock: FakeClock(DateTime(2026, 3, 1, 12)),
        echeance: Echeance(
          id: 'a',
          description: '',
          dateEcheance: DateTime(2026, 5, 1, 12),
        ),
      );
      expect(fevrier.nombreAffiche, mars.nombreAffiche);
      expect(fevrier.nombreAffiche, 2);
    });

    test(
      'écrêtage du jour : 31 janvier + 1 mois = 28 février, jamais le 2 mars',
      () {
        // Cible au 28/02 : si l'écrêtage n'existait pas, le calcul rendrait 1 mois
        // pour une cible SUPÉRIEURE à un mois écrêté et ferait dériver p.
        final r = moteur.calculer(
          clock: FakeClock(DateTime(2026, 1, 31, 12)),
          echeance: Echeance(
            id: 'a',
            description: '',
            dateEcheance: DateTime(2026, 2, 28, 12),
          ),
        );
        expect(r.nombreAffiche, 1);
      },
    );
  });

  group(
    'progression p — définie par les deux instants qui encadrent (ADR-002 §4)',
    () {
      test('p = 0 juste après un changement de nombre', () {
        // Cible à exactement 6 heures : le nombre « 6 » vient de prendre sa valeur.
        final r = calcul(DateTime(2026, 8, 1, 18));
        expect(r.nombre, 6);
        expect(r.p, closeTo(0.0, 1e-9));
      });

      test('p proche de 1 juste avant un changement', () {
        // 5 h 01 min : le nombre est 6, le passage à 5 est imminent.
        final r = calcul(DateTime(2026, 8, 1, 17, 1));
        expect(r.nombre, 6);
        expect(r.p, greaterThan(0.98));
      });

      test('p vaut 0,5 à mi-chemin entre deux changements', () {
        final r = calcul(DateTime(2026, 8, 1, 17, 30));
        expect(r.nombre, 6);
        expect(r.p, closeTo(0.5, 1e-6));
      });

      test('p reste dans [0;1] sur un balayage de 400 instants', () {
        for (var minutes = 1; minutes <= 400; minutes++) {
          final r = calcul(maintenant.add(Duration(minutes: minutes)));
          expect(
            r.p,
            inInclusiveRange(0.0, 1.0),
            reason: 'p hors bornes à $minutes min',
          );
        }
      });

      test('p ne dépend PAS de la grandeur du nombre (AC-5)', () {
        // Un grand nombre peut être à p=0 (orange) et un petit à p élevé.
        final grand = calcul(DateTime(2029, 8, 1, 12)); // 3 ans pile -> p = 0
        final petit = calcul(
          DateTime(2026, 8, 1, 13, 1),
        ); // 1 h 01 -> 2 h, p ~ 0,98
        expect(grand.nombre, greaterThan(petit.nombre));
        expect(grand.p, lessThan(petit.p));
      });
    },
  );

  group('échéance atteinte (T <= 0) — état normal, pas une erreur (AC-7)', () {
    test('cible dans le passé', () {
      final r = calcul(DateTime(2026, 7, 31, 12));
      expect(r.echue, isTrue);
      expect(r.nombre, 0);
      expect(r.p, 1.0);
    });

    test('cible exactement maintenant', () {
      final r = calcul(maintenant);
      expect(r.echue, isTrue);
      expect(r.nombre, 0);
    });

    test('aucun nombre négatif, même très en retard', () {
      final r = calcul(DateTime(2000));
      expect(r.nombre, 0);
      expect(r.nombre, isNonNegative);
    });
  });

  group('libellé d’accessibilité — seul endroit où l’unité devient un mot', () {
    test('accorde le nombre et porte la description', () {
      final r = moteur.calculer(
        clock: FakeClock(maintenant),
        echeance: Echeance(
          id: 'a',
          description: 'préparation du projet',
          dateEcheance: DateTime(2029, 8, 1, 12),
        ),
      );
      expect(r.libelleAccessibilite, '3 ans, préparation du projet');
    });

    test('singulier au nombre 1', () {
      final r = moteur.calculer(
        clock: FakeClock(maintenant),
        echeance: Echeance(
          id: 'a',
          description: '',
          dateEcheance: DateTime(2026, 8, 1, 13),
        ),
      );
      expect(r.libelleAccessibilite, '1 heure');
    });

    test('description vide : aucun suffixe parasite (I-3)', () {
      final r = moteur.calculer(
        clock: FakeClock(maintenant),
        echeance: Echeance(
          id: 'a',
          description: '',
          dateEcheance: DateTime(2026, 8, 3, 12),
        ),
      );
      expect(r.libelleAccessibilite, '2 jours');
    });

    test('échue : le libellé le dit, sans nombre négatif', () {
      final r = moteur.calculer(
        clock: FakeClock(maintenant),
        echeance: Echeance(
          id: 'a',
          description: 'impôts',
          dateEcheance: DateTime(2026, 7, 1),
        ),
      );
      expect(r.libelleAccessibilite, 'échéance atteinte, impôts');
    });
  });

  group(
    'changement d’heure (DST) — comportement DOCUMENTÉ, pas laissé implicite',
    () {
      test(
        'la bascule à 24 h absolues traverse un changement d’heure sans planter',
        () {
          // Dernier dimanche d'octobre 2026 : retour à l'heure d'hiver en Europe.
          final veille = DateTime(2026, 10, 24, 12);
          final r = moteur.calculer(
            clock: FakeClock(veille),
            echeance: Echeance(
              id: 'a',
              description: '',
              dateEcheance: DateTime(2026, 10, 25, 12),
            ),
          );
          // ADR-002 assume que jours/heures se mesurent en durée ABSOLUE : selon le
          // fuseau de la machine, 24 h civiles peuvent valoir 25 h réelles, donc
          // l'unité peut légitimement être « jours » (1) ou « heures » (25).
          expect(
            r.unite == TimeUnit.jours || r.unite == TimeUnit.heures,
            isTrue,
            reason: 'unité inattendue : ${r.unite}',
          );
          expect(r.nombreAffiche, greaterThan(0));
          expect(r.progression, inInclusiveRange(0.0, 1.0));
        },
      );
    },
  );
}
