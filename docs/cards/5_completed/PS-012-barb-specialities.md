---
id: PS-012
titolo: Introduci le Specialità di Barb
tipo: feat
area: gameplay
stato: COMPLETATO
priorita: alta
dipende_da: []
origine:
milestone:
creato: 2026-08-30
aggiornato: 2026-09-04
---

# PS-012 — Introduci le Specialità di Barb

## Contesto

Il catalogo level-up contiene oggi sia potenziamenti statistici ripetibili sia carte che modificano in modo più significativo il comportamento della build, come Gossip e le forme d'attacco introdotte con B41.

Queste carte devono diventare **Specialità di Barb**: non compaiono nel normale pool all'inizio della run, ma vengono sbloccate come ricompensa dopo la sconfitta di un Boss.

Il loro design gameplay non deve essere modificato.

## Comportamento atteso

Alla sconfitta di un Boss viene aperta una scelta dedicata alle **Specialità di Barb**.

Il sistema presenta fino a tre Specialità non ancora sbloccate nella run.

Quando il Player ne sceglie una:

* la Specialità viene assegnata immediatamente al rank `1`;
* viene marcata come sbloccata per la run corrente;
* da quel momento entra nel normale pool di level-up;
* i rank successivi vengono ottenuti tramite il normale sistema di upgrade già esistente;
* le altre Specialità offerte ma non selezionate restano bloccate e possono essere offerte dopo Boss successivi.

Una Specialità già sbloccata non viene più proposta da Barb.

Una Specialità raggiunto il proprio rank massimo non viene più proposta nei normali level-up.

## Catalogo Specialità

Il primo catalogo utilizza le carte strutturali già esistenti, senza modificarne gli effetti:

* **Gossip**;
* **Colpo Perforante**;
* **Raffica Doppia**;
* **Esplosione Finale**.

Il catalogo può essere ampliato in futuro, ma PS-012 non introduce nuove Specialità e non ridisegna quelle esistenti.

Le forme d'attacco esistenti sono già implementate come modificatori qualitativi della build e devono mantenere il comportamento corrente.

## Rank e progressione

Ogni Specialità:

* mantiene la progressione già definita nell'implementazione corrente;
* mantiene i propri effetti, parametri e comportamento per rank;
* può avere al massimo `5` rank;
* non deve necessariamente arrivare a rank `5` se il limite corrente è inferiore;
* non cambia il proprio `max_rank` esistente se questo è già compreso fra `1` e `5`;
* utilizza il normale sistema di rank e applicazione degli upgrade.

PS-012 non introduce nuove progressioni per singola Specialità.

In particolare non devono essere aggiunti nuovi effetti, nuovi breakpoint o nuove regole per i rank allo scopo di adattare le carte al sistema Barb.

## Pool level-up normale

All'inizio della run il normale pool di level-up contiene:

* potenziamenti statistici/ripetibili già previsti dal catalogo normale;
* rank successivi dell'abilità attiva del personaggio;
* nessuna Specialità di Barb ancora bloccata.

Dopo lo sblocco di una Specialità, i suoi rank successivi entrano nel pool normale secondo le stesse regole di eleggibilità già esistenti.

Il level-up non deve poter assegnare il rank `1` di una Specialità ancora bloccata.

## Ricompensa Boss

Alla morte di un Boss:

1. vengono individuate le Specialità non ancora sbloccate;
2. ne vengono offerte fino a tre, senza duplicati;
3. il Player ne sceglie una;
4. la scelta assegna il rank `1`;
5. la Specialità entra nel pool level-up della run;
6. la run prosegue.

La selezione deve utilizzare RNG deterministico derivato dal seed della run.

Se rimangono meno di tre Specialità bloccate, vengono mostrate soltanto quelle disponibili.

Se tutte le Specialità sono già state sbloccate, il sistema non deve mostrare un'offerta vuota o bloccare la progressione della run. Il comportamento di fallback deve essere gestito esplicitamente senza creare nuove Specialità.

## Fallback Specialità esaurite

Quando non esistono più Specialità bloccate, la ricompensa Boss viene sostituita da due selezioni upgrade bonus consecutive, generate tramite lo stesso pool e le stesse regole dei normali level-up. Le selezioni applicano gli upgrade normalmente ma non aumentano il livello del Player e non modificano XP o soglie di progressione.

## Organizzazione dei file

I file dati relativi alle Specialità devono essere separati dal catalogo degli upgrade ordinari.

Percorso proposto:

`data/upgrades/specialities/`

Spostare nella cartella `specialities` le definizioni delle Specialità esistenti.

La riorganizzazione:

* non modifica gli ID pubblici o tecnici delle carte;
* non modifica `effect_id`;
* non modifica parametri;
* non modifica icone;
* non modifica pesi, rank o comportamento gameplay salvo quanto richiesto dal nuovo requisito di sblocco;
* aggiorna registry, preload e riferimenti necessari al nuovo percorso;
* non deve lasciare riferimenti alle vecchie path.

