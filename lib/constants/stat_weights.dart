class StatWeights {
  // Poids globaux appliqués à chaque augmentation/diminution de stat selon l'état

  // Ronque : 0 à 100 % d'énergie en 8 heures (28 800 s) avec multiplicateur 2.5
  // 2.5 * weightEnergie * 28800 = 100 => weightEnergie = 1 / 720
  static const double weightEnergie = 100.0 / 9000.0;

  // Birse : 0 à 100 % de birse en 8 heures (28 800 s) avec multiplicateur 1.5
  // 1.5 * weightBirse * 28800 = 100 => weightBirse = 1 / 720
  static const double weightBirse = 100.0 / 9000.0;

  // Monôme : 0 à 100 % de trad's en 8 heures (28 800 s) avec multiplicateur 1.5
  // 1.5 * weightTrads * 28800 = 100 => weightTrads = 1 / 720
  static const double weightTrads = 100.0 / 9000.0;
}
