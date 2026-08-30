---
id: PS-006
titolo: Dai agli Evil una Signature Ability
tipo: feat
area: gameplay
stato: BLOCCATO
priorita: alta
dipende_da: [PS-004]
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-006 — Dai agli Evil una Signature Ability

## Contesto

Gli `Evil <Nome>` sono visivamente differenti, ma oggi condividono statistiche, hitbox e gli stessi pattern del Boss base. Le abilità attive dei personaggi non fanno ancora parte del comportamento dei rispettivi Evil.

Ogni Evil deve diventare riconoscibile anche dal modo in cui viene affrontato, mantenendo alcuni pattern comuni ma aggiungendo una mossa personale derivata dall'attiva del relativo personaggio.

## Comportamento atteso

Ogni Evil conserva i pattern Boss comuni esistenti e aggiunge **una Signature Ability**.

La Signature:

* deriva dall'abilità attiva del personaggio corrispondente;
* viene annunciata chiaramente prima di diventare pericolosa;
* deve poter essere evitata o gestita tramite movimento e posizionamento;
* non deve infliggere danno inevitabile;
* usa valori Boss propri e non copia direttamente quelli dell'abilità Player;
* entra nella rotazione dei pattern senza eliminare i pattern Boss comuni;
* rispetta il seed della run per ogni elemento casuale.

Baseline: la Signature può essere scelta come terzo pattern della rotazione Boss.

### Evil Magno — Onda d'Urto Tellurica

Evil Magno prepara visivamente un forte impatto a terra.

Dopo il telegraph genera una grande onda d'urto radiale.

La zona pericolosa parte dal Boss e si espande verso l'esterno, lasciando al Player il tempo di allontanarsi o attraversare il fronte nel momento corretto.

Effetti:

* danno;
* knockback;
* nessun colpo istantaneo senza telegraph.

La versione Boss non usa il momentum del Player.

### Evil Bea — Powerslide

Una linea di telegraph mostra in anticipo direzione e traiettoria.

Dopo il preavviso Evil Bea esegue un Powerslide rapido lungo quella linea e lascia una scia di fuoco temporanea.

Effetti:

* il contatto con Bea durante lo scatto può danneggiare;
* la scia infligge danno nel tempo;
* il Player può evitare lo scatto leggendo la traiettoria;
* la scia modifica temporaneamente lo spazio sicuro dell'arena.

### Evil Zat — Tempesta di Tuoni

La Signature di Evil Zat deve essere derivata dalla versione definitiva di **PS-004 — Lega Tempesta di Tuoni al danno recuperabile**.

Non implementare la Signature Evil sulla vecchia sequenza di fulmini telegrafati.

La variante Boss deve mantenere l'identità del nuovo Tuono senza introdurre danno globale inevitabile sul Player.

Design definitivo subordinato alla chiusura di PS-004.

### Evil Alea — Gran Piroetta

Evil Alea entra in una breve fase di rotazione e si muove durante l'attacco.

Durante la Piroetta:

* possiede un'area di contatto pericolosa chiaramente visibile;
* insegue il Player con velocità limitata;
* non può cambiare direzione istantaneamente;
* il Player deve mantenere distanza e sfruttare il movimento dell'arena.

La Signature termina dopo una durata configurabile.

### Evil Aleo — Shock Termico

Evil Aleo mostra un telegraph ciano su un'area dell'arena.

La Signature avviene in due fasi:

1. **Freddo**

   * l'area viene evidenziata chiaramente;
   * il Player dentro l'area viene rallentato;

2. **Caldo**

   * dopo un breve intervallo la stessa area detona;
   * il Player ancora presente riceve danno.

Il rallentamento deve lasciare comunque il tempo necessario per uscire dall'area se il telegraph viene letto correttamente.

### Evil Lollo — Cosplay Casuale

Evil Lollo prepara in anticipo una Signature appartenente a un altro Evil.

La Signature scelta:

* viene determinata tramite RNG seedato;
* è annunciata visivamente prima dell'esecuzione;
* non può selezionare Cosplay Casuale;
* non può generare ricorsione;
* usa sempre i parametri Boss della Signature copiata;
* non può scegliere Signature non ancora abilitate o incompatibili.

Il Player deve poter riconoscere quale abilità verrà copiata prima che venga eseguita.

### Evil Migi — Rallentamento Zen

Evil Migi genera temporaneamente una zona Zen attorno a sé.

Dentro la zona:

* il Player viene rallentato;
* i proiettili alleati che entrano vengono assorbiti.

La zona non infligge direttamente danno.

Il comportamento forza il Player a decidere se allontanarsi, aspettare la fine dell'effetto o riposizionarsi per continuare a colpire il Boss.

### Evil Marghe — Reggaeton time!

Evil Marghe genera un clone ballerino separato dal Boss.

Durante la durata:

* il sistema di auto-targeting può preferire il clone;
* il clone devia temporaneamente parte dell'offensiva automatica del Player;
* Evil Marghe continua a utilizzare normalmente i propri pattern;
* il clone è chiaramente distinguibile dal Boss reale;
* il clone scompare alla scadenza o secondo una condizione configurabile.

La Signature non modifica direttamente i comandi del Player.

## Criteri di accettazione

