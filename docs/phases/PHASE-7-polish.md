# Phase 7 — Polish : modèles 3D, animations, sons, effets

| | |
|---|---|
| **Statut** | ⏳ À faire (**la préparation des assets peut démarrer maintenant**) |
| **Dépend de** | Phase 2 ✅ pour le chef et les meubles ; Phase 3 pour le rat et les effets de sabotage ; Phase 4 pour l'habillage des écrans |
| **Débloque** | Phase 8 (démo) |
| **Profil** | Artiste/intégrateur (Blender est un plus, pas obligatoire) |
| **Estimation** | 2 à 3 h, à répartir tout au long du hackathon |
| **Fichiers possédés** | `assets/**`, `CREDITS.md` ; les scènes des personnages et des meubles **après passage de relais** avec le gameplay |

---

## 1. Objectif

Que le jeu soit **agréable à regarder et à écouter**, pas seulement fonctionnel : vrais modèles 3D, animations, bruitages, musique et effets visuels qui rendent chaque action lisible.

**Guide détaillé des assets : [docs/ASSETS.md](../ASSETS.md)** (où les trouver, comment les générer par IA, les nettoyer dans Blender et les intégrer dans Godot).

## 2. État jouable exigé (critères d'acceptation)

- [ ] Plus **aucune primitive visible** pour les éléments principaux (chef, rat, meubles, tomates, assiette), sauf choix assumé.
- [ ] Le chef a au moins **idle** et **walk** ; le rat **court** (animé ou animation procédurale).
- [ ] **Un seul style** visuel cohérent.
- [ ] Chaque action a un **retour visuel et sonore** (voir §4).
- [ ] Musique en boucle, **baissée automatiquement** quand le commentateur parle.
- [ ] Écrans titre et fin **habillés** (police, couleurs, logo).
- [ ] Build Web **< 30 Mo** et **60 images/s** (ou au moins un rendu fluide) sur un téléphone de milieu de gamme.
- [ ] `CREDITS.md` complet.

## 3. Plan de travail

