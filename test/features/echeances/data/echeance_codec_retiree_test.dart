import 'dart:convert';

import 'package:concentration/features/echeances/data/echeance_document_codec.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:flutter_test/flutter_test.dart';

/// **T2, côté codec** — la clé `retiree` sur le disque *(US-01.4, ADR-012 §2-§3)*.
///
/// 🔴 **LE MUTANT QUI DOIT MOURIR ICI EST INVISIBLE À TOUT TEST GÉNÉRIQUE** :
/// *dans `_encoderEntree`, supprimer la ligne `entree.remove('retiree')`*.
/// `_encoderEntree` copie les clés d'`origine` **AVANT** les clés explicites
/// (mesuré, ADR-012 §Contexte 5) ⇒ un `retiree: true` **d'origine SURVIVRAIT**
/// à une entité non retirée, et la tuile resterait absente de la grille **pour
/// toujours**. ⛔ Sur un document qui n'a jamais porté la clé — c'est-à-dire
/// **tout le parc installé** — les deux formes sont **identiques** : seul un
/// test qui **pose la clé lui-même** peut voir la différence.
///
/// ⛔ **Aucune date « vivante » ici** : ces chaînes sont des VALEURS PERSISTÉES,
/// pas des échéances soumises au temps qui passe (R-13 ne les vise pas).
void main() {
  const codec = EcheanceDocumentCodec();

  String document(String entrees) =>
      '{"schemaVersion":2,"echeances":[$entrees],"_inconnu":{"garde":true}}';

  const presente =
      '{"id":"a1","description":"Convention","dateEcheance":"2027-03-15T23:59"}';
  const retiree =
      '{"id":"a2","description":"Revue","dateEcheance":"2026-01-09T23:59",'
      '"retiree":true}';

  Echeance parId(List<Echeance> liste, String id) =>
      liste.firstWhere((e) => e.id == id);

  group('LECTURE — la grammaire d’ADR-012 §3, sur les octets', () {
    test('`true` est lu comme RETIRÉE, `absente` comme PRÉSENTE', () {
      final lu = codec.decoder(document('$presente,$retiree'))!;
      expect(lu.echeances, hasLength(2));
      expect(parId(lu.echeances, 'a1').retiree, isFalse);
      expect(parId(lu.echeances, 'a2').retiree, isTrue);
    });

    test(
      '`false` est une forme LICITE : l’entrée est RECONNUE et présente',
      () {
        final lu = codec.decoder(
          document(
            '{"id":"a3","description":"x","dateEcheance":"2027-03-15T23:59",'
            '"retiree":false}',
          ),
        )!;
        expect(
          lu.echeances,
          hasLength(1),
          reason: 'la traiter en résidu ferait disparaître une tuile valide',
        );
        expect(lu.echeances.single.retiree, isFalse);
      },
    );

    test('🔴 valeur HORS DOMAINE : l’entrée ENTIÈRE est un RÉSIDU', () {
      for (final hors in const ['"oui"', '1', '0', 'null', '[]', '{}']) {
        final texte = document(
          '$presente,'
          '{"id":"a4","description":"x","dateEcheance":"2027-03-15T23:59",'
          '"retiree":$hors}',
        );
        final lu = codec.decoder(texte)!;
        expect(
          lu.echeances.map((e) => e.id).toList(),
          <String>['a1'],
          reason: 'retiree:$hors doit rendre l’entrée résiduelle',
        );
        // Un résidu n'est PAS dans la table des index reconnus : c'est cela qui
        // permet de le ré-émettre À SA PLACE.
        expect(lu.idParIndex.keys.toSet(), <int>{0});
        // ⛔ Ni réparée, ni normalisée, ni supprimée, ⛔ et AUCUNE exception.
        expect(codec.encoder(lu, lu.echeances), contains('"retiree":$hors'));
      }
    });

    test('🔴 D-4 — `retiree: null` : `containsKey`, ⛔ JAMAIS la nullité', () {
      // Le mutant : `ligne['retiree'] != null` en place de `containsKey`, ou un
      // `?? false` à la frontière. Il rendrait cette entrée PRÉSENTE, donc
      // afficherait une tuile dont l'état n'a pas pu être lu.
      final lu = codec.decoder(
        document(
          '{"id":"a5","description":"x","dateEcheance":"2027-03-15T23:59",'
          '"retiree":null}',
        ),
      )!;
      expect(lu.echeances, isEmpty);
      expect(lu.lignes, hasLength(1), reason: 'l’octet est conservé');
    });
  });

  group('ÉCRITURE — la clé est émise SSI `true`, et RETIRÉE sinon', () {
    test('une entité non retirée n’émet AUCUNE clé `retiree`', () {
      final lu = codec.decoder(document(presente))!;
      expect(codec.encoder(lu, lu.echeances), isNot(contains('retiree')));
    });

    test('une entité retirée émet `"retiree":true`, ⛔ jamais `false`', () {
      final lu = codec.decoder(document(presente))!;
      final reecrit = codec.encoder(lu, [
        lu.echeances.single.avec(retiree: true),
      ]);
      expect(reecrit, contains('"retiree":true'));
      expect(reecrit, isNot(contains('"retiree":false')));
    });

    test('🔴 LE MUTANT — un `retiree:true` D’ORIGINE ne survit pas à une entité '
        'non retirée', () {
      // C'est ici, et NULLE PART AILLEURS, que se joue le retrait explicite de
      // la clé : les clés d'`origine` sont copiées AVANT les clés explicites.
      final lu = codec.decoder(document('$presente,$retiree'))!;
      final remises = lu.echeances.map((e) => e.avec(retiree: false)).toList();
      final reecrit = codec.encoder(lu, remises);
      expect(
        reecrit,
        isNot(contains('retiree')),
        reason:
            'sans `entree.remove`, le `true` d’origine survivrait et la tuile '
            'resterait absente de la grille POUR TOUJOURS',
      );
      // Et l'entrée reste lisible, avec tous ses autres champs intacts.
      final relu = codec.decoder(reecrit)!;
      expect(relu.echeances.map((e) => e.id).toList(), <String>['a1', 'a2']);
      expect(parId(relu.echeances, 'a2').description, 'Revue');
      expect(parId(relu.echeances, 'a2').retiree, isFalse);
    });

    test('une clé INCONNUE d’une entrée RETIRÉE survit à sa mise à jour', () {
      final lu = codec.decoder(
        document(
          '{"id":"a6","description":"x","dateEcheance":"2027-03-15T23:59",'
          '"retiree":true,"garde":7}',
        ),
      )!;
      final reecrit = codec.encoder(lu, [
        lu.echeances.single.avec(description: 'y'),
      ]);
      expect(reecrit, contains('"garde":7'));
      expect(reecrit, contains('"retiree":true'));
      expect(reecrit, contains('"description":"y"'));
    });
  });

  group('F-3 / D-5 — la clé CONSERVE SA POSITION à la ré-émission', () {
    test('🔴 une entrée retirée INCHANGÉE se réécrit OCTET POUR OCTET', () {
      // C'est la garantie que D-5 protège : si la clé était retirée puis
      // réinsérée en queue, cette égalité tomberait — et avec elle
      // `A3_aller_retour` du critère d'US-01.2.
      final texte = document(retiree);
      final lu = codec.decoder(texte)!;
      expect(codec.encoder(lu, lu.echeances), texte);
    });

    test('`retiree` reste AVANT une clé inconnue qui la suivait', () {
      const entree =
          '{"id":"a7","description":"x","dateEcheance":"2027-03-15T23:59",'
          '"retiree":true,"garde":7}';
      final lu = codec.decoder(document(entree))!;
      final reecrit = codec.encoder(lu, lu.echeances);
      final entrees = (jsonDecode(reecrit) as Map)['echeances'] as List;
      expect(
        (entrees.single as Map).keys.toList(),
        <String>['id', 'description', 'dateEcheance', 'retiree', 'garde'],
        reason: 'ORDRE des clés, ⛔ pas seulement leur présence',
      );
    });

    test('une entrée CRÉÉE retirée porte la clé en queue, sans origine', () {
      final lu = codec.decoder(document(''))!;
      final reecrit = codec.encoder(lu, [
        Echeance(
          id: 'neuve',
          description: 'x',
          dateEcheance: DateTime(2027, 3, 15, 23, 59),
          retiree: true,
        ),
      ]);
      final entree =
          ((jsonDecode(reecrit) as Map)['echeances'] as List).single as Map;
      expect(entree.keys.toList(), <String>[
        'id',
        'description',
        'dateEcheance',
        'retiree',
      ]);
    });
  });
}
