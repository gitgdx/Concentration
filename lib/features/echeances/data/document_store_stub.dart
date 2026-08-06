import 'document_store.dart';

/// Branche **NON-`dart:io`** — le web, aujourd'hui.
///
/// 🔴 **`ecrire` LÈVE, par conception — ⛔ jamais un `catch` silencieux.** Sur
/// une plateforme sans stockage, l'application doit **dire** qu'elle ne
/// persiste pas, pas faire semblant. C'est ce refus qui rend **AC-17
/// observable** : le pratiquant voit *« l'échéance n'a pas été enregistrée »*
/// au lieu de croire à un enregistrement qui n'aura jamais eu lieu.
///
/// ⚠️ **Conséquence assumée, écrite pour qu'elle ne se découvre pas** :
/// `flutter build web --release` reste **VERT** et produit une application
/// **constructible mais pas utilisable**. AC-17 fait que cela **se voit** au
/// lieu de se deviner. ⛔ **Non observé** — borne **NM-10**, qui ⛔ **ne se
/// lèvera PAS avec US-01.3** (elle vise iOS/Android).
///
/// 🔴 **R-15** : un fichier de `lib/` **non importé par un test n'entre pas au
/// dénominateur** de la couverture ⇒ ce stub pourrait être faux sans qu'on le
/// sache. Un test l'importe donc **DIRECTEMENT** ; ⛔ se contenter de l'import
/// conditionnel ne suffit pas.
class DocumentStoreStub implements DocumentStore {
  const DocumentStoreStub();

  @override
  Future<String?> lire() async => null;

  @override
  Future<void> ecrire(String contenu) async {
    throw UnsupportedError('Cette plateforme ne fournit aucun stockage local.');
  }

  @override
  Future<void> mettreDeCote() async {
    throw UnsupportedError('Cette plateforme ne fournit aucun stockage local.');
  }
}

Future<DocumentStore> creerMagasin() async => const DocumentStoreStub();
