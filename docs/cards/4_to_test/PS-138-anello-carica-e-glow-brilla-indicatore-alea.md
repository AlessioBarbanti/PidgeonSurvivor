---
id: PS-138
titolo: Ridisegna l'indicatore HUD della passiva di Alea con anello di carica e glow Brilla
tipo: ux
area: ui
stato: IN VERIFICA
priorita: media
dipende_da: [PS-106]
origine:
creato: 2026-09-09
aggiornato: 2026-09-10
---

# PS-138 — Ridisegna l'indicatore HUD della passiva di Alea con anello di carica e glow Brilla

## Contesto

[PS-106](../4_to_test/PS-106-integra-icona-calice-sobrieta-alea-hud.md) ha
cablato l'icona a calice di [PS-104](../5_completed/PS-104-icona-calice-sobrieta-alea.md)
in `TopBand/SobrietySlot` (`scenes/ui/hud.tscn`, 32×32), con un
`TextureProgressBar` che maschera verticalmente il vino
(`alea_sobriety_wine_fill.png`) sopra il vetro
(`alea_sobriety_glass_empty.png`) seguendo `alea_sobriety_changed(fill_ratio)`
esposto da `FriendPassiveController`. Il proprietario segnala due problemi,
verificati in questa sessione con una cattura reale (non solo a codice) prima
di scrivere la card:

1. **Bug di posizionamento.** Il rect logico di `SobrietySlot` (32×32) non si
   sovrappone a `HealthPanel`/`ExperiencePanel` — per questo il test
   `test_sobriety_icon_does_not_overlap_health_or_experience_panel` di PS-106
   passa — ma la texture 128×128 viene disegnata dal `TextureProgressBar`
   senza essere scalata al riquadro assegnato: nella cattura la coppa del
   calice sconfina visibilmente sopra la barra XP. È un bug di scala/layout,
   non un problema di posizione dei nodi.
2. **Leggibilità.** Il livello di carica si legge solo dal riempimento
   verticale del vino, poco leggibile nel caos del gameplay, e non comunica
   "quanto manca" in modo netto. Inoltre lo stato **Brilla**
   (`FriendPassiveController.is_alea_brilla_active()`,
   `_start_alea_brilla()`/`_end_alea_brilla()` alle righe 413/442) non è
   **oggi esposto all'HUD da nessun segnale**: durante Brilla l'icona resta
   semplicemente "piena" per tutta la durata, indistinguibile dallo stato
   "appena caricata".

Consultato il `game-art-designer` in modalità pianificazione (PS-109, due
turni): l'anello di carica e il glow dello stato Brilla sono ottenibili
interamente **via shader/codice sulle texture già esistenti**, senza nuovo
master pittorico — un tentativo iniziale di ipotizzare una card `tipo: art`
per l'anello è stato scartato dallo stesso sotto-agente dopo aver ispezionato
l'outline reale del calice (troppo sottile per un `modulate` a produrre un
anello spesso; serve un'estrusione shader dell'alpha, tecnica "sprite
outline" standard in Godot 4). Questa resta quindi l'unica card, senza
dipendenza da produzione d'arte.

Documento sorgente completo della richiesta del proprietario, con tutti i
dettagli su stati e regole di lettura:
`c:\Users\aless\Downloads\prompt-codex-indicatore-passiva-alea.md`.

## Comportamento atteso

L'icona calice resta l'identità visiva della passiva, ma comunica la carica
in due segnali distinti invece di uno:

- **Anello di carica**, spesso e vistoso a scala HUD, che avvolge **solo la
  coppa** del calice (non stelo/piede) seguendone la sagoma reale
  (nel canvas sorgente 128×128: fascia y≈4-74, centrata su x=64, spessore
  equivalente a ~3px alla resa finale 32×32, cioè ~12px nel canvas
  128×128 prima del downscale nearest-neighbor già in uso). Il colore
  scalda progressivamente da bronzo spento (`#A67B35` desaturato/scurito)
  a oro vivo (`#F4BC55`, lo stesso oro già presente nei bordi/piede del
  master di PS-104) man mano che `charge_ratio` si avvicina a 1.0 — nessun
  hue nuovo, solo una rampa di temperatura sulla palette esistente.
