#!/usr/bin/env python3
"""Genere test/e2e/gestion_echeances_test.dart.

⛔ LES TITRES NE SONT PAS RETAPES (R-8) : ils sont LUS dans le `.feature`
NORMATIF et copies verbatim. En US-01.1, 13 scenarios et 13 lignes de resume
divergeaient par 5 titres — un titre recopie a la main derive.
Le generateur ECHOUE si le nombre de corps ne correspond pas au nombre de
titres, ou si un titre porte un guillemet double.
"""
import io
from pathlib import Path

RACINE = Path(r"c:/Users/guillaume.decroix/MesProjets/Concentration")
FEATURE = RACINE / "tests/features/US-01.2-gestion-echeances.feature"
CIBLE = RACINE / "test/e2e/gestion_echeances_test.dart"

titres = [
    l[len("  Scénario: "):].rstrip("\n")
    for l in io.open(FEATURE, encoding="utf-8")
    if l.startswith("  Scénario: ")
]

ENTETE = r'''import 'dart:convert';
import 'dart:io';

import 'package:concentration/app/app.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:concentration/core/theme/rgb_extension.dart';
import 'package:concentration/core/time/clock.dart';
import 'package:concentration/features/echeances/data/echeance_document_codec.dart';
import 'package:concentration/features/echeances/data/echeance_document_repository.dart';
import 'package:concentration/features/echeances/data/echeance_schema_migrations.dart';
import 'package:concentration/features/echeances/domain/echeance.dart';
import 'package:concentration/features/echeances/presentation/echeances_notifier.dart';
import 'package:concentration/features/echeances/presentation/gestion_echeances_page.dart';
import 'package:concentration/features/echeances/presentation/widgets/confirmation_suppression.dart';
import 'package:concentration/features/echeances/presentation/widgets/formulaire_echeance.dart';
import 'package:concentration/features/echeances/presentation/widgets/ligne_echeance.dart';
import 'package:concentration/features/echeances/presentation/widgets/echeance_tile.dart';
import 'package:concentration/features/echeances/presentation/widgets/empty_echeances_placeholder.dart';
import 'package:concentration/features/hub/presentation/hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/echeances_exemple.dart';
import '../support/magasin_temporaire.dart';

/// **Les 50 scénarios d'US-01.2** — un test par scénario du `.feature`
/// **NORMATIF** (T12).
///
/// ⛔ **LES TITRES NE SONT PAS RETAPÉS** : ce fichier est **généré** en LISANT
/// le `.feature`. En US-01.1, **13 scénarios et 13 lignes de résumé
/// divergeaient par 5 titres** (R-8) — un titre recopié à la main **dérive**.
///
/// 🔴 **CONTRAT D'ADR-010 §1, non négociable, et vérifié par machine (T13)** :
/// 1. **monter la RACINE** (`ConcentrationApp`), ⛔ jamais un sous-arbre ;
/// 2. **traverser un magasin RÉEL** — un fichier réel, dans un répertoire
///    temporaire réel, lu et écrit par le **code de production**. ⛔ Aucun faux
///    dépôt, aucun magasin en mémoire ;
/// 3. **assertionner l'ÉTAT PERSISTÉ** partout où le scénario parle du
///    stockage : l'assertion **lit les octets**, ⛔ elle ne se contente pas du
///    rendu. *« Un test qui n'observe que des widgets ne couvre pas une clause
///    de persistance. »*
///
/// ⚠️ **`FakeClock` n'est PAS un magasin factice** : c'est l'horloge injectée
/// d'ADR-002, du **code de production**, et elle n'a rien à voir avec la couche
/// de données. Le contrôle de T13 doit savoir les distinguer — son autotest le
/// vérifie.
void main() {
  // ⛔ AUCUNE DATE DE CALENDRIER EN DUR (R-13) : tout se dérive de cet instant.
  // « 08:00 aujourd'hui » est la donnée exacte des scénarios d'AC-3 et d'AC-4.
  final maintenant = DateTime(2026, 8, 6, 8);
  final horloge = FakeClock(maintenant);
  const codec = EcheanceDocumentCodec();
  late MagasinTemporaire harnais;
  late EcheancesNotifier notifier;

  setUp(() => harnais = MagasinTemporaire.creer());
  tearDown(() => harnais.nettoyer());

  String jjmmaaaa(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year.toString().padLeft(4, '0')}';

  Echeance ech(String id, Duration dans, [String d = 'Libellé']) =>
      Echeance(id: id, description: d, dateEcheance: maintenant.add(dans));

  /// Pose un document **directement sur le disque**, avant tout démarrage.
  void poser(List<Echeance> liste) => harnais.poser(
    codec.encoder(codec.documentNeuf(versionCourante), liste),
  );

  /// Ce que le **FICHIER** contient — ⛔ pas ce que l'écran montre.
  List<Echeance> persistees() {
    final texte = harnais.octets();
    if (texte == null) return const <Echeance>[];
    return codec.decoder(texte)?.echeances ?? const <Echeance>[];
  }

  /// ⛔ **LE SEUL `pumpWidget` DU FICHIER**, et il monte **la RACINE**.
  ///
  /// Chaque appel construit un dépôt et un notifier **NEUFS** sur le **même**
  /// répertoire : c'est exactement ce que « je rouvre l'application » veut
  /// dire, et ⛔ ce n'est pas le même objet en mémoire — sinon on ne testerait
  /// que la RAM.
  Future<void> ouvrirApplication(WidgetTester tester) async {
    notifier = EcheancesNotifier(
      depot: EcheanceDocumentRepository(harnais.magasin),
      clock: horloge,
    );
    await tester.runAsync(notifier.charger);
    await tester.pumpWidget(
      ConcentrationApp(notifier: notifier, clock: horloge),
    );
    await tester.pumpAndSettle();
  }

  Future<void> ouvrirGestion(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
  }

  Future<void> ouvrirFormulaire(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(GestionEcheancesPage),
        matching: find.text('Ajouter une échéance'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> saisir(
    WidgetTester tester, {
    String? description,
    String? date,
    String? heure,
  }) async {
    if (description != null) {
      await tester.enterText(find.byType(TextField).at(0), description);
    }
    if (date != null) {
      await tester.enterText(find.byType(TextField).at(1), date);
    }
    if (heure != null) {
      await tester.enterText(find.byType(TextField).at(2), heure);
    }
    await tester.pump();
  }

  Future<void> enregistrer(WidgetTester tester) async {
    await tester.tap(find.text('Enregistrer'));
    await reglerEcritures(
      tester,
      jusqua: () => !tester.any(find.byType(FormulaireEcheance)),
    );
    await tester.pumpAndSettle();
  }

  /// Parcours COMPLET depuis le hub : gestion → formulaire → saisie → validation.
  Future<void> creer(
    WidgetTester tester, {
    required String description,
    required String date,
    String heure = '',
  }) async {
    await ouvrirFormulaire(tester);
    await saisir(tester, description: description, date: date, heure: heure);
    await enregistrer(tester);
  }

  Future<void> supprimerPremiere(WidgetTester tester, {Finder? cible}) async {
    await tester.tap(cible ?? find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await reglerEcritures(
      tester,
      jusqua: () => !tester.any(find.byType(ConfirmationSuppression)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> revenir(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }

'''

