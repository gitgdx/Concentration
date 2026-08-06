#!/usr/bin/env python3
"""Critere de sortie EXECUTABLE du patron aller-retour d'ADR-005 pour US-01.2.

POURQUOI CE FICHIER EXISTE
--------------------------
Le critere d'entree transfere par EPIC_00 (critere de cloture no 112) exige que la
convention d'ADR-005 cesse d'etre "documentee et jamais instanciee" : le patron
aller-retour de docs/architecture/MIGRATIONS.md section 4 doit etre EXECUTE sur le
premier schema reel du projet. Un patron DECRIT ne vaut rien ; seul un patron JOUE
compte. Ce script le joue.

CE QU'IL FAIT, ET DANS QUEL ORDRE IL FAUT LE LIRE
-------------------------------------------------
  --selftest   Joue les 8 assertions contre 8 sources Dart EMBARQUEES : une conforme
               et SEPT MUTANTS COMPORTEMENTAUX. Il compare, pour chaque source,
               l'ENSEMBLE des assertions en echec a l'ENSEMBLE attendu -- des
               ENSEMBLES, jamais des cardinaux (un decompte egal n'est pas une preuve
               d'equivalence). Ce mode mesure LE POUVOIR DU CRITERE : un critere qui
               ne sait pas rougir ne mesure rien. Il tourne AUJOURD'HUI, sans que
               lib/ existe.
  (defaut)     Joue les MEMES 8 assertions contre le module reel
               lib/features/echeances/data/echeance_schema_migrations.dart (tache T5).
               Tant que ce fichier n'existe pas, le critere rend exit 1 en le disant
               PLATEMENT : il est REJOUABLE, il n'est pas encore SATISFAIT.

CE QU'IL N'ATTESTE PAS
----------------------
  - Il ne teste PAS le codec, le magasin, l'ecriture atomique ni l'application : il
    porte sur les fonctions PURES de migration (Map -> Map). L'atomicite (AC-12
    "Erreur") se prouve sur les OCTETS, en T6/T7, pas ici.
  - Il ne remplace AUCUN test de test/ : le gate requis est flutter test. Ce script
    est un critere de sortie rejouable, pas un gate CI (il exige le SDK Dart et un
    fichier que la CI n'a pas encore).
  - Le mutant M-conforme n'est PAS une implementation de reference : il est
    DELIBEREMENT partiel (aucune validation d'id, aucune gestion de residu au
    decodage, aucun acces disque). Le copier dans lib/ produirait deux exemplaires
    d'une meme regle -- ce corpus a mesure trois fois que deux copies derivent.

CONTRAT ATTENDU DU MODULE (voir docs/architecture/SCHEMA_STOCKAGE_ECHEANCES.md)
-------------------------------------------------------------------------------
    const int versionCourante;                     // == 2 pour US-01.2
    const List<EtapeMigration> etapesMigration;    // ordonnee, contigue, jusqu'a
                                                   // versionCourante
    class EtapeMigration { final int version;
                           final Map<String,Object?> Function(Map<String,Object?>) up;
                           final Map<String,Object?> Function(Map<String,Object?>) down; }
    int? lireVersion(Map<String, Object?> document);
    Map<String, Object?>? migrer(Map<String, Object?> document, {int cible});

Usage :
    python reports/US-01.2/migration_roundtrip_criterion.py --selftest
    python reports/US-01.2/migration_roundtrip_criterion.py
"""

from __future__ import annotations

import argparse
import io
import re
import shutil
import subprocess
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
MODULE_CIBLE = RACINE / "lib" / "features" / "echeances" / "data" / "echeance_schema_migrations.dart"
IMPORT_CIBLE = "package:concentration/features/echeances/data/echeance_schema_migrations.dart"
ATELIER = RACINE / ".dart_tool" / "us012_migration_criterion"

