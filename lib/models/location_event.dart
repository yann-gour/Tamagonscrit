import 'random_event.dart';

class LocationEvent {
  final String id;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final RandomEvent event;
  final String? achievementId;

  const LocationEvent({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.event,
    this.achievementId,
  });
}

// Événement Iéna (Hôtel des Arts et Métiers, 9bis Av. d'Iéna, 75016 Paris)
// Coordonnées : 48.86514, 2.29432 (rayon 100m)
final LocationEvent ienaLocationEvent = LocationEvent(
  id: 'iena_location',
  latitude: 48.86514,
  longitude: 2.29432,
  radiusMeters: 100.0,
  achievementId: 'iena',
  event: RandomEvent(
    id: 'iena_event',
    title: 'Iéna',
    getDescription: (name) => 'Bienvenue à l\'Hôtel des Arts et Métiers !',
    choices: [
      EventChoice(
        label: 'Frat\'s !',
        getResultText: (name) => '$name est allé voir l\'archi Tatoulu !',
        applyEffect: (context) {
          context.addTrads(50.0);
        },
      ),
    ],
  ),
);

// Événement Liancourt (2 Av. de la Faïence, 60140 Liancourt)
// Coordonnées : 49.3308, 2.4675 (rayon 100m)
final LocationEvent liancourtLocationEvent = LocationEvent(
  id: 'liancourt_location',
  latitude: 49.3308,
  longitude: 2.4675,
  radiusMeters: 100.0,
  achievementId: 'liancourt',
  event: RandomEvent(
    id: 'liancourt_event',
    title: 'Liancourt',
    getDescription: (name) => 'Bienvenue à Liancourt !',
    choices: [
      EventChoice(
        label: 'Frat\'s !',
        getResultText: (name) => '$name se fait bien usiner !',
        applyEffect: (context) {
          context.addTrads(100.0);
        },
      ),
    ],
  ),
);

// Liste extensible pour ajouter facilement de futurs événements GPS
final List<LocationEvent> allLocationEvents = [
  ienaLocationEvent,
  liancourtLocationEvent,
];
