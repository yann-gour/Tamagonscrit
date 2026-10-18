import 'dart:math';

class ConscritNames {
  static const List<String> names = [
    'Antoine',
    'Arthur',
    'Auguste',
    'Basile',
    'Benoît',
    'Charles',
    'Clément',
    'Émile',
    'Enzo',
    'Étienne',
    'Fernand',
    'François',
    'Gabin',
    'Gaspard',
    'Gaston',
    'Guillaume',
    'Henri',
    'Hugo',
    'Jean',
    'Jules',
    'Julien',
    'Léo',
    'Léon',
    'Louis',
    'Lucas',
    'Lucien',
    'Marcel',
    'Martin',
    'Mathieu',
    'Maxime',
    'Nicolas',
    'Paul',
    'Pierre',
    'Raphaël',
    'Sacha',
    'Sébastien',
    'Théo',
    'Thomas',
    'Valentin',
    'Victor',
  ];

  static String getRandomName() {
    final random = Random();
    return names[random.nextInt(names.length)];
  }
}