# --------------------------------------------------------------------------
# La graine du patron : MIGRATIONS.md section 4, etape 1.
# "un jeu de donnees representatif, DONT DES LIGNES NON CONCERNEES par la
#  migration, pour detecter les pertes collaterales."
#   a1,a2,a3 : les 3 echeances que le .feature exige ("contient 3 echeances")
#   a2       : description VIDE -- I-3 reste vrai
#   a3       : porte une cle d'entree INCONNUE ("garde")
#   a4       : instant a SECONDES non nulles  -> conversion NON INVERSIBLE (mesure)
#   a6       : instant de l'heure REPETEE de la bascule automne (Europe/Paris)
#              -> conversion NON INVERSIBLE (mesure du 2026-08-06)
#   "ceci..."  : ligne NON CONCERNEE (element non-objet)
#   _inconnu   : cle de TETE inconnue -- doit survivre a up puis down
# --------------------------------------------------------------------------
GRAINE_V1 = (
    '{"schemaVersion":1,'
    '"echeances":['
    '{"id":"a1","description":"Convent","dateEcheance":"2026-11-15T22:59:00.000Z"},'
    '{"id":"a2","description":"","dateEcheance":"2026-07-15T21:59:00.000Z"},'
    '{"id":"a3","description":"Revue annuelle","dateEcheance":"2027-01-09T22:59:00.000Z","garde":7},'
    '{"id":"a4","description":"secondes non nulles","dateEcheance":"2026-11-15T22:59:30.000Z"},'
    '{"id":"a6","description":"heure repetee","dateEcheance":"2026-10-25T01:30:00.000Z"},'
    '"ceci n est pas un objet"'
    '],'
    '"_inconnu":{"garde":true}}'
)

IDS_CONVERTIBLES = ["a1", "a2", "a3"]

