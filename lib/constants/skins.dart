class SkinItem {
  final String id;
  final String name;
  final int zloeilsPrice;
  final String? assetPath;

  const SkinItem({
    required this.id,
    required this.name,
    required this.zloeilsPrice,
    this.assetPath,
  });
}

class AvatarSkins {
  static const List<SkinItem> skins = [
    SkinItem(id: 'none', name: 'Aucun', zloeilsPrice: 0),
    SkinItem(
      id: 'bache_bleue',
      name: 'Bâche bleue',
      zloeilsPrice: 10,
      assetPath: 'assets/skin_bache_bleue.png',
    ),
    SkinItem(
      id: 'bache_rouge',
      name: 'Bâche rouge',
      zloeilsPrice: 10,
      assetPath: 'assets/skin_bache_rouge.png',
    ),
    SkinItem(
      id: 'bache_verte',
      name: 'Bâche verte',
      zloeilsPrice: 10,
      assetPath: 'assets/skin_bache_verte.png',
    ),
    SkinItem(
      id: 'equerre',
      name: 'Équerre',
      zloeilsPrice: 100,
      assetPath: 'assets/skin_equerre.png',
    ),
    SkinItem(
      id: 'fignos',
      name: "Figno's",
      zloeilsPrice: 100,
      assetPath: 'assets/skin_fignos.png',
    ),
    SkinItem(
      id: 'craps',
      name: "Crap's",
      zloeilsPrice: 1000,
      assetPath: 'assets/skin_craps.png',
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
