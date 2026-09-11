// ignore_for_file: avoid_print
//
// ⛔ `print` est VOULU : ce fichier est un CRITÈRE D'AUDIT, sa valeur est la
// sortie qu'il imprime. Sans cette directive il rend `flutter analyze` ROUGE.

/// CRITÈRE DE SÉCURITÉ EXÉCUTABLE — audit sécurité US-01.4, SHA `8509f44`.
///
/// Arbitrage D-8 : l'historique des retirées n'a **ni plafond ni purge**.
/// Question de DISPONIBILITÉ mesurée ici, sur le **chemin de production**
/// (`EcheanceDocumentCodec.encoder`, ⛔ pas une copie du format dans ce test) :
///   ① combien d'octets coûte UNE retirée, à la marge ?
///   ② une écriture quelconque réécrit-elle TOUT le document ?
///      (c'est le facteur d'amplification, ⛔ pas la taille seule)
library;

import 'dart:convert';
import 'dart:io';

import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/document_store_io.dart';
import 'package:concentration/features/echeances/data/echeance_document_repository.dart';
import 'package:concentration/features/echeances/domain/validation_echeance.dart';
import 'package:concentration/features/echeances/presentation/echeances_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(Directory, EcheancesNotifier)> _harnais(
  DateTime instant,
  int nbRetirees,
) async {
  final dir = await Directory.systemTemp.createTemp('audit_secu_croissance_');
  final document = <String, Object?>{
    'schemaVersion': 3,
    'echeances': <Object?>[
      for (var i = 0; i < nbRetirees; i++)
        <String, Object?>{
          'id': 'retiree-$i',
          'description': descriptionFixture(i),
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

int _tailleApresUneEcriture(Directory dir) =>
    File('${dir.path}${Platform.pathSeparator}echeances.json').lengthSync();

/// La description de la fixture. `pire = true` ⇒ **80 caractères**, la borne
/// `ValidationEcheance.longueurMaxDescription` — ⛔ elle n'est PAS recopiée en
/// dur, elle est LUE depuis le domaine.
bool pireCas = false;
String descriptionFixture(int i) {
  const court = 'echeance retiree numero ';
  if (!pireCas) return '$court$i';
  final base = '$court$i ';
  return base.padRight(longueurMaxDescriptionLue, 'x').substring(
    0,
    longueurMaxDescriptionLue,
  );
}

final int longueurMaxDescriptionLue =
    ValidationEcheance.longueurMaxDescription;

void main() {
  final instant = DateTime(2026, 9, 11, 12, 0);

  test('croissance marginale par retiree, chemin de PRODUCTION', () async {
    final mesures = <int, int>{};
    for (final n in <int>[0, 10, 100, 1000]) {
      final (dir, notifier) = await _harnais(instant, n);
      // Une écriture RÉELLE passant par `codec.encoder` : c'est elle qui fixe
      // le format, ⛔ pas la fixture ci-dessus.
      final refus = await notifier.creer(
        description: 'sonde',
        date: '31/12/2027',
        heure: '',
      );
      expect(refus, isNull);
      mesures[n] = _tailleApresUneEcriture(dir);
      dir.deleteSync(recursive: true);
    }
    for (final e in mesures.entries) {
      print('n=${e.key.toString().padLeft(5)} retirees  ->  '
          '${e.value.toString().padLeft(8)} octets');
    }
    final marginal =
        (mesures[1000]! - mesures[0]!) / 1000.0;
    print('OCTETS PAR RETIREE (marge 0 -> 1000) = '
        '${marginal.toStringAsFixed(1)}');
    print('EXTRAPOLATION a n=10 000              = '
        '${(mesures[0]! + marginal * 10000).round()} octets');
    // ⛔ AUCUN plafond n'est asserte ici : la croissance EST non bornee, c'est
    //    l'arbitrage D-8. Ce test MESURE, il ne juge pas.
    expect(marginal, greaterThan(0), reason: 'la croissance est bien lineaire');
  });

  test('AMPLIFICATION : une ecriture reecrit-elle TOUT le document ?', () async {
    final (dir, notifier) = await _harnais(instant, 1000);
    addTearDown(() => dir.deleteSync(recursive: true));
    final cible = File('${dir.path}${Platform.pathSeparator}echeances.json');
    final avant = cible.lengthSync();
    final horodatageAvant = cible.statSync().modified;

    await notifier.creer(
      description: 'une seule echeance de plus',
      date: '31/12/2027',
      heure: '',
    );

    final apres = cible.lengthSync();
    print('taille AVANT ecriture = $avant octets');
    print('taille APRES ecriture = $apres octets');
    print('horodatage change     = '
        '${cible.statSync().modified != horodatageAvant}');
    print('=> octets REECRITS par UNE creation = $apres '
        '(le document ENTIER, ⛔ pas le delta)');
    expect(apres, greaterThan(avant));
  });

  test('PIRE CAS : description a la borne du domaine', () async {
    pireCas = true;
    addTearDown(() => pireCas = false);
    final mesures = <int, int>{};
    for (final n in <int>[0, 1000]) {
      final (dir, notifier) = await _harnais(instant, n);
      await notifier.creer(
        description: 'sonde',
        date: '31/12/2027',
        heure: '',
      );
      mesures[n] = _tailleApresUneEcriture(dir);
      dir.deleteSync(recursive: true);
    }
    final marginal = (mesures[1000]! - mesures[0]!) / 1000.0;
    print('borne LUE du domaine (longueurMaxDescription) = '
        '$longueurMaxDescriptionLue');
    print('PIRE CAS octets par retiree = ${marginal.toStringAsFixed(1)}');
    print('PIRE CAS extrapolation n=10 000 = '
        '${(mesures[0]! + marginal * 10000).round()} octets');
    expect(marginal, greaterThan(0));
  });
}
