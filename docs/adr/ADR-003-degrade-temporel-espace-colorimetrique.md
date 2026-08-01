# ADR-003 : Dégradé temporel orange → bleu — espace colorimétrique et mapping de progression

- **Date** : 2026-08-01
- **Statut** : Accepté
- **US associée** : US-01.1 (Affichage Hub & grille d'échéances)

## Contexte

La couleur de fond d'une tuile est **la seule information ambiante** du produit : elle exprime la
**proximité du prochain changement de nombre** — `p = 0` → **orange**, `p = 1` → **bleu**, en
**interpolation continue** *(RF-04, AC-5)*. Trois contraintes la cadrent, et elles se contredisent
partiellement :

1. **Continuité perceptuelle** : le PRD demande un **dégradé continu**, pas des paliers. AC-5 le tranche
   déjà en faveur du continu *(les 4 paliers de la maquette Stitch sont un artefact de maquettage)*.
2. **⛔ Aucune couleur d'urgence — pas de rouge** *(AC-5 « Erreur », RNF-03)*.
3. **Lisibilité WCAG AA sur TOUTE la plage** *(RNF-06, AC-8 « Limite »)*, alors que le fond varie
   continûment sous un texte qui, lui, doit rester lisible.

Flutter ne fournit **aucun espace perceptuel** : `Color.lerp` interpole en **sRGB**, ce qui fait passer
orange → bleu par des **médians ternes et assombris**, et rend le dégradé visuellement non uniforme.

⚠️ **Piège majeur, vérifié sur les valeurs de la maquette** : en coordonnées **polaires** (OKLCH), la
teinte de l'orange est autour de **~60°** et celle du bleu autour de **~260°**. L'écart direct vaut donc
~200°, si bien que **l'arc le plus COURT (~160°) passe par 0° — c'est-à-dire par le ROUGE**. Une
interpolation de teinte « au plus court », qui est le réglage par défaut de la plupart des bibliothèques,
**violerait donc frontalement l'interdit du rouge**.

## Décision

**1 · L'interpolation se fait en OKLab, en coordonnées CARTÉSIENNES `(L, a, b)`** — même espace
perceptuel qu'OKLCH, **autre système de coordonnées**. `backgroundFor(p)` interpole **linéairement `L`, `a`
et `b`** entre les deux extrémités, puis reconvertit vers sRGB.
**Motif décisif** : la forme cartésienne **n'a pas de notion de sens de rotation**, donc la question
« court ou long arc » **ne se pose pas** et ⛔ **le chemin ne peut pas traverser le rouge par accident**.
La forme polaire obligerait à imposer explicitement le sens croissant *(orange → jaune → vert → cyan →
bleu)* et **un seul réglage par défaut oublié ferait apparaître du rouge** — un défaut *silencieux*, de la
famille que ce projet paie le plus cher.
📌 **Écart explicite avec la lettre du PRD**, qui écrit « OKLCH » : c'est le **même espace**, exprimé
autrement. **Nommé ici pour qu'aucun relecteur n'ait à le déduire.**

**2 · Conversions implémentées en Dart pur** *(sRGB ⇄ linéaire ⇄ OKLab)*, dans `core/color/`, sans
dépendance, sans `BuildContext`, **fonctions déterministes**. ⛔ **Aucune dépendance ajoutée** — le projet
n'a **ni SAST ni scanner de CVE**.

**3 · Les EXTRÉMITÉS ne sont PAS décidées ici.** Cet ADR fixe l'**espace**, le **mapping** et le
**contrat** ; l'orange et le bleu de référence sont des **tokens de design**, autorité **@UXDesigner**
*(`DESIGN_SYSTEM.md`)* — c'est là que se tranche `#3D7DD8` *(PRD)* contre `#005ab3` *(maquette)*.
⇒ `temporal_gradient.dart` **lit les tokens**, il n'en contient aucun.

**4 · Hors gamut : réduction de CHROMA, jamais écrêtage par canal.** Si une couleur interpolée sort du
gamut sRGB, on **réduit la chroma** *(rapprochement de `a` et `b` de l'origine)* jusqu'au retour dans le
gamut, à `L` **constante**. Un écrêtage canal par canal déplacerait la **luminance** et casserait la
garantie de contraste du point 5.

**5 · `foregroundFor(p)` CHOISIT parmi les tokens de texte, il n'en invente pas** : il calcule le
**rapport de contraste WCAG** *(luminance relative)* de chaque couleur de texte candidate contre le fond
`backgroundFor(p)`, et retient la meilleure. **Seuils exigés** : **≥ 3:1** pour le **nombre** *(texte
large)*, **≥ 4,5:1** pour la **description** *(texte normal)*.
⛔ **Si aucune candidate n'atteint le seuil, le moteur ÉCHOUE bruyamment** — il ne renvoie pas
silencieusement « la moins mauvaise ». Un dégradé illisible est un **défaut de tokens**, et il doit se
voir au test, pas à l'usage.

**6 · Contrats testables, adossés au dégradé et non à une capture** : `p = 0` rend **exactement**
l'orange de référence · `p = 1` **exactement** le bleu · `L` est **monotone** en `p` · ⛔ **aucun `p ∈ [0;1]`
ne produit une couleur de teinte rouge** · le contraste tient sur un **échantillonnage** de `p`.

## Alternatives considérées

- **`Color.lerp` (sRGB)**. **Écarté** : médians ternes et assombris, dégradé perceptuellement non
  uniforme — le contraire de l'effet recherché, pour un seul appel de moins.
- **OKLCH polaire avec sens de teinte imposé** *(croissant : orange → jaune → vert → cyan → bleu)*.
  **Écarté, mais c'est l'alternative sérieuse** : elle **préserve la chroma** sur tout le trajet, donc un
  dégradé plus vif. ⛔ Rejetée parce que sa **correction dépend d'un réglage** *(le sens)* dont la valeur
  par défaut est *fausse* et le défaut **silencieux** — le rouge apparaîtrait sans qu'aucun test évident ne
  le dise. **Si @UXDesigner veut ce trajet vif, cela exige un NOUVEL ADR** qui remplacera celui-ci et
  **imposera l'assertion « aucune teinte rouge » comme test bloquant**.
- **HSL / HSV**. **Écarté** : non perceptuels — la luminance perçue varie brutalement à teinte constante,
  ce qui rend la garantie de contraste du point 5 impossible à tenir proprement.
- **Une bibliothèque de couleur**. **Écarté** : ~60 lignes de conversion pures et testables contre une
  **dépendance non scannée**.
- **Les 4 paliers de la maquette**. **Écarté** : AC-5 exige le **continu** ; la maquette est une
  **référence**, le PRD fait foi *(inversion de sens incluse — voir §Risques du Story File)*.

## Conséquences

**Positif** — un dégradé perceptuellement régulier, **impossible à faire passer par le rouge par
construction** *(et non par vigilance)*, une frontière nette entre **décision d'architecture**
*(espace, mapping, contrat)* et **décision de design** *(les deux extrémités)*, et un moteur **pur**
couvrable à ~100 % qui aide à tenir le cliquet.

**Négatif, et visible à l'œil**

- ⚠️ **Le milieu du dégradé sera DÉSATURÉ.** La droite orange → bleu en `(a, b)` passe **près du neutre** :
  vers `p ≈ 0,5`, la tuile tirera vers un gris-beige plutôt que vers une couleur vive. **C'est le prix
  assumé** de l'impossibilité structurelle de croiser le rouge. Si l'effet déplaît, la sortie est le
  **nouvel ADR** décrit ci-dessus — ⛔ **pas un « petit ajustement » dans le code**.
- ⚠️ **La réduction de chroma peut faire diverger légèrement une couleur de la valeur théorique** près des
  extrémités si un token est lui-même limite en gamut. Les **extrémités exactes restent garanties**
  *(elles sont des couleurs sRGB par construction)*, mais l'assertion de monotonicité doit porter sur `L`,
  **pas** sur la chroma.
- ⚠️ **L'échec bruyant du point 5 est un choix de rigueur qui a un coût** : un token de texte mal choisi
  **casse le build** au lieu de dégrader l'affichage. **Assumé** — c'est exactement la posture du projet
  *(un vert non fondé est pire qu'un rouge)*.
- ⛔ **Cet ADR ne dit RIEN de l'aspect final** : sans les tokens de @UXDesigner, `temporal_gradient.dart`
  **ne peut pas être écrit**. Il est **bloquant amont** pour T1 et T5.

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables**
une fois acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien
(ne jamais éditer un ADR Accepté).