BODIES = []

# 1
BODIES.append(r'''
    poser([ech('a', const Duration(days: 90), 'Convention')]);
    await ouvrirApplication(tester);
    expect(find.byType(HubPage), findsOneWidget);

    await ouvrirGestion(tester);

    expect(find.byType(GestionEcheancesPage), findsOneWidget);
    final theme = Theme.of(tester.element(find.byType(GestionEcheancesPage)));
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, ConcentrationTokens.fondApp.couleur);
    // ...et elle liste ce que LE FICHIER contient, pas autre chose.
    expect(persistees().single.description, 'Convention');
    expect(find.text('Convention'), findsWidgets);
''')

# 2
BODIES.append(r'''
    expect(harnais.octets(), isNull, reason: 'le stockage est vide');
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);

    expect(find.text('Aucune échéance enregistrée.'), findsOneWidget);
    expect(
      find.text('Ajoutez-en une pour commencer votre revue.'),
      findsOneWidget,
    );
    // ⛔ ni erreur technique, ni couleur d'urgence.
    expect(find.byType(MessageValidation), findsNothing);
    for (final interdit in ['Exception', 'Error', 'errno', 'échec']) {
      expect(find.textContaining(interdit), findsNothing);
    }
''')

# 3
BODIES.append(r'''
    poser([ech('a', const Duration(days: 5))]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await revenir(tester);
    expect(find.byType(HubPage), findsOneWidget);

    for (final module in ['Respiration', 'Concentration']) {
      // ⛔ `findsNothing` sur l'ANCÊTRE INTERACTIF — ⛔ pas un `tap` sans effet,
      // qui passe aussi quand l'écran est mort (C-1).
      expect(
        find.ancestor(
          of: find.text(module),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
      await tester.tap(find.text(module).last, warnIfMissed: false);
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(HubPage), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byIcon(Icons.settings),
        matching: find.byType(IconButton),
      ),
      findsNothing,
      reason: '« Réglages » reste NON-INTERACTIF',
    );
''')

# 4
BODIES.append(r'''
    expect(harnais.octets(), isNull);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await creer(
      tester,
      description: 'Convent',
      date: jjmmaaaa(DateTime(maintenant.year, maintenant.month + 3, maintenant.day)),
    );

    expect(find.text('Convent'), findsWidgets, reason: 'listée en gestion');
    // ASSERTION SUR LES OCTETS.
    expect(persistees(), hasLength(1));
    expect(persistees().single.description, 'Convent');

    await revenir(tester);
    expect(find.byType(EcheanceTile), findsOneWidget);
''')

# 5
BODIES.append(r'''
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await ouvrirFormulaire(tester);
    await saisir(tester, description: '', date: jjmmaaaa(maintenant.add(const Duration(days: 30))));
    await enregistrer(tester);

    expect(find.byType(FormulaireEcheance), findsOneWidget);
    expect(find.byType(MessageValidation), findsOneWidget);
    expect(find.textContaining('description'), findsWidgets);
    // ⛔ « aucune création partielle » s'asserte SUR LES OCTETS.
    expect(harnais.octets(), isNull);
''')

# 6
BODIES.append(r'''
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await ouvrirFormulaire(tester);
    // La donnée EXACTE du scénario : 3 espaces.
    await saisir(
      tester,
      description: '   ',
      date: jjmmaaaa(maintenant.add(const Duration(days: 30))),
    );
    await enregistrer(tester);

    expect(find.byType(MessageValidation), findsOneWidget);
    expect(find.textContaining('description'), findsWidgets);
    expect(harnais.octets(), isNull);
''')

# 7
BODIES.append(r'''
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await ouvrirFormulaire(tester);
    final date = jjmmaaaa(maintenant.add(const Duration(days: 30)));

    // 81 : REFUSÉ, et le message NOMME la limite.
    await saisir(tester, description: 'a' * 81, date: date);
    await enregistrer(tester);
    expect(find.byType(FormulaireEcheance), findsOneWidget);
    expect(find.textContaining('80'), findsWidgets);
    expect(harnais.octets(), isNull, reason: '⛔ aucune troncature silencieuse');

    // 80 : ACCEPTÉE. ⛔ Sans cet autre côté, un refus systématique passerait.
    await saisir(tester, description: 'b' * 80);
    await enregistrer(tester);
    expect(persistees(), hasLength(1));
    expect(persistees().single.description.length, 80);
''')