# --------------------------------------------------------------------------
# Le HARNAIS : il ne connait du module que le CONTRAT ci-dessus.
# Chaque assertion imprime une ligne ASSERTION|<nom>|OK|ECHEC|<detail>.
# --------------------------------------------------------------------------
HARNAIS = r"""
import 'dart:convert';
import 'dart:io';
import '__IMPORT__' as m;

const String graineJson = r'''__GRAINE__''';
const List<String> idsConvertibles = <String>[__IDS__];

class _Echec implements Exception {
  _Echec(this.message);
  final String message;
}

void exige(bool condition, String message) {
  if (!condition) throw _Echec(message);
}

Map<String, Object?> graine() =>
    Map<String, Object?>.from(jsonDecode(graineJson) as Map);

List<Object?> lignes(Map<String, Object?> d) {
  final brut = d['echeances'];
  return brut is List ? brut : const <Object?>[];
}

Map<String, Object?>? parId(Map<String, Object?> d, String id) {
  for (final ligne in lignes(d)) {
    if (ligne is Map && ligne['id'] == id) {
      return Map<String, Object?>.from(ligne);
    }
  }
  return null;
}

Object? ligneNonObjet(Map<String, Object?> d) {
  for (final ligne in lignes(d)) {
    if (ligne is! Map) return ligne;
  }
  return null;
}

String? dateDe(Map<String, Object?>? entree) {
  final v = entree?['dateEcheance'];
  return v is String ? v : null;
}

Map<String, Object?> avecVersion(Object? version) {
  final d = graine();
  if (version == null) {
    d.remove('schemaVersion');
  } else {
    d['schemaVersion'] = version;
  }
  return d;
}

final List<String> journal = <String>[];
final List<String> enEchec = <String>[];

void assertion(String nom, void Function() corps) {
  try {
    corps();
    journal.add('ASSERTION|$nom|OK|');
  } on _Echec catch (e) {
    enEchec.add(nom);
    journal.add('ASSERTION|$nom|ECHEC|${e.message}');
  } catch (e) {
    enEchec.add(nom);
    journal.add('ASSERTION|$nom|ECHEC|exception ${e.runtimeType}: $e');
  }
}

void main() {
  // CONTEXTE : le comportement des bascules d'heure DEPEND du fuseau de l'hote.
  // Il est IMPRIME, jamais suppose.
  final janvier = DateTime(2026, 1, 15, 12).timeZoneOffset;
  final juillet = DateTime(2026, 7, 15, 12).timeZoneOffset;
  final nonInversibles = <String>[];
  for (final ligne in lignes(graine())) {
    if (ligne is! Map) continue;
    final brut = ligne['dateEcheance'];
    if (brut is! String) continue;
    final t = DateTime.tryParse(brut);
    if (t == null || !t.isUtc) continue;
    final l = t.toLocal();
    final civil = '${l.year.toString().padLeft(4, '0')}-'
        '${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')}T'
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
    if (DateTime.parse(civil).toUtc() != t) {
      nonInversibles.add('${ligne['id']}');
    }
  }
  print('CONTEXTE|dart=${Platform.version.split(' ').first}'
      '|offset_janvier=$janvier|offset_juillet=$juillet'
      '|non_inversibles_ici=${nonInversibles.join(',')}');

  // A1 -- ADR-005 section 1 : version monotone, couple up/down OBLIGATOIRE.
  assertion('A1_contrat_couple', () {
    exige(m.versionCourante >= 2,
        'versionCourante = ${m.versionCourante} : le .feature exige une version '
        'anterieure CONTENANT des echeances, donc au moins deux versions');
    final versions = m.etapesMigration.map((e) => e.version).toList();
    exige(versions.isNotEmpty, 'aucune etape de migration declaree');
    exige(versions.last == m.versionCourante,
        'la derniere etape ($versions) ne mene pas a versionCourante '
        '(${m.versionCourante})');
    for (var i = 0; i < versions.length; i++) {
      exige(versions[i] == m.versionCourante - versions.length + 1 + i,
          'les versions ne sont pas contigues et croissantes : $versions');
    }
    for (final e in m.etapesMigration) {
      exige(!identical(e.up, e.down),
          'etape v${e.version} : up et down sont la MEME fonction -- ADR-005 '
          'section 1 interdit un up sans down');
    }
  });

  // A2 -- la montee TRANSFORME reellement, sans deplacer l'instant, et laisse
  // intacte la ligne non concernee (MIGRATIONS.md section 4, etape 3).
  assertion('A2_montee_transforme', () {
    final haut = m.migrer(graine());
    exige(haut != null, 'migrer a rendu null sur un document v1 valide');
    exige(lignes(haut!).length == lignes(graine()).length,
        'le nombre de lignes a change : '
        '${lignes(graine()).length} -> ${lignes(haut).length}');
    for (final id in idsConvertibles) {
      final avant = dateDe(parId(graine(), id));
      final apres = dateDe(parId(haut, id));
      exige(apres != null, 'entree $id : disparue ou date non textuelle apres up');
      exige(apres != avant, 'entree $id : la date n a PAS ete transformee ($avant)');
      exige(DateTime.parse(apres!).toUtc() == DateTime.parse(avant!),
          'entree $id : l instant a BOUGE ($avant -> $apres)');
    }
    exige(jsonEncode(ligneNonObjet(haut)) == jsonEncode(ligneNonObjet(graine())),
        'la ligne NON CONCERNEE a ete modifiee ou perdue : '
        '${jsonEncode(ligneNonObjet(haut))}');
  });

  // A3 -- LE PATRON de MIGRATIONS.md section 4, sur les OCTETS du document.
  assertion('A3_aller_retour', () {
    final avant = jsonEncode(graine());
    final haut = m.migrer(graine(), cible: m.versionCourante);
    exige(haut != null, 'up : migrer a rendu null');
    exige(m.lireVersion(haut!) == m.versionCourante,
        'up : version lue = ${m.lireVersion(haut)}, attendu ${m.versionCourante}');
    final bas = m.migrer(haut, cible: 1);
    exige(bas != null, 'down : migrer a rendu null');
    exige(m.lireVersion(bas!) == 1,
        'down : version lue = ${m.lireVersion(bas)}, attendu 1');
    exige(jsonEncode(bas) == avant,
        'ALLER-RETOUR NON EXACT\n       attendu = $avant\n       obtenu  = ${jsonEncode(bas)}');
  });

  // A4 -- R-6 : apres un up reussi, le document PORTE la nouvelle version,
  // donc la relecture suivante ne trouve plus rien a migrer.
  assertion('A4_idempotence', () {
    final une = m.migrer(graine());
    exige(une != null, 'migrer a rendu null');
    exige(m.lireVersion(une!) == m.versionCourante,
        'le document migre porte encore la version ${m.lireVersion(une)} : '
        'la migration se REJOUERA a chaque ouverture');
    final deux = m.migrer(une);
    exige(deux != null, 'migrer a rendu null au second passage');
    exige(jsonEncode(deux!) == jsonEncode(une),
        'le second passage a MODIFIE le document');
  });

  // A5 -- rien de ce que la migration ne comprend pas ne disparait.
  assertion('A5_cles_inconnues', () {
    final haut = m.migrer(graine());
    exige(haut != null, 'migrer a rendu null');
    exige(jsonEncode(haut!['_inconnu']) == jsonEncode(graine()['_inconnu']),
        'la cle de tete inconnue a ete perdue ou alteree : '
        '${jsonEncode(haut['_inconnu'])}');
    exige(jsonEncode(parId(haut, 'a3')?['garde']) == jsonEncode(7),
        'la cle d entree inconnue a ete perdue : '
        '${jsonEncode(parId(haut, 'a3')?['garde'])}');
    final bas = m.migrer(haut, cible: 1);
    exige(bas != null, 'down : migrer a rendu null');
    exige(jsonEncode(bas!['_inconnu']) == jsonEncode(graine()['_inconnu']),
        'la cle de tete inconnue a ete perdue par le down');
  });

  // A6 -- l'invariant qui rend A3 vrai PAR CONSTRUCTION : jamais une conversion
  // AVEC PERTE. Une entree est soit convertie sans deplacer l'instant, soit
  // conservee VERBATIM. Le troisieme cas -- convertie avec perte -- est le defaut.
  assertion('A6_jamais_de_conversion_avec_perte', () {
    final haut = m.migrer(graine());
    exige(haut != null, 'migrer a rendu null');
    final details = <String>[];
    for (final ligne in lignes(graine())) {
      if (ligne is! Map) continue;
      final id = '${ligne['id']}';
      final avant = dateDe(Map<String, Object?>.from(ligne));
      if (avant == null) continue;
      final entree = parId(haut!, id);
      exige(entree != null, 'entree $id : disparue apres up');
      final apres = dateDe(entree);
      exige(apres != null, 'entree $id : date non textuelle apres up');
      if (apres == avant) {
        details.add('$id=verbatim');
        continue;
      }
      exige(DateTime.parse(apres!).toUtc() == DateTime.parse(avant),
          'entree $id : CONVERTIE AVEC PERTE ($avant -> $apres) -- une conversion '
          'non inversible doit laisser l entree VERBATIM, jamais la tronquer');
      details.add('$id=convertie');
    }
    journal.add('DETAIL|A6|${details.join(' ')}');
  });

  // A7 -- version inconnue ou FUTURE : on ne devine pas, on ne reecrit rien.
  assertion('A7_version_non_supportee', () {
    exige(m.migrer(avecVersion(m.versionCourante + 1)) == null,
        'un document de version FUTURE a ete accepte : le binaire courant ne '
        'connait aucune etape pour redescendre, l accepter ECRASE la donnee');
    exige(m.migrer(avecVersion(null)) == null,
        'un document SANS schemaVersion a ete accepte : la version se lit, elle '
        'ne se devine pas');
    exige(m.migrer(avecVersion('2')) == null,
        'un schemaVersion textuel a ete accepte');
    exige(m.migrer(avecVersion(0)) == null, 'un schemaVersion nul a ete accepte');
    exige(m.lireVersion(avecVersion(null)) == null,
        'lireVersion rend une valeur pour un document sans schemaVersion');
  });

  // A8 -- AC-14 : la forme persistee est CIVILE. Assertion sur le TEXTE.
  assertion('A8_forme_canonique_civile', () {
    final haut = m.migrer(graine());
    exige(haut != null, 'migrer a rendu null');
    final civil = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$');
    for (final id in idsConvertibles) {
      final v = dateDe(parId(haut!, id));
      exige(v != null, 'entree $id : date absente');
      exige(civil.hasMatch(v!),
          'entree $id : "$v" n est pas de la forme AAAA-MM-JJThh:mm');
      exige(!v.contains('Z'), 'entree $id : "$v" porte une marque de temps universel');
      exige(!DateTime.parse(v).isUtc, 'entree $id : "$v" se relit comme un instant UTC');
    }
  });

  for (final ligne in journal) {
    print(ligne);
  }
  if (enEchec.isEmpty) {
    print('VERDICT|OK|');
    exit(0);
  }
  print('VERDICT|ECHEC|${enEchec.join(',')}');
  exit(1);
}
"""

