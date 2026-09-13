---
id: PS-162
titolo: Evita ripetizioni ravvicinate nella selezione dei Boss
tipo: fix
area: gameplay
stato: PRONTO
priorita: media
dipende_da: [PS-127]
origine: playtest esterno 2026-09-11 — feedback Lollo/Magno
creato: 2026-09-11
aggiornato: 2026-09-11
---

# PS-162 — Evita ripetizioni ravvicinate nella selezione dei Boss

## Contesto

In una singola run di playtest sono comparsi più volte gli stessi Evil (tre occorrenze dello stesso profilo e due di un altro), riducendo rapidamente la sensazione di varietà. La selezione corrente estrae un `FriendDefinition` valido in modo uniforme e indipendente per ogni `schedule_index`; con PS-127 il Piccione Malvagio è raro e gli Evil costituiscono la grande maggioranza degli incontri.

## Comportamento atteso

Una run con Boss ricorrenti deve esplorare il roster prima di ripetere frequentemente la stessa identità. La selezione resta deterministica rispetto a seed e schedule, ma tiene conto degli Evil già incontrati nella run.

## Criteri di accettazione

- [ ] Quando esistono almeno tre Evil eleggibili, lo stesso Evil non può apparire in due incontri consecutivi.
- [ ] Nei primi quattro incontri Evil di una run compaiono almeno tre identità diverse, salvo roster eleggibile inferiore.
- [ ] A parità di seed e sequenza di `schedule_index`, la successione dei Boss resta deterministica.
- [ ] Restart e nuova run azzerano la memoria degli incontri; ripetendo lo stesso seed si ottiene di nuovo la stessa sequenza iniziale.
- [ ] La probabilità del Piccione Malvagio definita da PS-127 non viene trasformata in una quota rigida per run.
- [ ] Non viene introdotta alcuna quota per genere: l'osservazione del playtest sulla prevalenza femminile è trattata come campione insufficiente, mentre il difetto verificato è la ripetizione delle identità.

## Ambito

- `scripts/bosses/boss_encounter.gd`: risoluzione della variante e memoria scene-local delle identità già incontrate, azzerata con la run.
- `scripts/game/game_director.gd` solo se serve trasportare stato di scheduling già disponibile.
- `tests/` con sequenze seedate su più ricorrenze.
- Non cambiare Signature, statistiche o probabilità baseline/Evil di PS-127.

## Verifica

- Smoke: `tests/unit/test_ps162_boss_variety_sequence.gd` → marker `PS162_BOSS_VARIETY_SEQUENCE_SMOKE_OK`
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run con almeno quattro Evil; annotare ordine delle identità)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-09-11 — Si corregge la ripetizione ravvicinata, non si impone una distribuzione uomo/donna sulla base di una sola run.**
- **2026-09-11 — La selezione deve restare seed-deterministica per non rompere il contratto dei test di run.**

## Documenti sincronizzati

- [ ] `docs/enemies-bosses.md` e `docs/systems-difficulty.md`, se descrivono la policy di selezione Boss.
- [ ] Nota `*-verification.md`, se viene salvata una sequenza seedata di evidenza.

## Note

Feedback originario raccolto il 2026-09-11 da trascrizioni audio di playtest esterno. I valori o gli esempi citati nel feedback sono trattati come evidenza percettiva e non come specifica numerica, salvo dove la card lo dichiara esplicitamente.
