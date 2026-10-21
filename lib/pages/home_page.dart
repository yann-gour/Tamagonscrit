import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'conscrit_page.dart';
import 'monome_page.dart';
import 'profile_page.dart';
import 'leaderboard_page.dart';
import 'carns_page.dart';
import '../services/achievement_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBucqueOnStartup();
    });
  }

  void _checkBucqueOnStartup() {
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final metadata = user.userMetadata ?? {};
    final bucque = metadata['bucque']?.toString().trim() ?? '';

    if (bucque.isEmpty) {
      _showBucqueRequiredDialog();
    } else {
      _syncProfileOnStartup(user.id, metadata);
    }
  }

  Future<void> _syncProfileOnStartup(String userId, Map<String, dynamic> metadata) async {
    try {
      final bucque = metadata['bucque']?.toString().trim();
      final fams = metadata['fams']?.toString().trim();
      final tabagns = metadata['tabagns']?.toString().trim();
      final proms = metadata['proms'] != null ? int.tryParse(metadata['proms'].toString()) : null;

      if (bucque != null && bucque.isNotEmpty) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': userId,
          'bucque': bucque,
          'fams': fams?.isNotEmpty == true ? fams : null,
          'tabagns': tabagns?.isNotEmpty == true ? tabagns : null,
          'proms': proms,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Erreur synchro profil au démarrage: $e');
    }
  }

  void _showBucqueRequiredDialog() {
    final bucqueController = TextEditingController();
    final famsController = TextEditingController();
    String? selectedTabagns;
    final promsController = TextEditingController();

    bool isSaving = false;
    String? dialogErrorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveBucque() async {
              final bucque = bucqueController.text.trim();
              if (bucque.isEmpty) {
                setDialogState(() {
                  dialogErrorMessage = 'La bucque est obligatoire.';
                });
                return;
              }

              final famsStr = famsController.text.trim();
              final String? fams = famsStr.isNotEmpty ? famsStr : null;

              int? proms;
              final promsStr = promsController.text.trim();
              if (promsStr.isNotEmpty) {
                proms = int.tryParse(promsStr);
                if (proms == null || proms < 100 || proms > 999) {
                  setDialogState(() {
                    dialogErrorMessage = 'La prom\'s doit être un nombre entre 100 et 999.';
                  });
                  return;
                }
              }

              setDialogState(() {
                isSaving = true;
                dialogErrorMessage = null;
              });

              try {
                final user = Supabase.instance.client.auth.currentUser;
                final existingData = Map<String, dynamic>.from(user?.userMetadata ?? {});
                existingData['bucque'] = bucque;
                existingData['fams'] = fams;
                existingData['tabagns'] = selectedTabagns;
                existingData['proms'] = proms;

                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(data: existingData),
                );

                if (user != null) {
                  try {
                    await Supabase.instance.client.from('profiles').upsert({
                      'id': user.id,
                      'bucque': bucque,
                      'fams': fams,
                      'tabagns': selectedTabagns,
                      'proms': proms,
                      'updated_at': DateTime.now().toUtc().toIso8601String(),
                    });
                  } catch (e) {
                    debugPrint('Erreur de synchro profiles: $e');
                  }
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              } catch (e) {
                setDialogState(() {
                  isSaving = false;
                  dialogErrorMessage = 'Erreur lors de la sauvegarde : $e';
                });
              }
            }

            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text('Sal\'s MT !'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Renseigne ta bucque dans le champ ci-dessous :',
                        style: TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: bucqueController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Bucque *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: famsController,
                        decoration: const InputDecoration(
                          labelText: 'Fam\'s',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedTabagns,
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
                          setDialogState(() {
                            selectedTabagns = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: promsController,
                        decoration: const InputDecoration(
                          labelText: 'Prom\'s',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      if (dialogErrorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          dialogErrorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  if (isSaving)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    )
                  else
                    ElevatedButton(
                      onPressed: saveBucque,
                      child: const Text('Valider'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      monomeRefreshNotifier.value++;
    } else if (index == 2) {
      leaderboardRefreshNotifier.value++;
    } else if (index == 3) {
      achievementsRefreshNotifier.value++;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamagonscrit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ConscritPage(isVisible: _selectedIndex == 0),
          const MonomePage(),
          const LeaderboardPage(),
          const CarnsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Conscrit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Monôme',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: "Zprom's",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: "Carn's",
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
