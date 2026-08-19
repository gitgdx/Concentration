/// **Port de PLATEFORME** — le magasin d'octets (T6).
///
/// ⛔ **Aucun `dart:io` ici**, ⛔ aucun `path_provider` : ce fichier est
/// atteignable par le web. La seule implémentation qui touche un disque vit
/// dans `document_store_io.dart`, atteint **uniquement** par import conditionnel
/// (ADR-009 §2, pattern nº 3).
///
/// ⚖️ **Deux ports, deux niveaux, et ⛔ ne pas les fusionner** (pattern nº 2) :
/// `EcheanceRepository` est le port **métier** (`domain/`), celui-ci est le port
/// **de plateforme**. C'est cette séparation qui rend le dépôt testable **sans
/// disque** et le magasin testable **sans métier**.
library;

/// Nom du document, en **un seul exemplaire**.
const String nomDocument = 'echeances.json';

/// Ce que rend **toute** lecture du document : **trois cas, et c'est le TYPE
/// qui les impose**.
///
/// 🔴 **Né du bloquant `B-1` (audit sécurité du 2026-08-07), et la forme
/// choisie n'est pas cosmétique.** `lire()` rendait `Future<String?>`, où
/// `null` signifiait « aucun fichier ». Le troisième cas — **le fichier existe
/// et n'a pas pu être lu** — n'avait **aucune place dans le type**, donc il
/// s'exprimait par la seule voie restante : une **exception qui traversait
/// tout**, jusqu'à `main()` qui l'`await` **avant `runApp`**. ⇒ l'application
/// ne démarrait **plus jamais**, et comme l'échec avait lieu **à la lecture**,
/// la mise de côté n'était **jamais atteinte** : le document fautif restait en
/// place, sans aucune issue depuis l'application.
///
/// ⚖️ **Pourquoi un type SCELLÉ plutôt que la sentinelle non-JSON proposée par
/// l'auditeur** *(rendre `'U+0000'` pour faire échouer le décodage en aval)* —
/// trois motifs, et le coût sur les deux implémentations est assumé :
/// * **① Symétrie avec le côté ÉCRITURE, que ce projet a déjà payée.**
///   `EcheanceRepository` impose un **refus TYPÉ** (`ResultatEcriture`,
///   *« ⛔ jamais `void` »*) précisément parce qu'une issue laissée hors du type
///   *peut être ignorée par l'appelant*. **La lecture méritait le même
///   traitement** : c'est la même règle, appliquée au même endroit.
/// * **② Une BARRIÈRE de compilation remplace une DISCIPLINE.** Un `switch`
///   sur un type scellé est **exhaustif** : une future implémentation du port
///   **ne peut pas oublier** de dire dans quel cas elle est, et
///   `EcheanceDocumentRepository.charger` **ne peut pas oublier** de traiter
///   l'illisible — le compilateur refuse. Avec une sentinelle, la correction
///   ne tient qu'à ce que l'appelant *traite par chance* une valeur magique
///   comme du JSON invalide, et **rien** ne relie `'U+0000'` à « illisible ».
/// * **③ Le contrat cesse d'être FAUX.** *« Le contenu du document »* et
///   *« la chaîne `'U+0000'` quand je n'ai pas su le lire »* ne peuvent pas
///   être le même type de retour sans mentir.
///
/// ⛔ **Ce qu'on ne fait PAS, et l'auditeur a raison de le proscrire** :
/// `utf8.decode(..., allowMalformed: true)`. Il ne lève plus, mais il remplace
/// les octets fautifs par `U+FFFD` ⇒ le document **parse**, l'échéance
/// **s'affiche altérée**, et la prochaine écriture **fige la corruption**.
/// C'est une **correction silencieuse d'une donnée que l'utilisateur n'a pas
/// saisie**, ce qu'AC-11 « Erreur » *(« ni affiché, ni réécrit »)* et AC-16
/// interdisent. **Le bon comportement est de traiter le document comme
/// illisible, ⛔ pas de le réparer.**
sealed class LectureDocument {
  const LectureDocument();
}

/// **Aucun fichier** — c'est `v0`, l'installation neuve, et l'état vide y est
/// **réellement atteignable** (AC-13 « Erreur »).
///
/// ⛔ **À ne JAMAIS confondre avec [DocumentIllisible]** : ici il n'y a rien à
/// mettre de côté et la première écriture est **légitime**. Là-bas, écrire sans
/// mise de côté **écraserait un document qu'on n'a pas su lire**.
final class DocumentAbsent extends LectureDocument {
  const DocumentAbsent();
}

/// Le document a été lu ; [contenu] est ce qu'il porte, **tel quel**.
final class DocumentLu extends LectureDocument {
  const DocumentLu(this.contenu);

  final String contenu;
}

/// Le document **EXISTE** et le magasin **n'a pas su le rendre** : octets non
/// décodables, droit refusé, disparition entre le test d'existence et la
/// lecture, ou **un occupant qui n'est pas un fichier** *(`NB-F` : un
/// **répertoire** portant le nom du document — « il y a quelque chose et je n'ai
/// pas su le lire », ⛔ **jamais `v0`**)*.
///
/// 🔴 **C'est « ILLISIBLE », pas « FATAL »** (AC-11 « Erreur ») : l'application
/// **s'ouvre**, le document fautif est **mis de côté par `rename`** — ⛔ jamais
/// réécrit, ⛔ jamais supprimé — et l'écriture redevient possible. **C'est cette
/// dernière propriété qui ferme la PERMANENCE de `B-1`.**
final class DocumentIllisible extends LectureDocument {
  const DocumentIllisible();
}

abstract interface class DocumentStore {
  /// L'état du document sur le support — voir [LectureDocument].
  ///
  /// 🔴 **⛔ NE LÈVE JAMAIS pour un document illisible** : elle rend
  /// [DocumentIllisible]. C'est la seule forme qui laisse l'appelant **ouvrir
  /// l'application** ; une exception, elle, remontait jusqu'à `main()` et
  /// empêchait `runApp` (bloquant `B-1`).
  Future<LectureDocument> lire();

  /// Écrit le document **entier**, de façon **ATOMIQUE**.
  ///
  /// 🔴 **Lève en cas d'échec — ⛔ JAMAIS un échec silencieux.** C'est ce qui
  /// permet à AC-17 d'exister : sur une plateforme sans stockage, l'application
  /// doit **dire** qu'elle ne persiste pas, pas faire semblant.
  Future<void> ecrire(String contenu);

  /// Met le document **illisible** de côté, par `rename`.
  ///
  /// ⛔ **JAMAIS un `delete`** (AC-11 « Limite ») : un document illisible se met
  /// de côté pour que l'application puisse écrire de nouveau, ⛔ il ne se
  /// détruit pas.
  ///
  /// 🔴 **LÈVE quand la mise de côté N'A PAS EU LIEU — ⛔ jamais un succès
  /// silencieux, et c'est le contrat sur lequel repose la correction de `B-2`**
  /// *(audit sécurité du 2026-08-11)* : si l'appelant ne peut pas distinguer
  /// « déplacé » de « toujours là », il **autorise l'écriture par-dessus un
  /// document qu'il n'a pas su lire** ⇒ **destruction silencieuse**, exactement
  /// la réfutation qu'AC-11 « Erreur » inscrit dans sa table.
  /// ⚠️ Rendre normalement **signifie donc** : *« il n'y a plus rien à ce nom »*
  /// — soit parce que le document a été déplacé, soit parce qu'il n'y avait
  /// **rien** à déplacer.
  Future<void> mettreDeCote();
}
