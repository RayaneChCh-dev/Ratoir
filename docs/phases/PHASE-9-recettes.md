# Phase 9 — Recettes et assemblage d'ingrédients *(plus tard)*

| | |
|---|---|
| **Statut** | 💡 Idée notée, **à ne pas commencer** avant que les phases 3 et 4 soient stables et testées sur téléphone |
| **Dépend de** | Phase 3 (rat), Phase 4 (manche, équilibrage) |
| **Profil** | Dev gameplay + Assets (nouveaux ingrédients) |
| **Estimation** | 3 à 4 h (gameplay 2 h, UI des commandes 1 h, assets à part) |

> Aujourd'hui, il n'y a qu'**un seul plat** : tomate → découpe → cuisson → assiette → livraison. Cette fiche décrit comment passer à de **vraies recettes à plusieurs ingrédients**, sans casser les contrôles (tout au contact, un seul bouton).

---

## 1. Le principe côté joueur

1. En haut de l'écran, **2 ou 3 commandes** s'affichent, sous forme de tickets : une icône par ingrédient et une petite jauge de temps.
2. Le joueur **prépare chaque ingrédient séparément**, comme aujourd'hui : il le prend dans son bac, le **découpe**, et le **cuit** si la recette le demande.
3. Il **pose les ingrédients prêts un par un sur une assiette**, sur un nouveau meuble : le **plan de dressage**. L'assiette affiche ce qu'elle contient.
4. Quand l'assiette correspond à une commande, **le plat apparaît sur l'assiette**. Le joueur la prend et la livre au comptoir.
5. **Livrer une commande en cours** rapporte ses points et fait apparaître une nouvelle commande. Une commande **expirée** disparaît sans point.

### Toujours au contact, un seul bouton
| Le joueur arrive au plan de dressage… | Résultat |
|--------------------------------------|----------|
| avec un **ingrédient prêt** qui entre dans une commande en cours | il est **posé sur l'assiette** |
| avec un ingrédient **pas prêt** (ex. tomate crue alors que la recette la veut découpée) ou **inutile** | **rien ne se passe**. On garde l'objet et une petite icône « ✗ » s'affiche. C'est ce qui évite les erreurs involontaires |
| **les mains vides**, assiette **complète** | il **prend le plat** |
| **les mains vides**, assiette incomplète | rien, pour ne pas la vider par accident |

Le bouton TAPER reste réservé au rat.

## 2. Exemples de recettes (base de départ)

| Recette | Ingrédients (état attendu) | Points | Remarque |
|---------|---------------------------|:------:|----------|
| **Tomates poêlées** | tomate *découpée + cuite* | 1 | = le plat actuel, gardé comme recette facile |
| **Salade** | tomate *découpée* + laitue *découpée* | 2 | Pas de cuisson : rapide |
| **Soupe à l'oignon et tomate** | tomate *découpée + cuite* + oignon *découpé + cuit* | 3 | Deux passages sur la plaque |
| **Burger** | pain + steak *cuit* + tomate *découpée* + laitue *découpée* | 4 | La recette « difficile » |

- Commencer avec **2 ingrédients** (tomate, laitue) et **2 recettes** (tomates poêlées, salade), puis ajouter les autres si tout va bien.
- **Un bac par ingrédient** (même principe que le bac à tomates actuel).
- **Les paliers d'étoiles (5 / 10 / 15)** devront être rééquilibrés : ils comptent alors des **points**, et plus des plats.

## 3. Le rat avec les recettes
Nouvelles occasions de sabotage, sans nouveau système (le même framework que la Phase 3) :
- **voler un ingrédient sur l'assiette** en cours de dressage ;
- **renverser l'assiette** entière (tous les ingrédients sont perdus) : un sabotage fort, à rendre rare ;
- **manger un ingrédient** posé sur la planche.

## 4. Conception technique (pour plus tard)

