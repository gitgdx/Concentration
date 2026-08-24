#!/usr/bin/env python3
"""Instrument de MESURE du cout d une ecriture atomique a N retirees (D-8, US-01.4).

CE QU IL EST, ET CE QU IL N EST PAS -- A LIRE AVANT TOUT
--------------------------------------------------------
Arbitrage humain du 2026-08-24 : "MESURER D ABORD, BORNER ENSUITE".
Ce fichier est donc un INSTRUMENT DE MESURE. Il ne pose AUCUN plafond, il
n enonce AUCUN critere d acceptation, et il ne dit PAS ce que le cout DEVRAIT
etre. Il dit ce qu il EST, de facon rejouable, et il refuse de conclure sur ce
qu il n a pas mesure.

  - AUCUN plafond de taille de document n est defini ici.
  - AUCUN plafond de duree d ecriture n est defini ici.
  - AUCUNE purge n est proposee : elle serait une perte silencieuse
    (clarify no 10 d US-01.2), et ADR-012 section 4 interdit un `down` qui
    detruit l information de retrait.

CE QUE D-8 DIT, ET POURQUOI LA QUESTION EST NEUVE
-------------------------------------------------
D-8 (docs/architecture/SCHEMA_STOCKAGE_ECHEANCES.md section 10) : "l historique
n a aucun plafond et le document ENTIER est reecrit a CHAQUE ecriture". Le fait
neuf apporte par US-01.4 : AVANT elle, une echue restait VISIBLE, donc genante,
donc supprimee par le pratiquant. Le retrait la fait DISPARAITRE TOUT EN LA
CONSERVANT ==> c est le PREMIER mecanisme du produit qui accumule de la donnee
que personne ne voit s accumuler. Et personne n a jamais mesure une ecriture
atomique de cette taille sur un appareil.

LES QUATRE MODES, ET DANS QUEL ORDRE LES LIRE
---------------------------------------------
  (defaut)     LE CRITERE. Il lit TROIS faits dans le corpus et dit PLATEMENT
               ce qu il ne peut PAS encore mesurer, puis rend exit 1. Il rendra
               exit 0 le jour ou (a) `lib/` connait la cle de retrait -- donc ou
               l axe des TAILLES est celui du PRODUIT et non le modele de ce
               critere -- et (b) une mesure APPAREIL est deposee et couvre la
               serie declaree. Aucun de ces deux faits n est ecrit a la main :
               ils sont LUS.
  --hote       LA MESURE HORS APPAREIL (chemin CI / poste). Elle traverse le
               CHEMIN D ECRITURE DE PRODUCTION -- `DocumentStoreFichier.ecrire`,
               donc `.tmp` + `flush: true` + `rename` -- sur un VRAI disque, et
               rend, pour chaque N de la serie : les OCTETS du document et les
               DUREES (min / mediane / max) de l ecriture. Rien n est ecrit a la
               main : le cout par retiree et le debit se LISENT de la mesure.
  --selftest   LE POUVOIR de la mesure, par MUTATION. Il rejoue les
               verifications internes contre des harnais derives d UN SEUL patch
               comportemental chacun (une source conforme + des mutants), et
               compare des ENSEMBLES d echecs, jamais des cardinaux.
               (Les DECOMPTES ne sont PAS ecrits ici : le mode les IMPRIME. Un
               nombre derive ecrit a la main a cote d une commande est la classe
               de defaut no 1 de ce depot -- il perime au mutant suivant, et
               celui-ci est arrive.) Controle negatif : un mutant dont la source
               est identique a la conforme est REFUSE.
  --appareil   LE CHEMIN APPAREIL. Il genere la cible Flutter (qui partage le
               MEME corps de mesure que le harnais de `--hote` -- une regle n
               existe qu en UN exemplaire), LIT la liste des appareils, imprime
               la commande REJOUABLE, et refuse PLATEMENT s il n y a aucun
               appareil. Il fait analyser la cible pour que son verdict ne soit
               pas de la prose.

CE QU IL N ATTESTE PAS
----------------------
  - Il ne remplace AUCUN test de test/, et il n est PAS un gate CI (il exige le
    SDK Flutter).
  - `--hote` mesure un DISQUE DE POSTE DE TRAVAIL. Une ecriture sur la memoire
    d un appareil Android de 2016 n a AUCUNE raison d avoir le meme cout. C est
    exactement pourquoi le mode par defaut refuse de conclure sans la mesure
    appareil.
  - Tant que `lib/` ne connait pas la cle de retrait (taches T2/T3 non livrees),
    le MARQUAGE des entrees retirees est un MODELE de ce critere, aligne sur
    ADR-012 section 4 (cle ecrite seulement si `true`, ajoutee en fin d entree
    -- regle F-3). Le mode `--hote` l imprime a chaque execution, et le DIFF
    d une entree est CALCULE, jamais decrit.
  - La DUREE, elle, ne depend pas de ce que les octets SIGNIFIENT : elle est
    reelle des aujourd hui.

Usage :
    python reports/US-01.4/cout_ecriture_atomique_criterion.py
    python reports/US-01.4/cout_ecriture_atomique_criterion.py --hote
    python reports/US-01.4/cout_ecriture_atomique_criterion.py --selftest
    python reports/US-01.4/cout_ecriture_atomique_criterion.py --appareil
"""

from __future__ import annotations

import argparse
import io
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
ATELIER = RACINE / ".dart_tool" / "us014_cout_ecriture"
DEPOT_APPAREIL = RACINE / "reports" / "US-01.4" / "cout_appareil"

# Les fichiers de `lib/` ou la cle de retrait DOIT apparaitre quand T2/T3 seront
# livrees. Ils sont DESIGNES PAR LEUR CHEMIN, jamais par une ligne.
SOURCES_LIB = (
    RACINE / "lib" / "features" / "echeances" / "domain" / "echeance.dart",
    RACINE / "lib" / "features" / "echeances" / "data"
    / "echeance_document_codec.dart",
    RACINE / "lib" / "features" / "echeances" / "data"
    / "echeance_schema_migrations.dart",
)

