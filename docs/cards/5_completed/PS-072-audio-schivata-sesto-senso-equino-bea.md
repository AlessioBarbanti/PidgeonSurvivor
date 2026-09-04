---
id: PS-072
titolo: Dai un audio alla schivata Sesto Senso Equino di Bea
tipo: feat
area: audio
stato: COMPLETATO
priorita: media
dipende_da: []
origine: B45
creato: 2026-09-02
aggiornato: 2026-09-04
---

# PS-072 — Dai un audio alla schivata Sesto Senso Equino di Bea

## Contesto

Il cue `DODGE` esiste già come costante in
[scripts/audio/game_audio.gd:29](../../../scripts/audio/game_audio.gd#L29), con
tanto di commento che ne dichiara lo stato: *"resta un no-op silenzioso finché
non arriva un asset dedicato"*. `has_complete_cue_set()` lo esclude
esplicitamente dai 14 cue verificati. Il trigger esiste già ed è quello giusto:
`FriendPassiveController.instinctive_dodge_triggered`
([scripts/content/friend_passive_controller.gd:16](../../../scripts/content/friend_passive_controller.gd#L16)),
già collegato in `movement_slice.gd` per far comparire l'accento visivo
`InstinctiveDodgeAccent` (sagoma a ferro di cavallo + scia viola). `GameAudio`
non ascolta però quel segnale: la schivata di Bea (Sesto Senso Equino, ogni 9
secondi annulla il colpo in arrivo) resta muta.

## Comportamento atteso

Quando la passiva di Bea scatta, un suono distinto e riconoscibile accompagna
l'accento visivo esistente, con lo stesso tempismo.

## Criteri di accettazione

- [x] `GameAudio` si collega a `instinctive_dodge_triggered` e riproduce il cue
      `DODGE` quando scatta. Il collegamento vive gia' in `movement_slice.gd`
      (`_on_instinctive_dodge_triggered`, coerente con com'e' gia' cablato
      `UI_CONFIRM`); mancava solo lo stream, ora assegnato.
- [x] `has_complete_cue_set()` include `DODGE` fra i cue verificati.
- [x] Il suono è udibile in sincrono con la comparsa dell'accento visivo
      (`InstinctiveDodgeAccent`), senza ritardo percepibile. Confermato
      dal proprietario con le cuffie (vedi Gate manuali).
- [x] Personaggi diversi da Bea, che non hanno questa passiva, non generano mai
      il cue.
- [x] Schivate ravvicinate (ai limiti del cooldown di 9 secondi della passiva)
      non producono sovrapposizione fastidiosa o distorsione. Garantito a
      livello strutturale dal cooldown di 9s della passiva stessa (non e'
      possibile ritriggerare piu' spesso); confermato anche a orecchio dal
      proprietario.
- [x] Con audio disattivato o volume a zero non è udibile alcun suono
      (stessa garanzia gia' in uso per gli altri 14 cue, coperta dallo smoke).
- [x] Il cue riusa uno stream CC0 già presente in `assets/audio/` se ne esiste
      uno adatto al tono (scarto/whoosh); altrimenti ne integra uno nuovo,
      seguendo `asset-pipeline`, con riga nel manifest di cartella. Nessuno
      stream esistente reggeva il tono "scarto": integrato `dodge.wav` (CC0,
      Swishes Sound Pack di artisticdude).

## Ambito

- `scripts/audio/game_audio.gd`: connessione al segnale, esportazione/assegnazione
  di `dodge_stream`, aggiornamento di `has_complete_cue_set()`.
- `assets/audio/`, solo se serve un nuovo stream: nuovo file + riga
  `ASSET-MANIFEST.md`.

Non toccare:

- `scripts/content/friend_passive_controller.gd` (logica del trigger e del
  cooldown della passiva);
- `scripts/abilities/instinctive_dodge_accent.gd` (l'accento visivo esistente,
  già approvato);
- bilanciamento della passiva (cooldown, invulnerabilità).

## Verifica

- Smoke: `tests/unit/test_ps072_bea_dodge_audio.gd` → marker
  `BEA_DODGE_AUDIO_SMOKE_OK` — verifica che il segnale produca il cue, che
  `has_complete_cue_set()` lo includa, che altri personaggi non lo attivino e
  che con audio disattivato o a volume zero non ci sia riproduzione.
- `Profile Focused` eseguito: verde, nessun `SCRIPT ERROR`/`FATAL EXCEPTION`
  nel log (`gut-focused.log`, marker presente).
- `Profile Relevant` **non completato**: il primo tentativo ha incontrato
  un'interferenza di un'altra sessione che lavorava in parallelo su PS-073
  sugli stessi file condivisi (`scenes/game/movement_slice.tscn`,
  `scripts/audio/game_audio.gd`) — un parse error transitorio su una risorsa
  audio non ancora atterrata su disco nello stesso istante. Su richiesta del
  proprietario i tentativi successivi sono stati saltati: la validazione
  resta manuale.

## Gate manuali

- [x] Runtime Windows
- [x] Validazione statica APK
- [x] Runtime fisico Pixel 9: gioca con Bea fino a far scattare la passiva più
      volte, con le cuffie
- [x] Controllo percettivo richiesto: sì — il suono deve leggersi come
      "schivata/scarto", non come un hit o un pickup

## Decisioni

- **2026-09-02 — Il gap era già dichiarato nel codice, non dedotto.** Il
  commento in `game_audio.gd` documentava da tempo l'attesa di un asset
  dedicato; questa card la chiude.
- **2026-09-02 — Sblocco del vincolo "nessun nuovo asset audio".** Non è mai
  stata una regola di progetto: era una scelta di scope di PS-056 per quella
  sola card. Qui un nuovo asset audio, se serve, è ammesso.
- **2026-09-04 — Nessuno stream esistente reggeva il tono.** I 14 SFX Kenney
  gia' in repo sono tutti da combattimento/interfaccia (colpo, pickup,
  conferma...); nessuno si legge come uno scarto/whoosh. Scaricato lo
  Swishes Sound Pack CC0 di artisticdude da OpenGameArt e scelto `swish-9`
  (il piu' lungo dei tredici, ~0.20s): gli altri sono tagli piu' secchi che
  rischiavano di leggersi come un tick/hit, contro il criterio esplicito
  "non come un hit o un pickup".
- **2026-09-04 — Ricodificato in `.ogg` per coerenza col resto di
  `assets/audio/`.** Il primo integro era rimasto `.wav` perche' nell'ambiente
  non c'era un transcoder ogg disponibile; su richiesta del proprietario
  installato `ffmpeg` (winget, `Gyan.FFmpeg`) e ricodificato con
  `ffmpeg -c:a libvorbis -q:a 6`. Il `.wav` intermedio non e' stato tenuto nel
  repository (nessuna distinzione master/derivato per gli asset audio di
  questo progetto, per precedente in `kenney_b18`, `congusbongus_b29` ecc.).
- **2026-09-04 — Verifica automatica fermata a `Focused` su richiesta del
  proprietario.** Il primo tentativo di `Relevant` ha incrociato un'altra
  sessione che editava in parallelo `movement_slice.tscn` e `game_audio.gd`
  per PS-073 (musica Boss dedicata): un asset non ancora scritto su disco ha
  prodotto un parse error transitorio, non imputabile a questa card. Il
  proprietario ha chiesto di saltare ulteriori esecuzioni del runner e di
  procedere con validazione manuale.

## Documenti sincronizzati

- [x] `docs/visual-audio-identity.md`: rimuovere `DODGE` dall'elenco delle
      mancanze dichiarate una volta chiuso.

## Note

Se nessuno stream CC0 esistente in `assets/audio/` regge il tono richiesto,
integrarne uno nuovo è preferibile a forzare un riuso che suoni sbagliato.
