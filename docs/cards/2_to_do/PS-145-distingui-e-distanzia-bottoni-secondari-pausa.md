---
id: PS-145
titolo: Distingui e distanzia CAMBIA PERSONAGGIO da IMPOSTAZIONI nel pannello pausa
tipo: ux
area: ui
stato: PRONTO
priorita: media
dipende_da: [PS-142, PS-143]
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-145 — Distingui e distanzia CAMBIA PERSONAGGIO da IMPOSTAZIONI nel pannello pausa

## Contesto

PS-143 ha aggiunto il bottone "IMPOSTAZIONI" alla colonna del pannello pausa,
con lo stesso stile secondario di "CAMBIA PERSONAGGIO" (stessa
`StyleBoxTexture_secondary_*`, stessa sagoma, stesso colore) e la stessa
`theme_override_constants/separation = 6` del `VBox`, pensata in origine per
una colonna a due bottoni. Provato dal vivo sul Pixel 9 dal proprietario
(screenshot alla mano): i due bottoni secondari risultano visivamente quasi
indistinguibili e "attaccati", a differenza del salto RIPRENDI→CAMBIA
PERSONAGGIO che ha una doppia discontinuità (colore caldo/freddo, sagoma
esagono/arrotondata) a segnalare dove finisce un elemento e inizia l'altro.

Consultato il direttore-artistico (modalità pianificazione): confermato che
non esiste un ornamento separatore riusabile fra i bottoni della colonna (i
diamanti visibili nella cornice del pannello sono ai bordi esterni, non fra i
bottoni) e che la causa tecnica è la combinazione di sagoma/colore identici a
distanza minima. Il proprietario ha scelto la direzione "spazio + tinta
diversa": più respiro fra i tre bottoni e una tonalità propria per
IMPOSTAZIONI, riusando la stessa texture nine-slice via `modulate_color`
(nessun nuovo asset).

## Comportamento atteso

Nel pannello "IN PAUSA", i tre bottoni (RIPRENDI, CAMBIA PERSONAGGIO,
IMPOSTAZIONI) si leggono a colpo d'occhio come tre elementi distinti e
separati: più spazio verticale fra loro, e IMPOSTAZIONI in una tonalità
propria (steel-blue) diversa da CAMBIA PERSONAGGIO, pur mantenendo la stessa
sagoma/nine-slice e la stessa altezza target touch (64px).

## Criteri di accettazione

- [ ] `theme_override_constants/separation` del `VBox` in
      `scenes/ui/pause_overlay.tscn` passa da `6` a `16` (stesso valore già
      in uso da `ConfirmationCenter/Panel/VBox` nello stesso file).
- [ ] `SettingsButton` usa tre nuovi `StyleBoxTexture` dedicati (cloni di
      `StyleBoxTexture_secondary_normal/_hover/_pressed`, stessa
      `AtlasTexture_secondary_cta`, stessi `texture_margin_*`/
      `expand_margin_*`) con `modulate_color`:
      `normal = Color(0.72, 0.8, 0.92, 1)`,
      `hover = Color(0.88, 0.94, 1.0, 1)`,
      `pressed = Color(0.6, 0.68, 0.78, 1)`; `focus` riusa lo stesso
      `StyleBoxTexture` dello stato `hover`, come già fanno gli altri
      bottoni del pannello.
- [ ] `CAMBIA PERSONAGGIO` non cambia stile: continua a usare
      `StyleBoxTexture_secondary_normal/_hover/_pressed` senza `modulate_color`.
- [ ] A parità di viewport, l'altezza naturale del `VBox` (con la nuova
      separazione) resta comunque un tetto per il clamp di PS-142, non un
      pavimento: nessuna scrollbar visibile su 16:9/20:9 con la nuova
      spaziatura.
- [ ] La catena `focus_neighbor` a tre elementi (RIPRENDI ↔ CAMBIA
      PERSONAGGIO ↔ IMPOSTAZIONI), stabilita da PS-143, resta invariata.

## Ambito

- File atteso: `scenes/ui/pause_overlay.tscn` (`VBox`, nuovi sub_resource
  `StyleBoxTexture_settings_normal/_hover/_pressed`, nodo `SettingsButton`).
- Non toccare: `scripts/ui/pause_overlay.gd` (nessuna logica coinvolta),
  `ConfirmationCenter` (resta il riferimento di separazione, non va
  modificato), lo stile di `ResumeButton`/`ChangeCharacterButton`.
- **Sostituisce** il criterio di PS-143 "IMPOSTAZIONI usa lo stesso stile
  secondario di CAMBIA PERSONAGGIO, non lo stile primario di RIPRENDI":
  resta vero che non è lo stile primario, ma non è più identico a CAMBIA
  PERSONAGGIO — vedi Decisioni.

## Verifica

- Smoke: `tests/unit/test_ps145_pause_buttons_distinct_and_spaced.gd` →
  marker `PS145_PAUSE_BUTTONS_DISTINCT_OK`, verifica la nuova separazione
  del `VBox`, che `SettingsButton` e `ChangeCharacterButton` abbiano
  `theme_override_styles/normal` diversi (oggetti differenti) e che la
  catena `focus_neighbor` a tre elementi resti corretta.
- Aggiornare `tests/unit/test_ps143_pause_settings_button.gd` (assertion
  `assert_eq` sullo stile di `settings_button`/`change_button` diventa
  `assert_ne`, coerente con la nuova direzione).
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: apertura pausa, confronto visivo dei
      tre bottoni)
- [ ] Controllo percettivo richiesto: sì — confronto screenshot fornito dal
      proprietario prima/dopo

## Decisioni

- **2026-09-10 — Emersa da una prova dal vivo su Pixel 9 durante il gate di
  runtime di PS-142/PS-143.** Il proprietario ha osservato CAMBIA
  PERSONAGGIO e IMPOSTAZIONI come "troppo simili e troppo vicini".
- **2026-09-10 — Consultato il direttore-artistico in modalità
  pianificazione, due volte.** Prima passata: analisi della causa
  (sagoma/colore identici + separazione minima, nessun ornamento separatore
  disponibile) e opzioni (solo spazio, solo tinta, spazio+tinta,
  separatore decorativo); il proprietario ha scelto "spazio + tinta
  diversa". Seconda passata: valori esatti di consegna (separazione 16px,
  `modulate_color` per i tre stati di `SettingsButton`) — nessun nuovo
  asset raster, solo `.tscn`.
- **Sostituisce:** il criterio "stesso stile secondario di CAMBIA
  PERSONAGGIO" di
  [PS-143](../4_to_test/PS-143-sostituisci-icona-ingranaggio-pausa-con-bottone.md).

## Documenti sincronizzati

- [ ] Nessuno atteso: fix di leggibilità UI, nessun contratto di prodotto
      cambia.

## Note

Alternative scartate dal direttore-artistico: separatore ornamentale a
diamante (avrebbe richiesto un nuovo asset derivato senza risolvere la
somiglianza texture-su-texture); solo spazio o solo tinta (avrebbero
risolto un solo sintomo dei due riportati dal proprietario).
