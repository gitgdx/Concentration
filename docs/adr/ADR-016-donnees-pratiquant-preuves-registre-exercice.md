# ADR-016 : Les échéances du pratiquant restent HORS des preuves publiques ; natures du registre fermées ; relevés sous clé ; mode d'exercice nommé

- **Date** : 2026-09-30
- **Statut** : **Accepté** *(2026-09-30 — @Architect, **à la clôture de l'Integration Lock** d'US-01.3, pratique d'ADR-014. Conditions levées : **Q-L1 (a)** et **Q-L2 (a)** ; **Q-L4 (b)** ne touche pas cet ADR. Vérifié avant acceptation : le jeu de codes dont dépendent §3 et §4 est **égal** des deux côtés, **par script** (60 = 60, exit 0). ⚠️ **Un ADR accepté est IMMUABLE.**)*
  - *(⛔ PÉRIMÉ-2026-09-30 — forme antérieure, conservée :)* **Proposé** *(2026-09-30 — @Architect, à l'Integration Lock d'US-01.3. ⛔ **Il ne passe pas
  `Accepté` avant la réponse humaine à Q-L1** *(§1 en dépend entièrement)* **et à Q-L2** *(§7)* — Story
  File d'US-01.3, §Integration Lock.)* *(⛔ PÉRIMÉ-2026-09-30 : **Q-L1 et Q-L2 TRANCHÉES par l'humain en (a)** — les deux conditions sont levées ; l'acceptation a lieu **à la clôture du lock**, suspendue à Q-L4, qui ne touche pas cet ADR.)*
- **US associée** : US-01.3 (Chaîne de déploiement mobile réelle — Android), EPIC_01, track FULL
- **Complète** : [ADR-015](ADR-015-deploiement-android-sans-serveur-signature-locale.md) *(Accepté,
  **non modifié**)*.
- **Remplace, dans ADR-015, et UNIQUEMENT** :
  1. **§5**, la seule parenthèse *« Preuves détaillées (journaux capturés, sorties d'outils) sous
     `docs/deploiement/preuves/` »* : elle reste vraie **pour les sorties d'outils caviardées** ; ⛔ elle
     cesse de l'être **pour le journal complet de l'application** *(§1 ci-dessous)*.
  2. **§7**, la seule phrase *« à défaut, capture d'écran jointe + constat humain à la validation, et la
     preuve le dit »* : le **constat humain** et **la mention dans la preuve** restent ; la **capture
     d'écran** est conservée **HORS du dépôt** *(§1)*.

  ⛔ **Rien d'autre d'ADR-015 n'est touché.** *(Forme suivie : ADR-014 remplaçant deux phrases d'ADR-013,
  ADR-013 non édité.)*

## Contexte

L'Integration Lock d'US-01.3 a relevé une **convergence INDÉPENDANTE** : @UXDesigner *(P-4)* et
@DataEngineer *(P-5)*, **sans lire le document de l'autre**, ont établi que trois voies prévues publieraient
**le contenu des échéances du pratiquant** dans un dépôt **PUBLIC** : ① la **capture d'écran** du hub
*(repli R-8 d'ADR-015 §7)* ; ② la **ligne `FATAL` citée** *(AC-8 « Erreur »)*, dont le message d'exception
peut porter le texte d'une échéance ; ③ les **relevés** d'AC-7. Or ADR-015 est **Accepté**, et ses §5 et §7
écrivent **en toutes lettres** l'emplacement versionné du journal et la jonction de la capture : ⛔ **une
lecture ne suffit pas**.

La même jointure a laissé ouverts trois points **structurants** qu'aucun ADR ne tranchait : la **liste des
natures** du registre *(fermée ou exemplative ?)*, l'**usage** de la clé d'empreinte pour hacher les
relevés, et le moyen d'**observer** le refus d'appareil d'AC-7 « Erreur » alors que la chaîne refuse
elle-même un APK signé par une autre clé.

## Décision

### §1 — Le contenu des échéances est une donnée C2 et n'entre JAMAIS dans un fichier versionné *(⚖️ Q-L1 (a), arbitrage humain du 2026-09-30 — ⛔ PÉRIMÉ-2026-09-30 : « SOUS Q-L1 »)*

- **Hors du dépôt**, au même statut que le keystore *(Art. 6, 1.3)* : les **captures d'écran**, le
  **journal complet** du processus de l'application, le **relevé en clair** des échéances.
- **Dans la preuve versionnée** : des **comptes**, une **empreinte à clé** du relevé *(§2)*, et la ligne
  `FATAL` **caviardée** — étiquette, **type** d'exception et **pile d'appels de l'application** conservés,
  **texte du message remplacé** par un marqueur fixe. ⛔ Un caviardage « intelligent » qui tenterait de
  reconnaître une échéance dans le message est **refusé** : il ne peut pas être exhaustif.
- **La console** de l'opérateur peut afficher la ligne **entière** ; ⛔ elle ne l'écrit dans **aucune**
  preuve.

### §2 — Les relevés sont hachés sous la clé d'empreinte, en domaine SÉPARÉ

`HMAC-SHA-256(clé d'empreinte, "concentration/releve/v1\n" ‖ forme canonique)`, tronqué à 16 caractères
hexadécimaux *(forme canonique : Data §3.4)*. Le préfixe contient `/` et un saut de ligne, qu'un numéro de
série ne contient pas ⇒ une empreinte de relevé **ne peut pas** égaler une empreinte d'appareil
*(ADR-015 §13)*. ⛔ **Pas de seconde clé** : elle ajouterait un secret à sauvegarder sans gain. **Audit de
@CyberSecurity** à `/audit-us`.

### §3 — La liste des natures du registre est FERMÉE

`build`, `staging`, `staging_echec`, `validation`, `production`, `refus` *(ADR-015 §5)* **+**
`non_concluant`, `attribution`, `desinstallation_unique`, `rupture_empreinte` *(chacune exigée par un AC —
Data §1.4)*. ⛔ **Toute nature nouvelle exige une nouvelle `schemaVersion` ET un nouvel ADR.**

### §4 — Un mode d'EXERCICE nommé rend AC-7 « Erreur » observable

Sans lui, un APK signé par une **autre** clé est refusé **par la chaîne** *(certificat ≠ référence, APK sans
ligne `build`)* et le refus **de l'appareil** n'est **jamais** observé. Le mode d'exercice : **option
explicite**, **confirmation saisie**, ne lève **que** `artefact_non_consigne` et `certificat_non_release` ;
exige un `versionCode` **supérieur** au registre *(sinon l'essai prouverait un refus de version)* ; consigne
un `refus` `exercice: true`, `origine: appareil`. 🆕 *(L-4, 2026-09-30)* **Avant l'essai**, l'application installée doit être **signée par la clé de release** *(sinon l'essai n'essaie rien)*. 🔒 *(clôture du lock)* **Et** l'APK d'exercice doit porter un certificat **DIFFÉRENT** du certificat de release *(sinon ce n'est pas « une autre clé », AC-7 « Erreur »)* — le mode d'exercice lève `certificat_non_release`, il ⛔ n'en autorise **pas** l'inverse. **Si l'appareil ACCEPTE** l'APK : `staging_echec`, cause `exercice_accepte_par_appareil`, et ⛔ **la clé jetable n'est PAS détruite** — elle est devenue **la seule** qui permette une mise à jour du paquet. ⇒ ⛔ **la clé jetable n'est détruite qu'après un refus CONSTATÉ.** ⛔ Il ne lève **aucun** autre contrôle et n'existe **que**
pour cet essai.

### §5 — L'éligibilité à la production est FIXÉE au staging, et re-vérifiée à la déclaration

AC-9 « Nominal » exige que la preuve de staging d'un artefact de branche **dise** qu'il ne pourra pas être
déclaré en production ; en ajout seul, cette phrase ne se corrige plus ⇒ **une répétition ne devient jamais
la production**, même après une fusion par **merge**. **Et** la validation d'un staging non éligible est
refusée *(INV-17)*.

### §6 — Refus avant installation des défauts intrinsèques et du schéma régressif

INV-9 *(réseau, sauvegarde, débogable)* et le schéma de document **non régressif** *(AC-6 « Erreur »,
amendée au lock)* sont refusés **avant** toute installation : l'appareil de staging est **celui du
pratiquant**, sans retour arrière *(ADR-015 §8)*.

### §7 — Périmètre de fraîcheur d'un visa *(⚖️ Q-L2 (a), arbitrage humain du 2026-09-30 — ⛔ PÉRIMÉ-2026-09-30 : « SOUS Q-L2 »)*

Un visa est **frais** si `git diff --name-only <commit du visa> <commit de production> -- <périmètre>` est
vide ; ⛔ **jamais** par ascendance *(squash et rebase autorisés)*. **Périmètre proposé** : `lib/`,
`android/`, `pubspec.*` — ⚖️ **retenu** *(Q-L2 (a))* : US-01.3 modifiant `android/`, **les visas d'US-01.1, US-01.2 et US-01.4 sont périmés** par elle.

## Alternatives considérées

| Alternative | Pourquoi écartée |
|---|---|
| **Lire ADR-015 §5 et §7 sans nouvel ADR** | Le §5 nomme **l'emplacement versionné du journal** : le relire « caviardé » serait adapter le texte au besoin |
| **Caviardage par reconnaissance des échéances** | Non exhaustif par construction |
| **Seconde clé pour les relevés** | Un secret de plus à sauvegarder ; aucune séparation de plus que le préfixe de domaine |
| **Publier seulement les comptes des relevés** | La CI ne pourrait plus vérifier l'égalité des relevés *(INV-16)* |
| **Pas de mode d'exercice** | AC-7 « Erreur » inobservable, ou contrôles de la chaîne affaiblis pour tous |
| **Éligibilité évaluée seulement à la déclaration** | Rendrait fausse, après une fusion par merge, une preuve de staging qu'on ne peut plus corriger |

## Conséquences

- ✅ Aucun contenu d'échéance n'atteint le dépôt public ; ⚠️ **le diagnostic d'un `FATAL` exige la
  machine de l'humain** *(le message complet n'est que local)*.
- ⚠️ **AC-8 « Erreur »** *(« la ligne est citée dans la preuve »)* se **lit** « citée caviardée » — lecture
  **à dater par @ProductOwner** sur la clause si Q-L1 (a) est retenue.
- ⚠️ La clé d'empreinte gagne un **second usage** : sa perte casse **aussi** la comparabilité des relevés
  *(rupture consignée, ⛔ pas une perte de données)*.
- ⚠️ Le mode d'exercice est **une porte** : il est audité, nommé, et ne lève que deux contrôles.
- **NM-14, NM-15, NM-16 restent vraies.** ⛔ **Rien ne vaut pour iOS** *(H-1, BT-1)*.

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables**
une fois acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien
(ne jamais éditer un ADR Accepté).
