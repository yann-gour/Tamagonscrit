# Walkthrough - Ajout de fonctions GPS et des événements géolocalisés (Iéna & Liancourt)

Mise en place d'une architecture extensible de géolocalisation pour les événements spéciaux, incluant l'événement **"Iéna"** (Hôtel des Arts et Métiers) et l'événement **"Liancourt"** (2 Av. de la Faïence, 60140 Liancourt), avec leurs succès associés.

## Modifications réalisées

### 1. Dépendances et Configuration
- **[pubspec.yaml](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/pubspec.yaml)** : Ajout de la dépendance `geolocator: ^13.0.4`.
- **[AndroidManifest.xml](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/android/app/src/main/AndroidManifest.xml)** : Ajout des permissions `ACCESS_FINE_LOCATION` et `ACCESS_COARSE_LOCATION`.
- **[Info.plist](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/ios/Runner/Info.plist)** : Ajout des descriptions `NSLocationWhenInUseUsageDescription`.

### 2. Architecture des Événements GPS
- **[NEW] [location_event.dart](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/lib/models/location_event.dart)** :
  - Création du modèle `LocationEvent` (coordonnées GPS lat/lon, rayon en mètres, lien avec `RandomEvent`, et `achievementId`).
  - Définition de l'événement **"Iéna"** (9bis Av. d'Iéna, 75016 Paris, rayon 100m, succès `'iena'`).
  - Définition de l'événement **"Liancourt"** (2 Av. de la Faïence, 60140 Liancourt, lat: `49.3308`, lon: `2.4675`, rayon 100m, succès `'liancourt'`).
  - Liste extensible `allLocationEvents` regroupant tous les lieux géolocalisés.

### 3. Succès Associés
- **[achievement_service.dart](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/lib/services/achievement_service.dart)** :
  - Configuration du succès caché `'iena'` ("Iéna").
  - Configuration du succès caché `'liancourt'` ("Liancourt").

### 4. Intégration UI et Logique
- **[conscrit_page.dart](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/lib/pages/conscrit_page.dart)** :
  - Vérification GPS périodique (`_checkGpsEvents()`) toutes les 30 secondes.
  - Calcul de distance et déclenchement automatique des événements et déblocage des succès correspondants.

## Résultats de validation

- **`flutter analyze`** : Succès (0 erreurs).
