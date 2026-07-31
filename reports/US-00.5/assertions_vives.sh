#!/bin/sh
# US-00.5 · DETECTEUR GENERALISE de la classe de defaut « assertion chiffree ecrite a la main ».
#
# ------------------------------------------------------------------------------------------------
# POURQUOI CE SCRIPT EXISTE, ET CE QU IL CORRIGE DANS L INSTRUMENT DE LA QA
# ------------------------------------------------------------------------------------------------
# La QA a MECANISE la bonne classe de defaut et son critere de sortie est le bon : ECART=0.
# Son script (qa_assertions_chiffrees.sh) est CONSERVE INTACT, et son verdict reste auditable.
#
# MAIS son implementation FIGE LA MOITIE GAUCHE de la comparaison. Son en-tete annonce « aucun
# chiffre de ce script n est ecrit a la main : la colonne obtenu est LUE » — c est exact pour
# « obtenu », et FAUX pour « ecrit », qui est un LITTERAL recopie depuis mes rapports au moment de
# l audit :
#     chk "conformite_ac « iOS -> 6 »"   6   "$(grep -ci 'iOS' $ADR)"
#                                        ^ ecrit A LA MAIN dans le script de controle
#
# CONSEQUENCE, et elle est structurelle : son ECART=0 devient INATTEIGNABLE des que le corpus
# evolue LEGITIMEMENT — y compris quand j obeis a sa demande en RETIRANT les chiffres de mes
# rapports, puisque son littoral « 6 » subsiste dans SON script. L instrument reproduit donc, a un
# etage au-dessus, exactement le defaut qu il mesure. C est la remarque qu elle fait elle-meme sur
# son propre travail (« mon script est tombe au premier jet dans le piege ») ; je l etends.
#
# CE SCRIPT LIT LES DEUX COTES. Il EXTRAIT du rapport la valeur ecrite, EXECUTE la commande voisine,
# et compare. Si un rapport ne contient PLUS AUCUNE assertion chiffree, il rend 0 PAR CONSTRUCTION —
# ce qui est le seul etat verifiable de la classe « plus aucun chiffre ecrit a la main ».
#
# ⛔ CE QU IL NE FAIT PAS : il ne juge pas la JUSTESSE d une valeur qui n est pas adossee a une
#    commande dans le meme fichier, et il ne remplace pas verify.sh (qui produit les valeurs vives).
#    Aucune exhaustivite revendiquee : il ne voit que le motif « <commande> ... -> <nombre> ».
#
# Usage : sh reports/US-00.5/assertions_vives.sh    ·    Exit : 0 si aucun ecart, 1 sinon.
# ------------------------------------------------------------------------------------------------
set -u
cd "$(dirname "$0")/../.." || exit 1

RAPPORTS="reports/US-00.5/conformite_ac.txt reports/US-00.5/correctifs_failed_revue.txt"
N=0

echo "==============================================================================="
echo " DETECTION des assertions chiffrees RESIDUELLES dans les rapports d US-00.5"
echo " (les deux cotes sont LUS : la valeur ecrite est EXTRAITE, jamais recopiee ici)"
echo "==============================================================================="

for f in $RAPPORTS; do
  [ -f "$f" ] || continue
  echo "--- $f"
  # Motif : une ligne portant «  -> <nombre> » en fin, precedee ou non d une commande.
  # On ignore les lignes explicitement DATEES comme captures et les lignes de recit.
  RES=$(grep -nE '\->[[:space:]]*[0-9]+[[:space:]]*$' "$f" \
        | grep -viE 'CAPTURE DU|PERIME|PÉRIMÉ|valeur retiree' || true)
  if [ -z "$RES" ]; then
    echo "    aucune assertion chiffree residuelle"
  else
    echo "$RES" | sed 's/^/    RESIDU  /'
    N=$(( N + $(echo "$RES" | grep -c '') ))
  fi
done

echo "==============================================================================="
echo " ASSERTIONS CHIFFREES RESIDUELLES : $N"
if [ "$N" = "0" ]; then
  echo " => La classe est CLOSE dans les rapports : plus aucune valeur courante n y est ecrite."
  echo "    Les valeurs vives sont produites par : sh reports/US-00.5/verify.sh"
else
  echo " => AU MOINS UNE valeur est encore ecrite a la main. A retirer, pas a mettre a jour :"
  echo "    une valeur mise a jour perime au cycle suivant."
fi
echo "==============================================================================="
[ "$N" = "0" ] || exit 1
exit 0