# --------------------------------------------------------------------------
# LES ENTREES DU CRITERE -- ce sont des PARAMETRES, ⛔ jamais des resultats.
# Chacune vit en UN SEUL exemplaire et est imprimee sous le prefixe `ENTREE|`
# pour qu on ne puisse pas la confondre avec une mesure.
#
# D ou vient `10000` : de D-8 lui-meme, qui pose la question a cet ordre de
# grandeur. Ce n est PAS un plafond -- c est le point le plus haut que la mesure
# doit ATTEINDRE pour que sa reponse vaille quelque chose.
# --------------------------------------------------------------------------
SERIE = (0, 100, 1000, 10000)
PRESENTES = 9      # la limite de la grille (maxPresentesSurGrille), le cas reel
REPETITIONS = 5    # ⛔ une duree mesuree UNE fois est du bruit, pas une mesure
# LA TOLERANCE de `V5`, ENTREE declaree -- ⛔ pas un resultat.
#
# ⚠️ ELLE PORTE L HISTOIRE DE DEUX FORMULATIONS FAUSSES DE `V5`, et on la garde
# parce que ce sont des MESURES qui les ont refutees, pas une relecture :
#   v1 : « mediane a n=10000 > mediane a n=0 ». ⛔ REFUTEE : elle a rendu DEUX
#        verdicts OPPOSES sur LA MEME source (mutant `T3`, ecriture sautee) --
#        deux medianes dominees par le bruit se comparent AU HASARD.
#   v2 : « mediane a n=10000 > MARGE x plancher de bruit ». ⛔ REFUTEE : quand le
#        chronometre est casse (mutant `T5`), le plancher vaut 0, donc le seuil
#        vaut 0, et le mutant PASSE. Un seuil multiplicatif degenere a zero.
#   v3 : celle en vigueur -- « le chronometre sous test REND COMPTE du temps
#        qu une REFERENCE INDEPENDANTE a mesure ». ⛔ Un instrument ne se valide
#        pas par lui-meme : le temoin est un `Stopwatch` pose dans la partie
#        FIXE du harnais, ⛔ hors de toute fente, donc hors d atteinte des
#        mutants.
MARGE_BRUIT = 10

# La cle de retrait, en UN SEUL exemplaire dans ce fichier. ⚠️ Le jour ou `lib/`
# la publie, c est de LA qu il faudra la lire -- la dependance est NOMMEE, pas
# oubliee.
CLE_RETRAIT = "retiree"

VERIFICATIONS = (
    "V1_octets_croissent_strictement",
    "V2_cout_par_retiree_constant",
    "V3_octets_presents_sur_le_disque",
    "V4_ecriture_atomique_traversee",
    "V5_chronometre_rend_compte_du_temps",
    "V6_nombre_de_retirees_conforme",
)

