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

abstract interface class DocumentStore {
  /// Le contenu du document, ou **`null` si aucun fichier n'existe** — c'est
  /// `v0`, l'installation neuve, et l'état vide y est **réellement
  /// atteignable** (AC-13 « Erreur »).
  Future<String?> lire();

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
  Future<void> mettreDeCote();
}
