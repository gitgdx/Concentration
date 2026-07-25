# language: fr

Fonctionnalité: Qualité statique de référence du squelette (US-00.2)
  En tant que membre de la squad de développement
  Je veux une qualité statique de référence formalisée et vérifiée sur le squelette
  Afin de garantir un socle de code propre, cohérent et reproductible en CI avant la première US métier

  Scénario: Le formatage du squelette est conforme (Nominal AC-1)
    Étant donné que le squelette applicatif Flutter est initialisé
    Et que les fichiers de "lib" et "test" respectent la convention de formatage Dart
    Quand j'exécute le gate de formatage sur le squelette
    Alors la commande retourne un code de sortie égal à zéro
    Et aucun fichier n'est signalé comme nécessitant un reformatage

  Scénario: L'analyse statique ne remonte aucune issue (Nominal AC-2)
    Étant donné que le squelette applicatif Flutter est initialisé
    Quand j'exécute le gate d'analyse statique sur le squelette
    Alors le rapport indique "No issues found!"
    Et le nombre d'erreurs, d'avertissements et de lints est égal à zéro
    Et la commande retourne un code de sortie égal à zéro

  Scénario: Aucune règle de lint n'est désactivée sans justification (Nominal AC-3)
    Étant donné que le fichier de configuration du lint inclut le set de base recommandé
    Et que je passe en revue chaque règle désactivée dans la configuration du lint
    Quand une règle est désactivée
    Alors un commentaire de justification écrit accompagne cette désactivation
    Et le gate qualité est vert

  Scénario: Une règle désactivée sans justification fait échouer le gate qualité (Erreur AC-3)
    Étant donné que le fichier de configuration du lint inclut le set de base recommandé
    Et qu'une règle de lint est désactivée sans commentaire de justification
    Quand j'exécute la vérification de la qualité statique
    Alors le défaut est détecté comme une règle désactivée non justifiée
    Et le gate qualité échoue

  Scénario: Un fichier mal formaté fait échouer le gate de formatage (Erreur AC-1)
    Étant donné que le squelette applicatif Flutter est initialisé
    Et qu'au moins un fichier de "lib" ou "test" n'est pas formaté selon la convention Dart
    Quand j'exécute le gate de formatage sur le squelette
    Alors la commande liste le fichier non conforme
    Et la commande retourne un code de sortie différent de zéro
    Et le gate de formatage échoue

  Scénario: Le gate qualité rejoué en CI donne le même résultat qu'en local (Limite/Reproductibilité AC-4)
    Étant donné que les commandes de qualité statique sont définies uniquement dans la configuration de la factory
    Et que le squelette passe la qualité statique en local
    Quand le job d'intégration continue rejoue les mêmes gates de formatage et d'analyse
    Alors le résultat obtenu en intégration continue est identique au résultat local
    Et le job de qualité est vert sur la pull request
