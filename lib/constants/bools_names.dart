class BoolsNames {
  static const Map<String, Map<String, String>> _tabagnsOverrides = {
    'Ai': {
      'Zt AE': 'Zt Cercle',
      'ME': 'Archimède',
      "Zt Foy's": 'Zt Kfet',
      'Zt UAI': 'Zt Pitate',
    },
    'Ch': {
      'Zt AE': 'GAF',
      'MT': 'Colon',
      "Grip's": "Trésor's",
      'Zt UAI': 'Zt Handball',
    },
    'Bo': {
      "Grip's": "Trésor's",
      'Zt UAI': "Zt Rub's",
    },
    'Me': {
      "Grip's": "Trésor's",
      'Zt UAI': 'Zt Volleyball',
    },
    'An': {
      "Grip's": "Trésor's",
      'Zt UAI': 'Zt Natation',
    },
    'Cl': {
      "Grip's": "Trésor's",
      'Zt UAI': 'Zt Ping Pong',
    },
    'Li': {
      "Grip's": "Trésor's",
      'MT': 'GAF',
      'Zt UAI': 'Zt Basketball',
    },
  };

  /// Retourne le nom d'affichage d'un bool's en fonction du tabagn's du conscrit
  static String getDisplayName(String baseBools, String? tabagns) {
    if (tabagns == null) return baseBools;
    return _tabagnsOverrides[tabagns]?[baseBools] ?? baseBools;
  }
}
