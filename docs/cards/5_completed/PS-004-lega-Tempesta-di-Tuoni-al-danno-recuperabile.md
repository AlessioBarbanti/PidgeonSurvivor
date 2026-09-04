---
id: PS-004
titolo: Lega Tempesta di Tuoni al danno recuperabile
tipo: feat
area: gameplay
stato: COMPLETATO
priorita: alta
dipende_da: [PS-003]
origine: B43
creato: 2026-08-29
aggiornato: 2026-09-04
---

# PS-004 — Lega Tempesta di Tuoni al danno recuperabile

## Contesto

Tempesta di Tuoni usa oggi fulmini telegrafati nell'arena e non interagisce direttamente con Guarigione Ritardata.

Il nome **Tempesta di Tuoni** deve restare invariato. La nuova attiva deve usare il danno recuperabile di Zat come fonte di potenza e avere un tell visivo immediato.

## Comportamento atteso

Quando Zat attiva Tempesta di Tuoni:

* vengono fotografati i nemici vivi presenti in quel momento;
* tutti i bersagli fotografati ricevono una singola istanza di danno;
* il danno dipende dalla quantità di HP recuperabili accumulati;
* gli HP recuperabili non vengono consumati.

La carica usa tre fasce:

| Fascia |          HP recuperabili | Aura             | Rotazione | Moltiplicatore |
| ------ | -----------------------: | ---------------- | --------- | -------------: |
| Bassa  |            `< 5% HP max` | 1 fulmine verde  | lenta     |           `×1` |
| Media  | `>= 5%` e `< 12% HP max` | 2 fulmini gialli | media     |           `×2` |
| Alta   |          `>= 12% HP max` | 3 fulmini rossi  | rapida    |           `×3` |

Baseline rank 1:

* danno base: `12`;
* fascia bassa: `12`;
* fascia media: `24`;
* fascia alta: `36`.

Numero, colore e velocità dei fulmini si aggiornano quando cambia la fascia di carica.

I fulmini orbitanti sono solo VFX: nessun danno, collisione, blocco proiettili o altro effetto gameplay.

Tutte le soglie, i moltiplicatori, il danno e le velocità di rotazione restano configurabili da dati.

## Criteri di accettazione

* [x] Tempesta di Tuoni non genera più fulmini telegrafati nell'arena.
* [x] Ogni nemico vivo fotografato all'attivazione riceve esattamente un colpo.
* [x] Nemici comparsi dopo lo snapshot non vengono colpiti.
* [x] La fascia bassa mostra esattamente 1 fulmine verde.
* [x] La fascia media mostra esattamente 2 fulmini gialli.
* [x] La fascia alta mostra esattamente 3 fulmini rossi.
* [x] La velocità di rotazione aumenta da fascia bassa a media ad alta.
* [x] Al rank 1 le tre fasce infliggono rispettivamente `12`, `24` e `36` danni.
* [x] Usare Tempesta di Tuoni non modifica gli HP recuperabili accumulati.
* [x] Guarigione Ritardata continua normalmente dopo l'attivazione.
* [x] I fulmini orbitanti non possono danneggiare o interagire con altre entità.
* [x] Cambiare fascia aggiorna numero, colore e velocità dell'aura.
* [x] L'aura rende leggibile la quota recuperabile corrente anche fuori
  dall'attivazione del Tuono (criterio ereditato da PS-003, differenza D3).
* [x] Tornare a vita piena spegne la carica in modo leggibile, senza far
  sembrare l'azzeramento un bug (decisione su D2). Verificato via contratto
  PS-003 (azzeramento nello stesso frame) più `_refresh_thunder_charge_aura`
  che riporta l'aura in fascia bassa allo stesso tick, senza nasconderla.
* [x] Pausa e stati non `RUNNING` congelano correttamente aura e cooldown.
* [x] Restart e cambio personaggio eliminano ogni stato e VFX residuo.
* [x] Il nome pubblico resta **Tempesta di Tuoni**.

## Ambito

Sistemi attesi:

* definizione e rank di Tempesta di Tuoni;
* effetto runtime dell'attiva;
* esposizione degli HP recuperabili di Guarigione Ritardata;
* VFX orbitante di Zat;
* cleanup e reset;
* test di integrazione dedicato.

Non modificare:

