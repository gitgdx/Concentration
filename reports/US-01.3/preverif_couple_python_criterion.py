#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""T0 d'US-01.3 — SONDE : le juge de correspondance lit-il un fichier PYTHON ?

QUESTION (ADR-015 §10, risque R-10)
-----------------------------------
`scripts/check_gherkin_mapping.py` a ete ecrit pour des fichiers de tests DART.
US-01.3 adossera ses scenarios a un fichier de tests PYTHON
(`scripts/deploiement/test_scenarios_us013.py`, cree a T5) dont chaque cas
s'enregistre par un appel `test("<titre>", ...)`. Que le juge lise ces titres
-- apostrophes comprises, titre reporte a la ligne suivante compris -- est une
HYPOTHESE. Cette sonde la tranche.

LE JUGE N'EST PAS RECOPIE
-------------------------
⛔ Aucun motif n'est ecrit ici : le module du juge est IMPORTE et c'est SA
fonction `verifier()` qui rend les ecarts, rejouee sur un corpus SYNTHETIQUE
pose dans un repertoire temporaire, a l'emplacement du premier couple de
`COUPLES`. Un second jeu de motifs deriverait, et la sonde cesserait de predire
le verdict du gate -- ce qu'elle sert precisement a eviter.
⛔ `COUPLES` n'est NI lu pour decider, NI modifie : le couple d'US-01.3 n'y
entre qu'a T14, en dernier (l'inscrire avant que le fichier de tests existe
rendrait le job REQUIS rouge sur « FICHIER DE TESTS ABSENT »).

L'ORACLE INDEPENDANT
--------------------
Pour savoir ce qu'un fichier Python DIT, la sonde ne lit pas son texte : elle
le fait analyser par le module `ast` de Python. Un vrai cas de test est un
appel dont la fonction est le NOM `test` et dont le premier argument est une
chaine LITTERALE ; son titre est la valeur DECODEE par Python. Ce n'est pas
une copie du motif du juge, c'est l'analyseur du langage : le comparer au juge
fait apparaitre tout ce que le juge lit A TORT ou NE VOIT PAS, sans
vocabulaire.

TROIS MODES, TROIS USAGES
-------------------------
    python reports/US-01.3/preverif_couple_python_criterion.py             # T0 : la sonde
    python reports/US-01.3/preverif_couple_python_criterion.py --couple    # T8 : le vrai couple
    python reports/US-01.3/preverif_couple_python_criterion.py --selftest  # mutation

CODES DE SORTIE
---------------
    0  le juge lit ces titres (sonde) / le couple est exact (--couple)
    1  le juge NE les lit PAS => ARRET, retour @Architect, ADR-015 §10 a
       remplacer avant T5 (sonde) / ecart dans le couple (--couple)
    3  defaut de l'instrument : juge introuvable ou ampute, oracle en
       contradiction avec ses propres cas, ou CONSTAT PERIME (le juge a change
       de comportement sur un piege documente : la contrainte d'ADR-015 §10
       est a relire)

CE QUE CETTE SONDE NE PROUVE PAS
--------------------------------
* Qu'un test eprouve ce que son scenario decrit : correspondance de TITRES.
* Le comportement du juge sur une forme qui n'est pas dans ses cas : elle
  mesure des CAS, elle ne prouve pas une grammaire.