# --------------------------------------------------------------------------
# LE CORPS DE MESURE -- en UN SEUL EXEMPLAIRE, partage par le harnais `flutter
# test` (--hote) et par la cible appareil (--appareil).
#
# ⛔ Deux copies d un corps de mesure derivent, et la mesure appareil finirait
# par ne plus mesurer la meme chose que la mesure hote. C est la classe de
# defaut no 1 de ce depot.
#
# Les QUATRE FENTES sont les seuls points que `--selftest` patche. Une fente
# absente fait ECHOUER la generation : ⛔ aucune substitution textuelle aveugle.
# --------------------------------------------------------------------------
CORPS_MESURE = r"""
// --- ENTREES du critere (parametres, ⛔ jamais des resultats) ---
const List<int> serie = __SERIE__;
const int presentes = __PRESENTES__;
const int repetitions = __REPETITIONS__;
const int margeBruit = __MARGE_BRUIT__;
const String cleRetrait = '__CLE_RETRAIT__';

// --- FENTE 1 : combien de retirees le GENERATEUR produit reellement pour n ---
int retireesPour(int n) {
__FENTE_RETIREES__
}

// --- FENTE 2 : la DESCRIPTION d une entree ---
String descriptionPour(int i) {
__FENTE_DESCRIPTION__
}

// --- FENTE 3 : l ECRITURE mesuree ---
Future<void> acteEcriture(DocumentStore magasin, String contenu) async {
__FENTE_ECRITURE__
}

// --- FENTE 4 : le CHRONOMETRE ---
Future<int> chronometrer(Future<void> Function() acte) async {
__FENTE_CHRONO__
}

/// Un identifiant de LARGEUR FIXE (36 caracteres, forme UUID). ⛔ La largeur
/// fixe n est pas une coquetterie : un compteur qui gagne un chiffre a 10 000
/// ferait varier la taille des entrees, et `V2` le verrait -- c est d ailleurs
/// ce que le mutant `T2` mesure.
String identifiantPour(int i, String famille) =>
    '${famille}${i.toString().padLeft(7, '0')}-4f2a-4c1b-9e77-0a1b2c3d4e5f';

/// Le document, produit par le CODEC DE PRODUCTION, puis marque.
///
/// ⛔ Le marquage est un MODELE tant que `lib/` ne connait pas la cle : il est
/// aligne sur ADR-012 section 4 (cle ecrite seulement si `true`) et sur la
/// regle F-3 (la cle prend sa place en FIN d entree, comme le fait une
/// insertion dans une `Map` litterale Dart). Il est IMPRIME, pas decrit.
String document(int n) {
  const codec = EcheanceDocumentCodec();
  final echeances = <Echeance>[];
  for (var i = 0; i < presentes; i++) {
    echeances.add(Echeance(
      id: identifiantPour(i, 'p'),
      description: descriptionPour(i),
      dateEcheance: DateTime(2027, 5, 4, 23, 59),
    ));
  }
  final k = retireesPour(n);
  for (var i = 0; i < k; i++) {
    echeances.add(Echeance(
      id: identifiantPour(i, 'r'),
      description: descriptionPour(i),
      dateEcheance: DateTime(2026, 5, 4, 23, 59),
    ));
  }
  final texte = codec.encoder(codec.documentNeuf(versionCourante), echeances);
  if (k == 0) return texte;
  final racine = Map<String, Object?>.from(jsonDecode(texte) as Map);
  final lignes = (racine['echeances']! as List).toList();
  for (var i = lignes.length - k; i < lignes.length; i++) {
    final entree = Map<String, Object?>.from(lignes[i]! as Map);
    entree[cleRetrait] = true;
    lignes[i] = entree;
  }
  racine['echeances'] = lignes;
  return jsonEncode(racine);
}

/// Le nombre d entrees PORTANT la cle de retrait -- lu du document, ⛔ jamais
/// compte par une recherche de texte (qui compterait aussi une description).
int retireesDans(String texte) {
  final racine = jsonDecode(texte) as Map;
  var vues = 0;
  for (final ligne in racine['echeances']! as List) {
    if (ligne is Map && ligne.containsKey(cleRetrait)) vues++;
  }
  return vues;
}

int mediane(List<int> valeurs) {
  final t = valeurs.toList()..sort();
  return t.length.isOdd
      ? t[t.length ~/ 2]
      : (t[t.length ~/ 2 - 1] + t[t.length ~/ 2]) ~/ 2;
}

final List<String> journal = <String>[];
final List<String> enEchec = <String>[];

void verification(String nom, bool Function() corps, String detail) {
  bool ok;
  try {
    ok = corps();
  } catch (e) {
    ok = false;
    detail = '$detail (exception ${e.runtimeType}: $e)';
  }
  if (ok) {
    journal.add('VERIFICATION|$nom|OK|');
  } else {
    enEchec.add(nom);
    journal.add('VERIFICATION|$nom|ECHEC|$detail');
  }
}

/// LA MESURE. `repertoire` sert a observer le residu de l ecriture atomique --
/// c est la seule chose qu on ne peut pas lire depuis le port.
Directory? repertoireMesure;

Future<int> mesurer(
    DocumentStore magasin, Directory repertoire, String plateforme) async {
  repertoireMesure = repertoire;
  print('ENTREE|serie=$serie|presentes=$presentes|repetitions=$repetitions'
      '|marge_bruit=$margeBruit|cle_retrait=$cleRetrait');
  print('CONTEXTE|plateforme=$plateforme|dart=${Platform.version.split(' ').first}'
      '|schemaVersion=$versionCourante|repertoire=${repertoire.path}');

  // Le DIFF exact du marquage sur UNE entree : prefixe et suffixe COMMUNS
  // CALCULES ==> on ne decrit pas le marquage, on le montre.
  final sansMarque = document(0);
  final avecMarque = document(1);
  var tete = 0;
  while (tete < sansMarque.length &&
      tete < avecMarque.length &&
      sansMarque[tete] == avecMarque[tete]) {
    tete++;
  }
  var queue = 0;
  while (queue < sansMarque.length - tete &&
      queue < avecMarque.length - tete &&
      sansMarque[sansMarque.length - 1 - queue] ==
          avecMarque[avecMarque.length - 1 - queue]) {
    queue++;
  }
  print('MARQUAGE|ajoute="${avecMarque.substring(tete, avecMarque.length - queue)}"'
      '|retire="${sansMarque.substring(tete, sansMarque.length - queue)}"');

  // LE PLANCHER DE BRUIT : le MEME chronometre, sur un acte qui ne fait RIEN.
  // C est lui qui rend `V5` DETERMINISTE -- sans lui, elle comparait deux
  // medianes de bruit et tirait au sort (mesure : deux verdicts opposes sur la
  // meme source).
  final bruits = <int>[];
  for (var k = 0; k < repetitions; k++) {
    bruits.add(await chronometrer(() async {}));
  }
  final bruit = mediane(bruits);
  print('BRUIT|us_median=$bruit|echantillons=${bruits..sort()}');

  final octets = <int, int>{};
  final medianes = <int, int>{};
  final retirees = <int, int>{};
  final residus = <int, List<String>>{};
  final surLeDisque = <int, bool>{};
  // La REFERENCE INDEPENDANTE : un chronometre qui n est PAS la fente 4, pose
  // autour de la boucle entiere. C est lui qui permet de demander au
  // chronometre sous test de RENDRE COMPTE du temps reellement ecoule -- une
  // validation d instrument par un instrument distinct, et non par lui-meme.
  final reference = <int, int>{};
  final somme = <int, int>{};

  for (final n in serie) {
    final contenu = document(n);
    final attendus = utf8.encode(contenu);
    octets[n] = attendus.length;
    retirees[n] = retireesDans(contenu);

    // ⛔ La cible porte d ABORD un contenu DIFFERENT : sans cela, "les octets
    // sont sur le disque" pourrait etre vrai parce qu ils y etaient deja.
    await acteEcriture(magasin, '{"schemaVersion":$versionCourante,'
        '"echeances":[],"_temoin_$n":true}');

    final durees = <int>[];
    final temoin = Stopwatch()..start();
    for (var k = 0; k < repetitions; k++) {
      durees.add(await chronometrer(() => acteEcriture(magasin, contenu)));
    }
    temoin.stop();
    reference[n] = temoin.elapsedMicroseconds;
    somme[n] = durees.fold<int>(0, (a, b) => a + b);
    durees.sort();
    medianes[n] = mediane(durees);

    final cible = File('${repertoire.path}${Platform.pathSeparator}$nomDocument');
    final lus = cible.existsSync() ? cible.readAsBytesSync() : const <int>[];
    surLeDisque[n] = lus.length == attendus.length &&
        utf8.decode(lus, allowMalformed: true) == contenu;
    residus[n] = repertoire
        .listSync()
        .map((e) => e.uri.pathSegments.last)
        .where((nom) => nom != nomDocument)
        .toList()
      ..sort();

    print('MESURE|n=$n|octets=${octets[n]}|entrees=${presentes + retirees[n]!}'
        '|retirees=${retirees[n]}'
        '|us_min=${durees.first}|us_median=${medianes[n]}|us_max=${durees.last}'
        '|ko_par_s=${medianes[n] == 0 ? 'infini' : (octets[n]! * 1000 ~/ medianes[n]! ~/ 1024)}'
        '|octets_sur_le_disque=${surLeDisque[n]}|residus=${residus[n]}'
        '|us_chronometres=${somme[n]}|us_reference=${reference[n]}');
  }

  // Le cout par retiree se LIT de la mesure -- ⛔ il n est ecrit nulle part.
  final base = octets[serie.first]!;
  for (final n in serie.where((n) => n > 0)) {
    print('DERIVE|n=$n|octets_par_retiree=${(octets[n]! - base) / n}'
        '|croissance_octets=${octets[n]! - base}'
        '|croissance_duree_us=${medianes[n]! - medianes[serie.first]!}'
        '|facteur_taille=${(octets[n]! / base).toStringAsFixed(1)}'
        '|facteur_duree=${(medianes[n]! / medianes[serie.first]!).toStringAsFixed(2)}');
  }

  verification('V1_octets_croissent_strictement', () {
    for (var i = 1; i < serie.length; i++) {
      if (octets[serie[i]]! <= octets[serie[i - 1]]!) return false;
    }
    return true;
  }, 'octets = ${serie.map((n) => '$n:${octets[n]}').toList()}');

  verification('V2_cout_par_retiree_constant', () {
    final couts = serie
        .where((n) => n > 0)
        .map((n) => (octets[n]! - base) % n == 0 ? (octets[n]! - base) ~/ n : -1)
        .toSet();
    return couts.length == 1 && !couts.contains(-1);
  }, 'couts par retiree = ${serie.where((n) => n > 0).map((n) => '$n:${(octets[n]! - base) / n}').toList()}');

  verification('V3_octets_presents_sur_le_disque',
      () => surLeDisque.values.every((v) => v),
      'octets_sur_le_disque = $surLeDisque');

  verification('V4_ecriture_atomique_traversee',
      () => residus.values.every((r) => r.isEmpty),
      'residus apres ecriture = $residus');

  // ⛔ ASSERTION DE GRANDEUR, et la seule qui puisse tuer un chronometre qui ne
  // chronometre rien : une egalite serait tautologique (les deux cotes bougeraient
  // ensemble). Elle porte sur la VALIDITE DE L INSTRUMENT (le chronometre mesure
  // un acte REEL), ⛔ PAS sur la physique : la CROISSANCE de la duree avec la
  // taille est IMPRIMEE (lignes DERIVE|), ⛔ jamais assertee -- la mesure montre
  // que le cout est domine par un terme FIXE (flush + rename), donc une plateforme
  // ou la croissance rentrerait dans le bruit rendrait une assertion de croissance
  // ROUGE A TORT : sur la PLATEFORME, et non sur l instrument.
  verification('V5_chronometre_rend_compte_du_temps',
      () => somme[serie.last]! * margeBruit >= reference[serie.last]!,
      'a n=${serie.last} : le chronometre sous test rend ${somme[serie.last]}us '
      'la ou la REFERENCE INDEPENDANTE mesure ${reference[serie.last]}us '
      '(tolerance : un facteur $margeBruit). Plancher de bruit du meme '
      'chronometre : ${bruit}us.');

  verification('V6_nombre_de_retirees_conforme',
      () => serie.every((n) => retirees[n] == n),
      'retirees mesurees = $retirees, serie declaree = $serie');

  for (final ligne in journal) {
    print(ligne);
  }
  if (enEchec.isEmpty) {
    print('VERDICT|OK|');
    return 0;
  }
  print('VERDICT|ECHEC|${enEchec.join(',')}');
  return 1;
}
"""

