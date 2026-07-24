#!/usr/bin/env python3
"""
Exécuteur des gates qualité de l'adapter — les commandes n'existent qu'à UN endroit :
factory.config.json → adapter.components.<composant>.gates.

Usage :
  python scripts/run_gates.py                          # tous les composants, tous les gates
  python scripts/run_gates.py --component backend      # un composant
  python scripts/run_gates.py --gate lint              # un gate sur tous les composants
  python scripts/run_gates.py --list                   # affiche les gates sans exécuter

Consommé par : ci.yml (jobs qualité), le rituel /certify, les agents @Developer et @QA_Tester,
init_factory.py (vérification finale).

Un gate peut porter "blocking": false (constat sans blocage) — tout le reste est bloquant.
Sortie : exit 0 si tous les gates bloquants passent, exit 1 sinon.
"""
import argparse
import subprocess
import sys

import factory_config

ROOT = factory_config.ROOT


def iter_gates(cfg: dict, component_filter: str | None, gate_filter: str | None):
    components = factory_config.get(cfg, "adapter.components", {}) or {}
    for comp_name, comp in components.items():
        if component_filter and comp_name != component_filter:
            continue
        for gate_name, gate in (comp.get("gates") or {}).items():
            if gate_filter and gate_name != gate_filter:
                continue
            yield comp_name, gate_name, gate


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--all", action="store_true", help="Tous les composants, tous les gates (comportement par défaut, flag explicite)")
    parser.add_argument("--component", help="Limiter à un composant (ex : backend)")
    parser.add_argument("--gate", help="Limiter à un gate (ex : lint, test)")
    parser.add_argument("--list", action="store_true", help="Lister sans exécuter")
    args = parser.parse_args()

    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except AttributeError:
        pass

    cfg = factory_config.load(required=True)
    gates = list(iter_gates(cfg, args.component, args.gate))
    if not gates:
        print("[ERREUR] aucun gate ne correspond (vérifier factory.config.json / --component / --gate).")
        return 1

    if args.list:
        for comp, name, gate in gates:
            blocking = "bloquant" if gate.get("blocking", True) else "non bloquant"
            print(f"  {comp}.{name:<12} [{blocking}]  ({gate.get('cwd', '.')}) $ {gate['cmd']}")
        return 0

    failures: list[str] = []
    for comp, name, gate in gates:
        cwd = ROOT / gate.get("cwd", ".")
        cmd = gate["cmd"]
        blocking = gate.get("blocking", True)
        print(f"▶ {comp}.{name} — ({gate.get('cwd', '.')}) $ {cmd}", flush=True)
        result = subprocess.run(cmd, shell=True, cwd=cwd)
        if result.returncode == 0:
            print(f"✅ {comp}.{name}")
        elif blocking:
            print(f"❌ {comp}.{name} (exit {result.returncode})")
            failures.append(f"{comp}.{name}")
        else:
            print(f"⚠️ {comp}.{name} (exit {result.returncode}, non bloquant)")

    print("—" * 40)
    if failures:
        print(f"GATES EN ÉCHEC ({len(failures)}) : {', '.join(failures)}")
        return 1
    print(f"Tous les gates bloquants passent ({len(gates)} exécutés).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
