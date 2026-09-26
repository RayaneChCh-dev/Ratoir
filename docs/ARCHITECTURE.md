# Architecture technique

Ce document explique **comment le code est organisé** et définit les **contrats** entre les modules (les noms, signaux et fonctions sur lesquels chacun peut compter). Si tu changes un contrat, mets ce fichier à jour **dans le même commit** et préviens l'équipe.

---

## 1. Vue d'ensemble

```
main.tscn (Node3D « Main »)
├── WorldEnvironment, Sun (DirectionalLight3D)
├── Camera3D ─────────────── camera_follow.gd  (suit « Player »)
├── Kitchen (Node3D)
│   ├── Floor, WallNorth/South/West/East   (CSGBox3D, use_collision)
│   ├── RatHole                            (CSGCylinder3D, décor pour l'instant)
│   ├── IngredientSpawn ─── ingredient_spawn.tscn
│   ├── ChopStation ─────── chop_station.tscn  (station.gd)
│   ├── CookStation ─────── cook_station.tscn  (station.gd)
│   └── DeliveryCounter ─── delivery_counter.tscn
├── Player ─────────────────── player.tscn (player.gd → hérite de cook.gd)
├── Rat ────────────────────── rat.tscn (rat/rat.gd, profil default.tres)
└── UI (CanvasLayer)
    ├── Score (RichTextLabel) ── hud.gd
    ├── TouchJoystick (Control plein écran) ── touch_joystick.gd
    └── HitButton (TouchScreenButton) ── hit_button.tscn

Autoload (singleton global) : GameState ── game_state.gd
```

## 2. Réglages du projet (`project.godot`)

| Réglage | Valeur | Pourquoi |
|---------|--------|----------|
| Rendu | `gl_compatibility` (bureau **et** mobile) | Seul rendu supporté par l'export Web |
| Fenêtre | 720 × 1280, `stretch_mode = canvas_items`, `aspect = expand` | Portrait ; s'adapte aux écrans plus longs sans bandes noires |
| Orientation | `handheld/orientation = 1` (portrait) | Téléphone tenu verticalement |
| `emulate_touch_from_mouse` | `true` | La souris simule le doigt sur PC : un seul code d'entrée à maintenir |
| Actions d'entrée | `move_left/right/up/down` (WASD + flèches), `hit` (Espace) | Clavier en secours sur PC |
| Autoload | `GameState` | Score et journal accessibles partout |
| Export | preset « Web », `thread_support = false` | Évite de devoir configurer `SharedArrayBuffer`/COOP-COEP sur itch.io |

## 3. Conventions (à respecter par tout le monde)

### Unités et orientation
- **1 unité = 1 mètre.** Le joueur fait environ 1,4 m de haut, un meuble environ 1 m.
- **Le sol est le plan `y = 0`.** Tout ce qui marche reste à `y = 0` (le déplacement est forcé à plat).
- **Le « devant » d'un personnage est l'axe +Z de son nœud `Model`.** Le script fait pivoter `Model` vers la direction de marche avec `atan2(dir.x, dir.z)`.
- **Axes de la cuisine** : +X = droite de l'écran ; −Z = vers le mur du fond (haut de l'écran) ; +Z = vers le bas de l'écran.

### Nœud `Model` : le visuel est séparé de la logique
Chaque personnage a un nœud enfant **`Model`** (Node3D) qui contient **uniquement le visuel**. La collision (`CollisionShape3D`) et les scripts restent sur la racine. **Pour remplacer une capsule par un vrai modèle 3D, on remplace le contenu de `Model`, rien d'autre** (voir [ASSETS.md](ASSETS.md)). Même idée pour les meubles : le mesh visuel (`Counter`, `Board`, `Burner`…) est séparé de l'`Area3D` et de `ItemSlot`.

### Code GDScript
- **Typage statique** partout (`var x := 0`, `func f(a: int) -> void`).
- **Commentaires et textes en français**, noms de code en anglais.
- `class_name` seulement pour ce qui est utilisé ailleurs par son type (`Cook`, `Item`, `Station`, `TouchJoystick`, `ProgressBar3D`).
- ⚠️ **Godot 4.7 a une classe native `VirtualJoystick`** : ne jamais créer de `class_name` qui porte le nom d'une classe native (erreur *« hides a native class »*).
- Indentation par tabulations (voir `.editorconfig`).

