import 'dart:convert';

import 'package:concentration/features/echeances/data/echeance_document_codec.dart';
import 'package:concentration/features/echeances/data/echeance_schema_migrations.dart';
import 'package:flutter_test/flutter_test.dart';

/// **T3 — LA GARDE DU COUPLE `v2 ⇄ v3`** *(US-01.4, ADR-012 §4-§5)*.
///
/// 🔴 **POURQUOI CE FICHIER EXISTE, ET POURQUOI IL N'EST PAS SUBSTITUABLE.**
/// Le critère `reports/US-01.2/migration_roundtrip_criterion.py` est **conservé,
/// exigé et bit-à-bit inchangé** — mais il ⛔ **NE PEUT PAS** réfuter un `down`
/// destructeur, et c'est **mesuré, pas supposé** :
/// * `A1_contrat_couple` n'exige que `!identical(up, down)` ⇒ **deux fonctions
///   distinctes suffisent, MÊME IDENTIQUES EN EFFET** ;
/// * sa graine `GRAINE_V1` ⛔ **ne contient AUCUNE clé `retiree`** ⇒
///   `A3_aller_retour` **ne peut pas observer** la destruction d'une information
///   qui n'est pas dans sa graine. Ce n'est pas une faiblesse d'assertion, c'est
///   une **impossibilité logique**.
///
/// ⇒ **QUATRE mutants destructeurs passent ce critère avec 8 assertions sur 8
/// VERTES** *(matrice `--croise`)*, et le plus dangereux est celui qui a l'air
/// le plus **propre** : *« redescendre proprement en retirant la clé »*. Il fait
/// tomber **AC-12 « Erreur » d'US-01.2**, une US **EN AVAL, déjà validée**.
///
/// ⛔ **ET CE FICHIER N'EST PAS NON PLUS UN DOUBLON DU CRITÈRE `v3`**
/// *(`reports/US-01.4/migration_v3_guard_criterion.py`)* : celui-là **exige le
/// SDK Dart** et ⛔ **n'est PAS un gate CI**. **La garde doit vivre dans
/// `flutter test`, qui EST un gate requis** — sinon elle ne protège rien entre
/// deux exécutions manuelles.
///
/// 🔴 **LA GRAINE EST LE LIVRABLE, ⛔ pas les assertions** : elle porte **CHAQUE
/// forme que la grammaire d'ADR-012 §3 déclare**, dont **deux entrées
/// retirées** — exactement ce que la graine du critère d'US-01.2 n'a pas.
///
/// ⚠️ **Et il faut dire ce que la RELECTURE ne peut pas faire ici** : le module
/// conforme contient **ZÉRO occurrence du mot `retiree`** ⇒ ⛔ **cette migration
/// ne peut pas être revue en cherchant le nom du champ**, et `dart analyze`
/// rend `No issues found!` **même sur les mutants destructeurs**. **La
/// protection est ce test, ⛔ pas la relecture.**
void main() {
  // ⛔ Aucune date « vivante » : ce sont des VALEURS PERSISTÉES (R-13 ne les
  // vise pas). Les instants v1 sont choisis INVERSIBLES (secondes et
  // millisecondes nulles, hors heure répétée) — sinon la garde de `v1 ⇄ v2` les
  // laisse verbatim, ce qui est son travail, pas un défaut.
  const graineV2Json =
      '{"schemaVersion":2,'
      '"echeances":['
      '{"id":"r1","description":"Convention","dateEcheance":"2026-11-15T23:59","retiree":true},'
      '{"id":"r2","description":"","dateEcheance":"2026-07-15T23:59","retiree":false},'
      '{"id":"r3","description":"Revue","dateEcheance":"2027-01-09T23:59","retiree":true,"garde":7},'
      '{"id":"r4","description":"hors domaine","dateEcheance":"2027-03-02T23:59","retiree":"oui"},'
      '{"id":"r5","description":"jamais retiree","dateEcheance":"2027-05-04T23:59"},'
      '"ceci n\'est pas un objet"'
      '],'
      '"_inconnu":{"garde":true}}';

  const graineV1Json =
      '{"schemaVersion":1,'
      '"echeances":['
      '{"id":"r1","description":"Convention","dateEcheance":"2026-11-15T22:59:00.000Z","retiree":true},'
      '{"id":"r5","description":"jamais retiree","dateEcheance":"2027-05-04T21:59:00.000Z"}'
      '],'
      '"_inconnu":{"garde":true}}';

  Map<String, Object?> lire(String json) =>
      Map<String, Object?>.from(jsonDecode(json) as Map);

  Map<String, Object?> graineV2() => lire(graineV2Json);
  Map<String, Object?> graineV3() => graineV2()..['schemaVersion'] = 3;

  Map<String, Object?>? parId(Map<String, Object?> d, String id) {
    final brut = d['echeances'];
    if (brut is! List) return null;
    for (final ligne in brut) {
      if (ligne is Map && ligne['id'] == id) {
        return Map<String, Object?>.from(ligne);
      }
    }
    return null;
  }

  /// 🔴 **LA GARDE, PARAMÉTRÉE PAR SON COUPLE** — c'est ce qui permet de la
  /// jouer contre le couple RÉEL *(elle doit passer)* **puis contre des couples
  /// MUTANTS** *(elle doit ÉCHOUER)*. Un patron qui n'échoue jamais ne mesure
  /// rien.
  ///
  /// Rend `null` si la garde passe, sinon **le motif** — l'échec est ainsi
  /// **observable**, pas une simple exception.
  String? echecDeLaGarde(EtapeFn up, EtapeFn down) {
    // 1. Le `up` est l'IDENTITÉ SUR TOUT LE DOCUMENT. `schemaVersion` est écrit
    //    par `migrer`, ⛔ pas par l'étape : l'étape, elle, ne touche À RIEN.
    if (jsonEncode(up(graineV2())) != jsonEncode(graineV2())) {
      return 'le `up` a MODIFIE le document\n'
          '  attendu = ${jsonEncode(graineV2())}\n'
          '  obtenu  = ${jsonEncode(up(graineV2()))}';
    }
    // 2. Le `down` aussi. C'est LUI que le critère d'US-01.2 ne sait pas voir.
    if (jsonEncode(down(graineV3())) != jsonEncode(graineV3())) {
      return 'le `down` a MODIFIE le document\n'
          '  attendu = ${jsonEncode(graineV3())}\n'
          '  obtenu  = ${jsonEncode(down(graineV3()))}';
    }
    // 3. `retiree: true` SURVIT au `down` : clé CONSERVÉE, valeur BOOLÉENNE,
    //    entrée identique AUX OCTETS. ⛔ « Redescendre proprement en retirant la
    //    clé » DÉTRUIT le retrait ⇒ AC-12 « Erreur » d'US-01.2 tombe.
    for (final id in const ['r1', 'r3']) {
      final e = parId(down(graineV3()), id);
      if (e == null) return 'entrée $id : DISPARUE au `down`';
      if (!e.containsKey('retiree')) {
        return 'entrée $id : la clé `retiree` a été RETIRÉE par le `down`';
      }
      if (e['retiree'] != true) {
        return 'entrée $id : `retiree` vaut ${jsonEncode(e['retiree'])} '
            'après le `down`';
      }
      if (jsonEncode(e) != jsonEncode(parId(graineV2(), id))) {
        return 'entrée $id : octets modifiés par le `down`';
      }
    }
    // 4. `false` est une forme LICITE : le `down` la laisse VERBATIM ELLE AUSSI.
    //    ⚖️ C'est la RECTIFICATION du 2026-08-24 : la cellule T3 du Story File
    //    disait qu'un `false` « disparaît au `down` ». Un `down` qui sait
    //    nettoyer les `false` sait retirer la clé — il retirera un `true` au
    //    premier remaniement.
    final r2 = parId(down(graineV3()), 'r2');
    if (r2 == null || !r2.containsKey('retiree') || r2['retiree'] != false) {
      return 'entrée r2 : le `down` a touché un `retiree: false` '
          '(obtenu ${jsonEncode(r2?['retiree'])})';
    }
    // 5. Aucune entrée ne GAGNE de clé au `up` : la forme « explicite partout »
    //    FABRIQUE le `down` destructif qu'ADR-012 §4 interdit.
    final r5 = parId(up(graineV2()), 'r5');
    if (r5 == null || r5.containsKey('retiree')) {
      return 'entrée r5 : le `up` a AJOUTÉ une clé `retiree`';
    }
    // 6. Rien n'est RECOMPOSÉ : clé d'entrée inconnue d'une entrée retirée,
    //    entrée RÉSIDUELLE (`retiree` hors domaine) et clé de TÊTE inconnue
    //    survivent à leur place, dans les deux sens.
    if (jsonEncode(parId(up(graineV2()), 'r3')?['garde']) != jsonEncode(7)) {
      return 'la clé inconnue d’une entrée RETIRÉE a été perdue par le `up`';
    }
    for (final sens in <Map<String, Object?>>[
      up(graineV2()),
      down(graineV3()),
    ]) {
      if (jsonEncode(parId(sens, 'r4')) !=
          jsonEncode(parId(graineV2(), 'r4'))) {
        return 'l’entrée RÉSIDUELLE (`retiree` hors domaine) a été altérée';
      }
      if (jsonEncode(sens['_inconnu']) != jsonEncode(graineV2()['_inconnu'])) {
        return 'la clé de TÊTE inconnue a été perdue';
      }
    }
    // 7. L'ALLER-RETOUR, dans les DEUX SENS, sur une graine QUI CONTIENT des
    //    entrées retirées.
    if (jsonEncode(down(up(graineV2()))) != jsonEncode(graineV2())) {
      return 'aller-retour v2 → v3 → v2 NON EXACT';
    }
    if (jsonEncode(up(down(graineV3()))) != jsonEncode(graineV3())) {
      return 'aller-retour v3 → v2 → v3 NON EXACT';
    }
    return null;
  }

  EtapeMigration etapeV3() => etapesMigration.firstWhere((e) => e.version == 3);

  group('ADR-005 §1 — le contrat de l’étape, vérifié PAR LE CALCUL', () {
    test('`versionCourante` vaut 3 et les étapes sont CONTIGUËS', () {
      expect(versionCourante, 3);
      final versions = etapesMigration.map((e) => e.version).toList();
      expect(versions, <int>[2, 3]);
      // ⛔ Le nombre n'est pas écrit à la main : la contiguïté est CALCULÉE,
      // exactement comme `A1_contrat_couple` la calcule.
      for (var i = 0; i < versions.length; i++) {
        expect(versions[i], versionCourante - versions.length + 1 + i);
      }
      expect(versions.last, versionCourante);
    });

    test('🔴 `up` et `down` sont DEUX FONCTIONS DISTINCTES', () {
      // CONTRAINTE DE LANGAGE MESURÉE : les tear-offs d'une fonction de premier
      // niveau sont CANONICALISÉS dans une liste `const` ⇒ un seul `_identite`
      // partagé rendrait `identical(up, down)` VRAI et ferait rougir
      // `A1_contrat_couple` du critère d'US-01.2.
      expect(identical(etapeV3().up, etapeV3().down), isFalse);
      // ⚠️ Et la BORNE de cette assertion, dite au lieu d'être tue : elle ne
      // prouve RIEN sur ce que le couple FAIT — deux fonctions distinctes mais
      // destructrices la satisferaient. C'est le groupe suivant qui le prouve.
      expect(etapeV3().up, isNot(same(etapeV3().down)));
    });
  });

  group('🔴 LA GARDE, et elle PORTE SES MUTANTS — tous EXÉCUTÉS ici', () {
    test('le couple RÉEL passe la garde', () {
      expect(echecDeLaGarde(etapeV3().up, etapeV3().down), isNull);
    });

    // Les quatre couples ci-dessous sont EXACTEMENT ceux qu'ADR-012 §4 interdit
    // et que le critère d'US-01.2 laisse passer 8/8 VERTES.
    Map<String, Object?> parcourir(
      Map<String, Object?> d,
      void Function(Map<Object?, Object?> ligne, Map<String, Object?> copie)
      remplir,
    ) {
      final brut = d['echeances'];
      if (brut is! List) return Map<String, Object?>.from(d);
      final sortie = <Object?>[];
      for (final ligne in brut) {
        if (ligne is! Map) {
          sortie.add(ligne);
          continue;
        }
        final copie = <String, Object?>{};
        remplir(ligne, copie);
        sortie.add(copie);
      }
      return Map<String, Object?>.from(d)..['echeances'] = sortie;
    }

    Map<String, Object?> identite(Map<String, Object?> d) =>
        Map<String, Object?>.from(d);

    Map<String, Object?> retireLaCle(Map<String, Object?> d) =>
        parcourir(d, (ligne, copie) {
          ligne.forEach((k, v) {
            if (k.toString() != 'retiree') copie['$k'] = v;
          });
        });

    Map<String, Object?> nettoieLesFalse(Map<String, Object?> d) =>
        parcourir(d, (ligne, copie) {
          ligne.forEach((k, v) {
            if (k.toString() == 'retiree' && v == false) return;
            copie['$k'] = v;
          });
        });

    Map<String, Object?> ecritFalsePartout(Map<String, Object?> d) =>
        parcourir(d, (ligne, copie) {
          ligne.forEach((k, v) => copie['$k'] = v);
          copie['retiree'] = copie['retiree'] ?? false;
        });

    Map<String, Object?> recompose(Map<String, Object?> d) => parcourir(d, (
      ligne,
      copie,
    ) {
      for (final k in const ['id', 'description', 'dateEcheance', 'retiree']) {
        if (ligne.containsKey(k)) copie[k] = ligne[k];
      }
    });

    test('⛔ MUTANT — le `down` RETIRE la clé (« redescendre proprement »)', () {
      // Le plus dangereux du lot : il a l'air le plus propre, et il DÉTRUIT
      // l'information de retrait.
      expect(echecDeLaGarde(identite, retireLaCle), isNotNull);
    });

    test('⛔ MUTANT — le `down` « nettoie les `false` »', () {
      // ⚖️ C'est la forme que prescrivait la cellule T3 avant sa rectification
      // du 2026-08-24. Elle DOIT échouer.
      expect(echecDeLaGarde(identite, nettoieLesFalse), isNotNull);
    });

    test('⛔ MUTANT — le `up` écrit `retiree: false` PARTOUT', () {
      expect(echecDeLaGarde(ecritFalsePartout, retireLaCle), isNotNull);
      // Et même avec un `down` inoffensif : le `up` seul suffit à la faire
      // rougir (il AJOUTE une clé).
      expect(echecDeLaGarde(ecritFalsePartout, identite), isNotNull);
    });

    test('⛔ MUTANT — le couple RECOMPOSE l’entrée', () {
      expect(echecDeLaGarde(recompose, recompose), isNotNull);
    });

    test('⛔ CONTRÔLE NÉGATIF — la garde n’est pas rouge « par principe »', () {
      // Sans lui, un `return "..."` inconditionnel rendrait les quatre tests
      // ci-dessus verts. C'est le même contrôle que le `M0_conforme` du critère.
      expect(echecDeLaGarde(identite, identite), isNull);
    });
  });

  group('`migrer` de bout en bout — SEUL `schemaVersion` change', () {
    test('v2 → v3 : le document est identique, à `schemaVersion` près', () {
      final haut = migrer(graineV2(), cible: 3);
      expect(haut, isNotNull);
      expect(jsonEncode(haut), jsonEncode(graineV3()));
      expect(lireVersion(haut!), 3);
    });

    test('l’aller-retour par `migrer` est EXACT AUX OCTETS', () {
      final avant = jsonEncode(graineV2());
      final haut = migrer(graineV2(), cible: 3)!;
      expect(jsonEncode(migrer(haut, cible: 2)), avant);
      final avant3 = jsonEncode(graineV3());
      final bas = migrer(graineV3(), cible: 2)!;
      expect(jsonEncode(migrer(bas, cible: 3)), avant3);
    });

    test('un document `v3` n’est PLUS une version FUTURE', () {
      // Avant T3, `schemaVersion: 3` faisait prendre la branche « version
      // future » : état vide et AUCUNE écriture. C'est cela que le bump paie.
      expect(migrer(graineV3(), cible: 3), isNotNull);
      expect(migrer(lire('{"schemaVersion":4,"echeances":[]}')), isNull);
    });

    test('la CHAÎNE v1 → v3 → v1 conserve le retrait ET les octets', () {
      final avant = jsonEncode(lire(graineV1Json));
      final haut = migrer(lire(graineV1Json), cible: 3);
      expect(haut, isNotNull);
      expect(lireVersion(haut!), 3);
      // La date A été convertie par l'étape v1→v2 : la chaîne traverse bien les
      // DEUX étapes, ⛔ elle ne court-circuite pas.
      expect(parId(haut, 'r1')?['dateEcheance'], isNot(contains('Z')));
      expect(parId(haut, 'r1')?['retiree'], isTrue);
      expect(jsonEncode(migrer(haut, cible: 1)), avant);
    });
  });

  group(
    '⚖️ OÙ un `false` disparaît VRAIMENT — ce n’est PAS le même endroit',
    () {
      // 🔴 La cellule T3 du Story File a porté pendant trois jours l'énoncé
      // « un `false` disparaît au `down` ». Ce groupe fixe la vérité aux DEUX
      // endroits à la fois, pour que l'erreur ne puisse pas revenir.
      const codec = EcheanceDocumentCodec();

      test('le `down` le laisse VERBATIM…', () {
        final bas = migrer(graineV3(), cible: 2)!;
        expect(parId(bas, 'r2')!.containsKey('retiree'), isTrue);
        expect(parId(bas, 'r2')!['retiree'], isFalse);
      });

      test('…et c’est LE CODEC qui ne le ré-émet pas', () {
        final document = codec.decoderDocument(graineV2());
        final reecrit = codec.encoder(document, document.echeances);
        // r2 est reconnue (un `false` est licite) et sa clé n'est PAS ré-émise.
        expect(parId(lire(reecrit), 'r2')!.containsKey('retiree'), isFalse);
        // ⛔ CONTRÔLE : le `true` de r1, lui, est ré-émis.
        expect(parId(lire(reecrit), 'r1')!['retiree'], isTrue);
        // ⛔ Et l'entrée RÉSIDUELLE r4 est ré-émise VERBATIM par le codec.
        expect(
          jsonEncode(parId(lire(reecrit), 'r4')),
          jsonEncode(parId(graineV2(), 'r4')),
        );
      });
    },
  );
}
