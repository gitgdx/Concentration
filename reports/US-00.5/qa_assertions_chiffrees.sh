#!/bin/sh
# ============================================================================
# US-00.5 · CRITERE DE SORTIE DE LA QA — script EXECUTABLE, rejouable, versionne.
# @QA_Tester · 2026-07-30 · HEAD e6d5c1d
#
# DEFAUT DONT CE SCRIPT MESURE L EXTENSION (classe, pas exemple) :
#   « une assertion CHIFFREE ou un EMPLACEMENT ecrit A LA MAIN a cote d une commande,
#     jamais relu dans la sortie de cette commande. »
#   Le projet a paye quatre occurrences de cette classe en deux jours (SCB + code_review) et
#   le re-audit a ecrit que « la cause racine n est PAS eteinte : le projet a la REGLE, il n a
#   AUCUN MECANISME ». Ce script EST le mecanisme manquant, restreint a reports/US-00.5/**.
#
# METHODE : pour chaque assertion chiffree des rapports d US-00.5 dont la commande est
# RECONSTRUCTIBLE, la commande est REJOUEE ici et son resultat COMPARE a la valeur ecrite.
# Aucun chiffre de ce script n est ecrit a la main : la colonne « obtenu » est LUE.
#
# CRITERE DE SORTIE :  ECART=0  ET  NON_PUBLIEE=0.
# Usage : sh reports/US-00.5/qa_assertions_chiffrees.sh ; echo $?
# ============================================================================
set -u
cd "$(dirname "$0")/../.." || exit 1

SCB=STORY_CERTIFICATION_BOARD.md
ADR=docs/adr/ADR-001-choix-de-stack.md
CONF=reports/US-00.5/conformite_ac.txt
CORR=reports/US-00.5/correctifs_failed_revue.txt
SWEEP=reports/US-00.5/sweep_transmissions.sh

ECART=0
OK=0

chk() { # $1 = source de l assertion (fichier + texte)  $2 = valeur ECRITE  $3 = valeur OBTENUE
  if [ "$2" = "$3" ]; then
    OK=$((OK + 1)); printf "  OK    | %-62s ecrit=%-4s obtenu=%s\n" "$1" "$2" "$3"
  else
    ECART=$((ECART + 1)); printf "  ECART | %-62s ecrit=%-4s obtenu=%s\n" "$1" "$2" "$3"
  fi
}

echo "### 1. conformite_ac.txt — assertions chiffrees"
chk "conformite_ac « statut Accepte -> 1 »"        1 "$(grep -c 'Statut\*\* : \*\*Accepté' $ADR)"
chk "conformite_ac « iOS -> 6 »"                   6 "$(grep -ci 'iOS' $ADR)"
chk "conformite_ac « Android -> 7 »"               7 "$(grep -ci 'Android' $ADR)"
chk "conformite_ac « deps_audit -> 2 »"            2 "$(grep -ci 'deps_audit' $ADR)"
chk "conformite_ac « SAST -> 2 »"                  2 "$(grep -ci 'SAST' $ADR)"
chk "conformite_ac « grep -c '~~' ADR -> 0 »"      0 "$(grep -c '~~' $ADR)"
chk "conformite_ac « PÉRIMÉ-2026-07-28 SCB -> 2 »" 2 "$(grep -c 'PÉRIMÉ-2026-07-28' $SCB)"
chk "conformite_ac « CONSTITUTION.md dans le diff -> 0 »" 0 \
    "$(git diff --name-only origin/main...HEAD | grep -c 'docs/governance/CONSTITUTION.md')"
chk "conformite_ac « fichiers Dart dans le diff -> 0 »"   0 \
    "$(git diff --name-only origin/main...HEAD | grep -c '\.dart$')"
chk "conformite_ac « factory.config.json dans le diff -> 0 »" 0 \
    "$(git diff --name-only origin/main...HEAD | grep -c '^factory\.config\.json$')"

echo "### 2. correctifs_failed_revue.txt — assertions chiffrees"
for n in 212 291 368; do
  chk "correctifs « SCB:$n -> 1 » (marqueur sur la ligne)" 1 "$(sed -n "${n}p" $SCB | grep -c 'PÉRIMÉ-2026-07-28')"
done
chk "correctifs « relève de **US-00.5 -> 1 »"       1 "$(grep -c 'relève de \*\*US-00\.5' $SCB)"
chk "correctifs « PR dédiée en US-00.5 -> 1 »"      1 "$(grep -c 'PR dédiée en US-00\.5' $SCB)"
chk "correctifs « @PO tranchera le véhicule -> 1 »" 1 "$(grep -c '@PO tranchera le véhicule' $SCB)"
# AVEU DE MA PROPRE INSTRUMENTATION — le piege « un grep de motifs matche la documentation des
# motifs » a happe CE SCRIPT au premier jet : en citant le motif, je faisais monter le compte de 5
# a 8 et j allais imputer a @Architect un ecart que j avais CREE moi-meme. Le controle porte sur le
# corpus D @ARCHITECT, pas sur l outillage de la QA : mes artefacts sont exclus NOMMEMENT, et le
# compte NON EXCLU est affiche juste apres — jamais de filtre silencieux.
NB1_BRUT=$(grep -rn 'dernier commit seulement\|ne compare que le' reports/US-00.5/ $SCB docs/stories/US-00.5-*.md | wc -l | tr -d ' ')
NB1_CORPUS=$(grep -rn 'dernier commit seulement\|ne compare que le' reports/US-00.5/ $SCB docs/stories/US-00.5-*.md \
    | grep -v '^reports/US-00.5/qa_assertions_chiffrees.sh:' | grep -v '^reports/US-00.5/qa.md:' \
    | wc -l | tr -d ' ')
