/// Le **double appui** et la purge de son reconnaisseur, **en UN SEUL
/// exemplaire** (US-01.4, T19).
///
/// ⚖️ **Extrait, ⛔ pas copié.** Le geste vivait comme fermeture **locale** dans
/// `grille_retrait_test.dart` (T10) ; T19 en a besoin sur une autre surface.
/// Le recopier aurait fait **deux exemplaires** d'un geste dont la mécanique
/// est subtile — *deux copies d'un motif dérivent, vérifié trois fois sur ce
/// corpus* — et la dérive aurait été **silencieuse** : un double appui mal
/// séparé est reçu comme **deux appuis simples**, donc le test observerait la
/// **révélation** au lieu du **retrait**, sans jamais rougir pour la bonne
/// raison.
///
/// ⛔ **Les bornes ne sont PAS écrites à la main** : elles se **lisent** dans le
/// SDK (`kDoubleTapMinTime`, `kDoubleTapTimeout`).
library;

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

/// Marge au-delà d'une borne du SDK — ⛔ jamais une durée « ronde » devinée en
/// remplacement de la borne elle-même.
const Duration grainDeGeste = Duration(milliseconds: 10);

/// ⛔ **Jamais deux `tap()` nus** : le premier appui doit être séparé du second
/// d'au moins `kDoubleTapMinTime`, sinon le reconnaisseur ⛔ **ne voit pas un
/// double appui**.
///
/// ⛔ **Aucun `pump` après le second appui** : c'est l'appelant qui décide,
/// parce que l'instant *« juste après le geste, avant toute frame »* est
/// précisément ce que le contrôle de `M-14` observe.
Future<void> doubleAppui(WidgetTester tester, Finder cible) async {
  final centre = tester.getRect(cible).center;
  await tester.tapAt(centre);
  await tester.pump(kDoubleTapMinTime + grainDeGeste);
  await tester.tapAt(centre);
}

/// ⚠️ Le reconnaisseur de double appui laisse un minuteur de
/// `kDoubleTapTimeout` en attente : sans cette avance, le démontage échoue sur
/// `!timersPending`. ⛔ **Ce n'est pas un défaut du produit**, c'est la
/// mécanique du reconnaisseur.
Future<void> purgerLeReconnaisseur(WidgetTester tester) =>
    tester.pump(kDoubleTapTimeout + grainDeGeste);
