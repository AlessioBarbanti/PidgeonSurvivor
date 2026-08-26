# Verifica B18W — Raffinamento della selezione personaggi

Data: 25 agosto 2026
Stato: `COMPLETATO`

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

La valutazione manuale fisica con dito e percezione umana del dispositivo è
stata completata il 25 agosto 2026. B18W è quindi completato sulla base della
prova umana, mantenuta distinta da screenshot e iniezione ADB.

## Aggiornamento 26 agosto 2026 — gerarchia icone kit

Il kit conserva l'ordine verticale originale: passiva sopra, abilità sotto.
La passiva usa `94×94`, l'attiva `128×128`: la differenza compensa il padding
trasparente interno delle icone attive e allinea la massa visiva. Lo smoke isolato
`_ability_selection_icon_scale_smoke.gd` copre le tre geometrie `16:9`, `20:9`
e `4:3`; la verifica percettiva sul dispositivo resta da rinnovare dopo questo
pass UI.

Il 26 agosto 2026 gli smoke `ABILITY_SELECTION_ICON_SCALE_SMOKE_OK` e
`B18W_CHARACTER_SELECT_REFINEMENT_SMOKE_OK` sono verdi. L'APK aggiornato è
stato installato e avviato sul Pixel 9; il controllo percettivo umano del nuovo
bilanciamento paritario passiva/attiva resta aperto.

Aggiornamento successivo del 26 agosto 2026: la passiva è stata calibrata a
`94×94`, con attiva `128×128`, senza cambiare disposizione. Il nuovo APK ha
avvio a freddo riuscito sul Pixel 9; l'ispezione visiva umana del layout
aggiornato resta aperta.

L'APK finale di questo pass ha SHA-256
`09DCE7EC4C9A06A7C0395101BDA006E8322FAA71AED9FDE1F661F3A30CE7DE8E`,
misura `96.379.884` byte ed è stato installato con cold launch riuscito sul
Pixel 9.

Calibrazione percettiva successiva: passiva `94×94`, attiva `128×128`; APK
installato sul Pixel 9, SHA-256
`D7DB4F26A1FF7B1CA5A83DE2EBC6778DD136FEDAFA911B64A5951163F3D7B8C6`,
`96.379.920` byte. La conferma visiva umana resta richiesta.

Ricalibrazione finale: passiva `94×94`, attiva `128×128`; APK installato con
cold launch riuscito sul Pixel 9, SHA-256
`441F03DC756EC6723ACA0544F84118BC46BDC3AEDA5BA9039A4DF14FA8D97C3E`,
`96.379.924` byte.

## Revisione 26 agosto 2026 — due card abilità

`KIT DI <NOME>` e il pannello verticale unico sono rimossi. La sezione laterale
usa due card indipendenti, Passiva e Abilità, con stesso stile, larghezza,
padding e altezza. Ogni card dispone l'icona una sola volta a sinistra, centrata
verticalmente rispetto a label, titolo dorato e descrizione a destra; non c'è
un separatore interno. La passiva conserva `94×94` nella corsia icona `128×128`,
mentre l'attiva conserva `128×128` per la compensazione del padding trasparente.

Verifiche automatiche verdi: `B18W_CHARACTER_SELECT_REFINEMENT_SMOKE_OK`,
`ABILITY_SELECTION_ICON_SCALE_SMOKE_OK`, `B18T_CHARACTER_CAROUSEL_SMOKE_OK`
e `B17A_COMPLETE_ROSTER_ABILITIES_SMOKE_OK`. Restano aperti export/controllo
statico dell'APK aggiornato e il confronto percettivo umano sul Pixel 9.

L'APK delle due card è stato esportato, installato e avviato a freddo sul Pixel
9: SHA-256 `0DF9FA57B2C1DD26F777A8CBAA3555BB80D56DBD6F3C2586FEBC90E1CAAE3C1D`,
`96.387.235` byte. Il 26 agosto 2026 il proprietario ha confermato il risultato
percettivo sul dispositivo; il gate del nuovo layout è chiuso.
