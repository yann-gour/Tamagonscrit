import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/color_processor.dart';
import '../widgets/sprite_sheet_animator.dart';

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
  Uint8List? _rawMonomeZgBytes;
  final Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    monomeRefreshNotifier.addListener(_onRefreshNotified);
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

  @override
  void dispose() {
    monomeRefreshNotifier.removeListener(_onRefreshNotified);
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
      // 1. Charger la sprite sheet brute de monome_zg.png si pas encore chargée
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

      // Récupérer la fam's du joueur depuis profiles
      String? playerFams;
      try {
        final profileRes = await _supabase
            .from('profiles')
            .select('fams')
            .eq('id', user.id)
            .maybeSingle();
        if (profileRes != null) {
          playerFams = profileRes['fams']?.toString();
        }
      } catch (e) {
        debugPrint('Erreur chargement profil fams: $e');
      }

      // 2. Charger les conscrits de l'utilisateur (du plus vieux au plus récent)
      final response = await _supabase
          .from('conscrits')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> conscritsData = List<Map<String, dynamic>>.from(response);

      // Assigner le numéro d'ancienneté (seniority) (1 = le plus vieux)
      for (int i = 0; i < conscritsData.length; i++) {
        conscritsData[i]['seniority'] = i + 1;
      }

      // Inverser pour afficher du plus récent au plus vieux
      final List<Map<String, dynamic>> displayConscrits = conscritsData.reversed.toList();

      // 3. Pré-traiter les images de chaque conscrit
      if (_rawMonomeZgBytes != null) {
        for (var conscrit in conscritsData) {
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

            if (processedBytes != null) {
              _imageCache[cacheKey] = processedBytes;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _playerFams = playerFams;
          _conscrits = displayConscrits;
          _isLoading = false;
        });
      }
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

  Widget _buildConscritTile(Map<String, dynamic> conscrit) {
    final skinHex = conscrit['skin_color'] as String? ?? '#E5AA7A';
    final hairHex = conscrit['hair_color'] as String? ?? '#9C5A3C';
    final cacheKey = '${skinHex}_$hairHex';
    final imageBytes = _imageCache[cacheKey];
    final String name = (conscrit['name'] as String?) ?? '';
    final String conscritTabagns = (conscrit['tabagns'] as String?) ?? '';
    final int seniority = conscrit['seniority'] as int? ?? 1;

    List<String> parts = [];
    if (name.isNotEmpty) parts.add(name);
    if (_playerFams != null && _playerFams!.isNotEmpty) parts.add(_playerFams!);
    if (conscritTabagns.isNotEmpty) {
      parts.add('$conscritTabagns$seniority');
    } else {
      parts.add('$seniority');
    }

    final displayLabel = parts.join(' ');

    return Container(
      color: const Color(0xFFE0E0E0), // Fond gris clair pour chaque conscrit
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
                      cropLeft: 200.0,
                      cropRight: 450.0,
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

    // Fond par défaut selon le thème de l'application
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
    final String formattedTrads = totalTrads % 1 == 0
        ? totalTrads.toInt().toString()
        : totalTrads.toStringAsFixed(1);

    Widget content;
    if (_conscrits.isEmpty) {
      content = RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            Icon(Icons.groups_outlined, size: 90, color: Colors.grey.shade500),
            const SizedBox(height: 16),
            const Text(
              'Le monôme est vide',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Obtiens le Zcu de tes conscrits pour les ajouter au monôme !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    } else {
      content = RefreshIndicator(
        onRefresh: _loadData,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Nombre de colonnes adapté à la largeur rognée des cartes
            int crossAxisCount = constraints.maxWidth > 600
                ? 8
                : (constraints.maxWidth > 380 ? 4 : 3);

            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _conscrits.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
                childAspectRatio: 950.0 / 1600.0, // Ratio adapté au rognage (1600 - 200 - 450 = 950)
              ),
              itemBuilder: (context, index) {
                return _buildConscritTile(_conscrits[index]);
              },
            );
          },
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
          child: Column(
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
        ),
        Expanded(child: content),
      ],
    );
  }
}
