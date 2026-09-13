---
id: PS-160
titolo: Rendi competitivi gli upgrade di velocità
tipo: chore
area: gameplay
stato: IN VERIFICA
priorita: alta
dipende_da: [PS-159]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-13
---

# PS-160 — Rendi competitivi gli upgrade di velocità

## Contesto

Nel playtest `Dai che si fredda!` e `Via dalla Griglia!` sono rimasti a rango zero senza creare un costo percepibile, mentre danno, cadenza, perforazione, multicolpo ed esplosioni hanno dominato le scelte. Entrambe le carte applicano oggi `×1,1` per rango e hanno lo stesso peso base `1,0`; la mobilità deve essere rivalutata dopo la nuova baseline di PS-159. L'audit del runtime ha inoltre escluso l'ipotesi di proiettili propri dei personaggi che accelerano autonomamente: l'arma automatica usa per tutto il roster `default_weapon_profile.tres` e il moltiplicatore universale di `WeaponController`.

## Comportamento atteso

I due upgrade di velocità devono avere casi d'uso percepibili e competitivi, senza diventare scelte obbligatorie. Il giocatore deve poter spiegare cosa guadagna scegliendoli rispetto a un incremento puramente offensivo.

## Criteri di accettazione

- [ ] Dopo PS-159, una run di confronto documenta almeno una situazione ricorrente in cui Movement Speed migliora concretamente sopravvivenza o controllo dello spazio. Non verificabile da codice: richiede un playtest reale (vedi Gate manuali).
- [x] `Via dalla Griglia!` riduce in modo misurabile il tempo di volo verso bersagli distanti e aumenta la distanza percorsa entro la lifetime invariata del proiettile; il confronto usa l'arma base condivisa dal roster, non una falsa variante per personaggio. Valore per rango alzato da `+10%` a `+20%`; verificato che `projectile_lifetime` resta invariato e che la misura avviene su `default_weapon_profile.tres`, l'unica arma del roster.
- [x] Nessuna delle due statistiche viene resa competitiva aggiungendo danno nascosto: descrizione carta ed effetto runtime restano coerenti. Verificato che `get_effective_damage()` non cambia quando si seleziona una delle due carte, e che `effect_summary` riporta lo stesso valore applicato a runtime (`+15%`/`+20%`).
- [ ] In un mini-playtest a scelta forzata fra una delle due carte e una carta offensiva generica, almeno una delle statistiche di velocità viene scelta volontariamente in più di un'occasione su una run completa. Non verificabile da codice: richiede un playtest reale (vedi Gate manuali).

## Ambito

- `data/upgrades/` per definizioni e parametri delle carte coinvolte.
- `scripts/progression/upgrade_effect_registry.gd`, `scripts/combat/weapon_controller.gd` e `scripts/actors/player.gd` per gli effetti esistenti.
- `docs/powerup-catalog.md` per eventuali variazioni di valori o descrizioni.
- Non cambiare piercing, chain/rimbalzo, death burst o fire rate in questa card.

## Verifica

- Smoke: `tests/unit/test_ps160_speed_upgrade_value.gd` → marker `PS160_SPEED_UPGRADE_VALUE_SMOKE_OK`. 4/4 verdi: valori dichiarati coerenti con `effect_summary`, singola scelta senza danno nascosto per entrambe le carte, distanza percorsa misurabilmente maggiore, saturazione del cap `max_move_speed_multiplier` a rango 5.
- Aggiornati due test di regressione preesistenti che assumevano il vecchio `×1,1`: `tests/unit/test_b12_upgrade_effects.gd` (atteso a rango 5 ora tiene conto del cap, `+15%^5 ≈ 2,011` saturato a `2,0`) e `tests/unit/test_powerup_first_wave.gd` (`+20%` invece di `+10%`); e uno che assumeva swift_steps non ancora saturo al rango 5: `tests/unit/test_b41_weapon_shapes.gd` (spostato il controllo al rango 4, l'ultimo non ancora saturo con il nuovo valore).
- Profilo minimo prima della chiusura: `Relevant` — eseguito, 16/16 verdi (1 focused + 15 di regressione), nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run comparativa dopo PS-159 con almeno una scelta Movement Speed e una Projectile Speed)
- [ ] Controllo percettivo richiesto: sì — resta aperto insieme ai due criteri di accettazione non verificabili da codice (situazione ricorrente osservata, mini-playtest a scelta forzata): richiedono un playtest reale del proprietario, non un'ispezione o simulazione mia.

## Decisioni

- **2026-09-11 — Sbloccata da PS-159 in `IN VERIFICA`: la baseline implementata è ora `300 px/s`, quindi la mobilità può essere rivalutata sul valore candidato al gate percettivo.**
- **2026-09-11 — Correzione dell'audit:** non esiste un proiettile di Magno con accelerazione propria. `projectile_speed` modifica la stessa arma automatica condivisa da tutto il roster; l'utilità va quindi misurata su distanza, tempo di volo e lifetime, non per personaggio.
- **2026-09-11 — Priorità alta nel filone di ricalibrazione.** Dopo PS-159 questa card deve precedere il playtest conclusivo 0–5 di PS-157, perché modifica direttamente la mobilità disponibile nelle prime scelte di upgrade.
- **2026-09-13 — Prima taratura implementata: `Dai che si fredda!` `+10%→+15%`/rango, `Via dalla Griglia!` `+10%→+20%`/rango.** Entrambe restano moltiplicatori composti (`pow(valore, rango)`), invariati gli altri parametri (`weight`, `max_rank`, `repeatable`). Scelta asimmetrica perché la velocità di movimento ha già un impatto indiretto ampio (sopravvivenza, controllo dello spazio) anche a incrementi minori, mentre la velocità proiettile è un beneficio più marginale (riduzione del tempo di volo) che richiede uno scarto maggiore per risultare percepibile. Come per PS-159, questi restano valori di prima candidatura soggetti al gate percettivo/mini-playtest del proprietario, non un valore validato.
- **2026-09-13 — Il nuovo valore di `Dai che si fredda!` fa saturare il cap esistente (`max_move_speed_multiplier = 2,0`) esattamente al rango 5 (`1,15^5 ≈ 2,011`), un rango prima di quanto accadesse con `+10%`.** Non è un effetto collaterale indesiderato: il cap resta lo stesso già validato da PS-093, la carta arriva semplicemente al proprio tetto con un rango di anticipo. Aggiornato di conseguenza `test_b41_weapon_shapes.gd`, che usava swift_steps a rango 5 come esempio di carta "non ancora satura".
- **2026-09-13 — I due criteri basati su playtest reale (situazione ricorrente in run, scelta volontaria in un mini-playtest a scelta forzata) restano esplicitamente non spuntati.** Nessuna simulazione o euristica automatica li sostituisce: richiedono il giudizio del proprietario su una run reale, coerentemente con «Onestà dei gate» di `CLAUDE.md`.

## Documenti sincronizzati

- [x] `docs/powerup-catalog.md`: aggiornato il valore per rango di `Via dalla Griglia!` (`+10%→+20%`) con nota del motivo. `Dai che si fredda!` non era documentata nel catalogo (carta preesistente non inclusa nel batch "Nuovi potenziamenti"): nessuna voce da aggiornare.
- [x] `docs/prd.md`, se cambia un contratto generale degli upgrade. Verificato: nessun valore numerico delle due carte è documentato lì, nessuna modifica necessaria.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
