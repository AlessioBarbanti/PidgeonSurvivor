---
id: PS-170
titolo: Aggiungi un selettore della difficoltà prima della run
tipo: feat
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: [PS-157, PS-158, PS-161]
origine: conversazione del proprietario 2026-09-11
creato: 2026-09-11
aggiornato: 2026-09-20
---

# PS-170 — Aggiungi un selettore della difficoltà prima della run

## Contesto

La Sopravvivenza usa oggi una sola curva autorevole: `EnemySpawnProfile` governa spawn e pressione ordinaria, `WaveEventSchedulerProfile` gli eventi e `GameDirectorProfile` soglie e ricorrenza dei Boss. Il giocatore non può scegliere una difficoltà e la run non registra quale configurazione di bilanciamento è stata usata.

La modalità `NORMALE` deve restare un moltiplicatore neutro sopra la baseline corrente, così le card di ribilanciamento possono continuare a modificare i profili autorevoli senza dover riscrivere il selettore. La difficoltà è una scelta gameplay esplicita e resta separata da `PerformanceProfile`, che non può alterare il bilanciamento in modo invisibile.

## Comportamento atteso

- L'overlay impostazioni guadagna una tab `GIOCO` che mostra un selettore a quattro opzioni: `FACILE`, `NORMALE`, `DIFFICILE`, `PAVONE`, con la descrizione dell'opzione corrente.
- `NORMALE` è selezionato al primo avvio. Ogni modifica viene salvata e riproposta nelle sessioni successive.
- La scelta viene fotografata all'avvio della run e resta immutabile fino alla schermata terminale. Poiché le impostazioni si aprono anche dalla pausa, fuori da `BOOT` il selettore resta visibile ma disabilitato (grigio), con una riga che lo dichiara.
- `RIPROVA` conserva la difficoltà della run appena conclusa: nulla la cambia se non un passaggio esplicito dalle impostazioni.
- Il riepilogo finale mostra la difficoltà accanto a livello e Boss sconfitti.

## Profili iniziali

| ID | Etichetta | Moltiplicatore pressione | Descrizione UI |
|---|---|---:|---|
| `easy` | FACILE | `0,80` | Nemici meno resistenti e meno pericolosi. |
| `normal` | NORMALE | `1,00` | L'esperienza di gioco prevista. |
| `hard` | DIFFICILE | `1,25` | Nemici più resistenti e più pericolosi. |
| `pavone` | PAVONE | `1,60` | Quasi punitivo: solo per chi vuole il massimo. |

Il moltiplicatore si compone con i valori correnti e con le curve temporali già esistenti, e si applica esclusivamente a:

- HP massimi e correnti di nemici ordinari e Boss;
- danno da contatto, proiettili dei tiratori, pattern del Boss e Signature Evil.

Non modifica intervalli o cap di spawn, pesi degli archetipi, eventi d'ondata, soglie/ricorrenza Boss, drop, XP, offerte, rarità o potenza degli upgrade. A parità di seed, l'ordine di spawn, eventi, Boss e offerte resta quindi identico fra i quattro livelli; cambiano soltanto resistenza e pericolosità dei nemici. Il valore di `pavone` è una prima proposta: resta soggetto ad approvazione percettiva del proprietario come gli altri tre, senza vincolo di dover risultare "impossibile" in senso letterale.

## Criteri di accettazione

- [x] Il selettore (impostazioni, tab `GIOCO`) mostra sempre le quattro opzioni, l'opzione corrente e la relativa descrizione.
- [x] Il primo avvio usa `normal`; una scelta valida persiste fra sessioni, mentre un ID mancante/corrotto torna in modo sicuro a `normal`.
- [x] La configurazione vive in Resource dichiarative con ID univoci, etichetta, descrizione e moltiplicatore finito maggiore di zero; la UI non contiene numeri di bilanciamento.
- [x] La difficoltà confermata è uno snapshot immutabile della run: nessun cambio di impostazioni, profilo prestazionale o stato UI la modifica dopo `start_run()`.
- [x] Il moltiplicatore viene applicato una sola volta, dopo i valori baseline e le curve temporali/di ricorrenza, a tutti i percorsi di HP e danno elencati; non altera direttamente statistiche del Player o ricompense.
- [x] Con seed e personaggio uguali, due run alla stessa difficoltà producono la stessa sequenza; fra difficoltà diverse la sequenza resta uguale e variano solo HP/danno secondo `0,80 / 1,00 / 1,25 / 1,60`.
- [x] `RunSummary` conserva ID ed etichetta della difficoltà e l'End Screen la mostra senza consultare sistemi gameplay vivi.
- [x] `RIPROVA` conserva la difficoltà conclusa. La seconda metà del criterio è stata riformulata con lo spostamento nelle impostazioni: non è più il cambio personaggio a permettere la modifica, ma la tab `GIOCO` delle impostazioni, raggiungibile dalla welcome fra una run e l'altra.
- [ ] Selettore, descrizione e focus restano nella safe area e sono utilizzabili con touch, tastiera e gamepad; ogni target touch è almeno `44 px`. **Parziale**: l'altezza minima di 44px è imposta nel codice (`SettingsOverlay.DIFFICULTY_BUTTON_MIN_HEIGHT`) e i bottoni sono focusabili come gli altri controlli del pannello, ma la prova reale con touch e controller è un gate manuale ancora aperto.
- [x] `PerformanceProfile` e le impostazioni grafiche non leggono, scrivono o selezionano la difficoltà.

