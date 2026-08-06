/// **La forme canonique CIVILE, en UN SEUL EXEMPLAIRE** — règle **V-2** du
/// [`SCHEMA_STOCKAGE_ECHEANCES.md`](../../../../docs/architecture/SCHEMA_STOCKAGE_ECHEANCES.md).
///
/// ⚖️ **Décision @Developer (T3), le prédicat n'ayant pas de fichier assigné.**
/// V-2 exige **un seul exemplaire** partagé par **la saisie** *(T3, `domain/`)*,
/// **le codec** *(T4, `data/`)* et **les migrations** *(T5, `data/`)*. Le sens
/// des dépendances est `presentation → domain ← data` : ⛔ `domain/` ne peut pas
/// importer `data/`, mais `data/` peut importer `domain/`. ⇒ **le seul endroit
/// d'où les trois peuvent le voir est `domain/`**, et il n'a sa place ni dans
/// `validation_echeance.dart` *(le codec n'a rien à faire d'un validateur de
/// saisie)*, ni dans le codec *(la saisie n'a rien à faire d'un encodeur)*.
///
/// 🔴 **CE QUE CE MODULE EXISTE POUR EMPÊCHER, et c'est MESURÉ** :
/// `DateTime.parse("2026-02-31T23:59")` **NE LÈVE PAS** — il rend
/// `2026-03-03T23:59`, **silencieusement**. ⇒ ⛔ **une exception n'est PAS une
/// barrière ; la barrière est la comparaison à la forme canonique.**
/// Sans elle, l'application **écrit une valeur qu'elle refusera de relire** :
/// à la relecture la valeur n'est pas canonique ⇒ elle devient un **résidu**
/// (AC-11) ⇒ 🔴 **l'échéance disparaît SANS MESSAGE**, alors que le pratiquant
/// l'a saisie **et validée**.
library;

String _deuxChiffres(int n) => n.toString().padLeft(2, '0');

/// Écrit le texte canonique `AAAA-MM-JJThh:mm` depuis des composantes
/// **ENTIÈRES**, ⛔ **sans jamais passer par un `DateTime`**.
///
/// 🔴 **C'est le point le plus facile à rater de tout ce module, et il est
/// mesuré** : `DateTime(2027, 2, 31)` rend **le 3 mars** et
/// `DateTime(2026, 3, 29, 2, 30)` rend **03:30** dans un fuseau qui pratique le
/// changement d'heure. Fabriquer le candidat d'une **saisie** à partir d'un
/// `DateTime` aurait donc **déjà commis la mutation** que ce module existe pour
/// refuser — et le prédicat aurait validé une valeur que l'utilisateur n'a
/// jamais tapée.
String texteCivil(int annee, int mois, int jour, int heure, int minute) =>
    '${annee.toString().padLeft(4, '0')}-${_deuxChiffres(mois)}-'
    '${_deuxChiffres(jour)}T${_deuxChiffres(heure)}:${_deuxChiffres(minute)}';

/// Écrit une date-heure locale **déjà normalisée** sous la même forme.
///
/// ⛔ **Ni `Z`, ni décalage, ni secondes** (AC-14, ADR-010 §2) : une date civile
/// **n'a pas de fuseau**, donc un déplacement de fuseau **ne peut pas** la
/// déplacer. La décision *dissout* le problème que la note I-5 voulait gérer.
String formatCivil(DateTime local) =>
    texteCivil(local.year, local.month, local.day, local.hour, local.minute);

/// **LE PRÉDICAT** : rend la date-heure locale si `texte` est **canonique**,
/// `null` sinon. `estCanonique(s) ⇔ formatCivil(DateTime.parse(s)) == s` **et**
/// `!isUtc` — exactement le §6 du schéma de stockage.
///
/// Refuse donc, sans exception et sans correction : une date **hors calendrier**
/// (`2026-02-31T23:59`), une heure **civile inexistante localement**
/// (`2026-03-29T02:30` le jour du saut de printemps), une valeur portant `Z`,
/// un décalage, des **secondes**, ou une date **sans heure** (`2026-11-15`).
DateTime? litDateCivile(String texte) {
  final DateTime local;
  try {
    local = DateTime.parse(texte);
  } on FormatException {
    return null;
  }
  if (local.isUtc) return null;
  if (formatCivil(local) != texte) return null;
  return local;
}

/// Vrai si le triplet désigne un jour qui **existe au calendrier**.
///
/// ⚠️ **Ce n'est PAS un second exemplaire de la règle V-1**, et la distinction
/// est vérifiable : [litDateCivile] refuse le 31 février **à lui seul**, sans
/// cette fonction *(test dédié)*. Elle sert **uniquement** à savoir **QUEL
/// CHAMP** est fautif — la date ou l'heure — pour ancrer le message sous le bon
/// champ (Design UX §14.6). Retirée, on perdrait l'**ancrage**, jamais la
/// **barrière**.
///
/// ⛔ Le calcul se fait en **UTC**, qui n'a **aucune transition d'heure** : sans
/// cela, un jour parfaitement existant pourrait être déclaré inexistant à cause
/// d'un saut d'heure, et l'attribution du champ deviendrait fausse.
bool jourExisteAuCalendrier(int annee, int mois, int jour) {
  final t = DateTime.utc(annee, mois, jour);
  return t.year == annee && t.month == mois && t.day == jour;
}
