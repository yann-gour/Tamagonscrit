# Walkthrough - Affichage des membres d'un groupe au clic

J'ai implémenté la fonctionnalité permettant d'afficher la liste détaillée des joueurs (bucques, fam's et scores) appartenant à un groupe lorsque l'on clique sur sa carte dans les différents onglets de classement (Tabagn's, Prom's, Paires/impaires, et PG/JP/TVA).

## Changes

### Leaderboard Page

#### [leaderboard_page.dart](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/lib/pages/leaderboard_page.dart)

- Ajout de la boîte de dialogue modale `_showGroupPlayersDialog(groupTitle, players)` listant les membres du groupe triés par score décroissant.
- Enveloppement des éléments de cartes (`ListTile` dans `InkWell`) sur les 4 vues de groupes pour intercepter les clics et filtrer dynamiquement les joueurs correspondants.

## Verification Results

### Automated Tests
- `flutter analyze` exécuté avec succès : **0 erreurs**.
