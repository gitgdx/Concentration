#!/usr/bin/env python3
"""Harnais de démonstration de la dette NB-1 — US-00.7, T1 (AC-7).

⛔ CE HARNAIS N'EST PAS UNE PREUVE DE L'ÉTAT RÉEL DU DÉPÔT. C'est une SIMULATION.

Il injecte une cible **SIMULÉE et AMPUTÉE** (substitution de `check_branch_protection.load_expected`)
puis appelle `check_branch_protection.run()` en mode fixture. Objet : exercer le trou **NB-1** —
une clé MAPPÉE mais ABSENTE DE LA CIBLE était doublement sautée (ni comparée par `compare()`, ni
signalée par `_guard_actual()`, qui filtrait la réponse réelle avec la constante STATIQUE
`MAPPED_TOP_KEYS`) → **exit 0 « conforme »** sur une comparaison incomplète.

Garanties de construction, vérifiables dans la sortie :
  · **AUCUN appel réseau** — `make_reader`, `_get_via_gh` et `_get_via_urllib` sont remplacés par
    une fonction qui LÈVE. Toute tentative de lecture de l'API ferait échouer le harnais bruyamment
    au lieu de la produire en silence. (Le mode fixture de `run()` n'en émet aucun par
    construction ; ce verrou le PROUVE au lieu de le déclarer.)
  · **JAMAIS la cible générée réelle** — le harnais REFUSE de démarrer si la cible injectée n'est
    pas amputée d'au moins une clé de `MAPPED_TOP_KEYS` (garde `_assert_amputee`).
  · **Sortie intégralement préfixée `[SIMULATION] `** — comme celle du comparateur en mode fixture
    (mitigation du risque R1 d'US-00.4 : une sortie simulée ne doit jamais pouvoir être relue comme
    un constat réel).
  · **Code de sortie du comparateur propagé tel quel** (0 / 1 / 2).

Usage (sans argument = le scénario **A** prescrit par T1(b) : cible amputée de `enforce_admins`
face à une réponse réelle portant `enforce_admins: {"enabled": true}`) :

  python tests/fixtures/US-00.7/nb1_harness.py
  python tests/fixtures/US-00.7/nb1_harness.py --target <cible.json> \
                                               --protection <get_protection.json> \
                                               --branch <get_branch.json>

Les clés préfixées `_` de la cible (métadonnée `_fixture`) sont RETIRÉES avant injection : la garde
`_guard_mapping()` du comparateur lèverait `MappingGap` sur toute clé de la cible hors mapping, ce
qui produirait un exit 2 pour un motif étranger à NB-1 et ruinerait la démonstration.
"""
import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "scripts"))

import check_branch_protection as cbp  # noqa: E402 — après ajustement de sys.path

DEFAULT_TARGET = "tests/fixtures/US-00.7/cible_amputee_enforce_admins.json"
DEFAULT_PROTECTION = "tests/fixtures/US-00.4/protection_conforme.json"
DEFAULT_BRANCH = "tests/fixtures/US-00.4/branch_protected_true.json"

SIM = cbp.SIM_PREFIX


def _say(text: str) -> None:
    """Toute ligne du harnais porte le même préfixe que celles du comparateur simulé."""
    print(f"{SIM}{text}")


def _no_network(*_args, **_kwargs):
    """Verrou dur : aucune lecture de l'API n'est atteignable depuis ce harnais."""
    raise AssertionError(
        "APPEL RÉSEAU INTERDIT dans le harnais NB-1 : ce harnais ne produit que des simulations."
    )


def _load_target(path_str: str) -> tuple[dict, list[str]]:
    path = Path(path_str)
    if not path.is_absolute():
        path = ROOT / path_str
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise SystemExit(f"{SIM}cible simulée invalide (objet JSON attendu) : {path_str}")
    meta = sorted(k for k in raw if k.startswith(cbp.INERT_KEY_PREFIX))
    target = {k: v for k, v in raw.items() if not k.startswith(cbp.INERT_KEY_PREFIX)}
    return target, meta


def _assert_amputee(target: dict) -> list[str]:
    """Refuse d'injecter une cible COMPLÈTE : le harnais ne doit jamais simuler la cible réelle."""
    missing = sorted(cbp.MAPPED_TOP_KEYS - set(target))
    if not missing:
        raise SystemExit(
            f"{SIM}REFUS : la cible injectée porte les 8 clés mappées — elle n'est pas amputée. "
            "Ce harnais n'exerce que des cibles SIMULÉES amputées, jamais la cible générée réelle."
        )
    return missing


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except AttributeError:  # pragma: no cover — flux non reconfigurable
        pass

    parser = argparse.ArgumentParser(
        description=(
            "Harnais SIMULÉ de démonstration de la dette NB-1 (US-00.7 T1). Aucun appel réseau, "
            "aucune preuve d'état réel."
        )
    )
    parser.add_argument("--target", default=DEFAULT_TARGET, help="cible SIMULÉE amputée (JSON)")
    parser.add_argument("--protection", default=DEFAULT_PROTECTION, help="fixture GET .../protection")
    parser.add_argument("--branch", default=DEFAULT_BRANCH, help="fixture GET .../branches/{b}")
    args = parser.parse_args()

    # Verrous réseau — posés AVANT toute exécution du comparateur.
    cbp.make_reader = _no_network
    cbp._get_via_gh = _no_network
    cbp._get_via_urllib = _no_network

    target, meta = _load_target(args.target)
    missing = _assert_amputee(target)

    _say("=" * 86)
    _say("HARNAIS NB-1 (US-00.7 T1) — cible SIMULÉE INJECTÉE, aucun appel réseau, aucune preuve.")
    _say(f"  Cible simulée      : {args.target}")
    _say(f"  Clés injectées     : {len(target)} — {', '.join(sorted(target))}")
    _say(f"  Clés AMPUTÉES      : {', '.join(missing)}  (mappées mais absentes de la cible)")
    _say(f"  Métadonnées ôtées  : {', '.join(meta) if meta else '<aucune>'}")
    _say(f"  Fixture protection : {args.protection}")
    _say(f"  Fixture branche    : {args.branch}")
    _say("  Verrou réseau      : make_reader / _get_via_gh / _get_via_urllib remplacés par un LEVÉ")
    _say("=" * 86)

    # Substitution de la cible : le comparateur ne lira JAMAIS la cible générée réelle ici.
    cbp.load_expected = lambda: json.loads(json.dumps(target))

    code = cbp.run(
        cbp.Options(from_protection=args.protection, from_branch=args.branch)
    )

    _say("-" * 86)
    _say(f"CODE DE SORTIE DU COMPARATEUR : {code}")
    _say(
        "Lecture : 0 = « conforme » (interdit sur une comparaison incomplète) · 1 = dérive · "
        "2 = vérification impossible."
    )
    _say("-" * 86)
    return code


if __name__ == "__main__":
    sys.exit(main())