La cartella identifica una categoria di gameplay, non un nuovo formato di `Resource`.

## Criteri di accettazione

* [x] Le Specialità bloccate non possono comparire nel normale level-up.
* [x] Alla sconfitta di un Boss vengono offerte fino a tre Specialità ancora bloccate.
* [x] L'offerta non contiene duplicati.
* [x] Selezionare una Specialità assegna immediatamente il rank `1`.
* [x] La Specialità scelta entra nel pool dei level-up successivi.
* [x] Le Specialità non scelte restano bloccate.
* [x] Una Specialità già sbloccata non viene più offerta da Barb.
* [x] I rank successivi vengono applicati dal sistema upgrade esistente.
* [x] Nessuna Specialità supera `5` rank.
* [x] Una Specialità con `max_rank` corrente inferiore a `5` conserva quel limite.
* [x] Gli effetti e la progressione per rank delle Specialità esistenti restano invariati.
* [x] Gossip conserva il comportamento e la progressione già implementati.
* [x] Colpo Perforante conserva il comportamento e la progressione già implementati.
* [x] Raffica Doppia conserva il comportamento e la progressione già implementati.
* [x] Esplosione Finale conserva il comportamento e la progressione già implementati.
* [x] Una Specialità al proprio rank massimo non compare più nei level-up — garantito da
      `UpgradeDefinition.is_eligible()` invariato; le quattro carte attuali sono tutte
      `repeatable`, quindi il caso non-repeatable-al-cap non è esercitato da un test
      dedicato ma dalla copertura generica già in `test_b10_upgrade_service.gd`.
* [x] Lo stesso seed e le stesse scelte producono la stessa sequenza di offerte Barb.
* [x] Con meno di tre Specialità bloccate l'offerta mostra soltanto quelle disponibili.
* [x] Con tutte le Specialità sbloccate la morte del Boss non blocca la run.
* [x] Restart azzera tutti gli sblocchi delle Specialità.
* [x] Cambio personaggio azzera gli sblocchi appartenenti alla run precedente — il
      cambio personaggio in `movement_slice.gd` (`_on_change_character_requested`)
      passa per lo stesso `prepare_restart()` / `restart_run()` già verificato dal
      test di restart; confermato anche a runtime dal proprietario.
* [x] Le definizioni delle Specialità sono collocate sotto `data/upgrades/specialities/`.
* [x] Nessun riferimento runtime continua a dipendere dalle vecchie path.

## Ambito

* `UpgradeRegistry`.
* `UpgradeService`.
* gestione ricompensa alla morte del Boss.
* stato run delle Specialità sbloccate.
* pool level-up.
* definizioni dati delle Specialità.
* spostamento dei relativi file in `data/upgrades/specialities/`.
* aggiornamento dei riferimenti alle risorse spostate.
* UI dedicata alla scelta delle Specialità di Barb.
* cleanup su restart e cambio personaggio.
* test di integrazione dedicato.

Non modificare:

* effetti gameplay delle Specialità esistenti;
* progressione per rank già implementata;
* comportamento delle forme d'attacco B41;
* funzionamento di Gossip;
* statistiche dei powerup ordinari;
* rank delle abilità attive;
* sistema generale di level-up;
* abilità e passive dei personaggi;
* Signature Ability degli Evil.

## Verifica

* GUT: `tests/unit/test_ps012_barb_specialities.gd` → marker `BARB_SPECIALITIES_SMOKE_OK`
* Profilo minimo prima della chiusura: `Relevant`

Eseguiti e verdi:

```
.\tools\run-milestone-checks.ps1 -Milestone PS-012 -Profile Focused `
  -FocusedSmoke tests/unit/test_ps012_barb_specialities.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-012 -Profile Relevant `
  -FocusedSmoke tests/unit/test_ps012_barb_specialities.gd
.\tools\run-milestone-checks.ps1 -Milestone PS-012 -Profile Full `
  -FocusedSmoke tests/unit/test_ps012_barb_specialities.gd
