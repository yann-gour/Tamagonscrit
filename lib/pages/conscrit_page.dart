import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

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
  String _currentGif = 'conscrit.gif';
  String _activity = 'idle';
  
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
          'current_gif': 'conscrit.gif',
          'activity': 'idle',
        });
        _startTimer();
      } else {
        setState(() {
          _energie = (data['energie'] as num).toDouble();
          _birse = (data['birse'] as num).toDouble();
          _trads = (data['trads'] as num).toDouble();
          _currentGif = data['current_gif'] as String;
          _activity = data['activity'] as String;
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
        
        _startTimer();
      }
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

  void _applyOfflineProgress(int seconds) {
    // Applique les gains/pertes cumulés pendant l'absence
    _processTick(secondsMultiplier: seconds.toDouble());
    // On force une sauvegarde pour enregistrer ce rattrapage
    _saveStateToSupabase();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activity != 'idle') {
        setState(() {
          _processTick(secondsMultiplier: 1.0);
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
    double limitSeconds = double.infinity; // Utilisation de l'infini au lieu de null

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

    // Retour à l'état de repos si la condition d'arrêt est atteinte
    if (shouldGoIdle) {
      _activity = 'idle';
      _currentGif = 'conscrit.gif';
      _saveStateToSupabase();
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
        'current_gif': _currentGif,
        'activity': _activity,
        // last_updated est géré automatiquement par le trigger Supabase ou default now() si update classique
      });
    } catch (e) {
      debugPrint('Erreur de sauvegarde: $e');
    }
  }

  void _toggleActivity(String newActivity, String newGif) {
    setState(() {
      if (_activity == newActivity) {
        // Clic sur l'activité en cours : on arrête tout
        _activity = 'idle';
        _currentGif = 'conscrit.gif';
      } else {
        // Changement d'activité
        _activity = newActivity;
        _currentGif = newGif;
      }
    });
    // On sauvegarde l'état en base de données dès qu'on change d'activité
    _saveStateToSupabase();
  }

  Widget _buildVerticalGauge(String topLabel, String bottomLabel, String title, double value, Color color) {
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
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
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
              const Text('Énergie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
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
              _buildVerticalGauge('Zcu', 'RKL', 'Birse', _birse, Colors.purple),

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
                        child: Image.asset(
                          'assets/$_currentGif',
                          width: 120, // Exactement la moitié du cadre (240x240)
                          height: 120,
                          fit: BoxFit.contain, // S'assure que le ratio est conservé
                          filterQuality: FilterQuality.none,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 120, color: Colors.grey);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Jauge Droite : Trad's
              _buildVerticalGauge("Bapt's", 'HU', "Trad's", _trads, Colors.orange),
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
                gifName: 'birse.gif',
                color: Colors.purple,
              ),
              _buildActionButton(
                title: 'Ronquer',
                icon: Icons.bed,
                activityId: 'ronque',
                gifName: 'ronque.gif',
                color: Colors.blue,
              ),
              _buildActionButton(
                title: 'Monômer',
                icon: Icons.groups,
                activityId: 'monome',
                gifName: 'monome.gif',
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
    required String gifName,
    required MaterialColor color,
  }) {
    final isActive = _activity == activityId;
    return ElevatedButton(
      onPressed: () => _toggleActivity(activityId, gifName),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? color.shade200 : color.shade50,
        foregroundColor: isActive ? color.shade900 : color.shade700,
        side: isActive ? BorderSide(color: color.shade800, width: 2) : BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: isActive ? 0 : 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }
}
