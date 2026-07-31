#!/usr/bin/env python3
"""
Vérifie la couverture de lignes à partir de coverage/lcov.info
(produit par `flutter test --coverage`).

`flutter test` n'a pas d'équivalent au `--cov-fail-under` de pytest ni aux
`thresholds` de Vitest — ce script comble ce manque, spécifique à l'adapter
`flutter` (voir gate `app.test` dans factory.config.json).

DEUX SEUILS, DEUX RÔLES DISTINCTS (US-00.6, AC-4) — ils coexistent :
  * `--min`            PLANCHER CONTRACTUEL. Il borne jusqu'où la référence peut
                       être abaissée. Nommé par ADR-001 (accepté, immuable).
  * `coverage_ratchet` CLIQUET. Il interdit la RÉGRESSION sous le dernier niveau
                       CONSIGNÉ. Sa valeur vit UNIQUEMENT dans
                       factory.config.json -> adapter.components.app.coverage_ratchet
                       (Art. 4 : « les seuils sont définis en un seul endroit »).
Le seuil appliqué est `max(plancher, cliquet)`, et le message dit TOUJOURS lequel
des deux est violé — jamais un « seuil » anonyme.

⛔ AUCUNE VALEUR DE SEUIL N'EST ÉCRITE EN DUR DANS CE FICHIER. Le cliquet est LU
   dans la configuration ; le plancher arrive par `--min`. C'est un critère de
   test d'US-00.6, et il est vérifié par MUTANT (on modifie la référence et le
   verdict doit changer).

FAIL-EXPLICIT, JAMAIS DE FAUX VERT (US-00.6, AC-2/AC-3 « Erreur ») :
  * rapport lcov absent .................. échec explicite
  * 0 ligne instrumentée ................. échec explicite (un vert par vide est
                                           un mensonge : une troncature du lcov
                                           AUGMENTE le pourcentage, les lignes non
                                           couvertes étant en tête du fichier)
  * clé `coverage_ratchet` absente ....... plancher seul + message explicite
  * clé mal formée ....................... échec explicite, jamais un plantage
  * référence < plancher ................. échec explicite (config incohérente),
                                           jamais « le plus strict gagne » en silence

Usage :
  python scripts/check_flutter_coverage.py --min 80 [--lcov coverage/lcov.info]
                                                    [--config factory.config.json]
                                                    [--no-ratchet]
"""
import argparse
import json
import sys
from pathlib import Path

# Une hausse de couverture n'est jamais bloquante, mais elle doit être VISIBLE :
# la référence vit dans un fichier PROTÉGÉ, donc sa mise à jour est une action
# humaine — le script imprime la valeur exacte à consigner, il ne la consigne pas.
RATCHET_PATH = ("adapter", "components", "app", "coverage_ratchet")


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


