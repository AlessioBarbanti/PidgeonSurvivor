---
id: PS-114
titolo: Cabla render_scale del PerformanceProfile alla risoluzione interna
tipo: perf
area: piattaforma
stato: DA DEFINIRE
priorita: media
dipende_da: []
origine:
creato: 2026-09-07
aggiornato: 2026-09-07
---

# PS-114 — Cabla render_scale del PerformanceProfile alla risoluzione interna

## Contesto

`PerformanceProfile.render_scale` ([scripts/platform/performance_profile.gd](../../../scripts/platform/performance_profile.gd))
è dichiarato ed è parte di `is_valid()` (0.5–1.0), ma non è consumato da
alcun punto del codice che scali la risoluzione interna di rendering — nota
già aperta in [docs/visual-audio-identity.md](../../../docs/visual-audio-identity.md)
(righe 178-182). Nei due file dati resta `1.0` su entrambi i profili, quindi
oggi è un parametro morto. Un consumer reale servirebbe a ridurre il fill-rate
su GPU Android deboli senza toccare la UI, ma la scelta di *quale* valore
usare per il profilo mobile è del proprietario, non di questa card: qui si
cabla solo il meccanismo, lasciando `render_scale = 1.0` su entrambi i
profili finché non verrà verificato l'impatto visivo su un device reale
(decisione 2026-09-07, vedi sotto).

## Comportamento atteso

**Sospeso in attesa di decisione del proprietario** (vedi Decisioni): il
comportamento atteso originale — applicare `render_scale` alla risoluzione
interna "senza toccare ArenaLayout" — si è dimostrato non realizzabile con
gli strumenti nativi di Godot 4 in modalità 2D Compatibility. L'unica strada
individuata (un `SubViewport` dedicato al solo mondo di gioco) è una
ristrutturazione più ampia del previsto e richiede una decisione esplicita
prima di scrivere un nuovo comportamento atteso vincolante.

## Criteri di accettazione

Da riscrivere dopo la decisione del proprietario. I criteri originali restano
qui come riferimento storico di cosa si è scoperto insufficiente:

- [ ] ~~Il `render_scale` del `PerformanceProfile` risolto viene applicato alla
      risoluzione interna di rendering del gameplay, non alla UI~~ — non
      realizzabile senza toccare anche cosa `ArenaLayout` vede come viewport
      (vedi Decisioni).
- [ ] Con `render_scale = 1.0` (valore corrente di entrambi i profili dati) il
      comportamento visivo resta identico a prima della modifica — nessuna
      regressione percepibile su Windows o Android. (Vero per costruzione:
      nessun codice è stato lasciato applicato in questa sessione.)
- [ ] `windows_performance_profile.tres` e `mobile_performance_profile.tres`
      non cambiano valore in questa card (restano `render_scale = 1.0`).

## Ambito

Da ridefinire con la decisione del proprietario. Se si procede con la strada
`SubViewport` (vedi Decisioni), l'ambito reale includerebbe
`scenes/game/movement_slice.tscn` (reparenting di `ArenaWorld` dentro un
nuovo `SubViewport`/`SubViewportContainer`), il targeting della `Camera2D`,
l'instradamento input touch/mouse verso il mondo di gioco, e la relazione fra
le coordinate di `ArenaLayout`/HUD (viewport radice) e quelle interne al
`SubViewport` — una superficie molto più ampia della sola
`movement_slice.gd` ipotizzata all'apertura della card.
- Non toccare in ogni caso: i valori di `render_scale` nei due `.tres`
  (restano `1.0`), `RunController`, la UI (deve restare a piena risoluzione).

## Verifica

Da ridefinire con la nuova geometria di consegna, una volta decisa. Nessuno
smoke esistente copre questa card: il tentativo `test_ps114_render_scale.gd`
è stato rimosso insieme al codice revertito.

## Gate manuali

- [ ] Runtime Windows (verificare nessuna regressione visiva a `render_scale = 1.0`)
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9: non bloccante essendo `render_scale = 1.0` in
      produzione con questa card; se il proprietario vuole verificare il
      meccanismo con un valore ridotto temporaneo, dichiarare esplicitamente
      che è solo una prova e non un valore da lasciare in produzione