# 8
BODIES.append(r'''
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await creer(
      tester,
      description: '   Convention annuelle   ',
      date: jjmmaaaa(maintenant.add(const Duration(days: 30))),
    );

    // Le `trim` est vérifié SUR LA VALEUR PERSISTÉE, ⛔ pas sur le champ.
    expect(persistees().single.description, 'Convention annuelle');
    await revenir(tester);
    expect(find.text('Convention annuelle'), findsWidgets);
''')

# 9
BODIES.append(r'''
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await creer(
      tester,
      description: 'Sans heure',
      date: jjmmaaaa(maintenant.add(const Duration(days: 30))),
    );

    // L'heure persistée est LITTÉRALEMENT 23:59 — ⛔ ni 00:00, ni l'heure
    // courante (les deux mutants les plus probables).
    expect(harnais.octets(), contains('T23:59'));
    final enregistree = persistees().single.dateEcheance;
    expect(enregistree.hour, 23);
    expect(enregistree.minute, 59);
    expect(enregistree.hour, isNot(0));
    expect(enregistree.hour, isNot(maintenant.hour));
    expect(enregistree.day, maintenant.add(const Duration(days: 30)).day);
''')

# 10
BODIES.append(r'''
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await ouvrirFormulaire(tester);
    await saisir(tester, description: 'Description valide', date: '');
    await enregistrer(tester);

    expect(find.byType(MessageValidation), findsOneWidget);
    expect(find.textContaining('date'), findsWidgets);
    // ⛔ Aucune date INVENTÉE.
    expect(harnais.octets(), isNull);
''')

# 11
BODIES.append(r'''
    // « il est 08:00 aujourd'hui » — horloge injectée.
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await creer(
      tester,
      description: 'Aujourd hui',
      date: jjmmaaaa(maintenant),
    );

    expect(persistees(), hasLength(1), reason: 'la création est acceptée');
    await revenir(tester);
    // 15 h 59 restantes, unité « heures », `ceil` ⇒ 16. ⛔ La donnée du
    // scénario, pas une autre (R-12).
    expect(
      find.descendant(
        of: find.byType(EcheanceTile),
        matching: find.text('16'),
      ),
      findsOneWidget,
    );
''')

# 12
BODIES.append(r'''
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await ouvrirFormulaire(tester);
    await saisir(
      tester,
      description: 'Description valide',
      date: jjmmaaaa(maintenant.subtract(const Duration(days: 1))),
    );
    await enregistrer(tester);

    expect(find.byType(MessageValidation), findsOneWidget);
    expect(
      find.textContaining('doit être dans le futur'),
      findsWidgets,
      reason: 'le message NOMME la règle',
    );
    expect(harnais.octets(), isNull);
''')

# 13
BODIES.append(r'''
    // « il est 08:00 aujourd'hui » et la cible est fixée EXACTEMENT à 08:00.
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await ouvrirFormulaire(tester);
    await saisir(
      tester,
      description: 'Temps restant nul',
      date: jjmmaaaa(maintenant),
      heure: '08:00',
    );
    await enregistrer(tester);

    expect(
      find.textContaining('doit être dans le futur'),
      findsWidgets,
      reason: 'le futur est STRICT : T = 0 est REFUSÉ',
    );
    expect(harnais.octets(), isNull);
''')

# 14
BODIES.append(r'''
    poser([ech('a', const Duration(days: 10), 'Convention')]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    final octetsOrigine = harnais.octets();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await saisir(
      tester,
      date: jjmmaaaa(maintenant.subtract(const Duration(days: 1))),
    );
    await enregistrer(tester);

    expect(find.textContaining('doit être dans le futur'), findsWidgets);
    // L'échéance CONSERVE sa date d'origine — assertion sur les OCTETS.
    expect(harnais.octets(), octetsOrigine);
''')

# 15
BODIES.append(r'''
    poser([for (var i = 0; i < 8; i++) ech('e$i', Duration(days: i + 2))]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await creer(
      tester,
      description: 'La neuvieme',
      date: jjmmaaaa(maintenant.add(const Duration(days: 40))),
    );

    expect(persistees(), hasLength(9), reason: 'la création est acceptée');
    await revenir(tester);
    expect(find.byType(EcheanceTile), findsNWidgets(9));
''')

# 16
BODIES.append(r'''
    poser([for (var i = 0; i < 9; i++) ech('e$i', Duration(days: i + 2))]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await ouvrirFormulaire(tester);
    await saisir(
      tester,
      description: 'La dixieme',
      date: jjmmaaaa(maintenant.add(const Duration(days: 40))),
    );
    await enregistrer(tester);

    expect(find.byType(FormulaireEcheance), findsOneWidget);
    expect(find.textContaining('9'), findsWidgets, reason: 'le message NOMME la limite');
    expect(find.textContaining('supprimer une échéance'), findsWidgets);
    // 🔴 Une assertion doit ÉCHOUER si le message promet « faire disparaître » :
    // ce geste est US-01.4, il N'EXISTE PAS ici.
    expect(find.textContaining('disparaît'), findsNothing);
    expect(persistees(), hasLength(9), reason: 'le stockage contient TOUJOURS 9');
''')

# 17
BODIES.append(r'''
    poser([
      for (var i = 0; i < 8; i++) ech('a$i', Duration(days: i + 2)),
      ech('echue', const Duration(days: -3), 'Passeport'),
    ]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await ouvrirFormulaire(tester);
    await saisir(
      tester,
      description: 'La dixieme',
      date: jjmmaaaa(maintenant.add(const Duration(days: 40))),
    );
    await enregistrer(tester);

    expect(
      find.textContaining('9'),
      findsWidgets,
      reason: '8 actives + 1 ÉCHUE = 9 PRÉSENTES sur la grille',
    );
    expect(persistees(), hasLength(9));
''')

