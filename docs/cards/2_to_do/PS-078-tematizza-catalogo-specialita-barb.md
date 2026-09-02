---
id: PS-078
titolo: Tematizza il catalogo delle Specialità di Barb come piatti speciali del grigliatore
tipo: art
area: arte
stato: BLOCCATO
priorita: media
dipende_da: [PS-077]
origine:
creato: 2026-09-02
aggiornato: 2026-09-02
---

# PS-078 — Tematizza il catalogo delle Specialità di Barb come piatti speciali del grigliatore

## Contesto

[docs/powerup-catalog.md](../powerup-catalog.md) dichiara già la direzione
visiva comune del catalogo upgrade: **grigliatori** — carne, utensili da
barbecue, pirofile, brace, condimenti, oggetti da cucina, mai piccioni come
soggetto dei powerup positivi. Le carte statistiche ordinarie la seguono già
(`A Tutta Brace!`, `Pinza Lunga`, `Il condimento di Barb`, `Forchettone da
Braciere`, ecc.).

Le Specialità di Barb non hanno mai ricevuto questo trattamento. Nomi e
icone restano un linguaggio generico da upgrade d'arma/abilità, scollegato
dall'identità di Barb come grigliatore che premia il Player con un "pezzo
speciale" dopo ogni Boss: `Gossip`, `Colpo Perforante`, `Raffica Doppia`,
`Esplosione Finale`, e — dopo
[PS-077](./PS-077-espandi-pool-specialita-barb.md) — anche `L'Ansia`,
`Birre di classe di Lollo`, `Ritardo Cronico`, `Non Ho Tempo Per Questo`.
Le icone attuali di queste ultime quattro (`anxiety.png`, `beer.png`,
`chronic_delay.png`, `no_time.png`) non appartengono al linguaggio visivo
grigliatore già stabilito per il resto del catalogo.

## Comportamento atteso

Ognuna delle otto Specialità si presenta come un pezzo/piatto speciale del
menù di Barb: nome, descrizione e icona coerenti con l'identità grigliatore
già stabilita per il resto del catalogo, senza alterare l'effetto meccanico
che rappresentano.

## Criteri di accettazione

- [ ] Ognuna delle otto Specialità ha un nome tematizzato attorno
      all'identità di pezzo/piatto speciale di Barb (grigliata, carne,
      brace, condimenti, utensili), mantenendo leggibile a colpo d'occhio
      l'effetto rappresentato.
- [ ] Ogni Specialità ha una nuova icona coerente con la direzione visiva
      dichiarata in `docs/powerup-catalog.md` (nessun piccione come
      soggetto principale, stile pixel-art già stabilito nel resto del
      catalogo).
- [ ] `effect_id`, `effect_parameters`, `weight`, `max_rank` e ogni altro
      dato meccanico restano bit-per-bit identici: la card cambia solo
      identità (`title`, `description`, `effect_summary`, `icon`), mai
      gameplay.
- [ ] Le otto Specialità restano distinguibili fra loro e dagli upgrade
      statistici ordinari già tematizzati, senza sovrapposizioni semantiche
      (stesso principio già dichiarato per le due pirofile in
      `powerup-catalog.md`).
- [ ] Le nuove icone hanno una riga nell'`ASSET-MANIFEST.md` pertinente con
      origine, autore/licenza, trasformazioni e hash SHA-256.
- [ ] `BarbRewardOverlay` (PS-036) mostra correttamente i nuovi nomi e le
      nuove icone senza modifiche al proprio layout o alla propria logica.

## Ambito

- `data/upgrades/specialities/*.tres` (le otto definizioni: `title`,
  `description`, `effect_summary`, `icon`).
- `assets/art/icons/upgrades/` per le nuove icone, con relativo
  `ASSET-MANIFEST.md`.

Non toccare:

- `effect_id`, `effect_parameters`, `weight`, `max_rank`, `tags` meccanici;
- layout e logica di `BarbRewardOverlay` (contratto PS-036);
- `UpgradeService`, `UpgradeRegistry` e la logica di sblocco
  (contratti PS-012/PS-077);
- il catalogo upgrade ordinario: `docs/powerup-catalog.md` resta la fonte
  per quel catalogo e non viene duplicato qui.

## Verifica

- Smoke: `tests/unit/test_ps078_barb_speciality_theming.gd` → marker
  `BARB_SPECIALITY_THEMING_SMOKE_OK` — verifica che `effect_id`,
  `effect_parameters`, `weight` e `max_rank` restino identici ai valori
  pre-restyle mentre `title`/`description`/`icon` cambiano, e che
  `BarbRewardOverlay` risolva le nuove icone senza riferimenti nulli.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: apri la schermata Barb con le nuove
      Specialità, verifica leggibilità di nome e icona a dimensione reale
- [ ] Controllo percettivo richiesto: sì — le otto icone devono leggersi
      come pezzi/piatti distinti del menù di Barb, non solo come restyle
      cosmetico casuale

## Decisioni

- **2026-09-02 — Bloccata da PS-077.** PS-077 è ancora `PRONTO`, non ha
  raggiunto `IN VERIFICA`: questa card resta `BLOCCATO` finché PS-077 non
  arriva almeno a quello stato, coerente con la regola di dipendenza della
  board. Si sblocca da sola quando PS-077 entra in `4_to_test/`.
- **2026-09-02 — Card `art`: delega a `game-art-designer`.** Richiede nuove
  icone generate, non solo adattamento di arte esistente; per contratto di
  board (`docs/cards/README.md`) va delegata all'agente Game Art Designer,
  non implementata direttamente da `card-risolvi`.
- **2026-09-02 — Dipende da PS-077.** Copre le otto Specialità risultanti
  dall'espansione del pool; tematizzare solo le quattro attuali richiederebbe
  un secondo passaggio quando arrivano le altre quattro.
- **2026-09-02 — Nessun nuovo effetto o rank.** Stesso principio già
  dichiarato da PS-012 ("il loro design gameplay non deve essere
  modificato"): qui si applica a identità invece che a meccanica di
  sblocco.

## Documenti sincronizzati

- [ ] `docs/powerup-catalog.md`: eventuale nota sulle Specialità tematizzate,
      se il proprietario vuole documentarle nello stesso file.

## Note

Se in fase di implementazione il nuovo nome di una carta rendesse l'effetto
meno leggibile rispetto a oggi, va preferita la leggibilità: segnalarlo
invece di forzare un titolo a effetto ma ambiguo.
