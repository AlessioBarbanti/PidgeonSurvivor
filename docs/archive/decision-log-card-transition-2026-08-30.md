# Archivio — Ultimo decision log prima del workflow solo-card

> Snapshot del 30 agosto 2026. Le nuove decisioni vivono nella card che le
> origina; i contratti risultanti vengono sincronizzati nei documenti durevoli.

Ultimo aggiornamento: 30 agosto 2026

Questo registro contiene decisioni ancora operative e questioni aperte. Il
[registro completo fino al 30 agosto](../archive/decision-log-through-2026-08-30.md)
conserva razionali, conseguenze e decisioni superate.

## Regole

- `Confermata`: decisione esplicita del proprietario.
- `Baseline operativa`: assunzione reversibile usata per avanzare.
- `Aperta`: scelta ancora necessaria.
- Una decisione nuova deve avere un ID, un motivo e una conseguenza osservabile.
- Gli stati tecnici restano nelle evidenze; questo file non trasforma
  un'accettazione proprietario in una prova mai eseguita.

## Decisioni correnti

| ID | Stato | Decisione | Conseguenza |
|---|---|---|---|
| DOC-001 | Confermata | `development-plan.md` è una dashboard corrente; dettagli conclusi e bozze superate vivono in `docs/archive/` | Stato e ordine si leggono senza attraversare lo storico |
| DOC-002 | Confermata | Il backlog puntuale vive in `docs/cards/`; non si mantengono tracker temporanei paralleli | Ogni richiesta ha una sola specifica operativa |
| ACCEPT-001 | Confermata | Il 30 agosto 2026 il proprietario accetta come `COMPLETATO` tutte le slice già implementate ancora `IN VERIFICA`, senza nuove prove fisiche o automatiche | Chiusura operativa; nessuna evidenza tecnica retroattiva viene dichiarata |
| PLAT-001 | Confermata | Windows x64 e Android ARM64 sono target co-primari | I nuovi contratti applicano i gate pertinenti su entrambe le piattaforme |
| TECH-001 | Baseline operativa | Godot 4.7.1 Standard, GDScript tipizzato, renderer Compatibility | Un solo stack per Windows e Android |
| AND-001 | Confermata | Android 12–16, `minSdk 31`, `targetSdk/compileSdk 36`, landscape | Preset e verifiche conservano questo intervallo |
| APP-001 | Confermata | Package `com.ilgioco.pidgeonsurvivor` | Identità Android stabile |
| APP-003 | Confermata | Nome `Pidgeon Survivor`, sottotitolo `It's grilling time!` | UI, export e documenti usano la stessa identità |
| DIST-001 | Confermata | Prima distribuzione tramite APK diretto | Pubblicazione Play non blocca la prima release |
| DIST-003 | Confermata | B20 segue B22 e B23 | Packaging finale resta bloccato da B23 |
| ARCH-001 | Confermata | Architettura scene-local e signal-driven, senza autoload/event bus | `RunController` resta autorità sulla run |
| DATA-001 | Confermata | Resource dichiarative con `effect_id`; logica nei registry GDScript | Nessuna funzione eseguibile nei dati |
| INPUT-001 | Confermata | `InputRouter` unifica tastiera, controller e touch | Stesse intenzioni e nessuna ripresa automatica dopo lifecycle |
| UI-001 | Confermata | Flusso `welcome → (tutorial) → selezione → run → pausa` | `BOOT` resta inattivo fino alla conferma |
| ARENA-001 | Confermata | `ArenaWorld` governa mondo fisico; `ArenaLayout` safe area e HUD | Nessuna coordinata schermo fissa nel gameplay |
| PERF-001 | Confermata | I profili prestazionali cambiano presentazione, non bilanciamento invisibile | Cap gameplay comuni finché non deciso altrimenti |
| GAME-001 | Confermata | Sopravvivenza è continua fino a sconfitta/uscita; Boss ricorrenti | La morte del Boss non chiude la run |
| GAME-002 | Confermata | Nessun potere o record persistente fra run | B48 resta rifiutato |
| CONTENT-001 | Confermata | Roster, identità e provenienze approvate sono in `characters.md` e `content-approvals.md` | Le nuove identità richiedono sincronizzazione esplicita |
| ASSET-001 | Confermata | Master e derivati hanno provenienza, licenza, trasformazioni e SHA-256 nel manifest locale | Le sorgenti HD restano fuori dall'export |

I dettagli storici delle decisioni di input, combattimento, progressione,
abilità, Boss, contenuti, asset, audio e visual sono ancora autorevoli nel
[registro archiviato](../archive/decision-log-through-2026-08-30.md), salvo
contrasto con una riga corrente più recente.

## Decisioni aperte

| ID | Entro | Decisione richiesta |
|---|---|---|
| OPEN-004 | Prima di B20 | Identità, percorso sicuro e backup del release keystore |
| OPEN-005 | Prima di B20 | Aggiungere o meno l'icona Android monocromatica opzionale |

Bilanciamento finale di curva XP, danno, spawn e Boss resta materia di playtest:
una modifica concreta deve entrare in una card o nuova slice, non in una nota
libera del decision log.
