# Introduction de la notion de Tabagn's du conscrit et mise à jour du Monôme

## Problem Statement & Background

We need to introduce the concept of the conscrit's "tabagn's" in Tamagonscrit:
1. **New Conscrit Field**: `tabagns` stored in `conscrit_state` and `conscrits` tables.
2. **RKL Popup**: If a conscrit does not have a `tabagn's`, a popup appears: "C'est la RKL ! $name doit choisir son tabagn's :" with a dropdown list proposing the different tabagn's with their full names (e.g., KIN (Ai), Boquette (An), etc.).
3. **Dynamic Background**: When the conscrit has a tabagn's, the background image changes accordingly (`fond_ai.png`, `fond_an.png`, etc.).
4. **Monome Display**: When the conscrit achieves their Zcu, the tabagn's is saved in the `conscrits` table. In the Monome page, each conscrit tile displays: `(bucque) (fam's du joueur) (bigrame TBK) (ordre de création)` where the creation order represents seniority in the monome (oldest = 1, next = 2, etc.).

## User Review Required

> [!IMPORTANT]
> - Ensure Supabase tables (`conscrit_state` and `conscrits`) include the `tabagns` column.
> - The RKL popup blocks interaction until a tabagn's is chosen if none is set.

## Proposed Changes

### Conscrit Management & UI

#### [MODIFY] [conscrit_page.dart](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/lib/pages/conscrit_page.dart)
- Add `_tabagns` state variable.
- Load `tabagns` from `conscrit_state`. If missing/null, trigger the RKL selection popup dialog.
- Save `tabagns` in Supabase (`conscrit_state` update and `conscrits` insert).
- Dynamically select the background asset: `assets/fond_${_tabagns!.toLowerCase()}.png` if `_tabagns` is not empty, else `assets/fond.png`.

#### [MODIFY] [monome_page.dart](file:///C:/Users/ygour/Documents/GitHub/Tamagonscrit/lib/pages/monome_page.dart)
- Fetch user profile (`fams`, `tabagns`) from `profiles` table.
- Load `conscrits` ordered by `created_at` ascending to compute seniority order (`1`, `2`, `3`, etc.).
- Update `_buildConscritTile` to display `(bucque) (fam's) (bigrame TBK) (ordre de création)`.

## Verification Plan

### Automated Tests
- Build and compile check (`flutter build` / analyzer).

### Manual Verification
- Launch app, verify RKL popup appears when conscrit has no tabagn's.
- Choose a tabagn's (e.g., Ai) and verify background changes to `fond_ai.png`.
- Achieve Zcu and verify conscrit appears in Monome with correct format: bucque, fam's, bigram TBK, and creation order.
