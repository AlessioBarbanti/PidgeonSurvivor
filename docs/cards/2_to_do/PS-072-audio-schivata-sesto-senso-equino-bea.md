---
id: PS-072
titolo: Dai un audio alla schivata Sesto Senso Equino di Bea
tipo: feat
area: audio
stato: PRONTO
priorita: media
dipende_da: []
origine: B45
creato: 2026-09-02
aggiornato: 2026-09-02
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

- [ ] `GameAudio` si collega a `instinctive_dodge_triggered` e riproduce il cue
      `DODGE` quando scatta.
- [ ] `has_complete_cue_set()` include `DODGE` fra i cue verificati.
- [ ] Il suono è udibile in sincrono con la comparsa dell'accento visivo
      (`InstinctiveDodgeAccent`), senza ritardo percepibile.
- [ ] Personaggi diversi da Bea, che non hanno questa passiva, non generano mai
      il cue.
- [ ] Schivate ravvicinate (ai limiti del cooldown di 9 secondi della passiva)
      non producono sovrapposizione fastidiosa o distorsione.
- [ ] Con audio disattivato o volume a zero non è udibile alcun suono.
- [ ] Il cue riusa uno stream CC0 già presente in `assets/audio/` se ne esiste
      uno adatto al tono (scarto/whoosh); altrimenti ne integra uno nuovo,
      seguendo `asset-pipeline`, con riga nel manifest di cartella.

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
  che con audio disattivato non ci sia riproduzione.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: gioca con Bea fino a far scattare la passiva più
      volte, con le cuffie
- [ ] Controllo percettivo richiesto: sì — il suono deve leggersi come
      "schivata/scarto", non come un hit o un pickup

## Decisioni

- **2026-09-02 — Il gap era già dichiarato nel codice, non dedotto.** Il
  commento in `game_audio.gd` documentava da tempo l'attesa di un asset
  dedicato; questa card la chiude.
- **2026-09-02 — Sblocco del vincolo "nessun nuovo asset audio".** Non è mai
  stata una regola di progetto: era una scelta di scope di PS-056 per quella
  sola card. Qui un nuovo asset audio, se serve, è ammesso.

## Documenti sincronizzati

- [ ] `docs/visual-audio-identity.md`: rimuovere `DODGE` dall'elenco delle
      mancanze dichiarate una volta chiuso.

## Note

Se nessuno stream CC0 esistente in `assets/audio/` regge il tono richiesto,
integrarne uno nuovo è preferibile a forzare un riuso che suoni sbagliato.
