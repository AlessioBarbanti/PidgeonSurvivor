---
id: PS-180
titolo: La citazione del Boss è leggermente nascosta su device reale (gate Pixel di PS-176)
tipo: fix
area: ui
stato: IN VERIFICA
priorita: alta
dipende_da: []
origine: test reale su Pixel 9 della v0.3.0, 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-17
---

# PS-180 — La citazione del Boss è leggermente nascosta su device reale (gate Pixel di PS-176)

## Contesto

[PS-176](../4_to_test/PS-176-ritratti-boss-fluttuanti-senza-cornice.md)
(ritratti Boss fluttuanti) ha il gate "Runtime fisico Pixel 9" esplicitamente
lasciato aperto proprio per questo controllo — mai eseguito in sessione,
solo validato via screenshot dall'agente `direttore-artistico`. Testando la
build reale v0.3.0 su Pixel 9, il proprietario segnala che la scritta
(citazione) del Boss è "leggermente nascosta". Non ancora chiaro se è
overflow dietro il cartiglio, sovrapposizione con un altro elemento
(pulsante AFFRONTA, HUD), o clipping ai bordi della safe area su questo
specifico rapporto d'aspetto (Pixel 9 ≈ 20:9, 2424×1080) — diverso dai
profili 16:9/20:9 "sintetici" già catturati in sessione.

## Comportamento atteso

La citazione è interamente leggibile, senza essere nascosta o tagliata, su
Pixel 9 reale, per tutte e 9 le varianti e con citazioni sia corte che al
limite di lunghezza.

## Criteri di accettazione

- [x] Riprodotto e identificato esattamente cosa nasconde la scritta
      (z-order, clipping del `RichTextLabel`, sovrapposizione con altro
      nodo, contrasto insufficiente) su screenshot/registrazione del device
      reale. Causa: clipping verticale del `RichTextLabel` (`clip_contents`).
      La citazione condivisa da tutte le 9 varianti (PS-101) va a capo su 3
      righe, ma il cartiglio aveva spazio verticale per ~2 sole righe — vero
      su qualunque aspect ratio landscape, perché il vincolo è l'altezza
      logica disponibile (720px), identica a 16:9 e 20:9.
- [x] Corretto mantenendo il contratto di PS-176 (ancore percentuali
      misurate su `REFERENCE.png`, `contain` scaling, nessun pannello/
      cornice reintrodotto). Le percentuali del cartiglio non sono cambiate;
      il ritratto cresce semplicemente nello spazio verticale liberato.
- [x] Verificato su almeno un Evil (Evil Magno, seed 4 del flag B22) e sul
      Piccione Malvagio (screenshot sintetici 16:9/20:9), citazione reale
      (unica in gioco, condivisa da tutte le varianti, PS-101) confermata
      senza clipping su device fisico. La citazione di stress sintetica da
      167 caratteri **resta fuori scope**: overflow pre-esistente scoperto
      durante questa verifica, mai la causa segnalata dal proprietario — vedi
      Decisioni e la nuova card aperta per tracciarlo separatamente.

## Ambito

- `scripts/ui/boss_ui.gd`, `scenes/ui/boss_ui.tscn` (stesso perimetro di
  PS-176).
