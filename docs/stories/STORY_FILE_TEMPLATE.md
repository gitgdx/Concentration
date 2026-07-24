# Story File : US-XXX — [Titre court]

> **Ce fichier est le document de référence autonome pour cette User Story.**
> Chaque intervenant peut travailler depuis ce seul fichier sans avoir à parcourir le SCB ou le backlog complet.

---

## 📋 Métadonnées

| Champ | Valeur |
|---|---|
| **ID** | US-XXX |
| **EPIC** | EPIC_XX — Nom de l'EPIC |
| **Priorité MoSCoW** | Must-Have / Should-Have / Could-Have |
| **Track** | QUICK / STANDARD / FULL (voir `docs/governance/TRACKS.md`) |
| **Phase SCB** | `business_alignment` → `technical_validation` → … |
| **Story File créé par** | @ProductOwner — YYYY-MM-DD |
| **Enrichi par** | @Architect — YYYY-MM-DD |
| **Branche de développement** | `feat/US-XXX-slug` |

---

## 🎯 Contexte métier

> *(Rempli par @ProductOwner)*

[Expliquer POURQUOI cette US existe — quel problème utilisateur elle résout, quelle valeur elle apporte. 2-3 phrases maximum.]

**Valeur ajoutée** : [Impact mesurable attendu]

---

## 📝 User Story

> *(Rempli par @ProductOwner)*

**En tant que** `[Rôle]`, **je veux** `[Action]` **afin de** `[Bénéfice]`.

---

## ✅ Critères d'Acceptation détaillés

> *(Rempli par @ProductOwner — plus détaillé que le backlog)*

### AC-1 : [Intitulé du critère]
- **Nominal** : [Ce qui doit se passer dans le cas normal]
- **Erreur** : [Ce qui doit se passer en cas d'erreur]
- **Limite** : [Cas limite à considérer]

### AC-2 : [Intitulé du critère]
- **Nominal** : …
- **Erreur** : …

*(Ajouter autant d'AC que nécessaire)*

---

## 🥒 Scénarios Gherkin

> *(Rempli par @ProductOwner)*

Fichier feature : [`tests/features/US-XXX_description.feature`](../../tests/features/US-XXX_description.feature)

*Résumé des scénarios couverts :*
- Scénario 1 : [Intitulé]
- Scénario 2 : [Intitulé]
- Scénario 3 (cas d'erreur) : [Intitulé]

---

## 🏗️ Contexte technique

> *(Rempli par @Architect lors de la phase `technical_validation` — chemins et outillage selon `docs/governance/STACK_PROFILE.md`)*

### Fichiers concernés

| Fichier | Type | Ce qui doit changer |
|---|---|---|
| `[chemin]` | [Composant] | [Description] |

### Patterns imposés

- **[Pattern 1]** : [Justification]
- **[Pattern 2]** : [Justification]

### Contraintes architecturales

- [Contrainte 1]
- [Contrainte 2]

### Dépendances

| Type | US / Composant | Raison |
|---|---|---|
| **Dépend de** | US-XXX | [Pourquoi cette US doit être terminée avant] |
| **Bloque** | US-YYY | [Ce qui ne peut pas démarrer sans cette US] |

### Risques et points d'attention

- ⚠️ [Risque 1]
- ⚠️ [Risque 2]

### ADR associé

> *(Si une décision architecturale structurante est prise pour cette US)*

[ADR-XXX : Titre](../../docs/adr/ADR-XXX-titre.md) — [Résumé en une ligne]

---

## 🔨 Tâches d'implémentation

> *(Rempli par @Architect — exécuté par @Developer)*
> Tâches atomiques et ordonnées. Chaque tâche = un commit possible.

- [ ] **T1** — [Description précise]
- [ ] **T2** — [Description précise]
- [ ] **T3** — Tests unitaires : [Description]

---

## 🧪 Critères de test

> *(Rempli par @Architect / @QA_Tester)*

| # | Scénario | Résultat attendu | Priorité |
|---|---|---|---|
| 1 | [Cas nominal principal] | [Résultat] | Haute |
| 2 | [Cas d'erreur] | [Résultat] | Haute |
| 3 | [Cas limite] | [Résultat] | Moyenne |
| 4 | [Régression — fonctionnalité connexe] | [Résultat] | Moyenne |

**Commandes de test** : `python scripts/run_gates.py --gate test`

---

## 🚦 Definition of Done (DoD)

> Toutes les cases doivent être cochées avant de passer la phase `quality_assurance`.

- [ ] Code livré sur sa branche dédiée
- [ ] PR ouverte (pas de commit direct sur la branche principale)
- [ ] Tests unitaires conformes aux seuils de `factory.config.json`
- [ ] Aucune régression sur les US précédentes
- [ ] `Audit Rev 🔍` validé par @CodeReviewer
- [ ] `Audit Sec 🛡️` validé par @CyberSecurity
- [ ] `QA Status 🧪 PASS` validé par @QA_Tester
- [ ] PROJECT_LOG.md mis à jour
- [ ] SCB mis à jour (toutes colonnes concernées)
- [ ] Story File archivé dans `docs/stories/`

---

## 📎 Liens utiles

- [Entrée SCB](../../STORY_CERTIFICATION_BOARD.md)
- [Entrée Backlog](../../BACKLOG.md)
- [Feature Gherkin](../../tests/features/US-XXX_description.feature)
- [Rapports d'audit](../../reports/US-XXX/) *(après audit/QA)*
