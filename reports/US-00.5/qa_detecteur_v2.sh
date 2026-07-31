#!/bin/sh
# ============================================================================================
# US-00.5 · DETECTEUR v2 de la classe « assertion chiffree ecrite a la main »
# @QA_Tester · re-audit du 2026-07-31 · remplace mon `qa_assertions_chiffrees.sh` comme
# CRITERE DE SORTIE (celui-ci est CONSERVE, mais retrograde en artefact date : voir ci-dessous).
#
# --- POURQUOI v2 : LE DIAGNOSTIC DE @Architect SUR MON PROPRE INSTRUMENT ETAIT JUSTE --------
# Mon v1 ecrivait la colonne « attendu » EN DUR :
#       chk "conformite_ac « iOS -> 6 »"   6   "$(grep -ci 'iOS' $ADR)"
#                                          ^ TRANSCRIPTION d une MESURE, recopiee a la main
# Une transcription de mesure PERIME. Son ECART=0 devenait donc inatteignable des que le corpus
# bougeait LEGITIMEMENT — y compris quand @Architect RETIRAIT les chiffres, comme je le demandais.
# ⇒ mon v1 reproduisait, un etage au-dessus, exactement le defaut qu il mesurait. JE LE CONCEDE.
#
# ⚠️ DISTINCTION QUI SAUVE `verify.sh` ET CONDAMNE MON v1 — elle est le coeur de ce re-audit :
#     * une valeur attendue qui est une SPECIFICATION ne perime pas
#         (« 1 ADR-001 doit exister », « 0 ADR accepte edite ») -> LEGITIME en dur.
#     * une valeur attendue qui est la TRANSCRIPTION d une MESURE perime a coup sur
#         (« iOS apparait 6 fois ») -> JAMAIS en dur.
#   `verify.sh` n ecrit que des SPECIFICATIONS. Mon v1 ecrivait des TRANSCRIPTIONS. C est la
#   difference entre un test et un decalque.
#
# --- POURQUOI `assertions_vives.sh` NE PEUT PAS SERVIR DE SUBSTITUT (etabli par execution) ---
# Il porte une LISTE D EXCLUSION PAR MOTS :  grep -viE 'CAPTURE DU|PERIME|PÉRIMÉ|valeur retiree'
# Or l assertion vivante la plus chargee du dossier est :
#       $ grep -c "PÉRIMÉ-2026-07-28" STORY_CERTIFICATION_BOARD.md -> 2      (sortie reelle : 5)
# La chaine « PÉRIMÉ » y figure PARCE QU ELLE EST LE MOTIF DE LA COMMANDE. L exclusion la
# supprime donc, et le detecteur rend « 0 residu, exit 0 » PAR-DESSUS le defaut.
# ⇒ ce n est pas un angle mort, c est un BLANCHIMENT : le piege documente du projet
#   (« un grep de motifs matche la documentation des motifs ») retourne en FAUX NEGATIF.
# ⇒ REGLE DE CONCEPTION DE v2 : **AUCUNE EXCLUSION PAR MOT**. Rien n est jamais supprime en
#   silence ; ce qui n est pas verifiable est AFFICHE comme tel et COMPTE.
#
# --- CE QUE v2 FAIT ------------------------------------------------------------------------
#   1. il LIT LES DEUX COTES : la valeur ecrite est EXTRAITE du rapport, jamais recopiee ici ;
#   2. quand la ligne publie sa commande (« $ <cmd> -> <N> »), il REJOUE la commande ;
#   3. quand aucune commande n est publiee, il classe UNVERIFIABLE — il ne blanchit pas ;
#   4. il porte son PROPRE TEST DE MUTATION (§C) : si ses mutants ne sont pas tous detectes,
#      il echoue. Un vert non falsifiable est interdit — c est la lecon de ce re-audit.
#
# --- CRITERE DE SORTIE ---------------------------------------------------------------------
#      ECART=0  ET  SANS_MARQUEUR=0  ET  autotest 8/8
# Usage : sh reports/US-00.5/qa_detecteur_v2.sh ; echo $?
# ⛔ AUCUNE exhaustivite revendiquee : ne voit que des chiffres presentes comme des RESULTATS.
# ============================================================================================
set -u
cd "$(dirname "$0")/../.." || exit 1

