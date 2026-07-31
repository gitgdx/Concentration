#!/bin/sh
# US-00.5 · CRITERE DE SORTIE DU MARQUAGE — script EXECUTABLE, jamais recopie a la main.
#
# Lecon d'US-00.7, payee cinq fois : « un critere de sortie se publie comme un script executable ».
# Lecon du FAILED de revue d'US-00.5 : « le marquage a suivi DEUX RENVOIS au lieu de couvrir
# l'EXTENSION du defaut » — j'avais marque 2 lignes sur 5, dont AUCUNE n'etait celle que le Story
# File cite mot pour mot.
#
# DEFAUT dont on cherche l'extension : « le SCB assigne encore a US-00.5 une charge ETEINTE ».
# ATTENDU : sortie VIDE, a la seule exception nommee ci-dessous.
#
#   *** EXCEPTION UNIQUE ET JUSTIFIEE, designee par son TEXTE et jamais par un numero de ligne ***
#   La ligne portant « US-00.5 GAGNE un item » — l'Art. 4 nomme ci.yml alors que le 4e contexte
#   requis vient de branch-naming.yml (arbitrage @PO du 2026-07-28).
#   -> Cette charge est VIVANTE et VRAIE : c'est l'item d'INCOMPLETUDE de l'Enforcement, encore DU,
#      et il part en PR no 2. La MARQUER PERIME serait FAUX.
#   -> Elle reste VISIBLE en sortie ; le script ne la filtre PAS. Un filtre silencieux est
#      exactement ce qui, chez la QA d'US-00.7, avait DISSIMULE la pire survivance du corpus.
#   (3e lecon d'US-00.7 : un renvoi par numero de ligne GLISSE EN SILENCE. Une premiere version de
#   ce commentaire designait la ligne par son numero ; il avait deja bouge quand je l'ecrivais, et
#   il a bouge deux fois de plus depuis. Designer par le TEXTE, toujours.)
#
# --- PERIMETRE, ET POURQUOI IL EST BORNE (rectifie le 2026-07-30, finding RB-1 du re-audit) ------
# Les deux premieres versions balayaient TOUT le SCB. Elles rendaient donc AUSSI les lignes de MA
# PROPRE PROSE qui CITENT le texte de l'exception pour la justifier — d'abord une, puis deux, et le
# compte augmentait A CHAQUE FOIS QUE J'ECRIVAIS SUR LE SUJET. C'est le piege deja documente du
# projet (« un grep de motifs matche la documentation des motifs »), ici en boucle : LE CONTROLE
# S'AUTO-ALIMENTAIT.
# BORNE SEMANTIQUE RETENUE, et elle n'est pas une commodite : une TRANSMISSION DE CHARGE VERS
# US-00.5 ne peut par construction exister que dans la section d'une AUTRE US. La section
# « ### [US-00.5] » est le visa D'US-00.5 ELLE-MEME : elle ne peut pas se transmettre une charge a
# elle-meme, elle ne fait que RENDRE COMPTE. Elle est donc exclue du perimetre.
# ⛔ CE QUE CETTE EXCLUSION N'AUTORISE PAS : elle ne dispense d'aucune exactitude dans la section
# US-00.5, qui reste couverte par les audits et par la QA. Elle borne le perimetre de CE controle,
# elle ne cree aucune zone franche.
#
# Usage : sh reports/US-00.5/sweep_transmissions.sh
set -u
cd "$(dirname "$0")/../.." || exit 1

SCB=STORY_CERTIFICATION_BOARD.md

# Bornes de la section « ### [US-00.5] » — calculees, jamais ecrites a la main.
DEB=$(grep -n '^### \[US-00\.5\]' "$SCB" | head -1 | cut -d: -f1)
if [ -n "${DEB:-}" ]; then
  FIN=$(awk -v d="$DEB" 'NR>d && /^### \[/ {print NR; exit}' "$SCB")
  [ -z "${FIN:-}" ] && FIN=$(wc -l < "$SCB")
  echo "# (section [US-00.5] exclue du perimetre : lignes $DEB a $FIN — bornes CALCULEES)"
else
  DEB=0; FIN=0
fi

# Motifs d'ASSIGNATION DE CHARGE a US-00.5 (verbes de transmission), et non de simple mention.
# On exclut deliberement les CONSTATS DE REDUCTION (« le perimetre d'US-00.5 se reduit ») : ils
# sont VRAIS et ne transmettent aucune charge.
#
# --- RECALL, rectifie le 2026-07-31 apres le FAILED de la QA ------------------------------------
# La QA a soumis la version precedente a un TEST DE MUTATION : 4 formulations de transmission
# injectees dans une copie du SCB, 3 NON DETECTEES, dont DEUX HORS de la zone exclue. Recall
# mesure : 8 lignes sur 25. Sa conclusion, et elle est juste : « on a debattu de la BORNE pendant
# que le trou etait dans le GREP » — la faiblesse etait le MOTIF, pas le PERIMETRE.
# Deux causes, toutes deux corrigees ici :
#   1. le motif etait une LISTE DE FORMULATIONS OBSERVEES, donc borne a ce qui existait deja ;
#   2. il etait DIRECTIONNEL (« US-00.5 … <verbe> »), donc aveugle a « incombe A US-00.5 », ou le
#      verbe PRECEDE la reference. Un motif a sens unique a un angle mort PAR CONSTRUCTION.
# ⛔ Ce qui n est PAS revendique : l exhaustivite. Un motif ne vaudra jamais mieux que sa liste de
#    verbes ; le test de mutation de verify.sh §7 en mesure le recall, il ne le garantit pas.
ASSIGNE="US-00\.5.*(tranchera|à traiter|incombe|reporté|amendement|transmis|relève|dédiée|GAGNE|transmission)|\
(tranchera|à traiter|incombe|reporté|transmis|relève|revient|dédiée|corriger) *(à|a|sur|en|de|par)? *\*{0,2}US-00\.5|\
(→|->) *\*{0,2}US-00\.5"

grep -nE "$ASSIGNE" "$SCB" \
  | grep -v "PÉRIMÉ-2026-07-28" \
  | grep -v "se réduit" \
  | grep -v "réduit (" \
  | awk -F: -v d="$DEB" -v f="$FIN" '($1 < d || $1 > f)' \
  | sed "s|^|$SCB:|"

# (RB-5 du re-audit : un « rc=$? » figurait ici. Il etait MORT — il capturait le code du dernier
#  element du pipe, pas celui du grep, et n etait jamais lu. Retire : une variable inutile dans un
#  script de controle est exactement le genre de faux repere que ce projet traque.)
echo "=== FIN — toute ligne ci-dessus est a CLASSER (charge eteinte => DEFAUT ; charge vivante => OK) ==="
exit 0
