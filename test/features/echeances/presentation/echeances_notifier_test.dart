import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/echeance_document_repository.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/domain/validation_echeance.dart';
import 'package:concentration/features/echeances/presentation/echeances_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/magasin_temporaire.dart';

/// La source de vérité (T8) — adossée au **dépôt RÉEL**, sur de **vrais
/// octets** : ⛔ aucun faux dépôt, même hors `test/e2e/**`.
void main() {
  final maintenant = DateTime(2026, 8, 6, 8);
  late MagasinTemporaire harnais;
  late EcheancesNotifier notifier;
  late int notifications;

  String jjmmaaaa(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year.toString().padLeft(4, '0')}';

  final dansTroisMois = jjmmaaaa(
    DateTime(maintenant.year, maintenant.month + 3, maintenant.day),
  );

  setUp(() {
    harnais = MagasinTemporaire.creer();
    notifier = EcheancesNotifier(
      depot: EcheanceDocumentRepository(harnais.magasin),
      clock: FakeClock(maintenant),
    );
    notifications = 0;
    notifier.addListener(() => notifications++);
  });

  tearDown(() {
    notifier.dispose();
    harnais.nettoyer();
  });

  Future<RefusValidation?> creer([String description = 'Convention']) =>
      notifier.creer(description: description, date: dansTroisMois, heure: '');

  group('I-1 — on RECHARGE, on ne mute pas', () {
    test('la liste exposée est NON MODIFIABLE', () async {
      await notifier.charger();
      await creer();
      expect(notifier.echeances, hasLength(1));
      expect(
        () => notifier.echeances.add(notifier.echeances.first),
        throwsUnsupportedError,
        reason:
            'ChangeNotifier n’offre AUCUNE garantie d’immuabilité : '
            'c’est à l’implémentation de la tenir',
      );
    });

    test(
      'après une création, l’état vient du DISQUE, pas de la mémoire',
      () async {
        await notifier.charger();
        await creer('Depuis le disque');
        // ⚠️ Assertion de GRANDEUR : l'id attribué se retrouve DANS LE FICHIER.
        expect(harnais.octets(), contains(notifier.echeances.single.id));
        expect(harnais.octets(), contains('Depuis le disque'));
      },
    );
  });

  group('chaque opération notifie EXACTEMENT une fois', () {
    test('charger notifie une fois', () async {
      await notifier.charger();
      expect(notifications, 1);
    });

    test('creer, modifier, supprimer notifient une fois CHACUNE', () async {
      await notifier.charger();
      notifications = 0;

      expect(await creer(), isNull);
      expect(notifications, 1);

      expect(
        await notifier.modifier(
          notifier.echeances.single,
          description: 'Corrigee',
          date: dansTroisMois,
          heure: '',
        ),
        isNull,
      );
      expect(notifications, 2);

      expect(await notifier.supprimer(notifier.echeances.single.id), isNull);
      expect(notifications, 3);
      expect(notifier.echeances, isEmpty);
    });
  });

  group('un REFUS ne notifie pas et n’écrit RIEN', () {
    test('refus de validation : 0 notification, 0 octet', () async {
      await notifier.charger();
      notifications = 0;
      final avant = harnais.octets();

      final refus = await creer('');
      expect(refus, isNotNull);
      expect(refus!.champ, ChampEcheance.description);
      expect(notifications, 0, reason: 'rien n’a changé, rien n’est annoncé');
      expect(harnais.octets(), avant);
      expect(notifier.echeances, isEmpty);
    });

    test(
      '🔴 échec d’ÉCRITURE : 0 notification, et l’écran ne MENT pas',
      () async {
        await notifier.charger();
        notifications = 0;
        harnais.bloquerEcriture();

        final refus = await creer('Jamais enregistree');
        expect(refus, isNotNull);
        // 3ᵉ ancrage : au PIED DE L'ACTION — aucun champ n'est fautif.
        expect(refus!.champ, ChampEcheance.action);
        expect(
          notifier.echeances,
          isEmpty,
          reason: '⛔ AUCUNE mise à jour optimiste : la création n’apparaît pas',
        );
        expect(notifications, 0);
        expect(harnais.octets(), isNull);
      },
    );

    test('🔴 une SUPPRESSION qui échoue laisse l’échéance en place', () async {
      await notifier.charger();
      await creer('Toujours la');
      final id = notifier.echeances.single.id;
      final avant = harnais.octets();

      harnais.bloquerEcriture();
      final refus = await notifier.supprimer(id);

      expect(refus, isNotNull);
      expect(refus!.champ, ChampEcheance.action);
      expect(notifier.echeances, hasLength(1));
      expect(harnais.octets(), avant);
    });

    test('les DEUX messages d’échec DIFFÈRENT selon l’acte', () async {
      await notifier.charger();
      await creer('Presente');
      final id = notifier.echeances.single.id;
      harnais.bloquerEcriture();

      final creation = await creer('Autre');
      final suppression = await notifier.supprimer(id);
      expect(creation!.message, isNot(suppression!.message));
      // ⛔ Aucun de ces textes n'est écrit ici : ils viennent du port (U-5).
      expect(creation.message, isNotEmpty);
      expect(suppression.message, isNotEmpty);
    });

    test(
      'l’écriture aboutit dès que le stockage redevient inscriptible',
      () async {
        await notifier.charger();
        harnais.bloquerEcriture();
        expect(await creer('Deuxieme essai'), isNotNull);

        harnais.debloquerEcriture();
        expect(await creer('Deuxieme essai'), isNull);
        expect(notifier.echeances, hasLength(1));
      },
    );
  });

  group('la validation est celle du domaine, pas une copie', () {
    test('la limite de 9 est appliquée à la création', () async {
      await notifier.charger();
      for (var i = 0; i < 9; i++) {
        expect(await creer('Echeance $i'), isNull);
      }
      final dixieme = await creer('La dixieme');
      expect(dixieme, isNotNull);
      expect(dixieme!.champ, ChampEcheance.formulaire);
      expect(notifier.echeances, hasLength(9));
    });

    test(
      'le refus d’éditer une échue est accessible avant tout formulaire',
      () {
        final echue = Echeance(
          id: 'e',
          description: 'Passee',
          dateEcheance: maintenant.subtract(const Duration(days: 1)),
        );
        expect(notifier.validation.refusEditionEchue(echue), isNotNull);
      },
    );
  });
}