"""

from __future__ import annotations

import ast
import importlib.util
import re
import sys
import tempfile
import types
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
SCRIPT_JUGE = 'scripts/check_gherkin_mapping.py'
FEATURE_US013 = 'tests/features/US-01.3-chaine-deploiement-mobile.feature'
TESTS_US013 = 'scripts/deploiement/test_scenarios_us013.py'

CODE_LIT = 0
CODE_NE_LIT_PAS = 1
CODE_DEFAUT = 3

ATTRIBUTS_REQUIS = (
    'COUPLES', 'MOTIF_TEST', 'MOTIF_SCENARIO', 'MANQUANT', 'ORPHELIN',
    'titres_tests', 'titres_scenarios', 'verifier',
)

# Nom de la fonction d'enregistrement d'un cas, fixe par ADR-015 §10.
# C'est une CONVENTION DU FICHIER DE TESTS, ⛔ pas le motif du juge.
NOM_ENREGISTREMENT = 'test'


class DefautInstrument(Exception):
    """L'instrument lui-meme est en cause : rien n'a ete etabli."""


# ---------------------------------------------------------------- le juge

def charger_juge() -> types.ModuleType:
    chemin = RACINE / SCRIPT_JUGE
    if not chemin.is_file():
        raise DefautInstrument('juge introuvable : %s' % SCRIPT_JUGE)
    spec = importlib.util.spec_from_file_location('juge_gherkin_sonde_us013', chemin)
    if spec is None or spec.loader is None:
        raise DefautInstrument('juge non chargeable : %s' % SCRIPT_JUGE)
    module = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(module)
    except Exception as exc:  # noqa: BLE001 — tout echec d'import est un defaut
        raise DefautInstrument('import du juge en echec : %r' % (exc,)) from exc
    exiger_attributs(module)
    return module


def exiger_attributs(module: types.ModuleType) -> None:
    absents = [nom for nom in ATTRIBUTS_REQUIS if not hasattr(module, nom)]
    if absents:
        raise DefautInstrument('juge ampute, attribut(s) introuvable(s) : %s'
                               % ', '.join(absents))
    if not module.COUPLES:
        raise DefautInstrument('COUPLES vide : aucun emplacement ou rejouer verifier()')


def ecarts_du_juge(juge: types.ModuleType, texte_feature: str,
                   texte_python: str) -> set[tuple[str, str]]:
    """Rend les ecarts que le GATE produirait sur ce couple, par SA fonction.

    Le corpus est pose dans un repertoire TEMPORAIRE, a l'emplacement du premier
    couple de COUPLES : seul l'emplacement est emprunte, aucun fichier reel du
    depot n'est lu ni touche. Les ecarts des autres couples (FEATURE ABSENT dans
    le repertoire temporaire) sont ecartes par chemin.
    """
    feature, fichier = juge.COUPLES[0]
    with tempfile.TemporaryDirectory() as tmp:
        racine = Path(tmp)
        f, t = racine / feature, racine / fichier
        f.parent.mkdir(parents=True, exist_ok=True)
        t.parent.mkdir(parents=True, exist_ok=True)
        f.write_text(texte_feature, encoding='utf-8')
        t.write_text(texte_python, encoding='utf-8')
        ecarts = juge.verifier(racine)
    return {(motif, titre) for chemin, motif, titre in ecarts if chemin == feature}


def feature_synthetique(scenarios: list[str]) -> str:
    return ('Fonctionnalité: corpus synthetique de la sonde T0\n'
            + ''.join('  Scénario: %s\n    Alors rien\n' % s for s in scenarios))


# ---------------------------------------------------------------- l'oracle

def cas_python(source: str) -> tuple[list[str], list[int]]:
    """Ce que le fichier Python DIT : (titres decodes, lignes a titre non litteral).

    Leve SyntaxError si le texte n'est pas du Python valide.
    """
    arbre = ast.parse(source)
    trouves: list[tuple[int, int, str]] = []
    non_litteraux: list[int] = []
    for noeud in ast.walk(arbre):
        if not (isinstance(noeud, ast.Call) and isinstance(noeud.func, ast.Name)
                and noeud.func.id == NOM_ENREGISTREMENT):
            continue
        premier = noeud.args[0] if noeud.args else None
        if isinstance(premier, ast.Constant) and isinstance(premier.value, str):
            trouves.append((noeud.lineno, noeud.col_offset, premier.value))
        else:
            non_litteraux.append(noeud.lineno)
    return [titre for _, _, titre in sorted(trouves)], sorted(non_litteraux)


# ---------------------------------------------------------------- les cas

# Titres choisis HORS du vocabulaire de la regle (aucun ne contient le nom de
# la fonction d'enregistrement), avec des accents : le .feature en porte.
_SIMPLE = 'Une échéance unique est relue'
_APOS_DOUBLE = "L'appareil n'est pas branché"
_APOS_ECHAPPEE = "L'outil d'empreinte manque"
_REPORT = 'Le titre est reporté à la ligne suivante'
_REPORT_APOS = "L'artefact n'a pas d'empreinte, titre reporté"
_DECORATEUR = 'Le cas est déclaré par décorateur'

# (nom, scenarios attendus, source Python). Les attendus sont ECRITS ici ET
# re-verifies par l'oracle : un desaccord est un defaut de l'instrument (3).
CAS_POSITIFS: tuple[tuple[str, list[str], str], ...] = (
    ('titre simple', [_SIMPLE],
     'test("%s", lambda: None)\n' % _SIMPLE),
    ('apostrophe entre guillemets doubles', [_APOS_DOUBLE],
     'test("%s", lambda: None)\n' % _APOS_DOUBLE),
    ('apostrophe echappee entre apostrophes', [_APOS_ECHAPPEE],
     "test('%s', lambda: None)\n" % _APOS_ECHAPPEE.replace("'", "\\'")),
    ('titre sur la ligne suivant l ouverture', [_REPORT],
     'test(\n    "%s",\n    lambda: None,\n)\n' % _REPORT),
    ('titre reporte ET apostrophe', [_REPORT_APOS],
     'test(\n    "%s",\n    lambda: None,\n)\n' % _REPORT_APOS),
    ('forme decorateur', [_DECORATEUR],
     '@test("%s")\ndef cas_decore():\n    pass\n' % _DECORATEUR),
    ('fichier complet, six cas ensemble',
     [_SIMPLE, _APOS_DOUBLE, _APOS_ECHAPPEE, _REPORT, _REPORT_APOS, _DECORATEUR],
     'import sys\n\n\ndef test(titre, fonction=None):\n    return fonction\n\n\n'
     'test("%s", lambda: None)\n' % _SIMPLE
     + 'test("%s", lambda: None)\n' % _APOS_DOUBLE
     + "test('%s', lambda: None)\n" % _APOS_ECHAPPEE.replace("'", "\\'")
     + 'test(\n    "%s",\n    lambda: None,\n)\n' % _REPORT
     + 'test(\n    "%s",\n    lambda: None,\n)\n' % _REPORT_APOS
     + '\n\n@test("%s")\ndef cas_decore():\n    pass\n' % _DECORATEUR),
)

_A = 'Le registre est relu'
_B = 'La version est relue'

# PIEGES MESURES — CONSTATES, ⛔ PAS CORRIGES (le juge n'est pas dans le
# perimetre de T0). Chacun : (nom, sens, scenarios, source, ecarts ATTENDUS du
# juge). « FAUX VERT » = le juge ne voit RIEN alors qu'un scenario n'a pas de
# vrai cas ; « FAUX ROUGE » = le juge crie alors que le fichier est juste, ou
# rate un vrai cas ecrit sous une forme qu'il ne lit pas.
# Un constat qui cesse d'etre vrai rend 3 : le juge a change, la contrainte
# d'ADR-015 §10 est a relire.
def _constats(juge: types.ModuleType):
    m, o = juge.MANQUANT, juge.ORPHELIN
    return (
        ('appel finissant par le nom, argument hors scenarios', 'FAUX ROUGE',
         [_A], 'test("%s", lambda: None)\nversion = latest("piege")\n' % _A,
         {(o, 'piege')}),
        ('appel finissant par le nom, argument = un titre de scenario', 'FAUX VERT',
         [_A, _B], 'test("%s", lambda: None)\nversion = latest("%s")\n' % (_A, _B),
         set()),
        ('methode portant le nom, argument = un titre de scenario', 'FAUX VERT',
         [_A, _B], 'test("%s", lambda: None)\nregistre.test("%s")\n' % (_A, _B),
         set()),
        ('commentaire citant un appel', 'FAUX VERT',
         [_A, _B], 'test("%s", lambda: None)\n# test("%s", lambda: None)\n' % (_A, _B),
         set()),
        ('titre en f-string', 'FAUX ROUGE',
         [_A], 'test(f"%s", lambda: None)\n' % _A,
         {(m, _A)}),
        ('titre en litteraux adjacents', 'FAUX ROUGE',
         [_A], 'test("Le registre " "est relu", lambda: None)\n',
         {(m, _A), (o, 'Le registre ')}),
        ('titre entre triples guillemets', 'FAUX ROUGE',
         [_A], 'test("""%s""", lambda: None)\n' % _A,
         {(m, _A), (o, '')}),
        ('titre portant un echappement unicode', 'FAUX ROUGE',
         ['Une échéance'], 'test("Une \\u00e9ch\\u00e9ance", lambda: None)\n',
         {(m, 'Une échéance'), (o, 'Une \\u00e9ch\\u00e9ance')}),
    )


# ---------------------------------------------------------------- la sonde

def evaluer(juge: types.ModuleType) -> tuple[int, set[str], set[str], list[str]]:
    """Rend (code, cas positifs en echec, constats perimes, lignes de rapport)."""
    lignes: list[str] = []
    echecs: set[str] = set()
    perimes: set[str] = set()

    lignes.append('Cas positifs (le juge doit rendre 0 ecart) :')
    for nom, scenarios, source in CAS_POSITIFS:
        try:
            dits, non_lit = cas_python(source)
        except SyntaxError as exc:
            raise DefautInstrument('cas %r : source Python invalide (%s)' % (nom, exc)) from exc
        if set(dits) != set(scenarios) or non_lit:
            raise DefautInstrument('cas %r : l oracle lit %r, le cas declare %r'
                                   % (nom, sorted(dits), sorted(scenarios)))
        obtenu = ecarts_du_juge(juge, feature_synthetique(scenarios), source)
        ok = obtenu == set()
        if not ok:
            echecs.add(nom)
        lignes.append('  [%s] %s' % ('LU' if ok else 'NON LU', nom))
        if not ok:
            lignes.append('        ecarts du juge : %r' % sorted(obtenu))

    lignes.append('')
    lignes.append('Pieges CONSTATES (non corriges, hors perimetre de T0) :')
    for nom, sens, scenarios, source, attendu in _constats(juge):
        try:
            dits, _ = cas_python(source)
        except SyntaxError as exc:
            raise DefautInstrument('piege %r : source Python invalide (%s)' % (nom, exc)) from exc
        obtenu = ecarts_du_juge(juge, feature_synthetique(scenarios), source)
        tient = obtenu == attendu
        if not tient:
            perimes.add(nom)
        vrais_manquants = sorted(set(scenarios) - set(dits))
        lignes.append('  [%s] %s -- %s' % ('CONSTAT TENU' if tient else 'CONSTAT PERIME',
                                           sens, nom))
        lignes.append('        juge : %r | scenarios sans vrai cas (oracle) : %r'
                      % (sorted(obtenu), vrais_manquants))
        if not tient:
            lignes.append('        constat attendu : %r' % sorted(attendu))

    if echecs:
        code = CODE_NE_LIT_PAS
    elif perimes:
        code = CODE_DEFAUT
    else:
        code = CODE_LIT
    return code, echecs, perimes, lignes


# ---------------------------------------------------------------- le couple

def controler_couple(juge: types.ModuleType, texte_feature: str,
                     texte_python: str) -> set[tuple[str, str]]:
    """Ecarts du VRAI couple : ceux du juge + toute divergence juge / oracle.

    La divergence est l'INTERDICTION VERIFIABLE d'ADR-015 §10, generalisee : un
    appel `latest(...)`, une methode `.test(...)`, un commentaire, une f-string,
    des litteraux adjacents... ne sont pas cherches par leur forme -- ils
    apparaissent tous comme un desaccord entre ce que le juge lit et ce que
    Python execute. Aucun motif lexical n'est ajoute.
    """
    try:
        vrais, non_lit = cas_python(texte_python)
    except SyntaxError as exc:
        return {('FICHIER PYTHON INVALIDE', 'ligne %s' % exc.lineno)}
    ecarts = set(ecarts_du_juge(juge, texte_feature, texte_python))
    lus = set(juge.titres_tests(texte_python))
    for ligne in non_lit:
        ecarts.add(('CAS A TITRE NON LITTERAL', 'ligne %d' % ligne))
    for titre in lus - set(vrais):
        ecarts.add(('LU PAR LE JUGE SANS ETRE UN CAS', titre))
    for titre in set(vrais) - lus:
        ecarts.add(('CAS INVISIBLE AU JUGE', titre))
    for titre in {t for t in vrais if vrais.count(t) > 1}:
        ecarts.add(('TITRE DE CAS EN DOUBLE', titre))
    scenarios = juge.titres_scenarios(texte_feature)
    for titre in {t for t in scenarios if scenarios.count(t) > 1}:
        ecarts.add(('TITRE DE SCENARIO EN DOUBLE', titre))
    return ecarts


def mode_couple(juge: types.ModuleType) -> int:
    f, t = RACINE / FEATURE_US013, RACINE / TESTS_US013
    print('Couple US-01.3 (hors COUPLES jusqu a T14) :')
    print('  %s' % FEATURE_US013)
    print('  %s' % TESTS_US013)
    if not f.is_file() or not t.is_file():
        absent = FEATURE_US013 if not f.is_file() else TESTS_US013
        print('\nECART : FICHIER ABSENT  <<%s>>' % absent)
        return CODE_NE_LIT_PAS
    ecarts = controler_couple(juge, f.read_text(encoding='utf-8'),
                              t.read_text(encoding='utf-8'))
    if ecarts:
        print('\nECART : %d ecart(s) -- T14 rendrait le job REQUIS rouge, ou masquerait un'
              ' scenario sans cas.' % len(ecarts))
        for motif, titre in sorted(ecarts):
            print('  [%s] <<%s>>' % (motif, titre))
        return CODE_NE_LIT_PAS
    print('\nCouple exact, juge et analyseur Python d accord : T14 peut inscrire le couple.')
    return CODE_LIT


# ---------------------------------------------------------------- autotest

def _juge_frais() -> types.ModuleType:
    return charger_juge()


def selftest() -> int:
    """Autotest de MUTATION. Les mutants alterent le COMPORTEMENT du juge (lecteur
    muet, intrus, echappement non resolu, report de ligne perdu, frontiere
    ajoutee, attribut retire) ; aucun n'est construit en ajoutant le nom de la
    fonction d'enregistrement a un corpus. Verdicts compares en ENSEMBLES."""
    resultats: list[tuple[str, bool, str]] = []
    noms_positifs = {nom for nom, _, _ in CAS_POSITIFS}
    noms_constats_frontiere = {
        'appel finissant par le nom, argument hors scenarios',
        'appel finissant par le nom, argument = un titre de scenario',
        'methode portant le nom, argument = un titre de scenario',
    }

    def verifie(nom: str, juge: types.ModuleType, code_attendu: int,
                echecs_attendus: set[str], perimes_attendus: set[str]) -> None:
        code, echecs, perimes, _ = evaluer(juge)
        ok = (code, echecs, perimes) == (code_attendu, echecs_attendus, perimes_attendus)
        resultats.append((nom, ok, 'code=%d echecs=%r perimes=%r'
                          % (code, sorted(echecs), sorted(perimes))))

    # Reference : le juge reel.
    verifie('juge reel => 0, aucun echec, aucun constat perime',
            _juge_frais(), CODE_LIT, set(), set())

    # M1 : lecteur muet. ⚠️ Le constat « f-string » TIENT sous ce mutant, et
    # c'est mesure (premiere execution de l'autotest) : un juge qui ne lit
    # RIEN et un juge qui ne lit pas une f-string rendent le MEME ecart. Il
    # est donc exclu des perimes attendus -- l'ensemble, pas le cardinal.
    j = _juge_frais()
    j.titres_tests = lambda texte: []
    verifie('M1 lecteur muet => 1, TOUS les cas positifs en echec',
            j, CODE_NE_LIT_PAS, noms_positifs,
            {n for n, _, _, _, _ in _constats(j)} - {'titre en f-string'})

    # M2 : un intrus s'ajoute a chaque lecture.
    j = _juge_frais()
    lecteur = j.titres_tests
    j.titres_tests = lambda texte, _l=lecteur: _l(texte) + ['zq-intrus-7']
    code, echecs, _, _ = evaluer(j)
    resultats.append(('M2 intrus a chaque lecture => 1, tous les cas positifs en echec',
                      code == CODE_NE_LIT_PAS and echecs == noms_positifs,
                      'code=%d echecs=%r' % (code, sorted(echecs))))

    # M3 : l'echappement n'est plus resolu (regression du remplacement).
    j = _juge_frais()
    lecteur = j.titres_tests
    j.titres_tests = lambda texte, _l=lecteur: [x.replace("'", "\\'") for x in _l(texte)]
    attendus = {nom for nom, scen, _ in CAS_POSITIFS if any("'" in s for s in scen)}
    code, echecs, _, _ = evaluer(j)
    resultats.append(('M3 echappement non resolu => 1, exactement les cas a apostrophe',
                      code == CODE_NE_LIT_PAS and echecs == attendus,
                      'code=%d echecs=%r attendus=%r' % (code, sorted(echecs), sorted(attendus))))

    # M4 : le report a la ligne suivante est perdu (blanc horizontal seulement).
    j = _juge_frais()
    motif = j.MOTIF_TEST.pattern
    mute = motif.replace('\\(\\s*', '\\([ \\t]*')
    if mute == motif:
        resultats.append(('M4 mutant construit', False, 'le motif n a pas la forme attendue'))
    else:
        j.MOTIF_TEST = re.compile(mute, j.MOTIF_TEST.flags)
        attendus = {nom for nom, _, src in CAS_POSITIFS if 'test(\n' in src}
        code, echecs, _, _ = evaluer(j)
        resultats.append(('M4 report de ligne perdu => 1, exactement les cas reportes',
                          code == CODE_NE_LIT_PAS and echecs == attendus,
                          'code=%d echecs=%r attendus=%r'
                          % (code, sorted(echecs), sorted(attendus))))

    # M5 : le juge est corrige d'une frontiere (le jour ou il le sera) => les
    # constats de frontiere PERIMENT, les cas positifs restent lus => 3.
    j = _juge_frais()
    j.MOTIF_TEST = re.compile('(?<![\\w.])' + j.MOTIF_TEST.pattern, j.MOTIF_TEST.flags)
    verifie('M5 frontiere ajoutee au juge => 3, exactement les constats de frontiere perimes',
            j, CODE_DEFAUT, set(), noms_constats_frontiere)

    # M6 : juge ampute d'une fonction => defaut de l'instrument.
    j = _juge_frais()
    del j.titres_tests
    try:
        exiger_attributs(j)
        resultats.append(('M6 juge ampute => DefautInstrument', False, 'aucune levee'))
    except DefautInstrument:
        resultats.append(('M6 juge ampute => DefautInstrument', True, ''))

    # Mode --couple, sur des couples SYNTHETIQUES.
    j = _juge_frais()
    feat = feature_synthetique([_A, _B])
    conforme = 'test("%s", lambda: None)\ntest(\n    "%s",\n    lambda: None,\n)\n' % (_A, _B)
    obtenu = controler_couple(j, feat, conforme)
    resultats.append(('C1 couple conforme => 0 ecart', obtenu == set(), repr(sorted(obtenu))))

    m, o = j.MANQUANT, j.ORPHELIN
    cas_couple = (
        ('C2 cas remplace par latest(titre) => divergence nommee, le juge ne voit rien',
         'test("%s", lambda: None)\nlatest("%s")\n' % (_A, _B),
         {('LU PAR LE JUGE SANS ETRE UN CAS', _B)}),
        ('C3 cas remplace par un commentaire => divergence nommee',
         'test("%s", lambda: None)\n# test("%s")\n' % (_A, _B),
         {('LU PAR LE JUGE SANS ETRE UN CAS', _B)}),
        ('C4 titre en f-string => non litteral ET manquant',
         'test("%s", lambda: None)\ntest(f"%s", lambda: None)\n' % (_A, _B),
         {('CAS A TITRE NON LITTERAL', 'ligne 2'), (m, _B)}),
        ('C5 deux cas au meme titre => double nomme, le juge ne voit rien',
         'test("%s", lambda: None)\ntest("%s", lambda: None)\ntest("%s", lambda: None)\n'
         % (_A, _A, _B),
         {('TITRE DE CAS EN DOUBLE', _A)}),
        ('C6 cas orphelin => ecart du juge',
         conforme + 'test("Hors specification zq", lambda: None)\n',
         {(o, 'Hors specification zq')}),
        ('C7 Python invalide => refus', 'test("%s", lambda: None\n' % _A,
         {('FICHIER PYTHON INVALIDE', 'ligne 1')}),
    )
    for nom, source, attendu in cas_couple:
        obtenu = controler_couple(j, feat, source)
        resultats.append((nom, obtenu == attendu,
                          'attendu=%r obtenu=%r' % (sorted(attendu), sorted(obtenu))))

    refus = [r for r in resultats if not r[1]]
    for nom, ok, detail in resultats:
        print('  [%s] %s' % ('OK' if ok else 'ECHEC', nom))
        if not ok:
            print('        %s' % detail)
    print('\nAutotest : %d assertion(s), %d echec(s).' % (len(resultats), len(refus)))
    return CODE_NE_LIT_PAS if refus else CODE_LIT


