# Fixtures US-00.7 — **SIMULATIONS**, jamais des preuves d'état réel (2026-07-27)

⛔ **Rien dans ce répertoire n'atteste l'état réel du dépôt.** Ce sont des cibles et des réponses
d'API **fabriquées**, destinées au seul harnais `nb1_harness.py` (T1, AC-7). Les preuves brutes
datées vivent dans `reports/US-00.7/entry_state/` et `reports/US-00.7/applied_state/`.
Toute exécution du harnais préfixe **chaque ligne** de sa sortie par `[SIMULATION] `, et le harnais
**n'émet aucun appel réseau** (`make_reader`, `_get_via_gh`, `_get_via_urllib` sont remplacés par une
fonction qui lève). Le harnais **refuse** d'injecter une cible **complète** : il ne peut pas simuler
la cible générée réelle.

| Fichier | Simule | Exerce |
|---|---|---|
| `cible_amputee_enforce_admins.json` | cible générée **moins `enforce_admins`** (7 clés) | scénarios **A** (réel `true`) et **B** (réel `false`) |
| `cible_amputee_required_pull_request_reviews.json` | cible générée **moins `required_pull_request_reviews`** | scénario **C** |
| `cible_amputee_required_status_checks.json` | cible générée **moins `required_status_checks`** | scénario **D** |
| `protection_enforce_admins_false.json` | `GET …/protection` avec `enforce_admins.enabled: false` — **bypass admin autorisé** | scénario **B** → reste **exit 0** (NB-1bis) |
| `protection_sans_required_pull_request_reviews.json` | `GET …/protection` **sans** `required_pull_request_reviews` — **aucune PR exigée** | scénario **C** → reste **exit 0** (NB-1bis) |
| `protection_403_plan_body.json` | **corps** de la preuve certifiée `reports/US-00.4/protection_api_403.json` (`grep -v '^#'`) | rejeu du chemin **403 de plan**, plus reproductible in vivo (dépôt public) |
| `nb1_harness.py` | — | injecte la cible simulée et appelle `check_branch_protection.run()` |

**Métadonnée `_fixture`** : les cibles la portent en en-tête, et le harnais **la retire avant
injection**. Raison : `_guard_mapping()` lève `MappingGap` sur **toute** clé de la cible hors mapping
— une cible commentée sortirait en **exit 2 pour un motif étranger à NB-1** et ruinerait la
démonstration du faux vert.

**Dérive assumée (risque R4 d'US-00.4)** : ces fixtures sont des **instantanés dérivés une seule
fois** de la cible générée et de `tests/fixtures/US-00.4/protection_conforme.json`, par un générateur
**laissé hors du dépôt**. Si `status_checks` ou `branch_protection` évoluent dans
`factory.config.json`, elles **échoueront bruyamment** — préférable au silence d'une fixture
auto-générée qui comparerait la config à elle-même.

Aucune donnée sensible : aucun jeton, aucun en-tête `Authorization`, `OWNER/REPO` en placeholder.
