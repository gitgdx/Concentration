import 'dart:convert';
import 'dart:io';

import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/document_store.dart';
import 'package:concentration/features/echeances/data/document_store_plateforme.dart';
import 'package:concentration/features/echeances/data/document_store_stub.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/magasin_temporaire.dart';

/// Le contenu **effectivement lu** — ⛔ jamais un simple `isA<DocumentLu>()`,
/// qui passerait sur un magasin rendant n'importe quoi.
Matcher estLu(String contenu) =>
    isA<DocumentLu>().having((l) => l.contenu, 'contenu', contenu);

/// Le magasin de plateforme (T6) — **de VRAIS octets sur un VRAI disque**.
void main() {
  late MagasinTemporaire harnais;

  setUp(() => harnais = MagasinTemporaire.creer());
  tearDown(() => harnais.nettoyer());

  group('DocumentStoreFichier — écriture ATOMIQUE, lecture, mise de côté', () {
    test('aucun fichier ⇒ lire() rend DocumentAbsent (c’est `v0`)', () async {
      expect(await harnais.magasin.lire(), isA<DocumentAbsent>());
    });

    test('écrire puis relire rend LES MÊMES OCTETS', () async {
      const contenu = '{"schemaVersion":2,"echeances":[]}';
      await harnais.magasin.ecrire(contenu);
      expect(await harnais.magasin.lire(), estLu(contenu));
      // ⚠️ Assertion sur le DISQUE, pas sur la valeur de retour : sans elle,
      // un magasin qui garderait tout en mémoire passerait.
      expect(harnais.octets(), contenu);
    });

    test(
      'l’écriture ne laisse AUCUN fichier provisoire derrière elle',
      () async {
        await harnais.magasin.ecrire('{"schemaVersion":2,"echeances":[]}');
        expect(harnais.fichiers(), [nomDocument]);
      },
    );

    test('🔴 un `.tmp` laissé par une INTERRUPTION n’est JAMAIS lu', () async {
      // Simule une écriture interrompue AVANT le `rename` : le provisoire
      // existe, la cible non.
      File('${harnais.fichier.path}.tmp').writeAsStringSync('MOITIE ECRIT');
      expect(
        await harnais.magasin.lire(),
        isA<DocumentAbsent>(),
        reason:
            'lire() ne regarde QUE la cible — c’est la moitié de ce qui '
            'rend AC-12 « Erreur » vrai par construction',
      );
    });

    test(
      'une interruption laisse la cible EXISTANTE strictement intacte',
      () async {
        const origine = '{"schemaVersion":2,"echeances":[{"id":"a"}]}';
        harnais.poser(origine);
        File('${harnais.fichier.path}.tmp').writeAsStringSync('MOITIE ECRIT');
        expect(harnais.octets(), origine);
        expect(await harnais.magasin.lire(), estLu(origine));
      },
    );

    test('mettreDeCote() CONSERVE le fichier et n’en supprime AUCUN', () async {
      const illisible = '{ceci n est pas du JSON';
      harnais.poser(illisible);
      await harnais.magasin.mettreDeCote();

      expect(
        harnais.octets(),
        isNull,
        reason: 'la cible a bougé, l’application peut écrire de nouveau',
      );
      final restants = harnais.fichiers();
      expect(restants, hasLength(1), reason: '⛔ JAMAIS un delete');
      expect(restants.single, startsWith('$nomDocument.illisible-'));
      expect(
        File(
          '${harnais.repertoire.path}${Platform.pathSeparator}'
          '${restants.single}',
        ).readAsStringSync(),
        illisible,
        reason: 'le contenu mis de côté est OCTET POUR OCTET celui d’origine',
      );
    });

    test(
      'mettreDeCote() sur un répertoire vide ne fait rien et ne lève pas',
      () async {
        await harnais.magasin.mettreDeCote();
        expect(harnais.fichiers(), isEmpty);
      },
    );

    test(
      '🔴 deux mises de côté au MÊME instant n’en écrasent pas une',
      () async {
        // Horloge FIGÉE : sans garde de collision, le second `rename` écraserait
        // le premier — une perte silencieuse, exactement ce que « jamais un
        // delete » interdit.
        final fige = MagasinTemporaire.creer(
          clock: FakeClock(DateTime(2026, 8, 6, 12)),
        );
        addTearDown(fige.nettoyer);
        fige.poser('PREMIER');
        await fige.magasin.mettreDeCote();
        fige.poser('SECOND');
        await fige.magasin.mettreDeCote();
        expect(fige.fichiers(), hasLength(2));
      },
    );
  });

  group('🔴 B-1 — des OCTETS non décodables, ⛔ pas du JSON invalide', () {
    // ⛔ **CE GROUPE EXISTE PARCE QUE 344 TESTS ET 97,9 % DE COUVERTURE N'ONT
    // RIEN VU** (audit sécurité du 2026-08-07). Les 3 tests d'AC-11 exerçaient
    // du **JSON invalide** ; le harnais, lui, ne pouvait poser que de l'UTF-8
    // valide (`poser` → `writeAsStringSync`) ⇒ la classe entière était **hors
    // d'atteinte**, et la couverture **MONTAIT** sur le diff qui introduisait le
    // bloquant.
    //
    // ⚠️ Ces tests exercent le **MAGASIN DE PRODUCTION** (`DocumentStoreFichier`
    // sur un répertoire temporaire réel) : ⛔ un magasin factice contournerait la
    // garde et rendrait le test **vert à tort**.

    test(
      'un SEUL octet cp1252 ⇒ DocumentIllisible, et lire() NE LÈVE PAS',
      () async {
        final fautif = documentNonDecodable();
        harnais.poserOctets(fautif);

        expect(
          await harnais.magasin.lire(),
          isA<DocumentIllisible>(),
          reason:
              'avant le correctif, readAsString LEVAIT une FileSystemException '
              'que personne n’attrapait, jusqu’à main() qui l’await AVANT runApp',
        );
        expect(
          harnais.octetsBruts(),
          fautif,
          reason:
              '⛔ lire() ne répare, ne réécrit et ne déplace RIEN — ⛔ surtout pas '
              'par allowMalformed, qui figerait la corruption (AC-11, AC-16)',
        );
      },
    );

    test(
      '🔴 CONTRÔLE NÉGATIF — le MÊME document en UTF-8 valide est LU',
      () async {
        // Un seul octet devient deux, au même endroit, et le verdict BASCULE.
        // ⛔ Sans cette assertion, un magasin déclarant TOUT illisible passerait.
        final sain = documentDecodable();
        harnais.poserOctets(sain);
        expect(await harnais.magasin.lire(), estLu(utf8.decode(sain)));
      },
    );

    test(
      'un document TRONQUÉ en pleine séquence ⇒ DocumentIllisible',
      () async {
        // « fichier tronqué » est le mot LITTÉRAL d'AC-11 « Erreur ».
        harnais.poserOctets(documentTronqueEnPleineSequence());
        expect(await harnais.magasin.lire(), isA<DocumentIllisible>());
      },
    );

    test('UN SEUL octet 0x80 AJOUTÉ à un document parfait suffit', () async {
      // ⚠️ Le document reste valide sur toute sa longueur : la faute peut être
      // n’importe où, y compris ajoutée par un outil tiers en fin de fichier.
      harnais.poserOctets(<int>[...documentDecodable(), 0x80]);
      expect(await harnais.magasin.lire(), isA<DocumentIllisible>());
    });
  });

  group('R-15 — le STUB est importé DIRECTEMENT par un test', () {
    // ⛔ Se contenter de l'import conditionnel le rendrait INVISIBLE à la
    // couverture : un fichier de `lib/` non importé par un test n'entre pas au
    // dénominateur, donc il pourrait être faux sans qu'on le sache.
    const stub = DocumentStoreStub();

    test('lire() rend DocumentAbsent — la plateforme ne stocke rien', () async {
      // ⛔ ET SURTOUT PAS `DocumentIllisible` : il n'y a rien à mettre de côté,
      // et le `rename` du stub LÈVE.
      expect(await stub.lire(), isA<DocumentAbsent>());
      expect(await stub.lire(), isNot(isA<DocumentIllisible>()));
    });

    test('🔴 ecrire() LÈVE — ⛔ jamais un échec silencieux', () async {
      await expectLater(
        stub.ecrire('{"schemaVersion":2,"echeances":[]}'),
        throwsUnsupportedError,
      );
    });

    test('mettreDeCote() lève aussi — rien ne peut être déplacé', () async {
      await expectLater(stub.mettreDeCote(), throwsUnsupportedError);
    });
  });

  group('l’import conditionnel choisit bien la branche de la plateforme', () {
    test('🔴 sous la VM, la branche IO est retenue — ⛔ PAS le stub', () async {
      // ⛔ Contrôle NÉGATIF de l'import conditionnel : si la branche stub était
      // retenue par erreur sous la VM, l'application ne persisterait RIEN et
      // aucun autre test ne le dirait — ils passent tous par le harnais, qui
      // construit `DocumentStoreFichier` directement.
      //
      // ⚠️ **Borne NM-8** : `getApplicationDocumentsDirectory` n'existe NI en
      // test hôte, NI en CI, NI sur le web ⇒ l'appel LÈVE ici. C'est
      // précisément ce qui DISCRIMINE les deux branches : la branche stub, elle,
      // rendrait paisiblement un `DocumentStoreStub`. **L'échec de l'appel est
      // donc la preuve que la branche IO a été retenue.**
      Object? capture;
      DocumentStore? rendu;
      try {
        rendu = await magasinDeLaPlateforme();
      } on Object catch (erreur) {
        capture = erreur;
      }
      expect(
        rendu,
        isNot(isA<DocumentStoreStub>()),
        reason: 'la branche STUB ne doit JAMAIS être retenue sous la VM',
      );
      expect(
        capture,
        isNotNull,
        reason:
            'la branche IO appelle path_provider, absent en test hôte — '
            'si rien ne lève, c’est que path_provider n’a pas été appelé',
      );
      expect(
        capture,
        isNot(isA<UnsupportedError>()),
        reason: 'un UnsupportedError signerait le STUB, pas path_provider',
      );
    });
  });

  group('le HARNAIS de test porte SON MUTANT (leçon NB-7)', () {
    // Un utilitaire de test peut mentir avec 112 tests verts. Les trois
    // mutants ci-dessous sont nommés, et chacun a son assertion tueuse.
    test(
      'MUTANT — `poser` qui écrirait ailleurs : le magasin ne lirait rien',
      () async {
        const contenu = '{"schemaVersion":2,"echeances":[]}';
        harnais.poser(contenu);
        expect(
          await harnais.magasin.lire(),
          estLu(contenu),
          reason: '`poser` et `lire` DOIVENT désigner le même fichier',
        );
      },
    );

    test(
      'MUTANT — `poserOctets` qui RÉ-ENCODERAIT : les octets relus diffèrent',
      () {
        // 🔴 Si `poserOctets` passait par `writeAsStringSync` (comme `poser`),
        // il produirait de l'UTF-8 VALIDE et le test de `B-1` deviendrait vert
        // pour la mauvaise raison — un harnais qui ne peut pas fabriquer
        // l'entrée fautive EFFACE la clause qu'il prétend vérifier.
        final fautif = documentNonDecodable();
        harnais.poserOctets(fautif);
        expect(
          harnais.octetsBruts(),
          fautif,
          reason: 'les octets sur le disque sont ceux posés, OCTET POUR OCTET',
        );
        expect(
          harnais.octetsBruts(),
          isNot(documentDecodable()),
          reason:
              'assertion de GRANDEUR : le document posé n’est PAS sa variante '
              'UTF-8 valide — sinon la paire de mutation ne mesurerait rien',
        );
      },
    );

    test('MUTANT — `octetsBrutsDe` doit désigner le fichier NOMMÉ', () {
      harnais.poser('CIBLE');
      expect(harnais.octetsBrutsDe(nomDocument), utf8.encode('CIBLE'));
      expect(
        harnais.octetsBrutsDe('$nomDocument.inexistant'),
        isNull,
        reason:
            'un accesseur qui rendrait toujours la cible masquerait une mise '
            'de côté au mauvais nom',
      );
    });

    test(
      'MUTANT — `octets` qui rendrait un cache : le disque fait foi',
      () async {
        await harnais.magasin.ecrire('AVANT');
        harnais.fichier.writeAsStringSync('APRES');
        expect(
          harnais.octets(),
          'APRES',
          reason:
              '`octets` doit RELIRE le disque, jamais rendre une valeur '
              'mémorisée à l’écriture',
        );
      },
    );

    test(
      'MUTANT — `fichiers` qui rendrait une liste vide passerait pour propre',
      () async {
        await harnais.magasin.ecrire('{"schemaVersion":2,"echeances":[]}');
        expect(harnais.fichiers(), isNotEmpty);
        expect(harnais.fichiers(), contains(nomDocument));
      },
    );
  });
}
