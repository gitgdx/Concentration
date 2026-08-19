import 'dart:convert';

import '../domain/date_civile.dart';
import '../domain/echeance.dart';

/// Un document décodé : **ce qui est reconnu, et TOUT LE RESTE, verbatim**.
///
/// 🔴 **R-2 — le risque que cette classe existe pour fermer** : toute écriture
/// réécrit le **document entier**. Recomposer depuis les seules entités
/// **supprimerait les résidus**, et **AC-11 tomberait sans qu'aucun test
/// générique ne rougisse**. La forme brute est donc **transportée**, pas
/// reconstruite.
class DocumentEcheances {
  const DocumentEcheances(
    this.racine,
    this.lignes,
    this.echeances,
    this.idParIndex,
  );

  /// Le document **entier**, tel qu'il a été lu — `schemaVersion` et **toute
  /// clé de tête inconnue** comprises. ⛔ Aucune clé n'en est retirée.
  final Map<String, Object?> racine;

  /// Le tableau `echeances` **tel qu'il est sur le disque**, ordre compris.
  final List<Object?> lignes;

  /// Les entrées **reconnues**, dans l'ordre du document.
  final List<Echeance> echeances;

  /// `index dans [lignes]` → `id` reconnu. Une ligne **absente de cette table
  /// est un RÉSIDU** : c'est elle qui permet de la ré-émettre **à sa place**.
  final Map<int, String> idParIndex;
}

/// Encodage / décodage du document `echeances.json` (T4).
///
/// ⛔ **Aucun `dart:io` ici** : ce fichier est du calcul pur sur des chaînes,
/// donc compilable pour le web et testable sans disque.
class EcheanceDocumentCodec {
  const EcheanceDocumentCodec();

  /// Lit le JSON et rend la **racine**, ou `null` si le **document entier** est
  /// illisible : JSON invalide, racine non-objet, ou `echeances` qui n'est pas
  /// un tableau (grammaire du §2 du schéma de stockage).
  ///
  /// ⚖️ **Pourquoi `decoder(String)` de T4 est SCINDÉ EN DEUX** *(déviation
  /// nommée)* : T7 doit **MIGRER entre les deux moitiés** — `lire → migrer →
  /// décoder`. Une unique fonction `String → entités` rendrait la migration
  /// impossible sans un ré-encodage intermédiaire, c'est-à-dire une occasion
  /// supplémentaire de perdre un octet. La composition des deux moitiés
  /// **existe** et est éprouvée : [decoder].
  Map<String, Object?>? lireRacine(String texte) {
    final Object? brut;
    try {
      brut = jsonDecode(texte);
    } on FormatException {
      return null;
    }
    if (brut is! Map) return null;
    if (brut['echeances'] is! List) return null;
    return Map<String, Object?>.from(brut);
  }

  /// Sépare les **entrées reconnues** des **résidus**. ⛔ Ne répare rien, ne
  /// normalise rien, ne supprime rien.
  DocumentEcheances decoderDocument(Map<String, Object?> racine) {
    final lignes = racine['echeances']! as List<Object?>;
    final echeances = <Echeance>[];
    final idParIndex = <int, String>{};
    final dejaVus = <String>{};
    for (var i = 0; i < lignes.length; i++) {
      final lue = _reconnaitre(lignes[i], dejaVus);
      if (lue == null) continue;
      echeances.add(lue);
      idParIndex[i] = lue.id;
    }
    return DocumentEcheances(racine, lignes, echeances, idParIndex);
  }

  /// Composition des deux moitiés — `null` si le document entier est illisible.
  DocumentEcheances? decoder(String texte) {
    final racine = lireRacine(texte);
    return racine == null ? null : decoderDocument(racine);
  }

  /// Un document **neuf** (`v0` — aucun fichier), à la version indiquée.
  DocumentEcheances documentNeuf(int version) => DocumentEcheances(
    <String, Object?>{'schemaVersion': version, 'echeances': <Object?>[]},
    const <Object?>[],
    const <Echeance>[],
    const <int, String>{},
  );

  /// Réécrit le document **entier** avec [echeances] pour seule vérité des
  /// entrées reconnues.
  ///
  /// 🔴 **Trois garanties, et elles sont la contrepartie du document unique** :
  /// * un **résidu** est ré-émis **octet pour octet, à SA PLACE** ;
  /// * les **clés inconnues** d'une entrée reconnue **survivent** à sa mise à
  ///   jour *(le littéral Dart conserve la position de première insertion, donc
  ///   une entrée inchangée se réécrit à l'identique)* ;
  /// * une entrée **absente** de [echeances] est **supprimée** — c'est le seul
  ///   acte destructif, et il vient d'une confirmation explicite (AC-7).
  String encoder(DocumentEcheances document, List<Echeance> echeances) {
    final parId = <String, Echeance>{for (final e in echeances) e.id: e};
    final sortie = <Object?>[];
    for (var i = 0; i < document.lignes.length; i++) {
      final id = document.idParIndex[i];
      if (id == null) {
        sortie.add(document.lignes[i]);
        continue;
      }
      final aJour = parId.remove(id);
      if (aJour == null) continue;
      sortie.add(_encoderEntree(aJour, document.lignes[i]! as Map));
    }
    for (final creee in parId.values) {
      sortie.add(_encoderEntree(creee, null));
    }
    final racine = Map<String, Object?>.from(document.racine);
    racine['echeances'] = sortie;
    return jsonEncode(racine);
  }

  /// `null` ⇒ **résidu** : l'entrée est conservée telle quelle et n'est **pas
  /// affichée** (AC-11 « Erreur »).
  Echeance? _reconnaitre(Object? ligne, Set<String> dejaVus) {
    if (ligne is! Map) return null;
    final id = ligne['id'];
    if (id is! String || id.isEmpty) return null;
    // `id` EN DOUBLE : la PREMIÈRE occurrence est reconnue, les suivantes sont
    // des résidus — ⛔ ni supprimées, ni affichées (deux `Key` de widgets de
    // même valeur entreraient en collision). Règle laissée SANS AC par
    // arbitrage humain du 2026-08-06, voie (b) ⇒ test unitaire déclaré.
    if (!dejaVus.add(id)) return null;
    final date = ligne['dateEcheance'];
    if (date is! String) return null;
    // ⛔ LA barrière : forme canonique, pas exception (règle V-1).
    final instant = litDateCivile(date);
    if (instant == null) return null;
    final description = ligne.containsKey('description')
        ? ligne['description']
        : '';
    if (description is! String) return null;
    // Passe par la frontière de l'entité (I-6) : c'est ici que `depuisDonnee`
    // gagne son PREMIER APPELANT RÉEL (finding N-6 d'US-01.1).
    return Echeance.depuisDonnee(<String, Object?>{
      'id': id,
      'description': description,
      'dateEcheance': instant,
    });
  }

  Map<String, Object?> _encoderEntree(
    Echeance echeance,
    Map<Object?, Object?>? origine,
  ) {
    return <String, Object?>{
      if (origine != null)
        for (final cle in origine.keys) '$cle': origine[cle],
      'id': echeance.id,
      'description': echeance.description,
      // AC-14 : date-heure CIVILE, ⛔ ni `Z`, ni décalage, ni secondes.
      'dateEcheance': formatCivil(echeance.dateEcheance),
    };
  }
}
