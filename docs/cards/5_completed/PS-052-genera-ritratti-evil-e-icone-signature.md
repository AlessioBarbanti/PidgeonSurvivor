---
id: PS-052
titolo: Generare i ritratti Evil e le icone Signature definitivi
tipo: art
area: arte
stato: IN VERIFICA
priorita: media
dipende_da: [PS-051]
origine:
creato: 2026-08-31
aggiornato: 2026-09-02
---

# PS-052 — Generare i ritratti Evil e le icone Signature definitivi

## Contesto

[PS-051](./PS-051-identita-individuale-degli-evil.md) introduce nella Boss
intro sedici segnaposto `fake_*.png`: otto busti Evil e otto icone Signature.
Questa card produce gli asset definitivi e aggiorna i riferimenti mantenendo
invariati layout, fallback e dati di gameplay.

La cattura
[06_boss_intro.png](../../../exports/ui-screenshots/pixel9-20x9/06_boss_intro.png)
riguarda il Piccione Malvagio baseline. Il suo ritratto esistente resta fuori
da questa produzione; il gate percettivo deve essere eseguito su vere intro
Evil.

## Comportamento atteso

Ogni Evil è riconoscibile come controparte corrotta del personaggio di origine
e ogni Signature possiede un'icona leggibile, coerente sia con la sua forma in
arena sia con l'`accent_color` dichiarato nei dati.

## Criteri di accettazione

### Otto ritratti Evil

- [x] Sono presenti Evil Alea, Aleo, Bea, Lollo, Magno, Marghe, Migi e Zat.
- [ ] Ogni busto conserva silhouette e tratti identificativi del personaggio
      corrispondente ed è distinguibile dagli altri sette. **Aperto**: gate
      percettivo del proprietario (vedi Gate manuali), non automatizzabile.
- [ ] Gli otto condividono una sola grammatica di corruzione, senza uniformare
      abiti, capelli o accessori che definiscono i personaggi. **Aperto**:
      gate percettivo del proprietario.
- [ ] Ogni ritratto è leggibile alla dimensione reale della Boss intro sul
      Pixel 9 e armonizza con l'accento personale senza esserne sommerso.
      **Aperto**: richiede runtime fisico su device, non disponibile in
      questa sessione (sandbox Linux remoto).
- [x] Nessun ritratto definitivo riusa lo spritesheet CC0 di terze parti:
      gli otto file sono PNG generati distinti, non `AtlasTexture` sulla
      spritesheet condivisa (verificato da
      `test_ps052_evil_portraits_and_signature_icons_resolve_definitive_art`).

### Otto icone Signature

- [ ] Ogni icona ha una silhouette distinta e resta leggibile alla dimensione
      reale della intro. **Aperto**: gate percettivo del proprietario.
- [ ] Ogni icona comunica il comportamento della Signature corrispondente:
      rotazione per Alea, sbalzo termico per Aleo, scivolata per Bea,
      trasformazione per Lollo, onda tellurica per Magno, clone ritmico per
      Marghe, rallentamento zen per Migi e tempesta per Zat. **Aperto**: gate
      percettivo del proprietario.
- [ ] Colore e forma restano coerenti con `accent_color` e telegraph runtime;
      l'icona non promette un'area d'effetto differente. **Aperto**: gli
      `accent_color` dichiarati restano invariati (verificato), ma la resa
      cromatica/formale dell'icona è un giudizio percettivo del proprietario.
- [x] Le otto icone condividono griglia, margini, pixel density e trattamento
      delle icone abilità e upgrade già approvate: prodotte con la stessa
      pipeline deterministica (`process-upgrade-icon.ps1 -Size 256 -Padding 20`),
      documentata nel manifest.

### Comuni

- [x] I sedici asset definitivi sostituiscono i `fake_*.png` cablati da PS-051
      e i riferimenti nei `.tres` vengono aggiornati.
- [x] Nessun `fake_*.png` resta nelle cartelle runtime dei ritratti Evil e
      delle icone Signature.
- [x] `evil_portrait_placeholder` resta disponibile come fallback; `portrait_source`
      continua a descrivere correttamente solo il fallback CC0 (non esiste un
      campo di provenienza dedicato a `evil_portrait`: la sua origine vive nei
      due `ASSET-MANIFEST.md`, aggiornati).
- [x] Ogni nuovo file possiede master HD e derivato runtime separati.
- [x] I manifest registrano percorso, prompt/origine, autore, licenza,
      trasformazioni e SHA-256; i master HD restano esclusi dai preset export
      (`assets/art/characters/*/hd/**` e `assets/art/icons/signatures/hd/**`
      in `export_presets.cfg`, verificato sui tre preset).
- [x] Nessun valore di Signature, colore dichiarativo o comportamento UI
      definito da PS-051 cambia per adattarsi all'arte (diff dei `.tres`
      limitato a percorso e id della risorsa).

## Ambito

