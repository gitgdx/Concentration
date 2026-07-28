# US-00.7 · T1 + T2 — Correctif **NB-1**, demonstration avant / apres, et controle compensatoire de completude

> **Portee de ce fichier : SIMULATIONS UNIQUEMENT.** Toute sortie de comparateur reproduite ici porte
> le prefixe `[SIMULATION] `. **Aucune ligne de ce fichier n'atteste l'etat reel du depot** — les
> preuves d'etat reel vivent dans `reports/US-00.7/entry_state/` (avant le `PUT`) puis dans
> `reports/US-00.7/applied_state/` (apres). Mitigation du risque **R1** d'US-00.4.
>
> **Aucune ecriture distante n'a ete emise pour produire ce fichier**, et **aucun appel reseau** : le
> harnais remplace `make_reader`, `_get_via_gh` et `_get_via_urllib` par une fonction qui **leve**.

| Champ | Valeur |
|---|---|
| US | **US-00.7** — Protection de la branche principale : application effective |
| Taches | **T1** (a -> g) et **T2** — phase 0, aucune ecriture distante |
| AC | **AC-7** (dette NB-1 reduite AVANT que l'`exit 0` ne serve de preuve) |
| Criteres de test leves | **1, 2, 3, 4, 5, 6** (tous conditionnes AVANT `PUT`) |
| Date | **2026-07-27** — horodatages UTC dans chaque bloc |
| Branche | `feat/US-00.7-application-protection-branche` |
| Sequence | ce fichier **precede** l'usage de l'`exit 0` comme preuve (AC-2) : c'est la raison d'etre de T1 |

---

## 1. Le defaut NB-1 — enonce exact, verifie dans le code

`compare()` ne parcourt que les cles **de la cible** (`if key not in expected: continue` pour les
booleens, `if isinstance(exp_rsc, dict)`, `if isinstance(exp_prr, dict)`, `if "restrictions" in
expected`). En regard, `_guard_actual()` filtrait la reponse **reelle** avec la constante
**STATIQUE** `MAPPED_TOP_KEYS`. Une cle **mappee mais absente de la cible** etait donc **doublement
sautee** : ni comparee, ni signalee -> **exit 0 « conforme »** sur une comparaison incomplete.

C'etait le **chemin nominal** du comparateur — celui-la meme que l'AC-2 de cette US s'apprete a
invoquer **comme preuve d'un etat de securite**. D'ou l'ordre impose : le correctif **precede** la
preuve.

---

## 2. Le correctif — diff exact (`git diff scripts/check_branch_protection.py`)

**3 lignes de code** : signature, intersection, site d'appel. Le decompte « une ligne » propage par
le rapport de re-audit d'US-00.4 et par la dette NB-1 de `CLAUDE.md` **etait faux** :
`_guard_actual(actual)` n'avait **pas acces** a `expected` (variable locale de `run()`, passee a
`compare()`), donc la formule `MAPPED_TOP_KEYS & set(expected)` exigeait de passer `expected` en
parametre.

```diff
diff --git a/scripts/check_branch_protection.py b/scripts/check_branch_protection.py
index a1b5e62..c0f0987 100644
--- a/scripts/check_branch_protection.py
+++ b/scripts/check_branch_protection.py
@@ -492,15 +492,21 @@ def _classify_extra(obj: dict, mapped: set[str], prefix: str) -> tuple[list[str]
     return neutral, active
 
 
-def _guard_actual(actual: dict) -> tuple[list[str], list[str]]:
+def _guard_actual(actual: dict, expected: dict) -> tuple[list[str], list[str]]:
     """Garde SYMÉTRIQUE côté réponse RÉELLE — top-level ET sous-objets mappés.
 
     Les sous-objets comptent autant que la racine : `required_pull_request_reviews` porte des
     champs d'enforcement absents du mapping (`dismiss_stale_reviews`,
     `require_code_owner_reviews`, `require_last_push_approval`,
     `bypass_pull_request_allowances`…). Les ignorer aurait reproduit B-2 un niveau plus bas.
+
+    `expected` est requis pour le filtrage DYNAMIQUE de la racine (dette NB-1, cf. ci-dessous) :
+    la constante statique `MAPPED_TOP_KEYS` couvrait des clés que la cible ne portait pas.
     """
-    neutral, active = _classify_extra(actual, MAPPED_TOP_KEYS, "")
+    # NB-1 (US-00.7) : filtrer par les clés RÉELLEMENT présentes dans la cible. Avec la constante
+    # statique, une clé mappée mais ABSENTE de la cible (cible amputée) était sautée EN SILENCE —
+    # ni comparée par compare() (`if key not in expected: continue`), ni signalée ici → exit 0.
+    neutral, active = _classify_extra(actual, MAPPED_TOP_KEYS & set(expected), "")
     for parent, mapped in (
         ("required_status_checks", MAPPED_RSC_KEYS),
         ("required_pull_request_reviews", MAPPED_PRR_KEYS),
@@ -576,7 +582,7 @@ def compare(expected: dict, actual: dict) -> Comparison:
     l'exit 0 (correctif du finding B-2).
     """
     _guard_mapping(expected)
-    neutral_ignored, uncovered_active = _guard_actual(actual)
+    neutral_ignored, uncovered_active = _guard_actual(actual, expected)
     ok: list[str] = []
     diffs: list[str] = []
 
```

