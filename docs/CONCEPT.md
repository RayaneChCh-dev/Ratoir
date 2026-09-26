# Ratoir — Concept complet

> **Document de référence du jeu.** En cas de doute ou de contradiction avec un autre document (y compris le PDF de conception d'origine « Duel de Cuisine »), **c'est ce fichier qui fait foi**.
> Toute décision de design qui change le jeu doit être reportée ici.

---

## 1. Le pitch

**Ratoir** est un jeu de cuisine en 3D pour téléphone. Le joueur est un cuisinier qui doit servir **le plus de plats possible avant la fin du chrono**. Un **rat** sort régulièrement d'un trou dans le mur pour **saboter** la cuisine. Le joueur peut **le taper** pour le faire fuir, mais chaque seconde passée à chasser le rat est une seconde de moins pour cuisiner.

Pendant la partie, un **commentateur IA** façon commentateur sportif réagit à ce qui se passe, avec une voix de synthèse. Un **juge IA** donne un nom absurde et une critique à chaque plat livré. À la fin, l'IA rédige un **récap' personnalisé** de la partie.

**En une phrase pour le jury :** *« Overcooked en solo contre un rat saboteur, commenté en direct par une IA. »*

## 2. Piliers de design

Quand il faut trancher, on suit ces priorités dans l'ordre :

1. **La boucle de cuisine d'abord.** Elle doit être solide et agréable avant d'ajouter quoi que ce soit. Aucune fonctionnalité ne doit la casser.
2. **Lisible en un coup d'œil, sur un petit écran.** Couleurs franches, formes simples, un seul bouton, textes gros.
3. **L'IA ne bloque jamais le jeu.** Tout appel réseau est asynchrone et a un plan B pré-généré. Si Internet tombe pendant la démo, le jeu reste jouable et continue de commenter.
4. **Court et rejouable.** Une manche dure 60 à 90 secondes, et on veut en relancer une tout de suite pour avoir plus d'étoiles.

## 3. Plateforme et format

| Élément | Choix | Pourquoi |
|---------|-------|----------|
| Moteur | Godot 4.7 (rendu *Compatibility*) | Le seul rendu compatible avec l'export Web |
| Cible | **Navigateur mobile** (export HTML5), hébergé sur **itch.io** | Pas de build Android/iOS (SDK, signature…) à gérer pendant un hackathon |
| Orientation | **Portrait** (720 × 1280 de référence, s'adapte aux écrans plus longs) | Conseil du jury : c'est la façon naturelle de tenir un téléphone |
| Joueurs | **1 joueur humain**, tout en local, pas de réseau de jeu | Simplicité |

## 4. Contrôles

- **Déplacement** : joystick **flottant** et **plein écran**. Le pouce se pose n'importe où, le joystick apparaît sous le doigt et on glisse. Le déplacement reste toujours à plat, sur le sol.
- **Interactions de cuisine** : **automatiques au contact**. On marche jusqu'au tapis coloré devant un meuble et l'action se fait toute seule (ramasser, poser, reprendre, livrer).
- **Un seul bouton à l'écran** : **TAPER**, dans le coin en bas à droite, facile à atteindre avec le pouce libre. Il sert uniquement à taper le rat quand il est à portée. *(Phase 3)*
- Sur ordinateur (développement) : clic-glisser à la souris, ou <kbd>ZQSD</kbd>/<kbd>WASD</kbd>/flèches, et <kbd>Espace</kbd> pour taper.

## 5. Caméra et vue

- **Vue en plongée à 55°**, projection orthographique. La cuisine est droite, alignée avec l'écran : **pas** de vue isométrique en losange.
- **La caméra ne tourne jamais** et le joueur ne la contrôle pas.
- **Elle suit le joueur** en se déplaçant dans le plan (gauche/droite, haut/bas). Tant que le joueur reste dans une petite zone au centre de l'écran (*zone morte*), elle ne bouge pas. Dès qu'il en sort, elle glisse en douceur.
- **Elle ne montre jamais l'extérieur** de la cuisine : elle s'arrête aux bords.
- La cuisine est volontairement **plus grande que l'écran** (environ 12 × 22 m) : on voit environ 9 m de large, donc la caméra se déplace.

## 6. La cuisine

Une seule pièce, un seul niveau.

```
          mur du fond (haut, avec le TROU DU RAT au centre)
   ┌──────────────────────────────────────────┐
   │ [TOMATES]          (trou)      [DÉCOUPE]  │
   │                                           │
   │                                           │
   │                                 [CUISSON] │
   │               (joueur)                    │
   │                                           │
   │                                           │
   │   [LIVRAISON]                             │
   └──────────────────────────────────────────┘
          mur de devant (bas)
```

| Meuble | Rôle | Règle |
|--------|------|-------|
| **Tomates** (bac, tapis jaune) | Source d'ingrédients | Donne une tomate crue à qui arrive les mains vides |
| **Découpe** (planche, tapis bleu) | Transformation 1 | Accepte une tomate **crue**, la découpe en **1,5 s**, puis on la reprend au contact |
| **Cuisson** (plaque, tapis orange) | Transformation 2 | Accepte une tomate **découpée**, la cuit en **2,5 s**, puis on reprend une **assiette** au contact |
| **Livraison** (comptoir, tapis vert) | Score | Accepte une assiette **cuite** : +1 point, « +1 » à l'écran |
| **Trou du rat** (mur du fond) | Point d'entrée et de sortie du rat | Le rat y apparaît et y retourne *(Phase 3)* |

**Règles d'objets :** le joueur tient **un seul objet à la fois**. Un objet qui n'est pas au bon état est ignoré par la station (une tomate crue ne va pas sur la plaque). La station continue de travailler même si le joueur s'éloigne, ce qui permet d'aller chercher la tomate suivante pendant la cuisson.

**Volontairement pas de recettes complexes** pour l'instant : un ingrédient qui passe par les deux stations fait un plat valide. On pourra ajouter une variante de recette au polish, **jamais avant** que la boucle et le rat soient solides.

**Plus tard : les recettes.** Le fonctionnement prévu est décrit dans [PHASE-9-recettes.md](phases/PHASE-9-recettes.md) : commandes affichées en tickets, chaque ingrédient préparé séparément, puis assemblé au contact sur une assiette posée sur un plan de dressage.

## 7. La manche, le score et les étoiles

- **Progression** : une partie est une suite de niveaux dans la même cuisine. L'objectif cumulé est de 5 plats au niveau 1, puis 10, 15, etc. Atteindre l'objectif valide le niveau et démarre immédiatement le suivant.
- **Chrono** : 90 s au niveau 1, puis 5 s de moins par niveau, avec un plancher de 60 s. Quand il expire avant l'objectif, le joueur perd une vie et rejoue le même niveau ; son score cumulé est conservé.
- **Santé** : 3 vies au départ, +1 vie à chaque niveau réussi, maximum 3. Un dégât direct du rat retire une vie ; à 0, la partie se termine.
- **Difficulté** : le rat reçoit un multiplicateur de +15 % par niveau, plafonné à 2×, pour accélérer et réduire le délai entre ses sorties.
- **Départ protégé** : pendant les **5 premières secondes**, le rat ne sort pas, le temps de comprendre la boucle.
- **Score** : **1 point par plat livré**.
- **Étoiles** à la fin du chrono :

| Résultat | Condition |
|----------|-----------|
| ☆☆☆ | moins de 5 points |
| ★☆☆ | 5 points ou plus |
| ★★☆ | 10 points ou plus |
| ★★★ | 15 points ou plus |

- **Écran de fin** : score, étoiles animées, récap' IA lu à voix haute, bouton **Rejouer**.

> ⚠️ **Équilibrage à faire (Phase 4).** Avec la cuisine actuelle, un plat prend environ 13 s (≈ 9 s de marche et 4 s de transformation). Le premier objectif de 5 plats est donc exigeant avec le rat ; vérifier les valeurs sur téléphone et ajuster ensemble les durées, déplacements et accélération du rat. Objectif : la progression doit rester possible, mais chaque niveau doit demander une meilleure gestion du temps et du rat.

## 8. Le rat

Le rat remplace l'adversaire humain ou bot du document d'origine. C'est un **personnage non joueur** qui vient déranger.

### 8.1 Comportement (machine à états simple et prévisible)

```
CACHÉ ──(délai aléatoire écoulé)──▶ SORT DU TROU ──▶ VA VERS SA CIBLE ──▶ SABOTE ──▶ RETOURNE AU TROU ──▶ CACHÉ
                                                      │                  │
                                         (tapé par le joueur, à tout moment hors CACHÉ)
                                                      ▼
                                                  S'ENFUIT (rapide, lâche ce qu'il porte) ──▶ CACHÉ (pause plus longue)
```

- **Choix de la cible** : parmi les sabotages possibles **à cet instant** (par exemple, il ne peut éteindre la plaque que si quelque chose cuit dessus), avec une préférence réglée par sa personnalité.
- **Temps de sabotage** : environ 1 s sur place avant que l'effet se déclenche. C'est la fenêtre où le joueur peut l'intercepter.
- **Jamais deux sabotages en même temps** : un seul rat, un sabotage à la fois, puis un temps de repos (*cooldown*).
- **Lisibilité** : le rat est gris foncé avec une queue rose, et un **« ! »** apparaît au-dessus de sa cible quand il se dirige vers elle.

### 8.2 Les sabotages

Ils reposent tous sur **un seul système commun** (une cible, une durée d'effet, un temps de repos), pas sur quatre systèmes séparés.

| Sabotage | Condition | Effet | Contre-mesure |
|----------|-----------|-------|---------------|
| **Éteindre la plaque** | Un aliment cuit sur la plaque | La cuisson se met en pause, la plaque devient grise et fume | Le joueur touche la plaque (contact) pour la rallumer |
| **Renverser le plat** | Le joueur porte un objet et le rat le percute | L'objet tombe et est perdu (flaque au sol) | Taper le rat avant qu'il arrive ; éviter son chemin |
| **Voler un ingrédient** | Un objet est posé sur une station | Le rat l'emporte vers son trou | Le taper pendant sa fuite : il lâche l'objet au sol, qu'on peut ramasser |
| **Flaque glissante** *(optionnel)* | Aucune | Une flaque au sol fait glisser et ralentir le joueur pendant quelques secondes | La contourner |

### 8.3 Taper le rat

- Bouton **TAPER** : si le rat est à moins d'environ **1,5 m**, il est **assommé**, s'enfuit dans son trou et reste caché plus longtemps.
- Petit *cooldown* du bouton (environ 0,8 s) pour empêcher le martelage.
- Un retour clair à l'écran : coup de poêle, étoiles au-dessus du rat, petit tremblement de l'écran, bruitage « bonk ».

## 9. L'intelligence artificielle

**Principe absolu : l'IA générative ne pilote jamais une action de jeu en temps réel.** Elle ne fait que parler (commentateur, juge, récap') et régler des curseurs au lancement (personnalité du rat).

### 9.1 Journal d'événements

Chaque action notable est enregistrée sous une forme structurée, par exemple `{"t": 12.4, "event": "sabotage_stove_off", "detail": "le rat a éteint la plaque"}`, via `GameState.log_event()`. Ce journal alimente le commentateur, le juge et le récap'. La liste des événements est dans [ARCHITECTURE.md](ARCHITECTURE.md#journal-dévénements).

### 9.2 Personnalité du rat (1 appel IA au lancement)

Avant le début du chrono (donc sans contrainte de temps de réponse), **un seul appel** à Gemini génère le profil du rat : **nom** (ex. « Gaston le Grignoteur »), **réplique d'entrée**, et des **curseurs** (agressivité, vitesse, sabotage préféré, audace). Ces curseurs règlent la machine à états classique ; ils ne la remplacent jamais. Si l'appel échoue ou dépasse le délai, on prend un profil par défaut ou un profil tiré d'une petite banque.

### 9.3 Commentateur en direct

- Ton **commentateur sportif de cuisine**, au second degré, une phrase maximum.
- Les événements sont regroupés par lots de 4 à 6 secondes, sauf un événement important (sabotage, plat livré, rat tapé) qui déclenche une réplique tout de suite.
- **Banque pré-générée prioritaire** : 15 à 20 répliques par catégorie, idéalement avec leur audio déjà synthétisé. Pendant la partie, **aucun appel réseau n'est sur le chemin critique**.
- Voix de synthèse (Gradium TTS) jouée dans une **file d'attente non bloquante**. Une réplique moins importante est abandonnée si un événement plus important arrive.
- **Sous-titres** : chaque réplique s'affiche aussi à l'écran dans une bulle, pour que le jeu soit compréhensible même sans son.

### 9.4 Juge de plat

À chaque livraison, le juge donne un **nom de plat absurde** et une **critique courte**, par exemple : « Tomate Existentialiste — croquante de désespoir, 7/10 ». Ces textes viennent d'une banque ou, si le temps le permet, sont générés en direct (on a quelques secondes, ce n'est pas urgent). *Bonus possible* : la note du juge multiplie le point du plat (à décider lors de l'équilibrage).

### 9.5 Récap' final (le « moment IA en direct »)

Sur l'écran de fin, **un appel** Gemini reçoit tout le journal et écrit un récap' personnalisé (« Tu as tapé Gaston 4 fois, mais il t'a volé 3 tomates… »), lu à voix haute. C'est là qu'on montre de la vraie IA en direct **sans mettre le gameplay en danger**. En secours, un récap' construit à partir d'un modèle de phrases et des statistiques.

### 9.6 Sécurité des clés d'API

Le jeu tourne dans le navigateur : **toute clé mise dans le jeu est publique**. Les appels à Gemini et à Gradium passent donc par un **petit serveur relais** (*proxy*) qui garde les clés secrètes. Voir la [Phase 5](phases/PHASE-5-commentateur.md).

## 10. Direction artistique

- **Ambiance** : *Overcooked* en plus simple. Cuisine chaleureuse, couleurs vives, formes rondes et lisibles.
- **Style** : low-poly coloré. Aujourd'hui ce sont des primitives (cubes, capsules, cylindres) ; en Phase 7 elles seront remplacées par des modèles `.glb` (voir [ASSETS.md](ASSETS.md)).
- **Codes couleur** : le joueur en **bleu** ; le rat en **gris foncé avec une queue rose** ; les tapis devant les meubles indiquent leur rôle (jaune = ingrédients, bleu = découpe, orange = cuisson, vert = livraison).
- **Audio** : musique entraînante, bruitages cartoon (découpe, grésillement, « ding » de livraison, couinement du rat, « bonk »), voix du commentateur par-dessus.
- **Déverrouillage audio** : les navigateurs mobiles bloquent le son tant que l'utilisateur n'a pas touché l'écran. Il y a donc **obligatoirement** un écran « Touchez pour commencer » avant toute voix (Phase 4).

## 11. Hors périmètre (pour ne pas se disperser)

- Multijoueur, réseau, comptes, classements en ligne.
- Plusieurs niveaux ou plusieurs cuisines.
- Recettes à plusieurs ingrédients (sauf en bonus, au polish).
- Rotation ou zoom de la caméra par le joueur.
- Build natif Android/iOS.

## 12. Historique des décisions

| Date | Décision | Raison |
|------|----------|--------|
| 2026-09-26 | Création à partir du PDF « Duel de Cuisine — Document de conception » (duel joueur contre bot, 4 sabotages, IA) | Point de départ |
| 2026-09-26 | Le bot adverse est **remplacé par un rat** saboteur qu'on peut taper ; plus de stations adverses | Plus drôle, plus lisible, un seul joueur |
| 2026-09-26 | **Portrait**, cuisine droite en plongée à 55° (au lieu d'une vue isométrique en losange), **caméra qui suit** le joueur | Conseil du jury, et la carte était trop petite en paysage |
| 2026-09-26 | Score transformé en **étoiles** en fin de manche (5 / 10 / 15 points) | Objectif clair et rejouabilité |
| 2026-09-26 | Nom du jeu : **Ratoir** | Nom du dépôt |
