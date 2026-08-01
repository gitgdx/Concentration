import 'package:concentration/core/color/oklab.dart';
import 'package:concentration/core/color/rgb.dart';
import 'package:concentration/core/color/temporal_gradient.dart';
import 'package:concentration/core/theme/concentration_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests du moteur de dégradé (T5 / ADR-003).
///
/// Les assertions portent sur des **mesures** (contraste, monotonie, teinte),
/// jamais sur une capture d'écran.
void main() {
  const gradient = TemporalGradient();

  group('extrémités exactes (AC-5 « Limite »)', () {
    test('p = 0 rend exactement l’orange de référence', () {
      expect(gradient.backgroundFor(0), ConcentrationTokens.gradientOrange);
    });

    test('p = 1 rend exactement le bleu de référence', () {
      expect(gradient.backgroundFor(1), ConcentrationTokens.gradientBleu);
    });

    test('p hors bornes est borné, jamais rejeté', () {
      expect(gradient.backgroundFor(-5), ConcentrationTokens.gradientOrange);
      expect(gradient.backgroundFor(42), ConcentrationTokens.gradientBleu);
    });
  });

  group('⛔ AUCUN ROUGE PERCEPTIBLE — l’interdit d’AC-5, énoncé correctement', () {
    // ⚠️ ADR-003 écrit que le rouge est « inatteignable par construction ».
    // MESURE : c'est FAUX au sens de la TEINTE — le segment cartésien croise la
    // direction rouge (15 points sur 101, p de 0,37 à ~0,51) parce qu'il passe
    // près du neutre, où b change de signe avant a. Ce qui est VRAI, et qui est
    // la vraie garantie : la traversée se fait à CHROMA TRÈS BASSE, donc en gris
    // chaud désaturé et non en rouge. L'arc polaire le plus court croiserait la
    // même teinte à PLEINE chroma. Correction consignée dans DESIGN_SYSTEM.md
    // (un ADR Accepté est immuable).
    test(
      'dans le secteur rouge, la chroma reste sous 1/2 de celle des extrémités',
      () {
        final chromaExtremites = [
          Oklab.depuisRgb(gradient.backgroundFor(0)).chroma,
          Oklab.depuisRgb(gradient.backgroundFor(1)).chroma,
        ].reduce((a, b) => a < b ? a : b);
        var chromaMaxRouge = 0.0;
        for (var i = 0; i <= 100; i++) {
          final o = Oklab.depuisRgb(gradient.backgroundFor(i / 100));
          final t = o.teinteDegres;
          if (t < 25 || t > 335) {
            chromaMaxRouge = chromaMaxRouge > o.chroma
                ? chromaMaxRouge
                : o.chroma;
          }
        }
        expect(
          chromaMaxRouge,
          lessThan(chromaExtremites / 2),
          reason:
              'chroma ${chromaMaxRouge.toStringAsFixed(4)} dans le secteur rouge, '
              'extrémités ${chromaExtremites.toStringAsFixed(4)}',
        );
      },
    );

    test(
      'aucun p ne produit un rouge SATURÉ (chroma > 0,07 dans le secteur rouge)',
      () {
        for (var i = 0; i <= 100; i++) {
          final p = i / 100;
          final o = Oklab.depuisRgb(gradient.backgroundFor(p));
          final t = o.teinteDegres;
          final rougeSature = (t < 25 || t > 335) && o.chroma > 0.07;
          expect(
            rougeSature,
            isFalse,
            reason:
                'rouge saturé à p=$p : teinte ${t.toStringAsFixed(1)}°, '
                'chroma ${o.chroma.toStringAsFixed(3)}',
          );
        }
      },
    );
  });

  group('monotonie perceptuelle', () {
    test(
      'L est EXACTEMENT monotone dans l’interpolation (contrat du moteur)',
      () {
        final depart = Oklab.depuisRgb(ConcentrationTokens.gradientOrange);
        final arrivee = Oklab.depuisRgb(ConcentrationTokens.gradientBleu);
        var precedent = depart.l;
        for (var i = 1; i <= 100; i++) {
          final actuel = Oklab.interpoler(depart, arrivee, i / 100).l;
          expect(actuel, lessThanOrEqualTo(precedent));
          precedent = actuel;
        }
      },
    );

    test('L rendue est monotone À LA QUANTIFICATION 8 BITS PRÈS', () {
      // Le rendu passe par des entiers 0-255 : une remontée de l'ordre du quantum
      // est un artefact d'arrondi, pas une non-monotonie du moteur. Mesurée :
      // 2,55e-4 au maximum. La tolérance est justifiée, pas choisie pour passer.
      const toleranceQuantification = 1e-3;
      var precedent = Oklab.depuisRgb(gradient.backgroundFor(0)).l;
      for (var i = 1; i <= 100; i++) {
        final actuel = Oklab.depuisRgb(gradient.backgroundFor(i / 100)).l;
        expect(
          actuel,
          lessThanOrEqualTo(precedent + toleranceQuantification),
          reason: 'L remonte de plus d’un quantum à p=${i / 100}',
        );
        precedent = actuel;
      }
    });
  });

  group(
    'contraste WCAG — sur un ÉCHANTILLONNAGE de p, pas aux seules extrémités',
    () {
      test('le meilleur candidat tient 4,5:1 partout (RNF-06)', () {
        var pire = double.infinity;
        var pirePoint = 0.0;
        for (var i = 0; i <= 100; i++) {
          final p = i / 100;
          final c = gradient.contrasteA(p);
          if (c < pire) {
            pire = c;
            pirePoint = p;
          }
        }
        expect(
          pire,
          greaterThanOrEqualTo(ConcentrationTokens.contrasteMinTexteNormal),
          reason: 'pire contraste ${pire.toStringAsFixed(2)}:1 à p=$pirePoint',
        );
      });

      test(
        'le pire point est bien à p = 1 et vaut ~4,53:1 — la marge est de 0,03',
        () {
          // Valeur MESURÉE et non écrite à la main : on la relit du moteur.
          final mesure = gradient.contrasteA(1);
          expect(mesure, closeTo(4.53, 0.02));
          expect(
            mesure,
            greaterThanOrEqualTo(ConcentrationTokens.contrasteMinTexteNormal),
          );
          for (var i = 0; i <= 100; i++) {
            expect(
              gradient.contrasteA(i / 100),
              greaterThanOrEqualTo(mesure - 1e-9),
            );
          }
        },
      );

      test('foregroundFor rend le candidat le PLUS contrasté', () {
        for (final p in [0.0, 0.25, 0.5, 0.75, 1.0]) {
          final fond = gradient.backgroundFor(p);
          final choisi = gradient.foregroundFor(p);
          for (final candidat in ConcentrationTokens.texteSurTuileCandidats) {
            expect(
              fond.contrasteAvec(choisi),
              greaterThanOrEqualTo(fond.contrasteAvec(candidat)),
            );
          }
        }
      });

      test('⛔ ÉCHOUE BRUYAMMENT si le seuil demandé est inatteignable', () {
        // 21:1 est le contraste maximal théorique (noir sur blanc) : aucun fond
        // coloré ne peut l'atteindre. Le moteur doit LEVER, pas rendre « la moins
        // mauvaise » couleur.
        expect(
          () => gradient.foregroundFor(0.5, contrasteMin: 21),
          throwsStateError,
        );
      });
    },
  );

  group('gamut — réduction de chroma, jamais écrêtage par canal', () {
    test('toutes les couleurs du dégradé sont dans le gamut sRGB', () {
      for (var i = 0; i <= 100; i++) {
        final rendu = gradient.backgroundFor(i / 100);
        expect(
          Oklab.depuisRgb(rendu).estDansGamut,
          isTrue,
          reason: 'hors gamut à p=${i / 100}',
        );
      }
    });

    test(
      'une couleur volontairement hors gamut voit sa CHROMA réduite, à L quasi constante',
      () {
        // Chroma absurde : impossible en sRGB.
        const absurde = Oklab(0.6, 0.9, 0.9);
        expect(absurde.estDansGamut, isFalse);
        final ramene = absurde.versRgb();
        final apres = Oklab.depuisRgb(ramene);
        expect(apres.estDansGamut, isTrue);
        expect(apres.chroma, lessThan(absurde.chroma));
        expect(
          apres.l,
          closeTo(absurde.l, 0.06),
          reason: 'la luminance ne doit pas dériver',
        );
      },
    );
  });

  group('Rgb — briques de mesure', () {
    test('hex aller-retour', () {
      expect(Rgb.hex('#FF8C42').hex, '#ff8c42');
      expect(() => Rgb.hex('#ABC'), throwsArgumentError);
    });

    test('contraste noir/blanc = 21:1', () {
      expect(
        Rgb.hex('#000000').contrasteAvec(Rgb.hex('#FFFFFF')),
        closeTo(21, 0.01),
      );
    });

    test('contraste d’une couleur avec elle-même = 1:1', () {
      final c = Rgb.hex('#3D7DD8');
      expect(c.contrasteAvec(c), closeTo(1, 1e-9));
    });
  });
}
