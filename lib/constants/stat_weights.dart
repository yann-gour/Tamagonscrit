class StatWeights {
  // Poids globaux appliqués à chaque augmentation/diminution de stat selon l'état

  // Ronque : 0 à 100 % d'énergie en 8 heures (28 800 s) avec multiplicateur 1

  static const double weightEnergie = 100.0 / 3600.0;

  // Birse : 0 à 100 % de birse en 8 heures (28 800 s) avec multiplicateur 1

  static const double weightBirse = 100.0 / 3600.0;

  // Monôme : 0 à 100 % de trad's en 8 heures (28 800 s) avec multiplicateur 1

  static const double weightTrads = 100.0 / 3600.0;
}
