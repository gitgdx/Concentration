#!/usr/bin/env python3
"""T12b — correspondance scenario Gherkin <-> nom de test, VERIFIEE PAR MACHINE.

POURQUOI CE SCRIPT EXISTE
-------------------------
ADR-008 autorise un test qui MONTE L APPLICATION ENTIERE a tenir lieu de
scenario E2E de track FULL, MAIS il y attache une contrainte non negociable :
la correspondance scenario <-> test doit etre VERIFIEE PAR MACHINE, jamais
declaree. Sans ce controle, une ligne de DoD annoncant « N scenarios » serait a
nouveau une affirmation invérifiable — le defaut que ce projet paie le plus.

CE QU IL VERIFIE, DANS LES DEUX SENS
------------------------------------
* MANQUANT : un scenario du .feature dont AUCUN nom de test ne reprend le titre.
* ORPHELIN : un test du fichier de scenarios qui ne correspond a AUCUN scenario.
Les deux sont des ECARTS. Un controle unidirectionnel laisserait passer un test
qui derive de sa specification.

CE QU IL NE VERIFIE PAS
-----------------------
Que le test EPROUVE reellement ce que le scenario decrit : aucune machine ne lit
l intention. C est un controle de CORRESPONDANCE DE TITRES, pas de semantique.
Borne assumee et nommee, comme pour check_epic00_docs.py.

CONVENTIONS DU PROJET APPLIQUEES
--------------------------------
* Les titres sont LUS dans les .feature, JAMAIS recopies ici : un titre recopie
  derive au premier renommage (le projet l a verifie trois fois).
* Le decompte vient de len(), jamais ecrit a la main.
* Comparaison d ENSEMBLES, jamais de cardinaux : un decompte egal n est pas une
  preuve d equivalence — mesure sur ce depot meme, ou 13 scenarios et 13 lignes
  de resume divergeaient par 5 titres.
* Autotest de mutation embarque (--selftest), mutants hors du vocabulaire teste.
* Sortie ASCII et stdout reconfigure (la classe de bug cp1252 a coute deux fois).

Usage :
    python scripts/check_gherkin_mapping.py            # controle du depot
    python scripts/check_gherkin_mapping.py --selftest # autotest de mutation
"""

from __future__ import annotations

import re
import sys
import tempfile
from pathlib import Path

# --- SOURCE UNIQUE : couples (fichier .feature, fichier de tests) sous controle.
# Seules les US de track FULL y figurent : ADR-008 n attache la contrainte qu a
# elles, et les 103 scenarios de gouvernance sont de la SPECIFICATION (T12d).
COUPLES: tuple[tuple[str, str], ...] = (
    (
        'tests/features/US-01.1-affichage-hub-grille.feature',
        'test/e2e/hub_echeances_test.dart',
    ),
    # US-01.2 — ⛔ ENREGISTRE EN DERNIER (T14, risque R-7). Tant que ce couple
    # n'etait pas la, US-01.2 n'etait sous AUCUN controle de correspondance et
    # ⛔ l'absence de rouge ne prouvait RIEN. L'inscrire plus tot aurait rendu
    # le job REQUIS « Governance » rouge a chaque scenario ajoute.
    (
        'tests/features/US-01.2-gestion-echeances.feature',
        'test/e2e/gestion_echeances_test.dart',
    ),
)

MOTIF_SCENARIO = re.compile(r'^[ \t]*(?:Scénario|Scenario|Plan du scénario|Scenario Outline)'
                            r'[ \t]*:[ \t]*(.+?)[ \t]*$')
# testWidgets('titre', ...) ou test('titre', ...) — les deux quotes admises.
#
# ⚠️ RECHERCHE MULTILIGNE, et non ligne a ligne : `dart format` reporte
# volontiers le titre sur la ligne SUIVANTE de `testWidgets(`. Un parseur
# ligne-a-ligne criait alors au « scenario sans test » alors que le test
# EXISTAIT — deux faux ecarts sur ce depot meme. Defaut trouve par l autotest.
MOTIF_TEST = re.compile(
    r"""(?:testWidgets|test)\(\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")""",
    re.S,
)

