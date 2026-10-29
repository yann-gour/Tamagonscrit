class NotificationContent {
  final int id;
  final String title;
  final String Function(String name) body;

  const NotificationContent({
    required this.id,
    required this.title,
    required this.body,
  });
}

abstract class NotificationMessages {
  static final NotificationContent energieEpuisee = NotificationContent(
    id: 1,
    title: 'Epuisement',
    body: (name) => 'Ho non ! $name est épuisé !',
  );

  static final NotificationContent birse100Jours = NotificationContent(
    id: 2,
    title: "C'est les 100 jours",
    body: (name) => 'Bravo ! $name obtient sa Zblanche !',
  );

  static final NotificationContent birseDelivrance = NotificationContent(
    id: 3,
    title: "C'est la délivrance",
    body: (name) => 'Bravo ! $name obtient son Zcu !',
  );

  static final NotificationContent tradsBapts = NotificationContent(
    id: 4,
    title: "C'est le Bapt's",
    body: (name) => 'Bravo ! $name choisit sa bucque !',
  );

  static final NotificationContent tradsMaster = NotificationContent(
    id: 5,
    title: "Gorgu",
    body: (name) => 'Bravo ! $name est plus trad\'s que Gorgu !',
  );

  static final NotificationContent tradsAlerteHU = NotificationContent(
    id: 6,
    title: 'HU',
    body: (name) => 'Ho non ! $name va se faire mettre HU !',
  );
}