# 18
BODIES.append(r'''
    // ⚠️ `ListView` ne MATÉRIALISE que le viewport : à 9 échéances, le groupe
    // des ÉCHUES est hors champ et son affordance de suppression serait
    // introuvable — un échec qui se lirait comme « l’affordance n’existe pas ».
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    poser([
      for (var i = 0; i < 8; i++) ech('a$i', Duration(days: i + 2)),
      ech('echue', const Duration(days: -3), 'Passeport'),
    ]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);

    // La suppression est, en US-01.2, la SEULE issue pour libérer une place.
    await supprimerPremiere(
      tester,
      cible: find.byTooltip('Supprimer Passeport'),
    );
    expect(persistees(), hasLength(8));

    await creer(
      tester,
      description: 'Apres liberation',
      date: jjmmaaaa(maintenant.add(const Duration(days: 40))),
    );
    expect(persistees(), hasLength(9), reason: 'la création est acceptée');
    await revenir(tester);
    expect(find.byType(EcheanceTile), findsNWidgets(9));
''')

# 19
BODIES.append(r'''
    poser([ech('a', const Duration(days: 10), 'Avant')]);
    await ouvrirApplication(tester);
    expect(find.text('Avant'), findsWidgets);
    await ouvrirGestion(tester);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await saisir(tester, description: 'Apres');
    await enregistrer(tester);

    expect(find.text('Apres'), findsWidgets, reason: 'la gestion est à jour');
    await revenir(tester);
    // ⛔ SANS `pumpWidget` supplémentaire : un remontage masquerait l'absence
    // de notification (C-6).
    expect(
      find.descendant(
        of: find.byType(EcheanceTile),
        matching: find.text('Apres'),
      ),
      findsOneWidget,
    );
    expect(find.text('Avant'), findsNothing);
''')

# 20
BODIES.append(r'''
    poser([ech('a', const Duration(days: 3), 'Visite')]);
    await ouvrirApplication(tester);
    expect(
      find.descendant(of: find.byType(EcheanceTile), matching: find.text('3')),
      findsOneWidget,
    );

    await ouvrirGestion(tester);
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await saisir(tester, date: jjmmaaaa(maintenant.add(const Duration(days: 5))));
    await enregistrer(tester);
    await revenir(tester);

    expect(
      find.descendant(of: find.byType(EcheanceTile), matching: find.text('5')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(EcheanceTile), matching: find.text('3')),
      findsNothing,
    );
''')

# 21
BODIES.append(r'''
    poser([ech('a', const Duration(days: 10), 'Convention')]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    final octetsOrigine = harnais.octets();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await saisir(tester, description: '');
    await enregistrer(tester);

    expect(find.byType(MessageValidation), findsOneWidget);
    // L'échéance conserve description ET date — LES OCTETS D'ORIGINE.
    expect(harnais.octets(), octetsOrigine);
''')

# 22
BODIES.append(r'''
    poser([ech('e', const Duration(days: -2), 'Passeport')]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    final octetsOrigine = harnais.octets();

    // ⛔ L'affordance ✎ est PRÉSENTE : la retirer rendrait « je TENTE de
    // modifier cette échéance » inobservable.
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(FormulaireEcheance), findsNothing);
    expect(find.textContaining('se consulte'), findsOneWidget);
    expect(find.textContaining('se supprime'), findsOneWidget);
    expect(harnais.octets(), octetsOrigine);
''')

# 23
BODIES.append(r'''
    poser([ech('a', const Duration(days: 10), 'Convention')]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    final octetsOrigine = harnais.octets();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await saisir(tester, description: 'Valeur modifiée NON validée');
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('Convention'), findsWidgets);
    // ⛔ « aucune écriture » se vérifie sur les OCTETS, ⛔ pas sur l'écran.
    expect(harnais.octets(), octetsOrigine);
''')

# 24
BODIES.append(r'''
    poser([ech('a', const Duration(days: 10), 'Convention')]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    final octetsAvant = harnais.octets();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmationSuppression), findsOneWidget);
    // Le fichier est INCHANGÉ entre la demande et la confirmation (C-7).
    expect(harnais.octets(), octetsAvant);

    await tester.tap(find.text('Supprimer'));
    await reglerEcritures(
      tester,
      jusqua: () => !tester.any(find.byType(ConfirmationSuppression)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Convention'), findsNothing);
    expect(persistees(), isEmpty);
    await revenir(tester);
    expect(find.byType(EcheanceTile), findsNothing);
''')

# 25
BODIES.append(r'''
    poser([ech('a', const Duration(days: 10), 'Convention')]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    final octetsAvant = harnais.octets();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('Convention'), findsWidgets);
    expect(harnais.octets(), octetsAvant);
    await revenir(tester);
    expect(find.byType(EcheanceTile), findsOneWidget);
''')

# 26
BODIES.append(r'''
    poser([ech('a', const Duration(days: 10), 'Convention')]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await supprimerPremiere(tester);
    expect(persistees(), isEmpty);

    // « je rouvre l'application » : une INSTANCE NEUVE du dépôt et du
    // notifier, sur le même répertoire. ⛔ Pas le même objet en mémoire.
    await ouvrirApplication(tester);
    expect(find.text('Convention'), findsNothing);
    expect(find.byType(EcheanceTile), findsNothing);
    await ouvrirGestion(tester);
    expect(find.text('Convention'), findsNothing);
''')

