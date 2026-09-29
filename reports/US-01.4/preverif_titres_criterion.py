# -*- coding: utf-8 -*-
"""PRE-VERIFICATION des titres, AVEC LE MEME JUGE que le gate.

⛔ On n'ecrit PAS ses propres motifs : on importe ceux de
`scripts/check_gherkin_mapping.py`. Un second jeu de motifs deriverait, et le
verdict de cette sonde cesserait de predire celui du gate — ce qui est
exactement ce qu'elle sert a eviter.

Sonde JETABLE (hors depot) : elle ne modifie rien, et T15 reste la seule tache
qui inscrit le couple.
"""
import io
import importlib.util
import sys

spec = importlib.util.spec_from_file_location(
    'mapping', 'scripts/check_gherkin_mapping.py'
)
mapping = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mapping)

FEATURE = 'tests/features/US-01.4-gestes-tuile.feature'
TESTS = 'test/e2e/gestes_tuile_test.dart'

scenarios = mapping.titres_scenarios(io.open(FEATURE, encoding='utf-8').read())
tests = mapping.titres_tests(io.open(TESTS, encoding='utf-8').read())

print('scenarios lus  : %d' % len(scenarios))
print('tests lus      : %d' % len(tests))

# ⛔ On compare des ENSEMBLES, jamais des cardinaux : un decompte egal n'est
# pas une preuve d'equivalence (regle du projet, payee trois fois).
manquants = [t for t in scenarios if t not in tests]
orphelins = [t for t in tests if t not in scenarios]

for t in manquants:
    print('  SCENARIO SANS TEST : %r' % t)
for t in orphelins:
    print('  TEST SANS SCENARIO : %r' % t)

doubles_s = {t for t in scenarios if scenarios.count(t) > 1}
doubles_t = {t for t in tests if tests.count(t) > 1}
for t in doubles_s:
    print('  TITRE DE SCENARIO EN DOUBLE : %r' % t)
for t in doubles_t:
    print('  TITRE DE TEST EN DOUBLE : %r' % t)

if manquants or orphelins or doubles_s or doubles_t:
    sys.stderr.write('ECART : T15 rendrait le job REQUIS rouge.\n')
    raise SystemExit(1)
print('OK : correspondance 1:1 exacte — T15 peut inscrire le couple.')
