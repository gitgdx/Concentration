#!/usr/bin/env python3
"""
AUTOTEST du cliquet de couverture — US-00.6.

⛔ CE SCRIPT EXISTE POUR PROUVER QUE `check_flutter_coverage.py` EST CAPABLE DE REFUSER.
   « Un contrôle qui ne peut pas rougir est nul » : leçon centrale d'US-00.5, et elle y a été
   MESURÉE — sur six instruments de contrôle, un contrôle PORTANT SON MUTANT a été juste
   7 fois sur 7, un contrôle purement lexical faux 7 fois sur 7.

Il tourne dans le job CI DÉJÀ REQUIS « 📋 Governance » (arbitrage C-3 d'US-00.6). Le laisser
« à lancer à la main » aurait recréé à l'identique la dette du `selftest` de
`check_branch_protection.py`, que le projet traîne, non exécutée, depuis US-00.4.

⚠️ CONTREPARTIE ASSUMÉE : une fixture cassée verrouille toute PR. Ce risque est AUTO-RÉVÉLATEUR,
   à la différence d'un contrôle qui dort.

Usage : python scripts/selftest_coverage_ratchet.py
Exit   : 0 si TOUTES les attentes declarees dans CAS sont tenues, 1 sinon.
         (PERIME-2026-07-31 : cette ligne disait « les 4 attentes » — chiffre RECOPIE, perime des
          l ajout de la 5e puis de la 6e. Le nombre est DERIVE de CAS et imprime a l execution.)
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

# Meme garde que dans check_flutter_coverage.py : un controle ne doit jamais planter
# sur son propre message. Voir le bug du 2026-07-31, trouve par CE script.
for _flux in (sys.stdout, sys.stderr):
    try:
        _flux.reconfigure(errors="replace")
    except (AttributeError, ValueError):
        pass

FIXTURES = Path("tests/fixtures/US-00.6")
CHECKER = Path("scripts/check_flutter_coverage.py")

# Référence utilisée pour l'autotest. ⛔ Ce n'est PAS le seuil du projet : c'est le
# paramètre du MUTANT. Le seuil du projet vit dans factory.config.json, source unique.
#
# ⛔ CORRECTIF B-QA-2 (QA, 2026-07-31) : cette valeur VALAIT LE SEUIL DU PROJET (89.4), si bien
#    que le mutant « cliquet ecrit EN DUR dans le checker » SURVIVAIT a l autotest — la QA l a
#    mesure : le jour ou un developpeur figerait le seuil, LA CI RESTERAIT VERTE.
#    Deux remedes cumules :
#      1. REF_MUTANT est desormais DISTINCTE du seuil du projet ;
#      2. un CONTROLE DIFFERENTIEL (voir CAS_DIFFERENTIEL) rejoue LA MEME fixture avec DEUX
#         references et EXIGE que le verdict CHANGE. Un checker qui figerait sa valeur rendrait
#         le MEME verdict pour les deux => l autotest rougit. C est la seule facon de prouver
#         qu une valeur est LUE et non ecrite : la comparer a elle-meme ne prouve rien.
REF_MUTANT = 86.0
PLANCHER = 80.0

# Controle DIFFERENTIEL : (fixture, reference BASSE, reference HAUTE, exit attendu bas, haut).
# La fixture 17/19 = 89,47 % doit PASSER sous une reference basse et ECHOUER sous une haute.
CAS_DIFFERENTIEL = ("inchange_17_sur_19.info", 86.0, 95.0, 0, 1)

# (fixture, exit attendu, ce que le cas prouve)
CAS = [
    ("regression_16_sur_19.info", 1, "REGRESSION refusee — ce cas passait VERT avant US-00.6"),
    ("inchange_17_sur_19.info", 0, "depot INCHANGE accepte — aucun rouge indu, pas de verrouillage"),
    ("hausse_18_sur_19.info", 0, "HAUSSE acceptee, valeur a consigner imprimee"),
    ("zero_ligne_mesurable.info", 1, "0 ligne mesurable REFUSE — un vert par vide est un mensonge"),
    # 5e cas AJOUTE le 2026-07-31 apres le finding B-1 de l audit de revue : un rapport dont les
    # totaux DECLARES contredisent les lignes COMPTEES rendait « 100.0% », exit 0, et proposait
    # de consigner 100.0 — donc le VERROUILLAGE du depot. Le mutant qui l a trouve n avait ete
    # ecrit par personne : c est l auditeur qui l a fabrique. Il est desormais DANS le jeu.
    ("totaux_incoherents.info", 1, "totaux DECLARES contredisant les lignes COMPTEES : REFUSE (B-1)"),
    # 6e cas AJOUTE le 2026-07-31 (finding RA-2 du re-audit) : la fixture de B-1 ne mentait que sur
    # LH, si bien que la branche LF du recoupement — LE DENOMINATEUR — n avait AUCUN mutant. Le code
    # refusait bien : c est la FIXTURE qui manquait. Un controle non exerce n est pas un controle prouve.
    ("lf_menteur.info", 1, "LF menteur (le DENOMINATEUR) : REFUSE — branche LF desormais exercee (RA-2)"),
]


def run(lcov: Path, config: Path) -> tuple[int, str]:
    proc = subprocess.run(
        [sys.executable, str(CHECKER), "--min", str(PLANCHER), "--lcov", str(lcov), "--config", str(config)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


def main() -> int:
    print("=" * 79)
    print(" AUTOTEST DU CLIQUET — il prouve que le controle sait REFUSER")
    print("=" * 79)

    if not CHECKER.exists():
        print(f"[ERREUR] {CHECKER} introuvable.")
        return 1

    manquantes = [c[0] for c in CAS if not (FIXTURES / c[0]).exists()]
    if manquantes:
        print(f"[ERREUR] fixtures manquantes : {', '.join(manquantes)}")
        return 1

    # Configuration TEMPORAIRE portant la reference du mutant. On ne touche jamais
    # factory.config.json : il est PROTEGE, et l autotest ne doit dependre d aucune
    # edition humaine pour etre executable.
    with tempfile.TemporaryDirectory() as tmp:
        cfg = Path(tmp) / "config_mutant.json"
        cfg.write_text(
            json.dumps(
                {
                    "adapter": {
                        "components": {
                            "app": {
                                "coverage_ratchet": {
                                    "value": REF_MUTANT,
                                    "date": "autotest",
                                    "motif": "reference du MUTANT, jamais le seuil du projet",
                                }
                            }
                        }
                    }
                }
            ),
            encoding="utf-8",
        )

        echecs = 0
        for fixture, attendu, propos in CAS:
            code, sortie = run(FIXTURES / fixture, cfg)
            ok = code == attendu
            print(f"  {'OK    ' if ok else 'ECHEC '}| {fixture:<28} exit attendu={attendu} obtenu={code}")
            print(f"         | {propos}")
            if not ok:
                echecs += 1
                for ligne in sortie.strip().splitlines():
                    print(f"         > {ligne}")

    # --- CONTROLE DIFFERENTIEL (B-QA-2) : tue le mutant « cliquet ecrit en dur ».
    fixture_d, ref_basse, ref_haute, att_bas, att_haut = CAS_DIFFERENTIEL
    with tempfile.TemporaryDirectory() as tmp2:
        codes = []
        for ref in (ref_basse, ref_haute):
            cfg2 = Path(tmp2) / ("cfg_%s.json" % ref)
            cfg2.write_text(
                json.dumps({"adapter": {"components": {"app": {"coverage_ratchet": {
                    "value": ref, "date": "autotest-differentiel",
                    "motif": "prouve que la reference est LUE et non ecrite"}}}}}),
                encoding="utf-8",
            )
            code, _ = run(FIXTURES / fixture_d, cfg2)
            codes.append(code)
        ok_d = codes == [att_bas, att_haut]
        print(f"  {'OK    ' if ok_d else 'ECHEC '}| DIFFERENTIEL {fixture_d:<15} "
              f"ref {ref_basse} -> exit {codes[0]} (attendu {att_bas}) | "
              f"ref {ref_haute} -> exit {codes[1]} (attendu {att_haut})")
        print("         | la MEME fixture change de verdict => la reference est LUE, jamais ecrite en dur")
        if not ok_d:
            echecs += 1

    print("-" * 79)
    if echecs:
        print(f" RESULTAT : {echecs} attente(s) NON tenue(s) — le cliquet ne fait pas ce qu il annonce.")
        return 1
    print(f" RESULTAT : les {len(CAS)} attentes sont tenues, dont {sum(1 for c in CAS if c[1] == 1)} REFUS.")
    print(" [BORNE] Ce qu il ne prouve PAS : ni l authenticite du rapport lcov, ni la qualite des tests.")
    print("    Un cliquet n ameliore pas les tests — il empeche seulement de reculer.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
