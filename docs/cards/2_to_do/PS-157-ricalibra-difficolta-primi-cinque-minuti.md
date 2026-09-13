---
id: PS-157
titolo: Ricalibra la difficoltà dei primi cinque minuti
tipo: chore
area: gameplay
stato: BLOCCATO
priorita: alta
dipende_da: [PS-123, PS-124, PS-159, PS-160, PS-161, PS-165]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-11
---

# PS-157 — Ricalibra la difficoltà dei primi cinque minuti

## Contesto

Il playtest esterno descrive la finestra iniziale della run come troppo permissiva: il Player può assorbire diversi contatti senza che la sopravvivenza sembri realmente in discussione. PS-123 e PS-124 hanno già corretto rispettivamente la ricalibrazione degli archetipi dopo PS-076 e gli eventi d'ondata che riducevano la pressione; entrambe sono ora `IN VERIFICA`. PS-159 deve inoltre fissare la nuova velocità base del Player, che cambia direttamente quanta pressione è evitabile. Questa card registra quindi il gate percettivo complessivo 0–5 minuti senza duplicare quei tre interventi.

## Comportamento atteso

Nei primi cinque minuti una run standard deve richiedere schivate e posizionamento senza trasformarsi in una partenza punitiva. Subire ripetutamente contatti o ignorare la pressione nemica deve produrre una conseguenza percepibile, mentre un giocatore che si muove correttamente deve avere spazio per recuperare dagli errori.

## Criteri di accettazione

- [ ] Su una build aggiornata con PS-123, PS-124 e PS-159, un playtest da 0:00 a 5:00 non viene giudicato «molto facile» da almeno due sessioni consecutive di verifica interna con personaggi diversi.
- [ ] Nei primi due minuti restano presenti finestre sicure per attraversare l'arena: l'aumento di difficoltà non si traduce in danno inevitabile o spawn addosso al Player.
- [ ] Restare deliberatamente a contatto con i nemici produce una perdita di HP chiaramente rilevante; la vita base non consente di attraversare ripetutamente l'orda senza conseguenze.
- [ ] La taratura non modifica la curva oltre `late_run_curve_full_seconds`: quel contratto resta di PS-126.

## Ambito

- `data/spawn_profiles/default_enemy_spawn_profile.tres` e profilo di spawn, solo se il playtest richiede una taratura ulteriore della finestra 0–5 minuti.
- `data/enemies/*.tres` e parametri di danno/HP solo se la verifica di PS-123 dimostra che la baseline resta troppo permissiva.
- `scripts/game/wave_event_scheduler.gd` / `data/wave_events/` solo per tarature conseguenti a PS-124.
- Non cambiare il contratto endless della Sopravvivenza né la crescita post-5:00 di PS-126.

## Verifica

- GUT: `tests/unit/test_ps157_early_difficulty.gd` → marker `PS157_EARLY_DIFFICULTY_SMOKE_OK`, mantenendo verdi anche `test_ps123_archetype_hp_rescale.gd` e `test_ps124_wave_event_pressure.gd`.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run 0:00–5:00 con almeno due personaggi; annotare HP perso, necessità di schivata e momenti di pressione)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-09-11 — La card non aumenta alla cieca HP o danno. Il feedback è percettivo e arriva mentre PS-123/PS-124 sono già in verifica: prima si valuta quella baseline, poi si ritocca solo ciò che resta insufficiente.**
- **2026-09-11 — BLOCCATO dalla stabilizzazione del Player.** Tarare la difficoltà prima di chiudere velocità base (PS-159), valore degli upgrade di velocità (PS-160), progressione delle attive (PS-161) e scorrimento sui prop (PS-165) significherebbe misurare fuga, potenza e controllo ancora destinati a cambiare.

## Documenti sincronizzati

- [ ] `docs/prd.md` e `docs/systems-difficulty.md`, se cambia un valore o un contratto della curva 0–5 minuti.
- [ ] Nota `*-verification.md`, se vengono prodotte nuove evidenze di playtest.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
