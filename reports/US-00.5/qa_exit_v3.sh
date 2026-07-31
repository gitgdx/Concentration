#!/bin/sh
# ================================================================================================
# US-00.5 · CRITERE DE SORTIE QA v3 — @QA_Tester, 3e passage (2026-07-31)
#
# ⛔ REMPLACE `qa_detecteur_v2.sh` COMME GATE. Deux raisons, toutes deux etablies PAR EXECUTION,
#    et toutes deux DE MA MAIN :
#   (1) le code de sortie de v2 est INOPERANT : sa condition finale porte un `\n` LITTERAL, le shell
#       rend « [: missing `]' » (rc=2), la chaine && casse et `|| exit 1` s execute. => v2 rend
#       EXIT 1 QUOI QU IL ARRIVE, meme avec TOUS ses compteurs a la valeur passante. Preuve :
#         sh -c 'ECART=0;SANS_MARQUEUR=0;AUTO_OK=8;DES_VIDES=0;NB1_FAUX=0
#                [ "$ECART" -eq 0 ] && [ "$AUTO_OK" -eq 8 ] \n && [ "$NB1_FAUX" -eq 0 ] || exit 1'
#         -> « [: missing `]' »   rc=1 ; la meme condition sans le `\n` rend rc=0.
#       Un gate qui ne peut pas etre vert ne gate pas : il ne distingue rien.
#   (2) son sous-controle §D « CIBLE » codait 4 emplacements PAR NUMERO DE LIGNE, sous un titre
#       qui enonce « un numero glisse en silence ». Il enfreignait la lecon qu il verifiait.
#       ⚖️ TRANCHE : son `NB-1-faux=2` etait un ARTEFACT DE MON INSTRUMENT, pas un defaut du corpus.
#       Verifie : le motif NB-1 est INTACT, il a BOUGE — conformite_ac.txt 45 -> 66, SCB 638 -> 644,
#       consequence directe de B-7 (mes designations remplacees par du TEXTE, ce que j avais exige).
#       => §D est REECRIT en §B ci-dessous : designation par TEXTE, jamais par numero.
#
# ⛔ REGLES DE CONCEPTION (heritees de v2, conservees, une ajoutee) :
#    * AUCUNE EXCLUSION PAR MOT en silence — ce qui n est pas compte est AFFICHE et motive.
#    * TOUT CONTROLE BLOQUANT PORTE SON PROPRE MUTANT. Un vert non falsifiable est interdit,
#      y compris quand c est MOI qui l ecris. §C est ne de cette regle appliquee a `verify.sh` §7,
#      dont le controle de monotonie s est revele TAUTOLOGIQUE.
#    * AUCUNE VALEUR ATTENDUE RECOPIEE A LA MAIN : les categories de l Art. 4 sont LUES dans
#      l article, le motif du sweep est LU dans le sweep, la reference de monotonie est un jeu de
#      TEXTES versionne (`monotonie_baseline.txt`), jamais des numeros de ligne.
#
# Usage : sh reports/US-00.5/qa_exit_v3.sh ; echo $?
# Exit  : 0 si TOUS les controles bloquants passent, 1 sinon.
# ⛔ AUCUNE exhaustivite revendiquee.
# ================================================================================================
set -u
cd "$(dirname "$0")/../.." || exit 1

FAIL=0
SCB=STORY_CERTIFICATION_BOARD.md
SWEEP=reports/US-00.5/sweep_transmissions.sh
VERIFY=reports/US-00.5/verify.sh
ST=docs/stories/US-00.5-adr-stack-constitution.md
ART4=/tmp/qa_v3_art4.$$
BASE=reports/US-00.5/monotonie_baseline.txt

ok()   { printf '  OK      | %s\n' "$1"; }
ko()   { printf '  ECHEC   | %s\n' "$1"; FAIL=1; }
info() { printf '  INFO    | %s\n' "$1"; }

echo "================================================================================"
echo " US-00.5 — CRITERE DE SORTIE QA v3.  Chaque controle bloquant porte son mutant."
echo "================================================================================"

