#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Critere de sortie de T4 d'US-01.3 -- regles gitleaks de la signature mobile.

CE QU'IL PROUVE (AC-4 Erreur, constat C-11, risque R-4)
-------------------------------------------------------
Sur des fixtures FACTICES generees dans un repertoire temporaire HORS du depot,
puis detruites :
  * avec la configuration PROPOSEE (reports/US-01.3/gitleaks.toml.proposed), les
    QUATRE formes de C-11 rendent exit 1, chacune par la regle attendue :
      F1 keystore binaire `.jks` (keytool du JBR, jamais le PATH),
      F2 `key.properties` a mot de passe aleatoire,
      F3 mot de passe aleatoire en dur dans un `.gradle.kts`,
      F4 `key.properties` a mot de passe FAIBLE (fins de ligne CRLF) ;
    et les fichiers SANS mot de passe ou a valeur RESERVEE rendent exit 0 ;
  * avec la configuration ACTUELLE (.gitleaks.toml), contrôle negatif : le constat
    de C-11 est retrouve (F1 et F4 -> exit 0, F2 et F3 -> exit 1) ;
  * la configuration proposee CONSERVE toutes les regles, l'allowlist et
    l'heritage de la configuration actuelle (comparaison de structures TOML) ;
  * la configuration proposee rend « no leaks » sur le DEPOT REEL (historique
    complet en mode git, comme la CI) et sur reports/US-01.3 (mode dir, qui
    contient ce critere et le fichier propose, pas encore versionnes).
Chaque execution de gitleaks est lue par son RAPPORT JSON, jamais par son seul
code de sortie : gitleaks rend aussi 1 sur une configuration illisible, et un 1
sans rapport est un DEFAUT, jamais un constat.

DEUX MODES DE GITLEAKS, ET UNE BORNE MESUREE
--------------------------------------------
Chaque fixture est jouee en mode `dir` (fichier sur disque : le critere ecrit de
T4) ET en mode `git` (fixture commitee dans un depot temporaire : ce que lisent
la CI et le hook pre-commit). ⚠️ En mode git, un fichier BINAIRE n'a aucune
ligne ajoutee dans le diff lu par gitleaks : la regle de chemin NE VOIT PAS le
keystore binaire (F1/git -> exit 0). C'est attendu ici comme une BORNE, imprimee
comme telle, pour que tout changement de comportement de gitleaks soit VU. La
variante F1A (meme keystore, attribut `diff` pose par `.gitattributes` dans le
depot temporaire) mesure le remede possible -- ⛔ non applique par T4.
Autre borne mesuree (B6) : l'allowlist globale « changeme » s'applique aussi
aux nouvelles regles.

CE QU'IL NE PROUVE PAS
----------------------
* La version du moteur de `gitleaks-action@v2` en CI (non lue) : le verdict vaut
  pour le gitleaks local, dont la version est imprimee.
* Qu'un keystore binaire commite soit refuse par gitleaks en CI : il ne l'est
  pas (borne ci-dessus) ; c'est T2 qui le refuse, par son contenu.
* Un mot de passe hors des cles storePassword / keyPassword, hors d'un fichier
  `.properties` ou d'un script Gradle : T2 et les regles par defaut seulement.

USAGE ET CODES DE SORTIE
------------------------
    python reports/US-01.3/gitleaks_t4_criterion.py                      # avant application
    python reports/US-01.3/gitleaks_t4_criterion.py --apres-application  # apres copie humaine
    python reports/US-01.3/gitleaks_t4_criterion.py --selftest           # autotest de mutation
    0  conforme
    1  ecart (attente non tenue, nommee)
    2  ne conclut pas : gitleaks, keytool ou git introuvable -- ⛔ JAMAIS un vert
    3  defaut de l'instrument (argument inconnu, configuration illisible, gitleaks
       sans rapport, autotest en echec)
