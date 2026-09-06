---
id: PS-106
titolo: Integra l'icona del calice Sobrietà di Alea in HUD
tipo: ux
area: ui
stato: BLOCCATO
priorita: media
dipende_da: [PS-104]
origine:
creato: 2026-09-05
aggiornato: 2026-09-05
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
l'asset. Questa card cabla l'icona di PS-104 in HUD e resta bloccata finché
quella non è pronta.

## Comportamento atteso

Durante una run con Alea, in alto a sinistra nella safe area appare un'icona
a calice di vino rosso (asset di PS-104) che comunica in tempo reale il
livello di riempimento della barra Sobrietà esposta dalla passiva, senza
sovrapporsi a `HealthPanel`/`ExperiencePanel` già presenti in quella fascia.
Con qualunque altro personaggio equipaggiato, l'icona non appare.

## Criteri di accettazione

- [ ] L'icona calice di PS-104 è visibile in HUD, in alto a sinistra nella
      safe area, senza sovrapporsi a `HealthPanel`/`ExperiencePanel`
      ([scenes/ui/hud.tscn](../../../scenes/ui/hud.tscn) righe 113-170).
- [ ] Il riempimento dell'icona riflette in tempo reale il valore esposto
      dalla passiva di Alea introdotta da PS-105 (0.0 = vuoto, 1.0 = pieno),
      aggiornato ad ogni variazione, senza polling né valori stantii.
- [ ] L'icona è visibile solo quando il personaggio equipaggiato è Alea (o
      la sua variante Evil, se la Signature ne condivide la passiva); con
      qualunque altro personaggio resta nascosta, senza riservare comunque
      spazio vuoto in HUD.
- [ ] L'icona non viene mai riusata come tell di stato "in Brilla": quel
      segnale resta il particellare dedicato introdotto da PS-105
      (confermato, vedi Decisioni di PS-104/PS-105).
- [ ] Il livello dell'icona si azzera/congela in sincronia con l'accumulo
      della barra Sobrietà (pausa, level-up, Boss intro, restart): nessuno
      stato residuo o scorretto visibile in HUD in quei momenti.
- [ ] Nessuna regressione sul resto della HUD (`HealthPanel`, `ExperiencePanel`,
      pannelli abilità) per qualunque personaggio, non solo Alea.

## Ambito

- `scenes/ui/hud.tscn`: nuovo elemento icona/barra Sobrietà in alto a
  sinistra, usando il derivato prodotto da
  [PS-104](./PS-104-icona-calice-sobrieta-alea.md).
- `scripts/ui/hud.gd`: cablaggio al segnale/metodo esposto dalla passiva di
  Alea (introdotto da [PS-105](./PS-105-nuova-passiva-alea-due-dita-e-parto.md)),
  visibilità condizionata al personaggio equipaggiato.

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
  del segnale/metodo di PS-105, assenza di sovrapposizione con
  `HealthPanel`/`ExperiencePanel`, e comportamento invariato con altri
  personaggi equipaggiati.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: run con Alea, osservare il calice
      riempirsi fino a un ciclo Brilla completo)
- [ ] Controllo percettivo richiesto: sì — il calice deve leggersi durante il
      gameplay reale (non solo in un provino statico) e non deve competere
      visivamente con `HealthPanel`/`ExperiencePanel`

## Decisioni

- **2026-09-05 — Scorporata da PS-105 su richiesta del proprietario.**
  PS-105 aveva un solo criterio (su nove) che dipendeva dall'asset di
  PS-104; il resto della passiva (RNG rimosso, ciclo Sobrietà/Brilla, deriva
  sull'input, reset, ruolo/passiva in `characters.md`, nuovo tell
  particellare) non tocca arte. Scorporare quel criterio in questa card
  sblocca PS-105 subito, stessa forma già usata per PS-102/PS-103.
- **2026-09-05 — Contratto di segnale proposto per l'integrazione:
  `alea_sobriety_changed(fill_ratio: float)`.** Nome scelto in coordinamento
  con l'implementazione di PS-105 nella stessa sessione, per tenere le due
  card allineate; se l'implementazione finale di PS-105 espone un nome
  diverso, questa card si cablerà a quello — non è un contratto imposto da
  PS-106 a PS-105.

## Documenti sincronizzati

- [ ] `docs/visual-audio-identity.md`: se l'icona introduce un nuovo elemento
      HUD stabile, aggiungere una riga quando cablata.

## Note

`BLOCCATO` finché [PS-104](./PS-104-icona-calice-sobrieta-alea.md) non
raggiunge almeno `IN VERIFICA` (asset e manifest pronti da cablare), per il
contratto board in `docs/cards/README.md`.

Non è una card `tipo: art`: è wiring in scena, quindi non va delegata a
`game-art-designer` (quella resta la competenza di PS-104).
