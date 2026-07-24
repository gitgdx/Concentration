# Écrans Stitch — Concentration (références UX)

> Maquettes haute-fidélité importées depuis Stitch (Google). **Références de design uniquement** —
> la source d'autorité du design system reste [`../DESIGN_SYSTEM.md`](../DESIGN_SYSTEM.md),
> maintenu par @UXDesigner.

## Provenance

- **Projet Stitch** : `projects/3148275337692523423` (titre généré : « Adventure Expedition Planner » — contenu = Concentration)
- **Date de récupération** : 2026-07-24
- **Récupéré via** : MCP Stitch (`stitch.googleapis.com`)

## Écrans

| Fichier | Écran Stitch | ID | Correspondance PRD/DESIGN |
|---|---|---|---|
| [`hub_de_pratiques.html`](hub_de_pratiques.html) · [`.png`](hub_de_pratiques.png) | Hub de Pratiques | `6969a6bd598b4065874910632c8384f1` | Hub de pratiques + grille Échéances (§6, RF-20) |
| [`gestion_des_echeances.html`](gestion_des_echeances.html) · [`.png`](gestion_des_echeances.png) | Gestion des Échéances | `1cf3ab9a01a94ef0911bfa69197e3817` | Page de gestion des événements (§6, RF-10/14) |

## Points de vigilance (à arbitrer en US UX)

- **Nombre nu sans unité** (DESIGN §2 règle 1) : la grille de tuiles respecte la règle ; la page
  de gestion « Journal » affiche « days left / days » — à confirmer comme volontaire (contexte
  gestion ≠ tuile de pratique).
- **Langue** : le HTML du Hub est en `lang="fr"`, celui de la gestion en `lang="en"` — à uniformiser.
- **Nommage** : les maquettes portent le nom de code « Sobriety » dans le `<title>`.