* [ ] Ogni Evil diverso da Zat possiede una Signature Ability dedicata.
* [ ] Evil Zat usa la propria Signature soltanto dopo la definizione definitiva di PS-004.
* [ ] Ogni Signature deriva dall'attiva del personaggio corrispondente.
* [ ] Ogni Signature presenta un telegraph leggibile prima del primo effetto pericoloso.
* [ ] Nessuna Signature infligge danno inevitabile al Player.
* [ ] Ogni Evil conserva almeno un pattern Boss comune oltre alla Signature personale.
* [ ] Le Signature usano parametri Boss separati dai dati delle abilità Player.
* [ ] Modificare il bilanciamento di una Signature Boss non modifica l'abilità del personaggio giocabile.
* [ ] Evil Bea mostra la traiettoria prima del Powerslide.
* [ ] Evil Alea mostra chiaramente l'area pericolosa durante Gran Piroetta.
* [ ] Evil Aleo applica prima il rallentamento e successivamente la detonazione sulla stessa area.
* [ ] Evil Lollo mostra quale Signature ha copiato prima di utilizzarla.
* [ ] Evil Lollo non può copiare Cosplay Casuale né generare ricorsione.
* [ ] Evil Migi rallenta il Player e assorbe proiettili alleati senza infliggere danno diretto tramite la zona.
* [ ] Il clone di Evil Marghe può deviare l'auto-targeting ed è distinguibile dal Boss reale.
* [ ] Tutte le scelte casuali delle Signature sono riproducibili dallo stesso seed.
* [ ] Pausa, Boss intro e stati terminali congelano o eliminano correttamente Signature e VFX.
* [ ] Alla morte del Boss non rimangono aree, cloni, scie, telegraph o altri effetti della Signature.
* [ ] Restart elimina completamente lo stato della Signature precedente.

## Ambito

Sistemi attesi:

* `BossDefinition`;
* controller/pattern del Boss;
* definizioni dati delle Signature Evil;
* sistema di telegraph;
* aree persistenti Boss;
* targeting per il clone di Marghe;
* assorbimento proiettili per Migi;
* selezione seedata delle copie di Lollo;
* cleanup Boss;
* test di integrazione dedicati.

Riutilizzare dove appropriato la logica delle abilità Player, ma senza condividere valori runtime o mutare `AbilityDefinition`.

Non modificare:

* identità e nome degli otto Evil;
* abilità dei personaggi giocabili;
* sistema generale di selezione personaggio;
* probabilità con cui il Boss baseline viene sostituito da un Evil;
* regole generali di pausa e clock della run.

## Verifica

* Smoke: `tests/integration/_evil_signature_abilities_smoke.gd` → marker `EVIL_SIGNATURE_ABILITIES_SMOKE_OK`
* Copertura minima:

  * risoluzione Evil → Signature corretta;
  * telegraph prima del danno;
  * Powerslide e scia di Bea;
  * Piroetta di Alea;
  * doppia fase di Aleo;
  * copia deterministica e anti-ricorsione di Lollo;
  * zona Zen e assorbimento di Migi;
  * clone e targeting di Marghe;
  * cleanup alla morte;
  * cleanup al restart.
* Evil Zat entra nello smoke quando PS-004 è chiusa.
* Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

* [ ] Runtime Windows
* [ ] Validazione statica APK
* [ ] Runtime fisico Pixel 9 con almeno un incontro per ogni Evil
* [ ] Controllo percettivo richiesto: sì
* [ ] Ogni Signature è riconoscibile prima che produca danno.
* [ ] Evil diversi richiedono reazioni differenti al Player.
* [ ] I telegraph restano leggibili insieme ai pattern Boss comuni.
* [ ] Powerslide di Bea resta leggibile a velocità reale.
* [ ] La fase fredda di Aleo lascia materialmente il tempo di uscire prima della detonazione.
* [ ] Gran Piroetta di Alea non produce inseguimenti inevitabili.
* [ ] La copia annunciata di Lollo è comprensibile senza testo tecnico.
* [ ] La zona di Migi non rende impossibile danneggiare il Boss per una durata eccessiva.
* [ ] Il clone di Marghe non viene confuso con il Boss reale.
* [ ] Nessuna Signature produce residui visivi dopo la morte del Boss.

## Decisioni

- **2026-08-30 — Pattern comuni più una Signature personale.** Ogni Evil
  conserva la grammatica Boss condivisa e aggiunge una mossa leggibile.
- **2026-08-30 — Evil Zat dipende da PS-004.** La sua Signature non viene
  fissata prima del nuovo contratto di Tempesta di Tuoni.
- **Baseline da playtest — valori Boss dedicati.** Danno, durata, area e
  cooldown non copiano direttamente le abilità Player.

## Documenti sincronizzati

- [ ] `characters.md`: identità finali delle Signature approvate.
- [ ] `prd.md`: regole comuni dei pattern Boss risultanti.

## Note

Gli Evil non devono diventare semplicemente versioni del Player con più HP.

Struttura desiderata:

**pattern Boss comuni + una Signature personale = identità dell'Evil.**

Le Signature reinterpretano le attive del roster in funzione Boss: maggiore telegraph, aree più leggibili e parametri dedicati.

Le abilità Player correnti di Magno, Bea, Alea, Aleo, Lollo, Migi e Marghe costituiscono il riferimento tematico delle rispettive Signature.

Evil Zat resta intenzionalmente incompleto finché PS-004 non stabilisce il nuovo contratto di Tempesta di Tuoni.

I valori numerici di durata, danno, area, velocità e cooldown delle Signature non vengono fissati in questa card: sono baseline di bilanciamento da definire durante implementazione e playtest.
