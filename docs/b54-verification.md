# B54 — Verifica tutorial dal Welcome Screen

Data: 28 agosto 2026.

## Perimetro implementato

- `TUTORIAL` sotto `GIOCA`, CTA secondario e percorso focus
  `GIOCA ↔ TUTORIAL ↔ ingranaggio`.
- `TutorialScreen` dedicata in `BOOT`, con Back/chiusura verso la welcome e
  `GIOCA` finale verso il selettore personaggio.
- Sei `TutorialPageDefinition` data-driven: obiettivo, movimento, abilità,
  progressione, nemici e Boss.
- Layout editoriale a due colonne: artwork originali per obiettivo, movimento e
  Boss; icone definitive già approvate per abilità, upgrade e nemici.
- Micro-animazioni senza nodi gameplay/RNG; stop del processing quando il
  tutorial non è visibile.
- Frecce, indicatori `n/6`, swipe touch, tastiera/controller e reset a pagina 1
  alla riapertura.
- `ESCI` sempre attivo in pagina uno, `INDIETRO` dalle pagine successive e
  nessuna `X` ridondante.
- Distinzione approvata fra decorazioni della welcome, ammesse sul viewport
  completo, e target interattivi, confinati alla safe area.

## Evidenza automatica

| Check | Esito | Evidenza |
|---|---|---|
| Refresh classi/import | Verde | `godot_console --headless --editor --path . --quit`; classi `TutorialPageDefinition`, `TutorialPreview`, `TutorialScreen` registrate |
| Focused B54 | Verde | `tools/run-milestone-checks.ps1 -Milestone B54 -Profile Focused -NoCache`; `B54_TUTORIAL_FLOW_SMOKE_OK` |
| Welcome/B32 | Verde | `godot_console --headless --path . --script tests/integration/_welcome_flow_smoke.gd`; `B18O_WELCOME_FLOW_SMOKE_OK`, `B32_WELCOME_CTA_SETTINGS_SMOKE_OK`, `B54_CONTRACT_OK` |
| Relevant, worktree completo | Parziale `30/31` | Unico failure `_complete_roster_abilities_smoke.gd`: pannello roster fuori safe area, preesistente e già registrato in B45 |
| Relevant, soli path B54 | Parziale `7/8` | Unico failure `_hud_smoke.gd`: aspettativa storica vita Magno `100`, runtime corrente `115`, preesistente e registrato in B47 |
| Regressioni successive esplicite | Verde `7/7` | Movement slice, lifecycle, Boss ricorrente, tipografia, upgrade overlay, welcome e confinamento XP |

Log Focused corrente:
`%LOCALAPPDATA%/Temp/il-gioco-verification/20260828-164748-B54/`.

## Revisione percettiva del 28 agosto

Il proprietario ha respinto la prima candidata: pannelli e visual geometriche
apparivano da debug e `INDIETRO` risultava inerte sulla prima pagina. La
candidata è stata sostituita, non ritoccata: nuova gerarchia a due colonne,
copy ridotto, artwork/icone definitive e comportamento `ESCI` coperto dallo
smoke. Sei catture Windows a `1280×720` sono state generate con renderer OpenGL
reale e controllate una per una; non sostituiscono la nuova prova Pixel 9.

Log Relevant:
`%LOCALAPPDATA%/Temp/il-gioco-verification/20260828-164801-B54/`.

Log Relevant limitato ai path B54:
`%LOCALAPPDATA%/Temp/il-gioco-verification/20260828-162048-B54/`.

Log regressioni successive:
`%LOCALAPPDATA%/Temp/il-gioco-verification/20260828-162144-B54/`.

## Evidenza piattaforma

| Gate | Esito | Evidenza |
|---|---|---|
| Export Windows debug redesign | Verde | `godot_console --headless --path . --export-debug "Windows Desktop" exports/windows/PidgeonSurvivor.exe`; exit `0`, `[DONE] savepack` |
| Avvio headless dell'export Windows | Parziale | processo terminato con exit code `0`, ma senza marker runtime osservabile; non sostituisce la navigazione interattiva |
| Export Android debug redesign | Verde | artefatto aggiornato il 28 agosto 2026; export `[DONE]` |
| Ispezione APK | Verde | package `com.ilgioco.pidgeonsurvivor`, min SDK `31`, target SDK `36`, ABI `arm64-v8a`, firma v2, launcher `com.godot.game.GodotAppLauncher` |
| Integrità APK redesign | Verde | `101.009.698` byte; SHA-256 `271F8BEEF9BE6B38631FD37F47C0E1E944B2272E8AD6D9F4262CAC70ABA3BAD7`; `ANDROID_STATIC_VALID` |
| Installazione Pixel 9 redesign | Verde | `adb -s 49140DLAQ0010Y install -r ...`; `Success`, package presente, `versionName=0.1.0`, `lastUpdateTime=2026-08-28 16:59:01` |
| Cold launch/runtime Pixel 9 redesign | Aperto | non eseguito: l'installazione non viene trasformata in prova runtime |
| Prova touch e accettazione percettiva | Da ripetere | richiesta sulla nuova candidata; nessun input ADB viene usato durante la prova del proprietario |

## Gate ancora aperti

- risolvere o isolare i failure roster/HUD preesistenti, poi rieseguire Relevant
  e Full senza abbreviazioni;
- profilo Release e runtime Windows interattivo con navigazione mouse, tastiera
  e controller;
- cold launch della nuova APK redesign e prova fisica Pixel 9 di tap, swipe,
  Back, leggibilità 20:9 e flusso tutorial
  → selezione → run;
- accettazione percettiva del proprietario per ritmo delle preview, gerarchia
  del CTA e densità della pagina Nemici.

Le catture del redesign sono state prodotte con renderer Windows OpenGL reale,
non con renderer headless/dummy. Restano evidenza percettiva locale e non
sostituiscono il gate Pixel 9 del proprietario.