# --------------------------------------------------------------------------
# La source Dart des fixtures : un GABARIT a fentes nommees.
# Chaque mutant remplace EXACTEMENT UNE fente. Aucune substitution textuelle
# aveugle : une fente absente fait echouer la generation (controle negatif).
# --------------------------------------------------------------------------
GABARIT_FIXTURE = r"""
// FIXTURE d'autotest du critere de sortie US-01.2 -- @DataEngineer.
// NE PAS COPIER DANS lib/ : deliberement partielle (ni validation d'id, ni
// residus au decodage, ni disque). Elle existe pour MESURER LE POUVOIR du
// critere, pas pour servir d'implementation.

typedef EtapeFn = Map<String, Object?> Function(Map<String, Object?>);

class EtapeMigration {
  const EtapeMigration(this.version, this.up, this.down);
  final int version;
  final EtapeFn up;
  final EtapeFn down;
}

const int versionCourante = 2;

const List<EtapeMigration> etapesMigration = <EtapeMigration>[
  EtapeMigration(2, __UP_REF__, __DOWN_REF__),
];

EtapeMigration _etapePour(int version) =>
    etapesMigration.firstWhere((e) => e.version == version);

int? lireVersion(Map<String, Object?> document) {
  final v = document['schemaVersion'];
  return (v is int && v >= 1) ? v : null;
}

Map<String, Object?>? migrer(Map<String, Object?> document,
    {int cible = versionCourante}) {
__MIGRER_CORPS__
}

Map<String, Object?> _identite(Map<String, Object?> d) =>
    Map<String, Object?>.from(d);

Map<String, Object?> _v1VersV2(Map<String, Object?> d) =>
    _transformer(d, _instantVersCivil);

Map<String, Object?> _v2VersV1(Map<String, Object?> d) =>
    _transformer(d, _civilVersInstant);

Map<String, Object?> _transformer(
    Map<String, Object?> d, String? Function(String) convertir) {
__TRANSFORMER_CORPS__
}

String _deuxChiffres(int n) => n.toString().padLeft(2, '0');

String _formatCivil(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-${_deuxChiffres(local.month)}-'
    '${_deuxChiffres(local.day)}T${_deuxChiffres(local.hour)}:'
    '${_deuxChiffres(local.minute)}';

String? _instantVersCivil(String iso) {
__UP_DATE_CORPS__
}

String? _civilVersInstant(String civil) {
  final DateTime local;
  try {
    local = DateTime.parse(civil);
  } on FormatException {
    return null;
  }
  if (local.isUtc) return null;
  if (_formatCivil(local) != civil) return null;
  return local.toUtc().toIso8601String();
}
"""

