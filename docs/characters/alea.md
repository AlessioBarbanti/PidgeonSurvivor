# Direzione visuale — Alea

Riferimento sintetico per la famiglia visiva di Alea, pensato come aiuto per
`.agents/skills/game-art-designer/SKILL.md` (Claude:
`.claude/agents/game-art-designer.md`; Codex:
`.codex/agents/game-art-designer.toml`). Non sostituisce l'ispezione dei
fratelli visivi reali: in caso di conflitto con i master o con
`assets/art/characters/ASSET-MANIFEST.md`, questi ultimi restano autorevoli.
Ruolo gameplay, passiva e abilità attiva restano in
[`docs/characters.md`](../characters.md), non duplicati qui.

## Direzione visuale approvata

"Ballerina classica nel pieno di una Gran Piroetta, circondata da un nastro
circolare e un richiamo d'aquila." (`docs/characters.md`)

## Silhouette, costume e palette

Ballerina classica, tutu leggibile, passi eleganti. Capelli biondo caldo,
costume bianco-avorio con oro — correzione rispetto al primo output B18U per
allinearsi al fondale welcome
(`assets/art/characters/ASSET-MANIFEST.md`, tabella prompt B18U). Nastro
circolare e richiamo d'aquila della Gran Piroetta restano VFX separati, non
parte della silhouette del personaggio.

Il prompt integrale originale dell'identity pass non è disponibile nel
checkout. Il registro storico conserva un
[prompt ricostruito](../archive/generation-prompts-and-references.md#prompt-comuni-ricostruiti--non-originali),
etichettato esplicitamente come non originale e utile solo per il riuso, non
come prova di provenienza.

## Variante Evil

Costume avorio-oro e ornamento preservati; posa composta e minacciosa,
accento magenta (`evil_alea`, `assets/art/characters/ASSET-MANIFEST.md`,
Parte 2). Ha richiesto un passaggio correttivo `background-extraction` per
rimuovere il checkerboard incorporato, senza ridisegnare il soggetto.

Grammatica Evil condivisa con tutto il cast: fumo prugna controllato, occhio
magenta-viola luminoso, poche crepe energetiche e rim light personale;
preserva acconciatura, corporatura, colori dell'abito e accessori del
Player.

## Reference fotografica

- `docs/characters/references/alea/source-01.png` — 1 file, ruolo `subject
  reference`, non editing target, mai output fotorealistico; autorizzata dal
  proprietario, archiviata il 2 settembre 2026.

## Master e derivati correnti

| File | Ruolo |
|---|---|
| `assets/art/characters/alea/hd/poses.png` | master HD Player, 3 pose (escluso da import/export) |
| `assets/art/characters/alea/hd/evil_portrait.png` | master HD Evil, ritratto busto (escluso da import/export) |
| `assets/art/characters/alea/generated/sprite.png` | striscia runtime 96×32 |
| `assets/art/characters/alea/generated/carousel.png` | ritratto carosello selezione 256×256 |
| `assets/art/characters/alea/generated/evil_portrait.png` | ritratto Evil runtime 256×256 |

Busto Player dedicato (`portrait.png`, analogo a `evil_portrait.png`): master
e derivato già presenti su disco
(`assets/art/characters/alea/hd/portrait.png`,
`assets/art/characters/alea/generated/portrait.png`), ma **non ancora
integrati**: `data/friends/alea.tres` continua a puntare
`portrait`/`portrait_placeholder` all'`AtlasTexture` CC0 e
`portraits_are_placeholders` resta `true`. Integrazione, manifest e
accettazione percettiva sono responsabilità di
[PS-068](../cards/3_in_sprint/PS-068-genera-ritratti-busto-cast-giocabile.md),
tuttora in corso.