- [ ] Controllo percettivo richiesto: sì (a `1.0`, nessuna differenza rispetto
      alla baseline attuale)

## Decisioni

- **2026-09-07 — Solo meccanismo, valore invariato.** Il proprietario ha
  scelto di cablare il consumer generico lasciando `render_scale = 1.0` su
  entrambi i profili, rimandando la scelta del valore mobile a una verifica
  percettiva su device reale fatta da lui in un secondo momento. Evita il
  rischio di sfocare la pixel art con un valore scelto alla cieca.
- **2026-09-07 — Il criterio "senza toccare ArenaLayout" si è rivelato
  impossibile con l'approccio più diretto, non implementato.** Tentativo:
  `Window.content_scale_mode = CONTENT_SCALE_MODE_VIEWPORT` con
  `content_scale_size` ridotto proporzionalmente a `render_scale`. Risultato
  osservato con un test reale (non solo previsto): a `render_scale = 0.75`,
  `get_viewport().get_visible_rect()` — ciò che `ArenaLayout` legge come
  "viewport corrente" — scende davvero a `960×540` invece di restare
  `1280×720`, perché in modalità `VIEWPORT` il viewport radice **è** la
  superficie interna ridotta, non la finestra fisica. Ha fatto fallire
  `_validate_current_contract()` (margini HUD asimmetrici, B18Q) al primo
  test. Il codice del tentativo è stato revertito integralmente (nessuna
  traccia in `movement_slice.gd`); solo PS-113 resta applicato.
- **Causa architetturale**, non un bug di implementazione: `content_scale_size`
  in modalità `VIEWPORT` non è "solo" la risoluzione di rendering, è anche la
  risoluzione logica che ogni nodo della scena vede tramite
  `get_viewport()`. Non esiste una proprietà nativa di Godot 4 per un 2D
  "compatibility renderer" che riduca la sola risoluzione di rasterizzazione
  lasciando invariata la risoluzione logica letta da `ArenaLayout`, HUD e
  input.
- **Alternativa architetturalmente corretta, non tentata qui**: spostare
  *solo* il rendering del mondo di gioco (`ArenaWorld`: player, nemici,
  proiettili, pickup, VFX) dentro un `SubViewport` + `SubViewportContainer`
  dedicato, mantenendo `ArenaLayout`, HUD, safe-area e input sul viewport
  radice reale e invariato. Riduce davvero il fill-rate sulla parte più
  pesante della scena, ma è una ristrutturazione con superficie molto più
  ampia di quanto scritto in questa card: tocca come la camera targetizza il
  mondo, come gli input touch/mouse raggiungono `ArenaWorld` (un
  `SubViewport` non riceve input di default), e la relazione fra le
  coordinate schermo di `ArenaLayout`/HUD e le coordinate mondo dentro il
  `SubViewport`. Non è "solo il meccanismo": è un cambio di architettura del
  rendering che merita una card propria, pianificata e rivista con la stessa
  cura di una modifica a `RunController` o `ArenaWorld`.
- **Aperto per il proprietario**: questa card torna `DA DEFINIRE`. Vedi la
  domanda posta fuori dalla card (in sessione) su come procedere: tentare la
  ristrutturazione `SubViewport` come card propria più ampia, oppure
  accantonare `render_scale` come leva di performance per ora (il cap FPS di
  PS-113 resta comunque applicato indipendentemente da questa card).

## Documenti sincronizzati

- [ ] [docs/visual-audio-identity.md](../../../docs/visual-audio-identity.md):
      rimuovere la "nota aperta" su `render_scale` non consumato e descrivere
      il consumer reale.

## Note

Card sorella: [PS-113](../4_to_test/PS-113-cabla-cap-fps-performance-profile.md)
(stesso profilo dati, leva diversa: cap FPS invece della risoluzione interna
— quella è andata a buon fine, `IN VERIFICA`). [PS-115](../2_to_do/PS-115-modalita-risparmio-energetico-profilo-mobile-low.md)
dipende da questa card per avere una leva reale sulla risoluzione nel profilo
"mobile_low": resta bloccata anche per questo finché questa card non si
risolve in una direzione o nell'altra.
