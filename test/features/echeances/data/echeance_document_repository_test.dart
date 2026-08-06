import 'package:concentration/features/echeances/data/document_store.dart';
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
  Future<String?> lire() => _delegue.lire();

  @override
  Future<void> ecrire(String contenu) {
    ecritures++;
    return _delegue.ecrire(contenu);
  }

  @override
  Future<void> mettreDeCote() => _delegue.mettreDeCote();
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
  });
}
