class EventConditionContext {
  final double birse;
  final double trads;
  final int brousoufs;

  EventConditionContext({
    required this.birse,
    required this.trads,
    required this.brousoufs,
  });
}

class EventEffectContext {
  final void Function(double deltaBirse) addBirse;
  final void Function(double deltaTrads) addTrads;
  final void Function(int deltaBrousoufs) addBrousoufs;
  final void Function(double value) setEnergie;
  final void Function(String activity, String image) setActivity;
  final void Function() resetState;

  EventEffectContext({
    required this.addBirse,
    required this.addTrads,
    required this.addBrousoufs,
    required this.setEnergie,
    required this.setActivity,
    required this.resetState,
  });
}

class EventChoice {
  final String label;
  final String Function(String conscritName) getResultText;
  final void Function(EventEffectContext context) applyEffect;
  final bool Function(EventConditionContext context)? isAvailable;

  const EventChoice({
    required this.label,
    required this.getResultText,
    required this.applyEffect,
    this.isAvailable,
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
      getResultText: (name) => '$name est resté toute la nuit chouiller au foy\'s !',
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
      getResultText: (name) => '$name est resté bouffer seul à Kgib\'s !',
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

final RandomEvent brousoufsEvent = RandomEvent(
  id: 'brousoufs',
  title: 'Brousoufs !',
  getDescription: (name) => '$name a besoin de brousoufs, comment va-t-on s\'y prendre ?',
  choices: [
    EventChoice(
      label: 'Participer à un projet AMJE',
      getResultText: (name) => '$name a participé à un projet AMJE et gagné 50 brousoufs !',
      isAvailable: (context) => context.birse >= 50.0,
      applyEffect: (context) {
        context.addBrousoufs(50);
      },
    ),
    EventChoice(
      label: 'Donner des cours de maths',
      getResultText: (name) => '$name a donné des cours de maths et gagné 10 brousoufs !',
      isAvailable: (context) => context.birse >= 10.0,
      applyEffect: (context) {
        context.addBrousoufs(10);
      },
    ),
    EventChoice(
      label: 'Demander un prêt d\'hon\'s à la SOCE',
      getResultText: (name) => '$name a reçu un prêt d\'hon\'s de 100 brousoufs !',
      isAvailable: (context) => context.trads >= 50.0,
      applyEffect: (context) {
        context.addBrousoufs(100);
      },
    ),
    EventChoice(
      label: 'Birouter au foy\'s',
      getResultText: (name) => '$name a birouté au foy\'s et s\'est fait mettre HP...',
      applyEffect: (context) {
        context.resetState();
      },
    ),
    EventChoice(
      label: 'Ne rien faire',
      getResultText: (name) => '$name n\'a rien fait et reste sans brousoufs.',
      applyEffect: (context) {},
    ),
  ],
);

final List<RandomEvent> allRandomEvents = [
  chouilleEvent,
  finsEvent,
  brousoufsEvent,
];