## Ambito

- Nuove Resource/registry per i quattro profili di difficoltà e persistenza dell'ID selezionato.
- `SettingsOverlay` (tab `GIOCO`) per selettore, descrizione, focus e stato disabilitato durante la run; `MovementSlice` per risoluzione e snapshot scene-local. **`CharacterSelectOverlay` non viene toccato** (vedi Decisioni, 2026-09-20).
- `EnemySpawner` e `BossEncounter` per comporre il moltiplicatore nei punti autorevoli di spawn/configurazione, coprendo anche danni ranged, pattern e Signature.
- `RunSummary` ed `EndScreen` per il dato immutabile e il riepilogo.
- Non introdurre ricompense esclusive, classifiche separate, sblocco progressivo delle difficoltà o modifica della difficoltà dalla pausa.

## Verifica

- GUT: `tests/unit/test_ps170_difficulty_selector.gd` → marker `PS170_DIFFICULTY_SELECTOR_SMOKE_OK`, con persistenza/fallback, snapshot, composizione numerica, copertura ordinari/Boss/ranged/Signature e determinismo della sequenza.
- Regressioni pertinenti: selezione personaggio, restart/cambio personaggio, `RunSummary`, `EnemySpawner`, Boss e profili prestazionali.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows (percorso completo su FACILE/NORMALE/DIFFICILE/PAVONE e riepilogo finale) — **aperto**: gli automatici girano su Windows e pilotano il vero `SettingsOverlay` dentro `MovementSlice`, ma nessuno ha ancora giocato le quattro difficoltà a mano.
- [ ] Validazione statica APK — **aperto**: non eseguita. Nessuna modifica a manifest o export, ma la card la elenca esplicitamente.
- [ ] Runtime fisico Pixel 9 (touch, safe area, persistenza dopo riavvio e restart) — **aperto**: `adb devices` non vede alcun device collegato.
- [ ] Controllo percettivo richiesto: sì, per leggibilità del selettore e differenza percepita fra i quattro livelli — **aperto**: spetta all'agente `direttore-artistico`, che il proprietario invoca esplicitamente. Due punti da guardare in particolare:
  1. la tab bar passa da tre a quattro voci (`GIOCO AUDIO ACCESSIBILITÀ CONTROLLI`) dentro un pannello con minimo 640px: verificare che non si stringano o vadano a capo;
  2. la riga statistiche del riepilogo ha ora quattro segmenti (`FACILE · Livello 12 · 3 Boss sconfitti · 847 piccioni uccisi`) e `StatsLabel` non ha autowrap: con numeri a più cifre il pannello si allarga oltre il suo minimo di 454px e la cornice a texture si stira. Non ho aggiunto `autowrap_mode` perché è una correzione che va vista, non indovinata.

## Decisioni

- **2026-09-20 — Sblocco: la dipendenza registrata era esaurita.** La card era `BLOCCATO` in attesa di PS-157, PS-158 e PS-161 ("la validazione percettiva non deve mascherare una curva Normale ancora instabile"). Tutte e tre risultano `COMPLETATO` in `docs/cards/5_completed/`, quindi il motivo del blocco non esisteva più e la card è stata presa su richiesta esplicita del proprietario.
- **2026-09-20 — Il selettore vive nelle impostazioni, non nella selezione personaggio.** Richiesta del proprietario in corso d'opera: quattro bottoni più una descrizione sopra `GIOCA CON …` rendevano quella schermata troppo affollata. `CharacterSelectOverlay` è 968 righe di geometria tarata al pixel, con budget verticale già dichiarato al limite nei propri commenti (card Passiva/Abilità che si fermano sopra la riga dorata, margini asimmetrici per il ritaglio fotocamera del Pixel 9): aggiungerci due righe avrebbe compresso il busto e le card. L'overlay impostazioni è già paginato per categoria (PS-137) ed è costruito per ospitare nuove voci. Conseguenza accettata: la difficoltà non si conferma più insieme al personaggio, e per cambiarla dopo una run si passa dalla welcome invece che dal selettore personaggi.
- **2026-09-20 — Disabilitata, non nascosta, durante la run.** Le impostazioni si aprono anche dalla pausa. Il selettore resta visibile e grigio invece di sparire: così il giocatore continua a vedere a che difficoltà sta giocando, e il contratto "non modificabile dalla pausa" diventa visibile invece che implicito. Il vincolo è espresso come `stato != BOOT`, letto da `RunController`, non come "sono stato aperto dalla pausa": l'autorità sullo stato resta una sola.
- **2026-09-20 — Il moltiplicatore entra da `pressure_multiplier`, non da un canale nuovo.** `EnemySpawner._apply_post_curve_pressure()` e `BossEncounter._apply_recurrence_scaling()` erano già gli unici due punti che applicano una pressione a HP e danno, e assegnano `BaseEnemy.pressure_multiplier`, che `RangedEnemy` legge per il danno a distanza e `FirstBoss` per raffica radiale, colpo mirato e Signature (PS-126). Comporre la difficoltà dentro quel calcolo copre tutti i percorsi elencati dalla card con una riga per sito, invece di aggiungere un secondo sistema parallelo da tenere allineato.
- **2026-09-11 — Tre livelli espliciti, con NORMALE neutro.** I valori sono relativi alla baseline autorevole e non dipendono dalla chiusura delle card di ribilanciamento.
- **2026-09-13 — Aggiunto un quarto livello `PAVONE` su richiesta del proprietario.** Livello estremo sopra `DIFFICILE`, pensato come sfida quasi punitiva per chi ha già superato gli altri tre; il moltiplicatore `1,60` è una prima proposta soggetta allo stesso gate percettivo degli altri livelli.
- **2026-09-11 — Difficoltà iniziale solo su HP e danno.** Densità, scheduling ed economia restano invariati per preservare leggibilità, determinismo e costo prestazionale.
- **2026-09-11 — Scelta persistente ma bloccata durante la run.** Il giocatore la conferma nella selezione personaggio; restart e riepilogo usano lo snapshot della run.
- **2026-09-11 — Difficoltà e prestazioni restano separate.** Nessun dispositivo riceve una curva più facile per effetto del profilo grafico.
- **2026-09-11 — BLOCCATO dalla baseline Normale.** Il selettore viene sviluppato dopo PS-157, PS-158 e PS-161: i moltiplicatori restano relativi, ma la loro validazione percettiva non deve mascherare una curva Normale o una progressione ancora instabili.

