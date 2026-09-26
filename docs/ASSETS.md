# Assets 3D (et sons) : trouver, générer, intégrer

Aujourd'hui, tout le jeu est fait de **primitives** (capsule bleue pour le chef, cubes pour les meubles, sphères pour les tomates). C'est volontaire : on valide le gameplay d'abord. Ce guide explique **comment les remplacer par de vrais modèles 3D** sans casser le jeu.

> **Règle d'or : un seul style visuel.** Un chef en style *Kenney* à côté d'un rat photoréaliste, c'est pire que des capsules. Choisis **une** famille d'assets principale et complète seulement ce qui manque.

---

## Sommaire
1. [Liste des assets nécessaires](#1-liste-des-assets-nécessaires)
2. [Contraintes techniques (à lire avant de télécharger quoi que ce soit)](#2-contraintes-techniques)
3. [Option A : packs gratuits (recommandé)](#3-option-a--packs-gratuits-recommandé)
4. [Option B : générer avec l'IA (image → 3D)](#4-option-b--générer-avec-lia-image--3d)
5. [Option C : modéliser soi-même dans Blender](#5-option-c--modéliser-soi-même-dans-blender)
6. [Animer les personnages](#6-animer-les-personnages)
7. [Intégrer un modèle dans Godot, pas à pas](#7-intégrer-un-modèle-dans-godot-pas-à-pas)
8. [Sons et musique](#8-sons-et-musique)
9. [Licences et crédits](#9-licences-et-crédits)
10. [Checklist finale](#10-checklist-finale)
11. [Catalogue de prompts (images à générer)](#11-catalogue-de-prompts-images-à-générer)

---

## 1. Liste des assets nécessaires

Par ordre de priorité. **P1** = indispensable pour la démo, **P2** = gros plus, **P3** = si on a le temps.

| Prio | Asset | Remplace | Animations | Notes |
|:----:|-------|----------|-----------|-------|
| P1 | **Chef** (personnage) | capsule bleue `Player/Model` | `idle`, `walk` (+ `hit` en P2) | Tenue ou toque **bleue** pour garder le code couleur |
| P1 | **Rat** | *(à créer en Phase 3)* | `idle`, `run` (+ `stunned` en P2) | Gris foncé, **queue rose**, gros yeux : il doit être lisible de loin |
| P1 | **Tomate** crue / tranches / assiette | sphère, cylindres, assiette de `item.gd` | — | 3 petits modèles, ou 1 tomate + 1 assiette |
| P1 | **Plan de travail** (meuble de base) | cubes `Counter` | — | Réutilisé par toutes les stations |
| P1 | **Planche à découper** | `Board` | — | Posée sur un plan de travail |
| P1 | **Plaque de cuisson / cuisinière** | `Burner` | — | Idéalement une version « allumée » (rouge) et « éteinte » (grise) |
| P1 | **Caisse de tomates** | caisse orange | — | |
| P1 | **Comptoir de livraison / passe-plat** | comptoir gris-bleu | — | Peut avoir une petite cloche |
| P2 | **Poêle** (l'arme pour taper le rat) | — | — | Tenue par le chef pendant `hit` |
| P2 | **Trou du rat** dans le mur | disque noir | — | Arche en bois ou en pierre |
| P2 | **Murs et sol** | carrelage généré par shader | — | Textures carrelage/briques, ou modèles de murs modulaires |
| P3 | Décor (étagères, casseroles, plantes…) | — | — | **Contre les murs uniquement**, pour ne pas gêner le passage |
| P3 | Effets : fumée, flaque, étoiles « assommé » | — | — | Particules Godot (`GPUParticles3D`/`CPUParticles3D`), pas des modèles |

## 2. Contraintes techniques

Le jeu tourne **dans le navigateur d'un téléphone**. Chaque mégaoctet et chaque triangle compte.

| Contrainte | Valeur | Pourquoi |
|------------|--------|----------|
| **Format** | **glTF 2.0 binaire (`.glb`)** | Format natif de Godot : matériaux et animations sont importés tels quels |
| **Échelle** | 1 unité = **1 mètre**. Chef ≈ 1,4 m, rat ≈ 0,5 m (exagéré pour la lisibilité), plan de travail ≈ 1 m de haut et 1,4 × 1,4 m au sol | Les collisions et les zones de contact du code sont réglées sur ces tailles |
| **Origine (pivot)** | **Aux pieds**, au centre, à `y = 0` | Sinon le modèle flotte ou s'enfonce dans le sol |
| **Orientation** | Le personnage **regarde vers +Z dans Godot**. Dans Blender, ça correspond à regarder vers **−Y** (vue de face, <kbd>Pavé num. 1</kbd>) | Le code fait tourner `Model` en supposant que l'avant est +Z |
| **Triangles** | Personnage ≤ **8 000**, meuble ≤ **3 000** (5 000 au maximum), aliment ou petit objet ≤ **1 500**, total de la scène ≤ **80 000** | Téléphones d'entrée de gamme + WebGL |
| **Textures** | **1024 × 1024 maximum** (512 suffit souvent). Idéalement **une texture « palette »** partagée par tous les modèles (style Kenney/KayKit) | Poids du téléchargement et mémoire vidéo |
| **Poids total des assets** | Objectif **< 15 Mo** | L'export Web pèse déjà ≈ 10 Mo compressé ; au-delà de 30 Mo, le chargement sur 4G devient pénible |
| **Squelette (rig)** | Un seul squelette par personnage, **≤ 4 influences par sommet** | Limite de WebGL |

⚠️ **Compression des textures pour mobile.** Le réglage *Projet → Paramètres du projet → Rendu → Textures → VRAM Compression → **Import ETC2 ASTC*** est **déjà activé** dans ce projet. Ne pas le désactiver : sans lui, les textures compressées peuvent mal s'afficher sur téléphone. Vérifier quand même chaque nouveau modèle **sur un vrai téléphone**.

## 3. Option A : packs gratuits (recommandé)

C'est le plus rapide, le plus sûr côté licence, et le style est cohérent. Pour un hackathon, **c'est l'option par défaut**.

### Sources conseillées

| Source | Licence habituelle | Ce qu'on y trouve pour Tomato Wars |
|--------|--------------------|-------------------------------|
| **KayKit** (Kay Lousberg), `kaylousberg.itch.io` | CC0 (domaine public) | Packs low-poly très cohérents, dont un pack de **cuisine/restaurant** (meubles, ustensiles, nourriture) et des **personnages animés**. **Premier choix pour le style.** |
| **Kenney**, `kenney.nl/assets` | CC0 | *Food Kit* (plein d'aliments dont tomates et assiettes), *Furniture Kit*, personnages simples, **packs de sons** |
| **Quaternius**, `quaternius.com` | CC0 | Personnages et **animaux animés** low-poly (chercher un rat ou une souris ; sinon un animal proche à recolorer) |
| **Poly Pizza**, `poly.pizza` | CC0 ou CC-BY selon le modèle | Moteur de recherche de modèles low-poly : chercher « rat », « mouse », « chef », « stove », « tomato » |
| **Sketchfab**, `sketchfab.com` | Variable | Filtrer *Downloadable* + licence **CC0 ou CC-BY** ; télécharger au format **glTF**. Attention au nombre de triangles |

> Vérifie la licence **sur la page de chaque pack** au moment du téléchargement (elles peuvent changer) et note-la dans `CREDITS.md` (voir §9).

### Méthode conseillée (≈ 1 h)
1. Parcourir **KayKit** et **Kenney** et choisir **la** famille principale (celle qui a le plus de ce qu'il nous faut).
2. Télécharger les packs, puis copier **uniquement** les `.glb` utiles dans `assets/models/…` (voir §7). Ne pas committer tout un pack de 200 Mo.
3. Pour ce qui manque (souvent le rat) : chercher dans la même gamme de couleurs sur Quaternius ou Poly Pizza. En dernier recours, le générer (option B) **avec une image de référence dans le même style**.
4. Recolorer si besoin : dans Godot, `material_override` ou modification du matériau importé. Le chef doit rester **bleu**.

## 4. Option B : générer avec l'IA (image → 3D)

Utile pour **le rat** ou un objet introuvable. Les outils du moment (Meshy, Tripo, Rodin/Hyper3D, Higgsfield 3D, etc.) transforment **une image** ou **un texte** en modèle 3D texturé exporté en `.glb`.

### Étape 1 : créer une bonne image de référence
L'image fait **80 % de la qualité**. Tous les prompts prêts à l'emploi sont dans le [catalogue (§11)](#11-catalogue-de-prompts-images-à-générer). Les règles :
- **un seul objet par image**, **entier** (rien de coupé) et centré, carré 1024 × 1024 ;
- **fond uni gris clair (#E0E0E0)**. Pas de blanc pur : la toque et la veste du chef, l'assiette et les plans de travail sont blancs, et l'outil ne saurait plus où s'arrête l'objet ;
- personnages **de face**, en **pose A** (bras un peu écartés, jambes séparées) pour pouvoir les animer ;
- **même style partout** : générer d'abord l'image de style (prompt 0 du catalogue) et la donner **en image de référence** pour toutes les autres, si le générateur le permet.

**Test de cohérence** : générer le chef puis la cuisinière avec la même référence. S'ils semblent sortir du même jeu, on peut produire le reste.

### Étape 2 : image → 3D
Réglages conseillés (noms des options de **Meshy** ; on trouve l'équivalent chez Tripo ou Hunyuan3D) :

| Asset | Mode | Triangles visés | Options |
|-------|------|----------------:|---------|
| Meubles, trou du rat | *Image to 3D*, **Low poly**, texturé | 3 000 à 5 000 | Sans PBR |
| Aliments, poêle | *Image to 3D*, **Low poly**, texturé | ≈ 1 500 | Sans PBR |
| **Chef** | *Image to 3D* (ou *Multi-image* avec face, profil et dos), texturé | 5 000 à 8 000 | **Pose A**, **Rigging** activé, animations **Idle** et **Walk** (voir §6) |
| **Rat** | *Image to 3D*, **Low poly**, texturé | ≈ 5 000 | **Sans rigging** : le squelette automatique ne marche bien que sur les humanoïdes. Il sera animé par code (§6) |

- Télécharger en **`.glb`**, nommé en minuscules (`chef.glb`, `stove.glb`, `rat.glb`…).
- Le déposer dans `assets/models/<catégorie>/` (voir §7).
- **Commencer par un seul modèle**, l'intégrer et le vérifier dans le jeu avant de produire le reste.

### Étape 3 : nettoyer dans Blender (obligatoire)
Les modèles générés par IA sont souvent **trop lourds** (50 000 à 500 000 triangles), **mal orientés** et **mal centrés**.
1. *Fichier → Importer → glTF 2.0*.
2. **Réduire les triangles** : sélectionner le mesh → modificateur **Decimate** → *Collapse*, baisser le ratio jusqu'à ≈ 5 000 triangles pour un personnage (le compteur est dans la barre d'état : clic droit → *Statistiques de scène*). Appliquer.
3. **Échelle** : mettre le chef à ≈ 1,4 m de haut (touche <kbd>N</kbd> → *Dimensions*).
4. **Orientation** : le personnage doit regarder vers **−Y** (vue de face, <kbd>Pavé num. 1</kbd>).
5. **Origine aux pieds** : placer le curseur 3D à (0, 0, 0), poser les pieds du modèle dessus, puis *Objet → Définir l'origine → Origine sur le curseur 3D*.
6. **Appliquer les transformations** : <kbd>Ctrl</kbd>+<kbd>A</kbd> → *Toutes les transformations*.
7. **Texture** : si elle fait 2048 ou plus, la réduire à 1024 (dans l'éditeur d'image : *Image → Redimensionner*).
8. *Fichier → Exporter → glTF 2.0*, format **glTF Binary (.glb)**, cocher *Appliquer les modificateurs*.

### Pièges connus
- Les **mains, les pattes et la queue** sortent souvent fusionnées au corps : c'est gênant pour l'animation. Sur une image de référence, bien séparer les membres.
- La **face arrière** est inventée par l'outil et souvent ratée. Vue en plongée, on ne la voit presque pas, donc c'est acceptable.
- **Licences** : les offres gratuites de certains outils imposent une attribution ou interdisent l'usage commercial. Vérifier les conditions de l'outil et les noter dans `CREDITS.md`.

## 5. Option C : modéliser soi-même dans Blender

À réserver aux **objets simples** (planche, plaque, caisse, trou du rat) si quelqu'un est à l'aise avec Blender. Un meuble low-poly prend 10 à 20 minutes : un cube, quelques *extrude*/*bevel*, et une couleur unie par matériau (pas besoin de texture). **Ne pas tenter de modéliser et rigger un personnage pendant le hackathon.**

## 6. Animer les personnages

### Le chef (humanoïde) → **Mixamo** (gratuit, compte Adobe)
1. Exporter le chef de Blender en **FBX** (ou OBJ), en pose T.
2. Sur `mixamo.com` : *Upload Character* → placer les repères (menton, poignets, coudes, genoux, aine) → rig automatique.
3. Choisir les animations : **Idle**, **Walking** (cocher **In Place**, sinon le personnage avance tout seul), éventuellement une animation de frappe pour `hit`.
4. Télécharger chacune en **FBX, *With Skin***, à 30 fps.
5. Dans Blender : importer les FBX, renommer les *actions* `idle`, `walk` et `hit`, les regrouper sur un seul squelette (via le *NLA Editor* ou l'*Action Editor*), puis exporter en `.glb` avec les animations.

### Le chef avec **Meshy** (c'est ce qui a été fait)
Le squelette automatique de Meshy (*Rigging*, type humanoïde) produit un squelette au format Mixamo : **pas besoin de passer par Mixamo**. Meshy exporte **un `.glb` par animation**, chacun contenant le modèle complet et des textures 2048 (≈ 6 Mo par fichier). On les fusionne et on les allège avec `tools/optimize_glb.py` (section suivante).

### Préparer un modèle sans Blender : `tools/optimize_glb.py`
```bash
# Personnage : fusionne les animations, les renomme, réduit les textures à 1024
python3 tools/optimize_glb.py Walking_withSkin.glb -o assets/models/characters/chef.glb \
    --anim-from Running_withSkin.glb --rename Walking=walk --rename Running=run

# Objet : textures 512 suffisent
python3 tools/optimize_glb.py stove_meshy.glb -o assets/models/kitchen/stove.glb --texture-size 512
```
Ce que fait le script :
- **textures** réduites (1024 par défaut) ; les cartes de reflets métalliques, de relief et d'occlusion sont retirées, ainsi que les tangentes (inutiles pour notre rendu mobile ; `--keep-pbr` pour les garder) ;
- **animations** d'autres fichiers ajoutées, à condition qu'ils aient le **même squelette** (les os sont associés par nom) ;
- doublons `.001` supprimés (poses figées d'une seule image qu'exporte Meshy).

Résultat pour le chef : 2 fichiers de 6 Mo deviennent **un seul fichier de 0,6 Mo**. Le script **ne réduit pas le nombre de triangles** : régler ça à la génération (*Target polycount*) ou avec *Remesh* dans Meshy.

**Échelle bizarre à l'import ?** Certains exports Meshy (squelettes non humanoïdes, format « Unreal ») arrivent **100 fois trop petits** (le rat mesurait 5 mm). Ce n'est pas grave : corriger l'échelle du nœud du modèle dans sa scène (`rat_model.tscn` : × 340).

Noms d'animations attendus par `player.gd` : **`idle`**, **`walk`**, **`run`**. S'il manque `idle`, le chef se fige sur la première image de `walk`.

### Le rat (quadrupède) → **animation procédurale** (recommandé)
Mixamo ne gère pas les quadrupèdes. Pour un rat qui se déplace vite et vu de haut, une animation **par code** suffit amplement et ne coûte presque rien :
```gdscript
# Dans rat.gd, _process : petit rebond de course + queue qui ondule.
var t := Time.get_ticks_msec() / 1000.0
var speed_ratio := velocity.length() / speed
$Model.position.y = abs(sin(t * 18.0)) * 0.06 * speed_ratio   # trottine
$Model/Tail.rotation.y = sin(t * 10.0) * 0.5                  # queue qui remue
$Model.scale = Vector3.ONE * (1.0 + sin(t * 18.0) * 0.04 * speed_ratio)  # écrasement léger
```
Pour que ça marche, il faut que la **queue soit un objet séparé** (`Tail`) dans le modèle. Si on trouve un rat **déjà animé** (Quaternius, Poly Pizza), on utilise ses animations.

### Lancer les animations dans Godot
Le `.glb` importé contient un `AnimationPlayer`. Dans `player.gd` :
```gdscript
@onready var _anim: AnimationPlayer = $Model/Chef/AnimationPlayer   # adapter le chemin

func _update_animation() -> void:
	var moving := Vector2(velocity.x, velocity.z).length() > 0.2
	var wanted := "walk" if moving else "idle"
	if _anim.current_animation != wanted:
		_anim.play(wanted, 0.15)   # 0.15 s de fondu entre les deux
```
Penser à mettre les animations en **boucle** : double-clic sur le `.glb` → onglet *Animation* → *Loop Mode : Linear*.

## 7. Intégrer un modèle dans Godot, pas à pas

### Arborescence
```
assets/
├── models/
│   ├── characters/   chef.glb, rat.glb
│   ├── kitchen/      counter.glb, stove.glb, cutting_board.glb, crate.glb, pass.glb, rat_hole.glb
│   └── food/         tomato.glb, tomato_sliced.glb, plate_dish.glb
├── textures/         floor_tiles.png, wall_bricks.png, sauce_splash.png
├── ui/               commentator.png, judge.png, star.png, hit_button.png, logo.png
└── audio/
    ├── sfx/          chop.ogg, sizzle.ogg, ding.ogg, squeak.ogg, bonk.ogg …
    ├── music/        theme.ogg
    └── voice/        (répliques pré-générées du commentateur, Phase 5)
```
Noms de fichiers en **minuscules_avec_underscores**, sans accents ni espaces.

Les **images sources** générées par IA (avant conversion 3D) vont dans `art/concepts/`, hors de `assets/`. Ce dossier contient un `.gdignore` pour que Godot ne les importe pas dans le jeu.

### Remplacer la capsule du chef
1. Copier `chef.glb` dans `assets/models/characters/`. Godot l'importe tout seul.
2. Ouvrir `scenes/player.tscn`.
3. Sous `Model`, **supprimer** `Body` et `Face`.
4. **Glisser `chef.glb`** depuis le panneau *Système de fichiers* sur le nœud `Model`.
5. Vérifier dans la vue 3D : pieds sur la grille (`y = 0`), le chef regarde vers la flèche bleue **+Z**, taille ≈ 1,4 m. Si besoin, corriger la position, la rotation ou l'échelle **du nœud du chef** (jamais de `Model` lui-même, que le script fait tourner).
6. **Garder `Model/HoldPoint`** : c'est là que l'objet tenu s'affiche. Le déplacer devant les mains du chef.
7. **Ne pas toucher à `CollisionShape3D`** sauf si le modèle est beaucoup plus gros ou plus petit que la capsule (rayon 0,4 m, hauteur 1,4 m).
8. <kbd>F5</kbd> : vérifier qu'il marche, tourne et porte la tomate correctement.

### Remplacer un meuble (ex. la plaque de cuisson)
Aujourd'hui, `Counter` est un `CSGBox3D` qui sert **à la fois** de visuel et de collision (`use_collision = true`). Pour mettre un modèle :
1. Ouvrir `scenes/cook_station.tscn`.
2. Garder la collision : sélectionner `Counter` et **décocher** *Visible* (la collision fonctionne toujours).
3. Supprimer `Burner`, puis glisser `stove.glb` comme enfant de la racine `CookStation`. Le placer pour qu'il occupe le même volume que `Counter` (1,4 × 1 × 1,4 m).
4. Déplacer `ItemSlot` (où l'aliment se pose) **pile sur le brûleur** du modèle.
5. **Ne pas toucher** à `Area3D`, `Rug`, `Progress` et `Label3D`, dont dépend la logique.

### Remplacer la tomate et l'assiette
`scripts/item.gd` construit aujourd'hui le visuel par code (`_rebuild()`). Pour utiliser des modèles :
```gdscript
const MODELS := {
	State.RAW: preload("res://assets/models/food/tomato.glb"),
	State.CHOPPED: preload("res://assets/models/food/tomato_sliced.glb"),
	State.COOKED: preload("res://assets/models/food/plate_dish.glb"),
}

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	add_child(MODELS[state].instantiate())
```
Les modèles d'aliments doivent avoir leur **origine en bas** et mesurer ≈ **0,3 à 0,6 m** de large (on exagère un peu la taille pour la lisibilité).

### Réglages d'import utiles (double-clic sur le `.glb`)
- *Meshes → Generate LODs* : **désactiver** (inutile avec une caméra fixe et ça alourdit).
- *Meshes → Light Baking* : `Disabled`.
- *Animation → Loop Mode* : `Linear` pour `idle`, `walk` et `run`.
- Cliquer *Réimporter* après chaque changement.

## 8. Sons et musique

| Besoin | Où chercher | Format |
|--------|-------------|--------|
| Bruitages (découpe, grésillement, « ding », couinement, « bonk », pas) | **Kenney** (packs audio CC0), **freesound.org** (vérifier la licence de chaque son), **jsfxr** (générateur de bruitages rétro, libre de droits) | **`.ogg`** (Ogg Vorbis), mono, 44,1 kHz |
| Musique (boucle entraînante, 1 à 2 min) | Pistes CC0/CC-BY sur itch.io (tag *music*), OpenGameArt, ou générée par une IA musicale **en vérifiant ses conditions** | `.ogg`, stéréo, ≤ 2 Mo, boucle propre |
| Voix du commentateur | Gradium TTS (Phase 5) ; les répliques de la banque peuvent être **pré-générées en fichiers** dans `assets/audio/voice/` | `.ogg` ou `.mp3` |

Rappel : sur mobile, **aucun son ne joue avant le premier contact de l'utilisateur** avec l'écran. L'écran « Touchez pour commencer » (Phase 4) règle ce problème.

## 9. Licences et crédits

Chaque asset externe doit avoir une ligne dans **`CREDITS.md`** à la racine du dépôt (un modèle est déjà présent). Pour CC-BY, c'est **obligatoire** (attribution) ; pour CC0, c'est de la politesse et ça aide le jury.

## 10. Checklist finale

Pour **chaque** modèle intégré :
- [ ] `.glb`, dans le bon dossier `assets/models/…`, nom en minuscules
- [ ] Taille réaliste (chef ≈ 1,4 m, meuble ≈ 1 m de haut)
- [ ] Origine aux pieds / en bas, regarde vers +Z
- [ ] Nombre de triangles dans le budget, texture ≤ 1024
- [ ] Même style que le reste
- [ ] Ligne ajoutée dans `CREDITS.md`
- [ ] Testé avec <kbd>F5</kbd> **et** sur un vrai téléphone après export (le poids du build reste raisonnable)

## 10 bis. Icônes du HUD (remplacement automatique)

Le HUD utilise ces fichiers (✅ fournis : toque, chrono, étoile). S'il en manque un, il dessine une icône de secours en code. Pour en changer, il suffit de remplacer le fichier (PNG carrés à fond transparent, 256 ou 512 px) pour qu'ils les remplacent, sans toucher au code (`scripts/ui/hud_icon.gd`) :

| Fichier | Icône |
|---------|-------|
| `assets/ui/icons/timer.png` | Chrono |
| `assets/ui/icons/star.png` | Étoile (objectif du niveau) |
| `assets/ui/icons/chef_hat.png` | Toque (niveau) |

## 11. Catalogue de prompts (images à générer)

Prompts en **anglais** : les générateurs d'images les comprennent mieux. Les images servent ensuite à la conversion image → 3D (§4), sauf celles de la partie 2D (§11.6), qui sont utilisées telles quelles dans le jeu.

**Ordre de production conseillé** : style (0) → chef → cuisinière → rat → autres meubles → aliments → images 2D. Le rat est attendu par la Phase 3 ; les images 2D ne bloquent personne.

### 11.1 Blocs à réutiliser

**Bloc de style commun**, à coller **à la fin de chaque prompt 3D** (là où le prompt indique `[STYLE]`) :
```
stylized 3D game asset, cozy cartoon cooking game style like Overcooked, chunky rounded shapes,
simple low-poly geometry, soft flat colors with subtle gradients, bold readable silhouette,
soft studio lighting, centered, entire object visible, isolated on plain solid light grey
background (#E0E0E0), no ground shadow, no text, no watermark, no border
```

**Prompt négatif**, si le générateur en accepte un :
```
realistic, photo, gritty, dark, noisy textures, cluttered, multiple objects, cropped,
cut off, text, logo, watermark, heavy shadows, perspective distortion, blurry
```

### 11.2 Image de style (à faire en premier)
Elle n'est pas convertie en 3D : elle sert de **référence de style** pour toutes les autres images, et d'image d'ambiance pour l'équipe et le jury.
```
cozy cartoon restaurant kitchen seen from above at a 55 degree angle, chunky rounded
furniture against the walls, checkered cream and beige tile floor, warm terracotta walls,
a small blue-dressed chef in the middle, a small dark grey rat peeking from a mouse hole
in the back wall, bright cheerful colors, stylized low-poly 3D game art like Overcooked,
clean readable shapes, soft lighting, vertical 9:16 composition
```

### 11.3 Personnages

| Fichier cible | Prompt |
|---------------|--------|
| `characters/chef.glb` | voir ci-dessous (le chef doit rester **bleu**, c'est la couleur du joueur) |
| `characters/rat.glb` | voir ci-dessous (**gris foncé et queue rose**, lisible de loin) |

**Chef :**
```
cute chubby cartoon chef character, chibi proportions with big head and small body,
blue chef jacket with white buttons, tall white chef hat, white apron, small black shoes,
friendly determined face with big eyes, holding nothing, full body, front view,
symmetrical A-pose with arms slightly away from the body and legs apart, [STYLE]
```
Pour la conversion *multi-vues*, générer aussi la même image avec `side view` puis `back view` à la place de `front view`, **avec l'image de face en référence**.

**Rat :**
```
cute mischievous cartoon rat character, chunky rounded body standing on four legs,
dark grey fur, light grey belly, big round pink ears, big shiny black eyes, sly grin
showing two front teeth, long pink tail held up and clearly separated from the body,
full body, three-quarter front view, [STYLE]
```
La queue doit être **bien détachée du corps** : elle sera animée séparément (§6).

**Rat assommé** (optionnel ; sert de référence visuelle pour l'effet, pas converti en 3D) :
```
same cartoon rat as reference, dizzy and knocked out, swirly eyes, small bump on head,
little yellow stars circling above the head, sitting, [STYLE]
```

### 11.4 Meubles
Dans le jeu, ils mesurent **1,4 × 1,4 m au sol et ≈ 1 m de haut**. On les demande **carrés et compacts**, sinon ils ne rentrent pas à leur place.

| Fichier cible | Prompt |
|---------------|--------|
| `kitchen/counter.glb` (plan de travail de base) | `square compact kitchen counter block, cube-shaped, white top with rounded edges, light wood front panel with a small drawer handle, three-quarter front view from slightly above, [STYLE]` |
| `kitchen/cutting_board.glb` (Découpe) | `square compact kitchen counter with a wooden cutting board on top and a big cartoon kitchen knife lying on the board, cube-shaped counter, white top, light wood front, three-quarter front view from slightly above, [STYLE]` |
| `kitchen/stove.glb` (Cuisson) | `square compact cartoon cooking stove, cube-shaped, dark charcoal grey body with one big round black burner plate on top, chunky control knob on the front, three-quarter front view from slightly above, [STYLE]` |
| `kitchen/crate.glb` (Tomates) | `square compact wooden crate full of big shiny red tomatoes, cube-shaped, cartoon style, three-quarter front view from slightly above, [STYLE]` |
| `kitchen/pass.glb` (Livraison) | `square compact restaurant serving counter, cube-shaped, brushed steel body, bright green stripe on the top edge, small silver service bell on top, three-quarter front view from slightly above, [STYLE]` |
| `kitchen/rat_hole.glb` (trou du rat) | `cartoon mouse hole in a wall, arched opening with a wooden frame, dark inside, small crumbs in front, front view, [STYLE]` |

Pour la plaque « éteinte » (sabotage de la Phase 3), **pas besoin d'un deuxième modèle** : le jeu changera la couleur du brûleur et ajoutera de la fumée.

### 11.5 Aliments et objets
Volontairement **grossis** dans le jeu pour rester lisibles sur un petit écran.

| Fichier cible | Prompt |
|---------------|--------|
| `food/tomato.glb` (crue) | `one big shiny cartoon red tomato with a green stem and leaves, [STYLE]` |
| `food/tomato_sliced.glb` (découpée) | `three thick cartoon tomato slices lying side by side, juicy red with visible seeds, [STYLE]` |
| `food/plate_dish.glb` (cuite) | `round white plate with a cooked tomato dish, glossy red-orange sauce, small green herb leaves on top, cartoon style, three-quarter view from slightly above, [STYLE]` |
| `kitchen/frying_pan.glb` (arme pour taper le rat) | `cartoon black frying pan with a wooden handle, [STYLE]` |

### 11.6 Images 2D (utilisées telles quelles, **fond transparent**)
Pas de conversion 3D : on les utilise dans l'interface ou comme texture. Demander un **PNG à fond transparent** ; si le générateur ne sait pas faire, un fond **vert uni #00FF00** qu'on retirera ensuite. Les ranger dans `assets/ui/` (portraits, icônes, logo) ou `assets/textures/` (sol, mur, effets).

| Fichier cible | Utilisation | Prompt |
|---------------|-------------|--------|
| `ui/commentator.png` | Portrait dans la bulle de sous-titres (Phase 5) | `cartoon portrait of an over-excited sports commentator, bust shot, headset microphone, loud colorful suit, huge smile, shouting with enthusiasm, bold outlines, flat colors, sticker style, transparent background` |
| `ui/judge.png` | Portrait sur la carte du juge (Phase 6) | `cartoon portrait of a snobbish food critic judge, bust shot, thin mustache, monocle, raised eyebrow, holding a small scorecard, bold outlines, flat colors, sticker style, transparent background` |
| `ui/star.png` | Étoiles de l'écran de fin (Phase 4) | `game UI icon, a golden star with a thick dark outline, glossy, cartoon, flat, centered, transparent background` |
| `ui/hit_button.png` | Bouton TAPER (Phase 3) | `game UI round button icon, cartoon frying pan hitting with motion lines, white icon on a bold orange circle, thick outline, flat, centered, transparent background` |
| `ui/logo.png` | Écran titre (Phase 4) | `game logo text "TOMATO WARS", chunky rounded bold cartoon letters, cream and tomato red colors, a small rat tail curling out of the letter W, a chef hat on the first letter O, thick dark outline, transparent background` |
| `textures/floor_tiles.png` | Sol (remplace le shader de damier) | `seamless tileable texture, top-down view, cartoon kitchen floor with cream and beige checkered tiles, flat colors, subtle grout lines, no perspective` |
| `textures/wall_bricks.png` | Murs | `seamless tileable texture, front view, warm terracotta cartoon kitchen wall with subtle brick pattern, flat colors, no perspective` |
| `textures/sauce_splash.png` | Flaque du plat renversé (Phase 3) | `top-down view of a cartoon red tomato sauce splash puddle, flat colors, simple shape, transparent background` |

Les générateurs d'images écrivent souvent mal le texte : pour le logo, vérifier l'orthographe de **TOMATO WARS**, ou générer le logo sans texte et ajouter les lettres dans Godot avec une police.

### 11.7 Avant de passer à la 3D
- [ ] Toutes les images ont le **même style** que l'image de référence.
- [ ] Objet **entier**, **seul**, sur **fond uni**, sans ombre ni texte.
- [ ] Chef en **pose A**, rat avec la **queue détachée**.
- [ ] Couleurs du jeu respectées : chef **bleu**, rat **gris et rose**, bande **verte** sur le comptoir de livraison.
- [ ] Images sources rangées dans `art/concepts/` (utile pour relancer une conversion ou retoucher plus tard).