### Données (ressources Godot `.tres`, modifiables sans coder)
```gdscript
class_name IngredientData extends Resource    # data/ingredients/tomato.tres…
@export var id := "tomato"
@export var display_name := "Tomate"
@export var can_chop := true
@export var can_cook := true
@export var models := {}          # état → PackedScene (cru, découpé, cuit)
@export var icon: Texture2D       # pour les tickets de commande

class_name RecipeData extends Resource        # data/recipes/salad.tres…
@export var display_name := "Salade"
@export var components: Array[Dictionary] = [] # [{ "ingredient": "tomato", "chopped": true, "cooked": false }, …]
@export var points := 2
@export var dish_model: PackedScene           # visuel du plat terminé
```

### Changements dans le code existant
| Élément | Aujourd'hui | Avec les recettes |
|---------|-------------|-------------------|
| `Item` | un état `RAW → CHOPPED → COOKED` sur une tomate | un **ingrédient** (`IngredientData`) + deux booléens `chopped` et `cooked` |
| `Station` Découpe / Cuisson | produit l'état suivant, et la cuisson sort une **assiette** | Découpe : `chopped = true` si `can_chop`. Cuisson : `cooked = true` si `can_cook`. **La cuisson ne produit plus d'assiette** |
| *(nouveau)* `Plate` | — | un objet qui contient une liste d'ingrédients et affiche le plat quand il correspond à une recette |
| *(nouveau)* `AssemblyStation` | — | le plan de dressage (règles du §1), avec une assiette toujours présente |
| *(nouveau)* autoload `Orders` | — | tire les commandes, gère leur temps, dit si une assiette correspond, émet `order_added`, `order_completed`, `order_expired` |
| `DeliveryCounter` | accepte une assiette cuite = 1 point | accepte une `Plate` qui correspond à une **commande en cours** → `GameState.add_points(recipe.points)` |
| `IngredientSpawn` | donne une tomate | réglable : `@export var ingredient: IngredientData` (un bac par ingrédient) |
| HUD | score + chrono | + **tickets de commande** en haut de l'écran |

**Nouveaux événements** (à ajouter à la liste d'[ARCHITECTURE.md](../ARCHITECTURE.md#5-journal-dévénements)) : `order_added`, `order_completed`, `order_expired`, `plate_assembled`, `sabotage_plate_steal`. Le commentateur et le juge (Phases 5 et 6) pourront ainsi parler des recettes (« Un burger complet sous le nez du rat ! »).

**Transition en douceur** : garder « Tomates poêlées » comme première recette permet de migrer sans casser la partie actuelle. La seule différence pour le joueur : il passe par le plan de dressage avant la livraison.

## 5. Assets supplémentaires (Phase 7, le moment venu)
Prompts dans le même style que [ASSETS.md](../ASSETS.md) :
- `food/lettuce.glb` : `one fresh cartoon lettuce head, bright green leaves, [STYLE]`
- `food/lettuce_chopped.glb` : `small pile of chopped cartoon lettuce leaves, [STYLE]`
- `food/onion.glb` / `onion_chopped.glb` : `one cartoon brown onion` / `cartoon onion rings and slices`
- `food/bread_bun.glb` : `cartoon burger bun, golden brown, sesame seeds`
- `food/patty_raw.glb` / `patty_cooked.glb` : `raw pink cartoon burger patty` / `grilled brown cartoon burger patty with grill marks`
- `food/plate_empty.glb` : `empty round white plate, cartoon`
- Plats finis : `food/salad_bowl.glb`, `food/soup_bowl.glb`, `food/burger.glb`
- `kitchen/assembly_counter.glb` : `square compact kitchen counter with a white plate on top and a small order ticket rail, cube-shaped`
- Icônes 2D des ingrédients pour les tickets : `flat cartoon icon of a <ingredient>, thick outline, transparent background`

## 6. Questions à trancher en équipe avant de commencer
- [ ] Combien de commandes en même temps (2 ou 3) ? Combien de temps pour chacune ?
- [ ] Livrer un plat **non commandé** : refusé (il reste dans les mains) ou accepté pour 0 point ?
- [ ] Les étoiles comptent-elles des **points** (recommandé) ou des **plats** ?
- [ ] Le juge de la Phase 6 note-t-il aussi la **recette** (bonus si la note est haute) ?
- [ ] Quelles recettes pour la démo (2 suffisent pour montrer le concept) ?
