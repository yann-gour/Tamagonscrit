import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/color_processor.dart';
import '../widgets/sprite_sheet_animator.dart';

final ValueNotifier<int> monomeRefreshNotifier = ValueNotifier<int>(0);

class MonomePage extends StatefulWidget {
  const MonomePage({super.key});

  @override
  State<MonomePage> createState() => _MonomePageState();
}

class _MonomePageState extends State<MonomePage> with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;

  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _conscrits = [];
  Uint8List? _rawMonomeZgBytes;
  final Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    monomeRefreshNotifier.addListener(_onRefreshNotified);
    _loadData();
  }

  void _onRefreshNotified() {
    if (mounted) {
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

      // 2. Charger les conscrits de l'utilisateur
      final response = await _supabase
          .from('conscrits')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> conscritsData = List<Map<String, dynamic>>.from(response);

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
          _conscrits = conscritsData;
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
                  name,
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
              'Le Monôme est vide',
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
                'Le Monôme',
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
