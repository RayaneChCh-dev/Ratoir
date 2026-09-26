# Phase 4 — Manche complète : écran titre, chrono, étoiles, rejouer

| | |
|---|---|
| **Statut** | 🚧 En cours — progression et rat connectés |
| **Dépend de** | Phase 2 ✅ (l'équilibrage final dépend aussi de la Phase 3) |
| **Débloque** | Phase 6 (récap' sur l'écran de fin), Phase 8 (démo) |
| **Profil** | Dev gameplay/UI Godot |
| **Estimation** | 1 h 30 à 2 h (+ 30 min d'équilibrage avec le rat) |
| **Fichiers possédés** | `scripts/game_state.gd`, `scenes/ui/*`, `scripts/ui/*`, `scripts/hud.gd` |

---

## 1. Objectif

Transformer la boucle en **une vraie partie, du début à la fin**, puis en progression de niveaux :

**écran titre** « Touchez pour commencer » → **3, 2, 1, Cuisinez !** → **niveau chronométré** → niveau suivant si l'objectif est atteint, sinon perte d'une vie et nouvel essai → **partie terminée** à 0 vie.

## 2. État jouable exigé (critères d'acceptation)

- [ ] Au lancement : écran titre (nom du jeu, « Touchez pour commencer »). Rien ne bouge derrière.
- [ ] Le premier contact **déverrouille l'audio** du navigateur : un petit son « pop » est joué à ce moment-là.
- [ ] Compte à rebours **3, 2, 1, Cuisinez !**, puis la manche démarre.
- [ ] **Chrono visible** en haut (à côté du score). Il passe en rouge et clignote dans les 10 dernières secondes.
- [ ] Événements `round_start`, `timer_milestone` (30 s et 10 s restantes) et `round_end` enregistrés.
- [ ] À 0 : le jeu se fige (joueur, rat et stations), « Temps écoulé ! » s'affiche, puis l'écran de fin.
- [ ] Écran de fin : **score**, **étoiles** qui apparaissent une par une (0 à 3, paliers 5/10/15), une **zone de texte pour le récap'** (texte de secours pour l'instant, remplacé en Phase 6) et un bouton **Rejouer**.
- [ ] **Rejouer** relance une manche propre : score à 0, journal vidé, cuisine vide, rat caché.
- [ ] Équilibrage fait (§4) et valeurs reportées dans [CONCEPT.md](../CONCEPT.md#7-la-manche-le-score-et-les-étoiles).
- [ ] Progression : objectif cumulatif de 5 plats par niveau, chrono -5 s par niveau (90 s au départ, minimum 60 s), difficulté du rat +15 % par niveau (plafond 2×).
- [ ] Santé : 3 vies, +1 vie par niveau réussi (maximum 3), -1 à l'expiration du chrono ou sur dégât direct du rat ; à 0, la partie se termine.
- [ ] Testé sur un vrai téléphone, audio compris.

## 3. Conception technique

### 3.1 État de la manche dans `GameState`
La progression conserve le score entre les niveaux : `target_score() == level * 5`. Le chrono redémarre à chaque niveau avec `max(60, 90 - 5 * (level - 1))`. Le rat écoute `difficulty_changed(level, scale)` et utilise `difficulty_scale()` pour augmenter sa vitesse et réduire son délai caché. Tout dégât direct passe par `GameState.take_damage()`.

```gdscript
enum RoundState { TITLE, COUNTDOWN, PLAYING, ENDED }

signal round_state_changed(state: RoundState)
signal round_started
signal round_ended(score: int, stars: int)
signal time_changed(time_left: float)

@export var round_duration := 90.0      # à régler à l'équilibrage
var round_state := RoundState.TITLE
var time_left := 0.0

func start_round() -> void      # remet _round_start_ms à maintenant, time_left = round_duration, PLAYING, log_event("round_start")
func is_playing() -> bool
func reset() -> void            # score = 0, events.clear(), round_state = TITLE, etc.
```
- Le chrono avance dans `GameState._process()` **uniquement** en `PLAYING`.
- Les paliers 30 s et 10 s : `log_event("timer_milestone", "30 s restantes")`, **une seule fois** chacun (garder un indicateur booléen).
- Fin : `round_state = ENDED`, `log_event("round_end", "score %d, %d étoile(s)" % [score, stars()])`, puis émettre `round_ended`.

### 3.2 Figer le jeu
**Méthode conseillée : la pause de Godot.**
- `get_tree().paused = true` hors `PLAYING` : tout ce qui est en `process_mode = INHERIT` (joueur, rat, stations) s'arrête.
- Les écrans d'interface (titre, compte à rebours, fin) ont **`process_mode = PROCESS_MODE_ALWAYS`**.
- `GameState` (autoload) aussi en `ALWAYS`, puisqu'il gère le chrono et les transitions.

### 3.3 Écrans (dans `scenes/ui/`, instanciés **une fois** dans `main.tscn` sous `UI`)
| Scène | Contenu | Détails |
|-------|---------|---------|
| `title_screen.tscn` | Fond semi-transparent, titre **RATOIR**, « Touchez pour commencer » qui pulse | Au **premier** `InputEventScreenTouch` pressé → jouer le son « pop » → se cacher → lancer le compte à rebours |
| `countdown.tscn` | Gros chiffres 3 → 2 → 1 → « Cuisinez ! » | ≈ 0,8 s par étape avec un `Tween` (grossit puis disparaît). À la fin, `GameState.start_round()`. **Plus tard (Phase 6)** : afficher ici le nom et la réplique du rat |
| `result_screen.tscn` | « Temps écoulé ! », score, 3 étoiles, texte du récap', bouton **Rejouer** | Étoiles qui s'allument une par une (tween d'échelle + son). Rejouer : `GameState.reset()` puis `get_tree().reload_current_scene()` |

⚠️ **Le caractère ★ n'existe pas dans la police par défaut de Godot** (il s'affiche en carré vide). Au choix :
- dessiner l'étoile par code (`draw_colored_polygon` avec 10 points alternant rayon grand/petit) dans un petit `Control` `star_icon.gd` ;
- utiliser une image d'étoile (les packs Kenney en ont, en CC0) ;
- importer une police qui contient ★ (à vérifier dans la police).

### 3.4 Le HUD
- Ajouter le **chrono** au HUD existant (`scripts/hud.gd`) : `SCORE 7 · 0:42`, ou deux labels séparés. Il écoute `GameState.time_changed`.
- Optionnel (bonus) : une petite jauge qui montre la prochaine étoile (« ★ dans 2 plats »).

### 3.5 Relancer proprement
`GameState` est un **autoload** : il **survit** à `reload_current_scene()`. Il faut donc **appeler `GameState.reset()` avant de recharger**, sinon le score et le journal de la partie précédente restent. Le rat (Phase 3) et le commentateur (Phase 5) doivent aussi repartir de zéro : ils écoutent `round_started`.

### 3.6 Déverrouillage audio (Web mobile)
Les navigateurs mobiles refusent de jouer du son avant une interaction de l'utilisateur. Jouer un son **dans le traitement même** du premier contact (écran titre) débloque l'audio pour le reste de la session. **Aucune voix ne doit être lancée avant ce contact.** Le commentateur (Phase 5) doit donc attendre `round_started`.

## 4. Équilibrage

Objectif, mesuré avec des joueurs qui découvrent le jeu :
| Résultat | Joueur débutant | Joueur qui connaît le jeu |
|----------|-----------------|---------------------------|
| ★ | presque toujours | toujours |
| ★★ | parfois | souvent |
| ★★★ | jamais | seulement s'il gère bien le rat |

**Aujourd'hui** : ≈ 13 s par plat sans rat → 6 à 7 plats en 90 s → ★★★ impossible.

Leviers, du plus simple au plus lourd :
| Levier | Où | Valeur actuelle |
|--------|----|-----------------|
| Durée de manche | `GameState.round_duration` | — (à créer), 60 à 90 s prévu |
| Temps de découpe | `ChopStation.duration` (inspecteur) | 1,5 s |
| Temps de cuisson | `CookStation.duration` | 2,5 s |
| Vitesse du joueur | `Player.speed` | 6 m/s |
| Distances | positions des meubles dans `main.tscn` | cuisine 12 × 22 m |
| Paliers | `GameState.STAR_THRESHOLDS` | 5 / 10 / 15 |
| Fréquence et vitesse du rat | `data/rat_profiles/default.tres` (Phase 3) | — |

Méthode :
1. Ajouter un affichage de debug (ou lire le journal) : **temps moyen entre deux `dish_delivered`**.
2. Faire jouer **au moins 3 personnes × 3 manches**, et noter score et étoiles.
3. Changer **un seul levier à la fois**.
4. **Décider en équipe** si on garde 5/10/15 (le concept l'impose, alors on adapte le reste) : pour ★★★ à 15 plats en 90 s, il faut ≈ 6 s par plat **avec** le rat. Il faudra probablement rapprocher les meubles, raccourcir les transformations, **et** rendre la station de travail active pendant la marche (déjà le cas).
5. Reporter les valeurs finales dans [CONCEPT.md §7](../CONCEPT.md#7-la-manche-le-score-et-les-étoiles).

## 5. Découpage en tâches

1. [ ] `GameState` : `RoundState`, chrono, signaux, `start_round()`, `reset()`, événements.
2. [ ] Pause de l'arbre + `process_mode` des écrans.
3. [ ] `title_screen.tscn` + son « pop » (déverrouillage audio).
4. [ ] `countdown.tscn`.
5. [ ] Chrono dans le HUD.
6. [ ] `result_screen.tscn` + étoiles + Rejouer (`reset` puis `reload`).
7. [ ] Texte de récap' de secours : « Tu as servi 8 plats ! » (sera remplacé en Phase 6).
8. [ ] Équilibrage (§4) avec la personne de la Phase 3.
9. [ ] Documentation : ARCHITECTURE (API de `GameState`), CONCEPT (valeurs), cases de cette fiche.

## 6. Tests à faire
| Scénario | Attendu |
|----------|---------|
| Ouvrir le jeu sur téléphone | Écran titre, rien ne bouge ; le joystick ne fait rien |
| Toucher l'écran | « Pop » audible, puis compte à rebours |
| Jouer jusqu'à 0 | Tout se fige, puis écran de fin avec les bonnes étoiles |
| Score 4, 5, 10, 15 (tricher en appelant `add_point()` pour tester) | 0, 1, 2, 3 étoiles |
| Rejouer 3 fois de suite | Chaque manche repart de zéro (score, journal, objets, rat) |
| Mettre le navigateur en arrière-plan pendant la manche | Au retour, le jeu reprend sans chrono négatif ni double fin |
| Atteindre 5 puis 10 plats | Le niveau et l'objectif montent, le chrono baisse, une vie est rendue sans dépasser 3 |
| Laisser le chrono expirer | Une vie est perdue, le score reste acquis, le même niveau redémarre |
| Recevoir un dégât direct du rat | Une vie est perdue ; à 0, le jeu se met en pause |

## 7. Pièges connus
- **Autoload qui survit au rechargement** : voir §3.5.
- **`process_mode`** : un bouton Rejouer dans une scène en pause ne réagit pas s'il n'est pas en `ALWAYS`.
- **Joystick actif sur l'écran titre** : le désactiver hors `PLAYING` (le mettre en `INHERIT` suffit avec la pause) et le **remettre à zéro** en fin de manche (sinon le joueur continue d'avancer au retour).
- **Police sans ★** : voir §3.3.

## 8. Hors périmètre
- Récap' généré par IA → Phase 6 (cette phase prévoit la zone de texte et un texte de secours).
- Nom et réplique du rat pendant le compte à rebours → Phase 6.
- Habillage graphique définitif des écrans → Phase 7.

## 9. Intégration après merge de la Phase 3

- `staging` intégré à `phase-4/level-progression`.
- Difficulté du rat connectée aux niveaux : vitesse × multiplicateur, délai de sortie ÷ multiplicateur, plafond 2×. Le profil partagé reste inchangé.
- Un renversement au contact retire une vie une seule fois ; les autres sabotages ne retirent pas de vie.
- Chaque début de manche cache le rat, rétablit 5 s de protection et rend son éventuel objet volé récupérable au sol.
- À zéro vie, la pause fige le gameplay ; le HUD affiche la fin et le joystick est relâché.
- Test automatisé : `godot --headless --path . res://tests/phase4_integration.tscn` (progression, dégâts, expiration, pause, reset et plafonds).

Restent à réaliser : titre/déverrouillage audio, compte à rebours, alerte visuelle du chrono, écran de résultat/rejouer, équilibrage avec joueurs et validation sur téléphone. Le reset de progression est testé ; le parcours complet Rejouer avec rechargement de cuisine reste à implémenter.
