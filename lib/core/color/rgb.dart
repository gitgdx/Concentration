import 'dart:math' as math;

/// Couleur sRGB 8 bits — type **du domaine**, volontairement pas `dart:ui`.
///
/// Le noyau colorimétrique reste ainsi du **Dart pur** : aucune dépendance à
/// Flutter, conformément aux patterns imposés (moteurs purs isolés des
/// widgets). La conversion vers `Color` se fait à la frontière de présentation.
class Rgb {
  const Rgb(this.r, this.g, this.b);

  /// Depuis une notation `#RRGGBB` (ou `RRGGBB`).
  factory Rgb.hex(String hex) {
    final h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length != 6) {
      throw ArgumentError.value(hex, 'hex', 'attendu #RRGGBB');
    }
    return Rgb(
      int.parse(h.substring(0, 2), radix: 16),
      int.parse(h.substring(2, 4), radix: 16),
      int.parse(h.substring(4, 6), radix: 16),
    );
  }

  final int r;
  final int g;
  final int b;

  /// Luminance relative WCAG 2.1.
  double get luminanceRelative {
    double lin(int c) {
      final v = c / 255.0;
      return v <= 0.04045
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
  }

  /// Rapport de contraste WCAG entre deux couleurs (de 1:1 à 21:1).
  double contrasteAvec(Rgb autre) {
    final a = luminanceRelative;
    final c = autre.luminanceRelative;
    final clair = math.max(a, c);
    final sombre = math.min(a, c);
    return (clair + 0.05) / (sombre + 0.05);
  }

  String get hex =>
      '#'
      '${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is Rgb && other.r == r && other.g == g && other.b == b;

  @override
  int get hashCode => Object.hash(r, g, b);

  @override
  String toString() => hex;
}
