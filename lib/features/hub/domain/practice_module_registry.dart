import 'practice_module.dart';

/// Registre des modules du hub (T6) — **implémente ADR-004**.
///
/// Le hub **itère** sur ce registre : il ne connaît aucun module en dur.
/// **RF-21** : ajouter un module coûte **une entrée**, rien d'autre.
///
/// Libellés **en français** (DESIGN_SYSTEM §Langue) — les maquettes Stitch, en
/// anglais, ne sont des repères de mise en page, jamais des tokens de contenu.
class PracticeModuleRegistry {
  const PracticeModuleRegistry();

  static const List<PracticeModule> modules = [
    PracticeModule(
      id: 'echeances',
      libelle: 'Échéances',
      statut: StatutModule.actif,
    ),
    PracticeModule(
      id: 'respiration',
      libelle: 'Respiration',
      statut: StatutModule.grise,
    ),
    PracticeModule(
      id: 'concentration',
      libelle: 'Concentration',
      statut: StatutModule.grise,
    ),
  ];

  /// Liste ordonnée, dans l'ordre d'affichage.
  List<PracticeModule> get tous => modules;

  /// Le module qui fournit le contenu de la zone active.
  ///
  /// ⛔ Le hub ne sait pas que c'est « Échéances » : il demande au registre.
  PracticeModule get actif =>
      modules.firstWhere((m) => m.statut == StatutModule.actif);

  /// Modules futurs — visibles, estompés, non-interactifs (AC-2).
  List<PracticeModule> get grises => modules
      .where((m) => m.statut == StatutModule.grise)
      .toList(growable: false);
}
