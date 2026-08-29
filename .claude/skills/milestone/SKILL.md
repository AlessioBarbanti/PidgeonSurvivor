---
name: milestone
description: Implementa o verifica un milestone della serie B del development plan di Pidgeon Survivor, oppure il primo backlog PRONTO. Usala per "procedi con B23", "prendi il primo PRONTO", "chiudi B18M", verifica di un milestone, gate di regressione/export o raccolta delle evidenze. Non usarla per domande isolate che non richiedono il workflow di milestone.
---

# Milestone B-series

Il development plan e il codice sono autorevoli. Questa skill è procedurale: non
reintrodurre contratti a memoria, leggili.

## 1. Individua la slice

1. `git status --short`: preserva ogni modifica preesistente. Non pulire,
   ripristinare, mettere in stage o committare lavoro non tuo.
2. Leggi [docs/development-plan.md](../../../docs/development-plan.md). Per un
   milestone nominato individua stato, dipendenze, criteri di accettazione,
   strategia di test e gate di piattaforma. Per "il primo PRONTO" scegli il primo
   elemento `PRONTO` con dipendenze chiuse nell'ordine documentato.
3. Vocabolario degli stati, in ordine: `DA DEFINIRE` → `BLOCCATO` → `PRONTO` →
   `IN CORSO` → `IN VERIFICA` (automatici verdi, gate manuali aperti) →
   `VERIFICATO` (tutti i gate chiusi, manca il commit) → `COMPLETATO`.
   Molte slice restano legittimamente in `IN VERIFICA`: non promuoverle senza le
   evidenze richieste.
4. Leggi solo le parti pertinenti di `prd.md`, `decision-log.md`,
   `content-approvals.md`, la nota di verifica esistente, le scene/script
   toccati e lo smoke più vicino.
5. Se la slice è bloccata, fermati e riporta la dipendenza o il gate esatto. Un
   device Android non disponibile **non** blocca implementazione e validazione
   statica dell'APK: lascia aperto solo il gate di runtime fisico.

## 2. Implementa

1. Implementa **solo** la slice scelta, con GDScript tipizzato, scene-local e
   signal-driven. Preserva i contratti descritti in
   [CLAUDE.md](../../../CLAUDE.md), in particolare l'autorità di
   `RunController` su stato, tempo logico, pausa e restart.
2. Toccando welcome, tutorial, selezione, pausa o modali, preserva
   `welcome → (tutorial) → selezione → run → pausa`: `BOOT` resta attivo fino
   alla conferma e Back/annulla chiude solo il modale in cima.
3. Dati in `.tres` con `effect_id` + parametri; la logica resta nei registry.
4. Aggiungi o aggiorna **uno** smoke deterministico
   `tests/integration/_*_smoke.gd` — vedi la skill `smoke-test`.

## 3. Verifica per profili crescenti

```powershell
.\tools\run-milestone-checks.ps1 -Milestone B23 -Profile Focused
.\tools\run-milestone-checks.ps1 -Milestone B23 -Profile Relevant
.\tools\run-milestone-checks.ps1 -Milestone B23 -Profile Full
.\tools\run-milestone-checks.ps1 -Milestone B23 -Profile Release
```

- `Focused` scopre da solo lo smoke il cui marker inizia con l'ID del milestone;
  passa `-FocusedSmoke` o `-ChangedPath` quando la scoperta è ambigua.
- `Relevant` legge le modifiche tracked e untracked e seleziona le regressioni
  da [tools/milestone-test-map.json](../../../tools/milestone-test-map.json).
  Se aggiungi un accoppiamento nuovo fra file e smoke, aggiorna quella mappa.
- Dopo aver aggiunto `class_name` o asset importati, usa `-RefreshEditor`.
- Solo i `PASS` sono in cache, per hash del contenuto. `-NoCache` solo per un
  rerun pulito deliberato; `-PlanOnly` per vedere il piano senza avviare Godot.
- Output `Compact` di default: apri i log completi solo per gli step falliti,
  `-OutputMode Detailed` solo quando serve il dettaglio per step.
- **Exit code `0` non basta**: `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL`,
  `CONTRACT_FAIL` nei log sono fallimenti.
- Se cambi il runner o la mappa, esegui `.\tests\tooling\_milestone_runner_contract.ps1`.

## 4. Gate di piattaforma

Applica la skill `gate-piattaforme`. Riporta Windows runtime, validazione
statica Android e runtime fisico Android come **tre risultati distinti**, e
dichiara esplicitamente i gate che restano aperti.

## 5. Chiudi il checkpoint

1. Aggiorna [docs/development-plan.md](../../../docs/development-plan.md): stato,
   riga di tabella, checklist della slice. Sincronizza i contratti di prodotto in
   `prd.md`, le decisioni in `decision-log.md`, approvazioni e provenienza in
   `content-approvals.md`, le evidenze in `docs/b<ID>-verification.md`.
2. Nuovi asset: riga nel `ASSET-MANIFEST.md` della cartella (skill
   `asset-pipeline`).
3. `git diff --check`, rileggi il diff, verifica che `.godot/`, `exports/` e
   `android/build/` non siano in stage.
4. Committa **solo** se richiesto: messaggio italiano, `feat(B23): ...` o
   `fix(B23): ...`, focalizzato. Nessun push se non richiesto.
5. Riporta: comportamento cambiato, comandi e marker esatti, risultati
   Windows/Android separati, gate manuali aperti, modifiche preesistenti lasciate
   intatte.
