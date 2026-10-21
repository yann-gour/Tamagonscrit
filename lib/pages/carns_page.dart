import 'package:flutter/material.dart';
import '../services/achievement_service.dart';

class CarnsPage extends StatefulWidget {
  const CarnsPage({super.key});

  @override
  State<CarnsPage> createState() => _CarnsPageState();
}

class _CarnsPageState extends State<CarnsPage> with AutomaticKeepAliveClientMixin {
  final AchievementService _achievementService = AchievementService();
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    achievementsRefreshNotifier.addListener(_onRefresh);
    _loadData();
  }

  void _onRefresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    await _achievementService.loadAchievements();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    achievementsRefreshNotifier.removeListener(_onRefresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final achievements = _achievementService.achievements;
    final unlockedCount = _achievementService.unlockedCount;
    final totalCount = achievements.length;
    final double progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            "Carn's",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Pages du carn's",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          // Carte de progression globale
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Progression du carn's",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "$unlockedCount / $totalCount",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Liste des succès
          Expanded(
            child: ListView.builder(
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final item = achievements[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  elevation: item.isUnlocked ? 2 : 1,
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: item.isUnlocked
                        ? BorderSide(color: Colors.amber.shade600, width: 1.5)
                        : BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: item.isUnlocked && item.customBackgroundColor != null
                            ? Border.all(color: Colors.grey.shade400, width: 1.5)
                            : null,
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: item.isUnlocked
                            ? (item.customBackgroundColor ?? Colors.amber.shade100)
                            : Colors.grey.shade200,
                        child: item.imageUrl != null
                            ? (item.isUnlocked
                                ? ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      item.customIconColor ?? Colors.amber.shade900,
                                      BlendMode.srcIn,
                                    ),
                                    child: Image.network(
                                      item.imageUrl!,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        item.icon,
                                        color: item.customIconColor ?? Colors.amber.shade900,
                                        size: 28,
                                      ),
                                    ),
                                  )
                                : ColorFiltered(
                                    colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                                    child: Image.network(
                                      item.imageUrl!,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        item.icon,
                                        color: Colors.grey.shade500,
                                        size: 28,
                                      ),
                                    ),
                                  ))
                            : Icon(
                                item.icon,
                                color: item.isUnlocked
                                    ? (item.customIconColor ?? Colors.amber.shade900)
                                    : Colors.grey.shade500,
                                size: 28,
                              ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: item.isUnlocked
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (item.isUnlocked)
                          const Icon(Icons.check_circle, color: Colors.green, size: 20)
                        else
                          Icon(Icons.lock, color: Colors.grey.shade500, size: 20),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        item.isUnlocked ? item.description : "???",
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: item.isUnlocked
                              ? Theme.of(context).textTheme.bodyMedium?.color
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
