# Fixtures US-00.6 — **le MUTANT du cliquet de couverture**

⛔ **Ces fichiers ne sont PAS des tests de l'application.** Ils sont le **mutant** du contrôle
`scripts/check_flutter_coverage.py` : ils existent pour **prouver que le cliquet est capable de
REFUSER**. Leçon centrale d'US-00.5, mesurée sur six instruments — *« un contrôle qui ne peut pas
rougir est nul »*, et un contrôle **portant son mutant** y a été juste **7 fois sur 7** quand un
contrôle purement lexical était faux **7 fois sur 7**.

| Fixture | Couverture | Verdict attendu | Ce qu'elle prouve |
|---|---|---|---|
| `regression_16_sur_19.info` | **16/19 = 84,21 %** | 🔴 **ROUGE** | ⚠️ **C'EST LE TROU QUE L'US FERME** : cette valeur passait **VERTE** avant US-00.6, le plancher étant à 80 %. **Le plancher tolérait exactement une régression d'une ligne.** |
| `inchange_17_sur_19.info` | **17/19 = 89,47 %** | ✅ **VERT** | ⛔ **Aucun rouge sur un dépôt inchangé.** C'est la garde contre le **verrouillage du dépôt** : le gate est un contexte **requis**, admin inclus. |
| `hausse_18_sur_19.info` | **18/19 = 94,74 %** | ✅ **VERT** + valeur à consigner | Une **hausse** n'est **jamais** bloquante, et la valeur exacte à consigner est **imprimée** — le fichier étant protégé, seule une **action humaine** peut l'y porter. |
| `zero_ligne_mesurable.info` | **0 ligne instrumentée** | 🔴 **ROUGE explicite** | ⛔ **Un vert par vide est un mensonge.** Ce n'est pas « 0 % » : **ce n'est pas une mesure**. |

## ⚠️ Pourquoi les lignes non couvertes sont EN TÊTE

Elles reproduisent la structure du vrai rapport *(`lib/main.dart:9-10`, soit `void main()` et
`runApp(...)`)*.

> **PÉRIMÉ-2026-07-31 — ce paragraphe affirmait, « comme vérifié », qu'une troncature AUGMENTE le pourcentage et qu'un rapport partiel serait « dangereux, pas conservateur ». C'EST L'INVERSE.**
> *(Marqueur et citation tiennent sur **une seule ligne** : les avoir séparés était le défaut RB-3/RB-4
> d'US-00.5 — un marqueur sur la ligne voisine ne couvre rien, et un `grep` par ligne ne le voit pas.)* Mesuré sur le rapport réel : `0 %, 0 %, 33,33 %, 50 %, 60 %, … 89,47 %` — la
> suite est **strictement croissante**, donc **toute troncature DIMINUE le pourcentage** et un `lcov`
> tronqué est **CONSERVATEUR**. Le raisonnement était **inversé** : des non-couvertes **en tête**
> impliquent qu'une troncature en garde proportionnellement **plus**.
> ⛔ **Ce que cela ne change pas** : le refus du cas « 0 ligne mesurable » est légitime **par
> lui-même** — ce n'est pas une mesure — et le refus des **totaux incohérents** *(fixture
> `totaux_incoherents.info`, finding **B-1**)* l'est aussi. **Les deux refus tiennent sans
> l'argument faux.**
> **Relevé par les DEUX auditeurs.** Je l'avais écrit à plusieurs endroits **et propagé dans leurs
> briefs** comme un fait établi : c'est exactement le défaut qu'US-00.5 a payé six fois.

## ⚠️ Ce que ces fixtures ne prouvent PAS

Elles n'**authentifient** pas le rapport `lcov` : le cliquet ne voit que ce que le rapport contient.
Elles ne disent **rien** de la qualité des tests — un cliquet **n'améliore pas** les tests, il
**empêche seulement de reculer**. Et la complaisance reste possible, **nommément** : couvrir
`void main()` / `runApp(...)` ferait **+10,5 pt sans aucune valeur**.

⛔ **Ne pas confondre** ces 4 fixtures, qui **s'exécutent réellement en CI**, avec les **18 scénarios
Gherkin** d'US-00.6, qui sont **documentaires** — le projet n'a ni step definitions ni runner BDD.
