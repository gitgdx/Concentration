import 'dart:io';

import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/domain/echeance_etat.dart';
import 'package:flutter_test/flutter_test.dart';

/// **T2** — `retiree` sur l'entité, et le filtre « présentes » *(US-01.4)*.
///
/// 🔴 **TESTS UNITAIRES DÉCLARÉS** *(§A-2, voie (b) du 2026-08-24)* : les règles
/// éprouvées ici sont des **contrats internes** — `retiree` non booléen,
/// `retiree: null`, `retiree: false` licite. ⛔ **Elles n'ont AUCUN AC et ne
/// doivent PAS en avoir un** : leur donner un scénario rendrait le couple
/// `.feature ↔ tests` incohérent, et `null` n'est pas une règle nouvelle mais
/// une **lecture** de la règle d'ADR-012 §3.
void main() {
  Echeance e({
    String id = 'a1',
    String description = 'Convention',
    bool retiree = false,
  }) => Echeance(
    id: id,
    description: description,
    dateEcheance: DateTime(2027, 3, 15, 23, 59),
    retiree: retiree,
  );

  group('ADR-012 §1 — le champ, et ce qu’il touche', () {
    test('le défaut est `false` : une échéance naît PRÉSENTE', () {
      expect(
        Echeance(
          id: 'a1',
          description: 'x',
          dateEcheance: DateTime(2027),
        ).retiree,
        isFalse,
      );
    });

    test('`retiree` EST dans l’égalité et dans le hashCode', () {
      expect(e(retiree: true), isNot(e()));
      expect(e(retiree: true).hashCode, isNot(e().hashCode));
      expect(e(retiree: true), e(retiree: true));
      expect(e(retiree: true).hashCode, e(retiree: true).hashCode);
    });

    test('⛔ `compareTo` est INCHANGÉ : le retrait ne touche pas l’ORDRE', () {
      // Le mutant à tuer : faire entrer `retiree` dans le comparateur. Il
      // changerait le tri de la grille ET le sens d'AC-6 « Erreur » d'US-01.1
      // sans qu'aucun AC ne le demande.
      final tot = Echeance(
        id: 'a1',
        description: 'x',
        dateEcheance: DateTime(2027),
        retiree: true,
      );
      final tard = Echeance(
        id: 'a2',
        description: 'x',
        dateEcheance: DateTime(2028),
      );
      expect(tot.compareTo(tard), lessThan(0));
      expect(
        tot.compareTo(tard.avec(retiree: true)),
        lessThan(0),
        reason: 'le retrait ne déplace RIEN dans l’ordre',
      );
      // À date ET id égaux, deux états de retrait différents se comparent à 0 :
      // l'ordre ne voit pas le champ.
      expect(e(retiree: true).compareTo(e()), 0);
    });
  });

  group('ADR-012 §1 — `avec()` : `null` = INCHANGÉ, jamais « effacé »', () {
    test('`avec()` sans argument CONSERVE le retrait', () {
      expect(e(retiree: true).avec(description: 'Autre').retiree, isTrue);
      expect(
        e().avec(description: 'Autre').retiree,
        isFalse,
        reason: 'et l’absence de retrait est conservée elle aussi',
      );
    });

    test('`avec(retiree: true)` retire ; `avec(retiree: false)` remet', () {
      expect(e().avec(retiree: true).retiree, isTrue);
      expect(e(retiree: true).avec(retiree: false).retiree, isFalse);
    });

    test('`avec()` ne touche à AUCUN autre champ', () {
      final retiree = e().avec(retiree: true);
      expect(retiree.id, e().id);
      expect(retiree.description, e().description);
      expect(retiree.dateEcheance, e().dateEcheance);
    });
  });

  group('ADR-012 §3 — la GRAMMAIRE de `retiree` à la frontière (F-1)', () {
    Map<String, Object?> donnee(Map<String, Object?> extra) =>
        <String, Object?>{
          'id': 'a1',
          'description': 'Convention',
          'dateEcheance': DateTime(2027, 3, 15, 23, 59),
          ...extra,
        };

    test('clé ABSENTE ⇒ PRÉSENTE — ⛔ jamais « c’était peut-être retiré »', () {
      final lue = Echeance.depuisDonnee(donnee(const {}));
      expect(lue, isNotNull);
      expect(lue!.retiree, isFalse);
    });

    test('`true` ⇒ RETIRÉE', () {
      expect(Echeance.depuisDonnee(donnee({'retiree': true}))!.retiree, isTrue);
    });

    test('`false` ⇒ PRÉSENTE : forme LICITE, ⛔ PAS un résidu', () {
      final lue = Echeance.depuisDonnee(donnee({'retiree': false}));
      expect(
        lue,
        isNotNull,
        reason:
            'un `false` sur le disque est licite (jamais écrit par le produit) '
            '⇒ le traiter en résidu ferait disparaître une tuile valide',
      );
      expect(lue!.retiree, isFalse);
    });

    test('🔴 valeur HORS DOMAINE ⇒ l’ENTRÉE ENTIÈRE est un RÉSIDU', () {
      // Règle V-1 : la barrière est la FORME CANONIQUE (`is bool`), ⛔ pas une
      // exception. ⛔ Aucun repli sur `false` : il AFFICHERAIT une tuile que le
      // pratiquant a retirée, sur la base d'une valeur non comprise.
      for (final hors in <Object?>[
        'oui',
        'true',
        1,
        0,
        <int>[],
        <String, int>{},
      ]) {
        expect(
          Echeance.depuisDonnee(donnee({'retiree': hors})),
          isNull,
          reason: 'valeur hors domaine : ${hors.runtimeType} $hors',
        );
      }
    });

    test('🔴 D-4 — `retiree: null` est PRÉSENT et non booléen ⇒ RÉSIDU', () {
      // ⛔ Le mutant à tuer : `donnee['retiree'] ?? false`. Il rendrait cette
      // entrée PRÉSENTE, donc afficherait une tuile dont l'application n'a pas
      // su lire l'état. La présence se teste par `containsKey`.
      expect(Echeance.depuisDonnee(donnee({'retiree': null})), isNull);
    });

    test('⛔ CONTRÔLE NÉGATIF — les autres refus n’ont pas changé de sens', () {
      // Sans ce contrôle, un `return null` inconditionnel rendrait le groupe
      // ci-dessus vert de bout en bout.
      expect(Echeance.depuisDonnee(donnee(const {})), isNotNull);
      expect(Echeance.depuisDonnee({'id': 'a1'}), isNull);
    });
  });

  group('C-7 — `presentesSurLaGrille` : UN SEUL filtre', () {
    test('les retirées sont exclues, les autres CONSERVÉES DANS L’ORDRE', () {
      final liste = [
        e(id: 'a1'),
        e(id: 'a2', retiree: true),
        e(id: 'a3'),
        e(id: 'a4', retiree: true),
      ];
      expect(presentesSurLaGrille(liste).map((x) => x.id).toList(), <String>[
        'a1',
        'a3',
      ]);
    });

    test('⛔ le filtre ne dépend PAS du temps : une échue NON retirée reste', () {
      // AC-5 : « aucune tuile ne disparaît sans geste ». Une échéance largement
      // dépassée est PRÉSENTE tant qu'elle n'a pas été retirée.
      final echue = Echeance(
        id: 'vieille',
        description: 'x',
        dateEcheance: DateTime(1999),
      );
      expect(presentesSurLaGrille([echue]), hasLength(1));
      expect(presentesSurLaGrille([echue.avec(retiree: true)]), isEmpty);
    });

    test('la liste rendue est NON MODIFIABLE', () {
      expect(
        () => presentesSurLaGrille([e()]).add(e(id: 'a9')),
        throwsUnsupportedError,
      );
    });
  });

  group('I-7 RÉDUIT D’UN CHAMP — et le contrôle porte son négatif', () {
    // ADR-012 §1 : `retiree` autorisé, ⛔ `createdAt`, `dirty`, `version` et
    // `retireeLe` toujours INTERDITS dans l'entité. Un contrôle STATIQUE, sur
    // le patron du scénario « aucune dépendance réseau » de `test/e2e/`.
    String source() =>
        File('lib/features/echeances/domain/echeance.dart').readAsStringSync();

    test('⛔ aucun champ de persistance spéculatif n’est DÉCLARÉ', () {
      // ⛔ On cherche une DÉCLARATION DE CHAMP, ⛔ pas le mot : les noms
      // interdits sont *cités* dans la documentation du fichier (elle explique
      // ce qu'elle interdit), et un contrôle par mot nu serait faux 8 fois
      // sur 8 — c'est la tension mesurée par `reports/US-00.5/`.
      for (final interdit in const [
        'retireeLe',
        'createdAt',
        'dirty',
        'version',
      ]) {
        expect(
          source(),
          isNot(contains('final DateTime? $interdit')),
          reason: '$interdit reste interdit dans l’entité (I-7)',
        );
        expect(source(), isNot(contains('this.$interdit')));
      }
    });

    test('⛔ CONTRÔLE NÉGATIF — le champ AUTORISÉ, lui, est bien déclaré', () {
      // Sans lui, le test précédent serait vert sur un fichier vide.
      expect(source(), contains('final bool retiree'));
      expect(source(), contains('this.retiree = false'));
    });
  });
}
