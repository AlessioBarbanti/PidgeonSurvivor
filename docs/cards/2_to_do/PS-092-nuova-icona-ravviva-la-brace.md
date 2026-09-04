---
id: PS-092
titolo: Genera una nuova icona per Ravviva la Brace! (ex Bis di Salsiccia)
tipo: art
area: arte
stato: PRONTO
priorita: bassa
dipende_da: []
origine: PS-089
creato: 2026-09-04
aggiornato: 2026-09-04
---

# PS-092 — Genera una nuova icona per Ravviva la Brace! (ex Bis di Salsiccia)

## Contesto

[PS-089](../5_completed/PS-089-elimina-sovrapposizioni-tema-carne-powerup.md) ha
rinominato `ability_cooldown` (`data/upgrades/ability_cooldown.tres`) da
`Bis di Salsiccia` a `Ravviva la Brace!`, perché un pezzo di carne è ora un
soggetto riservato alle otto Specialità di Barb
([PS-078](../3_in_sprint/PS-078-tematizza-catalogo-specialita-barb.md)). Quella
card ha toccato solo `title`/`description`/`effect_summary`: l'icona runtime
resta `assets/art/icons/upgrades/generated/bis_di_salsiccia.png`, derivata da
`assets/art/icons/upgrades/hd/upgrade_bis_di_salsiccia.png`, e ritrae
letteralmente una salsiccia — un'incoerenza fra testo e immagine che PS-089
ha dichiarato esplicitamente fuori dal proprio ambito (generare arte non
richiesta non è compito di una card `chore`).

## Comportamento atteso

`ability_cooldown` ha un'icona coerente con il nuovo titolo e con la
direzione visiva grigliatore già stabilita in `docs/powerup-catalog.md`
(utensili, condimenti, pirofile, brace, cottura — mai carne), che comunica
"riduzione del cooldown dell'abilità attiva" senza raffigurare un pezzo di
carne.

## Criteri di accettazione

- [ ] Nuovo master HD in `assets/art/icons/upgrades/hd/` e derivato
      `128×128` in `assets/art/icons/upgrades/generated/` che sostituiscono
      `upgrade_bis_di_salsiccia.png`/`bis_di_salsiccia.png`, con riga
      aggiornata in `assets/art/icons/upgrades/ASSET-MANIFEST.md` (origine,
      autore/licenza, trasformazioni, hash SHA-256).
- [ ] Il soggetto raffigurato non è un taglio, un pezzo o un piatto di carne:
      resta nel registro utensili/brace/cottura già stabilito per il
      catalogo ordinario, mai carne (riservata alle Specialità, PS-078).
- [ ] L'icona comunica a colpo d'occhio "ricarica più rapida dell'abilità
      attiva" (es. brace che si riaccende, un secondo giro di cottura),
      leggibile a dimensione carta reale.
- [ ] Nessun piccione come soggetto principale, coerente con la direzione
      visiva dichiarata in `docs/powerup-catalog.md`.
- [ ] Nessuna modifica a `title`, `description`, `effect_summary`,
      `effect_id`, `effect_parameters`, `weight`, `max_rank`: questa card
      cambia solo l'icona.

## Ambito

- `assets/art/icons/upgrades/hd/` e `assets/art/icons/upgrades/generated/`:
  solo il nuovo asset per `ability_cooldown`.
- `assets/art/icons/upgrades/ASSET-MANIFEST.md`.

Non toccare:

- `data/upgrades/ability_cooldown.tres` oltre al riferimento `icon`;
- qualunque altra carta del catalogo ordinario o delle Specialità di Barb;
- `docs/powerup-catalog.md` oltre a un'eventuale nota sul nuovo file icona,
  se il proprietario la vuole registrare.

Card `tipo: art` che richiede una nuova generazione: per contratto di board
([docs/cards/README.md](../README.md)) va delegata all'agente
`game-art-designer`, non implementata direttamente da `card-risolvi`. Il
riferimento `icon = ExtResource(...)` in `ability_cooldown.tres` verso il
nuovo derivato è lo scambio di un `ext_resource` già esistente sulla stessa
riga, non un nuovo wiring: resta dentro questa card invece di aprire una
card di integrazione separata (vedi [PS-090](../3_in_sprint/PS-090-separa-generazione-integrazione-card-art.md),
che comunque non era ancora chiusa quando questa card è stata scritta).

## Verifica

- Nessuno smoke GUT dedicato: la copertura runtime esistente
  (`test_powerup_first_wave.gd`, `test_b12_upgrade_effects.gd`) verifica già
  che `ability_cooldown` risolva un'icona non nulla; non serve un nuovo test
  per un cambio di solo asset.
- Profilo minimo prima della chiusura: `Focused` sulla suite upgrade
  esistente, per confermare che il nuovo riferimento icona non rompa nulla.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: apri il level-up o Barb con `Ravviva la
      Brace!` in offerta, verifica leggibilità dell'icona a dimensione reale
- [ ] Controllo percettivo richiesto: sì — l'icona deve leggersi come
      brace/cottura, non più come salume, e restare coerente con le altre
      icone del catalogo ordinario

## Decisioni

- **2026-09-04 — Aperta da PS-089, non generata dentro quella card.** PS-089
  è una card `chore` di rinomina testuale; generare una nuova icona è lavoro
  di competenza `game-art-designer` per contratto di board, quindi PS-089 ha
  dichiarato l'incoerenza e aperto questa card invece di produrre l'asset.
- **2026-09-04 — Priorità bassa.** L'icona attuale è fuorviante ma non rotta:
  il gioco funziona, la carta resta selezionabile e leggibile come "riduzione
  cooldown" dal testo. Non blocca nessun'altra card.
- **2026-09-04 — Titolo corretto in `Ravviva la Brace!` (era `Bis di
  Brace`).** Il proprietario ha giudicato `Bis di Brace` un titolo debole e
  ha chiesto qualcosa sul riaccendere/ravvivare la brace: il nuovo titolo
  comunica meglio "l'abilità è di nuovo pronta" (la brace si riaccende)
  invece di limitarsi a un'eco del vecchio "bis". Propagato in
  `data/upgrades/ability_cooldown.tres`, `docs/powerup-catalog.md`, PS-089,
  PS-090 e nei test coinvolti.

## Documenti sincronizzati

- [ ] `assets/art/icons/upgrades/ASSET-MANIFEST.md`: nuova riga per il
      derivato che sostituisce `bis_di_salsiccia`.

## Note

Possibile prompt di generazione (da adattare in fase di implementazione
contro lo stile pixel-art già stabilito nel resto del catalogo, vedi le
icone vicine in `assets/art/icons/upgrades/generated/`):

> Pixel-art icon, 128×128, game upgrade card icon for a backyard-grill
> survivor game. Subject: a pair of glowing charcoal embers/briquettes with
> small motion lines suggesting them flaring up a second time, as if
> quickly reignited — communicates "ability cooldown reduced, ready again
> faster". Warm orange-red glow against dark charcoal, small spark
> particles. No sausage, no meat, no cut of any kind. No pigeons. Clean
> readable silhouette at small size, thick outline, flat cel-shaded pixel
> art matching a barbecue/grill-master visual theme (tongs, seasoning,
> roasting trays, embers — utensils and cooking, not food). Centered
> composition, transparent background.

