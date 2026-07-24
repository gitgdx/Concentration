#!/usr/bin/env python3
"""
Vérifie le seuil de couverture de lignes à partir de coverage/lcov.info
(produit par `flutter test --coverage`).

`flutter test` n'a pas d'équivalent au `--cov-fail-under` de pytest ni aux
`thresholds` de Vitest — ce script comble ce manque, spécifique à l'adapter
`flutter` (voir gate `app.test` dans factory.config.json).

Usage :
  python scripts/check_flutter_coverage.py --min 80 [--lcov coverage/lcov.info]
"""
import argparse
import sys
from pathlib import Path


def line_coverage_percent(lcov_path: Path) -> tuple[float, int, int]:
    covered = 0
    total = 0
    for line in lcov_path.read_text(encoding="utf-8").splitlines():
        if line.startswith("DA:"):
            _, _, hits = line.partition(":")[2].partition(",")
            total += 1
            if int(hits) > 0:
                covered += 1
    pct = (covered / total * 100) if total else 0.0
    return pct, covered, total


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--min", type=float, required=True, help="Seuil minimal de couverture de lignes (%%)")
    parser.add_argument("--lcov", default="coverage/lcov.info", help="Chemin du rapport lcov")
    args = parser.parse_args()

    lcov_path = Path(args.lcov)
    if not lcov_path.exists():
        print(f"[ERREUR] {lcov_path} introuvable — lancer `flutter test --coverage` avant ce script.")
        return 1

    pct, covered, total = line_coverage_percent(lcov_path)
    print(f"Couverture de lignes : {pct:.1f}% ({covered}/{total}) — seuil requis : {args.min}%")

    if pct < args.min:
        print(f"[ERREUR] couverture {pct:.1f}% < seuil {args.min}%")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