`git diff --stat` : **9 insertions, 3 suppressions** — **3 lignes de code** (signature l. 495,
intersection l. 503 -> 509, site d'appel l. 579 -> 585), **3 lignes de commentaire** nommant NB-1,
**2 lignes de docstring** justifiant le nouveau parametre, 1 ligne vide. Rien d'autre : pas de
garde sur les sous-objets (`MAPPED_RSC_KEYS` / `MAPPED_PRR_KEYS` restent **statiques** — un champ
manquant de la cible y ressort deja en **ecart** via `.get()`, pas en silence), pas de `selftest`,
pas de nouveau drapeau CLI, **aucun** chemin d'ecriture.

`python -m py_compile scripts/check_branch_protection.py` -> **OK**.

---

## 3. Materiel de demonstration cree — `tests/fixtures/US-00.7/`

| Fichier | Role | Nature |
|---|---|---|
| `cible_amputee_enforce_admins.json` | cible **generee** le 2026-07-27 par `--emit-branch-protection`, **moins `enforce_admins`** (7 cles) — scenarios **A** et **B** | **simulation** |
| `cible_amputee_required_pull_request_reviews.json` | idem, **moins `required_pull_request_reviews`** (7 cles) — scenario **C** | **simulation** |
| `cible_amputee_required_status_checks.json` | idem, **moins `required_status_checks`** (7 cles) — scenario **D** | **simulation** |
| `protection_enforce_admins_false.json` | reponse `GET .../protection` derivee de `tests/fixtures/US-00.4/protection_conforme.json`, **seul** `enforce_admins.enabled` passe a `false` (**relachement reel** : bypass admin autorise) — scenario **B** | **simulation** |
| `protection_sans_required_pull_request_reviews.json` | idem, `required_pull_request_reviews` **retire** (**aucune PR exigee**) — scenario **C** | **simulation** |
| `protection_403_plan_body.json` | **corps** de la preuve certifiee `reports/US-00.4/protection_api_403.json`, isole par `grep -v '^#'` pour redevenir parsable | **corps de preuve datee** (2026-07-26) |
| `nb1_harness.py` | harnais : **injecte** la cible simulee (substitution de `load_expected`) puis appelle `run()` en mode fixture | **outil de simulation** |
| `README.md` | avertissement : simulations, **jamais** des preuves d'etat reel | doc |

**Ajouts au materiel prescrit par T1(b), et pourquoi.** Le Story File ne nomme qu'une fixture de
cible amputee. Le **critere de test n° 5** exige, lui, de **demontrer** (et non seulement de
documenter) que les scenarios **B** et **C** restent en `exit 0` apres correctif : cela impose deux
cibles amputees supplementaires et deux reponses `GET` relachees. `protection_403_plan_body.json`
sert au rejeu du chemin **403**, **plus reproductible in vivo** depuis que le depot est public. Ces
5 ajouts sont **du materiel de test** : ils ne changent ni le correctif ni son perimetre.

**Trois contraintes de construction, a ne pas perdre** :

1. **Aucun commentaire JSON dans une cible.** `_guard_mapping()` leve `MappingGap` sur **toute** cle
   de la cible hors mapping — `_fixture` comprise. Une cible portant un en-tete de commentaire
   sortirait donc en **exit 2 pour un motif etranger a NB-1**, ce qui **ruinerait la demonstration du
   faux vert**. Solution retenue : la metadonnee `_fixture` figure dans le fichier mais est
   **retiree par le harnais avant injection** (meme convention `INERT_KEY_PREFIX` que le
   comparateur), et le harnais **imprime** ce qu'il a retire. *Ecart avec la lettre de T1(a), qui
   demandait la fixture « en-tetee d'un commentaire de fixture » : impossible sans casser la
   demonstration — resolu par le retrait au chargement, et signale ici.*
2. **Le harnais refuse une cible complete** (`_assert_amputee`) : il ne peut pas, meme par erreur,
   simuler la cible generee reelle.
3. **Les fixtures derivent de la cible generee** — donc, comme celles d'US-00.4 (risque **R4**), si
   `status_checks` ou `branch_protection` evoluent dans `factory.config.json`, elles **echoueront
   bruyamment**. C'est preferable au silence.

---

## 4. T1(c) — **AVANT** correctif : le faux vert est reproduit

Les **4** scenarios de la sonde @Architect sortent en **exit 0** — dont deux qui sont des
**relachements reels** de l'enforcement.

```text
--------------------------------------------------------------------------------------------
 [A/AVANT] cible amputee de enforce_admins · reel {"enabled": true} (DURCI) — code de sortie ATTENDU : 0
 $ python tests/fixtures/US-00.7/nb1_harness.py
 Horodatage UTC : 2026-07-28T06:57:09Z
--------------------------------------------------------------------------------------------
[SIMULATION] ======================================================================================
[SIMULATION] HARNAIS NB-1 (US-00.7 T1) — cible SIMULÉE INJECTÉE, aucun appel réseau, aucune preuve.
[SIMULATION]   Cible simulée      : tests/fixtures/US-00.7/cible_amputee_enforce_admins.json
[SIMULATION]   Clés injectées     : 7 — allow_deletions, allow_force_pushes, required_conversation_resolution, required_linear_history, required_pull_request_reviews, required_status_checks, restrictions
[SIMULATION]   Clés AMPUTÉES      : enforce_admins  (mappées mais absentes de la cible)
[SIMULATION]   Métadonnées ôtées  : _fixture
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/protection_conforme.json
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json
[SIMULATION]   Verrou réseau      : make_reader / _get_via_gh / _get_via_urllib remplacés par un LEVÉ
[SIMULATION] ======================================================================================
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/protection_conforme.json (statut simulé : 200)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 11 champ(s) alignés, 0 écart(s), 6 champ(s) additionnel(s) neutre(s), 0 champ(s) ACTIF(S) non couvert(s).
[SIMULATION]   [OK] required_status_checks.strict | true | true
[SIMULATION]   [OK] required_status_checks.contexts | "check-branch-name" | "check-branch-name"
[SIMULATION]   [OK] required_status_checks.contexts | "📋 Governance (SCB + traçabilité + synchro)" | "📋 Governance (SCB + traçabilité + synchro)"
[SIMULATION]   [OK] required_status_checks.contexts | "📱 App (gates run_gates.py)" | "📱 App (gates run_gates.py)"
[SIMULATION]   [OK] required_status_checks.contexts | "🔐 Secrets scan (gitleaks)" | "🔐 Secrets scan (gitleaks)"
[SIMULATION]   [OK] required_pull_request_reviews.required_approving_review_count | 0 | 0
[SIMULATION]   [OK] allow_force_pushes (GET: allow_force_pushes.enabled) | false | false
[SIMULATION]   [OK] allow_deletions (GET: allow_deletions.enabled) | false | false
[SIMULATION]   [OK] required_linear_history (GET: required_linear_history.enabled) | false | false
[SIMULATION]   [OK] required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | true
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION]   [IGNORÉ — NEUTRE] champs de la réponse hors mapping, dont la valeur ne peut ni durcir ni relâcher l'enforcement : allow_fork_syncing, block_creations, lock_branch, required_pull_request_reviews.dismiss_stale_reviews, required_pull_request_reviews.require_code_owner_reviews, required_pull_request_reviews.require_last_push_approval
[SIMULATION] conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt
[SIMULATION] --------------------------------------------------------------------------------------
[SIMULATION] CODE DE SORTIE DU COMPARATEUR : 0
[SIMULATION] Lecture : 0 = « conforme » (interdit sur une comparaison incomplète) · 1 = dérive · 2 = vérification impossible.
[SIMULATION] --------------------------------------------------------------------------------------
  -> code de sortie OBTENU : 0 (attendu 0)  [OK]

--------------------------------------------------------------------------------------------
 [B/AVANT] cible amputee de enforce_admins · reel {"enabled": false} (RELACHE) — code de sortie ATTENDU : 0
 $ python tests/fixtures/US-00.7/nb1_harness.py --protection tests/fixtures/US-00.7/protection_enforce_admins_false.json
 Horodatage UTC : 2026-07-28T06:57:10Z
--------------------------------------------------------------------------------------------
[SIMULATION] ======================================================================================
[SIMULATION] HARNAIS NB-1 (US-00.7 T1) — cible SIMULÉE INJECTÉE, aucun appel réseau, aucune preuve.
[SIMULATION]   Cible simulée      : tests/fixtures/US-00.7/cible_amputee_enforce_admins.json
[SIMULATION]   Clés injectées     : 7 — allow_deletions, allow_force_pushes, required_conversation_resolution, required_linear_history, required_pull_request_reviews, required_status_checks, restrictions
[SIMULATION]   Clés AMPUTÉES      : enforce_admins  (mappées mais absentes de la cible)
[SIMULATION]   Métadonnées ôtées  : _fixture
[SIMULATION]   Fixture protection : tests/fixtures/US-00.7/protection_enforce_admins_false.json
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json
[SIMULATION]   Verrou réseau      : make_reader / _get_via_gh / _get_via_urllib remplacés par un LEVÉ
[SIMULATION] ======================================================================================
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.7/protection_enforce_admins_false.json (statut simulé : 200)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 11 champ(s) alignés, 0 écart(s), 6 champ(s) additionnel(s) neutre(s), 0 champ(s) ACTIF(S) non couvert(s).
[SIMULATION]   [OK] required_status_checks.strict | true | true
[SIMULATION]   [OK] required_status_checks.contexts | "check-branch-name" | "check-branch-name"
[SIMULATION]   [OK] required_status_checks.contexts | "📋 Governance (SCB + traçabilité + synchro)" | "📋 Governance (SCB + traçabilité + synchro)"
[SIMULATION]   [OK] required_status_checks.contexts | "📱 App (gates run_gates.py)" | "📱 App (gates run_gates.py)"
[SIMULATION]   [OK] required_status_checks.contexts | "🔐 Secrets scan (gitleaks)" | "🔐 Secrets scan (gitleaks)"
[SIMULATION]   [OK] required_pull_request_reviews.required_approving_review_count | 0 | 0
[SIMULATION]   [OK] allow_force_pushes (GET: allow_force_pushes.enabled) | false | false
[SIMULATION]   [OK] allow_deletions (GET: allow_deletions.enabled) | false | false
[SIMULATION]   [OK] required_linear_history (GET: required_linear_history.enabled) | false | false
[SIMULATION]   [OK] required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | true
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION]   [IGNORÉ — NEUTRE] champs de la réponse hors mapping, dont la valeur ne peut ni durcir ni relâcher l'enforcement : allow_fork_syncing, block_creations, lock_branch, required_pull_request_reviews.dismiss_stale_reviews, required_pull_request_reviews.require_code_owner_reviews, required_pull_request_reviews.require_last_push_approval
[SIMULATION] conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt
[SIMULATION] --------------------------------------------------------------------------------------
[SIMULATION] CODE DE SORTIE DU COMPARATEUR : 0
[SIMULATION] Lecture : 0 = « conforme » (interdit sur une comparaison incomplète) · 1 = dérive · 2 = vérification impossible.
[SIMULATION] --------------------------------------------------------------------------------------
  -> code de sortie OBTENU : 0 (attendu 0)  [OK]

--------------------------------------------------------------------------------------------
 [C/AVANT] cible amputee de required_pull_request_reviews · reel ABSENT (aucune PR exigee) — code de sortie ATTENDU : 0
 $ python tests/fixtures/US-00.7/nb1_harness.py --target tests/fixtures/US-00.7/cible_amputee_required_pull_request_reviews.json --protection tests/fixtures/US-00.7/protection_sans_required_pull_request_reviews.json
 Horodatage UTC : 2026-07-28T06:57:11Z
--------------------------------------------------------------------------------------------
[SIMULATION] ======================================================================================
[SIMULATION] HARNAIS NB-1 (US-00.7 T1) — cible SIMULÉE INJECTÉE, aucun appel réseau, aucune preuve.
[SIMULATION]   Cible simulée      : tests/fixtures/US-00.7/cible_amputee_required_pull_request_reviews.json
[SIMULATION]   Clés injectées     : 7 — allow_deletions, allow_force_pushes, enforce_admins, required_conversation_resolution, required_linear_history, required_status_checks, restrictions
[SIMULATION]   Clés AMPUTÉES      : required_pull_request_reviews  (mappées mais absentes de la cible)
[SIMULATION]   Métadonnées ôtées  : _fixture
[SIMULATION]   Fixture protection : tests/fixtures/US-00.7/protection_sans_required_pull_request_reviews.json
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json
[SIMULATION]   Verrou réseau      : make_reader / _get_via_gh / _get_via_urllib remplacés par un LEVÉ
[SIMULATION] ======================================================================================
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.7/protection_sans_required_pull_request_reviews.json (statut simulé : 200)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 11 champ(s) alignés, 0 écart(s), 3 champ(s) additionnel(s) neutre(s), 0 champ(s) ACTIF(S) non couvert(s).
[SIMULATION]   [OK] required_status_checks.strict | true | true
[SIMULATION]   [OK] required_status_checks.contexts | "check-branch-name" | "check-branch-name"
[SIMULATION]   [OK] required_status_checks.contexts | "📋 Governance (SCB + traçabilité + synchro)" | "📋 Governance (SCB + traçabilité + synchro)"
[SIMULATION]   [OK] required_status_checks.contexts | "📱 App (gates run_gates.py)" | "📱 App (gates run_gates.py)"
[SIMULATION]   [OK] required_status_checks.contexts | "🔐 Secrets scan (gitleaks)" | "🔐 Secrets scan (gitleaks)"
[SIMULATION]   [OK] enforce_admins (GET: enforce_admins.enabled) | true | true
[SIMULATION]   [OK] allow_force_pushes (GET: allow_force_pushes.enabled) | false | false
[SIMULATION]   [OK] allow_deletions (GET: allow_deletions.enabled) | false | false
[SIMULATION]   [OK] required_linear_history (GET: required_linear_history.enabled) | false | false
[SIMULATION]   [OK] required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | true
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION]   [IGNORÉ — NEUTRE] champs de la réponse hors mapping, dont la valeur ne peut ni durcir ni relâcher l'enforcement : allow_fork_syncing, block_creations, lock_branch
[SIMULATION] conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt
[SIMULATION] --------------------------------------------------------------------------------------
[SIMULATION] CODE DE SORTIE DU COMPARATEUR : 0
[SIMULATION] Lecture : 0 = « conforme » (interdit sur une comparaison incomplète) · 1 = dérive · 2 = vérification impossible.
[SIMULATION] --------------------------------------------------------------------------------------
  -> code de sortie OBTENU : 0 (attendu 0)  [OK]

--------------------------------------------------------------------------------------------
 [D/AVANT] cible amputee de required_status_checks · reel PRESENT (4 contextes) — code de sortie ATTENDU : 0
 $ python tests/fixtures/US-00.7/nb1_harness.py --target tests/fixtures/US-00.7/cible_amputee_required_status_checks.json
 Horodatage UTC : 2026-07-28T06:57:12Z
--------------------------------------------------------------------------------------------
[SIMULATION] ======================================================================================
[SIMULATION] HARNAIS NB-1 (US-00.7 T1) — cible SIMULÉE INJECTÉE, aucun appel réseau, aucune preuve.
[SIMULATION]   Cible simulée      : tests/fixtures/US-00.7/cible_amputee_required_status_checks.json
[SIMULATION]   Clés injectées     : 7 — allow_deletions, allow_force_pushes, enforce_admins, required_conversation_resolution, required_linear_history, required_pull_request_reviews, restrictions
[SIMULATION]   Clés AMPUTÉES      : required_status_checks  (mappées mais absentes de la cible)
[SIMULATION]   Métadonnées ôtées  : _fixture
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/protection_conforme.json
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json
[SIMULATION]   Verrou réseau      : make_reader / _get_via_gh / _get_via_urllib remplacés par un LEVÉ
[SIMULATION] ======================================================================================
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/protection_conforme.json (statut simulé : 200)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 7 champ(s) alignés, 0 écart(s), 6 champ(s) additionnel(s) neutre(s), 0 champ(s) ACTIF(S) non couvert(s).
[SIMULATION]   [OK] required_pull_request_reviews.required_approving_review_count | 0 | 0
[SIMULATION]   [OK] enforce_admins (GET: enforce_admins.enabled) | true | true
[SIMULATION]   [OK] allow_force_pushes (GET: allow_force_pushes.enabled) | false | false
[SIMULATION]   [OK] allow_deletions (GET: allow_deletions.enabled) | false | false
[SIMULATION]   [OK] required_linear_history (GET: required_linear_history.enabled) | false | false
[SIMULATION]   [OK] required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | true
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION]   [IGNORÉ — NEUTRE] champs de la réponse hors mapping, dont la valeur ne peut ni durcir ni relâcher l'enforcement : allow_fork_syncing, block_creations, lock_branch, required_pull_request_reviews.dismiss_stale_reviews, required_pull_request_reviews.require_code_owner_reviews, required_pull_request_reviews.require_last_push_approval
[SIMULATION] conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt
[SIMULATION] --------------------------------------------------------------------------------------
[SIMULATION] CODE DE SORTIE DU COMPARATEUR : 0
[SIMULATION] Lecture : 0 = « conforme » (interdit sur une comparaison incomplète) · 1 = dérive · 2 = vérification impossible.
[SIMULATION] --------------------------------------------------------------------------------------
  -> code de sortie OBTENU : 0 (attendu 0)  [OK]
```

**Lecture du scenario A avant correctif** : `11 champ(s) alignes, 0 ecart(s), 6 champ(s)
additionnel(s) neutre(s), 0 champ(s) ACTIF(S) non couvert(s)` — le comparateur annonce
**« conforme »** alors que `enforce_admins` **n'apparait nulle part** : ni dans les `[OK]`, ni dans
les ecarts, ni dans les `[IGNORE — NEUTRE]`. C'est **exactement** la definition du trou NB-1 : une
cle de securite **effacee du champ de vision** du controle.

---

## 5. T1(e) — **APRES** correctif : memes commandes, issues mesurees

```text
--------------------------------------------------------------------------------------------
 [A/APRES] cible amputee de enforce_admins · reel {"enabled": true} (DURCI) — code de sortie ATTENDU : 2
 $ python tests/fixtures/US-00.7/nb1_harness.py
 Horodatage UTC : 2026-07-28T06:59:49Z
--------------------------------------------------------------------------------------------
[SIMULATION] ======================================================================================
[SIMULATION] HARNAIS NB-1 (US-00.7 T1) — cible SIMULÉE INJECTÉE, aucun appel réseau, aucune preuve.
[SIMULATION]   Cible simulée      : tests/fixtures/US-00.7/cible_amputee_enforce_admins.json
[SIMULATION]   Clés injectées     : 7 — allow_deletions, allow_force_pushes, required_conversation_resolution, required_linear_history, required_pull_request_reviews, required_status_checks, restrictions
[SIMULATION]   Clés AMPUTÉES      : enforce_admins  (mappées mais absentes de la cible)
[SIMULATION]   Métadonnées ôtées  : _fixture
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/protection_conforme.json
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json
[SIMULATION]   Verrou réseau      : make_reader / _get_via_gh / _get_via_urllib remplacés par un LEVÉ
[SIMULATION] ======================================================================================
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/protection_conforme.json (statut simulé : 200)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 11 champ(s) alignés, 0 écart(s), 6 champ(s) additionnel(s) neutre(s), 1 champ(s) ACTIF(S) non couvert(s).
[SIMULATION]   [OK] required_status_checks.strict | true | true
[SIMULATION]   [OK] required_status_checks.contexts | "check-branch-name" | "check-branch-name"
[SIMULATION]   [OK] required_status_checks.contexts | "📋 Governance (SCB + traçabilité + synchro)" | "📋 Governance (SCB + traçabilité + synchro)"
[SIMULATION]   [OK] required_status_checks.contexts | "📱 App (gates run_gates.py)" | "📱 App (gates run_gates.py)"
[SIMULATION]   [OK] required_status_checks.contexts | "🔐 Secrets scan (gitleaks)" | "🔐 Secrets scan (gitleaks)"
[SIMULATION]   [OK] required_pull_request_reviews.required_approving_review_count | 0 | 0
[SIMULATION]   [OK] allow_force_pushes (GET: allow_force_pushes.enabled) | false | false
[SIMULATION]   [OK] allow_deletions (GET: allow_deletions.enabled) | false | false
[SIMULATION]   [OK] required_linear_history (GET: required_linear_history.enabled) | false | false
[SIMULATION]   [OK] required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | true
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION]   [IGNORÉ — NEUTRE] champs de la réponse hors mapping, dont la valeur ne peut ni durcir ni relâcher l'enforcement : allow_fork_syncing, block_creations, lock_branch, required_pull_request_reviews.dismiss_stale_reviews, required_pull_request_reviews.require_code_owner_reviews, required_pull_request_reviews.require_last_push_approval
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Code HTTP : 200 — MAPPING INCOMPLET — la réponse GET porte 1 champ(s) ACTIF(S) non couvert(s) par le mapping PUT → GET d'US-00.4 : enforce_admins = {"enabled": true}. Ces champs peuvent modifier l'enforcement réel de la branche (ex. `lock_branch` verrouille toute écriture, `bypass_pull_request_allowances` dispense de PR) : la comparaison est INCOMPLÈTE et ne peut donc RIEN conclure
[SIMULATION]   Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte).
[SIMULATION] --------------------------------------------------------------------------------------
[SIMULATION] CODE DE SORTIE DU COMPARATEUR : 2
[SIMULATION] Lecture : 0 = « conforme » (interdit sur une comparaison incomplète) · 1 = dérive · 2 = vérification impossible.
[SIMULATION] --------------------------------------------------------------------------------------
  -> code de sortie OBTENU : 2 (attendu 2)  [OK]

--------------------------------------------------------------------------------------------
 [B/APRES] cible amputee de enforce_admins · reel {"enabled": false} (RELACHE) — code de sortie ATTENDU : 0
 $ python tests/fixtures/US-00.7/nb1_harness.py --protection tests/fixtures/US-00.7/protection_enforce_admins_false.json
 Horodatage UTC : 2026-07-28T06:59:51Z
--------------------------------------------------------------------------------------------
[SIMULATION] ======================================================================================
[SIMULATION] HARNAIS NB-1 (US-00.7 T1) — cible SIMULÉE INJECTÉE, aucun appel réseau, aucune preuve.
[SIMULATION]   Cible simulée      : tests/fixtures/US-00.7/cible_amputee_enforce_admins.json
[SIMULATION]   Clés injectées     : 7 — allow_deletions, allow_force_pushes, required_conversation_resolution, required_linear_history, required_pull_request_reviews, required_status_checks, restrictions
[SIMULATION]   Clés AMPUTÉES      : enforce_admins  (mappées mais absentes de la cible)
[SIMULATION]   Métadonnées ôtées  : _fixture
[SIMULATION]   Fixture protection : tests/fixtures/US-00.7/protection_enforce_admins_false.json
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json
[SIMULATION]   Verrou réseau      : make_reader / _get_via_gh / _get_via_urllib remplacés par un LEVÉ
[SIMULATION] ======================================================================================
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.7/protection_enforce_admins_false.json (statut simulé : 200)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 11 champ(s) alignés, 0 écart(s), 7 champ(s) additionnel(s) neutre(s), 0 champ(s) ACTIF(S) non couvert(s).
[SIMULATION]   [OK] required_status_checks.strict | true | true
[SIMULATION]   [OK] required_status_checks.contexts | "check-branch-name" | "check-branch-name"
[SIMULATION]   [OK] required_status_checks.contexts | "📋 Governance (SCB + traçabilité + synchro)" | "📋 Governance (SCB + traçabilité + synchro)"
[SIMULATION]   [OK] required_status_checks.contexts | "📱 App (gates run_gates.py)" | "📱 App (gates run_gates.py)"
[SIMULATION]   [OK] required_status_checks.contexts | "🔐 Secrets scan (gitleaks)" | "🔐 Secrets scan (gitleaks)"
[SIMULATION]   [OK] required_pull_request_reviews.required_approving_review_count | 0 | 0
[SIMULATION]   [OK] allow_force_pushes (GET: allow_force_pushes.enabled) | false | false
[SIMULATION]   [OK] allow_deletions (GET: allow_deletions.enabled) | false | false
[SIMULATION]   [OK] required_linear_history (GET: required_linear_history.enabled) | false | false
[SIMULATION]   [OK] required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | true
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION]   [IGNORÉ — NEUTRE] champs de la réponse hors mapping, dont la valeur ne peut ni durcir ni relâcher l'enforcement : allow_fork_syncing, block_creations, enforce_admins, lock_branch, required_pull_request_reviews.dismiss_stale_reviews, required_pull_request_reviews.require_code_owner_reviews, required_pull_request_reviews.require_last_push_approval
[SIMULATION] conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt
[SIMULATION] --------------------------------------------------------------------------------------
[SIMULATION] CODE DE SORTIE DU COMPARATEUR : 0
[SIMULATION] Lecture : 0 = « conforme » (interdit sur une comparaison incomplète) · 1 = dérive · 2 = vérification impossible.
[SIMULATION] --------------------------------------------------------------------------------------
  -> code de sortie OBTENU : 0 (attendu 0)  [OK]

--------------------------------------------------------------------------------------------
 [C/APRES] cible amputee de required_pull_request_reviews · reel ABSENT (aucune PR exigee) — code de sortie ATTENDU : 0
 $ python tests/fixtures/US-00.7/nb1_harness.py --target tests/fixtures/US-00.7/cible_amputee_required_pull_request_reviews.json --protection tests/fixtures/US-00.7/protection_sans_required_pull_request_reviews.json
 Horodatage UTC : 2026-07-28T06:59:53Z
--------------------------------------------------------------------------------------------
[SIMULATION] ======================================================================================
[SIMULATION] HARNAIS NB-1 (US-00.7 T1) — cible SIMULÉE INJECTÉE, aucun appel réseau, aucune preuve.
[SIMULATION]   Cible simulée      : tests/fixtures/US-00.7/cible_amputee_required_pull_request_reviews.json
[SIMULATION]   Clés injectées     : 7 — allow_deletions, allow_force_pushes, enforce_admins, required_conversation_resolution, required_linear_history, required_status_checks, restrictions
[SIMULATION]   Clés AMPUTÉES      : required_pull_request_reviews  (mappées mais absentes de la cible)
[SIMULATION]   Métadonnées ôtées  : _fixture
[SIMULATION]   Fixture protection : tests/fixtures/US-00.7/protection_sans_required_pull_request_reviews.json
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json
[SIMULATION]   Verrou réseau      : make_reader / _get_via_gh / _get_via_urllib remplacés par un LEVÉ
[SIMULATION] ======================================================================================
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.7/protection_sans_required_pull_request_reviews.json (statut simulé : 200)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 11 champ(s) alignés, 0 écart(s), 3 champ(s) additionnel(s) neutre(s), 0 champ(s) ACTIF(S) non couvert(s).
[SIMULATION]   [OK] required_status_checks.strict | true | true
[SIMULATION]   [OK] required_status_checks.contexts | "check-branch-name" | "check-branch-name"
[SIMULATION]   [OK] required_status_checks.contexts | "📋 Governance (SCB + traçabilité + synchro)" | "📋 Governance (SCB + traçabilité + synchro)"
[SIMULATION]   [OK] required_status_checks.contexts | "📱 App (gates run_gates.py)" | "📱 App (gates run_gates.py)"
[SIMULATION]   [OK] required_status_checks.contexts | "🔐 Secrets scan (gitleaks)" | "🔐 Secrets scan (gitleaks)"
[SIMULATION]   [OK] enforce_admins (GET: enforce_admins.enabled) | true | true
[SIMULATION]   [OK] allow_force_pushes (GET: allow_force_pushes.enabled) | false | false
[SIMULATION]   [OK] allow_deletions (GET: allow_deletions.enabled) | false | false
[SIMULATION]   [OK] required_linear_history (GET: required_linear_history.enabled) | false | false
[SIMULATION]   [OK] required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | true
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION]   [IGNORÉ — NEUTRE] champs de la réponse hors mapping, dont la valeur ne peut ni durcir ni relâcher l'enforcement : allow_fork_syncing, block_creations, lock_branch
[SIMULATION] conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt
[SIMULATION] --------------------------------------------------------------------------------------
[SIMULATION] CODE DE SORTIE DU COMPARATEUR : 0
[SIMULATION] Lecture : 0 = « conforme » (interdit sur une comparaison incomplète) · 1 = dérive · 2 = vérification impossible.
[SIMULATION] --------------------------------------------------------------------------------------
  -> code de sortie OBTENU : 0 (attendu 0)  [OK]

--------------------------------------------------------------------------------------------
 [D/APRES] cible amputee de required_status_checks · reel PRESENT (4 contextes) — code de sortie ATTENDU : 2
 $ python tests/fixtures/US-00.7/nb1_harness.py --target tests/fixtures/US-00.7/cible_amputee_required_status_checks.json
 Horodatage UTC : 2026-07-28T06:59:54Z
--------------------------------------------------------------------------------------------
[SIMULATION] ======================================================================================
[SIMULATION] HARNAIS NB-1 (US-00.7 T1) — cible SIMULÉE INJECTÉE, aucun appel réseau, aucune preuve.
[SIMULATION]   Cible simulée      : tests/fixtures/US-00.7/cible_amputee_required_status_checks.json
[SIMULATION]   Clés injectées     : 7 — allow_deletions, allow_force_pushes, enforce_admins, required_conversation_resolution, required_linear_history, required_pull_request_reviews, restrictions
[SIMULATION]   Clés AMPUTÉES      : required_status_checks  (mappées mais absentes de la cible)
[SIMULATION]   Métadonnées ôtées  : _fixture
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/protection_conforme.json
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json
[SIMULATION]   Verrou réseau      : make_reader / _get_via_gh / _get_via_urllib remplacés par un LEVÉ
[SIMULATION] ======================================================================================
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/protection_conforme.json (statut simulé : 200)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 7 champ(s) alignés, 0 écart(s), 6 champ(s) additionnel(s) neutre(s), 1 champ(s) ACTIF(S) non couvert(s).
[SIMULATION]   [OK] required_pull_request_reviews.required_approving_review_count | 0 | 0
[SIMULATION]   [OK] enforce_admins (GET: enforce_admins.enabled) | true | true
[SIMULATION]   [OK] allow_force_pushes (GET: allow_force_pushes.enabled) | false | false
[SIMULATION]   [OK] allow_deletions (GET: allow_deletions.enabled) | false | false
[SIMULATION]   [OK] required_linear_history (GET: required_linear_history.enabled) | false | false
[SIMULATION]   [OK] required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | true
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION]   [IGNORÉ — NEUTRE] champs de la réponse hors mapping, dont la valeur ne peut ni durcir ni relâcher l'enforcement : allow_fork_syncing, block_creations, lock_branch, required_pull_request_reviews.dismiss_stale_reviews, required_pull_request_reviews.require_code_owner_reviews, required_pull_request_reviews.require_last_push_approval
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Code HTTP : 200 — MAPPING INCOMPLET — la réponse GET porte 1 champ(s) ACTIF(S) non couvert(s) par le mapping PUT → GET d'US-00.4 : required_status_checks = {"url": "https://api.github.com/repos/OWNER/REPO/branches/main/protection/required_status_checks", "strict": true, "c…. Ces champs peuvent modifier l'enforcement réel de la branche (ex. `lock_branch` verrouille toute écriture, `bypass_pull_request_allowances` dispense de PR) : la comparaison est INCOMPLÈTE et ne peut donc RIEN conclure
[SIMULATION]   Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte).
[SIMULATION] --------------------------------------------------------------------------------------
[SIMULATION] CODE DE SORTIE DU COMPARATEUR : 2
[SIMULATION] Lecture : 0 = « conforme » (interdit sur une comparaison incomplète) · 1 = dérive · 2 = vérification impossible.
[SIMULATION] --------------------------------------------------------------------------------------
  -> code de sortie OBTENU : 2 (attendu 2)  [OK]
```

### 5.1 Tableau avant / apres — **codes de sortie reels**, pas annonces

| Scenario | Cible amputee de | Valeur reelle | AVANT | APRES | Cle nommee ? | Verdict |
|---|---|---|---|---|---|---|
| **A** | `enforce_admins` | `{"enabled": true}` — **durci** | **exit 0** « conforme » | **exit 2** `MAPPING INCOMPLET` | **OUI** : `enforce_admins = {"enabled": true}` | **corrige** |
| **B** | `enforce_admins` | `{"enabled": false}` — **relache** (*bypass admin autorise*) | **exit 0**, cle **non nommee** | **exit 0**, cle nommee `[IGNORE — NEUTRE]` | **OUI** (progres partiel) | **NON corrige** |
| **C** | `required_pull_request_reviews` | **absente** — *aucune PR exigee* | **exit 0**, cle non nommee | **exit 0**, cle **toujours pas nommee** | **NON** | **NON corrige** |
| **D** | `required_status_checks` | **presente** (4 contextes) | **exit 0** « conforme » | **exit 2** `MAPPING INCOMPLET` | **OUI** : `required_status_checks = {...}` | **corrige** |

Preuves de lecture, extraites des blocs ci-dessus :

* **A / APRES** — `Code HTTP : 200 — MAPPING INCOMPLET — la reponse GET porte 1 champ(s) ACTIF(S) non
  couvert(s) ... : enforce_admins = {"enabled": true}` · et le mot **« conforme » est ABSENT** du bloc
  A apres correctif (verifie : **0** occurrence de « conforme a la cible » dans le bloc `[A/APRES]`).
* **B** — la liste `[IGNORE — NEUTRE]` passe de **6** a **7** champs et gagne exactement
  `enforce_admins` : la cle est **desormais nommee**, mais l'issue **reste exit 0**.
* **C** — les deux listes `[IGNORE — NEUTRE]` sont **identiques** avant et apres
  (`allow_fork_syncing, block_creations, lock_branch`) : `required_pull_request_reviews` **n'est
  nommee ni avant ni apres**, parce qu'elle est absente **des deux cotes**. Le correctif ne peut rien
  y voir : il filtre les cles **presentes dans la reponse**.
* **D** — la cle nommee est le **conteneur entier** `required_status_checks`, tronque a 120
  caracteres par `_summarize()`.

### 5.2 Le correctif est un **progres strict**, PAS une fermeture — dette **NB-1bis**, OUVERTE

L'AC-7 nominal affirme qu'une cle absente de la cible « **est nommee et interdit l'exit 0** ».
**C'est vrai uniquement si sa valeur reelle est ACTIVE.** Mesure ci-dessus :

* sur un **relachement** — `enforce_admins: {"enabled": false}`, qui **autorise le bypass
  administrateur** — la cle est **nommee** mais **l'exit 0 subsiste** (scenario B) ;
* si la cle est **absente des deux cotes** — `required_pull_request_reviews` absente signifiant
  **aucune pull request exigee** — elle **n'est pas meme nommee** (scenario C).

Or **c'est precisement le cas decrit par la dette NB-1** de `CLAUDE.md` (« exit 0 possible sur un
**relachement** reel avec une cible amputee »). La doctrine de neutralite heritee d'US-00.4 assimile
« valeur fausse / absente » a « inerte » — ce qui est **faux pour les cles dont la permissivite *est*
le defaut**.

