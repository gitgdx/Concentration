#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""T2 d'US-01.3 -- controle des secrets de signature et de l'identifiant d'appareil.

CE QU'IL REFUSE (AC-4 Nominal et Limite, AC-1, R-4, ADR-015 §13, REGISTRE §1.8)
-------------------------------------------------------------------------------
Dans les FICHIERS SUIVIS, dans TOUT L'HISTORIQUE (contenus de toutes les
references) et dans les MESSAGES DE COMMIT :
* un keystore, reconnu par son CONTENU (en-tetes JKS, JCEKS, structure PKCS12)
  et, en plus, par son extension. ⚠️ Le keytool du JBR d'Android Studio ecrit du
  PKCS12 par defaut, meme dans un fichier nomme `.jks` (mesure le 2026-10-01 sur
  des keystores factices hors depot) : l'extension ne dit rien du format ;
* un fichier `key.properties`, ou un mot de passe de signature en clair (fichier
  de proprietes, litteral dans un script de build, argument de keytool ou
  d'apksigner) ;
* un identifiant d'appareil hors du champ `appareil.empreinte` : ligne de sortie
  `adb devices`, valeur de `ro.serialno`, argument `adb -s`, dont la serie
  n'est pas dans la LISTE AUTORISEE des valeurs fictives ci-dessous ;
* dans le registre, les preuves (`docs/deploiement/`) et les fixtures
  (`scripts/deploiement/fixtures/`) : un champ `appareil` portant autre chose que
  `modele`, `api`, `empreinte` ; une empreinte hors de la forme `^[0-9a-f]{16}$` ;
  dans une fixture, une empreinte hors de la liste autorisee ; un chemin absolu
  du poste, une adresse electronique, une adresse MAC, un nom de certificat
  (`CN=`) autre que fictif ou de debogage, une liste d'applications installees.

DEUX MODES
----------
    python scripts/deploiement/check_secrets_signature.py             # (a) CI : par la FORME
    python scripts/deploiement/check_secrets_signature.py --local     # (a) + (b) : par la VALEUR
    python scripts/deploiement/check_secrets_signature.py --selftest  # autotest de mutation

(b) lit le numero de serie des appareils connectes par `adb`, resolu depuis
`sdk.dir` de `android/local.properties`, sinon `ANDROID_HOME` (ADR-015 §6) --
⛔ JAMAIS depuis le PATH. Le SDK de la machine de reference porte un doublon
`platform-tools-2` : seul `platform-tools` est utilise, tout doublon est NOMME
(jamais choisi), et un SDK qui n'a QUE le doublon rend `adb_introuvable`.
⛔ La valeur lue n'est JAMAIS affichee : seulement trouvee ou non, et ou.
⛔ (b) est reserve a l'HUMAIN : la valeur lue est une donnee C2.

CODES DE SORTIE (ADR-015 §6)
----------------------------
    0  conforme
    1  refus, cause nommee
    2  ne conclut pas (clone superficiel, adb introuvable, aucun appareil...)
    3  defaut de l'instrument (git illisible, argument inconnu, autotest en echec)

CODES DE CAUSE : uniquement le jeu gele de 60 (REGISTRE §6.2 et §6.2 bis,
controle par `reports/US-01.3/egalite_codes_criterion.py` ; l'autotest le
verifie). ⛔ AUCUN CODE N'EST CREE ICI. Plusieurs causes de ce controle n'ont
AUCUN code dans ce jeu (leur nombre est imprime par --selftest, jamais ecrit
ici) : leur entree de CAUSES porte `code=None`, la sortie imprime
`(code de cause non attribue)`, et l'attribution releve de l'arbitrage. Les
cles internes ne sont jamais imprimees.

CE QU'IL NE PROUVE PAS
----------------------
* ⛔ En CI, la VALEUR reelle du numero de serie : la CI ne la connait pas, elle
  ne refuse que la FORME, la ou la forme d'un identifiant est attendue. Une
  serie collee dans une prose libre n'est vue que par le mode (b).
* Un keystore BKS / BCFKS reconnu par son contenu (seulement par extension),
  ni un keystore chiffre dans une archive.
* Un mot de passe faible ecrit hors d'une syntaxe cle-valeur ou d'un argument
  de commande, ni un texte encode en UTF-16 (traite comme binaire).
* Le contenu des echeances du pratiquant dans une preuve (ADR-016 §1) : aucune
  forme ne le distingue d'une phrase quelconque.
* Une sortie `adb devices` dont les tabulations ont ete remplacees par UN seul
  espace.
"""

from __future__ import annotations

import importlib.util
import json
import os
import random
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Iterable

RACINE = Path(__file__).resolve().parents[2]

CONFORME, REFUSE, NE_CONCLUT_PAS, DEFAUT = 0, 1, 2, 3
MOT_VERDICT = {
    CONFORME: "CONFORME",
    REFUSE: "REFUSÉ",
    NE_CONCLUT_PAS: "NE CONCLUT PAS",
    DEFAUT: "DÉFAUT DE L'INSTRUMENT",
}
PHRASE_FIXE = {
    NE_CONCLUT_PAS: "Rien n'a été établi. Aucune étape suivante n'est autorisée par ce résultat.",
    DEFAUT: "L'outil lui-même est en cause. Rien n'a été établi sur l'artefact ni sur l'appareil.",
}
ETAPE = "contrôle des secrets"
LARGEUR = 100

# ---------------------------------------------------------------------------
# LISTE AUTORISEE DES VALEURS FICTIVES -- exemplaire UNIQUE (REGISTRE §5.3).
# ⛔ Les tests l'IMPORTENT, ils ne la recopient pas.
# ---------------------------------------------------------------------------
SERIES_FICTIVES = frozenset({"FICTIF0SERIE01", "FICTIF0SERIE02", "emulator-5554"})
EMPREINTES_FICTIVES = frozenset({"f1c7f1c7f1c7f1c7", "f1c70000f1c70000"})
PREFIXE_SHA256_FICTIF = "f1c7"
CN_ADMIS = frozenset({"FICTIF", "Android Debug"})
DESCRIPTIONS_FICTIVES = tuple("Fictif " + c for c in "ABCDEFGHI")

MOTIF_EMPREINTE = re.compile(r"[0-9a-f]{16}")
CLES_APPAREIL = frozenset({"modele", "api", "empreinte"})
PORTEE_PREUVES = ("docs/deploiement/",)
PORTEE_FIXTURES = ("scripts/deploiement/fixtures/",)
EXTENSIONS_KEYSTORE = frozenset({".jks", ".keystore", ".p12", ".pfx", ".bks", ".jceks", ".bcfks"})
NOM_PROPRIETES = "key.properties"


@dataclass(frozen=True)
class Cause:
    code: str | None  # code du jeu gele ; None = AUCUN code dans le jeu (arbitrage)
    issue: int
    phrase: str
    a_faire: str


A_FAIRE_FUITE = ("retirez-le du dépôt. S'il figure dans l'historique, le dépôt public l'a déjà "
                 "exposé : tenez le secret pour perdu (étape du runbook « contrôle des secrets »).")

# Ordre = ordre d'affichage. Cles internes : jamais imprimees.
CAUSES: dict[str, Cause] = {
    "keystore": Cause(
        "signature_keystore_dans_le_depot", REFUSE,
        "Un keystore est présent dans le dépôt, qui est public.", A_FAIRE_FUITE),
    # Code a attribuer : propriete ou mot de passe de signature versionne.
    "proprietes": Cause(
        None, REFUSE,
        "Un fichier de propriétés de signature ou un mot de passe de signature est versionné.",
        A_FAIRE_FUITE),
    # Code a attribuer : identifiant d'appareil hors de appareil.empreinte (forme).
    "appareil": Cause(
        None, REFUSE,
        "Un identifiant d'appareil figure hors du champ appareil.empreinte, ou une empreinte "
        "n'a pas la forme imposée.",
        "remplacez l'identifiant par l'empreinte, ou par une valeur de la liste autorisée dans "
        "une fixture, puis relancez."),
    # Code a attribuer : numero de serie lu par adb, trouve en clair (valeur).
    "serie_en_clair": Cause(
        None, REFUSE,
        "Le numéro de série d'un appareil connecté figure en clair dans le dépôt.", A_FAIRE_FUITE),
    # Code a attribuer : valeur interdite (REGISTRE §1.8) dans une preuve ou une fixture.
    "valeur_interdite": Cause(
        None, REFUSE,
        "Une preuve ou une fixture porte une valeur interdite : chemin absolu du poste, adresse, "
        "nom de certificat ou liste d'applications.",
        "remplacez la valeur par sa forme caviardée (registre, paragraphe 5.2), puis relancez."),
    # Code a attribuer : historique tronque.
    "historique_incomplet": Cause(
        None, NE_CONCLUT_PAS,
        "Le clone est superficiel : l'historique du dépôt n'a pas pu être lu en entier.",
        "relancez dans un clone complet (en CI : fetch-depth: 0)."),
    "adb_introuvable": Cause(
        "adb_introuvable", NE_CONCLUT_PAS,
        "L'outil adb est introuvable : ni sdk.dir de android/local.properties, ni ANDROID_HOME "
        "ne mènent à platform-tools. Aucune liste d'appareils n'a pu être lue.",
        "vérifiez sdk.dir dans android/local.properties. L'outil ne cherche jamais adb dans le "
        "PATH."),
    "aucun_appareil": Cause(
        "aucun_appareil", NE_CONCLUT_PAS,
        "Aucun appareil physique n'est connecté : aucun numéro de série n'a été lu.",
        "branchez l'appareil de référence, autorisez le débogage, puis relancez."),
    # Code a attribuer : adb present mais muet.
    "adb_muet": Cause(
        None, NE_CONCLUT_PAS,
        "L'outil adb a été lancé mais n'a rendu aucune liste d'appareils lisible.",
        "relancez le serveur adb, puis relancez."),
    # Code a attribuer : defaut de l'instrument.
    "git_illisible": Cause(
        None, DEFAUT,
        "git n'a pas pu lire le dépôt.",
        "signalez-le à @DevOps ou @Architect, sans relancer en boucle."),
}


@dataclass(frozen=True)
class Constat:
    cause: str
    chemin: str
    portee: str  # "suivi" | "historique" | "message" | "depot"
    detail: str


@dataclass
class Corpus:
    suivis: dict[str, bytes]
    historique: list[tuple[str, bytes]]
    messages: list[tuple[str, str]]
    superficiel: bool


# ---------------------------------------------------------------------------
# Keystores : reconnaissance par le CONTENU
# ---------------------------------------------------------------------------
OID_PKCS7_DATA = bytes.fromhex("06092a864886f70d010701")


def _entete_der(c: bytes, i: int) -> int | None:
    """Saute l'octet de longueur DER/BER a l'indice i ; rend l'indice du contenu."""
    if i >= len(c):
        return None
    n = c[i]
    if n < 0x80 or n == 0x80:
        return i + 1
    k = n & 0x7F
    if k > 4:
        return None
    return i + 1 + k


def format_keystore(c: bytes) -> str | None:
    if len(c) >= 8 and c[4:8] in (b"\x00\x00\x00\x01", b"\x00\x00\x00\x02"):
        if c[:4] == b"\xfe\xed\xfe\xed":
            return "JKS"
        if c[:4] == b"\xce\xce\xce\xce":
            return "JCEKS"
    if len(c) >= 24 and c[0] == 0x30:
        i = _entete_der(c, 1)
        if i is not None and c[i:i + 3] == b"\x02\x01\x03" and i + 3 < len(c) and c[i + 3] == 0x30:
            j = _entete_der(c, i + 4)
            if j is not None and c[j:j + len(OID_PKCS7_DATA)] == OID_PKCS7_DATA:
                return "PKCS12"
    return None


# ---------------------------------------------------------------------------
# Regles textuelles
# ---------------------------------------------------------------------------
ETATS_ADB = r"device|unauthorized|offline|recovery|sideload|bootloader|rescue|host|no permissions"
MOTIF_LIGNE_ADB = re.compile(
    r"^[ \t>]*(?P<s>[A-Za-z0-9][A-Za-z0-9._:-]{3,63})(?P<sep>\t+|[ ]{2,})"
    r"(?P<e>" + ETATS_ADB + r")\b(?P<reste>[^\r\n]*)", re.M)
ATTRIBUTS_ADB = re.compile(r"\b(?:transport_id|model|product|usb):")
MOTIF_GETPROP = re.compile(
    r"\[?\b(?:ro\.(?:boot\.)?serialno|ril\.serialnumber)\]?[ \t]*[:=][ \t]*\[?"
    r"(?P<s>[A-Za-z0-9._-]+)", re.I)
MOTIF_ADB_S = re.compile(r"\badb(?:\.exe)?\b[^\r\n]*?[ \t]-s[ \t]+(?P<s>[^\s\"'`]+)")
MOTIF_CLE_MDP = re.compile(
    r"^[ \t]*(?:[#!][ \t]*)?(?:(?:val|var|const|def|final)[ \t]+)?[\"']?"
    r"(?P<k>\b[\w.-]*(?:password|passwd)|\bstorepass|\bkeypass)[\"']?"
    r"[ \t]*(?:[=:]|[ \t])[ \t]*(?P<v>[^\r\n]*)", re.I | re.M)
CLES_SIGNATURE = re.compile(
    r"^[ \t]*(?P<k>storeFile|keyAlias|storePassword|keyPassword)[ \t]*[=:]", re.M)
MOTIF_KEYTOOL = re.compile(
    r"(?<![\w-])-(?:src|dest|new)?(?:store|key)pass(?P<ind>:(?:env|file))?[ \t]+"
    r"(?P<v>\"[^\"]*\"|'[^']*'|[^\s\"'`]+)", re.I)
MOTIF_APKSIGNER = re.compile(r"--(?:ks|key)-pass[ \t=]+pass:(?P<v>[^\s\"'`]+)", re.I)
ESPACE_RESERVE = re.compile(r"<[^<>]+>|\$\{?\w+\}?|%\w+%|\*{3,}|…|\.{3}")
EXPRESSION = re.compile(r"[\[\](){}$]|\bas\b|getenv|System\.")

MOTIF_CHEMIN_ABSOLU = re.compile(
    r"(?<![\w<])(?:[A-Za-z]:[\\/](?=[^\s\"'<>])|\\\\[A-Za-z0-9._-]+\\|/(?:home|Users|root)/[^\s\"'<>/]+)")
MOTIF_COURRIEL = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}")
MOTIF_MAC = re.compile(r"(?<![0-9A-Fa-f:-])(?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}(?![0-9A-Fa-f:-])")
MOTIF_CN = re.compile(r"\bCN=(?P<v>[^,\r\n\"]+)")
MOTIF_PAQUET = re.compile(r"^package:(?P<p>[\w.]+)", re.M)
NOMS_IDENTIFIANT = frozenset({
    "serial", "serialno", "serialnumber", "serie", "numeroserie", "numerodeserie", "androidid",
    "imei", "mac", "macaddress", "adressemac", "nomappareil", "devicename"})