# 27
BODIES.append(r'''
    poser([ech('e', const Duration(days: -3), 'Passeport')]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    expect(find.text('Échéance atteinte'), findsOneWidget);

    await supprimerPremiere(tester);

    expect(find.text('Passeport'), findsNothing);
    expect(persistees(), isEmpty, reason: 'disparue DU STOCKAGE LOCAL');
    await revenir(tester);
    expect(find.byType(EcheanceTile), findsNothing);
''')

# 28
BODIES.append(r'''
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    poser([
      ech('a3', const Duration(days: 30), 'Loin'),
      ech('a1', const Duration(days: 2), 'Proche'),
      ech('a2', const Duration(days: 10), 'Milieu'),
      ech('e2', const Duration(days: -20), 'Ancienne'),
      ech('e1', const Duration(days: -3), 'Recente'),
    ]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);

    expect(find.text('Actives · 3'), findsOneWidget);
    expect(find.text('Échues · 2'), findsOneWidget);
    final ordre = tester
        .widgetList<LigneEcheance>(find.byType(LigneEcheance))
        .map((l) => l.echeance.id)
        .toList();
    // Actives CROISSANTES, échues du plus RÉCEMMENT échu vers l'ancien.
    expect(ordre, ['a1', 'a2', 'a3', 'e1', 'e2']);
    expect(ordre.sublist(3), isNot(['e2', 'e1']));
''')

# 29
BODIES.append(r'''
    poser([ech('v', const Duration(days: 5), '')]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);

    // ⛔ Jamais masquée : une donnée invisible est une donnée perdue.
    expect(find.byType(LigneEcheance), findsOneWidget);
    expect(
      find.text(dateLisible(maintenant.add(const Duration(days: 5)))),
      findsWidgets,
      reason: 'la date monte en ligne de titre',
    );
    // ...et elle reste ÉDITABLE et SUPPRIMABLE comme les autres.
    expect(find.byIcon(Icons.edit), findsOneWidget);
    await supprimerPremiere(tester);
    expect(persistees(), isEmpty);
''')

# 30
BODIES.append(r'''
    poser([ech('a', const Duration(days: 3), 'Visite')]);
    await ouvrirApplication(tester);
    // La TUILE n'affiche que le nombre NU.
    expect(
      find.descendant(of: find.byType(EcheanceTile), matching: find.text('3')),
      findsOneWidget,
    );
    for (final unite in ['jours', 'jour', 'heures', 'mois', 'ans']) {
      expect(
        find.descendant(
          of: find.byType(EcheanceTile),
          matching: find.textContaining(unite),
        ),
        findsNothing,
      );
    }

    await ouvrirGestion(tester);
    // ⛔ LES DEUX MOITIÉS : sans la seconde, « une unité partout »
    // satisferait la règle.
    expect(find.text('3 jours'), findsOneWidget);
''')

# 31
BODIES.append(r'''
    poser([
      ech('a1', const Duration(days: 4), 'Active proche'),
      ech('a2', const Duration(days: 12), 'Active loin'),
      ech('e1', const Duration(days: -2), 'Echue'),
    ]);
    // INSTANCE NEUVE du dépôt — ⛔ pas le même objet en mémoire.
    await ouvrirApplication(tester);

    expect(find.byType(EcheanceTile), findsNWidgets(3));
    final premiere = tester
        .widgetList<EcheanceTile>(find.byType(EcheanceTile))
        .first;
    expect(
      premiere.temps.estEchue,
      isTrue,
      reason: 'l’échue revient EN TÊTE (US-01.1 AC-6)',
    );

    await ouvrirGestion(tester);
    expect(find.text('Échues · 1'), findsOneWidget);
    expect(find.text('Actives · 2'), findsOneWidget);
''')

# 32
BODIES.append(r'''
    // ⛔ Un test NE PEUT PAS prouver un non-appel réseau (borne NM-2) : ce qui
    // est vérifié, c'est l'ABSENCE DE TOUTE DÉPENDANCE ET DE TOUT APPEL RÉSEAU
    // DANS LE CODE LIVRÉ — un contrôle STATIQUE, sur les sources de `lib/`.
    const interdits = [
      "dart:html",
      "dart:js",
      "package:http",
      "package:dio",
      "HttpClient",
      "WebSocket",
      "http://",
      "https://",
    ];
    final fautifs = <String>[];
    for (final fichier in Directory('lib').listSync(recursive: true)) {
      if (fichier is! File || !fichier.path.endsWith('.dart')) continue;
      final source = fichier.readAsStringSync();
      for (final motif in interdits) {
        if (source.contains(motif)) fautifs.add('${fichier.path} : $motif');
      }
    }
    expect(fautifs, isEmpty, reason: 'aucune dépendance réseau dans lib/');
    // Et les trois opérations aboutissent, sans aucune connexion.
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await creer(
      tester,
      description: 'Hors ligne',
      date: jjmmaaaa(maintenant.add(const Duration(days: 20))),
    );
    expect(persistees(), hasLength(1));
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await saisir(tester, description: 'Hors ligne modifiee');
    await enregistrer(tester);
    expect(persistees().single.description, 'Hors ligne modifiee');
    await supprimerPremiere(tester);
    expect(persistees(), isEmpty);
''')

# 33
BODIES.append(r'''
    harnais.poser(
      '{"schemaVersion":2,"echeances":['
      '{"id":"ok1","description":"Valide un","dateEcheance":"2027-03-15T23:59"},'
      '{"id":"","description":"illisible","dateEcheance":"2027-04-01T09:00"},'
      '{"id":"ok2","description":"Valide deux","dateEcheance":"2027-05-01T09:00"}]}',
    );
    await ouvrirApplication(tester);

    // L'application s'ouvre et le hub reste debout.
    expect(find.byType(HubPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.byType(EcheanceTile), findsNWidgets(2));
    expect(find.text('Valide un'), findsOneWidget);
    expect(find.text('illisible'), findsNothing);
''')