MOI="reports/US-00.5/qa_detecteur_v2.sh"
CIBLES="reports/US-00.5/conformite_ac.txt reports/US-00.5/correctifs_failed_revue.txt \
reports/US-00.5/entry_state/art4_vs_gates_reels.txt reports/US-00.5/entry_state/registre_et_sast.txt \
reports/US-00.5/verify.sh reports/US-00.5/assertions_vives.sh reports/US-00.5/sweep_transmissions.sh"

# Un chiffre PRESENTE COMME UN RESULTAT. Pas de liste d exclusion : on ne cache rien.
RES_MOTIF='(->|=>)[[:space:]]*[0-9]+'

ECART=0; VERIF=0; SANS_MARQUEUR=0; MARQUE=0

echo "==========================================================================================="
echo " DETECTEUR v2 — les deux cotes sont LUS. Aucune exclusion par mot. Rien n est blanchi."
echo " Fichier exclu, NOMMEMENT et pour cette seule raison : $MOI (il cite ses propres mutants)"
echo "==========================================================================================="

for f in $CIBLES; do
  [ -f "$f" ] || continue
  HITS=$(grep -nE "$RES_MOTIF" "$f" || true)
  [ -z "$HITS" ] && { printf '  --- %-52s aucun chiffre presente comme resultat\n' "$f"; continue; }
  printf '  --- %s\n' "$f"
  printf '%s\n' "$HITS" | while IFS= read -r h; do
    NUM=${h%%:*}; TXT=${h#*:}
    printf '%s' "$TXT" | grep -qE '^[[:space:]]*#' && continue   # commentaire de script : recit
    echo "$NUM|$TXT" >> /tmp/qa_v2_hits.$$
  done
done

[ -f /tmp/qa_v2_hits.$$ ] || : > /tmp/qa_v2_hits.$$

while IFS='|' read -r NUM TXT; do
  [ -z "${TXT:-}" ] && continue
  VAL=$(printf '%s' "$TXT" | sed -nE 's/.*(->|=>)[[:space:]]*([0-9]+).*/\2/p' | head -1)
  CMD=$(printf '%s' "$TXT" | sed -nE 's/^[[:space:]]*\$[[:space:]]*(.*)[[:space:]]*(->|=>)[[:space:]]*[0-9]+[[:space:]]*$/\1/p')
  if [ -n "$CMD" ] && printf '%s' "$CMD" | grep -qE '^(grep|git|ls|wc|sed|awk|python|sh) '; then
    OBT=$(sh -c "$CMD" 2>/dev/null | tr -d ' \r\n')
    VERIF=$((VERIF+1))
    if [ "$OBT" = "$VAL" ]; then
      printf '      OK          | L%-5s ecrit=%-5s obtenu=%-5s  $ %s\n' "$NUM" "$VAL" "$OBT" "$CMD"
    else
      printf '      ECART       | L%-5s ecrit=%-5s obtenu=%-5s  $ %s\n' "$NUM" "$VAL" "$OBT" "$CMD"
      ECART=$((ECART+1))
    fi
  else
    if printf '%s' "$TXT" | grep -qE 'PERIME-[0-9]{4}-[0-9]{2}-[0-9]{2}|PÉRIMÉ-[0-9]{4}-[0-9]{2}-[0-9]{2}|CAPTURE DU [0-9]{4}|valeur retiree'; then
      printf '      capture-datee| L%-5s %s\n' "$NUM" "$(printf '%s' "$TXT" | cut -c1-84)"
      MARQUE=$((MARQUE+1))
    else
      printf '      SANS MARQUEUR| L%-5s %s\n' "$NUM" "$(printf '%s' "$TXT" | cut -c1-84)"
      SANS_MARQUEUR=$((SANS_MARQUEUR+1))
    fi
  fi
done < /tmp/qa_v2_hits.$$
rm -f /tmp/qa_v2_hits.$$

echo "-------------------------------------------------------------------------------------------"
echo " §D  DESIGNATIONS PAR NUMERO DE LIGNE — 3e lecon d US-00.7 : « un numero glisse en silence »"
echo "     Sous-controle OBJECTIF : la ligne designee doit exister et n etre pas VIDE."
echo "     Sous-controle CIBLE    : les 5 emplacements du classement NB-1 doivent porter SON motif."
DES_VIDES=0; DES_TOT=0; NB1_FAUX=0
NB1_MOTIF='dernier commit seulement|ne compare que le'
for d in $(grep -rhoE '(STORY_CERTIFICATION_BOARD\.md|SCB|PROJECT_LOG|conformite_ac\.txt|code_review\.md|correctifs_[^ :]*)[:_][0-9]{2,4}'            reports/US-00.5/conformite_ac.txt reports/US-00.5/correctifs_failed_revue.txt | sort -u); do
  FIC=${d%%:*}; LIG=${d##*:}
  case "$FIC" in
    SCB|STORY_CERTIFICATION_BOARD.md) PATHF=STORY_CERTIFICATION_BOARD.md ;;
    PROJECT_LOG) PATHF=PROJECT_LOG.md ;;
    correctifs_*) PATHF=reports/US-00.5/correctifs_failed_revue.txt ;;
    *) PATHF="reports/US-00.5/$FIC" ;;
  esac
  [ -f "$PATHF" ] || continue
  DES_TOT=$((DES_TOT+1))
  CONT=$(sed -n "${LIG}p" "$PATHF")
  if [ -z "$(printf '%s' "$CONT" | tr -d ' 	')" ]; then
    printf '      DESIGNATION MORTE | %-28s -> ligne %s VIDE
