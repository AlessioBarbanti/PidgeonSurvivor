---
id: PS-052
titolo: Generare i ritratti Evil e le icone Signature definitivi
tipo: art
area: arte
stato: PRONTO
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

- [ ] Sono presenti Evil Alea, Aleo, Bea, Lollo, Magno, Marghe, Migi e Zat.
- [ ] Ogni busto conserva silhouette e tratti identificativi del personaggio
      corrispondente ed è distinguibile dagli altri sette.
- [ ] Gli otto condividono una sola grammatica di corruzione, senza uniformare
      abiti, capelli o accessori che definiscono i personaggi.
- [ ] Ogni ritratto è leggibile alla dimensione reale della Boss intro sul
      Pixel 9 e armonizza con l'accento personale senza esserne sommerso.
- [ ] Nessun ritratto definitivo riusa lo spritesheet CC0 di terze parti.

### Otto icone Signature

- [ ] Ogni icona ha una silhouette distinta e resta leggibile alla dimensione
      reale della intro.
- [ ] Ogni icona comunica il comportamento della Signature corrispondente:
      rotazione per Alea, sbalzo termico per Aleo, scivolata per Bea,
      trasformazione per Lollo, onda tellurica per Magno, clone ritmico per
      Marghe, rallentamento zen per Migi e tempesta per Zat.
- [ ] Colore e forma restano coerenti con `accent_color` e telegraph runtime;
      l'icona non promette un'area d'effetto differente.
- [ ] Le otto icone condividono griglia, margini, pixel density e trattamento
      delle icone abilità e upgrade già approvate.

### Comuni

- [ ] I sedici asset definitivi sostituiscono i `fake_*.png` cablati da PS-051
      e i riferimenti nei `.tres` vengono aggiornati.
- [ ] Nessun `fake_*.png` resta nelle cartelle runtime dei ritratti Evil e
      delle icone Signature.
- [ ] `evil_portrait_placeholder` resta disponibile come fallback; i campi di
      approvazione e provenienza vengono aggiornati solo quando descrivono
      correttamente sia asset pubblico sia fallback.
- [ ] Ogni nuovo file possiede master HD e derivato runtime separati.
- [ ] I manifest registrano percorso, prompt/origine, autore, licenza,
      trasformazioni e SHA-256; i master HD restano esclusi dai preset export.
- [ ] Nessun valore di Signature, colore dichiarativo o comportamento UI
      definito da PS-051 cambia per adattarsi all'arte.

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

- Smoke: riusa `tests/unit/test_ps051_boss_intro_identity.gd`, esteso per
  verificare che gli otto Evil e le otto Signature risolvano asset definitivi
  e che nessun riferimento contenga `fake_`.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK — master HD esclusi dai tre preset
- [ ] Runtime fisico Pixel 9: intro di almeno due Evil con silhouette e
      Signature differenti
- [ ] Controllo percettivo richiesto: sì — accettazione del proprietario sui
      sedici file e riconoscibilità rispetto al cast di origine

## Decisioni

- **2026-08-31 — Il Piccione Malvagio non fa parte del lotto.** Possiede già
  un ritratto dedicato; questa card risolve esclusivamente gli otto Evil.
- **2026-08-31 — Un'unica grammatica, otto identità.** Il trattamento Evil è
  condiviso, ma non cancella i tratti distintivi del cast.
- **2026-08-31 — Il colore viene dai dati.** L'arte si adegua agli accenti
  approvati e non li riscrive per comodità grafica.

## Documenti sincronizzati

- [ ] `assets/art/characters/ASSET-MANIFEST.md`.
- [ ] `assets/art/icons/signatures/ASSET-MANIFEST.md`.
- [ ] `docs/visual-audio-identity.md`: ritratti Evil e icone Signature finali.
- [ ] `docs/characters.md`, se cambia lo stato di approvazione dei ritratti.

## Note

Conservare master HD, derivati runtime, prompt, trasformazioni e hash secondo
la pipeline asset del repository.