> **NB-1bis — dette OUVERTE.** *Correctif identifie* : ajouter dans `_guard_mapping()` un controle de
> **completude de la cible** (`MAPPED_TOP_KEYS - set(expected)` non vide -> `MappingGap` -> **exit 2** :
> une cible incomplete ne peut pas servir de reference). *Motif d'exclusion* : l'**AC-7 erreur**
> interdit tout elargissement au-dela des 3 lignes, et ce correctif **toucherait la doctrine de
> neutralite** — decision structurante, a porter par une US de dette, avec le `selftest` CI.
> *Compensation du jour* : le controle **T2** ci-dessous.

**Aucune phrase de ce rapport n'affirme que NB-1 « ferme le trou ».** Ce qui est acquis : sur une
cible amputee, une cle reelle **ACTIVE** ne peut plus etre ecartee en silence. Ce qui reste ouvert :
la meme situation avec une valeur **neutre au sens de la doctrine** mais **permissive en fait**.

---

## 6. T1(f) — **13 chemins d'US-00.4 rejoues : aucune issue ne change**

Les **12** chemins listes par le critere de test n° 3, **plus** le chemin des cles additives neutres
(critere n° 4 = critere #24 d'US-00.4). Chaque invocation porte son code de sortie **attendu** et
**obtenu**.

| # | Chemin | Attendu | Obtenu | Verdict |
|---|---|---|---|---|
| 1 | `exit 0` fixture conforme | 0 | **0** | inchange |
| 2 | `exit 1` fixture divergente (4 ecarts) | 1 | **1** | inchange |
| 3 | `exit 1` 404 + `protected:false` | 1 | **1** | inchange |
| 4 | `exit 2` 404 + `protected:true` | 2 | **2** | inchange |
| 5 | `exit 2` **403 de plan** | 2 | **2** | inchange |
| 6 | `exit 2` usage : `--from-protection` seul | 2 | **2** | inchange |
| 7 | `exit 2` usage : `--from-branch` seul | 2 | **2** | inchange |
| 8 | `exit 2` usage : `--raw-out` refuse en mode fixture (R1) | 2 | **2** | inchange |
| 9 | `exit 2` `lock_branch` actif — *le cas du faux vert B-2* | 2 | **2** | inchange |
| 10 | `exit 2` `block_creations` actif | 2 | **2** | inchange |
| 11 | `exit 2` cle inconnue active + `bypass_pull_request_allowances` non vide | 2 | **2** | inchange |
| 12 | **`exit 0` cles additives NEUTRES** — *critere #24 : l'outil ne rougit pas sur une evolution additive de l'API* | 0 | **0** | **inchange — garantie centrale** |
| 13 | `exit 2` aucun transport (`gh` hors `PATH` **et** aucun jeton) | 2 | **2** | inchange |

**13 / 13 conformes. Aucun changement d'issue**, y compris sur le chemin n° 12 : **le correctif ne
rend pas l'outil rouge sur une evolution additive neutre de l'API GitHub**. La raison est
structurelle : quand la cible est **complete** (cas de tous ces rejeux),
`MAPPED_TOP_KEYS & set(expected) == MAPPED_TOP_KEYS` — le correctif est alors **strictement neutre**.

Controle negatif associe : le fichier `INTERDIT_ne_doit_pas_etre_cree.txt` du chemin n° 8 **n'a pas
ete cree** (`ls` -> *No such file or directory*).

```text
--------------------------------------------------------------------------------------------
 [1/13] exit 0 — fixture CONFORME (200) — code de sortie ATTENDU : 0
 $ python scripts/check_branch_protection.py --from-protection tests/fixtures/US-00.4/protection_conforme.json --from-branch tests/fixtures/US-00.4/branch_protected_true.json
 Horodatage UTC : 2026-07-28T07:07:59Z
--------------------------------------------------------------------------------------------
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/protection_conforme.json (statut simulé : 200)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 12 champ(s) alignés, 0 écart(s), 6 champ(s) additionnel(s) neutre(s), 0 champ(s) ACTIF(S) non couvert(s).
[SIMULATION]   [OK] required_status_checks.strict | true | true
[SIMULATION]   [OK] required_status_checks.contexts | "check-branch-name" | "check-branch-name"
[SIMULATION]   [OK] required_status_checks.contexts | "📋 Governance (SCB + traçabilité + synchro)" | "📋 Governance (SCB + traçabilité + synchro)"
[SIMULATION]   [OK] required_status_checks.contexts | "📱 App (gates run_gates.py)" | "📱 App (gates run_gates.py)"
[SIMULATION]   [OK] required_status_checks.contexts | "🔐 Secrets scan (gitleaks)" | "🔐 Secrets scan (gitleaks)"
[SIMULATION]   [OK] required_pull_request_reviews.required_approving_review_count | 0 | 0
[SIMULATION]   [OK] enforce_admins (GET: enforce_admins.enabled) | true | true
[SIMULATION]   [OK] allow_force_pushes (GET: allow_force_pushes.enabled) | false | false
[SIMULATION]   [OK] allow_deletions (GET: allow_deletions.enabled) | false | false
[SIMULATION]   [OK] required_linear_history (GET: required_linear_history.enabled) | false | false
[SIMULATION]   [OK] required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | true
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION]   [IGNORÉ — NEUTRE] champs de la réponse hors mapping, dont la valeur ne peut ni durcir ni relâcher l'enforcement : allow_fork_syncing, block_creations, lock_branch, required_pull_request_reviews.dismiss_stale_reviews, required_pull_request_reviews.require_code_owner_reviews, required_pull_request_reviews.require_last_push_approval
[SIMULATION] conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt
  -> code de sortie OBTENU : 0 (attendu 0)  [OK]

--------------------------------------------------------------------------------------------
 [2/13] exit 1 — fixture DIVERGENTE (200, 4 ecarts) — code de sortie ATTENDU : 1
 $ python scripts/check_branch_protection.py --from-protection tests/fixtures/US-00.4/protection_divergente.json --from-branch tests/fixtures/US-00.4/branch_protected_true.json
 Horodatage UTC : 2026-07-28T07:08:00Z
--------------------------------------------------------------------------------------------
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/protection_divergente.json (statut simulé : 200)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 9 champ(s) alignés, 4 écart(s), 6 champ(s) additionnel(s) neutre(s), 0 champ(s) ACTIF(S) non couvert(s).
[SIMULATION]   [OK] required_status_checks.strict | true | true
[SIMULATION]   [OK] required_status_checks.contexts | "check-branch-name" | "check-branch-name"
[SIMULATION]   [OK] required_status_checks.contexts | "📋 Governance (SCB + traçabilité + synchro)" | "📋 Governance (SCB + traçabilité + synchro)"
[SIMULATION]   [OK] required_status_checks.contexts | "🔐 Secrets scan (gitleaks)" | "🔐 Secrets scan (gitleaks)"
[SIMULATION]   [OK] allow_force_pushes (GET: allow_force_pushes.enabled) | false | false
[SIMULATION]   [OK] allow_deletions (GET: allow_deletions.enabled) | false | false
[SIMULATION]   [OK] required_linear_history (GET: required_linear_history.enabled) | false | false
[SIMULATION]   [OK] required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | true
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION]   [IGNORÉ — NEUTRE] champs de la réponse hors mapping, dont la valeur ne peut ni durcir ni relâcher l'enforcement : allow_fork_syncing, block_creations, lock_branch, required_pull_request_reviews.dismiss_stale_reviews, required_pull_request_reviews.require_code_owner_reviews, required_pull_request_reviews.require_last_push_approval
[SIMULATION] DÉRIVE DÉTECTÉE — protection divergente sur <owner/repo SIMULÉ>:main
[SIMULATION]   4 écart(s) entre la cible générée et l'état lu :
[SIMULATION]   champ | attendu | réel
[SIMULATION]   required_status_checks.contexts (MANQUANT) | "📱 App (gates run_gates.py)" | <absent de la réponse GET>
[SIMULATION]   required_status_checks.contexts (EN TROP) | <absent de la cible générée> | "🧪 E2E smoke (nightly)"
[SIMULATION]   required_pull_request_reviews.required_approving_review_count | 0 | 1
[SIMULATION]   enforce_admins (GET: enforce_admins.enabled) | true | false
  -> code de sortie OBTENU : 1 (attendu 1)  [OK]

--------------------------------------------------------------------------------------------
 [3/13] exit 1 — 404 + protected:false (protection ABSENTE) — code de sortie ATTENDU : 1
 $ python scripts/check_branch_protection.py --from-protection tests/fixtures/US-00.4/http_404.json --from-branch tests/fixtures/US-00.4/branch_protected_false.json --from-protection-status 404
 Horodatage UTC : 2026-07-28T07:08:01Z
--------------------------------------------------------------------------------------------
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/http_404.json (statut simulé : 404)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_false.json (statut simulé : 200)
[SIMULATION] GET /repos/<owner/repo SIMULÉ>/branches/main/protection → 404 et GET /repos/<owner/repo SIMULÉ>/branches/main → "protected": false : la branche n'est réellement PAS protégée (ce n'est pas un défaut de droits).
[SIMULATION] DÉRIVE DÉTECTÉE — protection ABSENTE sur <owner/repo SIMULÉ>:main (404 + protected == false)
[SIMULATION]   7 écart(s) entre la cible générée et l'état lu :
[SIMULATION]   champ | attendu | réel
[SIMULATION]   required_status_checks | "objet présent (strict + contexts)" | <clé absente de la réponse GET — aucun status check requis>
[SIMULATION]   required_pull_request_reviews | "objet présent, required_approving_review_count=0 (pull request EXIGÉE)" | <objet absent de la réponse GET — aucune pull request exigée>
[SIMULATION]   enforce_admins (GET: enforce_admins.enabled) | true | <clé absente de la réponse GET>
[SIMULATION]   allow_force_pushes (GET: allow_force_pushes.enabled) | false | <clé absente de la réponse GET>
[SIMULATION]   allow_deletions (GET: allow_deletions.enabled) | false | <clé absente de la réponse GET>
[SIMULATION]   required_linear_history (GET: required_linear_history.enabled) | false | <clé absente de la réponse GET>
[SIMULATION]   required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | <clé absente de la réponse GET>
  -> code de sortie OBTENU : 1 (attendu 1)  [OK]

--------------------------------------------------------------------------------------------
 [4/13] exit 2 — 404 + protected:true (droits insuffisants) — code de sortie ATTENDU : 2
 $ python scripts/check_branch_protection.py --from-protection tests/fixtures/US-00.4/http_404.json --from-branch tests/fixtures/US-00.4/branch_protected_true.json --from-protection-status 404
 Horodatage UTC : 2026-07-28T07:08:02Z
--------------------------------------------------------------------------------------------
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/http_404.json (statut simulé : 404)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Code HTTP : 404 — 404 sur la protection alors que GET /repos/<owner/repo SIMULÉ>/branches/main annonce "protected": true → la protection existe mais reste ILLISIBLE : droits insuffisants (admin requis)
[SIMULATION]   Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte).
  -> code de sortie OBTENU : 2 (attendu 2)  [OK]

--------------------------------------------------------------------------------------------
 [5/13] exit 2 — 403 de PLAN (corps de la preuve certifiee US-00.4) — code de sortie ATTENDU : 2
 $ python scripts/check_branch_protection.py --from-protection tests/fixtures/US-00.7/protection_403_plan_body.json --from-branch tests/fixtures/US-00.4/branch_protected_false.json --from-protection-status 403
 Horodatage UTC : 2026-07-28T07:08:03Z
--------------------------------------------------------------------------------------------
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.7/protection_403_plan_body.json (statut simulé : 403)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_false.json (statut simulé : 200)
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Code HTTP : 403 — protection de branche INDISPONIBLE SUR CE PLAN (dépôt privé sans GitHub Pro) — ni un défaut de droits, ni un défaut de configuration : aucune commande ne peut lire ni appliquer la protection en l'état. Message API : 'Upgrade to GitHub Pro or make this repository public to enable this feature.'
[SIMULATION]   Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte).
  -> code de sortie OBTENU : 2 (attendu 2)  [OK]

--------------------------------------------------------------------------------------------
 [6/13] exit 2 — USAGE : --from-protection SEUL — code de sortie ATTENDU : 2
 $ python scripts/check_branch_protection.py --from-protection tests/fixtures/US-00.4/protection_conforme.json
 Horodatage UTC : 2026-07-28T07:08:03Z
--------------------------------------------------------------------------------------------
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Cause : ERREUR D'USAGE — --from-protection et --from-branch vont obligatoirement PAR PAIRE (l'ambiguïté du 404 se lève en croisant les deux lectures) — l'un sans l'autre est une erreur d'usage, jamais une dérive (aucun code HTTP obtenu)
[SIMULATION]   Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte).
  -> code de sortie OBTENU : 2 (attendu 2)  [OK]

--------------------------------------------------------------------------------------------
 [7/13] exit 2 — USAGE : --from-branch SEUL — code de sortie ATTENDU : 2
 $ python scripts/check_branch_protection.py --from-branch tests/fixtures/US-00.4/branch_protected_true.json
 Horodatage UTC : 2026-07-28T07:08:03Z
--------------------------------------------------------------------------------------------
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Cause : ERREUR D'USAGE — --from-protection et --from-branch vont obligatoirement PAR PAIRE (l'ambiguïté du 404 se lève en croisant les deux lectures) — l'un sans l'autre est une erreur d'usage, jamais une dérive (aucun code HTTP obtenu)
[SIMULATION]   Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte).
  -> code de sortie OBTENU : 2 (attendu 2)  [OK]

--------------------------------------------------------------------------------------------
 [8/13] exit 2 — USAGE : --raw-out REFUSE en mode fixture (R1) — code de sortie ATTENDU : 2
 $ python scripts/check_branch_protection.py --from-protection tests/fixtures/US-00.4/protection_conforme.json --from-branch tests/fixtures/US-00.4/branch_protected_true.json --raw-out INTERDIT_ne_doit_pas_etre_cree.txt
 Horodatage UTC : 2026-07-28T07:08:04Z
--------------------------------------------------------------------------------------------
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Cause : ERREUR D'USAGE — --raw-out est refusé en mode fixture : archiver une réponse SIMULÉE comme une réponse brute de l'API la rendrait relisible comme une preuve d'état réel (R1) (aucun code HTTP obtenu)
[SIMULATION]   Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte).
  -> code de sortie OBTENU : 2 (attendu 2)  [OK]

--------------------------------------------------------------------------------------------
 [9/13] exit 2 — lock_branch ACTIF (LE cas du faux vert B-2) — code de sortie ATTENDU : 2
 $ python scripts/check_branch_protection.py --from-protection tests/fixtures/US-00.4/protection_lock_branch_actif.json --from-branch tests/fixtures/US-00.4/branch_protected_true.json
 Horodatage UTC : 2026-07-28T07:08:05Z
--------------------------------------------------------------------------------------------
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/protection_lock_branch_actif.json (statut simulé : 200)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 12 champ(s) alignés, 0 écart(s), 5 champ(s) additionnel(s) neutre(s), 1 champ(s) ACTIF(S) non couvert(s).
[SIMULATION]   [OK] required_status_checks.strict | true | true
[SIMULATION]   [OK] required_status_checks.contexts | "check-branch-name" | "check-branch-name"
[SIMULATION]   [OK] required_status_checks.contexts | "📋 Governance (SCB + traçabilité + synchro)" | "📋 Governance (SCB + traçabilité + synchro)"
[SIMULATION]   [OK] required_status_checks.contexts | "📱 App (gates run_gates.py)" | "📱 App (gates run_gates.py)"
[SIMULATION]   [OK] required_status_checks.contexts | "🔐 Secrets scan (gitleaks)" | "🔐 Secrets scan (gitleaks)"
[SIMULATION]   [OK] required_pull_request_reviews.required_approving_review_count | 0 | 0
[SIMULATION]   [OK] enforce_admins (GET: enforce_admins.enabled) | true | true
[SIMULATION]   [OK] allow_force_pushes (GET: allow_force_pushes.enabled) | false | false
[SIMULATION]   [OK] allow_deletions (GET: allow_deletions.enabled) | false | false
[SIMULATION]   [OK] required_linear_history (GET: required_linear_history.enabled) | false | false
[SIMULATION]   [OK] required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | true
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION]   [IGNORÉ — NEUTRE] champs de la réponse hors mapping, dont la valeur ne peut ni durcir ni relâcher l'enforcement : allow_fork_syncing, block_creations, required_pull_request_reviews.dismiss_stale_reviews, required_pull_request_reviews.require_code_owner_reviews, required_pull_request_reviews.require_last_push_approval
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Code HTTP : 200 — MAPPING INCOMPLET — la réponse GET porte 1 champ(s) ACTIF(S) non couvert(s) par le mapping PUT → GET d'US-00.4 : lock_branch = {"enabled": true}. Ces champs peuvent modifier l'enforcement réel de la branche (ex. `lock_branch` verrouille toute écriture, `bypass_pull_request_allowances` dispense de PR) : la comparaison est INCOMPLÈTE et ne peut donc RIEN conclure
[SIMULATION]   Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte).
  -> code de sortie OBTENU : 2 (attendu 2)  [OK]

--------------------------------------------------------------------------------------------
 [10/13] exit 2 — block_creations ACTIF — code de sortie ATTENDU : 2
 $ python scripts/check_branch_protection.py --from-protection tests/fixtures/US-00.4/protection_block_creations_actif.json --from-branch tests/fixtures/US-00.4/branch_protected_true.json
 Horodatage UTC : 2026-07-28T07:08:06Z
--------------------------------------------------------------------------------------------
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/protection_block_creations_actif.json (statut simulé : 200)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 12 champ(s) alignés, 0 écart(s), 5 champ(s) additionnel(s) neutre(s), 1 champ(s) ACTIF(S) non couvert(s).
[SIMULATION]   [OK] required_status_checks.strict | true | true
[SIMULATION]   [OK] required_status_checks.contexts | "check-branch-name" | "check-branch-name"
[SIMULATION]   [OK] required_status_checks.contexts | "📋 Governance (SCB + traçabilité + synchro)" | "📋 Governance (SCB + traçabilité + synchro)"
[SIMULATION]   [OK] required_status_checks.contexts | "📱 App (gates run_gates.py)" | "📱 App (gates run_gates.py)"
[SIMULATION]   [OK] required_status_checks.contexts | "🔐 Secrets scan (gitleaks)" | "🔐 Secrets scan (gitleaks)"
[SIMULATION]   [OK] required_pull_request_reviews.required_approving_review_count | 0 | 0
[SIMULATION]   [OK] enforce_admins (GET: enforce_admins.enabled) | true | true
[SIMULATION]   [OK] allow_force_pushes (GET: allow_force_pushes.enabled) | false | false
[SIMULATION]   [OK] allow_deletions (GET: allow_deletions.enabled) | false | false
[SIMULATION]   [OK] required_linear_history (GET: required_linear_history.enabled) | false | false
[SIMULATION]   [OK] required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | true
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION]   [IGNORÉ — NEUTRE] champs de la réponse hors mapping, dont la valeur ne peut ni durcir ni relâcher l'enforcement : allow_fork_syncing, lock_branch, required_pull_request_reviews.dismiss_stale_reviews, required_pull_request_reviews.require_code_owner_reviews, required_pull_request_reviews.require_last_push_approval
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Code HTTP : 200 — MAPPING INCOMPLET — la réponse GET porte 1 champ(s) ACTIF(S) non couvert(s) par le mapping PUT → GET d'US-00.4 : block_creations = {"enabled": true}. Ces champs peuvent modifier l'enforcement réel de la branche (ex. `lock_branch` verrouille toute écriture, `bypass_pull_request_allowances` dispense de PR) : la comparaison est INCOMPLÈTE et ne peut donc RIEN conclure
[SIMULATION]   Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte).
  -> code de sortie OBTENU : 2 (attendu 2)  [OK]

--------------------------------------------------------------------------------------------
 [11/13] exit 2 — cle INCONNUE active + bypass_pull_request_allowances non vide — code de sortie ATTENDU : 2
 $ python scripts/check_branch_protection.py --from-protection tests/fixtures/US-00.4/protection_cle_inconnue_active.json --from-branch tests/fixtures/US-00.4/branch_protected_true.json
 Horodatage UTC : 2026-07-28T07:08:07Z
--------------------------------------------------------------------------------------------
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/protection_cle_inconnue_active.json (statut simulé : 200)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 12 champ(s) alignés, 0 écart(s), 6 champ(s) additionnel(s) neutre(s), 2 champ(s) ACTIF(S) non couvert(s).
[SIMULATION]   [OK] required_status_checks.strict | true | true
[SIMULATION]   [OK] required_status_checks.contexts | "check-branch-name" | "check-branch-name"
[SIMULATION]   [OK] required_status_checks.contexts | "📋 Governance (SCB + traçabilité + synchro)" | "📋 Governance (SCB + traçabilité + synchro)"
[SIMULATION]   [OK] required_status_checks.contexts | "📱 App (gates run_gates.py)" | "📱 App (gates run_gates.py)"
[SIMULATION]   [OK] required_status_checks.contexts | "🔐 Secrets scan (gitleaks)" | "🔐 Secrets scan (gitleaks)"
[SIMULATION]   [OK] required_pull_request_reviews.required_approving_review_count | 0 | 0
[SIMULATION]   [OK] enforce_admins (GET: enforce_admins.enabled) | true | true
[SIMULATION]   [OK] allow_force_pushes (GET: allow_force_pushes.enabled) | false | false
[SIMULATION]   [OK] allow_deletions (GET: allow_deletions.enabled) | false | false
[SIMULATION]   [OK] required_linear_history (GET: required_linear_history.enabled) | false | false
[SIMULATION]   [OK] required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | true
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION]   [IGNORÉ — NEUTRE] champs de la réponse hors mapping, dont la valeur ne peut ni durcir ni relâcher l'enforcement : allow_fork_syncing, block_creations, lock_branch, required_pull_request_reviews.dismiss_stale_reviews, required_pull_request_reviews.require_code_owner_reviews, required_pull_request_reviews.require_last_push_approval
[SIMULATION] VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
[SIMULATION]   Code HTTP : 200 — MAPPING INCOMPLET — la réponse GET porte 2 champ(s) ACTIF(S) non couvert(s) par le mapping PUT → GET d'US-00.4 : require_signed_commits_v2 = {"enabled": true} · required_pull_request_reviews.bypass_pull_request_allowances = {"users": [{"login": "octocat"}], "teams": [], "apps": []}. Ces champs peuvent modifier l'enforcement réel de la branche (ex. `lock_branch` verrouille toute écriture, `bypass_pull_request_allowances` dispense de PR) : la comparaison est INCOMPLÈTE et ne peut donc RIEN conclure
[SIMULATION]   Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte).
  -> code de sortie OBTENU : 2 (attendu 2)  [OK]

--------------------------------------------------------------------------------------------
 [12/13] exit 0 — cles additives NEUTRES (critere #24 US-00.4) — code de sortie ATTENDU : 0
 $ python scripts/check_branch_protection.py --from-protection tests/fixtures/US-00.4/protection_cles_additives_neutres.json --from-branch tests/fixtures/US-00.4/branch_protected_true.json
 Horodatage UTC : 2026-07-28T07:08:08Z
--------------------------------------------------------------------------------------------
[SIMULATION] Source SIMULÉE (fixtures locales) — AUCUN appel réseau, aucune lecture du dépôt réel. Cette sortie n'atteste RIEN de l'état de GitHub.
[SIMULATION]   Fixture protection : tests/fixtures/US-00.4/protection_cles_additives_neutres.json (statut simulé : 200)
[SIMULATION]   Fixture branche    : tests/fixtures/US-00.4/branch_protected_true.json (statut simulé : 200)
[SIMULATION] Comparaison champ par champ — <owner/repo SIMULÉ>:main · 12 champ(s) alignés, 0 écart(s), 10 champ(s) additionnel(s) neutre(s), 0 champ(s) ACTIF(S) non couvert(s).
[SIMULATION]   [OK] required_status_checks.strict | true | true
[SIMULATION]   [OK] required_status_checks.contexts | "check-branch-name" | "check-branch-name"
[SIMULATION]   [OK] required_status_checks.contexts | "📋 Governance (SCB + traçabilité + synchro)" | "📋 Governance (SCB + traçabilité + synchro)"
[SIMULATION]   [OK] required_status_checks.contexts | "📱 App (gates run_gates.py)" | "📱 App (gates run_gates.py)"
[SIMULATION]   [OK] required_status_checks.contexts | "🔐 Secrets scan (gitleaks)" | "🔐 Secrets scan (gitleaks)"
[SIMULATION]   [OK] required_pull_request_reviews.required_approving_review_count | 0 | 0
[SIMULATION]   [OK] enforce_admins (GET: enforce_admins.enabled) | true | true
[SIMULATION]   [OK] allow_force_pushes (GET: allow_force_pushes.enabled) | false | false
[SIMULATION]   [OK] allow_deletions (GET: allow_deletions.enabled) | false | false
[SIMULATION]   [OK] required_linear_history (GET: required_linear_history.enabled) | false | false
[SIMULATION]   [OK] required_conversation_resolution (GET: required_conversation_resolution.enabled) | true | true
[SIMULATION]   [OK] restrictions | null | <clé absente de la réponse GET — aucune restriction>
[SIMULATION]   [IGNORÉ — NEUTRE] champs de la réponse hors mapping, dont la valeur ne peut ni durcir ni relâcher l'enforcement : allow_fork_syncing, block_creations, future_flag_absent, future_liste_vide, lock_branch, require_signed_commits_v2, required_pull_request_reviews.bypass_pull_request_allowances, required_pull_request_reviews.dismiss_stale_reviews, required_pull_request_reviews.require_code_owner_reviews, required_pull_request_reviews.require_last_push_approval
[SIMULATION] conforme à la cible générée — SOURCE SIMULÉE, n'atteste PAS l'état réel du dépôt
  -> code de sortie OBTENU : 0 (attendu 0)  [OK]
--------------------------------------------------------------------------------------------
 [13/13] exit 2 — AUCUN TRANSPORT : `gh` hors PATH ET aucun jeton — code de sortie ATTENDU : 2
 $ PATH=<dossier de python uniquement>  GH_REPO=gitgdx/Concentration  (GH_TOKEN/GITHUB_TOKEN retires)
 $ python scripts/check_branch_protection.py
 Horodatage UTC : 2026-07-28T07:08:37Z
 Note : GH_REPO est fourni pour que la resolution du depot n'echoue PAS avant le transport —
        sans lui, l'exit 2 aurait pour cause « depot non resolu » (piege R-10) et non l'absence
        de transport. AUCUN appel reseau n'est emis : make_reader() leve avant toute lecture.
--------------------------------------------------------------------------------------------
VERIFICATION IMPOSSIBLE — ce n'est PAS un succès
  Cause : `gh` introuvable dans le PATH ET aucun jeton GH_TOKEN/GITHUB_TOKEN : aucune lecture de l'API n'est possible (si gh est installé, le PATH de la session est peut-être périmé — rouvrir le terminal) (aucun code HTTP obtenu)
  Portée : l'état réel de la protection n'a PAS été lu — ce constat n'atteste ni la présence, ni l'absence de dérive. À SIGNALER (dette maintenue ouverte).
  -> code de sortie OBTENU : 2 (attendu 2)  [OK]
```

---

## 7. **T2 — controle compensatoire de completude de la cible** *(c'est lui qui rend l'`exit 0` d'AC-2 fiable AUJOURD'HUI)*

```text
Horodatage UTC : 2026-07-28T07:20:36Z
$ python scripts/factory_sync.py --emit-branch-protection

1. nombre de cles du payload                 : 8   (attendu 8)
2. set(payload) == MAPPED_TOP_KEYS            : True   <-- LE controle compensatoire
   MAPPED_TOP_KEYS (8)                      : ['allow_deletions', 'allow_force_pushes', 'enforce_admins', 'required_conversation_resolution', 'required_linear_history', 'required_pull_request_reviews', 'required_status_checks', 'restrictions']
   set(payload)    (8)                      : ['allow_deletions', 'allow_force_pushes', 'enforce_admins', 'required_conversation_resolution', 'required_linear_history', 'required_pull_request_reviews', 'required_status_checks', 'restrictions']
   MAPPED_TOP_KEYS - set(payload)  (amputation) : []   (attendu : [])
   set(payload) - MAPPED_TOP_KEYS  (en trop)    : []   (attendu : [])
3. required_pull_request_reviews PRESENT      : True · required_approving_review_count = 0   (attendu 0)
4. restrictions                               : None   (attendu None/null)
5. required_status_checks.strict               : True   (attendu True)
6. nombre de contextes requis                 : 4   (attendu 4)
      - '🔐 Secrets scan (gitleaks)'
      - '📋 Governance (SCB + traçabilité + synchro)'
      - 'check-branch-name'
      - '📱 App (gates run_gates.py)'
7. enforce_admins                             : True   (attendu True)
8. _guard_mapping(payload) leve MappingGap ?  : NON — la cible est integralement couverte par le mapping PUT -> GET

$ python scripts/factory_sync.py --emit-branch-protection   (payload brut, tel quel)
{

  "required_status_checks": {

    "strict": true,

    "contexts": [

      "🔐 Secrets scan (gitleaks)",

      "📋 Governance (SCB + traçabilité + synchro)",

      "check-branch-name",

      "📱 App (gates run_gates.py)"

    ]

  },

  "required_pull_request_reviews": {

    "required_approving_review_count": 0

  },

  "enforce_admins": true,

  "restrictions": null,

  "allow_force_pushes": false,

  "allow_deletions": false,

  "required_linear_history": false,

  "required_conversation_resolution": true

}
```

### Conclusion de T2, a lire avec le §5.2

`set(payload) == MAPPED_TOP_KEYS` -> **`True`** (8 cles de part et d'autre, **aucune** amputation,
**aucune** cle en trop). Par consequent :

> **Aucun scenario B, C ou D n'est atteignable tant que la cible est complete et que
> `factory.config.json` n'est pas modifie.** Les scenarios non couverts par le correctif (B, C)
> comme ceux qu'il couvre (A, D) supposent **tous** une cible **amputee** — situation que le
> controle ci-dessus montre **inexistante aujourd'hui**.

Ce qui fonde cette completude, et ce qui la revoquerait :

* `emit_branch_protection()` (`scripts/factory_sync.py:60-77`) emet les **8** cles
  **inconditionnellement** — aucune branche de code n'en omet une ;
* `_guard_mapping()` **rejette** (exit 2) toute cle de la cible **en trop** — verifie ci-dessus :
  aucune levee de `MappingGap` sur le payload reel ;
* `factory.config.json` **n'est pas modifie par cette US** (fichier d'enforcement, **Art. 6**) ;
* **la fiabilite de l'`exit 0` d'AC-2 repose donc sur un fait verifiable en une commande**, et non
  sur la completude du correctif NB-1. NB-1bis deviendrait atteignable **le jour ou une cle serait
  retiree de `factory.config.json`** — une **action humaine** (Art. 6) : c'est a cette porte que la
  dette NB-1bis doit rester attachee.

