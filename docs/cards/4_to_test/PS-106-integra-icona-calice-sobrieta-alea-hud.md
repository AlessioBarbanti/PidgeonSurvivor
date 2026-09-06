---
id: PS-106
titolo: Integra l'icona del calice Sobrietà di Alea in HUD
tipo: ux
area: ui
stato: IN ATTESA ASSET
priorita: media
dipende_da: [PS-104]
origine:
creato: 2026-09-05
aggiornato: 2026-09-06
---

# PS-106 — Integra l'icona del calice Sobrietà di Alea in HUD

## Contesto

[PS-105](./PS-105-nuova-passiva-alea-due-dita-e-parto.md) sostituisce la
passiva di Alea con "Due Dita e Parto": una barra Sobrietà che si riempie nel
tempo e, raggiunta la soglia, fa entrare Alea in "Brilla". PS-105 copre la
logica di accumulo/trigger e i segnali che la espongono
(`FriendPassiveController.alea_sobriety_changed`/`alea_brilla_changed`), ma
non tocca `hud.tscn`/`hud.gd`: quella card si ferma alla logica, per lo stesso
motivo per cui [PS-104](./PS-104-icona-calice-sobrieta-alea.md) (l'icona a
calice di vino rosso) si ferma a master/derivato/manifest (PS-090).

Questa card era in origine un unico criterio di accettazione dentro PS-105;
il proprietario ha scelto di scorporarla in una card di integrazione
separata — stessa forma già usata per [PS-102](./PS-102-cornice-dedicata-boss-intro.md)/[PS-103](./PS-103-integra-cornice-boss-intro.md)
— così PS-105 si sblocca sul resto della passiva senza dover attendere
l'asset.

## Comportamento atteso

Durante una run con Alea, in alto a sinistra nella safe area appare un'icona
a calice di vino rosso (asset di PS-104) che comunica in tempo reale il
livello di riempimento della barra Sobrietà esposta dalla passiva, senza
sovrapporsi a `HealthPanel`/`ExperiencePanel` già presenti in quella fascia.
Con qualunque altro personaggio equipaggiato, l'icona non appare.

## Criteri di accettazione

- [ ] L'icona calice **reale** di PS-104 è visibile in HUD, in alto a
      sinistra nella safe area, senza sovrapporsi a
      `HealthPanel`/`ExperiencePanel` ([scenes/ui/hud.tscn](../../../scenes/ui/hud.tscn)
      righe 146-179). Il posizionamento e l'assenza di sovrapposizione sono
      verificati dallo smoke, ma con l'asset placeholder di PS-110 (vedi
      Decisioni): resta da confermare che l'asset reale, una volta generato
      da PS-104, non cambi le dimensioni assunte qui.
- [x] Il riempimento dell'icona riflette in tempo reale il valore esposto
      dalla passiva di Alea introdotta da PS-105 (0.0 = vuoto, 1.0 = pieno),
      aggiornato ad ogni variazione, senza polling né valori stantii —
      verificato dallo smoke (`TextureProgressBar` legge il segnale
      `alea_sobriety_changed`, comportamento indipendente dall'asset).
- [x] L'icona è visibile solo quando il personaggio equipaggiato è Alea; con
      qualunque altro personaggio resta nascosta, senza riservare comunque
      spazio vuoto in HUD — verificato dallo smoke. La parentesi sulla
      variante Evil non si applica: Evil esiste solo come identità Boss
      (PS-051), mai come personaggio giocabile in HUD.
- [x] L'icona non viene mai riusata come tell di stato "in Brilla": quel
      segnale resta il particellare dedicato introdotto da PS-105 — per
      costruzione, questa card non tocca `passive_state_particles.gd` né la
      risoluzione del tell esistente.
- [ ] Il livello dell'icona si azzera/congela in sincronia con l'accumulo
      della barra Sobrietà (pausa, level-up, Boss intro, restart): il
      restart è verificato esplicitamente dallo smoke; pausa/level-up/Boss
      intro non hanno un'asserzione dedicata in questa card (derivano dal
      fatto che l'HUD si limita a riflettere un segnale che il controller
      stesso, già coperto da PS-105, non emette in quegli stati) — lasciato
      non spuntato perché non verificato esplicitamente, non perché
      sospetto un problema.
- [x] Nessuna regressione sul resto della HUD (`HealthPanel`, `ExperiencePanel`,
      pannelli abilità) per qualunque personaggio, non solo Alea — profilo
      `Relevant` verde (41/41), incluso `test_b09_hud.gd`.

## Ambito

- `scenes/ui/hud.tscn`: nuovo `SobrietySlot`/`SobrietyIcon`
  (`TextureProgressBar`) in `TopBand`, sotto le barre XP/HP.
- `scripts/ui/hud.gd`: nuovo parametro `friend_passive_controller` in
  `configure()`, cablaggio al segnale `alea_sobriety_changed`, visibilità
  condizionata in `set_friend_definition()`.
- `scripts/game/movement_slice.gd`: passa `_friend_passive_controller` alla
  chiamata esistente di `_hud.configure()`.

