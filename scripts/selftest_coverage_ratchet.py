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
Exit   : 0 si les 4 attentes sont tenues, 1 sinon.
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

FIXTURES = Path("tests/fixtures/US-00.6")
CHECKER = Path("scripts/check_flutter_coverage.py")

# Référence utilisée pour l'autotest. ⛔ Ce n'est PAS le seuil du projet : c'est le
# paramètre du MUTANT. Le seuil du projet vit dans factory.config.json, source unique.
REF_MUTANT = 89.4
PLANCHER = 80.0

# (fixture, exit attendu, ce que le cas prouve)
CAS = [
    ("regression_16_sur_19.info", 1, "REGRESSION refusee — ce cas passait VERT avant US-00.6"),
    ("inchange_17_sur_19.info", 0, "depot INCHANGE accepte — aucun rouge indu, pas de verrouillage"),
    ("hausse_18_sur_19.info", 0, "HAUSSE acceptee, valeur a consigner imprimee"),
    ("zero_ligne_mesurable.info", 1, "0 ligne mesurable REFUSE — un vert par vide est un mensonge"),
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

    print("-" * 79)
    if echecs:
        print(f" RESULTAT : {echecs} attente(s) NON tenue(s) — le cliquet ne fait pas ce qu il annonce.")
        return 1
    print(f" RESULTAT : les {len(CAS)} attentes sont tenues, dont {sum(1 for c in CAS if c[1] == 1)} REFUS.")
    print(" ⛔ Ce qu il ne prouve PAS : ni l authenticite du rapport lcov, ni la qualite des tests.")
    print("    Un cliquet n ameliore pas les tests — il empeche seulement de reculer.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
