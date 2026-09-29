import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/domain/echeance_etat.dart';
import 'package:concentration/features/echeances/domain/validation_echeance.dart';
import 'package:flutter_test/flutter_test.dart';

/// Règles de saisie — AC-2, AC-3, AC-4, AC-5, AC-6, AC-16 (T3).
///
/// ⛔ **Aucune date de calendrier en dur** (R-13) : tout se dérive de l'horloge
/// injectée. Les seules valeurs fixes sont des **règles** — `23:59`, `80`, `9`.
void main() {
  // 08:00 « aujourd'hui » : l'instant de référence des scénarios d'AC-3/AC-4.
  final maintenant = DateTime(2026, 8, 6, 8);
  final validation = ValidationEcheance(FakeClock(maintenant));

  String jjmmaaaa(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year.toString().padLeft(4, '0')}';

  final dansTroisMois = DateTime(
    maintenant.year,
    maintenant.month + 3,
    maintenant.day,
  );
  final veille = maintenant.subtract(const Duration(days: 1));

  ResultatValidation valider({
    String description = 'Convention',
    String? date,
    String heure = '',
    List<Echeance> presentes = const [],
    Echeance? original,
  }) => validation.valider(
    description: description,
    date: date ?? jjmmaaaa(dansTroisMois),
    heure: heure,
    presentes: presentes,
    original: original,
  );

  Echeance echeance(String id, DateTime date, [String d = 'x']) =>
      Echeance(id: id, description: d, dateEcheance: date);

  group('AC-2 — description obligatoire, et les DEUX côtés de la borne', () {
    test('une description vide est refusée, en DÉSIGNANT la description', () {
      final r = valider(description: '');
      expect(r.estAcceptee, isFalse);
      expect(r.refus!.champ, ChampEcheance.description);
      expect(r.refus!.message.toLowerCase(), contains('description'));
      expect(r.echeance, isNull, reason: 'aucune création partielle');
    });

    test('3 espaces sont refusés — la donnée EXACTE du scénario', () {
      final r = valider(description: '   ');
      expect(r.estAcceptee, isFalse);
      expect(r.refus!.champ, ChampEcheance.description);
    });

    test('80 caractères ACCEPTÉS / 81 REFUSÉS', () {
      final quatreVingts = 'a' * ValidationEcheance.longueurMaxDescription;
      expect(
        valider(description: quatreVingts).estAcceptee,
        isTrue,
        reason:
            '80 est la borne INCLUSE — sans ce côté, un refus '
            'systématique passerait pour une règle',
      );
      final trop = valider(description: '$quatreVingts!');
      expect(trop.estAcceptee, isFalse);
      expect(trop.refus!.champ, ChampEcheance.description);
      expect(
        trop.refus!.message,
        contains('${ValidationEcheance.longueurMaxDescription}'),
        reason: 'le message doit NOMMER la limite',
      );
    });

    test('la borne se mesure APRÈS trim, et le trim est ENREGISTRÉ', () {
      final quatreVingts = 'b' * ValidationEcheance.longueurMaxDescription;
      final r = valider(description: '   $quatreVingts   ');
      expect(r.estAcceptee, isTrue, reason: '80 après trim, donc accepté');
      expect(r.echeance!.description, quatreVingts);
      expect(r.echeance!.description.length, 80);
    });

    test('⛔ jamais de troncature silencieuse : 81 n’est pas ramené à 80', () {
      final r = valider(description: 'c' * 81);
      expect(r.estAcceptee, isFalse);
      expect(r.echeance, isNull);
    });
  });

  group('AC-3 — date obligatoire, heure optionnelle à 23:59', () {
    test('sans heure, l’heure enregistrée est LITTÉRALEMENT 23:59', () {
      final r = valider();
      expect(r.estAcceptee, isTrue);
      expect(r.echeance!.dateEcheance.hour, ValidationEcheance.heureParDefaut);
      expect(
        r.echeance!.dateEcheance.minute,
        ValidationEcheance.minuteParDefaut,
      );
      // ⛔ Ni 00:00, ni l'heure courante — les deux mutants les plus probables.
      expect(r.echeance!.dateEcheance.hour, isNot(0));
      expect(r.echeance!.dateEcheance.hour, isNot(maintenant.hour));
    });

    test('une heure renseignée l’emporte sur la valeur par défaut', () {
      final r = valider(heure: '09:05');
      expect(r.echeance!.dateEcheance.hour, 9);
      expect(r.echeance!.dateEcheance.minute, 5);
    });

    test('une création SANS date est refusée, en désignant la date', () {
      final r = valider(date: '');
      expect(r.estAcceptee, isFalse);
      expect(r.refus!.champ, ChampEcheance.date);
      expect(r.refus!.message.toLowerCase(), contains('date'));
      expect(r.echeance, isNull, reason: '⛔ aucune date inventée');
    });

    test('une date hors gabarit est refusée sans lever', () {
      final r = valider(date: '15 mars');
      expect(r.estAcceptee, isFalse);
      expect(r.refus!.champ, ChampEcheance.date);
    });

    test('une heure hors gabarit est refusée, ancrée sur le champ heure', () {
      final r = valider(heure: '9h');
      expect(r.estAcceptee, isFalse);
      expect(r.refus!.champ, ChampEcheance.heure);
    });

    test('une échéance du jour courant sans heure reste valide à 08:00', () {
      final r = valider(date: jjmmaaaa(maintenant));
      expect(r.estAcceptee, isTrue);
      expect(r.echeance!.dateEcheance.day, maintenant.day);
    });
  });

  group('AC-4 — futur STRICT, création ET édition (R-10)', () {
    test('la veille est refusée, et le message NOMME la règle', () {
      final r = valider(date: jjmmaaaa(veille));
      expect(r.estAcceptee, isFalse);
      expect(r.refus!.champ, ChampEcheance.date);
      expect(
        r.refus!.message.toLowerCase(),
        contains('la date doit être dans le futur'),
      );
    });

    test('T = 0 est REFUSÉ / T = +1 min est ACCEPTÉ — les deux côtés', () {
      final aMemeHeure = valider(date: jjmmaaaa(maintenant), heure: '08:00');
      expect(
        aMemeHeure.estAcceptee,
        isFalse,
        reason:
            'T = 0 : une échéance naîtrait « à zéro » et occuperait '
            'une des 9 places sans jamais servir',
      );
      expect(
        valider(date: jjmmaaaa(maintenant), heure: '08:01').estAcceptee,
        isTrue,
      );
    });

    test('une ÉDITION vers le passé est refusée par la MÊME fonction', () {
      final active = echeance('a', maintenant.add(const Duration(days: 3)));
      final r = valider(date: jjmmaaaa(veille), original: active);
      expect(r.estAcceptee, isFalse);
      expect(
        r.refus!.message.toLowerCase(),
        contains('la date doit être dans le futur'),
        reason: 'sans cela la règle est contournable en DEUX gestes',
      );
      expect(r.echeance, isNull);
    });
  });

  group('AC-5 — limite de 9 sur ACTIVE + ÉCHUE (clarify nº 5)', () {
    List<Echeance> presentes(int actives, {int echues = 0}) => [
      for (var i = 0; i < actives; i++)
        echeance('a$i', maintenant.add(Duration(days: i + 1))),
      for (var i = 0; i < echues; i++)
        echeance('e$i', maintenant.subtract(Duration(days: i + 1))),
    ];

    test('la 9ᵉ est ACCEPTÉE / la 10ᵉ est REFUSÉE — les deux côtés', () {
      expect(valider(presentes: presentes(8)).estAcceptee, isTrue);
      final dixieme = valider(presentes: presentes(9));
      expect(dixieme.estAcceptee, isFalse);
      expect(dixieme.refus!.champ, ChampEcheance.formulaire);
    });

    test('une ÉCHUE compte dans la limite', () {
      final r = valider(presentes: presentes(8, echues: 1));
      expect(
        r.estAcceptee,
        isFalse,
        reason: '8 actives + 1 échue = 9 présentes sur la grille',
      );
    });

    test('le message NOMME 9 et la SEULE issue disponible : supprimer', () {
      final message = validation.refusDeLimite(presentes(9))!.message;
      expect(message, contains('${ValidationEcheance.maxPresentesSurGrille}'));
      expect(message.toLowerCase(), contains('supprimer une échéance'));
      // 🔴 Une assertion doit ÉCHOUER si le message promet « faire
      // disparaître » : ce geste est US-01.4, il N'EXISTE PAS ici, et
      // l'annoncer inviterait le pratiquant à un geste inexistant.
      expect(message.toLowerCase(), isNot(contains('disparaît')));
      expect(message.toLowerCase(), isNot(contains('disparaitre')));
    });

    test(
      'la limite ne s’applique PAS à une édition — éditer n’ajoute rien',
      () {
        final liste = presentes(9);
        final r = valider(presentes: liste, original: liste.first);
        expect(r.estAcceptee, isTrue);
      },
    );

    // ─────────────────────────────────────────────────────────────────────
    // 🔴 AC-6 « Erreur » d'US-01.4 (T5) — LE MESSAGE EST CONDITIONNEL.
    //
    // ⛔ LES DEUX CÔTÉS DE LA BORNE, jamais un seul : « sans le second, un
    // message unique satisferait la règle » (cellule T5 du Story File). Le
    // mutant qui compte n'est pas « pas de variante » — c'est la variante
    // INVERSÉE, et seule une assertion DIRECTIONNELLE la tue.
    //
    // ⛔ Aucun de ces textes n'est recopié ici (Design UX §10) : les
    // assertions portent sur des PROPRIÉTÉS du message — la phrase de la
    // limite PARTAGÉE, l'annonce du geste, son absence de l'autre côté.
    // ─────────────────────────────────────────────────────────────────────
    group('AC-6 « Erreur » — les deux variantes du message de la limite', () {
      // Le geste est nommé par son SEUL canal pointeur ; c'est la propriété
      // même que le scénario asserte (« le message annonce le retrait d'une
      // échue »). ⛔ Le mot n'est pas choisi ici : il est LU dans le message.
      bool annonceLeGeste(String m) => m.toLowerCase().contains('double appui');

      String messageAvecEchue() =>
          validation.refusDeLimite(presentes(8, echues: 1))!.message;
      String messageSansEchue() =>
          validation.refusDeLimite(presentes(9))!.message;

      test('avec une échue sur la grille, le message ANNONCE le retrait', () {
        final m = messageAvecEchue();
        expect(
          annonceLeGeste(m),
          isTrue,
          reason:
              'c’est le SEUL endroit du produit qui enseigne le geste : sans '
              'lui, « faire disparaître » reste invisible à qui atteint la '
              'limite (RF-15 amputé)',
        );
        expect(
          m.toLowerCase(),
          contains('sans la supprimer'),
          reason:
              'le message doit dire l’INNOCUITÉ du geste, sinon le pratiquant '
              'croit qu’on lui propose de détruire',
        );
        expect(
          m.toLowerCase(),
          contains('supprimer'),
          reason: 'la suppression reste une issue, elle ne disparaît pas',
        );
      });

      test('sans échue sur la grille, le message N’ANNONCE PAS le retrait', () {
        final m = messageSansEchue();
        expect(
          annonceLeGeste(m),
          isFalse,
          reason:
              '⛔ JAMAIS un geste indisponible : à 9 actives, aucune tuile ne '
              'peut être retirée — l’annoncer serait la faute qu’US-01.2 a '
              'explicitement refusée, commise dans l’autre sens',
        );
        expect(m.toLowerCase(), contains('supprimer une échéance'));
      });

      test('🔴 les deux variantes sont DISTINCTES — un message unique ne '
          'satisferait PAS la règle', () {
        expect(messageAvecEchue(), isNot(messageSansEchue()));
      });

      test('la PHRASE DE LA LIMITE est la même dans les deux variantes', () {
        // 🔴 Ce que ce test tue : la variante neuve RÉÉCRIVANT l’énoncé de la
        // limite (deux exemplaires de la même règle, qui dériveraient), et
        // un « 9 » écrit à la main d’un seul côté.
        String phraseDeLimite(String m) => m.split('. ').first;
        expect(
          phraseDeLimite(messageAvecEchue()),
          phraseDeLimite(messageSansEchue()),
        );
        for (final m in [messageAvecEchue(), messageSansEchue()]) {
          expect(
            m,
            contains('${ValidationEcheance.maxPresentesSurGrille}'),
            reason:
                'le « 9 » est INTERPOLÉ depuis la constante, des deux côtés',
          );
        }
      });

      test('🔴 une échue RETIRÉE ne déclenche PAS la variante du retrait', () {
        // ⛔ LE PIÈGE : `retiree` ne change RIEN au prédicat « est échue »
        // (`echeance_etat.dart` le dit : ÉCHUE et ÉCHUE RETIRÉE sont toutes
        // deux échues). Si un appelant passait la liste COMPLÈTE, une échue
        // retirée ferait annoncer un geste INDISPONIBLE — elle n’est plus sur
        // la grille, on ne peut plus l’y retirer.
        //
        // ⇒ ce test fixe le CONTRAT : `refusDeLimite` reçoit les PRÉSENTES
        // (C-7), et sur des présentes toutes actives il n’annonce rien.
        final retiree = echeance(
          'r0',
          maintenant.subtract(const Duration(days: 1)),
        ).avec(retiree: true);
        expect(
          estEchue(retiree, maintenant),
          isTrue,
          reason: 'contrôle positif : une RETIRÉE est bel et bien échue',
        );
        // ⛔ ET LE PENDANT, qui rend le piège MESURABLE : sur la liste
        // COMPLÈTE — ce que faisaient DEUX appelants sur trois avant T5 — le
        // geste EST annoncé. La protection n'est donc PAS dans ce prédicat :
        // elle est dans le filtre `presentes` que l'appelant applique (C-7).
        expect(
          annonceLeGeste(
            validation.refusDeLimite([...presentes(8), retiree])!.message,
          ),
          isTrue,
          reason:
              'un appelant qui passe la liste complète annonce un geste '
              'INDISPONIBLE — c’est ce que les tests de surface interdisent',
        );
        // ⛔ Le MÊME jeu, passé au travers du filtre UNIQUE : il ne fait que
        // 8 présentes ⇒ il n'y a même pas de refus, donc rien à annoncer.
        expect(
          validation.refusDeLimite(
            presentesSurLaGrille([...presentes(8), retiree]),
          ),
          isNull,
        );
      });
    });
  });

  group('AC-6 — édition, id conservé, et refus sur une échue', () {
    test('l’édition CONSERVE l’id et remplace les valeurs', () {
      final active = echeance(
        'id-stable',
        maintenant.add(const Duration(days: 3)),
      );
      final r = valider(description: 'Nouveau libellé', original: active);
      expect(r.estAcceptee, isTrue);
      expect(r.echeance!.id, 'id-stable');
      expect(r.echeance!.description, 'Nouveau libellé');
    });

    test('éditer une ÉCHUE est refusé, avec le message prescrit', () {
      final echue = echeance('e', maintenant.subtract(const Duration(days: 1)));
      final refus = validation.refusEditionEchue(echue);
      expect(refus, isNotNull);
      expect(refus!.message.toLowerCase(), contains('se consulte'));
      expect(refus.message.toLowerCase(), contains('se supprime'));
    });

    test('éditer une ACTIVE n’est PAS refusé — contrôle négatif', () {
      final active = echeance('a', maintenant.add(const Duration(minutes: 1)));
      expect(validation.refusEditionEchue(active), isNull);
    });

    test('une échéance exactement à T = 0 est ÉCHUE, donc non éditable', () {
      expect(
        validation.refusEditionEchue(echeance('t0', maintenant)),
        isNotNull,
      );
    });
  });

  group('AC-16 — date ou heure civile qui n’existe pas (règle V-1)', () {
    // ⛔ AUCUNE DATE DE CALENDRIER EN DUR (R-13) : le 31 février VISÉ se dérive
    // de l'horloge et il est DANS LE FUTUR ⇒ le refus ne peut pas être imputé
    // à AC-4, sans quoi le test passerait pour la mauvaise raison.
    final anneeProchaine = maintenant.year + 1;

    test(
      'le 31 février est REFUSÉ / le 28 février est ACCEPTÉ — même test',
      () {
        final refus = valider(date: '31/02/$anneeProchaine');
        expect(refus.estAcceptee, isFalse);
        expect(refus.refus!.champ, ChampEcheance.date);
        expect(
          refus.refus!.message,
          contains('31/02/$anneeProchaine'),
          reason: 'le message doit DÉSIGNER la date, verbatim',
        );
        // ⛔ AUCUNE assertion sur la date de dérive (« le 3 mars ») : elle
        // dépend de l'année bissextile. Ce qui est asserté, c'est qu'AUCUNE
        // échéance n'est produite — vrai sous toute année.
        expect(refus.echeance, isNull);

        // L'AUTRE CÔTÉ, sans lequel un refus systématique passerait.
        final accepte = valider(date: '28/02/$anneeProchaine');
        expect(accepte.estAcceptee, isTrue);
        expect(accepte.echeance!.dateEcheance.day, 28);
        expect(accepte.echeance!.dateEcheance.month, 2);
      },
    );

    test('l’ÉDITION refuse la même date, par la MÊME fonction (R-10)', () {
      final active = echeance('a', maintenant.add(const Duration(days: 3)));
      final r = valider(date: '31/02/$anneeProchaine', original: active);
      expect(r.estAcceptee, isFalse);
      expect(r.refus!.message, contains('31/02/$anneeProchaine'));
      expect(r.echeance, isNull);
    });

    test('⛔ aucune correction silencieuse : rien n’est produit', () {
      final r = valider(date: '31/02/$anneeProchaine');
      expect(
        r.echeance,
        isNull,
        reason:
            'l’application ne doit JAMAIS enregistrer à la place une '
            'autre date, fût-elle « la plus proche »',
      );
    });

    test('le message ne parle NI de fuseau NI d’analyseur syntaxique', () {
      final r = valider(date: '31/02/$anneeProchaine');
      for (final interdit in ['fuseau', 'parse', 'format invalide', 'corrig']) {
        expect(r.refus!.message.toLowerCase(), isNot(contains(interdit)));
      }
    });

    // ⚠️ Le volet « heure civile inexistante » (02:30 le jour du saut de
    // printemps) N'A PAS DE TEST : borne NM-9. Sous `TZ=UTC` il n'existe
    // AUCUNE transition ⇒ le test y serait vrai quoi qu'il arrive.
    // Ce qui est éprouvé ci-dessous, c'est que le champ HEURE porte bien un
    // ancrage de message quand l'heure est en cause — sous tout fuseau.
    test('une heure impossible ancre son message sous le champ HEURE', () {
      final r = valider(heure: '25:00');
      expect(r.estAcceptee, isFalse);
      expect(r.refus!.champ, ChampEcheance.heure);
      expect(r.refus!.message, contains('25:00'));
      expect(r.refus!.message.toLowerCase(), isNot(contains('fuseau')));
    });
  });

  group('id attribué à la création — non vide et UNIQUE', () {
    test('deux créations au MÊME instant produisent deux id distincts', () {
      // L'horloge est figée : sans le suffixe, la collision serait certaine.
      final premiere = valider().echeance!;
      final seconde = valider(presentes: [premiere]).echeance!;
      expect(premiere.id, isNotEmpty);
      expect(seconde.id, isNotEmpty);
      expect(seconde.id, isNot(premiere.id));
    });

    test('trois créations au même instant restent distinctes', () {
      final a = valider().echeance!;
      final b = valider(presentes: [a]).echeance!;
      final c = valider(presentes: [a, b]).echeance!;
      expect({a.id, b.id, c.id}, hasLength(3));
    });
  });
}
