---
id: PS-003
titolo: Conferma il funzionamento di Guarigione Ritardata
tipo: chore
area: gameplay
stato: COMPLETATO
priorita: alta
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-003 — Conferma il funzionamento di Guarigione Ritardata

## Contesto

La passiva di Zat, **Guarigione Ritardata**, converte una parte del danno subito in salute recuperabile e la restituisce se Zat riesce a evitare ulteriori colpi per un certo periodo.

Prima di basare Tempesta di Tuoni sulla quantità di HP recuperabili è necessario confermare esattamente il comportamento runtime della passiva e verificare che coincida con il comportamento desiderato.

## Comportamento atteso

Confermare e documentare almeno questi aspetti:

* quale percentuale del danno ricevuto diventa recuperabile;
* dopo quanto tempo senza subire danni inizia il recupero;
* se il recupero avviene istantaneamente o progressivamente;
* quanto dura il recupero completo;
* cosa succede alla quota recuperabile se Zat viene colpita nuovamente;
* se nuovi danni si sommano alla quota già recuperabile;
* quale sia il limite massimo di HP recuperabili accumulabili;
* cosa accade se Zat riceve un colpo letale mentre possiede HP recuperabili;
* come vengono gestiti heal esterni o variazioni degli HP massimi;
* se pausa, level-up e Boss intro congelano correttamente attesa e recupero;
* se restart e cambio personaggio azzerano completamente lo stato della passiva.

Al termine della verifica il comportamento effettivo deve essere registrato come contratto autorevole prima di collegarlo a PS-004.

## Criteri di accettazione

* [x] È confermata la percentuale di ogni hit che diventa HP recuperabili: `recoverable_fraction = 0.35` del danno **applicato**.
* [x] È confermato il tempo necessario senza nuovi danni prima dell'inizio della guarigione: `recovery_delay = 3.0` s.
* [x] È confermato se la guarigione è istantanea o progressiva: è progressiva.
* [x] Se progressiva, sono confermati durata e ritmo del recupero: `recovery_duration = 4.0` s, drenaggio lineare.
* [x] È documentato cosa succede alla quota recuperabile quando Zat viene colpita durante l'attesa: si somma, l'attesa riparte da capo.
* [x] È documentato cosa succede alla quota recuperabile quando Zat viene colpita durante il recupero: il residuo sopravvive, si somma e riparte l'attesa piena.
* [x] È confermato se più hit accumulano HP recuperabili e con quale limite: accumulano, **senza alcun tetto**.
* [x] È verificato il comportamento in caso di danno letale: la quota non assorbe il colpo e non resuscita Zat.
* [x] È verificata l'interazione con eventuali cure e modifiche degli HP massimi.
* [x] Attesa e guarigione non avanzano durante stati non `RUNNING` (pausa manuale, level-up e Boss intro verificati).
* [x] Restart e cambio personaggio eliminano completamente gli HP recuperabili e ogni timer associato.
* [x] Il comportamento confermato è compatibile con la lettura degli HP recuperabili richiesta da PS-004.
* [x] Eventuali differenze tra comportamento runtime e comportamento desiderato sono registrate esplicitamente prima di modificare il codice (vedi *Differenze registrate*).

## Ambito

Sistemi da verificare:

* `FriendDefinition` di Zat;
* controller delle passive;
* `HealthComponent` del Player;
* timer e stato runtime di Guarigione Ritardata;
* pause e transizioni del `RunController`;
* restart e cambio personaggio.

Non modificare durante questa card:

* Tempesta di Tuoni;
* valori o meccaniche della passiva prima della conclusione della verifica;
* comportamento delle passive degli altri personaggi.

Questa card serve prima di tutto a **stabilire il contratto corrente**. Eventuali correzioni emerse dalla verifica devono essere eseguite tramite una card separata o tramite un aggiornamento esplicito di questa card.

## Verifica

* Smoke: `tests/unit/test_ps003_zat_delayed_healing.gd` (10 test, 108 asserzioni).
  La card chiedeva `tests/integration/_zat_delayed_healing_contract_smoke.gd`
  con marker `ZAT_DELAYED_HEALING_CONTRACT_SMOKE_OK`: quel percorso appartiene
  alla convenzione legacy. Il runner raccoglie solo `tests/**/test_*.gd` e i
  marker sono stati rimossi nella conversione a GUT, quindi uno smoke con quel
  nome non verrebbe mai eseguito. Formulazione corretta adottata: test GUT in
  `tests/unit/`, come impone `CLAUDE.md`.
