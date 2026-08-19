/// Les migrations de schéma du document `echeances.json` (T5).
///
/// 🔴 **C'est ici que se joue le critère d'entrée transféré par EPIC_00**
/// *(critère de clôture nº 112)* : la convention d'
/// [ADR-005](../../../../docs/adr/ADR-005-convention-migrations-reversibles.md)
/// cesse d'être « documentée et jamais instanciée ». ⛔ **Tant que le patron
/// aller-retour n'est pas vert, le risque nº 4 d'EPIC_00 reste OUVERT.**
///
/// ⛔ **Ces noms sont CONTRAIGNANTS** : le critère de sortie
/// `reports/US-01.2/migration_roundtrip_criterion.py` s'y **lie**. Un nom
/// différent laisse le critère rouge — c'est le principe même d'un critère.
///
/// ⛔ **Fonctions PURES** : ni disque, ni horloge, ni mutation de l'entrée.
library;

import '../domain/date_civile.dart';

typedef EtapeFn = Map<String, Object?> Function(Map<String, Object?>);

/// Une étape, **avec son couple `up`/`down`** — ⛔ ADR-005 §1 interdit un `up`
/// sans `down`.
class EtapeMigration {
  const EtapeMigration(this.version, this.up, this.down);

  /// Version **ATTEINTE** par [up] ; [down] en repart.
  final int version;
  final EtapeFn up;
  final EtapeFn down;
}

/// ⚠️ **`v2`, et le `.feature` l'impose** : ses scénarios d'AC-12 exigent une
/// *« version antérieure **contenant 3 échéances** »*, or `v0` = **aucun
/// fichier**. Il faut donc au moins deux versions **porteuses de données**.
const int versionCourante = 2;

/// 🔴 **DÉVIATION ASSUMÉE D'ADR-005 §1, reprise du §4 du schéma de stockage** :
/// **il n'existe AUCUNE étape `v0 → v1`.** Pour un magasin document, `v0` est
/// **l'absence de fichier** ; « créer le schéma » n'est pas une transformation
/// de données mais **la première écriture**, qui relève du dépôt. Une étape
/// fictive n'aurait aucun effet, et son `down` — *supprimer le fichier* —
/// serait **le seul `down` destructif du projet** (ADR-005 §3) pour un chemin
/// que **rien n'emprunte**.
const List<EtapeMigration> etapesMigration = <EtapeMigration>[
  // v1 → v2 : `date_utc_vers_date_civile`.
  EtapeMigration(2, _v1VersV2, _v2VersV1),
];

/// `null` si le document ne porte pas d'entier `>= 1`.
///
/// ⛔ **Jamais une version DEVINÉE** : deviner « c'est sûrement du v1 », c'est
/// risquer d'appliquer un `up` sur une forme qu'il ne comprend pas.
int? lireVersion(Map<String, Object?> document) {
  final v = document['schemaVersion'];
  return (v is int && v >= 1) ? v : null;
}

/// Applique les étapes montantes **ou** descendantes jusqu'à [cible], puis
/// réécrit `schemaVersion`.
///
/// Rend **`null`** si la version de départ n'est pas prise en charge — absente,
/// non entière, `< 1`, ou **supérieure à [versionCourante]**.
/// ⚠️ **Le cas « version FUTURE » est le plus facile à rater** : le binaire
/// courant ne connaît **aucune étape pour redescendre**, donc l'accepter
/// **écraserait** une donnée parfaitement valide du point de vue de la version
/// qui l'a écrite.
///
/// 🔴 **R-6 — la migration ne se rejoue pas** : après un `up` réussi le
/// document **porte la nouvelle version**, donc la relecture suivante ne trouve
/// plus rien à migrer. ⛔ Vérifié par **compteur d'appels** dans le test de T7,
/// pas par relecture du code.
Map<String, Object?>? migrer(
  Map<String, Object?> document, {
  int cible = versionCourante,
}) {
  final depart = lireVersion(document);
  if (depart == null) return null;
  if (depart > versionCourante) return null;
  if (cible < 1 || cible > versionCourante) return null;
  var doc = Map<String, Object?>.from(document);
  var v = depart;
  while (v < cible) {
    doc = _etapePour(v + 1).up(doc);
    v++;
  }
  while (v > cible) {
    doc = _etapePour(v).down(doc);
    v--;
  }
  doc['schemaVersion'] = cible;
  return doc;
}