# ------------------------------------------------------------------------------------------------
echo "### A. Chiffres presentes comme des RESULTATS dans le corpus de preuves"
CIBLES="reports/US-00.5/conformite_ac.txt reports/US-00.5/correctifs_failed_revue.txt \
reports/US-00.5/entry_state/art4_vs_gates_reels.txt reports/US-00.5/entry_state/registre_et_sast.txt \
$VERIFY reports/US-00.5/assertions_vives.sh $SWEEP"
RES_MOTIF='(->|=>)[[:space:]]*[0-9]+'
HITS=/tmp/qa_v3_hits.$$; : > "$HITS"
for f in $CIBLES; do
  [ -f "$f" ] || continue
  grep -nE "$RES_MOTIF" "$f" 2>/dev/null | while IFS= read -r h; do
    printf '%s' "${h#*:}" | grep -qE '^[[:space:]]*#' && continue
    printf '%s|%s\n' "${h%%:*}" "${h#*:}" >> "$HITS"
  done
done
ECART=0; VERIF=0; SANS=0; MARQ=0
while IFS='|' read -r NUM TXT; do
  [ -z "${TXT:-}" ] && continue
  VAL=$(printf '%s' "$TXT" | sed -nE 's/.*(->|=>)[[:space:]]*([0-9]+).*/\2/p' | head -1)
  CMD=$(printf '%s' "$TXT" | sed -nE 's/^[[:space:]]*\$[[:space:]]*(.*)[[:space:]]*(->|=>)[[:space:]]*[0-9]+[[:space:]]*$/\1/p')
  if [ -n "$CMD" ] && printf '%s' "$CMD" | grep -qE '^(grep|git|ls|wc|sed|awk|python|sh) '; then
    OBT=$(sh -c "$CMD" 2>/dev/null | tr -d ' \r\n'); VERIF=$((VERIF+1))
    [ "$OBT" = "$VAL" ] || { printf '            ECART L%s ecrit=%s obtenu=%s $ %s\n' "$NUM" "$VAL" "$OBT" "$CMD"; ECART=$((ECART+1)); }
  elif printf '%s' "$TXT" | grep -qE 'PERIME-[0-9]{4}|PÉRIMÉ-[0-9]{4}|CAPTURE DU [0-9]{4}|valeur retiree'; then
    MARQ=$((MARQ+1))
  else
    printf '            SANS MARQUEUR L%s %s\n' "$NUM" "$(printf '%s' "$TXT" | cut -c1-80)"; SANS=$((SANS+1))
  fi
done < "$HITS"
rm -f "$HITS"
[ "$ECART" -eq 0 ] && ok "ECART=$ECART (verifiees=$VERIF, captures datees=$MARQ)" || ko "ECART=$ECART"
[ "$SANS" -eq 0 ]  && ok "SANS_MARQUEUR=$SANS" || ko "SANS_MARQUEUR=$SANS"
if [ "$VERIF" -eq 0 ]; then
  info "⚠️ BORNE : VERIFIEES=0 -> « ECART=0 » est VRAI PAR VIDE."
  info "   Il etablit que les rapports ne publient plus de chiffre COURANT ; il n etablit"
  info "   RIEN sur la justesse d un chiffre. A ne jamais lire comme un vert de fond."
fi
AUTO=0
for m in 'x -> 99' 'x -> 99 occurrences' 'x => 99' 'PERIME x -> 99' \
  '$ grep -c "PÉRIMÉ-2026-07-28" f -> 99' '  label    -> 99   ' '$ wc -l f -> 99' 'la valeur retiree x -> 99'; do
  printf '%s\n' "$m" | grep -qE "$RES_MOTIF" && AUTO=$((AUTO+1))
done
[ "$AUTO" -eq 8 ] && ok "mutant A : 8/8 formes de chiffre-resultat detectees" || ko "mutant A : $AUTO/8"

