# Phase 6 — Juge de plats, personnalité du rat, récap' final

| | |
|---|---|
| **Statut** | 🟡 Juge fait (banque de textes) ; IA en direct, personnalité du rat et récap' à faire |
| **Dépend de** | Phase 5 (serveur relais, file audio, bulle), Phase 4 (écran de fin, compte à rebours), Phase 3 (`RatProfile`) |
| **Débloque** | Phase 8 (démo) |
| **Profil** | Dev IA/backend |
| **Estimation** | 1 h 30 à 2 h |
| **Fichiers possédés** | `server/*` (nouvelles routes), `scripts/ai/*`, `data/judge_bank.json`, `data/rat_profiles/*.tres`, `scenes/ui/judge_card.tscn` |

---

## 1. Objectif

Trois usages de l'IA, **tous sans risque pour le gameplay** :
1. **Personnalité du rat** : un appel au lancement génère son nom, sa réplique d'entrée et ses curseurs de comportement.
2. **Juge de plats** : à chaque livraison, un nom de plat absurde et une critique courte.
3. **Récap' final** : sur l'écran de fin, un texte personnalisé à partir du journal de la partie, lu à voix haute. C'est **le moment « IA en direct »** à montrer au jury.

Règles de design : [CONCEPT.md §9](../CONCEPT.md#9-lintelligence-artificielle).

## 2. État jouable exigé (critères d'acceptation)

- [ ] Pendant le compte à rebours, le **nom** et la **réplique d'entrée** du rat s'affichent (et le commentateur la lit si possible).
- [ ] Les **curseurs** générés changent réellement le comportement du rat (vitesse, fréquence, sabotage préféré), **dans des limites sûres** (valeurs bornées).
- [ ] Si l'IA ne répond pas en **3 s** au lancement : profil tiré d'une banque de 3 à 5 profils écrits à la main. **Le jeu ne démarre jamais en retard.**
- [x] À chaque plat livré, le **juge** (assis à la table de droite de la salle) reçoit l'assiette, goûte, réagit et affiche une **bulle** au-dessus de lui : nom du plat, **note sur 5 étoiles**, critique. Les livraisons rapprochées sont jugées l'une après l'autre. Implémentation : `scenes/judge.tscn`, `scripts/judge/`, `data/judge_bank.json`. Note : 4 de base, +1 si servi en moins de 12 s, −1 au-delà de 25 s, −1 si le rat a saboté entre-temps, un peu de hasard.
- [ ] Sur l'écran de fin, un **récap' personnalisé** qui cite des faits réels de la partie (nombre de plats, sabotages, coups sur le rat, nom du rat), affiché progressivement (effet machine à écrire) et **lu à voix haute**.
- [ ] Si le récap' IA ne répond pas en **8 s** : récap' de secours construit à partir des statistiques, sans erreur visible.
- [ ] Testé hors ligne et en ligne, sur téléphone.

## 3. Nouvelles routes du relais (même serveur que la Phase 5)

| Route | Entrée | Sortie | Délai max |
|-------|--------|--------|----------:|
| `POST /rat-profile` | `{}` (ou `{"seed": 42}`) | JSON profil (§4) | 3 s |
| `POST /judge` | `{"dish_index": 3, "context": {"was_sabotaged": true, "time_taken": 14.2}}` | `{"dish_name": "…", "critique": "…", "score": 7}` | 3 s |
| `POST /recap` | `{"events": [...], "stats": {...}, "rat_name": "Gaston", "score": 9, "stars": 1}` | `{"text": "…"}` | 8 s |

Utiliser la **sortie JSON structurée** de Gemini (type de réponse `application/json` + schéma) pour `/rat-profile` et `/judge` : pas de parsing de texte libre.

## 4. Personnalité du rat

### Schéma demandé à l'IA
```json
{
  "name": "Gaston le Grignoteur",
  "intro_line": "Ta cuisine sent bon… elle sentira bientôt MON odeur.",
  "speed": 0.6,
  "aggressiveness": 0.7,
  "favorite_sabotage": "steal"
}
```
- `speed` et `aggressiveness` entre 0 et 1 ; `favorite_sabotage` parmi `stove_off`, `steal`, `spill`.

### Conversion en `RatProfile` (Phase 3), **côté jeu**
| Champ IA | Champ `RatProfile` | Conversion (bornée) |
|----------|--------------------|---------------------|
| `name` | `display_name` | texte coupé à 24 caractères |
| `intro_line` | `intro_line` | texte coupé à 90 caractères |
| `speed` 0..1 | `speed` | `lerp(3.0, 5.0, clamp(v, 0, 1))` (toujours plus lent que le joueur) |
| `aggressiveness` 0..1 | `aggressiveness` | `clamp(v, 0.2, 0.9)` |
| `favorite_sabotage` | `weight_*` | le favori ×2, les autres ×1 |

**Jamais** faire confiance aux valeurs brutes : tout est borné côté jeu, et une valeur absente ou invalide prend la valeur par défaut.

### Prompt (point de départ)
```
Invente le rat saboteur d'un jeu de cuisine comique. Il sort d'un trou pour embêter le chef.
Donne-lui un nom ridicule et mémorable (prénom + surnom), une réplique d'entrée
provocatrice mais bon enfant (une phrase, 15 mots max), et une personnalité
traduite en curseurs. Varie les personnalités d'une partie à l'autre.
Réponds uniquement avec le JSON demandé.
```

### Quand l'appeler
Au **toucher de l'écran titre** (Phase 4) : la requête part et le compte à rebours commence **en même temps**. Si la réponse arrive avant la fin du compte à rebours, on l'utilise ; sinon, profil de secours. **Le compte à rebours n'attend jamais.**
Banque de secours : `data/rat_profiles/gaston.tres`, `ratatouille_nulle.tres`, etc. (3 à 5 profils écrits à la main).

## 5. Juge de plats

- Sur `event_logged` avec `event == "dish_delivered"` → afficher une **carte** (`scenes/ui/judge_card.tscn`) en haut de l'écran, sous le score, pendant 2,5 s : **nom du plat** en gros, critique en dessous, note « 7/10 ».
- **Source par défaut : la banque** `data/judge_bank.json`, qui contient des **morceaux combinables** pour avoir beaucoup de variété avec peu de texte :
  ```json
  {
    "dish_prefixes": ["Tomate", "Carpaccio", "Symphonie", "Mille-feuille"],
    "dish_suffixes": ["existentialiste", "du désespoir", "à la sauvette", "façon grand-mère énervée"],
    "critiques": ["Croquant comme un lundi matin.", "J'ai pleuré. De joie ? Je ne sais pas."],
    "critiques_sabotaged": ["On sent le passage du rat. Et pas en bien."]
  }
  ```
- **En direct** (si le relais est configuré) : `/judge` avec le contexte (le plat a-t-il été saboté ? combien de temps a-t-il pris ?). C'est sans urgence : si la réponse arrive dans les 3 s, on met à jour la carte, sinon on garde la banque.
- **Pas de voix pour le juge**, pour ne pas couvrir le commentateur. On peut éventuellement le faire lire au commentateur en priorité basse.
- **Option d'équilibrage** (à décider en équipe, **désactivée par défaut**) : la note multiplie le point (8/10 et plus = 2 points). Si on l'active, mettre à jour CONCEPT §7 et les paliers.

## 6. Récap' final

### Statistiques à envoyer (calculées à partir de `GameState.events`)
```json
{
  "dishes": 9, "stars": 1, "duration": 90,
  "rat_name": "Gaston le Grignoteur",
  "rat_hits": 4, "stove_off": 2, "steals": 3, "steals_recovered": 1, "spills": 1,
  "fastest_dish_s": 8.4, "longest_gap_s": 21.0
}
```
Envoyer **les stats et le journal** : les stats pour la fiabilité des chiffres, le journal pour les anecdotes (« à 42 s, il t'a volé ta tomate juste sous ton nez »).

### Prompt (point de départ)
```
Tu es le commentateur de « Tomato Wars ». La partie est finie. Fais un récap' de 3 phrases maximum,
drôle et bienveillant, adressé au joueur (tutoiement). Cite au moins deux faits précis
tirés des statistiques ou du journal, et le nom du rat. Termine par une phrase qui donne
envie de rejouer. N'invente aucun chiffre.
Statistiques : {stats}
Journal : {events}
```

### Affichage
- Dans la zone de texte de `result_screen.tscn` (Phase 4) : « Le jury délibère… » avec une animation, puis le texte avec un effet **machine à écrire** (`visible_ratio` animé).
- Voix : `/tts` puis lecture sur le bus `Voice` (file de la Phase 5).
- **Secours** (délai ou erreur) : modèle de phrases à trous, par exemple : « {dishes} plats servis et {rat_hits} coups de poêle sur {rat_name} ! » + une réplique `result_{stars}_star(s)` de la banque du commentateur.

## 7. Découpage en tâches
1. [ ] Routes `/rat-profile`, `/judge`, `/recap` dans le relais (JSON structuré + délais).
2. [ ] 3 à 5 `RatProfile` de secours + conversion et bornage IA → `RatProfile`.
3. [ ] Appel au toucher de l'écran titre, puis affichage du nom et de la réplique pendant le compte à rebours.
4. [ ] `judge_bank.json` + `judge_card.tscn` + branchement sur `dish_delivered`.
5. [ ] Mode direct du juge (optionnel).
6. [ ] Calcul des statistiques + `/recap` + effet machine à écrire + voix + secours.
7. [ ] Tests hors ligne, en ligne et avec un réseau lent (ajouter un délai dans le relais).
8. [ ] Documentation : ARCHITECTURE (routes, schémas), cases de cette fiche.

## 8. Pièges connus
- **L'IA invente des chiffres** dans le récap' : lui donner les stats **explicitement** et lui interdire d'inventer. Relire plusieurs récap' avant la démo.
- **JSON invalide ou champ manquant** : toujours valider et prendre la valeur par défaut, jamais planter.
- **Texte trop long** pour l'écran : couper côté jeu (et le demander court dans le prompt).
- **Récap' qui arrive après que le joueur a cliqué sur Rejouer** : ignorer les réponses dont la manche n'est plus la manche actuelle (garder un identifiant de manche).

## 9. Hors périmètre
- Tout ce qui ferait piloter une action du rat **en temps réel** par l'IA : interdit par le concept.