def _serie_admise(s: str) -> bool:
    return s in SERIES_FICTIVES


def _espace_reserve(v: str) -> bool:
    return bool(ESPACE_RESERVE.fullmatch(v.strip()))


def _litteral(v: str, brut_admis: bool) -> bool:
    v = v.strip().rstrip(",;").strip()
    if not v or _espace_reserve(v):
        return False
    q = re.fullmatch(r"\"([^\"]*)\"|'([^']*)'", v)
    if q:
        dedans = q.group(1) if q.group(1) is not None else (q.group(2) or "")
        return bool(dedans) and not _espace_reserve(dedans)
    if not brut_admis or EXPRESSION.search(v):
        return False
    return True


def _regles_ligne(ligne: str) -> tuple[tuple[str, str, bool], ...]:
    """Regles LOCALES a une ligne. Rend (cause, detail, exige_brut) : exige_brut = la valeur est
    un litteral NON cite, qui ne compte que dans un fichier de proprietes (decision par fichier).
    Les prefiltres par sous-chaine sont des conditions NECESSAIRES de leur motif : ils ne
    changent pas le verdict, seulement le temps de calcul."""
    out: list[tuple[str, str, bool]] = []
    bas = ligne.lower()
    m = MOTIF_LIGNE_ADB.match(ligne) if "	" in ligne or "  " in ligne else None
    if m and not _serie_admise(m.group("s")) and (
            "	" in m.group("sep") or not m.group("reste").strip() or ATTRIBUTS_ADB.search(m.group("reste"))):
        out.append(("appareil", "ligne de sortie adb devices portant une série non fictive", False))
    if "serialno" in bas or "serialnumber" in bas:
        for m in MOTIF_GETPROP.finditer(ligne):
            if not _serie_admise(m.group("s")):
                out.append(("appareil", "valeur de propriété de numéro de série non fictive", False))
    if "adb" in bas and "-s" in bas:
        for m in MOTIF_ADB_S.finditer(ligne):
            v = m.group("s")
            if not _serie_admise(v) and not _espace_reserve(v) and v[0] not in "<$%{":
                out.append(("appareil", "cible adb désignée par une série non fictive", False))
    if "pass" in bas:
        m = MOTIF_CLE_MDP.match(ligne)
        if m and _litteral(m.group("v"), brut_admis=False):
            out.append(("proprietes", "mot de passe de signature en clair", False))
        elif m and _litteral(m.group("v"), brut_admis=True):
            out.append(("proprietes", "mot de passe de signature en clair", True))
        for m in MOTIF_KEYTOOL.finditer(ligne):
            if not m.group("ind") and _litteral(m.group("v"), brut_admis=True):
                out.append(("proprietes", "mot de passe en argument de commande", False))
        for m in MOTIF_APKSIGNER.finditer(ligne):
            if not _espace_reserve(m.group("v")):
                out.append(("proprietes", "mot de passe en argument de commande", False))
    return tuple(out)


