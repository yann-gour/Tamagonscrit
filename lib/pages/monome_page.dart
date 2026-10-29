import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_color_picker/web_color_picker.dart';
import '../utils/color_processor.dart';
import '../widgets/sprite_sheet_animator.dart';
import '../widgets/avatar_conscrit_widget.dart';
import '../services/achievement_service.dart';
import '../constants/skins.dart';

final ValueNotifier<int> monomeRefreshNotifier = ValueNotifier<int>(0);

class MonomePage extends StatefulWidget {
  final bool isVisible;
  const MonomePage({super.key, required this.isVisible});

  @override
  State<MonomePage> createState() => _MonomePageState();
}

class _MonomePageState extends State<MonomePage> with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;

  @override
  bool get wantKeepAlive => true;

  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _conscrits = [];
  String? _playerFams;
  String? _playerTabagns;

  // Monnaies
  int _zloeils = 0;

  // État de l'avatar personnalisable
  String _avatarState = 'idle';
  Color _avatarSkinColor = const Color(0xFFE5AA7A);
  Color _avatarHairColor = const Color(0xFF9C5A3C);
  Color _avatarTshirtColor = const Color(0xFFA8E61D);
  Color _avatarPantsColor = const Color(0xFF709AD1);
  bool _avatarIsBiaudeWhite = false;
  String _avatarEquippedSkin = 'none';

  Uint8List? _rawMonomeZgBytes;
  final Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    monomeRefreshNotifier.addListener(_onRefreshNotified);
    achievementsRefreshNotifier.addListener(_onAchievementsNotified);
    if (widget.isVisible) {
      _loadData();
    }
  }

  @override
  void didUpdateWidget(MonomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && (!oldWidget.isVisible || !_hasLoadedOnce)) {
      _loadData();
    }
  }

  void _onRefreshNotified() {
    if (mounted && widget.isVisible) {
      _loadData();
    }
  }

  void _onAchievementsNotified() {
    if (mounted) {
      setState(() {
        _zloeils = AchievementService().totalZloeils;
      });
    }
  }

  @override
  void dispose() {
    monomeRefreshNotifier.removeListener(_onRefreshNotified);
    achievementsRefreshNotifier.removeListener(_onAchievementsNotified);
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    _hasLoadedOnce = true;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_rawMonomeZgBytes == null) {
        final data = await rootBundle.load('assets/monome_zg.png');
        _rawMonomeZgBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      }

      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Utilisateur non connecté.";
        });
        return;
      }

      // 1. Lire d'abord les métadonnées de secours
      final userMeta = user.userMetadata ?? {};
      String avatarState = userMeta['avatar_state']?.toString() ?? 'idle';
      Color avatarSkinColor = userMeta['avatar_skin_color'] != null
          ? ColorProcessor.colorFromHex(userMeta['avatar_skin_color'].toString())
          : const Color(0xFFE5AA7A);
      Color avatarHairColor = userMeta['avatar_hair_color'] != null
          ? ColorProcessor.colorFromHex(userMeta['avatar_hair_color'].toString())
          : const Color(0xFF9C5A3C);
      Color avatarTshirtColor = userMeta['avatar_tshirt_color'] != null
          ? ColorProcessor.colorFromHex(userMeta['avatar_tshirt_color'].toString(), fallback: const Color(0xFFA8E61D))
          : const Color(0xFFA8E61D);
      Color avatarPantsColor = userMeta['avatar_pants_color'] != null
          ? ColorProcessor.colorFromHex(userMeta['avatar_pants_color'].toString(), fallback: const Color(0xFF709AD1))
          : const Color(0xFF709AD1);
      bool avatarIsBiaudeWhite = userMeta['avatar_is_biaude_white'] as bool? ?? false;
      String avatarEquippedSkin = userMeta['avatar_equipped_skin']?.toString() ?? 'none';

      String? playerFams = userMeta['fams']?.toString();
      String? playerTabagns = userMeta['tabagns']?.toString();
      int zloeils = (userMeta['zloeils'] as num?)?.toInt() ?? 0;

      // 2. Récupérer le profil depuis la table profiles de Supabase
      try {
        final profileRes = await _supabase
            .from('profiles')
            .select('fams, tabagns, avatar_state, avatar_skin_color, avatar_hair_color, avatar_tshirt_color, avatar_pants_color, avatar_is_biaude_white, avatar_equipped_skin, zloeils')
            .eq('id', user.id)
            .maybeSingle();

        if (profileRes != null) {
          if (profileRes['fams'] != null) playerFams = profileRes['fams']?.toString();
          if (profileRes['tabagns'] != null) playerTabagns = profileRes['tabagns']?.toString();
          if (profileRes['zloeils'] != null) {
            zloeils = (profileRes['zloeils'] as num).toInt();
          }
          if (profileRes['avatar_state'] != null && profileRes['avatar_state'].toString().isNotEmpty) {
            avatarState = profileRes['avatar_state'].toString();
          }
          if (profileRes['avatar_skin_color'] != null) {
            avatarSkinColor = ColorProcessor.colorFromHex(profileRes['avatar_skin_color'].toString());
          }
          if (profileRes['avatar_hair_color'] != null) {
            avatarHairColor = ColorProcessor.colorFromHex(profileRes['avatar_hair_color'].toString());
          }
          if (profileRes['avatar_tshirt_color'] != null) {
            avatarTshirtColor = ColorProcessor.colorFromHex(profileRes['avatar_tshirt_color'].toString(), fallback: const Color(0xFFA8E61D));
          }
          if (profileRes['avatar_pants_color'] != null) {
            avatarPantsColor = ColorProcessor.colorFromHex(profileRes['avatar_pants_color'].toString(), fallback: const Color(0xFF709AD1));
          }
          if (profileRes['avatar_is_biaude_white'] != null) {
            avatarIsBiaudeWhite = profileRes['avatar_is_biaude_white'] as bool;
          }
          if (profileRes['avatar_equipped_skin'] != null) {
            avatarEquippedSkin = profileRes['avatar_equipped_skin'].toString();
          }
        }
      } catch (e) {
        debugPrint('Erreur chargement profil avatar/fams: $e');
      }

      // 3. Charger les succès et calculer le total des Zloeils
      await AchievementService().loadAchievements();
      final computedZloeils = AchievementService().totalZloeils;
      if (computedZloeils > zloeils) {
        zloeils = computedZloeils;
      }

      final response = await _supabase
          .from('conscrits')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> conscritsData = List<Map<String, dynamic>>.from(response);

      for (int i = 0; i < conscritsData.length; i++) {
        conscritsData[i]['seniority'] = i + 1;
      }

      final List<Map<String, dynamic>> displayConscrits = conscritsData.reversed.toList();

      if (mounted) {
        setState(() {
          _playerFams = playerFams;
          _playerTabagns = playerTabagns;
          _zloeils = AchievementService().totalZloeils;
          _avatarState = avatarState;
          _avatarSkinColor = avatarSkinColor;
          _avatarHairColor = avatarHairColor;
          _avatarTshirtColor = avatarTshirtColor;
          _avatarPantsColor = avatarPantsColor;
          _avatarIsBiaudeWhite = avatarIsBiaudeWhite;
          _avatarEquippedSkin = avatarEquippedSkin;
          _conscrits = displayConscrits;
          _isLoading = false;
        });
      }

      _processImagesProgressively(conscritsData);

    } catch (e) {
      debugPrint('Erreur de chargement du monôme: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Impossible de charger le monôme.";
        });
      }
    }
  }

  Future<void> _processImagesProgressively(List<Map<String, dynamic>> conscritsData) async {
    if (_rawMonomeZgBytes == null) return;

    for (var conscrit in conscritsData) {
      if (!mounted) break;

      final skinHex = conscrit['skin_color'] as String? ?? '#E5AA7A';
      final hairHex = conscrit['hair_color'] as String? ?? '#9C5A3C';
      final cacheKey = '${skinHex}_$hairHex';

      if (!_imageCache.containsKey(cacheKey)) {
        final skinColor = ColorProcessor.colorFromHex(skinHex);
        final hairColor = ColorProcessor.colorFromHex(hairHex);

        final processedBytes = await ColorProcessor.processMonomeZg(
          rawMonomeZgBytes: _rawMonomeZgBytes!,
          skinColor: skinColor,
          hairColor: hairColor,
        );

        if (processedBytes != null && mounted) {
          setState(() {
            _imageCache[cacheKey] = processedBytes;
          });
        }
      }
    }
  }

  Future<void> _updateAvatarProfile({
    String? newState,
    Color? newSkinColor,
    Color? newHairColor,
    Color? newTshirtColor,
    Color? newPantsColor,
    bool? newIsBiaudeWhite,
    String? newEquippedSkin,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final stateToSave = newState ?? _avatarState;
    final skinToSave = newSkinColor ?? _avatarSkinColor;
    final hairToSave = newHairColor ?? _avatarHairColor;
    final tshirtToSave = newTshirtColor ?? _avatarTshirtColor;
    final pantsToSave = newPantsColor ?? _avatarPantsColor;
    final isBiaudeWhiteToSave = newIsBiaudeWhite ?? _avatarIsBiaudeWhite;
    final equippedSkinToSave = newEquippedSkin ?? _avatarEquippedSkin;

    setState(() {
      _avatarState = stateToSave;
      _avatarSkinColor = skinToSave;
      _avatarHairColor = hairToSave;
      _avatarTshirtColor = tshirtToSave;
      _avatarPantsColor = pantsToSave;
      _avatarIsBiaudeWhite = isBiaudeWhiteToSave;
      _avatarEquippedSkin = equippedSkinToSave;
    });

    try {
      final skinHex = ColorProcessor.colorToHex(skinToSave);
      final hairHex = ColorProcessor.colorToHex(hairToSave);
      final tshirtHex = ColorProcessor.colorToHex(tshirtToSave);
      final pantsHex = ColorProcessor.colorToHex(pantsToSave);

      Map<String, dynamic>? profileRes;
      try {
        profileRes = await _supabase
            .from('profiles')
            .select('bucque, fams, tabagns, proms')
            .eq('id', user.id)
            .maybeSingle();
      } catch (e) {
        debugPrint('Erreur lecture profil pour upsert: $e');
      }

      final userMeta = user.userMetadata ?? {};
      final bucque = profileRes?['bucque']?.toString() ?? userMeta['bucque']?.toString() ?? '';
      final fams = profileRes?['fams']?.toString() ?? userMeta['fams']?.toString();
      final tabagns = profileRes?['tabagns']?.toString() ?? userMeta['tabagns']?.toString();
      final proms = profileRes?['proms'] ?? userMeta['proms'];

      await _supabase.from('profiles').upsert({
        'id': user.id,
        'bucque': bucque,
        'fams': fams,
        'tabagns': tabagns,
        'proms': proms,
        'zloeils': _zloeils,
        'avatar_state': stateToSave,
        'avatar_skin_color': skinHex,
        'avatar_hair_color': hairHex,
        'avatar_tshirt_color': tshirtHex,
        'avatar_pants_color': pantsHex,
        'avatar_is_biaude_white': isBiaudeWhiteToSave,
        'avatar_equipped_skin': equippedSkinToSave,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      final existingMeta = Map<String, dynamic>.from(userMeta);
      existingMeta['zloeils'] = _zloeils;
      existingMeta['avatar_state'] = stateToSave;
      existingMeta['avatar_skin_color'] = skinHex;
      existingMeta['avatar_hair_color'] = hairHex;
      existingMeta['avatar_tshirt_color'] = tshirtHex;
      existingMeta['avatar_pants_color'] = pantsHex;
      existingMeta['avatar_is_biaude_white'] = isBiaudeWhiteToSave;
      existingMeta['avatar_equipped_skin'] = equippedSkinToSave;

      await _supabase.auth.updateUser(
        UserAttributes(data: existingMeta),
      );
    } catch (e) {
      debugPrint('Erreur de sauvegarde de l\'avatar dans Supabase: $e');
    }
  }

  Widget _buildStateDropdown() {
    final textThemeColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return SizedBox(
      width: 135,
      child: DropdownButtonFormField<String>(
        initialValue: _avatarState,
        isExpanded: true,
        dropdownColor: cardColor,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          border: OutlineInputBorder(),
          labelText: 'État',
        ),
        style: TextStyle(fontSize: 12, color: textThemeColor, fontWeight: FontWeight.w500),
        items: AvatarConscritWidget.stateLabels.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.value,
              style: TextStyle(fontSize: 11, color: textThemeColor),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            _updateAvatarProfile(newState: val);
          }
        },
      ),
    );
  }

  Widget _buildBiaudeDropdown() {
    final textThemeColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return SizedBox(
      width: 135,
      child: DropdownButtonFormField<bool>(
        initialValue: _avatarIsBiaudeWhite,
        isExpanded: true,
        dropdownColor: cardColor,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          border: OutlineInputBorder(),
          labelText: 'Biaude',
        ),
        style: TextStyle(fontSize: 12, color: textThemeColor, fontWeight: FontWeight.w500),
        items: const [
          DropdownMenuItem<bool>(
            value: false,
            child: Text('Zgrise', style: TextStyle(fontSize: 11)),
          ),
          DropdownMenuItem<bool>(
            value: true,
            child: Text('Zblanche', style: TextStyle(fontSize: 11)),
          ),
        ],
        onChanged: (val) {
          if (val != null) {
            _updateAvatarProfile(newIsBiaudeWhite: val);
          }
        },
      ),
    );
  }

  Widget _buildSkinDropdown() {
    final textThemeColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return SizedBox(
      width: 135,
      child: DropdownButtonFormField<String>(
        initialValue: _avatarEquippedSkin,
        isExpanded: true,
        dropdownColor: cardColor,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          border: OutlineInputBorder(),
          labelText: 'Zloeils',
        ),
        style: TextStyle(fontSize: 12, color: textThemeColor, fontWeight: FontWeight.w500),
        items: AvatarSkins.sortedSkins.map((skin) {
          final label = skin.zloeilsPrice > 0
              ? '${skin.name} (${skin.zloeilsPrice} 💎)'
              : skin.name;
          final bool isLocked = _zloeils < skin.zloeilsPrice;
          return DropdownMenuItem<String>(
            value: skin.id,
            child: Text(
              isLocked ? '$label 🔒' : label,
              style: TextStyle(
                fontSize: 11,
                color: isLocked ? Colors.grey : textThemeColor,
              ),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val == null) return;
          final selectedSkin = AvatarSkins.getSkin(val);
          if (_zloeils < selectedSkin.zloeilsPrice) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Tu as besoin de ${selectedSkin.zloeilsPrice} Zloeils pour équiper ${selectedSkin.name} ! (Solde : $_zloeils 💎)',
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
            setState(() {});
            return;
          }
          _updateAvatarProfile(newEquippedSkin: val);
        },
      ),
    );
  }

  Widget _buildElementPickerTile({
    required String title,
    required Color currentColor,
    required ValueChanged<Color> onChanged,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black26, width: 1),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        WebColorPicker(
          initialColor: currentColor,
          onChange: (colorObj, textHex) {
            onChanged(colorObj);
          },
        ),
      ],
    );
  }

  Widget _buildAvatarCustomizer() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne gauche : Conscrit + Dropdowns (état et biaude)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AvatarConscritWidget(
                      tabagns: _playerTabagns,
                      state: _avatarState,
                      skinColor: _avatarSkinColor,
                      hairColor: _avatarHairColor,
                      tshirtColor: _avatarTshirtColor,
                      pantsColor: _avatarPantsColor,
                      isBiaudeWhite: _avatarIsBiaudeWhite,
                      equippedSkin: _avatarEquippedSkin,
                      size: 130,
                    ),
                    const SizedBox(height: 8),
                    _buildStateDropdown(),
                    const SizedBox(height: 8),
                    _buildBiaudeDropdown(),
                    const SizedBox(height: 8),
                    _buildSkinDropdown(),
                  ],
                ),
                const SizedBox(width: 12),

                // Colonne droite : 4 WebColorPickers autonomes visibles simultanément
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Couleurs du Conscrit',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.95,
                        children: [
                          _buildElementPickerTile(
                            title: 'Peau',
                            currentColor: _avatarSkinColor,
                            onChanged: (color) => _updateAvatarProfile(newSkinColor: color),
                          ),
                          _buildElementPickerTile(
                            title: 'Cheveux',
                            currentColor: _avatarHairColor,
                            onChanged: (color) => _updateAvatarProfile(newHairColor: color),
                          ),
                          _buildElementPickerTile(
                            title: 'T-shirt',
                            currentColor: _avatarTshirtColor,
                            onChanged: (color) => _updateAvatarProfile(newTshirtColor: color),
                          ),
                          _buildElementPickerTile(
                            title: 'Pantalon',
                            currentColor: _avatarPantsColor,
                            onChanged: (color) => _updateAvatarProfile(newPantsColor: color),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConscritTile(Map<String, dynamic> conscrit) {
    final skinHex = conscrit['skin_color'] as String? ?? '#E5AA7A';
    final hairHex = conscrit['hair_color'] as String? ?? '#9C5A3C';
    final cacheKey = '${skinHex}_$hairHex';
    final imageBytes = _imageCache[cacheKey];
    final String name = (conscrit['name'] as String?) ?? '';
    final String conscritTabagns = (conscrit['tabagns'] as String?) ?? '';
    final String conscritFams = (conscrit['fams'] as String?) ?? '';
    final int seniority = conscrit['seniority'] as int? ?? 1;

    List<String> parts = [];
    if (name.isNotEmpty) parts.add(name);
    if (conscritFams.isNotEmpty) {
      parts.add(conscritFams);
    } else if (_playerFams != null && _playerFams!.isNotEmpty) {
      parts.add(_playerFams!);
    }
    if (conscritTabagns.isNotEmpty) {
      parts.add('$conscritTabagns$seniority');
    } else {
      parts.add('$seniority');
    }

    final displayLabel = parts.join(' ');

    return Container(
      color: const Color(0xFFE0E0E0),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          imageBytes != null
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return SpriteSheetAnimator(
                      imageBytes: imageBytes,
                      frameCount: 2,
                      frameDuration: const Duration(milliseconds: 500),
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      cropLeft: 4.0,
                      cropRight: 9.0,
                    );
                  },
                )
              : const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
          if (name.isNotEmpty)
            Positioned(
              bottom: 4,
              left: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  displayLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SafeArea(
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_hasLoadedOnce && !_isLoading) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Chargement du monôme...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final double totalTrads = _conscrits.fold(0.0, (sum, conscrit) {
      final t = conscrit['trads'];
      return sum + (t is num ? t.toDouble() : 0.0);
    });
    final String formattedTrads = totalTrads.round().toString();

    Widget gridContent;
    if (_conscrits.isEmpty) {
      gridContent = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(24.0),
        children: [
          Icon(Icons.groups_outlined, size: 70, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          const Text(
            'Le monôme est vide',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Obtiens le Zcu de tes conscrits pour les ajouter au monôme !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    } else {
      gridContent = LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 600
              ? 8
              : (constraints.maxWidth > 380 ? 4 : 3);

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _conscrits.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
              childAspectRatio: 950.0 / 1600.0,
            ),
            itemBuilder: (context, index) {
              return _buildConscritTile(_conscrits[index]);
            },
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 16.0, right: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "Gadz'Arts, en monôme !",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Score Trad\'s total : $formattedTrads',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.cyan, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.diamond, color: Colors.cyan, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '$_zloeils',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Section Avatar Personnalisable du Joueur
            _buildAvatarCustomizer(),
            const SizedBox(height: 8),
            // Grille du Monôme
            gridContent,
          ],
        ),
      ),
    );
  }
}
