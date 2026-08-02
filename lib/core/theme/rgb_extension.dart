import 'dart:ui';

import '../color/rgb.dart';

/// Frontière **unique** entre le noyau colorimétrique pur et Flutter.
///
/// Le noyau manipule [Rgb] (Dart pur, aucun `dart:ui`) ; la présentation a
/// besoin de `Color`. Cette conversion est le **seul** point de contact, ce qui
/// garde les moteurs testables hors arbre de widgets.
extension RgbVersColor on Rgb {
  Color get couleur => Color.fromARGB(255, r, g, b);
}
