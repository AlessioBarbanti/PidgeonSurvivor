# Verifica B09A — Framework abilità attive e Onda d'Urto Tellurica

Data: 17 agosto 2026  
Engine: Godot 4.7.1  
Stato: implementazione e gate Windows/Pixel 9 completati; profili Android 12 e Android 16 esatti e controller fisico aperti

## Risultato

Il vertical slice B09A aggiunge una prima abilità attiva completa senza
accoppiarla agli upgrade o allo sparo automatico:

- `AbilityDefinition` contiene ID, testi, icona, cooldown, durata, area, danno,
  `effect_id`, parametri e tag; il profilo di Magno vive in
  `data/abilities/magno_earthquake_shockwave.tres`;
- `AbilityEffectRegistry` registra e risolve le definizioni, filtra per tag e
  interpreta `earthquake_shockwave` senza funzioni eseguibili nei dati;
- `AbilityController`, figlio scene-local del Player, accetta soltanto
  intenzioni di `InputRouter` in `RUNNING`, a cooldown terminato e con effetto
  valido; una richiesta rifiutata non modifica il cooldown;
- Space, face button sud del controller e pulsante touch producono la stessa
  intenzione `active_ability`; una pressione mantenuta non viene ripetuta e il
  riarmo dopo focus/pause richiede il ritorno al neutro;
- l'Onda d'Urto applica separatamente 20 danni e knockback radiale 300 per
  0,2 s ai nemici vivi entro 220 unità, usando il registro del targeting e
  senza scansioni del `SceneTree`;
- cooldown, knockback e VFX avanzano soltanto in `RUNNING`; pausa e `LEVEL_UP`
  li congelano;
- l'HUD mostra icona, nome, barra di ricarica, secondi residui e stato pronto;
  il pulsante touch è nella safe area in basso a destra, separato dal joystick;
- il restart azzera cooldown e HUD, rimuove le onde attive e consente una
  seconda run senza callback duplicate.

## Raggio e dimensioni dello schermo

`area_radius = 220` indica unità del mondo logico Godot, non pixel fisici del
display. La configurazione `canvas_items` + `expand` e `ArenaLayout` fanno sì
che risoluzione, DPI e cutout siano trasformati nello stesso sistema di
coordinate usato da Player e nemici. Lo smoke verifica, sui profili 16:9,
20:9 e 4:3, che un bersaglio a 219 unità sia incluso e uno a 221 sia escluso.

Il valore non è una percentuale dello schermo: su layout estremi può quindi
occupare una frazione visiva diversa, mentre la distanza gameplay rimane
coerente. Se il playtest richiederà un'area proporzionale al playfield, la
scelta sarà esplicita e potrà essere implementata senza confonderla con DPI o
risoluzione fisica. Per ora 220 resta la baseline regolabile prevista dal PRD.

## Test automatici

Comando dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 `
  --script tests/integration/_active_ability_smoke.gd
```

Lo smoke copre:

- validazione del `Resource`, valori PRD, registry e filtri tag;
- invarianti del raggio in coordinate mondo su 16:9, 20:9 e 4:3;
- binding tastiera/controller e singola intenzione per pressione;
- pulsante touch, safe area e separazione dal joystick;
- danno, esclusione fuori raggio, direzione/durata del knockback e VFX;
- richiesta rifiutata senza consumo del cooldown;
- congelamento dopo focus loss/lifecycle e in `LEVEL_UP`, ripresa esplicita e
  singolo segnale di prontezza;
- reset di cooldown, HUD, nemici ed effetti e seconda run senza segnali doppi.

Esito dedicato:

```text
B09A_ACTIVE_ABILITY_SMOKE_OK
```

È stata rieseguita anche l'intera suite B03–B09A: dieci smoke test verdi, senza
`SCRIPT ERROR` o errori runtime. Il contratto della scena principale stampa:

```text
B09A_CONTRACT_OK
B09A_READY
```

