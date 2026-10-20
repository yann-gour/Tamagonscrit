import 'dart:math';
import 'package:random_name_generator/random_name_generator.dart';

class ConscritNames {
  static final Random _random = Random();

  /// Tirage au sort de la zone selon les poids :
  /// - 70% : France
  /// - 10% : Maghreb / Monde arabe (Égypte, Arabie Saoudite)
  /// - 10% : Europe du Sud (Espagne, Italie)
  /// - 5%  : Europe de l'Est (Pologne, Russie)
  /// - 5%  : Asie de l'Est (Chine, Japon)
  static Zone _selectWeightedZone() {
    final roll = _random.nextDouble() * 100;

    if (roll < 70) {
      return Zone.france;
    } else if (roll < 80) {
      final arabZones = [Zone.egypt, Zone.saudiArabia];
      return arabZones[_random.nextInt(arabZones.length)];
    } else if (roll < 90) {
      final southEuropeZones = [Zone.spain, Zone.italy];
      return southEuropeZones[_random.nextInt(southEuropeZones.length)];
    } else if (roll < 95) {
      final eastEuropeZones = [Zone.poland, Zone.russia];
      return eastEuropeZones[_random.nextInt(eastEuropeZones.length)];
    } else {
      final eastAsiaZones = [Zone.china, Zone.japan];
      return eastAsiaZones[_random.nextInt(eastAsiaZones.length)];
    }
  }

  static String getRandomName() {
    final zone = _selectWeightedZone();
    final randomNames = RandomNames(zone);

    final name = randomNames.name();
    final firstName = name.split(' ').first.trim();
    return firstName.isNotEmpty ? firstName : 'Antoine';
  }
}
