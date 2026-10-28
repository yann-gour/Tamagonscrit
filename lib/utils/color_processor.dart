import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart' show Color, debugPrint;
import 'package:flutter/foundation.dart' show compute;

class ColorProcessRequest {
  final Map<String, Uint8List> rawImages;
  final Color newSkinColor;
  final Color newHairColor;
  final Color newTshirtColor;
  final Color newPantsColor;
  final bool isBiaudeWhite;

  ColorProcessRequest({
    required this.rawImages,
    required this.newSkinColor,
    required this.newHairColor,
    required this.newTshirtColor,
    required this.newPantsColor,
    required this.isBiaudeWhite,
  });
}

class MonomeZgRequest {
  final Uint8List rawMonomeZgBytes;
  final Color skinColor;
  final Color hairColor;

  MonomeZgRequest({
    required this.rawMonomeZgBytes,
    required this.skinColor,
    required this.hairColor,
  });
}

class ColorProcessor {
  // Couleurs cibles originales (au format ARGB utilisé par la librairie image)
  // Attention: la librairie image encode généralement les couleurs en 0xAABBGGRR 
  // depuis la version 4, ou utilise des méthodes utilitaires.
  // Utilisons les composantes pour être sûrs.
  static const int origSkinR = 229, origSkinG = 170, origSkinB = 122; // #e5aa7a
  static const int origHairR = 156, origHairG = 90, origHairB = 60; // #9c5a3c
  static const int origTshirtR = 168, origTshirtG = 230, origTshirtB = 29; // #a8e61d
  static const int origPantsR = 112, origPantsG = 154, origPantsB = 209; // #709ad1
  static const int origBiaudeR = 180, origBiaudeG = 180, origBiaudeB = 180; // #b4b4b4

  /// Traite une image depuis les assets et remplace les couleurs spécifiées.
  static Future<Uint8List?> processImage({
    required String assetPath,
    required Color newSkinColor,
    required Color newHairColor,
    required Color newTshirtColor,
    required Color newPantsColor,
    required bool isBiaudeWhite,
  }) async {
    try {
      // Lire le fichier asset
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Décoder l'image PNG
      final img.Image? decodedImage = img.decodePng(bytes);
      if (decodedImage == null) return null;

      // Parcourir tous les pixels
      for (final pixel in decodedImage) {
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        // Remplacement de la Peau
        if (r == origSkinR && g == origSkinG && b == origSkinB) {
          // Dans Flutter 3.27+, on récupère les valeurs entières 0-255 via le canal
          pixel.r = (newSkinColor.r * 255).toInt();
          pixel.g = (newSkinColor.g * 255).toInt();
          pixel.b = (newSkinColor.b * 255).toInt();
          pixel.a = 255; // Forcer l'opacité
        }
        // Remplacement des Cheveux
        else if (r == origHairR && g == origHairG && b == origHairB) {
          pixel.r = (newHairColor.r * 255).toInt();
          pixel.g = (newHairColor.g * 255).toInt();
          pixel.b = (newHairColor.b * 255).toInt();
          pixel.a = 255;
        }
        // Remplacement du T-Shirt
        else if (r == origTshirtR && g == origTshirtG && b == origTshirtB) {
          pixel.r = (newTshirtColor.r * 255).toInt();
          pixel.g = (newTshirtColor.g * 255).toInt();
          pixel.b = (newTshirtColor.b * 255).toInt();
          pixel.a = 255;
        }
        // Remplacement du Pantalon
        else if (r == origPantsR && g == origPantsG && b == origPantsB) {
          pixel.r = (newPantsColor.r * 255).toInt();
          pixel.g = (newPantsColor.g * 255).toInt();
          pixel.b = (newPantsColor.b * 255).toInt();
          pixel.a = 255;
        }
        // Remplacement de la Biaude
        else if (r == origBiaudeR && g == origBiaudeG && b == origBiaudeB) {
          if (isBiaudeWhite) {
            pixel.r = 255;
            pixel.g = 255;
            pixel.b = 255;
            pixel.a = 255;
          }
        }
      }

      // Ré-encoder en PNG
      return img.encodePng(decodedImage);
    } catch (e) {
      debugPrint('Erreur lors du traitement de l\'image: $e');
      return null;
    }
  }

  /// Traite toutes les images d'un coup dans un Isolate séparé.
  static Future<Map<String, Uint8List>> processAllImagesInBackground({
    required Color newSkinColor,
    required Color newHairColor,
    required Color newTshirtColor,
    required Color newPantsColor,
    required bool isBiaudeWhite,
  }) async {
    // 1. Lire tous les fichiers sur le Main Thread (car rootBundle n'est pas dispo dans un Isolate)
    final assetsToProcess = ['conscrit.png', 'birse.png', 'ronque.png', 'monome.png', 'chouille.png', 'fins.png'];
    final Map<String, Uint8List> rawImages = {};
    
    for (String asset in assetsToProcess) {
      final ByteData data = await rootBundle.load('assets/$asset');
      rawImages[asset] = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }

    // 2. Préparer la requête
    final request = ColorProcessRequest(
      rawImages: rawImages,
      newSkinColor: newSkinColor,
      newHairColor: newHairColor,
      newTshirtColor: newTshirtColor,
      newPantsColor: newPantsColor,
      isBiaudeWhite: isBiaudeWhite,
    );

    // 3. Lancer le traitement lourd dans un Isolate
    return await compute(_processImagesInIsolate, request);
  }

