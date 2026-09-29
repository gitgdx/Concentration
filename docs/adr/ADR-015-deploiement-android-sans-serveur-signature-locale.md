# ADR-015 : « Déployé » pour une application sans serveur — preuve sur l'appareil, signature LOCALE, identité d'application protégée

- **Date** : 2026-09-29
- **Statut** : **Proposé** *(2026-09-29 — @Architect. ⛔ **Il ne peut PAS passer `Accepté` tant que
  les points A-3 et A-4 du Story File ne sont pas arbitrés** : ce texte contredit aujourd'hui la
  **lettre** de l'Art. 6 et de l'Art. 4 de la Constitution, §Conséquences.)*
- **US associée** : US-01.3 (Chaîne de déploiement mobile réelle — Android), EPIC_01, track FULL
- **Remplace** : **rien.** ⛔ Aucun ADR accepté n'est modifié. ADR-001 §4 et `STACK_PROFILE.md`
  §DevOps décrivaient une séquence *« Play Console / TestFlight »* : ce sont des **constats et
  prescriptions d'époque**, amendés **par encadré daté** là où ils vivent, ⛔ pas ici.

> ⚖️ **Ce que cet ADR NE décide PAS, parce que c'est déjà décidé ailleurs, en un seul exemplaire** :
> la **définition** de `🚀 DEPLOYED` est **AC-1** du [Story File d'US-01.3](../stories/US-01.3-chaine-deploiement-mobile.md)
> *(conjonction de six observations sur un même artefact)* — ⛔ **elle n'est pas recopiée ici**. Les
> arbitrages **H-1** *(Android seul)*, **H-2** *(canal `adb`, appareil de référence SM T580)*, **H-3**
> *(signature locale, CI non signée, aucun secret sur GitHub)* et les **verdicts** du gate *clarify*
> du 2026-09-29 *(leur compte se lit dans le Story File, ⛔ il n'est pas écrit ici)* sont **des entrées** de cet ADR, ⛔ **pas des décisions qu'il prend**. Cet ADR décide le
> **COMMENT** : où vit la preuve, quels mécanismes rendent chaque observation d'AC-1 **constatable par
> machine**, et quelles barrières empêchent les faux verts **déjà identifiés dans le dépôt**.

## Contexte

1. **Il n'y a ni serveur, ni store, ni second environnement.** La « production » est **un seul
   appareil** *(celui de l'humain)*, et le staging est **le même appareil** *(verdict Q2)*. Ce qui peut
   être distingué, donc vérifié, est **l'ARTEFACT** *(ses octets, son certificat, sa version)* et **la
   DÉCISION** *(validation humaine datée)*.
2. **Le stockage est local et unique** *(ADR-009 : document JSON sous `getApplicationDocumentsDirectory()`,
   lu dans `lib/features/echeances/data/document_store_io.dart`)*. Sur Android, ce répertoire appartient
   au **paquet** *(identifiant d'application)* ⇒ **désinstaller le paquet détruit la seule copie des
   échéances**.
3. **Trois faux verts sont DÉJÀ dans le dépôt ou l'outillage, et ils sont mesurés** *(2026-09-29)* :
   - **(F-1)** `android/app/build.gradle.kts`, type `release` : `signingConfig = signingConfigs.getByName("debug")`
     ⇒ un build de release **sans clé** réussit **en silence**, signé par la clé de débogage.
   - **(F-2) 🔴 L'outil Flutter DÉSINSTALLE l'application en cas d'échec d'installation.** Lu dans le
     SDK installé *(Flutter **3.44.7**, `packages/flutter_tools/lib/src/android/android_device.dart`,
     méthode `installApp`)* : si `_installApp` échoue et que l'application est déjà installée, il imprime
     `Uninstalling old version...`, appelle `uninstallApp`, puis réinstalle — **sans confirmation**. Or
     une installation **debug ou profil** *(clé de débogage)* par-dessus une **release** *(clé de release)*
     **échoue par construction** *(certificats différents)*. ⇒ ⛔ **un simple `flutter run` sur
     l'appareil du pratiquant, ou l'instrument RNF-02 actuel (`flutter run --profile`), détruirait toutes
     ses échéances** — exactement ce qu'AC-7 interdit, **par un outil et non par un geste**.
   - **(F-3)** Le contrôle de secrets **ne voit pas** deux des trois formes de secret de signature.
     **Mesuré** avec `gitleaks 8.30.1` et la configuration **du dépôt** sur des fixtures **FACTICES**
     *(mot de passe aléatoire jetable, keystore jetable de validité 1 jour, créés dans le **scratchpad de
     session**, ⛔ **jamais dans le dépôt**)* : keystore **binaire** `.jks` → **exit 0, aucune règle** ·
     `key.properties` à mot de passe **à forte entropie** → **exit 1** *(`generic-api-key`)* · mot de passe
     en dur dans un `.gradle.kts` à forte entropie → **exit 1** *(`generic-api-key`)* · ⚠️ **`key.properties`
     à mot de passe à FAIBLE entropie** *(forme « mot + année »)* → **exit 0, `no leaks found`**. ⇒ AC-4
     « Erreur » serait **vraie sans pouvoir échouer** pour un keystore et pour un mot de passe humain.
     ⚠️ Borne : la CI utilise `gitleaks/gitleaks-action@v2` *(version de moteur non épinglée, non lue)*.
4. **La rotation de clé ne sauve pas une clé perdue ou publiée sur cet appareil.** Le schéma de
   signature APK **v3** *(rotation)* est documenté à partir d'**Android 9 / API 28** ; l'appareil de
   référence est en **API 27**. ⚠️ **Fait de DOCUMENTATION, ⛔ non vérifié par exécution** — il n'y a
   rien à exécuter sur API 27 qui prouverait une absence. Conséquence retenue **dans les deux cas** :
   **aucune stratégie ne s'appuie sur la rotation**.

## Décision

### §1 — Identité de l'application : l'identifiant de RELEASE est protégé des modes de développement

- L'identifiant d'application de **release** est **`com.concentration.concentration`**, ⚖️ **DÉFINITIF**
  *(verdict humain Q15 du 2026-09-29)*. **Irréversible en pratique** : identifiant + clé = identité de
  l'application sur l'appareil ; le changer après la première release installerait **une autre
  application** à côté, l'ancienne gardant les échéances. Le commentaire `TODO: Specify your own unique
  Application ID` est **retiré en développement** *(tâche), ⛔ pas avant*.
- 🆕 **Les modes `debug` et `profile` reçoivent un SUFFIXE d'identifiant** *(`applicationIdSuffix`
  `.debug` et `.profile`)*. **Motif : F-2.** Un build de développement ou de mesure devient **un autre
  paquet**, avec **son propre stockage** ⇒ ni `flutter run`, ni `flutter install`, ni l'instrument RNF-02
  ne peuvent plus **toucher** le paquet du pratiquant, **quelle que soit** la discipline de l'opérateur.
  ⛔ **C'est une barrière par construction, pas une consigne.**
- ⛔ **L'outil Flutter n'installe JAMAIS l'artefact de release sur l'appareil de référence** :
  l'installation passe par **`adb install -r`** *(mise à jour, conserve les données)*, ⛔ **jamais `-d`**
  *(rétrogradation, AC-6 Erreur)*, ⛔ **jamais `uninstall`** — sauf l'**unique** étape nommée d'AC-7
  « Limite » *(remplacement de l'installation debug du 2026-08-21)*, qui exige une **confirmation humaine
  saisie** et est **consignée**. `adb install -r` en échec **échoue** : il ne désinstalle pas.

### §2 — Signature : deux modes NOMMÉS, ⛔ aucun repli *(verdict Q3)*

- Le mode est choisi par une **propriété Gradle explicite**, transmise par l'option **`-P`** de
  `flutter build` *(option `--android-project-arg`, abrégée `-P`, **lue** dans le SDK 3.44.7,
  `flutter_command.dart`)* :
  - **absente ⇒ mode « release signée »** *(le défaut est le mode SÛR)* : exige un fichier de propriétés
    de signature **présent**, portant ses **quatre** clés, et désignant un keystore **existant** et
    **situé HORS de l'arbre du dépôt**. **Tout manque lève une erreur de build qui NOMME la cause**, et
    ⛔ **aucun artefact n'est produit**. Un mot de passe faux fait échouer la tâche de signature d'AGP,
    qui le nomme.
  - **`-Pconcentration.signature=aucune` ⇒ mode « release NON signée »** : `signingConfig` nul, artefact
    **non installable**. ⛔ **Réservé à la CI** *(AC-5)* ; aucun outil de déploiement ne l'accepte.
- ⛔ **La ligne `signingConfigs.getByName("debug")` disparaît du type `release`.** Aucune troisième
  voie : ni « absence de clé ⇒ non signé » *(repli implicite, refusé Q3 (b))*, ni clé jetable en CI
  *(refusé Q3 (c))*.
- **Le certificat est vérifié SUR L'ARTEFACT**, indépendamment de la procédure *(AC-3 Limite)* :
  `apksigner verify --print-certs` ; refus si le certificat est celui de la clé de débogage
  *(empreinte du keystore de débogage local **et** DN `CN=Android Debug`, les deux)*.
- ⚠️ **Le fichier de propriétés vit dans `android/key.properties`, gitignoré** *(H-3, lettre de
  l'arbitrage)* ; le keystore vit **hors du dépôt**. ⛔ **Aucun agent ne lit, n'affiche ni ne transmet
  leur contenu** ; les outils n'en impriment **que la présence** et **l'empreinte publique** du
  certificat *(AC-4 Limite)*.

### §3 — Format et empreinte : un APK universel, empreinte de CE QUI EST INSTALLÉ *(verdict Q7)*

- **APK** *(non AAB — un AAB ne s'installe pas par `adb` et aucun store n'est visé)*, **universel**
  *(sans découpage par ABI : un seul fichier, une seule empreinte)*.
- **Empreinte d'artefact = SHA-256 du fichier APK.** ⚠️ **Hypothèse à MESURER à la première
  installation, ⛔ pas à supposer** : le `base.apk` relu sur l'appareil *(`pm path` puis récupération)*
  est **identique octet pour octet** au fichier installé. **Si elle est fausse**, l'observation ④
  d'AC-1 se replie sur **versionCode lu sur l'appareil + empreinte du certificat de l'APK relu**, et la
  preuve **le dit** — ⛔ jamais silencieusement.

### §4 — Version : un seul exemplaire, strictement croissante, reliée à un commit

- La version vit **dans `pubspec.yaml` seul** *(`version: x.y.z+N`, `N` = `versionCode`)*. Un
  incrément est **un commit** ⇒ l'arbre propre *(AC-2 Erreur)* garantit que le numéro **est** porté par
  le commit construit.
- **Le registre des déploiements** *(§5)* fait foi du « dernier numéro » : **toute installation sur
  l'appareil de référence**, staging comme production, **consomme** un numéro. Un artefact de numéro
  `≤` au maximum du registre est **refusé avant installation**.

### §5 — La preuve : un REGISTRE append-only, versionné, lu par machine

- **`docs/deploiement/registre.jsonl`** : une ligne par **constat** *(`build`, `staging`, `staging_echec`,
  `validation`, `production`, `refus`)*, portant commit, versionCode, empreinte d'APK, empreinte de
  certificat, appareil *(modèle, API, identifiant — §Conséquences, point A-2)*, versions de la chaîne
  d'outils, horodatage. **Preuves détaillées** *(journaux capturés, sorties d'outils)* sous
  `docs/deploiement/preuves/`. ⛔ **Il vit hors de `reports/US-XX/`** parce qu'**un déploiement vaut
  pour plusieurs US** *(verdict Q5)*.
- Un contrôle en CI *(job requis `governance`)* vérifie le registre : versionCode **strictement
  croissant** sur les installations · toute `production` a une `staging` réussie **de même empreinte**
  suivie d'une `validation` **datée entre les deux** · commit de production **ancêtre de `origin/main`**
  *(verdict Q16)* · **aucun motif de secret** dans le registre ni les preuves *(AC-4)*.
- ⚠️ **Borne** : « append-only » est **vérifiable** en CI *(toute ligne supprimée ou modifiée par rapport
  à la branche principale est un refus)* ; ⛔ il ne l'est **pas** contre une réécriture d'historique
  locale avant le premier push.

### §6 — Les verdicts ont QUATRE issues, patron de l'instrument RNF-02

Chaque outil de la chaîne rend **`0` conforme · `1` refus, condition nommée · `2` ne conclut pas ·
`3` défaut de l'instrument**. `2` couvre **outil `adb` introuvable** *(nommé comme tel, ⛔ jamais « liste
vide »)*, **aucun appareil**, **capture de journal vide** *(AC-8 Limite)*. **Plusieurs appareils sans
cible nommée** et **émulateur** sont des **refus** `1` *(AC-11 Limite)*. ⛔ **`adb` est résolu depuis le
SDK déclaré** *(`android/local.properties` → `sdk.dir`, sinon `ANDROID_HOME`)*, ⛔ **pas depuis le
`PATH`** *(il en est absent sur cette machine au 2026-09-29, mesuré — 3ᵉ occurrence après le 2026-09-11
et le 2026-09-14)*.

### §7 — Smoke test : aucune entrée injectée

Démarrage à froid *(`force-stop`, purge du journal, lancement de l'activité)*, attente bornée, capture
du journal **filtrée sur le PID de l'application**, recherche de `FATAL`, constat d'affichage du hub.
⛔ **Le smoke test n'injecte AUCUN événement d'entrée** *(liste blanche de commandes, vérifiée par son
autotest)* ⇒ il ne peut **rien écrire** au titre de l'utilisateur *(AC-8 Limite)*. ⚠️ **Le lancement
d'une version de schéma plus récente réécrit le document** *(migration au premier lancement, ADR-009 /
ADR-012)* : c'est une écriture de **format**, pas de **contenu** — l'égalité exigée porte sur les
**échéances**. ⚠️ **Le constat « hub affiché » par machine est à MESURER** *(arbre d'accessibilité
exporté par `uiautomator`, non vérifié sur une application Flutter release de ce projet)* ; à défaut,
**capture d'écran jointe + constat humain à la validation**, et la preuve **le dit**.

### §8 — Pas de retour arrière : on corrige EN AVANT

Staging et production partageant l'appareil, **un staging raté laisse le candidat installé chez le
pratiquant**, et **aucun retour arrière n'est possible** *(rétrogradation interdite, AC-6 ; désinstallation
interdite, AC-7)*. ⇒ **La seule remédiation est une version corrective** de numéro supérieur, qui repasse
le staging. ⛔ **Ce coût est assumé** et c'est pourquoi le smoke test ne peut **rien** écrire.

### §9 — La CI : une release NON signée, contexte REQUIS en quatre temps *(verdict Q4)*

- Commande définie **en un seul endroit** *(Art. 4)* : un **composant d'adapter** `android` dans
  `factory.config.json` portant un gate de build release **non signée** *(`-Pconcentration.signature=aucune`)*,
  suivi d'une vérification que l'APK **ne vérifie pas** sous `apksigner`. Un **nouveau job** de `ci.yml`
  l'exécute par `run_gates.py --component android`.
- **Ordre qui évite de rendre `main` infusionnable** *(le contexte requis doit EXISTER et être VERT
  avant d'être EXIGÉ)* : **①** job ajouté, **rapporté non requis**, vert sur la PR · **②** entrée
  `status_checks` ajoutée **par l'humain** *(fichier Art. 6)* + `factory_sync.py --write` +
  `--check` vert, **dans la même PR**, la protection distante restant inchangée · **③** fusion, puis
  **constat du contexte vert sur le push de `main`** · **④** **l'humain** applique la protection
  *(`scripts/apply_branch_protection.sh`)* puis `factory_sync.py --check-remote` → **exit 0**, preuve
  datée. ⛔ **Inverser ② et ④** ferait exiger un contexte **jamais rapporté** ⇒ **verrouillage de toute
  PR, administrateur inclus** *(avertissement en tête de `ci.yml`)*.
- ⛔ **La CI ne reçoit aucun secret ni variable de signature** : ni `secrets.*` ni `vars.*` liés à la
  signature. La **propriété de mode** `concentration.signature=aucune` **n'est pas un secret** : elle
  **demande l'absence** de signature. ⚠️ Lecture à confirmer par @ProductOwner *(point A-6)*.

### §10 — Scénarios d'appareil : logique en CI sur sorties enregistrées, exécution réelle datée *(verdict Q1)*

- La **logique de verdict** est testée en CI sur des **sorties d'outils ENREGISTRÉES** *(fixtures
  expurgées : ⛔ aucun identifiant réel d'appareil, aucune empreinte réelle)*, avec **autotest de
  mutation** *(mutants ⛔ jamais tirés du vocabulaire de la règle testée)*.
- La correspondance scénario ↔ test *(ADR-008)* porte sur un **fichier de tests Python** dont chaque
  cas s'enregistre par un appel `test("<titre>", …)`. ⚠️ **À PROUVER AVANT d'écrire les titres** : le
  motif de `scripts/check_gherkin_mapping.py` a été écrit pour Dart ; qu'il lise un fichier Python
  correctement est une **hypothèse**, à établir par sonde *(précédent : `reports/US-01.4/preverif_titres_criterion.py`)*.
  ⛔ **Le couple est inscrit dans `COUPLES` EN DERNIER** *(leçon T15 d'US-01.4)*.
- L'**exécution réelle** sur l'appareil de référence est une **preuve datée** dans le registre — ⛔ elle
  **n'est pas** un test de CI, et un test de CI vert **n'est pas** un déploiement.

### §11 — RNF-02 : l'instrument EXISTANT est amendé en place, jamais doublé

`reports/US-01.1/rnf02_exit_criterion.py` reste **le seul** lecteur du seuil *(un second instrument
créerait le second exemplaire qu'il refuse)*. Amendements **datés** : le diagnostic « mesurable » cesse
de rendre **`0`** *(code réservé à `LEVÉ` par son propre en-tête)* · série **≥ 5** mesures à froid, verdict
sur la **pire** *(verdict Q12)* · cible **Android seule** *(H-1)* · message JDK périmé retiré · appareil
**nommé** dans la sortie · mesure sur le paquet **`.profile`** *(§1 — sans quoi F-2 s'appliquerait)*, avec
**9 échéances saisies dans CE paquet**, et borne écrite **« profil ≠ release »** *(verdict Q13)*.

## Alternatives considérées

| Alternative | Pourquoi écartée |
|---|---|
| **AAB + `bundletool`** | Un intermédiaire de plus entre l'empreinte et ce qui est installé ; aucun store visé *(Q7)* |
| **Signature en CI avec secrets GitHub** | ⛔ H-3 — dépôt **public** |
| **Clé jetable en CI pour produire un APK installable** | Produit un artefact **installable hors H-3** *(Q3 (c))* |
| **Runner CI auto-hébergé relié à l'appareil** | Expose un appareil personnel à un dépôt **public** *(Q1 (c))* |
| **Garder un identifiant unique pour tous les modes** | **F-2** : un `flutter run` détruirait les données du pratiquant — refusé **par construction**, pas par consigne |
| **Installer par `flutter install`** | Même méthode `installApp` que F-2 |
| **Gate Android DANS le job requis existant `📱 App`** *(précédent d'actionlint)* | N'aurait exigé **aucune** modification de la protection distante — ⚖️ mais le verdict humain Q4 demande un **status check requis** propre ; un job séparé garde la constructibilité Android **lisible à part** et n'impose pas un JDK au job `app`. ⛔ Non retenu, ⛔ non re-litigé |
| **Registre sous `reports/US-01.3/`** | Un déploiement vaut pour **plusieurs** US *(Q5)* : le registre survit à l'US qui l'a créé |
| **Second instrument RNF-02** | Second lecteur du seuil ⇒ second exemplaire de la règle |
| **Mesurer RNF-02 sur l'artefact release** | La trace de démarrage exige le mode profil *(lu dans l'instrument)* ; ⚠️ la non-disponibilité en release est un **fait transmis, non vérifié** — Q13 l'a rendu sans objet |

## Conséquences

**Positives** — les trois faux verts F-1, F-2, F-3 deviennent des **refus** ; « déployé » devient une
**ligne de registre vérifiée par machine** et non une déclaration ; la constructibilité Android est
prouvée **à chaque PR** *(jusque-là, seul le repli web l'était)*.

**Négatives, assumées et NOMMÉES** :
- ⛔ **Perte de la clé = perte des échéances** *(aucune mise à jour possible ⇒ désinstallation)*. La
  sauvegarde est une **attestation humaine datée, DÉCLARATIVE** *(Q9)* : aucune machine ne peut la
  prouver sans que la preuve soit elle-même un secret.
- ⛔ **Aucun retour arrière** *(§8)*.
- ⚠️ **Le build Android allonge chaque PR** *(téléchargement Gradle + compilation ; durée à MESURER à la
  tâche, ⛔ non estimée ici)*, et un 5ᵉ contexte requis **sérialise** davantage *(`strict: true`)*.
- ⚠️ **Nom de l'APK non signé** : l'outil Flutter recherche des noms d'APK fixés ; qu'il retrouve
  l'artefact **non signé** produit par AGP est **à mesurer** à la tâche CI — repli : lire la sortie AGP
  directement.
- 🔴 **Conflit avec la LETTRE de l'Art. 6** *(point A-3)* : *« Les secrets ne vivent que dans les
  variables d'environnement de la plateforme d'hébergement et les `.env` locaux jamais commités »* — un
  **keystore** est un **fichier**, et H-3 place les mots de passe dans **`key.properties`**. ⛔ **Cet ADR
  ne peut pas être accepté contre la Constitution** : amendement par **PR dédiée** *(clause de Révision)*,
  ou mots de passe déplacés dans un `.env` local — **décision humaine**.
- 🔴 **Conflit avec la LETTRE de l'Art. 4** *(point A-4)* : son §*Enforcement* dit que `ci.yml` et
  `branch-naming.yml` portent *« les **quatre** contextes requis »* ⇒ **faux dès l'étape ④ du §9**.
  Même traitement : **PR dédiée**, avant l'étape ④.
- ⚠️ **Identifiant d'appareil dans un dépôt PUBLIC** *(point A-2)* : AC-1 exige le **numéro de série**
  dans chaque preuve ; le publier expose un identifiant matériel de l'appareil personnel de l'humain.
  Recommandation : une **empreinte** du numéro de série *(comparable, non réversible en pratique)* —
  **décision @ProductOwner / humain**.
- 🔴 **RNF-07 n'est pas tenu par l'absence de permission réseau seule** *(point A-1)* : le manifeste
  principal ne fixe pas `android:allowBackup` ⇒ **valeur par défaut `true`** ⇒ la **sauvegarde
  automatique Android** peut copier le répertoire de données *(qui contient le document d'ADR-009)* vers
  le compte du propriétaire de l'appareil. ⚠️ **Fait de DOCUMENTATION Android, ⛔ non mesuré sur le SM
  T580.** ⛔ **Non tranché ici** : `allowBackup=false` **renforce RNF-07** mais **supprime la seule
  voie de récupération** des échéances hors de l'application — c'est un **arbitrage produit**.
- **NM-14** *(taux de crash)* et **NM-15** *(reproductibilité inter-machines)* **restent vraies**.
  ⛔ « 0 `FATAL` » **n'est jamais** un taux de crash.
- ⛔ **RNF-08 reste PARTIELLEMENT OUVERT** *(H-1)* : tout ce qui précède **ne vaut que pour Android**.

---
**Règle** : une décision d'architecture sans ADR n'est pas validée. Les ADR sont **immuables**
une fois acceptés — pour changer une décision, créer un nouvel ADR qui remplace l'ancien
(ne jamais éditer un ADR Accepté).