- `assets/art/characters/<id>/hd/` e
  `assets/art/characters/<id>/generated/`, per gli otto personaggi.
- `assets/art/icons/signatures/hd/` e
  `assets/art/icons/signatures/generated/`.
- I relativi `ASSET-MANIFEST.md`.
- `data/friends/*.tres` e `data/bosses/signatures/*.tres`, solo per percorsi,
  fallback e metadati di approvazione/provenienza.

Non toccare:

- `scripts/ui/boss_ui.gd` e la scena Boss intro definiti da PS-051;
- ritratto e dati del Piccione Malvagio baseline;
- valori di gameplay e `accent_color` delle Signature.

## Verifica

- Smoke: riusa `tests/unit/test_ps051_boss_intro_identity.gd`, esteso con
  `test_ps052_evil_portraits_and_signature_icons_resolve_definitive_art` per
  verificare che gli otto Evil e le otto Signature risolvano asset
  definitivi, distinti fra loro, e che nessun riferimento contenga `fake_`.
- Profilo minimo prima della chiusura: `Relevant`. Eseguito con Godot 4.7.1
  headless in sandbox Linux (nessun PowerShell disponibile in questa
  sessione): tutti gli smoke mappati su
  `data/friends/*`/`data/bosses/*`/`assets/art/characters/*/generated/*`/
  `assets/art/icons/signatures/*` passano, incluso il file esteso.

## Gate manuali

- [ ] Runtime Windows. **Aperto**: nessun ambiente Windows disponibile in
      questa sessione, solo validazione headless via Godot/GUT.
- [x] Validazione statica APK — master HD esclusi dai tre preset: verificato
      per ispezione di `export_presets.cfg` (`assets/art/characters/*/hd/**`
      e `assets/art/icons/signatures/hd/**` nell'`exclude_filter` di tutti e
      tre i preset). Non è stato compilato un APK in questa sessione.
- [ ] Runtime fisico Pixel 9: intro di almeno due Evil con silhouette e
      Signature differenti. **Aperto**: richiede device collegato.
- [ ] Controllo percettivo richiesto: sì — accettazione del proprietario sui
      sedici file e riconoscibilità rispetto al cast di origine. **Aperto**.

## Decisioni

- **2026-08-31 — Il Piccione Malvagio non fa parte del lotto.** Possiede già
  un ritratto dedicato; questa card risolve esclusivamente gli otto Evil.
- **2026-08-31 — Un'unica grammatica, otto identità.** Il trattamento Evil è
  condiviso, ma non cancella i tratti distintivi del cast.
- **2026-08-31 — Il colore viene dai dati.** L'arte si adegua agli accenti
  approvati e non li riscrive per comodità grafica.
- **2026-09-02 — Card trovata quasi completa: arte già prodotta, mancava solo
  l'integrazione.** Un commit precedente (`feat(PS-052): produci asset Evil e
  Signature`) aveva già generato i sedici asset definitivi (master HD +
  derivati runtime + manifest), ma non aveva aggiornato `data/friends/*.tres`
  e `data/bosses/signatures/*.tres`, che continuavano a puntare ai
  `fake_*.png` di PS-051 — coerente con quanto i due `ASSET-MANIFEST.md`
  stessi dichiaravano ("non sono referenziati"). Questa sessione ha
  completato l'integrazione (rewiring dei 16 riferimenti, rimozione dei
  `fake_*.png`, estensione dello smoke, sincronizzazione dei documenti),
  lasciando aperti solo i gate percettivi/su device che richiedono il
  giudizio del proprietario o un ambiente non disponibile in sandbox.
- **2026-09-02 — Due difetti preesistenti trovati e spostati in card
  separate, non corretti qui.** Verificando il set di regressione toccato da
  questa card sono emersi due fallimenti indipendenti, riprodotti identici
  anche su `HEAD` prima di qualunque modifica di PS-052: l'aspettativa
  `32x32` su `evil_portrait` in `test_b17_friend_content.gd`, superata da
  PS-051 (vedi [PS-070](../2_to_do/PS-070-aggiorna-aspettativa-32x32-evil-portrait-b17.md)),
  e l'overflow del pannello Boss Intro dalla safe area in
  `test_b15_boss_encounter.gd` (vedi
  [PS-071](../2_to_do/PS-071-pannello-boss-intro-esce-dalla-safe-area.md)).

## Documenti sincronizzati

- [x] `assets/art/characters/ASSET-MANIFEST.md`.
- [x] `assets/art/icons/signatures/ASSET-MANIFEST.md`.
- [x] `docs/visual-audio-identity.md`: ritratti Evil e icone Signature finali.
- [x] `docs/characters.md`: nessun riferimento ai ritratti Evil o al loro
      stato di approvazione in questo documento, nulla da sincronizzare.

## Note

Conservare master HD, derivati runtime, prompt, trasformazioni e hash secondo
la pipeline asset del repository.
