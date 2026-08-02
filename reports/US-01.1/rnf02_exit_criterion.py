#!/usr/bin/env python3
"""Critere de LEVEE, executable, d'AC-1 << Limite >> / RNF-02 -- @QA_Tester.

Commit de reference : 558a47592651d6c4384a519fab2dceee390e74d9 (558a475).

POURQUOI CE FICHIER EXISTE
--------------------------
Au 1er passage, la QA a declare AC-1 << Limite >> NON VERIFIE et a RECOMMANDE
sans trancher : la decision de reporter un AC appartient au @PO / @Architect,
pas a la QA. Trois auditeurs l'ont laisse ouvert (N-11) et -- c'est le point
important -- AUCUN VERT N'A JAMAIS ETE FABRIQUE DESSUS.

Lecon d'US-00.7 : << un critere de sortie se publie comme un SCRIPT
EXECUTABLE, jamais recopie a la main >>. Ce fichier ne demande donc rien : il
DIT, par execution, si RNF-02 est mesurable, avec quel instrument, sur quelle
cible, et contre quel seuil -- puis il mesure si on le lui permet.

CE QUI EST MESURE, ET CE QUI NE L'EST PAS
-----------------------------------------
RNF-02 parle de L'OUVERTURE de l'application. Le harnais `flutter_test` est
HEADLESS : il mesure `build + layout` du premier frame et EXCLUT le demarrage
du moteur, l'init de la VM, le chargement des polices, la compilation des
shaders et la RASTERISATION. Une mesure faite la est une BORNE INFERIEURE,
jamais la valeur de l'AC. C'est pourquoi ce script n'accepte QUE la mesure
`--trace-startup`, qui produit `build/start_up_info.json` sur un APPAREIL.

LES TROIS INCONNUES QUE @PO / @Architect DOIVENT FIXER (et que ce script
refuse de deviner a leur place)
------------------------------------------------------------------------
1. INSTRUMENT : `flutter run --profile --trace-startup` ->
   `build/start_up_info.json`, cle `timeToFirstFrameRasterizedMicros`.
   C'est le seul chiffre du toolchain qui couvre << l'ouverture >> au sens de
   l'AC (jusqu'au premier frame RASTERISE, donc reellement visible).
2. SEUIL : il n'est PAS ecrit dans ce script. Il est LU dans le Story File --
   une regle n'existe qu'en UN SEUL EXEMPLAIRE. Si la phrase disparait ou
   change de forme, ce script ECHOUE au lieu de se blanchir en silence.
3. CIBLE : aucune valeur par defaut. `--device` est OBLIGATOIRE pour mesurer.
   << 500 ms >> n'a de sens que sur une machine nommee ; mesurer sur ce qui
   traine et appeler ca RNF-02 serait un faux vert de plus.

CODES DE SORTIE (le mode par defaut est le DIAGNOSTIC, il ne lance rien)
-----------------------------------------------------------------------
    0 -> LEVE           : mesure effectuee sur la cible, sous le seuil.
    1 -> NON LEVE       : mesure effectuee, seuil DEPASSE.
    2 -> NON MESURABLE  : l'instrument n'est pas disponible ici. Le rapport
                          nomme exactement ce qui manque. ATTENTION : 2 n'est
                          PAS un echec du produit, et surtout PAS un succes.
    3 -> DEFAUT DE L'INSTRUMENT : le seuil n'a pas pu etre lu dans le Story
                          File, ou le fichier de mesure est illisible.

USAGE
-----
    python reports/US-01.1/rnf02_exit_criterion.py --selftest
    python reports/US-01.1/rnf02_exit_criterion.py                # diagnostic
    python reports/US-01.1/rnf02_exit_criterion.py --mesurer --device <id>
"""

from __future__ import annotations

import argparse
import io
import json
import os
import re
import subprocess
import sys

sys.stdout.reconfigure(encoding="ascii", errors="replace")

DEPOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
STORY = os.path.join(DEPOT, "docs", "stories", "US-01.1-affichage-hub-grille.md")
START_UP_INFO = os.path.join(DEPOT, "build", "start_up_info.json")

# La cle du toolchain qui porte << l'ouverture >> au sens de l'AC : premier
# frame RASTERISE, donc reellement visible a l'ecran. `EngineEnterTimestamp`
# et `timeToFirstFrameMicros` mesurent MOINS que ce que l'AC exige.
CLE_MESURE = "timeToFirstFrameRasterizedMicros"