_CACHE_LIGNES: dict[str, tuple[tuple[str, str, bool], ...]] = {}


def analyser_texte(texte: str, proprietes: bool) -> list[tuple[str, str]]:
    """Analyse ligne par ligne, chaque ligne DISTINCTE une seule fois (l'historique repete les
    memes lignes d'une version a l'autre). Un fichier compte comme fichier de proprietes s'il
    est nomme *.properties ou s'il porte au moins deux cles de signature."""
    out: list[tuple[str, str]] = []
    conditionnels: list[tuple[str, str]] = []
    cles_signature: set[str] = set()
    for ligne in texte.splitlines():
        r = _CACHE_LIGNES.get(ligne)
        if r is None:
            r = _CACHE_LIGNES[ligne] = _regles_ligne(ligne)
        for cause, detail, exige_brut in r:
            (conditionnels if exige_brut else out).append((cause, detail))
        if "store" in ligne or "key" in ligne:
            m = CLES_SIGNATURE.match(ligne)
            if m:
                cles_signature.add(m.group("k"))
    if conditionnels and (proprietes or len(cles_signature) >= 2):
        out += conditionnels
    return out


def _valeurs_interdites(texte: str) -> list[tuple[str, str]]:
    out: list[tuple[str, str]] = []
    if MOTIF_CHEMIN_ABSOLU.search(texte):
        out.append(("valeur_interdite", "chemin absolu du poste"))
    if MOTIF_COURRIEL.search(texte):
        out.append(("valeur_interdite", "adresse électronique"))
    if MOTIF_MAC.search(texte):
        out.append(("valeur_interdite", "adresse MAC"))
    if any(m.group("v").strip() not in CN_ADMIS for m in MOTIF_CN.finditer(texte)):
        out.append(("valeur_interdite", "nom de certificat non fictif"))
    if any(not m.group("p").startswith("com.concentration.concentration")
           for m in MOTIF_PAQUET.finditer(texte)):
        out.append(("valeur_interdite", "liste d'applications installées"))
    return out


def _structure_json(texte: str, fixture: bool) -> list[tuple[str, str]]:
    docs: list[object] = []
    try:
        docs.append(json.loads(texte))
    except ValueError:
        for ligne in texte.splitlines():
            try:
                docs.append(json.loads(ligne))
            except ValueError:
                continue  # grammaire du registre : check_registre.py (T7)
    out: list[tuple[str, str]] = []

    def empreinte(v: object) -> None:
        if not isinstance(v, str) or not MOTIF_EMPREINTE.fullmatch(v):
            out.append(("appareil", "empreinte hors de la forme imposée"))
        elif fixture and v not in EMPREINTES_FICTIVES:
            out.append(("appareil", "empreinte non fictive dans une fixture"))

    def parcourir(o: object) -> None:
        if isinstance(o, dict):
            rupture = o.get("nature") == "rupture_empreinte"
            for k, v in o.items():
                if re.sub(r"[^a-z0-9]", "", str(k).lower()) in NOMS_IDENTIFIANT:
                    out.append(("appareil", "champ nommé comme un identifiant d'appareil"))
                if k == "appareil":
                    if not isinstance(v, dict) or not set(v) <= CLES_APPAREIL:
                        out.append(("appareil", "champ appareil portant autre chose que "
                                                "modele, api, empreinte"))
                if k == "empreinte" or (rupture and k in ("ancienne", "nouvelle")):
                    empreinte(v)
                parcourir(v)
        elif isinstance(o, list):
            for v in o:
                parcourir(v)

    for d in docs:
        parcourir(d)
    return out


