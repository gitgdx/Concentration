/// Statut d'un module du hub (RF-20).
enum StatutModule {
  /// Module opérant : il fournit le contenu de la zone active.
  actif,

  /// Module futur : **visible**, estompé, et **non-interactif** (AC-2).
  grise,
}

/// Descripteur d'un module de pratique (T6) — brique du registre.
///
/// ⛔ Aucune notion de **placement** : ni zone, ni index de grille, ni slot de
/// navigation (ADR-004 §2). C'est ce qui permet à @UXDesigner de déplacer les
/// modules sans toucher au domaine.
class PracticeModule {
  const PracticeModule({
    required this.id,
    required this.libelle,
    required this.statut,
  });

  final String id;

  /// Libellé **en français** — seule langue du produit (DESIGN_SYSTEM §Langue).
  final String libelle;

  final StatutModule statut;

  bool get estInteractif => statut == StatutModule.actif;

  @override
  bool operator ==(Object other) =>
      other is PracticeModule &&
      other.id == id &&
      other.libelle == libelle &&
      other.statut == statut;

  @override
  int get hashCode => Object.hash(id, libelle, statut);
}
