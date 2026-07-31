# US-00.5 — La tension structurelle qui a fait échouer **six instruments successifs**

> **@Architect, 2026-07-31.** Ce document ne corrige rien : il **nomme une incompatibilité** que quatre
> jours d'audits ont mise au jour sans jamais la formuler. C'est, à mon avis, le vrai livrable de
> méthode de cette US — et il est destiné à **`/audit-methodo`**.

---

## 1. Le constat brut

Le gate `qa_exit_v3.sh` rend **7 échecs**. **Les 7 sont des faux positifs**, et je le montre par
structure, pas par affirmation :

| Échec rapporté | État réel, vérifié |
|---|---|
| « `verify.sh` §7 est TAUTOLOGIQUE » | ✅ **réparé** — le motif est **lu** depuis sa source, et le contrôle **se prouve par un mutant** *(« le mutant est VU (2 lignes) ⇒ contrôle FALSIFIABLE »)*. La ligne fautive ne subsiste que **dans le commentaire qui documente sa réparation**. |
| « 1 catégorie absente / 2 catégories périmées dans la table » | ✅ **réparé** — les catégories sont **lues dans l'Art. 4** *(`mise en forme, lint, typage statique, tests, audit de dépendances`)*. Les anciennes ne subsistent que **dans le commentaire expliquant F-2**. |
| « SCB annonce encore la PR nº 2 comme À VENIR » | ✅ **réparé** — le §`[US-00.5]` enregistre **PR #17 et PR #18 fusionnées**. Les mots « PR nº 2 » subsistent dans le **récit** de ce qui a été fait. |
| « DoD 5 porte encore *l'Art. 4 n'est pas amendé ici* » | ✅ **case COCHÉE** avec sa preuve. La phrase est une **citation**, sur une ligne portant `PÉRIMÉ-2026-07-31` et précédée de « **ce motif disait** ». |
| « DoD 14 porte encore *il n'y a pas encore d'amendement à approuver* » | ✅ **idem** — et la case est **DÉCOCHÉE À RAISON : l'attestation humaine manque réellement.** |
| « critère de clôture EPIC_00 encore DÉCOCHÉ » | ✅ **COCHÉ** dans `EPIC_00-fondations.md`, avec sa preuve et ses bornes. |

⛔ **Et un `OK` est FAUX, celui qui compte le plus** : « *une attestation humaine de l'amendement est
consignée* ». **Il n'y en a aucune.** `reviews = 0`, `reviewDecision` vide, et l'humain n'a rien attesté.
Le contrôle matche un texte **parlant** d'attestation. **Un gate qui valide une approbation humaine
absente est pire que pas de gate** — c'est le seul contrôle irremplaçable de cette US, sur le **seul
artefact normatif sans prévention ni détection**. ⛔ **Je ne m'en sers pas.**

---

## 2. La tension, et pourquoi elle est structurelle

Deux exigences du projet, chacune **justifiée**, sont **mutuellement incompatibles** sous un gate par
mots-clés :

**(A) La convention de correction**, payée par cinq `FAIL` sur US-00.7 :
> *« Marqueur littéral sur la ligne même, jamais `~~texte~~`. On DATE, on ne REPEINT pas — réécrire
> détruirait la seule preuve que le défaut s'est produit. »*

⇒ Toute correction **conserve le texte fautif** et l'explique. **Un correctif qui s'explique produit
MÉCANIQUEMENT des occurrences de ce qu'il corrige.**

**(B) Le gate qui cherche le texte fautif.** Il ne peut pas distinguer une **assertion** d'une
**citation-dans-sa-réfutation**. Deux issues, **toutes deux fausses** :

| Choix du gate | Conséquence | Constaté |
|---|---|---|
| **Exclure** les lignes marquées | il masque le défaut réel dont la ligne **contient** le mot-clé | 🔴 **mon `assertions_vives.sh`** : l'exclusion `grep -v PÉRIMÉ` matchait « PÉRIMÉ » **dans la commande** et **blanchissait** le seul écart réel |
| **Ne pas exclure** | chaque correction expliquée **trip** le gate | 🔴 **`qa_exit_v3.sh`** : **7/7 faux positifs** |

**Il n'y a pas de troisième voie par mots-clés.** C'est pourquoi **six instruments successifs** ont
échoué — trois de moi, trois de la QA :

1. mon décompte de marqueurs *(mesurait le fait, pas le reste)* ·
2. son `qa_assertions_chiffrees.sh` v1 *(colonne `écrit` = **transcription**, pas spécification — **elle
   l'a retiré**)* ·
3. mon `assertions_vives.sh` *(**blanchissait** — retiré)* ·
4. son `qa_detecteur_v2.sh` *(emplacements **figés**, exit code inopérant — **elle l'a retiré**)* ·
5. mon contrôle de monotonie *(comparait l'ancien motif **à lui-même** — **infalsifiable**)* ·
6. son `qa_exit_v3.sh` *(**7/7 faux positifs** + **1 faux OK sur l'attestation humaine**)*.

⚠️ **Aucun n'a été juste du premier coup, dans les deux camps.** Ce n'est donc **pas** un défaut de
rigueur individuelle : c'est un **défaut de conception** que la tension (A)↔(B) rend inévitable.

---

## 3. La voie de sortie — **structurelle**, jamais lexicale

Un discriminateur **assertion / citation** ne peut pas être un mot. Il doit être **positionnel** :

1. **Les guillemets délimitent.** Un texte entre `«` … `»` ou entre backticks est une **citation** : il
   ne peut porter aucune assertion du document qui le contient.
2. **Le marqueur doit précéder la citation sur la même ligne** — `PÉRIMÉ-<date>` **avant** le `«`. Un
   marqueur qui suit, ou qui vit sur une ligne voisine, ne couvre rien *(déjà établi : findings RB-3 et
   RB-4)*.
3. **Un contrôle qui ne peut pas rougir est nul.** Tout contrôle bloquant **porte son mutant** : on
   injecte le défaut qu'il cherche et on **exige** qu'il le voie. *(C'est ce qui a démasqué mon §7.)*
4. **Un `OK` obtenu sur un ensemble vide est un faux `OK`.** Toute assertion de conformité imprime son
   **dénominateur** *(la QA l'a relevé sur son propre v2 : `VERIFIEES=0` rendait `ECART=0` vrai par
   vide)*.
5. **Une règle n'existe qu'en un seul exemplaire.** Motif, liste de verbes, catégories, emplacements :
   **lus** depuis leur source, jamais recopiés. *(Trois dérives constatées, toutes détectées après
   coup.)*

⛔ **Ce document ne prétend pas que cette voie fonctionne** : elle n'est **pas implémentée**, et le
précédent de six instruments interdit de le supposer. **Elle est versée à `/audit-methodo` comme
spécification à éprouver — par mutation, avant d'être crue.**

---

## 4. Ce que cela ne change pas

Le **produit** d'US-00.5 est validé et sur `main` : la QA écrit que « *le produit est bon et il est
prêt* », les **8 affirmations** de l'Art. 4 amendé sont **exactes** *(vérifiées une par une, à charge,
par exécution)*, et **la contradiction ADR-001 ↔ Art. 4 est ÉTEINTE, réserve sur le `🚀 OUI` levée**.
**Tout ce qui échoue est l'appareil de preuve**, et c'est ce document qui en explique la cause.

⏳ **Il reste une seule chose qui ne soit pas de mon ressort** : l'**attestation humaine de l'amendement**
*(DoD 14)*. Elle est **demandée** et **non reçue**. Elle restera **décochée** jusque-là.