* logica di accumulo e recupero di Guarigione Ritardata;
* sistema generale dei rank;
* clock delle abilità;
* regole di pausa;
* Onda d'Urto Tellurica di Magno.

Tempesta di Tuoni non applica knockback, slow o controllo radiale.

## Verifica

* Smoke: `tests/unit/test_ps004_zat_thunder_charge.gd` (10 test). Il percorso e
  il marker indicati sopra appartengono alla convenzione legacy `tests/integration/_*_smoke.gd`,
  già superata dal cutover a GUT (vedi PS-003): il runner raccoglie solo
  `tests/**/test_*.gd`, quindi uno smoke con quel nome non verrebbe mai
  eseguito. Stessa formulazione corretta adottata da PS-003.
* Copertura effettiva:

  * `test_ps004_fascia_bassa_danno_12_e_aura_verde` / `..._media_danno_24_e_aura_gialla` /
    `..._alta_danno_36_e_aura_rossa`: tre soglie di carica, danno `12/24/36`,
    numero e colore dei fulmini, quota recuperabile non consumata, nome
    pubblico invariato;
  * `test_ps004_velocita_rotazione_cresce_con_la_fascia`: rotazione monotona
    bassa < media < alta;
  * `test_ps004_snapshot_esclude_nemici_comparsi_dopo`: fotografia dei
    bersagli, nemico comparso dopo lo snapshot non colpito;
  * `test_ps004_ogni_nemico_fotografato_riceve_un_solo_colpo`: multi-bersaglio,
    un solo colpo ciascuno;
  * `test_ps004_guarigione_ritardata_continua_dopo_lattivazione`: il contratto
    PS-003 (attesa, recupero lineare, azzeramento a fine finestra) resta
    intatto dopo un'attivazione;
  * `test_ps004_pausa_congela_aura_e_preavviso`: pausa manuale congela
    rotazione dell'aura e preavviso del Tuono, entrambi riprendono al resume;
  * `test_ps004_restart_e_cambio_personaggio_azzerano_laura`: restart e cambio
    personaggio azzerano fascia, quota e presentazione dell'aura;
  * `test_ps004_fulmini_orbitanti_sono_solo_vfx`: l'aura non ha figli con
    collisioni o effetti propri.
* Profilo minimo prima della chiusura: `Relevant` — **eseguito**.

## Gate manuali

* [x] Runtime Windows
* [x] Validazione statica APK
* [x] Runtime fisico Pixel 9: Zat → accumula progressivamente danno recuperabile → verifica verde/giallo/rosso → attiva il Tuono nelle tre fasce
* [x] Controllo percettivo richiesto: sì
* [x] 1/2/3 fulmini restano leggibili con orde dense.
* [x] Verde/giallo/rosso restano distinguibili durante il gameplay.
* [x] Le tre velocità di rotazione risultano chiaramente differenti.
* [x] La fascia rossa comunica chiaramente uno stato di alta carica.
* [x] Il VFX non viene confuso con proiettili o telegraph ostili.
* [x] **Ereditato da PS-003**: la salute recuperabile è comprensibile durante
  una run reale guardando l'aura.
* [x] Tempesta di Tuoni non viene percepita come la shockwave di Magno.

## Decisioni

- **2026-08-29 — Danno basato su una fotografia dei bersagli vivi.** Ogni
  nemico presente all'attivazione riceve una sola istanza di danno.
- **2026-08-29 — Gli HP recuperabili non vengono consumati.** La sinergia
  rafforza l'attiva senza annullare la funzione difensiva della passiva.
- **Baseline da playtest — tre fasce a 5% e 12%.** Soglie e moltiplicatori
  restano configurabili finché non vengono validati.
- **2026-08-30 — La potenza è a gradini, non continua.** La quota recuperabile
  non ha cap (PS-003, D1): il limite alla potenza lo impone questa card usando
  soltanto le tre fasce. Oltre la soglia alta la Tempesta non cresce più.
- **2026-08-30 — L'aura assorbe il tell mancante della passiva.** PS-003 ha
  confermato che la quota recuperabile è oggi invisibile (D3); invece di aprire
  una card di tell dedicata, il proprietario ha scelto l'aura elettrica di
  questa card come lettura unica della quantità recuperabile.
