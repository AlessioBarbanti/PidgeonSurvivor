---
id: PS-192
titolo: La citazione di stress da 167 caratteri sfora il cartiglio della Boss Intro
tipo: fix
area: ui
stato: DA DEFINIRE
priorita: bassa
dipende_da: [PS-180]
origine:
creato: 2026-09-17
aggiornato: 2026-09-17
---

# PS-192 — La citazione di stress da 167 caratteri sfora il cartiglio della Boss Intro

## Contesto

[PS-180](../4_to_test/PS-180-citazione-boss-nascosta-gate-pixel-ps176.md) ha
corretto il clipping della citazione reale (unica in gioco, condivisa da
tutte le 9 varianti Boss, PS-101) aggiungendo un'asserzione mai esistita
prima in `tests/unit/test_ps176_boss_intro_floating_portrait.gd`:
`BossUI.get_intro_quote_content_height() <= quote_rect.size.y`. Applicando
lo stesso controllo alla citazione di stress sintetica da 167 caratteri
(`STRESS_QUOTE`, usata solo dal test
`test_stress_quote_stays_inside_caption_across_variants_and_aspect_ratios`),
il contenuto renderizzato eccede il rettangolo del cartiglio — vero anche
prima di PS-180 (misurato: overflow di circa 10px anche col vecchio font a
12px, peggio a 14px). Il test esistente non l'ha mai rilevato perché
controllava solo la posizione/dimensione del rettangolo (fisso per ancore
percentuali), non l'altezza del testo effettivamente renderizzato.

Questa citazione non esiste nel gioco spedito: è un valore di test pensato
come "caso limite" per il cartiglio, la cui plausibilità come limite reale
non è mai stata confermata dal proprietario.

## Comportamento atteso

Va deciso dal proprietario quale delle due strade seguire, poi applicata:

- la lunghezza massima realistica di una citazione Boss viene definita (in
  caratteri o in righe) ed enforced/validata dove le citazioni vengono
  scritte/approvate, e il test di stress usa quel limite invece di 167
  caratteri; oppure
- 167 caratteri resta il limite da garantire, e il cartiglio/font della Boss
  Intro vengono ulteriormente adattati (dentro il contratto PS-176: nessun
  pannello/cornice reintrodotto) finché anche quel caso limite rientra senza
  clipping.

In entrambi i casi, il test aggiornato deve verificare l'altezza del
contenuto renderizzato, non solo il rettangolo assegnato.

## Criteri di accettazione

- [ ] Il proprietario ha scelto fra le due strade sopra (o una terza), non
      assunta unilateralmente in fase di implementazione.
- [ ] `test_stress_quote_stays_inside_caption_across_variants_and_aspect_ratios`
      verifica `BossUI.get_intro_quote_content_height() <= quote_rect.size.y`
      (con la stessa tolleranza usata da PS-180) per tutte e 9 le varianti e
      i tre profili di aspect ratio, verde senza eccezioni.
- [ ] Nessuna regressione sulla citazione reale già corretta da PS-180.

## Ambito

- `tests/unit/test_ps176_boss_intro_floating_portrait.gd` (valore/limite
  della citazione di stress, nuova asserzione sul contenuto).
- Eventualmente `scripts/ui/boss_ui.gd`/`scenes/ui/boss_ui.tscn` (stesso
  perimetro di PS-176/PS-180), solo se la strada scelta è adattare ancora il
  cartiglio invece di accorciare il limite.
- Se la strada scelta introduce una validazione di lunghezza sulle
  citazioni, il punto di validazione va deciso col proprietario (dato in
  `BossDefinition`? Editor-time? Non è ovvio senza la sua scelta).

Non toccare:

- Il contratto geometrico di PS-176 (ancore percentuali su `REFERENCE.png`,
  `contain` scaling, nessun pannello/cornice).
- Il fix di PS-180 (margine HUD nascosto durante `BOSS_INTRO`, font 14px)
  salvo che la strada scelta lo richieda esplicitamente.

## Verifica

- GUT: `tests/unit/test_ps176_boss_intro_floating_portrait.gd` aggiornato,
  verde su `Relevant`.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK (solo se si tocca `boss_ui.tscn`)
- [ ] Runtime fisico Pixel 9 (solo se si tocca il layout della Boss Intro)
- [ ] Controllo percettivo richiesto: sì, solo se cambia il layout/font della
      Boss Intro

## Decisioni

- **2026-09-17 — Scoperta durante PS-180, non risolta lì per restare nel
  perimetro del bug reale segnalato.** La citazione di stress non è mai
  apparsa in gioco (nessuna citazione shippata supera i caratteri della
  citazione baseline); il problema è nel valore di test o nel layout, non
  ancora chiaro quale dei due senza una decisione del proprietario.

## Documenti sincronizzati

- [ ] Nessuno atteso finché non è chiara la strada scelta.

## Note

Aperta da PS-180 invece di allargarne l'ambito. Nessuna urgenza: il gioco
spedito non produce oggi una citazione così lunga.