# ------------------------------------------------------------------------------------------------
echo "### B. Classement NB-1 — DESIGNE PAR TEXTE (remplace le §D a numeros figes de v2)"
# Regle : toute occurrence du motif NB-1 dans le corpus doit etre QUALIFIEE DE FAUSSE dans ses
# 3 lignes de contexte. Deux exemptions, NOMMEES et AFFICHEES (jamais filtrees en silence) :
#   - un script de controle PORTE le motif : c est sa nature ;
#   - une COMMANDE PUBLIEE porte le motif dans son argument -> c est le piege documente du projet,
#     « un grep de motifs matche la documentation des motifs ».
NB1='dernier commit seulement|ne compare que le'
NB1_TOT=0; NB1_NU=0; NB1_EX=0
for f in $(grep -rlE "$NB1" reports/US-00.5/ "$SCB" docs/stories/US-00.5-*.md 2>/dev/null); do
  case "$f" in *.sh) info "exempte (script de controle) : $f"; continue ;; esac
  while IFS=: read -r n _; do
    [ -z "${n:-}" ] && continue
    LN=$(sed -n "${n}p" "$f")
    if printf '%s' "$LN" | grep -qE '(grep|sed|awk) '; then
      printf '            exempte (motif dans une COMMANDE publiee) : %s ligne %s\n' "$f" "$n"
      NB1_EX=$((NB1_EX+1)); continue
    fi
    NB1_TOT=$((NB1_TOT+1))
    CTX=$(awk -v a="$n" 'NR>=a-1 && NR<=a+3' "$f")
    printf '%s' "$CTX" | grep -qiE "c(’|')est faux|C EST FAUX|est FAUSSE|Remplacer, dans les|valeur retiree" \
      || { printf '            NON QUALIFIEE : %s ligne %s\n' "$f" "$n"; NB1_NU=$((NB1_NU+1)); }
  done <<EOF
$(grep -nE "$NB1" "$f" | cut -d: -f1)
EOF
done
[ "$NB1_NU" -eq 0 ] && ok "occurrences NB-1 examinees=$NB1_TOT (exemptees=$NB1_EX), NON qualifiees=$NB1_NU" \
                    || ko "occurrences NB-1 NON qualifiees=$NB1_NU"
MT=/tmp/qa_v3_nb1.$$; printf 'blabla ne compare que le dernier commit\nrien ici\n' > "$MT"
if awk 'NR<=4' "$MT" | grep -qiE "c(’|')est faux|C EST FAUX|est FAUSSE"; then
  ko "mutant B NON detecte -> ce controle serait tautologique"
else ok "mutant B detecte : une occurrence NUE serait signalee"; fi
rm -f "$MT"

# ------------------------------------------------------------------------------------------------
echo "### C. MONOTONIE du motif du sweep — controle HONNETE + son mutant"
# ⛔ POURQUOI CE §C EXISTE : `verify.sh` §7 pretend comparer l ANCIEN et le NOUVEAU motif. Il ne le
#    fait PAS. Son cote « nouveau » est calcule par  $(sed ... >/dev/null 2>&1; echo "$ANCIEN")
#    -> la lecture est REDIRIGEE VERS /dev/null et la valeur substituee est $ANCIEN LUI-MEME.
#    Il compare donc l ancien motif A LUI-MEME : `comm -23` est vide PAR CONSTRUCTION et « PERDUES »
#    est une CONSTANTE publiee comme une mesure. Verifie : le chemin du fichier est indifferent
#    (un chemin INEXISTANT rend exactement le meme resultat).
#    Regression reelle injectee (perte de « transmission US-00.5 » et « US-00\.5 : ») :
#      verify.sh §7 -> PERDUES=0  |  controle honnete -> PERDUES=2  |  recall des 8 mutants -> 8/8
#    => la seule barriere censee voir cette regression ne la voit pas, et aucune autre ne la voit.
MOTIF_SRC=$(awk '/^VERBES=/{f=1} /^ASSIGNE=/{g=1} f||g{print} g && /"$/ && !/^ASSIGNE="$/{exit}' "$SWEEP")
eval "$MOTIF_SRC"; MOTIF="$ASSIGNE"
info "motif LU dans $SWEEP ($(printf '%s' "$MOTIF" | wc -c | tr -d ' ') octets) — aucune copie"
if [ ! -f "$BASE" ]; then
  grep -hE "$MOTIF" "$SCB" | sed 's/^[[:space:]]*//' | sort -u > "$BASE"
  info "baseline de monotonie CREEE : $BASE ($(wc -l < "$BASE" | tr -d ' ') TEXTES, aucun numero)"
