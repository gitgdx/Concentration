#!/usr/bin/env python3
"""Critere de sortie EXECUTABLE de la GARDE du couple v2 <=> v3 (US-01.4).

POURQUOI CE FICHIER EXISTE, ET POURQUOI IL N'EST PAS UNE COPIE DU PRECEDENT
--------------------------------------------------------------------------
Le critere d'US-01.2 (reports/US-01.2/migration_roundtrip_criterion.py) est
CONSERVE, EXIGE et BIT-A-BIT INCHANGE -- git diff vide sur lui : "c'est le fait de
ne pas l'avoir touche qui rendait sa mesure croyable". Mais sa graine ne porte
AUCUNE cle `retiree`, et une graine ne peut pas observer la destruction d'une
information qu'elle ne contient pas. Ce n'est pas une faiblesse d'assertion,
c'est une impossibilite logique.

MESURE QUI JUSTIFIE CE FICHIER (reproduite par --selftest) : QUATRE formes de
up/down explicitement interdites par ADR-012 section 4 passent le critere
d'US-01.2 avec ses 8 assertions VERTES. La plus dangereuse est celle qui a l'air
la plus propre -- "redescendre proprement en retirant la cle" -- et elle detruit
l'information de retrait, donc fait tomber AC-12 "Erreur" d'US-01.2, une US EN
AVAL, deja validee.

CE QU'IL FAIT, ET DANS QUEL ORDRE IL FAUT LE LIRE
-------------------------------------------------
  --selftest   Joue les 8 assertions contre 7 sources Dart derivees du module
               REEL par patch d'UNE SEULE fente comportementale chacune (1
               conforme + 6 mutants). Il compare, pour chaque source, l'ENSEMBLE
               des assertions en echec a l'ENSEMBLE attendu -- des ENSEMBLES,
               jamais des cardinaux. Controle negatif : une source identique a la
               conforme est REFUSEE. Ce mode mesure LE POUVOIR de la garde, et il
               tourne AVANT que la tache T3 existe.
  --croise     Rejoue les MEMES sources contre le critere d'US-01.2 (inchange) et
               imprime la matrice des deux instruments cote a cote. C'est ce mode
               qui etablit que les deux ne sont PAS redondants -- dans les DEUX
               SENS -- et qu'aucune de leurs assertions ne doit etre dupliquee.
  --parc       Mesure, sur un document du PARC (9 entrees, aucune cle `retiree`),
               (1) l'EFFET EXACT du `up` -- prefixe et suffixe COMMUNS calcules,
               donc le diff REEL, jamais decrit -- et (2) le poids d'un
               historique qui n'a AUCUN plafond, le document ENTIER etant
               reecrit a chaque ecriture (dette nommee).
  (defaut)     Joue les 8 assertions contre le module REEL
               lib/features/echeances/data/echeance_schema_migrations.dart.
               Tant qu'il n'est pas en v3, le critere rend exit 1 en le disant
               PLATEMENT : il est REJOUABLE, il n'est pas encore SATISFAIT.

CE QU'IL N'ATTESTE PAS
----------------------
  - Il ne remplace AUCUN test de test/. La garde du couple v2 <=> v3 doit vivre
    dans flutter test, qui EST un gate requis ; ce script est un critere de
    sortie rejouable, PAS un gate CI (il exige le SDK Dart).
  - Il porte sur les fonctions PURES de migration (Map -> Map). Il ne teste ni le
    codec, ni l'entite, ni le magasin, ni l'ecriture atomique : les regles F-1 a
    F-3 du section 2 bis du schema de stockage relevent des tests unitaires du
    codec et de l'entite.
  - Les sources de --selftest sont des FIXTURES derivees : leurs fonctions v3
    portent des noms propres a ce critere (_g3*) pour ne JAMAIS entrer en
    collision avec celles que T3 ecrira. NE PAS LES COPIER DANS lib/.

Usage :
    python reports/US-01.4/migration_v3_guard_criterion.py --selftest
    python reports/US-01.4/migration_v3_guard_criterion.py --croise
    python reports/US-01.4/migration_v3_guard_criterion.py --parc
    python reports/US-01.4/migration_v3_guard_criterion.py
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
MODULE_CIBLE = (RACINE / "lib" / "features" / "echeances" / "data"
                / "echeance_schema_migrations.dart")
IMPORT_CIBLE = ("package:concentration/features/echeances/data"
                "/echeance_schema_migrations.dart")
CRITERE_US012 = RACINE / "reports" / "US-01.2" / "migration_roundtrip_criterion.py"
ATELIER = RACINE / ".dart_tool" / "us014_migration_v3_guard"

# --------------------------------------------------------------------------
# LA GRAINE -- c'est ELLE le livrable, pas les assertions.
# MIGRATIONS.md section 4 (amende le 2026-08-24) : "la graine doit contenir au
# moins une instance de la donnee dont la migration PARLE, dans CHAQUE forme que
# sa grammaire declare".
#   r1 : retiree = true                        -> le fait a ne jamais perdre
#   r2 : retiree = false                       -> forme LICITE, jamais ecrite
#   r3 : retiree = true + cle INCONNUE `garde` -> detecte une recomposition
#   r4 : retiree = "oui"                       -> hors domaine => RESIDU
#   r5 : aucune cle retiree                    -> le cas de TOUT le parc installe
#   ligne non-objet + cle de tete inconnue     -> transport de l'incompris
# --------------------------------------------------------------------------
GRAINE_V2 = (
    '{"schemaVersion":2,'
    '"echeances":['
    '{"id":"r1","description":"Convent","dateEcheance":"2026-11-15T23:59","retiree":true},'
    '{"id":"r2","description":"","dateEcheance":"2026-07-15T23:59","retiree":false},'
    '{"id":"r3","description":"Revue","dateEcheance":"2027-01-09T23:59","retiree":true,"garde":7},'
    '{"id":"r4","description":"hors domaine","dateEcheance":"2027-03-02T23:59","retiree":"oui"},'
    '{"id":"r5","description":"jamais retiree","dateEcheance":"2027-05-04T23:59"},'
    '"ceci n est pas un objet"'
    '],'
    '"_inconnu":{"garde":true}}'
)

# La MEME graine en v1, pour la NON-REGRESSION du couple v1 <=> v2 en presence de
# la nouvelle etape : la chaine de DEUX etapes, dans les deux sens. Les instants
# sont choisis INVERSIBLES (secondes et millisecondes nulles, hors heure repetee)
# -- sinon la garde de v1 <=> v2 les laisse verbatim, ce qui est son travail.
GRAINE_V1 = (
    '{"schemaVersion":1,'
    '"echeances":['
    '{"id":"r1","description":"Convent","dateEcheance":"2026-11-15T22:59:00.000Z","retiree":true},'
    '{"id":"r5","description":"jamais retiree","dateEcheance":"2027-05-04T21:59:00.000Z"}'
    '],'
    '"_inconnu":{"garde":true}}'
)

ASSERTIONS = (
    "B1_up_identite_sur_les_entrees",
    "B2_aller_retour_v2_v3_v2",
    "B3_aller_retour_v3_v2_v3",
    "B4_true_survit_au_down",
    "B5_false_laisse_verbatim_par_le_down",
    "B6_up_n_ajoute_aucune_cle",
    "B7_cle_inconnue_et_residu_survivent",
    "B8_chaine_v1_v3_v1",
)

# --------------------------------------------------------------------------
# LE HARNAIS : il ne connait du module que le CONTRAT publie au section 4 du
# schema de stockage. Chaque assertion imprime ASSERTION|<nom>|OK|ECHEC|<detail>.
# --------------------------------------------------------------------------
HARNAIS = r"""
import 'dart:convert';
import 'dart:io';
import '__IMPORT__' as m;