IMPORTS_COMMUNS = r"""
import 'dart:convert';
import 'dart:io';

import 'package:concentration/features/echeances/data/document_store.dart';
import 'package:concentration/features/echeances/data/document_store_io.dart';
import 'package:concentration/features/echeances/data/echeance_document_codec.dart';
import 'package:concentration/features/echeances/data/echeance_schema_migrations.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
"""

# Enveloppe HOTE : `flutter test`. ⛔ Pas `testWidgets` : le corps d un
# `testWidgets` tourne dans une zone `FakeAsync`, ou une entree-sortie REELLE n
# aboutit pas sans `runAsync` (fait mesure par US-01.2, cf.
# test/support/magasin_temporaire.dart). Un `test` nu a la VRAIE boucle
# d evenements, donc le chronometre mesure une vraie ecriture.
ENVELOPPE_HOTE = (
    IMPORTS_COMMUNS
    + "import 'package:flutter_test/flutter_test.dart';\n"
    + CORPS_MESURE
    + r"""
void main() {
  test('cout d une ecriture atomique a N retirees', () async {
    final repertoire = Directory.systemTemp.createTempSync('us014_cout_');
    final magasin = DocumentStoreFichier(repertoire);
    final code = await mesurer(magasin, repertoire, 'hote');
    try {
      repertoire.deleteSync(recursive: true);
    } on FileSystemException {
      // Un echec de MENAGE ne doit jamais faire rougir une mesure.
    }
    expect(code, 0, reason: 'voir les lignes VERIFICATION|...|ECHEC ci-dessus');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
"""
)

