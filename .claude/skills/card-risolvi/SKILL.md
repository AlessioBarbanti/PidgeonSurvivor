---
name: card-risolvi
description: Risolvi una card della board di Pidgeon Survivor in docs/cards/ — implementazione, smoke, verifica e aggiornamento dello stato. Usala per "risolvi PS-007", "prendi la prossima card", "chiudi la card del joystick" o quando si lavora su un file docs/cards/PS-*.md.
---

# Risolvi una card

Stessa disciplina della skill `milestone`, in scala ridotta. La card è il
contratto: non allargarla e non reinterpretarla.

## 1. Prendi la card

1. `git status --short`: preserva ogni modifica preesistente.
2. Apri la card indicata. Se ti è stato chiesto "la prossima", scegli in
   [docs/cards/README.md](../../../docs/cards/README.md) la card `PRONTO` con
   priorità più alta e dipendenze chiuse.
3. Se lo stato è `DA DEFINIRE` o `BLOCCATO`, **fermati**: riporta la domanda o la
   dipendenza registrata nella card e non implementare.
4. Se la card punta un `milestone` B-series, leggi quella sezione del
   [development plan](../../../docs/development-plan.md): il contratto della
   slice ha la precedenza sulla card.
5. Porta lo stato a `IN CORSO` e aggiorna `aggiornato`.

## 2. Implementa

- Solo ciò che i criteri di accettazione richiedono. Se durante il lavoro emerge
  un problema adiacente, **apri una nuova card** (skill `card-crea`) invece di
  allargare questa.
- GDScript tipizzato, scene-local, signal-driven; contratti di
  [CLAUDE.md](../../../CLAUDE.md) intatti.
- Se la card tocca asset, applica la skill `asset-pipeline`.
- Se serve una prova nuova, applica la skill `smoke-test`.
- Se un criterio si rivela impossibile o sbagliato, non riscriverlo di nascosto:
  segnalalo, proponi la formulazione corretta e procedi sul resto.

## 3. Verifica

```powershell
.\tools\run-milestone-checks.ps1 -Milestone B23 -Profile Focused
.\tools\run-milestone-checks.ps1 -Milestone B23 -Profile Relevant
```

Usa l'ID del milestone collegato; se la card non ne ha uno, passa
`-FocusedSmoke` con il percorso dello smoke pertinente. Exit code `0` non basta:
controlla i log per `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL`,
`CONTRACT_FAIL`. Per i gate di piattaforma applica `gate-piattaforme`.

## 4. Chiudi

1. Spunta i criteri di accettazione **realmente** verificati e lascia non
   spuntati gli altri, con una riga che dice perché.
2. Aggiorna lo stato:
   - `IN VERIFICA` se gli automatici sono verdi ma restano gate manuali,
     percettivi o su device;
   - `VERIFICATO` se tutti i gate pertinenti sono chiusi ma manca il commit;
   - `COMPLETATO` solo dopo il commit dedicato.
3. Scrivi in Note le decisioni prese, le alternative scartate e i comandi/marker
   esatti usati come evidenza.
4. Aggiorna la riga nella tabella di
   [docs/cards/README.md](../../../docs/cards/README.md).
5. Se la modifica cambia un contratto di prodotto, una decisione o
   un'approvazione, propagala rispettivamente in `prd.md`, `decision-log.md` o
   `content-approvals.md`.
6. Commit solo su richiesta: `feat(PS-007): ...` o `fix(PS-007): ...`, in
   italiano, focalizzato. Nessun push se non richiesto.
7. Riporta: cosa è cambiato, criteri chiusi e criteri lasciati aperti, risultati
   Windows/Android separati, gate ancora aperti.