Aucun mot de passe n'est imprime (option --redact, et les fixtures sont tirees
au hasard puis detruites). Aucun chemin absolu du poste n'est imprime.
"""

from __future__ import annotations

import json
import os
import re
import secrets
import shutil
import stat
import subprocess
import sys
import tempfile
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

RACINE = Path(__file__).resolve().parents[2]
PROPOSEE = Path("reports") / "US-01.3" / "gitleaks.toml.proposed"
ACTUELLE = Path(".gitleaks.toml")
PORTEE_DIR = Path("reports") / "US-01.3"

CONFORME, ECART, NE_CONCLUT_PAS, DEFAUT = 0, 1, 2, 3

ID_CHEMIN = "signature-keystore-chemin"
ID_PROPRIETES = "signature-mot-de-passe-proprietes"
ID_SCRIPT = "signature-mot-de-passe-script"
ID_GENERIQUE = "generic-api-key"  # regle par defaut qui voyait F2 et F3 en C-11

KEYTOOL_JBR = Path(r"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe")


class NeConclutPas(Exception):
    pass


class Defaut(Exception):
    pass


# ---------------------------------------------------------------------------
# Fixtures FACTICES -- jamais une valeur reelle. Les cles sont assemblees a
# l'execution : aucune ligne de ce fichier n'a la forme « cle = valeur » d'un
# mot de passe de signature (sinon T2 et la regle proposee la refuseraient).
# ---------------------------------------------------------------------------
K_STORE = "store" + "Password"
K_KEY = "key" + "Password"
FAIBLE = "soleil" + "2026"           # mot de passe humain a faible entropie, fictif
ALLOWLISTE = "change" + "me" + "42"  # contient le motif de l'allowlist globale


def _hasard() -> str:
    return secrets.token_urlsafe(18)


def _proprietes(lignes: list[str], fin: str = "\n") -> bytes:
    return fin.join(lignes + [""]).encode("utf-8")


def resoudre_keytool() -> Path:
    if KEYTOOL_JBR.is_file():
        return KEYTOOL_JBR
    flutter = shutil.which("flutter")  # seul flutter est cherche dans le PATH ; keytool jamais
    if flutter:
        try:
            r = subprocess.run([flutter, "config", "--list"], capture_output=True, text=True,
                               timeout=120, shell=flutter.lower().endswith(".bat"))
            m = re.search(r"jdk-dir:\s*(.+)", r.stdout)
            if m:
                k = Path(m.group(1).strip()) / "bin" / ("keytool.exe" if os.name == "nt" else "keytool")
                if k.is_file():
                    return k
        except (OSError, subprocess.SubprocessError):
            pass
    raise NeConclutPas("keytool introuvable (ni le JBR d'Android Studio, ni jdk-dir de flutter config)")


def keystore_binaire(keytool: Path, cible: Path) -> bytes:
    mdp = _hasard()
    r = subprocess.run(
        [str(keytool), "-genkeypair", "-keystore", str(cible), "-alias", "fictif",
         "-keyalg", "RSA", "-keysize", "2048", "-validity", "1",
         "-dname", "CN=FICTIF", "-storepass", mdp, "-keypass", mdp, "-noprompt"],
        capture_output=True, timeout=120)
    if r.returncode != 0 or not cible.is_file():
        raise Defaut("keytool n'a pas produit le keystore factice (exit %s)" % r.returncode)
    contenu = cible.read_bytes()
    cible.unlink()
    if b"\x00" not in contenu[:8192]:
        raise Defaut("le keystore factice n'est pas binaire : F1 ne mesurerait pas C-11")
    return contenu


@dataclass(frozen=True)
class Fixture:
    nom: str
    libelle: str
    fichiers: dict[str, bytes]


def fixtures(keytool: Path, travail: Path) -> list[Fixture]:
    (travail / "ks").mkdir()
    ks = keystore_binaire(keytool, travail / "ks" / "fictif.jks")
    r = _hasard()
    return [
        Fixture("F1", "keystore binaire .jks", {"upload-keystore.jks": ks}),
        Fixture("F1A", "keystore binaire .jks + attribut diff", {
            "upload-keystore.jks": ks, ".gitattributes": b"*.jks diff\n"}),
        Fixture("F2", "key.properties, mot de passe aleatoire", {"android/key.properties": _proprietes([
            K_STORE + "=" + r, K_KEY + "=" + r, "keyAlias=upload", "storeFile=../fictif.jks"])}),
        Fixture("F3", "mot de passe aleatoire en dur dans un .gradle.kts", {
            "android/app/build.gradle.kts": _proprietes([
                "android {", "    signingConfigs {", '        create("release") {',
                '            keyAlias = "upload"', "            " + K_STORE + ' = "' + r + '"',
                "            " + K_KEY + ' = "' + r + '"', "        }", "    }", "}"])}),
        Fixture("F4", "key.properties, mot de passe FAIBLE (CRLF)", {"android/key.properties": _proprietes([
            K_STORE + "=" + FAIBLE, K_KEY + "=" + FAIBLE, "keyAlias=upload",
            "storeFile=../fictif.jks"], fin="\r\n")}),
        Fixture("F5", "mot de passe FAIBLE en dur dans un .gradle (Groovy)", {
            "android/app/build.gradle": _proprietes([
                "signingConfigs {", "    release {", "        " + K_STORE + " '" + FAIBLE + "'",
                "        " + K_KEY + " '" + FAIBLE + "'", "    }", "}"])}),
        Fixture("N1", "key.properties SANS mot de passe", {"android/key.properties": _proprietes([
            "keyAlias=upload", "storeFile=../fictif.jks"])}),
        Fixture("N2", "key.properties a valeurs RESERVEES", {"android/key.properties": _proprietes([
            K_STORE + "=<a renseigner hors du depot>", K_KEY + "=$KEY_PASSWORD",
            K_STORE + " = ${STORE_PASSWORD}", K_KEY + "=", "keyAlias=upload"])}),
        Fixture("N3", ".gradle.kts lisant les proprietes", {"android/app/build.gradle.kts": _proprietes([
            "val props = java.util.Properties()",
            "android {", "    signingConfigs {", '        create("release") {',
            "            " + K_STORE + ' = props["' + K_STORE + '"] as String',
            "            " + K_KEY + ' = System.getenv("KEY_PASSWORD")',
            "            " + K_KEY + ' = "\\$KEY_PASSWORD"',
            "            " + K_STORE + ' = "<a renseigner>"',
            "        }", "    }", "}"])}),
        Fixture("B6", "key.properties, mot de passe contenant le motif d'allowlist", {
            "android/key.properties": _proprietes([K_STORE + "=" + ALLOWLISTE, "keyAlias=upload"])}),
    ]


# Attentes : (config, fixture, mode) -> (exit attendu, regles exigees, nature)
# nature : "critere" (T4), "controle" (C-11 sur l'actuelle), "borne" (mesuree, assumee).
Cle = tuple[str, str, str]


def attentes_proposee() -> dict[Cle, tuple[int, frozenset[str], str]]:
    a: dict[Cle, tuple[int, frozenset[str], str]] = {}
    for mode in ("dir", "git"):
        a[("proposee", "F2", mode)] = (1, frozenset({ID_PROPRIETES}), "critere")
        a[("proposee", "F3", mode)] = (1, frozenset({ID_SCRIPT}), "critere")
        a[("proposee", "F4", mode)] = (1, frozenset({ID_PROPRIETES}), "critere")
        a[("proposee", "F5", mode)] = (1, frozenset({ID_SCRIPT}), "critere")
        a[("proposee", "F1A", mode)] = (1, frozenset({ID_CHEMIN}), "critere")
        for n in ("N1", "N2", "N3"):
            a[("proposee", n, mode)] = (0, frozenset(), "critere")
        a[("proposee", "B6", mode)] = (0, frozenset(), "borne")
    a[("proposee", "F1", "dir")] = (1, frozenset({ID_CHEMIN}), "critere")
    a[("proposee", "F1", "git")] = (0, frozenset(), "borne")
    return a


def attentes_actuelle() -> dict[Cle, tuple[int, frozenset[str], str]]:
    a: dict[Cle, tuple[int, frozenset[str], str]] = {}
    for mode in ("dir", "git"):
        a[("actuelle", "F1", mode)] = (0, frozenset(), "controle")
        a[("actuelle", "F2", mode)] = (1, frozenset({ID_GENERIQUE}), "controle")
        a[("actuelle", "F3", mode)] = (1, frozenset({ID_GENERIQUE}), "controle")
        a[("actuelle", "F4", mode)] = (0, frozenset(), "controle")
        a[("actuelle", "N1", mode)] = (0, frozenset(), "controle")
    return a


# ---------------------------------------------------------------------------
# Execution de gitleaks, lue par son rapport
# ---------------------------------------------------------------------------
def resoudre_gitleaks() -> list[str]:
    g = shutil.which("gitleaks")
    if not g:
        raise NeConclutPas("gitleaks introuvable dans le PATH")
    return [g]


def lancer(gitleaks: list[str], mode: str, cible: Path, config: Path, travail: Path) -> tuple[int, frozenset[str]]:
    rapport = travail / ("rapport_%s.json" % secrets.token_hex(6))
    cmd = gitleaks + [mode, str(cible), "--config", str(config), "--no-banner", "--no-color",
                      "--redact", "--log-level", "error", "--report-format", "json",
                      "--report-path", str(rapport)]
    try:
        r = subprocess.run(cmd, cwd=str(travail), capture_output=True, timeout=600)
    except FileNotFoundError as e:
        raise NeConclutPas("gitleaks introuvable : %s" % type(e).__name__) from e
    except subprocess.TimeoutExpired as e:
        raise Defaut("gitleaks n'a pas rendu dans le delai") from e
    try:
        trouve = json.loads(rapport.read_text(encoding="utf-8")) if rapport.is_file() else None
    except ValueError:
        trouve = None
    finally:
        if rapport.exists():
            rapport.unlink()
    if r.returncode == 0 and trouve == []:
        return 0, frozenset()
    if r.returncode == 1 and isinstance(trouve, list) and trouve:
        return 1, frozenset(str(f.get("RuleID")) for f in trouve)
    raise Defaut("gitleaks a rendu %s sans rapport coherent (configuration illisible ?)" % r.returncode)


def _git(d: Path, vide: Path, *args: str) -> None:
    git = shutil.which("git")
    if not git:
        raise NeConclutPas("git introuvable")
    subprocess.run([git, "-c", "core.hooksPath=" + str(vide), "-c", "commit.gpgsign=false",
                    "-c", "core.autocrlf=false", "-c", "user.name=fictif",
                    "-c", "user.email=fictif@invalid", "-C", str(d), *args],
                   check=True, capture_output=True)


def _rmtree(p: Path) -> None:
    def forcer(fn: Callable[..., object], chemin: str, _exc: object) -> None:
        os.chmod(chemin, stat.S_IWRITE)
        fn(chemin)
    if p.exists():
        shutil.rmtree(p, onexc=forcer)


@dataclass
class Banc:
    travail: Path
    cibles: dict[tuple[str, str], Path]  # (fixture, mode) -> chemin


def hors_depot(travail: Path) -> Path:
    if RACINE in travail.resolve().parents or travail.resolve() == RACINE:
        raise Defaut("le repertoire temporaire est DANS le depot : refus")
    return travail


def preparer(fx: list[Fixture], travail: Path) -> Banc:
    hors_depot(travail)
    vide = travail / "sans_crochets"
    vide.mkdir()
    cibles: dict[tuple[str, str], Path] = {}
    for f in fx:
        for mode in ("dir", "git"):
            d = travail / f.nom / mode
            for rel, contenu in f.fichiers.items():
                p = d / rel
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_bytes(contenu)
            if mode == "git":
                _git(d, vide, "init", "-q")
                _git(d, vide, "add", "-A")
                _git(d, vide, "commit", "-q", "-m", "fixture factice")
            cibles[(f.nom, mode)] = d
    return Banc(travail, cibles)


def evaluer(gitleaks: list[str], banc: Banc, configs: dict[str, Path],
            attentes: dict[Cle, tuple[int, frozenset[str], str]]) -> tuple[set[Cle], dict[Cle, tuple[int, frozenset[str]]]]:
    obtenus: dict[Cle, tuple[int, frozenset[str]]] = {}
    ecarts: set[Cle] = set()
    for cle, (code, regles, _nature) in sorted(attentes.items()):
        conf, fixture, mode = cle
        o = lancer(gitleaks, mode, banc.cibles[(fixture, mode)], configs[conf], banc.travail)
        obtenus[cle] = o
        if o[0] != code or not regles <= o[1]:
            ecarts.add(cle)
    return ecarts, obtenus


# ---------------------------------------------------------------------------
# Conservation des regles actuelles (structure TOML, jamais le texte)
# ---------------------------------------------------------------------------
def regles_perdues(actuelle: str, proposee: str) -> list[str]:
    try:
        a = tomllib.loads(actuelle)
        p = tomllib.loads(proposee)
    except tomllib.TOMLDecodeError as e:
        raise Defaut("configuration TOML illisible : %s" % e) from e
    perdu: list[str] = []
    rp = {r.get("id"): r for r in p.get("rules", [])}
    for r in a.get("rules", []):
        if rp.get(r.get("id")) != r:
            perdu.append("regle %s" % r.get("id"))
    if p.get("extend") != a.get("extend"):
        perdu.append("[extend]")
    if p.get("allowlist") != a.get("allowlist"):
        perdu.append("[allowlist]")
    for nouvelle in (ID_CHEMIN, ID_PROPRIETES, ID_SCRIPT):
        if nouvelle not in rp:
            perdu.append("regle T4 absente : %s" % nouvelle)
    return perdu


# ---------------------------------------------------------------------------
# Execution principale
# ---------------------------------------------------------------------------
def _ligne(cle: Cle, attendu: tuple[int, frozenset[str], str], obtenu: tuple[int, frozenset[str]] | None,
           ecart: bool) -> str:
    conf, fixture, mode = cle
    regles = ",".join(sorted(obtenu[1])) if obtenu and obtenu[1] else "-"
    etat = "ECART" if ecart else ("BORNE" if attendu[2] == "borne" else "ok")
    return "  %-5s %-8s %-4s %-3s attendu exit %d, obtenu exit %s  regles: %s" % (
        etat, conf, fixture, mode, attendu[0], obtenu[0] if obtenu else "?", regles)


def executer(apres: bool) -> int:
    print("Critere T4 d'US-01.3 -- regles gitleaks de la signature mobile")
    print("Mode : %s" % ("APRES application (.gitleaks.toml = proposee)" if apres else
                         "AVANT application (controle negatif C-11 sur .gitleaks.toml)"))
    gitleaks = resoudre_gitleaks()
    v = subprocess.run(gitleaks + ["version"], capture_output=True, text=True)
    print("gitleaks version : %s" % v.stdout.strip())
    keytool = resoudre_keytool()
    print("keytool : %s" % ("JBR d'Android Studio" if keytool == KEYTOOL_JBR else "jdk-dir de flutter config"))

    txt_a = (RACINE / ACTUELLE).read_text(encoding="utf-8")
    txt_p = (RACINE / PROPOSEE).read_text(encoding="utf-8")
    meme = txt_a.replace("\r\n", "\n") == txt_p.replace("\r\n", "\n")
    ecarts_globaux: list[str] = []
    if apres and not meme:
        ecarts_globaux.append(".gitleaks.toml n'est PAS identique a la proposition : application incomplete")
    if not apres and meme:
        ecarts_globaux.append(".gitleaks.toml est DEJA la proposition : relancer avec --apres-application")
    perdu = regles_perdues(txt_a, txt_p) if not meme else []
    for p in perdu:
        ecarts_globaux.append("la proposition ne conserve pas : %s" % p)
    print("Conservation des regles actuelles : %s" % ("identique (appliquee)" if meme else
                                                       ("OK" if not perdu else "ECART")))

    travail = Path(tempfile.mkdtemp(prefix="t4_gitleaks_"))
    try:
        banc = preparer(fixtures(keytool, hors_depot(travail)), travail)
        config_t4 = (RACINE / ACTUELLE) if apres else (RACINE / PROPOSEE)
        attentes = attentes_proposee()
        configs = {"proposee": config_t4}
        if not apres:
            attentes.update(attentes_actuelle())
            configs["actuelle"] = RACINE / ACTUELLE
        ecarts, obtenus = evaluer(gitleaks, banc, configs, attentes)
    finally:
        _rmtree(travail)
    print("Fixtures factices : generees hors du depot, puis DETRUITES (%s)" %
          ("repertoire supprime" if not travail.exists() else "⛔ RESTE SUR DISQUE"))
    if travail.exists():
        ecarts_globaux.append("le repertoire temporaire des fixtures n'a pas ete detruit")
    print("Resultats (config %s) :" % (".gitleaks.toml" if apres else "proposee + actuelle"))
    for cle in sorted(attentes):
        print(_ligne(cle, attentes[cle], obtenus.get(cle), cle in ecarts))

    print("Depot reel avec la configuration %s :" % ("appliquee" if apres else "proposee"))
    travail2 = Path(tempfile.mkdtemp(prefix="t4_depot_"))
    try:
        hist = lancer(gitleaks, "git", RACINE, config_t4, travail2)
        rep = lancer(gitleaks, "dir", RACINE / PORTEE_DIR, config_t4, travail2)
    finally:
        _rmtree(travail2)
    for nom, o in (("historique complet (mode git)", hist), ("reports/US-01.3 (mode dir)", rep)):
        print("  %-5s %-32s exit %d  regles: %s" % ("ok" if o[0] == 0 else "ECART", nom, o[0],
                                                     ",".join(sorted(o[1])) or "-"))
        if o[0] != 0:
            ecarts_globaux.append("la configuration rend un constat sur le depot reel : %s" % nom)

    for e in ecarts_globaux:
        print("ECART : " + e)
    n = len(ecarts) + len(ecarts_globaux)
    print("Verdict : %s (%d attente(s) non tenue(s))" % ("CONFORME" if n == 0 else "ECART", n))
    return CONFORME if n == 0 else ECART


# ---------------------------------------------------------------------------
# AUTOTEST DE MUTATION -- mutants STRUCTURELS de la configuration (bloc de regle
# retire, allowlist universelle, regle additionnelle sans condition, syntaxe
# cassee, regle d'origine retiree) et de l'outil (gitleaks absent, gitleaks sans
# rapport). Ecarts attendus compares en ENSEMBLES de cles, jamais en cardinaux.
# ---------------------------------------------------------------------------
def retirer_bloc(txt: str, ident: str) -> str:
    blocs = re.split(r"(?m)^(?=\[\[rules\]\]|\[allowlist\])", txt)
    garde = [b for b in blocs if not re.search(r'(?m)^id = "%s"$' % re.escape(ident), b)]
    if len(garde) != len(blocs) - 1:
        raise Defaut("mutant : bloc %s introuvable" % ident)
    return "".join(garde)


def selftest() -> int:
    echecs: list[str] = []
    tues = 0
    gitleaks = resoudre_gitleaks()
    keytool = resoudre_keytool()
    txt_p = (RACINE / PROPOSEE).read_text(encoding="utf-8")
    # Configuration « d'avant T4 » RECONSTRUITE depuis la proposition (les trois blocs T4
    # retires), et NON lue dans .gitleaks.toml : l'autotest reste jouable APRES application.
    # Avant application, elle doit conserver les memes regles que .gitleaks.toml.
    txt_a = txt_p
    for ident in (ID_CHEMIN, ID_PROPRIETES, ID_SCRIPT):
        txt_a = retirer_bloc(txt_a, ident)
    reel = (RACINE / ACTUELLE).read_text(encoding="utf-8")
    if reel.replace("\r\n", "\n") != txt_p.replace("\r\n", "\n"):
        attendu_reconstruit = ["regle T4 absente : %s" % i for i in (ID_CHEMIN, ID_PROPRIETES, ID_SCRIPT)]
        if regles_perdues(reel, txt_a) != attendu_reconstruit:
            print("  ECHEC la configuration reconstruite ne porte pas les regles de .gitleaks.toml")
            return DEFAUT
    att_p = attentes_proposee()
    att_a = attentes_actuelle()
    travail = Path(tempfile.mkdtemp(prefix="t4_selftest_"))
    try:
        banc = preparer(fixtures(keytool, hors_depot(travail)), travail)

        def conf(nom: str, txt: str) -> Path:
            p = travail / (re.sub(r"[^A-Za-z0-9]+", "_", nom) + ".toml")  # « : » = flux NTFS
            p.write_text(txt, encoding="utf-8")
            return p

        def cles(attentes: dict[Cle, tuple[int, frozenset[str], str]], conf_nom: str,
                 fixtures_: set[str], modes: set[str]) -> set[Cle]:
            return {c for c in attentes if c[0] == conf_nom and c[1] in fixtures_ and c[2] in modes}

        def verifier(nom: str, txt: str, attendu: set[Cle], base: str = "proposee") -> None:
            nonlocal tues
            att = att_p if base == "proposee" else att_a
            ecarts, _ = evaluer(gitleaks, banc, {base: conf(nom, txt)}, att)
            if ecarts == attendu:
                if attendu:
                    tues += 1
                print("  ok    %-44s ecarts = attendus (%d cle(s))" % (nom, len(attendu)))
            else:
                echecs.append(nom)
                print("  ECHEC %-44s en trop %s, manquants %s" % (
                    nom, sorted(ecarts - attendu), sorted(attendu - ecarts)))

        dg = {"dir", "git"}
        positifs = {c for c, v in att_p.items() if v[0] == 1}
        print("Autotest : temoins")
        verifier("T-P proposee intacte", txt_p, set())
        verifier("T-A actuelle intacte (controle C-11)", txt_a, set(), base="actuelle")
        print("Autotest : mutants de configuration")
        verifier("M1 bloc de regle de chemin retire", retirer_bloc(txt_p, ID_CHEMIN),
                 {("proposee", "F1", "dir"), ("proposee", "F1A", "dir"), ("proposee", "F1A", "git")})
        verifier("M2 bloc de regle proprietes retire", retirer_bloc(txt_p, ID_PROPRIETES),
                 cles(att_p, "proposee", {"F2", "F4"}, dg))
        verifier("M3 bloc de regle script retire", retirer_bloc(txt_p, ID_SCRIPT),
                 cles(att_p, "proposee", {"F3", "F5"}, dg))
        verifier("M4 allowlist universelle de chemins",
                 txt_p.replace("paths = [\n", "paths = [\n  '''.*''',\n", 1), positifs)
        regle_sans_condition = ('\n[[rules]]\nid = "mutant"\ndescription = "mutant"\n'
                                "path = '''(?i)\\.properties$'''\nregex = '''\\S+'''\n")
        i = txt_p.index("[allowlist]")
        verifier("M5 regle additionnelle sans condition",
                 txt_p[:i] + regle_sans_condition + "\n" + txt_p[i:],
                 cles(att_p, "proposee", {"N1", "N2", "B6"}, dg))
        verifier("M6 controle negatif : actuelle + regle de chemin",
                 txt_a.replace("[allowlist]", "[[rules]]\nid = \"%s\"\ndescription = \"m\"\n"
                               "path = '''(?i)\\.jks$'''\n\n[allowlist]" % ID_CHEMIN, 1),
                 {("actuelle", "F1", "dir")}, base="actuelle")
        print("Autotest : mutants de l'instrument")
        try:
            evaluer(gitleaks, banc, {"proposee": conf("m7", txt_p + "\n[[rules]]\nid = '''")}, att_p)
            echecs.append("M7 syntaxe cassee")
            print("  ECHEC M7 syntaxe cassee : aucun DEFAUT leve")
        except Defaut:
            tues += 1
            print("  ok    M7 syntaxe cassee                           -> DEFAUT (3), jamais un constat")
        stub = travail / "faux_gitleaks.py"
        stub.write_text("import sys\nsys.exit(1)\n", encoding="utf-8")
        try:
            lancer([sys.executable, str(stub)], "dir", banc.cibles[("F1", "dir")], conf("m8", txt_p), travail)
            echecs.append("M8 exit 1 sans rapport")
            print("  ECHEC M8 exit 1 sans rapport : pris pour un constat")
        except Defaut:
            tues += 1
            print("  ok    M8 gitleaks rend 1 sans rapport               -> DEFAUT (3), jamais un constat")
        try:
            lancer([str(travail / "absent" / "gitleaks.exe")], "dir", banc.cibles[("F1", "dir")],
                   conf("m9", txt_p), travail)
            echecs.append("M9 gitleaks absent")
            print("  ECHEC M9 gitleaks absent : aucune exception")
        except NeConclutPas:
            tues += 1
            print("  ok    M9 gitleaks absent                            -> NE CONCLUT PAS (2), jamais un vert")
        perdu = regles_perdues(txt_a, retirer_bloc(txt_p, "stitch-token-aq"))
        if perdu == ["regle stitch-token-aq"]:
            tues += 1
            print("  ok    M10 regle d'origine retiree de la proposition -> nommee : %s" % perdu)
        else:
            echecs.append("M10 regle d'origine retiree")
            print("  ECHEC M10 regle d'origine retiree : %s" % perdu)
        perdu = regles_perdues(txt_a, txt_p.replace("'''changeme''',", "", 1))
        if perdu == ["[allowlist]"]:
            tues += 1
            print("  ok    M11 allowlist d'origine alteree               -> nommee : %s" % perdu)
        else:
            echecs.append("M11 allowlist alteree")
            print("  ECHEC M11 allowlist alteree : %s" % perdu)
    finally:
        _rmtree(travail)
    if travail.exists():
        echecs.append("repertoire temporaire non detruit")
    print("Autotest : %d mutant(s) tue(s), %d echec(s)" % (tues, len(echecs)))
    return CONFORME if not echecs else DEFAUT


def main(argv: list[str]) -> int:
    os.chdir(RACINE)
    if argv not in ([], ["--apres-application"], ["--selftest"]):
        print("Argument inconnu : %s" % " ".join(argv))
        print(__doc__.split("USAGE ET CODES DE SORTIE")[1].split("Aucun mot")[0])
        return DEFAUT
    try:
        if argv == ["--selftest"]:
            return selftest()
        return executer(argv == ["--apres-application"])
    except NeConclutPas as e:
        print("NE CONCLUT PAS : %s. Rien n'a ete etabli -- ce n'est pas un vert." % e)
        return NE_CONCLUT_PAS
    except Defaut as e:
        print("DEFAUT DE L'INSTRUMENT : %s" % e)
        return DEFAUT
    except subprocess.CalledProcessError as e:
        print("DEFAUT DE L'INSTRUMENT : commande en echec (exit %s)" % e.returncode)
        return DEFAUT
    except Exception as e:  # jamais une trace brute (chemins du poste), jamais le code 1
        print("DEFAUT DE L'INSTRUMENT : %s" % type(e).__name__)
        return DEFAUT


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
