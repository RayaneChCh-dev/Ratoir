# Ratoir

> Un jeu de cuisine mobile en 3D où tu dois servir un maximum de plats avant la fin du temps… pendant qu'un rat sort de son trou pour tout saboter.

<p align="center"><img src="docs/images/screenshot.png" width="300" alt="Capture du jeu : le cuisinier bleu tient une assiette, le trou du rat est dans le mur du fond"></p>

Projet de hackathon réalisé avec **Godot 4.7** et exporté pour le **navigateur mobile** (HTML5, hébergé sur itch.io).
Le chef cuisine dans la cuisine, un rat sabote, un juge en salle note chaque plat, et un critique commente avec neuf phrases déjà enregistrées (voir [le concept complet](docs/CONCEPT.md)).

---

## Sommaire

- [Le jeu en 30 secondes](#le-jeu-en-30-secondes)
- [État d'avancement](#état-davancement)
- [Démarrer (développeurs)](#démarrer-développeurs)
- [Entendre le critique](#entendre-le-critique)
- [Contrôles](#contrôles)
- [Tester sur téléphone](#tester-sur-téléphone)
- [Publier sur itch.io](#publier-sur-itchio)
- [Structure du dépôt](#structure-du-dépôt)
- [Documentation](#documentation)

---

## Le jeu en 30 secondes

- **Format** : portrait, plein écran, sur téléphone (dans le navigateur).
- **Vue** : 3D en plongée façon *Overcooked*. La caméra ne tourne jamais ; elle suit le joueur en glissant quand il s'éloigne du centre de l'écran.
- **Deux pièces** : la **cuisine** (bac, découpe, plaque, comptoir) et la **salle**, où le juge est assis.
- **Boucle** : prendre une tomate au bac → la **découper** → la **cuire** → la **livrer** au comptoir → **+1 point**. Tout se fait au contact, sans bouton.
- **L'ennemi** : un **rat** sort d'un trou pour éteindre la plaque, renverser le plat ou voler un ingrédient. On rallume la plaque au contact. En manche 3, quand il court plus vite que le chef, un bac à **pièges** apparaît : on en prend un et on le pose (bouton **POSER** ou <kbd>E</kbd>).
- **Progression** : 3 manches, à 5, 10 puis 15 plats cumulés. Le chrono passe de 90 s à 75 s puis 60 s, la recette accélère, et le rat court plus vite (4 m/s, 5,6 m/s, puis 7,2 m/s ; le chef reste à 6 m/s). Pas de vies : chrono à 0 avant l'objectif = partie terminée. La 3e manche réussie = victoire.
- **Écrans** : **PLAY** au départ (la partie est en pause tant qu'on n'a pas touché), **VICTOIRE !** ou **PARTIE TERMINÉE**, puis **REJOUER**.
- **Le juge** : à chaque livraison, l'assiette va jusqu'à sa table. Il donne un nom de plat, une note sur 5 et une phrase, tirés d'une banque locale. Ça ne met pas le jeu en pause.
- **Le critique** : neuf phrases anglaises déjà enregistrées. Toutes les quelques secondes, il commente l'action la plus fréquente (prendre, découper, cuire, livrer). Le jeu n'attend jamais la voix.
- **Musique** : une minute de morceau par manche, bouclée tant que le chrono dure. Elle démarre après **PLAY** (geste exigé par le navigateur).

## État d'avancement

| Phase | Contenu | État |
|------:|---------|------|
| 1 | Squelette : scène 3D, caméra, joueur, joystick tactile, export Web | ✅ Terminé |
| 2 | Boucle de cuisine complète (ramasser, découper, cuire, livrer, score) + passage en portrait | ✅ Terminé |
| 3 | Le rat et ses sabotages (le coup pour le taper est désactivé pour l'instant) | ✅ Terminé |
| 4 | Manche : 3 niveaux, chrono, écran PLAY, victoire et défaite | ✅ Jouable |
| 5 | Critique vocal : neuf phrases MP3 selon l'action dominante | ✅ Démo jouable |
| 6 | Juge de plats local ; personnalité du rat et récap' IA encore à faire | ⏳ En cours |
| 7 | Modèles 3D du chef, du rat, du juge et de la cuisine branchés ; sons et effets encore à faire | ⏳ En cours |
| 8 | Déploiement itch.io, tests sur téléphones, script et répétition de la démo | ⏳ À faire |
| 9 | Recettes à plusieurs ingrédients, plan de dressage, commandes | 💡 Plus tard |

Chaque phase restante a sa fiche détaillée dans [`docs/phases/`](docs/phases/README.md), avec la répartition possible entre coéquipiers.

## Démarrer (développeurs)

1. **Installer Godot 4.7.x « Standard »** (pas la version .NET) : <https://godotengine.org/download>.
2. **Cloner** le dépôt :
   ```bash
   git clone git@github.com:RayaneChCh-dev/Ratoir.git
   cd Ratoir
   ```
3. **Ouvrir** Godot → *Importer* → choisir `project.godot`. Le premier import régénère le dossier `.godot/` (ignoré par git, c'est normal).
4. **Lancer** avec <kbd>F5</kbd>. La scène principale est `scenes/main.tscn`.

> 💡 Sur ordinateur, la souris simule le doigt (`emulate_touch_from_mouse`) : clique-glisse n'importe où pour faire apparaître le joystick. Le clavier marche aussi.

Avant de coder, lis [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) (règles pour ne pas se marcher dessus dans les scènes Godot) et [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Entendre le critique

Les neuf phrases sont déjà enregistrées dans `assets/audio/critic/` (voix Mark). Le jeu les joue tout seul : pas besoin de lancer le proxy ni d'une clé Gradium.

```bash
godot --path .
```

Appuie sur **PLAY**. La voix dit « I'm hungry. The chef had better hurry. » Il n'y a pas de sous-titre. Ensuite, la phrase suivante suit l'action la plus fréquente sur environ 4 secondes.

## Contrôles

| Action | Téléphone | Ordinateur |
|--------|-----------|------------|
| Se déplacer | Poser le pouce **n'importe où** et glisser (joystick flottant) | Clic-glisser, ou <kbd>Z</kbd><kbd>Q</kbd><kbd>S</kbd><kbd>D</kbd> / <kbd>W</kbd><kbd>A</kbd><kbd>S</kbd><kbd>D</kbd> / flèches |
| Ramasser, poser, livrer | **Automatique au contact** : marcher jusqu'au tapis devant un meuble | idem |
| Poser un piège | Bouton **POSER** (manche 3, seulement si un piège est en main) | <kbd>E</kbd> |
| Taper le rat | *Désactivé* (voir CONCEPT §8.3). La parade jouable est le piège | — |
| Commencer / rejouer | **PLAY**, puis **REJOUER** | idem |

## Tester sur téléphone

Godot Web exige une page servie en **HTTPS** (ou `localhost`). Pour tester sur ton téléphone depuis ton PC :

```bash
./tools/export_web.sh            # exporte dans build/web/ (+ build/ratoir-web.zip)
python3 tools/serve_https.py     # affiche l'adresse à ouvrir, ex. https://192.168.1.20:8765
```

Sur le téléphone (même Wi-Fi que le PC) : ouvrir l'adresse affichée → avertissement « connexion non privée » (certificat auto-signé, normal) → *Paramètres avancés* → *Continuer vers le site*.

**Prérequis de l'export** : les *export templates* Godot 4.7.x pour le Web. Dans l'éditeur : *Éditeur → Gérer les modèles d'exportation → Télécharger et installer*.

## Publier sur itch.io

1. `./tools/export_web.sh` → produit `build/ratoir-web.zip` (`index.html` à la racine du zip, c'est ce qu'itch.io attend).
2. Sur itch.io : *Create new project* → **Kind of project : HTML** → envoyer le zip → cocher **« This file will be played in the browser »**.
3. Dans *Embed options* : cocher **Mobile friendly**, orientation **Portrait**, et **Fullscreen button**.
4. Taille de la fenêtre intégrée conseillée : 360 × 640 (ratio 9:16).
5. Pas besoin de cocher *SharedArrayBuffer support* : l'export est configuré **sans threads** exprès.

Détails et checklist de démo : [`docs/phases/PHASE-8-demo.md`](docs/phases/PHASE-8-demo.md).

## Structure du dépôt

```
Ratoir/
├── project.godot                 # portrait 720×1280, rendu Compatibility
│                                 # autoloads : GameState, Commentator
├── export_presets.cfg            # export Web, sans threads
├── scenes/
│   ├── main.tscn                 # cuisine, salle, joueur, rat, juge, musique, UI
│   ├── player.tscn               # le chef
│   ├── rat.tscn                  # le rat et ses sabotages
│   ├── judge.tscn                # le juge à table, bulle de note
│   ├── chop_station.tscn         # découpe
│   ├── cook_station.tscn         # cuisson
│   ├── ingredient_spawn.tscn     # bac à tomates
│   ├── delivery_counter.tscn     # comptoir : +1 point
│   ├── trap_bin.tscn             # bac à pièges (manche 3)
│   ├── rat_trap.tscn             # piège posé au sol
│   └── ui/
│       ├── game_hud.tscn         # niveau, chrono, score / objectif
│       └── onboarding.tscn       # PLAY, VICTOIRE, PARTIE TERMINÉE
├── scripts/
│   ├── game_state.gd             # manche, chrono, score, journal
│   ├── soundtrack.gd             # une minute de morceau par manche
│   ├── ai/commentator.gd         # neuf phrases MP3, selon l'action dominante
│   ├── judge/                    # note locale, data/judge_bank.json
│   ├── rat/                      # machine à états et sabotages
│   └── ui/                       # HUD et écrans d'accueil / fin
├── assets/
│   ├── audio/sizzling_bistro_panic.mp3
│   ├── audio/critic/             # neuf phrases du critique
│   └── models/                   # chef, rat, juge, meubles, plats
├── data/judge_bank.json          # noms de plats et critiques du juge
├── server/                       # ancien proxy Gradium, plus appelé en jeu
└── docs/                         # concept, architecture, phases
```

## Documentation

| Document | Pour qui | Contenu |
|----------|----------|---------|
| [CONCEPT.md](docs/CONCEPT.md) | Toute l'équipe, le jury | Vision, règles, rat, sabotages, IA, direction artistique |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Développeurs | Scènes, scripts, autoloads, événements, conventions |
| [ASSETS.md](docs/ASSETS.md) | Artiste / intégrateur | Où trouver ou comment générer les modèles 3D, format, import |
| [CONTRIBUTING.md](docs/CONTRIBUTING.md) | Toute l'équipe | Branches, commits, conflits de scènes, tests |
| [phases/](docs/phases/README.md) | Toute l'équipe | Feuille de route et répartition du travail |