FENTES_CONFORMES = {
    "UP_REF": "_v1VersV2",
    "DOWN_REF": "_v2VersV1",
    "MIGRER_CORPS": """  final depart = lireVersion(document);
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
  return doc;""",
    "TRANSFORMER_CORPS": """  final brut = d['echeances'];
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
      ...Map<String, Object?>.from(ligne),
      'dateEcheance': converti,
    });
  }
  final resultat = Map<String, Object?>.from(d);
  resultat['echeances'] = sortie;
  return resultat;""",
    "UP_DATE_CORPS": """  final DateTime t;
  try {
    t = DateTime.parse(iso);
  } on FormatException {
    return null;
  }
  if (!t.isUtc) return null;
  if (t.toIso8601String() != iso) return null;
  final civil = _formatCivil(t.toLocal());
  if (DateTime.parse(civil).toUtc() != t) return null;
  return civil;""",
}

# Les MUTANTS sont COMPORTEMENTAUX : ils changent ce que le code FAIT, pas
# comment il est ecrit. Aucun n'est tire du vocabulaire de la regle testee.
MUTANTS = {
    "M0_conforme": ({}, set()),
    "M1_down_identite": (
        {"DOWN_REF": "_identite"},
        {"A3_aller_retour"},
    ),
    "M2_up_sans_garde_inversibilite": (
        {
            "UP_DATE_CORPS": """  final DateTime t;
  try {
    t = DateTime.parse(iso);
  } on FormatException {
    return null;
  }
  if (!t.isUtc) return null;
  return _formatCivil(t.toLocal());"""
        },
        {"A3_aller_retour", "A6_jamais_de_conversion_avec_perte"},
    ),
    "M3_version_non_reecrite": (
        {
            "MIGRER_CORPS": """  final depart = lireVersion(document);
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
  return doc;"""
        },
        {"A3_aller_retour", "A4_idempotence"},
    ),
    "M4_up_recompose_le_document": (
        {
            "TRANSFORMER_CORPS": """  final brut = d['echeances'];
  final sortie = <Object?>[];
  if (brut is List) {
    for (final ligne in brut) {
      if (ligne is! Map) continue;
      final date = ligne['dateEcheance'];
      if (date is! String) continue;
      final converti = convertir(date);
      if (converti == null) continue;
      sortie.add(<String, Object?>{
        'id': ligne['id'],
        'description': ligne['description'],
        'dateEcheance': converti,
      });
    }
  }
  return <String, Object?>{
    'schemaVersion': d['schemaVersion'],
    'echeances': sortie,
  };"""
        },
        {
            "A2_montee_transforme",
            "A3_aller_retour",
            "A5_cles_inconnues",
            "A6_jamais_de_conversion_avec_perte",
        },
    ),
    "M5_version_future_acceptee": (
        {
            "MIGRER_CORPS": """  final depart = lireVersion(document);
  if (depart == null) return null;
  if (cible < 1 || cible > versionCourante) return null;
  var doc = Map<String, Object?>.from(document);
  var v = depart;
  while (v < cible) {
    doc = _etapePour(v + 1).up(doc);
    v++;
  }
  while (v > cible) {
    if (etapesMigration.any((e) => e.version == v)) {
      doc = _etapePour(v).down(doc);
    }
    v--;
  }
  doc['schemaVersion'] = cible;
  return doc;"""
        },
        {"A7_version_non_supportee"},
    ),
    "M6_up_produit_un_instant_utc": (
        {
            "UP_DATE_CORPS": """  final DateTime t;
  try {
    t = DateTime.parse(iso);
  } on FormatException {
    return null;
  }
  if (!t.isUtc) return null;
  return t.toIso8601String();"""
        },
        {"A2_montee_transforme", "A8_forme_canonique_civile"},
    ),
    "M7_down_egale_up": (
        {"DOWN_REF": "_v1VersV2"},
        {"A1_contrat_couple", "A3_aller_retour"},
    ),
}


