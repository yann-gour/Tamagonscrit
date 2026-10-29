import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/color_processor.dart';
import '../widgets/sprite_sheet_animator.dart';
import '../widgets/avatar_conscrit_widget.dart';
import 'home_page.dart' show homeTabNotifier;
import 'monome_page.dart' show monomeRefreshNotifier;

final ValueNotifier<int> leaderboardRefreshNotifier = ValueNotifier<int>(0);

class GadzScore {
  final String userId;
  final String bucque;
  final String? fams;
  final String? tabagns;
  final int? proms;
  final String? strass;
  final double score;
  final String avatarState;
  final Color skinColor;
  final Color hairColor;
  final Color tshirtColor;
  final Color pantsColor;
  final bool isBiaudeWhite;
  final String equippedSkin;

  GadzScore({
    required this.userId,
    required this.bucque,
    this.fams,
    this.tabagns,
    this.proms,
    this.strass,
    required this.score,
    this.avatarState = 'idle',
    this.skinColor = const Color(0xFFE5AA7A),
    this.hairColor = const Color(0xFF9C5A3C),
    this.tshirtColor = const Color(0xFFA8E61D),
    this.pantsColor = const Color(0xFF709AD1),
    this.isBiaudeWhite = false,
    this.equippedSkin = 'none',
  });
}

class GadzScoreTile extends StatelessWidget {
  final GadzScore gadz;
  final Widget? leading;
  final bool isMe;
  final VoidCallback? onTap;

  const GadzScoreTile({
    super.key,
    required this.gadz,
    this.leading,
    this.isMe = false,
    this.onTap,
  });