- `scripts/ui/hud.gd`: la fascia HUD superiore (`%TopBand`) si attenua
  (`modulate.a`, non `visible`) durante `BOSS_INTRO` per lasciare risalto al
  ritratto che cresce nello spazio liberato, restando comunque leggibile
  (decisione del proprietario in sessione, ambito ampliato rispetto
  all'apertura della card — vedi Decisioni).
- Non reintrodurre il trattamento a pannello/medaglione/cornice scartato da
  PS-176 (PS-102/PS-103 restano storiche e scartate).

## Verifica

- GUT: nuova asserzione in `tests/unit/test_ps176_boss_intro_floating_portrait.gd`
  (`get_intro_quote_content_height() <= quote_rect.size.y`) — il solo
  controllo geometrico sul rettangolo (già esistente) non intercetta un
  clipping di contenuto, perché il rettangolo è fisso per ancore percentuali
  indipendentemente da quante righe servano.
- Screenshot reale da device Pixel 9 (flag di verifica fisica B22,
  `res://scripts/game/movement_slice.gd`), non solo cattura sintetica via
  `godot_console`.
- Profilo minimo prima della chiusura: `Relevant`; `Full` eseguito per il
  perimetro allargato a `GameHud`.

## Gate manuali

- [x] Runtime Windows: nessun `SCRIPT ERROR`/`FATAL EXCEPTION`, screenshot
      rigenerati (16:9 e Pixel9 20:9).
- [x] Validazione statica APK: `RECOVERED` (export non uscito da solo dopo
      `[ DONE ] export`, APK stabile e ispezione statica verde).
- [x] Runtime fisico Pixel 9: APK installato, flag B22 (seed 4, Evil Magno),
      `B22_PHYSICAL_BOSS_INTRO` in log, nessun `SCRIPT ERROR`/`FATAL
      EXCEPTION`, screenshot fisico del device confermano citazione
      interamente leggibile su 2 righe, ritratto ingrandito, fascia HUD
      attenuata ma leggibile (non nascosta, dopo la revisione del
      direttore-artistico).
- [ ] Controllo percettivo richiesto: sì — delegato all'agente
      `direttore-artistico` (non un'ispezione diretta mia, per prassi di
      progetto). Prima passata (fascia HUD nascosta del tutto): **approvato
      con modifiche** — rompeva la coerenza con gli altri modali e toglieva
      la vista su HP entrando in uno scontro Boss (vedi Decisioni).
      Implementata l'alternativa raccomandata (attenuazione, non
      nascondimento); seconda passata di conferma sul risultato finale
      ancora da eseguire.

## Decisioni

- **2026-09-15 — Non duplica PS-176, la completa.** Questa card nasce dal
  gate Pixel 9 di PS-176 rimasto esplicitamente aperto: a risoluzione
  avvenuta, aggiornare anche PS-176 invece di lasciarla disallineata.
