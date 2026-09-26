# Phase 3 — Le rat et les sabotages

| | |
|---|---|
| **Statut** | ⏳ À faire |
| **Dépend de** | Phase 2 ✅ |
| **Débloque** | Équilibrage (Phase 4), événements réels pour le commentateur (Phase 5), personnalité du rat (Phase 6), modèle du rat (Phase 7) |
| **Profil** | Dev gameplay Godot |
| **Estimation** | 2 h 30 à 3 h |
| **Fichiers possédés** | `scenes/rat.tscn`, `scripts/rat/*`, `scenes/main.tscn` (pendant la phase), `scenes/player.tscn`, `scripts/station.gd`, `scripts/touch_joystick.gd` |

---

## 1. Objectif

Un **rat** sort régulièrement du trou dans le mur du fond, va **saboter** la cuisine, puis retourne dans son trou. Le joueur peut le **taper** avec un bouton pour le faire fuir. Tous les sabotages reposent sur **un seul système commun**.

Règles de design : [CONCEPT.md §8](../CONCEPT.md#8-le-rat).

## 2. État jouable exigé (critères d'acceptation)

- [ ] Pendant les **5 premières secondes**, le rat ne sort pas (départ protégé).
- [ ] Ensuite, il sort **régulièrement** du trou, un seul rat à la fois, avec des pauses variables.
- [ ] **Éteindre la plaque** : pendant une cuisson, le rat éteint la plaque, la cuisson se met en pause et la plaque devient visiblement grise. Le joueur la **rallume au contact** et la cuisson reprend là où elle en était.
- [ ] **Voler un ingrédient** : le rat prend l'objet posé sur une station et part vers son trou. S'il y arrive, l'objet est perdu. S'il est tapé en route, il **lâche l'objet au sol**, et le joueur peut le **ramasser au contact** (mains vides).
- [ ] **Renverser le plat** : le rat fonce sur le joueur qui porte un objet. Au contact, l'objet est **perdu** et une flaque apparaît quelques secondes. Le rat est **plus lent** que le joueur : on peut lui échapper.
- [ ] **TAPER** : un bouton dans le coin en bas à droite (et <kbd>Espace</kbd> sur PC). Si le rat est à moins de 1,5 m, il est assommé, lâche ce qu'il porte, fuit et reste caché plus longtemps. Rien ne se passe s'il est trop loin. Petit délai entre deux coups (≈ 0,8 s).
- [ ] Sur téléphone, **deux doigts en même temps** fonctionnent : un doigt pour le joystick, l'autre pour le bouton. Appuyer sur le bouton **ne fait pas bouger** le joueur.
- [ ] Chaque action notable est enregistrée avec `GameState.log_event(...)` (voir §6).
- [ ] **La boucle ne se bloque jamais** : aucune station ne reste coincée, le rat ne reste jamais bloqué dans un mur (délai de secours), et le joueur peut toujours continuer à cuisiner.
- [ ] Testé sur un vrai téléphone.

## 3. Conception technique

### 3.1 Scène du rat (`scenes/rat.tscn`)
```
Rat (CharacterBody3D) ── scripts/rat/rat.gd
├── CollisionShape3D      (capsule couchée ou sphère, rayon ≈ 0,25 m)
├── Model (Node3D)        ← UNIQUEMENT le visuel (remplacé en Phase 7)
│   ├── Body              (capsule grise couchée sur l'axe Z)
│   ├── Tail              (cylindre rose fin, à l'arrière)
│   └── HoldPoint         (Marker3D, devant la bouche : objet volé)
├── ContactArea (Area3D)  (détecte le joueur pour « renverser »)
└── Alert (Label3D « ! »), affiché au-dessus de la CIBLE, pas du rat (ou un nœud séparé)
```
- `motion_mode = FLOATING`, déplacement à plat comme le joueur.
- Couleur : **gris foncé** et queue **rose**. Taille exagérée (≈ 0,5 m de long) pour la lisibilité.

### 3.2 Machine à états du rat (`scripts/rat/rat.gd`)
```
enum State { HIDDEN, EMERGING, GOING, SABOTAGING, RETURNING, FLEEING }
```
| État | Ce qu'il fait | Sortie |
|------|---------------|--------|
| `HIDDEN` | Invisible, collisions désactivées, dans le trou. Attend `_hidden_timer` | Délai écoulé **et** départ protégé terminé **et** au moins un sabotage possible → `EMERGING` |
| `EMERGING` | Apparaît au trou (petite animation d'échelle, 0,3 s), `log_event("rat_appeared")` | → `GOING` |
| `GOING` | Va vers `current_sabotage.target_position()` | Arrivé (< 0,4 m) → `SABOTAGING`. Cible devenue invalide → choisir un autre sabotage ou `RETURNING`. **Plus de 6 s sans arriver → `RETURNING` (secours anti-blocage)** |
| `SABOTAGING` | Reste sur place pendant `windup` (≈ 1 s) : c'est **la fenêtre de réaction du joueur** | Fin du `windup` → `current_sabotage.apply(self)` → `RETURNING` |
| `RETURNING` | Retourne au trou (vitesse normale) | Arrivé → si l'objet volé est encore porté, il est détruit (`sabotage_steal` réussi) → `HIDDEN` avec un délai normal |
| `FLEEING` | Après un coup : lâche son objet, vitesse × 1,5, étoiles « assommé » | Arrivé au trou → `HIDDEN` avec un **délai long** |

**À tout moment hors `HIDDEN`**, `hit()` fait passer en `FLEEING`.

Déplacement : **en ligne droite** vers la cible avec `move_and_slide()`. La cuisine est ouverte et les meubles sont contre les murs, donc ça suffit. Si le rat se coince sur un coin de meuble, ajouter un `NavigationRegion3D` et un `NavigationAgent3D` (seulement si nécessaire).

### 3.3 Un seul système de sabotage (`scripts/rat/sabotage.gd`)
Chaque sabotage est un petit objet qui répond aux **mêmes questions**. Le rat ne connaît que cette interface :
```gdscript
class_name Sabotage
extends RefCounted
## Base commune de tous les sabotages (voir docs/phases/PHASE-3-rat.md §3.3).

var windup := 1.0            # secondes sur place avant l'effet
var weight := 1.0            # probabilité relative d'être choisi (réglée par le profil du rat)

## Le sabotage est-il possible maintenant ? (ex. : il faut qu'une cuisson soit en cours)
func can_apply() -> bool:
	return false

## Où le rat doit aller.
func target_position() -> Vector3:
	return Vector3.ZERO

## Applique l'effet. Appelé quand le rat a fini son windup sur place.
func apply(rat: Rat) -> void:
	pass
```
Implémentations :

| Classe | `can_apply()` | `target_position()` | `apply()` |
|--------|---------------|---------------------|-----------|
| `StoveOffSabotage` | Une station `can_be_switched_off` a un objet **en cours** de transformation et n'est pas déjà éteinte | Le `ApproachPoint` de la plaque | `station.switch_off()`, `log_event("sabotage_stove_off")` |
| `StealSabotage` | Une station a un objet posé (n'importe quel état) | Le `ApproachPoint` de cette station | `rat.carry(station.steal_item())`, `log_event("sabotage_steal")`, puis `RETURNING` |
| `SpillSabotage` | Le joueur tient un objet | **La position actuelle du joueur** (mise à jour à chaque image) ; `windup = 0`, l'effet se déclenche au **contact** (`ContactArea`) | `player.take_item().queue_free()`, crée une flaque, `log_event("sabotage_spill")`. Abandon au bout de 4 s de poursuite |

Choix : parmi les sabotages où `can_apply()` est vrai, **tirage pondéré** par `weight`. Les poids viennent du profil (§3.6).

Pour trouver les cibles **sans chemins de nœuds en dur**, utiliser des **groupes** Godot : `stations` (toutes les stations), `player` (le joueur).

### 3.4 Changements dans `Station` (`scripts/station.gd`)
Ajouter (sans casser la boucle actuelle) :
```gdscript
@export var can_be_switched_off := false   # true uniquement sur la Cuisson
var switched_off := false

func has_item() -> bool
func is_processing() -> bool                 # objet présent et encore à l'état `accepts`
func steal_item() -> Item                    # retire l'objet, remet _elapsed à 0, cache la barre
func switch_off() -> void                    # switched_off = true, visuel « éteint » (brûleur gris, fumée)
func approach_point() -> Vector3             # position du Marker3D « ApproachPoint » sur le tapis
```
- Pendant `switched_off`, **la progression est en pause** (`_elapsed` n'avance plus).
- **Rallumer** : dans `_interact()`, si `switched_off`, n'importe quel contact du `Cook` rallume (même les mains pleines) → `log_event("stove_relit")`. On `return` ensuite : pas d'autre action sur la même image.
- Ajouter un `Marker3D` nommé **`ApproachPoint`** dans `chop_station.tscn` et `cook_station.tscn`, posé sur le tapis, côté cuisine.
- Mettre `can_be_switched_off = true` sur l'instance `CookStation` dans `main.tscn`.

### 3.5 Objets au sol
Quand le rat tapé lâche un objet volé :
- Créer un petit nœud `FloorItem` (`scripts/floor_item.gd` + scène) : un `Node3D` avec un `Area3D` (rayon ≈ 0,6 m) qui contient l'`Item`, posé à `y = 0`.
- Un `Cook` **les mains vides** qui entre dans la zone le ramasse : `cook.hold(item)`, `log_event("item_recovered")`, puis le `FloorItem` se libère.
- Petit rebond ou clignotement pour qu'on le remarque.

### 3.6 Profil du rat (`scripts/rat/rat_profile.gd`), préparé pour la Phase 6
```gdscript
class_name RatProfile
extends Resource

@export var display_name := "Gaston"
@export var intro_line := "Ce soir, c'est moi le chef."
@export_range(2.5, 5.5) var speed := 4.0                 # joueur = 6 m/s : le rat doit rester plus lent
@export_range(0.0, 1.0) var aggressiveness := 0.5         # 0 = rares sorties, 1 = sorties fréquentes
@export var hidden_time_range := Vector2(4.0, 8.0)        # délai entre deux sorties (réduit par l'agressivité)
@export var weight_stove_off := 1.0
@export var weight_steal := 1.0
@export var weight_spill := 1.0
```
- Créer `data/rat_profiles/default.tres` et l'assigner au rat (`@export var profile: RatProfile`).
- **Le rat ne lit que ce profil** : en Phase 6, l'IA remplira un `RatProfile` au lancement, sans rien changer au code du rat.

### 3.7 Le bouton TAPER
- Action d'entrée **`hit`** : l'ajouter dans *Projet → Paramètres → Contrôles* avec la touche <kbd>Espace</kbd>.
- Bouton : **`TouchScreenButton`** (et **pas** un `Button`), dans `UI`, en bas à droite. Régler `action = "hit"`, une texture ronde (≈ 180 px) avec une icône de poêle, et `visibility_mode = TOUCHSCREEN_ONLY` si on veut le cacher sur PC.
  > Pourquoi `TouchScreenButton` ? Il gère le **multitouch** : il réagit à un deuxième doigt pendant que le premier tient le joystick. Un `Button` classique ne reçoit que le premier doigt (via la souris émulée).
- **Joystick** : `touch_joystick.gd` doit **ignorer un appui qui commence sur le bouton**. Ajouter par exemple :
  ```gdscript
  @export var ignore_zones: Array[TouchScreenButton] = []

  func _is_in_ignore_zone(pos: Vector2) -> bool:
  	for button in ignore_zones:
  		var size := button.texture_normal.get_size() * button.global_scale
  		if Rect2(button.global_position, size).has_point(pos):
  			return true
  	return false
  ```
  et, dans `_input`, ne pas démarrer le joystick si `_is_in_ignore_zone(event.position)`.
- **Joueur** (`player.gd`) : si `Input.is_action_just_pressed("hit")` et que le délai est écoulé → chercher le rat (groupe `rat`) ; s'il est à moins de 1,5 m et pas `HIDDEN` → `rat.hit()` et `log_event("rat_hit")`. Retour visuel minimal : « BONK ! » en `Label3D` qui s'envole et le rat qui clignote. Les effets plus riches viendront en Phase 7.

### 3.8 Couches de collision (à mettre en place)
| Couche | Qui | `collision_layer` | `collision_mask` |
|-------:|-----|------------------|------------------|
| 1 `world` | murs, sol, meubles | 1 | — |
| 2 `player` | joueur | 2 | 1 (murs) |
| 3 `rat` | rat | 3 | 1 (murs). Il **traverse** le joueur, et le contact passe par `ContactArea` |
| — | `Area3D` des stations, bac, comptoir | — | **2** (le joueur) ⚠️ |
| — | `ContactArea` du rat | — | 2 |
| — | `FloorItem` | — | 2 |

⚠️ **Piège n°1 de la phase** : si tu mets le joueur sur la couche 2 **sans** mettre à jour le `collision_mask` des `Area3D` existants (stations, bac, comptoir), **plus aucune interaction ne marche**. Mettre à jour le tableau de [ARCHITECTURE.md](../ARCHITECTURE.md#couches-de-collision).

### 3.9 Départ protégé
Tant que la Phase 4 n'existe pas, le rat garde un compteur local : `_protected_time = 5.0`, décrémenté depuis son `_ready`. **Dès que la Phase 4 est fusionnée**, le remplacer par l'écoute de `GameState.round_started` (le rat ne sort que pendant `PLAYING`) et le cacher sur `round_ended`. Se coordonner avec la personne de la Phase 4.

## 4. Découpage en tâches

1. [ ] Couches de collision (§3.8) + vérifier que la boucle marche toujours.
2. [ ] `rat.tscn` + déplacement vers un point + `HIDDEN`/`EMERGING`/`RETURNING` (sans sabotage) : il sort, va au centre et revient.
3. [ ] `Sabotage` + `StoveOffSabotage` + changements de `Station` (`switch_off`, rallumage, `ApproachPoint`).
4. [ ] Bouton **TAPER** + `hit()` + `FLEEING` + exclusion de zone dans le joystick. **Tester sur téléphone à deux doigts.**
5. [ ] `StealSabotage` + `FloorItem`.
6. [ ] `SpillSabotage` + flaque.
7. [ ] `RatProfile` + `default.tres` + tirage pondéré.
8. [ ] Événements `log_event` partout (§6), départ protégé, secours anti-blocage.
9. [ ] Mise à jour de la doc : ARCHITECTURE (couches, API `Station`, rat), cases de cette fiche.

## 5. Tests à faire

| Scénario | Attendu |
|----------|---------|
| Lancer le jeu et ne rien faire pendant 5 s | Le rat ne sort pas |
| Rester loin de la plaque pendant une cuisson | Le rat finit par l'éteindre ; la barre s'arrête ; la plaque change de visuel |
| Toucher la plaque éteinte | Elle se rallume et la barre reprend là où elle en était |
| Taper le rat pendant son windup sur la plaque | Le sabotage n'a pas lieu, le rat fuit |
| Laisser une tomate sur la planche et s'éloigner | Le rat la vole et repart vers le trou |
| Taper le rat qui porte la tomate | Il la lâche au sol ; en passant dessus mains vides, on la reprend |
| Porter une assiette près du rat | Il fonce sur le joueur ; au contact, l'assiette est perdue et une flaque apparaît |
| Fuir le rat avec une assiette | On le distance ; il abandonne au bout de ≈ 4 s |
| Appuyer sur TAPER loin du rat | Rien (le délai du bouton se lance quand même) |
| Téléphone : joystick d'un pouce, TAPER de l'autre | Les deux marchent en même temps ; le bouton ne déplace pas le joueur |
| Jouer 3 minutes d'affilée | Jamais de station bloquée ni de rat coincé ; la console Godot reste sans erreur |

Test automatisé conseillé (comme en Phase 2) : téléporter le joueur, forcer `rat.start_sabotage(StoveOffSabotage.new(...))` et vérifier les états dans la console.

## 6. Événements à émettre

| Moment | Appel |
|--------|-------|
| Le rat sort | `GameState.log_event("rat_appeared", "%s sort de son trou" % profile.display_name)` |
| Plaque éteinte | `log_event("sabotage_stove_off", "le rat a éteint la plaque")` |
| Plaque rallumée | `log_event("stove_relit", "le chef a rallumé la plaque")` |
| Vol réussi (arrivé au trou) | `log_event("sabotage_steal", "le rat a volé une tomate découpée")` (préciser l'état de l'objet) |
| Plat renversé | `log_event("sabotage_spill", "le rat a renversé l'assiette")` |
| Rat tapé | `log_event("rat_hit", "bonk ! le rat est assommé")` |
| Rat de retour au trou après un coup | `log_event("rat_fled", "le rat retourne dans son trou")` |
| Objet ramassé au sol | `log_event("item_recovered", "tomate récupérée au sol")` |

## 7. Pièges connus

- **Couches de collision** : voir §3.8. C'est le bug le plus probable.
- **Un objet ne doit avoir qu'un seul parent** : toujours passer par `reparent()`, ou `take_item()` puis ajout. Ne jamais garder deux références qui « possèdent » le même `Item`.
- **Rat caché** : penser à désactiver sa `CollisionShape3D` **et** sa `ContactArea` (`set_deferred("disabled", true)`), pas seulement le cacher.
- **Plusieurs contacts sur la même image** : garder la logique « une action par contact et par image » (le `return` après le rallumage).
- **Pas de `await` dans `_physics_process`** pour les délais : utiliser des compteurs (`_timer -= delta`). C'est plus prévisible et plus facile à mettre en pause (Phase 4).

## 8. Hors périmètre de cette phase
- Modèle 3D et animations du rat → Phase 7.
- Nom et personnalité générés par IA → Phase 6 (le rat lit déjà un `RatProfile`).
- Commentaires sur les sabotages → Phase 5 (qui écoute simplement `event_logged`).