def _texte(contenu: bytes) -> str | None:
    if b"\x00" in contenu[:8192]:
        return None
    if contenu.startswith(b"\xef\xbb\xbf"):
        contenu = contenu[3:]
    try:
        return contenu.decode("utf-8")
    except UnicodeDecodeError:
        return contenu.decode("latin-1")


def analyser_contenu(chemin: str, contenu: bytes) -> list[tuple[str, str]]:
    out: list[tuple[str, str]] = []
    nom = chemin.rsplit("/", 1)[-1]
    ext = ("." + nom.rsplit(".", 1)[-1].lower()) if "." in nom else ""
    fmt = format_keystore(contenu)
    if fmt:
        out.append(("keystore", "contenu de keystore " + fmt))
    elif ext in EXTENSIONS_KEYSTORE:
        out.append(("keystore", "extension de keystore"))
    if nom == NOM_PROPRIETES:
        out.append(("proprietes", "fichier key.properties"))
    texte = _texte(contenu)
    if texte is None:
        return out
    out += analyser_texte(texte, proprietes=ext == ".properties")
    fixture = chemin.startswith(PORTEE_FIXTURES)
    if fixture or chemin.startswith(PORTEE_PREUVES):
        out += _valeurs_interdites(texte)
        if ext in (".json", ".jsonl"):
            out += _structure_json(texte, fixture)
    return out


def _fusionner(bruts: Iterable[tuple[str, str, str, str]]) -> set[Constat]:
    """(cause, chemin, portee, detail) -> un Constat par (cause, chemin) ; le suivi l'emporte."""
    par_cle: dict[tuple[str, str], tuple[str, set[str]]] = {}
    rang = {"depot": 0, "suivi": 1, "message": 2, "historique": 3}
    for cause, chemin, portee, detail in bruts:
        cle = (cause, chemin)
        if cle in par_cle:
            p, d = par_cle[cle]
            d.add(detail)
            if rang[portee] < rang[p]:
                par_cle[cle] = (portee, d)
        else:
            par_cle[cle] = (portee, {detail})
    return {Constat(c, ch, p, " ; ".join(sorted(d))) for (c, ch), (p, d) in par_cle.items()}


def analyser(corpus: Corpus) -> set[Constat]:
    bruts: list[tuple[str, str, str, str]] = []
    for chemin, contenu in corpus.suivis.items():
        bruts += [(c, chemin, "suivi", d) for c, d in analyser_contenu(chemin, contenu)]
    vus: set[tuple[str, bytes]] = set()
    for chemin, contenu in corpus.historique:
        if (chemin, contenu) in vus:
            continue
        vus.add((chemin, contenu))
        bruts += [(c, chemin, "historique", d) for c, d in analyser_contenu(chemin, contenu)]
    for sha, message in corpus.messages:
        lieu = "message de commit " + sha
        bruts += [(c, lieu, "message", d) for c, d in analyser_texte(message, proprietes=False)]
    if corpus.superficiel:
        bruts.append(("historique_incomplet", ".", "depot", "clone superficiel"))
    return _fusionner(bruts)


def chercher_valeurs(corpus: Corpus, valeurs: Iterable[str]) -> set[Constat]:
    """Mode (b) : recherche de VALEURS lues, insensible a la casse. Rien n'est conserve d'elles."""
    aiguilles = [v.strip().lower().encode("utf-8") for v in valeurs if v.strip()]
    bruts: list[tuple[str, str, str, str]] = []
    if not aiguilles:
        return set()

    def contient(b: bytes) -> bool:
        b = b.lower()
        return any(a in b for a in aiguilles)

    for chemin, contenu in corpus.suivis.items():
        if contient(contenu):
            bruts.append(("serie_en_clair", chemin, "suivi", "valeur lue par adb, trouvée"))
    for chemin, contenu in corpus.historique:
        if contient(contenu):
            bruts.append(("serie_en_clair", chemin, "historique", "valeur lue par adb, trouvée"))
    for sha, message in corpus.messages:
        if contient(message.encode("utf-8")):
            bruts.append(("serie_en_clair", "message de commit " + sha, "message",
                          "valeur lue par adb, trouvée"))
    return _fusionner(bruts)


# ---------------------------------------------------------------------------
# Effets : lecture du depot par git
# ---------------------------------------------------------------------------
class GitIllisible(Exception):
    pass


def _git(racine: Path, *args: str, entree: bytes | None = None) -> bytes:
    try:
        r = subprocess.run(["git", "-c", "core.quotePath=false", "-C", str(racine), *args],
                           input=entree, capture_output=True, timeout=600)
    except (OSError, subprocess.SubprocessError) as e:
        raise GitIllisible(type(e).__name__) from e
    if r.returncode != 0:
        raise GitIllisible("git " + args[0] + " : code " + str(r.returncode))
    return r.stdout


def lire_corpus(racine: Path) -> Corpus:
    suivis: dict[str, bytes] = {}
    for chemin in _git(racine, "ls-files", "-z").decode("utf-8", "replace").split("\0"):
        if chemin and (racine / chemin).is_file() and not (racine / chemin).is_symlink():
            suivis[chemin] = (racine / chemin).read_bytes()
    superficiel = _git(racine, "rev-parse", "--is-shallow-repository").strip() == b"true"
    paires: set[tuple[str, str]] = set()
    if _git(racine, "for-each-ref", "--count=1").strip():
        brut = _git(racine, "log", "--all", "--root", "-m", "--raw", "--no-abbrev",
                    "--no-renames", "--format=", "-z")
        jetons = brut.decode("utf-8", "replace").split("\0")
        i = 0
        while i < len(jetons):
            j = jetons[i].lstrip("\n")
            if j.startswith(":") and i + 1 < len(jetons):
                meta = j[1:].split()
                if len(meta) >= 5 and meta[1] != "160000" and set(meta[3]) != {"0"}:
                    paires.add((meta[3], jetons[i + 1]))
                i += 2
            else:
                i += 1
        for ligne in _git(racine, "rev-list", "--objects", "--all").decode("utf-8", "replace").splitlines():
            sha, _, chemin = ligne.partition(" ")
            if chemin:
                paires.add((sha, chemin))
    historique: list[tuple[str, bytes]] = []
    shas = sorted({s for s, _ in paires})
    contenus: dict[str, bytes] = {}
    if shas:
        sortie = _git(racine, "cat-file", "--batch", entree=("\n".join(shas) + "\n").encode())
        k = 0
        while k < len(sortie):
            fin = sortie.index(b"\n", k)
            entete = sortie[k:fin].decode("ascii", "replace").split()
            k = fin + 1
            if len(entete) == 2 and entete[1] == "missing":
                continue
            taille = int(entete[2])
            if entete[1] == "blob":
                contenus[entete[0]] = sortie[k:k + taille]
            k += taille + 1
    for sha, chemin in sorted(paires):
        if sha in contenus:
            historique.append((chemin, contenus[sha]))
    messages: list[tuple[str, str]] = []
    if paires or suivis:
        brut = _git(racine, "log", "--all", "--format=%h%x00%B%x01").decode("utf-8", "replace")
        for bloc in brut.split("\x01"):
            sha, sep, corps = bloc.strip("\n").partition("\0")
            if sep:
                messages.append((sha, corps))
    return Corpus(suivis, historique, messages, superficiel)


