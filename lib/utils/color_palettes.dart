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
    _fromHex("ffe0bd"),
    _fromHex("ffdbac"),
    _fromHex("ffcd94"),
    _fromHex("eac086"),
    _fromHex("e0ac69"),
    _fromHex("f1c27d"),
    _fromHex("ffad60"),
    _fromHex("c68642"),
    _fromHex("8d5524"),
    _fromHex("896347"),
    _fromHex("765339"),
    _fromHex("613d24"),
    _fromHex("4c2d17"),
  ];

  static final List<Color> hairColors = [
    _fromHex("8d5524"),
    _fromHex("896347"),
    _fromHex("765339"),
    _fromHex("613d24"),
    _fromHex("4c2d17"),
    _fromHex("9c5a3c"),
    _fromHex("ffc20e"),
    _fromHex("ff7e00"),
  ];

  static final List<Color> clothesColors = [
    _fromHex("f44336"),
    _fromHex("e91e63"),
    _fromHex("9c27b0"),
    _fromHex("673ab7"),
    _fromHex("3f51b5"),
    _fromHex("4caf50"),
    _fromHex("ffeb3b"),
  ];

  // --- Méthodes utilitaires ---

  static Color getRandomSkinColor() {
    return skinColors[_random.nextInt(skinColors.length)];
  }

  static Color getRandomHairColor() {
    return hairColors[_random.nextInt(hairColors.length)];
  }

  static Color getRandomClothesColor() {
    return clothesColors[_random.nextInt(clothesColors.length)];
  }
}