- **Glow del calice intero** quando la passiva è in stato Brilla: uno
  shader applicato alla texture del vetro (non solo al vino) produce un
  alone luminoso basato sul canale alpha esistente, più un `modulate` più
  chiaro. Nessuna nuova texture "calice acceso": lo stesso principio già in
  uso nel progetto per gli stati attivi delle passive (VFX/tell, non
  texture bakate).
- Il vino interno (`alea_sobriety_wine_fill.png`) resta come dettaglio
  estetico secondario, invariato nel meccanismo di riempimento verticale.
- L'icona è resa alla scala corretta all'interno di `SobrietySlot`, senza
  sconfinare visivamente su `HealthPanel`/`ExperiencePanel` né su altri
  elementi HUD.

## Criteri di accettazione

- [x] Il contenuto renderizzato di `SobrietyIcon` (calice + anello) resta
      entro i confini di `SobrietySlot`: nessun pixel opaco della texture
      finale eccede il rect 32×32 assegnato — verificabile confrontando la
      dimensione/scala effettiva del nodo dopo il fix con quella dichiarata
      dallo slot, non solo i rect logici (il criterio che PS-106 già
      verifica e che oggi non basta). Verificato da
      `test_icon_rendered_content_stays_within_slot_bounds` (confronto
      `icon.size`/`slot.size`) e da cattura reale prima/dopo (vedi
      Decisioni): la coppa non sconfina più sopra la barra XP.
- [x] Un anello/arco è visibile attorno alla sola coppa del calice, non
      sull'intera altezza (stelo e piede ne restano fuori). Verificato
      visivamente (cattura zoomata 6× sull'angolo HUD).
- [x] Il colore dell'anello segue `charge_ratio` con una rampa continua da
      bronzo spento a oro vivo (non un colore fisso, non un cambio a
      gradini discreti). Verificato visivamente a 0%/35%/90% (`Color.lerp`
      continuo in `_draw_charge_ring()`, non a gradini).
- [x] Il progresso verso Brilla si legge principalmente dall'anello, non dal
      solo livello del vino (il vino resta visibile ma secondario).
- [x] Esiste un segnale (o proprietà osservabile equivalente) che espone lo
      stato Brilla all'HUD — oggi assente — emesso da `_start_alea_brilla()`
      e `_end_alea_brilla()` in `friend_passive_controller.gd`. Verificato
      da `test_brilla_signal_toggles_hud_glow_state`.
- [x] Quando Brilla è attivo, l'intero calice (vetro incluso, non solo il
      vino) mostra un glow evidente via shader/modulate; l'anello può
      risultare pieno/enfatizzato ma il segnale principale dello stato
      attivo è il calice acceso. Verificato visivamente: alone a cerchi
      concentrici dietro al vetro + tinta più chiara sul vetro, anello pieno
      oro.
- [x] Stato scarico, stato in carica e stato Brilla sono distinguibili a
      colpo d'occhio l'uno dall'altro (tre segnali visivamente diversi, non
      varianti sottili dello stesso segnale). Confermato dalle quattro
      catture (vuoto/35%/90%/Brilla): traccia bronzo tenue senza glow, arco
      che si scalda senza glow, alone dorato + anello pieno.
- [x] Nessuna riga nuova in un `ASSET-MANIFEST.md`: la card non genera né
      integra nessun asset raster nuovo, solo codice procedurale sulle
      texture esistenti di PS-104 (nessuno shader neppure: vedi Decisioni
      sulla scelta tecnica finale).
- [x] La soglia, la durata e il ciclo di accumulo della passiva di Alea
      (logica di [PS-105](../4_to_test/PS-105-nuova-passiva-alea-due-dita-e-parto.md))
      restano invariati: questa card espone stato, non lo modifica (`git
      diff` su `friend_passive_controller.gd` limitato a un nuovo segnale e
      ai suoi punti di emit).
