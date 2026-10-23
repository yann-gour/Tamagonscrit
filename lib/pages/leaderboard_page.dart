import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final ValueNotifier<int> leaderboardRefreshNotifier = ValueNotifier<int>(0);

class GadzScore {
  final String userId;
  final String bucque;
  final String? fams;
  final String? tabagns;
  final int? proms;
  final double score;

  GadzScore({
    required this.userId,
    required this.bucque,
    this.fams,
    this.tabagns,
    this.proms,
    required this.score,
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
  List<TabagnsScore> _tabagnsScores = [];
  List<PromsScore> _promsScores = [];
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

        int? proms;
        if (profile?['proms'] != null) {
          if (profile!['proms'] is int) {
            proms = profile['proms'] as int;
          } else {
            proms = int.tryParse(profile['proms'].toString());
          }
        }

        gadzList.add(GadzScore(
          userId: userId,
          bucque: bucque,
          fams: fams?.isNotEmpty == true ? fams : null,
          tabagns: tabagns?.isNotEmpty == true ? tabagns : null,
          proms: proms,
          score: score,
        ));
      }

      // Tri des gadz par score décroissant
      gadzList.sort((a, b) => b.score.compareTo(a.score));

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
          _tabagnsScores = tabagnsList;
          _promsScores = promsList;
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Membres de $groupTitle (${players.length})"),
          content: SizedBox(
            width: double.maxFinite,
            child: players.isEmpty
                ? const Text("Aucun membre dans ce groupe.")
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('#${index + 1}', style: const TextStyle(fontSize: 12)),
                        ),
                        title: Text(player.bucque, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: player.fams != null && player.fams!.isNotEmpty
                            ? Text("Fam's : ${player.fams}")
                            : null,
                        trailing: Text(
                          "${_formatScore(player.score)} Trad's",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
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
    if (score % 1 == 0) {
      return score.toInt().toString();
    }
    return score.toStringAsFixed(1);
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

        final List<String> details = [];
        if (item.fams != null && item.fams!.isNotEmpty) {
          details.add("Fam's : ${item.fams}");
        }
        if (item.tabagns != null && item.tabagns!.isNotEmpty) {
          details.add("Tabagn's : ${item.tabagns}");
        }
        if (item.proms != null) {
          details.add("Prom's : ${item.proms}");
        }

        final subtitleText = details.isNotEmpty
            ? details.join('  •  ')
            : 'Aucune information additionnelle';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: isMe ? 3 : 1,
          color: isMe ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
          child: ListTile(
            leading: _buildRankWidget(index),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.bucque,
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
                    child: Text("phy's", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Text(
              subtitleText,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            trailing: Text(
              "${_formatScore(item.score)} Trad's",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.orange,
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
            onTap: () => _showGroupPlayersDialog("Groupe ${item.groupName}", groupPlayers),
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
      length: 5,
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
                icon: Icon(Icons.location_city),
                text: 'Top tabagn\'s',
              ),
              Tab(
                icon: Icon(Icons.school),
                text: 'Top prom\'s',
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
                  _buildTopTabagnsView(),
                  _buildTopPromsView(),
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
