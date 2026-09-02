---
id: PS-083
titolo: Storicizzare prompt e reference di generazione
tipo: chore
area: arte
stato: IN VERIFICA
priorita: bassa
dipende_da: []
origine: conversazione del proprietario 2026-08-28
creato: 2026-09-02
aggiornato: 2026-09-02
---

# PS-083 — Storicizzare prompt e reference di generazione

## Contesto

I prompt ImageGen e le reference ricevute in conversazione erano distribuiti
fra messaggi, manifest sintetici e master HD. Un riuso futuro richiede un
archivio testuale puntuale e un posto protetto per le foto autorizzate, senza
farle entrare nel runtime.

## Comportamento atteso

Ogni generazione storicizzata rimanda al prompt effettivamente usato, alla
reference locale o alla sua assenza dichiarata, e al master prodotto. Le foto
personali originali restano archiviate solo dopo che il proprietario ne fornisce
nuovamente i file.

## Criteri di accettazione

- [x] I prompt finali delle tre icone B41 sono archiviati integralmente.
- [x] La reference di stile B41 locale e il suo hash sono registrati.
- [x] Il registro del cast elenca le reference fotografiche ricevute e dichiara
      onestamente quali file non sono disponibili nel checkout.
- [x] Le foto originali autorizzate sono archiviate con hash fuori da import ed
      export.
- [x] I prompt originali recuperati per Aleo e Magno sono archiviati
      integralmente; gli altri prompt del cast sono separati e marcati come
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
  forma integrale e i byte delle foto non vengono inventati né rigenerati; il
  registro separa ciò che è verificabile da ciò che richiede una nuova
  consegna del proprietario.
- **2026-09-02 — Le reference personali restano fuori dal runtime.** Le
  quattordici foto consegnate sono normalizzate in
  `references/<id>/source-XX.png`, ignorate da Godot ed escluse dai tre preset;
  i loro hash vivono nel registro storico.
- **2026-09-02 — Originali e ricostruzioni non sono equivalenti.** I testi
  completi recuperati da `img_char_prompts.md` per Aleo e Magno sono conservati
  verbatim; per gli altri sei personaggi il registro conserva prompt di riuso
  ricostruiti dalle fonti allora disponibili e li etichetta esplicitamente come
  non originali.

## Documenti sincronizzati

- [x] `assets/art/characters/ASSET-MANIFEST.md`.
- [x] `assets/art/icons/upgrades/ASSET-MANIFEST.md`.
- [x] `export_presets.cfg`.

## Note

Le foto risultano archiviate; resta soltanto la verifica finale del proprietario
sul registro e sulla convenzione dei nomi.

**2026-09-02 — Nota di percorso, non riapertura.** Il percorso citato in
questa card (`assets/art/characters/references/`) è stato spostato sotto
`docs/characters/references/` da
[PS-084](../3_in_sprint/PS-084-direzione-visuale-per-personaggio-e-reference-cast.md),
senza alterare i byte delle foto né le decisioni qui registrate. Riferimento
aggiornato: `docs/archive/generation-prompts-and-references.md` e
`assets/art/characters/ASSET-MANIFEST.md`.
