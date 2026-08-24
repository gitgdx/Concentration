/// Le vocabulaire d'état d'une échéance — **en UN SEUL exemplaire** (T1).
///
/// ⛔ **Dart pur** : aucun `import` de `package:flutter/**`, aucun `import` de
/// `data/` (pattern nº 1, ADR-011 §3). ⛔ **Aucun `DateTime.now()`** : l'instant
/// est **passé en paramètre**, ce fichier ne va jamais le chercher
/// (pattern nº 4, ADR-002).
///
/// 🔴 **POURQUOI CE FICHIER EXISTE, et ce n'est pas un rangement** : **mesuré le
/// 2026-08-24, AVANT ce fichier**, le prédicat « est échue » vivait en **QUATRE
/// exemplaires** *(`remaining_time_calculator`, `validation_echeance` dans
/// `refusEditionEchue`, et **deux** dans `gestion_echeances_page`)*, et US-01.4
/// en demanderait **deux de plus**. Or *« une règle n'existe qu'en un seul
/// exemplaire — deux copies dérivent »*, vérifié trois fois sur ce corpus.
/// ⛔ **Ce compte est un fait DATÉ, pas une affirmation courante** : la mesure
/// vivante est la commande publiée au §T1 du Story File, ⛔ jamais un nombre
/// recopié ici *(classe de défaut nº 1 du projet — un chiffre écrit à la main à
/// côté d'une commande, jamais relu dans sa sortie)*.
///
/// ⛔ **LA 5ᵉ OCCURRENCE N'EST PAS DE CETTE FAMILLE et ne doit PAS être
/// absorbée ici** : `validation_echeance.dart` porte aussi le **futur strict
/// d'une SAISIE** *(AC-4 d'US-01.2 : « la date doit être dans le futur »)*.
/// Les deux règles ont la même **forme** et des **objets différents** — l'une
/// qualifie une échéance **existante**, l'autre **refuse une saisie**. Les
/// confondre les rendrait solidaires : changer la borne de l'une changerait
/// l'autre **sans qu'aucun AC ne le demande**.
library;

import 'echeance.dart';

/// `true` ⇔ l'échéance est **ÉCHUE** à [instant] : son terme est **atteint ou
/// dépassé**.
///
/// **La borne est INCLUSIVE, et c'est le comportement existant, à la lettre** :
/// `T == 0` **est** échue *(`RemainingTimeCalculator` rend déjà
/// `estEchue: true` et le nombre `0` à cet instant)*, `T == +1 µs` ne l'est pas.
/// ⛔ Une borne exclusive ferait apparaître une échéance « à zéro » qui ne
/// serait ni active ni échue.
///
/// ⚠️ **Ce prédicat ne dit RIEN du retrait** : `ÉCHUE` et `ÉCHUE RETIRÉE` sont
/// **toutes deux** échues. Le retrait se lit sur l'entité, pas sur l'horloge —
/// c'est précisément parce qu'il **ne se dérive de rien** qu'il est persisté
/// *(ADR-012 §Contexte 4)*.
bool estEchue(Echeance echeance, DateTime instant) =>
    !echeance.dateEcheance.isAfter(instant);
