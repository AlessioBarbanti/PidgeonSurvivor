---
id: PS-012
titolo: Introduci le Specialità di Barb
tipo: feat
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: []
origine:
milestone:
creato: 2026-08-30
aggiornato: 2026-08-30
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

* [ ] Le Specialità bloccate non possono comparire nel normale level-up.
* [ ] Alla sconfitta di un Boss vengono offerte fino a tre Specialità ancora bloccate.
* [ ] L'offerta non contiene duplicati.
* [ ] Selezionare una Specialità assegna immediatamente il rank `1`.
* [ ] La Specialità scelta entra nel pool dei level-up successivi.
* [ ] Le Specialità non scelte restano bloccate.
* [ ] Una Specialità già sbloccata non viene più offerta da Barb.
* [ ] I rank successivi vengono applicati dal sistema upgrade esistente.
* [ ] Nessuna Specialità supera `5` rank.
* [ ] Una Specialità con `max_rank` corrente inferiore a `5` conserva quel limite.
* [ ] Gli effetti e la progressione per rank delle Specialità esistenti restano invariati.
* [ ] Gossip conserva il comportamento e la progressione già implementati.
* [ ] Colpo Perforante conserva il comportamento e la progressione già implementati.
* [ ] Raffica Doppia conserva il comportamento e la progressione già implementati.
* [ ] Esplosione Finale conserva il comportamento e la progressione già implementati.
* [ ] Una Specialità al proprio rank massimo non compare più nei level-up.
* [ ] Lo stesso seed e le stesse scelte producono la stessa sequenza di offerte Barb.
* [ ] Con meno di tre Specialità bloccate l'offerta mostra soltanto quelle disponibili.
* [ ] Con tutte le Specialità sbloccate la morte del Boss non blocca la run.
* [ ] Restart azzera tutti gli sblocchi delle Specialità.
* [ ] Cambio personaggio azzera gli sblocchi appartenenti alla run precedente.
* [ ] Le definizioni delle Specialità sono collocate sotto `data/upgrades/specialities/`.
* [ ] Nessun riferimento runtime continua a dipendere dalle vecchie path.

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

## Gate manuali

* [ ] Runtime Windows
* [ ] Validazione statica APK
* [ ] Runtime fisico Pixel 9 (percorso: inizia run → verifica assenza Specialità nel pool → sconfiggi Boss → scegli Specialità → verifica rank 1 → continua fino a un level-up → verifica possibilità di rank successivo)
* [ ] Controllo percettivo richiesto: sì
* [ ] La ricompensa Boss viene percepita come distinta da un normale level-up.
* [ ] È chiaro quale Specialità viene sbloccata.
* [ ] Dopo lo sblocco la Specialità compare naturalmente fra i successivi level-up.
* [ ] Le offerte Barb non vengono confuse con le normali carte statistiche.
* [ ] La transizione Boss sconfitto → Specialità di Barb → ripresa della run è leggibile.

## Note

Barb non modifica direttamente il gameplay durante la run: il suo ruolo è offrire le **Specialità** dopo la sconfitta dei Boss.

Principio:

**Barb sblocca la meccanica → i normali level-up la potenziano.**

PS-012 modifica il modo in cui queste carte vengono ottenute, non il loro design.

Le Specialità iniziali sono carte già presenti e funzionanti. Non devono essere reinterpretate o ridisegnate per questo sistema.

Il limite generale è `max_rank <= 5`; ogni carta conserva comunque il proprio limite corrente quando inferiore.

Gli upgrade statistici ordinari restano il nucleo del pool disponibile dall'inizio della run.