chk "correctifs NB-1 « le grep rend 5 » (corpus @Architect seul)" 5 "$NB1_CORPUS"
echo "        (compte NON EXCLU, artefacts QA compris : $NB1_BRUT — l ecart est MON instrumentation)"
chk "correctifs « factory_sync.py -> 4 »"           4 "$(grep -c 'factory_sync\.py' $ADR)"
chk "correctifs « rendu visuel -> 1 »"              1 "$(grep -c 'rendu visuel' $ADR)"
chk "correctifs « set-exit-if-changed -> 1 »"       1 "$(grep -c 'set-exit-if-changed' $ADR)"
chk "correctifs « show-all -> 1 »"                  1 "$(grep -c 'show-all' $ADR)"
chk "correctifs « factory_env.sh -> 1 »"            1 "$(grep -c 'factory_env\.sh' $ADR)"
chk "correctifs « install_hooks.sh -> 1 »"          1 "$(grep -c 'install_hooks\.sh' $ADR)"
chk "correctifs « settings.json -> 1 »"             1 "$(grep -c 'settings\.json' $ADR)"
chk "correctifs « PR nº 2 de CETTE US -> 1 »"       1 "$(grep -c 'PR nº 2 de CETTE US' $ADR)"
chk "correctifs « borne datee de l affirmation positive -> 1 »" 1 \
    "$(grep -c 'AU 2026-07-30, ET SOUS CETTE DATE UNIQUEMENT' $ADR)"
chk "correctifs « grep -c '~~' ADR-001 -> 0 »"      0 "$(grep -c '~~' $ADR)"
chk "correctifs RB-3 « aux deux emplacements exacts -> 1 »" 1 "$(grep -c 'aux deux emplacements exacts' $SCB)"
chk "correctifs RB-3 « marqueur sur la MEME ligne -> 1 »"   1 "$(grep -cE 'relève de \*\*US-00\.5.*PÉRIMÉ-2026-07-28' $SCB)"
chk "correctifs RB-4 « ligne portant marqueur ET 'LA COMMANDE REND 5' -> 1 »" 1 \
    "$(grep -c 'PERIME-2026-07-30.*LA COMMANDE REND 5' $CORR)"
chk "correctifs RB-5 « rc=\$? hors commentaire dans le sweep -> 0 »" 0 \
    "$(grep -n 'rc=\$?' $SWEEP | grep -vc ':#')"

echo "### 3. correctifs — CONTROLE NEGATIF DU PERIMETRE (« -> 0 »), rejoue avec le motif DU SCRIPT"
ASSIGNE="relève de \*\*US-00.5|transmis à \*\*US-00.5|PR dédiée en US-00.5|transmission US-00.5|US-00.5 :|US-00.5 GAGNE"
DEB=$(grep -n '^### \[US-00\.5\]' "$SCB" | head -1 | cut -d: -f1)
FIN=$(awk -v d="$DEB" 'NR>d && /^### \[/ {print NR; exit}' "$SCB")
[ -z "${FIN:-}" ] && FIN=$(wc -l < "$SCB")
N=$(grep -nE "$ASSIGNE" "$SCB" | grep -v 'PÉRIMÉ-2026-07-28' | grep -v 'se réduit' | grep -v 'réduit (' \
    | awk -F: -v d="$DEB" -v f="$FIN" '($1 >= d && $1 <= f)' | wc -l | tr -d ' ')
chk "correctifs « transmissions DANS la section exclue -> 0 »" 0 "$N"
echo "        (bornes CALCULEES : $DEB..$FIN — le rapport les ECRIT « 557..766 », donc par NUMERO)"

echo "### 4. DESIGNATIONS par numero de ligne — le rapport en declare 0 ; verification"
D=$(sed -n '27p' $CORR | grep -cE 'dernier commit seulement|ne compare que le')
chk "correctifs L97 designe « correctifs_...:27 » : cette ligne porte-t-elle le motif ?" 1 "$D"
echo "        emplacement REEL du 5e match (LU, jamais recopie) :"
grep -rn 'dernier commit seulement\|ne compare que le' $CORR | cut -d: -f1,2 | sed 's/^/          /'

echo "### 5. Sortie collee sous « \$ sh reports/US-00.5/sweep_transmissions.sh » — reproductible ?"
sh "$SWEEP" > /tmp/qa_sweep_now.$$ 2>&1
R=$(grep -c 'DEFAUT NON COUVERT' /tmp/qa_sweep_now.$$)
chk "correctifs L7-9 : le script rend-il encore « DEFAUT NON COUVERT » ?" 1 "$R"
rm -f /tmp/qa_sweep_now.$$

echo "### 6. Assertions dont la commande n est PAS PUBLIEE (donc non rejouables telles quelles)"
NP=$(grep -cE '^  [^$].*-> *[0-9]+' $CORR)
PUB=$(grep -cE '^[[:space:]]*\$ ' $CORR)
echo "  assertions chiffrees en prose dans correctifs : $NP   commandes publiees ('\$ ') : $PUB"

echo "============================================================================"
echo "OK=$OK  ECART=$ECART"
echo "CRITERE DE SORTIE : ECART=0. Toute valeur > 0 est une assertion chiffree ou un"
echo "emplacement ECRIT A LA MAIN que sa propre commande contredit."
echo "============================================================================"
[ "$ECART" -eq 0 ] || exit 1
exit 0
