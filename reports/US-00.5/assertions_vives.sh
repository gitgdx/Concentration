#!/bin/sh
# ################################################################################################
# ⛔⛔  DETECTEUR RETIRE LE 2026-07-31 — IL BLANCHISSAIT.  NE PAS S EN SERVIR COMME GATE.  ⛔⛔
# ################################################################################################
#
# CE QUE CE SCRIPT FAISAIT, ET POURQUOI C EST PIRE QU UN ANGLE MORT
# -----------------------------------------------------------------
# Ecrit par @Architect le 2026-07-31 pour detecter la classe « assertion chiffree ecrite a la main ».
# Il rendait « 0 residu / exit 0 » — et c etait FAUX. Son filtre d exclusion etait :
#
#     grep -viE 'CAPTURE DU|PERIME|PÉRIMÉ|valeur retiree'
#
# Or l assertion fautive qui subsistait etait precisement :
#
#     $ grep -c "PÉRIMÉ-2026-07-28" STORY_CERTIFICATION_BOARD.md -> 2      (la commande rend 5)
#
# Le filtre matchait « PÉRIMÉ » DANS LA COMMANDE ELLE-MEME et masquait donc la ligne. La QA l a
# qualifie exactement : « ce n est pas un angle mort, c est un BLANCHIMENT » — le piege que ce projet
# documente depuis trois jours (« un grep de motifs matche la documentation des motifs »), retourne
# en FAUX NEGATIF et deplace du rapport vers L INSTRUMENT.
# Recall mesure de ce script : 2 formes sur 8. Il ratait « => N », « : N », « -> N <texte> », les
# tableaux — ET LE CAS REEL.
#
# C etait la SIXIEME manifestation en trois jours de ma classe de defaut, et la premiere DANS UN
# OUTIL DE CONTROLE. Un instrument qui se trompe en silence est plus nuisible que pas d instrument.
#
# POURQUOI IL EST RETIRE ET NON REPARE
# ------------------------------------
# La QA a livre `reports/US-00.5/qa_detecteur_v2.sh`, qui fait le meme travail correctement et porte
# son AUTOTEST DE MUTATION (8/8) — un vert non falsifiable y est interdit par construction.
# Maintenir deux detecteurs dont l un blanchit, c est garder un piege pour le prochain lecteur.
# ⛔ Le fichier n est pas SUPPRIME : sa trace documente la sixieme manifestation. Il est DESARME.
#
# GATE AUTORITAIRE  : sh reports/US-00.5/qa_detecteur_v2.sh   (critere de test no 20)
# VALEURS VIVES     : sh reports/US-00.5/verify.sh            (critere de test no 19)
# ################################################################################################
echo "RETIRE — ce detecteur blanchissait (voir l en-tete). Utiliser :"
echo "  sh reports/US-00.5/qa_detecteur_v2.sh   (gate autoritaire, autotest 8/8)"
echo "  sh reports/US-00.5/verify.sh            (valeurs vives)"
exit 2
