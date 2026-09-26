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
└── UI (CanvasLayer)
    ├── Score (RichTextLabel) ── hud.gd
    └── TouchJoystick (Control plein écran) ── touch_joystick.gd

Autoload (singleton global) : GameState ── game_state.gd
```

## 2. Réglages du projet (`project.godot`)

| Réglage | Valeur | Pourquoi |
|---------|--------|----------|
| Rendu | `gl_compatibility` (bureau **et** mobile) | Seul rendu supporté par l'export Web |
| Fenêtre | 720 × 1280, `stretch_mode = canvas_items`, `aspect = expand` | Portrait ; s'adapte aux écrans plus longs sans bandes noires |
| Orientation | `handheld/orientation = 1` (portrait) | Téléphone tenu verticalement |
| `emulate_touch_from_mouse` | `true` | La souris simule le doigt sur PC : un seul code d'entrée à maintenir |
| Actions d'entrée | `move_left/right/up/down` (ZQSD/WASD + flèches) | Clavier en secours sur PC |
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
**Aujourd'hui, tout est sur la couche 1.** Les `Area3D` filtrent par type de script (`body is Cook`). À la Phase 3 on introduit les couches suivantes. La personne qui fait la Phase 3 les met en place **et** met à jour ce tableau :

| Couche | Nom | Qui |
|-------:|-----|-----|
| 1 | `world` | murs, sol, meubles |
| 2 | `player` | le cuisinier |
| 3 | `rat` | le rat |
| 4 | `pickup` | objets tombés au sol (ramassables) |

## 4. Scripts et contrats

### `GameState` (autoload, `scripts/game_state.gd`)
| Membre | Type | Rôle |
|--------|------|------|
| `score` | `int` | Points de la manche |
| `STAR_THRESHOLDS` | `Array[int]` = `[5, 10, 15]` | Paliers d'étoiles |
| `add_point()` | fonction | +1 point, émet `score_changed` |
| `stars() -> int` | fonction | Étoiles (0 à 3) pour le score actuel |
| `log_event(event: String, detail := "")` | fonction | Ajoute au journal et émet `event_logged` |
| `events` | `Array[Dictionary]` | Journal complet de la manche |
| `score_changed(score)` | signal | Le HUD l'écoute |
| `event_logged(entry)` | signal | Le commentateur l'écoute (Phase 5) |

*Phase 4 ajoutera* : l'état de la manche (`READY`, `PLAYING`, `ENDED`), le chrono, `start_round()`, `reset()` et les signaux `round_started`/`round_ended`. Voir [PHASE-4](phases/PHASE-4-manche.md).

### `Item` (`scripts/item.gd`) : un ingrédient
- `enum State { RAW, CHOPPED, COOKED }` : tomate crue → tranches → assiette.
- Assigner `item.state` reconstruit le visuel automatiquement (`_rebuild()`).
- Créé par code : `Item.new()` (il n'y a pas de scène `.tscn`). Son origine est **en bas de l'objet** : il se pose sur un point.

### `Cook` (`scripts/cook.gd`) : la base du cuisinier
- `held_item: Item` : l'objet tenu, ou `null`.
- `hold(item)` : met l'objet dans les mains (sur `Model/HoldPoint`) ; il peut venir d'une station ou être neuf.
- `take_item() -> Item` : retire l'objet des mains et le renvoie. **L'appelant doit le re-parenter ou le libérer.**
- Le rat **n'est pas** un `Cook`. Les stations n'interagissent qu'avec les `Cook`.

### `Player` (`scripts/player.gd`, hérite de `Cook`)
- Lit `joystick.output` (`Vector2`, x = droite, y = bas, longueur de 0 à 1) ; si c'est nul, lit le clavier.
- Convertit l'entrée écran en direction au sol **à partir de la caméra**, pour que « haut » à l'écran corresponde toujours à « haut » dans le jeu.
- `motion_mode = FLOATING`, `velocity.y = 0` et `y` forcé à 0 : aucun mouvement vertical possible.
- Réglages : `speed` (6 m/s), `acceleration`, `turn_speed`.

### `Station` (`scripts/station.gd`) : Découpe et Cuisson
- Réglages : `accepts` (état accepté), `produces` (état produit), `duration`, `rug_color`.
- À chaque image de physique, pour chaque `Cook` dans son `Area3D` :
  1. Station vide et le cuisinier tient un objet à l'état `accepts` → l'objet est posé et la transformation démarre.
  2. Objet terminé (`produces`) et cuisinier les mains vides → il reprend l'objet.
- Nœuds attendus dans la scène : `Rug`, `ItemSlot`, `Area3D`, `Progress` (`ProgressBar3D`).
- *Phase 3 ajoutera* un état « sabotée » (ex. plaque éteinte) : voir [PHASE-3](phases/PHASE-3-rat.md).

### `IngredientSpawn`, `DeliveryCounter`
- Le bac donne `Item.new()` à tout `Cook` qui arrive les mains vides.
- Le comptoir accepte un `Item` `COOKED` : `GameState.add_point()`, `log_event("dish_delivered")` et une animation « +1 ».

### `TouchJoystick` (`scripts/touch_joystick.gd`)
- `Control` plein écran avec `mouse_filter = IGNORE`. Il écoute `_input` (événements `InputEventScreenTouch`/`Drag`) et suit **un seul doigt** (`_touch_index`).
- `output: Vector2` avec zone morte (`dead_zone`) et progression douce.
- ⚠️ **Phase 3** : il faudra qu'il **ignore les appuis qui commencent sur le bouton TAPER** (sinon, appuyer sur le bouton fait aussi bouger le joueur).

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
| `timer_milestone` | GameState | `"30 s restantes"` / `"10 s restantes"` | 4 |
| `round_end` | GameState | `"score 9, 1 étoile"` | 4 |

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
