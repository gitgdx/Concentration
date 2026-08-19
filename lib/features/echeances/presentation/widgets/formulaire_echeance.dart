import 'package:flutter/material.dart';

import '../../../../core/theme/concentration_tokens.dart';
import '../../../../core/theme/rgb_extension.dart';
import '../../domain/echeance.dart';
import '../../domain/validation_echeance.dart';
import '../echeances_notifier.dart';
import 'ligne_echeance.dart';

/// Formulaire de **création ET d'édition** — ⛔ **un seul widget, deux titres**
/// (T9).
///
/// ✅ **C'est cette unicité qui tient la clause « Limite » d'AC-16 PAR
/// CONSTRUCTION** : il n'existe pas deux chemins de saisie qui pourraient
/// diverger. *(⚠️ Elle ne dit rien de l'unicité du prédicat de canonicité —
/// c'est la règle V-2, tenue ailleurs.)*
///
/// 🔴 **QUATRE INTERDITS, et ils viennent des AC, pas du goût** :
/// 1. ⛔ **Aucun `maxLength`** — il **empêcherait de taper le 81ᵉ caractère**,
///    donc le refus d'AC-2 « Limite » **n'aurait jamais lieu** ;
/// 2. ⛔ **Aucun compteur de caractères** — nommément interdit par AC-15
///    « Erreur » (`counterText: ''`) ;
/// 3. ⛔ **Aucun `placeholder` tenant lieu de libellé** — le libellé serait
///    perdu dès la première frappe (A-10) ;
/// 4. ⛔ **AUCUN formateur de saisie qui corrige, borne ou réécrit** la date ou
///    l'heure — `31/02/2027` doit rester **TAPABLE**, sinon le scénario
///    d'AC-16 devient **inobservable**.
///
/// 📌 **La règle dont ces quatre découlent** : ⛔ **ce qui doit être refusé doit
/// d'abord pouvoir être SAISI.** Un contrôle qui empêche de produire l'entrée
/// fautive ne protège pas l'utilisateur : il **efface la clause** qui le
/// protégeait.
class FormulaireEcheance extends StatefulWidget {
  const FormulaireEcheance({required this.notifier, super.key, this.original});

  final EcheancesNotifier notifier;

  /// `null` ⇒ création. Sinon **édition**, `id` conservé.
  final Echeance? original;

  @override
  State<FormulaireEcheance> createState() => _FormulaireEcheanceState();
}

class _FormulaireEcheanceState extends State<FormulaireEcheance> {
  late final TextEditingController _description;
  late final TextEditingController _date;
  late final TextEditingController _heure;
  RefusValidation? _refus;

  /// ⛔ Garde « un seul vol » : une seconde activation **pendant** l'écriture
  /// est ignorée — un double appui créerait **deux** échéances. Elle se
  /// **RELÂCHE à l'échec** (AC-17 « Erreur » : *« la nouvelle tentative aboutit
  /// sans ressaisie »*), sans quoi le 2ᵉ scénario serait inobservable.
  bool _enVol = false;

  @override
  void initState() {
    super.initState();
    final origine = widget.original;
    _description = TextEditingController(text: origine?.description ?? '');
    _date = TextEditingController(
      text: origine == null ? '' : _enJjMmAaaa(origine.dateEcheance),
    );
    _heure = TextEditingController(
      text: origine == null ? '' : heureLisible(origine.dateEcheance),
    );
    // AC-5 : à 9 présentes, le message de la limite est affiché EN TÊTE, dès
    // l'ouverture. ⛔ Il n'est pas réécrit ici : c'est celui du domaine, en un
    // seul exemplaire (pattern nº 10).
    if (origine == null) {
      _refus = widget.notifier.validation.refusDeLimite(
        widget.notifier.echeances,
      );
    }
  }

  static String _enJjMmAaaa(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year.toString().padLeft(4, '0')}';

