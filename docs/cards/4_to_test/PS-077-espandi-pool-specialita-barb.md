---
id: PS-077
titolo: Espandi il pool delle Specialità di Barb con le carte signature rimaste
tipo: feat
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: [PS-012]
origine: B13
creato: 2026-09-02
aggiornato: 2026-09-04
---

# PS-077 — Espandi il pool delle Specialità di Barb con le carte signature rimaste

## Contesto

[PS-012](./PS-012-barb-specialities.md) ha introdotto il sistema
Specialità di Barb migrando quattro carte "strutturali" dal pool ordinario:
Gossip, Colpo Perforante, Raffica Doppia, Esplosione Finale
(`data/upgrades/specialities/`). Il criterio dichiarato da PS-012 era
esplicito: le carte "che modificano in modo più significativo il
comportamento della build" (contro i semplici potenziamenti statistici
ripetibili) devono diventare Specialità.

Quattro carte che rispettano esattamente lo stesso criterio non sono mai
state migrate. Sono le "upgrade signature del PRD" introdotte in **B13**
(`docs/archive/development-plan-through-b54-2026-08-30.md:364`), tutte
`max_rank = 1`, tutte con tag `&"signature"` in
`data/upgrades/*.tres`, tutte un tradeoff/meccanica dedicata invece di un
semplice moltiplicatore:

| ID | Titolo | Effetto |
|---|---|---|
| `anxiety_signature` | L'Ansia | `+35%` velocità, `-20%` vita max, vignetta |
| `beer_signature` | Birre di classe di Lollo | `+25%` cadenza, `±24°` dispersione |
| `chronic_delay` | Ritardo Cronico | rallenta tutti i nemici a intervalli |
| `damage_shockwave` | Non Ho Tempo Per Questo | onda d'urto reattiva al danno subito |

Oggi compaiono ancora nel pool normale fin dall'inizio della run, mescolate
alle carte statistiche semplici — esattamente il problema che PS-012 aveva
già risolto per Gossip e le altre tre.

## Comportamento atteso

Le quattro carte diventano Specialità di Barb con lo stesso meccanismo già
implementato da PS-012: non compaiono più nel pool normale dall'inizio della
run, vengono offerte come ricompensa alla sconfitta di un Boss insieme alle
quattro Specialità esistenti (pool totale: otto), e una volta sbloccate
seguono le stesse regole già in vigore.

## Criteri di accettazione

- [x] `anxiety_signature`, `beer_signature`, `chronic_delay` e
      `damage_shockwave` ottengono `is_speciality = true`, seguendo
      esattamente lo schema già usato dalle quattro Specialità esistenti.
- [x] I quattro file vengono spostati sotto `data/upgrades/specialities/`,
      coerentemente con l'organizzazione già stabilita da PS-012.
- [x] Le quattro nuove Specialità non compaiono nel pool normale di
      level-up finché non sono sbloccate da Barb.
- [x] Alla sconfitta di un Boss, Barb offre fino a tre Specialità pescate
      fra le otto totali (le quattro originali più le quattro nuove), senza
      duplicati.
- [x] Essendo `max_rank = 1`, una volta sbloccata ciascuna nuova Specialità
      non viene più riproposta né da Barb né dal normale level-up (già al
      rango massimo), tramite lo stesso `is_eligible()` invariato.
- [x] Restart e cambio personaggio azzerano lo sblocco delle nuove
      Specialità esattamente come per le quattro esistenti.
- [x] Stesso seed e stesse scelte producono la stessa sequenza di offerte
      Barb su tutte e otto le Specialità.
- [x] Nessuna modifica a `effect_id`, `effect_parameters`, `weight` o
      `max_rank` delle quattro carte: restano bit-per-bit identiche nei loro
      effetti a quanto implementato in B13.
- [x] Registry e preload sono aggiornati ai nuovi percorsi; nessun
      riferimento residuo alle vecchie path.

## Ambito

- `UpgradeRegistry` (percorsi/preload delle definizioni).
- I quattro file `data/upgrades/anxiety_signature.tres`,
  `beer_signature.tres`, `chronic_delay.tres`, `damage_shockwave.tres` →
  spostati in `data/upgrades/specialities/`, con `is_speciality = true`
  aggiunto.
- `tests/unit/test_ps012_barb_specialities.gd` e
  `tests/unit/test_b13_signature_upgrades.gd`, se pinnano il conteggio o la
  posizione attuale di queste quattro carte nel pool normale.

Non toccare:

- effetti, parametri, pesi e `max_rank` delle quattro carte;
- le quattro Specialità già esistenti (Gossip, Colpo Perforante, Raffica
  Doppia, Esplosione Finale);
- `BarbRewardOverlay` e il suo trattamento visivo (PS-036) — nome,
  descrizione e icona di queste quattro carte restano quelle attuali: la
  tematizzazione è demandata a [PS-078](../2_to_do/PS-078-tematizza-catalogo-specialita-barb.md);
- il pool statistico ordinario e le altre carte taggate `stat`.

## Verifica

