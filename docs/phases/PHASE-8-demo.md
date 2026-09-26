# Phase 8 — Déploiement, tests sur téléphones et démo

| | |
|---|---|
| **Statut** | ⏳ À faire (**le déploiement itch.io peut être testé dès maintenant** avec la version actuelle) |
| **Dépend de** | Toutes les autres phases pour la version finale |
| **Profil** | Toute l'équipe |
| **Estimation** | 1 h (dont 30 min de répétition) |

---

## 1. Objectif

Un jeu **en ligne sur itch.io**, qui marche **sur les téléphones du jury**, et une **démo de 3 minutes** répétée plusieurs fois, qui tourne de bout en bout **même si quelque chose tombe en panne**.

## 2. État exigé (critères d'acceptation)

- [ ] Le jeu est publié sur itch.io et se lance sur **au moins 2 Android et 1 iPhone** différents.
- [ ] La démo a été **répétée 3 fois de suite** sans accroc, chronométrée.
- [ ] Le **plan B** est prêt : vidéo de secours, mode hors ligne vérifié, partage de connexion.
- [ ] Le script de démo ci-dessous est adapté et chacun connaît son rôle.

## 3. Déployer sur itch.io

### Première fois (à faire **dès maintenant**, pour valider la chaîne)
1. `./tools/export_web.sh` → `build/ratoir-web.zip`.
2. itch.io → *Upload new project* :
   - **Title** : Ratoir
   - **Kind of project** : **HTML**
   - **Uploads** : envoyer le zip et cocher **« This file will be played in the browser »**
   - **Embed options** : taille **360 × 640**, cocher **Mobile friendly** (orientation **Portrait**), cocher **Fullscreen button**
   - **SharedArrayBuffer support** : **laisser décoché** (l'export est sans threads)
   - **Visibility** : *Draft* ou *Restricted* (avec mot de passe) tant qu'on n'est pas prêts, puis *Public*
3. Ouvrir la page **sur un téléphone** : le jeu doit se lancer (itch.io est en HTTPS, donc pas d'avertissement de certificat).

### Mises à jour
- Soit **renvoyer le zip** sur la page (supprimer l'ancien fichier).
- Soit utiliser **butler**, l'outil en ligne de commande d'itch.io (`butler login` une fois, puis `butler push build/web <compte>/ratoir:html5`). Pratique pour pousser en 10 secondes pendant le hackathon.

### Relais IA (Phases 5 et 6)
- Le relais doit être **déployé** (pas sur un PC de l'équipe) et son URL renseignée dans le jeu (`proxy_url`).
- Vérifier le **CORS** avec l'origine réelle du jeu sur itch.io : ouvrir la console du navigateur sur la page itch.io et regarder l'en-tête `Origin` des requêtes.

## 4. Tests sur téléphones (checklist)

À faire sur **chaque** téléphone de test :
- [ ] La page charge en moins de 15 s en 4G.
- [ ] Écran titre → toucher → **le son se lance** (mode silencieux de l'iPhone désactivé !).
- [ ] Joystick fluide, bouton TAPER utilisable **en même temps** que le joystick.
- [ ] Le commentateur parle, les sous-titres sont lisibles.
- [ ] Une manche complète, l'écran de fin, le récap' et **Rejouer**.
- [ ] Le bouton plein écran d'itch.io fonctionne et le portrait est respecté.
- [ ] **Mode avion activé après le chargement** : le jeu tourne toujours et commente (banque).

Particularités connues :
- **iPhone (Safari)** : le bouton silencieux coupe le son du navigateur ; le vrai plein écran n'est pas toujours disponible (utiliser *Partager → Sur l'écran d'accueil* pour un rendu proche du plein écran).
- **Android** : Chrome recommandé.

## 5. Script de démo (3 minutes, à adapter)

| Temps | Qui | Quoi |
|------:|-----|------|
| 0:00 | Orateur | **Accroche** : « Vous avez déjà cuisiné avec un rat dans la cuisine ? » + pitch en une phrase ([CONCEPT §1](../CONCEPT.md#1-le-pitch)) |
| 0:15 | Joueur | Écran titre → toucher → **le rat se présente** (nom et réplique générés par IA) |
| 0:25 | Joueur | Première assiette : montrer la boucle **prendre → découper → cuire → livrer**, et le **juge** qui nomme le plat |
| 0:50 | Joueur | Le rat arrive : **laisser volontairement** un sabotage (plaque éteinte) → le commentateur réagit → rallumer |
| 1:15 | Joueur | **Taper le rat** au bon moment → « BONK », le commentateur s'emballe |
| 1:15–2:00 | Orateur | Pendant que ça joue : **explication technique** — Godot, Web mobile, IA **jamais bloquante** (banque + direct), relais sécurisé |
| 2:00 | Joueur | Fin du chrono → **écran de fin** : étoiles + **récap' IA en direct**, lu à voix haute |
| 2:30 | Orateur | Conclusion : ce qui est original (l'IA commente et juge sans piloter le jeu), et ce qu'on ferait ensuite. **« Scannez le QR code pour jouer ! »** |

**Conseils :**
- Le joueur de la démo est **la personne qui joue le mieux**, et il a **répété le parcours**. Il sait provoquer un sabotage et taper le rat au moment voulu.
- Pour régler le rat pendant la démo : prévoir **un profil de rat spécial démo** (sorties plus fréquentes, pour que le sabotage arrive au bon moment).
- **Durée de manche** : si 90 s est trop long pour la démo, prévoir une option cachée (ex. 60 s).
- Afficher un **QR code** vers la page itch.io sur la dernière diapo ou sur un papier : le jury peut jouer tout de suite.

## 6. Projeter l'écran du téléphone
- **Android** : `scrcpy` (gratuit, câble USB) affiche l'écran du téléphone sur le PC relié au projecteur.
- **iPhone** : câble + **QuickTime Player** sur Mac (*Fichier → Nouvel enregistrement vidéo* → choisir l'iPhone), ou recopie AirPlay.
- **Tester le branchement sur place** avant de passer : c'est la panne la plus fréquente.

## 7. Plan B (à préparer **avant**)
| Problème | Solution |
|----------|----------|
| Pas de Wi-Fi ou Wi-Fi saturé | Partage de connexion d'un téléphone ; le jeu tourne hors ligne une fois chargé (banque de répliques) |
| Relais IA en panne | Le jeu bascule seul sur la banque. **Le dire** au jury comme une fonctionnalité : « même sans réseau, le commentateur continue » |
| Le téléphone de démo plante | Un **deuxième téléphone** avec la page déjà ouverte |
| La projection ne marche pas | **Vidéo de secours** d'une partie complète (enregistrée la veille, avec le son), sur le PC et sur une clé USB |
| La démo déraille (bug) | Recharger la page (≈ 10 s) ; l'orateur continue d'expliquer pendant ce temps |

## 8. Découpage en tâches
1. [ ] Premier déploiement itch.io (version actuelle) + test sur 1 téléphone.
2. [ ] Déploiement du relais IA + CORS vérifié depuis itch.io.
3. [ ] Checklist §4 sur 3 téléphones.
4. [ ] Profil de rat « démo » + durée de manche de démo.
5. [ ] Enregistrer la vidéo de secours.
6. [ ] QR code + diapo de fin.
7. [ ] 3 répétitions chronométrées, avec les rôles fixés.
