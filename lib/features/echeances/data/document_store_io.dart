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

  /// 🔴 **LA GARDE QUI FERME LE BLOQUANT `B-1`** *(audit sécurité du
  /// 2026-08-07)*, et ⛔ **elle ne se relit pas : elle se MESURE.**
  ///
  /// `File.readAsString()` décode en UTF-8 **STRICT** et **LÈVE** une
  /// `FileSystemException` — *« Failed to decode data using encoding 'utf-8' »*
  /// — dès qu'**un seul octet** n'est pas décodable, dans un JSON par ailleurs
  /// **parfaitement valide**. C'est le cas de « révision » enregistré en
  /// **cp1252** par l'éditeur de texte du système, d'une **troncature** tombant
  /// au milieu d'une séquence multi-octets *(le mot littéral d'AC-11)*, ou d'une
  /// **restauration de sauvegarde partielle**.
  ///
  /// **Sans cette garde, l'exception traversait `charger()` puis `main()`, qui
  /// l'`await` AVANT `runApp` ⇒ l'application ne démarrait plus jamais** ; et
  /// comme l'échec avait lieu **à la lecture**, [mettreDeCote] n'était **jamais
  /// atteint** ⇒ le document fautif **restait en place**, sans aucune issue
  /// depuis l'application.
  ///
  /// ⚠️ **Le `try` n'entoure QUE la lecture, pas le test d'existence** : rendre
  /// [DocumentIllisible] pour un fichier **absent** ferait mettre de côté ce qui
  /// n'existe pas et **brouillerait `v0`**.
  ///
  /// 🔴 **`NB-F` (audit sécurité du 2026-08-11) — ⛔ « aucun fichier » et « pas
  /// un fichier » ne sont PAS la même chose, et `File.existsSync()` les
  /// confondait** : il rend **`false` pour un RÉPERTOIRE** portant le nom du
  /// document *(mesuré)*. Le nom était donc annoncé **`v0`** alors que quelque
  /// chose l'**occupait**, et seule l'atomicité de l'écriture évitait le dommage
  /// — *le bon comportement par accident, pas par intention*.
  /// ⇒ **le TYPE est lu, pas l'existence** : un occupant qui n'est pas un
  /// fichier est **ILLISIBLE** *(« il y a quelque chose et je n'ai pas su le
  /// lire »)*, ⛔ jamais `v0`.
  ///
  /// ⚠️ **Ce que ce choix ne change PAS, délibérément** : `followLinks` reste à
  /// sa valeur par défaut *(les liens sont **suivis**, comme le faisait
  /// `existsSync`)* ⇒ un lien mort reste **`v0`** et un lien vers un fichier
  /// reste **lu**. La question du lien symbolique est **`N-1`**, hors périmètre
  /// de ce correctif — ⛔ on ne la tranche pas au passage.
  @override
  Future<LectureDocument> lire() async {
    final cible = _cible;
    final occupant = FileSystemEntity.typeSync(cible.path);
    if (occupant == FileSystemEntityType.notFound) {
      return const DocumentAbsent();
    }
    if (occupant != FileSystemEntityType.file) {
      // Un RÉPERTOIRE (ou tout autre occupant) porte le nom du document.
      // ⛔ Ni `v0` — il y a quelque chose — ni une lecture : `readAsString`
      // lèverait, et l'exception traversait `main()` (c'était `B-1`).
      return const DocumentIllisible();
    }
    try {
      return DocumentLu(await cible.readAsString());
    } on FileSystemException {
      // ⛔ Ni `allowMalformed`, ni valeur par défaut, ni fichier réparé : le
      // document est traité comme ILLISIBLE, donc mis de côté par `rename` en
      // amont — jamais réécrit, jamais supprimé (AC-11 « Erreur »).
      //
      // ⚠️ Le type attrapé est ÉTROIT par choix : `FileSystemException` couvre
      // l'échec de décodage, le droit refusé et la disparition du fichier entre
      // le test et la lecture (fenêtre TOCTOU). ⛔ Un `on Object` masquerait en
      // plus les erreurs de programmation, ce qui rendrait un défaut futur
      // INVISIBLE — exactement la classe de bug que cette garde corrige.
      return const DocumentIllisible();
    }
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

  /// Le nom de destination d'une mise de côté, **pour un rang donné**.
  ///
  /// 🔴 **EN UN SEUL EXEMPLAIRE, et ce n'est pas une élégance** : la règle de
  /// nommage était écrite **DEUX FOIS** dans la boucle de [mettreDeCote] — la
  /// classe de défaut nº 1 de ce dépôt *(« une règle n'existe qu'en un seul
  /// exemplaire », deux copies dérivent)*.
  ///
  /// ⚠️ **Publique EXPRÈS** *(même motif que `transformerDates`)* : c'est ce qui
  /// permet à un test d'**OCCUPER les candidats** sans recopier la règle. ⛔ Un
  /// test qui écrirait le nom à la main mesurerait sa propre copie.
  ///
  /// ⚠️ **La destination reste PRÉVISIBLE** *(`NB-G`)* : elle dérive de
  /// l'horloge injectée, et ⛔ **ce correctif ne ferme PAS cette
  /// prévisibilité** — la fermer demanderait une source d'aléa, donc une
  /// décision qui appartient à `N-1` *(création en exclusif, répertoire partagé)*,
  /// **hors périmètre**. Ce qui est corrigé ici est l'**aveuglement** de la
  /// boucle, ⛔ pas l'imprévisibilité du nom.
  String destinationMiseDeCote(int rang) =>
      '${_cible.path}.illisible-${clock.now().microsecondsSinceEpoch}'
      '${rang == 0 ? '' : '-$rang'}';

  /// 🔴 **LÈVE si le document n'a PAS été mis de côté** — ⛔ jamais un succès
  /// silencieux. C'est ce que `B-2` a coûté : un échec avalé ici faisait
  /// autoriser l'écriture **par-dessus un document toujours présent**.
  @override
  Future<void> mettreDeCote() async {
    final cible = _cible;
    // ⛔ `NB-F` : le TYPE, pas l'existence — `File.existsSync()` rend `false`
    // pour un répertoire, donc un occupant non-fichier faisait rendre « rien à
    // faire » alors qu'il y avait bien quelque chose.
    if (FileSystemEntity.typeSync(cible.path) ==
        FileSystemEntityType.notFound) {
      return;
    }
    // ⛔ Le nom ne doit JAMAIS écraser une mise de côté antérieure : deux
    // documents illisibles successifs sont rares, mais les écraser serait
    // exactement la perte silencieuse que « jamais un delete » interdit.
    //
    // 🔴 **`NB-G` : la boucle était AVEUGLE à un occupant non-fichier** —
    // `File(destination).existsSync()` rend **`false` pour un répertoire**, donc
    // le `rename` partait **droit dessus** et levait. Ici c'est le **type** qui
    // est lu, `followLinks: false` pour qu'un **lien mort** compte lui aussi
    // comme un occupant *(le remplacer serait silencieux)*.
    for (var rang = 0; rang < essaisMiseDeCote; rang++) {
      final destination = destinationMiseDeCote(rang);
      if (FileSystemEntity.typeSync(destination, followLinks: false) !=
          FileSystemEntityType.notFound) {
        continue;
      }
      await cible.rename(destination);
      return;
    }
    // ⛔ **BORNÉE, et la borne LÈVE** : ⛔ jamais une boucle sans borne sur un
    // état du disque qu'un tiers contrôle, et ⛔ surtout jamais un `return`
    // muet ici — ce serait exactement `B-2` : l'appelant croirait le document
    // mis de côté et l'écraserait à la première saisie.
    throw FileSystemException(
      'Aucun nom libre pour mettre le document de côté',
      cible.path,
    );
  }
}

/// Nombre de noms essayés par [DocumentStoreFichier.mettreDeCote] — **borné**.
///
/// ⚠️ **Il n'a pas besoin d'être grand, il a besoin d'être FINI** : une
/// collision exige la **même microseconde** sur l'horloge réelle. Au-delà, la
/// mise de côté **lève** — l'application s'ouvre, et ⛔ **toute écriture est
/// refusée** plutôt que d'écraser *(voir `B-2`)*.
const int essaisMiseDeCote = 8;

/// ⚠️ **LA SEULE LIGNE DE CETTE US QUI N'EST PAS TESTABLE — borne NM-8.**
///
/// `path_provider` n'existe **ni en test hôte, ni en CI, ni sur le web** : il
/// n'a de sens que sur un appareil, **que ce projet n'a jamais eu**. Elle est
/// tenue à une ligne exprès (budget R-1), et ce qu'elle rend est **le même
/// objet** que celui qu'exercent les tests.
Future<DocumentStore> creerMagasin() async =>
    DocumentStoreFichier(await getApplicationDocumentsDirectory());
