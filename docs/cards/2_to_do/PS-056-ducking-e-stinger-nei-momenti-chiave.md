---
id: PS-056
titolo: Aggiungere ducking e stinger su warning, Boss e ricompensa Barb
tipo: feat
area: audio
stato: PRONTO
priorita: bassa
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-08-31
---

# PS-056 — Aggiungere ducking e stinger su warning, Boss e ricompensa Barb

## Contesto

L'audio ha già i mattoni: bus `SFX` e `Music` separati, una musica di fondo a
`-7 dB` e un set completo di cue fra cui `boss_warning`, `boss_attack`,
`level_up` e `victory`
([scripts/audio/game_audio.gd:9-34](../../../scripts/audio/game_audio.gd#L9-L34)).
Quello che manca è la dinamica: la musica scorre alla stessa intensità durante
un'ondata normale, un avvertimento Boss e la ricompensa di Barb, quindi i
momenti chiave non si sentono diversi.

La review chiede variazioni leggere, non nuove tracce complete.

## Comportamento atteso

Nei tre momenti chiave la musica si abbassa per lasciare spazio a uno stinger e
poi risale: l'avvertimento dell'arrivo del Boss, l'intro del Boss e la
schermata di ricompensa di Barb. Il ritorno al volume normale è graduale e non
lascia mai la musica muta per errore.

## Criteri di accettazione

- [ ] All'avvertimento di arrivo del Boss il volume della musica scende e
      risale entro una durata definita in modo centralizzato.
- [ ] All'ingresso in `BOSS_INTRO` la musica è abbassata e uno stinger è
      udibile sopra di essa.
- [ ] All'ingresso in `BARB_REWARD` la musica è abbassata e uno stinger è
      udibile sopra di essa.
- [ ] Alla chiusura di ciascuno dei tre momenti la musica torna esattamente al
      volume precedente.
- [ ] Due momenti sovrapposti o ravvicinati non producono un doppio abbassamento
      cumulativo né lasciano la musica abbassata in modo permanente.
- [ ] Con l'audio disattivato o il volume a zero, il ducking non riporta alcun
      suono udibile.
- [ ] Restart, sconfitta e cambio personaggio durante un ducking riportano il
      volume allo stato di partenza.
- [ ] Le durate del ducking sono timing di presentazione e vivono in
      `scripts/vfx/presentation_timings.gd`, non sparse nei chiamanti.
- [ ] Nessuna nuova traccia musicale completa viene aggiunta.
- [ ] Gli stinger riusano cue già presenti in `assets/audio/`; se un cue viene
      riproposto in un contesto nuovo, il manifest lo registra.

## Ambito

- `scripts/audio/game_audio.gd`, per il controllo del volume del bus `Music` e
  la riproduzione degli stinger.
- `scripts/vfx/presentation_timings.gd`, per le durate.
- `scripts/game/movement_slice.gd`, solo per collegare gli stati del
  `RunController` alle richieste audio.

Non toccare:

- l'autorità del `RunController` sugli stati e sull'arbitraggio dei modali;
- la persistenza delle impostazioni audio e il significato di mute e volume;
- il bilanciamento e i tempi di gioco: il ducking non deve introdurre attese;
- `PerformanceProfile`.

## Verifica

- Smoke: `tests/unit/test_ps056_audio_ducking.gd` → marker
  `AUDIO_DUCKING_SMOKE_OK` — verifica abbassamento e ripristino nei tre
  momenti, assenza di accumulo su eventi sovrapposti, ripristino su restart e
  sconfitta e silenzio totale con audio disattivato.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run fino all'avvertimento Boss, intro,
      sconfitta del Boss e schermata di ricompensa Barb, ascoltando con le
      cuffie)
- [ ] Controllo percettivo richiesto: sì — il ducking deve farsi notare senza
      diventare fastidioso.

## Decisioni

- **2026-08-31 — Nessuna nuova traccia.** La review chiede esplicitamente
  variazioni leggere; il costo di produzione musicale non è giustificato prima
  dei playtest di ritmo.
- **2026-08-31 — Il ducking è un timing di presentazione.** Le durate stanno
  con gli altri timing di presentazione, separate dai valori di gameplay.

## Documenti sincronizzati

- [ ] `docs/visual-audio-identity.md`: dinamica audio dei momenti chiave.

## Note

Se un cue esistente non regge come stinger in uno dei tre momenti, aprire una
card separata per il cue mancante invece di allargare questa.
