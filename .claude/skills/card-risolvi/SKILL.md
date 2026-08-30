---
name: card-risolvi
description: Risolvi una card della board di Pidgeon Survivor in docs/cards/ — implementazione, smoke, verifica e aggiornamento dello stato. Usala per "risolvi PS-007", "prendi la prossima card", "chiudi la card del joystick" o quando si lavora su un file docs/cards/PS-*.md.
---

# Risolvi una card

La card è l'unico contratto operativo: non allargarla e non reinterpretarla.

## 1. Prendi la card

1. `git status --short`: preserva ogni modifica preesistente.
2. Apri la card indicata. Se ti è stato chiesto "la prossima", scegli in
   [docs/cards/README.md](../../../docs/cards/README.md) la card `PRONTO` con
   priorità più alta e dipendenze chiuse.
3. Se lo stato è `DA DEFINIRE` o `BLOCCATO`, **fermati**: riporta la domanda o la
   dipendenza registrata nella card e non implementare.
4. Se ricevi un vecchio ID B-series, trova la card tramite `origine`; se non
   esiste, creala prima di implementare.
5. Porta lo stato a `IN CORSO` e aggiorna `aggiornato` e la board.

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
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Focused `
  -FocusedSmoke tests/integration/_grill_defense_mode_smoke.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-010 -Profile Relevant `
  -FocusedSmoke tests/integration/_grill_defense_mode_smoke.gd
```

Il parametro tecnico storico `-Milestone` accetta l'ID card; passa sempre
`-FocusedSmoke` con il percorso pertinente quando esiste. Exit code `0` non basta:
controlla i log per `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL`,
`CONTRACT_FAIL`. Per i gate di piattaforma applica `gate-piattaforme`.

## 4. Chiudi

1. Spunta i criteri di accettazione **realmente** verificati e lascia non
   spuntati gli altri, con una riga che dice perché.
2. Aggiorna lo stato:
   - `IN VERIFICA` se gli automatici sono verdi ma restano gate manuali,
     percettivi o su device;
   - `VERIFICATO` se tutti i gate pertinenti sono chiusi;
   - `COMPLETATO` quando la card è accettata e chiusa; il commit resta separato.
3. Scrivi in `Decisioni` le scelte e motivazioni; in Note alternative, comandi e
   marker esatti usati come evidenza.
4. Aggiorna la riga nella tabella di
   [docs/cards/README.md](../../../docs/cards/README.md).
5. Controlla che metadati, dipendenze e riga della board restino allineati.
6. Se cambia la verità corrente, propaga il solo contratto risultante in
   `prd.md`, `CLAUDE.md`, cataloghi, `content-approvals.md` o `setup.md` e spunta
   `Documenti sincronizzati`. La motivazione resta nella card.
7. Commit solo su richiesta: `feat(PS-007): ...` o `fix(PS-007): ...`, in
   italiano, focalizzato. Nessun push se non richiesto.
8. Riporta: cosa è cambiato, criteri chiusi e criteri lasciati aperti, risultati
   Windows/Android separati, gate ancora aperti.