### Couches de collision
Les valeurs `collision_layer` et `collision_mask` sont des masques de bits :

| Objet | Couche (valeur) | Masque |
|-------|----------------|--------|
| Murs, sol, meubles | world (1) | — |
| Joueur | player (2) | world (1) |
| Rat | rat (4, troisième couche) | world (1) |
| Zones des stations, bac, livraison, rat et objets au sol | aucune (0) | player (2) |

Le rat traverse le joueur ; seul `ContactArea` déclenche le renversement.

## 4. Scripts et contrats

### `GameState` (autoload, `scripts/game_state.gd`)
| Membre | Type | Rôle |
|--------|------|------|
| `score` | `int` | Plats livrés pendant la partie |
| `level` | `int` | Niveau courant ; objectif = `level * 5` plats cumulés |
| `health` | `int` | Santé (3 au départ, +1 à chaque niveau, maximum 3) |
| `time_left` | `float` | Temps restant dans le niveau |
| `STAR_THRESHOLDS` | `Array[int]` = `[5, 10, 15]` | Paliers d'étoiles |
| `add_point()` | fonction | +1 point, émet `score_changed` |
| `stars() -> int` | fonction | Étoiles (0 à 3) pour le score actuel |
| `target_score() -> int` | fonction | Objectif cumulatif du niveau (`level * 5`) |
| `round_duration_for_level() -> float` | fonction | 90 s au niveau 1, -5 s par niveau, minimum 60 s |
| `difficulty_scale() -> float` | fonction | Multiplicateur de difficulté du rat : +15 % par niveau, plafonné à 2× |
| `take_damage(amount, reason)` | fonction | Retire de la santé ; zéro santé termine et met le jeu en pause |
| `reset()` | fonction | Repart au niveau 1, réinitialise score/santé/journal et relance le chrono |
| `log_event(event: String, detail := "")` | fonction | Ajoute au journal et émet `event_logged` |
| `events` | `Array[Dictionary]` | Journal complet de la manche |
| `score_changed(score)` | signal | Le HUD l'écoute |
| `level_changed(level, target_score)` | signal | Le HUD met à jour l'objectif |
| `health_changed(health)` | signal | Le HUD met à jour les vies |
| `time_changed(time_left)` | signal | Le HUD met à jour le chrono |
| `difficulty_changed(level, scale)` | signal | Le rat ajuste sa vitesse et son intervalle de sortie |
| `round_started` / `round_ended(level, score, health)` | signaux | Début/fin d'un niveau |
| `event_logged(entry)` | signal | Le commentateur l'écoute (Phase 5) |

Chaque niveau dure 90 s au niveau 1, puis 5 s de moins par niveau (minimum 60 s). Le score est cumulatif : atteindre 5, 10, 15… plats valide le niveau suivant. Un chrono expiré retire une vie et relance le niveau ; un dégât direct du rat passe par `take_damage()`. Le renversement au contact retire une vie via `take_damage()` ; le vol et l’extinction de plaque ne retirent pas de vie. Le rat écoute `difficulty_changed` : vitesse multipliée et délai de sortie divisé par `difficulty_scale()`, sans modifier la ressource de profil. Le délai de fuite après un coup reste de 10 s. Voir [PHASE-4](phases/PHASE-4-manche.md).