const String graineV2Json = r'''__GRAINE_V2__''';
const String graineV1Json = r'''__GRAINE_V1__''';

class _Echec implements Exception {
  _Echec(this.message);
  final String message;
}

void exige(bool condition, String message) {
  if (!condition) throw _Echec(message);
}

Map<String, Object?> lire(String json) =>
    Map<String, Object?>.from(jsonDecode(json) as Map);

Map<String, Object?> graineV2() => lire(graineV2Json);
Map<String, Object?> graineV1() => lire(graineV1Json);
Map<String, Object?> graineV3() => graineV2()..['schemaVersion'] = 3;

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
  // CONTEXTE : imprime, jamais suppose.
  print('CONTEXTE|dart=${Platform.version.split(' ').first}'
      '|versionCourante=${m.versionCourante}'
      '|etapes=${m.etapesMigration.map((e) => e.version).toList()}');

  // B1 -- le `up` NE TOUCHE AUCUNE ENTREE : dans tout le document, le seul octet
  // qui change est celui de schemaVersion (ADR-012 section 4).
  assertion('B1_up_identite_sur_les_entrees', () {
    final haut = m.migrer(graineV2(), cible: 3);
    exige(haut != null, 'migrer a rendu null sur un document v2 valide');
    exige(
        jsonEncode(haut!['echeances']) == jsonEncode(graineV2()['echeances']),
        'le `up` a MODIFIE le tableau des entrees\n'
        '       attendu = ${jsonEncode(graineV2()['echeances'])}\n'
        '       obtenu  = ${jsonEncode(haut['echeances'])}');
    exige(m.lireVersion(haut) == 3,
        'le `up` n a pas reecrit schemaVersion (lu ${m.lireVersion(haut)})');
  });

  // B2 -- LE PATRON de MIGRATIONS.md section 4, sur une graine qui CONTIENT des
  // entrees retirees -- exactement ce que la graine du critere d'US-01.2 n'a pas.
  assertion('B2_aller_retour_v2_v3_v2', () {
    final avant = jsonEncode(graineV2());
    final haut = m.migrer(graineV2(), cible: 3);
    exige(haut != null, 'up : migrer a rendu null');
    final bas = m.migrer(haut!, cible: 2);
    exige(bas != null, 'down : migrer a rendu null');
    exige(
        jsonEncode(bas!) == avant,
        'ALLER-RETOUR NON EXACT\n       attendu = $avant\n'
        '       obtenu  = ${jsonEncode(bas)}');
  });

  // B3 -- L AUTRE SENS, celui qu un document REDESCENDU puis remonte emprunte
  // (le cas meme pour lequel ADR-005 a refuse le "forward-only"). C est la SEULE
  // assertion qui voit un `up` qui "nettoierait" une cle que v2 ne connait pas.
  assertion('B3_aller_retour_v3_v2_v3', () {
    final avant = jsonEncode(graineV3());
    final bas = m.migrer(lire(avant), cible: 2);
    exige(bas != null, 'down : migrer a rendu null');
    final haut = m.migrer(bas!, cible: 3);
    exige(haut != null, 'up : migrer a rendu null');
    exige(
        jsonEncode(haut!) == avant,
        'ALLER-RETOUR NON EXACT (sens v3 -> v2 -> v3)\n'
        '       attendu = $avant\n       obtenu  = ${jsonEncode(haut)}');
  });

  // B4 -- le fait a ne jamais perdre : `retiree: true` SURVIT au down, cle
  // CONSERVEE, valeur booleenne, entree identique AUX OCTETS.
  assertion('B4_true_survit_au_down', () {
    final bas = m.migrer(graineV3(), cible: 2);
    exige(bas != null, 'down : migrer a rendu null');
    for (final id in <String>['r1', 'r3']) {
      final e = parId(bas!, id);
      exige(e != null, 'entree $id : DISPARUE au down');
      exige(
          e!.containsKey('retiree'),
          'entree $id : la cle `retiree` a ete RETIREE par le down -- AC-12 '
          '"Erreur" d US-01.2 (US EN AVAL) tombe');
      exige(e['retiree'] == true,
          'entree $id : `retiree` vaut ${jsonEncode(e['retiree'])} apres le down');
      exige(
          jsonEncode(e) == jsonEncode(parId(graineV2(), id)),
          'entree $id : octets modifies par le down\n'
          '       attendu = ${jsonEncode(parId(graineV2(), id))}\n'
          '       obtenu  = ${jsonEncode(e)}');
    }
  });

  // B5 -- `false` est une forme LICITE : le down la laisse VERBATIM elle aussi.
  // Ce n est pas un detail : un down qui sait "nettoyer les false" sait retirer
  // la cle, et il retirera un `true` au premier remaniement.
  assertion('B5_false_laisse_verbatim_par_le_down', () {
    final bas = m.migrer(graineV3(), cible: 2);
    exige(bas != null, 'down : migrer a rendu null');
    final e = parId(bas!, 'r2');
    exige(e != null, 'entree r2 : DISPARUE au down');
    exige(
        e!.containsKey('retiree') && e['retiree'] == false,
        'entree r2 : le down a touche un `retiree: false` '
        '(obtenu ${jsonEncode(e['retiree'])})');
  });

  // B6 -- aucune entree ne GAGNE de cle au up : la forme "explicite partout"
  // FABRIQUE le down destructif qu ADR-012 section 4 interdit.
  assertion('B6_up_n_ajoute_aucune_cle', () {
    final haut = m.migrer(graineV2(), cible: 3);
    exige(haut != null, 'up : migrer a rendu null');
    final e = parId(haut!, 'r5');
    exige(e != null, 'entree r5 : disparue au up');
    exige(
        !e!.containsKey('retiree'),
        'entree r5 : le `up` a AJOUTE une cle `retiree` -- son down devrait alors '
        'la RETIRER, donc detruire un `true` preexistant');
  });

  // B7 -- rien n est recompose : cle d entree INCONNUE d une entree retiree,
  // entree RESIDUELLE (retiree hors domaine) et cle de TETE inconnue survivent
  // a leur place, dans les deux sens.
  assertion('B7_cle_inconnue_et_residu_survivent', () {
    final haut = m.migrer(graineV2(), cible: 3);
    exige(haut != null, 'up : migrer a rendu null');
    exige(jsonEncode(parId(haut!, 'r3')?['garde']) == jsonEncode(7),
        'la cle inconnue d une entree RETIREE a ete perdue par le up');
    exige(
        jsonEncode(parId(haut, 'r4')) == jsonEncode(parId(graineV2(), 'r4')),
        'l entree a `retiree` HORS DOMAINE (residu) a ete alteree par le up : '
        '${jsonEncode(parId(haut, 'r4'))}');
    final bas = m.migrer(haut, cible: 2);
    exige(bas != null, 'down : migrer a rendu null');
    exige(jsonEncode(parId(bas!, 'r4')) == jsonEncode(parId(graineV2(), 'r4')),
        'l entree residuelle a ete alteree par le down');
    exige(jsonEncode(bas['_inconnu']) == jsonEncode(graineV2()['_inconnu']),
        'la cle de TETE inconnue a ete perdue');
  });

  // B8 -- NON-REGRESSION du couple v1 <=> v2 EN PRESENCE de la nouvelle etape :
  // la chaine de DEUX etapes, dans les deux sens, sur un document v1 portant
  // deja une entree retiree (cas d un document redescendu jusqu a v1).
  assertion('B8_chaine_v1_v3_v1', () {
    final avant = jsonEncode(graineV1());
    final haut = m.migrer(graineV1(), cible: 3);
    exige(haut != null, 'up : migrer a rendu null');
    exige(m.lireVersion(haut!) == 3,
        'la chaine ne mene pas a v3 (lu ${m.lireVersion(haut)})');
    final civil = parId(haut, 'r1')?['dateEcheance'];
    exige(civil is String && !civil.contains('Z'),
        'la date n a pas ete convertie par la chaine : ${jsonEncode(civil)}');
    exige(parId(haut, 'r1')?['retiree'] == true,
        'le `retiree` a ete perdu par la chaine MONTANTE');
    final bas = m.migrer(haut, cible: 1);
    exige(bas != null, 'down : migrer a rendu null');
    exige(
        jsonEncode(bas!) == avant,
        'ALLER-RETOUR NON EXACT sur la chaine v1 -> v3 -> v1\n'
        '       attendu = $avant\n       obtenu  = ${jsonEncode(bas)}');
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
# LES SOURCES DE L AUTOTEST : derivees du module REEL par patch de DEUX fentes.
# Les fonctions v3 portent des noms propres a ce critere (_g3*) pour ne JAMAIS
# entrer en collision avec celles que T3 ecrira dans lib/.
# --------------------------------------------------------------------------
FENTE_VERSION = re.compile(r"^const int versionCourante = \d+;", re.MULTILINE)
FENTE_ETAPES = re.compile(
    r"(const List<EtapeMigration> etapesMigration = <EtapeMigration>\[)"
    r".*?(\n\];)",
    re.DOTALL,
)
IMPORT_RELATIF = "import '../domain/date_civile.dart';"
IMPORT_PAQUET = ("import 'package:concentration/features/echeances/domain"
                 "/date_civile.dart';")

_IDENT = ("Map<String, Object?> %s(Map<String, Object?> d) =>\n"
          "    Map<String, Object?>.from(d);\n")


def _parcours(nom, corps):
    """Un up/down qui parcourt les entrees ; `corps` remplit `copie`."""
    return ("Map<String, Object?> %s(Map<String, Object?> d) {\n"
            "  final brut = d['echeances'];\n"
            "  if (brut is! List) return Map<String, Object?>.from(d);\n"
            "  final sortie = <Object?>[];\n"
            "  for (final ligne in brut) {\n"
            "    if (ligne is! Map) { sortie.add(ligne); continue; }\n"
            "    final copie = <String, Object?>{};\n"
            "%s"
            "    sortie.add(copie);\n"
            "  }\n"
            "  final r = Map<String, Object?>.from(d);\n"
            "  r['echeances'] = sortie;\n"
            "  return r;\n"
            "}\n") % (nom, corps)


_RETIRE_TOUT = ("    ligne.forEach((k, v) {\n"
                "      if (k.toString() != 'retiree') copie[k.toString()] = v;\n"
                "    });\n")
_RETIRE_FALSE = ("    ligne.forEach((k, v) {\n"
                 "      if (k.toString() == 'retiree' && v == false) return;\n"
                 "      copie[k.toString()] = v;\n"
                 "    });\n")
_AJOUTE_FALSE = ("    ligne.forEach((k, v) { copie[k.toString()] = v; });\n"
                 "    copie['retiree'] = copie['retiree'] ?? false;\n")
_RECOMPOSE = ("    for (final k in const <String>['id', 'description',\n"
              "        'dateEcheance', 'retiree']) {\n"
              "      if (ligne.containsKey(k)) copie[k] = ligne[k];\n"
              "    }\n")

# nom -> (etape v3 inseree, fonctions ajoutees, ENSEMBLE attendu d'echecs)
SOURCES = {
    "M0_conforme": (
        "  EtapeMigration(3, _g3Up, _g3Down),",
        (_IDENT % "_g3Up") + "\n" + (_IDENT % "_g3Down"),
        set(),
    ),
    "M1_down_retire_la_cle": (
        "  EtapeMigration(3, _g3Up, _g3Down),",
        (_IDENT % "_g3Up") + "\n" + _parcours("_g3Down", _RETIRE_TOUT),
        {"B2_aller_retour_v2_v3_v2", "B3_aller_retour_v3_v2_v3",
         "B4_true_survit_au_down", "B5_false_laisse_verbatim_par_le_down",
         "B7_cle_inconnue_et_residu_survivent", "B8_chaine_v1_v3_v1"},
    ),
    "M2_down_nettoie_les_false": (
        "  EtapeMigration(3, _g3Up, _g3Down),",
        (_IDENT % "_g3Up") + "\n" + _parcours("_g3Down", _RETIRE_FALSE),
        {"B2_aller_retour_v2_v3_v2", "B3_aller_retour_v3_v2_v3",
         "B5_false_laisse_verbatim_par_le_down"},
    ),
    "M3_up_ecrit_false_partout": (
        "  EtapeMigration(3, _g3Up, _g3Down),",
        _parcours("_g3Up", _AJOUTE_FALSE) + "\n"
        + _parcours("_g3Down", _RETIRE_TOUT),
        set(ASSERTIONS),
    ),
    "M4_up_nettoie_la_cle": (
        "  EtapeMigration(3, _g3Up, _g3Down),",
        _parcours("_g3Up", _RETIRE_TOUT) + "\n" + (_IDENT % "_g3Down"),
        {"B1_up_identite_sur_les_entrees", "B2_aller_retour_v2_v3_v2",
         "B3_aller_retour_v3_v2_v3", "B7_cle_inconnue_et_residu_survivent",
         "B8_chaine_v1_v3_v1"},
    ),
    "M5_recompose_l_entree": (
        "  EtapeMigration(3, _g3Up, _g3Down),",
        _parcours("_g3Up", _RECOMPOSE) + "\n"
        + _parcours("_g3Down", _RECOMPOSE),
        {"B1_up_identite_sur_les_entrees", "B2_aller_retour_v2_v3_v2",
         "B3_aller_retour_v3_v2_v3", "B4_true_survit_au_down",
         "B7_cle_inconnue_et_residu_survivent"},
    ),
    # Mutant NOMME pour qu il ne soit PAS teste deux fois : il est deja tue par
    # A1 du critere d US-01.2 (tear-offs canonicalises dans une liste const), et
    # la garde ne le voit PAS -- c est la preuve que les deux instruments ne sont
    # pas redondants, DANS LES DEUX SENS.
    "M6_une_seule_fonction": (
        "  EtapeMigration(3, _g3Identite, _g3Identite),",
        _IDENT % "_g3Identite",
        set(),
    ),
}


def _dart() -> str:
    chemin = shutil.which("dart")
    if not chemin:
        raise SystemExit(
            "ERREUR : le SDK Dart est introuvable dans le PATH. Ce critere exige "
            "dart (mesure : Dart 3.12.2 sur ce poste)."
        )
    return chemin


def _ecrire(chemin: Path, contenu: str) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    with io.open(chemin, "w", encoding="utf-8", newline="\n") as f:
        f.write(contenu)


def _harnais(import_dart: str) -> str:
    return (
        HARNAIS.replace("__IMPORT__", import_dart)
        .replace("__GRAINE_V2__", GRAINE_V2)
        .replace("__GRAINE_V1__", GRAINE_V1)
    )


def _source(nom: str) -> str:
    """Le module REEL, patche sur DEUX fentes nommees. Une fente absente fait
    echouer la generation -- aucune substitution textuelle aveugle."""
    if not MODULE_CIBLE.exists():
        raise SystemExit(
            "ERREUR : %s est introuvable -- l autotest derive ses sources du "
            "module REEL." % MODULE_CIBLE.relative_to(RACINE).as_posix()
        )
    src = MODULE_CIBLE.read_text(encoding="utf-8")
    etape, fns, _ = SOURCES[nom]
    if not FENTE_VERSION.search(src):
        raise SystemExit("fente `const int versionCourante = N;` absente")
    src = FENTE_VERSION.sub("const int versionCourante = 3;", src, count=1)
    if not FENTE_ETAPES.search(src):
        raise SystemExit("fente `etapesMigration` absente")
    src = FENTE_ETAPES.sub(
        lambda mo: mo.group(1) + "\n  EtapeMigration(2, _v1VersV2, _v2VersV1),\n"
        + (etape + "\n" if etape else "") + mo.group(2).lstrip("\n"),
        src,
        count=1,
    )
    if IMPORT_RELATIF in src:
        src = src.replace(IMPORT_RELATIF, IMPORT_PAQUET)
    return src + "\n" + fns


def _executer(nom_harnais: str, import_dart: str) -> tuple:
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


def _jouer_source(nom: str) -> tuple:
    """Rend (echecs_garde, lignes) pour une source derivee."""
    fichier = ATELIER / ("fixture_%s.dart" % nom.lower())
    _ecrire(fichier, _source(nom))
    return _executer("harnais_%s.dart" % nom.lower(),
                     "fixture_%s.dart" % nom.lower())


def selftest() -> int:
    print("== AUTOTEST DE MUTATION de la garde v2 <=> v3 (US-01.4) ==")
    print("   %d assertions x %d sources derivees du module REEL "
          "(1 conforme + %d mutants)" % (len(ASSERTIONS), len(SOURCES),
                                         len(SOURCES) - 1))
    print("   Verdicts compares en ENSEMBLES, jamais en cardinaux.")
    print("")
    conforme = _source("M0_conforme")
    ecarts = []
    couverture = set()
    for nom in sorted(SOURCES):
        attendu = SOURCES[nom][2]
        # Controle negatif : un mutant qui ne mute rien ne mesure rien.
        if nom != "M0_conforme" and _source(nom) == conforme:
            ecarts.append("%s : la source du mutant est IDENTIQUE a la conforme"
                          % nom)
            continue
        code, lignes = _jouer_source(nom)
        if not _a_tourne(lignes):
            ecarts.append("%s : le harnais n a pas rendu de VERDICT (code %d)\n"
                          "     %s" % (nom, code, "\n     ".join(lignes[:12])))
            continue
        obtenu = _echecs(lignes)
        couverture |= obtenu
        etat = "OK " if obtenu == attendu else "ECART"
        print("[%s] %-28s attendu=%s" % (etat, nom, sorted(attendu) or "aucun"))
        print("        %-28s obtenu =%s" % ("", sorted(obtenu) or "aucun"))
        if obtenu != attendu:
            ecarts.append("%s : manquants=%s inattendus=%s"
                          % (nom, sorted(attendu - obtenu),
                             sorted(obtenu - attendu)))
            for ligne in lignes:
                if "|ECHEC|" in ligne:
                    print("        %s" % ligne)
    print("")
    non_tuees = sorted(set(ASSERTIONS) - couverture)
    print("Assertions tuees par au moins un mutant : %s" % sorted(couverture))
    if non_tuees:
        print("Assertions qu AUCUN mutant ne tue (a ne PAS lire comme "
              "eprouvees) : %s" % non_tuees)
    if ecarts:
        print("")
        print("AUTOTEST EN ECHEC :")
        for e in ecarts:
            print("  - %s" % e)
        return 1
    print("")
    print("AUTOTEST OK : la garde sait rougir, et sur les bonnes assertions.")
    print("Rappel MESURE : M6 est VERT ici et ROUGE sur le critere d US-01.2 "
          "(--croise) --")
    print("les deux instruments ne sont pas redondants, DANS LES DEUX SENS.")
    return 0


def _miroir(nom_source: str) -> Path:
    """Un PAQUET JETABLE sous .dart_tool/ : c'est la seule facon de jouer le
    critere d'US-01.2 contre une source derivee SANS JAMAIS ECRIRE DANS lib/.

    Le critere d'US-01.2 se lie en dur a lib/.../echeance_schema_migrations.dart
    et calcule sa racine depuis SON PROPRE chemin ; on lui fabrique donc une
    racine, et il s'y retrouve sans qu'un octet de son fichier change.
    """
    racine = ATELIER / "miroir"
    (racine / "reports" / "US-01.2").mkdir(parents=True, exist_ok=True)
    (racine / "lib" / "features" / "echeances" / "domain").mkdir(
        parents=True, exist_ok=True)
    (racine / "lib" / "features" / "echeances" / "data").mkdir(
        parents=True, exist_ok=True)
    _ecrire(racine / "pubspec.yaml",
            "name: concentration\npublish_to: none\nenvironment:\n"
            "  sdk: ^3.8.0\n")
    origine = CRITERE_US012.read_bytes()
    copie = racine / "reports" / "US-01.2" / CRITERE_US012.name
    copie.write_bytes(origine)
    # CONTROLE NEGATIF : si la copie differait de l original, la mesure ne
    # porterait plus sur le critere d US-01.2.
    if copie.read_bytes() != origine:
        raise SystemExit("la copie du critere d US-01.2 n est PAS identique")
    (racine / "lib" / "features" / "echeances" / "domain"
     / "date_civile.dart").write_bytes(
        (RACINE / "lib" / "features" / "echeances" / "domain"
         / "date_civile.dart").read_bytes())
    _ecrire(racine / "lib" / "features" / "echeances" / "data"
            / "echeance_schema_migrations.dart", _source(nom_source))
    if not (racine / ".dart_tool" / "package_config.json").exists():
        subprocess.run([_dart(), "pub", "get"], cwd=str(racine),
                       capture_output=True, text=True)
    return racine


def croise() -> int:
    """Rejoue les memes sources contre le critere d'US-01.2, INCHANGE.

    ⛔ N ECRIT JAMAIS DANS lib/ : chaque source est deposee dans un PAQUET
    JETABLE sous .dart_tool/ (ignore par git).
    """
    print("== MATRICE CROISEE : garde v3 (US-01.4) x critere aller-retour "
          "(US-01.2) ==")
    if not CRITERE_US012.exists():
        print("ERREUR : %s introuvable." % CRITERE_US012)
        return 1
    print("   Le critere d US-01.2 est joue SANS AUCUNE MODIFICATION (copie "
          "verifiee identique aux")
    print("   octets), contre la MEME source derivee, dans un paquet jetable "
          "sous .dart_tool/.")
    print("   Sa graine ne porte AUCUNE cle `retiree` ; celle de la garde en "
          "porte quatre formes.")
    print("")
    print("%-28s | %-24s | %s"
          % ("source derivee", "critere US-01.2", "garde v3"))
    print("-" * 92)
    ecarts = []
    for nom in sorted(SOURCES):
        racine = _miroir(nom)
        proc = subprocess.run(
            [sys.executable,
             str(racine / "reports" / "US-01.2" / CRITERE_US012.name)],
            cwd=str(racine), capture_output=True, text=True,
            encoding="utf-8", errors="replace",
        )
        lignes_crit = ((proc.stdout or "") + (proc.stderr or "")).splitlines()
        e_crit = _echecs(lignes_crit)
        if not _a_tourne(lignes_crit):
            ecarts.append("%s : le critere d US-01.2 n a pas rendu de VERDICT\n"
                          "     %s" % (nom, "\n     ".join(lignes_crit[:12])))
            continue
        _, lignes = _jouer_source(nom)
        e_garde = _echecs(lignes)
        print("%-28s | %-24s | %s"
              % (nom,
                 ("%d rouge(s) : %s" % (len(e_crit), ",".join(
                     sorted(x.split('_')[0] for x in e_crit)))) if e_crit
                 else "8/8 VERTES",
                 ("%d rouge(s) : %s" % (len(e_garde), ",".join(
                     sorted(x.split('_')[0] for x in e_garde)))) if e_garde
                 else "8/8 VERTES"))
        if nom != "M0_conforme" and not e_crit and not e_garde:
            ecarts.append("%s : AUCUN des deux instruments ne le voit" % nom)
    print("")
    print("Verification : lib/ n a PAS ete touche par ce mode -- "
          "git diff --stat -- lib/  doit etre VIDE.")
    if ecarts:
        print("")
        for e in ecarts:
            print("  - %s" % e)
        return 1
    print("")
    print("LECTURE : les mutants que le critere d US-01.2 laisse passer sont "
          "exactement ceux dont la")
    print("cle `retiree` est absente de sa graine ; et M6 est vu par LUI SEUL. "
          "Les deux instruments")
    print("ne sont pas redondants, DANS LES DEUX SENS.")
    return 0


EFFET_DART = r"""
import 'dart:convert';
import 'package:concentration/features/echeances/data/echeance_schema_migrations.dart'
    as m;

String docParc(int presentes, int retirees) => jsonEncode(<String, Object?>{
      'schemaVersion': 2,
      'echeances': <Map<String, Object?>>[
        for (var i = 0; i < presentes; i++)
          <String, Object?>{
            'id': 'e${i.toString().padLeft(4, '0')}-4f2a-4c1b-9e77-0a1b2c3d4e5f',
            'description': 'Preparation du projet numero $i',
            'dateEcheance': '2027-05-04T23:59',
          },
        for (var i = 0; i < retirees; i++)
          <String, Object?>{
            'id': 'r${i.toString().padLeft(4, '0')}-4f2a-4c1b-9e77-0a1b2c3d4e5f',
            'description': 'Preparation du projet numero $i',
            'dateEcheance': '2026-05-04T23:59',
            'retiree': true,
          },
      ],
    });

void main() {
  // (1) L EFFET EXACT DU `up` sur un document du parc : aucune cle `retiree`,
  // 9 entrees presentes. On mesure le prefixe et le suffixe COMMUNS, donc le
  // diff REEL -- on ne le decrit pas, on le calcule.
  final avant = docParc(9, 0);
  final apres = jsonEncode(m.migrer(
      Map<String, Object?>.from(jsonDecode(avant) as Map),
      cible: m.versionCourante)!);
  var i = 0;
  while (i < avant.length && i < apres.length && avant[i] == apres[i]) {
    i++;
  }
  var j = 0;
  while (j < avant.length - i &&
      j < apres.length - i &&
      avant[avant.length - 1 - j] == apres[apres.length - 1 - j]) {
    j++;
  }
  print('EFFET|octets_avant=${avant.length}|octets_apres=${apres.length}'
      '|prefixe_commun=$i|suffixe_commun=$j'
      '|diff_avant="${avant.substring(i, avant.length - j)}"'
      '|diff_apres="${apres.substring(i, apres.length - j)}"');

  // (2) LE POIDS : l historique n a AUCUN plafond, et le document ENTIER est
  // reecrit a chaque ecriture.
  final base = docParc(9, 0).length;
  for (final n in <int>[0, 100, 1000, 10000]) {
    final d = docParc(9, n);
    print('VOLUME|retirees=$n|octets=${d.length}'
        '|octets_par_retiree=${n == 0 ? 0 : (d.length - base) ~/ n}');
  }
}
"""


def parc() -> int:
    """Deux mesures sur un document du PARC : l'effet exact du `up`, et le poids
    d'un historique sans plafond. La migration est jouee dans le paquet jetable
    (source conforme) -- ⛔ jamais dans lib/."""
    print("== MESURES SUR UN DOCUMENT DU PARC (9 entrees, aucune cle "
          "`retiree`) ==")
    racine = _miroir("M0_conforme")
    cible = racine / "tool" / "effet_parc.dart"
    _ecrire(cible, EFFET_DART)
    proc = subprocess.run(
        [_dart(), "run", str(cible)], cwd=str(racine), capture_output=True,
        text=True, encoding="utf-8", errors="replace",
    )
    lignes = ((proc.stdout or "") + (proc.stderr or "")).splitlines()
    utiles = [l for l in lignes if l.startswith(("EFFET|", "VOLUME|"))]
    for ligne in utiles:
        print(ligne)
    if not utiles:
        print("ECHEC : aucune mesure produite.")
        for ligne in lignes[:12]:
            print("  %s" % ligne)
        return 1
    print("")
    print("LECTURE (1) : la TOTALITE de l effet du `up` sur un document du parc "
          "est le diff imprime")
    print("ci-dessus -- c est ce qui rend AC-5 \"Erreur\" d US-01.4 falsifiable "
          "SUR LES OCTETS, et pas")
    print("seulement sur un decompte de tuiles.")
    print("LECTURE (2) : aucun AC ne borne la taille du document ; aucune purge "
          "n est autorisee (elle")
    print("serait une perte silencieuse) ; et personne n a mesure le temps "
          "d une ecriture atomique de")
    print("cette taille sur un appareil REEL. Dette nommee au section 7 de")
    print("docs/architecture/SCHEMA_STOCKAGE_ECHEANCES.md.")
    return 0


def contre_lib() -> int:
    print("== CRITERE DE SORTIE : garde du couple v2 <=> v3 sur le module REEL ==")
    print("   cible : %s" % MODULE_CIBLE.relative_to(RACINE).as_posix())
    if not MODULE_CIBLE.exists():
        print("")
        print("NON SATISFAIT -- le module n existe pas.")
        return 1
    code, lignes = _executer("harnais_lib.dart", IMPORT_CIBLE)
    for ligne in lignes:
        print(ligne)
    if not _a_tourne(lignes):
        print("")
        print("NON SATISFAIT -- le module ne respecte pas le CONTRAT attendu "
              "(le harnais ne compile pas), OU il n est pas encore en v3 "
              "(tache T3 non livree).")
        print("Ce n est PAS un echec du critere : il est REJOUABLE en l etat, "
              "et il rendra exit 0 le jour ou T3 livrera le couple v2 <=> v3.")
        print("Pouvoir de la garde mesurable des AUJOURD HUI : --selftest")
        return 1
    if code == 0:
        print("")
        print("SATISFAIT -- 8 assertions vertes. La garde du couple v2 <=> v3 "
              "est EXECUTEE sur le module reel.")
        print("RAPPEL : ce script n est PAS un gate CI. La garde doit AUSSI "
              "vivre dans flutter test.")
        return 0
    print("")
    # Le motif se LIT dans la sortie du harnais, il ne se suppose pas.
    version = None
    for ligne in lignes:
        if ligne.startswith("CONTEXTE|"):
            for morceau in ligne.split("|"):
                if morceau.startswith("versionCourante="):
                    version = morceau.split("=", 1)[1]
    if version is not None and version.isdigit() and int(version) < 3:
        print("NON SATISFAIT -- et le motif est PLAT : le module est encore en "
              "v%s (tache T3 non livree)." % version)
        print("Ce n est PAS un echec du critere : il est REJOUABLE en l etat, "
              "et il rendra exit 0 le")
        print("jour ou T3 livrera le couple v2 <=> v3. Pouvoir de la garde "
              "mesurable des AUJOURD HUI : --selftest")
        return 1
    print("NON SATISFAIT -- voir les lignes ASSERTION|...|ECHEC ci-dessus.")
    return 1


def main() -> int:
    parseur = argparse.ArgumentParser(
        description="Critere de sortie de la garde du couple v2 <=> v3 (US-01.4)."
    )
    parseur.add_argument("--selftest", action="store_true",
                         help="mesurer le POUVOIR de la garde (1 conforme + 6 "
                              "mutants comportementaux)")
    parseur.add_argument("--croise", action="store_true",
                         help="rejouer les memes sources contre le critere "
                              "d US-01.2, INCHANGE")
    parseur.add_argument("--parc", action="store_true",
                         help="mesurer, sur un document du PARC, l effet exact "
                              "du up et le poids d un historique sans plafond")
    args = parseur.parse_args()
    if args.selftest:
        return selftest()
    if args.croise:
        return croise()
    if args.parc:
        return parc()
    return contre_lib()


if __name__ == "__main__":
    sys.exit(main())
