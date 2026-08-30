---
id: PS-004
titolo: Lega Tempesta di Tuoni al danno recuperabile
tipo: feat
area: gameplay
stato: BLOCCATO
priorita: alta
dipende_da: [PS-003]
origine: B43
creato: 2026-08-29
aggiornato: 2026-08-30
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

* [ ] Tempesta di Tuoni non genera più fulmini telegrafati nell'arena.
* [ ] Ogni nemico vivo fotografato all'attivazione riceve esattamente un colpo.
* [ ] Nemici comparsi dopo lo snapshot non vengono colpiti.
* [ ] La fascia bassa mostra esattamente 1 fulmine verde.
* [ ] La fascia media mostra esattamente 2 fulmini gialli.
* [ ] La fascia alta mostra esattamente 3 fulmini rossi.
* [ ] La velocità di rotazione aumenta da fascia bassa a media ad alta.
* [ ] Al rank 1 le tre fasce infliggono rispettivamente `12`, `24` e `36` danni.
* [ ] Usare Tempesta di Tuoni non modifica gli HP recuperabili accumulati.
* [ ] Guarigione Ritardata continua normalmente dopo l'attivazione.
* [ ] I fulmini orbitanti non possono danneggiare o interagire con altre entità.
* [ ] Cambiare fascia aggiorna numero, colore e velocità dell'aura.
* [ ] Pausa e stati non `RUNNING` congelano correttamente aura e cooldown.
* [ ] Restart e cambio personaggio eliminano ogni stato e VFX residuo.
* [ ] Il nome pubblico resta **Tempesta di Tuoni**.

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

* Smoke: `tests/integration/_zat_thunder_charge_smoke.gd` → marker `ZAT_THUNDER_CHARGE_SMOKE_OK`
* Copertura minima:

  * tre soglie di carica;
  * danno `12 / 24 / 36`;
  * snapshot dei bersagli;
  * HP recuperabili invariati dopo l'attivazione;
  * aura corretta per numero/colore/fascia;
  * cleanup su restart e cambio personaggio.
* Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

* [ ] Runtime Windows
* [ ] Validazione statica APK
* [ ] Runtime fisico Pixel 9: Zat → accumula progressivamente danno recuperabile → verifica verde/giallo/rosso → attiva il Tuono nelle tre fasce
* [ ] Controllo percettivo richiesto: sì
* [ ] 1/2/3 fulmini restano leggibili con orde dense.
* [ ] Verde/giallo/rosso restano distinguibili durante il gameplay.
* [ ] Le tre velocità di rotazione risultano chiaramente differenti.
* [ ] La fascia rossa comunica chiaramente uno stato di alta carica.
* [ ] Il VFX non viene confuso con proiettili o telegraph ostili.
* [ ] Tempesta di Tuoni non viene percepita come la shockwave di Magno.

## Decisioni

- **2026-08-29 — Danno basato su una fotografia dei bersagli vivi.** Ogni
  nemico presente all'attivazione riceve una sola istanza di danno.
- **2026-08-29 — Gli HP recuperabili non vengono consumati.** La sinergia
  rafforza l'attiva senza annullare la funzione difensiva della passiva.
- **Baseline da playtest — tre fasce a 5% e 12%.** Soglie e moltiplicatori
  restano configurabili finché non vengono validati.

## Documenti sincronizzati

- [ ] `characters.md`: contratto finale dell'attiva e della sinergia con Zat.
- [ ] `content-approvals.md`: eventuali asset dell'aura, se introdotti.

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
