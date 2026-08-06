import '../domain/echeance.dart';
import '../domain/echeance_repository.dart';
import 'document_store.dart';
import 'echeance_document_codec.dart';
import 'echeance_schema_migrations.dart';

/// Adaptateur du port métier (T7) : **lire → migrer → décoder**, écrire en
/// **atomique**, **mettre de côté** un document illisible.
///
/// ⛔ **Aucun `dart:io` ici** : il ne connaît du disque que le port
/// [DocumentStore].
class EcheanceDocumentRepository implements EcheanceRepository {
  EcheanceDocumentRepository(
    this.magasin, {
    this.codec = const EcheanceDocumentCodec(),
  });

  final DocumentStore magasin;
  final EcheanceDocumentCodec codec;

  /// Le dernier document lu — **il PORTE LES RÉSIDUS**, et c'est pour cela
  /// qu'il est conservé. `null` ⇒ **aucune écriture n'est permise** (voir
  /// [_ecrire]).
  DocumentEcheances? _document;

  @override
  Future<List<Echeance>> charger() async {
    final texte = await magasin.lire();
    if (texte == null) {
      // `v0` — aucun fichier. L'état vide est ici RÉELLEMENT atteignable
      // (AC-13 « Erreur »), et ⛔ rien n'est écrit avant un geste utilisateur.
      _document = codec.documentNeuf(versionCourante);
      return const <Echeance>[];
    }

    final racine = codec.lireRacine(texte);
    final version = racine == null ? null : lireVersion(racine);
    if (racine == null || version == null) {
      // Document ENTIER illisible, ou `schemaVersion` absent / non entier /
      // `< 1`. ⛔ On ne DEVINE jamais une version : deviner « c'est sûrement du
      // v1 », c'est risquer d'appliquer un `up` sur une forme incomprise.
      // ⇒ mise de côté par `rename`, puis état vide. ⛔ JAMAIS un `delete`.
      await _mettreDeCoteSansBruit();
      _document = codec.documentNeuf(versionCourante);
      return const <Echeance>[];
    }

    if (version > versionCourante) {
      // 🔴 **LA DISTINCTION LA PLUS FACILE À RATER, ET LA PLUS COÛTEUSE**
      // (§5 du schéma de stockage) : un document ÉCRIT PAR UNE VERSION PLUS
      // RÉCENTE est **parfaitement lisible par elle**. ⛔ Le mettre de côté
      // serait **destructeur en effet**, même si aucun octet n'est effacé.
      // ⇒ état vide **ET AUCUNE ÉCRITURE** : `_document` reste `null`, ce qui
      // fait refuser toute écriture ultérieure.
      // ⚠️ Conséquence produit assumée (§Hors périmètre, arbitrage du
      // 2026-08-06, voie b) : le pratiquant voit l'état vide **sans
      // explication** — mais ⛔ aucune donnée n'est touchée.
      _document = null;
      return const <Echeance>[];
    }

    final document = codec.decoderDocument(migrer(racine)!);
    _document = document;
    if (version != versionCourante) {
      // R-6 : après un `up` réussi, le document réécrit PORTE la nouvelle
      // version ⇒ la relecture suivante ne trouve plus rien à migrer.
      // ⛔ Si cette écriture échoue, les octets d'origine sont INTACTS
      // (écriture atomique) : AC-12 « Erreur » est vrai PAR CONSTRUCTION, et
      // la migration se rejouera simplement à la prochaine ouverture.
      // ⚠️ Les données migrées sont servies quand même : aucune n'est perdue.
      try {
        await magasin.ecrire(codec.encoder(document, document.echeances));
      } on Object {
        // Rien à faire : le disque est dans son état antérieur, qui est valide.
      }
    }
    return List<Echeance>.unmodifiable(document.echeances);
  }

  @override
  Future<ResultatEcriture> creer(Echeance echeance) => _ecrire(
    ActeEcriture.enregistrement,
    (liste) => <Echeance>[...liste, echeance],
  );

  @override
  Future<ResultatEcriture> remplacer(Echeance echeance) => _ecrire(
    ActeEcriture.enregistrement,
    (liste) => <Echeance>[
      for (final e in liste)
        if (e.id == echeance.id) echeance else e,
    ],
  );

  @override
  Future<ResultatEcriture> supprimer(String id) => _ecrire(
    ActeEcriture.suppression,
    (liste) => liste.where((e) => e.id != id).toList(),
  );

  /// 🔴 **U-6 ① appliqué** : rend un **refus TYPÉ**, ⛔ jamais `void`, ⛔ jamais
  /// un `Future` tiré et oublié. C'est ce retour qui rend AC-17 observable ;
  /// sans lui, l'appelant **ne pourrait pas connaître l'issue** et devrait
  /// muter l'état de façon optimiste.
  Future<ResultatEcriture> _ecrire(
    ActeEcriture acte,
    List<Echeance> Function(List<Echeance>) muter,
  ) async {
    final document = _document;
    if (document == null) {
      // Aucun chargement, ou document de version FUTURE. ⛔ Écrire ici
      // ÉCRASERAIT un document qu'on n'a pas su lire — le refus est la
      // protection, pas une limitation.
      return const ResultatEcriture.echec(ActeEcriture.enregistrement);
    }
    try {
      await magasin.ecrire(codec.encoder(document, muter(document.echeances)));
    } on Object {
      // ⛔ L'échec n'est JAMAIS silencieux, et l'état en mémoire n'est JAMAIS
      // muté : `_document` est inchangé, donc l'écran continue de refléter
      // exactement ce qui est sur le disque (règle métier d'AC-17).
      return ResultatEcriture.echec(acte);
    }
    return const ResultatEcriture.reussie();
  }

  Future<void> _mettreDeCoteSansBruit() async {
    try {
      await magasin.mettreDeCote();
    } on Object {
      // Une plateforme sans stockage lève ici (stub). Il n'y a rien à mettre
      // de côté, et ⛔ l'ouverture de l'application ne doit pas en dépendre :
      // le hub doit rester debout (AC-11 « Nominal »).
    }
  }
}
