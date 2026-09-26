---
name: phase-workflow
description: À utiliser dès qu'on commence, reprend ou termine une phase de Ratoir (docs/phases/PHASE-N-*.md) ou toute tâche qui modifie le dépôt. Impose une branche dédiée, partie de staging et poussée sur le remote pour relecture en Pull Request vers staging ; ne jamais pousser sur main ni sur staging.
---

# Workflow git d'une phase Ratoir

## Modèle de branches

```
phase-N/<sujet> ──PR──▶ staging ──PR──▶ main
```

- `main` : version stable, celle qu'on publie. Ne reçoit que des PR venant de `staging`.
- `staging` : branche d'intégration. Toutes les branches de feature **partent de `staging`** et y reviennent par PR.
- Branches de feature : une par tâche, créées depuis `staging`.

## Règle absolue

**Ne jamais pousser directement sur `main` ni sur `staging`.** Ni `git push origin main`/`staging`, ni `git push` depuis ces branches, ni `--force` dessus. Tout passe par une branche + une Pull Request relue par quelqu'un d'autre.

Si tu te retrouves avec des commits sur `main` ou `staging` en local : crée la branche à partir de là (`git switch -c <branche>`), puis remets la branche d'origine à `origin/<branche>` **seulement après** avoir vérifié que la nouvelle branche contient bien les commits.

## Démarrer une phase

1. Partir d'un `staging` à jour :
   ```bash
   git switch staging
   git pull --rebase origin staging
   ```
2. Créer la branche, nommée d'après la phase (voir [CONTRIBUTING](../../../docs/CONTRIBUTING.md#2-branches-et-commits)) :
   ```bash
   git switch -c phase-<N>/<sujet-court>   # ex. phase-3/rat-ia, phase-4/ecran-fin
   ```
   Pour une tâche hors phase : `docs/<sujet>`, `fix/<sujet>`, `chore/<sujet>`.
3. Pousser la branche tout de suite pour qu'elle existe sur le remote :
   ```bash
   git push -u origin phase-<N>/<sujet-court>
   ```

## Pendant la phase

- Petits commits fréquents, messages en français à l'impératif (`Ajoute le bouton TAPER`).
- Avant chaque push : `git pull --rebase origin staging`, puis vérifier que le projet se lance sans erreur.
- `git push` (la branche suit déjà `origin/<branche>`).
- Mettre à jour la doc dans la même branche : fiche `docs/phases/PHASE-N-*.md` (cases cochées), tableau d'avancement du `README.md`, `ARCHITECTURE.md` / `CONCEPT.md` si un contrat ou une règle change.

## Terminer la phase

1. Vérifier la [définition de « terminé »](../../../docs/CONTRIBUTING.md#5-définition-de-terminé-pour-une-tâche).
2. Pousser le dernier état de la branche.
3. Ouvrir la PR vers `staging` :
   ```bash
   gh pr create --base staging --title "Phase N : <résumé>" --body "<ce qui change, comment tester>"
   ```
4. **Ne pas fusionner soi-même** : la PR attend la relecture d'un coéquipier.

## Passer staging en production

Quand `staging` est stable (se lance, testé sur téléphone), ouvrir une PR `staging` → `main` :
```bash
gh pr create --base main --head staging --title "Release : <résumé>"
```
Elle est relue et fusionnée comme les autres, jamais poussée directement.

## Vérification avant tout push

```bash
git branch --show-current   # ne doit JAMAIS afficher "main" ni "staging"
```
