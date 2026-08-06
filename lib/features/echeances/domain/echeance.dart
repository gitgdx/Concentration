/// Entité du domaine — une échéance (T2).
///
/// Invariants portés par `docs/architecture/MODELE_ECHEANCE.md` :
/// * **I-1** immuable, égalité par valeur — la grille recalcule à chaque tick,
///   une entité mutable rendrait l'ordre non déterministe ;
/// * **I-2** `id` non vide et stable ;
/// * **I-3** `description` **peut être vide** — ce n'est pas une erreur
///   (AC-3 « Erreur » : le nombre reste affiché) ;
/// * **I-4** `dateEcheance` **peut être dans le passé** — état normal (AC-7) ;
/// * **I-7** aucun champ de persistance : ils arriveront avec US-01.2.
class Echeance implements Comparable<Echeance> {
  Echeance({
    required this.id,
    required this.description,
    required this.dateEcheance,
  }) : assert(id != '', 'I-2 : id non vide');

  final String id;
  final String description;
  final DateTime dateEcheance;

  /// Recopie **modifiée** — l'`id` est **CONSERVÉ** (édition, AC-6 d'US-01.2).
  ///
  /// ⛔ **Aucun champ nouveau** (I-7) : l'entité reste exactement celle
  /// d'US-01.1. Un `null` signifie « inchangé », jamais « effacé » — c'est ce
  /// qui permet à l'édition de ne toucher qu'un seul champ sans que l'autre
  /// puisse être perdu par omission.
  Echeance avec({String? description, DateTime? dateEcheance}) => Echeance(
    id: id,
    description: description ?? this.description,
    dateEcheance: dateEcheance ?? this.dateEcheance,
  );

  /// Construit depuis une donnée potentiellement illisible.
  ///
  /// **I-6** : une donnée invalide rend `null` — elle est **ignorée**, jamais
  /// fatale (AC-1/AC-3 « Erreur »). La validation vit à la frontière, pas dans
  /// le widget.
  ///
  /// 🔴 **NB-1 (audit sécurité US-01.1), et c'est le point de T2** : le refus
  /// d'un `id` vide est porté **par ce code EXÉCUTÉ**, jamais par l'`assert`
  /// du constructeur — un `assert` est **retiré en release** (ADR-010 §3), donc
  /// il ne peut pas être la barrière. L'`assert` reste comme **documentation**
  /// de l'invariant ; ⛔ aucune clause d'AC ne s'appuie sur lui.
  /// En US-01.1 ce chemin n'avait **aucun appelant** (finding N-6) ; il en a un
  /// réel depuis que la donnée vient du disque (AC-11).
  static Echeance? depuisDonnee(Object? donnee) {
    if (donnee is! Map) return null;
    final id = donnee['id'];
    final date = donnee['dateEcheance'];
    if (id is! String || id.isEmpty) return null;
    if (date is! DateTime) return null;
    final description = donnee['description'];
    return Echeance(
      id: id,
      description: description is String ? description : '',
      dateEcheance: date,
    );
  }

  /// Comparateur **TOTAL** (`docs/architecture/MODELE_ECHEANCE.md` §Ordre).
  ///
  /// Tri strict par `dateEcheance` croissante (RF-07, AC-6) ⇒ une échéance
  /// dépassée, étant la plus ancienne, **remonte en tête**. Départage par `id`
  /// à date égale : un comparateur non total est instable selon
  /// l'implémentation, et deux tuiles pourraient **échanger leur place** entre
  /// deux rafraîchissements (AC-6 « Erreur » exige un ordre déterministe).
  @override
  int compareTo(Echeance autre) {
    final parDate = dateEcheance.compareTo(autre.dateEcheance);
    return parDate != 0 ? parDate : id.compareTo(autre.id);
  }

  @override
  bool operator ==(Object other) =>
      other is Echeance &&
      other.id == id &&
      other.description == description &&
      other.dateEcheance == dateEcheance;

  @override
  int get hashCode => Object.hash(id, description, dateEcheance);
}