# Enveloppe APPAREIL : une cible `flutter run -t`. Le MEME corps de mesure.
# ⛔ Elle n appelle pas `magasinDeLaPlateforme()` : elle construit le MEME objet
# de production (`DocumentStoreFichier(getApplicationDocumentsDirectory())`, qui
# est LITTERALEMENT le corps de `creerMagasin`), parce que `V4` a besoin du
# REPERTOIRE, que le port ne rend pas.
ENVELOPPE_APPAREIL = (
    IMPORTS_COMMUNS
    + "import 'package:flutter/widgets.dart';\n"
    + "import 'package:path_provider/path_provider.dart';\n"
    + CORPS_MESURE
    + r"""
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repertoire = await getApplicationDocumentsDirectory();
  final magasin = DocumentStoreFichier(repertoire);
  final code = await mesurer(magasin, repertoire, 'appareil');
  print('FIN|code=$code');
  exit(code);
}
"""
)

# --------------------------------------------------------------------------
# LES FENTES : une source conforme + des mutants, UN patch comportemental chacun.
# (⛔ Le DECOMPTE n'est pas ecrit ici : `--selftest` l'imprime. Il a deja perime
# une fois, quand `T7` a ete ajoute pour tuer `V4`.)
# ⛔ Aucun mutant ne touche un MOT de la regle mesuree : ils changent tous un
# COMPORTEMENT (le generateur, la description, l ecriture, le chronometre).
# --------------------------------------------------------------------------
CONFORME = {
    "RETIREES": "  return n;",
    "DESCRIPTION":
        "  return 'Preparation du projet ${i.toString().padLeft(7, '0')}';",
    "ECRITURE": "  await magasin.ecrire(contenu);",
    "CHRONO": (
        "  final chrono = Stopwatch()..start();\n"
        "  await acte();\n"
        "  chrono.stop();\n"
        "  return chrono.elapsedMicroseconds;"
    ),
}

SOURCES = {
    "T0_conforme": ({}, set()),
    # Le generateur IGNORE n : la serie est plate. C est le mutant qui dit si la
    # mesure sait qu elle mesure quelque chose de VARIABLE.
    "T1_serie_plate": (
        {"RETIREES": "  return 0;"},
        {"V1_octets_croissent_strictement",
         "V6_nombre_de_retirees_conforme"},
    ),
    # Les entrees n ont pas toutes la MEME taille ==> "octets par retiree" cesse
    # d avoir un sens, et c est `V2` seule qui doit le voir.
    "T2_entrees_de_taille_variable": (
        {"DESCRIPTION": "  return 'Preparation du projet ' * (1 + i % 3);"},
        {"V2_cout_par_retiree_constant"},
    ),
    # L ecriture n a PAS LIEU : on chronometrerait le vide.
    "T3_ecriture_sautee": (
        {"ECRITURE": "  // l ecriture est sautee"},
        {"V3_octets_presents_sur_le_disque"},
    ),
    # UNE PURGE, c est-a-dire exactement ce qu ADR-012 interdit. L instrument
    # doit la VOIR, sinon il ne pourrait pas distinguer "l historique croit" de
    # "l historique est rogne en silence".
    "T4_purge_silencieuse": (
        {"RETIREES": "  return n > 1000 ? 1000 : n;"},
        {"V1_octets_croissent_strictement", "V2_cout_par_retiree_constant",
         "V6_nombre_de_retirees_conforme"},
    ),
    # Le chronometre demarre APRES l ecriture : il rend un temps reel, non nul,
    # et totalement etranger a ce qu on mesure. ⛔ Le defaut le plus silencieux
    # du lot : aucune duree n est absurde a la lecture.
    "T5_chrono_hors_sujet": (
        {"CHRONO": (
            "  await acte();\n"
            "  final chrono = Stopwatch()..start();\n"
            "  chrono.stop();\n"
            "  return chrono.elapsedMicroseconds;"
        )},
        {"V5_chronometre_rend_compte_du_temps"},
    ),
    # L ecriture NON ATOMIQUE : ecriture en place, sans `.tmp` ni `rename`.
    # C est le mutant qui dit si `V3` + `V4` savent distinguer "des octets sont
    # arrives" de "le chemin de production a ete traverse".
    "T6_ecriture_ailleurs": (
        {"ECRITURE": (
            "  final cible = File('${Directory.systemTemp.path}'\n"
            "      '${Platform.pathSeparator}us014_hors_cible.json');\n"
            "  await cible.writeAsString(contenu, flush: true);"
        )},
        {"V3_octets_presents_sur_le_disque"},
    ),
    # LE PROVISOIRE EST ABANDONNE : `.tmp` ecrit, `rename` JAMAIS fait. C est le
    # seul mutant qui tue `V4` -- sans lui elle serait DECORATIVE, et l autotest
    # le disait LUI-MEME (ligne "Verifications qu AUCUN mutant ne tue"). Il
    # modelise en outre `NB-E` (audit securite du 2026-08-11) : une remanence des
    # donnees du pratiquant a un nom PREVISIBLE.
    "T7_provisoire_abandonne": (
        {"ECRITURE": (
            "  final provisoire = File('${repertoireMesure!.path}'\n"
            "      '${Platform.pathSeparator}$nomDocument.tmp');\n"
            "  await provisoire.writeAsString(contenu, flush: true);"
        )},
        {"V3_octets_presents_sur_le_disque",
         "V4_ecriture_atomique_traversee"},
    ),
}


def _flutter() -> str:
    chemin = shutil.which("flutter")
    if not chemin:
        raise SystemExit(
            "ERREUR : le SDK Flutter est introuvable dans le PATH. Cet "
            "instrument l exige (mesure : Flutter 3.44.7 sur ce poste)."
        )
    return chemin


def _ecrire(chemin: Path, contenu: str) -> None:
    chemin.parent.mkdir(parents=True, exist_ok=True)
    with io.open(chemin, "w", encoding="utf-8", newline="\n") as f:
        f.write(contenu)


