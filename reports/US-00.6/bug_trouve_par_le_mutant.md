# US-00.6 · Le mutant a trouvé un **vrai bug**, avant la production

> **@Architect, 2026-07-31.** Ce document existe parce que l'autotest a fait **exactement** ce pour quoi
> il a été écrit, **dès sa première exécution en conditions réelles**. C'est la meilleure preuve que la
> leçon d'US-00.5 valait son prix.

---

## Le bug

`scripts/check_flutter_coverage.py` imprimait son message de **hausse** avec un caractère `⬆️`
*(U+2B06 + U+FE0F)*. Sur une console Windows en **`cp1252`** — celle du poste, et celle de tout
utilisateur français par défaut — ce caractère est **inencodable** :

```
UnicodeEncodeError: 'charmap' codec can't encode characters in position 2-3
```

⇒ **le script rendait `1` au lieu de `0`** sur une couverture qui **montait**.
**Un gate qui plante sur son propre message de SUCCÈS est un faux rouge.**

## ⚠️ Pourquoi il aurait échappé à tout le reste

Le chemin fautif n'est atteint **que si la couverture DÉPASSE la référence** d'au moins **0,1 pt** après
arrondi vers le bas. Or la mesure réelle vaut **89,4737 %** pour une référence à **89,4** :
`int(89.4737 × 10) / 10 = 89.4`, qui **n'est pas supérieur** à `89.4`.

⇒ **Le gate nominal `run_gates --gate test` passe VERT et ne touche jamais la ligne fautive.**
⇒ Le bug se serait déclenché **le jour où la couverture serait réellement montée** — donc en
**production**, sur une PR **légitime**, et il l'aurait **bloquée** en affirmant une régression
inexistante.

**Seule la fixture `hausse_18_sur_19.info`** *(94,74 %)* atteint ce chemin. **C'est le mutant qui a
trouvé le bug, et rien d'autre n'aurait pu le trouver.**

## Action → attendu → obtenu

| | |
|---|---|
| **Action** | `python scripts/selftest_coverage_ratchet.py`, console `cp1252`, **sans** `PYTHONIOENCODING` |
| **Attendu** | 4 attentes tenues, `exit 0` |
| **Obtenu (avant correctif)** | `ECHEC \| hausse_18_sur_19.info  exit attendu=0 obtenu=1` + `UnicodeEncodeError` |
| **Obtenu (après correctif)** | `les 4 attentes sont tenues, dont 2 REFUS` · **`exit=0`** |

## Correctif — double, parce qu'un gate ne se répare pas à moitié

1. **Messages imprimés en ASCII.** Vérifié **par AST** *(analyse des seuls arguments de `print`, jamais
   des commentaires ni des docstrings)* : **aucun** caractère hors `cp1252` ne subsiste dans les sorties
   des **deux** scripts.
2. **Garde au démarrage** : `sys.stdout.reconfigure(errors="replace")` sur `stdout` **et** `stderr`, dans
   un `try/except` *(un flux redirigé n'est pas toujours reconfigurable)*. Elle **rattrape tout caractère
   qui reviendrait par inadvertance** : il s'affichera en `?`, et **le gate ne plantera pas**.

⛔ **Pourquoi les deux et pas un seul** : l'ASCII seul se re-dégrade à la première rédaction distraite ;
la garde seule laisserait des `?` dans des messages qu'on peut écrire proprement. **La garde est le filet,
l'ASCII est la propreté.**

## Ce que cet épisode établit — et c'est le point

> **Un gate ne doit jamais dépendre de l'encodage de la console où il tourne.**

Et surtout, la validation de la doctrine d'US-00.5, **cette fois par un cas positif** :

- Le projet a payé **six instruments de contrôle faux** pour apprendre que *« un contrôle qui ne peut pas
  rougir est nul »*, avec une mesure : un contrôle **portant son mutant** juste **7 fois sur 7**, un
  contrôle **purement lexical** faux **7 fois sur 7**.
- **Ici, le mutant a trouvé un bug de production dans le livrable qu'il accompagne, à sa première
  exécution.** Sans lui, ce bug partait sur `main`, dans un **contexte requis**, et se réveillait le jour
  d'une hausse de couverture — c'est-à-dire le jour d'une **bonne nouvelle**.

⛔ **Ce que cela ne prouve pas** : que le mutant trouvera les prochains. Il ne couvre que **4 cas**, et
son jeu de fixtures est **fini**. Aucune exhaustivité n'est revendiquée.
