# CTA Boss

La plancia `AFFRONTA` e' stata generata il 28 agosto 2026 con OpenAI ImageGen
built-in per sostituire il rettangolo flat nell'introduzione Boss. Origine e
autore: progetto IL GIOCO con assistenza OpenAI ImageGen. Licenza: Licenza del
progetto. Il raster non incorpora testo, quindi la label resta nativa Godot.

## Prompt finale

```text
Use case: ui-mockup
Asset type: text-free reusable boss-introduction CTA button plaque for IL GIOCO
Primary request: one wide horizontal ornamental button plaque, isolated on a
flat #00ff00 chroma-key background; deep violet/magenta pixel-art double bevel,
dark-purple inner frame, angular diamond end ornaments and a clean central area
for dynamic Godot text. No text, character, logo, watermark, shadow or detached
particles; perfectly horizontal and symmetrical.
```

## File e trasformazioni

| Percorso | Generatore | Dimensioni | Trasformazioni | SHA-256 |
|---|---|---:|---|---|
| `hd/boss_continue_cta_source.png` | OpenAI ImageGen built-in | `2172x724` RGBA PNG | Master originale, escluso da import/export con `.gdignore`; l'alpha nativo ha reso superflua la rimozione chroma. | `658744CCFD89580038888B9CD617227CCCF5204EFEFC5E063283FD1DC1213395` |
| `boss_continue_cta_base.png` | Derivazione deterministica | `747x175` RGBA PNG | Alpha bounds (soglia 8), padding 4, scala 35% nearest-neighbor tramite `tools/process-character-select-cta.ps1`. | `64022CF2EB53A1FC8727FB568870DC92AC3AFA239348DF77E13F7F4C52D2D8A8` |

La plancia e' usata solo da `ContinueButton` in `scenes/ui/boss_ui.tscn`; i
margin del nine-patch preservano estremita' e bevel su tutte le larghezze.
Il controllo percettivo Windows/Pixel 9 durante un'introduzione Boss resta un
gate manuale aperto.

## Cornice Boss Intro — PS-102 (06/09/2026)

Nuova cornice per la rivelazione Boss, distinta dal pannello di pausa. Origine
e autore: progetto IL GIOCO con assistenza OpenAI ImageGen built-in. Licenza:
Licenza del progetto. Generazione senza immagini di riferimento: nessun
riferimento di progetto è stato usato.

Prompt finale: placca 3:2 frontale, trasparente e senza testo, con medaglione
ritratto circolare integrato in alto, piume scure, ferro brunito, brace arancio
e centro neutro quasi nero per contenuto Godot dinamico; nessun personaggio,
logo, simbolo leggibile, bottone o tinta personale. Il linguaggio è una
rivelazione drammatica e giocosa di un amico divenuto Evil, non un menu di
sistema.

| Percorso | Generatore | Dimensioni | Trasformazioni | SHA-256 |
|---|---|---:|---|---|
| `hd/boss_intro_frame_source.png` | OpenAI ImageGen built-in | `1536x1024` RGBA PNG | Master originale, escluso da import/export con `.gdignore` e filtri dei tre preset. | `AE736D41B4C30671238EF02D7E5A3906D6831BF2DB66849D797EFB6F58AA478D` |
| `generated/boss_intro_frame.png` | Derivazione deterministica | `764x464` RGBA PNG | Alpha bounds (soglia 8), padding 4, scala 50% nearest-neighbor tramite `tools/process-character-select-cta.ps1`. Non ancora referenziato: cablaggio PS-103. | `07AF5CBBA3E8A1BA895ED4DF06492B33E8DD015C45B053920B1820D18D799E28` |
