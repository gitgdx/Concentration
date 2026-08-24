import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/echeance_document_codec.dart';
import 'package:concentration/features/echeances/data/echeance_document_repository.dart';
import 'package:concentration/features/echeances/data/echeance_schema_migrations.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/domain/echeance_etat.dart';
import 'package:concentration/features/echeances/domain/echeance_repository.dart';
import 'package:concentration/features/echeances/domain/validation_echeance.dart';
import 'package:concentration/features/echeances/presentation/echeances_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/magasin_temporaire.dart';

/// **T4 — le port, le 3ᵉ acte, et `retirer` de bout en bout** *(US-01.4)*.
///
/// 🔴 **LES TROIS ASSERTIONS ÉLIMINATOIRES du Story File sont ici** :
/// ⓵ une écriture **bloquée** ⇒ la tuile **ne disparaît PAS** et **le disque est
/// inchangé** ; ⓶ le refus **n'est pas `void`** ; ⓷ **`presentes` et la limite
/// lisent le MÊME filtre**.
///
/// ⛔ **Le magasin est RÉEL** *(fichier temporaire)* et l'échec d'écriture est
/// une `FileSystemException` **émise par le système de fichiers** — ⛔ aucun
/// magasin factice, aucun mock, aucune injection : le chemin traversé est
/// **exactement** celui de l'appareil.
void main() {
  late MagasinTemporaire harnais;

  setUp(() => harnais = MagasinTemporaire.creer());
  tearDown(() => harnais.nettoyer());

  final horloge = FakeClock(DateTime(2026, 8, 24, 12));

  Echeance e(String id, String description, {int jours = 30}) => Echeance(
    id: id,
    description: description,
    dateEcheance: horloge.now().add(Duration(days: jours)),
  );

  EcheanceDocumentRepository depot() =>
      EcheanceDocumentRepository(harnais.magasin);

  /// Un document **à la version courante**, écrit par le codec de production.
  /// ⛔ La version se **LIT**, jamais recopiée.
  void poser(List<Echeance> echeances) {
    const codec = EcheanceDocumentCodec();
    harnais.poser(
      codec.encoder(codec.documentNeuf(versionCourante), echeances),
    );
  }

  group('ADR-012 §6 — le TEXTE du 3ᵉ acte, et les DEUX propriétés', () {
    test('le 3ᵉ acte existe et porte LE texte du Design UX (U-1)', () {
      expect(ActeEcriture.values, hasLength(3));
      expect(
        ActeEcriture.retrait.messageEchec,
        "L'échéance n'a pas été retirée de la grille.",
      );
    });

    test(
      '🔴 les trois messages : DISTINCTS **et** aucun SOUS-CHAÎNE d’un autre',
      () {
        // ✅ Le contrôle porte les DEUX propriétés, comme le recommande le Design
        // UX §4.1 : « distincts » SEUL laisserait passer un futur
        // « L'échéance n'a pas été enregistrée. » / « … enregistrée. » — et c'est
        // exactement la famille de `NB-B`.
        final messages = ActeEcriture.values
            .map((a) => a.messageEchec)
            .toList(growable: false);
        expect(
          messages.toSet(),
          hasLength(messages.length),
          reason: 'deux à deux DISTINCTS',
        );
        for (final a in messages) {
          for (final b in messages) {
            if (a == b) continue;
            expect(
              a.contains(b),
              isFalse,
              reason: '« $b » est une SOUS-CHAÎNE de « $a »',
            );
          }
        }
        // ⛔ CONTRÔLE NÉGATIF : le contrôle sait rougir. Deux messages dont l'un
        // est sous-chaîne de l'autre DOIVENT le faire échouer — sinon la boucle
        // ci-dessus serait vraie par vacuité.
        const fautifs = ['Rien ne va.', 'ne va.'];
        expect(fautifs.first.contains(fautifs.last), isTrue);
      },
    );

    test('un échec de RETRAIT porte le message du RETRAIT, ⛔ pas un autre', () {
      const echec = ResultatEcriture.echec(ActeEcriture.retrait);
      expect(echec.estReussi, isFalse);
      expect(echec.message, ActeEcriture.retrait.messageEchec);
      // C'est le cœur de `NB-B` : l'utilisateur doit savoir CE QUI n'a pas eu
      // lieu.
      expect(echec.message, isNot(ActeEcriture.enregistrement.messageEchec));
      expect(echec.message, isNot(ActeEcriture.suppression.messageEchec));
    });
  });

  group('C-8 — `retirer(String id)` par le MÊME `_ecrire`', () {
    test(
      'le retrait écrit `"retiree":true` et NE TOUCHE À RIEN D’AUTRE',
      () async {
        poser([e('a1', 'Convention'), e('a2', 'Notaire', jours: 60)]);
        final d = depot();
        await d.charger();

        final resultat = await d.retirer('a1');
        // ⓶ ASSERTION ÉLIMINATOIRE — le refus n'est PAS `void` : on LIT le
        // résultat, et il est typé.
        expect(resultat, isA<ResultatEcriture>());
        expect(resultat.estReussi, isTrue);
        expect(resultat.acteEchoue, isNull);

        final octets = harnais.octets()!;
        expect(octets, contains('"retiree":true'));
        // ⛔ Description et date INTACTES, et l'autre entrée n'a RIEN gagné.
        expect(octets, contains('"description":"Convention"'));
        expect(octets, contains('"description":"Notaire"'));
        expect(
          RegExp('"retiree"').allMatches(octets).length,
          1,
          reason: 'UNE seule entrée est retirée',
        );

        // Relecture par le dépôt de production : l'échéance est CONSERVÉE.
        final relues = await depot().charger();
        expect(relues, hasLength(2), reason: '⛔ ce n’est PAS une suppression');
        expect(relues.firstWhere((x) => x.id == 'a1').retiree, isTrue);
        expect(
          relues.firstWhere((x) => x.id == 'a1').description,
          'Convention',
        );
        expect(presentesSurLaGrille(relues).map((x) => x.id), <String>['a2']);
      },
    );

    test(
      '🔴 LA MISE À JOUR PERDUE — ce que `retirer(String id)` rend IMPOSSIBLE',
      () async {
        // Le motif d'ADR-012 §6, MESURÉ au lieu d'être affirmé. L'appelant
        // détient une entité PÉRIMÉE ; le produit a déjà changé la description.
        poser([e('a1', 'Ancienne description')]);
        final d = depot();
        final perimee = (await d.charger()).single;
        expect(
          (await d.remplacer(perimee.avec(description: 'A JOUR'))).estReussi,
          isTrue,
        );

        // ✅ Le port réel : on ne peut PAS lui passer l'entité périmée.
        await d.charger();
        expect((await d.retirer('a1')).estReussi, isTrue);
        final apres = (await depot().charger()).single;
        expect(apres.retiree, isTrue);
        expect(
          apres.description,
          'A JOUR',
          reason: 'aucun autre champ ne peut être écrasé par un retrait',
        );

        // ⛔ LE MUTANT, JOUÉ : ce qu'aurait fait `retirer(Echeance)` en
        // réutilisant l'entité de l'appelant. La mise à jour est PERDUE, et
        // ⛔ SILENCIEUSEMENT — le résultat est un SUCCÈS.
        await d.charger();
        final commeSiEntite = await d.remplacer(perimee.avec(retiree: true));
        expect(commeSiEntite.estReussi, isTrue, reason: 'succès… trompeur');
        expect(
          (await depot().charger()).single.description,
          'Ancienne description',
          reason:
              '🔴 VOILÀ la mise à jour perdue silencieuse : c’est POUR CELA que '
              'la signature prend un `id` et non une entité',
        );
      },
    );

    test('sans correspondance d’`id` : SUCCÈS, document inchangé', () async {
      poser([e('a1', 'Convention')]);
      final d = depot();
      await d.charger();
      final avant = harnais.octets();
      expect((await d.retirer('inconnu')).estReussi, isTrue);
      expect(harnais.octets(), avant);
    });

    test(
      'retirer DEUX FOIS est idempotent — succès, aucun changement',
      () async {
        poser([e('a1', 'Convention')]);
        final d = depot();
        await d.charger();
        expect((await d.retirer('a1')).estReussi, isTrue);
        final apresUn = harnais.octets();
        await d.charger();
        expect((await d.retirer('a1')).estReussi, isTrue);
        expect(harnais.octets(), apresUn);
      },
    );
  });

  group('🔴 ⓵ ÉCRITURE BLOQUÉE — la tuile RESTE et le disque est INCHANGÉ', () {
    test('refus TYPÉ portant `retrait`, octets identiques', () async {
      poser([e('a1', 'Convention'), e('a2', 'Notaire', jours: 60)]);
      final d = depot();
      await d.charger();
      final avant = harnais.octets()!;

      harnais.bloquerEcriture();
      final refus = await d.retirer('a1');

      // Le refus est TYPÉ et porte le BON acte.
      expect(refus.estReussi, isFalse);
      expect(refus.acteEchoue, ActeEcriture.retrait);
      expect(refus.message, ActeEcriture.retrait.messageEchec);
      // ⛔ OCTET POUR OCTET inchangé : rien n'a été écrit.
      expect(harnais.octets(), avant);
      expect(avant, isNot(contains('retiree')));

      // ⛔ AUCUNE mise à jour optimiste : l'échéance est TOUJOURS présente.
      harnais.debloquerEcriture();
      final relues = await depot().charger();
      expect(presentesSurLaGrille(relues).map((x) => x.id), <String>[
        'a1',
        'a2',
      ]);
    });

    test('✅ et c’est RÉVERSIBLE : le réessai aboutit', () async {
      poser([e('a1', 'Convention')]);
      final d = depot();
      await d.charger();
      harnais.bloquerEcriture();
      expect((await d.retirer('a1')).estReussi, isFalse);
      harnais.debloquerEcriture();
      expect(
        (await d.retirer('a1')).estReussi,
        isTrue,
        reason: '⛔ pas de « tuile encore là mais geste mort »',
      );
      expect(harnais.octets(), contains('"retiree":true'));
    });
  });

  group('🔴 ⓷ C-7 — `presentes` et la LIMITE lisent le MÊME filtre', () {
    Future<EcheancesNotifier> notifier() async {
      final n = EcheancesNotifier(depot: depot(), clock: horloge);
      await n.charger();
      return n;
    }

    test('9 présentes ⇒ création REFUSÉE ; une retirée ⇒ ACCEPTÉE', () async {
      // ⛔ Le nombre 9 ne s'écrit PAS à la main : il se LIT dans la règle.
      final max = ValidationEcheance.maxPresentesSurGrille;
      poser([
        for (var i = 0; i < max; i++) e('a$i', 'Echeance $i', jours: 10 + i),
      ]);
      final n = await notifier();
      expect(n.presentes, hasLength(max));
      expect(n.echeances, hasLength(max));

      final refus = await n.creer(
        description: 'La dixieme',
        date: '31/12/2027',
        heure: '',
      );
      expect(refus, isNotNull, reason: 'la limite est atteinte');

      // On RETIRE une échéance : une place se libère.
      expect(await n.retirer('a0'), isNull);
      expect(
        n.presentes,
        hasLength(max - 1),
        reason: 'la grille en montre une de moins',
      );
      expect(
        n.echeances,
        hasLength(max),
        reason: '⛔ la GESTION, elle, les liste TOUTES (AC-7)',
      );

      // 🔴 LE MUTANT que cette paire d'assertions tue : filtrer dans la GRILLE
      // au lieu du getter unique ⇒ 8 tuiles affichées ET création refusée.
      expect(
        await n.creer(description: 'La dixieme', date: '31/12/2027', heure: ''),
        isNull,
        reason:
            '🔴 si la limite lisait `echeances` et la grille `presentes`, la '
            'création resterait REFUSÉE avec 8 tuiles à l’écran',
      );
    });

    test('un refus de retrait NE LIBÈRE AUCUNE place', () async {
      final max = ValidationEcheance.maxPresentesSurGrille;
      poser([
        for (var i = 0; i < max; i++) e('a$i', 'Echeance $i', jours: 10 + i),
      ]);
      final n = await notifier();
      harnais.bloquerEcriture();
      final refus = await n.retirer('a0');
      // ⓶ Le notifier rend un REFUS NOMMÉ, ⛔ jamais `void`, ⛔ jamais un booléen.
      expect(refus, isNotNull);
      expect(refus!.champ, ChampEcheance.action);
      // ⛔ Le message est celui du PORT, en UN exemplaire — ⛔ pas réécrit ici.
      expect(refus.message, ActeEcriture.retrait.messageEchec);
      expect(
        n.presentes,
        hasLength(max),
        reason: '⛔ AUCUNE mise à jour optimiste',
      );
      harnais.debloquerEcriture();
    });
  });

  group('AC-5 « Erreur » — ASSERTÉE, ⛔ pas seulement « par construction »', () {
    test('🔴 un document ANTÉRIEUR sans aucune clé `retiree` : AUCUNE tuile ne '
        'disparaît après migration', () async {
      // Le contre-exemple nommé : « un document `v2` existant dont une tuile
      // disparaît après migration ». Ce document est celui de TOUT le parc
      // installé — il ne porte la clé NULLE PART.
      const v2 =
          '{"schemaVersion":2,"echeances":['
          '{"id":"a1","description":"Convention","dateEcheance":"2027-03-15T23:59"},'
          '{"id":"a2","description":"Notaire","dateEcheance":"2027-06-02T09:00"},'
          '{"id":"a3","description":"Passeport","dateEcheance":"2027-09-10T23:00"}]}';
      expect(v2, isNot(contains('retiree')));

      harnais.poser(v2);
      final chargees = await depot().charger();

      expect(chargees, hasLength(3));
      // ⛔ L'ABSENCE de clé signifie « PRÉSENTE » : les trois sont sur la
      // grille, et aucune n'a été retirée d'office.
      expect(presentesSurLaGrille(chargees), hasLength(3));
      expect(chargees.every((x) => !x.retiree), isTrue);
      // Le document a été migré et réécrit, et il ne porte TOUJOURS aucune
      // clé `retiree` : le `up` n'ajoute rien.
      final apres = harnais.octets()!;
      expect(apres, contains('"schemaVersion":$versionCourante'));
      expect(apres, isNot(contains('retiree')));
    });
  });
}