# Le seuil se LIT, il ne s'ecrit pas. Le motif designe la phrase par son
# TEXTE, jamais par un numero de ligne (lecon d'US-00.7 : un numero glisse en
# silence et la couverture cesse de couvrir sans qu'aucun outil ne le dise).
MOTIF_SEUIL = re.compile(
    r"pr[eê]t au regard\s*[^.]*?moins de\s*(\d+)\s*ms", re.IGNORECASE
)

# Une plateforme n'est lancable que si son DOSSIER RUNNER existe dans le
# depot. Le creer (`flutter create --platforms=...`) modifierait le produit :
# hors du perimetre d'ecriture de la QA (reports/ et docs/trace/ seulement).
RUNNER_PAR_PLATEFORME = {
    "android": "android",
    "ios": "ios",
    "web-javascript": "web",
    "windows-x64": "windows",
    "linux-x64": "linux",
    "darwin": "macos",
}

# La cible du PRODUIT. Mesurer RNF-02 ailleurs ne leve pas l'AC : cela
# produirait un chiffre vrai sur une machine qui n'est pas celle de
# l'utilisateur. C'est une constatation, pas un arbitrage -- l'arbitrage
# (accepter une cible de substitution) appartient au @PO / @Architect.
PLATEFORMES_CIBLES = {"android", "ios"}


def lire_seuil_ms() -> int:
    """Lit le seuil DANS le Story File. Un motif introuvable est un ECHEC."""
    if not os.path.exists(STORY):
        raise LookupError("Story File introuvable : %s" % STORY)
    texte = io.open(STORY, encoding="utf-8").read()
    trouves = {int(m) for m in MOTIF_SEUIL.findall(texte)}
    if not trouves:
        raise LookupError(
            "le seuil RNF-02 est INTROUVABLE dans le Story File. Un seuil que "
            "l'on ne sait plus lire ne doit JAMAIS valoir succes."
        )
    if len(trouves) > 1:
        raise LookupError(
            "le Story File porte %d seuils differents (%s) : une regle "
            "n'existe qu'en UN SEUL EXEMPLAIRE." % (len(trouves), sorted(trouves))
        )
    return trouves.pop()


def verdict(mesure_us: int, seuil_ms: int) -> str:
    """LEVE si la mesure est STRICTEMENT sous le seuil. << moins de 500 ms >>."""
    return "LEVE" if mesure_us < seuil_ms * 1000 else "NON LEVE"


def lire_mesure(chemin: str) -> int:
    donnees = json.loads(io.open(chemin, encoding="utf-8").read())
    if CLE_MESURE not in donnees:
        raise LookupError(
            "la cle %s est absente de %s : cles presentes = %s"
            % (CLE_MESURE, chemin, sorted(donnees))
        )
    return int(donnees[CLE_MESURE])


def appareils() -> list[dict]:
    p = subprocess.run(
        ["flutter", "devices", "--machine"],
        cwd=DEPOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        shell=True,
    )
    debut = (p.stdout or "").find("[")
    if debut < 0:
        return []
    try:
        return json.loads(p.stdout[debut:])
    except ValueError:
        return []