Non toccare:

- `scripts/content/friend_passive_controller.gd`: logica di accumulo,
  soglia, Brilla e tell particellare — restano di PS-105;
- `data/friends/alea.tres` e le altre sette passive del cast;
- `HealthPanel`/`ExperiencePanel`/pannelli abilità esistenti, se non per
  l'assenza di sovrapposizione richiesta sopra.

## Verifica

- Smoke: `tests/unit/test_ps106_alea_sobriety_hud.gd` → marker
  `ALEA_SOBRIETY_HUD_SMOKE_OK` — verifica visibilità condizionata al
  personaggio Alea, aggiornamento in tempo reale del riempimento al variare
  del segnale di PS-105, assenza di sovrapposizione con
  `HealthPanel`/`ExperiencePanel`, azzeramento al restart, e comportamento
  invariato con altri personaggi equipaggiati. 3/3 verdi.
- Profilo eseguito: `Relevant` (41/41 verdi), nessun `SCRIPT ERROR`/
  `FATAL EXCEPTION` nei log.

## Gate manuali

- [ ] Runtime Windows: non pertinente finché l'asset è un placeholder
      (scacchiera magenta riconoscibile, non arte da giudicare)
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run con Alea, osservare il calice
      riempirsi fino a un ciclo Brilla completo) — da rifare con l'asset
      reale, non ha senso con il placeholder
- [ ] Controllo percettivo richiesto: sì — ma non prima che l'asset reale di
      PS-104 sostituisca il placeholder

## Decisioni

- **2026-09-05 — Scorporata da PS-105 su richiesta del proprietario.**
  PS-105 aveva un solo criterio (su nove) che dipendeva dall'asset di
  PS-104; il resto della passiva (RNG rimosso, ciclo Sobrietà/Brilla, deriva
  sull'input, reset, ruolo/passiva in `characters.md`, nuovo tell
  particellare) non tocca arte. Scorporare quel criterio in questa card
  sblocca PS-105 subito, stessa forma già usata per PS-102/PS-103.
- **2026-09-05 — Contratto di segnale proposto per l'integrazione:
  `alea_sobriety_changed(fill_ratio: float)`.** Confermato invariato
  nell'implementazione finale di PS-105 (`scripts/content/friend_passive_controller.gd`):
  nessun adattamento necessario.
- **2026-09-06 — Procede con un placeholder invece di restare `BLOCCATO`
  (PS-109/PS-110), prima prova pratica del meccanismo.** PS-104 ha fissato
  in modalità pianificazione (vedi le sue Decisioni) la geometria di
  consegna: due derivati `128×128` RGBA, `alea_sobriety_glass_empty.png`
  (base statica) e `alea_sobriety_wine_fill.png` (liquido, da mascherare),
  pensati per un riempimento verticale guidato da un float continuo. Questo
  ha reso possibile generare subito un placeholder alla stessa geometria con
  `tools/generate-art-placeholder.ps1 -Width 128 -Height 128 -Label
  "GLASS"/"WINE"` e cablarlo in `hud.tscn` con un `TextureProgressBar`
  (`fill_mode` verticale dal basso), invece di aspettare che PS-104 generi
  l'asset reale. Stato portato a `IN ATTESA ASSET` invece di restare
  `BLOCCATO`.
- **2026-09-06 — `TextureProgressBar` richiede `min_value=0.0`/
  `max_value=1.0`/`step=0.0` espliciti.** Il default di `Range`
  (`max_value=100`, `step=1`) arrotondava il float 0.0-1.0 allo step intero
  più vicino (0.5 diventava 1.0) — scoperto dallo smoke stesso durante
  questa prova, non da ispezione a priori. Impostato esplicitamente nella
  scena.
- **Aperto:** questa card non può passare a `IN VERIFICA`/`COMPLETATO`
  finché PS-104 non genera l'asset reale e lo scrive agli stessi due
  percorsi in `assets/art/icons/hud/generated/`, sostituendo il
  placeholder. Il gate è il pixel `(0,0)` dei due derivati: finché resta
  magenta pieno (`255,0,255,255`), la card resta qui.

## Documenti sincronizzati

- [ ] `docs/visual-audio-identity.md`: da aggiornare quando l'asset reale
      (non il placeholder) sostituisce quello attuale.

## Note

Non è una card `tipo: art`: è wiring in scena, quindi non va delegata a
`game-art-designer` (quella resta la competenza di PS-104).

Prima prova end-to-end del flusso PS-109 (pianificazione: il
game-art-designer ha interpellato il proprietario sul meccanismo di
riempimento invece di lasciarlo indeciso) + PS-110 (placeholder e
`IN ATTESA ASSET`): entrambi i meccanismi hanno funzionato, con una
correzione emersa durante il test stesso — `AskUserQuestion` non è
disponibile per i sotto-agenti, quindi la domanda è stata rigirata
all'orchestratore invece che posta direttamente dal game-art-designer. Il
design di PS-109 va corretto di conseguenza (card separata).