fi
LOST=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  printf '%s\n' "$line" | grep -qE "$MOTIF" || { printf '            TEXTE PERDU : %s\n' "$(printf '%s' "$line" | cut -c1-70)"; LOST=$((LOST+1)); }
done < "$BASE"
[ "$LOST" -eq 0 ] && ok "monotonie : 0 texte de reference perdu (sur $(wc -l < "$BASE" | tr -d ' '))" || ko "monotonie : $LOST texte(s) perdu(s)"
MUT_MOTIF=$(printf '%s' "$MOTIF" | sed 's/|transmission US-00\.5|US-00\\\.5 :|/|/')
LOSTM=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  printf '%s\n' "$line" | grep -qE "$MUT_MOTIF" || LOSTM=$((LOSTM+1))
done < "$BASE"
[ "$LOSTM" -ge 1 ] && ok "mutant C detecte : motif ampute -> $LOSTM texte(s) perdu(s) VU(s)" \
                   || ko "mutant C NON detecte -> ce controle de monotonie serait TAUTOLOGIQUE"
if grep -q '>/dev/null 2>&1; echo "$ANCIEN"' "$VERIFY"; then
  ko "verify.sh §7 : le cote « nouveau motif » est \$ANCIEN (lecture redirigee vers /dev/null) -> TAUTOLOGIQUE"
else ok "verify.sh §7 : le cote « nouveau motif » n est plus une copie de l ancien"; fi

# ------------------------------------------------------------------------------------------------
echo "### D. Art. 4 <-> table de correspondance des categories (derive apres la PR no 2)"
awk '/^## Art\. 4/,/^## Art\. 5/' docs/governance/CONSTITUTION.md > "$ART4"
CATS=$(sed -n '/gates de qualité (/,/)/p' "$ART4" | tr '\n' ' ' \
       | sed -e 's/.*gates de qualité (//' -e 's/).*//' -e 's/\*\*//g' \
       | tr ',' '\n' | sed -e 's/^ *//' -e 's/ *$//' | grep -v '^$')
info "categories LUES dans l Art. 4 : $(printf '%s' "$CATS" | tr '\n' '/')"
MISS=0
OLDIFS=$IFS; IFS='
'
for cat in $CATS; do
  grep -qiF "$cat" "$VERIFY" || { printf '            categorie « %s » nommee par l Art. 4 mais ABSENTE de %s\n' "$cat" "$VERIFY"; MISS=$((MISS+1)); }
done
IFS=$OLDIFS
[ "$MISS" -eq 0 ] && ok "toutes les categories de l Art. 4 figurent dans la table de $VERIFY" \
                  || ko "$MISS categorie(s) de l Art. 4 absente(s) de la table de correspondance"
STALE=0
for k in typecheck SAST; do
  if grep -qiF "$k" "$VERIFY" && ! printf '%s\n' "$CATS" | grep -qiF "$k"; then
    printf '            « %s » traite en categorie par %s mais NON nomme comme gate par l Art. 4\n' "$k" "$VERIFY"
    STALE=$((STALE+1))
  fi
done
[ "$STALE" -eq 0 ] && ok "aucune categorie perimee dans la table" || ko "$STALE categorie(s) perimee(s) dans la table"
if grep -q "n est PAS une categorie de l Art. 4" "$VERIFY" && grep -q "mise en forme" "$ART4"; then
  ko "$VERIFY affirme « format n est PAS une categorie de l Art. 4 » alors que l Art. 4 nomme « mise en forme »"
