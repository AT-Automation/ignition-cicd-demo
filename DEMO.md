# Draaiboek — Git & CI/CD voor Ignition

Voer dit uit vanuit de root van de repository in een Git Bash/WSL-terminal. De trainer werkt op `main`; vervang `<github-user>` en `<repo>` alleen wanneer nodig. Maak vooraf `.env`, start Compose en configureer de `production` Environment en self-hosted runner volgens de README.

## 1. VS Code en de file-based view

Open de repository met `code .`. Toon Explorer, `projects/demo-project/project.json` en daarna `projects/demo-project/com.inductiveautomation.perspective/views/demo/view.json`. Wijs `LabelMachine`, `LabelStatus` en hun losse `props.text`-waarden aan. Toon Source Control en open de geïntegreerde terminal. Leg uit: Ignition 8.3 bewaart projectresources als gewone files; deze kleine view is dus goed te diffen en reviewen.

Open de lokale pagina: `http://localhost:8088/data/perspective/client/demo-project/`. Als de view na een eerste start niet verschijnt, log in op de Gateway en kies **Platform → System → Projects → Scan File System**.

## 2. Git basics: werkmap → staging → lokale commit → remote

Maak een kleine, tijdelijke docs-wijziging, bijvoorbeeld één regel onderaan deze sectie, en toon elke tussenstaat:

```bash
git status
git diff
git add DEMO.md
git status
git commit -m "docs: add training note"
git log --oneline --graph --decorate -5
git push origin main
```

Leg bij `git status` uit: vóór `git add` staat de wijziging alleen in de werkmap; daarna in staging; `git commit` schrijft alleen lokaal; `git push` maakt de commit op GitHub zichtbaar. Verwijder de tijdelijke regel later via een eigen PR als de demo-repository schoon moet blijven.

## 3. Feature branch en Pull Request

```bash
git switch main
git pull --ff-only origin main
git switch -c feature/change-machine-label
```

Wijzig in `view.json` uitsluitend de waarde op de regel direct onder `"name": "LabelMachine"`, van `Machine: Demo` naar `Machine: Menglijn 01`. Doe vervolgens:

```bash
git diff -- projects/demo-project/com.inductiveautomation.perspective/views/demo/view.json
git add projects/demo-project/com.inductiveautomation.perspective/views/demo/view.json
git commit -m "feat: show Menglijn 01"
git push -u origin feature/change-machine-label
```

Open op GitHub de aangeboden **Compare & pull request**-link (of `gh pr create --base main --head feature/change-machine-label --fill`). Toon diff, commit, review en de groene **JSON validation and Perspective lint** check. Merge pas als groen; de merge naar `main` start CD.

## 4. Twee ontwikkelaars, één view, geen conflict

Start beide branches vanaf exact dezelfde `main`-commit. Gebruik twee clones of twee terminals/worktrees zodat de branches echt parallel blijven.

```bash
git switch main
git pull --ff-only origin main
git switch -c feature/change-machine-label-again
# wijzig alleen LabelMachine props.text naar: Machine: Menglijn 02
git add projects/demo-project/com.inductiveautomation.perspective/views/demo/view.json
git commit -m "feat: rename machine"
git push -u origin feature/change-machine-label-again

git switch main
git switch -c feature/change-status-label
# wijzig alleen LabelStatus props.text naar: Status: In bedrijf
git add projects/demo-project/com.inductiveautomation.perspective/views/demo/view.json
git commit -m "feat: show running status"
git push -u origin feature/change-status-label
```

Maak voor beide branches een PR naar `main`, merge de eerste, en update/merge de tweede. De twee `text`-regels zijn gescheiden, dus Git combineert ze automatisch. Dit toont dat dezelfde view bewerken niet automatisch een conflict betekent. Wijzig nooit `resource.json` in deze oefening.

## 5. Eén klein, voorspelbaar merge conflict

Begin opnieuw vanaf dezelfde `main`-commit. In branch A wijzig je alleen `LabelStatus` naar `Status: Productie`; in branch B wijzig je dezelfde `LabelStatus`-waarde naar `Status: Storing`.

```bash
git switch main
git pull --ff-only origin main
git switch -c feature/status-production
# wijzig alleen LabelStatus props.text naar: Status: Productie
git add projects/demo-project/com.inductiveautomation.perspective/views/demo/view.json
git commit -m "feat: set production status"
git push -u origin feature/status-production

git switch main
git switch -c feature/status-incident
# wijzig alleen LabelStatus props.text naar: Status: Storing
git add projects/demo-project/com.inductiveautomation.perspective/views/demo/view.json
git commit -m "feat: set incident status"
git push -u origin feature/status-incident
```

Maak en merge eerst de PR `feature/status-production`. Werk daarna de andere branch bij:

```bash
git fetch origin
git switch feature/status-incident
git merge origin/main
```

Verwacht één conflictblok rond `"text": "Status: ..."`; `LabelMachine` blijft ongewijzigd. Open `view.json` in VS Code. Toon **Current Change** (`Status: Storing`) en **Incoming Change** (`Status: Productie`), kies of schrijf de gewenste eindwaarde, verwijder markers via de merge editor, sla op en vervolg:

```bash
git add projects/demo-project/com.inductiveautomation.perspective/views/demo/view.json
git commit -m "merge: resolve status text"
git push
```

De bestaande PR krijgt de push en CI opnieuw. In GitHub wordt hij weer mergeable.

## 6. CI bewust rood, dan groen

Open een nieuwe PR-branch en verander uitsluitend de componentnaam `LabelMachine` in `machine`. Commit en push. `NamePatternRule` in `rule_config.json` vereist PascalCase en maakt de CI-check rood. Open de Actions-log en toon de lintmelding.

Herstel `machine` precies naar `LabelMachine`, commit en push opnieuw. Dezelfde PR wordt groen. Het verschil in één zin: parsevalidatie controleert of JSON leesbaar is; lint controleert waarschijnlijke bugs/conventies; style checks gaan over consistente vormgeving, niet over JSON-syntax.

## 7. Merge, CD en productie verifiëren

Merge de groene PR naar `main`. Open **Actions → Deploy production**. De log toont: checkout, prerequisites, JSON-validatie, `docker cp`, project-scan en health check. Open vervolgens:

```text
http://localhost:8090/data/perspective/client/demo-project/
```

Ververs de pagina en toon de nieuwe labeltekst. Een restart is na de eerste commissioning niet nodig: de workflow roept de officiële project scan API aan.

## Herstelpunten

- CI fout vóór de PR? Run `bash scripts/validate.sh` lokaal.
- Production workflow zegt dat de container ontbreekt? Start `docker compose up -d` op de runner-host.
- Scan geeft 401/403? Maak/controleer de API key in de production Gateway en update uitsluitend Environment secret `IGNITION_API_KEY`.
- Gateway nog niet RUNNING? Wacht tot `docker compose ps` healthy meldt; de eerste image-pull/start kan enkele minuten duren.
