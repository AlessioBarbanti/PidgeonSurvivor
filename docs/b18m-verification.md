# B18M — Migliorie grafiche delle abilità

## Refresh VFX runtime — 29 agosto 2026

Stato corrente: `IN VERIFICA` per il nuovo controllo percettivo in movimento.
Il runtime non mostra piu l'icona HUD come emblema sopra l'arena: nove decal
ImageGen dedicati coprono shockwave, scia, impatto elettrico, Piroetta, le due
fasi di Shock Termico, reveal Cosplay, campo Zen e clone Reggaeton.

I master RGBA `1254x1254` sono in
`assets/art/vfx/abilities/hd/`; i derivati runtime `512x512` sono in
`assets/art/vfx/abilities/generated/`. `tools/process-ability-vfx.ps1` conserva
il canvas quadrato, ricampiona in bicubica e azzera l'alpha residuo sotto `32`;
master e prompt/hashes sono
registrati nel manifest. Gli output ImageGen built-in avevano alpha nativo,
quindi non e servita rimozione chroma.

L'integrazione mantiene un bordo procedurale sul raggio gameplay reale e usa il
decal come resa artistica: danno, hitbox, cooldown, targeting e input non
cambiano. La sola durata presentazionale della shockwave di Magno passa da
`0,35 s` a `1,20 s`; l'impatto resta istantaneo e il nodo non contiene
collisioni.

### Passata di taratura sulla leggibilita' — 29 agosto 2026

La prima integrazione dei decal introduceva tre disallineamenti fra resa e
gameplay, ora corretti; nessuna correzione tocca dati, hitbox o timing di danno.

- Onda d'Urto Tellurica: l'espansione si chiudeva a `~0,50 s` mentre danno,
  knockback e stun sono istantanei, quindi i nemici al bordo volavano via prima
  del fronte. Il fronte raggiunge ora il raggio pieno entro il `15%` della
  durata visiva (`~0,18 s`) e la coda comincia a dissolversi dal `22%`.
- Il master tellurico e' l'unico dei nove senza centro aperto: l'opacita' del
  decal e' ora limitata a `0,62`, mentre il bordo del raggio resta a `0,85`, per
  non nascondere il Player durante gli `1,20 s` di coda. Lo stesso master e'
  pittorico e non pixel-art, quindi il suo nodo usa filtro lineare.
- Tempesta di Tuoni: il decal riempie il quadrato fino agli angoli mentre l'AoE
  e' circolare, cosi' l'impatto appariva fino a `1,41x` il raggio che fa danno.
  Telegraph e afterglow sono ora inscritti nel cerchio (`1/sqrt(2)`).
- Powerslide: il master non e' raccordabile, quindi gli stampi accumulavano
  alpha nelle sovrapposizioni. Passo portato a `0,72` del lato, opacita' del
  singolo tassello a `0,62` e specchiatura alternata per spezzare la ripetizione.
- Pulizie: `VISUAL_PARTICLE_COUNT` di Shock Termico allineato a `0` (le schegge
  che lo giustificavano sono state sostituite dal decal), note musicali del
  clone Reggaeton spostate fuori dalla sagoma, variabile morta rimossa,
  `ABILITY_ICON_BURST_SECONDS` rinominata `ABILITY_VFX_TAIL_SECONDS` e percorso
  `_attach_generated_icon_burst` marcato come deprecato.

Resta aperta, come scelta artistica: `zen_field` e `thermal_frost` sono
pittorici accanto a master pixel-art e condividono il nodo con questi ultimi,
quindi non possono ricevere un filtro diverso senza rigenerarli o separarli.

Verifica automatica corrente:

- import Godot dei nove PNG: verde;
- `_ability_visuals_smoke.gd`: `B18M_ABILITY_VISUALS_SMOKE_OK`;
- `_visual_timing_smoke.gd`: `B18R_VISUAL_TIMING_SMOKE_OK`;
- profilo `Relevant` su `66` step: `62` verdi. I tre rossi sono preesistenti e
  non riguardano le abilita': `_hud_smoke` si aspetta HP `80/100` ma riceve
  `95/115`, mentre `_typography_smoke` e `_welcome_flow_smoke` appartengono al
  refresh B18O ancora in verifica (entrambi rossi anche senza queste modifiche).
  `_signature_upgrades_smoke` e' risultato instabile: rosso in una passata e
  verde in tre esecuzioni successive con le modifiche applicate, per via
  dell'asserzione sulla dispersione casuale della Birra.

Restano aperti export/runtime Windows, build/install Android e controllo
percettivo Pixel 9 del nuovo candidato; le evidenze del 25 agosto riguardano la
grafica precedente e non vengono riutilizzate.

Data verifica refresh ImageGen: 24 agosto 2026
Godot: `4.7.1.stable.official.a13da4feb`
Target obbligatori: Windows x64 e Android ARM64

## Stato storico del refresh icone — 24/26 agosto 2026

