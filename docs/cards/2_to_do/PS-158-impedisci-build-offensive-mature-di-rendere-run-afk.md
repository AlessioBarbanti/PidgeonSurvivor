---
id: PS-158
titolo: Impedisci alle build offensive mature di rendere la run AFK
tipo: fix
area: gameplay
stato: BLOCCATO
priorita: alta
dipende_da: [PS-126, PS-157]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-11
---

# PS-158 — Impedisci alle build offensive mature di rendere la run AFK

## Contesto

Nel playtest Magno ha raggiunto una combinazione di piercing, rimbalzo, esplosione, danno e fire rate che gli ha permesso di smettere letteralmente di muoversi senza subire più pressione. PS-007 aveva già fissato il principio anti-AFK e PS-126 introduce crescita oltre il minuto 5, ma il nuovo test mostra che una build offensiva matura può ancora annullare la necessità di prendere decisioni spaziali.

## Comportamento atteso

Anche una build offensiva molto forte deve continuare a richiedere movimento, lettura dei tell o riposizionamento. La late run può premiare la build rendendo il Player potente, ma non deve consentire di restare fermo in sicurezza per periodi prolungati.

## Criteri di accettazione

- [ ] Con una build deterministica che combini almeno piercing, rimbalzo/chain, esplosione o death burst, danno e fire rate, restare fermi per 30 secondi in late run espone il Player ad almeno una minaccia che richiede una risposta attiva.
- [ ] La pressione anti-AFK non dipende esclusivamente dall'aumento di HP dei nemici: almeno una sorgente di minaccia resta spaziale o temporale e non viene neutralizzata dal solo DPS.
- [ ] Il giocatore in movimento può leggere e schivare la minaccia; non viene introdotto danno inevitabile fuori schermo o senza telegraph.
- [ ] PS-007 resta il principio di design storico; questa card documenta e corregge il finding emerso dal nuovo playtest invece di riscriverne retroattivamente la card completata.

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

## Documenti sincronizzati

- [ ] `docs/systems-difficulty.md` e `docs/prd.md`, se cambia il contratto anti-AFK/late-run.
- [ ] Nota `*-verification.md`, con evidenza della build usata nel test.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
