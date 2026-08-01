import 'package:concentration/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de l'horloge injectable (T3).
void main() {
  test('FakeClock rend l’instant fixé, et rien d’autre', () {
    final instant = DateTime(2026, 8, 1, 12);
    expect(FakeClock(instant).now(), instant);
  });

  test('FakeClock avance de la durée demandée', () {
    final horloge = FakeClock(DateTime(2026, 8, 1, 12));
    horloge.avancerDe(const Duration(hours: 3, minutes: 30));
    expect(horloge.now(), DateTime(2026, 8, 1, 15, 30));
  });

  test('FakeClock se positionne sur un instant précis', () {
    final horloge = FakeClock(DateTime(2026));
    horloge.positionnerA(DateTime(2030, 6, 15));
    expect(horloge.now(), DateTime(2030, 6, 15));
  });

  test('SystemClock lit l’heure réelle, dans le fuseau local (RNF-04)', () {
    const horloge = SystemClock();
    final avant = DateTime.now();
    final lu = horloge.now();
    final apres = DateTime.now();
    expect(lu.isBefore(avant.subtract(const Duration(seconds: 1))), isFalse);
    expect(lu.isAfter(apres.add(const Duration(seconds: 1))), isFalse);
    expect(lu.isUtc, isFalse);
  });
}