MANQUANT = 'SCENARIO SANS TEST'
ORPHELIN = 'TEST SANS SCENARIO'


def titres_scenarios(texte: str) -> list[str]:
    return [m.group(1) for m in (MOTIF_SCENARIO.match(l) for l in texte.splitlines()) if m]


def titres_tests(texte: str) -> list[str]:
    titres = []
    for m in MOTIF_TEST.finditer(texte):
        brut = m.group(1) if m.group(1) is not None else m.group(2)
        # Un titre Dart peut echapper une apostrophe : \' vaut '.
        titres.append(brut.replace("\\'", "'").replace('\\"', '"'))
    return titres


def _ligne_test(titre: str) -> str:
    """Une ligne de test Dart VALIDE : l apostrophe y est ECHAPPEE.

    Sans cet echappement, le corpus synthetique de l autotest produisait du Dart
    invalide et le lecteur s arretait a la premiere apostrophe, ce qui faisait
    echouer quatre assertions sur six. Defaut de l OUTIL, trouve par son autotest.
    """
    return "  testWidgets('%s', (tester) async {});\n" % titre.replace("'", "\\'")


def verifier(racine: Path) -> list[tuple[str, str, str]]:
    """Rend la liste des ecarts : (feature, motif, titre). Vide == conforme."""
    ecarts: list[tuple[str, str, str]] = []
    for chemin_feature, chemin_test in COUPLES:
        f = racine / chemin_feature
        t = racine / chemin_test
        if not f.is_file():
            ecarts.append((chemin_feature, 'FEATURE ABSENT', chemin_feature))
            continue
        if not t.is_file():
            ecarts.append((chemin_feature, 'FICHIER DE TESTS ABSENT', chemin_test))
            continue
        scenarios = set(titres_scenarios(f.read_text(encoding='utf-8', errors='replace')))
        tests = set(titres_tests(t.read_text(encoding='utf-8', errors='replace')))
        for titre in sorted(scenarios - tests):
            ecarts.append((chemin_feature, MANQUANT, titre))
        for titre in sorted(tests - scenarios):
            ecarts.append((chemin_feature, ORPHELIN, titre))
    return ecarts


def _corpus_synthetique(racine: Path, titres: list[str]) -> None:
    """Corpus SYNTHETIQUE : aucun fichier reel du depot n est touche."""
    for chemin_feature, chemin_test in COUPLES:
        f = racine / chemin_feature
        t = racine / chemin_test
        f.parent.mkdir(parents=True, exist_ok=True)
        t.parent.mkdir(parents=True, exist_ok=True)
        f.write_text(
            'Fonctionnalité: corpus synthetique\n'
            + ''.join('  Scénario: %s\n    Alors rien\n' % x for x in titres),
            encoding='utf-8',
        )
        t.write_text(
            'void main() {\n' + ''.join(_ligne_test(x) for x in titres) + '}\n',
            encoding='utf-8',
        )