- [x] Nessuna regressione sul resto della HUD per qualunque personaggio
      equipaggiato (stesso perimetro già coperto da
      `test_ps106_alea_sobriety_hud.gd`) — Relevant 39/39 verde, incluso
      `test_ps106_alea_sobriety_hud.gd` invariato.

## Ambito

- `scenes/ui/hud.tscn`: `TopBand/SobrietySlot/SobrietyIcon` passa da
  `TextureProgressBar` a `Control` con il nuovo script (vedi sotto); stesse
  texture `ExtResource` di PS-104, nessun asset nuovo.
- Nuovo file `scripts/ui/alea_sobriety_indicator.gd`
  (`class_name AleaSobrietyIndicator extends Control`): disegno procedurale
  in `_draw()` (vetro+vino scalati esplicitamente al `size` del nodo, anello
  via `draw_arc`, glow via `draw_circle` concentrici) — **non uno shader**,
  vedi Decisioni per la correzione rispetto alla raccomandazione iniziale.
- `scripts/ui/hud.gd`: tipo di `_sobriety_icon` aggiornato a
  `AleaSobrietyIndicator`; nuovo handler `_on_alea_brilla_active_changed()`;
  nuova getter `is_sobriety_brilla_active()`; connect/disconnect del nuovo
  segnale in `configure()`/`_disconnect_sources()`.
- `scripts/content/friend_passive_controller.gd`: nuovo segnale
  `alea_brilla_active_changed(active: bool)` emesso da `_start_alea_brilla()`
  (riga 413), `_end_alea_brilla()` (riga 442) e `_reset_runtime()` — **solo
  esposizione dello stato esistente**, nessuna modifica alla logica di
  soglia/durata.
- `tools/milestone-test-map.json`: nuovo smoke registrato sotto i pattern
  `scripts/ui/*`/`scenes/ui/*`, `scripts/content/friend_passive_controller.gd`
  e `assets/art/icons/hud/*`.

Non toccare:

- `assets/art/icons/hud/generated/alea_sobriety_*.png` e il relativo master:
  restano gli stessi asset di PS-104, l'anello e il glow sono shader sopra
  di essi, non nuovi derivati.
- Soglia, durata e formula di accumulo della passiva (`sobriety_fill_duration`,
  `brilla_duration`, moltiplicatori di movimento/fuoco): logica di PS-105,
  non di questa card.
- Il particellare dedicato al tell "in Brilla" già esistente
  (`_refresh_passive_state_tell()`), che resta un segnale separato come
  deciso in PS-104.
- `data/friends/alea.tres` e le altre sette passive del cast.

## Verifica

- Smoke: `tests/unit/test_ps138_alea_ring_glow.gd` (nuovo file, 4 test) →
  marker `ALEA_RING_GLOW_SMOKE_OK` — verifica: dimensione renderizzata
  dell'icona identica a quella dello slot (nessuno sconfinamento),
  emissione/lettura del segnale Brilla da `_start_alea_brilla()`/
  `_end_alea_brilla()`, `charge_ratio` letto dall'HUD in tempo reale, nessuna
  regressione sul perimetro già coperto da PS-106.
- Eseguito: Focused 1/1 (4/4 asserzioni per test verdi), Relevant 39/39,
  nessun `SCRIPT ERROR`/`FATAL EXCEPTION` nei log.
- Verifica visiva: script di cattura headless ad-hoc (Windows, 1280×720, non
  committato) su quattro stati — vuoto, 35%, 90%, Brilla attivo — con
  ritaglio/ingrandimento 6× dell'angolo HUD per ispezione ravvicinata.

## Gate manuali

- [x] Runtime Windows — **verificato non interattivamente**: script di
      cattura headless con rendering reale (non solo GUT/logica), quattro
      stati ispezionati a occhio via screenshot ingranditi. Non sostituisce
      una sessione interattiva vera (nessun input umano, nessuna verifica di
      frame pacing) — se serve quel livello di conferma, riaprire il gate.