### Étape 1 — Choisir et préparer (peut commencer **maintenant**, ≈ 45 min)
- [ ] Parcourir KayKit, Kenney, Quaternius et Poly Pizza (voir [ASSETS.md §3](../ASSETS.md#3-option-a--packs-gratuits-recommandé)), puis **choisir la famille de style**. La faire valider en 2 minutes par l'équipe avec une capture.
- [ ] Rassembler la liste P1 de [ASSETS.md §1](../ASSETS.md#1-liste-des-assets-nécessaires) dans `assets/models/…`.
- [ ] Rat introuvable ? Le générer ([ASSETS.md §4](../ASSETS.md#4-option-b--générer-avec-lia-image--3d)), avec la **queue en objet séparé** pour l'animation procédurale.
- [ ] Remplir `CREDITS.md` au fur et à mesure.

### Étape 2 — Intégrer le chef et les meubles (dès maintenant, **en se coordonnant** avec la personne de la Phase 3, qui modifie aussi `player.tscn` et les stations)
- [x] Chef dans `player.tscn` → `Model` ([ASSETS.md §7](../ASSETS.md#7-intégrer-un-modèle-dans-godot-pas-à-pas)), animations **walk** et **run** branchées dans `player.gd`.
- [ ] Animation **idle** du chef (Meshy → *Animate* → Idle, puis `tools/optimize_glb.py --anim-from`). En attendant, pose figée.
- [ ] Meubles : plan de travail, planche, plaque, caisse, passe-plat (garder `Area3D`, `ItemSlot`, `Rug`, `ApproachPoint`).
- [ ] Tomate, tranches et assiette dans `item.gd` (constante `MODELS`).
- [ ] Trou du rat (arche).

### Étape 3 — Intégrer le rat (après la Phase 3)
- [ ] Modèle dans `rat.tscn` → `Model`, avec animation `run` ou procédurale ([ASSETS.md §6](../ASSETS.md#6-animer-les-personnages)).
- [ ] État « assommé » : petites étoiles qui tournent au-dessus de sa tête.

### Étape 4 — Effets et sons (§4)

### Étape 5 — Habillage de l'interface
- [ ] Une **police** ronde et grasse, lisible sur téléphone (ex. une police de Google Fonts sous licence OFL). L'importer et la définir dans un **thème** (`assets/ui/theme.tres`) appliqué à `UI`.
- [ ] Bouton TAPER avec une icône de poêle, écrans titre et fin aux couleurs du jeu, logo « RATOIR ».

## 4. Retours visuels et sonores par action

| Action | Visuel | Son (`assets/audio/sfx/`) | Accroche technique |
|--------|--------|---------------------------|--------------------|
| Prendre une tomate | Petit « pop » d'échelle sur l'objet | `pickup.ogg` | `Cook.hold()` |
| Découpe en cours | Barre de progression (existe) + petits morceaux qui sautent | `chop.ogg` en boucle | `Station` (`accepts` = RAW) |
| Cuisson en cours | Vapeur légère (particules) | `sizzle.ogg` en boucle | `Station` (`accepts` = CHOPPED) |
| Transformation terminée | Éclat (flash) sur l'objet | `ready.ogg` (petit « ding » aigu) | `Station`, au changement d'état |
| Livraison | « +1 » (existe) + confettis | `deliver.ogg` (cloche) | `DeliveryCounter` |
| Le rat sort | Poussière au trou, « ! » au-dessus de la cible | `squeak.ogg` | `event_logged` : `rat_appeared` |
| Plaque éteinte | Brûleur gris + fumée noire | `fizzle.ogg` | `sabotage_stove_off` |
| Plaque rallumée | Petite flamme | `ignite.ogg` | `stove_relit` |
| Vol | L'objet dans la gueule du rat | `steal.ogg` | `sabotage_steal` |
| Plat renversé | Éclaboussure + flaque qui disparaît | `splash.ogg` | `sabotage_spill` |
| Coup sur le rat | Coup de poêle, « BONK ! », **tremblement de caméra**, étoiles | `bonk.ogg` + couinement | `rat_hit` |
| 10 dernières secondes | Chrono rouge qui pulse | `tick.ogg` chaque seconde | `timer_milestone` |
| Étoile gagnée (écran de fin) | Étoile qui grossit et tourne | `star.ogg` (hauteur croissante 1 → 2 → 3) | `result_screen` |

**Conseils :**
- Un autoload `Sfx` (`scripts/sfx.gd`) qui écoute `GameState.event_logged` couvre la moitié du tableau **sans toucher au code du gameplay**. Pour le reste (découpe, prise d'objet…), un appel direct `Sfx.play("chop")`.
- **Tremblement de caméra** : ajouter `shake(intensity, duration)` à `camera_follow.gd` (décalage aléatoire ajouté à la position, qui diminue avec le temps).
- **Vibration** : `Input.vibrate_handheld(40)` sur le coup. Sur le Web, ça marche sur Android (Chrome), pas sur iPhone. C'est un bonus.
- **Particules** : `CPUParticles3D` est le plus sûr pour la compatibilité Web/mobile.
- **Musique** : bus `Music`, `AudioStreamPlayer` avec lecture en boucle ; *ducking* quand le bus `Voice` joue (voir Phase 5).

## 5. Performances (à vérifier après chaque gros ajout)
- Moniteur de Godot (*Débogueur → Moniteurs*) : images/s, *draw calls*, mémoire vidéo.
- Si ça rame sur téléphone, par ordre d'efficacité :
  1. désactiver les **ombres** du soleil (`shadow_enabled = false`), ou réduire leur résolution ;
  2. réduire le nombre de particules ;
  3. décimer les modèles trop lourds ;
  4. fusionner les matériaux (une texture palette pour tout).
- Vérifier le poids du build : `ls -lh build/ratoir-web.zip` (le moteur seul fait ≈ 10 Mo).

## 6. Pièges connus
- **Modèle qui regarde du mauvais côté** : il doit regarder vers +Z. Corriger la rotation du **nœud du modèle**, jamais de `Model` (le script le fait tourner).
- **Conflits dans `player.tscn` et les stations** avec la Phase 3 : se prévenir et passer le relais (voir [CONTRIBUTING §3](../CONTRIBUTING.md#3-qui-possède-quelle-scène)).
- **Textures floues ou noires sur téléphone** : vérifier que *Import ETC2 ASTC* est bien activé (c'est le cas dans ce projet) et réimporter.
- **Sons qui ne jouent pas au premier lancement** : c'est normal avant le premier contact (Phase 4).

## 7. Hors périmètre
- Nouveaux niveaux, nouvelles recettes, personnalisation du chef.
