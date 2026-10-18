import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:typed_data';
import '../utils/color_processor.dart';
import '../utils/color_palettes.dart';
import '../widgets/sprite_sheet_animator.dart';

class ConscritPage extends StatefulWidget {
  const ConscritPage({super.key});

  @override
  State<ConscritPage> createState() => _ConscritPageState();
}

class _ConscritPageState extends State<ConscritPage> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  double _energie = 100.0;
  double _birse = 0.0;
  double _trads = 0.0;
  DateTime? _startTime;
  String _currentImage = 'conscrit.png';
  String _activity = 'idle';

  Color _skinColor = ColorPalettes.getRandomSkinColor();
  Color _hairColor = ColorPalettes.getRandomHairColor();
  Color _tshirtColor = ColorPalettes.getRandomClothesColor();
  Color _pantsColor = ColorPalettes.getRandomClothesColor();
  
  Map<String, Uint8List> _imageCache = {};
  bool _isProcessingImages = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchConscritState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _saveStateToSupabase(); // Sauvegarde finale en quittant
    super.dispose();
  }

  Future<void> _fetchConscritState() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('conscrit_state')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data == null) {
        // Création de l'état par défaut si inexistant
        await _supabase.from('conscrit_state').insert({
          'user_id': user.id,
          'energie': 100.0,
          'birse': 0.0,
          'trads': 0.0,
          'current_gif': 'conscrit.png',
          'activity': 'idle',
          'start_time': null,
          'skin_color': ColorProcessor.colorToHex(_skinColor),
          'hair_color': ColorProcessor.colorToHex(_hairColor),
          'tshirt_color': ColorProcessor.colorToHex(_tshirtColor),
          'pants_color': ColorProcessor.colorToHex(_pantsColor),
        });
        _startTimer();
      } else {
        setState(() {
          _energie = (data['energie'] as num).toDouble();
          _birse = (data['birse'] as num).toDouble();
          _trads = (data['trads'] as num).toDouble();
          
          // Compatibilité : si c'est encore un gif en DB, on force le png
          String gifFromDb = data['current_gif'] as String;
          _currentImage = gifFromDb.replaceAll('.gif', '.png');
          
          _activity = data['activity'] as String;
          _startTime = data['start_time'] != null
              ? DateTime.parse(data['start_time'])
              : null;

          if (data['skin_color'] != null) {
            _skinColor = ColorProcessor.colorFromHex(data['skin_color']);
          }
          if (data['hair_color'] != null) {
            _hairColor = ColorProcessor.colorFromHex(data['hair_color']);
          }
          if (data['tshirt_color'] != null) {
            _tshirtColor = ColorProcessor.colorFromHex(data['tshirt_color']);
          }
          if (data['pants_color'] != null) {
            _pantsColor = ColorProcessor.colorFromHex(data['pants_color']);
          }
        });

        // Calcul du temps passé hors-ligne
        if (data['last_updated'] != null) {
          final lastUpdated = DateTime.parse(data['last_updated']);
          final now = DateTime.now().toUtc();
          final differenceInSeconds = now.difference(lastUpdated).inSeconds;

          if (differenceInSeconds > 0 && _activity != 'idle') {
            _applyOfflineProgress(differenceInSeconds);
          }
        }

        if (_birse >= 100.0) {
          _showCongratulations();
        } else {
          _startTimer();
        }
      }
      
      // On lance la pré-génération de TOUTES les images
      await _preloadAllImages();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de synchronisation.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _preloadAllImages() async {
    if (_isProcessingImages) return;
    setState(() {
      _isProcessingImages = true;
    });

    final newCache = await ColorProcessor.processAllImagesInBackground(
      newSkinColor: _skinColor,
      newHairColor: _hairColor,
      newTshirtColor: _tshirtColor,
      newPantsColor: _pantsColor,
      isBiaudeWhite: _birse >= 50.0,
    );

    if (mounted) {
      setState(() {
        _imageCache = newCache;
        _isProcessingImages = false;
      });
    }
  }

  void _applyOfflineProgress(int seconds) {
    // Applique les gains/pertes cumulés pendant l'absence
    _processTick(secondsMultiplier: seconds.toDouble());
    // On force une sauvegarde pour enregistrer ce rattrapage
    _saveStateToSupabase();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activity != 'idle') {
        setState(() {
          _processTick(secondsMultiplier: 1.0);
          if (_birse >= 100.0) {
            _showCongratulations();
          }
        });
      }
    });
  }

  void _processTick({required double secondsMultiplier}) {
    double rateEnergie = 0;
    double rateBirse = 0;
    double rateTrads = 0;

    switch (_activity) {
      case 'birse':
        rateEnergie = -1.0;
        rateBirse = 1.5;
        rateTrads = -1.5;
        break;
      case 'ronque':
        rateEnergie = 2.5;
        break;
      case 'monome':
        rateEnergie = -1.5;
        rateTrads = 1.5;
        break;
      case 'idle':
      default:
        return;
    }

    double effectiveSeconds = secondsMultiplier;
    bool shouldGoIdle = false;
    double limitSeconds =
        double.infinity; // Utilisation de l'infini au lieu de null

    // 1. Limite d'énergie à 0
    if (rateEnergie < 0) {
      double t = _energie / (-rateEnergie);
      if (t < limitSeconds) limitSeconds = t;
    }
    // 2. Limite d'énergie à 100
    else if (rateEnergie > 0) {
      double t = (100.0 - _energie) / rateEnergie;
      if (t < limitSeconds) limitSeconds = t;
    }

    // 3. Limite de Birse à 100
    if (rateBirse > 0) {
      double t = (100.0 - _birse) / rateBirse;
      if (t < limitSeconds) limitSeconds = t;
    }

    // 4. Limite de Trad's à 100
    if (rateTrads > 0) {
      double t = (100.0 - _trads) / rateTrads;
      if (t < limitSeconds) limitSeconds = t;
    }

    // Si une des limites est atteinte dans le temps imparti
    if (limitSeconds != double.infinity && secondsMultiplier >= limitSeconds) {
      effectiveSeconds = limitSeconds;
      shouldGoIdle = true;
    }

    _energie = (_energie + (rateEnergie * effectiveSeconds)).clamp(0.0, 100.0);
    _birse = (_birse + (rateBirse * effectiveSeconds)).clamp(0.0, 100.0);
    _trads = (_trads + (rateTrads * effectiveSeconds)).clamp(0.0, 100.0);

    // Vérifier si Birse atteint 100
    if (_birse >= 100.0) {
      _activity = 'idle';
      _currentImage = 'conscrit.png';
      _timer?.cancel();
      return;
    }

    // Retour à l'état de repos si la condition d'arrêt est atteinte
    if (shouldGoIdle) {
      _activity = 'idle';
      _currentImage = 'conscrit.png';
      _saveStateToSupabase();
    }
    
    // Mettre à jour l'image si on passe le cap des 50 birse (biaude blanche)
    // On vérifie le changement d'état pour ne pas le faire à chaque tick
    final wasBelow50 = (_birse - (rateBirse * effectiveSeconds)) < 50.0;
    if (wasBelow50 && _birse >= 50.0) {
      _show100JoursPopup();
    }
  }

  Future<void> _saveStateToSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('conscrit_state').upsert({
        'user_id': user.id,
        'energie': _energie,
        'birse': _birse,
        'trads': _trads,
        'current_gif': _currentImage,
        'activity': _activity,
        'start_time': _startTime?.toIso8601String(),
        'skin_color': ColorProcessor.colorToHex(_skinColor),
        'hair_color': ColorProcessor.colorToHex(_hairColor),
        'tshirt_color': ColorProcessor.colorToHex(_tshirtColor),
        'pants_color': ColorProcessor.colorToHex(_pantsColor),
        // last_updated est géré automatiquement par le trigger Supabase ou default now() si update classique
      });
    } catch (e) {
      debugPrint('Erreur de sauvegarde: $e');
    }
  }

  void _showExhaustedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Conscrit épuisé !'),
          content: const Text(
            'Ton conscrit n\'a plus d\'énergie ! Il doit ronquer pour se reposer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _toggleActivity(String newActivity, String newImage) {
    if (_energie <= 0 && (newActivity == 'birse' || newActivity == 'monome')) {
      _showExhaustedDialog();
      return;
    }

    setState(() {
      if (_startTime == null && newActivity != 'idle') {
        _startTime = DateTime.now().toUtc();
      }

      if (_activity == newActivity) {
        // Clic sur l'activité en cours : on arrête tout
        _activity = 'idle';
        _currentImage = 'conscrit.png';
      } else {
        // Changement d'activité
        _activity = newActivity;
        _currentImage = newImage;
      }
    });
    // Plus besoin de recalculer l'image, elle est déjà dans _imageCache !
    // On sauvegarde l'état en base de données dès qu'on change d'activité
    _saveStateToSupabase();
  }

  void _showCongratulations() {
    if (!mounted) return;

    final int seconds = _startTime != null
        ? DateTime.now().toUtc().difference(_startTime!).inSeconds
        : 0;

    String def;
    if (_trads < 10) {
      def = "crapaud";
    } else if (_trads < 30) {
      def = "pek's";
    } else if (_trads < 70) {
      def = "trad's";
    } else {
      def = "ber's";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Félicitations !'),
          content: Text(
            'Bravo ! Ton conscrit a eu son Zcu en $seconds secondes et est $def !',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetState();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _show100JoursPopup() {
    if (!mounted) return;

    // Met le conscrit au repos (stoppe la jauge de trad's pour éviter des bugs)
    setState(() {
      _activity = 'idle';
      _currentImage = 'conscrit.png';
    });
    _timer?.cancel();
    _saveStateToSupabase();

    // On lance la génération des assets avec la biaude blanche
    // Le spinner tournera sous le popup
    _preloadAllImages();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("C'est les 100 jours !"),
          content: const Text("Ton conscrit a obtenu sa blanche !"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Relancer le timer d'idle
                _startTimer();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _resetState() {
    setState(() {
      _energie = 100.0;
      _birse = 0.0;
      _trads = 0.0;
      _activity = 'idle';
      _currentImage = 'conscrit.png';
      _startTime = null;
      _skinColor = ColorPalettes.getRandomSkinColor();
      _hairColor = ColorPalettes.getRandomHairColor();
      _tshirtColor = ColorPalettes.getRandomClothesColor();
      _pantsColor = ColorPalettes.getRandomClothesColor();
    });
    // On génère les 4 nouvelles images en arrière-plan
    _preloadAllImages();
    _saveStateToSupabase();
    _startTimer();
  }

  double _getStatRate(String stat) {
    switch (_activity) {
      case 'birse':
        if (stat == 'energie') return -1.0;
        if (stat == 'birse') return 1.5;
        if (stat == 'trads') return -1.5;
        break;
      case 'ronque':
        if (stat == 'energie') return 2.5;
        break;
      case 'monome':
        if (stat == 'energie') return -1.5;
        if (stat == 'trads') return 1.5;
        break;
      case 'idle':
      default:
        return 0.0;
    }
    return 0.0;
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0s';
    if (totalSeconds < 60) {
      return '${totalSeconds}s';
    }
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    if (minutes < 60) {
      if (remainingSeconds == 0) {
        return '${minutes}m';
      }
      return '${minutes}m ${remainingSeconds}s';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }

  Widget _buildEnergyRemainingTime() {
    final rate = _getStatRate('energie');
    if (rate == 0) return const SizedBox.shrink();

    int secondsRemaining = 0;
    Color textColor = Colors.green;

    if (rate < 0) {
      if (_energie <= 0) return const SizedBox.shrink();
      secondsRemaining = (_energie / (-rate)).ceil();
      textColor = Colors.red;
    } else if (rate > 0) {
      if (_energie >= 100.0) return const SizedBox.shrink();
      secondsRemaining = ((100.0 - _energie) / rate).ceil();
      textColor = Colors.green;
    }

    final formatted = _formatDuration(secondsRemaining);

    return Text(
      ' ($formatted)',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: textColor,
      ),
    );
  }

  Widget _buildTrendIndicator(String stat, {double iconSize = 20}) {
    final rate = _getStatRate(stat);
    if (rate > 0) {
      return Icon(
        Icons.arrow_upward,
        color: Colors.green,
        size: iconSize,
      );
    } else if (rate < 0) {
      return Icon(
        Icons.arrow_downward,
        color: Colors.red,
        size: iconSize,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildVerticalGauge(
    String topLabel,
    String bottomLabel,
    String title,
    double value,
    Color color,
    String statKey,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(topLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          width: 30,
          child: RotatedBox(
            quarterTurns: -1,
            child: LinearProgressIndicator(
              value: value / 100.0,
              backgroundColor: color.withValues(alpha: 0.2),
              color: color,
              minHeight: 30,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(bottomLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 2),
            _buildTrendIndicator(statKey, iconSize: 18),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Haut : Titre et Jauge NRJ
          Column(
            children: [
              const Text(
                'Mon Conscrit',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Énergie',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildTrendIndicator('energie', iconSize: 22),
                  _buildEnergyRemainingTime(),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 250,
                child: LinearProgressIndicator(
                  value: _energie / 100.0,
                  backgroundColor: Colors.green.withValues(alpha: 0.2),
                  color: Colors.green,
                  minHeight: 20,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),

          // Milieu : Jauge Birse + GIF + Jauge Trad's
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Jauge Gauche : Birse
              _buildVerticalGauge(
                'Zcu',
                'RKL',
                'Birse',
                _birse,
                Colors.purple,
                'birse',
              ),

              // Image Centrale
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image de fond
                      Image.asset(
                        'assets/fond.png',
                        fit: BoxFit.cover, // Remplit complètement le cadre
                        filterQuality: FilterQuality.none,
                      ),
                      // GIF du Conscrit par-dessus
                      Center(
                        child: _isProcessingImages
                            ? const CircularProgressIndicator()
                            : _imageCache[_currentImage] != null
                                ? SpriteSheetAnimator(
                                    // Utilisation de l'image cachée
                                    imageBytes: _imageCache[_currentImage]!,
                                    frameCount: 2,
                                    frameDuration:
                                        const Duration(milliseconds: 600),
                                    width: 120,
                                    height: 120,
                                  )
                                : const Icon(Icons.error, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),

              // Jauge Droite : Trad's
              _buildVerticalGauge(
                'beru',
                'HU',
                "Trad's",
                _trads,
                Colors.orange,
                'trads',
              ),
            ],
          ),

          // Bas : Boutons d'actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                title: 'Birser',
                icon: Icons.edit,
                activityId: 'birse',
                imageName: 'birse.png',
                color: Colors.purple,
              ),
              _buildActionButton(
                title: 'Ronquer',
                icon: Icons.bed,
                activityId: 'ronque',
                imageName: 'ronque.png',
                color: Colors.blue,
              ),
              _buildActionButton(
                title: 'Monômer',
                icon: Icons.groups,
                activityId: 'monome',
                imageName: 'monome.png',
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required String activityId,
    required String imageName,
    required MaterialColor color,
  }) {
    final isActive = _activity == activityId;
    return ElevatedButton(
      onPressed: () => _toggleActivity(activityId, imageName),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? color.shade200 : color.shade50,
        foregroundColor: isActive ? color.shade900 : color.shade700,
        side: isActive
            ? BorderSide(color: color.shade800, width: 2)
            : BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: isActive ? 0 : 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon), const SizedBox(height: 4), Text(title)],
      ),
    );
  }
}