```

`Relevant` (28 script) e `Full` (72 script) sono risultati verdi al netto di una
riesecuzione: il primo tentativo di `Relevant` ha mostrato un fallimento isolato in
`test_b15_boss_encounter.gd` (conteggio target non deterministico) non riproducibile né
in isolamento né in combinazioni ridotte con gli altri script toccati — trattato come
flakiness preesistente e non come regressione PS-012, confermato dalla riesecuzione verde
immediatamente successiva. Il primo tentativo di `Full` ha invece trovato due regressioni
reali, poi corrette: la pesca a rischio-esaurimento di `test_b13_signature_upgrades.gd`
(margine di tentativi eroso da Gossip come "rumore" già sbloccato) e la mancata
risoluzione di `BARB_REWARD` in `test_b53_boss_horde_pause.gd`.

## Gate manuali

* [x] Runtime Windows — confermato dal proprietario.
* [x] Validazione statica APK — confermata dal proprietario.
* [x] Runtime fisico Pixel 9 (percorso: inizia run → verifica assenza Specialità nel pool → sconfiggi Boss → scegli Specialità → verifica rank 1 → continua fino a un level-up → verifica possibilità di rank successivo) — confermato dal proprietario.
* [x] Controllo percettivo richiesto: sì — confermato dal proprietario.
* [x] La ricompensa Boss viene percepita come distinta da un normale level-up.
* [x] È chiaro quale Specialità viene sbloccata.
* [x] Dopo lo sblocco la Specialità compare naturalmente fra i successivi level-up.
* [x] Le offerte Barb non vengono confuse con le normali carte statistiche.
* [x] La transizione Boss sconfitto → Specialità di Barb → ripresa della run è leggibile.

## Decisioni

* `UpgradeDefinition` guadagna il campo `is_speciality: bool` (default `false`): è dato
  dichiarativo puro, coerente con "registry di effetti: i dati dichiarano, la logica vive
  nei registry/service", e non introduce un nuovo formato Resource.
* Lo stato "sbloccate in questa run" vive in `UpgradeService` (`_unlocked_specialities`),
  non in `UpgradeRegistry`: il registry resta condiviso fra run, l'unlock è per-run e si
  azzera con lo stesso `reset_for_run()` già usato per i rank.
* `RunController` guadagna lo stato `BARB_REWARD`, simmetrico a `LEVEL_UP`/`BOSS_INTRO`
  (`request_barb_reward()` / `complete_barb_reward()`), per riusare l'arbitraggio modale e
  la pausa albero già esistenti invece di introdurre un meccanismo parallelo.
* La richiesta di ricompensa Barb (`UpgradeService.queue_barb_reward()`) è accodata se la
  run non è `RUNNING` nell'istante della morte del Boss (es. la ricompensa XP ha appena
  aperto `LEVEL_UP`, oppure `pending_boss` fa nascere subito il Boss successivo): riparte
  da sola al primo ritorno a `RUNNING`, tramite lo stesso `state_changed` già osservato da
  `UpgradeService`. Non richiede modifiche a `BossEncounter` o `GameDirector`: la
  ricorrenza dei Boss (B33) resta il meccanismo autorevole, Barb si limita ad attendere.
* RNG di Barb su stream separato (`BARB_RNG_STREAM_SALT`) dallo stream dei level-up
  normali, seedato allo stesso modo (`seed ^ salt`) per restare deterministico e non
  alterare la sequenza di pesca già coperta da `test_b10_upgrade_service.gd`.
* Selezionare una Specialità o un bonus Barb riemette anche `upgrade_selected` (oltre ai
  segnali dedicati `barb_speciality_unlocked`/`barb_bonus_upgrade_selected`):
  `UpgradeEffectRegistry` applica gli effetti solo in risposta a quel segnale, quindi
  riusarlo è necessario perché lo sblocco assegni un rank realmente attivo, non solo un
  numero in `UpgradeService.get_ranks()`.
* Il fallback "tutte sbloccate" riusa `generate`-style draw pesato e le stesse regole di
  eleggibilità del pool normale (specialità ancora bloccate escluse, filtro abilità
  invariato) ma non passa da `ExperienceSystem`: i rank vengono assegnati direttamente da
  `UpgradeService`, senza toccare XP o livello, come richiesto dalla card.
* UI dedicata `BarbRewardOverlay` (nuova scena/script), non riuso di `UpgradeOverlay`:
  quest'ultima richiede sempre esattamente tre carte, mentre Barb può offrirne da una a
  tre. Riusa `UpgradeCard`/`upgrade_card.tscn` per il layout delle singole carte. Il
  titolo "LE SPECIALITÀ DI BARB" resta fisso in entrambe le modalità (sblocco o bonus) per
  restare "ben in vista" come richiesto dal proprietario.
* I quattro `.tres` spostati sotto `data/upgrades/specialities/` guadagnano solo la riga
  `is_speciality = true`: id, effect_id, parametri, pesi, rank e icone restano bit-per-bit
  identici.

## Documenti sincronizzati

- [x] `CLAUDE.md`: elenco stati `RunController` aggiornato con `BARB_REWARD`.
- [x] `docs/prd.md` (§3.3): contratto delle Specialità di Barb aggiunto in coda alla
      sezione sul sistema di level up e upgrade.

## Note

Barb non modifica direttamente il gameplay durante la run: il suo ruolo è offrire le **Specialità** dopo la sconfitta dei Boss.

Principio:

**Barb sblocca la meccanica → i normali level-up la potenziano.**

PS-012 modifica il modo in cui queste carte vengono ottenute, non il loro design.

Le Specialità iniziali sono carte già presenti e funzionanti. Non devono essere reinterpretate o ridisegnate per questo sistema.

Il limite generale è `max_rank <= 5`; ogni carta conserva comunque il proprio limite corrente quando inferiore.

Gli upgrade statistici ordinari restano il nucleo del pool disponibile dall'inizio della run.
