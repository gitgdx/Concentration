/// **Port métier** du dépôt d'échéances (T2) — `domain/`, donc **Dart pur**.
///
/// ⛔ **Aucun `import` de `package:flutter/**`, aucun `import` de `data/`**
/// (pattern nº 1, ADR-011 §3) : le sens des dépendances est
/// `presentation → domain ← data`. Une `String` n'est pas un import Flutter,
/// donc porter ici le texte d'un message ne rompt pas cette pureté.
library;

import 'echeance.dart';

/// L'acte d'écriture qui a échoué — **et c'est lui qui porte le message**.
///
/// ⚖️ **U-5 / pattern nº 10 AMENDÉ par l'Integration Lock du 2026-08-06.** La
/// règle « un seul exemplaire » était bonne, **son porteur était trop étroit** :
/// un échec d'écriture **n'est pas un refus de validation** (rien n'est fautif
/// dans la saisie, c'est le disque qui a refusé), donc l'ancienne formulation
/// ne le couvrait pas et son texte serait allé **dans le widget** par défaut.
///
/// 🔴 **Deux textes, pas un** (Design UX §14.5) : les scénarios distinguent
/// « l'enregistrement n'a pas eu lieu » de « la suppression n'a pas eu lieu ».
/// Un message générique unique *satisferait la lettre et raterait l'objet* —
/// l'utilisateur doit savoir **ce qui** n'a pas eu lieu.
///
/// ⛔ Ces textes ne contiennent **ni nom de fichier, ni chemin, ni exception,
/// ni code d'erreur** (AC-17 « Nominal » : *« aucune trace technique »*), ⛔ ni
/// promesse de réessai ou de brouillon — **il n'y en a aucun** (AC-17 « Limite »).
enum ActeEcriture {
  enregistrement("L'échéance n'a pas été enregistrée."),
  suppression("La suppression n'a pas eu lieu.");

  const ActeEcriture(this.messageEchec);

  /// ⛔ **UN SEUL EXEMPLAIRE** — ⛔ jamais recopié dans un widget ni dans un
  /// test (deux copies d'une règle dérivent, vérifié trois fois sur ce corpus).
  final String messageEchec;
}

/// Ce que rend **toute** écriture du port. ⛔ **Jamais `void`.**
///
/// ⚖️ **U-6 ①, ÉLIMINATOIRE pour AC-17.** Si l'écriture était « tirée et
/// oubliée » (un `Future` non attendu, une exception avalée), l'appelant ne
/// pourrait **pas connaître l'issue** ⇒ **les 3 scénarios d'AC-17 seraient
/// inobservables** — même classe de défaut qu'un bouton désactivé, qui efface
/// la clause qu'il prétendait servir.
///
/// ⚠️ **Le lint `unawaited_futures` ne suffit PAS** : mesuré par mutant dans les
/// deux sens le 2026-08-06, il rend le gate requis `analyze` **rouge** sur un
/// `await` oublié **dans une fonction `async`**, et il est ⛔ **AVEUGLE dans un
/// appelant synchrone**, où le gate reste **vert à tort**. C'est ce type de
/// retour, plus le test d'AC-17 « Erreur », qui ferme le résidu.
class ResultatEcriture {
  /// L'écriture a **abouti sur le disque**.
  const ResultatEcriture.reussie() : acteEchoue = null;

  /// L'écriture **n'a pas eu lieu** — rien n'a été écrit.
  const ResultatEcriture.echec(ActeEcriture acte) : acteEchoue = acte;

  /// `null` ⇔ succès.
  final ActeEcriture? acteEchoue;

  bool get estReussi => acteEchoue == null;

  /// Message destiné à l'utilisateur ; `null` en cas de succès.
  String? get message => acteEchoue?.messageEchec;
}

/// Le port : quatre opérations, **aucune** ne rend `void`.
///
/// 🔴 **Règle métier d'AC-17, prise à la lettre** : *« ce qui est affiché
/// correspond TOUJOURS à ce qui est sur le disque »* ⇒ ⛔ **l'état en mémoire
/// n'est JAMAIS muté avant un succès**, ⛔ **aucune mise à jour optimiste**.
///
/// ⛔ Ce port **n'a pas de test propre** : une interface n'a pas de
/// comportement. Il est éprouvé par son implémentation (T7) et par les E2E.
abstract interface class EcheanceRepository {
  /// Les échéances **lisibles** du stockage. Un enregistrement illisible est
  /// **ignoré** — ⛔ ni réparé, ni supprimé (AC-11).
  Future<List<Echeance>> charger();

  Future<ResultatEcriture> creer(Echeance echeance);

  /// Remplace l'échéance de **même `id`**.
  ///
  /// ⚖️ **`NB-A` — TRANCHÉ le 2026-08-07 : c'était la DOC qui avait tort, pas le
  /// comportement.** Cette phrase promettait *« sans correspondance : échec »*,
  /// or l'implémentation réécrit la liste **inchangée** et rend un **succès** —
  /// **les deux exemplaires de la règle avaient déjà divergé**, et la revue de
  /// code l'a mesuré.
  ///
  /// **Contrat RÉEL, et il est désormais en UN SEUL exemplaire** : sans
  /// correspondance d'`id`, le document est réécrit **à l'identique** et le
  /// résultat est un **succès**.
  ///
  /// **Motifs du choix** *(⛔ pas une « mise à jour vague » : un des deux
  /// énoncés devait disparaître)* :
  /// * **① Aucun AC n'exige ce refus.** AC-6 ne parle que de l'édition d'une
  ///   échéance **listée** ; aucune clause, aucun scénario, aucune réfutation
  ///   de la table anti-orphelin ne mentionne l'absence de correspondance.
  /// * **② Un refus pour une entrée que le produit ne peut pas produire serait
  ///   une CLAUSE SANS SURFACE** — l'acquis ② du design d'US-01.2 : *« ce qui
  ///   doit être refusé doit d'abord pouvoir être SAISI »*. Une édition part
  ///   **toujours** d'une échéance listée ⇒ le chemin est **inatteignable
  ///   depuis l'IHM**, et un scénario ne pourrait pas l'observer.
  /// * **③ Changer le COMPORTEMENT au lieu de la doc serait un changement de
  ///   périmètre** dans un cycle de **correctif d'audit**, sur un design
  ///   **verrouillé** — et ⛔ aucun événement du catalogue ne modélise cela.
  ///
  /// ⚠️ **Ce que ce contrat n'excuse pas** : il **n'est pas la garantie qu'une
  /// édition a modifié quelque chose**. Si un appelant devait un jour distinguer
  /// « remplacé » de « rien à remplacer », il faudrait un **troisième acte** dans
  /// [ActeEcriture] — ⛔ pas une lecture inversée de ce succès.
  Future<ResultatEcriture> remplacer(Echeance echeance);

  Future<ResultatEcriture> supprimer(String id);
}
