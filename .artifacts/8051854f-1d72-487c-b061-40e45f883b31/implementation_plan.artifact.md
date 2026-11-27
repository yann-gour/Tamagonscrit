# Plan d'implémentation - Ajout de fonctions GPS et d'événements géolocalisés (avec succès Iéna)

Ce plan détaille l'ajout d'une fonctionnalité de géolocalisation pour déclencher des événements spéciaux basés sur la position du joueur (notamment l'événement "Iéna" à l'Hôtel des Arts et Métiers), ainsi que le déblocage du succès associé.

## Modifications proposées

### Dépendances et Configuration
#### [MODIFY] [pubspec.yaml](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/pubspec.yaml)
- Ajouter `geolocator: ^13.0.2`.

#### [MODIFY] [AndroidManifest.xml](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/android/app/src/main/AndroidManifest.xml)
- Ajouter les permissions de localisation (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`).

#### [MODIFY] [Info.plist](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/ios/Runner/Info.plist)
- Ajouter les descriptions d'accès à la position (`NSLocationWhenInUseUsageDescription`).

---

### Modèle et Succès
#### [NEW] [location_event.dart](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/lib/models/location_event.dart)
- Définir le modèle `LocationEvent` (latitude, longitude, rayon en mètres, `RandomEvent`, etc.).
- Définir l'événement "Iéna" (9bis Av. d'Iéna, 75016 Paris, rayon 100m, titre "Iéna", texte "Bienvenue à l'Hôtel des Arts et Métiers !").

#### [MODIFY] [achievement_service.dart](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/lib/services/achievement_service.dart)
- Ajouter l'achievement `'iena'` (Titre "Iéna", description "Bienvenue à l'Hôtel des Arts et Métiers !", isHidden: true).

#### [MODIFY] [conscrit_page.dart](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/lib/pages/conscrit_page.dart)
- Intégrer la vérification GPS (`_checkGpsEvents()`), la gestion des permissions `geolocator`, le calcul de distance et le déblocage du succès `'iena'`.

## Plan de vérification

### Tests automatisés
- Vérification de la compilation du projet (`flutter pub get`).

### Vérification manuelle
- Test de la géolocalisation et du déclenchement de l'événement.
