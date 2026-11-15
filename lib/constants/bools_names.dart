class BoolsNames {
  static const Map<String, Map<String, String>> _tabagnsOverrides = {
    'Ai': {
      'Zt AE': 'Zt Cercle',
      "Grip's": "Trésor's",
    },
    'Ch': {
      'Zt AE': 'GAF',
      'MT': 'Colon',
    },
  };

  /// Retourne le nom d'affichage d'un bool's en fonction du tabagn's du conscrit
  static String getDisplayName(String baseBools, String? tabagns) {
    if (tabagns == null) return baseBools;
    return _tabagnsOverrides[tabagns]?[baseBools] ?? baseBools;
  }
}
