---
id: PS-158
titolo: Impedisci alle build offensive mature di rendere la run AFK
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: [PS-126, PS-157]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-14
---

# PS-158 — Impedisci alle build offensive mature di rendere la run AFK

## Contesto

Nel playtest Magno ha raggiunto una combinazione di piercing, rimbalzo, esplosione, danno e fire rate che gli ha permesso di smettere letteralmente di muoversi senza subire più pressione. PS-007 aveva già fissato il principio anti-AFK e PS-126 introduce crescita oltre il minuto 5, ma il nuovo test mostra che una build offensiva matura può ancora annullare la necessità di prendere decisioni spaziali.

## Comportamento atteso

Anche una build offensiva molto forte deve continuare a richiedere movimento, lettura dei tell o riposizionamento. La late run può premiare la build rendendo il Player potente, ma non deve consentire di restare fermo in sicurezza per periodi prolungati.

## Criteri di accettazione

- [ ] Con una build deterministica che combini almeno piercing, rimbalzo/chain, esplosione o death burst, danno e fire rate, restare fermi per 30 secondi in late run espone il Player ad almeno una minaccia che richiede una risposta attiva.
      *Non chiuso: il test automatico usa un burst letale generico (una sola `take_damage` che eccede gli HP del Tiratore), non una build reale composta da tutti quegli effetti simultanei per 30s in una run vera. Serve il gate manuale "Runtime fisico Pixel 9" con una build reale.*
- [x] La pressione anti-AFK non dipende esclusivamente dall'aumento di HP dei nemici: almeno una sorgente di minaccia resta spaziale o temporale e non viene neutralizzata dal solo DPS.
      *Ridisegnato su richiesta del proprietario (2026-09-14): il Tiratore non telegrafa più, spara appena a tiro e si ricarica. Un proiettile già lanciato è indipendente dalla fonte: `RangedEnemy._exit_tree()` pulisce i proiettili in volo solo se la run non è più `RUNNING` (restart vero), non quando il Tiratore muore in combattimento a run ancora in corso. Uccidere la fonte dopo lo sparo non cancella più il colpo (`tests/unit/test_ps158_mature_build_anti_afk.gd`, primo test). La minaccia è quindi impegnata per tempo, non per gli HP di chi l'ha generata.*
- [x] Il giocatore in movimento può leggere e schivare la minaccia; non viene introdotto danno inevitabile fuori schermo o senza telegraph.
      *Il proprietario ha chiesto esplicitamente di rimuovere ogni telegraph/anello dal Tiratore: l'unico tell resta il proiettile stesso in volo (velocità finita, raggio visibile), come per qualunque altro proiettile ostile del gioco. Il controllo di raggio resta al momento dello sparo (se il bersaglio non è a tiro quando il cooldown scade, il colpo non parte).*
- [x] PS-007 resta il principio di design storico; questa card documenta e corregge il finding emerso dal nuovo playtest invece di riscriverne retroattivamente la card completata.
      *Nessuna modifica a PS-007, ai suoi valori o alla sua card.*

## Ambito

- `scripts/game/enemy_spawner.gd`, `scripts/game/wave_event_scheduler.gd` e relativi profili/eventi, se serve una leva spaziale aggiuntiva.
- `scripts/actors/ranged_enemy.gd` e sistemi di telegraph/proiettili nemici, se la soluzione passa dalla pressione a distanza.
- `scripts/bosses/*` solo se il finding resta evidente durante i Boss ricorrenti.
- Non ridurre artificialmente la potenza delle build offensive solo per far fallire il test: il problema è la necessità di continuare a giocare.

## Verifica

