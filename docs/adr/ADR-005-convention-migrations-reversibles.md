# ADR-005 : Convention de migrations de schéma local réversibles

- **Date** : 2026-07-26
- **Statut** : Accepté
- **US associée** : US-00.3

## Contexte

Concentration est **offline-first** (RNF-01/07) : toutes les données vivent localement sur l'appareil.
Dès que la première persistance (US-01.2) introduira un schéma réel, toute évolution ultérieure du
modèle (nouveau champ, futurs modules Respiration/Concentration — extensibilité RF-21) devra migrer les
données locales **sans perte** et **de façon réversible**, y compris lors d'une simple mise à jour de
l'app. Sans convention établie **avant** le premier schéma, chaque US de persistance improviserait sa
propre approche → risque de migration destructive, de perte de données et d'absence de chemin de retour.

Contrainte de cadrage (`STACK_PROFILE.md §DataEngineer`) : le **choix du mécanisme de persistance**
(`sqflite`/`drift`/`isar`/`hive`/…) est **délibérément reporté à US-01.2 + un ADR dédié**. Il n'existe
donc **aucun schéma concret à migrer au Sprint 0** : la décision porte sur une **convention agnostique**,
pas sur une implémentation.

## Décision

Adopter la **convention de migrations réversibles** décrite dans
[`docs/architecture/MIGRATIONS.md`](../architecture/MIGRATIONS.md) :

1. **Version de schéma entière monotone** (`v0` = aucun schéma) ; tout changement `+1` avec un **couple
   `up`/`down`** obligatoire.
2. **Invariant d'aller-retour** non négociable : `up(N-1→N)` puis `down(N→N-1)` restaure un état
   fonctionnellement équivalent.
3. **Additif par défaut** (RF-21) ; migration **destructive interdite** sauf exception encadrée
   (préservation documentée **+** validation humaine tracée `EVT_WAIVER_GRANTED`).
4. **Patron de test aller-retour** obligatoire pour toute migration (canevas documenté, instancié par US-01.2).
5. **Agnosticisme techno** : la convention s'exprime en version/up/down/round-trip, applicable à tout
   mécanisme. Le **choix du mécanisme reste reporté à US-01.2 + ADR**.

## Alternatives considérées

- **Ne rien formaliser avant US-01.2** (laisser la persistance décider) — écarté : reproduit le risque
  d'improvisation et de migration destructive que l'US vise précisément à éliminer ; une convention
  rétroactive est plus coûteuse et moins fiable.
- **Choisir le mécanisme de persistance dès maintenant** pour écrire une convention concrète — écarté :
  contredit `STACK_PROFILE §DataEngineer` (report assumé à US-01.2) et coupler la convention à une techno
  la rendrait fragile à un changement ultérieur.
- **Migrations « forward-only » (sans `down`)** — écarté : incompatible avec l'exigence de réversibilité
  offline (pas de rollback possible sur l'appareil de l'utilisateur en cas de mise à jour défaillante).

## Conséquences

- **Positif** : toute évolution future du modèle est dé-risquée (réversible, non destructive par défaut,
  testée) ; US-01.2 devient certifiable sur la persistance ; base saine pour l'extensibilité RF-21.
- **Coût / limite** : la convention n'est **prouvée « appliquée »** qu'à US-01.2 (première instanciation
  réelle du patron de test) ; au Sprint 0 elle est validée par **revue de conformité**, pas par exécution
  automatisée. Risque résiduel d'abstraction — mitigé par un canevas concret (version/up/down/round-trip).
- **Dette / vigilance** : l'exception « destructif encadré » ne doit pas se banaliser (préservation +
  waiver humain systématiquement exigés) ; le numéro **ADR-005** a été choisi pour éviter la collision
  avec ADR-001 (stack, US-00.5) et ADR-002..004 (pressentis US-01.1).

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables** une fois
acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien.
