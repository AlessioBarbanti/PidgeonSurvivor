---
id: PS-128
titolo: Genera un ritratto definitivo per il Piccione Malvagio
tipo: art
area: arte
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-128 — Genera un ritratto definitivo per il Piccione Malvagio

## Contesto

Il campo `portrait` del Boss baseline in `data/bosses/first_boss.tres` non è un
ritratto dedicato: è un `AtlasTexture` che ritaglia un riquadro `48×48` dalla
spritesheet di gameplay `assets/art/enemies/pigeons/pigeon_special.png`.
[PS-052](../5_completed/PS-052-genera-ritratti-evil-e-icone-signature.md) aveva
escluso deliberatamente il Piccione Malvagio dal lotto degli otto ritratti Evil
assumendo che possedesse già un ritratto dedicato. PS-128 produce l'asset
definitivo; [PS-129](./PS-129-integra-ritratto-piccione-malvagio-boss-intro.md)
ne possiede wiring e verifica runtime.

## Comportamento atteso

È disponibile un busto del Piccione Malvagio alla stessa qualità e con lo stesso
trattamento produttivo degli otto ritratti Evil, pronto per sostituire il
ritaglio dello spritesheet nella Boss intro senza ridisegnare il personaggio.

## Criteri di accettazione

- [x] Esiste un master HD in
      `assets/art/characters/piccione_malvagio/hd/portrait.png` e un derivato
      runtime `generated/portrait.png` a `256×256`, prodotto con
      `tools/process-upgrade-icon.ps1 -Size 256 -Padding 24`.
- [x] Il busto conserva silhouette, colori e identità visiva dichiarati in
      `data/bosses/first_boss.tres` e riconoscibili in `pigeon_special.png`:
      corpo charcoal/indaco, outline prugna quasi nero, collare magenta e
      accenti oro-arancio.
- [x] La composizione segue la famiglia dei ritratti Evil: busto centrale a tre
      quarti, outline scuro, cluster pixel leggibili, fumo prugna controllato,
      margine sicuro e sfondo realmente trasparente.
- [x] Il master HD è protetto da `.gdignore` ed escluso dai tre preset tramite
      `assets/art/characters/*/hd/**`; il derivato isolato è stato riesaminato
      alla dimensione reale `256×256`.
- [x] `assets/art/characters/ASSET-MANIFEST.md` registra prompt, origine,
      autore, licenza, trasformazione, dimensioni e SHA-256 di entrambi i file.

## Ambito

- Master e derivato del nuovo ritratto.
- `.gdignore` della cartella HD.
- Manifest e documentazione della sola produzione artistica.

Non toccare:

- `data/bosses/first_boss.tres`, test e wiring runtime, posseduti da PS-129;
- `pigeon_special.png` e lo sprite di gameplay;
- `scripts/ui/boss_ui.gd` e il layout della Boss intro;
- dati o pattern di gameplay del Boss baseline, oggetto invece di
  [PS-127](../4_to_test/PS-127-piccione-malvagio-boss-raro-e-piu-difficile-degli-evil.md).

## Verifica

- [x] Derivazione deterministica: marker `UPGRADE_ICON_RUNTIME_OK`; output
      `256x256`, `120448` byte, SHA-256
      `51C4ADCAFC11B9ECCE53C2E3910AC62C3FE5CAD1C0F78A11ED92F62C1D5865AB`.
- [x] Master `1254x1254` RGBA e derivato `256x256` RGBA; alpha degli angoli del
      derivato `0,0,0,0`.
- [x] I tre `exclude_filter` contengono
      `assets/art/characters/*/hd/**`; `.gdignore` presente nella cartella HD.
- [x] Art review isolata: silhouette da piccione immediata, volto dominante,
      palette indaco/magenta/oro coerente e dettagli leggibili a `256×256`.

I profili del runner, l'import Godot e i gate Windows/APK/Pixel 9 appartengono
a PS-129 perché richiedono l'asset collegato al runtime.

## Gate manuali

- [x] Approvazione percettiva del proprietario sul derivato isolato: coerenza
      con lo sprite di gameplay e leggibilità alla scala della Boss intro.

## Decisioni

- **2026-09-07 — Produzione separata dall'integrazione.** Il contratto PS-090
  vieta a una card `art` di modificare `.tres`, test o runtime. I criteri
  originari di wiring e piattaforma sono stati trasferiti a PS-129.
- **2026-09-07 — Direzione visiva non ambigua.** Il personaggio esiste già:
  PS-128 ne produce una resa a piena risoluzione, non un redesign. Lo sprite
  esistente definisce identità e palette; i ritratti Evil definiscono taglio,
  densità, outline ed effetti di famiglia.
- **2026-09-07 — Percorso nella famiglia character.** Il nuovo asset vive sotto
  `assets/art/characters/piccione_malvagio/` così riusa l'esclusione HD già
  comune ai ritratti Player/Evil e mantiene separati sprite di gameplay e busto
  UI.
- **2026-09-07 — Candidato promosso alla prima generazione.** La review non ha
  rilevato difetti che richiedessero rigenerazione: identità, composizione,
  alfa e resa a scala runtime soddisfano il brief. Resta l'approvazione
  percettiva del proprietario.
- **2026-09-07 — Approvazione del proprietario.** Il proprietario ha dichiarato
  il risultato accettabile ("diciamo che va bene"); il gate percettivo isolato
  è quindi chiuso.

## Documenti sincronizzati

- [x] `assets/art/characters/ASSET-MANIFEST.md`.
- [x] `docs/visual-audio-identity.md`: nessuna modifica necessaria; PS-128
      applica la grammatica Evil esistente senza introdurre una regola nuova.

## Note

Il wiring runtime è stato completato separatamente da PS-129. Nessun import
Godot, smoke o gate di piattaforma è stato attribuito retroattivamente a questa
card `art`.
