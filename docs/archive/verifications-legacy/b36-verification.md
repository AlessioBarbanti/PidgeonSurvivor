# B36 — Sistema tipografico di progetto

Data: 27 agosto 2026  
Stato: `IN VERIFICA` — gate automatici e Windows verdi, gate Android aperto.

## Problema

Il progetto non dichiarava alcun font. `project.godot` non aveva sezione
`[gui]`, `assets/fonts/` era vuota e ogni testo veniva reso con il font interno
di Godot (Open Sans SemiBold): neutro, di sistema, in contrasto con il logo
dipinto e con gli sprite pixel-art.

Le dimensioni erano inoltre alla deriva: `64` `theme_override_font_sizes`
sparsi in `8` scene, con `19` valori distinti (12, 13, 14, 16, 17, 18, 19, 20,
21, 22, 23, 24, 25, 26, 28, 30, 31, 34, 38) e nessuna scala.

## Implementazione

- Coppia display/testo: **Lilita One** per titoli, nomi, CTA e timer HUD;
  **Nunito** per descrizioni, impostazioni e valori. **Noto Sans Symbols 2**
  come fallback deterministico per i cinque glifi simbolo della UI. Origini,
  licenze OFL, hash e motivazione: `assets/fonts/ASSET-MANIFEST.md`.
- Tema di progetto `assets/themes/pidgeon_survivor.tres`, agganciato via
  `gui/theme/custom`, con `19` variazioni di tipo su base `Label`, `Button` e
  `CheckButton`. Il tema e le `FontVariation` sono generati da
  `tools/_generate_typography.gd`, unica fonte di verità della scala.
- I `64` override locali sono sostituiti da `theme_type_variation`. Nessuna
  scena UI dichiara più una dimensione font: lo smoke lo impone.
- Interlinea negativa sulle variazioni display. Lilita One ha un box di riga
  pari a `1.73×` la dimensione: senza correzione gonfiava i pannelli e leggeva
  slegato. `TitleXL` `-6`, `TitleL` `-5`, `TitleM`/`TitleS` `-4`, `TitleXS`
  `-3`; le variazioni di testo usano `-2`.
- `TouchAbilityButton` disegnava il countdown con `ThemeDB.fallback_font`,
  l'unico testo rimasto fuori dal tema: ora risolve `HudTimer` dal tema e
  condivide il display font con il cronometro.
- `Ⅱ` (U+2161) del pulsante pausa è sostituito da `II`: il numero romano
  sarebbe arrivato dal fallback simboli, stonando con il display.

### Scala

| Variazione | Base | Font | Dimensione | `line_spacing` |
|---|---|---|---|---|
| `TitleXL` | `Label` | Lilita One | 36 | -6 |
| `TitleL` | `Label` | Lilita One | 32 | -5 |
| `TitleM` | `Label` | Lilita One | 26 | -4 |
| `TitleS` | `Label` | Lilita One | 21 | -4 |
| `TitleXS` | `Label` | Lilita One | 17 | -3 |
| `HudTimer` | `Label` | Lilita One | 28 | 0 |
| `BodyXL` | `Label` | Nunito 600 | 20 | -2 |
| `BodyL` | `Label` | Nunito 600 | 18 | -2 |
| `BodyM` | `Label` | Nunito 600 | 16 | -2 |
| `BodyS` | `Label` | Nunito 400 | 12 | -2 |
| `ValueNumeric` | `Label` | Nunito 700 | 16 | — |
| `Eyebrow` | `Label` | Nunito 800 | 13 | — |
| `ButtonPrimary` | `Button` | Lilita One | 28 | — |
| `ButtonStandard` | `Button` | Lilita One | 20 | — |
| `ButtonCompact` | `Button` | Nunito 700 | 16 | — |
| `GlyphButtonS/M/L` | `Button` | Lilita One | 20 / 26 / 32 | — |
| `CheckLabel` | `CheckButton` | Nunito 600 | 16 | — |

## Regressioni di layout trovate e corrette

Il cambio font ha rotto due contratti geometrici esistenti; entrambi sono stati
corretti, non aggirati.

1. **`B18Q` fascia HUD.** `TimerSlot` era alto `42` unità (`y` da `42` a `84`)
   dentro una fascia da `88`. Lilita One a `28` ha un box di riga da `48`, quindi
   lo slot cresceva fino a `94` e usciva dalla fascia dichiarata, con il
   playfield che sarebbe finito dietro l'HUD. `TimerSlot` passa a `y` da `39` a
   `87`: contiene le `48` unità e resta dentro la fascia, sotto le barre.
2. **`B17A` pannello roster.** Con la scala iniziale, `Alea` — la copy più lunga
   del roster — sforava la safe area di `6.5` unità. Interlinea negativa sui
   titoli e `BodyS` a `12` riportano tutti e otto i personaggi al tetto naturale
   del pannello (`659` unità), con `10.5` unità di margine sulla safe area.

## Evidenza automatica

```powershell
godot_console --headless --path . --script tools/_generate_typography.gd
godot_console --headless --path . --script tests/integration/_typography_smoke.gd
```

`TYPOGRAPHY_SMOKE_OK`. Lo smoke verifica il binding `gui/theme/custom`, la
presenza e il tipo base delle `19` variazioni, e — attraverso lo shaping reale
del `TextServer` sull'intera catena `base + fallback` — la copertura di
`àèéìòùÀÈÉÌÒÙ‘’“”•…` e di `←◀▶⚙` senza tofu su entrambe le famiglie. Impone
inoltre che nessuna scena UI reintroduca `theme_override_font_sizes`.

Suite completa del 27 agosto 2026: `52` smoke eseguiti, `52` `PASS`, `0` `FAIL`,
inclusi `B18Q_ARENA_HUD_MINIMAL_SMOKE_OK` e
`B17A_COMPLETE_ROSTER_ABILITIES_SMOKE_OK` dopo le correzioni sopra.

Controllo percettivo su cattura tramite `tools/_capture_ui_screenshots.gd`, che
salva otto PNG in `exports/ui-screenshots/` (welcome, impostazioni, selettore,
HUD in run, level-up, intro boss, pausa, terminale).

## Gate aperti

- **Android/Pixel 9.** Il fallback simboli è deterministico e non dipende più
  dai font di sistema, ma la resa di `⚙`, `◀`, `▶` e la leggibilità di `BodyS` a
  `12` su schermo fisico vanno confermate su dispositivo, come richiesto per
  ogni modifica visiva.
- **Peso APK.** `NotoSansSymbols2-Regular.ttf` pesa `1233128` byte per cinque
  glifi. Se il budget dell'artefatto diventa critico, valutare il subsetting del
  fallback o la sostituzione dei quattro glifi UI con texture icona.