`COMPLETATO`. Il refresh sostituisce le otto icone SVG runtime con emblemi PNG
ImageGen e li riusa in brevi animazioni di attivazione. Smoke, regressione,
toolchain, export/runtime Windows ed export Android statico sono verdi. La prova
percettiva sul Pixel 9 è stata completata il 25 agosto 2026.

Il precedente gate Pixel 9 del 24 agosto resta valido per primitive procedurali,
layer, lifecycle e input della baseline `11329cf`, ma non certifica leggibilità e
animazione dei nuovi asset.

## Emblemi ImageGen

La modalità built-in di OpenAI ImageGen ha prodotto un asset distinto per:

- Magno: roccia spaccata, anelli d'impatto e polvere;
- Bea: pattino inline, scia a Z e scintille;
- Zat: nube, singolo fulmine e onde del tuono;
- Alea: gonna da piroetta, archi opposti e scintille;
- Aleo: secchio, colata e bolle di cemento;
- Lollo: maschera, stella mistero e coriandoli;
- Migi: loto, onde di respiro e moti;
- Marghe: boombox, silhouette danzante e note per `Reggeton time!`.

Specifica condivisa: pixel-art arcade caricaturale, silhouette leggibile a
`42 px`, composizione centrata, palette limitata, nessun testo, numero, cornice,
card, marchio o watermark. Gli output built-in erano già PNG RGBA trasparenti;
il 26 agosto 2026 il padding residuo è stato rimosso con un crop quadrato minimo
sul bounding box alpha, senza deformare il soggetto, poi ricampionato Lanczos a
`256×256` e ottimizzato. File finali:
[`assets/art/icons/abilities/generated/`](../assets/art/icons/abilities/generated/).

Prompt, origine, autore, licenza, trasformazioni e SHA-256 individuali sono nel
[`manifest B18M`](../assets/art/vfx/ASSET-MANIFEST.md). Le vecchie icone runtime
SVG sono state rimosse; la sorgente Pinhead CC0 resta come storico documentato e
non viene consumata dalla build.

## Animazioni di attivazione

`ability_icon_burst.gd` mostrava nella baseline B18M per `0,72 s` la stessa
texture usata da HUD e carte rank. B18R ha poi portato il valore finale a
`1,20 s`. I profili sono distinti: impatto e tremore, scorrimento, pulse del
tuono, rotazione, caduta/squash, reveal, respiro e beat. Ogni effetto usa un solo
emblema, zero materiali custom e `z_index=1`, quindi resta sotto nemici,
telegraph, Player e proiettili prioritari.

Il clock avanza soltanto in `RunController.RUNNING`; B18R separa la dissolvenza
come coda sibling non interattiva, mentre morte, cambio profilo e restart la
ripuliscono. Collisioni, raggio, danno, durata, cooldown, snapshot rank e routing
touch sono invariati.

## Verifica automatica

Smoke dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_ability_visuals_smoke.gd
```

Marker: `B18M_ABILITY_VISUALS_SMOKE_OK`.

La fixture istanzia tutte le abilità e verifica famiglia visiva, budget, layer,
geometria gameplay, manifest/hash, PNG ImageGen, corrispondenza texture HUD/VFX,
un solo emblema, zero materiali custom, pausa e cleanup. La regressione completa
è `32/32`; `tools/verify-toolchain.ps1 -RunProjectSmoke` è verde. Log ed exit
code sono privi di `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` e
`CONTRACT_FAIL`.

## Windows x64

L'export debug finale è riuscito. L'eseguibile è stato avviato realmente a
`1280×720` con renderer Compatibility/OpenGL 3.3 su NVIDIA GeForce RTX 3060. Il
log contiene `SMOKE_OK`, `B18M_CONTRACT_OK` e `B17A_READY`, senza errori runtime.
L'anteprima tecnica comparativa resta ignorata in
`exports/ability-icons-imagegen-preview.png`.

## Android ARM64

L'export APK debug finale è riuscito. I controlli statici confermano:

- package `com.ilgioco.friendshipsurvival`, versione `0.1.0`/code `1`;
- `minSdk 31`, `targetSdk 36`, `compileSdk 36`;
- orientamento landscape, activity ridimensionabile e sola ABI `arm64-v8a`;
- firma APK Signature Scheme v2 valida.

Nella sessione automatica precedente l'APK non era stato installato e le nuove
icone/animazioni non erano state provate fisicamente. Il 25 agosto 2026 il gate
Pixel 9 è stato chiuso con le otto attivazioni in movimento e densità elevata a
20:9, controllando leggibilità a `42 px`, priorità visive e assenza di residui
dopo pausa/restart.

## Artefatti verificati

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `exports/windows/FriendshipSurvival.exe` | `103033344` | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `exports/windows/FriendshipSurvival.pck` | `1564344` | `ADCA5F69F90737F4C8ECF9AA7A3E3E03F99E4AFFD8648B99CE451CC00FE778FB` |
| `exports/android/friendship-survival-debug.apk` | `85377683` | `351B1D91B58A8476A266AF96954D77B61652D952FCAE56E05FEE03E8BFBAF2A7` |
