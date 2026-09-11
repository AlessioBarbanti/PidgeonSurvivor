---
id: PS-156
titolo: Riduci il peso dell'APK Android
tipo: perf
area: piattaforma
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine:
creato: 2026-09-11
aggiornato: 2026-09-11
---

# PS-156 — Riduci il peso dell'APK Android

## Contesto

L'APK pubblico della versione 0.2.1 pesa 120.501.565 byte. Il pacchetto di
release contiene la libreria nativa ARM64 senza compressione ZIP e include la
musica Boss nel formato MP3 sorgente da circa 14 MB: entrambe le scelte fanno
crescere il download senza migliorare il contenuto percepito dal giocatore.

Serve una pipeline riproducibile che mantenga il master audio nel repository,
esporti soltanto un derivato adatto al runtime e misuri il risultato su un APK
di release realmente prodotto da `develop`.

## Comportamento atteso

L'APK Android di release resta installabile e firmato, contiene soltanto
l'architettura ARM64 prevista e pesa sensibilmente meno della versione 0.2.1.
La musica Boss continua a essere caricata dalla scena, ma il pacchetto include
il derivato Ogg Vorbis e non il master MP3. La conversione può essere ripetuta
con uno script documentato e verificabile.

## Criteri di accettazione

- [x] Un APK di release prodotto da `develop` pesa almeno il 40% in meno dei
      120.501.565 byte dell'APK pubblico 0.2.1.
- [x] La libreria nativa ARM64 è compressa nel contenitore APK; nessuna ABI
      diversa da `arm64-v8a` viene introdotta.
- [x] L'APK supera l'ispezione statica: manifest leggibile, build non
      debuggable, firma v2 valida e contenuto ZIP coerente.
- [x] La musica Boss runtime è un Ogg Vorbis stereo a 44,1 kHz derivato dal
      master MP3; scena, import e manifest puntano al derivato corretto.
- [x] Il master audio vive sotto `hd/`, è escluso dall'import/export Godot e
      non compare nell'APK.
- [x] `tools/process-music-track.ps1` riproduce la conversione, valida codec,
      durata, canali, frequenza, riduzione e hash, fallendo su output non
      conforme.
- [x] La documentazione descrive il workflow e la scelta di packaging senza
      cambiare il numero di versione del progetto.
- [x] I test focalizzati sulla musica Boss e le regressioni pertinenti passano
      senza marker di errore nei log.

## Ambito

- Preset Android APK in `export_presets.cfg`.
- Musica Boss sotto
  `assets/audio/third_party/matthewpablo_vilified/`, relativo manifest e
  riferimento in `scenes/game/movement_slice.tscn`.
- Script deterministico `tools/process-music-track.ps1` e documentazione in
  `docs/setup.md` / `docs/visual-audio-identity.md`.

Non cambiare il bilanciamento, la selezione musicale, gli altri asset audio,
la versione del progetto o il formato AAB, che conserva il comportamento
richiesto dal Play Store.

## Verifica

- Focused/Relevant: `tests/unit/test_ps073_boss_dedicated_music.gd` tramite
  `tools/run-milestone-checks.ps1 -Milestone PS-156`.
- Conversione completa del derivato con FFmpeg e validazione dello script
  PowerShell.
- Export release stabile e ispezione con
  `tools/inspect-android-artifact.ps1`, `aapt2`, `apksigner` e inventario ZIP.
- Profilo minimo prima della chiusura: `Relevant`.
- Evidenza automatica: `Relevant` PASS, focused 1/1 e regressioni 39/39;
  nessun `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL` in
  `20260911-134812-PS-156`.

## Gate manuali

- [ ] Runtime Windows: riproduzione e loop della musica Boss.
- [x] Validazione statica APK: artefatto stabile, manifest coerente, firma v2,
      build non debuggable e sola ABI ARM64.
- [ ] Runtime fisico Pixel 9: installazione, cold launch e ingresso Boss.
- [ ] Controllo percettivo richiesto: sì, qualità e continuità del loop dopo la
      compressione.

## Decisioni

- **2026-09-11 — Lavoro tracciato su `develop`, non come hotfix.** Il
  proprietario ha riclassificato l'intervento come ottimizzazione ordinaria:
  nessun branch hotfix, nessuna PR dedicata e nessun bump di versione.
- **2026-09-11 — Master e derivato hanno ruoli distinti.** Il master MP3 resta
  conservato sotto `hd/` con `.gdignore`; il runtime usa un Ogg Vorbis a
  bitrate nominale 112 kbit/s, 44,1 kHz e due canali. In questo modo la
  sorgente non viene persa e la trasformazione resta ripetibile.
- **2026-09-11 — Compressione delle librerie limitata all'APK.** Il preset APK
  abilita la compressione delle librerie native; il preset AAB resta invariato
  perché il packaging finale per il Play Store è gestito dal bundle/store.

## Documenti sincronizzati

- [x] `docs/setup.md`: comando di conversione e comportamento dei preset.
- [x] `docs/visual-audio-identity.md`: formato runtime e posizione del master.
- [x] `ASSET-MANIFEST.md`: origine, trasformazione e SHA-256 di master e
      derivato.

## Note

La baseline pubblica 0.2.1 è 120.501.565 byte. Il candidato release costruito
da `develop` (`config/version="0.2.0"`, nessun bump introdotto dalla card) pesa
63.133.191 byte: 57.368.374 byte in meno, pari al 47,61%. SHA-256:
`75087179C8BDDBEB665361A634FD1A42FDD3D73943CE713FBF92C153792CEC65`.

Nell'APK, `lib/arm64-v8a/libgodot_android.so` passa da 71.110.440 byte raw a
24.022.729 byte compressi (−66,22%). L'inventario ZIP non contiene master MP3,
cartelle `hd/`, `tools/`, `tests/` o ABI ulteriori. Il derivato audio è stato
rigenerato in una cartella temporanea con hash identico al file runtime
(`09E189CF473A9F6D1E489A1B66ACE3D5FB32CE99FBDF1329249D9C2C5F169D59`) e
decodificato integralmente con FFmpeg senza errori.

`adb devices -l` non elenca device collegati: installazione, cold launch,
ingresso Boss e valutazione percettiva restano aperti.
