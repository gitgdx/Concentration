# US-00.6 · Les **DEUX** éditions humaines — T7 et T8

> **@Architect, 2026-07-31.** ⛔ Les deux fichiers ci-dessous sont **protégés par
> `.claude/hooks/protect_files.sh`** : **aucun agent ne peut les écrire**, et c'est voulu. Les diffs sont
> **exacts** et **prêts à copier**. ⚠️ **L'ordre compte** : la **logique est déjà livrée** et **tolérante à
> l'absence de la clé** *(vérifié : sans elle, seul le plancher s'applique et le gate reste vert)*, donc
> **aucun état intermédiaire ne casse une PR** — le gate `📱 App` est un **contexte REQUIS**.

---

## T7 — `factory.config.json` : ajouter `app.coverage_ratchet`

**Où** : dans `adapter.components.app`, **juste après** la ligne `"coverage_min": 80,`.

```diff
     "app": {
       "path": ".",
       "runtime": { "flutter": "3.44.7", "dart": "3.12" },
       "coverage_min": 80,
+      "coverage_ratchet": {
+        "value": 89.4,
+        "date": "2026-07-31",
+        "motif": "US-00.6 — couverture initiale mesuree 17/19 = 89,4737 %, arrondie VERS LE BAS. Toute baisse sous cette valeur est une REGRESSION."
+      },
       "install": { "cmd": "flutter pub get" },
```

### ⚠️ Pourquoi **`89.4`** et surtout **pas `89.5`**

| | |
|---|---|
| Couverture **exacte** mesurée | **`89.4737 %`** *(17 lignes sur 19)* |
| Ce que le script **AFFICHE** | **`89.5 %`** — c'est un **arrondi d'affichage** |
| Valeur **consignée** | **`89.4`** — arrondie **vers le bas** |

⛔ **Consigner `89.5` fabriquerait un rouge immédiat sur un dépôt inchangé** : `89.4737 < 89.5`. Le gate
étant un **contexte requis**, cela rendrait **toute PR infusionnable, administrateur inclus**. Le coût de
l'arrondi vers le bas est **0,07 pt** — soit **73 fois moins qu'une ligne** *(1 ligne = **5,26 pt** sur 19)*.

### Pourquoi un **objet** et non un nombre nu

Le schéma déclare `"coverage_ratchet": { "type": "object" }`, et **JSON ne porte aucun commentaire** : le
lien entre la valeur et sa justification **doit être une donnée**, sinon il n'existe pas. La `date` et le
`motif` sont **lus et affichés** par le script à chaque exécution.

---

## T8 — `scripts/factory_sync.py` : lire le cliquet **pour le composant `app`**

**Où** : dans la fonction qui valide les seuils de l'adapter, **juste après** le bloc `frontend` existant
*(celui qui se termine par `< ratchet config ({expected})"`)* et **avant** le `return errors`.

```diff
                     errors.append(
                         f"{vitest_cfg.relative_to(ROOT)} : {key}={m.group(1)} < ratchet config ({expected})"
                     )
+
+    # US-00.6 — cliquet de couverture du composant `app` (adapter `flutter`).
+    # Le bloc `frontend` ci-dessus ne voyait PAS ce composant : la cle y etait donc
+    # IGNOREE en silence. Ici on valide sa FORME et sa COHERENCE avec le plancher.
+    app = components.get("app", {})
+    app_ratchet = app.get("coverage_ratchet")
+    if app_ratchet is not None:
+        if not isinstance(app_ratchet, dict) or "value" not in app_ratchet:
+            errors.append(
+                "factory.config.json : app.coverage_ratchet doit etre un objet {value, date, motif}"
+            )
+        else:
+            try:
+                r_val = float(app_ratchet["value"])
+            except (TypeError, ValueError):
+                errors.append(
+                    f"factory.config.json : app.coverage_ratchet.value n'est pas un nombre "
+                    f"({app_ratchet['value']!r})"
+                )
+            else:
+                app_min = app.get("coverage_min")
+                if app_min is not None and r_val < float(app_min):
+                    errors.append(
+                        f"factory.config.json : app.coverage_ratchet.value={r_val} "
+                        f"< coverage_min ({app_min}) — le plancher borne l'abaissement du cliquet"
+                    )
+                # Le cliquet n'a d'effet QUE si le gate l'applique : on verifie que la
+                # commande du gate `test` passe bien par le script qui le lit.
+                test_cmd = ((app.get("gates") or {}).get("test") or {}).get("cmd", "")
+                if "check_flutter_coverage.py" not in test_cmd:
+                    errors.append(
+                        "factory.config.json : app.coverage_ratchet est defini mais le gate "
+                        "app.test n'appelle pas check_flutter_coverage.py — le cliquet serait IGNORE"
+                    )
     return errors
```

### ⚠️ Ce que ce diff fait, et **ce qu'il ne fait pas**

✅ **Il fait** : `factory_sync.py --check` — donc le job CI **requis** `📋 Governance` — **valide désormais
la forme du cliquet, sa cohérence avec le plancher, et le fait que le gate l'applique réellement**. Sans
ce diff, la clé serait présente mais `--check` n'en dirait **rien**.

⛔ **Il ne fait pas** : il **n'applique pas** le cliquet — c'est
`scripts/check_flutter_coverage.py` *(déjà livré)* qui le fait, dans le gate `app.test`.
Il **ne touche aucun autre comportement** de `factory_sync.py` : le bloc `frontend` est **inchangé**, et
tout le reste du fichier aussi. **Un seul hunk, en ajout pur.**

---

## Après tes deux copies — contrôle de sortie, à exécuter

```sh
python scripts/factory_sync.py --check          # doit rester exit 0, et valider le cliquet
python scripts/run_gates.py --gate test         # doit imprimer « seuil requis : 89.4% (cliquet) »
python scripts/selftest_coverage_ratchet.py     # doit rester exit 0 (4 attentes, 2 REFUS)
```

⚠️ **Si `run_gates --gate test` échoue après ta copie, c'est que la valeur consignée est trop haute** —
c'est le risque **R-1** *(verrouillage du dépôt)*. Le remède est **immédiat et sûr** : abaisser la valeur,
jamais toucher au script.

## Ce que ces deux éditions **ne prouvent pas**

- ⛔ **Le cliquet ne monte jamais tout seul.** Il protège le dernier niveau **CONSIGNÉ**, jamais le dernier
  **atteint** : sa mise à jour est une **action humaine**, puisque le fichier est protégé. Si la couverture
  monte à 95 % et que personne ne consigne, une **régression jusqu'à 89,4 % restera silencieuse**.
- ⛔ **Aucune détection de dérive** : `--check` valide la **forme** et la **cohérence**, jamais que la
  valeur soit **encore atteignable**.
- ⛔ **Un cliquet n'améliore pas les tests** — il empêche seulement de reculer. Et la complaisance reste
  possible, **nommément** : couvrir `void main()` et `runApp(...)` *(les **2** lignes non couvertes,
  `lib/main.dart:9-10`)* ferait **+10,5 pt sans aucune valeur**.
- ⛔ **La couverture porte sur un squelette** : **19 lignes**. `89,47 %` n'a **aucune valeur statistique**,
  et **aucune valeur n'existe entre 89,47 % et 94,74 %** — le grain minimal est **5,26 pt**.
