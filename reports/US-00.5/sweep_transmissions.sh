#!/bin/sh
# US-00.5 · CRITERE DE SORTIE DU MARQUAGE — script EXECUTABLE, jamais recopie a la main.
#
# Lecon d'US-00.7, payee cinq fois : « un critere de sortie se publie comme un script executable ».
# Lecon du FAILED de revue d'US-00.5 : « le marquage a suivi DEUX RENVOIS au lieu de couvrir
# l'EXTENSION du defaut » — j'avais marque 2 lignes sur 5, dont AUCUNE n'etait celle que le Story
# File cite mot pour mot.
#
# DEFAUT dont on cherche l'extension : « le SCB assigne encore a US-00.5 une charge ETEINTE ».
#
# ATTENDU : sortie VIDE, A LA SEULE EXCEPTION NOMMEE ci-dessous.
#
#   *** EXCEPTION UNIQUE ET JUSTIFIEE, designee par son TEXTE et jamais par un numero de ligne ***
#   La ligne portant « US-00.5 GAGNE un item » — l'Art. 4 nomme ci.yml alors que le 4e contexte
#   requis vient de branch-naming.yml (arbitrage @PO du 2026-07-28).
#   (3e lecon d'US-00.7 : un renvoi par numero de ligne GLISSE EN SILENCE. Une premiere version de
#   ce commentaire disait « SCB:1036 » ; le numero avait deja bouge de 8 lignes en une seule
#   session de corrections. Designer par le TEXTE, toujours.)
#   -> Cette charge est VIVANTE et VRAIE : c'est l'item d'INCOMPLETUDE de l'Enforcement, encore DU,
#      et il part en PR no 2. La MARQUER PERIME serait FAUX.
#   -> Le script ne la filtre PAS : elle doit RESTER VISIBLE en sortie, et c'est le lecteur qui
#      constate qu'elle est la seule. Un filtre silencieux serait exactement le defaut que ce
#      script existe pour empecher (cf. la QA d'US-00.7 : un filtre oublie dans la commande publiee
#      avait DISSIMULE la pire survivance du corpus).
#
# Usage : sh reports/US-00.5/sweep_transmissions.sh
set -u
cd "$(dirname "$0")/../.." || exit 1

SCB=STORY_CERTIFICATION_BOARD.md

# Motifs d'ASSIGNATION DE CHARGE a US-00.5 (verbes de transmission), et non de simple mention.
# On exclut deliberement les CONSTATS DE REDUCTION (« le perimetre d'US-00.5 se reduit »,
# « restent US-00.5 et US-00.6 ») : ils sont VRAIS et ne transmettent aucune charge.
ASSIGNE="relève de \*\*US-00.5|transmis à \*\*US-00.5|PR dédiée en US-00.5|\
transmission US-00.5|US-00.5 :|US-00.5 GAGNE"

grep -nE "$ASSIGNE" "$SCB" \
  | grep -v "PÉRIMÉ-2026-07-28" \
  | grep -v "se réduit" \
  | grep -v "réduit (" \
  | sed "s|^|$SCB:|"

rc=$?
echo "=== FIN — toute ligne ci-dessus est un DEFAUT NON COUVERT ==="
exit 0
