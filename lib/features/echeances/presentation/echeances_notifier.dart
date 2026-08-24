import 'package:flutter/foundation.dart';

import '../../../core/time/clock.dart';
import '../domain/echeance.dart';
import '../domain/echeance_etat.dart';
import '../domain/echeance_repository.dart';
import '../domain/validation_echeance.dart';

/// **Source de vérité unique** de la liste d'échéances (T8, ADR-011).
///
/// ⛔ **`ChangeNotifier` du SDK, `+0` dépendance** : aucun paquet d'état, aucun
/// service locator, aucun singleton, aucune variable globale mutable.
///
/// 🔴 **RÈGLE MÉTIER D'AC-17, PRISE À LA LETTRE** : *« ce qui est affiché
/// correspond TOUJOURS à ce qui est sur le disque »* ⇒ **on RECHARGE depuis le
/// dépôt, on ne MUTE jamais la liste en place** (I-1), et ⛔ **l'état n'est
/// jamais modifié avant un succès** — ⛔ **aucune mise à jour optimiste**
/// (U-6 ①). Une carte qui apparaîtrait puis disparaîtrait est un « flash » que
/// l'œil enregistre comme une **perte de donnée**.
class EcheancesNotifier extends ChangeNotifier {
  // ⚠️ `prefer_initializing_formals` suggère `this._depot`, ce que Dart
  // INTERDIT : un paramètre NOMMÉ ne peut pas commencer par un souligné. La
  // règle est donc inapplicable ici, et la désactiver ponctuellement est le
  // seul moyen de garder `depot` nommé — ce qu'exige l'injection par la racine
  // (ADR-011 §2 : les dépendances restent VISIBLES dans les signatures).
  EcheancesNotifier({required EcheanceRepository depot, required Clock clock})
    // ignore: prefer_initializing_formals
    : _depot = depot,
      validation = ValidationEcheance(clock);

  final EcheanceRepository _depot;

  /// Les règles de saisie — exposées parce que la page en a besoin **avant**
  /// d'ouvrir un formulaire (refus d'édition d'une échue, message de limite).
  /// ⛔ Leurs textes vivent **là**, jamais dans un widget.
  final ValidationEcheance validation;

  List<Echeance> _echeances = const <Echeance>[];

  /// Liste **NON MODIFIABLE** (ADR-011 §Conséquences) : `ChangeNotifier`
  /// n'offre aucune garantie d'immuabilité, c'est à l'implémentation de la
  /// tenir — sans quoi I-1 perdrait son effet et l'ordre des tuiles cesserait
  /// d'être déterministe.
  /// La liste **COMPLÈTE**, retirées comprises — **la page de GESTION en a
  /// besoin** *(AC-7 d'US-01.4 : une échue retirée reste listée et supprimable)*.
  /// ⛔ Ne pas la confondre avec [presentes].
  List<Echeance> get echeances => _echeances;

  /// Les échéances **PRÉSENTES SUR LA GRILLE** — ⛔ les retirées en sont exclues.
  ///
  /// 🔴 **C-7 — UN SEUL FILTRE, UN SEUL DÉCOMPTE.** Ce getter est consommé **par
  /// la grille** *(ce qui s'affiche)* **ET** par la **limite de 9**
  /// *(`refusDeLimite`, plus bas)*. ⛔ **Deux filtres dériveraient**, et le
  /// symptôme serait le pire possible : *la grille montre 8 tuiles et la
  /// création est refusée*.
  ///
  /// ⛔ **Le filtre lui-même vit dans le DOMAINE**, en un seul exemplaire
  /// *(`echeance_etat.dart`)* : ce getter ne fait que **l'exposer**, il ne le
  /// **réécrit pas**.
  List<Echeance> get presentes => presentesSurLaGrille(_echeances);

  Future<void> charger() async {
    _echeances = List<Echeance>.unmodifiable(await _depot.charger());
    notifyListeners();
  }

  /// Rend **`null` en cas de succès**, sinon le **refus à afficher** — ⛔ jamais
  /// un booléen nu, ⛔ jamais `void`.
  Future<RefusValidation?> creer({
    required String description,
    required String date,
    required String heure,
  }) async {
    final resultat = validation.valider(
      description: description,
      date: date,
      heure: heure,
      // ⛔ `presentes`, ⛔ JAMAIS `_echeances` (C-7) : une échéance RETIRÉE ne
      // doit pas occuper une des 9 places — c'est le sens même d'AC-6 d'US-01.4,
      // *« une échue retirée LIBÈRE une place »*.
      presentes: presentes,
    );
    if (!resultat.estAcceptee) return resultat.refus;
    return _appliquer(await _depot.creer(resultat.echeance!));
  }

  /// ⛔ **La MÊME fonction de validation qu'à la création** (R-10) : deux
  /// chemins dériveraient, et la règle du futur strict deviendrait
  /// contournable en deux gestes.
  Future<RefusValidation?> modifier(
    Echeance original, {
    required String description,
    required String date,
    required String heure,
  }) async {
    final resultat = validation.valider(
      description: description,
      date: date,
      heure: heure,
      presentes: presentes,
      original: original,
    );
    if (!resultat.estAcceptee) return resultat.refus;
    return _appliquer(await _depot.remplacer(resultat.echeance!));
  }

  Future<RefusValidation?> supprimer(String id) async =>
      _appliquer(await _depot.supprimer(id));

  /// **RETIRE de la grille** — l'échéance est **CONSERVÉE** *(AC-4, AC-5)*.
  ///
  /// 🔴 **Rend `null` en cas de SUCCÈS, sinon le REFUS À AFFICHER** — ⛔ jamais
  /// `void`, ⛔ jamais un booléen nu, ⛔ **aucune mise à jour optimiste** : on
  /// **recharge** après succès, exactement comme les quatre autres écritures.
  /// C'est ce type de retour qui rend **AC-11 observable** *(« la tuile RESTE si
  /// l'écriture échoue »)*.
  ///
  /// ⚠️ **`unawaited_futures` ne suffirait PAS** : mesuré par mutant dans les
  /// deux sens, il est **AVEUGLE dans un appelant synchrone**. C'est le **type de
  /// retour**, plus le test d'AC-11, qui ferme le résidu.
  ///
  /// ⚖️ **`String id` et ⛔ pas `Echeance`** — ce paramètre **s'aligne sur
  /// [supprimer] juste au-dessus** et sur la signature du port, rectifiée par
  /// ADR-012 §6. ⛔ **Deux formes d'argument pour le même geste dériveraient.**
  Future<RefusValidation?> retirer(String id) async =>
      _appliquer(await _depot.retirer(id));

  /// ⛔ **Rien n'est rechargé, donc rien n'est affiché, tant que l'écriture n'a
  /// pas RÉUSSI.** Le message d'échec est celui du **port**, en un seul
  /// exemplaire (U-5) — ⛔ il n'est pas réécrit ici, seulement **ancré**.
  Future<RefusValidation?> _appliquer(ResultatEcriture ecriture) async {
    if (!ecriture.estReussi) {
      return RefusValidation(ChampEcheance.action, ecriture.message!);
    }
    await charger();
    return null;
  }
}
