# Archivio — Ultima dashboard B-series prima del workflow solo-card

> Snapshot del 30 agosto 2026. La fonte operativa corrente è la
> [`board delle card`](../cards/README.md); questo file non va aggiornato.

Ultimo aggiornamento: 30 agosto 2026

Questo file è la **fonte di verità operativa**: contiene soltanto stato corrente,
ordine di lavoro, dipendenze e gate. Il dettaglio storico B03–B54 è conservato
nello [snapshot del piano precedente](../archive/development-plan-through-b54-2026-08-30.md);
diagnosi e matematica B40–B54 restano nel
[piano di evoluzione archiviato](../archive/gameplay-evolution-plan-2026-08-28.md).

## 1. Stato corrente

Il 30 agosto 2026 il proprietario ha accettato operativamente come
`COMPLETATO` tutte le slice già implementate che risultavano ancora
`IN VERIFICA`, rinunciando a nuove prove fisiche, percettive, Full o Release.
Questa decisione **non crea evidenza tecnica retroattiva**: le note
`*-verification.md` continuano a registrare con precisione quali comandi,
artefatti e prove erano stati realmente eseguiti.

Non sono comprese nella chiusura le attività non implementate o ancora da
definire: B23, B46 e le card `PRONTO` restano aperte.

| Coda | Elementi |
|---|---|
| In corso | [PS-001](../cards/PS-001-tell-di-stato-senza-snaturare-lo-sprite.md) |
| Pronti B-series | B23, B46 |
| Card pronte | [PS-003–PS-009](../cards/README.md) |
| In verifica | Nessuna: le slice implementate sono state accettate operativamente dal proprietario |
| Rifiutati | B48 |

### Ordine operativo

1. terminare il lavoro già `IN CORSO`;
2. scegliere il primo elemento `PRONTO` con dipendenze chiuse, rispettando la
   priorità della [board](../cards/README.md);
3. non riaprire una slice `COMPLETATO` per un cambiamento nuovo: creare una card
   o una nuova B-series con criteri propri;
4. eseguire B20 packaging soltanto dopo B23, come stabilito da DIST-003.

## 2. Vocabolario degli stati

| Stato | Significato |
|---|---|
| `DA DEFINIRE` | Mancano decisioni necessarie a scrivere criteri verificabili |
| `BLOCCATO` | Una dipendenza esplicita impedisce l'avvio |
| `PRONTO` | Contratto e dipendenze consentono di iniziare |
| `IN CORSO` | Implementazione attiva |
| `IN VERIFICA` | Codice e automatici pronti, gate manuali ancora aperti |
| `VERIFICATO` | Tutti i gate chiusi, commit dedicato mancante |
| `COMPLETATO` | Slice chiusa; eventuali eccezioni probatorie sono dichiarate |
| `RIFIUTATO` | Proposta esplicitamente esclusa |

## 3. Roadmap consolidata

### Fondazioni e vertical slice

| Intervallo | Stato | Contenuto |
|---|---|---|
| B03–B18B, incluse B06A, B09A e B17A | `COMPLETATO` | Movimento, combattimento, sopravvivenza, XP, upgrade, Boss, roster, abilità, audio/VFX e identità baseline |
| B18C–B18W | `COMPLETATO` | Animazione cast, abilità, touch, arena/HUD, welcome, selezione, asset e hardening |
| B20 | `BLOCCATO` | Packaging Windows, APK release e AAB; dipende da B23 |
| B22 | `COMPLETATO` | Boss piccione speciale e varianti Evil |
| B23 | `PRONTO` | Modalità Difesa Grigliata |

### Evoluzione dopo la vertical slice