  @override
  void dispose() {
    _description.dispose();
    _date.dispose();
    _heure.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (_enVol) return;
    setState(() => _enVol = true);
    final origine = widget.original;
    final refus = origine == null
        ? await widget.notifier.creer(
            description: _description.text,
            date: _date.text,
            heure: _heure.text,
          )
        : await widget.notifier.modifier(
            origine,
            description: _description.text,
            date: _date.text,
            heure: _heure.text,
          );
    if (!mounted) return;
    // ⛔ La garde se relâche TOUJOURS : après un échec, « Enregistrer » doit
    // redevenir activable.
    setState(() {
      _enVol = false;
      _refus = refus;
    });
    // 🔴 ⛔ UNE SURFACE D'ÉCRITURE NE SE FERME JAMAIS SUR UN ÉCHEC — fermer,
    // c'est dire « c'est fait ». On ne referme que sur un succès avéré.
    if (refus == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final titre = widget.original == null
        ? 'Nouvelle échéance'
        : "Modifier l'échéance";
    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: Semantics(
        namesRoute: true,
        label: titre,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_refus?.champ == ChampEcheance.formulaire)
                MessageValidation(texte: _refus!.message),
              _Champ(
                libelle: 'Description (obligatoire)',
                aide:
                    'Au maximum '
                    '${ValidationEcheance.longueurMaxDescription} caractères.',
                controleur: _description,
                enErreur: _refus?.champ == ChampEcheance.description,
                message: _refus?.champ == ChampEcheance.description
                    ? _refus!.message
                    : null,
              ),
              _Champ(
                libelle: 'Date (obligatoire)',
                aide: 'Format : JJ/MM/AAAA.',
                controleur: _date,
                enErreur: _refus?.champ == ChampEcheance.date,
                message: _refus?.champ == ChampEcheance.date
                    ? _refus!.message
                    : null,
              ),
              _Champ(
                libelle: 'Heure (optionnel)',
                aide:
                    "Sans heure, l'échéance est fixée à "
                    '${ValidationEcheance.heureParDefaut}:'
                    '${ValidationEcheance.minuteParDefaut}.',
                controleur: _heure,
                enErreur: _refus?.champ == ChampEcheance.heure,
                message: _refus?.champ == ChampEcheance.heure
                    ? _refus!.message
                    : null,
              ),
              const SizedBox(height: 24),
              // 3ᵉ ancrage de C-5 : LE PIED DE L'ACTION. Le message est ancré
              // sur CE QUI A ÉCHOUÉ — ici l'action, pas un champ : la saisie
              // n'est PAS fautive.
              if (_refus?.champ == ChampEcheance.action)
                MessageValidation(texte: _refus!.message),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ConcentrationTokens.moduleActif.couleur,
                    foregroundColor: ConcentrationTokens.fondApp.couleur,
                  ),
                  onPressed: _enregistrer,
                  child: const Text('Enregistrer'),
                ),
              ),
              SizedBox(
                height: 48,
                child: TextButton(
                  // ⛔ AUCUNE confirmation d'abandon : quitter le formulaire
                  // abandonne la saisie, et c'est LA SEULE PERTE ADMISE
                  // (AC-17 « Limite »). Un second dialogue modal serait un
                  // ré-embarquement de friction là où le produit n'en veut
                  // qu'une, sur le seul acte destructif.
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Composant **C-4** — champ de saisie, libellé **permanent**, aide **toujours
/// visible** (⛔ le message ne la REMPLACE pas : l'aide porte le format attendu,
/// c'est-à-dire l'information dont l'utilisateur a besoin **au moment du
/// refus**).
class _Champ extends StatelessWidget {
  const _Champ({
    required this.libelle,
    required this.aide,
    required this.controleur,
    required this.enErreur,
    required this.message,
  });

  final String libelle;
  final String aide;
  final TextEditingController controleur;
  final bool enErreur;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final bordure = enErreur
        ? ConcentrationTokens.erreur.couleur
        : ConcentrationTokens.contour.couleur;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            libelle,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: ConcentrationTokens.texteSecondaire.couleur,
            ),
          ),
          Semantics(
            label: libelle,
            textField: true,
            child: TextField(
              controller: controleur,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: ConcentrationTokens.texteSurFond.couleur,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: ConcentrationTokens.surfaceElevee.couleur,
                // ⛔ `counterText: ''` : AC-15 « Erreur » interdit nommément
                // tout compteur. Et ⛔ aucun `maxLength` : le 81ᵉ caractère
                // DOIT pouvoir être tapé.
                counterText: '',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: bordure),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: ConcentrationTokens.moduleActif.couleur,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          if (message != null) MessageValidation(texte: message!),
          Text(
            aide,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: ConcentrationTokens.texteSecondaire.couleur,
            ),
          ),
        ],
      ),
    );
  }
}

/// Composant **C-5** — message de validation ou d'échec, **en un seul
/// exemplaire**.
///
/// ⚖️ **Déviation nommée** : le tableau des fichiers n'en prévoyait pas, mais
/// **trois surfaces le consomment** — le formulaire, la page de gestion *(le
/// message de la limite de 9)* et le dialogue de confirmation. Le dupliquer
/// aurait fait **trois copies d'un composant**, et deux copies dérivent.
///
/// ⛔ Il ne **rédige** rien : son texte vient du domaine, en un seul exemplaire.
/// Le signe ⚠ est **obligatoire** : `erreur`, `moduleActif` et
/// `texteSecondaire` ont une luminance **quasi identique** (1,00:1), donc la
/// teinte **ne peut rien porter seule** (SC 1.4.1).
class MessageValidation extends StatelessWidget {
  const MessageValidation({required this.texte, super.key});

  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Semantics(
        liveRegion: true,
        child: Text(
          '⚠ $texte',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ConcentrationTokens.erreur.couleur,
          ),
        ),
      ),
    );
  }
}
