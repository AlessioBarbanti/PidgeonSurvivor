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
      *`RangedEnemy._on_died()` affida il colpo già in telegraph a `PendingRangedShot`, un nodo indipendente dal Tiratore: uccidere la fonte a metà telegraph non cancella più il colpo (`tests/unit/test_ps158_mature_build_anti_afk.gd`, primo test). La minaccia diventa quindi impegnata per tempo, non per gli HP di chi l'ha generata.*
- [x] Il giocatore in movimento può leggere e schivare la minaccia; non viene introdotto danno inevitabile fuori schermo o senza telegraph.
      *`PendingRangedShot` continua a disegnare lo stesso anello di telegraph fino allo sparo e ricontrolla il raggio rispetto al bersaglio al momento del colpo, esattamente come farebbe il Tiratore vivo: se il Player esce dal raggio prima che il colpo risolva, non parte (terzo test).*
- [x] PS-007 resta il principio di design storico; questa card documenta e corregge il finding emerso dal nuovo playtest invece di riscriverne retroattivamente la card completata.
      *Nessuna modifica a PS-007, ai suoi valori o alla sua card: solo un nuovo componente (`pending_ranged_shot.gd`) che completa un colpo già annunciato.*

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
- **2026-09-14 — Scelta implementativa: colpo pendente indipendente, non "morte ritardata".** Valutata l'alternativa di rimandare `queue_free()` del Tiratore finché il telegraph non risolve (così il nemico resta "vivo" solo per finire lo sparo): scartata perché lascerebbe il cadavere visibile e reattivo a schermo dopo che il giocatore lo ha ucciso, un feedback di danno ritardato e confuso. Preferito un nodo `PendingRangedShot` separato: il Tiratore muore e sparisce all'istante (feedback pulito), il colpo già annunciato continua a contare alla rovescia e a disegnare il proprio anello di telegraph in autonomia.
- **2026-09-14 — Nessuna modifica numerica.** Non toccati HP, danno, cadenza o potenza di alcuna build (vedi Ambito: "non ridurre artificialmente la potenza delle build offensive"). Il fix è puramente strutturale: disaccoppia l'esecuzione del colpo già in corso dal ciclo di vita del Tiratore.
- **2026-09-14 — Chiusura parziale.** `Focused` e `Relevant` verdi (14 regressioni incluse, `test_ps126_post_curve_pressure.gd` fra queste), nessun `SCRIPT ERROR`/`FATAL EXCEPTION`. Il primo criterio (30s reali senza movimento con una build composta) resta un giudizio da playtest fisico: nessun device disponibile in questa sessione, gate lasciato aperto.

## Documenti sincronizzati

- [x] `docs/systems-difficulty.md` e `docs/prd.md`, se cambia il contratto anti-AFK/late-run.
      *Aggiunta la sezione "PS-158 — il colpo telegrafato sopravvive alla morte del Tiratore" in `systems-difficulty.md`. Non tocca `prd.md`: nessun valore numerico o contratto di densità/pesi è cambiato, solo il ciclo di vita del colpo già annunciato.*
- [ ] Nota `*-verification.md`, con evidenza della build usata nel test.
      *Non prodotta: nessuna sessione di playtest fisico eseguita in questa sessione.*

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
