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
///
/// ⚖️ **I-7 est RÉDUIT D'UN CHAMP, NOMMÉMENT, par
/// [ADR-012](../../../../docs/adr/ADR-012-etat-echue-retiree-persistance-migration-v3.md)
/// §1 — ⛔ il n'est PAS levé.** `retiree` est autorisé ; ⛔ `createdAt`,
/// `dirty`, `version` et **`retireeLe`** restent interdits. **Motif, et il est
/// dans le texte d'I-7 lui-même** : son interdit visait la modélisation
/// **SPÉCULATIVE** *(« aucun sens sans stockage »)*, or il y a maintenant un
/// stockage **et** deux AC qui exigent ce champ *(AC-4, AC-5 d'US-01.4)*.
/// ⛔ **`retireeLe` n'a, lui, aucun AC** ⇒ l'ajouter serait exactement la
/// spéculation qu'I-7 refuse.
class Echeance implements Comparable<Echeance> {
  Echeance({
    required this.id,
    required this.description,
    required this.dateEcheance,
    this.retiree = false,
  }) : assert(id != '', 'I-2 : id non vide');

  final String id;
  final String description;
  final DateTime dateEcheance;

  /// `true` ⇔ l'échéance est **`ÉCHUE RETIRÉE`** : absente de la grille,
  /// **conservée** et listée en gestion (RF-06, AC-4 / AC-5 d'US-01.4).
  ///
  /// 🔴 **C'est le SEUL fait de l'entité qui ne se dérive de RIEN**, et c'est
  /// pour cela qu'il est persisté : `ACTIVE` et `ÉCHUE` se dérivent de
  /// `(dateEcheance, Clock)` — les stocker les rendrait **faux à la seconde
  /// suivante** — tandis que *« le pratiquant a retiré cette tuile »* ne se
  /// dérive d'aucune autre donnée. ⇒ la **3NF est respectée**, ⛔ pas contournée
  /// (ADR-012 §Contexte 4).
  ///
  /// ⚠️ **Le défaut est `false`, et ce n'est pas une commodité** : sur le disque
  /// la clé est **optionnelle**, donc **son absence signifie « présente »** ⇒
  /// **AC-5 « Erreur » est vrai PAR CONSTRUCTION** pour tout document déjà
  /// écrit, ⛔ pas par un test de garde.
  final bool retiree;

  /// Recopie **modifiée** — l'`id` est **CONSERVÉ** (édition, AC-6 d'US-01.2).
  ///
  /// Un `null` signifie « inchangé », jamais « effacé » — c'est ce qui permet à
  /// l'édition de ne toucher qu'un seul champ sans que l'autre puisse être perdu
  /// par omission. ⚠️ **`retiree: null` suit ce MÊME contrat** : il laisse le
  /// retrait **tel quel**. ⛔ Il ne le remet pas à `false` — sans quoi une
  /// simple édition **ramènerait une tuile retirée sur la grille**, ce
  /// qu'**AC-5 « Limite » d'US-01.4 interdit** *(« une échue retirée ne revient
  /// JAMAIS »)*.
  Echeance avec({String? description, DateTime? dateEcheance, bool? retiree}) =>
      Echeance(
        id: id,
        description: description ?? this.description,
        dateEcheance: dateEcheance ?? this.dateEcheance,
        retiree: retiree ?? this.retiree,
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
    // 🔴 **F-1 — LE REFUS DE `retiree` VIT ICI, ET EN UN SEUL EXEMPLAIRE.**
    // Le codec ne fait que **transporter** la valeur brute ; un second contrôle
    // chez lui serait **non assertable** (deux barrières, dont une jamais
    // atteinte). ⛔ Et la barrière est du **code exécuté en release**
    // (ADR-010 §3), ⛔ jamais un `assert`.
    //
    // ⛔ **LA PRÉSENCE SE TESTE PAR `containsKey`, JAMAIS PAR LA NULLITÉ**
    // (D-4, arbitrage du 2026-08-24) : `donnee['retiree'] ?? false`
    // **AFFICHERAIT COMME PRÉSENTE** une tuile dont l'application **n'a pas su
    // lire l'état** — l'application contredirait une action de l'utilisateur
    // sur la base d'une valeur qu'elle n'a pas comprise.
    final bool retiree;
    if (donnee.containsKey('retiree')) {
      final brut = donnee['retiree'];
      // Règle **V-1** prise à la lettre : la barrière est la **FORME
      // CANONIQUE** (`is bool`), ⛔ pas une exception levée. Une valeur hors
      // domaine — `"oui"`, `1`, `null`, une liste — rend l'entrée **RÉSIDUELLE**
      // (ADR-012 §3) : ⛔ ni réparée, ni normalisée, ni supprimée, ⛔ **et
      // surtout pas repliée sur `false`**.
      if (brut is! bool) return null;
      retiree = brut;
    } else {
      // ⛔ Absence ⇒ **PRÉSENTE**. ⛔ Jamais « c'était peut-être retiré ».
      retiree = false;
    }
    return Echeance(
      id: id,
      description: description is String ? description : '',
      dateEcheance: date,
      retiree: retiree,
    );
  }

  /// Comparateur **TOTAL** (`docs/architecture/MODELE_ECHEANCE.md` §Ordre).
  ///
  /// Tri strict par `dateEcheance` croissante (RF-07, AC-6) ⇒ une échéance
  /// dépassée, étant la plus ancienne, **remonte en tête**. Départage par `id`
  /// à date égale : un comparateur non total est instable selon
  /// l'implémentation, et deux tuiles pourraient **échanger leur place** entre
  /// deux rafraîchissements (AC-6 « Erreur » exige un ordre déterministe).
  ///
  /// ⛔ **`retiree` N'ENTRE PAS DANS CET ORDRE, et c'est une décision d'ADR-012
  /// §1, pas un oubli** : l'y faire entrer changerait le tri de la grille **et**
  /// le sens d'**AC-6 « Erreur » d'US-01.1** *(ordre déterministe)* **sans
  /// qu'aucun AC ne le demande**. Le retrait décide **qui est sur la grille**,
  /// ⛔ jamais **dans quel ordre**.
  @override
  int compareTo(Echeance autre) {
    final parDate = dateEcheance.compareTo(autre.dateEcheance);
    return parDate != 0 ? parDate : id.compareTo(autre.id);
  }

  /// ⚠️ **`retiree` EST dans l'égalité** *(I-1 : égalité par valeur, ADR-012
  /// §1)* : sans lui, une échéance retirée serait **égale** à la même non
  /// retirée, et un `ListenableBuilder` pourrait **ne pas voir** le changement.
  @override
  bool operator ==(Object other) =>
      other is Echeance &&
      other.id == id &&
      other.description == description &&
      other.dateEcheance == dateEcheance &&
      other.retiree == retiree;

  @override
  int get hashCode => Object.hash(id, description, dateEcheance, retiree);
}
