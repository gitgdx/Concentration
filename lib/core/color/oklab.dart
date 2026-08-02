import 'dart:math' as math;

import 'rgb.dart';

/// Couleur en **OKLab** — coordonnées cartésiennes `(L, a, b)`.
///
/// **ADR-003** : c'est en cartésien que l'interpolation se fait, et non en
/// OKLCH polaire. Motif décisif : la forme polaire impose de choisir un **sens
/// de rotation** de teinte, et l'arc le plus court entre l'orange (~50°) et le
/// bleu (~258°) **passe par le rouge à PLEINE CHROMA**, ce qu'AC-5 interdit.
///
/// ⚠️ **Précision MESURÉE, contre la formulation d'ADR-003** : le segment
/// cartésien **croise lui aussi la direction de teinte rouge** (15 points sur
/// 101, `p` de 0,37 à ~0,51), parce qu'il passe près du neutre où `b` change de
/// signe avant `a`. Le rouge n'est donc **pas** « inatteignable par
/// construction » — ce qui est vrai, et qui est la vraie garantie, c'est que la
/// traversée se fait à **chroma ≤ 0,059** contre **0,164 aux extrémités** : un
/// gris chaud désaturé, jamais un rouge perceptible. Correction consignée dans
/// `DESIGN_SYSTEM.md`, l'ADR Accepté étant immuable. Assertion correspondante :
/// `test/core/color/temporal_gradient_test.dart`.
class Oklab {
  const Oklab(this.l, this.a, this.b);

  factory Oklab.depuisRgb(Rgb c) {
    final r = _versLineaire(c.r);
    final g = _versLineaire(c.g);
    final bl = _versLineaire(c.b);

    final l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * bl;
    final m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * bl;
    final s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * bl;

    final l3 = _racineCubique(l);
    final m3 = _racineCubique(m);
    final s3 = _racineCubique(s);

    return Oklab(
      0.2104542553 * l3 + 0.7936177850 * m3 - 0.0040720468 * s3,
      1.9779984951 * l3 - 2.4285922050 * m3 + 0.4505937099 * s3,
      0.0259040371 * l3 + 0.7827717662 * m3 - 0.8086757660 * s3,
    );
  }

  final double l;
  final double a;
  final double b;

  /// Interpolation **linéaire** en cartésien : c'est tout l'objet d'ADR-003.
  static Oklab interpoler(Oklab depart, Oklab arrivee, double t) => Oklab(
    depart.l + (arrivee.l - depart.l) * t,
    depart.a + (arrivee.a - depart.a) * t,
    depart.b + (arrivee.b - depart.b) * t,
  );

  /// Chroma (distance au neutre) — utile aux assertions, jamais à
  /// l'interpolation.
  double get chroma => math.sqrt(a * a + b * b);

  /// Teinte en degrés `[0;360)` — **diagnostic uniquement** (les tests
  /// vérifient qu'aucun `p` ne produit une teinte rouge).
  double get teinteDegres {
    final d = math.atan2(b, a) * 180 / math.pi;
    return d < 0 ? d + 360 : d;
  }

  /// Conversion vers sRGB **en réduisant la CHROMA** si la couleur sort du
  /// gamut, à `L` constante (ADR-003 §4).
  ///
  /// ⛔ Jamais d'écrêtage canal par canal : il déplacerait la **luminance** et
  /// casserait la garantie de contraste.
  Rgb versRgb() {
    // Le test de gamut porte sur les canaux LINÉAIRES NON écrêtés : les
    // écrêter d'abord rendrait le test toujours vrai et la réduction de chroma
    // ne se déclencherait jamais (vert silencieux).
    for (var i = 0; i <= 64; i++) {
      final facteur = 1.0 - i / 64.0;
      final lineaire = Oklab(l, a * facteur, b * facteur)._versLineaireRgb();
      if (lineaire.every((v) => v >= -0.0005 && v <= 1.0005)) {
        return _depuisLineaire(lineaire);
      }
    }
    // Dernier recours : chroma nulle (gris de même L), toujours dans le gamut.
    return _depuisLineaire(Oklab(l, 0, 0)._versLineaireRgb());
  }

  /// Vrai si la couleur tient dans le gamut sRGB **sans** réduction de chroma.
  bool get estDansGamut =>
      _versLineaireRgb().every((v) => v >= -0.0005 && v <= 1.0005);

  static Rgb _depuisLineaire(List<double> lineaire) => Rgb(
    _versSrgb(lineaire[0]).round().clamp(0, 255),
    _versSrgb(lineaire[1]).round().clamp(0, 255),
    _versSrgb(lineaire[2]).round().clamp(0, 255),
  );

  List<double> _versLineaireRgb() {
    final l3 = l + 0.3963377774 * a + 0.2158037573 * b;
    final m3 = l - 0.1055613458 * a - 0.0638541728 * b;
    final s3 = l - 0.0894841775 * a - 1.2914855480 * b;

    final lc = l3 * l3 * l3;
    final mc = m3 * m3 * m3;
    final sc = s3 * s3 * s3;

    return [
      4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc,
      -1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc,
      -0.0041960863 * lc - 0.7034186147 * mc + 1.7076147010 * sc,
    ];
  }

  static double _versLineaire(int composante) {
    final v = composante / 255.0;
    return v <= 0.04045
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  static double _versSrgb(double lineaire) {
    final v = lineaire.clamp(0.0, 1.0);
    final s = v <= 0.0031308 ? 12.92 * v : 1.055 * math.pow(v, 1 / 2.4) - 0.055;
    return s * 255.0;
  }

  static double _racineCubique(double v) =>
      v >= 0 ? math.pow(v, 1 / 3).toDouble() : -math.pow(-v, 1 / 3).toDouble();
}
