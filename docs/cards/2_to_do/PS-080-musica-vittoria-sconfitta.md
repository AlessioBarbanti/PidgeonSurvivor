---
id: PS-080
titolo: Aggiungi una musica dedicata a vittoria e sconfitta
tipo: feat
area: audio
stato: PRONTO
priorita: media
dipende_da: []
origine:
creato: 2026-09-02
aggiornato: 2026-09-02
---

# PS-080 — Aggiungi una musica dedicata a vittoria e sconfitta

## Contesto

Oggi `VICTORY` e `DEFEAT` sono due cue SFX brevi
([scripts/audio/game_audio.gd:471-476](../../../scripts/audio/game_audio.gd#L471-L476)):
alla fine della run la musica si ferma (`stop_background_music()`) e parte
solo un suono puntuale, dello stesso tipo di `HIT` o `PICKUP`. La schermata
finale ([PS-053](./4_to_test/PS-053-riepilogo-finale-della-run.md), un
riepilogo della run) chiude quindi la sessione senza un vero momento
musicale, mentre gli altri eventi di rilievo (level-up, ricompensa Barb,
Boss) hanno già o stanno per avere una risposta audio dedicata.

## Comportamento atteso

Alla fine della run parte una breve musica dedicata, distinta dal semplice
cue SFX: trionfale per la vittoria, dimessa per la sconfitta. Suona una
volta sola, non in loop, e si interrompe in modo pulito rispetto a qualunque
musica precedente (di run, Boss, o menu).

## Criteri di accettazione

- [ ] Alla `VICTORY` parte una breve traccia musicale trionfale.
- [ ] Alla `DEFEAT` parte una breve traccia musicale dimessa.
- [ ] Qualunque musica in corso (run, Boss dedicata di PS-073, menu) si
      interrompe senza sovrapposizione prima che parta la musica di fine
      run.
- [ ] La musica di fine run non è in loop: si esaurisce naturalmente o si
      interrompe alla chiusura della schermata finale, mai a metà in modo
      brusco durante la sua riproduzione normale.
- [ ] Restart dopo la fine della run interrompe correttamente la musica di
      fine run, senza lasciarla sovrapposta alla musica di menu o di una
      nuova run.
- [ ] Con audio disattivato o volume a zero non è udibile alcun suono.
- [ ] I due nuovi asset musicali sono integrati con `asset-pipeline` e
      registrati nel manifest di `assets/audio/`.
- [ ] La scelta di mantenere, sostituire o affiancare i cue SFX
      `VICTORY`/`DEFEAT` esistenti è dichiarata esplicitamente nelle
      Decisioni della card al momento dell'implementazione.

## Ambito

- `scripts/audio/game_audio.gd`: nuovo player o riuso del pattern esistente
  per la musica di fine run, connessione a `run_ended`.
- `assets/audio/`: due nuovi file musicali (vittoria, sconfitta) + riga
  manifest.

Non toccare:

- `RunController` e l'arbitraggio degli stati terminali;
- contenuto e layout della schermata di riepilogo (PS-053);
- la logica di restart.

## Verifica

- Smoke: `tests/unit/test_ps080_end_run_music.gd` → marker
  `END_RUN_MUSIC_SMOKE_OK` — verifica che `VICTORY`/`DEFEAT` avviino la
  musica dedicata, che qualunque musica precedente si interrompa senza
  sovrapposizione, che il restart la interrompa e che con audio disattivato
  non ci sia riproduzione.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso sconfitta: gioca fino alla morte,
      ascolta la musica dimessa; percorso vittoria: **non raggiungibile in
      un playthrough reale oggi**, vedi Decisioni — verificabile solo via
      `RunController.request_victory()` da test/debug)
- [ ] Controllo percettivo richiesto: sì per la sconfitta (raggiungibile in
      gioco); rimane aperto per la vittoria finché non esiste un percorso di
      gioco reale che la raggiunga

## Decisioni

- **2026-09-02 — Scelta come primo evento musicale nuovo.** Nato dalla
  discussione sugli "eventi audio mancanti" insieme a PS-073 (musica Boss)
  e PS-081 (intensità late-run); il proprietario ha scelto Vittoria/Sconfitta
  come priorità.
- **2026-09-02 — `VICTORY` non è ancora raggiungibile in gioco.**
  `docs/systems-difficulty.md` dichiara esplicitamente che
  `request_victory()` non è chiamato da nessuno script di produzione nella
  vertical slice attuale: la condizione di vittoria dipende da
  [PS-055](./1_idea/PS-055-filosofia-della-vittoria.md) (`DA DEFINIRE`).
  Questa card implementa e verifica comunque il comportamento via API/test:
  il gate percettivo reale su un vero playthrough di vittoria resta aperto
  finché PS-055 non è risolta, dichiarato onestamente come tale invece di
  essere aggirato o chiuso in anticipo.

## Documenti sincronizzati

- [ ] `docs/visual-audio-identity.md`: musica di fine run.

## Note

Se in implementazione risultasse più semplice riusare i cue SFX esistenti
come "coda" della nuova musica invece di sostituirli, è una scelta legittima
purché dichiarata: il criterio richiede solo che la scelta sia esplicita, non
una direzione specifica fra le due.