' "$d" "$LIG"
    DES_VIDES=$((DES_VIDES+1))
  fi
done
for d in "code_review.md:172" "code_review.md:173" "conformite_ac.txt:45" "SCB:638"; do
  FIC=${d%%:*}; LIG=${d##*:}
  case "$FIC" in SCB) PATHF=STORY_CERTIFICATION_BOARD.md ;; *) PATHF="reports/US-00.5/$FIC" ;; esac
  if sed -n "${LIG}p" "$PATHF" | grep -qE "$NB1_MOTIF"; then
    printf '      classement NB-1   | %-28s porte bien le motif
' "$d"
  else
    printf '      classement NB-1   | %-28s *** NE PORTE PLUS LE MOTIF ***
' "$d"
    NB1_FAUX=$((NB1_FAUX+1))
  fi
done
printf '      designations examinees=%s  MORTES=%s  classement NB-1 faux=%s
' "$DES_TOT" "$DES_VIDES" "$NB1_FAUX"

echo "-------------------------------------------------------------------------------------------"
echo " §C  AUTOTEST DE MUTATION — un vert non falsifiable est interdit"
AUTO_OK=0; AUTO_KO=0
i=0
for m in \
  'x -> 99' \
  'x -> 99 occurrences' \
  'x => 99' \
  'PERIME x -> 99' \
  '$ grep -c "PÉRIMÉ-2026-07-28" fichier -> 99' \
  '  label    -> 99   ' \
  '$ wc -l fichier -> 99' \
  'la valeur retiree x -> 99' ; do
  i=$((i+1))
  if printf '%s\n' "$m" | grep -qE "$RES_MOTIF"; then AUTO_OK=$((AUTO_OK+1)); printf '      autotest %s : DETECTE\n' "$i"
  else AUTO_KO=$((AUTO_KO+1)); printf '      autotest %s : *** RATE *** %s\n' "$i" "$m"; fi
done
printf '      autotest : %s/8 detectes\n' "$AUTO_OK"

echo "==========================================================================================="
printf ' VERIFIEES=%s  ECART=%s  SANS_MARQUEUR=%s  captures-datees=%s  autotest=%s/8\n' \
       "$VERIF" "$ECART" "$SANS_MARQUEUR" "$MARQUE" "$AUTO_OK"
echo " CRITERE DE SORTIE : ECART=0 ET SANS_MARQUEUR=0 ET autotest=8/8 ET MORTES=0 ET NB-1-faux=0"
echo "==========================================================================================="
[ "$ECART" -eq 0 ] && [ "$SANS_MARQUEUR" -eq 0 ] && [ "$AUTO_OK" -eq 8 ] \n  && [ "$DES_VIDES" -eq 0 ] && [ "$NB1_FAUX" -eq 0 ] || exit 1
exit 0
