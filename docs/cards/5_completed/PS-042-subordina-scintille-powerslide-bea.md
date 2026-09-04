---
id: PS-042
titolo: Subordina le scintille della Powerslide al nastro di fuoco
tipo: fix
area: arte
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-09-04
---


# PS-042 — Subordina le scintille della Powerslide al nastro di fuoco

## Contesto

Durante la Powerslide di Bea, sopra la scia di fuoco compaiono dei rombi gialli
a tinta unita dal bordo netto, che il proprietario ha segnalato con uno
screenshot come "stelline" e come causa di una fiammata dalla tinta non
uniforme.

Non sono un residuo di asset: le disegna
[`fire_z_trail.gd:126-141`](../../../scripts/abilities/fire_z_trail.gd), sedici
per volta (`VISUAL_PARTICLE_COUNT = 16`), con `draw_colored_polygon` in
`Color(1.0, 0.88, 0.36, ...)` — nessuna texture, nessuna sfumatura.

Il difetto è misurabile, non solo di gusto: il nastro di fuoco è stampato a
`STAMP_ALPHA = 0.62`, mentre l'alpha delle scintille arriva a
`0.55 + 0.4 = 0.95`. Le scintille sono quindi fino al **53% più opache del
nastro su cui poggiano**, e leggono come macchie piene sopra una fiamma
semitrasparente.

Sono della stessa generazione procedurale delle due `draw_polyline` che
[PS-027](./PS-027-rimuovi-artefatto-powerslide-bea.md) ha già rimosso dalla
stessa funzione `_draw()`; sono sopravvissute a quel giro perché PS-027 guardava
l'artefatto *sotto* Bea, non quello *sopra* la scia.

## Comportamento atteso

Le scintille restano visibili, ma leggono come dettaglio interno alla fiammata
invece che come forme sovrapposte: non superano mai l'opacità del nastro, sono
più piccole di oggi e prendono la loro tinta dalla palette della fiamma invece
del giallo piatto attuale.

La tinta complessiva della fiammata torna a leggersi uniforme: nessuna macchia
gialla piena si stacca dal nastro.

La modifica è esclusivamente visuale e non tocca traiettoria, distanza, durata,
danno o collisioni della Powerslide.

## Criteri di accettazione

- [x] L'opacità massima di una scintilla è **strettamente minore** di
      `STAMP_ALPHA` (0.62) nello stesso frame, per ogni valore dell'alpha di
      dissolvenza della scia. `SPARK_ALPHA_BASE + SPARK_ALPHA_SWING = 0.52 <
      0.62`; la dissolvenza moltiplica entrambe allo stesso modo quindi il
      margine vale per ogni frame.
- [x] La tinta delle scintille non è più `Color(1.0, 0.88, 0.36)`, ma un colore
      appartenente alla palette del nastro
      (`assets/art/vfx/abilities/generated/fire_trail.png`). Campionata
      dai pixel reali della texture (fascia arancio del corpo,
      `Color(0.988, 0.62, 0.055)`).
- [x] Le scintille sono più piccole di oggi (`spark_size` corrente: `2.0 +
      spark_index % 3`, quindi 2–4 unità). Ora `1.2 + (spark_index % 3) * 0.6`,
      cioè 1.2–2.4.
- [x] Nessun rombo giallo pieno si distingue dal nastro nello screenshot di
      confronto sullo stesso punto della scia. Gate percettivo, vedi Gate
      manuali.
- [x] La famiglia visiva resta `powerslide_ribbon_and_sparks` e
      `get_visual_particle_count()` resta entro `MAX_VISUAL_PARTICLES` di
      `test_b18m_ability_visuals.gd` (il test impone un tetto, non un minimo).
- [x] Traiettoria, distanza, durata, danno e collisioni della Powerslide
      restano invariati. Non toccati; regressione confermata da
      `test_ps040_bea_powerslide_landing_iframe.gd`.
- [x] Le due `draw_polyline` rimosse da PS-027 non tornano. Confermato da
      `test_ps027_bea_powerslide_visual_cleanup.gd` e dal nuovo smoke.

## Ambito

- `scripts/abilities/fire_z_trail.gd`: il solo blocco scintille in `_draw()`
  (righe 125-142) e le costanti di presentazione che ne derivano.

Non toccare:

- `_build_straight_path()`, `_apply_damage_tick()`, `_is_point_near_trail()`:
  usano `_path_points`/`_trail_width` e sono indipendenti dal disegno;
- gli stampi di texture del nastro (`draw_texture_rect` con
  `FIRE_TRAIL_TEXTURE`), `STAMP_SPACING_RATIO` e `STAMP_ALPHA`, che definiscono
  il nastro a cui le scintille devono subordinarsi;
- `VISUAL_FAMILY_ID`: il nome resta, perché le scintille restano;
- l'autorità di `RunController` e il registry degli effetti: la card non tocca
  dati né wiring, solo presentazione.

## Verifica

