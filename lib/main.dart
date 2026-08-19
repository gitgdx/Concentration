// Point d'entrée Flutter — ⛔ **SEUL POINT DE COMPOSITION** (T11, ADR-011 §2).
//
// ⛔ Aucune logique ici, et ⛔ aucune composition ailleurs : ni dans un
// `initState` d'écran, ni dans un singleton, ni dans un service locator.
//
// 🔴 **R-14 — `main()` devient ASYNCHRONE, et l'ordre n'est pas négociable** :
// `path_provider` est un greffon, donc `WidgetsFlutterBinding.ensureInitialized()`
// doit précéder tout accès. ⚠️ Le chargement se fait **ICI**, avant `runApp` :
// dans un `initState`, un échec de chargement serait **invisible**, et il
// faudrait un état « données non encore chargées » — c'est-à-dire un écran de
// chargement, que le design interdit *(un spinner serait un mensonge
// d'interface : le premier `runApp` a déjà les données)*.

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/time/clock.dart';
import 'features/echeances/data/document_store_plateforme.dart';
import 'features/echeances/data/echeance_document_repository.dart';
import 'features/echeances/presentation/echeances_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const clock = SystemClock();
  final notifier = EcheancesNotifier(
    depot: EcheanceDocumentRepository(await magasinDeLaPlateforme()),
    clock: clock,
  );
  await notifier.charger();
  runApp(ConcentrationApp(notifier: notifier, clock: clock));
}
