# Synchronisation de la config Claude Code entre machines

Ce dépôt contient la configuration globale de Claude Code (`~/.claude`), synchronisée via GitHub pour être partagée entre plusieurs ordinateurs.

---

## Quitter un ordinateur — sauvegarder ses changements

Avant de changer de machine, pousser la config actuelle vers GitHub :

```powershell
cd ~/.claude
git add -A
git commit -m "chore: sync config from <nom-machine>"
git push origin main
```

---

## Arriver sur un nouvel ordinateur — première fois

Le dossier `~/.claude` existe déjà (Claude Code l'a créé) mais n'est pas encore un dépôt git.

```powershell
cd ~/.claude
git init
git remote add origin https://github.com/sha0lean/.claude.git
git fetch origin
git checkout -f -b main origin/main
```

La config locale est écrasée par celle de GitHub. C'est voulu.

---

## Arriver sur un ordinateur déjà configuré — synchros suivantes

Le dépôt est déjà initialisé, il suffit de tirer les derniers changements :

```powershell
cd ~/.claude
git fetch origin
git reset --hard origin/main
```

> `reset --hard` écrase tout le contenu local non commité. Ne pas l'utiliser si des changements doivent être conservés — faire un `git stash` ou un commit d'abord.

---

## Fichiers ignorés

Les packs de sons (`hooks/peon-ping/packs/`) et autres fichiers volumineux ou locaux sont exclus du dépôt via `.gitignore`. Ils ne se synchronisent pas entre machines.
