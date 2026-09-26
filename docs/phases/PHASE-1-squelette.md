# Phase 1 — Squelette ✅ Terminé

> Fiche conservée pour l'historique : elle explique ce qui existe et pourquoi.

## Objectif
Une scène 3D avec une caméra fixe et un joueur qu'on déplace au doigt, exportée en Web et **testée sur un vrai téléphone**.

## Ce qui a été fait
- Projet Godot 4.7, rendu **Compatibility** (obligatoire pour le Web).
- `scenes/player.tscn` : `CharacterBody3D` (capsule bleue), déplacement **uniquement horizontal** (`motion_mode = FLOATING`, `y` forcé à 0), rotation douce vers la direction de marche.
- `scripts/touch_joystick.gd` : joystick **flottant plein écran** (le pouce se pose n'importe où), avec zone morte et progression douce. La souris le simule sur PC.
- Contrôles clavier en secours (ZQSD/WASD/flèches).
- Preset d'export **Web sans threads** (`export_presets.cfg`), donc pas besoin de `SharedArrayBuffer` sur itch.io.
- Validé : le joueur se déplace, ne traverse pas les murs, et le build tourne dans le navigateur d'un téléphone.

## Ce qu'on a appris (pièges)
- **Godot 4.7 a une classe native `VirtualJoystick`** : notre classe s'appelle donc `TouchJoystick`.
- **Godot Web exige HTTPS** (ou `localhost`). En HTTP sur l'IP du PC, le téléphone affiche *« Secure Context — use HTTPS »*. D'où `tools/serve_https.py`.
- Un navigateur **met en pause le jeu** quand son onglet est en arrière-plan : c'est normal, ce n'est pas un bug.

## Évolutions ultérieures
Le bot statique de test a été supprimé en Phase 2 (remplacé par le concept du rat), et la vue isométrique en paysage est passée en portrait avec une caméra qui suit le joueur.