# ---------------------------------------------------------------------------
# Effets : mode (b), adb depuis le SDK declare
# ---------------------------------------------------------------------------
Executeur = Callable[[list[str]], "tuple[int | None, str]"]


def executer_reel(args: list[str]) -> tuple[int | None, str]:
    try:
        r = subprocess.run(args, capture_output=True, timeout=60)
    except (OSError, subprocess.SubprocessError):
        return None, ""
    return r.returncode, r.stdout.decode("utf-8", "replace")


def _deproteger(v: str) -> str:
    """Echappements des fichiers de proprietes Java (sdk.dir=C\\:\\\\...)."""
    return re.sub(r"\\(.)", lambda m: {"t": "\t", "n": "\n"}.get(m.group(1), m.group(1)), v)


def lire_sdk(racine: Path, environ: dict[str, str]) -> tuple[Path | None, str]:
    lp = racine / "android" / "local.properties"
    if lp.is_file():
        for ligne in lp.read_text(encoding="utf-8", errors="replace").splitlines():
            m = re.match(r"^\s*sdk\.dir\s*[=:]\s*(.*?)\s*$", ligne)
            if m and m.group(1):
                return Path(_deproteger(m.group(1))), "sdk.dir de android/local.properties"
    if environ.get("ANDROID_HOME"):
        return Path(environ["ANDROID_HOME"]), "ANDROID_HOME"
    return None, ""


def resoudre_adb(racine: Path, environ: dict[str, str], windows: bool) -> tuple[Path | None, str, list[str]]:
    """Rend (adb | None, source nommee, doublons nommes). ⛔ Le PATH n'est jamais lu."""
    sdk, source = lire_sdk(racine, environ)
    if sdk is None or not sdk.is_dir():
        return None, source, []
    nom = "adb.exe" if windows else "adb"
    doublons = sorted(p.name for p in sdk.glob("platform-tools-*") if (p / nom).is_file())
    canon = sdk / "platform-tools" / nom
    return (canon if canon.is_file() else None), source, doublons


def lire_series(adb: Path, executer: Executeur) -> tuple[set[str] | None, int]:
    """Rend (series lues hors emulateurs | None si adb muet, nombre d'appareils physiques)."""
    rc, sortie = executer([str(adb), "devices"])
    if rc != 0 or "List of devices" not in sortie:
        return None, 0
    series: set[str] = set()
    physiques = 0
    for ligne in sortie.split("List of devices", 1)[1].splitlines()[1:]:
        champs = ligne.strip().split()
        if len(champs) < 2 or champs[0].startswith("emulator-"):
            continue
        physiques += 1
        series.add(champs[0])
        if champs[1] == "device":
            rc2, prop = executer([str(adb), "-s", champs[0], "shell", "getprop", "ro.serialno"])
            if rc2 == 0 and prop.strip():
                series.add(prop.strip())
    return series, physiques


# ---------------------------------------------------------------------------
# Sortie : grammaire UX §2 et §8 (aucune couleur, libelle avant valeur, <= 100)
# ---------------------------------------------------------------------------
def _envelopper(libelle: str, texte: str) -> list[str]:
    lignes: list[str] = []
    courante = libelle + " :" if libelle else ""
    for mot in texte.split():
        essai = (courante + " " + mot) if courante else mot
        if len(essai) <= LARGEUR or not courante.strip():
            courante = essai
        else:
            lignes.append(courante)
            courante = "  " + mot
    lignes.append(courante)
    return lignes


def rendre(issue: int, constats: set[Constat], etabli: str, notes: list[tuple[str, str]],
           causes_forcees: list[str] | None = None) -> str:
    out: list[str] = ["Étape : " + ETAPE + ", fichiers suivis et historique du dépôt"]
    for libelle, texte in notes:
        out += _envelopper(libelle, texte)
    ordre = list(CAUSES)
    for c in sorted(constats, key=lambda x: (ordre.index(x.cause), x.chemin)):
        lieu = "dépôt" if c.portee == "depot" else c.chemin + " (" + c.portee + ")"
        out += _envelopper("Constat", lieu + " : " + c.detail)
    out.append("")
    out.append("VERDICT : " + MOT_VERDICT[issue])
    if issue in PHRASE_FIXE:
        out.append(PHRASE_FIXE[issue])
    out.append("Étape : " + ETAPE)
    noms = causes_forcees if causes_forcees is not None else sorted(
        {c.cause for c in constats if CAUSES[c.cause].issue == issue}, key=ordre.index)
    for nom in noms:
        cause = CAUSES[nom]
        out += _envelopper("Cause", cause.phrase)
        out.append("  (" + (cause.code or "code de cause non attribué") + ")")
    if issue == CONFORME:
        out += _envelopper("Ce qui est établi", etabli)
        out += _envelopper("À faire", "passez à l'étape suivante du runbook.")
    else:
        pas_fait = {
            REFUSE: "aucun fichier n'a été modifié et l'historique n'a pas été réécrit.",
            NE_CONCLUT_PAS: "la recherche n'a pas porté sur tout ce qu'elle devait lire.",
            DEFAUT: "aucune lecture du dépôt n'a abouti.",
        }[issue]
        out += _envelopper("Ce qui n'a pas été fait", pas_fait)
        out += _envelopper("À faire", CAUSES[noms[0]].a_faire if noms else "relancez.")
    out.append("Registre : rien n'est consigné.")
    out.append("Code de sortie : " + str(issue))
    return "\n".join(out) + "\n"


def _issue(constats: set[Constat]) -> int:
    issues = {CAUSES[c.cause].issue for c in constats}
    for i in (DEFAUT, REFUSE, NE_CONCLUT_PAS):
        if i in issues:
            return i
    return CONFORME


def _etabli(corpus: Corpus) -> str:
    return ("%d fichiers suivis, %d contenus de l'historique et %d messages de commit lus. Aucun "
            "keystore, aucune propriété ni aucun mot de passe de signature, aucun identifiant "
            "d'appareil hors empreinte, aucune valeur interdite dans les preuves."
            % (len(corpus.suivis), len(corpus.historique), len(corpus.messages)))


BORNE_CI = ("ce contrôle refuse la forme d'un identifiant d'appareil ; il ne connaît pas sa valeur "
            "(mode local : --local, sur la machine de l'humain).")


def mode_ci(racine: Path) -> tuple[int, str]:
    try:
        corpus = lire_corpus(racine)
    except GitIllisible:
        return DEFAUT, rendre(DEFAUT, set(), "", [], causes_forcees=["git_illisible"])
    constats = analyser(corpus)
    issue = _issue(constats)
    return issue, rendre(issue, constats, _etabli(corpus), [("Borne", BORNE_CI)])