* Copertura minima:

  * singolo colpo;
  * più colpi consecutivi;
  * nuovo colpo durante l'attesa;
  * nuovo colpo durante il recupero;
  * pausa durante l'attesa;
  * pausa durante il recupero;
  * danno letale;
  * restart;
  * cambio personaggio.
* Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

Nessuno di questi gate è stato eseguito, e nessuno è stato dichiarato superato.
Il proprietario li ha giudicati **non applicabili** il 2026-08-30: la card non ha
modificato una riga di runtime — ha prodotto un test e la trascrizione di un
contratto già esistente — quindi non c'è comportamento che possa differire fra
esecuzione headless, Windows e Android. I gate percettivi sulla stessa materia
sono ereditati da PS-004, dove esisterà finalmente qualcosa da guardare.

* [—] Runtime Windows — **non applicabile**: nessun runtime modificato.
* [—] Runtime fisico Pixel 9 — **non applicabile**: nessun runtime modificato,
  nessun APK prodotto per questa card.
* [—] Verificare visivamente che la salute recuperabile sia comprensibile durante
  una run reale — **ereditato da PS-004** (decisione del 2026-08-30 su D3): oggi
  la quota non ha rappresentazione a schermo, e il tell sarà l'aura elettrica a
  tre fasce.
* [—] Verificare che un nuovo colpo produca il comportamento atteso sia durante
  l'attesa sia durante la guarigione — parte funzionale coperta dai test, parte
  percettiva **ereditata da PS-004** per la stessa ragione. In una run reale
  resta comunque osservabile dalla barra della vita: dopo 3 s senza colpi
  risale progressivamente per 4 s.
* [—] Controllo percettivo richiesto: sì → assorbito da PS-004.

## Decisioni

- **2026-08-30 — Nessun dettaglio della passiva viene assunto.** Percentuali,
  tempi, accumulo e casi limite devono essere confermati prima di diventare
  contratto.
- **2026-08-30 — PS-004 resta bloccata da questa verifica.** Il danno di
  Tempesta di Tuoni non può dipendere da uno stato ancora ambiguo.
- **2026-08-30 — Il contratto è stato confermato, non riscritto.** Nessuna riga
  di runtime è stata toccata: la card produce un test che fotografa il
  comportamento esistente e la sua trascrizione in `characters.md`. Tutte le
  108 asserzioni sono passate alla prima esecuzione, quindi lettura statica del
  codice e comportamento runtime coincidono.
- **2026-08-30 — Smoke GUT in `tests/unit/` invece dello smoke integration
  richiesto.** Il percorso e il marker indicati nella card appartengono alla
  convenzione legacy e non sarebbero stati eseguiti dal runner. La motivazione
  è nella sezione *Verifica*.
- **2026-08-30 — Le differenze emerse restano non corrette.** L'ambito della
  card vieta di modificare la passiva: D1, D2 e D3 sono registrate qui e
  attendono una decisione del proprietario, non una correzione silenziosa.
- **2026-08-30 — Il proprietario ha accettato tutte e quattro le differenze.**
  D1, D2 e D4 diventano contratto senza alcuna modifica al codice; D3 non è un
  difetto della passiva ma un lavoro mancante, ed è delegato a PS-004. Il
  comportamento runtime confermato *è* quindi il comportamento desiderato: non
  resta alcuna correzione pendente su Guarigione Ritardata.
- **2026-08-30 — Gate di piattaforma dichiarati non applicabili, non superati.**
  La card non ha toccato il runtime: non esiste un comportamento che possa
  divergere fra headless, Windows e Android, quindi una sessione di gioco o un
  APK non produrrebbero evidenza aggiuntiva sul contratto. I gate percettivi
  passano a PS-004, che introduce il tell mancante. Decisione del proprietario,
  registrata qui perché la card si chiude senza che quei gate siano stati
  eseguiti.

## Differenze registrate

Comportamenti confermati nel runtime che potrebbero non coincidere con quello
desiderato. Nessuno è stato modificato da questa card, e il proprietario le ha
accettate tutte il 2026-08-30: sono contratto, non debito.

