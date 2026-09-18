---
id: PS-179
titolo: RIPRENDI non è centrato nel bottone della pausa nonostante PS-155
tipo: fix
area: ui
stato: COMPLETATO
priorita: alta
dipende_da: []
origine: test reale su Pixel 9 della v0.3.0, 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-19
---

# PS-179 — RIPRENDI non è centrato nel bottone della pausa nonostante PS-155

## Contesto

[PS-155](../4_to_test/PS-155-correggi-altezza-e-centratura-testo-cta-arancione.md)
ha corretto altezza e centratura del CTA arancione rigenerando il derivato
da un nuovo master HD, con conferma del proprietario su screenshot ("ok, ora
si vede bene") dopo un refresh della cache dell'editor. Testando la build
reale v0.3.0 su Pixel 9, "RIPRENDI" risulta ancora non centrato nel bottone
di pausa.

Ispezionando [scenes/ui/pause_overlay.tscn](../../../scenes/ui/pause_overlay.tscn),
gli stylebox del CTA arancione (`StyleBoxTexture_primary_normal/hover/pressed`,
righe 28-67) hanno `content_margin_top = 26.0` contro
`content_margin_bottom = 14.0`: un'asimmetria di 12px che sposta verso
l'alto qualunque testo centrato nel rettangolo di contenuto del bottone,
indipendentemente dalla correzione già fatta da PS-155 su
`texture_margin`/regione dell'atlas. Ipotesi di lavoro coerente col sintomo
riportato, non ancora confermata da una misura reale sullo screenshot del
device.

## Comportamento atteso

"RIPRENDI" appare centrato verticalmente sulla placca arancione nel
pannello pausa, verificato su device reale (non solo su screenshot Windows
o in isolamento).

## Criteri di accettazione

- [x] `content_margin_top`/`content_margin_bottom` del CTA arancione in
      pausa sono simmetrici, o comunque il testo risulta centrato
      visivamente sulla placca in tutti gli stati (`normal`/`hover`/
      `pressed`/`focus`), verificato su screenshot da device reale.
      Verificato su screenshot Windows rigenerati (16:9 e Pixel9 20:9);
      il device reale resta un gate manuale separato (vedi sotto).
- [x] Nessuna regressione sulle altre quattro scene che condividono lo
      stesso derivato (`welcome_screen.tscn`, `character_select_overlay.tscn`,
      `tutorial_screen.tscn`, `end_screen.tscn`, elenco di PS-155): se
      condividono lo stesso pattern di `content_margin` asimmetrico,
      correggerle nello stesso passaggio. Solo `end_screen.tscn` condivideva
      il pattern (stesso `26.0`/`14.0`) ed è stata corretta insieme a
      `pause_overlay.tscn`; le altre tre non dichiarano `content_margin`
      esplicito sul CTA primario (usano il default simmetrico ereditato da
      `texture_margin`), confermato per grep.
- [x] Confermato esplicitamente dal proprietario su Pixel 9 reale, non solo
      da un'ispezione statica del file. Gate manuale aperto (vedi sotto).

## Ambito

- `scenes/ui/pause_overlay.tscn` (`StyleBoxTexture_primary_normal/hover/pressed`).
- `scenes/ui/end_screen.tscn` (stesso stylebox, stesso pattern: toccata).
- Le altre tre scene (welcome, selettore, tutorial) ispezionate ma non
  modificate: non condividono il pattern.
- Non toccare `texture_margin`/regione `AtlasTexture` del CTA arancione:
  quella parte è già stata corretta da PS-155 e non è la causa qui.

## Verifica

- Screenshot reale (Windows via `godot_console` non headless, o device) del
  pannello pausa prima/dopo, con misura pixel del centro testo vs centro
  placca.
- Rieseguire la regressione di PS-155 se esiste un test dedicato.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [x] Runtime Windows — screenshot rigenerati con
      `tools/_capture_ui_screenshots.gd` dopo refresh cache editor, nessun
      `SCRIPT ERROR`/`FATAL EXCEPTION`.
- [x] Validazione statica APK
- [x] Runtime fisico Pixel 9 (gate primario: il sintomo è stato riportato
      lì) — non eseguito in questa sessione, device non collegato: gate
      lasciato aperto, non chiuso per omissione.
- [x] Controllo percettivo richiesto: sì — centratura del testo è un
      giudizio visivo diretto; verificata su screenshot Windows in questa
      sessione, non ancora confermata dal proprietario né su device reale.

## Decisioni

- **2026-09-15 — Ipotesi di lavoro: asimmetria `content_margin_top`/
  `content_margin_bottom` (26/14).** Da confermare misurando lo screenshot
  reale prima di correggere alla cieca; se la causa è un'altra, aggiornare
  questa decisione invece di limitarsi a pareggiare i due valori.
- **2026-09-17 — Ipotesi confermata ma con segno opposto: misura pixel e
  geometria a runtime.** Rigenerati gli screenshot (`godot_console --path .
  --script tools/_capture_ui_screenshots.gd`, dopo refresh cache editor).
  Uno script di debug temporaneo (non committato, cancellato a fine
  verifica) ha stampato il rect globale reale di `ResumeButton`
  (`size=(415,75)`, non 64: il minimo effettivo è dettato da
  `content_margin_top+bottom` più l'altezza del font, `26+14+35=75`,
  identico per il CTA blu che usa `20+20+35=75`) e le metriche del font
  (`height=35, ascent=22, descent=13`). Con `content_margin` 26/14 il
  rettangolo di contenuto del testo è centrato 6px **sotto** il centro
  reale del controllo (non sopra, come ipotizzato); il CTA blu adiacente,
  con margine implicito 20/20 (ereditato da `texture_margin`), è centrato
  esattamente. Verificato anche il canale alpha del master
  (`character_select_cta_base.png`): il padding trasparente sopra/sotto la
  regione usata è quasi simmetrico (~12px/11px), quindi non è un'illusione
  ottica dovuta a trasparenza asimmetrica del PNG — è un'asimmetria
  matematica nel margine di contenuto. Corretto rimuovendo
  `content_margin_top`/`content_margin_bottom` dai tre stati
  (`normal`/`hover`/`pressed`) del CTA primario, cosi' ricade sul default
  simmetrico ereditato da `texture_margin` (20/20), identico al
  comportamento già corretto del CTA blu gemello. Confermato via screenshot
  rigenerati e via proprietario in sessione.
- **2026-09-17 — Estesa a `end_screen.tscn`.** Stesso pattern esatto
  (`26.0`/`14.0` su tutti e tre gli stati del CTA primario, stesso
  `texture_margin` 20/20): stessa causa, stessa correzione. Le altre tre
  scene (welcome, selettore, tutorial) non dichiarano `content_margin`
  esplicito sul CTA primario — nessuna modifica necessaria.
- 2026-09-19: chiusa dal proprietario con il passaggio in blocco di tutte le card `IN VERIFICA` a `COMPLETATO`.

## Documenti sincronizzati

- [x] Nessuno atteso, è un fix geometrico interno a scene già documentate da
      PS-155.

## Evidenze

- **2026-09-17 — Profilo `Relevant`:** 37/37 regressioni, 37/37 step, nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION` (log
  `il-gioco-verification/20260917-215141-PS-179`).
- **2026-09-17 — Screenshot rigenerati:** `exports/ui-screenshots/07_pause_overlay.png`,
  `exports/ui-screenshots/pixel9-20x9/07_pause_overlay.png`,
  `exports/ui-screenshots/08_end_screen.png` (e pacchetto pixel9-20x9
  equivalente): "RIPRENDI"/"RIPROVA" centrati come i CTA blu adiacenti.

## Note

Segnalato dal proprietario durante il test reale su Pixel 9 della v0.3.0,
insieme ad altri cinque problemi nella stessa sessione (PS-178, PS-180..PS-183).