- Smoke: `tests/unit/test_ps077_barb_speciality_pool_expansion.gd` → marker
  `BARB_SPECIALITY_POOL_EXPANSION_SMOKE_OK` — verifica `is_speciality`,
  esclusione dal pool normale finché bloccate, offerta Barb su tutte e otto
  senza duplicati, determinismo su seed fisso, reset su restart e cambio
  personaggio.
- Aggiornare `test_ps012_barb_specialities.gd`/`test_b13_signature_upgrades.gd`
  se assumono che queste quattro carte restino nel pool normale.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: sconfiggi almeno due Boss, verifica che le
      nuove Specialità compaiano nell'offerta di Barb e non nel pool normale
      prima dello sblocco
- [ ] Controllo percettivo richiesto: sì — le quattro carte come scelta
      random early-game funzionavano diversamente da come funzioneranno come
      sblocco post-Boss; verificare che il ritmo delle prime run non ne
      risenta negativamente (build meno "estreme" disponibili da subito)

## Decisioni

- **2026-09-02 — Completa una migrazione mai finita, non ne inventa una
  nuova.** PS-012 aveva già dichiarato il criterio ("carte che modificano in
  modo più significativo il comportamento della build") ma lo aveva
  applicato solo a Gossip e alle tre carte B41; queste quattro carte B13
  rispettano lo stesso criterio e sono rimaste indietro.
- **2026-09-02 — `max_rank = 1` non è un problema per il modello
  Specialità.** Il modello prevede "Barb assegna rank 1 → i rank successivi
  arrivano dal pool normale"; con `max_rank = 1` non ci sono rank successivi
  da assegnare, la Specialità è semplicemente sbloccata e conclusa — stesso
  comportamento già previsto da `is_eligible()` per carte non-repeatable al
  cap (osservato ma non testato esplicitamente da un caso dedicato in
  PS-012, essendo le sue quattro carte originali tutte `repeatable`).
- **2026-09-02 — Theming rimandato a una card separata.** Non si mescola il
  refactor meccanico (questa card) con il restyle di nomi/icone, sullo
  stesso schema già usato per PS-012 → PS-036.

- **2026-09-04 — Il pool normale va misurato su molte pesche, non su una.**
  Una singola `generate_offer()` non prova l'esclusione: il pool e' pesato e
  potrebbe non mostrare una Specialità comunque. Lo smoke ripete ventiquattro
  pesche sulla scena composta e altrettante dopo lo sblocco.
- **2026-09-04 — I valori B13 sono congelati a mano nello smoke.** Rileggere
  il `.tres` che la card si impegna a non toccare non proverebbe niente:
  `effect_id`, parametri, peso, `max_rank` e ripetibilità sono scritti come
  costanti nel test e confrontati contro il dato.
- **2026-09-04 — Tre smoke esistenti passavano dalla pesca normale.**
  `test_b13_signature_upgrades.gd`, `test_b18j_summer_grill.gd` e
  `test_b26_damage_upgrade.gd` acquisivano queste carte dal level-up: ora le
  sbloccano da ricompense Boss, che e' il percorso reale dopo la migrazione.
  Nessuna asserzione di effetto e' stata rilassata.
- **2026-09-04 — `movement_slice.gd` pinnava il conteggio a quattro.** Il
  contratto di scena verifica ora otto Specialità registrate e otto bloccate a
  inizio run; e' l'unica riga di runtime cambiata dalla card.

## Documenti sincronizzati

- [x] `docs/prd.md` §3.3: elenco Specialità aggiornato da quattro a otto.

## Note

Le quattro carte restano quelle implementate in B13: nessun nuovo effetto,
nessun nuovo parametro, nessuna nuova regola di rank.

Evidenze automatiche (2026-09-04):

```powershell
.	oolsun-milestone-checks.ps1 -Milestone PS-077 -Profile Focused `
  -FocusedSmoke tests/unit/test_ps077_barb_speciality_pool_expansion.gd -RefreshEditor
.	oolsun-milestone-checks.ps1 -Milestone PS-077 -Profile Relevant `
  -FocusedSmoke tests/unit/test_ps077_barb_speciality_pool_expansion.gd
.	oolsun-milestone-checks.ps1 -Milestone PS-077 -Profile Full
```

- Focused `PASS` — 5 test, 325 assert, marker
  `BARB_SPECIALITY_POOL_EXPANSION_SMOKE_OK` presente in `gut-focused.log`.
- Relevant `PASS` — focused 1/1, regressione 28/28, 78 test, 2307 assert.
- Full `PASS` — focused 5/5, regressione 95/95, toolchain 1/1, 288 test,
  22385 assert.
- Nessun `SCRIPT ERROR` né `FATAL EXCEPTION` nei log dei tre profili.

Gate ancora aperti: runtime Windows interattivo, validazione statica dell'APK,
runtime fisico su Pixel 9 e controllo percettivo sul ritmo delle prime run.
Sono tre risultati distinti e nessuno è stato esercitato: la verifica sopra è
soltanto automatica.