# 34
BODIES.append(r'''
    const document =
        '{"schemaVersion":2,"echeances":['
        '{"id":"","description":"illisible","dateEcheance":"2027-04-01T09:00"}]}';
    harnais.poser(document);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);

    // OCTET POUR OCTET inchangé après ouverture.
    expect(harnais.octets(), document);
    expect(
      harnais.fichiers(),
      ['echeances.json'],
      reason: '⛔ ni réécrit, ni mis de côté, ni supprimé',
    );
    // ...et il n'est listé ni parmi les actives, ni parmi les échues.
    expect(find.byType(LigneEcheance), findsNothing);
    expect(find.text('illisible'), findsNothing);
''')

# 35
BODIES.append(r'''
    harnais.poser('{ceci n est pas du JSON');
    await ouvrirApplication(tester);

    expect(find.byType(EmptyEcheancesPlaceholder), findsOneWidget);
    expect(find.byType(EcheanceTile), findsNothing);
    expect(tester.takeException(), isNull);
    for (final interdit in ['Exception', 'FormatException', 'errno', 'Error']) {
      expect(find.textContaining(interdit), findsNothing);
    }
    // ⛔ Mis de côté, JAMAIS supprimé.
    expect(harnais.fichiers().single, startsWith('echeances.json.illisible-'));
''')

# 36
BODIES.append(r'''
    // Une version ANTÉRIEURE (v1) contenant 3 échéances.
    const v1 =
        '{"schemaVersion":1,"echeances":['
        '{"id":"a1","description":"Convention","dateEcheance":"2027-03-15T22:59:00.000Z"},'
        '{"id":"a2","description":"Notaire","dateEcheance":"2027-06-02T07:00:00.000Z"},'
        '{"id":"a3","description":"Passeport","dateEcheance":"2027-09-10T21:00:00.000Z"}]}';
    harnais.poser(v1);
    await ouvrirApplication(tester);

    expect(persistees(), hasLength(3));
    expect(harnais.octets(), contains('"schemaVersion":2'));
    // La migration s'exécute UNE SEULE FOIS : à la relecture, le document
    // porte déjà la version courante, donc plus rien à migrer.
    final apresPremiere = harnais.octets();
    await ouvrirApplication(tester);
    expect(harnais.octets(), apresPremiere);
    // Description, date et heure INCHANGÉES.
    final relues = {for (final e in persistees()) e.description: e.dateEcheance};
    expect(relues.keys.toSet(), {'Convention', 'Notaire', 'Passeport'});
    for (final e in persistees()) {
      expect(e.dateEcheance.isUtc, isFalse, reason: 'AC-14 : date CIVILE');
    }
''')

# 37
BODIES.append(r'''
    const v1 =
        '{"schemaVersion":1,"echeances":['
        '{"id":"a1","description":"Convention","dateEcheance":"2027-03-15T22:59:00.000Z"},'
        '{"id":"a2","description":"Notaire","dateEcheance":"2027-06-02T07:00:00.000Z"},'
        '{"id":"a3","description":"Passeport","dateEcheance":"2027-09-10T21:00:00.000Z"}]}';
    harnais.poser(v1);
    // Interruption RÉELLE de l'écriture : le système de fichiers refuse.
    harnais.bloquerEcriture();

    await ouvrirApplication(tester);

    // Les 3 échéances sont TOUJOURS LISIBLES dans leur état antérieur, et les
    // OCTETS du fichier sont strictement inchangés — l'écriture atomique n'a
    // jamais ouvert la cible.
    expect(harnais.octets(), v1);
    expect(find.byType(EcheanceTile), findsNWidgets(3));
    expect(tester.takeException(), isNull);
''')

# 38
BODIES.append(r'''
    const v1 =
        '{"schemaVersion":1,"echeances":['
        '{"id":"a1","description":"Convention","dateEcheance":"2027-03-15T22:59:00.000Z"},'
        '{"id":"a2","description":"Notaire","dateEcheance":"2027-06-02T07:00:00.000Z"},'
        '{"id":"a3","description":"Passeport","dateEcheance":"2027-09-10T21:00:00.000Z"}]}';
    harnais.poser(v1);
    // La migration MONTANTE a été exécutée : l'application s'ouvre.
    await ouvrirApplication(tester);
    expect(lireVersion(codec.lireRacine(harnais.octets()!)!), 2);

    // La migration DESCENDANTE est exécutée, avec le code de production.
    final redescendu = migrer(
      codec.lireRacine(harnais.octets()!)!,
      cible: 1,
    );
    await tester.runAsync(
      () => harnais.magasin.ecrire(jsonEncode(redescendu!)),
    );

    expect(lireVersion(codec.lireRacine(harnais.octets()!)!), 1);
    // Les 3 échéances sont restituées À L'IDENTIQUE — sur les OCTETS.
    expect(harnais.octets(), v1);
''')

# 39
BODIES.append(r'''
    poser([
      ech('p1', const Duration(days: 6), 'Saisie par le pratiquant'),
      ech('p2', const Duration(days: 20), 'Autre saisie'),
    ]);
    await ouvrirApplication(tester);

    expect(find.byType(EcheanceTile), findsNWidgets(2));
    expect(find.text('Saisie par le pratiquant'), findsOneWidget);
    // 🔴 Une assertion doit ÉCHOUER si une échéance d'EXEMPLE apparaît : les
    // descriptions du jeu d'exemple sont NOMMÉES, ⛔ pas devinées.
    for (final exemple in EcheancesExemple.depuis(horloge)) {
      if (exemple.description.isEmpty) continue;
      expect(
        find.text(exemple.description),
        findsNothing,
        reason: '⛔ « ${exemple.description} » vient du jeu d’EXEMPLE',
      );
    }
''')

