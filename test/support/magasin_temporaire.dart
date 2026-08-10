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

import 'dart:convert';
import 'dart:io';

import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/document_store.dart';
import 'package:concentration/features/echeances/data/document_store_io.dart';
import 'package:concentration/features/echeances/data/echeance_document_codec.dart';
import 'package:concentration/features/echeances/data/echeance_document_repository.dart';
import 'package:concentration/features/echeances/data/echeance_schema_migrations.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/presentation/echeances_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Les documents du bloquant `B-1`, en **UN SEUL EXEMPLAIRE** — ⛔ jamais
// recopiés dans un fichier de test : deux copies d'une fixture dérivent, et
// c'est la classe de défaut nº 1 de ce dépôt.
//
// ⚠️ Ce sont des **fonctions**, pas des constantes : une liste partagée entre
// deux tests pourrait être mutée par l'un et fausser l'autre en silence.
// ---------------------------------------------------------------------------

const String _prefixeB1 =
    '{"schemaVersion":2,"echeances":[{"id":"b1","description":"r';
const String _suffixeB1 = 'vision","dateEcheance":"2027-03-15T23:59"}]}';

/// 🔴 **Le document de `B-1`** : un JSON **PARFAITEMENT VALIDE**, structure
/// intacte, dont **UN SEUL octet** n'est pas décodable en UTF-8 — « révision »
/// tel que l'écrit un éditeur de texte réglé en **cp1252** *(Notepad par
/// défaut)*. Le pratiquant qui corrige un libellé à la main produit **exactement
/// ceci**.
List<int> documentNonDecodable() => <int>[
  ...utf8.encode(_prefixeB1),
  0xE9, // « é » en cp1252 — ⛔ séquence UTF-8 invalide à elle seule
  ...utf8.encode(_suffixeB1),
];

/// ⛔ **LE CONTRÔLE NÉGATIF, et c'est lui qui fait de la paire une MESURE plutôt
/// qu'une relecture** : le **MÊME** document, à la **MÊME** place, avec
/// « révision » en UTF-8 **valide**. La seule différence est l'encodage d'une
/// lettre — **un octet contre deux** — et le verdict doit **BASCULER**.
///
/// ⚠️ **Sans ce document, le test de `B-1` passerait aussi avec un magasin qui
/// déclarerait TOUT illisible.**
List<int> documentDecodable() => <int>[
  ...utf8.encode(_prefixeB1),
  ...utf8.encode('é'),
  ...utf8.encode(_suffixeB1),
];

