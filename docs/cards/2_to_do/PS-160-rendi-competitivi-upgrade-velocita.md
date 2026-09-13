---
id: PS-160
titolo: Rendi competitivi gli upgrade di velocità
tipo: chore
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: [PS-159]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-11
---

# PS-160 — Rendi competitivi gli upgrade di velocità

## Contesto

Nel playtest `Dai che si fredda!` e `Via dalla Griglia!` sono rimasti a rango zero senza creare un costo percepibile, mentre danno, cadenza, perforazione, multicolpo ed esplosioni hanno dominato le scelte. Entrambe le carte applicano oggi `×1,1` per rango e hanno lo stesso peso base `1,0`; la mobilità deve essere rivalutata dopo la nuova baseline di PS-159. L'audit del runtime ha inoltre escluso l'ipotesi di proiettili propri dei personaggi che accelerano autonomamente: l'arma automatica usa per tutto il roster `default_weapon_profile.tres` e il moltiplicatore universale di `WeaponController`.

## Comportamento atteso

I due upgrade di velocità devono avere casi d'uso percepibili e competitivi, senza diventare scelte obbligatorie. Il giocatore deve poter spiegare cosa guadagna scegliendoli rispetto a un incremento puramente offensivo.

## Criteri di accettazione

- [ ] Dopo PS-159, una run di confronto documenta almeno una situazione ricorrente in cui Movement Speed migliora concretamente sopravvivenza o controllo dello spazio.
- [ ] `Via dalla Griglia!` riduce in modo misurabile il tempo di volo verso bersagli distanti e aumenta la distanza percorsa entro la lifetime invariata del proiettile; il confronto usa l'arma base condivisa dal roster, non una falsa variante per personaggio.
- [ ] Nessuna delle due statistiche viene resa competitiva aggiungendo danno nascosto: descrizione carta ed effetto runtime restano coerenti.
- [ ] In un mini-playtest a scelta forzata fra una delle due carte e una carta offensiva generica, almeno una delle statistiche di velocità viene scelta volontariamente in più di un'occasione su una run completa.

## Ambito

- `data/upgrades/` per definizioni e parametri delle carte coinvolte.
- `scripts/progression/upgrade_effect_registry.gd`, `scripts/combat/weapon_controller.gd` e `scripts/actors/player.gd` per gli effetti esistenti.
- `docs/powerup-catalog.md` per eventuali variazioni di valori o descrizioni.
- Non cambiare piercing, chain/rimbalzo, death burst o fire rate in questa card.

## Verifica

- Smoke: `tests/unit/test_ps160_speed_upgrade_value.gd` → marker `PS160_SPEED_UPGRADE_VALUE_SMOKE_OK`
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run comparativa dopo PS-159 con almeno una scelta Movement Speed e una Projectile Speed)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-09-11 — Sbloccata da PS-159 in `IN VERIFICA`: la baseline implementata è ora `300 px/s`, quindi la mobilità può essere rivalutata sul valore candidato al gate percettivo.**
- **2026-09-11 — Correzione dell'audit:** non esiste un proiettile di Magno con accelerazione propria. `projectile_speed` modifica la stessa arma automatica condivisa da tutto il roster; l'utilità va quindi misurata su distanza, tempo di volo e lifetime, non per personaggio.
- **2026-09-11 — Priorità alta nel filone di ricalibrazione.** Dopo PS-159 questa card deve precedere il playtest conclusivo 0–5 di PS-157, perché modifica direttamente la mobilità disponibile nelle prime scelte di upgrade.

## Documenti sincronizzati

- [ ] `docs/powerup-catalog.md`, se cambiano effetto, valore o descrizione delle carte.
- [ ] `docs/prd.md`, se cambia un contratto generale degli upgrade.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
