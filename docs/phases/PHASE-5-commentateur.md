# Phase 5 — Commentateur IA (texte + voix)

| | |
|---|---|
| **Statut** | ⏳ À faire (**peut démarrer maintenant**, en parallèle des phases 3 et 4) |
| **Dépend de** | Phase 2 ✅ (`GameState.event_logged` existe déjà). S'intègre mieux une fois les phases 3 (vrais événements du rat) et 4 (`round_started`) faites |
| **Débloque** | Phase 6 (réutilise le serveur relais et la file audio) |
| **Profil** | Dev IA/backend + un peu de Godot |
| **Estimation** | 2 h 30 à 3 h |
| **Fichiers possédés** | `server/*`, `scripts/ai/*`, `data/commentary_bank.json`, `assets/audio/voice/*`, `scenes/ui/commentator_bubble.tscn`, `tools/generate_*.py` |

---

## 1. Objectif

Un **commentateur sportif de cuisine** réagit en direct à la partie, en **une phrase**, avec **sous-titre et voix**. Exemple : *« Et le rat éteint la plaque ! C'est un coup bas, mesdames et messieurs ! »*

**Règle absolue : le commentateur ne peut jamais bloquer ni ralentir le jeu.** Il a toujours une réplique de secours prête, et aucun appel réseau n'est sur le chemin critique.

Règles de design : [CONCEPT.md §9](../CONCEPT.md#9-lintelligence-artificielle).

## 2. État jouable exigé (critères d'acceptation)

- [ ] Chaque événement important (plat livré, sabotage, rat tapé, 30 s et 10 s restantes, début et fin de manche) déclenche une réplique **en moins d'une seconde**, avec **sous-titre** et **voix**.
- [ ] Les événements mineurs sont regroupés : au plus une réplique toutes les 4 à 6 s, pas de mitraillage.
- [ ] **Jamais deux voix en même temps.** Une réplique plus importante interrompt ou remplace une moins importante.
- [ ] **Pas de répétition** de la même réplique dans une manche (tant que la banque le permet).
- [ ] **Mode hors ligne** : Wi-Fi coupé, le jeu commente quand même (banque et audio pré-générés), **sans erreur ni ralentissement**.
- [ ] **Mode en direct** (optionnel, activable) : certaines répliques sont générées par Gemini ; si la réponse arrive trop tard (> 2,5 s), elle est **abandonnée** et on garde la banque.
- [ ] **Aucune clé d'API** dans le dépôt ni dans le build Web.
- [ ] Testé sur un vrai téléphone : son audible après l'écran titre et fluidité intacte.

## 3. Architecture

```
┌──────────── Jeu (navigateur) ────────────┐        ┌──── Serveur relais (proxy) ────┐       ┌── Services ──┐
│ GameState.event_logged                   │        │ POST /comment  ──────────────────────▶ Gemini       │
│        │                                 │ HTTPS  │ POST /tts      ──────────────────────▶ Gradium TTS  │
│        ▼                                 │◀──────▶│ (Phase 6 : /rat-profile,        │       └──────────────┘
│ Commentator (autoload)                   │        │  /judge, /recap)                │
│  ├─ classe l'événement → catégorie       │        │ Garde les clés (variables       │
│  ├─ choisit : banque (défaut) ou direct  │        │ d'environnement), CORS, délais  │
│  ├─ file de répliques avec priorités     │        └─────────────────────────────────┘
│  ├─ bulle de sous-titre                  │
│  └─ AudioStreamPlayer (bus « Voice »)    │
└──────────────────────────────────────────┘
```

### Sécurité des clés
Un jeu Web est **entièrement lisible** par n'importe qui (le `.pck` s'ouvre facilement). **Une clé d'API mise dans le jeu est une clé publiée.** Donc :
- les clés Gemini et Gradium vivent **uniquement** dans les variables d'environnement du **serveur relais** ;
- le dépôt contient un `server/.env.example` **sans valeurs**, et `server/.env` est dans `.gitignore` ;
- le relais limite les abus : **CORS** restreint à itch.io et `localhost`, **délai maximal** par requête, **longueur de texte limitée**, et éventuellement un plafond de requêtes par minute ;
- **variante sans clé du tout** : relais sur **Google Cloud Run** avec **Vertex AI** et un compte de service (aucune clé à gérer).

## 4. Le serveur relais (`server/`)

Petit service HTTP, dans le langage le plus confortable pour l'équipe (Python FastAPI ou Node/Express). À héberger où c'est le plus rapide : Cloud Run, Render, Railway, Vercel, Cloudflare Workers…

### Contrat de l'API (à respecter, la Phase 6 l'étend)
| Route | Entrée (JSON) | Sortie | Délai max côté relais |
|-------|---------------|--------|----------------------:|
| `POST /comment` | `{"events": [...], "context": {"score": 7, "time_left": 42, "rat_name": "Gaston"}}` | `{"text": "…"}` | 2,5 s |
| `POST /tts` | `{"text": "…", "voice": "commentator"}` | Audio **`audio/mpeg`** (MP3) | 4 s |
| `GET /health` | — | `{"ok": true}` | — |

