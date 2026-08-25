# Verifica B18U — Sprite del cast coerenti

Data: 25 agosto 2026  
Stato: **IN VERIFICA**

## Risultato

Gli otto `FriendDefinition` usano ora strisce Player originali `96×32`, con tre
pose `32×32` ordinate `passo A | idle | passo B`. Gli asset sono archetipi
fittizi e mantengono la direzione visuale approvata nella welcome B18O:

- Magno umano, largo e tellurico, con soli richiami bovini;
- Bea pattinatrice con capelli scuri ricci e palette viola;
- Zat infermiera elettrica senza copricapo, in bianco-ciano e con cuore medico
  generico;
- Alea ballerina bionda in bianco-avorio e oro;
- Aleo giovane muratore in verde oliva e giallo;
- Lollo cosplayer retrofuturista blu e giallo con goggles;
- Migi con capelli neri, occhiali, palette teal e scudo a guscio;
- Marghe dalla corporatura morbida, capelli neri molto lunghi e palette
  viola-magenta-oro.

Il confronto ha usato sia il fondale approvato
`welcome_ability_cast_background.png` sia la conversazione B18O del 24 agosto.
I primi output di Magno, Zat, Alea, Aleo e Marghe sono stati corretti perché non
rispettavano abbastanza anatomia, capelli, età, costume, corporatura o palette
della welcome. Bea, Lollo e Migi erano già coerenti.

## Pipeline e sorgenti conservate

Gli output selezionati sono stati prodotti con OpenAI ImageGen built-in su
chroma uniforme. La rimozione del chroma produce sorgenti RGBA `1536×1024`; lo
script `tools/process-cast-sprite.ps1` isola la componente opaca principale di
ogni cella, ricampiona nearest-neighbor entro `28×28`, centra e allinea la posa
su un canvas `32×32` senza ritocchi manuali o VFX.

Le otto sorgenti trasparenti HD sono conservate in
`assets/art/characters/players/hd/` per riusi futuri. `hd/.gdignore` impedisce
l'import Godot e tutti e tre i preset di export escludono esplicitamente la
cartella. L'ispezione dell'APK B18U conferma `HD_ENTRY_COUNT=0`.

Prompt condiviso, prompt specifici, correzioni dalla welcome, generatore, data,
licenza, trasformazioni e SHA-256 di sorgenti, HD e derivati runtime sono nel
[manifest degli sprite](../assets/art/characters/players/ASSET-MANIFEST.md).

## Invarianti gameplay

La sostituzione modifica soltanto le texture gameplay nei resource dei profili.
Restano invariati:

- scala Player `1,65`, origine e `CollisionShape2D` circolare con raggio `24`;
- collision layer `1`, mask `0`, velocità e movimento;
- passive, ID e definizioni delle abilità, cooldown e timing;
- sequenza B18C a quattro fasi, flip orizzontale e ultima direzione vettoriale;
- ritratti hero/Evil B17, che restano placeholder CC0 separati.

`CharacterSprite` usa il filtro nearest. Il contratto della scena verifica che
ogni profilo punti alla propria striscia, abbia idle `32×32`, quattro frame di
movimento e due pose di passo distinte; il runtime stampa
`B18U_CONTRACT_OK`.

## Verifica automatica

Comandi principali:

```powershell
godot_console --headless --path . --script tests/integration/_cast_sprites_smoke.gd
godot_console --headless --path . --script tests/integration/_player_direction_animation_smoke.gd
godot_console --headless --path . --script tests/integration/_friend_content_smoke.gd
godot_console --headless --path . --script tests/integration/_pause_change_character_smoke.gd
.\tools\verify-toolchain.ps1 -RunProjectSmoke
```

Esito:

- `_cast_sprites_smoke.gd`: `B18U_CAST_SPRITES_SMOKE_OK`;
- regressione completa: `38/38` smoke verdi;
- project smoke e toolchain Godot/JDK/Android: verdi;
- nessun `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o `CONTRACT_FAIL`.

Lo smoke B18U copre tutti gli hash runtime/HD, gli otto profili, idle e
locomozione, facing, cambio profilo da BOOT, sconfitta/restart, assenza di frame
residui, geometria di collisione, scala e filtro nearest. I controlli visivi
diretti delle otto strisce confermano silhouette distinte, registrazione delle
pose e trasparenza pulita.

## Windows

L'export debug Windows x64 è completato. L'avvio headless dell'artefatto ha
stampato `SMOKE_OK` e tutti i contratti fino a `B18U_CONTRACT_OK`; il processo è
stato poi chiuso esplicitamente perché la build di gioco attende normalmente
input e non è un test auto-terminante.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `PidgeonSurvivor.exe` | `103115264` | `BFA5766944AD646D797F3FEB0172A0287A65CFD9FF08B1B1E449955985BC85FA` |
| `PidgeonSurvivor.pck` | `9767152` | `1BFFCAFD1A3CBE4B51F40B30E11D52F03128C11E326D1B80BB72ACAFE0681D5A` |

## Android statico

L'export debug APK è completato e i controlli statici confermano:

- package `com.ilgioco.pidgeonsurvivor`, label `Pidgeon Survivor`;
- `minSdk 31`, `targetSdk 36`, `compileSdk 36`;
- sola ABI `arm64-v8a`;
- firma APK Signature Scheme v2 valida;
- nessuna sorgente `hd/*_source.png` inclusa.

APK: `94275160` byte, SHA-256
`49622E6E6F387DA7C5D43CF8CC444D86BD649F4853A5AC408ED01AD6DFEF4A11`.

## Gate ancora aperti

`adb devices -l` non rilevava dispositivi collegati. Non sono quindi chiusi il
controllo percettivo in movimento e ad alta densità sul Pixel 9, il multitouch
reale joystick più abilità e il confronto fisico 20:9. Anche il percorso
welcome → carosello → run resta dipendente da B18T, ancora `PRONTO`; 16:9 e 4:3
richiedono il confronto finale previsto dal piano. Per questi motivi B18U resta
`IN VERIFICA` e B18V non viene sbloccato.