## Documenti sincronizzati

- [x] `docs/prd.md` §3.2A con i quattro profili e la composizione del moltiplicatore.
- [x] `docs/systems-difficulty.md` con autorità, punto di composizione, determinismo e confine rispetto a `PerformanceProfile`.
- [x] `docs/ui-ux-flow.md` con la quarta tab, selettore, persistenza, stato disabilitato e riepilogo.
- [x] `docs/setup.md`: nessuna modifica necessaria. La persistenza usa `user://difficulty_settings.cfg`, scritto a runtime come gli altri `*Settings`; non introduce variabili locali, passi di export o configurazione per chi sviluppa, e `setup.md` non documenta oggi nessuno degli altri file `user://`.

## Note

La prima stesura `DA DEFINIRE` è stata chiusa scegliendo un MVP verificabile: la difficoltà cambia la pressione numerica dei nemici senza moltiplicare contemporaneamente densità, eventi ed economia.

Comandi di verifica eseguiti:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-170 -Profile Focused `
  -FocusedSmoke tests/unit/test_ps170_difficulty_selector.gd -RefreshEditor
.\tools\run-milestone-checks.ps1 -Milestone PS-170 -Profile Relevant `
  -FocusedSmoke tests/unit/test_ps170_difficulty_selector.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-170 -Profile Full
```

Esiti: `Focused` PASS (4/4 test, 65 assert), `Relevant` PASS (94/94 script,
312/312 test), `Full` PASS (160/160 script, 503/503 test, toolchain PASS).
Nessun `SCRIPT ERROR` né `FATAL EXCEPTION` nei log. Marker
`PS170_DIFFICULTY_SELECTOR_SMOKE_OK` presente.

I quattro casi dello smoke:

- `test_difficulty_choice_persists_and_falls_back_to_normal` — tre sessioni
  simulate su un `DifficultySettings` con file dedicato
  (`user://test_ps170_difficulty.cfg`, non quello del giocatore): primo avvio
  su `normal`, `hard` che sopravvive alla sessione, id inesistente nel file
  che ricade su `normal` senza profilo nullo.
- `test_difficulty_selector_shows_every_option_and_greys_out_during_a_run` —
  le quattro etichette nell'ordine dichiarato, opzione corrente, descrizione
  non vuota, tutti i bottoni `disabled` mentre la run gira e di nuovo attivi
  dopo il ritorno in `BOOT`.
- `test_difficulty_scales_pressure_without_changing_the_spawn_sequence` — due
  run allo stesso seed su `easy` e `hard`: sequenza di posizioni di spawn
  identica, e su ogni nemico il rapporto di HP pari a 1.25/0.80 = 1.5625.
- `test_run_difficulty_is_an_immutable_snapshot_shown_in_the_recap` —
  snapshot su spawner e Boss, immutabile quando le impostazioni cambiano a
  run avviata, etichetta nel riepilogo, più un `RunSummary` costruito a mano
  che dimostra che `EndScreen` disegna la riga dal solo snapshot.

Nuova regola in `tools/milestone-test-map.json` che lega lo smoke a tutti i
file toccati (profili, `DifficultySettings`, `SettingsOverlay` e la sua
scena, `EnemySpawner`, `BossEncounter`, `MovementSlice`, `RunSummary`,
`EndScreen`).