`required_pull_request_reviews` est **present avec `0`** : consigne de non-regression d'ADR-006
decision 5 — **`0` approbation != pas de PR exigee**. Le retirer desactiverait « Require a pull
request before merging » et ferait tomber AC-3 **et** AC-4.

---

## 8. Ce que ce rapport NE prouve PAS

* **Rien sur l'etat reel du depot** : tout ici est simule. `main` n'est **pas** protegee a la date de
  ce fichier — voir `reports/US-00.7/entry_state/` (404 + `protected: false` + `--check-remote`
  **exit 1**).
* **Le correctif n'est couvert par aucun gate automatique.** Il n'existe **aucun `selftest` en CI** :
  les 21 invocations de ce rapport sont lancees **a la main**. Dette d'US-00.4 **maintenue OUVERTE** —
  elle ne disparait pas a la faveur de ce correctif.
* **`scripts/check_branch_protection.py` n'est toujours PAS couvert par
  `.claude/hooks/protect_files.sh`** : un agent peut encore l'affaiblir — dettes **#4** et **#5**
  d'US-00.4, **maintenues et re-consignees**. Leur traitement exigerait d'editer `.claude/hooks/*`
  (**Art. 6**) : action humaine, hors perimetre.
* **Aucune couverture Python n'existe** dans la factory (`adapter.components` = `app` / Flutter
  seulement) : la validation de ce correctif passe par les criteres de test sur fixtures, **jamais**
  par un seuil de couverture.
* **Rien n'est prouve sur le comportement du comparateur face a l'API reelle apres le `PUT`** : c'est
  l'objet de T9, et le risque **R-3** (une cle ACTIVE hors mapping ferait sortir en exit 2) reste
  entier.
