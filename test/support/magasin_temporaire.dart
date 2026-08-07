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
import 'package:flutter_test/flutter_test.dart';

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

  /// 🔴 **REND LE STOCKAGE RÉELLEMENT NON INSCRIPTIBLE** — la réponse à la
  /// tension qu'AC-17 laissait ouverte.
  ///
  /// **Le problème posé** : les 3 scénarios d'AC-17 exigent de provoquer un
  /// échec d'écriture, or **ADR-010 §1 interdit tout magasin factice dans
  /// `test/e2e/**`**. ⛔ Un faux magasin qui lèverait est exactement ce qui est
  /// proscrit.
  ///
  /// **Le moyen retenu, et il n'a rien d'un artifice** : l'écriture atomique
  /// passe **obligatoirement** par `echeances.json.tmp` (`.tmp` + `flush` +
  /// `rename`). En créant **un RÉPERTOIRE** portant ce nom, le
  /// `writeAsString` du **code de production** échoue par une
  /// `FileSystemException` **réelle**, émise par le **système de fichiers**.
  /// ⇒ ⛔ **aucun magasin factice, aucun mock, aucune injection** : le chemin
  /// traversé est **exactement** celui de l'appareil, et la cause de l'échec
  /// est de la même nature qu'un disque plein ou qu'un droit refusé.
  ///
  /// ✅ **Et il est RÉVERSIBLE** — ce que le 2ᵉ scénario d'AC-17 exige
  /// littéralement : *« quand le stockage local redevient inscriptible »*.
  void bloquerEcriture() {
    Directory('${fichier.path}.tmp').createSync();
  }

  void debloquerEcriture() {
    final obstacle = Directory('${fichier.path}.tmp');
    if (obstacle.existsSync()) obstacle.deleteSync(recursive: true);
  }

  void nettoyer() {
    // ⚠️ Sous Windows, un descripteur peut rester ouvert quelques
    // millisecondes après la dernière écriture ⇒ `deleteSync` lève
    // `PathAccessException`. ⛔ Un ÉCHEC DE MÉNAGE ne doit JAMAIS faire rougir
    // un test : il ferait croire à un défaut du produit là où il n'y a qu'un
    // répertoire temporaire qui survit une seconde de plus.
    try {
      if (repertoire.existsSync()) repertoire.deleteSync(recursive: true);
    } on FileSystemException {
      // Le système d'exploitation le récupérera.
    }
  }
}

/// 🔴 **FAIT MESURÉ, et il gouverne TOUS les tests de widgets de cette US** :
/// une écriture disque **RÉELLE déclenchée par un TAP n'aboutit PAS** sous
/// `testWidgets`. Le corps d'un `testWidgets` tourne dans une zone
/// **`FakeAsync`** : les continuations de `Future` y sont des **microtâches
/// que seul `pump()` draine**, et l'achèvement de l'entrée-sortie ne peut
/// arriver que si la **vraie** boucle d'événements tourne — ce que seul
/// `runAsync` autorise.
///
/// **Mesuré dans les deux sens le 2026-08-06** *(sonde jetable, supprimée)* :
/// * `tap` → `pump` → `runAsync(delay 50 ms)` → `pump` ⇒ **`octets() == null`,
///   l'écriture N'A PAS EU LIEU** ;
/// * la même chose **répétée** ⇒ le fichier est écrit.
///
/// ⚠️ **Le nombre de tours est GÉNÉREUX et la sortie est ANTICIPÉE** : sous la
/// charge d'une suite complète *(plusieurs fichiers en parallèle)*, une chaîne
/// de **deux** entrées-sorties réelles *(écriture puis rechargement)* met
/// sensiblement plus longtemps qu'isolée. Un nombre juste suffisant **en
/// isolement** produit un test **INSTABLE en suite** — observé, puis corrigé.
/// La condition `jusqua` fait que le coût n'est payé **que** si l'attente est
/// réelle.
///
/// ⛔ **Sans cet utilitaire, un E2E qui tape « Enregistrer » serait VERT en
/// n'écrivant RIEN** — exactement le faux vert qu'ADR-010 §1 existe pour
/// interdire. ⚠️ Et il aurait été **indétectable** : l'écran, lui, se met bien
/// à jour.
Future<void> reglerEcritures(
  WidgetTester tester, {
  bool Function()? jusqua,
  int tours = 40,
}) async {
  for (var i = 0; i < tours; i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));
    if (jusqua != null && jusqua()) return;
  }
}