/// La **TRONCATURE** — le mot **littéral** d'AC-11 « Erreur » *(« fichier
/// tronqué »)* : le document est coupé **au milieu** d'une séquence multi-octets,
/// ce qu'aucune coupure d'un document purement ASCII ne peut produire.
List<int> documentTronqueEnPleineSequence() => <int>[
  ...utf8.encode(_prefixeB1),
  utf8.encode('é').first,
];

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
  ///
  /// 🔴 **DÉFAUT DE HARNAIS TROUVÉ PAR EXÉCUTION, ⛔ PAS un défaut du produit.**
  /// Sous Windows, le `rename` de l'**écriture atomique** verrouille brièvement
  /// la cible (`errno 32`, *« le fichier est utilisé par un autre
  /// processus »*). Une lecture **synchrone** tombant dans cette fenêtre
  /// **LÈVE** — et l'échec s'imputait au **produit**, sur un test **une fois
  /// sur trois**. Or ce n'est NI « le fichier n'existe pas », NI « le contenu
  /// vaut X » : c'est **« pas lisible à cet instant »**.
  ///
  /// ⛔ **On ne rend JAMAIS une valeur mémorisée** *(ce serait un mensonge, et
  /// c'est précisément le mutant que le test du harnais tue)* et ⛔ **on
  /// n'avale JAMAIS l'erreur** : on réessaie brièvement, puis on **RELÈVE**.
  String? octets() {
    final brut = octetsBruts();
    return brut == null ? null : utf8.decode(brut);
  }

  /// Les octets **BRUTS** du fichier cible, ou `null` s'il n'existe pas.
  ///
  /// 🔴 **⛔ [octets] NE PEUT PAS servir à assertionner un document illisible** :
  /// il **décode en UTF-8**, donc il **LÈVE** exactement dans le cas à
  /// vérifier — c'est-à-dire sur le document du bloquant `B-1`. La clause
  /// d'AC-11 *« ni réécrit ni supprimé »* ne se vérifie donc **que sur les
  /// octets**.
  List<int>? octetsBruts() => _lireOctets(fichier);

  /// Les octets bruts d'un fichier du répertoire, **désigné par son nom** —
  /// ⛔ jamais par sa position dans la liste.
  List<int>? octetsBrutsDe(String nom) =>
      _lireOctets(File('${repertoire.path}${Platform.pathSeparator}$nom'));

  /// La boucle de réessai vit **ICI, en un seul exemplaire** : deux copies de
  /// cette règle auraient dérivé, et l'une aurait fini par avaler l'erreur.
  List<int>? _lireOctets(File source) {
    for (var essai = 0; ; essai++) {
      try {
        return source.existsSync() ? source.readAsBytesSync() : null;
      } on FileSystemException {
        if (essai >= 40) rethrow;
        sleep(const Duration(milliseconds: 5));
      }
    }
  }

  /// Pose un contenu **directement sur le disque**, avant tout démarrage.
  void poser(String contenu) => fichier.writeAsStringSync(contenu, flush: true);

  /// Pose des **OCTETS ARBITRAIRES** directement sur le disque.
  ///
  /// 🔴 **CETTE MÉTHODE EXISTE PARCE QUE SON ABSENCE A RENDU `B-1` INVISIBLE, et
  /// ce n'est pas une intuition : c'est une MESURE.** Avant le 2026-08-07,
  /// `grep -rn "writeAsBytes|utf8.encode|latin1|0xFF|readAsBytes" test/` rendait
  /// **AUCUNE occurrence** : [poser] passe par `writeAsStringSync`, donc
  /// ⛔ **il ne PEUT produire que de l'UTF-8 valide**. Les 3 tests d'AC-11
  /// exerçaient du **JSON invalide**, ⛔ **jamais des OCTETS invalides** ⇒ la
  /// classe entière était **hors d'atteinte du harnais**, et **344 tests avec
  /// 97,9 % de couverture n'ont rien vu**.
  ///
  /// ⚠️ **Ce que cela dit du cliquet, et qui vaut au-delà de cette US** : la
  /// couverture **MONTAIT** sur le diff qui introduisait le bloquant. Un harnais
  /// qui ne peut pas fabriquer l'entrée fautive **efface la clause** qu'il
  /// prétendait vérifier — même famille que « ce qui doit être refusé doit
  /// d'abord pouvoir être saisi ».
  void poserOctets(List<int> octets) =>
      fichier.writeAsBytesSync(octets, flush: true);

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

/// Un notifier **ADOSSÉ AU DISQUE**, déjà chargé avec [echeances].
///
/// ⚖️ **Le seam `ConcentrationApp(echeances:)` d'US-01.1 a été SUPPRIMÉ**
/// (ADR-011 §5) : un jeu de données ne s'**injecte** plus, il s'**écrit**.
/// Cette fonction est la voie de remplacement, et elle **traverse le codec, le
/// magasin fichier et le dépôt de PRODUCTION** — ⛔ elle ne court-circuite rien.
Future<EcheancesNotifier> notifierCharge(
  WidgetTester tester,
  MagasinTemporaire harnais,
  List<Echeance> echeances, {
  required Clock clock,
}) async {
  const codec = EcheanceDocumentCodec();
  harnais.poser(codec.encoder(codec.documentNeuf(versionCourante), echeances));
  final notifier = EcheancesNotifier(
    depot: EcheanceDocumentRepository(harnais.magasin),
    clock: clock,
  );
  await tester.runAsync(notifier.charger);
  return notifier;
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