def _source(enveloppe: str, fentes: dict) -> str:
    """Substitue les 4 fentes + les 4 entrees. Une fente absente fait ECHOUER la
    generation : ⛔ jamais de substitution textuelle aveugle."""
    src = enveloppe
    remplacements = {
        "__SERIE__": "<int>[%s]" % ", ".join(str(n) for n in SERIE),
        "__PRESENTES__": str(PRESENTES),
        "__REPETITIONS__": str(REPETITIONS),
        "__MARGE_BRUIT__": str(MARGE_BRUIT),
        "__CLE_RETRAIT__": CLE_RETRAIT,
    }
    for cle, corps in CONFORME.items():
        remplacements["__FENTE_%s__" % cle] = fentes.get(cle, corps)
    for marque, valeur in remplacements.items():
        if marque not in src:
            raise SystemExit("fente `%s` absente de l enveloppe" % marque)
        src = src.replace(marque, valeur)
    reste = re.findall(r"__[A-Z_]+__", src)
    if reste:
        raise SystemExit("marques non substituees : %s" % sorted(set(reste)))
    return src


def _executer_hote(nom: str, fentes: dict) -> tuple:
    cible = ATELIER / ("harnais_%s_test.dart" % nom.lower())
    _ecrire(cible, _source(ENVELOPPE_HOTE, fentes))
    proc = subprocess.run(
        [_flutter(), "test", str(cible.relative_to(RACINE).as_posix())],
        cwd=str(RACINE), capture_output=True, text=True,
        encoding="utf-8", errors="replace",
    )
    sortie = (proc.stdout or "") + (proc.stderr or "")
    return proc.returncode, sortie.splitlines()


def _echecs(lignes: list) -> set:
    echecs = set()
    for ligne in lignes:
        if ligne.startswith("VERIFICATION|"):
            morceaux = ligne.split("|")
            if len(morceaux) >= 3 and morceaux[2] == "ECHEC":
                echecs.add(morceaux[1])
    return echecs


def _a_tourne(lignes: list) -> bool:
    return any(l.startswith("VERDICT|") for l in lignes)


def _utiles(lignes: list) -> list:
    prefixes = ("ENTREE|", "CONTEXTE|", "MARQUAGE|", "BRUIT|", "MESURE|",
                "DERIVE|", "VERIFICATION|", "VERDICT|")
    return [l for l in lignes if l.startswith(prefixes)]


# --------------------------------------------------------------------------
# MODE --hote
# --------------------------------------------------------------------------
def hote() -> int:
    print("== COUT D UNE ECRITURE ATOMIQUE A N RETIREES -- MESURE HORS APPAREIL ==")
    print("   chemin traverse : DocumentStoreFichier.ecrire (.tmp + flush + "
          "rename), VRAI disque")
    print("   ATTENTION : ce mode mesure un DISQUE DE POSTE DE TRAVAIL. Il ne "
          "dit RIEN de l appareil.")
    print("")
    code, lignes = _executer_hote("T0_conforme", {})
    utiles = _utiles(lignes)
    for ligne in utiles:
        print(ligne)
    if not _a_tourne(lignes):
        print("")
        print("ECHEC : le harnais n a pas rendu de VERDICT. Sortie brute :")
        for ligne in lignes[:20]:
            print("  %s" % ligne)
        return 1
    print("")
    if code != 0:
        print("MESURE PRODUITE MAIS NON FIABLE : au moins une verification "
              "interne a echoue (voir VERIFICATION|...|ECHEC).")
        return 1
    print("LECTURE : les nombres ci-dessus se LISENT, et AUCUN n est ecrit dans "
          "ce fichier. Le cout")
    print("par retiree est DERIVE de la mesure ; le debit aussi. AUCUN "
          "plafond n est pose ici, et")
    print("aucune purge n est proposee -- elle serait une perte silencieuse "
          "(ADR-012 section 4).")
    print("CE QUE CE MODE NE DIT PAS : ce que la meme ecriture coute sur "
          "l appareil. --> mode --appareil")
    return 0


# --------------------------------------------------------------------------
# MODE --selftest
# --------------------------------------------------------------------------
def selftest() -> int:
    print("== AUTOTEST DE MUTATION de l instrument de mesure (D-8, US-01.4) ==")
    print("   %d verifications x %d harnais derives (1 conforme + %d mutants)"
          % (len(VERIFICATIONS), len(SOURCES), len(SOURCES) - 1))
    print("   Verdicts compares en ENSEMBLES, JAMAIS en cardinaux.")
    print("   Chaque mutant patche UN COMPORTEMENT, JAMAIS un mot de la "
          "regle mesuree.")
    print("")
    conforme = _source(ENVELOPPE_HOTE, {})
    ecarts = []
    couverture = set()
    for nom in sorted(SOURCES):
        fentes, attendu = SOURCES[nom]
        # ⛔ CONTROLE NEGATIF : un mutant qui ne mute rien ne mesure rien.
        if nom != "T0_conforme" and _source(ENVELOPPE_HOTE, fentes) == conforme:
            ecarts.append("%s : la source du mutant est IDENTIQUE a la "
                          "conforme" % nom)
            continue
        code, lignes = _executer_hote(nom, fentes)
        if not _a_tourne(lignes):
            ecarts.append("%s : le harnais n a pas rendu de VERDICT (code %d)\n"
                          "     %s" % (nom, code, "\n     ".join(lignes[:14])))
            continue
        obtenu = _echecs(lignes)
        couverture |= obtenu
        etat = "OK " if obtenu == attendu else "ECART"
        print("[%s] %-30s attendu=%s" % (etat, nom, sorted(attendu) or "aucun"))
        print("        %-30s obtenu =%s" % ("", sorted(obtenu) or "aucun"))
        if obtenu != attendu:
            ecarts.append("%s : manquants=%s inattendus=%s"
                          % (nom, sorted(attendu - obtenu),
                             sorted(obtenu - attendu)))
            for ligne in lignes:
                if "|ECHEC|" in ligne:
                    print("        %s" % ligne)
    print("")
    non_tuees = sorted(set(VERIFICATIONS) - couverture)
    print("Verifications tuees par au moins un mutant : %s" % sorted(couverture))
    if non_tuees:
        print("Verifications qu AUCUN mutant ne tue (a ne PAS lire comme "
              "eprouvees) : %s" % non_tuees)
    if ecarts:
        print("")
        print("AUTOTEST EN ECHEC :")
        for e in ecarts:
            print("  - %s" % e)
        return 1
    print("")
    print("AUTOTEST OK : la mesure sait rougir, et sur les bonnes "
          "verifications.")
    return 0


