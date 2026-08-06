/// Magasin **RÉEL** sur répertoire temporaire réel — le harnais de persistance
/// des tests (T6).
///
/// 🔴 **Ce n'est PAS un faux dépôt** (ADR-010 §1) : il construit
/// `DocumentStoreFichier`, c'est-à-dire **le code de production**, et lui donne
/// un répertoire temporaire au lieu du répertoire de documents de l'appareil.
/// **Des octets réels sont écrits et relus.** ⛔ Aucun magasin en mémoire,
/// aucun mock de la couche de données.
///
/// 🔴 **Il PORTE SON MUTANT** (leçon **NB-7**) : un utilitaire de test peut
/// mentir avec 112 tests verts. `magasin_temporaire_test.dart` vérifie que ce
/// harnais **échoue** si on le fait mentir — voir son mutant nommé.
library;

import 'dart:io';

import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/document_store.dart';
import 'package:concentration/features/echeances/data/document_store_io.dart';

/// Un magasin fichier neuf, dans un répertoire temporaire **qui lui est
/// propre** — deux tests ne peuvent pas se marcher dessus.
class MagasinTemporaire {
  MagasinTemporaire._(this.repertoire, this.magasin);

  factory MagasinTemporaire.creer({Clock? clock}) {
    final repertoire = Directory.systemTemp.createTempSync('us012_');
    return MagasinTemporaire._(
      repertoire,
      DocumentStoreFichier(repertoire, clock: clock ?? const SystemClock()),
    );
  }

  final Directory repertoire;
  final DocumentStoreFichier magasin;

  /// Le fichier cible, **désigné par son nom**, jamais par sa position.
  File get fichier =>
      File('${repertoire.path}${Platform.pathSeparator}$nomDocument');

  /// Les **OCTETS réellement sur le disque**, ou `null` si aucun fichier.
  ///
  /// ⛔ C'est cette lecture — et non le rendu d'un widget — que les scénarios
  /// parlant du stockage doivent assertionner (ADR-010 §1, point 3).
  String? octets() => fichier.existsSync() ? fichier.readAsStringSync() : null;

  /// Pose un contenu **directement sur le disque**, avant tout démarrage.
  void poser(String contenu) => fichier.writeAsStringSync(contenu, flush: true);

  /// Les fichiers présents dans le répertoire, **noms triés**.
  List<String> fichiers() =>
      repertoire.listSync().map((e) => e.uri.pathSegments.last).toList()
        ..sort();

  void nettoyer() {
    if (repertoire.existsSync()) repertoire.deleteSync(recursive: true);
  }
}
