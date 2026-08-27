# Chiusura gate B24–B35 — 27 agosto 2026

Sessione dedicata alla chiusura dei gate automatici, di piattaforma e percettivi
rimasti aperti sul blocco B24–B35. Registra anche due esiti negativi: un blocco
tecnico sul multitouch e un rilievo di bilanciamento che tocca B28 e le carte.

## Metodo e sua portata

I controlli percettivi di questa sessione sono stati eseguiti dall'agente su
catture `adb exec-out screencap` del Pixel 9 `49140DLAQ0010Y` e su input
iniettati via `adb shell input`. **Non sostituiscono l'accettazione umana del
proprietario** dove le note precedenti la richiedono esplicitamente; sono
registrati come evidenza tecnica riproducibile, distinta dal giudizio umano.

Device: Pixel 9 `49140DLAQ0010Y`, Android 17 / API 37, `1080x2424` @ 420 dpi,
finestra applicativa `2424x1080` (20:9), `mCurrentRotation=ROTATION_90`.

## Correzioni ai test automatici

La suite `Full` non era verde per **cinque difetti nei soli file di test**, tutti
rimasti indietro rispetto a scelte di prodotto già committate. Nessuna
modifica a scene, dati o runtime di gioco.

| File | Difetto | Correzione |
|---|---|---|
| `_ability_selection_icon_scale_smoke.gd` | Attendeva icone `128`/`94`; `8be3663` le ha portate a `136`/`108` | Soglie allineate ai valori committati |
| `_character_select_refinement_smoke.gd` | Attendeva icona `128`, gap nome/ruolo `6–12`, frecce `≤46` | Allineato a `136`, gap `0–12`, frecce `≤48`; messaggi ora riportano il valore reale |
| `_upgrade_icon_refresh_smoke.gd` | Attendeva icona offerta `76×76`, superata dalla decisione `192×192` già applicata in `_upgrade_overlay_smoke.gd` | Soglia portata a `192×192` |
| `_upgrade_effects_smoke.gd` | **Hang infinito** | Vedi sotto |
| `_xp_arena_confinement_smoke.gd` | Attendeva un pickup per ogni morte, incompatibile con il budget XP frazionario B28 | La kill viene ripetuta nello stesso punto finche' il budget emette il pickup |

### Hang di `_upgrade_effects_smoke.gd`

Era la causa del blocco del runner completo già annotato in
[`b29-verification.md`](./b29-verification.md), e non un problema di ambiente.

`ExperienceSystem.add_experience()` richiede lo stato `RUNNING`. Dopo B26 le
quattro carte statistiche sono tutte `repeatable = true`, quindi l'offerta espone
sempre tre ID su quattro definizioni eleggibili e il bersaglio puo' non essere
pescato. In quel caso `_grant_and_select()` usciva lasciando il `LEVEL_UP`
aperto: ogni chiamata successiva veniva rifiutata, il rank non avanzava piu' e il
`while service.get_rank(...) < 5` privo di guard girava all'infinito, saturando
un core.

Correzioni:

- `_grant_and_select()` scarta l'offerta che non contiene il bersaglio chiamando
  `experience.complete_level_up()` — che chiude il livello senza applicare
  effetti e ripulisce l'offerta — e ripesca, entro `OFFER_RETRY_LIMIT`;
- il ciclo dei tre primari ha un guard esplicito e fallisce invece di appendersi;
- l'attesa sul danno del proiettile dopo `Forchettone da Braciere` passa da
  `×1,05` a `×1,15`: `1,05` era un residuo del `fallback_power` rimosso da B26,
  mentre `meat_fork_damage.tres` dichiara `multiplier = 1.15`.

Sono stati inoltre terminati due processi Godot orfani della sessione
precedente (`_powerup_first_wave_smoke.gd`, avviati alle 10:57 e 10:59), che
consumavano CPU. Rieseguito isolatamente, quello smoke è verde.

## Esiti automatici

| Profilo | Esito |
|---|---|
| `Full` | **PASS** — `regression=51/51`, `toolchain=1/1`, `steps=52/52` |
| `Release` | **PASS** — `bootstrap=1/1`, `regression=51/51`, `toolchain=1/1`, `windows=2/2`, `android=2/2`, `steps=57/57`, `android_static=True`, `recovered=1` |

