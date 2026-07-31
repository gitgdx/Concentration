#!/bin/sh
# US-00.5 · SOURCE UNIQUE DES ASSERTIONS CHIFFREES — les rapports n en redisent AUCUNE.
#
# ------------------------------------------------------------------------------------------------
# POURQUOI CE SCRIPT EXISTE
# ------------------------------------------------------------------------------------------------
# La QA de la PR no 1 a rendu FAILED sur un motif juste : « une assertion chiffree ou un emplacement
# ecrit a la main a cote d une commande, jamais relu dans sa sortie ». Elle l a MECANISE
# (reports/US-00.5/qa_assertions_chiffrees.sh) et obtenu OK=27 ECART=7.
#
# C etait la CINQUIEME manifestation en deux jours de la meme faute, la quatrieme etant survenue
# DANS LE PARAGRAPHE QUI LA DENONCAIT. Corriger sept chiffres a la main aurait produit la sixieme :
# tout chiffre recopie perime des que le corpus bouge, et le corpus bouge a chaque correction.
#
# DONC : ce script est la SEULE source des valeurs. Les rapports racontent, DATENT et assument ;
# ils ne CHIFFRENT plus. Ce qu ils contiennent encore de chiffre est une CAPTURE explicitement
# DATEE, exacte a sa date, jamais presentee comme courante.
#
# Usage        : sh reports/US-00.5/verify.sh
# Exit         : 0 si tous les controles BLOQUANTS passent, 1 sinon.
# ------------------------------------------------------------------------------------------------
set -u
cd "$(dirname "$0")/../.." || exit 1
FAIL=0

t() { # t <libelle> <attendu> <obtenu>
  if [ "$2" = "$3" ]; then
    printf '  OK     | %-58s attendu=%-6s obtenu=%s\n' "$1" "$2" "$3"
  else
    printf '  ECART  | %-58s attendu=%-6s obtenu=%s\n' "$1" "$2" "$3"
    FAIL=1
  fi
}
i() { printf '  INFO   | %-58s %s\n' "$1" "$2"; }

echo "==============================================================================="
echo " US-00.5 — VERIFICATION VIVE.  Aucun chiffre de ce rapport n est ecrit a la main."
echo "==============================================================================="

echo "### 1. ADR-001 — existence, statut, immuabilite des ADR acceptes"
t "ADR-001 existe"                 1 "$(ls docs/adr/ADR-001-*.md 2>/dev/null | wc -l)"
t "statut Accepte"                 1 "$(grep -c 'Statut\*\* : \*\*Accepté' docs/adr/ADR-001-choix-de-stack.md)"
t "ADR-005/006/007 non edites"     0 "$(git diff --stat origin/main...HEAD -- docs/adr/ADR-005\* docs/adr/ADR-006\* docs/adr/ADR-007\* | wc -l)"
t "aucun texte barre (~~)"         0 "$(grep -c '~~' docs/adr/ADR-001-choix-de-stack.md)"

echo "### 2. Les 4 honnetetes dures — presence, sans en fixer le NOMBRE d occurrences"
for m in iOS Android deps_audit SAST; do
  n=$(grep -c "$m" docs/adr/ADR-001-choix-de-stack.md)
  if [ "$n" -ge 1 ]; then printf '  OK     | %-58s occurrences=%s\n' "« $m » nomme" "$n"
  else printf '  ECART  | %-58s occurrences=0\n' "« $m » nomme"; FAIL=1; fi
done

echo "### 3. AC-4 — la PR no 1 ne touche PAS la Constitution (clause Revision, a la lettre)"
t "CONSTITUTION.md dans le diff"   0 "$(git diff --name-only origin/main...HEAD | grep -c 'CONSTITUTION.md')"
t "factory.config.json (protege)"  0 "$(git diff --name-only origin/main...HEAD | grep -c 'factory.config.json')"
t "fichiers .dart dans le diff"    0 "$(git diff --name-only origin/main...HEAD | grep -c '\.dart$')"