- [ ] Validazione statica APK.
- [ ] Runtime fisico Pixel 9: stesso percorso del runtime Windows.
- [x] Controllo percettivo richiesto: sì — **eseguito dalla sessione**
      tramite le catture ingrandite (vuoto: traccia bronzo tenue, nessun
      glow; 35%/90%: arco che scalda da bronzo a oro; Brilla: alone dorato +
      anello pieno). Il proprietario non ha ancora visto questi stati dal
      vivo in gioco: se la sua valutazione percettiva diverge da questa,
      riaprire il gate.

## Decisioni

- **2026-09-09 — Bug di posizionamento verificato con cattura reale, non
  solo dedotto dal codice.** Screenshot headless (Windows, 1280×720, HUD con
  Alea equipaggiata) mostra la coppa del calice sconfinare sopra la barra
  XP, mentre `get_sobriety_icon_rect()`/il test PS-106 non lo rilevano
  perché confrontano solo rect logici, non l'estensione reale della texture
  renderizzata.
- **2026-09-09 — Consultato il game-art-designer in pianificazione (PS-109),
  due turni.** Primo turno: raccomandazione tecnica su anello (asset su
  misura vs primitiva generica) e glow (shader vs master pittorico), con tre
  domande al proprietario. Il proprietario ha confermato tutte e quattro le
  opzioni raccomandate: anello solo attorno alla coppa, spesso e vistoso,
  colore che scalda progressivamente, glow via shader/modulate.
- **2026-09-09 — Corretta l'ipotesi di una card `tipo: art` separata per
  l'anello.** Nel primo turno il sotto-agente aveva ipotizzato due master
  raster per l'anello (coerenti con "asset su misura"); nel secondo turno,
  dopo aver ispezionato l'outline reale del calice (1-2px, da disegno
  tecnico), ha corretto se stesso: un `modulate` su un outline così sottile
  non produce mai un anello spesso, serve un'estrusione shader dell'alpha
  esistente — tecnica di codice, non di arte. Card unica, nessuna
  dipendenza da produzione d'arte.
- **2026-09-09 — Geometria e palette dell'anello misurate sul master reale,
  non stimate.** Il game-art-designer ha campionato pixel-per-pixel
  `alea_sobriety_glass_empty.png`: fascia della coppa y≈4-74 su canvas
  128×128 (centrata x=64), oro esistente nei bordi `#F4BC55`
  (bright)/`#A67B35` (mid/shadow) riusato come endpoint della rampa colore,
  invece di introdurre una nuova tinta.