`recovered=1` è il caso documentato in
[`verification-workflow.md`](./verification-workflow.md): l'exporter Android
resta aperto dopo aver scritto un APK valido. `android_runtime` è risultato
`OPEN_ADB_SERVER_NOT_RUNNING` perché il server adb si era riavviato durante la
sessione; l'installazione e il runtime sono stati verificati a parte, sotto.

Artefatti correnti:

- `exports/android/pidgeon-survivor-debug.apk`, `99.011.121` byte, SHA-256
  `35A4AD938B17277D1642ACCFC67CFA94DD77EA5FAFF2E602F18A0765FA948202`;
- `exports/windows/PidgeonSurvivor.exe`, SHA-256
  `BFA5766944AD646D797F3FEB0172A0287A65CFD9FF08B1B1E449955985BC85FA`.

L'APK è stato installato con `adb install -r` e ha completato un cold launch
pulito: `0` occorrenze di `SCRIPT ERROR`, `FATAL EXCEPTION`, `SMOKE_FAIL` o
`CONTRACT_FAIL` nel logcat della sessione.

## Prestazioni Pixel 9 (B28)

Misura su `dumpsys SurfaceFlinger --timestats` del layer
`SurfaceView[com.ilgioco.pidgeonsurvivor/...]`, sull'APK corrente, durante una
run guidata con puntatore persistente:

- `totalFrames = 1634`, `droppedFrames = 0`, `badDesiredPresentFrames = 0`;
- `present2present`: `16ms = 1632`, `17ms = 2` — il `99,88%` dei frame a un
  intervallo esatto di refresh;
- `averageFPS = 62,495`; `displayRefreshRate = 60`, `renderRate = 60`.

Il diagnostico interno `B18V_PERF_SAMPLE` conferma dal lato Godot: su `74`
campioni, `67` a `60.0` FPS, `4` a `59.0`, `2` a `61.0` e un singolo `46.0` sul
frame di cold launch; `frame_ms 16.67`, `draw_calls` max `92`, `profile: mobile`.

`data/performance/mobile_performance_profile.tres` dichiara
`stress_enemy_count = 150`, allineato ai budget Windows: **nessun cap mobile
invisibile**, come richiesto dal piano.

**Limite dell'evidenza**: i campioni riportano al massimo `enemies: 9` vivi. Il
pacing a 60 FPS è quindi verificato alla densità realmente raggiunta in gioco,
non al cap di `140`. Il motivo è il rilievo qui sotto.

## Rilievo di bilanciamento: la run finisce prima del primo level-up

Cinque run consecutive con Magno sul Pixel 9, con movimento continuo guidato via
puntatore persistente, sono terminate a **`00:13`, `00:16`, `00:17`, `00:17` e
`00:14`**. In nessuna è stato raggiunto il livello `1`: la barra XP si è fermata
intorno al `55%`.

Numeri dichiarati che compongono l'esito:

- Player: `health_max = 100`, `invulnerability_duration = 0.75`;
- nemico base: `health_max = 24.0`, danno da contatto `20.0` — cinque contatti
  uccidono, con un minimo teorico di `3 s` per morire;
- curva XP: `base_experience_required = 10`, `experience_growth_per_level = 5`;
- il budget XP B28 rende il credito per kill frazionario: una kill sotto la
  soglia è contabilizzata ma non genera pickup.

Conseguenze verificabili:

1. la densità che B28 vuole introdurre non si manifesta: le run finiscono con
   circa `9` nemici vivi contro un cap di `140`;
2. l'overlay di level-up non è raggiungibile in gioco reale, quindi il controllo
   percettivo delle carte B26/B27 e dei nuovi powerup B35 **non è eseguibile**
   dal gioco finché il bilanciamento resta questo;
3. il Boss a `04:00` e la progressione B33 restano fuori portata.

L'input usato è scriptato e non ottimale, quindi il dato non prova da solo che
il bilanciamento sia sbagliato; prova però che la combinazione corrente di danno
da contatto, vita del Player e soglia XP non consente di osservare né la densità
né il ciclo delle carte. Serve una decisione esplicita del proprietario, non una
correzione silenziosa: è un contratto di gameplay, non un difetto di codice.

## Gate di piattaforma verificati

### Lifecycle (B06A, B34)

Sequenza reale sul device, con run attiva:

