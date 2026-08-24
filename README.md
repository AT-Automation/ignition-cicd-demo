# Ignition Git & CI/CD demo

Een zeer kleine trainingsrepository voor deze flow:

`VS Code → Git → feature/* → pull request → CI → merge naar main → production Gateway`.

Er is één Ignition 8.3 Perspective-project, één view en twee labels. `main` is de enige long-lived branch; alle werk gaat via short-lived `feature/*` branches en een PR.

## Vereisten

- Docker Desktop met Docker Compose v2 en ten minste circa 3 GB vrij RAM
- Git en VS Code
- Bash (Git Bash of WSL) voor `scripts/*.sh`
- Een GitHub-repository; GitHub CLI (`gh`) is optioneel

De officiële Ignition-image is vastgezet op `inductiveautomation/ignition:8.3.8`. Maak geen productie-credentials onderdeel van Git.

## Starten en stoppen

```bash
cp .env.example .env
# wijzig ten minste GATEWAY_ADMIN_PASSWORD in .env
docker compose up -d
docker compose ps
```

De lokale Gateway is [http://localhost:8088](http://localhost:8088); de production-demo is [http://localhost:8090](http://localhost:8090). De Perspective-pagina is na een scan bereikbaar op:

```text
http://localhost:8088/data/perspective/client/demo-project/
http://localhost:8090/data/perspective/client/demo-project/
```

Login met `GATEWAY_ADMIN_USERNAME` en `GATEWAY_ADMIN_PASSWORD` uit `.env`. Bij eerste start kan Ignition ongeveer twee minuten nodig hebben. Stoppen: `docker compose down`. Voeg alleen als een volledige, lokale reset gewenst is `--volumes` toe; dat verwijdert Gateway-state.

De lokale Gateway bind-mount `./projects`, zodat bestanden direct op disk staan. Gebruik in de Gateway-webinterface **Platform → System → Projects → Scan File System** na een lokale edit, of maak een API key aan en run:

```bash
set -a; . ./.env; set +a
bash scripts/deploy.sh
```

Dat laatste deployt bewust naar de production-demo, niet naar local.

## CI en CD

`ci.yml` draait op iedere PR naar `main` met `ubuntu-latest`: JSON/projectvalidatie en `ign-lint==0.6.1` op elke Perspective `view.json`.

`deploy-production.yml` draait op een push naar `main` die project/deploy-bestanden wijzigt. Het gebruikt expres een self-hosted runner met label `ignition-demo`: alleen die kan de Docker-container op de trainingsmachine bereiken. De workflow kopieert uitsluitend `demo-project`, roept de project-scan API aan en controleert `/StatusPing`.

Stel in GitHub **Settings → Environments → production** in:

| Type | Naam | Waarde |
| --- | --- | --- |
| Secret | `IGNITION_API_KEY` | API key van production Gateway (Gateway → Config → Security → API Keys) |
| Variable | `IGNITION_CONTAINER` | optioneel; standaard `ignition-demo-production` |
| Variable | `IGNITION_URL` | optioneel; standaard `http://localhost:8090` voor een host-runner |

Registreer daarnaast op de Docker-host een self-hosted GitHub Actions runner met labels `self-hosted,ignition-demo`; de runnergebruiker moet `docker ps` kunnen uitvoeren. Gebruik de registratie-opdracht die GitHub onder **Settings → Actions → Runners → New self-hosted runner** voor deze repository toont. Een container-runner op hetzelfde Compose-netwerk gebruikt als URL `http://ignition-production:8088`; voor de eenvoudige host-runner is de standaard juist `http://localhost:8090`.

## Resource-hygiëne

`resource.json` is een Ignition-manifest en niet het lesmateriaal. Bewerk in de demo alleen de twee afzonderlijke `props.text`-regels in `view.json`. Gebruik geen Designer-save tussen de twee Git-wijzigingen: Ignition kan manifest-attributen opnieuw stempelen, wat afleidende metadata-diffs oplevert. Als dat toch gebeurt, herstel alleen het manifest naar de branchversie met `git restore projects/demo-project/.../resource.json` vóór je commit; behoud je beoogde `view.json`-wijziging.

Zie [DEMO.md](DEMO.md) voor het letterlijk uitvoerbare draaiboek.