# --------------------------------------------------------------------------
# La SONDE : elle ne teste rien, elle MESURE le comportement de dart:core sur
# les cas qui gouvernent la forme du schema. C'est elle qui a etabli, le
# 2026-08-06, que l'aller-retour v1 <-> v2 n'est PAS exact partout -- fait qui
# rend la garde d'inversibilite OBLIGATOIRE et non decorative.
# --------------------------------------------------------------------------
SONDE = r"""
String d2(int n) => n.toString().padLeft(2, '0');

String civil(DateTime l) =>
    '${l.year.toString().padLeft(4, '0')}-${d2(l.month)}-${d2(l.day)}'
    'T${d2(l.hour)}:${d2(l.minute)}';

void cas(String titre, String v1) {
  final t = DateTime.parse(v1);
  final v2 = civil(t.toLocal());
  final retour = DateTime.parse(v2).toUtc().toIso8601String();
  final garde = DateTime.parse(v2).toUtc() == t;
  print('${titre.padRight(34)} v1=$v1  up=$v2  down=$retour  '
      'ALLER_RETOUR_EXACT=${retour == v1}  GARDE=$garde');
}

void main() {
  // Le nom de fuseau vient de l'OS et n'est pas ASCII sur un Windows francais :
  // il est translittere, sinon la sortie devient illisible sur une console cp1252
  // (piege deja paye par ce depot).
  final nomFuseau =
      DateTime.now().timeZoneName.replaceAll(RegExp(r'[^\x20-\x7E]'), '?');
  print('fuseau=$nomFuseau  '
      'offset_janvier=${DateTime(2026, 1, 15, 12).timeZoneOffset}  '
      'offset_juillet=${DateTime(2026, 7, 15, 12).timeZoneOffset}');
  cas('nominal hiver', '2026-11-15T22:59:00.000Z');
  cas('nominal ete', '2026-07-15T21:59:00.000Z');
  cas('secondes non nulles', '2026-11-15T22:59:30.000Z');
  cas('millisecondes non nulles', '2026-11-15T22:59:00.500Z');
  cas('bascule automne 1re occurrence', '2026-10-25T00:30:00.000Z');
  cas('bascule automne 2e occurrence', '2026-10-25T01:30:00.000Z');
  cas('bascule printemps', '2026-03-29T01:30:00.000Z');
  // Sens v2 -> v1 -> v2 : une heure civile qui N EXISTE PAS localement.
  const inexistante = '2026-03-29T02:30';
  final versUtc = DateTime.parse(inexistante).toUtc().toIso8601String();
  final revenu = civil(DateTime.parse(versUtc).toLocal());
  print('heure civile inexistante          v2=$inexistante  down=$versUtc  '
      'up=$revenu  ALLER_RETOUR_EXACT=${revenu == inexistante}');
  // Un piege du parseur : une date hors calendrier ne LEVE PAS.
  final debordee = DateTime.parse('2026-02-31T23:59');
  print('date hors calendrier 2026-02-31T23:59 -> parse rend ${civil(debordee)} '
      'SANS exception ; forme canonique preservee='
      '${civil(debordee) == '2026-02-31T23:59'}');
  for (final s in <String>['2026-11-15', '2026-11-15T23:59:00Z']) {
    final p = DateTime.parse(s);
    print('parse("$s") -> ${p.toIso8601String()} isUtc=${p.isUtc} '
        'forme canonique preservee=${!p.isUtc && civil(p) == s}');
  }
}
"""


