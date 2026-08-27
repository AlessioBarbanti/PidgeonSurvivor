# Manifest tipografia

## Sistema tipografico B36

Data: 27 agosto 2026
Origine: Google Fonts, repository ufficiale `github.com/google/fonts`
Licenza: SIL Open Font License 1.1 per tutti e tre i file, copia integrale
accanto al font (`OFL-*.txt`); uso commerciale e ridistribuzione all'interno
dell'eseguibile consentiti senza attribuzione obbligatoria in-game.

Il progetto non dichiarava alcun font: ogni testo usava il font interno di
Godot (Open Sans SemiBold), neutro e in contrasto con l'identità pixel-art
arcade del logo. B36 introduce una coppia display/testo più un fallback simboli.

| File | Ruolo | SHA-256 |
|---|---|---|
| `LilitaOne-Regular.ttf` | Display: titoli, nomi, CTA, timer HUD | `f5b641c45c69d772ee4eda687bc9fda411d5cad6b0b45371491da4580cbc8d59` |
| `Nunito-Variable.ttf` | Testo: descrizioni, impostazioni, valori | `bb55a5ca5c2042335b3991af27c4d0705d0ef41cac6164ac737fd8f2a1e85207` |
| `NotoSansSymbols2-Regular.ttf` | Fallback simboli | `7d5fb73b7ca67a6798101741f5d280a3d016a56a197afcd4199dbb57b4b82a21` |

### Motivazione della scelta

- **Lilita One** condivide con il logo `welcome_logo.png` la stessa energia da
  insegna: grazie spesse, terminali arrotondati, leggermente condensato. Un solo
  peso, copertura Latin Extended completa (accenti italiani inclusi).
- **Nunito** resta amichevole ma è disegnato per il testo piccolo: le descrizioni
  degli upgrade e del roster arrivano a cinque righe a 12–16 px su telefono, dove
  un font pixel-art sarebbe illeggibile. Variabile, quindi copre 400/600/700/800
  da un singolo file.
- **Noto Sans Symbols 2** copre soltanto i cinque glifi simbolo usati dalla UI
  (`←` U+2190, `◀` U+25C0, `▶` U+25B6, `⚙` U+2699 e la punteggiatura tipografica
  residua). Serve come fallback deterministico: senza di esso quei caratteri
  dipenderebbero dal fallback di sistema, diverso tra Windows e Android.

### Risorse derivate

Le `FontVariation` in questa cartella e il tema di progetto sono generati da
`tools/_generate_typography.gd`, unica fonte di verità della scala. Rilanciarlo
dopo ogni modifica alla scala:

```powershell
godot_console --headless --path . --script tools/_generate_typography.gd
```

| Risorsa | Base | Peso | Note |
|---|---|---|---|
| `lilita_one_display.tres` | Lilita One | unico | Display |
| `nunito_regular.tres` | Nunito | 400 | Testo minore |
| `nunito_semibold.tres` | Nunito | 600 | Font di default del tema |
| `nunito_bold.tres` | Nunito | 700 | Valori numerici, pulsanti compatti |
| `nunito_eyebrow.tres` | Nunito | 800 | Eyebrow, con `spacing_glyph` a 1 |

Tutte e cinque dichiarano `NotoSansSymbols2-Regular.ttf` come fallback.
