import 'dart:io';

import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/document_store.dart';
import 'package:concentration/features/echeances/data/document_store_plateforme.dart';
import 'package:concentration/features/echeances/data/document_store_stub.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/magasin_temporaire.dart';

/// Le magasin de plateforme (T6) — **de VRAIS octets sur un VRAI disque**.
void main() {
  late MagasinTemporaire harnais;

  setUp(() => harnais = MagasinTemporaire.creer());
  tearDown(() => harnais.nettoyer());

  group('DocumentStoreFichier — écriture ATOMIQUE, lecture, mise de côté', () {
    test('aucun fichier ⇒ lire() rend null (c’est `v0`)', () async {
      expect(await harnais.magasin.lire(), isNull);
    });

    test('écrire puis relire rend LES MÊMES OCTETS', () async {
      const contenu = '{"schemaVersion":2,"echeances":[]}';
      await harnais.magasin.ecrire(contenu);
      expect(await harnais.magasin.lire(), contenu);
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
        isNull,
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
        expect(await harnais.magasin.lire(), origine);
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

  group('R-15 — le STUB est importé DIRECTEMENT par un test', () {
    // ⛔ Se contenter de l'import conditionnel le rendrait INVISIBLE à la
    // couverture : un fichier de `lib/` non importé par un test n'entre pas au
    // dénominateur, donc il pourrait être faux sans qu'on le sache.
    const stub = DocumentStoreStub();

    test('lire() rend null — la plateforme ne stocke rien', () async {
      expect(await stub.lire(), isNull);
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
          contenu,
          reason: '`poser` et `lire` DOIVENT désigner le même fichier',
        );
      },
    );

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
