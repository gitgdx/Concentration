import 'package:concentration/features/echeances/data/echeance_document_codec.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:flutter_test/flutter_test.dart';

/// Codec du document `echeances.json` (T4) — AC-11, AC-14.
///
/// 🔴 **MUTANT OBLIGATOIRE (R-2)** : un codec qui **oublie** les résidus doit
/// **FAIRE ÉCHOUER** ce fichier. Le mutant qui les tue est nommé sur chaque
/// test concerné : *dans `encoder`, remplacer la branche « `id == null` ⇒
/// ré-émettre `lignes[i]` » par un `continue`*. Trois assertions distinctes
/// tombent alors — la présence du résidu, sa **position**, et ses **octets**.
void main() {
  const codec = EcheanceDocumentCodec();

  // ⛔ Aucune date de calendrier « vivante » ici : ces chaînes sont des VALEURS
  // PERSISTÉES, pas des échéances soumises au temps qui passe (R-13 vise les
  // données qui deviennent passées et font pourrir un test — une valeur sur
  // disque, elle, ne bouge pas).
  const documentAvecResidu =
      '{"schemaVersion":2,'
      '"echeances":['
      '{"id":"a1","description":"Convention","dateEcheance":"2027-03-15T23:59"},'
      '{"id":"","description":"identifiant vide","dateEcheance":"2027-04-01T09:00"},'
      '{"id":"a2","description":"Rendez-vous","dateEcheance":"2027-06-02T09:00"}'
      '],'
      '"_inconnu":{"garde":true}}';

  group('lireRacine — ce qui rend le DOCUMENT ENTIER illisible', () {
    test('un JSON invalide rend null, sans lever', () {
      expect(codec.lireRacine('{"schemaVersion":2,'), isNull);
      expect(codec.lireRacine(''), isNull);
    });

    test('une racine non-objet rend null', () {
      expect(codec.lireRacine('[1,2,3]'), isNull);
      expect(codec.lireRacine('null'), isNull);
    });

    test('un `echeances` qui n’est pas un tableau rend null', () {
      expect(codec.lireRacine('{"schemaVersion":2,"echeances":{}}'), isNull);
      expect(codec.lireRacine('{"schemaVersion":2}'), isNull);
    });

    test('un document conforme rend sa racine ENTIÈRE', () {
      final racine = codec.lireRacine(documentAvecResidu);
      expect(racine, isNotNull);
      expect(racine!['schemaVersion'], 2);
      expect(racine['_inconnu'], isNotNull);
    });
  });

  group('AC-11 — reconnues et résidus, séparés sans rien réparer', () {
    test('2 valides + 1 illisible ⇒ 2 reconnues + 1 résidu', () {
      final document = codec.decoder(documentAvecResidu)!;
      expect(document.echeances.map((e) => e.id).toList(), ['a1', 'a2']);
      expect(document.lignes, hasLength(3));
      // La ligne 1 (l'identifiant vide) n'a PAS d'id reconnu : c'est un résidu.
      expect(document.idParIndex.keys.toSet(), {0, 2});
    });

    test('🔴 un résidu ré-émis est OCTET POUR OCTET identique, À SA PLACE', () {
      final document = codec.decoder(documentAvecResidu)!;
      final reecrit = codec.encoder(document, document.echeances);
      // MUTANT R-2 : un `continue` à la place de la ré-émission fait tomber
      // cette assertion — et les deux suivantes.
      expect(
        reecrit,
        contains(
          '{"id":"","description":"identifiant vide",'
          '"dateEcheance":"2027-04-01T09:00"}',
        ),
        reason: 'le résidu doit survivre OCTET POUR OCTET',
      );
      // ⚠️ Assertion de GRANDEUR, pas une égalité au token : la POSITION du
      // résidu est vérifiée par l'ordre des trois identifiants dans le texte.
      expect(
        reecrit.indexOf('"a1"') < reecrit.indexOf('identifiant vide'),
        isTrue,
      );
      expect(
        reecrit.indexOf('identifiant vide') < reecrit.indexOf('"a2"'),
        isTrue,
        reason: 'le résidu reste ENTRE les deux entrées reconnues',
      );
    });

    test('un aller-retour SANS modification rend les octets d’origine', () {
      final document = codec.decoder(documentAvecResidu)!;
      expect(codec.encoder(document, document.echeances), documentAvecResidu);
    });

    test(
      'une date NON CANONIQUE fait de l’entrée un résidu, pas une réparation',
      () {
        // Le 31 février : `DateTime.parse` l'avale, la forme canonique le refuse.
        const doc =
            '{"schemaVersion":2,"echeances":['
            '{"id":"x","description":"impossible","dateEcheance":"2027-02-31T23:59"}]}';
        final document = codec.decoder(doc)!;
        expect(document.echeances, isEmpty);
        expect(codec.encoder(document, document.echeances), doc);
      },
    );

    test('un `id` EN DOUBLE : la première reconnue, la suivante résidu', () {
      // ⚖️ Règle laissée SANS AC ni Gherkin par arbitrage humain du 2026-08-06
      // (voie b) — couverte par ce test unitaire DÉCLARÉ.
      const doc =
          '{"schemaVersion":2,"echeances":['
          '{"id":"d","description":"premiere","dateEcheance":"2027-03-15T23:59"},'
          '{"id":"d","description":"seconde","dateEcheance":"2027-04-15T23:59"}]}';
      final document = codec.decoder(doc)!;
      expect(document.echeances, hasLength(1));
      expect(document.echeances.single.description, 'premiere');
      expect(
        codec.encoder(document, document.echeances),
        doc,
        reason: '⛔ le doublon est CONSERVÉ, jamais supprimé',
      );
    });

    test('une entrée non-objet est un résidu', () {
      const doc =
          '{"schemaVersion":2,"echeances":["ceci n\'est pas un objet"]}';
      final document = codec.decoder(doc)!;
      expect(document.echeances, isEmpty);
      expect(codec.encoder(document, document.echeances), doc);
    });

    test('une description ABSENTE vaut vide (I-3), non-textuelle = résidu', () {
      const doc =
          '{"schemaVersion":2,"echeances":['
          '{"id":"sans","dateEcheance":"2027-03-15T23:59"},'
          '{"id":"nombre","description":7,"dateEcheance":"2027-03-16T23:59"}]}';
      final document = codec.decoder(doc)!;
      expect(document.echeances.map((e) => e.id).toList(), ['sans']);
      expect(
        document.echeances.single.description,
        isEmpty,
        reason: 'I-3 : une description vide est LICITE en lecture',
      );
      expect(
        codec.encoder(document, document.echeances),
        contains('"description":7'),
        reason: '⛔ une description non textuelle n’est pas NORMALISÉE',
      );
    });
  });

  group('AC-14 — la valeur persistée est une DATE CIVILE (texte)', () {
    test('la chaîne écrite ne porte NI Z NI décalage NI secondes', () {
      final document = codec.documentNeuf(2);
      final texte = codec.encoder(document, [
        Echeance(
          id: 'n1',
          description: 'Convention',
          dateEcheance: DateTime(2027, 11, 15, 23, 59),
        ),
      ]);
      expect(texte, contains('"dateEcheance":"2027-11-15T23:59"'));
      // Assertion SUR LE TEXTE, exigée par C-13.
      final valeur = RegExp(
        r'"dateEcheance":"([^"]+)"',
      ).firstMatch(texte)!.group(1)!;
      expect(valeur, matches(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$'));
      expect(valeur, isNot(contains('Z')));
      expect(valeur, isNot(contains('+')));
      expect(
        valeur.split('T').last,
        isNot(contains(':00:')),
        reason: 'aucune composante de secondes',
      );
    });

    test('relecture LITTÉRALE : la date et l’heure reviennent identiques', () {
      final document = codec.documentNeuf(2);
      final origine = Echeance(
        id: 'n1',
        description: 'Convention',
        dateEcheance: DateTime(2027, 3, 15, 8, 5),
      );
      final relu = codec.decoder(codec.encoder(document, [origine]))!;
      expect(relu.echeances.single.dateEcheance, origine.dateEcheance);
      expect(relu.echeances.single.dateEcheance.isUtc, isFalse);
    });
  });

  group('encoder — création, mise à jour, suppression', () {
    test('une création est ajoutée EN FIN, le résidu ne bouge pas', () {
      final document = codec.decoder(documentAvecResidu)!;
      final texte = codec.encoder(document, [
        ...document.echeances,
        Echeance(
          id: 'neuve',
          description: 'Ajoutée',
          dateEcheance: DateTime(2027, 12, 1, 23, 59),
        ),
      ]);
      expect(
        texte.indexOf('identifiant vide') < texte.indexOf('"neuve"'),
        isTrue,
      );
      expect(texte, contains('identifiant vide'));
    });

    test('une suppression retire SON entrée et RIEN d’autre', () {
      final document = codec.decoder(documentAvecResidu)!;
      final texte = codec.encoder(
        document,
        document.echeances.where((e) => e.id != 'a1').toList(),
      );
      expect(texte, isNot(contains('Convention')));
      expect(texte, contains('"a2"'));
      expect(
        texte,
        contains('identifiant vide'),
        reason: '⛔ un résidu survit à une suppression (MUTANT R-2)',
      );
    });

    test('une mise à jour PRÉSERVE les clés inconnues de l’entrée', () {
      const doc =
          '{"schemaVersion":2,"echeances":['
          '{"id":"g","description":"Avant","dateEcheance":"2027-03-15T23:59",'
          '"garde":7}]}';
      final document = codec.decoder(doc)!;
      final texte = codec.encoder(document, [
        document.echeances.single.avec(description: 'Après'),
      ]);
      expect(texte, contains('"description":"Après"'));
      expect(
        texte,
        contains('"garde":7'),
        reason: 'une clé d’entrée inconnue ne se perd pas à la réécriture',
      );
    });

    test('les clés de TÊTE inconnues survivent à toute écriture', () {
      final document = codec.decoder(documentAvecResidu)!;
      expect(
        codec.encoder(document, const []),
        contains('"_inconnu":{"garde":true}'),
      );
    });

    test('documentNeuf porte sa version et un tableau vide', () {
      final texte = codec.encoder(codec.documentNeuf(2), const []);
      expect(texte, '{"schemaVersion":2,"echeances":[]}');
    });
  });
}
