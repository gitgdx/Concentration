import 'dart:io';

import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/document_store.dart';
import 'package:concentration/features/echeances/data/document_store_io.dart';
import 'package:concentration/features/echeances/data/echeance_document_repository.dart';
import 'package:concentration/features/echeances/data/echeance_schema_migrations.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/domain/echeance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/magasin_temporaire.dart';

/// Décorateur qui **COMPTE les écritures** et délègue au magasin RÉEL.
///
/// 🔴 **R-6 exige un COMPTEUR D'APPELS, ⛔ pas une relecture du code** : un
/// runner qui migre **sans réécrire la version** boucle en silence, et aucune
/// assertion sur le contenu ne le verrait *(le contenu final serait le même à
/// chaque ouverture)*.
///
/// ⚠️ Ce n'est **PAS un magasin factice** : il n'implémente aucun comportement,
/// il **délègue tout**. Il vit hors de `test/e2e/**`, où ADR-010 §1 interdit
/// jusqu'aux décorateurs.
class MagasinCompteur implements DocumentStore {
  MagasinCompteur(this._delegue);

  final DocumentStore _delegue;
  int ecritures = 0;

  @override
  Future<LectureDocument> lire() => _delegue.lire();

  @override
  Future<void> ecrire(String contenu) {
    ecritures++;
    return _delegue.ecrire(contenu);
  }

  @override
  Future<void> mettreDeCote() => _delegue.mettreDeCote();
}

/// Décorateur dont **la seule mise de côté échoue**, tout le reste étant
/// délégué au magasin **RÉEL**.
///
/// ⚖️ **Pourquoi il existe alors que le test suivant fait échouer un `rename`
/// POUR DE VRAI** : celui-ci isole la **décision du DÉPÔT** de la plateforme —
/// il vaut sous Windows, sous POSIX et en CI **à l'identique**, quels que soient
/// les mécanismes d'échec de `rename` du système de fichiers hôte. ⛔ Il ne
/// remplace pas le test réel, il le **complète** : sans le test réel, rien ne
/// prouverait que la classe est **atteignable** ; sans celui-ci, la preuve
/// dépendrait d'un comportement de plateforme.
///
/// ⚠️ Comme `MagasinCompteur`, il vit **hors de `test/e2e/**`**, où ADR-010 §1
/// interdit jusqu'aux décorateurs.
class MagasinMiseDeCoteImpossible implements DocumentStore {
  MagasinMiseDeCoteImpossible(this._delegue);

  final DocumentStore _delegue;
  int tentatives = 0;

  @override
  Future<LectureDocument> lire() => _delegue.lire();

  @override
  Future<void> ecrire(String contenu) => _delegue.ecrire(contenu);

  @override
  Future<void> mettreDeCote() async {
    tentatives++;
    throw const FileSystemException('mise de côté impossible');
  }
}

