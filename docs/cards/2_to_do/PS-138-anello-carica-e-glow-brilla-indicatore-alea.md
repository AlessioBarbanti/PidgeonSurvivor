---
id: PS-138
titolo: Ridisegna l'indicatore HUD della passiva di Alea con anello di carica e glow Brilla
tipo: ux
area: ui
stato: PRONTO
priorita: media
dipende_da: [PS-106]
origine:
creato: 2026-09-09
aggiornato: 2026-09-09
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

- [ ] Il contenuto renderizzato di `SobrietyIcon` (calice + anello) resta
      entro i confini di `SobrietySlot`: nessun pixel opaco della texture
      finale eccede il rect 32×32 assegnato — verificabile confrontando la
      dimensione/scala effettiva del nodo dopo il fix con quella dichiarata
      dallo slot, non solo i rect logici (il criterio che PS-106 già
      verifica e che oggi non basta).
- [ ] Un anello/arco è visibile attorno alla sola coppa del calice, non
      sull'intera altezza (stelo e piede ne restano fuori).
- [ ] Il colore dell'anello segue `charge_ratio` con una rampa continua da
      bronzo spento a oro vivo (non un colore fisso, non un cambio a
      gradini discreti).
- [ ] Il progresso verso Brilla si legge principalmente dall'anello, non dal
      solo livello del vino (il vino resta visibile ma secondario).
- [ ] Esiste un segnale (o proprietà osservabile equivalente) che espone lo
      stato Brilla all'HUD — oggi assente — emesso da `_start_alea_brilla()`
      e `_end_alea_brilla()` in `friend_passive_controller.gd`.
- [ ] Quando Brilla è attivo, l'intero calice (vetro incluso, non solo il
      vino) mostra un glow evidente via shader/modulate; l'anello può
      risultare pieno/enfatizzato ma il segnale principale dello stato
      attivo è il calice acceso.
- [ ] Stato scarico, stato in carica e stato Brilla sono distinguibili a
      colpo d'occhio l'uno dall'altro (tre segnali visivamente diversi, non
      varianti sottili dello stesso segnale).
- [ ] Nessuna riga nuova in un `ASSET-MANIFEST.md`: la card non genera né
      integra nessun asset raster nuovo, solo shader/codice sulle texture
      esistenti di PS-104.
- [ ] La soglia, la durata e il ciclo di accumulo della passiva di Alea
      (logica di [PS-105](../4_to_test/PS-105-nuova-passiva-alea-due-dita-e-parto.md))
      restano invariati: questa card espone stato, non lo modifica.
- [ ] Nessuna regressione sul resto della HUD per qualunque personaggio
      equipaggiato (stesso perimetro già coperto da
      `test_ps106_alea_sobriety_hud.gd`).

## Ambito

- `scenes/ui/hud.tscn`: fix di scala/layout di `TopBand/SobrietySlot` /
  `SobrietyIcon`; nuovo materiale/shader assegnato alla texture del calice
  per anello e glow.
- Nuovo file `assets/shaders/alea_sobriety_ring_glow.gdshader` (o nome
  equivalente): estrusione del bordo alpha per l'anello (clippata alla
  fascia della coppa) e alone luminoso per il glow Brilla, con uniform
  pilotati da `charge_ratio` e dallo stato Brilla.
- `scripts/ui/hud.gd`: lettura del nuovo segnale/stato Brilla, aggiornamento
  degli uniform dello shader in `_on_alea_sobriety_changed()` e in un nuovo
  handler per il cambio di stato Brilla.
- `scripts/content/friend_passive_controller.gd`: nuovo segnale (es.
  `alea_brilla_active_changed(active: bool)`) emesso da `_start_alea_brilla()`
  (riga 413) e `_end_alea_brilla()` (riga 442) — **solo esposizione dello
  stato esistente**, nessuna modifica alla logica di soglia/durata.

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

- Smoke: estendere `tests/unit/test_ps106_alea_sobriety_hud.gd` (o nuovo
  `tests/unit/test_ps138_alea_ring_glow.gd`) → marker
  `ALEA_RING_GLOW_SMOKE_OK` — verifica: dimensione/scala renderizzata
  dell'icona entro i confini dello slot, emissione del nuovo segnale Brilla
  da `_start_alea_brilla()`/`_end_alea_brilla()`, uniform dell'anello che
  segue `charge_ratio` (campionato ad almeno tre valori: 0.0, 0.5, 1.0),
  uniform/uniform del glow attivo solo quando `is_alea_brilla_active()` è
  vero, nessuna regressione sul perimetro già coperto da PS-106.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows: percorso — equipaggiare Alea, osservare l'anello
      scaldarsi di colore fino a Brilla, osservare il glow del calice
      intero durante Brilla.
- [ ] Validazione statica APK.
- [ ] Runtime fisico Pixel 9: stesso percorso del runtime Windows, più
      verifica esplicita che lo shader (renderer Compatibility) non
      degradi/sparisca su Android — rischio segnalato dal game-art-designer,
      non solo teorico.
- [ ] Controllo percettivo richiesto: sì — il proprietario deve vedere la
      progressione di colore dell'anello e il glow Brilla in azione, non
      solo leggere i valori degli uniform nei test.

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

## Documenti sincronizzati

- [ ] `docs/ui-ux-flow.md` o `docs/visual-audio-identity.md`: se esiste già
      una sezione sull'icona Sobrietà di Alea, aggiornarla con anello e
      glow; altrimenti non serve una nuova sezione dedicata (resta un
      dettaglio dello stesso indicatore HUD già documentato da PS-104/106).

## Note

Nessuna nuova sintesi ImageGen/Codex prevista per questa card: verificare in
chiusura che non sia stata comunque generata arte non necessaria, coerente
con la regola PS-112 (il game-art-designer lato Claude non genera raster da
sé) e con la decisione sopra (shader, non asset).