# 40
BODIES.append(r'''
    // Installation neuve : aucun fichier.
    expect(harnais.octets(), isNull);
    await ouvrirApplication(tester);

    expect(find.byType(EmptyEcheancesPlaceholder), findsOneWidget);
    expect(find.byType(EcheanceTile), findsNothing);
    for (final exemple in EcheancesExemple.depuis(horloge)) {
      if (exemple.description.isEmpty) continue;
      expect(find.text(exemple.description), findsNothing);
    }
    // ⛔ Et l'ouverture n'écrit RIEN avant un geste de l'utilisateur.
    expect(harnais.octets(), isNull);
''')

# 41
BODIES.append(r'''
    poser([
      ech('a1', const Duration(days: 4)),
      ech('a2', const Duration(days: 12)),
    ]);
    await ouvrirApplication(tester);
    expect(find.byType(EcheanceTile), findsNWidgets(2));

    await ouvrirGestion(tester);
    await creer(
      tester,
      description: 'La troisieme',
      date: jjmmaaaa(maintenant.add(const Duration(days: 25))),
    );
    await revenir(tester);

    // ⛔ SANS redémarrage : aucun `pumpWidget` supplémentaire.
    expect(find.byType(EcheanceTile), findsNWidgets(3));
''')

# 42
BODIES.append(r'''
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    final date = jjmmaaaa(maintenant.add(const Duration(days: 45)));
    await creer(tester, description: 'Convention', date: date, heure: '09:05');

    // Relecture par une INSTANCE NEUVE : la date et l'heure restituées sont
    // EXACTEMENT celles qui ont été saisies.
    await ouvrirApplication(tester);
    final relue = persistees().single.dateEcheance;
    expect(jjmmaaaa(relue), date);
    expect(relue.hour, 9);
    expect(relue.minute, 5);
    // ⛔ Aucune conversion de fuseau ne les a décalées.
    expect(relue.isUtc, isFalse);
''')

# 43
BODIES.append(r'''
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await creer(
      tester,
      description: 'Convention',
      date: jjmmaaaa(maintenant.add(const Duration(days: 45))),
    );

    // ASSERTION SUR LE TEXTE PERSISTÉ, ⛔ pas sur l'objet en mémoire.
    final valeur = RegExp(
      r'"dateEcheance":"([^"]+)"',
    ).firstMatch(harnais.octets()!)!.group(1)!;
    expect(valeur, matches(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$'));
    expect(valeur, isNot(contains('Z')), reason: 'aucune marque de temps universel');
    expect(valeur, isNot(contains('+')), reason: 'aucun décalage');
    expect(
      valeur.substring(11),
      isNot(contains(':00:')),
      reason: 'aucune composante de secondes',
    );
    expect(DateTime.parse(valeur).isUtc, isFalse);
''')

# 44
BODIES.append(r'''
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await ouvrirFormulaire(tester);

    // ⚠️ Borne NM-6 : ⛔ rien ici ne prouve qu'un lecteur d'écran les PRONONCE.
    for (final libelle in [
      'Description (obligatoire)',
      'Date (obligatoire)',
      'Heure (optionnel)',
    ]) {
      expect(find.text(libelle), findsOneWidget);
      expect(find.bySemanticsLabel(libelle), findsWidgets);
    }

    // Le message de validation est lui aussi ANNONCÉ (`liveRegion`).
    await enregistrer(tester);
    expect(find.byType(MessageValidation), findsOneWidget);
    // ⛔ Aucune sélection PAR POSITION : on cherche, parmi les `Semantics` de
    // la surface du message, ceux qui déclarent `liveRegion`.
    final annonces = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byType(MessageValidation),
            matching: find.byType(Semantics),
          ),
        )
        .where((s) => s.properties.liveRegion ?? false);
    expect(
      annonces,
      isNotEmpty,
      reason: 'sans `liveRegion`, le refus est MUET pour le lecteur d’écran',
    );
''')

# 45
BODIES.append(r'''
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await ouvrirFormulaire(tester);
    await saisir(
      tester,
      description: 'Description valide',
      date: jjmmaaaa(maintenant.subtract(const Duration(days: 1))),
    );
    await enregistrer(tester);

    final message = find.byType(MessageValidation);
    expect(message, findsOneWidget);
    // Il utilise la couleur d'ERREUR du design system et reste lisible.
    final texte = tester.widget<Text>(
      find.descendant(of: message, matching: find.byType(Text)),
    );
    expect(texte.style!.color, ConcentrationTokens.erreur.couleur);
    expect(
      ConcentrationTokens.erreur.contrasteAvec(ConcentrationTokens.fondApp),
      greaterThanOrEqualTo(ConcentrationTokens.contrasteMinTexteNormal),
    );
    // ⛔ Aucun badge, compteur, alerte animée ni gamification.
    expect(find.byType(Badge), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('/80'), findsNothing);
''')