def selftest() -> int:
    """Autotest de MUTATION : le controle doit REFUSER ce qui est faux.

    Les mutants ne sont pas tires du vocabulaire de la regle : on RETIRE un test
    et on AJOUTE un test sans scenario. Verdicts compares en ENSEMBLES.
    """
    resultats: list[tuple[str, bool, str]] = []
    titres = ['Alpha du corpus', "Beta avec une apostrophe d'essai", 'Gamma final']
    feature, fichier_test = COUPLES[0]

    with tempfile.TemporaryDirectory() as tmp:
        racine = Path(tmp)

        _corpus_synthetique(racine, titres)
        ecarts = verifier(racine)
        resultats.append(('corpus conforme => 0 ecart', ecarts == [], '%r' % (ecarts,)))

        # MUTANT 1 : un scenario perd son test.
        _corpus_synthetique(racine, titres)
        chemin = racine / fichier_test
        garde = [x for x in titres if x != titres[1]]
        chemin.write_text(
            'void main() {\n' + ''.join(_ligne_test(x) for x in garde) + '}\n',
            encoding='utf-8',
        )
        attendu = {(feature, MANQUANT, titres[1])}
        obtenu = set(verifier(racine))
        resultats.append((
            'mutant test retire => refus qui NOMME le scenario',
            obtenu == attendu,
            'attendu=%r obtenu=%r' % (sorted(attendu), sorted(obtenu)),
        ))

        # MUTANT 2 : un test sans scenario (derive de la specification).
        _corpus_synthetique(racine, titres)
        chemin.write_text(
            chemin.read_text(encoding='utf-8').replace(
                '}\n', "  testWidgets('Delta hors specification', (tester) async {});\n}\n"
            ),
            encoding='utf-8',
        )
        attendu = {(feature, ORPHELIN, 'Delta hors specification')}
        obtenu = set(verifier(racine))
        resultats.append((
            'mutant test orphelin => refus DISTINCT du manquant',
            obtenu == attendu,
            'attendu=%r obtenu=%r' % (sorted(attendu), sorted(obtenu)),
        ))

        # MUTANT 3 : un titre RENOMME cote test doit produire LES DEUX ecarts.
        _corpus_synthetique(racine, titres)
        chemin.write_text(
            chemin.read_text(encoding='utf-8').replace(titres[0], titres[0] + ' (renomme)'),
            encoding='utf-8',
        )
        attendu = {
            (feature, MANQUANT, titres[0]),
            (feature, ORPHELIN, titres[0] + ' (renomme)'),
        }
        obtenu = set(verifier(racine))
        resultats.append((
            'mutant titre renomme => manquant ET orphelin',
            obtenu == attendu,
            'attendu=%r obtenu=%r' % (sorted(attendu), sorted(obtenu)),
        ))

        # MUTANT 4 : une apostrophe echappee dans un titre Dart doit se lire.
        resultats.append((
            "un titre a apostrophe est lu correctement",
            titres[1] in titres_tests(_ligne_test(titres[1])),
            'lecture de %r' % titres[1],
        ))

        resultats.append(('les deux motifs sont DISTINCTS', MANQUANT != ORPHELIN,
                          '%s vs %s' % (MANQUANT, ORPHELIN)))

    refus = sum(1 for _, ok, _ in resultats if not ok)
    for nom, ok, detail in resultats:
        print('  [%s] %s' % ('OK' if ok else 'ECHEC', nom))
        if not ok:
            print('        %s' % detail)
    print('\nAutotest : %d assertions, %d echec(s), %d couple(s) sous controle.'
          % (len(resultats), refus, len(COUPLES)))
    return 1 if refus else 0


def main() -> int:
    if '--selftest' in sys.argv[1:]:
        return selftest()

    racine = Path(__file__).resolve().parent.parent
    ecarts = verifier(racine)

    print('T12b -- correspondance scenario <-> test (racine : %s)' % racine)
    for chemin_feature, chemin_test in COUPLES:
        f, t = racine / chemin_feature, racine / chemin_test
        n_s = len(titres_scenarios(f.read_text(encoding='utf-8', errors='replace'))) if f.is_file() else 0
        n_t = len(titres_tests(t.read_text(encoding='utf-8', errors='replace'))) if t.is_file() else 0
        print('  %-52s %d scenarios' % (chemin_feature, n_s))
        print('  %-52s %d tests' % (chemin_test, n_t))

    if ecarts:
        print('\nECHEC : %d ecart(s).' % len(ecarts))
        for chemin, motif, titre in ecarts:
            print('  [%s] %s  <<%s>>' % (motif, chemin, titre))
        return 1
    print('\nOK : chaque scenario a son test et chaque test son scenario.'
          ' Controle de CORRESPONDANCE DE TITRES -- pas de semantique.')
    return 0


if __name__ == '__main__':
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except (AttributeError, ValueError):
        pass
    sys.exit(main())