def mode_local(racine: Path, executer: Executeur, environ: dict[str, str],
               windows: bool) -> tuple[int, str]:
    try:
        corpus = lire_corpus(racine)
    except GitIllisible:
        return DEFAUT, rendre(DEFAUT, set(), "", [], causes_forcees=["git_illisible"])
    constats = analyser(corpus)
    notes: list[tuple[str, str]] = []
    adb, source, doublons = resoudre_adb(racine, environ, windows)
    if source:
        notes.append(("Source du SDK", source + " (valeur non affichée)"))
    for d in doublons:
        notes.append(("Doublon du SDK non utilisé", d + " : seul platform-tools est lu"))
    if adb is None:
        constats.add(Constat("adb_introuvable", ".", "depot", "adb non résolu"))
    else:
        series, physiques = lire_series(adb, executer)
        if series is None:
            constats.add(Constat("adb_muet", ".", "depot", "liste d'appareils illisible"))
        elif not series:
            constats.add(Constat("aucun_appareil", ".", "depot", "aucun appareil physique"))
        else:
            notes.append(("Appareils physiques lus", "%d (numéros de série non affichés)" % physiques))
            trouves = chercher_valeurs(corpus, series)
            notes.append(("Numéro de série en clair", "trouvé" if trouves else "non trouvé"))
            constats |= trouves
            del series
    issue = _issue(constats)
    etabli = _etabli(corpus) + " Le numéro de série des appareils connectés n'est présent nulle part."
    return issue, rendre(issue, constats, etabli, notes)


# ---------------------------------------------------------------------------
# AUTOTEST DE MUTATION
# Mutants tires de la STRUCTURE (emplacement, separateur, fin de ligne, nom de
# fichier neutre, historique seul, forme de longueur DER, portee), jamais du
# vocabulaire de la regle. Verdicts compares en ENSEMBLES (cause, chemin, portee).
# ---------------------------------------------------------------------------
def _hasard(n: int) -> str:
    return "".join(random.choice("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") for _ in range(n))


def _pkcs12(forme: str) -> bytes:
    corps = bytes.fromhex("020103") + bytes.fromhex("3082") + b"\x00\x40" + OID_PKCS7_DATA + bytes(64)
    if forme == "82":
        return b"\x30\x82" + len(corps).to_bytes(2, "big") + corps
    if forme == "83":
        return b"\x30\x83" + len(corps).to_bytes(3, "big") + corps
    return b"\x30\x80" + corps + b"\x00\x00"


def _cles(constats: set[Constat]) -> set[tuple[str, str, str]]:
    return {(c.cause, c.chemin, c.portee) for c in constats}


def _codes_geles() -> set[str]:
    p = RACINE / "reports" / "US-01.3" / "egalite_codes_criterion.py"
    spec = importlib.util.spec_from_file_location("egalite_codes_criterion", p)
    mod = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
    spec.loader.exec_module(mod)  # type: ignore[union-attr]
    ux = mod.UX.read_text(encoding="utf-8")
    rg = mod.REGISTRE.read_text(encoding="utf-8")
    return set(mod.ensembles(ux, rg)[1])


def _git_tmp(d: Path, *args: str) -> None:
    sans_crochets = d.parent / "sans_crochets"
    sans_crochets.mkdir(exist_ok=True)
    subprocess.run(["git", "-c", "core.hooksPath=" + str(sans_crochets), "-c", "commit.gpgsign=false",
                    "-c", "core.autocrlf=false", "-c", "user.name=fictif",
                    "-c", "user.email=fictif@invalid", "-C", str(d), *args],
                   check=True, capture_output=True)