  String _formatScore(double score) {
    return score.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final line1Text = gadz.fams != null && gadz.fams!.isNotEmpty
        ? "${gadz.bucque} ${gadz.fams}"
        : gadz.bucque;

    String? line2Text;
    if (gadz.tabagns != null && gadz.tabagns!.isNotEmpty && gadz.proms != null) {
      line2Text = "${gadz.tabagns}${gadz.proms}";
    } else if (gadz.tabagns != null && gadz.tabagns!.isNotEmpty) {
      line2Text = gadz.tabagns;
    } else if (gadz.proms != null) {
      line2Text = "${gadz.proms}";
    }

    final leadingWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading ?? const SizedBox.shrink(),
        const SizedBox(width: 8),
        AvatarConscritWidget(
          tabagns: gadz.tabagns,
          state: gadz.avatarState,
          skinColor: gadz.skinColor,
          hairColor: gadz.hairColor,
          tshirtColor: gadz.tshirtColor,
          pantsColor: gadz.pantsColor,
          isBiaudeWhite: gadz.isBiaudeWhite,
          equippedSkin: gadz.equippedSkin,
          showBackground: false,
          spriteScale: 1.4,
          size: 42.0,
        ),
      ],
    );

    return ListTile(
      leading: leadingWidget,
      onTap: onTap ?? () {
        showDialog(
          context: context,
          builder: (context) => PlayerMonomeDialog(gadz: gadz),
        );
      },
      title: Row(
        children: [
          Expanded(
            child: Text(
              line1Text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          if (isMe)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text("phy's", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      subtitle: line2Text != null
          ? Text(
              line2Text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            )
          : null,
      trailing: Text(
        "${_formatScore(gadz.score)} Trad's",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.orange,
        ),
      ),
    );
  }
}

class PlayerMonomeDialog extends StatefulWidget {
  final GadzScore gadz;

  const PlayerMonomeDialog({super.key, required this.gadz});

  @override
  State<PlayerMonomeDialog> createState() => _PlayerMonomeDialogState();
}

class _PlayerMonomeDialogState extends State<PlayerMonomeDialog> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _conscrits = [];
  Uint8List? _rawMonomeZgBytes;
  final Map<String, Uint8List> _imageCache = {};

  String _avatarState = 'idle';
  Color _avatarSkinColor = const Color(0xFFE5AA7A);
  Color _avatarHairColor = const Color(0xFF9C5A3C);
  Color _avatarTshirtColor = const Color(0xFFA8E61D);
  Color _avatarPantsColor = const Color(0xFF709AD1);
  bool _avatarIsBiaudeWhite = false;
  String _avatarEquippedSkin = 'none';
  String? _avatarTabagns;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (_rawMonomeZgBytes == null) {
        final data = await rootBundle.load('assets/monome_zg.png');
        _rawMonomeZgBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      }

      // Récupérer les informations d'avatar depuis profiles
      try {
        final profileRes = await _supabase
            .from('profiles')
            .select('tabagns, avatar_state, avatar_skin_color, avatar_hair_color, avatar_tshirt_color, avatar_pants_color, avatar_is_biaude_white, avatar_equipped_skin')
            .eq('id', widget.gadz.userId)
            .maybeSingle();

        if (profileRes != null) {
          if (profileRes['tabagns'] != null) {
            _avatarTabagns = profileRes['tabagns'].toString();
          }
          if (profileRes['avatar_state'] != null && profileRes['avatar_state'].toString().isNotEmpty) {
            _avatarState = profileRes['avatar_state'].toString();
          }
          if (profileRes['avatar_skin_color'] != null) {
            _avatarSkinColor = ColorProcessor.colorFromHex(profileRes['avatar_skin_color'].toString(), fallback: const Color(0xFFE5AA7A));
          }
          if (profileRes['avatar_hair_color'] != null) {
            _avatarHairColor = ColorProcessor.colorFromHex(profileRes['avatar_hair_color'].toString(), fallback: const Color(0xFF9C5A3C));
          }
          if (profileRes['avatar_tshirt_color'] != null) {
            _avatarTshirtColor = ColorProcessor.colorFromHex(profileRes['avatar_tshirt_color'].toString(), fallback: const Color(0xFFA8E61D));
          }
          if (profileRes['avatar_pants_color'] != null) {
            _avatarPantsColor = ColorProcessor.colorFromHex(profileRes['avatar_pants_color'].toString(), fallback: const Color(0xFF709AD1));
          }
          if (profileRes['avatar_is_biaude_white'] != null) {
            _avatarIsBiaudeWhite = profileRes['avatar_is_biaude_white'] as bool;
          }
          if (profileRes['avatar_equipped_skin'] != null) {
            _avatarEquippedSkin = profileRes['avatar_equipped_skin'].toString();
          }
        }
      } catch (e) {
        debugPrint('Erreur chargement avatar profil joueur: $e');
      }

      final response = await _supabase
          .from('conscrits')
          .select()
          .eq('user_id', widget.gadz.userId)
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> conscritsData = List<Map<String, dynamic>>.from(response);

      for (int i = 0; i < conscritsData.length; i++) {
        conscritsData[i]['seniority'] = i + 1;
      }

      final List<Map<String, dynamic>> displayConscrits = conscritsData.reversed.toList();

      if (mounted) {
        setState(() {
          _conscrits = displayConscrits;
          _isLoading = false;
        });
      }

      _processImagesProgressively(conscritsData);
    } catch (e) {
      debugPrint('Erreur chargement monôme joueur: $e');
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
    } else if (widget.gadz.fams != null && widget.gadz.fams!.isNotEmpty) {
      parts.add(widget.gadz.fams!);
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
                    fontSize: 9,
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
    final currentUserId = _supabase.auth.currentUser?.id;
    final bool isMe = currentUserId != null && currentUserId == widget.gadz.userId;

    final List<String> details = [];
    if (widget.gadz.tabagns != null && widget.gadz.tabagns!.isNotEmpty && widget.gadz.proms != null) {
      details.add("${widget.gadz.tabagns}${widget.gadz.proms}");
    } else if (widget.gadz.tabagns != null && widget.gadz.tabagns!.isNotEmpty) {
      details.add(widget.gadz.tabagns!);
    } else if (widget.gadz.proms != null) {
      details.add("${widget.gadz.proms}");
    }
    details.add("${widget.gadz.score.round()} Trad's");

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.gadz.fams != null && widget.gadz.fams!.isNotEmpty
                ? "${widget.gadz.bucque} ${widget.gadz.fams}"
                : widget.gadz.bucque,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            details.join(' • '),
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 520,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : Column(
                    children: [
                      // Conscrit personnalisable du joueur (240px comme la page Conscrit)
                      Center(
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            AvatarConscritWidget(
                              tabagns: _avatarTabagns ?? widget.gadz.tabagns,
                              state: _avatarState,
                              skinColor: _avatarSkinColor,
                              hairColor: _avatarHairColor,
                              tshirtColor: _avatarTshirtColor,
                              pantsColor: _avatarPantsColor,
                              isBiaudeWhite: _avatarIsBiaudeWhite,
                              equippedSkin: _avatarEquippedSkin,
                              size: 240,
                            ),
                            if (isMe)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Material(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  shape: const CircleBorder(),
                                  elevation: 4,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      size: 20,
                                    ),
                                    tooltip: 'Modifier mon conscrit',
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      monomeRefreshNotifier.value++;
                                      homeTabNotifier.value = 1;
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _conscrits.isEmpty
                            ? Center(
                                child: Text(
                                  "Le monôme de ${widget.gadz.bucque} est vide.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                ),
                              )
                            : GridView.builder(
                                itemCount: _conscrits.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 0,
                                  mainAxisSpacing: 0,
                                  childAspectRatio: 950.0 / 1600.0,
                                ),
                                itemBuilder: (context, index) {
                                  return _buildConscritTile(_conscrits[index]);
                                },
                              ),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

class FamsScore {
  final String fams;
  final double score;
  final int playerCount;

  FamsScore({
    required this.fams,
    required this.score,
    required this.playerCount,
  });
}

class TabagnsScore {
  final String tabagns;
  final double score;
  final int playerCount;

  TabagnsScore({
    required this.tabagns,
    required this.score,
    required this.playerCount,
  });
}

class PromsScore {
  final int proms;
  final double score;
  final int playerCount;

  PromsScore({
    required this.proms,
    required this.score,
    required this.playerCount,
  });
}

class StrassScore {
  final String strass;
  final double score;
  final int playerCount;

  StrassScore({
    required this.strass,
    required this.score,
    required this.playerCount,
  });
}

class PromsEvenOddScore {
  final String groupName;
  final double score;
  final int playerCount;
  final bool isEven;

  PromsEvenOddScore({
    required this.groupName,
    required this.score,
    required this.playerCount,
    required this.isEven,
  });
}

class PgJpTvaScore {
  final String groupName;
  final double score;
  final int playerCount;
  final String groupKey;

  PgJpTvaScore({
    required this.groupName,
    required this.score,
    required this.playerCount,
    required this.groupKey,
  });
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;

  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  String? _errorMessage;

  List<GadzScore> _gadzScores = [];
  List<FamsScore> _famsScores = [];
  List<TabagnsScore> _tabagnsScores = [];
  List<PromsScore> _promsScores = [];
  List<StrassScore> _strassScores = [];
  List<PromsEvenOddScore> _promsEvenOddScores = [];
  List<PgJpTvaScore> _pgJpTvaScores = [];

  static const Map<String, String> _tabagnsFullNames = {
    'Ai': 'KIN (Ai)',
    'An': 'Boquette (An)',
    'Bo': 'Bordel\'s (Bo)',
    'Ch': 'Chalon\'s (Ch)',
    'Cl': 'Clun\'s (Cl)',
    'Li': 'Birse (Li)',
    'Me': 'Siber\'s (Me)',
  };

  @override
  void initState() {
    super.initState();
    leaderboardRefreshNotifier.addListener(_onRefreshNotified);
    _loadLeaderboardData();
  }

  void _onRefreshNotified() {
    if (mounted) {
      _loadLeaderboardData();
    }
  }

  @override
  void dispose() {
    leaderboardRefreshNotifier.removeListener(_onRefreshNotified);
    super.dispose();
  }

  Future<void> _loadLeaderboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Récupérer les profils
      List<Map<String, dynamic>> profilesData = [];
      try {
        final profilesResponse = await _supabase.from('profiles').select();
        profilesData = List<Map<String, dynamic>>.from(profilesResponse);
      } catch (e) {
        debugPrint('Erreur lors du chargement des profils: $e');
      }

      // 2. Récupérer les conscrits terminés
      List<Map<String, dynamic>> conscritsData = [];
      try {
        final conscritsResponse = await _supabase.from('conscrits').select();
        conscritsData = List<Map<String, dynamic>>.from(conscritsResponse);
      } catch (e) {
        debugPrint('Erreur lors du chargement des conscrits: $e');
      }

      // 3. Récupérer l'état des conscrits en cours
      List<Map<String, dynamic>> conscritStatesData = [];
      try {
        final stateResponse = await _supabase.from('conscrit_state').select();
        conscritStatesData = List<Map<String, dynamic>>.from(stateResponse);
      } catch (e) {
        debugPrint('Erreur lors du chargement de conscrit_state: $e');
      }

      // Dictionnaire userId -> Profile Map
      final Map<String, Map<String, dynamic>> profilesMap = {};
      for (var p in profilesData) {
        final id = p['id']?.toString();
        if (id != null) {
          profilesMap[id] = p;
        }
      }

      // Compléter avec l'utilisateur actuel si nécessaire
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null && !profilesMap.containsKey(currentUser.id)) {
        final meta = currentUser.userMetadata ?? {};
        final bucque = meta['bucque']?.toString().trim();
        if (bucque != null && bucque.isNotEmpty) {
          profilesMap[currentUser.id] = {
            'id': currentUser.id,
            'bucque': bucque,
            'fams': meta['fams']?.toString().trim(),
            'tabagns': meta['tabagns']?.toString().trim(),
            'proms': meta['proms'] != null ? int.tryParse(meta['proms'].toString()) : null,
            'strass': meta['strass']?.toString().trim(),
          };
        }
      }

      // Dictionnaire userId -> total score
      final Map<String, double> userScoresMap = {};

      for (var c in conscritsData) {
        final userId = c['user_id']?.toString();
        if (userId == null) continue;
        final trads = (c['trads'] as num?)?.toDouble() ?? 0.0;
        userScoresMap[userId] = (userScoresMap[userId] ?? 0.0) + trads;
      }

      for (var cs in conscritStatesData) {
        final userId = cs['user_id']?.toString();
        if (userId == null) continue;
        final trads = (cs['trads'] as num?)?.toDouble() ?? 0.0;
        userScoresMap[userId] = (userScoresMap[userId] ?? 0.0) + trads;
      }

      // Ensemble de tous les identifiants d'utilisateurs connus
      final Set<String> allUserIds = {
        ...profilesMap.keys,
        ...userScoresMap.keys,
      };

      final List<GadzScore> gadzList = [];

      for (var userId in allUserIds) {
        final profile = profilesMap[userId];
        final score = userScoresMap[userId] ?? 0.0;

        final bucque = profile?['bucque']?.toString().trim() ?? '';
        if (bucque.isEmpty) {
          continue;
        }

        final fams = profile?['fams']?.toString().trim();
        final tabagns = profile?['tabagns']?.toString().trim();
        final strass = profile?['strass']?.toString().trim();

        int? proms;
        if (profile?['proms'] != null) {
          if (profile!['proms'] is int) {
            proms = profile['proms'] as int;
          } else {
            proms = int.tryParse(profile['proms'].toString());
          }
        }

        final avatarState = profile?['avatar_state']?.toString() ?? 'idle';
        final skinHex = profile?['avatar_skin_color']?.toString();
        final hairHex = profile?['avatar_hair_color']?.toString();
        final tshirtHex = profile?['avatar_tshirt_color']?.toString();
        final pantsHex = profile?['avatar_pants_color']?.toString();
        final isBiaudeWhite = profile?['avatar_is_biaude_white'] as bool? ?? false;
        final equippedSkin = profile?['avatar_equipped_skin']?.toString() ?? 'none';

        final skinColor = ColorProcessor.colorFromHex(skinHex, fallback: const Color(0xFFE5AA7A));
        final hairColor = ColorProcessor.colorFromHex(hairHex, fallback: const Color(0xFF9C5A3C));
        final tshirtColor = ColorProcessor.colorFromHex(tshirtHex, fallback: const Color(0xFFA8E61D));
        final pantsColor = ColorProcessor.colorFromHex(pantsHex, fallback: const Color(0xFF709AD1));

        gadzList.add(GadzScore(
          userId: userId,
          bucque: bucque,
          fams: fams?.isNotEmpty == true ? fams : null,
          tabagns: tabagns?.isNotEmpty == true ? tabagns : null,
          proms: proms,
          strass: strass?.isNotEmpty == true ? strass : null,
          score: score,
          avatarState: avatarState,
          skinColor: skinColor,
          hairColor: hairColor,
          tshirtColor: tshirtColor,
          pantsColor: pantsColor,
          isBiaudeWhite: isBiaudeWhite,
          equippedSkin: equippedSkin,
        ));
      }

      // Tri des gadz par score décroissant
      gadzList.sort((a, b) => b.score.compareTo(a.score));

      // Aggrégation par Fam's
      final Map<String, _AggregatedStat> famsAgg = {};
      for (var g in gadzList) {
        if (g.fams != null && g.fams!.isNotEmpty) {
          final f = g.fams!;
          famsAgg.putIfAbsent(f, () => _AggregatedStat());
          famsAgg[f]!.score += g.score;
          famsAgg[f]!.count += 1;
        }
      }

      final List<FamsScore> famsList = famsAgg.entries.map((entry) {
        return FamsScore(
          fams: entry.key,
          score: entry.value.score,
          playerCount: entry.value.count,
        );
      }).toList();

      famsList.sort((a, b) => b.score.compareTo(a.score));

      // 4. Aggrégation par Tabagn's
      final Map<String, _AggregatedStat> tabagnsAgg = {};
      for (var g in gadzList) {
        if (g.tabagns != null && g.tabagns!.isNotEmpty) {
          final t = g.tabagns!;
          tabagnsAgg.putIfAbsent(t, () => _AggregatedStat());
          tabagnsAgg[t]!.score += g.score;
          tabagnsAgg[t]!.count += 1;
        }
      }

      final List<TabagnsScore> tabagnsList = tabagnsAgg.entries.map((entry) {
        return TabagnsScore(
          tabagns: entry.key,
          score: entry.value.score,
          playerCount: entry.value.count,
        );
      }).toList();

      tabagnsList.sort((a, b) => b.score.compareTo(a.score));

      // 5. Aggrégation par Prom's
      final Map<int, _AggregatedStat> promsAgg = {};
      for (var g in gadzList) {
        if (g.proms != null && g.proms! > 0) {
          final p = g.proms!;
          promsAgg.putIfAbsent(p, () => _AggregatedStat());
          promsAgg[p]!.score += g.score;
          promsAgg[p]!.count += 1;
        }
      }

      final List<PromsScore> promsList = promsAgg.entries.map((entry) {
        return PromsScore(
          proms: entry.key,
          score: entry.value.score,
          playerCount: entry.value.count,
        );
      }).toList();

      promsList.sort((a, b) => b.score.compareTo(a.score));

      // 5.5 Aggrégation par Strass
      final Map<String, _AggregatedStat> strassAgg = {};
      for (var g in gadzList) {
        if (g.strass != null && g.strass!.isNotEmpty) {
          final s = g.strass!;
          strassAgg.putIfAbsent(s, () => _AggregatedStat());
          strassAgg[s]!.score += g.score;
          strassAgg[s]!.count += 1;
        }
      }

      final List<StrassScore> strassList = strassAgg.entries.map((entry) {
        return StrassScore(
          strass: entry.key,
          score: entry.value.score,
          playerCount: entry.value.count,
        );
      }).toList();

      strassList.sort((a, b) => b.score.compareTo(a.score));

      // 6. Aggrégation par Prom's paires vs impaires
      double evenScore = 0.0;
      int evenCount = 0;
      double oddScore = 0.0;
      int oddCount = 0;

      for (var g in gadzList) {
        if (g.proms != null && g.proms! > 0) {
          if (g.proms! % 2 == 0) {
            evenScore += g.score;
            evenCount += 1;
          } else {
            oddScore += g.score;
            oddCount += 1;
          }
        }
      }

      final List<PromsEvenOddScore> promsEvenOddList = [
        PromsEvenOddScore(
          groupName: "Prom's paires",
          score: evenScore,
          playerCount: evenCount,
          isEven: true,
        ),
        PromsEvenOddScore(
          groupName: "Prom's impaires",
          score: oddScore,
          playerCount: oddCount,
          isEven: false,
        ),
      ];

      promsEvenOddList.sort((a, b) => b.score.compareTo(a.score));

      // 7. Aggrégation PG / JP / TVA
      final int currentYear = DateTime.now().year;
      double pgScore = 0.0;
      int pgCount = 0;
      double jpScore = 0.0;
      int jpCount = 0;
      double tvaScore = 0.0;
      int tvaCount = 0;

      for (var g in gadzList) {
        if (g.proms != null && g.proms! > 0) {
          final int p = g.proms!;
          final int promsYear = _getPromsYear(p);

          if (promsYear > currentYear - 3) {
            pgScore += g.score;
            pgCount += 1;
          } else if (promsYear > currentYear - 13) {
            jpScore += g.score;
            jpCount += 1;
          } else {
            tvaScore += g.score;
            tvaCount += 1;
          }
        }
      }

      final List<PgJpTvaScore> pgJpTvaList = [
        PgJpTvaScore(
          groupName: "PG",
          score: pgScore,
          playerCount: pgCount,
          groupKey: "PG",
        ),
        PgJpTvaScore(
          groupName: "JP",
          score: jpScore,
          playerCount: jpCount,
          groupKey: "JP",
        ),
        PgJpTvaScore(
          groupName: "TVA",
          score: tvaScore,
          playerCount: tvaCount,
          groupKey: "TVA",
        ),
      ];

      pgJpTvaList.sort((a, b) => b.score.compareTo(a.score));

      if (mounted) {
        setState(() {
          _gadzScores = gadzList;
          _famsScores = famsList;
          _tabagnsScores = tabagnsList;
          _promsScores = promsList;
          _strassScores = strassList;
          _promsEvenOddScores = promsEvenOddList;
          _pgJpTvaScores = pgJpTvaList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du leaderboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Impossible de charger le classement Zprom's.";
        });
      }
    }
  }

  int _getPromsYear(int proms) {
    if (proms >= 1000) return proms;
    if (proms >= 200) {
      return 2000 + (proms % 100);
    } else {
      return 1900 + (proms % 100);
    }
  }

  void _showGroupPlayersDialog(String groupTitle, List<GadzScore> players) {
    final String dialogTitle = (groupTitle == "PG" || groupTitle == "JP" || groupTitle == "TVA")
        ? "Gadz $groupTitle"
        : "Gadz de $groupTitle";

    final currentUserId = _supabase.auth.currentUser?.id;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: players.isEmpty
                ? const Text("Aucun membre dans ce groupe.")
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      return GadzScoreTile(
                        gadz: player,
                        leading: CircleAvatar(
                          child: Text('#${index + 1}', style: const TextStyle(fontSize: 12)),
                        ),
                        isMe: player.userId == currentUserId,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  String _formatScore(double score) {
    return score.round().toString();
  }

  Widget _buildRankWidget(int index) {
    if (index == 0) {
      return const CircleAvatar(
        backgroundColor: Color(0xFFFFD700), // Or
        foregroundColor: Colors.black,
        child: Text('🥇', style: TextStyle(fontSize: 20)),
      );
    } else if (index == 1) {
      return const CircleAvatar(
        backgroundColor: Color(0xFFC0C0C0), // Argent
        foregroundColor: Colors.black,
        child: Text('🥈', style: TextStyle(fontSize: 20)),
      );
    } else if (index == 2) {
      return const CircleAvatar(
        backgroundColor: Color(0xFFCD7F32), // Bronze
        foregroundColor: Colors.white,
        child: Text('🥉', style: TextStyle(fontSize: 20)),
      );
    }
    return CircleAvatar(
      backgroundColor: Colors.grey.shade200,
      foregroundColor: Colors.black87,
      child: Text(
        '#${index + 1}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildTopGadzView() {
    if (_gadzScores.isEmpty) {
      return Center(
        child: const Text("Aucun Gadz's enregistré.", style: TextStyle(fontSize: 16)),
      );
    }

    final currentUserId = _supabase.auth.currentUser?.id;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _gadzScores.length,
      itemBuilder: (context, index) {
        final item = _gadzScores[index];
        final isMe = item.userId == currentUserId;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: isMe ? 3 : 1,
          color: isMe ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
          child: GadzScoreTile(
            gadz: item,
            leading: _buildRankWidget(index),
            isMe: isMe,
          ),
        );
      },
    );
  }

  Widget _buildTopFamsView() {
    if (_famsScores.isEmpty) {
      return const Center(
        child: Text(
          "Aucune fam's enregistrée.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final currentUserId = _supabase.auth.currentUser?.id;
    final myGadz = _gadzScores.cast<GadzScore?>().firstWhere(
          (g) => g?.userId == currentUserId,
          orElse: () => null,
        );
    final myFams = myGadz?.fams;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _famsScores.length,
      itemBuilder: (context, index) {
        final item = _famsScores[index];
        final isMyFams = myFams != null && myFams.isNotEmpty && myFams == item.fams;

        final famsGroup = item.fams;
        final groupPlayers = _gadzScores.where((g) => g.fams == famsGroup).toList();
        groupPlayers.sort((a, b) => b.score.compareTo(a.score));

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: isMyFams ? 3 : 1,
          color: isMyFams ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
          child: InkWell(
            onTap: () => _showGroupPlayersDialog(item.fams, groupPlayers),
            child: ListTile(
              leading: _buildRankWidget(index),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.fams,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (isMyFams)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text("phy's", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Text("${item.playerCount} ${item.playerCount > 1 ? 'gadz' : 'gadz'}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              trailing: Text(
                '${_formatScore(item.score)} Trad\'s',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopTabagnsView() {
    if (_tabagnsScores.isEmpty) {
      return Center(
        child: Text(
          "Aucun Tabagn's enregistré.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final currentUserId = _supabase.auth.currentUser?.id;
    final myGadz = _gadzScores.cast<GadzScore?>().firstWhere(
          (g) => g?.userId == currentUserId,
          orElse: () => null,
        );
    final myTabagns = myGadz?.tabagns;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _tabagnsScores.length,
      itemBuilder: (context, index) {
        final item = _tabagnsScores[index];
        final fullName = _tabagnsFullNames[item.tabagns] ?? item.tabagns;
        final isMyTabagns = myTabagns != null && myTabagns.isNotEmpty && myTabagns == item.tabagns;

        final tabagnsGroup = item.tabagns;
        final groupPlayers = _gadzScores.where((g) => g.tabagns == tabagnsGroup).toList();
        groupPlayers.sort((a, b) => b.score.compareTo(a.score));

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: isMyTabagns ? 3 : 1,
          color: isMyTabagns ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
          child: InkWell(
            onTap: () => _showGroupPlayersDialog(fullName, groupPlayers),
            child: ListTile(
              leading: _buildRankWidget(index),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (isMyTabagns)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text("phy's", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Text("${item.playerCount} ${item.playerCount > 1 ? 'gadz' : 'gadz'}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              trailing: Text(
                '${_formatScore(item.score)} Trad\'s',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopPromsView() {
    if (_promsScores.isEmpty) {
      return Center(
        child: Text(
          "Aucune Prom's enregistrée.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final currentUserId = _supabase.auth.currentUser?.id;
    final myGadz = _gadzScores.cast<GadzScore?>().firstWhere(
          (g) => g?.userId == currentUserId,
          orElse: () => null,
        );
    final myProms = myGadz?.proms;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _promsScores.length,
      itemBuilder: (context, index) {
        final item = _promsScores[index];
        final isMyProms = myProms != null && myProms == item.proms;

        final promsNumber = item.proms;
        final groupPlayers = _gadzScores.where((g) => g.proms == promsNumber).toList();
        groupPlayers.sort((a, b) => b.score.compareTo(a.score));

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: isMyProms ? 3 : 1,
          color: isMyProms ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
          child: InkWell(
            onTap: () => _showGroupPlayersDialog("Prom's ${item.proms}", groupPlayers),
            child: ListTile(
              leading: _buildRankWidget(index),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Prom\'s ${item.proms}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (isMyProms)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text("phy's", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Text("${item.playerCount} ${item.playerCount > 1 ? 'gadz' : 'gadz'}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              trailing: Text(
                '${_formatScore(item.score)} Trad\'s',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopStrassView() {
    if (_strassScores.isEmpty) {
      return const Center(
        child: Text(
          "Aucune strass enregistré.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final currentUserId = _supabase.auth.currentUser?.id;
    final myGadz = _gadzScores.cast<GadzScore?>().firstWhere(
          (g) => g?.userId == currentUserId,
          orElse: () => null,
        );
    final myStrass = myGadz?.strass;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _strassScores.length,
      itemBuilder: (context, index) {
        final item = _strassScores[index];
        final isMyStrass = myStrass != null && myStrass.isNotEmpty && myStrass == item.strass;

        final strassGroup = item.strass;
        final groupPlayers = _gadzScores.where((g) => g.strass == strassGroup).toList();
        groupPlayers.sort((a, b) => b.score.compareTo(a.score));

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: isMyStrass ? 3 : 1,
          color: isMyStrass ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
          child: InkWell(
            onTap: () => _showGroupPlayersDialog(item.strass, groupPlayers),
            child: ListTile(
              leading: _buildRankWidget(index),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.strass,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (isMyStrass)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text("phy's", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Text("${item.playerCount} ${item.playerCount > 1 ? 'gadz' : 'gadz'}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              trailing: Text(
                '${_formatScore(item.score)} Trad\'s',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildTopPromsEvenOddView() {
    if (_promsEvenOddScores.isEmpty) {
      return const Center(
        child: Text(
          "Aucune donnée de prom's.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final currentUserId = _supabase.auth.currentUser?.id;
    final myGadz = _gadzScores.cast<GadzScore?>().firstWhere(
          (g) => g?.userId == currentUserId,
          orElse: () => null,
        );
    final myProms = myGadz?.proms;
    final myIsEven = myProms != null && myProms > 0 ? (myProms % 2 == 0) : null;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _promsEvenOddScores.length,
      itemBuilder: (context, index) {
        final item = _promsEvenOddScores[index];
        final isMyGroup = myIsEven != null && myIsEven == item.isEven;

        final isEven = item.isEven;
        final groupPlayers = _gadzScores.where((g) => g.proms != null && g.proms! > 0 && (g.proms! % 2 == 0) == isEven).toList();
        groupPlayers.sort((a, b) => b.score.compareTo(a.score));

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: isMyGroup ? 3 : 1,
          color: isMyGroup ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
          child: InkWell(
            onTap: () => _showGroupPlayersDialog(item.groupName, groupPlayers),
            child: ListTile(
              leading: _buildRankWidget(index),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.groupName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (isMyGroup)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text("phy's", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Text("${item.playerCount} ${item.playerCount > 1 ? 'gadz' : 'gadz'}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              trailing: Text(
                '${_formatScore(item.score)} Trad\'s',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPgJpTvaView() {
    if (_pgJpTvaScores.isEmpty) {
      return const Center(
        child: Text(
          "Aucune donnée PG/JP/TVA.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final currentUserId = _supabase.auth.currentUser?.id;
    final myGadz = _gadzScores.cast<GadzScore?>().firstWhere(
          (g) => g?.userId == currentUserId,
          orElse: () => null,
        );
    final myProms = myGadz?.proms;
    String? myGroupKey;
    if (myProms != null && myProms > 0) {
      final int promsYear = _getPromsYear(myProms);
      final int currentYear = DateTime.now().year;
      if (promsYear > currentYear - 3) {
        myGroupKey = "PG";
      } else if (promsYear > currentYear - 13) {
        myGroupKey = "JP";
      } else {
        myGroupKey = "TVA";
      }
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _pgJpTvaScores.length,
      itemBuilder: (context, index) {
        final item = _pgJpTvaScores[index];
        final isMyGroup = myGroupKey != null && myGroupKey == item.groupKey;

        final groupKey = item.groupKey;
        final groupPlayers = _gadzScores.where((g) {
          if (g.proms == null || g.proms! <= 0) return false;
          final year = _getPromsYear(g.proms!);
          final currentYear = DateTime.now().year;
          if (groupKey == "PG") return year > currentYear - 3;
          if (groupKey == "JP") return year > currentYear - 13;
          return year <= currentYear - 13;
        }).toList();
        groupPlayers.sort((a, b) => b.score.compareTo(a.score));

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: isMyGroup ? 3 : 1,
          color: isMyGroup ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
          child: InkWell(
            onTap: () => _showGroupPlayersDialog(item.groupName, groupPlayers),
            child: ListTile(
              leading: _buildRankWidget(index),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.groupName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (isMyGroup)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text("phy's", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Text("${item.playerCount} ${item.playerCount > 1 ? 'gadz' : 'gadz'}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              trailing: Text(
                '${_formatScore(item.score)} Trad\'s',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Chargement du classement Zprom\'s...',
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
              onPressed: _loadLeaderboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 7,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              'Zprom\'s',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(
                icon: Icon(Icons.person),
                text: 'Top gadz',
              ),
              Tab(
                icon: Icon(Icons.family_restroom),
                text: 'Top fam\'s',
              ),
              Tab(
                icon: Icon(Icons.school),
                text: 'Top prom\'s',
              ),
              Tab(
                icon: Icon(Icons.location_city),
                text: 'Top tabagn\'s',
              ),
              Tab(
                icon: Icon(Icons.group),
                text: 'Top strass',
              ),
              Tab(
                icon: Icon(Icons.percent),
                text: 'Paires/impaires',
              ),
              Tab(
                icon: Icon(Icons.elderly),
                text: 'PG/JP/TVA',
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadLeaderboardData,
              child: TabBarView(
                children: [
                  _buildTopGadzView(),
                  _buildTopFamsView(),
                  _buildTopPromsView(),
                  _buildTopTabagnsView(),
                  _buildTopStrassView(),
                  _buildTopPromsEvenOddView(),
                  _buildPgJpTvaView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AggregatedStat {
  double score = 0.0;
  int count = 0;
}