EtapeMigration _etapePour(int version) =>
    etapesMigration.firstWhere((e) => e.version == version);

Map<String, Object?> _v1VersV2(Map<String, Object?> d) =>
    transformerDates(d, instantVersCivil);

Map<String, Object?> _v2VersV1(Map<String, Object?> d) =>
    transformerDates(d, civilVersInstant);

/// Applique [convertir] à chaque `dateEcheance` **textuelle**, et **transporte
/// tout le reste**.
///
/// ⛔ **Aucune clé retirée, aucune entrée supprimée, aucun document recomposé** :
/// clés de tête inconnues, clés d'entrée inconnues et lignes non-objet sont
/// **portées telles quelles**. `convertir` rendant `null` ⇒ l'entrée est
/// **laissée VERBATIM**.
///
/// ⚠️ Exposée *(non privée)* pour que le test du patron puisse la composer avec
/// un **mutant** ; ⛔ elle n'est appelée par aucun autre fichier de `lib/`.
Map<String, Object?> transformerDates(
  Map<String, Object?> d,
  String? Function(String) convertir,
) {
  final brut = d['echeances'];
  if (brut is! List) return Map<String, Object?>.from(d);
  final sortie = <Object?>[];
  for (final ligne in brut) {
    if (ligne is! Map) {
      sortie.add(ligne);
      continue;
    }
    final date = ligne['dateEcheance'];
    if (date is! String) {
      sortie.add(ligne);
      continue;
    }
    final converti = convertir(date);
    if (converti == null) {
      sortie.add(ligne);
      continue;
    }
    sortie.add(<String, Object?>{
      for (final cle in ligne.keys) '$cle': ligne[cle],
      'dateEcheance': converti,
    });
  }
  final resultat = Map<String, Object?>.from(d);
  resultat['echeances'] = sortie;
  return resultat;
}

/// `v1 → v2` : l'instant UTC devient la date-heure **civile locale**.
///
/// 🔴 **GARDE D'INVERSIBILITÉ, non négociable — et elle n'est PAS une
/// élégance.** MESURÉ le 2026-08-06 : l'aller-retour `v1 ⇄ v2` **n'est pas
/// exact, même dans un seul fuseau**, pour deux classes de valeurs — les
/// instants à **secondes ou millisecondes non nulles**, et la **2ᵉ occurrence
/// de l'heure répétée** de la bascule d'automne. Sans cette garde,
/// `22:59:30Z` deviendrait `23:59` puis `22:59:00Z` ⇒ **30 secondes détruites**,
/// et **AC-12 « Erreur »** *(« aucune migration ne tronque une donnée »)*
/// **tomberait**. La colonne `GARDE` de la sonde vaut **exactement**
/// `ALLER_RETOUR_EXACT`, **7 cas sur 7, dans les deux sens** : le prédicat est
/// donc la **caractérisation exacte** de l'inversibilité, pas une approximation.
///
/// ⚠️ **Contrepartie, à ne pas sur-lire** : une entrée non inversible est
/// **conservée** mais devient un **résidu** — **aucune donnée n'est perdue**,
/// une échéance peut disparaître de la grille. Sur `v1` la portée réelle est
/// **nulle** *(personne n'a jamais détenu de document `v1`)*.
String? instantVersCivil(String iso) {
  final DateTime instant;
  try {
    instant = DateTime.parse(iso);
  } on FormatException {
    return null;
  }
  if (!instant.isUtc) return null;
  // Forme canonique de `v1` : instant ISO-8601 marqué UTC, écrit à l'identique.
  if (instant.toIso8601String() != iso) return null;
  final civil = formatCivil(instant.toLocal());
  if (DateTime.parse(civil).toUtc() != instant) return null;
  return civil;
}

/// `v2 → v1` : la date-heure civile redevient un instant UTC.
///
/// ⛔ La reconnaissance passe par [litDateCivile] — **le prédicat de forme
/// canonique, en un seul exemplaire** (règle V-2). Une valeur non canonique
/// est **laissée verbatim**, jamais réparée.
String? civilVersInstant(String civil) {
  final local = litDateCivile(civil);
  if (local == null) return null;
  return local.toUtc().toIso8601String();
}