# 46
BODIES.append(r'''
    // ⛔ AUCUNE DATE DE CALENDRIER EN DUR : « l'année prochaine » se dérive de
    // l'horloge et le 31 février VISÉ est DANS LE FUTUR ⇒ le refus ne peut pas
    // être imputé à AC-4.
    final anneeProchaine = maintenant.year + 1;
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await ouvrirFormulaire(tester);
    await saisir(
      tester,
      description: 'Description valide',
      date: '31/02/$anneeProchaine',
    );
    await enregistrer(tester);

    expect(find.byType(FormulaireEcheance), findsOneWidget);
    expect(
      find.textContaining('31/02/$anneeProchaine'),
      findsWidgets,
      reason: 'le message DÉSIGNE la date, verbatim',
    );
    // 🔴 ⛔ AUCUNE assertion sur la date de dérive (« le 3 mars ») : elle dépend
    // de l'année bissextile. Ce qui est asserté est vrai SOUS TOUTE ANNÉE.
    expect(harnais.octets(), isNull, reason: 'le stockage ne contient AUCUNE échéance');
    // ⛔ Et la saisie n'est pas réécrite : le champ porte encore ce qui a été tapé.
    expect(find.text('31/02/$anneeProchaine'), findsOneWidget);

    // L'AUTRE CÔTÉ DE LA BORNE, sans lequel un refus systématique passerait.
    await saisir(tester, date: '28/02/$anneeProchaine');
    await enregistrer(tester);
    expect(persistees(), hasLength(1));
    expect(persistees().single.dateEcheance.day, 28);
    expect(persistees().single.dateEcheance.month, 2);
''')

# 47
BODIES.append(r'''
    final anneeProchaine = maintenant.year + 1;
    poser([ech('a', const Duration(days: 10), 'Convention')]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    final octetsOrigine = harnais.octets();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await saisir(tester, date: '31/02/$anneeProchaine');
    await enregistrer(tester);

    expect(find.byType(FormulaireEcheance), findsOneWidget);
    expect(find.textContaining('31/02/$anneeProchaine'), findsWidgets);
    // L'échéance CONSERVE sa date d'origine — sur les OCTETS. La MÊME fonction
    // de validation sert création et édition (R-10).
    expect(harnais.octets(), octetsOrigine);
''')

# 48
BODIES.append(r'''
    // « le stockage local ne peut pas être écrit » — condition RÉELLE du
    // système de fichiers, ⛔ aucun magasin factice (ADR-010 §1).
    harnais.bloquerEcriture();
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await ouvrirFormulaire(tester);
    await saisir(
      tester,
      description: 'Jamais enregistree',
      date: jjmmaaaa(maintenant.add(const Duration(days: 30))),
    );
    await tester.tap(find.text('Enregistrer'));
    await reglerEcritures(tester);

    // Un message SOBRE indique que l'enregistrement n'a pas eu lieu.
    expect(find.byType(MessageValidation), findsOneWidget);
    expect(find.textContaining('pas été enregistrée'), findsOneWidget);
    // ⛔ Aucune échéance listée ni sur la grille — AUCUNE mise à jour optimiste.
    expect(find.byType(LigneEcheance), findsNothing);
    expect(harnais.octets(), isNull);
    await revenir(tester);
    await revenir(tester);
    expect(find.byType(EcheanceTile), findsNothing);
    // ⛔ Aucune trace technique, aucun code d'erreur.
    for (final interdit in [
      'Exception',
      'errno',
      'OS Error',
      'echeances.json',
      'PathAccess',
    ]) {
      expect(find.textContaining(interdit), findsNothing);
    }
''')

# 49
BODIES.append(r'''
    harnais.bloquerEcriture();
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    await ouvrirFormulaire(tester);
    final date = jjmmaaaa(maintenant.add(const Duration(days: 30)));
    await saisir(tester, description: 'Deuxieme essai', date: date);
    await tester.tap(find.text('Enregistrer'));
    await reglerEcritures(tester);
    expect(harnais.octets(), isNull);

    // Le formulaire est TOUJOURS OUVERT et porte ENCORE la saisie.
    expect(find.byType(FormulaireEcheance), findsOneWidget);
    expect(find.text('Deuxieme essai'), findsOneWidget);
    expect(find.text(date), findsOneWidget);

    // Le stockage redevient inscriptible, et je valide DE NOUVEAU — ⛔ sans
    // avoir eu à ressaisir quoi que ce soit.
    harnais.debloquerEcriture();
    await enregistrer(tester);

    expect(persistees(), hasLength(1));
    expect(persistees().single.description, 'Deuxieme essai');
    expect(find.byType(FormulaireEcheance), findsNothing);
''')

# 50
BODIES.append(r'''
    poser([ech('a', const Duration(days: 10), 'Toujours la')]);
    await ouvrirApplication(tester);
    await ouvrirGestion(tester);
    final octetsAvant = harnais.octets();
    harnais.bloquerEcriture();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await reglerEcritures(tester);

    // Un message SOBRE indique que la suppression n'a pas eu lieu, et le
    // dialogue NE SE FERME PAS — fermer, ce serait dire « c'est fait ».
    expect(find.byType(ConfirmationSuppression), findsOneWidget);
    expect(find.textContaining("n'a pas eu lieu"), findsOneWidget);
    // L'échéance est TOUJOURS listée, sur la grille, et DANS LE STOCKAGE.
    expect(harnais.octets(), octetsAvant);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Toujours la'), findsWidgets);
    await revenir(tester);
    expect(find.byType(EcheanceTile), findsOneWidget);
''')

if len(BODIES) != len(titres):
    raise SystemExit(
        "REFUS : %d corps pour %d titres — le fichier ne sera pas ecrit."
        % (len(BODIES), len(titres))
    )

morceaux = [ENTETE]
for titre, corps in zip(titres, BODIES):
    if '"' in titre:
        raise SystemExit("REFUS : le titre contient un guillemet double : %s" % titre)
    # Apostrophes -> chaine a guillemets DOUBLES (convention du .feature).
    litteral = '"%s"' % titre if "'" in titre or "\u2019" in titre else "'%s'" % titre
    morceaux.append(
        "  testWidgets(%s, (tester) async {%s  });\n\n" % (litteral, corps)
    )
morceaux.append("}\n")

io.open(CIBLE, "w", encoding="utf-8", newline="\n").write("".join(morceaux))
print("ECRIT : %s (%d tests)" % (CIBLE, len(titres)))