# --------------------------------------------------------------------------
# MODE --appareil
# --------------------------------------------------------------------------
def _appareils() -> list:
    """La liste des appareils, LUE de `flutter devices --machine`."""
    proc = subprocess.run(
        [_flutter(), "devices", "--machine"], cwd=str(RACINE),
        capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    brut = proc.stdout or ""
    debut = brut.find("[")
    if debut < 0:
        return []
    try:
        return json.loads(brut[debut:])
    except json.JSONDecodeError:
        return []


def appareil() -> int:
    print("== CHEMIN APPAREIL : la mesure que D-8 reclame vraiment ==")
    cible = ATELIER / "cible_appareil.dart"
    _ecrire(cible, _source(ENVELOPPE_APPAREIL, {}))
    relatif = cible.relative_to(RACINE).as_posix()
    print("   cible generee : %s" % relatif)
    print("   Elle partage le MEME corps de mesure que le harnais de --hote "
          "(une regle n existe")
    print("      qu en UN exemplaire) ; seules l enveloppe et la source du "
          "repertoire changent.")
    print("")

    # ⛔ Un verdict de ce mode ne doit pas etre de la PROSE : la cible est
    # ANALYSEE, et le resultat est lu.
    proc = subprocess.run(
        [_flutter(), "analyze", "--no-pub", relatif], cwd=str(RACINE),
        capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    sortie = ((proc.stdout or "") + (proc.stderr or "")).strip().splitlines()
    # ⛔ LE CODE DE SORTIE NE SUFFIT PAS : `flutter analyze` rend 1 pour un simple
    # `info` (ici `avoid_print`, inevitable dans une cible dont le LIVRABLE est
    # ce qu elle imprime). Ce qui dit si la cible COMPILE, ce sont les `error`.
    # Meme lecon que le gate 3 de `/certify` : on lit un VERDICT, jamais une
    # presence.
    niveaux = {n: sum(1 for l in sortie if (" %s - " % n) in l)
               for n in ("error", "warning", "info")}
    print("ANALYSE|code=%d|error=%d|warning=%d|info=%d|compile=%s"
          % (proc.returncode, niveaux["error"], niveaux["warning"],
             niveaux["info"], niveaux["error"] == 0))
    for ligne in sortie:
        if " error - " in ligne or " warning - " in ligne:
            print("  %s" % ligne)
    print("  (les `info` restants sont des `avoid_print` : la cible n a pas "
          "d autre canal de sortie.)")
    print("  CONTROLE NEGATIF a rejouer : `flutter analyze` SANS argument doit "
          "rester vert --")
    print("  la cible vit sous .dart_tool/, que l analyseur ignore tant qu on "
          "ne la lui donne pas.")
    print("")

    tous = _appareils()
    for a in tous:
        print("APPAREIL|id=%s|nom=%s|plateforme=%s|emulateur=%s"
              % (a.get("id"), a.get("name"), a.get("targetPlatform"),
                 a.get("emulator")))
    physiques = [a for a in tous
                 if str(a.get("targetPlatform", "")).startswith("android")
                 and not a.get("emulator")]
    print("LECTURE|appareils=%d|android_physiques=%d"
          % (len(tous), len(physiques)))
    print("")

    DEPOT_APPAREIL.mkdir(parents=True, exist_ok=True)
    print("COMMANDE REJOUABLE -- a lancer avec l appareil branche, deverrouille,")
    print("debogage USB autorise (l autorisation se donne SUR l ecran de "
          "l appareil) :")
    print("")
    print("  flutter run --release -d <id> -t %s \\" % relatif)
    print("    | tee %s/<id>-<date>.txt"
          % DEPOT_APPAREIL.relative_to(RACINE).as_posix())
    print("")
    print("  puis relancer le mode par defaut, qui LIT le depot :")
    print("    python %s"
          % Path(__file__).resolve().relative_to(RACINE).as_posix())
    print("")

    if not physiques:
        print("NON EXECUTABLE AUJOURD HUI, et le motif est PLAT : AUCUN "
              "appareil Android physique n est")
        print("visible de `flutter devices --machine` (lu ci-dessus). Ce n "
              "est PAS un echec de cet")
        print("instrument : la commande ci-dessus est rejouable telle quelle "
              "des qu un appareil repond.")
        print("ATTENTION : tant qu elle n a pas tourne, la commande elle-meme est "
              "NON VERIFIEE -- seule son")
        print("ANALYSE statique l est (ligne ANALYSE| ci-dessus).")
        return 1
    print("APPAREIL PRESENT : lancement.")
    proc = subprocess.run(
        [_flutter(), "run", "--release", "-d", physiques[0]["id"],
         "-t", relatif],
        cwd=str(RACINE), capture_output=True, text=True,
        encoding="utf-8", errors="replace",
    )
    lignes = ((proc.stdout or "") + (proc.stderr or "")).splitlines()
    utiles = _utiles(lignes)
    for ligne in utiles:
        print(ligne)
    if not _a_tourne(lignes):
        print("ECHEC : la cible n a rendu aucun VERDICT. Sortie brute :")
        for ligne in lignes[:20]:
            print("  %s" % ligne)
        return 1
    depose = DEPOT_APPAREIL / ("%s.txt" % physiques[0]["id"].replace(":", "_"))
    _ecrire(depose, "\n".join(utiles) + "\n")
    print("")
    print("DEPOSE|%s" % depose.relative_to(RACINE).as_posix())
    return 0


# --------------------------------------------------------------------------
# MODE PAR DEFAUT : LE CRITERE
# --------------------------------------------------------------------------
def _lib_connait_la_cle() -> list:
    """Les fichiers de `lib/` ou la cle de retrait apparait. LUS."""
    porteurs = []
    for source in SOURCES_LIB:
        if source.exists() and CLE_RETRAIT in source.read_text(encoding="utf-8"):
            porteurs.append(source.relative_to(RACINE).as_posix())
    return porteurs


def _depots() -> list:
    """Les mesures appareil deposees, avec la serie que chacune COUVRE."""
    if not DEPOT_APPAREIL.exists():
        return []
    trouves = []
    for fichier in sorted(DEPOT_APPAREIL.glob("*.txt")):
        texte = fichier.read_text(encoding="utf-8", errors="replace")
        couverts = set()
        for m in re.finditer(r"^MESURE\|n=(\d+)\|", texte, re.MULTILINE):
            couverts.add(int(m.group(1)))
        verdict = "OK" if re.search(r"^VERDICT\|OK\|", texte, re.MULTILINE) \
            else "ECHEC/ABSENT"
        trouves.append((fichier.relative_to(RACINE).as_posix(), couverts,
                        verdict))
    return trouves


def critere() -> int:
    print("== CRITERE DE SORTIE de D-8 : le cout d une ecriture atomique a N "
          "retirees est MESURE ==")
    print("   Ce critere ne pose AUCUN plafond et n enonce AUCUN AC "
          "(arbitrage humain du")
    print("      2026-08-24 : MESURER D ABORD, BORNER ENSUITE). Il exige une "
          "MESURE, pas une borne.")
    print("")
    print("ENTREE|serie=%s|presentes=%d|repetitions=%d|cle_retrait=%s"
          % (list(SERIE), PRESENTES, REPETITIONS, CLE_RETRAIT))
    print("")

    porteurs = _lib_connait_la_cle()
    print("FAIT-1|lib_connait_la_cle=%s|porteurs=%s"
          % (bool(porteurs), porteurs or "aucun"))
    depots = _depots()
    for chemin, couverts, verdict in depots:
        print("FAIT-2|depot=%s|serie_couverte=%s|verdict=%s"
              % (chemin, sorted(couverts), verdict))
    if not depots:
        print("FAIT-2|depot=aucun|repertoire=%s"
              % DEPOT_APPAREIL.relative_to(RACINE).as_posix())
    tous = _appareils()
    physiques = [a for a in tous
                 if str(a.get("targetPlatform", "")).startswith("android")
                 and not a.get("emulator")]
    print("FAIT-3|appareils_visibles=%d|android_physiques=%d|contexte=oui"
          % (len(tous), len(physiques)))
    print("       (FAIT-3 n est PAS un critere : un critere qui depend d un "
          "cable USB serait instable.)")
    print("")

    complets = [d for d in depots
                if set(SERIE).issubset(d[1]) and d[2] == "OK"]
    manques = []
    if not porteurs:
        manques.append(
            "l axe des TAILLES est le MODELE de ce critere, PAS celui du "
            "produit : la cle `%s`\n"
            "    n apparait dans AUCUN des %d fichiers de `lib/` designes "
            "ci-dessus (taches T2/T3 non\n"
            "    livrees). La DUREE, elle, est reelle des aujourd hui."
            % (CLE_RETRAIT, len(SOURCES_LIB)))
    if not complets:
        manques.append(
            "AUCUNE mesure APPAREIL couvrant la serie declaree n est deposee "
            "sous\n    %s. Or personne n a jamais mesure une ecriture "
            "atomique de cette taille sur un\n    appareil -- c est la "
            "question MEME de D-8."
            % DEPOT_APPAREIL.relative_to(RACINE).as_posix())

    if manques:
        print("NON SATISFAIT -- et le motif est PLAT :")
        for i, m in enumerate(manques, 1):
            print("  (%d) %s" % (i, m))
        print("")
        print("Ce n est PAS un echec de cet instrument : il est REJOUABLE en "
              "l etat.")
        print("   Ce qui est mesurable DES AUJOURD HUI : --hote (le chemin "
              "d ecriture de production,")
        print("   sur un vrai disque) et --selftest (le POUVOIR de la mesure, "
              "par mutation).")
        print("   Le chemin qui leve le (2) : --appareil (il imprime la "
              "commande rejouable).")
        return 1
    print("SATISFAIT -- une mesure appareil couvrant la serie declaree est "
          "deposee, et l axe des")
    print("tailles est celui du produit. Cela ne pose toujours AUCUN plafond "
          ": c est au")
    print("@ProductOwner de borner ou d assumer par ecrit, MAINTENANT SUR DES "
          "CHIFFRES.")
    return 0


def main() -> int:
    parseur = argparse.ArgumentParser(
        description="Instrument de mesure du cout d une ecriture atomique a N "
                    "retirees (D-8, US-01.4). Il ne pose aucun plafond."
    )
    parseur.add_argument("--hote", action="store_true",
                         help="mesurer HORS APPAREIL (chemin CI / poste), par "
                              "le chemin d ecriture de production")
    parseur.add_argument("--selftest", action="store_true",
                         help="mesurer le POUVOIR de la mesure (une source "
                              "conforme + des mutants comportementaux ; le mode "
                              "IMPRIME les decomptes, ils ne sont ecrits nulle "
                              "part)")
    parseur.add_argument("--appareil", action="store_true",
                         help="generer la cible appareil, LIRE la liste des "
                              "appareils et imprimer la commande rejouable")
    args = parseur.parse_args()
    if args.hote:
        return hote()
    if args.selftest:
        return selftest()
    if args.appareil:
        return appareil()
    return critere()


if __name__ == "__main__":
    sys.exit(main())