- **CORS** : autoriser l'origine d'itch.io (les jeux HTML y sont servis depuis un sous-domaine de `itch.zone` : **vérifier l'en-tête `Origin` réel** dans les outils de développement du navigateur une fois le jeu publié) et `https://localhost` / `https://<IP locale>:8765` pour les tests.
- **Gradium** : se référer à sa documentation pour l'URL, l'authentification, les voix disponibles et le format audio renvoyé. Le relais **convertit ou renvoie tel quel en MP3**, pour que le jeu n'ait qu'un format à gérer.
- **Gemini** : un modèle **Flash** (le plus rapide disponible), `temperature` ≈ 0,9, `max_output_tokens` bas (≈ 60).

### Prompt système du commentateur (point de départ)
```
Tu es le commentateur sportif survolté d'une émission de cuisine absurde, « Ratoir ».
Un chef cuisinier doit servir un maximum d'assiettes de tomates avant la fin du chrono,
pendant qu'un rat nommé {rat_name} sort de son trou pour saboter la cuisine.
Tu commentes en français, au second degré, comme un match de foot.
Règles :
- UNE seule phrase, 15 mots maximum.
- Jamais vulgaire, jamais méchant envers le joueur.
- Réagis au DERNIER événement en priorité.
- N'invente pas d'événement qui n'est pas dans la liste.
Exemples :
- « Et c'est une assiette de plus ! Le chef est en feu, mais pas la plaque ! »
- « Oh le rat ! Oh le petit rat ! Il éteint la plaque, c'est scandaleux ! »
- « BONK ! Le rongeur repart dans sa tanière avec une migraine ! »
- « Dix secondes ! Le chef transpire plus que ses tomates ! »
Contexte : score {score}, {time_left} secondes restantes.
Événements récents : {events}
```

## 5. Côté Godot

### 5.1 Autoload `Commentator` (`scripts/ai/commentator.gd`)
À déclarer dans *Projet → Paramètres → Autoload*, **après** `GameState`.

Fonctionnement :
1. Écoute `GameState.event_logged(entry)`.
2. **Classe** l'événement en catégorie avec une **priorité** :

| Événement(s) | Catégorie de la banque | Priorité | Immédiat ? |
|--------------|------------------------|:--------:|:----------:|
| `round_start` | `round_start` | 3 | oui |
| `sabotage_stove_off`, `sabotage_steal`, `sabotage_spill` | `sabotage_stove_off` / `sabotage_steal` / `sabotage_spill` | 3 | oui |
| `rat_hit` | `rat_hit` | 3 | oui |
| `dish_delivered` | `dish_delivered` | 2 | oui |
| `timer_milestone` 30 s / 10 s | `time_30` / `time_10` | 3 | oui |
| `rat_appeared` | `rat_appeared` | 1 | non (regroupé) |
| `stove_relit`, `item_recovered`, `rat_fled` | `recovery` | 1 | non (regroupé) |
| `round_end` | `round_end` | 3 | oui |
| *(aucun événement depuis 8 s)* | `filler` (« Le chef est concentré… ») | 0 | — |

3. **Regroupement** : les événements non immédiats s'accumulent ; toutes les 4 à 6 s, s'il y en a, on produit **une** réplique pour le plus important.
4. **Choix de la réplique** :
   - **Par défaut : la banque.** On tire une réplique **pas encore utilisée** dans la catégorie. Si elle a un fichier audio pré-généré, on le joue directement (latence nulle).
   - **Si le mode direct est activé** et qu'aucune requête n'est en cours : on appelle `/comment` puis `/tts`, avec délai. Si le tout arrive en moins de 2,5 s et que rien de plus important n'est arrivé entre-temps, on l'utilise. Sinon, **on jette la réponse** et on prend la banque.
5. **File de lecture** : une seule réplique à la fois. Une nouvelle réplique de priorité **supérieure** coupe la réplique en cours ; de priorité **égale ou inférieure**, elle attend (au plus 1 en attente, les plus anciennes sont jetées).
6. **Sous-titre** : la bulle affiche le texte pendant la lecture (ou 2,5 s sans audio). **Le texte s'affiche même si la voix échoue.**
7. Remise à zéro sur `round_started` (répliques utilisées, file vide).

### 5.2 Réseau (`HTTPRequest`)
- `HTTPRequest` fonctionne dans l'export Web (il passe par `fetch` du navigateur, **CORS obligatoire** côté relais).
- Régler `timeout` sur le nœud (ex. 3 s) **et** vérifier soi-même le temps écoulé à la réception.
- Lire l'audio reçu :
  ```gdscript
  var stream := AudioStreamMP3.new()
  stream.data = body            # PackedByteArray reçu de /tts
  _voice_player.stream = stream
  _voice_player.play()
  ```
- Adresse du relais : `@export var proxy_url := ""` sur l'autoload (ou un paramètre de projet). **Vide = mode hors ligne** (banque seulement). C'est la valeur par défaut, la plus sûre.

### 5.3 Audio
- Créer des **bus audio** : `Master` → `Music`, `SFX`, `Voice`.
- Pendant une réplique, **baisser la musique** (≈ −8 dB) puis la remonter : c'est le *ducking*. On peut aussi le faire en Phase 7.
- **Ne rien jouer avant `round_started`** : l'audio n'est débloqué qu'après le premier contact (Phase 4).

### 5.4 Bulle de sous-titre (`scenes/ui/commentator_bubble.tscn`)
- En bas de l'écran, **au-dessus du joystick** mais sans gêner le pouce : par exemple entre 60 % et 75 % de la hauteur, ou juste sous le score.
- Fond sombre arrondi, texte blanc **gros** (≥ 32 px), petite icône micro, apparition et disparition en fondu.
- `mouse_filter = IGNORE` : ne doit **jamais** bloquer le joystick.

## 6. La banque de répliques

### 6.1 Format (`data/commentary_bank.json`)
```json
{
  "dish_delivered": [
    {"id": "dish_01", "text": "Et une assiette de plus ! Le public est debout !"},
    {"id": "dish_02", "text": "Service impeccable ! Le chef enchaîne comme un métronome !"}
  ],
  "sabotage_stove_off": [
    {"id": "stove_01", "text": "Le rat éteint la plaque ! Quelle audace, quel culot !"}
  ]
}
```
Catégories : `round_start`, `dish_delivered`, `sabotage_stove_off`, `sabotage_steal`, `sabotage_spill`, `rat_hit`, `rat_appeared`, `recovery`, `time_30`, `time_10`, `filler`, `round_end`, et pour l'écran de fin (lus en Phase 6) `result_0_star` à `result_3_stars`.
**15 à 20 répliques par catégorie** (sauf `time_30`, `time_10` et `round_start` : 5 à 8 suffisent).

Si le nom du rat est généré (Phase 6), les répliques peuvent contenir `{rat}`, remplacé au moment de l'affichage. **Attention** : dans ce cas, pas d'audio pré-généré possible pour ces répliques (le nom change à chaque partie). Garder donc la majorité des répliques **sans** `{rat}`.

### 6.2 Générer la banque (hors jeu, une fois)
1. `tools/generate_bank.py` : appelle Gemini avec le prompt système ci-dessus et demande N répliques par catégorie, en **sortie JSON structurée**.
2. **Relecture humaine obligatoire** : supprimer les répliques ratées, répétitives, trop longues ou limites. C'est ce qui sera entendu devant le jury.
3. `tools/generate_voice.py` : pour chaque réplique, appelle la TTS (Gradium) et enregistre `assets/audio/voice/<id>.ogg`, par exemple en convertissant avec `ffmpeg -i in.mp3 -c:a libvorbis -q:a 4 out.ogg`.
4. Committer le JSON **et** les `.ogg` (vérifier que le poids total reste raisonnable, **< 5 Mo** ; sinon baisser la qualité ou le nombre de répliques).

## 7. Tester sans le rat ni la Phase 4
Ajouter un **mode debug** dans `Commentator`, uniquement dans l'éditeur (`OS.is_debug_build()`) : touches <kbd>F1</kbd> à <kbd>F6</kbd> qui appellent `GameState.log_event(...)` avec de faux événements (`sabotage_stove_off`, `rat_hit`, `dish_delivered`, `timer_milestone`…). Tester ainsi le regroupement, les priorités et l'interruption.

## 8. Découpage en tâches
1. [ ] Écrire la banque (génération + relecture) → `data/commentary_bank.json`.
2. [ ] Autoload `Commentator` en mode **hors ligne** : classement, regroupement, file, anti-répétition, bulle (texte seul).
3. [ ] Bus audio + lecture des `.ogg` pré-générés (`tools/generate_voice.py`).
4. [ ] Serveur relais : `/health`, `/comment`, `/tts`, CORS, délais, `.env.example`. Le déployer.
5. [ ] Mode direct dans `Commentator` (activé si `proxy_url` est renseignée) avec abandon après délai.
6. [ ] Brancher sur `round_started` (Phase 4) et les vrais événements du rat (Phase 3).
7. [ ] Tests : hors ligne, en direct, réseau lent (simuler un délai dans le relais), sur téléphone.
8. [ ] Documentation : ARCHITECTURE (autoload `Commentator`, bus audio), README (comment configurer le relais), cases de cette fiche.

## 9. Pièges connus
- **Pas de son sur téléphone** : l'audio n'est pas encore débloqué (Phase 4), ou le téléphone est en mode silencieux (iPhone : le bouton latéral coupe aussi le son du navigateur).
- **Erreur CORS** dans la console du navigateur : l'origine exacte n'est pas autorisée dans le relais.
- **Réponse en retard qui parle d'un événement passé** : toujours comparer le moment de la demande avec le moment de la réception, et jeter la réponse si elle est trop vieille.
- **Voix qui se chevauchent** : un seul `AudioStreamPlayer` pour la voix, jamais un nouveau par réplique.
- **Clé d'API poussée par erreur** : la révoquer **immédiatement** (supprimer le commit ne suffit pas, elle est dans l'historique).

## 10. Hors périmètre
- Juge de plat, personnalité du rat, récap' final → Phase 6 (même relais, mêmes outils).
