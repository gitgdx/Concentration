## 📋 Description de la Pull Request (US-XX.X)

**Titre de la Story :** [Entrer le titre de la story]
**ID de la Story :** `US-XX.X`
**Étape actuelle du Workflow :** [e.g., parallel_audit / quality_assurance]

---

### ⛔ Checklist de conformité workflow (à remplir par le Développeur)

Avant de soumettre cette PR pour revue, assurez-vous que les étapes de conception ont été formellement complétées et validées dans le [Story Certification Board](../STORY_CERTIFICATION_BOARD.md) :

- [ ] **PO Visa** : le Product Owner a rédigé les critères BDD et validé la spec (`✅ @PO`).
- [ ] **Design Data** : le Data Engineer a validé la structure de données (`✅ @Data` ou `N/A` justifié).
- [ ] **Design UX** : l'UX Designer a fourni et validé les wireframes / design tokens (`✅ @UX` ou `N/A` justifié).
- [ ] **Integration Lock** : l'Architecte a verrouillé la conception technique (`integration_lock`).
- [ ] **Naming Convention** : le nom de la branche respecte le format déclaré (`feat/US-XX.X-description`).
- [ ] **PROJECT_LOG.md** : l'événement `EVT_CODE_READY` a été logué avec les fichiers impactés.
- [ ] **SCB** : la colonne `Code (Dev)` a été mise à jour à `✅ @Dev` avec le détail des visas en bas de page.

---

### 🔍 Équipe d'audit & review (requis pour approbation)

Le merge vers la branche principale requiert impérativement la validation et le visa des agents suivants :

- **Revue de Code** : @CodeReviewer (`Audit Rev 🔍` → `✅ 🔍` dans le SCB)
- **Audit de Sécurité** : @CyberSecurity (`Audit Sec 🛡️` → `✅ 🛡️` dans le SCB)

> [!WARNING]
> Tout merge direct sur la branche principale sans passer par cette checklist de PR est strictement interdit.