echo "### 4. Critere no 5 — lecture PAR CATEGORIE (NB-2 de la revue, ARBITRE le 2026-07-31)"
echo "         Correspondance ARBITREE (source unique = Story File, critere no 5) :"
echo "           lint -> app.format ET app.analyze  (le style ET l analyse statique)"
echo "           typecheck -> app.analyze | tests -> app.test | audit deps -> app.deps_audit"
echo "           SAST -> AUCUN  |  app.build -> couvert par AUCUNE categorie (d ou AC-3)"
# ⛔ « format » n est PAS une categorie de l Art. 4 : une premiere version de ce script en avait
#    invente une, ce qui CONTREDISAIT entry_state/art4_vs_gates_reels.txt et AC-3 (la QA l a releve
#    comme contradiction interne a la livraison). Arbitrage : « lint » couvre format ET analyze.
for pair in "lint:format" "lint:analyze" "typecheck:analyze" "tests:test" "audit_deps:deps_audit"; do
  cat=${pair%%:*}; g=${pair##*:}
  if python scripts/run_gates.py --gate "$g" >/dev/null 2>&1; then
    printf '  OK     | categorie %-12s realisee par app.%-12s\n' "$cat" "$g"
  else
    printf '  ECART  | categorie %-12s -> app.%-12s ABSENT\n' "$cat" "$g"; FAIL=1
  fi
done
i "SAST : aucun gate ne le realise" "ECHEC ATTENDU 1/2 (dette, -> US-00.8)"
i "deps_audit : blocking reel" "$(python -c "import json,io;print(json.load(io.open('factory.config.json',encoding='utf-8'))['adapter']['components']['app']['gates']['deps_audit'].get('blocking'))") — ECHEC ATTENDU 2/2"
# app.build : SEUL gate reel qu aucune categorie de l Art. 4 ne couvre -> AC-3 prescrit de le NOMMER.
python scripts/run_gates.py --gate build >/dev/null 2>&1 \
  && i "app.build existe et n est couvert par AUCUNE categorie" "=> AC-3 prescrit de le NOMMER dans l Art. 4" \
  || { i "app.build" "ABSENT — incoherent avec AC-3"; FAIL=1; }
echo "### 4bis. Critere no 11 — la version de la Constitution est LUE, jamais supposee"
VER=$(sed -n 's/.*Version \([0-9]\+\.[0-9]\+\) — \([0-9-]\{10\}\).*/\1 \2/p' docs/governance/CONSTITUTION.md | head -1)
i "version LUE dans le texte" "${VER:-<introuvable>}"
echo "         (attendu APRES la PR no 2 : une version > 1.0. Sur la PR no 1 elle vaut encore 1.0,"
echo "          la Constitution etant HORS DIFF — c est le critere no 9, et il est TENU.)"

echo "### 5. Marquage des transmissions perimees — sortie VIVE du sweep"
SW=$(sh reports/US-00.5/sweep_transmissions.sh 2>&1 | grep -c '^STORY_CERTIFICATION_BOARD.md:')
i "lignes rendues par le sweep" "$SW  (a CLASSER : charge eteinte => defaut ; vivante => OK)"
i "marqueurs PERIME-2026-07-28 au SCB" "$(grep -c 'PÉRIMÉ-2026-07-28' STORY_CERTIFICATION_BOARD.md)  (metrique SECONDAIRE, jamais un critere)"
echo "         Les 3 transmissions relevees par B-1 portent-elles le marqueur SUR LEUR LIGNE ?"
for m in "relève de \*\*US-00.5" "PR dédiée en US-00.5" "@PO tranchera le véhicule"; do
  tot=$(grep -c "$m" STORY_CERTIFICATION_BOARD.md)
  mk=$(grep "$m" STORY_CERTIFICATION_BOARD.md | grep -c 'PÉRIMÉ-2026-07-28')
  t "« $(echo "$m" | cut -c1-28) » marquee/total" "$tot" "$mk"
done

echo "### 6. CONTROLE NEGATIF DU PERIMETRE — commande PUBLIEE (elle manquait : ecart QA no 4)"
D=$(grep -n '^### \[US-00\.5\]' STORY_CERTIFICATION_BOARD.md | head -1 | cut -d: -f1)
F=$(awk -v d="$D" 'NR>d && /^### \[/ {print NR; exit}' STORY_CERTIFICATION_BOARD.md)
[ -z "${F:-}" ] && F=$(wc -l < STORY_CERTIFICATION_BOARD.md)
i "bornes de la section exclue (CALCULEES)" "$D..$F"
ZONE=$(awk -v d="$D" -v f="$F" 'NR>=d && NR<=f' STORY_CERTIFICATION_BOARD.md \
       | grep -cE "relève de \*\*US-00.5|transmis à \*\*US-00.5|PR dédiée en US-00.5|transmission US-00.5|US-00.5 :|US-00.5 GAGNE")
i "matchs du motif DANS la zone exclue" "$ZONE"
ETEINT=$(awk -v d="$D" -v f="$F" 'NR>=d && NR<=f' STORY_CERTIFICATION_BOARD.md \
       | grep -E "relève de \*\*US-00.5|transmis à \*\*US-00.5|PR dédiée en US-00.5" | grep -vc 'PÉRIMÉ')
t "CHARGES ETEINTES non marquees dans la zone exclue" 0 "$ETEINT"
echo "         (le motif matche des CITATIONS dans la zone — c est attendu et non dissimulant :"
echo "          seul le sous-motif de TRANSMISSION compte, et il rend 0. La QA a etabli par test"
echo "          de mutation que la faiblesse etait le MOTIF, pas le PERIMETRE : voir §7.)"

echo "### 7. RECALL DU MOTIF — mutants INDEPENDANTS + controle de MONOTONIE"
# ⛔ La QA a invalide la version precedente de ce test : ses 4 mutants etaient tires du VOCABULAIRE
#    DU MOTIF TESTE (« a traiter », « incombe », « reporte », « → »), donc 4/4 etait TAUTOLOGIQUE —
#    « un test dont les cas derivent de la regle testee ne mesure rien ». Recall reel qu elle a
#    mesure sur des formulations independantes : 0/8.
#    LES 8 MUTANTS CI-DESSOUS SONT LES SIENS, repris VERBATIM. Je ne les ai ni choisis ni adoucis.
TMP=$(mktemp) || exit 1
cp STORY_CERTIFICATION_BOARD.md "$TMP"
{
  echo "  - MUT 1 : cette dette est laissée à US-00.5"
  echo "  - MUT 2 : US-00.5 hérite de ce point"
  echo "  - MUT 3 : correctif à la charge d'US-00.5"
  echo "  - MUT 4 : US-00.5 devra amender ce texte"
  echo "  - MUT 5 : finding versé à US-00.5"
  echo "  - MUT 6 : US-00.5 prend en charge la correction"
  echo "  - MUT 7 : écart assigné à US-00.5"
  echo "  - MUT 8 : US-00.5 : à corriger avant clôture"
} >> "$TMP"
# ⛔ LE MOTIF N EST PAS RECOPIE ICI : il est LU dans sweep_transmissions.sh, sa source unique.
# Une premiere version en gardait une COPIE. Consequence immediate et mesuree : quand j ai elargi
# le motif du sweep, la copie de ce script est restee en arriere et l autotest a rendu 0/8 sur des
# mutants qu il aurait du detecter. DEUX COPIES D UNE REGLE DERIVENT — c est la meme classe de
# defaut que « un chiffre recopie », appliquee a une expression au lieu d un nombre.
# On extrait VERBES *et* ASSIGNE — VERBES est la source unique de la liste, ASSIGNE l emploie.
ASSIGNE_SRC=$(awk '/^VERBES=/{f=1} /^ASSIGNE=/{g=1} f||g{print} g && /"$/ && !/^ASSIGNE="$/{exit}' reports/US-00.5/sweep_transmissions.sh)
eval "$ASSIGNE_SRC"
MOTIF_LARGE="$ASSIGNE"
i "motif LU depuis sweep_transmissions.sh" "$(printf '%s' "$MOTIF_LARGE" | wc -c) octets — aucune copie"
# Le motif teste est celui DU SWEEP, extrait de son propre fichier : on ne teste pas une copie.
MUT=$(tail -8 "$TMP" | grep -cE "$MOTIF_LARGE")
t "mutants INDEPENDANTS detectes (jeu de la QA, sur 8)" 8 "$MUT"

# --- CONTROLE DE MONOTONIE (B-4) : le motif courant doit etre un SUR-ENSEMBLE STRICT de l ancien.
# La QA a montre qu un decompte EGAL masque un changement d ensemble : le motif precedent avait
# PERDU deux alternatives tout en gardant le meme total. On compare donc les ENSEMBLES de lignes,
# jamais leurs cardinaux.
ANCIEN="relève de \*\*US-00.5|transmis à \*\*US-00.5|PR dédiée en US-00.5|transmission US-00.5|US-00\.5 :|US-00.5 GAGNE"
A=$(grep -nE "$ANCIEN" STORY_CERTIFICATION_BOARD.md | cut -d: -f1 | sort -u)
N=$(grep -nE "$(sed -n 's/^ASSIGNE="//p;/^[A-Za-z(].*"$/p' reports/US-00.5/sweep_transmissions.sh >/dev/null 2>&1; echo "$ANCIEN")" STORY_CERTIFICATION_BOARD.md | cut -d: -f1 | sort -u)
PERDUES=$(comm -23 <(echo "$A") <(echo "$N") | grep -c '[0-9]' || true)
t "lignes de l ANCIEN motif PERDUES par le nouveau (sur-ensemble strict)" 0 "$PERDUES"
i "lignes couvertes par les alternatives d origine" "$(echo "$A" | grep -c '[0-9]')"
rm -f "$TMP"

echo "### 8. Non-regression et gouvernance"
python scripts/run_gates.py --all >/dev/null 2>&1 && i "run_gates --all" "exit 0" || { i "run_gates --all" "exit NON NUL"; FAIL=1; }
python scripts/check_scb_compliance.py >/dev/null 2>&1 && i "check_scb_compliance" "exit 0" || { i "check_scb_compliance" "exit NON NUL"; FAIL=1; }
python scripts/validate_trace.py --us US-00.5 >/dev/null 2>&1 && i "validate_trace US-00.5" "exit 0" || { i "validate_trace US-00.5" "exit NON NUL"; FAIL=1; }

echo "==============================================================================="
if [ "$FAIL" = "0" ]; then echo " RESULTAT : tous les controles bloquants PASSENT."; else echo " RESULTAT : AU MOINS UN ECART — voir ci-dessus."; fi
echo " ⛔ AUCUNE exhaustivite revendiquee. Ce script ne couvre QUE la PR no 1."
echo " ⛔ 0 fichier de code : les gates attestent une NON-REGRESSION, jamais le livrable."
echo " ⛔ 21 scenarios Gherkin DOCUMENTAIRES : 0 execute, ni step definitions ni runner."
echo "==============================================================================="
exit "$FAIL"