  /// Fonction globale (Top-level) qui sera exécutée par l'Isolate
  static Map<String, Uint8List> _processImagesInIsolate(ColorProcessRequest request) {
    final Map<String, Uint8List> processedImages = {};

    for (var entry in request.rawImages.entries) {
      final String imageName = entry.key;
      final Uint8List bytes = entry.value;

      final img.Image? decodedImage = img.decodePng(bytes);
      if (decodedImage == null) continue;

      for (final pixel in decodedImage) {
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        // Remplacement de la Peau
        if (r == origSkinR && g == origSkinG && b == origSkinB) {
          pixel.r = (request.newSkinColor.r * 255).toInt();
          pixel.g = (request.newSkinColor.g * 255).toInt();
          pixel.b = (request.newSkinColor.b * 255).toInt();
          pixel.a = 255;
        }
        // Remplacement des Cheveux
        else if (r == origHairR && g == origHairG && b == origHairB) {
          pixel.r = (request.newHairColor.r * 255).toInt();
          pixel.g = (request.newHairColor.g * 255).toInt();
          pixel.b = (request.newHairColor.b * 255).toInt();
          pixel.a = 255;
        }
        // Remplacement du T-Shirt
        else if (r == origTshirtR && g == origTshirtG && b == origTshirtB) {
          pixel.r = (request.newTshirtColor.r * 255).toInt();
          pixel.g = (request.newTshirtColor.g * 255).toInt();
          pixel.b = (request.newTshirtColor.b * 255).toInt();
          pixel.a = 255;
        }
        // Remplacement du Pantalon
        else if (r == origPantsR && g == origPantsG && b == origPantsB) {
          pixel.r = (request.newPantsColor.r * 255).toInt();
          pixel.g = (request.newPantsColor.g * 255).toInt();
          pixel.b = (request.newPantsColor.b * 255).toInt();
          pixel.a = 255;
        }
        // Remplacement de la Biaude
        else if (r == origBiaudeR && g == origBiaudeG && b == origBiaudeB) {
          if (request.isBiaudeWhite) {
            pixel.r = 255;
            pixel.g = 255;
            pixel.b = 255;
            pixel.a = 255;
          }
        }
      }

      processedImages[imageName] = img.encodePng(decodedImage);
    }

    return processedImages;
  }

  /// Traite la sprite sheet monome_zg.png pour un conscrit spécifique.
  static Future<Uint8List?> processMonomeZg({
    required Uint8List rawMonomeZgBytes,
    required Color skinColor,
    required Color hairColor,
  }) async {
    final request = MonomeZgRequest(
      rawMonomeZgBytes: rawMonomeZgBytes,
      skinColor: skinColor,
      hairColor: hairColor,
    );
    return await compute(_processMonomeZgInIsolate, request);
  }

  static Uint8List? _processMonomeZgInIsolate(MonomeZgRequest request) {
    try {
      final img.Image? decodedImage = img.decodePng(request.rawMonomeZgBytes);
      if (decodedImage == null) return null;

      final skinR = (request.skinColor.r * 255).toInt();
      final skinG = (request.skinColor.g * 255).toInt();
      final skinB = (request.skinColor.b * 255).toInt();

      final hairR = (request.hairColor.r * 255).toInt();
      final hairG = (request.hairColor.g * 255).toInt();
      final hairB = (request.hairColor.b * 255).toInt();

      for (final pixel in decodedImage) {
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        // Remplacement de la Peau
        if (r == origSkinR && g == origSkinG && b == origSkinB) {
          pixel.r = skinR;
          pixel.g = skinG;
          pixel.b = skinB;
          pixel.a = 255;
        }
        // Remplacement des Cheveux
        else if (r == origHairR && g == origHairG && b == origHairB) {
          pixel.r = hairR;
          pixel.g = hairG;
          pixel.b = hairB;
          pixel.a = 255;
        }
      }

      return img.encodePng(decodedImage);
    } catch (e) {
      debugPrint('Erreur lors du traitement de monome_zg: $e');
      return null;
    }
  }

  /// Parse une couleur depuis un string Hex (ex: "#FF00FF" ou "Color(0xff123456)") avec valeur par défaut
  static Color colorFromHex(String? hexColor, {Color fallback = const Color(0xFFE5AA7A)}) {
    if (hexColor == null || hexColor.trim().isEmpty) return fallback;
    try {
      var hex = hexColor.trim().toUpperCase()
          .replaceAll("#", "")
          .replaceAll("COLOR(0X", "")
          .replaceAll("COLOR(", "")
          .replaceAll(")", "")
          .replaceAll("0X", "");
      if (hex.length == 6) {
        hex = "FF$hex";
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  /// Convertit une couleur en string Hex (ex: "#FF00FF")
  static String colorToHex(Color color) {
    // toARGB32() retourne un entier. On pad avec des zéros pour être sûr d'avoir 8 caractères.
    final hexStr = color.toARGB32().toRadixString(16).padLeft(8, '0');
    // On extrait les 6 derniers caractères (RRGGBB) et on ajoute le #
    return '#${hexStr.substring(2, 8).toUpperCase()}';
  }
}