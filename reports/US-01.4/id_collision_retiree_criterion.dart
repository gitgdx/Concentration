// ignore_for_file: avoid_print
//
// ⛔ `print` est VOULU ici : ce fichier est un CRITÈRE D'AUDIT, sa valeur est
// la sortie qu'il imprime dans le rapport. Sans cette directive il rend le
// gate REQUIS `flutter analyze` ROUGE (mesuré : exit 1, 6 issues).
/// CRITÈRE DE SÉCURITÉ EXÉCUTABLE — audit sécurité US-01.4, SHA `8509f44`.
///
/// Question mesurée : `ValidationEcheance._idLibre` cherche un `id` libre dans
/// la liste `presentes`, dont `presentesSurLaGrille` EXCLUT les retirées.
/// L'écriture, elle, porte sur la liste COMPLÈTE du document.
/// ⇒ un `id` déjà porté par une échéance RETIRÉE est-il considéré comme LIBRE,
///   et que devient l'entrée retirée ?
///
/// ⛔ Ce fichier ne modifie AUCUN code de `lib/` : il l'exerce tel qu'il est.
/// Il porte son CONTRÔLE NÉGATIF : le même scénario avec un `id` non colliding
/// doit rendre le verdict INVERSE. Sans lui, un magasin qui perdrait TOUJOURS
/// l'entrée rendrait le premier cas vert pour une mauvaise raison.
library;

import 'dart:convert';
import 'dart:io';

import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/document_store_io.dart';
import 'package:concentration/features/echeances/data/echeance_document_repository.dart';
import 'package:concentration/features/echeances/presentation/echeances_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monte le harnais RÉEL (octets sur disque, code de production) avec un
/// document `v3` portant UNE entrée retirée dont l'`id` est [idRetiree].
Future<(Directory, EcheancesNotifier)> _harnais(
  DateTime instant,
  String idRetiree,
) async {
  final dir = await Directory.systemTemp.createTemp('audit_secu_us014_');
  final document = <String, Object?>{
    'schemaVersion': 3,
    'echeances': <Object?>[
      <String, Object?>{
        'id': idRetiree,
        'description': 'ancienne echeance RETIREE du pratiquant',
        'dateEcheance': '2020-01-01T10:00',
        'retiree': true,
      },
    ],
  };
  File('${dir.path}${Platform.pathSeparator}echeances.json')
      .writeAsStringSync(jsonEncode(document));
  final clock = FakeClock(instant);
  final notifier = EcheancesNotifier(
    depot: EcheanceDocumentRepository(DocumentStoreFichier(dir, clock: clock)),
    clock: clock,
  );
  await notifier.charger();
  return (dir, notifier);
}

List<Object?> _entreesSurDisque(Directory dir) {
  final texte = File(
    '${dir.path}${Platform.pathSeparator}echeances.json',
  ).readAsStringSync();
  return (jsonDecode(texte) as Map)['echeances'] as List<Object?>;
}

void main() {
  // L'`id` fabriqué par `_idLibre` est `clock.now().microsecondsSinceEpoch`.
  // ⛔ Il n'est PAS écrit à la main ici : il est DÉRIVÉ de l'instant, comme le
  //    fait le code de production. Une valeur recopiée mesurerait sa copie.
  final instant = DateTime(2026, 9, 11, 12, 0);
  final idQueLaProductionVaFabriquer = instant.microsecondsSinceEpoch
      .toString();

  test('M1 — un id de RETIREE est vu comme LIBRE, et la retiree est DETRUITE', () async {
    final (dir, notifier) = await _harnais(
      instant,
      idQueLaProductionVaFabriquer,
    );
    addTearDown(() => dir.deleteSync(recursive: true));

    expect(
      notifier.echeances.length,
      1,
      reason: 'la retiree est bien chargee au depart',
    );
    expect(notifier.presentes, isEmpty, reason: 'elle est hors grille');

    final refus = await notifier.creer(
      description: 'nouvelle echeance',
      date: '31/12/2027',
      heure: '',
    );
    expect(refus, isNull, reason: 'la creation est acceptee');

    final entrees = _entreesSurDisque(dir);
    final idsSurDisque = entrees
        .map((e) => (e! as Map)['id'] as String)
        .toSet();
    final retireesSurDisque = entrees
        .where((e) => (e! as Map)['retiree'] == true)
        .length;

    print('M1  entrees sur disque        = ${entrees.length}');
    print('M1  ids sur disque            = $idsSurDisque');
    print('M1  entrees RETIREES restantes= $retireesSurDisque');
    print('M1  document brut             = ${jsonEncode(entrees)}');

    // Ce que le schema de stockage promet : une entree n'est supprimee QUE par
    // une confirmation explicite (AC-7). Aucune confirmation n'a eu lieu ici.
    expect(
      retireesSurDisque,
      1,
      reason: 'ECHEC = la retiree a ete detruite sans confirmation',
    );
  });

  test('CONTROLE NEGATIF — id NON colliding : la retiree SURVIT', () async {
    final (dir, notifier) = await _harnais(instant, 'id-sans-collision');
    addTearDown(() => dir.deleteSync(recursive: true));

    final refus = await notifier.creer(
      description: 'nouvelle echeance',
      date: '31/12/2027',
      heure: '',
    );
    expect(refus, isNull);

    final entrees = _entreesSurDisque(dir);
    final retireesSurDisque = entrees
        .where((e) => (e! as Map)['retiree'] == true)
        .length;

    print('CN  entrees sur disque        = ${entrees.length}');
    print('CN  entrees RETIREES restantes= $retireesSurDisque');

    expect(
      retireesSurDisque,
      1,
      reason: 'le controle negatif doit etre VERT : rien ne detruit ici',
    );
  });
}