void main() {
  late MagasinTemporaire harnais;

  setUp(() => harnais = MagasinTemporaire.creer());
  tearDown(() => harnais.nettoyer());

  // Les 3 échéances qu'exige le `.feature` d'AC-12, en version ANTÉRIEURE.
  const troisEnV1 =
      '{"schemaVersion":1,"echeances":['
      '{"id":"a1","description":"Convention","dateEcheance":"2027-03-15T22:59:00.000Z"},'
      '{"id":"a2","description":"Notaire","dateEcheance":"2027-06-02T07:00:00.000Z"},'
      '{"id":"a3","description":"Passeport","dateEcheance":"2027-09-10T21:00:00.000Z"}'
      ']}';

  EcheanceDocumentRepository depotSur(DocumentStore magasin) =>
      EcheanceDocumentRepository(magasin);

  group('AC-12 — migration : une seule fois, jamais destructive', () {
    test(
      '🔴 la migration s’exécute UNE SEULE FOIS (compteur d’appels)',
      () async {
        harnais.poser(troisEnV1);
        final compteur = MagasinCompteur(harnais.magasin);
        final depot = depotSur(compteur);

        expect(await depot.charger(), hasLength(3));
        expect(compteur.ecritures, 1, reason: 'la montée réécrit le document');
        expect(harnais.octets(), contains('"schemaVersion":2'));

        // Une INSTANCE NEUVE, comme à la réouverture de l'application.
        final apres = MagasinCompteur(harnais.magasin);
        expect(await depotSur(apres).charger(), hasLength(3));
        expect(
          apres.ecritures,
          0,
          reason:
              'un runner qui migre sans réécrire la version BOUCLE en '
              'silence — c’est ce que le compteur attrape',
        );
      },
    );

    test('les 3 échéances gardent description, date et heure', () async {
      harnais.poser(troisEnV1);
      final chargees = await depotSur(harnais.magasin).charger();
      expect(chargees.map((e) => e.description).toList()..sort(), [
        'Convention',
        'Notaire',
        'Passeport',
      ]);
      for (final e in chargees) {
        expect(e.dateEcheance.isUtc, isFalse, reason: 'AC-14 : date CIVILE');
      }
    });

    test('🔴 une migration INTERROMPUE laisse les OCTETS inchangés', () async {
      harnais.poser(troisEnV1);
      // Interruption RÉELLE : l'écriture atomique ne peut pas aboutir.
      harnais.bloquerEcriture();

      final chargees = await depotSur(harnais.magasin).charger();

      // Assertion SUR LES OCTETS, exigée par C-11.
      expect(
        harnais.octets(),
        troisEnV1,
        reason:
            'l’écriture atomique n’a jamais ouvert la cible ⇒ état '
            'antérieur strictement intact',
      );
      expect(
        chargees,
        hasLength(3),
        reason: 'aucune donnée perdue ni tronquée : elles restent lisibles',
      );
    });
  });

  group('AC-11 — l’illisible est mis de côté, JAMAIS supprimé', () {
    test('document entier illisible ⇒ mis de côté puis état vide', () async {
      harnais.poser('{ceci n est pas du JSON');
      expect(await depotSur(harnais.magasin).charger(), isEmpty);
      expect(harnais.octets(), isNull);
      expect(
        harnais.fichiers().single,
        startsWith('$nomDocument.illisible-'),
        reason: '⛔ jamais un delete',
      );
    });

    test(
      '`schemaVersion` absent ⇒ traité comme illisible, pas DEVINÉ',
      () async {
        // ⚖️ Règle laissée SANS AC par l'arbitrage du 2026-08-06 (voie b) —
        // couverte par ce test unitaire DÉCLARÉ.
        harnais.poser('{"echeances":[]}');
        expect(await depotSur(harnais.magasin).charger(), isEmpty);
        expect(
          harnais.fichiers().single,
          startsWith('$nomDocument.illisible-'),
        );
      },
    );

    test('un enregistrement illisible est ignoré, les valides restent', () async {
      harnais.poser(
        '{"schemaVersion":2,"echeances":['
        '{"id":"ok1","description":"Un","dateEcheance":"2027-03-15T23:59"},'
        '{"id":"","description":"cassee","dateEcheance":"2027-04-01T09:00"},'
        '{"id":"ok2","description":"Deux","dateEcheance":"2027-05-01T09:00"}]}',
      );
      final chargees = await depotSur(harnais.magasin).charger();
      expect(chargees.map((e) => e.id).toList(), ['ok1', 'ok2']);
      expect(
        harnais.fichiers(),
        [nomDocument],
        reason: '⛔ un enregistrement fautif n’est NI réécrit NI mis de côté',
      );
    });

    // -----------------------------------------------------------------------
    // 🔴 **B-1 — LE NIVEAU HONNÊTE, et il est BORNÉ ; la borne est écrite, pas
    // déguisée.** `main()` fait `await notifier.charger()` **avant `runApp`** :
    // c'est cet `await` qui empêchait l'application de démarrer.
    // ⛔ **`main()` n'est PAS exécutable en test hôte** — `path_provider` n'y
    // existe pas *(borne **NM-8**, entière)* ⇒ ce qui est prouvé ici est que
    // **`charger()` REND au lieu de LEVER**, sur le **magasin `io` de
    // production**. Que `runApp` s'exécute ensuite et que le hub se dresse
    // **reste non observé** ; ⛔ un magasin factice, lui, contournerait la garde
    // et rendrait ces tests **verts à tort**.
    // -----------------------------------------------------------------------

    test(
      '🔴 B-1 — un document NON DÉCODABLE : charger() REND l’état vide, et le '
      'fautif est CONSERVÉ OCTET POUR OCTET',
      () async {
        final fautif = documentNonDecodable();
        harnais.poserOctets(fautif);

        // ⛔ L'ASSERTION QUI PORTE TOUT : avant le correctif, cet appel LEVAIT
        // une FileSystemException ⇒ `runApp` n'était jamais atteint.
        expect(await depotSur(harnais.magasin).charger(), isEmpty);

        final misDeCote = harnais.fichiers().single;
        expect(
          misDeCote,
          startsWith('$nomDocument.illisible-'),
          reason: '⛔ JAMAIS un delete (AC-11 « Erreur »)',
        );
        expect(
          harnais.octetsBrutsDe(misDeCote),
          fautif,
          reason:
              'assertion SUR LES OCTETS : ni réécrit, ni réparé, ni tronqué — '
              '⛔ `allowMalformed` aurait figé la corruption ici',
        );
        expect(
          harnais.octetsBruts(),
          isNull,
          reason: 'la cible a bougé ⇒ l’application peut écrire de nouveau',
        );
      },
    );

    test('🔴 B-1 — la PERMANENCE est FERMÉE : le 2ᵉ démarrage aboutit et '
        'l’écriture redevient possible', () async {
      harnais.poserOctets(documentNonDecodable());
      expect(await depotSur(harnais.magasin).charger(), isEmpty);

      // Une INSTANCE NEUVE, comme à la RÉOUVERTURE de l'application. Avant le
      // correctif, la mise de côté n'était jamais atteinte ⇒ chaque démarrage
      // échouait à l'identique, ⛔ sans aucune issue depuis l'application.
      final depot = depotSur(harnais.magasin);
      expect(await depot.charger(), isEmpty);
      final reprise = await depot.creer(
        Echeance(
          id: 'apres',
          description: 'Reprise',
          dateEcheance: DateTime(2027, 12, 1, 23, 59),
        ),
      );
      expect(
        reprise.estReussi,
        isTrue,
        reason: 'sans mise de côté, l’écriture écraserait l’illisible',
      );
      expect(harnais.octets(), contains('"description":"Reprise"'));
    });

    test('🔴 CONTRÔLE NÉGATIF — le MÊME document en UTF-8 valide est CHARGÉ, '
        'et ⛔ AUCUN rename', () async {
      // Un seul octet diffère de la fixture ci-dessus, et le verdict BASCULE.
      harnais.poserOctets(documentDecodable());
      expect(await depotSur(harnais.magasin).charger(), hasLength(1));
      expect(
        harnais.fichiers(),
        [nomDocument],
        reason: '⛔ un document LISIBLE ne doit JAMAIS être mis de côté',
      );
    });

    // -----------------------------------------------------------------------
    // 🔴 **B-2 — UNE MISE DE CÔTÉ QUI ÉCHOUE NE DOIT PAS AUTORISER L'ÉCRITURE**
    // *(bloquant, audit sécurité du 2026-08-11)*.
    //
    // ⛔ **CETTE CLASSE N'AVAIT AUCUN TEST, et c'est ce qui l'a laissée
    // passer** : les 5 tests de `mettreDeCote` livrés jusqu'ici l'exerçaient
    // **dans son cas de SUCCÈS**, ou la faisaient lever **sur le stub, sans
    // passer par le dépôt** ⇒ ce que le dépôt fait d'un échec n'était **jamais
    // observé**. ⛔ Et la couverture ne pouvait pas le dire : le `catch` fautif
    // avait un **corps fait de commentaires**, donc **aucune ligne à
    // instrumenter** *(`NB-I`)*.
    // -----------------------------------------------------------------------

    test(
      '🔴 B-2 — mise de côté IMPOSSIBLE : charger() rend, l’écriture est '
      'REFUSÉE, et le document illisible est INTACT OCTET POUR OCTET',
      () async {
        final fautif = documentNonDecodable();
        harnais.poserOctets(fautif);
        final magasin = MagasinMiseDeCoteImpossible(harnais.magasin);
        final depot = depotSur(magasin);

        // ⛔ L'application s'ouvre quand même : `charger()` est `await`é AVANT
        // `runApp` (c'était `B-1`), donc elle ne doit pas lever ici non plus.
        expect(await depot.charger(), isEmpty);
        expect(magasin.tentatives, 1, reason: 'la mise de côté a été TENTÉE');

        final creation = await depot.creer(
          Echeance(
            id: 'ecrase',
            description: 'Saisie du pratiquant',
            dateEcheance: DateTime(2027, 12, 1, 23, 59),
          ),
        );

        // 🔴 L'ASSERTION QUI PORTE TOUT : avant le correctif, `estReussi` valait
        // `true` et les octets d'origine étaient DÉTRUITS à cet instant.
        expect(
          creation.estReussi,
          isFalse,
          reason:
              'le document illisible est TOUJOURS sur le disque : écrire '
              'l’écraserait, ce qu’AC-11 « Erreur » interdit littéralement',
        );
        expect(creation.acteEchoue, ActeEcriture.enregistrement);
        expect(
          harnais.octetsBruts(),
          fautif,
          reason:
              '⛔ ni réécrit, ni réparé, ni tronqué — assertion SUR LES OCTETS',
        );
        expect(
          harnais.fichiers(),
          [nomDocument],
          reason:
              '⛔ aucune copie `.illisible-` : rien n’a été déplacé, donc rien '
              'n’autorisait à écrire',
        );
      },
    );

    test(
      '🔴 CONTRÔLE NÉGATIF de B-2 — la MÊME séquence quand la mise de côté '
      'RÉUSSIT : le document est déplacé ET l’écriture est AUTORISÉE',
      () async {
        // ⛔ Sans ce contrôle, un dépôt qui refuserait TOUJOURS d’écrire
        // passerait le test ci-dessus.
        harnais.poserOctets(documentNonDecodable());
        final depot = depotSur(harnais.magasin);

        expect(await depot.charger(), isEmpty);
        final creation = await depot.creer(
          Echeance(
            id: 'apres',
            description: 'Reprise',
            dateEcheance: DateTime(2027, 12, 1, 23, 59),
          ),
        );

        expect(creation.estReussi, isTrue);
        expect(
          harnais.fichiers().where((n) => n.contains('.illisible-')),
          hasLength(1),
          reason:
              'le document fautif a bien été mis de côté, ⛔ jamais supprimé',
        );
        expect(harnais.octets(), contains('"description":"Reprise"'));
      },
    );

    test('🔴 B-2 sur le magasin de PRODUCTION — un `rename` qui ÉCHOUE POUR DE '
        'VRAI : l’écriture est refusée, puis elle REDEVIENT possible', () async {
      // ⚠️ **AUCUN MAGASIN FACTICE ICI** : l'échec vient de la boucle de
      // `mettreDeCote` du **code de production**, dont **tous** les noms de
      // destination sont occupés par des **répertoires** — un obstacle réel,
      // déterministe et réversible, de la même nature que celui qu'AC-17
      // emploie déjà pour l'écriture.
      //
      // 🔴 **CE DÉCLENCHEUR NE DÉPEND PAS DES CORRECTIFS DE `NB-F`/`NB-G`, et
      // c'était le piège** : avec la boucle AVEUGLE d'avant, le `rename`
      // partait **droit sur le répertoire** et levait ; avec la boucle
      // corrigée, il **épuise sa borne** et lève. **Les deux régimes échouent**
      // — vérifié par mutant, ⛔ pas supposé.
      final fige = MagasinTemporaire.creer(
        clock: FakeClock(DateTime(2026, 8, 11, 9)),
      );
      addTearDown(fige.nettoyer);
      final fautif = documentNonDecodable();
      fige.poserOctets(fautif);
      final obstacles = <Directory>[
        for (var rang = 0; rang < essaisMiseDeCote; rang++)
          Directory(fige.magasin.destinationMiseDeCote(rang))..createSync(),
      ];

      final depot = depotSur(fige.magasin);
      expect(
        await depot.charger(),
        isEmpty,
        reason: '⛔ l’application s’ouvre : `charger()` NE LÈVE PAS',
      );

      final refus = await depot.creer(
        Echeance(
          id: 'ecrase',
          description: 'Saisie du pratiquant',
          dateEcheance: DateTime(2027, 12, 1, 23, 59),
        ),
      );
      expect(refus.estReussi, isFalse);
      expect(
        fige.octetsBruts(),
        fautif,
        reason: 'les octets du pratiquant sont INTACTS — c’est tout l’enjeu',
      );

      // ✅ **L'ÉTAT N'EST PAS UN CUL-DE-SAC** : l'obstacle retiré, le
      // démarrage suivant met de côté et l'écriture redevient possible.
      for (final obstacle in obstacles) {
        obstacle.deleteSync();
      }
      final apres = depotSur(fige.magasin);
      expect(await apres.charger(), isEmpty);
      final reprise = await apres.creer(
        Echeance(
          id: 'apres',
          description: 'Reprise',
          dateEcheance: DateTime(2027, 12, 1, 23, 59),
        ),
      );
      expect(
        reprise.estReussi,
        isTrue,
        reason: 'le refus était CONDITIONNEL à l’obstacle, ⛔ pas permanent',
      );
      expect(
        fige.octetsBrutsDe(
          fige.magasin
              .destinationMiseDeCote(0)
              .split(Platform.pathSeparator)
              .last,
        ),
        fautif,
        reason: 'et le document fautif est mis de côté, OCTET POUR OCTET',
      );
    });

    test('🔴 un RÉSIDU survit à une création ET à une suppression', () async {
      harnais.poser(
        '{"schemaVersion":2,"echeances":['
        '{"id":"ok1","description":"Un","dateEcheance":"2027-03-15T23:59"},'
        '{"id":"","description":"cassee","dateEcheance":"2027-04-01T09:00"}]}',
      );
      final depot = depotSur(harnais.magasin);
      await depot.charger();

      await depot.creer(
        Echeance(
          id: 'neuve',
          description: 'Ajoutee',
          dateEcheance: DateTime(2027, 12, 1, 23, 59),
        ),
      );
      expect(harnais.octets(), contains('"description":"cassee"'));

      await depot.charger();
      await depot.supprimer('ok1');
      expect(
        harnais.octets(),
        contains('"description":"cassee"'),
        reason: 'MUTANT R-2 : un codec qui oublie les résidus tue ce test',
      );
      expect(harnais.octets(), isNot(contains('"id":"ok1"')));
    });
  });

  group('🔴 version FUTURE — état vide ET AUCUNE écriture, AUCUN rename', () {
    // ⚖️ Règle laissée SANS AC par l'arbitrage du 2026-08-06 (voie b).
    final futur =
        '{"schemaVersion":${versionCourante + 1},"echeances":['
        '{"id":"f","description":"venue du futur","dateEcheance":"2027-03-15T23:59"}]}';

    test('le document est laissé STRICTEMENT INTACT', () async {
      harnais.poser(futur);
      expect(await depotSur(harnais.magasin).charger(), isEmpty);
      expect(
        harnais.octets(),
        futur,
        reason:
            'un document de version future est PARFAITEMENT VALIDE pour la '
            'version qui l’a écrit — le déplacer serait destructeur EN EFFET',
      );
      expect(harnais.fichiers(), [nomDocument], reason: '⛔ aucun rename');
    });

    test('toute écriture ultérieure est REFUSÉE, jamais tentée', () async {
      harnais.poser(futur);
      final depot = depotSur(harnais.magasin);
      await depot.charger();
      final resultat = await depot.creer(
        Echeance(
          id: 'x',
          description: 'x',
          dateEcheance: DateTime(2027, 12, 1, 23, 59),
        ),
      );
      expect(resultat.estReussi, isFalse);
      expect(harnais.octets(), futur, reason: '⛔ le document n’est pas écrasé');
    });
  });

  group('écritures — succès, effets sur les octets, et refus TYPÉ', () {
    Echeance e(String id, String description) => Echeance(
      id: id,
      description: description,
      dateEcheance: DateTime(2027, 3, 15, 23, 59),
    );

    test(
      'aucun fichier ⇒ état vide, et ⛔ RIEN n’est écrit avant un geste',
      () async {
        expect(await depotSur(harnais.magasin).charger(), isEmpty);
        expect(harnais.octets(), isNull);
        expect(harnais.fichiers(), isEmpty);
      },
    );

    test(
      'creer / remplacer / supprimer aboutissent et touchent le disque',
      () async {
        final depot = depotSur(harnais.magasin);
        await depot.charger();

        expect((await depot.creer(e('a', 'Avant'))).estReussi, isTrue);
        expect(harnais.octets(), contains('"description":"Avant"'));

        await depot.charger();
        expect((await depot.remplacer(e('a', 'Apres'))).estReussi, isTrue);
        expect(harnais.octets(), contains('"description":"Apres"'));
        expect(harnais.octets(), isNot(contains('Avant')));

        await depot.charger();
        expect((await depot.supprimer('a')).estReussi, isTrue);
        expect(harnais.octets(), '{"schemaVersion":2,"echeances":[]}');
      },
    );

    test('🔴 échec d’écriture ⇒ refus TYPÉ portant le BON acte', () async {
      final depot = depotSur(harnais.magasin);
      await depot.charger();
      await depot.creer(e('a', 'Presente'));
      await depot.charger();
      final avant = harnais.octets();

      harnais.bloquerEcriture();

      final creation = await depot.creer(e('b', 'Refusee'));
      expect(creation.estReussi, isFalse);
      expect(creation.acteEchoue, ActeEcriture.enregistrement);

      final suppression = await depot.supprimer('a');
      expect(suppression.estReussi, isFalse);
      expect(
        suppression.acteEchoue,
        ActeEcriture.suppression,
        reason:
            'DEUX textes, pas un : l’utilisateur doit savoir CE QUI n’a '
            'pas eu lieu (Design UX §14.5)',
      );

      // 🔴 L'assertion qui porte tout : le DISQUE n'a pas bougé.
      expect(harnais.octets(), avant);
      expect(harnais.octets(), isNot(contains('Refusee')));
      expect(harnais.octets(), contains('Presente'));
    });

    test(
      'l’écriture REDEVIENT possible quand le stockage se débloque',
      () async {
        final depot = depotSur(harnais.magasin);
        await depot.charger();
        harnais.bloquerEcriture();
        expect((await depot.creer(e('a', 'Essai'))).estReussi, isFalse);

        harnais.debloquerEcriture();
        expect(
          (await depot.creer(e('a', 'Essai'))).estReussi,
          isTrue,
          reason:
              'le blocage est RÉVERSIBLE — c’est ce que le 2ᵉ scénario '
              'd’AC-17 exige littéralement',
        );
        expect(harnais.octets(), contains('Essai'));
      },
    );

    test('⛔ écrire AVANT tout chargement est refusé', () async {
      // Écrire ici ÉCRASERAIT un document qu'on n'a pas su lire.
      final resultat = await depotSur(harnais.magasin).creer(e('a', 'x'));
      expect(resultat.estReussi, isFalse);
      expect(harnais.octets(), isNull);
    });

    test('🔴 NB-B — un refus AVANT chargement porte l’acte RÉEL, ⛔ pas '
        '« enregistrement » en dur', () async {
      // ⚠️ **LA BRANCHE EST ATTEIGNABLE, et c'est mesuré ici, ⛔ pas simulé
      // par un fake** : sans chargement préalable, `_document` est `null` —
      // c'est le chemin de la revue de code (`NB-B`). Le deuxième porteur du
      // même chemin est un document de version FUTURE.
      final depot = depotSur(harnais.magasin);

      final suppression = await depot.supprimer('a');
      expect(suppression.estReussi, isFalse);
      expect(
        suppression.acteEchoue,
        ActeEcriture.suppression,
        reason:
            'avant le correctif, une SUPPRESSION refusée annonçait « '
            'L’échéance n’a pas été enregistrée. » — le port exige DEUX '
            'textes : l’utilisateur doit savoir CE QUI n’a pas eu lieu',
      );

      // ⛔ CONTRÔLE NÉGATIF : l'autre acte, sur la MÊME branche, ne doit PAS
      // avoir basculé — sinon le correctif aurait juste inversé l'erreur.
      final creation = await depot.creer(e('a', 'x'));
      expect(creation.acteEchoue, ActeEcriture.enregistrement);
      expect(
        creation.acteEchoue,
        isNot(suppression.acteEchoue),
        reason:
            'assertion de GRANDEUR : les deux actes doivent DIFFÉRER sur la '
            'même branche, sinon un message unique passerait',
      );
    });

    test(
      '🔴 NB-B — même refus sur un document de version FUTURE : la suppression '
      'dit « suppression »',
      () async {
        // Le second porteur de la branche `document == null`, celui-ci ATTEINT
        // par un chargement réel — ⛔ aucun fake, aucun accès à l'état privé.
        harnais.poser(
          '{"schemaVersion":${versionCourante + 1},"echeances":['
          '{"id":"f","description":"venue du futur",'
          '"dateEcheance":"2027-03-15T23:59"}]}',
        );
        final depot = depotSur(harnais.magasin);
        await depot.charger();

        final suppression = await depot.supprimer('f');
        expect(suppression.acteEchoue, ActeEcriture.suppression);
        expect(
          suppression.message,
          ActeEcriture.suppression.messageEchec,
          reason: '⛔ le texte se LIT dans l’enum, jamais recopié dans un test',
        );
      },
    );

    test(
      '⚖️ NB-A — `remplacer` SANS correspondance d’id : le document est réécrit '
      'À L’IDENTIQUE et le résultat est un SUCCÈS',
      () async {
        // Ce test ÉPINGLE le contrat tranché le 2026-08-07 : la doc du port
        // promettait un « échec » que l'implémentation n'a jamais rendu, et les
        // deux exemplaires de la règle avaient DÉJÀ divergé. ⛔ Sans lui, rien
        // n'empêcherait la doc et le code de re-divergér.
        //
        // ⚠️ Le chemin est INATTEIGNABLE depuis l'IHM (une édition part toujours
        // d'une échéance listée) : il s'exerce donc au PORT, jamais par un
        // scénario — un refus pour une entrée que le produit ne peut pas
        // produire serait une clause sans surface.
        final depot = depotSur(harnais.magasin);
        await depot.charger();
        expect((await depot.creer(e('present', 'Présente'))).estReussi, isTrue);
        await depot.charger();
        final avant = harnais.octets();

        final resultat = await depot.remplacer(e('ABSENT', 'Fantome'));

        expect(
          resultat.estReussi,
          isTrue,
          reason: 'contrat RÉEL du port, désormais écrit tel qu’il est',
        );
        expect(
          harnais.octets(),
          avant,
          reason: 'réécrit À L’IDENTIQUE : ⛔ rien n’est ajouté ni perdu',
        );
        expect(harnais.octets(), isNot(contains('Fantome')));
        expect(
          harnais.octets(),
          contains('"description":"Présente"'),
          reason: 'l’échéance existante est intacte',
        );
      },
    );
  });
}