def sonde() -> int:
    print("== SONDE : comportement REEL de dart:core sur la forme du schema ==")
    print("   (elle ne teste rien : elle mesure. Rejouable sur tout poste.)")
    cible = ATELIER / "sonde_date_civile.dart"
    _ecrire(cible, SONDE)
    proc = subprocess.run(
        [_dart(), "run", str(cible)],
        cwd=str(RACINE),
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    print((proc.stdout or "") + (proc.stderr or ""), end="")
    return proc.returncode


def _source_fixture(surcharges: dict) -> str:
    fentes = dict(FENTES_CONFORMES)
    for cle, valeur in surcharges.items():
        if cle not in fentes:
            raise SystemExit("fente inconnue : %s" % cle)
        fentes[cle] = valeur
    source = GABARIT_FIXTURE
    for cle, valeur in fentes.items():
        marqueur = "__%s__" % cle
        if marqueur not in source:
            raise SystemExit("fente absente du gabarit : %s" % marqueur)
        source = source.replace(marqueur, valeur)
    # Controle negatif : une fente laissee en place produirait un Dart qui ne
    # compile pas, donc un mutant qui ne mesure rien. On le refuse ICI.
    # ⚠️ Il cherche TOUTE fente residuelle, pas seulement celles dont le nom est
    # connu : une fente au nom MAL ORTHOGRAPHIE est justement celle qu'aucune
    # substitution n'atteint. Une premiere version de ce garde-fou ne regardait
    # que les noms connus -- elle etait MORTE (ils sont tous substitues par
    # construction), et c'est un mutant qui l'a montre le 2026-08-06.
    restes = sorted(set(re.findall(r"__[A-Z][A-Z0-9_]*__", source)))
    if restes:
        raise SystemExit("fentes non substituees : %s" % restes)
    return source


def _ecrire(chemin: Path, contenu: str) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    with io.open(chemin, "w", encoding="utf-8", newline="\n") as f:
        f.write(contenu)


def _harnais(import_dart: str) -> str:
    ids = ",".join("'%s'" % i for i in IDS_CONVERTIBLES)
    return (
        HARNAIS.replace("__IMPORT__", import_dart)
        .replace("__GRAINE__", GRAINE_V1)
        .replace("__IDS__", ids)
    )


def _dart() -> str:
    chemin = shutil.which("dart")
    if not chemin:
        raise SystemExit(
            "ERREUR : le SDK Dart est introuvable dans le PATH. Ce critere exige "
            "dart (mesure ADR-009 : Dart 3.12.2 sur ce poste)."
        )
    return chemin


def _executer(nom_harnais: str, import_dart: str) -> tuple:
    """Rend (code_retour, lignes) apres execution reelle du harnais Dart."""
    cible = ATELIER / nom_harnais
    _ecrire(cible, _harnais(import_dart))
    proc = subprocess.run(
        [_dart(), "run", str(cible)],
        cwd=str(RACINE),
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    sortie = (proc.stdout or "") + (proc.stderr or "")
    return proc.returncode, sortie.splitlines()


def _echecs(lignes: list) -> set:
    echecs = set()
    for ligne in lignes:
        if ligne.startswith("ASSERTION|"):
            morceaux = ligne.split("|")
            if len(morceaux) >= 3 and morceaux[2] == "ECHEC":
                echecs.add(morceaux[1])
    return echecs


def _a_tourne(lignes: list) -> bool:
    return any(l.startswith("VERDICT|") for l in lignes)


def selftest() -> int:
    print("== AUTOTEST DE MUTATION du critere de sortie US-01.2 ==")
    print("   8 assertions x %d sources Dart (1 conforme + %d mutants "
          "COMPORTEMENTAUX)" % (len(MUTANTS), len(MUTANTS) - 1))
    print("   Verdicts compares en ENSEMBLES, jamais en cardinaux.")
    print("")
    conforme = _source_fixture({})
    ecarts = []
    couverture = set()
    for nom in sorted(MUTANTS):
        surcharges, attendu = MUTANTS[nom]
        source = _source_fixture(surcharges)
        # Controle negatif : un mutant qui ne mute rien ne mesure rien.
        if nom != "M0_conforme" and source == conforme:
            ecarts.append("%s : la source du mutant est IDENTIQUE a la conforme" % nom)
            continue
        fichier = ATELIER / ("fixture_%s.dart" % nom.lower())
        _ecrire(fichier, source)
        code, lignes = _executer(
            "harnais_%s.dart" % nom.lower(), "fixture_%s.dart" % nom.lower()
        )
        if not _a_tourne(lignes):
            ecarts.append(
                "%s : le harnais n a pas rendu de VERDICT (code %d)\n     %s"
                % (nom, code, "\n     ".join(lignes[:12]))
            )
            continue
        obtenu = _echecs(lignes)
        couverture |= obtenu
        etat = "OK " if obtenu == attendu else "ECART"
        print("[%s] %-32s attendu=%s" % (etat, nom, sorted(attendu) or "aucun echec"))
        print("        %-32s obtenu =%s" % ("", sorted(obtenu) or "aucun echec"))
        if obtenu != attendu:
            ecarts.append(
                "%s : manquants=%s inattendus=%s"
                % (nom, sorted(attendu - obtenu), sorted(obtenu - attendu))
            )
            for ligne in lignes:
                if "|ECHEC|" in ligne:
                    print("        %s" % ligne)
    print("")
    non_tuees = sorted({"A1_contrat_couple", "A2_montee_transforme", "A3_aller_retour",
                        "A4_idempotence", "A5_cles_inconnues",
                        "A6_jamais_de_conversion_avec_perte",
                        "A7_version_non_supportee",
                        "A8_forme_canonique_civile"} - couverture)
    print("Assertions tuees par au moins un mutant : %s" % sorted(couverture))
    if non_tuees:
        print("Assertions qu AUCUN mutant ne tue (a ne PAS lire comme eprouvees) : %s"
              % non_tuees)
    if ecarts:
        print("")
        print("AUTOTEST EN ECHEC :")
        for e in ecarts:
            print("  - %s" % e)
        return 1
    print("")
    print("AUTOTEST OK : le critere sait rougir, et sur les bonnes assertions.")
    return 0


def contre_lib() -> int:
    print("== CRITERE DE SORTIE : patron aller-retour ADR-005 sur le module REEL ==")
    print("   cible : %s" % MODULE_CIBLE.relative_to(RACINE).as_posix())
    if not MODULE_CIBLE.exists():
        print("")
        print("NON SATISFAIT -- le module n existe pas encore (tache T5 non livree).")
        print("Ce n est PAS un echec du critere : il est REJOUABLE en l etat, et il")
        print("rendra exit 0 le jour ou T5 livrera un couple up/down conforme.")
        print("Pouvoir du critere mesurable des AUJOURD HUI : --selftest")
        return 1
    code, lignes = _executer("harnais_lib.dart", IMPORT_CIBLE)
    for ligne in lignes:
        print(ligne)
    if not _a_tourne(lignes):
        print("")
        print("NON SATISFAIT -- le module ne respecte pas le CONTRAT attendu "
              "(le harnais ne compile pas). Voir la sortie du compilateur ci-dessus "
              "et docs/architecture/SCHEMA_STOCKAGE_ECHEANCES.md section Contrat.")
        return 1
    if code == 0:
        print("")
        print("SATISFAIT -- 8 assertions vertes. Le patron de MIGRATIONS.md section 4")
        print("est INSTANCIE ET EXECUTE sur le premier schema reel du projet.")
        return 0
    print("")
    print("NON SATISFAIT -- voir les lignes ASSERTION|...|ECHEC ci-dessus.")
    return 1


def contre_fixture(nom: str) -> int:
    """Joue le patron contre une source EMBARQUEE et imprime tout le journal."""
    if nom not in MUTANTS:
        print("Sources disponibles : %s" % sorted(MUTANTS))
        return 1
    surcharges, attendu = MUTANTS[nom]
    print("== Patron aller-retour ADR-005 joue contre la source EMBARQUEE %s ==" % nom)
    print("   (source de FIXTURE, PAS le module de lib/ -- voir l en-tete)")
    fichier = ATELIER / ("fixture_%s.dart" % nom.lower())
    _ecrire(fichier, _source_fixture(surcharges))
    code, lignes = _executer(
        "harnais_%s.dart" % nom.lower(), "fixture_%s.dart" % nom.lower()
    )
    for ligne in lignes:
        print(ligne)
    print("")
    print("echecs attendus pour cette source : %s" % (sorted(attendu) or "aucun"))
    return code


def main() -> int:
    parseur = argparse.ArgumentParser(
        description="Critere de sortie du patron aller-retour ADR-005 (US-01.2)."
    )
    parseur.add_argument(
        "--selftest",
        action="store_true",
        help="mesurer le POUVOIR du critere sur 1 source conforme et 7 mutants",
    )
    parseur.add_argument(
        "--fixture",
        metavar="NOM",
        help="jouer le patron contre une source embarquee et imprimer le journal "
        "complet (ex. M0_conforme)",
    )
    parseur.add_argument(
        "--sonde",
        action="store_true",
        help="mesurer le comportement de dart:core sur les bascules d heure, les "
        "secondes et les formes non canoniques",
    )
    args = parseur.parse_args()
    if args.selftest:
        return selftest()
    if args.sonde:
        return sonde()
    if args.fixture:
        return contre_fixture(args.fixture)
    return contre_lib()


if __name__ == "__main__":
    sys.exit(main())
