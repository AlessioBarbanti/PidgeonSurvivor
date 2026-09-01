---
id: PS-060
titolo: Compilare l'APK Android in CI e pubblicarlo come GitHub Release
tipo: chore
area: tooling
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-09-01
aggiornato: 2026-09-01
---

# PS-060 — Compilare l'APK Android in CI e pubblicarlo come GitHub Release

## Contesto

Oggi l'unico modo per ottenere un APK è esportare da un editor Godot locale su
Windows, seguendo `docs/setup.md`: toolchain con percorsi personali,
`godot_console`, Android SDK e NDK installati a mano. Una sessione di lavoro
remota (senza Windows, senza Godot, senza Android SDK installati) non può
produrre un APK da consegnare al proprietario.

Il proprietario ha chiesto esplicitamente la soluzione "GitHub Release": un
workflow CI che compila l'APK debug e lo allega come asset scaricabile a una
Release GitHub, evitando di modificare `.gitignore` o di mettere in stage un
binario in `/exports/` (che CLAUDE.md vieta esplicitamente).

## Comportamento atteso

Dal repository GitHub, un run manuale del workflow (`workflow_dispatch`)
produce un APK Android debug con le stesse versioni pinnate documentate in
`docs/setup.md` (Godot 4.7.1, JDK 17, Android build-tools 36.1.0, NDK
29.0.14206865, minSdk 31, targetSdk 36, `arm64-v8a`) e lo pubblica come asset
scaricabile di una GitHub Release, senza richiedere alcun toolchain locale né
committare il binario nella cronologia git.

## Criteri di accettazione

