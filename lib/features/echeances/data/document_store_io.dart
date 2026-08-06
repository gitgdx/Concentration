import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/time/clock.dart';
import 'document_store.dart';

/// Magasin **FICHIER RÉEL** — ⛔ le nom de ce fichier **doit** finir par
/// `_io.dart` : c'est la branche que l'import conditionnel d'ADR-009 §2 exclut
/// du bundle web.
///
/// 🔴 **Mesuré, et c'est un piège** : un `import 'dart:io'` **COMPILE** pour le
/// web — `flutter build web --release` resterait **VERT** en produisant un
/// artefact qui casse à l'exécution (`UnsupportedError: _Namespace`). ⛔ **Aucun
/// gate ne le verrait** ⇒ le contrôle est `scripts/check_e2e_persistance.py`
/// (T13), pas la CI.
///
/// ✅ **Le MÊME code sert en test et sur l'appareil** — seul le répertoire
/// diffère. C'est ce qui autorise ADR-010 §1 à exiger un magasin **réel** sous
/// `flutter test` : le harnais de test ne remplace aucune couche.
class DocumentStoreFichier implements DocumentStore {
  DocumentStoreFichier(this.repertoire, {this.clock = const SystemClock()});

  final Directory repertoire;

  /// ⛔ ADR-002 : jamais de `DateTime.now()` dans la logique. Elle ne sert
  /// qu'à horodater un document mis de côté.
  final Clock clock;

  File get _cible =>
      File('${repertoire.path}${Platform.pathSeparator}$nomDocument');

  /// ⛔ Le provisoire n'est **jamais lu** : [lire] ne regarde que la cible. Un
  /// `.tmp` laissé par une interruption est donc **inerte** — c'est la moitié
  /// de ce qui rend AC-12 « Erreur » vrai **par construction**.
  File get _provisoire => File('${_cible.path}.tmp');

  @override
  Future<String?> lire() async {
    final cible = _cible;
    if (!cible.existsSync()) return null;
    return cible.readAsString();
  }

  /// 🔴 **ÉCRITURE ATOMIQUE, TOUJOURS** : `.tmp` + `flush: true` + `rename`.
  /// ⛔ **Jamais d'écriture en place.** C'est l'autre moitié d'AC-12 « Erreur » :
  /// une interruption laisse la cible **intacte**, parce qu'elle n'a jamais été
  /// ouverte en écriture.
  @override
  Future<void> ecrire(String contenu) async {
    final provisoire = _provisoire;
    await provisoire.writeAsString(contenu, flush: true);
    await provisoire.rename(_cible.path);
  }

  @override
  Future<void> mettreDeCote() async {
    final cible = _cible;
    if (!cible.existsSync()) return;
    // ⛔ Le nom ne doit JAMAIS écraser une mise de côté antérieure : deux
    // documents illisibles successifs sont rares, mais les écraser serait
    // exactement la perte silencieuse que « jamais un delete » interdit.
    var destination =
        '${cible.path}.illisible-'
        '${clock.now().microsecondsSinceEpoch}';
    var rang = 0;
    while (File(destination).existsSync()) {
      rang++;
      destination =
          '${cible.path}.illisible-'
          '${clock.now().microsecondsSinceEpoch}-$rang';
    }
    await cible.rename(destination);
  }
}

/// ⚠️ **LA SEULE LIGNE DE CETTE US QUI N'EST PAS TESTABLE — borne NM-8.**
///
/// `path_provider` n'existe **ni en test hôte, ni en CI, ni sur le web** : il
/// n'a de sens que sur un appareil, **que ce projet n'a jamais eu**. Elle est
/// tenue à une ligne exprès (budget R-1), et ce qu'elle rend est **le même
/// objet** que celui qu'exercent les tests.
Future<DocumentStore> creerMagasin() async =>
    DocumentStoreFichier(await getApplicationDocumentsDirectory());