def selftest() -> int:
    echecs: list[str] = []
    tues = 0
    serie = "Q" + _hasard(11)  # valeur fictive NON listee, tiree a l'execution
    mdp = "x" + _hasard(9).lower()
    propre = {
        "README.md": b"# Projet\nadb -s <SERIE> shell getprop\n",
        "scripts/deploiement/fixtures/adb/deux.txt":
            b"List of devices attached\r\nFICTIF0SERIE01\tdevice\r\nemulator-5554\tdevice\r\n",
        "docs/deploiement/registre.jsonl":
            b'{"nature":"staging","appareil":{"modele":"SM-T580","api":27,"empreinte":"0123456789abcdef"}}\n',
        "scripts/deploiement/fixtures/apksigner/debug.txt":
            b"Signer #1 certificate DN: CN=Android Debug, O=Android, C=US\nCN=FICTIF\n",
        "android/app/build.gradle.kts":
            b'storePassword = props["storePassword"] as String\nkeyAlias = props["keyAlias"] as String\n',
        "config/signing.properties": b"storeFile=<chemin>\nkeyAlias=<alias>\n",
        "docs/cert.der": bytes.fromhex("308202c6308201aea003020102") + bytes(40),
        "reports/note.md": b"Chemin : C:\\Program Files\\Android\n",
    }

    def verifier(nom: str, corpus: Corpus, attendu: set[tuple[str, str, str]]) -> None:
        nonlocal tues
        obtenu = _cles(analyser(corpus))
        if obtenu == attendu:
            tues += 1 if attendu else 0
        else:
            echecs.append("%s : attendu %s, obtenu %s" % (nom, sorted(attendu), sorted(obtenu)))

    def avec(**ajouts: bytes) -> Corpus:
        s = dict(propre)
        s.update({k.replace("__", "/").replace("_DOT_", "."): v for k, v in ajouts.items()})
        return Corpus(s, [], [], False)

    def un(chemin: str, contenu: bytes) -> Corpus:
        s = dict(propre)
        s[chemin] = contenu
        return Corpus(s, [], [], False)

    verifier("T0 corpus propre", Corpus(dict(propre), [], [], False), set())
    # Keystores : contenu, forme de longueur, nom neutre, emplacement hors android/
    jks = b"\xfe\xed\xfe\xed\x00\x00\x00\x02" + bytes(40)
    verifier("K1 JKS, nom neutre", un("a/b/c/donnees.bin", jks), {("keystore", "a/b/c/donnees.bin", "suivi")})
    verifier("K2 JCEKS sous une extension d'image", un("img.png", b"\xce\xce\xce\xce\x00\x00\x00\x01" + bytes(40)),
             {("keystore", "img.png", "suivi")})
    for forme in ("82", "83", "80"):
        verifier("K3 PKCS12 longueur " + forme, un("x/sans_extension", _pkcs12(forme)),
                 {("keystore", "x/sans_extension", "suivi")})
    verifier("K4 extension seule", un("racine.keystore", b"texte"), {("keystore", "racine.keystore", "suivi")})
    verifier("K5 historique seul", Corpus(dict(propre), [("old/d.bin", jks)], [], False),
             {("keystore", "old/d.bin", "historique")})
    verifier("K6 JKS a version hors domaine", un("v.bin", b"\xfe\xed\xfe\xed\x00\x00\x00\x07" + bytes(40)), set())
    # Proprietes : separateur, fin de ligne, BOM, nom neutre, commentaire, litteral
    verifier("P1 '=' fichier .properties", un("z/s.properties", ("storePassword=" + mdp + "\n").encode()),
             {("proprietes", "z/s.properties", "suivi")})
    verifier("P2 ':' CRLF BOM nom neutre", un("notes.txt", ("\ufeffstoreFile : f\r\nkeyPassword : " + mdp
                                                             + "\r\n").encode("utf-8")),
             {("proprietes", "notes.txt", "suivi")})
    verifier("P3 litteral dans un script de build", un("app/b.gradle.kts", ('  storePassword = "' + mdp + '"\n').encode()),
             {("proprietes", "app/b.gradle.kts", "suivi")})
    verifier("P4 ligne commentee", un("c.properties", ("# keyPassword=" + mdp + "\n").encode()),
             {("proprietes", "c.properties", "suivi")})
    verifier("P5 key.properties sans mot de passe, hors android/", un("tools/key.properties", b"storeFile=<f>\n"),
             {("proprietes", "tools/key.properties", "suivi")})
    verifier("P6 argument de commande", un("doc.md", ("keytool -genkeypair -" + "storepass " + mdp + "\n").encode()),
             {("proprietes", "doc.md", "suivi")})
    verifier("P7 argument apksigner", un("doc2.md", ("apksigner sign --ks-pass pass:" + mdp + "\n").encode()),
             {("proprietes", "doc2.md", "suivi")})
    verifier("P8 message de commit", Corpus(dict(propre), [], [("abc1234", "storePassword=\"" + mdp + "\"")], False),
             {("proprietes", "message de commit abc1234", "message")})
    verifier("P9 argument par variable", un("doc3.md", b"keytool -storepass:env STORE_PASS\n"), set())
    # Appareil (forme)
    verifier("S1 adb devices tabulation", un("reports/r.md", ("List of devices attached\n" + serie + "\tdevice\n").encode()),
             {("appareil", "reports/r.md", "suivi")})
    verifier("S2 adb devices -l espaces, CRLF", un("r2.txt", (serie + "   unauthorized usb:1-1 transport_id:3\r\n").encode()),
             {("appareil", "r2.txt", "suivi")})
    verifier("S3 getprop", un("r3.txt", ("[ro.serialno]: [" + serie + "]\n").encode()), {("appareil", "r3.txt", "suivi")})
    verifier("S4 adb -s", un("r4.md", ("adb -s " + serie + " shell dumpsys\n").encode()), {("appareil", "r4.md", "suivi")})
    verifier("S5 message de commit", Corpus(dict(propre), [], [("def5678", serie + "\tdevice")], False),
             {("appareil", "message de commit def5678", "message")})
    reg = "docs/deploiement/registre.jsonl"
    verifier("S6 champ supplementaire sous appareil", un(reg, b'{"appareil":{"modele":"m","api":1,"empreinte":"0123456789abcdef","x":"y"}}\n'),
             {("appareil", reg, "suivi")})
    for nom, v in (("majuscules", "0123456789ABCDEF"), ("15", "0123456789abcde"), ("17", "0123456789abcdef0")):
        verifier("S7 empreinte " + nom, un(reg, ('{"appareil":{"empreinte":"' + v + '"}}\n').encode()),
                 {("appareil", reg, "suivi")})
    fx = "scripts/deploiement/fixtures/registre/l.json"
    verifier("S8 empreinte bien formee non fictive dans une fixture", un(fx, b'{"empreinte":"0123456789abcdef"}'),
             {("appareil", fx, "suivi")})
    verifier("S9 meme empreinte fictive dans une fixture", un(fx, b'{"empreinte":"f1c7f1c7f1c7f1c7"}'), set())
    verifier("S10 rupture : nouvelle mal formee", un(reg, b'{"nature":"rupture_empreinte","ancienne":"f1c7f1c7f1c7f1c7","nouvelle":"z"}\n'),
             {("appareil", reg, "suivi")})
    # Valeurs interdites : portee preuves/fixtures seulement
    pv = "docs/deploiement/preuves/p.txt"
    for nom, v in (("chemin", b"C:\\Users\\fictif\\k"), ("courriel", b"a.b@exemple.org"),
                   ("MAC", b"0a:1b:2c:3d:4e:5f"), ("CN", b"CN=Autre, O=X"), ("paquets", b"package:com.autre.app\n")):
        verifier("F " + nom + " dans une preuve", un(pv, v), {("valeur_interdite", pv, "suivi")})
        verifier("F " + nom + " hors portee", un("docs/autre.md", v), set())
    # Superficiel
    verifier("H1 clone superficiel", Corpus(dict(propre), [], [], True), {("historique_incomplet", ".", "depot")})

    # Lecture git de bout en bout : historique seul, message, CRLF, clone superficiel
    with tempfile.TemporaryDirectory() as t:
        d = Path(t) / "depot"
        d.mkdir()
        _git_tmp(d, "init", "-q")
        (d / "a.txt").write_bytes(b"neutre\n")
        (d / "cache.bin").write_bytes(_pkcs12("82"))
        _git_tmp(d, "add", "-A")
        _git_tmp(d, "commit", "-q", "-m", "c1")
        (d / "cache.bin").unlink()
        (d / "b.txt").write_bytes(("x\r\nkeyPassword=" + mdp + "\r\nstoreFile=f\r\n").encode())
        _git_tmp(d, "add", "-A")
        _git_tmp(d, "commit", "-q", "-m", "c2\n\n" + serie + "\tdevice")
        _git_tmp(d, "rm", "-q", "--cached", "b.txt")
        _git_tmp(d, "commit", "-q", "-m", "c3")
        try:
            c = lire_corpus(d)
            obtenu = {(x.cause, x.chemin if not x.chemin.startswith("message") else "message", x.portee)
                      for x in analyser(c)}
            attendu = {("keystore", "cache.bin", "historique"), ("proprietes", "b.txt", "historique"),
                       ("appareil", "message", "message")}
            if obtenu != attendu:
                echecs.append("G1 lecture git : attendu %s, obtenu %s" % (sorted(attendu), sorted(obtenu)))
            else:
                tues += 1
            # Mode (b), adb SIMULE, SDK factice avec doublon, depot SANS refus de forme
            e = Path(t) / "local"
            e.mkdir()
            _git_tmp(e, "init", "-q")
            (e / "n.txt").write_bytes(b"neutre\n")
            _git_tmp(e, "add", "-A")
            _git_tmp(e, "commit", "-q", "-m", "e1")
            (e / "c.txt").write_bytes(("note " + serie.lower() + "\n").encode())
            _git_tmp(e, "add", "-A")
            _git_tmp(e, "commit", "-q", "-m", "e2")
            (e / "c.txt").unlink()
            _git_tmp(e, "add", "-A")
            _git_tmp(e, "commit", "-q", "-m", "e3 relie a " + serie)
            sdk = Path(t) / "sdk"
            for rep in ("platform-tools", "platform-tools-2"):
                (sdk / rep).mkdir(parents=True)
                for n in ("adb", "adb.exe"):
                    (sdk / rep / n).write_bytes(b"")
            (e / "android").mkdir()
            (e / "android" / "local.properties").write_text(
                "sdk.dir=" + str(sdk).replace("\\", "\\\\").replace(":", "\\:") + "\n", encoding="utf-8")

            def faux(sortie_devices: str) -> Executeur:
                def ex(args: list[str]) -> tuple[int | None, str]:
                    if args[1:] == ["devices"]:
                        return 0, sortie_devices
                    return 0, serie + "\r\n"
                return ex

            listes = {
                "B1 trouve (CRLF, casse, historique seul, message)":
                    ("List of devices attached\r\n" + serie + "\tdevice\r\n\r\n", REFUSE),
                "B2 liste vide": ("List of devices attached\r\n\r\n", NE_CONCLUT_PAS),
                "B3 emulateur seul": ("List of devices attached\nemulator-5554\tdevice\n", NE_CONCLUT_PAS),
                "B4 adb muet": ("", NE_CONCLUT_PAS),
            }
            for nom, (sortie, attendu_issue) in listes.items():
                issue, texte = mode_local(e, faux(sortie), {}, windows=os.name == "nt")
                constats_b = {l.split(" : ", 1)[1].rsplit(" (", 1)[0] for l in texte.splitlines()
                              if l.startswith("Constat : ")}
                attendu_b = ({"c.txt"} | {l for l in constats_b if l.startswith("message de commit ")}
                             if attendu_issue == REFUSE else set())
                if issue != attendu_issue:
                    echecs.append("%s : issue %d attendue, %d obtenue" % (nom, attendu_issue, issue))
                elif attendu_issue == REFUSE and (constats_b != attendu_b or len(constats_b) != 2):
                    echecs.append("%s : constats %s" % (nom, sorted(constats_b)))
                elif serie in texte or serie.lower() in texte:
                    echecs.append(nom + " : la valeur lue est imprimee")
                elif "platform-tools-2" not in texte:
                    echecs.append(nom + " : doublon non nomme")
                else:
                    tues += 1
            # B5 : adb dans le PATH seulement -> adb_introuvable, jamais le PATH
            d = e
            (d / "android" / "local.properties").unlink()
            env = {"PATH": str(sdk / "platform-tools")}
            issue, texte = mode_local(d, faux("List of devices attached\n" + serie + "\tdevice\n"), env,
                                      windows=os.name == "nt")
            if issue != NE_CONCLUT_PAS or "(adb_introuvable)" not in texte:
                echecs.append("B5 PATH seul : adb_introuvable attendu, issue %d" % issue)
            else:
                tues += 1
            # B6 : SDK qui n'a QUE le doublon -> adb_introuvable, doublon nomme
            shutil.rmtree(sdk / "platform-tools")
            issue, texte = mode_local(d, faux("List of devices attached\n" + serie + "\tdevice\n"),
                                      {"ANDROID_HOME": str(sdk)}, windows=os.name == "nt")
            if issue != NE_CONCLUT_PAS or "(adb_introuvable)" not in texte or "platform-tools-2" not in texte:
                echecs.append("B6 doublon seul : adb_introuvable et doublon nomme attendus, issue %d" % issue)
            else:
                tues += 1
            # H2 : clone superficiel reel
            s = Path(t) / "superficiel"
            subprocess.run(["git", "clone", "-q", "--depth", "1", d.resolve().as_uri(), str(s)],
                           check=True, capture_output=True)
            if not lire_corpus(s).superficiel:
                echecs.append("H2 clone --depth 1 non vu superficiel")
            else:
                tues += 1
        except (GitIllisible, subprocess.CalledProcessError, OSError) as e:
            echecs.append("G lecture git en defaut : " + type(e).__name__)

    # Grammaire de sortie (UX §2.2, §8) sur des sorties de chaque issue
    admis = set(chr(i) for i in range(0x20, 0x7F)) | set("àâäçéèêëîïôöùûüÿœæÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸŒÆ«»\n")
    interdits = re.compile(r"(?<!\w)(conforme|succès|réussi|réussite|ok|passé|vert|valide|validé)(?!\w)", re.I)
    sorties = {
        REFUSE: rendre(REFUSE, analyser(un("z/s.properties", ("storePassword=" + mdp).encode())), "", []),
        NE_CONCLUT_PAS: rendre(NE_CONCLUT_PAS, {Constat("historique_incomplet", ".", "depot", "x")}, "", []),
        DEFAUT: rendre(DEFAUT, set(), "", [], causes_forcees=["git_illisible"]),
        CONFORME: rendre(CONFORME, set(), _etabli(Corpus(dict(propre), [], [], False)), [("Borne", BORNE_CI)]),
    }
    for issue, texte in sorties.items():
        lignes = [l for l in texte.splitlines() if l.strip()]
        defauts = []
        if "\x1b" in texte or "\r" in texte:
            defauts.append("caractere de controle")
        if not set(texte) <= admis:
            defauts.append("caractere hors jeu admis")
        if any(len(l) > LARGEUR for l in texte.splitlines()):
            defauts.append("ligne > %d" % LARGEUR)
        if lignes[-1] != "Code de sortie : %d" % issue:
            defauts.append("derniere ligne")
        if issue in (NE_CONCLUT_PAS, DEFAUT):
            bloc = texte.split("VERDICT :", 1)[1]
            if interdits.search(bloc.replace(MOT_VERDICT[issue], "")):
                defauts.append("vocabulaire de l'issue 0")
        if mdp in texte:
            defauts.append("mot de passe imprime")
        if defauts:
            echecs.append("O%d grammaire : %s" % (issue, ", ".join(defauts)))
        else:
            tues += 1
    # Mutant de grammaire : un mot de l'issue 0 reintroduit a la forme negative doit etre vu
    if not interdits.search("Ce n'est pas un succès."):
        echecs.append("O mutant : vocabulaire interdit non detecte")
    # Codes emis ⊆ jeu gele de 60 ; aucun code cree
    try:
        geles = _codes_geles()
        hors = {c.code for c in CAUSES.values() if c.code and c.code not in geles}
        if hors:
            echecs.append("codes hors du jeu gele : %s" % sorted(hors))
        else:
            tues += 1
    except (OSError, ValueError, AttributeError) as e:
        echecs.append("jeu gele illisible : " + type(e).__name__)
    # Controle negatif : le depot reel ne porte AUCUN refus -- ce fichier compris, meme non suivi
    soi = Path(__file__).resolve()
    if analyser_contenu(soi.relative_to(RACINE).as_posix(), soi.read_bytes()):
        echecs.append("controle negatif : ce fichier se refuse lui-meme")
    try:
        reels = analyser(lire_corpus(RACINE))
        refus = {c for c in reels if CAUSES[c.cause].issue == REFUSE}
        if refus:
            echecs.append("controle negatif : %d refus sur le depot reel" % len(refus))
    except GitIllisible as e:
        echecs.append("controle negatif : git illisible (%s)" % e)

    for e in echecs:
        print("ECHEC : " + e)
    sans_code = sorted(k for k, c in CAUSES.items() if c.code is None)
    print("Causes sans code dans le jeu gele : %d" % len(sans_code))
    print("Mutants tues : %d ; controle negatif sur le depot reel : %s"
          % (tues, "aucun refus" if not any("controle negatif" in e for e in echecs) else "EN ECHEC"))
    print("Autotest : " + ("aucun echec" if not echecs else "%d echec(s)" % len(echecs)))
    print("Code de sortie : %d" % (0 if not echecs else DEFAUT))
    return 0 if not echecs else DEFAUT


def main(argv: list[str]) -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[union-attr]
    except (AttributeError, ValueError):
        pass
    if argv == ["--selftest"]:
        return selftest()
    if argv == ["--local"]:
        issue, texte = mode_local(RACINE, executer_reel, dict(os.environ), windows=os.name == "nt")
    elif not argv:
        issue, texte = mode_ci(RACINE)
    else:
        issue, texte = DEFAUT, ("Argument inconnu. Usage : [--local | --selftest]\n"
                                "Code de sortie : %d\n" % DEFAUT)
    sys.stdout.write(texte)
    return issue


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
