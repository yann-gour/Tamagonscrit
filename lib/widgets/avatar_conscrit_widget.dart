import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../utils/color_processor.dart';
import '../constants/skins.dart';
import 'sprite_sheet_animator.dart';

class AvatarConscritWidget extends StatefulWidget {
  final String? tabagns;
  final String state; // 'idle', 'birse', 'ronque', 'monome', 'fins', 'chouille'
  final Color skinColor;
  final Color hairColor;
  final Color tshirtColor;
  final Color pantsColor;
  final bool isBiaudeWhite;
  final String equippedSkin; // 'none', 'equerre', etc.
  final bool showBackground;
  final double spriteScale;
  final double size;

  const AvatarConscritWidget({
    super.key,
    this.tabagns,
    this.state = 'idle',
    required this.skinColor,
    required this.hairColor,
    this.tshirtColor = const Color(0xFFA8E61D),
    this.pantsColor = const Color(0xFF709AD1),
    this.isBiaudeWhite = false,
    this.equippedSkin = 'none',
    this.showBackground = true,
    this.spriteScale = 0.7,
    this.size = 140.0,
  });

  /// Map d'état vers le fichier image asset
  static String getImageForState(String state) {
    switch (state.toLowerCase()) {
      case 'birse':
        return 'birse.png';
      case 'ronque':
        return 'ronque.png';
      case 'monome':
        return 'monome.png';
      case 'fins':
      case "fin's":
        return 'fins.png';
      case 'chouille':
        return 'chouille.png';
      case 'idle':
      case 'tranquille':
      default:
        return 'conscrit.png';
    }
  }

  /// Map d'état vers un label utilisateur
  static const Map<String, String> stateLabels = {
    'idle': 'Tranquille',
    'birse': 'Birser',
    'ronque': 'Ronque',
    'monome': 'Monôme',
    'fins': "Fin's",
    'chouille': 'Chouille',
  };

  @override
  State<AvatarConscritWidget> createState() => _AvatarConscritWidgetState();
}

class _AvatarConscritWidgetState extends State<AvatarConscritWidget> {
  Uint8List? _processedImageBytes;
  bool _isProcessing = false;

  // Cache mémoire par clé (asset_skinHex_hairHex_tshirtHex_pantsHex_biaudeWhite)
  static final Map<String, Uint8List> _avatarCache = {};
  static final Map<String, Uint8List> _skinBytesCache = {};

  @override
  void initState() {
    super.initState();
    _processAvatarImage();
    _loadSkinBytes(widget.equippedSkin);
  }

  @override
  void didUpdateWidget(AvatarConscritWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state ||
        oldWidget.skinColor != widget.skinColor ||
        oldWidget.hairColor != widget.hairColor ||
        oldWidget.tshirtColor != widget.tshirtColor ||
        oldWidget.pantsColor != widget.pantsColor ||
        oldWidget.isBiaudeWhite != widget.isBiaudeWhite) {
      _processAvatarImage();
    }
    if (oldWidget.equippedSkin != widget.equippedSkin) {
      _loadSkinBytes(widget.equippedSkin);
    }
  }

  Future<void> _loadSkinBytes(String skinId) async {
    final skin = AvatarSkins.getSkin(skinId);
    if (skin.assetPath == null || _skinBytesCache.containsKey(skin.id)) return;
    try {
      final data = await rootBundle.load(skin.assetPath!);
      _skinBytesCache[skin.id] = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Erreur lors du chargement du skin $skinId : $e');
    }
  }

  Future<void> _processAvatarImage() async {
    final assetName = AvatarConscritWidget.getImageForState(widget.state);
    final skinHex = ColorProcessor.colorToHex(widget.skinColor);
    final hairHex = ColorProcessor.colorToHex(widget.hairColor);
    final tshirtHex = ColorProcessor.colorToHex(widget.tshirtColor);
    final pantsHex = ColorProcessor.colorToHex(widget.pantsColor);
    final cacheKey = '${assetName}_${skinHex}_${hairHex}_${tshirtHex}_${pantsHex}_${widget.isBiaudeWhite}';

    if (_avatarCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _processedImageBytes = _avatarCache[cacheKey];
          _isProcessing = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    try {
      final processed = await ColorProcessor.processImage(
        assetPath: 'assets/$assetName',
        newSkinColor: widget.skinColor,
        newHairColor: widget.hairColor,
        newTshirtColor: widget.tshirtColor,
        newPantsColor: widget.pantsColor,
        isBiaudeWhite: widget.isBiaudeWhite,
      );

      if (processed != null) {
        _avatarCache[cacheKey] = processed;
      }

      if (mounted) {
        setState(() {
          _processedImageBytes = processed;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du traitement de l\'avatar conscrit : $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabagnsLower = widget.tabagns?.toLowerCase();
    final backgroundAsset = (tabagnsLower != null && tabagnsLower.isNotEmpty)
        ? 'assets/fond_$tabagnsLower.png'
        : 'assets/fond.png';

    final activeSkin = AvatarSkins.getSkin(widget.equippedSkin);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: widget.showBackground
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black26, width: 2),
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.showBackground ? 14 : 0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image de fond du tabagn's (si activée)
            if (widget.showBackground)
              Image.asset(
                backgroundAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset('assets/fond.png', fit: BoxFit.cover),
              ),

            // Conscrit animé recoloré + Skin superposé
            Center(
              child: _isProcessing
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_processedImageBytes != null)
                          SpriteSheetAnimator(
                            imageBytes: _processedImageBytes!,
                            frameCount: 2,
                            frameDuration: const Duration(milliseconds: 600),
                            width: widget.size * widget.spriteScale,
                            height: widget.size * widget.spriteScale,
                          )
                        else
                          const Icon(Icons.person, color: Colors.grey),

                        // Superposition du skin
                        if (activeSkin.assetPath != null &&
                            _skinBytesCache[activeSkin.id] != null)
                          SpriteSheetAnimator(
                            imageBytes: _skinBytesCache[activeSkin.id]!,
                            frameCount: 2,
                            frameDuration: const Duration(milliseconds: 600),
                            width: widget.size * widget.spriteScale,
                            height: widget.size * widget.spriteScale,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
