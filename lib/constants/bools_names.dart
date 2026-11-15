class BoolsNames {
  static const Map<String, Map<String, String>> _tabagnsOverrides = {
    'Ai': {
      'Zt AE': 'Zt Cercle',
      "Grip's": "Trésor's",
      "Zt Foy's": 'Zt Kfet',
      'Zt UAI': 'Zt Pitate',
    },
    'Ch': {
      'Zt AE': 'GAF',
      'MT': 'Colon',
      'Zt UAI': 'Zt Handball',
    },
    'Bo': {
      'Zt UAI': "Zt Rub's",
    },
    'Me': {
      'Zt UAI': 'Zt Volleyball',
    },
    'An': {
      'Zt UAI': 'Zt Natation',
    },
    'Cl': {
      'Zt UAI': 'Zt Ping Pong',
    },
    'Li': {
      'Zt UAI': 'Zt Basketball',
    },
  };

  /// Retourne le nom d'affichage d'un bool's en fonction du tabagn's du conscrit
  static String getDisplayName(String baseBools, String? tabagns) {
    if (tabagns == null) return baseBools;
    return _tabagnsOverrides[tabagns]?[baseBools] ?? baseBools;
  }
}
