---
id: PS-118
titolo: Genera nome e icona definitivi per la nona Specialità (cariche multiple abilità attiva)
tipo: art
area: arte
stato: PRONTO
priorita: bassa
dipende_da: []
origine:
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-118 — Genera nome e icona definitivi per la nona Specialità (cariche multiple abilità attiva)

## Contesto

[PS-094](../3_in_sprint/PS-094-specialita-cariche-abilita-attiva.md) introduce
una nona Specialità di Barb (cariche multiple sull'abilità attiva,
`effect_id = &"ability_charge_stacking"`, `id = &"ability_charge_stacking"`).
Per contratto PS-090 quella card non produce arte: usa il titolo di lavoro
provvisorio "Bis alla Griglia" e un'icona placeholder deterministica
(`tools/generate-art-placeholder.ps1`, firma magenta `(0,0)`) generata in
`assets/art/icons/upgrades/generated/ability_charge_stacking.png`. Questa
card chiude quel debito: nome definitivo coerente col registro "pezzo di
carne" già stabilito da [PS-078](../5_completed/PS-078-tematizza-catalogo-specialita-barb.md)
(Costine, Salsiccia, Fiorentina, Hamburger, ecc.) e icona pixel-art arcade
nello stesso stile della famiglia upgrade.

## Comportamento atteso

La Specialità mostra un nome italiano definitivo e un'icona pixel-art coerente
con le altre otto Specialità tematizzate, al posto del titolo di lavoro e del
placeholder a scacchiera magenta.

## Criteri di accettazione

- [ ] Nome italiano definitivo proposto (soggetto da griglia, coerente col
      registro di PS-078) e approvato dal proprietario.
- [ ] Master HD e derivato `128×128` generati con
      `tools/process-upgrade-icon.ps1`, stessa geometria delle altre icone
      upgrade; il soggetto comunica visivamente "più cariche/riutilizzo"
      (es. una porzione doppia/ripetuta dello stesso taglio) senza badge,
      numeri o testo.
- [ ] `ASSET-MANIFEST.md` di `assets/art/icons/upgrades/` aggiornato: nuova
      sezione con origine, prompt, trasformazione, hash SHA-256 di master e
      derivato; la riga placeholder odierna viene sostituita, non duplicata.
- [ ] Integrazione (banale, un solo criterio esplicito per PS-090): il campo
      `title` di `data/upgrades/specialities/ability_charge_stacking.tres`
      viene aggiornato al nome approvato; il campo `icon` continua a
      referenziare lo stesso percorso `generated/ability_charge_stacking.png`
      (solo i byte del file cambiano, nessun rewiring di scena/registry).
- [ ] Il pixel `(0,0)` del derivato non è più la firma placeholder (magenta
      piena `255,0,255,255`).

## Ambito

- `assets/art/icons/upgrades/hd/` e `generated/ability_charge_stacking.png`.
- `assets/art/icons/upgrades/ASSET-MANIFEST.md`.
- `data/upgrades/specialities/ability_charge_stacking.tres` (solo `title`,
  eventualmente `effect_summary` se il nome lo richiede).

Non toccare:

- `effect_id`, `effect_parameters`, `max_rank`, `is_speciality`: la meccanica
  di PS-094 resta invariata.
- le altre otto Specialità e il catalogo ordinario.
- `scenes/game/movement_slice.tscn`: il wiring esiste già (PS-094), nessun
  ext_resource da aggiungere o spostare.

## Verifica

- Nessuno smoke nuovo: `tests/unit/test_ps094_ability_charge_stacking.gd`
  non asserisce su titolo/icona. Rifresca la cache import prima di un
  controllo percettivo manuale.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9
- [ ] Controllo percettivo richiesto: sì — confronto diretto con le altre
      otto icone Specialità a dimensione reale (128×128) e a 48×48.

## Decisioni

- **2026-09-07 — Aperta in handoff da PS-094**, come da contratto PS-090 (una
  card `art` non produce mai la propria integrazione, e una card di
  meccanica non produce mai arte). PS-078 era già `IN VERIFICA` quando
  PS-094 è stata presa in carico: per la stessa card PS-094, questa nona
  tematizzazione va aperta qui invece di riaprire PS-078.

## Documenti sincronizzati

- [ ] `docs/powerup-catalog.md`, se il proprietario vuole registrare qui
      anche le Specialità di Barb.

## Note

Nome di lavoro attuale (non approvato): "Bis alla Griglia". Il proprietario
può confermarlo, proporne uno diverso, o delegare la scelta al
game-art-designer insieme alla direzione dell'icona.
