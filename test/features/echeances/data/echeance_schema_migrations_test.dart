import 'dart:convert';

import 'package:concentration/features/echeances/data/echeance_schema_migrations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le **PATRON ALLER-RETOUR d'ADR-005**, instancié sur le premier schéma réel
/// du projet (T5, AC-12, C-11).
///
/// 🔴 **Ce fichier PORTE SES MUTANTS, et ils sont EXÉCUTÉS ici** : le patron est
/// écrit comme une **fonction réutilisable** à qui l'on passe un couple
/// `up`/`down`. On lui donne d'abord le **couple réel** *(il doit passer)*, puis
/// des **couples mutants** *(il doit ÉCHOUER)*. Un patron qui n'échoue jamais ne
/// mesure rien — *« un contrôle portant son mutant a été juste 7 fois sur 7 ;
/// un contrôle purement lexical, faux 7 fois sur 7 »*.
void main() {
  // MIGRATIONS.md §4, étape 1 : « un jeu de données représentatif, DONT DES
  // LIGNES NON CONCERNÉES par la migration, pour détecter les pertes
  // collatérales ». Les 3 échéances qu'exige le `.feature`, plus :
  //   a2   description VIDE (I-3 reste vrai)
  //   a3   clé d'entrée INCONNUE (« garde »)
  //   a4   SECONDES non nulles      -> conversion NON INVERSIBLE (mesuré)
  //   ligne non-objet, clé de tête inconnue
  const graineV1 =
      '{"schemaVersion":1,'
      '"echeances":['
      '{"id":"a1","description":"Convention","dateEcheance":"2026-11-15T22:59:00.000Z"},'
      '{"id":"a2","description":"","dateEcheance":"2026-07-15T21:59:00.000Z"},'
      '{"id":"a3","description":"Revue","dateEcheance":"2027-01-09T22:59:00.000Z","garde":7},'
      '{"id":"a4","description":"secondes","dateEcheance":"2026-11-15T22:59:30.000Z"},'
      '"ceci n\'est pas un objet"'
      '],'
      '"_inconnu":{"garde":true}}';

  Map<String, Object?> graine() =>
      Map<String, Object?>.from(jsonDecode(graineV1) as Map);

  List<Object?> lignes(Map<String, Object?> d) =>
      d['echeances']! as List<Object?>;

  Map<String, Object?>? parId(Map<String, Object?> d, String id) {
    for (final ligne in lignes(d)) {
      if (ligne is Map && ligne['id'] == id) {
        return Map<String, Object?>.from(ligne);
      }
    }
    return null;
  }

  String? dateDe(Map<String, Object?> d, String id) =>
      parId(d, id)?['dateEcheance'] as String?;

  /// 🔴 **LE PATRON de `MIGRATIONS.md` §4**, paramétré par son couple.
  ///
  /// Rend `null` si le patron **passe**, sinon le **motif** de son échec — ce
  /// qui rend l'échec observable au lieu d'être une simple exception.
  String? echecDuPatron(EtapeFn up, EtapeFn down) {
    // 1. seed @v1
    final avant = jsonEncode(graine());
    // 2. up
    final haut = up(graine());
    haut['schemaVersion'] = 2;
    // 3. assert @v2 — la migration a bien TRANSFORMÉ, sans déplacer l'instant
    if (lignes(haut).length != lignes(graine()).length) {
      return 'le nombre de lignes a changé';
    }
    if (dateDe(haut, 'a1') == dateDe(graine(), 'a1')) {
      return 'a1 : la date n’a PAS été transformée';
    }
    // 4. down
    final bas = down(haut);
    bas['schemaVersion'] = 1;
    // 5. assert @v1 — équivalence FONCTIONNELLE, mesurée sur les OCTETS
    if (jsonEncode(bas) != avant) {
      return 'ALLER-RETOUR NON EXACT\n  attendu=$avant\n  obtenu =${jsonEncode(bas)}';
    }
    return null;
  }

  final etape = etapesMigration.single;

  group('ADR-005 §1 — contrat du couple', () {
    test('la version courante est atteinte par la dernière étape', () {
      expect(versionCourante, 2);
      expect(etapesMigration.map((e) => e.version).toList(), [versionCourante]);
    });

    test('⛔ un up SANS down est interdit : les deux diffèrent', () {
      expect(identical(etape.up, etape.down), isFalse);
    });
  });

  group('🔴 LE PATRON ALLER-RETOUR, et ses MUTANTS', () {
    test('le couple RÉEL passe le patron', () {
      expect(
        echecDuPatron(etape.up, etape.down),
        isNull,
        reason:
            'ADR-005 §2 : état@v1 → up → état@v2 → down → état@v1 équivalent',
      );
    });

    test(
      '🔴 MUTANT (a) — un `down` qui NE RESTAURE PAS fait ÉCHOUER le patron',
      () {
        Map<String, Object?> identite(Map<String, Object?> d) =>
            Map<String, Object?>.from(d);
        expect(
          echecDuPatron(etape.up, identite),
          isNotNull,
          reason: 'un patron qui n’échoue jamais ne mesure rien',
        );
      },
    );

    test(
      '🔴 MUTANT (b) — un `up` qui ne transforme rien fait ÉCHOUER le patron',
      () {
        Map<String, Object?> identite(Map<String, Object?> d) =>
            Map<String, Object?>.from(d);
        expect(echecDuPatron(identite, etape.down), isNotNull);
      },
    );

    test('🔴 MUTANT (c) — un `up` SANS GARDE d’inversibilité fait ÉCHOUER', () {
      // ⛔ Mutant HORS du vocabulaire de la règle testée : il ne retire pas
      // « la garde », il fabrique une conversion qui ignore l'inversibilité.
      String? sansGarde(String iso) {
        final t = DateTime.tryParse(iso);
        if (t == null || !t.isUtc) return null;
        return '${t.toLocal().year.toString().padLeft(4, '0')}-'
            '${t.toLocal().month.toString().padLeft(2, '0')}-'
            '${t.toLocal().day.toString().padLeft(2, '0')}T'
            '${t.toLocal().hour.toString().padLeft(2, '0')}:'
            '${t.toLocal().minute.toString().padLeft(2, '0')}';
      }

      expect(
        echecDuPatron((d) => transformerDates(d, sansGarde), etape.down),
        isNotNull,
        reason:
            'sans la garde, « 22:59:30Z » perd 30 secondes — AC-12 « Erreur »',
      );
    });
  });

  group('AC-12 — ce que la montée fait et ne fait pas', () {
    test(
      'les 3 échéances convertibles gardent leur INSTANT, pas leur texte',
      () {
        final haut = migrer(graine())!;
        for (final id in ['a1', 'a2', 'a3']) {
          final avant = dateDe(graine(), id)!;
          final apres = dateDe(haut, id)!;
          expect(apres, isNot(avant), reason: '$id doit être transformée');
          expect(
            DateTime.parse(apres).toUtc(),
            DateTime.parse(avant),
            reason: '$id : l’instant a BOUGÉ',
          );
        }
      },
    );

    test('la forme écrite est CIVILE : ni Z, ni décalage, ni secondes', () {
      final haut = migrer(graine())!;
      final civil = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$');
      for (final id in ['a1', 'a2', 'a3']) {
        final v = dateDe(haut, id)!;
        expect(civil.hasMatch(v), isTrue, reason: '« $v » n’est pas civile');
        expect(v, isNot(contains('Z')));
        expect(DateTime.parse(v).isUtc, isFalse);
      }
    });

    test('⛔ JAMAIS de conversion AVEC PERTE : a4 reste VERBATIM', () {
      final haut = migrer(graine())!;
      expect(
        dateDe(haut, 'a4'),
        dateDe(graine(), 'a4'),
        reason:
            'les secondes non nulles rendent la conversion non inversible '
            '⇒ l’entrée est LAISSÉE TELLE QUELLE, jamais tronquée',
      );
    });

    test('rien de ce que la migration ne comprend pas ne disparaît', () {
      final haut = migrer(graine())!;
      expect(jsonEncode(haut['_inconnu']), jsonEncode(graine()['_inconnu']));
      expect(parId(haut, 'a3')!['garde'], 7);
      expect(lignes(haut).whereType<String>(), hasLength(1));
      final bas = migrer(haut, cible: 1)!;
      expect(jsonEncode(bas['_inconnu']), jsonEncode(graine()['_inconnu']));
    });

    test('l’aller-retour COMPLET par `migrer` rend les octets d’origine', () {
      final haut = migrer(graine())!;
      expect(lireVersion(haut), 2);
      final bas = migrer(haut, cible: 1)!;
      expect(lireVersion(bas), 1);
      expect(jsonEncode(bas), jsonEncode(graine()));
    });
  });

  group('R-6 — la migration ne se rejoue pas', () {
    test('le document migré PORTE la nouvelle version', () {
      expect(lireVersion(migrer(graine())!), versionCourante);
    });

    test('un second passage ne modifie RIEN', () {
      final une = migrer(graine())!;
      expect(jsonEncode(migrer(une)!), jsonEncode(une));
    });
  });

  group('lireVersion / migrer — on ne DEVINE jamais une version', () {
    Map<String, Object?> avecVersion(Object? version) {
      final d = graine();
      if (version == null) {
        d.remove('schemaVersion');
      } else {
        d['schemaVersion'] = version;
      }
      return d;
    }

    test(
      'une version FUTURE est refusée — l’accepter ÉCRASERAIT la donnée',
      () {
        expect(migrer(avecVersion(versionCourante + 1)), isNull);
      },
    );

    test('une version absente, textuelle ou nulle est refusée', () {
      expect(lireVersion(avecVersion(null)), isNull);
      expect(migrer(avecVersion(null)), isNull);
      expect(migrer(avecVersion('2')), isNull);
      expect(migrer(avecVersion(0)), isNull);
    });

    test('une cible hors plage est refusée', () {
      expect(migrer(graine(), cible: 0), isNull);
      expect(migrer(graine(), cible: versionCourante + 1), isNull);
    });

    test('une version valide est bien LUE — contrôle négatif', () {
      // ⛔ Sans ce côté-ci, un `lireVersion` qui rendrait TOUJOURS null et un
      // `migrer` qui refuserait TOUT passeraient pour des gardes exemplaires.
      expect(lireVersion(avecVersion(1)), 1);
      expect(lireVersion(avecVersion(2)), 2);
      expect(migrer(graine()), isNotNull);
    });
  });

  group('transformerDates — ce qui n’est pas un document ne casse rien', () {
    test('un `echeances` absent ou non-tableau est rendu tel quel', () {
      final sans = <String, Object?>{'schemaVersion': 1};
      expect(
        jsonEncode(transformerDates(sans, instantVersCivil)),
        jsonEncode(sans),
      );
    });

    test('une date non textuelle est laissée verbatim', () {
      final d = <String, Object?>{
        'schemaVersion': 1,
        'echeances': [
          {'id': 'x', 'dateEcheance': 42},
        ],
      };
      expect(jsonEncode(transformerDates(d, instantVersCivil)), jsonEncode(d));
    });

    test('instantVersCivil refuse ce qui n’est pas un v1 canonique', () {
      expect(instantVersCivil('pas une date'), isNull);
      expect(instantVersCivil('2026-11-15T23:59'), isNull, reason: 'non UTC');
      expect(
        instantVersCivil('2026-11-15T22:59:00Z'),
        isNull,
        reason: 'forme non canonique : millisecondes absentes',
      );
      expect(instantVersCivil('2026-11-15T22:59:00.000Z'), isNotNull);
    });

    test('civilVersInstant refuse ce qui n’est pas un v2 canonique', () {
      expect(civilVersInstant('2027-02-31T23:59'), isNull);
      expect(civilVersInstant('2026-11-15T22:59:00.000Z'), isNull);
      expect(civilVersInstant('2026-11-15T23:59'), isNotNull);
    });
  });
}
