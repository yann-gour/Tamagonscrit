import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Pour accéder à themeNotifier
import '../services/notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static const List<String> tabagnsList = ['Ai', 'An', 'Bo', 'Ch', 'Cl', 'Li', 'Me'];

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;

  final _bucqueController = TextEditingController();
  final _famsController = TextEditingController();
  String? _selectedTabagns;
  final _promsController = TextEditingController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    NotificationService().areNotificationsEnabled().then((val) {
      if (mounted) setState(() => _notificationsEnabled = val);
    });
    final user = supabase.auth.currentUser;
    _emailController.text = user?.email ?? '';

    final metadata = user?.userMetadata ?? {};
    _bucqueController.text = metadata['bucque']?.toString() ?? '';
    _famsController.text = metadata['fams']?.toString() ?? '';
    final savedTabagns = metadata['tabagns']?.toString();
    if (savedTabagns != null && ProfilePage.tabagnsList.contains(savedTabagns)) {
      _selectedTabagns = savedTabagns;
    }
    _promsController.text = metadata['proms']?.toString() ?? '';
  }

  Future<void> _updateProfile() async {
    final bucque = _bucqueController.text.trim();
    if (bucque.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La bucque est obligatoire.')),
      );
      return;
    }

    final famsStr = _famsController.text.trim();
    final String? fams = famsStr.isNotEmpty ? famsStr : null;

    int? proms;
    final promsStr = _promsController.text.trim();
    if (promsStr.isNotEmpty) {
      proms = int.tryParse(promsStr);
      if (proms == null || proms < 100 || proms > 999) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La prom\'s doit être un nombre entre 100 et 999.')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final String? newEmail =
          _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null;
      final String? newPassword =
          _passwordController.text.trim().isNotEmpty ? _passwordController.text.trim() : null;

      final updatedMetadata = <String, dynamic>{
        'bucque': bucque,
        'fams': fams,
        'tabagns': _selectedTabagns,
        'proms': proms,
      };

      await supabase.auth.updateUser(UserAttributes(
        email: newEmail,
        password: newPassword,
        data: updatedMetadata,
      ));

      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        try {
          await supabase.from('profiles').upsert({
            'id': currentUser.id,
            'bucque': bucque,
            'fams': fams,
            'tabagns': _selectedTabagns,
            'proms': proms,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Erreur de synchro profiles: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès !')),
        );
        _passwordController.clear();
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur inattendue')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _bucqueController.dispose();
    _famsController.dispose();
    _promsController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Informations Gadz\'arts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bucqueController,
                  decoration: const InputDecoration(
                    labelText: 'Bucque *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _famsController,
                  decoration: const InputDecoration(
                    labelText: 'Fam\'s',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTabagns,
                  decoration: const InputDecoration(
                    labelText: 'Tabagn\'s',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Aucun'),
                    ),
                    ...ProfilePage.tabagnsList.map((t) => DropdownMenuItem<String>(
                          value: t,
                          child: Text(t),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTabagns = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _promsController,
                  decoration: const InputDecoration(
                    labelText: 'Prom\'s',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Compte & Sécurité',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Nouvel Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau Mot de passe',
                    border: OutlineInputBorder(),
                    helperText: 'Laissez vide pour ne pas changer',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Mettre à jour le profil'),
                  ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Apparence',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, currentMode, child) {
                    return SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_system_daydream),
                          label: Text('Auto'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode),
                          label: Text('Clair'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode),
                          label: Text('Sombre'),
                        ),
                      ],
                      selected: {currentMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        themeNotifier.value = newSelection.first;
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activer les notifications'),
                  subtitle: const Text('Alertes sur l\'énergie, birse et trad\'s'),
                  value: _notificationsEnabled,
                  onChanged: (val) async {
                    setState(() => _notificationsEnabled = val);
                    await NotificationService().setNotificationsEnabled(val);
                    if (val) {
                      await NotificationService().requestPermissions();
                    }
                  },
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