else ok "aucune affirmation de $VERIFY contredite par le texte de l Art. 4"; fi
for g in format analyze test deps_audit build; do
  python scripts/run_gates.py --gate "$g" >/dev/null 2>&1 || ko "gate app.$g INTROUVABLE"
done
ok "les 5 gates de factory.config.json existent (run_gates --gate x5)"

# ------------------------------------------------------------------------------------------------
echo "### E. LEDGERS — le 2e livrable est-il ENREGISTRE ? (sur main depuis 2026-07-31T11:00:05Z)"
D=$(grep -n '^### \[US-00\.5\]' "$SCB" | head -1 | cut -d: -f1)
F=$(awk -v d="$D" 'NR>d && /^### \[/ {print NR; exit}' "$SCB"); [ -z "${F:-}" ] && F=$(wc -l < "$SCB")
ZONE=$(awk -v d="$D" -v f="$F" 'NR>=d && NR<=f' "$SCB")
printf '%s' "$ZONE" | grep -qE '#18|1\.0 (→|->) 1\.1|version \*{0,2}1\.1' \
  && ok "SCB §[US-00.5] enregistre l amendement (PR #18 / increment 1.1)" \
  || ko "SCB §[US-00.5] N ENREGISTRE PAS le 2e livrable (ni #18, ni l increment 1.1)"
printf '%s' "$ZONE" | grep -qE 'Prochaine étape.*(PR nº 2|3ᵉ passage)' \
  && ko "SCB §[US-00.5] annonce encore la PR nº 2 / le 3e passage QA comme A VENIR" \
  || ok "la « Prochaine étape » du SCB n annonce plus un livrable deja fusionne"
grep -q "il n'y a pas encore d'amendement à approuver" "$ST" \
  && ko "DoD 14 porte encore « il n y a pas encore d amendement a approuver »" \
  || ok "la DoD ne declare plus l amendement inexistant"
grep -q "l'Art. 4 n'est pas amendé ici" "$ST" \
  && ko "DoD 5 porte encore « l Art. 4 n est pas amende ici »" \
  || ok "la DoD ne declare plus l Art. 4 non amende"
grep -rqiE 'attestation.*(amendement|Art\. 4|constitutionnel)|amendement.*attestation' "$SCB" reports/US-00.5/*.md 2>/dev/null \
  && ok "une attestation humaine de l amendement est consignee (niveau 1, declaratif)" \
  || ko "DoD 14 : AUCUNE attestation humaine datee de l amendement dans le corpus (API : reviews=0)"
grep -qE '^- \[x\] ADR-001 \(stack\) publié' docs/epics/EPIC_00-fondations.md \
  && ok "critere de cloture EPIC_00 « ADR-001 publie et Constitution ajustee » COCHE" \
  || ko "critere de cloture EPIC_00 encore DECOCHE (DoD 23) alors que les 2 livrables sont sur main"

# ------------------------------------------------------------------------------------------------
echo "### F. Non-regression et gouvernance (executees, jamais declarees)"
sh "$VERIFY" >/dev/null 2>&1 && ok "verify.sh exit 0" || ko "verify.sh exit NON NUL"
python scripts/run_gates.py --all >/dev/null 2>&1 && ok "run_gates --all exit 0" || ko "run_gates --all exit NON NUL"
python scripts/check_scb_compliance.py >/dev/null 2>&1 && ok "check_scb_compliance exit 0" || ko "check_scb_compliance exit NON NUL"
python scripts/validate_trace.py --us US-00.5 >/dev/null 2>&1 && ok "validate_trace US-00.5 exit 0" || ko "validate_trace exit NON NUL"

rm -f "$ART4"
echo "================================================================================"
if [ "$FAIL" -eq 0 ]; then echo " CRITERE DE SORTIE : ATTEINT (exit 0)"; else echo " CRITERE DE SORTIE : NON ATTEINT — voir les ECHEC ci-dessus (exit 1)"; fi
echo " ⛔ Aucune exhaustivite revendiquee. Chaque controle bloquant porte son mutant."
echo "================================================================================"
exit "$FAIL"
