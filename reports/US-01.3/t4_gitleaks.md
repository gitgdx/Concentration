# US-01.3 — T4 : règles gitleaks de la signature mobile

> **Rédigé par** @Developer, 2026-10-02, sur `feat/US-01.3-chaine-deploiement-mobile`.
> **État** : moitié @Developer **faite** · **application humaine à faire** *(Art. 6 : `.gitleaks.toml`
> est un fichier d'enforcement, l'agent n'y écrit pas)*.
> ⛔ Ce rapport ne contient **aucun secret**. Les fixtures sont **factices**, générées hors du dépôt
> dans un répertoire temporaire, puis **détruites**, et aucune n'est versionnée.

## Livrables

| Fichier | Rôle |
|---|---|
| [`gitleaks.toml.proposed`](gitleaks.toml.proposed) | Configuration **complète** à copier telle quelle sur `.gitleaks.toml` |
| [`gitleaks_t4_criterion.py`](gitleaks_t4_criterion.py) | Critère de sortie exécutable : défaut *(avant application)*, `--apres-application`, `--selftest` |

La proposition **conserve** à l'identique le titre, `[extend] useDefault = true`, les deux règles
existantes et l'allowlist. Le critère le vérifie en comparant les **structures TOML**, pas le texte.
Elle **ajoute** trois règles :

- `signature-keystore-chemin` : règle de **chemin** sur `.jks`, `.keystore`, `.p12`, `.pfx`.
- `signature-mot-de-passe-proprietes` : règle de **mot-clé** `storePassword` / `keyPassword` limitée
  aux fichiers `.properties`, **sans entropie minimale**, si bien qu'un mot de passe faible déclenche aussi.
- `signature-mot-de-passe-script` : même mot-clé, pour un **littéral cité** dans un `.gradle` ou un
  `.gradle.kts`.

La note d'ingénierie d'US-00.1 n'est **pas repeinte**. Elle est **datée `PÉRIMÉ-2026-10-02`**, avec
ce qui en reste vrai et ce qui est devenu faux.

## Ce que le critère établit, lu dans sa sortie

Les verdicts se **lisent** en rejouant les commandes ci-dessous. Ils ne sont pas recopiés ici.
Fixtures : `F1` keystore binaire `.jks` *(keytool du JBR)* · `F2` `key.properties` à mot de passe
aléatoire · `F3` mot de passe aléatoire en dur dans un `.gradle.kts` · `F4` `key.properties` à mot de
passe **faible**, en CRLF · `F5` mot de passe faible dans un `.gradle` Groovy · `N1` `key.properties`
**sans** mot de passe · `N2` valeurs réservées (`<…>`, `$VAR`, `${VAR}`, valeur vide) · `N3`
`.gradle.kts` qui **lit** les propriétés (`props["storePassword"]`, `System.getenv`) · `F1A` = `F1`
avec un attribut `diff` · `B6` borne de l'allowlist.

Chaque fixture est jouée **en mode `dir` ET en mode `git`**. Le mode `git` correspond à ce que lisent
la CI (`gitleaks-action@v2`) et le hook `pre-commit` (`gitleaks protect --staged`). Chaque exécution
est lue **par son rapport JSON**, car gitleaks rend aussi `1` sur une configuration illisible. Un `1`
**sans rapport** est donc un **défaut** (code `3`), jamais un constat.

## ⚠️ Deux bornes MESURÉES, à ne pas sur-lire

1. **En mode `git`, la règle de chemin NE VOIT PAS un keystore BINAIRE** *(gitleaks 8.30.1)*. Le
   diff d'un binaire n'a aucune ligne ajoutée, donc gitleaks n'a aucun fragment à examiner. En
   pratique : **en CI et au pre-commit, un `.jks` binaire commité passe gitleaks, même après
   application de T4.** La barrière du binaire en CI reste **T2**, qui reconnaît un keystore par
   son contenu, avec le `.gitignore` racine. Le critère d'écrit de T4, « les quatre fixtures
   rejouées hors dépôt rendent exit 1 », est tenu **en mode `dir`**. Le critère attend
   `F1/git → 0` comme une **BORNE**, pour que tout changement de comportement de gitleaks soit
   **vu**.
   - 🔬 **Remède mesuré, ⛔ non appliqué** (hors du périmètre de T4, décision @Architect) : la
     variante `F1A` pose `*.jks diff` dans un `.gitattributes`, uniquement dans le dépôt temporaire.
     La règle de chemin voit alors le binaire **aussi en mode `git`**. Étendre le `.gitattributes`
     racine aux quatre extensions est donc une option **démontrée**.
2. **L'allowlist globale `changeme` s'applique aussi aux nouvelles règles** : un mot de passe
   **contenant** `changeme` n'est pas signalé (fixture `B6`, attendue `0` comme BORNE). T2 le voit.

Ce que le critère **ne prouve pas** : la version du moteur de `gitleaks-action@v2` en CI *(non lue)*,
et un mot de passe placé hors des clés `storePassword` / `keyPassword` ou hors d'un `.properties` ou
d'un script Gradle. Un keystore à extension **non listée** (`.bks`, `.jceks`, `.bcfks`) n'est vu
**que** par T2.

## Cohérence avec T2 (note du lock du 2026-10-01)

Ce sont deux couches distinctes, et il n'y a pas de contradiction. T4 règle gitleaks par le
**contenu** et par le **chemin des keystores seulement**. ⛔ **Aucune règle de chemin ne porte sur
`key.properties`**. `N1` (`key.properties` sans mot de passe) rend `0` sous gitleaks, et c'est voulu :
cela évite les faux positifs. Ce résultat ne rend **pas** acceptable un `key.properties` suivi, car
**T2 le refuse par son nom**. Rejeu : `python scripts/deploiement/check_secrets_signature.py` reste
`exit 0` avec les deux nouveaux fichiers. Ces fichiers ont aussi été passés **directement** à
`analyser_contenu` de T2, sous leur futur chemin suivi, et aucun constat n'est sorti.

## PROCÉDURE HUMAINE — application (Art. 6)

À exécuter **par l'humain**, à la racine du dépôt, sur la branche `feat/US-01.3-chaine-deploiement-mobile`.

```bash
# 0. Pré-vérification : le critère est vert AVANT application (contrôle négatif C-11 compris)
python reports/US-01.3/gitleaks_t4_criterion.py            # attendu : exit 0, « Verdict : CONFORME »

# 1. Application : copie INTÉGRALE (pas de fusion à la main)
cp reports/US-01.3/gitleaks.toml.proposed .gitleaks.toml

# 2. Le diff ne doit porter QUE des AJOUTS (3 règles + la note datée), aucune suppression
git diff --stat .gitleaks.toml
git diff .gitleaks.toml

# 3. Vérification APRÈS application (exige .gitleaks.toml == proposition, octet pour octet aux fins de ligne près)
python reports/US-01.3/gitleaks_t4_criterion.py --apres-application   # attendu : exit 0
python reports/US-01.3/gitleaks_t4_criterion.py --selftest            # attendu : exit 0
python scripts/deploiement/check_secrets_signature.py                 # attendu : exit 0

# 4. Même lecture que la CI, sur le dépôt réel, avec la configuration appliquée
gitleaks git . --config .gitleaks.toml --no-banner --redact           # attendu : « no leaks found », exit 0
```

Lecture des codes du critère : `0` conforme · `1` écart nommé · `2` **ne conclut pas** *(gitleaks,
keytool ou git introuvable — ⛔ jamais un vert)* · `3` défaut de l'instrument.
⚠️ Lancé **sans** `--apres-application` après la copie, le critère rend `1` **en le disant**
(« `.gitleaks.toml` est DÉJÀ la proposition »), puisque le contrôle négatif C-11 n'a alors plus
d'objet. C'est attendu.
⚠️ Le `--selftest` reconstruit la configuration « d'avant T4 » à partir de la proposition, en retirant
les trois blocs. Il ne lit pas `.gitleaks.toml` : il reste donc jouable **après** application.

Une fois la copie faite, cocher la moitié humaine de T4 dans le Story File, avec la date.