- **2026-08-30 — Soglie e velocità di rotazione vivono nei dati di Zat, i
  moltiplicatori e il danno base nei dati dell'attiva.** `charge_threshold_medium`,
  `charge_threshold_high`, `aura_rotation_speed_low/medium/high` sono in
  `data/friends/zat.tres` (`passive_parameters`), perché descrivono la quota
  recuperabile e il suo tell indipendentemente dall'attiva. `tier_multiplier_low/medium/high`
  e `damage` (rank-scalato) restano in `data/abilities/zat_lightning_storm.tres`,
  perché descrivono la potenza del Tuono. `FriendPassiveController.get_thunder_charge_tier()`
  è il solo punto che legge le soglie; l'attiva chiede la fascia già risolta
  invece di riderivarla, cosi passiva e attiva restano due sistemi
  scene-local disaccoppiati (nessun autoload, nessun bus fra i due).
- **2026-08-30 — Nessun flash fullscreen all'attivazione.** Il vecchio budget
  B18E (un solo flash pieno schermo) apparteneva al wipe telegrafato rimosso.
  Il nuovo tell immediato sono i decal tinti per fascia disegnati su ogni
  bersaglio fotografato, dopo un breve preavviso (`warning_seconds = 0,35 s`).
  `ThunderStorm.uses_fullscreen_overlay()` ora dichiara `false`.
- **2026-08-30 — La fascia bassa è lo stato di riposo dell'aura, non uno stato
  nascosto.** Con `0` HP recuperabili la fascia è comunque "bassa" (1 fulmine
  verde), non "nessuna fascia": l'aura resta sempre visibile durante `RUNNING`
  finché il personaggio equipaggiato è Zat. Questo rende leggibile
  l'azzeramento brusco (D2 di PS-003): la carica scende a un fulmine verde
  invece di sparire, coerente col criterio "senza far sembrare l'azzeramento
  un bug".
- **2026-08-30 — Cosplay Casuale su Tempesta di Tuoni fuori da Zat resta in
  fascia bassa.** `AbilityEffectRegistry._resolve_zat_thunder_tier` legge la
  passiva equipaggiata sulla sorgente; se non è Guarigione Ritardata (copia
  Cosplay su un altro personaggio) la fascia è bassa per definizione. Non
  esplicitamente richiesto dalla card, ma necessario perché l'attiva resti
  eseguibile da `RANDOM_COSPLAY` senza toccarne la logica (fuori Ambito).
- **2026-08-30 — Aperta PS-030 per un bug del runner, non risolto qui.** La
  rimozione dei due test obsoleti (`test_b43_lightning_storm.gd`,
  `test_b18e_zat_thunder_storm.gd`) fa crashare il profilo `Relevant` del
  runner (`Resolve-RepositoryPath -MustExist` su un path cancellato). Aggirato
  per questa card con `-ChangedPath` esplicito; la correzione del runner resta
  in PS-030, fuori Ambito.

## Termini confermati da PS-003

PS-003 ha chiuso la verifica di Guarigione Ritardata; il contratto completo è
in [characters.md](../../characters.md). Termini che questa card deve usare come
dati di ingresso invece di riderivarli:

- **Lettura**: `FriendPassiveController.get_recoverable_health()` restituisce la
  quota corrente e non la consuma. Il segnale `delayed_healing_changed(float)`
  annuncia ogni variazione: è l'aggancio giusto per aggiornare la fascia
  dell'aura senza campionare ogni frame.
- **Ordine di grandezza**: la quota è il 35% del danno applicato e non ha tetto.
  Con gli HP massimi di Zat (moltiplicatore `1.1`) le soglie `5%` e `12%`
  cadono attorno a `5.5` e `13.2` HP recuperabili, cioè poco più di uno e di due
  colpi da `20`. Le tre fasce sono quindi tutte raggiungibili.
- **Il tetto lo mette questa card, non la passiva** (decisione del 2026-08-30 su
  D1). La quota può crescere senza limite, ma la potenza è una funzione a
  gradini: superata la soglia alta la Tempesta resta a `×3`. Nessun termine
  continuo, nessuna interpolazione oltre la terza fascia.
- **Durata della carica**: la fascia alta è transitoria. Dopo l'ultimo colpo la
  quota resta ferma `3 s` e poi si svuota linearmente in `4 s`: al netto di
  nuovi colpi la carica dura al massimo ~`7 s`. Il tell dell'aura deve reggere
  una discesa continua, non solo salti discreti.