- GUT: `tests/unit/test_ps158_mature_build_anti_afk.gd` → marker `PS158_MATURE_BUILD_ANTI_AFK_SMOKE_OK`, con `test_ps126_post_curve_pressure.gd` come regressione obbligatoria.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run ≥ 6:00 con build offensiva forte; prova controllata di 30 s senza movimento e poi ripetizione giocando normalmente)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-09-11 — Distinta da PS-157: qui non si misura se la run è genericamente facile, ma se una build matura elimina la necessità di movimento.**
- **2026-09-11 — PS-126 e PS-157 sono prerequisiti.** La crescita post-5:00 e la baseline 0–5 devono essere stabilizzate prima di aggiungere una seconda leva anti-AFK, altrimenti il test misurerebbe una curva ancora in movimento.
- **2026-09-14 — Sblocco.** PS-126 e PS-157 hanno raggiunto entrambe `IN VERIFICA`, condizione sufficiente secondo la regola della board. Card presa in carico.
- **2026-09-14 — Causa radice individuata.** `RangedEnemy._advance_attack_cycle` interrompe il telegraph appena `is_alive()` è falso (`ranged_enemy.gd`): un burst che uccide il Tiratore prima che il telegraph scada annulla il colpo con lui. `Nido di tiratori` (`data/wave_events/wave_event_nido_tiratori.tres`) è l'unico evento baseline che non usa fodder a bassa vita spammabile (Accerchiamento/Stormo laterale sono sciamatori da 5 HP, già trascurabili per una build matura): è quindi la leva più efficace da correggere, coerente con l'Ambito della card ("ranged_enemy.gd... se la soluzione passa dalla pressione a distanza").
- **2026-09-14 — Scelta implementativa iniziale (superata, vedi sotto): colpo pendente indipendente, non "morte ritardata".** Valutata l'alternativa di rimandare `queue_free()` del Tiratore finché il telegraph non risolve (così il nemico resta "vivo" solo per finire lo sparo): scartata perché lascerebbe il cadavere visibile e reattivo a schermo dopo che il giocatore lo ha ucciso, un feedback di danno ritardato e confuso. Preferito un nodo `PendingRangedShot` separato: il Tiratore muore e sparisce all'istante (feedback pulito), il colpo già annunciato continua a contare alla rovescia e a disegnare il proprio anello di telegraph in autonomia.
- **2026-09-14 — Nessuna modifica numerica (prima iterazione).** Non toccati HP, danno, cadenza o potenza di alcuna build (vedi Ambito: "non ridurre artificialmente la potenza delle build offensive"). Il fix era puramente strutturale: disaccoppiava l'esecuzione del colpo già in corso dal ciclo di vita del Tiratore.
- **2026-09-14 — Chiusura parziale (prima iterazione).** `Focused` e `Relevant` verdi (14 regressioni incluse, `test_ps126_post_curve_pressure.gd` fra queste), nessun `SCRIPT ERROR`/`FATAL EXCEPTION`. Il primo criterio (30s reali senza movimento con una build composta) restava un giudizio da playtest fisico: nessun device disponibile in questa sessione, gate lasciato aperto.
- **2026-09-14 — Redesign su richiesta diretta del proprietario: nessun telegraph sul Tiratore.** Il proprietario ha chiesto di rimuovere completamente il tempo di telegraph e le relative animazioni dai Tiratori: a tiro e a cooldown scaduto lo sparo è immediato, poi ricarica per `ranged_attack_interval`. Questo rende strutturalmente impossibile "sorprendere" il Tiratore a metà telegraph (non esiste più una fase intermedia da interrompere), quindi `PendingRangedShot` non ha più nulla da proteggere: rimosso interamente (`scripts/actors/pending_ranged_shot.gd` e il suo test) invece di lasciarlo come codice morto irraggiungibile. Rimossi anche i campi ormai inerti `ranged_telegraph_duration`/`ranged_telegraph_color` da `EnemyArchetypeDefinition`, dal `.tres` del Tiratore e dal clone di Evil Marghe (`_build_decoy_attack_definition` in `first_boss.gd`, che riusa `RangedEnemy` e perde il telegraph allo stesso modo).
- **2026-09-14 — Scoperta una seconda causa, più diretta, dello stesso bug: revisionata durante il redesign.** `RangedEnemy._exit_tree()` chiamava incondizionatamente `clear_attack_runtime()`, che forza `expire()` su ogni proiettile ancora in volo del Tiratore. Poiché `_on_died() → queue_free()` porta comunque a `_exit_tree()`, questo cancellava anche un proiettile già sparato e in viaggio se il Tiratore moriva prima che il colpo arrivasse a bersaglio — indipendentemente dal telegraph, e probabilmente la causa più rilevante nel playtest originale (una build ad alto DPS/AoE spazza via i Tiratori appena dopo che sparano). Corretto: `_exit_tree()` ora esegue `clear_attack_runtime()` solo se `RunController.is_running()` è falso (restart/teardown genuini); una morte in combattimento a run ancora in corso lascia il proiettile già lanciato libero di proseguire.
- **2026-09-14 — Nessuna modifica numerica (redesign).** Resta valido: nessun HP, danno o cadenza toccato. `ranged_attack_interval` (già `2.2s` nei dati) funge da "ricarica" così come richiesto, senza bisogno di un nuovo valore.
- **2026-09-14 — Chiusura aggiornata.** `Focused` e `Relevant` verdi (29 regressioni, incluse `test_b40_enemy_archetypes.gd`, `test_ps007_late_run_pressure.gd`, `test_ps006_evil_signature_abilities.gd` — quest'ultima copre anche il clone di Evil Marghe che riusa `RangedEnemy`), nessun `SCRIPT ERROR`/`FATAL EXCEPTION`. Il primo criterio resta un giudizio da playtest fisico reale, non automatizzabile da qui.

## Documenti sincronizzati

- [x] `docs/systems-difficulty.md` e `docs/prd.md`, se cambia il contratto anti-AFK/late-run.
      *Sezione "PS-158 — il Tiratore spara senza telegraph e il colpo sopravvive alla sua morte" in `systems-difficulty.md`; descrizione del Tiratore aggiornata in `docs/enemies-bosses.md` (tabella archetipi, paragrafo dedicato, tabella eventi d'ondata). Non tocca `prd.md`: nessun valore numerico o contratto di densità/pesi è cambiato, solo il comportamento d'attacco del Tiratore e il ciclo di vita del suo proiettile.*
- [ ] Nota `*-verification.md`, con evidenza della build usata nel test.
      *Non prodotta: nessuna sessione di playtest fisico eseguita in questa sessione.*

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