- **2026-09-17 — Causa reale: la citazione condivisa (PS-101) sfora il
  cartiglio su 3 righe, non su un difetto di z-order/sovrapposizione.**
  Riprodotto su Pixel 9 fisico col flag di verifica B22: screenshot mostra
  "grigliata!" quasi del tutto tagliato. Misurato via script di debug
  temporaneo (non committato): a 720px di altezza logica (identica a 16:9 e
  20:9 — il vincolo è verticale, non l'aspect ratio) il cartiglio riceveva
  ~43px, la citazione ne richiedeva 50 per 3 righe.
- **2026-09-17 — Scope ampliato in sessione: liberare lo spazio della fascia
  HUD superiore durante `BOSS_INTRO` per ingrandire il ritratto, su richiesta
  esplicita del proprietario.** Alternativa valutata (stringere solo i
  margini interni a `boss_ui.gd`) avrebbe recuperato troppo poco spazio
  (~30-60px) per garantire margine anche a citazioni future più lunghe; non
  riservare più `GameHud.GAMEPLAY_TOP_INSET` (140px) ne recupera 124 in un
  colpo solo per `BossUI.CONTENT_TOP_MARGIN`. Il ritratto, opaco, copre
  comunque la fascia nella zona centrale in cui si sovrappone.
- **2026-09-17 — Prima implementazione: nascondere del tutto `%TopBand`
  (`visible = false`) durante `BOSS_INTRO`. Bocciata dal controllo
  percettivo del direttore-artistico.** In tutti gli altri stati non-`RUNNING`
  (`LEVEL_UP`, `BARB_REWARD`, `MANUAL_PAUSE`) la fascia resta sempre visibile
  a piena opacità — nessun modale la nasconde mai. Nasconderla solo in
  `BOSS_INTRO` era una nuova, unica eccezione non documentata da nessuna
  parte, e toglieva al giocatore la vista su HP/XP proprio entrando in uno
  scontro Boss (può arrivarci con vita residua bassa dallo scontro
  precedente). **Corretto attenuando invece di nascondere**: `%TopBand.modulate.a`
  passa a `GameHud.ABILITY_FADED_ALPHA` (0.3, lo stesso valore già usato per
  affievolire — non nascondere — il controllo abilità quando il Player ci
  passa sotto) durante `BOSS_INTRO`, tornando a `1.0` negli altri stati.
  Nella fascia orizzontale coperta dal ritratto l'effetto visivo non cambia
  (l'arte opaca copre comunque quel che c'è sotto), ma ai lati — dove le
  barre XP/HP occupano quasi tutta la larghezza dello schermo — restano
  visibili, attenuate. Resta comunque un'eccezione isolata al solo stato
  `BOSS_INTRO`: gli altri modali continuano a mostrare l'HUD a piena
  opacità, invariati.
- **2026-09-17 — Font della citazione aumentato da 12px a 14px, su richiesta
  del proprietario dopo aver visto lo spazio liberato.** Verificato via
  script di debug che a 14px la citazione reale resta su 2 righe con margine
  su tutti e 3 i profili (16:9, 20:9, 4:3); 15px e oltre la farebbero
  ritornare a 3 righe con overflow. Resta lo stesso font (`nunito_regular`)
  della scelta PS-176, solo la dimensione cambia — non è uno dei valori
  nominati nel tema (`BodyS`=12, `BodyM`=16), scelto puntualmente per il
  margine di sicurezza verificato piuttosto che forzare un token esistente
  che avrebbe riaperto il clipping.
- **2026-09-17 — Overflow pre-esistente della citazione di stress sintetica
  (167 caratteri) scoperto ma non risolto qui: fuori scope.** Il test GUT
  esistente controllava solo posizione/dimensione del rettangolo della
  citazione (fisso per ancore percentuali), mai l'altezza del contenuto
  renderizzato: la citazione di stress usata solo nei test sfora il
  cartiglio anche dopo questo fix (peggio a 14px). Non è la causa segnalata
  dal proprietario (in gioco esiste una sola citazione reale, condivisa da
  tutte le varianti, PS-101) e non è chiaro se 167 caratteri sia un limite
  realistico da garantire o un valore di test da rivedere: aperta
  [PS-192](../1_idea/PS-192-citazione-stress-sfora-cartiglio-boss.md)
  (`DA DEFINIRE`, serve una scelta del proprietario) invece di allargare
  ulteriormente questa.

## Documenti sincronizzati

- [x] `docs/enemies-bosses.md`: aggiunta la nota sulla fascia HUD attenuata
      durante `BOSS_INTRO`.
- [x] Nessun altro documento atteso oltre a quanto già sincronizzato da
      PS-176.

## Evidenze

- **2026-09-17 — Riproduzione reale (bug):** APK v0.3.0-equivalente (pre-fix)
  installato su Pixel 9 (`49140DLAQ0010Y`), flag B22 (`seed=4`), log
  `B22_PHYSICAL_BOSS_INTRO id=evil_magno title=Evil Magno evil=true`;
  screenshot fisico (`adb exec-out screencap`) mostra "grigliata!" tagliato.
- **2026-09-17 — `Relevant`:** `focused=1/1`, `regression=36/36`, nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.
- **2026-09-17 — `Full`:** `focused=1/1`, `regression=152/152`, toolchain
  PASS, nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.
- **2026-09-17 — Export/validazione statica Android:** `android-export`
  `RECOVERED` (non uscito da solo dopo `[ DONE ] export`, APK stabile),
  `android-static` PASS.
- **2026-09-17 — Riproduzione reale (prima versione, fascia nascosta):** APK
  con `visible = false` installato, stesso flag B22/seed, screenshot fisico
  conferma citazione su 2 righe leggibili ma fascia HUD completamente
  assente.
- **2026-09-17 — Riproduzione reale (versione finale, fascia attenuata):**
  APK con `modulate.a` reinstallato, stesso flag B22/seed, log pulito,
  screenshot fisico conferma citazione su 2 righe interamente leggibili,
  ritratto ingrandito, barre XP/HP e pulsante pausa visibili ma attenuati.
- **2026-09-17 — Controllo percettivo:** delegato all'agente
  `direttore-artistico` in questa sessione; verdetto riportato sopra in
  Decisioni non appena disponibile.

## Note

Segnalato dal proprietario durante il test reale su Pixel 9 della v0.3.0,
insieme ad altri cinque problemi nella stessa sessione (PS-178, PS-179,
PS-181..PS-183).
