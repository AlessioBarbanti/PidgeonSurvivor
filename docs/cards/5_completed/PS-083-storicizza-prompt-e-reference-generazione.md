---
id: PS-083
titolo: Storicizzare prompt e reference di generazione
tipo: chore
area: arte
stato: COMPLETATO
priorita: bassa
dipende_da: []
origine: conversazione del proprietario 2026-08-28
creato: 2026-09-02
aggiornato: 2026-09-04
---

# PS-083 — Storicizzare prompt e reference di generazione

## Contesto

I prompt ImageGen e le reference ricevute in conversazione erano distribuiti
fra messaggi, manifest sintetici e master HD. Un riuso futuro richiede un
archivio testuale puntuale e un posto protetto per le reference visive
riservate, senza farle entrare nel runtime.

## Comportamento atteso

Ogni generazione storicizzata rimanda al prompt archiviato, alla reference
locale o alla sua assenza dichiarata, e al master prodotto. I materiali
sorgente riservati restano fuori da import ed export.

## Criteri di accettazione

- [x] I prompt finali delle tre icone B41 sono archiviati integralmente.
- [x] La reference di stile B41 locale e il suo hash sono registrati.
- [x] Il registro del cast elenca le reference visive riservate e dichiara
      onestamente quali file non sono disponibili nel checkout.
- [x] I file sorgente riservati sono archiviati con hash fuori da import ed
      export.
- [x] I prompt riutilizzabili per Aleo e Magno sono archiviati in forma
      ripulita; gli altri prompt del cast sono separati e marcati come
      ricostruzioni probabili.

## Ambito

- `docs/archive/generation-prompts-and-references.md`.
- `docs/characters/references/`, solo come archivio privato ignorato da Godot
  e fuori dai preset export.
- Manifest del cast e delle icone upgrade, solo per i link all'archivio.
- Nessun asset runtime, dato gameplay, scena o export viene modificato finché
  le reference originali non vengono riallegate.

## Verifica

- Smoke: non applicabile — sola documentazione e provenienza.
- Verifica: link locali, percorsi e hash della reference B41 esistenti.

## Gate manuali

- [x] Controllo del proprietario richiesto: il registro deve essere abbastanza
      completo da permettere un futuro riuso senza inventare fonti mancanti.

## Decisioni

- **2026-09-02 — Nessuna ricostruzione fittizia.** I prompt non disponibili in
  forma integrale e i byte dei materiali sorgente non vengono inventati né
  rigenerati; il registro separa ciò che è verificabile da ciò che manca.
- **2026-09-02 — Le reference riservate restano fuori dal runtime.** I
  quattordici file sorgente sono normalizzati in
  `references/<id>/source-XX.png`, ignorati da Godot ed esclusi dai tre preset;
  i loro hash vivono nel registro storico.
- **2026-09-02 — Prompt ripuliti e ricostruzioni non sono equivalenti.** Per
  Aleo e Magno il registro conserva versioni riutilizzabili ripulite; per gli
  altri sei personaggi conserva prompt ricostruiti dalle fonti disponibili e
  li etichetta esplicitamente come non originali.

## Documenti sincronizzati

- [x] `assets/art/characters/ASSET-MANIFEST.md`.
- [x] `assets/art/icons/upgrades/ASSET-MANIFEST.md`.
- [x] `export_presets.cfg`.

## Note

Le reference risultano archiviate; resta soltanto la verifica finale del
proprietario sul registro e sulla convenzione dei nomi.

**2026-09-02 — Nota di percorso, non riapertura.** Il percorso citato in
questa card (`assets/art/characters/references/`) è stato spostato sotto
`docs/characters/references/` da
[PS-084](./PS-084-direzione-visuale-per-personaggio-e-reference-cast.md),
senza alterare i byte dei file sorgente. Riferimento
aggiornato: `docs/archive/generation-prompts-and-references.md` e
`assets/art/characters/ASSET-MANIFEST.md`.
