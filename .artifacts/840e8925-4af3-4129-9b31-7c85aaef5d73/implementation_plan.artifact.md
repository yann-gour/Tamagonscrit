# Affichage de la liste des joueurs au clic sur un groupe dans la page Zprom's

## User Review Required

> [!IMPORTANT]
> Lorsqu'un utilisateur clique sur une carte de groupe (dans les onglets *Top tabagn's*, *Top prom's*, *Prom's paires vs impaires*, ou *PG/JP/TVA*), une boîte de dialogue (Popup / AlertDialog) s'ouvrira pour afficher :
> - La liste de tous les joueurs (bucques, fam's, score) appartenant à ce groupe.
> - Le nombre total de membres du groupe.
> - Le tri des joueurs du groupe par score décroissant.

## Proposed Changes

### Leaderboard Component

#### [MODIFY] [leaderboard_page.dart](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/lib/pages/leaderboard_page.dart)

- Ajouter une méthode utilitaire `_showGroupPlayersDialog(String groupTitle, List<GadzScore> players)` pour afficher l'interface modale des membres d'un groupe.
- Ajouter la gestion du clic (`onTap`) sur les cartes des 4 vues de groupes :
  - `_buildTopTabagnsView()` : filtre les joueurs du tabagn's sélectionné.
  - `_buildTopPromsView()` : filtre les joueurs de la prom's sélectionnée.
  - `_buildTopPromsEvenOddView()` : filtre les joueurs ayant une prom's paire ou impaire.
  - `_buildPgJpTvaView()` : filtre les joueurs appartenant au groupe PG, JP ou TVA.

## Verification Plan

### Automated Tests
- Lancer `flutter analyze` pour vérifier l'absence d'erreurs de syntaxe ou de compilation.

### Manual Verification
- Déployer l'application et tester le clic sur différents groupes dans les onglets de classement pour valider l'affichage de la liste des bucques.
