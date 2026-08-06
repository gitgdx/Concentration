import '../../../core/time/clock.dart';
import 'date_civile.dart';
import 'echeance.dart';

/// Le champ visé par un refus — il détermine **où le message s'ancre**
/// (Design UX §14.2.1 : *« le message est ancré sur CE QUI A ÉCHOUÉ : un champ
/// si c'est un champ, l'action si c'est l'action »*).
enum ChampEcheance { description, date, heure, formulaire }

/// **Refus NOMMÉ** : le champ visé **et** son message, en un seul objet.
///
/// ⛔ Le texte vit **ici et nulle part ailleurs** (pattern nº 10) : ⛔ jamais
/// recopié dans un widget, ⛔ jamais recopié dans un test. Deux copies d'une
/// règle dérivent — vérifié trois fois sur ce corpus.
class RefusValidation {
  const RefusValidation(this.champ, this.message);

  final ChampEcheance champ;
  final String message;
}

/// Ce que rend [ValidationEcheance.valider] : ⛔ **jamais un booléen nu**.
class ResultatValidation {
  const ResultatValidation.acceptee(Echeance this.echeance) : refus = null;
  const ResultatValidation.refusee(RefusValidation this.refus)
    : echeance = null;

  /// L'échéance **prête à écrire** (description `trim`ée, heure résolue).
  final Echeance? echeance;
  final RefusValidation? refus;

  bool get estAcceptee => refus == null;
}

/// Les règles de saisie d'AC-2, AC-3, AC-4, AC-5, AC-6 et AC-16 — **pures**.
///
/// ⛔ **Aucun `import` de Flutter, aucun accès disque, aucun `DateTime.now()`**
/// (ADR-002 : la `Clock` est injectée).
///
/// 🔴 **R-10 — LA MÊME FONCTION SERT CRÉATION ET ÉDITION.** Deux chemins de
/// validation dériveraient, et la règle du futur strict deviendrait
/// **contournable en deux gestes** (créer valide, puis re-dater dans le passé).
class ValidationEcheance {
  const ValidationEcheance(this.clock);

  final Clock clock;

  /// AC-2 « Limite » — mesurée **après `trim`**. ⛔ 80 accepté, 81 refusé.
  static const int longueurMaxDescription = 80;

  /// AC-5 — le décompte porte sur `ACTIVE + ÉCHUE` (clarify nº 5).
  static const int maxPresentesSurGrille = 9;

  /// AC-3 « Nominal » — heure non renseignée ⇒ **23:59 du jour indiqué**.
  static const int heureParDefaut = 23;
  static const int minuteParDefaut = 59;

  static final RegExp _gabaritDate = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
  static final RegExp _gabaritHeure = RegExp(r'^(\d{2}):(\d{2})$');

  /// AC-5 « Erreur » — `null` tant qu'il reste une place.
  ///
  /// ⚖️ **Le message ne promet PAS « faire disparaître »** : ce geste est
  /// **US-01.4**, il n'existe pas ici ; l'annoncer inviterait le pratiquant à un
  /// geste inexistant. La **seule** issue disponible est la suppression.
  RefusValidation? refusDeLimite(List<Echeance> presentes) {
    if (presentes.length < maxPresentesSurGrille) return null;
    return const RefusValidation(
      ChampEcheance.formulaire,
      'Limite de $maxPresentesSurGrille échéances atteinte. '
      'Il faut supprimer une échéance existante pour en créer une nouvelle.',
    );
  }

  /// AC-6 « Limite » — `null` si l'échéance est **active**, donc éditable.
  ///
  /// ⚠️ L'affordance ✎ **reste présente et activable** sur une échue (Design UX
  /// §4.3) : la retirer rendrait le scénario *« je **tente** de modifier cette
  /// échéance »* **inobservable**. C'est ce refus qui est la réponse au geste.
  RefusValidation? refusEditionEchue(Echeance echeance) {
    if (echeance.dateEcheance.isAfter(clock.now())) return null;
    return const RefusValidation(
      ChampEcheance.formulaire,
      'Une échéance échue se consulte ou se supprime, elle ne se modifie pas.',
    );
  }