`tools/verify-toolchain.ps1 -RunProjectSmoke` termina con codice `0` e conferma
Godot 4.7.1, JDK 17, SDK 31/36, Build Tools 36.1.0, NDK, template e import.

## Export Windows e Android

Gli export debug sono stati rigenerati e restano nelle directory ignorate.
Lo smoke headless dell'eseguibile Windows esportato termina con codice `0` e
stampa anche `B09A_CONTRACT_OK`.

| Artefatto | Byte | SHA-256 |
|---|---:|---|
| `FriendshipSurvival.console.exe` | 101.376 | `6948E3214518231D0E009A43D013014A17D214E1EB5807E5AC309617860E07EA` |
| `FriendshipSurvival.exe` | 103.033.344 | `47A4D4E119346D53E6A435986935BAC1C68E08DFEADF531F1422707F75061BCA` |
| `FriendshipSurvival.pck` | 310.504 | `7BCC74AF0507DA27E766ACEC890DA40A2731B9494518ECDD2052AAD32230DE9B` |
| `friendship-survival-debug.apk` | 84.181.039 | `59DF535678966F563D0496DD6C193745C03D4B9D1A951F0EAD4A0507C335F08E` |

Il controllo statico dell'APK conferma package
`com.ilgioco.friendshipsurvival`, versione `0.1.0`/code 1, minSdk 31,
target/compileSdk 36, sola ABI `arm64-v8a` e firma debug APK Signature Scheme v2
valida.

I preset escludono `exports/**` e `android/build/**`: il PCK finale non contiene
anteprime, screenshot o altri output locali generati durante le verifiche.

## Runtime Pixel 9

L'APK B09A è stato installato con `adb install -r` sul Pixel 9 (`tokay`),
Android 17/API 37, ARM64. Il processo usa Compatibility/OpenGL ES 3.2 su
Mali-G715 e ha stampato:

```text
SMOKE_OK version=4.7.1 renderer=gl_compatibility os=Android
B09A_CONTRACT_OK
B09A_READY os=Android viewport=(1616, 720) window=(2424, 1080)
```

La safe area logica rilevata è `1460,667×680` a `(135,333, 20)`; il playfield
16:9 è `1208,889×680` a `(261,222, 20)`. HUD, joystick e dock abilità sono
risultati contenuti e separati anche con il cutout fisico sinistro.

Il gate runtime reale ha verificato:

- run nuova con abilità `PRONTA`, tap sul pulsante e onda circolare visibile;
- cooldown partito da 8 s e aggiornato nello stesso HUD (`7,8 s` nella prima
  cattura dopo l'attivazione);
- Back durante cooldown: overlay `IN PAUSA`, timer `00:02` e cooldown `6,1 s`
  identici dopo due secondi; secondo Back riprende e porta il cooldown a
  `5,4 s`;
- Home durante cooldown: al ritorno la run resta su `IN PAUSA`; timer `00:01`
  e cooldown `7,0 s` restano identici per due secondi, poi `RIPRENDI` riavvia
  esplicitamente il clock e la ricarica (`6,3 s`);
- `LEVEL_UP` congela l'abilità (`0,5 s` e, in un secondo ciclo, `0,1 s`) senza
  attivazioni spurie;
- multitouch reale confermato dall'utente: Player in movimento con il joystick
  posseduto dal primo dito e attivazione accettata dal secondo dito;
- `GAME OVER → RIPROVA` crea una nuova run a `00:00`, vita `100/100`, livello 1
  e abilità nuovamente `PRONTA`;
- nessun `SCRIPT ERROR`, `FATAL EXCEPTION` o errore Godot nel log del processo.

Le schermate di verifica restano in `exports/android/b09a-runtime/`, directory
ignorata e non destinata al repository.

## Gate ancora aperti

- prova su Android 12/API 31 e sul target Android 16/API 36;
- prova con controller USB/Bluetooth reale;
- playtest del raggio 220 e del bilanciamento 8 s / 20 danni / knockback 300.
