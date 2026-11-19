import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audio_service.dart';

class Achievement {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String? imageUrl;
  final Color? customIconColor;
  final Color? customBackgroundColor;
  final int zloeils;
  final String? audioPath;
  final bool isHidden;
  double maxProgress;
  double currentProgress;
  double unlockPercentage;
  bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    this.imageUrl,
    this.customIconColor,
    this.customBackgroundColor,
    this.zloeils = 100,
    this.audioPath,
    this.isHidden = false,
    this.maxProgress = 1.0,
    this.currentProgress = 0.0,
    this.unlockPercentage = 0.0,
    this.isUnlocked = false,
  });
}

final ValueNotifier<int> achievementsRefreshNotifier = ValueNotifier<int>(0);

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  static const String _prefKeyUnlocked = 'unlocked_achievements_v1';

  final List<Achievement> _achievements = [
    Achievement(
      id: 'a_l_ecole',
      title: "A l'Ecole",
      subtitle: "Usiner un conscrit jusqu'à son Zcu",
      description: "Moines dormez sous vos six pieds de terre, \nDormez en paix et vive les Gadz'Arts !",
      icon: Icons.school,
      audioPath: 'ecole.mp3',
    ),
    Achievement(
      id: 'aux_trads',
      title: "Aux Trad's",
      subtitle: "Usiner un conscrit 100% Trad's",
      description: "Chanter bien haut d'une voix triomphale : \nLes Trad's mourront quand mourront les Gadz'Arts !",
      icon: Icons.military_tech,
      audioPath: 'trads.mp3',
      maxProgress: 100,
    ),
    Achievement(
      id: 'aux_sacques',
      title: "Aux Sacqués",
      subtitle: "Faire sacquer son conscrit (24h)",
      description: "Nous chanterons sans soucis de l'orage,\nQue votre action est digne d'un Gadz'Arts !",
      icon: Icons.history,
      audioPath: 'sacques.mp3',
      maxProgress: 24,
    ),
    Achievement(
      id: 'aux_lourdes',
      title: "Aux Lourdés",
      subtitle: "Faire lourder son conscrit (7j)",
      description: "Mais vous aurez une force infinie, \nCar malgré tout vous êtes des Gadz'Arts !",
      icon: Icons.exit_to_app,
      zloeils: 200,
      audioPath: 'lourdes.mp3',
      maxProgress: 168,
    ),
    Achievement(
      id: 'aux_disparus',
      title: "Aux Disparus",
      subtitle: "Disparaître du jeu",
      description: "Car dans nos coeurs sont gravés à jamais, \nCes quelques mots : vous êtes des Gadz'Arts !",
      icon: Icons.heart_broken,
      imageUrl: 'https://img.icons8.com/material/96/skull.png',
      zloeils: 1000,
      audioPath: 'disparus.mp3',
    ),
    Achievement(
      id: 'a_la_fraterns',
      title: "A la Fratern's",
      subtitle: "Avoir 100 gadz dans son monôme",
      description: "Fraternité c'est la notre devise, \nC'est la devise de tous les vrais Gadz'Arts !",
      icon: Icons.groups,
      zloeils: 1000,
      audioPath: 'fraterns.mp3',
      maxProgress: 100,
    ),
    Achievement(
      id: 'a_bacchus',
      title: "A Bacchus",
      subtitle: "Chouiller",
      description: "Ce jus divin qui réjouit la terre, \nN'emplit jamais la coupe d'un Gadz'Arts !",
      icon: Icons.wine_bar,
      audioPath: 'bacchus.mp3',
    ),
    Achievement(
      id: 'monome_ch',
      title: "Le Grand Bastringue",
      subtitle: "Usiner un conscrit à Châlon's",
      description: "On a souvent parlé de la belle vie, que les Gadz'Arts menaient au Tabagnon !",
      icon: Icons.pets,
      imageUrl: 'https://img.icons8.com/external-tanah-basah-glyph-tanah-basah/48/external-boar-animals-tanah-basah-glyph-tanah-basah.png',
      customIconColor: const Color(0xFFFF3333),
      customBackgroundColor: const Color(0xFF1E1E1E),
    ),
    Achievement(
      id: 'monome_an',
      title: "Dans les rues",
      subtitle: "Usiner un conscrit à Boquette",
      description: "Dans les rues que nous traversons en monôme...",
      icon: Icons.pets,
      imageUrl: 'https://img.icons8.com/material/96/falcon.png',
      customIconColor: const Color(0xFF001F54),
      customBackgroundColor: const Color(0xFFD32F2F),
    ),
    Achievement(
      id: 'monome_ai',
      title: "Les Olives",
      subtitle: "Usiner un conscrit à KIN",
      description: "J'ai de belles olives, oui qu'on se le dise !",
      icon: Icons.pets,
      imageUrl: 'https://img.icons8.com/material/96/dolphin.png',
      customIconColor: const Color(0xFF001F54),
      customBackgroundColor: const Color(0xFF81D4FA),
    ),
    Achievement(
      id: 'monome_cl',
      title: "En monôme !",
      subtitle: "Usiner un conscrit à Clun's",
      description: "Formez l'monôme, formez l'monôme !",
      icon: Icons.pets,
      imageUrl: 'https://img.icons8.com/material/96/year-of-goat.png',
      customIconColor: const Color(0xFF001F54),
      customBackgroundColor: const Color(0xFFFFEB3B),
    ),
    Achievement(
      id: 'monome_li',
      title: "Monôme de Birse",
      subtitle: "Usiner un conscrit à Birse",
      description: "Entre ces murs, résonnent les voix du passé !",
      icon: Icons.pets,
      imageUrl: 'https://img.icons8.com/material/96/bear.png',
      customIconColor: const Color(0xFF0B4F26),
      customBackgroundColor: const Color(0xFFFFFFFF),
    ),
    Achievement(
      id: 'monome_bo',
      title: "Monôme de Bordel's",
      subtitle: "Usiner un conscrit à Bordel's",
      description: "Non ce n'est pas l'amphi...",
      icon: Icons.pets,
      imageUrl: 'https://img.icons8.com/material/96/bull.png',
      customIconColor: const Color(0xFF121212),
      customBackgroundColor: const Color(0xFFD32F2F),
    ),
    Achievement(
      id: 'monome_me',
      title: "Monôme de Siber's",
      subtitle: "Usiner un conscrit à Siber's",
      description: "Dans le froid du grand nord d'la Lorraine...",
      icon: Icons.pets,
      imageUrl: 'https://img.icons8.com/material/96/wolf.png',
      customIconColor: const Color(0xFF311B92),
      customBackgroundColor: const Color(0xFF800020),
    ),
    Achievement(
      id: 'uai',
      title: "L'UAI a des athlètes !",
      subtitle: "Usiner un Zt UAI de chaque tabagn's",
      description: "L'UAI a des athlètes, qui connaissent le prix de l'effort !",
      icon: Icons.sports_score,
      zloeils: 500,
      maxProgress: 7,
    ),
    Achievement(
      id: 'colon',
      title: ".o.o.",
      subtitle: "U.i.e. u. .o.o.",
      description: ".o...i.. e. .o.o.e !",
      icon: Symbols.elderly,
      isHidden: true,
    ),
    Achievement(
      id: 'commits',
      title: "Aux Trad's (bis)",
      subtitle: "Usiner 1 MT et 4 FT",
      description: "Sonnez clairons aux notes éclatantes !",
      icon: Icons.groups,
      zloeils: 600,
      maxProgress: 5,
    ),
    Achievement(
      id: 'trident',
      title: "Trident",
      subtitle: "Usiner 1 MT, 1 Zt AE et 1 ME",
      description: "C'est mieux qu'une fourchette ?",
      icon: Symbols.fork_spoon,
      imageUrl: 'https://img.icons8.com/fluency-systems-filled/96/trident.png',
      zloeils: 500,
      maxProgress: 3,
    ),
    Achievement(
      id: 'brousouf',
      title: "Archi brousouf",
      subtitle: "Gagner 1 000 000 brousoufs",
      description: "Brousouf comme crésu's !",
      icon: Icons.savings,
      imageUrl: 'https://img.icons8.com/material/96/money-box--v1.png',
      zloeils: 1000,
      maxProgress: 1000000,
    ),
    Achievement(
      id: 'zt2',
      title: "Zt UE",
      subtitle: "Usiner 1 Zt de chaque tabagn's",
      description: "Validée l'UE !",
      icon: Symbols.chess_rook,
      imageUrl: 'https://img.icons8.com/material/96/rook.png',
      zloeils: 1000,
      maxProgress: 7,
    ),
    Achievement(
      id: 'mt2',
      title: "MT²",
      subtitle: "Usiner 1 MT de chaque tabagn's",
      description: "Validée l'UE !",
      icon: Symbols.chess_bishop,
      imageUrl: 'https://img.icons8.com/material/96/bishop.png',
      zloeils: 1000,
      maxProgress: 7,
    ),
    Achievement(
      id: 'me2',
      title: "MEME",
      subtitle: "Usiner 1 ME de chaque tabagn's",
      description: "Validée l'UE !",
      icon: Symbols.chess_knight,
      imageUrl: 'https://img.icons8.com/material/96/knight.png',
      zloeils: 1000,
      maxProgress: 7,
    ),
    Achievement(
      id: 'crapaud',
      title: "Crapaud",
      subtitle: "Usiner un conscrit sans Trad's",
      description: "Le mot crapaud est un nom vernaculaire ambigu qui est donné en français à plus de 500 différentes espèces d'amphibiens anoures, les Bufonidae et notamment parmi eux, les représentants du genre Bufo, genre le mieux représenté sur la planète avec plus de 250 espèces.",
      icon: Icons.pets,
      imageUrl: 'https://img.icons8.com/ios-glyphs/90/frog.png',
      customIconColor: const Color(0xFF2E7D32),
      zloeils: 10,
    ),
    Achievement(
      id: '508',
      title: "508",
      subtitle: "Usiner à 5h08",
      description: "5h08 c'est les 508 !",
      icon: Symbols.nest_clock_farsight_analog,
      //imageUrl: 'https://img.icons8.com/material/96/invert-selection--v1.png',
      isHidden: true,
    ),
    Achievement(
      id: 'bn',
      title: "BN",
      subtitle: "Tricher",
      description: "Si vous voyez rôder dans cette enceinte, \nNe craignez rien car ce sont des Gadz'Arts !",
      icon: Symbols.help,
      imageUrl: 'https://img.icons8.com/material/96/ski-mask.png',
      isHidden: true,
    ),
    Achievement(
      id: 'le_duc',
      title: "Le Duc",
      subtitle: "Finir les autres pages du carn's",
      description: "Aider tout ce qui est utile, \nAttacher son nom à tout ce qui est bon",
      icon: Icons.workspace_premium,
      zloeils: 1000000,
      maxProgress: 25,
    ),
  ];

  bool _isLoaded = false;

  List<Achievement> get achievements => _achievements;

  int get unlockedCount => _achievements.where((a) => a.isUnlocked).length;

  int get totalZloeils => _achievements
      .where((a) => a.isUnlocked)
      .fold(0, (sum, a) => sum + a.zloeils);

  Future<void> loadAchievements() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final prefs = await SharedPreferences.getInstance();

      final String prefKey = user != null
          ? 'unlocked_achievements_${user.id}'
          : 'unlocked_achievements_v1';

      final List<String> unlockedIds = prefs.getStringList(prefKey) ?? prefs.getStringList(_prefKeyUnlocked) ?? [];

      // Charger aussi depuis Supabase metadata si disponible
      final metadata = user?.userMetadata ?? {};
      final List<dynamic> remoteUnlocked = metadata['achievements'] as List<dynamic>? ?? [];
      for (var id in remoteUnlocked) {
        final idStr = id.toString();
        if (!unlockedIds.contains(idStr)) {
          unlockedIds.add(idStr);
        }
      }

      // Charger depuis la table profiles de Supabase si disponible
      if (user != null) {
        try {
          final profileRes = await Supabase.instance.client
              .from('profiles')
              .select('achievements')
              .eq('id', user.id)
              .maybeSingle();
          if (profileRes != null && profileRes['achievements'] != null) {
            final List<dynamic> tableUnlocked = profileRes['achievements'] as List<dynamic>;
            for (var id in tableUnlocked) {
              final idStr = id.toString();
              if (!unlockedIds.contains(idStr)) {
                unlockedIds.add(idStr);
              }
            }
          }
        } catch (e) {
          debugPrint('Erreur chargement table profiles achievements: $e');
        }
      }

      double maxTrads = 0.0;
      double maxDurationHours = 0.0;
      double currentBrousoufs = 0.0;
      int monomeCount = 0;

      final Set<String> uaiTabagns = {};
      final Set<String> mt2Tabagns = {};
      final Set<String> zt2Tabagns = {};
      final Set<String> me2Tabagns = {};
      int tridentMt = 0;
      int tridentZtAe = 0;
      int tridentMe = 0;
      int mtCount = 0;
      int ftCount = 0;

      // Auto-récupération intelligente basée sur la base de données Supabase du joueur
      if (user != null) {
        try {
          // 1. Conscrits terminés du joueur
          final conscritsResponse = await Supabase.instance.client
              .from('conscrits')
              .select()
              .eq('user_id', user.id);
          final List<Map<String, dynamic>> conscritsData =
              List<Map<String, dynamic>>.from(conscritsResponse);

          monomeCount = conscritsData.length;

          if (conscritsData.isNotEmpty) {
            // S'il a au moins un conscrit terminé, il a eu 100 en birse ("A l'Ecole")
            if (!unlockedIds.contains('a_l_ecole')) unlockedIds.add('a_l_ecole');

            for (var c in conscritsData) {
              final trads = (c['trads'] as num?)?.toDouble() ?? 0.0;
              if (trads > maxTrads) maxTrads = trads;

              final durSeconds = (c['duration_seconds'] as num?)?.toDouble() ?? 0.0;
              final durHours = durSeconds / 3600.0;
              if (durHours > maxDurationHours) maxDurationHours = durHours;

              final b = c['bools']?.toString();
              final t = c['tabagns']?.toString();

              if (b == 'MT') {
                mtCount++;
                tridentMt++;
                if (t != null) mt2Tabagns.add(t);
              }
              if (b == 'FT') {
                ftCount++;
              }
              if (b == 'Zt AE') {
                tridentZtAe++;
                if (t != null) zt2Tabagns.add(t);
              }
              if (b == 'ME') {
                tridentMe++;
                if (t != null) me2Tabagns.add(t);
              }
              if (b == 'Zt UAI' && t != null) {
                uaiTabagns.add(t);
              }

              if (trads >= 100.0 && !unlockedIds.contains('aux_trads')) {
                unlockedIds.add('aux_trads');
              }
              if (trads <= 0.0 && !unlockedIds.contains('crapaud')) {
                unlockedIds.add('crapaud');
              }
              if (t != null) {
                final tabagnsMap = {
                  'Ch': 'monome_ch',
                  'An': 'monome_an',
                  'Ai': 'monome_ai',
                  'Cl': 'monome_cl',
                  'Li': 'monome_li',
                  'Bo': 'monome_bo',
                  'Me': 'monome_me',
                };
                final achievId = tabagnsMap[t];
                if (achievId != null && !unlockedIds.contains(achievId)) {
                  unlockedIds.add(achievId);
                }
              }
              if (b == 'MT' && t == 'Ch' && !unlockedIds.contains('colon')) {
                unlockedIds.add('colon');
              }
            }

            if (monomeCount >= getMaxProgress('a_la_fraterns') && !unlockedIds.contains('a_la_fraterns')) {
              unlockedIds.add('a_la_fraterns');
            }
            if (uaiTabagns.length >= getMaxProgress('uai') && !unlockedIds.contains('uai')) {
              unlockedIds.add('uai');
            }
            if (mt2Tabagns.length >= getMaxProgress('mt2') && !unlockedIds.contains('mt2')) {
              unlockedIds.add('mt2');
            }
            if (zt2Tabagns.length >= getMaxProgress('zt2') && !unlockedIds.contains('zt2')) {
              unlockedIds.add('zt2');
            }
            if (me2Tabagns.length >= getMaxProgress('me2') && !unlockedIds.contains('me2')) {
              unlockedIds.add('me2');
            }
            if (tridentMt >= 1 && tridentZtAe >= 1 && tridentMe >= 1 && !unlockedIds.contains('trident')) {
              unlockedIds.add('trident');
            }
            if (mtCount >= 1 && ftCount >= 4 && !unlockedIds.contains('commits')) {
              unlockedIds.add('commits');
            }
          }

          // 2. État du conscrit en cours
          final stateResponse = await Supabase.instance.client
              .from('conscrit_state')
              .select()
              .eq('user_id', user.id)
              .maybeSingle();

          if (stateResponse != null) {
            final birse = (stateResponse['birse'] as num?)?.toDouble() ?? 0.0;
            final trads = (stateResponse['trads'] as num?)?.toDouble() ?? 0.0;
            final brousoufs = (stateResponse['brousoufs'] as num?)?.toDouble() ?? 0.0;
            final activity = stateResponse['activity']?.toString();
            final startTimeStr = stateResponse['start_time']?.toString();

            currentBrousoufs = brousoufs;
            if (trads > maxTrads) maxTrads = trads;

            if (startTimeStr != null && startTimeStr.isNotEmpty) {
              final startTime = DateTime.tryParse(startTimeStr);
              if (startTime != null) {
                final elapsedHours = DateTime.now().toUtc().difference(startTime).inSeconds / 3600.0;
                if (elapsedHours > maxDurationHours) maxDurationHours = elapsedHours;
              }
            }

            if (birse >= 100.0 && !unlockedIds.contains('a_l_ecole')) {
              unlockedIds.add('a_l_ecole');
            }
            if (trads >= getMaxProgress('aux_trads') && !unlockedIds.contains('aux_trads')) {
              unlockedIds.add('aux_trads');
            }
            if (brousoufs >= getMaxProgress('brousouf') && !unlockedIds.contains('brousouf')) {
              unlockedIds.add('brousouf');
            }
            if (maxDurationHours >= getMaxProgress('aux_sacques') && !unlockedIds.contains('aux_sacques')) {
              unlockedIds.add('aux_sacques');
            }
            if (maxDurationHours >= getMaxProgress('aux_lourdes') && !unlockedIds.contains('aux_lourdes')) {
              unlockedIds.add('aux_lourdes');
            }
            if (activity == 'chouille' && !unlockedIds.contains('a_bacchus')) {
              unlockedIds.add('a_bacchus');
            }
          }
        } catch (e) {
          debugPrint('Erreur auto-récupération des succès depuis Supabase: $e');
        }
      }

      int commitsProgress = (mtCount > 0 ? 1 : 0) + (ftCount > 4 ? 4 : ftCount);
      int tridentProgress = (tridentMt > 0 ? 1 : 0) + (tridentZtAe > 0 ? 1 : 0) + (tridentMe > 0 ? 1 : 0);
      int otherUnlockedCount = unlockedIds.where((id) => id != 'le_duc').length;

      for (var achievement in _achievements) {
        if (achievement.id == 'le_duc') {
          achievement.maxProgress = (_achievements.length - 1).toDouble();
        }

        achievement.isUnlocked = unlockedIds.contains(achievement.id);

        if (achievement.isUnlocked) {
          achievement.currentProgress = achievement.maxProgress;
        } else {
          switch (achievement.id) {
            case 'le_duc':
              achievement.currentProgress = otherUnlockedCount.toDouble().clamp(0.0, achievement.maxProgress);
              break;
            case 'aux_trads':
              achievement.currentProgress = maxTrads.clamp(0.0, achievement.maxProgress);
              break;
            case 'aux_sacques':
              achievement.currentProgress = maxDurationHours.clamp(0.0, achievement.maxProgress);
              break;
            case 'aux_lourdes':
              achievement.currentProgress = maxDurationHours.clamp(0.0, achievement.maxProgress);
              break;
            case 'a_la_fraterns':
              achievement.currentProgress = monomeCount.toDouble().clamp(0.0, achievement.maxProgress);
              break;
            case 'uai':
              achievement.currentProgress = uaiTabagns.length.toDouble().clamp(0.0, achievement.maxProgress);
              break;
            case 'mt2':
              achievement.currentProgress = mt2Tabagns.length.toDouble().clamp(0.0, achievement.maxProgress);
              break;
            case 'zt2':
              achievement.currentProgress = zt2Tabagns.length.toDouble().clamp(0.0, achievement.maxProgress);
              break;
            case 'me2':
              achievement.currentProgress = me2Tabagns.length.toDouble().clamp(0.0, achievement.maxProgress);
              break;
            case 'commits':
              achievement.currentProgress = commitsProgress.toDouble().clamp(0.0, achievement.maxProgress);
              break;
            case 'trident':
              achievement.currentProgress = tridentProgress.toDouble().clamp(0.0, achievement.maxProgress);
              break;
            case 'brousouf':
              achievement.currentProgress = currentBrousoufs.clamp(0.0, achievement.maxProgress);
              break;
            default:
              achievement.currentProgress = 0.0;
              break;
          }
        }
      }

      // Calcul des statistiques globales pour chaque succès depuis la table profiles Supabase
      try {
        final profilesRes = await Supabase.instance.client
            .from('profiles')
            .select('achievements');
        final List<dynamic> profilesList = profilesRes as List<dynamic>;
        final int totalProfiles = profilesList.length;
        if (totalProfiles > 0) {
          final Map<String, int> counts = {};
          for (var p in profilesList) {
            final List<dynamic> userAchievs = (p['achievements'] as List<dynamic>?) ?? [];
            for (var id in userAchievs) {
              final idStr = id.toString();
              counts[idStr] = (counts[idStr] ?? 0) + 1;
            }
          }
          for (var achievement in _achievements) {
            final count = counts[achievement.id] ?? 0;
            achievement.unlockPercentage = (count / totalProfiles) * 100.0;
          }
        }
      } catch (e) {
        debugPrint('Erreur lors du calcul des statistiques globales de succès: $e');
      }

      // Vérifier le succès ultime "Le Duc"
      final allOthersUnlocked = _achievements
          .where((a) => a.id != 'le_duc')
          .every((a) => a.isUnlocked);
      if (allOthersUnlocked) {
        final duc = _achievements.firstWhere((a) => a.id == 'le_duc');
        duc.isUnlocked = true;
        if (!unlockedIds.contains('le_duc')) {
          unlockedIds.add('le_duc');
        }
      }

      // Sauvegarder localement et à distance
      await prefs.setStringList(prefKey, unlockedIds);
      await prefs.setStringList(_prefKeyUnlocked, unlockedIds);

      if (user != null) {
        await _syncAchievementsToSupabase(user.id, unlockedIds);
      }

      _isLoaded = true;
      achievementsRefreshNotifier.value++;
    } catch (e) {
      debugPrint('Erreur lors du chargement des succès: $e');
    }
  }

  Future<void> _syncAchievementsToSupabase(String userId, List<String> unlockedIds) async {
    final currentZloeils = totalZloeils;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final existingData = Map<String, dynamic>.from(user.userMetadata ?? {});
        existingData['achievements'] = unlockedIds;
        existingData['zloeils'] = currentZloeils;
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: existingData),
        );
      }
    } catch (e) {
      debugPrint('Erreur synchro Supabase userMetadata: $e');
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final bucque = user?.userMetadata?['bucque']?.toString() ?? '';
      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'bucque': bucque,
        'achievements': unlockedIds,
        'zloeils': currentZloeils,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Note: Synchro table profiles achievements: $e');
    }
  }

  double getMaxProgress(String achievementId) {
    try {
      final a = _achievements.firstWhere((a) => a.id == achievementId);
      return a.maxProgress;
    } catch (_) {
      return 1.0;
    }
  }

  bool isUnlocked(String achievementId) {
    final achievement = _achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => Achievement(id: '', title: '', subtitle: '', description: '', icon: Icons.help),
    );
    return achievement.isUnlocked;
  }

  Future<void> unlockAndShowPopup(BuildContext context, String achievementId) async {
    if (!_isLoaded) {
      await loadAchievements();
    }

    final achievement = _achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => Achievement(id: '', title: '', subtitle: '', description: '', icon: Icons.help),
    );

    if (achievement.id.isEmpty || achievement.isUnlocked) {
      return; // Déjà débloqué ou inconnu
    }

    // Marquer comme débloqué
    achievement.isUnlocked = true;

    // Persistance locale avec clé utilisateur
    final user = Supabase.instance.client.auth.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final String prefKey = user != null
        ? 'unlocked_achievements_${user.id}'
        : 'unlocked_achievements_v1';

    final List<String> unlockedIds = prefs.getStringList(prefKey) ?? prefs.getStringList(_prefKeyUnlocked) ?? [];
    if (!unlockedIds.contains(achievementId)) {
      unlockedIds.add(achievementId);
      await prefs.setStringList(prefKey, unlockedIds);
      await prefs.setStringList(_prefKeyUnlocked, unlockedIds);
    }

    // Persistance distante immédiate (Supabase userMetadata + table profiles)
    if (user != null) {
      await _syncAchievementsToSupabase(user.id, unlockedIds);
    }

    achievementsRefreshNotifier.value++;

    // Jouer le son du succès s'il est débloqué et s'il existe
    if (achievement.isUnlocked && achievement.audioPath != null) {
      AudioService.playAchievementSound(achievement.audioPath!);
    }

    // Afficher le popup
    if (context.mounted) {
      _showAchievementDialog(context, achievement);
    }

    // Vérifier si tous les autres succès sont débloqués pour déclencher "Le Duc"
    if (achievementId != 'le_duc') {
      final allOthersUnlocked = _achievements
          .where((a) => a.id != 'le_duc')
          .every((a) => a.isUnlocked);
      if (allOthersUnlocked && context.mounted) {
        await unlockAndShowPopup(context, 'le_duc');
      }
    }
  }

  void _showAchievementDialog(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              achievement.imageUrl != null
                  ? ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        achievement.customIconColor ?? Colors.amber,
                        BlendMode.srcIn,
                      ),
                      child: Image.network(
                        achievement.imageUrl!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                      ),
                    )
                  : const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Nouvelle page de carn's !",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (achievement.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  achievement.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.diamond, color: Colors.cyan, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '+${achievement.zloeils} Zloeils',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.cyan,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                achievement.description,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Frat's !"),
            ),
          ],
        );
      },
    );
  }
}