# ---------------------------------------------------------------- entree

def main(argv: list[str]) -> int:
    inconnus = [a for a in argv if a not in ('--selftest', '--couple')]
    if inconnus or len(argv) > 1:
        print('DEFAUT DE L INSTRUMENT : arguments non reconnus %r' % (argv,))
        return CODE_DEFAUT
    try:
        juge = charger_juge()
        if argv == ['--selftest']:
            return selftest()
        if argv == ['--couple']:
            return mode_couple(juge)
        code, _, _, lignes = evaluer(juge)
    except DefautInstrument as exc:
        print('DEFAUT DE L INSTRUMENT : %s' % exc)
        print("L'outil lui-meme est en cause. Rien n'a ete etabli sur le juge.")
        return CODE_DEFAUT

    print('T0 US-01.3 -- le juge %s lit-il un fichier de tests PYTHON ?' % SCRIPT_JUGE)
    print('(juge IMPORTE, verifier() rejouee sur corpus synthetique ; COUPLES non modifie)')
    print('')
    print('\n'.join(lignes))
    inscrit = any(t == TESTS_US013 for _, t in juge.COUPLES)
    print('')
    print('Information : couple US-01.3 inscrit dans COUPLES : %s.' % ('oui' if inscrit else 'non'))
    print('Information : %s %s.' % (TESTS_US013,
                                     'existe' if (RACINE / TESTS_US013).is_file()
                                     else 'absent (attendu avant T5)'))
    print('')
    if code == CODE_LIT:
        print('REPONSE : OUI. Le juge lit ces titres dans un fichier Python. Les pieges'
              ' ci-dessus sont des CONSTATS : le fichier de scenarios ne doit en porter aucun,'
              ' et --couple le verifie.')
    elif code == CODE_NE_LIT_PAS:
        print('REPONSE : NON. ARRET : retour @Architect, ADR-015 §10 a remplacer avant T5.')
    else:
        print('DEFAUT DE L INSTRUMENT : un constat documente ne tient plus, le juge a change.'
              " Rien n'a ete etabli : relire la contrainte d'ADR-015 §10 et cette sonde.")
    return code


if __name__ == '__main__':
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except (AttributeError, ValueError):
        pass
    sys.exit(main(sys.argv[1:]))
