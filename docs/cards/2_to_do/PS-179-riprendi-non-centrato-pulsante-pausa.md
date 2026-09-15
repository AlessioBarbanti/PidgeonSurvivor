---
id: PS-179
titolo: RIPRENDI non è centrato nel bottone della pausa nonostante PS-155
tipo: fix
area: ui
stato: PRONTO
priorita: alta
dipende_da: []
origine: test reale su Pixel 9 della v0.3.0, 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-15
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

- [ ] `content_margin_top`/`content_margin_bottom` del CTA arancione in
      pausa sono simmetrici, o comunque il testo risulta centrato
      visivamente sulla placca in tutti gli stati (`normal`/`hover`/
      `pressed`/`focus`), verificato su screenshot da device reale.
- [ ] Nessuna regressione sulle altre quattro scene che condividono lo
      stesso derivato (`welcome_screen.tscn`, `character_select_overlay.tscn`,
      `tutorial_screen.tscn`, `end_screen.tscn`, elenco di PS-155): se
      condividono lo stesso pattern di `content_margin` asimmetrico,
      correggerle nello stesso passaggio.
- [ ] Confermato esplicitamente dal proprietario su Pixel 9 reale, non solo
      da un'ispezione statica del file.

## Ambito

- `scenes/ui/pause_overlay.tscn` (`StyleBoxTexture_primary_normal/hover/pressed`).
- Le altre quattro scene elencate sopra, solo se condividono lo stesso
  problema.
- Non toccare `texture_margin`/regione `AtlasTexture` del CTA arancione:
  quella parte è già stata corretta da PS-155 e non è la causa qui.

## Verifica

- Screenshot reale (Windows via `godot_console` non headless, o device) del
  pannello pausa prima/dopo, con misura pixel del centro testo vs centro
  placca.
- Rieseguire la regressione di PS-155 se esiste un test dedicato.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (gate primario: il sintomo è stato riportato
      lì)
- [ ] Controllo percettivo richiesto: sì — centratura del testo è un
      giudizio visivo diretto

## Decisioni

- **2026-09-15 — Ipotesi di lavoro: asimmetria `content_margin_top`/
  `content_margin_bottom` (26/14).** Da confermare misurando lo screenshot
  reale prima di correggere alla cieca; se la causa è un'altra, aggiornare
  questa decisione invece di limitarsi a pareggiare i due valori.

## Documenti sincronizzati

- [ ] Nessuno atteso, è un fix geometrico interno a scene già documentate da
      PS-155.

## Note

Segnalato dal proprietario durante il test reale su Pixel 9 della v0.3.0,
insieme ad altri cinque problemi nella stessa sessione (PS-178, PS-180..PS-183).