- **D1 — L'accumulo non ha alcun tetto.** `_recoverable_health` cresce a ogni
  colpo senza limite: cinque colpi da `20` producono `35` HP recuperabili, più
  del triplo della vita residua. Nessun parametro `recoverable_max` esiste nei
  dati. Per PS-004 significa che la fascia di carica alta non ha soffitto.
  **Accettata (2026-08-30):** nessun cap aggiuntivo alla quota. Il soffitto lo
  mette PS-004 a valle: la Tempesta usa soltanto le tre fasce, quindi una quota
  oltre la soglia alta non aumenta ulteriormente la potenza.
- **D2 — A vita piena la quota viene scartata per intero, non conservata.**
  In [friend_passive_controller.gd:286-289](../../../scripts/content/friend_passive_controller.gd#L286-L289),
  se `heal()` non può applicare nulla (vita già al massimo, per esempio dopo un
  pickup di salute), il ramo azzera `_recoverable_health` invece di scalarne la
  sola parte non applicabile. Un pickup raccolto durante l'attesa quindi
  *cancella* la guarigione differita già maturata.
  **Accettata (2026-08-30):** raggiungere la vita massima azzera la quota
  residua. La guarigione differita non è un credito da spendere su danni
  futuri, e non deve diventarlo.
- **D3 — La quota non è visibile da nessuna parte.** `delayed_healing_changed`
  non ha alcun consumatore nel progetto e `_refresh_passive_state_outline()` non
  ha un ramo per `ZAT_DELAYED_HEALING`: Zat è l'unico profilo a fasi senza tell.
  È la ragione per cui il gate percettivo di questa card non è chiudibile oggi.
  L'aura a tre fasce di PS-004 è il candidato naturale a colmarlo.
  **Delegata a PS-004 (2026-08-30):** l'aura elettrica diventa il tell visivo
  della quantità recuperabile. Non è un difetto della passiva, quindi non apre
  una card di correzione; il gate percettivo di PS-003 si sposta su PS-004.
- **D4 — L'attesa scade con un tick di ritardo.** Il ramo dell'attesa decrementa
  e ritorna nello stesso frame, quindi il primo HP torna indietro al tick
  successivo alla scadenza. Irrilevante in gioco (un frame), ma va tenuto
  presente quando si scrivono test a passi grandi.
  **Accettata (2026-08-30):** nessun intervento, salvo evidenza di un effetto
  percepibile durante il gioco.

## Documenti sincronizzati

- [x] `characters.md`: contratto finale di Guarigione Ritardata, sotto la scheda
  di Zat.
- [x] PS-004: sezione *Termini confermati da PS-003* con lettura, ordine di
  grandezza delle soglie, durata della carica e azzeramenti bruschi.

## Note

Il comportamento descritto attualmente per Zat è:

**parte del danno subito resta recuperabile; se Zat evita altri colpi per alcuni secondi, quella quota torna indietro.**

Questa card non assume ulteriori dettagli finché non vengono verificati nel runtime e nei dati.

PS-003 è prerequisito di **PS-004 — Lega Tempesta di Tuoni al danno recuperabile**, perché la nuova potenza del Tuono dipende dalla quantità corrente di HP recuperabili.

PS-004 resta `BLOCCATO`: questa card è `IN VERIFICA`, non `COMPLETATO`, finché i
gate manuali non sono chiusi.

Comandi eseguiti come evidenza:

    .\tools\run-milestone-checks.ps1 -Milestone PS-003 -Profile Focused
        -FocusedSmoke tests/unit/test_ps003_zat_delayed_healing.gd -RefreshEditor
    .\tools\run-milestone-checks.ps1 -Milestone PS-003 -Profile Relevant
        -FocusedSmoke tests/unit/test_ps003_zat_delayed_healing.gd

Esito:

- `Focused`: `status=PASS bootstrap=1/1 focused=1/1 steps=2/2` — 10 test, 108
  asserzioni, 0 fallimenti, nessun `SCRIPT ERROR` nel log.
- `Relevant`: `status=PASS focused=1/1 regression=8/8 steps=9/9` — 8 script, 15
  test, 1135 asserzioni, 0 fallimenti, nessun `SCRIPT ERROR` nel log.

Il test è registrato in `tools/milestone-test-map.json` sotto le regole di
`data/friends/*` e `scripts/content/friend_passive_controller.gd`, così una
modifica futura alla passiva lo riesegue automaticamente in profilo `Relevant`.