def read_ratchet(config_path: Path) -> tuple[float | None, str]:
    """Retourne (valeur, message). valeur None => cliquet non applicable.
    Lève ValueError si la clé existe mais est inexploitable (fail-explicit)."""
    if not config_path.exists():
        return None, f"cliquet IGNORÉ : {config_path} introuvable"
    try:
        data = json.loads(config_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"{config_path} illisible : {exc}") from exc

    node = data
    for key in RATCHET_PATH:
        if not isinstance(node, dict) or key not in node:
            return None, (
                "cliquet NON CONFIGURÉ (clé "
                + ".".join(RATCHET_PATH)
                + " absente) — seul le plancher contractuel s'applique"
            )
        node = node[key]

    # Le schéma déclare un OBJET : la valeur doit venir avec sa date et son motif,
    # JSON ne portant aucun commentaire (US-00.6, C-1).
    if not isinstance(node, dict):
        raise ValueError(
            "cliquet MAL FORMÉ : "
            + ".".join(RATCHET_PATH)
            + f" doit être un objet {{value, date, motif}}, reçu {type(node).__name__}"
        )
    if "value" not in node:
        raise ValueError("cliquet MAL FORMÉ : champ « value » absent")
    try:
        value = float(node["value"])
    except (TypeError, ValueError) as exc:
        raise ValueError(f"cliquet MAL FORMÉ : « value » n'est pas un nombre ({node['value']!r})") from exc

    detail = ""
    if node.get("date"):
        detail += f", consigné le {node['date']}"
    if node.get("motif"):
        detail += f" — {node['motif']}"
    return value, f"cliquet = {value}%{detail}"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--min", type=float, required=True, help="Plancher contractuel de couverture (%%)")
    parser.add_argument("--lcov", default="coverage/lcov.info", help="Chemin du rapport lcov")
    parser.add_argument("--config", default="factory.config.json", help="Source unique du cliquet")
    parser.add_argument(
        "--no-ratchet",
        action="store_true",
        help="N'applique QUE le plancher (diagnostic ; jamais en CI)",
    )
    args = parser.parse_args()

    lcov_path = Path(args.lcov)
    if not lcov_path.exists():
        print(f"[ERREUR] {lcov_path} introuvable — lancer `flutter test --coverage` avant ce script.")
        return 1

    pct, covered, total = line_coverage_percent(lcov_path)

    # ⛔ Un rapport sans ligne instrumentée n'est pas « 0 % » : il n'est PAS UNE MESURE.
    #    Le laisser passer serait un vert par vide — refusé explicitement.
    if total == 0:
        print(f"[ERREUR] {lcov_path} ne contient AUCUNE ligne instrumentée (0 ligne mesurable).")
        print("         Ce n'est pas une couverture de 0 % : ce n'est pas une mesure. Refusé.")
        return 1

    # Cliquet : lu dans la source unique, jamais écrit en dur ici.
    ratchet = None
    ratchet_msg = "cliquet DÉSACTIVÉ par --no-ratchet (diagnostic)"
    if not args.no_ratchet:
        try:
            ratchet, ratchet_msg = read_ratchet(Path(args.config))
        except ValueError as exc:
            print(f"[ERREUR] {exc}")
            print("         Fail-explicit : ni plantage, ni vert silencieux.")
            return 1

    # Configuration incohérente : une référence sous le plancher contractuel
    # n'est jamais résolue en silence par « le plus strict gagne ».
    if ratchet is not None and ratchet < args.min:
        print(f"[ERREUR] configuration INCOHÉRENTE : cliquet {ratchet}% < plancher contractuel {args.min}%.")
        print("         Le plancher borne l'abaissement de la référence — corriger la configuration.")
        return 1

    required = max(args.min, ratchet) if ratchet is not None else args.min
    source = "cliquet" if (ratchet is not None and ratchet >= args.min) else "plancher contractuel"

    # `{pct:.1f}` est un AFFICHAGE. La valeur à consigner est arrondie VERS LE BAS,
    # sans quoi consigner l'affiché fabriquerait un rouge sur un dépôt inchangé
    # (US-00.6, C-2 : la mesure vaut 89,4737 % et s'affiche « 89.5 % »).
    print(f"Couverture de lignes : {pct:.1f}% ({covered}/{total}) — seuil requis : {required}% ({source})")
    print(f"  plancher contractuel : {args.min}%  |  {ratchet_msg}")

    if pct < required:
        manque = required - pct
        lignes = manque * total / 100.0
        print(f"[ERREUR] RÉGRESSION : couverture {pct:.2f}% < {required}% ({source}).")
        print(f"         Écart {manque:.2f} pt, soit ~{lignes:.1f} ligne(s) sur {total}.")
        return 1

    # Hausse : jamais bloquante, mais la valeur exacte à consigner est IMPRIMÉE —
    # le fichier étant protégé, seule une action humaine peut l'y porter.
    if ratchet is not None and pct > ratchet:
        a_consigner = int(pct * 10) / 10.0  # arrondi VERS LE BAS
        if a_consigner > ratchet:
            print(
                f"  ⬆️  HAUSSE : {pct:.2f}% > cliquet {ratchet}%. "
                f"Valeur à consigner (arrondie VERS LE BAS) : {a_consigner}"
            )
            print("      Action HUMAINE : factory.config.json est protégé, aucun agent ne l'édite.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
