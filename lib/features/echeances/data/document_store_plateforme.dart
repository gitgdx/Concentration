import 'document_store.dart';
import 'document_store_stub.dart'
    if (dart.library.io) 'document_store_io.dart'
    as plateforme;

/// ⛔ **LE SEUL endroit de `lib/` qui choisit la plateforme** (ADR-009 §2,
/// pattern nº 3).
///
/// La forme de l'import est **imposée, pas recommandée** : c'est la seule qui
/// transforme un **plantage silencieux** en **dégradation déclarée**. Mesuré :
/// la branche IO fait passer le bundle web de **134 140 à 12 474 caractères**
/// quand elle est exclue — la preuve qu'elle l'est réellement.
///
/// ⛔ **Aucun autre fichier de `lib/` n'importe `dart:io` ni `path_provider`.**
Future<DocumentStore> magasinDeLaPlateforme() => plateforme.creerMagasin();