- **Azzeramenti bruschi**: a vita piena (o con il tetto HP già raggiunto) la
  quota viene scartata **per intero** al primo tick di recupero. L'aura passa
  da alta a bassa in un frame: il VFX non deve dare per scontata una discesa
  graduale. Il comportamento è voluto (decisione del 2026-08-30 su D2): tornare
  a vita piena spegne la carica, e la guarigione differita non è un credito
  utilizzabile su danni futuri.
- **L'aura è anche il tell della passiva** (decisione del 2026-08-30 su D3).
  Oggi la quota recuperabile non ha alcuna rappresentazione a schermo:
  `delayed_healing_changed` non ha consumatori e Zat non ha un contorno di
  stato. L'aura elettrica a tre fasce introdotta qui non serve solo a
  telegrafare la potenza del Tuono, è **la** lettura della quota recuperabile
  per il giocatore. Il gate percettivo corrispondente arriva da PS-003.
- **Congelamento**: attesa e recupero avanzano solo in `RUNNING`, quindi la
  fascia non cambia da sola durante pausa, level-up e Boss intro.
- **Reset**: restart e cambio personaggio azzerano quota e timer prima che
  l'attiva possa leggerli.

## Documenti sincronizzati

- [x] `characters.md`: contratto finale dell'attiva e della sinergia con Zat
  (sezione Zat, dopo il contratto di Guarigione Ritardata).
- [x] `prd.md`: sezione 3.6, scheda "Zat — Tempesta di Tuoni" riscritta per il
  nuovo contratto (fotografia, fasce, tell persistente).
- [—] `content-approvals.md`: **non applicabile**. L'aura è disegnata a
  runtime con primitive `CanvasItem` (linee e cerchi), come il contorno di
  stato di PS-001: nessun nuovo asset grafico introdotto.

## Note

**Tempesta di Tuoni** resta il nome pubblico per ragioni di identità/meme del gruppo.

Scartati:

* fulmini telegrafati nell'arena;
* shockwave sonora con knockback;
* consumo degli HP recuperabili all'attivazione.

Loop desiderato:

**subisci danno → accumuli HP recuperabili → aumenta la carica visiva → Tuono più potente → sopravvivi → recuperi HP.**

Baseline da playtest:

* soglie: `5% / 12%`;
* danno rank 1: `12`;
* moltiplicatori: `×1 / ×2 / ×3`.

Nessuno di questi valori è un contratto di bilanciamento definitivo.

Comandi eseguiti come evidenza:

    .\tools\run-milestone-checks.ps1 -Milestone PS-004 -Profile Focused
        -FocusedSmoke tests/unit/test_ps004_zat_thunder_charge.gd -RefreshEditor
    .\tools\run-milestone-checks.ps1 -Milestone PS-004 -Profile Relevant
        -FocusedSmoke tests/unit/test_ps004_zat_thunder_charge.gd -ChangedPath <path pertinenti>

`-ChangedPath` esplicito per il profilo `Relevant` per aggirare il bug del
runner descritto in PS-030 (i due test cancellati fanno crashare la selezione
automatica basata su `git diff`); l'elenco passato copre tutti i file
effettivamente toccati da questa card, incluso il test nuovo.

Esito:

- `Focused`: `status=PASS bootstrap=1/1 focused=1/1 steps=2/2` — 10 test, 0
  fallimenti, nessun `SCRIPT ERROR` né `FATAL EXCEPTION` nel log.
- `Relevant`: `status=PASS focused=1/1 regression=23/23 steps=24/24` — 23
  script di regressione (incluso `test_b17a_complete_roster_abilities.gd`,
  `test_b18g_ability_ranks.gd`, `test_b18m_ability_visuals.gd`,
  `test_ps003_zat_delayed_healing.gd`), nessun `SCRIPT ERROR` né
  `FATAL EXCEPTION` nei log.

Il test è registrato in `tools/milestone-test-map.json` sotto le regole di
`scripts/actors/player.gd` (+`data/friends/*`), `scripts/abilities/*`
(+`data/abilities/*`), `scripts/vfx/*` e
`scripts/content/friend_passive_controller.gd`.