def diagnostic(seuil_ms: int) -> int:
    print("RNF-02 -- AC-1 << Limite >> : << pret au regard >> en moins de %d ms" % seuil_ms)
    print("Seuil LU dans %s (jamais ecrit ici)." % os.path.relpath(STORY, DEPOT))
    print("Instrument exige : flutter run --profile --trace-startup")
    print("                   -> build/start_up_info.json [%s]" % CLE_MESURE)
    print()
    liste = appareils()
    if not liste:
        print("Aucun appareil detecte -> NON MESURABLE.")
        return 2

    print("Appareils detectes (%d) :" % len(liste))
    lancables = []
    for d in liste:
        ident = d.get("id", "?")
        plateforme = d.get("targetPlatform", "?")
        runner = RUNNER_PAR_PLATEFORME.get(plateforme)
        a_runner = bool(runner) and os.path.isdir(os.path.join(DEPOT, runner))
        est_cible = runner in PLATEFORMES_CIBLES
        raisons = []
        if not a_runner:
            raisons.append(
                "dossier runner '%s/' ABSENT du depot (le creer modifierait le "
                "produit : hors perimetre QA)" % (runner or plateforme)
            )
        if not est_cible:
            raisons.append(
                "plateforme '%s' n'est PAS la cible du produit (%s)"
                % (runner or plateforme, ", ".join(sorted(PLATEFORMES_CIBLES)))
            )
        etat = "LANCABLE ET PERTINENT" if not raisons else "ecarte"
        print("  - %-10s %-16s %s" % (ident, plateforme, etat))
        for r in raisons:
            print("        * %s" % r)
        if not raisons:
            lancables.append(ident)

    print()
    if lancables:
        print("MESURABLE. Relancer avec : --mesurer --device %s" % lancables[0])
        return 0
    print("NON MESURABLE ICI -- et ce n'est ni un succes ni un echec du produit.")
    print("CE QU'IL FAUT, EXACTEMENT, POUR LEVER AC-1 << Limite >> :")
    print("  (1) un appareil de la cible produit (%s) :" % ", ".join(sorted(PLATEFORMES_CIBLES)))
    print("      emulateur Android ou telephone physique -- exige un JDK")
    print("      (`flutter doctor` : << No Java Development Kit (JDK) found >>) ;")
    print("  (2) le dossier runner correspondant present dans le depot ;")
    print("  (3) ce script relance avec --mesurer --device <id> : il rendra")
    print("      exit 0 (sous %d ms) ou exit 1 (au-dessus). Aucune relecture," % seuil_ms)
    print("      aucune impression : un chiffre lu dans un fichier produit par")
    print("      le toolchain.")
    print()
    print("VOIE ALTERNATIVE, qui appartient au @PO / @Architect et PAS a la QA :")
    print("  reformuler RNF-02 en budget de `build + layout` du PREMIER FRAME,")
    print("  mesurable dans le harnais headless et donc PROTEGE par le gate")
    print("  `test`. ATTENTION : ce serait un AC DIFFERENT, plus faible -- il")
    print("  exclut moteur, VM, polices, shaders et rasterisation. L'ecrire")
    print("  serait honnete ; l'appeler << RNF-02 >> sans le dire ne le serait")
    print("  pas.")
    return 2


def mesurer(seuil_ms: int, device: str) -> int:
    if os.path.exists(START_UP_INFO):
        os.remove(START_UP_INFO)
    print("Mesure sur '%s' -- flutter run --profile --trace-startup" % device)
    p = subprocess.run(
        [
            "flutter", "run", "--profile", "--trace-startup",
            "-d", device, "--no-pub",
        ],
        cwd=DEPOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        shell=True,
        timeout=900,
    )
    if not os.path.exists(START_UP_INFO):
        print("[DEFAUT INSTRUMENT] %s n'a pas ete produit." % START_UP_INFO)
        print((p.stdout or "")[-2000:])
        print((p.stderr or "")[-2000:])
        return 3
    mesure = lire_mesure(START_UP_INFO)
    v = verdict(mesure, seuil_ms)
    print("%s = %d us (%.1f ms) | seuil %d ms -> %s"
          % (CLE_MESURE, mesure, mesure / 1000.0, seuil_ms, v))
    print("Mesure LUE dans %s, jamais recopiee." % os.path.relpath(START_UP_INFO, DEPOT))
    return 0 if v == "LEVE" else 1


