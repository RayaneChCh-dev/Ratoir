# Travailler à plusieurs sur Ratoir

Godot stocke les scènes dans des fichiers texte (`.tscn`), mais **deux personnes qui modifient la même scène en même temps**, c'est un conflit git quasi garanti et pénible à résoudre. Ces règles sont là pour l'éviter.

---

## 1. Installation (une fois)

1. **Godot 4.7.x Standard** (pas .NET) : <https://godotengine.org/download>. **Tout le monde doit avoir la même version** (4.7.x) : une autre version réécrit les fichiers de scène et crée des conflits.
2. **Templates d'export Web** : dans Godot, *Éditeur → Gérer les modèles d'exportation → Télécharger et installer*.
3. Cloner et ouvrir :
   ```bash
   git clone git@github.com:RayaneChCh-dev/Ratoir.git
   ```
   Puis dans Godot : *Importer* → `Ratoir/project.godot`.
4. Pour tester sur téléphone : `python3` et `openssl` (déjà présents sur Linux et macOS). Voir le [README](../README.md#tester-sur-téléphone).

## 2. Branches et commits

- `main` doit **toujours se lancer sans erreur** et être jouable : c'est la version publiée. On ne pousse **jamais** directement dessus.
- `staging` est la branche d'intégration. On ne pousse **jamais** directement dessus non plus.
- **Une branche par tâche**, créée **depuis `staging`** et nommée d'après la phase : `phase-3/rat-ia`, `phase-4/ecran-fin`, `phase-7/modele-chef`…
- Circuit : `phase-N/<sujet>` → PR vers `staging` → (quand c'est stable) PR `staging` → `main`.
- **Petits commits fréquents**, messages en français à l'impératif : `Ajoute le bouton TAPER`, `Corrige la plaque qui reste éteinte`.
- On fusionne dans `staging` via une **Pull Request** relue rapidement par quelqu'un d'autre (5 minutes suffisent : ça se lance ? ça marche sur téléphone ?).
- Avant de pousser : `git pull --rebase origin staging`, puis vérifier que le projet se lance (<kbd>F5</kbd>).

## 3. Qui possède quelle scène

**Une scène = un propriétaire à la fois.** Si tu dois modifier une scène que tu ne possèdes pas, préviens son propriétaire (ou attends qu'il ait poussé).

| Fichier | Propriétaire par défaut | Remarque |
|---------|------------------------|----------|
| `scenes/main.tscn` | Personne en charge du gameplay (Phase 3/4) | **La scène la plus sensible.** Les autres créent **leurs propres scènes** et demandent qu'on les ajoute dans `main.tscn` |
| `scenes/player.tscn` | Gameplay (Phase 3), puis Assets (Phase 7) | Passage de relais explicite |
| `scenes/rat.tscn` *(à créer)* | Gameplay (Phase 3) | |
| `scenes/*_station.tscn`, `ingredient_spawn.tscn`, `delivery_counter.tscn` | Gameplay, puis Assets (Phase 7) | |
| `scenes/ui/*` *(à créer)* | Phase 4 | Écran titre, écran de fin |
| `scripts/game_state.gd` | Phase 4 | Les autres **utilisent** son API sans la modifier ; pour ajouter quelque chose, en parler |
| `scripts/ai/*`, autoload `Commentator` *(à créer)* | IA (Phases 5 et 6) | Indépendant du reste : communique **uniquement** par les signaux de `GameState` |
| `assets/**` | Assets (Phase 7) | |
| `docs/**` | Tout le monde | Mettre à jour la doc **dans la même PR** que le code |

**Astuce anti-conflit :** plutôt que d'ajouter 10 nœuds dans `main.tscn`, crée une scène (ex. `scenes/ui/result_screen.tscn`) et fais-la instancier une seule fois dans `main.tscn`. Une seule ligne à fusionner au lieu de 50.

## 4. Fichiers à committer ou non

| Committer ✅ | Ne pas committer ❌ |
|-------------|--------------------|
| `.tscn`, `.gd`, `.gdshader`, `.tres` | `.godot/` (cache, régénéré automatiquement) |
| **Les fichiers `.uid`** (Godot 4.4+ en crée un à côté de chaque script ou shader : ils servent aux références, **il faut les committer**) | `build/` (exports, zip, certificats) |
| Les `.import` à côté des assets | Les scènes ou scripts de test perso |
| `project.godot`, `export_presets.cfg` | Des packs d'assets entiers (seulement les fichiers utilisés) |

## 5. Définition de « terminé » pour une tâche

Une tâche est terminée quand :
1. Le projet se lance **sans erreur ni avertissement** dans la console Godot.
2. Les **critères d'acceptation** de la fiche de phase sont vérifiés.
3. Ça a été **testé sur un vrai téléphone** (export Web + `tools/serve_https.py`) si ça touche aux contrôles, à l'affichage, au son ou aux performances.
4. La doc est à jour : [ARCHITECTURE.md](ARCHITECTURE.md) si un contrat a changé, [CONCEPT.md](CONCEPT.md) si une règle du jeu a changé, et la fiche de phase (cases cochées).
5. La PR est fusionnée dans `staging`.

## 6. Conventions de code

Résumé (le détail est dans [ARCHITECTURE.md](ARCHITECTURE.md#3-conventions-à-respecter-par-tout-le-monde)) :
- GDScript **typé** statiquement, indentation par **tabulations**.
- **Commentaires en français**, identifiants en anglais.
- Pas de `class_name` qui porte le nom d'une classe native de Godot.
- Les événements de jeu passent **toujours** par `GameState.log_event(...)`, avec un nom de la liste officielle.
- **Jamais de clé d'API dans le dépôt ni dans le jeu** (voir [Phase 5](phases/PHASE-5-commentateur.md#sécurité-des-clés)).
