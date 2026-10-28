import 'dart:math';
import 'package:flutter/material.dart' show Color;

class ColorPalettes {
  static final Random _random = Random();

  /// Parse une couleur depuis un string Hex (ex: "FF00FF" ou "#FF00FF")
  static Color _fromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // --- Listes des couleurs paramétrables ---

  static final List<Color> skinColors = [
    _fromHex("FFE0BD"),
    _fromHex("FFDBAC"),
    _fromHex("FFCD94"),
    _fromHex("EAC086"),
    _fromHex("E0AC69"),
    _fromHex("F1C27D"),
    _fromHex("FFAD60"),
    _fromHex("C68642"),
    _fromHex("8D5524"),
    _fromHex("896347"),
    _fromHex("765339"),
    _fromHex("613D24"),
    _fromHex("4C2D17"),
    _fromHex("3B2212"),
    _fromHex("E5AA7A"),
    _fromHex("D1A384"),
    _fromHex("B8860B"),
    _fromHex("D2B48C"),
  ];

  static final List<Color> hairColors = [
    _fromHex("000000"), // Noir
    _fromHex("2C1609"), // Brun très foncé
    _fromHex("4C2D17"), // Châtain foncé
    _fromHex("613D24"), // Châtain
    _fromHex("896347"), // Châtain clair
    _fromHex("8D5524"), // Marron
    _fromHex("9C5A3C"), // Acajou / Châtain cuivré
    _fromHex("FF7E00"), // Orange
    _fromHex("FFC20E"), // Blond vénitien
    _fromHex("D4AF37"), // Blond
    _fromHex("A0A0A0"), // Gris / Argent
    _fromHex("E8E8E8"), // Blanc / Platine
    _fromHex("E91E63"), // Rose
    _fromHex("9C27B0"), // Violet
    _fromHex("2196F3"), // Bleu
    _fromHex("4CAF50"), // Vert
  ];

  static final List<Color> tshirtColors = [
    _fromHex("A8E61D"), // Vert pomme original
    _fromHex("F44336"), // Rouge
    _fromHex("E91E63"), // Rose
    _fromHex("9C27B0"), // Violet
    _fromHex("673AB7"), // Violet foncé
    _fromHex("3F51B5"), // Indigo
    _fromHex("2196F3"), // Bleu
    _fromHex("03A9F4"), // Bleu clair
    _fromHex("00BCD4"), // Cyan
    _fromHex("009688"), // Teal
    _fromHex("4CAF50"), // Vert
    _fromHex("8BC34A"), // Vert clair
    _fromHex("CDDC39"), // Lime
    _fromHex("FFEB3B"), // Jaune
    _fromHex("FFC107"), // Amber
    _fromHex("FF9800"), // Orange
    _fromHex("FF5722"), // Orange foncé
    _fromHex("795548"), // Marron
    _fromHex("9E9E9E"), // Gris
    _fromHex("607D8B"), // Blue grey
    _fromHex("FFFFFF"), // Blanc
    _fromHex("212121"), // Noir
  ];

  static final List<Color> pantsColors = [
    _fromHex("709AD1"), // Bleu jean original
    _fromHex("1A365D"), // Jean brut / Marine foncé
    _fromHex("2B6CB0"), // Jean classique
    _fromHex("4A5568"), // Gris ardoise
    _fromHex("2D3748"), // Gris foncé
    _fromHex("1A202C"), // Noir
    _fromHex("718096"), // Gris clair
    _fromHex("D69E2E"), // Camel / Beige
    _fromHex("C05621"), // Marron rouille
    _fromHex("742A2A"), // Bordeaux
    _fromHex("22543D"), // Vert olive
    _fromHex("7B341E"), // Marron terre
    _fromHex("EDF2F7"), // Blanc cassé
  ];

  // Compatibilité alias pour clothesColors
  static List<Color> get clothesColors => tshirtColors;

  // --- Méthodes utilitaires ---

  static Color getRandomSkinColor() {
    return skinColors[_random.nextInt(skinColors.length)];
  }

  static Color getRandomHairColor() {
    return hairColors[_random.nextInt(hairColors.length)];
  }

  static Color getRandomClothesColor() {
    return tshirtColors[_random.nextInt(tshirtColors.length)];
  }
}