  /// Valide une saisie **brute** (telle que tapée) et rend l'échéance à écrire.
  ///
  /// [original] `null` ⇒ **création** *(la limite de 9 s'applique, un `id` est
  /// attribué)* ; sinon **édition** *(l'`id` est CONSERVÉ, la limite ne
  /// s'applique pas — éditer n'ajoute rien à la grille)*.
  ///
  /// [presentes] = les échéances **présentes sur la grille** (`ACTIVE + ÉCHUE`).
  ResultatValidation valider({
    required String description,
    required String date,
    required String heure,
    required List<Echeance> presentes,
    Echeance? original,
  }) {
    if (original == null) {
      final trop = refusDeLimite(presentes);
      if (trop != null) return ResultatValidation.refusee(trop);
    }

    final libelle = description.trim();
    if (libelle.isEmpty) {
      return const ResultatValidation.refusee(
        RefusValidation(
          ChampEcheance.description,
          'La description est obligatoire.',
        ),
      );
    }
    if (libelle.length > longueurMaxDescription) {
      return const ResultatValidation.refusee(
        RefusValidation(
          ChampEcheance.description,
          'La description ne doit pas dépasser '
          '$longueurMaxDescription caractères.',
        ),
      );
    }

    final saisieDate = date.trim();
    if (saisieDate.isEmpty) {
      return const ResultatValidation.refusee(
        RefusValidation(ChampEcheance.date, 'La date est obligatoire.'),
      );
    }
    final partsDate = _gabaritDate.firstMatch(saisieDate);
    if (partsDate == null) {
      return const ResultatValidation.refusee(
        RefusValidation(
          ChampEcheance.date,
          'La date doit être au format JJ/MM/AAAA.',
        ),
      );
    }

    final saisieHeure = heure.trim();
    var h = heureParDefaut;
    var min = minuteParDefaut;
    if (saisieHeure.isNotEmpty) {
      final partsHeure = _gabaritHeure.firstMatch(saisieHeure);
      if (partsHeure == null) {
        return const ResultatValidation.refusee(
          RefusValidation(
            ChampEcheance.heure,
            "L'heure doit être au format hh:mm.",
          ),
        );
      }
      h = int.parse(partsHeure.group(1)!);
      min = int.parse(partsHeure.group(2)!);
    }

    final jour = int.parse(partsDate.group(1)!);
    final mois = int.parse(partsDate.group(2)!);
    final annee = int.parse(partsDate.group(3)!);

    // AC-16 « Erreur » — ⛔ AUCUNE CORRECTION SILENCIEUSE. On refuse en
    // DÉSIGNANT la date telle qu'elle a été saisie ; ⛔ jamais « vous vouliez
    // sans doute le 28 ? » — proposer une date, c'est décider à la place du
    // pratiquant, et la seule chose que l'application sait, c'est que ce qu'il
    // a saisi n'existe pas.
    if (!jourExisteAuCalendrier(annee, mois, jour)) {
      return ResultatValidation.refusee(
        RefusValidation(
          ChampEcheance.date,
          'Le $saisieDate n’existe pas au calendrier.',
        ),
      );
    }

    // AC-16 « Limite » — LA barrière (règle V-1), en un seul exemplaire.
    // ⚠️ Ce qu'elle attrape ici et que le calendrier ne voit pas : l'heure
    // civile qui n'existe pas localement (02:30 le jour du saut de printemps).
    // ⛔ Borne NM-9 : sous `TZ=UTC` il n'existe AUCUNE transition, donc ce
    // chemin y est inatteignable — ⛔ il ne doit pas être déguisé en test vert.
    final candidat = texteCivil(annee, mois, jour, h, min);
    final instant = litDateCivile(candidat);
    if (instant == null) {
      return ResultatValidation.refusee(
        RefusValidation(
          ChampEcheance.heure,
          'L’heure ${candidat.split('T').last} n’existe pas ce jour-là.',
        ),
      );
    }

    // AC-4 — futur STRICT : `T = 0` est REFUSÉ. Sans cela, une échéance
    // naîtrait « à zéro » et occuperait une des 9 places sans jamais servir.
    if (!instant.isAfter(clock.now())) {
      return const ResultatValidation.refusee(
        RefusValidation(ChampEcheance.date, 'La date doit être dans le futur.'),
      );
    }

    return ResultatValidation.acceptee(
      original == null
          ? Echeance(
              id: _idLibre(presentes),
              description: libelle,
              dateEcheance: instant,
            )
          : original.avec(description: libelle, dateEcheance: instant),
    );
  }

  /// Un `id` **non vide et unique** dans la collection (grammaire du §2 du
  /// schéma de stockage). Dérivé de la `Clock` injectée, donc **déterministe en
  /// test** ; le suffixe ferme le cas de deux créations au **même instant**,
  /// qu'une horloge figée rend certain.
  String _idLibre(List<Echeance> existantes) {
    final base = clock.now().microsecondsSinceEpoch.toString();
    var candidat = base;
    var rang = 0;
    while (existantes.any((e) => e.id == candidat)) {
      rang++;
      candidat = '$base-$rang';
    }
    return candidat;
  }
}