### `Item` (`scripts/item.gd`) : un ingrédient
- `enum State { RAW, CHOPPED, COOKED }` : tomate crue → tranches → assiette.
- Assigner `item.state` reconstruit le visuel automatiquement (`_rebuild()`).
- `get_item_name() -> String` : description française de l’état, utilisée dans les événements.
- Créé par code : `Item.new()` (il n'y a pas de scène `.tscn`). Son origine est **en bas de l'objet** : il se pose sur un point.

### `Cook` (`scripts/cook.gd`) : la base du cuisinier
- `held_item: Item` : l'objet tenu, ou `null`.
- `hold(item)` : met l'objet dans les mains (sur `Model/HoldPoint`) ; il peut venir d'une station ou être neuf.
- `has_item() -> bool` : mains occupées.
- `take_item() -> Item` : retire l'objet des mains et le renvoie. **L'appelant doit le re-parenter ou le libérer.**
- Le rat **n'est pas** un `Cook`. Les stations n'interagissent qu'avec les `Cook`.

### `Player` (`scripts/player.gd`, hérite de `Cook`)
- Lit `joystick.output` (`Vector2`, x = droite, y = bas, longueur de 0 à 1) ; si c'est nul, lit le clavier.
- Convertit l'entrée écran en direction au sol **à partir de la caméra**, pour que « haut » à l'écran corresponde toujours à « haut » dans le jeu.
- `motion_mode = FLOATING`, `velocity.y = 0` et `y` forcé à 0 : aucun mouvement vertical possible.
- Réglages : `speed` (6 m/s), `acceleration`, `turn_speed`.
- **Visuel** : `Model/Chef` est le modèle `assets/models/characters/chef.glb` (échelle 0,95 : ≈ 2 m avec la toque, volontairement exagéré pour la lisibilité). `Model/HoldPoint` est devant ses mains.
- **Animations** : `_update_animation()` trouve le premier `AnimationPlayer` sous `Model`, met toutes ses animations en boucle, puis joue `idle` (arrêt, < `idle_threshold`), `walk` ou `run` (au-dessus de `run_threshold` = 3 m/s). La cadence suit la vitesse réelle (`walk_anim_speed`, `run_anim_speed`) pour limiter l'effet de glisse.

### `Station` (`scripts/station.gd`) : Découpe et Cuisson
- Réglages : `accepts` (état accepté), `produces` (état produit), `duration`, `rug_color`.
- À chaque image de physique, pour chaque `Cook` dans son `Area3D` :
  1. Station vide et le cuisinier tient un objet à l'état `accepts` → l'objet est posé et la transformation démarre.
  2. Objet terminé (`produces`) et cuisinier les mains vides → il reprend l'objet.
- Nœuds attendus dans la scène : `Rug`, `ItemSlot`, `Area3D`, `Progress` (`ProgressBar3D`).
- Groupe `stations` ; `has_item()`, `is_transforming_item()`, `steal_item()`, `switch_off()`, `approach_point()`.
- `is_transforming_item()` évite le nom natif Godot `Node.is_processing()`.
- `can_be_switched_off` est activé uniquement sur la plaque. `switched_off` suspend `_elapsed` et grise `Burner`. Le prochain contact rallume, même mains pleines, sans autre interaction sur cette image.
- `ApproachPoint` est placé devant le meuble ; `steal_item()` vide la station et réinitialise la progression.

### `Rat`, `Sabotage`, `RatProfile`, `FloorItem`
- Une instance de `rat.tscn`, groupe `rat`, lit `data/rat_profiles/default.tres`.
- États : `HIDDEN`, `EMERGING`, `GOING`, `SABOTAGING`, `RETURNING`, `FLEEING`. Départ protégé de 5 s ; pauses pondérées par le profil.
- `Sabotage.can_apply()` choisit une cible ; `is_valid()` revalide cette même cible sans la changer ; `target_position()` et `apply()` complètent le contrat commun.
- Poursuite limitée à 4 s, trajet normal à 6 s. Retour/fuite bloqués : retour caché au trou au bout de 6 s ; un objet volé est laissé au sol avant ce secours.
- Le vol est enregistré à l’arrivée au trou. `hit() -> bool` indique si le coup est accepté, lâche l’objet, puis impose une fuite et 10 s caché.
- `FloorItem` transfère l’objet à un `Cook` libre dans sa zone, y compris si ses mains se libèrent après son entrée ; le rebond est arrêté au ramassage.
- À chaque `round_started`, le rat retourne caché au trou avec 5 s de protection ; un objet volé est déposé au sol et reste récupérable. La pause de fin de partie fige le rat, le joueur et les stations. Le HUD reste actif et le joystick est remis à zéro.

### `IngredientSpawn`, `DeliveryCounter`
- Le bac donne `Item.new()` à tout `Cook` qui arrive les mains vides.
- Le comptoir accepte un `Item` `COOKED` : `GameState.add_point()`, `log_event("dish_delivered")` et une animation « +1 ».

### `TouchJoystick` (`scripts/touch_joystick.gd`)
- `Control` plein écran avec `mouse_filter = IGNORE`. Il écoute `_input` (événements `InputEventScreenTouch`/`Drag`) et suit **un seul doigt** (`_touch_index`).
- `output: Vector2` avec zone morte (`dead_zone`) et progression douce.
- `ignore_zones` référence le bouton TAPER : un appui commencé dessus ne démarre pas le joystick. `TouchScreenButton` accepte un deuxième doigt ; son placement suit la taille du viewport.

### `camera_follow.gd`
- Caméra orthographique inclinée à −55° sur X, `keep_aspect = largeur`, `size = 10` (≈ 9 m visibles en largeur).
- `target` : le nœud à suivre. `dead_zone` : demi-taille de la zone morte en mètres. `follow_speed` : douceur du suivi. `bounds` : emprise de la cuisine (x, z, largeur, profondeur).
- Le point visé est **borné** : la zone visible au sol est **mesurée en lançant des rayons depuis les bords de l'écran** (`project_ray_origin/normal`), donc c'est juste quelle que soit la taille de l'écran.
- **Si tu agrandis la cuisine, mets à jour `bounds`.**

### `ProgressBar3D`
- Deux rectangles sans ombrage (`unshaded`) orientés vers la caméra, dessinés **par-dessus** le décor (`no_depth_test`). `set_value(0..1)`, `show()`/`hide()`.

## 5. Journal d'événements

Toujours passer par `GameState.log_event(event, detail)`. `t` (secondes depuis le début de la manche) est ajouté automatiquement.

**Noms d'événements autorisés** (en ajouter un = mettre à jour cette liste) :

| Événement | Émis par | `detail` (exemple) | Phase |
|-----------|----------|--------------------|-------|
| `round_start` | GameState | `"manche de 90 s"` | 4 |
| `dish_delivered` | DeliveryCounter | `"assiette de tomates cuites"` | ✅ 2 |
| `rat_appeared` | Rat | `"Gaston sort de son trou"` | 3 |
| `sabotage_stove_off` | Rat / CookStation | `"le rat a éteint la plaque"` | 3 |
| `sabotage_spill` | Rat | `"le rat a renversé l'assiette"` | 3 |
| `sabotage_steal` | Rat | `"le rat a volé une tomate découpée"` | 3 |
| `stove_relit` | CookStation | `"le chef a rallumé la plaque"` | 3 |
| `rat_hit` | Player | `"bonk ! le rat est assommé"` | 3 |
| `rat_fled` | Rat | `"le rat retourne dans son trou"` | 3 |
| `item_recovered` | Player | `"tomate récupérée au sol"` | 3 |
| `judge_verdict` | Judge | `"Velouté à la sauvette : 5/5, « Je vais l'encadrer. »"` | ✅ 6 |
| `timer_milestone` | GameState | `"30 s restantes"` / `"10 s restantes"` | 4 |
| `round_end` | GameState | `"score 9, 1 étoile"` | 4 |
| `level_up` | GameState | `"niveau 2"` | 4 |
| `player_damaged` | GameState | `"rat"` | 4 |

## 6. Ajouter une nouvelle station (exemple)

1. Dupliquer `scenes/chop_station.tscn`, puis changer le visuel du dessus (`Board` → autre chose) et le `Label3D`.
2. Régler `accepts`, `produces`, `duration` et `rug_color` dans l'inspecteur.
3. Si un nouvel état d'objet est nécessaire : l'ajouter à `Item.State` **à la fin** de l'enum (les scènes stockent les états sous forme de nombres) et ajouter son visuel dans `Item._rebuild()`.
4. L'instancier dans `main.tscn` sous `Kitchen`, contre un mur, **sans que son tapis chevauche un autre tapis**.

## 7. Tester sans téléphone

- **Dans l'éditeur** : <kbd>F5</kbd>, puis clic-glisser.
- **Tests automatisés rapides** : un petit script qui téléporte le joueur de station en station et affiche l'état en console. C'est comme ça que les phases 1 et 2 ont été vérifiées :
  ```bash
  godot --headless --path . res://mon_test.tscn          # sans affichage
  godot --path . --write-movie /tmp/f.png --fixed-fps 60 res://mon_test.tscn   # avec captures image par image
  ```
  Mettre ces fichiers de test **hors du dépôt**, ou les supprimer avant de committer.
- **Vérifier qu'il n'y a pas d'erreur de chargement** : `godot --headless --path . --quit-after 60`.
