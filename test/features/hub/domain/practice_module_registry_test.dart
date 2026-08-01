import 'package:concentration/features/hub/domain/practice_module.dart';
import 'package:concentration/features/hub/domain/practice_module_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests du registre de modules (T6 / ADR-004).
void main() {
  const registre = PracticeModuleRegistry();

  test('expose 3 modules dans l’ordre attendu, avec les bons statuts', () {
    expect(registre.tous.map((m) => m.id).toList(), [
      'echeances',
      'respiration',
      'concentration',
    ]);
    expect(registre.tous.map((m) => m.statut).toList(), [
      StatutModule.actif,
      StatutModule.grise,
      StatutModule.grise,
    ]);
  });

  test('libellés en FRANÇAIS — seule langue du produit', () {
    expect(registre.tous.map((m) => m.libelle).toList(), [
      'Échéances',
      'Respiration',
      'Concentration',
    ]);
  });

  test('le module actif est désigné par son STATUT, pas par son nom', () {
    // Le hub ne sait pas que c'est « Échéances » : il demande au registre.
    expect(registre.actif.statut, StatutModule.actif);
    expect(registre.actif.id, 'echeances');
  });

  test('les modules grisés ne sont PAS interactifs (AC-2)', () {
    expect(registre.grises, hasLength(2));
    for (final m in registre.grises) {
      expect(m.estInteractif, isFalse);
    }
  });

  test('seul le module actif est interactif', () {
    expect(
      registre.tous.where((m) => m.estInteractif).map((m) => m.id).toList(),
      ['echeances'],
    );
  });

  test('RF-21 : ajouter un module coûte UNE entrée — la structure le permet', () {
    // On n'édite pas le registre : on vérifie que le type de son contenu suffit
    // à décrire un module de plus, sans champ de placement ni de navigation.
    const nouveau = PracticeModule(
      id: 'ancrage',
      libelle: 'Ancrage',
      statut: StatutModule.grise,
    );
    final etendu = [...registre.tous, nouveau];
    expect(etendu, hasLength(registre.tous.length + 1));
    expect(etendu.last.estInteractif, isFalse);
  });

  test('égalité par valeur du descripteur', () {
    const a = PracticeModule(id: 'x', libelle: 'X', statut: StatutModule.actif);
    const b = PracticeModule(id: 'x', libelle: 'X', statut: StatutModule.actif);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
