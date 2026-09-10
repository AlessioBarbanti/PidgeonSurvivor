---
id: PS-146
titolo: Rendi le barre HP/XP "sospese" e rimuovi il doppio bordo
tipo: ux
area: ui
stato: PRONTO
priorita: media
dipende_da: [PS-140]
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-146 — Rendi le barre HP/XP "sospese" e rimuovi il doppio bordo

## Contesto

Le barre HP/XP dell'HUD (`scenes/ui/hud.tscn`) oggi disegnano lo stesso
`StyleBoxFlat_bar_background` due volte: una volta come
`theme_override_styles/panel` di `ExperiencePanel`/`HealthPanel`
(`PanelContainer` a piena larghezza schermo) e una seconda volta, 3px più
dentro, come `theme_override_styles/background` di
`ExperienceBar`/`HealthBar` (`ProgressBar`). Il risultato percepito è un
bordo che sembra più spesso del previsto e una barra "incassata in una
cornice a piena larghezza", non un elemento sospeso sopra la scena.

Provato dal vivo sul Pixel 9 dal proprietario dopo PS-140 (che aveva
cambiato solo il colore del bordo, non la forma): non gli piace il
trattamento "incorniciato" a piena larghezza. Ha chiarito subito dopo,
però, che lo sfondo scuro della barra (il "track" che comunica quanto manca
a riempirla) gli piace e va mantenuto: il problema è la cornice/pannello
esterno, non lo sfondo interno del `ProgressBar`.

Consultato il direttore-artistico (modalità pianificazione): confermato che
rimuovere il solo pannello esterno (sostituendolo con uno `StyleBoxEmpty`
che preserva l'inset attuale via `content_margin_*`) elimina il doppio
bordo senza cambiare le dimensioni della barra, ma da solo non basta per un
effetto "sospeso" — serve anche un margine laterale. Il proprietario ha
scelto la direzione "barra sospesa": dedup del bordo + margine laterale,
con le etichette "XP"/"HP" che seguono il nuovo inset invece di restare
fisse al margine schermo.

## Comportamento atteso

Le barre HP/XP non toccano più i lati dello schermo e non mostrano più un
bordo raddoppiato: leggono come un elemento sospeso sopra la scena di gioco,
con un solo bordo oro (quello del `ProgressBar`) e lo stesso sfondo scuro di
oggi che comunica quanto manca a riempirle. Le etichette "XP"/"HP" restano
allineate all'inizio della barra.

## Criteri di accettazione

- [ ] `ExperiencePanel` e `HealthPanel` non usano più
      `StyleBoxFlat_bar_background` come `theme_override_styles/panel`: usano
      un nuovo `StyleBoxEmpty` con `content_margin_left/top/right/bottom =
      3/3/3/2` (identico all'inset del bordo attuale), così la `ProgressBar`
      figlia non cambia dimensione.
- [ ] `ExperienceBar`/`HealthBar` continuano a usare
      `StyleBoxFlat_bar_background` come `theme_override_styles/background`
      (sfondo/track invariato, incluso il colore oro di PS-140): nessun
      doppio bordo visibile.
- [ ] `ExperiencePanel` e `HealthPanel` hanno `offset_left = 20.0` e
      `offset_right = -20.0` (oggi impliciti a `0`), stesso margine di 20px
      già in uso nello stesso HUD (`PauseButton`, `AbilityPanel`): le barre
      non toccano più i lati dello schermo.
- [ ] `ExperienceKindLabel` e `HealthKindLabel` passano da `offset_left =
      10.0`/`offset_right = 58.0` a `offset_left = 30.0`/`offset_right =
      78.0`: restano allineate all'inizio della barra con lo stesso scarto
      e la stessa larghezza (48px) di oggi.
- [ ] Nessun'altra proprietà di `StyleBoxFlat_bar_background` (colore,
      spessore bordo, fill) cambia rispetto a PS-140.

## Ambito

- File atteso: `scenes/ui/hud.tscn` (`ExperiencePanel`, `HealthPanel`,
  `ExperienceKindLabel`, `HealthKindLabel`, nuovo `StyleBoxEmpty`).
- Non toccare: `scripts/ui/hud.gd` (nessuna logica di riempimento
  coinvolta), `StyleBoxFlat_experience_fill`/`StyleBoxFlat_health_fill`,
  `PauseButton`, `TimeLabel`, `TimerSlot`, `AbilityPanel`.
- Nessun nuovo asset raster: solo `.tscn`.

## Verifica

- Smoke: `tests/unit/test_ps146_hud_bars_floating.gd` → marker
  `PS146_HUD_BARS_FLOATING_OK`, verifica che il pannello non usi più
  `StyleBoxFlat_bar_background` come proprio stile (nessun bordo duplicato),
  che la `ProgressBar` mantenga lo stesso sfondo/colore di PS-140, e che
  pannello ed etichette abbiano i nuovi offset.
- Aggiornare `tests/unit/test_ps140_hud_bar_border_color.gd` se la lettura
  dello stile del pannello (non più `StyleBoxFlat_bar_background`) rompe
  un'assunzione — il colore del bordo resta sulla barra, quel test dovrebbe
  restare valido leggendo `ExperienceBar`/`HealthBar` come già fa.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: HUD a schermo pieno in
      combattimento, controllo che le barre non tocchino i lati schermo)
- [ ] Controllo percettivo richiesto: sì — confronto screenshot
      `04_gameplay_hud.png` prima/dopo

## Decisioni

- **2026-09-10 — Emersa da una prova dal vivo su Pixel 9 durante il gate di
  runtime di PS-140.** Il proprietario non ha apprezzato il trattamento
  incorniciato a piena larghezza, ma ha chiarito subito dopo di apprezzare
  lo sfondo scuro della barra (comunica quanto manca a riempirla): la card
  si limita quindi alla cornice esterna, non tocca lo sfondo/track del
  `ProgressBar`.
- **2026-09-10 — Consultato il direttore-artistico in modalità
  pianificazione, due volte.** Prima passata: diagnosi del doppio bordo
  (stesso StyleBox condiviso da pannello e barra) e tre direzioni (solo
  dedup, dedup + inset laterale, dedup + inset + bordo alleggerito); il
  proprietario ha scelto "barra sospesa" (dedup + inset laterale) e che le
  etichette seguano il nuovo margine. Seconda passata: valori esatti di
  consegna (content_margin 3/3/3/2, margine laterale 20px — riuso della
  stessa unità già in uso nell'HUD per `PauseButton`/`AbilityPanel` — offset
  etichette 30/78) — nessun nuovo asset raster, solo `.tscn`.

## Documenti sincronizzati

- [ ] Nessuno atteso: fix di leggibilità/identità visiva HUD, nessun
      contratto di prodotto cambia.

## Note

Direzione scartata dal proprietario: "sospesa e più leggera" (bordo
alleggerito e/o ombra sotto la barra) — valutata dal direttore-artistico ma
non richiesta; resta un'estensione possibile per una card futura se il
risultato di questa non convince ancora a schermo pieno.
