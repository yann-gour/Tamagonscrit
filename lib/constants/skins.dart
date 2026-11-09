class SkinItem {
  final String id;
  final String name;
  final int zloeilsPrice;
  final String? assetPath;
  final bool isRecolored;

  const SkinItem({
    required this.id,
    required this.name,
    required this.zloeilsPrice,
    this.assetPath,
    this.isRecolored = false,
  });
}

class AvatarSkins {
  static const List<SkinItem> skins = [
    SkinItem(id: 'none', name: 'Aucun', zloeilsPrice: 0),
    SkinItem(
      id: 'bache_bleue',
      name: 'Bâche bleue',
      zloeilsPrice: 100,
      assetPath: 'assets/skin_bache_bleue.png',
    ),
    SkinItem(
      id: 'bache_rouge',
      name: 'Bâche rouge',
      zloeilsPrice: 100,
      assetPath: 'assets/skin_bache_rouge.png',
    ),
    SkinItem(
      id: 'bache_verte',
      name: 'Bâche verte',
      zloeilsPrice: 100,
      assetPath: 'assets/skin_bache_verte.png',
    ),
    SkinItem(
      id: 'bache_perso',
      name: 'Bâche perso',
      zloeilsPrice: 200,
      assetPath: 'assets/skin_bache_perso.png',
      isRecolored: true,
    ),
    SkinItem(
      id: 'cache_boule_perso',
      name: 'Cache boule perso',
      zloeilsPrice: 300,
      assetPath: 'assets/skin_cache_boule_perso.png',
      isRecolored: true,
    ),
    SkinItem(
      id: 'cache_boule_ai',
      name: 'Cache boule (Ai)',
      zloeilsPrice: 200,
      assetPath: 'assets/skin_cache_boule_ai.png',
    ),
    SkinItem(
      id: 'cache_boule_an',
      name: 'Cache boule (An)',
      zloeilsPrice: 200,
      assetPath: 'assets/skin_cache_boule_an.png',
    ),
    SkinItem(
      id: 'cache_boule_bo',
      name: 'Cache boule (Bo)',
      zloeilsPrice: 200,
      assetPath: 'assets/skin_cache_boule_bo.png',
    ),
    SkinItem(
      id: 'cache_boule_ch',
      name: 'Cache boule (Ch)',
      zloeilsPrice: 200,
      assetPath: 'assets/skin_cache_boule_ch.png',
    ),
    SkinItem(
      id: 'cache_boule_cl',
      name: 'Cache boule (Cl)',
      zloeilsPrice: 200,
      assetPath: 'assets/skin_cache_boule_cl.png',
    ),
    SkinItem(
      id: 'cache_boule_li',
      name: 'Cache boule (Li)',
      zloeilsPrice: 200,
      assetPath: 'assets/skin_cache_boule_li.png',
    ),
    SkinItem(
      id: 'cache_boule_me',
      name: 'Cache boule (Me)',
      zloeilsPrice: 200,
      assetPath: 'assets/skin_cache_boule_me.png',
    ),
    SkinItem(
      id: 'equerre',
      name: 'Équerre',
      zloeilsPrice: 500,
      assetPath: 'assets/skin_equerre.png',
    ),
    SkinItem(
      id: 'fignos',
      name: "Figno's",
      zloeilsPrice: 500,
      assetPath: 'assets/skin_fignos.png',
    ),
    SkinItem(
      id: 'craps',
      name: "Crap's",
      zloeilsPrice: 1000,
      assetPath: 'assets/skin_craps.png',
    ),
    SkinItem(
      id: 'canaris',
      name: "Canari's",
      zloeilsPrice: 1000,
      assetPath: 'assets/skin_jaune.png',
    ),
  ];

  static List<SkinItem> get sortedSkins {
    final list = List<SkinItem>.from(skins);
    list.sort((a, b) {
      final priceComp = a.zloeilsPrice.compareTo(b.zloeilsPrice);
      if (priceComp != 0) return priceComp;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  static SkinItem getSkin(String? skinId) {
    if (skinId == null || skinId.isEmpty) return skins.first;
    return skins.firstWhere(
      (s) => s.id.toLowerCase() == skinId.toLowerCase(),
      orElse: () => skins.first,
    );
  }
}