- **2026-09-09 — Implementazione finale: disegno procedurale in `_draw()`,
  non uno shader.** In fase di risoluzione ho trovato due precedenti già in
  uso nello stesso layer UI — `TouchAbilityButton` (l'anello di ricarica di
  PS-120/PS-122, `draw_arc` su una `Button` con `_draw()` proprio) e
  `PixelArcadeMedallion` (cornice circolare a `draw_circle`/`draw_arc`) — che
  risolvono esattamente lo stesso problema (anello leggibile attorno a
  un'icona piccola) senza shader, con `Palette` di riferimento condivisa.
  Riusare questo pattern, già collaudato e testato, invece dello shader di
  estrusione alpha raccomandato in pianificazione: stessa resa visiva
  richiesta (anello spesso, colore che scala, glow), zero rischio di
  compatibilità shader su Compatibility renderer Android (il rischio che il
  game-art-designer stesso aveva segnalato come "non solo teorico"), e
  risolve *anche* il bug di scala alla radice (`draw_texture_rect(...,
  Rect2(Vector2.ZERO, size), ...)` scala sempre esplicitamente, a differenza
  di `TextureProgressBar` che disegna le texture non-nine-patch alla loro
  risoluzione nativa ignorando il `size` del nodo — la causa del bug di
  posizionamento). Nessun file `.gdshader` introdotto. Il criterio "solo
  shader/codice sulle texture esistenti, nessun asset nuovo" resta
  soddisfatto: qui è "solo codice", senza la parola shader.
- **2026-09-09 — `AleaSobrietyIndicator` sostituisce interamente
  `TextureProgressBar`.** Non un'aggiunta sopra di esso: il nodo
  `SobrietyIcon` cambia tipo (`Control` con nuovo script), perché
  `TextureProgressBar` non espone un modo pulito per far coesistere il
  proprio riempimento verticale con un `_draw()` script che debba anche
  disegnare glow *dietro* al vetro (l'ordine di disegno fra `_draw()` custom
  e il rendering interno del nodo built-in non è garantito) — un `Control`
  puro dà controllo esplicito sull'ordine: glow → vetro → vino → anello.
- **2026-09-10 — Feedback dal vivo sul Pixel 9: dimensione e posizione
  riviste in tre passaggi.** Il proprietario ha visto la prima build
  installata (32×32, `SobrietySlot` incollato subito sotto `HealthPanel`) e
  segnalato: icona troppo piccola e "sospesa nel nulla" sopra le barre.
  Applicato in sequenza, ciascuno riverificato con `Relevant` + cattura
  Windows ingrandita prima del successivo:
  1. Dimensione raddoppiata da 32×32 a 48×48 (1,5×, valore confermato
     esplicitamente dal proprietario, "non deve diventare grosso come
     l'abilità a destra" — resta ben sotto i 128px+ di `TouchAbilityButton`).
  2. Prima riposizionato come badge indipendente nell'angolo, poi corretto
     su richiesta esplicita: allineato al **bordo sinistro reale** di
     `HealthPanel`/`ExperiencePanel`. Scoperta empirica non ovvia dalla sola
     lettura del `.tscn`: `HealthPanel` non ha `offset_left` esplicito (quindi
     sembrerebbe 0, cioè il bordo di `TopBand`), ma il suo
     `get_global_rect()` reale restituisce x=64 — verificato stampando
     `get_top_band_rect()` (x=20) accanto a `get_health_panel_rect()` (x=64)
     nello stesso frame. Usato il valore empirico (offset locale 44, non 0)
     invece di fidarsi della sola lettura statica del file.
  3. Margine verticale sotto `HealthPanel` regolato da 8px a 20px su
     ulteriore richiesta ("più in basso").
  Geometria finale `SobrietySlot`: `offset_left=44, offset_top=58,
  offset_right=92, offset_bottom=106` (48×48, allineato a x=64 globale,
  ~20px sotto il bordo inferiore di `HealthPanel`). Nessuna riga di
  `_draw()` toccata in `alea_sobriety_indicator.gd`: la geometria
  dell'anello è già espressa in frazioni di `size`, si riscala da sola.
  Rieseguito `Relevant` dopo ogni passaggio (27/27 verde ogni volta,
  incluso il test di non sovrapposizione). Nuova APK compilata e installata
  sul Pixel 9 con la geometria finale: **il proprietario non ha ancora
  confermato dal vivo questa versione** — gate percettivo e runtime fisico
  restano aperti finché non lo fa.

## Documenti sincronizzati

- [x] `docs/visual-audio-identity.md`: sezione "Indicatore HUD di Alea"
      estesa con anello di carica procedurale e glow Brilla, con rimando al
      nuovo script e al precedente tecnico (`TouchAbilityButton`/
      `PixelArcadeMedallion`).

## Note

Nessuna nuova sintesi ImageGen/Codex generata per questa card, coerente con
PS-112 e con la decisione di implementare via codice, non asset.

Comandi di verifica usati in questa sessione:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-138 -Profile Focused `
  -FocusedSmoke tests/unit/test_ps138_alea_ring_glow.gd -RefreshEditor
.\tools\run-milestone-checks.ps1 -Milestone PS-138 -Profile Relevant `
  -FocusedSmoke tests/unit/test_ps138_alea_ring_glow.gd
```

Script di cattura visiva ad-hoc (non committato, scratchpad di sessione):
instanzia `movement_slice.tscn`, equipaggia Alea, avanza
`FriendPassiveController._process()` fino a 0%/35%/90%/oltre-soglia (Brilla),
salva screenshot a 1280×720 e un secondo script ritaglia/ingrandisce 6×
l'angolo HUD (`Image.crop`/`Image.resize` con `INTERPOLATE_NEAREST`) per
l'ispezione ravvicinata riportata in Criteri di accettazione.
