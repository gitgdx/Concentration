/// Abstraction du temps (T3).
///
/// Le temps est une **dépendance explicite** : jamais de `DateTime.now()` dans
/// la logique (ADR-002). C'est ce qui rend le rafraîchissement (RF-05) et tous
/// les cas limites temporels reproductibles en test.
abstract class Clock {
  const Clock();

  /// Instant courant, dans le fuseau **local** de l'appareil (RNF-04).
  DateTime now();
}

/// Horloge réelle, seule implémentation à consulter le système.
class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Horloge de test : rend l'instant qu'on lui a fixé, et rien d'autre.
class FakeClock extends Clock {
  FakeClock(this._instant);

  DateTime _instant;

  @override
  DateTime now() => _instant;

  /// Avance l'horloge — utilisé pour éprouver le rafraîchissement (RF-05).
  void avancerDe(Duration d) => _instant = _instant.add(d);

  /// Positionne l'horloge sur un instant précis.
  void positionnerA(DateTime instant) => _instant = instant;
}
