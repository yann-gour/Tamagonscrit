class EventEffectContext {
  final void Function(double deltaBirse) addBirse;
  final void Function(double deltaTrads) addTrads;
  final void Function(double value) setEnergie;
  final void Function(String activity, String image) setActivity;

  EventEffectContext({
    required this.addBirse,
    required this.addTrads,
    required this.setEnergie,
    required this.setActivity,
  });
}

class EventChoice {
  final String label;
  final String Function(String conscritName) getResultText;
  final void Function(EventEffectContext context) applyEffect;

  const EventChoice({
    required this.label,
    required this.getResultText,
    required this.applyEffect,
  });
}

class RandomEvent {
  final String id;
  final String title;
  final String Function(String conscritName) getDescription;
  final List<EventChoice> choices;

  const RandomEvent({
    required this.id,
    required this.title,
    required this.getDescription,
    required this.choices,
  });
}

final RandomEvent chouilleEvent = RandomEvent(
  id: 'chouille',
  title: 'Chouille !',
  getDescription: (name) => 'Une chouille a lieu au foy\'s ! que va faire $name ?',
  choices: [
    EventChoice(
      label: 'Rester birser à Kgib\'s',
      getResultText: (name) => '$name est resté birser toute la soirée !',
      applyEffect: (context) {
        context.addBirse(20.0);
        context.addTrads(-10.0);
        context.setActivity('birse', 'birse.png');
      },
    ),
    EventChoice(
      label: 'Descendre boire un quillon',
      getResultText: (name) => '$name est descendu chouiller avec ses cop\'s !',
      applyEffect: (context) {
        context.addTrads(20.0);
        context.setActivity('chouille', 'chouille.png');
      },
    ),
    EventChoice(
      label: 'Se mettre un placard',
      getResultText: (name) => '$name est resté toute la nuit au foy\'s !',
      applyEffect: (context) {
        context.addBirse(-20.0);
        context.addTrads(20.0);
        context.setEnergie(0.0);
        context.setActivity('ronque', 'ronque.png');
      },
    ),
    EventChoice(
      label: 'Rester ronquer à Kgib\'s.',
      getResultText: (name) => '$name est resté ronquer tranquillement à Kgib\'s !',
      applyEffect: (context) {
        context.setActivity('ronque', 'ronque.png');
      },
    ),
  ],
);

final RandomEvent finsEvent = RandomEvent(
  id: 'fins',
  title: 'Fin\'s !',
  getDescription: (name) => 'Un fin\'s a lieu au foy\'s ! que va faire $name ?',
  choices: [
    EventChoice(
      label: 'Rester birser à Kgib\'s',
      getResultText: (name) => '$name est resté birser toute la soirée !',
      applyEffect: (context) {
        context.addBirse(20.0);
        context.addTrads(-10.0);
        context.setActivity('birse', 'birse.png');
      },
    ),
    EventChoice(
      label: 'Descendre bouffer',
      getResultText: (name) => '$name est descendu fin\'ser avec ses cop\'s !',
      applyEffect: (context) {
        context.setActivity('fins', 'fins.png');
      },
    ),
    EventChoice(
      label: 'Rester bouffer à Kgib\'s',
      getResultText: (name) => '$name est resté bouffer à Kgib\'s !',
      applyEffect: (context) {
        context.addTrads(-20.0);
        context.setEnergie(100.0);
        context.setActivity('idle', 'conscrit.png');
      },
    ),
    EventChoice(
      label: 'Rester ronquer à Kgib\'s.',
      getResultText: (name) => '$name est resté ronquer tranquillement à Kgib\'s !',
      applyEffect: (context) {
        context.setActivity('ronque', 'ronque.png');
      },
    ),
  ],
);

final List<RandomEvent> allRandomEvents = [
  chouilleEvent,
  finsEvent,
];