- [x] Il workflow è azionabile manualmente da GitHub Actions
      (`workflow_dispatch`) e non richiede input diversi da quelli di
      default.
      *Lanciato due volte da questa sessione via `run_workflow` senza alcun
      input: [run #1](https://github.com/AlessioBarbanti/PidgeonSurvivor/actions/runs/33477655843)
      (fallito, vedi sotto) e
      [run #2](https://github.com/AlessioBarbanti/PidgeonSurvivor/actions/runs/33478203059)
      (verde).*
- [x] Il workflow installa Godot 4.7.1 headless e i relativi template di
      export, JDK 17 e Android SDK/NDK con le stesse versioni di
      `docs/setup.md`, senza introdurre valori diversi o non documentati.
      *Confermato dai log del run #2: `Godot Engine v4.7.1.stable.official`,
      JDK 17 Temurin, `build-tools;36.1.0`/`ndk;29.0.14206865` installati e
      usati (aapt2/apksigner letti dal path con quella versione esatta).*
- [x] Il workflow esporta il preset `Android APK` già presente in
      `export_presets.cfg` (nessun preset nuovo, nessuna modifica ai preset
      esistenti) producendo un `.apk` firmato con il keystore di debug
      predefinito di Godot (nessun segreto nuovo nel repository).
      *`export_presets.cfg` non toccato in nessun commit di questa card;
      badging dell'APK reale conferma package, versionName e ABI attesi.*
- [x] Prima di pubblicare, il workflow esegue almeno l'ispezione statica
      minima descritta in `docs/setup.md` (package
      `com.ilgioco.pidgeonsurvivor`, `minSdk` 31, `targetSdk` 36, sola ABI
      `arm64-v8a`, firma valida) e fallisce se un controllo non passa, invece
      di pubblicare un artefatto rotto.
      *Comportamento osservato in entrambe le direzioni: il run #1 è
      realmente fallito quando un controllo (bug di case-sensitivity nel mio
      grep, non nell'APK) non ha combaciato, senza pubblicare nulla; il run
      #2, con lo stesso APK sostanzialmente equivalente, ha superato package,
      `minSdkVersion:'31'`, `targetSdkVersion:'36'`, ABI `arm64-v8a` e
      `apksigner verify` prima di procedere.*
- [x] L'APK risultante è allegato come asset di una GitHub Release (non
      committato in nessuna cartella del repository); una Release precedente
      con lo stesso tag viene aggiornata invece di accumulare release
      duplicate a ogni run manuale.
      *Release `android-debug-latest` pubblicata con asset
      `pidgeon-survivor-debug.apk` (~101 MB), confermata via
      `get_release_by_tag`. **Aggiornamento 2026-09-01:** un run #3
      successivo (fix PS-059 sul draw order) ha confermato anche la parte
      "aggiorna invece di duplicare": stessa Release (`id 380263638`),
      asset sostituito con un nuovo id/digest/timestamp invece di crearne
      una seconda.*
- [x] `/exports/`, `/android/build/` e le altre voci di `.gitignore` restano
      invariate: il workflow non richiede di tracciare artefatti generati.
      *`.gitignore` non toccato in nessun commit di questa card.*

## Ambito

- Nuovo file `.github/workflows/*.yml`.
- Eventuale nota breve in `docs/setup.md` che documenta l'esistenza del
  percorso CI accanto a quello locale Windows (non lo sostituisce).

Non toccare:

- `export_presets.cfg` (preset, ABI, ID pacchetto, icone già validati);
- `.gitignore` per `/exports/`, `/android/build/`, `/android/.gradle/`;
- qualunque contratto di runtime, `RunController`, gameplay o dati;
- il percorso di export locale Windows descritto in `docs/setup.md`, che
  resta il riferimento per i gate manuali di `gate-piattaforme`.

## Verifica

- Non esiste uno smoke GUT per questa card: è infrastruttura CI, non
  comportamento runtime del gioco.
- Verifica reale: lanciare il workflow su GitHub Actions
  (`workflow_dispatch`) e leggerne i log fino al completamento; l'esito è
  onesto solo se il run è stato osservato verde almeno una volta, non se il
  file YAML "sembra corretto".

## Gate manuali

- [x] Runtime Windows: non pertinente, il percorso locale non cambia.
- [x] Validazione statica APK: eseguita in CI e osservata verde sul
      [run #2](https://github.com/AlessioBarbanti/PidgeonSurvivor/actions/runs/33478203059)
      (`Static APK inspection`, conclusion `success`).
- [x] Runtime fisico Pixel 9: non richiesto da questa card (verifica solo che
      l'APK si generi e sia strutturalmente valido, non il gameplay). Non
      installato su device reale in questa sessione: resta un controllo
      facoltativo del proprietario, non un gate bloccante per questa card.
- [x] Controllo percettivo richiesto: no.

## Decisioni

- **2026-09-01 — "GitHub Release" scelta esplicitamente dal proprietario**
  fra tre opzioni proposte (Release CI, export una tantum dalla sessione
  remota, commit dell'APK in una cartella del repo). Le altre due sono
  scartate: la prima non lascia nulla di riutilizzabile in un container
  effimero, la seconda contraddice l'igiene del repository già dichiarata in
  CLAUDE.md.
- **2026-09-01 — Solo APK debug, non release firmata.** Il preset `Android
  APK` esistente produce un debug build col keystore di default di Godot;
  una build di release firmata richiederebbe un keystore e password segreti
  da gestire come GitHub Secret, fuori scopo per questa card salvo richiesta
  esplicita futura.
- **2026-09-01 — Trigger solo manuale (`workflow_dispatch`).** L'export
  Android è lento (SDK/NDK grandi, build Gradle); non ha senso farlo scattare
  automaticamente a ogni push finché non lo richiede un flusso di rilascio
  reale.
- **2026-09-01 — Push diretto su `main` autorizzato esplicitamente dal
  proprietario per questa card.** GitHub registra un workflow
  `workflow_dispatch` solo se il file esiste sul branch di default: senza
  questo il workflow non era azionabile né verificabile da nessuno. Fatto
  fast-forward, nessun conflitto, nessuna cronologia riscritta.
- **2026-09-01 — Run #1 fallito per un bug del mio script di verifica, non
  dell'export.** `aapt2` produceva correttamente `minSdkVersion:'31'`; il
  controllo cercava `sdkVersion:'31'` (S minuscola), mai combaciante per
  case-sensitivity. Corretto il pattern e, insieme, il rilevamento del
  marker `[ DONE ] export` (Godot lo stampa circondato da codici ANSI anche
  in headless: il grep letterale non lo vedeva mai, ma non era comunque
  bloccante). Fix in un commit separato, rilanciato come run #2, verde.
- **2026-09-01 — Card chiusa `COMPLETATO` su un run reale osservato verde,
  non su un file YAML "che sembra corretto".** Vedi i link ai run nei criteri
  sopra.

## Documenti sincronizzati

- [x] `docs/setup.md`: breve nota che rimanda al workflow CI come percorso
      alternativo per ottenere un APK senza toolchain locale.

## Note

Questa card nasce da una richiesta diretta del proprietario durante una
sessione remota senza Godot/Android SDK disponibili: l'implementazione va
verificata lanciando davvero il workflow, non solo scrivendolo.
