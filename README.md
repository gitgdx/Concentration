# Concentration

> Projet initialisé depuis [`factory-starter-kit`](https://github.com/<org>/factory-starter-kit) —
> software factory gouvernée par agents Claude Code. Voir `CLAUDE.md` (règles dures) et
> `docs/SQUAD_GUIDE.md` (guide complet).

## Démarrage

Compléter cette section avec les instructions réelles de build/lancement de l'application, une
fois le squelette de l'adapter `flutter` adapté au besoin métier
(voir `docs/governance/STACK_PROFILE.md`).

## Qualité

```bash
python scripts/run_gates.py --list   # lister les gates configurés
python scripts/run_gates.py --all    # tout exécuter (lint, typecheck, tests, audit dépendances…)
```

## Gouvernance

- Constitution : `docs/governance/CONSTITUTION.md`
- Tracks : `docs/governance/TRACKS.md`
- État du sprint : `/sprint-status`
- Créer une US : `/us-new <EPIC> <titre>`
