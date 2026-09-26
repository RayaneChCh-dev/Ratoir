# Phase 2 — Boucle de cuisine + passage en portrait ✅ Terminé

> Fiche conservée pour l'historique.

## Objectif
Une boucle de cuisine complète et jouable : **ramasser → découper → cuire → livrer → score**, sans sabotage.

## Ce qui a été fait
- **Interactions automatiques au contact** (pas de bouton) : un `Area3D` devant chaque meuble, avec un tapis coloré qui montre la zone.
- `Item` : tomate **crue → découpée → cuite (assiette)**, visuel reconstruit à chaque changement d'état.
- `Cook` : base du cuisinier, qui tient un objet à la fois (`hold()`, `take_item()`).
- `Station` (script unique pour Découpe 1,5 s et Cuisson 2,5 s), avec une barre de progression 3D.
- Bac à tomates, comptoir de livraison avec « +1 », score dans `GameState` (autoload) et HUD.
- **Refonte après les retours du jury** :
  - adversaire rouge supprimé → à la place, **trou du rat** dans le mur du fond ;
  - **portrait** 720 × 1280, cuisine droite de 12 × 22 m en **plongée à 55°** ;
  - **caméra qui suit** le joueur (zone morte, bornée à la cuisine) ;
  - paliers d'**étoiles** 5 / 10 / 15 dans `GameState.stars()`.
- `GameState.log_event()` : le journal d'événements est en place (`dish_delivered` est déjà émis).

## Validé
Test automatisé : bac → découpe → cuisson → livraison, et le score passe à 1. La caméra suit le joueur au joystick sans montrer l'extérieur de la cuisine. Le jeu fonctionne sur téléphone dans le navigateur.

## Laissé pour plus tard
- Chrono, écran de fin et affichage des étoiles → [Phase 4](PHASE-4-manche.md).
- **Équilibrage** : ≈ 13 s par plat aujourd'hui, donc ★★★ (15 plats) est impossible en 90 s → [Phase 4](PHASE-4-manche.md#4-équilibrage).