def selftest() -> int:
    """Autotest de MUTATION de la logique PROPRE a ce script.

    Les mutants ne sont PAS tires du vocabulaire de la regle testee (pas de
    << 500 >>, pas de << ms >>) : un autotest qui reutilise les mots de sa
    regle ne mesure rien. Les resultats se comparent en ENSEMBLES, jamais en
    cardinaux (un decompte egal n'est pas une preuve d'equivalence).
    """
    echecs = 0

    # 1. La frontiere est STRICTE : << moins de >> exclut l'egalite.
    attendus = {
        (1, 999): "LEVE",
        (1, 1000): "NON LEVE",
        (1, 1001): "NON LEVE",
        (7, 6999): "LEVE",
        (7, 7000): "NON LEVE",
    }
    obtenus = {(s, m): verdict(m, s) for (s, m) in attendus}
    if obtenus != attendus:
        print("[ECHEC] verdict : %s != %s" % (obtenus, attendus))
        echecs += 1
    else:
        print("[OK] la frontiere est stricte sur %d cas" % len(attendus))

    # 2. Le seuil est LU dans le Story File, et il est unique.
    try:
        seuil = lire_seuil_ms()
        print("[OK] seuil lu dans le Story File : %d" % seuil)
    except LookupError as e:
        print("[ECHEC] %s" % e)
        echecs += 1
        seuil = None

    # 3. MUTATION DE CORPUS : un Story File d'ou la phrase est retiree doit
    #    faire ECHOUER la lecture, jamais la laisser rendre une valeur.
    global STORY
    original = STORY
    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        texte = io.open(original, encoding="utf-8").read()
        mute = MOTIF_SEUIL.sub("(phrase retiree par le mutant)", texte)
        faux = os.path.join(tmp, "mutant.md")
        io.open(faux, "w", encoding="utf-8").write(mute)
        STORY = faux
        try:
            v = lire_seuil_ms()
            print("[ECHEC] seuil INVENTE (%s) sur un corpus qui ne le porte plus" % v)
            echecs += 1
        except LookupError:
            print("[OK] phrase retiree -> ECHEC franc, pas de valeur inventee")

        # ...et un corpus qui en porte DEUX doit echouer aussi.
        io.open(faux, "w", encoding="utf-8").write(
            texte + "\n- **Limite** : pret au regard en moins de 42 ms.\n"
        )
        try:
            v = lire_seuil_ms()
            print("[ECHEC] deux seuils divergents acceptes -> %s" % v)
            echecs += 1
        except LookupError:
            print("[OK] deux seuils divergents -> ECHEC franc")
        STORY = original

    # 4. Une cle absente du fichier de mesure est un ECHEC, pas un zero.
    with tempfile.TemporaryDirectory() as tmp:
        f = os.path.join(tmp, "s.json")
        io.open(f, "w", encoding="utf-8").write(
            json.dumps({"engineEnterTimestampMicros": 111})
        )
        try:
            lire_mesure(f)
            print("[ECHEC] une mesure a ete rendue sans la cle exigee")
            echecs += 1
        except LookupError:
            print("[OK] cle de mesure absente -> ECHEC franc")
        io.open(f, "w", encoding="utf-8").write(json.dumps({CLE_MESURE: 123456}))
        if lire_mesure(f) != 123456:
            print("[ECHEC] la mesure n'est pas lue telle quelle")
            echecs += 1
        else:
            print("[OK] la mesure est lue telle quelle")

    # 5. CONTROLE NEGATIF : sans lui, un autotest qui echouerait sur TOUT
    #    passerait pour severe. Deux cas manifestement conformes DOIVENT
    #    passer -- l'un de chaque cote de la frontiere.
    #
    #    NB honnete : la 1re redaction de ce controle inversait les deux
    #    arguments (`verdict(mesure_us, seuil_ms)`) et l'autotest l'a REFUSE
    #    au premier lancement. C'est la classe de defaut recurrente du projet
    #    -- une valeur posee a la main a cote d'une commande -- cette fois
    #    dans l'instrument de mesure, et c'est le mutant qui l'a arretee.
    extremes = {
        # (mesure_us, seuil_ms) -> verdict attendu
        (1, 10**6): "LEVE",       # 1 us contre 1000 s : evidemment sous
        (10**9, 1): "NON LEVE",   # 1000 s contre 1 ms : evidemment au-dessus
    }
    obtenus_ex = {k: verdict(*k) for k in extremes}
    if obtenus_ex != extremes:
        print("[ECHEC] controle negatif : %s != %s" % (obtenus_ex, extremes))
        echecs += 1
    else:
        print("[OK] controle negatif : les 2 cas evidents se comportent bien")

    print("\nAutotest : %d echec(s)." % echecs)
    return 1 if echecs else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="Critere de levee de RNF-02.")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--mesurer", action="store_true")
    ap.add_argument("--device")
    a = ap.parse_args()

    if a.selftest:
        raise SystemExit(selftest())
    try:
        seuil = lire_seuil_ms()
    except LookupError as exc:
        print("[DEFAUT INSTRUMENT] %s" % exc)
        raise SystemExit(3)
    if a.mesurer:
        if not a.device:
            print("--device est OBLIGATOIRE : ce script ne devine pas la cible.")
            raise SystemExit(3)
        raise SystemExit(mesurer(seuil, a.device))
    raise SystemExit(diagnostic(seuil))
