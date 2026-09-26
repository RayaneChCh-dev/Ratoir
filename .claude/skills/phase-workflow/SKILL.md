---
name: phase-workflow
description: À utiliser dès qu'on commence, reprend ou termine une phase de Ratoir (docs/phases/PHASE-N-*.md) ou toute tâche qui modifie le dépôt. Impose une branche dédiée poussée sur le remote pour relecture en Pull Request ; ne jamais pousser sur main.
---

# Workflow git d'une phase Ratoir

## Règle absolue

**Ne jamais pousser sur `main`.** Ni `git push origin main`, ni `git push` depuis `main`, ni `--force` sur `main`. Tout passe par une branche + une Pull Request relue par quelqu'un d'autre.

Si tu te retrouves avec des commits sur `main` en local : crée la branche à partir de là (`git switch -c <branche>`), puis remets `main` à `origin/main` **seulement après** avoir vérifié que la branche contient bien les commits.

## Démarrer une phase

1. Partir d'un `main` à jour :
   ```bash
   git switch main
   git pull --rebase origin main
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
- Avant chaque push : `git pull --rebase origin main`, puis vérifier que le projet se lance sans erreur.
- `git push` (la branche suit déjà `origin/<branche>`).
- Mettre à jour la doc dans la même branche : fiche `docs/phases/PHASE-N-*.md` (cases cochées), tableau d'avancement du `README.md`, `ARCHITECTURE.md` / `CONCEPT.md` si un contrat ou une règle change.

## Terminer la phase

1. Vérifier la [définition de « terminé »](../../../docs/CONTRIBUTING.md#5-définition-de-terminé-pour-une-tâche).
2. Pousser le dernier état de la branche.
3. Ouvrir la PR vers `main` :
   ```bash
   gh pr create --base main --title "Phase N : <résumé>" --body "<ce qui change, comment tester>"
   ```
4. **Ne pas fusionner soi-même** : la PR attend la relecture d'un coéquipier.

## Vérification avant tout push

```bash
git branch --show-current   # ne doit JAMAIS afficher "main"
```
