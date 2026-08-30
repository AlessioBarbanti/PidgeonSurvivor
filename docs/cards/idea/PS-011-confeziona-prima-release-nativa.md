---
id: PS-011
titolo: Confeziona la prima release nativa
tipo: chore
area: piattaforma
stato: IDEA
priorita: alta
dipende_da: [PS-010]
origine: B20
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-011 — Confeziona la prima release nativa

## Contesto

Dopo Difesa Grigliata serve una candidata distribuibile per Windows e Android.
La prima distribuzione è diretta: nessun account, listing o upload Google Play.

## Comportamento atteso

- Produrre ZIP Windows x64 e APK Android ARM64 release installabile.
- Conservare package `com.ilgioco.pidgeonsurvivor`, versione semantica e
  `versionCode` crescente.
- Verificare che il progetto possa generare un AAB Gradle per uso futuro, senza
  pubblicarlo.
- Usare un keystore release esterno al repository, con backup e procedura di
  recupero.

## Criteri di accettazione

- [ ] PS-010 è `COMPLETATO` e i due modi entrano nella candidata.
- [ ] Identità, posizione sicura e backup del keystore sono decisi.
- [ ] È deciso se includere l'icona Android monocromatica opzionale.
- [ ] ZIP Windows x64 si avvia su macchina pulita o profilo equivalente.
- [ ] APK contiene solo `arm64-v8a`, API `31/36`, firma release e launcher corretto.
- [ ] Installazione, cold launch, Back/Home/resume e orientamento sono verificati.
- [ ] AAB Gradle viene generato e ispezionato localmente, senza upload.
- [ ] Nessun keystore, password, output o credenziale entra nel repository.
- [ ] Istruzioni di installazione e hash degli artefatti sono registrati.

## Ambito

Preset export, versioning, firma, icone applicazione, documentazione di
distribuzione e artefatti finali. Non include pagina store, privacy form,
closed testing o pubblicazione.

## Verifica

- Profilo `Release` del runner con label card `PS-011`.
- Ispezione statica tramite `tools/inspect-android-artifact.ps1`.
- Hash SHA-256 di ZIP, APK e AAB candidati.

## Gate manuali

- [ ] Runtime Windows dalla ZIP candidata.
- [ ] Installazione e runtime dell'APK firmato su Pixel 9.
- [ ] Back, Home, resume, touch e multitouch sulla build firmata.
- [ ] Controllo finale di nome, icona, versione e orientamento.

## Decisioni

- **2026-08-25 — Packaging dopo Difesa Grigliata.** La dipendenza storica
  B20 → B23 diventa PS-011 → PS-010.
- **2026-08-30 — Prima distribuzione tramite APK diretto.** L'AAB prova la
  predisposizione futura ma non viene caricato su Google Play.
- **Confermata — Credenziali fuori dal repository.** Percorsi e password
  passano da ambiente/configurazione locale.
- **Aperta — Keystore release.** Decidere identità, posizione, backup e recupero.
- **Aperta — Icona monocromatica.** Decidere se aggiungere la variante Android
  opzionale prima della candidata.

## Documenti sincronizzati

- [ ] `setup.md`: firma, versioning e comandi finali.
- [ ] `README.md`: installazione/distribuzione della candidata.
- [ ] `content-approvals.md`: eventuale icona monocromatica.
- [ ] Nota di verifica release con artefatti, hash e gate separati.

## Note

Le decisioni storiche complete restano negli snapshot del decision log in
[`docs/archive/`](../../archive/README.md).