- Smoke: `tests/unit/test_ps042_bea_powerslide_spark_subordination.gd`.
  Per restare deterministico e non fragile, il test deve asserire su **costanti
  esposte** (per esempio `SPARK_ALPHA_BASE + SPARK_ALPHA_SWING < STAMP_ALPHA`),
  non sul testo del sorgente né su un rendering. Estrarre le costanti oggi
  inline è parte del lavoro.
- Regressione attesa nello stesso giro: `test_ps027_bea_powerslide_visual_cleanup.gd`
  (le `draw_polyline` non devono tornare) e `test_b18m_ability_visuals.gd`
  (famiglia visiva e budget particelle).
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [x] Runtime Windows — percorso: attiva la Powerslide di Bea e confronta la
      scia con lo screenshot allegato alla segnalazione.
- [x] Controllo percettivo richiesto: sì — solo il proprietario può dichiarare
      uniforme la tinta della fiammata.

Validazione statica APK e runtime fisico Pixel 9 non sono pertinenti: la
modifica non tocca codice di piattaforma, input o lifecycle.

## Decisioni

- **2026-08-31 — Le scintille restano, subordinate al nastro.** Scelta del
  proprietario fra tre opzioni proposte: rimuoverle del tutto (come PS-027 fece
  con le polyline), tenerle subordinandole, o restilizzarle con una texture in
  pixel art. Le prime e la terza sono state scartate: la rimozione avrebbe
  richiesto di rinominare la famiglia visiva verificata per nome da B18M, la
  restilizzazione avrebbe richiesto un asset nuovo con voce di
  `ASSET-MANIFEST.md`. La subordinazione risolve il difetto misurato —
  l'inversione di opacità — col minor raggio di impatto.
- **Il difetto è l'inversione di opacità, non la presenza delle scintille.**
  Il criterio duro della card è l'alpha; taglia e tinta seguono da quello.
- **Non sostituisce PS-027**, che resta aperta sul proprio criterio di cleanup
  (restart e cambio personaggio). Le due card toccano la stessa funzione ma
  elementi diversi.
- **2026-09-01 — Tinta campionata dalla texture reale, non a occhio.** Letti i
  pixel di `fire_trail.png` con `System.Drawing` per evitare un colore
  inventato che "assomiglia" alla fiamma senza appartenerle davvero; scelta
  la fascia arancio del corpo (nucleo crema e bordo magenta erano gli altri
  due estremi della palette, meno adatti a un dettaglio piccolo).
- **2026-09-01 — Margine di alpha ampio, non al limite.** `0.52` contro un
  tetto di `0.62` lascia margine percettibile invece di un rispetto
  puramente numerico del criterio.

## Documenti sincronizzati

- [x] `docs/visual-audio-identity.md`, se la resa concordata cambia il contratto
      di identità visiva della Powerslide.

## Note

Segnalazione del proprietario con screenshot, 2026-08-31: rombi gialli visibili
lungo tutta la scia, più evidenti nella metà iniziale dove l'alpha di
dissolvenza è ancora vicina a 1.

Evidenza di chiusura automatica (2026-09-01):

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-042 -Profile Focused `
  -FocusedSmoke tests/unit/test_ps042_bea_powerslide_spark_subordination.gd -RefreshEditor
# PASS focused=1/1

.\tools\run-milestone-checks.ps1 -Milestone PS-042 -Profile Relevant `
  -FocusedSmoke tests/unit/test_ps042_bea_powerslide_spark_subordination.gd `
  -ChangedPath scripts/abilities/fire_z_trail.gd,tests/unit/test_ps042_bea_powerslide_spark_subordination.gd,tools/milestone-test-map.json,assets/art/vfx/ASSET-MANIFEST.md
# PASS regression=8/8, nessun SCRIPT ERROR/FATAL EXCEPTION nei log
```

`-ChangedPath` esplicito perché il working tree conteneva, per un altro
workflow in corso (PS-052), nuovi PNG non tracciati sotto `assets/art/` non
ancora mappati in `tools/milestone-test-map.json`: senza `-ChangedPath` la
rilevazione automatica dei path modificati li considerava "runtime non
mappati" e faceva scattare `run_all`, con un batch da 87 script che è andato
in TIMEOUT dopo 30 minuti. Non è un difetto di questa card.

Aggiornato anche `assets/art/vfx/ASSET-MANIFEST.md`: le due righe che
tracciano l'hash di `fire_z_trail.gd` avevano gia' valori disallineati fra
loro prima di questa card; portate entrambe all'hash corrente
(`39346b07d7aef0f95b88b2dd29092bfd02150e2ff52c0ec4166fe07fec54193c`), come
richiesto da `test_b18m_ability_visuals.gd::test_manifest_contract`.

Misure di partenza, da `fire_z_trail.gd`:

| Elemento | Alpha | Tinta | Forma |
|---|---|---|---|
| Nastro (`draw_texture_rect`) | `0.62` fisso | texture | `fire_trail.png`, specchiata a alternanza |
| Scintilla (`draw_colored_polygon`) | `0.55`–`0.95` | `Color(1.0, 0.88, 0.36)` | rombo, diagonali `3.6×spark_size` e `2×spark_size` |
