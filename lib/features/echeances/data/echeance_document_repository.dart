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

  /// 🔴 **Pourquoi une exception d'ici est FATALE** : `main()` l'`await` **avant
  /// `runApp`**, donc toute exception qui en sortirait **empêcherait
  /// l'application de démarrer** — c'était le bloquant `B-1` (audit sécurité du
  /// 2026-08-07).
  ///
  /// ⚖️ **`NB-J` (revue de code du 2026-08-11) — la version antérieure écrivait
  /// « ⛔ NE LÈVE JAMAIS », une affirmation ABSOLUE qu'aucun mécanisme
  /// n'enforçait** : ni type de retour, ni gate, ni test. **Même classe que
  /// `NB-A`** *(un contrat écrit qui n'est pas garanti DÉRIVE)*, et la voie prise
  /// est la même : **la doc dit ce qui EST, et rien de plus**.
  ///
  /// **⛔ NE LÈVE PAS pour ces classes d'échec — et chacune a SON test** :
  /// * **aucun fichier** (`v0`) et **document lu normalement** ;
  /// * **octets non décodables**, y compris à **un seul octet** près *(`B-1`)* ;
  /// * un **occupant qui n'est pas un fichier** au nom du document *(`NB-F`)* ;
  /// * **racine non-JSON**, `schemaVersion` **absent**, **non entier** ou `< 1` ;
  /// * document de **version FUTURE** ;
  /// * **échec de la réécriture** qui suit une migration montante ;
  /// * **échec de la mise de côté**, quelle que soit l'exception levée par le
  ///   magasin *(`on Object`, ⛔ pas `on FileSystemException` : le stub lève un
  ///   `UnsupportedError`, et un type attrapé trop étroit ferait ressortir
  ///   l'exception ⇒ **`B-1` à nouveau**)*.
  ///
  /// ⛔ **CE QUI N'EST PAS GARANTI, et c'est écrit au lieu d'être promis** : elle
  /// **LÈVE** si le magasin **viole son contrat** en levant depuis
  /// [DocumentStore.lire] — ⛔ ce n'est **pas** attrapé ici, délibérément *(un
  /// `catch` de plus masquerait les erreurs de PROGRAMMATION, exactement ce que
  /// la garde étroite de `document_store_io.dart` refuse)*. **Cette borne est
  /// épinglée par un test**, ⛔ pas laissée à la relecture.
  @override
  Future<List<Echeance>> charger() async {
    final String texte;
    // ⚖️ `switch` sur un type SCELLÉ, donc EXHAUSTIF : le jour où le port gagne
    // un quatrième cas, le compilateur **refuse ce fichier** au lieu de laisser
    // l'application démarrer sur une branche non traitée.
    switch (await magasin.lire()) {
      case DocumentAbsent():
        // `v0` — aucun fichier. L'état vide est ici RÉELLEMENT atteignable
        // (AC-13 « Erreur »), et ⛔ rien n'est écrit avant un geste utilisateur.
        _document = codec.documentNeuf(versionCourante);
        return const <Echeance>[];
      case DocumentIllisible():
        // Le fichier EXISTE et n'a pas pu être lu (octets non décodables, droit
        // refusé). ⛔ Ce n'est PAS `v0` : écrire sans mettre de côté écraserait
        // un document qu'on n'a pas su lire.
        return _misDeCotePuisEtatVide();
      case DocumentLu(contenu: final lu):
        texte = lu;
    }

    final racine = codec.lireRacine(texte);
    final version = racine == null ? null : lireVersion(racine);
    if (racine == null || version == null) {
      // Document ENTIER illisible, ou `schemaVersion` absent / non entier /
      // `< 1`. ⛔ On ne DEVINE jamais une version : deviner « c'est sûrement du
      // v1 », c'est risquer d'appliquer un `up` sur une forme incomprise.
      return _misDeCotePuisEtatVide();
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
      //
      // 🔴 **`acte`, ⛔ JAMAIS `ActeEcriture.enregistrement` en dur** (`NB-B`,
      // revue de code du 2026-08-07) : l'acte était codé en dur ici alors que
      // la branche `catch` du même corps, elle, le portait correctement ⇒ une
      // **suppression** refusée annonçait *« L'échéance n'a pas été
      // enregistrée. »*. C'est exactement ce que le motif écrit dans le port
      // interdit : *« Deux textes, pas un […] l'utilisateur doit savoir CE QUI
      // n'a pas eu lieu. »*
      return ResultatEcriture.echec(acte);
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

  /// Mise de côté **par `rename`** puis état vide — ⛔ **JAMAIS un `delete`**.
  ///
  /// ⚖️ **En UN SEUL exemplaire** *(règle du projet : « une règle n'existe qu'en
  /// un seul exemplaire »)* : les **deux** familles d'illisible — le document
  /// que le magasin n'a pas su rendre *(`B-1`)* et celui dont la racine ou la
  /// version est incompréhensible — doivent aboutir **exactement** au même
  /// traitement. Deux copies auraient dérivé.
  ///
  /// 🔴 **CE QUE CETTE MÉTHODE FAIT DÉPEND DE L'ISSUE DE LA MISE DE CÔTÉ, et
  /// c'était le bloquant `B-2`** *(audit sécurité du 2026-08-11)*.
  ///
  /// * **Mise de côté RÉUSSIE** ⇒ `_document` est un document **NEUF** : le nom
  ///   du document est **libre**, la prochaine écriture est **légitime** et
  ///   n'écrase plus rien — **c'est ce qui ferme la PERMANENCE de `B-1`**, où
  ///   chaque démarrage échouait à l'identique.
  /// * **Mise de côté ÉCHOUÉE** ⇒ `_document` reste **`null`**, donc [_ecrire]
  ///   **REFUSE tout** : le document illisible est **toujours sur le disque**, et
  ///   écrire par-dessus lui serait **exactement** la réfutation qu'AC-11
  ///   « Erreur » inscrit dans sa table *(« l'enregistrement fautif est
  ///   **réécrit** ou supprimé »)*. ⛔ **Une destruction totale, silencieuse et
  ///   irréversible** — ⛔ pas une gêne d'ergonomie.
  ///
  /// ⚠️ **La version antérieure posait `documentNeuf` INCONDITIONNELLEMENT** et
  /// sa documentation affirmait *« la prochaine écriture est légitime et n'écrase
  /// plus rien »* : c'était **FAUX dès que le `rename` échouait**, et la première
  /// saisie du pratiquant détruisait ses données **sans message, sans copie, sans
  /// trace**. Le chemin « version FUTURE » de [charger], à vingt lignes d'ici,
  /// **traitait déjà correctement le même danger** — les deux convergent enfin.
  ///
  /// ⚖️ **État résultant, assumé** *(même compromis que « version FUTURE »,
  /// arbitré au Story File)* : hub **vide** et écriture **refusée avec le message
  /// du port** (AC-17). ✅ **Et il s'AUTO-RÉPARE** : l'obstacle disparu, le
  /// démarrage suivant met le document de côté et l'écriture redevient possible.
  Future<List<Echeance>> _misDeCotePuisEtatVide() async {
    _document = await _tenterMiseDeCote()
        ? codec.documentNeuf(versionCourante)
        : null;
    return const <Echeance>[];
  }

  /// `true` **si et seulement si** le document n'est plus au nom du document.
  ///
  /// 🔴 **L'exception est CONVERTIE, ⛔ jamais perdue** — et c'est là toute la
  /// différence avec l'avalement d'avant *(un `on Object` au corps **vide**,
  /// donc **sans aucune ligne à instrumenter** : ⛔ la couverture ne pouvait
  /// **structurellement pas** signaler qu'il n'était jamais emprunté)*.
  ///
  /// ⚖️ **Pourquoi le `catch` doit RESTER, alors que `B-2` est corrigé** *(la
  /// question posée par `NB-D`)* : [charger] est `await`é **avant `runApp`** ⇒ une
  /// exception qui sortirait d'ici **empêcherait l'application de démarrer**,
  /// c'est-à-dire **`B-1` à nouveau**. Le devoir de ce `catch` n'est donc pas de
  /// **taire** l'échec mais de le **rendre exploitable** : `false` **désarme
  /// l'écriture**.
  ///
  /// ⛔ **`NB-D` — le motif écrit ici invoquait le stub** *(« une plateforme sans
  /// stockage lève ici »)* : **c'est FAUX, et la mesure le montre** — le stub rend
  /// **toujours** `DocumentAbsent`, cas sur lequel [charger] **retourne**, donc ce
  /// chemin y est **INATTEIGNABLE**. Une doc périmée **légitimait** un
  /// comportement dangereux et **décourageait de le regarder**. Le motif RÉEL est
  /// le magasin **fichier** : `rename` refusé *(document ouvert par un antivirus,
  /// une synchronisation, une seconde instance)*, occupant non-fichier au nom du
  /// document, ou **tous** les noms de destination déjà pris *(borne de
  /// `mettreDeCote`)*.
  Future<bool> _tenterMiseDeCote() async {
    try {
      await magasin.mettreDeCote();
      return true;
    } on Object {
      // ⛔ Le document est TOUJOURS là. L'appelant doit REFUSER d'écrire.
      return false;
    }
  }
}