- `KEYCODE_BACK` apre il menu di pausa;
- `KEYCODE_HOME` e rientro con `am start`: la run è **ancora in pausa**, senza
  ripresa automatica e senza stato residuo;
- `KEYCODE_POWER` per bloccare, sblocco e rientro: la run resta in pausa,
  `mCurrentFocus` torna su `GodotAppLauncher`, nessun joystick residuo a schermo.

### Joystick dinamico (B18L)

Un `input motionevent DOWN` a `(900, 700)` in coordinate landscape ha creato il
joystick centrato esattamente in quel punto; il successivo `MOVE` ha spostato la
manopola conservando l'origine. Ownership del puntatore e origine dinamica
confermate sul device reale.

### Audio (B29)

`dumpsys audio` riporta, per il pid del gioco (`28615`), una traccia
`OpenSL ES AudioPlayer (Buffer Queue)` in `state:started`, `usage=USAGE_MEDIA`,
stereo, `44100 Hz`. L'import `super_wreck_roadway_loop.ogg.import` dichiara
`loop=false`, ma `game_audio.gd` forza `ogg_stream.loop = true` a runtime e
`_b29_background_music_smoke.gd` lo verifica: il loop è attivo.

Resta aperto l'ascolto reale: continuità del loop, bilanciamento sotto SFX in
orda e percezione di pausa/ripresa non sono misurabili da `dumpsys`.

## Controlli percettivi eseguiti su cattura

- **B24** — la scala `1,25×` rende Magno leggibile a 20:9 sul playfield, senza
  clipping ai bordi durante il movimento guidato.
- **B25** — nessun indicatore di vita circolare sopra il Player in nessuna delle
  catture di gameplay; la barra `HP` globale resta l'unica fonte.
- **B31** — pausa e pulsante abilità conservano un margine netto dai bordi e dal
  playfield; l'icona abilità è al `150%` di default.
- **B32** — la welcome mostra il CTA `GIOCA` come placca pixel-fantasy
  fluttuante, senza riquadro esterno e senza outline di focus; l'ingranaggio è in
  alto a destra dentro la safe area.
- **B34** — pausa, HUD e controlli condividono la grammatica pixel-fantasy:
  pannello e header dorati, slider arancioni con manopola squadrata, checkbox
  ciano, barre `XP`/`HP` con soli tag fissi, cronometro flottante e pausa in
  placca.
- **B18W** — la selezione conserva UI-009: due card separate passiva/attiva con
  icona a sinistra centrata sul blocco testo, Back distinto dalle frecce
  compatte, placca CTA centrata. Le icone portate a `136` non dominano la card.

### Osservazione fuori perimetro

Il terminale `GAME OVER` **non** segue la grammatica B34: usa un pannello piatto
con bordo rosa e pulsanti grigi squadrati, diverso dalla pausa. B34 dichiarava
come perimetro pausa, HUD e controlli touch, quindi non è una regressione; è però
l'elemento più vistosamente incoerente rimasto ed è la candidata naturale per
un'estensione del pass.

## Gate che restano aperti

1. **Densità target B28** — profiling a `140` nemici vivi, non raggiungibile
   finché le run durano ~15 s.
2. **Controllo percettivo carte B26/B27/B35** — irraggiungibile in gioco per lo
   stesso motivo.
3. **Ascolto reale B29** su Windows e Pixel 9.
4. **Windows percettivo B32** — tastiera/controller, resize e percezione della
   placca; il profilo `Release` prova il runtime, non l'interazione.

## Multitouch: chiuso dal proprietario

Il multitouch fisico su Pixel 9 **non è automatizzabile**. L'iniezione di eventi
multi-dito richiede `sendevent` su `/dev/input/event2`, che risponde
`Permission denied`: l'utente `shell` appartiene al gruppo `input` e i permessi
DAC sono corretti (`crw-rw---- root input`), ma il contesto SELinux
`u:r:shell:s0` non può iniettare eventi raw, e `adb root` non è disponibile
(`adbd cannot run as root in production builds`, `ro.debuggable=0`).
`adb shell input` gestisce un solo puntatore.

**Il proprietario ha verificato personalmente il multitouch sul Pixel 9 il
27 agosto 2026.** Il gate touch di B31 e B34 è chiuso su questa accettazione, non
su evidenza automatica. I cicli futuri vanno pianificati allo stesso modo: prova
manuale del proprietario, non lavoro automatizzabile.
