# Verifica B18W — Raffinamento della selezione personaggi

Data: 25 agosto 2026
Stato: `IN VERIFICA`

B18W porta il carosello B18T verso la gerarchia del mockup approvato: fondale
notturno incorniciato, Back compatto in alto a sinistra, card squadrate, mini-card
laterali complete, frecce metalliche/oro, kit compatto e un solo CTA.

## CTA e fondale ImageGen

Il fondale `character_select_backdrop.png` e la base senza testo
`character_select_cta_base.png` sono raster originali generati con ImageGen. La
prima richiesta descrive un fondale menu pixel-art blu notte, vuoto, con cornice
in pietra/acciaio e cristalli ciano agli angoli; la seconda una placca fantasy
bronzata/arancione, senza testo o logo, con doppio bordo dorato e ornamenti a
rombo. I prompt integrali, generatore, data, trasformazioni, licenza e SHA-256
sono registrati in `assets/art/ui/character_select/ASSET-MANIFEST.md`.

Godot sovrappone il testo dinamico `Gioca con <Nome>` alla placca. Il CTA misura
`510×76` unità logiche, non supera il `55%` del pannello e lascia almeno `30`
unità dalla cornice inferiore. Non è più un rettangolo a tutta larghezza e non
copre il fondale. Il master CTA HD è escluso dagli export; il derivato runtime è
prodotto deterministicamente da `tools/process-character-select-cta.ps1`.

## Gerarchia e dati

Il pannello laterale `KIT DI <NOME>` aggiorna atomicamente icona, nome e
descrizione della passiva, icona B18M, nome completo e descrizione dell'abilità
per tutti gli otto profili. Le copy approvate, incluso `Reggeton time!`, non
vengono abbreviate. Passiva e attiva hanno titoli dorati equivalenti; tutti i
profili usano un emblema passivo raster dedicato, senza ricadere sul ritratto
come fallback. Prompt, trasformazioni, licenza e hash sono nel manifest
`assets/art/icons/passives/ASSET-MANIFEST.md`. Ciano
resta riservato a selezione/focus; oro e arancione alla gerarchia importante.
Back torna alla welcome e nessun input avanza la run prima del CTA.

Il ricompattamento finale usa un `IdentityBlock` con `6` unità tra nome e ruolo,
porta il kit a `380` unità, aumenta leggermente card centrale, icone e testi e
mantiene al massimo `34` unità tra la fine del ruolo e il CTA. Il gruppo segue
quindi l'ordine titolo → carosello/kit → nome/ruolo → conferma senza la precedente
area vuota centrale.

Lo smoke `_character_select_refinement_smoke.gd` verifica gerarchia, focus,
copy, icone, mini-card complete, bordi squadrati, frecce non circolari, unica
conferma, dimensioni del CTA, distanza dalla cornice e layout
16:9, 20:9 e 4:3. Marker: `B18W_CHARACTER_SELECT_REFINEMENT_SMOKE_OK`.

### Set completo delle icone passive

Le sette nuove sorgenti RGBA fornite dal proprietario sono state elaborate con
`tools/process-passive-icon.ps1` a `128×128`, con crop alpha, soglia `8`, padding
`12` e nearest-neighbor. Ogni `FriendDefinition` punta ora al proprio PNG
runtime: Alea/aquila, Aleo/scudo, Bea/senso equino, Lollo/stivale, Marghe/sorriso,
Migi/guscio e Zat/clessidra; Magno conserva l'emblema bovino già integrato.

Lo smoke B18W impone la mappa completa `profilo → icona passiva`, oltre alla
presenza del file, e la regressione del roster attraversa tutti gli otto profili.
Prompt, provenienza, trasformazioni, dimensioni e hash sono registrati in
`assets/art/icons/passives/ASSET-MANIFEST.md`.

## Gate

- regressione completa: `40/40`;
- smoke aggiornato: `B18W_CHARACTER_SELECT_REFINEMENT_SMOKE_OK`;
- regressione roster: `B17A_COMPLETE_ROSTER_ABILITIES_SMOKE_OK`;
- regressione carosello: `B18T_CHARACTER_CAROUSEL_SMOKE_OK`;
- project smoke e toolchain: verdi;
- runtime Windows: `SMOKE_OK`, `B18T_CONTRACT_OK`, `B18W_CONTRACT_OK`, exit `0`;
- export Windows e Android e controlli APK statici: verdi; APK finale
  `96057827` byte, SHA-256
  `2076C520AB274C3DEDDF5A34EB222833DE5EC9A1C04FF28CB1B748018AFE7BDA`,
  firma v2 valida, sola ABI `arm64-v8a`, master HD esclusi e otto icone passive
  runtime incluse;
- Pixel 9 20:9: l'installazione dell'artefatto finale è rimasta correttamente
  silenziosa durante il trasferimento e ha poi restituito `Success`;
- gerarchia, CTA, avanzamento singolo Zat → Alea, conferma, run, pausa e ritorno
  al carosello verificati tramite ADB sull'artefatto finale;
- Pixel 9 20:9, nuovo set: cold launch, apertura del selettore e controllo
  percettivo delle icone Magno e Bea verificati sull'APK che include tutte e otto
  le risorse; gli otto collegamenti sono coperti dagli smoke deterministici;
- nessun `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL` nei
  log controllati.

Resta aperta soltanto la valutazione manuale fisica con dito e percezione umana
del dispositivo. Per questo B18W rimane `IN VERIFICA` e non viene dichiarato
completato sulla sola base di screenshot e iniezione ADB.
