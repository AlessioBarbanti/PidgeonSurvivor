---
id: PS-089
titolo: Elimina le sovrapposizioni fra il tema carne delle Specialità e il catalogo powerup ordinario
tipo: chore
area: arte
priorita: media
stato: PRONTO
dipende_da: []
origine: conversazione del proprietario 2026-09-04
creato: 2026-09-04
aggiornato: 2026-09-04
---

# PS-089 — Elimina le sovrapposizioni fra il tema carne delle Specialità e il catalogo powerup ordinario

## Contesto

Il proprietario ha confermato la regola che regge
[PS-078](./PS-078-tematizza-catalogo-specialita-barb.md): le otto Specialità
di Barb sono pezzi di carne alla griglia, il catalogo powerup ordinario resta
a tema grigliatore ma **non** carne — utensili, condimenti, pirofile, brace.
Quella regola è nuova e il catalogo ordinario è stato tematizzato prima che
esistesse: almeno un titolo già in gioco la infrange. `ability_cooldown`
(`data/upgrades/ability_cooldown.tres`) si chiama **`Bis di Salsiccia`**, con
icona `bis_di_salsiccia.png` — una salsiccia è un pezzo di carne, esattamente
il soggetto ora riservato alle Specialità. Senza un controllo esplicito, la
distinzione fra i due registri che rende leggibile "il pezzo speciale di
Barb" (PS-078) rischia di restare vera solo sulla carta.

## Comportamento atteso

Nessun titolo del catalogo powerup ordinario nomina un taglio, un pezzo o un
piatto di carne alla griglia. Ogni sovrapposizione trovata viene rinominata
restando dentro il registro già stabilito (utensili, condimenti, pirofile,
brace, cottura) invece di scivolare nel registro ora riservato alle
Specialità.

## Criteri di accettazione

- [ ] Ogni `title` in `data/upgrades/*.tres` **fuori** da
      `data/upgrades/specialities/` è stato controllato contro la regola "non
      è un pezzo/taglio/piatto di carne"; ogni violazione trovata è stata
      rinominata.
- [ ] `ability_cooldown` non si chiama più `Bis di Salsiccia` (o qualunque
      variante che nomini un salume/taglio di carne); il nuovo titolo resta
      leggibile come riduzione del cooldown dell'abilità attiva.
- [ ] `effect_id`, `effect_parameters`, `weight`, `max_rank`, `tags`
      meccanici di ogni carta toccata restano bit-per-bit identici: la card
      cambia solo `title`/`description`/`effect_summary`, mai gameplay.
- [ ] `docs/powerup-catalog.md` riflette i nuovi titoli ovunque il vecchio
      nome compariva.
- [ ] Nessuna Specialità di Barb (`data/upgrades/specialities/*.tres`) viene
      toccata da questa card: la loro tematizzazione resta compito esclusivo
      di PS-078.

## Ambito

- `title`, `description`, `effect_summary` dei file in `data/upgrades/*.tres`
  **esclusa** la cartella `specialities/`.
- `docs/powerup-catalog.md`, per allineare i nomi documentati.

Non toccare:

- `data/upgrades/specialities/*.tres` (PS-078);
- `effect_id`, `effect_parameters`, `weight`, `max_rank`, `tags` meccanici di
  qualunque carta;
- icone: se una rinomina lascia un'icona il cui **soggetto raffigurato** è
  ancora un pezzo di carne (caso plausibile per `Bis di Salsiccia`, la cui
  icona ritrae letteralmente una salsiccia), questa card lo dichiara in
  `Decisioni` e apre una card `tipo: art` dedicata invece di generare l'icona
  qui: generare arte non richiesta esplicitamente non è compito di questa
  card.

## Verifica

- Smoke: `tests/unit/test_ps089_ordinary_catalog_meat_audit.gd` → marker
  `ORDINARY_CATALOG_MEAT_AUDIT_SMOKE_OK` — verifica che nessun titolo fuori da
  `specialities/` contenga una delle parole vietate (salsiccia, bistecca,
  costata, spiedino, filetto, ecc. — lista da fissare in fase di
  implementazione insieme all'elenco definitivo degli otto nomi Specialità di
  PS-078, per evitare falsi negativi) e che `effect_id`/`effect_parameters`
  restino quelli pre-rinomina.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: non richiesto, solo testo
- [ ] Controllo percettivo richiesto: no per il testo; sì solo se questa card
      apre la card `art` per una nuova icona (vedi Ambito)

## Decisioni

- **2026-09-04 — Non è bloccata da PS-078.** La regola che questa card
  applica ("Specialità = carne, ordinario = non carne") è già stata
  confermata dal proprietario in conversazione, non serve attendere che
  PS-078 produca le otto icone definitive per applicarla al catalogo
  ordinario. Ha comunque senso eseguirla vicino a PS-078 per coerenza di
  release, ma non è un prerequisito tecnico.
- **2026-09-04 — Trovata almeno una violazione concreta prima di aprire la
  card.** `Bis di Salsiccia` (`ability_cooldown`) nomina esplicitamente un
  salume. La ricerca completa sulle altre carte resta da fare in fase di
  implementazione, ma questa non è una card speculativa: parte da un caso
  reale già identificato.
- **2026-09-04 — Le icone restano fuori ambito salvo un caso già noto.** Se
  l'audit conferma che l'icona di `Bis di Salsiccia` ritrae una salsiccia,
  serve una card `tipo: art` separata per la nuova icona, delegata
  all'agente Game Art Designer secondo la regola di board — non generata
  dentro questa card.

## Documenti sincronizzati

- [ ] `docs/powerup-catalog.md`: nomi aggiornati ovunque compaia il vecchio
      titolo.

## Note

Nessuna.