| ID | Attività | Stato | Nota operativa |
|---|---|---|---|
| B24 | Scala visiva del Player | `COMPLETATO` | Candidato `1,25×` accettato operativamente |
| B25 | Vita Player solo nel HUD | `COMPLETATO` | Indicatore circolare rimosso |
| B26 | Potenziamento danno dedicato | `COMPLETATO` | `Forchettone da Braciere` e stacking |
| B27 | Icone powerup raster | `COMPLETATO` | Master, derivati e manifest |
| B28 | Densità orde e TTK | `COMPLETATO` | Profilo bullet-hell accettato operativamente |
| B29 | Musica di background | `COMPLETATO` | Loop run/menu e mix accettati operativamente |
| B30 | Boss senza aura viola | `COMPLETATO` | Fallback geometrico corretto |
| B31 | Padding pausa e abilità | `COMPLETATO` | Safe area e target touch aggiornati |
| B32 | CTA welcome e ingranaggio | `COMPLETATO` | Frontend coerente |
| B33 | Run continua e Boss ricorrenti | `COMPLETATO` | L'estensione futura a Difesa Grigliata appartiene a B23 |
| B34 | UI pixel-fantasy arcade | `COMPLETATO` | Presentazione accettata operativamente |
| B35 | Prima ondata powerup grigliatori | `COMPLETATO` | Contratti nel [catalogo powerup](../powerup-catalog.md) |
| B36 | Sistema tipografico | `COMPLETATO` | Scala condivisa e regressioni di layout |
| B37 | Densità leggibile e direzione orde | `COMPLETATO` | Settori e offset di inseguimento |
| B38 | Arena, camera e ostacoli | `COMPLETATO` | Mondo fisso più grande del viewport |
| B39 | Pickup di cura | `COMPLETATO` | Coscia di piccione rara |
| B40 | Archetipi nemici | `COMPLETATO` | Sciamatore, corazzato, divisore e tiratore |
| B41 | Forme d'attacco arma | `COMPLETATO` | Perforazione, multishot ed esplosione |
| B42 | Passive Marghe e Alea | `COMPLETATO` | Effetti misurabili |
| B43 | Tempesta di Tuoni con decisione | `COMPLETATO` | Il nuovo rework proposto è tracciato da PS-003/PS-004 |
| B44 | Tell di stato Aleo e Lollo | `COMPLETATO` | Ulteriore restyle tracciato da PS-001 |
| B45 | Identità Bea, Migi e Magno | `COMPLETATO` | Verbi distinti contro B40 |
| B46 | Eventi d'ondata | `PRONTO` | Dettaglio trasferito a PS-008 |
| B47 | Statistiche base per profilo | `COMPLETATO` | Scarti dichiarativi e reset |
| B48 | Record persistenti | `RIFIUTATO` | Nessuna meta-progressione o classifica |
| B49 | Texture archetipi speciali | `COMPLETATO` | Asset runtime e manifest completi; candidato accettato operativamente |
| B50 | Ostacoli leggibili e confine arena | `COMPLETATO` | Codice accettato operativamente |
| B51 | Direzione Powerslide | `COMPLETATO` | Usa il vettore persistente |
| B52 | Playfield protetto dai controlli | `COMPLETATO` | Esclusione ingombro abilità |
| B53 | Stop orde durante il Boss | `COMPLETATO` | Spawn ordinario sospeso |
| B54 | Tutorial dalla welcome | `COMPLETATO` | Carosello in `BOOT` accettato operativamente |

## 4. Backlog B-series pronto

### B23 — Modalità Difesa Grigliata

Stato: `PRONTO`. Dipende da B22; B20 resta successivo.

- aggiungere `GameModeDefinition` e scelta modalità in `BOOT`, senza avviare la run;
- creare una griglia centrale con salute propria e HUD fuori dal playfield;
- consentire ai nemici di scegliere Player o obiettivo tramite dati;
- terminare in `DEFEAT` alla morte del Player o della griglia;
- isolare seed, target, HUD, spawn e cleanup per modalità;
- coprire entrambe le modalità, restart, pausa, Boss e target con smoke e gate
  Windows/Android pertinenti.

Contratto storico completo:
[snapshot B23](../archive/development-plan-through-b54-2026-08-30.md#b23--modalità-difesa-grigliata).

### B46 — Eventi d'ondata

Stato: `PRONTO`. Dipende da B37 e B40; la card eseguibile è
[PS-008](../cards/PS-008-eventi-di-ondata.md).

- eventi annunciati, riconoscibili e limitati nel tempo;
- cadenza indipendente dai Boss e nessun overlap con `BOSS_INTRO`;
- composizione e settori deterministici per seed;
- rispetto di cap nemici, budget XP e priorità dei telegraph.

Razionale completo:
[snapshot B46](../archive/gameplay-evolution-plan-2026-08-28.md#b46--eventi-dondata).

## 5. Board delle modifiche puntuali

Le richieste che non richiedono una nuova slice B-series vivono esclusivamente
in [`docs/cards/`](../cards/README.md). La card contiene comportamento atteso,
criteri, dipendenze e gate; questo piano conserva soltanto il collegamento e lo
stato aggregato.

Una card va promossa a B-series solo se introduce un sistema o richiede gate di
piattaforma autonomi. Dopo la promozione la card resta come puntatore, non come
seconda specifica.

## 6. Gate comuni

Ogni nuova slice applica soltanto i gate pertinenti:

- smoke deterministico con marker `*_SMOKE_OK` e uscita non nulla su errore;
- profilo `Relevant` prima del checkpoint e `Full`/`Release` quando richiesti;
- runtime Windows distinto dall'export riuscito;
- APK statico distinto da installazione e runtime Android;
- touch, multitouch, lifecycle, performance e accettazione percettiva richiedono
  evidenza specifica quando fanno parte del nuovo contratto;
- nessuna prova storica viene trasferita automaticamente a un artefatto cambiato.

Il workflow completo è in
[`verification-workflow.md`](../verification-workflow.md); le evidenze sono
indicizzate in [`docs/README.md`](../README.md).

## 7. Definition of Done

Una slice nuova è chiusa quando:

1. criteri e dipendenze sono soddisfatti;
2. codice e dati rispettano i contratti architetturali di `CLAUDE.md`;
3. smoke e regressioni pertinenti sono verdi e i log non contengono marker di errore;
4. documenti di prodotto, decisioni, approvazioni e manifest sono sincronizzati;
5. i gate manuali richiesti sono registrati oppure il proprietario ne accetta
   esplicitamente la rinuncia, senza trasformarla in evidenza tecnica;
6. il diff è focalizzato e non include output generati o modifiche estranee.
