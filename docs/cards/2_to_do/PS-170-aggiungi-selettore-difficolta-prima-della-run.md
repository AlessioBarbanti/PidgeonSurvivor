---
id: PS-170
titolo: Aggiungi un selettore della difficoltà prima della run
tipo: feat
area: gameplay
stato: BLOCCATO
priorita: media
dipende_da: [PS-157, PS-158, PS-161]
origine: conversazione del proprietario 2026-09-11
creato: 2026-09-11
aggiornato: 2026-09-13
---

# PS-170 — Aggiungi un selettore della difficoltà prima della run

## Contesto

La Sopravvivenza usa oggi una sola curva autorevole: `EnemySpawnProfile` governa spawn e pressione ordinaria, `WaveEventSchedulerProfile` gli eventi e `GameDirectorProfile` soglie e ricorrenza dei Boss. Il giocatore non può scegliere una difficoltà e la run non registra quale configurazione di bilanciamento è stata usata.

La modalità `NORMALE` deve restare un moltiplicatore neutro sopra la baseline corrente, così le card di ribilanciamento possono continuare a modificare i profili autorevoli senza dover riscrivere il selettore. La difficoltà è una scelta gameplay esplicita e resta separata da `PerformanceProfile`, che non può alterare il bilanciamento in modo invisibile.

## Comportamento atteso

- La schermata di selezione personaggio mostra, sopra il pulsante `GIOCA CON …`, un selettore a quattro opzioni: `FACILE`, `NORMALE`, `DIFFICILE`, `PAVONE`.
- `NORMALE` è selezionato al primo avvio. Ogni modifica viene salvata e riproposta nelle sessioni successive; premere `GIOCA CON …` conferma insieme personaggio e difficoltà.
- La scelta viene fotografata all'avvio della run e resta immutabile fino alla schermata terminale. Non è modificabile dalla pausa.
- `RIPROVA` conserva la difficoltà della run appena conclusa; `CAMBIA PERSONAGGIO` riapre il selettore sull'ultima scelta.
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

- [ ] Il selettore mostra sempre le quattro opzioni, l'opzione corrente e la relativa descrizione prima dell'avvio della run.
- [ ] Il primo avvio usa `normal`; una scelta valida persiste fra sessioni, mentre un ID mancante/corrotto torna in modo sicuro a `normal`.
- [ ] La configurazione vive in Resource dichiarative con ID univoci, etichetta, descrizione e moltiplicatore finito maggiore di zero; la UI non contiene numeri di bilanciamento.
- [ ] La difficoltà confermata è uno snapshot immutabile della run: nessun cambio di impostazioni, profilo prestazionale o stato UI la modifica dopo `start_run()`.
- [ ] Il moltiplicatore viene applicato una sola volta, dopo i valori baseline e le curve temporali/di ricorrenza, a tutti i percorsi di HP e danno elencati; non altera direttamente statistiche del Player o ricompense.
- [ ] Con seed e personaggio uguali, due run alla stessa difficoltà producono la stessa sequenza; fra difficoltà diverse la sequenza resta uguale e variano solo HP/danno secondo `0,80 / 1,00 / 1,25 / 1,60`.
- [ ] `RunSummary` conserva ID ed etichetta della difficoltà e l'End Screen la mostra senza consultare sistemi gameplay vivi.
- [ ] `RIPROVA` conserva la difficoltà conclusa; il cambio personaggio permette di modificarla prima della nuova run.
- [ ] Selettore, descrizione e focus restano nella safe area e sono utilizzabili con touch, tastiera e gamepad; ogni target touch è almeno `44 px`.
- [ ] `PerformanceProfile` e le impostazioni grafiche non leggono, scrivono o selezionano la difficoltà.

## Ambito

- Nuove Resource/registry per i quattro profili di difficoltà e persistenza dell'ID selezionato.
- `CharacterSelectOverlay` per selettore, descrizione, focus e conferma; `MovementSlice` per risoluzione e snapshot scene-local.
- `EnemySpawner` e `BossEncounter` per comporre il moltiplicatore nei punti autorevoli di spawn/configurazione, coprendo anche danni ranged, pattern e Signature.
- `RunSummary` ed `EndScreen` per il dato immutabile e il riepilogo.
- Non introdurre ricompense esclusive, classifiche separate, sblocco progressivo delle difficoltà o modifica della difficoltà dalla pausa.

## Verifica

- GUT: `tests/unit/test_ps170_difficulty_selector.gd` → marker `PS170_DIFFICULTY_SELECTOR_SMOKE_OK`, con persistenza/fallback, snapshot, composizione numerica, copertura ordinari/Boss/ranged/Signature e determinismo della sequenza.
- Regressioni pertinenti: selezione personaggio, restart/cambio personaggio, `RunSummary`, `EnemySpawner`, Boss e profili prestazionali.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows (percorso completo su FACILE/NORMALE/DIFFICILE/PAVONE e riepilogo finale)
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (touch, safe area, persistenza dopo riavvio e restart)
- [ ] Controllo percettivo richiesto: sì, per leggibilità del selettore e differenza percepita fra i quattro livelli

## Decisioni

- **2026-09-11 — Tre livelli espliciti, con NORMALE neutro.** I valori sono relativi alla baseline autorevole e non dipendono dalla chiusura delle card di ribilanciamento.
- **2026-09-13 — Aggiunto un quarto livello `PAVONE` su richiesta del proprietario.** Livello estremo sopra `DIFFICILE`, pensato come sfida quasi punitiva per chi ha già superato gli altri tre; il moltiplicatore `1,60` è una prima proposta soggetta allo stesso gate percettivo degli altri livelli.
- **2026-09-11 — Difficoltà iniziale solo su HP e danno.** Densità, scheduling ed economia restano invariati per preservare leggibilità, determinismo e costo prestazionale.
- **2026-09-11 — Scelta persistente ma bloccata durante la run.** Il giocatore la conferma nella selezione personaggio; restart e riepilogo usano lo snapshot della run.
- **2026-09-11 — Difficoltà e prestazioni restano separate.** Nessun dispositivo riceve una curva più facile per effetto del profilo grafico.
- **2026-09-11 — BLOCCATO dalla baseline Normale.** Il selettore viene sviluppato dopo PS-157, PS-158 e PS-161: i moltiplicatori restano relativi, ma la loro validazione percettiva non deve mascherare una curva Normale o una progressione ancora instabili.

## Documenti sincronizzati

- [ ] `docs/prd.md` con i quattro profili e la composizione del moltiplicatore.
- [ ] `docs/systems-difficulty.md` con autorità, determinismo e confine rispetto ai profili esistenti.
- [ ] `docs/ui-ux-flow.md` con selettore, persistenza, conferma, restart e riepilogo.
- [ ] `docs/setup.md` soltanto se la persistenza richiede una chiave/configurazione documentata.

## Note

La prima stesura `DA DEFINIRE` è stata chiusa scegliendo un MVP verificabile: la difficoltà cambia la pressione numerica dei nemici senza moltiplicare contemporaneamente densità, eventi ed economia.
